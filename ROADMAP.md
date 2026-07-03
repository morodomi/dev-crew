# Roadmap

> 完了済みの Phase 1-10 は [docs/archive/development-plan.md](docs/archive/development-plan.md) を参照。
> 完了済みの v2/v2.4/v2.5/v2.6/v2.6.x/v2.7/v3 は [docs/archive/roadmap-v2-v3-completed.md](docs/archive/roadmap-v2-v3-completed.md) を参照。

## 現在地

v2.10.0 リリース済み。main には v2.11.0 向けの品質規律強化が蓄積中（下記）。全完了済みバージョン:
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
- v3-pre (Phase 1-8, archive label): Constitution-Driven Development

次: **v2.11.0 — スキル棚卸し + 品質規律強化**（下記）

---

## v2.11 スキル棚卸し + 品質規律強化

skill-audit（2026-07-02 外部レビュー）を起点に、死蔵スキルの削除と「規律の自動契約化」を一括で進めるリリース。

### 実施済み（main マージ済み or PR/branch 上）

| 項目 | 内容 | 状態 |
|------|------|------|
| スキル棚卸し | phase-compact / reload / strategy 削除（32→29）+ quality 系 description 先鋭化 | main マージ済み (#146) |
| gate 修正 | pre-commit/pre-red gate の ACTIVE_CYCLE 選択を latest-updated + 明示指定に修正（#145）。skill 文書 7 ファイルの同型バグ一掃 | main マージ済み (#150) |
| codify 実装 | 直近 cycle の codified insight 9 件を rules 5 ファイル + red skill Stage 3.5 に実装。削除スキル名の inverse contract（#143） | PR #152 レビュー中 |
| parallel 削除 | parallel スキル削除（29→28、#142）。worktree 並行実装の実用性なし + 読み取り並列・実行直列の原則と衝突 | branch push 済み（#152 マージ後に PR） |

### リリースまでの残タスク

| # | Cycle | 内容 | 目安 |
|---|-------|------|------|
| 1 | codify 実装 (2) | #151 追跡ラベルの自動 inverse contract（2-strike rule の初適用）+ codified 済み 2 件（integration-verification self-apply 拡張 / test-patterns の process-substitution rc 検査）+ 20260703_1650 captured 3 insight の triage・実装 | 0.5 日 |
| 2 | phase lifecycle | #147 non-DONE cycle doc 15 件の DONE 遷移 + COMMIT→DONE 遷移責務の workflow 明文化 | 0.5 日 |
| 3 | リリース準備 | CHANGELOG 補完（v2.8.0〜v2.10.0 のエントリが欠落中 — 本リリースで v2.11.0 と合わせて追記）+ docs/STATUS.md 整合 | 0.25 日 |
| 4 | リリース | release-skill で v2.11.0（marketplace.json 更新 + tag、`--follow-tags` で同時 push） | 即日 |

前提: PR #152 と parallel 削除 PR の main マージ。スケジュール目安: **2026-07-04〜07-05 リリース**。

### v2.11 に含めない（v2.12 以降候補）

| 項目 | 理由 |
|------|------|
| #148 gate 間選択ロジックの drift guard | 共有 lib 化 vs 行範囲 diff の設計判断が必要。急がない |
| #144 test-hooks-structure の standalone/full-suite 不一致調査 | staleness 解消で実害なし。再現条件の調査から |
| Agile Loop Step 1.5 以降（下記） | 規律基盤（v2.11）安定後に再開 |

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
