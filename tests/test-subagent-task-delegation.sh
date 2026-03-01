#!/bin/bash
# test-subagent-task-delegation.sh - Task() delegation enforcement validation
# TC-01 ~ TC-09

set -euo pipefail

# Constants
BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_FILE="$BASE_DIR/skills/orchestrate/steps-subagent.md"
MUST_MARKER='> **MUST**: Task() で委譲すること。PdM による Skill() 直接呼び出し禁止。'

# Test result counters
PASS=0
FAIL=0

# Test result helpers
pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

# Extract section content between two markdown headings
# Usage: extract_section "file" "start_heading" "end_heading"
# start_heading/end_heading are grep patterns for ### level headings
extract_section() {
  local file="$1"
  local start="$2"
  local end="$3"
  sed -n "/^### ${start}/,/^### ${end}/p" "$file" | sed '$d'
}

# Extract content between two ## level headings
# Usage: extract_block "file" "start_heading" "end_heading"
extract_block() {
  local file="$1"
  local start="$2"
  local end="$3"
  sed -n "/^## ${start}/,/^## ${end}/p" "$file" | sed '$d'
}

# Early guard: target file must exist
if [ ! -f "$TARGET_FILE" ]; then
  echo "FATAL: steps-subagent.md not found at $TARGET_FILE"
  exit 1
fi

echo "=== Subagent Task() Delegation Enforcement Tests ==="

########################################
# MUST Marker Validation (Layer 2)
########################################

echo ""
echo "--- MUST Marker Validation (Layer 2) ---"

# TC-01 ~ TC-03: Each phase section contains MUST marker for Task() delegation
# Given: steps-subagent.md has ### KICKOFF/RED/GREEN sections
# When: checking for MUST marker in each section
# Then: should find the exact MUST string requiring Task() delegation

MUST_MARKER_CASES=(
  "KICKOFF:Delegation"
  "RED:GREEN"
  "GREEN:REVIEW"
)

TC_NUM=1
for case in "${MUST_MARKER_CASES[@]}"; do
  phase="${case%%:*}"
  end_heading="${case##*:}"

  echo ""
  echo "TC-$(printf '%02d' $TC_NUM): ${phase} section contains MUST marker"

  section_content=$(extract_section "$TARGET_FILE" "$phase" "$end_heading")
  if echo "$section_content" | grep -qF "$MUST_MARKER"; then
    pass "${phase} section has MUST marker"
  else
    fail "${phase} section missing MUST marker"
  fi

  TC_NUM=$((TC_NUM + 1))
done

########################################
# /simplify delegation (Layer 2)
########################################

echo ""
echo "--- /simplify Delegation (Layer 2) ---"

# TC-04: /simplify section references refactor skill
echo ""
echo "TC-04: /simplify section references Skill(refactor)"
if grep -q "Skill(dev-crew:refactor)" "$TARGET_FILE"; then
  pass "/simplify section references Skill(refactor)"
else
  fail "/simplify section missing Skill(refactor) reference"
fi

########################################
# REVIEW Exception (Layer 2)
########################################

echo ""
echo "--- REVIEW Exception (Layer 2) ---"

# TC-05: REVIEW section contains exception note for review
echo ""
echo "TC-05: REVIEW section contains exception note"
REVIEW_SECTION=$(extract_section "$TARGET_FILE" "REVIEW" "Phase Summary")
if echo "$REVIEW_SECTION" | grep -qF '> NOTE: review 内部で subagent 化済みのため、Skill() 直接呼び出しが正しい。'; then
  pass "REVIEW section has exception note"
else
  fail "REVIEW section missing exception note for review"
fi

########################################
# Delegation Rule (Layer 1)
########################################

echo ""
echo "--- Delegation Rule (Layer 1) ---"

# TC-06: Delegation Decision section does NOT contain lightweight -> PdM direct execution (negative test)
echo ""
echo "TC-06: No 'lightweight -> PdM direct execution' pattern (negative test)"
if grep -qE "lightweight.*PdM 直接実行|lightweight.*Skill\(\)" "$TARGET_FILE" 2>/dev/null; then
  fail "Found 'lightweight -> PdM direct execution' pattern (must be removed)"
else
  pass "No 'lightweight -> PdM direct execution' pattern found"
fi

########################################
# Fallback Constraint (Layer 1)
########################################

echo ""
echo "--- Fallback Constraint (Layer 1) ---"

# TC-07: Fallback section references Task() spawn errors
echo ""
echo "TC-07: Fallback section references Task() spawn errors"
FALLBACK_SECTION=$(sed -n '/^## Fallback/,$p' "$TARGET_FILE")
if echo "$FALLBACK_SECTION" | grep -qE "Task\(\).*失敗|spawn.*エラー|タイムアウト"; then
  pass "Fallback section references Task() spawn errors"
else
  fail "Fallback section missing Task() spawn error reference"
fi

########################################
# PdM Pre-Flight Check (Layer 3)
########################################

echo ""
echo "--- PdM Pre-Flight Check (Layer 3) ---"

# TC-08: Pre-Flight Check exists in Block 1
echo ""
echo "TC-08: Pre-Flight Check exists in Block 1"
BLOCK1_CONTENT=$(extract_block "$TARGET_FILE" "Block 1" "Block 2")
if echo "$BLOCK1_CONTENT" | grep -q "Pre-Flight Check"; then
  pass "Block 1 has Pre-Flight Check"
else
  fail "Block 1 missing Pre-Flight Check"
fi

# TC-09: Pre-Flight Check exists in Block 2
echo ""
echo "TC-09: Pre-Flight Check exists in Block 2"
BLOCK2_CONTENT=$(extract_block "$TARGET_FILE" "Block 2" "Block 3")
if echo "$BLOCK2_CONTENT" | grep -q "Pre-Flight Check"; then
  pass "Block 2 has Pre-Flight Check"
else
  fail "Block 2 missing Pre-Flight Check"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
