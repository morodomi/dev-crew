#!/bin/bash
# test-rules-path-scoping.sh - rules path-scoping frontmatter tests
# TC-01 to TC-04: file-scoped rules / TC-05 to TC-11: cycle-scoped rules + load-tier contracts

set -uo pipefail

BASE_DIR="${BASE_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

RULES_DIR="$BASE_DIR/rules"
CLAUDE_RULES_DIR="$BASE_DIR/.claude/rules"

echo "=== rules path-scoping Tests (20260625_1101) ==="

# Helper: extract frontmatter body (between first and second --- delimiters)
# Usage: frontmatter_of <file>
# Anchored to line 1: frontmatter MUST open with ^---$ on the very first line
# (Claude Code rules contract). A heading or any content before --- yields empty
# output, preventing false-pass when frontmatter is not at the top.
frontmatter_of() {
  awk 'NR==1{if($0!="---") exit} NR>1 && /^---$/{exit} NR>1{print}' "$1"
}

# TC-01: rules/test-patterns.md frontmatter has paths: containing tests/**
# Given: rules/test-patterns.md is a rule file scheduled for path-scoping
# When:  awk extracts content between the two --- delimiters (frontmatter range)
# Then:  the extracted text contains "tests/**"
echo ""
echo "TC-01: rules/test-patterns.md frontmatter has paths: with tests/**"
FILE="$RULES_DIR/test-patterns.md"
if [ ! -f "$FILE" ]; then
  fail "TC-01: rules/test-patterns.md does not exist"
else
  # awk frontmatter scan — body content must NOT be searched (whole-file grep禁止)
  fm_output=$(frontmatter_of "$FILE" 2>&1 || true)
  has_paths=$(echo "$fm_output" | grep -cF "paths:" || true)
  has_glob=$(echo "$fm_output" | grep -cF "tests/**" || true)
  if [ "$has_paths" -ge 1 ] && [ "$has_glob" -ge 1 ]; then
    pass "TC-01: rules/test-patterns.md frontmatter has paths: with tests/**"
  elif [ "$has_paths" -lt 1 ]; then
    fail "TC-01: rules/test-patterns.md frontmatter missing 'paths:' key (frontmatter not added yet?)"
  else
    fail "TC-01: rules/test-patterns.md frontmatter has paths: but missing 'tests/**' value"
  fi
fi

# TC-02: rules/skill-authoring.md frontmatter has paths: containing skills/**
# Given: rules/skill-authoring.md is a rule file scheduled for path-scoping
# When:  awk extracts content between the two --- delimiters (frontmatter range)
# Then:  the extracted text contains "skills/**"
echo ""
echo "TC-02: rules/skill-authoring.md frontmatter has paths: with skills/**"
FILE="$RULES_DIR/skill-authoring.md"
if [ ! -f "$FILE" ]; then
  fail "TC-02: rules/skill-authoring.md does not exist"
else
  fm_output=$(frontmatter_of "$FILE" 2>&1 || true)
  has_paths=$(echo "$fm_output" | grep -cF "paths:" || true)
  has_glob=$(echo "$fm_output" | grep -cF "skills/**" || true)
  if [ "$has_paths" -ge 1 ] && [ "$has_glob" -ge 1 ]; then
    pass "TC-02: rules/skill-authoring.md frontmatter has paths: with skills/**"
  elif [ "$has_paths" -lt 1 ]; then
    fail "TC-02: rules/skill-authoring.md frontmatter missing 'paths:' key (frontmatter not added yet?)"
  else
    fail "TC-02: rules/skill-authoring.md frontmatter has paths: but missing 'skills/**' value"
  fi
fi

# TC-03: Both canonical files have exactly 2 --- delimiters (balanced open/close frontmatter)
# Given: frontmatter requires exactly one opening --- and one closing --- line
# When:  grep -cE '^---$' counts ^---$ lines in each file
# Then:  count == 2 for both rules/test-patterns.md and rules/skill-authoring.md
echo ""
echo "TC-03: Both canonical files have exactly 2 '---' delimiters (balanced frontmatter)"
TC03_PASS=true
for fname in "test-patterns.md" "skill-authoring.md"; do
  fpath="$RULES_DIR/$fname"
  if [ ! -f "$fpath" ]; then
    fail "TC-03: rules/$fname does not exist"
    TC03_PASS=false
    continue
  fi
  # count is obtained once — no || fallback concatenation (test-patterns.md #4禁止事項準拠)
  delim_count=$(grep -cE '^---$' "$fpath" || true)
  if [ "$delim_count" -eq 2 ]; then
    : # ok
  else
    fail "TC-03: rules/$fname has $delim_count '---' delimiter(s), expected exactly 2"
    TC03_PASS=false
  fi
done
if [ "$TC03_PASS" = "true" ]; then
  pass "TC-03: Both canonical files have exactly 2 '---' delimiters"
fi

# TC-04: .claude/rules/ mirror files are byte-identical to canonical rules/
# Given: mirror invariant requires byte-identical content between rules/ and .claude/rules/
# When:  line-1 frontmatter presence is asserted (RED guard) AND full-file diff is run
# Then:  frontmatter present AND diff empty for both pairs (catches body drift, not just frontmatter)
echo ""
echo "TC-04: .claude/rules/ mirror files are byte-identical to canonical (full-file diff)"
TC04_PASS=true
for fname in "test-patterns.md" "skill-authoring.md"; do
  canonical="$RULES_DIR/$fname"
  mirror="$CLAUDE_RULES_DIR/$fname"
  if [ ! -f "$canonical" ]; then
    fail "TC-04: canonical rules/$fname does not exist"
    TC04_PASS=false
    continue
  fi
  if [ ! -f "$mirror" ]; then
    fail "TC-04: mirror .claude/rules/$fname does not exist"
    TC04_PASS=false
    continue
  fi
  # RED guard: require line-1 frontmatter present (fails before GREEN adds it)
  fm_canonical=$(frontmatter_of "$canonical" 2>&1 || true)
  if [ -z "$fm_canonical" ]; then
    fail "TC-04: rules/$fname has no line-1 frontmatter (mirror+presence cannot be verified)"
    TC04_PASS=false
  # Full-file byte comparison — catches body drift, not only frontmatter divergence
  elif diff -q "$canonical" "$mirror" >/dev/null 2>&1; then
    : # ok — canonical and mirror are byte-identical (frontmatter + body)
  else
    fail "TC-04: .claude/rules/$fname differs from rules/$fname (full-file mirror drift)"
    TC04_PASS=false
  fi
done
if [ "$TC04_PASS" = "true" ]; then
  pass "TC-04: All mirror files are byte-identical to their canonical counterpart"
fi

# TC-05: cycle-scoped rules have line-1 frontmatter for docs/cycles/**
# Given: seven workflow rules are classified as cycle-scoped
# When:  line-1 frontmatter and delimiter counts are inspected
# Then:  each file has paths: docs/cycles/** and exactly two delimiters
echo ""
echo "TC-05: Seven cycle-scoped rules have anchored docs/cycles/** frontmatter"
TC05_PASS=true
TC05_MISSING=""
for fname in \
  "plan-discipline.md" \
  "review-triage.md" \
  "integration-verification.md" \
  "agent-prompts.md" \
  "multi-file-consistency.md" \
  "doc-mutations.md" \
  "state-ownership.md"; do
  fpath="$RULES_DIR/$fname"
  if [ ! -f "$fpath" ]; then
    TC05_PASS=false
    TC05_MISSING="$TC05_MISSING rules/$fname(missing)"
    continue
  fi
  fm_output=$(frontmatter_of "$fpath" 2>&1 || true)
  delim_count=$(grep -cE '^---$' "$fpath" || true)
  has_paths=$(echo "$fm_output" | grep -cF "paths:" || true)
  has_glob=$(echo "$fm_output" | grep -cF "docs/cycles/**" || true)
  if [ "$delim_count" -ne 2 ] || [ "$has_paths" -lt 1 ] || [ "$has_glob" -lt 1 ]; then
    TC05_PASS=false
    TC05_MISSING="$TC05_MISSING rules/$fname"
  fi
done
if [ "$TC05_PASS" = "true" ]; then
  pass "TC-05: All seven cycle-scoped rules have anchored docs/cycles/** frontmatter"
else
  fail "TC-05: Invalid cycle-scoped frontmatter:$TC05_MISSING"
fi

# TC-06: cycle-scoped canonical rules and mirrors are byte-identical
# Given: seven cycle-scoped rules have canonical and mirror copies
# When:  each complete file pair is compared
# Then:  all seven pairs are byte-identical
echo ""
echo "TC-06: Seven cycle-scoped rule mirrors are byte-identical"
TC06_PASS=true
TC06_DRIFT=""
for fname in \
  "plan-discipline.md" \
  "review-triage.md" \
  "integration-verification.md" \
  "agent-prompts.md" \
  "multi-file-consistency.md" \
  "doc-mutations.md" \
  "state-ownership.md"; do
  canonical="$RULES_DIR/$fname"
  mirror="$CLAUDE_RULES_DIR/$fname"
  if [ ! -f "$canonical" ] || [ ! -f "$mirror" ]; then
    TC06_PASS=false
    TC06_DRIFT="$TC06_DRIFT $fname"
    continue
  fi
  fm_canonical=$(frontmatter_of "$canonical" 2>&1 || true)
  if [ -z "$fm_canonical" ] || ! diff -q "$canonical" "$mirror" >/dev/null 2>&1; then
    TC06_PASS=false
    TC06_DRIFT="$TC06_DRIFT $fname"
  fi
done
if [ "$TC06_PASS" = "true" ]; then
  pass "TC-06: All seven cycle-scoped mirrors are byte-identical"
else
  fail "TC-06: Missing or non-identical mirror pairs:$TC06_DRIFT"
fi

# TC-07: the always-loaded layer stays within its frozen line budgets
# Given: rule files without paths: frontmatter belong to the always-loaded layer
# When:  their line counts are summed independently in canonical and mirror trees
# Then:  canonical total is <=76 and mirror total is <=103
echo ""
echo "TC-07: Always-loaded rule layer stays within frozen line budgets"
canonical_always_lines=0
for fpath in "$RULES_DIR"/*.md; do
  fm_output=$(frontmatter_of "$fpath" 2>&1 || true)
  has_paths=$(echo "$fm_output" | grep -cF "paths:" || true)
  if [ "$has_paths" -eq 0 ]; then
    line_count=$(wc -l < "$fpath" | tr -d ' ')
    canonical_always_lines=$((canonical_always_lines + line_count))
  fi
done
mirror_always_lines=0
for fpath in "$CLAUDE_RULES_DIR"/*.md; do
  fm_output=$(frontmatter_of "$fpath" 2>&1 || true)
  has_paths=$(echo "$fm_output" | grep -cF "paths:" || true)
  if [ "$has_paths" -eq 0 ]; then
    line_count=$(wc -l < "$fpath" | tr -d ' ')
    mirror_always_lines=$((mirror_always_lines + line_count))
  fi
done
if [ "$canonical_always_lines" -le 76 ] && [ "$mirror_always_lines" -le 103 ]; then
  pass "TC-07: Always-loaded totals are canonical=$canonical_always_lines mirror=$mirror_always_lines"
else
  fail "TC-07: Always-loaded totals exceed budgets: canonical=$canonical_always_lines/76 mirror=$mirror_always_lines/103"
fi

# TC-08: spec explicitly reads plan-discipline before planning and stays compact
# Given: skills/spec/SKILL.md is the pre-cycle planning entry point
# When:  its instructions and total line count are inspected
# Then:  an explicit plan-discipline Read exists and the file is <=100 lines
echo ""
echo "TC-08: spec explicitly Reads plan-discipline and stays within 100 lines"
SPEC_SKILL="$BASE_DIR/skills/spec/SKILL.md"
spec_lines=$(wc -l < "$SPEC_SKILL" | tr -d ' ')
spec_read_count=$(grep -Ei '\.claude/rules/plan-discipline\.md.*(Read|読む|読み)' "$SPEC_SKILL" | wc -l | tr -d ' ')
if [ "$spec_read_count" -ge 1 ] && [ "$spec_lines" -le 100 ]; then
  pass "TC-08: spec has an explicit plan-discipline Read and is $spec_lines lines"
elif [ "$spec_read_count" -lt 1 ]; then
  fail "TC-08: skills/spec/SKILL.md lacks an explicit plan-discipline Read"
else
  fail "TC-08: skills/spec/SKILL.md has $spec_lines lines, expected <=100"
fi

# TC-09: all orchestrate mode documents explicitly reference agent-prompts
# Given: Codex, subagent, and teams modes construct agent prompts
# When:  each mode document is searched for agent-prompts
# Then:  all three documents contain the reference
echo ""
echo "TC-09: All orchestrate mode documents reference agent-prompts"
TC09_PASS=true
TC09_MISSING=""
for relpath in \
  "skills/orchestrate/steps-codex.md" \
  "skills/orchestrate/steps-subagent.md" \
  "skills/orchestrate/steps-teams.md"; do
  if ! grep -qF "agent-prompts" "$BASE_DIR/$relpath"; then
    TC09_PASS=false
    TC09_MISSING="$TC09_MISSING $relpath"
  fi
done
if [ "$TC09_PASS" = "true" ]; then
  pass "TC-09: All three orchestrate mode documents reference agent-prompts"
else
  fail "TC-09: Missing agent-prompts reference:$TC09_MISSING"
fi

# TC-10: codify-insight documents define executable rule-tier contracts
# Given: codify-insight records decisions without changing canonical enums
# When:  SKILL.md and reference.md are inspected for the tier specification
# Then:  tier values, scoping clauses, examples, and existing enums are present
echo ""
echo "TC-10: codify-insight documents define the complete rule-tier contract"
CODIFY_SKILL="$BASE_DIR/skills/codify-insight/SKILL.md"
CODIFY_REFERENCE="$BASE_DIR/skills/codify-insight/reference.md"
CODIFY_DOCS="$CODIFY_SKILL $CODIFY_REFERENCE"
has_always=$(grep -hF "always" $CODIFY_DOCS | wc -l | tr -d ' ')
has_cycle_scoped=$(grep -hF "cycle-scoped" $CODIFY_DOCS | wc -l | tr -d ' ')
has_file_scoped=$(grep -hF "file-scoped" $CODIFY_DOCS | wc -l | tr -d ' ')
has_file_paths_clause=$(grep -hEi 'file-scoped.*paths.*(必須|required)' $CODIFY_DOCS | wc -l | tr -d ' ')
has_always_exchange=$(grep -hEi 'always.*(交換|置換|統合|削減).*(条件|必須|required)' $CODIFY_DOCS | wc -l | tr -d ' ')
has_positive_example=$(grep -Ei '(正例|good example|valid example)' "$CODIFY_REFERENCE" | wc -l | tr -d ' ')
has_negative_example=$(grep -Ei '(不正例|bad example|invalid example)' "$CODIFY_REFERENCE" | wc -l | tr -d ' ')
has_missing_tier_invalid=$(grep -Ei 'tier.*(無指定|未指定|missing).*(不正|invalid)' "$CODIFY_REFERENCE" | wc -l | tr -d ' ')
has_decision_markers=true
for marker in "codified" "deferred" "no-codify"; do
  if ! grep -qF "$marker" "$CODIFY_REFERENCE"; then
    has_decision_markers=false
  fi
done
has_destinations=true
for destination in "rule" "skill" "instinct" "new-cycle" "inline-update"; do
  if ! grep -qF "$destination" "$CODIFY_REFERENCE"; then
    has_destinations=false
  fi
done
if [ "$has_always" -ge 1 ] \
  && [ "$has_cycle_scoped" -ge 1 ] \
  && [ "$has_file_scoped" -ge 1 ] \
  && [ "$has_file_paths_clause" -ge 1 ] \
  && [ "$has_always_exchange" -ge 1 ] \
  && [ "$has_positive_example" -ge 1 ] \
  && [ "$has_negative_example" -ge 1 ] \
  && [ "$has_missing_tier_invalid" -ge 1 ] \
  && [ "$has_decision_markers" = "true" ] \
  && [ "$has_destinations" = "true" ]; then
  pass "TC-10: codify-insight rule-tier contract and canonical enums are complete"
else
  fail "TC-10: codify-insight rule-tier contract is incomplete"
fi

# TC-11: every production phase entry path explicitly reads the Cycle doc
# Given: nine agent, skill, and orchestrate production entry documents
# When:  each file is searched for a Cycle doc Read instruction
# Then:  all nine files contain an explicit Read, read, or confirmation instruction
echo ""
echo "TC-11: All production phase entry paths explicitly Read the Cycle doc"
TC11_PASS=true
TC11_MISSING=""
for relpath in \
  "agents/red-worker.md" \
  "agents/green-worker.md" \
  "skills/refactor/SKILL.md" \
  "skills/review/SKILL.md" \
  "skills/commit/SKILL.md" \
  "skills/cycle-retrospective/SKILL.md" \
  "skills/orchestrate/steps-codex.md" \
  "skills/orchestrate/steps-subagent.md" \
  "skills/orchestrate/steps-teams.md"; do
  read_count=$(grep -Ei 'Cycle doc.*(Read|読む|読み|確認)' "$BASE_DIR/$relpath" | wc -l | tr -d ' ')
  if [ "$read_count" -lt 1 ]; then
    TC11_PASS=false
    TC11_MISSING="$TC11_MISSING $relpath"
  fi
done
if [ "$TC11_PASS" = "true" ]; then
  pass "TC-11: All nine production phase entry paths explicitly Read the Cycle doc"
else
  fail "TC-11: Missing Cycle doc Read instruction:$TC11_MISSING"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
