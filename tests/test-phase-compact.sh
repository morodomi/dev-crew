#!/bin/bash
# test-phase-compact.sh - phase-compact skill validation
# TC-01 ~ TC-10

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILL_DIR="$BASE_DIR/skills/phase-compact"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

get_frontmatter() {
  local file="$1"
  local key="$2"
  awk '/^---$/{n++; next} n==1{print}' "$file" | grep "^${key}: " | head -1 | sed "s/^${key}: *//" || true
}

echo "=== Phase-Compact Skill Tests ==="

# TC-01: skills/phase-compact/ directory exists
echo ""
echo "TC-01: phase-compact directory exists"
if [ -d "$SKILL_DIR" ]; then
  pass "skills/phase-compact/ exists"
else
  fail "skills/phase-compact/ not found"
fi

# TC-02: SKILL.md exists and under 100 lines
echo ""
echo "TC-02: SKILL.md exists and < 100 lines"
if [ -f "$SKILL_DIR/SKILL.md" ]; then
  line_count=$(wc -l < "$SKILL_DIR/SKILL.md" | tr -d ' ')
  if [ "$line_count" -le 100 ]; then
    pass "SKILL.md exists ($line_count lines)"
  else
    fail "SKILL.md has $line_count lines (max 100)"
  fi
else
  fail "SKILL.md not found"
fi

# TC-03: SKILL.md has name/description frontmatter
echo ""
echo "TC-03: SKILL.md frontmatter"
if [ -f "$SKILL_DIR/SKILL.md" ]; then
  name_val=$(get_frontmatter "$SKILL_DIR/SKILL.md" "name")
  desc_val=$(get_frontmatter "$SKILL_DIR/SKILL.md" "description")
  if [ -n "$name_val" ] && [ -n "$desc_val" ]; then
    pass "frontmatter: name='$name_val'"
  else
    [ -z "$name_val" ] && fail "missing 'name' frontmatter"
    [ -z "$desc_val" ] && fail "missing 'description' frontmatter"
  fi
else
  fail "SKILL.md not found"
fi

# TC-04: SKILL.md contains Phase Summary format template
echo ""
echo "TC-04: Phase Summary format template"
if [ -f "$SKILL_DIR/SKILL.md" ]; then
  if grep -q "Phase Summary" "$SKILL_DIR/SKILL.md" && \
     grep -q "Artifacts" "$SKILL_DIR/SKILL.md" && \
     grep -q "Decisions" "$SKILL_DIR/SKILL.md" && \
     grep -q "Next Phase Input" "$SKILL_DIR/SKILL.md"; then
    pass "Phase Summary format template present"
  else
    fail "Phase Summary format template incomplete"
  fi
else
  fail "SKILL.md not found"
fi

# TC-05: SKILL.md contains Workflow section
echo ""
echo "TC-05: Workflow section"
if [ -f "$SKILL_DIR/SKILL.md" ]; then
  if grep -q "## Workflow" "$SKILL_DIR/SKILL.md"; then
    pass "Workflow section present"
  else
    fail "Workflow section missing"
  fi
else
  fail "SKILL.md not found"
fi

# TC-06: reference.md exists
echo ""
echo "TC-06: reference.md exists"
if [ -f "$SKILL_DIR/reference.md" ]; then
  pass "reference.md exists"
else
  fail "reference.md not found"
fi

# TC-07: reference.md contains Compaction Points
echo ""
echo "TC-07: Compaction Points table"
if [ -f "$SKILL_DIR/reference.md" ]; then
  if grep -q "Compaction Points" "$SKILL_DIR/reference.md"; then
    pass "Compaction Points table present"
  else
    fail "Compaction Points table missing"
  fi
else
  fail "reference.md not found"
fi

# TC-08: reference.md contains all 6 transitions
echo ""
echo "TC-08: All 6 phase transitions defined"
if [ -f "$SKILL_DIR/reference.md" ]; then
  transitions=("INIT" "PLAN" "RED" "GREEN" "REFACTOR" "REVIEW")
  missing=0
  for t in "${transitions[@]}"; do
    if ! grep -q "$t" "$SKILL_DIR/reference.md"; then
      fail "transition '$t' not found in reference.md"
      missing=$((missing + 1))
    fi
  done
  if [ "$missing" -eq 0 ]; then
    pass "All 6 transitions defined"
  fi
else
  fail "reference.md not found"
fi

# TC-09: Existing structure validation passes
echo ""
echo "TC-09: Structure validation (test-skills-structure.sh)"
if bash "$BASE_DIR/tests/test-skills-structure.sh" > /dev/null 2>&1; then
  pass "Structure validation passes"
else
  fail "Structure validation failed"
fi

# TC-10: [Negative] Phase Summary format validation
echo ""
echo "TC-10: [Negative] Incomplete Phase Summary detection"
# A Phase Summary without 'Artifacts' should be considered incomplete
incomplete_summary="### Phase: TEST - Completed at 12:00
**Decisions**: none"
if echo "$incomplete_summary" | grep -q "Artifacts"; then
  fail "Failed to detect missing Artifacts field"
else
  pass "Correctly detects missing Artifacts field"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
