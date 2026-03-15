#!/bin/bash
# test-agents-md-propagation.sh - AGENTS.md propagation tests across skills
# TC-08 ~ TC-11, TC-14

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

COMMIT_SKILL="$BASE_DIR/skills/commit/SKILL.md"
STALENESS_HOOK="$BASE_DIR/scripts/hooks/check-claude-md-staleness.sh"
SKILLS_STRUCTURE_TEST="$BASE_DIR/tests/test-skills-structure.sh"

for f in "$COMMIT_SKILL" "$STALENESS_HOOK" "$SKILLS_STRUCTURE_TEST"; do
  [ -f "$f" ] || { echo "ERROR: $f not found"; exit 1; }
done

echo "=== AGENTS.md Propagation Tests ==="
echo ""

# TC-08: Given commit/SKILL.md, When reading doc table, Then AGENTS.md is listed
echo "TC-08: commit/SKILL.md doc update table has AGENTS.md"
if grep -q "AGENTS.md" "$COMMIT_SKILL"; then
  pass "TC-08: AGENTS.md found in commit/SKILL.md"
else
  fail "TC-08: AGENTS.md not found in commit/SKILL.md"
fi

# TC-10: Given staleness hook, When AGENTS.md exists, Then both AGENTS.md and CLAUDE.md are checked
echo ""
echo "TC-10: staleness hook checks both AGENTS.md and CLAUDE.md"
HOOK_CONTENT=$(cat "$STALENESS_HOOK")
if echo "$HOOK_CONTENT" | grep -q "AGENTS.md" && echo "$HOOK_CONTENT" | grep -q "CLAUDE.md"; then
  pass "TC-10: both AGENTS.md and CLAUDE.md referenced in hook"
else
  fail "TC-10: hook does not reference both AGENTS.md and CLAUDE.md"
fi

# TC-11: Given staleness hook, When AGENTS.md not exists, Then only CLAUDE.md is checked (backward compat)
echo ""
echo "TC-11: staleness hook has AGENTS.md-absent fallback to CLAUDE.md only"
# check_staleness function handles missing files via [ -f "$file" ] || return 0
if echo "$HOOK_CONTENT" | grep -q 'check_staleness' && echo "$HOOK_CONTENT" | grep -q '\[ -f "\$file" \]\|"\$file".*return'; then
  pass "TC-11: check_staleness handles missing files gracefully"
else
  fail "TC-11: check_staleness missing file guard not found in hook"
fi

# TC-14: Given test-skills-structure.sh TC-B1/TC-B2, When grep target changed, Then AGENTS.md is target
echo ""
echo "TC-14: test-skills-structure.sh TC-B1/TC-B2 grep targets AGENTS.md"
# TC-B1 and TC-B2 should grep AGENTS.md, not CLAUDE.md for agent counts
B1_SECTION=$(sed -n '/TC-B1/,/TC-B2/p' "$SKILLS_STRUCTURE_TEST")
B2_SECTION=$(sed -n '/TC-B2/,/Summary/p' "$SKILLS_STRUCTURE_TEST")
B1_TARGET=$(echo "$B1_SECTION" | grep -o 'AGENTS\.md\|CLAUDE\.md' | grep -c "AGENTS.md" || true)
B2_TARGET=$(echo "$B2_SECTION" | grep -o 'AGENTS\.md\|CLAUDE\.md' | grep -c "AGENTS.md" || true)
if [ "$B1_TARGET" -gt 0 ] && [ "$B2_TARGET" -gt 0 ]; then
  pass "TC-14: TC-B1/TC-B2 grep AGENTS.md"
else
  fail "TC-14: TC-B1/TC-B2 not targeting AGENTS.md (B1=$B1_TARGET, B2=$B2_TARGET)"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
