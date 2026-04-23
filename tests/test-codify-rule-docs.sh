#!/bin/bash
# test-codify-rule-docs.sh - rule document codification tests
# TC-01 to TC-10 for follow-up-codify-23-insights cycle

set -uo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

RULES_DIR="$BASE_DIR/rules"
SKILL_MAKER_REF="$BASE_DIR/skills/skill-maker/reference.md"

echo "=== codify rule docs Tests (follow-up-codify-23-insights) ==="

# TC-01: rules/test-patterns.md exists + H1 title + 出典 section with >= 1 reference
echo ""
echo "TC-01: rules/test-patterns.md exists + H1 title + 出典 section (>= 1 ref)"
FILE="$RULES_DIR/test-patterns.md"
if [ ! -f "$FILE" ]; then
  fail "TC-01: rules/test-patterns.md does not exist"
else
  has_h1=$(grep -cE "^# " "$FILE" || true)
  has_source=$(grep -cE "^## (出典|Source)" "$FILE" || true)
  if [ "$has_h1" -ge 1 ] && [ "$has_source" -ge 1 ]; then
    pass "TC-01: rules/test-patterns.md exists + H1 + 出典 section"
  elif [ "$has_h1" -lt 1 ]; then
    fail "TC-01: rules/test-patterns.md missing H1 title"
  else
    fail "TC-01: rules/test-patterns.md missing '## 出典' or '## Source' section"
  fi
fi

# TC-02: rules/plan-discipline.md exists + H1 + 出典 section with >= 2 references
echo ""
echo "TC-02: rules/plan-discipline.md exists + H1 + 出典 section (>= 2 refs — 複数 cycle 由来)"
FILE="$RULES_DIR/plan-discipline.md"
if [ ! -f "$FILE" ]; then
  fail "TC-02: rules/plan-discipline.md does not exist"
else
  has_h1=$(grep -cE "^# " "$FILE" || true)
  has_source=$(grep -cE "^## (出典|Source)" "$FILE" || true)
  # Count cycle references: lines under 出典/Source section that reference a cycle doc or PR
  source_refs=$(awk '/^## (出典|Source)/{found=1; next} found && /^## /{found=0} found && NF>0{print}' "$FILE" | grep -cE "cycle|Cycle|20[0-9]{6}|PR #" || true)
  if [ "$has_h1" -ge 1 ] && [ "$has_source" -ge 1 ] && [ "$source_refs" -ge 2 ]; then
    pass "TC-02: rules/plan-discipline.md exists + H1 + 出典 section (>= 2 cycle refs)"
  elif [ "$has_h1" -lt 1 ]; then
    fail "TC-02: rules/plan-discipline.md missing H1 title"
  elif [ "$has_source" -lt 1 ]; then
    fail "TC-02: rules/plan-discipline.md missing '## 出典' or '## Source' section"
  else
    fail "TC-02: rules/plan-discipline.md 出典 section has fewer than 2 cycle references (found: $source_refs)"
  fi
fi

# TC-03: rules/agent-prompts.md exists + H1 + 出典 section with >= 1 reference
echo ""
echo "TC-03: rules/agent-prompts.md exists + H1 + 出典 section (>= 1 ref)"
FILE="$RULES_DIR/agent-prompts.md"
if [ ! -f "$FILE" ]; then
  fail "TC-03: rules/agent-prompts.md does not exist"
else
  has_h1=$(grep -cE "^# " "$FILE" || true)
  has_source=$(grep -cE "^## (出典|Source)" "$FILE" || true)
  if [ "$has_h1" -ge 1 ] && [ "$has_source" -ge 1 ]; then
    pass "TC-03: rules/agent-prompts.md exists + H1 + 出典 section"
  elif [ "$has_h1" -lt 1 ]; then
    fail "TC-03: rules/agent-prompts.md missing H1 title"
  else
    fail "TC-03: rules/agent-prompts.md missing '## 出典' or '## Source' section"
  fi
fi

# TC-04: rules/multi-file-consistency.md exists + H1 + 出典 section with >= 1 reference
echo ""
echo "TC-04: rules/multi-file-consistency.md exists + H1 + 出典 section (>= 1 ref)"
FILE="$RULES_DIR/multi-file-consistency.md"
if [ ! -f "$FILE" ]; then
  fail "TC-04: rules/multi-file-consistency.md does not exist"
else
  has_h1=$(grep -cE "^# " "$FILE" || true)
  has_source=$(grep -cE "^## (出典|Source)" "$FILE" || true)
  if [ "$has_h1" -ge 1 ] && [ "$has_source" -ge 1 ]; then
    pass "TC-04: rules/multi-file-consistency.md exists + H1 + 出典 section"
  elif [ "$has_h1" -lt 1 ]; then
    fail "TC-04: rules/multi-file-consistency.md missing H1 title"
  else
    fail "TC-04: rules/multi-file-consistency.md missing '## 出典' or '## Source' section"
  fi
fi

# TC-05: rules/review-triage.md exists + H1 + 出典 section with >= 1 reference
echo ""
echo "TC-05: rules/review-triage.md exists + H1 + 出典 section (>= 1 ref)"
FILE="$RULES_DIR/review-triage.md"
if [ ! -f "$FILE" ]; then
  fail "TC-05: rules/review-triage.md does not exist"
else
  has_h1=$(grep -cE "^# " "$FILE" || true)
  has_source=$(grep -cE "^## (出典|Source)" "$FILE" || true)
  if [ "$has_h1" -ge 1 ] && [ "$has_source" -ge 1 ]; then
    pass "TC-05: rules/review-triage.md exists + H1 + 出典 section"
  elif [ "$has_h1" -lt 1 ]; then
    fail "TC-05: rules/review-triage.md missing H1 title"
  else
    fail "TC-05: rules/review-triage.md missing '## 出典' or '## Source' section"
  fi
fi

# TC-06: rules/doc-mutations.md exists + H1 + 出典 section with >= 1 reference
echo ""
echo "TC-06: rules/doc-mutations.md exists + H1 + 出典 section (>= 1 ref)"
FILE="$RULES_DIR/doc-mutations.md"
if [ ! -f "$FILE" ]; then
  fail "TC-06: rules/doc-mutations.md does not exist"
else
  has_h1=$(grep -cE "^# " "$FILE" || true)
  has_source=$(grep -cE "^## (出典|Source)" "$FILE" || true)
  if [ "$has_h1" -ge 1 ] && [ "$has_source" -ge 1 ]; then
    pass "TC-06: rules/doc-mutations.md exists + H1 + 出典 section"
  elif [ "$has_h1" -lt 1 ]; then
    fail "TC-06: rules/doc-mutations.md missing H1 title"
  else
    fail "TC-06: rules/doc-mutations.md missing '## 出典' or '## Source' section"
  fi
fi

# TC-07: rules/skill-authoring.md exists + H1 + "100 行" description + "exit contract" description
echo ""
echo "TC-07: rules/skill-authoring.md exists + H1 + '100 行' or 'line limit' + 'exit contract' (case-insensitive)"
FILE="$RULES_DIR/skill-authoring.md"
if [ ! -f "$FILE" ]; then
  fail "TC-07: rules/skill-authoring.md does not exist"
else
  has_h1=$(grep -cE "^# " "$FILE" || true)
  # Check for either Japanese "100 行" or English "line limit / 100-line" wording (mutually exclusive via if/elif to avoid concatenating both grep counts)
  if grep -qF "100 行" "$FILE"; then
    has_100line=1
  elif grep -qiE "100.line|line.limit|100-line" "$FILE"; then
    has_100line=1
  else
    has_100line=0
  fi
  has_exit_contract=$(grep -ciE "exit contract" "$FILE" || true)
  if [ "$has_h1" -ge 1 ] && [ "$has_100line" -ge 1 ] && [ "$has_exit_contract" -ge 1 ]; then
    pass "TC-07: rules/skill-authoring.md exists + H1 + 100-line limit + exit contract"
  elif [ "$has_h1" -lt 1 ]; then
    fail "TC-07: rules/skill-authoring.md missing H1 title"
  elif [ "$has_100line" -lt 1 ]; then
    fail "TC-07: rules/skill-authoring.md missing '100 行' / 'line limit' / '100-line' description"
  else
    fail "TC-07: rules/skill-authoring.md missing 'exit contract' description (case-insensitive)"
  fi
fi

# TC-08: All 7 rule files size >= 200 bytes
echo ""
echo "TC-08: All 7 rule files size >= 200 bytes"
TC08_PASS=true
for fname in \
  "test-patterns.md" \
  "plan-discipline.md" \
  "agent-prompts.md" \
  "multi-file-consistency.md" \
  "review-triage.md" \
  "doc-mutations.md" \
  "skill-authoring.md"
do
  fpath="$RULES_DIR/$fname"
  if [ ! -f "$fpath" ]; then
    fail "TC-08: rules/$fname does not exist (cannot check size)"
    TC08_PASS=false
  else
    size=$(wc -c < "$fpath" | tr -d ' ')
    if [ "$size" -ge 200 ]; then
      : # ok
    else
      fail "TC-08: rules/$fname is too small ($size bytes, need >= 200)"
      TC08_PASS=false
    fi
  fi
done
if [ "$TC08_PASS" = "true" ]; then
  pass "TC-08: All 7 rule files are >= 200 bytes"
fi

# TC-09: skills/skill-maker/reference.md Validation Checklist contains "Exit Contract"
echo ""
echo "TC-09: skills/skill-maker/reference.md Validation Checklist has 'Exit Contract'"
if [ ! -f "$SKILL_MAKER_REF" ]; then
  fail "TC-09: skills/skill-maker/reference.md does not exist"
else
  has_exit_contract=$(grep -ciE "Exit Contract" "$SKILL_MAKER_REF" || true)
  if [ "$has_exit_contract" -ge 1 ]; then
    pass "TC-09: skills/skill-maker/reference.md contains 'Exit Contract'"
  else
    fail "TC-09: skills/skill-maker/reference.md does NOT contain 'Exit Contract'"
  fi
fi

# TC-10: skills/skill-maker/reference.md contains cross-link to rules/skill-authoring.md
echo ""
echo "TC-10: skills/skill-maker/reference.md contains cross-link 'skill-authoring'"
if [ ! -f "$SKILL_MAKER_REF" ]; then
  fail "TC-10: skills/skill-maker/reference.md does not exist"
else
  has_crosslink=$(grep -cF "skill-authoring" "$SKILL_MAKER_REF" || true)
  if [ "$has_crosslink" -ge 1 ]; then
    pass "TC-10: skills/skill-maker/reference.md contains 'skill-authoring' cross-link"
  else
    fail "TC-10: skills/skill-maker/reference.md does NOT contain 'skill-authoring' cross-link"
  fi
fi

# Section-specific grep: extract content under a given H2 heading until next H2.
# Usage: section_grep <file> <heading_regex> <pattern> → emits matching lines.
section_grep() {
  local file="$1"
  local heading="$2"
  local pattern="$3"
  awk -v h="$heading" '
    $0 ~ "^## " h {in_sec=1; next}
    in_sec && /^## /{in_sec=0}
    in_sec
  ' "$file" | grep -cF "$pattern" || true
}

# TC-11: rules/plan-discipline.md — 推奨 に「grep -rn」literal、出典 に「20260422_1313」
echo ""
echo "TC-11: rules/plan-discipline.md has 'grep -rn' in 推奨 + '20260422_1313' in 出典"
FILE="$RULES_DIR/plan-discipline.md"
if [ ! -f "$FILE" ]; then
  fail "TC-11: rules/plan-discipline.md does not exist"
else
  count_grep_rn=$(section_grep "$FILE" "推奨" "grep -rn")
  count_cycle1313_in_source=$(section_grep "$FILE" "出典" "20260422_1313")
  if [ "$count_grep_rn" -ge 1 ] && [ "$count_cycle1313_in_source" -ge 1 ]; then
    pass "TC-11: plan-discipline.md 推奨 has grep -rn + 出典 has 20260422_1313"
  elif [ "$count_grep_rn" -lt 1 ]; then
    fail "TC-11: plan-discipline.md 推奨 section missing 'grep -rn' literal"
  else
    fail "TC-11: plan-discipline.md 出典 section missing '20260422_1313' reference"
  fi
fi

# TC-12: rules/test-patterns.md — 禁止事項 に「command substitution」、出典 に「20260422_1313」
echo ""
echo "TC-12: rules/test-patterns.md has 'command substitution' in 禁止事項 + '20260422_1313' in 出典"
FILE="$RULES_DIR/test-patterns.md"
if [ ! -f "$FILE" ]; then
  fail "TC-12: rules/test-patterns.md does not exist"
else
  count_cmd_sub=$(section_grep "$FILE" "禁止事項" "command substitution")
  count_cycle1313_in_source=$(section_grep "$FILE" "出典" "20260422_1313")
  if [ "$count_cmd_sub" -ge 1 ] && [ "$count_cycle1313_in_source" -ge 1 ]; then
    pass "TC-12: test-patterns.md 禁止事項 has command substitution + 出典 has 20260422_1313"
  elif [ "$count_cmd_sub" -lt 1 ]; then
    fail "TC-12: test-patterns.md 禁止事項 section missing 'command substitution' description"
  else
    fail "TC-12: test-patterns.md 出典 section missing '20260422_1313' reference"
  fi
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
