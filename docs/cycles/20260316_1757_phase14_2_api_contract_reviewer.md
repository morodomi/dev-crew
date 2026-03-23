---
phase: DONE
---

# Phase 14.2: api-contract-reviewer 新設

## Metadata

| Key | Value |
|-----|-------|
| Status | DONE |
| Phase | COMMIT |
| Created | 2026-03-16 |
| Branch | feature/phase-14-2-api-contract-reviewer |
| Risk | LOW |

## Context

ROADMAP v4 Phase 14.2。API の破壊的変更と設計品質を検出する専門 reviewer agent を新設する。現在の Code Review には API 契約の観点がなく、required field 後追い追加、enum 値削除、レスポンス型変更等の破壊的変更が見逃される。Google API Design Guide / Microsoft REST API Guidelines / Azure Breaking Changes Guidelines を参照元とする。

## Scope

### In Scope

- `agents/api-contract-reviewer.md`: 新規エージェント定義
- `skills/review/steps-subagent.md`: Code Mode Risk-gated に追加
- `skills/review/reference.md`: Agent Roster (Code Mode) に追加
- `tests/test-api-contract-reviewer.sh`: テスト新設
- `docs/STATUS.md`: 更新

### Out of Scope

- risk-classifier.sh の変更（既に API/route/controller/endpoint 検出シグナルあり）
- 既存 api-attacker.md の変更（セキュリティ用、別の目的）
- OpenAPI/Swagger スキーマの静的バリデーション

## Test List

- [x] TC-01: agents/api-contract-reviewer.md が存在する
- [x] TC-02: model: sonnet である
- [x] TC-03: memory: project である
- [x] TC-04: description に「API」と「契約」を含む
- [x] TC-05: Breaking Changes 観点が含まれる
- [x] TC-06: blocking_score 基準が定義されている
- [x] TC-07: steps-subagent.md の Code Mode Risk-gated に存在する
- [x] TC-08: reference.md の Agent Roster (Code Mode) に存在する
- [x] TC-09: Condition が API/endpoint flags である
- [x] TC-10: risk-classifier.sh に API contract シグナルが存在する
- [x] TC-11: 既存テスト全通過（リグレッション）

### DISCOVERED

- TC-07 等の awk 範囲マッチが Code/Plan Mode を区別しない false-positive リスク（既存テスト共通の構造的課題）
- api-contract-reviewer と correctness/design-reviewer の dedup ルール未定義（Phase 17.1 統合テストで対応）
- get_frontmatter() の grep -F 推奨（プロジェクト内4例目、一括対応が妥当）

## Progress Log

### 2026-03-16 17:50 - RED
- テスト 11件作成 (test-api-contract-reviewer.sh)
- TC-10, TC-11 以外の 9件が失敗することを確認
- Phase completed

### 2026-03-16 17:52 - GREEN
- agents/api-contract-reviewer.md 新規作成（5観点: Breaking Changes, Resource Naming, Error Structure, Versioning, Pagination）
- skills/review/steps-subagent.md に Risk-gated エントリ追加
- skills/review/reference.md の Agent Roster (Code Mode) に行追加
- docs/STATUS.md 更新
- 全11テスト通過
- Phase completed

### 2026-03-16 17:54 - REFACTOR
- 変更が最小限のため、リファクタリング不要
- Phase completed

### 2026-03-16 18:00 - REVIEW
- [REVIEW] Mode: code, Risk: MEDIUM (score: 35)
- security-reviewer: PASS (score: 10) - optional 3件
- correctness-reviewer: PASS (score: 22) - important 1件 (TC-07 awk範囲), optional 2件
- product-reviewer: PASS (score: 28) - important 2件 (dedup未定義, ベースライン未測定), optional 3件
- 最大スコア: 28 → PASS
- DISCOVERED 3件記録
- Phase completed

### 2026-03-16 18:05 - COMMIT
- feat: v4 Phase 14.2 api-contract-reviewer 新設
- AGENTS.md エージェント数更新 (33→35)
- Phase completed
