#!/bin/bash
# test-designer-integration.sh - Designer integration with unified review validation
# TC-01 ~ TC-13
# Tests the integration of designer agent into the unified review workflow (plan mode)

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

# Terminal output helpers
pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

SKILL_FILE="$BASE_DIR/skills/review/SKILL.md"
REFERENCE_FILE="$BASE_DIR/skills/review/reference.md"
STEPS_FILE="$BASE_DIR/skills/review/steps-subagent.md"

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

for f in "$SKILL_FILE" "$REFERENCE_FILE" "$STEPS_FILE"; do
  if [ ! -f "$f" ]; then
    fail "TC-02: $(basename "$f") not found"
    tc02_fail=$((tc02_fail + 1))
  fi
done

if [ -f "$SKILL_FILE" ]; then
  if ! grep -q "^name: review" "$SKILL_FILE"; then
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

# TC-03: UI detection in risk classifier
echo ""
echo "TC-03: UI detection in risk classification"
tc03_fail=0

if [ -f "$REFERENCE_FILE" ]; then
  if ! grep -qE "(component|view|page|\.vue|\.tsx)" "$REFERENCE_FILE"; then
    fail "TC-03: reference.md missing UI component detection patterns"
    tc03_fail=$((tc03_fail + 1))
  fi
else
  fail "TC-03: reference.md not found"
  tc03_fail=1
fi

if [ "$tc03_fail" -eq 0 ]; then
  pass "TC-03: UI detection patterns in risk classification"
fi

# TC-04: Designer in plan mode agent roster
echo ""
echo "TC-04: Designer in plan mode agent roster"
tc04_fail=0

if [ -f "$REFERENCE_FILE" ]; then
  if ! grep -qi "designer" "$REFERENCE_FILE"; then
    fail "TC-04: reference.md missing 'designer' agent"
    tc04_fail=$((tc04_fail + 1))
  fi
  if ! grep -qiE "UI.*tech.*stack|UI.*flag" "$REFERENCE_FILE"; then
    fail "TC-04: reference.md missing designer UI condition"
    tc04_fail=$((tc04_fail + 1))
  fi
else
  fail "TC-04: reference.md not found"
  tc04_fail=1
fi

if [ "$tc04_fail" -eq 0 ]; then
  pass "TC-04: Designer in plan mode roster with UI condition"
fi

# TC-05: Designer in steps-subagent.md
echo ""
echo "TC-05: steps-subagent.md has designer"
tc05_fail=0

if [ -f "$STEPS_FILE" ]; then
  if ! grep -qi "designer" "$STEPS_FILE"; then
    fail "TC-05: steps-subagent.md missing 'designer'"
    tc05_fail=$((tc05_fail + 1))
  fi
  if ! grep -qi "model" "$STEPS_FILE"; then
    fail "TC-05: steps-subagent.md missing 'model' parameter"
    tc05_fail=$((tc05_fail + 1))
  fi
else
  fail "TC-05: steps-subagent.md not found"
  tc05_fail=1
fi

if [ "$tc05_fail" -eq 0 ]; then
  pass "TC-05: steps-subagent.md has designer with model parameter"
fi

# TC-06: Designer scoring exclusion
echo ""
echo "TC-06: Designer scoring exclusion"
tc06_fail=0

found_scoring_exclusion=0
if [ -f "$STEPS_FILE" ]; then
  if grep -qi "designer.*スコア対象外" "$STEPS_FILE"; then
    found_scoring_exclusion=1
  fi
fi

if [ "$found_scoring_exclusion" -eq 0 ]; then
  fail "TC-06: No mention that designer is excluded from scoring"
  tc06_fail=1
else
  pass "TC-06: Designer is excluded from blocking_score calculation"
fi

# TC-07: Usability-reviewer and designer coexistence
echo ""
echo "TC-07: usability-reviewer and designer coexistence"
tc07_fail=0

if [ -f "$REFERENCE_FILE" ]; then
  if grep -qi "usability" "$REFERENCE_FILE" && grep -qi "designer" "$REFERENCE_FILE"; then
    pass "TC-07: Both usability-reviewer and designer in reference"
  else
    fail "TC-07: Missing usability-reviewer or designer in reference"
    tc07_fail=1
  fi
else
  fail "TC-07: reference.md not found"
  tc07_fail=1
fi

# TC-08: Risk-based scaling includes designer
echo ""
echo "TC-08: Risk-based scaling"
tc08_fail=0

if [ -f "$REFERENCE_FILE" ]; then
  if grep -qE "LOW|MEDIUM|HIGH" "$REFERENCE_FILE" && grep -q "Risk" "$REFERENCE_FILE"; then
    pass "TC-08: Risk-based scaling with LOW/MEDIUM/HIGH levels"
  else
    fail "TC-08: Missing risk-based scaling"
    tc08_fail=1
  fi
else
  fail "TC-08: reference.md not found"
  tc08_fail=1
fi

# TC-09: Plan mode vs code mode distinction
echo ""
echo "TC-09: Plan mode vs code mode distinction"
tc09_fail=0

if [ -f "$STEPS_FILE" ]; then
  if grep -qi "Plan Mode" "$STEPS_FILE" && grep -qi "Code Mode" "$STEPS_FILE"; then
    pass "TC-09: Both plan and code modes documented in steps"
  else
    fail "TC-09: Missing plan/code mode distinction in steps"
    tc09_fail=1
  fi
else
  fail "TC-09: steps-subagent.md not found"
  tc09_fail=1
fi

# TC-10: Designer conditional on UI flags
echo ""
echo "TC-10: Designer conditional on UI flags"
tc10_fail=0

if [ -f "$STEPS_FILE" ]; then
  if grep -qi "UI" "$STEPS_FILE"; then
    pass "TC-10: steps-subagent.md has UI-related conditions"
  else
    fail "TC-10: steps-subagent.md missing UI conditions"
    tc10_fail=1
  fi
else
  fail "TC-10: steps-subagent.md not found"
  tc10_fail=1
fi

# TC-11: SKILL.md references unified review modes
echo ""
echo "TC-11: SKILL.md references plan and code modes"
tc11_fail=0

if [ -f "$SKILL_FILE" ]; then
  if grep -qi "plan" "$SKILL_FILE" && grep -qi "code" "$SKILL_FILE"; then
    pass "TC-11: SKILL.md references both plan and code modes"
  else
    fail "TC-11: SKILL.md missing plan/code mode references"
    tc11_fail=1
  fi
else
  fail "TC-11: SKILL.md not found"
  tc11_fail=1
fi

# TC-12: ブロッキングスコア基準 in reference
echo ""
echo "TC-12: Blocking score criteria in reference"
tc12_fail=0

if [ -f "$REFERENCE_FILE" ]; then
  if grep -q "ブロッキングスコア基準" "$REFERENCE_FILE"; then
    pass "TC-12: reference.md has blocking score criteria section"
  else
    fail "TC-12: reference.md missing blocking score criteria"
    tc12_fail=1
  fi
else
  fail "TC-12: reference.md not found"
  tc12_fail=1
fi

# TC-13: Cost comparison documented
echo ""
echo "TC-13: Cost comparison in reference"
tc13_fail=0

if [ -f "$REFERENCE_FILE" ]; then
  if grep -q "コスト比較" "$REFERENCE_FILE"; then
    pass "TC-13: reference.md has cost comparison section"
  else
    fail "TC-13: reference.md missing cost comparison"
    tc13_fail=1
  fi
else
  fail "TC-13: reference.md not found"
  tc13_fail=1
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
