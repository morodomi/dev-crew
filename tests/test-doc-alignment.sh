#!/bin/bash
# test-doc-alignment.sh - CONSTITUTION.md / workflow.md との整合テスト
# T-01 ~ T-09

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

AGENTS_FILE="$BASE_DIR/AGENTS.md"
CLAUDE_FILE="$BASE_DIR/CLAUDE.md"
ARCH_FILE="$BASE_DIR/docs/architecture.md"
ROADMAP_FILE="$BASE_DIR/ROADMAP.md"
WORKFLOW_FILE="$BASE_DIR/docs/workflow.md"

echo "=== Document Alignment Tests ==="
echo ""

# T-01: Given AGENTS.md TDD Workflow, Then pre-red-gate の記載がある
echo "T-01: AGENTS.md has pre-red-gate in TDD Workflow"
if grep -q 'pre-red-gate' "$AGENTS_FILE"; then
  pass "T-01: pre-red-gate found in AGENTS.md"
else
  fail "T-01: pre-red-gate missing from AGENTS.md"
fi

# T-02: Given AGENTS.md TDD Workflow, Then pre-commit-gate の記載がある
echo ""
echo "T-02: AGENTS.md has pre-commit-gate in TDD Workflow"
if grep -q 'pre-commit-gate' "$AGENTS_FILE"; then
  pass "T-02: pre-commit-gate found in AGENTS.md"
else
  fail "T-02: pre-commit-gate missing from AGENTS.md"
fi

# T-03: Given CLAUDE.md Codex Integration, Then REFACTOR の主従記載がある
echo ""
echo "T-03: CLAUDE.md has REFACTOR ownership in Codex Integration"
if grep -qE 'Claude.*主|Claude.*primary|REFACTOR.*Claude' "$CLAUDE_FILE"; then
  pass "T-03: REFACTOR ownership found in CLAUDE.md"
else
  fail "T-03: REFACTOR ownership missing from CLAUDE.md"
fi

# T-04: Given CLAUDE.md Usage Patterns, Then compact の記載がある
echo ""
echo "T-04: CLAUDE.md Usage Patterns has compact"
if grep -q 'compact' "$CLAUDE_FILE"; then
  pass "T-04: compact found in CLAUDE.md Usage Patterns"
else
  fail "T-04: compact missing from CLAUDE.md Usage Patterns"
fi

# T-05: Given architecture.md, Then pre-red-gate がフロー図にある
echo ""
echo "T-05: architecture.md has pre-red-gate in flow"
if grep -q 'pre-red-gate' "$ARCH_FILE"; then
  pass "T-05: pre-red-gate found in architecture.md"
else
  fail "T-05: pre-red-gate missing from architecture.md"
fi

# T-06: Given architecture.md, Then pre-commit-gate がフロー図にある
echo ""
echo "T-06: architecture.md has pre-commit-gate in flow"
if grep -q 'pre-commit-gate' "$ARCH_FILE"; then
  pass "T-06: pre-commit-gate found in architecture.md"
else
  fail "T-06: pre-commit-gate missing from architecture.md"
fi

# T-07: Given architecture.md, Then エージェント/スキルの具体数値がハードコードされていない
echo ""
echo "T-07: architecture.md has no hardcoded agent/skill counts"
if grep -qE '34 agents|28 skills' "$ARCH_FILE"; then
  fail "T-07: hardcoded counts found in architecture.md"
else
  pass "T-07: no hardcoded counts in architecture.md"
fi

# T-08: Given docs/workflow.md 開発フロー図（COMMIT (Claude) box）、
#       When そのfenced blockをCOMMIT行以降で走査、
#       Then DONE終端がCOMMITより後の行として存在する（#157 順序契約）
echo ""
echo "T-08: workflow.md phase flow has COMMIT -> DONE terminal order"
wf_flow_heading=$(grep -n '^## 開発フロー$' "$WORKFLOW_FILE" | head -1 | cut -d: -f1 || true)
wf_fence_open=""
wf_fence_close=""
if [ -n "$wf_flow_heading" ]; then
  wf_fence_open=$(awk -v s="$wf_flow_heading" 'NR>s && /^```$/{print NR; exit}' "$WORKFLOW_FILE" || true)
fi
if [ -n "$wf_fence_open" ]; then
  wf_fence_close=$(awk -v s="$wf_fence_open" 'NR>s && /^```$/{print NR; exit}' "$WORKFLOW_FILE" || true)
fi
if [ -n "$wf_fence_open" ] && [ -n "$wf_fence_close" ]; then
  wf_block=$(sed -n "${wf_fence_open},${wf_fence_close}p" "$WORKFLOW_FILE")
  wf_commit_line=$(printf '%s\n' "$wf_block" | grep -n 'COMMIT (Claude)' | head -1 | cut -d: -f1 || true)
  # 特異トークン 'DONE (cycle' で pin（任意の "phase: DONE" 記述等での偽 PASS 回避）
  wf_done_line=$(printf '%s\n' "$wf_block" | grep -n 'DONE (cycle' | head -1 | cut -d: -f1 || true)
  if [ -n "$wf_commit_line" ] && [ -n "$wf_done_line" ] && [ "$wf_done_line" -gt "$wf_commit_line" ]; then
    pass "T-08: workflow.md phase flow has DONE after COMMIT (Claude)"
  else
    fail "T-08: workflow.md phase flow missing COMMIT->DONE order (commit_line=${wf_commit_line:-none} done_line=${wf_done_line:-none})"
  fi
else
  fail "T-08: workflow.md 開発フロー fenced block not found"
fi

# T-09: Given docs/architecture.md System Architecture box diagram（COMMIT box）、
#       When そのfenced blockをCOMMIT行以降で走査、
#       Then DONE box がCOMMIT boxより後の行として存在する（#157 順序契約）
echo ""
echo "T-09: architecture.md System Architecture diagram has COMMIT -> DONE box order"
arch_sys_heading=$(grep -n '^## System Architecture$' "$ARCH_FILE" | head -1 | cut -d: -f1 || true)
arch_fence_open=""
arch_fence_close=""
if [ -n "$arch_sys_heading" ]; then
  arch_fence_open=$(awk -v s="$arch_sys_heading" 'NR>s && /^```$/{print NR; exit}' "$ARCH_FILE" || true)
fi
if [ -n "$arch_fence_open" ]; then
  arch_fence_close=$(awk -v s="$arch_fence_open" 'NR>s && /^```$/{print NR; exit}' "$ARCH_FILE" || true)
fi
if [ -n "$arch_fence_open" ] && [ -n "$arch_fence_close" ]; then
  arch_block=$(sed -n "${arch_fence_open},${arch_fence_close}p" "$ARCH_FILE")
  # box ノードに限定（'│ ... COMMIT' / '│ ... DONE' の box 内トークンで pin）
  arch_commit_line=$(printf '%s\n' "$arch_block" | grep -nE '│ +COMMIT' | head -1 | cut -d: -f1 || true)
  arch_done_line=$(printf '%s\n' "$arch_block" | grep -nE '│ +DONE' | head -1 | cut -d: -f1 || true)
  if [ -n "$arch_commit_line" ] && [ -n "$arch_done_line" ] && [ "$arch_done_line" -gt "$arch_commit_line" ]; then
    pass "T-09: architecture.md System Architecture diagram has DONE box after COMMIT box"
  else
    fail "T-09: architecture.md System Architecture diagram missing COMMIT->DONE box order (commit_line=${arch_commit_line:-none} done_line=${arch_done_line:-none})"
  fi
else
  fail "T-09: architecture.md System Architecture fenced block not found"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
