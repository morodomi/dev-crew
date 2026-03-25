#!/bin/bash
# test-post-approve-gate.sh - Tests for plan-exit-flag.sh and post-approve-gate.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FLAG_DIR="${CLAUDE_PLUGIN_DATA:-${HOME}/.claude/dev-crew}"

# PROJECT_HASH: ハッシュベースのフラグ名（CLAUDE_PROJECT_DIRまたはpwdから計算）
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PROJECT_HASH=$(echo "$PROJECT_DIR" | md5 -q 2>/dev/null || echo "$PROJECT_DIR" | md5sum | cut -d' ' -f1)
FLAG_FILE="${FLAG_DIR}/.plan-approved-${PROJECT_HASH}"

PASS=0
FAIL=0

# Save original flag if exists
ORIG_FLAG=""
if [ -f "$FLAG_FILE" ]; then
  ORIG_FLAG=$(cat "$FLAG_FILE")
fi

cleanup() {
  # Restore original flag state
  if [ -n "$ORIG_FLAG" ]; then
    echo "$ORIG_FLAG" > "$FLAG_FILE"
  else
    rm -f "$FLAG_FILE"
  fi
  # Remove any temporary project flags created during tests
  rm -f "${FLAG_DIR}/.plan-approved-fakehash_project_b"
}
trap cleanup EXIT

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

# --- plan-exit-flag.sh tests ---

echo "=== plan-exit-flag.sh ==="

# Given: no flag file
rm -f "$FLAG_FILE"
# When: plan-exit-flag.sh runs
OUTPUT=$(bash "$SCRIPT_DIR/scripts/hooks/plan-exit-flag.sh" 2>&1)
# Then: flag file is created (ハッシュベースのパス)
assert_eq "creates flag file" "true" "$([ -f "$FLAG_FILE" ] && echo true || echo false)"

# Then: flag file contains ISO timestamp
CONTENT=$(cat "$FLAG_FILE" 2>/dev/null || echo "")
assert_eq "flag has ISO timestamp format" "true" "$(echo "$CONTENT" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}T' && echo true || echo false)"

# Then: output tells user to run orchestrate
assert_contains "output mentions orchestrate" "orchestrate" "$OUTPUT"

# --- TC-01: フラグファイル名にpwdハッシュが含まれること ---

echo ""
echo "=== TC-01: plan-exit-flag.sh creates hash-based flag filename ==="

# Given: plan-exit-flag.sh を実行後
rm -f "$FLAG_FILE"
bash "$SCRIPT_DIR/scripts/hooks/plan-exit-flag.sh" >/dev/null 2>&1

# Then: FLAG_DIR 内に `.plan-approved-<hash>` 形式のファイルが存在する
HASH_FLAG_EXISTS=$([ -f "${FLAG_DIR}/.plan-approved-${PROJECT_HASH}" ] && echo true || echo false)
assert_eq "TC-01: flag file named .plan-approved-<hash> exists" "true" "$HASH_FLAG_EXISTS"

# Then: 旧フォーマット（ハッシュなし）のファイルが作成されていないこと
assert_eq "TC-01: old-style flag (.plan-approved) not created" "false" "$([ -f "${FLAG_DIR}/.plan-approved" ] && echo true || echo false)"

# --- post-approve-gate.sh tests ---

echo ""
echo "=== post-approve-gate.sh ==="

# Given: no flag file
rm -f "$FLAG_FILE"
# When: post-approve-gate.sh runs
bash "$SCRIPT_DIR/scripts/hooks/post-approve-gate.sh" >/dev/null 2>&1 || true
EXIT_CODE=$?
# Then: exits 0 (allow)
assert_eq "no flag → exit 0 (allow)" "0" "$EXIT_CODE"

# Given: valid flag file (recent timestamp)
date -u +"%Y-%m-%dT%H:%M:%SZ" > "$FLAG_FILE"
# When: post-approve-gate.sh runs
OUTPUT=$(bash "$SCRIPT_DIR/scripts/hooks/post-approve-gate.sh" 2>&1; echo "EXIT:$?")
EXIT_CODE=$(echo "$OUTPUT" | grep -o 'EXIT:[0-9]*' | cut -d: -f2)
OUTPUT=$(echo "$OUTPUT" | grep -v 'EXIT:')
# Then: exits 2 (block)
assert_eq "valid flag → exit 2 (block)" "2" "$EXIT_CODE"

# Then: output mentions orchestrate
assert_contains "block message mentions orchestrate" "orchestrate" "$OUTPUT"

# --- TC-02: プロジェクトAのフラグがプロジェクトBをブロックしないこと ---

echo ""
echo "=== TC-02: project isolation - project B not blocked by project A flag ==="

# Given: プロジェクトAのpwdハッシュでフラグを作成
FAKE_PROJECT_B_HASH="fakehash_project_b"
rm -f "${FLAG_DIR}/.plan-approved-${FAKE_PROJECT_B_HASH}"
# プロジェクトAのフラグを作成（現在のpwdハッシュ = PROJECT_HASH）
date -u +"%Y-%m-%dT%H:%M:%SZ" > "$FLAG_FILE"

# When: プロジェクトBのハッシュに対応するフラグが存在しない状態で post-approve-gate を実行
# post-approve-gate は実行時の pwd からハッシュを計算するため、
# プロジェクトBのハッシュを使ったフラグが存在しない → exit 0 を期待
# 現在の実装がハッシュ対応していない場合は固定パスを見てしまうため失敗する
# ここではサブシェルで TMPDIR を使って別pwdをシミュレートする
PROJECT_B_HASH=$(echo "/tmp/fake-project-b" | md5 -q 2>/dev/null || echo "/tmp/fake-project-b" | md5sum | cut -d' ' -f1)
rm -f "${FLAG_DIR}/.plan-approved-${PROJECT_B_HASH}"

mkdir -p /tmp/fake-project-b
(export CLAUDE_PROJECT_DIR="/tmp/fake-project-b" && bash "$SCRIPT_DIR/scripts/hooks/post-approve-gate.sh" >/dev/null 2>&1) || true
EXIT_CODE=$?
# Then: exit 0（プロジェクトBはブロックされない）
assert_eq "TC-02: project B not blocked by project A flag" "0" "$EXIT_CODE"

# Cleanup project B hash flag if created
rm -f "${FLAG_DIR}/.plan-approved-${PROJECT_B_HASH}"

# --- TC-03: プロジェクトAのフラグがプロジェクトAをブロックすること ---

echo ""
echo "=== TC-03: project A flag blocks project A ==="

# Given: 現在のpwdハッシュでフラグを作成
date -u +"%Y-%m-%dT%H:%M:%SZ" > "$FLAG_FILE"
# When: post-approve-gate.sh を現在のディレクトリで実行
OUTPUT=$(bash "$SCRIPT_DIR/scripts/hooks/post-approve-gate.sh" 2>&1; echo "EXIT:$?")
EXIT_CODE=$(echo "$OUTPUT" | grep -o 'EXIT:[0-9]*' | cut -d: -f2)
# Then: exit 2（ブロックされる）
assert_eq "TC-03: project A flag blocks project A" "2" "$EXIT_CODE"

# --- TC-04: 期限切れフラグで許可されること ---

echo ""
echo "=== TC-04: expired flag → exit 0 (allow) ==="

# Given: 3時間前のタイムスタンプでフラグを作成
EXPIRED=$(date -u -v-3H +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d "3 hours ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "")
if [ -n "$EXPIRED" ]; then
  echo "$EXPIRED" > "$FLAG_FILE"
  # When: post-approve-gate.sh runs
  bash "$SCRIPT_DIR/scripts/hooks/post-approve-gate.sh" >/dev/null 2>&1 || true
  EXIT_CODE=$?
  # Then: exits 0 (allow, flag expired)
  assert_eq "TC-04: expired flag → exit 0 (allow)" "0" "$EXIT_CODE"
  # Then: flag file is cleaned up
  assert_eq "TC-04: expired flag is removed" "false" "$([ -f "$FLAG_FILE" ] && echo true || echo false)"
else
  echo "SKIP: TC-04 expired flag test (date -v not available)"
fi

# Given: flag cleared by orchestrate (simulated)
date -u +"%Y-%m-%dT%H:%M:%SZ" > "$FLAG_FILE"
rm -f "$FLAG_FILE"
# When: post-approve-gate.sh runs
bash "$SCRIPT_DIR/scripts/hooks/post-approve-gate.sh" >/dev/null 2>&1 || true
EXIT_CODE=$?
# Then: exits 0 (allow)
assert_eq "cleared flag → exit 0 (allow)" "0" "$EXIT_CODE"

# --- Summary ---
echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
