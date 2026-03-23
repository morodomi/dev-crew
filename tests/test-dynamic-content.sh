#!/bin/bash
# test-dynamic-content.sh - 動的スキルコンテンツ注入 構造チェック
# Phase 24: TC-06 ADR構造（TC-01〜TC-05 は手動検証）
# Phase 25: TC-07/07f 注入構文, TC-08 行数制限, TC-09 コードブロック内禁止

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
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

echo "=== Dynamic Content ADR Structure Checks ==="

# TC-06: ADR が docs/decisions/ に存在する
ADR_FILE="$SCRIPT_DIR/docs/decisions/adr-dynamic-skill-content.md"
if [ -f "$ADR_FILE" ]; then
  assert_eq "TC-06: ADR file exists" "true" "true"
else
  assert_eq "TC-06: ADR file exists" "true" "false"
fi

# TC-06a: ADR に Status が含まれる
if grep -q "^## Status:" "$ADR_FILE" 2>/dev/null; then
  assert_eq "TC-06a: ADR has Status section" "true" "true"
else
  assert_eq "TC-06a: ADR has Status section" "true" "false"
fi

# TC-06b: ADR に Findings セクションが含まれる
if grep -q "## Findings" "$ADR_FILE" 2>/dev/null; then
  assert_eq "TC-06b: ADR has Findings section" "true" "true"
else
  assert_eq "TC-06b: ADR has Findings section" "true" "false"
fi

# TC-06c: ADR に使用ガイドラインが含まれる
if grep -q "使用ガイドライン" "$ADR_FILE" 2>/dev/null; then
  assert_eq "TC-06c: ADR has usage guidelines" "true" "true"
else
  assert_eq "TC-06c: ADR has usage guidelines" "true" "false"
fi

# --- TC-07: SKILL.mdに動的注入構文が存在する（5スキル分）---
echo ""
echo "=== TC-07: Dynamic injection syntax in SKILL.md ==="

SKILLS="orchestrate reload spec red green"
for SKILL in $SKILLS; do
  SKILL_FILE="$SCRIPT_DIR/skills/$SKILL/SKILL.md"
  if awk '/^```/{in_code=!in_code; next} !in_code && /!\x60ls -t docs\/cycles\//' "$SKILL_FILE" 2>/dev/null | grep -q .; then
    assert_eq "TC-07-$SKILL: $SKILL/SKILL.md has ls cycles pattern" "true" "true"
  else
    assert_eq "TC-07-$SKILL: $SKILL/SKILL.md has ls cycles pattern" "true" "false"
  fi
done

# --- TC-07f: orchestrate専用git log注入 ---
echo ""
echo "=== TC-07f: orchestrate git log injection ==="

SKILL_FILE="$SCRIPT_DIR/skills/orchestrate/SKILL.md"
if awk '/^```/{in_code=!in_code; next} !in_code && /!\x60git log --oneline/' "$SKILL_FILE" 2>/dev/null | grep -q .; then
  assert_eq "TC-07f: orchestrate/SKILL.md has git log pattern" "true" "true"
else
  assert_eq "TC-07f: orchestrate/SKILL.md has git log pattern" "true" "false"
fi

# --- TC-08: 100行制限チェック ---
echo ""
echo "=== TC-08: SKILL.md line count <= 100 ==="

for SKILL in $SKILLS; do
  SKILL_FILE="$SCRIPT_DIR/skills/$SKILL/SKILL.md"
  LINE_COUNT=$(wc -l < "$SKILL_FILE")
  if [ "$LINE_COUNT" -le 100 ]; then
    assert_eq "TC-08-$SKILL: $SKILL/SKILL.md is <= 100 lines ($LINE_COUNT)" "true" "true"
  else
    assert_eq "TC-08-$SKILL: $SKILL/SKILL.md is <= 100 lines ($LINE_COUNT)" "true" "false"
  fi
done

# --- TC-09: コードブロック内の!`command`禁止チェック ---
echo ""
echo "=== TC-09: No dynamic injection inside code blocks ==="

for SKILL in $SKILLS; do
  SKILL_FILE="$SCRIPT_DIR/skills/$SKILL/SKILL.md"
  if awk '/^```/{in_code=!in_code; next} in_code && /!\x60/' "$SKILL_FILE" 2>/dev/null | grep -q .; then
    assert_eq "TC-09-$SKILL: $SKILL/SKILL.md has no !backtick in code blocks" "true" "false"
  else
    assert_eq "TC-09-$SKILL: $SKILL/SKILL.md has no !backtick in code blocks" "true" "true"
  fi
done

# --- Summary ---
echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
