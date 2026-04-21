#!/bin/bash
# test-cycle-retrospective.sh - cycle-retrospective skill structure tests
# TC-01 to TC-15 for v2.7 Agile Loop Cycle A2a

set -uo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

SKILL_MD="$BASE_DIR/skills/cycle-retrospective/SKILL.md"
REFERENCE_MD="$BASE_DIR/skills/cycle-retrospective/reference.md"
STATE_OWNERSHIP="$BASE_DIR/rules/state-ownership.md"
README_MD="$BASE_DIR/README.md"
AGENTS_MD="$BASE_DIR/AGENTS.md"
CLAUDE_MD="$BASE_DIR/CLAUDE.md"
STATUS_MD="$BASE_DIR/docs/STATUS.md"
FRONTMATTER_VALIDATOR="$BASE_DIR/scripts/validate-yaml-frontmatter.sh"

echo "=== cycle-retrospective Skill Structure Tests (v2.7 Cycle A2a) ==="

# TC-01: SKILL.md frontmatter valid (via validate-yaml-frontmatter.sh)
echo ""
echo "TC-01: SKILL.md frontmatter validation via validate-yaml-frontmatter.sh"
if [ ! -f "$SKILL_MD" ]; then
  fail "TC-01: skills/cycle-retrospective/SKILL.md does not exist"
elif ! bash "$FRONTMATTER_VALIDATOR" "$SKILL_MD" 2>/dev/null; then
  fail "TC-01: SKILL.md frontmatter is invalid (validate-yaml-frontmatter.sh returned non-zero)"
else
  pass "TC-01: SKILL.md frontmatter is valid"
fi

# TC-02: SKILL.md line count <= 100
echo ""
echo "TC-02: SKILL.md line count <= 100"
if [ ! -f "$SKILL_MD" ]; then
  fail "TC-02: skills/cycle-retrospective/SKILL.md does not exist"
else
  line_count=$(wc -l < "$SKILL_MD" | tr -d ' ')
  if [ "$line_count" -le 100 ]; then
    pass "TC-02: SKILL.md has $line_count lines (<= 100)"
  else
    fail "TC-02: SKILL.md has $line_count lines (> 100, hard limit exceeded)"
  fi
fi

# TC-03: SKILL.md allowed-tools contains AskUserQuestion
echo ""
echo "TC-03: SKILL.md allowed-tools contains AskUserQuestion"
if [ ! -f "$SKILL_MD" ]; then
  fail "TC-03: skills/cycle-retrospective/SKILL.md does not exist"
elif grep -q "AskUserQuestion" "$SKILL_MD"; then
  pass "TC-03: SKILL.md allowed-tools contains AskUserQuestion"
else
  fail "TC-03: SKILL.md does NOT contain AskUserQuestion in allowed-tools"
fi

# TC-04: SKILL.md description contains "retrospective" or "振り返り"
echo ""
echo "TC-04: SKILL.md description contains trigger keyword (retrospective / 振り返り)"
if [ ! -f "$SKILL_MD" ]; then
  fail "TC-04: skills/cycle-retrospective/SKILL.md does not exist"
else
  # Extract description line from frontmatter
  desc_line=$(awk '/^---$/{n++; next} n==1 && /^description:/{print; exit} n==2{exit}' "$SKILL_MD" || true)
  if echo "$desc_line" | grep -qE "retrospective|振り返り"; then
    pass "TC-04: SKILL.md description contains trigger keyword"
  else
    fail "TC-04: SKILL.md description does NOT contain 'retrospective' or '振り返り' (line: '$desc_line')"
  fi
fi

# TC-05: SKILL.md Workflow contains Hard Gate with "Cycle doc" + ("存在" or "exist")
echo ""
echo "TC-05: SKILL.md Workflow has Hard Gate referencing Cycle doc existence"
if [ ! -f "$SKILL_MD" ]; then
  fail "TC-05: skills/cycle-retrospective/SKILL.md does not exist"
else
  # Check that SKILL.md contains both "Cycle doc" and ("存在" or "exist") as a gate
  has_cycle_doc=$(grep -i "Cycle doc" "$SKILL_MD" || true)
  has_exist=$(grep -iE "存在|exist" "$SKILL_MD" || true)
  if [ -n "$has_cycle_doc" ] && [ -n "$has_exist" ]; then
    pass "TC-05: SKILL.md Workflow contains Hard Gate with Cycle doc + exist/存在"
  else
    fail "TC-05: SKILL.md Workflow does NOT contain Hard Gate with 'Cycle doc' + '存在'/'exist'"
  fi
fi

# TC-06: SKILL.md Workflow contains idempotency check
# Requires "retro_status" + ("skip" or "captured" or "none") together
echo ""
echo "TC-06: SKILL.md Workflow contains idempotency check (retro_status + skip/captured/none)"
if [ ! -f "$SKILL_MD" ]; then
  fail "TC-06: skills/cycle-retrospective/SKILL.md does not exist"
else
  has_retro=$(grep "retro_status" "$SKILL_MD" || true)
  has_idempotent=$(grep -E "skip|captured|none" "$SKILL_MD" || true)
  if [ -n "$has_retro" ] && [ -n "$has_idempotent" ]; then
    pass "TC-06: SKILL.md Workflow contains idempotency check (retro_status + skip/captured/none)"
  else
    fail "TC-06: SKILL.md Workflow does NOT contain idempotency check (retro_status + skip/captured/none)"
  fi
fi

# TC-07: skills/cycle-retrospective/reference.md exists
echo ""
echo "TC-07: skills/cycle-retrospective/reference.md exists"
if [ -f "$REFERENCE_MD" ]; then
  pass "TC-07: reference.md exists"
else
  fail "TC-07: skills/cycle-retrospective/reference.md does NOT exist"
fi

# TC-08: reference.md contains both "proceed" and "abort" (override 2-path split)
echo ""
echo "TC-08: reference.md contains override 2-path split (proceed + abort)"
if [ ! -f "$REFERENCE_MD" ]; then
  fail "TC-08: skills/cycle-retrospective/reference.md does not exist"
else
  has_proceed=$(grep -i "proceed" "$REFERENCE_MD" || true)
  has_abort=$(grep -i "abort" "$REFERENCE_MD" || true)
  if [ -n "$has_proceed" ] && [ -n "$has_abort" ]; then
    pass "TC-08: reference.md contains both 'proceed' and 'abort'"
  else
    fail "TC-08: reference.md does NOT contain both 'proceed' and 'abort' (override 2-path)"
  fi
fi

# TC-09: reference.md contains all 3 fixed string contracts
echo ""
echo "TC-09: reference.md contains all 3 fixed string contracts"
if [ ! -f "$REFERENCE_MD" ]; then
  fail "TC-09: skills/cycle-retrospective/reference.md does not exist"
else
  TC09_PASS=true
  for contract in \
    "Extraction skipped by override" \
    "Extraction failed after N retries" \
    "No reusable lesson this cycle"
  do
    if ! grep -qF "$contract" "$REFERENCE_MD"; then
      fail "TC-09: reference.md missing fixed string: '$contract'"
      TC09_PASS=false
    fi
  done
  if [ "$TC09_PASS" = "true" ]; then
    pass "TC-09: reference.md contains all 3 fixed string contracts"
  fi
fi

# TC-10: reference.md contains idempotency spec (retro_status + none + skip)
echo ""
echo "TC-10: reference.md contains idempotency spec (retro_status + none + skip)"
if [ ! -f "$REFERENCE_MD" ]; then
  fail "TC-10: skills/cycle-retrospective/reference.md does not exist"
else
  has_retro=$(grep "retro_status" "$REFERENCE_MD" || true)
  has_none=$(grep -w "none" "$REFERENCE_MD" || true)
  has_skip=$(grep -i "skip" "$REFERENCE_MD" || true)
  if [ -n "$has_retro" ] && [ -n "$has_none" ] && [ -n "$has_skip" ]; then
    pass "TC-10: reference.md contains idempotency spec (retro_status + none + skip)"
  else
    fail "TC-10: reference.md does NOT contain idempotency spec (retro_status + none + skip)"
  fi
fi

# TC-11: rules/state-ownership.md has cycle-retrospective row with retro_status + (captured or resolved)
echo ""
echo "TC-11: state-ownership.md has cycle-retrospective row with retro_status transition"
if [ ! -f "$STATE_OWNERSHIP" ]; then
  fail "TC-11: rules/state-ownership.md does not exist"
else
  retro_line=$(grep "cycle-retrospective" "$STATE_OWNERSHIP" || true)
  if [ -z "$retro_line" ]; then
    fail "TC-11: state-ownership.md does NOT contain cycle-retrospective row"
  elif echo "$retro_line" | grep -q "retro_status"; then
    if echo "$retro_line" | grep -qE "captured|resolved"; then
      pass "TC-11: state-ownership.md has cycle-retrospective row with retro_status transition"
    else
      fail "TC-11: state-ownership.md cycle-retrospective row has retro_status but no 'captured'/'resolved' (line: '$retro_line')"
    fi
  else
    fail "TC-11: state-ownership.md cycle-retrospective row does NOT contain 'retro_status' (line: '$retro_line')"
  fi
fi

# TC-12: state-ownership.md sync-plan row still has retro_status + "none" (regression check)
echo ""
echo "TC-12: state-ownership.md sync-plan row contains retro_status + none (A1 regression check)"
if [ ! -f "$STATE_OWNERSHIP" ]; then
  fail "TC-12: rules/state-ownership.md does not exist"
else
  syncplan_line=$(grep "sync-plan" "$STATE_OWNERSHIP" || true)
  if [ -z "$syncplan_line" ]; then
    fail "TC-12: state-ownership.md has no sync-plan row"
  elif echo "$syncplan_line" | grep -q "retro_status"; then
    if echo "$syncplan_line" | grep -qE "retro_status[^|]*none"; then
      pass "TC-12: state-ownership.md sync-plan row has retro_status with none (A1 intact)"
    else
      fail "TC-12: state-ownership.md sync-plan row has retro_status but not 'none' (line: '$syncplan_line')"
    fi
  else
    fail "TC-12: state-ownership.md sync-plan row does NOT have retro_status (line: '$syncplan_line')"
  fi
fi

# TC-13: README.md / AGENTS.md / CLAUDE.md / STATUS.md each mention "cycle-retrospective"
echo ""
echo "TC-13: README.md / AGENTS.md / CLAUDE.md / STATUS.md each mention cycle-retrospective"
TC13_PASS=true
for label_file in \
  "README.md:$README_MD" \
  "AGENTS.md:$AGENTS_MD" \
  "CLAUDE.md:$CLAUDE_MD" \
  "docs/STATUS.md:$STATUS_MD"
do
  label="${label_file%%:*}"
  fpath="${label_file#*:}"
  if [ ! -f "$fpath" ]; then
    fail "TC-13: $label does not exist"
    TC13_PASS=false
  elif grep -q "cycle-retrospective" "$fpath"; then
    : # pass individually counted at end
  else
    fail "TC-13: $label does NOT mention cycle-retrospective"
    TC13_PASS=false
  fi
done
if [ "$TC13_PASS" = "true" ]; then
  pass "TC-13: All 4 files mention cycle-retrospective"
fi

# TC-14: docs/STATUS.md shows Skills count = 31
echo ""
echo "TC-14: docs/STATUS.md Skills count = 31"
if [ ! -f "$STATUS_MD" ]; then
  fail "TC-14: docs/STATUS.md does not exist"
elif grep -qE "Skills[[:space:]]*\|[[:space:]]*31" "$STATUS_MD"; then
  pass "TC-14: docs/STATUS.md Skills count is 31"
else
  current_count=$(grep -oE "Skills[[:space:]]*\|[[:space:]]*[0-9]+" "$STATUS_MD" | grep -oE "[0-9]+$" | head -1 || echo "not found")
  fail "TC-14: docs/STATUS.md Skills count is NOT 31 (current: $current_count)"
fi

# TC-15: README.md "N skills" matches actual skills/ directory count
echo ""
echo "TC-15: README.md 'N skills' matches actual skills/ directory count"
if [ ! -f "$README_MD" ]; then
  fail "TC-15: README.md does not exist"
else
  readme_count=$(grep -oE '[0-9]+ skills' "$README_MD" | head -1 | grep -oE '^[0-9]+' || true)
  actual_count=$(find "$BASE_DIR/skills" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
  if [ -z "$readme_count" ]; then
    fail "TC-15: README.md has no 'N skills' pattern"
  elif [ "$readme_count" = "$actual_count" ]; then
    pass "TC-15: README.md '$readme_count skills' matches actual ($actual_count)"
  else
    fail "TC-15: README.md '$readme_count skills' != actual ($actual_count)"
  fi
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
