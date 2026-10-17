#!/usr/bin/env bash
# Test: steps-codex.md improvements (Issue 4 - v2.1.0)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
STEPS_CODEX="$BASE_DIR/skills/orchestrate/steps-codex.md"

PASS=0
FAIL=0

assert() {
  local desc="$1"
  local result="$2"
  if [ "$result" = "0" ]; then
    echo "PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $desc"
    FAIL=$((FAIL + 1))
  fi
}

# REVIEW 節（`### REVIEW` 始まりの見出しから、コードフェンス外の次の H1-H3 見出しまで）を出す
review_section() {
  awk '
    /^```/ { fence = !fence }
    !fence && /^#+ / {
      match($0, /^#+/)
      if (on && RLENGTH <= 3) on = 0
      if (index($0, "### REVIEW") == 1) { on = 1; next }
    }
    on { print }
  ' "$STEPS_CODEX"
}
REVIEW_SEC=$(review_section)

# T-01: steps-codex.md の REVIEW 節は対象ファイルの一覧（git diff HEAD --name-only + 未追跡）をレビュー入力に限る
# set -e で止まらないよう、&& でつながず if で rc を取る
if [ -n "$REVIEW_SEC" ] \
   && grep -qF "git diff HEAD --name-only" <<< "$REVIEW_SEC" \
   && grep -qF "git ls-files --others --exclude-standard" <<< "$REVIEW_SEC" \
   && grep -qF "対象ファイルの一覧" <<< "$REVIEW_SEC"; then
  rc=0
else
  rc=1
fi
assert "T-01: steps-codex.md REVIEW section scopes the review input to the changed-file list" "$rc"

# T-02: code REVIEW は競争的レビューでなく敵対的レビュー 1 回（旧 Why Competitive Review Works 節は無く、REVIEW 節に「再レビューしない」がある）
if [ -n "$REVIEW_SEC" ] \
   && ! grep -qF "### Why Competitive Review Works" "$STEPS_CODEX" \
   && grep -qF "再レビューしない" <<< "$REVIEW_SEC"; then
  rc=0
else
  rc=1
fi
assert "T-02: steps-codex.md REVIEW section is a single adversarial review (no competitive-review rationale section)" "$rc"

# T-03: steps-codex.md contains "Open Questions Response" section
grep -q "### Open Questions Response" "$STEPS_CODEX"
assert "T-03: steps-codex.md contains Open Questions Response section" "$?"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
