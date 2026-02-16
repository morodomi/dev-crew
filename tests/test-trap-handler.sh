#!/bin/bash
# test-trap-handler.sh - trap handler validation for test-hooks-structure.sh
# T-01: Trap handler cleans up on normal exit
# T-02: Trap handler registers EXIT INT TERM signals
# T-03: Inline cleanup removed (trap handles it)
# T-04: All existing tests still pass

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== Trap Handler Tests ==="

# T-01: Trap handler cleans up on normal exit
echo ""
echo "T-01: Trap handler cleans up on normal exit"

# Check if trap handler exists in test-hooks-structure.sh
if grep -q "^trap" "$BASE_DIR/tests/test-hooks-structure.sh" && \
   grep -q "cleanup()" "$BASE_DIR/tests/test-hooks-structure.sh"; then
  pass "Trap handler found in test-hooks-structure.sh"
else
  fail "Trap handler NOT found in test-hooks-structure.sh"
fi

# T-02: Trap handler cleans up on INT/TERM signal
echo ""
echo "T-02: Trap handler registers EXIT INT TERM signals"

# Check if trap registers proper signals
if grep -q "trap.*EXIT.*INT.*TERM" "$BASE_DIR/tests/test-hooks-structure.sh" || \
   grep -q "trap.*EXIT INT TERM" "$BASE_DIR/tests/test-hooks-structure.sh"; then
  pass "Trap handler registers EXIT INT TERM signals"
else
  fail "Trap handler does NOT register EXIT INT TERM signals"
fi

# T-03: Inline cleanup removed (trap handles it)
echo ""
echo "T-03: Inline cleanup removed (trap handles it)"

# Check that test-hooks-structure.sh does NOT have inline rm commands after TC-03
if grep -q "^rm -f.*TEMP_AGENT" "$BASE_DIR/tests/test-hooks-structure.sh" || \
   grep -q "^rm -rf.*TEMP_SKILL_DIR" "$BASE_DIR/tests/test-hooks-structure.sh"; then
  fail "Inline cleanup commands still present (should be removed, trap should handle it)"
else
  pass "Inline cleanup commands removed (trap handles cleanup)"
fi

# T-04: All existing tests still pass
echo ""
echo "T-04: All existing tests still pass"

if bash "$BASE_DIR/tests/test-hooks-structure.sh" >/dev/null 2>&1; then
  pass "test-hooks-structure.sh all tests PASS (exit code 0)"
else
  fail "test-hooks-structure.sh has failing tests (exit code non-zero)"
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
