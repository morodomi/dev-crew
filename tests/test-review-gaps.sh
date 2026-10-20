#!/bin/bash
# test-review-gaps.sh - REVIEW の穴 4 件（#265 #266 #272 #273）の契約テスト
# TC-01, 02, 04〜06, 08〜13 は修正前に FAIL する。TC-03 と TC-07 は回帰契約（修正前でも PASS）。
#
# gate の TC は一時ディレクトリの docs/cycles/ に fixture の Cycle doc を作り、
# `bash scripts/gates/pre-commit-gate.sh <fixture.md>`（明示モード）で流す。
# `which codex` の有無は PATH で作る:
#   - codex あり: 偽の codex（実行可能な空スクリプト）を先頭に置いた PATH
#   - codex なし: /usr/bin:/bin のみ（実機に codex が入っていても影響されない）
# rc だけでなく BLOCK のメッセージも assert する。
#
# 逆向きの既存契約（tests/test-adversarial-review.sh）:
#   steps の REVIEW 節に `mktemp` が無いこと、agents/adversarial-reviewer.md の `## 禁止事項` に
#   `mktemp -d` があること。TC-12 は steps 側に mktemp を要求せず、TC-13 は fallback として
#   mktemp -d が残ることを要求する。

set -uo pipefail

BASE_DIR="${BASE_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

GATE="$BASE_DIR/scripts/gates/pre-commit-gate.sh"
COMMIT_SKILL="$BASE_DIR/skills/commit/SKILL.md"
AR="$BASE_DIR/skills/orchestrate/adversarial-review.md"
AGENT="$BASE_DIR/agents/adversarial-reviewer.md"
ORCH_DIR="$BASE_DIR/skills/orchestrate"
STEPS_FILES="$ORCH_DIR/steps-codex.md $ORCH_DIR/steps-subagent.md $ORCH_DIR/steps-teams.md"
BASH_BIN="$(command -v bash)"

# 件数の行の形（gate と commit skill が共有する正規表現。Design の文字列そのまま）
COUNT_RE='^- Codex review: (失敗（[^）]*）。adversarial-reviewer で代行: )?直す [0-9]+ / 人間に戻す [0-9]+ / 記録のみ [0-9]+'

TMPROOT=$(mktemp -d)
trap 'rm -rf "$TMPROOT"' EXIT
FAKE_BIN="$TMPROOT/fakebin"
mkdir -p "$FAKE_BIN"
printf '#!/bin/sh\nexit 0\n' > "$FAKE_BIN/codex"
chmod +x "$FAKE_BIN/codex"
PATH_WITH_CODEX="$FAKE_BIN:/usr/bin:/bin"
PATH_NO_CODEX="/usr/bin:/bin"

# sec FILE PREFIX LEVEL: PREFIX で始まる見出し（fence 外）から、LEVEL 以下の次の見出しまでを出す。
sec() {
  local file="$1" prefix="$2" level="$3"
  [ -f "$file" ] || return 0
  awk -v p="$prefix" -v lv="$level" '
    /^```/ { fence = !fence }
    !fence && /^#+ / {
      match($0, /^#+/); l = RLENGTH
      if (on && l <= lv) on = 0
      if (index($0, p) == 1) { on = 1; next }
    }
    on { print }
  ' "$file"
}

count_in() {
  local c
  c=$(printf '%s\n' "$1" | grep -cF -- "$2" || true)
  printf '%s' "${c:-0}"
}

# new_fixture NAME: 空の fixture ルートを作り、そのパスを出す
new_fixture() {
  local root="$TMPROOT/$1"
  mkdir -p "$root/docs/cycles"
  printf '%s' "$root"
}

# write_doc FILE: stdin の本文に frontmatter（phase: COMMIT, retro_status: captured）を付けて書く
write_doc() {
  {
    printf -- '---\nphase: COMMIT\nretro_status: captured\n---\n# fixture\n\n## Progress Log\n\n'
    cat
  } > "$1"
}

# run_gate DOC PATHVAR: 明示モードで gate を流し、出力を GATE_OUT、rc を GATE_RC に入れる
run_gate() {
  GATE_OUT=$(env PATH="$2" "$BASH_BIN" "$GATE" "$1" 2>&1)
  GATE_RC=$?
}

echo "=== REVIEW gaps tests ==="

# 偽 codex の PATH 差が which に反映されていること（前提の自己検証）
if env PATH="$PATH_WITH_CODEX" "$BASH_BIN" -c 'which codex' >/dev/null 2>&1 \
  && ! env PATH="$PATH_NO_CODEX" "$BASH_BIN" -c 'which codex' >/dev/null 2>&1; then
  pass "PRE: PATH fixtures control 'which codex' (with=found, without=absent)"
else
  fail "PRE: PATH fixtures do not control 'which codex'"
fi

# --- TC-01 ---
echo ""
echo "TC-01: REVIEW 節に件数の行が無く、Plan Review Record の似た行だけがあるとき BLOCK（codex あり）"
root=$(new_fixture tc01)
write_doc "$root/docs/cycles/20261020_0001_tc01.md" <<'DOC'
### 2026-10-20 09:00 - Plan Review (pre-approval)
- Codex review: 直す 1 / 人間に戻す 0 / 記録のみ 0
- Phase completed

### 2026-10-20 10:00 - REVIEW
- Code review passed
- Phase completed
DOC
run_gate "$root/docs/cycles/20261020_0001_tc01.md" "$PATH_WITH_CODEX"
if [ "$GATE_RC" -eq 1 ] && [ "$(count_in "$GATE_OUT" "Codex review result not recorded")" -ge 1 ]; then
  pass "TC-01: BLOCK with 'Codex review result not recorded'"
else
  fail "TC-01: expected rc=1 + 'Codex review result not recorded', got rc=$GATE_RC out: $GATE_OUT"
fi

# --- TC-02 ---
echo ""
echo "TC-02: 件数の行が REVIEW の後の別の ### 節にだけあるとき BLOCK（codex あり）"
root=$(new_fixture tc02)
write_doc "$root/docs/cycles/20261020_0002_tc02.md" <<'DOC'
### 2026-10-20 10:00 - REVIEW
- Code review passed
- Phase completed

### 2026-10-20 10:30 - COMMIT
- Codex review: 直す 1 / 人間に戻す 0 / 記録のみ 0
DOC
run_gate "$root/docs/cycles/20261020_0002_tc02.md" "$PATH_WITH_CODEX"
if [ "$GATE_RC" -eq 1 ] && [ "$(count_in "$GATE_OUT" "Codex review result not recorded")" -ge 1 ]; then
  pass "TC-02: BLOCK when the count line lives outside the REVIEW section"
else
  fail "TC-02: expected rc=1 + 'Codex review result not recorded', got rc=$GATE_RC out: $GATE_OUT"
fi

# --- TC-03 (回帰契約) ---
echo ""
echo "TC-03: REVIEW 節に成功の形 / 失敗→代行の形の行があるとき PASS（codex あり）"
root=$(new_fixture tc03a)
write_doc "$root/docs/cycles/20261020_0003_tc03a.md" <<'DOC'
### 2026-10-20 10:00 - REVIEW
- Codex review: 直す 2 / 人間に戻す 1 / 記録のみ 3
- Phase completed
DOC
run_gate "$root/docs/cycles/20261020_0003_tc03a.md" "$PATH_WITH_CODEX"
rc_a=$GATE_RC; out_a=$GATE_OUT
root=$(new_fixture tc03b)
write_doc "$root/docs/cycles/20261020_0003_tc03b.md" <<'DOC'
### 2026-10-20 10:00 - REVIEW
- Codex review: 失敗（timeout）。adversarial-reviewer で代行: 直す 0 / 人間に戻す 1 / 記録のみ 2
- Phase completed
DOC
run_gate "$root/docs/cycles/20261020_0003_tc03b.md" "$PATH_WITH_CODEX"
rc_b=$GATE_RC; out_b=$GATE_OUT
if [ "$rc_a" -eq 0 ] && [ "$(count_in "$out_a" "PASS:")" -ge 1 ] \
  && [ "$rc_b" -eq 0 ] && [ "$(count_in "$out_b" "PASS:")" -ge 1 ]; then
  pass "TC-03: both count-line forms PASS"
else
  fail "TC-03: success-form rc=$rc_a / substitute-form rc=$rc_b (out: $out_a | $out_b)"
fi

# --- TC-04 ---
echo ""
echo "TC-04: 同じ fixture で件数の行だけを新形式→旧形式に差し替えると PASS→BLOCK（codex あり）"
root=$(new_fixture tc04)
doc="$root/docs/cycles/20261020_0004_tc04.md"
write_doc "$doc" <<'DOC'
### 2026-10-20 10:00 - REVIEW
- Codex review: 直す 2 / 人間に戻す 0 / 記録のみ 1
- Phase completed
DOC
run_gate "$doc" "$PATH_WITH_CODEX"
rc_new=$GATE_RC
sed 's|^- Codex review: .*$|- Codex review: Accept 2, Reject 0|' "$doc" > "$root/docs/cycles/20261020_0004_tc04_old.md"
run_gate "$root/docs/cycles/20261020_0004_tc04_old.md" "$PATH_WITH_CODEX"
if [ "$rc_new" -eq 0 ] && [ "$GATE_RC" -eq 1 ] \
  && [ "$(count_in "$GATE_OUT" "Codex review result not recorded")" -ge 1 ] \
  && [ "$(count_in "$GATE_OUT" "直す N / 人間に戻す M / 記録のみ K")" -ge 1 ]; then
  pass "TC-04: old-format line BLOCKs and the message shows the new count form"
else
  fail "TC-04: new-form rc=$rc_new, old-form rc=$GATE_RC, out: $GATE_OUT"
fi

# --- TC-05 ---
echo ""
echo "TC-05: REVIEW 節に Phase completed が無く、後ろの COMMIT 節にだけあるとき BLOCK"
fail_paths=""
for variant in with without; do
  root=$(new_fixture "tc05_$variant")
  doc="$root/docs/cycles/20261020_0005_$variant.md"
  write_doc "$doc" <<'DOC'
### 2026-10-20 10:00 - REVIEW
- Codex review: 直す 1 / 人間に戻す 0 / 記録のみ 0

### 2026-10-20 10:30 - COMMIT
- committed
- Phase completed
DOC
  if [ "$variant" = "with" ]; then p="$PATH_WITH_CODEX"; else p="$PATH_NO_CODEX"; fi
  run_gate "$doc" "$p"
  if [ "$GATE_RC" -ne 1 ] || [ "$(count_in "$GATE_OUT" "REVIEW not completed")" -lt 1 ]; then
    fail_paths="$fail_paths [$variant: rc=$GATE_RC out=$GATE_OUT]"
  fi
done
if [ -z "$fail_paths" ]; then
  pass "TC-05: BLOCK 'REVIEW not completed' with and without codex"
else
  fail "TC-05: expected BLOCK 'REVIEW not completed':$fail_paths"
fi

# --- TC-06 ---
echo ""
echo "TC-06: REVIEW 節が 2 つあるとき、最後の節だけを見る（codex あり）"
root=$(new_fixture tc06a)
write_doc "$root/docs/cycles/20261020_0006_a.md" <<'DOC'
### 2026-10-20 10:00 - REVIEW
- first attempt, no record

### 2026-10-20 10:20 - GREEN
- fix applied
- Phase completed

### 2026-10-20 10:40 - REVIEW
- Codex review: 直す 1 / 人間に戻す 0 / 記録のみ 0
- Phase completed
DOC
run_gate "$root/docs/cycles/20261020_0006_a.md" "$PATH_WITH_CODEX"
rc_last=$GATE_RC; out_last=$GATE_OUT
root=$(new_fixture tc06b)
write_doc "$root/docs/cycles/20261020_0006_b.md" <<'DOC'
### 2026-10-20 10:00 - REVIEW
- Codex review: 直す 1 / 人間に戻す 0 / 記録のみ 0
- Phase completed

### 2026-10-20 10:20 - GREEN
- fix applied
- Phase completed

### 2026-10-20 10:40 - REVIEW
- second attempt, no record
DOC
run_gate "$root/docs/cycles/20261020_0006_b.md" "$PATH_WITH_CODEX"
rc_first=$GATE_RC; out_first=$GATE_OUT
if [ "$rc_last" -eq 0 ] && [ "$rc_first" -eq 1 ] \
  && [ "$(count_in "$out_first" "REVIEW not completed")" -ge 1 ]; then
  pass "TC-06: last REVIEW section decides (last-only PASS, first-only BLOCK)"
else
  fail "TC-06: last-only rc=$rc_last (out: $out_last); first-only rc=$rc_first (out: $out_first)"
fi

# --- TC-07 (回帰契約) ---
echo ""
echo "TC-07: codex の無い PATH では件数の行が無くても検査 2 で止まらない"
root=$(new_fixture tc07)
write_doc "$root/docs/cycles/20261020_0007_tc07.md" <<'DOC'
### 2026-10-20 10:00 - REVIEW
- Adversarial review passed
- Phase completed
DOC
run_gate "$root/docs/cycles/20261020_0007_tc07.md" "$PATH_NO_CODEX"
if [ "$GATE_RC" -eq 0 ] && [ "$(count_in "$GATE_OUT" "PASS:")" -ge 1 ] \
  && [ "$(count_in "$GATE_OUT" "Codex review result not recorded")" -eq 0 ]; then
  pass "TC-07: check 2 does not run without codex"
else
  fail "TC-07: expected PASS without codex, got rc=$GATE_RC out: $GATE_OUT"
fi

# --- TC-08 ---
echo ""
echo "TC-08: commit skill の Pre-COMMIT Gate bash ブロックが gate と同じ件数の正規表現を持つ"
gate_src=$(cat "$GATE" 2>/dev/null || true)
pc_sec=$(sec "$COMMIT_SKILL" "### Pre-COMMIT Gate" 3)
# 見出し区間の中の ```bash ブロックだけを取り出す（区間外の decoy を拾わない）
pc_block=$(printf '%s\n' "$pc_sec" | awk '/^```bash/{on=1;next} /^```/{on=0} on')
missing=""
[ "$(count_in "$gate_src" "$COUNT_RE")" -ge 1 ] || missing="$missing [gate script: 件数の正規表現]"
[ "$(count_in "$pc_block" "$COUNT_RE")" -ge 1 ] || missing="$missing [commit SKILL bash block: 件数の正規表現]"
if [ -z "$pc_block" ]; then missing="$missing [bash block empty]"; fi
if [ "$(count_in "$pc_block" "grep -qiE 'Codex.*review")" -ge 1 ]; then
  missing="$missing [旧式 grep -qiE 'Codex.*review が残っている]"
fi
if [ -z "$missing" ]; then
  pass "TC-08: commit skill gate regex matches the gate script, old grep gone"
else
  fail "TC-08:$missing"
fi

# --- TC-09 ---
echo ""
echo "TC-09: commit skill Step 5 が新しい区分、SKILL.md は 100 行未満"
step5=$(sec "$COMMIT_SKILL" "### Step 5" 3)
missing=""
for lit in "直す" "人間に戻す" "記録のみ"; do
  [ "$(count_in "$step5" "$lit")" -ge 1 ] || missing="$missing [$lit]"
done
[ "$(count_in "$step5" "Accept: X")" -eq 0 ] || missing="$missing [旧区分 'Accept: X' が残っている]"
[ -n "$step5" ] || missing="$missing [Step 5 empty]"
lines=$(wc -l < "$COMMIT_SKILL" | tr -d ' ')
[ "${lines:-999}" -lt 100 ] || missing="$missing [SKILL.md ${lines} lines >= 100]"
if [ -z "$missing" ]; then
  pass "TC-09: Step 5 uses 直す/人間に戻す/記録のみ, SKILL.md < 100 lines"
else
  fail "TC-09:$missing"
fi

# --- TC-10 ---
echo ""
echo "TC-10: adversarial-review.md ## 振り分け に元からある欠陥の項とキャッシュを消す指示"
body=$(sec "$AR" "## 振り分け" 2)
missing=""
for lit in "今回の diff が入れたものではない" "修正の前に無かった未追跡ファイル"; do
  [ "$(count_in "$body" "$lit")" -ge 1 ] || missing="$missing [$lit]"
done
[ -n "$body" ] || missing="$missing [section empty]"
if [ -z "$missing" ]; then
  pass "TC-10: 振り分け has the pre-existing-defect rule and the cache cleanup rule"
else
  fail "TC-10: 振り分け missing:$missing"
fi

# --- TC-11 ---
echo ""
echo "TC-11: adversarial-review.md ## 頼み方 が scratch ディレクトリを渡す"
body=$(sec "$AR" "## 頼み方" 2)
missing=""
[ "$(count_in "$body" '/tmp/dev-crew-review-<cycle_id>/scratch')" -ge 1 ] || missing="$missing [scratch path]"
[ "$(count_in "$body" '/tmp に置く')" -eq 0 ] || missing="$missing [旧文 '/tmp に置く' が残っている]"
[ -n "$body" ] || missing="$missing [section empty]"
if [ -z "$missing" ]; then
  pass "TC-11: 頼み方 uses the scratch directory, no 'put in /tmp'"
else
  fail "TC-11: 頼み方:$missing"
fi

# --- TC-12 ---
# 'git ls-files --others --exclude-standard' は対象の列挙（手順 0）で既に 1 行ある。
# 修正役の前後で 2 回取る指示を見るため、REVIEW 節で 2 行以上を要求する（単体語 pin を避ける）。
echo ""
echo "TC-12: steps-codex/subagent/teams の REVIEW 節に前後比較・片付け・TC-R 追記・scratch の mkdir -p"
missing=""
for f in $STEPS_FILES; do
  b=$(basename "$f")
  body=$(sec "$f" "### REVIEW" 3)
  if [ -z "$body" ]; then missing="$missing [$b: REVIEW 節なし]"; continue; fi
  n=$(count_in "$body" "git ls-files --others --exclude-standard")
  [ "$n" -ge 2 ] || missing="$missing [$b: git ls-files --others --exclude-standard が ${n} 行（修正役の前後で 2 行以上）]"
  for lit in "片付け" "TC-R" "mkdir -p /tmp/dev-crew-review-<cycle_id>/scratch"; do
    [ "$(count_in "$body" "$lit")" -ge 1 ] || missing="$missing [$b: $lit]"
  done
done
if [ -z "$missing" ]; then
  pass "TC-12: all 3 steps files carry cleanup / TC-R / scratch instructions"
else
  fail "TC-12:$missing"
fi

# --- TC-13 ---
echo ""
echo "TC-13: adversarial-reviewer.md が scratch ディレクトリを使い、mktemp -d を fallback に残す"
whole=$(cat "$AGENT" 2>/dev/null || true)
prohibit=$(sec "$AGENT" "## 禁止事項" 2)
missing=""
[ "$(count_in "$whole" "scratch")" -ge 1 ] || missing="$missing [scratch ディレクトリの指示]"
[ "$(count_in "$prohibit" "mktemp -d")" -ge 1 ] || missing="$missing [禁止事項に mktemp -d (fallback)]"
if [ "$(count_in "$whole" '/tmp` に置く')" -ge 1 ] || [ "$(count_in "$whole" '/tmp に置く')" -ge 1 ]; then
  missing="$missing [旧文 '/tmp に置く' が残っている]"
fi
if [ -z "$missing" ]; then
  pass "TC-13: reviewer uses the scratch directory and keeps mktemp -d as fallback"
else
  fail "TC-13:$missing"
fi

# --- TC-14 ---
echo ""
echo "TC-14: REVIEW 節のコードブロック内の ### 行で節が切れず、件数の行と完了記録が見つかる（codex あり）"
root=$(new_fixture tc14)
write_doc "$root/docs/cycles/20261020_0014_tc14.md" <<'DOC'
### 2026-10-20 10:00 - REVIEW
- 確認した入力:
```markdown
### example
```
- Codex review: 直す 1 / 人間に戻す 0 / 記録のみ 0
- Phase completed
DOC
run_gate "$root/docs/cycles/20261020_0014_tc14.md" "$PATH_WITH_CODEX"
if [ "$GATE_RC" -eq 0 ]; then
  pass "TC-14: PASS when a fenced '### ' line sits inside the REVIEW section"
else
  fail "TC-14: expected rc=0, got rc=$GATE_RC out: $GATE_OUT"
fi

# --- TC-15 ---
echo ""
echo "TC-15: 後続節のコードブロック内にある偽の REVIEW 見出し・件数行では通らない（codex あり）"
root=$(new_fixture tc15)
write_doc "$root/docs/cycles/20261020_0015_tc15.md" <<'DOC'
### 2026-10-20 10:00 - REVIEW
- Code review passed

### 2026-10-20 10:30 - GREEN
```markdown
### 2026-10-20 10:40 - REVIEW
- Codex review: 直す 1 / 人間に戻す 0 / 記録のみ 0
- Phase completed
```
DOC
run_gate "$root/docs/cycles/20261020_0015_tc15.md" "$PATH_WITH_CODEX"
if [ "$GATE_RC" -eq 1 ] && [ "$(count_in "$GATE_OUT" "REVIEW not completed")" -ge 1 ]; then
  pass "TC-15: BLOCK when the only complete REVIEW heading is inside a code fence"
else
  fail "TC-15: expected rc=1 + 'REVIEW not completed', got rc=$GATE_RC out: $GATE_OUT"
fi

# --- TC-16 ---
echo ""
echo "TC-16: commit skill の bash ブロックも gate と同じくコードブロックを飛ばす"
skill_awk=$(grep -F 'SEC=$(awk' "$COMMIT_SKILL" 2>/dev/null || true)
if [ "$(count_in "$skill_awk" '^```')" -ge 1 ]; then
  pass "TC-16: commit skill awk is fence-aware"
else
  fail "TC-16: commit skill awk does not toggle on code fences"
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
