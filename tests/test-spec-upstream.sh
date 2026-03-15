#!/bin/bash
# test-spec-upstream.sh - Upstream Consistency Check validation
# T-01, T-02, T-03

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== Spec Upstream Consistency Check Tests ==="

# T-01: spec/SKILL.md contains "Upstream Consistency Check" or "Step 7.1"
echo ""
echo "T-01: spec/SKILL.md contains Upstream Consistency Check or Step 7.1"
if grep -q 'Upstream Consistency Check\|Step 7\.1' "$BASE_DIR/skills/spec/SKILL.md"; then
  pass "spec/SKILL.md contains Upstream Consistency Check"
else
  fail "spec/SKILL.md does not contain Upstream Consistency Check or Step 7.1"
fi

# T-02: spec/reference.md contains "upstream-check" section
echo ""
echo "T-02: spec/reference.md contains upstream-check section"
if grep -q 'upstream-check' "$BASE_DIR/skills/spec/reference.md"; then
  pass "spec/reference.md contains upstream-check section"
else
  fail "spec/reference.md does not contain upstream-check section"
fi

# T-03: design-reviewer.md Focus line contains "upstream"
echo ""
echo "T-03: design-reviewer.md Focus line contains upstream"
if grep -i '^Scope validity.*upstream\|Upstream consistency' "$BASE_DIR/agents/design-reviewer.md" | grep -qi 'upstream'; then
  pass "design-reviewer.md Focus line contains upstream"
else
  fail "design-reviewer.md Focus line does not contain upstream"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
