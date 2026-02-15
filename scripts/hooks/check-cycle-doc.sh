#!/bin/bash
set -e

# Get staged files
STAGED_FILES=$(git diff --cached --name-only 2>/dev/null || echo "")

# Check if any skills/ or agents/ files are staged
HAS_SKILL_CHANGES=false
HAS_AGENT_CHANGES=false
HAS_ONLY_DOCS=true

for file in $STAGED_FILES; do
  case "$file" in
    skills/*) HAS_SKILL_CHANGES=true; HAS_ONLY_DOCS=false ;;
    agents/*) HAS_AGENT_CHANGES=true; HAS_ONLY_DOCS=false ;;
    docs/*) ;; # docs changes are fine
    *) HAS_ONLY_DOCS=false ;;
  esac
done

# If only docs/ changes, skip check
if [ "$HAS_ONLY_DOCS" = true ]; then
  exit 0
fi

# If no skills/ or agents/ changes, skip check
if [ "$HAS_SKILL_CHANGES" = false ] && [ "$HAS_AGENT_CHANGES" = false ]; then
  exit 0
fi

# Check for skip flag (environment variable)
if [ "${SKIP_CYCLE_CHECK:-0}" = "1" ]; then
  exit 0
fi

# Check for cycle doc existence
if ls docs/cycles/*.md 1>/dev/null 2>&1; then
  exit 0
fi

# No cycle doc found
echo "[pre-commit hook] Cycle doc check failed."
echo "Skills or agents changes detected, but no cycle doc found in docs/cycles/."
echo "Please run 'Skill(dev-crew:init)' or create a cycle doc manually before committing."
exit 1
