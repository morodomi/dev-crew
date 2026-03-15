#!/usr/bin/env bash
# Test: Post-Approve Action ordering matches PHILOSOPHY.md
# Plan review MUST come before Cycle doc (sync-plan)

set -euo pipefail
PASS=0; FAIL=0
BASE="$(cd "$(dirname "$0")/.." && pwd)"

pass() { PASS=$((PASS+1)); echo "  PASS: $1"; }
fail() { FAIL=$((FAIL+1)); echo "  FAIL: $1"; }

echo "=== Post-Approve Action Ordering ==="

# Helper: extract Post-Approve Action section and check ordering
check_ordering() {
  local file="$1" label="$2"
  local section
  section=$(sed -n '/^## Post-Approve Action/,/^```$/p' "$file")
  local plan_line cycle_line
  plan_line=$(echo "$section" | grep -n "Plan review" | head -1 | cut -d: -f1)
  cycle_line=$(echo "$section" | grep -n "Cycle doc" | head -1 | cut -d: -f1)
  if [ -n "$plan_line" ] && [ -n "$cycle_line" ] && [ "$plan_line" -lt "$cycle_line" ]; then
    return 0
  else
    echo "    Plan review at line $plan_line, Cycle doc at line $cycle_line in section"
    return 1
  fi
}

# TC-01: reference.md - Plan review before Cycle doc
if check_ordering "$BASE/skills/spec/reference.md" "reference.md"; then
  pass "TC-01: reference.md Plan review before Cycle doc"
else
  fail "TC-01: reference.md Plan review should be before Cycle doc"
fi

# TC-02: reference.ja.md - Plan review before Cycle doc
if check_ordering "$BASE/skills/spec/reference.ja.md" "reference.ja.md"; then
  pass "TC-02: reference.ja.md Plan review before Cycle doc"
else
  fail "TC-02: reference.ja.md Plan review should be before Cycle doc"
fi

# TC-03: reference.md contains all three steps
missing=""
grep -q "Plan review" "$BASE/skills/spec/reference.md" || missing="$missing Plan_review"
grep -q "Cycle doc" "$BASE/skills/spec/reference.md" || missing="$missing Cycle_doc"
grep -q "orchestrate" "$BASE/skills/spec/reference.md" || missing="$missing orchestrate"
if [ -z "$missing" ]; then
  pass "TC-03: reference.md contains all three Post-Approve steps"
else
  fail "TC-03: reference.md missing:$missing"
fi

# TC-04: existing test passes (regression)
if bash "$BASE/tests/test-plugin-structure.sh" > /dev/null 2>&1; then
  pass "TC-04: test-plugin-structure.sh passes (regression)"
else
  fail "TC-04: test-plugin-structure.sh failed"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
