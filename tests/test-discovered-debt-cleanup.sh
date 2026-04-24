#!/bin/bash
# test-discovered-debt-cleanup.sh - discovered debt cleanup tests
# TC-01: alias 残留検査 (rules/) — 対象 5 files で informal alias が 0 件
# TC-02: alias 残留検査 (.claude/rules/) — 同 5 files mirror 側で 0 件
# TC-03: careful/SKILL.md に allowed-tools: 行が存在する
# TC-04: worker agents (sync-plan, green-worker, red-worker, refactorer) 全て model: 行が存在する

set -uo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

# 対象 5 rule files (doc-mutations.md は scope 外 — 例示行が意図的に残存)
SWEEP_FILES="agent-prompts.md plan-discipline.md review-triage.md skill-authoring.md test-patterns.md"
ALIAS_PATTERN="Cycle B|eval-[0-9]|A2[ab]"

# count_alias_in_dir <base_path_prefix> <tc_id>
#   base_path_prefix: e.g. "rules" or ".claude/rules"
#   tc_id: e.g. "TC-01" (used for missing-file fail message)
# stdout: total count (or 99 if any file missing)
count_alias_in_dir() {
  local dir="$1" tc_id="$2" total=0 fname fpath output n
  for fname in $SWEEP_FILES; do
    fpath="$BASE_DIR/$dir/$fname"
    if [ ! -f "$fpath" ]; then
      fail "$tc_id: $dir/$fname does not exist"
      echo 99
      return
    fi
    # pipefail masking 回避: 出力を変数に取得してから件数を数える
    output=$(grep -E "$ALIAS_PATTERN" "$fpath" 2>&1 || true)
    n=$(printf '%s' "$output" | grep -c . || true)
    total=$((total + n))
  done
  echo "$total"
}

echo "=== discovered-debt-cleanup Tests ==="

# TC-01: alias 残留検査 (rules/) — 対象 5 files で informal alias が 0 件
# Given: 24 occurrences の informal alias が rules/ 対象 5 files に存在する
# When:  grep -E "Cycle B|eval-[0-9]|A2[ab]" で検索する
# Then:  GREEN 完了後は 0 件 (現時点 RED = 24 件残存 → FAIL expected)
echo ""
echo "TC-01: alias 残留検査 (rules/) — 対象 5 files で informal alias が 0 件"
tc01_count=$(count_alias_in_dir "rules" "TC-01")
if [ "$tc01_count" -eq 0 ]; then
  pass "TC-01: rules/ 対象 5 files に informal alias が 0 件 (sweep 完了)"
else
  fail "TC-01: rules/ 対象 5 files に informal alias が ${tc01_count} 件残存 (sweep 未完了)"
fi

# TC-02: alias 残留検査 (.claude/rules/) — 同 5 files mirror 側で 0 件
# Given: mirror 側も同数 (24 occurrences) の informal alias が存在する
# When:  grep -E "Cycle B|eval-[0-9]|A2[ab]" で検索する
# Then:  GREEN 完了後は 0 件 (現時点 RED = 24 件残存 → FAIL expected)
echo ""
echo "TC-02: alias 残留検査 (.claude/rules/) — 対象 5 files mirror 側で informal alias が 0 件"
tc02_count=$(count_alias_in_dir ".claude/rules" "TC-02")
if [ "$tc02_count" -eq 0 ]; then
  pass "TC-02: .claude/rules/ 対象 5 files に informal alias が 0 件 (sweep 完了)"
else
  fail "TC-02: .claude/rules/ 対象 5 files に informal alias が ${tc02_count} 件残存 (sweep 未完了)"
fi

# TC-03: careful/SKILL.md に allowed-tools: 行が存在する
# Given: skills/careful/SKILL.md に allowed-tools: 行が存在しない
# When:  grep -q "^allowed-tools:" skills/careful/SKILL.md を実行する
# Then:  GREEN 完了後は 1 件 (現時点 RED = 不在 → FAIL expected)
echo ""
echo "TC-03: skills/careful/SKILL.md に allowed-tools: 行が存在する"
CAREFUL_SKILL="$BASE_DIR/skills/careful/SKILL.md"
if [ ! -f "$CAREFUL_SKILL" ]; then
  fail "TC-03: skills/careful/SKILL.md does not exist"
else
  output=$(grep "^allowed-tools:" "$CAREFUL_SKILL" 2>&1 || true)
  if [ -n "$output" ]; then
    pass "TC-03: skills/careful/SKILL.md に allowed-tools: 行が存在する"
  else
    fail "TC-03: skills/careful/SKILL.md に allowed-tools: 行が存在しない (要追加)"
  fi
fi

# TC-04: worker agents 全 4 files で model: 行が存在する (baseline regression guard)
# Given: 4 worker agents (sync-plan, green-worker, red-worker, refactorer) が model: frontmatter を持つ
# When:  各 agent file に grep "^model: " を実行する
# Then:  全 4 件 PASS (現時点 baseline 確認済 → PASS expected)
echo ""
echo "TC-04: worker agents 全 4 files で model: 行が存在する (baseline regression guard)"
WORKER_AGENTS="sync-plan green-worker red-worker refactorer"
tc04_pass=true
for agent in $WORKER_AGENTS; do
  fpath="$BASE_DIR/agents/${agent}.md"
  if [ ! -f "$fpath" ]; then
    fail "TC-04: agents/${agent}.md does not exist"
    tc04_pass=false
    continue
  fi
  output=$(grep "^model: " "$fpath" 2>&1 || true)
  if [ -z "$output" ]; then
    fail "TC-04: agents/${agent}.md に model: 行が存在しない"
    tc04_pass=false
  fi
done
if [ "$tc04_pass" = "true" ]; then
  pass "TC-04: 全 4 worker agents に model: 行が存在する"
fi

# Summary
echo ""
echo "PASS: $PASS, FAIL: $FAIL"
[ $FAIL -eq 0 ] && exit 0 || exit 1
