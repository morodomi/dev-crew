---
phase: DONE
---

# Phase 15.1: test-reviewer 新設

## Metadata

| Key | Value |
|-----|-------|
| Status | DONE |
| Phase | COMMIT |
| Created | 2026-03-17 |
| Branch | feature/phase-15-1-test-reviewer |
| Risk | LOW |

## Context

ROADMAP v4 Phase 15.1。RED フェーズ後のテストコード品質を見る専門 reviewer agent を新設する。現在の Code Review にはテストコード固有の品質観点がなく、Fragile Test / Obscure Test / Mystery Guest 等のテストスメルが見逃される。xUnit Test Patterns (Meszaros) と Google SWE Book Ch11-12 を参照元とする。

## Scope

### In Scope

| # | 内容 | ファイル | type |
|---|------|---------|------|
| 1 | test-reviewer agent 定義の新設 | agents/test-reviewer.md | new |
| 2 | steps-subagent.md に flags-based 条件で登録 | skills/review/steps-subagent.md | modify |
| 3 | reference.md の Agent Roster に追加 | skills/review/reference.md | modify |
| 4 | risk-classifier.sh にテストファイル検出シグナル追加 | skills/review/risk-classifier.sh | modify |
| 5 | correctness-reviewer から Test assertion quality を分離 | agents/correctness-reviewer.md | modify |
| 6 | テスト新設 | tests/test-test-reviewer.sh | new |
| 7 | STATUS.md 更新 | docs/STATUS.md | modify |

### Out of Scope

- Plan mode の実装（Phase 15.2 / 16.5 で対応）
- exspec の変更（既存の CLI 層として独立）

## Design

### agent 定義 (agents/test-reviewer.md)

Focus テーブル:

| 観点 | チェック内容 | 参照元 |
|------|------------|--------|
| Fragile Test | 実装詳細への過度な結合、壊れやすいセットアップ、順序依存 | xUnit Test Patterns |
| Obscure Test | テスト意図の不明瞭さ、過度な setup、不明瞭なアサーション | xUnit Test Patterns |
| Mystery Guest | 外部ファイル・環境への暗黙の依存、テスト内で不可視のデータ | xUnit Test Patterns |
| Conditional Test Logic | テスト内の if/switch/loop、テスト内での例外キャッチ | xUnit Test Patterns |
| Test Code Duplication | テスト間の重複コード、共通化すべき fixture/helper | xUnit Test Patterns |
| テスト独立性 | 共有状態、実行順序依存、テスト間の副作用 | Google SWE Book Ch11 |

Output: `{"blocking_score": 0-100, "issues": [{"severity": "critical|important|optional", "category": "fragile-test|obscure-test|mystery-guest|conditional-logic|duplication|independence", "message", "file", "line", "suggestion"}]}`

ブロッキングスコア基準: 80-100→BLOCK | 50-79→WARN | 0-49→PASS

### steps-subagent.md 更新

Code Mode に flags-based 条件カテゴリを新設。既存の Risk-gated (MEDIUM/HIGH) とは独立し、ファイルタイプフラグで起動する。test-reviewer は test-file flags で起動（Risk level に関係なく）。

### correctness-reviewer dedup

correctness-reviewer.md の Focus から「Test assertion quality (AND vs OR conditions, verification granularity, design spec coverage)」を削除。テストコード品質観点は test-reviewer に一本化。correctness-reviewer はロジック正確性（論理エラー、エッジケース、例外処理）に専念。

### reference.md 更新

Agent Roster (Code Mode) テーブルに `test-reviewer | Sonnet | If test-file flags` を追加。

### risk-classifier.sh 更新

ファイルパスベースのシグナルに test/spec/__tests__ 検出を追加（+10）。

## Test List

- [x] TC-01: agents/test-reviewer.md が存在する
- [x] TC-02: model: sonnet である
- [x] TC-03: memory: project である
- [x] TC-04: description に「テストスメル」または「テストコード」を含む
- [x] TC-05: Focus テーブルに「Fragile Test」観点が含まれる
- [x] TC-06: xUnit Test Patterns 参照が含まれる
- [x] TC-07: blocking_score 基準が定義されている
- [x] TC-08: Output に category が含まれる
- [x] TC-09: Focus テーブル形式である（| 観点 |）
- [x] TC-10: Google SWE Book 参照が含まれる
- [x] TC-11: steps-subagent.md の Code Mode に test-reviewer が flags-based 条件で含まれる
- [x] TC-12: reference.md の Agent Roster (Code Mode) に test-reviewer が含まれる
- [x] TC-13: reference.md の test-reviewer の Condition が test-file flags である
- [x] TC-14: risk-classifier.sh にテストファイル検出シグナルが含まれる
- [x] TC-15: correctness-reviewer.md の Focus に Test assertion quality が含まれない
- [x] TC-16: correctness-reviewer.md の Focus に論理エラー観点が残っている
- [x] TC-17: リグレッション: 既存テスト全通過

### DISCOVERED

(none)

## Progress Log

### 2026-03-17 00:00 - PLAN

- Cycle doc 作成
- Socrates review: 3指摘（dedup未解決、+10では起動しない、Plan Mode欠落）
- 選択肢2採用: dedup ルール追加 + flags-based 条件明確化
- Scope 拡大: correctness-reviewer.md modify 追加、TC-15/TC-16 追加

### 2026-03-17 00:05 - RED

- テスト 17件作成 (test-test-reviewer.sh)
- TC-01〜TC-15 の 15件が失敗、TC-16/TC-17 の 2件が通過
- Phase completed

### 2026-03-17 00:07 - GREEN

- agents/test-reviewer.md: Focus テーブル（6観点 + dedup ルール）、Output category、Memory
- agents/correctness-reviewer.md: Test assertion quality を削除（test-reviewer に移管）
- skills/review/steps-subagent.md: Flags-based 条件カテゴリ新設、test-reviewer 登録
- skills/review/reference.md: Agent Roster (Code Mode) に test-reviewer 追加
- skills/review/risk-classifier.sh: テストファイル検出シグナル (+10) 追加
- tests/test-correctness-reviewer-quality.sh: dedup 対応に更新
- AGENTS.md: エージェント数 36→37
- docs/STATUS.md: 更新
- 全17テスト通過
- Phase completed

### 2026-03-17 00:10 - REFACTOR

- チェックリスト確認、改善対象なし（Markdown + シェルスクリプトのみ）
- Phase completed

### 2026-03-17 00:15 - REVIEW

- [REVIEW] Mode: code, Risk: HIGH (score: 60, テスト/スコアパターンで膨張)
- security-reviewer: PASS (score: 15) - optional 3件
- correctness-reviewer: PASS (score: 42) - important 5件, optional 2件
- TC-14 テストロジック修正（grep -q | head -1 パイプ問題）
- reference.md Signal テーブルにテストファイルシグナル追加
- 最大スコア: 42 → PASS
- Phase completed
