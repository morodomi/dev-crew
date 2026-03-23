#!/bin/bash
# test-pre-commit-gate.sh - pre-commit-gate.sh deterministic gate tests
# T-01: BLOCK when REVIEW not recorded in Progress Log
# T-02: PASS when REVIEW recorded (no codex)
# T-03: STATUS.md test script count warning (mismatch)
# T-04: PASS when all conditions met with matching STATUS.md

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$BASE_DIR/scripts/gates/pre-commit-gate.sh"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== Pre-COMMIT Gate Tests ==="

# Setup
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

mkdir -p "$TMPDIR/docs/cycles"
mkdir -p "$TMPDIR/tests"

# T-01: BLOCK when REVIEW not recorded
echo ""
echo "T-01: BLOCK when REVIEW not recorded in Progress Log"

cat > "$TMPDIR/docs/cycles/20260315_1400_active.md" <<'CYCLE'
---
phase: COMMIT
---
# Active cycle

## Progress Log

### 2026-03-15 - RED
- Tests created
- Phase completed

### 2026-03-15 - GREEN
- Implementation done
- Phase completed

### 2026-03-15 - REFACTOR
- Code quality improved
- Phase completed
CYCLE

output=$(bash "$SCRIPT" "$TMPDIR" 2>&1) && rc=$? || rc=$?
if [ "$rc" -eq 1 ] && echo "$output" | grep -qiE "REVIEW|review"; then
  pass "BLOCK on missing REVIEW record"
else
  fail "Expected BLOCK on missing REVIEW, got rc=$rc output: $output"
fi

# T-02: PASS when REVIEW recorded (with Codex review if codex available)
echo ""
echo "T-02: PASS when REVIEW recorded"

cat > "$TMPDIR/docs/cycles/20260315_1400_active.md" <<'CYCLE'
---
phase: COMMIT
---
# Active cycle

## Progress Log

### 2026-03-15 - RED
- Tests created
- Phase completed

### 2026-03-15 - GREEN
- Implementation done
- Phase completed

### 2026-03-15 - REFACTOR
- Code quality improved
- Phase completed

### 2026-03-15 - REVIEW
- Code review passed
- Codex review: Accept 2, Reject 0
- Phase completed
CYCLE

output=$(bash "$SCRIPT" "$TMPDIR" 2>&1) && rc=$? || rc=$?
if [ "$rc" -eq 0 ]; then
  pass "PASS when REVIEW recorded"
else
  fail "Expected PASS, got rc=$rc output: $output"
fi

# T-03: STATUS.md warning on test script count mismatch
echo ""
echo "T-03: STATUS.md test script count mismatch warning"

cat > "$TMPDIR/docs/STATUS.md" <<'STATUS'
# Status

| Metric | Value |
|--------|-------|
| Test Scripts | 99 |
STATUS

# Create a few test scripts
touch "$TMPDIR/tests/test-foo.sh" "$TMPDIR/tests/test-bar.sh"

output=$(bash "$SCRIPT" "$TMPDIR" 2>&1) && rc=$? || rc=$?
# Should warn but NOT block (exit 0)
if [ "$rc" -eq 0 ] && echo "$output" | grep -qiE "warn|STATUS|mismatch"; then
  pass "Warning on STATUS.md test count mismatch"
else
  fail "Expected warning (exit 0) on mismatch, got rc=$rc output: $output"
fi

# T-04: No warning when STATUS.md count matches
echo ""
echo "T-04: No warning when STATUS.md count matches"

actual_count=$(ls "$TMPDIR"/tests/test-*.sh 2>/dev/null | wc -l | tr -d ' ')
cat > "$TMPDIR/docs/STATUS.md" <<STATUS
# Status

| Metric | Value |
|--------|-------|
| Test Scripts | $actual_count |
STATUS

output=$(bash "$SCRIPT" "$TMPDIR" 2>&1) && rc=$? || rc=$?
if [ "$rc" -eq 0 ] && ! echo "$output" | grep -qi "warn"; then
  pass "No warning when count matches"
else
  fail "Expected clean PASS, got rc=$rc output: $output"
fi

# T-06: BLOCK when only old-format Cycle doc exists (no phase: field)
echo ""
echo "T-06: BLOCK when old-format Cycle doc (no phase: field) is only doc"

rm -f "$TMPDIR/docs/cycles/20260315_1400_active.md"
cat > "$TMPDIR/docs/cycles/20260316_0053_old-format.md" <<'CYCLE'
---
title: "Old Format Phase 13"
date: 2026-03-16
status: IN_PROGRESS
---
# Old format cycle
CYCLE

output=$(bash "$SCRIPT" "$TMPDIR" 2>&1) && rc=$? || rc=$?
if [ "$rc" -eq 1 ] && echo "$output" | grep -qi "cycle doc"; then
  pass "BLOCK on old-format Cycle doc (no phase: field)"
else
  fail "Expected BLOCK (exit 1) on old-format doc, got rc=$rc output: $output"
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
