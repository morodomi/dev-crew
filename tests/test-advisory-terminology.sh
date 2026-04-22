#!/bin/bash
# test-advisory-terminology.sh - advisory terminology replacement tests (eval-4)
# TC-01 (TC-A1): steps-codex.md does NOT contain 'advisory' (case-insensitive)
# TC-02 (TC-A5): steps-codex.md and steps-teams.md VERIFY-section line body is identical
# TC-03 (TC-A6): Both files contain cross-link reference.md#product-verification in VERIFY section
# TC-04 (contract): reference.md STILL contains 'advisory' (TC-07 contract preservation)

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

STEPS_CODEX="$BASE_DIR/skills/orchestrate/steps-codex.md"
STEPS_TEAMS="$BASE_DIR/skills/orchestrate/steps-teams.md"
REFERENCE="$BASE_DIR/skills/orchestrate/reference.md"

# VERIFY-section line body pattern: post-fix ('参考エビデンス') OR pre-fix ('advisory evidence')
VERIFY_LINE_PATTERN='参考エビデンス、委譲不要\|advisory evidence、委譲不要'
PV_CROSSLINK='reference.md#product-verification'

echo "=== Advisory Terminology Tests ==="

# TC-01: steps-codex.md AND steps-teams.md must NOT contain 'advisory' (case-insensitive)
# Both files are mirror-paired; test both to catch future drift where only one is updated.
echo ""
echo "TC-01: steps-codex.md and steps-teams.md do not contain 'advisory'"
if grep -qi 'advisory' "$STEPS_CODEX"; then
  fail "TC-01: 'advisory' still present in steps-codex.md (must be '参考エビデンス')"
elif grep -qi 'advisory' "$STEPS_TEAMS"; then
  fail "TC-01: 'advisory' still present in steps-teams.md (must be '参考エビデンス')"
else
  pass "TC-01: 'advisory' not found in either steps-codex.md or steps-teams.md"
fi

# TC-02: Both steps-codex.md and steps-teams.md VERIFY-section lines have identical body text
# The line contains '参考エビデンス、委譲不要' or 'advisory evidence、委譲不要'
echo ""
echo "TC-02: steps-codex.md and steps-teams.md VERIFY-section line body is identical"
codex_line="$(grep "$VERIFY_LINE_PATTERN" "$STEPS_CODEX" || true)"
teams_line="$(grep "$VERIFY_LINE_PATTERN" "$STEPS_TEAMS" || true)"

codex_count=$(echo "$codex_line" | grep -c '.' || true)
teams_count=$(echo "$teams_line" | grep -c '.' || true)

if [ "$codex_count" -ne 1 ]; then
  fail "TC-02: steps-codex.md must have exactly 1 matching line, found $codex_count"
elif [ "$teams_count" -ne 1 ]; then
  fail "TC-02: steps-teams.md must have exactly 1 matching line, found $teams_count"
elif [ "$codex_line" = "$teams_line" ]; then
  pass "TC-02: Both files have identical VERIFY-section line body"
else
  fail "TC-02: VERIFY-section lines differ between files (codex='$codex_line' teams='$teams_line')"
fi

# TC-03: Both files contain cross-link reference.md#product-verification
echo ""
echo "TC-03: Both files contain cross-link reference.md#product-verification"
codex_has_link=0
teams_has_link=0
grep -q "$PV_CROSSLINK" "$STEPS_CODEX" && codex_has_link=1 || true
grep -q "$PV_CROSSLINK" "$STEPS_TEAMS" && teams_has_link=1 || true

if [ "$codex_has_link" -eq 1 ] && [ "$teams_has_link" -eq 1 ]; then
  pass "TC-03: Both steps-codex.md and steps-teams.md contain reference.md#product-verification cross-link"
else
  if [ "$codex_has_link" -eq 0 ]; then
    fail "TC-03: steps-codex.md is missing cross-link reference.md#product-verification"
  fi
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
