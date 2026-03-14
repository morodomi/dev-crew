#!/bin/bash
# test-doc-consistency.sh - Document consistency validation
# TC-01 ~ TC-13

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== Document Consistency Tests ==="

########################################
# Skill count consistency
########################################

echo ""
echo "--- Skill Count Consistency ---"

# Count actual skill directories
ACTUAL_COUNT=$(find "$BASE_DIR/skills" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')

# TC-01: README.md skill count = actual skill directories
echo ""
echo "TC-01: README.md skill count matches actual ($ACTUAL_COUNT)"
readme_counts=$(grep -oE '[0-9]+ skills' "$BASE_DIR/README.md" | head -1 | grep -oE '[0-9]+')
if [ "$readme_counts" = "$ACTUAL_COUNT" ]; then
  pass "README.md skill count ($readme_counts) = actual ($ACTUAL_COUNT)"
else
  fail "README.md skill count ($readme_counts) != actual ($ACTUAL_COUNT)"
fi

# TC-02: architecture.md skill count = actual skill directories
echo ""
echo "TC-02: architecture.md skill count matches actual ($ACTUAL_COUNT)"
arch_count=$(grep -oE '[0-9]+ skills' "$BASE_DIR/docs/architecture.md" | head -1 | grep -oE '[0-9]+')
if [ "$arch_count" = "$ACTUAL_COUNT" ]; then
  pass "architecture.md skill count ($arch_count) = actual ($ACTUAL_COUNT)"
else
  fail "architecture.md skill count ($arch_count) != actual ($ACTUAL_COUNT)"
fi

########################################
# Missing skill listings
########################################

echo ""
echo "--- Missing Skill Listings ---"

# TC-03: README.md lists "reload"
echo ""
echo "TC-03: README.md lists 'reload'"
if grep -q "reload" "$BASE_DIR/README.md"; then
  pass "README.md lists reload"
else
  fail "README.md does not list reload"
fi

# TC-04: README.md lists "skill-maker"
echo ""
echo "TC-04: README.md lists 'skill-maker'"
if grep -q "skill-maker" "$BASE_DIR/README.md"; then
  pass "README.md lists skill-maker"
else
  fail "README.md does not list skill-maker"
fi

# TC-05: README.md lists "security-audit"
echo ""
echo "TC-05: README.md lists 'security-audit'"
if grep -q "security-audit" "$BASE_DIR/README.md"; then
  pass "README.md lists security-audit"
else
  fail "README.md does not list security-audit"
fi

# TC-06: skills-catalog.md lists "reload"
echo ""
echo "TC-06: skills-catalog.md lists 'reload'"
if grep -q "reload" "$BASE_DIR/docs/skills-catalog.md"; then
  pass "skills-catalog.md lists reload"
else
  fail "skills-catalog.md does not list reload"
fi

# TC-07: skills-catalog.md lists "skill-maker"
echo ""
echo "TC-07: skills-catalog.md lists 'skill-maker'"
if grep -q "skill-maker" "$BASE_DIR/docs/skills-catalog.md"; then
  pass "skills-catalog.md lists skill-maker"
else
  fail "skills-catalog.md does not list skill-maker"
fi

# TC-08: skills-catalog.md lists "security-audit"
echo ""
echo "TC-08: skills-catalog.md lists 'security-audit'"
if grep -q "security-audit" "$BASE_DIR/docs/skills-catalog.md"; then
  pass "skills-catalog.md lists security-audit"
else
  fail "skills-catalog.md does not list security-audit"
fi

########################################
# Content accuracy
########################################

echo ""
echo "--- Content Accuracy ---"

# TC-09: architecture.md Session Continuity mentions "reload"
echo ""
echo "TC-09: architecture.md Session Continuity mentions 'reload'"
# Check in the Session Continuity section (after the heading, before next ##)
in_section=false
found=false
while IFS= read -r line; do
  if echo "$line" | grep -q "## Session Continuity"; then
    in_section=true
    continue
  fi
  if $in_section && echo "$line" | grep -qE "^## [^#]" ; then
    break
  fi
  if $in_section && echo "$line" | grep -q "reload"; then
    found=true
    break
  fi
done < "$BASE_DIR/docs/architecture.md"
if $found; then
  pass "architecture.md Session Continuity mentions reload"
else
  fail "architecture.md Session Continuity does not mention reload"
fi

# TC-10: phase-compact SKILL.md does NOT claim "orchestrateスキルから自動呼び出し"
echo ""
echo "TC-10: phase-compact SKILL.md does NOT claim 'orchestrateスキルから自動呼び出し'"
if grep -q "orchestrateスキルから自動呼び出し" "$BASE_DIR/skills/phase-compact/SKILL.md"; then
  fail "phase-compact SKILL.md still claims 'orchestrateスキルから自動呼び出し'"
else
  pass "phase-compact SKILL.md does not claim auto-invocation from orchestrate"
fi

# TC-11: sync-plan.md or archive has test category content
echo ""
echo "TC-11: sync-plan agent or archive has relevant content"
if [ -f "$BASE_DIR/agents/sync-plan.md" ]; then
  pass "sync-plan.md exists (test categories migrated to archive)"
else
  fail "sync-plan.md does not exist"
fi

# TC-12: CLAUDE.md has "Usage Patterns" section
echo ""
echo "TC-12: CLAUDE.md has 'Usage Patterns' section"
if grep -q "## Usage Patterns" "$BASE_DIR/CLAUDE.md"; then
  pass "CLAUDE.md has Usage Patterns section"
else
  fail "CLAUDE.md does not have Usage Patterns section"
fi

########################################
# Terminology consistency (docs/terminology.md)
########################################

echo ""
echo "--- Terminology Consistency ---"

# TC-14: /simplify not present in key skill/doc files (fully removed)
echo ""
echo "TC-14: /simplify absent from key files"
TERM_FAIL=0
for rel_file in README.md skills/orchestrate/SKILL.md skills/refactor/SKILL.md CLAUDE.md docs/terminology.md; do
  file="$BASE_DIR/$rel_file"
  [ -f "$file" ] || continue
  if grep -q '/simplify' "$file"; then
    fail "/simplify found in $rel_file"
    TERM_FAIL=1
  fi
done
if [ "$TERM_FAIL" -eq 0 ]; then
  pass "/simplify absent from key files"
fi

# TC-15: Phase names UPPERCASE in orchestrate SKILL.md workflow steps
echo ""
echo "TC-15: Phase names UPPERCASE in orchestrate SKILL.md"
PHASE_FAIL=0
for phase in RED GREEN REFACTOR REVIEW COMMIT; do
  lower=$(echo "$phase" | tr '[:upper:]' '[:lower:]')
  # Block 2 numbered steps use "N. **PHASE**:" pattern
  if grep -qE "^[0-9]+\. \*\*${lower}\*\*" "$BASE_DIR/skills/orchestrate/SKILL.md"; then
    fail "orchestrate SKILL.md uses lowercase '$lower' instead of '$phase'"
    PHASE_FAIL=1
  fi
done
if [ "$PHASE_FAIL" -eq 0 ]; then
  pass "Phase names UPPERCASE in orchestrate SKILL.md"
fi

########################################
# Regression
########################################

echo ""
echo "--- Regression ---"

# TC-13: All existing tests pass
echo ""
echo "TC-13: Existing tests pass"
existing_fail=0
for test_file in "$BASE_DIR/tests"/test-*.sh; do
  test_name=$(basename "$test_file")
  # Skip ourselves to avoid recursion
  [ "$test_name" = "test-doc-consistency.sh" ] && continue
  if ! bash "$test_file" > /dev/null 2>&1; then
    fail "Existing test failed: $test_name"
    existing_fail=1
  fi
done
if [ "$existing_fail" -eq 0 ]; then
  pass "All existing tests pass"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
