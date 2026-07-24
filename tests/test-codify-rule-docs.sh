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
# Usage: section_grep <file> <heading_prefix (fixed-string)> <pattern> → emits matching lines.
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

# Plan File Template region grep (fence-aware). The template lives inside a fenced
# ```markdown block that itself contains nested '## ' lines (## TDD Context, ## Recall,
# ## Plan Review Record, ## Post-Approve Action), so section_grep's naive H2 termination
# cannot be reused here. Capture from the "## Plan File Template" heading through the
# fenced body and trailing prose, stopping at the next real (out-of-fence) H2.
# Usage: plan_template_grep <file> <pattern> → emits match count.
plan_template_grep() {
  local file="$1"
  local pattern="$2"
  awk '
    index($0, "## Plan File Template") == 1 {cap=1; next}
    cap {
      if ($0 ~ /^```/) {infence = !infence; print; next}
      if (!infence && $0 ~ /^## /) {exit}
      print
    }
  ' "$file" | grep -cF -- "$pattern" || true
}

# Plan File Template — emit ONLY the fenced '- override:' field line (first match).
# Used to prove the fenced template value is empty (no gate-regex forgery path).
# Usage: plan_template_fence_override <file> → prints the fenced override line (may be empty).
plan_template_fence_override() {
  awk '
    index($0, "## Plan File Template") == 1 {cap=1; next}
    cap {
      if ($0 ~ /^```/) {infence = !infence; next}
      if (!infence && $0 ~ /^## /) {exit}
      if (infence && index($0, "- override:") == 1) {print; exit}
    }
  ' "$1"
}

# Plan File Template — emit ONLY the fence-EXTERNAL prose lines of the section.
# Used to assert the evidence-requirement note lives outside the fenced template.
# Usage: plan_template_prose <file> <pattern> → emits match count.
plan_template_prose() {
  awk '
    index($0, "## Plan File Template") == 1 {cap=1; next}
    cap {
      if ($0 ~ /^```/) {infence = !infence; next}
      if (!infence && $0 ~ /^## /) {exit}
      if (!infence) print
    }
  ' "$1" | grep -cF -- "$2" || true
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

# TC-13: rules/doc-mutations.md — SSOT 即時同期 section に "collateral fix" + "即時更新"、出典 に "20260422_1313"
echo ""
echo "TC-13: rules/doc-mutations.md has 'collateral fix'+'即時更新' in SSOT 即時同期 section + '20260422_1313' in 出典"
FILE="$RULES_DIR/doc-mutations.md"
if [ ! -f "$FILE" ]; then
  fail "TC-13: rules/doc-mutations.md does not exist"
else
  count_collateral=$(section_grep "$FILE" "SSOT 即時同期" "collateral fix")
  count_soku=$(section_grep "$FILE" "SSOT 即時同期" "即時更新")
  count_cycle1313=$(section_grep "$FILE" "出典" "20260422_1313")
  if [ "$count_collateral" -ge 1 ] && [ "$count_soku" -ge 1 ] && [ "$count_cycle1313" -ge 1 ]; then
    pass "TC-13: doc-mutations.md SSOT 即時同期 has collateral fix + 即時更新 + 出典 has 20260422_1313"
  elif [ "$count_collateral" -lt 1 ]; then
    fail "TC-13: doc-mutations.md SSOT 即時同期 section missing 'collateral fix'"
  elif [ "$count_soku" -lt 1 ]; then
    fail "TC-13: doc-mutations.md SSOT 即時同期 section missing '即時更新'"
  else
    fail "TC-13: doc-mutations.md 出典 section missing '20260422_1313' reference"
  fi
fi

# TC-14: rules/doc-mutations.md — Cycle 参照 format section に "full filename" + "cycle_id"、出典 に "20260422_1313"
echo ""
echo "TC-14: rules/doc-mutations.md has 'full filename'+'cycle_id' in Cycle 参照 format section + '20260422_1313' in 出典"
FILE="$RULES_DIR/doc-mutations.md"
if [ ! -f "$FILE" ]; then
  fail "TC-14: rules/doc-mutations.md does not exist"
else
  count_full_filename=$(section_grep "$FILE" "Cycle 参照 format" "full filename")
  count_cycle_id=$(section_grep "$FILE" "Cycle 参照 format" "cycle_id")
  count_cycle1313=$(section_grep "$FILE" "出典" "20260422_1313")
  if [ "$count_full_filename" -ge 1 ] && [ "$count_cycle_id" -ge 1 ] && [ "$count_cycle1313" -ge 1 ]; then
    pass "TC-14: doc-mutations.md Cycle 参照 format has full filename + cycle_id + 出典 has 20260422_1313"
  elif [ "$count_full_filename" -lt 1 ]; then
    fail "TC-14: doc-mutations.md Cycle 参照 format section missing 'full filename'"
  elif [ "$count_cycle_id" -lt 1 ]; then
    fail "TC-14: doc-mutations.md Cycle 参照 format section missing 'cycle_id'"
  else
    fail "TC-14: doc-mutations.md 出典 section missing '20260422_1313' reference"
  fi
fi

# TC-15: rules/skill-authoring.md — Insight 引用の原則 section に "原文引用" + "generalize"、出典 に "20260422_1313"
echo ""
echo "TC-15: rules/skill-authoring.md has '原文引用'+'generalize' in Insight 引用の原則 section + '20260422_1313' in 出典"
FILE="$RULES_DIR/skill-authoring.md"
if [ ! -f "$FILE" ]; then
  fail "TC-15: rules/skill-authoring.md does not exist"
else
  count_genmon=$(section_grep "$FILE" "Insight 引用の原則" "原文引用")
  count_generalize=$(section_grep "$FILE" "Insight 引用の原則" "generalize")
  count_cycle1313=$(section_grep "$FILE" "出典" "20260422_1313")
  if [ "$count_genmon" -ge 1 ] && [ "$count_generalize" -ge 1 ] && [ "$count_cycle1313" -ge 1 ]; then
    pass "TC-15: skill-authoring.md Insight 引用の原則 has 原文引用 + generalize + 出典 has 20260422_1313"
  elif [ "$count_genmon" -lt 1 ]; then
    fail "TC-15: skill-authoring.md Insight 引用の原則 section missing '原文引用'"
  elif [ "$count_generalize" -lt 1 ]; then
    fail "TC-15: skill-authoring.md Insight 引用の原則 section missing 'generalize'"
  else
    fail "TC-15: skill-authoring.md 出典 section missing '20260422_1313' reference"
  fi
fi

# TC-16: skills/onboard/SKILL.md と reference.md 両方に "rules/*.md" glob 表記が存在 (forward direction 統一)
echo ""
echo "TC-16: skills/onboard/SKILL.md and reference.md each have 'rules/*.md' glob (forward direction)"
ONBOARD_SKILL="$BASE_DIR/skills/onboard/SKILL.md"
ONBOARD_REF="$BASE_DIR/skills/onboard/reference.md"
if [ ! -f "$ONBOARD_SKILL" ]; then
  fail "TC-16: skills/onboard/SKILL.md does not exist"
elif [ ! -f "$ONBOARD_REF" ]; then
  fail "TC-16: skills/onboard/reference.md does not exist"
else
  count_skill=$(grep -cF "rules/*.md" "$ONBOARD_SKILL" || true)
  count_ref=$(grep -cF "rules/*.md" "$ONBOARD_REF" || true)
  if [ "$count_skill" -ge 1 ] && [ "$count_ref" -ge 1 ]; then
    pass "TC-16: Both onboard/SKILL.md and reference.md contain 'rules/*.md' glob"
  elif [ "$count_skill" -lt 1 ]; then
    fail "TC-16: skills/onboard/SKILL.md missing 'rules/*.md' glob expression"
  else
    fail "TC-16: skills/onboard/reference.md missing 'rules/*.md' glob expression"
  fi
fi

# TC-17: skills/onboard/*.md に "git-safety, security, git-conventions" enumeration が存在しない (stale list 除去)
echo ""
echo "TC-17: skills/onboard/*.md has no 'git-safety, security, git-conventions' hardcoded enumeration"
ONBOARD_DIR="$BASE_DIR/skills/onboard"
count_stale=0
for f in "$ONBOARD_DIR"/*.md; do
  [ -e "$f" ] || continue
  n=$(grep -cE "git-safety, security, git-conventions" "$f" || true)
  count_stale=$((count_stale + n))
done
if [ "$count_stale" -eq 0 ]; then
  pass "TC-17: No hardcoded 'git-safety, security, git-conventions' enumeration in onboard/*.md"
else
  fail "TC-17: Found $count_stale occurrence(s) of stale enumeration 'git-safety, security, git-conventions' in onboard/*.md"
fi

# TC-18: skills/onboard/validation.md に "test -f .claude/rules/git-safety.md" と "test -f .claude/rules/security.md" の個別 assertion が除去済み
echo ""
echo "TC-18: skills/onboard/validation.md has no hardcoded 'test -f .claude/rules/git-safety.md' or 'test -f .claude/rules/security.md'"
VALIDATION_MD="$BASE_DIR/skills/onboard/validation.md"
if [ ! -f "$VALIDATION_MD" ]; then
  fail "TC-18: skills/onboard/validation.md does not exist"
else
  count_old_gitsafety=$(grep -cF "test -f .claude/rules/git-safety.md" "$VALIDATION_MD" || true)
  count_old_security=$(grep -cF "test -f .claude/rules/security.md" "$VALIDATION_MD" || true)
  if [ "$count_old_gitsafety" -eq 0 ] && [ "$count_old_security" -eq 0 ]; then
    pass "TC-18: validation.md has no hardcoded git-safety/security individual assertions"
  elif [ "$count_old_gitsafety" -gt 0 ]; then
    fail "TC-18: validation.md still has hardcoded 'test -f .claude/rules/git-safety.md' ($count_old_gitsafety occurrence(s))"
  else
    fail "TC-18: validation.md still has hardcoded 'test -f .claude/rules/security.md' ($count_old_security occurrence(s))"
  fi
fi

# TC-19: rules/integration-verification.md exists + structure validation
echo ""
echo "TC-19: rules/integration-verification.md exists + H1 + 禁止事項/推奨/出典 sections + key phrases + size >= 300 bytes"
FILE="$RULES_DIR/integration-verification.md"
if [ ! -f "$FILE" ]; then
  fail "TC-19: rules/integration-verification.md does not exist"
else
  has_h1=$(grep -cE "^# " "$FILE" || true)
  # 禁止事項 section に real-invocation なしの禁止文言 (bash tests/test or mock or echo)
  count_kinshi_bash=$(section_grep "$FILE" "禁止事項" "bash tests/test")
  count_kinshi_mock=$(section_grep "$FILE" "禁止事項" "mock")
  count_kinshi_echo=$(section_grep "$FILE" "禁止事項" "echo")
  if [ "$count_kinshi_bash" -ge 1 ] || [ "$count_kinshi_mock" -ge 1 ] || [ "$count_kinshi_echo" -ge 1 ]; then
    kinshi_ok=1
  else
    kinshi_ok=0
  fi
  # 推奨 section に real-path invocation 例 (docker or curl or python -m)
  count_suishou_docker=$(section_grep "$FILE" "推奨" "docker")
  count_suishou_curl=$(section_grep "$FILE" "推奨" "curl")
  count_suishou_python=$(section_grep "$FILE" "推奨" "python -m")
  if [ "$count_suishou_docker" -ge 1 ] || [ "$count_suishou_curl" -ge 1 ] || [ "$count_suishou_python" -ge 1 ]; then
    suishou_ok=1
  else
    suishou_ok=0
  fi
  # 出典 section に Kyotei or 20260424 reference
  count_shuten_kyotei=$(section_grep "$FILE" "出典" "Kyotei")
  count_shuten_cycle=$(section_grep "$FILE" "出典" "20260424")
  if [ "$count_shuten_kyotei" -ge 1 ] || [ "$count_shuten_cycle" -ge 1 ]; then
    shuten_ok=1
  else
    shuten_ok=0
  fi
  # file size >= 300 bytes
  size=$(wc -c < "$FILE" | tr -d ' ')
  if [ "$size" -ge 300 ]; then
    size_ok=1
  else
    size_ok=0
  fi

  if [ "$has_h1" -ge 1 ] && [ "$kinshi_ok" -ge 1 ] && [ "$suishou_ok" -ge 1 ] && [ "$shuten_ok" -ge 1 ] && [ "$size_ok" -ge 1 ]; then
    pass "TC-19: rules/integration-verification.md exists + H1 + 禁止事項/推奨/出典 + key phrases + size >= 300 bytes"
  elif [ "$has_h1" -lt 1 ]; then
    fail "TC-19: rules/integration-verification.md missing H1 title"
  elif [ "$kinshi_ok" -lt 1 ]; then
    fail "TC-19: rules/integration-verification.md 禁止事項 section missing 'bash tests/test' or 'mock' or 'echo'"
  elif [ "$suishou_ok" -lt 1 ]; then
    fail "TC-19: rules/integration-verification.md 推奨 section missing 'docker' or 'curl' or 'python -m'"
  elif [ "$shuten_ok" -lt 1 ]; then
    fail "TC-19: rules/integration-verification.md 出典 section missing 'Kyotei' or '20260424' reference"
  else
    fail "TC-19: rules/integration-verification.md is too small ($size bytes, need >= 300)"
  fi
fi

# TC-20: rules/integration-verification.md — 適用範囲 に「新 rule cycle」literal (0900-1 self-apply)
echo ""
echo "TC-20: rules/integration-verification.md 適用範囲 has '新 rule cycle' (0900-1)"
FILE="$RULES_DIR/integration-verification.md"
if [ ! -f "$FILE" ]; then
  fail "TC-20: rules/integration-verification.md does not exist"
else
  count=$(section_grep "$FILE" "適用範囲" "新 rule cycle")
  if [ "$count" -ge 1 ]; then
    pass "TC-20: 新 rule cycle literal in integration-verification.md 適用範囲"
  else
    fail "TC-20: missing '新 rule cycle' in integration-verification.md 適用範囲 (0900-1 未実装)"
  fi
fi

# TC-21: rules/test-patterns.md — 推奨 に「section_grep」literal (0900-2 section-specific grep)
echo ""
echo "TC-21: rules/test-patterns.md 推奨 has 'section_grep' (0900-2)"
FILE="$RULES_DIR/test-patterns.md"
if [ ! -f "$FILE" ]; then
  fail "TC-21: rules/test-patterns.md does not exist"
else
  count=$(section_grep "$FILE" "推奨" "section_grep")
  if [ "$count" -ge 1 ]; then
    pass "TC-21: section_grep literal in test-patterns.md 推奨"
  else
    fail "TC-21: missing 'section_grep' in test-patterns.md 推奨 (0900-2 未実装)"
  fi
fi

# TC-22: rules/plan-discipline.md — 推奨 に「grep -rlF」literal (0900-3 doc sweep)
echo ""
echo "TC-22: rules/plan-discipline.md 推奨 has 'grep -rlF' (0900-3)"
FILE="$RULES_DIR/plan-discipline.md"
if [ ! -f "$FILE" ]; then
  fail "TC-22: rules/plan-discipline.md does not exist"
else
  count=$(section_grep "$FILE" "推奨" "grep -rlF")
  if [ "$count" -ge 1 ]; then
    pass "TC-22: grep -rlF literal in plan-discipline.md 推奨"
  else
    fail "TC-22: missing 'grep -rlF' in plan-discipline.md 推奨 (0900-3 未実装)"
  fi
fi

# TC-23: rules/plan-discipline.md — 推奨 に「除外 category」literal (1119-1 除外数値明記)
echo ""
echo "TC-23: rules/plan-discipline.md 推奨 has '除外 category' (1119-1)"
FILE="$RULES_DIR/plan-discipline.md"
if [ ! -f "$FILE" ]; then
  fail "TC-23: rules/plan-discipline.md does not exist"
else
  count=$(section_grep "$FILE" "推奨" "除外 category")
  if [ "$count" -ge 1 ]; then
    pass "TC-23: 除外 category literal in plan-discipline.md 推奨"
  else
    fail "TC-23: missing '除外 category' in plan-discipline.md 推奨 (1119-1 未実装)"
  fi
fi

# TC-24: rules/test-patterns.md — 禁止事項 に「alternation」literal (1119-2 ERE alternation escape)
echo ""
echo "TC-24: rules/test-patterns.md 禁止事項 has 'alternation' (1119-2)"
FILE="$RULES_DIR/test-patterns.md"
if [ ! -f "$FILE" ]; then
  fail "TC-24: rules/test-patterns.md does not exist"
else
  count=$(section_grep "$FILE" "禁止事項" "alternation")
  if [ "$count" -ge 1 ]; then
    pass "TC-24: alternation literal in test-patterns.md 禁止事項"
  else
    fail "TC-24: missing 'alternation' in test-patterns.md 禁止事項 (1119-2 未実装)"
  fi
fi

# TC-25: skills/review/SKILL.md — Workflow に「git status --short」literal (1119-3 repo-state pre-check)
echo ""
echo "TC-25: skills/review/SKILL.md Workflow has 'git status --short' (1119-3)"
REVIEW_SKILL="$BASE_DIR/skills/review/SKILL.md"
if [ ! -f "$REVIEW_SKILL" ]; then
  fail "TC-25: skills/review/SKILL.md does not exist"
else
  count=$(section_grep "$REVIEW_SKILL" "Workflow" "git status --short")
  if [ "$count" -ge 1 ]; then
    pass "TC-25: git status --short literal in skills/review/SKILL.md Workflow"
  else
    fail "TC-25: missing 'git status --short' in skills/review/SKILL.md Workflow (1119-3 未実装)"
  fi
fi

# TC-26: skills/codify-insight/reference.md — Recurrence-aware Pre-triage に「Reason-aware」literal (1119-4)
echo ""
echo "TC-26: skills/codify-insight/reference.md Recurrence-aware Pre-triage has 'Reason-aware' (1119-4)"
CODIFY_REF="$BASE_DIR/skills/codify-insight/reference.md"
if [ ! -f "$CODIFY_REF" ]; then
  fail "TC-26: skills/codify-insight/reference.md does not exist"
else
  count=$(section_grep "$CODIFY_REF" "Recurrence-aware Pre-triage" "Reason-aware")
  if [ "$count" -ge 1 ]; then
    pass "TC-26: Reason-aware literal in codify-insight/reference.md Recurrence-aware Pre-triage"
  else
    fail "TC-26: missing 'Reason-aware' in codify-insight/reference.md Recurrence-aware Pre-triage (1119-4 未実装)"
  fi
fi

# TC-27: rules/plan-discipline.md — 推奨 に GREEN 検証 sweep literals（curated/GREEN/逆向き契約 or sweep）+ 出典 に 20260625_1101
echo ""
echo "TC-27: rules/plan-discipline.md 推奨 has 'GREEN 検証は curated'+'逆向き契約 sweep' phrases + 出典 has '20260625_1101'"
FILE="$RULES_DIR/plan-discipline.md"
if [ ! -f "$FILE" ]; then
  fail "TC-27: rules/plan-discipline.md does not exist"
else
  # 新規行にのみ現れる連続句で検査する。単体語 (逆向き契約 / sweep / curated / GREEN) は
  # 推奨 section の既存項目にも出現し false-pass する (逆向き契約=L4, sweep=L10 既存)。
  # Codex code review 指摘: 追記行を pin するため contiguous phrase を使う (本 cycle が codify する規律の自己適用)
  count_green_curated=$(section_grep "$FILE" "推奨" "GREEN 検証は curated")
  count_gyaku_sweep=$(section_grep "$FILE" "推奨" "逆向き契約 sweep")
  count_cycle1101=$(section_grep "$FILE" "出典" "20260625_1101")
  if [ "$count_green_curated" -ge 1 ] && [ "$count_gyaku_sweep" -ge 1 ] && [ "$count_cycle1101" -ge 1 ]; then
    pass "TC-27: plan-discipline.md 推奨 has 'GREEN 検証は curated'+'逆向き契約 sweep' + 出典 has 20260625_1101"
  elif [ "$count_green_curated" -lt 1 ]; then
    fail "TC-27: plan-discipline.md 推奨 section missing 'GREEN 検証は curated' phrase (GREEN sweep 規律)"
  elif [ "$count_gyaku_sweep" -lt 1 ]; then
    fail "TC-27: plan-discipline.md 推奨 section missing '逆向き契約 sweep' phrase"
  else
    fail "TC-27: plan-discipline.md 出典 section missing '20260625_1101' reference"
  fi
fi

# TC-28: rules/test-patterns.md — 禁止事項 に「単体語で pin」(A1 禁止形連続句) + 推奨 に
# 「contiguous phrase」「pre-existing count」+ 出典 に 20260701_1120
# A1 の禁止事項も pin する（推奨のみだと禁止形を落としても PASS するため）
echo ""
echo "TC-28: rules/test-patterns.md 禁止事項 has '単体語で pin' + 推奨 has 'contiguous phrase'+'pre-existing count' + 出典 has '20260701_1120'"
FILE="$RULES_DIR/test-patterns.md"
if [ ! -f "$FILE" ]; then
  fail "TC-28: rules/test-patterns.md does not exist"
else
  count_tandaigo=$(section_grep "$FILE" "禁止事項" "単体語で pin")
  count_contiguous=$(section_grep "$FILE" "推奨" "contiguous phrase")
  count_preexisting=$(section_grep "$FILE" "推奨" "pre-existing count")
  count_cycle0701=$(section_grep "$FILE" "出典" "20260701_1120")
  if [ "$count_tandaigo" -ge 1 ] && [ "$count_contiguous" -ge 1 ] && [ "$count_preexisting" -ge 1 ] && [ "$count_cycle0701" -ge 1 ]; then
    pass "TC-28: test-patterns.md 禁止事項 has 単体語で pin + 推奨 has contiguous phrase + pre-existing count + 出典 has 20260701_1120"
  elif [ "$count_tandaigo" -lt 1 ]; then
    fail "TC-28: test-patterns.md 禁止事項 section missing '単体語で pin' phrase (A1 禁止形 pin 未実装)"
  elif [ "$count_contiguous" -lt 1 ]; then
    fail "TC-28: test-patterns.md 推奨 section missing 'contiguous phrase'"
  elif [ "$count_preexisting" -lt 1 ]; then
    fail "TC-28: test-patterns.md 推奨 section missing 'pre-existing count'"
  else
    fail "TC-28: test-patterns.md 出典 section missing '20260701_1120' reference"
  fi
fi

# TC-29: rules/test-patterns.md — 推奨 に「分岐 × 既存チェック」「出力文字列 assert」
# 「挙動チェックリスト」+ 出典 に 20260702_1930
echo ""
echo "TC-29: rules/test-patterns.md 推奨 has '分岐 × 既存チェック'+'出力文字列 assert'+'挙動チェックリスト' + 出典 has '20260702_1930'"
FILE="$RULES_DIR/test-patterns.md"
if [ ! -f "$FILE" ]; then
  fail "TC-29: rules/test-patterns.md does not exist"
else
  count_bunki=$(section_grep "$FILE" "推奨" "分岐 × 既存チェック")
  count_shutsuryoku=$(section_grep "$FILE" "推奨" "出力文字列 assert")
  count_kyodo=$(section_grep "$FILE" "推奨" "挙動チェックリスト")
  count_cycle1930=$(section_grep "$FILE" "出典" "20260702_1930")
  if [ "$count_bunki" -ge 1 ] && [ "$count_shutsuryoku" -ge 1 ] && [ "$count_kyodo" -ge 1 ] && [ "$count_cycle1930" -ge 1 ]; then
    pass "TC-29: test-patterns.md 推奨 has 分岐×既存チェック + 出力文字列 assert + 挙動チェックリスト + 出典 has 20260702_1930"
  elif [ "$count_bunki" -lt 1 ]; then
    fail "TC-29: test-patterns.md 推奨 section missing '分岐 × 既存チェック'"
  elif [ "$count_shutsuryoku" -lt 1 ]; then
    fail "TC-29: test-patterns.md 推奨 section missing '出力文字列 assert'"
  elif [ "$count_kyodo" -lt 1 ]; then
    fail "TC-29: test-patterns.md 推奨 section missing '挙動チェックリスト'"
  else
    fail "TC-29: test-patterns.md 出典 section missing '20260702_1930' reference"
  fi
fi

# TC-30: rules/plan-discipline.md — 推奨 に「immutable snapshot 複製」「並行プロセスから隔離」
# + 出典 に 20260702_1200
echo ""
echo "TC-30: rules/plan-discipline.md 推奨 has 'immutable snapshot 複製'+'並行プロセスから隔離' + 出典 has '20260702_1200'"
FILE="$RULES_DIR/plan-discipline.md"
if [ ! -f "$FILE" ]; then
  fail "TC-30: rules/plan-discipline.md does not exist"
else
  count_snapshot=$(section_grep "$FILE" "推奨" "immutable snapshot 複製")
  count_kakuri=$(section_grep "$FILE" "推奨" "並行プロセスから隔離")
  count_cycle1200=$(section_grep "$FILE" "出典" "20260702_1200")
  if [ "$count_snapshot" -ge 1 ] && [ "$count_kakuri" -ge 1 ] && [ "$count_cycle1200" -ge 1 ]; then
    pass "TC-30: plan-discipline.md 推奨 has immutable snapshot 複製 + 並行プロセスから隔離 + 出典 has 20260702_1200"
  elif [ "$count_snapshot" -lt 1 ]; then
    fail "TC-30: plan-discipline.md 推奨 section missing 'immutable snapshot 複製'"
  elif [ "$count_kakuri" -lt 1 ]; then
    fail "TC-30: plan-discipline.md 推奨 section missing '並行プロセスから隔離'"
  else
    fail "TC-30: plan-discipline.md 出典 section missing '20260702_1200' reference"
  fi
fi

# TC-31: rules/agent-prompts.md — 並列起動時の prompt 契約 に「読み取り並列・実行直列」
# 「テスト実行可否」+ 出典 に 20260702_1200
echo ""
echo "TC-31: rules/agent-prompts.md 並列起動時の prompt 契約 has '読み取り並列・実行直列'+'テスト実行可否' + 出典 has '20260702_1200'"
FILE="$RULES_DIR/agent-prompts.md"
if [ ! -f "$FILE" ]; then
  fail "TC-31: rules/agent-prompts.md does not exist"
else
  count_yomikaki=$(section_grep "$FILE" "並列起動時の prompt 契約" "読み取り並列・実行直列")
  count_kahi=$(section_grep "$FILE" "並列起動時の prompt 契約" "テスト実行可否")
  count_cycle1200=$(section_grep "$FILE" "出典" "20260702_1200")
  if [ "$count_yomikaki" -ge 1 ] && [ "$count_kahi" -ge 1 ] && [ "$count_cycle1200" -ge 1 ]; then
    pass "TC-31: agent-prompts.md 並列起動時の prompt 契約 has 読み取り並列・実行直列 + テスト実行可否 + 出典 has 20260702_1200"
  elif [ "$count_yomikaki" -lt 1 ]; then
    fail "TC-31: agent-prompts.md 並列起動時の prompt 契約 section missing '読み取り並列・実行直列'"
  elif [ "$count_kahi" -lt 1 ]; then
    fail "TC-31: agent-prompts.md 並列起動時の prompt 契約 section missing 'テスト実行可否'"
  else
    fail "TC-31: agent-prompts.md 出典 section missing '20260702_1200' reference"
  fi
fi

# TC-32: rules/integration-verification.md — 推奨 に「usage を実測」+ 出典 に 20260702_1200
echo ""
echo "TC-32: rules/integration-verification.md 推奨 has 'usage を実測' + 出典 has '20260702_1200'"
FILE="$RULES_DIR/integration-verification.md"
if [ ! -f "$FILE" ]; then
  fail "TC-32: rules/integration-verification.md does not exist"
else
  count_usage=$(section_grep "$FILE" "推奨" "usage を実測")
  count_cycle1200=$(section_grep "$FILE" "出典" "20260702_1200")
  if [ "$count_usage" -ge 1 ] && [ "$count_cycle1200" -ge 1 ]; then
    pass "TC-32: integration-verification.md 推奨 has usage を実測 + 出典 has 20260702_1200"
  elif [ "$count_usage" -lt 1 ]; then
    fail "TC-32: integration-verification.md 推奨 section missing 'usage を実測'"
  else
    fail "TC-32: integration-verification.md 出典 section missing '20260702_1200' reference"
  fi
fi

# TC-33: rules/multi-file-consistency.md — 推奨 に「信頼するディレクトリ境界」+ 出典 に 20260702_1930
echo ""
echo "TC-33: rules/multi-file-consistency.md 推奨 has '信頼するディレクトリ境界' + 出典 has '20260702_1930'"
FILE="$RULES_DIR/multi-file-consistency.md"
if [ ! -f "$FILE" ]; then
  fail "TC-33: rules/multi-file-consistency.md does not exist"
else
  count_kyokai=$(section_grep "$FILE" "推奨" "信頼するディレクトリ境界")
  count_cycle1930=$(section_grep "$FILE" "出典" "20260702_1930")
  if [ "$count_kyokai" -ge 1 ] && [ "$count_cycle1930" -ge 1 ]; then
    pass "TC-33: multi-file-consistency.md 推奨 has 信頼するディレクトリ境界 + 出典 has 20260702_1930"
  elif [ "$count_kyokai" -lt 1 ]; then
    fail "TC-33: multi-file-consistency.md 推奨 section missing '信頼するディレクトリ境界'"
  else
    fail "TC-33: multi-file-consistency.md 出典 section missing '20260702_1930' reference"
  fi
fi

# TC-34: rules/test-patterns.md — 推奨 に「変数に受けて」「process substitution」+ 出典 に 20260703_1215
echo ""
echo "TC-34: rules/test-patterns.md 推奨 has '変数に受けて'+'process substitution' + 出典 has '20260703_1215'"
FILE="$RULES_DIR/test-patterns.md"
if [ ! -f "$FILE" ]; then
  fail "TC-34: rules/test-patterns.md does not exist"
else
  count_hensuu=$(section_grep "$FILE" "推奨" "変数に受けて")
  count_procsub=$(section_grep "$FILE" "推奨" "process substitution")
  count_cycle1215=$(section_grep "$FILE" "出典" "20260703_1215")
  if [ "$count_hensuu" -ge 1 ] && [ "$count_procsub" -ge 1 ] && [ "$count_cycle1215" -ge 1 ]; then
    pass "TC-34: test-patterns.md 推奨 has 変数に受けて + process substitution + 出典 has 20260703_1215"
  elif [ "$count_hensuu" -lt 1 ]; then
    fail "TC-34: test-patterns.md 推奨 section missing '変数に受けて'"
  elif [ "$count_procsub" -lt 1 ]; then
    fail "TC-34: test-patterns.md 推奨 section missing 'process substitution'"
  else
    fail "TC-34: test-patterns.md 出典 section missing '20260703_1215' reference"
  fi
fi

# TC-35: rules/plan-discipline.md — 推奨 に「自動契約に昇格」「2-strike」+ 出典 に 20260703_1215
echo ""
echo "TC-35: rules/plan-discipline.md 推奨 has '自動契約に昇格'+'2-strike' + 出典 has '20260703_1215'"
FILE="$RULES_DIR/plan-discipline.md"
if [ ! -f "$FILE" ]; then
  fail "TC-35: rules/plan-discipline.md does not exist"
else
  count_shoukaku=$(section_grep "$FILE" "推奨" "自動契約に昇格")
  count_2strike=$(section_grep "$FILE" "推奨" "2-strike")
  count_cycle1215=$(section_grep "$FILE" "出典" "20260703_1215")
  if [ "$count_shoukaku" -ge 1 ] && [ "$count_2strike" -ge 1 ] && [ "$count_cycle1215" -ge 1 ]; then
    pass "TC-35: plan-discipline.md 推奨 has 自動契約に昇格 + 2-strike + 出典 has 20260703_1215"
  elif [ "$count_shoukaku" -lt 1 ]; then
    fail "TC-35: plan-discipline.md 推奨 section missing '自動契約に昇格'"
  elif [ "$count_2strike" -lt 1 ]; then
    fail "TC-35: plan-discipline.md 推奨 section missing '2-strike'"
  else
    fail "TC-35: plan-discipline.md 出典 section missing '20260703_1215' reference"
  fi
fi

# TC-36: rules/integration-verification.md — 適用範囲 (H2、H3「新 rule cycle への self-apply」を包含) に
# 「全成果物」「checklist 適用」+ 出典 に 20260703_1215
echo ""
echo "TC-36: rules/integration-verification.md 適用範囲 has '全成果物'+'checklist 適用' + 出典 has '20260703_1215'"
FILE="$RULES_DIR/integration-verification.md"
if [ ! -f "$FILE" ]; then
  fail "TC-36: rules/integration-verification.md does not exist"
else
  count_zenseika=$(section_grep "$FILE" "適用範囲" "全成果物")
  count_checklist=$(section_grep "$FILE" "適用範囲" "checklist 適用")
  count_cycle1215=$(section_grep "$FILE" "出典" "20260703_1215")
  if [ "$count_zenseika" -ge 1 ] && [ "$count_checklist" -ge 1 ] && [ "$count_cycle1215" -ge 1 ]; then
    pass "TC-36: integration-verification.md 適用範囲 has 全成果物 + checklist 適用 + 出典 has 20260703_1215"
  elif [ "$count_zenseika" -lt 1 ]; then
    fail "TC-36: integration-verification.md 適用範囲 section missing '全成果物'"
  elif [ "$count_checklist" -lt 1 ]; then
    fail "TC-36: integration-verification.md 適用範囲 section missing 'checklist 適用'"
  else
    fail "TC-36: integration-verification.md 出典 section missing '20260703_1215' reference"
  fi
fi

# TC-37: rules/agent-prompts.md — 並列起動時の prompt 契約 に「委譲 prompt」「テンプレートを疑」+ 出典 に 20260703_1650
# section_grep のheading matchはawkの正規表現なので括弧付き見出し
# "並列起動時の prompt 契約 (3+ subagent fan-out)" は match しない（実測確認済み）。
# 括弧を含まない前方一致部分のみ渡す
echo ""
echo "TC-37: rules/agent-prompts.md 並列起動時の prompt 契約 has '委譲 prompt'+'テンプレートを疑' + 出典 has '20260703_1650'"
FILE="$RULES_DIR/agent-prompts.md"
if [ ! -f "$FILE" ]; then
  fail "TC-37: rules/agent-prompts.md does not exist"
else
  count_itaku=$(section_grep "$FILE" "並列起動時の prompt 契約" "委譲 prompt")
  count_utagau=$(section_grep "$FILE" "並列起動時の prompt 契約" "テンプレートを疑")
  count_cycle1650=$(section_grep "$FILE" "出典" "20260703_1650")
  if [ "$count_itaku" -ge 1 ] && [ "$count_utagau" -ge 1 ] && [ "$count_cycle1650" -ge 1 ]; then
    pass "TC-37: agent-prompts.md 並列起動時の prompt 契約 has 委譲 prompt + テンプレートを疑 + 出典 has 20260703_1650"
  elif [ "$count_itaku" -lt 1 ]; then
    fail "TC-37: agent-prompts.md 並列起動時の prompt 契約 section missing '委譲 prompt'"
  elif [ "$count_utagau" -lt 1 ]; then
    fail "TC-37: agent-prompts.md 並列起動時の prompt 契約 section missing 'テンプレートを疑'"
  else
    fail "TC-37: agent-prompts.md 出典 section missing '20260703_1650' reference"
  fi
fi

# TC-38: rules/doc-mutations.md — SSOT 即時同期 に「実行した主体」「Test List 遷移」+ 出典 に 20260703_1650
# TC-37 と同じ理由で、見出しの括弧付き補足部分は section_grep に渡さない
echo ""
echo "TC-38: rules/doc-mutations.md SSOT 即時同期 has '実行した主体'+'Test List 遷移' + 出典 has '20260703_1650'"
FILE="$RULES_DIR/doc-mutations.md"
if [ ! -f "$FILE" ]; then
  fail "TC-38: rules/doc-mutations.md does not exist"
else
  count_shutai=$(section_grep "$FILE" "SSOT 即時同期" "実行した主体")
  count_iko=$(section_grep "$FILE" "SSOT 即時同期" "Test List 遷移")
  count_cycle1650=$(section_grep "$FILE" "出典" "20260703_1650")
  if [ "$count_shutai" -ge 1 ] && [ "$count_iko" -ge 1 ] && [ "$count_cycle1650" -ge 1 ]; then
    pass "TC-38: doc-mutations.md SSOT 即時同期 has 実行した主体 + Test List 遷移 + 出典 has 20260703_1650"
  elif [ "$count_shutai" -lt 1 ]; then
    fail "TC-38: doc-mutations.md SSOT 即時同期 section missing '実行した主体'"
  elif [ "$count_iko" -lt 1 ]; then
    fail "TC-38: doc-mutations.md SSOT 即時同期 section missing 'Test List 遷移'"
  else
    fail "TC-38: doc-mutations.md 出典 section missing '20260703_1650' reference"
  fi
fi

# TC-39: rules/doc-mutations.md — 「Frontmatter 遷移の区間限定編集」に「全文一括置換」+ 出典 に 20260703_2035
echo ""
echo "TC-39: rules/doc-mutations.md Frontmatter 遷移の区間限定編集 has '全文一括置換' + 出典 has '20260703_2035'"
FILE="$RULES_DIR/doc-mutations.md"
if [ ! -f "$FILE" ]; then
  fail "TC-39: rules/doc-mutations.md does not exist"
else
  count_zenbun=$(section_grep "$FILE" "Frontmatter 遷移の区間限定編集" "全文一括置換")
  count_cycle2035=$(section_grep "$FILE" "出典" "20260703_2035")
  if [ "$count_zenbun" -ge 1 ] && [ "$count_cycle2035" -ge 1 ]; then
    pass "TC-39: doc-mutations.md Frontmatter 遷移の区間限定編集 has 全文一括置換 + 出典 has 20260703_2035"
  elif [ "$count_zenbun" -lt 1 ]; then
    fail "TC-39: doc-mutations.md Frontmatter 遷移の区間限定編集 section missing '全文一括置換' (cycle 20260703_2035 #1 未実装)"
  else
    fail "TC-39: doc-mutations.md 出典 section missing '20260703_2035' reference"
  fi
fi

# TC-40: rules/test-patterns.md — 禁止事項 に「ERE メタ文字」、推奨 に「短縮見出し」+ 出典 に 20260703_2035
echo ""
echo "TC-40: rules/test-patterns.md 禁止事項 has 'ERE メタ文字' + 推奨 has '短縮見出し' + 出典 has '20260703_2035'"
FILE="$RULES_DIR/test-patterns.md"
if [ ! -f "$FILE" ]; then
  fail "TC-40: rules/test-patterns.md does not exist"
else
  count_ere=$(section_grep "$FILE" "禁止事項" "ERE メタ文字")
  count_tanshuku=$(section_grep "$FILE" "推奨" "短縮見出し")
  count_cycle2035=$(section_grep "$FILE" "出典" "20260703_2035")
  if [ "$count_ere" -ge 1 ] && [ "$count_tanshuku" -ge 1 ] && [ "$count_cycle2035" -ge 1 ]; then
    pass "TC-40: test-patterns.md 禁止事項 has ERE メタ文字 + 推奨 has 短縮見出し + 出典 has 20260703_2035"
  elif [ "$count_ere" -lt 1 ]; then
    fail "TC-40: test-patterns.md 禁止事項 section missing 'ERE メタ文字' (cycle 20260703_2035 #2 未実装)"
  elif [ "$count_tanshuku" -lt 1 ]; then
    fail "TC-40: test-patterns.md 推奨 section missing '短縮見出し'"
  else
    fail "TC-40: test-patterns.md 出典 section missing '20260703_2035' reference"
  fi
fi

# TC-41: rules/agent-prompts.md（既存・無変更）— section_grep をフル括弧見出し
# 「並列起動時の prompt 契約 (3+ subagent fan-out)」× literal「担当範囲」で呼ぶ回帰契約。
# 意図的にメタ文字（括弧・+）を含むフル見出しを section_grep に渡す。旧 ERE 実装
# ($0 ~ "^## " h) では見出し文字列が動的正規表現として解釈され silent no-match
# (count=0) になっていた — 現行の fixed-string 実装 (index($0, "## " h) == 1) では
# count>=1 となる。ERE 解釈への退行を検出する回帰契約
echo ""
echo "TC-41: rules/agent-prompts.md section_grep with full parenthesized heading has '担当範囲' (fixed-string regression contract)"
FILE="$RULES_DIR/agent-prompts.md"
if [ ! -f "$FILE" ]; then
  fail "TC-41: rules/agent-prompts.md does not exist"
else
  count_tantou=$(section_grep "$FILE" "並列起動時の prompt 契約 (3+ subagent fan-out)" "担当範囲")
  if [ "$count_tantou" -ge 1 ]; then
    pass "TC-41: section_grep with full parenthesized heading matches '担当範囲' (fixed-string 化済み)"
  else
    fail "TC-41: section_grep with full parenthesized heading returns count=0 for '担当範囲' (section_grep が ERE 解釈のまま — fixed-string 化未実装)"
  fi
fi

# TC-42: rules/plan-discipline.md — 禁止事項 に「否定形前提」「発生機序」+ 出典 に 20260706_1020
echo ""
echo "TC-42: rules/plan-discipline.md 禁止事項 has '否定形前提'+'発生機序' + 出典 has '20260706_1020'"
FILE="$RULES_DIR/plan-discipline.md"
if [ ! -f "$FILE" ]; then
  fail "TC-42: rules/plan-discipline.md does not exist"
else
  count_hitei=$(section_grep "$FILE" "禁止事項" "否定形前提")
  count_kijo=$(section_grep "$FILE" "禁止事項" "発生機序")
  count_cycle1020=$(section_grep "$FILE" "出典" "20260706_1020")
  if [ "$count_hitei" -ge 1 ] && [ "$count_kijo" -ge 1 ] && [ "$count_cycle1020" -ge 1 ]; then
    pass "TC-42: plan-discipline.md 禁止事項 has 否定形前提 + 発生機序 + 出典 has 20260706_1020"
  elif [ "$count_hitei" -lt 1 ]; then
    fail "TC-42: plan-discipline.md 禁止事項 section missing '否定形前提' (cycle 20260706_1020 #1 未実装)"
  elif [ "$count_kijo" -lt 1 ]; then
    fail "TC-42: plan-discipline.md 禁止事項 section missing '発生機序'"
  else
    fail "TC-42: plan-discipline.md 出典 section missing '20260706_1020' reference"
  fi
fi

# TC-43: rules/plan-discipline.md — 推奨 に「親構造ごと複製」「棄却実験」+ 出典 に 20260706_1216
echo ""
echo "TC-43: rules/plan-discipline.md 推奨 has '親構造ごと複製'+'棄却実験' + 出典 has '20260706_1216'"
FILE="$RULES_DIR/plan-discipline.md"
if [ ! -f "$FILE" ]; then
  fail "TC-43: rules/plan-discipline.md does not exist"
else
  count_oyakouzou=$(section_grep "$FILE" "推奨" "親構造ごと複製")
  count_kikyaku=$(section_grep "$FILE" "推奨" "棄却実験")
  count_cycle1216=$(section_grep "$FILE" "出典" "20260706_1216")
  if [ "$count_oyakouzou" -ge 1 ] && [ "$count_kikyaku" -ge 1 ] && [ "$count_cycle1216" -ge 1 ]; then
    pass "TC-43: plan-discipline.md 推奨 has 親構造ごと複製 + 棄却実験 + 出典 has 20260706_1216"
  elif [ "$count_oyakouzou" -lt 1 ]; then
    fail "TC-43: plan-discipline.md 推奨 section missing '親構造ごと複製' (cycle 20260706_1216 #1 未実装)"
  elif [ "$count_kikyaku" -lt 1 ]; then
    fail "TC-43: plan-discipline.md 推奨 section missing '棄却実験'"
  else
    fail "TC-43: plan-discipline.md 出典 section missing '20260706_1216' reference"
  fi
fi

# TC-44: rules/multi-file-consistency.md — 推奨 に「multi-mode」「契約テストで pin」+ 出典 に 20260706_1020
echo ""
echo "TC-44: rules/multi-file-consistency.md 推奨 has 'multi-mode'+'契約テストで pin' + 出典 has '20260706_1020'"
FILE="$RULES_DIR/multi-file-consistency.md"
if [ ! -f "$FILE" ]; then
  fail "TC-44: rules/multi-file-consistency.md does not exist"
else
  count_multimode=$(section_grep "$FILE" "推奨" "multi-mode")
  count_pin=$(section_grep "$FILE" "推奨" "契約テストで pin")
  count_cycle1020=$(section_grep "$FILE" "出典" "20260706_1020")
  if [ "$count_multimode" -ge 1 ] && [ "$count_pin" -ge 1 ] && [ "$count_cycle1020" -ge 1 ]; then
    pass "TC-44: multi-file-consistency.md 推奨 has multi-mode + 契約テストで pin + 出典 has 20260706_1020"
  elif [ "$count_multimode" -lt 1 ]; then
    fail "TC-44: multi-file-consistency.md 推奨 section missing 'multi-mode' (cycle 20260706_1020 #2 未実装)"
  elif [ "$count_pin" -lt 1 ]; then
    fail "TC-44: multi-file-consistency.md 推奨 section missing '契約テストで pin'"
  else
    fail "TC-44: multi-file-consistency.md 出典 section missing '20260706_1020' reference"
  fi
fi

# TC-45: rules/test-patterns.md — 禁止事項 に「同型 sweep」、推奨 に「検証重量」+ 出典 に 20260706_1216
echo ""
echo "TC-45: rules/test-patterns.md 禁止事項 has '同型 sweep' + 推奨 has '検証重量' + 出典 has '20260706_1216'"
FILE="$RULES_DIR/test-patterns.md"
if [ ! -f "$FILE" ]; then
  fail "TC-45: rules/test-patterns.md does not exist"
else
  count_doukei=$(section_grep "$FILE" "禁止事項" "同型 sweep")
  count_kenshou=$(section_grep "$FILE" "推奨" "検証重量")
  count_cycle1216=$(section_grep "$FILE" "出典" "20260706_1216")
  if [ "$count_doukei" -ge 1 ] && [ "$count_kenshou" -ge 1 ] && [ "$count_cycle1216" -ge 1 ]; then
    pass "TC-45: test-patterns.md 禁止事項 has 同型 sweep + 推奨 has 検証重量 + 出典 has 20260706_1216"
  elif [ "$count_doukei" -lt 1 ]; then
    fail "TC-45: test-patterns.md 禁止事項 section missing '同型 sweep' (cycle 20260706_1216 #2 未実装)"
  elif [ "$count_kenshou" -lt 1 ]; then
    fail "TC-45: test-patterns.md 推奨 section missing '検証重量'"
  else
    fail "TC-45: test-patterns.md 出典 section missing '20260706_1216' reference"
  fi
fi

# TC-46: rules/agent-prompts.md — 推奨 に「実測値で記録」「date "+%Y-%m-%d %H:%M"」+ 出典 に 20260706_1216
echo ""
echo 'TC-46: rules/agent-prompts.md 推奨 has 実測値で記録 + date "+%Y-%m-%d %H:%M" + 出典 has 20260706_1216'
FILE="$RULES_DIR/agent-prompts.md"
if [ ! -f "$FILE" ]; then
  fail "TC-46: rules/agent-prompts.md does not exist"
else
  count_jissoku=$(section_grep "$FILE" "推奨" "実測値で記録")
  count_dateformat=$(section_grep "$FILE" "推奨" 'date "+%Y-%m-%d %H:%M"')
  count_cycle1216=$(section_grep "$FILE" "出典" "20260706_1216")
  if [ "$count_jissoku" -ge 1 ] && [ "$count_dateformat" -ge 1 ] && [ "$count_cycle1216" -ge 1 ]; then
    pass 'TC-46: agent-prompts.md 推奨 has 実測値で記録 + date "+%Y-%m-%d %H:%M" + 出典 has 20260706_1216'
  elif [ "$count_jissoku" -lt 1 ]; then
    fail "TC-46: agent-prompts.md 推奨 section missing '実測値で記録' (cycle 20260706_1216 #3 未実装)"
  elif [ "$count_dateformat" -lt 1 ]; then
    fail 'TC-46: agent-prompts.md 推奨 section missing date "+%Y-%m-%d %H:%M" literal'
  else
    fail "TC-46: agent-prompts.md 出典 section missing '20260706_1216' reference"
  fi
fi

# --- codified rules batch (7 rule files + spec template) ---
# Each TC-47..64 pins its clause by FOUR region-limited section_grep checks:
#   (1) phrase1 + (2) phrase2 — a contiguous phrase pair capturing the clause's core
#       causality (prohibition句 + 対応句), each verified pre-existing count=0 in-section
#       (removal of the clause drives count to 0, so a single word cannot false-pass);
#   (3) the full-path inline source ref in the SAME target section (body-to-source binding
#       — pairs with the inline citation migration);
#   (4) the same full-path ref in ## 出典.
# The docs/cycles/<file>.md #N literal is inspection data (grep argument only), not a
# comment identifier.

# clause_check <tc> <file> <section> <phrase1> <phrase2> <full-path ref>
clause_check() {
  local tc="$1" file="$2" sec="$3" p1="$4" p2="$5" ref="$6"
  if [ ! -f "$file" ]; then
    fail "$tc: $file does not exist"
    return
  fi
  local c1 c2 cin csrc
  c1=$(section_grep "$file" "$sec" "$p1")
  c2=$(section_grep "$file" "$sec" "$p2")
  cin=$(section_grep "$file" "$sec" "$ref")
  csrc=$(section_grep "$file" "出典" "$ref")
  if [ "$c1" -ge 1 ] && [ "$c2" -ge 1 ] && [ "$cin" -ge 1 ] && [ "$csrc" -ge 1 ]; then
    pass "$tc: $sec has clause phrase pair + inline full-path ref + 出典 ref"
  elif [ "$c1" -lt 1 ]; then
    fail "$tc: $sec section missing phrase '$p1'"
  elif [ "$c2" -lt 1 ]; then
    fail "$tc: $sec section missing phrase '$p2'"
  elif [ "$cin" -lt 1 ]; then
    fail "$tc: $sec section missing inline full-path source ref '$ref'"
  else
    fail "$tc: 出典 section missing source ref '$ref'"
  fi
}

# TC-47: rules/test-patterns.md 推奨 — SIGPIPE consumer clause
echo ""
echo "TC-47: test-patterns.md 推奨 SIGPIPE consumer clause (phrase pair + full-path ref)"
clause_check "TC-47" "$RULES_DIR/test-patterns.md" "推奨" \
  "早期終了する consumer" "materialize して pipe を消す" \
  "docs/cycles/20260709_1125_risk-classifier-doc-diff-fix.md #1"

# TC-48: rules/test-patterns.md 推奨 — diagram node-token pin clause
echo ""
echo "TC-48: test-patterns.md 推奨 diagram node-token pin clause"
clause_check "TC-48" "$RULES_DIR/test-patterns.md" "推奨" \
  "ノードトークン + 隣接ノードとの位置" "COMMIT ノード < DONE ノード" \
  "docs/cycles/20260715_1346_v2.12-docs-alignment.md #1"

# TC-49: rules/test-patterns.md 推奨 — multi-pipe rc + 権限拒否 fixture clause
echo ""
echo "TC-49: test-patterns.md 推奨 multi-pipe rc + 権限拒否 fixture clause"
clause_check "TC-49" "$RULES_DIR/test-patterns.md" "推奨" \
  "rc を検査したいコマンドは pipe に入れない" "権限拒否 fixture で誘発" \
  "docs/cycles/20260716_1328_doc-drift-fix.md #1"

# TC-50: rules/test-patterns.md 推奨 — negative sweep 新文言不一致 clause
echo ""
echo "TC-50: test-patterns.md 推奨 negative sweep 新文言不一致 oracle clause"
clause_check "TC-50" "$RULES_DIR/test-patterns.md" "推奨" \
  "置換後の新文言に不一致" "reviewer の提案パターンも無検証で採用しない" \
  "docs/cycles/20260716_1328_doc-drift-fix.md #3"

# TC-51: rules/test-patterns.md 推奨 — hash boundary fixture pin clause
echo ""
echo "TC-51: test-patterns.md 推奨 hash boundary fixture pin clause"
clause_check "TC-51" "$RULES_DIR/test-patterns.md" "推奨" \
  "部分文字列 split は本文引用で誤切断" "被検証者の実装を流用しない" \
  "docs/cycles/20260717_1126_approval-reorder.md #1"

# TC-52: rules/test-patterns.md 推奨 — 見出し区間先行抽出 code block clause
echo ""
echo "TC-52: test-patterns.md 推奨 見出し区間先行抽出→区間内 code block clause"
clause_check "TC-52" "$RULES_DIR/test-patterns.md" "推奨" \
  "見出し区間を先行抽出 → 区間内 code block を走査" "別 section の decoy を拾い" \
  "docs/cycles/20260717_1605_approval-reorder-cycle2.md #1"

# TC-53: rules/test-patterns.md 禁止事項 — 相対アンカー禁止 clause
echo ""
echo "TC-53: test-patterns.md 禁止事項 相対アンカー禁止 clause"
clause_check "TC-53" "$RULES_DIR/test-patterns.md" "禁止事項" \
  "リリースで指示対象が変わる相対アンカー" "immutable な絶対アンカー" \
  "docs/cycles/20260721_1503_rules-load-trigger-reclassification.md #1"

# TC-54: rules/test-patterns.md 推奨 — 機械可読契約 executable + fixture oracle clause
echo ""
echo "TC-54: test-patterns.md 推奨 機械可読契約 実行可能コマンド + fixture oracle clause"
clause_check "TC-54" "$RULES_DIR/test-patterns.md" "推奨" \
  "実行可能コマンド（そのまま動く変数表記" "散文契約は「もっともらしいが動かないコマンド」を許す" \
  "docs/cycles/20260723_1103_cycle-doc-trailer-and-recall-miss-question.md #1"

# TC-55: rules/plan-discipline.md 推奨 — 継承デフォルト前提 clause
echo ""
echo "TC-55: plan-discipline.md 推奨 継承デフォルト前提 clause"
clause_check "TC-55" "$RULES_DIR/plan-discipline.md" "推奨" \
  "継承デフォルト前提" "解決順を一次ソース（公式 doc）で確認" \
  "docs/cycles/20260709_1313_reviewer-model-policy-v1.md #1"

# TC-56: rules/plan-discipline.md 推奨 — 連番次値 grep 実測 clause
echo ""
echo "TC-56: plan-discipline.md 推奨 連番次値 grep 実測 clause"
clause_check "TC-56" "$RULES_DIR/plan-discipline.md" "推奨" \
  "識別子の連番次値" "採番の根拠にしない" \
  "docs/cycles/20260716_1328_doc-drift-fix.md #2"

# TC-57: rules/plan-discipline.md 推奨 — Block 0 codify scope 同梱 clause
echo ""
echo "TC-57: plan-discipline.md 推奨 Block 0 codify scope 同梱透明化 clause"
clause_check "TC-57" "$RULES_DIR/plan-discipline.md" "推奨" \
  "codify gate は前 cycle doc を変更" "scope 同梱として明示裁定" \
  "docs/cycles/20260717_1605_approval-reorder-cycle2.md #2"

# TC-58: rules/review-triage.md 推奨 — 判定割れ機構分解 clause
echo ""
echo "TC-58: review-triage.md 推奨 判定割れ機構分解 + 実測 oracle clause"
clause_check "TC-58" "$RULES_DIR/review-triage.md" "推奨" \
  "reviewer 間の判定割れ" "機構レベルの分解 + 実測 oracle" \
  "docs/cycles/20260709_1125_risk-classifier-doc-diff-fix.md #2"

# TC-59: rules/review-triage.md 推奨 — tier テーブル置換 構造突合 clause
echo ""
echo "TC-59: review-triage.md 推奨 tier テーブル置換 構造突合 clause"
clause_check "TC-59" "$RULES_DIR/review-triage.md" "推奨" \
  "tier テーブル置換" "構造と突合してから書く" \
  "docs/cycles/20260709_1313_reviewer-model-policy-v1.md #2"

# TC-60: rules/agent-prompts.md 推奨 — フェーズ完了マーカー clause
echo ""
echo "TC-60: agent-prompts.md 推奨 委譲 worker フェーズ完了マーカー clause"
clause_check "TC-60" "$RULES_DIR/agent-prompts.md" "推奨" \
  "フェーズ完了マーカー" "SYNC-PLAN 完了マーカー欠落" \
  "docs/cycles/20260717_1126_approval-reorder.md #4"

# TC-61: rules/agent-prompts.md 推奨 — timestamp Progress Log 追記全般 clause
echo ""
echo "TC-61: agent-prompts.md 推奨 timestamp 契約 Progress Log 追記全般拡張 clause"
clause_check "TC-61" "$RULES_DIR/agent-prompts.md" "推奨" \
  "Progress Log 追記全般" "別ステップでの実測は世代がずれる" \
  "docs/cycles/20260721_1503_rules-load-trigger-reclassification.md #2"

# TC-62: rules/integration-verification.md 推奨 — gate 強化 全 caller pin clause
echo ""
echo "TC-62: integration-verification.md 推奨 gate 強化 全 caller pin clause"
clause_check "TC-62" "$RULES_DIR/integration-verification.md" "推奨" \
  "全 caller pin" "dead な防御" \
  "docs/cycles/20260717_1126_approval-reorder.md #2"

# TC-63: rules/multi-file-consistency.md 推奨 — 順序反転 negative assert clause
echo ""
echo "TC-63: multi-file-consistency.md 推奨 順序反転 negative assert pin clause"
clause_check "TC-63" "$RULES_DIR/multi-file-consistency.md" "推奨" \
  "negative assert（旧呼び出しの不在）" "旧記述の除去 + 新記述" \
  "docs/cycles/20260717_1126_approval-reorder.md #3"

# TC-64: rules/doc-mutations.md 推奨 — current-state doc 全体 sweep clause
echo ""
echo "TC-64: doc-mutations.md 推奨 current-state 更新は doc 全体 sweep clause"
clause_check "TC-64" "$RULES_DIR/doc-mutations.md" "推奨" \
  "doc 全体 sweep" "header ローカルでなく doc-wide" \
  "docs/cycles/20260715_1346_v2.12-docs-alignment.md #2"

# TC-65: skills/spec Plan File Template — override forgery-path closure (both langs).
# The fenced '- override:' field must be VALUE-LESS so a verbatim template copy does NOT
# satisfy the pre-red-gate contract `^- override: [^ ]` (a placeholder value like
# '- override: [BLOCK...]' would forge the evidence check). The evidence-requirement
# description must live in fence-EXTERNAL prose. The '厳密形式' note and the nested
# review_attempts '- {started:' form must remain intact.
echo ""
echo "TC-65: spec templates have value-less '- override:' in fence (no gate-regex match) + 実証跡 note in prose + 厳密形式 + nested '- {started:' intact (both langs)"
SPEC_EN="$BASE_DIR/skills/spec/reference.md"
SPEC_JA="$BASE_DIR/skills/spec/reference.ja.md"
# printf oracle: prove the gate regex the template must respect. A value-less override
# must NOT match; a filled override (real evidence) must match.
oracle_empty=$(printf '%s\n' '- override:' | grep -cE '^- override: [^ ]' || true)
oracle_filled=$(printf '%s\n' '- override: 2026-01-01 human approval via ExitPlanMode' | grep -cE '^- override: [^ ]' || true)
if [ ! -f "$SPEC_EN" ]; then
  fail "TC-65: skills/spec/reference.md does not exist"
elif [ ! -f "$SPEC_JA" ]; then
  fail "TC-65: skills/spec/reference.ja.md does not exist"
elif [ "$oracle_empty" -ne 0 ] || [ "$oracle_filled" -ne 1 ]; then
  fail "TC-65: gate-regex printf oracle broken (empty=$oracle_empty expect 0, filled=$oracle_filled expect 1)"
else
  en_ovr=$(plan_template_fence_override "$SPEC_EN")
  ja_ovr=$(plan_template_fence_override "$SPEC_JA")
  en_has=$(printf '%s\n' "$en_ovr" | grep -cF -- '- override:' || true)
  ja_has=$(printf '%s\n' "$ja_ovr" | grep -cF -- '- override:' || true)
  en_forge=$(printf '%s\n' "$en_ovr" | grep -cE '^- override: [^ ]' || true)
  ja_forge=$(printf '%s\n' "$ja_ovr" | grep -cE '^- override: [^ ]' || true)
  en_ev=$(plan_template_prose "$SPEC_EN" "実証跡")
  ja_ev=$(plan_template_prose "$SPEC_JA" "実証跡")
  en_strict=$(plan_template_grep "$SPEC_EN" "厳密形式")
  ja_strict=$(plan_template_grep "$SPEC_JA" "厳密形式")
  en_nested=$(plan_template_grep "$SPEC_EN" "- {started:")
  ja_nested=$(plan_template_grep "$SPEC_JA" "- {started:")
  if [ "$en_has" -ge 1 ] && [ "$ja_has" -ge 1 ] \
     && [ "$en_forge" -eq 0 ] && [ "$ja_forge" -eq 0 ] \
     && [ "$en_ev" -ge 1 ] && [ "$ja_ev" -ge 1 ] \
     && [ "$en_strict" -ge 1 ] && [ "$ja_strict" -ge 1 ] \
     && [ "$en_nested" -ge 1 ] && [ "$ja_nested" -ge 1 ]; then
    pass "TC-65: value-less override in fence (no forgery match) + 実証跡 prose note + 厳密形式 + nested review_attempts intact (both langs)"
  elif [ "$en_has" -lt 1 ] || [ "$ja_has" -lt 1 ]; then
    fail "TC-65: fenced '- override:' field line missing (en=$en_has ja=$ja_has)"
  elif [ "$en_forge" -ne 0 ] || [ "$ja_forge" -ne 0 ]; then
    fail "TC-65: fenced '- override:' carries a value → template copy forges gate regex '^- override: [^ ]' (en=$en_forge ja=$ja_forge); keep the template field value-less"
  elif [ "$en_ev" -lt 1 ] || [ "$ja_ev" -lt 1 ]; then
    fail "TC-65: fence-external prose missing '実証跡' evidence-requirement note (en=$en_ev ja=$ja_ev)"
  elif [ "$en_strict" -lt 1 ] || [ "$ja_strict" -lt 1 ]; then
    fail "TC-65: Plan File Template missing '厳密形式' note (en=$en_strict ja=$ja_strict)"
  else
    fail "TC-65: Plan File Template nested review_attempts '- {started:' not intact (en=$en_nested ja=$ja_nested)"
  fi
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
