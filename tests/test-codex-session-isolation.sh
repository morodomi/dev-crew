#!/bin/bash
# test-codex-session-isolation.sh - Verify Codex session isolation with Cycle ID-based binding (#55)
# TC-01: Cycle doc template has codex_session_id in frontmatter
# TC-02: sync-plan.md Frontmatter Initialization has codex_session_id
# TC-03: orchestrate/reference.md Session Management mentions codex_session_id
# TC-04: orchestrate/reference.md Session Management states orchestrate does not resume (resume しない)
# TC-08: steps-teams.md REVIEW section has session-id or fallback pattern
# TC-09: steps-subagent.md REVIEW section has session-id or fallback pattern
# TC-10: CLAUDE.md records codex_session_id
# TC-11: reference.md has Session Management section

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

# TC-03: orchestrate/reference.md Session Management mentions codex_session_id
echo ""
echo "TC-03: orchestrate/reference.md Session Management mentions codex_session_id"
session_section=$(sed -n '/^## Session Management/,/^## /p' "$BASE_DIR/skills/orchestrate/reference.md" | sed '$d')
if echo "$session_section" | grep -q 'codex_session_id'; then
  pass "Session Management mentions codex_session_id"
else
  fail "Session Management does not mention codex_session_id"
fi

# TC-04: orchestrate/reference.md Session Management states orchestrate does not resume
echo ""
echo "TC-04: orchestrate/reference.md Session Management states resume しない"
if echo "$session_section" | grep -qF 'resume しない'; then
  pass "Session Management states resume しない"
else
  fail "Session Management does not state resume しない"
fi

# TC-08: steps-teams.md REVIEW section は codex_session_id で resume せず、新しいセッションでレビューする（実装者の自己レビュー防止）
echo ""
echo "TC-08: steps-teams.md REVIEW uses a new session (no resume), pointing at the exception"
review_section=$(sed -n '/^### REVIEW/,/^### Phase Summary/p' "$BASE_DIR/skills/orchestrate/steps-teams.md" | sed '$d')
if echo "$review_section" | grep -q '`resume` しない' && ! echo "$review_section" | grep -q 'codex exec .*resume'; then
  pass "steps-teams.md REVIEW states the new-session exception"
else
  fail "steps-teams.md REVIEW missing the new-session exception"
fi

# TC-09: steps-subagent.md REVIEW section も同じ（新しいセッション）
echo ""
echo "TC-09: steps-subagent.md REVIEW uses a new session (no resume), pointing at the exception"
review_section_sub=$(sed -n '/^### REVIEW/,/^### Phase Summary/p' "$BASE_DIR/skills/orchestrate/steps-subagent.md" | sed '$d')
if echo "$review_section_sub" | grep -q '`resume` しない' && ! echo "$review_section_sub" | grep -q 'codex exec .*resume'; then
  pass "steps-subagent.md REVIEW states the new-session exception"
else
  fail "steps-subagent.md REVIEW missing the new-session exception"
fi

# TC-10: CLAUDE.md records codex_session_id
echo ""
echo "TC-10: CLAUDE.md records codex_session_id"
if grep -q 'codex_session_id' "$BASE_DIR/CLAUDE.md"; then
  pass "CLAUDE.md records codex_session_id"
else
  fail "CLAUDE.md missing codex_session_id"
fi

# TC-11: reference.md has Session Management section
echo ""
echo "TC-11: reference.md has Session Management section"
if grep -q '## Session Management' "$BASE_DIR/skills/orchestrate/reference.md"; then
  pass "reference.md has Session Management section"
else
  fail "reference.md missing Session Management section"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
