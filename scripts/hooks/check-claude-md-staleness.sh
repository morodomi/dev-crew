#!/bin/bash
# CLAUDE.md staleness warning (non-blocking)
# Exit 0 always - warning only, never blocks commit

set -euo pipefail

THRESHOLD_DAYS="${STALENESS_THRESHOLD_DAYS:-30}"
CLAUDE_MD="CLAUDE.md"

# Skip if env var set
[ "${SKIP_STALENESS_CHECK:-0}" = "1" ] && exit 0

# Skip if no CLAUDE.md
[ -f "$CLAUDE_MD" ] || exit 0

# Get last commit timestamp of CLAUDE.md
last_modified=$(git log -1 --format="%ct" -- "$CLAUDE_MD" 2>/dev/null || echo "0")
[ "$last_modified" = "0" ] && exit 0

now=$(date +%s)
threshold=$((THRESHOLD_DAYS * 86400))
age=$((now - last_modified))

if [ "$age" -gt "$threshold" ]; then
  days_old=$((age / 86400))
  echo "[WARNING] CLAUDE.md は ${days_old} 日間更新されていません (閾値: ${THRESHOLD_DAYS}日)"
  echo "  -> CLAUDE.md の内容が現状と乖離している可能性があります"
  echo "  -> 確認して更新してください"
fi

exit 0
