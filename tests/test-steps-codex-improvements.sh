#!/usr/bin/env bash
# Test: steps-codex.md improvements (Issue 4 - v2.1.0)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
STEPS_CODEX="$BASE_DIR/skills/orchestrate/steps-codex.md"

PASS=0
FAIL=0

assert() {
  local desc="$1"
  local result="$2"
  if [ "$result" = "0" ]; then
    echo "PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $desc"
    FAIL=$((FAIL + 1))
  fi
}

# T-01: steps-codex.md contains "CHANGED_FILES" (scoped review prompt)
grep -q "CHANGED_FILES" "$STEPS_CODEX"
assert "T-01: steps-codex.md contains CHANGED_FILES (scoped review prompt)" "$?"

# T-02: steps-codex.md contains "Why Competitive Review Works" section
grep -q "### Why Competitive Review Works" "$STEPS_CODEX"
assert "T-02: steps-codex.md contains Why Competitive Review Works section" "$?"

# T-03: steps-codex.md contains "Open Questions Response" section
grep -q "### Open Questions Response" "$STEPS_CODEX"
assert "T-03: steps-codex.md contains Open Questions Response section" "$?"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
