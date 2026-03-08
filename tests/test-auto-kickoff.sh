#!/bin/bash
# test-auto-kickoff.sh - verify Post-Approve Action documentation in 4 files
# TC-03 ~ TC-06

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== Auto-Kickoff After Plan Approve Tests ==="

# TC-03: CLAUDE.md contains Post-Approve Action in Workflow section
echo ""
echo "TC-03: CLAUDE.md Workflow contains Post-Approve Action"
if grep -q "Post-Approve Action" "$BASE_DIR/CLAUDE.md"; then
  pass "TC-03: CLAUDE.md contains Post-Approve Action"
else
  fail "TC-03: CLAUDE.md missing Post-Approve Action"
fi

# Also check review --plan is in workflow
if grep -q "review --plan" "$BASE_DIR/CLAUDE.md"; then
  pass "TC-03b: CLAUDE.md contains review --plan"
else
  fail "TC-03b: CLAUDE.md missing review --plan"
fi

# TC-04: spec/reference.md Plan File Template contains Post-Approve Action section
echo ""
echo "TC-04: spec/reference.md Plan File Template has Post-Approve Action"
if grep -q "Post-Approve Action" "$BASE_DIR/skills/spec/reference.md"; then
  pass "TC-04: spec/reference.md contains Post-Approve Action"
else
  fail "TC-04: spec/reference.md missing Post-Approve Action"
fi

# TC-05: spec/SKILL.md mentions Post-Approve Action as required
echo ""
echo "TC-05: spec/SKILL.md Step 6 requires Post-Approve Action"
if grep -q "Post-Approve Action" "$BASE_DIR/skills/spec/SKILL.md"; then
  pass "TC-05: spec/SKILL.md contains Post-Approve Action"
else
  fail "TC-05: spec/SKILL.md missing Post-Approve Action"
fi

# TC-06: kickoff/SKILL.md description reflects auto-execution
echo ""
echo "TC-06: kickoff/SKILL.md description reflects auto-execution"
description=$(awk '/^description:/{print; exit}' "$BASE_DIR/skills/kickoff/SKILL.md")
if echo "$description" | grep -qi "auto\|Post-Approve"; then
  pass "TC-06: kickoff/SKILL.md description mentions auto-execution"
else
  fail "TC-06: kickoff/SKILL.md description missing auto-execution mention"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
