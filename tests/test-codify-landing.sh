#!/bin/bash
# test-codify-landing.sh - codified の rules への着地を数える scripts/codify-landing.sh の契約
#
# 判定の入力は docs/cycles/*.md の `## Codify Decisions`（Decision: codified かつ Destination: rule…）、
# 着地の根拠は rules/*.md と .claude/rules/*.md の出典（<cycle_id> #N）、取り下げは docs/codify-withdrawn.md。
#
# TC-01: 引数の誤り（なし / 存在しないディレクトリ / 未知のオプション）は exit 2 + usage
# TC-02: 着地済みの insight は出さず、--count は 0
# TC-03: 出典の 4 つの書き方（パス + #N / Insight N / Insights 1, 2, 4 / #1, #5）を着地とみなす
# TC-04: 見出し `### Insight 1:` と Decision の後ろの説明を扱う
# TC-04b: 空の初回節 + 2 つ目の節 / コードブロック内の偽の節 / `### Insight 2（補足）`
# TC-05: no-codify・deferred・Destination が rule 以外は出さない
# TC-06: 誤判定 3 種（#12 で #1、1 行に複数 cycle の #N、別 cycle の同番号）を着地にしない
# TC-07: .claude/rules/ だけの導入先の形
# TC-08: 台帳の取り下げ（理由あり = 着地扱い、理由なし = 未着地）
# TC-09: 1 行ずつ `<cycle_id> #N`、--count は件数だけ、rc 0
# TC-11: 実際の作業ツリーで未着地 0 件
# TC-12: 台帳の各行が理由・消えた仕組みの指し先・実在の insight を持つ
# TC-13: orchestrate の 4 文書が同じ landing の呼び出しブロックを持つ。SKILL.md は 100 行以下
# TC-13b: 導入先の形の fixture repo で Block 0 の landing ブロックを実行し整数 1 行が出る
# TC-14: codify-insight/reference.md の Rule Tier Contract が出典の書式と台帳を挙げる
# TC-15: rules/shell-scripts.md の frontmatter
#
# TC-10（GREEN 前の 66 件の突合）は一回限りの計測で、このテストには入れない。
# `cmd | grep -q` は pipefail 下で使わず、here-string か変数経由で grep する。

set -uo pipefail

BASE_DIR="${BASE_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

SCRIPT="$BASE_DIR/scripts/codify-landing.sh"
SKILL_MD="$BASE_DIR/skills/orchestrate/SKILL.md"
REF_MD="$BASE_DIR/skills/orchestrate/reference.md"
STEPS_SUB_MD="$BASE_DIR/skills/orchestrate/steps-subagent.md"
STEPS_TEAMS_MD="$BASE_DIR/skills/orchestrate/steps-teams.md"
CODIFY_REF_MD="$BASE_DIR/skills/codify-insight/reference.md"
SHELL_RULE="$BASE_DIR/rules/shell-scripts.md"
LEDGER="$BASE_DIR/docs/codify-withdrawn.md"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "=== codify-landing Tests ==="

# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------

# run_landing <args...>: OUT / ERR / RC を設定する。コマンド置換の直後に rc を取る
run_landing() {
  OUT=$(bash "$SCRIPT" "$@" 2>"$TMP/err")
  RC=$?
  ERR=$(cat "$TMP/err")
}

# sorted_lines <text>: 空行を除いて並べ替える（出力の行の集合で比べるため）
sorted_lines() {
  printf '%s\n' "$1" | sed '/^$/d' | sort
}

# mk_fixture <name>: 空の repo の形を作り、そのパスを FX に入れる
mk_fixture() {
  FX="$TMP/$1"
  mkdir -p "$FX/docs/cycles"
}

# ins <N> <decision> <destination>: Codify Decisions の insight 1 件
ins() {
  printf '### Insight %s\n- **Decision**: %s\n- **Destination**: %s\n- **Reason**: r\n\n' "$1" "$2" "$3"
}

# mk_doc <fixture dir> <cycle_id>: 標準入力を本文にして docs/cycles/<id>_x.md を作る
mk_doc() {
  mkdir -p "$1/docs/cycles"
  {
    printf -- '---\nfeature: x\nretro_status: resolved\n---\n\n# x\n\n'
    cat
  } > "$1/docs/cycles/$2_x.md"
}

# mk_rule <fixture dir> <rules dir 名> <file> <内容>
mk_rule() {
  mkdir -p "$1/$2"
  printf '%s\n' "$4" > "$1/$2/$3"
}

# expect_set <label> <expected text>: RC 0 かつ出力の行の集合が一致
expect_set() {
  local label="$1" expected="$2" got want
  got=$(sorted_lines "$OUT")
  want=$(sorted_lines "$expected")
  if [ "$RC" -ne 0 ]; then
    fail "$label: rc=$RC (expected 0) stderr='$ERR'"
  elif [ "$got" != "$want" ]; then
    fail "$label: output set differs. got=[$(printf '%s' "$got" | tr '\n' ',')] want=[$(printf '%s' "$want" | tr '\n' ',')]"
  else
    pass "$label"
  fi
}

# expect_count <label> <n>: --count の出力が整数 1 行で n、rc 0
expect_count() {
  local label="$1" n="$2"
  if [ "$RC" -ne 0 ]; then
    fail "$label: --count rc=$RC (expected 0)"
  elif [ "$OUT" != "$n" ]; then
    fail "$label: --count output '$OUT' (expected '$n')"
  else
    pass "$label"
  fi
}

# fence_with <pattern> (stdin: 区間テキスト): ```bash ブロックのうち pattern を含むものだけを出す
fence_with() {
  awk -v pat="$1" '
    /^```bash/ {f=1; buf=""; next}
    f && /^```/ {f=0; if (index(buf, pat)) printf "%s", buf; next}
    f {buf = buf $0 "\n"}
  '
}

# 区間の切り出し（tests/test-codify-insight.sh と同じ規則）
sec_skill_notice() {
  awk '
    index($0, "**0. Codify notice**") == 1 {s=1; next}
    s && (/^\*\*/ || /^#/) {exit}
    s
  ' "$1"
}
sec_steps_notice() {
  awk '
    index($0, "### 0. Codify notice") == 1 {s=1; next}
    s && /^##/ {exit}
    s
  ' "$1"
}
sec_h2() {
  awk -v h="$2" '
    index($0, "## " h) == 1 {s=1; next}
    s && /^## /{exit}
    s
  ' "$1"
}

# ---------------------------------------------------------------------------
# TC-01
# ---------------------------------------------------------------------------
echo ""
echo "TC-01: argument errors exit 2 with usage on stderr"
mk_fixture tc01
for case_name in "no-args" "missing-dir" "unknown-option"; do
  case "$case_name" in
    no-args)        run_landing ;;
    missing-dir)    run_landing "$TMP/does-not-exist" ;;
    unknown-option) run_landing "$FX" --bogus ;;
  esac
  if [ "$RC" -ne 2 ]; then
    fail "TC-01: [$case_name] rc=$RC (expected 2)"
  elif ! grep -qiF 'usage' <<< "$ERR"; then
    fail "TC-01: [$case_name] stderr has no usage text: '$ERR'"
  else
    pass "TC-01: [$case_name] exit 2 + usage on stderr"
  fi
done

# ---------------------------------------------------------------------------
# TC-02
# ---------------------------------------------------------------------------
echo ""
echo "TC-02: landed insight is not reported; --count is 0"
mk_fixture tc02
{ printf '## Codify Decisions\n\n'; ins 1 codified rule; } | mk_doc "$FX" 20260101_0000
mk_rule "$FX" rules x.md '- 条項 (20260101_0000 #1)'
run_landing "$FX"
expect_set "TC-02: no output when landed" ""
run_landing "$FX" --count
expect_count "TC-02: --count prints 0" 0

# ---------------------------------------------------------------------------
# TC-03
# ---------------------------------------------------------------------------
echo ""
echo "TC-03: the four citation forms all count as landed"
mk_fixture tc03
{ printf '## Codify Decisions\n\n'; ins 2 codified rule; } | mk_doc "$FX" 20260101_0000
{ printf '## Codify Decisions\n\n'; ins 3 codified rule; } | mk_doc "$FX" 20260102_0000
{ printf '## Codify Decisions\n\n'; ins 1 codified rule; ins 2 codified rule; ins 3 codified rule; ins 4 codified rule; } | mk_doc "$FX" 20260103_0000
{ printf '## Codify Decisions\n\n'; ins 1 codified rule; ins 5 codified rule; } | mk_doc "$FX" 20260104_0000
mkdir -p "$FX/rules"
cat > "$FX/rules/forms.md" <<'EOF'
## 出典

- `docs/cycles/20260101_0000_x.md #2` — path + #N
- `docs/cycles/20260102_0000_x.md` Insight 3
- `docs/cycles/20260103_0000_x.md` Insights 1, 2, 4
- (cycle 20260104_0000 #1, #5)
EOF
run_landing "$FX"
# 20260103_0000 の #3 は出典に無いので、これだけが未着地
expect_set "TC-03: only the uncited 20260103_0000 #3 remains" "20260103_0000 #3"

# ---------------------------------------------------------------------------
# TC-04
# ---------------------------------------------------------------------------
echo ""
echo "TC-04: '### Insight 1:' heading and trailing text after Decision"
mk_fixture tc04
mkdir -p "$FX/docs/cycles"
cat > "$FX/docs/cycles/20260101_0000_x.md" <<'EOF'
---
feature: x
---

## Codify Decisions

### Insight 1: 見出しにコロンと題が付く
- **Decision**: codified (2+ 回再発で自動昇格)
- **Destination**: rule (rules/x.md + .claude/rules/ mirror)
- **Reason**: r
EOF
run_landing "$FX"
expect_set "TC-04: colon heading + decision with explanation is insight 1" "20260101_0000 #1"

# ---------------------------------------------------------------------------
# TC-04b
# ---------------------------------------------------------------------------
echo ""
echo "TC-04b: empty first section, fenced fake section, parenthesised heading"
mk_fixture tc04b
cat > "$FX/docs/cycles/20260101_0000_x.md" <<'EOF'
---
feature: x
---

## Codify Decisions

(まだ何も無い)

## Notes

記述例:

```markdown
## Codify Decisions

### Insight 9
- **Decision**: codified
- **Destination**: rule
```

## Codify Decisions

### Insight 1
- **Decision**: codified
- **Destination**: rule

### Insight 2（補足）
- **Decision**: codified
- **Destination**: rule
EOF
run_landing "$FX"
expect_set "TC-04b: second section counted, fence ignored, 'Insight 2（補足）' is #2" "20260101_0000 #1
20260101_0000 #2"

# ---------------------------------------------------------------------------
# TC-05
# ---------------------------------------------------------------------------
echo ""
echo "TC-05: only codified + rule destinations are targets"
mk_fixture tc05
{
  printf '## Codify Decisions\n\n'
  ins 1 no-codify rule
  ins 2 deferred rule
  ins 3 codified inline-update
  ins 4 codified skill
  ins 5 codified new-cycle
  ins 6 codified 'rule (rules/x.md + .claude/rules/ mirror)'
} | mk_doc "$FX" 20260101_0000
run_landing "$FX"
expect_set "TC-05: only the codified rule insight (#6) is reported" "20260101_0000 #6"

# ---------------------------------------------------------------------------
# TC-06
# ---------------------------------------------------------------------------
echo ""
echo "TC-06: three false-landing patterns stay unlanded"
# (a) #12 は #1 の着地ではない
mk_fixture tc06a
{ printf '## Codify Decisions\n\n'; ins 1 codified rule; } | mk_doc "$FX" 20260101_0000
mk_rule "$FX" rules x.md '- 条項 (20260101_0000 #12)'
run_landing "$FX"
expect_set "TC-06a: '#12' does not land #1" "20260101_0000 #1"
# (b) 1 行に 2 つの cycle id。#2 は直前の cycle id に結び付く
mk_fixture tc06b
{ printf '## Codify Decisions\n\n'; ins 1 codified rule; ins 2 codified rule; } | mk_doc "$FX" 20260101_0000
{ printf '## Codify Decisions\n\n'; ins 2 codified rule; } | mk_doc "$FX" 20260202_0000
mk_rule "$FX" rules x.md '- 条項 (20260101_0000 #1, 20260202_0000 #2)'
run_landing "$FX"
expect_set "TC-06b: '<idA> #1, <idB> #2' lands idA #1 and idB #2 only" "20260101_0000 #2"
# (c) 別の cycle の同じ番号
mk_fixture tc06c
{ printf '## Codify Decisions\n\n'; ins 1 codified rule; } | mk_doc "$FX" 20260303_0000
mk_rule "$FX" rules x.md '- 条項 (20260909_0000 #1)'
run_landing "$FX"
expect_set "TC-06c: same number from another cycle does not land" "20260303_0000 #1"

# ---------------------------------------------------------------------------
# TC-07
# ---------------------------------------------------------------------------
echo ""
echo "TC-07: consumer layout (.claude/rules/ only, no rules/)"
mk_fixture tc07
{ printf '## Codify Decisions\n\n'; ins 1 codified rule; } | mk_doc "$FX" 20260101_0000
mk_rule "$FX" .claude/rules local-x.md '- 条項 (20260101_0000 #1)'
run_landing "$FX"
expect_set "TC-07: landed through .claude/rules/ only" ""
# rules が一切ない repo でも落ちずに未着地を出す
mk_fixture tc07b
{ printf '## Codify Decisions\n\n'; ins 1 codified rule; } | mk_doc "$FX" 20260101_0000
run_landing "$FX"
expect_set "TC-07: repo without any rules dir reports unlanded and exits 0" "20260101_0000 #1"

# ---------------------------------------------------------------------------
# TC-08
# ---------------------------------------------------------------------------
echo ""
echo "TC-08: withdrawal ledger (reason required)"
mk_fixture tc08
{ printf '## Codify Decisions\n\n'; ins 1 codified rule; ins 2 codified rule; } | mk_doc "$FX" 20260101_0000
printf '%s\n' '# withdrawn' '' '- 20260101_0000 #1 — 消えた仕組みに依存 (abc1234)' '- 20260101_0000 #2' > "$FX/docs/codify-withdrawn.md"
run_landing "$FX"
expect_set "TC-08: #1 (with reason) is landed, #2 (no reason) is reported" "20260101_0000 #2"

# ---------------------------------------------------------------------------
# TC-09
# ---------------------------------------------------------------------------
echo ""
echo "TC-09: one '<cycle_id> #N' per line; --count prints only the number"
mk_fixture tc09
{ printf '## Codify Decisions\n\n'; ins 1 codified rule; ins 2 codified rule; } | mk_doc "$FX" 20260101_0000
run_landing "$FX"
expect_set "TC-09: two lines" "20260101_0000 #1
20260101_0000 #2"
run_landing "$FX" --count
expect_count "TC-09: --count prints 2" 2

# ---------------------------------------------------------------------------
# TC-16: Insight 以外の ### 見出しは直前の insight の判定を上書きしない
# ---------------------------------------------------------------------------
echo ""
echo "TC-16: a non-Insight ### heading does not overwrite the previous insight"
mk_fixture tc16a
{
  printf '## Codify Decisions\n\n'; ins 1 codified rule
  printf '### 成功事例\n- **Decision**: no-codify\n'
} | mk_doc "$FX" 20260101_0000
run_landing "$FX"
expect_set "TC-16a: codified #1 stays a target after a following non-Insight heading" "20260101_0000 #1"

mk_fixture tc16b
{
  printf '## Codify Decisions\n\n'; ins 1 no-codify -
  printf '### Observation（成功事例）\n- **Decision**: codified\n- **Destination**: rule\n'
} | mk_doc "$FX" 20260101_0000
run_landing "$FX"
expect_set "TC-16b: a non-Insight heading is not counted as an insight" ""

# ---------------------------------------------------------------------------
# TC-17: 出典の行にある無関係な #N（PR #2 など）は着地とみなさない
# ---------------------------------------------------------------------------
echo ""
echo "TC-17: an unrelated '#N' later on the citation line does not land another insight"
mk_fixture tc17
{ printf '## Codify Decisions\n\n'; ins 1 codified rule; ins 2 codified rule; } | mk_doc "$FX" 20260101_0000
mk_rule "$FX" rules x.md '- 条項 (20260101_0000 #1。PR #2 で修正)'
run_landing "$FX"
expect_set "TC-17: PR #2 on the same line leaves #2 unlanded" "20260101_0000 #2"

# ---------------------------------------------------------------------------
# TC-18: 4 連バッククォートの fence の中の ``` で fence 判定が反転しない
# ---------------------------------------------------------------------------
echo ""
echo "TC-18: a four-backtick fence containing a three-backtick line closes only on its own length"
mk_fixture tc18
mkdir -p "$FX/docs/cycles"
{
  printf '````md\n```\n````\n\n'
  printf '## Codify Decisions\n\n'; ins 1 codified rule
} > "$FX/docs/cycles/20260101_0000_x.md"
run_landing "$FX"
expect_set "TC-18: the real section after the fence is counted" "20260101_0000 #1"

# ---------------------------------------------------------------------------
# TC-19: ~~~ の fence も同じ文字・開いた長さ以上でだけ閉じる
# ---------------------------------------------------------------------------
echo ""
echo "TC-19: tilde fences hide fake sections; mixed fence characters do not flip the state"
mk_fixture tc19a
{
  printf '~~~md\n## Codify Decisions\n\n'; ins 7 codified rule
  printf '~~~\n\n'
  printf '## Codify Decisions\n\n'; ins 1 codified rule
} > "$FX/docs/cycles/20260101_0000_x.md"
run_landing "$FX"
expect_set "TC-19a: a fake section inside a ~~~ fence is not counted, the real one is" "20260101_0000 #1"

mk_fixture tc19b
{
  printf '~~~~md\n~~~\n## Codify Decisions\n\n'; ins 7 codified rule
  printf '~~~~\n\n'
  printf '## Codify Decisions\n\n'; ins 1 codified rule
} > "$FX/docs/cycles/20260101_0000_x.md"
run_landing "$FX"
expect_set "TC-19b: a ~~~ line inside a ~~~~ fence does not close it" "20260101_0000 #1"

mk_fixture tc19c
{
  printf '## Codify Decisions\n\n'
  printf '```md\n~~~\n'; ins 7 codified rule
  printf '```\n\n'; ins 1 codified rule
} > "$FX/docs/cycles/20260101_0000_x.md"
run_landing "$FX"
expect_set "TC-19c: a ~~~ line inside a backtick fence does not close it" "20260101_0000 #1"

mk_fixture tc19d
{
  printf '## Codify Decisions\n\n'
  printf '~~~md\n```\n'; ins 7 codified rule
  printf '~~~\n\n'; ins 1 codified rule
} > "$FX/docs/cycles/20260101_0000_x.md"
run_landing "$FX"
expect_set "TC-19d: a backtick line inside a ~~~ fence does not close it" "20260101_0000 #1"

# ---------------------------------------------------------------------------
# TC-11
# ---------------------------------------------------------------------------
echo ""
echo "TC-11: real working tree has no unlanded codified rule insights"
run_landing "$BASE_DIR" --count
expect_count "TC-11: codify-landing.sh \$BASE_DIR --count prints 0" 0

# ---------------------------------------------------------------------------
# TC-12
# ---------------------------------------------------------------------------
echo ""
echo "TC-12: every ledger line has a reason, a pointer to the vanished mechanism, and a real insight"

# codified_rule_nums <cycle doc>: コードブロックの外の Codify Decisions 節で codified・rule の番号を出す
codified_rule_nums() {
  awk '
    /^```/ {fence = !fence; next}
    fence {next}
    /^## / {sec = ($0 ~ /^## Codify Decisions/); n = ""; next}
    !sec {next}
    /^### Insight [0-9]+/ {
      s = $0; sub(/^### Insight /, "", s); sub(/[^0-9].*$/, "", s); n = s; dec[n] = ""; dst[n] = ""; next
    }
    n != "" && /^- \*\*Decision\*\*:/ { v = $0; sub(/^- \*\*Decision\*\*:[ ]*/, "", v); dec[n] = v }
    n != "" && /^- \*\*Destination\*\*:/ { v = $0; sub(/^- \*\*Destination\*\*:[ ]*/, "", v); dst[n] = v }
    END { for (k in dec) if (dec[k] ~ /^codified/ && dst[k] ~ /^rule/) print k }
  ' "$1"
}

if [ ! -f "$LEDGER" ]; then
  fail "TC-12: docs/codify-withdrawn.md does not exist"
else
  tc12_ok=true
  tc12_entries=0
  ENTRY_RE='^-[[:space:]]+([0-9]{8}_[0-9]{4})[[:space:]]+#([0-9]+)([[:space:]]+—[[:space:]]*(.*))?$'
  while IFS= read -r line; do
    case "$line" in
      "- "[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]_[0-9][0-9][0-9][0-9]*) ;;
      *) continue ;;
    esac
    tc12_entries=$((tc12_entries + 1))
    if ! [[ "$line" =~ $ENTRY_RE ]]; then
      fail "TC-12: malformed ledger line: $line"; tc12_ok=false; continue
    fi
    cid="${BASH_REMATCH[1]}"; num="${BASH_REMATCH[2]}"; reason="${BASH_REMATCH[4]:-}"
    if [ -z "${reason// /}" ]; then
      fail "TC-12: $cid #$num has no reason"; tc12_ok=false; continue
    fi
    # 消えた仕組みを指す commit hash（数字を含む 7〜40 桁の 16 進）かパス（/ を含む、または .md / .sh で終わる語）
    hash_hit=$(printf '%s\n' "$reason" | grep -oE '(^|[^0-9A-Za-z])[0-9a-f]{7,40}([^0-9A-Za-z]|$)' | grep -E '[0-9]' || true)
    path_hit=$(printf '%s\n' "$reason" | grep -oE '[A-Za-z0-9_.-]+/[A-Za-z0-9_./-]+|[A-Za-z0-9_-]+\.(md|sh)' || true)
    if [ -z "$hash_hit" ] && [ -z "$path_hit" ]; then
      fail "TC-12: $cid #$num reason has neither a commit hash nor a path"; tc12_ok=false; continue
    fi
    doc=$(ls "$BASE_DIR/docs/cycles/${cid}_"*.md 2>/dev/null | head -1 || true)
    if [ -z "$doc" ]; then
      fail "TC-12: $cid #$num points to a cycle doc that does not exist"; tc12_ok=false; continue
    fi
    nums=$(codified_rule_nums "$doc")
    if ! grep -qxF "$num" <<< "$nums"; then
      fail "TC-12: $cid #$num is not a codified / rule insight in $(basename "$doc")"; tc12_ok=false
    fi
  done < "$LEDGER"
  if [ "$tc12_entries" -eq 0 ]; then
    fail "TC-12: ledger has no '- <cycle_id> #N — 理由' line"
  elif [ "$tc12_ok" = "true" ]; then
    pass "TC-12: all $tc12_entries ledger lines have reason + pointer + real codified/rule insight"
  fi
fi

# ---------------------------------------------------------------------------
# TC-13
# ---------------------------------------------------------------------------
echo ""
echo "TC-13: four orchestrate docs share the same landing code block"
LANDING_CALL='bash "<orchestrate の Base directory>/../../scripts/codify-landing.sh" . --count'
tc13_ref=""
tc13_ok=true
for spec in "SKILL.md:$SKILL_MD:skill" "reference.md:$REF_MD:ref" "steps-subagent.md:$STEPS_SUB_MD:steps" "steps-teams.md:$STEPS_TEAMS_MD:steps"; do
  label="${spec%%:*}"; rest="${spec#*:}"; file="${rest%%:*}"; kind="${rest##*:}"
  if [ ! -f "$file" ]; then fail "TC-13: $label does not exist"; tc13_ok=false; continue; fi
  case "$kind" in
    skill) sec=$(sec_skill_notice "$file") ;;
    ref)   sec=$(sec_h2 "$file" "Block 0 Pre-Check") ;;
    steps) sec=$(sec_steps_notice "$file") ;;
  esac
  block=$(printf '%s\n' "$sec" | fence_with 'codify-landing.sh')
  if [ -z "$block" ]; then
    fail "TC-13: $label Block 0 has no code block calling codify-landing.sh"; tc13_ok=false; continue
  fi
  if ! grep -qxF "$LANDING_CALL" <<< "$block"; then
    fail "TC-13: $label landing block lacks the line: $LANDING_CALL"; tc13_ok=false
  fi
  if ! grep -qE '未着地.*通知しない|通知しない.*未着地' <<< "$sec"; then
    fail "TC-13: $label Block 0 does not say that 0 unlanded means no notice (未着地 ... 通知しない)"; tc13_ok=false
  fi
  if [ -z "$tc13_ref" ]; then
    tc13_ref="$block"
  elif [ "$block" != "$tc13_ref" ]; then
    fail "TC-13: $label landing block differs from SKILL.md"; tc13_ok=false
  fi
done
if [ -f "$SKILL_MD" ]; then
  skill_lines=$(wc -l < "$SKILL_MD" | tr -d ' ')
  if [ "$skill_lines" -gt 100 ]; then
    fail "TC-13: orchestrate/SKILL.md is $skill_lines lines (limit 100)"; tc13_ok=false
  fi
fi
if [ "$tc13_ok" = "true" ]; then
  pass "TC-13: SKILL.md / reference.md / steps-subagent.md / steps-teams.md share one landing block; SKILL.md <= 100 lines"
fi

# ---------------------------------------------------------------------------
# TC-13b
# ---------------------------------------------------------------------------
echo ""
echo "TC-13b: landing block from SKILL.md runs in a consumer-shaped repo and prints one integer"
mk_fixture tc13b
{ printf '## Codify Decisions\n\n'; ins 1 codified rule; ins 2 codified rule; } | mk_doc "$FX" 20260101_0000
mk_rule "$FX" .claude/rules local-x.md '- 条項 (20260101_0000 #1)'
SKILL_LANDING=""
[ -f "$SKILL_MD" ] && SKILL_LANDING=$(sec_skill_notice "$SKILL_MD" | fence_with 'codify-landing.sh')
if [ -z "$SKILL_LANDING" ]; then
  fail "TC-13b: no landing block in orchestrate/SKILL.md Block 0"
else
  PLACEHOLDER='<orchestrate の Base directory>'
  REAL_BASE="$BASE_DIR/skills/orchestrate"
  cmd="${SKILL_LANDING//$PLACEHOLDER/$REAL_BASE}"
  out=$(cd "$FX" && bash -o pipefail -c "$cmd" 2>"$TMP/err13b")
  rc=$?
  if [ "$rc" -ne 0 ]; then
    fail "TC-13b: landing block rc=$rc stderr='$(cat "$TMP/err13b")'"
  elif [ "$out" != "1" ]; then
    fail "TC-13b: landing block output '$out' (expected single integer 1)"
  else
    pass "TC-13b: landing block printed 1 for the consumer-shaped fixture"
  fi
fi

# ---------------------------------------------------------------------------
# TC-14
# ---------------------------------------------------------------------------
echo ""
echo "TC-14: Rule Tier Contract names the citation form and the withdrawal ledger"
tc14_sec=""
[ -f "$CODIFY_REF_MD" ] && tc14_sec=$(sec_h2 "$CODIFY_REF_MD" "Rule Tier Contract")
if [ -z "$tc14_sec" ]; then
  fail "TC-14: '## Rule Tier Contract' section not found"
elif ! grep -qF '(<cycle_id> #N)' <<< "$tc14_sec"; then
  fail "TC-14: Rule Tier Contract lacks '(<cycle_id> #N)'"
elif ! grep -qF 'docs/codify-withdrawn.md' <<< "$tc14_sec"; then
  fail "TC-14: Rule Tier Contract lacks 'docs/codify-withdrawn.md'"
else
  pass "TC-14: Rule Tier Contract names '(<cycle_id> #N)' and docs/codify-withdrawn.md"
fi

# ---------------------------------------------------------------------------
# TC-15
# ---------------------------------------------------------------------------
echo ""
echo "TC-15: rules/shell-scripts.md frontmatter"
if [ ! -f "$SHELL_RULE" ]; then
  fail "TC-15: rules/shell-scripts.md does not exist"
else
  first=$(head -1 "$SHELL_RULE")
  # 値は行ごとに取り出し、完全一致で比べる（部分文字列だと '**/*.sh' が '**/*' に当たる）
  vals=$(awk '
    NR == 1 {next}
    /^---$/ {exit}
    /^paths:/ {p = 1; next}
    p && /^[[:space:]]*-[[:space:]]/ {sub(/^[[:space:]]*-[[:space:]]*/, ""); gsub(/"/, ""); print; next}
    p && /^[^[:space:]]/ {p = 0}
  ' "$SHELL_RULE" | sed "s/'//g")
  tc15_ok=true
  if [ "$first" != "---" ]; then
    fail "TC-15: line 1 is '$first' (expected '---')"; tc15_ok=false
  fi
  for want in '**/*.sh' 'scripts/**' 'skills/**'; do
    if ! grep -qxF -- "$want" <<< "$vals"; then
      fail "TC-15: paths lacks '$want'"; tc15_ok=false
    fi
  done
  for bad in '**' '**/*'; do
    if grep -qxF -- "$bad" <<< "$vals"; then
      fail "TC-15: paths has repo-wide glob '$bad'"; tc15_ok=false
    fi
  done
  if [ "$tc15_ok" = "true" ]; then
    pass "TC-15: frontmatter starts at line 1, paths = {**/*.sh, scripts/**, skills/**} without repo-wide globs"
  fi
fi

echo ""
echo "=== Summary ==="
echo "PASS: $PASS"
echo "FAIL: $FAIL"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
