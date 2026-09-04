#!/bin/bash
# severity-verdict.sh - Deterministic severity validation and verdict aggregation
# Usage: severity-verdict.sh validate <dir>
#        severity-verdict.sh verdict <triage.json> [--invalid <reviewer-name>]...
#
# validate <dir>:
#   For every <dir>/*.json file, checks (via jq) that it parses as JSON, that
#   the top-level value is an object, that .issues is an array of objects, and
#   that every issue's .severity is one of critical|important|optional. Every
#   jq access is type-guarded before use so a malformed shape (top-level array,
#   a non-object .issues element, etc.) always yields a contract "INVALID"
#   line -- never a raw jq runtime crash. Unknown keys (e.g. a legacy 0-100
#   self-score field a reviewer agent may still emit from a stale session
#   snapshot) are ignored on purpose -- rejecting on unknown keys would make
#   an in-flight migration from that legacy field unrecoverable via retry.
#   Output: one line per file, "OK <basename>" or "INVALID <basename>: <reason>"
#   (reason is a short, retry-prompt-safe sentence). A nonexistent directory or
#   a directory with zero *.json files is a hard error (exit 1, non-vacuous) --
#   never a silent exit 0. Exit 1 if any file is INVALID, exit 0 if all files
#   are OK. If jq is not on PATH, prints "DEGRADED: jq not found" and exits 0
#   (fail-open: caller falls back to the previous LLM-prose synthesis path
#   rather than treating a missing validator as a hard failure -- same degrade
#   direction as scripts/hooks/*).
#
# verdict <triage.json> [--invalid <name>]...:
#   triage.json is a JSON array of finding objects: {"severity": ..., "category": ...}
#   written by the PdM after 3-category triage (rules/review-triage.md). This
#   input is itself LLM-authored and is validated before use, with the same
#   type-guarded-before-access discipline as validate above: unparseable / not
#   an array / a non-object element / severity or category outside its enum ->
#   exit 2 with "INVALID-TRIAGE: <reason>" (a validation failure must never be
#   silently downgraded to PASS, and must never crash raw).
#   On success: findings with category accept-apply or accept-defer are
#   counted by severity (category reject is excluded -- rejected findings do
#   not influence the verdict, even if a rejected finding was critical).
#   critical>=1 -> BLOCK, else important>=1 -> WARN, else PASS.
#   --invalid <name> parsing is strict: only the exact two-token form is
#   accepted. `--invalid=<name>` (equals form), a trailing `--invalid` with no
#   value, and any unrecognized flag are usage errors (exit 64) -- a loosely
#   parsed flag would let a malformed invocation silently skip the floor
#   below. Each accepted <name> is normalized (a `dev-crew:` namespace prefix
#   and a `.json` filename suffix are both stripped) before the NON-NEGOTIABLE
#   comparison, so cosmetic name drift cannot bypass the floor. --invalid
#   security-reviewer or --invalid correctness-reviewer (post-normalization)
#   forces BLOCK (fail-closed NON-NEGOTIABLE floor: these two invariants must
#   never be silently skipped). Any other --invalid forces at least WARN,
#   without downgrading an already-BLOCK verdict. The floor is independent of
#   jq availability: jq's presence is checked only after --invalid parsing, so
#   a forced BLOCK still reaches stdout even when jq is absent (any DEGRADED
#   note in that case goes to stderr only, never stdout).
#   Output: "<BLOCK|WARN|PASS> critical:N important:N optional:N invalid:M",
#   exit 0.
#
# Enums:
#   severity: critical|important|optional
#   category: accept-apply|accept-defer|reject (rules/review-triage.md SSOT)

set -euo pipefail

SEVERITY_ENUM="critical|important|optional"
CATEGORY_ENUM="accept-apply|accept-defer|reject"

usage() {
  echo "Usage: $0 validate <dir>" >&2
  echo "       $0 verdict <triage.json> [--invalid <reviewer-name>]..." >&2
  exit 64
}

MODE="${1:-}"
[ -n "$MODE" ] || usage

case "$MODE" in
  validate)
    DIR="${2:-}"
    [ -n "$DIR" ] || usage

    if [ ! -d "$DIR" ]; then
      echo "ERROR: directory not found: $DIR" >&2
      exit 1
    fi

    if ! command -v jq >/dev/null 2>&1; then
      echo "DEGRADED: jq not found"
      exit 0
    fi

    ANY_INVALID=0
    FILE_COUNT=0
    for f in "$DIR"/*.json; do
      [ -f "$f" ] || continue
      FILE_COUNT=$((FILE_COUNT + 1))
      base=$(basename "$f")

      if ! jq -e . "$f" >/dev/null 2>&1; then
        echo "INVALID $base: not valid JSON"
        ANY_INVALID=1
        continue
      fi

      top_type=$(jq -r 'type' "$f")
      if [ "$top_type" != "object" ]; then
        echo "INVALID $base: top-level JSON must be an object (got $top_type)"
        ANY_INVALID=1
        continue
      fi

      issues_type=$(jq -r 'if has("issues") then (.issues | type) else "missing" end' "$f")
      if [ "$issues_type" = "missing" ]; then
        echo "INVALID $base: missing .issues field"
        ANY_INVALID=1
        continue
      fi
      if [ "$issues_type" != "array" ]; then
        echo "INVALID $base: .issues is not an array (got $issues_type)"
        ANY_INVALID=1
        continue
      fi

      # Type-guard every element before touching .severity: select(type=="object")
      # runs before the .severity access in the pipe, so a non-object element
      # (e.g. a bare string) never reaches a field access and cannot crash jq.
      # The ($s|type)!="string" guard must come before index(): jq's index()
      # treats an array argument as a subsequence search, so a non-string
      # severity like ["critical"] would pass the enum check while never
      # matching the string equality used in counting -- a critical finding
      # would silently vanish into "PASS critical:0".
      read -r bad_shape bad_severity <<EOF
$(jq -r --arg enum "$SEVERITY_ENUM" '
  ([.issues[] | select(type != "object")] | length) as $shape
  | ([.issues[] | select(type == "object") | select((.severity // "") as $s | ($s | type) != "string" or ($enum | split("|") | index($s)) == null)] | length) as $sev
  | "\($shape) \($sev)"
' "$f")
EOF
      if [ "$bad_shape" -gt 0 ]; then
        echo "INVALID $base: $bad_shape issue(s) in .issues are not objects"
        ANY_INVALID=1
        continue
      fi
      if [ "$bad_severity" -gt 0 ]; then
        echo "INVALID $base: $bad_severity issue(s) have .severity outside {critical,important,optional}"
        ANY_INVALID=1
        continue
      fi

      echo "OK $base"
    done

    if [ "$FILE_COUNT" -eq 0 ]; then
      echo "INVALID: no reviewer JSON files found"
      exit 1
    fi

    if [ "$ANY_INVALID" -eq 0 ]; then
      exit 0
    else
      exit 1
    fi
    ;;

  verdict)
    TRIAGE_FILE="${2:-}"
    [ -n "$TRIAGE_FILE" ] || usage
    shift 2

    INVALID_COUNT=0
    FORCE_BLOCK=0
    while [ "$#" -gt 0 ]; do
      case "$1" in
        --invalid)
          # Strict two-token form only: a trailing --invalid with nothing
          # after it (only 1 token left) is a usage error, not a silent noop.
          [ "$#" -ge 2 ] || usage
          NAME="$2"
          # Normalize before the NON-NEGOTIABLE comparison: strip a
          # `dev-crew:` namespace prefix and a `.json` filename suffix so
          # cosmetic name drift cannot bypass the floor.
          NORM="${NAME#dev-crew:}"
          NORM="${NORM%.json}"
          INVALID_COUNT=$((INVALID_COUNT + 1))
          if [ "$NORM" = "security-reviewer" ] || [ "$NORM" = "correctness-reviewer" ]; then
            FORCE_BLOCK=1
          fi
          shift 2
          ;;
        *)
          # Equals form (--invalid=x), unrecognized flags, and any other
          # malformed token are usage errors -- a silent shift here would let
          # a malformed invocation bypass the floor below undetected.
          usage
          ;;
      esac
    done

    # jq availability is checked only after --invalid parsing so the
    # NON-NEGOTIABLE floor can still reach stdout when jq is absent.
    if ! command -v jq >/dev/null 2>&1; then
      if [ "$FORCE_BLOCK" -eq 1 ]; then
        echo "DEGRADED: jq not found (NON-NEGOTIABLE floor still enforced)" >&2
        echo "BLOCK critical:0 important:0 optional:0 invalid:$INVALID_COUNT"
        exit 0
      fi
      echo "DEGRADED: jq not found"
      exit 0
    fi

    if ! jq -e . "$TRIAGE_FILE" >/dev/null 2>&1; then
      echo "INVALID-TRIAGE: triage.json is not valid JSON"
      exit 2
    fi

    triage_type=$(jq -r 'type' "$TRIAGE_FILE")
    if [ "$triage_type" != "array" ]; then
      echo "INVALID-TRIAGE: triage.json is not an array (got $triage_type)"
      exit 2
    fi

    # Type-guard every element before touching .severity/.category, same
    # discipline as validate above: select(type=="object") runs before the
    # field access, so a non-object element (e.g. a bare number) never
    # reaches a field access and cannot crash jq. The type!="string" guards
    # mirror validate: index() on an array argument is a subsequence search,
    # so ["critical"]/["accept-apply"] would pass the enum check but never
    # match the == comparisons in counting -- an accepted critical finding
    # would be dropped from the tally and yield a silent PASS.
    read -r bad_shape bad_items <<EOF
$(jq -r --arg sev "$SEVERITY_ENUM" --arg cat "$CATEGORY_ENUM" '
  ([.[] | select(type != "object")] | length) as $shape
  | ([.[] | select(type == "object") | select(
      ((.severity // "") as $s | ($s | type) != "string" or ($sev | split("|") | index($s)) == null)
      or
      ((.category // "") as $c | ($c | type) != "string" or ($cat | split("|") | index($c)) == null)
    )] | length) as $bad
  | "\($shape) \($bad)"
' "$TRIAGE_FILE")
EOF
    if [ "$bad_shape" -gt 0 ]; then
      echo "INVALID-TRIAGE: $bad_shape item(s) in triage.json are not objects"
      exit 2
    fi
    if [ "$bad_items" -gt 0 ]; then
      echo "INVALID-TRIAGE: $bad_items item(s) have severity or category outside the allowed enum"
      exit 2
    fi

    counts=$(jq -r '
      [ .[] | select(.category=="accept-apply" or .category=="accept-defer") ] as $a
      | "\([$a[] | select(.severity=="critical")] | length) \([$a[] | select(.severity=="important")] | length) \([$a[] | select(.severity=="optional")] | length)"
    ' "$TRIAGE_FILE")
    read -r critical important optional <<EOF
$counts
EOF

    if [ "$critical" -ge 1 ]; then
      VERDICT="BLOCK"
    elif [ "$important" -ge 1 ]; then
      VERDICT="WARN"
    else
      VERDICT="PASS"
    fi

    if [ "$INVALID_COUNT" -gt 0 ]; then
      if [ "$FORCE_BLOCK" -eq 1 ]; then
        VERDICT="BLOCK"
      elif [ "$VERDICT" = "PASS" ]; then
        VERDICT="WARN"
      fi
    fi

    echo "$VERDICT critical:$critical important:$important optional:$optional invalid:$INVALID_COUNT"
    exit 0
    ;;

  *)
    usage
    ;;
esac
