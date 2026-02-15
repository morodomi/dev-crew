#!/bin/bash
# test-tdd-enforcement.sh - TDD enforcement validation (cycle doc check + pre-commit hook)
# TC-01 ~ TC-16

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEAMS_FILE="$BASE_DIR/skills/orchestrate/steps-teams.md"
SUBAGENT_FILE="$BASE_DIR/skills/orchestrate/steps-subagent.md"
HOOKS_JSON="$BASE_DIR/hooks/hooks.json"
HOOK_SCRIPT="$BASE_DIR/scripts/hooks/check-cycle-doc.sh"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== TDD Enforcement Tests ==="

########################################
# Steps Modification
########################################

echo ""
echo "--- Steps Modification ---"

# TC-01: steps-teams.md has "Block 0" or "Prerequisite Check" section
echo ""
echo "TC-01: steps-teams.md has Block 0 or Prerequisite Check"
if grep -q "Block 0\|Prerequisite Check" "$TEAMS_FILE" 2>/dev/null; then
  pass "steps-teams.md has prerequisite check section"
else
  fail "steps-teams.md missing Block 0 or Prerequisite Check"
fi

# TC-02: steps-subagent.md has "Block 0" or "Prerequisite Check" section
echo ""
echo "TC-02: steps-subagent.md has Block 0 or Prerequisite Check"
if grep -q "Block 0\|Prerequisite Check" "$SUBAGENT_FILE" 2>/dev/null; then
  pass "steps-subagent.md has prerequisite check section"
else
  fail "steps-subagent.md missing Block 0 or Prerequisite Check"
fi

# TC-03: steps-*.md has branching when no cycle doc → execute INIT
echo ""
echo "TC-03: steps-*.md branch to INIT when no cycle doc"
if grep -q "cycle doc.*存在しない\|cycle doc.*not found\|Skill(dev-crew:init)\|Skill(init)" "$TEAMS_FILE" 2>/dev/null || \
   grep -q "cycle doc.*存在しない\|cycle doc.*not found\|Skill(dev-crew:init)\|Skill(init)" "$SUBAGENT_FILE" 2>/dev/null; then
  pass "INIT branch found when no cycle doc"
else
  fail "INIT branch not found in steps-*.md"
fi

# TC-04: steps-*.md has branching when cycle doc exists → proceed to PLAN
echo ""
echo "TC-04: steps-*.md branch to PLAN when cycle doc exists"
if grep -q "cycle doc.*存在\|cycle doc.*found\|Block 1\|PLAN" "$TEAMS_FILE" 2>/dev/null && \
   grep -q "cycle doc.*存在\|cycle doc.*found\|Block 1\|PLAN" "$SUBAGENT_FILE" 2>/dev/null; then
  pass "PLAN branch found when cycle doc exists"
else
  fail "PLAN branch not found in steps-*.md"
fi

########################################
# Pre-commit Hook
########################################

echo ""
echo "--- Pre-commit Hook ---"

# TC-05: hooks.json has "PreCommit" or "pre-commit" hook definition
echo ""
echo "TC-05: hooks.json has pre-commit hook definition"
if grep -q "PreCommit\|pre-commit" "$HOOKS_JSON" 2>/dev/null; then
  pass "hooks.json has pre-commit hook"
else
  fail "hooks.json missing pre-commit hook definition"
fi

# TC-06: scripts/hooks/check-cycle-doc.sh exists
echo ""
echo "TC-06: scripts/hooks/check-cycle-doc.sh exists"
if [ -f "$HOOK_SCRIPT" ]; then
  pass "check-cycle-doc.sh exists"
else
  fail "check-cycle-doc.sh not found"
fi

# TC-07: hook script detects skills/ changes (git diff --cached --name-only)
echo ""
echo "TC-07: hook script detects skills/ changes"
if [ -f "$HOOK_SCRIPT" ]; then
  if grep -q "git diff --cached --name-only\|git diff.*--cached" "$HOOK_SCRIPT" 2>/dev/null && \
     grep -q "skills/" "$HOOK_SCRIPT" 2>/dev/null; then
    pass "hook detects skills/ changes"
  else
    fail "hook does not detect skills/ changes"
  fi
else
  fail "hook script not found (TC-06 prerequisite)"
fi

# TC-08: hook script checks docs/cycles/ existence
echo ""
echo "TC-08: hook script checks docs/cycles/ existence"
if [ -f "$HOOK_SCRIPT" ]; then
  if grep -q "docs/cycles" "$HOOK_SCRIPT" 2>/dev/null; then
    pass "hook checks docs/cycles/ directory"
  else
    fail "hook does not check docs/cycles/"
  fi
else
  fail "hook script not found (TC-06 prerequisite)"
fi

# TC-09: hook script detects agents/ changes
echo ""
echo "TC-09: hook script detects agents/ changes"
if [ -f "$HOOK_SCRIPT" ]; then
  if grep -q "agents/" "$HOOK_SCRIPT" 2>/dev/null; then
    pass "hook detects agents/ changes"
  else
    fail "hook does not detect agents/ changes"
  fi
else
  fail "hook script not found (TC-06 prerequisite)"
fi

# TC-10: hook script excludes docs/ only changes
echo ""
echo "TC-10: hook script excludes docs/ only changes"
if [ -f "$HOOK_SCRIPT" ]; then
  if grep -q "docs/\|docs only" "$HOOK_SCRIPT" 2>/dev/null; then
    pass "hook excludes docs/ only changes"
  else
    fail "hook does not exclude docs/ only changes"
  fi
else
  fail "hook script not found (TC-06 prerequisite)"
fi

# TC-11: hook script supports SKIP_CYCLE_CHECK environment variable
echo ""
echo "TC-11: hook script supports SKIP_CYCLE_CHECK environment variable"
if [ -f "$HOOK_SCRIPT" ]; then
  if grep -q "SKIP_CYCLE_CHECK" "$HOOK_SCRIPT" 2>/dev/null; then
    pass "hook supports SKIP_CYCLE_CHECK=1"
  else
    fail "hook does not support SKIP_CYCLE_CHECK"
  fi
else
  fail "hook script not found (TC-06 prerequisite)"
fi

# TC-12: hook script checks SKIP_CYCLE_CHECK value is "1"
echo ""
echo "TC-12: hook script checks SKIP_CYCLE_CHECK value is \"1\""
if [ -f "$HOOK_SCRIPT" ]; then
  if grep -q 'SKIP_CYCLE_CHECK.*=.*"1"' "$HOOK_SCRIPT" 2>/dev/null; then
    pass "hook checks SKIP_CYCLE_CHECK=1"
  else
    fail "hook does not validate SKIP_CYCLE_CHECK=1"
  fi
else
  fail "hook script not found (TC-06 prerequisite)"
fi

########################################
# Test Infrastructure
########################################

echo ""
echo "--- Test Infrastructure ---"

# TC-13: tests/test-tdd-enforcement.sh exists (this script)
echo ""
echo "TC-13: tests/test-tdd-enforcement.sh exists"
TEST_SCRIPT="$BASE_DIR/tests/test-tdd-enforcement.sh"
if [ -f "$TEST_SCRIPT" ]; then
  pass "test-tdd-enforcement.sh exists"
else
  fail "test-tdd-enforcement.sh not found"
fi

# TC-14: test script contains TC-07~TC-12 equivalent test cases
echo ""
echo "TC-14: test script contains TC-07~TC-12 test cases"
if [ -f "$TEST_SCRIPT" ]; then
  # Check if this script itself contains tests for TC-07 through TC-12
  if grep -q "TC-07\|TC-08\|TC-09\|TC-10\|TC-11\|TC-12" "$TEST_SCRIPT" 2>/dev/null; then
    pass "test script contains TC-07~TC-12"
  else
    fail "test script missing TC-07~TC-12 test cases"
  fi
else
  fail "test script not found (TC-13 prerequisite)"
fi

# TC-15: hook script has shebang (#!/bin/bash)
echo ""
echo "TC-15: hook script has shebang"
if [ -f "$HOOK_SCRIPT" ]; then
  if head -1 "$HOOK_SCRIPT" | grep -q "^#!/bin/bash\|^#!/usr/bin/env bash" 2>/dev/null; then
    pass "hook script has shebang"
  else
    fail "hook script missing shebang"
  fi
else
  fail "hook script not found (TC-06 prerequisite)"
fi

# TC-16: hook script uses set -e
echo ""
echo "TC-16: hook script uses set -e"
if [ -f "$HOOK_SCRIPT" ]; then
  if grep -q "set -e" "$HOOK_SCRIPT" 2>/dev/null; then
    pass "hook script uses set -e"
  else
    fail "hook script does not use set -e"
  fi
else
  fail "hook script not found (TC-06 prerequisite)"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
