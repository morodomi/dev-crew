#!/bin/bash
# test-rules-mirror.sh - rules/ <-> .claude/rules/ mirror completeness tests
# TC-01: rules/*.md each exists identical in .claude/rules/ (forward direction)
# TC-02: .claude/rules/*.md each exists in rules/ OR is in CLAUDE_ONLY_FILES allowlist (backward direction)

set -uo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

RULES_DIR="$BASE_DIR/rules"
CLAUDE_RULES_DIR="$BASE_DIR/.claude/rules"

# Explicit allowlist for Claude-specific files that exist only in .claude/rules/
CLAUDE_ONLY_FILES=("post-approve.md")

echo "=== rules mirror Tests ==="

# TC-01: rules/*.md each exists in .claude/rules/ AND diff is empty (forward direction)
echo ""
echo "TC-01: rules/*.md each file exists in .claude/rules/ with identical content (forward)"
TC01_PASS=true
for src_file in "$RULES_DIR"/*.md; do
  fname="$(basename "$src_file")"
  dst_file="$CLAUDE_RULES_DIR/$fname"
  if [ ! -f "$dst_file" ]; then
    fail "TC-01: .claude/rules/$fname does not exist (missing mirror)"
    TC01_PASS=false
  else
    diff_output=$(diff "$src_file" "$dst_file" || true)
    if [ -n "$diff_output" ]; then
      fail "TC-01: .claude/rules/$fname differs from rules/$fname (drift detected)"
      TC01_PASS=false
    fi
  fi
done
if [ "$TC01_PASS" = "true" ]; then
  pass "TC-01: All rules/*.md files exist identically in .claude/rules/"
fi

# TC-02: .claude/rules/*.md each exists in rules/ OR is in CLAUDE_ONLY_FILES allowlist (backward direction)
echo ""
echo "TC-02: .claude/rules/*.md each file is in rules/ OR in CLAUDE_ONLY_FILES allowlist (backward)"
TC02_PASS=true
for dst_file in "$CLAUDE_RULES_DIR"/*.md; do
  fname="$(basename "$dst_file")"
  # Check if this file is in the explicit allowlist
  in_allowlist=false
  for allowed in "${CLAUDE_ONLY_FILES[@]}"; do
    if [ "$fname" = "$allowed" ]; then
      in_allowlist=true
      break
    fi
  done
  if [ "$in_allowlist" = "true" ]; then
    : # allowed — skip
  elif [ ! -f "$RULES_DIR/$fname" ]; then
    fail "TC-02: .claude/rules/$fname has no corresponding rules/$fname and is not in CLAUDE_ONLY_FILES allowlist"
    TC02_PASS=false
  fi
done
if [ "$TC02_PASS" = "true" ]; then
  pass "TC-02: All .claude/rules/*.md files are either mirrored from rules/ or in allowlist"
fi

# Summary
echo ""
echo "PASS: $PASS, FAIL: $FAIL"
[ $FAIL -eq 0 ] && exit 0 || exit 1
