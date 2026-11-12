#!/bin/bash
# codify-landing.sh - codified で Destination が rule の insight のうち、rules に着地していないものを数える
#
# Usage: bash codify-landing.sh <repo_root> [--count]
#
# 入力:
#   docs/cycles/*.md のコードブロック外の `## Codify Decisions` 節（複数あれば全部）。
#   `### Insight N` ごとに Decision が codified、Destination が rule で始まるものが対象。
# 着地の根拠:
#   rules/*.md と .claude/rules/*.md の各行で、cycle id (YYYYMMDD_HHMM) の後ろに続く番号
#   (#N / Insight N / Insights 1, 2, N)。1 行に cycle id が複数あれば直前の cycle id に結び付ける。
#   docs/codify-withdrawn.md の `- <cycle_id> #N — <理由>`（理由が空でない行）も着地扱い。
# 出力: 未着地の `<cycle_id> #N` を 1 行ずつ。--count は件数だけ。rc 0。引数の誤りは usage + exit 2。
#
# 判定は git に依存しない。rules が無い repo でも動く。

set -euo pipefail

# ロケールや GREP_OPTIONS に判定が左右されないようにする
export LC_ALL=C
unset GREP_OPTIONS || true

usage() {
  echo "Usage: bash codify-landing.sh <repo_root> [--count]" >&2
}

root=""
count=false
for arg in "$@"; do
  case "$arg" in
    --count) count=true ;;
    -*) usage; exit 2 ;;
    *)
      if [ -n "$root" ]; then usage; exit 2; fi
      root="$arg"
      ;;
  esac
done
if [ -z "$root" ] || [ ! -d "$root" ]; then
  usage
  exit 2
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
targets="$tmp/targets"
landed="$tmp/landed"
: > "$targets"
: > "$landed"

# 1. 対象: codified かつ Destination が rule の insight（出力は "<cycle_id> N"）
for f in "$root"/docs/cycles/*.md; do
  [ -f "$f" ] || continue
  base=$(basename "$f")
  id=${base%%_*}
  rest=${base#*_}
  id="${id}_${rest:0:4}"
  case "$id" in
    [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]_[0-9][0-9][0-9][0-9]) ;;
    *) continue ;;
  esac
  awk -v id="$id" '
    # fence は開いた文字（` か ~）と同じ文字で、開いた長さ以上の並びだけで閉じる。
    # 4 連の fence の中の ``` や、``` の中の ~~~ で判定が反転しないため
    /^(```|~~~)/ {
      ch = substr($0, 1, 1)
      t = $0; sub("[^" ch "].*$", "", t); len = length(t)
      if (!fence) { fence = 1; fch = ch; flen = len }
      else if (ch == fch && len >= flen && substr($0, len + 1) ~ /^[ \t\r]*$/) fence = 0
      next
    }
    fence { next }
    /^## / { sec = (index($0, "## Codify Decisions") == 1); n = ""; next }
    !sec { next }
    /^### Insight [0-9]+/ {
      s = $0; sub(/^### Insight /, "", s); sub(/[^0-9].*$/, "", s)
      n = s; dec[n] = ""; dst[n] = ""; next
    }
    # Insight でない ### 見出し（成功事例など）の Decision が直前の insight を上書きしないよう、番号を切る
    /^### / { n = ""; next }
    n != "" && /^- \*\*Decision\*\*:/ { v = $0; sub(/^- \*\*Decision\*\*:[ ]*/, "", v); dec[n] = v }
    n != "" && /^- \*\*Destination\*\*:/ { v = $0; sub(/^- \*\*Destination\*\*:[ ]*/, "", v); dst[n] = v }
    END { for (k in dec) if (dec[k] ~ /^codified/ && dst[k] ~ /^rule/) print id " " k }
  ' "$f" >> "$targets"
done

# 2. 着地: rules の出典（cycle id の後ろの番号を直前の cycle id に結び付ける）
for f in "$root"/rules/*.md "$root"/.claude/rules/*.md; do
  [ -f "$f" ] || continue
  awk '
    function digits(s,   i, m, a) {
      m = split(s, a, /[^0-9]+/)
      for (i = 1; i <= m; i++) if (a[i] != "") print id " " a[i]
    }
    function scan_tail(t,   r, seg) {
      # #N は最初の 1 つと、そこに `, #M` / `、#M` で続くものだけ。同じ行の後ろの "PR #2" を着地にしない
      r = t
      if (match(r, /#[0-9]+/)) {
        print id " " substr(r, RSTART + 1, RLENGTH - 1)
        r = substr(r, RSTART + RLENGTH)
        while (match(r, /^(,|\343\200\201)[ ]?#[0-9]+/)) {
          seg = substr(r, RSTART, RLENGTH)
          sub(/^[^#]*#/, "", seg)
          print id " " seg
          r = substr(r, RSTART + RLENGTH)
        }
      }
      # Insight N / Insights 1, 2, N
      r = t
      while (match(r, /Insights? [0-9]+(, ?[0-9]+)*/)) {
        seg = substr(r, RSTART, RLENGTH)
        sub(/^Insights? /, "", seg)
        digits(seg)
        r = substr(r, RSTART + RLENGTH)
      }
    }
    {
      line = $0
      pat = "[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]_[0-9][0-9][0-9][0-9]"
      id = ""
      while (match(line, pat)) {
        if (id != "") scan_tail(substr(line, 1, RSTART - 1))
        id = substr(line, RSTART, RLENGTH)
        line = substr(line, RSTART + RLENGTH)
      }
      if (id != "") scan_tail(line)
    }
  ' "$f" >> "$landed"
done

# 取り下げ台帳: `- <cycle_id> #N — <理由>`（理由が空でない行）
ledger="$root/docs/codify-withdrawn.md"
if [ -f "$ledger" ]; then
  awk '
    /^-[ ]+[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]_[0-9][0-9][0-9][0-9][ ]+#[0-9]+[ ]+—[ ]*[^ ]/ {
      s = $0; sub(/^-[ ]+/, "", s)
      id = substr(s, 1, 13)
      s = substr(s, 14); sub(/^[ ]+#/, "", s); sub(/[^0-9].*$/, "", s)
      print id " " s
    }
  ' "$ledger" >> "$landed"
fi

# 3. 未着地 = 対象 - 着地
result=$(awk '
  FILENAME == ARGV[1] { l[$0] = 1; next }
  !($0 in l) { split($0, p, " "); print p[1] " #" p[2] }
' "$landed" "$targets" | sort -u)

if [ "$count" = "true" ]; then
  if [ -z "$result" ]; then
    echo 0
  else
    printf '%s\n' "$result" | wc -l | tr -d ' '
  fi
else
  [ -z "$result" ] || printf '%s\n' "$result"
fi
exit 0
