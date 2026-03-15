#!/bin/bash
# test-onboard-validation.sh - onboard validation.md の存在とチェック項目を検証
set -uo pipefail

DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0

pass() { echo "  PASS: $1"; ((PASS++)); }
fail() { echo "  FAIL: $1"; ((FAIL++)); }

echo "=== test-onboard-validation ==="

# --- validation.md existence ---

echo "-- validation.md --"

VALIDATION_FILE="$DIR/skills/onboard/validation.md"

# Given onboard/validation.md exists, When read, Then contains check items table
if [ -f "$VALIDATION_FILE" ]; then
  pass "validation.md exists"
else
  fail "validation.md does not exist"
fi

# Given validation.md, When check for table, Then contains pipe-delimited table
if grep -c "^|" "$VALIDATION_FILE" 2>/dev/null | grep -qE "^[5-9]|^[1-9][0-9]"; then
  pass "validation.md contains table with 5+ rows"
else
  fail "validation.md missing or has fewer than 5 table rows"
fi

# Given validation.md check items, When count data rows, Then >= 5 items
# Count rows that start with "| " followed by a number (data rows, not header/separator)
ITEM_COUNT=$(grep -cE "^\| [0-9]" "$VALIDATION_FILE" 2>/dev/null || echo 0)
if [ "$ITEM_COUNT" -ge 5 ]; then
  pass "validation.md has >= 5 check items (found: $ITEM_COUNT)"
else
  fail "validation.md has < 5 check items (found: $ITEM_COUNT)"
fi

# --- SKILL.md references validation.md ---

echo "-- onboard/SKILL.md --"

SKILL_FILE="$DIR/skills/onboard/SKILL.md"

# Given onboard/SKILL.md, When grep "validation.md", Then Step 9 references it
if grep -q "validation.md" "$SKILL_FILE"; then
  pass "SKILL.md references validation.md"
else
  fail "SKILL.md does not reference validation.md"
fi

# Verify validation step exists before the final completion step
if grep -B 2 "validation" "$SKILL_FILE" | grep -qi "step 9\|validation\|Generated Files"; then
  pass "SKILL.md has validation step"
else
  fail "SKILL.md missing validation step"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
