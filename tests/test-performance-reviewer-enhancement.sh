#!/bin/bash
# test-performance-reviewer-enhancement.sh - performance-reviewer enhancement tests

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

AGENT_FILE="$BASE_DIR/agents/performance-reviewer.md"

echo "=== Performance Reviewer Enhancement Tests ==="

# TC-01: Agent file exists
echo ""
echo "TC-01: Agent file exists"
if [ -f "$AGENT_FILE" ]; then
  pass "TC-01: agents/performance-reviewer.md exists"
else
  fail "TC-01: agents/performance-reviewer.md not found"
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

# TC-04: description contains concurrency terms
echo ""
echo "TC-04: description contains concurrency terms"
desc_val=$(get_frontmatter "$AGENT_FILE" "description")
if echo "$desc_val" | grep -q "並行性\|並行"; then
  pass "TC-04: description contains '並行性' or '並行'"
else
  fail "TC-04: description missing '並行性' or '並行' (got: $desc_val)"
fi

# TC-05: Focus table contains concurrency safety perspective
echo ""
echo "TC-05: Focus table contains concurrency safety perspective"
if grep -q "並行性安全" "$AGENT_FILE"; then
  pass "TC-05: '並行性安全' perspective included"
else
  fail "TC-05: '並行性安全' perspective not found"
fi

# TC-06: SEI CERT reference included
echo ""
echo "TC-06: SEI CERT reference"
if grep -q "SEI CERT" "$AGENT_FILE"; then
  pass "TC-06: SEI CERT reference found"
else
  fail "TC-06: SEI CERT reference not found"
fi

# TC-07: blocking_score criteria defined
echo ""
echo "TC-07: blocking_score criteria"
if grep -q "blocking_score" "$AGENT_FILE"; then
  pass "TC-07: blocking_score criteria defined"
else
  fail "TC-07: blocking_score criteria not found"
fi

# TC-08: Output contains category field
echo ""
echo "TC-08: Output contains category"
if grep -q "category" "$AGENT_FILE"; then
  pass "TC-08: Output contains category field"
else
  fail "TC-08: Output category field not found"
fi

# TC-09: Focus is table format (| 観点 | pattern)
echo ""
echo "TC-09: Focus table format"
if grep -q "| 観点 |" "$AGENT_FILE"; then
  pass "TC-09: Focus is table format with '| 観点 |'"
else
  fail "TC-09: Focus is not table format (missing '| 観点 |')"
fi

# TC-10: Resource exhaustion perspective included
echo ""
echo "TC-10: Resource exhaustion perspective"
if grep -q "リソース枯渇" "$AGENT_FILE"; then
  pass "TC-10: 'リソース枯渇' perspective included"
else
  fail "TC-10: 'リソース枯渇' perspective not found"
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
