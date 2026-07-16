#!/bin/bash
# test-doc-consistency.sh - Document consistency validation
# TC-01 ~ TC-19（欠番: 03, 06-10 — 削除済みTC）

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

# TC-01: README.md skill count = actual skill directories
echo ""
echo "TC-01: README.md skill count matches actual ($ACTUAL_COUNT)"
readme_counts=$(grep -oE '[0-9]+ skills' "$BASE_DIR/README.md" 2>/dev/null | head -1 | grep -oE '[0-9]+' || true)
if [ "$readme_counts" = "$ACTUAL_COUNT" ]; then
  pass "README.md skill count ($readme_counts) = actual ($ACTUAL_COUNT)"
else
  fail "README.md skill count ($readme_counts) != actual ($ACTUAL_COUNT)"
fi

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
# Regression
########################################

echo ""
echo "--- Regression ---"

# TC-13: All existing tests pass
echo ""
echo "TC-13: Existing tests pass"
existing_fail=0
for test_file in "$BASE_DIR/tests"/test-*.sh; do
  test_name=$(basename "$test_file")
  # Skip ourselves and meta test to avoid recursion
  [ "$test_name" = "test-doc-consistency.sh" ] && continue
  [ "$test_name" = "test-meta-doc-consistency.sh" ] && continue
  if ! bash "$test_file" > /dev/null 2>&1; then
    fail "Existing test failed: $test_name"
    existing_fail=1
  fi
done
if [ "$existing_fail" -eq 0 ]; then
  pass "All existing tests pass"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
