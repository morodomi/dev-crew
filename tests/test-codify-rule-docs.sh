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

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
