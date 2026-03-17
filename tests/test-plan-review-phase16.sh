#!/bin/bash
# test-plan-review-phase16.sh - Phase 16 Plan Review 強化テスト
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

echo "=== Phase 16: Plan Review 強化 Tests ==="

# --- 新規 agent 存在・構造 ---

# TC-01: agents/change-safety-reviewer.md が存在する
assert "TC-01" "agents/change-safety-reviewer.md が存在する" \
  "$([ -f "$BASE_DIR/agents/change-safety-reviewer.md" ] && echo true || echo false)"

# TC-02: agents/impact-reviewer.md が存在する
assert "TC-02" "agents/impact-reviewer.md が存在する" \
  "$([ -f "$BASE_DIR/agents/impact-reviewer.md" ] && echo true || echo false)"

# TC-03: agents/resiliency-reviewer.md が存在する
assert "TC-03" "agents/resiliency-reviewer.md が存在する" \
  "$([ -f "$BASE_DIR/agents/resiliency-reviewer.md" ] && echo true || echo false)"

# TC-04: change-safety-reviewer の description にロールバックまたはマイグレーションを含む
assert "TC-04" "change-safety-reviewer の description にロールバックまたはマイグレーションを含む" \
  "$(grep -E '^description:' "$BASE_DIR/agents/change-safety-reviewer.md" 2>/dev/null | grep -qE 'ロールバック|マイグレーション' && echo true || echo false)"

# TC-05: impact-reviewer の description に影響または依存を含む
assert "TC-05" "impact-reviewer の description に影響または依存を含む" \
  "$(grep -E '^description:' "$BASE_DIR/agents/impact-reviewer.md" 2>/dev/null | grep -qE '影響|依存' && echo true || echo false)"

# TC-06: resiliency-reviewer の description に耐障害またはタイムアウトを含む
assert "TC-06" "resiliency-reviewer の description に耐障害またはタイムアウトを含む" \
  "$(grep -E '^description:' "$BASE_DIR/agents/resiliency-reviewer.md" 2>/dev/null | grep -qE '耐障害|タイムアウト' && echo true || echo false)"

# TC-07: 3体とも model: sonnet である
tc07_result=true
for agent in change-safety-reviewer impact-reviewer resiliency-reviewer; do
  if ! grep -q '^model: sonnet' "$BASE_DIR/agents/$agent.md" 2>/dev/null; then
    tc07_result=false
  fi
done
assert "TC-07" "3体とも model: sonnet である" "$tc07_result"

# --- design-reviewer 強化 ---

# TC-08: design-reviewer.md の Focus に過剰設計関連の記述がある
assert "TC-08" "design-reviewer.md の Focus に過剰設計関連の記述がある" \
  "$(grep -qiE 'Over-engineering|Speculative Generality|YAGNI' "$BASE_DIR/agents/design-reviewer.md" 2>/dev/null && echo true || echo false)"

# --- test-reviewer Plan mode ---

# TC-09: test-reviewer.md に Plan mode セクションが含まれる
assert "TC-09" "test-reviewer.md に Plan mode セクションが含まれる" \
  "$(grep -qi 'Plan mode\|Plan Mode' "$BASE_DIR/agents/test-reviewer.md" 2>/dev/null && echo true || echo false)"

# TC-10: Plan mode に TC カバレッジ観点が含まれる
assert "TC-10" "Plan mode に TC カバレッジ観点が含まれる" \
  "$(grep -q 'TC カバレッジ\|TC coverage\|TCカバレッジ' "$BASE_DIR/agents/test-reviewer.md" 2>/dev/null && echo true || echo false)"

# --- risk-classifier.sh 拡張 ---

# TC-11: risk-classifier.sh にスキーマ/migration 検出シグナルが含まれる
assert "TC-11" "risk-classifier.sh にスキーマ/migration 検出シグナルが含まれる" \
  "$(grep -qiE 'migration|schema' "$BASE_DIR/skills/review/risk-classifier.sh" 2>/dev/null && echo true || echo false)"

# TC-12: risk-classifier.sh に外部通信検出シグナルが含まれる
assert "TC-12" "risk-classifier.sh に外部通信検出シグナルが含まれる" \
  "$(grep -qiE 'fetch|axios|requests|http.client|external.*comm' "$BASE_DIR/skills/review/risk-classifier.sh" 2>/dev/null && echo true || echo false)"

# TC-13: risk-classifier.sh に広範囲変更（ディレクトリ分散）検出シグナルが含まれる
assert "TC-13" "risk-classifier.sh に広範囲変更検出シグナルが含まれる" \
  "$(grep -qiE 'dir.*spread|directory.*dispers|wide.*change|dir_count' "$BASE_DIR/skills/review/risk-classifier.sh" 2>/dev/null && echo true || echo false)"

# --- steps-subagent.md / reference.md 統合 ---

# TC-14: steps-subagent.md の Plan Mode に change-safety-reviewer が含まれる
assert "TC-14" "steps-subagent.md の Plan Mode に change-safety-reviewer が含まれる" \
  "$(sed -n '/Plan Mode/,/Code Mode\|^## /p' "$BASE_DIR/skills/review/steps-subagent.md" 2>/dev/null | grep -q 'change-safety-reviewer' && echo true || echo false)"

# TC-15: steps-subagent.md の Plan Mode に impact-reviewer が含まれる
assert "TC-15" "steps-subagent.md の Plan Mode に impact-reviewer が含まれる" \
  "$(sed -n '/Plan Mode/,/Code Mode\|^## /p' "$BASE_DIR/skills/review/steps-subagent.md" 2>/dev/null | grep -q 'impact-reviewer' && echo true || echo false)"

# TC-16: steps-subagent.md の Plan Mode に resiliency-reviewer が含まれる
assert "TC-16" "steps-subagent.md の Plan Mode に resiliency-reviewer が含まれる" \
  "$(sed -n '/Plan Mode/,/Code Mode\|^## /p' "$BASE_DIR/skills/review/steps-subagent.md" 2>/dev/null | grep -q 'resiliency-reviewer' && echo true || echo false)"

# TC-17: steps-subagent.md の Plan Mode に test-reviewer が含まれる
assert "TC-17" "steps-subagent.md の Plan Mode に test-reviewer が含まれる" \
  "$(sed -n '/Plan Mode/,/Code Mode\|^## /p' "$BASE_DIR/skills/review/steps-subagent.md" 2>/dev/null | grep -q 'test-reviewer' && echo true || echo false)"

# TC-18: reference.md の Agent Roster (Plan Mode) に change-safety-reviewer が含まれる
assert "TC-18" "reference.md の Agent Roster (Plan Mode) に change-safety-reviewer が含まれる" \
  "$(sed -n '/Agent Roster (Plan Mode)/,/^##/p' "$BASE_DIR/skills/review/reference.md" 2>/dev/null | grep -q 'change-safety-reviewer' && echo true || echo false)"

# --- リグレッション ---

echo ""
echo "  TC-19: リグレッション確認..."
regression_pass=true
for f in "$BASE_DIR"/tests/test-agents-structure.sh "$BASE_DIR"/tests/test-test-reviewer.sh "$BASE_DIR"/tests/test-socrates-review-integration.sh; do
  if [ -f "$f" ]; then
    if ! bash "$f" > /dev/null 2>&1; then
      regression_pass=false
      echo "    FAIL: $(basename "$f") failed"
    fi
  fi
done
assert "TC-19" "既存テスト全通過" "$regression_pass"

echo ""
echo "=== Results: $passed passed, $failed failed ==="
if [ "$failed" -gt 0 ]; then
  echo -e "\nFailures:$errors"
  exit 1
fi
