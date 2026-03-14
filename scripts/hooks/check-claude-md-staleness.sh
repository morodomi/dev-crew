#!/bin/bash
# CLAUDE.md / AGENTS.md staleness warning (non-blocking)
# Exit 0 always - warning only, never blocks commit

set -euo pipefail

THRESHOLD_DAYS="${STALENESS_THRESHOLD_DAYS:-30}"
CLAUDE_MD="CLAUDE.md"
AGENTS_MD="AGENTS.md"

# Skip if env var set
[ "${SKIP_STALENESS_CHECK:-0}" = "1" ] && exit 0

check_staleness() {
  local file="$1"
  [ -f "$file" ] || return 0

  local last_modified
  last_modified=$(git log -1 --format="%ct" -- "$file" 2>/dev/null || echo "0")
  [ "$last_modified" = "0" ] && return 0

  local now age days_old
  now=$(date +%s)
  age=$((now - last_modified))

  if [ "$age" -gt "$((THRESHOLD_DAYS * 86400))" ]; then
    days_old=$((age / 86400))
    echo "[WARNING] $file は ${days_old} 日間更新されていません (閾値: ${THRESHOLD_DAYS}日)"
    echo "  -> $file の内容が現状と乖離している可能性があります"
    echo "  -> 確認して更新してください"
  fi
}

# Check both files (check_staleness handles missing files gracefully)
check_staleness "$CLAUDE_MD"
check_staleness "$AGENTS_MD"

exit 0
