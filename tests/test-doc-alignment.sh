#!/bin/bash
# test-doc-alignment.sh - CONSTITUTION.md / workflow.md との整合テスト (ROADMAP 12.2)
# T-01 ~ T-08

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
if grep -qE '34 agents|29 skills' "$ARCH_FILE"; then
  fail "T-07: hardcoded counts found in architecture.md"
else
  pass "T-07: no hardcoded counts in architecture.md"
fi

# T-08: Given ROADMAP.md, Then 12.2 に完了マークがある
echo ""
echo "T-08: ROADMAP.md 12.2 has completion mark"
if grep -qE '12\.2.*完了|12\.2.*\(完了\)' "$ROADMAP_FILE"; then
  pass "T-08: ROADMAP.md 12.2 has completion mark"
else
  fail "T-08: ROADMAP.md 12.2 missing completion mark"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
