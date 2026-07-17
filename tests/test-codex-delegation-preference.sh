#!/bin/bash
# test-codex-delegation-preference.sh - Verify Codex delegation preference feature (#53)
# TC-01: steps-codex.md Pre-check has delegation mode confirmation (AskUserQuestion or Cycle doc)
# TC-02: steps-codex.md Pre-check has "full" and "no" options
# TC-03: steps-codex.md Gate 1 has "full" skip condition
# TC-04: steps-codex.md Gate 2 has "full" skip condition
# TC-05: steps-codex.md Test Plan consistency check is always executed
# TC-06: reference.md TDD Gate has delegation mode explanation
# TC-07: spec reference.md Post-Approve Action has NO plan-review mention (moved to
#        pre-approval Step 8)
# TC-08: spec reference.md Post-Approve Action has Codex delegation confirmation step
# TC-09: docs/workflow.md flow diagram has plan-review before sync-plan
# TC-10: docs/workflow.md has Claude plan-review before 承認ゲート(1)
# TC-11: Existing test-orchestrate-codex.sh passes (regression)
# TC-12: SKILL.md Mode Selection has user choice priority rule
# TC-13: spec reference.ja.md Post-Approve Action matches reference.md order

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== Codex Delegation Preference Tests ==="

# TC-01: steps-codex.md Pre-check has delegation mode confirmation
echo ""
echo "TC-01: steps-codex.md Pre-check has delegation mode confirmation"
if grep -qi 'codex_mode\|codex_delegation\|委譲モード\|delegation mode\|AskUserQuestion' "$BASE_DIR/skills/orchestrate/steps-codex.md"; then
  pass "steps-codex.md has delegation mode confirmation"
else
  fail "steps-codex.md missing delegation mode confirmation"
fi

# TC-02: steps-codex.md Pre-check has "full" and "no" options
echo ""
echo "TC-02: steps-codex.md has full and no options"
has_full=$(grep -ci 'full' "$BASE_DIR/skills/orchestrate/steps-codex.md" || true)
has_no=$(grep -ciE '\bno\b' "$BASE_DIR/skills/orchestrate/steps-codex.md" || true)
if [ "$has_full" -gt 0 ] && [ "$has_no" -gt 0 ]; then
  pass "steps-codex.md has both full and no options"
else
  fail "steps-codex.md missing full ($has_full) or no ($has_no) options"
fi

# TC-03: steps-codex.md Gate 1 has "full" skip condition
echo ""
echo "TC-03: steps-codex.md Gate 1 has full skip condition"
# Extract Gate 1 section and check for full/skip reference
gate1_section=$(sed -n '/Gate 1/,/Gate 2\|^##/p' "$BASE_DIR/skills/orchestrate/steps-codex.md")
if echo "$gate1_section" | grep -qi 'full\|スキップ\|skip'; then
  pass "Gate 1 has full mode skip condition"
else
  fail "Gate 1 missing full mode skip condition"
fi

# TC-04: steps-codex.md Gate 2 has "full" skip condition
echo ""
echo "TC-04: steps-codex.md Gate 2 has full skip condition"
gate2_section=$(sed -n '/Gate 2/,/^##/p' "$BASE_DIR/skills/orchestrate/steps-codex.md")
if echo "$gate2_section" | grep -qi 'full\|スキップ\|skip'; then
  pass "Gate 2 has full mode skip condition"
else
  fail "Gate 2 missing full mode skip condition"
fi

# TC-05: steps-codex.md Test Plan consistency check is always executed
echo ""
echo "TC-05: steps-codex.md Test Plan consistency check is always executed"
if grep -qi '常時\|無条件\|always\|regardless\|全モード' "$BASE_DIR/skills/orchestrate/steps-codex.md"; then
  pass "Test Plan consistency check is always executed"
else
  fail "Test Plan consistency check missing always/unconditional marker"
fi

# TC-06: reference.md TDD Gate has delegation mode explanation
echo ""
echo "TC-06: reference.md TDD Gate has delegation mode explanation"
tdd_gate_section=$(sed -n '/## TDD Gate/,/^## /p' "$BASE_DIR/skills/orchestrate/reference.md")
if echo "$tdd_gate_section" | grep -qi 'full\|codex_mode\|委譲モード\|delegation'; then
  pass "reference.md TDD Gate has delegation mode explanation"
else
  fail "reference.md TDD Gate missing delegation mode explanation"
fi

# TC-07: spec reference.md Post-Approve Action has NO plan-review mention
# (plan review moved to pre-approval Step 8)
echo ""
echo "TC-07: spec reference.md Post-Approve Action has no plan-review mention"
post_approve=$(sed -n '/## Post-Approve Action/,/```$/p' "$BASE_DIR/skills/spec/reference.md")
if echo "$post_approve" | grep -qi 'plan.review\|Plan review'; then
  fail "Post-Approve Action still mentions plan-review (should be pre-approval only)"
else
  pass "Post-Approve Action has no plan-review mention"
fi

# TC-08: spec reference.md Post-Approve Action has Codex delegation confirmation
echo ""
echo "TC-08: spec reference.md has Codex delegation confirmation"
if echo "$post_approve" | grep -qi 'codex.*委譲\|delegation.*confirm\|委譲.*確認\|codex_mode\|full.*no'; then
  pass "Post-Approve Action has Codex delegation confirmation"
else
  fail "Post-Approve Action missing Codex delegation confirmation"
fi

# TC-09: workflow.md flow diagram has plan-review before sync-plan (flipped: new order)
echo ""
echo "TC-09: workflow.md plan-review before sync-plan (new order)"
flow_section=$(sed -n '/^```$/,/^```$/p' "$BASE_DIR/docs/workflow.md" | head -40)
sync_line_p=$(echo "$flow_section" | grep -n -i 'sync-plan' | head -1 | cut -d: -f1)
review_line_p=$(echo "$flow_section" | grep -n -i 'plan.review\|plan review' | head -1 | cut -d: -f1)
if [ -n "$sync_line_p" ] && [ -n "$review_line_p" ] && [ "$review_line_p" -lt "$sync_line_p" ]; then
  pass "plan-review ($review_line_p) before sync-plan ($sync_line_p) in workflow.md"
else
  fail "plan-review ($review_line_p) NOT before sync-plan ($sync_line_p) in workflow.md"
fi

# TC-10: workflow.md has Claude plan-review before 承認ゲート(1) (flipped: pre-approval)
echo ""
echo "TC-10: workflow.md Claude plan-review precedes 承認ゲート(1)"
claude_review_line=$(grep -n -i 'Claude.*plan.review\|plan.review.*(Claude)' "$BASE_DIR/docs/workflow.md" | head -1 | cut -d: -f1)
gate_line_10=$(grep -nF '承認ゲート(1)' "$BASE_DIR/docs/workflow.md" | head -1 | cut -d: -f1)
if [ -n "$claude_review_line" ] && [ -n "$gate_line_10" ] && [ "$claude_review_line" -lt "$gate_line_10" ]; then
  pass "Claude plan-review ($claude_review_line) precedes 承認ゲート(1) ($gate_line_10)"
else
  fail "Claude plan-review ($claude_review_line) does NOT precede 承認ゲート(1) ($gate_line_10)"
fi

# TC-11: Existing test-orchestrate-codex.sh passes (regression)
echo ""
echo "TC-11: test-orchestrate-codex.sh regression"
if bash "$BASE_DIR/tests/test-orchestrate-codex.sh" > /dev/null 2>&1; then
  pass "test-orchestrate-codex.sh passes"
else
  fail "test-orchestrate-codex.sh failed (regression)"
fi

# TC-12: SKILL.md Mode Selection has user choice priority rule
echo ""
echo "TC-12: SKILL.md has user choice priority rule"
if grep -qi 'codex_mode\|ユーザー選択\|user.*choice\|user.*preference\|委譲モード' "$BASE_DIR/skills/orchestrate/SKILL.md"; then
  pass "SKILL.md has user choice priority rule"
else
  fail "SKILL.md missing user choice priority rule"
fi

# TC-13: spec reference.ja.md Post-Approve Action matches reference.md order
echo ""
echo "TC-13: reference.ja.md Post-Approve Action order"
post_approve_ja=$(sed -n '/## Post-Approve Action/,/```$/p' "$BASE_DIR/skills/spec/reference.ja.md")
sync_line_ja=$(echo "$post_approve_ja" | grep -n -i 'sync-plan\|Cycle doc' | head -1 | cut -d: -f1)
review_line_ja=$(echo "$post_approve_ja" | grep -n -i 'plan.review\|Plan review' | head -1 | cut -d: -f1)
if [ -n "$sync_line_ja" ] && [ -n "$review_line_ja" ] && [ "$sync_line_ja" -lt "$review_line_ja" ]; then
  pass "reference.ja.md sync-plan ($sync_line_ja) before plan-review ($review_line_ja)"
else
  fail "reference.ja.md sync-plan ($sync_line_ja) NOT before plan-review ($review_line_ja)"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
