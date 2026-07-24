# Changelog

## [Unreleased]

### Added
- spec に強制想起（Forced Recall、Step 7.2）を追加（#187）: Files to Change 確定後・Step 8 の前に `scripts/recall-candidates.sh` を実行し、変更予定ファイルに関連する過去 cycle doc を決定論的に提示する。データソースは既存のもののみ（`git log --name-only` の共変更 + Cycle-Doc トレーラーの確定リンク優先）で、ハブファイルは IDF 相当で寄与を減衰。上位候補を助言者形式 3 点セット（何が起きたか / 当時の前提 / 今回も同じ前提か）で plan の `## Recall` に記録し、sync-plan が Cycle doc へ転記する。正本変更ゼロ・冪等・常駐プロセスなし
- コミットメッセージに `Cycle-Doc: <path>` トレーラーを付与（commit スキル）: feature コミットと cycle doc を機械可読なリンクで結ぶ。値は Cycle Doc Gate が解決した主サイクル 1 件の repo-relative パス。commit スキル以外の経路（release-skill・手動コミット）には付与しない
- cycle-retrospective に想起漏れ設問を追加: 「今回の手戻りは、過去のどの cycle doc を最初に読んでいれば防げたか」を全正常終了経路で `### 想起漏れ` 固定 2 行スキーマ（回答 `該当なし` or `docs/cycles/<file>.md`）に記録し、機械集計可能にする
- 20260709 以降の 8 cycle に蓄積された codified insight 19 件を rules へ条項化（rules/{test-patterns, plan-discipline, review-triage, agent-prompts, integration-verification, multi-file-consistency, doc-mutations}.md + .claude/rules/ の同名 mirror へ同時反映）: SIGPIPE consumer 禁止・図契約のノードトークン pin・多段 pipe rc 先取り + 権限拒否 fixture・negative sweep の新文言不一致 oracle・hash boundary fixture pin・doc 内 code block の見出し区間先行抽出・逆向き契約の相対アンカー禁止・機械可読契約の実行可能コマンド化・継承デフォルト前提の一次ソース確認・連番次値の実装実測・Block 0 codify の scope 同梱透明化・判定割れの機構分解 + 実測 oracle・tier テーブル置換の構造突合・委譲 worker のフェーズ完了マーカー必須・timestamp 契約の Progress Log 追記全般拡張・gate 強化の全 caller pin・順序反転の negative assert・current-state 更新の doc 全体 sweep。加えて skills/spec の Plan File Template に `override` フィールドと review_attempts 厳密形式注記を追記（両言語 lockstep）

## [2.14.0] - 2026-07-22

### Changed
- Rules をロード契機（always / cycle-scoped / file-scoped）で分類し、TDD workflow rules を Cycle doc 操作時に限定してロードする構成へ変更

## [2.13.0] - 2026-07-21

### Breaking
- 承認ゲートの意味論変更（approval-reorder、#176）: plan review の実行タイミングが人間承認の前（plan mode 内、spec Step 8）へ変更。新形式の（`plan_file` を持つ）cycle doc では pre-red-gate が `plan_file` と Plan Review Record の存在を要求するようになった（plan_file 不在の legacy cycle doc は従来通り弱い fallback で通過）

### Added
- approval-reorder（#176/#179）: spec に Step 8（承認前 plan review）を追加。Cycle 1（PR #182）で機構・実行時 memory・権威 doc（AGENTS/CLAUDE/workflow/README/architecture）を新順序へ更新。Cycle 2 で残る narrative doc（usability.md フロー図・ROADMAP.md 現在地）と onboard 生成テンプレート（AGENTS.md TDD Workflow / Post-Approve Action / Codex セッション作成の read-only 化）を新順序へ伝播

## [2.12.0] - 2026-07-15

reviewer モデルの設定機構 + 品質規律の codify + risk-classifier 精度改善。v2.11.0 リリース後に main へ蓄積した4サイクル（#148/#165、codified rule/#166、#164/#169、reviewer-policy v1/#173）を一括リリース。

### Breaking
- Code Mode の policy 対象 reviewer が、従来の `model: "sonnet"` 固定から `self`（orchestrator 自身の現在モデルを Task に明示指定）へ変更（#173）。既存 install（`.claude/dev-crew.json` に `review_policy` 未設定）でも既定 `self` が適用され、reviewer は sonnet ではなく実行中モデルで走る。品質・コストへの影響は実行モデルと環境の allowlist 次第。従来挙動に戻すには `review_policy.reviewer_model` を `"sonnet"` に、HIGH のみ上位にするには `escalate_high_to` を設定する。Plan Mode の固定 reviewer は対象外

### Added
- reviewer-policy v1（#173）: `.claude/dev-crew.json` の `review_policy` で Code Mode の reviewer モデルを設定可能に（`reviewer_model` / `escalate_high_to`、allowlist self/sonnet/haiku/opus/fable）。HIGH tier のみ上位モデルへ escalation。security+correctness の NON-NEGOTIABLE floor を初の契約テスト化（TC-04/06）。onboard が dev-crew.json + CLAUDE.md 宣言を生成
- codified rule 7件を rules に実装: (1) 否定形前提の全 grep 根拠 (2) multi-mode skill の全モード契約テスト pin (3) 隔離 snapshot の親構造複製 + N件同時 FAIL の cascade 切り分け (4) 裸 command-substitution の同型 sweep (5) 委譲 worker の timestamp date 実測（以上 #166）(6) frontmatter 区間限定編集 (7) section_grep heading の fixed-string 化（以上 #165）
- gate 選択ロジック drift guard（#148、test-phase-gate TC-24）

### Changed
- review-triage の LOW tier を correctness floor 厳格化（trivial でも security+correctness は常時必須）

### Fixed
- risk-classifier の doc-diff 過大スコア FP（#164/#169）: SQL/external/行数シグナルを code hunk 限定に。doc-centric cycle が誤って HIGH 判定される問題を修正。pipefail 下の pipe+grep -q SIGPIPE under-score bug も修正
- section_grep の ERE 解釈を fixed-string 化（#165、括弧付き見出しの silent no-match 解消）
- phase 図（workflow.md / architecture.md）に COMMIT→DONE 終端を反映（#157）

## [2.11.0] - 2026-07-06

スキル棚卸しと品質規律の自動契約化。skill-audit（外部レビュー）を起点に、
死蔵スキルの削除・ゲート機構の修復・「指示で防げない規約の契約テスト化」を一括で実施。

### Removed
- 死蔵スキル 4 種を削除（32→28）: phase-compact / reload / strategy / parallel（#142）。PreCompact hook は存続
- テストコメントの追跡ラベル（cycle 番号・issue 番号）を全除去し、自動 inverse contract（TC-17）で再混入を禁止（#151）

### Fixed
- pre-commit/pre-red gate の ACTIVE_CYCLE 選択を latest-updated + 明示指定に修正（#145）。first-non-DONE 選択により 2 ヶ月前の doc を検査していた穴を解消。skill 文書 7 ファイルの同型探索も統一
- commit 時の phase: DONE 遷移を orchestrate 全モード（SKILL.md / steps-subagent / steps-codex / steps-teams）で commit skill 委譲に統一（#147）。完了済み 19 doc を DONE へ migration し「non-DONE = active」の意味論を修復（TC-18 invariant）

### Added
- codified insight 14 件を rules 8 ファイル + red skill に実装: contiguous phrase pin / pre-existing count 実測 / baseline snapshot 隔離 / 読み取り並列・実行直列 / usage 実測 / 信頼ディレクトリ境界 / process-substitution rc 検査 / 2-strike rule / 委譲 prompt テンプレート監査 / Test List 遷移責務ほか
- red skill に Stage 3.5「False-pass 自己証明」を新設
- 削除スキル名の path-form inverse contract（TC-16、#143）
- quality 系スキル 6 種の description 先鋭化（トリガー語衝突の解消）

## [2.10.0] - 2026-07-01

### Added
- plan-discipline: count/status 変更 cycle の GREEN 検証を逆向き契約 sweep で全実行する規律（curated リスト禁止、#140）
- rules の path-scoping（#139）

## [2.9.0] - 2026-05-25

### Added
- agent-prompts: 並列起動時の prompt 契約（3+ subagent fan-out の担当範囲・出力形式・統合キー・検証条件）
- review: Step 5 Findings Synthesis

## [2.8.0] - 2026-04-27

### Added
- rules/ ⇄ .claude/rules/ の byte-identical mirror 体制（#132）
- integration-verification rule: Verification Gate に real-path invocation を必須化（#133）
- 蓄積 codify 決定 7 件の rule/skill 実装

### Fixed
- pre-existing 6 FAIL の全解消（full baseline 0 FAIL 達成）
- careful allowed-tools / informal alias sweep / risk-classifier FP ほか debt 解消

## [2.7.0] - 2026-04-21

Agile Loop Step 1: cycle-retrospective ループの実用完成。
TDD サイクル末尾で「最初の失敗 → 最終解 → 事前知識化」のペアを抽出し、
Cycle doc に永続化する。pre-commit-gate で deterministic に検証。

設計: [ADR-002](docs/decisions/adr-cycle-retrospective.md)
PRs: #119 (A1 foundation) / #120 (A2a skill 本体) / #121 (A2b orchestrate 統合) / #122 (post-commit fixes)

### Added

- `skills/cycle-retrospective/` 新規 skill
  - Hard Gate (Cycle doc 存在 + phase REVIEW/COMMIT/DONE)
  - Idempotency Check (retro_status != none → skip)
  - Extraction (mizchi 方式 failure → final fix → insight)
  - Output (## Retrospective を Cycle doc EOF に append、retro_status 遷移)
  - Override 2 路分離 (proceed / abort、default abort)
- `frontmatter.retro_status: none|captured|resolved` 必須フィールド
  - sync-plan agent が新規 cycle で `none` 初期化
  - cycle-retrospective が `none → captured` (insight あり) または `none → resolved` (no-lesson / extraction failed override) に遷移
- `orchestrate Block 2f`: REVIEW → DISCOVERED → cycle-retrospective → COMMIT の自動順序
- `pre-commit-gate.sh check 4`: retro_status の deterministic 検証
  - `captured` / `resolved` → PASS
  - `none` / 空値 / 不在 / 無効値 → BLOCK
- 新規テスト: `tests/test-frontmatter-retro-status.sh` / `test-cycle-retrospective.sh` / `test-pre-commit-gate-retro.sh` / `test-orchestrate-a2b.sh`

### Changed

- `validate-cycle-frontmatter.sh`: retro_status 値の strict validation + body contamination check (行頭限定)
- `rules/state-ownership.md`: cycle-retrospective 行追加 (retro_status / updated)
- `skills/orchestrate/SKILL.md`: 106 → 97 行に compress + Block 2f 挿入
- `skills/orchestrate/{reference, steps-subagent, steps-teams, steps-codex}.md`: Block 2f + abort handling
- `skills/commit/SKILL.md`: Pre-COMMIT Gate に retro_status check 追記
- `docs/workflow.md` / `docs/architecture.md` / `README.md` / `AGENTS.md` / `CLAUDE.md`: cycle-retrospective 同期
- `skills/spec/templates/cycle.md`: frontmatter に retro_status: none 追加 (placeholder セクションは入れない)

### Breaking (edge case only)

- `pre-commit-gate.sh` が `retro_status` 不在 cycle doc を BLOCK するようになった
  - A1 以降の新規 cycle は sync-plan が自動で `retro_status: none` を初期化、影響なし
  - Archived cycles は phase: DONE で gate skip、影響なし
  - 影響対象: A1 以前の in-progress cycle doc を upgrade 後に commit しようとする場合のみ
  - 対処: frontmatter に `retro_status: none` を手動追加して cycle-retrospective を実行

## [2.6.6] - 2026-03-27

post-approve-gate廃止とorchestrateプロセス強化。

### Changed

- post-approve-gateフラグを廃止し、orchestrate TaskCreateに移行
- orchestrate TaskCreateの7件全登録を必須化

## [2.6.5] - 2026-03-27

Post-Approve Action安全性強化とバグ修正。

### Fixed

- Post-Approve Actionでsync-planを直接呼ばせないルール追加
- risk-classifier.sh の grep -vc 0件時に整数比較エラー修正

## [2.6.4] - 2026-03-26

hook環境変数の修正。

### Fixed

- hookのpwdをCLAUDE_PROJECT_DIRに置換 + set -u除去

## [2.6.3] - 2026-03-24

バックログ整理。

### Removed

- babysit-prをBacklogから削除

## [2.0.2] - 2026-03-15

Codex セッション分離と onboard テンプレート品質強化。

### Added

- Codex session isolation: Cycle ID ベースのセッションバインディング (#55)
- onboard reference.md に TDD Workflow リテラルテンプレート追加（表記ブレ防止）
- onboard reference.md に Codex Integration リテラルテンプレート追加（Auto-orchestrate トリガー行含む）
- CLAUDE.md マージ戦略を最大3セクション（Codex Integration 追加）に更新

### Fixed

- onboard テンプレートの plan-review 記述を Codex 非依存に修正
- Migration セクションに Codex Integration を追加（整合性修正）

## [2.0.1] - 2026-03-15

Codex 統合の整理と委譲スコープの明確化。

### Changed

- P0: sync-plan から Codex Debate を削除。Codex Plan Review は Post-Approve Action に一本化
- P1: commit 後に Review Findings サマリーを表示（指摘内容・修正内容の可視化）
- P2: codex_mode (full/no) は RED/GREEN 委譲のみ制御。Plan Review と Code Review は Codex 利用可能なら常時 competitive に実行
- P2: steps-subagent.md / steps-teams.md の REVIEW に Codex competitive review を追加
- REFACTOR のワーディングを PHILOSOPHY.md に合わせて Claude 主担当に修正
- Post-Approve Action の Codex plan review を codex_mode から分離

### Fixed

- #53: Codex 委譲確認を plan-review 時に実施
- #54: Post-Approve Action の順序修正 (sync-plan → plan-review)

## [2.0.0] - 2026-03-15

Claude + Codex 統合開発フロー。60+ commits since v1.0.0.

### Phase 11: Claude + Codex 統合開発フロー

- 11.1: kickoff → sync-plan 移行（完全置換、エイリアスなし）
- 11.2: Codex 委譲インターフェース（orchestrate に Codex パス追加）
- 11.3: 競争的レビュー（Claude + Codex 並行レビュー、findings 集約）
- 11.5: マイグレーション検証（kickoff 参照 0 件確認）
- 11.6: onboard スキル改善（AGENTS.md/CLAUDE.md テンプレート、symlink/commit ガイダンス）
- 11.7: refactor スキル再構築（/simplify 依存解消、チェックリスト駆動）

### Phase 10: docs-reorganization

- PHILOSOPHY.md 作成（target philosophy 定義）
- ROADMAP.md 作成（Phase 11+ 計画）
- README.md 刷新（Claude + Codex Integration セクション）
- development-plan.md / skills-catalog.md アーカイブ化

### Phase 9: Codex 環境整備

- sync-skills スキル（Codex 用 symlink 生成）
- AGENTS.md / CLAUDE.md 分離
- YAML frontmatter validation (yamllint)

### Phase 8: State Ownership + RED Fast-path

- State ownership rules + frontmatter enrichment
- RED skill complexity-based fast-path
- Auto-kickoff after plan approve
- ADR template and decision records

## [1.0.0] - 2026-03-03

Initial public release. 33 agents, 29 skills, 3 rules, hook-based automation.

### Phase 7: Factory Model Adaptation

- Ambiguity Detection (Questioning Protocol) in init skill
- RED phase 3-stage split: Test Plan, Test Plan Review, Test Code
- 14 validation tests for factory model

### Phase 6: Next Evolution

- CLAUDE.md staleness detection hook
- Onboard template simplification
- Risk Classifier tuning (LOW threshold)
- On-Demand Capabilities research (OSS survey, E2E benchmark)

### Phase 5.5: Orchestrator Redesign

- Plan mode-driven workflow unification
- refactor skill with /simplify delegation
- Phase-compact + /compact natural context compression

### Phase 5: v2 Restructuring

- Unified review skill (quality-gate + plan-review merged)
- Risk Classifier: deterministic reviewer scaling (LOW/WARN/BLOCK)
- review-briefer (haiku) for input token compression
- design-reviewer: integrated design review (scope + architecture + risk)
- strategy skill for project planning phase

### Phase 4: Optimization

- Model selection hints in agent frontmatter
- Hook-based tool output filtering (git log, git diff)
- SKILL.md slim-down + Progressive Disclosure to reference.md

### Phase 3: Designer Agent

- designer.md with Japanese/Western UI/UX comparison
- Integrated into review skill (plan mode)

### Phase 2: phase-compact

- Phase-boundary context compaction skill
- Cycle doc persistence for cross-phase context
- Orchestrate skill integration

### Phase 1.5: Test Infrastructure

- test-plugin-structure.sh, test-agents-structure.sh, test-skills-structure.sh
- SKILL.md size enforcement (< 100 lines)

### Phase 1: Migration

- Consolidated tdd-core, tdd-*, redteam-core, meta-skills into single plugin
- Flat structure: agents/, skills/, rules/, hooks/
- Single plugin.json (marketplace.json removed)
