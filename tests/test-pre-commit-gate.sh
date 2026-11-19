#!/bin/bash
# test-pre-commit-gate.sh - pre-commit-gate.sh deterministic gate tests
# T-01: BLOCK when REVIEW not recorded in Progress Log
# T-02: PASS when REVIEW recorded (no codex)

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
- Codex review: 直す 2 / 人間に戻す 0 / 記録のみ 0
- Phase completed

### 2026-03-15 10:00 - PRE-RED GATE
- pre-red-gate: PASS
CYCLE

output=$(bash "$SCRIPT" "$TMPDIR" 2>&1) && rc=$? || rc=$?
if [ "$rc" -eq 0 ]; then
  pass "PASS when REVIEW recorded"
else
  fail "Expected PASS, got rc=$rc output: $output"
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
- Codex review: 直す 2 / 人間に戻す 0 / 記録のみ 0
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
- Codex review: 直す 2 / 人間に戻す 0 / 記録のみ 0
- Phase completed

### 2026-01-01 00:00 - PRE-RED GATE
- pre-red-gate: PASS
CYCLE

output=$(bash "$SCRIPT" "$TMPDIR" 2>&1) && rc=$? || rc=$?
if [ "$rc" -eq 0 ]; then
  pass "TC-07: PASS on correct '### YYYY-MM-DD HH:MM - REVIEW' format"
else
  fail "TC-07: Expected PASS (exit 0), got BLOCK (exit $rc): $output"
fi

########################################
# $1 polymorphic selection contract (TC-08 ~ TC-13)
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
- Codex review: 直す 2 / 人間に戻す 0 / 記録のみ 0
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
- Codex review: 直す 2 / 人間に戻す 0 / 記録のみ 0
- Phase completed

### 2026-01-01 00:00 - PRE-RED GATE
- pre-red-gate: PASS
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
- Codex review: 直す 2 / 人間に戻す 0 / 記録のみ 0
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
- Codex review: 直す 2 / 人間に戻す 0 / 記録のみ 0
- Phase completed
CYCLE

output_13=$(bash "$SCRIPT" "$FIXTURE_13/forged.md" 2>&1) && rc_13=$? || rc_13=$?
if [ "$rc_13" -eq 1 ] && echo "$output_13" | grep -qF "docs/cycles"; then
  pass "TC-13: explicit doc outside docs/cycles/ BLOCKs (rc=$rc_13)"
else
  fail "TC-13: expected BLOCK mentioning docs/cycles, got rc=$rc_13 output: $output_13"
fi

# ---------------------------------------------------------------------------
# pre-red-gate の記録検査 (4 番目の検査) TC-R1 .. TC-R13
# ---------------------------------------------------------------------------
echo ""
echo "=== pre-red-gate record check (TC-R1..R13) ==="

R_ROOT="$TMPDIR/r"
mkdir -p "$R_ROOT"
R_SEQ=0
DOC=""

# mk_doc PRE RED_EXTRA POST REVIEW(yes|no)
#   PRE: `## Progress Log` より前に置く本文 / RED_EXTRA: RED 節の末尾に足す行 /
#   POST: REVIEW 節の後ろに足す本文。DOC に作った Cycle doc のパスを入れる。
mk_doc() {
  local pre="$1" red_extra="$2" post="$3" review="$4"
  R_SEQ=$((R_SEQ + 1))
  local d="$R_ROOT/f$R_SEQ"
  mkdir -p "$d/docs/cycles"
  DOC="$d/docs/cycles/20260315_1400_fixture.md"
  {
    printf -- '---\nphase: COMMIT\nretro_status: captured\n---\n# fixture\n\n'
    printf '%s' "$pre"
    printf -- '## Progress Log\n\n### 2026-03-15 09:00 - RED\n- Tests created\n'
    printf '%s' "$red_extra"
    printf -- '- Phase completed\n\n### 2026-03-15 09:10 - GREEN\n- Phase completed\n\n'
    if [ "$review" = "yes" ]; then
      printf -- '### 2026-03-15 09:20 - REVIEW\n- Code review passed\n- Codex review: 直す 0 / 人間に戻す 0 / 記録のみ 0\n- Phase completed\n\n'
    fi
    printf '%s' "$post"
  } > "$DOC"
}

# run_g DOC: gate を流し G_OUT / G_RC に入れる
run_g() {
  G_OUT=$(bash "$SCRIPT" "$1" 2>&1) && G_RC=0 || G_RC=$?
}

# expect_rc NAME DOC WANT
expect_rc() {
  run_g "$2"
  if [ "$G_RC" -eq "$3" ]; then
    pass "$1 (rc=$G_RC)"
  else
    fail "$1: expected rc=$3, got rc=$G_RC output: $G_OUT"
  fi
}

TABC=$'\t'
E_PASS=$'### 2026-03-15 10:00 - PRE-RED GATE\n- pre-red-gate: PASS\n'

echo ""
echo "TC-R1: BLOCK with run command when no PRE-RED GATE entry"
mk_doc "" "" "" yes
run_g "$DOC"
if [ "$G_RC" -eq 1 ] && grep -qF "pre-red-gate result not recorded" <<<"$G_OUT" \
  && grep -qF "pre-red-gate.sh" <<<"$G_OUT"; then
  pass "TC-R1: BLOCK names missing record and pre-red-gate.sh"
else
  fail "TC-R1: expected rc=1 + message + pre-red-gate.sh, got rc=$G_RC output: $G_OUT"
fi

echo ""
echo "TC-R2: PASS entry"
mk_doc "" "" "$E_PASS" yes
expect_rc "TC-R2: PRE-RED GATE + PASS" "$DOC" 0

echo ""
echo "TC-R3: PASS with annotation"
mk_doc "" "" $'### 2026-03-15 10:00 - PRE-RED GATE\n- pre-red-gate: PASS（rc=0）\n' yes
expect_rc "TC-R3: PASS（rc=0）" "$DOC" 0

echo ""
echo "TC-R4: last entry BLOCK (earlier PASS)"
mk_doc "" "" "$E_PASS"$'\n### 2026-03-15 10:05 - PRE-RED GATE\n- pre-red-gate: BLOCK（BLOCK: sync-plan not completed. Run sync-plan before RED.）\n' yes
expect_rc "TC-R4: last entry is BLOCK" "$DOC" 1

echo ""
echo "TC-R5: PASS entry after BLOCK entry"
mk_doc "" "" $'### 2026-03-15 10:00 - PRE-RED GATE\n- pre-red-gate: BLOCK（BLOCK: sync-plan not completed. Run sync-plan before RED.）\n\n### 2026-03-15 10:05 - PRE-RED GATE\n- pre-red-gate: PASS\n' yes
expect_rc "TC-R5: BLOCK then PASS" "$DOC" 0

echo ""
echo "TC-R6: PASS outside a PRE-RED GATE entry"
mk_doc "" $'- pre-red-gate: PASS\n' "" yes
expect_rc "TC-R6a: PASS as a note inside the RED entry" "$DOC" 1
mk_doc "" $'- sync-plan 済み。pre-red-gate PASS。\n' "" yes
expect_rc "TC-R6b-prose: 'pre-red-gate PASS。' in a sentence" "$DOC" 1

echo ""
echo "TC-R6b: heading and PASS only outside Progress Log (Implementation Notes)"
mk_doc $'## Implementation Notes\n\n### 2026-03-15 10:00 - PRE-RED GATE\n- pre-red-gate: PASS\n\n' "" "" yes
expect_rc "TC-R6b: record in Implementation Notes only" "$DOC" 1

echo ""
echo "TC-R7: heading and PASS only inside a code block"
mk_doc "" "" $'```\n### 2026-03-15 10:00 - PRE-RED GATE\n- pre-red-gate: PASS\n```\n' yes
expect_rc "TC-R7: record only in a fenced block" "$DOC" 1

echo ""
echo "TC-R7b: real entry BLOCK + PASS in a code example"
mk_doc "" "" $'### 2026-03-15 10:00 - PRE-RED GATE\n- pre-red-gate: BLOCK（BLOCK: sync-plan not completed. Run sync-plan before RED.）\n```\n- pre-red-gate: PASS\n```\n' yes
expect_rc "TC-R7b: PASS only inside fence in entry body" "$DOC" 1

echo ""
echo "TC-R8: near-miss values"
mk_doc "" "" $'### 2026-03-15 10:00 - PRE-RED GATE\n- pre-red-gate: PASSING\n' yes
expect_rc "TC-R8a: PASSING" "$DOC" 1
mk_doc "" "" $'### 2026-03-15 10:00 - PRE-RED GATEKEEPER\n- pre-red-gate: PASS\n' yes
expect_rc "TC-R8-heading: PRE-RED GATEKEEPER heading" "$DOC" 1

echo ""
echo "TC-R8b: OVERRIDE"
mk_doc "" "" $'### 2026-03-15 10:00 - PRE-RED GATE\n- pre-red-gate: OVERRIDE（人間が承認: plan ファイルが上書きされ hash を照合できない）\n' yes
expect_rc "TC-R8b: OVERRIDE with reason" "$DOC" 0
mk_doc "" "" $'### 2026-03-15 10:00 - PRE-RED GATE\n- pre-red-gate: OVERRIDE（）\n' yes
expect_rc "TC-R8b: OVERRIDE（） empty" "$DOC" 1
mk_doc "" "" $'### 2026-03-15 10:00 - PRE-RED GATE\n- pre-red-gate: OVERRIDE（ ）\n' yes
expect_rc "TC-R8b: OVERRIDE（space）" "$DOC" 1
mk_doc "" "" "### 2026-03-15 10:00 - PRE-RED GATE"$'\n'"- pre-red-gate: OVERRIDE（${TABC}）"$'\n' yes
expect_rc "TC-R8b: OVERRIDE（tab）" "$DOC" 1
mk_doc "" "" $'### 2026-03-15 10:00 - PRE-RED GATE\n- pre-red-gate: OVERRIDE\n' yes
expect_rc "TC-R8b: bare OVERRIDE" "$DOC" 1

echo ""
echo "TC-R9: existing REVIEW BLOCK wins over missing record"
mk_doc "" "" "" no
run_g "$DOC"
if [ "$G_RC" -eq 1 ] && grep -qF "REVIEW not completed" <<<"$G_OUT" \
  && ! grep -qF "pre-red-gate result not recorded" <<<"$G_OUT"; then
  pass "TC-R9: REVIEW BLOCK message only"
else
  fail "TC-R9: expected rc=1 with REVIEW message only, got rc=$G_RC output: $G_OUT"
fi

# section_of FILE HEADING_PREFIX LEVEL_MARK(### or ####): fence-aware section body
section_of() {
  awk -v p="$2" -v m="$3" '
    /^```/ { fence = !fence }
    !fence && index($0, m " ") == 1 {
      if (on) on = 0
      if (index($0, p) == 1) { on = 1; next }
    }
    !fence && on && /^## / { on = 0 }
    on { print }
  ' "$1"
}

echo ""
echo "TC-R10: orchestrate SKILL.md Block 2a calls pre-red-gate before red-worker"
SKILL_MD="$BASE_DIR/skills/orchestrate/SKILL.md"
B2A=$(section_of "$SKILL_MD" "#### Block 2a" "####")
call_ln=$(grep -nF 'bash "<orchestrate の Base directory>/../../scripts/gates/pre-red-gate.sh"' <<<"$B2A" | head -1 | cut -d: -f1 || true)
task_ln=$(grep -nF 'Task(red-worker' <<<"$B2A" | head -1 | cut -d: -f1 || true)
skill_lines=$(wc -l < "$SKILL_MD" | tr -d ' ')
r10_ok=1
[ -n "$call_ln" ] || r10_ok=0
[ -n "$task_ln" ] || r10_ok=0
if [ "$r10_ok" -eq 1 ] && [ "$call_ln" -ge "$task_ln" ]; then r10_ok=0; fi
grep -qF 'PRE-RED GATE' <<<"$B2A" || r10_ok=0
grep -qF -- '- pre-red-gate: PASS' <<<"$B2A" || r10_ok=0
[ "$skill_lines" -le 99 ] || r10_ok=0
if [ "$r10_ok" -eq 1 ]; then
  pass "TC-R10: Block 2a call precedes Task(red-worker), SKILL.md ${skill_lines} lines"
else
  fail "TC-R10: Block 2a contract not met (call_ln=${call_ln:-none} task_ln=${task_ln:-none} lines=$skill_lines)"
fi

# entry_block FILE [SECTION_PREFIX]: PRE-RED GATE を含むコードブロックがちょうど 1 つなら、その中身を出す
entry_block() {
  awk -v p="${2:-}" '
    function flush() { if (blk ~ /PRE-RED GATE/) { n++; out = blk } blk = "" }
    BEGIN { insec = (p == "") }
    /^```/ {
      if (inb) { inb = 0; if (insec) flush(); next }
      else { inb = 1; blk = ""; next }
    }
    !inb && /^### / { if (p != "") insec = (index($0, p) == 1) }
    inb && insec { blk = blk $0 "\n" }
    END { if (n == 1) printf "%s", out }
  ' "$1"
}

echo ""
echo "TC-R11: documented entry blocks pass the gate"
for f in skills/orchestrate/steps-subagent.md skills/orchestrate/steps-teams.md skills/spec/templates/cycle.md; do
  if [ "$f" = "skills/spec/templates/cycle.md" ]; then
    blk=$(entry_block "$BASE_DIR/$f")
    sec_text=""
  else
    blk=$(entry_block "$BASE_DIR/$f" "### Pre-RED Gate")
    sec_text=$(section_of "$BASE_DIR/$f" "### Pre-RED Gate" "###")
  fi
  if [ -z "$blk" ]; then
    fail "TC-R11: $f: could not extract exactly one PRE-RED GATE block"
    continue
  fi
  lines=$(printf '%s\n' "$blk" | grep -c . || true)
  filled=$(sed 's/YYYY-MM-DD HH:MM/2026-03-15 10:00/' <<<"$blk")
  mk_doc "" "" "$filled"$'\n' yes
  run_g "$DOC"
  extra_ok=1
  if [ "$f" != "skills/spec/templates/cycle.md" ]; then
    grep -qF 'OVERRIDE' <<<"$sec_text" || extra_ok=0
    grep -qF 'AskUserQuestion' <<<"$sec_text" || extra_ok=0
  fi
  if [ "$G_RC" -eq 0 ] && [ "$lines" -eq 2 ] && [ "$extra_ok" -eq 1 ]; then
    pass "TC-R11: $f block passes gate"
  else
    fail "TC-R11: $f: rc=$G_RC lines=$lines extra_ok=$extra_ok output: $G_OUT"
  fi
done

echo ""
echo "TC-R12: commit SKILL.md check agrees with the gate"
COMMIT_MD="$BASE_DIR/skills/commit/SKILL.md"
R12_CODE=$(awk '/^```/ { if (on) exit } on { print } $0 == "# 4. pre-red-gate の記録チェック" { on = 1 }' "$COMMIT_MD")
if [ -z "$R12_CODE" ]; then
  fail "TC-R12: could not extract the pre-red-gate check from commit SKILL.md"
else
  r12_bad=""
  r12_n=0
  r12_run() {
    # r12_run LABEL DOC
    run_g "$2"
    local gate_rc="$G_RC" c_rc
    CYCLE_DOC="$2" bash -c "$R12_CODE" >/dev/null 2>&1 && c_rc=0 || c_rc=$?
    r12_n=$((r12_n + 1))
    if { [ "$gate_rc" -eq 0 ] && [ "$c_rc" -ne 0 ]; } || { [ "$gate_rc" -ne 0 ] && [ "$c_rc" -eq 0 ]; }; then
      r12_bad="$r12_bad [$1: gate rc=$gate_rc commit rc=$c_rc]"
    fi
  }
  mk_doc "" "" "" yes;                                                         r12_run R1 "$DOC"
  mk_doc "" "" "$E_PASS" yes;                                                  r12_run R2 "$DOC"
  mk_doc "" "" $'### 2026-03-15 10:00 - PRE-RED GATE\n- pre-red-gate: BLOCK（x）\n' yes; r12_run R4 "$DOC"
  mk_doc $'## Implementation Notes\n\n### 2026-03-15 10:00 - PRE-RED GATE\n- pre-red-gate: PASS\n\n' "" "" yes; r12_run R6b "$DOC"
  mk_doc "" "" $'### 2026-03-15 10:00 - PRE-RED GATE\n- pre-red-gate: BLOCK（x）\n```\n- pre-red-gate: PASS\n```\n' yes; r12_run R7b "$DOC"
  mk_doc "" "" $'### 2026-03-15 10:00 - PRE-RED GATE\n- pre-red-gate: PASSING\n' yes; r12_run R8-PASSING "$DOC"
  mk_doc "" "" $'### 2026-03-15 10:00 - PRE-RED GATEKEEPER\n- pre-red-gate: PASS\n' yes; r12_run R8-GATEKEEPER "$DOC"
  mk_doc "" "" $'### 2026-03-15 10:00 - PRE-RED GATE\n- pre-red-gate: OVERRIDE（人間が承認: 理由）\n' yes; r12_run R8b-valid "$DOC"
  mk_doc "" "" $'### 2026-03-15 10:00 - PRE-RED GATE\n- pre-red-gate: OVERRIDE（）\n' yes; r12_run R8b-empty "$DOC"
  mk_doc "" "" $'### 2026-03-15 10:00 - PRE-RED GATE\n- pre-red-gate: OVERRIDE（ ）\n' yes; r12_run R8b-space "$DOC"
  mk_doc "" "" "### 2026-03-15 10:00 - PRE-RED GATE"$'\n'"- pre-red-gate: OVERRIDE（${TABC}）"$'\n' yes; r12_run R8b-tab "$DOC"
  # 検査が空振りしていないこと: 記録なしで commit 側が非 0、PASS で 0
  mk_doc "" "" "" yes
  CYCLE_DOC="$DOC" bash -c "$R12_CODE" >/dev/null 2>&1 && cn_rc=0 || cn_rc=$?
  mk_doc "" "" "$E_PASS" yes
  CYCLE_DOC="$DOC" bash -c "$R12_CODE" >/dev/null 2>&1 && cp_rc=0 || cp_rc=$?
  if [ -z "$r12_bad" ] && [ "$cn_rc" -ne 0 ] && [ "$cp_rc" -eq 0 ]; then
    pass "TC-R12: commit check matches gate on $r12_n fixtures"
  else
    fail "TC-R12: mismatches:${r12_bad:- none} (no-record rc=$cn_rc, pass rc=$cp_rc)"
  fi
fi

echo ""
echo "TC-R13: printed Run command is executable and reaches pre-red-gate"
mk_doc "" "" "" yes
run_g "$DOC"
run_line=$(grep -E '^Run: ' <<<"$G_OUT" | head -1 || true)
if [ "$G_RC" -ne 1 ] || [ -z "$run_line" ]; then
  fail "TC-R13: gate did not BLOCK with a 'Run: ' line (rc=$G_RC output: $G_OUT)"
else
  run_cmd="${run_line#Run: }"
  R13_OUT=$(bash -c "$run_cmd" 2>&1) && R13_RC=0 || R13_RC=$?
  if [ "$R13_RC" -eq 1 ] && grep -qF "BLOCK: sync-plan not completed" <<<"$R13_OUT"; then
    pass "TC-R13: Run command executes pre-red-gate.sh (rc=$R13_RC)"
  else
    fail "TC-R13: Run command rc=$R13_RC output: $R13_OUT"
  fi
fi

echo ""
echo "TC-R14: Run command does not evaluate shell syntax in the Cycle doc path"
mk_doc "" "" "" yes
R14_DOC="$(dirname "$DOC")/20261118_2304_"'$(printf INJ%s ECTED >&2)'".md"
cp "$DOC" "$R14_DOC"
run_g "$R14_DOC"
run_line=$(grep -E '^Run: ' <<<"$G_OUT" | head -1 || true)
if [ "$G_RC" -ne 1 ] || [ -z "$run_line" ]; then
  fail "TC-R14: gate did not BLOCK with a 'Run: ' line (rc=$G_RC output: $G_OUT)"
else
  R14_OUT=$(bash -c "${run_line#Run: }" 2>&1) || true
  if grep -qF "INJECTED" <<<"$R14_OUT"; then
    fail "TC-R14: path was evaluated by the printed command: $R14_OUT"
  elif grep -qF "BLOCK: sync-plan not completed" <<<"$R14_OUT"; then
    pass "TC-R14: Run command passes the path literally"
  else
    fail "TC-R14: Run command did not reach pre-red-gate: $R14_OUT"
  fi
fi

echo ""
echo "TC-R15: gate and commit check agree on fence, reason and locale cases"
if [ -z "$R12_CODE" ]; then
  fail "TC-R15: commit check not extracted"
else
  r15_bad=""
  r15_n=0
  # r15_case LABEL WANT_RC BODY: gate and commit check, in the C locale and the default one, must all give WANT
  r15_case() {
    local label="$1" want="$2" body="$3" g_c g_d c_c c_d
    mk_doc "" "" "### 2026-03-15 10:00 - PRE-RED GATE"$'\n'"$body"$'\n' yes
    LC_ALL=C bash "$SCRIPT" "$DOC" >/dev/null 2>&1 && g_c=0 || g_c=1
    bash "$SCRIPT" "$DOC" >/dev/null 2>&1 && g_d=0 || g_d=1
    LC_ALL=C CYCLE_DOC="$DOC" bash -c "$R12_CODE" >/dev/null 2>&1 && c_c=0 || c_c=1
    CYCLE_DOC="$DOC" bash -c "$R12_CODE" >/dev/null 2>&1 && c_d=0 || c_d=1
    r15_n=$((r15_n + 1))
    if [ "$g_c" != "$want" ] || [ "$g_d" != "$want" ] || [ "$c_c" != "$want" ] || [ "$c_d" != "$want" ]; then
      r15_bad="$r15_bad [$label: want=$want gate C=$g_c def=$g_d commit C=$c_c def=$c_d]"
    fi
  }
  r15_case tilde-fence-pass 1 $'- pre-red-gate: BLOCK（x）\n~~~markdown\n- pre-red-gate: PASS\n~~~'
  r15_case mixed-fence-pass 1 $'- pre-red-gate: BLOCK（x）\n```\n~~~\n- pre-red-gate: PASS\n```'
  r15_case reason-then-note 1 '- pre-red-gate: OVERRIDE（）補足（rc=1）'
  r15_case ideographic-space 1 '- pre-red-gate: OVERRIDE（　）'
  r15_case valid-with-note 0 '- pre-red-gate: OVERRIDE（承認済み）補足'
  r15_case plain-pass 0 '- pre-red-gate: PASS'
  if [ -z "$r15_bad" ]; then
    pass "TC-R15: gate and commit check agree on $r15_n fixtures"
  else
    fail "TC-R15: mismatches:$r15_bad"
  fi
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
