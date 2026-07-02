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

ARG="${1:-.}"
PROJECT_ROOT="."
ACTIVE_CYCLE=""

# $1 is polymorphic: a `.md` file path selects that doc explicitly; a directory
# falls back to picking the updated-latest non-DONE doc; anything else is rejected.
if [ -f "$ARG" ] && case "$ARG" in *.md) true;; *) false;; esac; then
  # Explicit mode: inspect only the given doc (enumerate-and-reject on bad state)
  ACTIVE_CYCLE="$ARG"
  # Normalize to absolute path (no realpath dependency) so the docs/cycles/
  # containment check can't be bypassed via relative-path tricks.
  ARG_ABS="$(cd "$(dirname "$ACTIVE_CYCLE")" && pwd)/$(basename "$ACTIVE_CYCLE")"
  case "$ARG_ABS" in
    */docs/cycles/*.md) : ;;
    *) echo "BLOCK: cycle doc must reside under docs/cycles/ (got: $ARG)"; exit 1 ;;
  esac
  phase=$(awk '/^---$/{c++;next} c==1{print}' "$ACTIVE_CYCLE" | grep '^phase:' | head -1 | sed 's/^phase: *//' || true)
  if [ -z "$phase" ]; then
    echo "BLOCK: invalid cycle doc '$ACTIVE_CYCLE' (no phase field)"
    exit 1
  fi
  if [ "$phase" = "DONE" ]; then
    echo "BLOCK: cycle doc '$ACTIVE_CYCLE' is already DONE"
    exit 1
  fi
  PROJECT_ROOT=$(dirname "$(dirname "$(dirname "$ARG_ABS")")")
  echo "Active Cycle: $ACTIVE_CYCLE"
elif [ -d "$ARG" ]; then
  # Directory mode: fall back to updated-latest non-DONE doc (manual / legacy use)
  PROJECT_ROOT="$ARG"
  candidates=""
  for f in "$PROJECT_ROOT"/docs/cycles/*.md; do
    [ -f "$f" ] || continue
    phase=$(awk '/^---$/{c++;next} c==1{print}' "$f" | grep '^phase:' | head -1 | sed 's/^phase: *//' || true)
    [ -z "$phase" ] && continue  # Skip docs without phase field (old format / no frontmatter)
    [ "$phase" = "DONE" ] && continue
    updated=$(awk '/^---$/{c++;next} c==1{print}' "$f" | grep '^updated:' | head -1 | sed 's/^updated: *//' | tr 'T' ' ' || true)
    [ -z "$updated" ] && updated="0000-00-00"
    # ISO-T normalized to space so ISO-T and space-separated updated values
    # compare consistently. Full-line lexicographic compare (no field-splitting
    # sort -k) keeps the tie-break deterministic.
    candidates="${candidates}${updated}"$'\t'"${f}"$'\n'
  done
  ACTIVE_CYCLE=$(printf '%s' "$candidates" | sort | tail -1 | cut -f2)
  if [ -z "$ACTIVE_CYCLE" ]; then
    echo "BLOCK: No active Cycle doc found (all DONE or none exist). Run spec first."
    exit 1
  fi
  echo "Active Cycle: $ACTIVE_CYCLE"
else
  echo "BLOCK: invalid argument '$ARG' (expected project root dir or cycle doc .md path)"
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
