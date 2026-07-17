#!/bin/bash
# test-pre-red-gate.sh - pre-red-gate.sh deterministic gate tests
# T-01: BLOCK when no Cycle doc exists
# T-02: BLOCK when sync-plan not recorded in Progress Log
# T-03: BLOCK when Plan Review not recorded in Progress Log
# T-04: PASS when all conditions met
# T-05: Script exits with 0 on PASS, 1 on BLOCK
#
# TC-R5(a-e) / TC-R15(f-q) pin the strengthened Plan Review (pre-approval) contract
# (structured extraction: Phase completed / verdict enumerate / codex_session_id /
# reviewed_plan_hash 実照合 / unresolved_blocks / override 証跡 / plan_file trust
# boundary / SIGPIPE-safe large-range handling). The gate now implements all of these
# checks directly (see scripts/gates/pre-red-gate.sh header for the 1:1 check list);
# every sub-case below PASSes against the current implementation.

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

########################################
# TC-R5 / TC-R15: Plan Review (pre-approval) 強化 gate 契約
# (gate は structured extraction・plan_file trust boundary・verdict/unresolved_blocks/
#  override 列挙・SIGPIPE-safe large-range handling を実装済み。全 sub-case が
#  現行 gate に対して PASS する契約)
########################################

# sha256 of a file's content strictly above the "## Plan Review Record" heading
# (mirrors Design Approach #2: "Record 見出し上部全文の sha256")
sha256_above_record() {
  local plan_path="$1"
  sed -n '1,/^## Plan Review Record$/p' "$plan_path" | sed '$d' | shasum -a 256 | awk '{print $1}'
}

# Write a minimal fixture plan file and return its pre-Record sha256
make_fixture_plan() {
  local plan_path="$1"
  cat > "$plan_path" <<'PLAN'
# Fixture Plan

Fixture plan body used for reviewed_plan_hash verification in TC-R5/TC-R15 fixtures.

## Plan Review Record
- verdict: WARN
PLAN
  sha256_above_record "$plan_path"
}

# TC-R5(a): Given Record 完備 fixture, When gate 実行, Then PASS
echo ""
echo "TC-R5(a): complete Plan Review (pre-approval) Record fixture -> PASS"

FIXTURE_R5A="$TMPDIR/tcr5a"
mkdir -p "$FIXTURE_R5A/docs/cycles"
PLAN_R5A="$FIXTURE_R5A/plan.md"
HASH_R5A=$(make_fixture_plan "$PLAN_R5A")

cat > "$FIXTURE_R5A/docs/cycles/20260101_0000_r5a.md" <<CYCLE
---
phase: RED
plan_file: $PLAN_R5A
updated: 2026-01-01 00:10
---
# Fixture cycle R5a

## Progress Log

### 2026-01-01 00:00 - SYNC-PLAN
- Cycle doc generated
- Phase completed

### 2026-01-01 00:05 - Plan Review (pre-approval)
- codex_session_id: session-r5a
- review_attempts:
  - {started: 2026-01-01 00:01, completed: 2026-01-01 00:03, verdict: WARN}
- unresolved_blocks: なし
- reviewed_plan_hash: $HASH_R5A
- verdict: WARN
- Phase completed
CYCLE

# plan_file lives under mktemp, outside the default trusted plan directory
# ($HOME/.claude/plans) — DEV_CREW_PLAN_DIR overrides the trust boundary to this
# fixture's own directory so the trust-boundary check (v) doesn't false-BLOCK it.
output_r5a=$(DEV_CREW_PLAN_DIR="$FIXTURE_R5A" bash "$SCRIPT" "$FIXTURE_R5A/docs/cycles/20260101_0000_r5a.md" 2>&1) && rc_r5a=$? || rc_r5a=$?
if [ "$rc_r5a" -eq 0 ]; then
  pass "TC-R5(a): complete Plan Review Record fixture PASSes"
else
  fail "TC-R5(a): expected PASS (rc=0), got rc=$rc_r5a output: $output_r5a"
fi

# TC-R5(b): Given Record 欠落（構造化見出しなし、casual mention のみ）,
# When gate 実行, Then BLOCK（現行の弱 grep は文字列一致のみで false PASS する）
echo ""
echo "TC-R5(b): missing structured Plan Review (pre-approval) entry (casual mention only) -> BLOCK"

FIXTURE_R5B="$TMPDIR/tcr5b"
mkdir -p "$FIXTURE_R5B/docs/cycles"

cat > "$FIXTURE_R5B/docs/cycles/20260101_0000_r5b.md" <<'CYCLE'
---
phase: RED
updated: 2026-01-01 00:10
---
# Fixture cycle R5b

## Progress Log

### 2026-01-01 00:00 - SYNC-PLAN
- Cycle doc generated
- Phase completed

### 2026-01-01 00:05 - Notes
- plan-review is scheduled for later, no structured record yet
- Phase completed
CYCLE

output_r5b=$(bash "$SCRIPT" "$FIXTURE_R5B/docs/cycles/20260101_0000_r5b.md" 2>&1) && rc_r5b=$? || rc_r5b=$?
if [ "$rc_r5b" -eq 1 ] && echo "$output_r5b" | grep -qiE "Plan Review"; then
  pass "TC-R5(b): missing structured Plan Review (pre-approval) entry BLOCKs"
else
  fail "TC-R5(b): expected BLOCK on missing structured entry, got rc=$rc_r5b output: $output_r5b"
fi

# TC-R5(c): Given verdict: BLOCK かつ override 証跡なし, When gate 実行, Then BLOCK
echo ""
echo "TC-R5(c): verdict: BLOCK without override evidence -> BLOCK"

FIXTURE_R5C="$TMPDIR/tcr5c"
mkdir -p "$FIXTURE_R5C/docs/cycles"
PLAN_R5C="$FIXTURE_R5C/plan.md"
HASH_R5C=$(make_fixture_plan "$PLAN_R5C")

cat > "$FIXTURE_R5C/docs/cycles/20260101_0000_r5c.md" <<CYCLE
---
phase: RED
plan_file: $PLAN_R5C
updated: 2026-01-01 00:10
---
# Fixture cycle R5c

## Progress Log

### 2026-01-01 00:00 - SYNC-PLAN
- Cycle doc generated
- Phase completed

### 2026-01-01 00:05 - Plan Review (pre-approval)
- codex_session_id: session-r5c
- review_attempts:
  - {started: 2026-01-01 00:01, completed: 2026-01-01 00:03, verdict: BLOCK}
- unresolved_blocks: なし
- reviewed_plan_hash: $HASH_R5C
- verdict: BLOCK
- Phase completed
CYCLE

# DEV_CREW_PLAN_DIR override so trust boundary (v) passes and the verdict check
# (viii)/(x) — the intended BLOCK reason here — is actually reached.
output_r5c=$(DEV_CREW_PLAN_DIR="$FIXTURE_R5C" bash "$SCRIPT" "$FIXTURE_R5C/docs/cycles/20260101_0000_r5c.md" 2>&1) && rc_r5c=$? || rc_r5c=$?
if [ "$rc_r5c" -eq 1 ] && echo "$output_r5c" | grep -qiE "verdict|override"; then
  pass "TC-R5(c): verdict: BLOCK without override BLOCKs"
else
  fail "TC-R5(c): expected BLOCK on unoverridden BLOCK verdict, got rc=$rc_r5c output: $output_r5c"
fi

# TC-R5(d): Given placeholder（フィールド名のみで値なし）, When gate 実行, Then BLOCK
echo ""
echo "TC-R5(d): placeholder fields (field names, no values) -> BLOCK"

FIXTURE_R5D="$TMPDIR/tcr5d"
mkdir -p "$FIXTURE_R5D/docs/cycles"

cat > "$FIXTURE_R5D/docs/cycles/20260101_0000_r5d.md" <<'CYCLE'
---
phase: RED
updated: 2026-01-01 00:10
---
# Fixture cycle R5d

## Progress Log

### 2026-01-01 00:00 - SYNC-PLAN
- Cycle doc generated
- Phase completed

### 2026-01-01 00:05 - Plan Review (pre-approval)
- codex_session_id:
- review_attempts:
- unresolved_blocks:
- reviewed_plan_hash:
- verdict:
- Phase completed
CYCLE

output_r5d=$(bash "$SCRIPT" "$FIXTURE_R5D/docs/cycles/20260101_0000_r5d.md" 2>&1) && rc_r5d=$? || rc_r5d=$?
if [ "$rc_r5d" -eq 1 ] && echo "$output_r5d" | grep -qiE "placeholder|empty|missing"; then
  pass "TC-R5(d): placeholder (empty-valued) fields BLOCKs"
else
  fail "TC-R5(d): expected BLOCK on placeholder fields, got rc=$rc_r5d output: $output_r5d"
fi

# TC-R5(e): Given reviewed_plan_hash フィールド欠落, When gate 実行, Then BLOCK
echo ""
echo "TC-R5(e): reviewed_plan_hash field entirely absent -> BLOCK"

FIXTURE_R5E="$TMPDIR/tcr5e"
mkdir -p "$FIXTURE_R5E/docs/cycles"
PLAN_R5E="$FIXTURE_R5E/plan.md"
HASH_R5E=$(make_fixture_plan "$PLAN_R5E")

cat > "$FIXTURE_R5E/docs/cycles/20260101_0000_r5e.md" <<CYCLE
---
phase: RED
plan_file: $PLAN_R5E
updated: 2026-01-01 00:10
---
# Fixture cycle R5e

## Progress Log

### 2026-01-01 00:00 - SYNC-PLAN
- Cycle doc generated
- Phase completed

### 2026-01-01 00:05 - Plan Review (pre-approval)
- codex_session_id: session-r5e
- review_attempts:
  - {started: 2026-01-01 00:01, completed: 2026-01-01 00:03, verdict: WARN}
- unresolved_blocks: なし
- verdict: WARN
- Phase completed
CYCLE

output_r5e=$(bash "$SCRIPT" "$FIXTURE_R5E/docs/cycles/20260101_0000_r5e.md" 2>&1) && rc_r5e=$? || rc_r5e=$?
if [ "$rc_r5e" -eq 1 ] && echo "$output_r5e" | grep -qiE "hash"; then
  pass "TC-R5(e): reviewed_plan_hash field absent BLOCKs"
else
  fail "TC-R5(e): expected BLOCK on missing hash field, got rc=$rc_r5e output: $output_r5e"
fi

# TC-R15(f): Given reviewed_plan_hash が fixture plan の実 hash と不一致, When gate 実行, Then BLOCK
echo ""
echo "TC-R15(f): reviewed_plan_hash mismatch vs actual plan file -> BLOCK"

FIXTURE_R15F="$TMPDIR/tcr15f"
mkdir -p "$FIXTURE_R15F/docs/cycles"
PLAN_R15F="$FIXTURE_R15F/plan.md"
make_fixture_plan "$PLAN_R15F" > /dev/null
WRONG_HASH_R15F="0000000000000000000000000000000000000000000000000000000000000000"
WRONG_HASH_R15F="${WRONG_HASH_R15F:0:64}"

cat > "$FIXTURE_R15F/docs/cycles/20260101_0000_r15f.md" <<CYCLE
---
phase: RED
plan_file: $PLAN_R15F
updated: 2026-01-01 00:10
---
# Fixture cycle R15f

## Progress Log

### 2026-01-01 00:00 - SYNC-PLAN
- Cycle doc generated
- Phase completed

### 2026-01-01 00:05 - Plan Review (pre-approval)
- codex_session_id: session-r15f
- review_attempts:
  - {started: 2026-01-01 00:01, completed: 2026-01-01 00:03, verdict: WARN}
- unresolved_blocks: なし
- reviewed_plan_hash: $WRONG_HASH_R15F
- verdict: WARN
- Phase completed
CYCLE

# DEV_CREW_PLAN_DIR override so trust boundary (v) passes and the hash re-match
# check (vii) — the intended BLOCK reason here — is actually reached.
output_r15f=$(DEV_CREW_PLAN_DIR="$FIXTURE_R15F" bash "$SCRIPT" "$FIXTURE_R15F/docs/cycles/20260101_0000_r15f.md" 2>&1) && rc_r15f=$? || rc_r15f=$?
if [ "$rc_r15f" -eq 1 ] && echo "$output_r15f" | grep -qiE "hash"; then
  pass "TC-R15(f): reviewed_plan_hash mismatch BLOCKs"
else
  fail "TC-R15(f): expected BLOCK on hash mismatch, got rc=$rc_r15f output: $output_r15f"
fi

# TC-R15(g): Given verdict: PASS かつ unresolved_blocks 非空, When gate 実行, Then BLOCK
echo ""
echo "TC-R15(g): verdict: PASS with non-empty unresolved_blocks -> BLOCK"

FIXTURE_R15G="$TMPDIR/tcr15g"
mkdir -p "$FIXTURE_R15G/docs/cycles"
PLAN_R15G="$FIXTURE_R15G/plan.md"
HASH_R15G=$(make_fixture_plan "$PLAN_R15G")

cat > "$FIXTURE_R15G/docs/cycles/20260101_0000_r15g.md" <<CYCLE
---
phase: RED
plan_file: $PLAN_R15G
updated: 2026-01-01 00:10
---
# Fixture cycle R15g

## Progress Log

### 2026-01-01 00:00 - SYNC-PLAN
- Cycle doc generated
- Phase completed

### 2026-01-01 00:05 - Plan Review (pre-approval)
- codex_session_id: session-r15g
- review_attempts:
  - {started: 2026-01-01 00:01, completed: 2026-01-01 00:03, verdict: PASS}
- unresolved_blocks: B1 (未解消の設計判断あり)
- reviewed_plan_hash: $HASH_R15G
- verdict: PASS
- Phase completed
CYCLE

# DEV_CREW_PLAN_DIR override so trust boundary (v) passes and the unresolved_blocks
# consistency check (ix) — the intended BLOCK reason here — is actually reached.
output_r15g=$(DEV_CREW_PLAN_DIR="$FIXTURE_R15G" bash "$SCRIPT" "$FIXTURE_R15G/docs/cycles/20260101_0000_r15g.md" 2>&1) && rc_r15g=$? || rc_r15g=$?
if [ "$rc_r15g" -eq 1 ] && echo "$output_r15g" | grep -qiE "unresolved"; then
  pass "TC-R15(g): PASS verdict with non-empty unresolved_blocks BLOCKs"
else
  fail "TC-R15(g): expected BLOCK on unresolved_blocks with PASS verdict, got rc=$rc_r15g output: $output_r15g"
fi

# TC-R15(h): Given verdict: BLOCK-overridden かつ override 証跡行なし, When gate 実行, Then BLOCK
echo ""
echo "TC-R15(h): verdict: BLOCK-overridden without override evidence line -> BLOCK"

FIXTURE_R15H="$TMPDIR/tcr15h"
mkdir -p "$FIXTURE_R15H/docs/cycles"
PLAN_R15H="$FIXTURE_R15H/plan.md"
HASH_R15H=$(make_fixture_plan "$PLAN_R15H")

cat > "$FIXTURE_R15H/docs/cycles/20260101_0000_r15h.md" <<CYCLE
---
phase: RED
plan_file: $PLAN_R15H
updated: 2026-01-01 00:10
---
# Fixture cycle R15h

## Progress Log

### 2026-01-01 00:00 - SYNC-PLAN
- Cycle doc generated
- Phase completed

### 2026-01-01 00:05 - Plan Review (pre-approval)
- codex_session_id: session-r15h
- review_attempts:
  - {started: 2026-01-01 00:01, completed: 2026-01-01 00:03, verdict: BLOCK-overridden}
- unresolved_blocks: なし
- reviewed_plan_hash: $HASH_R15H
- verdict: BLOCK-overridden
- Phase completed
CYCLE

# DEV_CREW_PLAN_DIR override so trust boundary (v) passes and the override-evidence
# check (x) — the intended BLOCK reason here — is actually reached.
output_r15h=$(DEV_CREW_PLAN_DIR="$FIXTURE_R15H" bash "$SCRIPT" "$FIXTURE_R15H/docs/cycles/20260101_0000_r15h.md" 2>&1) && rc_r15h=$? || rc_r15h=$?
if [ "$rc_r15h" -eq 1 ] && echo "$output_r15h" | grep -qiE "override"; then
  pass "TC-R15(h): BLOCK-overridden without override evidence line BLOCKs"
else
  fail "TC-R15(h): expected BLOCK on missing override evidence, got rc=$rc_r15h output: $output_r15h"
fi

# TC-R15(i): Given codex_session_id 空 + extraction_failed: true (degraded 許容),
# When gate 実行, Then PASS
echo ""
echo "TC-R15(i): codex_session_id empty + extraction_failed: true -> PASS (degraded allowed)"

FIXTURE_R15I="$TMPDIR/tcr15i"
mkdir -p "$FIXTURE_R15I/docs/cycles"
PLAN_R15I="$FIXTURE_R15I/plan.md"
HASH_R15I=$(make_fixture_plan "$PLAN_R15I")

cat > "$FIXTURE_R15I/docs/cycles/20260101_0000_r15i.md" <<CYCLE
---
phase: RED
plan_file: $PLAN_R15I
updated: 2026-01-01 00:10
---
# Fixture cycle R15i

## Progress Log

### 2026-01-01 00:00 - SYNC-PLAN
- Cycle doc generated
- Phase completed

### 2026-01-01 00:05 - Plan Review (pre-approval)
- codex_session_id: ""
- extraction_failed: true
- review_attempts:
  - {started: 2026-01-01 00:01, completed: 2026-01-01 00:03, verdict: WARN}
- unresolved_blocks: なし
- reviewed_plan_hash: $HASH_R15I
- verdict: WARN
- Phase completed
CYCLE

# DEV_CREW_PLAN_DIR override so trust boundary (v) passes — without it this
# fixture would false-BLOCK on the trust boundary instead of reaching the
# degraded-extraction PASS path this sub-case is meant to pin.
output_r15i=$(DEV_CREW_PLAN_DIR="$FIXTURE_R15I" bash "$SCRIPT" "$FIXTURE_R15I/docs/cycles/20260101_0000_r15i.md" 2>&1) && rc_r15i=$? || rc_r15i=$?
if [ "$rc_r15i" -eq 0 ]; then
  pass "TC-R15(i): degraded session extraction (extraction_failed: true) still PASSes"
else
  fail "TC-R15(i): expected PASS (rc=0) for degraded extraction, got rc=$rc_r15i output: $output_r15i"
fi

# TC-R15(j): Given a synthetic cycle doc with a >25KB Progress Log (large-range
# SIGPIPE regression pin) and a well-formed Plan Review (pre-approval) entry,
# When gate を明示指定モードで実行, Then PASS.
# Synthetic rather than the real project cycle doc on purpose: a real-doc dependency
# is a time bomb here — once that doc's own phase flips to DONE (end of its own
# cycle) this sub-case would BLOCK permanently on an unrelated cause (explicit-mode
# rejects DONE docs), and its plan_file frontmatter points at a machine-local path
# outside any fixture's control. The size threshold (not the specific content) is
# what exercises the SIGPIPE-safety property (checks read via direct awk / herestring,
# never `producer | grep -q`), so a self-contained oversized fixture pins the same
# regression without either liability.
echo ""
echo "TC-R15(j): synthetic cycle doc with >25KB Progress Log (SIGPIPE regression pin) -> PASS"

FIXTURE_R15J="$TMPDIR/tcr15j"
mkdir -p "$FIXTURE_R15J/docs/cycles"
PLAN_R15J="$FIXTURE_R15J/plan.md"
HASH_R15J=$(make_fixture_plan "$PLAN_R15J")

PADDING_R15J="$TMPDIR/tcr15j-padding.txt"
i=1
while [ "$i" -le 400 ]; do
  printf -- '- padding line %04d for SIGPIPE large-range regression pin xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\n' "$i"
  i=$((i + 1))
done > "$PADDING_R15J"

{
  printf -- '---\nphase: RED\nplan_file: %s\nupdated: 2026-01-01 00:20\n---\n' "$PLAN_R15J"
  printf -- '# Fixture cycle R15j (synthetic, large Progress Log)\n\n## Progress Log\n\n### 2026-01-01 00:00 - Padding\n'
  cat "$PADDING_R15J"
  printf -- '\n### 2026-01-01 00:10 - SYNC-PLAN\n- Cycle doc generated\n- Phase completed\n\n'
  printf -- '### 2026-01-01 00:15 - Plan Review (pre-approval)\n'
  printf -- '- codex_session_id: session-r15j\n'
  printf -- '- review_attempts:\n  - {started: 2026-01-01 00:11, completed: 2026-01-01 00:13, verdict: WARN}\n'
  printf -- '- unresolved_blocks: なし\n'
  printf -- '- reviewed_plan_hash: %s\n' "$HASH_R15J"
  printf -- '- verdict: WARN\n- Phase completed\n'
} > "$FIXTURE_R15J/docs/cycles/20260101_0000_r15j.md"
rm -f "$PADDING_R15J"

doc_bytes_r15j=$(wc -c < "$FIXTURE_R15J/docs/cycles/20260101_0000_r15j.md")
if [ "$doc_bytes_r15j" -le 25600 ]; then
  fail "TC-R15(j): fixture setup error — synthetic doc is only ${doc_bytes_r15j} bytes (need >25KB to exercise the SIGPIPE-safety property)"
else
  output_r15j=$(DEV_CREW_PLAN_DIR="$FIXTURE_R15J" bash "$SCRIPT" "$FIXTURE_R15J/docs/cycles/20260101_0000_r15j.md" 2>&1) && rc_r15j=$? || rc_r15j=$?
  if [ "$rc_r15j" -eq 0 ]; then
    pass "TC-R15(j): synthetic large cycle doc (${doc_bytes_r15j} bytes) PASSes without SIGPIPE false-BLOCK"
  else
    fail "TC-R15(j): expected PASS (rc=0), got rc=$rc_r15j output: $output_r15j (SIGPIPE false-BLOCK regression)"
  fi
fi

########################################
# TC-R15(k-q): code review accept-apply — negative fixtures for 5 bypasses the
# review oracle-verified against the strengthened gate, plus 2 boundary pins.
########################################

# TC-R15(k): Given plan_file resolves outside the trusted plan directory
# (DEV_CREW_PLAN_DIR points elsewhere than plan_file's actual directory — the
# fixture-local equivalent of "plan_file under /tmp directly"), When gate 実行,
# Then BLOCK before the file is ever opened/hashed (no hash output in the message).
echo ""
echo "TC-R15(k): plan_file outside trusted plan directory -> BLOCK (no hash computed)"

FIXTURE_R15K="$TMPDIR/tcr15k"
mkdir -p "$FIXTURE_R15K/docs/cycles" "$FIXTURE_R15K/untrusted_plans" "$FIXTURE_R15K/trusted_plans"
PLAN_R15K="$FIXTURE_R15K/untrusted_plans/plan.md"
HASH_R15K=$(make_fixture_plan "$PLAN_R15K")

cat > "$FIXTURE_R15K/docs/cycles/20260101_0000_r15k.md" <<CYCLE
---
phase: RED
plan_file: $PLAN_R15K
updated: 2026-01-01 00:10
---
# Fixture cycle R15k

## Progress Log

### 2026-01-01 00:00 - SYNC-PLAN
- Cycle doc generated
- Phase completed

### 2026-01-01 00:05 - Plan Review (pre-approval)
- codex_session_id: session-r15k
- review_attempts:
  - {started: 2026-01-01 00:01, completed: 2026-01-01 00:03, verdict: WARN}
- unresolved_blocks: なし
- reviewed_plan_hash: $HASH_R15K
- verdict: WARN
- Phase completed
CYCLE

output_r15k=$(DEV_CREW_PLAN_DIR="$FIXTURE_R15K/trusted_plans" bash "$SCRIPT" "$FIXTURE_R15K/docs/cycles/20260101_0000_r15k.md" 2>&1) && rc_r15k=$? || rc_r15k=$?
if [ "$rc_r15k" -eq 1 ] && echo "$output_r15k" | grep -qiE "trusted plan directory" && ! echo "$output_r15k" | grep -qiE "computed=|mismatch"; then
  pass "TC-R15(k): out-of-boundary plan_file BLOCKs before hash computation"
else
  fail "TC-R15(k): expected BLOCK naming the trust boundary with no hash output, got rc=$rc_r15k output: $output_r15k"
fi

# TC-R15(l): Given a heading containing "(pre-approval)" but with a trailing
# suffix after it (e.g. "— attempt 2"), so it does NOT exactly equal
# "### <ts> - Plan Review (pre-approval)", When gate 実行, Then BLOCK — the
# discriminator still requires strict mode (the substring match sees
# "(pre-approval)"), but the exact-heading search fails, so this must BLOCK
# rather than silently falling back to the legacy weak check.
echo ""
echo "TC-R15(l): '(pre-approval)' heading with trailing suffix -> BLOCK (no legacy fallback)"

FIXTURE_R15L="$TMPDIR/tcr15l"
mkdir -p "$FIXTURE_R15L/docs/cycles"

cat > "$FIXTURE_R15L/docs/cycles/20260101_0000_r15l.md" <<'CYCLE'
---
phase: RED
updated: 2026-01-01 00:10
---
# Fixture cycle R15l

## Progress Log

### 2026-01-01 00:00 - SYNC-PLAN
- Cycle doc generated
- Phase completed

### 2026-01-01 00:05 - Plan Review (pre-approval) — attempt 2
- codex_session_id: session-r15l
- review_attempts:
  - {started: 2026-01-01 00:01, completed: 2026-01-01 00:03, verdict: WARN}
- unresolved_blocks: なし
- reviewed_plan_hash: 0000000000000000000000000000000000000000000000000000000000000000
- verdict: WARN
- Phase completed
CYCLE

output_r15l=$(bash "$SCRIPT" "$FIXTURE_R15L/docs/cycles/20260101_0000_r15l.md" 2>&1) && rc_r15l=$? || rc_r15l=$?
if [ "$rc_r15l" -eq 1 ] && echo "$output_r15l" | grep -qiE "no exact|not permitted"; then
  pass "TC-R15(l): suffixed '(pre-approval)' heading BLOCKs strict, does not fall back to legacy"
else
  fail "TC-R15(l): expected BLOCK naming the missing exact heading / no-fallback, got rc=$rc_r15l output: $output_r15l"
fi

# TC-R15(m): Given verdict: PASSING (near-miss of PASS), When gate 実行, Then BLOCK
# — the enumerate pattern requires an exact token followed by a
# space/paren-delimited annotation or end-of-line, so a prefix-glob-style match
# would wrongly accept this.
echo ""
echo "TC-R15(m): verdict: PASSING (near-miss token) -> BLOCK"

FIXTURE_R15M="$TMPDIR/tcr15m"
mkdir -p "$FIXTURE_R15M/docs/cycles"
PLAN_R15M="$FIXTURE_R15M/plan.md"
HASH_R15M=$(make_fixture_plan "$PLAN_R15M")

cat > "$FIXTURE_R15M/docs/cycles/20260101_0000_r15m.md" <<CYCLE
---
phase: RED
plan_file: $PLAN_R15M
updated: 2026-01-01 00:10
---
# Fixture cycle R15m

## Progress Log

### 2026-01-01 00:00 - SYNC-PLAN
- Cycle doc generated
- Phase completed

### 2026-01-01 00:05 - Plan Review (pre-approval)
- codex_session_id: session-r15m
- review_attempts:
  - {started: 2026-01-01 00:01, completed: 2026-01-01 00:03, verdict: PASSING}
- unresolved_blocks: なし
- reviewed_plan_hash: $HASH_R15M
- verdict: PASSING
- Phase completed
CYCLE

output_r15m=$(DEV_CREW_PLAN_DIR="$FIXTURE_R15M" bash "$SCRIPT" "$FIXTURE_R15M/docs/cycles/20260101_0000_r15m.md" 2>&1) && rc_r15m=$? || rc_r15m=$?
if [ "$rc_r15m" -eq 1 ] && echo "$output_r15m" | grep -qiE "verdict"; then
  pass "TC-R15(m): near-miss verdict 'PASSING' BLOCKs"
else
  fail "TC-R15(m): expected BLOCK on verdict: PASSING, got rc=$rc_r15m output: $output_r15m"
fi

# TC-R15(n): Given verdict: WARN かつ unresolved_blocks: B1（"なし"ではない値）,
# When gate 実行, Then BLOCK.
echo ""
echo "TC-R15(n): unresolved_blocks: B1 (not なし) with verdict: WARN -> BLOCK"

FIXTURE_R15N="$TMPDIR/tcr15n"
mkdir -p "$FIXTURE_R15N/docs/cycles"
PLAN_R15N="$FIXTURE_R15N/plan.md"
HASH_R15N=$(make_fixture_plan "$PLAN_R15N")

cat > "$FIXTURE_R15N/docs/cycles/20260101_0000_r15n.md" <<CYCLE
---
phase: RED
plan_file: $PLAN_R15N
updated: 2026-01-01 00:10
---
# Fixture cycle R15n

## Progress Log

### 2026-01-01 00:00 - SYNC-PLAN
- Cycle doc generated
- Phase completed

### 2026-01-01 00:05 - Plan Review (pre-approval)
- codex_session_id: session-r15n
- review_attempts:
  - {started: 2026-01-01 00:01, completed: 2026-01-01 00:03, verdict: WARN}
- unresolved_blocks: B1
- reviewed_plan_hash: $HASH_R15N
- verdict: WARN
- Phase completed
CYCLE

output_r15n=$(DEV_CREW_PLAN_DIR="$FIXTURE_R15N" bash "$SCRIPT" "$FIXTURE_R15N/docs/cycles/20260101_0000_r15n.md" 2>&1) && rc_r15n=$? || rc_r15n=$?
if [ "$rc_r15n" -eq 1 ] && echo "$output_r15n" | grep -qiE "unresolved"; then
  pass "TC-R15(n): bare non-empty unresolved_blocks (B1) with verdict: WARN BLOCKs"
else
  fail "TC-R15(n): expected BLOCK on unresolved_blocks: B1, got rc=$rc_r15n output: $output_r15n"
fi

# TC-R15(o): Given verdict: BLOCK-overridden かつ "- override: "行はあるが値が空,
# When gate 実行, Then BLOCK — an override line must carry a non-empty reason,
# not merely exist.
echo ""
echo "TC-R15(o): BLOCK-overridden with an empty-valued '- override: ' line -> BLOCK"

FIXTURE_R15O="$TMPDIR/tcr15o"
mkdir -p "$FIXTURE_R15O/docs/cycles"
PLAN_R15O="$FIXTURE_R15O/plan.md"
HASH_R15O=$(make_fixture_plan "$PLAN_R15O")

cat > "$FIXTURE_R15O/docs/cycles/20260101_0000_r15o.md" <<CYCLE
---
phase: RED
plan_file: $PLAN_R15O
updated: 2026-01-01 00:10
---
# Fixture cycle R15o

## Progress Log

### 2026-01-01 00:00 - SYNC-PLAN
- Cycle doc generated
- Phase completed

### 2026-01-01 00:05 - Plan Review (pre-approval)
- codex_session_id: session-r15o
- review_attempts:
  - {started: 2026-01-01 00:01, completed: 2026-01-01 00:03, verdict: BLOCK-overridden}
- unresolved_blocks: なし
- reviewed_plan_hash: $HASH_R15O
- verdict: BLOCK-overridden
- override:
- Phase completed
CYCLE

output_r15o=$(DEV_CREW_PLAN_DIR="$FIXTURE_R15O" bash "$SCRIPT" "$FIXTURE_R15O/docs/cycles/20260101_0000_r15o.md" 2>&1) && rc_r15o=$? || rc_r15o=$?
if [ "$rc_r15o" -eq 1 ] && echo "$output_r15o" | grep -qiE "override"; then
  pass "TC-R15(o): empty-valued '- override: ' line still BLOCKs"
else
  fail "TC-R15(o): expected BLOCK on empty override value, got rc=$rc_r15o output: $output_r15o"
fi

# TC-R15(p): Given the Plan Review (pre-approval) entry itself has NO "Phase
# completed" line, but a LATER unrelated entry does, When gate 実行, Then BLOCK
# — the section-extraction boundary (stop at the next "### " heading) must not
# let a later entry's "Phase completed" satisfy an earlier, incomplete entry.
echo ""
echo "TC-R15(p): Phase completed missing from this entry but present in a later entry -> BLOCK"

FIXTURE_R15P="$TMPDIR/tcr15p"
mkdir -p "$FIXTURE_R15P/docs/cycles"

cat > "$FIXTURE_R15P/docs/cycles/20260101_0000_r15p.md" <<'CYCLE'
---
phase: RED
updated: 2026-01-01 00:10
---
# Fixture cycle R15p

## Progress Log

### 2026-01-01 00:00 - SYNC-PLAN
- Cycle doc generated
- Phase completed

### 2026-01-01 00:05 - Plan Review (pre-approval)
- codex_session_id: session-r15p
- review_attempts:
  - {started: 2026-01-01 00:01, completed: 2026-01-01 00:03, verdict: WARN}
- unresolved_blocks: なし
- reviewed_plan_hash: 0000000000000000000000000000000000000000000000000000000000000000
- verdict: WARN

### 2026-01-01 00:20 - Later Entry
- Some unrelated later action
- Phase completed
CYCLE

output_r15p=$(bash "$SCRIPT" "$FIXTURE_R15P/docs/cycles/20260101_0000_r15p.md" 2>&1) && rc_r15p=$? || rc_r15p=$?
if [ "$rc_r15p" -eq 1 ] && echo "$output_r15p" | grep -qiE "Phase completed"; then
  pass "TC-R15(p): entry-boundary extraction does not borrow a later entry's Phase completed"
else
  fail "TC-R15(p): expected BLOCK on missing Phase completed (no cross-entry borrowing), got rc=$rc_r15p output: $output_r15p"
fi

# TC-R15(q): Given plan_file exists and resides under the trusted plan directory
# but contains no "## Plan Review Record" heading at all, When gate 実行, Then
# BLOCK before hash re-computation.
echo ""
echo "TC-R15(q): plan_file with no '## Plan Review Record' heading -> BLOCK"

FIXTURE_R15Q="$TMPDIR/tcr15q"
mkdir -p "$FIXTURE_R15Q/docs/cycles"
PLAN_R15Q="$FIXTURE_R15Q/plan.md"
cat > "$PLAN_R15Q" <<'PLAN'
# Fixture Plan (no Record heading)

This plan intentionally has no "## Plan Review Record" heading anywhere in it.
PLAN

cat > "$FIXTURE_R15Q/docs/cycles/20260101_0000_r15q.md" <<CYCLE
---
phase: RED
plan_file: $PLAN_R15Q
updated: 2026-01-01 00:10
---
# Fixture cycle R15q

## Progress Log

### 2026-01-01 00:00 - SYNC-PLAN
- Cycle doc generated
- Phase completed

### 2026-01-01 00:05 - Plan Review (pre-approval)
- codex_session_id: session-r15q
- review_attempts:
  - {started: 2026-01-01 00:01, completed: 2026-01-01 00:03, verdict: WARN}
- unresolved_blocks: なし
- reviewed_plan_hash: 0000000000000000000000000000000000000000000000000000000000000000
- verdict: WARN
- Phase completed
CYCLE

output_r15q=$(DEV_CREW_PLAN_DIR="$FIXTURE_R15Q" bash "$SCRIPT" "$FIXTURE_R15Q/docs/cycles/20260101_0000_r15q.md" 2>&1) && rc_r15q=$? || rc_r15q=$?
if [ "$rc_r15q" -eq 1 ] && echo "$output_r15q" | grep -qiE "Plan Review Record"; then
  pass "TC-R15(q): plan_file missing '## Plan Review Record' heading BLOCKs"
else
  fail "TC-R15(q): expected BLOCK naming the missing Record heading, got rc=$rc_r15q output: $output_r15q"
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
