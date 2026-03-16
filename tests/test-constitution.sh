#!/bin/bash
# test-constitution.sh - CONSTITUTION.md 整合性テスト (v3 Phase 6)
# T-01 ~ T-08

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== Constitution Tests ==="
echo ""

# T-01: Given CONSTITUTION.md exists at root, When checked, Then file exists and is non-empty
echo "T-01: CONSTITUTION.md exists and is non-empty"
if [ -s "$BASE_DIR/CONSTITUTION.md" ]; then
  pass "T-01: CONSTITUTION.md exists and is non-empty"
else
  fail "T-01: CONSTITUTION.md missing or empty"
fi

# T-02: Given CONSTITUTION.md has 5-Layer Authority, When layers checked, Then Layer 0-4 all present
echo ""
echo "T-02: CONSTITUTION.md has 5-Layer Authority (Layer 0-4)"
LAYERS=0
grep -q 'Layer 0\|CONSTITUTION' "$BASE_DIR/CONSTITUTION.md" 2>/dev/null && \
  grep -q '| 0 ' "$BASE_DIR/CONSTITUTION.md" 2>/dev/null && LAYERS=$((LAYERS + 1))
grep -q '| 1 ' "$BASE_DIR/CONSTITUTION.md" 2>/dev/null && LAYERS=$((LAYERS + 1))
grep -q '| 2 ' "$BASE_DIR/CONSTITUTION.md" 2>/dev/null && LAYERS=$((LAYERS + 1))
grep -q '| 3 ' "$BASE_DIR/CONSTITUTION.md" 2>/dev/null && LAYERS=$((LAYERS + 1))
grep -q '| 4 ' "$BASE_DIR/CONSTITUTION.md" 2>/dev/null && LAYERS=$((LAYERS + 1))
if [ "$LAYERS" -eq 5 ]; then
  pass "T-02: All 5 layers (0-4) present"
else
  fail "T-02: Only $LAYERS/5 layers found"
fi

# T-03: Given CONSTITUTION.md is Layer 0, When referenced from AGENTS.md, Then link is valid
echo ""
echo "T-03: AGENTS.md references CONSTITUTION.md"
if grep -q 'CONSTITUTION.md' "$BASE_DIR/AGENTS.md" 2>/dev/null; then
  pass "T-03: CONSTITUTION.md reference found in AGENTS.md"
else
  fail "T-03: CONSTITUTION.md reference missing from AGENTS.md"
fi

# T-04: Given workflow.md exists, When checked, Then contains development flow diagram
echo ""
echo "T-04: workflow.md contains development flow diagram"
if [ -f "$BASE_DIR/docs/workflow.md" ] && grep -q 'pre-red-gate' "$BASE_DIR/docs/workflow.md"; then
  pass "T-04: workflow.md has development flow diagram"
else
  fail "T-04: workflow.md missing or no flow diagram"
fi

# T-05: Given document-hierarchy.md, When checked, Then file does NOT exist (廃止確認)
echo ""
echo "T-05: document-hierarchy.md does NOT exist"
if [ ! -f "$BASE_DIR/docs/document-hierarchy.md" ]; then
  pass "T-05: document-hierarchy.md properly removed"
else
  fail "T-05: document-hierarchy.md still exists"
fi

# T-06: Given PHILOSOPHY.md, When checked, Then file does NOT exist (廃止確認)
echo ""
echo "T-06: PHILOSOPHY.md does NOT exist"
if [ ! -f "$BASE_DIR/docs/PHILOSOPHY.md" ]; then
  pass "T-06: PHILOSOPHY.md properly removed"
else
  fail "T-06: PHILOSOPHY.md still exists"
fi

# T-07: Given skill-map.md, When Authority checked, Then references CONSTITUTION.md (not PHILOSOPHY.md)
echo ""
echo "T-07: skill-map.md references CONSTITUTION.md"
if grep -q 'CONSTITUTION.md' "$BASE_DIR/docs/skill-map.md" 2>/dev/null && \
   ! grep -q 'PHILOSOPHY.md' "$BASE_DIR/docs/skill-map.md" 2>/dev/null; then
  pass "T-07: skill-map.md references CONSTITUTION.md (not PHILOSOPHY.md)"
else
  fail "T-07: skill-map.md Authority reference incorrect"
fi

# T-08: Given ROADMAP.md at root, When checked, Then file exists
echo ""
echo "T-08: ROADMAP.md exists at root"
if [ -f "$BASE_DIR/ROADMAP.md" ]; then
  pass "T-08: ROADMAP.md exists at root"
else
  fail "T-08: ROADMAP.md missing from root"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
