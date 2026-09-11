#!/bin/bash
# test-retro-insight-ledger.sh - retrospective unit ledger tests
# TC-01 ~ TC-59: fixture-based validation of retro-insight-ledger.sh output.
# All fixtures live under a mktemp -d tree; no real repository is read or written.

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$BASE_DIR/scripts/retro-insight-ledger.sh"
TMPDIR_FIX="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_FIX"' EXIT

ERRFILE="$TMPDIR_FIX/.stderr"
LEDGER_HEADER=$'label\tdoc\tretro_status\thas_codify\tform\tcontainer\tunit_no\tline\tpolarity\theading'

PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

# Helper: create an isolated fixture repo containing docs/cycles/
mk_repo() {
  local r="$TMPDIR_FIX/$1"
  mkdir -p "$r/docs/cycles"
  printf '%s' "$r"
}

# Helper: build a label -> repo mapping TSV. Usage: mk_conf <name> <label> <path> [...]
mk_conf() {
  local c="$TMPDIR_FIX/$1.tsv"
  shift
  : > "$c"
  while [ "$#" -ge 2 ]; do
    printf '%s\t%s\n' "$1" "$2" >> "$c"
    shift 2
  done
  printf '%s' "$c"
}

# Helper: path of a fixture cycle doc. Usage: doc_path <repo> <filename> [archive]
doc_path() {
  local d="$1/docs/cycles"
  [ "${3:-}" = "archive" ] && d="$1/docs/cycles/archive"
  mkdir -p "$d"
  printf '%s' "$d/$2"
}

# Helper: run the subject script, capturing stdout / stderr / exit code separately
run_cmd() {
  RUN_RC=0
  RUN_OUT="$(bash "$SCRIPT" "$@" 2>"$ERRFILE")" || RUN_RC=$?
  RUN_ERR="$(cat "$ERRFILE")"
}

# Helper: data row count of a ledger output (header excluded)
nrows() { awk -F'\t' 'NR>1 && NF>0 {n++} END {print n+0}' <<<"$1"; }

# Helper: value of column $3 on data row $2 of ledger output $1
lfield() { awk -F'\t' -v r="$2" -v c="$3" 'NR>1 && NF>0 {i++; if (i==r) {print $c; exit}}' <<<"$1"; }

# Helper: tab-separated field count of data row $2 of ledger output $1
lnf() { awk -F'\t' -v r="$2" 'NR>1 && NF>0 {i++; if (i==r) {print NF; exit}}' <<<"$1"; }

# Helper: value of key $3 on the STAT line of label $2 in summary output $1
sval() {
  awk -v L="label=$2" -v K="$3" '$1=="STAT" && $2==L {
    for (i=3; i<=NF; i++) { p = index($i, "="); if (substr($i, 1, p-1) == K) { print substr($i, p+1); exit } }
  }' <<<"$1"
}

# Helper: occurrences of the fixed string $2 inside text $1 (grep -c is avoided on purpose)
nfixed() { awk -v p="$2" 'index($0, p) > 0 {n++} END {print n+0}' <<<"$1"; }

# Helper: fixed-string / regex presence
has()   { grep -qF -- "$2" <<<"$1"; }
hasre() { grep -qE -- "$2" <<<"$1"; }

echo "=== Retrospective Insight Ledger Tests ==="

# --- Prerequisite check ---
echo ""
echo "Prerequisite: retro-insight-ledger.sh exists"
if [ ! -f "$SCRIPT" ]; then
  fail "Prerequisite: scripts/retro-insight-ledger.sh not found"
  echo ""
  echo "=== Summary ==="
  echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
  exit 1
fi

# ---------------------------------------------------------------------------
# Contract
# ---------------------------------------------------------------------------

echo ""
echo "TC-01: no arguments -> exit 2 + Usage on stderr"
TC01_RC=0
TC01_ERR="$(bash "$SCRIPT" 2>&1 >/dev/null)" || TC01_RC=$?
if [ "$TC01_RC" = "2" ] && has "$TC01_ERR" "Usage:"; then
  pass "TC-01: no args -> exit 2 with Usage:"
else
  fail "TC-01: expected exit 2 + 'Usage:' on stderr (rc=$TC01_RC)"
fi

echo ""
echo "TC-02: unknown subcommand -> exit 2"
TC02_R=$(mk_repo tc02)
TC02_CONF=$(mk_conf tc02 R1 "$TC02_R")
run_cmd ledgr "$TC02_CONF" || true
if [ "$RUN_RC" = "2" ]; then
  pass "TC-02: unknown subcommand -> exit 2"
else
  fail "TC-02: expected exit 2 for unknown subcommand (rc=$RUN_RC)"
fi

echo ""
echo "TC-03: subcommand without repos_tsv -> exit 2"
run_cmd ledger || true
if [ "$RUN_RC" = "2" ]; then
  pass "TC-03: missing repos_tsv -> exit 2"
else
  fail "TC-03: expected exit 2 for missing repos_tsv (rc=$RUN_RC)"
fi

echo ""
echo "TC-04: non-existent repos_tsv -> exit 2"
run_cmd ledger "$TMPDIR_FIX/tc04-absent.tsv" || true
if [ "$RUN_RC" = "2" ]; then
  pass "TC-04: unreadable repos_tsv -> exit 2"
else
  fail "TC-04: expected exit 2 for unreadable repos_tsv (rc=$RUN_RC)"
fi

echo ""
echo "TC-05: comment and blank lines in repos_tsv are not labels"
TC05_R=$(mk_repo tc05)
cat > "$(doc_path "$TC05_R" "20260101_0000_a.md")" <<'DOC'
# doc

## Retrospective

### Insight 1: a
DOC
TC05_CONF="$TMPDIR_FIX/tc05.tsv"
{
  printf '# comment line\n'
  printf '\n'
  printf 'R1\t%s\n' "$TC05_R"
  printf '\n'
} > "$TC05_CONF"
run_cmd summary "$TC05_CONF"
TC05_STATS=$(awk '$1=="STAT" {n++} END {print n+0}' <<<"$RUN_OUT")
if [ "$RUN_RC" = "0" ] && [ "$TC05_STATS" = "2" ] \
   && hasre "$RUN_OUT" '^GRAMMAR version=v2 generated=[0-9]{4}-[0-9]{2}-[0-9]{2} labels=1 files_scanned=1$'; then
  pass "TC-05: comment/blank lines ignored (labels=1)"
else
  fail "TC-05: expected 1 label + TOTAL only (stat_lines=$TC05_STATS rc=$RUN_RC)"
fi

echo ""
echo "TC-06: empty docs/cycles -> header only, exit 0"
TC06_R=$(mk_repo tc06)
TC06_CONF=$(mk_conf tc06 R1 "$TC06_R")
run_cmd ledger "$TC06_CONF"
TC06_HDR=$(awk 'NR==1' <<<"$RUN_OUT")
if [ "$RUN_RC" = "0" ] && [ "$TC06_HDR" = "$LEDGER_HEADER" ] && [ "$(nrows "$RUN_OUT")" = "0" ]; then
  pass "TC-06: empty repo -> header only, exit 0"
else
  fail "TC-06: expected 10-column header and 0 data rows (rc=$RUN_RC)"
fi

echo ""
echo "TC-07: missing docs/cycles is warned and skipped, other labels survive"
TC07_BAD="$TMPDIR_FIX/tc07bad"
mkdir -p "$TC07_BAD"
TC07_OK=$(mk_repo tc07ok)
cat > "$(doc_path "$TC07_OK" "20260101_0000_a.md")" <<'DOC'
# doc

## Retrospective

### Insight 1: a
DOC
TC07_CONF=$(mk_conf tc07 R1 "$TC07_BAD" R2 "$TC07_OK")
run_cmd ledger "$TC07_CONF"
# Both sides of the contract: the broken label warns by name, and the healthy
# label draws no warning of its own.
if [ "$RUN_RC" = "0" ] && has "$RUN_ERR" 'warn: label=R1' \
   && ! has "$RUN_ERR" 'warn: label=R2' \
   && [ "$(nrows "$RUN_OUT")" = "1" ] && [ "$(lfield "$RUN_OUT" 1 1)" = "R2" ]; then
  pass "TC-07: missing docs/cycles warned by label, healthy label silent and emitted"
else
  fail "TC-07: expected exit 0 + 'warn: label=R1' only + R2 row (rc=$RUN_RC)"
fi

# ---------------------------------------------------------------------------
# Region boundaries (do not over-count)
# ---------------------------------------------------------------------------

echo ""
echo "TC-08: docs without ## Retrospective contribute nothing (with positive control)"
TC08_R=$(mk_repo tc08)
cat > "$(doc_path "$TC08_R" "20260101_0000_a.md")" <<'DOC'
# doc

## Progress Log

### 2026-01-01 00:00 - RED
- something
DOC
# Positive control: without a doc that must be counted, "0 rows" is also what a
# file set that was never read produces.
cat > "$(doc_path "$TC08_R" "20260101_0100_b.md")" <<'DOC'
# control doc

## Retrospective

### Insight 1: counted
DOC
TC08_CONF=$(mk_conf tc08 R1 "$TC08_R")
run_cmd ledger "$TC08_CONF"
TC08_ROWS=$(nrows "$RUN_OUT")
TC08_DOC1=$(lfield "$RUN_OUT" 1 2)
run_cmd summary "$TC08_CONF"
TC08_DOCS=$(sval "$RUN_OUT" R1 docs_with_retro)
if [ "$TC08_ROWS" = "1" ] && [ "$TC08_DOC1" = "20260101_0100_b.md" ] && [ "$TC08_DOCS" = "1" ]; then
  pass "TC-08: doc without a Retrospective contributes nothing, control doc counted"
else
  fail "TC-08: expected 1 row from the control doc / docs_with_retro=1 (rows=$TC08_ROWS doc=$TC08_DOC1 docs=$TC08_DOCS)"
fi

echo ""
echo "TC-09: ## Retrospective Notes is not a region (exact match, with positive control)"
TC09_R=$(mk_repo tc09)
cat > "$(doc_path "$TC09_R" "20260101_0000_a.md")" <<'DOC'
# doc

## Retrospective Notes

### Insight 1: a
DOC
# Positive control, as in TC-08: the exact-match contract must reject the padded
# heading while a real region in the same file set still lands.
cat > "$(doc_path "$TC09_R" "20260101_0100_b.md")" <<'DOC'
# control doc

## Retrospective

### Insight 1: counted
DOC
TC09_CONF=$(mk_conf tc09 R1 "$TC09_R")
run_cmd ledger "$TC09_CONF"
TC09_ROWS=$(nrows "$RUN_OUT")
TC09_DOC1=$(lfield "$RUN_OUT" 1 2)
run_cmd summary "$TC09_CONF"
TC09_DOCS=$(sval "$RUN_OUT" R1 docs_with_retro)
if [ "$TC09_ROWS" = "1" ] && [ "$TC09_DOC1" = "20260101_0100_b.md" ] && [ "$TC09_DOCS" = "1" ]; then
  pass "TC-09: '## Retrospective Notes' does not open a region, control doc counted"
else
  fail "TC-09: expected 1 row from the control doc / docs_with_retro=1 (rows=$TC09_ROWS doc=$TC09_DOC1 docs=$TC09_DOCS)"
fi

echo ""
echo "TC-10: identical Insight headings under Codify Decisions are not counted"
TC10_R=$(mk_repo tc10)
cat > "$(doc_path "$TC10_R" "20260101_0000_a.md")" <<'DOC'
# doc

## Retrospective

### Insight 1: a
### Insight 2: b
### Insight 3: c

## Codify Decisions

### Insight 1: a
### Insight 2: b
### Insight 3: c
DOC
TC10_CONF=$(mk_conf tc10 R1 "$TC10_R")
run_cmd ledger "$TC10_CONF"
if [ "$(nrows "$RUN_OUT")" = "3" ]; then
  pass "TC-10: Codify Decisions duplicates excluded (3 rows)"
else
  fail "TC-10: expected 3 rows, got $(nrows "$RUN_OUT")"
fi

echo ""
echo "TC-11: Insight heading under ## Progress Log is not a unit"
TC11_R=$(mk_repo tc11)
cat > "$(doc_path "$TC11_R" "20260101_0000_a.md")" <<'DOC'
# doc

## Retrospective

### Insight 1: a

## Progress Log

### Insight 1: b
DOC
TC11_CONF=$(mk_conf tc11 R1 "$TC11_R")
run_cmd ledger "$TC11_CONF"
if [ "$(nrows "$RUN_OUT")" = "1" ]; then
  pass "TC-11: Progress Log Insight excluded (1 row)"
else
  fail "TC-11: expected 1 row, got $(nrows "$RUN_OUT")"
fi

echo ""
echo "TC-12: ### 想起漏れ is not a unit"
TC12_R=$(mk_repo tc12)
cat > "$(doc_path "$TC12_R" "20260101_0000_a.md")" <<'DOC'
# doc

## Retrospective

### 想起漏れ
- missed recall note

### Insight 1: a
DOC
TC12_CONF=$(mk_conf tc12 R1 "$TC12_R")
run_cmd ledger "$TC12_CONF"
if [ "$(nrows "$RUN_OUT")" = "1" ] && [ "$(lfield "$RUN_OUT" 1 5)" = "insight" ]; then
  pass "TC-12: 想起漏れ excluded (1 insight row)"
else
  fail "TC-12: expected 1 insight row, got $(nrows "$RUN_OUT")"
fi

echo ""
echo "TC-13: Progress Log style date heading inside a region is not a unit"
TC13_R=$(mk_repo tc13)
cat > "$(doc_path "$TC13_R" "20260101_0000_a.md")" <<'DOC'
# doc

## Retrospective

### 2026-09-10 12:00 - COMMIT
- committed

### Insight 1: a
DOC
TC13_CONF=$(mk_conf tc13 R1 "$TC13_R")
run_cmd ledger "$TC13_CONF"
if [ "$(nrows "$RUN_OUT")" = "1" ] && [ "$(lfield "$RUN_OUT" 1 5)" = "insight" ]; then
  pass "TC-13: date heading excluded (1 insight row)"
else
  fail "TC-13: expected 1 insight row, got $(nrows "$RUN_OUT")"
fi

echo ""
echo "TC-14: Failure pattern with Final fix / Reusable lesson sub-headings -> 1 unit"
TC14_R=$(mk_repo tc14)
cat > "$(doc_path "$TC14_R" "20260101_0000_a.md")" <<'DOC'
# doc

## Retrospective

### Failure pattern 1: wrong assumption
#### Final fix
- corrected
#### Reusable lesson
- measure first
DOC
TC14_CONF=$(mk_conf tc14 R1 "$TC14_R")
run_cmd ledger "$TC14_CONF"
if [ "$(nrows "$RUN_OUT")" = "1" ] && [ "$(lfield "$RUN_OUT" 1 5)" = "failure-pattern" ]; then
  pass "TC-14: failure-pattern counted once"
else
  fail "TC-14: expected 1 failure-pattern row, got $(nrows "$RUN_OUT")/$(lfield "$RUN_OUT" 1 5)"
fi

echo ""
echo "TC-15: numbered sub-items under a unit heading do not become numbered-item"
TC15_R=$(mk_repo tc15)
cat > "$(doc_path "$TC15_R" "20260101_0000_a.md")" <<'DOC'
# doc

## Retrospective

### Insight 1: a
#### 1. first detail
#### 2. second detail
DOC
TC15_CONF=$(mk_conf tc15 R1 "$TC15_R")
run_cmd ledger "$TC15_CONF"
if [ "$(nrows "$RUN_OUT")" = "1" ] && [ "$(lfield "$RUN_OUT" 1 5)" = "insight" ]; then
  pass "TC-15: unit heading does not open a numbered-item container"
else
  fail "TC-15: expected 1 insight row, got $(nrows "$RUN_OUT")"
fi

echo ""
echo "TC-16: ### Insights / ### Insightful are not units"
TC16_R=$(mk_repo tc16)
cat > "$(doc_path "$TC16_R" "20260101_0000_a.md")" <<'DOC'
# doc

## Retrospective

### Insights
- a

### Insightful
- b
DOC
TC16_CONF=$(mk_conf tc16 R1 "$TC16_R")
run_cmd ledger "$TC16_CONF"
TC16_ROWS=$(nrows "$RUN_OUT")
run_cmd summary "$TC16_CONF"
TC16_DOCS=$(sval "$RUN_OUT" R1 docs_with_retro)
# docs_with_retro pins that the region really was parsed: "0 rows" on its own
# also holds when nothing was read at all, which makes the assertion vacuous.
if [ "$TC16_ROWS" = "0" ] && [ "$TC16_DOCS" = "1" ]; then
  pass "TC-16: word-boundary respected (0 rows, region seen)"
else
  fail "TC-16: expected 0 rows + docs_with_retro=1 (rows=$TC16_ROWS docs=$TC16_DOCS)"
fi

echo ""
echo "TC-17: a code fence both opens and closes (fenced ignored, following counted)"
TC17_R=$(mk_repo tc17)
cat > "$(doc_path "$TC17_R" "20260101_0000_a.md")" <<'DOC'
# doc

## Retrospective

```
### Insight 1: a
```

### Insight 2: b
DOC
TC17_CONF=$(mk_conf tc17 R1 "$TC17_R")
run_cmd ledger "$TC17_CONF"
TC17_ROWS=$(nrows "$RUN_OUT")
TC17_HEAD=$(lfield "$RUN_OUT" 1 10)
run_cmd summary "$TC17_CONF"
TC17_DOCS=$(sval "$RUN_OUT" R1 docs_with_retro)
# The marker after the closing fence is the half that a stuck-open fence loses:
# without it, a toggle that never closes still passes.
if [ "$TC17_ROWS" = "1" ] && [ "$TC17_HEAD" = "Insight 2: b" ] && [ "$TC17_DOCS" = "1" ]; then
  pass "TC-17: fenced marker ignored, marker after the closing fence counted"
else
  fail "TC-17: expected 1 row 'Insight 2: b' (rows=$TC17_ROWS head='$TC17_HEAD' docs=$TC17_DOCS)"
fi

echo ""
echo "TC-18: docs/cycles/archive/ is out of the file set"
TC18_R=$(mk_repo tc18)
cat > "$(doc_path "$TC18_R" "20260101_0000_a.md" archive)" <<'DOC'
# archived doc

## Retrospective

### Insight 1: a
DOC
# Positive control: the live doc proves the depth limit excluded archive/ rather
# than the whole file set failing to be read.
cat > "$(doc_path "$TC18_R" "20260101_0100_b.md")" <<'DOC'
# live doc

## Retrospective

### Insight 1: counted
DOC
TC18_CONF=$(mk_conf tc18 R1 "$TC18_R")
run_cmd ledger "$TC18_CONF"
TC18_ROWS=$(nrows "$RUN_OUT")
TC18_DOC1=$(lfield "$RUN_OUT" 1 2)
run_cmd summary "$TC18_CONF"
TC18_DOCS=$(sval "$RUN_OUT" R1 docs_with_retro)
if [ "$TC18_ROWS" = "1" ] && [ "$TC18_DOC1" = "20260101_0100_b.md" ] && [ "$TC18_DOCS" = "1" ]; then
  pass "TC-18: archive/ excluded, live doc counted"
else
  fail "TC-18: expected 1 row from the live doc / docs_with_retro=1 (rows=$TC18_ROWS doc=$TC18_DOC1 docs=$TC18_DOCS)"
fi

echo ""
echo "TC-19: region state resets at the file boundary"
TC19_R=$(mk_repo tc19)
cat > "$(doc_path "$TC19_R" "20260101_0000_a.md")" <<'DOC'
# doc a

## Retrospective

### Insight 1: a
DOC
cat > "$(doc_path "$TC19_R" "20260101_0100_b.md")" <<'DOC'
### Insight 1: b
DOC
TC19_CONF=$(mk_conf tc19 R1 "$TC19_R")
run_cmd ledger "$TC19_CONF"
if [ "$(nrows "$RUN_OUT")" = "1" ] && [ "$(lfield "$RUN_OUT" 1 2)" = "20260101_0000_a.md" ]; then
  pass "TC-19: region does not bleed into the next file"
else
  fail "TC-19: expected 1 row from doc a, got $(nrows "$RUN_OUT")"
fi

# ---------------------------------------------------------------------------
# Forms (do not under-count)
# ---------------------------------------------------------------------------

echo ""
echo "TC-20: ### Insight 1..3 -> 3 insight rows"
TC20_R=$(mk_repo tc20)
cat > "$(doc_path "$TC20_R" "20260101_0000_a.md")" <<'DOC'
# doc

## Retrospective

### Insight 1: a
### Insight 2: b
### Insight 3: c
DOC
TC20_CONF=$(mk_conf tc20 R1 "$TC20_R")
run_cmd ledger "$TC20_CONF"
TC20_OK=true
[ "$(nrows "$RUN_OUT")" = "3" ] || TC20_OK=false
for i in 1 2 3; do
  [ "$(lfield "$RUN_OUT" "$i" 5)" = "insight" ] || TC20_OK=false
done
if [ "$TC20_OK" = true ]; then
  pass "TC-20: 3 insight rows"
else
  fail "TC-20: expected 3 rows all form=insight, got $(nrows "$RUN_OUT")"
fi

echo ""
echo "TC-21: ### Failure pattern without a number -> failure-pattern"
TC21_R=$(mk_repo tc21)
cat > "$(doc_path "$TC21_R" "20260101_0000_a.md")" <<'DOC'
# doc

## Retrospective

### Failure pattern
- unnumbered
DOC
TC21_CONF=$(mk_conf tc21 R1 "$TC21_R")
run_cmd ledger "$TC21_CONF"
if [ "$(nrows "$RUN_OUT")" = "1" ] && [ "$(lfield "$RUN_OUT" 1 5)" = "failure-pattern" ]; then
  pass "TC-21: unnumbered failure pattern counted"
else
  fail "TC-21: expected 1 failure-pattern row, got $(nrows "$RUN_OUT")/$(lfield "$RUN_OUT" 1 5)"
fi

echo ""
echo "TC-22: ### Retrospective 追記 -> addendum-pair"
TC22_R=$(mk_repo tc22)
cat > "$(doc_path "$TC22_R" "20260101_0000_a.md")" <<'DOC'
# doc

## Retrospective

### Retrospective 追記（2026-01-01）: 後日談
- detail
DOC
TC22_CONF=$(mk_conf tc22 R1 "$TC22_R")
run_cmd ledger "$TC22_CONF"
if [ "$(nrows "$RUN_OUT")" = "1" ] && [ "$(lfield "$RUN_OUT" 1 5)" = "addendum-pair" ]; then
  pass "TC-22: addendum-pair counted"
else
  fail "TC-22: expected 1 addendum-pair row, got $(nrows "$RUN_OUT")/$(lfield "$RUN_OUT" 1 5)"
fi

echo ""
echo "TC-23: #### N. under a Failure container -> numbered-item"
TC23_R=$(mk_repo tc23)
cat > "$(doc_path "$TC23_R" "20260101_0000_a.md")" <<'DOC'
# doc

## Retrospective

### Failure → Fix → Insight

#### 1. first pair
- detail

#### 2. second pair
- detail
DOC
TC23_CONF=$(mk_conf tc23 R1 "$TC23_R")
run_cmd ledger "$TC23_CONF"
TC23_OK=true
[ "$(nrows "$RUN_OUT")" = "2" ] || TC23_OK=false
for i in 1 2; do
  [ "$(lfield "$RUN_OUT" "$i" 5)" = "numbered-item" ] || TC23_OK=false
  # The marker lines carry no keyword of their own: the polarity can only come
  # from the enclosing container, which is the sole source for this whole form.
  [ "$(lfield "$RUN_OUT" "$i" 9)" = "explicit_failure" ] || TC23_OK=false
done
run_cmd summary "$TC23_CONF"
# A mapped section that produced units still reports its heading as one excluded
# observation. That is the grammar v2 rule the corpus was validated against, so
# the row is pinned rather than left to drift.
has "$RUN_OUT" "SKIP label=R1 kind=sub-field container=Failure → Fix → Insight count=1" || TC23_OK=false
if [ "$TC23_OK" = true ]; then
  pass "TC-23: 2 numbered-item rows, container-derived explicit_failure, SKIP count=1"
else
  fail "TC-23: expected 2 numbered-item/explicit_failure rows + sub-field SKIP count=1"
fi

echo ""
echo "TC-24: **Pair N: X** -> pair"
TC24_R=$(mk_repo tc24)
cat > "$(doc_path "$TC24_R" "20260101_0000_a.md")" <<'DOC'
# doc

## Retrospective

**Pair 1: X**
- detail
DOC
TC24_CONF=$(mk_conf tc24 R1 "$TC24_R")
run_cmd ledger "$TC24_CONF"
# The heading column pins that the bold delimiters are stripped: a no-op strip()
# would leave them in place.
if [ "$(nrows "$RUN_OUT")" = "1" ] && [ "$(lfield "$RUN_OUT" 1 5)" = "pair" ] \
   && [ "$(lfield "$RUN_OUT" 1 10)" = "Pair 1: X" ]; then
  pass "TC-24: bold pair counted, ** stripped from the heading"
else
  fail "TC-24: expected 1 pair row heading 'Pair 1: X', got '$(lfield "$RUN_OUT" 1 10)'"
fi

echo ""
echo "TC-25: - Pair N (...) -> pair-bullet"
TC25_R=$(mk_repo tc25)
cat > "$(doc_path "$TC25_R" "20260101_0000_a.md")" <<'DOC'
# doc

## Retrospective

- Pair 1 (high): X
DOC
TC25_CONF=$(mk_conf tc25 R1 "$TC25_R")
run_cmd ledger "$TC25_CONF"
if [ "$(nrows "$RUN_OUT")" = "1" ] && [ "$(lfield "$RUN_OUT" 1 5)" = "pair-bullet" ] \
   && [ "$(lfield "$RUN_OUT" 1 10)" = "Pair 1 (high): X" ]; then
  pass "TC-25: bullet pair counted, '- ' stripped from the heading"
else
  fail "TC-25: expected 1 pair-bullet row heading 'Pair 1 (high): X', got '$(lfield "$RUN_OUT" 1 10)'"
fi

echo ""
echo "TC-26: - 最初の失敗 -> prose-pair"
TC26_R=$(mk_repo tc26)
cat > "$(doc_path "$TC26_R" "20260101_0000_a.md")" <<'DOC'
# doc

## Retrospective

**失敗→成功ペア**:

- 最初の失敗: X
- 最終解: Y
DOC
TC26_CONF=$(mk_conf tc26 R1 "$TC26_R")
run_cmd ledger "$TC26_CONF"
if [ "$(nrows "$RUN_OUT")" = "1" ] && [ "$(lfield "$RUN_OUT" 1 5)" = "prose-pair" ]; then
  pass "TC-26: prose pair counted"
else
  fail "TC-26: expected 1 prose-pair row, got $(nrows "$RUN_OUT")/$(lfield "$RUN_OUT" 1 5)"
fi

# ---------------------------------------------------------------------------
# Evaluation order and container semantics
# ---------------------------------------------------------------------------

echo ""
echo "TC-27: bold container rule must not consume a bold pair marker"
TC27_R=$(mk_repo tc27)
cat > "$(doc_path "$TC27_R" "20260101_0000_a.md")" <<'DOC'
# doc

## Retrospective

**Positive validations**:

- an observation

**Pair 1: X**
- detail
DOC
TC27_CONF=$(mk_conf tc27 R1 "$TC27_R")
run_cmd ledger "$TC27_CONF"
# Three contracts in one row: the bold-line container rule exists (column 6 holds
# the bold heading), the unit rules are evaluated first (form is still pair), and
# polarity can be derived from a bold container (column 9).
if [ "$(nrows "$RUN_OUT")" = "1" ] && [ "$(lfield "$RUN_OUT" 1 5)" = "pair" ] \
   && [ "$(lfield "$RUN_OUT" 1 6)" = '**Positive validations**:' ] \
   && [ "$(lfield "$RUN_OUT" 1 9)" = "explicit_positive" ]; then
  pass "TC-27: unit rules before the bold container rule, bold container recorded and polarising"
else
  fail "TC-27: expected pair row with bold container and explicit_positive (container='$(lfield "$RUN_OUT" 1 6)' polarity='$(lfield "$RUN_OUT" 1 9)')"
fi

echo ""
echo "TC-28: container is the enclosing non-unit heading, not the unit itself"
TC28_R=$(mk_repo tc28)
cat > "$(doc_path "$TC28_R" "20260101_0000_a.md")" <<'DOC'
# doc

## Retrospective

### この cycle で機能したもの

### Insight 1: x
DOC
TC28_CONF=$(mk_conf tc28 R1 "$TC28_R")
run_cmd ledger "$TC28_CONF"
if [ "$(nrows "$RUN_OUT")" = "1" ] && [ "$(lfield "$RUN_OUT" 1 6)" = "### この cycle で機能したもの" ]; then
  pass "TC-28: container column holds the enclosing heading"
else
  fail "TC-28: unexpected container column value"
fi

echo ""
echo "TC-29: no enclosing section -> container is '-'"
TC29_R=$(mk_repo tc29)
cat > "$(doc_path "$TC29_R" "20260101_0000_a.md")" <<'DOC'
# doc

## Retrospective

### Insight 1: x
DOC
TC29_CONF=$(mk_conf tc29 R1 "$TC29_R")
run_cmd ledger "$TC29_CONF"
if [ "$(nrows "$RUN_OUT")" = "1" ] && [ "$(lfield "$RUN_OUT" 1 6)" = "-" ]; then
  pass "TC-29: container defaults to '-'"
else
  fail "TC-29: expected container '-', got '$(lfield "$RUN_OUT" 1 6)'"
fi

# ---------------------------------------------------------------------------
# Polarity (3 values + precedence)
# ---------------------------------------------------------------------------

echo ""
echo "TC-30: (positive) on the marker line -> explicit_positive"
TC30_R=$(mk_repo tc30)
cat > "$(doc_path "$TC30_R" "20260101_0000_a.md")" <<'DOC'
# doc

## Retrospective

**Pair 2 (positive): Y**
- detail
DOC
TC30_CONF=$(mk_conf tc30 R1 "$TC30_R")
run_cmd ledger "$TC30_CONF"
if [ "$(lfield "$RUN_OUT" 1 9)" = "explicit_positive" ]; then
  pass "TC-30: (positive) marker -> explicit_positive"
else
  fail "TC-30: expected explicit_positive, got '$(lfield "$RUN_OUT" 1 9)'"
fi

echo ""
echo "TC-31: (Success) on the marker line -> explicit_positive"
TC31_R=$(mk_repo tc31)
cat > "$(doc_path "$TC31_R" "20260101_0000_a.md")" <<'DOC'
# doc

## Retrospective

### Insight 1: x (Success)
DOC
TC31_CONF=$(mk_conf tc31 R1 "$TC31_R")
run_cmd ledger "$TC31_CONF"
if [ "$(lfield "$RUN_OUT" 1 9)" = "explicit_positive" ]; then
  pass "TC-31: (Success) marker -> explicit_positive"
else
  fail "TC-31: expected explicit_positive, got '$(lfield "$RUN_OUT" 1 9)'"
fi

echo ""
echo "TC-32: full-width （Success） -> explicit_positive"
TC32_R=$(mk_repo tc32)
cat > "$(doc_path "$TC32_R" "20260101_0000_a.md")" <<'DOC'
# doc

## Retrospective

### Insight 1: x（Success）
DOC
TC32_CONF=$(mk_conf tc32 R1 "$TC32_R")
run_cmd ledger "$TC32_CONF"
if [ "$(lfield "$RUN_OUT" 1 9)" = "explicit_positive" ]; then
  pass "TC-32: full-width （Success） -> explicit_positive"
else
  fail "TC-32: expected explicit_positive, got '$(lfield "$RUN_OUT" 1 9)'"
fi

echo ""
echo "TC-33: positive container without a marker keyword -> explicit_positive"
TC33_R=$(mk_repo tc33)
cat > "$(doc_path "$TC33_R" "20260101_0000_a.md")" <<'DOC'
# doc

## Retrospective

### Positive validations

**Pair 6: Z**
- detail
DOC
TC33_CONF=$(mk_conf tc33 R1 "$TC33_R")
run_cmd ledger "$TC33_CONF"
TC33_POL=$(lfield "$RUN_OUT" 1 9)
run_cmd summary "$TC33_CONF"
# Same pinned rule as TC-23, on the standalone-positive kind.
if [ "$TC33_POL" = "explicit_positive" ] \
   && has "$RUN_OUT" "SKIP label=R1 kind=standalone-positive container=Positive validations count=1"; then
  pass "TC-33: positive container -> explicit_positive, SKIP count=1"
else
  fail "TC-33: expected explicit_positive + standalone-positive SKIP count=1 (polarity='$TC33_POL')"
fi

echo ""
echo "TC-34: positive marker wins over a failure container"
TC34_R=$(mk_repo tc34)
cat > "$(doc_path "$TC34_R" "20260101_0000_a.md")" <<'DOC'
# doc

## Retrospective

### Failure → Final fix pairs

**Pair 3 (positive): X**
- detail
DOC
TC34_CONF=$(mk_conf tc34 R1 "$TC34_R")
run_cmd ledger "$TC34_CONF"
if [ "$(lfield "$RUN_OUT" 1 9)" = "explicit_positive" ]; then
  pass "TC-34: positive takes precedence over failure"
else
  fail "TC-34: expected explicit_positive, got '$(lfield "$RUN_OUT" 1 9)'"
fi

echo ""
echo "TC-35: Failure keyword on the marker line -> explicit_failure"
TC35_R=$(mk_repo tc35)
cat > "$(doc_path "$TC35_R" "20260101_0000_a.md")" <<'DOC'
# doc

## Retrospective

### Failure pattern 1: x
DOC
TC35_CONF=$(mk_conf tc35 R1 "$TC35_R")
run_cmd ledger "$TC35_CONF"
if [ "$(lfield "$RUN_OUT" 1 9)" = "explicit_failure" ]; then
  pass "TC-35: Failure marker -> explicit_failure"
else
  fail "TC-35: expected explicit_failure, got '$(lfield "$RUN_OUT" 1 9)'"
fi

echo ""
echo "TC-36: 失敗 keyword on the marker line -> explicit_failure"
TC36_R=$(mk_repo tc36)
cat > "$(doc_path "$TC36_R" "20260101_0000_a.md")" <<'DOC'
# doc

## Retrospective

### Insight 1: 失敗した設定の扱い
DOC
TC36_CONF=$(mk_conf tc36 R1 "$TC36_R")
run_cmd ledger "$TC36_CONF"
if [ "$(lfield "$RUN_OUT" 1 9)" = "explicit_failure" ]; then
  pass "TC-36: 失敗 keyword -> explicit_failure"
else
  fail "TC-36: expected explicit_failure, got '$(lfield "$RUN_OUT" 1 9)'"
fi

echo ""
echo "TC-37: neither keyword present -> unknown (never guessed)"
TC37_R=$(mk_repo tc37)
cat > "$(doc_path "$TC37_R" "20260101_0000_a.md")" <<'DOC'
# doc

## Retrospective

### Insight 1: 設定値は定数へ集約する
DOC
TC37_CONF=$(mk_conf tc37 R1 "$TC37_R")
run_cmd ledger "$TC37_CONF"
if [ "$(lfield "$RUN_OUT" 1 9)" = "unknown" ]; then
  pass "TC-37: polarity left unknown"
else
  fail "TC-37: expected unknown, got '$(lfield "$RUN_OUT" 1 9)'"
fi

# ---------------------------------------------------------------------------
# Doc-level attributes and output format
# ---------------------------------------------------------------------------

echo ""
echo "TC-38: two regions in one doc -> docs=1, sections=2, units=4"
TC38_R=$(mk_repo tc38)
cat > "$(doc_path "$TC38_R" "20260101_0000_a.md")" <<'DOC'
# doc

## Retrospective

### Insight 1: a
### Insight 2: b

## Progress Log

- something

## Retrospective

### Insight 1: c
### Insight 2: d
DOC
TC38_CONF=$(mk_conf tc38 R1 "$TC38_R")
run_cmd summary "$TC38_CONF"
TC38_D=$(sval "$RUN_OUT" R1 docs_with_retro)
TC38_S=$(sval "$RUN_OUT" R1 retro_sections)
TC38_U=$(sval "$RUN_OUT" R1 units)
if [ "$TC38_D" = "1" ] && [ "$TC38_S" = "2" ] && [ "$TC38_U" = "4" ]; then
  pass "TC-38: docs=1 sections=2 units=4"
else
  fail "TC-38: got docs=$TC38_D sections=$TC38_S units=$TC38_U"
fi

echo ""
echo "TC-39: retro_status is read from frontmatter only"
TC39_R=$(mk_repo tc39)
# The decoy sits at the start of a body line, in the same shape the frontmatter
# uses: a whole-file scan would read it and report resolved.
cat > "$(doc_path "$TC39_R" "20260101_0000_a.md")" <<'DOC'
---
feature: x
retro_status: captured
---

# doc

## Retrospective

### Insight 1: a
retro_status: resolved
DOC
TC39_CONF=$(mk_conf tc39 R1 "$TC39_R")
run_cmd ledger "$TC39_CONF"
if [ "$(lfield "$RUN_OUT" 1 3)" = "captured" ]; then
  pass "TC-39: frontmatter retro_status wins over body mentions"
else
  fail "TC-39: expected captured, got '$(lfield "$RUN_OUT" 1 3)'"
fi

echo ""
echo "TC-40: absent retro_status -> '-'"
TC40_R=$(mk_repo tc40)
cat > "$(doc_path "$TC40_R" "20260101_0000_a.md")" <<'DOC'
---
feature: x
phase: DONE
---

# doc

## Retrospective

### Insight 1: a
DOC
TC40_CONF=$(mk_conf tc40 R1 "$TC40_R")
run_cmd ledger "$TC40_CONF"
if [ "$(lfield "$RUN_OUT" 1 3)" = "-" ]; then
  pass "TC-40: missing retro_status -> '-'"
else
  fail "TC-40: expected '-', got '$(lfield "$RUN_OUT" 1 3)'"
fi

echo ""
echo "TC-41: has_codify reflects the presence of ## Codify Decisions"
TC41_R=$(mk_repo tc41)
cat > "$(doc_path "$TC41_R" "20260101_0000_a.md")" <<'DOC'
# doc a

## Retrospective

### Insight 1: a

## Codify Decisions

- codified
DOC
cat > "$(doc_path "$TC41_R" "20260101_0100_b.md")" <<'DOC'
# doc b

## Retrospective

### Insight 1: b
DOC
TC41_CONF=$(mk_conf tc41 R1 "$TC41_R")
run_cmd ledger "$TC41_CONF"
if [ "$(nrows "$RUN_OUT")" = "2" ] \
   && [ "$(lfield "$RUN_OUT" 1 4)" = "yes" ] && [ "$(lfield "$RUN_OUT" 2 4)" = "no" ]; then
  pass "TC-41: has_codify yes/no"
else
  fail "TC-41: expected yes then no, got '$(lfield "$RUN_OUT" 1 4)'/'$(lfield "$RUN_OUT" 2 4)'"
fi

echo ""
echo "TC-42: a tab inside a heading keeps the row at exactly 10 fields"
TC42_R=$(mk_repo tc42)
TC42_DOC=$(doc_path "$TC42_R" "20260101_0000_a.md")
{
  printf '# doc\n\n## Retrospective\n\n'
  printf '### Insight 1: a\tb\n'
} > "$TC42_DOC"
TC42_CONF=$(mk_conf tc42 R1 "$TC42_R")
run_cmd ledger "$TC42_CONF"
# The field count alone does not say what happened to the tab; the heading value
# pins that it became a space and that the '### ' prefix was removed.
if [ "$(nrows "$RUN_OUT")" = "1" ] && [ "$(lnf "$RUN_OUT" 1)" = "10" ] \
   && [ "$(lfield "$RUN_OUT" 1 10)" = "Insight 1: a b" ]; then
  pass "TC-42: embedded tab squashed to a space, 10 fields, prefix stripped"
else
  fail "TC-42: expected 10 fields and heading 'Insight 1: a b', got $(lnf "$RUN_OUT" 1)/'$(lfield "$RUN_OUT" 1 10)'"
fi

echo ""
echo "TC-43: unit_no is a parser sequence, not the heading number"
TC43_R=$(mk_repo tc43)
cat > "$(doc_path "$TC43_R" "20260101_0000_a.md")" <<'DOC'
# doc

## Retrospective

### Insight 3: a
### Insight 3: b
### Insight 7: c
DOC
TC43_CONF=$(mk_conf tc43 R1 "$TC43_R")
run_cmd ledger "$TC43_CONF"
TC43_OK=true
[ "$(nrows "$RUN_OUT")" = "3" ] || TC43_OK=false
[ "$(lfield "$RUN_OUT" 1 7)" = "1" ] || TC43_OK=false
[ "$(lfield "$RUN_OUT" 2 7)" = "2" ] || TC43_OK=false
[ "$(lfield "$RUN_OUT" 3 7)" = "3" ] || TC43_OK=false
if [ "$TC43_OK" = true ]; then
  pass "TC-43: unit_no renumbered 1..3"
else
  fail "TC-43: expected unit_no 1/2/3"
fi

echo ""
echo "TC-44: line column matches the source line number"
TC44_R=$(mk_repo tc44)
TC44_DOC=$(doc_path "$TC44_R" "20260101_0000_a.md")
cat > "$TC44_DOC" <<'DOC'
---
feature: x
---

# doc

## Retrospective

Some prose before the first unit.

### Insight 1: a
DOC
TC44_EXP=$(awk '/^### Insight 1/ {print NR; exit}' "$TC44_DOC")
TC44_CONF=$(mk_conf tc44 R1 "$TC44_R")
run_cmd ledger "$TC44_CONF"
if [ -n "$TC44_EXP" ] && [ "$(lfield "$RUN_OUT" 1 8)" = "$TC44_EXP" ]; then
  pass "TC-44: line column points back to the source"
else
  fail "TC-44: expected line=$TC44_EXP, got '$(lfield "$RUN_OUT" 1 8)'"
fi

echo ""
echo "TC-45: non-git fixture -> INPUT line with sha=- dirty=- and a 16 hex digest"
TC45_R=$(mk_repo tc45)
cat > "$(doc_path "$TC45_R" "20260101_0000_a.md")" <<'DOC'
# doc

## Retrospective

### Insight 1: a
DOC
TC45_CONF=$(mk_conf tc45 R1 "$TC45_R")
run_cmd summary "$TC45_CONF"
if [ "$RUN_RC" = "0" ] && hasre "$RUN_OUT" '^INPUT label=R1 sha=- dirty=- files=1 digest=[0-9a-f]{16}$'; then
  pass "TC-45: INPUT line format for a non-git input"
else
  fail "TC-45: INPUT line missing or malformed (rc=$RUN_RC)"
fi

echo ""
echo "TC-46: no fixture absolute path leaks into ledger or summary output"
TC46_R=$(mk_repo tc46)
cat > "$(doc_path "$TC46_R" "20260101_0000_a.md")" <<'DOC'
---
feature: x
retro_status: captured
---

# doc

## Retrospective

### Positive validations

**Pair 1: X**

### Insight 1: 設定値は定数へ集約する

## Codify Decisions

- codified
DOC
TC46_CONF=$(mk_conf tc46 R1 "$TC46_R")
run_cmd ledger "$TC46_CONF"
TC46_LED="$RUN_OUT"
run_cmd summary "$TC46_CONF"
TC46_HITS=$(nfixed "$TC46_LED
$RUN_OUT" "$TMPDIR_FIX")
# The row count pins that both outputs are non-empty: "0 path hits" is also
# true of an empty output, which makes the leak check vacuous.
TC46_ROWS=$(nrows "$TC46_LED")
if [ "$TC46_HITS" = "0" ] && [ "$TC46_ROWS" = "2" ]; then
  pass "TC-46: 0 absolute paths in non-empty output"
else
  fail "TC-46: expected 0 path hits over 2 ledger rows (hits=$TC46_HITS rows=$TC46_ROWS)"
fi

echo ""
echo "TC-47: retro section without units -> units=0 and a ZERO line"
TC47_R=$(mk_repo tc47)
cat > "$(doc_path "$TC47_R" "20260101_0000_a.md")" <<'DOC'
# doc

## Retrospective

No reusable lesson this cycle
DOC
TC47_CONF=$(mk_conf tc47 R1 "$TC47_R")
run_cmd summary "$TC47_CONF"
TC47_U=$(sval "$RUN_OUT" R1 units)
if [ "$TC47_U" = "0" ] && has "$RUN_OUT" "ZERO label=R1 doc=20260101_0000_a.md"; then
  pass "TC-47: zero-unit doc enumerated"
else
  fail "TC-47: expected units=0 and a ZERO line (units=$TC47_U)"
fi

echo ""
echo "TC-48: STAT form / polarity / doc counts match hand-computed fixture values"
TC48_A=$(mk_repo tc48a)
cat > "$(doc_path "$TC48_A" "20260101_0000_a.md")" <<'DOC'
# doc

## Retrospective

### Insight 1: a
### Insight 2: b
DOC
cat > "$(doc_path "$TC48_A" "20260101_0100_b.md")" <<'DOC'
# doc

## Retrospective

No reusable lesson this cycle
DOC
TC48_B=$(mk_repo tc48b)
cat > "$(doc_path "$TC48_B" "20260101_0000_a.md")" <<'DOC'
# doc

## Retrospective

**Pair 1: X**
- Pair 2 (high): Y
### Failure pattern 1: z
### Insight 3: c (positive)
DOC
TC48_CONF=$(mk_conf tc48 R1 "$TC48_A" R2 "$TC48_B")
run_cmd ledger "$TC48_CONF"
TC48_LED="$RUN_OUT"
TC48_ROWS=$(nrows "$TC48_LED")
run_cmd summary "$TC48_CONF"
TC48_OK=true
# Hand-computed from the fixture: 3 insight (2 in R1 + 1 in R2), 1 failure-pattern,
# 1 pair, 1 pair-bullet; polarity 1 failure (Failure on the marker line), 1
# positive ((positive) on the marker line), 4 unknown; 3 docs carry a region, 2
# of them carry units, 1 is zero-unit. A totals-only assertion passes even when
# every unit is misclassified into one bucket.
[ "$TC48_ROWS" = "6" ]                                  || TC48_OK=false
[ "$(sval "$RUN_OUT" TOTAL units)" = "6" ]              || TC48_OK=false
[ "$(sval "$RUN_OUT" TOTAL insight)" = "3" ]            || TC48_OK=false
[ "$(sval "$RUN_OUT" TOTAL failure-pattern)" = "1" ]    || TC48_OK=false
[ "$(sval "$RUN_OUT" TOTAL addendum-pair)" = "0" ]      || TC48_OK=false
[ "$(sval "$RUN_OUT" TOTAL pair)" = "1" ]               || TC48_OK=false
[ "$(sval "$RUN_OUT" TOTAL pair-bullet)" = "1" ]        || TC48_OK=false
[ "$(sval "$RUN_OUT" TOTAL prose-pair)" = "0" ]         || TC48_OK=false
[ "$(sval "$RUN_OUT" TOTAL numbered-item)" = "0" ]      || TC48_OK=false
[ "$(sval "$RUN_OUT" TOTAL explicit_failure)" = "1" ]   || TC48_OK=false
[ "$(sval "$RUN_OUT" TOTAL explicit_positive)" = "1" ]  || TC48_OK=false
[ "$(sval "$RUN_OUT" TOTAL unknown)" = "4" ]            || TC48_OK=false
[ "$(sval "$RUN_OUT" TOTAL docs_with_retro)" = "3" ]    || TC48_OK=false
[ "$(sval "$RUN_OUT" TOTAL docs_with_units)" = "2" ]    || TC48_OK=false
[ "$(sval "$RUN_OUT" TOTAL zero_unit)" = "1" ]          || TC48_OK=false
# Cross-check each STAT count against the ledger column it summarises: a shifted
# column inside the record layout moves a value without changing any total.
for TC48_F in insight failure-pattern addendum-pair pair pair-bullet prose-pair numbered-item; do
  TC48_N=$(awk -F'\t' -v f="$TC48_F" 'NR>1 && NF>0 && $5==f {c++} END {print c+0}' <<<"$TC48_LED")
  [ "$(sval "$RUN_OUT" TOTAL "$TC48_F")" = "$TC48_N" ] || TC48_OK=false
done
for TC48_P in explicit_failure explicit_positive unknown; do
  TC48_N=$(awk -F'\t' -v q="$TC48_P" 'NR>1 && NF>0 && $9==q {c++} END {print c+0}' <<<"$TC48_LED")
  [ "$(sval "$RUN_OUT" TOTAL "$TC48_P")" = "$TC48_N" ] || TC48_OK=false
done
if [ "$TC48_OK" = true ]; then
  pass "TC-48: form/polarity/doc distribution matches the fixture and the ledger"
else
  fail "TC-48: STAT distribution mismatch (rows=$TC48_ROWS units=$(sval "$RUN_OUT" TOTAL units) insight=$(sval "$RUN_OUT" TOTAL insight) unknown=$(sval "$RUN_OUT" TOTAL unknown))"
fi

echo ""
echo "TC-49: STAT line is a fixed key order, single-space separated"
TC49_R=$(mk_repo tc49)
cat > "$(doc_path "$TC49_R" "20260101_0000_a.md")" <<'DOC'
# doc

## Retrospective

### Insight 1: a
DOC
TC49_CONF=$(mk_conf tc49 R1 "$TC49_R")
run_cmd summary "$TC49_CONF"
TC49_RE='^STAT label=R1 docs_with_retro=[0-9]+ retro_sections=[0-9]+ docs_with_units=[0-9]+ units=[0-9]+ insight=[0-9]+ failure-pattern=[0-9]+ addendum-pair=[0-9]+ pair=[0-9]+ pair-bullet=[0-9]+ prose-pair=[0-9]+ numbered-item=[0-9]+ explicit_failure=[0-9]+ explicit_positive=[0-9]+ unknown=[0-9]+ zero_unit=[0-9]+$'
if hasre "$RUN_OUT" "$TC49_RE"; then
  pass "TC-49: STAT key order fixed"
else
  fail "TC-49: STAT line does not match the frozen key order"
fi

# ---------------------------------------------------------------------------
# SKIP lines (exclusions are never silent)
# ---------------------------------------------------------------------------

echo ""
echo "TC-50: standalone-positive bullet next to a real unit"
TC50_R=$(mk_repo tc50)
cat > "$(doc_path "$TC50_R" "20260101_0000_a.md")" <<'DOC'
# doc

## Retrospective

### Positive validations

**Pair 1: X**

- **観察 A**: y
DOC
TC50_CONF=$(mk_conf tc50 R1 "$TC50_R")
run_cmd ledger "$TC50_CONF"
TC50_ROWS=$(nrows "$RUN_OUT")
run_cmd summary "$TC50_CONF"
if [ "$TC50_ROWS" = "1" ] \
   && has "$RUN_OUT" "SKIP label=R1 kind=standalone-positive container=Positive validations count=1"; then
  pass "TC-50: 1 unit + standalone-positive SKIP count=1"
else
  fail "TC-50: expected 1 row and a standalone-positive SKIP (rows=$TC50_ROWS)"
fi

echo ""
echo "TC-51: derivative enumeration -> 0 units, SKIP count=2"
TC51_R=$(mk_repo tc51)
cat > "$(doc_path "$TC51_R" "20260101_0000_a.md")" <<'DOC'
# doc

## Retrospective

### 事前知識化候補

1. **x**: a
2. **y**: b
DOC
TC51_CONF=$(mk_conf tc51 R1 "$TC51_R")
run_cmd ledger "$TC51_CONF"
TC51_ROWS=$(nrows "$RUN_OUT")
run_cmd summary "$TC51_CONF"
if [ "$TC51_ROWS" = "0" ] && hasre "$RUN_OUT" '^SKIP label=R1 kind=derivative container=.+ count=2$'; then
  pass "TC-51: derivative SKIP count=2"
else
  fail "TC-51: expected 0 rows and a derivative SKIP count=2 (rows=$TC51_ROWS)"
fi

echo ""
echo "TC-52: sub-field bullets under a pair -> 1 unit, SKIP count=2"
TC52_R=$(mk_repo tc52)
cat > "$(doc_path "$TC52_R" "20260101_0000_a.md")" <<'DOC'
# doc

## Retrospective

### Failure → Final fix pairs

**Pair 1: X**
- **失敗**: a
- **解決**: b
DOC
TC52_CONF=$(mk_conf tc52 R1 "$TC52_R")
run_cmd ledger "$TC52_CONF"
TC52_ROWS=$(nrows "$RUN_OUT")
run_cmd summary "$TC52_CONF"
if [ "$TC52_ROWS" = "1" ] && hasre "$RUN_OUT" '^SKIP label=R1 kind=sub-field container=.+ count=2$'; then
  pass "TC-52: sub-field SKIP count=2"
else
  fail "TC-52: expected 1 row and a sub-field SKIP count=2 (rows=$TC52_ROWS)"
fi

echo ""
echo "TC-53: heading-form standalone-positive -> 0 units, SKIP count=1"
TC53_R=$(mk_repo tc53)
cat > "$(doc_path "$TC53_R" "20260101_0000_a.md")" <<'DOC'
# doc

## Retrospective

### 成功事例（observation）: x
DOC
TC53_CONF=$(mk_conf tc53 R1 "$TC53_R")
run_cmd ledger "$TC53_CONF"
TC53_ROWS=$(nrows "$RUN_OUT")
run_cmd summary "$TC53_CONF"
if [ "$TC53_ROWS" = "0" ] \
   && has "$RUN_OUT" "SKIP label=R1 kind=standalone-positive container=成功事例 count=1"; then
  pass "TC-53: heading-form standalone-positive SKIP count=1"
else
  fail "TC-53: expected 0 rows and a standalone-positive SKIP (rows=$TC53_ROWS)"
fi

echo ""
echo "TC-54: every SKIP mapping is emitted with its own kind and count"
TC54_R=$(mk_repo tc54)
cat > "$(doc_path "$TC54_R" "20260101_0000_a.md")" <<'DOC'
# doc

## Retrospective

### Failure → Final fix pairs

- **失敗**: a
- **解決**: b

### Failure → Fix → Insight

- **x**: 1
- **y**: 2
- **z**: 3

### 事前知識化候補

1. **k**: a

### Reusable lessons

- **l1**: a
- **l2**: b
- **l3**: c
- **l4**: d

### Positive validations

- **p1**: a
- **p2**: b
- **p3**: c
- **p4**: d
- **p5**: e

### この cycle で機能したもの

- **m1**: a
- **m2**: b
- **m3**: c
- **m4**: d
- **m5**: e
- **m6**: f

### 成功事例

- **s1**: a
- **s2**: b
- **s3**: c
- **s4**: d
- **s5**: e
- **s6**: f
- **s7**: g
DOC
TC54_CONF=$(mk_conf tc54 R1 "$TC54_R")
run_cmd ledger "$TC54_CONF"
TC54_ROWS=$(nrows "$RUN_OUT")
run_cmd summary "$TC54_CONF"
TC54_OK=true
TC54_MISS=""
# Each mapping carries a distinct entry count, so a mapping wired to the wrong
# kind or dropped altogether shows up as a wrong number rather than as a line
# that merely moved. Presence-only assertions let three of these be deleted.
while IFS='|' read -r TC54_K TC54_C TC54_N; do
  [ -n "$TC54_K" ] || continue
  if ! has "$RUN_OUT" "SKIP label=R1 kind=$TC54_K container=$TC54_C count=$TC54_N"; then
    TC54_OK=false
    TC54_MISS="$TC54_MISS [$TC54_K/$TC54_C/$TC54_N]"
  fi
done <<'MAP'
sub-field|Failure → Final fix pairs|2
sub-field|Failure → Fix → Insight|3
derivative|事前知識化候補|1
derivative|Reusable lessons|4
standalone-positive|Positive validations|5
standalone-positive|この cycle で機能したもの|6
standalone-positive|成功事例|7
MAP
# The total pins the other direction: no mapping may quietly appear twice or a
# spurious eighth row show up.
TC54_LINES=$(awk '$1=="SKIP" {c++} END {print c+0}' <<<"$RUN_OUT")
[ "$TC54_LINES" = "7" ] || TC54_OK=false
[ "$TC54_ROWS" = "0" ] || TC54_OK=false
if [ "$TC54_OK" = true ]; then
  pass "TC-54: 7 SKIP mappings pinned by count, exactly 7 SKIP lines, 0 units"
else
  fail "TC-54: SKIP mapping mismatch (lines=$TC54_LINES rows=$TC54_ROWS missing:$TC54_MISS)"
fi

echo ""
echo "TC-55: SKIP rows aggregate per container and are absent without a mapping"
TC55_A=$(mk_repo tc55a)
cat > "$(doc_path "$TC55_A" "20260101_0000_a.md")" <<'DOC'
# doc a

## Retrospective

### Positive validations

- **p1**: a
- **p2**: b
DOC
cat > "$(doc_path "$TC55_A" "20260101_0100_b.md")" <<'DOC'
# doc b

## Retrospective

### Positive validations

- **p3**: c
DOC
TC55_B=$(mk_repo tc55b)
cat > "$(doc_path "$TC55_B" "20260101_0000_a.md")" <<'DOC'
# doc

## Retrospective

### 通常の観察

### Insight 1: a
DOC
TC55_CONF=$(mk_conf tc55 R1 "$TC55_A" R2 "$TC55_B")
run_cmd summary "$TC55_CONF"
TC55_LINES=$(awk '$1=="SKIP" {c++} END {print c+0}' <<<"$RUN_OUT")
TC55_R2=$(awk '$1=="SKIP" && $2=="label=R2" {c++} END {print c+0}' <<<"$RUN_OUT")
# One row per (label, kind, container) with the counts summed, and a section
# outside the mapping contributes no row at all.
if [ "$TC55_LINES" = "1" ] \
   && has "$RUN_OUT" "SKIP label=R1 kind=standalone-positive container=Positive validations count=3" \
   && [ "$TC55_R2" = "0" ]; then
  pass "TC-55: two docs aggregate into one SKIP row (count=3), unmapped section emits none"
else
  fail "TC-55: expected a single aggregated SKIP count=3 and none for R2 (lines=$TC55_LINES r2=$TC55_R2)"
fi

echo ""
echo "TC-56: a fenced ## heading neither closes the region nor sets has_codify"
TC56_R=$(mk_repo tc56)
cat > "$(doc_path "$TC56_R" "20260101_0000_a.md")" <<'DOC'
# doc

## Retrospective

### Insight 1: a

```
## Example
### Insight 99: fenced
## Codify Decisions
```

### Insight 2: b
DOC
TC56_CONF=$(mk_conf tc56 R1 "$TC56_R")
run_cmd ledger "$TC56_CONF"
TC56_OK=true
# A fenced line is out of scope for every rule. If the region-heading rule is
# evaluated ahead of the fence, the fenced '## Example' ends the region and the
# marker after the fence is lost, while '## Codify Decisions' is believed.
[ "$(nrows "$RUN_OUT")" = "2" ]                     || TC56_OK=false
[ "$(lfield "$RUN_OUT" 1 10)" = "Insight 1: a" ]    || TC56_OK=false
[ "$(lfield "$RUN_OUT" 2 10)" = "Insight 2: b" ]    || TC56_OK=false
[ "$(lfield "$RUN_OUT" 1 4)" = "no" ]               || TC56_OK=false
if [ "$TC56_OK" = true ]; then
  pass "TC-56: fenced ## headings are inert (region survives, has_codify=no)"
else
  fail "TC-56: expected 2 rows (Insight 1/Insight 2) with has_codify=no, got $(nrows "$RUN_OUT") rows"
fi

echo ""
echo "TC-57: '## Retrospective' with trailing whitespace is not a region"
TC57_R=$(mk_repo tc57)
TC57_DOC=$(doc_path "$TC57_R" "20260101_0000_a.md")
{
  printf '# doc\n\n'
  printf '## Retrospective   \n\n'
  printf '### Insight 1: a\n'
} > "$TC57_DOC"
cat > "$(doc_path "$TC57_R" "20260101_0100_b.md")" <<'DOC'
# control doc

## Retrospective

### Insight 1: counted
DOC
TC57_CONF=$(mk_conf tc57 R1 "$TC57_R")
run_cmd ledger "$TC57_CONF"
TC57_ROWS=$(nrows "$RUN_OUT")
TC57_DOC1=$(lfield "$RUN_OUT" 1 2)
run_cmd summary "$TC57_CONF"
TC57_DOCS=$(sval "$RUN_OUT" R1 docs_with_retro)
# The region heading is an exact match, so a padded heading is a different
# section; the control doc keeps the assertion from holding vacuously.
if [ "$TC57_ROWS" = "1" ] && [ "$TC57_DOC1" = "20260101_0100_b.md" ] && [ "$TC57_DOCS" = "1" ]; then
  pass "TC-57: padded region heading rejected, exact heading still counted"
else
  fail "TC-57: expected 1 row from the control doc only (rows=$TC57_ROWS doc=$TC57_DOC1 docs=$TC57_DOCS)"
fi

echo ""
echo "TC-58: an unreadable docs/cycles fails closed instead of emitting an empty ledger"
TC58_R=$(mk_repo tc58)
cat > "$(doc_path "$TC58_R" "20260101_0000_a.md")" <<'DOC'
# doc

## Retrospective

### Insight 1: a
DOC
TC58_CONF=$(mk_conf tc58 R1 "$TC58_R")
# Permission denial is the only portable way to make enumeration fail; an absent
# directory takes the warn-and-skip path instead. This case expects to run as a
# non-root user, and fails loudly rather than passing vacuously if it does not.
chmod 000 "$TC58_R/docs/cycles"
run_cmd ledger "$TC58_CONF" || true
TC58_RC="$RUN_RC"
TC58_ROWS=$(nrows "$RUN_OUT")
chmod 755 "$TC58_R/docs/cycles"
if [ "$TC58_RC" != "0" ] && [ "$TC58_ROWS" = "0" ]; then
  pass "TC-58: enumeration failure -> non-zero exit (rc=$TC58_RC)"
else
  fail "TC-58: expected a non-zero exit on an unreadable docs/cycles (rc=$TC58_RC rows=$TC58_ROWS)"
fi

echo ""
echo "TC-59: a container-side 失敗 keyword sets explicit_failure"
TC59_R=$(mk_repo tc59)
cat > "$(doc_path "$TC59_R" "20260101_0000_a.md")" <<'DOC'
# doc

## Retrospective

### 失敗の記録

**Pair 1: X**
- detail
DOC
TC59_CONF=$(mk_conf tc59 R1 "$TC59_R")
run_cmd ledger "$TC59_CONF"
# The marker line carries no keyword, so only the container's Japanese branch can
# produce this verdict.
if [ "$(nrows "$RUN_OUT")" = "1" ] \
   && [ "$(lfield "$RUN_OUT" 1 9)" = "explicit_failure" ] \
   && [ "$(lfield "$RUN_OUT" 1 6)" = "### 失敗の記録" ]; then
  pass "TC-59: container-side 失敗 -> explicit_failure"
else
  fail "TC-59: expected explicit_failure from the container, got '$(lfield "$RUN_OUT" 1 9)'"
fi

# Summary
# The expected case count is part of the contract: without it a deleted case
# leaves FAIL at 0 and the suite still reports success.
EXPECTED_TC=59
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
if [ "$((PASS + FAIL))" -ne "$EXPECTED_TC" ]; then
  echo "FAIL: expected $EXPECTED_TC test cases, ran $((PASS + FAIL))"
  exit 1
fi
[ "$FAIL" -eq 0 ] && [ "$PASS" -eq "$EXPECTED_TC" ] && exit 0 || exit 1
