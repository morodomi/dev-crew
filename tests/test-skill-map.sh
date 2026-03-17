#!/bin/bash
# test-skill-map.sh - docs/skill-map.md の構造検証テスト (Phase 13)
# T-01 ~ T-08

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

SKILL_MAP="$BASE_DIR/docs/skill-map.md"
README="$BASE_DIR/docs/README.md"
ROADMAP="$BASE_DIR/ROADMAP.md"

echo "=== Skill Map Tests ==="
echo ""

# T-01: Given docs/, Then skill-map.md が存在する
echo "T-01: docs/skill-map.md exists"
if [ -f "$SKILL_MAP" ]; then
  pass "T-01: skill-map.md exists"
else
  fail "T-01: skill-map.md does not exist"
fi

# T-02: Given skill-map.md, Then TDD Workflow Skills テーブルに pre-red-gate がある
echo ""
echo "T-02: skill-map.md has pre-red-gate in TDD Workflow Skills"
if grep -q 'pre-red-gate' "$SKILL_MAP" 2>/dev/null; then
  pass "T-02: pre-red-gate found"
else
  fail "T-02: pre-red-gate not found"
fi

# T-03: Given skill-map.md, Then TDD Workflow Skills テーブルに pre-commit-gate がある
echo ""
echo "T-03: skill-map.md has pre-commit-gate in TDD Workflow Skills"
if grep -q 'pre-commit-gate' "$SKILL_MAP" 2>/dev/null; then
  pass "T-03: pre-commit-gate found"
else
  fail "T-03: pre-commit-gate not found"
fi

# T-04: Given skill-map.md, Then Support Skills テーブルに phase-compact がある
echo ""
echo "T-04: skill-map.md has phase-compact in Support Skills"
if grep -q 'phase-compact' "$SKILL_MAP" 2>/dev/null; then
  pass "T-04: phase-compact found"
else
  fail "T-04: phase-compact not found"
fi

# T-05: Given skill-map.md, Then PHILOSOPHY.md への参照がある
echo ""
echo "T-05: skill-map.md references PHILOSOPHY.md"
if grep -q 'PHILOSOPHY.md' "$SKILL_MAP" 2>/dev/null; then
  pass "T-05: PHILOSOPHY.md reference found"
else
  fail "T-05: PHILOSOPHY.md reference not found"
fi

# T-06: Given skill-map.md, Then ハードコード数値がない
echo ""
echo "T-06: skill-map.md has no hardcoded agent/skill counts"
if grep -qE '34 agents|29 skills' "$SKILL_MAP" 2>/dev/null; then
  fail "T-06: hardcoded counts found"
else
  pass "T-06: no hardcoded counts"
fi

# T-07: Given docs/README.md, Then skill-map への参照がある
echo ""
echo "T-07: docs/README.md references skill-map"
if grep -q 'skill-map' "$README" 2>/dev/null; then
  pass "T-07: skill-map reference found in README.md"
else
  fail "T-07: skill-map reference not found in README.md"
fi

# T-08: Given ROADMAP.md, Then Phase 13 に完了マークがある
echo ""
echo "T-08: ROADMAP.md Phase 13 has completion mark"
if grep -qE 'Phase 13.*完了|スキルマップ.*完了|スキルマップ.*\(完了\)' "$ROADMAP" 2>/dev/null; then
  pass "T-08: Phase 13 completion mark found"
else
  fail "T-08: Phase 13 completion mark not found"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
