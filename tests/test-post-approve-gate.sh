#!/bin/bash
# test-post-approve-gate.sh - Tests for plan-exit-flag.sh and post-approve-gate.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FLAG_DIR="${HOME}/.claude/dev-crew"
FLAG_FILE="${FLAG_DIR}/.plan-approved"
PASS=0
FAIL=0

# Save original flag if exists
ORIG_FLAG=""
if [ -f "$FLAG_FILE" ]; then
  ORIG_FLAG=$(cat "$FLAG_FILE")
fi

cleanup() {
  # Restore original flag state
  if [ -n "$ORIG_FLAG" ]; then
    echo "$ORIG_FLAG" > "$FLAG_FILE"
  else
    rm -f "$FLAG_FILE"
  fi
}
trap cleanup EXIT

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo "PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $desc (expected=$expected, actual=$actual)"
    FAIL=$((FAIL + 1))
  fi
}

assert_contains() {
  local desc="$1" expected="$2" actual="$3"
  if echo "$actual" | grep -q "$expected"; then
    echo "PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $desc (expected to contain '$expected')"
    FAIL=$((FAIL + 1))
  fi
}

# --- plan-exit-flag.sh tests ---

echo "=== plan-exit-flag.sh ==="

# Given: no flag file
rm -f "$FLAG_FILE"
# When: plan-exit-flag.sh runs
OUTPUT=$(bash "$SCRIPT_DIR/scripts/hooks/plan-exit-flag.sh" 2>&1)
# Then: flag file is created
assert_eq "creates flag file" "true" "$([ -f "$FLAG_FILE" ] && echo true || echo false)"

# Then: flag file contains ISO timestamp
CONTENT=$(cat "$FLAG_FILE")
assert_eq "flag has ISO timestamp format" "true" "$(echo "$CONTENT" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}T' && echo true || echo false)"

# Then: output tells user to run orchestrate
assert_contains "output mentions orchestrate" "orchestrate" "$OUTPUT"

# --- post-approve-gate.sh tests ---

echo ""
echo "=== post-approve-gate.sh ==="

# Given: no flag file
rm -f "$FLAG_FILE"
# When: post-approve-gate.sh runs
bash "$SCRIPT_DIR/scripts/hooks/post-approve-gate.sh" >/dev/null 2>&1
EXIT_CODE=$?
# Then: exits 0 (allow)
assert_eq "no flag → exit 0 (allow)" "0" "$EXIT_CODE"

# Given: valid flag file (recent timestamp)
date -u +"%Y-%m-%dT%H:%M:%SZ" > "$FLAG_FILE"
# When: post-approve-gate.sh runs
OUTPUT=$(bash "$SCRIPT_DIR/scripts/hooks/post-approve-gate.sh" 2>&1; echo "EXIT:$?")
EXIT_CODE=$(echo "$OUTPUT" | grep -o 'EXIT:[0-9]*' | cut -d: -f2)
OUTPUT=$(echo "$OUTPUT" | grep -v 'EXIT:')
# Then: exits 2 (block)
assert_eq "valid flag → exit 2 (block)" "2" "$EXIT_CODE"

# Then: output mentions orchestrate
assert_contains "block message mentions orchestrate" "orchestrate" "$OUTPUT"

# Given: expired flag file (3 hours ago)
EXPIRED=$(date -u -v-3H +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d "3 hours ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "")
if [ -n "$EXPIRED" ]; then
  echo "$EXPIRED" > "$FLAG_FILE"
  # When: post-approve-gate.sh runs
  bash "$SCRIPT_DIR/scripts/hooks/post-approve-gate.sh" >/dev/null 2>&1
  EXIT_CODE=$?
  # Then: exits 0 (allow, flag expired)
  assert_eq "expired flag → exit 0 (allow)" "0" "$EXIT_CODE"
  # Then: flag file is cleaned up
  assert_eq "expired flag is removed" "false" "$([ -f "$FLAG_FILE" ] && echo true || echo false)"
else
  echo "SKIP: expired flag test (date -v not available)"
fi

# Given: flag cleared by orchestrate (simulated)
date -u +"%Y-%m-%dT%H:%M:%SZ" > "$FLAG_FILE"
rm -f "$FLAG_FILE"
# When: post-approve-gate.sh runs
bash "$SCRIPT_DIR/scripts/hooks/post-approve-gate.sh" >/dev/null 2>&1
EXIT_CODE=$?
# Then: exits 0 (allow)
assert_eq "cleared flag → exit 0 (allow)" "0" "$EXIT_CODE"

# --- Summary ---
echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
