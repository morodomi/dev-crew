#!/bin/bash
# test-architecture-dedup.sh - Test Architecture Guide deduplication regression tests
# TC-01 ~ TC-07: Ensure duplicated content is removed and references/anchors are preserved

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

REF="$BASE_DIR/skills/red/reference.md"
KEIBA="$BASE_DIR/docs/project-conventions/keiba.md"

echo "=== Test Architecture Dedup Tests ==="

# TC-01: reference.md must NOT contain the design principles table (duplicated from authority source)
echo ""
echo "TC-01: reference.md does not contain design principles table"
if grep -q "What not How" "$REF"; then
  fail "reference.md still contains 'What not How' (duplicated design principle)"
else
  pass "reference.md does not contain duplicated design principles"
fi

# TC-02: keiba.md must NOT contain the design principles table
echo ""
echo "TC-02: keiba.md does not contain design principles table"
if grep -qE "\*{0,2}What not How\*{0,2}" "$KEIBA"; then
  fail "keiba.md still contains 'What not How' (duplicated design principle)"
else
  pass "keiba.md does not contain duplicated design principles"
fi

# TC-03: reference.md must retain the 2-domain model (anti-over-deletion)
echo ""
echo "TC-03: reference.md retains 2-domain model"
if grep -q "決定論的" "$REF"; then
  pass "reference.md retains 2-domain model (決定論的)"
else
  fail "reference.md lost 2-domain model (決定論的) - over-deletion!"
fi

# TC-04: reference.md must retain language tool mapping table
echo ""
echo "TC-04: reference.md retains language tool mapping"
if grep -q "Pandera" "$REF" && grep -q "Hypothesis" "$REF" && grep -q "fast-check" "$REF"; then
  pass "reference.md retains language tool mapping"
else
  fail "reference.md lost language tool mapping - over-deletion!"
fi

# TC-05: reference.md must reference the authority source
echo ""
echo "TC-05: reference.md references authority source"
if grep -q "Keiba/docs/test_architecture.md" "$REF"; then
  pass "reference.md references authority source"
else
  fail "reference.md does not reference Keiba/docs/test_architecture.md"
fi

# TC-06: keiba.md must reference the authority source
echo ""
echo "TC-06: keiba.md references authority source"
if grep -q "Keiba/docs/test_architecture.md" "$KEIBA"; then
  pass "keiba.md references authority source"
else
  fail "keiba.md does not reference Keiba/docs/test_architecture.md"
fi

# TC-07: reference.md must retain the anchor for red-worker.md link
echo ""
echo "TC-07: reference.md retains {#test-architecture-guide} anchor"
if grep -q '{#test-architecture-guide}' "$REF"; then
  pass "reference.md retains anchor {#test-architecture-guide}"
else
  fail "reference.md lost {#test-architecture-guide} anchor - breaks red-worker.md link!"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
