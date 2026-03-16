#!/bin/bash
# test-correctness-reviewer-quality.sh - Verify correctness-reviewer focus (dedup with test-reviewer)
# T-01: correctness-reviewer.md Focus does NOT contain "Test assertion quality" (moved to test-reviewer)
# T-02: correctness-reviewer.md Focus contains core responsibilities

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

# Terminal output helpers
pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== Correctness Reviewer Quality Tests ==="

FILE="$BASE_DIR/agents/correctness-reviewer.md"

# T-01: Test assertion quality moved to test-reviewer
echo ""
echo "T-01: correctness-reviewer.md Focus does NOT contain 'Test assertion quality'"
if [ ! -f "$FILE" ]; then
  fail "T-01: correctness-reviewer.md not found"
elif grep -q 'Test assertion quality' "$FILE"; then
  fail "T-01: correctness-reviewer.md still contains 'Test assertion quality' (should be in test-reviewer)"
else
  pass "T-01: correctness-reviewer.md correctly excludes 'Test assertion quality'"
fi

# T-02: Core responsibilities remain
echo ""
echo "T-02: correctness-reviewer.md Focus contains core responsibilities"
if ! grep -q 'Logic errors' "$FILE"; then
  fail "T-02: correctness-reviewer.md Focus missing 'Logic errors'"
elif ! grep -q 'Edge cases' "$FILE"; then
  fail "T-02: correctness-reviewer.md Focus missing 'Edge cases'"
elif ! grep -q 'Exception handling' "$FILE"; then
  fail "T-02: correctness-reviewer.md Focus missing 'Exception handling'"
else
  pass "T-02: correctness-reviewer.md Focus contains all core responsibilities"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
