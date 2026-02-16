#!/bin/bash
# test-designer-agent.sh - Designer agent validation
# TC-01 ~ TC-09

set -euo pipefail

# Constants
BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DESIGNER_FILE="$BASE_DIR/agents/designer.md"
PATTERN_COUNT=12
EXPECTED_AGENT_NAME="designer"

# Test result counters
PASS=0
FAIL=0

# Test result helpers
pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

# Extract frontmatter value from a markdown file
# Returns empty string if not found
get_frontmatter() {
  local file="$1"
  local key="$2"
  # Read between first --- and second ---
  awk '/^---$/{n++; next} n==1{print}' "$file" | grep "^${key}: " | head -1 | sed "s/^${key}: *//" || true
}

echo "=== Designer Agent Tests ==="

########################################
# TC-01: Frontmatter validation
########################################
echo ""
echo "TC-01: designer.md exists with valid frontmatter"
if [ -f "$DESIGNER_FILE" ]; then
  name_val=$(get_frontmatter "$DESIGNER_FILE" "name")
  desc_val=$(get_frontmatter "$DESIGNER_FILE" "description")

  if [ -n "$name_val" ] && [ -n "$desc_val" ]; then
    pass "TC-01: designer.md has valid frontmatter (name, description)"
  else
    fail "TC-01: designer.md missing 'name' or 'description' in frontmatter"
  fi
else
  fail "TC-01: agents/designer.md does not exist"
fi

########################################
# TC-02: Agent name validation
########################################

echo ""
echo "TC-02: designer.md name is '$EXPECTED_AGENT_NAME'"
if [ -f "$DESIGNER_FILE" ]; then
  name_val=$(get_frontmatter "$DESIGNER_FILE" "name")
  if [ "$name_val" = "$EXPECTED_AGENT_NAME" ]; then
    pass "TC-02: name is '$EXPECTED_AGENT_NAME'"
  else
    fail "TC-02: name is '$name_val' (expected '$EXPECTED_AGENT_NAME')"
  fi
else
  fail "TC-02: designer.md does not exist"
fi

########################################
# TC-03: Pattern IDs validation
########################################

echo ""
echo "TC-03: All $PATTERN_COUNT pattern IDs (P-01~P-12) referenced"
if [ -f "$DESIGNER_FILE" ]; then
  missing_patterns=0
  for i in $(seq -f "%02g" 1 "$PATTERN_COUNT"); do
    if ! grep -q "P-$i" "$DESIGNER_FILE"; then
      fail "TC-03: Pattern P-$i not found in designer.md"
      missing_patterns=$((missing_patterns + 1))
    fi
  done

  if [ "$missing_patterns" -eq 0 ]; then
    pass "TC-03: All $PATTERN_COUNT patterns (P-01~P-12) referenced"
  fi
else
  fail "TC-03: designer.md does not exist"
fi

########################################
# TC-04: Categories validation
########################################

echo ""
echo "TC-04: Four categories referenced"
# Define expected categories as data
CATEGORIES=(
  "Visual Design"
  "Information Architecture"
  "Interaction Design"
  "Trust"
)

if [ -f "$DESIGNER_FILE" ]; then
  missing_categories=0
  for category in "${CATEGORIES[@]}"; do
    if ! grep -q "$category" "$DESIGNER_FILE"; then
      fail "TC-04: Category '$category' not found"
      missing_categories=$((missing_categories + 1))
    fi
  done

  if [ "$missing_categories" -eq 0 ]; then
    pass "TC-04: All ${#CATEGORIES[@]} categories referenced"
  fi
else
  fail "TC-04: designer.md does not exist"
fi

########################################
# TC-05: Role boundary validation
########################################

echo ""
echo "TC-05: Role boundary with usability-reviewer"
if [ -f "$DESIGNER_FILE" ]; then
  if grep -q "usability-reviewer" "$DESIGNER_FILE"; then
    pass "TC-05: usability-reviewer role boundary mentioned"
  else
    fail "TC-05: usability-reviewer not mentioned"
  fi
else
  fail "TC-05: designer.md does not exist"
fi

########################################
# TC-06: Output Format section validation
########################################

echo ""
echo "TC-06: Output Format section exists"
if [ -f "$DESIGNER_FILE" ]; then
  if grep -q "Output Format" "$DESIGNER_FILE" || grep -q "## Output" "$DESIGNER_FILE"; then
    pass "TC-06: Output Format section found"
  else
    fail "TC-06: Output Format section not found"
  fi
else
  fail "TC-06: designer.md does not exist"
fi

########################################
# TC-07: Regression test
########################################

echo ""
echo "TC-07: Existing test-agents-structure.sh still passes"
AGENTS_STRUCTURE_TEST="$BASE_DIR/tests/test-agents-structure.sh"
if [ -f "$AGENTS_STRUCTURE_TEST" ]; then
  if bash "$AGENTS_STRUCTURE_TEST" > /dev/null 2>&1; then
    pass "TC-07: test-agents-structure.sh passes"
  else
    fail "TC-07: test-agents-structure.sh failed"
  fi
else
  fail "TC-07: test-agents-structure.sh does not exist"
fi

########################################
# TC-08: Negative test - missing frontmatter
########################################

echo ""
echo "TC-08: [Negative] Detects missing frontmatter"
tmpdir=$(mktemp -d)
cat > "$tmpdir/broken-designer.md" << 'AGENT'
# Broken Designer

No frontmatter here.
AGENT

name_val=$(get_frontmatter "$tmpdir/broken-designer.md" "name")
desc_val=$(get_frontmatter "$tmpdir/broken-designer.md" "description")
if [ -z "$name_val" ] && [ -z "$desc_val" ]; then
  pass "TC-08: Correctly detected missing frontmatter"
else
  fail "TC-08: Failed to detect missing frontmatter"
fi
rm -rf "$tmpdir"

########################################
# TC-09: Input section validation
########################################

echo ""
echo "TC-09: Input section exists"
if [ -f "$DESIGNER_FILE" ]; then
  if grep -q "## Input" "$DESIGNER_FILE"; then
    pass "TC-09: Input section found"
  else
    fail "TC-09: Input section not found"
  fi
else
  fail "TC-09: designer.md does not exist"
fi

########################################
# Summary
########################################

echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
