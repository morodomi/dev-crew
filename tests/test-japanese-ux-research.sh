#!/bin/bash
# test-japanese-ux-research.sh - Japanese UX patterns research document validation
# TC-30 ~ TC-38

set -euo pipefail

# Constants
BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_FILE="$BASE_DIR/docs/research/japanese-ux-patterns.md"
MIN_PATTERN_COUNT=10
MIN_SOURCE_COUNT=5
GREP_CONTEXT=50

# Test result counters
PASS=0
FAIL=0

# Test result helpers
pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

# Check that all items in an array exist in the target file
# Usage: check_all_present "TC label" "pass msg" "fail msg" item1 item2 ...
check_all_present() {
  local label="$1" pass_msg="$2" fail_msg="$3"
  shift 3
  local ok=true
  for item in "$@"; do
    if grep -qF "$item" "$TARGET_FILE"; then
      printf "    found: %s\n" "$item"
    else
      printf "    missing: %s\n" "$item"
      ok=false
    fi
  done
  if [ "$ok" = true ]; then pass "$pass_msg"; else fail "$fail_msg"; fi
}

echo "=== Japanese UX Research Document Tests ==="

########################################
# TC-30: File existence (early guard)
########################################

echo ""
echo "--- File Existence ---"

# Given: the research doc path is defined
# When: checking filesystem
# Then: file must exist; abort all tests if missing
echo ""
echo "TC-30: japanese-ux-patterns.md exists"
if [ -f "$TARGET_FILE" ]; then
  pass "japanese-ux-patterns.md exists"
else
  fail "japanese-ux-patterns.md not found at $TARGET_FILE"
  echo ""
  echo "=== Summary ==="
  echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
  exit 1
fi

########################################
# TC-31: Required sections
########################################

echo ""
echo "--- Required Sections ---"

# Given: a valid research document
# When: checking for top-level sections
# Then: Overview, Categories, Designer Agent Prompt Reference, Sources must all exist
echo ""
echo "TC-31: Required sections exist"
TC31_OK=true
for section in "Overview" "Categories" "Designer Agent Prompt Reference" "Sources"; do
  if grep -q "^#\+\s*${section}" "$TARGET_FILE"; then
    printf "    found: %s\n" "$section"
  else
    printf "    missing: %s\n" "$section"
    TC31_OK=false
  fi
done

if [ "$TC31_OK" = true ]; then
  pass "All required sections present"
else
  fail "One or more required sections missing"
fi

########################################
# TC-32: Pattern count >= MIN_PATTERN_COUNT
########################################

echo ""
echo "--- Pattern Count ---"

# Given: document contains patterns identified by P-XX headings
# When: counting unique pattern headings
# Then: must have at least MIN_PATTERN_COUNT patterns
echo ""
echo "TC-32: At least $MIN_PATTERN_COUNT patterns (P-01 ~ P-10+)"
PATTERN_COUNT=$(grep -cE '^#+\s*P-[0-9]+' "$TARGET_FILE" || true)
PATTERN_COUNT=${PATTERN_COUNT:-0}
echo "    found: $PATTERN_COUNT patterns"
if [ "$PATTERN_COUNT" -ge "$MIN_PATTERN_COUNT" ]; then
  pass "Pattern count >= $MIN_PATTERN_COUNT ($PATTERN_COUNT found)"
else
  fail "Pattern count < $MIN_PATTERN_COUNT ($PATTERN_COUNT found)"
fi

# Extract pattern IDs for use in TC-33 and TC-37
PATTERN_IDS=$(grep -oE 'P-[0-9]+' "$TARGET_FILE" | sort -u || true)

########################################
# TC-33: Unified format per pattern
########################################

echo ""
echo "--- Unified Format ---"

# Given: each pattern should have Japanese Pattern, Western Pattern, Implementation Guidelines
# When: checking GREP_CONTEXT lines after each pattern ID
# Then: all required fields must appear
echo ""
echo "TC-33: Each pattern has unified format fields"
TC33_OK=true
TC33_CHECKED=0
for pid in $PATTERN_IDS; do
  for field in "Japanese Pattern" "Western Pattern" "Implementation Guidelines"; do
    if ! grep -A "$GREP_CONTEXT" "$pid" "$TARGET_FILE" 2>/dev/null | grep -q "$field"; then
      printf "    %s missing field: %s\n" "$pid" "$field"
      TC33_OK=false
    fi
  done
  TC33_CHECKED=$((TC33_CHECKED + 1))
done

if [ "$TC33_CHECKED" -eq 0 ]; then
  fail "No patterns found to check format"
elif [ "$TC33_OK" = true ]; then
  pass "All patterns have unified format ($TC33_CHECKED checked)"
else
  fail "Some patterns missing required format fields"
fi

########################################
# TC-34: Decision Matrix table
########################################

echo ""
echo "--- Decision Matrix ---"

# Given: Designer Agent Prompt Reference section exists
# When: extracting that section
# Then: must contain a markdown table
echo ""
echo "TC-34: Designer Agent Prompt Reference has Decision Matrix table"
PROMPT_REF_SECTION=$(sed -n '/^#.*Designer Agent Prompt Reference/,/^# [^#]/p' "$TARGET_FILE" 2>/dev/null || echo "")
if echo "$PROMPT_REF_SECTION" | grep -qE '^\|.*\|.*\|'; then
  pass "Decision Matrix table found in Designer Agent Prompt Reference"
else
  fail "Decision Matrix table not found in Designer Agent Prompt Reference"
fi

########################################
# TC-35: Sources >= MIN_SOURCE_COUNT
########################################

echo ""
echo "--- Sources ---"

# Given: Sources section at end of document
# When: counting numbered/bulleted list items
# Then: must have at least MIN_SOURCE_COUNT references
echo ""
echo "TC-35: Sources section has >= $MIN_SOURCE_COUNT references"
SOURCES_SECTION=$(sed -n '/^#.*Sources/,$p' "$TARGET_FILE" 2>/dev/null || echo "")
SOURCE_COUNT=$(echo "$SOURCES_SECTION" | grep -cE '^\s*[-*]|^\s*[0-9]+\.' || true)
SOURCE_COUNT=${SOURCE_COUNT:-0}
echo "    found: $SOURCE_COUNT references"
if [ "$SOURCE_COUNT" -ge "$MIN_SOURCE_COUNT" ]; then
  pass "Sources count >= $MIN_SOURCE_COUNT ($SOURCE_COUNT found)"
else
  fail "Sources count < $MIN_SOURCE_COUNT ($SOURCE_COUNT found)"
fi

########################################
# TC-36: All 4 categories exist
########################################

echo ""
echo "--- Categories ---"

# Given: document organizes patterns into 4 categories
# When: checking for category headings
# Then: all 4 must be present
echo ""
echo "TC-36: All 4 categories present"
check_all_present "TC-36" \
  "All 4 categories present" \
  "One or more categories missing" \
  "Visual Design" "Information Architecture" "Interaction Design" "Trust & Credibility"

########################################
# TC-37: Examples section per pattern
########################################

echo ""
echo "--- Examples Section ---"

# Given: each pattern should have real-world examples
# When: checking GREP_CONTEXT lines after each pattern ID
# Then: must find "Examples" text
echo ""
echo "TC-37: Each pattern has Examples section"
TC37_OK=true
TC37_CHECKED=0
for pid in $PATTERN_IDS; do
  if ! grep -A "$GREP_CONTEXT" "$pid" "$TARGET_FILE" 2>/dev/null | grep -qE 'Examples|examples'; then
    printf "    %s missing Examples section\n" "$pid"
    TC37_OK=false
  fi
  TC37_CHECKED=$((TC37_CHECKED + 1))
done

if [ "$TC37_CHECKED" -eq 0 ]; then
  fail "No patterns found to check Examples"
elif [ "$TC37_OK" = true ]; then
  pass "All patterns have Examples section ($TC37_CHECKED checked)"
else
  fail "Some patterns missing Examples section"
fi

########################################
# TC-38: Negative test - empty file
########################################

echo ""
echo "--- Negative Test ---"

# Given: an empty temporary file
# When: running pattern count check against it
# Then: must fail the minimum pattern count threshold
echo ""
echo "TC-38: Empty file fails TC-32 pattern count check"
TEMP_FILE=$(mktemp)
touch "$TEMP_FILE"
EMPTY_PATTERN_COUNT=$(grep -cE '^#+\s*P-[0-9]+' "$TEMP_FILE" || true)
EMPTY_PATTERN_COUNT=${EMPTY_PATTERN_COUNT:-0}
rm -f "$TEMP_FILE"

if [ "$EMPTY_PATTERN_COUNT" -lt "$MIN_PATTERN_COUNT" ]; then
  pass "Empty file correctly fails pattern count check (found $EMPTY_PATTERN_COUNT)"
else
  fail "Empty file should fail pattern count check but got $EMPTY_PATTERN_COUNT"
fi

########################################
# Summary
########################################

echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
