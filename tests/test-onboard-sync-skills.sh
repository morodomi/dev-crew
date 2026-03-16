#!/bin/bash
# test-onboard-sync-skills.sh - onboard完了時のsync-skills誘導テスト (ROADMAP 11.8)
# T-01 ~ T-07

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

SKILL_FILE="$BASE_DIR/skills/onboard/SKILL.md"
REFERENCE_FILE="$BASE_DIR/skills/onboard/reference.md"
ROADMAP_FILE="$BASE_DIR/ROADMAP.md"

[ -f "$SKILL_FILE" ] || { echo "ERROR: $SKILL_FILE not found"; exit 1; }
[ -f "$REFERENCE_FILE" ] || { echo "ERROR: $REFERENCE_FILE not found"; exit 1; }
[ -f "$ROADMAP_FILE" ] || { echo "ERROR: $ROADMAP_FILE not found"; exit 1; }

SKILL_CONTENT=$(cat "$SKILL_FILE")
REF_CONTENT=$(cat "$REFERENCE_FILE")
ROADMAP_CONTENT=$(cat "$ROADMAP_FILE")

echo "=== Onboard sync-skills Prompt Tests ==="
echo ""

# T-01: Given SKILL.md Step 9, Then reference.md#sync-skills-prompt参照がある
echo "T-01: SKILL.md Step 9 has reference to sync-skills-prompt"
if echo "$SKILL_CONTENT" | grep -q 'sync-skills-prompt\|sync-skills.*誘導\|Codex連携'; then
  pass "T-01: SKILL.md Step 9 references sync-skills prompt"
else
  fail "T-01: SKILL.md Step 9 missing sync-skills prompt reference"
fi

# T-02: Given reference.md, Then sync-skills誘導セクションが存在する
echo ""
echo "T-02: reference.md has sync-skills guidance section"
if echo "$REF_CONTENT" | grep -q '## sync-skills 誘導\|## sync-skills.*誘導'; then
  pass "T-02: sync-skills guidance section found"
else
  fail "T-02: sync-skills guidance section missing"
fi

# T-03: Given reference.md sync-skills section, Then Codex検出条件がある
echo ""
echo "T-03: reference.md has Codex detection condition"
if echo "$REF_CONTENT" | grep -q 'command -v codex'; then
  pass "T-03: Codex detection condition (command -v codex) found"
else
  fail "T-03: Codex detection condition missing"
fi

# T-04: Given reference.md sync-skills section, Then .agents/skills/存在チェックがある
echo ""
echo "T-04: reference.md has .agents/skills/ existence check"
if echo "$REF_CONTENT" | grep -q '\.agents/skills/'; then
  pass "T-04: .agents/skills/ existence check found"
else
  fail "T-04: .agents/skills/ existence check missing"
fi

# T-05: Given reference.md sync-skills section, Then AskUserQuestion記述がある
echo ""
echo "T-05: reference.md has AskUserQuestion description"
if echo "$REF_CONTENT" | grep -q 'AskUserQuestion'; then
  pass "T-05: AskUserQuestion description found"
else
  fail "T-05: AskUserQuestion description missing (note: may exist in other sections)"
fi

# T-06: Given SKILL.md, Then 行数が100行以内
echo ""
echo "T-06: SKILL.md is within 100 lines"
LINE_COUNT=$(wc -l < "$SKILL_FILE" | tr -d ' ')
if [ "$LINE_COUNT" -le 100 ]; then
  pass "T-06: SKILL.md is $LINE_COUNT lines (<= 100)"
else
  fail "T-06: SKILL.md is $LINE_COUNT lines (> 100)"
fi

# T-07: Given ROADMAP.md, Then 11.8に完了マークがある
echo ""
echo "T-07: ROADMAP.md 11.8 has completion mark"
# Check that 11.8 section header contains "完了" marker
if echo "$ROADMAP_CONTENT" | grep -q '11\.8.*完了\|11\.8.*\(完了\)'; then
  pass "T-07: ROADMAP.md 11.8 has completion mark"
else
  fail "T-07: ROADMAP.md 11.8 missing completion mark"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
