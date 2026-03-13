#!/bin/bash
# test-kickoff-debate.sh - Debate Protocol (Phase 2) validation
# TC-01 through TC-09

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILL_MD="$BASE_DIR/skills/kickoff/SKILL.md"
REF_MD="$BASE_DIR/skills/kickoff/reference.md"
ROADMAP="$BASE_DIR/ROADMAP.md"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== Kickoff Debate Protocol Tests ==="

# TC-01: kickoff SKILL.md has Step 3.5 with Codex check and debate/fallback branching
echo ""
echo "TC-01: SKILL.md Step 3.5 existence"
if grep -q "Step 3.5" "$SKILL_MD" && grep -q "codex" "$SKILL_MD" && grep -q -i "フォールバック\|fallback\|plan-review" "$SKILL_MD"; then
  pass "TC-01: SKILL.md has Step 3.5 with Codex check and fallback branching"
else
  fail "TC-01: SKILL.md missing Step 3.5 or Codex check or fallback branching"
fi

# TC-02: reference.md has Debate Workflow with 5 subsections
echo ""
echo "TC-02: reference.md Debate Workflow subsections"
has_workflow=false
has_round=false
has_clarification=false
has_recording=false
has_adr=false
if grep -q "## Debate Workflow" "$REF_MD"; then has_workflow=true; fi
if grep -q "Round Loop\|### Round" "$REF_MD"; then has_round=true; fi
if grep -q "Human Clarification" "$REF_MD"; then has_clarification=true; fi
if grep -q "Result Recording" "$REF_MD"; then has_recording=true; fi
if grep -q "ADR" "$REF_MD"; then has_adr=true; fi
if $has_workflow && $has_round && $has_clarification && $has_recording && $has_adr; then
  pass "TC-02: reference.md has Debate Workflow with all 5 subsections"
else
  fail "TC-02: reference.md missing Debate Workflow subsections (workflow=$has_workflow round=$has_round clarification=$has_clarification recording=$has_recording adr=$has_adr)"
fi

# TC-03: reference.md codex exec commands include --full-auto
echo ""
echo "TC-03: codex exec with --full-auto"
if grep "codex exec" "$REF_MD" | grep -q "\-\-full-auto"; then
  pass "TC-03: codex exec commands include --full-auto"
else
  fail "TC-03: codex exec commands missing --full-auto flag"
fi

# TC-04: reference.md has resume --last pattern
echo ""
echo "TC-04: resume --last pattern"
if grep -q "resume --last" "$REF_MD"; then
  pass "TC-04: reference.md has resume --last pattern"
else
  fail "TC-04: reference.md missing resume --last pattern"
fi

# TC-05: reference.md has max 3 rounds convergence condition
echo ""
echo "TC-05: max 3 rounds convergence"
if grep -q "max 3\|3.*round\|3.*ラウンド" "$REF_MD"; then
  pass "TC-05: reference.md has max 3 rounds convergence condition"
else
  fail "TC-05: reference.md missing max 3 rounds convergence condition"
fi

# TC-06: reference.md has ADR template and creation conditions
echo ""
echo "TC-06: ADR template and conditions"
has_template=false
has_conditions=false
if grep -q "ADR-NNN\|# ADR-" "$REF_MD"; then has_template=true; fi
if grep -q "ADR.*作成条件\|以下の場合のみ.*ADR\|ADR.*条件" "$REF_MD"; then has_conditions=true; fi
if $has_template && $has_conditions; then
  pass "TC-06: reference.md has ADR template and creation conditions"
else
  fail "TC-06: reference.md missing ADR template ($has_template) or creation conditions ($has_conditions)"
fi

# TC-07: ROADMAP.md Phase 2 status updated
echo ""
echo "TC-07: ROADMAP Phase 2 status"
if grep -q "Phase 2.*DONE\|Phase 2.*in-progress\|Phase 2.*IN-PROGRESS\|Phase 2.*In Progress" "$ROADMAP"; then
  pass "TC-07: ROADMAP Phase 2 status updated"
else
  fail "TC-07: ROADMAP Phase 2 not marked as DONE or in-progress"
fi

# TC-08: kickoff SKILL.md under 100 lines
echo ""
echo "TC-08: SKILL.md line count"
line_count=$(wc -l < "$SKILL_MD" | tr -d ' ')
if [ "$line_count" -le 100 ]; then
  pass "TC-08: SKILL.md is $line_count lines (max 100)"
else
  fail "TC-08: SKILL.md is $line_count lines (exceeds 100)"
fi

# TC-09: Codex absence fallback to plan-review documented in SKILL.md
echo ""
echo "TC-09: Codex absence plan-review fallback"
if grep -q "which codex\|コマンド.*確認\|利用可能.*確認" "$SKILL_MD" && grep -q "plan-review\|review.*plan\|既存.*review" "$SKILL_MD"; then
  pass "TC-09: SKILL.md documents Codex absence plan-review fallback"
else
  fail "TC-09: SKILL.md missing Codex absence plan-review fallback"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
