#!/bin/bash
# test-reviewer-scoring.sh - severity-verdict migration validation (blocking_score -> severity)
# Cycle: docs/cycles/20260903_1130_severity-verdict.md
# TC-01..07/09..11 correspond to Files-to-Change F / Test List TC-01..04/13/15/16.
# TC-08 preserves the prior file's TC-10 verbatim (out-of-scope confidence residual guard).

set -uo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SEVERITY_SCRIPT="$BASE_DIR/skills/review/severity-verdict.sh"
PASS=0
FAIL=0

# Terminal output helpers
pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

# Generic file array checker - returns count of failures
# Usage: check_all_files_contain <tc_id> <pattern> <description> <file_array[@]>
check_all_files_contain() {
  local tc_id="$1"
  local pattern="$2"
  local desc="$3"
  shift 3
  local files=("$@")
  local fail_count=0

  for file in "${files[@]}"; do
    if [ ! -f "$file" ]; then
      fail "$tc_id: $(basename "$file") not found"
      fail_count=$((fail_count + 1))
      continue
    fi

    if ! grep -q -- "$pattern" "$file"; then
      fail "$tc_id: $(basename "$file") missing '$pattern'"
      fail_count=$((fail_count + 1))
    fi
  done

  [ "$fail_count" -eq 0 ] && pass "$tc_id: $desc"
  return "$fail_count"
}

# Generic file array checker for negative assertions
# Usage: check_all_files_not_contain <tc_id> <pattern> <description> <file_array[@]>
check_all_files_not_contain() {
  local tc_id="$1"
  local pattern="$2"
  local desc="$3"
  shift 3
  local files=("$@")
  local fail_count=0

  for file in "${files[@]}"; do
    [ ! -f "$file" ] && continue

    if grep -q -- "$pattern" "$file"; then
      fail "$tc_id: $(basename "$file") still contains '$pattern'"
      fail_count=$((fail_count + 1))
    fi
  done

  [ "$fail_count" -eq 0 ] && pass "$tc_id: $desc"
  return "$fail_count"
}

# Single file checker for positive assertions
# Usage: check_single_file_contains <tc_id> <file> <pattern> <description>
check_single_file_contains() {
  local tc_id="$1"
  local file="$2"
  local pattern="$3"
  local desc="$4"

  if [ ! -f "$file" ]; then
    fail "$tc_id: $(basename "$file") not found"
    return 1
  elif ! grep -q -- "$pattern" "$file"; then
    fail "$tc_id: $(basename "$file") missing '$pattern'"
    return 1
  else
    pass "$tc_id: $desc"
    return 0
  fi
}

# Extract the "## Output" section's first non-blank line from an agent file and
# strip the surrounding inline-code backticks. Section-scoped (not whole-file
# grep) per rules/test-patterns.md.
extract_output_line() {
  local file="$1"
  awk '/^## Output/{f=1;next} f && /^## /{exit} f && NF{print; exit}' "$file" \
    | sed -E 's/^`(.*)`$/\1/'
}

# Extract a heading-anchored section (from "## <heading>" up to next "## ") by
# fixed-string prefix match, avoiding ERE metachar interpretation of the
# heading argument (rules/test-patterns.md: section_grep heading fixed-string).
section_grep() {
  local file="$1"
  local heading="$2"
  awk -v h="$heading" '
    index($0, h) == 1 { f=1; next }
    f && index($0, "## ") == 1 { exit }
    f { print }
  ' "$file"
}

# Constants: 13 reviewer agents (severity-verdict cycle roster — all reviewer-suffixed
# agents that emit findings; review-briefer excluded, generates briefs not findings)
REVIEWERS=(
  "api-contract-reviewer"
  "change-safety-reviewer"
  "correctness-reviewer"
  "design-reviewer"
  "impact-reviewer"
  "maintainability-reviewer"
  "observability-reviewer"
  "performance-reviewer"
  "product-reviewer"
  "resiliency-reviewer"
  "security-reviewer"
  "test-reviewer"
  "usability-reviewer"
)

# Build file paths array
REVIEWER_FILES=()
for reviewer in "${REVIEWERS[@]}"; do
  REVIEWER_FILES+=("$BASE_DIR/agents/${reviewer}.md")
done

echo "=== Reviewer Severity-Verdict Migration Tests ==="

# TC-01: [Given] 13 reviewer agent / [When] Output 行を grep / [Then] "blocking_score" 0 件
echo ""
echo "TC-01: All 13 reviewer agents have no 'blocking_score' in Output line"
tc01_fail=0
for f in "${REVIEWER_FILES[@]}"; do
  if [ ! -f "$f" ]; then
    fail "TC-01: $(basename "$f") not found"
    tc01_fail=$((tc01_fail + 1))
    continue
  fi
  line=$(extract_output_line "$f")
  if printf '%s' "$line" | grep -q "blocking_score"; then
    fail "TC-01: $(basename "$f") Output line still has blocking_score"
    tc01_fail=$((tc01_fail + 1))
  fi
done
[ "$tc01_fail" -eq 0 ] && pass "TC-01: all 13 reviewer Output lines have no blocking_score"

# TC-02: [Given] 13 reviewer agent / [When] 節見出し / [Then] '## Severity 基準' あり・'ブロッキングスコア基準' 0 件
echo ""
echo "TC-02: All 13 reviewer agents have '## Severity 基準' and no 'ブロッキングスコア基準'"
check_all_files_contain "TC-02a" 'Severity 基準' "All 13 reviewer agents have 'Severity 基準' section" "${REVIEWER_FILES[@]}"
check_all_files_not_contain "TC-02b" 'ブロッキングスコア基準' "All 13 reviewer agents have no 'ブロッキングスコア基準' section" "${REVIEWER_FILES[@]}"

# TC-03: [Given] 13 reviewer agent / [When] Output 行 / [Then] severity 具体値 ("severity": ") が存在
echo ""
echo "TC-03: All 13 reviewer agents' Output line declares a concrete severity value"
tc03_fail=0
for f in "${REVIEWER_FILES[@]}"; do
  if [ ! -f "$f" ]; then
    fail "TC-03: $(basename "$f") not found"
    tc03_fail=$((tc03_fail + 1))
    continue
  fi
  line=$(extract_output_line "$f")
  if ! printf '%s' "$line" | grep -qF '"severity": "'; then
    fail "TC-03: $(basename "$f") Output line missing '\"severity\": \"'"
    tc03_fail=$((tc03_fail + 1))
  fi
done
[ "$tc03_fail" -eq 0 ] && pass "TC-03: all 13 reviewer Output lines declare a concrete severity value"

# TC-04: [Given] 13 reviewer agent / [When] grep / [Then] '"confidence"' 不在（負の契約維持）
echo ""
echo "TC-04: All 13 reviewer agents do not contain old '\"confidence\"'"
check_all_files_not_contain "TC-04" '"confidence"' "All 13 reviewer agents do not contain old 'confidence'" "${REVIEWER_FILES[@]}"

# TC-05: [Given] review SKILL.md / [When] grep / [Then] 'Verdict Aggregation' が存在
echo ""
echo "TC-05: review SKILL.md has 'Verdict Aggregation'"
check_single_file_contains "TC-05" "$BASE_DIR/skills/review/SKILL.md" 'Verdict Aggregation' "review SKILL.md has 'Verdict Aggregation'"

# TC-06: [Given] architect.md / [When] pre_review スキーマ節（## Output）+ 判定基準節
#         （### Design Review Gate）/ [Then] '"score"' 行なし・verdict 3 トークンが判定基準節内にあり
#         （addendum 2 item 13: 単体語 PASS/WARN/BLOCK の whole-file grep 禁止 — rules/test-patterns.md
#         「単体語で pin」— を節スコープ限定に是正。判定基準節は verdict トークンが実際に定義される
#         場所であり、whole-file grep では散文中の同語（"orchestrate が...進行" 等）でも偽 PASS し得る）
echo ""
echo "TC-06: architect.md pre_review has no 'score' field, has PASS/WARN/BLOCK tokens in 判定基準節"
ARCHITECT_FILE="$BASE_DIR/agents/architect.md"
if [ ! -f "$ARCHITECT_FILE" ]; then
  fail "TC-06: agents/architect.md not found"
else
  output_block=$(section_grep "$ARCHITECT_FILE" "## Output")
  verdict_criteria_block=$(section_grep "$ARCHITECT_FILE" "### Design Review Gate")
  if printf '%s\n' "$output_block" | grep -qE '"score"[[:space:]]*:'; then
    fail "TC-06: architect.md ## Output block still has a \"score\": field"
  elif [ -z "$verdict_criteria_block" ]; then
    fail "TC-06: architect.md '### Design Review Gate' section not found"
  elif ! { printf '%s\n' "$verdict_criteria_block" | grep -q 'PASS' \
         && printf '%s\n' "$verdict_criteria_block" | grep -q 'WARN' \
         && printf '%s\n' "$verdict_criteria_block" | grep -q 'BLOCK'; }; then
    fail "TC-06: architect.md '### Design Review Gate' section missing one of PASS/WARN/BLOCK verdict tokens"
  else
    pass "TC-06: architect.md pre_review has no score field and 判定基準節 has PASS/WARN/BLOCK tokens"
  fi
fi

# TC-07: [Given] socrates.md Input 表 / [When] grep / [Then] 'severity_counts' あり・'統合スコア (0-100)' なし
echo ""
echo "TC-07: socrates.md Input table has 'severity_counts', not old '統合スコア (0-100)'"
SOCRATES_FILE="$BASE_DIR/agents/socrates.md"
if [ ! -f "$SOCRATES_FILE" ]; then
  fail "TC-07: agents/socrates.md not found"
elif ! grep -q 'severity_counts' "$SOCRATES_FILE"; then
  fail "TC-07: socrates.md missing 'severity_counts'"
elif grep -qF '統合スコア (0-100)' "$SOCRATES_FILE"; then
  fail "TC-07: socrates.md still contains old '統合スコア (0-100)'"
else
  pass "TC-07: socrates.md Input table has severity_counts, no old 統合スコア (0-100)"
fi

# TC-08: [Given] out-of-scope files (observer 算術は別 cycle) / [When] grep /
#        [Then] 'confidence' が引き続き存在（変更なし）
# (旧 test-reviewer-scoring.sh TC-10 を内容そのまま維持 — observer/false-positive-filter/learn/
#  diagnose は本 cycle の Out of Scope。番号は全面改稿に伴い TC-08 へ整理)
echo ""
echo "TC-08: Out-of-scope files still contain 'confidence' (unchanged)"
SCOPE_EXTERNAL=(
  "$BASE_DIR/agents/observer.md"
  "$BASE_DIR/agents/false-positive-filter-reference.md"
  "$BASE_DIR/skills/learn/reference.md"
  "$BASE_DIR/skills/diagnose/steps-subagent.md"
  "$BASE_DIR/skills/diagnose/reference.md"
)
check_all_files_contain "TC-08" 'confidence' "Out-of-scope files still contain 'confidence' (unchanged)" "${SCOPE_EXTERNAL[@]}"

# TC-09: [Given] 13 reviewer の Output fenced JSON 例 / [When] 抽出して mktemp dir に置き
#        severity-verdict.sh validate を実行 / [Then] 全て OK（validator 自身を oracle にする）
echo ""
echo "TC-09: All 13 reviewer Output examples are valid per severity-verdict.sh validate"
if [ ! -f "$SEVERITY_SCRIPT" ]; then
  fail "TC-09: $SEVERITY_SCRIPT not found (RED state — GREEN creates it)"
else
  TC09_DIR=$(mktemp -d)
  for reviewer in "${REVIEWERS[@]}"; do
    f="$BASE_DIR/agents/${reviewer}.md"
    [ -f "$f" ] || continue
    line=$(extract_output_line "$f")
    printf '%s' "$line" > "$TC09_DIR/${reviewer}.json"
  done
  tc09_out=$(bash "$SEVERITY_SCRIPT" validate "$TC09_DIR" 2>&1)
  tc09_rc=$?
  if [ "$tc09_rc" -eq 0 ]; then
    pass "TC-09: all 13 reviewer Output examples pass severity-verdict.sh validate"
  else
    fail "TC-09: severity-verdict.sh validate reported INVALID for some reviewer Output examples: $tc09_out"
  fi
  rm -rf "$TC09_DIR"
fi

# TC-10: [Given] steps-subagent.md Step 4.4 節 / [When] 文言 pin / [Then] 6 トークンが節内に存在
#        (決定的トリガー含む workflow 契約 pin)
echo ""
echo "TC-10: review/steps-subagent.md Step 4.4 section has the 6 required tokens"
REVIEW_STEPS="$BASE_DIR/skills/review/steps-subagent.md"
if [ ! -f "$REVIEW_STEPS" ]; then
  fail "TC-10: skills/review/steps-subagent.md not found"
else
  step44_section=$(section_grep "$REVIEW_STEPS" "## Step 4.4")
  if [ -z "$step44_section" ]; then
    fail "TC-10: '## Step 4.4' section not found in steps-subagent.md"
  else
    tc10_missing=""
    for token in "INVALID を返した場合のみ" "最大 1 回" "error 行を verbatim" "--invalid" "security-reviewer" "correctness-reviewer"; do
      if ! printf '%s\n' "$step44_section" | grep -qF -- "$token"; then
        tc10_missing="${tc10_missing} [${token}]"
      fi
    done
    if [ -z "$tc10_missing" ]; then
      pass "TC-10: Step 4.4 section contains all 6 required tokens"
    else
      fail "TC-10: Step 4.4 section missing tokens:$tc10_missing"
    fi
  fi
fi

# TC-11: [Given] repo 全体（docs/cycles・archive・requests・tests・.git・agent-memory を除外、
#        risk score 軸を名指し除外）/ [When] 数値閾値 sweep（blocking_score / 80-100|50-79|0-49 /
#        review 文脈の score:NN|score: NN）/ [Then] 0 件 — skills/spec/templates/cycle.md と
#        docs/usability.md を含む
# QA note (rules/plan-discipline.md): 除外 category と根拠を明記する。実行は real `bash <script>`
#   subprocess で printf oracle 実測した（対話シェルの grep alias(ugrep, --exclude-dir=.git 相当を
#   自動適用)は実運用の BSD grep と挙動が異なり、`.git/`・`./` prefix の有無で偽の集計になるため、
#   本 TC は bash -c サブプロセスで実測して確定した — 対話シェル実測を鵜呑みにしない）。
#   - ./docs/cycles/, ./docs/archive/, ./docs/requests/: historical record（過去 cycle・提案書の
#     記述は変更しない。requests/ は 20260315 時点の pre-cycle 提案で score:NN (risk score 言及) を
#     含むが本 cycle の対象外）
#   - ./tests/, ./.git/: テスト自身・VCS メタデータ（sweep 対象外）
#   - ./.claude/agent-memory/: architect 等の起動時注入 memory（"Design Review Gate: PASS
#     (score: N)" 等、第三の score 軸=agent memory の runtime 記録。Files to Change に含まれない
#     動的データであり、静的な plugin 定義の外側）
#   - ./CHANGELOG.md: 過去 cycle と同種の historical record。本 cycle の Changed 節は
#     "blocking_score 廃止" という事実を記述するため、旧語彙への言及そのものは除去できない
#   - ./skills/review/risk-classifier.sh 全体: risk score 軸（reviewer 起動数制御。
#     0-29/30-59/60+ の別軸）の "score:" 表記。語境界パターンは元々このスコープの数値と
#     重ならないため実害はないが、plan の名指し除外指定を保存する
#   - risk score 軸の内容アンカー（addendum 2 item 12: 行番号アンカーは REVIEW BLOCK 指摘により
#     内容アンカーへ置換 — 行番号は編集で drift し無防備な false-negative を生むため、除外対象の
#     実文言を fixed-string で pin する）:
#     - `- Risk Level: [LOW/MEDIUM/HIGH] (score: NN)`（agents/review-briefer.md・
#       skills/review/reference.md の Review Brief テンプレートに共通して出現する risk 行）
#     - `"LOW|MEDIUM|HIGH score:NN"`（skills/review/steps-subagent.md が risk-classifier.sh の
#       出力形式を引用する行。risk-classifier.sh 自身は上で全体除外済みのため二重に該当しても実害なし）
#   - `Total score: 65 (auth +60, no duplicates)`: skills/spec/reference.md の spec risk 軸
#     （risk calc 例）の内容アンカー
#   - ./agents/*attacker*.md: CVSS score 軸（無関係、現状マッチなしだが将来の drift に備える）
echo ""
echo "TC-11: repo-wide numeric-threshold sweep (blocking_score/80-100|50-79|0-49/score:NN) is 0 hits"
SWEEP_PATTERN='blocking_score|(^|[^0-9])(80-100|50-79|0-49)([^0-9]|$)|score: *(NN|[0-9]+)'
sweep_raw=$(cd "$BASE_DIR" && grep -rnE "$SWEEP_PATTERN" --include='*.md' --include='*.sh' . 2>/dev/null || true)

sweep_violations=""
if [ -n "$sweep_raw" ]; then
  sweep_violations=$(printf '%s\n' "$sweep_raw" \
    | grep -v '^\./docs/cycles/' \
    | grep -v '^\./docs/archive/' \
    | grep -v '^\./docs/requests/' \
    | grep -v '^\./tests/' \
    | grep -v '^\./\.git/' \
    | grep -v '^\./\.claude/agent-memory/' \
    | grep -v '^\./CHANGELOG\.md:' \
    | grep -v '^\./skills/review/risk-classifier\.sh' \
    | grep -vF -- '- Risk Level: [LOW/MEDIUM/HIGH] (score: NN)' \
    | grep -vF -- '"LOW|MEDIUM|HIGH score:NN"' \
    | grep -vF -- 'Total score: 65 (auth +60, no duplicates)' \
    | grep -vE '^\./agents/[a-zA-Z-]*attacker[a-zA-Z-]*\.md:' \
    || true)
fi

sweep_count=0
if [ -n "$sweep_violations" ]; then
  sweep_count=$(printf '%s\n' "$sweep_violations" | grep -c '')
fi

if [ "$sweep_count" -eq 0 ]; then
  pass "TC-11: repo-wide numeric-threshold sweep found 0 hits (excluding historical/risk-axis-immune files)"
else
  fail "TC-11: repo-wide numeric-threshold sweep found $sweep_count hits: $(printf '%s' "$sweep_violations" | head -5)..."
fi

# =============================================================================
# TC-12: [Given] skills/ + rules mirror 両方の *.md / [When] `severity-verdict.sh verdict`
#         への言及行を全走査 / [Then] 全行が `--invalid` 引き継ぎを併記している
#         （Codex post-hoc review P1-2: steps-codex.md の Codex findings 統合再実行が
#         `--invalid` を落とすと、INVALID reviewer の fail-closed floor
#         （security/correctness は NON-NEGOTIABLE BLOCK）が再実行で消える。
#         行単位 invariant として pin し、将来の再実行記述の追加にも適用する）
# =============================================================================
echo ""
echo "TC-12: every 'severity-verdict.sh verdict' mention in skills/ and rules mirrors carries --invalid forwarding"
verdict_lines=$(cd "$BASE_DIR" && grep -rn 'severity-verdict\.sh verdict' skills/ rules/ .claude/rules/ --include='*.md' 2>/dev/null || true)
missing_invalid=""
if [ -n "$verdict_lines" ]; then
  missing_invalid=$(printf '%s\n' "$verdict_lines" | grep -vF -- '--invalid' || true)
fi
if [ -z "$verdict_lines" ]; then
  fail "TC-12: no 'severity-verdict.sh verdict' mention found under skills//rules/ (vacuous — invariant target missing)"
elif [ -z "$missing_invalid" ]; then
  pass "TC-12: all verdict invocation mentions carry --invalid forwarding"
else
  fail "TC-12: verdict mention(s) without --invalid forwarding: $missing_invalid"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
