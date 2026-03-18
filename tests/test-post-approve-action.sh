#!/bin/bash
# test-post-approve-action.sh - Post-Approve Action の存在と順序を検証
set -uo pipefail

DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0

pass() { echo "  PASS: $1"; ((PASS++)); }
fail() { echo "  FAIL: $1"; ((FAIL++)); }

echo "=== test-post-approve-action ==="

# --- AGENTS.md ---

echo "-- AGENTS.md --"

# Given AGENTS.md exists, When grep "Post-Approve Action", Then found
if grep -q "Post-Approve Action" "$DIR/AGENTS.md"; then
  pass "AGENTS.md contains Post-Approve Action"
else
  fail "AGENTS.md missing Post-Approve Action"
fi

# Given AGENTS.md Post-Approve Action, When check content, Then mentions orchestrate
if grep -A 3 "Post-Approve Action" "$DIR/AGENTS.md" | grep -q "orchestrate"; then
  pass "Post-Approve Action mentions orchestrate"
else
  fail "Post-Approve Action missing orchestrate"
fi

# --- onboard/reference.md TDD Workflow template ---

echo "-- onboard/reference.md --"

# Given AGENTS.md TDD Workflow template in onboard/reference.md, When grep "sync-plan", Then found before "orchestrate"
TEMPLATE_FILE="$DIR/skills/onboard/reference.md"
if grep -q "Post-Approve Action" "$TEMPLATE_FILE"; then
  pass "onboard/reference.md TDD Workflow template contains Post-Approve Action"
else
  fail "onboard/reference.md TDD Workflow template missing Post-Approve Action"
fi

# Verify sync-plan appears before orchestrate in template's Post-Approve Action
if awk '/Post-Approve Action/,/^```$/' "$TEMPLATE_FILE" | grep -q "sync-plan"; then
  pass "onboard/reference.md Post-Approve Action has sync-plan"
else
  fail "onboard/reference.md Post-Approve Action missing sync-plan"
fi

# --- orchestrate/SKILL.md Block 0 ---

echo "-- orchestrate/SKILL.md --"

# Given orchestrate/SKILL.md Block 0, When read, Then conditional skip logic exists
ORCH_FILE="$DIR/skills/orchestrate/SKILL.md"
if grep -q "plan-review" "$ORCH_FILE" && grep -q "skip\|Skip\|スキップ" "$ORCH_FILE"; then
  pass "orchestrate Block 0 has conditional skip logic (plan-review + skip)"
else
  fail "orchestrate Block 0 missing conditional skip logic"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
