#!/bin/bash
# recall-candidates.sh - Deterministic recall of related cycle docs for a change set.
#
# Usage: bash scripts/recall-candidates.sh <project_root> <file>... [-n N]
# Output: TSV `score<TAB>docs/cycles/<resolved-path>` for the top N candidates
#         (default 5), score-descending, newer-basename first on ties.
#         Zero candidates -> empty stdout + exit 0.
# Exit:   0 = normal (including 0 candidates); 1 = argument/environment error.
#
# Data sources are existing history only: git co-change (--name-only) plus the
# Cycle-Doc commit trailer (confirmed provenance overrides co-change). No frontmatter
# extension, no SQLite, no embeddings. The working tree is never mutated (read-only).
#
# Invariant (implicit, currently holds with zero collisions): cycle doc basenames are
# unique across docs/cycles/ and docs/cycles/archive/. Aggregation is basename-keyed,
# so a same-basename pair of DISTINCT docs in both dirs would be conflated (the live
# path wins at resolve time). Keep basenames unique when archiving.
#
# Scoring: for the unique set of (input file F, cycle doc) pairs, each pair contributes
# 1 / (distinct docs linked to F) to its doc's score. This IDF-style hub decay keeps a
# hub file (linked to many docs) from collapsing the ranking onto the most-recent cycles.
# A pair repeated across commits contributes once.
#
# git log stream shape (single pass, bash 3.2 / SIGPIPE safe — piped into awk which
# reads to EOF, never `| grep -q`):
#   C<TAB><hash><TAB><Cycle-Doc trailer value or empty>   commit header
#   <changed path>                                        one per --name-only file
# Query files are primed into the same stream as `Q<TAB><path>` lines so no awk -v
# newline escaping is needed.

set -euo pipefail

usage() {
  echo "ERROR: usage: recall-candidates.sh <project_root> <file>... [-n N]" >&2
  exit 1
}

TOP_N=5
ROOT=""
FILES=()

while [ $# -gt 0 ]; do
  case "$1" in
    -n)
      shift
      [ $# -gt 0 ] || usage
      TOP_N="$1"
      ;;
    *)
      if [ -z "$ROOT" ]; then
        ROOT="$1"
      else
        # Strip a leading ./ so query paths match git --name-only output.
        FILES+=("${1#./}")
      fi
      ;;
  esac
  shift
done

[ -n "$ROOT" ] || usage
[ "${#FILES[@]}" -ge 1 ] || usage
[ -d "$ROOT" ] || { echo "ERROR: not a directory: $ROOT" >&2; exit 1; }
case "$TOP_N" in
  ''|*[!0-9]*) echo "ERROR: -n requires a positive integer" >&2; exit 1 ;;
esac
[ "$TOP_N" -ge 1 ] || { echo "ERROR: -n requires a positive integer" >&2; exit 1; }

# Single-pass aggregation: emit `score<TAB>doc-basename` for every candidate doc.
raw=$(
  {
    printf 'Q\t%s\n' "${FILES[@]}"
    git -C "$ROOT" log --format='C%x09%H%x09%(trailers:key=Cycle-Doc,valueonly)' --name-only
  } | awk -F'\t' '
    function basename(p) { sub(/.*\//, "", p); return p }

    function flush(   f, d) {
      if (!have) return
      split("", docs)
      if (trailer != "") {
        docs[basename(trailer)] = 1
      } else {
        for (f in changed)
          if (f ~ /^docs\/cycles\/.*\.md$/) docs[basename(f)] = 1
      }
      for (f in changed)
        if (f in QUERY)
          for (d in docs) pair[f SUBSEP d] = 1
      split("", changed)
      have = 0
      trailer = ""
    }

    BEGIN { have = 0; trailer = "" }

    $1 == "Q" && NF >= 2 { QUERY[$2] = 1; next }
    $1 == "C" && NF >= 3 { flush(); have = 1; trailer = $3; next }
    $0 == "" { next }
    { changed[$0] = 1 }

    END {
      flush()
      for (p in pair) { split(p, a, SUBSEP); fcount[a[1]]++ }
      for (p in pair) { split(p, a, SUBSEP); score[a[2]] += 1.0 / fcount[a[1]] }
      for (d in score) printf "%.6f\t%s\n", score[d], d
    }
  '
)

# Resolve each candidate basename to its current path (docs/cycles/, then archive/).
# Docs absent from both are excluded and reported once on stderr (no silent caps).
excluded=0
resolved=""
while IFS=$'\t' read -r score b; do
  [ -n "${score:-}" ] || continue
  if [ -f "$ROOT/docs/cycles/$b" ]; then
    p="docs/cycles/$b"
  elif [ -f "$ROOT/docs/cycles/archive/$b" ]; then
    p="docs/cycles/archive/$b"
  else
    excluded=$((excluded + 1))
    continue
  fi
  resolved+="${score}"$'\t'"${b}"$'\t'"${p}"$'\n'
done <<< "$raw"

[ "$excluded" -eq 0 ] || echo "excluded $excluded cycle doc(s) absent from current tree" >&2

if [ -n "$resolved" ]; then
  printf '%s' "$resolved" \
    | sort -t "$(printf '\t')" -k1,1nr -k2,2r \
    | awk -F'\t' -v n="$TOP_N" 'NR <= n { print $1 "\t" $3 }'
fi

exit 0
