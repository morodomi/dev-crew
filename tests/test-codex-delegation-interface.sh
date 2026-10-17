#!/bin/bash
# test-codex-delegation-interface.sh - Codex delegation interface + competitive review validation
# Phase 11.2 + 11.3: 18 TCs

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== Codex Delegation Interface Tests ==="

# --- red/reference.md ---
echo ""
echo "--- red/reference.md ---"

echo "TC-01: red/reference.md contains Codex heading"
if grep -q '## Codex' "$BASE_DIR/skills/red/reference.md"; then
  pass "red/reference.md contains Codex heading"
else
  fail "red/reference.md missing Codex heading"
fi

echo "TC-02: red/reference.md contains fallback mention"
if grep -qi 'fallback' "$BASE_DIR/skills/red/reference.md"; then
  pass "red/reference.md contains fallback mention"
else
  fail "red/reference.md missing fallback mention"
fi

echo "TC-03: red/reference.md contains steps-codex.md reference"
if grep -q 'steps-codex' "$BASE_DIR/skills/red/reference.md"; then
  pass "red/reference.md references steps-codex.md"
else
  fail "red/reference.md missing steps-codex.md reference"
fi

# --- green/reference.md ---
echo ""
echo "--- green/reference.md ---"

echo "TC-04: green/reference.md contains Codex heading"
if grep -q '## Codex' "$BASE_DIR/skills/green/reference.md"; then
  pass "green/reference.md contains Codex heading"
else
  fail "green/reference.md missing Codex heading"
fi

echo "TC-05: green/reference.md contains fallback mention"
if grep -qi 'fallback' "$BASE_DIR/skills/green/reference.md"; then
  pass "green/reference.md contains fallback mention"
else
  fail "green/reference.md missing fallback mention"
fi

echo "TC-06: green/reference.md contains steps-codex.md reference"
if grep -q 'steps-codex' "$BASE_DIR/skills/green/reference.md"; then
  pass "green/reference.md references steps-codex.md"
else
  fail "green/reference.md missing steps-codex.md reference"
fi

# --- steps-codex.md ---
echo ""
echo "--- steps-codex.md ---"

# REVIEW 節（`### REVIEW` 始まりの見出しから、コードフェンス外の次の H1-H3 見出しまで）。節の外の言及で通らないよう、先に切り出す
REVIEW_SEC=$(awk '
  /^```/ { fence = !fence }
  !fence && /^#+ / {
    match($0, /^#+/)
    if (on && RLENGTH <= 3) on = 0
    if (index($0, "### REVIEW") == 1) { on = 1; next }
  }
  on { print }
' "$BASE_DIR/skills/orchestrate/steps-codex.md")

echo "TC-07: steps-codex.md REVIEW section runs Codex as the adversarial reviewer (read-only, new session)"
if [ -n "$REVIEW_SEC" ] && \
   grep -qF 'codex exec --sandbox read-only' <<< "$REVIEW_SEC" && \
   grep -qF '敵対的レビュー' <<< "$REVIEW_SEC"; then
  pass "steps-codex.md REVIEW runs Codex as the adversarial reviewer"
else
  fail "steps-codex.md REVIEW missing Codex adversarial review"
fi

echo "TC-08: steps-codex.md does NOT contain 'supplementary'"
if grep -qi 'supplementary' "$BASE_DIR/skills/orchestrate/steps-codex.md"; then
  fail "steps-codex.md still contains 'supplementary'"
else
  pass "steps-codex.md does not contain 'supplementary'"
fi

echo "TC-09: steps-codex.md does NOT contain 'advisory'"
if grep -qi 'advisory' "$BASE_DIR/skills/orchestrate/steps-codex.md"; then
  fail "steps-codex.md still contains 'advisory'"
else
  pass "steps-codex.md does not contain 'advisory'"
fi

echo "TC-10: findings are triaged into 直す / 人間に戻す / 記録のみ (adversarial-review.md referenced from steps-codex.md)"
if [ -n "$REVIEW_SEC" ] && grep -qF 'adversarial-review.md' <<< "$REVIEW_SEC" && \
   grep -q '直す' "$BASE_DIR/skills/orchestrate/adversarial-review.md" && \
   grep -q '人間に戻す' "$BASE_DIR/skills/orchestrate/adversarial-review.md" && \
   grep -q '記録のみ' "$BASE_DIR/skills/orchestrate/adversarial-review.md"; then
  pass "findings triage categories defined and referenced"
else
  fail "steps-codex.md / adversarial-review.md missing findings triage"
fi

echo "TC-11: steps-codex.md REVIEW section has the 人間に戻す hand-off, and SKILL.md Block 2e still records DISCOVERED"
# DISCOVERED は REVIEW 節でなく次の Block 2e の責務
if [ -n "$REVIEW_SEC" ] && grep -qF '人間に戻す' <<< "$REVIEW_SEC" && \
   grep -qF '#### Block 2e: DISCOVERED' "$BASE_DIR/skills/orchestrate/SKILL.md"; then
  pass "steps-codex.md REVIEW has 人間に戻す, SKILL.md has Block 2e DISCOVERED"
else
  fail "steps-codex.md REVIEW missing 人間に戻す, or SKILL.md missing Block 2e DISCOVERED"
fi

# --- review skill ---
echo ""
echo "--- review skill ---"

echo "TC-12: review/SKILL.md contains Codex section"
if grep -q 'Codex' "$BASE_DIR/skills/review/SKILL.md"; then
  pass "review/SKILL.md contains Codex section"
else
  fail "review/SKILL.md missing Codex section"
fi

echo "TC-13: review/steps-subagent.md contains Codex cross-reference"
if grep -qi 'codex\|steps-codex' "$BASE_DIR/skills/review/steps-subagent.md"; then
  pass "review/steps-subagent.md contains Codex cross-reference"
else
  fail "review/steps-subagent.md missing Codex cross-reference"
fi

echo "TC-14: review/reference.md contains Competitive Review section"
if grep -q 'Competitive Review' "$BASE_DIR/skills/review/reference.md"; then
  pass "review/reference.md contains Competitive Review section"
else
  fail "review/reference.md missing Competitive Review section"
fi

echo "TC-15: review/reference.md contains Accept/Reject/AskUserQuestion"
if grep -q 'Accept' "$BASE_DIR/skills/review/reference.md" && \
   grep -q 'Reject' "$BASE_DIR/skills/review/reference.md" && \
   grep -q 'AskUserQuestion' "$BASE_DIR/skills/review/reference.md"; then
  pass "review/reference.md contains Accept/Reject/AskUserQuestion"
else
  fail "review/reference.md missing Accept/Reject/AskUserQuestion"
fi

# --- refactor skill ---
echo ""
echo "--- refactor skill ---"

echo "TC-16: refactor/SKILL.md contains Codex mention"
if grep -qi 'codex\|cross-tool' "$BASE_DIR/skills/refactor/SKILL.md"; then
  pass "refactor/SKILL.md contains Codex mention"
else
  fail "refactor/SKILL.md missing Codex mention"
fi

# --- constraints ---
echo ""
echo "--- Constraints ---"

echo "TC-17: All modified SKILL.md files under 100 lines"
all_under=true
for f in "$BASE_DIR/skills/review/SKILL.md" "$BASE_DIR/skills/refactor/SKILL.md"; do
  lines=$(wc -l < "$f" | tr -d ' ')
  if [ "$lines" -ge 100 ]; then
    fail "$(basename "$(dirname "$f")")/SKILL.md has $lines lines (>= 100)"
    all_under=false
  fi
done
if $all_under; then
  pass "All modified SKILL.md files under 100 lines"
fi

# --- Regression ---
echo ""
echo "--- Regression ---"

echo "TC-18: Key existing tests pass"
regression_pass=true
for test_file in test-refactor-rebuild.sh test-subagent-task-delegation.sh test-plugin-structure.sh; do
  if [ -f "$BASE_DIR/tests/$test_file" ]; then
    if ! bash "$BASE_DIR/tests/$test_file" > /dev/null 2>&1; then
      fail "Existing test failed: $test_file"
      regression_pass=false
    fi
  fi
done
if $regression_pass; then
  pass "Key existing tests pass"
fi

# === Summary ===
echo ""
echo "=== Summary ==="
TOTAL=$((PASS + FAIL))
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $TOTAL"

[ "$FAIL" -eq 0 ] || exit 1
