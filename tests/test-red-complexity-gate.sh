#!/bin/bash
# test-red-complexity-gate.sh - RED skill complexity gate validation
# TC-R1, TC-R2, TC-R3, TC-R4, TC-R5, TC-R6

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

SKILL_MD="$BASE_DIR/skills/red/SKILL.md"
REFERENCE_MD="$BASE_DIR/skills/red/reference.md"

echo "=== RED Skill Complexity Gate Tests ==="

# TC-R1: SKILL.md contains complexity gate specifying trivial class skips Stage 2
echo ""
echo "TC-R1: SKILL.md - trivial complexity skips Stage 2"
if grep -qiE 'trivial.*(skip|stage.?2)|stage.?2.*(skip|trivial)' "$SKILL_MD"; then
  pass "TC-R1: SKILL.md indicates trivial complexity skips Stage 2"
else
  fail "TC-R1: SKILL.md does not indicate trivial complexity skips Stage 2"
fi

# TC-R2: SKILL.md contains complexity gate specifying standard class skips Stage 2 Review
echo ""
echo "TC-R2: SKILL.md - standard complexity skips Stage 2 Review"
if grep -qiE 'standard.*(skip|review)|review.*(skip|standard)' "$SKILL_MD"; then
  pass "TC-R2: SKILL.md indicates standard complexity skips Stage 2 Review"
else
  fail "TC-R2: SKILL.md does not indicate standard complexity skips Stage 2 Review"
fi

# TC-R3: SKILL.md contains complexity gate referencing full 3-stage for complex class
echo ""
echo "TC-R3: SKILL.md - complex class uses full 3-stage"
if grep -qiE 'complex.*(full|3.stage|all.stage)|full.*(3.stage|complex)' "$SKILL_MD"; then
  pass "TC-R3: SKILL.md indicates complex class uses full 3-stage"
else
  fail "TC-R3: SKILL.md does not indicate complex class uses full 3-stage"
fi

# TC-R4: reference.md specifies Property/Metamorphic paradigm escalates to complex
echo ""
echo "TC-R4: reference.md - Property/Metamorphic paradigm escalates to complex"
if grep -qiE '(property|metamorphic).*(complex|escalat)|(complex|escalat).*(property|metamorphic)' "$REFERENCE_MD"; then
  pass "TC-R4: reference.md specifies Property/Metamorphic escalates to complex"
else
  fail "TC-R4: reference.md does not specify Property/Metamorphic escalates to complex"
fi

# TC-R5: reference.md specifies external I/O escalates to standard or above
echo ""
echo "TC-R5: reference.md - external I/O escalates to standard or above"
if grep -qiE '(i/o|external|io).*(standard|escalat)|(standard|escalat).*(i/o|external|io)' "$REFERENCE_MD"; then
  pass "TC-R5: reference.md specifies external I/O escalates to standard or above"
else
  fail "TC-R5: reference.md does not specify external I/O escalates to standard or above"
fi

# TC-R6: SKILL.md must remain <= 100 lines
echo ""
echo "TC-R6: SKILL.md line count <= 100"
line_count=$(wc -l < "$SKILL_MD" | tr -d ' ')
if [ "$line_count" -le 100 ]; then
  pass "TC-R6: SKILL.md has $line_count lines (<= 100)"
else
  fail "TC-R6: SKILL.md has $line_count lines (exceeds 100)"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
