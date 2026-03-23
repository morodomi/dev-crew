#!/bin/bash
# post-approve-gate.sh - PreToolUse hook for Edit|Write
# Blocks Edit/Write if plan was approved but orchestrate hasn't started.
# Exit 2 = block the tool call.

set -uo pipefail

PROJECT_HASH=$(pwd | md5 -q 2>/dev/null || echo "$PWD" | md5sum | cut -d' ' -f1)
FLAG_FILE="${HOME}/.claude/dev-crew/.plan-approved-${PROJECT_HASH}"

# No flag → allow
if [ ! -f "$FLAG_FILE" ]; then
  exit 0
fi

# Flag exists but expired (older than 2 hours) → clean up and allow
FLAG_TIME=$(cat "$FLAG_FILE" 2>/dev/null || echo "")
if [ -n "$FLAG_TIME" ]; then
  FLAG_EPOCH=$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$FLAG_TIME" +%s 2>/dev/null || echo "0")
  NOW_EPOCH=$(date -u +%s)
  DIFF=$(( NOW_EPOCH - FLAG_EPOCH ))
  if [ "$DIFF" -gt 7200 ]; then
    rm -f "$FLAG_FILE"
    exit 0
  fi
fi

# Flag is valid → block
echo "BLOCKED: Plan was approved but /orchestrate has not been started."
echo "Run /orchestrate first. It handles sync-plan, plan-review, and the full TDD cycle."
echo "To clear this gate manually: rm ~/.claude/dev-crew/.plan-approved-${PROJECT_HASH}"
exit 2
