#!/bin/bash
# test-codex-mode-removed.sh - codex_mode の full（RED/GREEN の Codex 委譲）の経路が消えたことの契約
#
# 「実行手順を書くファイル」= CLAUDE.md・AGENTS.md・rules/*.md・.claude/rules/*.md・agents/*.md・skills/**/*.md
#
# TC-01: skills/orchestrate/steps-codex.md が存在しない
# TC-02: 実行手順を書くファイルと CONSTITUTION/README/workflow/skill-map に codex_mode が無い
# TC-03: 同じ範囲と tests/（このファイル自身を除く）に steps-codex が無い
# TC-04: 全 codex exec 呼び出しが --sandbox read-only を持ち、workspace-write の呼び出しが 0 件
# TC-05: steps-subagent/teams の REVIEW 節に Codex 呼び出しがちょうど 1 つ（read-only + -o の出力先）
# TC-06: orchestrate/SKILL.md が挙げるモードは steps-subagent と steps-teams の 2 つだけ、100 行以下
# TC-07: spec の reference.md / reference.ja.md から委譲確認（full/no）と「RED 以降」が消え、sync-plan と architect は残る
# TC-08: CONSTITUTION §4 の原則 3・4 の文言と、ADR adr-codex-review-only.md
# TC-09: --full-auto が無く、どの codex exec 呼び出しも < /dev/null を伴う（移設: 旧 codex-session-unify TC-08）
# TC-10: REVIEW 節に対象の列挙 2 コマンドと「再レビューしない」がある（移設: 旧 steps-codex-improvements T-01/T-02）
# TC-11: onboard/reference.md の Codex テンプレートとセットアップガイダンスが read-only + < /dev/null
#
# codex exec の呼び出しは「行末 \ の継続行を連結 → "codex exec" で分割 → 最初の backtick か次の
# codex exec で切る」で 1 つずつ取り出す。引用符付きの prompt を持つものだけを呼び出しとみなす
# （`codex exec` という名前だけの言及は対象にしない）。1 行に 2 つあっても 1 つずつ判定する。

set -uo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SELF_NAME="$(basename "$0")"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

# has <text> <fixed string>: here-string を使い pipefail 下の SIGPIPE を避ける
has() { grep -qF -- "$2" <<< "$1"; }

# 実行手順を書くファイル（BASE_DIR からの相対）
instr_files() {
  (
    cd "$BASE_DIR" || exit 0
    ls CLAUDE.md AGENTS.md rules/*.md .claude/rules/*.md agents/*.md 2>/dev/null
    find skills -name '*.md' 2>/dev/null | sort
  )
}
INSTR=$(instr_files)

# 行末 \ の継続行を 1 行に連結して出力
join_lines() { sed -e ':a' -e '/\\$/N; s/\\\n//; ta' "$1"; }

# stdin のテキストから codex exec の呼び出しを 1 つずつ出力する
segments() {
  awk '{
    s = $0
    # 空白の揺れ（"codex  exec" 等）で呼び出しを見逃さないよう、連続する空白を 1 つにそろえる
    gsub(/[ \t]+/, " ", s)
    while ((i = index(s, "codex exec")) > 0) {
      s = substr(s, i + 10)
      t = s
      j = index(t, "`"); if (j > 0) t = substr(t, 1, j - 1)
      k = index(t, "codex exec"); if (k > 0) t = substr(t, 1, k - 1)
      print "codex exec" t
    }
  }'
}

# 引用符（二重・単一）付きの prompt を持つ呼び出しだけ
real_calls() { grep -E "[\"']" || true; }

# REVIEW 節: "### REVIEW" から次の ## / ### 見出しの前まで
review_section() { awk '/^### REVIEW/{f=1;next} f&&/^(##|###) /{exit} f' "$1"; }

echo "=== Codex Mode Removed Tests ==="

# ---------------------------------------------------------------------------
echo ""
echo "TC-01: steps-codex.md does not exist"
# Given 作業ツリー / When steps-codex.md を探す / Then 存在しない
if [ ! -e "$BASE_DIR/skills/orchestrate/steps-codex.md" ]; then
  pass "TC-01: skills/orchestrate/steps-codex.md is gone"
else
  fail "TC-01: skills/orchestrate/steps-codex.md still exists"
fi

# ---------------------------------------------------------------------------
echo ""
echo "TC-02: no codex_mode in instruction files and top-level docs"
# Given 実行手順を書くファイル + CONSTITUTION/README/workflow/skill-map
# When codex_mode を grep / Then 0 件（docs/cycles と CHANGELOG は対象外）
tc02_files="$INSTR
CONSTITUTION.md
README.md
docs/workflow.md
docs/skill-map.md"
tc02_bad=""
while IFS= read -r f; do
  [ -z "$f" ] && continue
  [ -f "$BASE_DIR/$f" ] || continue
  grep -qF 'codex_mode' "$BASE_DIR/$f" && tc02_bad="$tc02_bad $f"
done <<< "$tc02_files"
if [ -z "$tc02_bad" ]; then
  pass "TC-02: no codex_mode reference"
else
  fail "TC-02: codex_mode remains in:$tc02_bad"
fi

# ---------------------------------------------------------------------------
echo ""
echo "TC-03: no steps-codex reference in instruction files, top-level docs, tests/"
# Given TC-02 と同じ範囲 + tests/（このファイル自身を除く）/ When steps-codex を grep / Then 0 件
tc03_tests=$(cd "$BASE_DIR" && find tests -type f -name '*.sh' | sort)
tc03_bad=""
while IFS= read -r f; do
  [ -z "$f" ] && continue
  [ "$(basename "$f")" = "$SELF_NAME" ] && continue
  [ -f "$BASE_DIR/$f" ] || continue
  grep -qF 'steps-codex' "$BASE_DIR/$f" && tc03_bad="$tc03_bad $f"
done <<< "$tc02_files
$tc03_tests"
if [ -z "$tc03_bad" ]; then
  pass "TC-03: no steps-codex reference"
else
  fail "TC-03: steps-codex remains in:$tc03_bad"
fi

# ---------------------------------------------------------------------------
echo ""
echo "TC-04: every codex exec call is read-only; no workspace-write call"
# Given 実行手順を書くファイル / When 継続行を連結し codex exec を 1 つずつ切り出す
# Then どの呼び出しも --sandbox read-only を含み、workspace-write を含む呼び出しは 0 件
tc04_ro_bad=""
tc04_ww_bad=""
tc04_total=0
while IFS= read -r f; do
  [ -z "$f" ] && continue
  [ -f "$BASE_DIR/$f" ] || continue
  segs=$(join_lines "$BASE_DIR/$f" | segments)
  [ -z "$segs" ] && continue
  while IFS= read -r seg; do
    [ -z "$seg" ] && continue
    # workspace-write は prompt の有無に関わらず禁止
    if has "$seg" 'workspace-write'; then
      tc04_ww_bad="$tc04_ww_bad [$f: $(printf '%s' "$seg" | cut -c1-60)]"
    fi
    # 引用符（二重・単一）付き prompt を持つものが実際の呼び出し
    if has "$seg" '"' || has "$seg" "'"; then
      tc04_total=$((tc04_total + 1))
      has "$seg" '--sandbox read-only' || tc04_ro_bad="$tc04_ro_bad [$f: $(printf '%s' "$seg" | cut -c1-60)]"
      # read-only を併記しても、別経路で sandbox を広げる指定は書き込み権限になる
      if has "$seg" 'danger-full-access' || has "$seg" 'sandbox_mode' \
        || has "$seg" 'dangerously-bypass' || has "$seg" ' -s '; then
        tc04_ww_bad="$tc04_ww_bad [$f: $(printf '%s' "$seg" | cut -c1-60)]"
      fi
    fi
  done <<< "$segs"
done <<< "$INSTR"
if [ "$tc04_total" -eq 0 ]; then
  fail "TC-04: no codex exec call found (vacuous)"
elif [ -n "$tc04_ro_bad" ] || [ -n "$tc04_ww_bad" ]; then
  fail "TC-04: not read-only:${tc04_ro_bad} workspace-write:${tc04_ww_bad}"
else
  pass "TC-04: all $tc04_total codex exec calls are --sandbox read-only"
fi

# ---------------------------------------------------------------------------
echo ""
echo "TC-05: REVIEW section of steps-subagent/teams has exactly one read-only Codex call with -o"
# Given steps-subagent.md と steps-teams.md の REVIEW 節
# Then which codex があり、codex exec がちょうど 1 つで --sandbox read-only と
#      -o "/tmp/dev-crew-review-<cycle_id>/review.md" を持ち、「resume しない」と
#      dev-crew:green-worker があり、「Codex への起動文字列」が無い
OUT_PATH='-o "/tmp/dev-crew-review-<cycle_id>/review.md"'
for mode in steps-subagent steps-teams; do
  f="skills/orchestrate/$mode.md"
  sec=$(review_section "$BASE_DIR/$f" 2>/dev/null)
  bad=""
  if [ -z "$sec" ]; then
    bad="$bad [REVIEW 節が取れない]"
  else
    has "$sec" 'which codex' || bad="$bad [which codex なし]"
    n=$(grep -o 'codex exec' <<< "$sec" | wc -l | tr -d ' ')
    [ "$n" -eq 1 ] || bad="$bad [codex exec が $n 個（期待 1）]"
    call=$(join_lines <(printf '%s\n' "$sec") | segments | real_calls | head -1)
    if [ -z "$call" ]; then
      bad="$bad [引用符付きの codex exec 呼び出しなし]"
    else
      has "$call" '--sandbox read-only' || bad="$bad [呼び出しに --sandbox read-only なし]"
      has "$call" "$OUT_PATH" || bad="$bad [呼び出しに $OUT_PATH なし]"
    fi
    has "$sec" 'resume しない' || bad="$bad [「resume しない」なし]"
    has "$sec" 'dev-crew:green-worker' || bad="$bad [dev-crew:green-worker なし]"
    has "$sec" 'Codex への起動文字列' && bad="$bad [「Codex への起動文字列」が残っている]"
  fi
  if [ -z "$bad" ]; then
    pass "TC-05: $mode REVIEW section ok"
  else
    fail "TC-05: $mode:$bad"
  fi
done

# ---------------------------------------------------------------------------
echo ""
echo "TC-06: orchestrate/SKILL.md lists only steps-subagent and steps-teams, <= 100 lines"
# Given orchestrate/SKILL.md / When steps-*.md へのリンクを集める
# Then 一意なリンク先が steps-subagent.md と steps-teams.md の 2 つだけ、かつ 100 行以下
skill="$BASE_DIR/skills/orchestrate/SKILL.md"
links=$(grep -oE '\]\(steps-[A-Za-z0-9_-]+\.md\)' "$skill" | sort -u || true)
expected=$(printf '%s\n%s\n' '](steps-subagent.md)' '](steps-teams.md)' | sort -u)
lines=$(wc -l < "$skill" | tr -d ' ')
if [ "$links" = "$expected" ]; then
  pass "TC-06a: mode list is exactly steps-subagent.md and steps-teams.md"
else
  fail "TC-06a: mode links are: $(printf '%s' "$links" | tr '\n' ' ')"
fi
if [ "$lines" -le 100 ]; then
  pass "TC-06b: SKILL.md is $lines lines (<= 100)"
else
  fail "TC-06b: SKILL.md is $lines lines (> 100)"
fi

# ---------------------------------------------------------------------------
echo ""
echo "TC-07: spec reference(.ja).md have no delegation question nor 'RED 以降'; sync-plan/architect stay"
# Given spec の reference.md / reference.ja.md
# Then 「(full/no)」と「RED 以降」が無く、Post-Approve Action の sync-plan と architect の行は残る
for f in skills/spec/reference.md skills/spec/reference.ja.md; do
  path="$BASE_DIR/$f"
  bad=""
  grep -qF 'full/no' "$path" && bad="$bad [full/no が残っている]"
  grep -qF 'RED 以降' "$path" && bad="$bad [「RED 以降」が残っている]"
  # Post-Approve Action 節: 見出しから次の ## 見出し か fence 終端まで
  pa=$(awk '/^## Post-Approve Action/{f=1;next} f&&(/^## /||/^```/){exit} f' "$path")
  if [ -z "$pa" ]; then
    bad="$bad [Post-Approve Action 節が取れない]"
  else
    grep -qE '^- sync-plan' <<< "$pa" || bad="$bad [sync-plan の行なし]"
    grep -qE '^- architect' <<< "$pa" || bad="$bad [architect の行なし]"
  fi
  if [ -z "$bad" ]; then
    pass "TC-07: $f"
  else
    fail "TC-07: $f:$bad"
  fi
done

# ---------------------------------------------------------------------------
echo ""
echo "TC-08: CONSTITUTION §4 principles 3/4 and the ADR"
# Given CONSTITUTION.md §4 / Then 原則 3・4 に「Implementer」「優先委譲」が無い。
# 原則 4 に codex_unavailable（plan review の skip、Codex が無いとき）と
# adversarial-reviewer（code REVIEW の代行）の両方がある。
# 「失敗」で plan review を skip する文が無い:
#   判定方法: 原則 4 の項を「。」「；」で文に分け、「失敗」を含む文が
#   skip / スキップ / codex_unavailable のどれかも含んでいたら落とす。
#   「失敗」を含む文は adversarial-reviewer と REVIEW を含み、plan に触れてはならない
#   （「Codex が失敗したときの code の REVIEW も adversarial-reviewer が代行する」は通る）
const="$BASE_DIR/CONSTITUTION.md"
s4=$(awk '/^## 4\./{f=1;next} f&&/^## /{exit} f' "$const")
p3=$(awk '/^3\. /{f=1;print;next} f&&/^[0-9]+\. /{exit} f&&NF==0{exit} f' <<< "$s4")
p4=$(awk '/^4\. /{f=1;print;next} f&&/^[0-9]+\. /{exit} f&&NF==0{exit} f' <<< "$s4")
if [ -z "$p3" ] || [ -z "$p4" ]; then
  fail "TC-08: principle 3 or 4 not found in §4"
else
  bad=""
  has "$p3$p4" 'Implementer' && bad="$bad [Implementer が残っている]"
  has "$p3$p4" '優先委譲' && bad="$bad [優先委譲が残っている]"
  has "$p4" 'codex_unavailable' || bad="$bad [原則 4 に codex_unavailable なし]"
  has "$p4" 'adversarial-reviewer' || bad="$bad [原則 4 に adversarial-reviewer なし]"
  sentences=$(printf '%s' "$p4" | sed -e 's/。/\
/g' -e 's/；/\
/g')
  while IFS= read -r s; do
    [ -z "$s" ] && continue
    if has "$s" '失敗' && { has "$s" 'skip' || has "$s" 'スキップ' || has "$s" 'codex_unavailable'; }; then
      bad="$bad [「失敗」で skip する文: $(printf '%s' "$s" | cut -c1-60)]"
    fi
    # 「失敗」の文は code の REVIEW を adversarial-reviewer が代行する文に限る。
    # plan review を持ち出す文（省略・行わない 等の言い換えを含む）は、skip 語が無くても落とす
    if has "$s" '失敗'; then
      has "$s" 'adversarial-reviewer' || bad="$bad [「失敗」の文に adversarial-reviewer なし: $(printf '%s' "$s" | cut -c1-60)]"
      has "$s" 'REVIEW' || bad="$bad [「失敗」の文に REVIEW なし: $(printf '%s' "$s" | cut -c1-60)]"
      if has "$s" 'plan'; then
        bad="$bad [「失敗」の文が plan review に触れている: $(printf '%s' "$s" | cut -c1-60)]"
      fi
    fi
  done <<< "$sentences"
  if [ -z "$bad" ]; then
    pass "TC-08a: principles 3/4 wording"
  else
    fail "TC-08a:$bad"
  fi
fi

adr="$BASE_DIR/docs/decisions/adr-codex-review-only.md"
if [ ! -f "$adr" ]; then
  fail "TC-08b: docs/decisions/adr-codex-review-only.md does not exist"
else
  dec=$(awk '/^## Decision$/{f=1;next} f&&/^## /{exit} f' "$adr")
  bad=""
  [ -z "$dec" ] && bad="$bad [## Decision 節が空/無い]"
  has "$dec" 'CONSTITUTION' || bad="$bad [Decision に CONSTITUTION なし]"
  grep -qE '原則 ?3' <<< "$dec" || bad="$bad [Decision に原則 3 なし]"
  grep -qE '原則 ?4|原則 ?3 ?[・,、] ?4' <<< "$dec" || bad="$bad [Decision に原則 4 なし]"
  if [ -z "$bad" ]; then
    pass "TC-08b: ADR exists and its Decision covers CONSTITUTION principles 3/4"
  else
    fail "TC-08b:$bad"
  fi
fi

# ---------------------------------------------------------------------------
echo ""
echo "TC-09: no --full-auto and every codex exec call has < /dev/null (moved from codex-session-unify TC-08)"
# Given 実行手順を書くファイル / When 継続行を連結し codex exec を 1 つずつ見る
# Then --full-auto が無く、どの呼び出しも < /dev/null を伴う（1 行に 2 つあって片方だけ欠けても落ちる）
tc09_fa=""
tc09_dn=""
tc09_total=0
while IFS= read -r f; do
  [ -z "$f" ] && continue
  [ -f "$BASE_DIR/$f" ] || continue
  grep -qF -- '--full-auto' "$BASE_DIR/$f" && tc09_fa="$tc09_fa $f"
  segs=$(join_lines "$BASE_DIR/$f" | segments | real_calls)
  [ -z "$segs" ] && continue
  while IFS= read -r seg; do
    [ -z "$seg" ] && continue
    tc09_total=$((tc09_total + 1))
    has "$seg" '< /dev/null' || tc09_dn="$tc09_dn [$f: $(printf '%s' "$seg" | cut -c1-60)]"
  done <<< "$segs"
done <<< "$INSTR"
if [ -n "$tc09_fa" ]; then
  fail "TC-09a: --full-auto remains in:$tc09_fa"
else
  pass "TC-09a: no --full-auto"
fi
if [ "$tc09_total" -eq 0 ]; then
  fail "TC-09b: no codex exec call found (vacuous)"
elif [ -n "$tc09_dn" ]; then
  fail "TC-09b: call without < /dev/null:$tc09_dn"
else
  pass "TC-09b: all $tc09_total codex exec calls have < /dev/null"
fi

# ---------------------------------------------------------------------------
echo ""
echo "TC-10: REVIEW section lists targets and does not re-review (moved from steps-codex-improvements T-01/T-02)"
# Given steps-subagent.md と steps-teams.md / Then REVIEW 節に 2 つの列挙コマンドと「再レビューしない」
for mode in steps-subagent steps-teams; do
  sec=$(review_section "$BASE_DIR/skills/orchestrate/$mode.md" 2>/dev/null)
  bad=""
  [ -z "$sec" ] && bad="$bad [REVIEW 節が取れない]"
  has "$sec" 'git diff HEAD --name-only' || bad="$bad [git diff HEAD --name-only なし]"
  has "$sec" 'git ls-files --others --exclude-standard' || bad="$bad [git ls-files --others --exclude-standard なし]"
  has "$sec" '再レビューしない' || bad="$bad [「再レビューしない」なし]"
  if [ -z "$bad" ]; then
    pass "TC-10: $mode"
  else
    fail "TC-10: $mode:$bad"
  fi
done

# ---------------------------------------------------------------------------
echo ""
echo "TC-11: onboard Codex template and setup guidance are read-only with < /dev/null"
# Given onboard/reference.md の「Codex Integration リテラルテンプレート」の fence と
#       「#### Codex セットアップガイダンス」節（旧説明は fence の外にあるので両方を範囲にする）
# Then 範囲内の codex exec がすべて --sandbox read-only と < /dev/null を持ち、「RED/GREEN 実装委譲」が無い
onb="$BASE_DIR/skills/onboard/reference.md"
tmpl=$(awk '/Codex Integration リテラルテンプレート/{s=1;next} s==1&&/^```/{s=2;next} s==2&&/^```/{exit} s==2' "$onb")
guide=$(awk '/^#### Codex セットアップガイダンス/{f=1;next} f&&/^#{1,4} /{exit} f' "$onb")
if [ -z "$tmpl" ] || [ -z "$guide" ]; then
  fail "TC-11: template fence or guidance section not found (tmpl=${#tmpl} guide=${#guide})"
else
  range="$tmpl
$guide"
  bad=""
  segs=$(printf '%s\n' "$range" | segments | real_calls)
  n=0
  if [ -n "$segs" ]; then
    while IFS= read -r seg; do
      [ -z "$seg" ] && continue
      n=$((n + 1))
      has "$seg" '--sandbox read-only' || bad="$bad [read-only なし: $(printf '%s' "$seg" | cut -c1-60)]"
      has "$seg" '< /dev/null' || bad="$bad [< /dev/null なし: $(printf '%s' "$seg" | cut -c1-60)]"
    done <<< "$segs"
  fi
  [ "$n" -ge 1 ] || bad="$bad [範囲内に codex exec 呼び出しなし]"
  has "$range" 'RED/GREEN 実装委譲' && bad="$bad [「RED/GREEN 実装委譲」が残っている]"
  if [ -z "$bad" ]; then
    pass "TC-11: $n codex exec calls in template/guidance are read-only with < /dev/null"
  else
    fail "TC-11:$bad"
  fi
fi

echo ""
echo "=== Summary ==="
echo "PASS: $PASS"
echo "FAIL: $FAIL"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
