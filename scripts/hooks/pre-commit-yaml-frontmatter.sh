#!/bin/bash
# pre-commit-yaml-frontmatter.sh - Git pre-commit hook for YAML frontmatter validation
# Validates only staged SKILL.md and agent .md files.
# Install: add to .git/hooks/pre-commit or use with pre-commit framework

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VALIDATOR="$SCRIPT_DIR/../validate-yaml-frontmatter.sh"

if [ ! -f "$VALIDATOR" ]; then
  echo "ERROR: validate-yaml-frontmatter.sh not found at $VALIDATOR" >&2
  exit 1
fi

# Get staged .md files in skills/ and agents/ directories
staged_files=$(git diff --cached --name-only --diff-filter=ACM -- \
  'skills/*/SKILL.md' \
  'agents/*.md' \
  2>/dev/null || true)

if [ -z "$staged_files" ]; then
  exit 0
fi

# Filter out reference files
files_to_check=()
while IFS= read -r file; do
  case "$file" in
    *-reference*) continue ;;
  esac
  [ -f "$file" ] && files_to_check+=("$file")
done <<< "$staged_files"

if [ ${#files_to_check[@]} -eq 0 ]; then
  exit 0
fi

echo "Validating YAML frontmatter..."
if ! bash "$VALIDATOR" "${files_to_check[@]}"; then
  echo ""
  echo "Fix: quote values containing colons with double quotes"
  echo '  description: "value with colon: here"'
  exit 1
fi
