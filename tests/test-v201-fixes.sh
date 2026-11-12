#!/bin/bash
# test-v201-fixes.sh - v2.0.1 pre-release fixes
# P0: sync-plan Codex Debate removal + Codex Plan Review integration
# P1: Findings summary after commit
#
# TC-01: sync-plan.md does NOT have Debate Workflow section
# TC-02: sync-plan.md does NOT have Human Clarification section
# TC-03: spec reference.md Post-Approve Action has NO Codex plan review (moved to
#        pre-approval spec Step 8)
# TC-04: steps-subagent.md REVIEW section has Codex competitive review
# TC-05: commit SKILL.md has findings summary step after commit
# (TC-06/07/08 removed: codex_mode is gone; absence is pinned by test-codex-delegation-preference.sh TC-06/TC-12)
# TC-09: spec reference.ja.md Post-Approve Action has NO Codex plan review, matching
#        reference.md
# TC-10: Existing tests pass (regression)

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== v2.0.1 Pre-Release Fixes Tests ==="

# TC-01: sync-plan.md does NOT have Debate Workflow section
echo ""
echo "TC-01: sync-plan.md has no Debate Workflow"
if grep -q '## Debate Workflow' "$BASE_DIR/agents/sync-plan.md"; then
  fail "sync-plan.md still has Debate Workflow section"
else
  pass "sync-plan.md has no Debate Workflow"
fi

# TC-02: sync-plan.md does NOT have Human Clarification section
echo ""
echo "TC-02: sync-plan.md has no Human Clarification"
if grep -q '### Human Clarification' "$BASE_DIR/agents/sync-plan.md"; then
  fail "sync-plan.md still has Human Clarification section"
else
  pass "sync-plan.md has no Human Clarification"
fi

# TC-03: spec reference.md Post-Approve Action has NO Codex plan review
# (plan review moved to pre-approval spec Step 8)
echo ""
echo "TC-03: Post-Approve Action has NO Codex plan review (moved to pre-approval Step 8)"
post_approve=$(sed -n '/## Post-Approve Action/,/^## /p' "$BASE_DIR/skills/spec/reference.md")
if echo "$post_approve" | grep -qi 'codex.*plan.*review\|codex.*exec.*plan'; then
  fail "Post-Approve Action still contains Codex plan review (should be pre-approval only)"
else
  pass "Post-Approve Action has no Codex plan review reference"
fi

# TC-04: steps-subagent.md REVIEW has Codex competitive review
echo ""
echo "TC-04: steps-subagent.md REVIEW has Codex competitive review"
review_section=$(sed -n '/### REVIEW/,/^## /p' "$BASE_DIR/skills/orchestrate/steps-subagent.md")
if echo "$review_section" | grep -qi 'codex.*review\|competitive\|codex exec'; then
  pass "steps-subagent.md REVIEW has Codex competitive review"
else
  fail "steps-subagent.md REVIEW missing Codex competitive review"
fi

# TC-05: commit SKILL.md has findings summary step
echo ""
echo "TC-05: commit SKILL.md has findings summary"
if grep -qi 'findings.*サマリー\|findings.*summary\|findings.*報告\|レビュー結果\|review.*findings' "$BASE_DIR/skills/commit/SKILL.md"; then
  pass "commit SKILL.md has findings summary"
else
  fail "commit SKILL.md missing findings summary"
fi

# TC-09: spec reference.ja.md Post-Approve Action has NO Codex plan review, matching
# reference.md
echo ""
echo "TC-09: reference.ja.md Post-Approve Action has no Codex plan review (matches reference.md)"
post_approve_ja=$(sed -n '/## Post-Approve Action/,/^## /p' "$BASE_DIR/skills/spec/reference.ja.md")
has_codex_ja=$(echo "$post_approve_ja" | grep -ci 'codex.*plan.*review\|codex.*exec.*plan' || true)
if [ "$has_codex_ja" -eq 0 ]; then
  pass "reference.ja.md Post-Approve Action has no Codex plan review reference"
else
  fail "reference.ja.md Post-Approve Action still contains Codex plan review (count=$has_codex_ja)"
fi

# TC-10: Existing tests pass (regression)
echo ""
echo "TC-10: Regression tests"
regression_pass=true
for f in "$BASE_DIR"/tests/test-codex-delegation-preference.sh; do
  if [ -f "$f" ]; then
    if ! bash "$f" > /dev/null 2>&1; then
      fail "$(basename "$f") failed"
      regression_pass=false
    fi
  fi
done
if $regression_pass; then
  pass "All regression tests pass"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
