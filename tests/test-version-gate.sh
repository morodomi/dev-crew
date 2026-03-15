#!/bin/bash
# test-version-gate.sh - version gate documentation validation
# TC-01, TC-02, TC-03, TC-04, TC-05, TC-06, TC-07

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== Version Gate Tests ==="

# TC-01: skills/onboard/reference.md Step 6 mentions .claude/dev-crew.json
echo ""
echo "TC-01: onboard/reference.md Step 6 mentions .claude/dev-crew.json"
if grep -A40 '^## Step 6:' "$BASE_DIR/skills/onboard/reference.md" | grep -q '\.claude/dev-crew\.json'; then
  pass "Step 6 includes .claude/dev-crew.json"
else
  fail "Step 6 does not include .claude/dev-crew.json"
fi

# TC-02: skills/onboard/reference.md includes dev_crew_version recording instructions
echo ""
echo "TC-02: onboard/reference.md includes dev_crew_version recording instructions"
if grep -q 'dev_crew_version' "$BASE_DIR/skills/onboard/reference.md"; then
  pass "onboard/reference.md includes dev_crew_version"
else
  fail "onboard/reference.md does not include dev_crew_version"
fi

# TC-03: skills/onboard/reference.md diff check table includes .claude/dev-crew.json
echo ""
echo "TC-03: onboard/reference.md diff check table includes .claude/dev-crew.json"
if grep -A20 '差分チェック' "$BASE_DIR/skills/onboard/reference.md" | grep -q '\.claude/dev-crew\.json'; then
  pass "diff check table includes .claude/dev-crew.json"
else
  fail "diff check table does not include .claude/dev-crew.json"
fi

# TC-04: skills/spec/SKILL.md Step 1 has Version Gate
echo ""
echo "TC-04: spec/SKILL.md Step 1 has Version Gate"
if grep -A20 '^### Step 1:' "$BASE_DIR/skills/spec/SKILL.md" | grep -q 'Version Gate'; then
  pass "Step 1 includes Version Gate"
else
  fail "Step 1 does not include Version Gate"
fi

# TC-05: skills/spec/SKILL.md warns when .claude/dev-crew.json is missing
echo ""
echo "TC-05: spec/SKILL.md warns when .claude/dev-crew.json is missing"
if grep -q '\.claude/dev-crew\.json.*missing\|missing.*\.claude/dev-crew\.json' "$BASE_DIR/skills/spec/SKILL.md"; then
  pass "spec/SKILL.md includes missing-file warning"
else
  fail "spec/SKILL.md does not include missing-file warning"
fi

# TC-06: skills/spec/reference.md includes version comparison details
echo ""
echo "TC-06: spec/reference.md includes version comparison details"
if grep -q 'installed_plugins.json' "$BASE_DIR/skills/spec/reference.md" && \
   grep -q 'dev_crew_version' "$BASE_DIR/skills/spec/reference.md"; then
  pass "spec/reference.md includes version comparison details"
else
  fail "spec/reference.md does not include version comparison details"
fi

# TC-07: regression - existing plugin structure test passes
echo ""
echo "TC-07: regression - test-plugin-structure.sh passes"
if bash "$BASE_DIR/tests/test-plugin-structure.sh"; then
  pass "test-plugin-structure.sh passes"
else
  fail "test-plugin-structure.sh failed"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
