#!/bin/bash
# test-onboard-agents-md.sh - AGENTS.md skill propagation tests for onboard
# TC-01 ~ TC-07, TC-12 ~ TC-13

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

SKILL_FILE="$BASE_DIR/skills/onboard/SKILL.md"
REFERENCE_FILE="$BASE_DIR/skills/onboard/reference.md"

[ -f "$SKILL_FILE" ] || { echo "ERROR: $SKILL_FILE not found"; exit 1; }
[ -f "$REFERENCE_FILE" ] || { echo "ERROR: $REFERENCE_FILE not found"; exit 1; }

SKILL_CONTENT=$(cat "$SKILL_FILE")
REF_CONTENT=$(cat "$REFERENCE_FILE")

LINES_AFTER_STEP=30

echo "=== Onboard AGENTS.md Tests ==="
echo ""

# TC-01: Given SKILL.md, When reading description, Then AGENTS.md is mentioned
echo "TC-01: SKILL.md description mentions AGENTS.md"
if echo "$SKILL_CONTENT" | grep -q "AGENTS.md"; then
  pass "TC-01: AGENTS.md mentioned in SKILL.md"
else
  fail "TC-01: AGENTS.md not mentioned in SKILL.md"
fi

# TC-02: Given reference.md Step 4, When reading, Then AGENTS.md generation section exists
echo ""
echo "TC-02: reference.md Step 4 has AGENTS.md generation section"
STEP4_CONTENT=$(echo "$REF_CONTENT" | grep -A "$LINES_AFTER_STEP" "^## Step 4")
if echo "$STEP4_CONTENT" | grep -q "AGENTS.md"; then
  pass "TC-02: AGENTS.md generation section found in Step 4"
else
  fail "TC-02: AGENTS.md generation section not found in Step 4"
fi

# TC-03: Given reference.md Step 4, When reading, Then CLAUDE.md contains @AGENTS.md template
echo ""
echo "TC-03: reference.md has @AGENTS.md template for CLAUDE.md"
if echo "$REF_CONTENT" | grep -q "@AGENTS.md"; then
  pass "TC-03: @AGENTS.md template found"
else
  fail "TC-03: @AGENTS.md template not found"
fi

# TC-04: Given reference.md mode detection, When reading, Then AGENTS.md is detection signal
echo ""
echo "TC-04: reference.md has AGENTS.md as detection signal"
DETECTION_SECTION=$(echo "$REF_CONTENT" | grep -A 20 "検出シグナル\|detection signal")
if echo "$DETECTION_SECTION" | grep -q "AGENTS.md"; then
  pass "TC-04: AGENTS.md listed as detection signal"
else
  fail "TC-04: AGENTS.md not listed as detection signal"
fi

# TC-05: Given reference.md backup, When reading, Then AGENTS.md.bak is mentioned
echo ""
echo "TC-05: reference.md mentions AGENTS.md.bak backup"
if echo "$REF_CONTENT" | grep -q "AGENTS.md.bak"; then
  pass "TC-05: AGENTS.md.bak backup mentioned"
else
  fail "TC-05: AGENTS.md.bak backup not mentioned"
fi

# TC-06: Given SKILL.md checklist, When reading, Then AGENTS.md step exists
echo ""
echo "TC-06: SKILL.md checklist has AGENTS.md step"
CHECKLIST=$(echo "$SKILL_CONTENT" | sed -n '/^```$/,/^```$/p')
if echo "$CHECKLIST" | grep -q "AGENTS.md"; then
  pass "TC-06: AGENTS.md step found in checklist"
else
  fail "TC-06: AGENTS.md step not found in checklist"
fi

# TC-07: Given reference.md section count, When reading, Then max 5 AGENTS.md sections stated
echo ""
echo "TC-07: reference.md states max 5 AGENTS.md sections"
if echo "$REF_CONTENT" | grep -q "5セクション\|最大5\|max 5.*AGENTS"; then
  pass "TC-07: max 5 AGENTS.md sections stated"
else
  fail "TC-07: max 5 AGENTS.md sections limit not stated"
fi

# TC-12: Given reference.md mode detection, When AGENTS.md absent, Then CLAUDE.md-based detection still works
echo ""
echo "TC-12: reference.md preserves CLAUDE.md-based mode detection (backward compat)"
# Classification logic must still reference CLAUDE.md for fresh/existing-no-tdd/dev-crew-installed
CLASSIFICATION=$(echo "$REF_CONTENT" | grep -A 15 "分類ロジック\|classification logic")
if echo "$CLASSIFICATION" | grep -q "CLAUDE.md"; then
  pass "TC-12: CLAUDE.md-based detection preserved in classification logic"
else
  fail "TC-12: CLAUDE.md-based detection missing from classification logic"
fi

# TC-13: Given test-onboard-research.sh existing TCs, When run, Then all pass
echo ""
echo "TC-13: existing test-onboard-research.sh tests still pass"
TC13_OUTPUT=$(bash "$BASE_DIR/tests/test-onboard-research.sh" 2>&1) && TC13_RC=0 || TC13_RC=$?
if [ "$TC13_RC" -eq 0 ]; then
  pass "TC-13: all existing onboard research TCs pass"
else
  fail "TC-13: existing onboard research TCs have failures:"
  echo "$TC13_OUTPUT" | grep "FAIL" || true
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
