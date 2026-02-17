#!/bin/bash
# test-stale-references.sh - verify stale references from auto-transition removal are cleaned up
# Issue #28: update stale references after auto-transition removal (#27)
# TC-01 ~ TC-09

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== Stale Reference Tests ==="

# --- generate-e2e/SKILL.md ---

GENERATE_E2E="$BASE_DIR/skills/generate-e2e/SKILL.md"

# TC-01: generate-e2e/SKILL.md does not reference --auto-e2e as a security-scan option
echo ""
echo "TC-01: generate-e2e/SKILL.md does not reference --auto-e2e as a security-scan option"
hits=$(grep -c 'security-scanの--auto-e2e' "$GENERATE_E2E" 2>/dev/null || true)
if [ "$hits" -eq 0 ]; then
  pass "TC-01: No 'security-scanの--auto-e2e' reference found"
else
  fail "TC-01: Found $hits 'security-scanの--auto-e2e' reference(s) -- stale reference"
fi

# TC-02: generate-e2e/SKILL.md references security-audit for --auto-e2e
echo ""
echo "TC-02: generate-e2e/SKILL.md references security-audit for --auto-e2e"
hits=$(grep -c 'security-auditの--auto-e2e' "$GENERATE_E2E" 2>/dev/null || true)
if [ "$hits" -gt 0 ]; then
  pass "TC-02: Found 'security-auditの--auto-e2e' reference"
else
  fail "TC-02: No 'security-auditの--auto-e2e' reference found -- not yet updated"
fi

# --- security-scan/reference.md ---

REFERENCE_MD="$BASE_DIR/skills/security-scan/reference.md"

# TC-03: security-scan/reference.md does not document --no-auto-report option
echo ""
echo "TC-03: security-scan/reference.md does not document --no-auto-report option"
hits=$(grep -c '\-\-no-auto-report' "$REFERENCE_MD" 2>/dev/null || true)
if [ "$hits" -eq 0 ]; then
  pass "TC-03: No '--no-auto-report' reference found"
else
  fail "TC-03: Found $hits '--no-auto-report' reference(s) -- stale option documentation"
fi

# TC-04: security-scan/reference.md does not document --auto-e2e option
echo ""
echo "TC-04: security-scan/reference.md does not document --auto-e2e option"
hits=$(grep -c '\-\-auto-e2e' "$REFERENCE_MD" 2>/dev/null || true)
if [ "$hits" -eq 0 ]; then
  pass "TC-04: No '--auto-e2e' reference found"
else
  fail "TC-04: Found $hits '--auto-e2e' reference(s) -- stale option documentation"
fi

# TC-05: security-scan/reference.md does not have "AUTO TRANSITION" as phase heading
echo ""
echo "TC-05: security-scan/reference.md does not have 'AUTO TRANSITION' as phase heading"
hits=$(grep -c 'Phase 4: AUTO TRANSITION' "$REFERENCE_MD" 2>/dev/null || true)
if [ "$hits" -eq 0 ]; then
  pass "TC-05: No 'Phase 4: AUTO TRANSITION' heading found"
else
  fail "TC-05: Found 'Phase 4: AUTO TRANSITION' heading -- stale phase name"
fi

# TC-06: security-scan/reference.md LEARN Phase does not reference AUTO TRANSITION timing
echo ""
echo "TC-06: security-scan/reference.md does not reference AUTO TRANSITION anywhere"
hits=$(grep -c 'AUTO TRANSITION' "$REFERENCE_MD" 2>/dev/null || true)
if [ "$hits" -eq 0 ]; then
  pass "TC-06: No 'AUTO TRANSITION' references found"
else
  fail "TC-06: Found $hits 'AUTO TRANSITION' reference(s) -- stale timing references"
fi

# --- Regression tests ---

# TC-07: Regression: test-no-auto-transitions.sh still passes
echo ""
echo "TC-07: Regression - test-no-auto-transitions.sh"
if [ -f "$BASE_DIR/tests/test-no-auto-transitions.sh" ]; then
  if bash "$BASE_DIR/tests/test-no-auto-transitions.sh" > /dev/null 2>&1; then
    pass "TC-07: test-no-auto-transitions.sh passes"
  else
    fail "TC-07: test-no-auto-transitions.sh failed"
  fi
else
  fail "TC-07: test-no-auto-transitions.sh not found"
fi

# TC-08: Regression: test-skills-structure.sh still passes
echo ""
echo "TC-08: Regression - test-skills-structure.sh"
if [ -f "$BASE_DIR/tests/test-skills-structure.sh" ]; then
  if bash "$BASE_DIR/tests/test-skills-structure.sh" > /dev/null 2>&1; then
    pass "TC-08: test-skills-structure.sh passes"
  else
    fail "TC-08: test-skills-structure.sh failed"
  fi
else
  fail "TC-08: test-skills-structure.sh not found"
fi

# TC-09: Regression: test-cross-references.sh still passes
echo ""
echo "TC-09: Regression - test-cross-references.sh"
if [ -f "$BASE_DIR/tests/test-cross-references.sh" ]; then
  if bash "$BASE_DIR/tests/test-cross-references.sh" > /dev/null 2>&1; then
    pass "TC-09: test-cross-references.sh passes"
  else
    fail "TC-09: test-cross-references.sh failed"
  fi
else
  fail "TC-09: test-cross-references.sh not found"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
