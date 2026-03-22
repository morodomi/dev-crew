#!/bin/bash
# test-orchestrate-codex.sh - Verify Codex delegation in orchestrate
# TC-01: steps-codex.md exists
# TC-02: SKILL.md Mode Selection links to steps-codex.md
# TC-03: SKILL.md is under 100 lines
# TC-04: steps-codex.md has `which codex` pre-check
# TC-05: steps-codex.md has Gate 1 (RED fail verification)
# TC-06: steps-codex.md has Gate 2 (GREEN pass verification)
# TC-07: steps-codex.md has `codex exec resume --last` pattern
# TC-08: all codex commands in steps-codex.md have --full-auto
# TC-09: steps-codex.md has Claude Code fallback
# TC-10: steps-codex.md does NOT use `codex review` directly
# TC-11: reference.md has TDD Gate section
# TC-12: ROADMAP.md Phase 4 is DONE

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== Orchestrate Codex Delegation Tests ==="

# TC-01: steps-codex.md exists
echo ""
echo "TC-01: steps-codex.md exists"
if [ -f "$BASE_DIR/skills/orchestrate/steps-codex.md" ]; then
  pass "steps-codex.md exists"
else
  fail "steps-codex.md does not exist"
fi

# TC-02: SKILL.md Mode Selection links to steps-codex.md
echo ""
echo "TC-02: SKILL.md links to steps-codex.md"
if grep -q 'steps-codex\.md' "$BASE_DIR/skills/orchestrate/SKILL.md"; then
  pass "SKILL.md links to steps-codex.md"
else
  fail "SKILL.md does not link to steps-codex.md"
fi

# TC-03: SKILL.md is under 100 lines
echo ""
echo "TC-03: SKILL.md line count"
line_count=$(wc -l < "$BASE_DIR/skills/orchestrate/SKILL.md" | tr -d ' ')
if [ "$line_count" -le 100 ]; then
  pass "SKILL.md is $line_count lines (max 100)"
else
  fail "SKILL.md is $line_count lines (exceeds 100)"
fi

# TC-04: steps-codex.md has `which codex` pre-check
echo ""
echo "TC-04: steps-codex.md has which codex pre-check"
if grep -q 'which codex' "$BASE_DIR/skills/orchestrate/steps-codex.md"; then
  pass "steps-codex.md has which codex pre-check"
else
  fail "steps-codex.md missing which codex pre-check"
fi

# TC-05: steps-codex.md has Gate 1 (RED fail verification)
echo ""
echo "TC-05: steps-codex.md has Gate 1"
if grep -qi 'Gate 1' "$BASE_DIR/skills/orchestrate/steps-codex.md"; then
  pass "steps-codex.md has Gate 1"
else
  fail "steps-codex.md missing Gate 1"
fi

# TC-06: steps-codex.md has Gate 2 (GREEN pass verification)
echo ""
echo "TC-06: steps-codex.md has Gate 2"
if grep -qi 'Gate 2' "$BASE_DIR/skills/orchestrate/steps-codex.md"; then
  pass "steps-codex.md has Gate 2"
else
  fail "steps-codex.md missing Gate 2"
fi

# TC-07: steps-codex.md has `codex exec resume` pattern (--last or <session-id>)
echo ""
echo "TC-07: steps-codex.md has codex exec resume pattern"
if grep -q 'codex exec resume' "$BASE_DIR/skills/orchestrate/steps-codex.md"; then
  pass "steps-codex.md has codex exec resume pattern"
else
  fail "steps-codex.md missing codex exec resume pattern"
fi

# TC-08: all codex exec commands have --full-auto
echo ""
echo "TC-08: all codex exec commands have --full-auto"
# Find lines with "codex exec" that do NOT contain "--full-auto"
bad_lines=$(grep 'codex exec' "$BASE_DIR/skills/orchestrate/steps-codex.md" | grep -v '\-\-full-auto' | grep -v '^#' || true)
if [ -z "$bad_lines" ]; then
  pass "all codex exec commands have --full-auto"
else
  fail "codex exec without --full-auto found: $bad_lines"
fi

# TC-09: steps-codex.md has Claude Code fallback
echo ""
echo "TC-09: steps-codex.md has fallback"
if grep -qi 'fallback\|フォールバック' "$BASE_DIR/skills/orchestrate/steps-codex.md"; then
  pass "steps-codex.md has fallback"
else
  fail "steps-codex.md missing fallback"
fi

# TC-10: steps-codex.md does NOT use `codex review` directly
echo ""
echo "TC-10: steps-codex.md does not use codex review directly"
# Should not have "codex review" as a command (but may mention it in explanatory text with negation)
if grep -qE '^\s*codex review|`codex review`' "$BASE_DIR/skills/orchestrate/steps-codex.md"; then
  fail "steps-codex.md uses codex review directly"
else
  pass "steps-codex.md does not use codex review directly"
fi

# TC-11: reference.md has TDD Gate section
echo ""
echo "TC-11: reference.md has TDD Gate section"
if grep -q '## TDD Gate' "$BASE_DIR/skills/orchestrate/reference.md"; then
  pass "reference.md has TDD Gate section"
else
  fail "reference.md missing TDD Gate section"
fi

# TC-12: ROADMAP.md Phase 4 is DONE (may be in archive)
echo ""
echo "TC-12: ROADMAP.md Phase 4 is DONE"
ARCHIVE="$BASE_DIR/docs/archive/roadmap-v2-v3-completed.md"
if grep -qE 'Phase 4.*DONE|Phase 4.*\(DONE\)' "$BASE_DIR/ROADMAP.md" 2>/dev/null || \
   grep -qE 'Phase 1-5.*完了' "$ARCHIVE" 2>/dev/null; then
  pass "ROADMAP.md Phase 4 is DONE"
else
  fail "ROADMAP.md Phase 4 is not marked DONE"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
