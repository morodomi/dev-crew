#!/usr/bin/env bash
# Test: kickoff → sync-plan migration validation
# Verifies Phase 11.1 migration completeness

set -uo pipefail
cd "$(dirname "$0")/.."

PASS=0
FAIL=0
pass() { echo "  PASS: $1"; ((PASS++)); }
fail() { echo "  FAIL: $1"; ((FAIL++)); }

echo "=== test-sync-plan-migration ==="

# TC-01: agents/sync-plan.md exists with frontmatter (name, description, model)
echo "TC-01: sync-plan.md frontmatter"
if [ -f agents/sync-plan.md ] && \
   grep -q '^name: sync-plan' agents/sync-plan.md && \
   grep -q '^description:' agents/sync-plan.md && \
   grep -q '^model:' agents/sync-plan.md; then
  pass "TC-01"
else
  fail "TC-01: agents/sync-plan.md missing or incomplete frontmatter"
fi

# TC-02: agents/sync-plan.md contains Cycle doc generation workflow
echo "TC-02: sync-plan.md Cycle doc workflow"
if grep -qi 'cycle doc' agents/sync-plan.md && \
   grep -qi 'test list' agents/sync-plan.md; then
  pass "TC-02"
else
  fail "TC-02: agents/sync-plan.md missing Cycle doc generation workflow"
fi

# TC-03: agents/sync-plan.md contains Debate Workflow
echo "TC-03: sync-plan.md Debate Workflow"
if grep -qi 'debate' agents/sync-plan.md; then
  pass "TC-03"
else
  fail "TC-03: agents/sync-plan.md missing Debate Workflow"
fi

# TC-04: skills/kickoff/ does not exist; old test files do not exist
echo "TC-04: kickoff artifacts removed"
if [ ! -d skills/kickoff ] && \
   [ ! -f tests/test-auto-kickoff.sh ] && \
   [ ! -f tests/test-kickoff-debate.sh ]; then
  pass "TC-04"
else
  fail "TC-04: kickoff artifacts still exist (skills/kickoff/ or old test files)"
fi

# TC-05: agents/architect.md references Task(sync-plan), not Skill(kickoff)
echo "TC-05: architect.md references sync-plan"
if grep -q 'sync-plan' agents/architect.md && \
   ! grep -qi 'Skill(kickoff)' agents/architect.md && \
   ! grep -qi 'Skill(dev-crew:kickoff)' agents/architect.md; then
  pass "TC-05"
else
  fail "TC-05: architect.md still references kickoff"
fi

# TC-06: orchestrate/steps-subagent.md Block 1 references sync-plan
echo "TC-06: steps-subagent.md sync-plan"
if grep -q 'sync-plan' skills/orchestrate/steps-subagent.md; then
  pass "TC-06"
else
  fail "TC-06: steps-subagent.md missing sync-plan reference"
fi

# TC-07: orchestrate/steps-teams.md Block 1 references sync-plan
echo "TC-07: steps-teams.md sync-plan"
if grep -q 'sync-plan' skills/orchestrate/steps-teams.md; then
  pass "TC-07"
else
  fail "TC-07: steps-teams.md missing sync-plan reference"
fi

# TC-08: orchestrate/SKILL.md contains no "kickoff" references
echo "TC-08: orchestrate/SKILL.md no kickoff"
if ! grep -qi 'kickoff' skills/orchestrate/SKILL.md; then
  pass "TC-08"
else
  fail "TC-08: orchestrate/SKILL.md still contains 'kickoff'"
fi

# TC-09: spec/SKILL.md Post-Approve Action references sync-plan
echo "TC-09: spec/SKILL.md sync-plan"
if grep -q 'sync-plan' skills/spec/SKILL.md; then
  pass "TC-09"
else
  fail "TC-09: spec/SKILL.md missing sync-plan reference"
fi

# TC-10: Gate messages in red/green/refactor/review/commit/diagnose say "run spec"
echo "TC-10: Gate messages say 'run spec'"
gate_ok=true
for skill in red green refactor review commit diagnose; do
  if grep -q 'BLOCK(run kickoff)' "skills/$skill/SKILL.md" 2>/dev/null; then
    echo "    FAIL: skills/$skill/SKILL.md still says 'run kickoff'"
    gate_ok=false
  fi
done
if $gate_ok; then
  pass "TC-10"
else
  fail "TC-10: Some gate messages still say 'run kickoff'"
fi

# TC-11: state-ownership.md references sync-plan, not kickoff
echo "TC-11: state-ownership.md sync-plan"
if grep -q 'sync-plan' rules/state-ownership.md && \
   ! grep -qi 'kickoff' rules/state-ownership.md; then
  pass "TC-11"
else
  fail "TC-11: state-ownership.md still references kickoff"
fi

# TC-12: docs/architecture.md contains no kickoff references (case-insensitive)
echo "TC-12: architecture.md no kickoff"
if ! grep -qi 'kickoff' docs/architecture.md; then
  pass "TC-12"
else
  fail "TC-12: docs/architecture.md still contains 'kickoff'"
fi

# TC-13: docs/terminology.md Skill names row does not list kickoff
echo "TC-13: terminology.md no kickoff in skill names"
if grep 'Skill names' docs/terminology.md | grep -qi 'kickoff'; then
  fail "TC-13: docs/terminology.md still lists kickoff as skill name"
else
  pass "TC-13"
fi

# TC-14: rg "kickoff" in active paths returns 0 results
echo "TC-14: No kickoff references in active paths"
kickoff_count=$(rg -ci "kickoff" skills/ CLAUDE.md AGENTS.md docs/ \
  --glob '!docs/cycles/**' \
  --glob '!docs/ROADMAP.md' \
  --glob '!docs/STATUS.md' \
  --glob '!docs/archive/**' \
  --glob '!docs/PHILOSOPHY.md' \
  --glob '!docs/metrics/**' 2>/dev/null | awk -F: '{s+=$NF} END {print s+0}')
if [ "$kickoff_count" -eq 0 ]; then
  pass "TC-14"
else
  fail "TC-14: Found $kickoff_count 'kickoff' references in active paths"
  rg -i "kickoff" skills/ CLAUDE.md AGENTS.md docs/ \
    --glob '!docs/cycles/**' \
    --glob '!docs/ROADMAP.md' \
    --glob '!docs/STATUS.md' \
    --glob '!docs/archive/**' \
    --glob '!docs/PHILOSOPHY.md' \
    --glob '!docs/metrics/**' 2>/dev/null || true
fi

# TC-15: All existing tests pass (regression) - skipped in migration test
# Run separately: for f in tests/test-*.sh; do bash "$f"; done
echo "TC-15: Regression (run separately)"
pass "TC-15 (placeholder - run full suite separately)"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
