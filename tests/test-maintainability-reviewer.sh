#!/bin/bash
# test-maintainability-reviewer.sh - maintainability-reviewer agent and integration tests

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

# Extract frontmatter value from a markdown file
get_frontmatter() {
  local file="$1"
  local key="$2"
  awk '/^---$/{n++; next} n==1{print}' "$file" | grep "^${key}: " | head -1 | sed "s/^${key}: *//" || true
}

AGENT_FILE="$BASE_DIR/agents/maintainability-reviewer.md"
STEPS_FILE="$BASE_DIR/skills/review/steps-subagent.md"
REF_FILE="$BASE_DIR/skills/review/reference.md"

echo "=== Maintainability Reviewer Tests ==="

# TC-01: Agent file exists
echo ""
echo "TC-01: Agent file exists"
if [ -f "$AGENT_FILE" ]; then
  pass "TC-01: agents/maintainability-reviewer.md exists"
else
  fail "TC-01: agents/maintainability-reviewer.md not found"
fi

# TC-02: model is sonnet
echo ""
echo "TC-02: model is sonnet"
model_val=$(get_frontmatter "$AGENT_FILE" "model")
if [ "$model_val" = "sonnet" ]; then
  pass "TC-02: model is 'sonnet'"
else
  fail "TC-02: model is '$model_val' (expected: sonnet)"
fi

# TC-03: memory is project
echo ""
echo "TC-03: memory is project"
memory_val=$(get_frontmatter "$AGENT_FILE" "memory")
if [ "$memory_val" = "project" ]; then
  pass "TC-03: memory is 'project'"
else
  fail "TC-03: memory is '$memory_val' (expected: project)"
fi

# TC-04: description contains keyword
echo ""
echo "TC-04: description contains keyword"
desc_val=$(get_frontmatter "$AGENT_FILE" "description")
if echo "$desc_val" | grep -q "保守性"; then
  pass "TC-04: description contains '保守性'"
else
  fail "TC-04: description does not contain '保守性' (got: $desc_val)"
fi

# TC-05: Fowler Code Smells 5 categories mentioned
echo ""
echo "TC-05: Fowler Code Smells 5 categories"
categories=("Bloaters" "OO Abusers" "Change Preventers" "Dispensables" "Couplers")
all_found=true
for cat in "${categories[@]}"; do
  if ! grep -qi "$cat" "$AGENT_FILE"; then
    fail "TC-05: Category '$cat' not found in agent definition"
    all_found=false
  fi
done
if [ "$all_found" = true ]; then
  pass "TC-05: All 5 Fowler Code Smells categories mentioned"
fi

# TC-06: blocking_score criteria defined
echo ""
echo "TC-06: blocking_score criteria"
if grep -q "blocking_score" "$AGENT_FILE"; then
  pass "TC-06: blocking_score criteria defined"
else
  fail "TC-06: blocking_score criteria not found"
fi

# TC-07: maintainability-reviewer in Code Mode Always-on
echo ""
echo "TC-07: maintainability-reviewer in Code Mode Always-on"
# Check that maintainability-reviewer appears in the Always-on section of Code Mode
if awk '/# Always-on/,/# Risk-gated/' "$STEPS_FILE" | grep -q 'maintainability-reviewer'; then
  pass "TC-07: maintainability-reviewer in Code Mode Always-on section"
else
  fail "TC-07: maintainability-reviewer not found in Code Mode Always-on section"
fi

# TC-08: maintainability-reviewer in Agent Roster (Code Mode)
echo ""
echo "TC-08: Agent Roster (Code Mode) contains maintainability-reviewer"
if awk '/## Agent Roster \(Code Mode\)/,0' "$REF_FILE" | grep -q 'maintainability-reviewer'; then
  pass "TC-08: maintainability-reviewer in Agent Roster (Code Mode)"
else
  fail "TC-08: maintainability-reviewer not found in Agent Roster (Code Mode)"
fi

# TC-09: maintainability-reviewer Condition is Always
echo ""
echo "TC-09: maintainability-reviewer Condition is Always"
if awk '/## Agent Roster \(Code Mode\)/,0' "$REF_FILE" | grep 'maintainability-reviewer' | grep -qi 'Always'; then
  pass "TC-09: maintainability-reviewer Condition is Always (NON-NEGOTIABLE)"
else
  fail "TC-09: maintainability-reviewer Condition is not Always"
fi

# TC-10: Code Mode LOW agent count >= 4
echo ""
echo "TC-10: Code Mode LOW agent count >= 4"
low_agents=$(grep -i '| LOW' "$STEPS_FILE" | grep -oE '[0-9]+' | tail -1)
if [ -n "$low_agents" ] && [ "$low_agents" -ge 4 ]; then
  pass "TC-10: Code Mode LOW agent count is $low_agents (>= 4)"
else
  fail "TC-10: Code Mode LOW agent count is '${low_agents:-empty}' (expected: >= 4)"
fi

# TC-11: Regression - existing tests pass
echo ""
echo "TC-11: Regression check (existing agent structure tests)"
if bash "$BASE_DIR/tests/test-agents-structure.sh" > /dev/null 2>&1; then
  pass "TC-11: test-agents-structure.sh passes"
else
  fail "TC-11: test-agents-structure.sh failed (regression)"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
