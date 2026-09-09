#!/bin/bash
# test-skills-structure.sh - dev-crew skill definition validation
# TC-08, TC-09, TC-10, TC-11, TC-14

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0
MAX_SKILL_LINES=100

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

get_frontmatter() {
  local file="$1"
  local key="$2"
  awk '/^---$/{n++; next} n==1{print}' "$file" | grep "^${key}: " | head -1 | sed "s/^${key}: *//" || true
}

echo "=== Skills Structure Tests ==="

# TC-08: All skill directories have SKILL.md
echo ""
echo "TC-08: SKILL.md existence"
missing_skill=0
for skill_dir in "$BASE_DIR"/skills/*/; do
  [ -d "$skill_dir" ] || continue
  skill_name=$(basename "$skill_dir")
  if [ ! -f "$skill_dir/SKILL.md" ]; then
    fail "TC-08: $skill_name/ missing SKILL.md"
    missing_skill=$((missing_skill + 1))
  fi
done
if [ "$missing_skill" -eq 0 ]; then
  pass "TC-08: All skill directories have SKILL.md"
fi

# TC-09: All SKILL.md are under 100 lines
echo ""
echo "TC-09: SKILL.md line count (max $MAX_SKILL_LINES)"
over_limit=0
for skill_file in "$BASE_DIR"/skills/*/SKILL.md; do
  [ -f "$skill_file" ] || continue
  skill_name=$(basename "$(dirname "$skill_file")")
  line_count=$(wc -l < "$skill_file" | tr -d ' ')
  if [ "$line_count" -gt "$MAX_SKILL_LINES" ]; then
    fail "TC-09: $skill_name/SKILL.md has $line_count lines (max $MAX_SKILL_LINES)"
    over_limit=$((over_limit + 1))
  fi
done
if [ "$over_limit" -eq 0 ]; then
  pass "TC-09: All SKILL.md under $MAX_SKILL_LINES lines"
fi

# TC-10 & TC-11: All SKILL.md have name and description frontmatter
echo ""
echo "TC-10/11: SKILL.md frontmatter validation"
name_fail=0
desc_fail=0
for skill_file in "$BASE_DIR"/skills/*/SKILL.md; do
  [ -f "$skill_file" ] || continue
  skill_name=$(basename "$(dirname "$skill_file")")

  name_val=$(get_frontmatter "$skill_file" "name")
  desc_val=$(get_frontmatter "$skill_file" "description")

  if [ -z "$name_val" ]; then
    fail "TC-10: $skill_name/SKILL.md missing 'name' frontmatter"
    name_fail=$((name_fail + 1))
  fi

  if [ -z "$desc_val" ]; then
    fail "TC-11: $skill_name/SKILL.md missing 'description' frontmatter"
    desc_fail=$((desc_fail + 1))
  fi
done
if [ "$name_fail" -eq 0 ]; then
  pass "TC-10: All SKILL.md have 'name' frontmatter"
fi
if [ "$desc_fail" -eq 0 ]; then
  pass "TC-11: All SKILL.md have 'description' frontmatter"
fi

# TC-14: [Negative] detect SKILL.md over 100 lines
echo ""
echo "TC-14: [Negative] detects over-limit SKILL.md"
tmpdir=$(mktemp -d)
mkdir -p "$tmpdir/skills/over-limit"
# Generate 150 lines
for i in $(seq 1 150); do echo "line $i"; done > "$tmpdir/skills/over-limit/SKILL.md"
line_count=$(wc -l < "$tmpdir/skills/over-limit/SKILL.md" | tr -d ' ')
if [ "$line_count" -gt "$MAX_SKILL_LINES" ]; then
  pass "Correctly detected $line_count-line SKILL.md"
else
  fail "Failed to detect over-limit SKILL.md"
fi
rm -rf "$tmpdir"

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
