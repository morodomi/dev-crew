#!/bin/bash
# test-agents-md-count.sh - AGENTS.md agent count declaration tests
# TC-01: test-skills-structure.sh TC-B1 passes with "declares 40 agents"
# TC-02: AGENTS.md line 65 has "40 agents (flat)", not "41 agents (flat)"

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== AGENTS.md Agent Count Tests ==="

# TC-01: test-skills-structure.sh TC-B1 passes and declares 40 agents
# Note: subject script may exit 1 due to unrelated pre-existing failures;
# capture output first then grep to avoid pipefail masking.
echo ""
echo "TC-01: test-skills-structure.sh TC-B1 PASS with declares 40 agents"
subject_output="$(bash "$BASE_DIR/tests/test-skills-structure.sh" 2>&1 || true)"
if echo "$subject_output" | grep -qE "PASS.*TC-B1.*declares 40 agents"; then
  pass "TC-01: TC-B1 PASS with declares 40 agents, actual is 40"
else
  fail "TC-01: TC-B1 did not PASS with declares 40 agents (current mismatch or wrong count)"
fi

# TC-02: AGENTS.md has "40 agents (flat)" and NOT "41 agents (flat)"
echo ""
echo "TC-02: AGENTS.md declares 40 agents (flat), not 41"
has_40=$(grep -c "40 agents (flat)" "$BASE_DIR/AGENTS.md" || true)
has_41=$(grep -c "41 agents (flat)" "$BASE_DIR/AGENTS.md" || true)

if [ "$has_40" -ge 1 ] && [ "$has_41" -eq 0 ]; then
  pass "TC-02: AGENTS.md has '40 agents (flat)' and no '41 agents (flat)'"
else
  if [ "$has_40" -lt 1 ]; then
    fail "TC-02: '40 agents (flat)' not found in AGENTS.md (has_40=$has_40)"
  fi
  if [ "$has_41" -gt 0 ]; then
    fail "TC-02: '41 agents (flat)' still present in AGENTS.md (has_41=$has_41)"
  fi
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
