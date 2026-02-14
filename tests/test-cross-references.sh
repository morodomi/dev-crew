#!/bin/bash
# test-cross-references.sh - verify all skill/agent references use dev-crew: prefix
# TC-01 ~ TC-06

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== Cross-Reference Tests ==="

# TC-01: No Skill/Task references with "core:" prefix (excluding "dev-crew:")
echo ""
echo "TC-01: No 'core:' references (excluding dev-crew:)"
# Match core: but not dev-crew: or redteam-core:
hits=$(grep -rn '"core:' "$BASE_DIR/skills" "$BASE_DIR/agents" --include='*.md' 2>/dev/null | grep -v 'dev-crew:' || true)
if [ -z "$hits" ]; then
  # Also check Skill(core: pattern without quotes
  hits2=$(grep -rn 'Skill(core:' "$BASE_DIR/skills" "$BASE_DIR/agents" --include='*.md' 2>/dev/null || true)
  if [ -z "$hits2" ]; then
    pass "No 'core:' references found"
  else
    fail "Found 'core:' references:"
    echo "$hits2" | head -5
  fi
else
  fail "Found 'core:' references:"
  echo "$hits" | head -5
fi

# TC-02: No "redteam-core:" references
echo ""
echo "TC-02: No 'redteam-core:' references"
hits=$(grep -rn 'redteam-core:' "$BASE_DIR/skills" "$BASE_DIR/agents" --include='*.md' 2>/dev/null || true)
if [ -z "$hits" ]; then
  pass "No 'redteam-core:' references found"
else
  fail "Found 'redteam-core:' references:"
  echo "$hits" | head -5
fi

# TC-03: No "meta-skills:" references
echo ""
echo "TC-03: No 'meta-skills:' references"
hits=$(grep -rn 'meta-skills:' "$BASE_DIR/skills" "$BASE_DIR/agents" --include='*.md' 2>/dev/null || true)
if [ -z "$hits" ]; then
  pass "No 'meta-skills:' references found"
else
  fail "Found 'meta-skills:' references:"
  echo "$hits" | head -5
fi

# TC-04: dev-crew: references exist
echo ""
echo "TC-04: dev-crew: references exist"
count=$(grep -rn 'dev-crew:' "$BASE_DIR/skills" "$BASE_DIR/agents" --include='*.md' 2>/dev/null | wc -l | tr -d ' ')
if [ "$count" -gt 0 ]; then
  pass "Found $count 'dev-crew:' references"
else
  fail "No 'dev-crew:' references found"
fi

# TC-05: Structure validation passes
echo ""
echo "TC-05: Structure validation"
if bash "$BASE_DIR/tests/test-skills-structure.sh" > /dev/null 2>&1 && \
   bash "$BASE_DIR/tests/test-agents-structure.sh" > /dev/null 2>&1; then
  pass "Structure validation passes"
else
  fail "Structure validation failed"
fi

# TC-06: No "tdd-core:" references
echo ""
echo "TC-06: No 'tdd-core:' references"
hits=$(grep -rn 'tdd-core:' "$BASE_DIR/skills" "$BASE_DIR/agents" --include='*.md' 2>/dev/null || true)
if [ -z "$hits" ]; then
  pass "No 'tdd-core:' references found"
else
  fail "Found 'tdd-core:' references:"
  echo "$hits" | head -5
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
