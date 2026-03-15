# Changelog

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
