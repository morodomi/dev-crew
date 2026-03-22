#!/bin/bash
# no-verify-guard.sh - PreToolUse hook for Bash
# Blocks any Bash command containing --no-verify.
# Exit 2 = block the tool call.

set -euo pipefail

# Read all stdin
INPUT=$(cat)

# If stdin is empty or whitespace-only, allow
if [ -z "$(echo "$INPUT" | tr -d '[:space:]')" ]; then
  exit 0
fi

# Extract command: jq preferred, grep fallback
# NO_VERIFY_GUARD_SKIP_JQ=1 forces fallback path (for testing)
if [ "${NO_VERIFY_GUARD_SKIP_JQ:-}" != "1" ] && command -v jq >/dev/null 2>&1; then
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null) || COMMAND="$INPUT"
else
  # jq absent or skipped: check entire INPUT (safe side)
  COMMAND="$INPUT"
fi

# Detect --no-verify → block
if echo "$COMMAND" | grep -q -- '--no-verify'; then
  echo "BLOCKED: --no-verify is prohibited by git-safety rules." >&2
  echo "Remove --no-verify and let pre-commit hooks run." >&2
  exit 2
fi

exit 0
