#!/bin/bash
# test-codex-delegation-preference.sh - Verify Codex delegation preference feature (#53)
# TC-01: steps-codex.md Pre-check has delegation mode confirmation (AskUserQuestion or Cycle doc)
# TC-02: steps-codex.md Pre-check has "full" and "no" options
# TC-03: steps-codex.md Gate 1 has "full" skip condition
# TC-04: steps-codex.md Gate 2 has "full" skip condition
# TC-05: steps-codex.md Test Plan consistency check is always executed
# TC-06: reference.md TDD Gate has delegation mode explanation
# TC-07: spec reference.md Post-Approve Action has sync-plan before plan-review
# TC-08: spec reference.md Post-Approve Action has Codex delegation confirmation step
# TC-09: PHILOSOPHY.md flow diagram has sync-plan before plan-review
# TC-10: PHILOSOPHY.md flow diagram has Claude plan-review
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

# TC-07: spec reference.md Post-Approve Action has sync-plan before plan-review
echo ""
echo "TC-07: spec reference.md sync-plan before plan-review in Post-Approve"
post_approve=$(sed -n '/## Post-Approve Action/,/```$/p' "$BASE_DIR/skills/spec/reference.md")
sync_line=$(echo "$post_approve" | grep -n -i 'sync-plan\|Cycle doc' | head -1 | cut -d: -f1)
review_line=$(echo "$post_approve" | grep -n -i 'plan.review\|Plan review' | head -1 | cut -d: -f1)
if [ -n "$sync_line" ] && [ -n "$review_line" ] && [ "$sync_line" -lt "$review_line" ]; then
  pass "sync-plan ($sync_line) before plan-review ($review_line)"
else
  fail "sync-plan ($sync_line) is NOT before plan-review ($review_line)"
fi

# TC-08: spec reference.md Post-Approve Action has Codex delegation confirmation
echo ""
echo "TC-08: spec reference.md has Codex delegation confirmation"
if echo "$post_approve" | grep -qi 'codex.*委譲\|delegation.*confirm\|委譲.*確認\|codex_mode\|full.*no'; then
  pass "Post-Approve Action has Codex delegation confirmation"
else
  fail "Post-Approve Action missing Codex delegation confirmation"
fi

# TC-09: PHILOSOPHY.md flow diagram has sync-plan before plan-review
echo ""
echo "TC-09: PHILOSOPHY.md sync-plan before plan-review"
flow_section=$(sed -n '/^```$/,/^```$/p' "$BASE_DIR/docs/PHILOSOPHY.md" | head -40)
sync_line_p=$(echo "$flow_section" | grep -n -i 'sync-plan' | head -1 | cut -d: -f1)
review_line_p=$(echo "$flow_section" | grep -n -i 'plan.review\|plan review' | head -1 | cut -d: -f1)
if [ -n "$sync_line_p" ] && [ -n "$review_line_p" ] && [ "$sync_line_p" -lt "$review_line_p" ]; then
  pass "sync-plan ($sync_line_p) before plan-review ($review_line_p) in PHILOSOPHY.md"
else
  fail "sync-plan ($sync_line_p) NOT before plan-review ($review_line_p) in PHILOSOPHY.md"
fi

# TC-10: PHILOSOPHY.md flow diagram has Claude plan-review
echo ""
echo "TC-10: PHILOSOPHY.md has Claude plan-review"
if grep -qi 'Claude.*plan.review\|plan.review.*(Claude)' "$BASE_DIR/docs/PHILOSOPHY.md"; then
  pass "PHILOSOPHY.md has Claude plan-review"
else
  fail "PHILOSOPHY.md missing Claude plan-review"
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
