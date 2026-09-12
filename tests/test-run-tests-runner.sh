#!/bin/bash
# test-run-tests-runner.sh - run-tests.sh admission + immutable snapshot tests
# TC-01~TC-46 + TC-04b/25b/25c/27b/27c/29b/35b (57 total). All fixture-based; the real
# tests/ suite is NEVER invoked from inside this file (that would recurse into
# run-tests.sh's own full-suite execution — see docs/cycles/20260913_0059).
#
# Fixture design (per Cycle doc fixture 設計 section):
#   - subject = a COPY of run-tests.sh under a mktemp'd fixture root, never the live one
#   - dummy test(s) only under the fixture tests/, never the real tests/ tree
#   - fixture-local .claude/test-serialization.json
#   - fixture-local TMPDIR passed via `env TMPDIR=...`, a SIBLING of the fixture
#     source tree (D3: "${TMPDIR} が source repo 内を指す場合は拒否" — TMPDIR must
#     not be nested inside the copied repo)
#   - probes (pgrep/sysctl/vm_stat) faked via a PATH-prepended shim directory that
#     defaults to REAL passthrough unless a control file requests fake/absent
#
# Invented contracts (no prior contract exists; GREEN must implement to match):
#   - exit code classes: 0=PASS, 1=FAIL (existing, unchanged), 2=admission BLOCK,
#     3=argument rejection, 4=snapshot manifest retry exceeded. Kept pairwise
#     distinct so a lazy blanket `exit 1` cannot satisfy these tests (TC-24 dist.).
#   - `.owner` snapshot metadata: text file with lines `pid=<PID>` `start=<token>`
#     `created=<epoch>` (TC-28~35 read/write against this shape via fixture control).
#   - probe "absent" == shim exits rc=127 (>=2). We cannot remove /usr/bin from PATH
#     inside this sandbox, so "absent" and "rc>=2" collapse to the same fixture
#     mechanism; both are exercised as literal rc values, which is harmless because
#     D2 defines both as the same "skip this condition" outcome (TC-08).
#
# Given/When/Then is written inline as a comment immediately above each TC block.

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== run-tests.sh Runner (admission + snapshot) Tests ==="

# ---------------------------------------------------------------------------
# Fixture bookkeeping (cleaned up unconditionally, even mid-TC failure)
# ---------------------------------------------------------------------------
ALL_FIX=()
ALL_SLEEP_PIDS=()

cleanup_all() {
  local p d
  for p in "${ALL_SLEEP_PIDS[@]:-}"; do
    [ -n "$p" ] && kill -KILL "$p" >/dev/null 2>&1 || true
  done
  for d in "${ALL_FIX[@]:-}"; do
    [ -n "$d" ] || continue
    chmod -R u+rwx "$d" >/dev/null 2>&1 || true
    rm -rf "$d" >/dev/null 2>&1 || true
  done
}
trap cleanup_all EXIT INT TERM

# ---------------------------------------------------------------------------
# jq-absence farm (TC-12): a directory of symlinks mirroring every standard
# system bin dir EXCEPT jq, so that PATH="$F_BIN:$NOJQ_BIN" (a full
# replacement of $PATH, not an append) makes jq genuinely unresolvable while
# every other tool the subject needs (bash, awk, sed, mktemp, shasum, ...)
# still resolves. Built once, shared across TCs.
# ---------------------------------------------------------------------------
NOJQ_BIN="$(mktemp -d)"
ALL_FIX+=("$NOJQ_BIN")
for d in /usr/bin /bin /usr/sbin /sbin; do
  [ -d "$d" ] || continue
  for f in "$d"/*; do
    [ -e "$f" ] || continue
    b="$(basename "$f")"
    [ "$b" = "jq" ] && continue
    [ -e "$NOJQ_BIN/$b" ] && continue
    ln -s "$f" "$NOJQ_BIN/$b" 2>/dev/null || true
  done
done

# ---------------------------------------------------------------------------
# Fixture construction
# ---------------------------------------------------------------------------
# new_fixture: builds a fresh isolated fixture tree and sets:
#   F_ROOT F_REPO F_DEV F_TMPBASE F_BIN F_CTL
# Layout:
#   F_ROOT/
#     repo-root/docs/test_architecture.md          (parent-of-parent doc, per D3 layout)
#     repo-root/agents/dev-crew/ = F_DEV            (copy of run-tests.sh + dummy test)
#     tmpbase/                   = F_TMPBASE         (sibling TMPDIR, NOT inside repo-root)
#     bin/                       = F_BIN             (PATH-shimmed pgrep/sysctl/vm_stat)
#     ctl/                       = F_CTL             (shim control files + evidence, outside repo-root)
new_fixture() {
  F_ROOT="$(mktemp -d)"
  ALL_FIX+=("$F_ROOT")
  F_REPO="$F_ROOT/repo-root"
  F_DEV="$F_REPO/agents/dev-crew"
  F_TMPBASE="$F_ROOT/tmpbase"
  F_BIN="$F_ROOT/bin"
  F_CTL="$F_ROOT/ctl"
  mkdir -p "$F_REPO/docs" "$F_DEV/tests" "$F_DEV/.claude" "$F_TMPBASE" "$F_BIN" "$F_CTL"

  printf 'fixture parent doc (stand-in for docs/test_architecture.md)\n' > "$F_REPO/docs/test_architecture.md"

  cp "$BASE_DIR/run-tests.sh" "$F_DEV/run-tests.sh"
  chmod +x "$F_DEV/run-tests.sh"

  cat > "$F_DEV/tests/test-zz-dummy.sh" <<'DUMMY'
#!/bin/bash
# Fixture dummy test: records its resolved BASE_DIR as evidence (so the outer
# test can tell whether it ran against the live fixture tree or a snapshot
# copy), then exits 0 (PASS). Never touches the real repo tests/.
set -euo pipefail
D="$(cd "$(dirname "$0")/.." && pwd)"
if [ -n "${DCRUN_EVIDENCE:-}" ]; then
  printf '%s\n' "$D" >> "$DCRUN_EVIDENCE/where"
fi
# Marker left relative to wherever this script actually resolved to run from
# (live fixture tree vs. a snapshot copy). Used by TC-20 to prove the live
# tree is never mutated / executed directly.
touch "$D/tests/.executed-marker" 2>/dev/null || true
exit 0
DUMMY
  chmod +x "$F_DEV/tests/test-zz-dummy.sh"

  cat > "$F_DEV/.claude/test-serialization.json" <<'CONF'
{"k_load": 2, "mem_min_mib": 3584, "snapshot_stale_minutes": 60, "warn_on_live_changes": true}
CONF

  # --- PATH shims: default to REAL passthrough; a control file switches a
  # given probe to "fake" (canned rc/output) or "absent" (rc=127) ---
  cat > "$F_BIN/pgrep" <<'SHIM'
#!/bin/bash
CTL="${DCRUN_CTL:?DCRUN_CTL not set}"
mode="real"
[ -f "$CTL/pgrep.mode" ] && mode="$(cat "$CTL/pgrep.mode")"
case "$mode" in
  absent) exit 127 ;;
  fake)
    rc=0
    [ -f "$CTL/pgrep.rc" ] && rc="$(cat "$CTL/pgrep.rc")"
    [ -f "$CTL/pgrep.out" ] && cat "$CTL/pgrep.out"
    exit "$rc"
    ;;
  *) exec /usr/bin/pgrep "$@" ;;
esac
SHIM

  cat > "$F_BIN/sysctl" <<'SHIM'
#!/bin/bash
CTL="${DCRUN_CTL:?DCRUN_CTL not set}"
key="${2:-}"
safe="$(printf '%s' "$key" | tr '.' '_')"
mode="real"
[ -f "$CTL/sysctl_${safe}.mode" ] && mode="$(cat "$CTL/sysctl_${safe}.mode")"
case "$mode" in
  absent) exit 127 ;;
  fake)
    rc=0
    [ -f "$CTL/sysctl_${safe}.rc" ] && rc="$(cat "$CTL/sysctl_${safe}.rc")"
    [ -f "$CTL/sysctl_${safe}.out" ] && cat "$CTL/sysctl_${safe}.out"
    exit "$rc"
    ;;
  *) exec /usr/sbin/sysctl "$@" ;;
esac
SHIM

  cat > "$F_BIN/vm_stat" <<'SHIM'
#!/bin/bash
CTL="${DCRUN_CTL:?DCRUN_CTL not set}"
mode="real"
[ -f "$CTL/vm_stat.mode" ] && mode="$(cat "$CTL/vm_stat.mode")"
case "$mode" in
  absent) exit 127 ;;
  fake)
    rc=0
    [ -f "$CTL/vm_stat.rc" ] && rc="$(cat "$CTL/vm_stat.rc")"
    [ -f "$CTL/vm_stat.out" ] && cat "$CTL/vm_stat.out"
    exit "$rc"
    ;;
  *) exec /usr/bin/vm_stat ;;
esac
SHIM

  chmod +x "$F_BIN/pgrep" "$F_BIN/sysctl" "$F_BIN/vm_stat"

  set_admission_healthy
}

# --- probe control setters (write into $F_CTL, read by the shims above) ---
set_pgrep_real()   { echo real   > "$F_CTL/pgrep.mode"; }
set_pgrep_absent() { echo absent > "$F_CTL/pgrep.mode"; }
set_pgrep_fake() { # rc out
  echo fake > "$F_CTL/pgrep.mode"
  printf '%s' "$1" > "$F_CTL/pgrep.rc"
  printf '%s' "$2" > "$F_CTL/pgrep.out"
}
set_sysctl_real()   { local k="${1//./_}"; echo real   > "$F_CTL/sysctl_${k}.mode"; }
set_sysctl_absent() { local k="${1//./_}"; echo absent > "$F_CTL/sysctl_${k}.mode"; }
set_sysctl_fake() { # key rc out
  local k="${1//./_}"
  echo fake > "$F_CTL/sysctl_${k}.mode"
  printf '%s' "$2" > "$F_CTL/sysctl_${k}.rc"
  printf '%s' "$3" > "$F_CTL/sysctl_${k}.out"
}
set_vmstat_real()   { echo real   > "$F_CTL/vm_stat.mode"; }
set_vmstat_absent() { echo absent > "$F_CTL/vm_stat.mode"; }
set_vmstat_fake() { # rc out
  echo fake > "$F_CTL/vm_stat.mode"
  printf '%s' "$1" > "$F_CTL/vm_stat.rc"
  printf '%s' "$2" > "$F_CTL/vm_stat.out"
}
vmstat_text() { # free_pages inactive_pages -> vm_stat-formatted text, page size 16384
  printf 'Mach Virtual Memory Statistics: (page size of 16384 bytes)\n'
  printf 'Pages free:                             %d.\n' "$1"
  printf 'Pages active:                           2000.\n'
  printf 'Pages inactive:                         %d.\n' "$2"
  printf 'Pages speculative:                      500.\n'
  printf 'Pages wired down:                       3000.\n'
  printf 'Pages purgeable:                        0.\n'
  printf 'Pages occupied by compressor:           0.\n'
}
set_vmstat_fake_pages() { # rc free_pages inactive_pages
  echo fake > "$F_CTL/vm_stat.mode"
  printf '%s' "$1" > "$F_CTL/vm_stat.rc"
  vmstat_text "$2" "$3" > "$F_CTL/vm_stat.out"
}
# Healthy defaults so TCs that are NOT about admission specifics (arg
# normalization, snapshot consistency, cleanup, ...) sail through admission.
set_admission_healthy() {
  set_pgrep_fake 1 ""
  set_sysctl_fake vm.loadavg 0 "{ 1.00 1.00 1.00 }"
  set_sysctl_fake hw.ncpu 0 "4"
  set_vmstat_fake_pages 0 3000000 2000000
}

# ---------------------------------------------------------------------------
# Subject invocation
# ---------------------------------------------------------------------------
# run_subject [args...] : runs the fixture's run-tests.sh with the fixture's
# TMPDIR/PATH/DCRUN_CTL wired in. Sets RUN_RC / RUN_OUT / RUN_ERR. Never lets
# a non-zero rc trip `set -e` (guarded with `|| RUN_RC=$?`).
run_subject() {
  RUN_RC=0
  # ${EXTRA_ENV:-} is intentionally unquoted: callers (TC-21/22/23/24/25c/37) set
  # it to space-separated KEY=val pairs (e.g. TC-22's two hook vars) and rely on
  # word splitting to hand `env` one assignment per word. Quoting it would pass
  # a single malformed "KEY=val KEY2=val2" token instead.
  ( cd "$F_DEV" && env TMPDIR="$F_TMPBASE" PATH="$F_BIN:$PATH" DCRUN_CTL="$F_CTL" DCRUN_EVIDENCE="$F_CTL" ${EXTRA_ENV:-} bash run-tests.sh "$@" >"$F_CTL/.stdout" 2>"$F_CTL/.stderr" ) || RUN_RC=$?
  RUN_OUT="$(cat "$F_CTL/.stdout" 2>/dev/null || true)"
  RUN_ERR="$(cat "$F_CTL/.stderr" 2>/dev/null || true)"
}
evidence_where() { cat "$F_CTL/where" 2>/dev/null || true; }
reset_evidence()  { : > "$F_CTL/where" 2>/dev/null || true; }
write_config() { printf '%s' "$1" > "$F_DEV/.claude/test-serialization.json"; }

# add_git_repo: turns $F_DEV into a tiny self-contained git repo (for TC-25b/25c
# only -- NOT the real 22MB .git, a throwaway one committing whatever is
# currently in $F_DEV).
add_git_repo() {
  ( cd "$F_DEV" && git init -q && git config user.email "fixture@example.com" \
    && git config user.name "Fixture" && git add -A && git commit -q -m init )
}

# mk_stale_snap <name> <owner-content|MISSING|GARBAGE> [minutes_ago]
# Seeds a fake dev-crew-snap.* directory directly under $F_TMPBASE, with a
# non-empty payload (so permission-based deletion failures are observable),
# and an invented `.owner` metadata file (schema: `pid=` `start=` `created=`
# lines) in the state the TC needs. Optionally backdates its mtime.
mk_stale_snap() {
  local dir="$F_TMPBASE/$1"
  mkdir -p "$dir/agents/dev-crew"
  printf 'payload\n' > "$dir/agents/dev-crew/payload.txt"
  case "$2" in
    MISSING) : ;;
    GARBAGE) printf 'not-parseable-garbage' > "$dir/.owner" ;;
    *) printf '%s\n' "$2" > "$dir/.owner" ;;
  esac
  if [ -n "${3:-}" ]; then
    local target="$dir/.owner"
    [ -e "$target" ] || target="$dir"
    touch_backdate "$target" "$3"
  fi
}
touch_backdate() { # path minutes_ago (BSD/macOS date, per repo's macOS-only tooling policy)
  local ts
  ts="$(date -v-"${2}M" "+%Y%m%d%H%M.%S" 2>/dev/null)"
  [ -n "$ts" ] && touch -t "$ts" "$1"
}

# section_lines <file> <exact H2 heading text without '## '>
# Extracts the body of one '## Heading' section (up to the next '## '), so
# TC-43/44 assert against the specific section rather than whole-file grep.
section_lines() {
  awk -v h="## $2" '
    index($0, h) == 1 { flag=1; next }
    /^## / { flag=0 }
    flag { print }
  ' "$1"
}

# ===========================================================================
# admission
# ===========================================================================

# TC-01
# Given: all 3 admission conditions satisfied (fake probes)
# When: runner invoked
# Then: it executes (dummy evidence shows a dev-crew-snap.* snapshot path)
echo ""
echo "TC-01: 3 conditions satisfied (fake probe) -> runner executes on a snapshot"
new_fixture
run_subject
where="$(evidence_where)"
if [ "$RUN_RC" -eq 0 ] && printf '%s' "$where" | grep -q "dev-crew-snap\."; then
  pass "TC-01: admission PASS, dummy executed inside dev-crew-snap.* snapshot"
else
  fail "TC-01: admission PASS, dummy executed inside dev-crew-snap.* snapshot (rc=$RUN_RC where='$where')"
fi

# TC-02
# Given: test process count > 0 (fake pgrep, 2 real sibling PIDs)
# When: runner invoked
# Then: BLOCK, with the measured count (2) reported
echo ""
echo "TC-02: test process count > 0 -> BLOCK with measured count"
new_fixture
sleep 600 & p1=$!; ALL_SLEEP_PIDS+=("$p1")
sleep 600 & p2=$!; ALL_SLEEP_PIDS+=("$p2")
set_pgrep_fake 0 "$p1
$p2"
run_subject
if [ "$RUN_RC" -eq 2 ] && printf '%s%s' "$RUN_OUT" "$RUN_ERR" | grep -Eq '(^|[^0-9])2([^0-9]|$)'; then
  pass "TC-02: BLOCK (rc=2) reports measured count 2"
else
  fail "TC-02: BLOCK (rc=2) reports measured count 2 (rc=$RUN_RC out='$RUN_OUT' err='$RUN_ERR')"
fi
kill -KILL "$p1" "$p2" >/dev/null 2>&1 || true

# TC-03
# Given: pgrep rc=1 (no match)
# When: runner invoked
# Then: treated as condition SATISFIED, not a probe failure (no skip logged)
echo ""
echo "TC-03: pgrep rc=1 (no-match) is treated as satisfied, not a probe failure"
new_fixture
set_pgrep_fake 1 ""
run_subject
where="$(evidence_where)"
if [ "$RUN_RC" -eq 0 ] && printf '%s' "$where" | grep -q "dev-crew-snap\." \
   && ! printf '%s' "$RUN_ERR" | grep -qi 'skip'; then
  pass "TC-03: pgrep rc=1 satisfies the condition; no probe-failure skip logged"
else
  fail "TC-03: pgrep rc=1 satisfies the condition; no probe-failure skip logged (rc=$RUN_RC err='$RUN_ERR')"
fi

# TC-04
# Given: self + an ancestor wrapper (`sh -c 'bash run-tests.sh tests/test-foo.sh'`)
#        (real pgrep, no fake; admission_check runs before any test child is
#        spawned, so there are no descendants matching 'tests/test-' to
#        exclude -- exclusion is ancestor-only, see build_exclude_set)
# When: single-test invocation via that wrapper
# Then: runner does NOT self-BLOCK (lineage-based exclusion, not cmdline substring)
echo ""
echo "TC-04: self / ancestor wrapper / descendant matches are excluded (no self-BLOCK)"
new_fixture
set_pgrep_real
RUN_RC=0
( cd "$F_DEV" && sh -c "TMPDIR='$F_TMPBASE' PATH='$F_BIN:$PATH' DCRUN_CTL='$F_CTL' DCRUN_EVIDENCE='$F_CTL' bash run-tests.sh tests/test-zz-dummy.sh" >"$F_CTL/.stdout" 2>"$F_CTL/.stderr" ) || RUN_RC=$?
RUN_OUT="$(cat "$F_CTL/.stdout" 2>/dev/null || true)"
RUN_ERR="$(cat "$F_CTL/.stderr" 2>/dev/null || true)"
where="$(evidence_where)"
if [ "$RUN_RC" -eq 0 ] && printf '%s' "$where" | grep -q "dev-crew-snap\."; then
  pass "TC-04: sh -c wrapper ancestor (cmdline matches tests/test-) does not self-BLOCK"
else
  fail "TC-04: sh -c wrapper ancestor (cmdline matches tests/test-) does not self-BLOCK (rc=$RUN_RC err='$RUN_ERR')"
fi

# TC-04b (anti-oracle for TC-04's exclusion)
# Given: an UNRELATED process (sibling, not ancestor/descendant) whose cmdline
#        also matches 'tests/test-' (real pgrep)
# When: runner invoked
# Then: it IS counted -> BLOCK (exclusion is not overbroad)
echo ""
echo "TC-04b: an unrelated tests/test- process still BLOCKs (exclusion not overbroad)"
new_fixture
set_pgrep_real
mkdir -p "$F_CTL/decoy/tests"
cat > "$F_CTL/decoy/tests/test-zzz-unrelated.sh" <<'DECOY'
#!/bin/bash
# No `exec` here: an `exec sleep 600` would replace this bash process's image
# with sleep's, changing its cmdline from "bash tests/test-zzz-unrelated.sh" to
# "sleep 600" -- which no longer matches 'tests/test-' and defeats this TC's
# purpose as an anti-oracle for TC-04's exclusion. Running sleep as a foreground
# child keeps this process's own cmdline (and its 'tests/test-' match) intact.
sleep 600
DECOY
chmod +x "$F_CTL/decoy/tests/test-zzz-unrelated.sh"
( cd "$F_CTL/decoy" && exec bash tests/test-zzz-unrelated.sh ) &
up=$!
ALL_SLEEP_PIDS+=("$up")
sleep 0.3
run_subject
if [ "$RUN_RC" -eq 2 ]; then
  pass "TC-04b: unrelated tests/test- process is not excluded, admission BLOCKs"
else
  fail "TC-04b: unrelated tests/test- process is not excluded, admission BLOCKs (rc=$RUN_RC)"
fi
kill -KILL "$up" >/dev/null 2>&1 || true

# TC-05
# Given: load1 just below / at / just above load_max (= ncpu(4) * k_load(2) = 8)
# When: runner invoked (3 sub-cases)
# Then: below allow(0) / at BLOCK(2, equal is BLOCK side) / above BLOCK(2)
echo ""
echo "TC-05: load1 boundary (below/at/above load_max) -> allow/BLOCK/BLOCK"
new_fixture
set_sysctl_fake vm.loadavg 0 "{ 7.99 1.00 1.00 }"
run_subject
below_rc=$RUN_RC
below_where="$(evidence_where)"
reset_evidence
set_sysctl_fake vm.loadavg 0 "{ 8.00 1.00 1.00 }"
run_subject
at_rc=$RUN_RC
set_sysctl_fake vm.loadavg 0 "{ 8.01 1.00 1.00 }"
run_subject
above_rc=$RUN_RC
if [ "$below_rc" -eq 0 ] && printf '%s' "$below_where" | grep -q "dev-crew-snap\." \
   && [ "$at_rc" -eq 2 ] && [ "$above_rc" -eq 2 ]; then
  pass "TC-05: load boundary below=allow(0) at=BLOCK(2) above=BLOCK(2)"
else
  fail "TC-05: load boundary below=allow(0) at=BLOCK(2) above=BLOCK(2) (below=$below_rc at=$at_rc above=$above_rc)"
fi

# TC-06
# Given: free memory just above / at / just below mem_min_mib (3584 MiB = 229376
#        pages at 16384-byte page size)
# When: runner invoked (3 sub-cases)
# Then: above allow(0) / at BLOCK(2, equal is BLOCK side) / below BLOCK(2)
echo ""
echo "TC-06: free memory boundary (above/at/below mem_min_mib) -> allow/BLOCK/BLOCK"
new_fixture
set_vmstat_fake_pages 0 200000 29377   # 229377 pages -> 3584 MiB + 1 page
run_subject
above_rc=$RUN_RC
above_where="$(evidence_where)"
reset_evidence
set_vmstat_fake_pages 0 200000 29376   # 229376 pages -> exactly 3584 MiB
run_subject
at_rc=$RUN_RC
set_vmstat_fake_pages 0 200000 29375   # 229375 pages -> 3584 MiB - 1 page
run_subject
below_rc=$RUN_RC
if [ "$above_rc" -eq 0 ] && printf '%s' "$above_where" | grep -q "dev-crew-snap\." \
   && [ "$at_rc" -eq 2 ] && [ "$below_rc" -eq 2 ]; then
  pass "TC-06: memory boundary above=allow(0) at=BLOCK(2) below=BLOCK(2)"
else
  fail "TC-06: memory boundary above=allow(0) at=BLOCK(2) below=BLOCK(2) (above=$above_rc at=$at_rc below=$below_rc)"
fi

# TC-07
# Given: all 3 conditions unsatisfied simultaneously
# When: runner invoked
# Then: all 3 are reported before BLOCK (not just the first one hit)
echo ""
echo "TC-07: all 3 admission conditions fail -> all reported before BLOCK"
new_fixture
sleep 600 & p1=$!; ALL_SLEEP_PIDS+=("$p1")
set_pgrep_fake 0 "$p1"
set_sysctl_fake vm.loadavg 0 "{ 20.00 20.00 20.00 }"
set_vmstat_fake_pages 0 1000 1000
run_subject
combined="$RUN_OUT$RUN_ERR"
if [ "$RUN_RC" -eq 2 ] && printf '%s' "$combined" | grep -qi 'process' \
   && printf '%s' "$combined" | grep -qi 'load' \
   && printf '%s' "$combined" | grep -qi 'mem'; then
  pass "TC-07: all 3 unsatisfied conditions reported, then BLOCK"
else
  fail "TC-07: all 3 unsatisfied conditions reported, then BLOCK (rc=$RUN_RC out+err='$combined')"
fi

# TC-08
# Given: each of {process-count, load, memory} probe fails in each of 4 ways
#        (absent / rc>=2 / empty output / non-numeric output) -- 3x4 = 12 cases
# When: runner invoked, other 2 conditions kept healthy
# Then: only the broken condition is skipped (stderr says so), the other 2
#       still decide, and overall admission still PASSes (snapshot evidence present)
echo ""
echo "TC-08: probe failure (absent/rc>=2/empty/non-numeric) skips only that condition"
tc08_ok=1
tc08_detail=""
for cond in pgrep loadavg vmstat; do
  for mode in absent rc2 empty nonnum; do
    new_fixture
    case "$cond" in
      pgrep)
        case "$mode" in
          absent) set_pgrep_absent ;;
          rc2)    set_pgrep_fake 2 "" ;;
          empty)  set_pgrep_fake 0 "" ;;
          nonnum) set_pgrep_fake 0 "abc" ;;
        esac
        ;;
      loadavg)
        case "$mode" in
          absent) set_sysctl_absent vm.loadavg ;;
          rc2)    set_sysctl_fake vm.loadavg 2 "" ;;
          empty)  set_sysctl_fake vm.loadavg 0 "" ;;
          nonnum) set_sysctl_fake vm.loadavg 0 "{ n/a n/a n/a }" ;;
        esac
        ;;
      vmstat)
        case "$mode" in
          absent) set_vmstat_absent ;;
          rc2)    set_vmstat_fake 2 "" ;;
          empty)  set_vmstat_fake 0 "" ;;
          nonnum) set_vmstat_fake 0 "Pages free: n/a.
Pages inactive: n/a." ;;
        esac
        ;;
    esac
    run_subject
    where="$(evidence_where)"
    if [ "$RUN_RC" -ne 0 ] || ! printf '%s' "$where" | grep -q "dev-crew-snap\." \
       || ! printf '%s%s' "$RUN_OUT" "$RUN_ERR" | grep -qi "skip"; then
      tc08_ok=0
      tc08_detail="$tc08_detail [${cond}/${mode}: rc=$RUN_RC where='$where']"
    fi
  done
done
if [ "$tc08_ok" -eq 1 ]; then
  pass "TC-08: each of 4 failure modes x 3 conditions skips only that condition, others still decide"
else
  fail "TC-08: each of 4 failure modes x 3 conditions skips only that condition, others still decide -$tc08_detail"
fi

# TC-09
# Given: all 3 conditions unmeasurable (all probes absent)
# When: runner invoked
# Then: admission PASS (fail-open when judgment is impossible for everything)
echo ""
echo "TC-09: all 3 conditions skip (all probes unusable) -> admission PASS"
new_fixture
set_pgrep_absent
set_sysctl_absent vm.loadavg
set_sysctl_absent hw.ncpu
set_vmstat_absent
run_subject
where="$(evidence_where)"
if [ "$RUN_RC" -eq 0 ] && printf '%s' "$where" | grep -q "dev-crew-snap\."; then
  pass "TC-09: all conditions unmeasurable -> fail-open PASS (does not block work)"
else
  fail "TC-09: all conditions unmeasurable -> fail-open PASS (rc=$RUN_RC where='$where')"
fi

# TC-10
# Given: ncpu probe fails (hw.ncpu absent)
# When: runner invoked
# Then: only the load condition is skipped (load_max needs ncpu); process-count
#       and memory conditions still decide, admission PASSes
echo ""
echo "TC-10: ncpu probe failure -> only the load condition is skipped"
new_fixture
set_sysctl_absent hw.ncpu
run_subject
where="$(evidence_where)"
combined="$RUN_OUT$RUN_ERR"
if [ "$RUN_RC" -eq 0 ] && printf '%s' "$where" | grep -q "dev-crew-snap\." \
   && printf '%s' "$combined" | grep -qi "load"; then
  pass "TC-10: ncpu unavailable -> load condition skipped, others decide, admission PASS"
else
  fail "TC-10: ncpu unavailable -> load condition skipped, others decide, admission PASS (rc=$RUN_RC where='$where')"
fi

# ===========================================================================
# config
# ===========================================================================

# TC-11
# Given: config key missing / type mismatch / out-of-range / whole file invalid JSON
# When: runner invoked
# Then: ONLY the broken key falls back to its default (whole-file-invalid falls
#       back on ALL keys) -- and the default is genuinely EVALUATED (proven via
#       a boundary probe that only BLOCKs if the default value is truly in effect)
echo ""
echo "TC-11: broken config -> only broken key defaults (whole-file invalid -> all keys), always evaluated"
tc11_ok=1
tc11_detail=""

# (a) missing key: mem_min_mib entirely absent -> default 3584 MiB applies
new_fixture
write_config '{"k_load": 2, "snapshot_stale_minutes": 60, "warn_on_live_changes": true}'
set_vmstat_fake_pages 0 200000 29376   # exactly 3584 MiB (default boundary) -> BLOCK
run_subject
if [ "$RUN_RC" -ne 2 ] || ! printf '%s%s' "$RUN_OUT" "$RUN_ERR" | grep -q "mem_min_mib"; then
  tc11_ok=0; tc11_detail="$tc11_detail [missing-key: rc=$RUN_RC]"
fi

# (b) type mismatch: k_load is a string -> default 2 applies (load_max = ncpu(4)*2 = 8.00)
new_fixture
write_config '{"k_load": "two", "mem_min_mib": 3584, "snapshot_stale_minutes": 60, "warn_on_live_changes": true}'
set_sysctl_fake vm.loadavg 0 "{ 8.00 1.00 1.00 }"   # exactly default boundary -> BLOCK
run_subject
if [ "$RUN_RC" -ne 2 ] || ! printf '%s%s' "$RUN_OUT" "$RUN_ERR" | grep -q "k_load"; then
  tc11_ok=0; tc11_detail="$tc11_detail [type-mismatch: rc=$RUN_RC]"
fi

# (c) out of range: mem_min_mib negative (contract requires >= 0) -> default 3584 applies
new_fixture
write_config '{"k_load": 2, "mem_min_mib": -100, "snapshot_stale_minutes": 60, "warn_on_live_changes": true}'
set_vmstat_fake_pages 0 200000 29376
run_subject
if [ "$RUN_RC" -ne 2 ] || ! printf '%s%s' "$RUN_OUT" "$RUN_ERR" | grep -q "mem_min_mib"; then
  tc11_ok=0; tc11_detail="$tc11_detail [out-of-range: rc=$RUN_RC]"
fi

# (d) whole file invalid JSON -> ALL keys default (both boundaries active simultaneously)
new_fixture
write_config '{not valid json'
set_sysctl_fake vm.loadavg 0 "{ 8.00 1.00 1.00 }"
set_vmstat_fake_pages 0 200000 29376
run_subject
if [ "$RUN_RC" -ne 2 ]; then
  tc11_ok=0; tc11_detail="$tc11_detail [invalid-json: rc=$RUN_RC]"
fi

# (e) mini-iteration follow-up (B5): mem_min_mib given as a non-integer NUMBER
# (1.5). `jq -r` on `.[$k]` would print "1.5" whether the JSON value is the
# number 1.5 or (as in (b)/(h) below) a string -- a bash-side regex like
# `^-?[0-9]+(\.[0-9]+)?$` cannot reject this, so a config-parser that skips
# an in-jq integer check silently accepts a fractional MiB threshold that
# never blocks anything. Correct: rejected (not an integer) -> default 3584
# applies -> BLOCKs at the default boundary.
new_fixture
write_config '{"k_load": 2, "mem_min_mib": 1.5, "snapshot_stale_minutes": 60, "warn_on_live_changes": true}'
set_vmstat_fake_pages 0 200000 29376   # exactly 3584 MiB (default boundary) -> BLOCK
run_subject
if [ "$RUN_RC" -ne 2 ] || ! printf '%s%s' "$RUN_OUT" "$RUN_ERR" | grep -q "mem_min_mib"; then
  tc11_ok=0; tc11_detail="$tc11_detail [float-for-integer-mem_min_mib: rc=$RUN_RC]"
fi

# (f) mini-iteration follow-up (B5): snapshot_stale_minutes given as a
# non-integer number (0.5). Discriminates via startup cleanup rather than
# admission: a MISSING-owner snapshot backdated 1 minute is NOT stale under
# the correct default (60) -> preserved; it WOULD be treated as stale under
# a wrongly-accepted 0.5 -> deleted.
new_fixture
write_config '{"k_load": 2, "mem_min_mib": 3584, "snapshot_stale_minutes": 0.5, "warn_on_live_changes": true}'
mk_stale_snap "dev-crew-snap.tc11f" MISSING 1
run_subject
if [ "$RUN_RC" -ne 0 ] || [ ! -d "$F_TMPBASE/dev-crew-snap.tc11f" ] \
   || ! printf '%s%s' "$RUN_OUT" "$RUN_ERR" | grep -q "snapshot_stale_minutes"; then
  tc11_ok=0; tc11_detail="$tc11_detail [float-for-integer-stale-minutes: rc=$RUN_RC exists=$([ -d "$F_TMPBASE/dev-crew-snap.tc11f" ] && echo yes || echo no)]"
fi

# (g) mini-iteration follow-up (B5): warn_on_live_changes given as the JSON
# STRING "false" (not the JSON boolean). `jq -r` stringifies both identically
# ("false"), so a parser that matches the raw text against `true|false`
# without an in-jq `type` check wrongly honors it. Correct: rejected (wrong
# type) -> default true applies -> the concurrent live-tree edit IS reported.
new_fixture
write_config '{"k_load": 2, "mem_min_mib": 3584, "snapshot_stale_minutes": 60, "warn_on_live_changes": "false"}'
cat > "$F_DEV/tests/test-mm-mutator.sh" <<'MUTTC11G'
#!/bin/bash
if [ -n "${DCRUN_LIVE_DEV:-}" ]; then
  printf 'concurrent edit\n' >> "$DCRUN_LIVE_DEV/LIVE_EDIT_DURING_RUN.txt"
fi
exit 0
MUTTC11G
chmod +x "$F_DEV/tests/test-mm-mutator.sh"
EXTRA_ENV="DCRUN_LIVE_DEV=$F_DEV"
run_subject
unset EXTRA_ENV
if [ "$RUN_RC" -ne 0 ] || ! printf '%s%s' "$RUN_OUT" "$RUN_ERR" | grep -q "LIVE_EDIT_DURING_RUN.txt" \
   || ! printf '%s%s' "$RUN_OUT" "$RUN_ERR" | grep -q "warn_on_live_changes"; then
  tc11_ok=0; tc11_detail="$tc11_detail [string-for-boolean-warn_on_live_changes: rc=$RUN_RC]"
fi

# (h) mini-iteration follow-up (B5): k_load given as a numeric-LOOKING JSON
# STRING "3" (not a JSON number). Same jq -r stringification blind spot as
# (g), but for get_num_key: the buggy value 3 gives load_max=12.00, the
# correct default 2 gives load_max=8.00 -- load1 pinned at exactly 8.00
# discriminates (correct -> BLOCK, buggy accepted-as-3 -> allow).
new_fixture
write_config '{"k_load": "3", "mem_min_mib": 3584, "snapshot_stale_minutes": 60, "warn_on_live_changes": true}'
set_sysctl_fake vm.loadavg 0 "{ 8.00 1.00 1.00 }"
run_subject
if [ "$RUN_RC" -ne 2 ] || ! printf '%s%s' "$RUN_OUT" "$RUN_ERR" | grep -q "k_load"; then
  tc11_ok=0; tc11_detail="$tc11_detail [numeric-string-k_load: rc=$RUN_RC]"
fi

if [ "$tc11_ok" -eq 1 ]; then
  pass "TC-11: broken config falls back per-key to defaults (whole-file invalid -> all keys), always evaluated"
else
  fail "TC-11: broken config falls back per-key to defaults (whole-file invalid -> all keys), always evaluated -$tc11_detail"
fi

# TC-12
# Given: jq is genuinely unresolvable on PATH (not merely a failing shim)
# When: runner invoked
# Then: all keys default and evaluation continues (BLOCK still triggers at the
#       default boundary); stderr names jq specifically (distinct path from
#       invalid-JSON handling in TC-11d)
echo ""
echo "TC-12: jq absent -> all keys default, continues, distinct from invalid-JSON path"
new_fixture
write_config '{"k_load": 1, "mem_min_mib": 100, "snapshot_stale_minutes": 5, "warn_on_live_changes": false}'
set_sysctl_fake vm.loadavg 0 "{ 8.00 1.00 1.00 }"
set_vmstat_fake_pages 0 200000 29376
RUN_RC=0
( cd "$F_DEV" && env TMPDIR="$F_TMPBASE" PATH="$F_BIN:$NOJQ_BIN" DCRUN_CTL="$F_CTL" DCRUN_EVIDENCE="$F_CTL" bash run-tests.sh >"$F_CTL/.stdout" 2>"$F_CTL/.stderr" ) || RUN_RC=$?
RUN_OUT="$(cat "$F_CTL/.stdout" 2>/dev/null || true)"
RUN_ERR="$(cat "$F_CTL/.stderr" 2>/dev/null || true)"
if [ "$RUN_RC" -eq 2 ] && printf '%s' "$RUN_ERR" | grep -qi "jq"; then
  pass "TC-12: jq absent -> defaults applied (boundary still enforced), stderr mentions jq"
else
  fail "TC-12: jq absent -> defaults applied (boundary still enforced), stderr mentions jq (rc=$RUN_RC err='$RUN_ERR')"
fi

# TC-13
# Given: config file does not exist at all
# When: runner invoked
# Then: all keys default (same boundary-proof technique as TC-11)
echo ""
echo "TC-13: config file absent -> all keys default"
new_fixture
rm -f "$F_DEV/.claude/test-serialization.json"
set_sysctl_fake vm.loadavg 0 "{ 8.00 1.00 1.00 }"
set_vmstat_fake_pages 0 200000 29376
run_subject
if [ "$RUN_RC" -eq 2 ]; then
  pass "TC-13: missing config file -> default k_load/mem_min_mib enforced (BLOCK at default boundary)"
else
  fail "TC-13: missing config file -> default k_load/mem_min_mib enforced (BLOCK at default boundary) (rc=$RUN_RC)"
fi

# ===========================================================================
# 引数の正規化 (argument normalization)
# ===========================================================================

# TC-14
# Given: `tests/test-foo.sh` (repo-relative)
# When: runner invoked with that argument
# Then: the corresponding path INSIDE the snapshot is executed
echo ""
echo "TC-14: tests/test-foo.sh argument -> the corresponding snapshot path is executed"
new_fixture
run_subject tests/test-zz-dummy.sh
where="$(evidence_where)"
if [ "$RUN_RC" -eq 0 ] && printf '%s' "$where" | grep -q "dev-crew-snap\."; then
  pass "TC-14: tests/test-foo.sh arg resolves & executes inside the snapshot"
else
  fail "TC-14: tests/test-foo.sh arg resolves & executes inside the snapshot (rc=$RUN_RC where='$where')"
fi

# TC-15
# Given: a repo-external absolute path
# When: runner invoked with that argument
# Then: rejected, exit non-zero (distinguishable class: rc=3)
echo ""
echo "TC-15: repo-external absolute path -> rejected"
new_fixture
outside="$(mktemp)"
printf '#!/bin/bash\nexit 0\n' > "$outside"
run_subject "$outside"
if [ "$RUN_RC" -eq 3 ]; then
  pass "TC-15: repo-external absolute path rejected (rc=3)"
else
  fail "TC-15: repo-external absolute path rejected (rc=3) (rc=$RUN_RC)"
fi
rm -f "$outside"

# TC-16
# Given: a `..`-escaping relative path
# When: runner invoked with that argument
# Then: rejected
echo ""
echo "TC-16: '..' path escape -> rejected"
new_fixture
run_subject "tests/../../../../etc/hosts"
if [ "$RUN_RC" -eq 3 ]; then
  pass "TC-16: '..' escape rejected (rc=3)"
else
  fail "TC-16: '..' escape rejected (rc=3) (rc=$RUN_RC)"
fi

# TC-17
# Given: a symlink under tests/ pointing outside the repo
# When: runner invoked with that argument
# Then: rejected
echo ""
echo "TC-17: symlink to a repo-external target -> rejected"
new_fixture
outside_target="$(mktemp)"
printf '#!/bin/bash\nexit 0\n' > "$outside_target"
ln -s "$outside_target" "$F_DEV/tests/test-escape-link.sh"
run_subject "tests/test-escape-link.sh"
if [ "$RUN_RC" -eq 3 ]; then
  pass "TC-17: symlink escaping the repo rejected (rc=3)"
else
  fail "TC-17: symlink escaping the repo rejected (rc=3) (rc=$RUN_RC)"
fi
rm -f "$outside_target"

# TC-18
# Given: a file that exists but is not under tests/
# When: runner invoked with that argument
# Then: rejected
echo ""
echo "TC-18: a file outside tests/ -> rejected"
new_fixture
printf '#!/bin/bash\nexit 0\n' > "$F_DEV/run-tests.sh.bak"
run_subject "run-tests.sh.bak"
if [ "$RUN_RC" -eq 3 ]; then
  pass "TC-18: non-tests/ path rejected (rc=3)"
else
  fail "TC-18: non-tests/ path rejected (rc=3) (rc=$RUN_RC)"
fi

# TC-18a (mini-iteration follow-up, B2)
# Given: a DIRECTORY under tests/ whose name matches the test-*.sh contract
# When: runner invoked with that argument
# Then: rejected -- a directory is not a regular test file; silently globbing
#       over it (the pre-fix behavior) can make TOTAL=0 look like a PASS
echo ""
echo "TC-18a: a directory under tests/ (even if name-matching) -> rejected"
new_fixture
mkdir -p "$F_DEV/tests/test-a-directory.sh"
run_subject "tests/test-a-directory.sh"
if [ "$RUN_RC" -eq 3 ]; then
  pass "TC-18a: directory argument rejected (rc=3)"
else
  fail "TC-18a: directory argument rejected (rc=3) (rc=$RUN_RC)"
fi

# TC-18b (mini-iteration follow-up, B2)
# Given: a regular file under tests/ that does NOT match the test-*.sh
#        naming contract (e.g. a helper/fixture file)
# When: runner invoked with that argument
# Then: rejected -- bash would happily execute any file handed to it; the
#       contract is name-based, not merely location-based
echo ""
echo "TC-18b: a non-test-*.sh-named file under tests/ -> rejected"
new_fixture
printf '#!/bin/bash\nexit 0\n' > "$F_DEV/tests/helper.txt"
run_subject "tests/helper.txt"
if [ "$RUN_RC" -eq 3 ]; then
  pass "TC-18b: non-test-*.sh name under tests/ rejected (rc=3)"
else
  fail "TC-18b: non-test-*.sh name under tests/ rejected (rc=3) (rc=$RUN_RC)"
fi

# TC-18c (mini-iteration follow-up, B2)
# Given: a tests/ directory with ZERO files matching test-*.sh (full-suite
#        invocation, no args)
# When: runner invoked
# Then: rejected as an error (rc=3) -- NOT a silent "TOTAL: 0 / exit 0" pass,
#       which would be indistinguishable from "everything passed"
echo ""
echo "TC-18c: zero test-*.sh targets (full suite) -> rejected, not a vacuous TOTAL=0/exit 0"
new_fixture
rm -f "$F_DEV/tests/test-zz-dummy.sh"
run_subject
if [ "$RUN_RC" -eq 3 ]; then
  pass "TC-18c: zero matching targets rejected (rc=3), not a vacuous pass"
else
  fail "TC-18c: zero matching targets rejected (rc=3), not a vacuous pass (rc=$RUN_RC out+err='$RUN_OUT$RUN_ERR')"
fi

# TC-19
# Given: a path that does not exist
# When: runner invoked with that argument
# Then: rejected
echo ""
echo "TC-19: nonexistent path -> rejected"
new_fixture
run_subject "tests/test-does-not-exist.sh"
if [ "$RUN_RC" -eq 3 ]; then
  pass "TC-19: nonexistent path rejected (rc=3)"
else
  fail "TC-19: nonexistent path rejected (rc=3) (rc=$RUN_RC)"
fi

# TC-20
# Given: a marker the dummy test leaves relative to wherever it actually ran
# When: runner invoked with a single-test argument
# Then: the marker appears ONLY inside the snapshot copy -- the LIVE fixture
#       tests/ directory is never touched (proves no direct live-tree execution)
echo ""
echo "TC-20: executed marker appears only inside the snapshot, never in the live tree"
new_fixture
run_subject tests/test-zz-dummy.sh
marker="$F_DEV/tests/.executed-marker"
where="$(evidence_where)"
if [ "$RUN_RC" -eq 0 ] && [ ! -e "$marker" ] && printf '%s' "$where" | grep -q "dev-crew-snap\."; then
  pass "TC-20: live tree left untouched (no marker); execution evidence points at a snapshot copy"
else
  marker_state="absent"; [ -e "$marker" ] && marker_state="PRESENT (live tree was executed directly)"
  fail "TC-20: live tree left untouched (no marker); execution evidence points at a snapshot copy (rc=$RUN_RC marker=$marker_state where='$where')"
fi

# ===========================================================================
# snapshot の一貫性 (invented test-hook contract: DEV_CREW_TEST_HOOK_BEFORE_COPY
# runs once after manifest A / before copy; DEV_CREW_TEST_HOOK_AFTER_COPY runs
# once after copy / before manifests B and C. Both receive $1 = snapshot root.
# GREEN must implement both for TC-21/22/23/24/25c to be satisfiable.)
# ===========================================================================

# TC-21
# Given: source changes once during copy and the change persists (A != B == C
#        is a NORMAL form per the design, not itself an error)
# When: runner invoked
# Then: NOT(A==B AND B==C) is detected, the snapshot is rebuilt, and (since the
#       2nd attempt sees a stable source) the run ultimately succeeds
echo ""
echo "TC-21: source changes during copy and stays changed -> rebuild, then succeeds"
new_fixture
printf 'v1\n' > "$F_DEV/MUTATE_ME.txt"
cat > "$F_CTL/hook_before21.sh" <<HOOK
#!/bin/bash
if [ ! -e "$F_CTL/tc21_mutated" ]; then
  touch "$F_CTL/tc21_mutated"
  printf 'v2\n' > "$F_DEV/MUTATE_ME.txt"
fi
HOOK
chmod +x "$F_CTL/hook_before21.sh"
EXTRA_ENV="DEV_CREW_TEST_HOOK_BEFORE_COPY=$F_CTL/hook_before21.sh"
run_subject
unset EXTRA_ENV
where="$(evidence_where)"
combined="$RUN_OUT$RUN_ERR"
if [ "$RUN_RC" -eq 0 ] && printf '%s' "$where" | grep -q "dev-crew-snap\." \
   && printf '%s' "$combined" | grep -Eqi 'rebuild|retry|mismatch|recreat'; then
  pass "TC-21: continuous mid-copy change (A!=B=C) detected, snapshot rebuilt, run succeeds"
else
  fail "TC-21: continuous mid-copy change (A!=B=C) detected, snapshot rebuilt, run succeeds (rc=$RUN_RC where='$where' out+err='$combined')"
fi

# TC-22
# Given: source changes then reverts DURING copy (ABA), and the snapshot
#        genuinely captured the intermediate value (deterministic via the
#        before/after hooks, not a sleep race)
# When: runner invoked
# Then: the 3-way check catches it (A==C but B differs -- a naive 2-point
#       A-vs-C compare would miss this entirely)
echo ""
echo "TC-22: ABA mid-copy change (A==C, B differs) is caught by the 3-way check"
new_fixture
printf 'v1\n' > "$F_DEV/MUTATE_ME.txt"
cat > "$F_CTL/hook_before22.sh" <<HOOK
#!/bin/bash
if [ ! -e "$F_CTL/tc22_done" ]; then
  printf 'v2\n' > "$F_DEV/MUTATE_ME.txt"
fi
HOOK
cat > "$F_CTL/hook_after22.sh" <<HOOK
#!/bin/bash
if [ ! -e "$F_CTL/tc22_done" ]; then
  printf 'v1\n' > "$F_DEV/MUTATE_ME.txt"
  touch "$F_CTL/tc22_done"
fi
HOOK
chmod +x "$F_CTL/hook_before22.sh" "$F_CTL/hook_after22.sh"
EXTRA_ENV="DEV_CREW_TEST_HOOK_BEFORE_COPY=$F_CTL/hook_before22.sh DEV_CREW_TEST_HOOK_AFTER_COPY=$F_CTL/hook_after22.sh"
run_subject
unset EXTRA_ENV
combined="$RUN_OUT$RUN_ERR"
if [ "$RUN_RC" -eq 0 ] && printf '%s' "$combined" | grep -Eqi 'rebuild|retry|mismatch|recreat'; then
  pass "TC-22: ABA mid-copy corruption (A==C, B differs) detected via the 3-way check, rebuilt, succeeds"
else
  fail "TC-22: ABA mid-copy corruption (A==C, B differs) detected via the 3-way check, rebuilt, succeeds (rc=$RUN_RC out+err='$combined')"
fi

# TC-23
# Given: the parent docs/test_architecture.md changes during copy
# When: runner invoked
# Then: it is included in the manifest and the change is detected (proving the
#       parent doc participates in the 3-way check, not just the repo proper)
echo ""
echo "TC-23: parent docs/test_architecture.md change during copy is included in the manifest & detected"
new_fixture
cat > "$F_CTL/hook_before23.sh" <<HOOK
#!/bin/bash
if [ ! -e "$F_CTL/tc23_done" ]; then
  touch "$F_CTL/tc23_done"
  printf 'mutated\n' >> "$F_REPO/docs/test_architecture.md"
fi
HOOK
chmod +x "$F_CTL/hook_before23.sh"
EXTRA_ENV="DEV_CREW_TEST_HOOK_BEFORE_COPY=$F_CTL/hook_before23.sh"
run_subject
unset EXTRA_ENV
combined="$RUN_OUT$RUN_ERR"
if [ "$RUN_RC" -eq 0 ] && printf '%s' "$combined" | grep -Eqi 'rebuild|retry|mismatch|recreat'; then
  pass "TC-23: parent docs/test_architecture.md change during copy is included in the manifest & detected"
else
  fail "TC-23: parent docs/test_architecture.md change during copy is included in the manifest & detected (rc=$RUN_RC out+err='$combined')"
fi

# TC-24
# Given: source keeps changing on every single attempt (never stabilizes)
# When: runner invoked
# Then: the rebuild cap (3 attempts) is exceeded -> exit non-zero, distinct
#       from admission BLOCK / arg-rejection (rc=4), reason explicitly stated
echo ""
echo "TC-24: rebuild cap (3) exceeded when source never stabilizes -> exit 4 with the specified reason"
new_fixture
printf 'v1\n' > "$F_DEV/MUTATE_ME.txt"
cat > "$F_CTL/hook_before24.sh" <<HOOK
#!/bin/bash
printf 'v-%s\n' "\$RANDOM" >> "$F_DEV/MUTATE_ME.txt"
HOOK
chmod +x "$F_CTL/hook_before24.sh"
EXTRA_ENV="DEV_CREW_TEST_HOOK_BEFORE_COPY=$F_CTL/hook_before24.sh"
run_subject
unset EXTRA_ENV
combined="$RUN_OUT$RUN_ERR"
if [ "$RUN_RC" -eq 4 ] && printf '%s' "$combined" | grep -q '書き込み中'; then
  pass "TC-24: rebuild cap exceeded -> exit 4, reason names the writing-in-progress cause"
else
  fail "TC-24: rebuild cap exceeded -> exit 4, reason names the writing-in-progress cause (rc=$RUN_RC out+err='$combined')"
fi

# TC-24b (mini-iteration follow-up, B1/B4)
# Given: a FIFO planted under the live tree (a special file compute_manifest
#        cannot hash)
# When: runner invoked
# Then: a DISTINCT infra exit code (5) is used, NOT exit 1 -- which per the
#       header contract means ">=1 test FAILED" and must never be produced
#       by an infra condition unrelated to any test's outcome
echo ""
echo "TC-24b: a FIFO under the live tree yields a distinct infra exit code (5), not exit 1 (FAIL misattribution)"
new_fixture
mkfifo "$F_DEV/a-fifo" 2>/dev/null || true
run_subject
if [ "$RUN_RC" -eq 5 ]; then
  pass "TC-24b: FIFO under the tree -> exit 5 (infra), distinguishable from exit 1 (test FAIL)"
else
  fail "TC-24b: FIFO under the tree -> exit 5 (infra), distinguishable from exit 1 (test FAIL) (rc=$RUN_RC)"
fi
rm -f "$F_DEV/a-fifo" 2>/dev/null || true

# TC-25
# Given: the real tests/test-paradigm-selection.sh, which depends on
#        $BASE_DIR/../.. to find docs/test_architecture.md
# When: run via the fixture (copied verbatim, plus its own real dependencies)
# Then: it passes INSIDE the snapshot (parent structure correctly replicated).
#       Tied to snapshot evidence too: the live fixture tree already has the
#       correct 2-level nesting by construction, so without also requiring
#       snapshot evidence this TC would vacuously pass on the live tree alone.
echo ""
echo "TC-25: tests/test-paradigm-selection.sh's ../.. dependency resolves inside the snapshot"
new_fixture
cp "$BASE_DIR/tests/test-paradigm-selection.sh" "$F_DEV/tests/test-paradigm-selection.sh"
mkdir -p "$F_DEV/skills/red" "$F_DEV/agents"
cp "$BASE_DIR/skills/red/reference.md" "$F_DEV/skills/red/reference.md"
cp "$BASE_DIR/agents/red-worker.md" "$F_DEV/agents/red-worker.md"
run_subject
where="$(evidence_where)"
if [ "$RUN_RC" -eq 0 ] && printf '%s' "$where" | grep -q "dev-crew-snap\."; then
  pass "TC-25: paradigm-selection's ../.. -> docs/test_architecture.md resolves inside the snapshot"
else
  fail "TC-25: paradigm-selection's ../.. -> docs/test_architecture.md resolves inside the snapshot (rc=$RUN_RC where='$where' out='$RUN_OUT' err='$RUN_ERR')"
fi

# TC-25b
# Given: a test that runs `git ls-files` inside its own resolved BASE_DIR
# When: run via the fixture (a throwaway git repo, NOT the real 22MB .git)
# Then: it passes inside the snapshot (.git replicated). Also tied to snapshot
#       evidence: `git ls-files` already works fine on the live fixture tree
#       today, so that alone would vacuously pass without snapshot logic.
echo ""
echo "TC-25b: a test running 'git ls-files' inside the snapshot passes (.git replicated)"
new_fixture
cat > "$F_DEV/tests/test-zz-git-check.sh" <<'GITCHK'
#!/bin/bash
set -euo pipefail
D="$(cd "$(dirname "$0")/.." && pwd)"
out=$(git -C "$D" ls-files 2>&1) || { echo "git ls-files failed: $out" >&2; exit 1; }
echo "$out" | grep -q "tests/test-zz-dummy.sh" || { echo "tracked file missing from git ls-files output: $out" >&2; exit 1; }
exit 0
GITCHK
chmod +x "$F_DEV/tests/test-zz-git-check.sh"
add_git_repo
run_subject
where="$(evidence_where)"
if [ "$RUN_RC" -eq 0 ] && printf '%s' "$where" | grep -q "dev-crew-snap\."; then
  pass "TC-25b: git ls-files works inside the snapshot (.git replicated)"
else
  fail "TC-25b: git ls-files works inside the snapshot (.git replicated) (rc=$RUN_RC where='$where')"
fi

# TC-25c
# Given: the snapshot's own git state is tampered with post-copy (one attempt
#        only), so its `git ls-files` output diverges from the source's
# When: runner invoked (AFTER_COPY hook does the tampering)
# Then: the virtual `git ls-files` manifest entry catches the divergence via
#       the 3-way check, the snapshot is rebuilt, and the (clean) retry succeeds
echo ""
echo "TC-25c: snapshot's 'git ls-files' output diverging from source is caught by the 3-way check"
new_fixture
cat > "$F_DEV/tests/test-zz-git-check.sh" <<'GITCHK'
#!/bin/bash
set -euo pipefail
D="$(cd "$(dirname "$0")/.." && pwd)"
git -C "$D" ls-files >/dev/null 2>&1
exit 0
GITCHK
chmod +x "$F_DEV/tests/test-zz-git-check.sh"
add_git_repo
cat > "$F_CTL/hook_after25c.sh" <<HOOK
#!/bin/bash
# \$1 = snapshot root, passed by the runner
if [ ! -e "$F_CTL/tc25c_done" ]; then
  touch "$F_CTL/tc25c_done"
  git -C "\$1/agents/dev-crew" rm --cached tests/test-zz-git-check.sh >/dev/null 2>&1 || true
fi
HOOK
chmod +x "$F_CTL/hook_after25c.sh"
EXTRA_ENV="DEV_CREW_TEST_HOOK_AFTER_COPY=$F_CTL/hook_after25c.sh"
run_subject
unset EXTRA_ENV
combined="$RUN_OUT$RUN_ERR"
if [ "$RUN_RC" -eq 0 ] && printf '%s' "$combined" | grep -Eqi 'rebuild|retry|mismatch|recreat'; then
  pass "TC-25c: snapshot git-ls-files divergence from source detected via the virtual entry, rebuilt, succeeds"
else
  fail "TC-25c: snapshot git-ls-files divergence from source detected via the virtual entry, rebuilt, succeeds (rc=$RUN_RC out+err='$combined')"
fi

# ===========================================================================
# snapshot の後始末 (cleanup)
# ===========================================================================

# TC-26
# Given: a normal successful run
# When: runner completes
# Then: the snapshot directory is removed afterward
echo ""
echo "TC-26: normal completion -> the snapshot directory is removed afterward"
new_fixture
run_subject
remaining=$(find "$F_TMPBASE" -maxdepth 1 -type d -name 'dev-crew-snap.*' 2>/dev/null | wc -l | tr -d ' ')
where="$(evidence_where)"
if [ "$RUN_RC" -eq 0 ] && printf '%s' "$where" | grep -q "dev-crew-snap\." && [ "$remaining" -eq 0 ]; then
  pass "TC-26: snapshot existed during the run and is gone afterward"
else
  fail "TC-26: snapshot existed during the run and is gone afterward (rc=$RUN_RC where='$where' remaining=$remaining)"
fi

# TC-27 / TC-27b
# Given: a slow child test (traps TERM/INT, signals a start sentinel, sleeps)
#        followed by a second test that would only run if the suite continued
# When: SIGTERM or SIGINT is delivered to the runner mid-run (real signal,
#       job-control subshell so INT delivery is not silently ignored)
# Then: non-zero exit, snapshot removed, the LATER test never runs (TC-27),
#       and the signal is forwarded to the still-running child (TC-27b,
#       observed via the child's own signal-handler sentinel)
echo ""
echo "TC-27 / TC-27b: SIGINT/SIGTERM mid-run -> snapshot removed, non-zero exit, no later test, signal forwarded to child"
for sig in TERM INT; do
  new_fixture
  rm -f "$F_DEV/tests/test-zz-dummy.sh"
  cat > "$F_DEV/tests/test-aa-slow.sh" <<'SLOW'
#!/bin/bash
term_handler() {
  [ -n "${DCRUN_EVIDENCE:-}" ] && touch "$DCRUN_EVIDENCE/child-signaled"
  exit 143
}
trap term_handler TERM INT
[ -n "${DCRUN_EVIDENCE:-}" ] && touch "$DCRUN_EVIDENCE/child-started"
sleep 30 &
wait $!
SLOW
  chmod +x "$F_DEV/tests/test-aa-slow.sh"
  cat > "$F_DEV/tests/test-zz-never.sh" <<'NEVER'
#!/bin/bash
[ -n "${DCRUN_EVIDENCE:-}" ] && touch "$DCRUN_EVIDENCE/zz-ran"
exit 0
NEVER
  chmod +x "$F_DEV/tests/test-zz-never.sh"
  rm -f "$F_CTL/child-started" "$F_CTL/child-signaled" "$F_CTL/zz-ran"

  RUN_RC=0
  ( set -m
    ( cd "$F_DEV" && exec env TMPDIR="$F_TMPBASE" PATH="$F_BIN:$PATH" DCRUN_CTL="$F_CTL" DCRUN_EVIDENCE="$F_CTL" bash run-tests.sh >"$F_CTL/.stdout" 2>"$F_CTL/.stderr" ) &
    subj_pid=$!
    for i in $(seq 1 100); do [ -e "$F_CTL/child-started" ] && break; sleep 0.05; done
    kill -s "$sig" "$subj_pid" 2>/dev/null || true
    wait "$subj_pid"
  ) || RUN_RC=$?
  RUN_OUT="$(cat "$F_CTL/.stdout" 2>/dev/null || true)"
  RUN_ERR="$(cat "$F_CTL/.stderr" 2>/dev/null || true)"

  # Give any genuine (future) forwarding a brief window, then evaluate BEFORE
  # doing any cleanup -- a cleanup sweep must never itself be able to satisfy
  # the "child was signaled" assertion (e.g. `pkill` without -KILL would send
  # its own SIGTERM and trip the child's trap independent of the runner).
  sleep 0.3
  remaining=$(find "$F_TMPBASE" -maxdepth 1 -type d -name 'dev-crew-snap.*' 2>/dev/null | wc -l | tr -d ' ')
  # W1 mini-iteration follow-up: assert the EXACT 143/130 exit code, not just
  # "non-zero". A blanket nonzero check would also pass under mutation #9
  # (explicit `exit` removed from the signal trap), since FAIL>0 -> exit 1
  # already happens to be nonzero too -- exact codes are the only thing that
  # actually distinguishes "the signal trap ran and exited 143/130" from
  # "something else made this nonzero".
  expected_rc=143
  [ "$sig" = "INT" ] && expected_rc=130
  if [ "$RUN_RC" -eq "$expected_rc" ] && [ ! -e "$F_CTL/zz-ran" ] && [ -e "$F_CTL/child-signaled" ] && [ "$remaining" -eq 0 ]; then
    pass "TC-27/TC-27b ($sig): exit $expected_rc, snapshot removed, no later test ran, signal forwarded to child"
  else
    fail "TC-27/TC-27b ($sig): exit $expected_rc, snapshot removed, no later test ran, signal forwarded to child (rc=$RUN_RC expected=$expected_rc zz_ran=$([ -e "$F_CTL/zz-ran" ] && echo yes || echo no) child_signaled=$([ -e "$F_CTL/child-signaled" ] && echo yes || echo no) remaining=$remaining)"
  fi

  # Currently (RED) nothing forwards the signal, so the orphaned sleeper can
  # linger for up to 30s; sweep it with SIGKILL (never plain pkill, which
  # defaults to SIGTERM and would falsely satisfy the assertion above).
  pkill -KILL -f "test-aa-slow.sh" >/dev/null 2>&1 || true
  pkill -KILL -f "test-zz-never.sh" >/dev/null 2>&1 || true
done

# TC-27c
# Given: both the signal handler AND the EXIT trap fire for the same run
# When: SIGTERM delivered mid-run
# Then: cleanup is idempotent -- no double-remove error noise, and the
#       snapshot ends up fully (not partially) gone
echo ""
echo "TC-27c: signal handler + EXIT trap both firing -> cleanup is idempotent"
new_fixture
rm -f "$F_DEV/tests/test-zz-dummy.sh"
cat > "$F_DEV/tests/test-aa-slow.sh" <<'SLOW2'
#!/bin/bash
trap 'exit 143' TERM INT
sleep 30 &
wait $!
SLOW2
chmod +x "$F_DEV/tests/test-aa-slow.sh"
RUN_RC=0
( set -m
  ( cd "$F_DEV" && exec env TMPDIR="$F_TMPBASE" PATH="$F_BIN:$PATH" DCRUN_CTL="$F_CTL" DCRUN_EVIDENCE="$F_CTL" bash run-tests.sh >"$F_CTL/.stdout" 2>"$F_CTL/.stderr" ) &
  subj_pid=$!
  sleep 0.3
  kill -s TERM "$subj_pid" 2>/dev/null || true
  wait "$subj_pid"
) || RUN_RC=$?
RUN_OUT="$(cat "$F_CTL/.stdout" 2>/dev/null || true)"
RUN_ERR="$(cat "$F_CTL/.stderr" 2>/dev/null || true)"
sleep 0.3
remaining=$(find "$F_TMPBASE" -maxdepth 1 -type d -name 'dev-crew-snap.*' 2>/dev/null | wc -l | tr -d ' ')
if [ "$RUN_RC" -ne 0 ] && [ "$remaining" -eq 0 ] && ! printf '%s' "$RUN_ERR" | grep -qiE 'no such file or directory|cannot remove'; then
  pass "TC-27c: cleanup after TERM is idempotent (no double-remove errors, snapshot fully gone)"
else
  fail "TC-27c: cleanup after TERM is idempotent (no double-remove errors, snapshot fully gone) (rc=$RUN_RC remaining=$remaining err='$RUN_ERR')"
fi
pkill -KILL -f "test-aa-slow.sh" >/dev/null 2>&1 || true

# TC-28
# Given: a dev-crew-snap.* with a dead owner PID
# When: startup cleanup runs
# Then: it is removed
echo ""
echo "TC-28: a dev-crew-snap.* with a dead owner PID is removed at startup"
new_fixture
( exit 0 ) & dead_pid=$!; wait "$dead_pid" 2>/dev/null || true
mk_stale_snap "dev-crew-snap.tc28dead" "pid=$dead_pid
start=x
created=0"
run_subject
if [ "$RUN_RC" -eq 0 ] && [ ! -d "$F_TMPBASE/dev-crew-snap.tc28dead" ]; then
  pass "TC-28: dead-owner snapshot removed at startup"
else
  fail "TC-28: dead-owner snapshot removed at startup (rc=$RUN_RC exists=$([ -d "$F_TMPBASE/dev-crew-snap.tc28dead" ] && echo yes || echo no))"
fi

# TC-29
# Given: a dev-crew-snap.* with a LIVE owner PID, but old (old-but-live)
# When: startup cleanup runs
# Then: it is NOT removed
echo ""
echo "TC-29: a dev-crew-snap.* with a LIVE owner PID is preserved even if old (old-but-live)"
new_fixture
sleep 300 & live_pid=$!; ALL_SLEEP_PIDS+=("$live_pid")
# W6/B3 mini-iteration follow-up: the `.owner` `start=` token is now actually
# used by startup_cleanup (cross-checked against the live process's real
# lstart, to detect PID reuse -- see TC-29b). A placeholder like "x" would
# itself look like a reused PID and be wrongly removed, so this must be the
# process's REAL start time, not a filler value.
sleep 0.05
real_start="$(ps -o lstart= -p "$live_pid" 2>/dev/null | tr -s ' ' '_')"
mk_stale_snap "dev-crew-snap.tc29live" "pid=$live_pid
start=$real_start
created=0" 120
run_subject
if [ "$RUN_RC" -eq 0 ] && [ -d "$F_TMPBASE/dev-crew-snap.tc29live" ]; then
  pass "TC-29: live-owner snapshot preserved despite being old"
else
  fail "TC-29: live-owner snapshot preserved despite being old (rc=$RUN_RC exists=$([ -d "$F_TMPBASE/dev-crew-snap.tc29live" ] && echo yes || echo no))"
fi
kill -KILL "$live_pid" >/dev/null 2>&1 || true

# TC-29b (mini-iteration follow-up, W6/B3)
# Given: owner PID is LIVE, but the recorded start token does NOT match that
#        process's actual start time (simulates the PID having been reused
#        by an unrelated process after the true owner already exited)
# When: startup cleanup runs
# Then: it IS removed -- `kill -0` succeeding is not, by itself, sufficient
#       evidence that the live process is the true owner
echo ""
echo "TC-29b: live PID but mismatched start token (simulated PID reuse) -> removed"
new_fixture
sleep 300 & live_pid2=$!; ALL_SLEEP_PIDS+=("$live_pid2")
mk_stale_snap "dev-crew-snap.tc29bstale" "pid=$live_pid2
start=not-the-real-start-time
created=0" 120
run_subject
if [ "$RUN_RC" -eq 0 ] && [ ! -d "$F_TMPBASE/dev-crew-snap.tc29bstale" ]; then
  pass "TC-29b: live PID with a mismatched start token (simulated reuse) is removed"
else
  fail "TC-29b: live PID with a mismatched start token (simulated reuse) is removed (rc=$RUN_RC exists=$([ -d "$F_TMPBASE/dev-crew-snap.tc29bstale" ] && echo yes || echo no))"
fi
kill -KILL "$live_pid2" >/dev/null 2>&1 || true

# TC-30
# Given: owner metadata missing/unparseable, AND under snapshot_stale_minutes
# When: startup cleanup runs
# Then: NOT removed
echo ""
echo "TC-30: owner missing/unparseable AND under snapshot_stale_minutes -> preserved"
new_fixture
mk_stale_snap "dev-crew-snap.tc30missing" MISSING 5
mk_stale_snap "dev-crew-snap.tc30garbage" GARBAGE 5
run_subject
if [ "$RUN_RC" -eq 0 ] && [ -d "$F_TMPBASE/dev-crew-snap.tc30missing" ] && [ -d "$F_TMPBASE/dev-crew-snap.tc30garbage" ]; then
  pass "TC-30: missing/unparseable owner under the staleness threshold is preserved"
else
  fail "TC-30: missing/unparseable owner under the staleness threshold is preserved (rc=$RUN_RC missing=$([ -d "$F_TMPBASE/dev-crew-snap.tc30missing" ] && echo yes || echo no) garbage=$([ -d "$F_TMPBASE/dev-crew-snap.tc30garbage" ] && echo yes || echo no))"
fi

# TC-31
# Given: owner metadata missing/unparseable, AND past snapshot_stale_minutes
# When: startup cleanup runs
# Then: removed
echo ""
echo "TC-31: owner missing/unparseable AND past snapshot_stale_minutes -> removed"
new_fixture
mk_stale_snap "dev-crew-snap.tc31missing" MISSING 90
mk_stale_snap "dev-crew-snap.tc31garbage" GARBAGE 90
run_subject
if [ "$RUN_RC" -eq 0 ] && [ ! -d "$F_TMPBASE/dev-crew-snap.tc31missing" ] && [ ! -d "$F_TMPBASE/dev-crew-snap.tc31garbage" ]; then
  pass "TC-31: missing/unparseable owner past the staleness threshold is removed"
else
  fail "TC-31: missing/unparseable owner past the staleness threshold is removed (rc=$RUN_RC missing=$([ -d "$F_TMPBASE/dev-crew-snap.tc31missing" ] && echo yes || echo no) garbage=$([ -d "$F_TMPBASE/dev-crew-snap.tc31garbage" ] && echo yes || echo no))"
fi

# TC-32
# Given: a temp dir under the same TMPDIR but with a DIFFERENT prefix
# When: startup cleanup runs
# Then: left alone
echo ""
echo "TC-32: a temp dir with a DIFFERENT prefix is left alone"
new_fixture
mkdir -p "$F_TMPBASE/other-tool.abcdef"
run_subject
if [ "$RUN_RC" -eq 0 ] && [ -d "$F_TMPBASE/other-tool.abcdef" ]; then
  pass "TC-32: differently-prefixed temp dir is not touched"
else
  fail "TC-32: differently-prefixed temp dir is not touched (rc=$RUN_RC exists=$([ -d "$F_TMPBASE/other-tool.abcdef" ] && echo yes || echo no))"
fi

# TC-33
# Given: a dev-crew-snap.* entry that is a symlink to a target OUTSIDE TMPDIR
# When: startup cleanup runs
# Then: not followed, target not deleted
echo ""
echo "TC-33: a dev-crew-snap.* symlink pointing outside TMPDIR is not followed or deleted"
new_fixture
outside_dir="$(mktemp -d)"
ALL_FIX+=("$outside_dir")
touch "$outside_dir/canary"
ln -s "$outside_dir" "$F_TMPBASE/dev-crew-snap.tc33link"
run_subject
if [ "$RUN_RC" -eq 0 ] && [ -e "$outside_dir/canary" ]; then
  pass "TC-33: symlink target outside TMPDIR survives (not followed/deleted)"
else
  fail "TC-33: symlink target outside TMPDIR survives (not followed/deleted) (rc=$RUN_RC canary_exists=$([ -e "$outside_dir/canary" ] && echo yes || echo no))"
fi

# TC-34
# Given: a dev-crew-snap.* entry that is NOT a directory
# When: startup cleanup runs
# Then: it is out of scope for cleanup (left alone)
echo ""
echo "TC-34: a non-directory dev-crew-snap.* entry is left alone (not a cleanup target)"
new_fixture
printf 'not a directory\n' > "$F_TMPBASE/dev-crew-snap.tc34file"
run_subject
if [ "$RUN_RC" -eq 0 ] && [ -f "$F_TMPBASE/dev-crew-snap.tc34file" ]; then
  pass "TC-34: non-directory dev-crew-snap.* entry survives"
else
  fail "TC-34: non-directory dev-crew-snap.* entry survives (rc=$RUN_RC exists=$([ -f "$F_TMPBASE/dev-crew-snap.tc34file" ] && echo yes || echo no))"
fi

# TC-35
# Given: a dead-owner stale snapshot that cannot be deleted (permission denied)
# When: startup cleanup runs
# Then: only a warning is emitted; the suite still runs to completion
echo ""
echo "TC-35: a deletion failure (permission denied) only warns; the suite still continues"
new_fixture
( exit 0 ) & dead_pid2=$!; wait "$dead_pid2" 2>/dev/null || true
mk_stale_snap "dev-crew-snap.tc35locked" "pid=$dead_pid2
start=x
created=0"
chmod 000 "$F_TMPBASE/dev-crew-snap.tc35locked"
run_subject
if [ "$RUN_RC" -eq 0 ] && printf '%s' "$RUN_ERR" | grep -qi "warn"; then
  pass "TC-35: undeletable stale snapshot only warns, suite still completes"
else
  fail "TC-35: undeletable stale snapshot only warns, suite still completes (rc=$RUN_RC err='$RUN_ERR')"
fi
chmod -R u+rwx "$F_TMPBASE/dev-crew-snap.tc35locked" 2>/dev/null || true

# TC-35b (mini-iteration follow-up, B3)
# Given: an EMPTY dev-crew-snap.* directory that cannot be inspected (chmod
#        000, simulating a crash immediately after `mktemp -d`, before
#        `.owner` or any payload was written)
# When: startup cleanup runs
# Then: it is WARNED about and PRESERVED, not silently removed. This is the
#       actual discriminator for the "inspect-fail -> warn and keep" fix: a
#       payload-bearing 000 dir (TC-35) already fails `rm -rf` loudly on its
#       own and looks identical whether or not this branch even attempts a
#       delete, but an EMPTY 000 dir's final `rmdir` succeeds even without
#       read/execute on the entry itself (permission for removing a
#       directory entry is checked on the PARENT, not the entry) -- so the
#       pre-fix code silently removed it with no warning at all.
echo ""
echo "TC-35b: an empty unreadable snapshot dir is warned about and preserved, not silently removed"
new_fixture
mkdir -p "$F_TMPBASE/dev-crew-snap.tc35bempty"
chmod 000 "$F_TMPBASE/dev-crew-snap.tc35bempty"
run_subject
if [ "$RUN_RC" -eq 0 ] && [ -d "$F_TMPBASE/dev-crew-snap.tc35bempty" ] && printf '%s' "$RUN_ERR" | grep -qi "warn"; then
  pass "TC-35b: empty unreadable snapshot dir preserved with a warning"
else
  fail "TC-35b: empty unreadable snapshot dir preserved with a warning (rc=$RUN_RC exists=$([ -d "$F_TMPBASE/dev-crew-snap.tc35bempty" ] && echo yes || echo no) err='$RUN_ERR')"
fi
chmod -R u+rwx "$F_TMPBASE/dev-crew-snap.tc35bempty" 2>/dev/null || true

# ===========================================================================
# 実行後の live tree 変化 (advisory)
# ===========================================================================

# TC-36
# Given: the live tree does not change during the run
# When: runner completes
# Then: reported as unchanged, exit 0
echo ""
echo "TC-36: no live-tree changes during the run -> reported as unchanged, exit 0"
new_fixture
run_subject
if [ "$RUN_RC" -eq 0 ] && printf '%s' "$RUN_OUT$RUN_ERR" | grep -Eqi 'no.*change|unchanged|0 change'; then
  pass "TC-36: unchanged live tree reported, exit 0"
else
  fail "TC-36: unchanged live tree reported, exit 0 (rc=$RUN_RC out+err='$RUN_OUT$RUN_ERR')"
fi

# TC-37
# Given: a test that, while the suite runs (from inside the snapshot or not),
#        writes into the KNOWN live tree path -- simulating e.g. a PdM
#        appending to the Cycle doc concurrently with the suite run
# When: runner completes
# Then: the changed path is listed as a warning, but exit stays 0
echo ""
echo "TC-37: live tree changes during the run -> changed paths listed, exit remains 0"
new_fixture
cat > "$F_DEV/tests/test-mm-mutator.sh" <<'MUT'
#!/bin/bash
if [ -n "${DCRUN_LIVE_DEV:-}" ]; then
  printf 'concurrent edit\n' >> "$DCRUN_LIVE_DEV/LIVE_EDIT_DURING_RUN.txt"
fi
exit 0
MUT
chmod +x "$F_DEV/tests/test-mm-mutator.sh"
EXTRA_ENV="DCRUN_LIVE_DEV=$F_DEV"
run_subject
unset EXTRA_ENV
combined="$RUN_OUT$RUN_ERR"
if [ "$RUN_RC" -eq 0 ] && printf '%s' "$combined" | grep -q "LIVE_EDIT_DURING_RUN.txt"; then
  pass "TC-37: live-tree change during the run is listed as a warning, exit stays 0"
else
  fail "TC-37: live-tree change during the run is listed as a warning, exit stays 0 (rc=$RUN_RC out+err='$combined')"
fi

# TC-38
# Given: warn_on_live_changes = false, same concurrent live-tree edit as TC-37
# When: runner completes
# Then: no warning is emitted, exit remains 0
echo ""
echo "TC-38: warn_on_live_changes=false -> the same live-tree change is not warned about"
new_fixture
write_config '{"k_load": 2, "mem_min_mib": 3584, "snapshot_stale_minutes": 60, "warn_on_live_changes": false}'
cat > "$F_DEV/tests/test-mm-mutator.sh" <<'MUT2'
#!/bin/bash
if [ -n "${DCRUN_LIVE_DEV:-}" ]; then
  printf 'concurrent edit\n' >> "$DCRUN_LIVE_DEV/LIVE_EDIT_DURING_RUN.txt"
fi
exit 0
MUT2
chmod +x "$F_DEV/tests/test-mm-mutator.sh"
EXTRA_ENV="DCRUN_LIVE_DEV=$F_DEV"
run_subject
unset EXTRA_ENV
combined="$RUN_OUT$RUN_ERR"
if [ "$RUN_RC" -eq 0 ] && ! printf '%s' "$combined" | grep -q "LIVE_EDIT_DURING_RUN.txt"; then
  pass "TC-38: warn_on_live_changes=false suppresses the live-change warning"
else
  fail "TC-38: warn_on_live_changes=false suppresses the live-change warning (rc=$RUN_RC out+err='$combined')"
fi

# ===========================================================================
# ps-shim direct unit test (mini-iteration follow-up, B6)
# ===========================================================================

# TC-45
# Given: a fabricated `ps -axo pid=,ppid=` table (self -> a fake ancestor ->
#        a fake grandparent -> pid 1, plus an unrelated sibling PID with no
#        path back to self), delivered via a PATH shim that dispatches ONLY
#        that exact `ps` invocation to the fabricated table and passes every
#        OTHER `ps` call straight through to the real binary
# When: build_exclude_set()/is_excluded_pid() are unit-tested directly by
#       sourcing the runner as a library (DEV_CREW_RUNNER_LIB_ONLY=1, a
#       source guard added for exactly this purpose) -- not by shelling out
#       through `pgrep`
# Then: self and the fabricated ancestor ARE excluded; the unrelated sibling
#       is NOT. This exercises the PID-lineage logic itself, independent of
#       macOS pgrep's own built-in ancestor-exclusion default, which is what
#       made TC-04/TC-04b unable to discriminate a correct vs. broken
#       self/ancestor exclusion implementation (`man pgrep`'s `-a` section:
#       "By default, the current pgrep or pkill process and all of its
#       ancestors are excluded" -- see docs/cycles/20260913_0059 VERIFY /
#       DISCOVERED). Descendant exclusion is deliberately NOT exercised here:
#       it was removed as dead code in this mini-iteration (admission_check,
#       which calls build_exclude_set, runs strictly before any test child
#       is forked).
echo ""
echo "TC-45: build_exclude_set()/is_excluded_pid() unit-tested via a fabricated ps table"
new_fixture
mkdir -p "$F_CTL/psbin"
cat > "$F_CTL/psbin/ps" <<'PSSHIM'
#!/bin/bash
TBL="${DCRUN_PS_TABLE:?DCRUN_PS_TABLE not set}"
case "$*" in
  "-axo pid=,ppid="*) cat "$TBL" ;;
  *) exec /bin/ps "$@" ;;
esac
PSSHIM
chmod +x "$F_CTL/psbin/ps"

cat > "$F_CTL/tc45_inner.sh" <<'INNER'
#!/bin/bash
set -uo pipefail
SELF=$$
ANCESTOR=$((SELF + 1000000))
GRANDPARENT=$((SELF + 2000000))
UNRELATED=$((SELF + 3000000))
{
  printf '%s %s\n' "$SELF" "$ANCESTOR"
  printf '%s %s\n' "$ANCESTOR" "$GRANDPARENT"
  printf '%s %s\n' "$GRANDPARENT" "1"
  printf '%s %s\n' "$UNRELATED" "1"
} > "$DCRUN_PS_TABLE"
DEV_CREW_RUNNER_LIB_ONLY=1 source ./run-tests.sh
build_exclude_set
is_excluded_pid "$SELF";       echo "self=$?"
is_excluded_pid "$ANCESTOR";   echo "ancestor=$?"
is_excluded_pid "$UNRELATED";  echo "unrelated=$?"
INNER
chmod +x "$F_CTL/tc45_inner.sh"

tc45_out="$F_CTL/tc45_out"
( cd "$F_DEV" && env PATH="$F_CTL/psbin:$PATH" DCRUN_PS_TABLE="$F_CTL/ps.table" bash "$F_CTL/tc45_inner.sh" ) > "$tc45_out" 2>&1
if grep -q '^self=0$' "$tc45_out" && grep -q '^ancestor=0$' "$tc45_out" && grep -q '^unrelated=1$' "$tc45_out"; then
  pass "TC-45: self + fabricated ancestor excluded, unrelated sibling not excluded"
else
  fail "TC-45: self + fabricated ancestor excluded, unrelated sibling not excluded (out='$(cat "$tc45_out")')"
fi

# TC-46
# Given: TMPDIR resolves to a directory INSIDE BASE_DIR (the fixture's
#        agents/dev-crew tree), AND a `mktemp` PATH shim that forces GNU/Linux
#        bare-mktemp semantics (bare `mktemp` honors $TMPDIR). This shim is
#        required for the TC to be non-vacuous on macOS: macOS's own BSD
#        mktemp prioritizes _CS_DARWIN_USER_TEMP_DIR over $TMPDIR for a bare
#        call (confirmed by `man mktemp` + measurement: `TMPDIR=/x mktemp`
#        still resolves under /var/folders/.../T on this platform), so
#        without the shim compute_manifest()'s bare `mktemp` calls never
#        actually land under BASE_DIR here and this TC would pass vacuously
#        even against the pre-fix implementation (measured directly: it did).
#        determine_safe_tmpdir() detects TMPDIR-inside-BASE_DIR and falls
#        SAFE_TMPDIR back to /tmp, but the TMPDIR *environment variable
#        itself* is left untouched (docs/cycles/20260913_0059 review F1:
#        compute_manifest()'s `mktemp` calls read $TMPDIR directly, bypassing
#        $SAFE_TMPDIR, so pre-fix -- under GNU semantics -- their scratch
#        files still land under BASE_DIR)
# When: runner invoked with that TMPDIR and the mktemp shim
# Then: compute_manifest's own scratch files never land under BASE_DIR, so
#       manifest A/B/C stay mutually consistent and the run exits 0 (the
#       fixture's one dummy test passes). Pre-fix -- under the shim's GNU
#       semantics -- the scratch file self-included in the BASE_DIR find
#       corrupts manifest A: the file is deleted before the batched
#       stat/shasum pass (L695-ish `rm -f "$filelist"`), so `xargs stat`
#       fails on a vanished path, compute_manifest returns 1 (not 2), and
#       build_snapshot classifies this as "infra", not "mismatch" -- so the
#       actual pre-fix failure is exit 5, NOT the exit-4 the reviewer's
#       static analysis predicted (measured directly). Assert rc==0 rather
#       than rc!=4 so this TC still catches the regression on either wrong
#       exit code.
echo ""
echo "TC-46: TMPDIR pointing inside BASE_DIR does not corrupt the manifest (compute_manifest scratch files must go through SAFE_TMPDIR)"
new_fixture
mkdir -p "$F_DEV/tmp-inside-repo"
cat > "$F_BIN/mktemp" <<'SHIM'
#!/bin/bash
# GNU/Linux bare-mktemp semantics: honor $TMPDIR. macOS's own mktemp ignores
# $TMPDIR for the bare (no-argument) form (prioritizes _CS_DARWIN_USER_TEMP_DIR
# instead), which would make TC-46 vacuous without this shim. A templated call
# (e.g. `mktemp -d ".../XXXXXX"`, used by run-tests.sh's own SNAP creation and,
# post-fix, by compute_manifest) is passed straight through untouched.
if [ $# -eq 0 ]; then
  exec /usr/bin/mktemp "${TMPDIR:-/tmp}/tmp.XXXXXXXXXX"
fi
exec /usr/bin/mktemp "$@"
SHIM
chmod +x "$F_BIN/mktemp"
EXTRA_ENV="TMPDIR=$F_DEV/tmp-inside-repo"
run_subject
unset EXTRA_ENV
where="$(evidence_where)"
if [ "$RUN_RC" -eq 0 ] && printf '%s' "$where" | grep -q "dev-crew-snap\."; then
  pass "TC-46: TMPDIR inside BASE_DIR does not corrupt the manifest (rc=$RUN_RC)"
else
  fail "TC-46: TMPDIR inside BASE_DIR does not corrupt the manifest (rc=$RUN_RC err='$RUN_ERR')"
fi

# ===========================================================================
# 条項・doc (not fixture-based; grep against the real repo files directly)
# ===========================================================================

# TC-39
# Given: rules/agent-prompts.md (and its .claude/rules/ mirror)
# When: grepping for the D5 completion-notification semantics
# Then: BOTH halves are pinned verbatim (not merely "some mention exists")
echo ""
echo "TC-39: rules/agent-prompts.md pins BOTH halves of the completion-notification semantics (+ mirror)"
half1='turn が終わったことを示すだけ'
half2='background descendant の終了を保証しない'
if grep -qF "$half1" "$BASE_DIR/rules/agent-prompts.md" \
   && grep -qF "$half2" "$BASE_DIR/rules/agent-prompts.md" \
   && grep -qF "$half1" "$BASE_DIR/.claude/rules/agent-prompts.md" \
   && grep -qF "$half2" "$BASE_DIR/.claude/rules/agent-prompts.md"; then
  pass "TC-39: both halves of the completion-notification semantics pinned in rules/agent-prompts.md and its mirror"
else
  fail "TC-39: both halves of the completion-notification semantics pinned in rules/agent-prompts.md and its mirror"
fi

# TC-40 (regression pin -- pre-existing content, expected to PASS already)
# Given: rules/agent-prompts.md
# When: grepping for the pre-existing literal
# Then: 「読み取り並列・実行直列」「テスト実行可否」+ citation remain
echo ""
echo "TC-40: rules/agent-prompts.md retains the pre-existing parallel/serial literal + citation (regression pin)"
if grep -qF "読み取り並列・実行直列" "$BASE_DIR/rules/agent-prompts.md" \
   && grep -qF "テスト実行可否" "$BASE_DIR/rules/agent-prompts.md" \
   && grep -qF "20260702_1200" "$BASE_DIR/rules/agent-prompts.md"; then
  pass "TC-40: pre-existing parallel/serial literal + citation retained"
else
  fail "TC-40: pre-existing parallel/serial literal + citation retained"
fi

# TC-41 (regression pin -- pre-existing content, expected to PASS already)
# Given: rules/plan-discipline.md
# When: grepping for the pre-existing literal
# Then: 「immutable snapshot 複製」「並行プロセスから隔離」+ citation remain
echo ""
echo "TC-41: rules/plan-discipline.md retains the pre-existing immutable-snapshot literal + citation (regression pin)"
if grep -qF "immutable snapshot 複製" "$BASE_DIR/rules/plan-discipline.md" \
   && grep -qF "並行プロセスから隔離" "$BASE_DIR/rules/plan-discipline.md" \
   && grep -qF "20260702_1200" "$BASE_DIR/rules/plan-discipline.md"; then
  pass "TC-41: pre-existing immutable-snapshot literal + citation retained"
else
  fail "TC-41: pre-existing immutable-snapshot literal + citation retained"
fi

# TC-42 (regression pin -- checked INLINE, never by invoking test-rules-mirror.sh)
# Given: rules/*.md and .claude/rules/*.md
# When: diffed pairwise
# Then: identical outside the post-approve.md allowlist
echo ""
echo "TC-42: rules/*.md and .claude/rules/*.md match exactly (allowlist: post-approve.md) -- checked inline"
tc42_ok=1
tc42_detail=""
for f in "$BASE_DIR"/rules/*.md; do
  name="$(basename "$f")"
  [ "$name" = "post-approve.md" ] && continue
  mirror="$BASE_DIR/.claude/rules/$name"
  if [ ! -f "$mirror" ] || ! diff -q "$f" "$mirror" >/dev/null 2>&1; then
    tc42_ok=0
    tc42_detail="$tc42_detail $name"
  fi
done
if [ "$tc42_ok" -eq 1 ]; then
  pass "TC-42: rules/*.md <-> .claude/rules/*.md match exactly outside the post-approve.md allowlist"
else
  fail "TC-42: rules/*.md <-> .claude/rules/*.md match exactly outside the post-approve.md allowlist - differing:$tc42_detail"
fi

# TC-43
# Given: AGENTS.md's '## Quick Start' section (section-scoped, not whole-file)
# When: inspected
# Then: BOTH lines point at run-tests.sh, and the old direct-invocation forms
#       are gone (negative sweep target is AGENTS.md ONLY -- generic templates
#       and tests/test-sync-plan-migration.sh:159's comment are explicitly out)
echo ""
echo "TC-43: AGENTS.md Quick Start uses run-tests.sh for both lines; old direct forms are gone"
qs="$(section_lines "$BASE_DIR/AGENTS.md" "Quick Start")"
rtcount=$(printf '%s\n' "$qs" | grep -cF "run-tests.sh" || true)
if [ "$rtcount" -ge 2 ] \
   && ! printf '%s' "$qs" | grep -qF 'for f in tests/test-*.sh; do bash "$f"; done' \
   && ! printf '%s' "$qs" | grep -qF 'bash tests/test-plugin-structure.sh'; then
  pass "TC-43: AGENTS.md Quick Start fully migrated to run-tests.sh (both lines), old forms removed"
else
  fail "TC-43: AGENTS.md Quick Start fully migrated to run-tests.sh (both lines), old forms removed (occurrences=$rtcount)"
fi

# TC-44
# Given: rules/plan-discipline.md's '## 具体例' section
# When: inspected
# Then: its own ad-hoc snapshot loop is gone, replaced by a run-tests.sh call
echo ""
echo "TC-44: rules/plan-discipline.md '## 具体例' no longer has its own snapshot loop"
ex="$(section_lines "$BASE_DIR/rules/plan-discipline.md" "具体例")"
if ! printf '%s' "$ex" | grep -qF 'cp -R . "$SNAP"' \
   && printf '%s' "$ex" | grep -qF "run-tests.sh"; then
  pass "TC-44: '## 具体例' no longer duplicates the snapshot loop; delegates to run-tests.sh"
else
  fail "TC-44: '## 具体例' no longer duplicates the snapshot loop; delegates to run-tests.sh"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS"
echo "FAIL: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi

exit 0
