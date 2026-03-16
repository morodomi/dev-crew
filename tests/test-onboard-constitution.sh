#!/bin/bash
# test-onboard-constitution.sh - onboard CONSTITUTION.md 対応のテスト
set -uo pipefail

DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0

pass() { echo "  PASS: $1"; ((PASS++)); }
fail() { echo "  FAIL: $1"; ((FAIL++)); }

echo "=== test-onboard-constitution ==="

REF_FILE="$DIR/skills/onboard/reference.md"
SKILL_FILE="$DIR/skills/onboard/SKILL.md"
VALIDATION_FILE="$DIR/skills/onboard/validation.md"

# --- 7.1 型検出ロジック ---

echo "-- 7.1: 型検出ロジック (reference.md) --"

# TC-01: Given reference.md, Then 型検出シグナルテーブルが存在する
if grep -q "Skills" "$REF_FILE" && grep -q "App" "$REF_FILE" && grep -q "CLI" "$REF_FILE" && grep -q "Data/ML" "$REF_FILE"; then
  pass "TC-01: 型検出シグナルテーブルに Skills/App/CLI/Data/ML が存在"
else
  fail "TC-01: 型検出シグナルテーブルに型が不足"
fi

# TC-02: Given reference.md, Then 型検出コマンドが存在する
if grep -q 'skills.*agents' "$REF_FILE" && grep -q 'src.*public\|src.*pages\|src.*app' "$REF_FILE" && grep -q 'main.rs\|cli.py\|bin' "$REF_FILE" && grep -q 'models\|notebooks\|experiments' "$REF_FILE"; then
  pass "TC-02: 型検出コマンド（skills/agents, src+public, main.rs/cli.py, models/notebooks）が存在"
else
  fail "TC-02: 型検出コマンドが不足"
fi

# --- 7.2 CONSTITUTION テンプレート ---

echo "-- 7.2: CONSTITUTION テンプレート (reference.md) --"

# TC-03: Given reference.md, Then CONSTITUTION 共通骨格テンプレート（5章全て）が存在する
CHAPTERS_FOUND=0
grep -q "One Sentence" "$REF_FILE" && ((CHAPTERS_FOUND++))
grep -q "Goal.*Non-Goals\|Goal / Non-Goals" "$REF_FILE" && ((CHAPTERS_FOUND++))
grep -q "Human.*AI\|Human vs AI" "$REF_FILE" && ((CHAPTERS_FOUND++))
grep -q "Source of Truth" "$REF_FILE" && ((CHAPTERS_FOUND++))
grep -qi "変更ポリシー\|Change Policy" "$REF_FILE" && ((CHAPTERS_FOUND++))
if [ "$CHAPTERS_FOUND" -ge 5 ]; then
  pass "TC-03: CONSTITUTION 共通骨格テンプレート 5章全て存在 (found: $CHAPTERS_FOUND)"
else
  fail "TC-03: CONSTITUTION 共通骨格テンプレート不足 (found: $CHAPTERS_FOUND/5)"
fi

# TC-04: Given reference.md, Then Skills 型拡張テンプレートが存在する
if grep -q "Skills" "$REF_FILE" && grep -qi "Quality Standards\|原則\|前提" "$REF_FILE"; then
  pass "TC-04: Skills 型拡張テンプレートが存在"
else
  fail "TC-04: Skills 型拡張テンプレートが不足"
fi

# TC-05: Given reference.md, Then App 型拡張テンプレートが存在する
if grep -q "Domain Boundaries\|Product Principles" "$REF_FILE"; then
  pass "TC-05: App 型拡張テンプレートが存在"
else
  fail "TC-05: App 型拡張テンプレートが不足"
fi

# TC-06: Given reference.md, Then CLI 型拡張テンプレートが存在する
if grep -q "Detection Philosophy\|Severity.*Confidence\|Scope Boundaries" "$REF_FILE"; then
  pass "TC-06: CLI 型拡張テンプレートが存在"
else
  fail "TC-06: CLI 型拡張テンプレートが不足"
fi

# TC-07: Given reference.md, Then Data/ML 型拡張テンプレートが存在する
if grep -q "Data Integrity\|Model Evaluation\|Decision Boundaries" "$REF_FILE"; then
  pass "TC-07: Data/ML 型拡張テンプレートが存在"
else
  fail "TC-07: Data/ML 型拡張テンプレートが不足"
fi

# --- 7.3 migration 支援 ---

echo "-- 7.3: migration 支援 (reference.md) --"

# TC-08: Given reference.md, Then モード別 CONSTITUTION 動作が記述されている
if grep -q "fresh" "$REF_FILE" && grep -q "existing-no-tdd" "$REF_FILE" && grep -q "dev-crew-installed" "$REF_FILE" && grep -qi "CONSTITUTION" "$REF_FILE"; then
  pass "TC-08: モード別 CONSTITUTION 動作が記述されている"
else
  fail "TC-08: モード別 CONSTITUTION 動作の記述が不足"
fi

# TC-09: Given reference.md, Then migration 支援（philosophy.md スキャン）が記述されている
if grep -q "philosophy.md\|PHILOSOPHY.md\|design_philosophy" "$REF_FILE"; then
  pass "TC-09: migration 支援（philosophy.md スキャン）が記述されている"
else
  fail "TC-09: migration 支援（philosophy.md スキャン）の記述が不足"
fi

# --- 7.4 SKILL.md ---

echo "-- 7.4: SKILL.md --"

# TC-10: Given SKILL.md, Then CONSTITUTION.md が言及されている
if grep -qi "CONSTITUTION" "$SKILL_FILE"; then
  pass "TC-10: SKILL.md に CONSTITUTION.md が言及されている"
else
  fail "TC-10: SKILL.md に CONSTITUTION.md の言及がない"
fi

# TC-11: Given SKILL.md, Then 100行以内
LINE_COUNT=$(wc -l < "$SKILL_FILE" | tr -d ' ')
if [ "$LINE_COUNT" -le 100 ]; then
  pass "TC-11: SKILL.md は100行以内 (${LINE_COUNT}行)"
else
  fail "TC-11: SKILL.md が100行超 (${LINE_COUNT}行)"
fi

# --- 7.5 validation.md ---

echo "-- 7.5: validation.md --"

# TC-12: Given validation.md, Then CONSTITUTION.md チェック項目が存在する
if grep -qi "CONSTITUTION" "$VALIDATION_FILE"; then
  pass "TC-12: validation.md に CONSTITUTION.md チェック項目が存在"
else
  fail "TC-12: validation.md に CONSTITUTION.md チェック項目がない"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
