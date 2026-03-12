#!/bin/bash
# validate-yaml-frontmatter.sh - Validate YAML frontmatter in markdown files
# Usage: bash validate-yaml-frontmatter.sh <file.md> [file2.md ...]
# Exit 0 if all valid, 1 if any invalid.
# Requires: yamllint

set -euo pipefail

if ! command -v yamllint >/dev/null 2>&1; then
  echo "ERROR: yamllint not found. Install with: brew install yamllint" >&2
  exit 1
fi

if [ $# -eq 0 ]; then
  echo "Usage: $0 <file.md> [file2.md ...]" >&2
  exit 1
fi

errors=0

for file in "$@"; do
  if [ ! -f "$file" ]; then
    echo "SKIP: $file not found" >&2
    continue
  fi

  # Check file starts with ---
  first_line=$(head -1 "$file")
  if [ "$first_line" != "---" ]; then
    echo "SKIP: $file has no frontmatter" >&2
    continue
  fi

  # Extract frontmatter (between first and second ---)
  yaml=$(awk 'NR==1 && /^---$/{next} /^---$/{exit} {print}' "$file")

  if [ -z "$yaml" ]; then
    echo "FAIL: $file has empty frontmatter" >&2
    errors=$((errors + 1))
    continue
  fi

  # Validate with yamllint (strict mode for quoting)
  result=$(echo "$yaml" | yamllint -d '{extends: default, rules: {line-length: disable, document-start: disable, document-end: disable}}' - 2>&1) || {
    echo "FAIL: $file" >&2
    echo "$result" | sed 's/^/  /' >&2
    errors=$((errors + 1))
  }
done

exit $((errors > 0 ? 1 : 0))
