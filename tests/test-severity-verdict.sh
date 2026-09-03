#!/bin/bash
# test-severity-verdict.sh - skills/review/severity-verdict.sh behavior contract
# Cycle: docs/cycles/20260903_1130_severity-verdict.md
# TC-01..13: RED (Test List TC-05..TC-12, TC-17). TC-14..TC-25: RED addendum 2
#   (REVIEW BLOCK critical/important findings — crash-on-malformed-input,
#   loose --invalid parsing, missing/empty dir handling, DEGRADED-vs-FORCE_BLOCK
#   ordering — hardened before GREEN re-implements).
#
# validate <dir>: jq-parses <dir>/*.json, requires .issues to be an array whose
#   items have .severity in {critical, important, optional}. Unknown keys (e.g. the
#   legacy blocking_score field) are ignored — migration compat, see Cycle doc
#   Files-to-Change A. Output: "OK <basename>" / "INVALID <basename>: <reason>".
#   Any INVALID -> exit 1, all OK -> exit 0. jq absent -> "DEGRADED: jq not found"
#   exit 0. Malformed input (top-level non-array-of-objects .issues, non-object
#   .issues elements, missing .issues) must produce INVALID + exit 1 -- never a
#   raw jq crash. A nonexistent or empty dir must not vacuously exit 0.
# verdict <triage.json> [--invalid <name>]...: triage.json is itself validated
#   (parseable, array of objects, severity/category enum) -> INVALID-TRIAGE: <reason>
#   + exit 2 on failure (no silent PASS, no crash on non-object array elements).
#   On success, counts accept-apply + accept-defer items (reject excluded) by
#   severity. critical>=1 -> BLOCK, else important>=1 -> WARN, else PASS.
#   --invalid parsing must be strict: only the exact `--invalid <name>` two-token
#   form is accepted; `--invalid=<name>` (equals form), a trailing `--invalid`
#   with no value, and any unrecognized flag are usage errors (exit 64), never
#   silently ignored. A reviewer name is normalized before the NON-NEGOTIABLE
#   (security-reviewer/correctness-reviewer) comparison so a namespaced form
#   (dev-crew:security-reviewer) or a filename form (security-reviewer.json)
#   still forces BLOCK -- the floor must not be bypassable by cosmetic name
#   drift. The floor is independent of jq availability: even when jq is absent,
#   `--invalid security-reviewer`/`correctness-reviewer` must still print
#   "BLOCK ... invalid:N" on stdout (the DEGRADED note, if any, goes to stderr
#   only -- it must never silently discard the floor).
#   Output: "<BLOCK|WARN|PASS> critical:N important:N optional:N invalid:M", exit 0.

set -uo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$BASE_DIR/skills/review/severity-verdict.sh"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== severity-verdict.sh Behavior Tests ==="

# --- Existence guard (recall-candidates pattern, rules/plan-discipline.md) ---
# Until GREEN creates skills/review/severity-verdict.sh, every TC below is
# unreachable-by-design: fail each TC explicitly with a clear reason instead of
# letting "command not found" produce a misleading/inconsistent failure shape.
if [ ! -f "$SCRIPT" ]; then
  for tc in TC-01 TC-02 TC-03 TC-04 TC-05 TC-06 TC-07 TC-08 TC-09 TC-10 TC-11 TC-12 TC-13 \
            TC-14 TC-15 TC-16 TC-17 TC-18 TC-19 TC-20 TC-21 TC-22 TC-23 TC-24 TC-25; do
    fail "$tc: $SCRIPT not found (RED state — GREEN creates skills/review/severity-verdict.sh)"
  done
  echo ""
  echo "=== Summary ==="
  echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
  exit 1
fi

# --- Fixture root (addendum item 11: single top-level trap, no per-TC mktemp
#     leaks — every fixture below is a path under FIXTURE_DIR) ---
FIXTURE_DIR=$(mktemp -d)
trap 'rm -rf "$FIXTURE_DIR"' EXIT

write_json() {
  # write_json <path> <content>
  printf '%s' "$2" > "$1"
}

# Portable jq-absent simulation (addendum item 10): an empty, freshly-created
# directory guarantees jq cannot be found regardless of host layout (a bare
# `PATH=/bin` can still resolve to jq on merged-usr Linux, producing a false
# non-degraded run there). The interpreter is invoked by its absolute path so
# the emptied PATH cannot break locating `bash` itself either.
EMPTY_PATH_DIR="$FIXTURE_DIR/empty-path"
mkdir -p "$EMPTY_PATH_DIR"
run_jq_absent() {
  env PATH="$EMPTY_PATH_DIR" /bin/bash "$SCRIPT" "$@" 2>&1
}
run_jq_absent_split() {
  # run_jq_absent_split <outfile> <errfile> <args...> — stdout/stderr captured
  # separately so a DEGRADED note (stderr-only, per the fixed contract above)
  # cannot pollute the machine-parseable stdout format assertion.
  env PATH="$EMPTY_PATH_DIR" /bin/bash "$SCRIPT" "${@:3}" >"$1" 2>"$2"
}

# =============================================================================
# TC-01: [Given] 3 件の valid JSON fixture dir / [When] validate / [Then] 全 OK, exit 0
# =============================================================================
echo ""
echo "TC-01: validate — all-valid fixture dir exits 0 with OK per file"
VDIR1="$FIXTURE_DIR/tc01"
mkdir -p "$VDIR1"
write_json "$VDIR1/security-reviewer.json" '{"issues": [{"severity": "critical", "message": "sql injection", "file": "a.php", "line": 10, "suggestion": "use bound params"}]}'
write_json "$VDIR1/correctness-reviewer.json" '{"issues": [{"severity": "important", "message": "off-by-one", "file": "b.php", "line": 5, "suggestion": "fix loop bound"}]}'
write_json "$VDIR1/maintainability-reviewer.json" '{"issues": []}'
out1=$(bash "$SCRIPT" validate "$VDIR1" 2>&1)
rc1=$?
if [ "$rc1" -eq 0 ] \
  && printf '%s\n' "$out1" | grep -q "^OK security-reviewer.json$" \
  && printf '%s\n' "$out1" | grep -q "^OK correctness-reviewer.json$" \
  && printf '%s\n' "$out1" | grep -q "^OK maintainability-reviewer.json$"; then
  pass "TC-01: all-valid dir -> exit 0 with OK <basename> per file"
else
  fail "TC-01: expected exit 0 + 3x OK lines, got rc=$rc1 out='$out1'"
fi

# =============================================================================
# TC-02: [Given] broken JSON 1 件混在 / [When] validate / [Then] INVALID <file>: + exit 1
# =============================================================================
echo ""
echo "TC-02: validate — one broken JSON among valid ones -> INVALID line + exit 1"
VDIR2="$FIXTURE_DIR/tc02"
mkdir -p "$VDIR2"
write_json "$VDIR2/security-reviewer.json" '{"issues": [{"severity": "optional", "message": "m", "file": "f", "line": 1, "suggestion": "s"}]}'
write_json "$VDIR2/broken-reviewer.json" '{"issues": [ this is not valid json'
out2=$(bash "$SCRIPT" validate "$VDIR2" 2>&1)
rc2=$?
if [ "$rc2" -eq 1 ] \
  && printf '%s\n' "$out2" | grep -qE "^INVALID broken-reviewer\.json:.+" \
  && printf '%s\n' "$out2" | grep -q "^OK security-reviewer.json$"; then
  pass "TC-02: broken JSON -> INVALID <file>: <reason> line + exit 1 (valid sibling still OK)"
else
  fail "TC-02: expected exit 1 + INVALID line with reason, got rc=$rc2 out='$out2'"
fi

# =============================================================================
# TC-03: [Given] severity に enum 外の値 "high" / [When] validate / [Then] INVALID
# =============================================================================
echo ""
echo "TC-03: validate — severity 'high' (outside critical|important|optional) -> INVALID"
VDIR3="$FIXTURE_DIR/tc03"
mkdir -p "$VDIR3"
write_json "$VDIR3/bad-severity-reviewer.json" '{"issues": [{"severity": "high", "message": "m", "file": "f", "line": 1, "suggestion": "s"}]}'
out3=$(bash "$SCRIPT" validate "$VDIR3" 2>&1)
rc3=$?
if [ "$rc3" -eq 1 ] && printf '%s\n' "$out3" | grep -qE "^INVALID bad-severity-reviewer\.json:.+"; then
  pass "TC-03: severity enum violation -> INVALID + exit 1"
else
  fail "TC-03: expected INVALID + exit 1 for severity=high, got rc=$rc3 out='$out3'"
fi

# =============================================================================
# TC-04: [Given] 未知キー (旧 blocking_score) を含む valid JSON / [When] validate /
#         [Then] OK — 移行互換（Cycle doc Files A: 必須構造のみ検査し未知キーは無視）
# =============================================================================
echo ""
echo "TC-04: validate — unknown key (legacy blocking_score) alongside valid structure -> OK"
VDIR4="$FIXTURE_DIR/tc04"
mkdir -p "$VDIR4"
write_json "$VDIR4/legacy-reviewer.json" '{"blocking_score": 42, "issues": [{"severity": "important", "message": "m", "file": "f", "line": 1, "suggestion": "s"}]}'
out4=$(bash "$SCRIPT" validate "$VDIR4" 2>&1)
rc4=$?
if [ "$rc4" -eq 0 ] && printf '%s\n' "$out4" | grep -q "^OK legacy-reviewer.json$"; then
  pass "TC-04: unknown key (blocking_score) ignored -> OK (migration compat)"
else
  fail "TC-04: expected OK despite unknown key, got rc=$rc4 out='$out4'"
fi

# =============================================================================
# TC-05: [Given] jq を PATH から外した env / [When] validate / [Then] DEGRADED + exit 0
#         (addendum item 10: portable empty-PATH-dir + absolute /bin/bash simulation)
# =============================================================================
echo ""
echo "TC-05: validate — jq absent from PATH -> DEGRADED + exit 0"
VDIR5="$FIXTURE_DIR/tc05"
mkdir -p "$VDIR5"
write_json "$VDIR5/x.json" '{"issues": []}'
out5=$(run_jq_absent validate "$VDIR5")
rc5=$?
if [ "$rc5" -eq 0 ] && printf '%s\n' "$out5" | grep -qE "^DEGRADED: jq not found$"; then
  pass "TC-05: jq absent -> DEGRADED: jq not found + exit 0"
else
  fail "TC-05: expected DEGRADED message + exit 0, got rc=$rc5 out='$out5'"
fi

# =============================================================================
# TC-06: [Given] triage.json (accept-apply, severity critical 1件) / [When] verdict /
#         [Then] BLOCK critical:1 ... 行
# =============================================================================
echo ""
echo "TC-06: verdict — accept-apply critical 1 -> BLOCK critical:1 ..."
T6="$FIXTURE_DIR/tc06.json"
write_json "$T6" '[{"severity": "critical", "category": "accept-apply", "message": "m", "file": "f", "line": 1}]'
out6=$(bash "$SCRIPT" verdict "$T6" 2>&1)
rc6=$?
if [ "$rc6" -eq 0 ] && printf '%s\n' "$out6" | grep -qE "^BLOCK critical:1 important:0 optional:0 invalid:0$"; then
  pass "TC-06: accept-apply critical:1 -> BLOCK critical:1 important:0 optional:0 invalid:0"
else
  fail "TC-06: expected BLOCK critical:1 line, got rc=$rc6 out='$out6'"
fi

# =============================================================================
# TC-07: [Given] accept-defer critical 1 + reject critical 1 / [When] verdict /
#         [Then] BLOCK（defer は効く・reject は無視）counts で reject 除外を検証
# =============================================================================
echo ""
echo "TC-07: verdict — accept-defer critical counts, reject critical is excluded"
T7="$FIXTURE_DIR/tc07.json"
write_json "$T7" '[
  {"severity": "critical", "category": "accept-defer", "message": "deferred but still blocking", "file": "f1", "line": 1},
  {"severity": "critical", "category": "reject", "message": "rejected, must not count", "file": "f2", "line": 2}
]'
out7=$(bash "$SCRIPT" verdict "$T7" 2>&1)
rc7=$?
if [ "$rc7" -eq 0 ] && printf '%s\n' "$out7" | grep -qE "^BLOCK critical:1 important:0 optional:0 invalid:0$"; then
  pass "TC-07: accept-defer critical:1 -> BLOCK, reject critical excluded from count (still critical:1, not 2)"
else
  fail "TC-07: expected BLOCK critical:1 (reject excluded), got rc=$rc7 out='$out7'"
fi

# =============================================================================
# TC-08: [Given] important のみ / [When] verdict / [Then] WARN。optional のみ・空配列 / [Then] PASS
# =============================================================================
echo ""
echo "TC-08a: verdict — important-only accepted findings -> WARN"
T8A="$FIXTURE_DIR/tc08a.json"
write_json "$T8A" '[{"severity": "important", "category": "accept-apply", "message": "m", "file": "f", "line": 1}]'
out8a=$(bash "$SCRIPT" verdict "$T8A" 2>&1)
rc8a=$?
if [ "$rc8a" -eq 0 ] && printf '%s\n' "$out8a" | grep -qE "^WARN critical:0 important:1 optional:0 invalid:0$"; then
  pass "TC-08a: important:1 -> WARN"
else
  fail "TC-08a: expected WARN important:1, got rc=$rc8a out='$out8a'"
fi

echo ""
echo "TC-08b: verdict — optional-only accepted findings -> PASS"
T8B="$FIXTURE_DIR/tc08b.json"
write_json "$T8B" '[{"severity": "optional", "category": "accept-apply", "message": "m", "file": "f", "line": 1}]'
out8b=$(bash "$SCRIPT" verdict "$T8B" 2>&1)
rc8b=$?
if [ "$rc8b" -eq 0 ] && printf '%s\n' "$out8b" | grep -qE "^PASS critical:0 important:0 optional:1 invalid:0$"; then
  pass "TC-08b: optional:1 -> PASS"
else
  fail "TC-08b: expected PASS optional:1, got rc=$rc8b out='$out8b'"
fi

echo ""
echo "TC-08c: verdict — empty array -> PASS"
T8C="$FIXTURE_DIR/tc08c.json"
write_json "$T8C" '[]'
out8c=$(bash "$SCRIPT" verdict "$T8C" 2>&1)
rc8c=$?
if [ "$rc8c" -eq 0 ] && printf '%s\n' "$out8c" | grep -qE "^PASS critical:0 important:0 optional:0 invalid:0$"; then
  pass "TC-08c: empty triage array -> PASS critical:0 important:0 optional:0 invalid:0"
else
  fail "TC-08c: expected PASS all-zero, got rc=$rc8c out='$out8c'"
fi

# =============================================================================
# TC-09/TC-10/TC-11: [Given] PASS 相当入力（optional のみ）+ --invalid <reviewer> /
#         [When] verdict / [Then] NON-NEGOTIABLE (security/correctness) -> BLOCK,
#         それ以外 -> WARN floor
# =============================================================================
T9="$FIXTURE_DIR/tc09.json"
write_json "$T9" '[{"severity": "optional", "category": "accept-apply", "message": "m", "file": "f", "line": 1}]'

echo ""
echo "TC-09: verdict — PASS-equivalent input + --invalid correctness-reviewer -> BLOCK"
out9=$(bash "$SCRIPT" verdict "$T9" --invalid correctness-reviewer 2>&1)
rc9=$?
if [ "$rc9" -eq 0 ] && printf '%s\n' "$out9" | grep -qE "^BLOCK critical:0 important:0 optional:1 invalid:1$"; then
  pass "TC-09: --invalid correctness-reviewer forces BLOCK (NON-NEGOTIABLE floor)"
else
  fail "TC-09: expected BLOCK with invalid:1, got rc=$rc9 out='$out9'"
fi

echo ""
echo "TC-10: verdict — PASS-equivalent input + --invalid security-reviewer -> BLOCK"
out10=$(bash "$SCRIPT" verdict "$T9" --invalid security-reviewer 2>&1)
rc10=$?
if [ "$rc10" -eq 0 ] && printf '%s\n' "$out10" | grep -qE "^BLOCK critical:0 important:0 optional:1 invalid:1$"; then
  pass "TC-10: --invalid security-reviewer forces BLOCK (NON-NEGOTIABLE floor)"
else
  fail "TC-10: expected BLOCK with invalid:1, got rc=$rc10 out='$out10'"
fi

echo ""
echo "TC-11: verdict — PASS-equivalent input + --invalid product-reviewer -> WARN floor"
out11=$(bash "$SCRIPT" verdict "$T9" --invalid product-reviewer 2>&1)
rc11=$?
if [ "$rc11" -eq 0 ] && printf '%s\n' "$out11" | grep -qE "^WARN critical:0 important:0 optional:1 invalid:1$"; then
  pass "TC-11: --invalid product-reviewer forces WARN floor (non-NON-NEGOTIABLE reviewer)"
else
  fail "TC-11: expected WARN with invalid:1, got rc=$rc11 out='$out11'"
fi

# =============================================================================
# TC-12: [Given] 不正 triage.json (severity が enum 外 / 非配列) / [When] verdict /
#         [Then] INVALID-TRIAGE: <理由> + exit 2（黙殺 PASS の禁止）
# =============================================================================
echo ""
echo "TC-12a: verdict — triage.json severity outside enum -> INVALID-TRIAGE + exit 2"
T12A="$FIXTURE_DIR/tc12a.json"
write_json "$T12A" '[{"severity": "urgent", "category": "accept-apply", "message": "m", "file": "f", "line": 1}]'
out12a=$(bash "$SCRIPT" verdict "$T12A" 2>&1)
rc12a=$?
if [ "$rc12a" -eq 2 ] && printf '%s\n' "$out12a" | grep -qE "^INVALID-TRIAGE:.+"; then
  pass "TC-12a: severity enum violation -> INVALID-TRIAGE + exit 2"
else
  fail "TC-12a: expected INVALID-TRIAGE + exit 2, got rc=$rc12a out='$out12a'"
fi

echo ""
echo "TC-12b: verdict — triage.json is not an array -> INVALID-TRIAGE + exit 2"
T12B="$FIXTURE_DIR/tc12b.json"
write_json "$T12B" '{"severity": "critical", "category": "accept-apply"}'
out12b=$(bash "$SCRIPT" verdict "$T12B" 2>&1)
rc12b=$?
if [ "$rc12b" -eq 2 ] && printf '%s\n' "$out12b" | grep -qE "^INVALID-TRIAGE:.+"; then
  pass "TC-12b: non-array triage.json -> INVALID-TRIAGE + exit 2"
else
  fail "TC-12b: expected INVALID-TRIAGE + exit 2 for non-array, got rc=$rc12b out='$out12b'"
fi

# =============================================================================
# TC-13: [Given] verdict の全出力 / [When] regex 検証 / [Then]
#         ^(BLOCK|WARN|PASS) critical:[0-9]+ important:[0-9]+ optional:[0-9]+ invalid:[0-9]+$
# =============================================================================
echo ""
echo "TC-13: verdict output matches fixed format regex across BLOCK/WARN/PASS"
FMT_RE='^(BLOCK|WARN|PASS) critical:[0-9]+ important:[0-9]+ optional:[0-9]+ invalid:[0-9]+$'
T13_BLOCK="$FIXTURE_DIR/tc13-block.json"
T13_WARN="$FIXTURE_DIR/tc13-warn.json"
T13_PASS="$FIXTURE_DIR/tc13-pass.json"
write_json "$T13_BLOCK" '[{"severity": "critical", "category": "accept-apply", "message": "m", "file": "f", "line": 1}]'
write_json "$T13_WARN" '[{"severity": "important", "category": "accept-apply", "message": "m", "file": "f", "line": 1}]'
write_json "$T13_PASS" '[]'
fmt_fail=0
for f in "$T13_BLOCK" "$T13_WARN" "$T13_PASS"; do
  fmt_out=$(bash "$SCRIPT" verdict "$f" 2>&1)
  if ! printf '%s\n' "$fmt_out" | grep -qE "$FMT_RE"; then
    fmt_fail=$((fmt_fail + 1))
  fi
done
if [ "$fmt_fail" -eq 0 ]; then
  pass "TC-13: BLOCK/WARN/PASS outputs all match fixed format regex"
else
  fail "TC-13: $fmt_fail/3 verdict outputs did not match format regex"
fi

# =============================================================================
# TC-14: [Given] validate 対象 dir に top-level 配列 JSON (["x"]) / [When] validate /
#         [Then] INVALID <file>: 行 + exit 1（jq 生 exit でのクラッシュ不可、REVIEW critical）
# =============================================================================
echo ""
echo "TC-14: validate — top-level array JSON (not an object) -> INVALID + exit 1, no crash"
VDIR14="$FIXTURE_DIR/tc14"
mkdir -p "$VDIR14"
write_json "$VDIR14/array-reviewer.json" '["x"]'
out14=$(bash "$SCRIPT" validate "$VDIR14" 2>&1)
rc14=$?
if [ "$rc14" -eq 1 ] \
  && printf '%s\n' "$out14" | grep -qE "^INVALID array-reviewer\.json:.+" \
  && ! printf '%s\n' "$out14" | grep -qi "jq: error"; then
  pass "TC-14: top-level array -> INVALID + exit 1 (no raw jq crash)"
else
  fail "TC-14: expected INVALID + exit 1 without a jq crash, got rc=$rc14 out='$out14'"
fi

# =============================================================================
# TC-15: [Given] .issues 配列の要素が非 object ({"issues": ["oops"]}) / [When] validate /
#         [Then] INVALID + exit 1（jq 生 exit でのクラッシュ不可、REVIEW critical）
# =============================================================================
echo ""
echo "TC-15: validate — .issues array with a non-object element -> INVALID + exit 1, no crash"
VDIR15="$FIXTURE_DIR/tc15"
mkdir -p "$VDIR15"
write_json "$VDIR15/bad-issue-reviewer.json" '{"issues": ["oops"]}'
out15=$(bash "$SCRIPT" validate "$VDIR15" 2>&1)
rc15=$?
if [ "$rc15" -eq 1 ] \
  && printf '%s\n' "$out15" | grep -qE "^INVALID bad-issue-reviewer\.json:.+" \
  && ! printf '%s\n' "$out15" | grep -qi "jq: error"; then
  pass "TC-15: non-object .issues element -> INVALID + exit 1 (no raw jq crash)"
else
  fail "TC-15: expected INVALID + exit 1 without a jq crash, got rc=$rc15 out='$out15'"
fi

# =============================================================================
# TC-16: [Given] .issues フィールド欠落 ({"foo": 1}) / [When] validate / [Then] INVALID + exit 1
#         (regression lock — already correct pre-addendum, kept as an explicit contract)
# =============================================================================
echo ""
echo "TC-16: validate — missing .issues field -> INVALID + exit 1"
VDIR16="$FIXTURE_DIR/tc16"
mkdir -p "$VDIR16"
write_json "$VDIR16/no-issues-reviewer.json" '{"foo": 1}'
out16=$(bash "$SCRIPT" validate "$VDIR16" 2>&1)
rc16=$?
if [ "$rc16" -eq 1 ] && printf '%s\n' "$out16" | grep -qE "^INVALID no-issues-reviewer\.json:.+"; then
  pass "TC-16: missing .issues -> INVALID + exit 1"
else
  fail "TC-16: expected INVALID + exit 1 for missing .issues, got rc=$rc16 out='$out16'"
fi

# =============================================================================
# TC-17: [Given] 存在しない dir / [When] validate / [Then] エラー行 + exit 1（vacuous exit 0 不可）
# =============================================================================
echo ""
echo "TC-17: validate — nonexistent dir -> error + exit 1 (not a vacuous exit 0)"
NONEXISTENT_DIR="$FIXTURE_DIR/does-not-exist-tc17"
out17=$(bash "$SCRIPT" validate "$NONEXISTENT_DIR" 2>&1)
rc17=$?
if [ "$rc17" -eq 1 ] && [ -n "$out17" ]; then
  pass "TC-17: nonexistent dir -> non-empty error output + exit 1 (got: '$out17')"
else
  fail "TC-17: expected non-empty error + exit 1, got rc=$rc17 out='$out17'"
fi

# =============================================================================
# TC-18: [Given] 空 dir (*.json 0 件) / [When] validate /
#         [Then] `INVALID: no reviewer JSON files found` 相当 + exit 1（vacuous exit 0 不可）
# =============================================================================
echo ""
echo "TC-18: validate — empty dir (0 *.json files) -> INVALID: no reviewer JSON files found + exit 1"
EMPTY_DIR="$FIXTURE_DIR/tc18-empty"
mkdir -p "$EMPTY_DIR"
out18=$(bash "$SCRIPT" validate "$EMPTY_DIR" 2>&1)
rc18=$?
if [ "$rc18" -eq 1 ] && printf '%s\n' "$out18" | grep -qiE "no reviewer JSON files found"; then
  pass "TC-18: empty dir -> INVALID: no reviewer JSON files found + exit 1"
else
  fail "TC-18: expected 'no reviewer JSON files found' + exit 1, got rc=$rc18 out='$out18'"
fi

# =============================================================================
# TC-19: [Given] triage 配列に非 object 要素 [{...valid...}, 42] / [When] verdict /
#         [Then] INVALID-TRIAGE + exit 2（jq 生 exit でのクラッシュ不可、REVIEW critical）
# =============================================================================
echo ""
echo "TC-19: verdict — triage array with a non-object element -> INVALID-TRIAGE + exit 2, no crash"
T19="$FIXTURE_DIR/tc19.json"
write_json "$T19" '[{"severity": "critical", "category": "accept-apply", "message": "m", "file": "f", "line": 1}, 42]'
out19=$(bash "$SCRIPT" verdict "$T19" 2>&1)
rc19=$?
if [ "$rc19" -eq 2 ] \
  && printf '%s\n' "$out19" | grep -qE "^INVALID-TRIAGE:.+" \
  && ! printf '%s\n' "$out19" | grep -qi "jq: error"; then
  pass "TC-19: non-object triage element -> INVALID-TRIAGE + exit 2 (no raw jq crash)"
else
  fail "TC-19: expected INVALID-TRIAGE + exit 2 without a jq crash, got rc=$rc19 out='$out19'"
fi

# =============================================================================
# TC-20/21/22: [Given] --invalid の不正な渡し方 / [When] verdict / [Then] usage exit 64
#         （REVIEW security: '=' 形式・値なし・未知フラグの黙殺は floor 迂回を許す）
# =============================================================================
T20_INPUT="$FIXTURE_DIR/tc20-input.json"
write_json "$T20_INPUT" '[]'

echo ""
echo "TC-20: verdict — --invalid=security-reviewer (equals form) -> usage exit 64"
out20=$(bash "$SCRIPT" verdict "$T20_INPUT" --invalid=security-reviewer 2>&1)
rc20=$?
if [ "$rc20" -eq 64 ]; then
  pass "TC-20: '--invalid=<name>' equals form rejected as usage error (exit 64)"
else
  fail "TC-20: expected usage exit 64 for '--invalid=security-reviewer', got rc=$rc20 out='$out20'"
fi

echo ""
echo "TC-21: verdict — trailing --invalid (no value) -> usage exit 64"
out21=$(bash "$SCRIPT" verdict "$T20_INPUT" --invalid 2>&1)
rc21=$?
if [ "$rc21" -eq 64 ]; then
  pass "TC-21: trailing '--invalid' with no value rejected as usage error (exit 64)"
else
  fail "TC-21: expected usage exit 64 for trailing '--invalid', got rc=$rc21 out='$out21'"
fi

echo ""
echo "TC-22: verdict — unknown flag --foo -> usage exit 64"
out22=$(bash "$SCRIPT" verdict "$T20_INPUT" --foo 2>&1)
rc22=$?
if [ "$rc22" -eq 64 ]; then
  pass "TC-22: unrecognized flag '--foo' rejected as usage error (exit 64)"
else
  fail "TC-22: expected usage exit 64 for '--foo', got rc=$rc22 out='$out22'"
fi

# =============================================================================
# TC-23: [Given] --invalid dev-crew:security-reviewer / --invalid security-reviewer.json /
#         [When] verdict / [Then] 正規化されて NON-NEGOTIABLE floor が発動し BLOCK
#         （REVIEW security: prefix/suffix ゆらぎでの floor 迂回を防ぐ）
# =============================================================================
echo ""
echo "TC-23a: verdict — --invalid dev-crew:security-reviewer (namespaced) -> normalized to BLOCK"
out23a=$(bash "$SCRIPT" verdict "$T9" --invalid dev-crew:security-reviewer 2>&1)
rc23a=$?
if [ "$rc23a" -eq 0 ] && printf '%s\n' "$out23a" | grep -qE "^BLOCK critical:0 important:0 optional:1 invalid:1$"; then
  pass "TC-23a: 'dev-crew:security-reviewer' normalizes to the NON-NEGOTIABLE floor -> BLOCK"
else
  fail "TC-23a: expected BLOCK for namespaced security-reviewer, got rc=$rc23a out='$out23a'"
fi

echo ""
echo "TC-23b: verdict — --invalid security-reviewer.json (filename form) -> normalized to BLOCK"
out23b=$(bash "$SCRIPT" verdict "$T9" --invalid security-reviewer.json 2>&1)
rc23b=$?
if [ "$rc23b" -eq 0 ] && printf '%s\n' "$out23b" | grep -qE "^BLOCK critical:0 important:0 optional:1 invalid:1$"; then
  pass "TC-23b: 'security-reviewer.json' normalizes to the NON-NEGOTIABLE floor -> BLOCK"
else
  fail "TC-23b: expected BLOCK for filename-form security-reviewer, got rc=$rc23b out='$out23b'"
fi

# =============================================================================
# TC-24: [Given] --invalid product-reviewer --invalid usability-reviewer (2件) /
#         [When] verdict / [Then] invalid:2 + WARN floor（regression lock）
# =============================================================================
echo ""
echo "TC-24: verdict — two non-NON-NEGOTIABLE --invalid flags -> invalid:2 + WARN floor"
out24=$(bash "$SCRIPT" verdict "$T9" --invalid product-reviewer --invalid usability-reviewer 2>&1)
rc24=$?
if [ "$rc24" -eq 0 ] && printf '%s\n' "$out24" | grep -qE "^WARN critical:0 important:0 optional:1 invalid:2$"; then
  pass "TC-24: two non-NON-NEGOTIABLE --invalid flags accumulate to invalid:2, WARN floor"
else
  fail "TC-24: expected WARN with invalid:2, got rc=$rc24 out='$out24'"
fi

# =============================================================================
# TC-25: [Given] jq 不在 env + --invalid correctness-reviewer / [When] verdict /
#         [Then] stdout に BLOCK critical:0 important:0 optional:0 invalid:1（floor は jq 非依存で
#         維持。DEGRADED 注記があるなら stderr のみ）。jq 不在 + --invalid なしは DEGRADED 維持
#         （REVIEW important: DEGRADED が FORCE_BLOCK を捨てる順序バグ）
# =============================================================================
echo ""
echo "TC-25a: verdict — jq absent + --invalid correctness-reviewer -> BLOCK on stdout (floor jq-independent)"
T25_OUT="$FIXTURE_DIR/tc25a.out"
T25_ERR="$FIXTURE_DIR/tc25a.err"
run_jq_absent_split "$T25_OUT" "$T25_ERR" verdict "$T8C" --invalid correctness-reviewer
rc25a=$?
out25a=$(cat "$T25_OUT")
if [ "$rc25a" -eq 0 ] \
  && printf '%s\n' "$out25a" | grep -qE "^BLOCK critical:0 important:0 optional:0 invalid:1$" \
  && ! printf '%s\n' "$out25a" | grep -qi "DEGRADED"; then
  pass "TC-25a: jq absent + --invalid correctness-reviewer -> clean BLOCK line on stdout (floor preserved)"
else
  fail "TC-25a: expected clean BLOCK line on stdout even with jq absent, got rc=$rc25a stdout='$out25a' stderr='$(cat "$T25_ERR")'"
fi

echo ""
echo "TC-25b: verdict — jq absent, no --invalid -> DEGRADED: jq not found + exit 0 (unchanged)"
out25b=$(run_jq_absent verdict "$T8C")
rc25b=$?
if [ "$rc25b" -eq 0 ] && printf '%s\n' "$out25b" | grep -qE "^DEGRADED: jq not found$"; then
  pass "TC-25b: jq absent without --invalid -> DEGRADED: jq not found + exit 0"
else
  fail "TC-25b: expected DEGRADED message + exit 0, got rc=$rc25b out='$out25b'"
fi

# --- Summary ---
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
