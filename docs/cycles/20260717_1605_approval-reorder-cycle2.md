---
feature: approval-reorder-cycle2
cycle: 20260717_1605
phase: DONE
complexity: standard
test_count: 5
risk_level: medium
retro_status: resolved
codex_session_id: "019f6eb7-ba83-79c3-a452-e781392e2eb4"
plan_file: /Users/morodomi/.claude/plans/twinkly-wishing-parasol.md
created: 2026-07-17 16:06
updated: 2026-07-21 15:03
---

# approval-reorder Cycle 2 — narrative doc + onboard 伝播を新順序へ

## Scope Definition

### In Scope
- [ ] onboard テンプレートの本体一致（Codex BLOCK 2）: reference.md L410-430 の AGENTS.md テンプレートを、本体 `AGENTS.md` の該当区間と文言一致させる。正準: Workflow 行 = `spec → plan-review → approve → /orchestrate (sync-plan → pre-red-gate → RED → GREEN → REFACTOR → REVIEW → cycle-retrospective → pre-commit-gate → COMMIT)`（AGENTS.md L33 verbatim）/ Post-Approve Action ブロック = AGENTS.md の該当ブロック（「plan review は承認前の spec 内（Step 8）で完了済み」+「Edit/Write は /orchestrate に委譲」、旧「orchestrate が plan-review を実行」「review --plan を直接呼ぶな」を除去）/ L387 の「最新版判定」基準（`sync-plan → plan-review` を含むか）も新順序基準へ
- [ ] security 修正 両側（Codex BLOCK 3 + 再レビュー残 BLOCK）: L521 区間（Codex セッション作成の項）を read-only に統一 — 初回 `codex exec --sandbox read-only "review plan"` と再レビュー `codex exec --sandbox read-only resume <session-id>` の両方を read-only にし、L521 区間内に `--full-auto` を残さない。L511 汎用 `--full-auto`（別区間、非 review-plan 用途）は据え置き
- [ ] usability フロー図（Codex BLOCK 5 で INIT 整理は撤回）: L62-63 の Phase Transition フロー図の plan mode 区間に plan-review（承認前）を追加。INIT は現役用語（spec SKILL L10 / orchestrate reference L72 / architecture L20 で使用中）のため触らない。L118 の `review(plan)` は用語統一のため `plan-review` へ
- [ ] ROADMAP 現在地: 「現在地」に approval-reorder(#176、2026-07-17 実装) を反映。v2.8.0 行（L17）は歴史的記録として不変。doc-mutations の current-state whole-doc sweep で他節の旧状態記述も確認
- [ ] CHANGELOG（リリース準備）（Codex WARN 確定）: `## [Unreleased]` セクションを新設し approval-reorder エントリを追加、Breaking 明記（承認ゲートの意味論変更 = plan review が承認前へ / pre-red-gate が plan_file・Plan Review Record を要求 / spec Step 8 追加）。TC-C2-5 は当該 section 内限定で検査（過去エントリの偽 PASS 回避）。version bump・tag は本 cycle scope 外（release-skill 委譲、marketplace/plugin.json 不変）
- [ ] terminology: plan-review を正式 Phase 化しない（Naming Layers と整合、Codex PASS）。用語表に「plan-review = plan mode 内レビュー」の 1 行注記のみ（#179 の terminology 項目への最小対応）
- [ ] positive assert の精度（Codex PASS 指摘）: onboard テンプレート検査は whole-file grep でなく AGENTS.md テンプレート区間を抽出して完全一致（section_grep 型）

### Out of Scope
- #180 3分岐 charter の SSOT 化 (Reason: 別 cycle。本 cycle scope 外)
- #181 テスト TC-R 識別子の cycle 固有 prefix 化 (Reason: 別 cycle。本 cycle scope 外)
- reference.ja.md の TC-13 回避行（Cycle 1 の互換処置）の本格整理 (Reason: Cycle 1 の暫定処置の恒久対応であり本 cycle の narrative/onboard 伝播スコープ外)
- docs/architecture.md L102「review(plan) 廃止」表現の現行用語への平滑化 (Reason: 歴史記述だが紛らわしい、Codex WARN。本 cycle の逆向き契約 sweep では「変更しない」対象として除外理由を明記済み — 統一 review skill 化の設計進化記述であり現行 `review --plan` の否定ではない)

### Files to Change (target: 10 or less — 全量9)
1. `skills/onboard/reference.md` — L414 テンプレート + L418-430 Post-Approve ブロックを本体 AGENTS.md 一致へ / L387 判定基準 / L521 security 両側（L511 不変）
2. `tests/test-onboard-tdd-workflow-template.sh` — TC-01 順序 literal を新順序へ flip（区間抽出完全一致）+ TC-C2-2 負契約追加（`--full-auto "review plan"` 不在 / review plan 用 read-only 存在 / 汎用 L511 --full-auto 維持）
3. `docs/usability.md` — L62-63 フロー図に plan-review（承認前）追加、L118 を `plan-review` へ（INIT は不変）
4. `ROADMAP.md` — 現在地に approval-reorder(#176) 反映（whole-doc sweep）
5. `CHANGELOG.md` — `## [Unreleased]` 新設 + approval-reorder + Breaking 明記
6. `docs/terminology.md` — plan-review の 1 行注記（Phase 化しない）
7. `tests/test-doc-consistency.sh` — TC-C2-3/4/5 を追加（doc test 配置を本ファイルに確定。usability フロー / ROADMAP 現在地 #176 / CHANGELOG [Unreleased] approval-reorder+Breaking）
8. `docs/cycles/20260717_1605_approval-reorder-cycle2.md` — sync-plan 生成の Cycle doc
9. `docs/STATUS.md` — COMMIT 時定常更新（Done count / Completed 行）

## Environment

### Scope
- Layer: Docs/Process（dev-crew bash/doc project。Backend/Frontend の実行時コード変更なし、doc/skill/test の narrative 伝播のみ）
- Plugin: dev-crew（bash/doc project type、rules/integration-verification.md の "dev-crew 内 (bash/doc project)" 分類に該当）
- Risk: 40（medium）（Codex plan review 指摘で LOW→MEDIUM に訂正。risk-classifier: test file +10 / 5 file 超 +15 / docs・skills・tests の 3 ディレクトリ分散 +15 ≈ 40）

### Runtime
- Language: Bash / Markdown（dev-crew skill・test 記述規約。コンパイル対象ランタイムなし）

### Dependencies (key packages)
- N/A（bash/doc project。テストスクリプトは grep/awk/shasum 等の POSIX 標準ツールのみ使用、外部パッケージ依存なし）

### Risk Interview (BLOCK only)
- N/A — risk_level: medium（BLOCK ではない）。Risk Interview は未実施

## Context & Dependencies

### Reference Documents
- issue #179（Cycle 2 スコープ）
- `docs/cycles/20260717_1126_approval-reorder.md`（Cycle 1、DONE） - spec Step 8 / 転記契約 / gate 硬化が SSOT。narrative（本 cycle）はそれを参照する形に揃える

### Dependent Features
- approval-reorder Cycle 1（PR #182 merge）: 機構・実行時 memory・権威 doc（AGENTS/CLAUDE/workflow/README/architecture）は新順序へ更新済み

### Related Issues/PRs
- Issue #179: 残る narrative doc（usability / ROADMAP）と onboard 生成テンプレートを新順序へ揃える
- Issue #180（別 cycle、scope 外）: 3分岐 SSOT 化
- Issue #181（別 cycle、scope 外）: テスト TC-R 識別子の cycle 固有 prefix 化
- リリース準備: 本 cycle 完了後、CHANGELOG [Unreleased] が整った状態で release-skill により 2.13.0（minor + Breaking 明記）を切る想定。version bump/tag は本 cycle scope 外

## Test List

### TODO
(none)

### WIP
(none)

実装は rules/test-patterns.md 準拠（section_grep 区間抽出、単独 grep + rc 直取り、contiguous phrase、追跡ラベル禁止）。test_count: 5。

### DISCOVERED
(none)

### DONE
- [x] TC-C2-1 (test-onboard-tdd-workflow-template.sh TC-01 flip): Given onboard は新順序を配布 / When AGENTS.md テンプレート区間を抽出 / Then Workflow 行が本体 AGENTS.md L33 と完全一致（plan-review が sync-plan/approve より前）、旧 `sync-plan → plan-review` は不在
- [x] TC-C2-2 (test-onboard-tdd-workflow-template.sh 追加): Given L521 両側 read-only 化 / When reference.md の L521 区間（Codex セッション作成の項）を section 抽出 / Then (a) 初回 `codex exec --sandbox read-only "review plan"` が存在、(b) 再レビュー `codex exec --sandbox read-only resume` が存在、(c) 当該区間に `--full-auto` が不在、(d) 別区間の汎用 `codex exec --full-auto`（L511）は維持 — を個別 assert
- [x] TC-C2-3 (test-doc-consistency.sh 追加): Given usability は承認前 review を描く / When docs/usability.md の Phase Transition フロー図区間を抽出 / Then plan mode 区間に plan-review が approve より前に存在
- [x] TC-C2-4 (test-doc-consistency.sh 追加): Given ROADMAP 現在地は #176 反映済み / When ROADMAP.md 現在地節を抽出 / Then approval-reorder または #176 への言及が存在
- [x] TC-C2-5 (test-doc-consistency.sh 追加): Given CHANGELOG に approval-reorder / When CHANGELOG.md の `## [Unreleased]` section を抽出 / Then approval-reorder エントリと Breaking 記述が section 内に存在

## Implementation Notes

### Goal
approval-reorder Cycle 1（PR #182 merge）で機構・実行時 memory・権威 doc（AGENTS/CLAUDE/workflow/README/architecture）は「plan review を人間承認の前（plan mode 内）」の新順序へ更新済み。Cycle 2 は残る narrative doc（usability / ROADMAP）と onboard 生成テンプレートを新順序へ揃え、Cycle 1 で持ち越した drift を解消する（issue #179）。

### Background
`skills/onboard/reference.md` L410-430 は新規プロジェクトに配布される AGENTS.md テンプレートを含み、Workflow 行（L414）も Post-Approve Action ブロック（L418-430）も丸ごと旧構造（`spec → sync-plan → plan-review`、「orchestrate が plan-review を実行」「review --plan を直接呼ぶな」）。加えて L521 に `codex exec --full-auto "review plan"`（新正準 `--sandbox read-only` と矛盾、security review 指摘）。配布物の自己矛盾はリリース前に必須で解消する。

本 cycle 自身が新フローの dogfood 第 2 号（spec Step 8 で承認前 Codex plan review を実施、下記 Plan Review (pre-approval) エントリ参照）。

### Design Approach
Codex plan review BLOCK 1-5 反映済み（設計判断 1-7、Files to Change の各項目に対応）:
1. onboard テンプレートの本体一致（Codex BLOCK 2）: reference.md L410-430 の AGENTS.md テンプレートを、本体 `AGENTS.md` の該当区間と文言一致させる。正準は上記 In Scope 記載の Workflow 行・Post-Approve Action ブロック・L387 判定基準
2. security 修正 両側（Codex BLOCK 3 + 再レビュー残 BLOCK）: L521 区間を read-only に統一（初回・再レビュー resume の両方）。L511 汎用 `--full-auto` は据え置き
3. usability フロー図（Codex BLOCK 5 で INIT 整理は撤回）: L62-63 に plan-review（承認前）を追加。INIT は現役用語のため触らない。L118 は `plan-review` へ用語統一
4. ROADMAP 現在地: approval-reorder(#176、2026-07-17 実装) を反映。v2.8.0 行（L17）は歴史的記録として不変
5. CHANGELOG（リリース準備）（Codex WARN 確定）: `## [Unreleased]` セクションを新設し approval-reorder エントリ + Breaking 明記。version bump・tag は本 cycle scope 外
6. terminology: plan-review を正式 Phase 化しない（Naming Layers と整合、Codex PASS）。用語表に 1 行注記のみ
7. positive assert の精度（Codex PASS 指摘）: onboard テンプレート検査は section_grep 型（区間抽出完全一致）

逆向き契約 sweep（Explore + Codex review + 実読で確認済み）:
- flip 必須の結合ペア: `skills/onboard/reference.md` L414 テンプレート ⇔ `tests/test-onboard-tdd-workflow-template.sh` L25 TC-01（`grep -q 'spec → sync-plan → plan-review →.*RED'`）。双方向 pin、原子的に反転
- TC-03 維持 + 負契約分離（Codex BLOCK 3）: L511 の汎用 `codex exec --full-auto`（"review plan" を伴わない非対話実行）は据え置き → TC-03 無変更 PASS。新 TC-C2-2 で「`--full-auto "review plan"` 不在 + review plan 用途は read-only」を別 assert として追加
- 歴史的記録（変更しない、除外理由明記）: ROADMAP.md L17（v2.8.0 成果記述）/ docs/decisions/adr-cycle-retrospective.md L7（ADR Context 凍結）/ docs/requests/20260315_workflow_enforcement.md L11（過去 request）/ docs/architecture.md L102「review(plan) は廃止」（統一 review skill 化の設計進化記述、現行 `review --plan` の否定ではない）/ docs/v3-data-ml-type-design.md L157（v3 将来設計、別ドメイン資料）
- 新規テストファイルなし → Test Scripts 113 不変（test-codify-insight.sh TC-19 非干渉）

## Baseline

- 全 113 テスト: 113/113 rc=0（ALL PASS）。evidence: `/private/tmp/claude-501/-Users-morodomi-Projects-MorodomiHoldings-agents-dev-crew/66be0fcc-9986-4114-b779-9d983b621721/scratchpad/c2-baseline.txt`（Holdings 親構造複製、隔離、2026-07-17 実測、隔離 snapshot 上）
- RED 期待遷移（Codex BLOCK 4 訂正）: baseline 113 scripts PASS → RED で TC-C2-1〜5 が FAIL（現状 doc は旧順序）→ GREEN 後 113/113 scripts PASS。Test Scripts 数は 113 不変（新規ファイルなし）

## Verification

```bash
bash tests/test-onboard-tdd-workflow-template.sh
bash tests/test-doc-consistency.sh
bash tests/test-doc-alignment.sh
grep -c 'full-auto "review plan"' skills/onboard/reference.md   # 0 を期待
grep -c "sync-plan → plan-review" skills/onboard/reference.md   # 歴史記述以外 0 を期待
awk '/^## \[Unreleased\]/{f=1} f&&/approval-reorder/{print "changelog ok"; exit}' CHANGELOG.md
grep -F "#176" ROADMAP.md && echo "roadmap updated"
```

最後に隔離 snapshot 上で全 113 テストを再実行し、baseline との diff が「TC-01 flip 分 + 新 TC の PASS 追加のみ」であることを確認。

Evidence: (orchestrate が自動記入)

## Progress Log

Format for each phase entry (**strict, required by pre-commit-gate.sh**):

```
### YYYY-MM-DD HH:MM - PHASE_NAME
- [completed action]
- Phase completed
```

Phase-specific content:
- RED: `Test code created, N tests failing`
- GREEN: `Implementation complete, all tests passing`
- REFACTOR: `refactor (checklist) + Verification Gate passed`
- REVIEW: `review(code) score:NN verdict:PASS/WARN/BLOCK`
- COMMIT: `Committed: [hash]`

### 2026-07-17 16:06 - KICKOFF
- Cycle doc created（sync-plan による plan → Cycle doc 転記、approval-reorder Cycle 1 で実装済みの Step 3.5 転記契約に準拠）
- Scope definition ready（plan の Files to Change 全量 9、Test List TC-C2-1〜5 を verbatim 転記）
- frontmatter 初期化: codex_session_id / plan_file は plan の Plan Review Record から転記
- Phase completed

### 2026-07-17 16:06 - Plan Review (pre-approval)
- codex_session_id: "019f6eb7-ba83-79c3-a452-e781392e2eb4"
- review_attempts:
  - {started: 2026-07-17 15:16:01, completed: 2026-07-17 15:24:25, verdict: BLOCK (5 BLOCK / 4 WARN / 7 PASS)}
  - {started: 2026-07-17 15:26:59, completed: 2026-07-17 15:28:59, verdict: BLOCK (1 BLOCK / 2 WARN、他は解消確認)}
- findings 要約: attempt 1 — B1 Files 過少（doc test 配置/Cycle doc/STATUS 漏れ）→ 9 files 明示 / B2 onboard 目標行が本体 AGENTS.md L33 と不一致 + Post-Approve ブロック全体未 scope→本体一致へ / B3 L521 security 片側 + 負契約未自動化→両側 read-only + TC-C2-2 / B4 RED 期待遷移矛盾→訂正 / B5 INIT 廃止前提が誤り（現役用語）→INIT 整理撤回。WARN — risk LOW→MEDIUM / narrative sweep（architecture L102 / v3-data-ml）→除外一覧明記 / CHANGELOG [Unreleased] 確定 / Record placeholder→本節記入。attempt 2 — 残 B3'（TC-C2-2 が L521 後半 resume を固定せず）→設計判断 2 と TC-C2-2 に (a)-(d) 個別 assert 化で反映 / W（evidence 相対パス）→絶対パスへ / W（Record 未確定）→本節確定
- unresolved_blocks: なし（attempt 2 の残 BLOCK は設計判断 2・TC-C2-2 の (a)-(d) 化として反映済み。反映後の Codex 再検証は「再レビュー1回まで」の新規則により未実施 — 承認者が本 plan 上で直接確認済み）
- reviewed_plan_hash: b7523f72a408a85c6c6892c595101acce427597aedb6b528fdc3801ca4652a8e
- plan_presented: 2026-07-17 15:30:14
- hash一致確認: b7523f72a408a85c6c6892c595101acce427597aedb6b528fdc3801ca4652a8e (architect実測)
- verdict: WARN（attempt 2 の残 BLOCK は plan 反映済み・unresolved なし。architect Design Review Gate は PASS ~20 だが、Codex 側 verdict 履歴としては WARN 相当を記録）
- Phase completed

### 2026-07-17 16:19 - RED
- Test code created, 5 tests failing（TC-C2-1〜5）
- `tests/test-onboard-tdd-workflow-template.sh`: TC-01 を新順序へ flip（onboard AGENTS.md テンプレート区間を awk 区間抽出し、本体 AGENTS.md の TDD Workflow 行と完全一致 assert + 旧 `sync-plan → plan-review` 不在 assert）。TC-C2-2 を追加（L521 Codex セッション作成 bullet を section 抽出し (a)-(d) 個別 assert）。実行結果: TC-01 FAIL（canonical_match=0 stale_hits=1）、TC-C2-2 FAIL（a/b/c FAIL、d PASS）。既存 TC-02〜TC-08 は PASS 維持（PASS: 7 / FAIL: 4 / TOTAL: 11, rc=1）
- `tests/test-doc-consistency.sh`: TC-C2-3（usability.md plan mode 区間の plan-review < approve 順序 assert）/ TC-C2-4（ROADMAP.md 現在地節の approval-reorder or #176 言及 assert）/ TC-C2-5（CHANGELOG.md `## [Unreleased]` section 内 approval-reorder + Breaking 言及 assert）を追加。実行結果: 3件とも FAIL（TC-C2-3: plan-review idx=0, approve idx=64／TC-C2-4: 言及なし／TC-C2-5: 全カウント0）。既存 TC-01〜TC-19 は PASS 維持。TC-13（Regression: 他 test-*.sh 実行）は test-onboard-tdd-workflow-template.sh の意図した FAIL に連鎖して FAIL（想定通り、RED 状態の cascading failure）
- red_state_verified: true（新 5 TC すべて FAIL、既存 TC は全 PASS を個別実行で確認。full suite 実行は行っていない）
- Phase completed

### 2026-07-17 16:39 - GREEN

- Implementation complete, all tests passing
- `skills/onboard/reference.md`: L387 判定基準を `plan-review → approve` 新順序基準へ更新／L410-430 テンプレート内 TDD Workflow 行 + Post-Approve Action ブロックを本体 `AGENTS.md` L33-40 と verbatim 一致へ書換（旧「orchestrate が plan-review を内部管理」「sync-plan や review --plan を直接呼ぶな」の旧禁止文は除去）／L521 Codex セッション作成 bullet を初回・resume 両方 `codex exec --sandbox read-only` 化（`--full-auto` 除去、L511 汎用 `--full-auto` は不変）
- `docs/usability.md`: L62 Phase Transition フロー図の plan mode 区間に `plan-review` を `QA` と `approve` の間へ挿入／L118 `review(plan)` を `plan-review` へ用語統一（INIT は現役用語のため不変）
- `ROADMAP.md`: 「現在地」節に approval-reorder（#176、2026-07-17）の説明段落を追加。v2.8.0 等の歴史記述は無変更
- `CHANGELOG.md`: 先頭に `## [Unreleased]` を新設し `### Breaking`（承認ゲート意味論変更: plan review が承認前へ / pre-red-gate が plan_file・Plan Review Record を要求 / spec Step 8 追加）+ `### Added`（approval-reorder Cycle 1/2 内容）を記載
- `docs/terminology.md`: 「### plan-review」節を新設し「正式 Phase 名ではない」旨の1行注記を追加（Naming Layers の Phase 表は無変更）
- 対象2テスト: `bash tests/test-onboard-tdd-workflow-template.sh` rc=0（PASS: 9 / FAIL: 0、TC-01・TC-C2-2 含む）／`bash tests/test-doc-consistency.sh` rc=0（PASS: 16 / FAIL: 0、TC-C2-3/4/5 含む、TC-13 内で既存111ファイルの回帰も実行しPASS）
- 回帰: `bash tests/test-doc-alignment.sh` rc=0（PASS: 9 / FAIL: 0）
- full suite の最終集計は orchestrator が確定
- Phase completed

---

## Next Steps

1. [Done] KICKOFF
2. [Done] RED
3. [Done] GREEN <- Current
4. [ ] REFACTOR
5. [ ] REVIEW
6. [ ] COMMIT
7. [ ] DONE

### 2026-07-17 16:47 - REFACTOR

- チェックリスト 7 項目を変更ファイル（doc 5 + test 2）へ適用。doc-only + テスト追加のためコード smell 対象薄。改善不要
- section_grep ヘルパー（test-doc-consistency.sh 新規追加 6 行）は test-codify-rule-docs.sh の fixed-string index() 方式を踏襲、既存ヘルパーと重複なし
- onboard 残存の旧順序文字列 1 件（L387）は migration 検出パターンでの旧表記引用（「旧表記を検出したら上書き提案」）— 意図的引用として保持（doc-drift-fix の historical reference と同型）。TC-C2-1 はテンプレート区間内の旧表記不在を assert しており矛盾なし
- full suite（orchestrator 実行、Holdings 親構造複製 snapshot、直列）: **113/113 rc=0、baseline diff 空**（scratchpad/c2-final.txt）
- Verification Gate: bash -n 2 テスト OK / onboard rc=0 / 追跡ラベル 0
- コード変更 0 件 → 全 PASS 維持
- Phase completed

### 2026-07-17 16:50 - VERIFY (Block 2c.5)

- Verification セクション全コマンドを real-path 実行。evidence: /tmp/dev-crew-verify-20260717_1605/verify.log
- onboard rc=0 (9/9、TC-C2-2 read-only 両側 + full-auto 不在確認) / doc-alignment rc=0 (9/9) / doc-consistency rc=0
- full-auto "review plan" count=0 / CHANGELOG [Unreleased] approval-reorder ok / ROADMAP #176 反映
- Phase completed

### 2026-07-17 16:59 - REVIEW (competitive: Claude panel + Codex)

- Risk: risk-classifier LOW score:0 だが Cycle 1 伝播 + 配布物（onboard）変更のため floor（Codex + security + correctness）で実施。review_policy self=fable
- 判定内訳: security 10 PASS / correctness 10 PASS（両者 optional のみ）/ Codex BLOCK 2 + WARN 2 + PASS 3
- Findings 3-category triage:
  1. **TC-C2-3 が section 抽出不備（Codex BLOCK-2）**: accept-apply。usability.md 全体の fenced block を走査し最初の `plan mode:` を採用しており、別 section に正しい例が入ると対象フロー退行でも偽 PASS。`## Phase Transition UX` / `### Automatic` 見出し範囲→code block の順で抽出へ修正
  2. **TC-C2-5 の Breaking 独立カウント（Codex WARN-1 = correctness optional 3）**: accept-apply。`### Breaking` subsection 内で approval-reorder/#176 を確認する形へ強化（別機能の Breaking で偽 PASS 防止）
  3. **CHANGELOG の絶対表現（Codex WARN-2）**: accept-apply。「pre-red-gate が plan_file と Plan Review Record を要求」→「新形式の cycle doc では」と限定（legacy fallback の存在と整合）
  4. **onboard L513 の read-only 継続 tension（security optional）**: accept-apply。「RED/GREEN 委譲は CLAUDE.md の --full-auto 継続コマンド」の一文追加で誤読防止
  5. **TC-C2-2 のコメント行番号ドリフト（correctness optional 1）**: accept-apply。L521/L511 ハードコードを内容参照に
  6. **TC-C2 prefix 衝突（correctness optional 2）**: accept-defer（#181 起票済み）
  7. **TC-01 先頭1行比較（correctness optional 4）**: accept-defer（現状 1 行構成、YAGNI）
- **Codex BLOCK-1（Files 9 契約外変更）の裁定**: docs/cycles/20260717_1126_approval-reorder.md の変更は本 cycle Block 0 の codify gate が生成した正規副産物（前 cycle retro の captured→resolved + Codify Decisions 追記）。state-ownership.md の codify-insight 権限に完全準拠し、本 cycle の実装意図（narrative + onboard 伝播）とは独立・内容中立。architect 3 分岐でいう「観察のみ = 記録」に相当し scope 実質変更ではないため**再承認不要**。透明化のため本エントリで scope 同梱を明示記録（+ STATUS.md は COMMIT 時定常更新で計画どおり）。実変更集合 = Files 9 + 前 cycle doc（codify）+ STATUS（COMMIT 時）
- PASS: onboard 本体一致 / read-only 両側化 + negative assert / narrative docs（架空 review skill 化の architecture L102・v3-data-ml 不変）
- 判定: 初回 Codex BLOCK → 全 accept-apply 適用後に再検証 → 統合判定は fix 後に確定

### 2026-07-17 17:05 - REVIEW accept-apply fix (test-owner担当分)

- 担当範囲: `tests/test-doc-consistency.sh` / `tests/test-onboard-tdd-workflow-template.sh` のみ（gate・doc 本体は対象外）
- Finding 1（Codex BLOCK-2）: TC-C2-3 を section-scoped 抽出へ強化。`## Phase Transition UX` 見出し区間を先に awk 抽出してから fenced code block を走査するよう変更し、区間外の `plan mode:` を含む decoy block を拾わない形にした（旧実装は whole-file scan で最初にヒットした fenced block を採用しており、別 section の decoy が偽 PASS/偽 FAIL を生む余地があった）
- Finding 2（Codex WARN-1 / correctness optional 3）: TC-C2-5 を `## [Unreleased]` → `### Breaking` の二段 awk 区間抽出へ変更し、Breaking subsection 内限定で approval-reorder/#176 の言及を assert。旧実装は `[Unreleased]` section 全体で approval-reorder と Breaking を独立カウントしており、別機能の Breaking 項目が残っていれば approval-reorder 側の Breaking 記述を消しても PASS してしまう欠陥があった
- Finding 3（correctness optional 1）: TC-C2-2 のコメント「L521 region」およびメッセージ「(L511)」のハードコード行番号参照を削除し、「Codex セッション作成 bullet」「Codex Integration bullet, non-review-plan usage」という内容参照へ統一（チェックロジック自体は無変更）
- 検証（直列実行）: `bash tests/test-doc-consistency.sh` rc=0（PASS 16/FAIL 0、TC-13 含め全 PASS）/ `bash tests/test-onboard-tdd-workflow-template.sh` rc=0（PASS 9/FAIL 0）
- oracle 確認（scratchpad 隔離 fixture、リポジトリ非変更）: `## Phase Transition UX` 区間外に decoy fenced block（正順 `plan mode: INIT -> plan-review -> approve`）を挿入し、区間内の実フロー行を退行させた（`approve -> plan-review` へ反転）fixture で TC-C2-3 抽出ロジックを単体実行。新ロジック（区間限定）は正しく FAIL（pr_idx=75 > ap_idx=64、decoy 非流入）、同 fixture に対する旧ロジック（whole-file scan）は decoy を拾い FAIL すべき所を PASS（false-PASS）することを確認。区間限定抽出が Codex BLOCK-2 の指摘した偽 PASS 経路を塞ぐことを実証
- Phase completed

### 2026-07-17 17:12 - REVIEW findings 適用（全 accept-apply）

- **red-worker（テスト側）**: TC-C2-3 を `## Phase Transition UX` 区間先行抽出→内部 code block 走査へ（whole-file scan の偽 PASS 封鎖、oracle で decoy block を拾わないことを実証）/ TC-C2-5 を `[Unreleased]`→`### Breaking` 二段区間抽出で approval-reorder/#176 の関連を pin / TC-C2-2 のコメント・メッセージ行番号を内容参照へ
- **green-worker（doc 側）**: CHANGELOG Breaking を「新形式の（plan_file を持つ）cycle doc では」と限定（legacy fallback と整合）/ onboard L513 に「read-only 継続は承認前 plan review 限定、RED/GREEN 委譲は非対話コマンド」の注記追加（--full-auto literal は参照のみ）
- **defer（accept-defer）**: TC-C2 prefix 衝突（#181 起票済み）/ TC-01 先頭1行比較（現状1行構成 YAGNI）
- 対象テスト rc=0（test-doc-consistency 16/16、test-onboard 9/9）。次に full suite 再検証

### 2026-07-17 17:20 - REVIEW 統合判定

- 全 accept-apply 適用後、full suite（Holdings 親構造複製 snapshot、直列）: **113/113 rc=0、baseline diff 空**（scratchpad/c2-final2.txt）
- Codex BLOCK 2（TC-C2-3 偽 PASS / Files scope 記録）+ WARN 2 は解消・記録済み。Claude 両 reviewer は初回から PASS
- **統合判定: 合意 PASS** → auto-COMMIT 進行
- Phase completed

### 2026-07-17 17:21 - DISCOVERED

- 本 cycle 新規 DISCOVERED なし。#179（Cycle 2）は本 cycle 完了で close
- 継続 follow-up（既起票）: #180 3分岐 charter SSOT 化 / #181 テスト TC-R・TC-C2 識別子の cycle 固有 prefix 化（本 cycle の correctness optional 2 も #181 に集約）

## Retrospective

抽出時刻: 2026-07-17 17:22
抽出方法: Cycle doc 全体（plan review 2 attempt / dogfood 第2号 / code review の TC-C2-3 偽 PASS + Files scope 記録漏れ / heredoc バッククォート事故）からの失敗→最終解→insight 抽出

### Insight 1: doc 内の code block/フロー図を契約テストする時は「見出し区間を先に抽出 → その区間内で走査」の二段。whole-file の fenced block scan は別 section の decoy を拾う
- **Failure**: TC-C2-3 が usability.md 全体の fenced block を走査して最初の `plan mode:` を採用 → `## Phase Transition UX` に限定していないため、別 section に正しい順序の例が追加されると対象フロー退行でも偽 PASS。Codex code review BLOCK-2。oracle で decoy block を拾う false-PASS を実証
- **Final fix**: `## Phase Transition UX` 見出し区間を先行抽出 → その内部の code block から `plan mode:` を取得。区間外 decoy を拾わないことを oracle 実証
- **Insight**: **structured doc（同種の code block/例が複数 section に散在しうる doc）の契約テストは「見出し区間の先行抽出 → 区間内走査」の二段構成にする。whole-file の fenced block / grep は別 section の decoy を拾い、対象が退行しても他 section の正例で偽 PASS する**。section_grep（cycle 20260703_2035 #2）の適用範囲を「見出し内の記述検査」から「見出し内の code block 検査」へ拡張
- **一般化**: rules/test-patterns.md 追記候補（doc 内 code block 契約は見出し区間先行抽出）

### Insight 2: Block 0 codify が生成する前 cycle doc 更新は、本 cycle の Files to Change に「scope 同梱」として明示計上する。承認済み scope 外の変更は内容中立でも記録する
- **Failure**: 本 cycle commit に docs/cycles/20260717_1126（前 cycle）の codify 更新が含まれるが、承認済み Files 9 に列挙されていなかった。Codex code review BLOCK-1（scope 契約外）
- **Final fix**: REVIEW judgment で「Block 0 codify の正規副産物・state-ownership 準拠・内容中立・再承認不要」を裁定し、実変更集合 = Files 9 + 前 cycle doc（codify）+ STATUS（COMMIT 時）と明示記録
- **Insight**: **orchestrate Block 0 の codify gate は前 cycle doc を変更する。この変更は承認済み plan の Files to Change に現れないため、plan 段階で「Block 0 codify による前 cycle doc 更新が commit に同梱される」を Files 注記に含めるか、REVIEW で scope 同梱として明示裁定する。承認 scope と実 commit の差分は内容中立でも透明化する**
- **一般化**: rules/state-ownership.md or plan-discipline.md 追記候補（Block 0 codify の scope 同梱記録）

### Insight 3（tooling 事故・no-codify 相当だが記録）: heredoc（非 quoted delimiter）に日本語文中のバッククォート/`$` を書くと command substitution される
- **Failure**: Cycle doc への REFACTOR エントリ追記で `cat << EOF` 内に `` `sync-plan → plan-review` `` を書き、バッククォートが command substitution されて `command not found: sync-plan` + 該当文字列が空欠落
- **Final fix**: Edit で欠落行を復元。以降の heredoc は quoted delimiter（`<< 'EOF'`）を使うか、バッククォートを含む本文は Edit/Write で書く
- **Insight**: **Cycle doc 等へバッククポート・`$`・`!` を含む本文を heredoc で追記する時は quoted delimiter（`<< 'HEREDOC'`）を使う。非 quoted heredoc は文中の技術用語（バッククォート引用・変数風文字列）を command substitution / 変数展開して静かに欠落させる**。本 cycle 後半は全 heredoc を quoted delimiter に統一して再発ゼロ
- **一般化**: 運用 tip（rule 化は過剰、no-codify。ただし再発したら test-patterns の bash 落とし穴へ）

### 成功事例（observation: dogfood 第2号で新フローが low-risk cycle でも安定動作）
- 本 cycle も承認前 Codex plan review（2 attempt、BLOCK 5+1 を承認前に反映）→ sync-plan 転記 + hash 照合（MATCH）→ 強化 pre-red-gate が hash 実照合込みで PASS。新フローが Cycle 1（medium/複雑）に続き low-risk cycle でも回った。提示前待ちは 2 attempt で計 ~10 分（Cycle 1 の ~15 分より短縮 = low-risk で BLOCK 数が減った）。no-codify（設計意図どおりの動作実証）

### 2026-07-17 17:22 - COMMIT

- 最終 full suite（Holdings 親構造複製 snapshot、直列、review-fix 反映後）: 113/113 rc=0、baseline diff 空（scratchpad/c2-final2.txt）
- pre-commit-gate（明示指定）rc=0 PASS
- STATUS.md: Done 70→71 + Completed 行。Test Scripts 113 不変。Done count pin テストなし
- commit 同梱: skills/onboard/reference.md / tests/test-onboard-tdd-workflow-template.sh / docs/usability.md / ROADMAP.md / CHANGELOG.md / docs/terminology.md / tests/test-doc-consistency.sh / 本 cycle doc / docs/STATUS.md + docs/cycles/20260717_1126（Block 0 codify 同梱、REVIEW で scope 裁定済み）
- #179 close。#180/#181 継続
- リリース準備完了: CHANGELOG [Unreleased] 整備済み。次は release-skill で 2.13.0（minor + Breaking）— ユーザー判断
- feature/approval-reorder-cycle2 → PR → --admin merge
- Phase completed

## Codify Decisions

### Insight 1
- **Decision**: codified
- **Destination**: rule
- **Reason**: section 限定走査の概念は cycle 20260703_2035 #2（section_grep）以降 4+ cycle で再発。「見出し区間先行抽出 → 区間内 code block 走査」への拡張として rules/test-patterns.md へ追記（follow-up 実装）
- **Decided**: 2026-07-21 15:03

### Insight 2
- **Decision**: codified
- **Destination**: rule
- **Reason**: Block 0 codify 出力の scope 同梱は 20260706_1216（Codex W2）・20260707_0936（Files #12）で手動対処済みの 3 度目の再発。2-strike rule（cycle 20260703_1215 #2）により自動昇格。rules/plan-discipline.md へ「Block 0 codify による前 cycle doc 更新を plan Files 注記 or REVIEW 裁定で透明化」を追記（follow-up 実装）
- **Decided**: 2026-07-21 15:03

### Insight 3
- **Decision**: no-codify
- **Reason**: heredoc command substitution 事故は初出（過去 cycle の heredoc 言及は bypass 議論・fixture 記述・onboard 設計で別文脈）。insight 自身の判定通り運用 tip に留める。再発時は rules/test-patterns.md の bash 落とし穴へ昇格
- **Decided**: 2026-07-21 15:03
