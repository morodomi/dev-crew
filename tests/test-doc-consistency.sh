#!/bin/bash
# test-doc-consistency.sh - Document consistency validation
# TC-01 ~ TC-32（欠番: 01, 03, 06-10, 13, 26, 27 — 削除済みTC。TC-13 は
# docs/cycles/20260916_1634_shrink-runner-remove-nesting.md で run-tests.sh
# への nested full-suite 実行を除去するため削除）+ TC-C2-3 ~ TC-C2-5 + TC-33a~f

set -euo pipefail

BASE_DIR="${BASE_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== Document Consistency Tests ==="

########################################
# Skill count consistency
########################################

echo ""
echo "--- Skill Count Consistency ---"

# Count actual skill directories
ACTUAL_COUNT=$(find "$BASE_DIR/skills" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')

# TC-02: architecture.md skill count = actual skill directories
echo ""
echo "TC-02: architecture.md skill count check (skip if absent per CONSTITUTION)"
arch_count=$(grep -oE '[0-9]+ skills' "$BASE_DIR/docs/architecture.md" 2>/dev/null | head -1 | grep -oE '[0-9]+' || true)
if [ -z "$arch_count" ]; then
  pass "architecture.md does not hardcode skill count (CONSTITUTION principle honored)"
elif [ "$arch_count" = "$ACTUAL_COUNT" ]; then
  pass "architecture.md skill count ($arch_count) = actual ($ACTUAL_COUNT)"
else
  fail "architecture.md skill count ($arch_count) != actual ($ACTUAL_COUNT)"
fi

########################################
# Missing skill listings
########################################

echo ""
echo "--- Missing Skill Listings ---"

# TC-04: README.md lists "skill-maker"
echo ""
echo "TC-04: README.md lists 'skill-maker'"
if grep -q "skill-maker" "$BASE_DIR/README.md"; then
  pass "README.md lists skill-maker"
else
  fail "README.md does not list skill-maker"
fi

# TC-05: README.md lists "security-audit"
echo ""
echo "TC-05: README.md lists 'security-audit'"
if grep -q "security-audit" "$BASE_DIR/README.md"; then
  pass "README.md lists security-audit"
else
  fail "README.md does not list security-audit"
fi

########################################
# Content accuracy
########################################

echo ""
echo "--- Content Accuracy ---"

# TC-11: sync-plan.md or archive has test category content
echo ""
echo "TC-11: sync-plan agent or archive has relevant content"
if [ -f "$BASE_DIR/agents/sync-plan.md" ]; then
  pass "sync-plan.md exists (test categories migrated to archive)"
else
  fail "sync-plan.md does not exist"
fi

# TC-12: CLAUDE.md has "Usage Patterns" section
echo ""
echo "TC-12: CLAUDE.md has 'Usage Patterns' section"
if grep -q "## Usage Patterns" "$BASE_DIR/CLAUDE.md"; then
  pass "CLAUDE.md has Usage Patterns section"
else
  fail "CLAUDE.md does not have Usage Patterns section"
fi

########################################
# Terminology consistency (docs/terminology.md)
########################################

echo ""
echo "--- Terminology Consistency ---"

# TC-14: /simplify not present in key skill/doc files (fully removed)
echo ""
echo "TC-14: /simplify absent from key files"
TERM_FAIL=0
for rel_file in README.md skills/orchestrate/SKILL.md skills/refactor/SKILL.md CLAUDE.md docs/terminology.md; do
  file="$BASE_DIR/$rel_file"
  [ -f "$file" ] || continue
  if grep -q '/simplify' "$file"; then
    fail "/simplify found in $rel_file"
    TERM_FAIL=1
  fi
done
if [ "$TERM_FAIL" -eq 0 ]; then
  pass "/simplify absent from key files"
fi

# TC-15: Phase names UPPERCASE in orchestrate SKILL.md workflow steps
echo ""
echo "TC-15: Phase names UPPERCASE in orchestrate SKILL.md"
PHASE_FAIL=0
for phase in RED GREEN REFACTOR REVIEW COMMIT; do
  lower=$(echo "$phase" | tr '[:upper:]' '[:lower:]')
  # Block 2 numbered steps use "N. **PHASE**:" pattern
  if grep -qE "^[0-9]+\. \*\*${lower}\*\*" "$BASE_DIR/skills/orchestrate/SKILL.md"; then
    fail "orchestrate SKILL.md uses lowercase '$lower' instead of '$phase'"
    PHASE_FAIL=1
  fi
done
if [ "$PHASE_FAIL" -eq 0 ]; then
  pass "Phase names UPPERCASE in orchestrate SKILL.md"
fi

########################################
# Inverse Contract — deleted skill stale-ref check
########################################

echo ""
echo "--- Inverse Contract: Deleted Skill Stale-ref ---"

# TC-16: tracked live files (git ls-files, excluding docs/cycles|decisions|archive +
# CHANGELOG.md — historical/changelog references to deleted skills are expected there)
# have zero path-form references to deleted skills phase-compact/reload/strategy/parallel.
# git ls-files ベース: grep --exclude-dir 方式は ignored local file
# (.claude/settings.local.json 等) にも hit し、path prune が不完全なため使わない。
# xargs は空入力時の macOS 挙動が不安定なため使わず、while ループで1ファイルずつ
# 判定する (rules/test-patterns.md 準拠)。git ls-files 自体の失敗（non-git dir 等）が
# 空出力を生み while ループが黙って 0 回実行され false-pass する経路を防ぐため、
# git 呼び出しの rc と filter 後の対象ファイル数を先に検証してから判定する
echo ""
echo "TC-16: tracked live files have 0 hits for 'skills/(phase-compact|reload|strategy|parallel)'"
tracked_rc=0
tracked=$(git -C "$BASE_DIR" ls-files 2>/dev/null) || tracked_rc=$?
if [ "$tracked_rc" -ne 0 ]; then
  fail "TC-16: git ls-files failed (rc=$tracked_rc) — cannot verify inverse contract"
else
  targets=$(echo "$tracked" | grep -vE "^docs/(cycles|decisions|archive)/|^CHANGELOG\.md$") || targets=""
  target_count=$(echo "$targets" | grep -c . || true)
  if [ "$target_count" -eq 0 ]; then
    fail "TC-16: filtered target file list is empty — filter likely over-excludes (0 files to check)"
  else
    STALE_HITS=0
    while IFS= read -r f; do
      [ -f "$BASE_DIR/$f" ] || continue
      if grep -qE "skills/(phase-compact|reload|strategy|parallel)" "$BASE_DIR/$f" 2>/dev/null; then
        STALE_HITS=$((STALE_HITS + 1))
      fi
    done < <(echo "$targets")
    if [ "$STALE_HITS" -eq 0 ]; then
      pass "No tracked live file references deleted skills phase-compact/reload/strategy/parallel ($target_count files checked)"
    else
      fail "$STALE_HITS tracked live file(s) reference deleted skills phase-compact/reload/strategy/parallel"
    fi
  fi
fi

########################################
# Tracking Label Inverse Contract (追跡ラベル自動契約)
########################################

echo ""
echo "--- Tracking Label Inverse Contract ---"

# TC-17: tests/*.sh のコメント行に追跡番号ラベル（cycle 番号 / issue 番号）が混入していないことを
# 保証する逆向き契約。委譲 prompt テンプレート由来で 3 cycle 連続再発した違反
# (rules/plan-discipline.md 2-strike rule の初適用対象) を自動契約に昇格する。
# 対象ファイル一覧を配列に受けて件数を直後検査する（glob 失敗が空ループで
# 黙って 0 件 PASS になるのを防ぐ、rules/test-patterns.md 準拠）。
# nullglob を一時的に有効化し、no-match 時に glob パターンの literal 文字列が
# 配列に残ってしまう bash デフォルト挙動を避ける（TEST_FILE_COUNT を実効的に 0 にする）。
# grep 結果も変数受け + rc 直後検査し、rc>=2（grep 自体のエラー）を
# 0 件 PASS に紛れ込ませない（process substitution ではなく command substitution で受ける）。
echo ""
echo "TC-17: tests/*.sh comment lines have 0 tracking-label hits (cycle NNNNNNNN / issue #N)"
TRACKING_LABEL_PATTERN='^[[:space:]]*#.*(cycle[: (]+2026[0-9]{4}|issue #[0-9]+)'
shopt -s nullglob
TEST_FILES=("$BASE_DIR"/tests/*.sh)
shopt -u nullglob
TEST_FILE_COUNT=${#TEST_FILES[@]}
if [ "$TEST_FILE_COUNT" -eq 0 ]; then
  fail "TC-17: tests/*.sh glob matched 0 files — glob likely failed, cannot verify inverse contract"
else
  # grep rc=1 (no match, the expected post-GREEN state) must not trip `set -e` and
  # silently abort the whole subject script — capture rc via `||` instead of a bare
  # $(...) assignment (rules/test-patterns.md 変数に受けて + rc 直後検査 の self-apply)
  LABEL_HITS_RC=0
  LABEL_HITS=$(grep -nEi "$TRACKING_LABEL_PATTERN" "${TEST_FILES[@]}" 2>/dev/null) || LABEL_HITS_RC=$?
  if [ "$LABEL_HITS_RC" -ge 2 ]; then
    fail "TC-17: grep failed with rc=$LABEL_HITS_RC (not a clean match/no-match) — cannot verify inverse contract"
  elif [ "$LABEL_HITS_RC" -eq 1 ]; then
    pass "TC-17: No tracking-label hits in tests/*.sh comment lines ($TEST_FILE_COUNT files checked)"
  else
    HIT_COUNT=$(echo "$LABEL_HITS" | grep -c . || true)
    fail "TC-17: $HIT_COUNT tracking-label hit(s) found in tests/*.sh comment lines"
    echo "$LABEL_HITS"
  fi
fi

########################################
# Cycle Doc Phase Lifecycle (completion invariant)
########################################

echo ""
echo "--- Cycle Doc Phase Lifecycle ---"

# TC-18: live docs/cycles/*.md（非再帰 glob のため archive/ は自動除外）の frontmatter phase を
# awk 区間抽出で判定し、DONE でない doc が定常状態で最大 1 件（進行中 cycle）であることを保証する
# 逆向き契約。phase フィールド自体が無い旧形式 doc は集計対象外（既存 gate と同じ扱い）。
# glob 0 件は前提破綻のため FAIL 扱い（rules/test-patterns.md nullglob 方式、直前の契約踏襲）。
echo ""
echo "TC-18: live docs/cycles/ non-DONE doc count <= 1"
shopt -s nullglob
CYCLE_DOCS=("$BASE_DIR"/docs/cycles/*.md)
shopt -u nullglob
CYCLE_DOC_COUNT=${#CYCLE_DOCS[@]}
if [ "$CYCLE_DOC_COUNT" -eq 0 ]; then
  fail "TC-18: docs/cycles/*.md glob matched 0 files — glob likely failed, cannot verify invariant"
else
  NON_DONE_DOCS=()
  for f in "${CYCLE_DOCS[@]}"; do
    fm=$(awk '/^---$/{c++;next} c==1{print}' "$f")
    phase_line=$(echo "$fm" | grep '^phase:' || true)
    [ -z "$phase_line" ] && continue
    echo "$phase_line" | grep -q 'DONE' && continue
    NON_DONE_DOCS+=("$f")
  done
  NON_DONE_COUNT=${#NON_DONE_DOCS[@]}
  if [ "$NON_DONE_COUNT" -le 1 ]; then
    pass "TC-18: non-DONE doc count ($NON_DONE_COUNT) <= 1 ($CYCLE_DOC_COUNT docs checked)"
  else
    fail "TC-18: non-DONE doc count ($NON_DONE_COUNT) > 1"
    printf '%s\n' "${NON_DONE_DOCS[@]}"
  fi
fi

########################################
# External Support Wording (stale support-status wording inverse contract)
########################################

echo ""
echo "--- External Support Wording ---"

# TC-19: README.md/SECURITY.md の外部サポート文言が新表現（No external support /
# no external support）に統一され、旧表現（Not Maintained / not maintained）が
# 残っていないことを保証する逆向き契約。case-sensitive literal（grep -F）で
# 大文字/小文字の両形を個別に検査する (rules/test-patterns.md: case-insensitive grep 禁止)
echo ""
echo "TC-19: README.md/SECURITY.md の外部サポート文言が更新済み（stale 0件・新文言各1件以上）"
stale_upper=$(grep -cF "Not Maintained" "$BASE_DIR/README.md" "$BASE_DIR/SECURITY.md" 2>/dev/null | awk -F: '{s+=$2} END{print s+0}' || true)
stale_lower=$(grep -cF "not maintained" "$BASE_DIR/README.md" "$BASE_DIR/SECURITY.md" 2>/dev/null | awk -F: '{s+=$2} END{print s+0}' || true)
[ -z "$stale_upper" ] && stale_upper=0
[ -z "$stale_lower" ] && stale_lower=0
stale_total=$((stale_upper + stale_lower))

readme_new=$(grep -cF "No external support" "$BASE_DIR/README.md" 2>/dev/null || true)
[ -z "$readme_new" ] && readme_new=0
security_new=$(grep -cF "no external support" "$BASE_DIR/SECURITY.md" 2>/dev/null || true)
[ -z "$security_new" ] && security_new=0

if [ "$stale_total" -eq 0 ] && [ "$readme_new" -ge 1 ] && [ "$security_new" -ge 1 ]; then
  pass "TC-19: stale 外部サポート文言 0 件 かつ README/SECURITY 新文言 各1件以上"
else
  fail "TC-19: stale=${stale_total} 件（Not Maintained=${stale_upper}, not maintained=${stale_lower}）/ README new=${readme_new} / SECURITY new=${security_new}"
fi

########################################
# Approval Reorder Cycle 2 — narrative doc sync (usability / ROADMAP / CHANGELOG)
########################################

echo ""
echo "--- Approval Reorder Cycle 2 ---"

# section extraction helper: extracts lines within a fixed-string H2 heading section.
# Heading matched via awk index() prefix (fixed-string), not regex — avoids ERE
# metachar pitfalls with headings like "[Unreleased]" (rules/test-patterns.md).
section_grep() {
  local file="$1"
  local heading="$2"
  local pattern="$3"
  awk -v h="$heading" '
    index($0, "## " h) == 1 {in_sec=1; next}
    in_sec && /^## /{in_sec=0}
    in_sec
  ' "$file" | grep -cF "$pattern" || true
}

# TC-C2-3: usability.md Phase Transition フロー図の plan mode 区間に
# plan-review が approve より前に存在することを検査。
# 見出し範囲（## Phase Transition UX）を先に抽出してから code block を探すことで、
# 別 section に偶然 "plan mode:" を含む fenced block があっても誤って拾わない
# （section 外の記述による偽 PASS 防止、rules/test-patterns.md 準拠）
echo ""
echo "TC-C2-3: usability.md flow diagram — plan-review precedes approve in plan mode line"
FILE="$BASE_DIR/docs/usability.md"
if [ ! -f "$FILE" ]; then
  fail "TC-C2-3: docs/usability.md not found"
else
  PHASE_TRANSITION_SECTION=$(awk '
    index($0, "## Phase Transition UX") == 1 {in_sec=1; next}
    in_sec && /^## /{in_sec=0}
    in_sec
  ' "$FILE")
  if [ -z "$PHASE_TRANSITION_SECTION" ]; then
    fail "TC-C2-3: '## Phase Transition UX' section not found (extraction failed)"
  else
    FLOW_BLOCK=$(printf '%s\n' "$PHASE_TRANSITION_SECTION" | awk '
      /^```/ {
        if (capturing) {
          if (index(buf, "plan mode:") > 0) { print buf; exit }
          capturing = 0
          next
        } else {
          capturing = 1
          buf = ""
          next
        }
      }
      capturing { buf = buf $0 "\n" }
    ')
    PLAN_MODE_LINE=$(printf '%s\n' "$FLOW_BLOCK" | grep -F 'plan mode:' || true)
    if [ -z "$PLAN_MODE_LINE" ]; then
      fail "TC-C2-3: 'plan mode:' line not found in Phase Transition UX flow diagram block (extraction failed)"
    else
      pr_idx=$(printf '%s' "$PLAN_MODE_LINE" | awk '{print index($0, "plan-review")}')
      ap_idx=$(printf '%s' "$PLAN_MODE_LINE" | awk '{print index($0, "approve")}')
      if [ "$pr_idx" -gt 0 ] && [ "$ap_idx" -gt 0 ] && [ "$pr_idx" -lt "$ap_idx" ]; then
        pass "TC-C2-3: plan-review precedes approve in plan mode line"
      else
        fail "TC-C2-3: plan-review does not precede approve (plan-review idx=$pr_idx, approve idx=$ap_idx)"
      fi
    fi
  fi
fi

# TC-C2-4: ROADMAP.md 現在地 section が approval-reorder または #176 に言及
echo ""
echo "TC-C2-4: ROADMAP.md 現在地 section mentions approval-reorder or #176"
FILE="$BASE_DIR/ROADMAP.md"
if [ ! -f "$FILE" ]; then
  fail "TC-C2-4: ROADMAP.md not found"
else
  count_approval=$(section_grep "$FILE" "現在地" "approval-reorder")
  count_issue176=$(section_grep "$FILE" "現在地" "#176")
  if [ "$count_approval" -ge 1 ] || [ "$count_issue176" -ge 1 ]; then
    pass "TC-C2-4: ROADMAP.md 現在地 mentions approval-reorder or #176"
  else
    fail "TC-C2-4: ROADMAP.md 現在地 section missing approval-reorder/#176 reference"
  fi
fi

# TC-C2-5: CHANGELOG.md の [2.13.0] セクションの "### Breaking" subsection 内に
# approval-reorder または #176 の言及があることを検査。
# approval-reorder の Breaking は v2.13.0 で出荷され [2.13.0] セクションに確定した。
# リリース済み version セクションは immutable な履歴のため、そこへ直接アンカーする。
# 旧実装の「先頭 version セクション」方式は、リリース後に新しい [Unreleased] を
# 新設した時点で対象がすり替わり、無関係な cycle に approval-reorder の Breaking 記載を
# 恒久要求する誤 BLOCK を起こすため廃止。
# section 全体で approval-reorder と Breaking を独立カウントすると、別機能の Breaking 項目が
# 残っている限り approval-reorder 側の Breaking 記述を消しても PASS してしまう
# （両者の関連性が pin されない）ため、Breaking subsection を先に抽出しその中限定で判定する
echo ""
echo "TC-C2-5: CHANGELOG.md [2.13.0] section '### Breaking' subsection mentions approval-reorder or #176"
FILE="$BASE_DIR/CHANGELOG.md"
if [ ! -f "$FILE" ]; then
  fail "TC-C2-5: CHANGELOG.md not found"
else
  # '## [2.13.0]' 見出しから次の '## ' 見出しまでを抽出
  RELEASE_SECTION=$(awk '
    index($0, "## [2.13.0]") == 1 {in_sec=1; next}
    in_sec && /^## /{in_sec=0}
    in_sec
  ' "$FILE")
  if [ -z "$RELEASE_SECTION" ]; then
    fail "TC-C2-5: [2.13.0] version section not found (extraction failed)"
  else
    BREAKING_SUBSECTION=$(printf '%s\n' "$RELEASE_SECTION" | awk '
      index($0, "### Breaking") == 1 {in_sub=1; next}
      in_sub && /^#/{in_sub=0}
      in_sub
    ')
    if [ -z "$BREAKING_SUBSECTION" ]; then
      fail "TC-C2-5: '### Breaking' subsection not found within [2.13.0] section (extraction failed)"
    else
      count_approval=$(printf '%s\n' "$BREAKING_SUBSECTION" | grep -cF "approval-reorder" || true)
      count_issue176=$(printf '%s\n' "$BREAKING_SUBSECTION" | grep -cF "#176" || true)
      [ -z "$count_approval" ] && count_approval=0
      [ -z "$count_issue176" ] && count_issue176=0
      if [ "$count_approval" -ge 1 ] || [ "$count_issue176" -ge 1 ]; then
        pass "TC-C2-5: CHANGELOG.md [2.13.0] Breaking subsection mentions approval-reorder or #176"
      else
        fail "TC-C2-5: CHANGELOG.md [2.13.0] Breaking subsection missing approval-reorder/#176 reference"
      fi
    fi
  fi
fi

########################################
# Staleness Hook Removal — negative contracts
########################################

echo ""
echo "--- Staleness Hook Removal ---"

# assert_zero_hits <tc_id> <file> <grep_flags> <pattern> <subject_label>
# 「このファイルにこのパターンが 1 件も無い」型の negative 契約を 1 箇所に集約する。
# abort-safety: この suite は tests/test-meta-doc-consistency.sh から、対象ファイルを
# 持たない fixture 上で BASE_DIR override 実行される。裸の $(grep ...) 代入は不一致時に
# rc=1 を返し set -e で Summary 到達前に abort するため、2>/dev/null + || true で防御し、
# 空文字は 0 に正規化する。ファイル欠落は vacuous PASS にせず fail() で報告する。
# count_hits <file> <grep_flags> <pattern>
# ヒット数を stdout へ、判定不能（ファイル欠落 / grep 実行エラー）を rc で返す。
# rc は直後に取得して rc>=2（grep 自体の失敗: 不正 ERE・権限拒否）を「0 件」から
# 分離する。`grep -c` はマッチなしでも stdout に 0 を出して rc=1 を返すため、
# 「マッチなし」と「実行エラー」は rc でしか区別できない。rc>=2 を先に return 2 で
# 弾くことで、実行エラーが「0 件 = PASS」に化けるのを防ぐ（同ファイル TC-17 の規律）。
# 後段の空文字→0 の正規化は -c 以外のモードで呼ばれた場合に備えた防御であり、
# rc>=2 は上で弾かれているためエラー隠蔽にはならない。
# rc: 0=判定できた / 1=ファイル欠落 / 2=grep 実行エラー
count_hits() {
  local file="$1" grep_flags="$2" pattern="$3"
  [ -f "$file" ] || return 1
  local hits grep_rc=0
  hits=$(grep "$grep_flags" -e "$pattern" "$file" 2>/dev/null) || grep_rc=$?
  [ "$grep_rc" -ge 2 ] && return 2
  [ -z "$hits" ] && hits=0
  printf '%s' "$hits"
}

assert_zero_hits() {
  local tc_id="$1" file="$2" grep_flags="$3" pattern="$4" label="$5"
  local hits rc=0
  hits=$(count_hits "$file" "$grep_flags" "$pattern") || rc=$?
  case "$rc" in
    1) fail "$tc_id: $label not found"; return ;;
    2) fail "$tc_id: grep failed on $label — cannot verify"; return ;;
  esac
  if [ "$hits" -eq 0 ]; then
    pass "$tc_id: $label has 0 hits"
  else
    fail "$tc_id: $label has $hits hit(s)"
  fi
}

# assert_min_hits <tc_id> <file> <grep_flags> <pattern> <min> <label>
# 「このファイルにこのパターンが min 件以上ある」型の positive 契約。overshoot 防止の
# ガード（削除しすぎを検出する）に使う。assert_zero_hits と同一の abort-safety を持つ:
# rc=1（ファイル欠落）/ rc=2（grep 実行エラー）を vacuous PASS にせず fail() で報告する。
assert_min_hits() {
  local tc_id="$1" file="$2" grep_flags="$3" pattern="$4" min="$5" label="$6"
  local hits rc=0
  hits=$(count_hits "$file" "$grep_flags" "$pattern") || rc=$?
  case "$rc" in
    1) fail "$tc_id: $label not found"; return ;;
    2) fail "$tc_id: grep failed on $label — cannot verify"; return ;;
  esac
  if [ "$hits" -ge "$min" ]; then
    pass "$tc_id: $label has $hits hit(s) (>= $min)"
  else
    fail "$tc_id: $label has $hits hit(s) (< $min)"
  fi
}

# assert_exact_hits <tc_id> <file> <grep_flags> <pattern> <expected> <label>
# 「このファイルにこのパターンがちょうど expected 件ある」型の契約。合計方式では
# 重複と欠落が相殺して偽 PASS するケース（TC-33f）を検出するため、見出しごとの
# exact-1 判定に使う。abort-safety は assert_zero_hits / assert_min_hits と同一。
assert_exact_hits() {
  local tc_id="$1" file="$2" grep_flags="$3" pattern="$4" expected="$5" label="$6"
  local hits rc=0
  hits=$(count_hits "$file" "$grep_flags" "$pattern") || rc=$?
  case "$rc" in
    1) fail "$tc_id: $label not found"; return ;;
    2) fail "$tc_id: grep failed on $label — cannot verify"; return ;;
  esac
  if [ "$hits" -eq "$expected" ]; then
    pass "$tc_id: $label has exactly $hits hit(s)"
  else
    fail "$tc_id: $label has $hits hit(s) (expected $expected)"
  fi
}

# TC-20: scripts/hooks/check-claude-md-staleness.sh does not exist (negative contract).
# `[ -f ... ]` は set -e 下でも if 条件式のため abort しない。fixture でも同様に不在 → PASS
# (abort-safety: fixture には scripts/ 自体が無いため常に不在 = 常に PASS で無害)
echo ""
echo "TC-20: scripts/hooks/check-claude-md-staleness.sh does not exist"
if [ -f "$BASE_DIR/scripts/hooks/check-claude-md-staleness.sh" ]; then
  fail "TC-20: check-claude-md-staleness.sh still exists"
else
  pass "TC-20: check-claude-md-staleness.sh does not exist"
fi

# TC-21: tests/test-hooks-structure.sh に staleness 専用識別子が0件（恒久negative契約）。
# fixture には tests/ が無いため、ファイル欠落時は fail() で報告しSummaryへ到達させる
# (abort-safety: 裸 command substitution を避け 2>/dev/null + || true で防御)
echo ""
echo "TC-21: tests/test-hooks-structure.sh has 0 hits for staleness-only identifiers"
assert_zero_hits "TC-21" "$BASE_DIR/tests/test-hooks-structure.sh" "-cE" \
  'check-claude-md-staleness|STALENESS_THRESHOLD_DAYS|fixture_repo_with_docs|fixture_commit_backdated|run_staleness_hook|DAY_SECONDS' \
  "tests/test-hooks-structure.sh staleness-only identifiers"

# TC-22: tests/test-agents-md-propagation.sh に 'STALENESS' が0件（恒久negative契約）
echo ""
echo "TC-22: tests/test-agents-md-propagation.sh has 0 hits for 'STALENESS'"
assert_zero_hits "TC-22" "$BASE_DIR/tests/test-agents-md-propagation.sh" "-cF" \
  "STALENESS" "tests/test-agents-md-propagation.sh STALENESS"

########################################
# Derived-Fact Contracts — skills / hooks / agents count
########################################

echo ""
echo "--- Derived-Fact Contracts ---"

# TC-23: AGENTS.md の 'Skills available:' 行をパースした skill 名集合が
# skills/*/ の basename 集合と完全一致することを検査。差分は欠落・余剰の両方向で報告する。
# abort-safety: AGENTS.md 欠落時（fixture）は fail() で報告しSummaryへ到達させる
echo ""
echo "TC-23: AGENTS.md 'Skills available:' set matches skills/*/ directory set"
AGENTS_FILE="$BASE_DIR/AGENTS.md"
if [ ! -f "$AGENTS_FILE" ]; then
  fail "TC-23: AGENTS.md not found"
else
  TC23_LINE=$(grep -m1 '^Skills available:' "$AGENTS_FILE" 2>/dev/null) || true
  if [ -z "$TC23_LINE" ]; then
    fail "TC-23: 'Skills available:' line not found in AGENTS.md"
  else
    TC23_DECLARED=$(echo "$TC23_LINE" | sed 's/^Skills available: *//' | tr ',' '\n' | sed 's/^ *//; s/ *$//' | sort) || true
    TC23_ACTUAL=$(find "$BASE_DIR/skills" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null | sort) || true
    TC23_MISSING=$(comm -23 <(printf '%s\n' "$TC23_ACTUAL") <(printf '%s\n' "$TC23_DECLARED") 2>/dev/null) || true
    TC23_EXTRA=$(comm -13 <(printf '%s\n' "$TC23_ACTUAL") <(printf '%s\n' "$TC23_DECLARED") 2>/dev/null) || true
    if [ -z "$TC23_MISSING" ] && [ -z "$TC23_EXTRA" ]; then
      pass "TC-23: AGENTS.md Skills available set matches skills/*/ directory set"
    else
      fail "TC-23: mismatch — missing from AGENTS.md list=[$(echo "$TC23_MISSING" | tr '\n' ' ')] extra in AGENTS.md list=[$(echo "$TC23_EXTRA" | tr '\n' ' ')]"
    fi
  fi
fi

# TC-24: CLAUDE.md の Hooks 表の script basename 集合が hooks/hooks.json の登録 command から
# 抽出した basename 集合と一致することを検査。`~/.claude/hooks/` 始まりの行（表に
# 「global hook」と明記されている）は除外する。
# abort-safety: CLAUDE.md / hooks.json いずれか欠落時（fixture）は fail() で報告する
echo ""
echo "TC-24: CLAUDE.md Hooks table script set matches hooks/hooks.json registered command set"
CLAUDE_FILE="$BASE_DIR/CLAUDE.md"
HOOKS_JSON="$BASE_DIR/hooks/hooks.json"
if [ ! -f "$CLAUDE_FILE" ] || [ ! -f "$HOOKS_JSON" ]; then
  fail "TC-24: CLAUDE.md or hooks/hooks.json not found"
else
  TC24_SECTION=$(awk '
    index($0, "## Hooks") == 1 {in_sec=1; next}
    in_sec && /^## /{in_sec=0}
    in_sec
  ' "$CLAUDE_FILE") || true
  TC24_CLAUDE_SCRIPTS=$(printf '%s\n' "$TC24_SECTION" | grep -oE '`[^`]+`' 2>/dev/null | tr -d '`' | grep -v '^~/\.claude/hooks/' | sed 's#.*/##' 2>/dev/null | sort -u) || true
  if ! command -v jq >/dev/null 2>&1; then
    fail "TC-24: jq not found — cannot verify hooks.json contract"
  else
    TC24_JSON_SCRIPTS=$(jq -r '.hooks[][].hooks[].command' "$HOOKS_JSON" 2>/dev/null | grep -oE '[A-Za-z0-9_-]+\.sh' 2>/dev/null | sort -u) || true
    if [ -n "$TC24_JSON_SCRIPTS" ] && [ "$TC24_CLAUDE_SCRIPTS" = "$TC24_JSON_SCRIPTS" ]; then
      pass "TC-24: CLAUDE.md Hooks table script set matches hooks.json registered command set"
    else
      fail "TC-24: mismatch — CLAUDE.md=[$(echo "$TC24_CLAUDE_SCRIPTS" | tr '\n' ' ')] hooks.json=[$(echo "$TC24_JSON_SCRIPTS" | tr '\n' ' ')]"
    fi
  fi
fi

# TC-25: CLAUDE.md に skill count / skills一覧が存在しない（CONSTITUTION §8の恒久negative契約、
# architecture.mdに対するTC-02と同型）。ファイル欠落は vacuous PASS にせず fail() で報告する
# (assert_zero_hits の fail-closed 方針。CLAUDE.md 消失自体が検出すべき異常)
echo ""
echo "TC-25: CLAUDE.md does not contain 'Available skills (N total)'"
assert_zero_hits "TC-25" "$BASE_DIR/CLAUDE.md" "-cE" \
  'Available skills \([0-9]+ total\)' "CLAUDE.md 'Available skills (N total)'"

STATUS_FILE="$BASE_DIR/docs/STATUS.md"

# TC-28: CLAUDE.md の 1 行目が `@AGENTS.md` であること。
# TC-25 が「CLAUDE.md に skills 一覧が戻っていないこと」を保証できるのは、AGENTS.md の
# 一覧がこの import 経由で読まれるという前提が成り立つ場合に限る。この 1 行が消えると
# skills 一覧は失われるのに TC-23〜27 は全て PASS のままになる（土台が無防備という
# 非対称）。行番号でなく「1 行目」という位置そのものが契約であるため head -1 で pin する。
echo ""
echo "TC-28: CLAUDE.md first line is '@AGENTS.md' (import that TC-25 depends on)"
TC28_FILE="$BASE_DIR/CLAUDE.md"
if [ ! -f "$TC28_FILE" ]; then
  fail "TC-28: CLAUDE.md not found"
else
  TC28_FIRST=$(head -1 "$TC28_FILE" 2>/dev/null) || TC28_FIRST=""
  if [ "$TC28_FIRST" = "@AGENTS.md" ]; then
    pass "TC-28: CLAUDE.md first line is '@AGENTS.md'"
  else
    fail "TC-28: CLAUDE.md first line is '$TC28_FIRST' (expected '@AGENTS.md')"
  fi
fi

########################################
# STATUS.md Derived-Number Removal — negative/positive contracts
########################################

echo ""
echo "--- STATUS.md Derived-Number Removal ---"

# TC-29: Given 変更後の docs/STATUS.md / When Current State の Metric 表 6 行を
# 「行頭 + ラベル + 数値セル + 行末」まで固定した regex と `## Current State` 見出しを grep
# / Then いずれも 0 件（恒久 negative 契約）。
# 数値セルと行末の固定が必須: ラベルのみの行頭固定だと保持対象の
# `## Cycle Doc Lifecycle` 表・AGENTS.md Constraints 表・docs/v3-failure-modes.md を
# 誤検出する（PdM・architect 実測確認）。
# abort-safety: 裸 command substitution を避け 2>/dev/null + rc 直後取得で防御し、
# ファイル欠落・grep 実行エラー(rc>=2) は vacuous PASS にせず fail() で報告する。
echo ""
echo "TC-29: docs/STATUS.md has 0 Current State Metric table rows and 0 '## Current State' heading"
# セル区切り前後の空白は [[:space:]]* で受ける。空白 1 個に固定すると
# `|Skills|28|` や `|  Skills  |  28  |` がすり抜け、表の再生成やフォーマッタで
# 空白数が変わった瞬間に契約が無力化する（printf oracle で 3 形式すべて検出、
# 実 STATUS.md では 0 件を維持することを実測確認済み）。
TC29_TABLE_RE='^[[:space:]]*\|[[:space:]]*(In-Progress Cycles|Done \(unarchived\)|Archived Cycles|Skills|Agents|Test Scripts)[[:space:]]*\|[[:space:]]*[0-9]+[[:space:]]*\|[[:space:]]*$'
# 見出しも行全体で固定する。部分一致にすると、Completed 行や本文で
# 「`## Current State` 見出しを削除した」と説明しただけで FAIL する。
TC29_HEADING_RE='^[[:space:]]*##[[:space:]]+Current State[[:space:]]*$'
# rc は明示初期化する。成功時は代入されないため、環境から非ゼロ値を継承すると
# 見出し検査を飛ばして未定義の tc29_heading_hits を参照し set -u で abort する。
tc29_rc=0
tc29_table_hits=0
tc29_heading_hits=0
tc29_table_hits=$(count_hits "$STATUS_FILE" "-cE" "$TC29_TABLE_RE") || tc29_rc=$?
if [ "$tc29_rc" -eq 0 ]; then
  tc29_heading_hits=$(count_hits "$STATUS_FILE" "-cE" "$TC29_HEADING_RE") || tc29_rc=$?
fi
case "$tc29_rc" in
  1) fail "TC-29: docs/STATUS.md not found" ;;
  2) fail "TC-29: grep failed on docs/STATUS.md — cannot verify" ;;
  *) if [ "$tc29_table_hits" -eq 0 ] && [ "$tc29_heading_hits" -eq 0 ]; then
       pass "TC-29: docs/STATUS.md has 0 Metric table rows and 0 '## Current State' heading"
     else
       fail "TC-29: docs/STATUS.md has $tc29_table_hits Metric table row hit(s) and $tc29_heading_hits '## Current State' heading hit(s)"
     fi ;;
esac

# TC-30: Given 変更後の docs/STATUS.md / When `Last updated:` 行を grep / Then 1 件以上
# （削除しすぎていないことの positive 契約。境界: L14 の `Last updated:` は派生事実ではなく
# タイムスタンプであり残す対象）。
echo ""
echo "TC-30: docs/STATUS.md has at least 1 'Last updated:' line"
tc30_rc=0
tc30_hits=$(count_hits "$STATUS_FILE" "-cE" '^Last updated:') || tc30_rc=$?
case "$tc30_rc" in
  1) fail "TC-30: docs/STATUS.md not found" ;;
  2) fail "TC-30: grep failed on docs/STATUS.md 'Last updated:' — cannot verify" ;;
  *) if [ "$tc30_hits" -ge 1 ]; then
       pass "TC-30: docs/STATUS.md has $tc30_hits 'Last updated:' line(s)"
     else
       fail "TC-30: docs/STATUS.md has 0 'Last updated:' lines"
     fi ;;
esac

# TC-31: Given 変更後の scripts/gates/pre-commit-gate.sh / When `Test Scripts` を grep
# / Then 0 件（STATUS.md 同期 WARN check 削除の恒久 negative 契約）。
echo ""
echo "TC-31: scripts/gates/pre-commit-gate.sh has 0 hits for 'Test Scripts'"
assert_zero_hits "TC-31" "$BASE_DIR/scripts/gates/pre-commit-gate.sh" "-cF" \
  "Test Scripts" "scripts/gates/pre-commit-gate.sh 'Test Scripts'"

# TC-32a〜f: 宙に浮いた STATUS.md 派生数値への doc 参照が残っていないことを
# 対象ごとに検査する（1 対象 = 1 TC）:
#   a) docs/architecture.md の 'STATUS.md for counts'
#   b) docs/skill-map.md の 'Counts: [STATUS.md]'（grep -F 必須 — 角括弧の ERE 誤解釈回避）
#   c) docs/README.md の 'テスト数'
#   d) docs/workflow.md の gate 検証対象リストに並ぶ 'STATUS.md同期'
#   e) docs/workflow.md の gate 行の検証対象カラムに並ぶ 'STATUS.md'
#      （L120 は「同期」の語を使わず列挙形式で書くため d の literal では取りこぼす）
#   f) docs/skill-map.md の 'STATUS.md同期'
# d/e は「削除した check の責務記述」だけを狙い、STATUS.md への正当な言及
# （commit skill が義務付ける Completed 更新手順の説明など）は許容する。
# ファイル全体禁止にすると開発フローの正典が必須手順を記述できなくなる。
# abort-safety: 各チェックはファイル欠落・grep 実行エラー(rc>=2) を「0件」に丸めず
# fail() で報告してから Summary へ到達する（assert_zero_hits / count_hits）。
# 1 対象 = 1 TC にするのは (a) 失敗時にどの対象かが pass/fail 行から読め
# (b)「各 negative 契約に変異注入 oracle を当てる」プロトコルを全対象で満たせるため。
echo ""
echo "TC-32a: docs/architecture.md has 0 hits for 'STATUS.md for counts'"
assert_zero_hits "TC-32a" "$BASE_DIR/docs/architecture.md" "-cF" \
  "STATUS.md for counts" "docs/architecture.md 'STATUS.md for counts'"

echo ""
echo "TC-32b: docs/skill-map.md has 0 hits for 'Counts: [STATUS.md]'"
assert_zero_hits "TC-32b" "$BASE_DIR/docs/skill-map.md" "-cF" \
  "Counts: [STATUS.md]" "docs/skill-map.md 'Counts: [STATUS.md]'"

echo ""
echo "TC-32c: docs/README.md has 0 hits for 'テスト数'"
assert_zero_hits "TC-32c" "$BASE_DIR/docs/README.md" "-cF" \
  "テスト数" "docs/README.md 'テスト数'"

# workflow.md はファイル全体ではなく「gate の責務としての STATUS.md 同期」だけを禁じる。
# 全体禁止にすると、skills/commit/SKILL.md が義務付ける「STATUS.md の Completed へ
# 完了タスクを移動」という手順を、開発フローの正典である workflow.md が恒久的に
# 記述できなくなる（削除済み check の責務記述を消すのが目的であり、STATUS.md への
# 正当な言及まで締め出すのは scope 過大）。
echo ""
# 削除した check の責務記述だけを狙う。単に `STATUS.md同期` を全面禁止すると
# 「commit skill が STATUS.md同期を行う」のような正当な記述まで落ちるため、
# gate が検証する対象の列挙（`REVIEW完了` / `Codex review記録` と並ぶ形）に限定する。
echo "TC-32d: docs/workflow.md has 0 gate-verification lists including STATUS.md同期"
assert_zero_hits "TC-32d" "$BASE_DIR/docs/workflow.md" "-cE" \
  '(REVIEW完了|Codex review記録)[^|]*STATUS\.md同期|STATUS\.md同期[^|]*(retro_status|を検証)' \
  "docs/workflow.md gate verification list with STATUS.md同期"

# L120 は「同期」の語を使わず列挙形式（`REVIEW, Codex review, STATUS.md, retro_status`）
# で責務を書くため上の literal では取りこぼす。gate 行の「検証対象カラム」に
# STATUS.md が並ぶ形だけを禁じ、手順を説明する自由記述は許容する。
echo ""
echo "TC-32e: docs/workflow.md has 0 gate rows listing STATUS.md in the verified-items column"
assert_zero_hits "TC-32e" "$BASE_DIR/docs/workflow.md" "-cE" \
  'pre-commit-gate[^|]*\|[^|]*(REVIEW|Codex review)[^|]*STATUS\.md' \
  "docs/workflow.md gate row listing STATUS.md as a verified item"

echo ""
echo "TC-32f: docs/skill-map.md has 0 hits for 'STATUS.md同期'"
assert_zero_hits "TC-32f" "$BASE_DIR/docs/skill-map.md" "-cF" \
  "STATUS.md同期" "docs/skill-map.md 'STATUS.md同期'"

########################################
# README/AGENTS derived-number reintroduction guard
########################################

echo ""
echo "--- README/AGENTS Derived-Number Reintroduction Guard ---"

# TC33_TREE_RE / TC33_HEAD_RE: 1 度だけ定義し TC-33a〜f 全体で共有する。
# TC33_TREE_RE は agents/ skills/ のツリー行に限定し、round 1〜3 で誤検出・検出漏れの
# 両方が出た「カウント名詞クラス」の一般化を放棄した round 4 確定形（plan Test List 参照）。
# `agents/` `skills/` 以外のツリー行（例: `├── tests/  # 116 test scripts`）は対象外。
# 逆に widening 側の代償として、`agents/` `skills/` 行のコメントに現れる数字は
# 件数と無関係なものも一律拒否する（ADR 番号・バージョン番号・`OWASP Top 10` 等）。
# この 2 行にそうした記述が必要になったら契約を明示的に変更すること — 気づけない
# drift ではなくテストの FAIL として可視化される、という設計上の取引である。
# TC33_HEAD_RE は 4 見出し名限定 + 括弧付きカウントを行末まで固定するため
# `### Security for PHP 8` 等の正当な将来記述は誤検出しない。
TC33_TREE_RE='^[[:space:]│]*[├└]──[[:space:]]+(agents|skills)/.*[0-9]'
TC33_HEAD_RE='^###[[:space:]]+(Development Workflow|Security|Language Quality|Meta)[[:space:]]+\([[:space:]]*[0-9]+[[:space:]]*\)[[:space:]]*$'

# TC-33a: Given 変更後の AGENTS.md / When TC33_TREE_RE を -cE で grep / Then 0 件
echo ""
echo "TC-33a: AGENTS.md has 0 hits for TC33_TREE_RE (agents/skills tree-line derived counts)"
assert_zero_hits "TC-33a" "$BASE_DIR/AGENTS.md" "-cE" \
  "$TC33_TREE_RE" "AGENTS.md agents/skills ツリー行コメント中の数字"

# TC-33b: Given 変更後の README.md / When 同 TC33_TREE_RE / Then 0 件
echo ""
echo "TC-33b: README.md has 0 hits for TC33_TREE_RE (agents/skills tree-line derived counts)"
assert_zero_hits "TC-33b" "$BASE_DIR/README.md" "-cE" \
  "$TC33_TREE_RE" "README.md agents/skills ツリー行コメント中の数字"

# TC-33c: Given 変更後の README.md / When TC33_HEAD_RE を -cE で grep / Then 0 件
echo ""
echo "TC-33c: README.md has 0 hits for TC33_HEAD_RE (section-heading derived counts)"
assert_zero_hits "TC-33c" "$BASE_DIR/README.md" "-cE" \
  "$TC33_HEAD_RE" "README.md Skills 見出しの括弧付き件数"

# TC-33d: Given 変更後の AGENTS.md / When '├── agents/' と '├── skills/' を -cF で grep
# / Then 各 1 件以上（overshoot 防止のガード。削除しすぎでツリー行自体が消えたことを検出する。
# ツリー行は最初から存在するため RED→GREEN 遷移を持たず、RED 時点から PASS が期待挙動）
echo ""
echo "TC-33d: AGENTS.md retains agents/ and skills/ tree lines"
# -cF の全文部分一致では、ツリー行を削除して同じ文字列をコメント等へ移すだけで
# PASS してしまい overshoot ガードが無効になる（Codex 再現: 行削除 + コメント追記で -cF=1）。
# 行頭アンカー + 枝記号クラスにして「ツリー構造の中に実在する行」だけを数える。
# 枝記号・空白幅は TC33_TREE_RE と同じ許容にし、negative/positive の非対称を作らない。
assert_min_hits "TC-33d" "$BASE_DIR/AGENTS.md" "-cE" \
  '^[[:space:]│]*[├└]──[[:space:]]+agents/' 1 "AGENTS.md agents/ ツリー行"
assert_min_hits "TC-33d" "$BASE_DIR/AGENTS.md" "-cE" \
  '^[[:space:]│]*[├└]──[[:space:]]+skills/' 1 "AGENTS.md skills/ ツリー行"

# TC-33e: Given 変更後の README.md / When 同 / Then 各 1 件以上
echo ""
echo "TC-33e: README.md retains agents/ and skills/ tree lines"
assert_min_hits "TC-33e" "$BASE_DIR/README.md" "-cE" \
  '^[[:space:]│]*[├└]──[[:space:]]+agents/' 1 "README.md agents/ ツリー行"
assert_min_hits "TC-33e" "$BASE_DIR/README.md" "-cE" \
  '^[[:space:]│]*[├└]──[[:space:]]+skills/' 1 "README.md skills/ ツリー行"

# TC-33f: Given 変更後の README.md / When 4 見出しを '^### <name>$' で 1 つずつ grep
# / Then 各ちょうど 1 件。「合計 4 件」にしてはいけない（Codex P1-3、PdM 実測で再現）。
# 合計方式は Development Workflow の重複と Security の欠落が相殺して 4 件になり PASS
# してしまう。4 見出しを個別に exact-1 検査することで重複・欠落を独立に検出する。
echo ""
echo "TC-33f: README.md has exactly 1 heading each for Development Workflow / Security / Language Quality / Meta"
assert_exact_hits "TC-33f" "$BASE_DIR/README.md" "-cE" \
  '^### Development Workflow$' 1 "README.md '### Development Workflow' heading"
assert_exact_hits "TC-33f" "$BASE_DIR/README.md" "-cE" \
  '^### Security$' 1 "README.md '### Security' heading"
assert_exact_hits "TC-33f" "$BASE_DIR/README.md" "-cE" \
  '^### Language Quality$' 1 "README.md '### Language Quality' heading"
assert_exact_hits "TC-33f" "$BASE_DIR/README.md" "-cE" \
  '^### Meta$' 1 "README.md '### Meta' heading"

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
