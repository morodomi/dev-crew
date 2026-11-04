#!/bin/bash
# plan-hash.sh - canonical reviewed_plan_hash of a plan file
#
# Purpose: the single implementation of the hash. pre-approve-gate.sh and
#   pre-red-gate.sh both call it so that the two checks cannot drift apart.
#   Algorithm: sha256 of everything strictly above the first line that is
#   exactly "## Plan Review Record" (whole-line match, not substring split —
#   a quoted occurrence of the heading text in the body must not cut the hash).
#
# Usage: bash plan-hash.sh <plan file>
# Output: 64-hex sha256 on stdout
# Exit codes:
#   0 - hash printed
#   1 - no argument, file missing, or no whole-line "## Plan Review Record" heading

set -euo pipefail

plan="${1:-}"

if [ -z "$plan" ]; then
  echo "plan-hash: usage: plan-hash.sh <plan file>" >&2
  exit 1
fi

if [ ! -f "$plan" ]; then
  echo "plan-hash: file not found: $plan" >&2
  exit 1
fi

if ! grep -qxF -- '## Plan Review Record' "$plan"; then
  echo "plan-hash: no '## Plan Review Record' heading in $plan" >&2
  exit 1
fi

awk '$0=="## Plan Review Record"{exit}{print}' "$plan" | shasum -a 256 | awk '{print $1}'
