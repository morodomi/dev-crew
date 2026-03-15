#!/bin/bash
# test-codex-session-isolation.sh - Verify Codex session isolation with Cycle ID-based binding (#55)
# TC-01: Cycle doc template has codex_session_id in frontmatter
# TC-02: sync-plan.md Frontmatter Initialization has codex_session_id
# TC-03: steps-codex.md Session Management mentions codex_session_id
# TC-04: steps-codex.md Session Management mentions frontmatter
# TC-05: steps-codex.md has `resume <session-id>` pattern
# TC-06: steps-codex.md has fallback to resume --last
# TC-07: steps-codex.md does NOT have "並行.*実行禁止" (hard prohibition removed)
# TC-08: steps-teams.md REVIEW section has session-id or fallback pattern
# TC-09: steps-subagent.md REVIEW section has session-id or fallback pattern
# TC-10: CLAUDE.md has session-id pattern
# TC-11: reference.md has Session Management section
# TC-12: test-orchestrate-codex.sh passes (regression)
# TC-13: test-codex-session-unify.sh passes (regression)

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== Codex Session Isolation Tests (#55) ==="

# TC-01: Cycle doc template has codex_session_id in frontmatter
echo ""
echo "TC-01: Cycle doc template has codex_session_id in frontmatter"
if grep -q 'codex_session_id' "$BASE_DIR/skills/spec/templates/cycle.md"; then
  pass "cycle.md template has codex_session_id"
else
  fail "cycle.md template missing codex_session_id"
fi

# TC-02: sync-plan.md Frontmatter Initialization has codex_session_id
echo ""
echo "TC-02: sync-plan.md Frontmatter Initialization has codex_session_id"
if grep -q 'codex_session_id' "$BASE_DIR/agents/sync-plan.md"; then
  pass "sync-plan.md has codex_session_id"
else
  fail "sync-plan.md missing codex_session_id"
fi

# TC-03: steps-codex.md Session Management mentions codex_session_id
echo ""
echo "TC-03: steps-codex.md Session Management mentions codex_session_id"
session_section=$(sed -n '/^## Session Management/,/^## /p' "$BASE_DIR/skills/orchestrate/steps-codex.md" | sed '$d')
if echo "$session_section" | grep -q 'codex_session_id'; then
  pass "Session Management mentions codex_session_id"
else
  fail "Session Management does not mention codex_session_id"
fi

# TC-04: steps-codex.md Session Management mentions frontmatter
echo ""
echo "TC-04: steps-codex.md Session Management mentions frontmatter"
if echo "$session_section" | grep -qi 'frontmatter'; then
  pass "Session Management mentions frontmatter"
else
  fail "Session Management does not mention frontmatter"
fi

# TC-05: steps-codex.md has `resume <session-id>` pattern
echo ""
echo "TC-05: steps-codex.md has resume <session-id> pattern"
if grep -q 'resume <session-id>' "$BASE_DIR/skills/orchestrate/steps-codex.md" || \
   grep -q 'resume.*session.id' "$BASE_DIR/skills/orchestrate/steps-codex.md"; then
  pass "steps-codex.md has resume <session-id> pattern"
else
  fail "steps-codex.md missing resume <session-id> pattern"
fi

# TC-06: steps-codex.md has fallback to resume --last
echo ""
echo "TC-06: steps-codex.md has fallback to resume --last"
if grep -q 'resume --last' "$BASE_DIR/skills/orchestrate/steps-codex.md"; then
  pass "steps-codex.md has fallback to resume --last"
else
  fail "steps-codex.md missing fallback to resume --last"
fi

# TC-07: steps-codex.md does NOT have "並行.*実行禁止" (hard prohibition removed)
echo ""
echo "TC-07: steps-codex.md does NOT have hard prohibition on parallel execution"
if grep -q '並行.*実行禁止' "$BASE_DIR/skills/orchestrate/steps-codex.md"; then
  fail "steps-codex.md still has hard prohibition on parallel execution"
else
  pass "steps-codex.md does not have hard prohibition"
fi

# TC-08: steps-teams.md REVIEW section has session-id or fallback pattern
echo ""
echo "TC-08: steps-teams.md REVIEW has session-id or fallback pattern"
review_section=$(sed -n '/^### REVIEW/,/^## /p' "$BASE_DIR/skills/orchestrate/steps-teams.md" | sed '$d')
if echo "$review_section" | grep -q 'codex_session_id\|resume <session-id>'; then
  pass "steps-teams.md REVIEW has session-id pattern"
else
  fail "steps-teams.md REVIEW missing session-id pattern"
fi

# TC-09: steps-subagent.md REVIEW section has session-id or fallback pattern
echo ""
echo "TC-09: steps-subagent.md REVIEW has session-id or fallback pattern"
review_section_sub=$(sed -n '/^### REVIEW/,/^## /p' "$BASE_DIR/skills/orchestrate/steps-subagent.md" | sed '$d')
if echo "$review_section_sub" | grep -q 'codex_session_id\|resume <session-id>'; then
  pass "steps-subagent.md REVIEW has session-id pattern"
else
  fail "steps-subagent.md REVIEW missing session-id pattern"
fi

# TC-10: CLAUDE.md has session-id pattern
echo ""
echo "TC-10: CLAUDE.md has session-id pattern"
if grep -q 'resume <session-id>\|resume.*session.id\|codex_session_id' "$BASE_DIR/CLAUDE.md"; then
  pass "CLAUDE.md has session-id pattern"
else
  fail "CLAUDE.md missing session-id pattern"
fi

# TC-11: reference.md has Session Management section
echo ""
echo "TC-11: reference.md has Session Management section"
if grep -q '## Session Management' "$BASE_DIR/skills/orchestrate/reference.md"; then
  pass "reference.md has Session Management section"
else
  fail "reference.md missing Session Management section"
fi

# TC-12: test-orchestrate-codex.sh passes (regression)
echo ""
echo "TC-12: regression - test-orchestrate-codex.sh"
if bash "$BASE_DIR/tests/test-orchestrate-codex.sh" > /dev/null 2>&1; then
  pass "test-orchestrate-codex.sh passes"
else
  fail "test-orchestrate-codex.sh failed (regression)"
fi

# TC-13: test-codex-session-unify.sh passes (regression)
echo ""
echo "TC-13: regression - test-codex-session-unify.sh"
if bash "$BASE_DIR/tests/test-codex-session-unify.sh" > /dev/null 2>&1; then
  pass "test-codex-session-unify.sh passes"
else
  fail "test-codex-session-unify.sh failed (regression)"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
