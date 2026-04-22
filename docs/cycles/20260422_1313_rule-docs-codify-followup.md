---
feature: rule-docs-codify-followup
cycle: follow-up-codify-23-insights
phase: REVIEW
complexity: standard
test_count: 10
risk_level: low
retro_status: captured
codex_session_id: "019db366-3682-7823-a9ee-978eee20bb0f"
created: 2026-04-22 13:13
updated: 2026-04-22 13:13
---

# Follow-up Cycle: codify→rule 23 insights を rule document 化 + skill-maker 強化

## Scope Definition

### In Scope
- [ ] `rules/test-patterns.md` 新規作成 (8 insights: testing pitfalls)
- [ ] `rules/plan-discipline.md` 新規作成 (7 insights: plan writing discipline)
- [ ] `rules/agent-prompts.md` 新規作成 (2 insights: agent prompt contracts)
- [ ] `rules/multi-file-consistency.md` 新規作成 (2 insights: multi-file mirror + gate defense)
- [ ] `rules/review-triage.md` 新規作成 (2 insights: review findings processing)
- [ ] `rules/doc-mutations.md` 新規作成 (2 insights: cycle doc / plan file discipline)
- [ ] `rules/skill-authoring.md` 新規作成 (2 insights: skill creation guidelines)
- [ ] `skills/skill-maker/reference.md` Validation Checklist に "Exit Contract" 項目追加 + cross-link
- [ ] `docs/STATUS.md` Test Scripts 107 → 108 更新
- [ ] `tests/test-codify-rule-docs.sh` 新規作成 (10 TCs)

### Out of Scope (Round 1 WARN 反映で明示的 rationale)
- **`.claude/rules/` mirror 作成**: 本 7 rules は **advisory documentation-only** (hook enforcement なし、human reader 向け reference)。`.claude/rules/` は現状 git-safety / git-conventions / security / post-approve を mirror しており、Claude 側での rule 可視化を提供しているが、本 cycle の 7 rules は Claude-side activation を直ちに必要としない (future: Claude に自動参照させたければ `.claude/rules/` へ追加する選択肢は残す、DISCOVERED 記録)
- `tests/test-skill-maker.sh` TC-20 追加 (別 cycle)
- `tests/test-rules-content.sh` 新設 (MVP scope 外)
- CLAUDE.md / AGENTS.md への新 rules 個別列挙 (existing convention 準拠)
- review skill 自体の Risk-based scaling 実装 (Cycle B #6, 別 cycle)
- rule enforcement hook 化 (documentation-only で開始)

### Files to Change (Final: 11 files — GREEN で collateral fix 1 件追加)
- `rules/test-patterns.md` (new)
- `rules/plan-discipline.md` (new)
- `rules/agent-prompts.md` (new)
- `rules/multi-file-consistency.md` (new)
- `rules/review-triage.md` (new)
- `rules/doc-mutations.md` (new)
- `rules/skill-authoring.md` (new)
- `skills/skill-maker/reference.md` (edit: Validation Checklist)
- `docs/STATUS.md` (edit: Test Scripts 107 → 108)
- `tests/test-codify-rule-docs.sh` (new)
- **`tests/test-codify-insight.sh`** (edit: TC-19 hardcoded 107 → 108 bump、GREEN phase collateral regression fix、Codex code review BLOCK #1 で SSOT 同期要求)

## Environment

### Scope
- Layer: Documentation + Test
- Plugin: dev-crew
- Risk: 25 (PASS)

### Runtime
- Language: bash (test script)

### Dependencies (key packages)
- (none — documentation only)

## Context & Dependencies

### Reference Documents
- `rules/state-ownership.md` — 既存 rule 書式の precedent
- `rules/git-safety.md` — 書式 precedent + hook linkage
- `docs/decisions/adr-cycle-retrospective.md` L77-91 — codify 実行の任意性
- `skills/codify-insight/SKILL.md` L60-72 — Exit Contract 参照実装
- `skills/skill-maker/reference.md` L296-333 — Validation Checklist 挿入点
- 6 cycle docs の `## Codify Decisions` section — 23 codified→rule insights の出典

### Dependent Features
- PR #130 (codify-insight): 23 insights の `Decision: codified, Destination: rule` 判定を前提

### Related Issues/PRs
- PR #130: codify 29 insights across 6 captured cycles (前提)

## Test List

### TODO
- [ ] TC-01: `rules/test-patterns.md` 存在 + H1 title 含 + 出典 cycle 引用 (≥1)
- [ ] TC-02: `rules/plan-discipline.md` 存在 + H1 + 出典引用 (≥2 — 複数 cycle 由来)
- [ ] TC-03: `rules/agent-prompts.md` 存在 + H1 + 出典引用 (≥1)
- [ ] TC-04: `rules/multi-file-consistency.md` 存在 + H1 + 出典引用 (≥1)
- [ ] TC-05: `rules/review-triage.md` 存在 + H1 + 出典引用 (≥1)
- [ ] TC-06: `rules/doc-mutations.md` 存在 + H1 + 出典引用 (≥1)
- [ ] TC-07: `rules/skill-authoring.md` 存在 + H1 + SKILL.md 100 行記述 + inter-skill exit contract 記述
- [ ] TC-08: 全 7 rule files のサイズが 200 bytes 以上
- [ ] TC-09: `skills/skill-maker/reference.md` Validation Checklist に "Exit Contract" 記述追加確認
- [ ] TC-10: `skills/skill-maker/reference.md` に `rules/skill-authoring.md` への cross-link 存在

### WIP
(none)

### DISCOVERED
- **`.claude/rules/` mirror 将来検討**: 本 cycle で追加する 7 rules を `.claude/rules/` にも mirror するか再評価する (Codex plan review round 1 WARN)。現状は advisory docs-only だが、Claude 自動参照を活かすなら mirror 価値あり。別 cycle で判断。

### DONE
(none)

## Implementation Notes

### Goal
先行 PR #130 で codify-insight skill が 29 insights を decide gate 処理し、23 件を `Decision: codified, Destination: rule` と判定した。本 cycle はその rule document 化を実施し、将来の cycle での同一失敗再発を防ぐ。

### Background
- ADR-002 L86「codify 実行は強制しない」の通り、判定記録のみで実際の rule document 化は follow-up 作業
- codify→skill (#3 inter-skill exit contract) も本 cycle で skill-maker reference.md に統合
- codify→new-cycle (#4 SKILL.md 100行制約 compress rule) も skill-authoring.md に統合

### Design Approach
**Rule 書式** (既存 state-ownership.md / git-safety.md precedent 準拠):
- H1 title + 1-2 sentence 概要
- `## 禁止事項` / `## 推奨` / `## 具体例` / `## 出典` セクション構成
- YAML frontmatter なし
- 500-1500 bytes target
- 日本語 + 英語 mixed
- コードブロック積極活用 (bash/markdown patterns)

**7 clusters**:
1. `test-patterns.md` — 8 insights (testing/bash pitfalls)
2. `plan-discipline.md` — 7 insights (plan 作成規律)
3. `agent-prompts.md` — 2 insights (architect prompt contracts)
4. `multi-file-consistency.md` — 2 insights (並行実装一貫性)
5. `review-triage.md` — 2 insights (review findings 処理)
6. `doc-mutations.md` — 2 insights (Cycle doc / plan 不変性)
7. `skill-authoring.md` — 2 insights (SKILL.md 100行制約 + exit contract)

**eval-4 / Cycle B insights 自己適用**:
- eval-4 #2 (baseline 実測): `/tmp/followup-baseline.txt` で diff 比較 (Round 1 BLOCK 反映で refresh 済、@ main acb597f、107 tests / 9 FAIL)
- eval-4 #4 (新規 test → meta-doc sync): STATUS.md 107→108 を scope に含む (test-v2-release.sh TC-04 で regression catch)
- Cycle B #4 (Plan file IMMUTABLE): approve 後は plan file 編集不可、Cycle doc SSOT

## Verification

```bash
cd /Users/morodomi/Projects/MorodomiHoldings/agents/dev-crew

# 1. 新 test script PASS (10 TCs)
bash tests/test-codify-rule-docs.sh 2>&1 | tail -3

# 2. 既存 plugin structure test 回帰なし
bash tests/test-plugin-structure.sh 2>&1 | grep -E 'TC-04|Summary'

# 3. Full suite per-test 回帰 (baseline refreshed @ main 069ba68 / acb597f = post PR #130)
# Baseline: /tmp/followup-baseline.txt (107 tests / 9 FAIL / 98 PASS)
for f in tests/test-*.sh; do
  bash "$f" >/dev/null 2>&1
  rc=$?
  printf "%s rc=%d\n" "$(basename $f)" "$rc"
done | sort > /tmp/followup-after.txt
diff /tmp/followup-baseline.txt /tmp/followup-after.txt
# 期待: 差分は test-codify-rule-docs.sh rc=0 の 1 行追加のみ
# STATUS.md 107→108 更新で test-v2-release.sh TC-04 regression なし (既存 test が count sync を検出)

# 4. 新 rules/ .md count 確認
ls rules/*.md | wc -l
# 期待: 11 (4既存 + 7新規)

# 5. Rule file サイズ確認
wc -c rules/test-patterns.md rules/plan-discipline.md rules/agent-prompts.md \
      rules/multi-file-consistency.md rules/review-triage.md rules/doc-mutations.md \
      rules/skill-authoring.md
# 期待: 各 500-1500 bytes

# 6. skill-maker reference.md 更新確認
grep -c 'Exit Contract\|skill-authoring' skills/skill-maker/reference.md
# 期待: ≥ 2
```

Evidence: (orchestrate が自動記入)

## Progress Log

### 2026-04-22 13:13 - KICKOFF
- Cycle doc created from plan `/Users/morodomi/.claude/plans/eval-4-eval-3-crystalline-snowflake.md`
- Design Review Gate: PASS (score: 5) — 出典引用正確性が未検証 (軽微 WARN) のみ
- Scope: 10 files (7 new rules + 1 skill-maker edit + 1 STATUS.md edit + 1 new test script)
- Risk: 25 (PASS auto-proceed)
- Phase completed

### 2026-04-22 13:20 - CODEX_PLAN_REVIEW_R1 → BLOCK
- Codex plan review round 1 verdict: **BLOCK** (1 BLOCK + 3 WARN)
- BLOCK: `/tmp/cycle-b-baseline.txt` stale (106 entries、test-codify-insight.sh 不在)、現 repo 107 tests、diff 期待値違反
- WARN #1: `.claude/rules/` mirror 判断が convention 誤認 — onboard/commit が .claude/rules/ を管理、現状 3 rules (git-safety/git-conventions/security) が mirror 済。state-ownership のみを precedent にするのは不十分
- WARN #2: plan file 内で scope 8 vs 10 file ambiguity (plan file 内の 2 箇所で不整合、Cycle doc は 10 で正確)
- WARN #3: STATUS.md 専用 TC なし、test-v2-release.sh TC-04 で regression catch 済 (軽微)

### 2026-04-22 13:25 - CYCLE_DOC_SYNCED_WITH_CODEX_R1
- Baseline refresh: `/tmp/followup-baseline.txt` @ main acb597f (107 tests / 9 FAIL)
- Out of Scope に `.claude/rules/` mirror の明示的 rationale 追記 (advisory docs-only、Claude-side activation 不要)
- DISCOVERED に `.claude/rules/` mirror 将来検討を記録
- Verification section を baseline 更新 + STATUS.md regression rationale 追記
- Plan file は IMMUTABLE (state-ownership.md L7-10 遵守)、Cycle doc が SSOT
- Accept 判断 (Codex WARN 3-category triage):
  - BLOCK baseline stale: **ACCEPT・適用** (baseline 再測定)
  - WARN #1 .claude/rules/ mirror: **ACCEPT・明示記述** (docs-only 宣言 + DISCOVERED)
  - WARN #2 plan file ambiguity: **DEFER** (plan file IMMUTABLE、Cycle doc SSOT で代替)
  - WARN #3 STATUS.md TC: **ACCEPT・Verification 注記** (test-v2-release.sh で covered)
- Next: Codex plan review round 2

### 2026-04-22 13:32 - CODEX_PLAN_REVIEW_R2 → WARN → PASS
- Codex plan review round 2 verdict: **WARN** (軽微 1 件のみ、Round 1 BLOCK/WARN 全解消)
- 残 WARN: L130-133 の eval-4 #2 自己適用記述が古い baseline path (`/tmp/cycle-b-baseline.txt`) を引用、Verification (L146-155) は refreshed path 使用で矛盾
- 即 fix: L130-133 の baseline path を `/tmp/followup-baseline.txt` に更新、@ main acb597f 明記
- Codex session: 019db366-3682-7823-a9ee-978eee20bb0f
- Final verdict: **PASS** (全指摘反映、plan_review 完了)
- Next: Block 2a (RED)

## plan_review

- **Rounds**: 2 (Round 1 BLOCK → Round 2 WARN → fix → PASS)
- **Critical fixes**: baseline refresh (BLOCK #1), .claude/rules/ rationale 明示 (WARN #1), Cycle doc SSOT 宣言 (WARN #2 deferred plan file fix), STATUS.md TC coverage note (WARN #3)
- **Codex session**: 019db366-3682-7823-a9ee-978eee20bb0f
- **Final**: PASS (baseline refreshed, rationale explicit, regression covered via existing tests)

### 2026-04-22 13:45 - RED
- `tests/test-codify-rule-docs.sh` 新規作成 (10 TCs、red-worker 委譲)
- 実行結果: PASS 0 / FAIL 16 (TC-08 が 7 files 個別 = 16 fail カウント、論理 10 TCs 全 FAIL)
- Phase completed

### 2026-04-22 14:00 - GREEN
- 9 files 作成/編集 (green-worker 委譲):
  - 新規 7 rules (`rules/test-patterns.md` 2540b, `plan-discipline.md` 2185b, `skill-authoring.md` 1891b, `review-triage.md` 1577b, `agent-prompts.md` 1544b, `doc-mutations.md` 1486b, `multi-file-consistency.md` 1475b)
  - 編集 2: `skills/skill-maker/reference.md` Validation Checklist + `docs/STATUS.md` Test Scripts 107→108
- **自己適用失敗の再発**: STATUS.md Test Scripts 更新で `tests/test-codify-insight.sh` TC-19 (hardcoded 107) が regression。eval-4 #1 / Cycle B #2 で rule 化した「逆向きテスト契約 grep 事前検索」を本 cycle の plan 段階で怠った
- 修正: `tests/test-codify-insight.sh` L378-395 の 107 → 108 bump (scope +1 file)
- Verification: test-codify-rule-docs.sh 10/10, test-codify-insight.sh 20/20, test-v2-release.sh 8/8, test-plugin-structure.sh 6/6
- Baseline diff: 新 test rc=0 1 行追加のみ、9 pre-existing FAIL 不変
- Rule files 平均 1813 bytes (precedent state-ownership.md 1341b、1.35x だが consolidated insight 密度で妥当)
- Phase completed

### 2026-04-22 14:15 - REVIEW (competitive、self-applied review-triage.md rule)
- Risk Classifier: MEDIUM (score 50) → review-triage.md rule 自己適用: correctness + security + Codex (maintainability skip、LOW→MED+1 tier)
- Claude-side reviewers (parallel):
  - correctness-reviewer: blocking_score 22 (PASS)、important x 1 (multi-file-consistency.md L7-8 inline tag 誤り: `(eval-3 #3)` → 正しくは orchestrate-integration Insight 3)、optional x 1 (TC-08 fail count が TC 論理数と乖離)
  - security-reviewer: blocking_score 3 (PASS)、optional x 1 (`set -uo pipefail` → `-euo` 推奨)
- Codex code review (session 019db366): **BLOCK** (2 BLOCK + 1 WARN)
  - BLOCK #1: Cycle doc Files to Change が 10 files のまま、実際は test-codify-insight.sh 追加で 11 files、SSOT drift
  - BLOCK #2: review-triage.md Risk matrix が source 不正確 — eval-3 #3 は「Codex のみ」ではなく「Codex approve 一発時に correctness skip 可」、Cycle B #6 は LOW で 2 views + Codex と記載
  - WARN: tests/test-codify-rule-docs.sh TC-07 OR logic bug — `||` で command substitution 内両 grep が走ると count 2 行 (`0\n1`) で numeric compare fail、現状 skill-authoring.md が "100 行" 含むので第 1 grep が hit して問題顕在化せず
- review-triage.md rule 自己適用 (3-category triage):
  - **accept-apply** (4 件): Cycle doc Files sync (Codex BLOCK #1) / review-triage.md source fix (Codex BLOCK #2) / multi-file-consistency.md inline tag 修正 (Claude correctness) / TC-07 OR logic fix (Codex WARN)
  - **accept-defer** (0 件)
  - **reject** (2 件): TC-08 fail count 形式 (test-codify-insight.sh TC-18 と同 pattern で正しい仕様、出力 cosmetic)、`set -euo` (既存 test scripts も `-uo`、統一は別 cycle の style refactor)
- 修正後 target test 10/10 PASS 維持、test-codify-insight.sh 20/20 維持
- Aggregate verdict: **PASS** (Codex BLOCK 2 件全適用、correctness important 適用、WARN 適用、軽微 optional reject)
- Phase completed

### 2026-04-22 14:05 - REFACTOR
- チェックリスト全 7 項目評価:
  - 重複コード: 7 rule files cross-file duplication なし、各 insight は 1 rule のみに配置
  - 定数化/未使用 import/let→const/N+1: N/A (Markdown)
  - メソッド分割: rule file あたり 1475-2540 bytes、precedent (500-1400) 超過するが consolidated insight 密度 (1 file あたり 2-8 insights) で正当化
  - 命名一貫性: 全 kebab-case、suffix なし、既存 rules/ 準拠
- 追加変更なし判定
- Verification Gate: target 10/10, test-codify-insight 20/20, v2-release 8/8 再確認 PASS
- Phase completed

---

## Next Steps

1. [Done] KICKOFF
2. [Done] RED
3. [Done] GREEN
4. [Done] REFACTOR
5. [Done] REVIEW
6. [Next] COMMIT
7. [ ] DONE

## Retrospective

抽出時刻: 2026-04-22 14:30
抽出方法: Cycle doc 全体 (plan / 2 rounds plan review / RED / GREEN with collateral fix / REFACTOR / REVIEW with 3 reviewer findings) からの失敗→最終解→insight ペア抽出

### Insight 1: rule を作る cycle 自身が、その rule に従わない (自動化なき規律は破綻する)

- **Failure**: 本 cycle の目的は 23 insights を rule 化すること。その中心に eval-4 #1 / Cycle B #2「逆向きテスト契約 事前 grep」が含まれる。しかし GREEN phase で STATUS.md Test Scripts 107 → 108 に更新した際、`grep -rn "107" tests/` を実施せず、test-codify-insight.sh TC-19 (hardcoded 107) が regression。自分で作る rule document の中で最も強調される手順を、作成中の cycle で破った。
- **Final fix**: test-codify-insight.sh TC-19 を 108 に bump (scope +1 file = 11 files)。Cycle doc Files to Change list にも反映。
- **Insight**: **rule を「知っている」ことと「適用する」ことは別の discipline**。LLM による rule の自発適用は unreliable — 「記述しておけば従う」は幻想。plan phase の checklist に **自動化された grep コマンド literal** を組み込むのが本質的解決 (例: plan template に「count/state bump 時: `grep -rn "<old-value>" tests/` 実行結果を貼る」欄を必須化)。今後 `plan-discipline.md` に「自動化 grep literal を plan に貼る」を追加検討。
- **一般化**: rule の効力は「書いてあるか」ではなく「checklist に機械化されているか」に依存する。文書化は必要条件、自動化は十分条件。

### Insight 2: GREEN collateral fix は Cycle doc Files list を即時同期せよ

- **Failure**: GREEN phase で green-worker が 9 files 作成、直後に私 (orchestrator) が test-codify-insight.sh を collateral fix (scope +1)。しかし Cycle doc Files to Change list (10 files のまま) を更新しなかった。Codex code review で BLOCK「Cycle doc SSOT が implemented scope と不整合」。
- **Final fix**: Cycle doc Files list を 11 files に更新、REVIEW log に collateral fix 経緯明示。
- **Insight**: Cycle doc は cycle 進行中の SSOT (Cycle B #4)。**GREEN phase の collateral fix (scope +1) は検出した瞬間に Cycle doc Files list も同時更新する**。「GREEN 完了後まとめて更新」は drift を生む。orchestrator (PdM) の責務: scope 変更の瞬間に SSOT を sync する規律。将来 green-worker prompt に「collateral fix 発生時は file path を返却」を明示、orchestrate 側で Cycle doc 即時更新する運用を検討。
- **一般化**: SSOT 宣言は「片方向更新」の discipline を要求する (Cycle B #4)。更新タイミングを「フェーズ終了時」に遅延させると必ず drift する。**SSOT 更新は変更発生と同時**が正しい頻度。

### Insight 3: Rule content の source accuracy — insight 原文を一言でも改変するな

- **Failure**: review-triage.md の Risk matrix 初版で「LOW: Codex のみで OK」と記述。原典 eval-3 #3 は「trivial scope + Codex approve 一発時に correctness **skip 可**」であり「Codex のみ」とは言っていない。Cycle B #6 は「LOW: 2 views + Codex」と明記。私の generalize は 2 つの source を都合良く merge した改変だった。
- **Final fix**: review-triage.md Risk matrix を原典準拠に修正 (LOW: Codex + correctness + security = 3 views、trivial 案件のみ correctness skip 可)、両 source を `## 出典` に明示引用。
- **Insight**: codify で複数 insight を 1 rule に集約する時、**元の insight 文言を読み直さずに generalize する誘惑**がある。rule 草稿 → Codex review で原典照合は貴重な防御。対策: rule 作成時に **各 insight の該当 Cycle doc L## を引用として明示、generalize する場合は「なぜ generalize したか」を 1 行書く**。Codex 競合 review が原典照合を担うのは設計的に正しい。
- **一般化**: LLM は insight を generalize する時、source の niceness より自分の "clean statement" を優先する bias がある。Human + Codex の cross-check が必須。

### Insight 4: bash `$(cmd1 || cmd2)` は fallback でなく concatenation

- **Failure**: test-codify-rule-docs.sh TC-07 で `has_100line=$(grep -cF "A" || grep -ciE "B" || true)` と書いた。意図は「A が無ければ B を試す」。しかし command substitution 内の `||` は **exit code** の連鎖だが stdout は各 command で独立生成。第 1 grep が 0 件 match (count=0 出力 + exit 1) → 第 2 grep が 1 件 match (count=1 出力) → 合計 `0\n1` が変数に入り、後段 `[ "$var" -ge 1 ]` で `integer expression expected` エラー。現状 PASS してるのは skill-authoring.md が "100 行" を含み第 1 grep が short-circuit したため、英語 fallback path で顕在化する hidden bug。
- **Final fix**: `if ... then has_X=1; elif ... then has_X=1; else has_X=0; fi` で明示分岐に置換。
- **Insight**: **bash の `$(cmd1 || cmd2 || ...)` fallback pattern は dangerous**。pipefail と命令式評価の挙動が異なる。条件分岐は `if/elif/else` で明示する。`||` chain は exit code 短絡のみを期待する場面 (e.g. `cmd || true`) で使う。`test-patterns.md` cluster に「command substitution の `||` fallback pattern は dangerous」として追加候補。
- **一般化**: bash の value-based fallback は awk/shell関数で明示実装、`||` 短絡には頼らない。eval-3 #1 (pipefail + pipe + grep) と同系統の bash pitfall。

### Insight 5: Cycle 名称の informal 略称は混同源 — full cycle filename を使え

- **Failure**: multi-file-consistency.md の rule 本文 inline tag で `(eval-3 #3)` `(eval-3 #4)` と書いたが、eval-3 (= agents-md-count-fix) には Insight 4 が存在しない。実際の出典は v2.8-orchestrate-integration (A2b、非 eval-N 命名) Insights 3, 4。`## 出典` section は正しく引用していたが、本文 inline tag のみ取り違え。
- **Final fix**: inline tag を `(v2.8-orchestrate-integration Insight 3)` 等の full/公式名に修正。
- **Insight**: **eval-N は informal な cycle 識別子で、非 eval cycle (A2b 等) には適用できない**。rule 内の cycle 参照は **full filename prefix** (例: `v2.8-orchestrate-integration`) または **cycle_id frontmatter 値** を使う。informal 略称は cross-reference ノイズを生む。`rules/doc-mutations.md` または新規 `rules/cycle-naming.md` に「rule 内 cycle 参照は full filename or cycle_id のみ使用」を追加候補。
- **一般化**: cross-reference は絶対識別子で行う。「eval-X」「A2b」「Cycle B」のような informal label は会話では許容だが永続 artifact (rule/doc) では使わない。

### Insight 6 (observation、no-codify 候補): Self-apply 2nd-order dogfood の価値

- **Observation**: 本 cycle で review-triage.md rule を作成、同 cycle の REVIEW phase で自分自身に適用した (Risk MEDIUM → Claude correctness + security + Codex、maintainability skip)。rule 内容が「書いた通り機能するか」を作成 cycle 内で即時検証できる設計は効率的だった。
- **Final fix**: N/A (observation のみ)
- **Insight**: rule を新設する cycle で「その rule を即時 self-apply する」のは retrospective loop の 2nd-order dogfood として強力。ただし actionable rule ではなく pattern observation。Cycle B Insight 5 「dogfood evidence」と同系統の no-codify 候補。
- **一般化**: 2nd-order dogfood は rule 品質検証に寄与するが、rule 化して他 cycle に強制するものではない。
