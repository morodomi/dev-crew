#!/bin/bash
# test-skill-maker.sh - skill-maker skill validation
# Cycle: 20260215_1500_skill-maker
# TC-01 to TC-16

set -uo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILL_DIR="$BASE_DIR/skills/skill-maker"
SKILL_MD="$SKILL_DIR/SKILL.md"
REF_MD="$SKILL_DIR/reference.md"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

get_frontmatter() {
  local file="$1"
  local key="$2"
  awk '/^---$/{n++; next} n==1{print}' "$file" | grep "^${key}: " | head -1 | sed "s/^${key}: *//" || true
}

echo "=== skill-maker Tests ==="

# --- Structure Tests ---
echo ""
echo "--- Structure Tests ---"

# TC-01: SKILL.md exists
if [ -f "$SKILL_MD" ]; then
  pass "TC-01: SKILL.md exists"
else
  fail "TC-01: SKILL.md does not exist at skills/skill-maker/SKILL.md"
fi

# TC-02: YAML frontmatter has name (kebab-case) and description (WHAT+WHEN+triggers)
if [ -f "$SKILL_MD" ]; then
  name_val=$(get_frontmatter "$SKILL_MD" "name")
  desc_val=$(get_frontmatter "$SKILL_MD" "description")

  if [ -n "$name_val" ] && echo "$name_val" | grep -qE '^[a-z][a-z0-9-]*$'; then
    pass "TC-02a: name is kebab-case: $name_val"
  else
    fail "TC-02a: name missing or not kebab-case: '$name_val'"
  fi

  # Check description has WHAT + WHEN + trigger phrases
  has_what=false
  has_when=false
  if [ -n "$desc_val" ]; then
    has_what=true
    # Check for trigger indicators
    if echo "$desc_val" | grep -qiE '(Use when|Triggers on|で起動|で使用)'; then
      has_when=true
    fi
  fi

  if $has_what && $has_when; then
    pass "TC-02b: description has WHAT + WHEN + triggers"
  else
    fail "TC-02b: description missing WHAT ($has_what) or WHEN ($has_when)"
  fi
else
  fail "TC-02a: Cannot check frontmatter - SKILL.md not found"
  fail "TC-02b: Cannot check frontmatter - SKILL.md not found"
fi

# TC-03: SKILL.md body under 100 lines
if [ -f "$SKILL_MD" ]; then
  line_count=$(wc -l < "$SKILL_MD" | tr -d ' ')
  if [ "$line_count" -le 100 ]; then
    pass "TC-03: SKILL.md is $line_count lines (<= 100)"
  else
    fail "TC-03: SKILL.md is $line_count lines (> 100)"
  fi
else
  fail "TC-03: Cannot check line count - SKILL.md not found"
fi

# TC-04: reference.md exists
if [ -f "$REF_MD" ]; then
  pass "TC-04: reference.md exists"
else
  fail "TC-04: reference.md does not exist at skills/skill-maker/reference.md"
fi

# --- SKILL.md Content Tests ---
echo ""
echo "--- SKILL.md Content Tests ---"

if [ -f "$SKILL_MD" ]; then
  skill_content=$(cat "$SKILL_MD")

  # TC-05: Create mode workflow defined
  if echo "$skill_content" | grep -qi 'create'; then
    pass "TC-05: Create mode workflow defined"
  else
    fail "TC-05: Create mode workflow not found"
  fi

  # TC-06: Review mode workflow defined
  if echo "$skill_content" | grep -qi 'review'; then
    pass "TC-06: Review mode workflow defined"
  else
    fail "TC-06: Review mode workflow not found"
  fi

  # TC-07: AskUserQuestion interaction
  if echo "$skill_content" | grep -q 'AskUserQuestion'; then
    pass "TC-07: AskUserQuestion interaction defined"
  else
    fail "TC-07: AskUserQuestion not found in SKILL.md"
  fi

  # TC-15: Progress Checklist
  if echo "$skill_content" | grep -qE '(Progress Checklist|Progress:)'; then
    pass "TC-15: Progress Checklist found"
  else
    fail "TC-15: Progress Checklist not found"
  fi

  # TC-16: Step context (Step N format)
  if echo "$skill_content" | grep -qE 'Step [0-9]'; then
    pass "TC-16: Step context format found"
  else
    fail "TC-16: Step N format not found"
  fi
else
  fail "TC-05: Cannot check - SKILL.md not found"
  fail "TC-06: Cannot check - SKILL.md not found"
  fail "TC-07: Cannot check - SKILL.md not found"
  fail "TC-15: Cannot check - SKILL.md not found"
  fail "TC-16: Cannot check - SKILL.md not found"
fi

# --- reference.md Content Tests (7 Gap Coverage) ---
echo ""
echo "--- reference.md Content Tests ---"

if [ -f "$REF_MD" ]; then
  ref_content=$(cat "$REF_MD")

  # TC-08: Description writing guide
  tc08_pass=true
  for keyword in "WHAT" "WHEN" "trigger" "negative\|NOT use\|Do NOT"; do
    if ! echo "$ref_content" | grep -qi "$keyword"; then
      tc08_pass=false
      break
    fi
  done
  if $tc08_pass; then
    pass "TC-08: Description guide (WHAT+WHEN+triggers+negative)"
  else
    fail "TC-08: Description guide missing required elements"
  fi

  # TC-09: 5 patterns
  tc09_count=0
  for pattern in "Sequential" "Multi-MCP" "Iterative" "Context-aware\|Context aware" "Domain-specific\|Domain specific"; do
    if echo "$ref_content" | grep -qi "$pattern"; then
      tc09_count=$((tc09_count + 1))
    fi
  done
  if [ "$tc09_count" -ge 5 ]; then
    pass "TC-09: All 5 patterns documented ($tc09_count/5)"
  else
    fail "TC-09: Only $tc09_count/5 patterns documented"
  fi

  # TC-10: 3 test areas
  tc10_count=0
  for area in "trigger" "functional" "performance"; do
    if echo "$ref_content" | grep -qi "$area"; then
      tc10_count=$((tc10_count + 1))
    fi
  done
  if [ "$tc10_count" -ge 3 ]; then
    pass "TC-10: All 3 test areas documented ($tc10_count/3)"
  else
    fail "TC-10: Only $tc10_count/3 test areas documented"
  fi

  # TC-11: Troubleshooting
  tc11_count=0
  for issue in "over-trigger\|overtrigger\|triggers too" "under-trigger\|undertrigger\|doesn.t trigger" "not followed\|instructions"; do
    if echo "$ref_content" | grep -qi "$issue"; then
      tc11_count=$((tc11_count + 1))
    fi
  done
  if [ "$tc11_count" -ge 3 ]; then
    pass "TC-11: Troubleshooting guide complete ($tc11_count/3)"
  else
    fail "TC-11: Troubleshooting guide incomplete ($tc11_count/3)"
  fi

  # TC-12: allowed-tools
  if echo "$ref_content" | grep -qi "allowed-tools\|allowed_tools"; then
    pass "TC-12: allowed-tools guide found"
  else
    fail "TC-12: allowed-tools guide not found"
  fi

  # TC-13: Security constraints
  tc13_count=0
  for constraint in "XML\|angle bracket" "claude\|anthropic.*reserved\|reserved.*name" "frontmatter"; do
    if echo "$ref_content" | grep -qi "$constraint"; then
      tc13_count=$((tc13_count + 1))
    fi
  done
  if [ "$tc13_count" -ge 2 ]; then
    pass "TC-13: Security constraints documented ($tc13_count/3)"
  else
    fail "TC-13: Security constraints incomplete ($tc13_count/3)"
  fi

  # TC-14: Validation checklist
  if echo "$ref_content" | grep -qiE '(checklist|Before.*upload|During.*development|After.*upload|\[ \])'; then
    pass "TC-14: Validation checklist found"
  else
    fail "TC-14: Validation checklist not found"
  fi
else
  fail "TC-08: Cannot check - reference.md not found"
  fail "TC-09: Cannot check - reference.md not found"
  fail "TC-10: Cannot check - reference.md not found"
  fail "TC-11: Cannot check - reference.md not found"
  fail "TC-12: Cannot check - reference.md not found"
  fail "TC-13: Cannot check - reference.md not found"
  fail "TC-14: Cannot check - reference.md not found"
fi

# --- DISCOVERED Tests (D-01, D-02, D-03) ---
echo ""
echo "--- DISCOVERED Tests ---"

if [ -f "$SKILL_MD" ]; then
  skill_content=$(cat "$SKILL_MD")

  # D-01: Mode conflict fallback
  if echo "$skill_content" | grep -qi '両方\|both.*detect\|競合'; then
    pass "D-01a: Mode conflict row exists"
  else
    fail "D-01a: Mode conflict row not found in Mode Selection"
  fi

  if echo "$skill_content" | grep -qi '両方.*AskUserQuestion\|競合.*AskUserQuestion\|both.*AskUserQuestion'; then
    pass "D-01b: Mode conflict triggers AskUserQuestion"
  else
    fail "D-01b: Mode conflict does not trigger AskUserQuestion"
  fi

  # D-02: Create mode retry
  if echo "$skill_content" | grep -qi 'リトライ\|再生成\|retry\|regenerat'; then
    pass "D-02: Create mode retry/regenerate noted"
  else
    fail "D-02: Create mode retry/regenerate not found in Step 3/6"
  fi
else
  fail "D-01a: Cannot check - SKILL.md not found"
  fail "D-01b: Cannot check - SKILL.md not found"
  fail "D-02: Cannot check - SKILL.md not found"
fi

# D-03: Security constraint tests
if [ -f "$SKILL_MD" ]; then
  name_val=$(get_frontmatter "$SKILL_MD" "name")
  desc_val=$(get_frontmatter "$SKILL_MD" "description")

  # TC-17: Description XML-free
  if echo "$desc_val" | grep -qE '[<>]'; then
    fail "TC-17: XML angle brackets found in description"
  else
    pass "TC-17: description is XML-free"
  fi

  # TC-18: Description length <= 1024
  desc_len=$(printf '%s' "$desc_val" | wc -c | tr -d ' ')
  if [ "$desc_len" -le 1024 ]; then
    pass "TC-18: description is $desc_len chars (<= 1024)"
  else
    fail "TC-18: description is $desc_len chars (> 1024)"
  fi

  # TC-19: Reserved name check
  if echo "$name_val" | grep -qiE '(claude|anthropic)'; then
    fail "TC-19: Reserved name detected: $name_val"
  else
    pass "TC-19: name avoids reserved words ($name_val)"
  fi
else
  fail "TC-17: Cannot check - SKILL.md not found"
  fail "TC-18: Cannot check - SKILL.md not found"
  fail "TC-19: Cannot check - SKILL.md not found"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
