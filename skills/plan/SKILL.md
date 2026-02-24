---
name: plan
description: 実装計画を作成し、Test Listを定義する。INITの次フェーズ。「設計して」「計画して」で起動。
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, WebSearch, WebFetch
---

# TDD PLAN Phase

実装計画を作成し、Cycle docのPLANセクションを更新する。

## Progress Checklist

```
PLAN Progress:
- [ ] Cycle doc確認 → リスク確認 → ドキュメント確認
- [ ] 探索（Exploration）→ 既存パターン把握
- [ ] 対話 → PLAN更新 → QA自問 → Test List作成
- [ ] 完了メッセージ表示
```

## 禁止事項

- 実装コード作成（GREENで行う）
- テストコード作成（REDで行う）

## Workflow

### Step 1: Cycle doc確認

```bash
ls -t docs/cycles/*.md 2>/dev/null | head -1
```

Environmentセクションでバージョン情報を把握。

### Step 1.5: リスクスコア確認

Cycle docの `Risk: [スコア] ([判定])` を読み取り、設計深度を決定:

| スコア | 判定 | 設計深度 |
|--------|------|----------|
| 0-29 | PASS | 簡易設計（Test List中心、対話省略可） |
| 30-59 | WARN | 標準設計（現行通り） |
| 60-100 | BLOCK | 詳細設計（[reference.md](reference.md)参照） |

Riskフィールドなし → WARN（標準設計）として扱う。

### Step 2: 最新ドキュメント確認

メジャーバージョンや破壊的変更が疑われる場合、WebSearch/WebFetchで確認。

### Step 2.5: 探索（Exploration）

設計に入る前に、関連コード・ドキュメントを最低5ファイル読む:

1. Scope内の既存コード・テストをRead/Glob/Grepで調査
2. 既存パターン・ユーティリティ・共通処理を特定
3. 影響範囲の把握（依存先・依存元）

探索結果をCycle docのPLANセクションに記録してから設計に入る。

### Step 3: 対話 → PLANセクション更新

アーキテクチャ、依存関係、品質基準をユーザーに確認し、背景・設計方針・ファイル構成をCycle docに追記。

### Step 4: QA Question Asker（自問）

Test List作成前に、以下の質問に回答しCycle docに記録する。詳細: [reference.md](reference.md#qa-question-asker)

1. この設計で最も壊れやすい箇所はどこか?
2. ユーザーが「やってはいけない」使い方をした場合に何が起こるか?
3. この機能が他の機能に与える影響は何か?
4. 6ヶ月後にこのコードを変更する人が困る点は何か?

### Step 5: Test List作成

**タスク粒度: 各タスクは2-5分で完了する1アクション**（詳細: [reference.md](reference.md#タスク粒度)）

必須: 正常系・境界値・エッジケース・異常系。目安: 5-10ケース。
テンプレート: [reference.md](reference.md#test-list-template)

### Step 5.5: クロスレイヤー検出（parallel 提案）

`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` 有効時、複数レイヤー検出で parallel を提案。詳細: [reference.md](reference.md#クロスレイヤー検出)

### Step 6: 完了

```
================================================================================
PLAN完了
================================================================================
設計・Test Listを作成しました。
次のステップ:
- Orchestrate: 自動的にreview(plan)が実行されます
- 手動: /review --plan で設計レビューを開始
================================================================================
```

## Reference

- [reference.md](reference.md) / [Phase Completion](reference.md#phase-completion)