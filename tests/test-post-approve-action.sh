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

# Verify Post-Approve Action delegates to orchestrate (not direct sync-plan call)
if awk '/Post-Approve Action/,/^```$/' "$TEMPLATE_FILE" | grep -q "/orchestrate"; then
  pass "onboard/reference.md Post-Approve Action delegates to /orchestrate"
else
  fail "onboard/reference.md Post-Approve Action missing /orchestrate delegation"
fi

# Verify Post-Approve Action does NOT instruct direct sync-plan call
if awk '/Post-Approve Action/,/^```$/' "$TEMPLATE_FILE" | grep -q 'dev-crew:sync-plan)'; then
  fail "onboard/reference.md Post-Approve Action still has direct sync-plan call"
else
  pass "onboard/reference.md Post-Approve Action has no direct sync-plan call"
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

# --- Constitution Check in spec ---

echo "-- spec constitution check --"

# Given spec SKILL.md, When check Step 7.1, Then mentions Constitution
if grep -q "Constitution" "$DIR/skills/spec/SKILL.md"; then
  pass "spec SKILL.md mentions Constitution check"
else
  fail "spec SKILL.md missing Constitution check"
fi

# Given spec reference.md, When check, Then has constitution-check section
if grep -q "constitution-check" "$DIR/skills/spec/reference.md"; then
  pass "spec reference.md has constitution-check section"
else
  fail "spec reference.md missing constitution-check section"
fi

# --- Constitution Check in design-reviewer ---

echo "-- design-reviewer constitution check --"

# Given design-reviewer.md, When check Focus, Then includes constitution
if grep -qi "constitution" "$DIR/agents/design-reviewer.md"; then
  pass "design-reviewer includes constitution in Focus"
else
  fail "design-reviewer missing constitution in Focus"
fi

# Given design-reviewer.md output, When check categories, Then includes constitution
if grep -q "constitution" "$DIR/agents/design-reviewer.md"; then
  pass "design-reviewer output has constitution category"
else
  fail "design-reviewer output missing constitution category"
fi

# --- Socrates Plan Review (Codex不在時) ---

echo "-- socrates plan review --"

# Given orchestrate SKILL.md Block 1, When check, Then mentions Socrates for Codex absent
if grep -q "Socrates" "$DIR/skills/orchestrate/SKILL.md" && grep -q "Codex不在" "$DIR/skills/orchestrate/SKILL.md"; then
  pass "orchestrate Block 1 has Socrates for Codex absent"
else
  fail "orchestrate Block 1 missing Socrates for Codex absent"
fi

# Given orchestrate reference.md, When check, Then has socrates-plan-review section
if grep -q "socrates-plan-review" "$DIR/skills/orchestrate/reference.md"; then
  pass "orchestrate reference.md has socrates-plan-review section"
else
  fail "orchestrate reference.md missing socrates-plan-review section"
fi

# Given orchestrate reference.md socrates section, When check, Then mentions CONSTITUTION
if grep -A 20 "socrates-plan-review" "$DIR/skills/orchestrate/reference.md" | grep -q "CONSTITUTION"; then
  pass "socrates plan review references CONSTITUTION"
else
  fail "socrates plan review missing CONSTITUTION reference"
fi

# TC-NEW-01: sync-plan.md description に「Skill()不可」が記載されている
echo "-- sync-plan description --"
if grep -q 'Skill().*不可\|直接呼び出し不可' "$DIR/agents/sync-plan.md"; then
  pass "sync-plan.md description has Skill() prohibition"
else
  fail "sync-plan.md description missing Skill() prohibition"
fi

# TC-NEW-02: post-approve.md に sync-plan 直接呼び出し禁止が記載
echo "-- post-approve prohibition --"
RULE_FILE="$DIR/.claude/rules/post-approve.md"
if grep -q 'Skill(dev-crew:sync-plan)' "$RULE_FILE" && grep -q '禁止' "$RULE_FILE"; then
  pass "post-approve.md has sync-plan direct call prohibition"
else
  fail "post-approve.md missing sync-plan direct call prohibition"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
