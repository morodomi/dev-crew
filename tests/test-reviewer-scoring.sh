#!/bin/bash
# test-reviewer-scoring.sh - Reviewer scoring terminology migration validation
# TC-01 to TC-10: Verify migration from confidence to blocking_score

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

# Terminal output helpers
pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

# Generic file array checker - returns count of failures
# Usage: check_all_files_contain <tc_id> <pattern> <description> <file_array[@]>
check_all_files_contain() {
  local tc_id="$1"
  local pattern="$2"
  local desc="$3"
  shift 3
  local files=("$@")
  local fail_count=0

  for file in "${files[@]}"; do
    if [ ! -f "$file" ]; then
      fail "$tc_id: $(basename "$file") not found"
      fail_count=$((fail_count + 1))
      continue
    fi

    if ! grep -q "$pattern" "$file"; then
      fail "$tc_id: $(basename "$file") missing '$pattern'"
      fail_count=$((fail_count + 1))
    fi
  done

  [ "$fail_count" -eq 0 ] && pass "$tc_id: $desc"
  return "$fail_count"
}

# Generic file array checker for negative assertions
# Usage: check_all_files_not_contain <tc_id> <pattern> <description> <file_array[@]>
check_all_files_not_contain() {
  local tc_id="$1"
  local pattern="$2"
  local desc="$3"
  shift 3
  local files=("$@")
  local fail_count=0

  for file in "${files[@]}"; do
    [ ! -f "$file" ] && continue

    if grep -q "$pattern" "$file"; then
      fail "$tc_id: $(basename "$file") still contains '$pattern'"
      fail_count=$((fail_count + 1))
    fi
  done

  [ "$fail_count" -eq 0 ] && pass "$tc_id: $desc"
  return "$fail_count"
}

# Single file checker for positive assertions
# Usage: check_single_file_contains <tc_id> <file> <pattern> <description>
check_single_file_contains() {
  local tc_id="$1"
  local file="$2"
  local pattern="$3"
  local desc="$4"

  if [ ! -f "$file" ]; then
    fail "$tc_id: $(basename "$file") not found"
    return 1
  elif ! grep -q "$pattern" "$file"; then
    fail "$tc_id: $(basename "$file") missing '$pattern'"
    return 1
  else
    pass "$tc_id: $desc"
    return 0
  fi
}

# Constants: 9 reviewer agents
REVIEWERS=(
  "correctness-reviewer"
  "performance-reviewer"
  "security-reviewer"
  "guidelines-reviewer"
  "product-reviewer"
  "risk-reviewer"
  "scope-reviewer"
  "architecture-reviewer"
  "usability-reviewer"
)

# Build file paths array
REVIEWER_FILES=()
for reviewer in "${REVIEWERS[@]}"; do
  REVIEWER_FILES+=("$BASE_DIR/agents/${reviewer}.md")
done

echo "=== Reviewer Scoring Migration Tests ==="

# TC-01: All reviewer agents have blocking_score
echo ""
echo "TC-01: All reviewer agents have 'blocking_score'"
check_all_files_contain "TC-01" '"blocking_score"' "All 9 reviewer agents have 'blocking_score'" "${REVIEWER_FILES[@]}"

# TC-02: All reviewer agents do not have old "confidence"
echo ""
echo "TC-02: All reviewer agents do not contain old 'confidence'"
check_all_files_not_contain "TC-02" '"confidence"' "All 9 reviewer agents do not contain old 'confidence'" "${REVIEWER_FILES[@]}"

# TC-03: All reviewer agents have ブロッキングスコア基準 section
echo ""
echo "TC-03: All reviewer agents have 'ブロッキングスコア基準' section"
check_all_files_contain "TC-03" 'ブロッキングスコア基準' "All 9 reviewer agents have 'ブロッキングスコア基準' section" "${REVIEWER_FILES[@]}"

# TC-04: All reviewer agents do not have old 信頼スコア基準
echo ""
echo "TC-04: All reviewer agents do not contain old '信頼スコア基準'"
check_all_files_not_contain "TC-04" '信頼スコア基準' "All 9 reviewer agents do not contain old '信頼スコア基準'" "${REVIEWER_FILES[@]}"

# TC-05: All reviewer agents have score explanation text
echo ""
echo "TC-05: All reviewer agents have score explanation '0 = 問題なし'"
check_all_files_contain "TC-05" '0 = 問題なし' "All 9 reviewer agents have score explanation text" "${REVIEWER_FILES[@]}"

# TC-06: quality-gate SKILL.md has ブロッキングスコア
echo ""
echo "TC-06: quality-gate SKILL.md has 'ブロッキングスコア'"
check_single_file_contains "TC-06" "$BASE_DIR/skills/quality-gate/SKILL.md" 'ブロッキングスコア' "quality-gate SKILL.md has 'ブロッキングスコア'"

# TC-07: plan-review SKILL.md has ブロッキングスコア
echo ""
echo "TC-07: plan-review SKILL.md has 'ブロッキングスコア'"
check_single_file_contains "TC-07" "$BASE_DIR/skills/plan-review/SKILL.md" 'ブロッキングスコア' "plan-review SKILL.md has 'ブロッキングスコア'"

# TC-08: skill reference.md files do not have old 信頼スコア
echo ""
echo "TC-08: skill reference.md files do not contain old '信頼スコア'"
REF_FILES=(
  "$BASE_DIR/skills/quality-gate/reference.md"
  "$BASE_DIR/skills/plan-review/reference.md"
  "$BASE_DIR/skills/review/reference.md"
)
check_all_files_not_contain "TC-08" '信頼スコア' "skill reference.md files do not contain old '信頼スコア'" "${REF_FILES[@]}"

# TC-09: steps-subagent.md files do not have old "confidence"
echo ""
echo "TC-09: steps-subagent.md files do not contain old 'confidence'"
STEPS_FILES=(
  "$BASE_DIR/skills/quality-gate/steps-subagent.md"
  "$BASE_DIR/skills/plan-review/steps-subagent.md"
)
check_all_files_not_contain "TC-09" '"confidence"' "steps-subagent.md files do not contain old 'confidence'" "${STEPS_FILES[@]}"

# TC-10: Out-of-scope files still have confidence (unchanged)
echo ""
echo "TC-10: Out-of-scope files still contain 'confidence' (unchanged)"
SCOPE_EXTERNAL=(
  "$BASE_DIR/agents/observer.md"
  "$BASE_DIR/agents/false-positive-filter-reference.md"
  "$BASE_DIR/skills/learn/reference.md"
  "$BASE_DIR/skills/diagnose/steps-subagent.md"
  "$BASE_DIR/skills/diagnose/reference.md"
)
check_all_files_contain "TC-10" 'confidence' "Out-of-scope files still contain 'confidence' (unchanged)" "${SCOPE_EXTERNAL[@]}"

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
