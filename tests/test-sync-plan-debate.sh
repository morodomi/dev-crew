#!/bin/bash
# test-sync-plan-debate.sh - Debate Protocol validation
# TC-01 through TC-09 (migrated from test-kickoff-debate.sh)

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
AGENT_MD="$BASE_DIR/agents/sync-plan.md"
ROADMAP="$BASE_DIR/ROADMAP.md"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== Sync-Plan Debate Protocol Tests ==="

# TC-01: sync-plan.md has Codex check and debate/fallback branching
echo ""
echo "TC-01: sync-plan.md Codex check and debate"
if grep -q "codex" "$AGENT_MD" && grep -qi "debate\|fallback" "$AGENT_MD"; then
  pass "TC-01: sync-plan.md has Codex check and fallback branching"
else
  fail "TC-01: sync-plan.md missing Codex check or fallback branching"
fi

# TC-02: sync-plan.md has Debate Workflow with subsections
echo ""
echo "TC-02: sync-plan.md Debate Workflow subsections"
has_workflow=false
has_round=false
has_clarification=false
has_recording=false
has_adr=false
if grep -q "## Debate Workflow" "$AGENT_MD"; then has_workflow=true; fi
if grep -q "Round Loop\|### Round" "$AGENT_MD"; then has_round=true; fi
if grep -q "Human Clarification" "$AGENT_MD"; then has_clarification=true; fi
if grep -q "Result Recording" "$AGENT_MD"; then has_recording=true; fi
if grep -q "ADR" "$AGENT_MD"; then has_adr=true; fi
if $has_workflow && $has_round && $has_clarification && $has_recording && $has_adr; then
  pass "TC-02: sync-plan.md has Debate Workflow with all 5 subsections"
else
  fail "TC-02: sync-plan.md missing Debate Workflow subsections (workflow=$has_workflow round=$has_round clarification=$has_clarification recording=$has_recording adr=$has_adr)"
fi

# TC-03: sync-plan.md codex exec commands include --full-auto
echo ""
echo "TC-03: codex exec with --full-auto"
if grep "codex exec" "$AGENT_MD" | grep -q "\-\-full-auto"; then
  pass "TC-03: codex exec commands include --full-auto"
else
  fail "TC-03: codex exec commands missing --full-auto flag"
fi

# TC-04: sync-plan.md has resume --last pattern
echo ""
echo "TC-04: resume --last pattern"
if grep -q "resume --last" "$AGENT_MD"; then
  pass "TC-04: sync-plan.md has resume --last pattern"
else
  fail "TC-04: sync-plan.md missing resume --last pattern"
fi

# TC-05: sync-plan.md has max 3 rounds convergence condition
echo ""
echo "TC-05: max 3 rounds convergence"
if grep -q "max 3\|3.*round" "$AGENT_MD"; then
  pass "TC-05: sync-plan.md has max 3 rounds convergence condition"
else
  fail "TC-05: sync-plan.md missing max 3 rounds convergence condition"
fi

# TC-06: sync-plan.md has ADR creation conditions
echo ""
echo "TC-06: ADR creation conditions"
has_conditions=false
if grep -q "複数サイクルに影響\|過去のADRを覆す\|Deferred判断" "$AGENT_MD"; then has_conditions=true; fi
if $has_conditions; then
  pass "TC-06: sync-plan.md has ADR creation conditions"
else
  fail "TC-06: sync-plan.md missing ADR creation conditions"
fi

# TC-07: ROADMAP.md Phase 2 status (kept for regression)
echo ""
echo "TC-07: ROADMAP Phase 2 status"
if grep -q "Phase 2.*DONE\|Phase 2.*in-progress\|Phase 2.*IN-PROGRESS\|Phase 2.*In Progress" "$ROADMAP"; then
  pass "TC-07: ROADMAP Phase 2 status updated"
else
  fail "TC-07: ROADMAP Phase 2 not marked as DONE or in-progress"
fi

# TC-08: sync-plan.md is a reasonably sized file
echo ""
echo "TC-08: sync-plan.md file exists and has content"
line_count=$(wc -l < "$AGENT_MD" | tr -d ' ')
if [ "$line_count" -gt 10 ]; then
  pass "TC-08: sync-plan.md is $line_count lines"
else
  fail "TC-08: sync-plan.md is only $line_count lines (too small)"
fi

# TC-09: sync-plan.md documents Codex absence handling
echo ""
echo "TC-09: Codex absence handling"
if grep -q "which codex\|利用可能.*確認\|不在" "$AGENT_MD"; then
  pass "TC-09: sync-plan.md documents Codex absence handling"
else
  fail "TC-09: sync-plan.md missing Codex absence handling"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
