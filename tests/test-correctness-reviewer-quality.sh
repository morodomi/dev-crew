#!/bin/bash
# test-correctness-reviewer-quality.sh - Verify correctness-reviewer test quality focus
# T-01: correctness-reviewer.md Focus line contains "Test assertion quality"

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

# Terminal output helpers
pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== Correctness Reviewer Quality Tests ==="

# T-01: correctness-reviewer.md Focus line contains "Test assertion quality"
echo ""
echo "T-01: correctness-reviewer.md Focus contains 'Test assertion quality'"
FILE="$BASE_DIR/agents/correctness-reviewer.md"
if [ ! -f "$FILE" ]; then
  fail "T-01: correctness-reviewer.md not found"
elif ! grep -q 'Test assertion quality' "$FILE"; then
  fail "T-01: correctness-reviewer.md Focus missing 'Test assertion quality'"
else
  pass "T-01: correctness-reviewer.md Focus contains 'Test assertion quality'"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
