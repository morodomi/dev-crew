#!/bin/bash
# test-commit-cycle-doc-trailer.sh - Cycle-Doc trailer (commit) + recall-miss question (cycle-retrospective)
#
# All TCs extract the target H2/H3 section region first (fence-aware), then grep
# within the region. Whole-file grep is forbidden: the target docs embed markdown
# code fences whose lines begin with "## " (e.g. "## Retrospective"), which a naive
# whole-file scan would mis-detect as headings.

set -uo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

COMMIT_SKILL="$BASE_DIR/skills/commit/SKILL.md"
COMMIT_REF="$BASE_DIR/skills/commit/reference.md"
RETRO_SKILL="$BASE_DIR/skills/cycle-retrospective/SKILL.md"
RETRO_REF="$BASE_DIR/skills/cycle-retrospective/reference.md"

# section_lines <file> <start_marker> <term_level>
#   start_marker: full heading incl leading hashes, fixed-string prefix (no ERE meta).
#   term_level:   terminate at the next heading whose level (# count) <= term_level.
#   Fence-aware: lines inside ``` code fences are emitted as body and never treated
#   as headings (so a fenced "## Retrospective" does not terminate the region).
section_lines() {
  awk -v sm="$2" -v tl="$3" '
    /^```/ { fence = !fence; if (in_sec) print; next }
    !in_sec && !fence && index($0, sm) == 1 { in_sec = 1; next }
    in_sec && !fence && /^#+ / {
      n = 0; while (substr($0, n + 1, 1) == "#") n++;
      if (n <= tl) { in_sec = 0; next }
    }
    in_sec { print }
  ' "$1"
}

# section_count <file> <start_marker> <term_level> <fixed_pattern> → prints match count
# `--` guards patterns that begin with '-' (e.g. "- **回答**:") from option parsing.
section_count() {
  section_lines "$1" "$2" "$3" | grep -cF -- "$4" || true
}

echo "=== Cycle-Doc trailer + recall-miss question Tests ==="

# --- TC-T1: commit/SKILL.md Step 4 has Cycle-Doc trailer instruction + whole file <= 100 lines ---
echo ""
echo "TC-T1: skills/commit/SKILL.md Step 4 section has 'Cycle-Doc' trailer instruction + <= 100 lines"
if [ ! -f "$COMMIT_SKILL" ]; then
  fail "TC-T1: skills/commit/SKILL.md does not exist"
else
  count_trailer=$(section_count "$COMMIT_SKILL" "### Step 4" 3 "Cycle-Doc")
  lines=$(wc -l < "$COMMIT_SKILL" | tr -d ' ')
  if [ "$count_trailer" -ge 1 ] && [ "$lines" -le 100 ]; then
    pass "TC-T1: Step 4 has Cycle-Doc trailer instruction + SKILL.md is $lines lines (<= 100)"
  elif [ "$count_trailer" -lt 1 ]; then
    fail "TC-T1: Step 4 section missing 'Cycle-Doc' trailer instruction"
  else
    fail "TC-T1: skills/commit/SKILL.md exceeds 100 lines ($lines lines)"
  fi
fi

# --- TC-T2: commit/reference.md コミットメッセージ詳細 has trailer example + two clauses ---
echo ""
echo "TC-T2: skills/commit/reference.md コミットメッセージ詳細 has 'Cycle-Doc:' + 'commit スキル以外の経路' + '主サイクル 1 件'"
if [ ! -f "$COMMIT_REF" ]; then
  fail "TC-T2: skills/commit/reference.md does not exist"
else
  count_example=$(section_count "$COMMIT_REF" "## コミットメッセージ詳細" 2 "Cycle-Doc:")
  count_scope=$(section_count "$COMMIT_REF" "## コミットメッセージ詳細" 2 "commit スキル以外の経路")
  count_primary=$(section_count "$COMMIT_REF" "## コミットメッセージ詳細" 2 "主サイクル 1 件")
  if [ "$count_example" -ge 1 ] && [ "$count_scope" -ge 1 ] && [ "$count_primary" -ge 1 ]; then
    pass "TC-T2: コミットメッセージ詳細 has Cycle-Doc: example + non-skill-path clause + single-primary clause"
  elif [ "$count_example" -lt 1 ]; then
    fail "TC-T2: コミットメッセージ詳細 section missing 'Cycle-Doc:' trailer line in example"
  elif [ "$count_scope" -lt 1 ]; then
    fail "TC-T2: コミットメッセージ詳細 section missing 'commit スキル以外の経路' clause"
  else
    fail "TC-T2: コミットメッセージ詳細 section missing '主サイクル 1 件' clause"
  fi
fi

# --- TC-T3: cycle-retrospective/reference.md recall-miss question, schema, no-lesson + override paths ---
echo ""
echo "TC-T3: skills/cycle-retrospective/reference.md recall-miss question + schema + no-lesson/override paths"
if [ ! -f "$RETRO_REF" ]; then
  fail "TC-T3: skills/cycle-retrospective/reference.md does not exist"
else
  # (a) recall-miss question in the extraction-algorithm section
  count_question=$(section_count "$RETRO_REF" "## 抽出アルゴリズム" 2 "どの cycle doc を最初に読んでいれば防げたか")
  # (b) fixed 2-line schema + answer-format regulation in the output-template section
  count_schema_q=$(section_count "$RETRO_REF" "## 出力テンプレート" 2 "- **設問**: 今回の手戻りは、過去のどの cycle doc を最初に読んでいれば防げたか")
  count_schema_a=$(section_count "$RETRO_REF" "## 出力テンプレート" 2 "- **回答**:")
  count_answer_none=$(section_count "$RETRO_REF" "## 出力テンプレート" 2 "該当なし")
  count_answer_path=$(section_count "$RETRO_REF" "## 出力テンプレート" 2 "docs/cycles/")
  # (b2) collection contract: doc must specify last-Retrospective-section extraction
  # (whole-file grep would pick up transcribed plan templates inside real cycle docs),
  # and the documented pipeline must extract exactly the real answer from a fixture
  # containing a fenced decoy template plus a real trailing Retrospective section.
  count_awk_last=$(section_count "$RETRO_REF" "## 出力テンプレート" 2 "awk '/^## Retrospective\$/")
  count_a3=$(section_count "$RETRO_REF" "## 出力テンプレート" 2 "grep -A3 '^### 想起漏れ\$'")
  fixture=$(mktemp)
  cat > "$fixture" << 'ORACLE_FIXTURE'
# fixture doc

## Plan Transcription

```markdown
### 想起漏れ

- **設問**: 今回の手戻りは、過去のどの cycle doc を最初に読んでいれば防げたか
- **回答**: 該当なし
```

## Retrospective

### Insight 1

- **Failure**: x

### 想起漏れ

- **設問**: 今回の手戻りは、過去のどの cycle doc を最初に読んでいれば防げたか
- **回答**: docs/cycles/real.md
ORACLE_FIXTURE
  a3_output=$(awk '/^## Retrospective$/{buf=""; found=1} found{buf=buf $0 ORS} END{printf "%s", buf}' "$fixture" \
    | grep -A3 '^### 想起漏れ$' 2>/dev/null || true)
  a3_oracle_count=$(echo "$a3_output" | grep -cF -- "- **回答**:" || true)
  a3_oracle_value=$(echo "$a3_output" | grep -cF -- "- **回答**: docs/cycles/real.md" || true)
  rm -f "$fixture"
  a3_oracle=0
  if [ "${a3_oracle_count:-0}" -eq 1 ] && [ "${a3_oracle_value:-0}" -eq 1 ]; then
    a3_oracle=1
  fi
  # (b3) every answer line in the doc (all templates: normal / no-lesson / override)
  # must match the anchored allowed pattern — whole-file scope is intentional here
  answer_lines_total=$(grep -cE '^- \*\*回答\*\*:' "$RETRO_REF" || true)
  answer_lines_valid=$(grep -cE '^- \*\*回答\*\*: (該当なし|docs/cycles/[^ ]+\.md(, docs/cycles/[^ ]+\.md)*)$' "$RETRO_REF" || true)
  # (c) both no-lesson section and override section require ### 想起漏れ
  count_nolesson=$(section_count "$RETRO_REF" "### No-lesson 処理" 2 "想起漏れ")
  count_override=$(section_count "$RETRO_REF" "### proceed (続行)" 3 "想起漏れ")
  # abort must NOT write anything (file-untouched contract) — negative pin
  count_abort_neg=$(section_count "$RETRO_REF" "### abort (中止)" 3 "想起漏れ")
  if [ "$count_question" -ge 1 ] && \
     [ "$count_schema_q" -ge 1 ] && [ "$count_schema_a" -ge 1 ] && \
     [ "$count_answer_none" -ge 1 ] && [ "$count_answer_path" -ge 1 ] && \
     [ "${count_awk_last:-0}" -ge 1 ] && [ "${count_a3:-0}" -ge 1 ] && [ "${a3_oracle:-0}" -ge 1 ] && \
     [ "${answer_lines_total:-0}" -ge 1 ] && [ "$answer_lines_total" -eq "$answer_lines_valid" ] && \
     [ "$count_nolesson" -ge 1 ] && [ "$count_override" -ge 1 ] && [ "${count_abort_neg:-0}" -eq 0 ]; then
    pass "TC-T3: recall-miss question + 2-line schema + no-lesson/override paths all present"
  elif [ "$count_question" -lt 1 ]; then
    fail "TC-T3: 抽出アルゴリズム section missing recall-miss question 'どの cycle doc を最初に読んでいれば防げたか'"
  elif [ "$count_schema_q" -lt 1 ]; then
    fail "TC-T3: 出力テンプレート section missing schema 設問 line literal"
  elif [ "$count_schema_a" -lt 1 ]; then
    fail "TC-T3: 出力テンプレート section missing schema '- **回答**:' line"
  elif [ "$count_answer_none" -lt 1 ] || [ "$count_answer_path" -lt 1 ]; then
    fail "TC-T3: 出力テンプレート section missing answer-format values ('該当なし' / 'docs/cycles/')"
  elif [ "${count_awk_last:-0}" -lt 1 ] || [ "${count_a3:-0}" -lt 1 ] || [ "${a3_oracle:-0}" -lt 1 ]; then
    fail "TC-T3: collection contract broken (last-section awk spec / anchored grep -A3 spec missing, or oracle did not extract exactly the real answer)"
  elif [ "${answer_lines_total:-0}" -lt 1 ] || [ "$answer_lines_total" -ne "$answer_lines_valid" ]; then
    fail "TC-T3: answer line(s) violate anchored format (total=$answer_lines_total valid=$answer_lines_valid)"
  elif [ "$count_nolesson" -lt 1 ]; then
    fail "TC-T3: No-lesson 処理 section missing '想起漏れ' record requirement"
  elif [ "$count_override" -lt 1 ]; then
    fail "TC-T3: proceed (続行) subsection missing '想起漏れ' record requirement"
  else
    fail "TC-T3: abort (中止) subsection must NOT mention '想起漏れ' (abort is file-untouched)"
  fi
fi

# --- TC-T4: cycle-retrospective/SKILL.md Extraction/Output mention question + all-normal-exit; 3 fixed strings intact ---
echo ""
echo "TC-T4: skills/cycle-retrospective/SKILL.md Extraction/Output has recall-miss + 全正常終了経路 + 3 fixed strings unchanged"
if [ ! -f "$RETRO_SKILL" ]; then
  fail "TC-T4: skills/cycle-retrospective/SKILL.md does not exist"
else
  count_ext_question=$(section_count "$RETRO_SKILL" "### Extraction" 3 "想起漏れ")
  count_out_allexit=$(section_count "$RETRO_SKILL" "### Output" 3 "全正常終了経路")
  count_fixed_nolesson=$(section_count "$RETRO_SKILL" "### Extraction" 3 "No reusable lesson this cycle")
  count_fixed_skipped=$(section_count "$RETRO_SKILL" "### Output" 3 "Extraction skipped by override")
  count_fixed_retries=$(section_count "$RETRO_SKILL" "### Output" 3 "Extraction failed after N retries")
  if [ "$count_ext_question" -ge 1 ] && [ "$count_out_allexit" -ge 1 ] && \
     [ "$count_fixed_nolesson" -ge 1 ] && [ "$count_fixed_skipped" -ge 1 ] && [ "$count_fixed_retries" -ge 1 ]; then
    pass "TC-T4: Extraction/Output mention recall-miss + all-normal-exit; 3 fixed strings intact"
  elif [ "$count_ext_question" -lt 1 ]; then
    fail "TC-T4: Extraction section missing '想起漏れ' recall-miss mention"
  elif [ "$count_out_allexit" -lt 1 ]; then
    fail "TC-T4: Output section missing '全正常終了経路' record instruction"
  else
    fail "TC-T4: a fixed string was altered/removed (nolesson=$count_fixed_nolesson skipped=$count_fixed_skipped retries=$count_fixed_retries)"
  fi
fi

# --- TC-T5: order contract — Cycle-Doc: after <type>: line, adjacent to Co-Authored-By trailer block ---
echo ""
echo "TC-T5: skills/commit/reference.md example — 'Cycle-Doc:' after '<type>:' line, near 'Co-Authored-By:'"
if [ ! -f "$COMMIT_REF" ]; then
  fail "TC-T5: skills/commit/reference.md does not exist"
else
  example=$(section_lines "$COMMIT_REF" "### 良いコミットメッセージ" 3)
  type_ln=$(printf '%s\n' "$example" | grep -nF "feat:" | head -1 | cut -d: -f1)
  cyc_ln=$(printf '%s\n' "$example" | grep -nF "Cycle-Doc:" | head -1 | cut -d: -f1)
  co_ln=$(printf '%s\n' "$example" | grep -nF "Co-Authored-By:" | head -1 | cut -d: -f1)
  if [ -z "$cyc_ln" ]; then
    fail "TC-T5: example has no 'Cycle-Doc:' trailer line"
  elif [ -z "$type_ln" ] || [ -z "$co_ln" ]; then
    fail "TC-T5: example missing '<type>:' (feat:) or 'Co-Authored-By:' anchor"
  else
    diff=$((cyc_ln - co_ln))
    [ "$diff" -lt 0 ] && diff=$((-diff))
    if [ "$type_ln" -lt "$cyc_ln" ] && [ "$diff" -le 3 ]; then
      pass "TC-T5: Cycle-Doc: (line $cyc_ln) is after type (line $type_ln) and within trailer block (Co-Authored-By line $co_ln)"
    elif [ "$type_ln" -ge "$cyc_ln" ]; then
      fail "TC-T5: 'Cycle-Doc:' (line $cyc_ln) must appear after '<type>:' line (line $type_ln)"
    else
      fail "TC-T5: 'Cycle-Doc:' (line $cyc_ln) not adjacent to Co-Authored-By trailer block (line $co_ln, distance $diff > 3)"
    fi
  fi
fi

# --- TC-R1 (regression): cycle-retrospective/reference.md 固定文字列 Contract keeps all 3 fixed strings ---
echo ""
echo "TC-R1: skills/cycle-retrospective/reference.md 固定文字列 Contract keeps 3 fixed strings (test-cycle-retrospective non-破壊)"
if [ ! -f "$RETRO_REF" ]; then
  fail "TC-R1: skills/cycle-retrospective/reference.md does not exist"
else
  r1_skipped=$(section_count "$RETRO_REF" "## 固定文字列 Contract" 2 "Extraction skipped by override")
  r1_retries=$(section_count "$RETRO_REF" "## 固定文字列 Contract" 2 "Extraction failed after N retries")
  r1_nolesson=$(section_count "$RETRO_REF" "## 固定文字列 Contract" 2 "No reusable lesson this cycle")
  if [ "$r1_skipped" -ge 1 ] && [ "$r1_retries" -ge 1 ] && [ "$r1_nolesson" -ge 1 ]; then
    pass "TC-R1: 固定文字列 Contract retains all 3 fixed strings"
  else
    fail "TC-R1: 固定文字列 Contract missing a fixed string (skipped=$r1_skipped retries=$r1_retries nolesson=$r1_nolesson)"
  fi
fi

# --- TC-R2 (regression): cycle-retrospective/SKILL.md Workflow keeps all 3 fixed strings ---
echo ""
echo "TC-R2: skills/cycle-retrospective/SKILL.md Workflow keeps 3 fixed strings (commit/phase-gate non-破壊 proxy)"
if [ ! -f "$RETRO_SKILL" ]; then
  fail "TC-R2: skills/cycle-retrospective/SKILL.md does not exist"
else
  r2_skipped=$(section_count "$RETRO_SKILL" "## Workflow" 2 "Extraction skipped by override")
  r2_retries=$(section_count "$RETRO_SKILL" "## Workflow" 2 "Extraction failed after N retries")
  r2_nolesson=$(section_count "$RETRO_SKILL" "## Workflow" 2 "No reusable lesson this cycle")
  if [ "$r2_skipped" -ge 1 ] && [ "$r2_retries" -ge 1 ] && [ "$r2_nolesson" -ge 1 ]; then
    pass "TC-R2: Workflow retains all 3 fixed strings"
  else
    fail "TC-R2: Workflow missing a fixed string (skipped=$r2_skipped retries=$r2_retries nolesson=$r2_nolesson)"
  fi
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
