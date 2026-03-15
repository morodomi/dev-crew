#!/bin/bash
# Test: spec template ordering fix + onboard template improvements
# Cycle: 20260315_1500_spec-onboard-improvements

set -euo pipefail

PASS=0
FAIL=0
ERRORS=""

assert() {
  local desc="$1"
  local result="$2"
  if [ "$result" = "true" ]; then
    PASS=$((PASS + 1))
    echo "  PASS: $desc"
  else
    FAIL=$((FAIL + 1))
    ERRORS="${ERRORS}\n  FAIL: $desc"
    echo "  FAIL: $desc"
  fi
}

SPEC_REF="skills/spec/reference.md"
SPEC_JA="skills/spec/reference.ja.md"
ONBOARD_REF="skills/onboard/reference.md"
ONBOARD_SKILL="skills/onboard/SKILL.md"

echo "=== Sub-task 1: spec template ==="

# TC-01: reference.md Workflow行に "sync-plan" が "plan-review" より前にある (v2.0.1)
SYNC_PLAN_POS=$(grep "Workflow:.*TDD" "$SPEC_REF" | grep -ob "sync-plan" 2>/dev/null | head -1 | cut -d: -f1 || echo "999")
PLAN_REVIEW_POS=$(grep "Workflow:.*TDD" "$SPEC_REF" | grep -ob "plan-review" 2>/dev/null | head -1 | cut -d: -f1 || echo "0")
if [ "$SYNC_PLAN_POS" != "999" ] && [ "$SYNC_PLAN_POS" -lt "$PLAN_REVIEW_POS" ] 2>/dev/null; then
  assert "TC-01: Workflow has 'sync-plan' before 'plan-review'" "true"
else
  assert "TC-01: Workflow has 'sync-plan' before 'plan-review'" "false"
fi

# TC-02: reference.ja.md に Plan File Template セクションが存在する
if grep -q "Plan File Template" "$SPEC_JA"; then
  assert "TC-02: reference.ja.md has Plan File Template section" "true"
else
  assert "TC-02: reference.ja.md has Plan File Template section" "false"
fi

# TC-03: reference.ja.md Workflow行に "plan-review" が含まれる
if grep "Workflow:" "$SPEC_JA" | grep -qE "plan-review|plan review|Codex.*review|レビュー"; then
  assert "TC-03: reference.ja.md Workflow has plan review reference" "true"
else
  assert "TC-03: reference.ja.md Workflow has plan review reference" "false"
fi

# TC-04: reference.md Post-Approve Action が orchestrate 単一アクション（3ステップ分離していない）
POST_APPROVE=$(sed -n '/Post-Approve Action/,/```$/p' "$SPEC_REF")
if echo "$POST_APPROVE" | grep -q "orchestrate" && ! echo "$POST_APPROVE" | grep -qE "sync-plan.*RED|RED.*GREEN.*REFACTOR"; then
  assert "TC-04: Post-Approve Action is single orchestrate action" "true"
else
  assert "TC-04: Post-Approve Action is single orchestrate action" "false"
fi

echo ""
echo "=== Sub-task 2: onboard AGENTS.md ==="

# TC-05: onboard/reference.md に "Start Here" パターンが存在する
if grep -qi "Start Here" "$ONBOARD_REF"; then
  assert "TC-05: onboard has Start Here pattern" "true"
else
  assert "TC-05: onboard has Start Here pattern" "false"
fi

# TC-06: onboard/reference.md に `for f in` テストコマンドパターンが存在する
if grep -q "for f in" "$ONBOARD_REF"; then
  assert "TC-06: onboard has 'for f in' test command pattern" "true"
else
  assert "TC-06: onboard has 'for f in' test command pattern" "false"
fi

# TC-07: onboard/reference.md に数値カウントは STATUS.md へのガイダンスがある
if grep -q "STATUS.md" "$ONBOARD_REF" && grep -qiE "count|数値|カウント" "$ONBOARD_REF"; then
  assert "TC-07: onboard has STATUS.md count guidance" "true"
else
  assert "TC-07: onboard has STATUS.md count guidance" "false"
fi

# TC-08: onboard/reference.md に migration note パターンが存在する
if grep -qi "migration" "$ONBOARD_REF" && grep -qi "docs.*migration\|migration.*note\|移行" "$ONBOARD_REF"; then
  assert "TC-08: onboard has migration note pattern" "true"
else
  assert "TC-08: onboard has migration note pattern" "false"
fi

echo ""
echo "=== Sub-task 3: onboard CLAUDE.md + Codex ==="

# TC-09: onboard/reference.md に Codex Integration テンプレートパターンが存在する
if grep -qi "Codex Integration" "$ONBOARD_REF"; then
  assert "TC-09: onboard has Codex Integration template" "true"
else
  assert "TC-09: onboard has Codex Integration template" "false"
fi

# TC-10: onboard/reference.md に Skills trigger table 不要の記述がある
if grep -qiE "trigger table.*不要|trigger table.*unnecessary|スキル.*trigger.*不要" "$ONBOARD_REF"; then
  assert "TC-10: onboard has Skills trigger table unnecessary note" "true"
else
  assert "TC-10: onboard has Skills trigger table unnecessary note" "false"
fi

# TC-11: onboard/reference.md に sync-skills ガイダンスが存在する
if grep -qi "sync-skills\|sync.skills" "$ONBOARD_REF"; then
  assert "TC-11: onboard has sync-skills guidance" "true"
else
  assert "TC-11: onboard has sync-skills guidance" "false"
fi

# TC-12: onboard/reference.md に Codex セッション作成ガイダンスが存在する
if grep -qiE "codex.*session|codex.*セッション|codex exec" "$ONBOARD_REF"; then
  assert "TC-12: onboard has Codex session guidance" "true"
else
  assert "TC-12: onboard has Codex session guidance" "false"
fi

echo ""
echo "=== Constraints + Regression ==="

# TC-13: onboard/SKILL.md が 100行以下
LINE_COUNT=$(wc -l < "$ONBOARD_SKILL")
if [ "$LINE_COUNT" -le 100 ]; then
  assert "TC-13: onboard/SKILL.md <= 100 lines ($LINE_COUNT lines)" "true"
else
  assert "TC-13: onboard/SKILL.md <= 100 lines ($LINE_COUNT lines)" "false"
fi

# TC-14: key existing tests pass
if bash tests/test-plugin-structure.sh > /dev/null 2>&1; then
  assert "TC-14: test-plugin-structure.sh passes" "true"
else
  assert "TC-14: test-plugin-structure.sh passes" "false"
fi

echo ""
echo "================================"
echo "Results: $PASS passed, $FAIL failed"
if [ $FAIL -gt 0 ]; then
  echo -e "Failures:$ERRORS"
  exit 1
fi
