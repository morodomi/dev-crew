#!/bin/bash
# test-instinct-paths.sh - Verify instinct storage paths use user-global ~/.claude/dev-crew/
# TC-10: learn skill has no .claude/meta-skills references
# TC-11: evolve skill has no .claude/meta-skills references
# TC-12: observe.sh uses ~/.claude/dev-crew/observations

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== Instinct Path Tests ==="

# TC-10: learn skill has no .claude/meta-skills references
echo ""
echo "TC-10: learn skill has no .claude/meta-skills references"
if grep -r '\.claude/meta-skills' "$BASE_DIR/skills/learn/" >/dev/null 2>&1; then
  fail "learn skill still references .claude/meta-skills"
else
  pass "learn skill has no .claude/meta-skills references"
fi

# TC-11: evolve skill has no .claude/meta-skills references
echo ""
echo "TC-11: evolve skill has no .claude/meta-skills references"
if grep -r '\.claude/meta-skills' "$BASE_DIR/skills/evolve/" >/dev/null 2>&1; then
  fail "evolve skill still references .claude/meta-skills"
else
  pass "evolve skill has no .claude/meta-skills references"
fi

# TC-12: observe.sh uses ~/.claude/dev-crew/observations
echo ""
echo "TC-12: observe.sh uses ~/.claude/dev-crew/observations"
if grep -q '\.claude/dev-crew/observations' "$BASE_DIR/scripts/hooks/observe.sh"; then
  pass "observe.sh uses ~/.claude/dev-crew/observations"
else
  fail "observe.sh does not use ~/.claude/dev-crew/observations"
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
