#!/bin/bash
# pre-compact.sh - PreCompact hook (manual only)
# Appends a snapshot entry to the latest Cycle doc's Progress Log
# before /compact clears conversation context.

set -uo pipefail

# Find latest Cycle doc
CYCLE_DOC=$(ls -t docs/cycles/*.md 2>/dev/null | head -1)

# No Cycle doc → no-op
if [ -z "$CYCLE_DOC" ]; then
  exit 0
fi

# Extract phase from "- status: PHASE" frontmatter
PHASE=$(grep -m1 '^- status: ' "$CYCLE_DOC" | sed 's/^- status: *//' || true)
if [ -z "$PHASE" ]; then
  PHASE="UNKNOWN"
fi

TIMESTAMP=$(date +"%Y-%m-%d %H:%M")

# Ensure Progress Log section exists
if ! grep -q "## Progress Log" "$CYCLE_DOC"; then
  printf '\n## Progress Log\n' >> "$CYCLE_DOC"
fi

# Append snapshot entry
printf '%s - PreCompact: phase=%s, snapshot saved\n' "$TIMESTAMP" "$PHASE" >> "$CYCLE_DOC"

exit 0
