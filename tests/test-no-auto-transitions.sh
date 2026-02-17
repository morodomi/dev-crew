#!/bin/bash
# test-no-auto-transitions.sh - verify individual skills don't chain Skill() calls
# TC-01 ~ TC-04

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

# Flow-control skills that ARE allowed to have Skill() chains
FLOW_CONTROL_SKILLS="orchestrate init parallel security-audit"

is_flow_control() {
  local skill_name="$1"
  for fc in $FLOW_CONTROL_SKILLS; do
    [ "$skill_name" = "$fc" ] && return 0
  done
  return 1
}

# Detect Skill(dev-crew:xxx) calls outside of markdown code blocks
# Skips lines inside ``` fenced blocks. Inline backtick formatting is NOT skipped
# (e.g. `Skill(dev-crew:green)` on a normal line IS an auto-transition instruction).
# Returns matching lines with line numbers, empty if none found.
detect_auto_transitions() {
  local file="$1"
  awk '
    /^```/{in_block=!in_block; next}
    in_block{next}
    /Skill\(dev-crew:[a-z]/{print NR": "$0}
  ' "$file"
}

echo "=== No Auto-Transition Tests ==="

# TC-01: Individual skills should NOT have auto-transition Skill() calls
echo ""
echo "TC-01: No auto-transition Skill() in individual skills"
violations=0
for skill_file in "$BASE_DIR"/skills/*/SKILL.md; do
  [ -f "$skill_file" ] || continue
  skill_name=$(basename "$(dirname "$skill_file")")

  # Skip flow-control skills
  is_flow_control "$skill_name" && continue

  hits=$(detect_auto_transitions "$skill_file")

  if [ -n "$hits" ]; then
    fail "TC-01: $skill_name/SKILL.md has auto-transition"
    echo "$hits" | while read -r line; do echo "    $line"; done
    violations=$((violations + 1))
  fi
done
if [ "$violations" -eq 0 ]; then
  pass "TC-01: No auto-transition Skill() found in individual skills"
fi

# TC-02: Flow-control skills are excluded from the check
echo ""
echo "TC-02: Flow-control skills excluded"
excluded_count=0
for fc_skill in $FLOW_CONTROL_SKILLS; do
  skill_file="$BASE_DIR/skills/$fc_skill/SKILL.md"
  [ -f "$skill_file" ] || continue
  hits=$(detect_auto_transitions "$skill_file")
  if [ -n "$hits" ]; then
    excluded_count=$((excluded_count + 1))
  fi
done
if [ "$excluded_count" -gt 0 ]; then
  pass "TC-02: $excluded_count flow-control skills correctly excluded"
else
  fail "TC-02: No flow-control skills with Skill() found (expected at least 1)"
fi

# TC-03: Skill() inside code blocks is not flagged
echo ""
echo "TC-03: Skill() in code blocks excluded"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
mkdir -p "$tmpdir/skills/test-block"
cat > "$tmpdir/skills/test-block/SKILL.md" << 'HEREDOC'
---
name: test-block
description: Test skill
---

# Test

Normal content here.

```
Skill(dev-crew:should-not-be-flagged)
```

End of file.
HEREDOC

hits=$(detect_auto_transitions "$tmpdir/skills/test-block/SKILL.md")
if [ -z "$hits" ]; then
  pass "TC-03: Skill() inside code blocks correctly excluded"
else
  fail "TC-03: Skill() inside code blocks was incorrectly flagged"
fi

# TC-04: Existing structure tests still pass
echo ""
echo "TC-04: Regression - existing tests pass"
regression_pass=true
for test_script in test-skills-structure.sh test-agents-structure.sh test-cross-references.sh; do
  if [ -f "$BASE_DIR/tests/$test_script" ]; then
    if ! bash "$BASE_DIR/tests/$test_script" > /dev/null 2>&1; then
      fail "TC-04: $test_script failed"
      regression_pass=false
    fi
  fi
done
if [ "$regression_pass" = true ]; then
  pass "TC-04: All existing structure tests pass"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
