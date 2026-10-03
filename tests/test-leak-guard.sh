#!/bin/bash
# test-leak-guard.sh - scripts/gates/leak-guard.sh の挙動テスト（ADR-005）
# すべて mktemp の一時 git repo と一時の禁止語リストで行い、実ツリーと実際の禁止語リストには触れない。
# 禁止語は架空の文字列（zzsecretprojzz）だけを使う。

set -uo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GUARD="$BASE_DIR/scripts/gates/leak-guard.sh"
PASS=0
FAIL=0

FIX="$(mktemp -d)"
trap 'rm -rf "$FIX"' EXIT

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

TOKEN="zzsecretprojzz"
# 例示の実 path はこのファイル自体が guard に止められないよう、実行時に組み立てる
MAC_HOME="/Users"
LINUX_HOME="/home"
DENYLIST="$FIX/labels.tsv"
printf '# label\t実プロジェクト\t備考\nA\t%s\tテスト用\n' "$TOKEN" > "$DENYLIST"

REPO="$FIX/repo"
REMOTE="$FIX/remote.git"
OTHER="$FIX/other"

git_q() { git -c user.name=t -c user.email=t@example.com -c commit.gpgsign=false "$@" >/dev/null 2>&1; }

git init -q --bare "$REMOTE"
git init -q -b main "$REPO"
printf 'base line\nold %s line\n' "$TOKEN" > "$REPO/notes.md"
git_q -C "$REPO" add notes.md
git_q -C "$REPO" commit -m "base"
git_q -C "$REPO" remote add origin "$REMOTE"
git_q -C "$REPO" push -u origin main
git init -q -b main "$OTHER"

# hook の入力 JSON を作り、guard を hook モードで実行する。rc と stderr を返す。
run_hook() {
  local cwd="$1" cmd="$2" denylist="${3:-$DENYLIST}"
  local json
  json=$(jq -n --arg c "$cmd" --arg d "$cwd" '{tool_name:"Bash", tool_input:{command:$c}, cwd:$d}')
  HOOK_ERR=$(printf '%s' "$json" | DEV_CREW_LEAK_DENYLIST="$denylist" DEV_CREW_LEAK_GUARD_REPO="$REPO" bash "$GUARD" hook 2>&1 >/dev/null)
  HOOK_RC=$?
}

reset_repo() {
  git -C "$REPO" reset -q --hard origin/main >/dev/null 2>&1
  git -C "$REPO" checkout -q main >/dev/null 2>&1
}

echo "=== leak-guard Tests (ADR-005) ==="

# TC-01: [Given] 禁止語を含む行を stage / [When] git commit / [Then] exit 2 で止め、場所を出す
echo ""
echo "TC-01: staged added line with denylisted token blocks git commit"
printf 'new %s line\n' "$TOKEN" > "$REPO/new.md"
git -C "$REPO" add new.md
run_hook "$REPO" 'git commit -m "add notes"'
if [ "$HOOK_RC" -eq 2 ] && printf '%s' "$HOOK_ERR" | grep -qF 'new.md'; then
  pass "TC-01: blocked with location"
else
  fail "TC-01: expected rc=2 mentioning new.md, got rc=$HOOK_RC: $HOOK_ERR"
fi

# TC-02: [Given] TC-01 の出力 / [Then] 禁止語そのものを出力しない
echo ""
echo "TC-02: output never echoes the denylisted token"
if printf '%s' "$HOOK_ERR" | grep -qiF "$TOKEN"; then
  fail "TC-02: token appeared in output"
else
  pass "TC-02: token not in output"
fi
reset_repo

# TC-03: [Given] 禁止語が既 commit 済みの行にだけある（文脈行） / [When] 同じファイルの別の行を変更して commit / [Then] 止めない
echo ""
echo "TC-03: token only in pre-existing (context) lines does not block"
printf 'base line changed\nold %s line\n' "$TOKEN" > "$REPO/notes.md"
git -C "$REPO" add notes.md
run_hook "$REPO" 'git commit -m "edit base line"'
if [ "$HOOK_RC" -eq 0 ]; then
  pass "TC-03: context-line token ignored"
else
  fail "TC-03: expected rc=0, got rc=$HOOK_RC: $HOOK_ERR"
fi
reset_repo

# TC-04: [Given] commit message（-m）に禁止語 / [Then] 止める
echo ""
echo "TC-04: denylisted token in git commit -m message blocks"
printf 'clean\n' > "$REPO/clean.md"
git -C "$REPO" add clean.md
run_hook "$REPO" "git commit -m \"fix for $TOKEN\""
[ "$HOOK_RC" -eq 2 ] && pass "TC-04: blocked" || fail "TC-04: expected rc=2, got rc=$HOOK_RC"

# TC-05: [Given] commit message ファイル（-F）に禁止語 / [Then] 止める
echo ""
echo "TC-05: denylisted token in git commit -F file blocks"
printf 'fix: something\n\nrelated to %s\n' "$TOKEN" > "$FIX/msg.txt"
run_hook "$REPO" "git commit -F $FIX/msg.txt"
[ "$HOOK_RC" -eq 2 ] && pass "TC-05: blocked" || fail "TC-05: expected rc=2, got rc=$HOOK_RC"
reset_repo

# TC-06: [Given] gh pr create の --body に禁止語 / [Then] 止める
echo ""
echo "TC-06: denylisted token in gh pr create --body blocks"
run_hook "$REPO" "gh pr create --title t --body \"see $TOKEN\""
[ "$HOOK_RC" -eq 2 ] && pass "TC-06: blocked" || fail "TC-06: expected rc=2, got rc=$HOOK_RC"

# TC-07: [Given] gh issue comment の --body-file に禁止語 / [Then] 止める
echo ""
echo "TC-07: denylisted token in gh issue comment --body-file blocks"
printf 'note about %s\n' "$TOKEN" > "$FIX/body.md"
run_hook "$REPO" "gh issue comment 1 --body-file $FIX/body.md"
[ "$HOOK_RC" -eq 2 ] && pass "TC-07: blocked" || fail "TC-07: expected rc=2, got rc=$HOOK_RC"

# TC-08: [Given] ホーム直下の実 path を追加 / [Then] 止める。.claude 配下（plan_file）は許可
echo ""
echo "TC-08: home project path blocks, ~/.claude path is allowed"
printf 'see %s/alice/Projects/private-app/README.md\n' "$MAC_HOME" > "$REPO/path.md"
git -C "$REPO" add path.md
run_hook "$REPO" 'git commit -m "add path"'
rc_block=$HOOK_RC
reset_repo
printf 'plan_file: %s/alice/.claude/plans/sample.md\n' "$MAC_HOME" > "$REPO/plan.md"
git -C "$REPO" add plan.md
run_hook "$REPO" 'git commit -m "add plan"'
rc_allow=$HOOK_RC
reset_repo
if [ "$rc_block" -eq 2 ] && [ "$rc_allow" -eq 0 ]; then
  pass "TC-08: project path blocked, .claude path allowed"
else
  fail "TC-08: expected block=2 allow=0, got block=$rc_block allow=$rc_allow"
fi

# TC-09: [Given] branch の commit が禁止語を追加 / [When] git push / [Then] 止める
echo ""
echo "TC-09: git push blocks when branch commits add a denylisted token"
git -C "$REPO" checkout -q -b feature
printf 'pushed %s\n' "$TOKEN" > "$REPO/push.md"
git_q -C "$REPO" add push.md
git_q -C "$REPO" commit -m "clean message"
run_hook "$REPO" 'git push -u origin feature'
[ "$HOOK_RC" -eq 2 ] && pass "TC-09: blocked" || fail "TC-09: expected rc=2, got rc=$HOOK_RC"
reset_repo
git -C "$REPO" branch -q -D feature >/dev/null 2>&1

# TC-10: [Given] branch の commit message に禁止語（内容は無害） / [When] git push / [Then] 止める
echo ""
echo "TC-10: git push blocks when a branch commit message has a denylisted token"
git -C "$REPO" checkout -q -b feature2
printf 'harmless\n' > "$REPO/harmless.md"
git_q -C "$REPO" add harmless.md
git_q -C "$REPO" commit -m "work for $TOKEN"
run_hook "$REPO" 'git push -u origin feature2'
[ "$HOOK_RC" -eq 2 ] && pass "TC-10: blocked" || fail "TC-10: expected rc=2, got rc=$HOOK_RC"
reset_repo
git -C "$REPO" branch -q -D feature2 >/dev/null 2>&1

# TC-11: [Given] 保護対象ではない repo へ cd して commit / [Then] 止めない（非公開 repo では固有名を書くのが正しい）
echo ""
echo "TC-11: commits in a non-protected repo are not checked"
printf 'private %s\n' "$TOKEN" > "$OTHER/p.md"
git -C "$OTHER" add p.md
run_hook "$REPO" "cd $OTHER && git commit -m \"$TOKEN\""
[ "$HOOK_RC" -eq 0 ] && pass "TC-11: not checked" || fail "TC-11: expected rc=0, got rc=$HOOK_RC: $HOOK_ERR"

# TC-12: [Given] 対象外のコマンド / [Then] 止めない
echo ""
echo "TC-12: unrelated commands pass"
run_hook "$REPO" "echo $TOKEN"
[ "$HOOK_RC" -eq 0 ] && pass "TC-12: passed" || fail "TC-12: expected rc=0, got rc=$HOOK_RC"

# TC-13: [Given] 禁止語リストが無い / [Then] 禁止語は検査しないが、実 path は止める
echo ""
echo "TC-13: without a denylist, only the generic path check runs"
printf 'only %s\n' "$TOKEN" > "$REPO/t.md"
git -C "$REPO" add t.md
run_hook "$REPO" 'git commit -m "x"' "$FIX/missing.tsv"
rc_token=$HOOK_RC
reset_repo
printf '%s/bob/Projects/app\n' "$LINUX_HOME" > "$REPO/h.md"
git -C "$REPO" add h.md
run_hook "$REPO" 'git commit -m "x"' "$FIX/missing.tsv"
rc_path=$HOOK_RC
reset_repo
if [ "$rc_token" -eq 0 ] && [ "$rc_path" -eq 2 ]; then
  pass "TC-13: token skipped, path still blocked"
else
  fail "TC-13: expected token=0 path=2, got token=$rc_token path=$rc_path"
fi

# TC-15: [Given] 未追跡ファイルに禁止語 / [When] 同じコマンド内で git add してから commit / [Then] 止める
# hook は add の実行前に動くので、add 予定のファイルも検査対象に含める必要がある
echo ""
echo "TC-15: git add <untracked> && git commit in one command blocks"
printf 'fresh %s\n' "$TOKEN" > "$REPO/fresh.md"
run_hook "$REPO" 'git add fresh.md && git commit -m "add fresh"'
rc_named=$HOOK_RC
run_hook "$REPO" 'git add -A && git commit -m "add all"'
rc_all=$HOOK_RC
# 未追跡でも add されないファイルは検査しない（手元の作業ファイルで毎回止まらないように）
printf 'clean\n' > "$REPO/other.md"
run_hook "$REPO" 'git add other.md && git commit -m "add other"'
rc_unrelated=$HOOK_RC
git -C "$REPO" clean -qf >/dev/null 2>&1
if [ "$rc_named" -eq 2 ] && [ "$rc_all" -eq 2 ] && [ "$rc_unrelated" -eq 0 ]; then
  pass "TC-15: files added in the same command are checked; untouched untracked files are not"
else
  fail "TC-15: expected named=2 all=2 unrelated=0, got named=$rc_named all=$rc_all unrelated=$rc_unrelated"
fi

# TC-16: [Given] 引用符・スペース・global option を含む呼び方 / [Then] いずれも検査する
echo ""
echo "TC-16: quoted paths, spaces and global options are still checked"
SPACED="$FIX/repo link"
ln -s "$REPO" "$SPACED"
printf 'quoted %s\n' "$TOKEN" > "$REPO/q.md"
git -C "$REPO" add q.md
tc16=""
run_hook "$FIX" "git -C \"$SPACED\" commit -m x"; [ "$HOOK_RC" -eq 2 ] || tc16="$tc16 -C-quoted($HOOK_RC)"
run_hook "$REPO" "git -c commit.gpgsign=false commit -m x"; [ "$HOOK_RC" -eq 2 ] || tc16="$tc16 -c($HOOK_RC)"
run_hook "$FIX" "cd \"$REPO\" && git commit -m x"; [ "$HOOK_RC" -eq 2 ] || tc16="$tc16 cd-quoted($HOOK_RC)"
reset_repo
printf 'body %s\n' "$TOKEN" > "$FIX/pr body.md"
run_hook "$REPO" "gh pr create --title t --body-file \"$FIX/pr body.md\""; [ "$HOOK_RC" -eq 2 ] || tc16="$tc16 body-file-spaced($HOOK_RC)"
run_hook "$REPO" "gh -R owner/dev-crew issue create --title t --body \"$TOKEN\""; [ "$HOOK_RC" -eq 2 ] || tc16="$tc16 gh-R-dev-crew($HOOK_RC)"
run_hook "$REPO" "gh issue create -R owner/private-app --title t --body \"$TOKEN\""; [ "$HOOK_RC" -eq 0 ] || tc16="$tc16 gh-R-other($HOOK_RC)"
[ -z "$tc16" ] && pass "TC-16: all variants handled" || fail "TC-16: missed:$tc16"

# TC-17: [Given] ディレクトリ指定・サブディレクトリからの add / [Then] add 予定の未追跡ファイルを検査する
echo ""
echo "TC-17: git add of a directory or from a subdirectory checks the untracked files"
mkdir -p "$REPO/docs/sub"
printf 'dir %s\n' "$TOKEN" > "$REPO/docs/sub/d.md"
tc17=""
run_hook "$REPO" 'git add docs/ && git commit -m x'; [ "$HOOK_RC" -eq 2 ] || tc17="$tc17 dir($HOOK_RC)"
run_hook "$REPO/docs/sub" 'git add d.md && git commit -m x'; [ "$HOOK_RC" -eq 2 ] || tc17="$tc17 subdir($HOOK_RC)"
git -C "$REPO" clean -qfd >/dev/null 2>&1
[ -z "$tc17" ] && pass "TC-17: checked" || fail "TC-17: missed:$tc17"

# TC-18: [Given] 別ブランチを push / 追加した後の commit で消した禁止語 / [Then] 送る ref の各 commit を検査する
echo ""
echo "TC-18: push checks the pushed ref and every unpublished commit"
tc18=""
git -C "$REPO" checkout -q -b side
printf 'side %s\n' "$TOKEN" > "$REPO/side.md"
git_q -C "$REPO" add side.md
git_q -C "$REPO" commit -m "side"
git -C "$REPO" checkout -q main
run_hook "$REPO" 'git push origin side'; [ "$HOOK_RC" -eq 2 ] || tc18="$tc18 other-ref($HOOK_RC)"
git -C "$REPO" branch -q -D side >/dev/null 2>&1
git -C "$REPO" checkout -q -b addrm
printf 'tmp %s\n' "$TOKEN" > "$REPO/tmp.md"
git_q -C "$REPO" add tmp.md
git_q -C "$REPO" commit -m "add"
git_q -C "$REPO" rm -q tmp.md
git_q -C "$REPO" commit -m "remove"
run_hook "$REPO" 'git push -u origin addrm'; [ "$HOOK_RC" -eq 2 ] || tc18="$tc18 add-then-remove($HOOK_RC)"
reset_repo
git -C "$REPO" branch -q -D addrm >/dev/null 2>&1
[ -z "$tc18" ] && pass "TC-18: checked" || fail "TC-18: missed:$tc18"

# TC-19: [Given] commit の後に PR 作成を続ける複合コマンド / [Then] PR 本文も検査する
echo ""
echo "TC-19: compound command checks every operation"
printf 'pr %s\n' "$TOKEN" > "$FIX/pr.md"
run_hook "$REPO" "git commit --allow-empty -m clean && gh pr create --title t --body-file $FIX/pr.md"
[ "$HOOK_RC" -eq 2 ] && pass "TC-19: blocked" || fail "TC-19: expected rc=2, got rc=$HOOK_RC"

# TC-20: [Given] ファイル名にも禁止語 / [Then] 出力（stdout・stderr）に禁止語を出さない
echo ""
echo "TC-20: file names containing the token are not echoed"
printf 'x %s\n' "$TOKEN" > "$REPO/${TOKEN}-notes.md"
git -C "$REPO" add "${TOKEN}-notes.md"
json=$(jq -n --arg c 'git commit -m x' --arg d "$REPO" '{tool_name:"Bash", tool_input:{command:$c}, cwd:$d}')
all_out=$(printf '%s' "$json" | DEV_CREW_LEAK_DENYLIST="$DENYLIST" DEV_CREW_LEAK_GUARD_REPO="$REPO" bash "$GUARD" hook 2>&1)
rc=$?
reset_repo
if [ "$rc" -eq 2 ] && ! printf '%s' "$all_out" | grep -qiF "$TOKEN"; then
  pass "TC-20: blocked without echoing the token"
else
  fail "TC-20: rc=$rc, token echoed or not blocked"
fi

# TC-21: [Given] 内容が '++ ' で始まる追加行（diff では '+++ ' になる） / [Then] 追加行として検査する
echo ""
echo "TC-21: added lines starting with '++ ' are still inspected"
printf '++ %s\n' "$TOKEN" > "$REPO/pp.md"
git -C "$REPO" add pp.md
run_hook "$REPO" 'git commit -m x'
reset_repo
[ "$HOOK_RC" -eq 2 ] && pass "TC-21: blocked" || fail "TC-21: expected rc=2, got rc=$HOOK_RC"

# TC-22: [Given] 改行で終わらない禁止語リスト / [Then] 最終行の禁止語も使う
echo ""
echo "TC-22: last denylist line without trailing newline is used"
printf 'A\t%s\tnote' "$TOKEN" > "$FIX/nonl.tsv"
run_hook "$REPO" "gh pr comment 1 --body \"$TOKEN\"" "$FIX/nonl.tsv"
[ "$HOOK_RC" -eq 2 ] && pass "TC-22: blocked" || fail "TC-22: expected rc=2, got rc=$HOOK_RC"

# TC-23: [Given] 対象操作を含むが解析できないコマンド（閉じていない引用符） / [Then] 止める（検査できないものは通さない）
echo ""
echo "TC-23: unparsable command with a target operation fails closed"
run_hook "$REPO" 'git commit -m "unterminated'
[ "$HOOK_RC" -eq 2 ] && pass "TC-23: blocked" || fail "TC-23: expected rc=2, got rc=$HOOK_RC"

# TC-24: [Given] リダイレクト（2>&1、> file、< file）を含む push / commit / gh / [Then] 引数と誤認せず通常どおり判定する
echo ""
echo "TC-24: redirections are not mistaken for arguments"
tc24=""
git -C "$REPO" checkout -q -b redir
printf 'clean\n' > "$REPO/r.md"
git_q -C "$REPO" add r.md
git_q -C "$REPO" commit -m "clean"
run_hook "$REPO" "git push -q -u origin redir 2>&1 | grep -v '^remote:'"; [ "$HOOK_RC" -eq 0 ] || tc24="$tc24 push-clean($HOOK_RC)"
run_hook "$REPO" "git commit --allow-empty -q -m clean > $FIX/out.log 2>&1"; [ "$HOOK_RC" -eq 0 ] || tc24="$tc24 commit-clean($HOOK_RC)"
run_hook "$REPO" "gh pr create --title t --body \"$TOKEN\" 2>/dev/null"; [ "$HOOK_RC" -eq 2 ] || tc24="$tc24 gh-token($HOOK_RC)"
reset_repo
git -C "$REPO" branch -q -D redir >/dev/null 2>&1
[ -z "$tc24" ] && pass "TC-24: redirections handled" || fail "TC-24: wrong:$tc24"

# TC-14: [Given] dev-crew repo の .claude/settings.json / [Then] PreToolUse(Bash) に leak-guard の hook が登録されている
echo ""
echo "TC-14: .claude/settings.json registers leak-guard as a PreToolUse Bash hook"
SETTINGS="$BASE_DIR/.claude/settings.json"
if [ ! -f "$SETTINGS" ]; then
  fail "TC-14: .claude/settings.json not found"
elif jq -e '.hooks.PreToolUse[] | select(.matcher=="Bash") | .hooks[] | select(.command | test("scripts/gates/leak-guard.sh hook"))' "$SETTINGS" >/dev/null 2>&1; then
  pass "TC-14: registered"
else
  fail "TC-14: leak-guard hook not registered for Bash"
fi

echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
