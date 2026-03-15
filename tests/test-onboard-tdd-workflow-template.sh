#!/bin/bash
# test-onboard-tdd-workflow-template.sh - TDD Workflow + Codex Integration template tests
# TC-01 ~ TC-08

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

REFERENCE_FILE="$BASE_DIR/skills/onboard/reference.md"
[ -f "$REFERENCE_FILE" ] || { echo "ERROR: $REFERENCE_FILE not found"; exit 1; }

REF_CONTENT=$(cat "$REFERENCE_FILE")

echo "=== Onboard TDD Workflow Template Tests ==="
echo ""

# TC-01: Given reference.md, When reading AGENTS.md template section,
# Then TDD Workflow literal template with "spec → sync-plan → plan-review → RED" exists
echo "TC-01: TDD Workflow literal template has correct workflow line"
if echo "$REF_CONTENT" | grep -q 'spec → sync-plan → plan-review → RED'; then
  pass "TC-01: TDD Workflow template has 'spec → sync-plan → plan-review → RED'"
else
  fail "TC-01: TDD Workflow template missing 'spec → sync-plan → plan-review → RED'"
fi

# TC-02: Given reference.md TDD Workflow template,
# Then it does NOT contain "KICKOFF"
echo ""
echo "TC-02: TDD Workflow template does NOT contain KICKOFF"
# Extract the TDD Workflow template block (between the template markers)
TDD_TEMPLATE=$(echo "$REF_CONTENT" | sed -n '/## TDD Workflow/,/^```$/p' | head -20)
if echo "$TDD_TEMPLATE" | grep -qi 'KICKOFF'; then
  fail "TC-02: TDD Workflow template contains KICKOFF (should not)"
else
  pass "TC-02: TDD Workflow template does not contain KICKOFF"
fi

# TC-03: Given reference.md, When reading CLAUDE.md template section,
# Then Codex Integration literal template exists
echo ""
echo "TC-03: Codex Integration literal template exists"
if echo "$REF_CONTENT" | grep -q 'codex exec --full-auto'; then
  pass "TC-03: Codex Integration template has 'codex exec --full-auto'"
else
  fail "TC-03: Codex Integration template missing 'codex exec --full-auto'"
fi

# TC-04: Given reference.md Codex Integration template,
# Then "Auto-orchestrate" trigger line exists
echo ""
echo "TC-04: Codex Integration template has Auto-orchestrate trigger"
if echo "$REF_CONTENT" | grep -q 'Auto-orchestrate after plan approve'; then
  pass "TC-04: Auto-orchestrate trigger found"
else
  fail "TC-04: Auto-orchestrate trigger missing"
fi

# TC-05: Given reference.md CLAUDE.md merge strategy,
# Then it allows 3 sections (not just 2)
echo ""
echo "TC-05: CLAUDE.md merge strategy allows 3 sections"
if echo "$REF_CONTENT" | grep -q '最大3セクション\|max 3'; then
  pass "TC-05: CLAUDE.md merge strategy allows 3 sections"
else
  fail "TC-05: CLAUDE.md merge strategy still limited to 2 sections"
fi

# TC-06: Given reference.md Codex Integration template,
# Then "codex review は使わない" is present
echo ""
echo "TC-06: Codex Integration template has 'codex review は使わない'"
if echo "$REF_CONTENT" | grep -q 'codex review.*は使わない'; then
  pass "TC-06: 'codex review は使わない' found"
else
  fail "TC-06: 'codex review は使わない' missing"
fi

# TC-07: Regression - AGENTS.md merge strategy max 5 sections still stated
echo ""
echo "TC-07: Regression - AGENTS.md merge strategy max 5 sections preserved"
if echo "$REF_CONTENT" | grep -q '最大5セクション'; then
  pass "TC-07: AGENTS.md max 5 sections preserved"
else
  fail "TC-07: AGENTS.md max 5 sections not found"
fi

# TC-08: Regression - @AGENTS.md import template preserved
echo ""
echo "TC-08: Regression - @AGENTS.md import template preserved"
if echo "$REF_CONTENT" | grep -q '@AGENTS.md'; then
  pass "TC-08: @AGENTS.md import template preserved"
else
  fail "TC-08: @AGENTS.md import template missing"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
