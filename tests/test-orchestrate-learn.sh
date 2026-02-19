#!/bin/bash
# test-orchestrate-learn.sh - Verify auto-learn trigger in orchestrate Block 3
# TC-18: steps-subagent.md Block 3 references learn
# TC-19: steps-teams.md Block 3 references learn
# TC-20: orchestrate mentions DEV_CREW_AUTO_LEARN environment variable
# TC-21: orchestrate mentions observations file check

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== Orchestrate Learn Tests ==="

# TC-18: steps-subagent.md Block 3 references learn
echo ""
echo "TC-18: steps-subagent.md Block 3 references learn"
# Check that learn appears after "Block 3" in the file
if awk '/Block 3/,0' "$BASE_DIR/skills/orchestrate/steps-subagent.md" | grep -qi 'learn'; then
  pass "steps-subagent.md Block 3 references learn"
else
  fail "steps-subagent.md Block 3 does not reference learn"
fi

# TC-19: steps-teams.md Block 3 references learn
echo ""
echo "TC-19: steps-teams.md Block 3 references learn"
if awk '/Block 3/,0' "$BASE_DIR/skills/orchestrate/steps-teams.md" | grep -qi 'learn'; then
  pass "steps-teams.md Block 3 references learn"
else
  fail "steps-teams.md Block 3 does not reference learn"
fi

# TC-20: orchestrate mentions DEV_CREW_AUTO_LEARN environment variable
echo ""
echo "TC-20: orchestrate mentions DEV_CREW_AUTO_LEARN"
if grep -rq 'DEV_CREW_AUTO_LEARN' "$BASE_DIR/skills/orchestrate/"; then
  pass "orchestrate mentions DEV_CREW_AUTO_LEARN"
else
  fail "orchestrate does not mention DEV_CREW_AUTO_LEARN"
fi

# TC-21: orchestrate mentions observations file check
echo ""
echo "TC-21: orchestrate mentions observations file check"
if grep -rq 'observations.*log\.jsonl\|log\.jsonl.*observations' "$BASE_DIR/skills/orchestrate/"; then
  pass "orchestrate mentions observations file check"
else
  fail "orchestrate does not mention observations file check"
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
