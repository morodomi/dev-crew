#!/bin/bash
# test-hooks-structure.sh - dev-crew hooks.json validation
# TC-01: hooks.json contains test-agents-structure.sh entry
# TC-02: test-agents-structure.sh executes successfully (TC-21~TC-34)
# TC-03: test-agents-structure.sh detects model drift and exits with code 1

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== Hooks Structure Tests ==="

# TC-01: hooks.json contains test-agents-structure.sh entry in PreCommit hooks
echo ""
echo "TC-01: hooks.json contains test-agents-structure.sh entry"
if jq -e '.hooks.PreCommit[].hooks[] | select(.command | contains("test-agents-structure.sh"))' "$BASE_DIR/hooks/hooks.json" >/dev/null 2>&1; then
  pass "test-agents-structure.sh entry found in PreCommit hooks"
else
  fail "test-agents-structure.sh entry NOT found in PreCommit hooks"
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
TEMP_AGENT="$BASE_DIR/agents/test-drift-agent.md"
cat > "$TEMP_AGENT" <<'EOF'
---
name: test-drift-agent
description: Temporary agent for testing model drift detection
model: claude-sonnet-4-5-20250929
---

# Test Drift Agent

This is a temporary agent for testing TC-03.
EOF

# Create temporary skill directory with drifted steps file
TEMP_SKILL_DIR="$BASE_DIR/skills/test-drift-skill"
mkdir -p "$TEMP_SKILL_DIR"
TEMP_STEPS="$TEMP_SKILL_DIR/steps-test-drift.md"
cat > "$TEMP_STEPS" <<'EOF'
# Test Drift Steps

Task() call with drifted model:

```
Task(
  name="test-drift-agent",
  model="claude-opus-3-7-20250219",  # This drifts from frontmatter
  instructions="Test instructions"
)
```
EOF

# Run test-agents-structure.sh and expect failure
if bash "$BASE_DIR/tests/test-agents-structure.sh" >/dev/null 2>&1; then
  fail "test-agents-structure.sh did NOT detect model drift (exit code 0)"
else
  pass "test-agents-structure.sh detected model drift (exit code 1)"
fi

# Cleanup temporary files
rm -f "$TEMP_AGENT"
rm -rf "$TEMP_SKILL_DIR"

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS"
echo "FAIL: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi

exit 0
