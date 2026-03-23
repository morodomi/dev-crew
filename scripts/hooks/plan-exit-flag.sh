#!/bin/bash
# plan-exit-flag.sh - PostToolUse hook for ExitPlanMode
# Creates a flag file when plan mode is exited.
# The flag is cleared by orchestrate at startup.

set -uo pipefail

# Only activate in dev-crew projects (has docs/cycles/ directory)
if [ ! -d "docs/cycles" ]; then
  exit 0
fi

FLAG_DIR="${HOME}/.claude/dev-crew"
PROJECT_HASH=$(pwd | md5 -q 2>/dev/null || echo "$PWD" | md5sum | cut -d' ' -f1)
FLAG_FILE="${FLAG_DIR}/.plan-approved-${PROJECT_HASH}"

mkdir -p "$FLAG_DIR"
date -u +"%Y-%m-%dT%H:%M:%SZ" > "$FLAG_FILE"

echo "Plan approved. Run /orchestrate to start the TDD cycle. Direct Edit/Write is blocked until orchestrate starts."
