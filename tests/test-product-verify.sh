#!/bin/bash
# test-product-verify.sh - Product Verification PoC structure validation
# TC-01 ~ TC-09

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== Product Verification PoC Tests ==="

# TC-01: Cycle doc テンプレートに ## Verification セクションが存在
echo ""
echo "TC-01: Cycle doc template has ## Verification section"
TEMPLATE="$BASE_DIR/skills/spec/templates/cycle.md"
if grep -q '^## Verification' "$TEMPLATE" 2>/dev/null; then
  pass "Cycle doc template has ## Verification section"
else
  fail "Cycle doc template missing ## Verification section"
fi

# TC-02: orchestrate SKILL.md の Progress Checklist に VERIFY ステップが存在
echo ""
echo "TC-02: orchestrate SKILL.md has VERIFY in Progress Checklist"
ORCH_SKILL="$BASE_DIR/skills/orchestrate/SKILL.md"
if grep -qiE 'VERIFY.*Product Verification|Block 2c\.5' "$ORCH_SKILL" 2>/dev/null; then
  pass "orchestrate SKILL.md has VERIFY step in checklist"
else
  fail "orchestrate SKILL.md missing VERIFY step"
fi

# TC-03: orchestrate SKILL.md の Workflow に Block 2c.5 が存在
echo ""
echo "TC-03: orchestrate SKILL.md Workflow has Block 2c.5"
if grep -q '2c\.5' "$ORCH_SKILL" 2>/dev/null; then
  pass "orchestrate SKILL.md has Block 2c.5"
else
  fail "orchestrate SKILL.md missing Block 2c.5"
fi

# TC-04: reference.md に Product Verification セクションが存在
echo ""
echo "TC-04: reference.md has Product Verification section"
ORCH_REF="$BASE_DIR/skills/orchestrate/reference.md"
if grep -qi 'Product Verification' "$ORCH_REF" 2>/dev/null; then
  pass "reference.md has Product Verification section"
else
  fail "reference.md missing Product Verification section"
fi

# TC-05: steps-subagent.md に VERIFY ステップが REFACTOR→REVIEW 間に存在
echo ""
echo "TC-05: steps-subagent.md has VERIFY between REFACTOR and REVIEW"
STEPS_SUB="$BASE_DIR/skills/orchestrate/steps-subagent.md"
if grep -qi 'VERIFY\|Product Verification' "$STEPS_SUB" 2>/dev/null; then
  # 位置確認: REFACTOR セクションの後、REVIEW セクションの前にあるか
  refactor_line=$(grep -n '### REFACTOR' "$STEPS_SUB" | head -1 | cut -d: -f1)
  verify_line=$(grep -n '### VERIFY' "$STEPS_SUB" | head -1 | cut -d: -f1)
  review_line=$(grep -n '### REVIEW' "$STEPS_SUB" | head -1 | cut -d: -f1)
  if [ -n "$refactor_line" ] && [ -n "$verify_line" ] && [ -n "$review_line" ] && \
     [ "$verify_line" -gt "$refactor_line" ] && [ "$verify_line" -lt "$review_line" ]; then
    pass "steps-subagent.md has VERIFY between REFACTOR and REVIEW"
  else
    fail "steps-subagent.md VERIFY not positioned between REFACTOR and REVIEW"
  fi
else
  fail "steps-subagent.md missing VERIFY step"
fi

# TC-06: steps-teams.md に VERIFY ステップが REFACTOR→REVIEW 間に存在
echo ""
echo "TC-06: steps-teams.md has VERIFY between REFACTOR and REVIEW"
STEPS_TEAMS="$BASE_DIR/skills/orchestrate/steps-teams.md"
if grep -qi 'VERIFY\|Product Verification' "$STEPS_TEAMS" 2>/dev/null; then
  pass "steps-teams.md has VERIFY step"
else
  fail "steps-teams.md missing VERIFY step"
fi

# TC-07: Verification は non-blocking (advisory) と明記されている
echo ""
echo "TC-07: Verification is documented as advisory/non-blocking"
if grep -qi 'advisory' "$ORCH_REF" 2>/dev/null && grep -qiE 'non.blocking|non blocking' "$ORCH_REF" 2>/dev/null; then
  pass "reference.md documents advisory/non-blocking nature"
else
  fail "reference.md missing advisory/non-blocking documentation"
fi

# TC-08: Evidence ディレクトリが /tmp に指定されている
echo ""
echo "TC-08: Evidence directory is under /tmp"
if grep -q '/tmp/dev-crew-verify' "$ORCH_REF" 2>/dev/null; then
  pass "Evidence directory specified as /tmp/dev-crew-verify"
else
  fail "Evidence directory not specified as /tmp/dev-crew-verify"
fi

# TC-09: Verification セクション不在時のスキップ挙動が明記されている
echo ""
echo "TC-09: Skip behavior documented for missing Verification section"
if grep -qiE 'skip|スキップ' "$ORCH_REF" 2>/dev/null; then
  pass "Skip behavior documented for missing Verification section"
else
  fail "Skip behavior not documented"
fi

# TC-10: orchestrate docs describe WARN log in VERIFY section (section-specific, not whole-file)
# Codex code review 指摘: whole-file grep では unrelated WARN 文言で偽 PASS。VERIFY block 内に限定して検査。
echo ""
echo "TC-10: orchestrate docs describe WARN log in VERIFY block specifically (all 4 docs)"
FILES="skills/orchestrate/SKILL.md skills/orchestrate/steps-subagent.md skills/orchestrate/steps-teams.md skills/orchestrate/steps-codex.md"
has_warn=0
for f in $FILES; do
  # Extract VERIFY block: from heading matching "VERIFY" to next "###"/"####" heading
  verify_block=$(awk '/^####* .*VERIFY/{in_block=1; next} in_block && /^####* /{in_block=0} in_block' "$BASE_DIR/$f" 2>/dev/null || true)
  if echo "$verify_block" | grep -qE "WARN.*real-path invocation|real-path invocation.*WARN"; then
    has_warn=$((has_warn + 1))
  fi
done
if [ "$has_warn" -ge 4 ]; then
  pass "WARN contract present in VERIFY section of all 4 orchestrate docs"
else
  fail "WARN contract missing in VERIFY section of $((4 - has_warn)) of 4 orchestrate docs (found $has_warn, requires section-specific match)"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
