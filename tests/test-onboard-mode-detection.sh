#!/bin/bash
# test-onboard-mode-detection.sh - Onboard mode detection improvement tests
# TC-01 ~ TC-11: symlink detection, section diff detection, update proposal

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

SKILL_FILE="$BASE_DIR/skills/onboard/SKILL.md"
REFERENCE_FILE="$BASE_DIR/skills/onboard/reference.md"

[ -f "$SKILL_FILE" ] || { echo "ERROR: $SKILL_FILE not found"; exit 1; }
[ -f "$REFERENCE_FILE" ] || { echo "ERROR: $REFERENCE_FILE not found"; exit 1; }

REF_CONTENT=$(cat "$REFERENCE_FILE")

echo "=== Onboard Mode Detection Tests ==="
echo ""

# --- Sub-task 1: symlink detection (TC-01 ~ TC-03) ---

# TC-01: Given reference.md, When reading, Then [ -L pattern exists for symlink check
echo "TC-01: reference.md contains symlink check pattern"
if echo "$REF_CONTENT" | grep -q '\[ -L'; then
  pass "TC-01: symlink check pattern [ -L found"
else
  fail "TC-01: symlink check pattern [ -L not found"
fi

# TC-02: Given reference.md, When symlink detected, Then user confirmation flow described
echo ""
echo "TC-02: reference.md has user confirmation flow for symlinks"
if echo "$REF_CONTENT" | grep -qi "symlink.*確認\|symlink.*confirm\|シンボリックリンク.*確認"; then
  pass "TC-02: symlink user confirmation flow found"
else
  fail "TC-02: symlink user confirmation flow not found"
fi

# TC-03: Given reference.md, When symlink detected, Then local copy conversion option exists
echo ""
echo "TC-03: reference.md has symlink resolution option"
if echo "$REF_CONTENT" | grep -qi "symlink.*解除\|ローカルコピー.*変換\|cp.*readlink\|resolve.*symlink"; then
  pass "TC-03: symlink resolution (local copy) option found"
else
  fail "TC-03: symlink resolution (local copy) option not found"
fi

# --- Sub-task 2: section diff detection (TC-04 ~ TC-06) ---

# TC-04: Given reference.md dev-crew-installed mode, When reading, Then section diff detection described
echo ""
echo "TC-04: dev-crew-installed mode has section diff detection"
DEV_CREW_SECTION=$(echo "$REF_CONTENT" | sed -n '/dev-crew-installed モード/,/^---$/p')
if echo "$DEV_CREW_SECTION" | grep -qi "セクション.*差分\|セクション.*比較\|section.*diff\|section.*compar"; then
  pass "TC-04: section diff detection found in dev-crew-installed mode"
else
  fail "TC-04: section diff detection not found in dev-crew-installed mode"
fi

# TC-05: Given reference.md, When reading, Then template comparison check items exist
echo ""
echo "TC-05: reference.md has template comparison check items"
if echo "$REF_CONTENT" | grep -qi "テンプレートと比較.*差分\|テンプレート.*比較.*チェック\|比較.*チェック項目"; then
  pass "TC-05: template comparison check items found"
else
  fail "TC-05: template comparison check items not found"
fi

# TC-06: Given reference.md, When reading, Then Codex Integration presence check exists
echo ""
echo "TC-06: reference.md has Codex Integration presence check"
if echo "$REF_CONTENT" | grep -qi "Codex Integration.*有無\|Codex Integration.*チェック\|Codex Integration.*存在"; then
  pass "TC-06: Codex Integration presence check found"
else
  fail "TC-06: Codex Integration presence check not found"
fi

# --- Sub-task 3: update proposal (TC-07 ~ TC-09) ---

# TC-07: Given reference.md, When reading, Then Post-Approve Action format check exists
echo ""
echo "TC-07: reference.md has Post-Approve Action format check"
if echo "$REF_CONTENT" | grep -qi "Post-Approve Action.*チェック\|Post-Approve Action.*形式\|Post-Approve Action.*フォーマット"; then
  pass "TC-07: Post-Approve Action format check found"
else
  fail "TC-07: Post-Approve Action format check not found"
fi

# TC-08: Given reference.md, When reading, Then Workflow line plan review check exists
echo ""
echo "TC-08: reference.md has Workflow line plan review check"
if echo "$REF_CONTENT" | grep -qi "Workflow.*plan review\|plan review.*Workflow\|Codex plan review.*有無"; then
  pass "TC-08: Workflow line plan review check found"
else
  fail "TC-08: Workflow line plan review check not found"
fi

# TC-09: Given reference.md, When reading, Then diff-only section update proposal described
echo ""
echo "TC-09: reference.md has diff-only section update proposal"
if echo "$REF_CONTENT" | grep -qi "差分あり.*のみ.*更新\|差分.*セクションのみ\|差分がある.*セクション.*更新"; then
  pass "TC-09: diff-only section update proposal found"
else
  fail "TC-09: diff-only section update proposal not found"
fi

# --- Constraints + Regression (TC-10 ~ TC-11) ---

# TC-10: Given SKILL.md, When counting lines, Then <= 100 lines
echo ""
echo "TC-10: onboard/SKILL.md stays under 100 lines"
LINE_COUNT=$(wc -l < "$SKILL_FILE")
if [ "$LINE_COUNT" -le 100 ]; then
  pass "TC-10: SKILL.md is $LINE_COUNT lines (<= 100)"
else
  fail "TC-10: SKILL.md is $LINE_COUNT lines (> 100)"
fi

# TC-11: Given existing onboard tests, When running, Then all pass
echo ""
echo "TC-11: Existing onboard tests pass"
REGRESSION_FAIL=0
for test_file in "$BASE_DIR/tests/test-onboard-research.sh" \
                 "$BASE_DIR/tests/test-onboard-discovered.sh"; do
  if [ -f "$test_file" ]; then
    if ! bash "$test_file" > /dev/null 2>&1; then
      REGRESSION_FAIL=1
    fi
  fi
done
# test-spec-onboard-improvements.sh may not exist, check first
if [ -f "$BASE_DIR/tests/test-spec-onboard-improvements.sh" ]; then
  if ! bash "$BASE_DIR/tests/test-spec-onboard-improvements.sh" > /dev/null 2>&1; then
    REGRESSION_FAIL=1
  fi
fi
if [ "$REGRESSION_FAIL" -eq 0 ]; then
  pass "TC-11: Existing onboard tests pass"
else
  fail "TC-11: One or more existing onboard tests failed"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
