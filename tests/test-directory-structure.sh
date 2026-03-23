#!/bin/bash
# test-directory-structure.sh - docs/cycles/ directory structure validation
# TC-DS01〜TC-DS09

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

# Helper: 新形式判定 (frontmatter内に feature: があれば新形式)
is_new_format() {
  local file="$1"
  head -20 "$file" | sed -n '/^---$/,/^---$/p' | grep -q "^feature:"
}

# Helper: frontmatter存在判定
has_frontmatter() {
  head -1 "$1" | grep -q "^---$"
}

# Helper: ファイル名パターン検証 (YYYYMMDD_HHMM_*.md)
# macOS/Linux両対応の純粋正規表現マッチ
is_valid_filename() {
  local name="$1"
  # bash extended glob: grepでポータブルに検証
  echo "$name" | grep -qE \
    '^[0-9]{4}(0[1-9]|1[0-2])(0[1-9]|[12][0-9]|3[01])_([01][0-9]|2[0-3])[0-5][0-9]_.+\.md$'
}

echo "=== Directory Structure Tests ==="

# TC-DS01: docs/cycles/ ディレクトリが存在する
echo ""
echo "TC-DS01: docs/cycles/ directory exists"
CYCLES_DIR="$BASE_DIR/docs/cycles"
if [ -d "$CYCLES_DIR" ]; then
  pass "docs/cycles/ directory exists"
else
  fail "docs/cycles/ directory does NOT exist"
fi

# TC-DS02: 全Cycle docファイル名が YYYYMMDD_HHMM_*.md パターンに一致 (archive/除外)
echo ""
echo "TC-DS02: all Cycle doc filenames match YYYYMMDD_HHMM_*.md pattern (excluding archive/)"
invalid_names=()
while IFS= read -r -d '' filepath; do
  name="$(basename "$filepath")"
  if ! is_valid_filename "$name"; then
    invalid_names+=("$name")
  fi
done < <(find "$CYCLES_DIR" -maxdepth 1 -name "*.md" -print0 2>/dev/null)

if [ "${#invalid_names[@]}" -eq 0 ]; then
  pass "All Cycle doc filenames match YYYYMMDD_HHMM_*.md pattern"
else
  fail "Invalid filenames found: ${invalid_names[*]}"
fi

# TC-DS03: 新形式Cycle docが必須frontmatterフィールドを持つ (feature, cycle, phase, created, updated)
echo ""
echo "TC-DS03: new-format Cycle docs have required frontmatter fields"
tc03_fail=0
while IFS= read -r -d '' filepath; do
  if ! has_frontmatter "$filepath"; then
    continue
  fi
  if ! is_new_format "$filepath"; then
    continue
  fi
  name="$(basename "$filepath")"
  # frontmatter ブロック抽出: 1行目の --- から次の --- まで (awk でポータブルに)
  fm_block=$(awk 'NR==1 && /^---$/{found=1; next} found && /^---$/{exit} found{print}' "$filepath")
  for field in feature cycle phase created updated; do
    if ! echo "$fm_block" | grep -q "^${field}:"; then
      fail "[$name] required field missing: '$field'"
      tc03_fail=$((tc03_fail + 1))
    fi
  done
done < <(find "$CYCLES_DIR" -maxdepth 1 -name "*.md" -print0 2>/dev/null)

if [ "$tc03_fail" -eq 0 ]; then
  pass "All new-format Cycle docs have required frontmatter fields"
fi

# TC-DS04: [Negative] 不正なファイル名パターンを検出 (fixture)
echo ""
echo "TC-DS04: [Negative] detects invalid filename pattern"
tmpdir=$(mktemp -d)
touch "$tmpdir/invalid_name.md"
touch "$tmpdir/20260399_9999_bad-timestamp.md"
touch "$tmpdir/20260101_1200_valid.md"

invalid_count=0
for filepath in "$tmpdir"/*.md; do
  name="$(basename "$filepath")"
  if ! is_valid_filename "$name"; then
    invalid_count=$((invalid_count + 1))
  fi
done

if [ "$invalid_count" -eq 2 ]; then
  pass "Correctly detected 2 invalid filenames (expected)"
else
  fail "Expected 2 invalid filenames, got $invalid_count"
fi
rm -rf "$tmpdir"

# TC-DS05: [Negative] 必須frontmatterフィールド欠落を検出 (fixture)
echo ""
echo "TC-DS05: [Negative] detects missing required frontmatter field"
tmpdir=$(mktemp -d)
# feature フィールドはあるが created/updated が欠落した新形式doc
cat > "$tmpdir/20260101_1200_missing-fields.md" << 'EOF'
---
feature: test-feature
cycle: test-cycle
phase: RED
complexity: trivial
test_count: 1
risk_level: low
---

# Missing created/updated fields
EOF

found_missing=0
filepath="$tmpdir/20260101_1200_missing-fields.md"
if has_frontmatter "$filepath" && is_new_format "$filepath"; then
  fm_block=$(awk 'NR==1 && /^---$/{found=1; next} found && /^---$/{exit} found{print}' "$filepath")
  for field in feature cycle phase created updated; do
    if ! echo "$fm_block" | grep -q "^${field}:"; then
      found_missing=$((found_missing + 1))
    fi
  done
fi

if [ "$found_missing" -gt 0 ]; then
  pass "Correctly detected $found_missing missing required fields in fixture"
else
  fail "Failed to detect missing frontmatter fields"
fi
rm -rf "$tmpdir"

# TC-DS06: 旧形式Cycle doc (title:/status: フィールドあり、feature: なし) がスキップされる (fixture)
echo ""
echo "TC-DS06: old-format Cycle doc (no feature: field) is skipped"
tmpdir=$(mktemp -d)
# 旧形式: title:/status: あり、feature: なし
cat > "$tmpdir/20260323_1352_old-format.md" << 'EOF'
---
phase: DONE
title: "Phase 29: Old Format"
date: 2026-03-23
status: DONE
---

# Old Format Doc
EOF

skip_count=0
filepath="$tmpdir/20260323_1352_old-format.md"
if has_frontmatter "$filepath" && ! is_new_format "$filepath"; then
  skip_count=$((skip_count + 1))
fi

if [ "$skip_count" -eq 1 ]; then
  pass "Old-format Cycle doc correctly skipped (no feature: field)"
else
  fail "Old-format Cycle doc was NOT skipped"
fi
rm -rf "$tmpdir"

# TC-DS07: archiveディレクトリのdocがスキップされる
echo ""
echo "TC-DS07: docs in archive/ directory are skipped"
ARCHIVE_DIR="$CYCLES_DIR/archive"
if [ -d "$ARCHIVE_DIR" ]; then
  # find with maxdepth 1 excludes archive/ subdirectory
  archive_in_main=$(find "$CYCLES_DIR" -maxdepth 1 -name "*.md" -path "*/archive/*" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$archive_in_main" -eq 0 ]; then
    pass "archive/ docs are not included in maxdepth 1 search (correctly excluded)"
  else
    fail "archive/ docs were unexpectedly included in main search"
  fi
else
  pass "archive/ directory does not exist (no docs to skip)"
fi

# TC-DS08: frontmatterなしのCycle docがスキップされる (fixture)
echo ""
echo "TC-DS08: Cycle doc without frontmatter is skipped"
tmpdir=$(mktemp -d)
# frontmatterなしのdoc
cat > "$tmpdir/20260101_1200_no-frontmatter.md" << 'EOF'
# No Frontmatter Doc

This document has no YAML frontmatter at all.
EOF

skip_count=0
filepath="$tmpdir/20260101_1200_no-frontmatter.md"
if ! has_frontmatter "$filepath"; then
  skip_count=$((skip_count + 1))
fi

if [ "$skip_count" -eq 1 ]; then
  pass "Doc without frontmatter correctly skipped"
else
  fail "Doc without frontmatter was NOT skipped"
fi
rm -rf "$tmpdir"

# TC-DS09: ファイル名のタイムスタンプが妥当な範囲 (月01-12, 日01-31, 時00-23, 分00-59)
echo ""
echo "TC-DS09: filename timestamps are in valid range"
tc09_fail=0

# 妥当なタイムスタンプ (TC-DS09用、より厳密なパターンで検証)
while IFS= read -r -d '' filepath; do
  name="$(basename "$filepath")"
  if ! is_valid_filename "$name"; then
    continue
  fi
  # YYYYMMDD_HHMM から各要素を抽出
  mm="${name:4:2}"   # 月 (05 in 20260523)
  dd="${name:6:2}"   # 日
  hh="${name:9:2}"   # 時 (後の _ を除く)
  mn="${name:11:2}"  # 分

  # 数値変換して範囲チェック
  mm_num=$((10#$mm))
  dd_num=$((10#$dd))
  hh_num=$((10#$hh))
  mn_num=$((10#$mn))

  if [ "$mm_num" -lt 1 ] || [ "$mm_num" -gt 12 ]; then
    fail "[$name] month out of range: $mm"
    tc09_fail=$((tc09_fail + 1))
  elif [ "$dd_num" -lt 1 ] || [ "$dd_num" -gt 31 ]; then
    fail "[$name] day out of range: $dd"
    tc09_fail=$((tc09_fail + 1))
  elif [ "$hh_num" -gt 23 ]; then
    fail "[$name] hour out of range: $hh"
    tc09_fail=$((tc09_fail + 1))
  elif [ "$mn_num" -gt 59 ]; then
    fail "[$name] minute out of range: $mn"
    tc09_fail=$((tc09_fail + 1))
  fi
done < <(find "$CYCLES_DIR" -maxdepth 1 -name "*.md" -print0 2>/dev/null)

if [ "$tc09_fail" -eq 0 ]; then
  pass "All Cycle doc timestamps are in valid range"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
