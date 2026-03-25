#!/bin/bash
# plan-exit-flag.sh - PostToolUse hook for ExitPlanMode
# Creates a flag file when plan mode is exited.
# The flag is cleared by orchestrate at startup.

set -o pipefail

# Only activate in dev-crew projects (has docs/cycles/ directory)
if [ ! -d "docs/cycles" ]; then
  exit 0
fi

FLAG_DIR="${CLAUDE_PLUGIN_DATA:-${HOME}/.claude/dev-crew}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PROJECT_HASH=$(echo "$PROJECT_DIR" | md5 -q 2>/dev/null || echo "$PROJECT_DIR" | md5sum | cut -d' ' -f1)
FLAG_FILE="${FLAG_DIR}/.plan-approved-${PROJECT_HASH}"

mkdir -p "$FLAG_DIR"
date -u +"%Y-%m-%dT%H:%M:%SZ" > "$FLAG_FILE"

echo "Plan approved. Run /orchestrate to start the TDD cycle. Direct Edit/Write is blocked until orchestrate starts."
