#!/bin/bash
# test-phase-gate.sh - Phase Gate + Progress Log + Commit doc update + Completion validation
# TC-01 ~ TC-22

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RED="$BASE_DIR/skills/red/SKILL.md"
GREEN="$BASE_DIR/skills/green/SKILL.md"
REFACTOR="$BASE_DIR/skills/refactor/SKILL.md"
REVIEW="$BASE_DIR/skills/review/SKILL.md"
COMMIT="$BASE_DIR/skills/commit/SKILL.md"
CYCLE_TMPL="$BASE_DIR/skills/spec/templates/cycle.md"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

for f in "$RED" "$GREEN" "$REFACTOR" "$REVIEW" "$COMMIT" "$CYCLE_TMPL"; do
  [ -f "$f" ] || { echo "FATAL: $f not found"; exit 1; }
done

echo "=== Phase Gate Tests ==="

########################################
# Hard Gate (TC-01 ~ TC-05)
########################################

echo ""
echo "--- Hard Gate ---"

# TC-01: red/SKILL.md has Hard Gate (grep -L 'phase: DONE' pattern)
echo ""
echo "TC-01: red/SKILL.md has Hard Gate"
if grep -q "phase: DONE" "$RED" && grep -q "BLOCK\|kickoff" "$RED"; then
  pass "red/SKILL.md has Hard Gate"
else
  fail "red/SKILL.md missing Hard Gate"
fi

# TC-02: green/SKILL.md has Hard Gate
echo ""
echo "TC-02: green/SKILL.md has Hard Gate"
if grep -q "phase: DONE" "$GREEN" && grep -q "BLOCK\|kickoff" "$GREEN"; then
  pass "green/SKILL.md has Hard Gate"
else
  fail "green/SKILL.md missing Hard Gate"
fi

# TC-03: refactor/SKILL.md has Hard Gate
echo ""
echo "TC-03: refactor/SKILL.md has Hard Gate"
if grep -q "phase: DONE" "$REFACTOR" && grep -q "BLOCK\|kickoff" "$REFACTOR"; then
  pass "refactor/SKILL.md has Hard Gate"
else
  fail "refactor/SKILL.md missing Hard Gate"
fi

# TC-04: review/SKILL.md has Hard Gate
echo ""
echo "TC-04: review/SKILL.md has Hard Gate"
if grep -q "phase: DONE" "$REVIEW" && grep -q "BLOCK\|kickoff" "$REVIEW"; then
  pass "review/SKILL.md has Hard Gate"
else
  fail "review/SKILL.md missing Hard Gate"
fi

# TC-05: commit/SKILL.md has Hard Gate
echo ""
echo "TC-05: commit/SKILL.md has Hard Gate"
if grep -q "phase: DONE" "$COMMIT" && grep -q "BLOCK\|kickoff" "$COMMIT"; then
  pass "commit/SKILL.md has Hard Gate"
else
  fail "commit/SKILL.md missing Hard Gate"
fi

########################################
# Phase Ordering Gate (TC-06 ~ TC-07)
########################################

echo ""
echo "--- Phase Ordering Gate ---"

# TC-06: review/SKILL.md has REFACTOR completion check (Phase Ordering Gate)
echo ""
echo "TC-06: review/SKILL.md has REFACTOR completion check"
if grep -q "Phase Ordering Gate" "$REVIEW" && grep -q "REFACTOR.*Phase completed" "$REVIEW"; then
  pass "review/SKILL.md has REFACTOR ordering gate"
else
  fail "review/SKILL.md missing REFACTOR ordering gate"
fi

# TC-07: commit/SKILL.md has REVIEW completion check (Phase Ordering Gate)
echo ""
echo "TC-07: commit/SKILL.md has REVIEW completion check"
if grep -q "Phase Ordering Gate" "$COMMIT" && grep -q "REVIEW.*Phase completed" "$COMMIT"; then
  pass "commit/SKILL.md has REVIEW ordering gate"
else
  fail "commit/SKILL.md missing REVIEW ordering gate"
fi

########################################
# Progress Log (TC-08 ~ TC-12)
########################################

echo ""
echo "--- Progress Log ---"

# TC-08: red/SKILL.md has Progress Log recording step
echo ""
echo "TC-08: red/SKILL.md has Progress Log recording step"
if grep -q "Progress Log" "$RED" && grep -q "Phase completed" "$RED"; then
  pass "red/SKILL.md has Progress Log step"
else
  fail "red/SKILL.md missing Progress Log step"
fi

# TC-09: green/SKILL.md has Progress Log recording step
echo ""
echo "TC-09: green/SKILL.md has Progress Log recording step"
if grep -q "Progress Log" "$GREEN" && grep -q "Phase completed" "$GREEN"; then
  pass "green/SKILL.md has Progress Log step"
else
  fail "green/SKILL.md missing Progress Log step"
fi

# TC-10: refactor/SKILL.md has Progress Log recording step
echo ""
echo "TC-10: refactor/SKILL.md has Progress Log recording step"
if grep -q "Progress Log" "$REFACTOR" && grep -q "Phase completed" "$REFACTOR"; then
  pass "refactor/SKILL.md has Progress Log step"
else
  fail "refactor/SKILL.md missing Progress Log step"
fi

# TC-11: review/SKILL.md has Progress Log recording step
echo ""
echo "TC-11: review/SKILL.md has Progress Log recording step"
if grep -q "Progress Log" "$REVIEW" && grep -q "Phase completed" "$REVIEW"; then
  pass "review/SKILL.md has Progress Log step"
else
  fail "review/SKILL.md missing Progress Log step"
fi

# TC-12: commit/SKILL.md has Progress Log recording step
echo ""
echo "TC-12: commit/SKILL.md has Progress Log recording step"
if grep -q "Progress Log" "$COMMIT" && grep -q "Phase completed" "$COMMIT"; then
  pass "commit/SKILL.md has Progress Log step"
else
  fail "commit/SKILL.md missing Progress Log step"
fi

########################################
# Commit Doc Updates (TC-13)
########################################

echo ""
echo "--- Commit Doc Updates ---"

# TC-13: commit/SKILL.md has README.md/AGENTS.md/CLAUDE.md update step
echo ""
echo "TC-13: commit/SKILL.md has README.md/AGENTS.md/CLAUDE.md update step"
if grep -q "README.md" "$COMMIT" && grep -q "CLAUDE.md" "$COMMIT" && grep -q "AGENTS.md" "$COMMIT"; then
  pass "commit/SKILL.md has README.md/AGENTS.md/CLAUDE.md update"
else
  fail "commit/SKILL.md missing README.md/AGENTS.md/CLAUDE.md update"
fi

########################################
# allowed-tools (TC-14 ~ TC-15)
########################################

echo ""
echo "--- allowed-tools ---"

# TC-14: review/SKILL.md allowed-tools has Edit
echo ""
echo "TC-14: review/SKILL.md allowed-tools has Edit"
if grep "^allowed-tools:" "$REVIEW" | grep -q "Edit"; then
  pass "review/SKILL.md allowed-tools has Edit"
else
  fail "review/SKILL.md allowed-tools missing Edit"
fi

# TC-15: commit/SKILL.md allowed-tools has Write and Edit
echo ""
echo "TC-15: commit/SKILL.md allowed-tools has Write and Edit"
if grep "^allowed-tools:" "$COMMIT" | grep -q "Write" && \
   grep "^allowed-tools:" "$COMMIT" | grep -q "Edit"; then
  pass "commit/SKILL.md allowed-tools has Write and Edit"
else
  fail "commit/SKILL.md allowed-tools missing Write and/or Edit"
fi

########################################
# Cycle Template (TC-16)
########################################

echo ""
echo "--- Cycle Template ---"

# TC-16: cycle.md template has Progress Log standard format
echo ""
echo "TC-16: cycle.md template has Progress Log standard format"
if grep -q "Progress Log" "$CYCLE_TMPL" && grep -q "PHASE_NAME\|Phase completed" "$CYCLE_TMPL"; then
  pass "cycle.md has Progress Log standard format"
else
  fail "cycle.md missing Progress Log standard format"
fi

########################################
# Line Count (TC-17)
########################################

echo ""
echo "--- Line Count ---"

# TC-17: All modified SKILL.md files are under 100 lines
echo ""
echo "TC-17: SKILL.md files under 100 lines"
ALL_UNDER=true
for f in "$RED" "$GREEN" "$REFACTOR" "$REVIEW" "$COMMIT"; do
  lines=$(wc -l < "$f")
  if [ "$lines" -gt 100 ]; then
    fail "$(basename "$(dirname "$f")")/SKILL.md is $lines lines (max 100)"
    ALL_UNDER=false
  fi
done
if $ALL_UNDER; then
  pass "All SKILL.md files under 100 lines"
fi

########################################
# STATUS.md (TC-18)
########################################

echo ""
echo "--- STATUS.md ---"

# TC-18: commit/SKILL.md has STATUS.md update condition (always)
echo ""
echo "TC-18: commit/SKILL.md has STATUS.md update condition"
if grep -q "STATUS.md" "$COMMIT"; then
  pass "commit/SKILL.md has STATUS.md update"
else
  fail "commit/SKILL.md missing STATUS.md update"
fi

########################################
# Commit Completion Validation (TC-19 ~ TC-22)
########################################

echo ""
echo "--- Commit Completion Validation ---"

COMMIT_REF="$BASE_DIR/skills/commit/reference.md"
[ -f "$COMMIT_REF" ] || { echo "FATAL: $COMMIT_REF not found"; exit 1; }

# TC-19: commit/SKILL.md has Test List Completion Gate
echo ""
echo "TC-19: commit/SKILL.md has Test List Completion Gate"
if grep -q "Test List Completion" "$COMMIT" && grep -q "BLOCK" "$COMMIT"; then
  pass "commit/SKILL.md has Test List Completion Gate"
else
  fail "commit/SKILL.md missing Test List Completion Gate"
fi

# TC-20: commit/reference.md has Test List Completion Gate details
echo ""
echo "TC-20: commit/reference.md has Test List Completion Gate details"
if grep -q "Test List Completion" "$COMMIT_REF" && grep -q "TODO\|WIP\|DISCOVERED" "$COMMIT_REF"; then
  pass "commit/reference.md has Test List Completion Gate details"
else
  fail "commit/reference.md missing Test List Completion Gate details"
fi

# TC-21: commit/SKILL.md has Progress Log Completeness Gate
echo ""
echo "TC-21: commit/SKILL.md has Progress Log Completeness Gate"
if grep -q "Progress Log Completeness" "$COMMIT" && grep -q "KICKOFF.*RED.*GREEN.*REFACTOR.*REVIEW\|5.*Phase completed\|5フェーズ\|全フェーズ" "$COMMIT"; then
  pass "commit/SKILL.md has Progress Log Completeness Gate"
else
  fail "commit/SKILL.md missing Progress Log Completeness Gate"
fi

# TC-22: commit/reference.md has Progress Log Completeness Gate details
echo ""
echo "TC-22: commit/reference.md has Progress Log Completeness Gate details"
if grep -q "Progress Log Completeness" "$COMMIT_REF" && grep -q "KICKOFF" "$COMMIT_REF" && grep -q "RED" "$COMMIT_REF" && grep -q "GREEN" "$COMMIT_REF" && grep -q "REFACTOR" "$COMMIT_REF" && grep -q "REVIEW" "$COMMIT_REF"; then
  pass "commit/reference.md has Progress Log Completeness Gate details"
else
  fail "commit/reference.md missing Progress Log Completeness Gate details"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
