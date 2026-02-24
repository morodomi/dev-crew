#!/bin/bash
# test-commit-auto-learn.sh - Verify auto-learn integration in commit skill
# TC-25: commit SKILL.md mentions auto-learn
# TC-26: commit SKILL.md mentions DEV_CREW_AUTO_LEARN
# TC-27: commit SKILL.md mentions observation threshold
# TC-28: commit reference.md documents auto-learn trigger conditions
# TC-29: commit reference.md documents non-blocking failure behavior
# TC-30: learn SKILL.md mentions .last-learn-timestamp update
# TC-31: learn reference.md documents .last-learn-timestamp management

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== Commit Auto-Learn Tests ==="

# TC-25: commit SKILL.md mentions auto-learn
echo ""
echo "TC-25: commit SKILL.md mentions auto-learn"
if grep -qi 'auto.learn' "$BASE_DIR/skills/commit/SKILL.md"; then
  pass "commit SKILL.md mentions auto-learn"
else
  fail "commit SKILL.md does NOT mention auto-learn"
fi

# TC-26: commit SKILL.md mentions DEV_CREW_AUTO_LEARN
echo ""
echo "TC-26: commit SKILL.md mentions DEV_CREW_AUTO_LEARN"
if grep -q 'DEV_CREW_AUTO_LEARN' "$BASE_DIR/skills/commit/SKILL.md"; then
  pass "commit SKILL.md mentions DEV_CREW_AUTO_LEARN"
else
  fail "commit SKILL.md does NOT mention DEV_CREW_AUTO_LEARN"
fi

# TC-27: commit SKILL.md mentions observation threshold
echo ""
echo "TC-27: commit SKILL.md mentions observation threshold"
if grep -qE '20.*件|20 件|20件|threshold.*20|>= *20|>=20|-ge 20' "$BASE_DIR/skills/commit/SKILL.md"; then
  pass "commit SKILL.md mentions observation threshold (20)"
else
  fail "commit SKILL.md does NOT mention observation threshold"
fi

# TC-28: commit reference.md documents auto-learn trigger conditions
echo ""
echo "TC-28: commit reference.md documents auto-learn trigger conditions"
if grep -q 'DEV_CREW_AUTO_LEARN' "$BASE_DIR/skills/commit/reference.md" && \
   grep -q 'log\.jsonl' "$BASE_DIR/skills/commit/reference.md" && \
   grep -qE '20.*件|20 件|threshold.*20|20件' "$BASE_DIR/skills/commit/reference.md"; then
  pass "commit reference.md documents auto-learn trigger conditions"
else
  fail "commit reference.md does NOT document all auto-learn trigger conditions"
fi

# TC-29: commit reference.md documents non-blocking failure behavior
echo ""
echo "TC-29: commit reference.md documents non-blocking failure behavior"
if grep -qi 'best.effort\|ブロックしない\|non.blocking' "$BASE_DIR/skills/commit/reference.md" && \
   grep -qi '警告\|warn' "$BASE_DIR/skills/commit/reference.md"; then
  pass "commit reference.md documents non-blocking failure behavior"
else
  fail "commit reference.md does NOT document non-blocking failure behavior"
fi

# TC-30: learn SKILL.md mentions .last-learn-timestamp update
echo ""
echo "TC-30: learn SKILL.md mentions .last-learn-timestamp update"
if grep -q 'last-learn-timestamp' "$BASE_DIR/skills/learn/SKILL.md"; then
  pass "learn SKILL.md mentions .last-learn-timestamp update"
else
  fail "learn SKILL.md does NOT mention .last-learn-timestamp update"
fi

# TC-31: learn reference.md documents .last-learn-timestamp management
echo ""
echo "TC-31: learn reference.md documents .last-learn-timestamp management"
if grep -q 'last-learn-timestamp' "$BASE_DIR/skills/learn/reference.md" && \
   grep -qE 'ISO.8601|UTC|%Y-%m-%dT' "$BASE_DIR/skills/learn/reference.md"; then
  pass "learn reference.md documents .last-learn-timestamp management"
else
  fail "learn reference.md does NOT document .last-learn-timestamp management"
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
