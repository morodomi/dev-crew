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

# T-06: BLOCK when only old-format Cycle doc exists (no phase: field)
echo ""
echo "T-06: BLOCK when old-format Cycle doc (no phase: field) is only doc"

# Remove previous active doc, add old-format only
rm -f "$TMPDIR/docs/cycles/20260315_1300_active.md"
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

# T-07: BLOCK when only no-frontmatter Cycle doc exists
echo ""
echo "T-07: BLOCK when no-frontmatter Cycle doc is only doc"

rm -f "$TMPDIR/docs/cycles/20260316_0053_old-format.md"
cat > "$TMPDIR/docs/cycles/20260316_1200_no-fm.md" <<'CYCLE'
# No Frontmatter Doc

This doc has no YAML frontmatter at all.
CYCLE

output=$(bash "$SCRIPT" "$TMPDIR" 2>&1) && rc=$? || rc=$?
if [ "$rc" -eq 1 ] && echo "$output" | grep -qi "cycle doc"; then
  pass "BLOCK on no-frontmatter Cycle doc"
else
  fail "Expected BLOCK (exit 1) on no-frontmatter doc, got rc=$rc output: $output"
fi

########################################
# $1 polymorphic selection contract (T-08 ~ T-09)
# Each TC uses an isolated fixture subdirectory under $TMPDIR
########################################

# T-08: Given multiple non-DONE Cycle docs (old: updated 早い + sync-plan/Plan Review
# 完了 = 単独なら PASS 条件充足, new: updated 遅い + Plan Review 未完了),
# When gate をディレクトリモードで実行, Then updated 最新の new doc が選択され
# Plan Review 未完了で BLOCK する（現行実装は glob 先頭の old を選び PASS するため
# FAIL = RED）
echo ""
echo "T-08: dir mode selects latest-updated non-DONE doc (new) over old"

FIXTURE_T08="$TMPDIR/t08"
mkdir -p "$FIXTURE_T08/docs/cycles"

cat > "$FIXTURE_T08/docs/cycles/20260101_0000_old.md" <<'CYCLE'
---
phase: RED
updated: 2026-01-02 10:00
---
# Old cycle

## Progress Log

### 2026-01-01 00:00 - SYNC-PLAN
- Cycle doc generated
- Phase completed

### 2026-01-01 00:00 - Plan Review
- Design review passed
- Phase completed
CYCLE

cat > "$FIXTURE_T08/docs/cycles/20260601_0000_new.md" <<'CYCLE'
---
phase: SPEC
updated: 2026-06-02 10:00
---
# New cycle

## Progress Log

### 2026-06-01 00:00 - SYNC-PLAN
- Cycle doc generated
- Phase completed
CYCLE

output_t08=$(bash "$SCRIPT" "$FIXTURE_T08" 2>&1) && rc_t08=$? || rc_t08=$?
if [ "$rc_t08" -eq 1 ]; then
  pass "T-08: dir mode selects newest-updated doc (new) and BLOCKs on missing Plan Review (rc=$rc_t08)"
else
  fail "T-08: expected BLOCK (rc=1) selecting new doc, got rc=$rc_t08 output: $output_t08"
fi

# T-09: Given 明示指定モード ($1 = 直接 doc パス), When 新 doc パスを指定,
# Then その doc のみ検査され BLOCK。When old doc パスを指定, Then PASS
# （現行実装は $1 をディレクトリ扱いするため両方 BLOCK になり old=PASS の期待が
# 崩れるため FAIL = RED）
echo ""
echo "T-09: explicit \$1 doc path mode inspects only the specified doc"

FIXTURE_T09="$TMPDIR/t09"
mkdir -p "$FIXTURE_T09/docs/cycles"

cat > "$FIXTURE_T09/docs/cycles/20260101_0000_old.md" <<'CYCLE'
---
phase: RED
updated: 2026-01-02 10:00
---
# Old cycle

## Progress Log

### 2026-01-01 00:00 - SYNC-PLAN
- Cycle doc generated
- Phase completed

### 2026-01-01 00:00 - Plan Review
- Design review passed
- Phase completed
CYCLE

cat > "$FIXTURE_T09/docs/cycles/20260601_0000_new.md" <<'CYCLE'
---
phase: SPEC
updated: 2026-06-02 10:00
---
# New cycle

## Progress Log

### 2026-06-01 00:00 - SYNC-PLAN
- Cycle doc generated
- Phase completed
CYCLE

output_t09a=$(bash "$SCRIPT" "$FIXTURE_T09/docs/cycles/20260601_0000_new.md" 2>&1) && rc_t09a=$? || rc_t09a=$?
output_t09b=$(bash "$SCRIPT" "$FIXTURE_T09/docs/cycles/20260101_0000_old.md" 2>&1) && rc_t09b=$? || rc_t09b=$?

if [ "$rc_t09a" -eq 1 ] && [ "$rc_t09b" -eq 0 ]; then
  pass "T-09: explicit new doc BLOCKs (rc=$rc_t09a), explicit old doc PASSes (rc=$rc_t09b)"
else
  fail "T-09: expected new=BLOCK(1)/old=PASS(0), got new rc=$rc_t09a output: $output_t09a / old rc=$rc_t09b output: $output_t09b"
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
