#!/bin/bash
# test-paradigm-selection.sh - Paradigm Selection in TC template regression tests
# TC-01 ~ TC-07: Ensure TC template has Paradigm/Invariant fields and red-worker connects Step 0

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

REF="$BASE_DIR/skills/red/reference.md"
RED_WORKER="$BASE_DIR/agents/red-worker.md"
HOLDINGS_DOC="$(cd "$BASE_DIR/../.." && pwd)/docs/test_architecture.md"

echo "=== Paradigm Selection TC Template Tests ==="

# TC-01: reference.md TC template contains Paradigm field
echo ""
echo "TC-01: reference.md TC template contains Paradigm field"
if grep -q '^\- \*\*Paradigm\*\*' "$REF"; then
  pass "TC template has Paradigm field"
else
  fail "TC template missing Paradigm field"
fi

# TC-02: reference.md TC template contains Invariant field
echo ""
echo "TC-02: reference.md TC template contains Invariant field"
if grep -q '^\- \*\*Invariant\*\*' "$REF"; then
  pass "TC template has Invariant field"
else
  fail "TC template missing Invariant field"
fi

# TC-03: red-worker.md connects Step 0 classification to TC template Paradigm
echo ""
echo "TC-03: red-worker.md connects Step 0 to Paradigm selection"
if grep -q 'Paradigm欄に反映' "$RED_WORKER"; then
  pass "red-worker connects Step 0 classification to Paradigm"
else
  fail "red-worker does not connect Step 0 to Paradigm"
fi

# TC-04: MorodomiHoldings/docs/test_architecture.md exists (SSOT)
echo ""
echo "TC-04: test_architecture.md exists at Holdings docs (SSOT)"
if [ -f "$HOLDINGS_DOC" ]; then
  pass "test_architecture.md exists at Holdings docs"
else
  fail "test_architecture.md not found at Holdings docs"
fi

# TC-05: reference.md references authority source (regression)
echo ""
echo "TC-05: reference.md references authority source"
if grep -q 'test_architecture.md' "$REF"; then
  pass "reference.md references authority source"
else
  fail "reference.md does not reference test_architecture.md"
fi

# TC-06: reference.md retains 2-domain model (regression)
echo ""
echo "TC-06: reference.md retains 2-domain model"
if grep -q '決定論的' "$REF" && grep -q '確率的' "$REF"; then
  pass "reference.md retains 2-domain model"
else
  fail "reference.md lost 2-domain model"
fi

# TC-07: reference.md retains language tool mapping (regression)
echo ""
echo "TC-07: reference.md retains language tool mapping"
if grep -q 'Pandera' "$REF" && grep -q 'Hypothesis' "$REF" && grep -q 'fast-check' "$REF"; then
  pass "reference.md retains language tool mapping"
else
  fail "reference.md lost language tool mapping"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
