#!/bin/bash
# test-review-plan-gate.sh - Block 0 decision tree + review plan mode gate
# TC-01 ~ TC-10

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REVIEW="$BASE_DIR/skills/review/SKILL.md"
ORCH_SKILL="$BASE_DIR/skills/orchestrate/SKILL.md"
ORCH_SUB="$BASE_DIR/skills/orchestrate/steps-subagent.md"
ORCH_TEAMS="$BASE_DIR/skills/orchestrate/steps-teams.md"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

for f in "$REVIEW" "$ORCH_SKILL" "$ORCH_SUB" "$ORCH_TEAMS"; do
  [ -f "$f" ] || { echo "FATAL: $f not found"; exit 1; }
done

echo "=== Block 0 Decision Tree + Review Plan Gate Tests ==="

########################################
# Block 0 decision tree: Plan file first
########################################

echo ""
echo "--- Block 0: Plan file first decision tree ---"

# TC-01: orchestrate/SKILL.md Block 0 checks Plan file BEFORE cycle doc
echo ""
echo "TC-01: SKILL.md Block 0 checks Plan file first"
plan_line=$(grep -n -i "plan.*file\|planファイル\|Plan ファイル" "$ORCH_SKILL" | head -1 | cut -d: -f1 || true)
cycle_line=$(grep -n -i "未完了.*cycle\|cycle.*doc.*未完了\|in-progress\|phase.*DONE" "$ORCH_SKILL" | head -1 | cut -d: -f1 || true)
if [ -n "$plan_line" ] && [ -n "$cycle_line" ] && [ "$plan_line" -lt "$cycle_line" ]; then
  pass "TC-01: Plan file checked before cycle doc"
else
  fail "TC-01: Plan file not checked before cycle doc (plan=${plan_line:-none}, cycle=${cycle_line:-none})"
fi

# TC-02: steps-subagent.md Block 0 checks Plan file first
echo ""
echo "TC-02: steps-subagent.md Block 0 checks Plan file first"
block0_sub=$(awk '/## Block 0/,/## Block 1/' "$ORCH_SUB" 2>/dev/null || true)
plan_pos=$(echo "$block0_sub" | grep -n -i "plan.*file\|planファイル\|Plan ファイル" 2>/dev/null | head -1 | cut -d: -f1 || true)
cycle_pos=$(echo "$block0_sub" | grep -n -i "未完了.*cycle\|cycle.*未完了\|phase.*DONE\|in-progress" 2>/dev/null | head -1 | cut -d: -f1 || true)
if [ -n "$plan_pos" ] && [ -n "$cycle_pos" ] && [ "$plan_pos" -lt "$cycle_pos" ]; then
  pass "TC-02: steps-subagent.md Plan file checked first"
else
  fail "TC-02: steps-subagent.md Plan file not first (plan=${plan_pos:-none}, cycle=${cycle_pos:-none})"
fi

# TC-03: steps-teams.md Block 0 checks Plan file first
echo ""
echo "TC-03: steps-teams.md Block 0 checks Plan file first"
block0_teams=$(awk '/## Block 0/,/## Phase 1/' "$ORCH_TEAMS" 2>/dev/null || true)
plan_pos=$(echo "$block0_teams" | grep -n -i "plan.*file\|planファイル\|Plan ファイル" 2>/dev/null | head -1 | cut -d: -f1 || true)
cycle_pos=$(echo "$block0_teams" | grep -n -i "未完了.*cycle\|cycle.*未完了\|phase.*DONE\|in-progress" 2>/dev/null | head -1 | cut -d: -f1 || true)
if [ -n "$plan_pos" ] && [ -n "$cycle_pos" ] && [ "$plan_pos" -lt "$cycle_pos" ]; then
  pass "TC-03: steps-teams.md Plan file checked first"
else
  fail "TC-03: steps-teams.md Plan file not first (plan=${plan_pos:-none}, cycle=${cycle_pos:-none})"
fi

########################################
# Block 0: review --plan in new start flow
########################################

echo ""
echo "--- Block 0: review --plan in new start ---"

# TC-04: orchestrate/SKILL.md has review --plan (as dev-crew:review) in new start flow
echo ""
echo "TC-04: SKILL.md has dev-crew:review"
if grep -q "dev-crew:review" "$ORCH_SKILL"; then
  pass "TC-04: SKILL.md has dev-crew:review"
else
  fail "TC-04: SKILL.md missing dev-crew:review"
fi

# TC-05: steps-subagent.md Block 0 has review --plan in new start flow
echo ""
echo "TC-05: steps-subagent.md Block 0 has review --plan"
if echo "$block0_sub" | grep -q "review.*--plan"; then
  pass "TC-05: steps-subagent.md Block 0 has review --plan"
else
  fail "TC-05: steps-subagent.md Block 0 missing review --plan"
fi

# TC-06: steps-teams.md Block 0 has review --plan in new start flow
echo ""
echo "TC-06: steps-teams.md Block 0 has review --plan"
if echo "$block0_teams" | grep -q "review.*--plan"; then
  pass "TC-06: steps-teams.md Block 0 has review --plan"
else
  fail "TC-06: steps-teams.md Block 0 missing review --plan"
fi

########################################
# review SKILL.md: plan mode gate
########################################

echo ""
echo "--- review SKILL.md: plan mode gate ---"

# TC-07: review/SKILL.md plan mode uses Plan file as input source
echo ""
echo "TC-07: review/SKILL.md plan mode input is Plan file"
if grep -qi "planファイル\|plan file" "$REVIEW"; then
  pass "TC-07: review/SKILL.md plan mode references Plan file"
else
  fail "TC-07: review/SKILL.md plan mode does not reference Plan file"
fi

# TC-08: review/SKILL.md Cycle Doc Gate is under "code mode only" section
echo ""
echo "TC-08: review/SKILL.md Cycle Doc Gate is code mode only"
# Verify "code mode only" section contains "Cycle Doc Gate" (same section, not unrelated match)
gate_section=$(awk '/code mode only/,/^$/' "$REVIEW" 2>/dev/null || true)
if [ -n "$gate_section" ] && echo "$gate_section" | grep -q "Cycle Doc Gate"; then
  pass "TC-08: review/SKILL.md Cycle Doc Gate is code mode only"
else
  fail "TC-08: review/SKILL.md Cycle Doc Gate not in code mode only section"
fi

# TC-09: review/SKILL.md still has Cycle Doc Gate (for code mode backward compat)
echo ""
echo "TC-09: review/SKILL.md still has Cycle Doc Gate"
if grep -q "phase: DONE" "$REVIEW" && grep -q "BLOCK\|spec" "$REVIEW"; then
  pass "TC-09: review/SKILL.md has Cycle Doc Gate"
else
  fail "TC-09: review/SKILL.md missing Cycle Doc Gate"
fi

# TC-10: review/SKILL.md Phase Ordering Gate is under "code mode only" section
echo ""
echo "TC-10: review/SKILL.md Phase Ordering Gate is code mode only"
# Verify "code mode only" section contains "Phase Ordering Gate" (same section)
if [ -n "$gate_section" ] && echo "$gate_section" | grep -q "Phase Ordering Gate"; then
  pass "TC-10: review/SKILL.md Phase Ordering Gate is code mode only"
else
  fail "TC-10: review/SKILL.md Phase Ordering Gate not in code mode only section"
fi

########################################
# frontmatter-only matching (no body-text false negative)
########################################

echo ""
echo "--- frontmatter-only matching ---"

# TC-11: steps-subagent.md does NOT use bare 'grep -L' for phase: DONE check
# (grep -L matches body text, causing false negatives)
echo ""
echo "TC-11: steps-subagent.md uses frontmatter-only matching"
if echo "$block0_sub" | grep -q "grep -L 'phase: DONE'\|grep -rL 'phase: DONE'"; then
  fail "TC-11: steps-subagent.md still uses bare grep -L (body-text false negative)"
else
  if echo "$block0_sub" | grep -q "awk.*phase.*DONE\|frontmatter"; then
    pass "TC-11: steps-subagent.md uses frontmatter-only matching"
  else
    fail "TC-11: steps-subagent.md missing frontmatter-only matching"
  fi
fi

# TC-12: steps-teams.md does NOT use bare 'grep -L' for phase: DONE check
echo ""
echo "TC-12: steps-teams.md uses frontmatter-only matching"
if echo "$block0_teams" | grep -q "grep -L 'phase: DONE'\|grep -rL 'phase: DONE'"; then
  fail "TC-12: steps-teams.md still uses bare grep -L (body-text false negative)"
else
  if echo "$block0_teams" | grep -q "awk.*phase.*DONE\|frontmatter"; then
    pass "TC-12: steps-teams.md uses frontmatter-only matching"
  else
    fail "TC-12: steps-teams.md missing frontmatter-only matching"
  fi
fi

# TC-13: review/SKILL.md Cycle Doc Gate does NOT use bare 'grep -L'
echo ""
echo "TC-13: review/SKILL.md uses frontmatter-only matching"
if echo "$gate_section" | grep -q "grep -L 'phase: DONE'\|grep -rL 'phase: DONE'"; then
  fail "TC-13: review/SKILL.md still uses bare grep -L (body-text false negative)"
else
  if echo "$gate_section" | grep -q "awk.*phase.*DONE\|frontmatter"; then
    pass "TC-13: review/SKILL.md uses frontmatter-only matching"
  else
    fail "TC-13: review/SKILL.md missing frontmatter-only matching"
  fi
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
