#!/bin/bash
# test-evolve-contribute.sh - Verify evolve contribute mode design
# TC-15: evolve SKILL.md mentions contribute mode
# TC-16: evolve mentions structure validation test execution
# TC-17: evolve SKILL.md contains Step 6 "Contribute"

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== Evolve Contribute Tests ==="

# TC-15: evolve SKILL.md mentions contribute mode
echo ""
echo "TC-15: evolve SKILL.md mentions contribute mode"
if grep -qi 'contribute' "$BASE_DIR/skills/evolve/SKILL.md"; then
  pass "evolve SKILL.md mentions contribute mode"
else
  fail "evolve SKILL.md does not mention contribute mode"
fi

# TC-16: evolve mentions structure validation test execution
echo ""
echo "TC-16: evolve mentions structure validation test execution"
if grep -q 'test' "$BASE_DIR/skills/evolve/SKILL.md" && grep -q 'structure\|validation\|test-.*-structure' "$BASE_DIR/skills/evolve/SKILL.md"; then
  pass "evolve mentions structure validation"
else
  fail "evolve does not mention structure validation"
fi

# TC-17: evolve SKILL.md contains Step 6 "Contribute"
echo ""
echo "TC-17: evolve SKILL.md contains Step 6 Contribute"
if grep -q 'Step 6.*[Cc]ontribute' "$BASE_DIR/skills/evolve/SKILL.md"; then
  pass "evolve SKILL.md contains Step 6 Contribute"
else
  fail "evolve SKILL.md does not contain Step 6 Contribute"
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
