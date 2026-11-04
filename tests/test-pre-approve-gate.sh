#!/bin/bash
# test-pre-approve-gate.sh - plan-hash.sh / pre-approve-gate.sh tests
# TC-01: PASS when hash and plan_presented are filled correctly
# TC-02: BLOCK when reviewed_plan_hash is empty
# TC-03: BLOCK when the body above the Record changed after the hash was recorded
# TC-04: BLOCK when plan_presented is empty
# TC-05: BLOCK when plan_presented is still the template placeholder
# TC-06: BLOCK when the plan_presented line is missing
# TC-07: BLOCK when the Record heading is missing (only quoted in the body)
# TC-08: BLOCK when a valid hash line exists only in the body above the Record
# TC-09: BLOCK on a missing file / no argument
# TC-10: plan-hash.sh matches the canonical awk|shasum; exit 1 without heading
# TC-11: spec docs call pre-approve-gate in the Step 8 section
# TC-12: BLOCK when values exist only in a later section (hash / plan_presented)
# TC-13: PASS when the body quotes the heading text inside a longer line
# TC-14: PASS when invoked from another cwd by absolute path
# TC-15: duplicate reviewed_plan_hash lines use the last one (same as pre-red-gate)
# TC-16: exported CDPATH does not break the relative-path call (both gates)

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GATE="$BASE_DIR/scripts/gates/pre-approve-gate.sh"
HASHER="$BASE_DIR/scripts/gates/plan-hash.sh"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== Pre-Approve Gate Tests ==="

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Independent oracle: canonical hash of everything above the first line that is
# exactly "## Plan Review Record" (does not use plan-hash.sh).
canon_hash() {
  awk '$0=="## Plan Review Record"{exit}{print}' "$1" | shasum -a 256 | awk '{print $1}'
}

# mk_plan <path> <body_extra_line> <hash_mode> <presented_mode>
#   hash_mode: auto | empty | none | <64-hex literal>
#   presented_mode: ok | empty | template | none
# The Record is followed by a "## Post-Approve Action" section.
mk_plan() {
  local path="$1" extra="$2" hmode="$3" pmode="$4" h
  {
    echo "# Sample plan"
    echo ""
    echo "## Context"
    echo "Body text of the plan."
    [ -n "$extra" ] && echo "$extra"
    echo ""
    echo "## Plan Review Record"
  } > "$path"
  case "$hmode" in
    auto) h=$(canon_hash "$path"); echo "- reviewed_plan_hash: $h" >> "$path" ;;
    empty) echo "- reviewed_plan_hash: " >> "$path" ;;
    none) : ;;
    *) echo "- reviewed_plan_hash: $hmode" >> "$path" ;;
  esac
  case "$pmode" in
    ok) echo "- plan_presented: 2026-11-04 10:21" >> "$path" ;;
    empty) echo "- plan_presented: " >> "$path" ;;
    template) echo "- plan_presented: [YYYY-MM-DD HH:MM]" >> "$path" ;;
    none) : ;;
  esac
  {
    echo "- verdict: PASS"
    echo ""
    echo "## Post-Approve Action"
    echo "Run /orchestrate."
  } >> "$path"
}

# run_gate <plan> -> sets rc and output
run_gate() {
  output=$(bash "$GATE" "$1" 2>&1) && rc=$? || rc=$?
}

# TC-01
echo ""
echo "TC-01: PASS with correct hash and plan_presented"
# Given: a plan whose Record has the canonical hash and a filled plan_presented
mk_plan "$TMPDIR/tc01.md" "" auto ok
# When: pre-approve-gate runs
run_gate "$TMPDIR/tc01.md"
# Then: exit 0
if [ "$rc" -eq 0 ]; then
  pass "exit 0 on valid plan"
else
  fail "Expected exit 0, got rc=$rc output: $output"
fi

# TC-02
echo ""
echo "TC-02: BLOCK when reviewed_plan_hash is empty"
# Given: reviewed_plan_hash has no value
mk_plan "$TMPDIR/tc02.md" "" empty ok
# When / Then
run_gate "$TMPDIR/tc02.md"
if [ "$rc" -eq 1 ]; then
  pass "exit 1 on empty hash"
else
  fail "Expected exit 1, got rc=$rc output: $output"
fi

# TC-03
echo ""
echo "TC-03: BLOCK when body above the Record changed after recording"
# Given: hash recorded for the TC-01 body, then the body differs by one line
tc01_hash=$(canon_hash "$TMPDIR/tc01.md")
mk_plan "$TMPDIR/tc03.md" "One extra line added after review." "$tc01_hash" ok
# When / Then
run_gate "$TMPDIR/tc03.md"
if [ "$rc" -eq 1 ]; then
  pass "exit 1 on hash mismatch"
else
  fail "Expected exit 1, got rc=$rc output: $output"
fi

# TC-04
echo ""
echo "TC-04: BLOCK when plan_presented is empty"
# Given: plan_presented has no value
mk_plan "$TMPDIR/tc04.md" "" auto empty
# When / Then
run_gate "$TMPDIR/tc04.md"
if [ "$rc" -eq 1 ]; then
  pass "exit 1 on empty plan_presented"
else
  fail "Expected exit 1, got rc=$rc output: $output"
fi

# TC-05
echo ""
echo "TC-05: BLOCK when plan_presented is the template placeholder"
# Given: plan_presented is the literal template copy
mk_plan "$TMPDIR/tc05.md" "" auto template
# When / Then
run_gate "$TMPDIR/tc05.md"
if [ "$rc" -eq 1 ]; then
  pass "exit 1 on template plan_presented"
else
  fail "Expected exit 1, got rc=$rc output: $output"
fi

# TC-06
echo ""
echo "TC-06: BLOCK when plan_presented line is missing"
# Given: no plan_presented line in the Record
mk_plan "$TMPDIR/tc06.md" "" auto none
# When / Then
run_gate "$TMPDIR/tc06.md"
if [ "$rc" -eq 1 ]; then
  pass "exit 1 on missing plan_presented"
else
  fail "Expected exit 1, got rc=$rc output: $output"
fi

# TC-07
echo ""
echo "TC-07: BLOCK when the Record heading is missing (quoted in body only)"
# Given: a plan with no real heading; the text is only quoted inside a line
cat > "$TMPDIR/tc07.md" <<'PLAN'
# Sample plan

## Context
See "## Plan Review Record" below for the review.
- reviewed_plan_hash: 0000000000000000000000000000000000000000000000000000000000000000
- plan_presented: 2026-11-04 10:21
PLAN
# When / Then
run_gate "$TMPDIR/tc07.md"
if [ "$rc" -eq 1 ]; then
  pass "exit 1 without Record heading"
else
  fail "Expected exit 1, got rc=$rc output: $output"
fi

# TC-08
echo ""
echo "TC-08: BLOCK when the hash line is only in the body above the Record"
# Given: a hash line above the heading; the Record section has no hash
mk_plan "$TMPDIR/tc08.md" "- reviewed_plan_hash: $tc01_hash" none ok
# When / Then
run_gate "$TMPDIR/tc08.md"
if [ "$rc" -eq 1 ]; then
  pass "exit 1 when hash is outside the Record section"
else
  fail "Expected exit 1, got rc=$rc output: $output"
fi

# TC-09
echo ""
echo "TC-09: BLOCK on missing file and no argument"
# Given: a path that does not exist / no argument
# When / Then
run_gate "$TMPDIR/does-not-exist.md"
rc_missing=$rc
output=$(bash "$GATE" 2>&1) && rc=$? || rc=$?
rc_noarg=$rc
if [ "$rc_missing" -eq 1 ]; then
  pass "exit 1 on nonexistent file"
else
  fail "Expected exit 1 on nonexistent file, got rc=$rc_missing"
fi
if [ "$rc_noarg" -eq 1 ]; then
  pass "exit 1 with no argument"
else
  fail "Expected exit 1 with no argument, got rc=$rc_noarg output: $output"
fi

# TC-10
echo ""
echo "TC-10: plan-hash.sh matches the canonical algorithm"
# Given: the TC-01 fixture
expected=$(canon_hash "$TMPDIR/tc01.md")
# When: plan-hash.sh runs
out=$(bash "$HASHER" "$TMPDIR/tc01.md" 2>&1) && rc=$? || rc=$?
# Then: stdout equals the independent computation
if [ "$rc" -eq 0 ] && [ "$out" = "$expected" ]; then
  pass "plan-hash.sh output equals awk|shasum"
else
  fail "Expected rc=0 and $expected, got rc=$rc out: $out"
fi
# Given: a plan with no Record heading
# When / Then: exit 1
out=$(bash "$HASHER" "$TMPDIR/tc07.md" 2>&1) && rc=$? || rc=$?
if [ "$rc" -eq 1 ]; then
  pass "plan-hash.sh exit 1 without heading"
else
  fail "Expected exit 1 without heading, got rc=$rc out: $out"
fi

# TC-11
echo ""
echo "TC-11: spec docs call pre-approve-gate in the Step 8 section"
# Given: spec SKILL.md (### Step 8) and the two references (## Step 8)
skill_sec=$(awk '/^### Step 8/{f=1;next} f && /^#{1,3} /{exit} f{print}' "$BASE_DIR/skills/spec/SKILL.md")
ref_sec=$(awk '/^## Step 8/{f=1;next} f && /^#{1,2} /{exit} f{print}' "$BASE_DIR/skills/spec/reference.md")
refja_sec=$(awk '/^## Step 8/{f=1;next} f && /^#{1,2} /{exit} f{print}' "$BASE_DIR/skills/spec/reference.ja.md")
GATE_REF='../../scripts/gates/pre-approve-gate.sh'
SILENT='黙って hash だけを記録し直さない'
# Then: each section mentions the gate path
if grep -qF -- "$GATE_REF" <<< "$skill_sec"; then
  pass "SKILL.md Step 8 references pre-approve-gate"
else
  fail "SKILL.md Step 8 section lacks $GATE_REF"
fi
if grep -qF -- "$GATE_REF" <<< "$ref_sec"; then
  pass "reference.md Step 8 references pre-approve-gate"
else
  fail "reference.md Step 8 section lacks $GATE_REF"
fi
if grep -qF -- "$GATE_REF" <<< "$refja_sec"; then
  pass "reference.ja.md Step 8 references pre-approve-gate"
else
  fail "reference.ja.md Step 8 section lacks $GATE_REF"
fi
# Then: both references forbid silently re-recording only the hash
if grep -qF -- "$SILENT" <<< "$ref_sec"; then
  pass "reference.md Step 8 forbids silent re-record"
else
  fail "reference.md Step 8 section lacks '$SILENT'"
fi
if grep -qF -- "$SILENT" <<< "$refja_sec"; then
  pass "reference.ja.md Step 8 forbids silent re-record"
else
  fail "reference.ja.md Step 8 section lacks '$SILENT'"
fi

# TC-12
echo ""
echo "TC-12: BLOCK when values exist only in a later section"
# Given (hash): Record lacks the hash; a later section holds the correct one
{
  echo "# Sample plan"
  echo ""
  echo "## Context"
  echo "Body text of the plan."
  echo ""
  echo "## Plan Review Record"
} > "$TMPDIR/tc12a.md"
h12=$(canon_hash "$TMPDIR/tc12a.md")
{
  echo "- plan_presented: 2026-11-04 10:21"
  echo ""
  echo "## Post-Approve Action"
  echo "- reviewed_plan_hash: $h12"
} >> "$TMPDIR/tc12a.md"
run_gate "$TMPDIR/tc12a.md"
if [ "$rc" -eq 1 ]; then
  pass "exit 1 when only a later section has the hash"
else
  fail "Expected exit 1, got rc=$rc output: $output"
fi
# Given (plan_presented): Record lacks it; a later section holds a valid one
{
  echo "# Sample plan"
  echo ""
  echo "## Context"
  echo "Body text of the plan."
  echo ""
  echo "## Plan Review Record"
  echo "- reviewed_plan_hash: $h12"
  echo ""
  echo "## Post-Approve Action"
  echo "- plan_presented: 2026-11-04 10:21"
} > "$TMPDIR/tc12b.md"
run_gate "$TMPDIR/tc12b.md"
if [ "$rc" -eq 1 ]; then
  pass "exit 1 when only a later section has plan_presented"
else
  fail "Expected exit 1, got rc=$rc output: $output"
fi

# TC-13
echo ""
echo "TC-13: PASS when the body quotes the heading text inside a longer line"
# Given: a body line containing the heading text but not equal to it
mk_plan "$TMPDIR/tc13.md" 'see "## Plan Review Record" below' auto ok
# When / Then: whole-line boundary keeps the canonical hash valid
run_gate "$TMPDIR/tc13.md"
if [ "$rc" -eq 0 ]; then
  pass "exit 0 with quoted heading text in body"
else
  fail "Expected exit 0, got rc=$rc output: $output"
fi

# TC-14
echo ""
echo "TC-14: PASS when invoked from another cwd by absolute path"
# Given: a different working directory
other=$(mktemp -d)
# When: the gate is called by absolute path on the TC-01 fixture
output=$(cd "$other" && bash "$GATE" "$TMPDIR/tc01.md" 2>&1) && rc=$? || rc=$?
rmdir "$other"
# Then: exit 0 (plan-hash.sh is resolved independent of cwd)
if [ "$rc" -eq 0 ]; then
  pass "exit 0 from another cwd"
else
  fail "Expected exit 0, got rc=$rc output: $output"
fi

# TC-15
echo ""
echo "TC-15: duplicate reviewed_plan_hash lines use the last one (same as pre-red-gate)"
# Given: a Record with the correct hash first and a wrong hash on the next line
zero_hash=$(printf '0%.0s' $(seq 1 64))
mk_plan "$TMPDIR/tc15a.md" "" auto ok
good15=$(canon_hash "$TMPDIR/tc15a.md")
{
  echo "# Sample plan"; echo ""; echo "## Context"; echo "Body text of the plan."; echo ""
  echo "## Plan Review Record"
  echo "- reviewed_plan_hash: $good15"
  echo "- reviewed_plan_hash: $zero_hash"
  echo "- plan_presented: 2026-11-04 10:21"
  echo "- verdict: PASS"
} > "$TMPDIR/tc15a.md"
# When / Then: the last line (wrong) decides, so BLOCK
run_gate "$TMPDIR/tc15a.md"
if [ "$rc" -eq 1 ]; then
  pass "exit 1 when the last hash line is wrong"
else
  fail "Expected exit 1, got rc=$rc output: $output"
fi
# Given: wrong hash first, correct hash last
{
  echo "# Sample plan"; echo ""; echo "## Context"; echo "Body text of the plan."; echo ""
  echo "## Plan Review Record"
  echo "- reviewed_plan_hash: $zero_hash"
  echo "- reviewed_plan_hash: $good15"
  echo "- plan_presented: 2026-11-04 10:21"
  echo "- verdict: PASS"
} > "$TMPDIR/tc15d.md"
# When / Then: the last line (correct) decides, so PASS
run_gate "$TMPDIR/tc15d.md"
if [ "$rc" -eq 0 ]; then
  pass "exit 0 when the last hash line is correct"
else
  fail "Expected exit 0, got rc=$rc output: $output"
fi

# TC-16
echo ""
echo "TC-16: exported CDPATH does not break the relative-path call"
# Given: CDPATH exported and the gates called by a relative path
mk_plan "$TMPDIR/tc16.md" "" auto ok
mkdir -p "$TMPDIR/tc16proj/docs/cycles"
h16=$(canon_hash "$TMPDIR/tc16.md")
cat > "$TMPDIR/tc16proj/docs/cycles/20260101_0000_tc16.md" <<CYCLE
---
phase: RED
plan_file: $TMPDIR/tc16.md
updated: 2026-01-01 00:10
---
# Fixture cycle tc16

## Progress Log

### 2026-01-01 00:00 - SYNC-PLAN
- Cycle doc generated
- Phase completed

### 2026-01-01 00:05 - Plan Review (pre-approval)
- codex_session_id: session-tc16
- review_attempts:
  - {started: 2026-01-01 00:01, completed: 2026-01-01 00:03, verdict: PASS}
- unresolved_blocks: なし
- reviewed_plan_hash: $h16
- verdict: PASS
- Phase completed
CYCLE
# When: pre-approve-gate runs with CDPATH including "."
output=$(cd "$BASE_DIR" && CDPATH=".:$TMPDIR" bash scripts/gates/pre-approve-gate.sh "$TMPDIR/tc16.md" 2>&1) && rc=$? || rc=$?
# Then: exit 0
if [ "$rc" -eq 0 ]; then
  pass "pre-approve-gate exit 0 with CDPATH"
else
  fail "Expected exit 0, got rc=$rc output: $output"
fi
# When: pre-red-gate runs the same way
output=$(cd "$BASE_DIR" && CDPATH=".:$TMPDIR" DEV_CREW_PLAN_DIR="$TMPDIR" bash scripts/gates/pre-red-gate.sh "$TMPDIR/tc16proj/docs/cycles/20260101_0000_tc16.md" 2>&1) && rc=$? || rc=$?
# Then: plan-hash.sh is still found
if ! grep -q 'plan-hash.sh' <<< "$output"; then
  pass "pre-red-gate finds plan-hash.sh with CDPATH"
else
  fail "plan-hash.sh not resolved with CDPATH, rc=$rc output: $output"
fi

echo ""
echo "=== Summary ==="
echo "PASS: $PASS"
echo "FAIL: $FAIL"
[ "$FAIL" -eq 0 ] || exit 1
