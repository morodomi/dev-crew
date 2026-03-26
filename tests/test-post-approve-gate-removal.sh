#!/bin/bash
# test-post-approve-gate-removal.sh - post-approve-gate フラグ廃止の検証
# TC-01: hooks.json に ExitPlanMode エントリがない
# TC-02: hooks.json に post-approve-gate エントリがない
# TC-03: plan-exit-flag.sh が存在しない
# TC-04: post-approve-gate.sh が存在しない
# TC-05: orchestrate SKILL.md に TaskCreate 指示がある
# TC-06: test-hooks-structure.sh に TC-11/TC-12 がない（回帰防止）

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

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS"
echo "FAIL: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi

exit 0
