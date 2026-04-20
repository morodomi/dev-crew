# Roadmap

> 完了済みの Phase 1-10 は [docs/archive/development-plan.md](docs/archive/development-plan.md) を参照。
> 完了済みの v2/v2.4/v2.5/v2.6/v2.6.x/v2.7/v3 は [docs/archive/roadmap-v2-v3-completed.md](docs/archive/roadmap-v2-v3-completed.md) を参照。

## 現在地

v2.6.6 リリース済み。全完了済みバージョン:
- v2 (Phase 11-13): Claude + Codex 統合開発フロー
- v2.4 (Phase 14-17): Review Taxonomy 体系化 (33→40 agents)
- v2.5 (Phase 18): Constitution-Driven Enforcement
- v2.6 (Phase 26-29): スキル成熟化 (Gotchas, On-demand hooks, PLUGIN_DATA)
- v2.6.x (Phase 30-31, #84, #102): 構造厳格化 + Product Verification + designer AI review
- v2.6.3-v2.6.6: バグ修正 + post-approve-gate廃止 + orchestrate TaskCreate導入
- v2.7 (Phase 24-25): 動的スキルコンテンツ注入
- v3 (Phase 1-8): Constitution-Driven Development

次: v2.8 Agile Loop（計画中）

---

## v2.8 Agile Loop（計画中）

dev-crew 内 agile namespace で Cycle Retrospective + Goal Layer + Knowledge Lifecycle を吸収する。別プラグイン化しない。詳細は [ADR-002](docs/decisions/adr-cycle-retrospective.md)。

| Step | 内容 | 状態 |
|------|------|------|
| 1   | cycle-retrospective (REVIEW→DISCOVERED→retro→COMMIT, auto blocking, 抽出のみ inline) | 未着手 |
| 1b  | codify-insight (次回 /orchestrate 開始時 decide gate, codify/defer/no-codify を明示判断) | 未着手 |
| 1.5 | captured 可視化 (未処理 insight 件数の警告) | 未着手 |
| 2   | search-task → agile-next 化 + Goal doc 新設 (docs/goals/) | 未着手 |
| 3a  | Cycle doc frontmatter 最小拡張 (cycle_id/goal_id/issue_id/status/retro_status/review_verdict/verification_status) | 未着手 |
| -   | 運用評価ポイント（Step 3a 完了後、Step 3b 以降の必要性を再判定） | - |
| 3b  | flow metrics 構造化 (本文 ## Metrics or sidecar) | 未着手 |
| 4   | 知見 lifecycle (codify 先 artifact に origin_cycle / evidence_count / last_validated) | 未着手 |
| 5   | knowledge-prune (手動起動、候補列挙のみ、削除実行は通常 cycle に乗せる) | 未着手 |

### スコープ明文化（CONSTITUTION.md / docs/architecture.md に反映予定）

- dev-crew が含む: Goal 定義 / Backlog 選択 / Cycle 実行 / Retrospective / Flow 分析 / Knowledge 管理
- 含まない: 価値計測（実ユーザー反応・KPI）/ 事業横断 portfolio review / Marketing・Sales 判断 → 別社員として将来採用

---

## 方針

- 各サブタスクは独立した TDD サイクルで実施
- security 系エージェント/スキルは現状維持
