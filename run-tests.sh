#!/bin/bash
# run-tests.sh - dev-crew の正規テストランナー。
#
# 責務: (1) 引数正規化 + 拒否 (2) admission check（テストプロセス数のみ）
# (3) immutable snapshot 上での実行（source tree 境界チェック + コピー、指紋
# 照合や再試行はしない） (4) 起動時の残留 snapshot 警告（削除はしない）
# (5) PASS/FAIL 集計。
#
# 設計: docs/cycles/20260913_0059_runner-admission-snapshot.md
#       docs/cycles/20260916_1634_shrink-runner-remove-nesting.md
#       （指紋の三点照合・再試行プロトコル・owner metadata・reaper・load/memory
#       admission・live tree advisory・DEV_CREW_RUNNER_LIB_ONLY・
#       DEV_CREW_TEST_HOOK_* を削除。受容する失敗は上記 cycle doc 参照）
#
# exit code 契約:
#   0 = 全テスト PASS
#   1 = 1 件以上 FAIL（実行したテストの FAIL のみ。流用禁止）
#   2 = runner が開始不能（admission BLOCK / snapshot 作成失敗 / コピー失敗を
#       統合。「1 件以上 FAIL」と混同させない）
#   3 = 引数拒否（repo 外パス / .. 脱出 / symlink 脱出 / tests/ 配下でない /
#       ディレクトリ / test-*.sh 命名でない / 不在 / 対象 0 件）
# signal 終了は別枠のまま変更しない: TERM=143 / INT=130 / HUP=129
#
# job control (`set -m`) は、SIGINT/SIGTERM を実行中の子テストへ転送する際に
# 子プロセスの trap を機能させるために必須（非 job-control 下では bash が
# 非同期コマンドの INT/QUIT を自動的に無視するため、子側の trap が発火しない
# ことを実測確認済み）。

set -uo pipefail
set -m

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
PARENT_DOC_SRC="$(cd "$BASE_DIR/../.." 2>/dev/null && pwd)/docs/test_architecture.md"

SNAPSHOT_PREFIX="dev-crew-snap."
# Loop guards, not tunables: bound pathological input (a symlink cycle that
# race conditions leave undetected by `-L`, or a `ps` snapshot with a
# corrupted ppid chain) so these loops cannot spin forever.
MAX_SYMLINK_HOPS=40
MAX_PID_ANCESTOR_HOPS=200

SNAP=""
CHILD_PID=""
CLEANED=0
PASS=0
FAIL=0
FAILED_TESTS=()
NORMALIZED_ARGS=()

# ===========================================================================
# cleanup / signal handling
# ===========================================================================

do_cleanup() {
  [ "$CLEANED" -eq 1 ] && return 0
  CLEANED=1
  if [ -n "$SNAP" ] && [ -d "$SNAP" ]; then
    rm -rf "$SNAP" 2>/dev/null
  fi
  return 0
}

on_signal() {
  # $1 = signal name, $2 = exit code to use. Explicit `exit` is required:
  # without it bash continues executing past the trap (実測確認済み).
  local sig="$1" code="$2"
  if [ -n "$CHILD_PID" ] && kill -0 "$CHILD_PID" 2>/dev/null; then
    # Send to the child's process GROUP first: under `set -m` the
    # backgrounded child is its own job with its own pgid (== CHILD_PID), so
    # a plain `kill -s sig CHILD_PID` never reaches grandchildren the test
    # itself spawned (e.g. `sleep 30 &`), leaving them orphaned. Fall back to
    # a direct kill if group delivery is refused for any reason.
    kill -s "$sig" -- "-$CHILD_PID" 2>/dev/null || kill -s "$sig" "$CHILD_PID" 2>/dev/null || true
    wait "$CHILD_PID" 2>/dev/null || true
  fi
  do_cleanup
  exit "$code"
}

trap do_cleanup EXIT
trap 'on_signal TERM 143' TERM
trap 'on_signal INT 130' INT
# HUP (e.g. a closing terminal) must also drain the snapshot; without this
# trap only EXIT/TERM/INT clean up and a HUP'd runner leaks its snapshot.
trap 'on_signal HUP 129' HUP

# ===========================================================================
# path helpers
# ===========================================================================

# physical_path: resolves a path to its fully symlink-resolved absolute form
# (directory components AND the leaf, if it is itself a symlink chain).
# realpath は意図的に使わない（repo の既存方針、rules/plan-discipline.md 参照）。
physical_path() {
  local target="$1"
  if [ -d "$target" ]; then
    (cd "$target" 2>/dev/null && pwd -P) || return 1
    return 0
  fi
  local dir base pdir full
  dir="$(dirname "$target")"
  base="$(basename "$target")"
  pdir="$(cd "$dir" 2>/dev/null && pwd -P)" || return 1
  full="$pdir/$base"
  local hops=0
  while [ -L "$full" ]; do
    hops=$((hops + 1))
    [ "$hops" -gt "$MAX_SYMLINK_HOPS" ] && return 1
    local link
    link="$(readlink "$full")"
    case "$link" in
      /*) full="$link" ;;
      *) full="$(dirname "$full")/$link" ;;
    esac
    local d2 b2 pd2
    d2="$(dirname "$full")"
    b2="$(basename "$full")"
    pd2="$(cd "$d2" 2>/dev/null && pwd -P)" || return 1
    full="$pd2/$b2"
  done
  printf '%s\n' "$full"
}

# ===========================================================================
# 引数の正規化 (argument normalization)
# ===========================================================================

normalize_args() {
  NORMALIZED_ARGS=()
  [ "$#" -eq 0 ] && return 0

  local base_real tests_real
  base_real="$(cd "$BASE_DIR" && pwd -P)" || { echo "ERROR: cannot resolve BASE_DIR" >&2; exit 3; }
  tests_real="$base_real/tests"

  local arg
  for arg in "$@"; do
    local candidate
    case "$arg" in
      /*) candidate="$arg" ;;
      *) candidate="$BASE_DIR/$arg" ;;
    esac

    if [ ! -e "$candidate" ]; then
      echo "ERROR: argument rejected (path does not exist): $arg" >&2
      exit 3
    fi

    local resolved
    resolved="$(physical_path "$candidate")"
    if [ -z "$resolved" ]; then
      echo "ERROR: argument rejected (cannot resolve path): $arg" >&2
      exit 3
    fi

    case "$resolved" in
      "$tests_real"/*) : ;;
      *)
        echo "ERROR: argument rejected (outside tests/ or outside the repo): $arg" >&2
        exit 3
        ;;
    esac

    if [ ! -f "$resolved" ]; then
      echo "ERROR: argument rejected (not a regular file, e.g. a directory): $arg" >&2
      exit 3
    fi

    case "$(basename "$resolved")" in
      test-*.sh) : ;;
      *)
        echo "ERROR: argument rejected (does not match the tests/test-*.sh naming contract): $arg" >&2
        exit 3
        ;;
    esac

    local rel="${resolved#"$base_real"/}"
    NORMALIZED_ARGS+=("$rel")
  done
}

# ===========================================================================
# admission: プロセス系統除外
# ===========================================================================

EXCLUDE_SET=""

build_exclude_set() {
  local self=$$
  local snapshot
  snapshot="$(ps -axo pid=,ppid= 2>/dev/null)"
  local set=" $self "

  # Ancestor-only exclusion (self + the full ancestor chain up to pid 1).
  # A descendant-exclusion BFS previously lived here but was dead code on
  # every call path: build_exclude_set() runs from admission_check(), which
  # executes strictly BEFORE run_tests_in_snapshot() forks any test child
  # (see `main` below) -- at the time this function runs, self has no
  # descendants yet to exclude. Removed rather than kept as inert code
  # (docs/cycles/20260913_0059 VERIFY finding / B6 mini-iteration).
  local cur="$self" hops=0 ppid
  while [ "$hops" -lt "$MAX_PID_ANCESTOR_HOPS" ]; do
    hops=$((hops + 1))
    ppid="$(printf '%s\n' "$snapshot" | awk -v p="$cur" '$1==p{print $2; exit}')"
    [ -z "$ppid" ] && break
    case " $set " in *" $ppid "*) break ;; esac
    set="$set $ppid "
    cur="$ppid"
    [ "$cur" -le 1 ] 2>/dev/null && break
  done

  EXCLUDE_SET="$set"
}

is_excluded_pid() {
  case "$EXCLUDE_SET" in
    *" $1 "*) return 0 ;;
    *) return 1 ;;
  esac
}

# ===========================================================================
# admission: テストプロセス数
# ===========================================================================

PGREP_STATUS="" PGREP_MSG=""

eval_pgrep() {
  local raw rc
  raw="$(pgrep -f 'tests/test-' 2>&1)"; rc=$?

  if [ "$rc" -ge 2 ]; then
    PGREP_STATUS=skip
    PGREP_MSG="SKIP: process-count probe unavailable (pgrep rc=$rc); condition skipped"
    return 0
  fi
  if [ "$rc" -eq 1 ]; then
    PGREP_STATUS=ok
    PGREP_MSG=""
    return 0
  fi

  if [ -z "$raw" ]; then
    PGREP_STATUS=skip
    PGREP_MSG="SKIP: process-count probe returned empty output despite rc=0; condition skipped"
    return 0
  fi

  local bad=0 line
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    case "$line" in
      '' | *[!0-9]*) bad=1 ;;
    esac
  done <<< "$raw"
  if [ "$bad" -eq 1 ]; then
    PGREP_STATUS=skip
    PGREP_MSG="SKIP: process-count probe returned non-numeric output; condition skipped"
    return 0
  fi

  local count=0
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    is_excluded_pid "$line" || count=$((count + 1))
  done <<< "$raw"

  if [ "$count" -gt 0 ]; then
    PGREP_STATUS=block
    PGREP_MSG="BLOCK: test process count = $count (> 0, excluding self/ancestors)"
  else
    PGREP_STATUS=ok
    PGREP_MSG=""
  fi
}

admission_check() {
  eval_pgrep

  case "$PGREP_STATUS" in
    skip)
      echo "$PGREP_MSG" >&2
      ;;
    block)
      echo "$PGREP_MSG" >&2
      echo "ADMISSION BLOCK: one or more resource conditions are unsatisfied; not starting the run" >&2
      exit 2
      ;;
  esac
}

# ===========================================================================
# snapshot: source tree 境界 + 残留 snapshot の警告
# ===========================================================================

SAFE_TMPDIR=""

determine_safe_tmpdir() {
  local candidate="${TMPDIR:-/tmp}"
  candidate="${candidate%/}"
  [ -z "$candidate" ] && candidate="/tmp"

  local base_real cand_real
  base_real="$(cd "$BASE_DIR" && pwd -P)"
  cand_real="$(cd "$candidate" 2>/dev/null && pwd -P)"

  if [ -n "$cand_real" ]; then
    case "$cand_real" in
      "$base_real" | "$base_real"/*)
        echo "WARN: TMPDIR ($candidate) is inside the source repo; falling back to /tmp" >&2
        candidate="/tmp"
        ;;
    esac
  fi

  SAFE_TMPDIR="$candidate"
}

# startup_residue_scan: warns about (never deletes) leftover dev-crew-snap.*
# directories under the ACTUAL post-boundary-check SAFE_TMPDIR (never the raw
# $TMPDIR -- a repo-internal TMPDIR that fell back to /tmp must be scanned at
# /tmp, or a leftover seeded there would be silently missed). No age/owner
# guessing: a strong-terminated run's snapshot is reported, not auto-reaped
# (docs/cycles/20260916_1634 B-2, 「受容する: 強制終了後の残骸を自動削除し
# ない」). Existence-guarded glob, not `ls`, so zero leftovers produce zero
# stderr output (`ls` on a no-match glob prints "No such file or directory").
startup_residue_scan() {
  local base="$SAFE_TMPDIR"
  [ -d "$base" ] || return 0

  local entry
  for entry in "$base"/${SNAPSHOT_PREFIX}*; do
    [ -e "$entry" ] || continue
    echo "WARN: leftover snapshot directory (not deleted; a prior run may have been interrupted): $entry" >&2
  done
  return 0
}

# ===========================================================================
# snapshot の作成 (single attempt: no fingerprinting, no retry)
# ===========================================================================

# build_snapshot: copies BASE_DIR into a fresh snapshot directory under
# SAFE_TMPDIR. B removes the fingerprint three-way match and its retry
# protocol entirely (docs/cycles/20260916_1634 B: 「そもそも原子的コピーは
# 保証していなかった」) -- a single cp attempt, any failure of which
# (mkdir/cp) is a start-failure, not a test failure, hence exit 2.
#
# 受容する失敗 (docs/cycles/20260916_1634 B-2): コピー中に live tree の編集が
# 入ると、どの revision にも一致しない混成 snapshot の上でテストが走り得る。
# コピー完了後は frozen な snapshot を読むため、実行中の live tree 編集との
# 混読は防げる（これが本来の目的）。
build_snapshot() {
  SNAP="$(mktemp -d "${SAFE_TMPDIR}/${SNAPSHOT_PREFIX}XXXXXX" 2>/dev/null)"
  if [ -z "$SNAP" ] || [ ! -d "$SNAP" ]; then
    echo "ERROR: failed to create a snapshot directory under $SAFE_TMPDIR" >&2
    exit 2
  fi
  if ! mkdir -p "$SNAP/docs" "$SNAP/agents" 2>/dev/null; then
    echo "ERROR: failed to create the snapshot layout under $SNAP" >&2
    rm -rf "$SNAP" 2>/dev/null
    SNAP=""
    exit 2
  fi

  local cp_err
  if [ -f "$PARENT_DOC_SRC" ]; then
    cp_err="$(cp -p "$PARENT_DOC_SRC" "$SNAP/docs/test_architecture.md" 2>&1)"
    if [ $? -ne 0 ]; then
      echo "ERROR: failed to copy the parent doc into the snapshot: $cp_err" >&2
      rm -rf "$SNAP" 2>/dev/null
      SNAP=""
      exit 2
    fi
  fi

  cp_err="$(cp -Rp "$BASE_DIR" "$SNAP/agents/dev-crew" 2>&1)"
  if [ $? -ne 0 ]; then
    echo "ERROR: failed to copy the repo into the snapshot: $cp_err" >&2
    rm -rf "$SNAP" 2>/dev/null
    SNAP=""
    exit 2
  fi
}

# ===========================================================================
# 実行
# ===========================================================================

run_tests_in_snapshot() {
  local snap_dev="$SNAP/agents/dev-crew"
  local targets=()

  if [ "${#NORMALIZED_ARGS[@]}" -eq 0 ]; then
    local f
    for f in "$snap_dev"/tests/test-*.sh; do
      [ -f "$f" ] || continue
      targets+=("$f")
    done
  else
    # normalize_args() validated these against the LIVE tree, before
    # build_snapshot() ran; it proves nothing about the SNAPSHOT copy made
    # afterward. If the file is removed from the live tree in that window
    # (validated, then deleted before `cp -Rp` runs), the snapshot simply
    # never has it. Re-validate against the snapshot here and reject rather
    # than silently omit it -- an explicitly requested test that never ran
    # must never collapse into "0 executed, exit 0".
    local rel target
    for rel in "${NORMALIZED_ARGS[@]}"; do
      target="$snap_dev/$rel"
      if [ ! -f "$target" ]; then
        echo "ERROR: argument rejected (test not present in the snapshot; it may have been deleted from the live tree between argument validation and snapshot copy): $rel" >&2
        exit 3
      fi
      targets+=("$target")
    done
  fi

  if [ "${#targets[@]}" -eq 0 ]; then
    echo "ERROR: no test targets matched (tests/test-*.sh); refusing to report a vacuous PASS" >&2
    exit 3
  fi

  local f name rc
  for f in "${targets[@]}"; do
    if [ ! -f "$f" ]; then
      # Every entry in $targets already passed an existence check at
      # selection time (the glob branch's own check, or the snapshot
      # re-validation above for explicit args). The snapshot is immutable
      # for the rest of this run, so a target missing here means something
      # outside our control altered it after selection -- an infra anomaly,
      # not a normal "0 tests" case. Fail loudly instead of silently
      # shrinking PASS+FAIL below the selected count.
      echo "ERROR: test target vanished from the snapshot after selection (infra anomaly): $f" >&2
      exit 2
    fi
    name="$(basename "$f")"
    ( cd "$snap_dev" && exec bash "$f" ) > /dev/null 2>&1 < /dev/null &
    CHILD_PID=$!
    wait "$CHILD_PID"
    rc=$?
    CHILD_PID=""
    if [ "$rc" -eq 0 ]; then
      printf "  \033[32mPASS\033[0m %s\n" "$name"
      PASS=$((PASS + 1))
    else
      printf "  \033[31mFAIL\033[0m %s\n" "$name"
      FAIL=$((FAIL + 1))
      FAILED_TESTS+=("$name")
    fi
  done
}

# ===========================================================================
# main
# ===========================================================================

normalize_args "$@"
determine_safe_tmpdir
startup_residue_scan
build_exclude_set
admission_check
build_snapshot
run_tests_in_snapshot

echo ""
echo "=== Results ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "Failed tests:"
  for t in "${FAILED_TESTS[@]}"; do
    echo "  - $t"
  done
  exit 1
fi

exit 0
