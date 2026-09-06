#!/bin/bash
# test-hooks-structure.sh - dev-crew hooks validation
# TC-01: check-cycle-doc.sh exists and is executable
# TC-02: test-agents-structure.sh executes successfully (TC-06~TC-46, real tree)
# TC-03: test-agents-structure.sh detects model drift via mktemp snapshot fixture
#        (hermetic, no real-tree writes; #195)
# TC-07: hooks.json PostToolUse observe.sh uses ${CLAUDE_PLUGIN_ROOT} path
# TC-08: observe.sh exists and is executable
# TC-09: observe.sh handles empty stdin without error
# TC-10: hooks.json has NO PreCommit entries

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

# Single mktemp root + trap cleanup (tests/test-severity-verdict.sh FIXTURE_DIR pattern).
# The TC-03 snapshot fixture lives under FIXTURE_DIR.
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
