#!/bin/bash
# test-gotchas-structure.sh - Verify ## Gotchas section exists in 6 core skill reference.md files
# T-01 to T-08

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== Gotchas Structure Tests ==="

# Skills under test
SKILLS="orchestrate spec red green review commit"

########################################
# T-01 to T-06: Each skill reference.md has ## Gotchas section
########################################

echo ""
echo "--- T-01 to T-06: ## Gotchas section present ---"

T_NUM=1
for skill in $SKILLS; do
  FILE="$BASE_DIR/skills/$skill/reference.md"
  echo ""
  echo "T-0${T_NUM}: Given skills/$skill/reference.md, When grep '## Gotchas', Then match"

  if [ ! -f "$FILE" ]; then
    fail "T-0${T_NUM}: skills/$skill/reference.md not found"
  elif grep -q '^## Gotchas' "$FILE"; then
    pass "T-0${T_NUM}: skills/$skill/reference.md has '## Gotchas' section"
  else
    fail "T-0${T_NUM}: skills/$skill/reference.md missing '## Gotchas' section"
  fi

  T_NUM=$((T_NUM + 1))
done

########################################
# T-07: Each Gotchas section has at least 1 table row (|)
########################################

echo ""
echo "--- T-07: Gotchas section contains at least 1 table row ---"
echo ""
echo "T-07: Given each skill reference.md, When checking Gotchas section, Then at least 1 table row exists"

ALL_HAVE_TABLE=true
for skill in $SKILLS; do
  FILE="$BASE_DIR/skills/$skill/reference.md"

  if [ ! -f "$FILE" ]; then
    fail "T-07: skills/$skill/reference.md not found"
    ALL_HAVE_TABLE=false
    continue
  fi

  # Extract lines after ## Gotchas and check for table row (|)
  # awk: print lines after "## Gotchas" until next "##" heading or EOF, then check for |
  table_rows=$(awk '/^## Gotchas/{found=1; next} found && /^## /{exit} found && /\|/{print}' "$FILE" | wc -l | tr -d ' ')

  if [ "$table_rows" -lt 1 ]; then
    fail "T-07: skills/$skill/reference.md Gotchas section has no table rows"
    ALL_HAVE_TABLE=false
  fi
done

if $ALL_HAVE_TABLE; then
  pass "T-07: All skills have at least 1 table row in Gotchas section"
else
  fail "T-07: One or more skills are missing table rows in Gotchas section"
fi

########################################
# T-08: [Negative] A temp reference.md without Gotchas should FAIL the grep check
########################################

echo ""
echo "--- T-08: [Negative] reference.md without Gotchas fails grep ---"
echo ""
echo "T-08: Given a temp reference.md without ## Gotchas, When grep '## Gotchas', Then no match"

TMPFILE=$(mktemp /tmp/test-gotchas-reference-XXXXXX.md)
trap 'rm -f "$TMPFILE"' EXIT

cat > "$TMPFILE" << 'MARKDOWN'
# Test Reference

## Overview
This is a reference file without a Gotchas section.

## Usage
Some usage details here.
MARKDOWN

if grep -q '^## Gotchas' "$TMPFILE"; then
  fail "T-08: temp reference.md without Gotchas unexpectedly matched (test invalid)"
else
  pass "T-08: temp reference.md without Gotchas correctly does not match (negative test confirmed)"
fi

########################################
# Summary
########################################

echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
