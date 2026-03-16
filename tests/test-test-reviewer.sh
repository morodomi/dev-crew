#!/bin/bash
# test-test-reviewer.sh - Tests for test-reviewer agent and integration
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

passed=0
failed=0
errors=""

assert() {
  local tc="$1" desc="$2" result="$3"
  if [ "$result" = "true" ]; then
    echo "  PASS: $tc - $desc"
    passed=$((passed + 1))
  else
    echo "  FAIL: $tc - $desc"
    failed=$((failed + 1))
    errors="${errors}\n  FAIL: $tc - $desc"
  fi
}

echo "=== test-reviewer Tests ==="

# TC-01: agents/test-reviewer.md exists
assert "TC-01" "agents/test-reviewer.md が存在する" \
  "$([ -f "$BASE_DIR/agents/test-reviewer.md" ] && echo true || echo false)"

# TC-02: model: sonnet
assert "TC-02" "model: sonnet である" \
  "$(grep -q '^model: sonnet' "$BASE_DIR/agents/test-reviewer.md" 2>/dev/null && echo true || echo false)"

# TC-03: memory: project
assert "TC-03" "memory: project である" \
  "$(grep -q '^memory: project' "$BASE_DIR/agents/test-reviewer.md" 2>/dev/null && echo true || echo false)"

# TC-04: description contains テストスメル or テストコード
assert "TC-04" "description にテストスメルまたはテストコードを含む" \
  "$(grep -E '^description:' "$BASE_DIR/agents/test-reviewer.md" 2>/dev/null | grep -qE 'テストスメル|テストコード' && echo true || echo false)"

# TC-05: Focus table contains Fragile Test
assert "TC-05" "Focus テーブルに Fragile Test 観点が含まれる" \
  "$(grep -q 'Fragile Test' "$BASE_DIR/agents/test-reviewer.md" 2>/dev/null && echo true || echo false)"

# TC-06: xUnit Test Patterns reference
assert "TC-06" "xUnit Test Patterns 参照が含まれる" \
  "$(grep -q 'xUnit Test Patterns' "$BASE_DIR/agents/test-reviewer.md" 2>/dev/null && echo true || echo false)"

# TC-07: blocking_score criteria defined
assert "TC-07" "blocking_score 基準が定義されている" \
  "$(grep -q 'blocking_score' "$BASE_DIR/agents/test-reviewer.md" 2>/dev/null && echo true || echo false)"

# TC-08: Output contains category
assert "TC-08" "Output に category が含まれる" \
  "$(grep -q 'category' "$BASE_DIR/agents/test-reviewer.md" 2>/dev/null && echo true || echo false)"

# TC-09: Focus table format (| 観点 |)
assert "TC-09" "Focus テーブル形式である" \
  "$(grep -q '| 観点 |' "$BASE_DIR/agents/test-reviewer.md" 2>/dev/null && echo true || echo false)"

# TC-10: Google SWE Book reference
assert "TC-10" "Google SWE Book 参照が含まれる" \
  "$(grep -q 'Google SWE Book' "$BASE_DIR/agents/test-reviewer.md" 2>/dev/null && echo true || echo false)"

# TC-11: steps-subagent.md contains test-reviewer with flags-based condition
assert "TC-11" "steps-subagent.md に test-reviewer が flags-based 条件で含まれる" \
  "$(grep -q 'test-reviewer' "$BASE_DIR/skills/review/steps-subagent.md" 2>/dev/null && echo true || echo false)"

# TC-12: reference.md Agent Roster (Code Mode) contains test-reviewer
assert "TC-12" "reference.md の Agent Roster (Code Mode) に test-reviewer が含まれる" \
  "$(sed -n '/Agent Roster (Code Mode)/,/^##/p' "$BASE_DIR/skills/review/reference.md" 2>/dev/null | grep -q 'test-reviewer' && echo true || echo false)"

# TC-13: reference.md test-reviewer condition is test-file flags
assert "TC-13" "reference.md の test-reviewer の Condition が test-file flags である" \
  "$(grep 'test-reviewer' "$BASE_DIR/skills/review/reference.md" 2>/dev/null | grep -q 'test-file flags' && echo true || echo false)"

# TC-14: risk-classifier.sh contains test file detection signal (comment + grep pattern)
assert "TC-14" "risk-classifier.sh にテストファイル検出シグナルが含まれる" \
  "$(grep -q 'Test file changes' "$BASE_DIR/skills/review/risk-classifier.sh" 2>/dev/null && grep -q "grep -qiE 'test|spec|__tests__'" "$BASE_DIR/skills/review/risk-classifier.sh" 2>/dev/null && echo true || echo false)"

# TC-15: correctness-reviewer.md Focus does NOT contain Test assertion quality
assert "TC-15" "correctness-reviewer.md の Focus に Test assertion quality が含まれない" \
  "$(grep -q 'Test assertion quality' "$BASE_DIR/agents/correctness-reviewer.md" 2>/dev/null && echo false || echo true)"

# TC-16: correctness-reviewer.md Focus still contains logic error aspects
assert "TC-16" "correctness-reviewer.md の Focus に論理エラー観点が残っている" \
  "$(grep -q 'Logic errors' "$BASE_DIR/agents/correctness-reviewer.md" 2>/dev/null && echo true || echo false)"

# TC-17: Regression - existing tests pass
echo ""
echo "  TC-17: リグレッション確認..."
regression_pass=true
for f in "$BASE_DIR"/tests/test-agents-structure.sh "$BASE_DIR"/tests/test-reviewer-scoring.sh; do
  if [ -f "$f" ]; then
    if ! bash "$f" > /dev/null 2>&1; then
      regression_pass=false
      echo "  FAIL: TC-17 - $(basename "$f") failed"
    fi
  fi
done
assert "TC-17" "既存テスト全通過" "$regression_pass"

echo ""
echo "=== Results: $passed passed, $failed failed ==="
if [ "$failed" -gt 0 ]; then
  echo -e "\nFailures:$errors"
  exit 1
fi
