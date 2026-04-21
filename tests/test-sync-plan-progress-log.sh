#!/bin/bash
# test-sync-plan-progress-log.sh - sync-plan agent and cycle template Progress Log format spec
# TC-01: sync-plan.md has ## Progress Log Format section with PHASE pattern spec
# TC-02: sync-plan.md contains pre-commit-gate compatibility wording
# TC-03: sync-plan.md Frontmatter Initialization phase default = KICKOFF (not RED)
# TC-04: cycle.md template Progress Log example uses KICKOFF (not INIT)
# TC-05: cycle.md template Progress Log format spec has strong required/strict wording

set -uo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

SYNC_PLAN="$BASE_DIR/agents/sync-plan.md"
TEMPLATE="$BASE_DIR/skills/spec/templates/cycle.md"

echo "=== sync-plan Progress Log Format Tests ==="

# TC-01: sync-plan.md has ## Progress Log Format section with PHASE pattern spec
echo ""
echo "TC-01: sync-plan.md has Progress Log Format section with PHASE pattern spec"
if [ ! -f "$SYNC_PLAN" ]; then
  fail "TC-01: agents/sync-plan.md does not exist"
elif grep -q "^## Progress Log Format" "$SYNC_PLAN" && \
     grep -q "### YYYY-MM-DD HH:MM - PHASE" "$SYNC_PLAN"; then
  pass "TC-01: sync-plan.md has Progress Log Format section with PHASE pattern spec"
else
  fail "TC-01: sync-plan.md does NOT have Progress Log Format section or PHASE pattern spec"
fi

# TC-02: sync-plan.md contains pre-commit-gate compatibility wording
echo ""
echo "TC-02: sync-plan.md contains pre-commit-gate compatibility wording"
if [ ! -f "$SYNC_PLAN" ]; then
  fail "TC-02: agents/sync-plan.md does not exist"
elif grep -qE "pre-commit-gate|互換" "$SYNC_PLAN"; then
  pass "TC-02: sync-plan.md contains pre-commit-gate compatibility wording"
else
  fail "TC-02: sync-plan.md does NOT contain pre-commit-gate or 互換 wording"
fi

# TC-03: sync-plan.md Frontmatter Initialization phase default = KICKOFF (not RED)
echo ""
echo "TC-03: sync-plan.md Frontmatter Initialization phase default = KICKOFF (not RED)"
if [ ! -f "$SYNC_PLAN" ]; then
  fail "TC-03: agents/sync-plan.md does not exist"
else
  phase_line="$(grep "^| phase |" "$SYNC_PLAN" || true)"
  if [ -z "$phase_line" ]; then
    fail "TC-03: sync-plan.md has no '| phase |' row in Frontmatter Initialization table"
  elif echo "$phase_line" | grep -q "KICKOFF" && ! echo "$phase_line" | grep -q "RED"; then
    pass "TC-03: sync-plan.md phase default = KICKOFF (RED not present in phase row)"
  else
    fail "TC-03: sync-plan.md phase row does not match expected (KICKOFF required, RED must be absent): '$phase_line'"
  fi
fi

# TC-04: cycle.md template Progress Log example uses KICKOFF (not INIT)
echo ""
echo "TC-04: cycle.md template Progress Log example uses KICKOFF (not INIT)"
if [ ! -f "$TEMPLATE" ]; then
  fail "TC-04: skills/spec/templates/cycle.md does not exist"
elif grep -q "### YYYY-MM-DD HH:MM - KICKOFF" "$TEMPLATE" && \
     ! grep -q "### YYYY-MM-DD HH:MM - INIT" "$TEMPLATE"; then
  pass "TC-04: cycle.md template uses KICKOFF example and INIT example is absent"
else
  fail "TC-04: cycle.md template KICKOFF example missing or INIT example still present"
fi

# TC-05: cycle.md template Progress Log format spec has strong required/strict wording
echo ""
echo "TC-05: cycle.md template Progress Log format spec has strong required/strict wording"
if [ ! -f "$TEMPLATE" ]; then
  fail "TC-05: skills/spec/templates/cycle.md does not exist"
else
  # Extract the Progress Log section (up to next --- or end of file)
  progress_log_section="$(awk '/^## Progress Log$/,/^---$/' "$TEMPLATE")"
  if echo "$progress_log_section" | grep -qE "strict|required|pre-commit-gate"; then
    pass "TC-05: cycle.md Progress Log format spec contains strong wording (strict/required/pre-commit-gate)"
  else
    fail "TC-05: cycle.md Progress Log format spec lacks strong wording (strict/required/pre-commit-gate not found)"
  fi
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
