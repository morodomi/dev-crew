#!/bin/bash
# test-advisory-terminology.sh - advisory terminology replacement tests (eval-4)
# TC-01 (TC-A1): steps-teams.md does NOT contain 'advisory' (case-insensitive)
# TC-03 (TC-A6): steps-teams.md contains cross-link reference.md#product-verification in VERIFY section
# TC-04 (contract): reference.md STILL contains 'advisory' (TC-07 contract preservation)

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

STEPS_TEAMS="$BASE_DIR/skills/orchestrate/steps-teams.md"
REFERENCE="$BASE_DIR/skills/orchestrate/reference.md"

PV_CROSSLINK='reference.md#product-verification'

echo "=== Advisory Terminology Tests ==="

# TC-01: steps-teams.md must NOT contain 'advisory' (case-insensitive)
echo ""
echo "TC-01: steps-teams.md does not contain 'advisory'"
if grep -qi 'advisory' "$STEPS_TEAMS"; then
  fail "TC-01: 'advisory' still present in steps-teams.md (must be '参考エビデンス')"
else
  pass "TC-01: 'advisory' not found in steps-teams.md"
fi

# TC-03: steps-teams.md contains cross-link reference.md#product-verification
echo ""
echo "TC-03: steps-teams.md contains cross-link reference.md#product-verification"
teams_has_link=0
grep -q "$PV_CROSSLINK" "$STEPS_TEAMS" && teams_has_link=1 || true

if [ "$teams_has_link" -eq 1 ]; then
  pass "TC-03: steps-teams.md contains reference.md#product-verification cross-link"
else
  if [ "$teams_has_link" -eq 0 ]; then
    fail "TC-03: steps-teams.md is missing cross-link reference.md#product-verification"
  fi
fi

# TC-04: reference.md STILL contains 'advisory' (contract invariant, TC-07 preservation)
echo ""
echo "TC-04: reference.md still contains 'advisory' (TC-07 contract)"
if grep -qi 'advisory' "$REFERENCE"; then
  pass "TC-04: reference.md contains 'advisory' (TC-07 contract preserved)"
else
  fail "TC-04: 'advisory' not found in reference.md (TC-07 contract broken)"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
