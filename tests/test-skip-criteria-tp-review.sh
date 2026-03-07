#!/bin/bash
# test-skip-criteria-tp-review.sh - Skip criteria + Test Plan Review paradigm alignment
# TC-01 ~ TC-05

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

REF="$BASE_DIR/skills/red/reference.md"

echo "=== Skip Criteria + TP Review Tests ==="

# TC-01: reference.md Paradigm Selection guide has skip criteria
echo ""
echo "TC-01: Paradigm Selection guide has skip criteria"
if grep -q 'Skip' "$REF" && grep -q 'プリミティブ' "$REF"; then
  pass "Skip criteria exists in Paradigm Selection guide"
else
  fail "Skip criteria missing in Paradigm Selection guide"
fi

# TC-02: reference.md Test Plan Review checklist has paradigm alignment
echo ""
echo "TC-02: Test Plan Review checklist has paradigm alignment"
if grep -q 'Paradigm' "$REF" | grep -q 'チェック項目' "$REF" 2>/dev/null; then
  # More precise: check that Paradigm appears in the review checklist table
  if awk '/レビューチェックリスト/,/Gap分析/' "$REF" | grep -q 'Paradigm'; then
    pass "Test Plan Review has paradigm alignment check"
  else
    fail "Test Plan Review missing paradigm alignment check"
  fi
else
  # Fallback: just check if paradigm alignment is in the review section
  if awk '/レビューチェックリスト/,/Gap分析/' "$REF" | grep -q 'Paradigm'; then
    pass "Test Plan Review has paradigm alignment check"
  else
    fail "Test Plan Review missing paradigm alignment check"
  fi
fi

# TC-03: reference.md retains 2-domain model (regression)
echo ""
echo "TC-03: reference.md retains 2-domain model (regression)"
if grep -q '決定論的' "$REF" && grep -q '確率的' "$REF"; then
  pass "reference.md retains 2-domain model"
else
  fail "reference.md lost 2-domain model"
fi

# TC-04: reference.md retains language tool mapping (regression)
echo ""
echo "TC-04: reference.md retains language tool mapping (regression)"
if grep -q 'Pandera' "$REF" && grep -q 'Hypothesis' "$REF" && grep -q 'fast-check' "$REF"; then
  pass "reference.md retains language tool mapping"
else
  fail "reference.md lost language tool mapping"
fi

# TC-05: Previous cycle tests still pass (regression)
echo ""
echo "TC-05: Previous cycle tests (test-paradigm-selection.sh) pass"
if bash "$BASE_DIR/tests/test-paradigm-selection.sh" > /dev/null 2>&1; then
  pass "Previous cycle tests all pass"
else
  fail "Previous cycle tests have regressions"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
