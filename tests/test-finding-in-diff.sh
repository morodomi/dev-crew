#!/bin/bash
# test-finding-in-diff.sh - scripts/gates/finding-in-diff.sh の判定契約テスト（TC-01〜TC-20）
#
# 一時ディレクトリに git repo を作り、`bash scripts/gates/finding-in-diff.sh <ファイル> <行>` を実際に実行して
# 終了コードを見る。0 = 指摘の場所が今回の diff の中 / 1 = diff の外（追跡ファイルだと確かめられ、変更行に入らない）
# / 2 = 判定できない。fixture は 1 つのテストの中で前後を作る。
# 利用者の ~/.gitconfig に左右されないよう GIT_CONFIG_GLOBAL=/dev/null と GIT_CONFIG_NOSYSTEM=1 を使う。
# スクリプトが無い間は bash が rc=127 を返すので、期待する rc（0/1/2）に一致せず全 TC が FAIL する。

set -uo pipefail

BASE_DIR="${BASE_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

SCRIPT="$BASE_DIR/scripts/gates/finding-in-diff.sh"
FP="$BASE_DIR/scripts/gates/worktree-fingerprint.sh"

export GIT_CONFIG_GLOBAL=/dev/null
export GIT_CONFIG_NOSYSTEM=1

TMPROOT=$(cd "$(mktemp -d)" && pwd -P)
trap 'rm -rf "$TMPROOT"' EXIT
export GIT_CEILING_DIRECTORIES="$TMPROOT"

N=0
ERRF="$TMPROOT/stderr.txt"

# newdir: 空の一時ディレクトリを作って絶対パスを出す
newdir() {
  # $(newdir) はサブシェルで走るため、カウンタではなく mktemp で毎回別のディレクトリにする
  mktemp -d "$TMPROOT/d.XXXXXX"
}

# g DIR ARGS...: DIR の repo で git を呼ぶ（user は -c で与える）
g() {
  local d="$1"
  shift
  git -C "$d" -c user.name=tester -c user.email=tester@example.com -c commit.gpgsign=false "$@"
}

# gen N: line1..lineN を出力
gen() { seq 1 "$1" | sed 's/^/line/'; }

# setline FILE N TEXT: FILE の N 行目を TEXT に書き換える（テスト fixture 用の新規書き出し）
setline() {
  awk -v n="$2" -v t="$3" 'NR==n{print t; next}{print}' "$1" > "$1.new" && mv "$1.new" "$1"
}

# mkbase DIR: f.txt（12 行）と other.txt（3 行）を HEAD に commit した repo
mkbase() {
  local d="$1"
  git -C "$d" init -q -b main
  gen 12 > "$d/f.txt"
  gen 3 > "$d/other.txt"
  g "$d" add -A
  g "$d" commit -q -m base
}

# run DIR ARGS...: DIR で finding-in-diff.sh を実行。RC に rc、ERR に stderr
RC=0
ERR=""
run() {
  local d="$1"
  shift
  (cd "$d" && bash "$SCRIPT" "$@" 2> "$ERRF" > /dev/null)
  RC=$?
  ERR=$(cat "$ERRF" 2>/dev/null || true)
}

# expect LABEL EXPECTED: 直前の run の RC を検査
expect() {
  if [ "$RC" -eq "$2" ]; then
    pass "$1: rc=$RC"
  else
    fail "$1: expected rc=$2, got rc=$RC (stderr: $ERR)"
  fi
}

# expect_err LABEL: rc=2 のとき stderr に理由があること（スクリプトが無い時の bash のエラーで通さない）
expect_err() {
  if [ "$RC" -eq 2 ] && [ -n "$ERR" ]; then
    pass "$1: stderr has a reason"
  else
    fail "$1: need rc=2 and non-empty stderr (rc=$RC)"
  fi
}

echo "=== finding-in-diff.sh Tests ==="

if [ ! -f "$SCRIPT" ]; then
  echo "  (note) $SCRIPT does not exist yet: every TC fails by rc=127"
fi

# TC-01
echo ""
echo "TC-01: untracked file -> any line is inside the diff (rc=0)"
d=$(newdir); mkbase "$d"
gen 8 > "$d/new.txt"
run "$d" new.txt 1; expect "TC-01 line 1" 0
run "$d" new.txt 8; expect "TC-01 line 8" 0

# TC-02
echo ""
echo "TC-02: changed line is inside (rc=0), unchanged line is outside (rc=1)"
d=$(newdir); mkbase "$d"
setline "$d/f.txt" 5 "CHANGED"
run "$d" f.txt 5; expect "TC-02 line 5" 0
run "$d" f.txt 3; expect "TC-02 line 3" 1
run "$d" f.txt 6; expect "TC-02 line 6 (next to the changed line)" 1

# TC-03
echo ""
echo "TC-03: tracked file not in the diff -> rc=1"
d=$(newdir); mkbase "$d"
setline "$d/other.txt" 2 "CHANGED"
run "$d" f.txt 5; expect "TC-03 f.txt:5" 1

# TC-04
echo ""
echo "TC-04: multi-line hunk boundaries (3 lines added after line 10)"
d=$(newdir); mkbase "$d"
{ gen 10; printf 'ADD1\nADD2\nADD3\n'; printf 'line11\nline12\n'; } > "$d/f.txt"
run "$d" f.txt 11; expect "TC-04 line 11" 0
run "$d" f.txt 13; expect "TC-04 line 13" 0
run "$d" f.txt 10; expect "TC-04 line 10" 1
run "$d" f.txt 14; expect "TC-04 line 14" 1

# TC-05
echo ""
echo "TC-05: deletion-only hunk (lines 6-7 removed): the lines around the deletion are inside"
d=$(newdir); mkbase "$d"
{ gen 5; printf 'line8\nline9\nline10\nline11\nline12\n'; } > "$d/f.txt"
run "$d" f.txt 5; expect "TC-05 line 5" 0
run "$d" f.txt 6; expect "TC-05 line 6" 0
run "$d" f.txt 3; expect "TC-05 line 3" 1
run "$d" f.txt 8; expect "TC-05 line 8" 1

# TC-06
echo ""
echo "TC-06: staged change with no worktree difference is inside (rc=0)"
d=$(newdir); mkbase "$d"
setline "$d/f.txt" 5 "CHANGED"
g "$d" add f.txt
run "$d" f.txt 5; expect "TC-06 staged line 5" 0
run "$d" f.txt 3; expect "TC-06 staged line 3" 1

# TC-07
echo ""
echo "TC-07: path forms (./file, absolute path, run from a subdirectory) give the TC-02 answers"
d=$(newdir); mkbase "$d"
setline "$d/f.txt" 5 "CHANGED"
mkdir -p "$d/sub"
run "$d" ./f.txt 5; expect "TC-07 ./f.txt:5" 0
run "$d" ./f.txt 3; expect "TC-07 ./f.txt:3" 1
run "$d" "$d/f.txt" 5; expect "TC-07 absolute:5" 0
run "$d" "$d/f.txt" 3; expect "TC-07 absolute:3" 1
run "$d/sub" f.txt 5; expect "TC-07 from sub f.txt:5" 0
run "$d/sub" f.txt 3; expect "TC-07 from sub f.txt:3" 1

# TC-08
echo ""
echo "TC-08: diff.external (failing) and a textconv driver that changes line counts do not change the answer"
d=$(newdir); mkbase "$d"
printf 'f.txt diff=drv\n' > "$d/.gitattributes"
g "$d" add .gitattributes
g "$d" commit -q -m attrs
git -C "$d" config diff.external false
git -C "$d" config diff.drv.textconv 'sed 1,3d'
setline "$d/f.txt" 5 "CHANGED"
run "$d" f.txt 5; expect "TC-08 line 5" 0
run "$d" f.txt 3; expect "TC-08 line 3" 1

# TC-09
echo ""
echo "TC-09: argument errors -> rc=2 with a reason on stderr"
d=$(newdir); mkbase "$d"
setline "$d/f.txt" 5 "CHANGED"
run "$d" f.txt; expect "TC-09 one arg" 2
expect_err "TC-09 one arg"
run "$d" f.txt 5 extra; expect "TC-09 three args" 2
expect_err "TC-09 three args"
for bad in abc 0 -1; do
  run "$d" f.txt "$bad"; expect "TC-09 line=$bad" 2
  expect_err "TC-09 line=$bad"
done

# TC-10
echo ""
echo "TC-10: outside a git repo -> rc=2"
d=$(newdir)
printf 'x\n' > "$d/f.txt"
run "$d" f.txt 1; expect "TC-10" 2

# TC-11
echo ""
echo "TC-11: path pointing outside the repository -> rc=2"
d=$(newdir); mkbase "$d"
printf 'x\n' > "$TMPROOT/outside.txt"
run "$d" ../outside.txt 1; expect "TC-11" 2

# TC-12
echo ""
echo "TC-12: repo with no commits -> rc=2"
d=$(newdir)
git -C "$d" init -q -b main
gen 5 > "$d/f.txt"
run "$d" f.txt 1; expect "TC-12" 2

# TC-13
echo ""
echo "TC-13: measured failures M1 (baseline defect, tests only added) and M3 (untracked api.py)"
d=$(newdir)
git -C "$d" init -q -b main
cat > "$d/pager.py" <<'PY'
# pager helpers

def page_count(total_items, per_page):
    """Number of pages needed."""
    return total_items // per_page + 1
PY
cat > "$d/footer.py" <<'PY'
from pager import page_count


def footer(total_items, per_page):
    return "pages: %d" % page_count(total_items, per_page)
PY
g "$d" add -A
g "$d" commit -q -m initial
mkdir -p "$d/tests"
cat > "$d/tests/test_pager.py" <<'PY'
from pager import page_count


def test_page_count_exact():
    assert page_count(10, 5) == 2
PY
run "$d" pager.py 5; expect "TC-13 M1 pager.py:5" 1
d=$(newdir)
git -C "$d" init -q -b main
printf 'x = 1\n' > "$d/base.py"
g "$d" add -A
g "$d" commit -q -m initial
cat > "$d/api.py" <<'PY'
import json


def handle(request):
    body = json.loads(request)
    return body["id"]
PY
run "$d" api.py 6; expect "TC-13 M3 api.py:6" 0

# TC-14
echo ""
echo "TC-14: the script only reads (worktree fingerprint is identical before and after)"
d=$(newdir); mkbase "$d"
setline "$d/f.txt" 5 "CHANGED"
before=$(cd "$d" && bash "$FP" 2>/dev/null); before_rc=$?
run "$d" f.txt 5
script_rc=$RC
after=$(cd "$d" && bash "$FP" 2>/dev/null); after_rc=$?
detail=""
[ "$script_rc" -eq 0 ] || detail="$detail [script rc=$script_rc]"
[ "$before_rc" -eq 0 ] || detail="$detail [fingerprint before rc=$before_rc]"
[ "$after_rc" -eq 0 ] || detail="$detail [fingerprint after rc=$after_rc]"
printf '%s' "$before" | grep -Eq '^[0-9a-f]{64}$' || detail="$detail [before not 64 hex: $before]"
printf '%s' "$after" | grep -Eq '^[0-9a-f]{64}$' || detail="$detail [after not 64 hex: $after]"
[ "$before" = "$after" ] || detail="$detail [fingerprints differ]"
if [ -z "$detail" ]; then
  pass "TC-14: read-only"
else
  fail "TC-14:$detail"
fi

# TC-15
echo ""
echo "TC-15: two distant changes with diff.interHunkContext=100 stay separate"
d=$(newdir); mkbase "$d"
git -C "$d" config diff.interHunkContext 100
setline "$d/f.txt" 3 "CHANGED3"
setline "$d/f.txt" 9 "CHANGED9"
run "$d" f.txt 6; expect "TC-15 line 6 (unchanged between)" 1
run "$d" f.txt 3; expect "TC-15 line 3" 0
run "$d" f.txt 9; expect "TC-15 line 9" 0

# TC-16
echo ""
echo "TC-16: clean filter on the path -> rc=2"
d=$(newdir)
git -C "$d" init -q -b main
git -C "$d" config filter.dropfirst.clean 'sed 1d'
git -C "$d" config filter.dropfirst.smudge cat
printf 'f.txt filter=dropfirst\n' > "$d/.gitattributes"
gen 12 > "$d/f.txt"
g "$d" add -A
g "$d" commit -q -m filtered
setline "$d/f.txt" 5 "CHANGED"
run "$d" f.txt 5; expect "TC-16 line 5" 2
run "$d" f.txt 3; expect "TC-16 line 3" 2

# TC-17
echo ""
echo "TC-17: neither tracked nor untracked (nonexistent, ignored) -> rc=2"
d=$(newdir)
git -C "$d" init -q -b main
printf 'ignored.txt\n' > "$d/.gitignore"
gen 5 > "$d/f.txt"
g "$d" add -A
g "$d" commit -q -m base
gen 5 > "$d/ignored.txt"
run "$d" nonexistent.txt 1; expect "TC-17 nonexistent" 2
run "$d" ignored.txt 1; expect "TC-17 ignored" 2

# TC-18
echo ""
echo "TC-18: GIT_LITERAL_PATHSPECS=1 in the caller's environment does not hide a changed line"
d=$(newdir); mkbase "$d"
setline "$d/f.txt" 5 "CHANGED"
GIT_LITERAL_PATHSPECS=1 run "$d" f.txt 5; expect "TC-18 changed line 5" 0
GIT_LITERAL_PATHSPECS=1 run "$d" f.txt 3; expect "TC-18 unchanged line 3" 1

# TC-19
echo ""
echo "TC-19: GIT_DIFF_OPTS=-u10 in the caller's environment does not widen the hunk"
d=$(newdir); mkbase "$d"
setline "$d/f.txt" 5 "CHANGED"
GIT_DIFF_OPTS=-u10 run "$d" f.txt 5; expect "TC-19 changed line 5" 0
GIT_DIFF_OPTS=-u10 run "$d" f.txt 3; expect "TC-19 unchanged line 3" 1

# TC-20
echo ""
echo "TC-20: changed file that git reports as binary (no hunk) -> rc=2, not rc=1"
d=$(newdir); mkbase "$d"
git -C "$d" config core.bigFileThreshold 1
setline "$d/f.txt" 5 "CHANGED"
run "$d" f.txt 5; expect "TC-20 changed line 5" 2
expect_err "TC-20 changed line 5"
run "$d" f.txt 3; expect "TC-20 line 3" 2

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ] || exit 1
exit 0
