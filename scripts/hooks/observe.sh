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
DATA_DIR="${CLAUDE_PLUGIN_DATA:-${HOME}/.claude/dev-crew}"
OBS_DIR="${DATA_DIR}/observations"
mkdir -p "$OBS_DIR"

# Cache plugin source path for evolve --contribute
printf '%s\n' "$(cd "$(dirname "$0")/../.." && pwd)" > "${DATA_DIR}/source-path" 2>/dev/null || true

# Filter out read-only Bash commands to reduce noise
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')
if [ "$TOOL_NAME" = "Bash" ]; then
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')
  # Skip read-only commands: ls, cat, head, tail, grep, find, wc, echo, which, type, file
  READ_ONLY_PATTERN='^[[:space:]]*(ls|cat|head|tail|grep|rg|find|wc|echo|which|type|file|pwd|date|whoami|uname|env|printenv|hostname|id|df|du|stat|realpath|dirname|basename|readlink|jq -r|jq -e|jq -c)[[:space:]]'
  if echo "$COMMAND" | grep -qE "$READ_ONLY_PATTERN"; then
    exit 0
  fi
fi

# Extract fields and build output JSON in a single jq call
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo "$INPUT" | jq -c --arg timestamp "$TIMESTAMP" \
  '{timestamp: $timestamp, session_id: .session_id, tool_name: .tool_name, target: (.tool_input.file_path // .tool_input.command // "")}' \
  >> "$OBS_DIR/log.jsonl"
