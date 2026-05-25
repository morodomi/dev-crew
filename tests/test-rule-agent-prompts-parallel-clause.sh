#!/usr/bin/env bash
# test-rule-agent-prompts-parallel-clause.sh
# TC01: rules/agent-prompts.md (canonical) と .claude/rules/agent-prompts.md (mirror) の
#       「並列起動時の prompt 契約」セクション存在・順序・挿入位置・identical 検証
#
# rules/test-patterns.md 準拠:
#   - case-sensitive grep (grep -i 禁止)
#   - section-specific awk 抽出 (whole-file grep 禁止)
#   - rc 記録パターン ($(cmd)...$? 並置禁止)
#   - ERE alternation: | 直接 (grep -E "a\|b" 禁止)
#   - pipefail masking 回避 (bash subject | grep -q 直接 pipe 禁止)
#
# rules/multi-file-consistency.md 準拠:
#   - 順序検証は行番号比較 (line_a < line_b) で実装

set -euo pipefail

BASE_DIR="${BASE_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

CANONICAL="$BASE_DIR/rules/agent-prompts.md"
MIRROR="$BASE_DIR/.claude/rules/agent-prompts.md"
SECTION_HEADING="並列起動時の prompt 契約"

echo "=== test-rule-agent-prompts-parallel-clause (TC01) ==="

# ---------------------------------------------------------------------------
# Helper: extract lines within section (H2 heading to next H2 heading)
# Usage: section_lines <file> <heading_literal>
# Outputs the lines inside the section (not the heading itself)
# ---------------------------------------------------------------------------
section_lines() {
  local file="$1"
  local heading="$2"
  awk -v h="^## ${heading}" '
    $0 ~ h { in_sec=1; next }
    in_sec && /^## / { in_sec=0 }
    in_sec { print }
  ' "$file"
}

# ---------------------------------------------------------------------------
# Helper: get first matching line number from grep
# Usage: get_first_line_number <file> <pattern>
# Outputs the line number (empty string if no match). Safe under set -euo pipefail.
# ---------------------------------------------------------------------------
get_first_line_number() {
  local file="$1"
  local pattern="$2"
  local raw
  raw=$(grep -n "$pattern" "$file" 2>/dev/null || true)
  echo "$raw" | head -1 | cut -d: -f1
}

# ---------------------------------------------------------------------------
# TC-01: 両ファイルに「並列起動時の prompt 契約」section が存在する
# ---------------------------------------------------------------------------
echo ""
echo "TC-01: 両ファイルに '${SECTION_HEADING}' section が存在する"

if [ ! -f "$CANONICAL" ]; then
  fail "TC-01: canonical $CANONICAL が存在しない"
elif [ ! -f "$MIRROR" ]; then
  fail "TC-01: mirror $MIRROR が存在しない"
else
  # case-sensitive grep で section heading を検索 (grep -i 禁止)
  count_canonical=$(grep -cF "## ${SECTION_HEADING}" "$CANONICAL" || true)
  count_mirror=$(grep -cF "## ${SECTION_HEADING}" "$MIRROR" || true)

  if [ "$count_canonical" -ge 1 ] && [ "$count_mirror" -ge 1 ]; then
    pass "TC-01: canonical + mirror 両方に '${SECTION_HEADING}' section が存在する"
  elif [ "$count_canonical" -lt 1 ]; then
    fail "TC-01: canonical ($CANONICAL) に '## ${SECTION_HEADING}' が存在しない"
  else
    fail "TC-01: mirror ($MIRROR) に '## ${SECTION_HEADING}' が存在しない"
  fi
fi

# ---------------------------------------------------------------------------
# TC-02: section 内に 5 キーワードが記述順で出現する
#   順序: 担当範囲 → 入力 → 出力形式 → 統合キー → 検証条件
#   実装: awk で section 範囲を抽出、各キーワードの最初の出現行番号を取得して昇順検証
# ---------------------------------------------------------------------------
echo ""
echo "TC-02: section 内に 5 キーワードが記述順 (担当範囲→入力→出力形式→統合キー→検証条件) で出現する"

check_keyword_order() {
  local file="$1"
  local label="$2"

  if [ ! -f "$file" ]; then
    fail "TC-02 ($label): ファイルが存在しない"
    return
  fi

  # section 内コンテンツを取得し、行番号付きで一時ファイルに書き出す
  # awk で section 範囲を抽出後、grep -n で行番号取得
  local section_content
  section_content=$(section_lines "$file" "${SECTION_HEADING}")

  if [ -z "$section_content" ]; then
    fail "TC-02 ($label): '${SECTION_HEADING}' section が空または存在しない"
    return
  fi

  # 各キーワードの最初の出現行番号を取得 (0 = 未出現)
  # grep -n で行番号付き出力 → head -1 で最初の行 → cut で行番号のみ抽出
  get_line() {
    local kw="$1"
    # pipefail masking 回避: 変数に受け取ってから grep
    local lines
    lines=$(echo "$section_content" | grep -n "$kw" || true)
    echo "$lines" | head -1 | cut -d: -f1
  }

  local line_tantou line_input line_output line_togo line_kensho
  line_tantou=$(get_line "担当範囲")
  line_input=$(get_line "入力")
  line_output=$(get_line "出力形式")
  line_togo=$(get_line "統合キー")
  line_kensho=$(get_line "検証条件")

  # 未出現チェック
  if [ -z "$line_tantou" ]; then
    fail "TC-02 ($label): section 内に '担当範囲' が存在しない"
    return
  fi
  if [ -z "$line_input" ]; then
    fail "TC-02 ($label): section 内に '入力' が存在しない"
    return
  fi
  if [ -z "$line_output" ]; then
    fail "TC-02 ($label): section 内に '出力形式' が存在しない"
    return
  fi
  if [ -z "$line_togo" ]; then
    fail "TC-02 ($label): section 内に '統合キー' が存在しない"
    return
  fi
  if [ -z "$line_kensho" ]; then
    fail "TC-02 ($label): section 内に '検証条件' が存在しない"
    return
  fi

  # 昇順検証: line_a < line_b (multi-file-consistency.md 順序検証パターン準拠)
  if [ "$line_tantou" -lt "$line_input" ] \
    && [ "$line_input" -lt "$line_output" ] \
    && [ "$line_output" -lt "$line_togo" ] \
    && [ "$line_togo" -lt "$line_kensho" ]; then
    pass "TC-02 ($label): 5 キーワードが正しい記述順で出現する (行 $line_tantou < $line_input < $line_output < $line_togo < $line_kensho)"
  else
    fail "TC-02 ($label): 5 キーワードの出現順序が不正 (担当範囲=$line_tantou 入力=$line_input 出力形式=$line_output 統合キー=$line_togo 検証条件=$line_kensho)"
  fi
}

check_keyword_order "$CANONICAL" "canonical"
check_keyword_order "$MIRROR" "mirror"

# ---------------------------------------------------------------------------
# TC-03: section の挿入位置検証
#   「## 推奨」の行番号 < 「## 並列起動時の prompt 契約」の行番号 < 「## 具体例」の行番号
#   multi-file-consistency.md 順序検証パターン準拠
# ---------------------------------------------------------------------------
echo ""
echo "TC-03: section 挿入位置 (推奨 < ${SECTION_HEADING} < 具体例) の行番号順検証"

check_insertion_order() {
  local file="$1"
  local label="$2"

  if [ ! -f "$file" ]; then
    fail "TC-03 ($label): ファイルが存在しない"
    return
  fi

  # get_first_line_number helper で各見出しの行番号を取得 (case-sensitive, set -e safe)
  local line_suishou line_parallel line_gutarei
  line_suishou=$(get_first_line_number "$file" "^## 推奨")
  line_parallel=$(get_first_line_number "$file" "^## ${SECTION_HEADING}")
  line_gutarei=$(get_first_line_number "$file" "^## 具体例")

  if [ -z "$line_suishou" ]; then
    fail "TC-03 ($label): '## 推奨' 見出しが存在しない"
    return
  fi
  if [ -z "$line_parallel" ]; then
    fail "TC-03 ($label): '## ${SECTION_HEADING}' 見出しが存在しない"
    return
  fi
  if [ -z "$line_gutarei" ]; then
    fail "TC-03 ($label): '## 具体例' 見出しが存在しない"
    return
  fi

  # 順序検証: 推奨 < 並列起動時の prompt 契約 < 具体例
  if [ "$line_suishou" -lt "$line_parallel" ] && [ "$line_parallel" -lt "$line_gutarei" ]; then
    pass "TC-03 ($label): 挿入位置が正しい (推奨=$line_suishou < ${SECTION_HEADING}=$line_parallel < 具体例=$line_gutarei)"
  elif [ "$line_suishou" -ge "$line_parallel" ]; then
    fail "TC-03 ($label): '${SECTION_HEADING}' が '推奨' より前に出現している (推奨=$line_suishou, section=$line_parallel)"
  else
    fail "TC-03 ($label): '${SECTION_HEADING}' が '具体例' の後に出現している (section=$line_parallel, 具体例=$line_gutarei)"
  fi
}

check_insertion_order "$CANONICAL" "canonical"
check_insertion_order "$MIRROR" "mirror"

# ---------------------------------------------------------------------------
# TC-04: canonical と mirror で section content が identical (diff 0 件)
# ---------------------------------------------------------------------------
echo ""
echo "TC-04: canonical と mirror の '${SECTION_HEADING}' section content が identical"

if [ ! -f "$CANONICAL" ] || [ ! -f "$MIRROR" ]; then
  fail "TC-04: canonical または mirror が存在しないため diff 不可"
else
  # section 内容を変数に取得してから diff
  canonical_section=$(section_lines "$CANONICAL" "${SECTION_HEADING}")
  mirror_section=$(section_lines "$MIRROR" "${SECTION_HEADING}")

  if [ -z "$canonical_section" ] && [ -z "$mirror_section" ]; then
    fail "TC-04: canonical + mirror 両方の '${SECTION_HEADING}' section が空または存在しない"
  elif [ -z "$canonical_section" ]; then
    fail "TC-04: canonical の '${SECTION_HEADING}' section が空または存在しない"
  elif [ -z "$mirror_section" ]; then
    fail "TC-04: mirror の '${SECTION_HEADING}' section が空または存在しない"
  else
    # diff で比較 (rc 記録パターン準拠)
    diff_output=$(diff <(echo "$canonical_section") <(echo "$mirror_section") || true)
    if [ -z "$diff_output" ]; then
      pass "TC-04: canonical と mirror の section content が identical (diff 0 件)"
    else
      fail "TC-04: canonical と mirror の section content に差分あり (diff: $diff_output)"
    fi
  fi
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
