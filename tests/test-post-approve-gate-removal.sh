#!/bin/bash
# test-post-approve-gate-removal.sh - post-approve-gate フラグ廃止の検証
# TC-01: hooks.json に ExitPlanMode エントリがない
# TC-02: hooks.json に post-approve-gate エントリがない
# TC-03: plan-exit-flag.sh が存在しない
# TC-04: post-approve-gate.sh が存在しない
# TC-05: orchestrate SKILL.md に TaskCreate 指示がある
# TC-06: test-hooks-structure.sh に TC-11/TC-12 がない（回帰防止）
# TC-07: stale hook 記述の逆向き契約（docs/cycles・docs/archive 除外で0件）+ 「プロンプトベースの規律」の存在確認
# TC-08: skills/ 配下に post-approve-gate 参照が0件

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== Post-Approve Gate Removal Tests ==="

# TC-01: hooks.json に ExitPlanMode エントリがない
echo ""
echo "TC-01: hooks.json に ExitPlanMode エントリがない"
if jq -e '.hooks.PostToolUse[] | select(.matcher == "ExitPlanMode")' "$BASE_DIR/hooks/hooks.json" >/dev/null 2>&1; then
  fail "TC-01: hooks.json still has ExitPlanMode entry"
else
  pass "TC-01: hooks.json has no ExitPlanMode entry"
fi

# TC-02: hooks.json に post-approve-gate エントリがない
echo ""
echo "TC-02: hooks.json に post-approve-gate エントリがない"
if grep -q 'post-approve-gate' "$BASE_DIR/hooks/hooks.json"; then
  fail "TC-02: hooks.json still references post-approve-gate"
else
  pass "TC-02: hooks.json has no post-approve-gate reference"
fi

# TC-03: plan-exit-flag.sh が存在しない
echo ""
echo "TC-03: plan-exit-flag.sh が存在しない"
if [ -f "$BASE_DIR/scripts/hooks/plan-exit-flag.sh" ]; then
  fail "TC-03: plan-exit-flag.sh still exists"
else
  pass "TC-03: plan-exit-flag.sh does not exist"
fi

# TC-04: post-approve-gate.sh が存在しない
echo ""
echo "TC-04: post-approve-gate.sh が存在しない"
if [ -f "$BASE_DIR/scripts/hooks/post-approve-gate.sh" ]; then
  fail "TC-04: post-approve-gate.sh still exists"
else
  pass "TC-04: post-approve-gate.sh does not exist"
fi

# TC-05: orchestrate SKILL.md に TaskCreate 指示がある
echo ""
echo "TC-05: orchestrate SKILL.md に TaskCreate 指示がある"
if grep -q 'TaskCreate' "$BASE_DIR/skills/orchestrate/SKILL.md"; then
  pass "TC-05: orchestrate SKILL.md has TaskCreate instruction"
else
  fail "TC-05: orchestrate SKILL.md missing TaskCreate instruction"
fi

# TC-06: test-hooks-structure.sh に TC-11/TC-12 がない（回帰防止）
echo ""
echo "TC-06: test-hooks-structure.sh に TC-11/TC-12 がない"
if grep -q 'TC-11\|TC-12' "$BASE_DIR/tests/test-hooks-structure.sh"; then
  fail "TC-06: test-hooks-structure.sh still has TC-11/TC-12"
else
  pass "TC-06: test-hooks-structure.sh has no TC-11/TC-12"
fi

# TC-07: stale hook 記述の逆向き契約（0件）+ 新文言の存在確認
echo ""
echo "TC-07: stale hook 記述 0 件（docs/cycles・docs/archive 除外）かつ「プロンプトベースの規律」が3ファイルに存在"
HOOK_HITS_RC=0
HOOK_RAW=$(grep -rE 'hook.*でブロックされる' --include="*.md" "$BASE_DIR" 2>/dev/null) || HOOK_HITS_RC=$?
if [ "$HOOK_HITS_RC" -ge 2 ]; then
  fail "TC-07: grep failed with rc=$HOOK_HITS_RC — cannot verify negative sweep"
else
  HOOK_HITS=$(echo "$HOOK_RAW" | grep -v "^$BASE_DIR/docs/cycles/" | grep -v "^$BASE_DIR/docs/archive/" || true)
  HOOK_HIT_COUNT=$(echo "$HOOK_HITS" | grep -c . || true)
  PROMPT_PHRASE_FAIL=0
  for rel_file in AGENTS.md skills/spec/reference.md skills/onboard/reference.md; do
    phrase_count=$(grep -cF "プロンプトベースの規律" "$BASE_DIR/$rel_file" 2>/dev/null || true)
    [ -z "$phrase_count" ] && phrase_count=0
    if [ "$phrase_count" -lt 1 ]; then
      PROMPT_PHRASE_FAIL=1
      echo "    missing in $rel_file (count=$phrase_count)"
    fi
  done
  if [ "$HOOK_HIT_COUNT" -eq 0 ] && [ "$PROMPT_PHRASE_FAIL" -eq 0 ]; then
    pass "TC-07: stale hook 記述 0 件 かつ プロンプトベースの規律 が3ファイルに存在"
  else
    fail "TC-07: stale hook 記述 ${HOOK_HIT_COUNT} 件 / プロンプトベースの規律 欠落フラグ=${PROMPT_PHRASE_FAIL}"
    [ "$HOOK_HIT_COUNT" -gt 0 ] && echo "$HOOK_HITS"
  fi
fi

# TC-08: skills/ 配下に post-approve-gate 参照が0件
echo ""
echo "TC-08: skills/ 配下に post-approve-gate 参照が0件"
PAG_RC=0
PAG_HITS=$(grep -r "post-approve-gate" "$BASE_DIR/skills/" 2>/dev/null) || PAG_RC=$?
if [ "$PAG_RC" -ge 2 ]; then
  fail "TC-08: grep failed with rc=$PAG_RC — cannot verify"
elif [ "$PAG_RC" -eq 1 ]; then
  pass "TC-08: skills/ has no post-approve-gate reference"
else
  fail "TC-08: skills/ still references post-approve-gate"
  echo "$PAG_HITS"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS"
echo "FAIL: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi

exit 0
