#!/bin/bash
# test-hooks-structure.sh - dev-crew hooks validation
# TC-01: check-cycle-doc.sh exists and is executable
# TC-02: test-agents-structure.sh executes successfully (TC-06~TC-46, real tree)
# TC-03: test-agents-structure.sh detects model drift via mktemp snapshot fixture
#        (hermetic, no real-tree writes; #195)
# TC-04: check-claude-md-staleness.sh exists and is executable
# TC-05a~f: check-claude-md-staleness.sh characterization on fixture dirs — git
#        repos with relative backdated commits, plus one non-git dir (TC-05d)
#        (decoupled from wall-clock; #144)
# TC-06: check-claude-md-staleness.sh warns when STALENESS_THRESHOLD_DAYS=0 (fixture repo)
# TC-07: hooks.json PostToolUse observe.sh uses ${CLAUDE_PLUGIN_ROOT} path
# TC-08: observe.sh exists and is executable
# TC-09: observe.sh handles empty stdin without error
# TC-10: hooks.json has NO PreCommit entries

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

# Single mktemp root + trap cleanup (tests/test-severity-verdict.sh FIXTURE_DIR pattern).
# All fixtures below (TC-03 snapshot, TC-05/06 fixture git repos) live under FIXTURE_DIR.
FIXTURE_DIR=$(mktemp -d)
cleanup() { rm -rf "$FIXTURE_DIR"; }
# Kept as one registration because tests/test-trap-handler.sh T-02 pins this
# exact shape (`trap ... EXIT INT TERM` on a single line). Splitting INT/TERM
# out to give them an explicit `exit` — which would stop the remaining TCs from
# running against a wiped FIXTURE_DIR after Ctrl-C — has to change that contract
# in the same edit; tracked as a follow-up rather than done here.
trap cleanup EXIT INT TERM

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

# --- TC-05/TC-06 fixture helpers (#144: decouple staleness tests from wall clock) ---

# Run git fully isolated from the invoking environment: inherited GIT_DIR /
# GIT_WORK_TREE / GIT_INDEX_FILE would retarget these commands at the real
# repository, and a global commit.gpgsign or core.hooksPath would make the
# fixture commit fail (no signing key in CI) or fire unrelated hooks.
fixture_git() {
  env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE \
    git -c user.email=test@test -c user.name=test \
        -c commit.gpgsign=false -c core.hooksPath=/dev/null "$@"
}

# git init a fixture repo at $1 (creates the directory).
fixture_git_init() {
  fixture_git init -q "$1"
}

# Stage and commit files in repo $1, backdating the committer time by $2 seconds
# from "now" (relative offset, so the fixture stays valid across execution days).
# check-claude-md-staleness.sh reads committer time (%ct), not author time.
fixture_commit_backdated() {
  local repo="$1" offset_seconds="$2"
  shift 2
  local commit_date
  commit_date="@$(( $(date +%s) - offset_seconds )) +0000"
  (
    cd "$repo" \
      && fixture_git add "$@" \
      && GIT_COMMITTER_DATE="$commit_date" fixture_git commit -q -m fixture
  )
}

# Run the staleness hook inside fixture repo $1 (remaining args are VAR=value
# overrides passed via env), publishing the result in HOOK_RC / HOOK_OUT.
# Results go through globals rather than stdout because an empty hook output is
# a meaningful expectation here, and command substitution cannot distinguish
# "" from a trailing newline. The if/else form is required: under `set -e` a
# bare `out=$(failing_cmd)` assignment aborts the script before the next line,
# so a following `rc=$?` guard would be unreachable dead code.
run_staleness_hook() {
  local repo="$1"
  shift
  if HOOK_OUT=$(cd "$repo" && env "$@" bash "$BASE_DIR/scripts/hooks/check-claude-md-staleness.sh" 2>&1); then
    HOOK_RC=0
  else
    HOOK_RC=$?
  fi
}

DAY_SECONDS=86400

# Create a fixture repo at $1 holding both CLAUDE.md and AGENTS.md, committed
# $2 seconds before now. Both files share one commit, so the hook sees the same
# committer time for each. A case needing two different ages (TC-05f) calls the
# primitives directly instead.
fixture_repo_with_docs() {
  local repo="$1" offset_seconds="$2"
  fixture_git_init "$repo"
  printf 'claude\n' > "$repo/CLAUDE.md"
  printf 'agents\n' > "$repo/AGENTS.md"
  fixture_commit_backdated "$repo" "$offset_seconds" CLAUDE.md AGENTS.md
}

echo "=== Hooks Structure Tests ==="

# TC-01: check-cycle-doc.sh exists and is executable
echo ""
echo "TC-01: check-cycle-doc.sh exists and is executable"
if [ -x "$BASE_DIR/scripts/hooks/check-cycle-doc.sh" ]; then
  pass "check-cycle-doc.sh exists and is executable"
else
  fail "check-cycle-doc.sh does not exist or is not executable"
fi

# TC-02: test-agents-structure.sh executes successfully (all TC-06~TC-46 pass, real tree)
echo ""
echo "TC-02: test-agents-structure.sh executes successfully"
if bash "$BASE_DIR/tests/test-agents-structure.sh" >/dev/null 2>&1; then
  pass "test-agents-structure.sh executed successfully (exit code 0)"
else
  fail "test-agents-structure.sh failed (exit code non-zero)"
fi

# TC-03: test-agents-structure.sh detects model drift via a mktemp snapshot fixture
# (Given) agents/ skills/ AGENTS.md CHANGELOG.md snapshot to $FIXTURE_DIR + a fixture
# steps-*.md that references an existing agent (review-briefer, frontmatter model
# 'haiku') with a mismatched model ('opus') / (When) BASE_DIR=<snapshot> bash
# tests/test-agents-structure.sh / (Then) exit 1, a model-drift-specific diagnostic
# line, Summary reached, FAIL: 1 (drift only), and zero writes to the real tree.
# Presupposes the real tree is drift-clean (what TC-02 verifies), since the
# snapshot carries the real agents/ and skills/: diagnose a TC-02 failure first
# before reading a TC-03 failure as fixture-specific.
echo ""
echo "TC-03: test-agents-structure.sh detects model drift (mktemp snapshot, hermetic; #195)"

tc03_real_fixture_path="$BASE_DIR/skills/review/steps-test-drift.md"
# The current fixture never creates an agent file; this path is kept as a
# regression guard against reintroducing the pre-#195 real-tree agent fixture.
tc03_real_agent_path="$BASE_DIR/agents/test-drift-agent.md"
tc03_ok=1
tc03_reasons=""

if [ -e "$tc03_real_fixture_path" ] || [ -e "$tc03_real_agent_path" ]; then
  tc03_ok=0
  tc03_reasons="${tc03_reasons}real tree already contains fixture leakage before TC-03; "
fi

TC03_SNAP="$FIXTURE_DIR/tc03-snap"
mkdir -p "$TC03_SNAP"
# All four are required: the subject's TC-44 reads AGENTS.md and TC-45 reads
# CHANGELOG.md, so omitting either makes those fail with "not found" — the
# subject would exit 1 for the wrong reason and TC-03 would pass falsely.
cp -R "$BASE_DIR"/agents "$BASE_DIR"/skills "$BASE_DIR"/AGENTS.md "$BASE_DIR"/CHANGELOG.md "$TC03_SNAP"/

cat > "$TC03_SNAP/skills/review/steps-test-drift.md" <<'EOF'
# Test Drift Steps (fixture, TC-03)

Task(subagent_type: "dev-crew:review-briefer", model: "opus", prompt: "Test instructions")
EOF

# Capture output+rc without tripping `set -e` on the subject's non-zero exit
# (a bare `x=$(failing_cmd)` assignment aborts under set -e; the if/else form
# is exempt since the command substitution is the condition of `if`).
if tc03_output=$(BASE_DIR="$TC03_SNAP" bash "$BASE_DIR/tests/test-agents-structure.sh" 2>&1); then
  tc03_rc=0
else
  tc03_rc=$?
fi

if [ "$tc03_rc" -ne 1 ]; then
  tc03_ok=0
  tc03_reasons="${tc03_reasons}exit=$tc03_rc (expected 1); "
fi

if ! grep -qF "Model drift in steps-test-drift.md: review-briefer has model 'haiku' in frontmatter but 'opus' in Task() call" <<< "$tc03_output"; then
  tc03_ok=0
  tc03_reasons="${tc03_reasons}missing model-drift diagnostic line; "
fi

if ! grep -qF "=== Summary ===" <<< "$tc03_output"; then
  tc03_ok=0
  tc03_reasons="${tc03_reasons}Summary not reached; "
fi

if ! grep -qE 'FAIL: 1( /|$)' <<< "$tc03_output"; then
  tc03_ok=0
  tc03_reasons="${tc03_reasons}FAIL count is not exactly 1; "
fi

if [ -e "$tc03_real_fixture_path" ] || [ -e "$tc03_real_agent_path" ]; then
  tc03_ok=0
  tc03_reasons="${tc03_reasons}real tree contains fixture leakage after TC-03; "
fi

if [ "$tc03_ok" -eq 1 ]; then
  pass "test-agents-structure.sh detected model drift via fixture snapshot (exit 1, diagnostic line, Summary, FAIL: 1, no real-tree writes)"
else
  fail "TC-03 assertion(s) failed: ${tc03_reasons}(rc=$tc03_rc, output='$tc03_output')"
fi

# TC-04: check-claude-md-staleness.sh exists and is executable
echo ""
echo "TC-04: check-claude-md-staleness.sh exists and is executable"
if [ -x "$BASE_DIR/scripts/hooks/check-claude-md-staleness.sh" ]; then
  pass "check-claude-md-staleness.sh exists and is executable"
else
  fail "check-claude-md-staleness.sh does not exist or is not executable"
fi

# TC-05a: (Given) fixture git repo, CLAUDE.md+AGENTS.md committed at current time /
# (When) hook run in fixture cwd / (Then) empty output + exit 0
echo ""
echo "TC-05a: CLAUDE.md+AGENTS.md 現在時刻 commit → 出力空 + exit 0"
FIX_05A="$FIXTURE_DIR/tc05a"
fixture_repo_with_docs "$FIX_05A" 0
run_staleness_hook "$FIX_05A"
rc="$HOOK_RC"; output="$HOOK_OUT"
if [ "$rc" -eq 0 ] && [ -z "$output" ]; then
  pass "TC-05a: recent commit -> no warning, exit 0"
else
  fail "TC-05a: Unexpected output or exit code (exit=$rc, output='$output')"
fi

# TC-05b: (Given) 40 日前 backdate commit / (When) 既定閾値 30 で実行 / (Then) [WARNING] + exit 0
echo ""
echo "TC-05b: 40 日前 backdate commit (既定閾値30) → [WARNING] + exit 0"
FIX_05B="$FIXTURE_DIR/tc05b"
fixture_repo_with_docs "$FIX_05B" $((40 * DAY_SECONDS))
run_staleness_hook "$FIX_05B"
rc="$HOOK_RC"; output="$HOOK_OUT"
# Assert both filenames separately: a bare "[WARNING]" match would still pass if
# the CLAUDE.md branch broke, since AGENTS.md alone satisfies it.
if [ "$rc" -eq 0 ] \
  && grep -qF "[WARNING] CLAUDE.md" <<< "$output" \
  && grep -qF "[WARNING] AGENTS.md" <<< "$output"; then
  pass "TC-05b: 40 日 stale -> CLAUDE.md と AGENTS.md 双方の [WARNING], exit 0"
else
  fail "TC-05b: Expected per-file [WARNING] for both docs with exit 0 (exit=$rc, output='$output')"
fi

# TC-05c: (Given) 20 日前 backdate commit / (When) 既定閾値で実行 / (Then) 出力空 + exit 0
echo ""
echo "TC-05c: 20 日前 backdate commit (既定閾値内) → 出力空 + exit 0"
FIX_05C="$FIXTURE_DIR/tc05c"
fixture_repo_with_docs "$FIX_05C" $((20 * DAY_SECONDS))
run_staleness_hook "$FIX_05C"
rc="$HOOK_RC"; output="$HOOK_OUT"
if [ "$rc" -eq 0 ] && [ -z "$output" ]; then
  pass "TC-05c: 20 日 (閾値内) -> no warning, exit 0"
else
  fail "TC-05c: Unexpected output or exit code (exit=$rc, output='$output')"
fi

# TC-05d: (Given) git repo でない dir + CLAUDE.md / (When) 実行 / (Then) 出力空 + exit 0
#         (last_modified=0 経路: git log が失敗し return 0 で即抜ける)
echo ""
echo "TC-05d: git repo でない dir + CLAUDE.md → 出力空 + exit 0 (last_modified=0 経路)"
FIX_05D="$FIXTURE_DIR/tc05d"
mkdir -p "$FIX_05D"
printf 'claude\n' > "$FIX_05D/CLAUDE.md"
run_staleness_hook "$FIX_05D"
rc="$HOOK_RC"; output="$HOOK_OUT"
if [ "$rc" -eq 0 ] && [ -z "$output" ]; then
  pass "TC-05d: non-git dir -> no warning, exit 0 (last_modified=0 path)"
else
  fail "TC-05d: Unexpected output or exit code (exit=$rc, output='$output')"
fi

# TC-05e: (Given) 40 日前 stale fixture / (When) SKIP_STALENESS_CHECK=1 で実行 / (Then) 出力空 + exit 0
echo ""
echo "TC-05e: 40 日前 stale fixture + SKIP_STALENESS_CHECK=1 → 出力空 + exit 0"
FIX_05E="$FIXTURE_DIR/tc05e"
fixture_repo_with_docs "$FIX_05E" $((40 * DAY_SECONDS))
run_staleness_hook "$FIX_05E" SKIP_STALENESS_CHECK=1
rc="$HOOK_RC"; output="$HOOK_OUT"
if [ "$rc" -eq 0 ] && [ -z "$output" ]; then
  pass "TC-05e: SKIP_STALENESS_CHECK=1 -> no warning even when stale, exit 0"
else
  fail "TC-05e: Unexpected output or exit code (exit=$rc, output='$output')"
fi

# TC-05f: (Given) CLAUDE.md fresh + AGENTS.md 40 日前 backdate (2 commits) /
# (When) 実行 / (Then) AGENTS.md の WARNING のみ (CLAUDE.md 行なし)
echo ""
echo "TC-05f: CLAUDE.md fresh + AGENTS.md 40 日前 → AGENTS.md の WARNING のみ"
FIX_05F="$FIXTURE_DIR/tc05f"
fixture_git_init "$FIX_05F"
printf 'agents\n' > "$FIX_05F/AGENTS.md"
fixture_commit_backdated "$FIX_05F" $((40 * DAY_SECONDS)) AGENTS.md
printf 'claude\n' > "$FIX_05F/CLAUDE.md"
fixture_commit_backdated "$FIX_05F" 0 CLAUDE.md
run_staleness_hook "$FIX_05F"
rc="$HOOK_RC"; output="$HOOK_OUT"
if [ "$rc" -eq 0 ] && grep -qF "[WARNING] AGENTS.md" <<< "$output" && ! grep -qF "[WARNING] CLAUDE.md" <<< "$output"; then
  pass "TC-05f: AGENTS.md 単独 stale -> AGENTS.md の WARNING のみ (CLAUDE.md 行なし)"
else
  fail "TC-05f: Expected AGENTS.md-only WARNING (rc=$rc, output='$output')"
fi

# TC-06: (Given) fixture repo, 60 秒 backdate commit / (When) STALENESS_THRESHOLD_DAYS=0
# で実行 / (Then) [WARNING] + exit 0
# 60 秒 backdate は必須: hook の条件は age -gt threshold*86400 で threshold=0 のとき
# age > 0 が必要。fresh commit と同一秒内実行では age=0 で警告が出ない。
echo ""
echo "TC-06: check-claude-md-staleness.sh warns when STALENESS_THRESHOLD_DAYS=0 (fixture repo)"
FIX_06="$FIXTURE_DIR/tc06"
fixture_repo_with_docs "$FIX_06" 60
run_staleness_hook "$FIX_06" STALENESS_THRESHOLD_DAYS=0
rc="$HOOK_RC"; output="$HOOK_OUT"
if [ "$rc" -eq 0 ] \
  && grep -qF "[WARNING] CLAUDE.md" <<< "$output" \
  && grep -qF "[WARNING] AGENTS.md" <<< "$output"; then
  pass "TC-06: 60 秒 backdate + threshold=0 (age>0 保証) -> 双方の [WARNING], exit 0"
else
  fail "TC-06: Expected per-file warnings with exit 0 (exit=$rc, output='$output')"
fi

# TC-07: hooks.json PostToolUse observe.sh uses ${CLAUDE_PLUGIN_ROOT} path
echo ""
echo "TC-07: hooks.json PostToolUse observe.sh uses \${CLAUDE_PLUGIN_ROOT} path"
if jq -e '.hooks.PostToolUse[].hooks[] | select(.command | contains("${CLAUDE_PLUGIN_ROOT}"))' "$BASE_DIR/hooks/hooks.json" >/dev/null 2>&1; then
  pass "observe.sh uses \${CLAUDE_PLUGIN_ROOT} path in PostToolUse hooks"
else
  fail "observe.sh does NOT use \${CLAUDE_PLUGIN_ROOT} path in PostToolUse hooks"
fi

# TC-08: observe.sh exists and is executable
echo ""
echo "TC-08: observe.sh exists and is executable"
if [ -x "$BASE_DIR/scripts/hooks/observe.sh" ]; then
  pass "observe.sh exists and is executable"
else
  fail "observe.sh does not exist or is not executable"
fi

# TC-09: observe.sh handles empty stdin without error (exit 0)
echo ""
echo "TC-09: observe.sh handles empty stdin without error"
if echo "" | bash "$BASE_DIR/scripts/hooks/observe.sh" 2>/dev/null; then
  pass "observe.sh exits 0 on empty stdin"
else
  fail "observe.sh exits non-zero on empty stdin"
fi

# TC-10: hooks.json has NO PreCommit entries (plugin-level hooks fire globally)
echo ""
echo "TC-10: hooks.json has NO PreCommit entries"
if jq -e '.hooks.PreCommit' "$BASE_DIR/hooks/hooks.json" >/dev/null 2>&1; then
  fail "hooks.json still contains PreCommit entries (plugin hooks fire for all projects)"
else
  pass "hooks.json has no PreCommit entries"
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
