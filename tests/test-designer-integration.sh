#!/bin/bash
# test-designer-integration.sh - Designer integration with plan-review validation
# TC-01, TC-02, TC-03/04/05, TC-06/09, TC-07, TC-08, TC-10, TC-11, TC-12, SKILL.md
# Tests the integration of designer agent into the plan-review workflow

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

# Terminal output helpers
pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

SKILL_FILE="$BASE_DIR/skills/plan-review/SKILL.md"
REFERENCE_FILE="$BASE_DIR/skills/plan-review/reference.md"
STEPS_FILE="$BASE_DIR/skills/plan-review/steps-subagent.md"

echo "=== Designer Integration Tests ==="

# TC-01: SKILL.md is under 100 lines
echo ""
echo "TC-01: SKILL.md line count (max 100)"
if [ ! -f "$SKILL_FILE" ]; then
  fail "TC-01: SKILL.md not found"
else
  line_count=$(wc -l < "$SKILL_FILE" | tr -d ' ')
  if [ "$line_count" -gt 100 ]; then
    fail "TC-01: SKILL.md has $line_count lines (max 100)"
  else
    pass "TC-01: SKILL.md has $line_count lines (under 100)"
  fi
fi

# TC-02: All three files exist with valid frontmatter
echo ""
echo "TC-02: File existence and frontmatter validation"
tc02_fail=0

if [ ! -f "$SKILL_FILE" ]; then
  fail "TC-02: SKILL.md not found"
  tc02_fail=$((tc02_fail + 1))
fi

if [ ! -f "$REFERENCE_FILE" ]; then
  fail "TC-02: reference.md not found"
  tc02_fail=$((tc02_fail + 1))
fi

if [ ! -f "$STEPS_FILE" ]; then
  fail "TC-02: steps-subagent.md not found"
  tc02_fail=$((tc02_fail + 1))
fi

if [ -f "$SKILL_FILE" ]; then
  # Check frontmatter has name and description
  if ! grep -q "^name: plan-review" "$SKILL_FILE"; then
    fail "TC-02: SKILL.md missing 'name' frontmatter"
    tc02_fail=$((tc02_fail + 1))
  fi

  if ! grep -q "^description:" "$SKILL_FILE"; then
    fail "TC-02: SKILL.md missing 'description' frontmatter"
    tc02_fail=$((tc02_fail + 1))
  fi
fi

if [ "$tc02_fail" -eq 0 ]; then
  pass "TC-02: All files exist with valid frontmatter"
fi

# TC-07: steps-subagent.md has designer description
echo ""
echo "TC-07: steps-subagent.md has designer description"
tc07_fail=0

if [ ! -f "$STEPS_FILE" ]; then
  fail "TC-07: steps-subagent.md not found"
  tc07_fail=1
else
  if ! grep -qi "designer" "$STEPS_FILE"; then
    fail "TC-07: steps-subagent.md missing 'designer'"
    tc07_fail=$((tc07_fail + 1))
  fi

  if ! grep -qi "model" "$STEPS_FILE"; then
    fail "TC-07: steps-subagent.md missing 'model' (sonnet specification)"
    tc07_fail=$((tc07_fail + 1))
  fi

  # Check for conditional invocation keywords (UI or 条件)
  if ! grep -qiE "(UI|条件)" "$STEPS_FILE"; then
    fail "TC-07: steps-subagent.md missing conditional invocation description"
    tc07_fail=$((tc07_fail + 1))
  fi
fi

if [ "$tc07_fail" -eq 0 ]; then
  pass "TC-07: steps-subagent.md has designer with model and conditional invocation"
fi

# TC-08: Result integration - designer excluded from scoring
echo ""
echo "TC-08: Result integration - designer scoring exclusion"
tc08_fail=0

# Check steps-subagent.md or reference.md for designer scoring exclusion mention
found_scoring_exclusion=0

if [ -f "$STEPS_FILE" ]; then
  if grep -qi "scoring.*対象外" "$STEPS_FILE" || grep -qi "ブロッキングスコア.*designer" "$STEPS_FILE"; then
    found_scoring_exclusion=1
  fi
fi

if [ -f "$REFERENCE_FILE" ]; then
  if grep -qi "blocking_score.*5.*reviewer" "$REFERENCE_FILE" || grep -qi "5.*レビュアー.*ブロッキングスコア" "$REFERENCE_FILE"; then
    found_scoring_exclusion=1
  fi
fi

if [ "$found_scoring_exclusion" -eq 0 ]; then
  fail "TC-08: No mention that designer is excluded from blocking_score calculation"
  tc08_fail=1
else
  pass "TC-08: Designer is excluded from blocking_score (5 reviewers only)"
fi

# TC-10: reference.md has designer section
echo ""
echo "TC-10: reference.md has designer section"
tc10_fail=0

if [ ! -f "$REFERENCE_FILE" ]; then
  fail "TC-10: reference.md not found"
  tc10_fail=1
else
  if ! grep -qi "designer" "$REFERENCE_FILE"; then
    fail "TC-10: reference.md missing 'designer' section"
    tc10_fail=$((tc10_fail + 1))
  fi

  if ! grep -qi "UI" "$REFERENCE_FILE"; then
    fail "TC-10: reference.md missing UI-related judgment criteria"
    tc10_fail=$((tc10_fail + 1))
  fi

  # Check for role separation with usability-reviewer (designer vs usability-reviewer)
  if ! grep -qiE "(usability|役割分離|role.*boundary)" "$REFERENCE_FILE"; then
    fail "TC-10: reference.md missing role separation explanation"
    tc10_fail=$((tc10_fail + 1))
  fi
fi

if [ "$tc10_fail" -eq 0 ]; then
  pass "TC-10: reference.md has designer section with UI criteria and role separation"
fi

# TC-11: steps-subagent.md heading reflects 5+1 reviewers
echo ""
echo "TC-11: steps-subagent.md heading shows 5+1 structure"
if [ ! -f "$STEPS_FILE" ]; then
  fail "TC-11: steps-subagent.md not found"
else
  if grep -qE "(5\+1|5.*1|6.*エージェント)" "$STEPS_FILE"; then
    pass "TC-11: steps-subagent.md heading reflects 5+1 structure"
  else
    fail "TC-11: steps-subagent.md heading missing 5+1 structure"
  fi
fi

# TC-03/04/05: reference.md documents UI detection keyword categories
echo ""
echo "TC-03/04/05: reference.md has UI detection keyword categories"
tc_ui_fail=0

if [ -f "$REFERENCE_FILE" ]; then
  # TC-03 equiv: UI tech stack keywords (React, Vue, Flutter etc.)
  if ! grep -qE "(React|Vue|Flutter|Next\.js|Angular|Svelte)" "$REFERENCE_FILE"; then
    fail "TC-03: reference.md missing UI tech stack keywords"
    tc_ui_fail=$((tc_ui_fail + 1))
  fi

  # TC-04 equiv: UI component file paths (components/, views/, pages/ etc.)
  if ! grep -qE "(components/|views/|templates/|pages/|layouts/)" "$REFERENCE_FILE"; then
    fail "TC-04: reference.md missing UI component file path patterns"
    tc_ui_fail=$((tc_ui_fail + 1))
  fi

  # TC-05 equiv: UI/UX keywords in description
  if ! grep -qE "(UI|UX|フロントエンド|デザイン)" "$REFERENCE_FILE"; then
    fail "TC-05: reference.md missing UI/UX description keywords"
    tc_ui_fail=$((tc_ui_fail + 1))
  fi
else
  fail "TC-03/04/05: reference.md not found"
  tc_ui_fail=1
fi

if [ "$tc_ui_fail" -eq 0 ]; then
  pass "TC-03/04/05: reference.md documents all 3 UI detection categories"
fi

# TC-06/09: steps-subagent.md documents both UI and non-UI flows
echo ""
echo "TC-06/09: steps-subagent.md documents conditional execution flows"
tc_flow_fail=0

if [ -f "$STEPS_FILE" ]; then
  # TC-06 equiv: non-UI case documented (5 agents only)
  if ! grep -qE "(FALSE|5.*エージェント)" "$STEPS_FILE"; then
    fail "TC-06: steps-subagent.md missing non-UI (5 agents) flow"
    tc_flow_fail=$((tc_flow_fail + 1))
  fi

  # TC-09 equiv: result collection distinguishes reviewer JSON from designer Markdown
  if ! grep -qi "Markdown" "$STEPS_FILE"; then
    fail "TC-09: steps-subagent.md missing designer Markdown output distinction"
    tc_flow_fail=$((tc_flow_fail + 1))
  fi
else
  fail "TC-06/09: steps-subagent.md not found"
  tc_flow_fail=1
fi

if [ "$tc_flow_fail" -eq 0 ]; then
  pass "TC-06/09: Both UI and non-UI flows documented with output format distinction"
fi

# TC-12: target_audience/ui_scope extraction guidance
echo ""
echo "TC-12: target_audience/ui_scope extraction guidance"
tc_param_fail=0

found_params=0
if [ -f "$STEPS_FILE" ] && grep -qi "target_audience" "$STEPS_FILE"; then
  found_params=$((found_params + 1))
fi
if [ -f "$REFERENCE_FILE" ] && grep -qi "target_audience" "$REFERENCE_FILE"; then
  found_params=$((found_params + 1))
fi

if [ "$found_params" -eq 0 ]; then
  fail "TC-12: No target_audience extraction guidance in steps or reference"
  tc_param_fail=1
fi

found_scope=0
if [ -f "$STEPS_FILE" ] && grep -qi "ui_scope" "$STEPS_FILE"; then
  found_scope=$((found_scope + 1))
fi
if [ -f "$REFERENCE_FILE" ] && grep -qi "ui_scope" "$REFERENCE_FILE"; then
  found_scope=$((found_scope + 1))
fi

if [ "$found_scope" -eq 0 ]; then
  fail "TC-12: No ui_scope extraction guidance in steps or reference"
  tc_param_fail=$((tc_param_fail + 1))
fi

if [ "$tc_param_fail" -eq 0 ]; then
  pass "TC-12: target_audience and ui_scope extraction documented"
fi

# SKILL.md designer mention
echo ""
echo "SKILL.md: designer mention check"
tc_skill_fail=0

if [ ! -f "$SKILL_FILE" ]; then
  fail "SKILL.md: File not found"
  tc_skill_fail=1
else
  if ! grep -qi "designer" "$SKILL_FILE"; then
    fail "SKILL.md: Missing 'designer' mention"
    tc_skill_fail=$((tc_skill_fail + 1))
  fi

  if ! grep -qE "(最大6つ|5\+1|6.*エージェント)" "$SKILL_FILE"; then
    fail "SKILL.md: Description missing '最大6つ' or '5+1' structure"
    tc_skill_fail=$((tc_skill_fail + 1))
  fi
fi

if [ "$tc_skill_fail" -eq 0 ]; then
  pass "SKILL.md: Has designer mention with 5+1 structure"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
