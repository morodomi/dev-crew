#!/bin/bash
# test-onboard-d1d2d3.sh - RED tests for onboard D1-D3
# TC-01 ~ TC-08: Validate pending SKILL.md/reference.md updates and regressions

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

SKILL_FILE="$BASE_DIR/skills/onboard/SKILL.md"
REFERENCE_FILE="$BASE_DIR/skills/onboard/reference.md"

[ -f "$SKILL_FILE" ] || { echo "ERROR: $SKILL_FILE not found"; exit 1; }
[ -f "$REFERENCE_FILE" ] || { echo "ERROR: $REFERENCE_FILE not found"; exit 1; }

SKILL_CONTENT=$(cat "$SKILL_FILE")
REF_CONTENT=$(cat "$REFERENCE_FILE")
STEP1=$(echo "$SKILL_CONTENT" | sed -n '/^### Step 1/,/^### Step 2/p')
STEP9=$(echo "$SKILL_CONTENT" | sed -n '/^### Step 9/,/^## Reference/p')
DEV_CREW_SECTION=$(echo "$REF_CONTENT" | sed -n '/^#### dev-crew-installed モード/,/^### AGENTS.md 必須セクション/p')

echo "=== Onboard D1-D3 RED Tests ==="
echo ""

# TC-01: Given SKILL.md Step 1, When reading project analysis guidance, Then symlink detection is mentioned
echo "TC-01: SKILL.md Step 1 mentions symlink detection"
if echo "$STEP1" | grep -qi "symlink\|シンボリックリンク"; then
  pass "TC-01: symlink detection mentioned in Step 1"
else
  fail "TC-01: symlink detection not mentioned in Step 1"
fi

# TC-02: Given SKILL.md, When checking line budget, Then it is 100 lines or fewer
echo ""
echo "TC-02: SKILL.md is 100 lines or fewer"
LINE_COUNT=$(wc -l < "$SKILL_FILE" | tr -d ' ')
if [ "$LINE_COUNT" -le 100 ]; then
  pass "TC-02: SKILL.md is $LINE_COUNT lines (<= 100)"
else
  fail "TC-02: SKILL.md is $LINE_COUNT lines (exceeds 100 line limit)"
fi

# TC-03: Given SKILL.md Step 9, When reading completion guidance, Then commit instruction exists
echo ""
echo "TC-03: SKILL.md Step 9 has commit guidance"
if echo "$STEP9" | grep -q "コミット"; then
  pass "TC-03: commit guidance found in Step 9"
else
  fail "TC-03: commit guidance not found in Step 9"
fi

# TC-04: Given reference.md dev-crew-installed Step 4, When reading update checks, Then AGENTS.md TDD Workflow overwrite instruction exists
echo ""
echo "TC-04: reference.md dev-crew-installed Step 4 has AGENTS.md TDD Workflow overwrite instruction"
if echo "$DEV_CREW_SECTION" | grep -Eq "AGENTS\.md TDD Workflow.*上書き|TDD Workflow.*AGENTS\.md.*上書き|TDD Workflow.*テンプレート.*置換"; then
  pass "TC-04: AGENTS.md TDD Workflow overwrite instruction found"
else
  fail "TC-04: AGENTS.md TDD Workflow overwrite instruction not found"
fi

# TC-05: Given reference.md dev-crew-installed Step 4, When reading update flow, Then sync-plan update check is described
echo ""
echo "TC-05: reference.md dev-crew-installed section mentions sync-plan update check"
if echo "$DEV_CREW_SECTION" | grep -Eq "sync-plan.*更新チェック|sync-plan.*update"; then
  pass "TC-05: sync-plan update check found in dev-crew-installed section"
else
  fail "TC-05: sync-plan update check not found in dev-crew-installed section"
fi

# TC-06: Given reference.md, When reading AGENTS.md update instructions, Then explicit '新規で上書き' wording exists for AGENTS.md sections
echo ""
echo "TC-06: reference.md explicitly says AGENTS.md sections are overwritten as '新規で上書き'"
if echo "$DEV_CREW_SECTION" | grep -Eq "AGENTS\.md.*新規で上書き|AGENTS\.md セクション.*新規で上書き|セクション.*新規で上書き.*AGENTS\.md"; then
  pass "TC-06: explicit AGENTS.md overwrite wording found"
else
  fail "TC-06: explicit AGENTS.md overwrite wording not found"
fi

# TC-07: Given existing mode detection test, When running, Then it still passes
echo ""
echo "TC-07: existing mode detection regression test passes"
if bash "$BASE_DIR/tests/test-onboard-mode-detection.sh" > /dev/null 2>&1; then
  pass "TC-07: test-onboard-mode-detection.sh passed"
else
  fail "TC-07: test-onboard-mode-detection.sh failed"
fi

# TC-08: Given existing research/discovered tests, When running, Then they still pass
echo ""
echo "TC-08: existing research/discovered regression tests pass"
if bash "$BASE_DIR/tests/test-onboard-research.sh" > /dev/null 2>&1 && \
   bash "$BASE_DIR/tests/test-onboard-discovered.sh" > /dev/null 2>&1; then
  pass "TC-08: test-onboard-research.sh and test-onboard-discovered.sh passed"
else
  fail "TC-08: research/discovered regression test failed"
fi

echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
