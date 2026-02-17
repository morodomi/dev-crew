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
- [ ] テストファイル依存関係分析
- [ ] red-worker並列起動
- [ ] 結果収集・マージ
- [ ] 全テスト実行→失敗確認
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

### Step 2: テストファイル依存関係分析

テストケースを対象テストファイル別にグルーピング:

| テストファイル | テストケース |
|---------------|-------------|
| tests/AuthTest.php | TC-01, TC-02 |
| tests/UserTest.php | TC-03 |

**原則**: 同一テストファイル→同一workerに割り当て（競合回避）

### Step 3: red-worker並列起動

Taskツールで `dev-crew:red-worker` を並列起動:

```
Task 1: TC-01, TC-02 → tests/AuthTest.php
Task 2: TC-03 → tests/UserTest.php
```

### Step 4: 結果収集・マージ

全workerの完了を待ち、結果を統合。失敗時は該当workerのみ再試行（最大2回）。

### Step 5: テスト実行→失敗確認

```bash
php artisan test --filter=TestName  # PHP
pytest tests/test_xxx.py -v          # Python
```

**期待**: テストが**失敗**すること（RED状態）

### Verification Gate

| 結果 | 判定 | アクション |
|------|------|-----------|
| テスト失敗 | PASS | GREENへ自動進行 |
| テスト成功 | BLOCK | テスト条件を見直して再試行 |

### Step 6: 完了

```
================================================================================
RED完了
================================================================================
テスト作成完了。失敗を確認しました。

次のステップ:
- Orchestrate使用時: 自動的にGREENが実行されます
- 手動実行時: /green で次フェーズを開始してください
================================================================================
```

## Reference

- 詳細: [reference.md](reference.md)
- red-worker: [../../agents/red-worker.md](../../agents/red-worker.md)
