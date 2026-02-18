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
#
# Thresholds:
#   0-29:  LOW
#   30-59: MEDIUM
#   60+:   HIGH

set -euo pipefail

FILES_LIST="${1:-}"
DIFF_CONTENT="${2:-}"

if [ -z "$FILES_LIST" ] || [ -z "$DIFF_CONTENT" ]; then
  echo "Usage: risk-classifier.sh <files_list_file> <diff_content_file>"
  exit 1
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

  # File count > 5 (+15)
  file_count=$(wc -l < "$FILES_LIST" | tr -d ' ')
  if [ "$file_count" -gt 5 ]; then
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
