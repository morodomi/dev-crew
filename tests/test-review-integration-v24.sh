#!/bin/bash
# test-review-integration-v24.sh - Phase 14-16 統合検証テスト
# v2.4 Review Taxonomy 全体の整合性を横断チェック
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

get_frontmatter() {
  local file="$1" key="$2"
  awk '/^---$/{n++; next} n==1{print}' "$file" | grep "^${key}: " | head -1 | sed "s/^${key}: *//" || true
}

echo "=== v2.4 Review Integration Tests ==="

# TC-01: Phase 14 新設4体の存在
echo ""
echo "TC-01: Phase 14 agents exist"
tc01_result=true
for agent in maintainability-reviewer api-contract-reviewer observability-reviewer performance-reviewer; do
  if [ ! -f "$BASE_DIR/agents/$agent.md" ]; then
    tc01_result=false
    echo "    Missing: $agent.md"
  fi
done
assert "TC-01" "Phase 14 agents (4体) exist" "$tc01_result"

# TC-02: Phase 15 新設1体の存在
echo ""
echo "TC-02: Phase 15 agent exists"
assert "TC-02" "test-reviewer.md exists" \
  "$([ -f "$BASE_DIR/agents/test-reviewer.md" ] && echo true || echo false)"

# TC-03: Phase 16 新設3体の存在
echo ""
echo "TC-03: Phase 16 agents exist"
tc03_result=true
for agent in change-safety-reviewer impact-reviewer resiliency-reviewer; do
  if [ ! -f "$BASE_DIR/agents/$agent.md" ]; then
    tc03_result=false
    echo "    Missing: $agent.md"
  fi
done
assert "TC-03" "Phase 16 agents (3体) exist" "$tc03_result"

# TC-04: 全 reviewer agent が model: sonnet or haiku を持つ
echo ""
echo "TC-04: All reviewer agents have valid model"
tc04_result=true
for agent_file in "$BASE_DIR"/agents/*-reviewer.md; do
  [ -f "$agent_file" ] || continue
  model=$(get_frontmatter "$agent_file" "model")
  if [[ ! "$model" =~ ^(sonnet|haiku)$ ]]; then
    tc04_result=false
    echo "    $(basename "$agent_file"): model=$model"
  fi
done
assert "TC-04" "All reviewer agents have model: sonnet or haiku" "$tc04_result"

# TC-05: dedup テーブルを持つべき agent ペアに dedup 記述がある
echo ""
echo "TC-05: Dedup tables exist for required pairs"
tc05_result=true
# test-reviewer <-> correctness-reviewer
if ! grep -q 'correctness-reviewer' "$BASE_DIR/agents/test-reviewer.md" 2>/dev/null; then
  tc05_result=false
  echo "    test-reviewer: missing correctness-reviewer dedup"
fi
# observability-reviewer <-> correctness-reviewer
if ! grep -q 'correctness-reviewer' "$BASE_DIR/agents/observability-reviewer.md" 2>/dev/null; then
  tc05_result=false
  echo "    observability-reviewer: missing correctness-reviewer dedup"
fi
# impact-reviewer <-> change-safety-reviewer
if ! grep -qi 'change-safety-reviewer' "$BASE_DIR/agents/impact-reviewer.md" 2>/dev/null; then
  tc05_result=false
  echo "    impact-reviewer: missing change-safety-reviewer dedup"
fi
if ! grep -qi 'impact-reviewer' "$BASE_DIR/agents/change-safety-reviewer.md" 2>/dev/null; then
  tc05_result=false
  echo "    change-safety-reviewer: missing impact-reviewer dedup"
fi
assert "TC-05" "Dedup tables exist for 3 pairs" "$tc05_result"

# TC-06: reference.md Plan Mode roster に Phase 16 新 agent 3体
echo ""
echo "TC-06: reference.md Plan Mode roster has Phase 16 agents"
tc06_result=true
plan_section=$(sed -n '/Agent Roster (Plan Mode)/,/^## /p' "$BASE_DIR/skills/review/reference.md" 2>/dev/null)
for agent in change-safety-reviewer impact-reviewer resiliency-reviewer; do
  if ! echo "$plan_section" | grep -q "$agent"; then
    tc06_result=false
    echo "    Missing in Plan roster: $agent"
  fi
done
assert "TC-06" "Plan Mode roster has Phase 16 agents" "$tc06_result"

# TC-07: reference.md Code Mode roster に Phase 14 新 agent 3体
echo ""
echo "TC-07: reference.md Code Mode roster has Phase 14 agents"
tc07_result=true
code_section=$(sed -n '/Agent Roster (Code Mode)/,/^## /p' "$BASE_DIR/skills/review/reference.md" 2>/dev/null)
for agent in maintainability-reviewer api-contract-reviewer observability-reviewer; do
  if ! echo "$code_section" | grep -q "$agent"; then
    tc07_result=false
    echo "    Missing in Code roster: $agent"
  fi
done
assert "TC-07" "Code Mode roster has Phase 14 agents" "$tc07_result"

# TC-08: risk-classifier.sh のシグナル数が11個（ポイント付きの行のみカウント）
echo ""
echo "TC-08: risk-classifier.sh has 11 signals"
signal_count=$(grep -cE '^\#   .+\+[0-9]+' "$BASE_DIR/skills/review/risk-classifier.sh" 2>/dev/null || echo 0)
assert "TC-08" "risk-classifier.sh has 11 signals (got: $signal_count)" \
  "$([ "$signal_count" -eq 11 ] && echo true || echo false)"

# TC-09: steps-subagent.md Plan Mode に Always-on 2体 + Risk-gated 8体
echo ""
echo "TC-09: steps-subagent.md Plan Mode agent counts"
plan_section=$(sed -n '/### Plan Mode/,/## Step 4\.5\|## Step 5/p' "$BASE_DIR/skills/review/steps-subagent.md" 2>/dev/null)
plan_always=$(echo "$plan_section" | grep -c 'Always-on\|Always' 2>/dev/null || echo 0)
plan_risk=$(echo "$plan_section" | grep -c 'Risk-gated' 2>/dev/null || echo 0)
plan_total=$(echo "$plan_section" | grep -c 'Task(' 2>/dev/null || echo 0)
# Always-on: design-reviewer, test-reviewer (2体) + review-briefer (Step 2)
# Risk-gated: security, product, performance, usability, designer, change-safety, impact, resiliency (8体)
assert "TC-09" "Plan Mode: Always-on + Risk-gated agents (total Task() >= 10, got: $plan_total)" \
  "$([ "$plan_total" -ge 10 ] && echo true || echo false)"

# TC-10: steps-subagent.md Code Mode に Always-on 3体 + Risk-gated/Flags 5体以上
echo ""
echo "TC-10: steps-subagent.md Code Mode agent counts"
code_section=$(sed -n '/### Code Mode/,/### Plan Mode\|## Step 4\.5\|## Step 5/p' "$BASE_DIR/skills/review/steps-subagent.md" 2>/dev/null)
code_total=$(echo "$code_section" | grep -c 'Task(' 2>/dev/null || echo 0)
assert "TC-10" "Code Mode: total Task() >= 8 (got: $code_total)" \
  "$([ "$code_total" -ge 8 ] && echo true || echo false)"

# TC-11: AGENTS.md の agent 数が 40
echo ""
echo "TC-11: AGENTS.md reports 40 agents"
agent_count=$(ls "$BASE_DIR"/agents/*.md | grep -v reference | wc -l | tr -d ' ')
assert "TC-11" "Agent count = 40 (got: $agent_count)" \
  "$([ "$agent_count" -eq 40 ] && echo true || echo false)"

# TC-12: 既存 Phase 14-16 テスト全通過（リグレッション）
echo ""
echo "TC-12: Phase 14-16 regression tests"
tc12_result=true
regression_tests=(
  "test-maintainability-reviewer.sh"
  "test-api-contract-reviewer.sh"
  "test-observability-reviewer.sh"
  "test-performance-reviewer-enhancement.sh"
  "test-test-reviewer.sh"
  "test-plan-review-phase16.sh"
  "test-socrates-review-integration.sh"
  "test-agents-structure.sh"
)
for test_file in "${regression_tests[@]}"; do
  test_path="$BASE_DIR/tests/$test_file"
  if [ -f "$test_path" ]; then
    if ! bash "$test_path" > /dev/null 2>&1; then
      tc12_result=false
      echo "    FAIL: $test_file"
    fi
  else
    echo "    SKIP: $test_file (not found)"
  fi
done
assert "TC-12" "Phase 14-16 regression tests pass" "$tc12_result"

echo ""
echo "=== Results: $passed passed, $failed failed ==="
if [ "$failed" -gt 0 ]; then
  echo -e "\nFailures:$errors"
  exit 1
fi
