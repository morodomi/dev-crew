#!/bin/bash
# test-decision-records.sh - Decision Records (Phase 5) validation
# TC-01 through TC-12

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DECISIONS_DIR="$BASE_DIR/docs/decisions"
TEMPLATE="$DECISIONS_DIR/TEMPLATE.md"
SYNC_PLAN="$BASE_DIR/agents/sync-plan.md"
ORCHESTRATE_REF="$BASE_DIR/skills/orchestrate/reference.md"
ROADMAP="$BASE_DIR/ROADMAP.md"
AGENTS_MD="$BASE_DIR/AGENTS.md"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== Decision Records (Phase 5) Tests ==="

# TC-01: docs/decisions/ directory exists
echo ""
echo "TC-01: docs/decisions/ directory exists"
if [ -d "$DECISIONS_DIR" ]; then
  pass "TC-01: docs/decisions/ directory exists"
else
  fail "TC-01: docs/decisions/ directory does not exist"
fi

# TC-02: docs/decisions/TEMPLATE.md exists
echo ""
echo "TC-02: TEMPLATE.md exists"
if [ -f "$TEMPLATE" ]; then
  pass "TC-02: TEMPLATE.md exists"
else
  fail "TC-02: TEMPLATE.md does not exist"
fi

# TC-03: TEMPLATE.md has Decision Scorecard section
echo ""
echo "TC-03: TEMPLATE.md Decision Scorecard"
if [ -f "$TEMPLATE" ] && grep -q "## Decision Scorecard" "$TEMPLATE"; then
  pass "TC-03: TEMPLATE.md has Decision Scorecard section"
else
  fail "TC-03: TEMPLATE.md missing Decision Scorecard section"
fi

# TC-04: TEMPLATE.md has Arguments with Accepted/Rejected/Deferred
echo ""
echo "TC-04: TEMPLATE.md Arguments subsections"
if [ -f "$TEMPLATE" ] && grep -q "## Arguments" "$TEMPLATE" && grep -q "### Accepted" "$TEMPLATE" && grep -q "### Rejected" "$TEMPLATE" && grep -q "### Deferred" "$TEMPLATE"; then
  pass "TC-04: TEMPLATE.md has Arguments with Accepted/Rejected/Deferred"
else
  fail "TC-04: TEMPLATE.md missing Arguments subsections"
fi

# TC-05: sync-plan.md references ADR decisions
echo ""
echo "TC-05: sync-plan.md references ADR"
if grep -q "ADR" "$SYNC_PLAN" && grep -q "docs/decisions" "$SYNC_PLAN"; then
  pass "TC-05: sync-plan.md references ADR decisions"
else
  fail "TC-05: sync-plan.md does not reference ADR decisions"
fi

# TC-06: orchestrate/reference.md has ADR Reference section
echo ""
echo "TC-06: orchestrate/reference.md ADR Reference"
if grep -q "## ADR Reference" "$ORCHESTRATE_REF"; then
  pass "TC-06: orchestrate/reference.md has ADR Reference section"
else
  fail "TC-06: orchestrate/reference.md missing ADR Reference section"
fi

# TC-07: ROADMAP.md Phase 5 marked DONE
echo ""
echo "TC-07: ROADMAP Phase 5 status"
if grep -q "Phase 5.*DONE\|Phase 5.*Decision Records.*(DONE)" "$ROADMAP"; then
  pass "TC-07: ROADMAP Phase 5 marked DONE"
else
  fail "TC-07: ROADMAP Phase 5 not marked DONE"
fi

# TC-08: TEMPLATE.md has Status line with accepted/rejected/deferred
echo ""
echo "TC-08: TEMPLATE.md Status line"
if [ -f "$TEMPLATE" ] && grep -q "## Status:" "$TEMPLATE" && grep -q "accepted" "$TEMPLATE" && grep -q "rejected" "$TEMPLATE" && grep -q "deferred" "$TEMPLATE"; then
  pass "TC-08: TEMPLATE.md has Status line with accepted/rejected/deferred"
else
  fail "TC-08: TEMPLATE.md missing Status line variants"
fi

# TC-09: sync-plan.md retains ADR creation conditions (3 triggers)
echo ""
echo "TC-09: sync-plan.md ADR creation conditions"
has_multi_cycle=false
has_override=false
has_deferred=false
if grep -q "複数サイクルに影響" "$SYNC_PLAN"; then has_multi_cycle=true; fi
if grep -q "過去のADRを覆す" "$SYNC_PLAN"; then has_override=true; fi
if grep -q "人間がDeferred判断" "$SYNC_PLAN"; then has_deferred=true; fi
if $has_multi_cycle && $has_override && $has_deferred; then
  pass "TC-09: sync-plan.md retains all 3 ADR creation conditions"
else
  fail "TC-09: sync-plan.md missing ADR creation conditions (multi=$has_multi_cycle override=$has_override deferred=$has_deferred)"
fi

# TC-10: TEMPLATE.md has Context, Decision, Consequences sections
echo ""
echo "TC-10: TEMPLATE.md Context/Decision/Consequences"
if [ -f "$TEMPLATE" ] && grep -q "## Context" "$TEMPLATE" && grep -q "## Decision$" "$TEMPLATE" && grep -q "## Consequences" "$TEMPLATE"; then
  pass "TC-10: TEMPLATE.md has Context/Decision/Consequences sections"
else
  fail "TC-10: TEMPLATE.md missing Context/Decision/Consequences sections"
fi

# TC-11: Regression - existing sync-plan debate tests still pass
echo ""
echo "TC-11: Regression test-sync-plan-debate.sh"
if bash "$BASE_DIR/tests/test-sync-plan-debate.sh" > /dev/null 2>&1; then
  pass "TC-11: test-sync-plan-debate.sh passes (regression OK)"
else
  fail "TC-11: test-sync-plan-debate.sh failed (regression)"
fi

# TC-12: AGENTS.md mentions decisions (ADR) in Project Structure
echo ""
echo "TC-12: AGENTS.md Project Structure mentions decisions"
if grep -q "decisions (ADR)" "$AGENTS_MD"; then
  pass "TC-12: AGENTS.md Project Structure mentions decisions (ADR)"
else
  fail "TC-12: AGENTS.md Project Structure missing decisions (ADR)"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
