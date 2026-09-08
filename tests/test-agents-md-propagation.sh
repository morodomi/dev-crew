#!/bin/bash
# test-agents-md-propagation.sh - AGENTS.md propagation tests across skills
# TC-08

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

COMMIT_SKILL="$BASE_DIR/skills/commit/SKILL.md"

# 存在確認は残存 TC が実際に読むファイルだけに限定する。無関係なファイルを
# 要求すると、そのファイルが将来リネーム・削除された際に fail() を経由せず
# exit 1 で即死し Summary へ到達しない（無警告の hard-exit）。
for f in "$COMMIT_SKILL"; do
  [ -f "$f" ] || { echo "ERROR: $f not found"; exit 1; }
done

echo "=== AGENTS.md Propagation Tests ==="
echo ""

# TC-08: Given commit/SKILL.md, When reading doc table, Then AGENTS.md is listed
echo "TC-08: commit/SKILL.md doc update table has AGENTS.md"
if grep -q "AGENTS.md" "$COMMIT_SKILL"; then
  pass "TC-08: AGENTS.md found in commit/SKILL.md"
else
  fail "TC-08: AGENTS.md not found in commit/SKILL.md"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
