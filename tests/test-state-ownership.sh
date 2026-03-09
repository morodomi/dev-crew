#!/bin/bash
# test-state-ownership.sh - State ownership rules + Cycle doc frontmatter validation
# TC-S1, TC-S2, TC-S3, TC-S4, TC-S5, TC-S6

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== State Ownership Rules + Frontmatter Tests ==="

# TC-S1: rules/state-ownership.md exists and contains plan file immutability rule
echo ""
echo "TC-S1: rules/state-ownership.md exists with plan file immutability rule"
OWNERSHIP_FILE="$BASE_DIR/rules/state-ownership.md"
if [ ! -f "$OWNERSHIP_FILE" ]; then
  fail "TC-S1: rules/state-ownership.md does not exist"
elif grep -qi "immutable" "$OWNERSHIP_FILE"; then
  pass "TC-S1: rules/state-ownership.md exists and contains IMMUTABLE rule"
else
  fail "TC-S1: rules/state-ownership.md exists but missing IMMUTABLE rule"
fi

# TC-S2: rules/state-ownership.md contains Cycle doc append-only rule
echo ""
echo "TC-S2: rules/state-ownership.md contains Cycle doc append-only rule"
if [ ! -f "$OWNERSHIP_FILE" ]; then
  fail "TC-S2: rules/state-ownership.md does not exist"
elif grep -qiE "append.only" "$OWNERSHIP_FILE"; then
  pass "TC-S2: rules/state-ownership.md contains APPEND-ONLY rule"
else
  fail "TC-S2: rules/state-ownership.md exists but missing APPEND-ONLY rule"
fi

# TC-S3: rules/state-ownership.md contains frontmatter update permissions table
echo ""
echo "TC-S3: rules/state-ownership.md contains frontmatter update permissions table"
if [ ! -f "$OWNERSHIP_FILE" ]; then
  fail "TC-S3: rules/state-ownership.md does not exist"
elif grep -qi "kickoff" "$OWNERSHIP_FILE" && grep -qi "green" "$OWNERSHIP_FILE"; then
  pass "TC-S3: rules/state-ownership.md contains permissions table with kickoff and green entries"
else
  fail "TC-S3: rules/state-ownership.md missing permissions table (kickoff and/or green entries not found)"
fi

# TC-S4: Cycle doc template contains complexity field in frontmatter
echo ""
echo "TC-S4: Cycle doc template contains complexity field in frontmatter"
CYCLE_TEMPLATE="$BASE_DIR/skills/spec/templates/cycle.md"
if [ ! -f "$CYCLE_TEMPLATE" ]; then
  fail "TC-S4: skills/spec/templates/cycle.md does not exist"
elif grep -q "complexity:" "$CYCLE_TEMPLATE"; then
  pass "TC-S4: Cycle doc template contains complexity: field"
else
  fail "TC-S4: Cycle doc template missing complexity: field"
fi

# TC-S5: Cycle doc template contains test_count field in frontmatter
echo ""
echo "TC-S5: Cycle doc template contains test_count field in frontmatter"
if [ ! -f "$CYCLE_TEMPLATE" ]; then
  fail "TC-S5: skills/spec/templates/cycle.md does not exist"
elif grep -q "test_count:" "$CYCLE_TEMPLATE"; then
  pass "TC-S5: Cycle doc template contains test_count: field"
else
  fail "TC-S5: Cycle doc template missing test_count: field"
fi

# TC-S6: Cycle doc template contains risk_level field in frontmatter
echo ""
echo "TC-S6: Cycle doc template contains risk_level field in frontmatter"
if [ ! -f "$CYCLE_TEMPLATE" ]; then
  fail "TC-S6: skills/spec/templates/cycle.md does not exist"
elif grep -q "risk_level:" "$CYCLE_TEMPLATE"; then
  pass "TC-S6: Cycle doc template contains risk_level: field"
else
  fail "TC-S6: Cycle doc template missing risk_level: field"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
