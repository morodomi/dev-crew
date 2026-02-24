#!/bin/bash
# test-evolve-contribute.sh - Verify evolve contribute mode design
# TC-15: evolve SKILL.md mentions contribute mode
# TC-16: evolve mentions structure validation test execution
# TC-17: evolve SKILL.md contains Step 6 "Contribute"
# TC-18: evolve SKILL.md documents source-path resolution
# TC-19: evolve reference.md documents fallback chain (source-path + AskUserQuestion)
# TC-20: evolve reference.md documents full test suite execution (test-*.sh)
# TC-21: evolve reference.md documents path validation (plugin.json)
# TC-22: observe.sh references source-path
# TC-23: observe.sh creates source-path file when run (functional)
# TC-24: observe.sh source-path contains correct plugin root path (functional)

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== Evolve Contribute Tests ==="

# TC-15: evolve SKILL.md mentions contribute mode
echo ""
echo "TC-15: evolve SKILL.md mentions contribute mode"
if grep -qi 'contribute' "$BASE_DIR/skills/evolve/SKILL.md"; then
  pass "evolve SKILL.md mentions contribute mode"
else
  fail "evolve SKILL.md does not mention contribute mode"
fi

# TC-16: evolve mentions test execution
echo ""
echo "TC-16: evolve mentions test execution"
if grep -q 'test-\*\.sh\|test-.*-structure' "$BASE_DIR/skills/evolve/SKILL.md"; then
  pass "evolve mentions test execution"
else
  fail "evolve does not mention test execution"
fi

# TC-17: evolve SKILL.md contains Step 6 "Contribute"
echo ""
echo "TC-17: evolve SKILL.md contains Step 6 Contribute"
if grep -q 'Step 6.*[Cc]ontribute' "$BASE_DIR/skills/evolve/SKILL.md"; then
  pass "evolve SKILL.md contains Step 6 Contribute"
else
  fail "evolve SKILL.md does not contain Step 6 Contribute"
fi

# TC-18: evolve SKILL.md documents source-path resolution
echo ""
echo "TC-18: evolve SKILL.md documents source-path resolution"
if grep -q 'source-path' "$BASE_DIR/skills/evolve/SKILL.md"; then
  pass "evolve SKILL.md documents source-path resolution"
else
  fail "evolve SKILL.md does not document source-path resolution"
fi

# TC-19: evolve reference.md documents fallback chain (source-path + AskUserQuestion)
echo ""
echo "TC-19: evolve reference.md documents fallback chain"
if grep -q 'source-path' "$BASE_DIR/skills/evolve/reference.md" && grep -q 'AskUserQuestion' "$BASE_DIR/skills/evolve/reference.md"; then
  pass "evolve reference.md documents fallback chain"
else
  fail "evolve reference.md does not document fallback chain (source-path + AskUserQuestion)"
fi

# TC-20: evolve reference.md documents full test suite execution (test-*.sh)
echo ""
echo "TC-20: evolve reference.md documents full test suite execution"
if grep -q 'test-\*\.sh\|test-\*' "$BASE_DIR/skills/evolve/reference.md"; then
  pass "evolve reference.md documents full test suite execution"
else
  fail "evolve reference.md does not document full test suite execution (test-*.sh)"
fi

# TC-21: evolve reference.md documents path validation (plugin.json)
echo ""
echo "TC-21: evolve reference.md documents path validation (plugin.json)"
if grep -q 'plugin\.json' "$BASE_DIR/skills/evolve/reference.md"; then
  pass "evolve reference.md documents path validation (plugin.json)"
else
  fail "evolve reference.md does not document path validation (plugin.json)"
fi

# TC-22: observe.sh references source-path
echo ""
echo "TC-22: observe.sh references source-path"
if grep -q 'source-path' "$BASE_DIR/scripts/hooks/observe.sh"; then
  pass "observe.sh references source-path"
else
  fail "observe.sh does not reference source-path"
fi

# TC-23: observe.sh creates source-path file when run (functional)
echo ""
echo "TC-23: observe.sh creates source-path file when run (functional)"
TMPDIR_TC23=$(mktemp -d)
MOCK_INPUT='{"tool_name":"Write","tool_input":{"file_path":"/tmp/test.txt"},"session_id":"test-session"}'
echo "$MOCK_INPUT" | HOME="$TMPDIR_TC23" bash "$BASE_DIR/scripts/hooks/observe.sh" 2>/dev/null || true
if [ -f "$TMPDIR_TC23/.claude/dev-crew/source-path" ]; then
  pass "observe.sh creates source-path file"
else
  fail "observe.sh does not create source-path file"
fi
rm -rf "$TMPDIR_TC23"

# TC-24: observe.sh source-path contains correct plugin root path (functional)
echo ""
echo "TC-24: observe.sh source-path contains correct plugin root path (functional)"
TMPDIR_TC24=$(mktemp -d)
MOCK_INPUT='{"tool_name":"Write","tool_input":{"file_path":"/tmp/test.txt"},"session_id":"test-session"}'
echo "$MOCK_INPUT" | HOME="$TMPDIR_TC24" bash "$BASE_DIR/scripts/hooks/observe.sh" 2>/dev/null || true
EXPECTED_ROOT="$(cd "$BASE_DIR" && pwd)"
if [ -f "$TMPDIR_TC24/.claude/dev-crew/source-path" ]; then
  ACTUAL_ROOT=$(cat "$TMPDIR_TC24/.claude/dev-crew/source-path")
  if [ "$ACTUAL_ROOT" = "$EXPECTED_ROOT" ]; then
    pass "source-path contains correct plugin root ($EXPECTED_ROOT)"
  else
    fail "source-path contains wrong path: got '$ACTUAL_ROOT', expected '$EXPECTED_ROOT'"
  fi
else
  fail "source-path file not created (prerequisite failed)"
fi
rm -rf "$TMPDIR_TC24"

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS"
echo "FAIL: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi

exit 0
