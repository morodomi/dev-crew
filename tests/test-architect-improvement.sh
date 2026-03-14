#!/bin/bash
# test-architect-improvement.sh - architect agent prompt improvement validation
# TC-01 ~ TC-10

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ARCHITECT_FILE="$BASE_DIR/agents/architect.md"
SYNC_PLAN="$BASE_DIR/agents/sync-plan.md"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== Architect Agent Improvement Tests ==="

########################################
# architect.md: sync-plan phase
########################################

echo ""
echo "--- architect.md: sync-plan ---"

# TC-01: architect.md references sync-plan
echo ""
echo "TC-01: architect.md references sync-plan"
if grep -qi "sync-plan" "$ARCHITECT_FILE"; then
  pass "sync-plan reference found in architect.md"
else
  fail "sync-plan reference not found in architect.md"
fi

# TC-02: architect.md mentions plan file reading
echo ""
echo "TC-02: architect.md mentions plan file"
if grep -qE "plan.*ファイル|planファイル|plan file" "$ARCHITECT_FILE"; then
  pass "Plan file reference found in architect.md"
else
  fail "Plan file reference not found in architect.md"
fi

# TC-03: architect.md Workflow has Task(sync-plan) reference
echo ""
echo "TC-03: Task(sync-plan) in Workflow"
workflow_start=$(grep -n "## Workflow" "$ARCHITECT_FILE" | head -1 | cut -d: -f1)
if [ -n "$workflow_start" ]; then
  task_line=$(tail -n +"$workflow_start" "$ARCHITECT_FILE" | grep -n "Task(.*sync-plan)" | head -1 | cut -d: -f1)
  if [ -n "$task_line" ]; then
    pass "Task(sync-plan) found in Workflow"
  else
    fail "Task(sync-plan) not found in Workflow"
  fi
else
  fail "Workflow section not found in architect.md"
fi

########################################
# sync-plan agent: Plan file → Cycle doc
########################################

echo ""
echo "--- sync-plan agent: Plan File → Cycle Doc ---"

# TC-04: sync-plan.md references plan file
echo ""
echo "TC-04: sync-plan.md references plan file"
if grep -qi "planファイル\|plan file\|plan mode" "$SYNC_PLAN"; then
  pass "Plan file reference found in sync-plan.md"
else
  fail "Plan file reference not found in sync-plan.md"
fi

# TC-05: sync-plan.md references Cycle doc generation
echo ""
echo "TC-05: sync-plan.md references Cycle doc generation"
if grep -qi "Cycle doc.*生成\|Cycle doc.*作成\|Generate Cycle Doc" "$SYNC_PLAN"; then
  pass "Cycle doc generation found in sync-plan.md"
else
  fail "Cycle doc generation not found in sync-plan.md"
fi

# TC-06: sync-plan.md has Test List transfer step
echo ""
echo "TC-06: sync-plan.md has Test List transfer"
if grep -qi "Test List.*転記\|Transfer Test List" "$SYNC_PLAN"; then
  pass "Test List transfer found in sync-plan.md"
else
  fail "Test List transfer not found in sync-plan.md"
fi

########################################
# sync-plan.md: Supporting content
########################################

echo ""
echo "--- sync-plan.md supporting content ---"

# TC-07: sync-plan.md contains Test List design section
echo ""
echo "TC-07: sync-plan.md contains Test List section"
if grep -qi "Test List" "$SYNC_PLAN"; then
  pass "Test List section found in sync-plan.md"
else
  fail "Test List section not found in sync-plan.md"
fi

# TC-08: sync-plan.md has plan file transfer guide
echo ""
echo "TC-08: sync-plan.md has transfer guide"
if grep -qi "転記\|transfer\|planファイルから" "$SYNC_PLAN"; then
  pass "Transfer guide found in sync-plan.md"
else
  fail "Transfer guide not found in sync-plan.md"
fi

########################################
# Structural validation
########################################

echo ""
echo "--- Structural validation ---"

# TC-09: sync-plan.md exists with proper frontmatter
echo ""
echo "TC-09: sync-plan.md has proper frontmatter"
if grep -q "^name: sync-plan" "$SYNC_PLAN" && grep -q "^model:" "$SYNC_PLAN"; then
  pass "sync-plan.md has proper frontmatter"
else
  fail "sync-plan.md missing proper frontmatter"
fi

# TC-10: Existing structure validation still passes (excluding pre-existing commit issue)
echo ""
echo "TC-10: Skill structure validation"
# Check all skills have SKILL.md and frontmatter
all_have_skill=true
for dir in "$BASE_DIR/skills"/*/; do
  if [ ! -f "$dir/SKILL.md" ]; then
    all_have_skill=false
    fail "Missing SKILL.md in $(basename "$dir")"
  fi
done
if $all_have_skill; then
  pass "All skill directories have SKILL.md"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
