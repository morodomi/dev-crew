#!/bin/bash
# test-codex-session-unify.sh - Verify Codex session management unification (#52)
# TC-01: steps-codex.md Session Management contains "plan review"
# TC-02: steps-codex.md Session Management does NOT contain "debate"
# TC-03: steps-codex.md RED section does NOT have `codex exec --full-auto` (new session)
# TC-04: steps-codex.md RED section has `codex exec resume --last`
# TC-05: all codex exec commands in steps-codex.md have --full-auto
# TC-06: CLAUDE.md Codex patterns consistent with steps-codex.md (RED = resume --last)
# TC-07: existing test-orchestrate-codex.sh passes (regression)

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
STEPS_CODEX="$BASE_DIR/skills/orchestrate/steps-codex.md"
CLAUDE_MD="$BASE_DIR/CLAUDE.md"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

# Extract section between two ## headings (macOS compatible)
extract_section() {
  local file="$1" start_pattern="$2"
  sed -n "/${start_pattern}/,/^## /p" "$file" | sed '$d'
}

# Extract section between two ### headings (macOS compatible)
extract_subsection() {
  local file="$1" start_pattern="$2"
  sed -n "/${start_pattern}/,/^### /p" "$file" | sed '$d'
}

echo "=== Codex Session Unification Tests (#52) ==="

# TC-01: Session Management contains "plan review"
echo ""
echo "TC-01: Session Management contains 'plan review'"
session_section=$(extract_section "$STEPS_CODEX" "^## Session Management")
if echo "$session_section" | grep -qi 'plan review'; then
  pass "Session Management mentions plan review"
else
  fail "Session Management does not mention plan review"
fi

# TC-02: Session Management does NOT contain "debate"
echo ""
echo "TC-02: Session Management does NOT contain 'debate'"
if echo "$session_section" | grep -qi 'debate'; then
  fail "Session Management still mentions debate"
else
  pass "Session Management does not mention debate"
fi

# TC-03: RED section does NOT have `codex exec --full-auto` (new session pattern)
echo ""
echo "TC-03: RED section has no new session (codex exec --full-auto without resume)"
red_section=$(extract_subsection "$STEPS_CODEX" "^### RED via Codex")
# Find lines with "codex exec" that do NOT contain "resume" (= new session)
bad=$(echo "$red_section" | grep 'codex exec' | grep -v 'resume' || true)
if [ -n "$bad" ]; then
  fail "RED section has new session pattern: $bad"
else
  pass "RED section has no new session pattern"
fi

# TC-04: RED section has `codex exec resume` pattern (--last or <session-id>)
echo ""
echo "TC-04: RED section has codex exec resume pattern"
if echo "$red_section" | grep -q 'codex exec resume'; then
  pass "RED section has codex exec resume pattern"
else
  fail "RED section missing codex exec resume pattern"
fi

# TC-05: all codex exec commands have --full-auto
echo ""
echo "TC-05: all codex exec commands have --full-auto"
bad_lines=$(grep 'codex exec' "$STEPS_CODEX" | grep -v '\-\-full-auto' | grep -v '^#' || true)
if [ -z "$bad_lines" ]; then
  pass "all codex exec commands have --full-auto"
else
  fail "codex exec without --full-auto found: $bad_lines"
fi

# TC-06: CLAUDE.md RED pattern uses resume (--last or <session-id>, consistent with steps-codex.md)
echo ""
echo "TC-06: CLAUDE.md RED pattern uses resume"
if grep -q 'codex exec resume.*red\|red.*codex exec resume' "$CLAUDE_MD" || \
   grep -A1 'RED.*GREEN.*REVIEW' "$CLAUDE_MD" | grep -q 'resume'; then
  pass "CLAUDE.md RED pattern uses resume"
else
  fail "CLAUDE.md RED pattern inconsistent"
fi

# TC-07: existing test-orchestrate-codex.sh passes (regression)
echo ""
echo "TC-07: regression - test-orchestrate-codex.sh"
if bash "$BASE_DIR/tests/test-orchestrate-codex.sh" > /dev/null 2>&1; then
  pass "test-orchestrate-codex.sh passes"
else
  fail "test-orchestrate-codex.sh failed (regression)"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
