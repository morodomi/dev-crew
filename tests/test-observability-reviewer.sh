#!/bin/bash
# test-observability-reviewer.sh - observability-reviewer agent and integration tests

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

AGENT_FILE="$BASE_DIR/agents/observability-reviewer.md"
STEPS_FILE="$BASE_DIR/skills/review/steps-subagent.md"
REF_FILE="$BASE_DIR/skills/review/reference.md"

echo "=== Observability Reviewer Tests ==="

# TC-01: Agent file exists
echo ""
echo "TC-01: Agent file exists"
if [ -f "$AGENT_FILE" ]; then
  pass "TC-01: agents/observability-reviewer.md exists"
else
  fail "TC-01: agents/observability-reviewer.md not found"
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

# TC-04: description contains observability-related terms
echo ""
echo "TC-04: description contains observability terms"
desc_val=$(get_frontmatter "$AGENT_FILE" "description")
if echo "$desc_val" | grep -q "可観測性" || echo "$desc_val" | grep -q "ログ"; then
  pass "TC-04: description contains '可観測性' or 'ログ'"
else
  fail "TC-04: description missing '可観測性' or 'ログ' (got: $desc_val)"
fi

# TC-05: Four Golden Signals / metrics perspective included
echo ""
echo "TC-05: Four Golden Signals / metrics perspective"
if grep -qi "メトリクス" "$AGENT_FILE"; then
  pass "TC-05: metrics perspective included"
else
  fail "TC-05: metrics perspective not found"
fi

# TC-06: blocking_score criteria defined
echo ""
echo "TC-06: blocking_score criteria"
if grep -q "blocking_score" "$AGENT_FILE"; then
  pass "TC-06: blocking_score criteria defined"
else
  fail "TC-06: blocking_score criteria not found"
fi

# TC-07: observability-reviewer in Code Mode Risk-gated
echo ""
echo "TC-07: observability-reviewer in Code Mode Risk-gated"
if awk '/# Risk-gated/,0' "$STEPS_FILE" | grep -q 'observability-reviewer'; then
  pass "TC-07: observability-reviewer in Code Mode Risk-gated section"
else
  fail "TC-07: observability-reviewer not found in Code Mode Risk-gated section"
fi

# TC-08: observability-reviewer in Agent Roster (Code Mode)
echo ""
echo "TC-08: Agent Roster (Code Mode) contains observability-reviewer"
if awk '/## Agent Roster \(Code Mode\)/,0' "$REF_FILE" | grep -q 'observability-reviewer'; then
  pass "TC-08: observability-reviewer in Agent Roster (Code Mode)"
else
  fail "TC-08: observability-reviewer not found in Agent Roster (Code Mode)"
fi

# TC-09: observability-reviewer Condition is error-handling/logging flags
echo ""
echo "TC-09: observability-reviewer Condition is error-handling/logging flags"
if awk '/## Agent Roster \(Code Mode\)/,0' "$REF_FILE" | grep 'observability-reviewer' | grep -qi 'error-handling\|logging'; then
  pass "TC-09: observability-reviewer Condition is error-handling/logging flags"
else
  fail "TC-09: observability-reviewer Condition is not error-handling/logging flags"
fi

# TC-10: correctness-reviewer dedup rules defined
echo ""
echo "TC-10: correctness-reviewer dedup rules"
if grep -q "correctness-reviewer" "$AGENT_FILE" && grep -qi "dedup\|分担" "$AGENT_FILE"; then
  pass "TC-10: correctness-reviewer dedup rules defined"
else
  fail "TC-10: correctness-reviewer dedup rules not found"
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
