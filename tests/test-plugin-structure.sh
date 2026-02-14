#!/bin/bash
# test-plugin-structure.sh - dev-crew plugin structure validation
# TC-01, TC-02, TC-03, TC-04, TC-05, TC-12

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== Plugin Structure Tests ==="

# TC-01: plugin.json is valid JSON
echo ""
echo "TC-01: plugin.json is valid JSON"
if jq empty "$BASE_DIR/.claude-plugin/plugin.json" 2>/dev/null; then
  pass "plugin.json is valid JSON"
else
  fail "plugin.json is NOT valid JSON"
fi

# TC-02: agents/ directory contains .md files
echo ""
echo "TC-02: agents/ has .md files"
agent_count=$(find "$BASE_DIR/agents" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
if [ "$agent_count" -gt 0 ]; then
  pass "agents/ contains $agent_count .md files"
else
  fail "agents/ contains no .md files"
fi

# TC-03: skills/ directory contains subdirectories
echo ""
echo "TC-03: skills/ has subdirectories"
skill_count=$(find "$BASE_DIR/skills" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
if [ "$skill_count" -gt 0 ]; then
  pass "skills/ contains $skill_count subdirectories"
else
  fail "skills/ contains no subdirectories"
fi

# TC-04: rules/ directory contains .md files
echo ""
echo "TC-04: rules/ has .md files"
rule_count=$(find "$BASE_DIR/rules" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
if [ "$rule_count" -gt 0 ]; then
  pass "rules/ contains $rule_count .md files"
else
  fail "rules/ contains no .md files"
fi

# TC-05: hooks/hooks.json is valid JSON
echo ""
echo "TC-05: hooks/hooks.json is valid JSON"
if jq empty "$BASE_DIR/hooks/hooks.json" 2>/dev/null; then
  pass "hooks/hooks.json is valid JSON"
else
  fail "hooks/hooks.json is NOT valid JSON"
fi

# TC-12: [Negative] invalid plugin.json detection
echo ""
echo "TC-12: [Negative] detects invalid JSON"
tmpdir=$(mktemp -d)
mkdir -p "$tmpdir/.claude-plugin"
echo "{ invalid json" > "$tmpdir/.claude-plugin/plugin.json"
if jq empty "$tmpdir/.claude-plugin/plugin.json" 2>/dev/null; then
  fail "Failed to detect invalid plugin.json"
else
  pass "Correctly detected invalid plugin.json"
fi
rm -rf "$tmpdir"

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
