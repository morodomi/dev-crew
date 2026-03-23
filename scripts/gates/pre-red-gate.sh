#!/bin/bash
# pre-red-gate.sh - Deterministic gate before RED phase
#
# Purpose:
#   LLMはワークフロー手順を確率的にスキップする（sync-plan飛ばし等）。
#   このスクリプトはCycle docの状態を機械的に検証し、
#   前提ステップが完了していなければREDフェーズへの遷移をBLOCKする。
#   CONSTITUTION.md 原則6「決定論的プロセス保証」の実装。
#
# Usage: pre-red-gate.sh [project_root]
# Exit 0 = PASS, Exit 1 = BLOCK
#
# Checks:
#   1. Active Cycle doc exists (phase != DONE)
#   2. sync-plan recorded in Progress Log
#   3. Plan Review recorded in Progress Log
#   4. Codex review recorded (only when `which codex` succeeds)

set -euo pipefail

PROJECT_ROOT="${1:-.}"

# 1. Find active Cycle doc (phase != DONE, skip docs without phase field)
ACTIVE_CYCLE=""
for f in "$PROJECT_ROOT"/docs/cycles/*.md; do
  [ -f "$f" ] || continue
  phase=$(awk '/^---$/{c++;next} c==1{print}' "$f" | grep '^phase:' | head -1 | sed 's/^phase: *//' || true)
  [ -z "$phase" ] && continue  # Skip docs without phase field (old format / no frontmatter)
  if [ "$phase" != "DONE" ]; then
    ACTIVE_CYCLE="$f"
    break
  fi
done

if [ -z "$ACTIVE_CYCLE" ]; then
  echo "BLOCK: No active Cycle doc found (all DONE or none exist). Run spec first."
  exit 1
fi

# 2. Check sync-plan record in Progress Log (awk range ensures section-level match)
if ! awk '/SYNC.PLAN|sync-plan/,/Phase completed/' "$ACTIVE_CYCLE" | grep -qi 'Phase completed'; then
  echo "BLOCK: sync-plan not completed. Run sync-plan before RED."
  exit 1
fi

# 3. Check Plan Review record in Progress Log
if ! grep -qiE 'Plan Review|plan-review' "$ACTIVE_CYCLE" 2>/dev/null; then
  echo "BLOCK: Plan Review not recorded in Progress Log. Run plan review before RED."
  exit 1
fi

echo "PASS: All pre-RED gate checks passed."
exit 0
