#!/bin/bash
# test-agents-structure.sh - dev-crew agent definition validation
# TC-06, TC-07, TC-13

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

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

echo "=== Agent Structure Tests ==="

# TC-06 & TC-07: All agents have name and description frontmatter
echo ""
echo "TC-06/07: Agent frontmatter validation"
name_fail=0
desc_fail=0
for agent_file in "$BASE_DIR"/agents/*.md; do
  [ -f "$agent_file" ] || continue
  basename_file=$(basename "$agent_file")

  # Skip non-agent files (e.g., reference files)
  if [[ "$basename_file" == *-reference* ]]; then
    continue
  fi

  name_val=$(get_frontmatter "$agent_file" "name")
  desc_val=$(get_frontmatter "$agent_file" "description")

  if [ -z "$name_val" ]; then
    fail "TC-06: $basename_file missing 'name' frontmatter"
    name_fail=$((name_fail + 1))
  fi

  if [ -z "$desc_val" ]; then
    fail "TC-07: $basename_file missing 'description' frontmatter"
    desc_fail=$((desc_fail + 1))
  fi
done

if [ "$name_fail" -eq 0 ]; then
  pass "TC-06: All agents have 'name' frontmatter"
fi
if [ "$desc_fail" -eq 0 ]; then
  pass "TC-07: All agents have 'description' frontmatter"
fi

# TC-13: [Negative] detect missing frontmatter
echo ""
echo "TC-13: [Negative] detects missing frontmatter"
tmpdir=$(mktemp -d)
mkdir -p "$tmpdir/agents"
cat > "$tmpdir/agents/broken-agent.md" << 'AGENT'
# Broken Agent

No frontmatter here.
AGENT

name_val=$(get_frontmatter "$tmpdir/agents/broken-agent.md" "name")
if [ -z "$name_val" ]; then
  pass "Correctly detected missing frontmatter"
else
  fail "Failed to detect missing frontmatter"
fi
rm -rf "$tmpdir"

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
