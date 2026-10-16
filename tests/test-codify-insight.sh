#!/bin/bash
# test-codify-insight.sh - codify-insight skill structure tests
# TC-01 to TC-20 for v2.7 Agile Loop Cycle B

set -uo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

SKILL_MD="$BASE_DIR/skills/codify-insight/SKILL.md"
REFERENCE_MD="$BASE_DIR/skills/codify-insight/reference.md"
STATE_OWNERSHIP="$BASE_DIR/rules/state-ownership.md"
ORCHESTRATE_SKILL_MD="$BASE_DIR/skills/orchestrate/SKILL.md"
STEPS_SUBAGENT_MD="$BASE_DIR/skills/orchestrate/steps-subagent.md"
STEPS_TEAMS_MD="$BASE_DIR/skills/orchestrate/steps-teams.md"
README_MD="$BASE_DIR/README.md"
AGENTS_MD="$BASE_DIR/AGENTS.md"
CLAUDE_MD="$BASE_DIR/CLAUDE.md"
STATUS_MD="$BASE_DIR/docs/STATUS.md"
FRONTMATTER_VALIDATOR="$BASE_DIR/scripts/validate-yaml-frontmatter.sh"

echo "=== codify-insight Skill Structure Tests (v2.7 Cycle B) ==="

# TC-01: SKILL.md frontmatter valid (via validate-yaml-frontmatter.sh)
echo ""
echo "TC-01: SKILL.md frontmatter validation via validate-yaml-frontmatter.sh"
if [ ! -f "$SKILL_MD" ]; then
  fail "TC-01: skills/codify-insight/SKILL.md does not exist"
elif ! bash "$FRONTMATTER_VALIDATOR" "$SKILL_MD" 2>/dev/null; then
  fail "TC-01: SKILL.md frontmatter is invalid (validate-yaml-frontmatter.sh returned non-zero)"
else
  pass "TC-01: SKILL.md frontmatter is valid"
fi

# TC-02: SKILL.md line count <= 100
echo ""
echo "TC-02: SKILL.md line count < 100"
if [ ! -f "$SKILL_MD" ]; then
  fail "TC-02: skills/codify-insight/SKILL.md does not exist"
else
  line_count=$(wc -l < "$SKILL_MD" | tr -d ' ')
  if [ "$line_count" -lt 100 ]; then
    pass "TC-02: SKILL.md has $line_count lines (< 100)"
  else
    fail "TC-02: SKILL.md has $line_count lines (>= 100, hard limit exceeded)"
  fi
fi

# TC-03: SKILL.md allowed-tools contains Read, Edit, AskUserQuestion, Glob
echo ""
echo "TC-03: SKILL.md allowed-tools contains Read, Edit, AskUserQuestion, Glob"
if [ ! -f "$SKILL_MD" ]; then
  fail "TC-03: skills/codify-insight/SKILL.md does not exist"
else
  TC03_PASS=true
  for tool in Read Edit AskUserQuestion Glob; do
    if ! grep -q "$tool" "$SKILL_MD"; then
      fail "TC-03: SKILL.md allowed-tools does NOT contain '$tool'"
      TC03_PASS=false
    fi
  done
  if [ "$TC03_PASS" = "true" ]; then
    pass "TC-03: SKILL.md allowed-tools contains Read, Edit, AskUserQuestion, Glob"
  fi
fi

# TC-04: SKILL.md description contains "codify-insight", "codify", or "decide gate"
echo ""
echo "TC-04: SKILL.md description contains trigger keyword (codify-insight / codify / decide gate)"
if [ ! -f "$SKILL_MD" ]; then
  fail "TC-04: skills/codify-insight/SKILL.md does not exist"
else
  desc_line=$(awk '/^---$/{n++; next} n==1 && /^description:/{print; exit} n==2{exit}' "$SKILL_MD" || true)
  if echo "$desc_line" | grep -qiE "codify-insight|codify|decide gate"; then
    pass "TC-04: SKILL.md description contains trigger keyword"
  else
    fail "TC-04: SKILL.md description does NOT contain 'codify-insight', 'codify', or 'decide gate' (line: '$desc_line')"
  fi
fi

# TC-05: SKILL.md workflow contains frontmatter-only awk pattern (positive)
#        AND does NOT contain bare grep -l / grep -rl 'retro_status: captured' (negative)
echo ""
echo "TC-05: SKILL.md frontmatter-only awk pattern (positive) + no bare grep pattern (negative)"
if [ ! -f "$SKILL_MD" ]; then
  fail "TC-05: skills/codify-insight/SKILL.md does not exist"
else
  AWK_PATTERN="awk '/^\-\-\-\$/{c++;next} c==1{print}'"
  # Check positive: awk frontmatter-only scan pattern present
  if grep -qF "awk '/^---\$/{c++;next} c==1{print}'" "$SKILL_MD"; then
    TC05_POSITIVE=true
  else
    TC05_POSITIVE=false
  fi
  # Check negative: bare grep -l or grep -rl 'retro_status: captured' must NOT be present
  if grep -qE "grep -l 'retro_status: captured'|grep -rl 'retro_status: captured'" "$SKILL_MD"; then
    TC05_NEGATIVE=false
  else
    TC05_NEGATIVE=true
  fi
  if [ "$TC05_POSITIVE" = "true" ] && [ "$TC05_NEGATIVE" = "true" ]; then
    pass "TC-05: SKILL.md has frontmatter-only awk pattern and no bare grep pattern"
  elif [ "$TC05_POSITIVE" = "false" ]; then
    fail "TC-05: SKILL.md does NOT contain frontmatter-only awk pattern"
  else
    fail "TC-05: SKILL.md contains bare grep 'retro_status: captured' (self-trigger risk)"
  fi
fi

# TC-06: reference.md contains verbatim 3-option strings: "codify now", "defer with reason", "no-codify"
#        AND documents they are fallback-only (not default per-insight interaction)
echo ""
echo "TC-06: reference.md contains 3-option strings and marks them fallback-only"
if [ ! -f "$REFERENCE_MD" ]; then
  fail "TC-06: skills/codify-insight/reference.md does not exist"
else
  TC06_PASS=true
  for option in "codify now" "defer with reason" "no-codify"; do
    if ! grep -qF "$option" "$REFERENCE_MD"; then
      fail "TC-06: reference.md missing verbatim option string: '$option'"
      TC06_PASS=false
    fi
  done
  has_fallback_only=$(grep -iE "fallback only|fallback のみ|default.*autonomous|autonomous.*default" "$REFERENCE_MD" || true)
  if [ "$TC06_PASS" = "true" ] && [ -n "$has_fallback_only" ]; then
    pass "TC-06: reference.md contains 3 options and marks them fallback-only"
  elif [ "$TC06_PASS" = "true" ]; then
    fail "TC-06: reference.md contains 3 options but does NOT mark them as fallback-only/autonomous default"
  fi
fi

# TC-07: reference.md states defer requires reason, no-codify reason is optional,
#        and AskUserQuestion is batched only for skill/low-confidence cases
echo ""
echo "TC-07: reference.md documents defer/no-codify reason contract + batch escalation"
if [ ! -f "$REFERENCE_MD" ]; then
  fail "TC-07: skills/codify-insight/reference.md does not exist"
else
  has_defer_required=$(grep -iE "defer.*(reason|required|必須)" "$REFERENCE_MD" || true)
  has_nocodify_optional=$(grep -iE "no-codify.*(optional|任意)|no-codify.*reason.*(optional|任意)" "$REFERENCE_MD" || true)
  has_batch_escalation=$(grep -iE "1 cycle.*1 回|once per cycle|skill.*candidate|low confidence|low-confidence" "$REFERENCE_MD" || true)
  if [ -n "$has_defer_required" ] && [ -n "$has_nocodify_optional" ] && [ -n "$has_batch_escalation" ]; then
    pass "TC-07: reference.md documents reason contract and batch escalation policy"
  else
    if [ -z "$has_defer_required" ]; then
      fail "TC-07: reference.md does NOT state defer requires reason"
    elif [ -z "$has_nocodify_optional" ]; then
      fail "TC-07: reference.md does NOT state no-codify reason is optional"
    else
      fail "TC-07: reference.md does NOT document batch escalation for skill/low-confidence cases"
    fi
  fi
fi

# TC-08: SKILL.md documents skip for both retro_status: resolved AND retro_status: none
echo ""
echo "TC-08: SKILL.md documents skip for both retro_status: resolved and retro_status: none"
if [ ! -f "$SKILL_MD" ]; then
  fail "TC-08: skills/codify-insight/SKILL.md does not exist"
else
  has_resolved=$(grep -F "retro_status: resolved" "$SKILL_MD" || true)
  has_none=$(grep -F "retro_status: none" "$SKILL_MD" || true)
  has_skip=$(grep -iE "skip|スキップ" "$SKILL_MD" || true)
  if [ -n "$has_resolved" ] && [ -n "$has_none" ] && [ -n "$has_skip" ]; then
    pass "TC-08: SKILL.md documents skip for retro_status: resolved and none"
  else
    if [ -z "$has_resolved" ]; then
      fail "TC-08: SKILL.md does NOT mention retro_status: resolved skip"
    elif [ -z "$has_none" ]; then
      fail "TC-08: SKILL.md does NOT mention retro_status: none skip"
    else
      fail "TC-08: SKILL.md does NOT document skip behavior"
    fi
  fi
fi

# TC-09: reference.md documents "no captured cycles found → no-op exit 0" message
echo ""
echo "TC-09: reference.md documents 'no captured cycles found → no-op exit 0'"
if [ ! -f "$REFERENCE_MD" ]; then
  fail "TC-09: skills/codify-insight/reference.md does not exist"
else
  has_no_captured=$(grep -iE "no captured|captured.*not found|captured.*なし|captured.*ない" "$REFERENCE_MD" || true)
  has_exit0=$(grep -iE "exit 0|no-op" "$REFERENCE_MD" || true)
  if [ -n "$has_no_captured" ] && [ -n "$has_exit0" ]; then
    pass "TC-09: reference.md documents no captured cycles → no-op exit 0"
  else
    if [ -z "$has_no_captured" ]; then
      fail "TC-09: reference.md does NOT document 'no captured cycles found' case"
    else
      fail "TC-09: reference.md does NOT document exit 0 / no-op behavior for no captured cycles"
    fi
  fi
fi

# TC-10: reference.md documents "## Codify Decisions" EOF section append (NOT per-insight inline)
echo ""
echo "TC-10: reference.md documents '## Codify Decisions' EOF section append (not per-insight inline)"
if [ ! -f "$REFERENCE_MD" ]; then
  fail "TC-10: skills/codify-insight/reference.md does not exist"
else
  has_codify_decisions=$(grep -F "## Codify Decisions" "$REFERENCE_MD" || true)
  has_eof_append=$(grep -iE "EOF|末尾|append.*section|section.*append" "$REFERENCE_MD" || true)
  if [ -n "$has_codify_decisions" ] && [ -n "$has_eof_append" ]; then
    pass "TC-10: reference.md documents '## Codify Decisions' EOF section append"
  else
    if [ -z "$has_codify_decisions" ]; then
      fail "TC-10: reference.md does NOT mention '## Codify Decisions' section"
    else
      fail "TC-10: reference.md does NOT document EOF/末尾 append approach"
    fi
  fi
fi

# TC-11: reference.md states APPEND-ONLY contract
#        (existing Retrospective unchanged, Codify Decisions is new EOF section)
echo ""
echo "TC-11: reference.md states APPEND-ONLY contract (Retrospective unchanged, Codify Decisions is new EOF section)"
if [ ! -f "$REFERENCE_MD" ]; then
  fail "TC-11: skills/codify-insight/reference.md does not exist"
else
  has_append_only=$(grep -iE "APPEND.ONLY|append only|追記のみ" "$REFERENCE_MD" || true)
  has_retro_unchanged=$(grep -iE "Retrospective.*不変|不変.*Retrospective|existing.*unchanged|unchanged.*existing|Retrospective.*変更しない" "$REFERENCE_MD" || true)
  if [ -n "$has_append_only" ] && [ -n "$has_retro_unchanged" ]; then
    pass "TC-11: reference.md states APPEND-ONLY contract with existing Retrospective unchanged"
  else
    if [ -z "$has_append_only" ]; then
      fail "TC-11: reference.md does NOT state APPEND-ONLY contract"
    else
      fail "TC-11: reference.md does NOT state existing Retrospective section is unchanged"
    fi
  fi
fi

# TC-12: reference.md states retro_status transition trigger is "all insights judged"
echo ""
echo "TC-12: reference.md states captured→resolved transition triggered by 'all insights judged'"
if [ ! -f "$REFERENCE_MD" ]; then
  fail "TC-12: skills/codify-insight/reference.md does not exist"
else
  has_transition=$(grep -iE "captured.*resolved|resolved.*遷移|captured → resolved" "$REFERENCE_MD" || true)
  has_all_judged=$(grep -iE "all.*judg|全.*判断|全.*insight|insight.*全|すべて.*判断" "$REFERENCE_MD" || true)
  if [ -n "$has_transition" ] && [ -n "$has_all_judged" ]; then
    pass "TC-12: reference.md states captured→resolved transition requires all insights judged"
  else
    if [ -z "$has_transition" ]; then
      fail "TC-12: reference.md does NOT mention captured→resolved transition"
    else
      fail "TC-12: reference.md does NOT state 'all insights judged' as transition trigger"
    fi
  fi
fi

# TC-13: reference.md contains fixed decision markers: codified, deferred, no-codify
echo ""
echo "TC-13: reference.md contains fixed decision markers (codified / deferred / no-codify)"
if [ ! -f "$REFERENCE_MD" ]; then
  fail "TC-13: skills/codify-insight/reference.md does not exist"
else
  TC13_PASS=true
  for marker in "codified" "deferred" "no-codify"; do
    if ! grep -qF "$marker" "$REFERENCE_MD"; then
      fail "TC-13: reference.md missing canonical decision marker: '$marker'"
      TC13_PASS=false
    fi
  done
  if [ "$TC13_PASS" = "true" ]; then
    pass "TC-13: reference.md contains all 3 canonical decision markers"
  fi
fi

# TC-14: rules/state-ownership.md contains codify-insight row
#        with retro_status (captured → resolved) + updated + body section append
echo ""
echo "TC-14: state-ownership.md contains codify-insight row (retro_status + updated + body section append)"
if [ ! -f "$STATE_OWNERSHIP" ]; then
  fail "TC-14: rules/state-ownership.md does not exist"
else
  codify_line=$(grep "codify-insight" "$STATE_OWNERSHIP" || true)
  if [ -z "$codify_line" ]; then
    fail "TC-14: state-ownership.md does NOT contain codify-insight row"
  else
    has_retro=$(echo "$codify_line" | grep -q "retro_status" && echo "yes" || echo "no")
    has_resolved=$(echo "$codify_line" | grep -qE "captured.*resolved|resolved" && echo "yes" || echo "no")
    has_updated=$(echo "$codify_line" | grep -q "updated" && echo "yes" || echo "no")
    if [ "$has_retro" = "yes" ] && [ "$has_resolved" = "yes" ] && [ "$has_updated" = "yes" ]; then
      pass "TC-14: state-ownership.md has codify-insight row with retro_status + updated"
    else
      fail "TC-14: state-ownership.md codify-insight row incomplete (retro_status=$has_retro, resolved=$has_resolved, updated=$has_updated) — line: '$codify_line'"
    fi
  fi
fi

# --- Block 0 "0. Codify notice" helpers ---
# 見出し区間を先行抽出してから判定する（whole-file grep は別 section の decoy で偽 PASS する）。
NOTICE_TEXT='未処理の振り返りを持つ Cycle doc が N 件あります（retro_status: captured）。処理するときは /dev-crew:codify-insight を別に実行し、タスクとは別の commit にしてください。'
NOTICE_PROCEED='件数にかかわらず次へ進む'
AWK_FM='awk '"'"'/^---$/{c++;next} c==1{print}'"'"

# SKILL.md: 太字行 "**0. Codify notice**" から次の太字行 / 見出し行の手前まで
extract_notice_skill() {
  awk '
    index($0, "**0. Codify notice**") == 1 {s=1; next}
    s && (/^\*\*/ || /^#/) {exit}
    s
  ' "$1"
}

# steps-*.md: "### 0. Codify notice" から次の H2/H3 の手前まで
extract_notice_steps() {
  awk '
    index($0, "### 0. Codify notice") == 1 {s=1; next}
    s && /^##/ {exit}
    s
  ' "$1"
}

# 区間テキスト (stdin) から ```bash フェンスの中身だけを取り出す
extract_bash_fence() {
  awk '/^```bash/{f=1; next} /^```/{f=0} f'
}

# check_notice_section TC FILE KIND(skill|steps) -> sets NOTICE_SECTION, NOTICE_SNIPPET; returns 0 on PASS
check_notice_section() {
  local tc="$1" file="$2" kind="$3" sec
  NOTICE_SECTION=""
  NOTICE_SNIPPET=""
  if [ ! -f "$file" ]; then
    fail "$tc: $file does not exist"
    return 1
  fi
  if [ "$kind" = "skill" ]; then
    sec=$(extract_notice_skill "$file")
  else
    sec=$(extract_notice_steps "$file")
  fi
  NOTICE_SECTION="$sec"
  if [ -z "$sec" ]; then
    fail "$tc: '0. Codify notice' section not found in $(basename "$file")"
    return 1
  fi
  NOTICE_SNIPPET=$(printf '%s\n' "$sec" | extract_bash_fence)
  if printf '%s\n' "$sec" | grep -qF 'Skill(dev-crew:codify-insight)'; then
    fail "$tc: notice section still invokes Skill(dev-crew:codify-insight)"
    return 1
  fi
  if printf '%s\n' "$sec" | grep -qF 'resolved 遷移後'; then
    fail "$tc: notice section still waits for 'resolved 遷移後'"
    return 1
  fi
  if printf '%s\n' "$sec" | grep -qF 'exit 1 (abort) → BLOCK'; then
    fail "$tc: notice section still has 'exit 1 (abort) → BLOCK'"
    return 1
  fi
  if ! printf '%s\n' "$sec" | grep -qF "$NOTICE_TEXT"; then
    fail "$tc: notice section missing fixed notice text"
    return 1
  fi
  if ! printf '%s\n' "$sec" | grep -qF "$NOTICE_PROCEED"; then
    fail "$tc: notice section missing '$NOTICE_PROCEED'"
    return 1
  fi
  if [ -z "$NOTICE_SNIPPET" ]; then
    fail "$tc: notice section has no fenced bash snippet"
    return 1
  fi
  if ! printf '%s\n' "$NOTICE_SNIPPET" | grep -qF "$AWK_FM"; then
    fail "$tc: notice snippet missing frontmatter-only awk pattern"
    return 1
  fi
  return 0
}

# TC-15: orchestrate/SKILL.md Block 0 "0. Codify notice" は通知のみ（起動しない）
# Given: orchestrate/SKILL.md の Block 0 節
# When:  "**0. Codify notice**" 区間を読む
# Then:  Skill 起動・待機条件が無く、固定通知文 + 「件数にかかわらず次へ進む」+ frontmatter-only awk がある
echo ""
echo "TC-15: orchestrate/SKILL.md Block 0 '0. Codify notice' is notify-only"
if check_notice_section "TC-15" "$ORCHESTRATE_SKILL_MD" skill; then
  pass "TC-15: SKILL.md Block 0 notice has fixed text, proceed clause, awk; no Skill invocation / wait"
fi
SKILL_NOTICE_SNIPPET="$NOTICE_SNIPPET"

# TC-15b: SKILL.md の通知スニペットを fixture で実行し、件数と exit 0 を確認する
# Given: SKILL.md から取り出した通知スニペットと mktemp fixture (docs/cycles/)
# When:  captured 0 / 1 / 3 件、本文だけに引用した doc を含む 1 件の各 fixture で実行
# Then:  標準出力は整数 1 行で 0 / 1 / 3 / 1、すべて exit 0
echo ""
echo "TC-15b: notice snippet from orchestrate/SKILL.md counts captured docs (frontmatter only) and exits 0"
if [ -z "$SKILL_NOTICE_SNIPPET" ]; then
  fail "TC-15b: no notice snippet extracted from orchestrate/SKILL.md"
else
  TC15B_PASS=true
  TC15B_TMP=$(mktemp -d)
  trap 'rm -rf "$TC15B_TMP"' EXIT
  mk_doc() { # path status [body-quote]
    {
      printf -- '---\nfeature: x\nretro_status: %s\n---\n\n# doc\n' "$2"
      if [ -n "${3:-}" ]; then printf 'quote: retro_status: captured\n'; fi
    } > "$1"
  }
  run_case() { # label expected
    local label="$1" expected="$2" d="$3" out rc
    out=$(cd "$d" && bash -o pipefail -c "$SKILL_NOTICE_SNIPPET" 2>/dev/null)
    rc=$?
    if [ "$rc" -ne 0 ]; then
      fail "TC-15b: [$label] exit code $rc (expected 0)"; TC15B_PASS=false
    elif [ "$out" != "$expected" ]; then
      fail "TC-15b: [$label] output '$out' (expected '$expected')"; TC15B_PASS=false
    fi
  }
  d0="$TC15B_TMP/c0"; mkdir -p "$d0/docs/cycles"
  mk_doc "$d0/docs/cycles/a.md" none
  mk_doc "$d0/docs/cycles/b.md" resolved
  run_case "0 captured" 0 "$d0"
  d1="$TC15B_TMP/c1"; mkdir -p "$d1/docs/cycles"
  mk_doc "$d1/docs/cycles/a.md" captured
  mk_doc "$d1/docs/cycles/b.md" resolved
  run_case "1 captured" 1 "$d1"
  d3="$TC15B_TMP/c3"; mkdir -p "$d3/docs/cycles"
  mk_doc "$d3/docs/cycles/a.md" captured
  mk_doc "$d3/docs/cycles/b.md" captured
  mk_doc "$d3/docs/cycles/c.md" captured
  mk_doc "$d3/docs/cycles/d.md" none
  run_case "3 captured" 3 "$d3"
  dq="$TC15B_TMP/cq"; mkdir -p "$dq/docs/cycles"
  mk_doc "$dq/docs/cycles/a.md" captured
  mk_doc "$dq/docs/cycles/b.md" none quote
  run_case "1 captured + body-only quote" 1 "$dq"
  # frontmatter 内のコメント行 / 他フィールド内の引用は数えない
  dc="$TC15B_TMP/cc"; mkdir -p "$dc/docs/cycles"
  printf -- '---\nfeature: x\nretro_status: resolved\n# retro_status: captured\nnote: "was retro_status: captured"\n---\n\n# doc\n' > "$dc/docs/cycles/a.md"
  run_case "frontmatter comment / quoted field only" 0 "$dc"
  # 約 1MB の frontmatter: grep の早期終了で awk が SIGPIPE になっても数え落とさない
  dbig="$TC15B_TMP/cbig"; mkdir -p "$dbig/docs/cycles"
  {
    printf -- '---\nretro_status: captured\n'
    head -c 1048576 /dev/zero | tr '\0' 'x' | fold -w 100
    printf -- '\n---\n\n# doc\n'
  } > "$dbig/docs/cycles/a.md"
  run_case "1 captured with ~1MB frontmatter (pipefail)" 1 "$dbig"
  if [ "$TC15B_PASS" = "true" ]; then
    pass "TC-15b: snippet prints 0/1/3/1/0/1 and exits 0 for all fixtures"
  fi
fi

# check_steps_notice TC FILE: TC-15 の (a)〜(d) + bare grep 無し + スニペットが SKILL.md と同一
check_steps_notice() {
  local tc="$1" file="$2" name
  name=$(basename "$file")
  if ! check_notice_section "$tc" "$file" steps; then
    return
  fi
  if grep -qE "grep -l 'retro_status: captured'|grep -rl 'retro_status: captured'" "$file"; then
    fail "$tc: $name contains bare grep 'retro_status: captured' (self-trigger risk)"
  elif [ -z "$SKILL_NOTICE_SNIPPET" ]; then
    fail "$tc: no reference snippet in orchestrate/SKILL.md to compare with"
  elif [ "$NOTICE_SNIPPET" != "$SKILL_NOTICE_SNIPPET" ]; then
    fail "$tc: $name notice snippet differs from orchestrate/SKILL.md snippet"
  else
    pass "$tc: $name notice is notify-only, no bare grep, snippet identical to SKILL.md"
  fi
}

# TC-16: steps-subagent.md Block 0 "0. Codify notice"
# Given: steps-subagent.md / When: "### 0. Codify notice" 区間を読む
# Then:  TC-15 の (a)〜(d) + bare grep 無し + スニペットが SKILL.md と同一
echo ""
echo "TC-16: steps-subagent.md Block 0 '0. Codify notice' (notify-only, snippet == SKILL.md)"
check_steps_notice "TC-16" "$STEPS_SUBAGENT_MD"

# TC-17: steps-teams.md Block 0 "0. Codify notice"
# Given: steps-teams.md / When: "### 0. Codify notice" 区間を読む / Then: TC-16 と同じ
echo ""
echo "TC-17: steps-teams.md Block 0 '0. Codify notice' (notify-only, snippet == SKILL.md)"
check_steps_notice "TC-17" "$STEPS_TEAMS_MD"

# TC-18: README.md, CLAUDE.md, AGENTS.md, docs/STATUS.md all contain grep-matchable "codify-insight"
echo ""
echo "TC-18: README.md / CLAUDE.md / AGENTS.md / docs/STATUS.md each mention codify-insight"
TC18_PASS=true
for label_file in \
  "README.md:$README_MD" \
  "CLAUDE.md:$CLAUDE_MD" \
  "AGENTS.md:$AGENTS_MD" \
  "docs/STATUS.md:$STATUS_MD"
do
  label="${label_file%%:*}"
  fpath="${label_file#*:}"
  if [ ! -f "$fpath" ]; then
    fail "TC-18: $label does not exist"
    TC18_PASS=false
  elif grep -q "codify-insight" "$fpath"; then
    : # counted at end
  else
    fail "TC-18: $label does NOT mention codify-insight"
    TC18_PASS=false
  fi
done
if [ "$TC18_PASS" = "true" ]; then
  pass "TC-18: All 4 files mention codify-insight"
fi

# TC-21: SKILL.md documents Recurrence-aware Pre-triage (2+ 回再発 → 自動 rule 昇格)
echo ""
echo "TC-21: SKILL.md documents Recurrence-aware Pre-triage"
if [ ! -f "$SKILL_MD" ]; then
  fail "TC-21: skills/codify-insight/SKILL.md does not exist"
else
  has_recurrence_heading=$(grep -cE "^### Recurrence" "$SKILL_MD" || true)
  has_promotion_rule=$(grep -cF "2+ 回再発" "$SKILL_MD" || true)
  if [ "$has_recurrence_heading" -ge 1 ] && [ "$has_promotion_rule" -ge 1 ]; then
    pass "TC-21: SKILL.md documents Recurrence-aware Pre-triage + 2+ 回再発 promotion"
  elif [ "$has_recurrence_heading" -lt 1 ]; then
    fail "TC-21: SKILL.md missing '### Recurrence' heading"
  else
    fail "TC-21: SKILL.md missing '2+ 回再発' promotion rule"
  fi
fi

# TC-22: reference.md documents frequency_threshold (default 2 回) + scan 範囲 (直近 10 cycle docs)
echo ""
echo "TC-22: reference.md documents frequency_threshold + scan 範囲"
if [ ! -f "$REFERENCE_MD" ]; then
  fail "TC-22: skills/codify-insight/reference.md does not exist"
else
  has_threshold=$(grep -cE "frequency_threshold|2 回" "$REFERENCE_MD" || true)
  has_scan_range=$(grep -cE "直近 10 cycle|10 cycles" "$REFERENCE_MD" || true)
  has_duplicate_detect=$(grep -cF "duplicate" "$REFERENCE_MD" || true)
  if [ "$has_threshold" -ge 1 ] && [ "$has_scan_range" -ge 1 ] && [ "$has_duplicate_detect" -ge 1 ]; then
    pass "TC-22: reference.md documents frequency_threshold + scan 範囲 + duplicate detection"
  elif [ "$has_threshold" -lt 1 ]; then
    fail "TC-22: reference.md missing frequency_threshold / 2 回 mention"
  elif [ "$has_scan_range" -lt 1 ]; then
    fail "TC-22: reference.md missing scan 範囲 (直近 10 cycle docs)"
  else
    fail "TC-22: reference.md missing duplicate detection documentation"
  fi
fi

# TC-23: SKILL.md documents Question 0 件条件 (全件 recurrence or high-confidence で質問スキップ)
echo ""
echo "TC-23: SKILL.md documents zero-question path"
if [ ! -f "$SKILL_MD" ]; then
  fail "TC-23: skills/codify-insight/SKILL.md does not exist"
else
  has_zero_question=$(grep -cE "質問 0 件|質問スキップ|0 件で summary" "$SKILL_MD" || true)
  if [ "$has_zero_question" -ge 1 ]; then
    pass "TC-23: SKILL.md documents zero-question path"
  else
    fail "TC-23: SKILL.md missing zero-question (質問 0 件 / 質問スキップ) documentation"
  fi
fi

STEPS_CODEX_MD="$BASE_DIR/skills/orchestrate/steps-codex.md"

# TC-24: steps-codex.md に codify-insight を起動・自動 triage する記述が無い
# Given: steps-codex.md / When: codify-insight に触れる行を読む
# Then:  「起動」「自動 triage」「triage」を含む行が無い
echo ""
echo "TC-24: steps-codex.md does not describe launching / auto-triaging codify-insight"
if [ ! -f "$STEPS_CODEX_MD" ]; then
  fail "TC-24: skills/orchestrate/steps-codex.md does not exist"
else
  tc24_hits=$(grep -F "codify-insight" "$STEPS_CODEX_MD" | grep -E "triage|起動" || true)
  if [ -z "$tc24_hits" ]; then
    pass "TC-24: steps-codex.md has no codify-insight launch / auto-triage description"
  else
    fail "TC-24: steps-codex.md still describes codify-insight launch/triage: '$tc24_hits'"
  fi
fi

# H2 見出し (prefix 一致, fixed-string) 区間の本文を出力
sec_h2() {
  awk -v h="$2" '
    index($0, "## " h) == 1 {s=1; next}
    s && /^## /{exit}
    s
  ' "$1"
}

# TC-25: codify-insight/SKILL.md は手動起動のみ + Restrictions 契約
# Given: codify-insight/SKILL.md
# When:  frontmatter / description / 全体 / "## Restrictions" 区間を読む
# Then:  (a) disable-model-invocation: true (b) description に Block 0・次サイクル開始時が無い
#        (c) SKILL.md 全体に Block 0 が無い (d) Restrictions 区間に 3 文が固定文字列で全部ある
echo ""
echo "TC-25: codify-insight/SKILL.md is manual-only + has Restrictions contract"
if [ ! -f "$SKILL_MD" ]; then
  fail "TC-25: skills/codify-insight/SKILL.md does not exist"
else
  TC25_PASS=true
  tc25_fm=$(awk '/^---$/{c++;next} c==1{print}' "$SKILL_MD")
  if ! printf '%s\n' "$tc25_fm" | grep -qx 'disable-model-invocation: true'; then
    fail "TC-25: frontmatter missing 'disable-model-invocation: true'"; TC25_PASS=false
  fi
  tc25_tools=$(printf '%s\n' "$tc25_fm" | grep '^allowed-tools:' || true)
  if [ -z "$tc25_tools" ]; then
    fail "TC-25: frontmatter missing allowed-tools"; TC25_PASS=false
  else
    for t in Bash Write; do
      if printf '%s\n' "$tc25_tools" | grep -qwF "$t"; then
        fail "TC-25: allowed-tools must not contain '$t'"; TC25_PASS=false
      fi
    done
  fi
  tc25_desc=$(printf '%s\n' "$tc25_fm" | grep '^description:' || true)
  for w in "Block 0" "次サイクル開始時"; do
    if printf '%s\n' "$tc25_desc" | grep -qF "$w"; then
      fail "TC-25: description still contains '$w'"; TC25_PASS=false
    fi
  done
  if grep -qF "Block 0" "$SKILL_MD"; then
    fail "TC-25: SKILL.md still mentions 'Block 0' (stale orchestrate linkage)"; TC25_PASS=false
  fi
  tc25_sec=$(sec_h2 "$SKILL_MD" "Restrictions")
  if [ -z "$tc25_sec" ]; then
    fail "TC-25: '## Restrictions' section not found"; TC25_PASS=false
  else
    while IFS= read -r sentence; do
      if ! printf '%s\n' "$tc25_sec" | grep -qF -- "$sentence"; then
        fail "TC-25: Restrictions missing sentence: '$sentence'"; TC25_PASS=false
      fi
    done <<'EOF'
編集してよいのは、対象 Cycle doc の `## Codify Decisions` への追記と、frontmatter の `retro_status` と `updated` の更新だけ。
rules、skills、agents、STATUS.md を含む、それ以外のファイルは編集しない。codified の反映は別サイクルで行う。
codify の変更はタスクの変更と同じ commit に入れない。
EOF
  fi
  if [ "$TC25_PASS" = "true" ]; then
    pass "TC-25: manual-only frontmatter, clean description, no Block 0, Restrictions 3 sentences present"
  fi
fi

# TC-26: reference.md の反映は別サイクル固定文言
# Given: codify-insight/reference.md
# When:  Rule Tier Contract 節と codified Marker MVP 意味論節をそれぞれ読む
# Then:  両方に固定文言がある + MVP 節に「手動 edit」「別 skill で実施」が無い
echo ""
echo "TC-26: reference.md Rule Tier Contract + codified MVP sections carry the separate-cycle sentence"
if [ ! -f "$REFERENCE_MD" ]; then
  fail "TC-26: skills/codify-insight/reference.md does not exist"
else
  TC26_PASS=true
  TC26_SENTENCE='follow-up は別サイクルで行い、codify-insight の実行中には反映しない。'
  tc26_tier=$(sec_h2 "$REFERENCE_MD" "Rule Tier Contract")
  tc26_mvp=$(sec_h2 "$REFERENCE_MD" '`codified` Marker MVP')
  if [ -z "$tc26_tier" ]; then
    fail "TC-26: '## Rule Tier Contract' section not found"; TC26_PASS=false
  elif ! printf '%s\n' "$tc26_tier" | grep -qF "$TC26_SENTENCE"; then
    fail "TC-26: Rule Tier Contract missing fixed sentence"; TC26_PASS=false
  fi
  if [ -z "$tc26_mvp" ]; then
    fail "TC-26: '## \`codified\` Marker MVP' section not found"; TC26_PASS=false
  else
    if ! printf '%s\n' "$tc26_mvp" | grep -qF "$TC26_SENTENCE"; then
      fail "TC-26: codified MVP section missing fixed sentence"; TC26_PASS=false
    fi
    for w in "手動 edit" "別 skill で実施"; do
      if printf '%s\n' "$tc26_mvp" | grep -qF "$w"; then
        fail "TC-26: codified MVP section still contains '$w'"; TC26_PASS=false
      fi
    done
  fi
  if [ "$TC26_PASS" = "true" ]; then
    pass "TC-26: both sections carry the fixed sentence; MVP section has no 手動 edit / 別 skill で実施"
  fi
fi

# TC-27: orchestrate/reference.md Block 0 節のスニペットと通知文が SKILL.md と同一
# Given: orchestrate/reference.md の "## Block 0 Pre-Check" 節 / When: bash フェンスと本文を読む
# Then:  スニペットが SKILL.md と同一、固定通知文・「件数にかかわらず次へ進む」がある、Skill 起動が無い
echo ""
echo "TC-27: orchestrate/reference.md Block 0 section (snippet == SKILL.md, notify-only)"
ORCHESTRATE_REF_MD="$BASE_DIR/skills/orchestrate/reference.md"
if [ ! -f "$ORCHESTRATE_REF_MD" ]; then
  fail "TC-27: skills/orchestrate/reference.md does not exist"
else
  tc27_sec=$(sec_h2 "$ORCHESTRATE_REF_MD" "Block 0 Pre-Check")
  tc27_snip=$(printf '%s\n' "$tc27_sec" | extract_bash_fence)
  if [ -z "$tc27_sec" ]; then
    fail "TC-27: '## Block 0 Pre-Check' section not found"
  elif [ -z "$SKILL_NOTICE_SNIPPET" ]; then
    fail "TC-27: no reference snippet in orchestrate/SKILL.md to compare with"
  elif [ "$tc27_snip" != "$SKILL_NOTICE_SNIPPET" ]; then
    fail "TC-27: reference.md Block 0 snippet differs from orchestrate/SKILL.md snippet"
  elif ! printf '%s\n' "$tc27_sec" | grep -qF "$NOTICE_TEXT"; then
    fail "TC-27: reference.md Block 0 section missing fixed notice text"
  elif ! printf '%s\n' "$tc27_sec" | grep -qF "$NOTICE_PROCEED"; then
    fail "TC-27: reference.md Block 0 section missing '$NOTICE_PROCEED'"
  elif printf '%s\n' "$tc27_sec" | grep -qF 'Skill(dev-crew:codify-insight)'; then
    fail "TC-27: reference.md Block 0 section invokes Skill(dev-crew:codify-insight)"
  else
    pass "TC-27: reference.md Block 0 section has identical snippet, fixed notice, proceed clause; no Skill invocation"
  fi
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
