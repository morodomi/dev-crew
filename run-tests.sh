#!/bin/bash
# Run all tests in tests/ and report results.

set -uo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
PASS=0
FAIL=0
FAILED_TESTS=()

for f in "$BASE_DIR"/tests/test-*.sh; do
  [ -f "$f" ] || continue
  name=$(basename "$f")
  if bash "$f" > /dev/null 2>&1; then
    printf "  \033[32mPASS\033[0m %s\n" "$name"
    PASS=$((PASS + 1))
  else
    printf "  \033[31mFAIL\033[0m %s\n" "$name"
    FAIL=$((FAIL + 1))
    FAILED_TESTS+=("$name")
  fi
done

echo ""
echo "=== Results ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "Failed tests:"
  for t in "${FAILED_TESTS[@]}"; do
    echo "  - $t"
  done
  exit 1
fi
