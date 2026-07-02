#!/bin/bash
# pre-commit-gate.sh - Deterministic gate before COMMIT phase
#
# Purpose:
#   LLMはレビューなしでCOMMITに直行することがある。
#   このスクリプトはCycle docの状態を機械的に検証し、
#   REVIEW（+ Codex competitive review）が完了していなければ
#   COMMITフェーズへの遷移をBLOCKする。
#   CONSTITUTION.md 原則6「決定論的プロセス保証」の実装。
#
# Usage: pre-commit-gate.sh [project_root]
# Exit 0 = PASS, Exit 1 = BLOCK
#
# Checks:
#   1. REVIEW Phase completed in Progress Log
#   2. Codex code review recorded (only when `which codex` succeeds)
#   3. STATUS.md test script count sync warning (non-blocking)
#   4. Retrospective status (retro_status: captured/resolved required;
#      none/empty/invalid/absent all BLOCK — absent is a bypass risk since
#      cycle-retrospective idempotency also treats absent as skip)

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
    echo "BLOCK: No active Cycle doc found."
    exit 1
  fi
  echo "Active Cycle: $ACTIVE_CYCLE"
else
  echo "BLOCK: invalid argument '$ARG' (expected project root dir or cycle doc .md path)"
  exit 1
fi

# 1. Check REVIEW record in Progress Log (anchored to phase header)
if ! awk '/^### .* - REVIEW/,/Phase completed/' "$ACTIVE_CYCLE" | grep -qi 'Phase completed'; then
  echo "BLOCK: REVIEW not completed in Progress Log. Run review before commit."
  exit 1
fi

# 2. Codex code review check (only when codex is available)
if which codex > /dev/null 2>&1; then
  if ! grep -qiE 'Codex.*review|codex.*Review' "$ACTIVE_CYCLE" 2>/dev/null; then
    echo "BLOCK: Codex code review not recorded. Run competitive review before commit."
    exit 1
  fi
fi

# 3. STATUS.md test script count sync warning (non-blocking)
STATUS_FILE="$PROJECT_ROOT/docs/STATUS.md"
if [ -f "$STATUS_FILE" ]; then
  recorded_count=$(grep -oE 'Test Scripts \| [0-9]+' "$STATUS_FILE" 2>/dev/null | grep -oE '[0-9]+' || echo "")
  if [ -n "$recorded_count" ]; then
    actual_count=$(ls "$PROJECT_ROOT"/tests/test-*.sh 2>/dev/null | wc -l | tr -d ' ')
    if [ "$recorded_count" != "$actual_count" ]; then
      echo "WARN: STATUS.md test script count mismatch (recorded: $recorded_count, actual: $actual_count). Consider updating STATUS.md."
    fi
  fi
fi

# 4. Retrospective check (defense in depth with validate-cycle-frontmatter.sh).
#    Since A1, retro_status is mandatory for new Cycle docs (sync-plan initializes it).
#    Field absence would allow bypass (merge conflict, manual removal) because
#    cycle-retrospective's idempotency also treats absent as skip — gate must BLOCK.
retro_status_line=$(awk '/^---$/{c++;next} c==1{print}' "$ACTIVE_CYCLE" | grep '^retro_status:' | head -1 || true)
if [ -z "$retro_status_line" ]; then
  echo "BLOCK: retro_status field missing from frontmatter. Add 'retro_status: none' and run cycle-retrospective."
  exit 1
fi
retro_status=$(echo "$retro_status_line" | sed 's/^retro_status: *//')
case "$retro_status" in
  captured|resolved) ;;  # PASS
  none)
    echo "BLOCK: retro_status=none. Run cycle-retrospective before commit."
    exit 1 ;;
  "")
    echo "BLOCK: retro_status is present but empty. Set to one of: none | captured | resolved."
    exit 1 ;;
  *)
    echo "BLOCK: invalid retro_status value: '$retro_status' (expected: none | captured | resolved)."
    exit 1 ;;
esac

echo "PASS: All pre-COMMIT gate checks passed."
exit 0
