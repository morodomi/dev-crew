# ADR-003: Codex plan review を承認前へ移動する（approval-reorder）

## Status: accepted

## Context

現行フロー（spec → 人間承認 → sync-plan → Codex plan review）では、承認後に review が scope を拡大し、実測で 3 cycle 連続 +3/+1/+4 のスコープ拡大が発生した（直近の doc-drift-fix cycle でも BLOCK 3 件を承認後に Cycle doc 補正で吸収）。人間が承認した内容と実際に実行される内容が構造的にずれる問題が issue #176 で外部レビュー合意され、10 cycle 評価基準が事前固定された。

v2.8 で現行の「承認後 review」順序になった技術的理由は 2 点: (1) pre-red-gate が Cycle doc 内の記録を要求していた、(2) codex_session_id が Cycle doc frontmatter を起点に管理されていた。本 cycle はこの 2 つの制約を「転記 + gate 強化」で解消し、承認前への移動を可能にする。承認前への移動はプロジェクト初の意味論変更である。

本 plan 自体が新フローの dogfood: draft を plan mode 内で `codex exec --sandbox read-only` レビュー（attempt 1: BLOCK 8/WARN 2/PASS 3、7分43秒）→ 全 BLOCK を反映 → 最終版を再レビュー（attempt 2: BLOCK 1/WARN 1、2分弱）→ 残指摘を設計判断へ反映済み。

## Decision Scorecard

| 項目 | 評価 | 理由 |
|------|------|------|
| Requirements Fit | A | 承認対象と実行対象の構造的ずれ（scope underestimation 実測 3/3 cycle）を根本解消 |
| Security | B | 承認ゲートの意味論変更はプロジェクト初。可逆設計（既存 gate は強化であり撤去でない）でリスク緩和 |
| Operability | B | Codex 2 attempt の外部検証済み。10 cycle 評価で運用実績を継続監視 |
| Complexity | C | Files 33（目標 ≤10 の 3.3 倍）。順序契約が doc↔test で相互 pin された原子的変更のため単一 cycle が必要と判断 |
| Testability | B | 新規 TC-R1〜R15 + 既存 flip 5 件で契約テスト化。gate 側は fixture ベースで decisive |

## Arguments

### Accepted

- **承認前 review への移動**: Codex plan review を plan mode 内（ExitPlanMode 前、spec Step 8）で実行し、findings を draft plan へ直接反映、最終版を 1 回だけ再レビューして打ち切る
- **同一性保証**: `reviewed_plan_hash`（Record 見出しより上の全文の sha256）を sync-plan（一次照合）+ pre-red-gate（frontmatter `plan_file:` から再算出する決定論的最終防衛）で二重照合
- **codex_session_id 取得の 3 段 fallback**: stdout header → rollout jsonl 最新ファイル名 → 両失敗時 `extraction_failed: true` の degraded 経路
- **pre-red-gate 強化**: Plan Review (pre-approval) エントリの区間抽出検証（Phase completed / verdict enumerate / hash 実照合 / unresolved_blocks 整合 / override 証跡）
- **Block 1 順序変更**: sync-plan（転記）→ architect（転記後検証、3 分岐: 転記欠落=BLOCK / scope 実質変更=再承認 / 観察のみ=DISCOVERED）。「承認後 findings は一律 DISCOVERED-only」の旧方針は撤回
- **計測は追加機構ゼロ**: 提示前待ち増分・承認までの時間は既存フィールドから算出

### Rejected

- **Approval Brief 等の追加承認補助機構**: issue #176 の 10 cycle 評価基準（見逃し 0・手戻り 0・承認 1 回/cycle・承認まで中央値 2 分/最大 5 分・理解不足 1 件以下）が達成された場合は不導入。評価未達の場合のみ次段階で検討する
- **レビュー待ち時間の tier 化**: 初回実測（単発レビュー 7 分 43 秒、再レビュー込み ~15 分）はあるが、10 cycle 評価の結果が出る前に対策を導入するのは時期尚早と判断。今回は実測記録のみに留める
- **Socrates plan review の完全 pre-approval 移動**: 本 cycle は spec/sync-plan/architect/gate の主経路のみを対象とし、Codex 不在時の Socrates 経路は DISCOVERED へ

### Deferred

- Cycle 2（narrative 残り: docs/usability.md / ROADMAP.md / skills/onboard/reference.md + 結合テスト / docs/terminology.md）は順序 pin テストなしで drift 実害が限定的なため分離
- 10 cycle 評価の結果次第でのレビュー待ち時間 tier 化の要否判断

## Decision

Codex plan review を承認前（plan mode 内、spec Step 8、read-only sandbox）へ移動する。新フロー: spec (plan mode) → draft plan → Codex plan review → findings 反映 → 最終版再レビュー(1 回) → 人間承認（レビュー済み・scope 確定済み） → orchestrate → sync-plan（Plan Review Record を転記） → architect（転記後検証） → RED。

同一性保証（reviewed_plan_hash 二重照合）と gate 強化により、v2.8 で承認後 review を選んだ技術的制約を解消した上での意味論変更である。

## Consequences

- 承認対象の質が向上し、承認回数は 1 回/cycle を維持（CONSTITUTION.md Goal 整合）
- pre-red-gate.sh が「決定論的 gate は単独完結」原則のもと hash 実照合まで担うようになり、gate 自体の責務が拡大（既存の sync-plan/Plan Review 検出ロジックへの依存を保ちながら強化）
- Cycle ごとの承認前レビュー所要時間が実測される（初回 7 分 43 秒、再レビュー込み ~15 分）。10 cycle 評価でこの数値が問題化すれば「レビュー深度の tier 化」を追加検討する
- 33 ファイルの一括変更は multi-file-consistency.md の「全モード契約テスト pin」原則の直接適用例となり、今後同様の順序契約変更の参照例として機能する
- 10 cycle 評価（issue #176 事前固定: 見逃し 0 / 手戻り 0 / 承認 1 回/cycle / 承認まで中央値 2 分・最大 5 分 / 提示前待ち増分計測 / 理解不足 1 件以下）で全達成が確認されれば、Approval Brief・運転モード・Ledger といった追加機構は導入しない。未達の場合は次 cycle で代替案を再評価する
