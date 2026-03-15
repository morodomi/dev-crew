#!/bin/bash
# test-v201-fixes.sh - v2.0.1 pre-release fixes
# P0: sync-plan Codex Debate removal + Codex Plan Review integration
# P1: Findings summary after commit
# P2: Codex review always runs; codex_mode controls RED/GREEN only
#
# TC-01: sync-plan.md does NOT have Debate Workflow section
# TC-02: sync-plan.md does NOT have Human Clarification section
# TC-03: spec reference.md Post-Approve Action has Codex plan review (not tied to codex_mode)
# TC-04: steps-subagent.md REVIEW section has Codex competitive review
# TC-05: commit SKILL.md has findings summary step after commit
# TC-06: steps-codex.md states codex_mode controls RED/GREEN only
# TC-07: SKILL.md Mode Selection describes codex_mode as RED/GREEN scope
# TC-08: reference.md TDD Gate codex_mode description says RED/GREEN only
# TC-09: spec reference.ja.md Post-Approve Action matches reference.md
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

# TC-03: spec reference.md Post-Approve Action has Codex plan review NOT tied to codex_mode
echo ""
echo "TC-03: Post-Approve Action Codex plan review not tied to codex_mode"
post_approve=$(sed -n '/## Post-Approve Action/,/^## /p' "$BASE_DIR/skills/spec/reference.md")
# Codex plan review should exist
if ! echo "$post_approve" | grep -qi 'codex.*plan.*review\|codex.*exec.*plan'; then
  fail "Post-Approve Action missing Codex plan review"
# codex_mode should NOT determine plan review (it's about RED/GREEN only)
elif echo "$post_approve" | grep -qi 'codex_mode.*plan.*review\|plan.*review.*codex_mode'; then
  fail "Codex plan review is tied to codex_mode"
else
  pass "Codex plan review exists and is not tied to codex_mode"
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

# TC-06: steps-codex.md states codex_mode controls RED/GREEN only
echo ""
echo "TC-06: steps-codex.md codex_mode scope is RED/GREEN"
if grep -qi 'RED/GREEN\|RED.*GREEN.*のみ\|RED.*GREEN.*only' "$BASE_DIR/skills/orchestrate/steps-codex.md"; then
  pass "steps-codex.md states codex_mode scope is RED/GREEN"
else
  fail "steps-codex.md missing RED/GREEN scope description"
fi

# TC-07: SKILL.md Mode Selection describes codex_mode as RED/GREEN scope
echo ""
echo "TC-07: SKILL.md codex_mode controls RED/GREEN only"
mode_section=$(sed -n '/## Mode Selection/,/^## /p' "$BASE_DIR/skills/orchestrate/SKILL.md")
if echo "$mode_section" | grep -qi 'RED/GREEN\|RED.*GREEN'; then
  pass "SKILL.md Mode Selection describes codex_mode as RED/GREEN"
else
  fail "SKILL.md Mode Selection missing RED/GREEN scope"
fi

# TC-08: reference.md TDD Gate codex_mode says RED/GREEN only
echo ""
echo "TC-08: reference.md TDD Gate codex_mode is RED/GREEN"
tdd_gate=$(sed -n '/## TDD Gate/,/^## /p' "$BASE_DIR/skills/orchestrate/reference.md")
if echo "$tdd_gate" | grep -qi 'RED/GREEN\|RED.*GREEN'; then
  pass "reference.md TDD Gate says codex_mode is RED/GREEN"
else
  fail "reference.md TDD Gate missing RED/GREEN scope"
fi

# TC-09: spec reference.ja.md Post-Approve Action matches reference.md
echo ""
echo "TC-09: reference.ja.md Post-Approve Action matches"
post_approve_ja=$(sed -n '/## Post-Approve Action/,/^## /p' "$BASE_DIR/skills/spec/reference.ja.md")
# Check sync-plan before plan-review (same as reference.md)
sync_ja=$(echo "$post_approve_ja" | grep -n -i 'sync-plan\|Cycle doc' | head -1 | cut -d: -f1)
review_ja=$(echo "$post_approve_ja" | grep -n -i 'plan.review\|Plan review' | head -1 | cut -d: -f1)
# Check Codex plan review exists
has_codex_ja=$(echo "$post_approve_ja" | grep -ci 'codex.*plan.*review\|codex.*exec.*plan' || true)
if [ -n "$sync_ja" ] && [ -n "$review_ja" ] && [ "$sync_ja" -lt "$review_ja" ] && [ "$has_codex_ja" -gt 0 ]; then
  pass "reference.ja.md Post-Approve Action matches"
else
  fail "reference.ja.md Post-Approve Action mismatch (sync=$sync_ja review=$review_ja codex=$has_codex_ja)"
fi

# TC-10: Existing tests pass (regression)
echo ""
echo "TC-10: Regression tests"
regression_pass=true
for f in "$BASE_DIR"/tests/test-orchestrate-codex.sh "$BASE_DIR"/tests/test-codex-delegation-preference.sh; do
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
