# Changelog

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
