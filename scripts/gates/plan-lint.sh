#!/bin/bash
# plan-lint.sh - check the acceptance criteria of a plan file before approval
#
# Purpose: every acceptance criterion (AC) in the plan's "## 受け入れ条件" section
#   must say how it is verified, in one of four kinds:
#     テスト <TC-ID, ...>        the IDs must exist in the plan's Test List
#     コマンド `<command>`       a command in backticks (not run in plan mode)
#     人が確認（<what to see>）  the parentheses must not be blank
#     未定（問い: <question>）   allowed to write, but BLOCKs and prints the
#                                question so the plan author asks a human
#   A criterion whose verification is undecided must go back to a human before
#   approval, not be filled in by an assumption.
#
# Scope of reading: the file is cut at the first line that is exactly
#   "## Plan Review Record" BEFORE code fences are considered, even when that
#   line sits inside a fence. plan-hash.sh cuts the hash the same way; if the
#   lint cut at a different place, the text that is hashed and the text that is
#   linted would differ and a plan could pass with content nobody reviewed.
#   Only text outside code fences (``` and ~~~, closed by the same character) is
#   read after the cut.
#
# Usage: bash plan-lint.sh <plan file>
# Exit codes:
#   0 - PASS (a "PASS:" line on stdout)
#   1 - BLOCK ("BLOCK:" lines on stdout)

set -euo pipefail

plan="${1:-}"

if [ -z "$plan" ] || [ ! -f "$plan" ]; then
  echo "BLOCK: plan file not given or not found: ${plan:-<none>}"
  exit 1
fi

# Records, tab separated: SEC (section seen), AC id count first-line-text,
# DUP id, TC id. Kept in awk because it is the only line-by-line state machine;
# the multibyte kind parsing is done in bash with prefix/suffix removal.
parsed=$(awk '
  $0 == "## Plan Review Record" { exit }
  # A tab would be read back as a field separator below.
  { gsub(/\t/, " ") }
  # Fences follow CommonMark: a closing fence is the same character, at least as
  # long as the opening one, with nothing else on the line; a backtick fence
  # cannot open on a line that has another backtick (inline code).
  fence == "" {
    s = $0
    sub(/^ */, "", s)
    if (match(s, /^`+/) && RLENGTH >= 3 && substr(s, RLENGTH + 1) !~ /`/) {
      fence = "`"; flen = RLENGTH; next
    }
    if (match(s, /^~+/) && RLENGTH >= 3) { fence = "~"; flen = RLENGTH; next }
  }
  fence != "" {
    s = $0
    sub(/^ */, "", s)
    sub(/[ \t]+$/, "", s)
    if (fence == "`" && s ~ /^`+$/ && length(s) >= flen) fence = ""
    else if (fence == "~" && s ~ /^~+$/ && length(s) >= flen) fence = ""
    next
  }
  /^## / {
    sec = ""
    cur = 0
    if ($0 == "## 受け入れ条件") { sec = "ac"; seen = 1 }
    else if ($0 ~ /^## Test List($| |（|\()/) sec = "tl"
    next
  }
  sec == "ac" && /^- AC-[^:]+:/ {
    id = $0
    sub(/^- /, "", id)
    sub(/:.*/, "", id)
    if (++count[id] == 2) dups[++nd] = id
    n++
    acid[n] = id
    accnt[n] = 0
    actxt[n] = ""
    cur = n
    next
  }
  sec == "ac" && cur > 0 && /^  +- 確かめ方: / {
    t = $0
    sub(/^  +- 確かめ方: /, "", t)
    if (accnt[cur] == 0) actxt[cur] = t
    accnt[cur]++
    next
  }
  sec == "ac" && /^[ ]*([-*+][ ]*)?AC-/ {
    bad[++nbad] = $0
    next
  }
  # The ID is the leading TC-... token (letters, digits, _, and - or . between
  # them), the same token the AC side extracts, so both sides compare equal.
  sec == "tl" && /^- \[[ xX]\] TC-[^:]+:/ {
    t = $0
    sub(/^- \[[ xX]\] /, "", t)
    if (match(t, /^TC-[0-9A-Za-z_]+([-.][0-9A-Za-z_]+)*/)) tcs[++nt] = substr(t, 1, RLENGTH)
    next
  }
  END {
    print "SEC\t" seen + 0
    for (i = 1; i <= nbad; i++) print "BAD\t" bad[i]
    for (i = 1; i <= nd; i++) print "DUP\t" dups[i]
    for (i = 1; i <= n; i++) print "AC\t" acid[i] "\t" accnt[i] "\t" actxt[i]
    for (i = 1; i <= nt; i++) print "TC\t" tcs[i]
  }
' "$plan")

sec_seen=0
ac_n=0
bad_n=0
dup_n=0
# Written as bytes so the strip works the same in the C locale and in UTF-8:
# [[:space:]] does not match U+3000 / U+00A0 in the C locale.
ideo_sp=$'\xe3\x80\x80'
nbsp=$'\xc2\xa0'
tc_list=""
while IFS=$'\t' read -r tag f1 f2 f3; do
  case "$tag" in
    SEC) sec_seen="$f1" ;;
    BAD) bad_n=$((bad_n + 1)); bad_line[$bad_n]="$f1" ;;
    DUP) dup_n=$((dup_n + 1)); dup_id[$dup_n]="$f1" ;;
    AC)  ac_n=$((ac_n + 1)); ac_id[$ac_n]="$f1"; ac_cnt[$ac_n]="$f2"; ac_txt[$ac_n]="$f3" ;;
    TC)  tc_list="${tc_list}${f1}"$'\n' ;;
  esac
done <<< "$parsed"

if [ "$sec_seen" != "1" ]; then
  echo "BLOCK: no '## 受け入れ条件' section"
  exit 1
fi

if [ "$bad_n" -gt 0 ]; then
  i=1
  while [ "$i" -le "$bad_n" ]; do
    echo "BLOCK: not an acceptance criterion line in the format '- AC-N: ...': ${bad_line[$i]}"
    i=$((i + 1))
  done
  exit 1
fi

if [ "$ac_n" -eq 0 ]; then
  echo "BLOCK: '## 受け入れ条件' has no '- AC-N:' line"
  exit 1
fi

if [ "$dup_n" -gt 0 ]; then
  i=1
  while [ "$i" -le "$dup_n" ]; do
    echo "BLOCK: duplicate AC-ID: ${dup_id[$i]}"
    i=$((i + 1))
  done
  exit 1
fi

bad=0
i=1
while [ "$i" -le "$ac_n" ]; do
  if [ "${ac_cnt[$i]}" != "1" ]; then
    echo "BLOCK: ${ac_id[$i]}: needs exactly one 確かめ方 line (found ${ac_cnt[$i]})"
    bad=1
  fi
  i=$((i + 1))
done
[ "$bad" -eq 0 ] || exit 1

undecided=""
i=1
while [ "$i" -le "$ac_n" ]; do
  id="${ac_id[$i]}"
  t="${ac_txt[$i]}"
  t="${t#"${t%%[![:space:]]*}"}"
  t="${t%"${t##*[![:space:]]}"}"
  case "$t" in
    テスト|テスト\ *)
      rest="${t#テスト}"
      tcs=$(grep -oE 'TC-[0-9A-Za-z_]+([-.][0-9A-Za-z_]+)*' <<< "$rest" || true)
      if [[ "$rest" == *〜* || "$rest" == *～* || "$rest" == *~* ]]; then
        echo "BLOCK: ${id}: テスト lists TC-IDs one by one, not as a range"
        bad=1
      elif [ -z "$tcs" ]; then
        echo "BLOCK: ${id}: テスト needs at least one TC-ID"
        bad=1
      else
        while IFS= read -r tc; do
          if [[ $'\n'"$tc_list" != *$'\n'"$tc"$'\n'* ]]; then
            echo "BLOCK: ${id}: ${tc} is not in the Test List"
            bad=1
          fi
        done <<< "$tcs"
      fi
      ;;
    コマンド|コマンド\ *)
      rest="${t#コマンド}"
      cmd=""
      if [[ "$rest" == *\`*\`* ]]; then
        after="${rest#*\`}"
        cmd="${after%%\`*}"
      fi
      cmd="${cmd//"$ideo_sp"/}"
      cmd="${cmd//"$nbsp"/}"
      if [ -z "${cmd//[[:space:]]/}" ]; then
        echo "BLOCK: ${id}: コマンド needs a non-empty command in backticks"
        bad=1
      fi
      ;;
    人が確認|人が確認（*）)
      inner=""
      if [ "$t" != "人が確認" ]; then
        inner="${t#人が確認（}"
        inner="${inner%）}"
      fi
      inner="${inner//"$ideo_sp"/}"
      inner="${inner//"$nbsp"/}"
      if [ -z "${inner//[[:space:]]/}" ]; then
        echo "BLOCK: ${id}: 人が確認 needs a non-empty description"
        bad=1
      fi
      ;;
    未定（*）)
      q="${t#未定（}"
      q="${q%）}"
      q="${q#問い:}"
      q="${q#"${q%%[![:space:]]*}"}"
      undecided="${undecided}BLOCK: ${id}: 未定の問い: ${q}"$'\n'
      ;;
    *)
      echo "BLOCK: ${id}: unknown 確かめ方 kind: ${t}"
      bad=1
      ;;
  esac
  i=$((i + 1))
done
[ "$bad" -eq 0 ] || exit 1

if [ -n "$undecided" ]; then
  printf '%s' "$undecided"
  exit 1
fi

echo "PASS: ${ac_n} acceptance criteria, each with one 確かめ方 of a known kind."
exit 0
