#!/bin/bash
# test-precompact-reload.sh - PreCompact Hook + reload skill validation
# TC-01 ~ TC-14

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HOOKS_FILE="$BASE_DIR/hooks/hooks.json"
SCRIPT_FILE="$BASE_DIR/scripts/hooks/pre-compact.sh"
RELOAD_DIR="$BASE_DIR/skills/reload"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

get_frontmatter() {
  local file="$1"
  local key="$2"
  awk '/^---$/{n++; next} n==1{print}' "$file" | grep "^${key}: " | head -1 | sed "s/^${key}: *//" || true
}

echo "=== PreCompact Hook + Reload Skill Tests ==="

########################################
# hooks.json: PreCompact entry
########################################

echo ""
echo "--- hooks.json: PreCompact Hook ---"

# TC-01: hooks.json has PreCompact entry
echo ""
echo "TC-01: hooks.json has PreCompact entry"
if jq -e '.hooks.PreCompact' "$HOOKS_FILE" >/dev/null 2>&1; then
  pass "PreCompact entry exists in hooks.json"
else
  fail "PreCompact entry not found in hooks.json"
fi

# TC-02: PreCompact matcher is "manual"
echo ""
echo "TC-02: PreCompact matcher is 'manual'"
matcher=$(jq -r '.hooks.PreCompact[0].matcher // ""' "$HOOKS_FILE" 2>/dev/null || true)
if [ "$matcher" = "manual" ]; then
  pass "PreCompact matcher is 'manual'"
else
  fail "PreCompact matcher is '$matcher' (expected 'manual')"
fi

# TC-03: PreCompact command references pre-compact.sh with ${CLAUDE_PLUGIN_ROOT}
echo ""
echo "TC-03: PreCompact command uses \${CLAUDE_PLUGIN_ROOT}"
cmd=$(jq -r '.hooks.PreCompact[0].hooks[0].command // ""' "$HOOKS_FILE" 2>/dev/null || true)
if echo "$cmd" | grep -q '${CLAUDE_PLUGIN_ROOT}.*pre-compact.sh'; then
  pass "PreCompact command uses \${CLAUDE_PLUGIN_ROOT}/scripts/hooks/pre-compact.sh"
else
  fail "PreCompact command does not reference pre-compact.sh with \${CLAUDE_PLUGIN_ROOT} (got: '$cmd')"
fi

########################################
# scripts/hooks/pre-compact.sh
########################################

echo ""
echo "--- scripts/hooks/pre-compact.sh ---"

# TC-04: pre-compact.sh exists and is executable
echo ""
echo "TC-04: pre-compact.sh exists and is executable"
if [ -x "$SCRIPT_FILE" ]; then
  pass "pre-compact.sh exists and is executable"
else
  fail "pre-compact.sh does not exist or is not executable"
fi

# TC-05: pre-compact.sh exits 0 when no Cycle doc exists
echo ""
echo "TC-05: pre-compact.sh exits 0 when no Cycle doc exists"
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT
mkdir -p "$TEMP_DIR/docs/cycles"
# Run with empty cycles dir
if (cd "$TEMP_DIR" && bash "$SCRIPT_FILE") 2>/dev/null; then
  pass "pre-compact.sh exits 0 with no Cycle doc"
else
  fail "pre-compact.sh exits non-zero with no Cycle doc"
fi

# TC-06: pre-compact.sh appends Progress Log entry when Cycle doc exists
echo ""
echo "TC-06: pre-compact.sh appends Progress Log entry when Cycle doc exists"
# Create a minimal Cycle doc with phase info
cat > "$TEMP_DIR/docs/cycles/20260224_test.md" <<'CYCLEDOC'
# Cycle: Test

- status: GREEN

## PLAN

### Design
Test design

## Progress Log
CYCLEDOC

before_lines=$(wc -l < "$TEMP_DIR/docs/cycles/20260224_test.md" | tr -d ' ')
(cd "$TEMP_DIR" && bash "$SCRIPT_FILE") 2>/dev/null
after_lines=$(wc -l < "$TEMP_DIR/docs/cycles/20260224_test.md" | tr -d ' ')
if [ "$after_lines" -gt "$before_lines" ]; then
  pass "pre-compact.sh appended to Progress Log"
else
  fail "pre-compact.sh did not append to Progress Log ($before_lines -> $after_lines lines)"
fi

# TC-07: Progress Log entry contains phase and timestamp
echo ""
echo "TC-07: Progress Log entry contains phase and timestamp"
log_entry=$(tail -1 "$TEMP_DIR/docs/cycles/20260224_test.md")
if echo "$log_entry" | grep -qE 'PreCompact.*phase=.*GREEN' && \
   echo "$log_entry" | grep -qE '[0-9]{4}-[0-9]{2}-[0-9]{2}'; then
  pass "Progress Log entry contains phase and timestamp"
else
  fail "Progress Log entry format incorrect (got: '$log_entry')"
fi

########################################
# skills/reload/
########################################

echo ""
echo "--- skills/reload/ ---"

# TC-08: skills/reload/ directory exists
echo ""
echo "TC-08: skills/reload/ directory exists"
if [ -d "$RELOAD_DIR" ]; then
  pass "skills/reload/ exists"
else
  fail "skills/reload/ not found"
fi

# TC-09: reload SKILL.md exists and < 100 lines
echo ""
echo "TC-09: reload SKILL.md exists and < 100 lines"
if [ -f "$RELOAD_DIR/SKILL.md" ]; then
  line_count=$(wc -l < "$RELOAD_DIR/SKILL.md" | tr -d ' ')
  if [ "$line_count" -le 100 ]; then
    pass "SKILL.md exists ($line_count lines)"
  else
    fail "SKILL.md has $line_count lines (max 100)"
  fi
else
  fail "SKILL.md not found"
fi

# TC-10: reload SKILL.md has name/description frontmatter
echo ""
echo "TC-10: reload SKILL.md frontmatter"
if [ -f "$RELOAD_DIR/SKILL.md" ]; then
  name_val=$(get_frontmatter "$RELOAD_DIR/SKILL.md" "name")
  desc_val=$(get_frontmatter "$RELOAD_DIR/SKILL.md" "description")
  if [ -n "$name_val" ] && [ -n "$desc_val" ]; then
    pass "frontmatter: name='$name_val'"
  else
    [ -z "$name_val" ] && fail "missing 'name' frontmatter"
    [ -z "$desc_val" ] && fail "missing 'description' frontmatter"
  fi
else
  fail "SKILL.md not found"
fi

# TC-11: reload SKILL.md contains Workflow section
echo ""
echo "TC-11: reload SKILL.md Workflow section"
if [ -f "$RELOAD_DIR/SKILL.md" ]; then
  if grep -q "## Workflow" "$RELOAD_DIR/SKILL.md"; then
    pass "Workflow section present"
  else
    fail "Workflow section missing"
  fi
else
  fail "SKILL.md not found"
fi

# TC-12: reload SKILL.md references Cycle doc loading
echo ""
echo "TC-12: reload SKILL.md references Cycle doc"
if [ -f "$RELOAD_DIR/SKILL.md" ]; then
  if grep -qi "cycle doc\|Cycle doc" "$RELOAD_DIR/SKILL.md"; then
    pass "Cycle doc reference found"
  else
    fail "Cycle doc reference not found"
  fi
else
  fail "SKILL.md not found"
fi

########################################
# Structural validation
########################################

echo ""
echo "--- Structural validation ---"

# TC-13: hooks.json is valid JSON
echo ""
echo "TC-13: hooks.json is valid JSON"
if jq empty "$HOOKS_FILE" 2>/dev/null; then
  pass "hooks.json is valid JSON"
else
  fail "hooks.json is invalid JSON"
fi

# TC-14: Existing structure validation still passes
echo ""
echo "TC-14: Existing structure validation"
if bash "$BASE_DIR/tests/test-skills-structure.sh" > /dev/null 2>&1; then
  pass "Structure validation passes"
else
  fail "Structure validation failed"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
