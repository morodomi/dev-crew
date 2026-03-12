#!/bin/bash
# test-yaml-frontmatter.sh - YAML frontmatter validation using yamllint
# TC-Y1: All SKILL.md frontmatter is valid YAML
# TC-Y2: All agent .md frontmatter is valid YAML
# TC-Y3: [Negative] Detects unquoted colon in description
# TC-Y4: [Negative] Detects invalid YAML syntax
# TC-Y5: validate-yaml-frontmatter.sh script exists

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VALIDATOR="$BASE_DIR/scripts/validate-yaml-frontmatter.sh"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== YAML Frontmatter Tests ==="

# TC-Y5: Validator script exists
echo ""
echo "TC-Y5: validate-yaml-frontmatter.sh exists"
if [ -f "$VALIDATOR" ]; then
  pass "TC-Y5: validator script exists"
else
  fail "TC-Y5: scripts/validate-yaml-frontmatter.sh not found"
  echo ""
  echo "=== Summary ==="
  echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
  exit 1
fi

# TC-Y1: All SKILL.md frontmatter is valid YAML
echo ""
echo "TC-Y1: SKILL.md frontmatter validation"
skill_fail=0
for skill_file in "$BASE_DIR"/skills/*/SKILL.md; do
  [ -f "$skill_file" ] || continue
  skill_name=$(basename "$(dirname "$skill_file")")
  if ! bash "$VALIDATOR" "$skill_file" >/dev/null 2>&1; then
    fail "TC-Y1: $skill_name/SKILL.md has invalid YAML frontmatter"
    skill_fail=$((skill_fail + 1))
  fi
done
if [ "$skill_fail" -eq 0 ]; then
  pass "TC-Y1: All SKILL.md have valid YAML frontmatter"
fi

# TC-Y2: All agent .md frontmatter is valid YAML
echo ""
echo "TC-Y2: Agent frontmatter validation"
agent_fail=0
for agent_file in "$BASE_DIR"/agents/*.md; do
  [ -f "$agent_file" ] || continue
  basename_file=$(basename "$agent_file")
  # Skip reference files (no frontmatter)
  if [[ "$basename_file" == *-reference* ]]; then
    continue
  fi
  if ! bash "$VALIDATOR" "$agent_file" >/dev/null 2>&1; then
    fail "TC-Y2: $basename_file has invalid YAML frontmatter"
    agent_fail=$((agent_fail + 1))
  fi
done
if [ "$agent_fail" -eq 0 ]; then
  pass "TC-Y2: All agent .md have valid YAML frontmatter"
fi

# TC-Y3: [Negative] Detects unquoted colon in description
echo ""
echo "TC-Y3: [Negative] Detects unquoted colon"
TMPDIR_Y=$(mktemp -d)
trap 'rm -rf "$TMPDIR_Y"' EXIT
cat > "$TMPDIR_Y/unquoted.md" << 'EOF'
---
name: test
description: This has a colon: inside the value
---
EOF
if bash "$VALIDATOR" "$TMPDIR_Y/unquoted.md" >/dev/null 2>&1; then
  fail "TC-Y3: unquoted colon was not detected"
else
  pass "TC-Y3: correctly detected unquoted colon"
fi

# TC-Y4: [Negative] Detects invalid YAML syntax
echo ""
echo "TC-Y4: [Negative] Detects invalid YAML"
cat > "$TMPDIR_Y/invalid.md" << 'EOF'
---
name: test
description: [unclosed bracket
allowed-tools: Read
---
EOF
if bash "$VALIDATOR" "$TMPDIR_Y/invalid.md" >/dev/null 2>&1; then
  fail "TC-Y4: invalid YAML was not detected"
else
  pass "TC-Y4: correctly detected invalid YAML"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
