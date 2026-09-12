#!/bin/bash
# run-tests.sh - dev-crew の正規テストランナー。
#
# 責務: (1) 引数正規化 + 拒否 (2) 資源 admission check (3) immutable snapshot
# 上での実行（3者照合 A==B==C） (4) 起動時の残留 snapshot 掃除
# (5) PASS/FAIL 集計・実行後 live tree 変化の advisory 報告。
#
# 設計: docs/cycles/20260913_0059_runner-admission-snapshot.md
#
# exit code 契約:
#   0 = 全テスト PASS
#   1 = 1 件以上 FAIL（既存契約、変更しない）
#   2 = admission BLOCK（資源条件不足）
#   3 = 引数拒否（repo 外パス / .. 脱出 / symlink 脱出 / tests/ 配下でない /
#       ディレクトリ / test-*.sh 命名でない / 不在 / 対象 0 件）
#   4 = snapshot 三者照合の再作成上限（3 回）超過（live tree が書き込み中と判断）
#   5 = インフラ障害（manifest 計算・snapshot コピーの失敗が再作成上限まで続いた、
#       または fifo/socket/device 等の特殊ファイルを検出した）。FAIL 件数とは無関係
#       であり、1（テスト失敗）と混同させない
#
# job control (`set -m`) は、SIGINT/SIGTERM を実行中の子テストへ転送する際に
# 子プロセスの trap を機能させるために必須（非 job-control 下では bash が
# 非同期コマンドの INT/QUIT を自動的に無視するため、子側の trap が発火しない
# ことを実測確認済み）。

set -uo pipefail
set -m

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
CONF_FILE="$BASE_DIR/.claude/test-serialization.json"
PARENT_DOC_SRC="$(cd "$BASE_DIR/../.." 2>/dev/null && pwd)/docs/test_architecture.md"

DEFAULT_K_LOAD=2
DEFAULT_MEM_MIN_MIB=3584
DEFAULT_SNAPSHOT_STALE_MIN=60
DEFAULT_WARN_ON_LIVE_CHANGES=true
MAX_SNAPSHOT_ATTEMPTS=3
SNAPSHOT_PREFIX="dev-crew-snap."
BYTES_PER_MIB=1048576
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
FINAL_SOURCE_MANIFEST=""

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
# config: .claude/test-serialization.json
# ===========================================================================

# get_num_key <key> <default> <rangecheck: gt0|ge0> <inttype: yes|no>
#
# `jq -r` stringifies a JSON number and a JSON string identically (both
# `"k_load": 2` and `"k_load": "2"` produce raw text "2"), so a bash-side
# regex check on the raw text cannot tell them apart. The type check MUST
# happen inside jq, against `.[$k] | type`, before the value is ever
# extracted as raw text. Integer-typed keys (mem_min_mib,
# snapshot_stale_minutes) additionally reject a non-integer number (e.g.
# 1.5) via `floor`.
get_num_key() {
  local key="$1" default="$2" rangecheck="$3" inttype="${4:-no}"
  local verdict
  verdict="$(jq -r --arg k "$key" --arg it "$inttype" '
    if (has($k) | not) or (.[$k] == null) then "missing"
    elif (.[$k] | type) != "number" then "badtype"
    elif ($it == "yes") and ((.[$k] | floor) != .[$k]) then "notint"
    else "ok"
    end
  ' "$CONF_FILE" 2>/dev/null)"

  case "$verdict" in
    missing)
      echo "WARN: config key '$key' missing; using default $default" >&2
      printf '%s' "$default"
      return 0
      ;;
    badtype)
      echo "WARN: config key '$key' has an invalid type (expected number, not e.g. a numeric-looking string); using default $default" >&2
      printf '%s' "$default"
      return 0
      ;;
    notint)
      echo "WARN: config key '$key' must be an integer (got a non-integer number); using default $default" >&2
      printf '%s' "$default"
      return 0
      ;;
    ok) : ;;
    *)
      echo "WARN: config key '$key' could not be evaluated; using default $default" >&2
      printf '%s' "$default"
      return 0
      ;;
  esac

  local raw
  raw="$(jq -r --arg k "$key" '.[$k]' "$CONF_FILE" 2>/dev/null)"

  local ok
  case "$rangecheck" in
    gt0) ok="$(awk -v v="$raw" 'BEGIN{print (v>0)?1:0}')" ;;
    ge0) ok="$(awk -v v="$raw" 'BEGIN{print (v>=0)?1:0}')" ;;
    *) ok=1 ;;
  esac
  if [ "$ok" != "1" ]; then
    echo "WARN: config key '$key' is out of range; using default $default" >&2
    printf '%s' "$default"
    return 0
  fi
  printf '%s' "$raw"
}

# get_bool_key <key> <default>
#
# Same jq-r stringification problem as get_num_key: a JSON string "false"
# and the JSON boolean false both print as raw text "false", so the type
# check must happen inside jq against `.[$k] | type`, not on the raw text.
get_bool_key() {
  local key="$1" default="$2"
  local verdict
  verdict="$(jq -r --arg k "$key" '
    if (has($k) | not) or (.[$k] == null) then "missing"
    elif (.[$k] | type) != "boolean" then "badtype"
    else "ok"
    end
  ' "$CONF_FILE" 2>/dev/null)"

  case "$verdict" in
    ok)
      jq -r --arg k "$key" '.[$k]' "$CONF_FILE" 2>/dev/null
      return 0
      ;;
    missing)
      echo "WARN: config key '$key' missing; using default $default" >&2
      ;;
    badtype)
      echo "WARN: config key '$key' has an invalid type (expected boolean, not e.g. the string \"false\"); using default $default" >&2
      ;;
    *)
      echo "WARN: config key '$key' could not be evaluated; using default $default" >&2
      ;;
  esac
  printf '%s' "$default"
}

load_config() {
  K_LOAD="$DEFAULT_K_LOAD"
  MEM_MIN_MIB="$DEFAULT_MEM_MIN_MIB"
  SNAPSHOT_STALE_MIN="$DEFAULT_SNAPSHOT_STALE_MIN"
  WARN_ON_LIVE_CHANGES="$DEFAULT_WARN_ON_LIVE_CHANGES"

  if ! command -v jq >/dev/null 2>&1; then
    echo "WARN: jq not found on PATH; using default test-serialization config for all keys" >&2
    return 0
  fi

  if [ ! -f "$CONF_FILE" ]; then
    return 0
  fi

  if ! jq -e . "$CONF_FILE" >/dev/null 2>&1; then
    echo "WARN: $CONF_FILE is not valid JSON; using default config for all keys" >&2
    return 0
  fi

  K_LOAD="$(get_num_key k_load "$DEFAULT_K_LOAD" gt0 no)"
  MEM_MIN_MIB="$(get_num_key mem_min_mib "$DEFAULT_MEM_MIN_MIB" ge0 yes)"
  SNAPSHOT_STALE_MIN="$(get_num_key snapshot_stale_minutes "$DEFAULT_SNAPSHOT_STALE_MIN" ge0 yes)"
  WARN_ON_LIVE_CHANGES="$(get_bool_key warn_on_live_changes "$DEFAULT_WARN_ON_LIVE_CHANGES")"
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
# admission: 3 条件の評価
# ===========================================================================

PGREP_STATUS="" PGREP_MSG=""
LOAD_STATUS="" LOAD_MSG=""
MEM_STATUS="" MEM_MSG=""

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

eval_load() {
  local raw rc
  raw="$(sysctl -n vm.loadavg 2>&1)"; rc=$?
  if [ "$rc" -ge 2 ]; then
    LOAD_STATUS=skip
    LOAD_MSG="SKIP: load probe unavailable (sysctl vm.loadavg rc=$rc); condition skipped"
    return 0
  fi

  local load1
  load1="$(printf '%s' "$raw" | grep -Eo '\-?[0-9]+\.[0-9]+' | head -1)"
  if [ -z "$load1" ]; then
    LOAD_STATUS=skip
    LOAD_MSG="SKIP: load probe returned non-numeric/empty output; condition skipped"
    return 0
  fi

  local ncpu_raw ncpu_rc
  ncpu_raw="$(sysctl -n hw.ncpu 2>&1)"; ncpu_rc=$?
  if [ "$ncpu_rc" -ge 2 ] || ! printf '%s' "$ncpu_raw" | grep -Eq '^[0-9]+$'; then
    LOAD_STATUS=skip
    LOAD_MSG="SKIP: load probe unavailable (ncpu probe failed, rc=$ncpu_rc); condition skipped"
    return 0
  fi

  local load_max ge
  load_max="$(awk -v n="$ncpu_raw" -v k="$K_LOAD" 'BEGIN{printf "%.6f", n*k}')"
  ge="$(awk -v a="$load1" -v b="$load_max" 'BEGIN{print (a>=b)?1:0}')"
  if [ "$ge" = "1" ]; then
    LOAD_STATUS=block
    LOAD_MSG="BLOCK: load1 = $load1 >= load_max $load_max (ncpu=$ncpu_raw, k_load=$K_LOAD)"
  else
    LOAD_STATUS=ok
    LOAD_MSG=""
  fi
}

eval_mem() {
  local raw rc
  raw="$(vm_stat 2>&1)"; rc=$?
  if [ "$rc" -ge 2 ]; then
    MEM_STATUS=skip
    MEM_MSG="SKIP: memory probe unavailable (vm_stat rc=$rc); condition skipped"
    return 0
  fi

  local pagesize free_pages inactive_pages
  pagesize="$(printf '%s' "$raw" | grep -Eo 'page size of [0-9]+ bytes' | grep -Eo '[0-9]+' | head -1)"
  free_pages="$(printf '%s' "$raw" | grep -Eo 'Pages free:[[:space:]]*[0-9]+' | grep -Eo '[0-9]+' | head -1)"
  inactive_pages="$(printf '%s' "$raw" | grep -Eo 'Pages inactive:[[:space:]]*[0-9]+' | grep -Eo '[0-9]+' | head -1)"

  if [ -z "$pagesize" ] || [ -z "$free_pages" ] || [ -z "$inactive_pages" ]; then
    MEM_STATUS=skip
    MEM_MSG="SKIP: memory probe returned non-numeric/empty output; condition skipped"
    return 0
  fi

  local free_bytes threshold_bytes le free_mib
  free_bytes="$(awk -v f="$free_pages" -v i="$inactive_pages" -v p="$pagesize" 'BEGIN{printf "%.0f", (f+i)*p}')"
  threshold_bytes="$(awk -v m="$MEM_MIN_MIB" -v u="$BYTES_PER_MIB" 'BEGIN{printf "%.0f", m*u}')"
  le="$(awk -v a="$free_bytes" -v b="$threshold_bytes" 'BEGIN{print (a<=b)?1:0}')"
  free_mib="$(awk -v b="$free_bytes" -v u="$BYTES_PER_MIB" 'BEGIN{printf "%.1f", b/u}')"

  if [ "$le" = "1" ]; then
    MEM_STATUS=block
    MEM_MSG="BLOCK: free memory = ${free_mib} MiB <= mem_min_mib ${MEM_MIN_MIB} MiB"
  else
    MEM_STATUS=ok
    MEM_MSG=""
  fi
}

admission_check() {
  eval_pgrep
  eval_load
  eval_mem

  local unsatisfied=0 report=""

  if [ "$PGREP_STATUS" = "skip" ]; then
    echo "$PGREP_MSG" >&2
  elif [ "$PGREP_STATUS" = "block" ]; then
    unsatisfied=1
    report="${report}${PGREP_MSG}
"
  fi

  if [ "$LOAD_STATUS" = "skip" ]; then
    echo "$LOAD_MSG" >&2
  elif [ "$LOAD_STATUS" = "block" ]; then
    unsatisfied=1
    report="${report}${LOAD_MSG}
"
  fi

  if [ "$MEM_STATUS" = "skip" ]; then
    echo "$MEM_MSG" >&2
  elif [ "$MEM_STATUS" = "block" ]; then
    unsatisfied=1
    report="${report}${MEM_MSG}
"
  fi

  if [ "$unsatisfied" -eq 1 ]; then
    printf '%s' "$report" >&2
    echo "ADMISSION BLOCK: one or more resource conditions are unsatisfied; not starting the run" >&2
    exit 2
  fi
}

# ===========================================================================
# snapshot の後始末 (cleanup)
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

is_stale() {
  local path="$1"
  local mtime now age_min
  mtime="$(stat -f '%m' "$path" 2>/dev/null)" || return 1
  now="$(date +%s)"
  age_min="$(awk -v m="$mtime" -v n="$now" 'BEGIN{print (n-m)/60}')"
  awk -v a="$age_min" -v t="$SNAPSHOT_STALE_MIN" 'BEGIN{exit !(a>=t)}'
}

startup_cleanup() {
  local base="$SAFE_TMPDIR"
  [ -d "$base" ] || return 0

  local entry
  for entry in "$base"/${SNAPSHOT_PREFIX}*; do
    [ -e "$entry" ] || continue

    if [ -L "$entry" ]; then
      continue
    fi
    if [ ! -d "$entry" ]; then
      continue
    fi

    if [ ! -r "$entry" ] || [ ! -x "$entry" ]; then
      # An entry we cannot even inspect (permission denied) must NOT be
      # guessed at: deleting it on the assumption that "unreadable == dead"
      # can destroy a live, in-use snapshot we simply failed to stat. Warn
      # and leave it in place; a genuine dead/stale one will still be caught
      # by a later run once its permissions/owner become inspectable.
      echo "WARN: cannot inspect snapshot candidate (permission denied); leaving it in place: $entry" >&2
      continue
    fi

    local owner="$entry/.owner"
    local should_delete=0
    if [ -f "$owner" ]; then
      local pid
      pid="$(awk -F= '/^pid=/{print $2; exit}' "$owner" 2>/dev/null)"
      if printf '%s' "$pid" | grep -Eq '^[0-9]+$'; then
        if kill -0 "$pid" 2>/dev/null; then
          # `kill -0` alone only proves SOME process holds this PID right
          # now, not that it is the original owner -- PIDs get reused. Cross
          # -check the `.owner` start-time token (written at snapshot
          # creation) against the live process's actual start time; a
          # mismatch means the original owner already exited and the PID
          # was reused by an unrelated process, so the snapshot is orphaned.
          local start_token cur_start
          start_token="$(awk -F= '/^start=/{print $2; exit}' "$owner" 2>/dev/null)"
          cur_start="$(ps -o lstart= -p "$pid" 2>/dev/null | tr -s ' ' '_')"
          if [ -n "$start_token" ] && [ "$start_token" != "unknown" ] \
             && [ -n "$cur_start" ] && [ "$start_token" != "$cur_start" ]; then
            should_delete=1
          else
            should_delete=0
          fi
        else
          should_delete=1
        fi
      else
        is_stale "$owner" && should_delete=1
      fi
    else
      is_stale "$entry" && should_delete=1
    fi

    if [ "$should_delete" -eq 1 ]; then
      if ! rm -rf "$entry" 2>/dev/null; then
        echo "WARN: failed to remove stale snapshot: $entry" >&2
      fi
    fi
  done
}

# ===========================================================================
# manifest / snapshot 一貫性 (D3)
# ===========================================================================

# compute_manifest <repo> <parent_doc>
#
# Every command whose result feeds the manifest (find / stat / shasum / git)
# is checked explicitly. A silently-swallowed failure here (the pre-fix
# behavior: `stat ... || echo 0`, `shasum ... 2>/dev/null`, an uncredited
# `find` under process substitution) can make an unreadable subtree vanish
# identically from manifest A, B and C, letting a corrupted/incomplete
# snapshot pass the three-way check as if it were consistent. Any such
# failure now aborts THIS manifest computation (return 1, or return 2 for a
# special file, which is deterministic and not worth retrying) rather than
# silently degrading the manifest.
#
# stat/shasum are BATCHED across all regular files (one process each, not
# one per file): measured 4.63s->0.04s (shasum) and 0.75s->0.01s (stat) for
# 452 files (docs/cycles/20260913_0059 W5). Both batch calls read the same
# NUL-delimited file list in the same order (xargs does not reorder or
# parallelize by default), so output line i of each always corresponds to
# reg_paths[i] -- correlated by POSITION, never by re-parsing a filename out
# of stat/shasum output (which would break on filenames containing spaces).
compute_manifest() {
  local repo="$1" parent_doc="$2"
  local out=""

  if [ -f "$parent_doc" ]; then
    local h
    h="$(shasum -a 256 "$parent_doc" 2>&1)"
    if [ $? -ne 0 ]; then
      echo "ERROR: shasum failed on parent doc $parent_doc: $h" >&2
      return 1
    fi
    h="${h%% *}"
    out="${out}$(printf 'DOC\t%s\t%s' "test_architecture.md" "$h")"$'\n'
  fi

  local filelist
  filelist="$(mktemp "${SAFE_TMPDIR:-${TMPDIR:-/tmp}}/dev-crew-manifest.XXXXXX" 2>/dev/null)"
  if [ -z "$filelist" ]; then
    echo "ERROR: mktemp failed while building manifest for $repo" >&2
    return 1
  fi

  local find_err find_rc
  find_err="$(find "$repo" -mindepth 1 \( -path "$repo/.git" -o -path "$repo/.git/*" \) -prune -o -print0 2>&1 1>"$filelist")"
  find_rc=$?
  if [ "$find_rc" -ne 0 ]; then
    echo "ERROR: find failed while scanning $repo for manifest (rc=$find_rc): $find_err" >&2
    rm -f "$filelist"
    return 1
  fi

  local reg_list sym_list
  reg_list="$(mktemp "${SAFE_TMPDIR:-${TMPDIR:-/tmp}}/dev-crew-manifest.XXXXXX" 2>/dev/null)"
  sym_list="$(mktemp "${SAFE_TMPDIR:-${TMPDIR:-/tmp}}/dev-crew-manifest.XXXXXX" 2>/dev/null)"
  if [ -z "$reg_list" ] || [ -z "$sym_list" ]; then
    echo "ERROR: mktemp failed while building manifest for $repo" >&2
    rm -f "$filelist" "$reg_list" "$sym_list"
    return 1
  fi

  local reg_paths=() special=0 p
  while IFS= read -r -d '' p; do
    if [ -L "$p" ]; then
      printf '%s\0' "$p" >> "$sym_list"
    elif [ -f "$p" ]; then
      printf '%s\0' "$p" >> "$reg_list"
      reg_paths+=("$p")
    elif [ -d "$p" ]; then
      :
    else
      special=1
    fi
  done < "$filelist"
  rm -f "$filelist"

  if [ "$special" -eq 1 ]; then
    echo "ERROR: unsupported special file (fifo/socket/device) found under $repo" >&2
    rm -f "$reg_list" "$sym_list"
    return 2
  fi

  # symlinks: per-entry (typically few; readlink has no useful batch form).
  local target th
  while IFS= read -r -d '' p; do
    local rel="${p#"$repo"/}"
    target="$(readlink "$p" 2>&1)"
    if [ $? -ne 0 ]; then
      echo "ERROR: readlink failed on symlink $p: $target" >&2
      rm -f "$reg_list" "$sym_list"
      return 1
    fi
    th="$(printf '%s' "$target" | shasum -a 256)"
    if [ $? -ne 0 ]; then
      echo "ERROR: shasum failed hashing the symlink target for $p" >&2
      rm -f "$reg_list" "$sym_list"
      return 1
    fi
    th="${th%% *}"
    out="${out}$(printf 'F\t%s\tsymlink\t%s\t%s' "$rel" "${#target}" "$th")"$'\n'
  done < "$sym_list"
  rm -f "$sym_list"

  if [ "${#reg_paths[@]}" -gt 0 ]; then
    local stat_out hash_out
    stat_out="$(mktemp "${SAFE_TMPDIR:-${TMPDIR:-/tmp}}/dev-crew-manifest.XXXXXX" 2>/dev/null)"
    hash_out="$(mktemp "${SAFE_TMPDIR:-${TMPDIR:-/tmp}}/dev-crew-manifest.XXXXXX" 2>/dev/null)"
    if [ -z "$stat_out" ] || [ -z "$hash_out" ]; then
      echo "ERROR: mktemp failed while building manifest for $repo" >&2
      rm -f "$reg_list" "$stat_out" "$hash_out"
      return 1
    fi

    local stat_err stat_rc
    stat_err="$(xargs -0 stat -f '%Lp %z' < "$reg_list" 2>&1 1>"$stat_out")"
    stat_rc=$?
    if [ "$stat_rc" -ne 0 ]; then
      echo "ERROR: stat failed while building manifest for $repo (rc=$stat_rc): $stat_err" >&2
      rm -f "$reg_list" "$stat_out" "$hash_out"
      return 1
    fi

    local hash_err hash_rc
    hash_err="$(xargs -0 shasum -a 256 < "$reg_list" 2>&1 1>"$hash_out")"
    hash_rc=$?
    if [ "$hash_rc" -ne 0 ]; then
      echo "ERROR: shasum failed while building manifest for $repo (rc=$hash_rc): $hash_err" >&2
      rm -f "$reg_list" "$stat_out" "$hash_out"
      return 1
    fi

    local stat_n hash_n
    stat_n=$(wc -l < "$stat_out" | tr -d ' ')
    hash_n=$(wc -l < "$hash_out" | tr -d ' ')
    if [ "$stat_n" -ne "${#reg_paths[@]}" ] || [ "$hash_n" -ne "${#reg_paths[@]}" ]; then
      echo "ERROR: manifest batch stat/shasum line count mismatch for $repo (files=${#reg_paths[@]} stat_lines=$stat_n hash_lines=$hash_n)" >&2
      rm -f "$reg_list" "$stat_out" "$hash_out"
      return 1
    fi

    local idx=0 mode size hline fh rel
    while IFS=' ' read -r -u 3 mode size && IFS= read -r -u 4 hline; do
      rel="${reg_paths[$idx]#"$repo"/}"
      fh="${hline%% *}"
      out="${out}$(printf 'F\t%s\t%s\t%s\t%s' "$rel" "$mode" "$size" "$fh")"$'\n'
      idx=$((idx + 1))
    done 3<"$stat_out" 4<"$hash_out"
    rm -f "$stat_out" "$hash_out"
  fi
  rm -f "$reg_list"

  if [ -d "$repo/.git" ]; then
    local gh grc
    gh="$(git -C "$repo" ls-files -z | shasum -a 256)"
    grc=$?
    if [ "$grc" -ne 0 ]; then
      echo "ERROR: git ls-files failed while building manifest for $repo (rc=$grc)" >&2
      return 1
    fi
    gh="${gh%% *}"
    out="${out}$(printf 'GIT\t%s' "$gh")"$'\n'
  fi

  printf '%s' "$out" | LC_ALL=C sort
}

write_owner_metadata() {
  local snap="$1" start_token
  start_token="$(ps -o lstart= -p $$ 2>/dev/null | tr -s ' ' '_')"
  [ -z "$start_token" ] && start_token="unknown"
  printf 'pid=%s\nstart=%s\ncreated=%s\n' "$$" "$start_token" "$(date +%s)" > "$snap/.owner"
}

# compute_manifest_or_fail <repo> <parent_doc> <out_var>
# A/B/C all need the identical "compute failed -> report it and let the
# caller decide whether to retry" handling; this de-triplicates it. Returns
# 0 on success (result written to $out_var via `printf -v`, not a nameref:
# the repo's macOS bash is 3.2, which predates nameref support / bash 4.3+),
# 2 if compute_manifest hit a deterministic, non-retryable condition (a
# special file), 1 for anything else (transient: a stat/shasum/find/git
# failure, possibly a file that vanished mid-race -- retrying is exactly
# how the surrounding three-way check already handles a moving live tree).
compute_manifest_or_fail() {
  local repo="$1" parent_doc="$2" out_var="$3" result rc
  result="$(compute_manifest "$repo" "$parent_doc")"
  rc=$?
  if [ "$rc" -ne 0 ]; then
    return "$rc"
  fi
  printf -v "$out_var" '%s' "$result"
  return 0
}

build_snapshot() {
  local attempt=0 manifest_A manifest_B manifest_C
  # Tracks WHY the retry loop is discarding attempts, so that if the cap is
  # exceeded we report the right failure class: "mismatch" (live tree kept
  # changing -> exit 4, existing contract) vs "infra" (find/stat/shasum/cp
  # kept failing -> exit 5, a NEW distinct code so this is never
  # misreported as "1 or more tests FAILED", per the exit-code contract).
  local last_reason="mismatch"

  while [ "$attempt" -lt "$MAX_SNAPSHOT_ATTEMPTS" ]; do
    attempt=$((attempt + 1))

    SNAP="$(mktemp -d "${SAFE_TMPDIR}/${SNAPSHOT_PREFIX}XXXXXX" 2>/dev/null)"
    if [ -z "$SNAP" ] || [ ! -d "$SNAP" ]; then
      echo "ERROR: failed to create a snapshot directory under $SAFE_TMPDIR" >&2
      exit 5
    fi
    if ! mkdir -p "$SNAP/docs" "$SNAP/agents" 2>/dev/null; then
      echo "ERROR: failed to create the snapshot layout under $SNAP" >&2
      rm -rf "$SNAP" 2>/dev/null
      SNAP=""
      exit 5
    fi

    # Written immediately after the snapshot directory exists (D3 lifecycle:
    # "snapshot 作成直後に書く") -- previously this happened after manifest_A
    # and the cp, so a crash mid-copy left a snapshot with no owner metadata
    # at all, indistinguishable from "never got an owner" for up to
    # snapshot_stale_minutes. Placed here it is never inside repo/.git-free
    # of the manifest scope: `.owner` lives at $SNAP/.owner, a sibling of
    # $SNAP/agents (manifest B's root is $SNAP/agents/dev-crew), so it was
    # already outside every manifest's scan regardless of write order.
    write_owner_metadata "$SNAP"

    compute_manifest_or_fail "$BASE_DIR" "$PARENT_DOC_SRC" manifest_A
    local cmf_rc=$?
    if [ "$cmf_rc" -ne 0 ]; then
      rm -rf "$SNAP" 2>/dev/null
      SNAP=""
      [ "$cmf_rc" -eq 2 ] && exit 5
      last_reason="infra"
      echo "WARN: manifest computation failed on attempt $attempt (source, pre-copy); discarding this snapshot attempt" >&2
      continue
    fi

    if [ -n "${DEV_CREW_TEST_HOOK_BEFORE_COPY:-}" ] && [ -x "${DEV_CREW_TEST_HOOK_BEFORE_COPY}" ]; then
      "$DEV_CREW_TEST_HOOK_BEFORE_COPY" "$SNAP" || true
    fi

    local cp_err
    if [ -f "$PARENT_DOC_SRC" ]; then
      cp_err="$(cp -p "$PARENT_DOC_SRC" "$SNAP/docs/test_architecture.md" 2>&1)"
      if [ $? -ne 0 ]; then
        rm -rf "$SNAP" 2>/dev/null
        SNAP=""
        last_reason="infra"
        echo "WARN: failed to copy the parent doc into the snapshot on attempt $attempt (a copy failure -- distinct from a live-tree-changed manifest mismatch): $cp_err" >&2
        continue
      fi
    fi
    cp_err="$(cp -Rp "$BASE_DIR" "$SNAP/agents/dev-crew" 2>&1)"
    if [ $? -ne 0 ]; then
      rm -rf "$SNAP" 2>/dev/null
      SNAP=""
      last_reason="infra"
      echo "WARN: failed to copy the repo into the snapshot on attempt $attempt (a copy failure -- distinct from a live-tree-changed manifest mismatch): $cp_err" >&2
      continue
    fi

    if [ -n "${DEV_CREW_TEST_HOOK_AFTER_COPY:-}" ] && [ -x "${DEV_CREW_TEST_HOOK_AFTER_COPY}" ]; then
      "$DEV_CREW_TEST_HOOK_AFTER_COPY" "$SNAP" || true
    fi

    compute_manifest_or_fail "$SNAP/agents/dev-crew" "$SNAP/docs/test_architecture.md" manifest_B
    cmf_rc=$?
    if [ "$cmf_rc" -ne 0 ]; then
      rm -rf "$SNAP" 2>/dev/null
      SNAP=""
      [ "$cmf_rc" -eq 2 ] && exit 5
      last_reason="infra"
      echo "WARN: manifest computation failed on attempt $attempt (snapshot); discarding this snapshot attempt" >&2
      continue
    fi

    compute_manifest_or_fail "$BASE_DIR" "$PARENT_DOC_SRC" manifest_C
    cmf_rc=$?
    if [ "$cmf_rc" -ne 0 ]; then
      rm -rf "$SNAP" 2>/dev/null
      SNAP=""
      [ "$cmf_rc" -eq 2 ] && exit 5
      last_reason="infra"
      echo "WARN: manifest computation failed on attempt $attempt (source, post-copy); discarding this snapshot attempt" >&2
      continue
    fi

    if [ "$manifest_A" = "$manifest_B" ] && [ "$manifest_B" = "$manifest_C" ]; then
      FINAL_SOURCE_MANIFEST="$manifest_C"
      return 0
    fi

    last_reason="mismatch"
    echo "WARN: snapshot manifest mismatch on attempt $attempt (A/B/C differ); rebuilding" >&2
    rm -rf "$SNAP" 2>/dev/null
    SNAP=""
  done

  if [ "$last_reason" = "infra" ]; then
    echo "ERROR: snapshot 作成に必要な操作（manifest 計算・コピー）が ${MAX_SNAPSHOT_ATTEMPTS} 回連続で失敗しました。live tree の変化ではなくインフラ障害（権限・ディスク逼迫等）の可能性があります。直前の WARN 行を確認してください。" >&2
    exit 5
  fi

  echo "ERROR: snapshot 再作成の上限(${MAX_SNAPSHOT_ATTEMPTS}回)を超過しました。コピー中に live tree が書き込み中の状態が続いています。書き込み中のプロセスを止めてから再実行してください。" >&2
  exit 4
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
    local rel
    for rel in "${NORMALIZED_ARGS[@]}"; do
      targets+=("$snap_dev/$rel")
    done
  fi

  if [ "${#targets[@]}" -eq 0 ]; then
    echo "ERROR: no test targets matched (tests/test-*.sh); refusing to report a vacuous PASS" >&2
    exit 3
  fi

  local f name rc
  for f in "${targets[@]}"; do
    [ -f "$f" ] || continue
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

report_live_changes() {
  local before="$1" after
  after="$(compute_manifest "$BASE_DIR" "$PARENT_DOC_SRC")"
  if [ $? -ne 0 ]; then
    # Advisory only: a failure recomputing the post-run manifest must not
    # turn into a false "live tree changed" report, and must not touch the
    # exit code (that is still governed solely by PASS/FAIL, per contract).
    echo "WARNING: could not recompute the live-tree manifest after the run; live-change advisory skipped (exit code unaffected)." >&2
    return 0
  fi

  if [ "$before" = "$after" ]; then
    echo "Live tree: no changes detected during the run (unchanged)."
    return 0
  fi

  [ "$WARN_ON_LIVE_CHANGES" != "true" ] && return 0

  echo "WARNING: live tree changed during the run (advisory only; does not affect exit code):"
  diff <(printf '%s\n' "$before") <(printf '%s\n' "$after") 2>/dev/null \
    | grep -E '^[<>]' \
    | awk -F'\t' '{ if ($1 ~ /GIT$/) print "(git ls-files state changed)"; else print $2 }' \
    | sort -u \
    | while IFS= read -r p; do
        [ -n "$p" ] && echo "  - $p"
      done
}

# ===========================================================================
# main
# ===========================================================================

if [ -n "${DEV_CREW_RUNNER_LIB_ONLY:-}" ]; then
  # Test-only escape hatch (parallel to DEV_CREW_TEST_HOOK_*): lets a test
  # `source` this file to unit-test a function (e.g. build_exclude_set /
  # is_excluded_pid against a fabricated `ps` table) without running the
  # main sequence below.
  #
  # Caveat: this guard only skips the main sequence below. `set -uo
  # pipefail` / `set -m` and the EXIT/TERM/INT/HUP traps above are
  # unconditional top-of-file statements, so sourcing this file still
  # applies them to the CALLER's shell (harmless for TC-45's disposable
  # inner-script sourcing, but a future reuse of this guard to unit-test a
  # different function in a long-lived shell could silently overwrite that
  # shell's own `set -m` / traps).
  return 0 2>/dev/null || exit 0
fi

normalize_args "$@"
load_config
determine_safe_tmpdir
startup_cleanup
build_exclude_set
admission_check
build_snapshot
run_tests_in_snapshot
report_live_changes "$FINAL_SOURCE_MANIFEST"

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
