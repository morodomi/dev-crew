#!/bin/bash
# test-codify-insight.sh - codify-insight skill structure tests
# TC-01 to TC-20 for v2.7 Agile Loop Cycle B

set -uo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

SKILL_MD="$BASE_DIR/skills/codify-insight/SKILL.md"
REFERENCE_MD="$BASE_DIR/skills/codify-insight/reference.md"
STATE_OWNERSHIP="$BASE_DIR/rules/state-ownership.md"
ORCHESTRATE_SKILL_MD="$BASE_DIR/skills/orchestrate/SKILL.md"
STEPS_SUBAGENT_MD="$BASE_DIR/skills/orchestrate/steps-subagent.md"
STEPS_TEAMS_MD="$BASE_DIR/skills/orchestrate/steps-teams.md"
README_MD="$BASE_DIR/README.md"
AGENTS_MD="$BASE_DIR/AGENTS.md"
CLAUDE_MD="$BASE_DIR/CLAUDE.md"
STATUS_MD="$BASE_DIR/docs/STATUS.md"
RETRO_TEST="$BASE_DIR/tests/test-cycle-retrospective.sh"
FRONTMATTER_VALIDATOR="$BASE_DIR/scripts/validate-yaml-frontmatter.sh"

echo "=== codify-insight Skill Structure Tests (v2.7 Cycle B) ==="

# TC-01: SKILL.md frontmatter valid (via validate-yaml-frontmatter.sh)
echo ""
echo "TC-01: SKILL.md frontmatter validation via validate-yaml-frontmatter.sh"
if [ ! -f "$SKILL_MD" ]; then
  fail "TC-01: skills/codify-insight/SKILL.md does not exist"
elif ! bash "$FRONTMATTER_VALIDATOR" "$SKILL_MD" 2>/dev/null; then
  fail "TC-01: SKILL.md frontmatter is invalid (validate-yaml-frontmatter.sh returned non-zero)"
else
  pass "TC-01: SKILL.md frontmatter is valid"
fi

# TC-02: SKILL.md line count <= 100
echo ""
echo "TC-02: SKILL.md line count <= 100"
if [ ! -f "$SKILL_MD" ]; then
  fail "TC-02: skills/codify-insight/SKILL.md does not exist"
else
  line_count=$(wc -l < "$SKILL_MD" | tr -d ' ')
  if [ "$line_count" -le 100 ]; then
    pass "TC-02: SKILL.md has $line_count lines (<= 100)"
  else
    fail "TC-02: SKILL.md has $line_count lines (> 100, hard limit exceeded)"
  fi
fi

# TC-03: SKILL.md allowed-tools contains Read, Edit, AskUserQuestion, Glob
echo ""
echo "TC-03: SKILL.md allowed-tools contains Read, Edit, AskUserQuestion, Glob"
if [ ! -f "$SKILL_MD" ]; then
  fail "TC-03: skills/codify-insight/SKILL.md does not exist"
else
  TC03_PASS=true
  for tool in Read Edit AskUserQuestion Glob; do
    if ! grep -q "$tool" "$SKILL_MD"; then
      fail "TC-03: SKILL.md allowed-tools does NOT contain '$tool'"
      TC03_PASS=false
    fi
  done
  if [ "$TC03_PASS" = "true" ]; then
    pass "TC-03: SKILL.md allowed-tools contains Read, Edit, AskUserQuestion, Glob"
  fi
fi

# TC-04: SKILL.md description contains "codify-insight", "codify", or "decide gate"
echo ""
echo "TC-04: SKILL.md description contains trigger keyword (codify-insight / codify / decide gate)"
if [ ! -f "$SKILL_MD" ]; then
  fail "TC-04: skills/codify-insight/SKILL.md does not exist"
else
  desc_line=$(awk '/^---$/{n++; next} n==1 && /^description:/{print; exit} n==2{exit}' "$SKILL_MD" || true)
  if echo "$desc_line" | grep -qiE "codify-insight|codify|decide gate"; then
    pass "TC-04: SKILL.md description contains trigger keyword"
  else
    fail "TC-04: SKILL.md description does NOT contain 'codify-insight', 'codify', or 'decide gate' (line: '$desc_line')"
  fi
fi

# TC-05: SKILL.md workflow contains frontmatter-only awk pattern (positive)
#        AND does NOT contain bare grep -l / grep -rl 'retro_status: captured' (negative)
echo ""
echo "TC-05: SKILL.md frontmatter-only awk pattern (positive) + no bare grep pattern (negative)"
if [ ! -f "$SKILL_MD" ]; then
  fail "TC-05: skills/codify-insight/SKILL.md does not exist"
else
  AWK_PATTERN="awk '/^\-\-\-\$/{c++;next} c==1{print}'"
  # Check positive: awk frontmatter-only scan pattern present
  if grep -qF "awk '/^---\$/{c++;next} c==1{print}'" "$SKILL_MD"; then
    TC05_POSITIVE=true
  else
    TC05_POSITIVE=false
  fi
  # Check negative: bare grep -l or grep -rl 'retro_status: captured' must NOT be present
  if grep -qE "grep -l 'retro_status: captured'|grep -rl 'retro_status: captured'" "$SKILL_MD"; then
    TC05_NEGATIVE=false
  else
    TC05_NEGATIVE=true
  fi
  if [ "$TC05_POSITIVE" = "true" ] && [ "$TC05_NEGATIVE" = "true" ]; then
    pass "TC-05: SKILL.md has frontmatter-only awk pattern and no bare grep pattern"
  elif [ "$TC05_POSITIVE" = "false" ]; then
    fail "TC-05: SKILL.md does NOT contain frontmatter-only awk pattern"
  else
    fail "TC-05: SKILL.md contains bare grep 'retro_status: captured' (self-trigger risk)"
  fi
fi

# TC-06: reference.md contains verbatim 3-option strings: "codify now", "defer with reason", "no-codify"
#        AND documents they are fallback-only (not default per-insight interaction)
echo ""
echo "TC-06: reference.md contains 3-option strings and marks them fallback-only"
if [ ! -f "$REFERENCE_MD" ]; then
  fail "TC-06: skills/codify-insight/reference.md does not exist"
else
  TC06_PASS=true
  for option in "codify now" "defer with reason" "no-codify"; do
    if ! grep -qF "$option" "$REFERENCE_MD"; then
      fail "TC-06: reference.md missing verbatim option string: '$option'"
      TC06_PASS=false
    fi
  done
  has_fallback_only=$(grep -iE "fallback only|fallback のみ|default.*autonomous|autonomous.*default" "$REFERENCE_MD" || true)
  if [ "$TC06_PASS" = "true" ] && [ -n "$has_fallback_only" ]; then
    pass "TC-06: reference.md contains 3 options and marks them fallback-only"
  elif [ "$TC06_PASS" = "true" ]; then
    fail "TC-06: reference.md contains 3 options but does NOT mark them as fallback-only/autonomous default"
  fi
fi

# TC-07: reference.md states defer requires reason, no-codify reason is optional,
#        and AskUserQuestion is batched only for skill/low-confidence cases
echo ""
echo "TC-07: reference.md documents defer/no-codify reason contract + batch escalation"
if [ ! -f "$REFERENCE_MD" ]; then
  fail "TC-07: skills/codify-insight/reference.md does not exist"
else
  has_defer_required=$(grep -iE "defer.*(reason|required|必須)" "$REFERENCE_MD" || true)
  has_nocodify_optional=$(grep -iE "no-codify.*(optional|任意)|no-codify.*reason.*(optional|任意)" "$REFERENCE_MD" || true)
  has_batch_escalation=$(grep -iE "1 cycle.*1 回|once per cycle|skill.*candidate|low confidence|low-confidence" "$REFERENCE_MD" || true)
  if [ -n "$has_defer_required" ] && [ -n "$has_nocodify_optional" ] && [ -n "$has_batch_escalation" ]; then
    pass "TC-07: reference.md documents reason contract and batch escalation policy"
  else
    if [ -z "$has_defer_required" ]; then
      fail "TC-07: reference.md does NOT state defer requires reason"
    elif [ -z "$has_nocodify_optional" ]; then
      fail "TC-07: reference.md does NOT state no-codify reason is optional"
    else
      fail "TC-07: reference.md does NOT document batch escalation for skill/low-confidence cases"
    fi
  fi
fi

# TC-08: SKILL.md documents skip for both retro_status: resolved AND retro_status: none
echo ""
echo "TC-08: SKILL.md documents skip for both retro_status: resolved and retro_status: none"
if [ ! -f "$SKILL_MD" ]; then
  fail "TC-08: skills/codify-insight/SKILL.md does not exist"
else
  has_resolved=$(grep -F "retro_status: resolved" "$SKILL_MD" || true)
  has_none=$(grep -F "retro_status: none" "$SKILL_MD" || true)
  has_skip=$(grep -iE "skip|スキップ" "$SKILL_MD" || true)
  if [ -n "$has_resolved" ] && [ -n "$has_none" ] && [ -n "$has_skip" ]; then
    pass "TC-08: SKILL.md documents skip for retro_status: resolved and none"
  else
    if [ -z "$has_resolved" ]; then
      fail "TC-08: SKILL.md does NOT mention retro_status: resolved skip"
    elif [ -z "$has_none" ]; then
      fail "TC-08: SKILL.md does NOT mention retro_status: none skip"
    else
      fail "TC-08: SKILL.md does NOT document skip behavior"
    fi
  fi
fi

# TC-09: reference.md documents "no captured cycles found → no-op exit 0" message
echo ""
echo "TC-09: reference.md documents 'no captured cycles found → no-op exit 0'"
if [ ! -f "$REFERENCE_MD" ]; then
  fail "TC-09: skills/codify-insight/reference.md does not exist"
else
  has_no_captured=$(grep -iE "no captured|captured.*not found|captured.*なし|captured.*ない" "$REFERENCE_MD" || true)
  has_exit0=$(grep -iE "exit 0|no-op" "$REFERENCE_MD" || true)
  if [ -n "$has_no_captured" ] && [ -n "$has_exit0" ]; then
    pass "TC-09: reference.md documents no captured cycles → no-op exit 0"
  else
    if [ -z "$has_no_captured" ]; then
      fail "TC-09: reference.md does NOT document 'no captured cycles found' case"
    else
      fail "TC-09: reference.md does NOT document exit 0 / no-op behavior for no captured cycles"
    fi
  fi
fi

# TC-10: reference.md documents "## Codify Decisions" EOF section append (NOT per-insight inline)
echo ""
echo "TC-10: reference.md documents '## Codify Decisions' EOF section append (not per-insight inline)"
if [ ! -f "$REFERENCE_MD" ]; then
  fail "TC-10: skills/codify-insight/reference.md does not exist"
else
  has_codify_decisions=$(grep -F "## Codify Decisions" "$REFERENCE_MD" || true)
  has_eof_append=$(grep -iE "EOF|末尾|append.*section|section.*append" "$REFERENCE_MD" || true)
  if [ -n "$has_codify_decisions" ] && [ -n "$has_eof_append" ]; then
    pass "TC-10: reference.md documents '## Codify Decisions' EOF section append"
  else
    if [ -z "$has_codify_decisions" ]; then
      fail "TC-10: reference.md does NOT mention '## Codify Decisions' section"
    else
      fail "TC-10: reference.md does NOT document EOF/末尾 append approach"
    fi
  fi
fi

# TC-11: reference.md states APPEND-ONLY contract
#        (existing Retrospective unchanged, Codify Decisions is new EOF section)
echo ""
echo "TC-11: reference.md states APPEND-ONLY contract (Retrospective unchanged, Codify Decisions is new EOF section)"
if [ ! -f "$REFERENCE_MD" ]; then
  fail "TC-11: skills/codify-insight/reference.md does not exist"
else
  has_append_only=$(grep -iE "APPEND.ONLY|append only|追記のみ" "$REFERENCE_MD" || true)
  has_retro_unchanged=$(grep -iE "Retrospective.*不変|不変.*Retrospective|existing.*unchanged|unchanged.*existing|Retrospective.*変更しない" "$REFERENCE_MD" || true)
  if [ -n "$has_append_only" ] && [ -n "$has_retro_unchanged" ]; then
    pass "TC-11: reference.md states APPEND-ONLY contract with existing Retrospective unchanged"
  else
    if [ -z "$has_append_only" ]; then
      fail "TC-11: reference.md does NOT state APPEND-ONLY contract"
    else
      fail "TC-11: reference.md does NOT state existing Retrospective section is unchanged"
    fi
  fi
fi

# TC-12: reference.md states retro_status transition trigger is "all insights judged"
echo ""
echo "TC-12: reference.md states captured→resolved transition triggered by 'all insights judged'"
if [ ! -f "$REFERENCE_MD" ]; then
  fail "TC-12: skills/codify-insight/reference.md does not exist"
else
  has_transition=$(grep -iE "captured.*resolved|resolved.*遷移|captured → resolved" "$REFERENCE_MD" || true)
  has_all_judged=$(grep -iE "all.*judg|全.*判断|全.*insight|insight.*全|すべて.*判断" "$REFERENCE_MD" || true)
  if [ -n "$has_transition" ] && [ -n "$has_all_judged" ]; then
    pass "TC-12: reference.md states captured→resolved transition requires all insights judged"
  else
    if [ -z "$has_transition" ]; then
      fail "TC-12: reference.md does NOT mention captured→resolved transition"
    else
      fail "TC-12: reference.md does NOT state 'all insights judged' as transition trigger"
    fi
  fi
fi

# TC-13: reference.md contains fixed decision markers: codified, deferred, no-codify
echo ""
echo "TC-13: reference.md contains fixed decision markers (codified / deferred / no-codify)"
if [ ! -f "$REFERENCE_MD" ]; then
  fail "TC-13: skills/codify-insight/reference.md does not exist"
else
  TC13_PASS=true
  for marker in "codified" "deferred" "no-codify"; do
    if ! grep -qF "$marker" "$REFERENCE_MD"; then
      fail "TC-13: reference.md missing canonical decision marker: '$marker'"
      TC13_PASS=false
    fi
  done
  if [ "$TC13_PASS" = "true" ]; then
    pass "TC-13: reference.md contains all 3 canonical decision markers"
  fi
fi

# TC-14: rules/state-ownership.md contains codify-insight row
#        with retro_status (captured → resolved) + updated + body section append
echo ""
echo "TC-14: state-ownership.md contains codify-insight row (retro_status + updated + body section append)"
if [ ! -f "$STATE_OWNERSHIP" ]; then
  fail "TC-14: rules/state-ownership.md does not exist"
else
  codify_line=$(grep "codify-insight" "$STATE_OWNERSHIP" || true)
  if [ -z "$codify_line" ]; then
    fail "TC-14: state-ownership.md does NOT contain codify-insight row"
  else
    has_retro=$(echo "$codify_line" | grep -q "retro_status" && echo "yes" || echo "no")
    has_resolved=$(echo "$codify_line" | grep -qE "captured.*resolved|resolved" && echo "yes" || echo "no")
    has_updated=$(echo "$codify_line" | grep -q "updated" && echo "yes" || echo "no")
    if [ "$has_retro" = "yes" ] && [ "$has_resolved" = "yes" ] && [ "$has_updated" = "yes" ]; then
      pass "TC-14: state-ownership.md has codify-insight row with retro_status + updated"
    else
      fail "TC-14: state-ownership.md codify-insight row incomplete (retro_status=$has_retro, resolved=$has_resolved, updated=$has_updated) — line: '$codify_line'"
    fi
  fi
fi

# TC-15: skills/orchestrate/SKILL.md Block 0 contains codify gate + frontmatter-only awk pattern
echo ""
echo "TC-15: orchestrate/SKILL.md Block 0 contains codify gate + frontmatter-only awk pattern"
if [ ! -f "$ORCHESTRATE_SKILL_MD" ]; then
  fail "TC-15: skills/orchestrate/SKILL.md does not exist"
else
  has_codify_gate=$(grep -iE "codify|codify-insight" "$ORCHESTRATE_SKILL_MD" || true)
  has_awk_pattern=$(grep -qF "awk '/^---\$/{c++;next} c==1{print}'" "$ORCHESTRATE_SKILL_MD" && echo "yes" || echo "no")
  if [ -n "$has_codify_gate" ] && [ "$has_awk_pattern" = "yes" ]; then
    pass "TC-15: orchestrate/SKILL.md Block 0 contains codify gate and frontmatter-only awk pattern"
  else
    if [ -z "$has_codify_gate" ]; then
      fail "TC-15: orchestrate/SKILL.md does NOT mention codify gate"
    else
      fail "TC-15: orchestrate/SKILL.md does NOT contain frontmatter-only awk pattern"
    fi
  fi
fi

# TC-16: steps-subagent.md Block 0 contains codify gate + awk pattern (positive)
#        AND does NOT contain bare grep -l 'retro_status: captured' (negative)
echo ""
echo "TC-16: steps-subagent.md Block 0 codify gate (positive) + no bare grep pattern (negative)"
if [ ! -f "$STEPS_SUBAGENT_MD" ]; then
  fail "TC-16: skills/orchestrate/steps-subagent.md does not exist"
else
  has_codify=$(grep -iE "codify|codify-insight" "$STEPS_SUBAGENT_MD" || true)
  has_awk=$(grep -qF "awk '/^---\$/{c++;next} c==1{print}'" "$STEPS_SUBAGENT_MD" && echo "yes" || echo "no")
  has_bare_grep=$(grep -qE "grep -l 'retro_status: captured'|grep -rl 'retro_status: captured'" "$STEPS_SUBAGENT_MD" && echo "yes" || echo "no")
  if [ -n "$has_codify" ] && [ "$has_awk" = "yes" ] && [ "$has_bare_grep" = "no" ]; then
    pass "TC-16: steps-subagent.md has codify gate + awk pattern and no bare grep"
  elif [ -z "$has_codify" ]; then
    fail "TC-16: steps-subagent.md does NOT contain codify gate"
  elif [ "$has_awk" = "no" ]; then
    fail "TC-16: steps-subagent.md does NOT contain frontmatter-only awk pattern"
  else
    fail "TC-16: steps-subagent.md contains bare grep 'retro_status: captured' (self-trigger risk)"
  fi
fi

# TC-17: steps-teams.md Block 0 contains codify gate + awk pattern (positive)
#        AND does NOT contain bare grep -l 'retro_status: captured' (negative)
echo ""
echo "TC-17: steps-teams.md Block 0 codify gate (positive) + no bare grep pattern (negative)"
if [ ! -f "$STEPS_TEAMS_MD" ]; then
  fail "TC-17: skills/orchestrate/steps-teams.md does not exist"
else
  has_codify=$(grep -iE "codify|codify-insight" "$STEPS_TEAMS_MD" || true)
  has_awk=$(grep -qF "awk '/^---\$/{c++;next} c==1{print}'" "$STEPS_TEAMS_MD" && echo "yes" || echo "no")
  has_bare_grep=$(grep -qE "grep -l 'retro_status: captured'|grep -rl 'retro_status: captured'" "$STEPS_TEAMS_MD" && echo "yes" || echo "no")
  if [ -n "$has_codify" ] && [ "$has_awk" = "yes" ] && [ "$has_bare_grep" = "no" ]; then
    pass "TC-17: steps-teams.md has codify gate + awk pattern and no bare grep"
  elif [ -z "$has_codify" ]; then
    fail "TC-17: steps-teams.md does NOT contain codify gate"
  elif [ "$has_awk" = "no" ]; then
    fail "TC-17: steps-teams.md does NOT contain frontmatter-only awk pattern"
  else
    fail "TC-17: steps-teams.md contains bare grep 'retro_status: captured' (self-trigger risk)"
  fi
fi

# TC-18: README.md, CLAUDE.md, AGENTS.md, docs/STATUS.md all contain grep-matchable "codify-insight"
echo ""
echo "TC-18: README.md / CLAUDE.md / AGENTS.md / docs/STATUS.md each mention codify-insight"
TC18_PASS=true
for label_file in \
  "README.md:$README_MD" \
  "CLAUDE.md:$CLAUDE_MD" \
  "AGENTS.md:$AGENTS_MD" \
  "docs/STATUS.md:$STATUS_MD"
do
  label="${label_file%%:*}"
  fpath="${label_file#*:}"
  if [ ! -f "$fpath" ]; then
    fail "TC-18: $label does not exist"
    TC18_PASS=false
  elif grep -q "codify-insight" "$fpath"; then
    : # counted at end
  else
    fail "TC-18: $label does NOT mention codify-insight"
    TC18_PASS=false
  fi
done
if [ "$TC18_PASS" = "true" ]; then
  pass "TC-18: All 4 files mention codify-insight"
fi

# TC-19: docs/STATUS.md contains "Skills | 32" AND "Test Scripts | 109", README.md contains "32 skills"
echo ""
echo "TC-19: STATUS.md Skills=32 + Test Scripts=109, README.md 32 skills"
if [ ! -f "$STATUS_MD" ]; then
  fail "TC-19: docs/STATUS.md does not exist"
else
  has_skills32=$(grep -qE "Skills[[:space:]]*\|[[:space:]]*32" "$STATUS_MD" && echo "yes" || echo "no")
  has_scripts109=$(grep -qE "Test Scripts[[:space:]]*\|[[:space:]]*109" "$STATUS_MD" && echo "yes" || echo "no")
  has_readme32=$(grep -qE "32 skills" "$README_MD" 2>/dev/null && echo "yes" || echo "no")
  if [ "$has_skills32" = "yes" ] && [ "$has_scripts109" = "yes" ] && [ "$has_readme32" = "yes" ]; then
    pass "TC-19: STATUS.md Skills=32 + Test Scripts=109, README.md 32 skills"
  else
    skills_current=$(grep -oE "Skills[[:space:]]*\|[[:space:]]*[0-9]+" "$STATUS_MD" | grep -oE "[0-9]+$" | head -1 || echo "not found")
    scripts_current=$(grep -oE "Test Scripts[[:space:]]*\|[[:space:]]*[0-9]+" "$STATUS_MD" | grep -oE "[0-9]+$" | head -1 || echo "not found")
    readme_current=$(grep -oE "[0-9]+ skills" "$README_MD" 2>/dev/null | head -1 || echo "not found")
    fail "TC-19: STATUS.md Skills=$skills_current (need 32), Test Scripts=$scripts_current (need 109), README=$readme_current (need '32 skills')"
  fi
fi

# TC-20: tests/test-cycle-retrospective.sh TC-14 has Skills count 32 (not 31 hardcode)
# Strategy: search TC-14 block for literal "31" (old) vs "32" (new)
# The file contains shell code like: grep -qE "Skills[[:space:]]*\|[[:space:]]*31" "$STATUS_MD"
# We search for the literal digit string in TC-14's grep command.
echo ""
echo "TC-20: test-cycle-retrospective.sh TC-14 checks Skills count 32 (not 31)"
if [ ! -f "$RETRO_TEST" ]; then
  fail "TC-20: tests/test-cycle-retrospective.sh does not exist"
else
  # Extract TC-14 block: from "# TC-14" to "# TC-15"
  tc14_block=$(awk '/^# TC-14:/,/^# TC-15:/{if(/^# TC-15:/)exit; print}' "$RETRO_TEST" || true)
  # The TC-14 grep command looks like: grep -qE "Skills[[:space:]]*\|[[:space:]]*31" or 32
  # Search for the literal count digit at the end of the pattern (e.g. *31" or *32")
  if echo "$tc14_block" | grep -qE '\*31"'; then
    fail "TC-20: test-cycle-retrospective.sh still hardcodes Skills=31 in TC-14 (needs bump to 32)"
  elif echo "$tc14_block" | grep -qE '\*32"'; then
    pass "TC-20: test-cycle-retrospective.sh TC-14 checks Skills count 32"
  elif echo "$tc14_block" | grep -q "Skills count = 31"; then
    fail "TC-20: test-cycle-retrospective.sh TC-14 still references Skills count 31"
  elif echo "$tc14_block" | grep -q "Skills count = 32"; then
    pass "TC-20: test-cycle-retrospective.sh TC-14 references Skills count 32"
  else
    fail "TC-20: test-cycle-retrospective.sh TC-14 Skills count check not found (pattern not recognized)"
  fi
fi

# TC-21: SKILL.md documents Recurrence-aware Pre-triage (2+ 回再発 → 自動 rule 昇格)
echo ""
echo "TC-21: SKILL.md documents Recurrence-aware Pre-triage"
if [ ! -f "$SKILL_MD" ]; then
  fail "TC-21: skills/codify-insight/SKILL.md does not exist"
else
  has_recurrence_heading=$(grep -cE "^### Recurrence" "$SKILL_MD" || true)
  has_promotion_rule=$(grep -cF "2+ 回再発" "$SKILL_MD" || true)
  if [ "$has_recurrence_heading" -ge 1 ] && [ "$has_promotion_rule" -ge 1 ]; then
    pass "TC-21: SKILL.md documents Recurrence-aware Pre-triage + 2+ 回再発 promotion"
  elif [ "$has_recurrence_heading" -lt 1 ]; then
    fail "TC-21: SKILL.md missing '### Recurrence' heading"
  else
    fail "TC-21: SKILL.md missing '2+ 回再発' promotion rule"
  fi
fi

# TC-22: reference.md documents frequency_threshold (default 2 回) + scan 範囲 (直近 10 cycle docs)
echo ""
echo "TC-22: reference.md documents frequency_threshold + scan 範囲"
if [ ! -f "$REFERENCE_MD" ]; then
  fail "TC-22: skills/codify-insight/reference.md does not exist"
else
  has_threshold=$(grep -cE "frequency_threshold|2 回" "$REFERENCE_MD" || true)
  has_scan_range=$(grep -cE "直近 10 cycle|10 cycles" "$REFERENCE_MD" || true)
  has_duplicate_detect=$(grep -cF "duplicate" "$REFERENCE_MD" || true)
  if [ "$has_threshold" -ge 1 ] && [ "$has_scan_range" -ge 1 ] && [ "$has_duplicate_detect" -ge 1 ]; then
    pass "TC-22: reference.md documents frequency_threshold + scan 範囲 + duplicate detection"
  elif [ "$has_threshold" -lt 1 ]; then
    fail "TC-22: reference.md missing frequency_threshold / 2 回 mention"
  elif [ "$has_scan_range" -lt 1 ]; then
    fail "TC-22: reference.md missing scan 範囲 (直近 10 cycle docs)"
  else
    fail "TC-22: reference.md missing duplicate detection documentation"
  fi
fi

# TC-23: SKILL.md documents Question 0 件条件 (全件 recurrence or high-confidence で質問スキップ)
echo ""
echo "TC-23: SKILL.md documents zero-question path"
if [ ! -f "$SKILL_MD" ]; then
  fail "TC-23: skills/codify-insight/SKILL.md does not exist"
else
  has_zero_question=$(grep -cE "質問 0 件|質問スキップ|0 件で summary" "$SKILL_MD" || true)
  if [ "$has_zero_question" -ge 1 ]; then
    pass "TC-23: SKILL.md documents zero-question path"
  else
    fail "TC-23: SKILL.md missing zero-question (質問 0 件 / 質問スキップ) documentation"
  fi
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
