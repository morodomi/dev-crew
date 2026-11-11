#!/bin/bash
# test-skill-script-paths.sh - skill 文書が呼ぶ本体スクリプトは Base directory からの相対で書く
#
# 導入先の repo には scripts/ が無い（onboard が配るのは rules と hooks だけ）。
# skill 文書の `bash scripts/...` は本体の作業ツリーでしか動かないので、
# `bash "<S の Base directory>/../../scripts/..."` の形に揃える。
#
# TC-01: skills/ 配下に引用符なしの相対パス呼び出し（bash scripts/ / bash skills/）が残っていない
# TC-02: 一覧の各文書が、期待する形の呼び出しを持ち、S が文書のある skill と一致する
# TC-03: TC-02 の各呼び出しが skills/<S>/ を起点に実在するファイルへ解決される
# TC-04: 本体の外の git repo を cwd にして、解決したパスで recall / fingerprint が動く
# TC-05: orchestrate の steps 3 ファイルが同じ形の呼び出しを持つ（モード間の一致）
#
# 説明文の中の言及（パスなしの scripts/gates/...）ではなく、`bash "<` で始まる
# 呼び出しの文字列そのものを切り出して検査する（説明文と起動の文字列が同じ行に並ぶため）。

set -uo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== Skill Script Path Tests ==="

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# 呼び出し箇所の一覧: <文書 (BASE_DIR からの相対)>|<S: その文書がある skill>|<Base directory からの相対>
# review のスクリプトは skill の中にあるので ../../scripts を経由しない。
SITES="
skills/orchestrate/steps-subagent.md|orchestrate|/../../scripts/gates/pre-red-gate.sh
skills/orchestrate/steps-subagent.md|orchestrate|/../../scripts/gates/worktree-fingerprint.sh
skills/orchestrate/steps-subagent.md|orchestrate|/../../scripts/gates/finding-in-diff.sh
skills/orchestrate/steps-teams.md|orchestrate|/../../scripts/gates/pre-red-gate.sh
skills/orchestrate/steps-teams.md|orchestrate|/../../scripts/gates/worktree-fingerprint.sh
skills/orchestrate/steps-teams.md|orchestrate|/../../scripts/gates/finding-in-diff.sh
skills/orchestrate/SKILL.md|orchestrate|/../../scripts/gates/pre-commit-gate.sh
skills/spec/SKILL.md|spec|/../../scripts/recall-candidates.sh
skills/spec/reference.md|spec|/../../scripts/recall-candidates.sh
skills/spec/reference.ja.md|spec|/../../scripts/recall-candidates.sh
skills/red/SKILL.md|red|/../../scripts/gates/exspec-check.sh
skills/red/reference.md|red|/../../scripts/gates/exspec-check.sh
skills/learn/SKILL.md|learn|/../../scripts/tfidf-summary.sh
skills/review/steps-subagent.md|review|/risk-classifier.sh
skills/review/steps-subagent.md|review|/severity-verdict.sh
"

# calls_of <file> <script basename>: `bash "<...>/<name>"` の文字列そのものを 1 行ずつ出力する
calls_of() {
  local file="$1" name="$2" out
  out=$(grep -oE 'bash "<[^"]*/'"$name"'"' "$BASE_DIR/$file" 2>/dev/null) || out=""
  [ -n "$out" ] && printf '%s\n' "$out"
  return 0
}

# ---------------------------------------------------------------------------
# TC-01
# ---------------------------------------------------------------------------
echo ""
echo "TC-01: no unquoted relative 'bash scripts/' or 'bash skills/' call remains under skills/"
tc01=$(cd "$BASE_DIR" && grep -rnE 'bash (scripts|skills)/' skills --include='*.md' 2>/dev/null) || tc01=""
if [ -z "$tc01" ]; then
  pass "TC-01: no relative-path call remains"
else
  tc01_n=$(printf '%s\n' "$tc01" | wc -l | tr -d ' ')
  fail "TC-01: $tc01_n relative-path call line(s) remain (e.g. $(printf '%s\n' "$tc01" | head -3 | cut -c1-110 | tr '\n' ' '))"
fi

# ---------------------------------------------------------------------------
# TC-02 / TC-03: 一覧の各行を検査し、解決先を RESOLVED に溜める（TC-04 で使う）
# ---------------------------------------------------------------------------
echo ""
echo "TC-02: each listed doc has 'bash \"<S の Base directory>…<name>\"' with S = its own skill"
echo "TC-03: each such call resolves from skills/<S>/ to an existing file"

RESOLVED="$TMPDIR/resolved.tsv"
: > "$RESOLVED"
tc02_bad=""
tc03_bad=""
tc02_n=0
while IFS='|' read -r doc skill rel; do
  [ -z "$doc" ] && continue
  tc02_n=$((tc02_n + 1))
  name=$(basename "$rel")
  expected="bash \"<$skill の Base directory>$rel\""
  calls=$(calls_of "$doc" "$name")
  # 実際の文字列が期待の形と一致する（S 違い・段数違い・名前違いはここで落ちる）
  if [ -z "$calls" ]; then
    tc02_bad="$tc02_bad [$doc: $name の呼び出し(bash \"<...)なし]"
    tc03_bad="$tc03_bad [$doc: $name 呼び出しなしで解決不能]"
    continue
  fi
  wrong=$(printf '%s\n' "$calls" | grep -vxF -- "$expected" || true)
  if [ -n "$wrong" ]; then
    tc02_bad="$tc02_bad [$doc: $name の呼び出しが期待と違う: $(printf '%s' "$wrong" | head -1)]"
  fi
  # TC-03: 文書が書いた呼び出し（期待の形に限らない）から Base directory 以降を取り出して解決する
  while IFS= read -r call; do
    [ -z "$call" ] && continue
    tail_part=${call#*の Base directory>}
    tail_part=${tail_part%\"}
    target="$BASE_DIR/skills/$skill$tail_part"
    if [ -f "$target" ]; then
      printf '%s\t%s\t%s\n' "$doc" "$name" "$target" >> "$RESOLVED"
    else
      tc03_bad="$tc03_bad [$doc: skills/$skill$tail_part は実在しない]"
    fi
  done <<< "$calls"
done <<< "$SITES"

if [ -z "$tc02_bad" ]; then
  pass "TC-02: all $tc02_n listed call sites have the expected form"
else
  fail "TC-02:$tc02_bad"
fi
if [ -z "$tc03_bad" ]; then
  pass "TC-03: all listed calls resolve to existing files"
else
  fail "TC-03:$tc03_bad"
fi

# ---------------------------------------------------------------------------
# TC-04: 本体の外の git repo を cwd にして、解決したパスで動く
# ---------------------------------------------------------------------------
echo ""
echo "TC-04: from a repo outside the plugin, resolved recall-candidates.sh / worktree-fingerprint.sh work"

resolved_of() { # <doc> <name> -> 解決済みパス（最初の 1 件）
  awk -F'\t' -v d="$1" -v n="$2" '$1==d && $2==n {print $3; exit}' "$RESOLVED"
}
RECALL=$(resolved_of skills/spec/SKILL.md recall-candidates.sh)
FPRINT=$(resolved_of skills/orchestrate/steps-subagent.md worktree-fingerprint.sh)

if [ -z "$RECALL" ] || [ -z "$FPRINT" ]; then
  fail "TC-04: no resolvable path from the docs (recall='${RECALL:-none}' fingerprint='${FPRINT:-none}')"
else
  REPO="$TMPDIR/fixture-repo"
  mkdir -p "$REPO"
  export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null GIT_CONFIG_NOSYSTEM=1
  export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.invalid GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.invalid
  DOC_REL="docs/cycles/20260101_0000_fixture-unique-doc.md"
  (
    cd "$REPO" || exit 1
    git init -q . &&
    echo init > README.md && git add README.md && git commit -qm "init" &&
    mkdir -p docs/cycles src &&
    printf -- '---\nphase: DONE\n---\n# fixture\n' > "$DOC_REL" &&
    echo v1 > src/target.txt &&
    git add . &&
    git commit -qm "$(printf 'feat: target\n\nCycle-Doc: %s' "$DOC_REL")"
  ) >/dev/null 2>&1
  setup_rc=$?
  if [ "$setup_rc" -ne 0 ]; then
    fail "TC-04: fixture repo setup failed (rc=$setup_rc)"
  else
    recall_out=$(cd "$REPO" && bash "$RECALL" . src/target.txt 2>&1) && recall_rc=0 || recall_rc=$?
    fp_before=$(cd "$REPO" && bash "$FPRINT" 2>&1) && fp1_rc=0 || fp1_rc=$?
    echo v2 > "$REPO/src/target.txt"
    fp_after=$(cd "$REPO" && bash "$FPRINT" 2>&1) && fp2_rc=0 || fp2_rc=$?
    tc04_bad=""
    [ "$recall_rc" -eq 0 ] || tc04_bad="$tc04_bad [recall rc=$recall_rc: $recall_out]"
    printf '%s\n' "$recall_out" | grep -qF "$DOC_REL" >/dev/null 2>&1 || tc04_bad="$tc04_bad [recall がfixture固有の Cycle doc を返さない: $recall_out]"
    [ "$fp1_rc" -eq 0 ] && [ "$fp2_rc" -eq 0 ] || tc04_bad="$tc04_bad [fingerprint rc=$fp1_rc/$fp2_rc]"
    if ! printf '%s' "$fp_before" | grep -qE '^[0-9a-f]{64}$' >/dev/null 2>&1; then
      tc04_bad="$tc04_bad [fingerprint が 64 桁 hex でない: $fp_before]"
    fi
    [ "$fp_before" != "$fp_after" ] || tc04_bad="$tc04_bad [ファイルを書き換えても fingerprint が変わらない]"
    if [ -z "$tc04_bad" ]; then
      pass "TC-04: recall returns the fixture cycle doc; fingerprint changes after a write"
    else
      fail "TC-04:$tc04_bad"
    fi
  fi
fi

# ---------------------------------------------------------------------------
# TC-05: orchestrate の steps 3 ファイルで同じ呼び出しを持つ
# ---------------------------------------------------------------------------
echo ""
echo "TC-05: orchestrate steps-subagent/teams carry identical gate call strings"
tc05_bad=""
for name in pre-red-gate.sh worktree-fingerprint.sh finding-in-diff.sh; do
  ref=$(calls_of skills/orchestrate/steps-subagent.md "$name" | sort -u)
  if [ -z "$ref" ]; then
    tc05_bad="$tc05_bad [steps-subagent.md: $name の呼び出しなし]"
    continue
  fi
  for f in steps-teams.md; do
    cur=$(calls_of "skills/orchestrate/$f" "$name" | sort -u)
    [ "$cur" = "$ref" ] || tc05_bad="$tc05_bad [$f: $name の呼び出しが steps-subagent.md と揃っていない]"
  done
done
if [ -z "$tc05_bad" ]; then
  pass "TC-05: call strings match across the 2 orchestrate step files"
else
  fail "TC-05:$tc05_bad"
fi

echo ""
echo "=== Summary ==="
echo "PASS: $PASS"
echo "FAIL: $FAIL"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
