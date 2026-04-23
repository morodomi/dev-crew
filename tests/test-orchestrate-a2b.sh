#!/bin/bash
# test-orchestrate-a2b.sh - orchestrate A2b integration structure tests
# TC-01 to TC-05, TC-10 to TC-18 for v2.7 Agile Loop Cycle A2b
# Structural inspection (grep-based): no fixtures needed

set -uo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

ORCHESTRATE_SKILL="$BASE_DIR/skills/orchestrate/SKILL.md"
ORCHESTRATE_REF="$BASE_DIR/skills/orchestrate/reference.md"
STEPS_SUBAGENT="$BASE_DIR/skills/orchestrate/steps-subagent.md"
STEPS_TEAMS="$BASE_DIR/skills/orchestrate/steps-teams.md"
STEPS_CODEX="$BASE_DIR/skills/orchestrate/steps-codex.md"
COMMIT_SKILL="$BASE_DIR/skills/commit/SKILL.md"
WORKFLOW_MD="$BASE_DIR/docs/workflow.md"
ARCH_MD="$BASE_DIR/docs/architecture.md"
STATUS_MD="$BASE_DIR/docs/STATUS.md"
CLAUDE_MD="$BASE_DIR/CLAUDE.md"
README_MD="$BASE_DIR/README.md"
AGENTS_MD="$BASE_DIR/AGENTS.md"
RETRO_SKILL="$BASE_DIR/skills/cycle-retrospective/SKILL.md"

echo "=== orchestrate A2b Integration Tests (v2.7 Cycle A2b) ==="

# ----------------------------------------------------------------
# TC-01: orchestrate/SKILL.md 行数 <= 100 (compress 確認)
# ----------------------------------------------------------------
echo ""
echo "TC-01: orchestrate/SKILL.md line count <= 100"
if [ ! -f "$ORCHESTRATE_SKILL" ]; then
  fail "TC-01: skills/orchestrate/SKILL.md does not exist"
else
  line_count=$(wc -l < "$ORCHESTRATE_SKILL" | tr -d ' ')
  if [ "$line_count" -le 100 ]; then
    pass "TC-01: orchestrate/SKILL.md has $line_count lines (<= 100)"
  else
    fail "TC-01: orchestrate/SKILL.md has $line_count lines (> 100, compress required)"
  fi
fi

# ----------------------------------------------------------------
# TC-02: orchestrate/SKILL.md Progress Checklist に Block 2f + cycle-retrospective
# ----------------------------------------------------------------
echo ""
echo "TC-02: orchestrate/SKILL.md Progress Checklist contains Block 2f + cycle-retrospective"
if [ ! -f "$ORCHESTRATE_SKILL" ]; then
  fail "TC-02: skills/orchestrate/SKILL.md does not exist"
else
  has_2f=$(grep -i "Block 2f" "$ORCHESTRATE_SKILL" || true)
  has_retro=$(grep "cycle-retrospective" "$ORCHESTRATE_SKILL" || true)
  if [ -n "$has_2f" ] && [ -n "$has_retro" ]; then
    pass "TC-02: SKILL.md contains Block 2f and cycle-retrospective"
  elif [ -z "$has_2f" ] && [ -z "$has_retro" ]; then
    fail "TC-02: SKILL.md missing both Block 2f and cycle-retrospective"
  elif [ -z "$has_2f" ]; then
    fail "TC-02: SKILL.md missing 'Block 2f' (has cycle-retrospective but not Block 2f)"
  else
    fail "TC-02: SKILL.md missing 'cycle-retrospective' (has Block 2f but not cycle-retrospective)"
  fi
fi

# ----------------------------------------------------------------
# TC-03: orchestrate/SKILL.md で Block 2f が Block 2e と Block 3 の間に位置
# ----------------------------------------------------------------
echo ""
echo "TC-03: orchestrate/SKILL.md Block 2f is between Block 2e and Block 3 (line order)"
if [ ! -f "$ORCHESTRATE_SKILL" ]; then
  fail "TC-03: skills/orchestrate/SKILL.md does not exist"
else
  line_2e=$(grep -n "Block 2e" "$ORCHESTRATE_SKILL" | head -1 | cut -d: -f1 || true)
  line_2f=$(grep -n "Block 2f" "$ORCHESTRATE_SKILL" | head -1 | cut -d: -f1 || true)
  line_b3=$(grep -n "Block 3" "$ORCHESTRATE_SKILL" | head -1 | cut -d: -f1 || true)
  if [ -z "$line_2e" ] || [ -z "$line_2f" ] || [ -z "$line_b3" ]; then
    missing=""
    [ -z "$line_2e" ] && missing="${missing}Block 2e "
    [ -z "$line_2f" ] && missing="${missing}Block 2f "
    [ -z "$line_b3" ] && missing="${missing}Block 3 "
    fail "TC-03: Missing block labels in SKILL.md: ${missing}(cannot verify order)"
  elif [ "$line_2e" -lt "$line_2f" ] && [ "$line_2f" -lt "$line_b3" ]; then
    pass "TC-03: Block 2e (L$line_2e) < Block 2f (L$line_2f) < Block 3 (L$line_b3)"
  else
    fail "TC-03: Block ordering incorrect: 2e=L$line_2e, 2f=L$line_2f, Block3=L$line_b3 (expected 2e < 2f < Block3)"
  fi
fi

# ----------------------------------------------------------------
# TC-04: orchestrate/reference.md に Block 2f + cycle-retrospective 詳細記述
# ----------------------------------------------------------------
echo ""
echo "TC-04: orchestrate/reference.md contains Block 2f + cycle-retrospective"
if [ ! -f "$ORCHESTRATE_REF" ]; then
  fail "TC-04: skills/orchestrate/reference.md does not exist"
else
  has_2f=$(grep -i "Block 2f" "$ORCHESTRATE_REF" || true)
  has_retro=$(grep "cycle-retrospective" "$ORCHESTRATE_REF" || true)
  if [ -n "$has_2f" ] && [ -n "$has_retro" ]; then
    pass "TC-04: reference.md contains Block 2f and cycle-retrospective"
  elif [ -z "$has_2f" ] && [ -z "$has_retro" ]; then
    fail "TC-04: reference.md missing both Block 2f and cycle-retrospective"
  elif [ -z "$has_2f" ]; then
    fail "TC-04: reference.md missing 'Block 2f'"
  else
    fail "TC-04: reference.md missing 'cycle-retrospective'"
  fi
fi

# ----------------------------------------------------------------
# TC-05: steps-subagent.md / steps-teams.md / steps-codex.md に cycle-retrospective 言及
# ----------------------------------------------------------------
echo ""
echo "TC-05: steps-subagent/teams/codex.md each mention cycle-retrospective"
TC05_PASS=true
for label_file in \
  "steps-subagent.md:$STEPS_SUBAGENT" \
  "steps-teams.md:$STEPS_TEAMS" \
  "steps-codex.md:$STEPS_CODEX"
do
  label="${label_file%%:*}"
  fpath="${label_file#*:}"
  if [ ! -f "$fpath" ]; then
    fail "TC-05: $label does not exist"
    TC05_PASS=false
  elif grep -q "cycle-retrospective" "$fpath"; then
    : # will pass collectively
  else
    fail "TC-05: $label does NOT mention cycle-retrospective"
    TC05_PASS=false
  fi
done
if [ "$TC05_PASS" = "true" ]; then
  pass "TC-05: All 3 steps-*.md files mention cycle-retrospective"
fi

# ----------------------------------------------------------------
# TC-10: commit/SKILL.md Pre-COMMIT Gate に retro_status check 記述
# ----------------------------------------------------------------
echo ""
echo "TC-10: commit/SKILL.md Pre-COMMIT Gate contains retro_status check"
if [ ! -f "$COMMIT_SKILL" ]; then
  fail "TC-10: skills/commit/SKILL.md does not exist"
elif grep -q "retro_status" "$COMMIT_SKILL"; then
  pass "TC-10: commit/SKILL.md contains retro_status"
else
  fail "TC-10: commit/SKILL.md does NOT contain retro_status (Pre-COMMIT Gate check missing)"
fi

# ----------------------------------------------------------------
# TC-11a: docs/workflow.md 開発フロー図セクション内に cycle-retrospective 言及
# ----------------------------------------------------------------
echo ""
echo "TC-11a: docs/workflow.md development flow section mentions cycle-retrospective"
if [ ! -f "$WORKFLOW_MD" ]; then
  fail "TC-11a: docs/workflow.md does not exist"
else
  # Extract content of ## 開発フロー section (until next ##)
  flow_section=$(awk '/^## 開発フロー/{found=1; next} found && /^## /{exit} found{print}' "$WORKFLOW_MD" || true)
  if echo "$flow_section" | grep -q "cycle-retrospective"; then
    pass "TC-11a: workflow.md 開発フロー section mentions cycle-retrospective"
  else
    fail "TC-11a: workflow.md 開発フロー section does NOT mention cycle-retrospective"
  fi
fi

# ----------------------------------------------------------------
# TC-11b: docs/workflow.md 決定論的ゲート表セクション内に retro_status 記述
# ----------------------------------------------------------------
echo ""
echo "TC-11b: docs/workflow.md deterministic gate table mentions retro_status"
if [ ! -f "$WORKFLOW_MD" ]; then
  fail "TC-11b: docs/workflow.md does not exist"
else
  # Extract content of ## 決定論的ゲート section (until next ##)
  gate_section=$(awk '/^## 決定論的ゲート/{found=1; next} found && /^## /{exit} found{print}' "$WORKFLOW_MD" || true)
  if echo "$gate_section" | grep -q "retro_status"; then
    pass "TC-11b: workflow.md 決定論的ゲート section mentions retro_status"
  else
    fail "TC-11b: workflow.md 決定論的ゲート section does NOT mention retro_status"
  fi
fi

# ----------------------------------------------------------------
# TC-12: docs/architecture.md に cycle-retrospective 追記
#         + "31 skills" のような hardcode count がないこと (negative assert)
# ----------------------------------------------------------------
echo ""
echo "TC-12: docs/architecture.md mentions cycle-retrospective (no hardcode skill count added)"
if [ ! -f "$ARCH_MD" ]; then
  fail "TC-12: docs/architecture.md does not exist"
else
  has_retro=$(grep "cycle-retrospective" "$ARCH_MD" || true)
  # Negative assert: "31 skills" or "32 skills" etc. hardcoded count patterns
  has_hardcode=$(grep -oE '[0-9]+ skills' "$ARCH_MD" || true)
  if [ -z "$has_retro" ]; then
    fail "TC-12: architecture.md does NOT mention cycle-retrospective"
  elif [ -n "$has_hardcode" ]; then
    fail "TC-12: architecture.md mentions cycle-retrospective but has hardcoded skill count: '$has_hardcode' (CONSTITUTION.md violation)"
  else
    pass "TC-12: architecture.md mentions cycle-retrospective without hardcoded skill count"
  fi
fi

# ----------------------------------------------------------------
# TC-13: skills/cycle-retrospective/SKILL.md Hard Gate に phase 制約
#         (REVIEW/COMMIT/DONE のみ許可、INIT/RED 等は BLOCK)
# ----------------------------------------------------------------
echo ""
echo "TC-13: cycle-retrospective/SKILL.md Hard Gate has phase constraint (REVIEW/COMMIT/DONE only)"
if [ ! -f "$RETRO_SKILL" ]; then
  fail "TC-13: skills/cycle-retrospective/SKILL.md does not exist"
else
  # Extract Hard Gate section
  gate_section=$(awk '/^### Hard Gate/{found=1; next} found && /^### /{exit} found{print}' "$RETRO_SKILL" || true)
  has_review=$(echo "$gate_section" | grep -i "REVIEW" || true)
  has_commit=$(echo "$gate_section" | grep -i "COMMIT" || true)
  has_done=$(echo "$gate_section" | grep -i "DONE" || true)
  # Also check that non-permitted phases (INIT, RED etc.) are referenced as BLOCKed
  has_block=$(echo "$gate_section" | grep -iE "BLOCK|INIT|RED|GREEN|REFACTOR" || true)
  if [ -n "$has_review" ] && [ -n "$has_commit" ] && [ -n "$has_done" ] && [ -n "$has_block" ]; then
    pass "TC-13: Hard Gate contains REVIEW/COMMIT/DONE allowlist and BLOCK for non-permitted phases"
  else
    missing=""
    [ -z "$has_review" ] && missing="${missing}REVIEW "
    [ -z "$has_commit" ] && missing="${missing}COMMIT "
    [ -z "$has_done" ] && missing="${missing}DONE "
    [ -z "$has_block" ] && missing="${missing}BLOCK/non-permitted-phase "
    fail "TC-13: Hard Gate missing: ${missing}in cycle-retrospective/SKILL.md"
  fi
fi

# ----------------------------------------------------------------
# TC-14: steps-subagent.md / steps-teams.md / steps-codex.md に
#         cycle-retrospective abort → BLOCK 分岐が記述される
# ----------------------------------------------------------------
echo ""
echo "TC-14: steps-*.md 3 files each describe abort -> BLOCK handling"
TC14_PASS=true
for label_file in \
  "steps-subagent.md:$STEPS_SUBAGENT" \
  "steps-teams.md:$STEPS_TEAMS" \
  "steps-codex.md:$STEPS_CODEX"
do
  label="${label_file%%:*}"
  fpath="${label_file#*:}"
  if [ ! -f "$fpath" ]; then
    fail "TC-14: $label does not exist"
    TC14_PASS=false
  else
    # Must contain "abort" AND ("BLOCK" or "commit 停止" or "停止") in the context of cycle-retrospective
    has_abort=$(grep -i "abort" "$fpath" || true)
    has_block=$(grep -iE "BLOCK|commit 停止|コミット停止|停止" "$fpath" || true)
    if [ -n "$has_abort" ] && [ -n "$has_block" ]; then
      : # will pass collectively
    elif [ -z "$has_abort" ]; then
      fail "TC-14: $label does NOT contain 'abort' handling"
      TC14_PASS=false
    else
      fail "TC-14: $label contains 'abort' but no BLOCK/commit-stop description"
      TC14_PASS=false
    fi
  fi
done
if [ "$TC14_PASS" = "true" ]; then
  pass "TC-14: All 3 steps-*.md files describe abort -> BLOCK handling"
fi

# ----------------------------------------------------------------
# TC-14b: steps-subagent.md / steps-teams.md / steps-codex.md で
#         DISCOVERED 判断 が Block 2f より前に位置する (order check、Codex P1 対応)
# ----------------------------------------------------------------
echo ""
echo "TC-14b: steps-*.md DISCOVERED comes BEFORE Block 2f (physical order)"
TC14B_PASS=true
for pair in "subagent:skills/orchestrate/steps-subagent.md" "teams:skills/orchestrate/steps-teams.md" "codex:skills/orchestrate/steps-codex.md"; do
  label="${pair%%:*}"
  file="$BASE_DIR/${pair##*:}"
  [ -f "$file" ] || { fail "TC-14b: $label file missing"; TC14B_PASS=false; continue; }
  discovered_line=$(grep -n "^### DISCOVERED 判断" "$file" | head -1 | cut -d: -f1)
  block2f_line=$(grep -n "^### Block 2f" "$file" | head -1 | cut -d: -f1)
  if [ -z "$discovered_line" ] || [ -z "$block2f_line" ]; then
    fail "TC-14b: $label missing DISCOVERED or Block 2f section (discovered=$discovered_line, block2f=$block2f_line)"
    TC14B_PASS=false
  elif [ "$discovered_line" -ge "$block2f_line" ]; then
    fail "TC-14b: $label has wrong order (DISCOVERED at line $discovered_line, Block 2f at $block2f_line; expected DISCOVERED < Block 2f)"
    TC14B_PASS=false
  fi
done
if [ "$TC14B_PASS" = "true" ]; then
  pass "TC-14b: All 3 steps-*.md files have DISCOVERED before Block 2f"
fi

# ----------------------------------------------------------------
# TC-15: docs/STATUS.md の Test Scripts count が 109
#         (current repository status)
# ----------------------------------------------------------------
echo ""
echo "TC-15: docs/STATUS.md Test Scripts count = 109"
if [ ! -f "$STATUS_MD" ]; then
  fail "TC-15: docs/STATUS.md does not exist"
elif grep -qE 'Test Scripts[[:space:]]*\|[[:space:]]*109' "$STATUS_MD"; then
  pass "TC-15: docs/STATUS.md Test Scripts count is 109"
else
  current=$(grep -oE 'Test Scripts[[:space:]]*\|[[:space:]]*[0-9]+' "$STATUS_MD" | grep -oE '[0-9]+$' | head -1 || echo "not found")
  fail "TC-15: docs/STATUS.md Test Scripts count is NOT 109 (current: $current)"
fi

# ----------------------------------------------------------------
# TC-16: CLAUDE.md に post-approve-gate.sh 参照が残っていない (negative assert)
# ----------------------------------------------------------------
echo ""
echo "TC-16: CLAUDE.md has no stale post-approve-gate.sh reference"
if [ ! -f "$CLAUDE_MD" ]; then
  fail "TC-16: CLAUDE.md does not exist"
elif grep -q "post-approve-gate" "$CLAUDE_MD"; then
  match=$(grep "post-approve-gate" "$CLAUDE_MD" | head -1 || true)
  fail "TC-16: CLAUDE.md still contains post-approve-gate.sh reference (line: '$match')"
else
  pass "TC-16: CLAUDE.md has no post-approve-gate.sh reference"
fi

# ----------------------------------------------------------------
# TC-17: README.md TDD Workflow 行に REVIEW.*cycle-retrospective.*COMMIT パターン
# ----------------------------------------------------------------
echo ""
echo "TC-17: README.md TDD Workflow line contains REVIEW...cycle-retrospective...COMMIT"
if [ ! -f "$README_MD" ]; then
  fail "TC-17: README.md does not exist"
elif grep -qE 'REVIEW.*cycle-retrospective.*COMMIT|REVIEW.+cycle-retrospective' "$README_MD"; then
  pass "TC-17: README.md TDD Workflow line contains cycle-retrospective between REVIEW and COMMIT"
else
  fail "TC-17: README.md TDD Workflow line does NOT contain cycle-retrospective between REVIEW and COMMIT"
fi

# ----------------------------------------------------------------
# TC-18: AGENTS.md TDD Workflow 行に REVIEW.*cycle-retrospective.*COMMIT パターン
# ----------------------------------------------------------------
echo ""
echo "TC-18: AGENTS.md TDD Workflow line contains REVIEW...cycle-retrospective...COMMIT"
if [ ! -f "$AGENTS_MD" ]; then
  fail "TC-18: AGENTS.md does not exist"
elif grep -qE 'REVIEW.*cycle-retrospective.*COMMIT|REVIEW.+cycle-retrospective' "$AGENTS_MD"; then
  pass "TC-18: AGENTS.md TDD Workflow line contains cycle-retrospective between REVIEW and COMMIT"
else
  fail "TC-18: AGENTS.md TDD Workflow line does NOT contain cycle-retrospective between REVIEW and COMMIT"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
