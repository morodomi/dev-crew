#!/bin/bash
# test-reference-docs.sh - Reference documentation validation
# T-01, T-02, T-03, T-04

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== Reference Docs Tests ==="

# T-01: docs/codex-patterns.md exists and contains "Codex Detection Patterns"
echo ""
echo "T-01: codex-patterns.md exists and contains heading"
if [ -f "$BASE_DIR/docs/codex-patterns.md" ] && grep -q "Codex Detection Patterns" "$BASE_DIR/docs/codex-patterns.md"; then
  pass "codex-patterns.md exists with correct heading"
else
  fail "codex-patterns.md missing or heading not found"
fi

# T-02: codex-patterns.md contains all 5 pattern names
echo ""
echo "T-02: codex-patterns.md contains all 5 pattern names"
patterns="early-return-case-leak api-input-duplication ambiguous-scope-boundary unused-field-scope-creep hot-loop-redundant-io"
all_found=true
for pattern in $patterns; do
  if ! grep -q "$pattern" "$BASE_DIR/docs/codex-patterns.md"; then
    fail "pattern '$pattern' not found in codex-patterns.md"
    all_found=false
  fi
done
if [ "$all_found" = true ]; then
  pass "all 5 pattern names found"
fi

# T-03: docs/known-gotchas.md exists and contains "Known Gotchas"
echo ""
echo "T-03: known-gotchas.md exists and contains heading"
if [ -f "$BASE_DIR/docs/known-gotchas.md" ] && grep -q "Known Gotchas" "$BASE_DIR/docs/known-gotchas.md"; then
  pass "known-gotchas.md exists with correct heading"
else
  fail "known-gotchas.md missing or heading not found"
fi

# T-04: known-gotchas.md contains "canonicalize" section
echo ""
echo "T-04: known-gotchas.md contains canonicalize section"
if grep -q "canonicalize" "$BASE_DIR/docs/known-gotchas.md"; then
  pass "canonicalize section found"
else
  fail "canonicalize section not found"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
