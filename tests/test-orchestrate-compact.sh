#!/bin/bash
# test-orchestrate-compact.sh - orchestrate phase-compact integration validation
# TC-01 ~ TC-14

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEAMS_FILE="$BASE_DIR/skills/orchestrate/steps-teams.md"
SUBAGENT_FILE="$BASE_DIR/skills/orchestrate/steps-subagent.md"
SKILL_FILE="$BASE_DIR/skills/orchestrate/SKILL.md"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

# Helper: check that pattern exists between two section markers in a file
# Usage: between_sections FILE START_PATTERN END_PATTERN SEARCH_PATTERN
between_sections() {
  local file="$1" start="$2" end="$3" search="$4"
  awk "/$start/,/$end/" "$file" | grep -q "$search"
}

echo "=== Orchestrate Phase-Compact Integration Tests ==="

########################################
# steps-teams.md: Phase Summary persistence
########################################

echo ""
echo "--- steps-teams.md: Phase Summary ---"

# TC-01: PLAN->RED Phase Summary
echo ""
echo "TC-01: PLAN->RED Phase Summary persistence"
if between_sections "$TEAMS_FILE" "### PLAN" "### RED" "Phase Summary" 2>/dev/null || \
   between_sections "$TEAMS_FILE" "review.*plan" "### RED" "Phase Summary" 2>/dev/null; then
  pass "PLAN->RED Phase Summary found"
else
  fail "PLAN->RED Phase Summary not found"
fi

# TC-02: RED->GREEN Phase Summary
echo ""
echo "TC-02: RED->GREEN Phase Summary persistence"
if between_sections "$TEAMS_FILE" "### RED" "### GREEN" "Phase Summary" 2>/dev/null; then
  pass "RED->GREEN Phase Summary found"
else
  fail "RED->GREEN Phase Summary not found"
fi

# TC-03: GREEN->/simplify Phase Summary
echo ""
echo "TC-03: GREEN->/simplify Phase Summary persistence"
if between_sections "$TEAMS_FILE" "### GREEN" "### .simplify" "Phase Summary" 2>/dev/null || \
   between_sections "$TEAMS_FILE" "### GREEN" "simplify" "Phase Summary" 2>/dev/null; then
  pass "GREEN->/simplify Phase Summary found"
else
  fail "GREEN->/simplify Phase Summary not found"
fi

# TC-04: /simplify->REVIEW Phase Summary
echo ""
echo "TC-04: /simplify->REVIEW Phase Summary persistence"
if grep -q "Phase Summary.*simplify.*REVIEW\|simplify→REVIEW" "$TEAMS_FILE" 2>/dev/null; then
  pass "/simplify->REVIEW Phase Summary found"
else
  fail "/simplify->REVIEW Phase Summary not found"
fi

# TC-05: REVIEW->COMMIT Phase Summary
echo ""
echo "TC-05: REVIEW->COMMIT Phase Summary persistence"
if between_sections "$TEAMS_FILE" "### REVIEW" "### COMMIT\|## Phase 4" "Phase Summary" 2>/dev/null; then
  pass "REVIEW->COMMIT Phase Summary found"
else
  fail "REVIEW->COMMIT Phase Summary not found"
fi

# TC-06: No Phase Summary after COMMIT (negative test)
echo ""
echo "TC-06: No Phase Summary after COMMIT"
# Extract from COMMIT section to end of file, check no Phase Summary persistence instruction
commit_section=$(awk '/### COMMIT/,0' "$TEAMS_FILE" 2>/dev/null || true)
if [ -n "$commit_section" ]; then
  if echo "$commit_section" | grep -q "Phase Summary.*Cycle doc\|Phase Summary.*永続化\|Phase Summary.*persist"; then
    fail "Phase Summary found after COMMIT (should not exist)"
  else
    pass "No Phase Summary after COMMIT"
  fi
else
  fail "COMMIT section not found in steps-teams.md"
fi

# TC-07: Subagent line (agent_id, tokens) in Phase Summary
echo ""
echo "TC-07: Subagent line in Phase Summary format"
if grep -q "agent_id\|tokens" "$TEAMS_FILE" 2>/dev/null && \
   grep -q "Subagent" "$TEAMS_FILE" 2>/dev/null; then
  pass "Subagent line (agent_id, tokens) found"
else
  fail "Subagent line (agent_id, tokens) not found"
fi

########################################
# steps-subagent.md: Task() delegation + context isolation
########################################

echo ""
echo "--- steps-subagent.md: Task() delegation ---"

# TC-08: Block1 uses Task() delegation (not direct Skill())
echo ""
echo "TC-08: Block1 Task() delegation"
block1=$(awk '/## Block 1/,/## Block 2/' "$SUBAGENT_FILE" 2>/dev/null || true)
if [ -n "$block1" ]; then
  if echo "$block1" | grep -q "Task("; then
    pass "Block1 uses Task() delegation"
  else
    fail "Block1 does not use Task() delegation"
  fi
else
  fail "Block 1 section not found"
fi

# TC-09: Block2 uses Task() delegation
echo ""
echo "TC-09: Block2 Task() delegation"
block2=$(awk '/## Block 2/,/## Block 3/' "$SUBAGENT_FILE" 2>/dev/null || true)
if [ -n "$block2" ]; then
  if echo "$block2" | grep -q "Task("; then
    pass "Block2 uses Task() delegation"
  else
    fail "Block2 does not use Task() delegation"
  fi
else
  fail "Block 2 section not found"
fi

# TC-10: Block1->Block2 Phase Summary persistence
echo ""
echo "TC-10: Block1->Block2 Phase Summary persistence"
# Phase Summary should appear between Block 1 and Block 2
if between_sections "$SUBAGENT_FILE" "## Block 1" "## Block 2" "Phase Summary" 2>/dev/null || \
   between_sections "$SUBAGENT_FILE" "Block 1" "Block 2" "Phase Summary" 2>/dev/null; then
  pass "Block1->Block2 Phase Summary found"
else
  fail "Block1->Block2 Phase Summary not found"
fi

# TC-11: Block2->Block3 Phase Summary persistence
echo ""
echo "TC-11: Block2->Block3 Phase Summary persistence"
if between_sections "$SUBAGENT_FILE" "## Block 2" "## Block 3" "Phase Summary" 2>/dev/null || \
   between_sections "$SUBAGENT_FILE" "Block 2" "Block 3" "Phase Summary" 2>/dev/null; then
  pass "Block2->Block3 Phase Summary found"
else
  fail "Block2->Block3 Phase Summary not found"
fi

# TC-12: Subagent line (agent_id, tokens) in steps-subagent.md
echo ""
echo "TC-12: Subagent line in Phase Summary format (subagent mode)"
if grep -q "agent_id\|tokens" "$SUBAGENT_FILE" 2>/dev/null && \
   grep -q "Subagent" "$SUBAGENT_FILE" 2>/dev/null; then
  pass "Subagent line (agent_id, tokens) found"
else
  fail "Subagent line (agent_id, tokens) not found"
fi

########################################
# Structure validation
########################################

echo ""
echo "--- Structure validation ---"

# TC-13: SKILL.md under 100 lines
echo ""
echo "TC-13: SKILL.md <= 100 lines"
if [ -f "$SKILL_FILE" ]; then
  line_count=$(wc -l < "$SKILL_FILE" | tr -d ' ')
  if [ "$line_count" -le 100 ]; then
    pass "SKILL.md: $line_count lines"
  else
    fail "SKILL.md: $line_count lines (max 100)"
  fi
else
  fail "SKILL.md not found"
fi

# TC-14: Existing structure validation passes
echo ""
echo "TC-14: Existing structure validation"
if bash "$BASE_DIR/tests/test-skills-structure.sh" > /dev/null 2>&1; then
  pass "Structure validation passes"
else
  fail "Structure validation failed"
fi

########################################
# steps-teams.md: Socrates on-demand
########################################

echo ""
echo "--- steps-teams.md: Socrates on-demand ---"

# TC-15: Phase 1 should NOT have socrates permanent spawn
echo ""
echo "TC-15: No socrates permanent spawn in Phase 1"
phase1=$(awk '/## Phase 1/,/## Phase 2/' "$TEAMS_FILE" 2>/dev/null || true)
if [ -n "$phase1" ]; then
  # Phase 1 should not contain socrates spawn with team_name
  if echo "$phase1" | grep -qi 'socrates.*常駐\|常駐.*socrates\|name:.*"socrates".*team_name'; then
    fail "Socrates permanent spawn found in Phase 1 (should be on-demand)"
  else
    pass "No socrates permanent spawn in Phase 1"
  fi
else
  fail "Phase 1 section not found"
fi

# TC-16: Socrates Protocol uses Task() for on-demand spawn (not SendMessage to pre-existing teammate)
echo ""
echo "TC-16: Socrates Protocol uses Task() for on-demand spawn"
# Extract Socrates Protocol sections and check for Task() with socrates
socrates_protocol=$(awk '/#### Socrates Protocol/,/^###[^#]/' "$TEAMS_FILE" 2>/dev/null || true)
if [ -n "$socrates_protocol" ]; then
  if echo "$socrates_protocol" | grep -q 'Task(.*socrates\|subagent_type.*socrates'; then
    pass "Socrates Protocol uses Task() for on-demand spawn"
  else
    fail "Socrates Protocol does not use Task() for on-demand spawn"
  fi
else
  fail "Socrates Protocol sections not found"
fi

# TC-17: Team Cleanup should NOT reference socrates shutdown
echo ""
echo "TC-17: No socrates shutdown in Team Cleanup"
cleanup_section=$(awk '/### Team Cleanup/,0' "$TEAMS_FILE" 2>/dev/null || true)
if [ -n "$cleanup_section" ]; then
  if echo "$cleanup_section" | grep -qi 'shutdown.*socrates\|socrates.*shutdown'; then
    fail "Socrates shutdown found in Team Cleanup (should not exist for on-demand)"
  else
    pass "No socrates shutdown in Team Cleanup"
  fi
else
  fail "Team Cleanup section not found"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
