#!/bin/bash
# worktree-fingerprint.sh - 作業ツリーの状態を 1 つの SHA-256 にまとめる
#
# Purpose:
#   REVIEW で adversarial-reviewer（Bash 可）を起動する前後に実行し、出力を比べる。
#   disallowedTools は Bash 経由の書き込みを防げないので、作業ツリーが変わっていないことを
#   この値の一致で確かめる。
#   git diff / git status には頼らない。clean filter・textconv・assume-unchanged・skip-worktree・
#   既変更ファイルの再書き換えで diff が変わらない書き換えを見逃すため、ファイルの実体を直接読む。
#
# Usage: worktree-fingerprint.sh [--list]
#   既定: stdout に 64 桁の 16 進を 1 行で出力する
#   --list: 診断用。ハッシュの代わりにレコードを 1 行ずつ（種別 TAB 名前 TAB 内容）出力する。
#           前後で出力して diff を取れば、BLOCK したときに何が変わったかが分かる
# Exit 0 = 成功 / 非 0 = stdout は空（git repo の外、git の失敗、読めないファイル等）。--list は途中まで出すことがある
#
# 含めるもの（レコードに直列化して NUL 区切りでハッシュする。名前に改行・タブがあっても衝突しない）:
#   - HEAD、HEAD が指すブランチ名、git for-each-ref、git stash list
#   - index（git ls-files -s -z の mode / blob / stage / path）と、git ls-files -v -z の assume-unchanged / skip-worktree 等の印
#   - 追跡ファイルと未追跡ファイル（--others --exclude-standard）の実体
#       通常ファイル: 実行権限の有無と内容の SHA-256 / symlink: リンク文字列（参照先は辿らない）
#       FIFO・ソケット・デバイス: 種別名だけ（中身を読むと止まるため）/ 無い: missing
#       ディレクトリ（入れ子 repo）: 名前と、そこに .git があれば rev-parse HEAD と status --porcelain のハッシュ
#   - .git の config・info/exclude・info/attributes の内容と、hooks 配下のファイルの内容
#   HEAD が無い（commit 0 件）repo でも動く。
#
# 検出しないもの:
#   - .gitignore（--exclude-standard）の対象になっているファイルの変更。node_modules などが大きく毎回ハッシュするのは重いため
#   - リポジトリの外の変更（~/.gitconfig、core.excludesFile、他のディレクトリ、ネットワーク越しの送信）
#   - 入れ子 repo の中で、すでに変更済みのファイルをさらに書き換えた場合（status の行が変わらない）
#   - .git の objects・index のタイムスタンプなど、上に挙げていない内部ファイル
#
# git は core.fsmonitor=false・core.hooksPath=/dev/null で呼ぶ（リポジトリ側の設定で外部コマンドが走らないように）。
# 入れ子 repo の status は --no-optional-locks で、この script 自身が index を書き換えないようにする。

set -euo pipefail

LIST=0
case "${1:-}" in
  "") ;;
  --list) LIST=1 ;;
  *)
    echo "usage: worktree-fingerprint.sh [--list]" >&2
    exit 2
    ;;
esac
if [ "$#" -gt 1 ]; then
  echo "usage: worktree-fingerprint.sh [--list]" >&2
  exit 2
fi

# sha256sum（Linux・新しい macOS）が速い。無ければ shasum（旧 macOS。1 ファイルあたり遅い）
if command -v sha256sum >/dev/null 2>&1; then
  SHA=(sha256sum)
elif command -v shasum >/dev/null 2>&1; then
  SHA=(shasum -a 256)
else
  echo "worktree-fingerprint: sha256sum / shasum not found" >&2
  exit 1
fi

g() { git -c core.fsmonitor=false -c core.hooksPath=/dev/null "$@"; }

top=$(git rev-parse --show-toplevel)
cd "$top"
gitdir=$(g rev-parse --absolute-git-dir)
commondir=$(cd "$(g rev-parse --git-common-dir)" && pwd)

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
records="$work/records"
: > "$records"

# emit KIND PATH DETAIL: NUL 区切りの 3 フィールドを 1 レコードとして足す
emit() { printf '%s\0%s\0%s\0' "$1" "$2" "$3" >> "$records"; }

# hash_stdin: 標準入力の SHA-256（64 桁）だけを出す
hash_stdin() {
  local out
  out=$("${SHA[@]}") || return 1
  printf '%s\n' "${out%% *}"
}

# describe_path PATH: 作業ツリー上の実体を PH_KIND / PH_DETAIL に入れる。読めなければ return 1
describe_path() {
  local p="$1" t h s x
  PH_KIND=""
  PH_DETAIL=""
  if [ -L "$p" ]; then
    # 参照先は辿らない。x は末尾の改行を $(...) に落とされないための印
    t=$(readlink -- "$p" && printf x) || return 1
    PH_KIND=link
    PH_DETAIL=${t%x}
  elif [ -f "$p" ]; then
    h=$("${SHA[@]}" < "$p") || return 1
    if [ -x "$p" ]; then x=x; else x=-; fi
    PH_KIND=file
    PH_DETAIL="$x ${h%% *}"
  elif [ -d "$p" ]; then
    PH_KIND=dir
    if [ -e "$p/.git" ] && h=$(g -C "$p" rev-parse HEAD 2>/dev/null); then
      s=$(g -C "$p" --no-optional-locks status --porcelain 2>/dev/null | hash_stdin) || return 1
      PH_DETAIL="$h $s"
    fi
  elif [ -p "$p" ]; then
    PH_KIND=special
    PH_DETAIL=fifo
  elif [ -S "$p" ]; then
    PH_KIND=special
    PH_DETAIL=socket
  elif [ -b "$p" ] || [ -c "$p" ]; then
    PH_KIND=special
    PH_DETAIL=device
  elif [ -e "$p" ]; then
    PH_KIND=special
    PH_DETAIL=other
  else
    PH_KIND=missing
  fi
}

# HEAD・ブランチ・参照・stash
if head=$(g rev-parse --verify -q HEAD); then
  :
else
  head="no-HEAD"
fi
emit head "" "$head"
if branch=$(g symbolic-ref -q HEAD); then
  emit headref "" "$branch"
fi
g for-each-ref --format='%(objectname) %(refname)' > "$work/refs"
while IFS= read -r line; do
  emit ref "" "$line"
done < "$work/refs"
g stash list --format='%H %gs' > "$work/stash"
while IFS= read -r line; do
  emit stash "" "$line"
done < "$work/stash"

# index: mode / blob / stage / path。タブは meta と path の区切りで、meta にタブは無いので最初のタブで切る
g ls-files -s -z > "$work/index"
while IFS= read -r -d '' rec; do
  meta=${rec%%$'\t'*}
  path=${rec#*$'\t'}
  emit index "$path" "$meta"
  describe_path "$path" || exit 1
  emit tree "$path" "$PH_KIND $PH_DETAIL"
done < "$work/index"

# assume-unchanged（小文字）・skip-worktree（S）など。通常の H 以外の印は diff に出ない書き換えの足場になる
g ls-files -v -z > "$work/tags"
while IFS= read -r -d '' rec; do
  tag=${rec:0:1}
  [ "$tag" = "H" ] && continue
  emit tag "${rec:2}" "$tag"
done < "$work/tags"

# 未追跡ファイル（.gitignore 対象は含めない）
g ls-files --others --exclude-standard -z > "$work/untracked"
while IFS= read -r -d '' path; do
  describe_path "$path" || exit 1
  emit untracked "$path" "$PH_KIND $PH_DETAIL"
done < "$work/untracked"

# .git の設定。config の filter / alias / core.* と info の exclude / attributes は、diff や ls-files の見え方を変える
for rel in config info/exclude info/attributes; do
  f="$commondir/$rel"
  if [ -f "$f" ]; then
    h=$("${SHA[@]}" < "$f") || exit 1
    emit gitfile "$rel" "${h%% *}"
  else
    emit gitfile "$rel" absent
  fi
done

# hooks 配下のファイル・symlink。sort -z は GNU / BSD どちらにもある
if [ -d "$commondir/hooks" ]; then
  find "$commondir/hooks" \( -type f -o -type l \) -print0 | sort -z > "$work/hooks"
  while IFS= read -r -d '' f; do
    rel=${f#"$commondir"/}
    describe_path "$f" || exit 1
    emit hook "$rel" "$PH_KIND $PH_DETAIL"
  done < "$work/hooks"
fi

# 診断用の表示。名前の改行・タブは \n \t に直し、他の制御文字は ? にする
esc() {
  local s="$1"
  s=${s//$'\n'/\\n}
  s=${s//$'\t'/\\t}
  printf '%s' "$s" | LC_ALL=C tr '\001-\037\177' '?'
}

if [ "$LIST" -eq 1 ]; then
  while IFS= read -r -d '' kind && IFS= read -r -d '' path && IFS= read -r -d '' detail; do
    printf '%s\t%s\t%s\n' "$(esc "$kind")" "$(esc "$path")" "$(esc "$detail")"
  done < "$records"
else
  hash_stdin < "$records"
fi
