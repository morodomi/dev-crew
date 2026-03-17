#!/bin/bash
# risk-classifier.sh - Deterministic risk classification (no LLM)
# Usage: risk-classifier.sh <files_list> <diff_content>
# Output: "LOW|MEDIUM|HIGH score:NN"
#
# Risk signals and points:
#   auth/security file changes  +25
#   SQL/DB operations           +25
#   crypto/token/secret         +30
#   API contract changes        +15
#   file count > 5              +15
#   line count > 200            +20
#   UI component changes        +10
#   test file changes            +10
#   schema/migration changes     +20
#   external communication       +15
#   wide change (dir spread>=3)  +15
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

score=0

# --- File-path based signals ---

if [ -f "$FILES_LIST" ]; then
  # auth/security file changes (+25)
  if grep -qiE 'auth|security|login|password|session|permission|middleware.*auth|guard' "$FILES_LIST" 2>/dev/null; then
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
  file_count=$(grep -vcE '\.(scm|fixture|snap|mock|seed)$|fixtures/|__snapshots__/' "$FILES_LIST" 2>/dev/null || echo "0")
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
  dir_count=$(grep '/' "$FILES_LIST" 2>/dev/null | awk -F/ '{print $1}' | sort -u | wc -l | tr -d ' ')
  if [ "$dir_count" -ge 3 ]; then
    score=$((score + 15))
  fi
fi

# --- Diff content based signals ---

if [ -f "$DIFF_CONTENT" ]; then
  # SQL/DB operations (+25)
  if grep -qiE 'SELECT|INSERT|UPDATE|DELETE|DROP|CREATE TABLE|DB::|database|migration|\.query\(|\.execute\(' "$DIFF_CONTENT" 2>/dev/null; then
    score=$((score + 25))
  fi

  # crypto/token/secret patterns (+30)
  if grep -qiE 'password|secret|token|hash|encrypt|decrypt|cipher|private.key|api.key|credential' "$DIFF_CONTENT" 2>/dev/null; then
    score=$((score + 30))
  fi

  # External communication patterns (+15)
  if grep -qiE 'fetch\(|axios\.|requests\.|http\.client|HttpClient|new URL\(|curl_|guzzle|urllib|httpx' "$DIFF_CONTENT" 2>/dev/null; then
    score=$((score + 15))
  fi

  # Line count > 200 (+20)
  diff_lines=$(wc -l < "$DIFF_CONTENT" | tr -d ' ')
  if [ "$diff_lines" -gt 200 ]; then
    score=$((score + 20))
  fi
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
