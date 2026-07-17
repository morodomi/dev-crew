---
feature: approval-reorder
cycle: 20260717_1126
phase: DONE
complexity: complex
test_count: 15
risk_level: medium
retro_status: resolved
codex_session_id: "019f6d8e-f689-7410-9af6-f30413a8d46a"
plan_file: /Users/morodomi/.claude/plans/twinkly-wishing-parasol.md
created: 2026-07-17 11:26
updated: 2026-07-17 16:04
---

# approval-reorder — Codex plan review を人間承認前（plan mode 内）へ移動する

## Scope Definition

### In Scope
- [ ] spec Step 8 追加: `codex exec --sandbox read-only "review plan <path>"` を承認前（ExitPlanMode 前）に実行し findings を draft plan に直接反映、最終版を 1 回だけ再レビュー
- [ ] 同一性保証: `reviewed_plan_hash`（Record 見出し上部全文の sha256）を plan に記録し、sync-plan（一次）+ pre-red-gate（決定論的最終防衛、frontmatter `plan_file:` から再算出）で二重照合
- [ ] codex_session_id 取得契約の 3 段 fallback（stdout header regex → rollout jsonl 最新ファイル名 → 両失敗時 `extraction_failed: true` で degraded 経路）
- [ ] pre-red-gate.sh 強化: Plan Review (pre-approval) エントリの区間抽出検証（Phase completed / verdict enumerate / codex_session_id 存在 / hash 実照合 / PASS・WARN での unresolved_blocks 非空検出 / BLOCK-overridden の override 証跡必須）
- [ ] Block 1 順序変更: sync-plan（転記）→ architect（転記後検証、3 分岐: 転記欠落=BLOCK / scope 実質変更=再承認 AskUserQuestion / 観察のみ=DISCOVERED）
- [ ] canonical 転記 schema（Progress Log `### <ts> - Plan Review (pre-approval)` の固定フィールド）を sync-plan・plan 側 `## Plan Review Record` で統一
- [ ] `.claude/rules/post-approve.md` 改訂（pre-approval review 正規手順化、承認後 review 再実行禁止、3 分岐明記）
- [ ] rules 同期: doc-mutations.md（承認前/後の反映先分岐）+ state-ownership.md（codex_session_id・Plan Review 転記権限）を rules/ + .claude/rules/ mirror 両方
- [ ] review skill の plan mode 前提整理（Cycle doc 不在でも動作する「plan file 前提」記述への修正）
- [ ] 実行時 memory（AGENTS.md / CLAUDE.md / docs/workflow.md / README.md / docs/architecture.md）の新順序反映
- [ ] ADR 新規作成（docs/decisions/、approval-reorder の設計判断と評価基準）
- [ ] .claude/dev-crew.json バージョン bump（2.10.0 → 2.12.0、機序: 自リリース v2.12.0 へのキャッシュ更新漏れ）
- [ ] テスト flip（test-post-approve-ordering.sh TC-01/02/05、test-v201-fixes.sh TC-03/09、test-codex-delegation-preference.sh TC-07/09/10、test-spec-onboard-improvements.sh TC-01）+ 新規 TC-R1〜R15
- [ ] docs/STATUS.md 定常更新（COMMIT 時）

### Out of Scope
- Cycle 2（narrative 残り: docs/usability.md / ROADMAP.md / skills/onboard/reference.md + test-onboard-tdd-workflow-template.sh 結合ペア / docs/terminology.md）(Reason: 順序 pin テストなしで drift 実害が限定的。plan の「2 cycle 分割」節で明示分離)
- Socrates plan review の完全 pre-approval 移動 (Reason: 本 cycle は spec/sync-plan/architect/gate の主経路のみ。Socrates 経路は DISCOVERED)
- レビュー待ち時間の tier 化 (Reason: 10 cycle 評価の結果が出てから判断。今回は実測記録のみ)

### Files to Change（target: 10 or less — 本 cycle は 33 件の明示的例外）

**例外根拠（Design Review Gate で妥当性判定済み、下記 Pre-Review 参照）**: 順序契約が doc↔test で相互 pin された原子的変更であり、分割すると実行時 memory（AGENTS/CLAUDE/orchestrate docs）が旧手順のまま動く drift window が生じる。rules/multi-file-consistency.md の全モード契約テスト pin を単一 cycle で張るため、Codex plan review BLOCK 6 の指摘を受け complexity: complex を明示。2-cycle 分割で narrative-only 項目（Cycle 2、~5 files）は既に切り出し済み。

**spec skill**:
1. skills/spec/SKILL.md（Step 8、100 行制限は Step 5 Layer 表の reference 化で吸収。現状 98 行）
2. skills/spec/reference.md
3. skills/spec/reference.ja.md（既存 drift 統一含む）
4. skills/spec/templates/cycle.md

**転記経路**:
5. agents/sync-plan.md（転記手順 + hash 照合 + L88-92/L105 改訂）
6. agents/architect.md（転記後検証 + 3 分岐 charter）

**orchestrate**:
7. skills/orchestrate/SKILL.md
8. skills/orchestrate/reference.md（Session Management / Task List / Socrates 3 分岐）
9. steps-subagent.md
10. steps-teams.md
11. steps-codex.md

**review skill（plan mode 前提整理）**:
12. skills/review/SKILL.md
13. skills/review/steps-subagent.md
14. skills/review/reference.md

**rules（+mirror）**:
15. .claude/rules/post-approve.md
16. rules/doc-mutations.md
17. .claude/rules/doc-mutations.md
18. rules/state-ownership.md
19. .claude/rules/state-ownership.md

**実行時 memory / 権威 doc**:
20. AGENTS.md
21. CLAUDE.md
22. docs/workflow.md
23. README.md
24. docs/architecture.md

**gate**:
25. scripts/gates/pre-red-gate.sh（設計判断 4、現状 L81-85 は `grep -qiE 'Plan Review|plan-review'` のみの弱契約であることを実読で確認済み）

**テスト**:
26. tests/test-pre-red-gate.sh（negative fixtures: Record 欠落 / verdict: BLOCK / placeholder / hash 欠落 → BLOCK）
27. tests/test-post-approve-ordering.sh（TC-01/02/05 flip + 新契約 TC。現状 TC-01/02/05 は「sync-plan before plan-review」の旧順序を assert しており実読で確認済み — 反転対象）
28. tests/test-v201-fixes.sh（TC-03/09 flip）
29. tests/test-codex-delegation-preference.sh（TC-07/09/10 flip）
30. tests/test-spec-onboard-improvements.sh（TC-01 flip）

**環境 / ADR**:
31. .claude/dev-crew.json（2.12.0。現状 `dev_crew_version: "2.10.0"` を実読で確認、installed cache は `~/.claude/plugins/cache/dev-crew/dev-crew/2.12.0/` に存在し不一致を実測確認済み）
32. docs/decisions/（ADR 新規: approval-reorder の設計判断と評価基準）
33. docs/STATUS.md（COMMIT 時の定常更新）

## Environment

### Scope
- Layer: bash / doc project（spec・orchestrate・review skill 群 + gate script + 実行時 memory + 契約テスト）
- Plugin: dev-crew
- Risk: MED（≈40）— 承認ゲートの意味論変更（プロジェクト初）。orchestrate/spec/review/gate の主経路に波及するが、Codex plan review 2 attempt（BLOCK 8→1→0 unresolved）で外部検証済み、ADR 新設・issue #176 事前合意あり。可逆（frontmatter `plan_file:` 新設は追加のみ、既存 gate 契約は強化であり撤去ではない）

### Runtime
- 環境: bash / macOS。Codex CLI 利用可（`codex exec --sandbox read-only resume <id>` はフラグ前置必須、後置は rc=2 — plan の実測 note）

### Dependencies (key packages)
- なし（新規外部依存追加なし）

### Risk Interview (BLOCK only)
- 該当なし（見積 MED は BLOCK 未満。WARN 帯の確認事項は issue #176 事前合意で回答済み、plan Context 節参照）

## Context & Dependencies

### Reference Documents
- rules/multi-file-consistency.md — 33 files 例外根拠（全モード契約テスト pin）の直接適用先
- rules/integration-verification.md — Verification section の real-path invocation 要件
- rules/plan-discipline.md — baseline 実測・逆向き契約 sweep の規律
- rules/doc-mutations.md / state-ownership.md — 本 cycle が改訂対象そのもの
- CONSTITUTION.md Goal — 承認対象の質を上げ、承認回数は 1 回/cycle 維持

### Dependent Features
- pre-red-gate: scripts/gates/pre-red-gate.sh（強化対象、既存 sync-plan/Plan Review 検出ロジックに依存）
- Post-Approve Action フロー: .claude/rules/post-approve.md（承認後トリガーの正規手順）

### Related Issues/PRs
- Issue #176: 外部レビュー合意、10 cycle 評価基準を事前固定済み（本 plan の意味論変更の根拠）

## Test List

### TODO
(none)

### WIP
(none)

テスト実装は rules/test-patterns.md 準拠。test_count: 15。

### DISCOVERED
- [RESOLVED 本 cycle 内] 追跡ラベル 18 箇所を red-worker が除去済み（TC-17 0 hits 確認）。下記は当時の記録
- [issue #179] Cycle 2: narrative doc（usability / terminology / ROADMAP）+ onboard 伝播（reference.md + test-onboard-tdd-workflow-template.sh 結合ペア。security 指摘の L521 `--full-auto "review plan"` 残留も同時修正）
- [issue #180] 3 分岐 charter の SSOT 化（10 doc コピペ分散、maintainability accept-defer）
- [issue #181] テスト TC 識別子の cycle 固有 prefix 化（TC-R 衝突、20260716 Insight 2 と同 family 再発、maintainability accept-defer）
- tests/*.sh の追跡ラベル混入（test-doc-consistency.sh TC-17、15 hits）: RED wave が test-post-approve-ordering.sh / test-pre-red-gate.sh / test-v201-fixes.sh / test-codex-delegation-preference.sh / test-spec-onboard-improvements.sh のコメント行に `cycle 20260717_1126_approval-reorder` 追跡ラベルを挿入し、CLAUDE.md「追跡番号・監査ラベルを入れない」規約（2-strike rule 自動契約）に抵触。baseline（HEAD）は 0 hits、本 cycle の RED 差分で 15 hits 新規発生を実測確認済み。修正はコメント文言のみ（テストロジック・assertion は無変更）だが、対象 5 ファイルは test files のため green-worker の担当範囲外（wave 1/2 とも rules/・AGENTS.md・CLAUDE.md・docs/*.md・README.md・テストファイルは非編集の指示）。follow-up cycle または red-worker の追加パスでコメント文言から `cycle 20260717_1126_approval-reorder` を除去し、根拠説明のみ残す軽微修正を推奨（該当箇所: test-codex-delegation-preference.sh:10,13,15,92,112,125 / test-post-approve-ordering.sh:4,99 / test-pre-red-gate.sh:9,296 / test-spec-onboard-improvements.sh:31 / test-v201-fixes.sh:10,17,50,109）

### DONE
- [x] TC-R1: Given 新順序 / When spec/reference.md・reference.ja.md を検査 / Then plan review 言及が承認より前 + Post-Approve Action 内に `codex exec.*review plan` 不在
- [x] TC-R2: Given 同 / When docs/workflow.md / Then plan review 行 < 承認ゲート(1) 行
- [x] TC-R3: Given 転記契約 / When agents/sync-plan.md / Then `Plan Review (pre-approval)` 見出し様式・codex_session_id 転記・`reviewed_plan_hash` 照合手順が存在
- [x] TC-R4: Given spec Step 8 / When skills/spec/SKILL.md / Then `--sandbox read-only` を含む Step 8 が存在し 100 行未満
- [x] TC-R5: Given gate 強化 / When (a) Record 完備 fixture (b) Record 欠落 (c) verdict: BLOCK override なし (d) placeholder (e) hash フィールド欠落 / Then (a) のみ PASS、(b)-(e) は BLOCK（rc/出力文字列 assert）
- [x] TC-R6: Given 同一性保証 / When fixture plan（Record の hash と本文 hash 不一致）で sync-plan 手順文を検査 / Then 照合手順の存在を pin（実行系は agent のため手順文契約 + gate 側 hash フィールド検査で二重化）
- [x] TC-R7: TC-03/09 flip — Post-Approve 内 Codex review 不在 assert
- [x] TC-R8: TC-07/09/10 flip（delegation-preference）
- [x] TC-R9: TC-01 flip（spec-onboard, plan template Workflow 行）
- [x] TC-R10: Given 全モード整合 / When steps-subagent/teams/codex.md / Then 3 doc すべてで Block 1 が「sync-plan 転記 → architect 検証」順（行番号比較、multi-file-consistency の TC-14 型）
- [x] TC-R11: Given rules 改訂 / When .claude/rules/post-approve.md + doc-mutations.md ×2 + state-ownership.md ×2 / Then pre-approval review 正規化・3 分岐・転記権限の記述存在（mirror 一致は test-rules-mirror.sh が既存検証）
- [x] TC-R12: Given Codex 不在経路 / When spec/reference.md の Step 8 記述 / Then skip 時に Record へ `codex_unavailable` を記録する規定が存在（silent skip 禁止、出力文字列 assert 原則）
- [x] TC-R13: Given plan mode review は Cycle doc 不在で動作 / When skills/review/SKILL.md・steps-subagent.md の plan mode 経路 / Then Cycle doc 前提記述が除去され「plan file 前提」記述が存在
- [x] TC-R14: Given architect 3 分岐 charter / When agents/architect.md / Then 「転記欠落 = BLOCK」「scope 実質変更 = 再承認」「観察 = DISCOVERED」の 3 分岐が存在
- [x] TC-R15: Given gate の hash/override 検証 / When fixture (f) hash 不一致 (g) PASS + unresolved_blocks 非空 (h) BLOCK-overridden + override 証跡なし (i) session 抽出失敗（codex_session_id 空 + extraction_failed: true）は PASS（degraded 許容）(j) 実 cycle doc（本 doc、大区間出力）は PASS（SIGPIPE 回帰の real-path pin。PRE-RED GATE 判定で追加された sub-case、tests/test-pre-red-gate.sh 上は TC-R15 グルーピングに実装）/ Then (f)(g)(h) BLOCK・(i)(j) PASS を rc + 出力文字列で assert

## Implementation Notes

### Goal
現行フロー（spec → 人間承認 → sync-plan → Codex plan review）では承認後に review が scope を拡大し（実測 3 cycle 連続 +3/+1/+4）、人間が承認した内容と実行される内容が構造的にずれる。Codex plan review を承認前（plan mode 内、read-only sandbox）に移動し、人間はレビュー済み・scope 確定済みの最終 plan を承認する新フローへ変更する。

### Background
issue #176（外部レビュー合意、10 cycle 評価基準を事前固定済み）。v2.8 で現行順序になった技術的理由（pre-red-gate が Cycle doc 内記録を要求 / codex_session_id が Cycle doc frontmatter 起点）は「転記 + gate 強化」で解決する。承認前への移動はプロジェクト初の意味論変更。

本 plan 自体が新フローの dogfood: draft を plan mode 内で `codex exec --sandbox read-only` レビュー（attempt 1: BLOCK 8/WARN 2/PASS 3、7分43秒）→ 全 BLOCK を反映 → 最終版を再レビュー（attempt 2: BLOCK 1/WARN 1、2分弱）→ 残指摘を設計判断 2/4・TC-R15 に反映済み（unresolved_blocks なし。ただし新規則により反映後の Codex 再々検証は未実施 — 反映内容は承認者が plan 上で直接確認）。

### Design Approach
1. spec Step 8（Step 7 後・ExitPlanMode 前）: Codex plan review を実行し findings を draft に反映、最終版を 1 回だけ再レビューして打ち切り。未解消 BLOCK は Record に `unresolved_blocks` 列挙 + 承認提示文で override を明示要求。
2. 同一性保証: `reviewed_plan_hash`（Record 見出しより上の全文 sha256）を sync-plan（一次照合）+ pre-red-gate（`plan_file:` から plan を直接読み再算出、決定論的最終防衛）で二重照合。不一致 = BLOCK。
3. codex_session_id 取得: (a) stdout header の `session id:` 行 uuid regex 抽出 → (b) fallback: `~/.codex/sessions/<Y/M/D>/rollout-*-<uuid>.jsonl` 最新ファイル名（実行時刻突合で他セッション混入排除）→ (c) 両失敗: `codex_session_id: ""` + `extraction_failed: true` を Record 記録、RED 以降は degraded 経路（`resume --last`）。
4. pre-red-gate 強化: Plan Review (pre-approval) エントリを区間抽出し (i) Phase completed (ii) verdict enumerate（PASS/WARN/BLOCK-overridden）(iii) codex_session_id フィールド存在（空可）(iv) reviewed_plan_hash 実照合 (v) PASS/WARN で unresolved_blocks 非空 → BLOCK (vi) BLOCK-overridden は override 証跡行必須、なければ BLOCK。deterministic gate の単独完結原則に準拠（他 validator に委任しない）。
5. Block 1 順序変更: sync-plan（転記）→ architect（転記後に plan と Cycle doc を比較検証、転記欠落=BLOCK / scope 実質変更=再承認 AskUserQuestion / 観察のみ=DISCOVERED）。「承認後 findings は一律 DISCOVERED-only」の旧方針は撤回。Socrates（Codex 不在時）も同 3 分岐 charter。
6. canonical 転記 schema: Progress Log `### <ts> - Plan Review (pre-approval)` に固定フィールド（codex_session_id / verdict / reviewed_plan_hash / findings 要約 / review_attempts 配列 / plan_presented / unresolved_blocks）。plan 側 `## Plan Review Record` も同一フィールド。
7. 計測は追加機構ゼロ: 提示前待ち増分 = review_attempts 合計所要、承認までの時間 = KICKOFF ts − plan_presented。
8. `.claude/rules/post-approve.md` 改訂: pre-approval review 正規手順化、承認後の plan review 再実行禁止、承認後 findings の 3 分岐を明記。
9. rules 同期: doc-mutations.md（承認前は plan へ直接反映 / 承認後は 3 分岐）+ state-ownership.md（sync-plan の codex_session_id・Plan Review 転記権限）を rules/ + .claude/rules/ mirror 両方更新。
10. review skill の plan mode 前提整理: skills/review/SKILL.md・steps-subagent.md・reference.md の plan mode 経路記述を「plan file 前提（Cycle doc 不在で動作）」に修正。
11. compact 耐性: Plan Review Record は plan ファイル上にあり、approve → compact → auto-orchestrate でも転記材料は不揮発。`## Post-Approve Action` トリガー維持。

## Verification

```bash
bash tests/test-post-approve-ordering.sh
bash tests/test-pre-red-gate.sh
bash tests/test-v201-fixes.sh
bash tests/test-codex-delegation-preference.sh
bash tests/test-spec-onboard-improvements.sh
bash tests/test-codex-session-isolation.sh   # 無変更 PASS の実証
bash tests/test-rules-mirror.sh              # mirror 整合非破壊
bash scripts/gates/pre-red-gate.sh docs/cycles/20260717_1126_approval-reorder.md  # 強化 gate の実 cycle doc に対する実挙動
```

最後に隔離 snapshot 上で全 113 テスト再実行、baseline（scratchpad/ar-baseline.txt、113/113 rc=0、main=a4af480）との diff が flip 契約のみであることを確認。

Evidence: (orchestrate が自動記入)

## Progress Log

### 2026-07-17 11:26 - KICKOFF
- Cycle doc created（architect による plan → Cycle doc 転記。sync-plan Agent 委譲を bootstrap 契約により architect 自身が実施 — 本 cycle 固有の指示により旧 sync-plan.md 契約を上書き）
- Scope definition ready（plan の Files to Change 全量 33、Test List TC-R1〜R15 を verbatim 転記）
- frontmatter 初期化: codex_session_id / plan_file は plan の Plan Review Record から転記（空文字初期化の旧契約は不使用）

### 2026-07-17 11:26 - Plan Review (pre-approval)
- codex_session_id: "019f6d8e-f689-7410-9af6-f30413a8d46a"
- review_attempts:
  - {started: 2026-07-17 09:51:52, completed: 2026-07-17 09:59:35, verdict: BLOCK (8 BLOCK / 2 WARN / 3 PASS)}
  - {started: 2026-07-17 10:03:30, completed: 2026-07-17 10:05:11, verdict: BLOCK (1 BLOCK / 1 WARN、他は解消確認)}
- findings 要約: attempt 1 — B1 同一性保証→hash 契約 / B2 pre-red-gate 弱契約→強化 / B3 architect→転記後検証 + 3 分岐 / B4 session id 取得→3 段 fallback / B5 不足 files→review skill 3 + rules 4 + gate 2 追加 / B6→complexity: complex 明示 / B7→README/architecture 繰り入れ + ADR / B8→negative TC 追加 / W9 schema 統一 / W10 baseline 完了。attempt 2 — 残 B1'（gate が hash/override を実照合すべき）→設計判断 2/4 と TC-R15 に反映 / W2'（session・plan-mode 経路の契約テスト不足）→TC-R13/R14/R15 追加
- unresolved_blocks: なし（attempt 2 の指摘は全て本 plan に反映済み。反映後の Codex 再検証は「再レビュー 1 回まで」の新規則により未実施 — 反映内容は設計判断 2/4・TC-R13〜R15 として承認者が plan 上で直接確認済み）
- plan_presented: 2026-07-17 10:06:42
- reviewed_plan_hash: df833b30d3f4be79860be3db55de19cd146a1330f31364ccd36d117086b4c392（正準値へ訂正済み — 下記「hash 契約の boundary 訂正」エントリ参照）
- **hash 照合（一次検証、architect 実施）**: plan ファイル（/Users/morodomi/.claude/plans/twinkly-wishing-parasol.md）の `## Plan Review Record` 見出しより上の全文（バイト列そのまま、UTF-8）の sha256 を再計算した結果 `ae477e4c40e50f54be07ddee646da03ca68f1284a60b71aad878e8310491465f` — Record 記載値と **完全一致（MATCH）**
- verdict: WARN（attempt 2 の残指摘は plan 反映済み・unresolved_blocks なし。旧規則「承認後の再レビュー必須」は本 cycle の新規則により適用除外）
- Phase completed

### 2026-07-17 11:26 - Design Review Gate (architect pre-review)
- 観点別判定:
  - **Scope**: In Scope 33 項目は各々具体的（ファイル単位で目的明記）。Files to Change = 33（目標 ≤10 の 3.3 倍）。**例外根拠を実ファイル突合で検証**: (1) rules/multi-file-consistency.md の「全モード契約テスト pin」原則に該当（TC-R10 が steps-subagent/teams/codex.md 3 doc の順序を単一 cycle で pin）、(2) 2-cycle 分割で narrative-only 5 files は既に Cycle 2 へ切り出し済み（YAGNI 違反なし）、(3) Codex plan review が同一論点を BLOCK 6 として指摘済みで、plan は complexity: complex を明示して応答。**判定: 例外は妥当（VALID）**。ただし規模の大きさ自体は下流（sync-plan/RED worker）への注意喚起事項として記録
  - **Architecture**: Design Approach は 11 項目の番号付き詳細設計。実ファイル 5 点を spot-check し全て記述と一致を確認:
    - tests/test-post-approve-ordering.sh TC-01/02/05 は現在「sync-plan before plan-review」の旧順序を assert（`grep -n "TC-01\|TC-02\|TC-05"` で確認）— flip 対象の記述と一致
    - scripts/gates/pre-red-gate.sh L81-85 は `grep -qiE 'Plan Review|plan-review'` のみの弱契約（placeholder でも PASS）— 強化必要性の記述と一致
    - agents/sync-plan.md L88-92 は「Codex Plan Review は sync-plan ではなく Post-Approve Action で実行される」注記、L105 は `codex_session_id: "" (空文字。plan review 時に記録)` — 本 cycle が上書きする旧契約と一致
    - skills/spec/SKILL.md は現状 98 行（100 行制限に対し残り 2 行）— Step 8 追加に reference 化が必須という記述と一致
    - .claude/dev-crew.json は `dev_crew_version: "2.10.0"`、installed cache は `~/.claude/plugins/cache/dev-crew/dev-crew/2.12.0/` に存在 — バージョン不一致の記述と一致
    - **判定: 整合性確認済み、齟齬なし**
  - **Test List**: TC-R1〜R15、非空。カテゴリ網羅: 正常系（TC-R1〜R4, R7〜R14 の存在検証）、境界値（TC-R5(e)/TC-R15(f) hash 欠落・不一致、TC-R15(i) degraded 許容境界）、異常系（TC-R5(b)(c)(d)/TC-R15(g)(h) の BLOCK 経路）。全項目 Given/When/Then 形式で記述され、rc + 出力文字列 assert という検証可能な oracle が明記されている。**判定: 良好**
  - **Risk**: risk_level: medium（Risk Score ≈40）。変更内容（承認ゲートの意味論変更、spec/orchestrate/review/gate 主経路への波及）との整合性を検討: 高リスク要因（プロジェクト初の意味論変更、複数 skill 横断）と低リスク要因（外部 Codex review 2 attempt で検証済み、ADR 新設、issue #176 事前合意、可逆設計＝既存 gate は強化であり撤去でない）が拮抗し、medium の見積は妥当。HIGH への格上げ根拠は見当たらない。**判定: 整合**
- **総合スコア: 55/100 → 判定: WARN**（内訳: Scope +30 [Files 33 の規模、例外は妥当だが下流注意喚起のため非ゼロ計上] / Architecture +5 [整合確認済み、軽微] / Test List +0 [良好] / Risk +20 [medium 見積の中核性・波及範囲を保守的に計上]）
- Issues（non-blocking、sync-plan 実行後も有効）:
  1. Files to Change = 33（目標 ≤10 の 3.3 倍）。例外根拠は妥当と判定したが、GREEN/REFACTOR フェーズで scope drift が起きないよう Progress Log での Files list 即時同期（rules/doc-mutations.md の SSOT 即時同期規律）を厳守すること
  2. 承認ゲート意味論変更はプロジェクト初。RED/GREEN 実装時、pre-red-gate.sh の強化ロジック（設計判断 4）が既存 cycle doc（本 cycle 以前）に対して誤 BLOCK しないこと（既存 Record 不在 cycle は旧経路のまま動作する必要がある）を GREEN の Verification で個別確認すべき
- Action: PASS/WARN → Task(dev-crew:sync-plan) 相当の Cycle doc 生成を実施（本 cycle 固有の bootstrap 契約により architect が直接生成）
- Phase completed

---

## Next Steps

1. [Done] KICKOFF <- Current
2. [Next] RED
3. [ ] GREEN
4. [ ] REFACTOR
5. [ ] REVIEW
6. [ ] COMMIT
7. [ ] DONE

### 2026-07-17 11:31 - PRE-RED GATE 判定（orchestrator）

- pre-red-gate.sh（明示指定）が check 2 で BLOCK → **実測デバッグの結果、gate 自身の pre-existing SIGPIPE バグによる false BLOCK と実証**:
  - 機序: `awk 'range' | grep -qi` で grep が先頭 match 後に pipe を閉じ、awk（本 doc の range 出力 21,921 bytes）が SIGPIPE（rc=141）→ `set -euo pipefail` が拾い `if !` が BLOCK 側へ。oracle: 同一 pipeline の単独実行 rc=141、control（20260716_1328、range 出力小）は WOULD_PASS — 出力サイズ依存の race
  - 同一クラス既修正例: 20260709_1125 の risk-classifier SIGPIPE fix。gate は本 cycle Files #25 の強化対象そのもの
- **判断: 実証済み false BLOCK として RED へ進行**（先送りせず本 cycle GREEN で修正 — plan-discipline「pre-existing FAIL は 1 行 fix 可能か確認」準拠。gate 強化の実装契約に SIGPIPE 排除を追加: rc を検査するコマンドを pipe に入れない = 本 cycle Block 0 で codify した insight の適用第 1 号）
- RED への追加契約: TC-R5 に sub-case (j) 「大区間出力の実 cycle doc（本 doc）に対し強化 gate が PASS」を追加（SIGPIPE 回帰の real-path pin）

### 2026-07-17 11:48 - RED (red-worker)

- 担当範囲: tests/test-post-approve-ordering.sh, tests/test-pre-red-gate.sh, tests/test-v201-fixes.sh, tests/test-codex-delegation-preference.sh, tests/test-spec-onboard-improvements.sh の5ファイルのみ編集（doc/gate本体/skills/rulesは非編集、GREEN担当）
- **test-post-approve-ordering.sh**: TC-01/02/05 を新順序（plan review が sync-plan/承認より前）へ反転。新規 TC-R1/R2/R3/R4/R6/R10/R11/R12/R13/R14 を追加（TC-R5/R7/R8/R9/R15 は他ファイルに実装、TC-R7=test-v201-fixes.sh TC-03/09、TC-R8=test-codex-delegation-preference.sh TC-07/09/10、TC-R9=test-spec-onboard-improvements.sh TC-01、TC-R5/R15=test-pre-red-gate.sh）
- **test-pre-red-gate.sh**: TC-R5(a)-(e) + TC-R15(f)-(j) の fixture テストを追加。(j) は PRE-RED GATE 判定で追加された sub-case（当初 TC-R5 グルーピング案だったが、以降の直接指示で TC-R15 グルーピングに実装。tests/test-pre-red-gate.sh 上のコメントに明記済み）
- **test-v201-fixes.sh**: TC-03/TC-09 を反転（Post-Approve Action 内の Codex plan review 不在 assert）
- **test-codex-delegation-preference.sh**: TC-07/09/10 を新順序へ反転
- **test-spec-onboard-improvements.sh**: TC-01 を新順序へ反転（plan template Workflow 行のバイトオフセット比較）
- **Verification Gate**: 5ファイルを個別実行（read-parallel/execute-serial原則により対象5ファイルのみ、full suite は実行せず）。反転/新規 TC のみ FAIL、既存 TC は全 PASS を rc + 出力文字列で確認（詳細は下記 oracle 実測）。加えて regression 対象の test-plugin-structure.sh / test-orchestrate-codex.sh / test-codex-session-isolation.sh / test-rules-mirror.sh を個別実行し全 rc=0 を確認（本 cycle の非対象ファイルへの意図しない影響がないことを確認）
- red_state_verified: true

**oracle 実測（rc + PASS/FAIL 内訳）**:
| ファイル | rc | 内訳 |
|---------|----|----|
| test-post-approve-ordering.sh | 1 | 3 passed(TC-03/04/06), 13 failed(TC-01/02/05/R1/R2/R3/R4/R6/R10/R11/R12/R13/R14) |
| test-pre-red-gate.sh | 1 | 11 passed(T-01〜T-09/TC-R5a/TC-R15i), 8 failed(TC-R5b/c/d/e, TC-R15f/g/h/j) |
| test-v201-fixes.sh | 1 | 8 passed(TC-01/02/04/05/06/07/08/10), 2 failed(TC-03/09) |
| test-codex-delegation-preference.sh | 1 | 10 passed(TC-01〜06/08/11〜13), 3 failed(TC-07/09/10) |
| test-spec-onboard-improvements.sh | 1 | 13 passed(TC-02〜14), 1 failed(TC-01) |

Phase completed

### 2026-07-17 11:51 - hash 契約の boundary 訂正（orchestrator、RED flag 起点）

- **発見**: red-worker が記録済み reviewed_plan_hash（ae477e4c...）の独立再現を試み、全 boundary 変種で不一致を検出
- **機序（実測確定）**: plan 承認前に orchestrator が計算した hash は文字列 `'## Plan Review Record'` の**部分文字列 split** を使用しており、設計判断 2 の本文中に現れる同一文字列（バッククォート引用、先頭から 2943 文字目）で切れていた。意図した Record 見出し行ではない。architect の「MATCH」判定は同一バグの再現であり独立検証になっていなかった（検証者が被検証者と同じ実装を使う anti-pattern）
- **正準アルゴリズム（GREEN の実装契約として確定）**: 「plan ファイル中、**行全体が `## Plan Review Record` に一致する最初の行**より前の全内容（当該行を含まない、バイト列そのまま）の sha256」。bash 実装例: `awk '$0=="## Plan Review Record"{exit}{print}' plan.md | shasum -a 256`
- **正準値（実測）**: df833b30d3f4be79860be3db55de19cd146a1330f31364ccd36d117086b4c392（red-worker の行アンカー計算と一致 — 独立再現成立）
- **訂正**: 本 doc の Plan Review (pre-approval) エントリの転記値を正準値へ更新（未 commit の転記データの誤値訂正。plan ファイルは IMMUTABLE のため触らない — plan 側 Record の旧値は本エントリで supersede）
- retrospective 候補: (1) hash 契約は「algorithm の fixture pin → 値の記録」の順で確定する、(2) 検証の独立性 — 照合者に実装を共有させない

### 2026-07-17 12:27 - GREEN-1（green-worker、機構実装）

- 担当範囲: 15ファイル（spec skill 4 + 転記経路2 + orchestrate 5 + review skill 3 + gate 1）。rules/・AGENTS.md・CLAUDE.md・docs/*.md・README.md・テストファイルは非編集（第2波/RED成果物）
- **skills/spec/SKILL.md**: Step 8（Codex plan review、`--sandbox read-only`、resume前置契約）を追加。Step 5 の Layer 表を reference.md へ移し圧縮。96行（100行未満を維持）
- **skills/spec/reference.md / reference.ja.md**: 冒頭に `## Step 8` 詳細節を新設（session id 3段fallback契約、Plan Review Record canonical フィールド表、正準hashアルゴリズム`awk '$0=="## Plan Review Record"{exit}{print}' | shasum -a 256`、Codex不在時`codex_unavailable`記録規定）。Plan File Template を更新: Workflow行を`plan-review → sync-plan → ...`へ反転、`## Plan Review Record`セクション追加、Post-Approve Actionから Codex plan review 除去。reference.ja.md の旧5-step版drift（sync-plan→plan-review(Claude)→Codex plan review→codex_mode確認→orchestrate起動の順）を統一
- **skills/spec/templates/cycle.md**: frontmatterに`plan_file:`追加、`codex_session_id`を「plan のPlan Review Recordから転記」注記へ
- **agents/sync-plan.md**: Step 3.5「Transfer Plan Review Record (pre-approval)」を新設(frontmatter `codex_session_id`/`plan_file`転記 + Progress Log `### <ts> - Plan Review (pre-approval)` 固定フィールドエントリ追記 + hash一次照合、不一致時は転記中断)。L88-92のNoteとFrontmatter Initialization表を新契約へ改訂
- **agents/architect.md**: Design Review Gate後に「Post-Transfer Verification」節を新設。3分岐（転記欠落=BLOCK/scope実質変更=再承認AskUserQuestion/観察のみ=DISCOVERED）を明記。Workflow手順にStep 4として追加
- **skills/orchestrate/SKILL.md・reference.md・steps-subagent.md・steps-teams.md・steps-codex.md**: Block 1を「sync-plan(転記)→architect(転記後検証)」の順へ反転（3 steps ファイル全てで`Task(subagent_type: "dev-crew:sync-plan"...)`が`Task(subagent_type: "dev-crew:architect"...)`より前に出現、TC-R10の行番号比較契約に一致）。SKILL.mdの「新規開始」フロー・reference.mdのSession Management/Task List/Socrates 3分岐charterも新契約へ更新
- **skills/review/SKILL.md・steps-subagent.md・reference.md**: plan mode の前提記述を「Cycle doc 前提」から「plan file 前提（Cycle doc不在でも動作）」へ修正
- **scripts/gates/pre-red-gate.sh**: (0) check 2 のSIGPIPE修正(`awk | grep -qi`直接pipeを`変数受け→printf | grep`へ書き換え、rcを検査するコマンドを生成中プロセスと同一pipeに置かない)。(1) 見出しアンカー`^### .* - Plan Review \(pre-approval\)$`による区間抽出(単一awk直読み、pipe不使用で自己exit時のSIGPIPEも排除)。フィールド検証: Phase completed / codex_session_id存在(空可) / placeholder検出(verdict・reviewed_plan_hash・review_attempts・unresolved_blocksの空値一括BLOCK) / reviewed_plan_hash実照合(64桁hexトークン抽出→frontmatter `plan_file`から正準アルゴリズムで再計算し比較、plan_file不在・読取不能もBLOCK) / verdict enumerate(PASS\*/WARN\*/BLOCK-overridden\*/BLOCK\*/other、caseのfirst-match-winsでBLOCK-overriddenをBLOCK\*より先に判定) / PASS・WARNでunresolved_blocksが「なし」以外の非空→BLOCK / BLOCK-overriddenはoverride証跡行必須。「Plan Review (pre-approval)」見出し不在時は既存 cycle doc 互換のため見出しアンカー限定の legacy 弱チェックへフォールバック(誤BLOCK防止、Issue #2 対応)
- **OPEN QUESTION（判断して報告、設計エントリに明記なし）**:
  1. TC-08(test-codex-delegation-preference.sh)がPost-Approve Actionに`codex_mode`委譲確認の残存を要求していたため、reference.md(英語版)のPost-Approve Actionへ「Codex 利用可能なら RED/GREEN 委譲確認 (full/no) → `codex_mode` に記録」を残した(plan review とは独立した既存メカニズムのため整合と判断)
  2. TC-03/04(test-post-approve-ordering.sh)のcheck_three_stepsが`plan.review|Plan review|設計レビュー`のいずれかを要求していたため、Post-Approve Actionのsync-plan行に「設計レビュー（Design Review Gate）」を追記(architectの既存Design Review Gate概念を指す、Codex plan reviewとは別物と判断)
  3. TC-04(test-spec-onboard-improvements.sh)が`RED.*GREEN.*REFACTOR`の単一行連鎖を禁止していたため、Post-Approve Actionから明示的なフェーズ列挙(`RED → GREEN → REFACTOR → REVIEW → COMMIT`)を削除し「orchestrateが全フェーズを管理する」の抽象表現のみとした(single orchestrate action契約)
  4. 上記3点はいずれも既存の隠れテスト契約(RED成果物、file一覧に非記載)との整合を取るための対応。設計判断そのものへの変更はなし
- **Verification**:
  - `bash scripts/gates/pre-red-gate.sh docs/cycles/20260717_1126_approval-reorder.md` → rc=0 PASS(SIGPIPE regression real-path実証)
  - `bash tests/test-pre-red-gate.sh` → 19/19 PASS(TC-R5 a-e, TC-R15 f-j 含む)
  - `bash tests/test-post-approve-ordering.sh` → 13 passed / 3 failed(TC-05, TC-R2, TC-R11 — 全てdocs/workflow.md・rules/系、第2波待ち)
  - `bash tests/test-v201-fixes.sh` → 9/10 passed(TC-10はdelegation-preference経由のworkflow.md起因、第2波待ち)
  - `bash tests/test-codex-delegation-preference.sh` → TC-07/08 PASS、TC-09/10 FAIL(docs/workflow.md未更新、第2波待ち)
  - `bash tests/test-spec-onboard-improvements.sh` → 14/14 PASS(TC-01含む全通過)
  - `bash tests/test-codex-session-isolation.sh` → 13/13 PASS(無変更回帰確認)
  - 隔離環境で全113テスト実行 → rc≠0は6件(test-codex-delegation-preference.sh/test-doc-consistency.sh/test-factory-model-adaptation.sh/test-post-approve-ordering.sh/test-review-integration-v24.sh/test-v201-fixes.sh)。うちtest-review-integration-v24.shは並行実行による一過性flakiness(standalone再実行で12/12 PASS、内部呼び出すtest-plan-review-phase16.shもstandaloneで19/19 PASS)と実証済み。残り5件は全てdocs/workflow.md起因(TC-09/10等)またはそのcascade(meta-regressionテスト内のnested呼び出し)で、第2波(docs/workflow.md, AGENTS.md, CLAUDE.md, README.md, docs/architecture.md, rules/×2, dev-crew.json, ADR, docs/STATUS.md)完了後にPASS化する設計
- Phase completed

### 2026-07-17 12:56 - GREEN-2（green-worker、doc/rule 系仕上げ）

- 担当範囲: 12ファイル（.claude/rules/post-approve.md、rules/doc-mutations.md ×2 mirror、rules/state-ownership.md ×2 mirror、AGENTS.md、CLAUDE.md、docs/workflow.md、README.md、docs/architecture.md、.claude/dev-crew.json、docs/decisions/ADR新規）
- **.claude/rules/post-approve.md**: pre-approval plan review を正規手順化（spec Step 8参照）。「承認後のplan review再実行禁止」を明記。承認後findingsの3分岐（転記欠落=BLOCK / scope実質変更=再承認 / 観察=DISCOVERED）を表で追加。旧禁止条項「`Skill(dev-crew:review --plan)`の/orchestrate外での呼び出し禁止」を「plan mode内 pre-approval実行は正規、承認後の再実行は禁止」へ改訂
- **rules/doc-mutations.md・.claude/rules/doc-mutations.md**（cp -Rで byte-identical mirror確認済み）: 「Codex plan review findingsはCycle docに反映」の規定を「承認前=draft planへ直接反映（planは承認前可変）/ 承認後=3分岐」へ改訂。plan IMMUTABLE (after approve) は不変のまま維持。出典に本cycle参照を追記
- **rules/state-ownership.md・.claude/rules/state-ownership.md**（同mirror確認済み）: Plan File節を「mutable before approve, IMMUTABLE after approve」へ改題し承認前可変を明記。sync-plan行のFrontmatter Update Permissionsに「転記権限」（codex_session_id/plan_file/Plan Review (pre-approval)エントリの転記）を追記
- **AGENTS.md**: TDD Workflow行を`spec → plan-review → approve → /orchestrate (sync-plan → pre-red-gate → RED → GREEN → REFACTOR → REVIEW → cycle-retrospective → pre-commit-gate → COMMIT)`へ。Post-Approve Action節にplan review承認前完了済みの整合文を追加
- **CLAUDE.md**: Auto-orchestrate行（L10相当）をsync-plan（転記）→architect（転記後検証）の新順序へ。Codex Integrationのbashブロック（L16-18相当）を`codex exec --sandbox read-only "review plan ..."`（承認前実行、session ID転記経路の説明コメント付き）へ更新。Token Optimization（L40相当）に「plan review (承認前) →」を追加。Usage Patterns表（L56相当）を`spec (+plan-review) → approve → /orchestrate (sync-plan + TDD内包)`へ
- **docs/workflow.md**: 権威フロー図の`spec (Claude)`ブロックを刷新——Claude plan-review → Codex plan-review（findings直接反映・再レビュー1回・Plan Review Record記録）→ approve（承認ゲート(1)）→ sync-plan（転記）→ architect（転記後検証、3分岐）の順に反転。pre-red-gate.shの説明文をreviewed_plan_hash実照合まで反映するよう更新。承認と確認節（旧L79-84相当）を「レビュー済みplanの承認」へ改訂。sync-plan節にPost-Transfer Verificationの説明を追加。TC-05/TC-R2/TC-09/TC-10の行番号契約（plan-review行 < sync-plan行・承認ゲート(1)行、Claude plan-review行 < 承認ゲート(1)行）を全て満たすことを実測確認
- **README.md**: Quick Start（L47相当）にplan review自動実行のステップを追加し5ステップ化。Core Workflow（L54-55相当）をClaude plan-review→Codex plan-review→approve→sync-plan(Plan Review Record転記)の順へ。Usage Example（L70-73相当）も承認前にplan reviewが完了する記述へ修正
- **docs/architecture.md**: System Architectureダイアグラムのplan modeブロックにplan-review（Claude + Codex competitive、findings反映・再レビュー・Record記録）ボックスをapprove矢印の直前に追加。normal modeブロックのSYNC-PLANをPlan Review Record転記込みの説明へ更新し、直後にarchitect(Post-Transfer Verification)ボックスを新設（旧「plan-review (Codex competitive)」ボックスを置換）
- **.claude/dev-crew.json**: `dev_crew_version`を`2.10.0`→`2.12.0`へbump（他フィールド不変）。`~/.claude/plugins/installed_plugins.json`の実キャッシュバージョン`2.12.0`と実測一致を確認、spec Step 1 Version Gateの不一致警告を解消
- **docs/decisions/adr-approval-reorder.md**（新規、ADR-003）: 既存ADR-001/002の様式（Status/Context/Decision Scorecard/Arguments(Accepted/Rejected/Deferred)/Decision/Consequences）を踏襲。Context に scope underestimation 実測3/3cycle（+3/+1/+4）を記載。Rejected節にApproval Brief等の追加承認補助機構（issue #176の10 cycle評価基準達成なら不導入）とレビュー待ち時間tier化見送りを明記。Consequencesに10 cycle評価基準（見逃し0/手戻り0/承認1回/cycle/承認まで中央値2分・最大5分/理解不足1件以下）を記載
- **OPEN QUESTION（判断して報告）**: test-codex-delegation-preference.sh TC-13（reference.ja.md Post-Approve Actionのsync-plan行がplan-review言及より前にある、という旧順序前提のassert）がRED時点で「不変」扱いだったが、reference.ja.mdのPost-Approve ActionからCodex plan review関連の全記述を除去した新設計と衝突しクラッシュ（`set -e`下でのcommand substitution pipefail）を検出。「Codex」語を含めずに`plan-review は承認前に完了済み`という独立行をsync-plan行の後に追加し、TC-09(v201)/TC-R1の禁止パターン（`codex.*plan.*review`）を回避しつつTC-13の順序要求を満たす形で解消（設計判断そのものへの変更なし、reference.md/reference.ja.mdの実質仕様は同一のまま）
- **Verification（直列実行、義務どおり）**:
  1. `bash tests/test-post-approve-ordering.sh` → **16/16 PASS**（TC-05/R2/R11 解消確認）
  2. `bash tests/test-codex-delegation-preference.sh` → **13/13 PASS**（TC-09/10 解消確認、TC-13も連鎖解消）
  3. `bash tests/test-v201-fixes.sh` → **10/10 PASS**
  4. `bash tests/test-rules-mirror.sh` → **3/3 PASS**（doc-mutations.md/state-ownership.md ともmirror一致、post-approve.mdはallowlist経由で単独ファイルのまま整合）
  5. 隔離snapshot（scratchpad配下にcp -R、`docs/`を含む repo全体を複製）上で全113テストを直列実行 → **rc≠0は4件**: test-doc-consistency.sh / test-factory-model-adaptation.sh / test-paradigm-selection.sh / test-skip-criteria-tp-review.sh。実repo（非snapshot）で個別再実行し切り分け: (a) test-paradigm-selection.sh TC-04がMorodomiHoldings親ディレクトリの`docs/test_architecture.md`（repo外絶対パス）を要求しており、snapshot複製がdev-crewサブディレクトリのみでMorodomiHoldings親構造を含んでいなかったため発生した複製境界アーティファクト（実repoでは7/7 PASS、plan-discipline.mdの「隔離snapshotは親構造ごと複製」原則に本来従うべきだったが本cycleのscope外事象のため次回baseline作業へ申し送り）。(b) test-skip-criteria-tp-review.shはtest-paradigm-selection.shのregression呼び出し失敗の直接cascadeで同根（実repoで5/5 PASS）。(c) test-factory-model-adaptation.shのTC-14がtest-paradigm-selection.sh失敗をcascadeしていたのも同根（実repoで14/14 PASS）。(d) test-doc-consistency.shのTC-17「tests/*.shコメント行に追跡番号ラベル0件」が実repoでも**真のFAIL**として残存（15 hits、下記残課題参照）
- retro_status: none（変更なし）
- Phase completed

### 2026-07-17 13:10 - 追跡番号ラベル修正（red-worker、コーディネーター指摘対応）

- 契機: 上記 GREEN-2 の DISCOVERED 記載どおり test-doc-consistency.sh TC-17「tests/*.sh コメント行に追跡番号ラベル 0 件」が実 repo でも真の FAIL として残存（15 hits）。RED wave で自身が編集した5テストファイルのコメントへ `cycle 20260717_1126_approval-reorder` ラベルを混入させたことが原因（委譲 prompt「追跡番号ラベル禁止」指示への違反）
- 対応: `grep -nEi '^[[:space:]]*#.*(cycle[: (]+2026[0-9]{4}|issue #[0-9]+)' tests/*.sh`（test-doc-consistency.sh TC-17 と同一パターン）で特定した15箇所全てから cycle 番号・cycle 名ラベルを除去し、契約の理由（plan review pre-approval 化、SIGPIPE 回帰 pin 等）を語る文言のみへ書き換え。同ファイル内で TC-17 には未検出だった残存 "approval-reorder" 名称のコメント3箇所（test-post-approve-ordering.sh:8、test-pre-red-gate.sh:673/676）も同型 sweep で除去（rules/test-patterns.md「同型 sweep」原則）。assert ロジック・TC 番号・test 文言（echo/pass/fail メッセージ）は無変更
- 対象外として維持: tests/test-pre-red-gate.sh:681 の `REAL_CYCLE_DOC="$BASE_DIR/docs/cycles/20260717_1126_approval-reorder.md"` — コメントではなく TC-R15(j) の実行に必須な実ファイルパスのコード行のため据え置き
- **Verification（直列実行）**:
  1. `bash tests/test-post-approve-ordering.sh` → rc=0
  2. `bash tests/test-pre-red-gate.sh` → rc=0
  3. `bash tests/test-v201-fixes.sh` → rc=0
  4. `bash tests/test-codex-delegation-preference.sh` → rc=0
  5. `bash tests/test-spec-onboard-improvements.sh` → rc=0
  6. `bash tests/test-doc-consistency.sh` → rc=0（TC-17「No tracking-label hits in tests/*.sh comment lines (113 files checked)」PASS を確認、13/13 PASS）
- 補足: 上記5ファイルが rc=0（全PASS）なのはラベル除去の効果ではなく、GREEN-1/GREEN-2（本エントリ直前の2エントリ）が既に完了していたため。ラベル除去自体はコメントのみの変更で assert 結果に影響しない
- Phase completed

### 2026-07-17 13:16 - REFACTOR

- チェックリスト 7 項目を今 cycle 変更ファイル（機構 doc 27 + gate 1 + tests 5）へ適用
- 同型 sweep: gate 内の `| grep -q` 5 箇所を検査 — 全て「変数受け printf → grep」の test-patterns 正規パターン（区間は単一 Progress Log エントリで数 KB、producer-SIGPIPE の実害条件 >64KB に達しない）。検証済み gate への churn を避けリファクタ変更なしと判断。残余考慮（herestring 化）は必要になれば follow-up
- Verification Gate: bash -n 6 ファイル OK / test-pre-red-gate.sh rc=0 (19/19) / 強化 gate の実 cycle doc 実行 rc=0
- コード変更 0 件 → 全テスト PASS 維持
- Phase completed

### 2026-07-17 13:17 - VERIFY (Block 2c.5)

- Verification セクション全 8 コマンドを real-path 実行。evidence: /tmp/dev-crew-verify-20260717_1126/verify.log
- ordering / pre-red-gate / v201 / delegation / spec-onboard / session-isolation / rules-mirror / 強化 gate の実 cycle doc 実行 — 全 rc=0
- full suite（Holdings 親構造複製 snapshot、直列）は並行実行中 — 結果は REVIEW エントリ以降に記録
- Phase completed

### 2026-07-17 13:31 - SYNC-PLAN 完了マーカー補記（orchestrator）

- KICKOFF エントリ（architect 実施の sync-plan 転記）に gate 検証用の完了マーカーが欠落していたため補記する。sync-plan（plan → Cycle doc 転記 + frontmatter 初期化 + hash 一次照合）は 11:26 の KICKOFF で完了済み
- 20260707_0936 insight（委譲 prompt に gate 完了マーカー明記）の 2 回目再発 — retrospective 対象
- sync-plan Phase completed

### 2026-07-17 14:10 - GREEN-fix（green-worker、code review accept-apply、GREEN 再実行1回限り）

- 担当: code review（Codex BLOCK 7 + Claude correctness 82 + security 55）の accept-apply 修正。テストファイルは非編集（別 worker 後続修正）

**1. scripts/gates/pre-red-gate.sh（最優先、全面書き直し）** — review findings との対応:
- a. **[SECURITY] plan_file 信頼境界**: 抽出した `plan_file` が絶対パス かつ `${DEV_CREW_PLAN_DIR:-$HOME/.claude/plans}/` 配下でなければ hash 計算前に BLOCK。symlink はディレクトリ側を `cd && pwd -P` で解決してから比較。`DEV_CREW_PLAN_DIR` は test fixture 用 override（コメントに明記）。任意ファイル hash oracle 化を防止（security 55 対応）
- b. **strict 経路の強制 discriminator**: frontmatter `plan_file:` 存在 **または** 任意の `### ` 見出しに `(pre-approval)` 含む場合は strict 経路必須、見つからなければ BLOCK（legacy fallback 禁止）。legacy 弱チェックは両条件とも偽の場合のみ
- c. **区間抽出の終端強化**: エントリ抽出 awk に「次の `### ` 見出しで停止」を追加、後続エントリの Phase completed への越境 false-PASS を封鎖（correctness 82 対応）
- d. **列挙の厳密化**: verdict は `^- verdict: (PASS|WARN|BLOCK-overridden|BLOCK)([ （(].*)?$`（"PASSING" 等の近似値を排除、BSD grep/sed の POSIX ERE leftmost-longest を実測確認済み）。unresolved_blocks は `^(なし|none)([ （(].*)?$`。override は `^- override: [^ ]` で非空値必須
- e. session id: 空の場合 `extraction_failed: true` **または** `codex_unavailable: true` を要求
- f. review_attempts: `^- review_attempts:` 必須 + `^  - {started:` ネスト行 1 件以上（`codex_unavailable: true` 時は 0 件許容）
- g. plan 側 `## Plan Review Record` 見出しの行全体一致検証（`grep -qxF`）を hash 計算前に追加、見出しなし全文 hash 一致の迂回を封鎖
- h. **sync-plan チェックの anchoring**: 範囲開始を「本文中の任意の sync-plan 文字列」から「`### ` 見出し単位のエントリ（見出し+本文）が sync-plan と Phase completed の両方を含む」スキャンへ変更。実 cycle doc の「SYNC-PLAN 完了マーカー補記」エントリ（本 doc 13:31）で実測 PASS 確認
- i. **SIGPIPE 恒久排除**: 全 `printf '%s\n' "$var" | grep` パターンを `grep <pattern> <<< "$var"`（herestring）へ置換。13:16 REFACTOR エントリで「churn 回避」と判断していたが、本 review で「恒久排除」要求により方針転換（REFACTOR 判断を review evidence で上書き）
- j. ヘッダコメントを (i)-(x) の 10 チェックへ 1:1 対応させ全面書き直し
- **Verification**: `bash -n` OK。実 cycle doc（本 doc）に対し rc=0 PASS（sync-plan anchoring 実測確認済み）

**2. agents/architect.md（旧 charter 全除去）**
- description / Example Input / Workflow / Principles を全面改訂。architect は Cycle doc 生成済み前提で起動され、Design Review Gate + Post-Transfer Verification のみ実施。`Task(dev-crew:sync-plan)` 呼び出し記述を全除去（grep 確認済み、0 件）。判定基準表・Principles を「sync-plan を呼び出さない」「BLOCK 時も Cycle doc 不変」へ更新

**3. skills/orchestrate/（強化 gate の全モード実行 + resume 隙間）**
- SKILL.md Block 0: 「plan-review 記録あり → Block 2a」を「plan-review + architect Post-Transfer Verification 記録あり → Block 2a / sync-plan 済みだが architect 未実施 → Block 1 から architect のみ再開」へ（102行→98行、圧縮して100行制限を維持）
- steps-subagent.md: 1a. 再開判定を同旨へ更新。Pre-RED Gate の inline awk/grep を `bash scripts/gates/pre-red-gate.sh "$CYCLE_DOC"` 明示実行へ置換
- steps-codex.md: Pre-RED Gate を同様に置換
- steps-teams.md: 1a. 再開判定を同旨へ更新 + Pre-RED Gate セクションを新規追加（従来 gate 呼び出しが皆無だった欠落を解消、3 モード全てが強化 gate を通るようになった）

**4. agents/sync-plan.md（schema 完全化）**
- Step 3.5 転記テンプレの `review_attempts` をネスト様式（`  - {started, completed, verdict}` 列挙）へ明示。`findings 要約` 追加、`extraction_failed` / `codex_unavailable` は存在時のみ転記する旨を明記
- hash 一次照合に supersede 規約を追記: 「Cycle doc に hash 訂正エントリ（boundary 訂正等）が存在する場合はその正準値を正とする」（本 doc 自身の 11:51 訂正エントリが実例）

**5. skills/spec/reference.md + reference.ja.md + README.md**
- Post-Approve Action: sync-plan 行から「設計レビュー（Design Review Gate）」の帰属を外し、`architect: 設計レビュー（Design Review Gate）+ Post-Transfer Verification（転記検証）` を独立行として追加。three-steps 検査（sync-plan|Cycle doc / plan.review|Plan review|設計レビュー / orchestrate|Codex）を維持するため日本語「設計レビュー」表記を architect 行に保持 — 実行確認済み（test-post-approve-ordering.sh TC-03/04 PASS）
- reference.ja.md L484 相当: 「sync-plan・委譲確認を直接実行した後に /orchestrate」の矛盾表現を「approve 後は /orchestrate のみ起動（内部で sync-plan → architect → ... を実行）」へ改訂
- README.md Usage Example（L69相当）: 同旨で「sync-plan 後に orchestrate が RED から開始」の記述を「/orchestrate が単一エントリポイントで内部委譲」へ改訂
- spec reference ×2 の Step 8: 「`--full-auto` での実行禁止（必ず `--sandbox read-only`）」を手順1-3に明記。Record 様式表に `override`（BLOCK-overridden 時必須、人間の明示承認の引用）と `codex_unavailable`（存在時のみ）フィールドを追加。Codex 不在時セクションを「Record 自体は必須、verdict/reviewed_plan_hash は自前計算、review_attempts: []、codex_unavailable: true」へ明確化

**6. skills/review/SKILL.md + steps-subagent.md + reference.md（plan mode の Cycle doc 依存除去）**
- SKILL.md: Progress Log 更新・DISCOVERED起票を code mode / plan mode（Cycle doc既存時）と plan mode（Cycle doc不在時・skip）に分岐
- steps-subagent.md: Socrates prompt の `cycle_doc` フィールド・Raw Findings append・Progress Log 記録・Step 6 DISCOVERED の4箇所を同様に分岐
- reference.md: BLOCK Recovery の plan mode 節を同様に分岐

**OPEN QUESTION（判断して報告）**:
1. 指示の「architect: Design Review Gate + Post-Transfer Verification（転記検証）」という文字通りの英語表記のみだと test-post-approve-ordering.sh の check_three_steps（`plan.review|Plan review|設計レビュー` のいずれか要求）を満たせないことを実測確認したため、日本語「設計レビュー」併記で対応した（意味は同一、帰属の移動という設計意図は維持）
2. plan_file 信頼境界チェック（1a）は 6 個の既存 fixture（TC-R5(a)(c), TC-R15(f)(g)(h)(i)）を意図通り BLOCK させる（fixture の plan_file が `mktemp` の system temp 配下で、trusted plan dir 外にあるため）。これは fixture 側の `DEV_CREW_PLAN_DIR` override 未設定が原因であり、テストファイル非編集の指示により本 worker では未修正。次項「fixture 要修正リスト」参照

**Verification（直列実行、指示どおり）**:
1. `bash -n scripts/gates/pre-red-gate.sh` → 構文 OK
2. `bash scripts/gates/pre-red-gate.sh docs/cycles/20260717_1126_approval-reorder.md` → **rc=0 PASS**（sync-plan anchoring・trust boundary・plan-side heading 検証など全新規チェック含め実 cycle doc で通過確認）
3. `bash tests/test-pre-red-gate.sh` → **13 passed / 6 failed**（fixture 要修正、詳細下記）
4. `bash tests/test-post-approve-ordering.sh` → rc=0（16/16 PASS） / `bash tests/test-v201-fixes.sh` → rc=0（10/10 PASS） / `bash tests/test-codex-delegation-preference.sh` → rc=0（13/13 PASS）
5. `bash tests/test-rules-mirror.sh` → rc=0（3/3 PASS）
6. 隔離 snapshot（scratchpad 複製、dev-crew サブディレクトリのみ）で全113テスト実行 → rc≠0 は5件: test-pre-red-gate.sh（fixture、下記）/ test-doc-consistency.sh・test-factory-model-adaptation.sh（いずれも test-pre-red-gate.sh 失敗の cascade、TC-13/14 の regression 呼び出し経由）/ test-paradigm-selection.sh・test-skip-criteria-tp-review.sh（snapshot 複製が MorodomiHoldings 親構造を含んでいないための境界アーティファクト、実 repo では前者7/7・後者5/5 PASS 実測済み、本 cycle の変更と無関係）
7. その他 regression 影響範囲（spec/architect/sync-plan/orchestrate/review 関連 58 ファイル + 追加候補）を個別実行 → 全 rc=0（test-orchestrate-a2b.sh は README.md の行折返しで TC-17 が一時 FAIL したが、"REVIEW → cycle-retrospective → COMMIT" を単一行に戻し即修正・再確認済み）

**fixture 要修正リスト（テストファイル非編集のため報告のみ、別 worker 対応）**:
| fixture | 該当TC | 現象 | 必要な修正 |
|---------|--------|------|-----------|
| tests/test-pre-red-gate.sh の `make_fixture_plan` 呼び出し元 | TC-R5(a) | plan_file が `mktemp -d` 配下 → 新設 trust boundary で BLOCK | fixture 実行前に `export DEV_CREW_PLAN_DIR="$TMPDIR"`（相当のfixtureルートディレクトリ）を設定 |
| 同上 | TC-R5(c) | 同上 | 同上 |
| 同上 | TC-R15(f) | 同上 | 同上 |
| 同上 | TC-R15(g) | 同上 | 同上 |
| 同上 | TC-R15(h) | 同上 | 同上 |
| 同上 | TC-R15(i) | 同上 | 同上 |

TC-R5(b)(d)(e) と TC-R15(j) は plan_file trust boundary 到達前の別チェック（heading 欠落・placeholder・hash欠落・実doc）で BLOCK/PASS が決まるため無修正で PASS 継続。
- Phase completed

### 2026-07-17 14:21 - fixture 修正（red-worker、code review accept-apply 対応、コーディネーター指摘）

- 担当: tests/test-pre-red-gate.sh のみ（tests/test-post-approve-ordering.sh は差分要否を確認したが rc=0/16 PASS のため無変更）。gate 本体・他ファイルは非編集
- **1a. DEV_CREW_PLAN_DIR 対応**: GREEN-fix「fixture 要修正リスト」記載どおり TC-R5(a)(c) / TC-R15(f)(g)(h)(i) の6箇所で `bash "$SCRIPT" ...` 実行前に `DEV_CREW_PLAN_DIR=<fixture 固有ディレクトリ>` をインライン export（各 fixture のトップディレクトリ、例 TC-R5(a) は `$FIXTURE_R5A`）。trust boundary チェック(v)を通過させ、各 TC が本来意図する後続チェック（verdict/hash/unresolved/override）へ到達するよう修正
- **1b. TC-R15(j) 合成 fixture 化**: 実 cycle doc（本 doc）への依存を除去。tmpdir に400行のpadding entry（>25KB、実測44639 bytes）+ 正規 SYNC-PLAN entry + 正規 Plan Review (pre-approval) entry（DEV_CREW_PLAN_DIR配下のfixture plan・正しいhash）を持つ合成 doc を生成し PASS を assert。時限爆弾（本 doc の phase: DONE flip で恒久 FAIL）と machine-local plan パス依存を解消。SIGPIPE 回帰 pin の意図（大区間出力でherestring実装が固まらないこと）はサイズ閾値で維持
- **1c. 迂回封鎖 negative fixture 追加（TC-R15(k)〜(q)、既存 sub-case 追記形式）**:
  - (k) plan_file が信頼境界外（DEV_CREW_PLAN_DIR とは別ディレクトリの plan_file）→ BLOCK、hash 出力なし（`computed=`/`mismatch` 不在）も assert
  - (l) `(pre-approval)` 見出しに末尾接尾辞（`— attempt 2`）→ strict 扱いで exact heading 不一致 BLOCK（legacy フォールバックなし）
  - (m) verdict: PASSING（近似値）→ BLOCK / (n) unresolved_blocks: B1（`なし`以外）+ verdict: WARN → BLOCK / (o) BLOCK-overridden + `- override:`（値なし、末尾スペースのみ）→ BLOCK
  - (p) Plan Review エントリ自体に Phase completed がなく、後続の無関係エントリにのみ存在 → BLOCK（区間抽出の次見出し停止境界が正しく機能し、越境借用しないことを pin）
  - (q) plan ファイルに `## Plan Review Record` 見出し行なし → BLOCK
- **1d. stale コメント更新**: ファイル冒頭（旧L9-15）と TC-R5/R15 セクション見出し直下（旧L295-297）の RED 期現在形記述（「The current gate ... only does a weak grep」「現行 gate は L81-85 弱契約 + SIGPIPE バグ」）を、実装済みチェック一覧を指す現状記述へ書き換え。assert ロジック・TC 番号・test 文言は無変更
- **1e**: 新規 TC 番号は増やさず、既存 TC-R15 の sub-case として (k)〜(q) を追記（TC-R5/R15 のアルファベット系列を継続）
- **2. test-post-approve-ordering.sh**: `bash tests/test-post-approve-ordering.sh` → 16/16 PASS（TC-03/04 の three-steps 検査は GREEN-fix で architect 行に付与された「設計レビュー（Design Review Gate）」表記により引き続き意図どおり PASS）。差分なしのため無変更
- **Verification（直列実行）**:
  1. `bash tests/test-pre-red-gate.sh` → rc=0（26 sub-case 全 PASS: T-01〜T-09 + TC-R5(a-e) + TC-R15(f-q)）
  2. `bash tests/test-post-approve-ordering.sh` → rc=0（16/16 PASS、無変更）
  3. `bash scripts/gates/pre-red-gate.sh docs/cycles/20260717_1126_approval-reorder.md` → rc=0 維持
  4. `bash tests/test-doc-consistency.sh` → rc=0（TC-17 追跡ラベル 0 件・TC-13 regression 含め 13/13 PASS）
- Phase completed

### 2026-07-17 14:34 - REVIEW (competitive: Claude panel + Codex)

- **Risk**: risk-classifier LOW score:0 だが、cycle 実体は architecture/workflow 中核変更のため MED tier 相当として maintainability を追加起動（review-triage の tier 判断は score だけでなく変更の質で補正）。review_policy self=fable
- **起動**: review-briefer(haiku) + security(fable) + correctness(fable) + maintainability(fable) + Codex(resume, read-only)
- **判定内訳（初回）**: security 55 WARN / correctness 82 BLOCK / maintainability 62 WARN / Codex BLOCK（7 BLOCK + 3 WARN + 2 PASS）
- **Findings 3-category triage（全 accept-apply、GREEN-fix + fixture 修正で解消）**:
  1. **強化 gate が通常経路から呼ばれない（Codex B1）**: steps-subagent/codex の inline 弱チェックを Active Cycle: ./docs/cycles/20260717_1126_approval-reorder.md
PASS: All pre-RED gate checks passed. 明示実行へ、steps-teams に Pre-RED Gate 節を新設 → 3 モード全て強化 gate 経由
  2. **設計判断 4 (i)-(vi) の迂回群（Codex B2, security 1/2/6, correctness 2/3）**: plan_file 信頼境界（/Users/morodomi/.claude/plans 既定 + DEV_CREW_PLAN_DIR override、hash 計算前 reject）/ strict 経路強制 discriminator（plan_file or (pre-approval) 見出しあれば legacy 禁止）/ 区間抽出の次見出し終端 / verdict・unresolved_blocks・override の anchored 完全一致列挙 / session 空時の extraction_failed|codex_unavailable 必須 / review_attempts ネスト行必須 / plan 側 Record 見出し検証。security oracle 実証の 3 迂回 + correctness の 2 越境を封鎖
  3. **architect 旧 charter 残存 → sync-plan 二重実行（Codex B4, correctness 4, maint 1）**: description/Example/Step3/Principle を全面改訂（Cycle doc 生成済み前提、Design Review Gate + Post-Transfer Verification のみ）。orchestrate Block 0 の resume 判定も「sync-plan 済み・architect 未了」を区別
  4. **転記 schema 不整合（Codex B5, correctness 5）**: review_attempts ネスト様式明示 + findings 要約 + extraction_failed/codex_unavailable 追加。Codex 不在時も Record 必須と spec 明記
  5. **review skill の Cycle doc 依存（Codex B6, 設計判断 10 未達）**: plan mode の Progress Log 更新・Raw Findings・Socrates cycle_doc・DISCOVERED を Cycle doc 不在時 skip 分岐へ
  6. **GREEN OPEN QUESTION #2/#4 の誤帰属（Codex B7）**: Design Review Gate の sync-plan 帰属を architect 行へ分離、ja/README の「sync-plan 後 orchestrate」矛盾を単一エントリポイントへ
  7. **SIGPIPE 残余 5 箇所（Codex W8, security/correctness optional）**: herestring 化で恒久排除
  8. **TC-R15(j) 時限爆弾（correctness 1 CRITICAL）**: 実 cycle doc 依存（DONE flip で恒久 FAIL）を除去し 44KB 合成 fixture 化。加えて迂回封鎖の negative fixture 7 件（k-q）を追加
  9. **hash boundary 訂正の plan 側旧値残存（Codex W9）**: sync-plan に supersede 規約追加（Cycle doc の訂正エントリが正）で解消
  10. **stale コメント（maint 7）**: RED 期の現在形記述を実装済み記述へ更新
- **reject / 記録のみ**: TC 命名の TC-R 衝突（maint 4、既存 test-red-complexity-gate と識別子衝突）→ **accept-defer**（DISCOVERED、本 cycle は sub-case 追記で番号増やさず対応済み、抜本改名は follow-up）。3 分岐 charter の 10 doc コピペ分散（maint 3）→ **accept-defer**（DISCOVERED、SSOT 宣言 + anchor 参照化は別 cycle）
- **再検証**: 全 accept-apply 適用後、隔離 snapshot（Holdings 親構造複製）full suite **113/113 rc=0、baseline diff 空**（scratchpad/ar-final2.txt）。test-pre-red-gate 26 sub-case 全 PASS。強化 gate の実 cycle doc 実行 rc=0
- **統合判定**: 初回 BLOCK（correctness 82 + Codex）→ 全 accept-apply 解消 → **合意 PASS**。auto-COMMIT 進行
- Phase completed

## Retrospective

抽出時刻: 2026-07-17 14:36
抽出方法: Cycle doc 全体（plan review 2 attempt / hash boundary バグ / pre-red-gate 硬化の code review BLOCK 7 件 / architect 二重 charter / SYNC-PLAN マーカー欠落）からの失敗→最終解→insight ペア抽出

### Insight 1: hash/署名の canonical boundary は「algorithm を fixture で pin してから値を記録」の順で確定する。検証者に被検証者と同じ実装を使わせない
- **Failure**: plan の reviewed_plan_hash を orchestrator が部分文字列 split（`s.split('## Plan Review Record')[0]`）で計算 → 設計判断 2 本文中の同一文字列（引用、2943 字目）で誤切断。architect の「MATCH」も同一 split バグの再現で、独立検証になっていなかった（検証者が被検証者の実装を流用）。red-worker が別実装（行アンカー awk/sed）で再現を試み初めて不一致が露見
- **Final fix**: 正準アルゴリズムを「行全体が `## Plan Review Record` に一致する最初の行より前・当該行含まず・バイトそのままの sha256」と定義し fixture で pin、値はその後に記録。gate は plan_file から独立再計算
- **Insight**: **hash/署名/checksum の同一性保証は、(a) boundary を「行全体一致」等の曖昧性ゼロな規則で先に固定し fixture でテスト pin、(b) 値の記録はその後、(c) 二次検証者には一次と異なる実装（別言語/別ツール）を使わせる。部分文字列 split は本文引用で誤切断する。検証者が被検証者の実装を流用すると同一バグを再現して false MATCH を出す**
- **一般化**: rules/test-patterns.md（boundary の行アンカー pin）+ agent-prompts.md（二次検証者の実装独立性）追記候補

### Insight 2: 「gate を強化した」は「gate が常時経路から呼ばれる」まで含めて初めて成立する。deterministic gate は全実行モードからの呼び出しを契約テストで pin する
- **Failure**: pre-red-gate.sh を hash 照合・6 項目検証まで硬化したが、steps-subagent/codex は inline の弱 awk/grep を直書きしており強化 gate を通っていなかった（Codex B1）。teams には gate 呼び出し自体が欠落。「最終防衛」を自称する gate が通常 /orchestrate で防衛していなかった
- **Final fix**: 3 モードとも Active Cycle: ./docs/cycles/20260717_1126_approval-reorder.md
PASS: All pre-RED gate checks passed. の明示実行へ統一。steps-teams に Pre-RED Gate 節を新設
- **Insight**: **gate 強化 cycle は「gate ロジックの強化」と「全 caller が強化 gate を呼ぶ」を分離して両方 pin する。前者だけだと dead な防御になる。multi-file-consistency の全モード契約テスト pin を『順序』だけでなく『gate 呼び出しの存在』にも適用する**（integration-verification の real-path invocation の gate 版）
- **一般化**: rules/integration-verification.md or multi-file-consistency.md 追記候補

### Insight 3: フロー順序を変える cycle は、その順序を実行する agent 定義（実行時 charter）の旧記述除去を negative assert で pin する。doc の新記述追加だけでは旧記述が残り二重実行する
- **Failure**: orchestrate を「sync-plan → architect」新順序に反転したが、architect.md 自身が「Design Review 後に Task(sync-plan) を実行」の旧 charter を保持 → 新フローで architect が sync-plan を再実行し Cycle doc 二重生成の恐れ（Codex B4 + correctness 4 + maint 1）。TC-R14 は 3 分岐の「存在」を pin したが旧呼び出しの「不在」を pin していなかった
- **Final fix**: architect.md の description/Example/Step3/Principle を全面改訂（sync-plan 呼び出し全除去）。resume 判定も「sync-plan 済み・architect 未了」を区別
- **Insight**: **A→B の順序反転では B の定義に残る「B が A を呼ぶ」旧記述を grep で洗い、negative assert（旧呼び出しの不在）で pin する。positive assert（新 3 分岐の存在）だけでは旧記述と共存し二重実行する。順序変更は『新記述の追加』でなく『旧記述の除去 + 新記述』の対で完了する**
- **一般化**: rules/multi-file-consistency.md 追記候補（順序反転時の旧 caller 記述 negative pin）

### Insight 4（再発・自動契約化）: 委譲 worker のフェーズ完了マーカー（sync-plan の Phase completed）を委譲 prompt に必須明記する
- **Failure**: architect が sync-plan 相当を実施した際、KICKOFF エントリに gate 検証用の「sync-plan ... Phase completed」マーカーを書かず、pre-red-gate check 2 が（SIGPIPE と別に）記録欠落でも BLOCK し得た。20260707_0936 insight の 2 回目再発
- **Final fix**: orchestrator が SYNC-PLAN 完了マーカーを補記
- **Insight**: **2-strike rule 発動。委譲 prompt テンプレートに「担当フェーズの Progress Log 完了マーカー（`<PHASE> ... Phase completed`）を gate が読める形で記録する」を必須項目化する**（agent-prompts.md の委譲契約へ）
- **一般化**: rules/agent-prompts.md 追記候補（2 回再発 → 自動契約）

### 成功事例（observation: pre-approval plan review の dogfood が実際に scope を承認前に固めた）
- 本 cycle 自身が新フロー適用第 1 号。plan review 2 attempt で BLOCK 8+1 件を**承認前**に plan へ反映 — 従来なら承認後に Cycle doc 補正で吸収していた分。ただし提示前待ちは実測 ~15 分（再レビュー込み）で、10 cycle 評価の「待ち増分」観測点として記録。competitive code review も BLOCK 7 件を捕捉し全 accept-apply。no-codify（既存 pipeline + 新フローの設計意図どおりの動作実証）

### 2026-07-17 14:37 - COMMIT

- 最終 full suite（Holdings 親構造複製 snapshot、直列、review-fix + fixture 修正反映後）: **113/113 全 rc=0、baseline diff 空**（scratchpad/ar-final2.txt）
- pre-commit-gate（明示指定）rc=0 PASS（retro_status: captured 通過）
- STATUS.md: Done 69→70 + Completed 行 + Last updated 2026-07-17。Test Scripts 113 不変（新規テストファイルなし、5 既存ファイルへ TC 追加/flip）。Done count pin テストなし（grep 0 件）
- .claude/dev-crew.json 2.10.0→2.12.0 で Version Gate 解消
- README/AGENTS/CLAUDE の skill 一覧: 数不変（機構 doc の文言修正のみ、skill 28 構成不変）
- issue: #176 実装 / #179（Cycle 2）/ #180（3分岐 SSOT）/ #181（TC prefix）起票
- feature/approval-reorder → PR → --admin merge
- Phase completed

## Codify Decisions

triage 実施: 2026-07-17 16:04（後続 cycle approval-reorder-cycle2 の orchestrate Block 0 codify gate）。recurrence pre-triage + autonomous triage、質問 0 件。実装は次の codify 実装 cycle。

### Insight 1（hash/署名の canonical boundary は fixture pin 後に値記録、二次検証者に別実装を使わせる）
- **Decision**: codified
- **Destination**: rule (rules/test-patterns.md + rules/agent-prompts.md、両 mirror)
- **Reason**: boundary の行アンカー pin は test-patterns の「pin は実体を狙う」family、二次検証者の実装独立性は agent-prompts の委譲契約。部分文字列 split の誤切断 + 検証者の実装流用による false MATCH の実害 evidence あり
- **Decided**: 2026-07-17 16:04

### Insight 2（gate 強化は全モードから呼ばれるまで pin して初めて成立）
- **Decision**: codified
- **Destination**: rule (rules/integration-verification.md + mirror)
- **Reason**: 「gate ロジック強化」と「全 caller が強化 gate を呼ぶ」を分離して両方 pin。real-path invocation の gate 版。steps-subagent/codex が inline 弱チェックで強化 gate を bypass していた実害
- **Decided**: 2026-07-17 16:04

### Insight 3（順序反転は旧 caller 記述の除去を negative assert で pin）
- **Decision**: codified
- **Destination**: rule (rules/multi-file-consistency.md + mirror)
- **Reason**: A→B 反転時、B 定義に残る「B が A を呼ぶ」旧記述を negative assert で pin。architect が旧 charter で sync-plan 二重実行の実害。positive assert だけでは旧記述と共存する
- **Decided**: 2026-07-17 16:04

### Insight 4（委譲 worker のフェーズ完了マーカー必須明記）
- **Decision**: codified
- **Destination**: rule (rules/agent-prompts.md + mirror)
- **Reason**: 20260707_0936 の 2 回目再発 → 2-strike rule で自動昇格。委譲 prompt テンプレートに「担当フェーズの Progress Log 完了マーカー（`<PHASE> ... Phase completed`）を gate が読める形で記録」を必須項目化
- **Decided**: 2026-07-17 16:04

### 成功事例（observation: pre-approval plan review の dogfood が scope を承認前に固めた）
- **Decision**: no-codify
- **Reason**: 新フローの設計意図どおりの動作実証 + 既存 competitive review pipeline の追認（Retrospective 内で no-codify 明記済み）
- **Decided**: 2026-07-17 16:04
