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
  local file="$1"
  local section
  section=$(sed -n '/^## Post-Approve Action/,/^```$/p' "$file")
  local plan_line cycle_line
  plan_line=$(echo "$section" | grep -n "Plan review" | head -1 | cut -d: -f1)
  cycle_line=$(echo "$section" | grep -n "Cycle doc" | head -1 | cut -d: -f1)
  if [ -n "$plan_line" ] && [ -n "$cycle_line" ] && [ "$plan_line" -lt "$cycle_line" ]; then
    return 0
  else
    echo "    Plan review at line ${plan_line:-?}, Cycle doc at line ${cycle_line:-?} in section"
    return 1
  fi
}

# Helper: check all three steps exist in Post-Approve section
check_three_steps() {
  local file="$1"
  local section
  section=$(sed -n '/^## Post-Approve Action/,/^```$/p' "$file")
  local missing=""
  echo "$section" | grep -q "Plan review" || missing="$missing Plan_review"
  echo "$section" | grep -q "Cycle doc" || missing="$missing Cycle_doc"
  echo "$section" | grep -q "orchestrate" || missing="$missing orchestrate"
  if [ -z "$missing" ]; then
    return 0
  else
    echo "    missing:$missing"
    return 1
  fi
}

# TC-01: reference.md - Plan review before Cycle doc
if check_ordering "$BASE/skills/spec/reference.md"; then
  pass "TC-01: reference.md Plan review before Cycle doc"
else
  fail "TC-01: reference.md Plan review should be before Cycle doc"
fi

# TC-02: reference.ja.md - Plan review before Cycle doc
if check_ordering "$BASE/skills/spec/reference.ja.md"; then
  pass "TC-02: reference.ja.md Plan review before Cycle doc"
else
  fail "TC-02: reference.ja.md Plan review should be before Cycle doc"
fi

# TC-03: reference.md contains all three steps
if check_three_steps "$BASE/skills/spec/reference.md"; then
  pass "TC-03: reference.md contains all three Post-Approve steps"
else
  fail "TC-03: reference.md missing steps"
fi

# TC-04: reference.ja.md contains all three steps
if check_three_steps "$BASE/skills/spec/reference.ja.md"; then
  pass "TC-04: reference.ja.md contains all three Post-Approve steps"
else
  fail "TC-04: reference.ja.md missing steps"
fi

# TC-05: ordering matches PHILOSOPHY.md (authoritative source)
# PHILOSOPHY.md L53: "Codex plan review", L55: "sync-plan" - plan review comes first
philosophy="$BASE/docs/PHILOSOPHY.md"
phil_review_line=$(grep -n "Codex plan review" "$philosophy" | head -1 | cut -d: -f1)
phil_sync_line=$(grep -n "sync-plan" "$philosophy" | head -1 | cut -d: -f1)
if [ -n "$phil_review_line" ] && [ -n "$phil_sync_line" ] && [ "$phil_review_line" -lt "$phil_sync_line" ]; then
  pass "TC-05: PHILOSOPHY.md confirms plan review before sync-plan (L${phil_review_line} < L${phil_sync_line})"
else
  fail "TC-05: PHILOSOPHY.md ordering unexpected (review L${phil_review_line:-?}, sync-plan L${phil_sync_line:-?})"
fi

# TC-06: existing test passes (regression)
if bash "$BASE/tests/test-plugin-structure.sh" > /dev/null 2>&1; then
  pass "TC-06: test-plugin-structure.sh passes (regression)"
else
  fail "TC-06: test-plugin-structure.sh failed"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
