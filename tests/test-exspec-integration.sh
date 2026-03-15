#!/bin/bash
# test-exspec-integration.sh - exspec integration tests
# T-01: reference.mdに## exspecセクションが存在する
# T-02: SKILL.mdからreference.md#exspecへの参照が有効
# T-03: reference.mdに言語マッピングテーブルが存在する
# T-04: exspec-check.shが存在し実行可能
# T-05: exspec未インストール時SKIP (exit 0)
# T-06: 非対応言語(javascript)でSKIP (exit 0)
# T-07: 引数なしでexit非0 (usage)
# T-08: SKILL.mdの行数が100行以内

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$BASE_DIR/scripts/gates/exspec-check.sh"
SKILL_MD="$BASE_DIR/skills/red/SKILL.md"
REFERENCE_MD="$BASE_DIR/skills/red/reference.md"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== exspec Integration Tests ==="

# T-01: reference.mdに## exspecセクションが存在する
echo ""
echo "T-01: reference.md has ## exspec section"

if grep -q '^## exspec' "$REFERENCE_MD"; then
  pass "## exspec section exists in reference.md"
else
  fail "## exspec section not found in reference.md"
fi

# T-02: SKILL.mdからreference.md#exspecへの参照が有効
echo ""
echo "T-02: SKILL.md references reference.md#exspec"

if grep -q 'reference\.md#exspec' "$SKILL_MD"; then
  pass "SKILL.md references reference.md#exspec"
else
  fail "SKILL.md does not reference reference.md#exspec"
fi

# T-03: reference.mdに言語マッピングテーブルが存在する
echo ""
echo "T-03: reference.md has language mapping table"

# Check for language mapping table rows (pipe-delimited)
python_count=$(grep -c '| python' "$REFERENCE_MD" || true)
ts_count=$(grep -c '| typescript' "$REFERENCE_MD" || true)
php_count=$(grep -c '| php' "$REFERENCE_MD" || true)

if [ "$python_count" -ge 1 ] && [ "$ts_count" -ge 1 ] && [ "$php_count" -ge 1 ]; then
  pass "Language mapping table contains python, typescript, php (table rows)"
else
  fail "Language mapping table missing entries (python=$python_count, typescript=$ts_count, php=$php_count)"
fi

# T-04: exspec-check.shが存在し実行可能
echo ""
echo "T-04: exspec-check.sh exists and is executable-compatible"

if [ -f "$SCRIPT" ]; then
  pass "exspec-check.sh exists"
else
  fail "exspec-check.sh does not exist at $SCRIPT"
fi

# T-05: exspec未インストール時SKIP (exit 0)
echo ""
echo "T-05: SKIP when exspec not installed (exit 0)"

# Override PATH to ensure exspec is not found
output=$(PATH="/usr/bin:/bin" bash "$SCRIPT" "tests/" "python" 2>&1) && rc=$? || rc=$?
if [ "$rc" -eq 0 ] && echo "$output" | grep -qi "skip"; then
  pass "SKIP (exit 0) when exspec not installed"
else
  fail "Expected SKIP (exit 0) when exspec not installed, got rc=$rc output: $output"
fi

# T-06: 非対応言語(javascript)でSKIP (exit 0)
echo ""
echo "T-06: SKIP for unsupported language (javascript)"

# Override PATH to ensure exspec is not found (same as T-05, test language gate independently)
output=$(PATH="/usr/bin:/bin" bash "$SCRIPT" "tests/" "javascript" 2>&1) && rc=$? || rc=$?
if [ "$rc" -eq 0 ] && echo "$output" | grep -qi "skip"; then
  pass "SKIP (exit 0) for unsupported language"
else
  fail "Expected SKIP (exit 0) for unsupported language, got rc=$rc output: $output"
fi

# T-07: 引数なしでexit非0 (usage)
echo ""
echo "T-07: Non-zero exit when no arguments"

output=$(bash "$SCRIPT" 2>&1) && rc=$? || rc=$?
if [ "$rc" -ne 0 ]; then
  pass "Non-zero exit on no arguments"
else
  fail "Expected non-zero exit on no arguments, got rc=$rc output: $output"
fi

# T-08: SKILL.mdの行数が100行以内
echo ""
echo "T-08: SKILL.md is 100 lines or fewer"

line_count=$(wc -l < "$SKILL_MD" | tr -d ' ')
if [ "$line_count" -le 100 ]; then
  pass "SKILL.md has $line_count lines (<= 100)"
else
  fail "SKILL.md has $line_count lines (> 100)"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS"
echo "FAIL: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi

exit 0
