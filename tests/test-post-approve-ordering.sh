#!/usr/bin/env bash
# Test: Post-Approve Action ordering matches workflow.md
# Plan review MUST come before Cycle doc (sync-plan)

set -euo pipefail
PASS=0; FAIL=0
BASE="$(cd "$(dirname "$0")/.." && pwd)"

pass() { PASS=$((PASS+1)); echo "  PASS: $1"; }
fail() { FAIL=$((FAIL+1)); echo "  FAIL: $1"; }

echo "=== Post-Approve Action Ordering ==="

# Helper: extract Post-Approve Action section and check ordering
# Correct order: sync-plan (Cycle doc) BEFORE plan-review (matches AGENTS.md TDD Workflow)
check_ordering() {
  local file="$1"
  local section
  section=$(sed -n '/^## Post-Approve Action/,/^```$/p' "$file")
  local sync_line review_line
  sync_line=$(echo "$section" | grep -ni "sync-plan\|Cycle doc" | head -1 | cut -d: -f1)
  review_line=$(echo "$section" | grep -ni "plan.review\|Plan review\|設計レビュー" | head -1 | cut -d: -f1)
  if [ -n "$sync_line" ] && [ -n "$review_line" ] && [ "$sync_line" -lt "$review_line" ]; then
    return 0
  else
    echo "    sync-plan at line ${sync_line:-?}, plan-review at line ${review_line:-?} in section"
    return 1
  fi
}

# Helper: check all three steps exist in Post-Approve section
check_three_steps() {
  local file="$1"
  local section
  section=$(sed -n '/^## Post-Approve Action/,/^```$/p' "$file")
  local missing=""
  echo "$section" | grep -qi "sync-plan\|Cycle doc" || missing="$missing sync-plan"
  echo "$section" | grep -qi "plan.review\|Plan review\|設計レビュー" || missing="$missing plan-review"
  echo "$section" | grep -qi "orchestrate\|Codex" || missing="$missing orchestrate"
  if [ -z "$missing" ]; then
    return 0
  else
    echo "    missing:$missing"
    return 1
  fi
}

# TC-01: reference.md - Plan review before Cycle doc
if check_ordering "$BASE/skills/spec/reference.md"; then
  pass "TC-01: reference.md sync-plan before plan-review"
else
  fail "TC-01: reference.md sync-plan should be before plan-review"
fi

# TC-02: reference.ja.md - Plan review before Cycle doc
if check_ordering "$BASE/skills/spec/reference.ja.md"; then
  pass "TC-02: reference.ja.md sync-plan before plan-review"
else
  fail "TC-02: reference.ja.md sync-plan should be before plan-review"
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

# TC-05: ordering matches workflow.md (authoritative source)
workflow="$BASE/docs/workflow.md"
wf_sync_line=$(grep -n "sync-plan" "$workflow" | head -1 | cut -d: -f1)
wf_review_line=$(grep -n "plan.review\|plan-review" "$workflow" | head -1 | cut -d: -f1)
if [ -n "$wf_sync_line" ] && [ -n "$wf_review_line" ] && [ "$wf_sync_line" -lt "$wf_review_line" ]; then
  pass "TC-05: workflow.md confirms sync-plan before plan-review (L${wf_sync_line} < L${wf_review_line})"
else
  fail "TC-05: workflow.md ordering unexpected (sync-plan L${wf_sync_line:-?}, review L${wf_review_line:-?})"
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
