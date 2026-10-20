#!/bin/bash
# pre-commit-gate.sh - Deterministic gate before COMMIT phase
#
# Purpose:
#   LLMはレビューなしでCOMMITに直行することがある。
#   このスクリプトはCycle docの状態を機械的に検証し、
#   REVIEW（敵対的レビュー 1 回 + 指摘の振り分け。skills/orchestrate/adversarial-review.md）が
#   完了していなければ COMMITフェーズへの遷移をBLOCKする。
#   CONSTITUTION.md 原則6「決定論的プロセス保証」の実装。
#
# Usage: pre-commit-gate.sh [project_root]
# Exit 0 = PASS, Exit 1 = BLOCK
#
# Checks:
#   1・2 は「最後の `### ... - REVIEW` 見出しから次の `### ` 見出しの手前まで」の節だけを見る
#   1. REVIEW Phase completed in Progress Log
#   2. Codex review count line recorded (only when `which codex` succeeds).
#      `- Codex review: 直す N / 人間に戻す M / 記録のみ K`、または代行の形
#      `- Codex review: 失敗（<理由>）。adversarial-reviewer で代行: ...`。Codex が無い環境は
#      `- Adversarial review: ...` で足りる（この検査自体が走らない）
#   3. Retrospective status (retro_status: captured/resolved required;
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

# REVIEW が複数回走った cycle では最後の REVIEW 節だけが現在の判定対象。
# 節の範囲は「最後の `### ... - REVIEW` 見出しから次の `### ` 見出しの手前まで」。
# Plan Review Record や後続の COMMIT 節にある似た行で検査が通らないようにする。
# コードブロック内の `### ` 行は見出しではないので、節の開始にも終端にも使わない。
REVIEW_SECTION=$(awk '
  /^```/ { fence = !fence }
  !fence && /^### / { on = ($0 ~ /^### .* - REVIEW/); if (on) buf = "" }
  on { buf = buf $0 "\n" }
  END { printf "%s", buf }
' "$ACTIVE_CYCLE")

# 1. Check REVIEW record in Progress Log (anchored to phase header)
if ! grep -qi 'Phase completed' <<<"$REVIEW_SECTION"; then
  echo "BLOCK: REVIEW not completed in Progress Log. Run the REVIEW phase (adversarial review, see skills/orchestrate/adversarial-review.md) before commit."
  exit 1
fi

# 2. Codex code review check (only when codex is available)
COUNT_RE='^- Codex review: (失敗（[^）]*）。adversarial-reviewer で代行: )?直す [0-9]+ / 人間に戻す [0-9]+ / 記録のみ [0-9]+'
if which codex > /dev/null 2>&1; then
  if ! grep -qE "$COUNT_RE" <<<"$REVIEW_SECTION"; then
    echo "BLOCK: Codex review result not recorded. Record the REVIEW count line ('- Codex review: 直す N / 人間に戻す M / 記録のみ K', or the adversarial-reviewer substitute form) in the REVIEW entry before commit."
    exit 1
  fi
fi

# 3. Retrospective check (defense in depth with validate-cycle-frontmatter.sh).
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
