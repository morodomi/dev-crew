#!/bin/bash
# careful-guard.sh - PreToolUse hook for Bash
# Blocks dangerous commands: rm -rf /, DROP TABLE/DATABASE, git push --force,
# git reset --hard, kubectl delete.
# Exit 2 = block the tool call.

set -euo pipefail

# Read all stdin
INPUT=$(cat)

# If stdin is empty or whitespace-only, allow
if [ -z "$(echo "$INPUT" | tr -d '[:space:]')" ]; then
  exit 0
fi

# Extract command: jq preferred, grep fallback
if command -v jq >/dev/null 2>&1; then
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null) || COMMAND="$INPUT"
else
  COMMAND="$INPUT"
fi

# --- rm -rf / or rm -rf ~ detection ---
# Block only when targeting / or ~ (root/home), NOT /tmp or other subdirs.
# Pattern: rm with -rf/-fr/etc flags followed by / or ~ (end or space), but NOT /something
if echo "$COMMAND" | grep -qE 'rm\s+(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r|--recursive)\s+(/\s*$|/\s+|~/|~\s*$)'; then
  echo "BLOCKED: rm -rf targeting root (/) or home (~) is prohibited." >&2
  exit 2
fi

# --- DROP TABLE / DROP DATABASE detection (case-insensitive) ---
if echo "$COMMAND" | grep -qiE '\b(DROP\s+(TABLE|DATABASE))\b'; then
  echo "BLOCKED: DROP TABLE/DATABASE is prohibited." >&2
  exit 2
fi

# --- git push --force / -f detection (but NOT --force-with-lease) ---
# First, neutralize --force-with-lease by removing it, then check for --force or -f
COMMAND_NO_LEASE=$(echo "$COMMAND" | sed 's/--force-with-lease[^[:space:]]*//g')
if echo "$COMMAND_NO_LEASE" | grep -qE 'git\s+push\s+.*(-f\b|--force\b)'; then
  echo "BLOCKED: git push --force/-f is prohibited. Use --force-with-lease instead." >&2
  exit 2
fi

# --- git reset --hard detection ---
if echo "$COMMAND" | grep -qE 'git\s+reset\s+--hard'; then
  echo "BLOCKED: git reset --hard is prohibited." >&2
  exit 2
fi

# --- kubectl delete detection ---
if echo "$COMMAND" | grep -qE 'kubectl\s+delete'; then
  echo "BLOCKED: kubectl delete is prohibited." >&2
  exit 2
fi

exit 0
