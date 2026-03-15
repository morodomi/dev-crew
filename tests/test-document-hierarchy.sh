#!/bin/bash
# test-document-hierarchy.sh - ドキュメント権威階層テスト (ROADMAP 11.9)
# T-01 ~ T-12

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

HIERARCHY_FILE="$BASE_DIR/docs/document-hierarchy.md"
DOCS_README="$BASE_DIR/docs/README.md"
ONBOARD_SKILL="$BASE_DIR/skills/onboard/SKILL.md"
ONBOARD_REF="$BASE_DIR/skills/onboard/reference.md"
SKILLMAKER_REF="$BASE_DIR/skills/skill-maker/reference.md"
ROADMAP_FILE="$BASE_DIR/docs/ROADMAP.md"

echo "=== Document Hierarchy Tests ==="
echo ""

# T-01: Given docs/, Then document-hierarchy.md が存在する
echo "T-01: docs/document-hierarchy.md exists"
if [ -f "$HIERARCHY_FILE" ]; then
  pass "T-01: document-hierarchy.md exists"
else
  fail "T-01: document-hierarchy.md not found"
fi

# T-02: Given document-hierarchy.md, Then PHILOSOPHY.md への参照がある
echo ""
echo "T-02: document-hierarchy.md references PHILOSOPHY.md"
if [ -f "$HIERARCHY_FILE" ] && grep -q 'PHILOSOPHY\.md' "$HIERARCHY_FILE"; then
  pass "T-02: PHILOSOPHY.md reference found"
else
  fail "T-02: PHILOSOPHY.md reference missing"
fi

# T-03: Given document-hierarchy.md, Then 4層(PURPOSE/PLANNING/DESIGN/PROCEDURE)が定義されている
echo ""
echo "T-03: document-hierarchy.md defines 4 layers"
if [ -f "$HIERARCHY_FILE" ]; then
  LAYERS=0
  grep -q 'PURPOSE' "$HIERARCHY_FILE" && LAYERS=$((LAYERS + 1))
  grep -q 'PLANNING' "$HIERARCHY_FILE" && LAYERS=$((LAYERS + 1))
  grep -q 'DESIGN' "$HIERARCHY_FILE" && LAYERS=$((LAYERS + 1))
  grep -q 'PROCEDURE' "$HIERARCHY_FILE" && LAYERS=$((LAYERS + 1))
  if [ "$LAYERS" -eq 4 ]; then
    pass "T-03: All 4 layers defined"
  else
    fail "T-03: Only $LAYERS/4 layers found"
  fi
else
  fail "T-03: document-hierarchy.md not found"
fi

# T-04: Given document-hierarchy.md, Then 矛盾解決ルールがある
echo ""
echo "T-04: document-hierarchy.md has conflict resolution rule"
if [ -f "$HIERARCHY_FILE" ] && grep -q '矛盾\|conflict\|上位.*勝つ\|upper.*wins' "$HIERARCHY_FILE"; then
  pass "T-04: Conflict resolution rule found"
else
  fail "T-04: Conflict resolution rule missing"
fi

# T-05: Given document-hierarchy.md, Then ファイル配置マップ（onboard, spec, skill-maker）がある
echo ""
echo "T-05: document-hierarchy.md has file placement map"
if [ -f "$HIERARCHY_FILE" ]; then
  SKILLS=0
  grep -q 'onboard' "$HIERARCHY_FILE" && SKILLS=$((SKILLS + 1))
  grep -q 'spec' "$HIERARCHY_FILE" && SKILLS=$((SKILLS + 1))
  grep -q 'skill-maker' "$HIERARCHY_FILE" && SKILLS=$((SKILLS + 1))
  if [ "$SKILLS" -eq 3 ]; then
    pass "T-05: File placement map includes onboard, spec, skill-maker"
  else
    fail "T-05: Only $SKILLS/3 skills in file placement map"
  fi
else
  fail "T-05: document-hierarchy.md not found"
fi

# T-06: Given docs/README.md, Then document-hierarchy.md が掲載されている
echo ""
echo "T-06: docs/README.md lists document-hierarchy.md"
if grep -q 'document-hierarchy' "$DOCS_README"; then
  pass "T-06: document-hierarchy.md listed in README"
else
  fail "T-06: document-hierarchy.md not listed in README"
fi

# T-07: Given onboard reference.md, Then プロジェクト目的質問（PROJECT_PURPOSE）がある
echo ""
echo "T-07: onboard reference.md has PROJECT_PURPOSE"
if grep -q 'PROJECT_PURPOSE' "$ONBOARD_REF"; then
  pass "T-07: PROJECT_PURPOSE found in onboard reference"
else
  fail "T-07: PROJECT_PURPOSE missing from onboard reference"
fi

# T-08: Given onboard reference.md, Then AGENTS.md OverviewテンプレートにPURPOSEがある
echo ""
echo "T-08: onboard reference.md AGENTS.md Overview template has PURPOSE"
if grep -q 'PROJECT_PURPOSE' "$ONBOARD_REF"; then
  pass "T-08: PURPOSE in AGENTS.md Overview template"
else
  fail "T-08: PURPOSE missing from AGENTS.md Overview template"
fi

# T-09: Given onboard SKILL.md Step 2, Then 「目的」への言及がある
echo ""
echo "T-09: onboard SKILL.md Step 2 mentions project purpose"
if grep -q '目的\|purpose\|PURPOSE' "$ONBOARD_SKILL"; then
  pass "T-09: Project purpose mentioned in SKILL.md Step 2"
else
  fail "T-09: Project purpose not mentioned in SKILL.md Step 2"
fi

# T-10: Given onboard SKILL.md, Then 100行以内
echo ""
echo "T-10: onboard SKILL.md is within 100 lines"
LINE_COUNT=$(wc -l < "$ONBOARD_SKILL" | tr -d ' ')
if [ "$LINE_COUNT" -le 100 ]; then
  pass "T-10: SKILL.md is $LINE_COUNT lines (<= 100)"
else
  fail "T-10: SKILL.md is $LINE_COUNT lines (> 100)"
fi

# T-11: Given skill-maker reference.md, Then document-hierarchy 参照がある
echo ""
echo "T-11: skill-maker reference.md references document-hierarchy"
if grep -q 'document-hierarchy' "$SKILLMAKER_REF"; then
  pass "T-11: document-hierarchy reference found"
else
  fail "T-11: document-hierarchy reference missing"
fi

# T-12: Given ROADMAP.md, Then 11.9に完了マークがある
echo ""
echo "T-12: ROADMAP.md 11.9 has completion mark"
if grep -q '11\.9.*完了\|11\.9.*\(完了\)' "$ROADMAP_FILE"; then
  pass "T-12: ROADMAP.md 11.9 has completion mark"
else
  fail "T-12: ROADMAP.md 11.9 missing completion mark"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
