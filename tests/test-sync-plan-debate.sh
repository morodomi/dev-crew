#!/bin/bash
# test-sync-plan-debate.sh - sync-plan structure validation (post-v2.0.1)
# Debate Workflow was removed in v2.0.1. Codex Plan Review moved to Post-Approve Action.
# TC-01: sync-plan.md exists and has content
# TC-02: sync-plan.md does NOT have Debate Workflow (removed in v2.0.1)
# TC-03: sync-plan.md has Cycle doc generation workflow
# TC-04: sync-plan.md has Frontmatter Initialization
# TC-05: sync-plan.md notes that Codex Plan Review is in Post-Approve Action

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
AGENT_MD="$BASE_DIR/agents/sync-plan.md"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== Sync-Plan Structure Tests ==="

# TC-01: sync-plan.md exists and has content
echo ""
echo "TC-01: sync-plan.md exists"
line_count=$(wc -l < "$AGENT_MD" | tr -d ' ')
if [ "$line_count" -gt 10 ]; then
  pass "sync-plan.md is $line_count lines"
else
  fail "sync-plan.md is only $line_count lines (too small)"
fi

# TC-02: sync-plan.md does NOT have Debate Workflow
echo ""
echo "TC-02: No Debate Workflow (removed in v2.0.1)"
if grep -q '## Debate Workflow' "$AGENT_MD"; then
  fail "sync-plan.md still has Debate Workflow"
else
  pass "Debate Workflow removed"
fi

# TC-03: sync-plan.md has Cycle doc generation workflow
echo ""
echo "TC-03: Cycle doc generation workflow"
if grep -q 'Generate Cycle Doc\|Cycle doc' "$AGENT_MD" && grep -q 'Test List' "$AGENT_MD"; then
  pass "Has Cycle doc generation and Test List transfer"
else
  fail "Missing Cycle doc generation workflow"
fi

# TC-04: sync-plan.md has Frontmatter Initialization
echo ""
echo "TC-04: Frontmatter Initialization"
if grep -q 'Frontmatter Initialization\|frontmatter' "$AGENT_MD"; then
  pass "Has Frontmatter Initialization"
else
  fail "Missing Frontmatter Initialization"
fi

# TC-05: sync-plan.md notes Codex Plan Review location
echo ""
echo "TC-05: Codex Plan Review is in Post-Approve Action"
if grep -qi 'Post-Approve Action\|Codex Plan Review' "$AGENT_MD"; then
  pass "Notes that Codex Plan Review is in Post-Approve Action"
else
  fail "Missing Post-Approve Action reference"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
