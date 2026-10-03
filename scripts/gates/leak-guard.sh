#!/bin/bash
# leak-guard.sh - 公開 repo（dev-crew）への固有名・実 path の混入を止める（ADR-005）
#
# Usage: leak-guard.sh hook
#   PreToolUse（Bash）の入力 JSON を stdin から読む。止めるときは exit 2、それ以外は exit 0。
#   本体は leak-guard.py。引用符・複合コマンドを shell と同じ規則で分解するため Python で書いている。

input=$(cat)
# hook は Bash の呼び出しごとに動くので、対象になり得ないコマンドは Python を起動せずに通す
if ! printf '%s' "$input" | grep -qE 'commit|push|gh '; then
  exit 0
fi
if ! command -v python3 >/dev/null 2>&1; then
  # 検査できない。対象の操作を含むなら通さない
  if printf '%s' "$input" | grep -qE 'git[^"]*(commit|push)|gh[^"]*(pr|issue)'; then
    echo "BLOCKED (leak-guard, ADR-005): python3 が無く検査できない" >&2
    exit 2
  fi
  exit 0
fi
printf '%s' "$input" | python3 "$(dirname "$0")/leak-guard.py" "$@"
