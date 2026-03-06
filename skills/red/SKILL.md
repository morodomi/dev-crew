---
name: red
description: テストコードを作成し、失敗することを確認する（並列実行対応）。PLANの次フェーズ。「テスト書いて」「red」で起動。
allowed-tools: Task, Read, Write, Edit, Bash, Grep, Glob
---

# TDD RED Phase

テストコードを作成し、失敗することを確認する（並列実行がデフォルト）。

## Progress Checklist

```
RED Progress:
- [ ] Cycle doc確認、TODO→WIPに移動
- [ ] Stage 1: テスト計画の正式化
- [ ] Stage 2: テスト計画の検証
- [ ] Stage 3: テストコード作成・失敗確認
- [ ] exspec check (optional)
- [ ] Cycle doc更新（WIP→DONE相当）
- [ ] 完了メッセージ表示
```

## 禁止事項

- 実装コード作成（GREENで行う）
- テストを通すための実装

## Workflow

### Step 1: Cycle doc確認

```bash
ls -t docs/cycles/*.md 2>/dev/null | head -1
```

Test ListのTODOからテストケースを選択してWIPに移動。

### Stage 1: Test Plan (テスト計画の正式化)

Cycle doc の Test List を Given/When/Then + 具体テストデータに展開。
Cycle doc の「## Formal Test Plan」セクションに記録。
詳細: [reference.md](reference.md#test-plan-stage)

### Stage 2: Test Plan Review (テスト計画の検証)

要件（Cycle doc Scope/Design）とテスト計画を照合:

| チェック | 内容 |
|---------|------|
| 網羅性 | In Scope全項目にTCがあるか |
| カテゴリバランス | 正常系/異常系/境界値/権限 |
| Gap発見時 | Test Listに追加 → Stage 1へ |

詳細: [reference.md](reference.md#tp-review)

### Stage 3: Test Code (テストコード作成)

#### テストファイル依存関係分析

テストケースを対象テストファイル別にグルーピング。
**原則**: 同一テストファイル→同一workerに割り当て（競合回避）。詳細: [reference.md](reference.md#dependency-analysis)

#### red-worker並列起動

Taskツールで `dev-crew:red-worker` を並列起動。詳細: [reference.md](reference.md)

#### 結果収集・マージ

全workerの完了を待ち、結果を統合。失敗時は該当workerのみ再試行（最大2回）。

#### テスト実行→失敗確認

テストを実行し**失敗**を確認（RED状態）。実行例: [reference.md](reference.md#test-execution)

### exspec check (optional)

テスト設計品質の静的解析。exspecインストール済みの場合のみ実行。

1. `which exspec` で存在確認。未インストール → スキップしてVerification Gateへ
2. `exspec --format json {test_files}` を実行（non-strictモード）
3. exit 0 → PASS、Verification Gateへ
4. exit 1 (BLOCK) → `exspec {test_files}` で人間可読出力を取得し、red-workerへフィードバック。最大2回リトライ
5. 2回失敗 → AskUserQuestionで判断を仰ぐ

### Verification Gate

| 結果 | 判定 | アクション |
|------|------|-----------|
| テスト失敗 | PASS | GREENへ自動進行 |
| テスト成功 | BLOCK | テスト条件を見直して再試行 |

### 完了

RED完了。次: Orchestrate時は自動GREEN / 手動時は `/green`。

## Reference

- 詳細: [reference.md](reference.md)
- red-worker: [../../agents/red-worker.md](../../agents/red-worker.md)
