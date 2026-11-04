#!/bin/bash
# pre-approve-gate.sh - check the Plan Review Record before approval
#
# Purpose: before ExitPlanMode, confirm the same hash match that pre-red-gate
#   runs after approval, plus plan_presented. Stopping after approval is too late
#   because the plan can no longer be fixed, so the omission is caught here.
#   Only the plan file is read; the Record section (from the whole-line
#   "## Plan Review Record" heading to the next "## " heading) is the only place
#   the fields are looked up.
#
# Usage: bash pre-approve-gate.sh <plan file>
# Exit codes:
#   0 - PASS
#   1 - BLOCK (reason on stdout)

set -euo pipefail

plan="${1:-}"

if [ -z "$plan" ] || [ ! -f "$plan" ]; then
  echo "BLOCK: plan file not given or not found: ${plan:-<none>}"
  exit 1
fi

if ! grep -qxF -- '## Plan Review Record' "$plan"; then
  echo "BLOCK: plan does not contain a '## Plan Review Record' heading."
  exit 1
fi

record=$(awk '
  !f && $0=="## Plan Review Record" {f=1; next}
  f && /^## / {exit}
  f {print}
' "$plan")

# Last line wins, as in pre-red-gate (iv); otherwise a duplicated line passes here
# but blocks after approval.
hash_line=$(grep '^- reviewed_plan_hash:' <<< "$record" | tail -1 || true)
if [ -z "$hash_line" ]; then
  echo "BLOCK: Plan Review Record has no '- reviewed_plan_hash:' line."
  exit 1
fi
recorded_hash=$(grep -oE '[0-9a-fA-F]{64}' <<< "$hash_line" | head -n1 || true)
if [ -z "$recorded_hash" ]; then
  echo "BLOCK: reviewed_plan_hash has no 64-hex value."
  exit 1
fi

# CDPATH= keeps cd from echoing the directory, which would make the path two lines.
hasher="$(CDPATH= cd "$(dirname "$0")" && pwd)/plan-hash.sh"
if ! computed_hash=$(bash "$hasher" "$plan" 2>&1); then
  echo "BLOCK: could not compute plan hash: $computed_hash"
  exit 1
fi
if [ "$computed_hash" != "$recorded_hash" ]; then
  echo "BLOCK: reviewed_plan_hash mismatch (recorded=$recorded_hash, computed=$computed_hash). The plan changed after the last review."
  exit 1
fi

presented_line=$(grep -m1 '^- plan_presented:' <<< "$record" || true)
if [ -z "$presented_line" ]; then
  echo "BLOCK: Plan Review Record has no '- plan_presented:' line."
  exit 1
fi
presented_value=${presented_line#- plan_presented:}
presented_value=${presented_value# }
if ! grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}' <<< "$presented_value"; then
  echo "BLOCK: plan_presented must start with 'YYYY-MM-DD HH:MM' (got: '$presented_value')."
  exit 1
fi

echo "PASS: reviewed_plan_hash matches and plan_presented is filled."
exit 0
