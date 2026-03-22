#!/bin/bash
# test-no-verify-guard.sh - Tests for no-verify-guard.sh (PreToolUse Bash hook)
# TC-01〜TC-12: --no-verify 検出・ブロックの決定論的テスト

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GUARD="$SCRIPT_DIR/scripts/hooks/no-verify-guard.sh"
HOOKS_JSON="$SCRIPT_DIR/hooks/hooks.json"
CLAUDE_MD="$SCRIPT_DIR/CLAUDE.md"
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

assert_contains() {
  local desc="$1" expected="$2" actual="$3"
  if echo "$actual" | grep -q "$expected"; then
    echo "PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $desc (expected to contain '$expected')"
    FAIL=$((FAIL + 1))
  fi
}

run_guard() {
  local input="$1"
  echo "$input" | bash "$GUARD" 2>/dev/null
  echo $?
}

# --- TC-01〜TC-06: exit code 検証 ---

echo "=== no-verify-guard.sh: exit code tests ==="

# TC-01
# Given: --no-verify なしの git commit コマンド
# When: no-verify-guard.sh に stdin でパイプ
# Then: exit 0（許可）
INPUT='{"tool_input":{"command":"git commit -m \"msg\""}}'
EXIT=$(run_guard "$INPUT")
assert_eq "TC-01: git commit without --no-verify → exit 0 (allow)" "0" "$EXIT"

# TC-02
# Given: --no-verify 付きの git commit コマンド
# When: no-verify-guard.sh に stdin でパイプ
# Then: exit 2（ブロック）
INPUT='{"tool_input":{"command":"git commit --no-verify -m \"msg\""}}'
EXIT=$(run_guard "$INPUT")
assert_eq "TC-02: git commit --no-verify → exit 2 (block)" "2" "$EXIT"

# TC-03
# Given: --no-verify 付きの git push コマンド
# When: no-verify-guard.sh に stdin でパイプ
# Then: exit 2（ブロック）
INPUT='{"tool_input":{"command":"git push --no-verify"}}'
EXIT=$(run_guard "$INPUT")
assert_eq "TC-03: git push --no-verify → exit 2 (block)" "2" "$EXIT"

# TC-04
# Given: --no-verify を含む echo コマンド（git 以外）
# When: no-verify-guard.sh に stdin でパイプ
# Then: exit 2（ブロック・安全側。--no-verify 自体を全遮断）
INPUT='{"tool_input":{"command":"echo \"--no-verify\""}}'
EXIT=$(run_guard "$INPUT")
assert_eq "TC-04: echo --no-verify (non-git) → exit 2 (block, safe side)" "2" "$EXIT"

# TC-05
# Given: --no-verify を含む grep コマンド（誤検知候補）
# When: no-verify-guard.sh に stdin でパイプ
# Then: exit 2（ブロック・--no-verify 自体を全遮断）
INPUT='{"tool_input":{"command":"grep --no-verify file.txt"}}'
EXIT=$(run_guard "$INPUT")
assert_eq "TC-05: grep --no-verify (false positive candidate) → exit 2 (block)" "2" "$EXIT"

# TC-06
# Given: 空の入力
# When: no-verify-guard.sh に stdin でパイプ
# Then: exit 0（許可）
EXIT=$(echo "" | bash "$GUARD" 2>/dev/null; echo $?)
assert_eq "TC-06: empty input → exit 0 (allow)" "0" "$EXIT"

# --- TC-07〜TC-09: jq パース検証 ---

echo ""
echo "=== no-verify-guard.sh: JSON parse tests ==="

# TC-07
# Given: ネストされた JSON（tool_input.command に --no-verify）
# When: no-verify-guard.sh に stdin でパイプ
# Then: exit 2（jq パースで検出・ブロック）
INPUT='{"session_id":"abc","tool_name":"Bash","tool_input":{"command":"git commit --no-verify"}}'
EXIT=$(run_guard "$INPUT")
assert_eq "TC-07: nested JSON with --no-verify → exit 2 (jq parse)" "2" "$EXIT"

# TC-08
# Given: pretty-print JSON（改行・インデント付き）で --no-verify を含む
# When: no-verify-guard.sh に stdin でパイプ
# Then: exit 2（フォーマット耐性）
INPUT=$(printf '{\n  "tool_input": {\n    "command": "git commit --no-verify -m msg"\n  }\n}')
EXIT=$(echo "$INPUT" | bash "$GUARD" 2>/dev/null; echo $?)
assert_eq "TC-08: pretty-print JSON with --no-verify → exit 2 (format tolerance)" "2" "$EXIT"

# TC-09
# Given: jq が不在の状況を模擬（PATH から jq を除外）
#        stdin には --no-verify を含む JSON
# When: no-verify-guard.sh に stdin でパイプ（jq 不在の PATH で）
# Then: exit 2（INPUT 全体への grep フォールバックで検出・ブロック）
INPUT='{"tool_input":{"command":"git commit --no-verify -m msg"}}'
EXIT=$(echo "$INPUT" | NO_VERIFY_GUARD_SKIP_JQ=1 bash "$GUARD" 2>/dev/null; echo $?)
assert_eq "TC-09: jq absent → fallback grep detects --no-verify → exit 2" "2" "$EXIT"

# --- TC-10〜TC-12: 構造チェック ---

echo ""
echo "=== Structure checks ==="

# TC-10
# Given: hooks/hooks.json が存在する
# When: no-verify-guard エントリを検索
# Then: no-verify-guard.sh への参照が存在する
if [ -f "$HOOKS_JSON" ]; then
  if grep -q "no-verify-guard" "$HOOKS_JSON" 2>/dev/null; then
    assert_eq "TC-10: hooks.json has no-verify-guard entry" "true" "true"
  else
    assert_eq "TC-10: hooks.json has no-verify-guard entry" "true" "false"
  fi
else
  echo "FAIL: TC-10: hooks.json not found at $HOOKS_JSON"
  FAIL=$((FAIL + 1))
fi

# TC-11
# Given: hooks/hooks.json が存在する
# When: post-approve-gate と no-verify-guard の両エントリを検索
# Then: 両方のエントリが共存している（既存 hook が保護されている）
if [ -f "$HOOKS_JSON" ]; then
  HAS_GATE=false
  HAS_GUARD=false
  grep -q "post-approve-gate" "$HOOKS_JSON" 2>/dev/null && HAS_GATE=true
  grep -q "no-verify-guard" "$HOOKS_JSON" 2>/dev/null && HAS_GUARD=true
  if [ "$HAS_GATE" = "true" ] && [ "$HAS_GUARD" = "true" ]; then
    assert_eq "TC-11: hooks.json has both post-approve-gate and no-verify-guard entries" "true" "true"
  else
    assert_eq "TC-11: hooks.json has both post-approve-gate and no-verify-guard entries" "true" "false"
  fi
else
  echo "FAIL: TC-11: hooks.json not found at $HOOKS_JSON"
  FAIL=$((FAIL + 1))
fi

# TC-12
# Given: CLAUDE.md が存在する
# When: Hooks テーブルから no-verify-guard を検索
# Then: no-verify-guard の行が存在する
if [ -f "$CLAUDE_MD" ]; then
  if grep -q "no-verify-guard" "$CLAUDE_MD" 2>/dev/null; then
    assert_eq "TC-12: CLAUDE.md Hooks table has no-verify-guard entry" "true" "true"
  else
    assert_eq "TC-12: CLAUDE.md Hooks table has no-verify-guard entry" "true" "false"
  fi
else
  echo "FAIL: TC-12: CLAUDE.md not found at $CLAUDE_MD"
  FAIL=$((FAIL + 1))
fi

# --- Summary ---
echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
