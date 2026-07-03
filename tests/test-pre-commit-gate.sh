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
retro_status: captured
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

# TC-06: BLOCK when Progress Log has old-format REVIEW entry (### REVIEW (date))
echo ""
echo "TC-06: BLOCK when Progress Log uses old-format '### REVIEW (date)' header"

rm -f "$TMPDIR/docs/cycles/20260316_0053_old-format.md"
cat > "$TMPDIR/docs/cycles/20260315_1400_active.md" <<'CYCLE'
---
phase: COMMIT
retro_status: captured
---
# Active cycle

## Progress Log

### 2026-01-01 - RED
- Tests created
- Phase completed

### 2026-01-01 - GREEN
- Implementation done
- Phase completed

### 2026-01-01 - REFACTOR
- Code quality improved
- Phase completed

### REVIEW (2026-01-01)
- Code review passed
- Codex review: Accept 2, Reject 0
- Phase completed
CYCLE

output=$(bash "$SCRIPT" "$TMPDIR" 2>&1) && rc=$? || rc=$?
if [ "$rc" -ne 0 ]; then
  pass "TC-06: BLOCK on old-format '### REVIEW (date)' Progress Log entry (exit $rc)"
else
  fail "TC-06: Expected BLOCK (exit non-0) on old-format REVIEW, got PASS (exit 0): $output"
fi

# TC-07: PASS when Progress Log has correct-format REVIEW entry (### YYYY-MM-DD HH:MM - REVIEW)
echo ""
echo "TC-07: PASS when Progress Log uses correct '### YYYY-MM-DD HH:MM - REVIEW' format"

cat > "$TMPDIR/docs/cycles/20260315_1400_active.md" <<'CYCLE'
---
phase: COMMIT
retro_status: captured
---
# Active cycle

## Progress Log

### 2026-01-01 00:00 - RED
- Tests created
- Phase completed

### 2026-01-01 00:00 - GREEN
- Implementation done
- Phase completed

### 2026-01-01 00:00 - REFACTOR
- Code quality improved
- Phase completed

### 2026-01-01 00:00 - REVIEW
- Code review passed
- Codex review: Accept 2, Reject 0
- Phase completed
CYCLE

output=$(bash "$SCRIPT" "$TMPDIR" 2>&1) && rc=$? || rc=$?
if [ "$rc" -eq 0 ]; then
  pass "TC-07: PASS on correct '### YYYY-MM-DD HH:MM - REVIEW' format"
else
  fail "TC-07: Expected PASS (exit 0), got BLOCK (exit $rc): $output"
fi

########################################
# $1 polymorphic selection contract (TC-08 ~ TC-14)
# Each TC uses an isolated fixture subdirectory under $TMPDIR
########################################

# TC-08: Given multiple non-DONE Cycle docs (old: updated 早い + REVIEW完了 + retro_status
# resolved = 単独なら gate PASS 条件充足, new: updated 遅い + REVIEW未完了),
# When gate をディレクトリモードで実行, Then updated 最新の new doc が選択され
# REVIEW 未完了で BLOCK する（現行実装は glob 先頭の old を選び PASS するため FAIL = RED）
echo ""
echo "TC-08: dir mode selects latest-updated non-DONE doc (new) over old, BLOCKs on missing REVIEW"

FIXTURE_08="$TMPDIR/tc08"
mkdir -p "$FIXTURE_08/docs/cycles"

cat > "$FIXTURE_08/docs/cycles/20260101_0000_old.md" <<'CYCLE'
---
phase: COMMIT
retro_status: resolved
updated: 2026-01-02 10:00
---
# Old cycle

## Progress Log

### 2026-01-01 00:00 - RED
- Tests created
- Phase completed

### 2026-01-01 00:00 - GREEN
- Implementation done
- Phase completed

### 2026-01-01 00:00 - REFACTOR
- Code quality improved
- Phase completed

### 2026-01-01 00:00 - REVIEW
- Code review passed
- Codex review: Accept 2, Reject 0
- Phase completed
CYCLE

cat > "$FIXTURE_08/docs/cycles/20260601_0000_new.md" <<'CYCLE'
---
phase: REVIEW
retro_status: none
updated: 2026-06-02 10:00
---
# New cycle

## Progress Log

### 2026-06-01 00:00 - RED
- Tests created
- Phase completed

### 2026-06-01 00:00 - GREEN
- Implementation done
- Phase completed

### 2026-06-01 00:00 - REFACTOR
- Code quality improved
- Phase completed
CYCLE

output_08=$(bash "$SCRIPT" "$FIXTURE_08" 2>&1) && rc_08=$? || rc_08=$?
if [ "$rc_08" -eq 1 ] && echo "$output_08" | grep -qF "20260601_0000_new"; then
  pass "TC-08: dir mode selects newest-updated doc (new) and BLOCKs (rc=$rc_08)"
else
  fail "TC-08: expected BLOCK (rc=1) selecting new doc, got rc=$rc_08 output: $output_08"
fi

# TC-09: Given 明示指定モード ($1 = 直接 doc パス), When 新 doc パスを指定,
# Then その doc のみ検査され BLOCK。When old doc パスを指定, Then PASS
# （現行実装は $1 をディレクトリ扱いするため両方 BLOCK「No active Cycle doc found」に
# なり old=PASS の期待が崩れるため FAIL = RED）
echo ""
echo "TC-09: explicit \$1 doc path mode inspects only the specified doc"

FIXTURE_09="$TMPDIR/tc09"
mkdir -p "$FIXTURE_09/docs/cycles"

cat > "$FIXTURE_09/docs/cycles/20260101_0000_old.md" <<'CYCLE'
---
phase: COMMIT
retro_status: resolved
updated: 2026-01-02 10:00
---
# Old cycle

## Progress Log

### 2026-01-01 00:00 - RED
- Tests created
- Phase completed

### 2026-01-01 00:00 - GREEN
- Implementation done
- Phase completed

### 2026-01-01 00:00 - REFACTOR
- Code quality improved
- Phase completed

### 2026-01-01 00:00 - REVIEW
- Code review passed
- Codex review: Accept 2, Reject 0
- Phase completed
CYCLE

cat > "$FIXTURE_09/docs/cycles/20260601_0000_new.md" <<'CYCLE'
---
phase: REVIEW
retro_status: none
updated: 2026-06-02 10:00
---
# New cycle

## Progress Log

### 2026-06-01 00:00 - RED
- Tests created
- Phase completed
CYCLE

output_09a=$(bash "$SCRIPT" "$FIXTURE_09/docs/cycles/20260601_0000_new.md" 2>&1) && rc_09a=$? || rc_09a=$?
output_09b=$(bash "$SCRIPT" "$FIXTURE_09/docs/cycles/20260101_0000_old.md" 2>&1) && rc_09b=$? || rc_09b=$?

if [ "$rc_09a" -eq 1 ] && [ "$rc_09b" -eq 0 ]; then
  pass "TC-09: explicit new doc BLOCKs (rc=$rc_09a), explicit old doc PASSes (rc=$rc_09b)"
else
  fail "TC-09: expected new=BLOCK(1)/old=PASS(0), got new rc=$rc_09a output: $output_09a / old rc=$rc_09b output: $output_09b"
fi

# TC-10: Given $1 が実在しないパス, When gate 実行, Then BLOCK (exit 1) し
# メッセージに "invalid" を含む（現行実装も exit 1 だが「No active Cycle doc found」
# であり "invalid" を含まないため FAIL = RED）
echo ""
echo "TC-10: nonexistent \$1 path BLOCKs with invalid argument message"

output_10=$(bash "$SCRIPT" "/nonexistent/path/xyz-tc10-does-not-exist" 2>&1) && rc_10=$? || rc_10=$?
if [ "$rc_10" -eq 1 ] && echo "$output_10" | grep -qi "invalid"; then
  pass "TC-10: BLOCK on nonexistent path with 'invalid' message (rc=$rc_10)"
else
  fail "TC-10: expected BLOCK (rc=1) with 'invalid' message, got rc=$rc_10 output: $output_10"
fi

# TC-11: Given updated 同値の 2 non-DONE doc (a, b; b が filename 昇順 sort の tail),
# When dir mode 実行, Then filename tail の b が選ばれ BLOCK メッセージに b のファイル名
# を含む（現行実装は glob 先頭の a を選ぶため b のファイル名を出力しない = FAIL = RED）
echo ""
echo "TC-11: dir mode tie-break on equal updated selects filename-tail doc (b)"

FIXTURE_11="$TMPDIR/tc11"
mkdir -p "$FIXTURE_11/docs/cycles"

cat > "$FIXTURE_11/docs/cycles/20260101_0000_a.md" <<'CYCLE'
---
phase: REVIEW
retro_status: none
updated: 2026-03-01 09:00
---
# Doc A

## Progress Log

### 2026-03-01 00:00 - RED
- Tests created
- Phase completed
CYCLE

cat > "$FIXTURE_11/docs/cycles/20260601_0000_b.md" <<'CYCLE'
---
phase: REVIEW
retro_status: none
updated: 2026-03-01 09:00
---
# Doc B

## Progress Log

### 2026-03-01 00:00 - RED
- Tests created
- Phase completed
CYCLE

output_11=$(bash "$SCRIPT" "$FIXTURE_11" 2>&1) && rc_11=$? || rc_11=$?
if [ "$rc_11" -eq 1 ] && echo "$output_11" | grep -qF "20260601_0000_b"; then
  pass "TC-11: tie-break selects filename-tail doc (b) on equal updated (rc=$rc_11)"
else
  fail "TC-11: expected BLOCK selecting doc b, got rc=$rc_11 output: $output_11"
fi

# TC-12: Given 明示指定 doc の phase が DONE, When gate 実行, Then BLOCK (exit 1) し
# 対象 doc 名が出力に含まれる（現行実装も rc=1 だが $1 を dir 扱いした
# 「No active Cycle doc found」という無関係な fallback メッセージで doc 名を含まない
# ため FAIL = RED）
echo ""
echo "TC-12: explicit \$1 doc path with phase: DONE BLOCKs"

FIXTURE_12="$TMPDIR/tc12"
mkdir -p "$FIXTURE_12/docs/cycles"

cat > "$FIXTURE_12/docs/cycles/20260101_0000_done.md" <<'CYCLE'
---
phase: DONE
retro_status: resolved
updated: 2026-01-01 10:00
---
# Done cycle

## Progress Log

### 2026-01-01 00:00 - REVIEW
- Code review passed
- Codex review: Accept 2, Reject 0
- Phase completed
CYCLE

output_12=$(bash "$SCRIPT" "$FIXTURE_12/docs/cycles/20260101_0000_done.md" 2>&1) && rc_12=$? || rc_12=$?
if [ "$rc_12" -eq 1 ] && echo "$output_12" | grep -qF "20260101_0000_done"; then
  pass "TC-12: explicit DONE doc BLOCKs and output identifies the doc (rc=$rc_12)"
else
  fail "TC-12: expected BLOCK identifying done doc, got rc=$rc_12 output: $output_12"
fi

# TC-13: Given 明示指定 doc が docs/cycles/ 配下に存在しない偽造 .md（phase: REVIEW +
# REVIEW 記録 + retro_status: resolved 完備、docs/cycles 制約さえ無ければ他チェックは
# 全て PASS 条件を満たす）, When gate 実行, Then BLOCK (exit 1) し出力に "docs/cycles"
# を含む
echo ""
echo "TC-13: explicit \$1 doc path outside docs/cycles/ BLOCKs"

FIXTURE_13="$TMPDIR/tc13"
mkdir -p "$FIXTURE_13"

cat > "$FIXTURE_13/forged.md" <<'CYCLE'
---
phase: REVIEW
retro_status: resolved
updated: 2026-01-01 10:00
---
# Forged cycle (outside docs/cycles/)

## Progress Log

### 2026-01-01 00:00 - REVIEW
- Code review passed
- Codex review: Accept 2, Reject 0
- Phase completed
CYCLE

output_13=$(bash "$SCRIPT" "$FIXTURE_13/forged.md" 2>&1) && rc_13=$? || rc_13=$?
if [ "$rc_13" -eq 1 ] && echo "$output_13" | grep -qF "docs/cycles"; then
  pass "TC-13: explicit doc outside docs/cycles/ BLOCKs (rc=$rc_13)"
else
  fail "TC-13: expected BLOCK mentioning docs/cycles, got rc=$rc_13 output: $output_13"
fi

# TC-14: Given 明示指定 doc の PROJECT_ROOT に STATUS.md 不一致 count が存在,
# When gate 実行, Then STATUS.md test script count mismatch の WARN が出力される
# （明示指定モードの PROJECT_ROOT 導出が正しく fixture root を指すことを確認）
echo ""
echo "TC-14: explicit \$1 doc path resolves PROJECT_ROOT for STATUS.md warning"

FIXTURE_14="$TMPDIR/tc14"
mkdir -p "$FIXTURE_14/docs/cycles" "$FIXTURE_14/tests"

cat > "$FIXTURE_14/docs/STATUS.md" <<'STATUS'
# Status

| Metric | Value |
|--------|-------|
| Test Scripts | 99 |
STATUS

touch "$FIXTURE_14/tests/test-foo.sh"

cat > "$FIXTURE_14/docs/cycles/20260101_0000_active.md" <<'CYCLE'
---
phase: COMMIT
retro_status: resolved
updated: 2026-01-01 10:00
---
# Active cycle

## Progress Log

### 2026-01-01 00:00 - REVIEW
- Code review passed
- Codex review: Accept 2, Reject 0
- Phase completed
CYCLE

output_14=$(bash "$SCRIPT" "$FIXTURE_14/docs/cycles/20260101_0000_active.md" 2>&1) && rc_14=$? || rc_14=$?
if echo "$output_14" | grep -qF "WARN: STATUS.md test script count mismatch"; then
  pass "TC-14: explicit doc path resolves PROJECT_ROOT and emits STATUS.md WARN (rc=$rc_14)"
else
  fail "TC-14: expected STATUS.md count mismatch WARN, got rc=$rc_14 output: $output_14"
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
