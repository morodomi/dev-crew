#!/bin/bash
# test-hooks-structure.sh - dev-crew hooks validation
# TC-01: check-cycle-doc.sh exists and is executable
# TC-02: test-agents-structure.sh executes successfully (TC-21~TC-34)
# TC-03: test-agents-structure.sh detects model drift and exits with code 1

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0
TEMP_AGENT="$BASE_DIR/agents/test-drift-agent.md"
TEMP_SKILL_DIR="$BASE_DIR/skills/test-drift-skill"

cleanup() {
  rm -f "$TEMP_AGENT"
  rm -rf "$TEMP_SKILL_DIR"
}

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

# TC-02: test-agents-structure.sh executes successfully (all TC-21~TC-34 pass)
echo ""
echo "TC-02: test-agents-structure.sh executes successfully"
if bash "$BASE_DIR/tests/test-agents-structure.sh" >/dev/null 2>&1; then
  pass "test-agents-structure.sh executed successfully (exit code 0)"
else
  fail "test-agents-structure.sh failed (exit code non-zero)"
fi

# TC-03: test-agents-structure.sh detects model drift and blocks commit
echo ""
echo "TC-03: test-agents-structure.sh detects model drift (exit code 1)"

# Create temporary agent file with drift
cat > "$TEMP_AGENT" <<'EOF'
---
name: test-drift-agent
description: Temporary agent for testing model drift detection
model: sonnet
---

# Test Drift Agent

This is a temporary agent for testing TC-03.
EOF

# Create temporary skill directory with drifted steps file
mkdir -p "$TEMP_SKILL_DIR"
TEMP_STEPS="$TEMP_SKILL_DIR/steps-test-drift.md"
cat > "$TEMP_STEPS" <<'EOF'
# Test Drift Steps

Task(subagent_type: "dev-crew:test-drift-agent", model: "opus", prompt: "Test instructions")
EOF

# Run test-agents-structure.sh and expect failure
if bash "$BASE_DIR/tests/test-agents-structure.sh" >/dev/null 2>&1; then
  fail "test-agents-structure.sh did NOT detect model drift (exit code 0)"
else
  pass "test-agents-structure.sh detected model drift (exit code 1)"
fi

# TC-04: check-claude-md-staleness.sh exists and is executable
echo ""
echo "TC-04: check-claude-md-staleness.sh exists and is executable"
if [ -x "$BASE_DIR/scripts/hooks/check-claude-md-staleness.sh" ]; then
  pass "check-claude-md-staleness.sh exists and is executable"
else
  fail "check-claude-md-staleness.sh does not exist or is not executable"
fi

# TC-05: check-claude-md-staleness.sh exits 0 with no warning when CLAUDE.md is recent
echo ""
echo "TC-05: check-claude-md-staleness.sh exits 0 with no warning when CLAUDE.md is recent"
output=$(cd "$BASE_DIR" && bash scripts/hooks/check-claude-md-staleness.sh 2>&1)
exit_code=$?
if [ "$exit_code" -eq 0 ] && [ -z "$output" ]; then
  pass "No warning and exit 0 for recently updated CLAUDE.md"
else
  fail "Unexpected output or exit code (exit=$exit_code, output='$output')"
fi

# TC-06: check-claude-md-staleness.sh warns when STALENESS_THRESHOLD_DAYS=0
echo ""
echo "TC-06: check-claude-md-staleness.sh warns when STALENESS_THRESHOLD_DAYS=0"
output=$(cd "$BASE_DIR" && STALENESS_THRESHOLD_DAYS=0 bash scripts/hooks/check-claude-md-staleness.sh 2>&1)
exit_code=$?
if [ "$exit_code" -eq 0 ] && echo "$output" | grep -q "\[WARNING\]"; then
  pass "Warning displayed and exit 0 with STALENESS_THRESHOLD_DAYS=0"
else
  fail "Expected warning with exit 0 (exit=$exit_code, output='$output')"
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
