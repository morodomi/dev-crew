#!/bin/bash
# test-architect-improvement.sh - architect agent prompt improvement validation
# TC-01 ~ TC-10

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ARCHITECT_FILE="$BASE_DIR/agents/architect.md"
PLAN_SKILL="$BASE_DIR/skills/plan/SKILL.md"
PLAN_REF="$BASE_DIR/skills/plan/reference.md"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== Architect Agent Improvement Tests ==="

########################################
# architect.md: Exploration phase
########################################

echo ""
echo "--- architect.md: Exploration Phase ---"

# TC-01: architect.md contains exploration step
echo ""
echo "TC-01: architect.md contains exploration step"
if grep -qi "探索\|Exploration\|Explore" "$ARCHITECT_FILE"; then
  pass "Exploration step found in architect.md"
else
  fail "Exploration step not found in architect.md"
fi

# TC-02: architect.md mentions reading at least 5 files
echo ""
echo "TC-02: architect.md mentions reading at least 5 files"
if grep -qE "最低.*5.*ファイル|at least 5|5.*files?\b" "$ARCHITECT_FILE"; then
  pass "5 files minimum found in architect.md"
else
  fail "5 files minimum not found in architect.md"
fi

# TC-03: architect.md Workflow has exploration before Skill(plan)
echo ""
echo "TC-03: Exploration before Skill(plan) in Workflow"
# Search only within Workflow section (after "## Workflow" heading)
workflow_start=$(grep -n "## Workflow" "$ARCHITECT_FILE" | head -1 | cut -d: -f1)
if [ -n "$workflow_start" ]; then
  explore_line=$(tail -n +"$workflow_start" "$ARCHITECT_FILE" | grep -n -i "探索\|Exploration" | head -1 | cut -d: -f1)
  skill_line=$(tail -n +"$workflow_start" "$ARCHITECT_FILE" | grep -n "Skill(.*plan)" | head -1 | cut -d: -f1)
  if [ -n "$explore_line" ] && [ -n "$skill_line" ] && [ "$explore_line" -lt "$skill_line" ]; then
    pass "Exploration before Skill(plan) in Workflow"
  else
    fail "Exploration not before Skill(plan) in Workflow (explore=$explore_line, skill=$skill_line)"
  fi
else
  fail "Workflow section not found in architect.md"
fi

########################################
# plan SKILL.md: Exploration + QA steps
########################################

echo ""
echo "--- plan SKILL.md: Exploration + QA ---"

# TC-04: plan SKILL.md contains exploration step
echo ""
echo "TC-04: plan SKILL.md contains exploration step"
if grep -qi "探索\|Exploration" "$PLAN_SKILL"; then
  pass "Exploration step found in plan SKILL.md"
else
  fail "Exploration step not found in plan SKILL.md"
fi

# TC-05: plan SKILL.md contains QA Question Asker step
echo ""
echo "TC-05: plan SKILL.md contains QA Question Asker step"
if grep -qi "QA.*Question\|Question Asker\|自問" "$PLAN_SKILL"; then
  pass "QA Question Asker step found in plan SKILL.md"
else
  fail "QA Question Asker step not found in plan SKILL.md"
fi

# TC-06: QA step heading comes before Test List step heading in Workflow
echo ""
echo "TC-06: QA step before Test List step"
# Match Step headings (### Step N:) to avoid matching within table text
qa_line=$(grep -n "### Step.*QA\|### Step.*自問" "$PLAN_SKILL" | head -1 | cut -d: -f1)
testlist_line=$(grep -n "### Step.*Test List" "$PLAN_SKILL" | head -1 | cut -d: -f1)
if [ -n "$qa_line" ] && [ -n "$testlist_line" ] && [ "$qa_line" -lt "$testlist_line" ]; then
  pass "QA step (line $qa_line) before Test List step (line $testlist_line)"
else
  fail "QA step not before Test List step (qa=$qa_line, testlist=$testlist_line)"
fi

########################################
# plan reference.md: QA section
########################################

echo ""
echo "--- plan reference.md: QA Section ---"

# TC-07: plan reference.md contains QA Question Asker section
echo ""
echo "TC-07: reference.md contains QA Question Asker section"
if grep -qi "QA.*Question\|Question Asker" "$PLAN_REF"; then
  pass "QA Question Asker section found in reference.md"
else
  fail "QA Question Asker section not found in reference.md"
fi

# TC-08: reference.md QA section has 4 questions
echo ""
echo "TC-08: reference.md QA section has 4 questions"
# Count lines starting with "- " or numbered list items within QA section
qa_start=$(grep -n -i "QA.*Question\|Question Asker" "$PLAN_REF" | head -1 | cut -d: -f1)
if [ -n "$qa_start" ]; then
  # Count question lines (lines containing "?" after the QA header)
  question_count=$(tail -n +"$qa_start" "$PLAN_REF" | grep -c '？\|?')
  if [ "$question_count" -ge 4 ]; then
    pass "QA section has $question_count questions (>= 4)"
  else
    fail "QA section has $question_count questions (expected >= 4)"
  fi
else
  fail "QA section not found, cannot count questions"
fi

########################################
# Structural validation
########################################

echo ""
echo "--- Structural validation ---"

# TC-09: plan SKILL.md still under 100 lines
echo ""
echo "TC-09: plan SKILL.md <= 100 lines"
line_count=$(wc -l < "$PLAN_SKILL" | tr -d ' ')
if [ "$line_count" -le 100 ]; then
  pass "plan SKILL.md: $line_count lines"
else
  fail "plan SKILL.md: $line_count lines (max 100)"
fi

# TC-10: Existing structure validation still passes
echo ""
echo "TC-10: Existing structure validation"
if bash "$BASE_DIR/tests/test-skills-structure.sh" > /dev/null 2>&1; then
  pass "Structure validation passes"
else
  fail "Structure validation failed"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
