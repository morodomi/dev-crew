#!/bin/bash
# test-onboard-discovered.sh - Phase 6 DISCOVERED items hardening tests
# TC-01 ~ TC-10: Validate onboard reference.md and SKILL.md documentation fixes

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

SKILL_FILE="$BASE_DIR/skills/onboard/SKILL.md"
REFERENCE_FILE="$BASE_DIR/skills/onboard/reference.md"

[ -f "$SKILL_FILE" ] || { echo "ERROR: $SKILL_FILE not found"; exit 1; }
[ -f "$REFERENCE_FILE" ] || { echo "ERROR: $REFERENCE_FILE not found"; exit 1; }

REF_CONTENT=$(cat "$REFERENCE_FILE")

echo "=== Onboard Discovered Items Tests ==="
echo ""

# --- Sub-task 1: Classification logic + MISSING array ---

# TC-01: Given reference.md classification logic, When AGENTS.md-only project, Then not classified as fresh
echo "TC-01: Classification logic handles AGENTS.md-only (not fresh)"
CLASSIFICATION=$(echo "$REF_CONTENT" | grep -A 20 "分類ロジック")
if echo "$CLASSIFICATION" | grep -q "AGENTS.md"; then
  pass "TC-01: Classification logic references AGENTS.md"
else
  fail "TC-01: Classification logic does not reference AGENTS.md"
fi

# TC-02: Given reference.md MISSING array, When reading, Then AGENTS.md check exists
echo ""
echo "TC-02: MISSING array includes AGENTS.md check"
MISSING_SECTION=$(echo "$REF_CONTENT" | grep -A 10 "MISSING")
if echo "$MISSING_SECTION" | grep -q 'AGENTS.md'; then
  pass "TC-02: AGENTS.md check found in MISSING array"
else
  fail "TC-02: AGENTS.md check not found in MISSING array"
fi

# TC-03: Given reference.md TDD section check, When reading, Then AGENTS.md is also searched
echo ""
echo "TC-03: TDD section detection searches AGENTS.md"
LOGIC_GREP=$(echo "$REF_CONTENT" | sed -n '/分類ロジック/,/^fi$/p')
if echo "$LOGIC_GREP" | grep -q 'grep.*AGENTS.md'; then
  pass "TC-03: TDD section detection includes AGENTS.md"
else
  fail "TC-03: TDD section detection does not include AGENTS.md"
fi

# TC-04: Given reference.md, When reading classification logic, Then AGENTS.md existence prevents fresh classification
echo ""
echo "TC-04: AGENTS.md prevents fresh classification (layout axis)"
# The classification logic bash snippet must check for AGENTS.md before declaring fresh
LOGIC_SNIPPET=$(echo "$REF_CONTENT" | sed -n '/分類ロジック/,/^fi$/p')
if echo "$LOGIC_SNIPPET" | grep -q '\-f AGENTS.md'; then
  pass "TC-04: AGENTS.md checked in fresh classification logic"
else
  fail "TC-04: AGENTS.md not checked in fresh classification logic"
fi

# --- Sub-task 2: Two-File mental model ---

# TC-05: Given reference.md Step 4, When reading intro, Then two-file model explanation exists
echo ""
echo "TC-05: Two-File Model explanation in reference.md Step 4"
STEP4=$(echo "$REF_CONTENT" | sed -n '/^## Step 4/,/^## Step [5-9]/p')
if echo "$STEP4" | grep -qi "two-file\|2ファイル"; then
  pass "TC-05: Two-File Model explanation found in Step 4"
else
  fail "TC-05: Two-File Model explanation not found in Step 4"
fi

# TC-06: Given reference.md Step 4, When reading, Then cross-tool purpose is stated for AGENTS.md
echo ""
echo "TC-06: AGENTS.md cross-tool purpose stated"
if echo "$STEP4" | grep -qi "cross-tool"; then
  pass "TC-06: cross-tool purpose stated for AGENTS.md"
else
  fail "TC-06: cross-tool purpose not stated for AGENTS.md"
fi

# --- Sub-task 3: Migration path ---

# TC-07: Given reference.md, When reading, Then migration section exists
echo ""
echo "TC-07: Migration section exists"
if echo "$REF_CONTENT" | grep -qi "migration\|マイグレーション"; then
  pass "TC-07: Migration section found"
else
  fail "TC-07: Migration section not found"
fi

# TC-08: Given reference.md migration, When reading, Then single-CLAUDE.md upgrade path described
echo ""
echo "TC-08: Single-CLAUDE.md upgrade path described"
if echo "$REF_CONTENT" | grep -qi "single.*CLAUDE.md\|CLAUDE.md.*only\|claude-md-only"; then
  pass "TC-08: Single-CLAUDE.md upgrade path found"
else
  fail "TC-08: Single-CLAUDE.md upgrade path not found"
fi

# --- Sub-task 4: Error recovery ---

# TC-09: Given reference.md error handling, When reading, Then AGENTS.md recovery case exists
echo ""
echo "TC-09: AGENTS.md error recovery case exists"
ERROR_SECTION=$(echo "$REF_CONTENT" | sed -n '/エラーハンドリング/,/^---$/p')
if echo "$ERROR_SECTION" | grep -q "AGENTS.md"; then
  pass "TC-09: AGENTS.md recovery case found in error handling"
else
  fail "TC-09: AGENTS.md recovery case not found in error handling"
fi

# TC-10: Given reference.md error handling, When reading, Then .bak restoration procedure exists
echo ""
echo "TC-10: .bak restoration procedure exists"
if echo "$REF_CONTENT" | grep -q "\.bak.*復旧\|\.bak.*restor\|復旧.*\.bak\|restor.*\.bak"; then
  pass "TC-10: .bak restoration procedure found"
else
  fail "TC-10: .bak restoration procedure not found"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
