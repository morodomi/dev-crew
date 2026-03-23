#!/bin/bash
# test-onboard-no-verify-hook.sh - Tests for onboard template no-verify-guard hook
# TC-01〜TC-03: recommended.md と onboard reference.md の構造検証

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RECOMMENDED_MD="$SCRIPT_DIR/.claude/hooks/recommended.md"
ONBOARD_REF_MD="$SCRIPT_DIR/skills/onboard/reference.md"
PASS=0
FAIL=0

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo "PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $desc (expected=$expected, actual=$actual)"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== onboard no-verify-guard hook: structure tests ==="

# TC-01
# Given: .claude/hooks/recommended.md が存在する
# When: grep で "no-verify-guard" を検索する
# Then: マッチすること（no-verify-guard.sh への参照が存在する）
if [ -f "$RECOMMENDED_MD" ]; then
  if grep -q "no-verify-guard" "$RECOMMENDED_MD" 2>/dev/null; then
    assert_eq "TC-01: recommended.md contains no-verify-guard" "true" "true"
  else
    assert_eq "TC-01: recommended.md contains no-verify-guard" "true" "false"
  fi
else
  echo "FAIL: TC-01: recommended.md not found at $RECOMMENDED_MD"
  FAIL=$((FAIL + 1))
fi

# TC-02
# Given: .claude/hooks/recommended.md が存在する
# When: JSONブロックを抽出し、PreToolUse/Bash hook エントリを確認する
# Then: no-verify-guard に関連するエントリが存在すること
if [ -f "$RECOMMENDED_MD" ]; then
  # JSON ブロック内に no-verify-guard の記述があるか確認
  # recommended.md 内の ``` ブロックから JSON 断片を抽出して検索
  JSON_CONTENT=$(awk '/^```(json)?$/,/^```$/' "$RECOMMENDED_MD" | grep -v '^```')
  if echo "$JSON_CONTENT" | grep -q "no-verify-guard"; then
    assert_eq "TC-02: recommended.md JSON block has PreToolUse/Bash no-verify-guard entry" "true" "true"
  else
    assert_eq "TC-02: recommended.md JSON block has PreToolUse/Bash no-verify-guard entry" "true" "false"
  fi
else
  echo "FAIL: TC-02: recommended.md not found at $RECOMMENDED_MD"
  FAIL=$((FAIL + 1))
fi

# TC-03
# Given: skills/onboard/reference.md が存在する
# When: Step 6 の hookの説明を確認する
# Then: 「決定論的ブロック」の記述があること
if [ -f "$ONBOARD_REF_MD" ]; then
  # Step 6 セクションを抽出して検索
  STEP6_CONTENT=$(awk '/^## Step 6:/,/^## Step [0-9]/' "$ONBOARD_REF_MD")
  if echo "$STEP6_CONTENT" | grep -q "決定論的ブロック"; then
    assert_eq "TC-03: onboard reference.md Step 6 contains 決定論的ブロック" "true" "true"
  else
    assert_eq "TC-03: onboard reference.md Step 6 contains 決定論的ブロック" "true" "false"
  fi
else
  echo "FAIL: TC-03: onboard reference.md not found at $ONBOARD_REF_MD"
  FAIL=$((FAIL + 1))
fi

# --- Summary ---
echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
