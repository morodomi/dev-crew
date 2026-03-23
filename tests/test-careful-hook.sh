#!/bin/bash
# test-careful-hook.sh - Tests for careful-guard.sh (PreToolUse Bash hook)
# T-01〜T-13: 破壊コマンド検出・ブロックの決定論的テスト

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GUARD="$SCRIPT_DIR/scripts/hooks/careful-guard.sh"
SKILL_MD="$SCRIPT_DIR/skills/careful/SKILL.md"
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

run_guard() {
  local input="$1"
  echo "$input" | bash "$GUARD" 2>/dev/null
  echo $?
}

# --- T-01〜T-09, T-11〜T-13: exit code 検証 ---

echo "=== careful-guard.sh: exit code tests ==="

# T-01
# Given: rm -rf /tmp/safe (safe path, /tmp is not root or home)
# When: careful-guard.sh に stdin でパイプ
# Then: exit 0 (allowed)
INPUT='{"tool_input":{"command":"rm -rf /tmp/safe"}}'
EXIT=$(run_guard "$INPUT")
assert_eq "T-01: rm -rf /tmp/safe → exit 0 (safe, /tmp is not root)" "0" "$EXIT"

# T-02
# Given: rm -rf / (root deletion)
# When: careful-guard.sh に stdin でパイプ
# Then: exit 2 (blocked)
INPUT='{"tool_input":{"command":"rm -rf /"}}'
EXIT=$(run_guard "$INPUT")
assert_eq "T-02: rm -rf / → exit 2 (blocked)" "2" "$EXIT"

# T-03
# Given: rm -rf ~/ (home deletion)
# When: careful-guard.sh に stdin でパイプ
# Then: exit 2 (blocked)
INPUT='{"tool_input":{"command":"rm -rf ~/"}}'
EXIT=$(run_guard "$INPUT")
assert_eq "T-03: rm -rf ~/ → exit 2 (blocked)" "2" "$EXIT"

# T-04
# Given: DROP TABLE users (DB破壊, 大文字)
# When: careful-guard.sh に stdin でパイプ
# Then: exit 2 (blocked, case-insensitive)
INPUT='{"tool_input":{"command":"DROP TABLE users"}}'
EXIT=$(run_guard "$INPUT")
assert_eq "T-04: DROP TABLE users → exit 2 (blocked, case-insensitive)" "2" "$EXIT"

# T-05
# Given: git push --force origin main
# When: careful-guard.sh に stdin でパイプ
# Then: exit 2 (blocked)
INPUT='{"tool_input":{"command":"git push --force origin main"}}'
EXIT=$(run_guard "$INPUT")
assert_eq "T-05: git push --force origin main → exit 2 (blocked)" "2" "$EXIT"

# T-06
# Given: git push --force-with-lease (safe alternative)
# When: careful-guard.sh に stdin でパイプ
# Then: exit 0 (allowed)
INPUT='{"tool_input":{"command":"git push --force-with-lease"}}'
EXIT=$(run_guard "$INPUT")
assert_eq "T-06: git push --force-with-lease → exit 0 (allowed)" "0" "$EXIT"

# T-07
# Given: git reset --hard HEAD
# When: careful-guard.sh に stdin でパイプ
# Then: exit 2 (blocked)
INPUT='{"tool_input":{"command":"git reset --hard HEAD"}}'
EXIT=$(run_guard "$INPUT")
assert_eq "T-07: git reset --hard HEAD → exit 2 (blocked)" "2" "$EXIT"

# T-08
# Given: kubectl delete pod foo
# When: careful-guard.sh に stdin でパイプ
# Then: exit 2 (blocked)
INPUT='{"tool_input":{"command":"kubectl delete pod foo"}}'
EXIT=$(run_guard "$INPUT")
assert_eq "T-08: kubectl delete pod foo → exit 2 (blocked)" "2" "$EXIT"

# T-09
# Given: echo hello (safe command)
# When: careful-guard.sh に stdin でパイプ
# Then: exit 0 (allowed)
INPUT='{"tool_input":{"command":"echo hello"}}'
EXIT=$(run_guard "$INPUT")
assert_eq "T-09: echo hello → exit 0 (safe command)" "0" "$EXIT"

echo ""
echo "=== careful-guard.sh: additional tests (Codex/Socrates review) ==="

# T-11
# Given: drop table users (小文字, case-insensitive check)
# When: careful-guard.sh に stdin でパイプ
# Then: exit 2 (blocked, case-insensitive)
INPUT='{"tool_input":{"command":"drop table users"}}'
EXIT=$(run_guard "$INPUT")
assert_eq "T-11: drop table users (lowercase) → exit 2 (case-insensitive)" "2" "$EXIT"

# T-12
# Given: git push -f origin main (short flag)
# When: careful-guard.sh に stdin でパイプ
# Then: exit 2 (blocked, short flag)
INPUT='{"tool_input":{"command":"git push -f origin main"}}'
EXIT=$(run_guard "$INPUT")
assert_eq "T-12: git push -f origin main → exit 2 (short flag)" "2" "$EXIT"

# T-13
# Given: DROP DATABASE production
# When: careful-guard.sh に stdin でパイプ
# Then: exit 2 (blocked)
INPUT='{"tool_input":{"command":"DROP DATABASE production"}}'
EXIT=$(run_guard "$INPUT")
assert_eq "T-13: DROP DATABASE production → exit 2 (blocked)" "2" "$EXIT"

# --- T-10: 構造チェック ---

echo ""
echo "=== Structure check ==="

# T-10
# Given: skills/careful/SKILL.md が存在する
# When: frontmatter を確認
# Then: hooks: セクションが存在すること
echo "T-10: Given skills/careful/SKILL.md, When frontmatter check, Then 'hooks:' section exists"

if [ ! -f "$SKILL_MD" ]; then
  echo "FAIL: T-10: skills/careful/SKILL.md not found at $SKILL_MD"
  FAIL=$((FAIL + 1))
elif grep -q '^hooks:' "$SKILL_MD"; then
  echo "PASS: T-10: skills/careful/SKILL.md has 'hooks:' section in frontmatter"
  PASS=$((PASS + 1))
else
  echo "FAIL: T-10: skills/careful/SKILL.md missing 'hooks:' section in frontmatter"
  FAIL=$((FAIL + 1))
fi

# --- Summary ---
echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
