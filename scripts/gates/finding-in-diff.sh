#!/bin/bash
# finding-in-diff.sh - レビュー指摘の場所（ファイル:行）が今回の diff の中にあるかを終了コードで判定する
#
# Purpose:
#   REVIEW で修正役を起動する前に、PdM が指摘ごとに実行する。diff の外（元からある欠陥）の指摘を
#   修正役に「直す」として渡さないための照合を、PdM の読みではなく終了コードにする。
#   疑わしいときは「元からある欠陥」と断定せず 2 に倒す（PdM は今までどおり修正役に任せる）。
#
# Usage: finding-in-diff.sh <ファイル> <行>
#   ファイルはリポジトリのルートからの相対パスとして読む（./ は外す。絶対パスはルートの下ならルートからの
#   相対に直す）。どのディレクトリから実行しても同じ結果になる。行は作業ツリーの今の行番号（正の整数）。
# Exit:
#   0 = diff の中: ファイルが未追跡、または git diff HEAD の変更行に行が入る
#       追加・変更の hunk +c,d（d>0）は c..c+d-1。削除だけの hunk +c,0 は削除箇所の前後（c と c+1）
#   1 = diff の外: 追跡ファイルだと確かめられ、行が変更行に入らない（diff に無い追跡ファイルを含む）
#   2 = 判定できない: 引数の誤り、git repo の外、HEAD が無い、パスがリポジトリの外、追跡も未追跡もされていない、
#       clean filter が掛かっている、git がバイナリ扱いにして hunk が取れない、git の失敗。stderr に理由を 1 行出す
#
# 方針:
#   - git diff は --no-ext-diff --no-textconv --no-color -U0 --inter-hunk-context=0 で呼ぶ。利用者の git 設定で
#     hunk の範囲が変わると、離れた 2 つの変更の間の未変更行まで「diff の中」になってしまうため
#   - clean filter は --no-textconv では外れず、diff の行番号を作業ツリーの行番号からずらす。掛かっているパスは判定しない
#   - 作業ツリーと index は変えない（読むだけ）

# 利用者の環境変数で pathspec の解釈や hunk の文脈行数が変わると、変更行の判定がずれる
unset GIT_LITERAL_PATHSPECS GIT_GLOB_PATHSPECS GIT_NOGLOB_PATHSPECS GIT_ICASE_PATHSPECS \
  GIT_DIFF_OPTS GIT_EXTERNAL_DIFF

die() {
  echo "finding-in-diff: $1" >&2
  exit 2
}

[ "$#" -eq 2 ] || die "usage: finding-in-diff.sh <file> <line>"
path_in="$1"
line="$2"
case "$line" in
  '' | *[!0-9]* | 0*) die "line must be a positive integer: $line" ;;
esac

root=$(git rev-parse --show-toplevel 2>/dev/null) || die "not inside a git repository"
[ -n "$root" ] || die "not inside a git repository"
cd "$root" || die "cannot enter repository root"

git rev-parse --verify -q HEAD >/dev/null 2>&1 || die "HEAD does not exist (no commits yet)"

# 絶対パスはルートの下ならルートからの相対に直す
case "$path_in" in
  /*)
    case "$path_in" in
      "$root"/*) path_in="${path_in#"$root"/}" ;;
      *) die "path is outside the repository: $1" ;;
    esac
    ;;
esac

# . と .. を畳む。ルートより上に出るなら判定しない
norm=""
old_ifs="$IFS"
IFS='/'
set -f
for comp in $path_in; do
  case "$comp" in
    '' | '.') ;;
    '..')
      case "$norm" in
        '') IFS="$old_ifs"; set +f; die "path is outside the repository: $1" ;;
        */*) norm="${norm%/*}" ;;
        *) norm="" ;;
      esac
      ;;
    *)
      if [ -z "$norm" ]; then norm="$comp"; else norm="$norm/$comp"; fi
      ;;
  esac
done
set +f
IFS="$old_ifs"
[ -n "$norm" ] || die "empty path: $1"
spec=":(literal)$norm"

untracked=$(git ls-files --others --exclude-standard -- "$spec" 2>/dev/null) || die "git ls-files failed"
if printf '%s\n' "$untracked" | grep -Fxq -- "$norm"; then
  exit 0
fi

cached=$(git ls-files --cached -- "$spec" 2>/dev/null) || die "git ls-files failed"
if ! printf '%s\n' "$cached" | grep -Fxq -- "$norm"; then
  git cat-file -e "HEAD:$norm" 2>/dev/null || die "path is neither tracked nor untracked: $norm"
fi

attr=$(git check-attr filter -- "$norm" 2>/dev/null) || die "git check-attr failed"
attr_val="${attr##*: }"
case "$attr_val" in
  unspecified | unset) ;;
  *) die "clean filter applies to $norm; cannot judge" ;;
esac

diff_out=$(git diff HEAD --no-color --no-ext-diff --no-textconv -U0 --inter-hunk-context=0 -- "$spec" 2>/dev/null)
rc=$?
[ "$rc" -eq 0 ] || die "git diff failed"

# バイナリ扱い（巨大ファイル等）では hunk が出ない。hunk が無いことを未変更と取り違えない
if printf '%s\n' "$diff_out" | grep -q '^Binary files '; then
  die "git treats $norm as binary; cannot judge"
fi

printf '%s\n' "$diff_out" | awk -v n="$line" '
  /^@@ / {
    s = $3
    sub(/^\+/, "", s)
    c = s; d = 1
    i = index(s, ",")
    if (i > 0) { c = substr(s, 1, i - 1); d = substr(s, i + 1) }
    c += 0; d += 0
    if (d > 0) { if (n >= c && n <= c + d - 1) found = 1 }
    else { if (n == c || n == c + 1) found = 1 }
  }
  END { exit(found ? 0 : 1) }
'
exit $?
