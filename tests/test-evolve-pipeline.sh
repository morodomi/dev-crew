#!/bin/bash
# test-evolve-pipeline.sh - Verify evolve pipeline structural requirements
# TC-01: evolve SKILL.md documents bootstrap period threshold (2 件)
# TC-02: evolve SKILL.md references evolved/ staging output directory
# TC-03: evolve SKILL.md documents backup before generation

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== Evolve Pipeline Tests ==="

# TC-01: evolve SKILL.md documents bootstrap period threshold relaxation
echo ""
echo "TC-01: evolve SKILL.md documents bootstrap period threshold"
# During bootstrap, cluster minimum should be relaxed from 3 to 2
if grep -qE 'bootstrap|ブートストラップ' "$BASE_DIR/skills/evolve/SKILL.md" && \
   grep -q '2' "$BASE_DIR/skills/evolve/SKILL.md"; then
  pass "evolve SKILL.md documents bootstrap threshold"
else
  fail "evolve SKILL.md does NOT document bootstrap threshold"
fi

# TC-02: evolve SKILL.md references evolved/ staging output directory
echo ""
echo "TC-02: evolve SKILL.md references evolved/ staging directory"
if grep -q 'evolved/' "$BASE_DIR/skills/evolve/SKILL.md"; then
  pass "evolve SKILL.md references evolved/ staging directory"
else
  fail "evolve SKILL.md does NOT reference evolved/ staging directory"
fi

# TC-03: evolve SKILL.md documents backup before generation
echo ""
echo "TC-03: evolve SKILL.md documents backup before generation"
if grep -qi 'backup\|バックアップ' "$BASE_DIR/skills/evolve/SKILL.md"; then
  pass "evolve SKILL.md documents backup"
else
  fail "evolve SKILL.md does NOT document backup"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS"
echo "FAIL: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi

exit 0
