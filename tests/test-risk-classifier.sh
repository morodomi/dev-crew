#!/bin/bash
# test-risk-classifier.sh - risk-classifier.sh fallback behavior tests
# T-01: No-args invocation outputs risk level (not usage error)
# T-02: Args invocation still works (backward compat)
# T-03: Trap cleanup registered for auto-generated temp files
# T-04: steps-subagent.md uses single command invocation

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$BASE_DIR/skills/review/risk-classifier.sh"
STEPS="$BASE_DIR/skills/review/steps-subagent.md"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== Risk Classifier Tests ==="

# T-01: No-args invocation outputs risk level (not usage error)
echo ""
echo "T-01: No-args invocation outputs risk level"

output=$(bash "$SCRIPT" 2>&1) || true
if echo "$output" | grep -qE '^(LOW|MEDIUM|HIGH) score:[0-9]+$'; then
  pass "No-args outputs risk level"
else
  fail "No-args did not output risk level, got: $output"
fi

# T-02: Args invocation still works (backward compat)
echo ""
echo "T-02: Args invocation with files works"

TMPFILES=$(mktemp)
TMPDIFF=$(mktemp)
trap 'rm -f "$TMPFILES" "$TMPDIFF"' EXIT

echo "src/auth/login.php" > "$TMPFILES"
echo "+password = hash(input)" > "$TMPDIFF"

output=$(bash "$SCRIPT" "$TMPFILES" "$TMPDIFF" 2>&1)
if echo "$output" | grep -qE '^(LOW|MEDIUM|HIGH) score:[0-9]+$'; then
  pass "Args invocation outputs risk level"
else
  fail "Args invocation failed, got: $output"
fi

# T-03: Script has trap EXIT for cleanup
echo ""
echo "T-03: Trap cleanup registered for auto-generated temp files"

if grep -q "trap.*EXIT" "$SCRIPT"; then
  pass "trap EXIT found in risk-classifier.sh"
else
  fail "trap EXIT NOT found in risk-classifier.sh"
fi

# T-04: steps-subagent.md uses single command invocation
echo ""
echo "T-04: steps-subagent.md uses single command (no /tmp/review-files.txt)"

if grep -q '/tmp/review-files.txt' "$STEPS"; then
  fail "steps-subagent.md still references /tmp/review-files.txt"
else
  pass "steps-subagent.md does not reference /tmp/review-files.txt"
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
