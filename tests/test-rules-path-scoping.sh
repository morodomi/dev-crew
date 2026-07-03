#!/bin/bash
# test-rules-path-scoping.sh - rules path-scoping frontmatter tests
# TC-01 to TC-04 for rules-path-scoping cycle

set -uo pipefail

BASE_DIR="${BASE_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

RULES_DIR="$BASE_DIR/rules"
CLAUDE_RULES_DIR="$BASE_DIR/.claude/rules"

echo "=== rules path-scoping Tests (20260625_1101) ==="

# Helper: extract frontmatter body (between first and second --- delimiters)
# Usage: frontmatter_of <file>
# Anchored to line 1: frontmatter MUST open with ^---$ on the very first line
# (Claude Code rules contract). A heading or any content before --- yields empty
# output, preventing false-pass when frontmatter is not at the top.
frontmatter_of() {
  awk 'NR==1{if($0!="---") exit} NR>1 && /^---$/{exit} NR>1{print}' "$1"
}

# TC-01: rules/test-patterns.md frontmatter has paths: containing tests/**
# Given: rules/test-patterns.md is a rule file scheduled for path-scoping
# When:  awk extracts content between the two --- delimiters (frontmatter range)
# Then:  the extracted text contains "tests/**"
echo ""
echo "TC-01: rules/test-patterns.md frontmatter has paths: with tests/**"
FILE="$RULES_DIR/test-patterns.md"
if [ ! -f "$FILE" ]; then
  fail "TC-01: rules/test-patterns.md does not exist"
else
  # awk frontmatter scan — body content must NOT be searched (whole-file grep禁止)
  fm_output=$(frontmatter_of "$FILE" 2>&1 || true)
  has_paths=$(echo "$fm_output" | grep -cF "paths:" || true)
  has_glob=$(echo "$fm_output" | grep -cF "tests/**" || true)
  if [ "$has_paths" -ge 1 ] && [ "$has_glob" -ge 1 ]; then
    pass "TC-01: rules/test-patterns.md frontmatter has paths: with tests/**"
  elif [ "$has_paths" -lt 1 ]; then
    fail "TC-01: rules/test-patterns.md frontmatter missing 'paths:' key (frontmatter not added yet?)"
  else
    fail "TC-01: rules/test-patterns.md frontmatter has paths: but missing 'tests/**' value"
  fi
fi

# TC-02: rules/skill-authoring.md frontmatter has paths: containing skills/**
# Given: rules/skill-authoring.md is a rule file scheduled for path-scoping
# When:  awk extracts content between the two --- delimiters (frontmatter range)
# Then:  the extracted text contains "skills/**"
echo ""
echo "TC-02: rules/skill-authoring.md frontmatter has paths: with skills/**"
FILE="$RULES_DIR/skill-authoring.md"
if [ ! -f "$FILE" ]; then
  fail "TC-02: rules/skill-authoring.md does not exist"
else
  fm_output=$(frontmatter_of "$FILE" 2>&1 || true)
  has_paths=$(echo "$fm_output" | grep -cF "paths:" || true)
  has_glob=$(echo "$fm_output" | grep -cF "skills/**" || true)
  if [ "$has_paths" -ge 1 ] && [ "$has_glob" -ge 1 ]; then
    pass "TC-02: rules/skill-authoring.md frontmatter has paths: with skills/**"
  elif [ "$has_paths" -lt 1 ]; then
    fail "TC-02: rules/skill-authoring.md frontmatter missing 'paths:' key (frontmatter not added yet?)"
  else
    fail "TC-02: rules/skill-authoring.md frontmatter has paths: but missing 'skills/**' value"
  fi
fi

# TC-03: Both canonical files have exactly 2 --- delimiters (balanced open/close frontmatter)
# Given: frontmatter requires exactly one opening --- and one closing --- line
# When:  grep -cE '^---$' counts ^---$ lines in each file
# Then:  count == 2 for both rules/test-patterns.md and rules/skill-authoring.md
echo ""
echo "TC-03: Both canonical files have exactly 2 '---' delimiters (balanced frontmatter)"
TC03_PASS=true
for fname in "test-patterns.md" "skill-authoring.md"; do
  fpath="$RULES_DIR/$fname"
  if [ ! -f "$fpath" ]; then
    fail "TC-03: rules/$fname does not exist"
    TC03_PASS=false
    continue
  fi
  # count is obtained once — no || fallback concatenation (test-patterns.md #4禁止事項準拠)
  delim_count=$(grep -cE '^---$' "$fpath" || true)
  if [ "$delim_count" -eq 2 ]; then
    : # ok
  else
    fail "TC-03: rules/$fname has $delim_count '---' delimiter(s), expected exactly 2"
    TC03_PASS=false
  fi
done
if [ "$TC03_PASS" = "true" ]; then
  pass "TC-03: Both canonical files have exactly 2 '---' delimiters"
fi

# TC-04: .claude/rules/ mirror files are byte-identical to canonical rules/
# Given: mirror invariant requires byte-identical content between rules/ and .claude/rules/
# When:  line-1 frontmatter presence is asserted (RED guard) AND full-file diff is run
# Then:  frontmatter present AND diff empty for both pairs (catches body drift, not just frontmatter)
echo ""
echo "TC-04: .claude/rules/ mirror files are byte-identical to canonical (full-file diff)"
TC04_PASS=true
for fname in "test-patterns.md" "skill-authoring.md"; do
  canonical="$RULES_DIR/$fname"
  mirror="$CLAUDE_RULES_DIR/$fname"
  if [ ! -f "$canonical" ]; then
    fail "TC-04: canonical rules/$fname does not exist"
    TC04_PASS=false
    continue
  fi
  if [ ! -f "$mirror" ]; then
    fail "TC-04: mirror .claude/rules/$fname does not exist"
    TC04_PASS=false
    continue
  fi
  # RED guard: require line-1 frontmatter present (fails before GREEN adds it)
  fm_canonical=$(frontmatter_of "$canonical" 2>&1 || true)
  if [ -z "$fm_canonical" ]; then
    fail "TC-04: rules/$fname has no line-1 frontmatter (mirror+presence cannot be verified)"
    TC04_PASS=false
  # Full-file byte comparison — catches body drift, not only frontmatter divergence
  elif diff -q "$canonical" "$mirror" >/dev/null 2>&1; then
    : # ok — canonical and mirror are byte-identical (frontmatter + body)
  else
    fail "TC-04: .claude/rules/$fname differs from rules/$fname (full-file mirror drift)"
    TC04_PASS=false
  fi
done
if [ "$TC04_PASS" = "true" ]; then
  pass "TC-04: All mirror files are byte-identical to their canonical counterpart"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
