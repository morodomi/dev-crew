#!/bin/bash
# test-refactor-rebuild.sh - Refactor skill /simplify removal validation
# TC-01 ~ TC-16

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== Refactor Skill Rebuild Tests ==="

########################################
# refactor skill files
########################################

echo ""
echo "--- refactor skill ---"

# TC-01: refactor/SKILL.md does NOT contain /simplify
echo ""
echo "TC-01: refactor/SKILL.md does NOT contain /simplify"
if grep -q '/simplify' "$BASE_DIR/skills/refactor/SKILL.md"; then
  fail "refactor/SKILL.md still contains /simplify"
else
  pass "refactor/SKILL.md does not contain /simplify"
fi

# TC-02: refactor/SKILL.md contains checklist
echo ""
echo "TC-02: refactor/SKILL.md contains checklist"
if grep -qiE 'チェックリスト|checklist' "$BASE_DIR/skills/refactor/SKILL.md"; then
  pass "refactor/SKILL.md contains checklist"
else
  fail "refactor/SKILL.md does not contain checklist"
fi

########################################
# orchestrate files
########################################

echo ""
echo "--- orchestrate files ---"

# TC-03: orchestrate/SKILL.md does NOT contain /simplify
echo ""
echo "TC-03: orchestrate/SKILL.md does NOT contain /simplify"
if grep -q '/simplify' "$BASE_DIR/skills/orchestrate/SKILL.md"; then
  fail "orchestrate/SKILL.md still contains /simplify"
else
  pass "orchestrate/SKILL.md does not contain /simplify"
fi

# TC-04: orchestrate/reference.md does NOT contain /simplify
echo ""
echo "TC-04: orchestrate/reference.md does NOT contain /simplify"
if grep -q '/simplify' "$BASE_DIR/skills/orchestrate/reference.md"; then
  fail "orchestrate/reference.md still contains /simplify"
else
  pass "orchestrate/reference.md does not contain /simplify"
fi

# TC-05: steps-subagent.md REFACTOR section does NOT contain Skill("simplify")
echo ""
echo "TC-05: steps-subagent.md REFACTOR section does NOT contain Skill(\"simplify\")"
if grep -q 'Skill("simplify")' "$BASE_DIR/skills/orchestrate/steps-subagent.md"; then
  fail "steps-subagent.md still contains Skill(\"simplify\")"
else
  pass "steps-subagent.md does not contain Skill(\"simplify\")"
fi

# TC-06: steps-teams.md REFACTOR section does NOT contain Skill("simplify")
echo ""
echo "TC-06: steps-teams.md REFACTOR section does NOT contain Skill(\"simplify\")"
if grep -q 'Skill("simplify")' "$BASE_DIR/skills/orchestrate/steps-teams.md"; then
  fail "steps-teams.md still contains Skill(\"simplify\")"
else
  pass "steps-teams.md does not contain Skill(\"simplify\")"
fi

# TC-07: steps-codex.md does NOT contain /simplify
echo ""
echo "TC-07: steps-codex.md does NOT contain /simplify"
if grep -q '/simplify' "$BASE_DIR/skills/orchestrate/steps-codex.md"; then
  fail "steps-codex.md still contains /simplify"
else
  pass "steps-codex.md does not contain /simplify"
fi

########################################
# Peripheral docs
########################################

echo ""
echo "--- Peripheral docs ---"

# TC-08: CLAUDE.md does NOT contain /simplify
echo ""
echo "TC-08: CLAUDE.md does NOT contain /simplify"
if grep -q '/simplify' "$BASE_DIR/CLAUDE.md"; then
  fail "CLAUDE.md still contains /simplify"
else
  pass "CLAUDE.md does not contain /simplify"
fi

# TC-09: README.md does NOT contain /simplify
echo ""
echo "TC-09: README.md does NOT contain /simplify"
if grep -q '/simplify' "$BASE_DIR/README.md"; then
  fail "README.md still contains /simplify"
else
  pass "README.md does not contain /simplify"
fi

# TC-10: terminology.md does NOT contain /simplify
echo ""
echo "TC-10: terminology.md does NOT contain /simplify"
if grep -q '/simplify' "$BASE_DIR/docs/terminology.md"; then
  fail "terminology.md still contains /simplify"
else
  pass "terminology.md does not contain /simplify"
fi

# TC-11: reload/SKILL.md does NOT contain /simplify
echo ""
echo "TC-11: reload/SKILL.md does NOT contain /simplify"
if grep -q '/simplify' "$BASE_DIR/skills/reload/SKILL.md"; then
  fail "reload/SKILL.md still contains /simplify"
else
  pass "reload/SKILL.md does not contain /simplify"
fi

# TC-12: reload/reference.md does NOT contain /simplify
echo ""
echo "TC-12: reload/reference.md does NOT contain /simplify"
if grep -q '/simplify' "$BASE_DIR/skills/reload/reference.md"; then
  fail "reload/reference.md still contains /simplify"
else
  pass "reload/reference.md does not contain /simplify"
fi

# TC-13: cycle.md template does NOT contain /simplify
echo ""
echo "TC-13: cycle.md template does NOT contain /simplify"
if grep -q '/simplify' "$BASE_DIR/skills/spec/templates/cycle.md"; then
  fail "cycle.md template still contains /simplify"
else
  pass "cycle.md template does not contain /simplify"
fi

########################################
# Regression
########################################

echo ""
echo "--- Regression ---"

# TC-14: Key existing tests pass (subagent-task-delegation, plugin-structure)
# NOTE: test-doc-consistency.sh excluded to avoid recursive loop (it runs all test-*.sh)
echo ""
echo "TC-14: Key existing tests pass"
existing_fail=0
for test_name in test-subagent-task-delegation.sh test-plugin-structure.sh; do
  test_file="$BASE_DIR/tests/$test_name"
  [ -f "$test_file" ] || continue
  if ! bash "$test_file" > /dev/null 2>&1; then
    fail "Existing test failed: $test_name"
    existing_fail=1
  fi
done
if [ "$existing_fail" -eq 0 ]; then
  pass "Key existing tests pass"
fi

########################################
# Verification Gate + Prohibition
########################################

echo ""
echo "--- Verification Gate + Prohibition ---"

# TC-15: refactor/SKILL.md Verification Gate unchanged
echo ""
echo "TC-15: refactor/SKILL.md Verification Gate unchanged"
if grep -q 'Tests PASS.*lint.*format' "$BASE_DIR/skills/refactor/SKILL.md"; then
  pass "Verification Gate intact"
else
  fail "Verification Gate missing or changed"
fi

# TC-16: refactor/SKILL.md contains prohibition rules
echo ""
echo "TC-16: refactor/SKILL.md contains prohibition rules"
PROHIB_FAIL=0
for term in "テストを壊す" "新機能" "テストの削除"; do
  if ! grep -q "$term" "$BASE_DIR/skills/refactor/SKILL.md"; then
    fail "Missing prohibition: $term"
    PROHIB_FAIL=1
  fi
done
if [ "$PROHIB_FAIL" -eq 0 ]; then
  pass "All prohibition rules present"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
