#!/bin/bash
# observe.sh - PostToolUse hook
# Records tool usage observations to JSONL for pattern extraction.
# Reads PostToolUse JSON from stdin, appends to observations/log.jsonl.

set -uo pipefail

# Read all stdin
INPUT=$(cat)

# If stdin is empty or whitespace-only, exit silently
if [ -z "$(echo "$INPUT" | tr -d '[:space:]')" ]; then
  exit 0
fi

# Check jq availability
if ! command -v jq >/dev/null 2>&1; then
  echo "warning: jq is not installed. observe.sh requires jq to process JSON." >&2
  exit 0
fi

# Determine output directory
OBS_DIR="${HOME}/.claude/dev-crew/observations"
mkdir -p "$OBS_DIR"

# Extract fields and build output JSON in a single jq call
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo "$INPUT" | jq -c --arg timestamp "$TIMESTAMP" \
  '{timestamp: $timestamp, session_id: .session_id, tool_name: .tool_name, target: (.tool_input.file_path // .tool_input.command // "")}' \
  >> "$OBS_DIR/log.jsonl"
