#!/bin/bash
# test-plan-lint.sh - scripts/gates/plan-lint.sh (acceptance criteria check) tests
#
# plan-lint の契約: bash plan-lint.sh <plan>。PASS は exit 0、BLOCK は exit 1 で理由を stdout に出す。
# BLOCK 行は 'BLOCK:' で始める。固定する文言（GREEN はこれに合わせる）:
#   節が無い        BLOCK: no '## 受け入れ条件' section
#   AC が 0 件      BLOCK: '## 受け入れ条件' has no '- AC-N:' line
#   AC-ID 重複      BLOCK: duplicate AC-ID: AC-1
#   確かめ方の数    BLOCK: AC-1: needs exactly one 確かめ方 line (found 0)   (found 2 もある)
#   種類が不正      BLOCK: AC-1: unknown 確かめ方 kind: 目視
#   TC-ID が無い    BLOCK: AC-1: TC-99 is not in the Test List
#   テストに ID 無  BLOCK: AC-1: テスト needs at least one TC-ID
#   コマンドが不正  BLOCK: AC-1: コマンド needs a non-empty command in backticks
#   人が確認が空    BLOCK: AC-1: 人が確認 needs a non-empty description
#   未定            BLOCK: AC-2: 未定の問い: <問い>   (1 件 1 行)
#   PASS            PASS: ... (exit 0)
#
# TC-01: BLOCK when the section is missing
# TC-02: BLOCK when the section has no AC line
# TC-03: BLOCK (names the AC) when the 確かめ方 line is missing or doubled
# TC-04: BLOCK when the kind is none of the four
# TC-05: BLOCK (names the TC) when a TC-ID is not in the Test List
# TC-06: BLOCK on empty 人が確認 / malformed コマンド / テスト without ID
# TC-07: PASS on a well-formed plan with the three kinds
# TC-07b: BLOCK on a duplicated AC-ID
# TC-08: BLOCK on 未定 and print the questions one per line
# TC-09: fenced (``` and ~~~) section is not counted
# TC-10: nothing after the Record heading counts (the heading cuts even inside a fence)
# TC-11: pre-approve-gate runs plan-lint (rc and reason carried through)
# TC-12: spec SKILL.md Step 7 calls plan-lint before Step 7.2
# TC-13: the Plan File Template example passes plan-lint; sync-plan / cycle template carry the section
#
# TC-R1: TC-ID is read the same way in the AC and in the Test List (hyphen / dot IDs)
# TC-R2: a TC range (TC-01〜TC-03) is refused
# TC-R3: blank-only 人が確認 / コマンド (U+3000, U+00A0) BLOCK in the C locale and in UTF-8
# TC-R4: an AC-looking line in the section that is not '- AC-N:' is refused
# TC-R5: Test List heading with a note, TC lines with a note or [X] are read
# TC-R6: a longer fence is not closed by a shorter one
# TC-R7: a line starting with inline code does not open a fence
# TC-R8: a tab inside an AC line cannot hide a missing 確かめ方

set -uo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LINT="$BASE_DIR/scripts/gates/plan-lint.sh"
GATE="$BASE_DIR/scripts/gates/pre-approve-gate.sh"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== Plan Lint Tests ==="

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Independent oracle: same as test-pre-approve-gate.sh (does not use plan-hash.sh).
canon_hash() {
  awk '$0=="## Plan Review Record"{exit}{print}' "$1" | shasum -a 256 | awk '{print $1}'
}

# run_lint <plan> -> sets rc and output
run_lint() {
  output=$(bash "$LINT" "$1" 2>&1) && rc=$? || rc=$?
}

# expect_block <label> <plan> <message>: rc=1, a line starting 'BLOCK:', and the message is printed
expect_block() {
  local label="$1" plan="$2" msg="$3"
  run_lint "$plan"
  if [ "$rc" -ne 1 ]; then
    fail "$label: expected rc=1, got rc=$rc output: $output"
    return
  fi
  if ! grep -q '^BLOCK:' <<< "$output"; then
    fail "$label: no line starting with 'BLOCK:' in output: $output"
    return
  fi
  if grep -qF -- "$msg" <<< "$output"; then
    pass "$label: rc=1 and '$msg'"
  else
    fail "$label: message '$msg' not in output: $output"
  fi
}

# tl_tail: the Test List that every fixture shares
tl_tail() {
  echo "## Test List"
  echo ""
  echo "### TODO"
  echo "- [ ] TC-01: first case"
  echo "- [x] TC-02: second case"
  echo ""
}

# mk_one <path> <check line>: one AC (AC-1) with the given 確かめ方 line (full line text)
mk_one() {
  {
    echo "# Sample plan"
    echo ""
    echo "## Context"
    echo "Body."
    echo ""
    echo "## 受け入れ条件"
    echo ""
    echo "- AC-1: cond one"
    printf '%s\n' "$2"
    echo ""
    tl_tail
  } > "$1"
}

# ---------------------------------------------------------------------------
echo ""
echo "TC-01: BLOCK when the section is missing"
# Given: a plan with no acceptance criteria section (the heading is only quoted in prose)
{
  echo "# Sample plan"
  echo ""
  echo "## Context"
  echo 'Write the "## 受け入れ条件" section later.'
  echo ""
  tl_tail
} > "$TMPDIR/tc01.md"
# When / Then
expect_block "TC-01" "$TMPDIR/tc01.md" "BLOCK: no '## 受け入れ条件' section"

# ---------------------------------------------------------------------------
echo ""
echo "TC-02: BLOCK when the section has no AC line"
# Given: the section exists but holds only prose and a bullet that is not '- AC-N:'
{
  echo "# Sample plan"
  echo ""
  echo "## 受け入れ条件"
  echo ""
  echo "後で書く。"
  echo "- 条件はまだ無い"
  echo ""
  tl_tail
} > "$TMPDIR/tc02.md"
# When / Then
expect_block "TC-02" "$TMPDIR/tc02.md" "BLOCK: '## 受け入れ条件' has no '- AC-N:' line"

# ---------------------------------------------------------------------------
echo ""
echo "TC-03: BLOCK naming the AC when the 確かめ方 line is missing or doubled"
# Given (a): AC-1 has no 確かめ方 line, AC-2 is valid
{
  echo "# Sample plan"
  echo ""
  echo "## 受け入れ条件"
  echo ""
  echo "- AC-1: cond one"
  echo "- AC-2: cond two"
  echo "  - 確かめ方: テスト TC-01"
  echo ""
  tl_tail
} > "$TMPDIR/tc03a.md"
expect_block "TC-03a (missing)" "$TMPDIR/tc03a.md" "BLOCK: AC-1: needs exactly one 確かめ方 line (found 0)"
# a valid neighbour must not be blamed
if [ "$rc" -ne 1 ] || grep -qF -- "AC-2:" <<< "$output"; then
  fail "TC-03a: expected rc=1 without naming AC-2 (valid), got rc=$rc output: $output"
else
  pass "TC-03a: valid AC-2 is not blamed"
fi
# Given (b): AC-1 has two 確かめ方 lines
{
  echo "# Sample plan"
  echo ""
  echo "## 受け入れ条件"
  echo ""
  echo "- AC-1: cond one"
  echo "  - 確かめ方: テスト TC-01"
  echo "  - 確かめ方: テスト TC-02"
  echo ""
  tl_tail
} > "$TMPDIR/tc03b.md"
expect_block "TC-03b (two lines)" "$TMPDIR/tc03b.md" "BLOCK: AC-1: needs exactly one 確かめ方 line (found 2)"

# ---------------------------------------------------------------------------
echo ""
echo "TC-04: BLOCK when the kind is none of the four"
# Given: 確かめ方 is 目視
mk_one "$TMPDIR/tc04.md" "  - 確かめ方: 目視"
# When / Then
expect_block "TC-04" "$TMPDIR/tc04.md" "BLOCK: AC-1: unknown 確かめ方 kind: 目視"

# ---------------------------------------------------------------------------
echo ""
echo "TC-05: BLOCK naming the TC when it is not in the Test List"
# Given: TC-99 appears in the body and in a fenced block inside the Test List, but not as a real item
{
  echo "# Sample plan"
  echo ""
  echo "## Context"
  echo "TC-99 is discussed here but is not a test case."
  echo ""
  echo "## 受け入れ条件"
  echo ""
  echo "- AC-1: cond one"
  echo "  - 確かめ方: テスト TC-01, TC-99"
  echo ""
  echo "## Test List"
  echo ""
  echo "- [ ] TC-01: first case"
  echo '```'
  echo "- [ ] TC-99: only inside a code block"
  echo '```'
  echo ""
} > "$TMPDIR/tc05.md"
# When / Then
expect_block "TC-05" "$TMPDIR/tc05.md" "BLOCK: AC-1: TC-99 is not in the Test List"
if [ "$rc" -ne 1 ] || grep -qF -- "TC-01 is not" <<< "$output"; then
  fail "TC-05: expected rc=1 without reporting TC-01, got rc=$rc output: $output"
else
  pass "TC-05: existing TC-01 is not reported"
fi

# ---------------------------------------------------------------------------
echo ""
echo "TC-06: BLOCK on empty 人が確認 / malformed コマンド / テスト without ID"
mk_one "$TMPDIR/tc06a.md" "  - 確かめ方: 人が確認（）"
expect_block "TC-06a (人が確認 empty)" "$TMPDIR/tc06a.md" "BLOCK: AC-1: 人が確認 needs a non-empty description"
mk_one "$TMPDIR/tc06b.md" "  - 確かめ方: 人が確認（ ）"
expect_block "TC-06b (人が確認 blank)" "$TMPDIR/tc06b.md" "BLOCK: AC-1: 人が確認 needs a non-empty description"
mk_one "$TMPDIR/tc06c.md" "  - 確かめ方: コマンド ls"
expect_block "TC-06c (コマンド no backticks)" "$TMPDIR/tc06c.md" "BLOCK: AC-1: コマンド needs a non-empty command in backticks"
mk_one "$TMPDIR/tc06d.md" '  - 確かめ方: コマンド ``'
expect_block "TC-06d (コマンド empty backticks)" "$TMPDIR/tc06d.md" "BLOCK: AC-1: コマンド needs a non-empty command in backticks"
mk_one "$TMPDIR/tc06e.md" '  - 確かめ方: コマンド ` `'
expect_block "TC-06e (コマンド blank backticks)" "$TMPDIR/tc06e.md" "BLOCK: AC-1: コマンド needs a non-empty command in backticks"
mk_one "$TMPDIR/tc06f.md" "  - 確かめ方: テスト"
expect_block "TC-06f (テスト no ID)" "$TMPDIR/tc06f.md" "BLOCK: AC-1: テスト needs at least one TC-ID"

# ---------------------------------------------------------------------------
echo ""
echo "TC-07: PASS on a well-formed plan with the three kinds"
# Given: テスト / コマンド / 人が確認 one each
{
  echo "# Sample plan"
  echo ""
  echo "## 受け入れ条件"
  echo ""
  echo "- AC-1: cond one"
  echo "  - 確かめ方: テスト TC-01, TC-02"
  echo "- AC-2: cond two"
  echo '  - 確かめ方: コマンド `bash scripts/gates/plan-lint.sh plan.md`'
  echo "- AC-3: cond three"
  echo "  - 確かめ方: 人が確認（タグ v2.25.0 を見る）"
  echo ""
  tl_tail
} > "$TMPDIR/tc07.md"
# When
run_lint "$TMPDIR/tc07.md"
# Then: rc=0 and a PASS line
if [ "$rc" -eq 0 ] && grep -q '^PASS:' <<< "$output"; then
  pass "TC-07: rc=0 and PASS line"
else
  fail "TC-07: expected rc=0 and 'PASS:' line, got rc=$rc output: $output"
fi

# ---------------------------------------------------------------------------
echo ""
echo "TC-07b: BLOCK on a duplicated AC-ID"
# Given: AC-1 appears twice
{
  echo "# Sample plan"
  echo ""
  echo "## 受け入れ条件"
  echo ""
  echo "- AC-1: cond one"
  echo "  - 確かめ方: テスト TC-01"
  echo "- AC-1: cond one again"
  echo "  - 確かめ方: テスト TC-02"
  echo ""
  tl_tail
} > "$TMPDIR/tc07b.md"
# When / Then
expect_block "TC-07b" "$TMPDIR/tc07b.md" "BLOCK: duplicate AC-ID: AC-1"

# ---------------------------------------------------------------------------
echo ""
echo "TC-08: BLOCK on 未定 and print each question on its own line"
Q2="古い表がある環境でも動く必要があるか"
Q3="件数の上限を決めるか"
# Given: AC-2 and AC-3 are 未定, AC-1 is valid
{
  echo "# Sample plan"
  echo ""
  echo "## 受け入れ条件"
  echo ""
  echo "- AC-1: cond one"
  echo "  - 確かめ方: テスト TC-01"
  echo "- AC-2: cond two"
  echo "  - 確かめ方: 未定（問い: ${Q2}）"
  echo "- AC-3: cond three"
  echo "  - 確かめ方: 未定（問い: ${Q3}）"
  echo ""
  tl_tail
} > "$TMPDIR/tc08.md"
# When
run_lint "$TMPDIR/tc08.md"
# Then: rc=1; each question is its own line; exactly two question lines
if [ "$rc" -eq 1 ]; then
  pass "TC-08: rc=1"
else
  fail "TC-08: expected rc=1, got rc=$rc output: $output"
fi
if grep -qxF -- "BLOCK: AC-2: 未定の問い: $Q2" <<< "$output"; then
  pass "TC-08: AC-2 question on its own line"
else
  fail "TC-08: line for AC-2 not found in output: $output"
fi
if grep -qxF -- "BLOCK: AC-3: 未定の問い: $Q3" <<< "$output"; then
  pass "TC-08: AC-3 question on its own line"
else
  fail "TC-08: line for AC-3 not found in output: $output"
fi
n08=$(grep -cF -- "未定の問い" <<< "$output" || true)
if [ "$n08" -eq 2 ]; then
  pass "TC-08: exactly 2 question lines"
else
  fail "TC-08: expected 2 question lines, got $n08 output: $output"
fi

# ---------------------------------------------------------------------------
echo ""
echo "TC-09: a section that exists only inside a code block is not counted"
# Given (a): inside a ``` fence
{
  echo "# Sample plan"
  echo ""
  echo "Template example:"
  echo '```markdown'
  echo "## 受け入れ条件"
  echo ""
  echo "- AC-1: cond one"
  echo "  - 確かめ方: テスト TC-01"
  echo '```'
  echo ""
  tl_tail
} > "$TMPDIR/tc09a.md"
expect_block "TC-09a (backtick fence)" "$TMPDIR/tc09a.md" "BLOCK: no '## 受け入れ条件' section"
# Given (b): inside a ~~~ fence
{
  echo "# Sample plan"
  echo ""
  echo "~~~markdown"
  echo "## 受け入れ条件"
  echo ""
  echo "- AC-1: cond one"
  echo "  - 確かめ方: テスト TC-01"
  echo "~~~"
  echo ""
  tl_tail
} > "$TMPDIR/tc09b.md"
expect_block "TC-09b (tilde fence)" "$TMPDIR/tc09b.md" "BLOCK: no '## 受け入れ条件' section"
# Given (c): a ~~~ fence that contains a ``` line; the ``` line must not close it
{
  echo "# Sample plan"
  echo ""
  echo "~~~"
  echo '```'
  echo "## 受け入れ条件"
  echo ""
  echo "- AC-1: cond one"
  echo "  - 確かめ方: テスト TC-01"
  echo "~~~"
  echo ""
  tl_tail
} > "$TMPDIR/tc09c.md"
expect_block "TC-09c (backtick line inside tilde fence)" "$TMPDIR/tc09c.md" "BLOCK: no '## 受け入れ条件' section"
# Given (d): a ``` fence that contains a ~~~ line; the ~~~ line must not close it
{
  echo "# Sample plan"
  echo ""
  echo '```'
  echo "~~~"
  echo "## 受け入れ条件"
  echo ""
  echo "- AC-1: cond one"
  echo "  - 確かめ方: テスト TC-01"
  echo '```'
  echo ""
  tl_tail
} > "$TMPDIR/tc09d.md"
expect_block "TC-09d (tilde line inside backtick fence)" "$TMPDIR/tc09d.md" "BLOCK: no '## 受け入れ条件' section"
# Given (e): a real section whose 確かめ方 line exists only in a fence -> the AC has no line
{
  echo "# Sample plan"
  echo ""
  echo "## 受け入れ条件"
  echo ""
  echo "- AC-1: cond one"
  echo '```'
  echo "  - 確かめ方: テスト TC-01"
  echo '```'
  echo ""
  tl_tail
} > "$TMPDIR/tc09e.md"
expect_block "TC-09e (確かめ方 only in a fence)" "$TMPDIR/tc09e.md" "BLOCK: AC-1: needs exactly one 確かめ方 line (found 0)"

# ---------------------------------------------------------------------------
echo ""
echo "TC-10: nothing at or after the Record heading counts"
# Given (a): the section exists only after the Record
{
  echo "# Sample plan"
  echo ""
  tl_tail
  echo "## Plan Review Record"
  echo "- verdict: PASS"
  echo ""
  echo "## 受け入れ条件"
  echo ""
  echo "- AC-1: cond one"
  echo "  - 確かめ方: テスト TC-01"
} > "$TMPDIR/tc10a.md"
expect_block "TC-10a (section after Record)" "$TMPDIR/tc10a.md" "BLOCK: no '## 受け入れ条件' section"
# Given (b): the TC-ID exists only after the Record
{
  echo "# Sample plan"
  echo ""
  echo "## 受け入れ条件"
  echo ""
  echo "- AC-1: cond one"
  echo "  - 確かめ方: テスト TC-01"
  echo ""
  echo "## Plan Review Record"
  echo "- verdict: PASS"
  echo ""
  tl_tail
} > "$TMPDIR/tc10b.md"
expect_block "TC-10b (Test List after Record)" "$TMPDIR/tc10b.md" "BLOCK: AC-1: TC-01 is not in the Test List"
# Given (c): a whole-line Record heading inside a code block cuts the file; the valid section follows it
{
  echo "# Sample plan"
  echo ""
  echo "Template:"
  echo '```markdown'
  echo "## Plan Review Record"
  echo '```'
  echo ""
  echo "## 受け入れ条件"
  echo ""
  echo "- AC-1: cond one"
  echo "  - 確かめ方: テスト TC-01"
  echo ""
  tl_tail
} > "$TMPDIR/tc10c.md"
expect_block "TC-10c (Record heading inside a fence)" "$TMPDIR/tc10c.md" "BLOCK: no '## 受け入れ条件' section"
# Given (d): a line that only quotes the heading inside a longer line does not cut
{
  echo "# Sample plan"
  echo ""
  echo 'see "## Plan Review Record" below'
  echo ""
  echo "## 受け入れ条件"
  echo ""
  echo "- AC-1: cond one"
  echo "  - 確かめ方: テスト TC-01"
  echo ""
  tl_tail
} > "$TMPDIR/tc10d.md"
run_lint "$TMPDIR/tc10d.md"
if [ "$rc" -eq 0 ] && grep -q '^PASS:' <<< "$output"; then
  pass "TC-10d: a quoted heading inside a longer line does not cut"
else
  fail "TC-10d: expected rc=0 and PASS line, got rc=$rc output: $output"
fi

# ---------------------------------------------------------------------------
echo ""
echo "TC-11: pre-approve-gate runs plan-lint and carries rc and reason"
# mk_recorded <path> <body file>: body + Record with the canonical hash and plan_presented
mk_recorded() {
  cp "$2" "$1"
  {
    echo ""
    echo "## Plan Review Record"
  } >> "$1"
  local h
  h=$(canon_hash "$1")
  {
    echo "- reviewed_plan_hash: $h"
    echo "- plan_presented: 2026-11-19 13:10"
    echo "- verdict: PASS"
  } >> "$1"
}
mk_recorded "$TMPDIR/tc11_bad.md" "$TMPDIR/tc01.md"
mk_recorded "$TMPDIR/tc11_good.md" "$TMPDIR/tc07.md"
# Given: hash and plan_presented are correct in both; only the acceptance criteria differ
# When / Then (bad): rc=1 with plan-lint's reason
output=$(bash "$GATE" "$TMPDIR/tc11_bad.md" 2>&1) && rc=$? || rc=$?
if [ "$rc" -eq 1 ] && grep -qF -- "BLOCK: no '## 受け入れ条件' section" <<< "$output"; then
  pass "TC-11: gate rc=1 with the plan-lint reason"
else
  fail "TC-11: expected rc=1 and plan-lint reason, got rc=$rc output: $output"
fi
# When / Then (good): rc=0
output=$(bash "$GATE" "$TMPDIR/tc11_good.md" 2>&1) && rc=$? || rc=$?
if [ "$rc" -eq 0 ]; then
  pass "TC-11: gate rc=0 for a valid plan"
else
  fail "TC-11: expected rc=0, got rc=$rc output: $output"
fi
# The two entry points agree on the same body
run_lint "$TMPDIR/tc11_bad.md"
rc_lint=$rc
if [ "$rc_lint" -eq 1 ]; then
  pass "TC-11: plan-lint alone also blocks the same plan"
else
  fail "TC-11: plan-lint alone expected rc=1, got rc=$rc_lint output: $output"
fi

# ---------------------------------------------------------------------------
echo ""
echo "TC-12: spec SKILL.md Step 7 calls plan-lint before Step 7.2"
# Given: the Step 7 section (### Step 7 up to, not including, ### Step 8), with line numbers
sec12=$(awk '/^### Step 7/{f=1} /^### Step 8/{f=0} f{print NR": "$0}' "$BASE_DIR/skills/spec/SKILL.md")
lint_line=$(grep -F 'plan-lint.sh' <<< "$sec12" | head -1 | cut -d: -f1 || true)
recall_line=$(grep -F '**Step 7.2:' <<< "$sec12" | head -1 | cut -d: -f1 || true)
lint_n=$(grep -cF 'plan-lint.sh' <<< "$sec12" || true)
# Then: at least one plan-lint line, and the first precedes the Step 7.2 line
if [ "${lint_n:-0}" -ge 1 ]; then
  pass "TC-12: Step 7 mentions plan-lint.sh ($lint_n line(s))"
else
  fail "TC-12: Step 7 section has no plan-lint.sh line"
fi
if [ -n "$lint_line" ] && [ -n "$recall_line" ] && [ "$lint_line" -lt "$recall_line" ]; then
  pass "TC-12: plan-lint (line $lint_line) precedes Step 7.2 (line $recall_line)"
else
  fail "TC-12: expected plan-lint line < Step 7.2 line (lint='${lint_line:-none}' recall='${recall_line:-none}')"
fi

# ---------------------------------------------------------------------------
echo ""
echo "TC-13: the Plan File Template example passes plan-lint"
for ref in reference.md reference.ja.md; do
  f="$BASE_DIR/skills/spec/$ref"
  # Given: the Plan File Template section first (fence-aware: '## ' inside the fence does not end it),
  #        then its outer ```markdown block, then the 受け入れ条件 part of that block
  sec13=$(awk '/^## Plan File Template/{f=1;next} f && /^```/{fence=!fence} f && !fence && /^## /{exit} f{print}' "$f")
  block13=$(awk '/^```markdown/{f=1;next} f && /^```$/{exit} f{print}' <<< "$sec13")
  ac13=$(awk '$0=="## 受け入れ条件"{f=1;print;next} f && /^## /{exit} f{print}' <<< "$block13")
  if [ -z "$ac13" ]; then
    fail "TC-13 ($ref): no '## 受け入れ条件' example in the Plan File Template block"
    continue
  fi
  ids13=$(grep -oE 'TC-[0-9]+' <<< "$ac13" | sort -u || true)
  if [ -z "$ids13" ]; then
    fail "TC-13 ($ref): the example has no 'テスト TC-NN' (the template should show the テスト kind)"
    continue
  fi
  # When: build a plan from the example, a Test List holding exactly the example's TC-IDs, and a Record
  {
    echo "# Sample plan"
    echo ""
    printf '%s\n' "$ac13"
    echo ""
    echo "## Test List"
    echo ""
    while IFS= read -r id; do
      [ -n "$id" ] && echo "- [ ] $id: from the template example"
    done <<< "$ids13"
    echo ""
    echo "## Plan Review Record"
    echo "- verdict: PASS"
  } > "$TMPDIR/tc13_$ref"
  run_lint "$TMPDIR/tc13_$ref"
  # Then
  if [ "$rc" -eq 0 ] && grep -q '^PASS:' <<< "$output"; then
    pass "TC-13 ($ref): template example passes plan-lint"
  else
    fail "TC-13 ($ref): expected rc=0 and PASS line, got rc=$rc output: $output"
  fi
done

# sync-plan transfer table and cycle template carry the section
if grep -qE '^\|[^|]*受け入れ条件[^|]*\|' "$BASE_DIR/agents/sync-plan.md"; then
  pass "TC-13: sync-plan.md transfer table has a 受け入れ条件 row"
else
  fail "TC-13: sync-plan.md has no table row with 受け入れ条件"
fi
if grep -qx '## 受け入れ条件' "$BASE_DIR/skills/spec/templates/cycle.md"; then
  pass "TC-13: cycle template has the 受け入れ条件 section"
else
  fail "TC-13: skills/spec/templates/cycle.md has no '## 受け入れ条件' heading"
fi

# ---------------------------------------------------------------------------
# REVIEW fixes (TC-R*)
# mk_plan <path> <check line> <Test List heading> <TC line>...: AC-1 with one 確かめ方 and a custom Test List
mk_plan() {
  local path="$1" check="$2" heading="$3"
  shift 3
  {
    echo "# Sample plan"
    echo ""
    echo "## 受け入れ条件"
    echo ""
    echo "- AC-1: cond one"
    printf '%s\n' "$check"
    echo ""
    printf '%s\n' "$heading"
    echo ""
    local l
    for l in "$@"; do printf '%s\n' "$l"; done
  } > "$path"
}

# expect_pass <label> <plan>
expect_pass() {
  run_lint "$2"
  if [ "$rc" -eq 0 ] && grep -q '^PASS:' <<< "$output"; then
    pass "$1: rc=0 PASS"
  else
    fail "$1: expected rc=0 and PASS, got rc=$rc output: $output"
  fi
}

echo ""
echo "TC-R1: TC-ID is read the same way in the AC and in the Test List (hyphen / dot IDs)"
mk_plan "$TMPDIR/r1a.md" "  - 確かめ方: テスト TC-01-b" "## Test List" "- [ ] TC-01: x"
expect_block "TC-R1a (TC-01-b is not TC-01)" "$TMPDIR/r1a.md" "BLOCK: AC-1: TC-01-b is not in the Test List"
mk_plan "$TMPDIR/r1b.md" "  - 確かめ方: テスト TC-1.9" "## Test List" "- [ ] TC-1: x"
expect_block "TC-R1b (TC-1.9 is not TC-1)" "$TMPDIR/r1b.md" "BLOCK: AC-1: TC-1.9 is not in the Test List"
mk_plan "$TMPDIR/r1c.md" "  - 確かめ方: テスト TC-REF-15" "## Test List" "- [ ] TC-REF-15: x"
expect_pass "TC-R1c (hyphen ID that exists)" "$TMPDIR/r1c.md"
mk_plan "$TMPDIR/r1d.md" "  - 確かめ方: テスト TC-1.2, TC-REF-15." "## Test List" "- [ ] TC-1.2: x" "- [ ] TC-REF-15: y"
expect_pass "TC-R1d (dot ID, trailing period)" "$TMPDIR/r1d.md"

echo ""
echo "TC-R2: a TC range is refused"
mk_plan "$TMPDIR/r2.md" "  - 確かめ方: テスト TC-01〜TC-03" "## Test List" "- [ ] TC-01: x" "- [ ] TC-03: y"
expect_block "TC-R2" "$TMPDIR/r2.md" "BLOCK: AC-1: テスト lists TC-IDs one by one, not as a range"

echo ""
echo "TC-R3: blank-only descriptions BLOCK in the C locale and in UTF-8"
ideo=$(printf '\xe3\x80\x80')
nbsp=$(printf '\xc2\xa0')
mk_plan "$TMPDIR/r3a.md" "  - 確かめ方: 人が確認（${ideo}）" "## Test List" "- [ ] TC-01: x"
mk_plan "$TMPDIR/r3b.md" "  - 確かめ方: コマンド \`${nbsp}\`" "## Test List" "- [ ] TC-01: x"
for loc in C en_US.UTF-8; do
  for f in a b; do
    out=$(LC_ALL="$loc" bash "$LINT" "$TMPDIR/r3$f.md" 2>&1) && r=$? || r=$?
    if [ "$r" -eq 1 ] && grep -q '^BLOCK: AC-1: .* needs a non-empty' <<< "$out"; then
      pass "TC-R3$f (LC_ALL=$loc): rc=1 and non-empty message"
    else
      fail "TC-R3$f (LC_ALL=$loc): expected rc=1 'needs a non-empty', got rc=$r output: $out"
    fi
  done
done

echo ""
echo "TC-R4: a line in the section that looks like an AC but is not in the format is refused"
for variant in "- AC-2：全角コロンの条件" "* AC-2: アスタリスクの条件" "  - AC-2: 字下げした条件"; do
  {
    echo "## 受け入れ条件"
    echo ""
    echo "- AC-1: cond one"
    echo "  - 確かめ方: テスト TC-01"
    echo "$variant"
    echo ""
    echo "## Test List"
    echo ""
    echo "- [ ] TC-01: x"
  } > "$TMPDIR/r4.md"
  expect_block "TC-R4 ($variant)" "$TMPDIR/r4.md" "BLOCK: not an acceptance criterion line in the format '- AC-N: ...': "
done

echo ""
echo "TC-R5: Test List heading with a note and TC lines with a note or [X] are read"
mk_plan "$TMPDIR/r5.md" "  - 確かめ方: テスト TC-01, TC-02, TC-03" "## Test List（Given/When/Then）" "- [ ] TC-01 (RED): a" "- [X] TC-02: b" "- [ ] TC-03（注記）: c"
expect_pass "TC-R5" "$TMPDIR/r5.md"
mk_plan "$TMPDIR/r5b.md" "  - 確かめ方: テスト TC-01" "## Test Listing" "- [ ] TC-01: a"
expect_block "TC-R5b (Test Listing is not the Test List)" "$TMPDIR/r5b.md" "BLOCK: AC-1: TC-01 is not in the Test List"

echo ""
echo "TC-R6: a longer fence is not closed by a shorter one"
{
  echo "# Sample plan"
  echo ""
  echo '````markdown'
  echo '```'
  echo "## 受け入れ条件"
  echo ""
  echo "- AC-1: cond one"
  echo "  - 確かめ方: テスト TC-01"
  echo ""
  echo "## Test List"
  echo ""
  echo "- [ ] TC-01: x"
  echo '```'
  echo '````'
} > "$TMPDIR/r6.md"
expect_block "TC-R6" "$TMPDIR/r6.md" "BLOCK: no '## 受け入れ条件' section"

echo ""
echo "TC-R7: a line that starts with inline code does not open a fence"
{
  echo "# Sample plan"
  echo ""
  echo '```inline``` で始まる文。'
  echo ""
  echo "## 受け入れ条件"
  echo ""
  echo "- AC-1: cond one"
  echo "  - 確かめ方: テスト TC-01"
  echo ""
  echo "## Test List"
  echo ""
  echo "- [ ] TC-01: x"
} > "$TMPDIR/r7.md"
expect_pass "TC-R7" "$TMPDIR/r7.md"

echo ""
echo "TC-R8: a tab inside an AC line cannot hide a missing 確かめ方"
{
  echo "## 受け入れ条件"
  echo ""
  printf -- '- AC-1\t1\tテスト TC-01: 条件\n'
  echo ""
  echo "## Test List"
  echo ""
  echo "- [ ] TC-01: x"
} > "$TMPDIR/r8.md"
expect_block "TC-R8" "$TMPDIR/r8.md" "needs exactly one 確かめ方 line (found 0)"

echo ""
echo "=== Summary ==="
echo "PASS: $PASS"
echo "FAIL: $FAIL"
[ "$FAIL" -eq 0 ] || exit 1
