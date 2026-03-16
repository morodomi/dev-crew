#!/usr/bin/env bash
# Test: Socrates Devil's Advocate review pipeline integration (Phase 15.3)
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

PASS=0
FAIL=0

assert() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "  PASS: $desc"
    ((PASS++))
  else
    echo "  FAIL: $desc"
    ((FAIL++))
  fi
}

assert_not() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "  FAIL: $desc"
    ((FAIL++))
  else
    echo "  PASS: $desc"
    ((PASS++))
  fi
}

echo "=== Socrates Review Integration Tests ==="

# TC-01: steps-subagent.md に "Step 4.5" または "Devil's Advocate" が含まれる
assert "TC-01: steps-subagent.md contains Step 4.5 or Devil's Advocate" \
  grep -qE "Step 4\.5|Devil's Advocate" "$BASE_DIR/skills/review/steps-subagent.md"

# TC-02: steps-subagent.md に socrates の Task 呼び出しが含まれる
assert "TC-02: steps-subagent.md contains socrates Task invocation" \
  grep -q "dev-crew:socrates" "$BASE_DIR/skills/review/steps-subagent.md"

# TC-03: reference.md に Score Escalation セクションが含まれる
assert "TC-03: reference.md contains Score Escalation section" \
  grep -q "Score Escalation" "$BASE_DIR/skills/review/reference.md"

# TC-04: reference.md に PASS から WARN への昇格ルールが含まれる
assert "TC-04: reference.md contains PASS to WARN escalation rule" \
  grep -q "WARN.*昇格" "$BASE_DIR/skills/review/reference.md"

# TC-05: socrates.md の description に review pipeline 関連の記述がある
assert "TC-05: socrates.md description mentions review pipeline" \
  grep -qE "review pipeline|全判定|Devil's Advocate" "$BASE_DIR/agents/socrates.md"

# TC-06: socrates.md の description に「WARN/BLOCK時」が含まれない（旧表現の除去確認）
assert_not "TC-06: socrates.md description does NOT contain old WARN/BLOCK trigger" \
  grep -q "WARN/BLOCK時" "$BASE_DIR/agents/socrates.md"

# TC-07: ROADMAP.md に Phase 15.3 が含まれる
assert "TC-07: ROADMAP.md contains Phase 15.3" \
  grep -q "15\.3" "$BASE_DIR/ROADMAP.md"

# TC-08: リグレッション: 直接関連する既存テスト通過
echo ""
echo "--- TC-08: Regression (related tests) ---"
REG_FAIL=0
RELATED_TESTS=(
  "test-agents-structure.sh"
  "test-plugin-structure.sh"
  "test-test-reviewer.sh"
)
for fname in "${RELATED_TESTS[@]}"; do
  f="$BASE_DIR/tests/$fname"
  [ -f "$f" ] || continue
  if bash "$f" >/dev/null 2>&1; then
    :
  else
    echo "  REGRESSION FAIL: $fname"
    REG_FAIL=1
  fi
done
if [ "$REG_FAIL" -eq 0 ]; then
  echo "  PASS: TC-08: Related tests pass"
  ((PASS++))
else
  echo "  FAIL: TC-08: Regression detected"
  ((FAIL++))
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
