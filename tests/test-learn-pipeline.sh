#!/bin/bash
# test-learn-pipeline.sh - Verify learn pipeline structural requirements
# TC-01: observer.md Input table has observations field
# TC-02: learn reference.md documents all required JSONL fields
# TC-03: learn documents confidence < 0.5 filtering
# TC-04: observe.sh filters read-only Bash commands
# TC-05: observer.md has tool usage log pattern extraction rules

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== Learn Pipeline Tests ==="

# TC-01: observer.md Input table has observations field
echo ""
echo "TC-01: observer.md Input table has observations field"
if grep -q 'observations' "$BASE_DIR/agents/observer.md" && \
   grep -q 'log\.jsonl\|observation' "$BASE_DIR/agents/observer.md"; then
  pass "observer.md Input includes observations field"
else
  fail "observer.md Input does NOT include observations field"
fi

# TC-02: learn reference.md documents all required JSONL fields
echo ""
echo "TC-02: learn reference.md documents required JSONL fields"
REQUIRED_FIELDS=("id" "trigger" "action" "confidence" "domain" "evidence" "created")
MISSING=""
for field in "${REQUIRED_FIELDS[@]}"; do
  if ! grep -q "$field" "$BASE_DIR/skills/learn/reference.md"; then
    MISSING="$MISSING $field"
  fi
done
if [ -z "$MISSING" ]; then
  pass "All required JSONL fields documented in reference.md"
else
  fail "Missing JSONL fields in reference.md:$MISSING"
fi

# TC-03: learn documents confidence < 0.5 filtering
echo ""
echo "TC-03: learn documents confidence < 0.5 filtering"
if grep -q '< 0\.5\|< 0.5' "$BASE_DIR/skills/learn/SKILL.md" || \
   grep -q '>= 0\.5\|>= 0.5' "$BASE_DIR/skills/learn/SKILL.md"; then
  pass "learn SKILL.md documents confidence filtering"
else
  fail "learn SKILL.md does NOT document confidence filtering"
fi

# TC-04: observe.sh filters read-only Bash commands
echo ""
echo "TC-04: observe.sh filters read-only Bash commands"
# observe.sh should skip logging for read-only commands like cat, ls, head, tail, grep, find, wc
if grep -qE 'filter|skip|exclude|read.only|READ_ONLY' "$BASE_DIR/scripts/hooks/observe.sh"; then
  pass "observe.sh has read-only command filtering"
else
  fail "observe.sh does NOT filter read-only Bash commands"
fi

# TC-05: observer.md has tool usage log pattern extraction rules
echo ""
echo "TC-05: observer.md has tool usage log pattern extraction rules"
# observer.md should mention patterns like repeated file edits, command sequences, tool preferences
if grep -q 'tool_name\|tool.*usage\|ツール使用' "$BASE_DIR/agents/observer.md" && \
   grep -qE 'sequence|繰り返し|頻度|frequency' "$BASE_DIR/agents/observer.md"; then
  pass "observer.md has tool usage pattern extraction rules"
else
  fail "observer.md does NOT have tool usage pattern extraction rules"
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
