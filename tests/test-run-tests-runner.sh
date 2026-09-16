#!/bin/bash
# test-run-tests-runner.sh - run-tests.sh admission + immutable snapshot tests
# TC-01~TC-52 (30 labels / 31 assertions; TC-27b lives inside the TC-27 block).
# All fixture-based; the real tests/ suite is NEVER invoked from inside this
# file (that would recurse into run-tests.sh's own full-suite execution — see
# docs/cycles/20260913_0059).
#
# Fixture design (per Cycle doc fixture 設計 section):
#   - subject = a COPY of run-tests.sh under a mktemp'd fixture root, never the live one
#   - dummy test(s) only under the fixture tests/, never the real tests/ tree
#   - fixture-local TMPDIR passed via `env TMPDIR=...`, a SIBLING of the fixture
#     source tree (D3: "${TMPDIR} が source repo 内を指す場合は拒否" — TMPDIR must
#     not be nested inside the copied repo)
#   - probes (pgrep) faked via a PATH-prepended shim directory that defaults to
#     REAL passthrough unless a control file requests fake/absent
#
# Exit code contract (docs/cycles/20260916_1634_shrink-runner-remove-nesting.md):
#   0=all PASS, 1=one or more executed tests FAILed (never repurposed for infra
#   failure), 2=runner could not start (admission BLOCK / snapshot creation
#   failure / copy failure, unified), 3=argument rejection. 4/5 retired.
#   Signal-driven exits (129/130/143) remain separate.
#
# `.owner` snapshot metadata, the fingerprint three-way match, the retry
# protocol, load/memory admission, the config file they read
# (.claude/test-serialization.json), and the jq dependency it required were
# all removed in the same cycle. The TCs that pinned that machinery were
# removed with it -- 31 TC total: TC-04/04b (pgrep self/ancestor-exclusion
# oracle, vacuous under real pgrep on macOS), TC-05/06/10 (load/memory
# admission), TC-07/08/09 (multi-condition fail-open combinations),
# TC-11/12/13 (config file + jq), TC-21/22/23/24/24b/25c (fingerprint
# three-way match + retry protocol), TC-28~35/35b (owner metadata / staleness
# / reaper), TC-36/37/38 (live-tree-change advisory), TC-45
# (DEV_CREW_RUNNER_LIB_ONLY / source-as-library). See the Cycle doc Test List
# for the full deletion/keep breakdown.
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
# Fixture construction
# ---------------------------------------------------------------------------
# new_fixture: builds a fresh isolated fixture tree and sets:
#   F_ROOT F_REPO F_DEV F_TMPBASE F_BIN F_CTL
# Layout:
#   F_ROOT/
#     repo-root/docs/test_architecture.md          (parent-of-parent doc, per D3 layout)
#     repo-root/agents/dev-crew/ = F_DEV            (copy of run-tests.sh + dummy test)
#     tmpbase/                   = F_TMPBASE         (sibling TMPDIR, NOT inside repo-root)
#     bin/                       = F_BIN             (PATH-shimmed pgrep/cp)
#     ctl/                       = F_CTL             (shim control files + evidence, outside repo-root)
new_fixture() {
  F_ROOT="$(mktemp -d)"
  ALL_FIX+=("$F_ROOT")
  F_REPO="$F_ROOT/repo-root"
  F_DEV="$F_REPO/agents/dev-crew"
  F_TMPBASE="$F_ROOT/tmpbase"
  F_BIN="$F_ROOT/bin"
  F_CTL="$F_ROOT/ctl"
  mkdir -p "$F_REPO/docs" "$F_DEV/tests" "$F_TMPBASE" "$F_BIN" "$F_CTL"

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

  chmod +x "$F_BIN/pgrep"

  # cp shim (TC-48/TC-49): defaults to REAL passthrough, like the probes
  # above. Two non-default modes:
  #   fail          -- every invocation fails (TC-49: build_snapshot's copy
  #                    step cannot succeed at all)
  #   delete-before -- before exec'ing the real /bin/cp, rm -f a single
  #                    target path (TC-48: reproduces the post-validation /
  #                    pre-copy TOCTOU window WITHOUT depending on the
  #                    production DEV_CREW_TEST_HOOK_BEFORE_COPY variable,
  #                    which B removes entirely from run-tests.sh)
  cat > "$F_BIN/cp" <<'SHIM'
#!/bin/bash
CTL="${DCRUN_CTL:?DCRUN_CTL not set}"
mode="real"
[ -f "$CTL/cp.mode" ] && mode="$(cat "$CTL/cp.mode")"
case "$mode" in
  fail)
    echo "cp: shim forced failure" >&2
    exit 1
    ;;
  delete-before)
    t="$(cat "$CTL/cp.delete_target" 2>/dev/null || true)"
    [ -n "$t" ] && rm -f "$t"
    exec /bin/cp "$@"
    ;;
  *) exec /bin/cp "$@" ;;
esac
SHIM
  chmod +x "$F_BIN/cp"

  set_admission_healthy
}

# --- probe control setters (write into $F_CTL, read by the shims above) ---
set_pgrep_absent() { echo absent > "$F_CTL/pgrep.mode"; }
set_pgrep_fake() { # rc out
  echo fake > "$F_CTL/pgrep.mode"
  printf '%s' "$1" > "$F_CTL/pgrep.rc"
  printf '%s' "$2" > "$F_CTL/pgrep.out"
}
set_cp_real() { echo real > "$F_CTL/cp.mode"; }
set_cp_fail() { echo fail > "$F_CTL/cp.mode"; }
set_cp_delete_before() { # abs_path_to_delete
  echo delete-before > "$F_CTL/cp.mode"
  printf '%s' "$1" > "$F_CTL/cp.delete_target"
}
# Healthy default so TCs that are NOT about admission specifics (arg
# normalization, snapshot consistency, cleanup, ...) sail through admission.
# Only pgrep remains as an admission condition (load/memory were removed).
set_admission_healthy() {
  set_pgrep_fake 1 ""
}

# ---------------------------------------------------------------------------
# Subject invocation
# ---------------------------------------------------------------------------
# run_subject [args...] : runs the fixture's run-tests.sh with the fixture's
# TMPDIR/PATH/DCRUN_CTL wired in. Sets RUN_RC / RUN_OUT / RUN_ERR. Never lets
# a non-zero rc trip `set -e` (guarded with `|| RUN_RC=$?`).
run_subject() {
  RUN_RC=0
  # ${EXTRA_ENV:-} is intentionally unquoted: callers (TC-46/TC-50, both
  # overriding TMPDIR to exercise the source-tree-boundary fallback) set it
  # to space-separated KEY=val pairs and rely on word splitting to hand `env`
  # one assignment per word. Quoting it would pass a single malformed
  # "KEY=val KEY2=val2" token instead.
  ( cd "$F_DEV" && env TMPDIR="$F_TMPBASE" PATH="$F_BIN:$PATH" DCRUN_CTL="$F_CTL" DCRUN_EVIDENCE="$F_CTL" ${EXTRA_ENV:-} bash run-tests.sh "$@" >"$F_CTL/.stdout" 2>"$F_CTL/.stderr" ) || RUN_RC=$?
  RUN_OUT="$(cat "$F_CTL/.stdout" 2>/dev/null || true)"
  RUN_ERR="$(cat "$F_CTL/.stderr" 2>/dev/null || true)"
}
evidence_where() { cat "$F_CTL/where" 2>/dev/null || true; }

# add_git_repo: turns $F_DEV into a tiny self-contained git repo (for TC-25b
# only -- NOT the real 22MB .git, a throwaway one committing whatever is
# currently in $F_DEV).
add_git_repo() {
  ( cd "$F_DEV" && git init -q && git config user.email "fixture@example.com" \
    && git config user.name "Fixture" && git add -A && git commit -q -m init )
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

# TC-46
# Given: TMPDIR resolves to a directory INSIDE BASE_DIR (the fixture's own
#        agents/dev-crew tree)
# When: runner invoked with that TMPDIR
# Then: the snapshot is NOT created inside the source tree -- this is the
#       MINIMAL source-tree-boundary contract this cycle keeps (B: 「削れな
#       い」。TMPDIR が repo 配下のとき `cp -Rp "$BASE_DIR"` が snapshot を
#       再帰的に含んでしまう事故の防止). Everything the prior TC-46
#       additionally pinned -- compute_manifest()'s own scratch-file
#       placement, exercised only via a GNU-mktemp-semantics PATH shim --
#       tested the fingerprint three-way-match machinery, which B removes
#       entirely; that coverage is deliberately NOT reintroduced here
#       (narrowed scope, not a weaker guarantee: the surviving assertion is
#       exactly what B commits to keeping, no more, no less).
echo ""
echo "TC-46: TMPDIR pointing inside BASE_DIR does not place the snapshot inside the source tree"
new_fixture
mkdir -p "$F_DEV/tmp-inside-repo"
EXTRA_ENV="TMPDIR=$F_DEV/tmp-inside-repo"
run_subject
unset EXTRA_ENV
where="$(evidence_where)"
if [ "$RUN_RC" -eq 0 ] \
   && printf '%s' "$where" | grep -q "dev-crew-snap\." \
   && ! printf '%s' "$where" | grep -qF "$F_DEV/"; then
  pass "TC-46: TMPDIR inside BASE_DIR -> snapshot stays outside the source tree (where=$where)"
else
  fail "TC-46: TMPDIR inside BASE_DIR -> snapshot stays outside the source tree (rc=$RUN_RC where='$where')"
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
# Given: rules/plan-discipline.md's '## 具体例' section (regression pin, kept
#        from the prior TC-44), its '## 推奨' section (extended by this
#        cycle -- Scope A: 「推奨行の direct loop を bash run-tests.sh へ」),
#        AND its '## 出典' section (the mini-iteration REVIEW B1 fix target:
#        both '## 具体例' and '## 出典' used to describe run-tests.sh as
#        still containing 三者照合（A==B==C）/ 起動時掃除 after cycle
#        20260916_1634 deleted that machinery -- doc drift the original
#        TC-44 never pinned), checked against BOTH rules/plan-discipline.md
#        and its .claude/rules/ mirror (test-rules-mirror.sh requires the
#        two trees to match exactly; fixing only one half would break that
#        contract)
# When: inspected
# Then: '## 具体例' still delegates to run-tests.sh (unchanged) AND no longer
#       claims run-tests.sh currently performs 三者照合; '## 推奨' no longer
#       recommends its own ad-hoc `for f in tests/test-*.sh` baseline loop --
#       it too must delegate to run-tests.sh; '## 出典' no longer claims
#       run-tests.sh currently contains 三者照合 either. All three checked in
#       both the primary file and the mirror
echo ""
echo "TC-44: rules/plan-discipline.md (+ mirror) '## 具体例'/'## 推奨'/'## 出典' no longer duplicate the snapshot/baseline loop or claim the deleted 三者照合 machinery is still current"
tc44_ok=1
tc44_detail=""
for f in "$BASE_DIR/rules/plan-discipline.md" "$BASE_DIR/.claude/rules/plan-discipline.md"; do
  ex="$(section_lines "$f" "具体例")"
  rec="$(section_lines "$f" "推奨")"
  src="$(section_lines "$f" "出典")"
  if printf '%s' "$ex" | grep -qF 'cp -R . "$SNAP"'; then
    tc44_ok=0; tc44_detail="$tc44_detail $f:具体例-has-ad-hoc-loop"
  fi
  if ! printf '%s' "$ex" | grep -qF "run-tests.sh"; then
    tc44_ok=0; tc44_detail="$tc44_detail $f:具体例-missing-run-tests.sh"
  fi
  if printf '%s' "$ex" | grep -qF "三者照合"; then
    tc44_ok=0; tc44_detail="$tc44_detail $f:具体例-still-claims-三者照合"
  fi
  if printf '%s' "$rec" | grep -qF 'for f in tests/test-*.sh'; then
    tc44_ok=0; tc44_detail="$tc44_detail $f:推奨-still-has-direct-loop"
  fi
  if ! printf '%s' "$rec" | grep -qF "run-tests.sh"; then
    tc44_ok=0; tc44_detail="$tc44_detail $f:推奨-missing-run-tests.sh"
  fi
  if printf '%s' "$src" | grep -qF "三者照合"; then
    tc44_ok=0; tc44_detail="$tc44_detail $f:出典-still-claims-三者照合"
  fi
done
if [ "$tc44_ok" -eq 1 ]; then
  pass "TC-44: '## 具体例' + '## 推奨' + '## 出典' (rules/ and mirror) delegate to run-tests.sh; no ad-hoc loops or stale 三者照合 claims remain"
else
  fail "TC-44: '## 具体例' + '## 推奨' + '## 出典' (rules/ and mirror) delegate to run-tests.sh; no ad-hoc loops or stale 三者照合 claims remain -$tc44_detail"
fi

# TC-48
# Given: an explicit test argument that exists at argument-validation time
#        (normalize_args() checks it against the LIVE tree), then a `cp`
#        PATH shim (delete-before mode) that deletes exactly that file from
#        the LIVE tree the moment the first `cp` invocation happens -- a
#        TOCTOU window that is real because argument validation happens
#        against the live tree while the snapshot copy happens strictly
#        afterward. B removes DEV_CREW_TEST_HOOK_* entirely from production
#        code (「案 a 確定」), so this replaces the prior TC-48's dependency
#        on DEV_CREW_TEST_HOOK_BEFORE_COPY with a fixture-only mechanism that
#        does not read any production hook variable at all
# When: runner invoked with that explicit argument
# Then: exit 3 (argument rejected), NOT exit 0. Pre-fix, the explicit
#       target's absence from the snapshot was never re-checked: the
#       0-targets guard only fires for an EMPTY targets array (never true
#       for an explicit arg, which is always appended unconditionally), and
#       the execution loop's `[ -f "$f" ] || continue` silently skipped the
#       missing file -- so the run reported 0 executed / PASS 0 / FAIL 0 and
#       STILL exited 0: a vacuous PASS for a test that never ran. B's fix
#       (run_tests_in_snapshot's explicit-arg re-validation against the
#       snapshot, not the live tree it was originally checked against) has
#       no fingerprinting or retry involved -- a single cp attempt, no
#       manifest comparison -- so no other stderr output is expected here.
echo ""
echo "TC-48: an explicit test arg deleted from the live tree via a cp shim (post-validation, pre-copy) is rejected (exit 3), not silently skipped"
new_fixture
cat > "$F_DEV/tests/test-zz-target.sh" <<'TARGET'
#!/bin/bash
exit 0
TARGET
chmod +x "$F_DEV/tests/test-zz-target.sh"
set_cp_delete_before "$F_DEV/tests/test-zz-target.sh"
run_subject tests/test-zz-target.sh
set_cp_real
combined="$RUN_OUT$RUN_ERR"
# rc==3 alone cannot distinguish "the new snapshot re-validation fired" from
# some unrelated exit-3 path, so the message is pinned too.
if [ "$RUN_RC" -eq 3 ] && printf '%s' "$combined" | grep -qF "not present in the snapshot"; then
  pass "TC-48: explicit-arg TOCTOU deletion via cp shim (no DEV_CREW_TEST_HOOK_* dependency) rejected with exit 3 and the snapshot-specific reason, not a vacuous PASS"
else
  fail "TC-48: explicit-arg TOCTOU deletion via cp shim (no DEV_CREW_TEST_HOOK_* dependency) rejected with exit 3 and the snapshot-specific reason, not a vacuous PASS (rc=$RUN_RC out+err='$combined')"
fi

# ===========================================================================
# 新設 TC -- replace the deleted PID/owner/reaper coverage and pin the new
# copy-failure exit code
# ===========================================================================

# TC-49
# Given: a `cp` PATH shim forced to fail on EVERY invocation (fixture-level
#        only -- NOT the production DEV_CREW_TEST_HOOK_* mechanism, which B
#        removes entirely). build_snapshot() makes up to two cp calls: the
#        parent-doc copy (guarded by `[ -f "$PARENT_DOC_SRC" ]`, which the
#        fixture's new_fixture() satisfies) THEN the repo copy (`cp -Rp
#        "$BASE_DIR" ...`, the actual target of this TC). With the parent doc
#        left in place, the "fail every call" shim fails at the FIRST cp
#        (the parent-doc copy) and the run never reaches the repo-copy path
#        at all -- both failures exit 2, so rc alone cannot tell them apart,
#        and the emitted message would be "failed to copy the parent doc",
#        not "failed to copy the repo" (REVIEW mini-iteration A3 / Codex
#        BLOCK: this TC previously never reached what it claimed to test).
#        Removing the fixture's parent doc makes the `[ -f ... ]` guard
#        false, so build_snapshot skips straight to the repo copy -- the
#        only cp call left, and the one this TC is actually about.
# When: runner invoked
# Then: exit 2, with the repo-copy-specific message. B's exit-code table
#       collapses admission BLOCK, snapshot creation failure, AND copy
#       failure into a single exit 2 ("runner が開始不能"); exit 1 is
#       reserved exclusively for "1 件以上 FAIL（実行したテストの FAIL の
#       み、流用禁止）". A copy failure means no test ever got the chance to
#       run, so it must never surface as exit 1 (which a caller would
#       misread as "the code under test is broken") nor as today's exit 4/5
#       (both retired by B).
echo ""
echo "TC-49: repo copy failure exits 2 with the repo-copy message, never conflated with exit 1's 'a test FAILed' or the parent-doc-copy failure path"
new_fixture
rm -f "$F_REPO/docs/test_architecture.md"
set_cp_fail
run_subject
set_cp_real
combined="$RUN_OUT$RUN_ERR"
if [ "$RUN_RC" -eq 2 ] && printf '%s' "$combined" | grep -qF "failed to copy the repo"; then
  pass "TC-49: copy failure exits 2 (repo-copy path, not the parent-doc copy), not 1 (rc=$RUN_RC)"
else
  fail "TC-49: copy failure exits 2 (repo-copy path, not the parent-doc copy), not 1 (rc=$RUN_RC out='$RUN_OUT' err='$RUN_ERR')"
fi

# TC-50
# Given/When/Then (three sub-scenarios against ONE pass/fail, matching the
# TC-42/TC-44 tc44_ok/tc44_detail pattern -- keeps this a single Test List
# label, kept to a single Test List entry rather than three):
#
#   50-a) a pre-existing dev-crew-snap.* directory already sits under the
#         run's actual SAFE_TMPDIR (F_TMPBASE here -- no repo-boundary
#         fallback involved) => runner warns about it on stderr AND leaves
#         it in place (B-2: 「受容する」強制終了後の残骸を自動削除しない /
#         「警告は残す」). This replaces the deleted PID/owner/reaper
#         machinery (TC-28~35b) with a non-destructive report: the runner no
#         longer guesses which leftovers are safe to delete.
#   50-b) zero leftover snapshot directories under SAFE_TMPDIR => stderr is
#         completely silent about it (Round 4 finding #3: a naive `ls
#         "$dir"/dev-crew-snap.*` glob-no-match emits "No such file or
#         directory" to stderr even when there is genuinely nothing to warn
#         about; the fix must use an existence-guarded glob, not `ls`).
#   50-c) TMPDIR points INSIDE the repo (triggers determine_safe_tmpdir's
#         fallback to /tmp) and the leftover snapshot directory is seeded
#         directly under the REAL /tmp (the actual post-fallback
#         SAFE_TMPDIR), never under the raw repo-internal TMPDIR path =>
#         still warned about. This is the discriminating case: a scan that
#         (incorrectly) reads the raw $TMPDIR env var instead of the
#         boundary-checked $SAFE_TMPDIR would find nothing here and stay
#         silent, which this sub-scenario would catch. /tmp is a symlink to
#         /private/tmp on macOS, so the warning is matched by basename, not
#         full path (a `pwd -P`/realpath-based implementation would print
#         the /private/tmp form).
echo ""
echo "TC-50: startup residue scan warns about (never deletes) leftover snapshot directories, using the actual post-boundary-check SAFE_TMPDIR, and stays silent when there is nothing to report"
tc50_ok=1
tc50_detail=""

# 50-a: leftover under the normal (non-fallback) SAFE_TMPDIR
new_fixture
leftover_a="$F_TMPBASE/dev-crew-snap.leftovera"
mkdir -p "$leftover_a/agents/dev-crew"
printf 'payload\n' > "$leftover_a/agents/dev-crew/payload.txt"
run_subject
if [ "$RUN_RC" -ne 0 ] \
   || ! printf '%s' "$RUN_ERR" | grep -qF "leftover snapshot directory" \
   || ! printf '%s' "$RUN_ERR" | grep -qF "$(basename "$leftover_a")" \
   || [ ! -d "$leftover_a" ] || [ ! -f "$leftover_a/agents/dev-crew/payload.txt" ]; then
  tc50_ok=0
  tc50_detail="$tc50_detail 50a(rc=$RUN_RC err='$RUN_ERR' still_exists=$([ -d "$leftover_a" ] && echo yes || echo no))"
fi

# 50-b: zero leftovers -> completely silent stderr
new_fixture
run_subject
if [ "$RUN_RC" -ne 0 ] || [ -n "$RUN_ERR" ]; then
  tc50_ok=0
  tc50_detail="$tc50_detail 50b(rc=$RUN_RC err='$RUN_ERR')"
fi

# 50-c: leftover under the REAL fallback root (/tmp), TMPDIR points inside repo
new_fixture
mkdir -p "$F_DEV/tmp-inside-repo"
real_leftover="$(mktemp -d "/tmp/dev-crew-snap.XXXXXX")"
ALL_FIX+=("$real_leftover")
mkdir -p "$real_leftover/agents/dev-crew"
printf 'payload\n' > "$real_leftover/agents/dev-crew/payload.txt"
EXTRA_ENV="TMPDIR=$F_DEV/tmp-inside-repo"
run_subject
unset EXTRA_ENV
if [ "$RUN_RC" -ne 0 ] \
   || ! printf '%s' "$RUN_ERR" | grep -qF "leftover snapshot directory" \
   || ! printf '%s' "$RUN_ERR" | grep -qF "$(basename "$real_leftover")"; then
  tc50_ok=0
  tc50_detail="$tc50_detail 50c(rc=$RUN_RC err='$RUN_ERR')"
fi

if [ "$tc50_ok" -eq 1 ]; then
  pass "TC-50: leftover snapshots warned about (not deleted) via the actual post-boundary SAFE_TMPDIR; silent when there are none"
else
  fail "TC-50: leftover snapshots warned about (not deleted) via the actual post-boundary SAFE_TMPDIR; silent when there are none -$tc50_detail"
fi

# ===========================================================================
# REVIEW mini-iteration (docs/cycles/20260916_1634) -- A1/A2 safety-valve TCs
# ===========================================================================

# TC-51
# Given/When/Then (three sub-scenarios against ONE pass/fail, matching the
# TC-42/44/50 *_ok/*_detail pattern): eval_pgrep()'s three DISTINCT fail-open
# ("skip") code paths, none of which any TC previously exercised --
# `set_pgrep_absent()` (defined since this cycle's RED) had zero call sites
# before this TC (Codex/Claude REVIEW A2):
#   51-a) probe absent (the `pgrep` binary itself resolves to nothing, rc=127
#         -- hits the same "rc>=2: probe unavailable" branch a genuine
#         non-127 execution error would)
#   51-b) probe returns rc=0 but non-numeric stdout (a corrupted/unexpected
#         pgrep implementation)
#   51-c) probe returns rc=0 with EMPTY stdout (contradicts rc=0's normal
#         meaning of "at least one match")
# When: runner invoked once per sub-case
# Then: admission_check() logs a SKIP reason to stderr for the unsatisfiable
#       condition but does NOT BLOCK (exit 2) or crash -- the run proceeds
#       past admission to build_snapshot/run_tests_in_snapshot (dummy
#       evidence shows it executed inside a dev-crew-snap.* snapshot). A
#       fail-open condition that silently blocked, or that crashed instead of
#       degrading, would be worse than the condition it was meant to guard.
echo ""
echo "TC-51: eval_pgrep's 3 fail-open paths (probe absent / non-numeric output / rc=0 empty output) skip the condition (stderr SKIP) without blocking or crashing"
tc51_ok=1
tc51_detail=""

new_fixture
set_pgrep_absent
run_subject
where="$(evidence_where)"
if [ "$RUN_RC" -ne 0 ] || ! printf '%s' "$where" | grep -q "dev-crew-snap\." \
   || ! printf '%s' "$RUN_ERR" | grep -qi 'skip'; then
  tc51_ok=0
  tc51_detail="$tc51_detail 51a-absent(rc=$RUN_RC where='$where' err='$RUN_ERR')"
fi

new_fixture
set_pgrep_fake 0 "not-a-number"
run_subject
where="$(evidence_where)"
if [ "$RUN_RC" -ne 0 ] || ! printf '%s' "$where" | grep -q "dev-crew-snap\." \
   || ! printf '%s' "$RUN_ERR" | grep -qi 'skip'; then
  tc51_ok=0
  tc51_detail="$tc51_detail 51b-non-numeric(rc=$RUN_RC where='$where' err='$RUN_ERR')"
fi

new_fixture
set_pgrep_fake 0 ""
run_subject
where="$(evidence_where)"
if [ "$RUN_RC" -ne 0 ] || ! printf '%s' "$where" | grep -q "dev-crew-snap\." \
   || ! printf '%s' "$RUN_ERR" | grep -qi 'skip'; then
  tc51_ok=0
  tc51_detail="$tc51_detail 51c-rc0-empty(rc=$RUN_RC where='$where' err='$RUN_ERR')"
fi

if [ "$tc51_ok" -eq 1 ]; then
  pass "TC-51: probe-absent / non-numeric / rc=0-empty all skip (stderr SKIP) and execution still proceeds"
else
  fail "TC-51: probe-absent / non-numeric / rc=0-empty all skip (stderr SKIP) and execution still proceeds -$tc51_detail"
fi

# TC-52
# Given: one dummy test that FAILs (exits 42, a value distinct from bash's
#        own generic 1, so a match cannot be mistaken for some other cause)
#        alongside the fixture's always-PASSing dummy
# When: runner invoked
# Then: the runner's OWN exit code is 1 (exit 1 was, until this TC, never
#       pinned by a single live case -- REVIEW mini-iteration A1: 31 deleted
#       TCs left FAIL-aggregation -> exit 1 completely unverified), and the
#       stdout summary reports the FAIL count and names the specific failed
#       test -- never conflated with exit 2 (runner start-failure, e.g.
#       TC-49's copy failure)
echo ""
echo "TC-52: a single executed test FAILing drives the runner's own exit code to 1, with the FAIL count + failed-test name in stdout (never exit 2's start-failure)"
new_fixture
cat > "$F_DEV/tests/test-zz-failing.sh" <<'DUMMY'
#!/bin/bash
exit 42
DUMMY
chmod +x "$F_DEV/tests/test-zz-failing.sh"
run_subject
if [ "$RUN_RC" -eq 1 ] \
   && printf '%s' "$RUN_OUT" | grep -Eq 'FAIL: 1( |$)' \
   && printf '%s' "$RUN_OUT" | grep -qF "test-zz-failing.sh"; then
  pass "TC-52: exit 1 + FAIL count + failed-test name (rc=$RUN_RC)"
else
  fail "TC-52: exit 1 + FAIL count + failed-test name (rc=$RUN_RC out='$RUN_OUT')"
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
