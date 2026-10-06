#!/bin/bash
# test-local-rules-separation.sh - 導入先独自 rule(`.claude/rules/local-*.md`) を onboard の同期から
# 守る契約と、plan-discipline の baseline 手順の一般化を pin する。
#
# 節は awk で先に切り出してから grep する。BASE_DIR は env で差し替えられる（退行の実証用）。

set -uo pipefail

BASE_DIR="${BASE_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

# section FILE HEADING_PREFIX
# HEADING_PREFIX で始まる見出し行から、同じか上位の見出し（# の数が同数以下）の直前までを出力する。
# コードフェンス内の `#` 行は見出し扱いしない。見出しの照合は index() の fixed-string 前方一致。
section() {
  awk -v h="$2" '
    /^```/ { fence = !fence }
    f && !fence && match($0, /^#+ /) && RLENGTH - 1 <= n { exit }
    !f && index($0, h) == 1 { f = 1; match(h, /^#+/); n = RLENGTH }
    f { print }
  ' "$1"
}

# require_all LABEL TEXT PHRASE...  : TEXT が全 PHRASE を fixed-string で含めば PASS
require_all() {
  local label="$1" text="$2" missing="" w
  shift 2
  if [ -z "$text" ]; then
    fail "$label (section not found or empty)"
    return
  fi
  for w in "$@"; do
    if ! grep -qF -- "$w" <<<"$text"; then
      missing="$missing [$w]"
    fi
  done
  if [ -z "$missing" ]; then
    pass "$label"
  else
    fail "$label (missing:$missing)"
  fi
}

# require_line LABEL TEXT PHRASE...  : 全 PHRASE を同じ 1 行に含む行が TEXT にあれば PASS
require_line() {
  local label="$1" text="$2" line w ok
  shift 2
  if [ -z "$text" ]; then
    fail "$label (section not found or empty)"
    return
  fi
  while IFS= read -r line; do
    ok=1
    for w in "$@"; do
      case "$line" in *"$w"*) ;; *) ok=0; break ;; esac
    done
    if [ "$ok" -eq 1 ]; then
      pass "$label"
      return
    fi
  done <<<"$text"
  fail "$label (no single line has all of: $*)"
}

line_count() { wc -l <"$1" | tr -d ' '; }

ONBOARD_REF="$BASE_DIR/skills/onboard/reference.md"
ONBOARD_SKILL="$BASE_DIR/skills/onboard/SKILL.md"
CODIFY_REF="$BASE_DIR/skills/codify-insight/reference.md"
SPEC_SKILL="$BASE_DIR/skills/spec/SKILL.md"
COMMIT_SKILL="$BASE_DIR/skills/commit/SKILL.md"
PD_FILES=("$BASE_DIR/rules/plan-discipline.md" "$BASE_DIR/.claude/rules/plan-discipline.md")

echo "=== local rules separation Tests ==="

STEP6=$(section "$ONBOARD_REF" "## Step 6:")

# TC-01
# Given onboard reference の Step 6
# When local- の命名規約と同期時の扱いを探す
# Then 命名規約があり、「通常の同期では」local-*.md を作成・上書き・削除しない旨が同じ行にある
echo ""
echo "TC-01: onboard Step 6 documents local- naming and that normal sync never touches it"
require_all "TC-01: naming convention" "$STEP6" ".claude/rules/local-"
require_line "TC-01: 通常の同期では local-*.md を作成・上書き・削除しない" "$STEP6" \
  "通常の同期では" "local-*.md" "作成・上書き・削除しない"

# TC-02
# Given onboard reference の Step 6
# When 既存ファイル更新時の「差分を表示し」の行を探す
# Then その行と同じ段落（空行・見出しまで）に local- への移動の案内と 2-way diff の限界（区別できない）がある。
#      負側: 節内に「初回のみ」も移行の小見出し（#### ）もない
echo ""
echo "TC-02: existing-file update line guides moving local lines to local- and states the 2-way diff limit"
ctx=$(awk '
  !n && index($0, "差分を表示し") { n = 1 }
  n && (/^$/ || /^#/) && started { exit }
  n { print; started = 1 }
' <<<"$STEP6")
require_all "TC-02: 差分を表示し の近傍に local- への移動案内" "$ctx" "差分を表示し" "local-"
require_line "TC-02: 置き換える前に local-<name>.md へ移す（順序）" "$ctx" \
  '置き換える前に `local-<name>.md` へ移す'
require_all "TC-02: 差分を表示し の近傍に 2-way diff の限界" "$ctx" "2-way diff" "区別できない"
first_only=$(grep -cF "初回のみ" <<<"$STEP6" || true)
sub_heads=$(grep -c '^#### ' <<<"$STEP6" || true)
if [ -z "$STEP6" ]; then
  fail "TC-02: section not found or empty"
else
  if [ "$first_only" -eq 0 ]; then pass "TC-02: no 初回のみ in Step 6"; else fail "TC-02: Step 6 has $first_only 初回のみ"; fi
  if [ "$sub_heads" -eq 0 ]; then pass "TC-02: no #### migration subheading in Step 6"; else fail "TC-02: Step 6 has $sub_heads #### subheading(s)"; fi
fi

# TC-02c
# Given onboard reference の Step 6
# When local- の scope 規約を探す
# Then paths あり=同じ値、なし=frontmatter なし(always) の両方がある
echo ""
echo "TC-02c: local- scope convention covers both paths: present and absent"
require_all "TC-02c: 同じ値 + frontmatter なし + always" "$STEP6" \
  "同じ値" "frontmatter なし" "always"

# TC-03
# Given onboard SKILL.md
# When Step 6 の rules の行を読む
# Then local-*.md を対象外とする記述があり、SKILL.md は 100 行未満
echo ""
echo "TC-03: onboard SKILL.md Step 6 excludes local- and stays under 100 lines"
SKILL_STEP6=$(section "$ONBOARD_SKILL" "### Step 6:")
require_all "TC-03: SKILL.md Step 6 excludes local-*.md" "$SKILL_STEP6" '`local-*.md` は対象外'
n=$(line_count "$ONBOARD_SKILL")
if [ "$n" -lt 100 ]; then
  pass "TC-03: onboard SKILL.md is $n lines (<100)"
else
  fail "TC-03: onboard SKILL.md is $n lines (>=100)"
fi

# TC-04
# Given codify-insight reference の Rule Tier Contract
# When 反映先の判定を読む
# Then plugin.json の name が dev-crew かで分け、rules/ の有無では判定しない。導入先は mirror に書かない
echo ""
echo "TC-04: codify-insight Rule Tier Contract splits dev-crew itself vs consumer by plugin.json name"
TIER=$(section "$CODIFY_REF" "## Rule Tier Contract")
require_all "TC-04: 判定は name が dev-crew、rules/ の有無では判定しない、mirror には書かない" "$TIER" \
  '`name` が `dev-crew`' "の有無では判定しない" "mirror には書かない" ".claude/rules/local-<name>.md"

# TC-05
# Given spec SKILL.md と commit SKILL.md
# When rule の Read 指示を読む
# Then spec は local-plan-discipline.md、commit は local-git-conventions.md の Read に触れ、どちらも 100 行未満
echo ""
echo "TC-05: spec/commit SKILL.md read the matching local- counterpart and stay under 100 lines"
for pair in "$SPEC_SKILL|local-plan-discipline.md" "$COMMIT_SKILL|local-git-conventions.md"; do
  f="${pair%%|*}"
  want="${pair##*|}"
  name="${f#"$BASE_DIR"/}"
  content=$(cat "$f")
  require_all "TC-05: $name mentions $want" "$content" "$want"
  n=$(line_count "$f")
  if [ "$n" -lt 100 ]; then
    pass "TC-05: $name is $n lines (<100)"
  else
    fail "TC-05: $name is $n lines (>=100)"
  fi
done

# TC-06
# Given rules/plan-discipline.md と mirror
# When ## 推奨 の baseline 行を読む
# Then Quick Commands / Quick Start / run-tests.sh をすべて含む
echo ""
echo "TC-06: plan-discipline recommendation references Quick Commands, Quick Start and run-tests.sh"
for f in "${PD_FILES[@]}"; do
  name="${f#"$BASE_DIR"/}"
  rec=$(section "$f" "## 推奨")
  require_all "TC-06: $name ## 推奨" "$rec" "Quick Commands" "Quick Start" "run-tests.sh"
done

# TC-07 (negative)
# Given 同じ 2 ファイルの ## 推奨
# When run-tests.sh を含む行を全て調べる
# Then どの行も Quick Commands か Quick Start も含む（run-tests.sh の無条件指示が残っていない）
echo ""
echo "TC-07: every run-tests.sh line in plan-discipline recommendation is tied to Quick Commands or Quick Start"
for f in "${PD_FILES[@]}"; do
  name="${f#"$BASE_DIR"/}"
  rec=$(section "$f" "## 推奨")
  if [ -z "$rec" ]; then
    fail "TC-07: $name ## 推奨 section not found"
    continue
  fi
  rt=$(grep -F "run-tests.sh" <<<"$rec" || true)
  bad=$(grep -vF -e "Quick Commands" -e "Quick Start" <<<"$rt" || true)
  if [ -z "$rt" ]; then
    fail "TC-07: $name has no run-tests.sh line (TC-06 contract)"
  elif [ -z "$bad" ]; then
    pass "TC-07: $name run-tests.sh lines all mention Quick Commands or Quick Start"
  else
    fail "TC-07: $name has run-tests.sh line without Quick Commands/Quick Start"
  fi
done

# TC-08
# Given 同じ 2 ファイルの ## 具体例
# When 例の注記を探す
# Then 「dev-crew 本体の例」の注記がある
echo ""
echo "TC-08: plan-discipline example section is annotated as the dev-crew itself example"
for f in "${PD_FILES[@]}"; do
  name="${f#"$BASE_DIR"/}"
  ex=$(section "$f" "## 具体例")
  require_all "TC-08: $name ## 具体例" "$ex" "dev-crew 本体の例"
done

echo ""
echo "PASS: $PASS, FAIL: $FAIL"
[ $FAIL -eq 0 ] && exit 0 || exit 1
