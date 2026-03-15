#!/bin/bash
# test-pre-red-gate.sh - pre-red-gate.sh deterministic gate tests
# T-01: BLOCK when no Cycle doc exists
# T-02: BLOCK when sync-plan not recorded in Progress Log
# T-03: BLOCK when Plan Review not recorded in Progress Log
# T-04: PASS when all conditions met
# T-05: Script exits with 0 on PASS, 1 on BLOCK

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$BASE_DIR/scripts/gates/pre-red-gate.sh"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== Pre-RED Gate Tests ==="

# Setup: create temp directory structure
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

mkdir -p "$TMPDIR/docs/cycles"

# T-01: BLOCK when no Cycle doc exists (no non-DONE cycle)
echo ""
echo "T-01: BLOCK when no Cycle doc exists"

# Create a DONE cycle doc only
cat > "$TMPDIR/docs/cycles/20260315_1200_done.md" <<'CYCLE'
---
phase: DONE
---
# Done cycle
CYCLE

output=$(bash "$SCRIPT" "$TMPDIR" 2>&1) && rc=$? || rc=$?
if [ "$rc" -eq 1 ] && echo "$output" | grep -qi "cycle doc"; then
  pass "BLOCK on no active Cycle doc"
else
  fail "Expected BLOCK (exit 1) on no active Cycle doc, got rc=$rc output: $output"
fi

# T-02: BLOCK when sync-plan not recorded
echo ""
echo "T-02: BLOCK when sync-plan not recorded in Progress Log"

cat > "$TMPDIR/docs/cycles/20260315_1300_active.md" <<'CYCLE'
---
phase: RED
---
# Active cycle

## Progress Log

### 2026-03-15 - SPEC
- Initial spec
- Phase completed
CYCLE

output=$(bash "$SCRIPT" "$TMPDIR" 2>&1) && rc=$? || rc=$?
if [ "$rc" -eq 1 ] && echo "$output" | grep -qiE "sync.plan|SYNC.PLAN"; then
  pass "BLOCK on missing sync-plan record"
else
  fail "Expected BLOCK on missing sync-plan, got rc=$rc output: $output"
fi

# T-03: BLOCK when Plan Review not recorded
echo ""
echo "T-03: BLOCK when Plan Review not recorded in Progress Log"

cat > "$TMPDIR/docs/cycles/20260315_1300_active.md" <<'CYCLE'
---
phase: RED
---
# Active cycle

## Progress Log

### 2026-03-15 - SPEC
- Initial spec
- Phase completed

### 2026-03-15 - SYNC-PLAN
- Cycle doc generated
- Phase completed
CYCLE

output=$(bash "$SCRIPT" "$TMPDIR" 2>&1) && rc=$? || rc=$?
if [ "$rc" -eq 1 ] && echo "$output" | grep -qiE "plan.review|Plan Review"; then
  pass "BLOCK on missing Plan Review record"
else
  fail "Expected BLOCK on missing Plan Review, got rc=$rc output: $output"
fi

# T-04: PASS when all conditions met
echo ""
echo "T-04: PASS when all conditions met"

cat > "$TMPDIR/docs/cycles/20260315_1300_active.md" <<'CYCLE'
---
phase: RED
---
# Active cycle

## Progress Log

### 2026-03-15 - SPEC
- Initial spec
- Phase completed

### 2026-03-15 - SYNC-PLAN
- Cycle doc generated
- Phase completed

### 2026-03-15 - Plan Review
- Design review passed
- Phase completed
CYCLE

output=$(bash "$SCRIPT" "$TMPDIR" 2>&1) && rc=$? || rc=$?
if [ "$rc" -eq 0 ]; then
  pass "PASS when all conditions met"
else
  fail "Expected PASS (exit 0), got rc=$rc output: $output"
fi

# T-05: Exit codes are correct (0=PASS, 1=BLOCK)
echo ""
echo "T-05: Script file exists and is executable-compatible"

if [ -f "$SCRIPT" ]; then
  pass "Script file exists"
else
  fail "Script file does not exist at $SCRIPT"
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
