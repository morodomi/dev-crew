#!/bin/bash
# risk-classifier.sh - Deterministic risk classification (no LLM)
# Usage: risk-classifier.sh <files_list> <diff_content>
# Output: "LOW|MEDIUM|HIGH score:NN"
#
# Risk signals and points:
#   auth/security file changes  +25
#   SQL/DB operations           +25  (code-scoped, see below)
#   crypto/token/secret         +30  (full-scoped, see below)
#   API contract changes        +15
#   file count > 5              +15
#   line count > 200            +20  (code-scoped, see below)
#   UI component changes        +10
#   test file changes            +10
#   schema/migration changes     +20
#   external communication       +15  (code-scoped, see below)
#   wide change (dir spread>=3)  +15
#
# Signal scoping:
#   code-scoped signals (SQL/external/line-volume): computed on code hunks
#     only, via code_only_diff(), excluding doc-ext files (.md/.markdown/
#     .txt/.rst/.mdx). These signals measure code-behavior risk (SQL
#     injection surface, outbound calls, code volume); prose matches are
#     pure noise and would otherwise false-positive on words like
#     "updated:" or "deleted" in Markdown.
#   full-scoped signals (crypto/secret, all file-path signals): computed
#     on the full diff / file list, including doc-ext files. Secret
#     exposure is a risk in any file type (including Markdown), so
#     narrowing to code hunks would create a blind spot. File-path
#     signals measure the breadth of a change independent of hunk content.
# Scope of the score: this number only tunes how many *supplementary*,
# risk-gated reviewers are added (performance/resiliency/etc). The
# security-reviewer and correctness-reviewer are NON-NEGOTIABLE in code mode
# and run regardless of score, so code-scoping a signal can never bypass the
# security review gate — worst case it under-triggers a supplementary reviewer.
#
# Thresholds:
#   0-29:  LOW
#   30-59: MEDIUM
#   60+:   HIGH

set -euo pipefail

FILES_LIST="${1:-}"
DIFF_CONTENT="${2:-}"

if [ -z "$FILES_LIST" ] || [ -z "$DIFF_CONTENT" ]; then
  FILES_LIST=$(mktemp)
  DIFF_CONTENT=$(mktemp)
  trap 'rm -f "$FILES_LIST" "$DIFF_CONTENT"' EXIT
  git diff HEAD --name-only > "$FILES_LIST"
  git diff HEAD > "$DIFF_CONTENT"
fi

# code_only_diff <diff_file>
# Streams only the hunk lines belonging to non-doc files (doc-ext:
# .md/.markdown/.txt/.rst/.mdx excluded). Tracks the current file via
# `+++ b/<path>` headers; for deleted files (`+++ /dev/null`) the path is
# taken from the preceding `--- a/<path>` line so deleted code is not
# under-scored. diff --git / index / mode metadata lines are dropped
# (never hunk body). Hunks with no recognized +++ header (headerless
# fixtures, malformed diffs) are fail-open: scanned rather than excluded,
# so real code risk is never silently dropped.
code_only_diff() {
  awk '
    /^diff --git/ { indoc=0; inhunk=0; hasheader=1; next }
    /^--- /       { a=$0; sub(/^--- /, "", a); inhunk=0; next }
    /^\+\+\+ /     { b=$0; sub(/^\+\+\+ /, "", b); p=(b=="/dev/null"?a:b); sub(/^[ab]\//, "", p);
                    indoc=(p ~ /\.(md|markdown|txt|rst|mdx)$/)?1:0; inhunk=0; next }
    /^@@/         { inhunk=1; next }
    { if (hasheader && !inhunk) next; if (indoc) next; print }
  ' "$1"
}

score=0

# --- File-path based signals ---

if [ -f "$FILES_LIST" ]; then
  # auth/security file changes (+25)
  # Path-segment-prefix match: keyword が path segment 先頭に現れる場合のみ match
  # (skill-authoring.md 等の FP を除去しつつ SecurityPolicy.ts / LoginController.php 等の
  # compound TP を維持。Codex code review cycle 20260424_1356 対応)
  if grep -qiE '(^|/)(auth|security|login|password|session|permission|guard)' "$FILES_LIST" 2>/dev/null \
     || grep -qiE 'middleware.*auth' "$FILES_LIST" 2>/dev/null; then
    score=$((score + 25))
  fi

  # API contract changes (+15)
  if grep -qiE 'route|api|controller|endpoint|swagger|openapi' "$FILES_LIST" 2>/dev/null; then
    score=$((score + 15))
  fi

  # UI component changes (+10)
  if grep -qiE 'component|view|page|template|layout|\.vue|\.tsx|\.jsx|\.blade\.php|\.dart' "$FILES_LIST" 2>/dev/null; then
    score=$((score + 10))
  fi

  # Test file changes (+10)
  if grep -qiE 'test|spec|__tests__' "$FILES_LIST" 2>/dev/null; then
    score=$((score + 10))
  fi

  # File count > 5 (+15) - excluding low-risk file types
  file_count=$(grep -vcE '\.(scm|fixture|snap|mock|seed)$|fixtures/|__snapshots__/' "$FILES_LIST" 2>/dev/null) || file_count=0
  if [ "$file_count" -gt 5 ]; then
    score=$((score + 15))
  fi

  # Skip file_count bonus for new-file-only changes
  if [ "$file_count" -gt 5 ] && [ -f "$DIFF_CONTENT" ]; then
    has_modified=$(grep -c '^--- a/' "$DIFF_CONTENT" 2>/dev/null) || has_modified=0
    if [ "$has_modified" -eq 0 ]; then
      score=$((score - 15))
    fi
  fi

  # Schema/migration file changes (+20)
  if grep -qiE 'migration|schema|\.migrate\.|model.*field|alter.table' "$FILES_LIST" 2>/dev/null; then
    score=$((score + 20))
  fi

  # Wide change - directory spread >= 3 (+15)
  dir_count=$(grep '/' "$FILES_LIST" 2>/dev/null | awk -F/ '{print $1}' | sort -u | wc -l | tr -d ' ') || dir_count=0
  if [ "$dir_count" -ge 3 ]; then
    score=$((score + 15))
  fi
fi

# --- Diff content based signals ---

if [ -f "$DIFF_CONTENT" ]; then
  # Materialize the code-only view once, then grep the file (not a pipe).
  # A pipe `code_only_diff | grep -q` is unsafe under `set -o pipefail`: grep -q
  # exits on first match, awk then gets SIGPIPE (exit 141), and pipefail makes the
  # pipeline report 141 even though grep matched — the `if` reads that as "no match"
  # and silently under-scores real code. Materializing to a temp avoids SIGPIPE
  # entirely and reuses the single awk pass for all three code-scoped signals.
  CODE_DIFF=$(mktemp)
  code_only_diff "$DIFF_CONTENT" > "$CODE_DIFF"

  # SQL/DB operations (+25) - code-scoped: doc-ext hunks excluded
  if grep -qiE 'SELECT|INSERT|UPDATE|DELETE|DROP|CREATE TABLE|DB::|database|migration|\.query\(|\.execute\(' "$CODE_DIFF" 2>/dev/null; then
    score=$((score + 25))
  fi

  # crypto/token/secret patterns (+30) - full-scoped: secret exposure risk
  # applies to any file type, including Markdown
  if grep -qiE 'password|secret|token|hash|encrypt|decrypt|cipher|private.key|api.key|credential' "$DIFF_CONTENT" 2>/dev/null; then
    score=$((score + 30))
  fi

  # External communication patterns (+15) - code-scoped: doc-ext hunks excluded
  if grep -qiE 'fetch\(|axios\.|requests\.|http\.client|HttpClient|new URL\(|curl_|guzzle|urllib|httpx' "$CODE_DIFF" 2>/dev/null; then
    score=$((score + 15))
  fi

  # Line count > 200 (+20) - code-scoped: doc-ext hunks excluded
  diff_lines=$(wc -l < "$CODE_DIFF" | tr -d ' ')
  if [ "$diff_lines" -gt 200 ]; then
    score=$((score + 20))
  fi

  rm -f "$CODE_DIFF"
fi

# --- Classification ---

if [ "$score" -ge 60 ]; then
  level="HIGH"
elif [ "$score" -ge 30 ]; then
  level="MEDIUM"
else
  level="LOW"
fi

echo "$level score:$score"
