#!/bin/bash
# test-codex-delegation-preference.sh - Verify Codex delegation preference feature (#53)
# TC-06: reference.md TDD Gate has NO codex_mode / delegation mode explanation (removed)
# TC-07: spec reference.md Post-Approve Action has NO plan-review mention (moved to
#        pre-approval Step 8)
# TC-08: spec reference.md Post-Approve Action has NO Codex delegation confirmation step (removed)
# TC-09: docs/workflow.md flow diagram has plan-review before sync-plan
# TC-10: docs/workflow.md has Claude plan-review before 承認ゲート(1)
# TC-12: orchestrate SKILL.md has NO codex_mode / delegation mode (removed)
# TC-13: spec reference.ja.md Post-Approve Action matches reference.md order

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== Codex Delegation Preference Tests ==="

# TC-06: reference.md TDD Gate has NO codex_mode / delegation mode explanation
echo ""
echo "TC-06: reference.md TDD Gate has no codex_mode / delegation mode"
tdd_gate_section=$(sed -n '/## TDD Gate/,/^## /p' "$BASE_DIR/skills/orchestrate/reference.md")
if [ -z "$tdd_gate_section" ]; then
  fail "reference.md TDD Gate section not found"
elif echo "$tdd_gate_section" | grep -qE 'codex_mode|委譲モード|`full`'; then
  fail "reference.md TDD Gate still has codex_mode / delegation mode"
else
  pass "reference.md TDD Gate has no codex_mode / delegation mode"
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

# TC-08: spec reference.md Post-Approve Action has NO Codex delegation confirmation
echo ""
echo "TC-08: spec reference.md has no Codex delegation confirmation"
if echo "$post_approve" | grep -qi 'codex.*委譲\|delegation.*confirm\|委譲.*確認\|codex_mode\|full.*no'; then
  fail "Post-Approve Action still has Codex delegation confirmation"
else
  pass "Post-Approve Action has no Codex delegation confirmation"
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

# TC-12: SKILL.md has NO codex_mode / delegation mode
echo ""
echo "TC-12: SKILL.md has no codex_mode / delegation mode"
if grep -qi 'codex_mode\|委譲モード' "$BASE_DIR/skills/orchestrate/SKILL.md"; then
  fail "SKILL.md still has codex_mode / delegation mode"
else
  pass "SKILL.md has no codex_mode / delegation mode"
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
