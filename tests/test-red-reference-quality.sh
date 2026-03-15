#!/bin/bash
# test-red-reference-quality.sh - Verify red reference.md test design quality rules
# T-01 to T-04: Verify test design quality sections exist

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

# Terminal output helpers
pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

FILE="$BASE_DIR/skills/red/reference.md"

echo "=== Red Reference Quality Tests ==="

if [ ! -f "$FILE" ]; then
  fail "red/reference.md not found"
  echo ""
  echo "=== Summary ==="
  echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
  exit 1
fi

# T-01: reference.md contains "Test Design Quality Rules" section
echo ""
echo "T-01: reference.md contains 'Test Design Quality Rules' section"
if grep -q 'Test Design Quality Rules' "$FILE"; then
  pass "T-01: 'Test Design Quality Rules' section exists"
else
  fail "T-01: 'Test Design Quality Rules' section missing"
fi

# T-02: reference.md contains "AND条件ルール" subsection
echo ""
echo "T-02: reference.md contains 'AND条件ルール' subsection"
if grep -q 'AND条件ルール' "$FILE"; then
  pass "T-02: 'AND条件ルール' subsection exists"
else
  fail "T-02: 'AND条件ルール' subsection missing"
fi

# T-03: reference.md contains "検証粒度ルール" subsection
echo ""
echo "T-03: reference.md contains '検証粒度ルール' subsection"
if grep -q '検証粒度ルール' "$FILE"; then
  pass "T-03: '検証粒度ルール' subsection exists"
else
  fail "T-03: '検証粒度ルール' subsection missing"
fi

# T-04: reference.md contains "動的取得推奨" subsection
echo ""
echo "T-04: reference.md contains '動的取得推奨' subsection"
if grep -q '動的取得推奨' "$FILE"; then
  pass "T-04: '動的取得推奨' subsection exists"
else
  fail "T-04: '動的取得推奨' subsection missing"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
