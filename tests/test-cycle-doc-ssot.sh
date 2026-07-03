#!/bin/bash
# test-cycle-doc-ssot.sh - Cycle doc SSOT + hybrid delegation validation
# TC-04 ~ TC-08

set -euo pipefail

# Constants
BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ORCHESTRATE_SUBAGENT="$BASE_DIR/skills/orchestrate/steps-subagent.md"
ORCHESTRATE_TEAMS="$BASE_DIR/skills/orchestrate/steps-teams.md"
ORCHESTRATE_REF="$BASE_DIR/skills/orchestrate/reference.md"

# Test result counters
PASS=0
FAIL=0

# Reusable patterns
DELEGATION_PATTERN="Phase Summary.*metrics\|delegation decision\|lightweight.*threshold\|evaluate.*line_count\|evaluate.*file_count"

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

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
