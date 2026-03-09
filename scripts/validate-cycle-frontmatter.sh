#!/bin/bash
# validate-cycle-frontmatter.sh - Validate Cycle doc frontmatter field values
# Usage: bash scripts/validate-cycle-frontmatter.sh <cycle-doc.md>
# Exit: 0 = PASS, 1 = FAIL (errors printed to stderr)

set -euo pipefail

if [ $# -ne 1 ] || [ ! -f "$1" ]; then
  echo "Usage: $0 <cycle-doc.md>" >&2
  exit 1
fi

FILE="$1"
ERRORS=0

error() { echo "ERROR: $1" >&2; ERRORS=$((ERRORS + 1)); }

# Extract frontmatter (between first --- and second ---)
IN_FM=0
FM_DONE=0
FM=""
BODY=""
while IFS= read -r line; do
  if [ "$FM_DONE" -eq 1 ]; then
    BODY="$BODY
$line"
  elif [ "$IN_FM" -eq 0 ] && [ "$line" = "---" ]; then
    IN_FM=1
  elif [ "$IN_FM" -eq 1 ] && [ "$line" = "---" ]; then
    FM_DONE=1
  elif [ "$IN_FM" -eq 1 ]; then
    FM="$FM
$line"
  fi
done < "$FILE"

# Guard: frontmatter must be properly closed
if [ "$FM_DONE" -eq 0 ]; then
  echo "ERROR: frontmatter not closed (missing closing ---)" >&2
  exit 1
fi

# Helper: extract value for a key from frontmatter
fm_val() { echo "$FM" | grep "^$1:" | head -1 | sed "s/^$1: *//"; }

# 1. phase validation
PHASE=$(fm_val phase)
case "$PHASE" in
  INIT|KICKOFF|RED|GREEN|REFACTOR|REVIEW|COMMIT|DONE) ;;
  *) error "invalid phase value: '$PHASE'" ;;
esac

# 2. complexity validation
COMPLEXITY=$(fm_val complexity)
case "$COMPLEXITY" in
  trivial|standard|complex) ;;
  *) error "invalid complexity value: '$COMPLEXITY'" ;;
esac

# 3. test_count validation (positive integer >= 1)
TEST_COUNT=$(fm_val test_count)
if echo "$TEST_COUNT" | grep -qE '^[0-9]+$' && [ "$TEST_COUNT" -ge 1 ]; then
  : # valid
else
  error "test_count must be positive integer: '$TEST_COUNT'"
fi

# 4. risk_level validation
RISK_LEVEL=$(fm_val risk_level)
case "$RISK_LEVEL" in
  low|medium|high) ;;
  *) error "invalid risk_level value: '$RISK_LEVEL'" ;;
esac

# 5. body contamination check
for FIELD in phase complexity test_count risk_level; do
  if echo "$BODY" | grep -q "^${FIELD}:"; then
    error "state-like metadata in body: '${FIELD}:'"
  fi
done

[ "$ERRORS" -eq 0 ] && exit 0 || exit 1
