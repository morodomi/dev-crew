#!/usr/bin/env bash
# Test: Post-Approve Action ordering matches workflow.md
#
# Codex plan review は承認前（plan mode 内、spec Step 8）へ移動した。新順序は
# 「plan review が sync-plan/承認より前」。
# TC-01/02/05 は旧順序（sync-plan before plan-review）を assert していたため、
# 新順序を assert するよう反転した（v2.8 orchestrate integration 時代の旧契約を上書き）。
# TC-R1〜R4/R6/R10〜R14 は plan review pre-approval 化に伴う新規契約。

set -euo pipefail
PASS=0; FAIL=0
BASE="$(cd "$(dirname "$0")/.." && pwd)"

pass() { PASS=$((PASS+1)); echo "  PASS: $1"; }
fail() { FAIL=$((FAIL+1)); echo "  FAIL: $1"; }

echo "=== Post-Approve Action Ordering ==="

# Helper: whole-file check that a "pre-approval" plan review marker appears
# before the "approve" line (Post-Approve Action opening). New design moves
# Codex plan review into spec Step 8, executed before ExitPlanMode/approve —
# so a pre-approval marker must exist earlier in the file than "approve".
check_review_before_approve() {
  local file="$1"
  local approve_line review_line
  approve_line=$(grep -n "approve" "$file" | head -1 | cut -d: -f1)
  review_line=$(grep -nF "承認前" "$file" | head -1 | cut -d: -f1)
  if [ -n "$approve_line" ] && [ -n "$review_line" ] && [ "$review_line" -lt "$approve_line" ]; then
    return 0
  else
    echo "    pre-approval marker at line ${review_line:-?}, approve at line ${approve_line:-?} in $file"
    return 1
  fi
}

# Helper: check all three steps exist in Post-Approve section
check_three_steps() {
  local file="$1"
  local section
  section=$(sed -n '/^## Post-Approve Action/,/^```$/p' "$file")
  local missing=""
  echo "$section" | grep -qi "sync-plan\|Cycle doc" || missing="$missing sync-plan"
  echo "$section" | grep -qi "plan.review\|Plan review\|設計レビュー" || missing="$missing plan-review"
  echo "$section" | grep -qi "orchestrate\|Codex" || missing="$missing orchestrate"
  if [ -z "$missing" ]; then
    return 0
  else
    echo "    missing:$missing"
    return 1
  fi
}

# TC-01: reference.md - pre-approval plan review marker before approve (flipped)
if check_review_before_approve "$BASE/skills/spec/reference.md"; then
  pass "TC-01: reference.md pre-approval plan review before approve"
else
  fail "TC-01: reference.md pre-approval plan review should be before approve"
fi

# TC-02: reference.ja.md - pre-approval plan review marker before approve (flipped)
if check_review_before_approve "$BASE/skills/spec/reference.ja.md"; then
  pass "TC-02: reference.ja.md pre-approval plan review before approve"
else
  fail "TC-02: reference.ja.md pre-approval plan review should be before approve"
fi

# TC-03: reference.md contains all three steps (unchanged)
if check_three_steps "$BASE/skills/spec/reference.md"; then
  pass "TC-03: reference.md contains all three Post-Approve steps"
else
  fail "TC-03: reference.md missing steps"
fi

# TC-04: reference.ja.md contains all three steps (unchanged)
if check_three_steps "$BASE/skills/spec/reference.ja.md"; then
  pass "TC-04: reference.ja.md contains all three Post-Approve steps"
else
  fail "TC-04: reference.ja.md missing steps"
fi

# TC-05: workflow.md - plan-review mention now precedes sync-plan mention (flipped)
workflow="$BASE/docs/workflow.md"
wf_review_line=$(grep -niE "plan.review|plan-review" "$workflow" | head -1 | cut -d: -f1)
wf_sync_line=$(grep -n "sync-plan" "$workflow" | head -1 | cut -d: -f1)
if [ -n "$wf_review_line" ] && [ -n "$wf_sync_line" ] && [ "$wf_review_line" -lt "$wf_sync_line" ]; then
  pass "TC-05: workflow.md confirms plan-review before sync-plan (L${wf_review_line} < L${wf_sync_line})"
else
  fail "TC-05: workflow.md ordering unexpected (review L${wf_review_line:-?}, sync-plan L${wf_sync_line:-?})"
fi

# TC-06: existing test passes (regression)
if bash "$BASE/tests/test-plugin-structure.sh" > /dev/null 2>&1; then
  pass "TC-06: test-plugin-structure.sh passes (regression)"
else
  fail "TC-06: test-plugin-structure.sh failed"
fi

########################################
# TC-R1〜R4/R6/R10〜R14: plan review pre-approval 化に伴う新契約
########################################

# TC-R1: reference.md / reference.ja.md — plan review 言及が承認より前
#        + Post-Approve Action 内に "codex exec.*review plan" 系記述が不在
echo ""
echo "TC-R1: spec reference.md / reference.ja.md — pre-approval review + no in-Post-Approve Codex review"
r1_ok=true
r1_msgs=""

for f in "$BASE/skills/spec/reference.md" "$BASE/skills/spec/reference.ja.md"; do
  if ! check_review_before_approve "$f" > /dev/null 2>&1; then
    r1_ok=false
    r1_msgs="$r1_msgs $(basename "$f"):review-not-before-approve"
  fi
  section=$(sed -n '/^## Post-Approve Action/,/^```$/p' "$f")
  if echo "$section" | grep -qiE "codex exec.*review plan|codex.*plan.*review"; then
    r1_ok=false
    r1_msgs="$r1_msgs $(basename "$f"):codex-plan-review-still-in-post-approve"
  fi
done

if $r1_ok; then
  pass "TC-R1: pre-approval review ordering + Post-Approve Action has no Codex plan review"
else
  fail "TC-R1: violations:$r1_msgs"
fi

# TC-R2: docs/workflow.md — plan review 行 < 承認ゲート(1) 行
echo ""
echo "TC-R2: docs/workflow.md — plan review line precedes 承認ゲート(1) label"
gate1_line=$(grep -nF "承認ゲート(1)" "$workflow" | head -1 | cut -d: -f1)
review_line_r2=$(grep -niE "plan.review|plan-review" "$workflow" | head -1 | cut -d: -f1)
if [ -n "$gate1_line" ] && [ -n "$review_line_r2" ] && [ "$review_line_r2" -lt "$gate1_line" ]; then
  pass "TC-R2: plan review (L${review_line_r2}) precedes 承認ゲート(1) (L${gate1_line})"
else
  fail "TC-R2: plan review (L${review_line_r2:-?}) does NOT precede 承認ゲート(1) (L${gate1_line:-?})"
fi

# TC-R3: agents/sync-plan.md — 転記契約 (Plan Review (pre-approval) 見出し様式 /
#        codex_session_id 転記 / reviewed_plan_hash 照合手順)
echo ""
echo "TC-R3: agents/sync-plan.md — Plan Review (pre-approval) transfer contract"
SYNC_PLAN_MD="$BASE/agents/sync-plan.md"
r3_ok=true
r3_msgs=""
grep -qF "Plan Review (pre-approval)" "$SYNC_PLAN_MD" || { r3_ok=false; r3_msgs="$r3_msgs no-heading"; }
grep -qF "codex_session_id を転記" "$SYNC_PLAN_MD" || { r3_ok=false; r3_msgs="$r3_msgs no-session-transfer"; }
grep -qF "reviewed_plan_hash" "$SYNC_PLAN_MD" || { r3_ok=false; r3_msgs="$r3_msgs no-hash-field"; }
if $r3_ok; then
  pass "TC-R3: sync-plan.md has Plan Review (pre-approval) transfer contract"
else
  fail "TC-R3: sync-plan.md missing:$r3_msgs"
fi

# TC-R4: skills/spec/SKILL.md — Step 8 (--sandbox read-only) + 100行未満
echo ""
echo "TC-R4: skills/spec/SKILL.md — Step 8 with --sandbox read-only, under 100 lines"
SPEC_SKILL_MD="$BASE/skills/spec/SKILL.md"
r4_ok=true
r4_msgs=""
grep -q "^### Step 8" "$SPEC_SKILL_MD" || { r4_ok=false; r4_msgs="$r4_msgs no-step8-heading"; }
grep -qF -- "--sandbox read-only" "$SPEC_SKILL_MD" || { r4_ok=false; r4_msgs="$r4_msgs no-sandbox-read-only"; }
skill_line_count=$(wc -l < "$SPEC_SKILL_MD")
if [ "$skill_line_count" -ge 100 ]; then
  r4_ok=false
  r4_msgs="$r4_msgs over-100-lines($skill_line_count)"
fi
if $r4_ok; then
  pass "TC-R4: SKILL.md has Step 8 (--sandbox read-only) and is under 100 lines ($skill_line_count)"
else
  fail "TC-R4: SKILL.md missing/violates:$r4_msgs"
fi

# TC-R6: 同一性保証 — fixture plan（Record の hash と本文 hash 不一致）を用意した上で
#        sync-plan.md の hash 不一致時の手順文が存在することを pin。
#        実行系は agent (自然言語) のため runtime invocation はできない — 手順文契約と
#        して pin する（gate 側の実 hash 照合は test-pre-red-gate.sh TC-R15(f) が担当し、
#        two-sided coverage で二重化する）。
echo ""
echo "TC-R6: fixture plan (hash mismatch) + sync-plan.md hash-mismatch procedure text"
TCR6_TMPDIR=$(mktemp -d)
FIXTURE_PLAN_R6="$TCR6_TMPDIR/fixture-plan.md"
cat > "$FIXTURE_PLAN_R6" <<'PLAN'
# Fixture Plan (TC-R6)

Fixture plan body used to document the hash-mismatch scenario.

## Plan Review Record
- reviewed_plan_hash: 0000000000000000000000000000000000000000000000000000000000000000
PLAN
FIXTURE_REAL_HASH_R6=$(sed -n '1,/^## Plan Review Record$/p' "$FIXTURE_PLAN_R6" | sed '$d' | shasum -a 256 | awk '{print $1}')
FIXTURE_RECORDED_HASH_R6="0000000000000000000000000000000000000000000000000000000000000000"
if [ "$FIXTURE_REAL_HASH_R6" != "$FIXTURE_RECORDED_HASH_R6" ] && grep -qF "不一致" "$SYNC_PLAN_MD"; then
  pass "TC-R6: fixture plan hash mismatch confirmed + sync-plan.md documents mismatch handling"
else
  fail "TC-R6: fixture mismatch=$([ "$FIXTURE_REAL_HASH_R6" != "$FIXTURE_RECORDED_HASH_R6" ] && echo yes || echo no), sync-plan.md 不一致 procedure present=$(grep -qF "不一致" "$SYNC_PLAN_MD" && echo yes || echo no)"
fi
rm -rf "$TCR6_TMPDIR"

# TC-R10: steps-subagent.md / steps-teams.md / steps-codex.md — Block 1 が
#         「sync-plan 転記 → architect 検証」順（Task() 呼び出しの行番号比較）
echo ""
echo "TC-R10: steps-subagent/teams/codex.md — sync-plan Task() precedes architect Task() (all 3 docs)"
check_sync_then_architect() {
  local file="$1"
  local sync_line arch_line
  sync_line=$(grep -n 'Task(subagent_type: "dev-crew:sync-plan"' "$file" | head -1 | cut -d: -f1)
  arch_line=$(grep -n 'Task(subagent_type: "dev-crew:architect"' "$file" | head -1 | cut -d: -f1)
  if [ -n "$sync_line" ] && [ -n "$arch_line" ] && [ "$sync_line" -lt "$arch_line" ]; then
    return 0
  else
    echo "    $(basename "$file"): sync-plan Task() at line ${sync_line:-?}, architect Task() at line ${arch_line:-?}"
    return 1
  fi
}
r10_ok=true
r10_msgs=""
for f in "$BASE/skills/orchestrate/steps-subagent.md" "$BASE/skills/orchestrate/steps-teams.md" "$BASE/skills/orchestrate/steps-codex.md"; do
  if ! check_sync_then_architect "$f"; then
    r10_ok=false
    r10_msgs="$r10_msgs $(basename "$f")"
  fi
done
if $r10_ok; then
  pass "TC-R10: all 3 orchestrate step docs have sync-plan Task() before architect Task()"
else
  fail "TC-R10: violations in:$r10_msgs"
fi

# TC-R11: rules 改訂 (.claude/rules/post-approve.md + doc-mutations.md x2 + state-ownership.md x2)
#         — pre-approval review 正規化・3 分岐・転記権限の記述存在
echo ""
echo "TC-R11: rules docs (post-approve / doc-mutations x2 / state-ownership x2) contain new contract descriptions"
r11_ok=true
r11_msgs=""

POST_APPROVE_RULE="$BASE/.claude/rules/post-approve.md"
if ! grep -qF "承認前" "$POST_APPROVE_RULE" || ! grep -qF "3 分岐" "$POST_APPROVE_RULE"; then
  r11_ok=false
  r11_msgs="$r11_msgs post-approve.md(承認前/3分岐欠落)"
fi

for f in "$BASE/rules/doc-mutations.md" "$BASE/.claude/rules/doc-mutations.md"; do
  if ! grep -qF "承認前" "$f" || ! grep -qF "承認後" "$f"; then
    r11_ok=false
    r11_msgs="$r11_msgs ${f#"$BASE"/}(承認前後欠落)"
  fi
done

for f in "$BASE/rules/state-ownership.md" "$BASE/.claude/rules/state-ownership.md"; do
  if ! grep -qF "転記権限" "$f"; then
    r11_ok=false
    r11_msgs="$r11_msgs ${f#"$BASE"/}(転記権限欠落)"
  fi
done

if $r11_ok; then
  pass "TC-R11: rules docs contain pre-approval normalization / 3-branch / transfer-authority descriptions"
else
  fail "TC-R11: missing:$r11_msgs"
fi

# TC-R12: Codex 不在経路 — spec/reference.md の Step 8 記述に codex_unavailable 記録規定
echo ""
echo "TC-R12: spec/reference.md Step 8 records codex_unavailable when Codex is absent"
if grep -qF "codex_unavailable" "$BASE/skills/spec/reference.md"; then
  pass "TC-R12: reference.md Step 8 has codex_unavailable recording rule"
else
  fail "TC-R12: reference.md missing codex_unavailable recording rule"
fi

# TC-R13: review skill の plan mode 前提整理 — Cycle doc 前提記述の除去 + plan file 前提の記述
echo ""
echo "TC-R13: skills/review — plan mode no longer depends on Cycle doc, 'plan file 前提' documented"
REVIEW_STEPS="$BASE/skills/review/steps-subagent.md"
r13_ok=true
r13_msgs=""
if grep -qF "Cycle doc の変更予定ファイル" "$REVIEW_STEPS"; then
  r13_ok=false
  r13_msgs="$r13_msgs steps-subagent.md-still-references-cycle-doc-in-plan-mode"
fi
if ! grep -rlF "plan file 前提" "$BASE/skills/review/SKILL.md" "$BASE/skills/review/steps-subagent.md" "$BASE/skills/review/reference.md" > /dev/null 2>&1; then
  r13_ok=false
  r13_msgs="$r13_msgs no-plan-file-premise-description"
fi
if $r13_ok; then
  pass "TC-R13: review skill plan mode premise updated (no Cycle doc dependency, plan file 前提 documented)"
else
  fail "TC-R13: violations:$r13_msgs"
fi

# TC-R14: agents/architect.md — 転記欠落=BLOCK / scope実質変更=再承認 / 観察のみ=DISCOVERED の3分岐
echo ""
echo "TC-R14: agents/architect.md — 3-branch charter (転記欠落=BLOCK / 再承認 / 観察のみ=DISCOVERED)"
ARCHITECT_MD="$BASE/agents/architect.md"
r14_ok=true
r14_msgs=""
grep -qF "転記欠落" "$ARCHITECT_MD" || { r14_ok=false; r14_msgs="$r14_msgs no-転記欠落"; }
grep -qF "再承認" "$ARCHITECT_MD" || { r14_ok=false; r14_msgs="$r14_msgs no-再承認"; }
grep -qF "観察のみ" "$ARCHITECT_MD" || { r14_ok=false; r14_msgs="$r14_msgs no-観察のみ"; }
if $r14_ok; then
  pass "TC-R14: architect.md has all 3 branches"
else
  fail "TC-R14: architect.md missing:$r14_msgs"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
