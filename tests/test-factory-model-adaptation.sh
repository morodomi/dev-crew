#!/bin/bash
# test-factory-model-adaptation.sh - Phase 7: Factory Model Adaptation
# 7.1 Spec Precision (TC-01~TC-07), 7.2 Test Plan Verification (TC-08~TC-13), Regression (TC-14)

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== 7.1 Spec Precision Tests ==="

INIT_SKILL="$BASE_DIR/skills/spec/SKILL.md"
INIT_REF="$BASE_DIR/skills/spec/reference.md"

# TC-01: init SKILL.md に Step 4.8 (Ambiguity Detection) が存在
echo ""
echo "TC-01: init SKILL.md contains Step 4.8 Ambiguity Detection"
if grep -q "Step 4.8.*Ambiguity Detection\|Step 4\.8:.*Ambiguity" "$INIT_SKILL"; then
  pass "TC-01: Step 4.8 Ambiguity Detection found in init SKILL.md"
else
  fail "TC-01: Step 4.8 Ambiguity Detection NOT found in init SKILL.md"
fi

# TC-02: init SKILL.md が reference.md#ambiguity-detection を参照
echo ""
echo "TC-02: init SKILL.md references reference.md#ambiguity-detection"
if grep -q "reference\.md.*#ambiguity-detection\|reference\.md#ambiguity-detection" "$INIT_SKILL"; then
  pass "TC-02: reference.md#ambiguity-detection link found"
else
  fail "TC-02: reference.md#ambiguity-detection link NOT found"
fi

# TC-03: init reference.md に Ambiguity Detection セクションが存在
echo ""
echo "TC-03: init reference.md contains Ambiguity Detection section"
if grep -q "## Ambiguity Detection" "$INIT_REF"; then
  pass "TC-03: Ambiguity Detection section found in reference.md"
else
  fail "TC-03: Ambiguity Detection section NOT found in reference.md"
fi

# TC-04: reference.md に5カテゴリ (Data/API/UI/Scope/Edge) が定義
echo ""
echo "TC-04: reference.md defines 5 ambiguity categories"
categories_found=0
for cat in "Data" "API" "UI" "Scope" "Edge"; do
  if grep -q "$cat" "$INIT_REF"; then
    categories_found=$((categories_found + 1))
  fi
done
if [ "$categories_found" -ge 5 ]; then
  pass "TC-04: All 5 categories found ($categories_found/5)"
else
  fail "TC-04: Only $categories_found/5 categories found"
fi

# TC-05: reference.md に AskUserQuestion テンプレートが存在
echo ""
echo "TC-05: reference.md contains AskUserQuestion template"
if grep -q "AskUserQuestion" "$INIT_REF"; then
  pass "TC-05: AskUserQuestion template found in reference.md"
else
  fail "TC-05: AskUserQuestion template NOT found in reference.md"
fi

# TC-06: reference.md にラウンド上限 (3ラウンド) が記載
echo ""
echo "TC-06: reference.md specifies round limit (3 rounds)"
if grep -q "3.*ラウンド\|3 round" "$INIT_REF"; then
  pass "TC-06: 3-round limit found in reference.md"
else
  fail "TC-06: 3-round limit NOT found in reference.md"
fi

# TC-07: init SKILL.md が100行以内
echo ""
echo "TC-07: init SKILL.md is within 100 lines"
init_lines=$(wc -l < "$INIT_SKILL" | tr -d ' ')
if [ "$init_lines" -le 100 ]; then
  pass "TC-07: init SKILL.md is $init_lines lines (max 100)"
else
  fail "TC-07: init SKILL.md is $init_lines lines (exceeds 100)"
fi

echo ""
echo "=== 7.2 Test Plan Verification Tests ==="

RED_SKILL="$BASE_DIR/skills/red/SKILL.md"
RED_REF="$BASE_DIR/skills/red/reference.md"

# TC-08: red SKILL.md に Stage 1 (Test Plan) が存在
echo ""
echo "TC-08: red SKILL.md contains Stage 1 (Test Plan)"
if grep -q "Stage 1.*Test Plan\|Stage 1:.*Test Plan" "$RED_SKILL"; then
  pass "TC-08: Stage 1 Test Plan found in red SKILL.md"
else
  fail "TC-08: Stage 1 Test Plan NOT found in red SKILL.md"
fi

# TC-09: red SKILL.md に Stage 2 (Test Plan Review) が存在
echo ""
echo "TC-09: red SKILL.md contains Stage 2 (Test Plan Review)"
if grep -q "Stage 2.*Test Plan Review\|Stage 2:.*Test Plan Review" "$RED_SKILL"; then
  pass "TC-09: Stage 2 Test Plan Review found in red SKILL.md"
else
  fail "TC-09: Stage 2 Test Plan Review NOT found in red SKILL.md"
fi

# TC-10: red SKILL.md に Stage 3 (Test Code) が存在
echo ""
echo "TC-10: red SKILL.md contains Stage 3 (Test Code)"
if grep -q "Stage 3.*Test Code\|Stage 3:.*Test Code" "$RED_SKILL"; then
  pass "TC-10: Stage 3 Test Code found in red SKILL.md"
else
  fail "TC-10: Stage 3 Test Code NOT found in red SKILL.md"
fi

# TC-11: red reference.md に Test Plan Stage セクションが存在
echo ""
echo "TC-11: red reference.md contains Test Plan Stage section"
if grep -q "## Test Plan Stage" "$RED_REF"; then
  pass "TC-11: Test Plan Stage section found in red reference.md"
else
  fail "TC-11: Test Plan Stage section NOT found in red reference.md"
fi

# TC-12: red reference.md に Test Plan Review チェックリストが存在
echo ""
echo "TC-12: red reference.md contains Test Plan Review checklist"
if grep -q "## Test Plan Review" "$RED_REF"; then
  pass "TC-12: Test Plan Review section found in red reference.md"
else
  fail "TC-12: Test Plan Review section NOT found in red reference.md"
fi

# TC-13: red SKILL.md が100行以内
echo ""
echo "TC-13: red SKILL.md is within 100 lines"
red_lines=$(wc -l < "$RED_SKILL" | tr -d ' ')
if [ "$red_lines" -le 100 ]; then
  pass "TC-13: red SKILL.md is $red_lines lines (max 100)"
else
  fail "TC-13: red SKILL.md is $red_lines lines (exceeds 100)"
fi

echo ""
echo "=== Regression Tests ==="

# TC-14: 既存テスト全PASSの確認
echo ""
echo "TC-14: All existing tests pass"
regression_fail=0
for test_file in "$BASE_DIR"/tests/test-*.sh; do
  [ -f "$test_file" ] || continue
  test_name=$(basename "$test_file")
  # Skip self and known recursive / slow tests (cascade timeout 対応、cycle 20260427_0930)
  [ "$test_name" = "test-factory-model-adaptation.sh" ] && continue
  [ "$test_name" = "test-doc-consistency.sh" ] && continue
  [ "$test_name" = "test-meta-doc-consistency.sh" ] && continue
  [ "$test_name" = "test-review-integration-v24.sh" ] && continue
  [ "$test_name" = "test-phase-compact.sh" ] && continue
  if timeout 90 bash "$test_file" > /dev/null 2>&1; then
    : # pass silently
  else
    fail "TC-14: $test_name failed"
    regression_fail=$((regression_fail + 1))
  fi
done
if [ "$regression_fail" -eq 0 ]; then
  pass "TC-14: All existing tests pass"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
