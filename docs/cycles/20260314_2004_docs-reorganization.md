---
feature: docs-reorganization
cycle: docs-reorg
phase: DONE
complexity: standard
risk_level: low
created: 2026-03-14 20:04
updated: 2026-03-14 20:04
---

# Docs Reorganization

## Goal

dev-crewのドキュメント体系を再構築。Claude Code + Codex統合開発フローを明文化し、各スキルの位置づけを明確にする。

## TODO

- [ ] PHILOSOPHY.md 新規作成 - 開発フロー哲学（Claude Code + Codex連携、PdM委譲、TDD-first）
- [ ] ROADMAP.md 新規作成 - Phase 11+、スキルマップ（いつ・どこで・誰が使うか）
- [ ] README.md 新規作成 - docs/ナビゲーション
- [ ] STATUS.md 更新 - 最新サイクル反映
- [ ] AGENTS.md 更新 - 正確な数値、Codex Integrationセクション
- [ ] CLAUDE.md 更新 - Codex統合フロー開発パターン
- [ ] development-plan.md アーカイブ化
- [ ] skills-catalog.md 簡素化 - Origin列削除、フロー上の位置で再編

## Progress Log

### 2026-03-14 20:04 - INIT
- 現状分析完了（Explore agent）
- 整理方針合意
- まずPHILOSOPHY.mdの哲学壁打ちから開始
- [x] PHILOSOPHY.md ドラフト作成 → Codexレビュー2回 → 6件findings対応済み
- [x] ROADMAP.md ドラフト作成 → Codexレビュー3回 → 8件findings対応済み

### 2026-03-14 20:30 - 哲学壁打ち完了
- 開発フロー哲学が確定。memory/philosophy_dev-flow.md に記録
- 核心: 「人間が楽をするための開発体制」
- Claude=planner, Codex=reviewer+implementer、性格差を活用
- kickoff廃止 → sync-plan agent（spec内部で呼ぶ軽量agent）
- 承認ポイント2つ: spec完了(設計承認), REVIEW後(debate時のみAskUserQuestion)
- 軽微修正は両者ACCEPT→auto-commit、人間の手を煩わせない
- Codex不在時はClaude fallback
- 確定フロー:
  ```
  spec → sync-plan → Codex plan review → findings判断 → 設計承認
  RED(Codex) → exspec → GREEN(Codex) → REFACTOR(Claude)
  Claude review + Codex review → findings判断 → auto-COMMIT or AskUserQuestion
  ```
