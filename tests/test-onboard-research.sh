#!/bin/bash
# test-onboard-research.sh - onboard skill research validation (#26)
# TC-01 ~ TC-08: Structural tests for onboard SKILL.md and reference.md

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

SKILL_FILE="$BASE_DIR/skills/onboard/SKILL.md"
REFERENCE_FILE="$BASE_DIR/skills/onboard/reference.md"

# Section extraction constants
LINES_AFTER_STEP=30

echo "=== Onboard Research Tests (#26) ==="
echo ""

# Verify files exist
[ -f "$SKILL_FILE" ] || { echo "ERROR: $SKILL_FILE not found"; exit 1; }
[ -f "$REFERENCE_FILE" ] || { echo "ERROR: $REFERENCE_FILE not found"; exit 1; }

# Read files once and reuse
SKILL_CONTENT=$(cat "$SKILL_FILE")
REF_CONTENT=$(cat "$REFERENCE_FILE")

# TC-01: SKILL.md が 100行以下であること
echo "TC-01: SKILL.md <= 100 lines"
LINE_COUNT=$(echo "$SKILL_CONTENT" | wc -l | tr -d ' ')
if [ "$LINE_COUNT" -le 100 ]; then
  pass "TC-01: SKILL.md is $LINE_COUNT lines (<= 100)"
else
  fail "TC-01: SKILL.md is $LINE_COUNT lines (> 100)"
fi

# TC-02: reference.md に「コンテンツ判定基準」セクションが存在すること
echo ""
echo "TC-02: reference.md has content criteria section"
if echo "$REF_CONTENT" | grep -q "コンテンツ判定基準"; then
  pass "TC-02: content criteria section found"
else
  fail "TC-02: content criteria section not found"
fi

# TC-03: reference.md に「書くべきもの」「書くべきでないもの」の両方が記載されていること
echo ""
echo "TC-03: reference.md has both inclusion and exclusion criteria"
if echo "$REF_CONTENT" | grep -q "書くべきもの" && \
   echo "$REF_CONTENT" | grep -q "書くべきでないもの"; then
  pass "TC-03: both inclusion and exclusion criteria found"
else
  fail "TC-03: missing inclusion and/or exclusion criteria"
fi

# TC-04: reference.md Step 5 に @ import の説明が含まれること
echo ""
echo "TC-04: reference.md Step 5 has @ import explanation"
if echo "$REF_CONTENT" | grep -A "$LINES_AFTER_STEP" "^## Step 5" | grep -q "@.*import\|@docs/\|@ import"; then
  pass "TC-04: @ import explanation found in Step 5"
else
  fail "TC-04: @ import explanation not found in Step 5"
fi

# TC-05: reference.md Step 6 に path targeting (paths フロントマター) の例示が含まれること
echo ""
echo "TC-05: reference.md Step 6 has path targeting example"
if echo "$REF_CONTENT" | grep -A "$LINES_AFTER_STEP" "^## Step 6" | grep -q "paths:"; then
  pass "TC-05: path targeting (paths frontmatter) example found in Step 6"
else
  fail "TC-05: path targeting (paths frontmatter) example not found in Step 6"
fi

# TC-06: reference.md に「メンテナンス」セクションが存在すること
echo ""
echo "TC-06: reference.md has maintenance section"
if echo "$REF_CONTENT" | grep -q "メンテナンス"; then
  pass "TC-06: maintenance section found"
else
  fail "TC-06: maintenance section not found"
fi

# TC-07: SKILL.md Step 4 に Deletion Test の言及があること
echo ""
echo "TC-07: SKILL.md Step 4 mentions Deletion Test"
if echo "$SKILL_CONTENT" | grep -A "$LINES_AFTER_STEP" "^### Step 4" | grep -qi "deletion test"; then
  pass "TC-07: Deletion Test mentioned in Step 4"
else
  fail "TC-07: Deletion Test not mentioned in Step 4"
fi

# TC-08: SKILL.md Step 9 にメンテナンス案内が含まれること
echo ""
echo "TC-08: SKILL.md Step 9 has maintenance guidance"
if echo "$SKILL_CONTENT" | grep -A "$LINES_AFTER_STEP" "^### Step 9" | grep -q "メンテナンス\|定期レビュー\|Feedback Loop"; then
  pass "TC-08: maintenance guidance found in Step 9"
else
  fail "TC-08: maintenance guidance not found in Step 9"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
