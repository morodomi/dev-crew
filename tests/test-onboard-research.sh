#!/bin/bash
# test-onboard-research.sh - onboard skill research validation (#26)
# TC-01 ~ TC-08: Structural tests for onboard SKILL.md and reference.md

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

SKILL_FILE="$BASE_DIR/skills/onboard/SKILL.md"
REFERENCE_FILE="$BASE_DIR/skills/onboard/reference.md"

# Section extraction constants
LINES_AFTER_STEP=30

echo "=== Onboard Research Tests (#26) ==="
echo ""

# Verify files exist
[ -f "$SKILL_FILE" ] || { echo "ERROR: $SKILL_FILE not found"; exit 1; }
[ -f "$REFERENCE_FILE" ] || { echo "ERROR: $REFERENCE_FILE not found"; exit 1; }

# Read files once and reuse
SKILL_CONTENT=$(cat "$SKILL_FILE")
REF_CONTENT=$(cat "$REFERENCE_FILE")

# TC-01: SKILL.md が 100行以下であること
echo "TC-01: SKILL.md <= 100 lines"
LINE_COUNT=$(echo "$SKILL_CONTENT" | wc -l | tr -d ' ')
if [ "$LINE_COUNT" -le 100 ]; then
  pass "TC-01: SKILL.md is $LINE_COUNT lines (<= 100)"
else
  fail "TC-01: SKILL.md is $LINE_COUNT lines (> 100)"
fi

# TC-02: reference.md に「コンテンツ判定基準」セクションが存在すること
echo ""
echo "TC-02: reference.md has content criteria section"
if echo "$REF_CONTENT" | grep -q "コンテンツ判定基準"; then
  pass "TC-02: content criteria section found"
else
  fail "TC-02: content criteria section not found"
fi

# TC-03: reference.md に「書くべきもの」「書くべきでないもの」の両方が記載されていること
echo ""
echo "TC-03: reference.md has both inclusion and exclusion criteria"
if echo "$REF_CONTENT" | grep -q "書くべきもの" && \
   echo "$REF_CONTENT" | grep -q "書くべきでないもの"; then
  pass "TC-03: both inclusion and exclusion criteria found"
else
  fail "TC-03: missing inclusion and/or exclusion criteria"
fi

# TC-04: reference.md Step 5 に @ import の説明が含まれること
echo ""
echo "TC-04: reference.md Step 5 has @ import explanation"
if echo "$REF_CONTENT" | grep -A "$LINES_AFTER_STEP" "^## Step 5" | grep -q "@.*import\|@docs/\|@ import"; then
  pass "TC-04: @ import explanation found in Step 5"
else
  fail "TC-04: @ import explanation not found in Step 5"
fi

# TC-05: reference.md Step 6 に path targeting (paths フロントマター) の例示が含まれること
echo ""
echo "TC-05: reference.md Step 6 has path targeting example"
if echo "$REF_CONTENT" | grep -A "$LINES_AFTER_STEP" "^## Step 6" | grep -q "paths:"; then
  pass "TC-05: path targeting (paths frontmatter) example found in Step 6"
else
  fail "TC-05: path targeting (paths frontmatter) example not found in Step 6"
fi

# TC-06: reference.md に「メンテナンス」セクションが存在すること
echo ""
echo "TC-06: reference.md has maintenance section"
if echo "$REF_CONTENT" | grep -q "メンテナンス"; then
  pass "TC-06: maintenance section found"
else
  fail "TC-06: maintenance section not found"
fi

# TC-07: SKILL.md Step 4 に Deletion Test の言及があること
echo ""
echo "TC-07: SKILL.md Step 4 mentions Deletion Test"
if echo "$SKILL_CONTENT" | grep -A "$LINES_AFTER_STEP" "^### Step 4" | grep -qi "deletion test"; then
  pass "TC-07: Deletion Test mentioned in Step 4"
else
  fail "TC-07: Deletion Test not mentioned in Step 4"
fi

# TC-08: SKILL.md Step 9 にメンテナンス案内が含まれること
echo ""
echo "TC-08: SKILL.md Step 9 has maintenance guidance"
if echo "$SKILL_CONTENT" | grep -A "$LINES_AFTER_STEP" "^### Step 9" | grep -q "メンテナンス\|定期レビュー\|Feedback Loop"; then
  pass "TC-08: maintenance guidance found in Step 9"
else
  fail "TC-08: maintenance guidance not found in Step 9"
fi

# TC-09: reference.md 必須セクション定義にセクション上限が明記されていること
echo ""
echo "TC-09: reference.md states max sections limit"
if echo "$REF_CONTENT" | grep -q "最大5セクション\|最大5\|5セクション"; then
  pass "TC-09: max 5 sections limit found"
else
  fail "TC-09: max 5 sections limit not found"
fi

# TC-10: reference.md に Project Structure が「条件付き」と明記されていること
echo ""
echo "TC-10: reference.md states Project Structure is conditional"
if echo "$REF_CONTENT" | grep -q "Project Structure.*条件付き\|条件付き.*Project Structure\|自動検出成功時のみ"; then
  pass "TC-10: Project Structure conditional generation found"
else
  fail "TC-10: Project Structure conditional generation not found"
fi

# TC-11: reference.md 変数一覧にフォールバック列 [要設定] があること
echo ""
echo "TC-11: reference.md variable table has fallback column with [要設定]"
if echo "$REF_CONTENT" | grep -q "\[要設定\]"; then
  pass "TC-11: fallback placeholder [要設定] found"
else
  fail "TC-11: fallback placeholder [要設定] not found"
fi

# TC-12: reference.md の AI Behavior Principles テンプレートがコードブロック内にあること
echo ""
echo "TC-12: AI Behavior Principles template is inside code block"
# Check that "## AI Behavior" does NOT appear outside code blocks
# Strategy: count occurrences outside code blocks by removing code block content first
OUTSIDE_CODE=$(echo "$REF_CONTENT" | awk '/^```/{inside=!inside; next} !inside{print}' | grep -c "^## AI Behavior" || true)
if [ "$OUTSIDE_CODE" -eq 0 ]; then
  pass "TC-12: AI Behavior Principles only inside code block"
else
  fail "TC-12: AI Behavior Principles found outside code block ($OUTSIDE_CODE occurrences)"
fi

# TC-13: reference.md マージ戦略に "Overview (Tech Stack含む)" があること
echo ""
echo "TC-13: merge strategy has 'Overview (Tech Stack含む)'"
if echo "$REF_CONTENT" | grep -q "Overview (Tech Stack含む)\|Overview.*Tech Stack.*含む"; then
  pass "TC-13: merged Overview with Tech Stack found"
else
  fail "TC-13: merged Overview with Tech Stack not found"
fi

# TC-14: SKILL.md Step 1 にプロジェクト状態判定への言及がある
echo ""
echo "TC-14: SKILL.md Step 1 mentions project state detection"
if echo "$SKILL_CONTENT" | grep -A "$LINES_AFTER_STEP" "^### Step 1" | grep -q "fresh\|existing-no-tdd\|dev-crew-installed\|状態.*判定\|プロジェクト状態"; then
  pass "TC-14: project state detection mentioned in Step 1"
else
  fail "TC-14: project state detection not mentioned in Step 1"
fi

# TC-15: reference.md にモード分類ロジックがある
echo ""
echo "TC-15: reference.md has mode classification logic"
if echo "$REF_CONTENT" | grep -q "fresh" && \
   echo "$REF_CONTENT" | grep -q "existing-no-tdd" && \
   echo "$REF_CONTENT" | grep -q "dev-crew-installed"; then
  pass "TC-15: all three modes defined in reference.md"
else
  fail "TC-15: mode classification logic incomplete in reference.md"
fi

# TC-16: reference.md に5つの検出シグナル全てが定義されている
echo ""
echo "TC-16: reference.md has all 5 detection signals"
SIGNALS=0
echo "$REF_CONTENT" | grep -q "CLAUDE.md.*存在\|CLAUDE.md existence" && SIGNALS=$((SIGNALS + 1))
echo "$REF_CONTENT" | grep -q "TDD.*セクション\|TDD section\|TDD Workflow" && SIGNALS=$((SIGNALS + 1))
echo "$REF_CONTENT" | grep -q "\.claude/rules\|rules/" && SIGNALS=$((SIGNALS + 1))
echo "$REF_CONTENT" | grep -q "\.claude/hooks\|hooks/" && SIGNALS=$((SIGNALS + 1))
echo "$REF_CONTENT" | grep -q "STATUS\.md\|docs/STATUS" && SIGNALS=$((SIGNALS + 1))
if [ "$SIGNALS" -ge 5 ]; then
  pass "TC-16: all 5 detection signals found ($SIGNALS/5)"
else
  fail "TC-16: only $SIGNALS/5 detection signals found"
fi

# TC-17: reference.md に existing-no-tdd モードのマージ戦略がある
echo ""
echo "TC-17: reference.md has existing-no-tdd merge strategy"
if echo "$REF_CONTENT" | grep -A 10 "existing-no-tdd" | grep -qi "マージ\|merge\|セクション追加\|バックアップ"; then
  pass "TC-17: existing-no-tdd merge strategy found"
else
  fail "TC-17: existing-no-tdd merge strategy not found"
fi

# TC-18: reference.md に dev-crew-installed モードの更新フローがある
echo ""
echo "TC-18: reference.md has dev-crew-installed update flow"
if echo "$REF_CONTENT" | grep -A 10 "dev-crew-installed" | grep -qi "更新\|update\|リフレッシュ\|refresh\|差分"; then
  pass "TC-18: dev-crew-installed update flow found"
else
  fail "TC-18: dev-crew-installed update flow not found"
fi

# TC-19: reference.md にファイル単位の差分チェック表がある
echo ""
echo "TC-19: reference.md has per-file diff check table"
if echo "$REF_CONTENT" | grep -q "git-safety.*作成\|git-safety.*差分\|不在時.*作成\|不在.*作成"; then
  pass "TC-19: per-file diff check table found"
else
  fail "TC-19: per-file diff check table not found"
fi

# TC-20: SKILL.md Step 4 に3モード全ての分岐がある
echo ""
echo "TC-20: SKILL.md Step 4 has all 3 mode branches"
STEP4=$(echo "$SKILL_CONTENT" | grep -A "$LINES_AFTER_STEP" "^### Step 4")
MODES=0
echo "$STEP4" | grep -q "fresh" && MODES=$((MODES + 1))
echo "$STEP4" | grep -q "existing-no-tdd" && MODES=$((MODES + 1))
echo "$STEP4" | grep -q "dev-crew-installed" && MODES=$((MODES + 1))
if [ "$MODES" -ge 3 ]; then
  pass "TC-20: all 3 modes found in Step 4 ($MODES/3)"
else
  fail "TC-20: only $MODES/3 modes found in Step 4"
fi

# TC-21: reference.md に CLAUDE.md バックアップ手順がある
echo ""
echo "TC-21: reference.md has CLAUDE.md backup procedure"
if echo "$REF_CONTENT" | grep -qi "バックアップ.*CLAUDE\|backup.*CLAUDE\|CLAUDE.*バックアップ\|CLAUDE.*backup\|\.bak"; then
  pass "TC-21: CLAUDE.md backup procedure found"
else
  fail "TC-21: CLAUDE.md backup procedure not found"
fi

# TC-22: reference.md にモード別確認項目セクションがある
echo ""
echo "TC-22: reference.md has mode-specific confirmation items section"
if echo "$REF_CONTENT" | grep -q "モード別確認\|モード別.*確認項目\|mode-specific.*confirm"; then
  pass "TC-22: mode-specific confirmation items section found"
else
  fail "TC-22: mode-specific confirmation items section not found"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
