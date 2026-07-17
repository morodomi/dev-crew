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
# Checks (code review accept-apply, cycle 20260717_1126_approval-reorder):
#   1. Active Cycle doc exists (phase != DONE)
#   2. sync-plan completion: heading-anchored Progress Log entry scan — at least one
#      "### "-delimited entry (heading text + body) contains both "sync-plan"
#      (SYNC-PLAN/sync-plan) and "Phase completed". Anchoring to entry boundaries
#      (not a whole-doc substring-to-substring range) prevents an unrelated later
#      entry's "Phase completed" from false-PASSing an earlier casual mention.
#   3. Plan Review completion. Two paths, gated by a strict-required discriminator:
#      - Strict "Plan Review (pre-approval)" contract is REQUIRED when frontmatter
#        has a `plan_file:` field OR any "### " heading contains "(pre-approval)".
#        If required but the exact heading isn't found, BLOCK (no legacy fallback).
#        Strict sub-checks, 1:1 with code below:
#          (i)    Phase completed marker present
#          (ii)   codex_session_id field present; if its value is empty, an
#                 `extraction_failed: true` or `codex_unavailable: true` companion
#                 field must be present in the same entry
#          (iii)  review_attempts field present, with >=1 nested `{started: ...}`
#                 item (0 items allowed only when codex_unavailable: true)
#          (iv)   reviewed_plan_hash field present with a valid 64-hex-char token
#          (v)    [SECURITY] plan_file trust boundary: frontmatter plan_file must
#                 resolve to an absolute path under the trusted plan directory
#                 (${DEV_CREW_PLAN_DIR:-$HOME/.claude/plans}), checked BEFORE the
#                 file is opened/hashed — otherwise a crafted plan_file value turns
#                 this gate into a read/hash oracle for an arbitrary file
#          (vi)   plan_file contains a whole-line "## Plan Review Record" heading
#                 (prevents a heading-less plan from hashing as "whole file" and
#                 coincidentally matching a recorded hash)
#          (vii)  reviewed_plan_hash real match: canonical hash re-derived from
#                 plan_file (content strictly above the "## Plan Review Record"
#                 line) must equal the recorded token — decisive re-computation,
#                 not trust
#          (viii) verdict enumerate: value must be exactly one of
#                 PASS / WARN / BLOCK-overridden / BLOCK, optionally followed by a
#                 space/paren-delimited annotation (rejects near-miss values like
#                 "PASSING")
#          (ix)   unresolved_blocks consistency: PASS/WARN requires the value to be
#                 empty or exactly "なし"/"none" (optionally annotated); anything
#                 else requires verdict: BLOCK-overridden
#          (x)    BLOCK-overridden requires a non-empty "- override: <reason>" line;
#                 bare BLOCK (no override) always BLOCKs
#      - Legacy "Plan Review" heading (pre-existing cycle docs, neither plan_file
#        frontmatter nor any "(pre-approval)" heading): weak heading-anchored
#        presence check only, preserved for backward compatibility.
#
# SIGPIPE safety: every check below either reads its subject via a single direct
# `awk '...' file` (no pipe) or captures output into a variable first and greps the
# variable via a herestring (`grep ... <<< "$var"`, no pipe). A `producer | grep -q`
# pipe lets grep close its stdin after the first match, which can SIGPIPE a
# still-writing producer on a large range (rc=141 under `set -o pipefail`, observed
# on this cycle doc's own ~20KB+ Progress Log) — turning a real PASS into a false
# BLOCK. No check in this script may reintroduce that pattern.

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

# 2. sync-plan completion (heading-anchored Progress Log entry scan)
#
# Each "### "-delimited entry (heading line + body, up to but not including the
# next "### " heading) is tested independently for both substrings. This replaces
# a prior whole-doc range scan (`awk '/SYNC.PLAN|sync-plan/,/Phase completed/'`)
# that started at ANY substring occurrence of "sync-plan" anywhere in the doc body
# (even unrelated prose) and read through to the next "Phase completed" anywhere
# after it — a false-PASS surface an unrelated later entry could satisfy. Single
# direct-file awk read (no pipe): safe against SIGPIPE by construction.
if ! awk '
  /^### / {
    if ((entry ~ /SYNC.PLAN/ || entry ~ /sync-plan/) && entry ~ /Phase completed/) { found=1; exit }
    entry=$0
    next
  }
  { entry = entry "\n" $0 }
  END {
    if (!found && (entry ~ /SYNC.PLAN/ || entry ~ /sync-plan/) && entry ~ /Phase completed/) { found=1 }
    exit !found
  }
' "$ACTIVE_CYCLE"; then
  echo "BLOCK: sync-plan not completed. Run sync-plan before RED."
  exit 1
fi

# 3. Plan Review completion
#
# Strict-required discriminator: if frontmatter declares `plan_file:` OR any
# "### " heading contains "(pre-approval)", the strict contract is mandatory —
# falling back to the legacy weak check in that situation would let a doc that
# clearly opted into the new contract slip through on a malformed/renamed entry.
plan_file_present_fm=false
if awk '/^---$/{c++;next} c==1{print}' "$ACTIVE_CYCLE" | grep -q '^plan_file:'; then
  plan_file_present_fm=true
fi
pre_approval_heading_anywhere=false
if grep -qE '^### .*\(pre-approval\)' "$ACTIVE_CYCLE"; then
  pre_approval_heading_anywhere=true
fi
strict_required=false
if $plan_file_present_fm || $pre_approval_heading_anywhere; then
  strict_required=true
fi

# Heading-anchored (not whole-file substring) so casual body-text mentions of
# "plan-review" don't false-PASS a doc with no real record. `tail -1` selects the
# most recent entry if the (append-only) Progress Log has more than one.
pre_approval_heading_line=$(grep -n '^### .* - Plan Review (pre-approval)$' "$ACTIVE_CYCLE" | tail -1 | cut -d: -f1 || true)

if [ -n "$pre_approval_heading_line" ]; then
  # --- Strict "Plan Review (pre-approval)" contract ---

  # Single direct-file awk read (no pipe): stop at the next "### " heading (never
  # cross into a later Progress Log entry) or at this entry's own "- Phase
  # completed" line, whichever comes first.
  section=$(awk -v start="$pre_approval_heading_line" '
    NR==start { print; next }
    NR>start {
      if (/^### /) { exit }
      print
      if (/^- Phase completed$/) { exit }
    }
  ' "$ACTIVE_CYCLE")

  # (i) Phase completed marker present
  if ! grep -qF -- '- Phase completed' <<< "$section"; then
    echo "BLOCK: Plan Review (pre-approval) entry is missing the 'Phase completed' marker."
    exit 1
  fi

  # (ii) codex_session_id field must exist. Its value may legitimately be empty
  # (3-tier session-id extraction failure) but only when paired with an explicit
  # degraded-state marker, so the empty state is provably intentional rather than
  # a silently dropped field.
  if ! grep -q '^- codex_session_id:' <<< "$section"; then
    echo "BLOCK: Plan Review (pre-approval) entry is missing the codex_session_id field."
    exit 1
  fi
  codex_session_id_value=$(grep '^- codex_session_id:' <<< "$section" | tail -1 | sed 's/^- codex_session_id: *//' || true)
  codex_unavailable_flag=false
  if grep -qE '^- codex_unavailable: true' <<< "$section"; then
    codex_unavailable_flag=true
  fi
  if [ -z "$codex_session_id_value" ] || [ "$codex_session_id_value" = '""' ]; then
    if ! grep -qE '^- (extraction_failed|codex_unavailable): true' <<< "$section"; then
      echo "BLOCK: codex_session_id is empty but neither 'extraction_failed: true' nor 'codex_unavailable: true' was found."
      exit 1
    fi
  fi

  # (iii) review_attempts field required; >=1 nested {started: ...} item required
  # unless Codex was unavailable for this review (codex_unavailable: true), in
  # which case an empty review_attempts list is the expected degraded state.
  if ! grep -q '^- review_attempts:' <<< "$section"; then
    echo "BLOCK: Plan Review (pre-approval) entry is missing the review_attempts field."
    exit 1
  fi
  review_attempt_items=$(grep -c '^  - {started:' <<< "$section" || true)
  if [ "$review_attempt_items" -eq 0 ] && [ "$codex_unavailable_flag" != "true" ]; then
    echo "BLOCK: Plan Review (pre-approval) entry's review_attempts has no nested {started: ...} items (and codex_unavailable is not true)."
    exit 1
  fi

  # (iv) reviewed_plan_hash field required with a valid 64-hex-char token
  # (trailing prose on the same line, e.g. a correction note, is tolerated —
  # only the first 64-hex-char run is taken as the value).
  if ! grep -q '^- reviewed_plan_hash:' <<< "$section"; then
    echo "BLOCK: Plan Review (pre-approval) entry is missing the reviewed_plan_hash field."
    exit 1
  fi
  hash_value=$(grep '^- reviewed_plan_hash:' <<< "$section" | tail -1 | sed 's/^- reviewed_plan_hash: *//' || true)
  hash_token=$(grep -oE '[0-9a-f]{64}' <<< "$hash_value" | head -1 || true)
  if [ -z "$hash_token" ]; then
    echo "BLOCK: reviewed_plan_hash value does not contain a valid 64-hex-char hash token."
    exit 1
  fi

  # (v) [SECURITY] plan_file trust boundary — checked BEFORE the file is opened.
  # Without this, a crafted frontmatter `plan_file:` pointing anywhere on disk
  # would turn this gate into a read/hash oracle for an arbitrary file the gate
  # process can access. Resolve symlinks in the containing directory (not the
  # leaf file) via `cd && pwd -P` before comparing.
  # DEV_CREW_PLAN_DIR: test-fixture override only; production always uses
  # $HOME/.claude/plans (real plan mode files never live elsewhere).
  plan_file=$(awk '/^---$/{c++;next} c==1{print}' "$ACTIVE_CYCLE" | grep '^plan_file:' | head -1 | sed 's/^plan_file: *//' || true)
  if [ -z "$plan_file" ] || [ ! -f "$plan_file" ]; then
    echo "BLOCK: frontmatter plan_file is missing or unreadable; cannot verify reviewed_plan_hash."
    exit 1
  fi
  case "$plan_file" in
    /*) : ;;
    *) echo "BLOCK: frontmatter plan_file must be an absolute path (got: $plan_file)"; exit 1 ;;
  esac
  PLAN_DIR_TRUSTED="${DEV_CREW_PLAN_DIR:-$HOME/.claude/plans}"
  plan_file_dir_abs="$(cd "$(dirname "$plan_file")" 2>/dev/null && pwd -P)" || plan_file_dir_abs=""
  plan_dir_trusted_abs="$(cd "$PLAN_DIR_TRUSTED" 2>/dev/null && pwd -P)" || plan_dir_trusted_abs=""
  if [ -z "$plan_file_dir_abs" ] || [ -z "$plan_dir_trusted_abs" ]; then
    echo "BLOCK: frontmatter plan_file or trusted plan directory ($PLAN_DIR_TRUSTED) could not be resolved."
    exit 1
  fi
  case "$plan_file_dir_abs" in
    "$plan_dir_trusted_abs"|"$plan_dir_trusted_abs"/*) : ;;
    *) echo "BLOCK: frontmatter plan_file must reside under the trusted plan directory ($PLAN_DIR_TRUSTED), got directory: $plan_file_dir_abs"; exit 1 ;;
  esac

  # (vi) plan_file must contain a whole-line "## Plan Review Record" heading.
  # Without this, a plan lacking the heading entirely would hash as "whole file"
  # under the canonical algorithm below and could coincidentally match a recorded
  # hash — this check makes the presence of a real Record section decisive rather
  # than incidental. `-x` requires the FULL line to equal the heading text.
  if ! grep -qxF -- '## Plan Review Record' "$plan_file"; then
    echo "BLOCK: plan_file does not contain a '## Plan Review Record' heading; cannot verify reviewed_plan_hash."
    exit 1
  fi

  # (vii) reviewed_plan_hash real match. Canonical algorithm: sha256 of all
  # content strictly above the first line that is exactly "## Plan Review Record"
  # (line-equality, not substring split — a prior substring-split implementation
  # truncated mid-body on an incidental quoted occurrence of the same heading
  # text). Decisive re-computation from plan_file, not trust in the recorded value.
  computed_hash=$(awk '$0=="## Plan Review Record"{exit}{print}' "$plan_file" | shasum -a 256 | awk '{print $1}')
  if [ "$computed_hash" != "$hash_token" ]; then
    echo "BLOCK: reviewed_plan_hash mismatch (recorded=$hash_token, computed=$computed_hash from plan_file=$plan_file)."
    exit 1
  fi

  # (viii) verdict enumerate: the value must be exactly one of the four known
  # tokens, optionally followed by a space/paren-delimited annotation (e.g. the
  # real cycle doc's "WARN（attempt 2 の残指摘は...）"). This rejects near-miss
  # values like "PASSING" that a prefix-glob match (`PASS*`) would wrongly accept.
  if ! grep -q '^- verdict:' <<< "$section"; then
    echo "BLOCK: Plan Review (pre-approval) entry is missing the verdict field."
    exit 1
  fi
  verdict_line=$(grep '^- verdict:' <<< "$section" | tail -1)
  VERDICT_PATTERN='^- verdict: (PASS|WARN|BLOCK-overridden|BLOCK)([ （(].*)?$'
  if ! grep -qE "$VERDICT_PATTERN" <<< "$verdict_line"; then
    echo "BLOCK: Plan Review (pre-approval) verdict field is missing, placeholder, or not one of PASS/WARN/BLOCK-overridden/BLOCK (line: '$verdict_line')."
    exit 1
  fi
  verdict_token=$(sed -E 's/^- verdict: (PASS|WARN|BLOCK-overridden|BLOCK).*$/\1/' <<< "$verdict_line")

  # (ix) unresolved_blocks consistency + (x) BLOCK-overridden override evidence.
  if ! grep -q '^- unresolved_blocks:' <<< "$section"; then
    echo "BLOCK: Plan Review (pre-approval) entry is missing the unresolved_blocks field."
    exit 1
  fi
  unresolved_raw=$(grep '^- unresolved_blocks:' <<< "$section" | tail -1 | sed 's/^- unresolved_blocks: *//' || true)
  UNRESOLVED_EMPTY_PATTERN='^(なし|none)([ （(].*)?$'
  unresolved_is_empty=false
  if [ -z "$unresolved_raw" ] || grep -qE "$UNRESOLVED_EMPTY_PATTERN" <<< "$unresolved_raw"; then
    unresolved_is_empty=true
  fi

  case "$verdict_token" in
    PASS|WARN)
      if [ "$unresolved_is_empty" != "true" ]; then
        echo "BLOCK: verdict is '$verdict_token' but unresolved_blocks is non-empty ('$unresolved_raw'). Unresolved BLOCKs require verdict: BLOCK-overridden."
        exit 1
      fi
      ;;
    BLOCK-overridden)
      if ! grep -qE '^- override: [^ ]' <<< "$section"; then
        echo "BLOCK: verdict is BLOCK-overridden but '- override:' evidence is missing or empty."
        exit 1
      fi
      ;;
    BLOCK)
      echo "BLOCK: verdict is BLOCK without override evidence. Use 'BLOCK-overridden' with an explicit '- override:' line after human approval."
      exit 1
      ;;
  esac
elif $strict_required; then
  echo "BLOCK: strict Plan Review (pre-approval) contract is required (plan_file frontmatter present or a '(pre-approval)' heading exists), but no exact 'Plan Review (pre-approval)' heading was found. Legacy fallback is not permitted for this doc."
  exit 1
else
  # --- Legacy "Plan Review" heading (pre-existing cycle docs, neither
  #     plan_file frontmatter nor a "(pre-approval)" heading present) ---
  # Heading-anchored (not whole-file substring) so casual body-text mentions of
  # "plan-review" don't false-PASS a doc with no real record.
  if ! grep -qE '^### .*(Plan Review|plan-review)' "$ACTIVE_CYCLE"; then
    echo "BLOCK: Plan Review (pre-approval) entry not found in Progress Log. Run plan review before RED."
    exit 1
  fi
fi

echo "PASS: All pre-RED gate checks passed."
exit 0
