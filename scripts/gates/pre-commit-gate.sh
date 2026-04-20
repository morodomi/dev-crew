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
#      field absence allowed for legacy compat with WARN)

set -euo pipefail

PROJECT_ROOT="${1:-.}"

# Find active Cycle doc (skip docs without phase field)
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
  echo "BLOCK: No active Cycle doc found."
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

# 4. Retrospective check (legacy compat: only enforce when retro_status field exists,
#    but strict value validation — defense in depth with validate-cycle-frontmatter.sh)
retro_status_line=$(awk '/^---$/{c++;next} c==1{print}' "$ACTIVE_CYCLE" | grep '^retro_status:' | head -1 || true)
if [ -z "$retro_status_line" ]; then
  echo "WARN: retro_status field absent (legacy doc). Consider running cycle-retrospective for new cycles."
else
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
fi

echo "PASS: All pre-COMMIT gate checks passed."
exit 0
