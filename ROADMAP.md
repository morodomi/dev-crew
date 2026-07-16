# Roadmap

> 完了済みの Phase 1-10 は [docs/archive/development-plan.md](docs/archive/development-plan.md) を参照。
> 完了済みの v2/v2.4/v2.5/v2.6/v2.6.x/v2.7/v3 は [docs/archive/roadmap-v2-v3-completed.md](docs/archive/roadmap-v2-v3-completed.md) を参照。

## 現在地

v2.12.0 リリース済み（2026-07-15）。全完了済みバージョン:
- v2 (Phase 11-13): Claude + Codex 統合開発フロー
- v2.4 (Phase 14-17): Review Taxonomy 体系化 (33→40 agents)
- v2.5 (Phase 18): Constitution-Driven Enforcement
- v2.6 (Phase 26-29): スキル成熟化 (Gotchas, On-demand hooks, PLUGIN_DATA)
- v2.6.x (Phase 30-31, #84, #102): 構造厳格化 + Product Verification + designer AI review
- v2.6.3-v2.6.6: バグ修正 + post-approve-gate廃止 + orchestrate TaskCreate導入
- v2.7-pre (Phase 24-25, archive label): 動的スキルコンテンツ注入 (released within v2.6.x patches; not a separate tag)
- v2.7.0: Agile Loop Step 1 — retrospective loop (#119/#120/#121/#122)
- v2.8.0: orchestrate 統合 (sync-plan → plan-review → TDD を orchestrate が一元管理、post-fix 群 #125-#127)
- v2.9.0: rules path-scoping (#139)
- v2.10.0: plan-discipline GREEN 検証の逆向き契約 sweep 規律 (#140)
- v2.11.0: スキル棚卸し + 品質規律強化 (2026-07-06)
- v2.12.0: reviewer モデル設定機構 (reviewer-policy v1) + codified rule 群 + gate drift guard + risk-classifier 精度改善 (2026-07-15)
- v3-pre (Phase 1-8, archive label): Constitution-Driven Development

次候補（v2.12.0 リリース後）: codify 実装2件 / #156 legacy 正規化 / reviewer-policy follow-up #170-172 / #144 flaky / Agile Loop 1.5

---

## v2.11.0 / v2.12.0（リリース済み）

- **v2.11.0**（2026-07-06）: スキル棚卸し（32→28）+ 品質規律の自動契約化。skill-audit を起点に死蔵スキル削除・gate 修復（#145/#150）・codified insight 実装（#143）・parallel 削除（#142）。詳細は [CHANGELOG](../CHANGELOG.md) [2.11.0]。
- **v2.12.0**（2026-07-15）: reviewer モデル設定機構（reviewer-policy v1、#173）+ codified rule 7件（#165/#166）+ gate drift guard（#148）+ risk-classifier 精度改善（#164/#169）+ phase 図 DONE 終端（#157）。詳細は [CHANGELOG](../CHANGELOG.md) [2.12.0]。

次候補は上記「現在地」を参照。

---

## v2.7 Agile Loop（継続計画）

> Step 1 (cycle-retrospective loop) は **v2.7.0** としてリリース済 (PR #119/#120/#121/#122)。
> Step 1b (codify-insight) も完了。Step 1.5 以降は v2.11 リリース後に再開判断。

dev-crew 内 agile namespace で Cycle Retrospective + Goal Layer + Knowledge Lifecycle を吸収する。別プラグイン化しない。詳細は [ADR-002](docs/decisions/adr-cycle-retrospective.md)。

| Step | 内容 | 状態 |
|------|------|------|
| 1   | cycle-retrospective (REVIEW→DISCOVERED→retro→COMMIT, auto blocking, 抽出のみ inline) | **完了 (v2.7.0)** |
| 1b  | codify-insight (次回 /orchestrate 開始時 decide gate, codify/defer/no-codify を明示判断) | 完了 |
| 1.5 | captured 可視化 (未処理 insight 件数の警告) | 次の候補（v2.12 以降） |
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
- 「指示で 2 回失敗した規約は自動契約に昇格する」（2-strike rule、cycle 20260703_1215 retro）を規律運用の基本則とする
