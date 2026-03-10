#!/bin/bash
# test-cycle-doc-ssot.sh - Cycle doc SSOT + hybrid delegation validation
# TC-01 ~ TC-09

set -euo pipefail

# Constants
BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PHASE_COMPACT_SKILL="$BASE_DIR/skills/phase-compact/SKILL.md"
PHASE_COMPACT_REF="$BASE_DIR/skills/phase-compact/reference.md"
ORCHESTRATE_SUBAGENT="$BASE_DIR/skills/orchestrate/steps-subagent.md"
ORCHESTRATE_TEAMS="$BASE_DIR/skills/orchestrate/steps-teams.md"
ORCHESTRATE_REF="$BASE_DIR/skills/orchestrate/reference.md"

# Test result counters
PASS=0
FAIL=0

# Reusable patterns
METRICS_PATTERN="line_count\|file_count\|test_count\|\*\*Metrics\*\*"
DELEGATION_PATTERN="Phase Summary.*metrics\|delegation decision\|lightweight.*threshold\|evaluate.*line_count\|evaluate.*file_count"
MAX_SKILL_LINES=100

# Test result helpers
pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

# Check if Block 0 (Prerequisite Check) essential structure is preserved
check_block0_preserved() {
  local file="$1"
  grep -q "Block 0: Prerequisite Check" "$file" 2>/dev/null && \
  grep -qi "Plan ファイル\|Plan file\|planファイル" "$file" 2>/dev/null && \
  grep -q "phase: DONE\|frontmatter" "$file" 2>/dev/null
}

echo "=== Cycle doc SSOT + Hybrid Delegation Tests ==="

########################################
# Phase Compact Structure
########################################

echo ""
echo "--- Phase Compact Structure ---"

# TC-01: phase-compact/SKILL.md contains structured Phase Summary format definition
# Given: SKILL.md has Phase Summary Format section
# When: checking for structured metrics fields (line_count, file_count, test_count or **Metrics**)
# Then: should find metrics field definitions for hybrid delegation decisions
echo ""
echo "TC-01: phase-compact/SKILL.md contains structured Phase Summary format with metrics"
if [ -f "$PHASE_COMPACT_SKILL" ]; then
  if grep -q "$METRICS_PATTERN" "$PHASE_COMPACT_SKILL" 2>/dev/null; then
    pass "SKILL.md has structured metrics fields"
  else
    fail "SKILL.md missing structured metrics fields (line_count, file_count, test_count)"
  fi
else
  fail "SKILL.md not found"
fi

# TC-02: phase-compact/SKILL.md remains under 100 lines (guard test)
# Given: SKILL.md file exists
# When: counting total lines
# Then: should be under 100 lines (Progressive Disclosure requirement)
echo ""
echo "TC-02: phase-compact/SKILL.md remains under 100 lines"
if [ -f "$PHASE_COMPACT_SKILL" ]; then
  LINE_COUNT=$(wc -l < "$PHASE_COMPACT_SKILL")
  if [ "$LINE_COUNT" -lt "$MAX_SKILL_LINES" ]; then
    pass "SKILL.md is $LINE_COUNT lines (under $MAX_SKILL_LINES)"
  else
    fail "SKILL.md is $LINE_COUNT lines (exceeds $MAX_SKILL_LINES)"
  fi
else
  fail "SKILL.md not found"
fi

# TC-03: phase-compact/reference.md contains updated Phase Summary templates with metrics
# Given: reference.md has Phase Summary Details section
# When: checking for structured metrics in templates
# Then: should find metrics fields in at least one phase template
echo ""
echo "TC-03: phase-compact/reference.md contains Phase Summary templates with metrics"
if [ -f "$PHASE_COMPACT_REF" ]; then
  if grep -q "$METRICS_PATTERN" "$PHASE_COMPACT_REF" 2>/dev/null; then
    pass "reference.md has metrics in Phase Summary templates"
  else
    fail "reference.md missing metrics fields in templates"
  fi
else
  fail "reference.md not found"
fi

########################################
# Orchestrate Cycle Doc SSOT
########################################

echo ""
echo "--- Orchestrate Cycle Doc SSOT ---"

# TC-04: orchestrate/steps-subagent.md contains hybrid delegation logic
# Given: steps-subagent.md has subagent spawn prompts
# When: checking for hybrid delegation decision point after phase completion
# Then: should find decision logic with metrics evaluation (Phase Summary metrics)
echo ""
echo "TC-04: orchestrate/steps-subagent.md contains hybrid delegation logic"
if [ -f "$ORCHESTRATE_SUBAGENT" ]; then
  if grep -q "$DELEGATION_PATTERN" "$ORCHESTRATE_SUBAGENT" 2>/dev/null; then
    pass "steps-subagent.md has hybrid delegation logic"
  else
    fail "steps-subagent.md missing hybrid delegation decision logic"
  fi
else
  fail "steps-subagent.md not found"
fi

# TC-05: orchestrate/steps-teams.md contains hybrid delegation logic
# Given: steps-teams.md has Task() spawn prompts
# When: checking for hybrid delegation decision point after phase completion
# Then: should find decision logic with metrics evaluation
echo ""
echo "TC-05: orchestrate/steps-teams.md contains hybrid delegation logic"
if [ -f "$ORCHESTRATE_TEAMS" ]; then
  if grep -q "$DELEGATION_PATTERN" "$ORCHESTRATE_TEAMS" 2>/dev/null; then
    pass "steps-teams.md has hybrid delegation logic"
  else
    fail "steps-teams.md missing hybrid delegation decision logic"
  fi
else
  fail "steps-teams.md not found"
fi

# TC-06: orchestrate/reference.md contains delegation decision criteria table
# Given: reference.md exists
# When: checking for delegation decision criteria
# Then: should find markdown table with delegation thresholds
echo ""
echo "TC-06: orchestrate/reference.md contains delegation decision criteria table"
if [ -f "$ORCHESTRATE_REF" ]; then
  # Check for "delegation" keyword AND markdown table pattern (|)
  if grep -q "delegation\|委譲" "$ORCHESTRATE_REF" 2>/dev/null && \
     grep -q "^|.*threshold\|^|.*lightweight\|^|.*Phase.*|.*decision" "$ORCHESTRATE_REF" 2>/dev/null; then
    pass "reference.md has delegation criteria table"
  else
    fail "reference.md missing delegation criteria table"
  fi
else
  fail "reference.md not found"
fi

########################################
# Block 0 Preservation (TDD Enforcement)
########################################

echo ""
echo "--- Block 0 Preservation (Issue #15) ---"

# TC-07: orchestrate/steps-subagent.md Block 0 remains unchanged
# Given: steps-subagent.md has Block 0 (lines 13-31 from TDD enforcement)
# When: checking Block 0 essential content
# Then: should preserve "Block 0: Prerequisite Check" and "Cycle Doc Validation"
echo ""
echo "TC-07: orchestrate/steps-subagent.md Block 0 remains unchanged"
if [ -f "$ORCHESTRATE_SUBAGENT" ]; then
  if check_block0_preserved "$ORCHESTRATE_SUBAGENT"; then
    pass "steps-subagent.md Block 0 preserved (TDD enforcement intact)"
  else
    fail "steps-subagent.md Block 0 modified or missing (violates #15 preservation)"
  fi
else
  fail "steps-subagent.md not found"
fi

# TC-08: orchestrate/steps-teams.md Block 0 remains unchanged
# Given: steps-teams.md has Block 0 (lines 6-23 from TDD enforcement)
# When: checking Block 0 essential content
# Then: should preserve "Block 0: Prerequisite Check" and "Cycle Doc Validation"
echo ""
echo "TC-08: orchestrate/steps-teams.md Block 0 remains unchanged"
if [ -f "$ORCHESTRATE_TEAMS" ]; then
  if check_block0_preserved "$ORCHESTRATE_TEAMS"; then
    pass "steps-teams.md Block 0 preserved (TDD enforcement intact)"
  else
    fail "steps-teams.md Block 0 modified or missing (violates #15 preservation)"
  fi
else
  fail "steps-teams.md not found"
fi

########################################
# Test Infrastructure Validation
########################################

echo ""
echo "--- Test Infrastructure Validation ---"

# TC-09: test-cycle-doc-ssot.sh validates Phase Summary structured fields meaningfully
# Given: this test script exists and TC-01, TC-03 exist
# When: running the metrics validation tests
# Then: TC-01 and TC-03 should both PASS (structured fields exist in actual files)
echo ""
echo "TC-09: test-cycle-doc-ssot.sh validates Phase Summary structured fields meaningfully"
TEST_SCRIPT="$BASE_DIR/tests/test-cycle-doc-ssot.sh"
if [ -f "$TEST_SCRIPT" ]; then
  # TC-09 succeeds only if TC-01 and TC-03 both pass (actual files have metrics)
  # This is a meta-validation: the test script is meaningful when it passes on real content
  if grep -q "$METRICS_PATTERN" "$PHASE_COMPACT_SKILL" 2>/dev/null && \
     grep -q "$METRICS_PATTERN" "$PHASE_COMPACT_REF" 2>/dev/null; then
    pass "test script validates structured metrics fields meaningfully"
  else
    fail "test script validation not yet meaningful (TC-01/TC-03 prerequisite)"
  fi
else
  fail "test-cycle-doc-ssot.sh not found"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
