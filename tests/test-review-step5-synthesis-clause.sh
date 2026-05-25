#!/usr/bin/env bash
# test-review-step5-synthesis-clause.sh
# TC02: skills/review/steps-subagent.md の Step 5 に
#       「Findings Synthesis」サブセクション構造・順序・キーワード・参照検証
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

SUBJECT="$BASE_DIR/skills/review/steps-subagent.md"

echo "=== test-review-step5-synthesis-clause (TC02) ==="

# ---------------------------------------------------------------------------
# Helper: extract lines within Step 5 section (from "^## Step 5:" to "^## Step 6:")
# Outputs the lines inside the section (not the headings themselves)
# ---------------------------------------------------------------------------
step5_lines() {
  # End condition uses generic ^## (any next H2 heading) for symmetry with
  # section_lines pattern. Robust to future H2 inserts between Step 5 and Step 6.
  awk '
    /^## Step 5:/ { in_sec=1; next }
    in_sec && /^## / { in_sec=0 }
    in_sec { print }
  ' "$SUBJECT"
}

# ---------------------------------------------------------------------------
# Helper: get first matching line number from grep
# Usage: get_first_line_number <pattern>
# Outputs the line number (empty string if no match). Safe under set -euo pipefail.
# ---------------------------------------------------------------------------
get_first_line_number() {
  local pattern="$1"
  local raw
  raw=$(grep -n "$pattern" "$SUBJECT" 2>/dev/null || true)
  echo "$raw" | head -1 | cut -d: -f1
}

# ---------------------------------------------------------------------------
# TC-01: Step 5 内に「Findings Synthesis」サブセクションが存在する
#   awk で「^## Step 5:」から「^## Step 6:」の範囲を抽出後、「### Findings Synthesis」を grep
# ---------------------------------------------------------------------------
echo ""
echo "TC-01: Step 5 内に '### Findings Synthesis' サブセクションが存在する"

if [ ! -f "$SUBJECT" ]; then
  fail "TC-01: $SUBJECT が存在しない"
else
  section_content=$(step5_lines)

  if [ -z "$section_content" ]; then
    fail "TC-01: Step 5 section が空または存在しない (## Step 5: が見つからない)"
  else
    # pipefail masking 回避: 変数受け取り後 grep
    count=$(echo "$section_content" | grep -cF "### Findings Synthesis" || true)
    if [ "$count" -ge 1 ]; then
      pass "TC-01: Step 5 内に '### Findings Synthesis' サブセクションが存在する"
    else
      fail "TC-01: Step 5 内に '### Findings Synthesis' サブセクションが存在しない"
    fi
  fi
fi

# ---------------------------------------------------------------------------
# TC-02: 「### Findings Synthesis」が「## Step 5:」見出しの直後 (= ### Score Aggregation より前)
#        に配置される。Cycle doc Design Approach: Synthesis は Score Aggregation の前段。
#        強化: Step 5 と Findings Synthesis の間に他の H3 が割り込んでいないことも検証 (Codex F1 対応)
#   multi-file-consistency.md 順序検証パターン準拠
# ---------------------------------------------------------------------------
echo ""
echo "TC-02: 'Findings Synthesis' が Step 5 見出しの直後 (Score Aggregation より前) に配置される"

if [ ! -f "$SUBJECT" ]; then
  fail "TC-02: $SUBJECT が存在しない"
else
  # get_first_line_number helper で各見出しの行番号を取得 (case-sensitive, set -e safe)
  line_step5=$(get_first_line_number "^## Step 5:")
  line_synthesis=$(get_first_line_number "### Findings Synthesis")
  line_score_agg=$(get_first_line_number "### Score Aggregation")

  if [ -z "$line_step5" ]; then
    fail "TC-02: '## Step 5:' 見出しが存在しない"
  elif [ -z "$line_synthesis" ]; then
    fail "TC-02: '### Findings Synthesis' が存在しない"
  elif [ -z "$line_score_agg" ]; then
    fail "TC-02: '### Score Aggregation' が存在しない"
  else
    # 順序検証 (基本): Step 5 < Findings Synthesis < Score Aggregation
    if ! { [ "$line_step5" -lt "$line_synthesis" ] && [ "$line_synthesis" -lt "$line_score_agg" ]; }; then
      if [ "$line_synthesis" -le "$line_step5" ]; then
        fail "TC-02: 'Findings Synthesis' が 'Step 5' 見出しより前に出現している (Step 5=$line_step5, Synthesis=$line_synthesis)"
      else
        fail "TC-02: 'Findings Synthesis' が 'Score Aggregation' の後に出現している (Synthesis=$line_synthesis, Score Aggregation=$line_score_agg)"
      fi
    else
      # Codex F1 対応: Step 5 と Findings Synthesis の間に他の H3 が割り込んでいないことを検証
      # awk で line_step5+1 から line_synthesis-1 までを抽出、その範囲に ^### で始まる行が無いことを assert
      between_h3=$(awk -v from="$line_step5" -v to="$line_synthesis" 'NR>from && NR<to && /^### /' "$SUBJECT" || true)
      if [ -z "$between_h3" ]; then
        pass "TC-02: 順序が正しく Findings Synthesis が Step 5 直後の最初の H3 (Step 5=$line_step5 < Synthesis=$line_synthesis < Score Aggregation=$line_score_agg, 間に他 H3 無し)"
      else
        fail "TC-02: 'Step 5' と 'Findings Synthesis' の間に他の H3 が割り込んでいる (割り込み: $between_h3)"
      fi
    fi
  fi
fi

# ---------------------------------------------------------------------------
# TC-03: section 内に「3-category 分類」と「raw finding index」が両方含まれる (case-sensitive)
# ---------------------------------------------------------------------------
echo ""
echo "TC-03: Step 5 内に '3-category 分類' と 'raw finding index' が両方含まれる"

if [ ! -f "$SUBJECT" ]; then
  fail "TC-03: $SUBJECT が存在しない"
else
  section_content=$(step5_lines)

  if [ -z "$section_content" ]; then
    fail "TC-03: Step 5 section が空または存在しない"
  else
    # pipefail masking 回避: 変数受け取り後 grep (case-sensitive)
    count_3cat=$(echo "$section_content" | grep -cF "3-category 分類" || true)
    count_rawindex=$(echo "$section_content" | grep -cF "raw finding index" || true)

    if [ "$count_3cat" -ge 1 ] && [ "$count_rawindex" -ge 1 ]; then
      pass "TC-03: '3-category 分類' と 'raw finding index' が両方 Step 5 内に存在する"
    elif [ "$count_3cat" -lt 1 ]; then
      fail "TC-03: Step 5 内に '3-category 分類' が存在しない"
    else
      fail "TC-03: Step 5 内に 'raw finding index' が存在しない"
    fi
  fi
fi

# ---------------------------------------------------------------------------
# TC-04: section 内に「rules/review-triage.md」への参照が含まれる (literal grep)
# ---------------------------------------------------------------------------
echo ""
echo "TC-04: Step 5 内に 'rules/review-triage.md' への参照が含まれる"

if [ ! -f "$SUBJECT" ]; then
  fail "TC-04: $SUBJECT が存在しない"
else
  section_content=$(step5_lines)

  if [ -z "$section_content" ]; then
    fail "TC-04: Step 5 section が空または存在しない"
  else
    # pipefail masking 回避: 変数受け取り後 grep (case-sensitive literal)
    count_ref=$(echo "$section_content" | grep -cF "rules/review-triage.md" || true)
    if [ "$count_ref" -ge 1 ]; then
      pass "TC-04: Step 5 内に 'rules/review-triage.md' への参照が存在する"
    else
      fail "TC-04: Step 5 内に 'rules/review-triage.md' への参照が存在しない"
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
