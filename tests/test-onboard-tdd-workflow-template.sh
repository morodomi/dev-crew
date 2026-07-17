#!/bin/bash
# test-onboard-tdd-workflow-template.sh - TDD Workflow + Codex Integration template tests
# TC-01 ~ TC-08, TC-C2-2

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

# TC-01: Given onboard reference.md distributes the new-order AGENTS.md template,
# When extracting the AGENTS.md TDD Workflow template block (section extraction, not
# whole-file grep) and comparing it against the canonical Workflow line in AGENTS.md,
# Then the template Workflow line matches AGENTS.md verbatim and the stale
# "sync-plan → plan-review" ordering is absent from that block
echo "TC-01: TDD Workflow literal template matches canonical AGENTS.md order"

AGENTS_MD="$BASE_DIR/AGENTS.md"
CANONICAL_WORKFLOW_LINE=$(awk '
  /^## TDD Workflow/ { f = 1; next }
  f && /^```/ { c++; if (c == 2) exit; next }
  f && c == 1 { print; exit }
' "$AGENTS_MD")

AGENTS_TEMPLATE_BLOCK=$(awk '
  /^```markdown/ { capturing = 1; buf = ""; next }
  capturing && /^```$/ {
    if (index(buf, "## TDD Workflow") > 0) { print buf; exit }
    capturing = 0
  }
  capturing { buf = buf $0 "\n" }
' "$REFERENCE_FILE")

if [ -z "$CANONICAL_WORKFLOW_LINE" ]; then
  fail "TC-01: could not extract canonical Workflow line from AGENTS.md (## TDD Workflow section)"
elif [ -z "$AGENTS_TEMPLATE_BLOCK" ]; then
  fail "TC-01: could not extract AGENTS.md template block from reference.md (## TDD Workflow marker not found)"
else
  has_canonical=$(printf '%s\n' "$AGENTS_TEMPLATE_BLOCK" | grep -cFx "$CANONICAL_WORKFLOW_LINE" || true)
  has_stale=$(printf '%s\n' "$AGENTS_TEMPLATE_BLOCK" | grep -cF 'sync-plan → plan-review' || true)
  [ -z "$has_canonical" ] && has_canonical=0
  [ -z "$has_stale" ] && has_stale=0
  if [ "$has_canonical" -ge 1 ] && [ "$has_stale" -eq 0 ]; then
    pass "TC-01: onboard template Workflow line matches AGENTS.md canonical order, stale order absent"
  else
    fail "TC-01: onboard template mismatch (canonical_match=$has_canonical stale_hits=$has_stale)"
  fi
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

# TC-C2-2: Given the Codex セッション作成 bullet is updated to read-only
# on both sides, When extracting that bullet item from reference.md,
# Then (a) the initial review-plan invocation uses --sandbox read-only, (b) the resume
# invocation uses --sandbox read-only, (c) --full-auto is absent from that bullet, and
# (d) the general --full-auto invocation elsewhere in reference.md (non-review-plan
# usage) is retained
echo ""
echo "TC-C2-2: Codex セッション作成 bullet uses read-only both sides, --full-auto absent; general --full-auto retained"

CODEX_SESSION_SECTION=$(awk '
  index($0, "**Codex セッション作成**") > 0 { capture = 1; print; next }
  capture && /^- \*\*/ { exit }
  capture && /^#/ { exit }
  capture { print }
' "$REFERENCE_FILE")

if [ -z "$CODEX_SESSION_SECTION" ]; then
  fail "TC-C2-2: Codex セッション作成 bullet not found (extraction failed)"
else
  c2_ok=1
  if ! printf '%s\n' "$CODEX_SESSION_SECTION" | grep -qF 'codex exec --sandbox read-only "review plan'; then
    fail "TC-C2-2a: initial review-plan invocation is not --sandbox read-only"
    c2_ok=0
  fi
  if ! printf '%s\n' "$CODEX_SESSION_SECTION" | grep -qF 'codex exec --sandbox read-only resume'; then
    fail "TC-C2-2b: resume invocation is not --sandbox read-only"
    c2_ok=0
  fi
  if printf '%s\n' "$CODEX_SESSION_SECTION" | grep -qF -- '--full-auto'; then
    fail "TC-C2-2c: --full-auto still present in Codex セッション作成 bullet"
    c2_ok=0
  fi
  general_count=$(grep -cF 'codex exec --full-auto' "$REFERENCE_FILE" || true)
  [ -z "$general_count" ] && general_count=0
  if [ "$general_count" -lt 1 ]; then
    fail "TC-C2-2d: general 'codex exec --full-auto' invocation (Codex Integration bullet, non-review-plan usage) missing from reference.md"
    c2_ok=0
  fi
  [ "$c2_ok" -eq 1 ] && pass "TC-C2-2: Codex セッション作成 bullet read-only both sides + --full-auto absent + general retained"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
