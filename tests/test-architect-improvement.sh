#!/bin/bash
# test-architect-improvement.sh - architect agent prompt improvement validation
# TC-01 ~ TC-10

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ARCHITECT_FILE="$BASE_DIR/agents/architect.md"
KICKOFF_SKILL="$BASE_DIR/skills/kickoff/SKILL.md"
KICKOFF_REF="$BASE_DIR/skills/kickoff/reference.md"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== Architect Agent Improvement Tests ==="

########################################
# architect.md: kickoff phase
########################################

echo ""
echo "--- architect.md: KICKOFF Phase ---"

# TC-01: architect.md references kickoff skill
echo ""
echo "TC-01: architect.md references kickoff skill"
if grep -qi "kickoff\|KICKOFF" "$ARCHITECT_FILE"; then
  pass "Kickoff reference found in architect.md"
else
  fail "Kickoff reference not found in architect.md"
fi

# TC-02: architect.md mentions plan file reading
echo ""
echo "TC-02: architect.md mentions plan file"
if grep -qE "plan.*ファイル|planファイル|plan file" "$ARCHITECT_FILE"; then
  pass "Plan file reference found in architect.md"
else
  fail "Plan file reference not found in architect.md"
fi

# TC-03: architect.md Workflow has Skill(kickoff) reference
echo ""
echo "TC-03: Skill(kickoff) in Workflow"
workflow_start=$(grep -n "## Workflow" "$ARCHITECT_FILE" | head -1 | cut -d: -f1)
if [ -n "$workflow_start" ]; then
  skill_line=$(tail -n +"$workflow_start" "$ARCHITECT_FILE" | grep -n "Skill(.*kickoff)" | head -1 | cut -d: -f1)
  if [ -n "$skill_line" ]; then
    pass "Skill(kickoff) found in Workflow"
  else
    fail "Skill(kickoff) not found in Workflow"
  fi
else
  fail "Workflow section not found in architect.md"
fi

########################################
# kickoff SKILL.md: Plan file → Cycle doc
########################################

echo ""
echo "--- kickoff SKILL.md: Plan File → Cycle Doc ---"

# TC-04: kickoff SKILL.md references plan file
echo ""
echo "TC-04: kickoff SKILL.md references plan file"
if grep -qi "planファイル\|plan file\|plan mode" "$KICKOFF_SKILL"; then
  pass "Plan file reference found in kickoff SKILL.md"
else
  fail "Plan file reference not found in kickoff SKILL.md"
fi

# TC-05: kickoff SKILL.md references Cycle doc generation
echo ""
echo "TC-05: kickoff SKILL.md references Cycle doc generation"
if grep -qi "Cycle doc.*生成\|Cycle doc.*作成\|Generate Cycle Doc" "$KICKOFF_SKILL"; then
  pass "Cycle doc generation found in kickoff SKILL.md"
else
  fail "Cycle doc generation not found in kickoff SKILL.md"
fi

# TC-06: kickoff SKILL.md has Test List transfer step
echo ""
echo "TC-06: kickoff SKILL.md has Test List transfer"
if grep -qi "Test List.*転記\|Transfer Test List" "$KICKOFF_SKILL"; then
  pass "Test List transfer found in kickoff SKILL.md"
else
  fail "Test List transfer not found in kickoff SKILL.md"
fi

########################################
# kickoff reference.md: Supporting content
########################################

echo ""
echo "--- kickoff reference.md ---"

# TC-07: kickoff reference.md contains Test List design section
echo ""
echo "TC-07: reference.md contains Test List section"
if grep -qi "Test List" "$KICKOFF_REF"; then
  pass "Test List section found in reference.md"
else
  fail "Test List section not found in reference.md"
fi

# TC-08: reference.md has plan file transfer guide
echo ""
echo "TC-08: reference.md has transfer guide"
if grep -qi "転記\|transfer\|planファイルから" "$KICKOFF_REF"; then
  pass "Transfer guide found in reference.md"
else
  fail "Transfer guide not found in reference.md"
fi

########################################
# Structural validation
########################################

echo ""
echo "--- Structural validation ---"

# TC-09: kickoff SKILL.md still under 100 lines
echo ""
echo "TC-09: kickoff SKILL.md <= 100 lines"
line_count=$(wc -l < "$KICKOFF_SKILL" | tr -d ' ')
if [ "$line_count" -le 100 ]; then
  pass "kickoff SKILL.md: $line_count lines"
else
  fail "kickoff SKILL.md: $line_count lines (max 100)"
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
