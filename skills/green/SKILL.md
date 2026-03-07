---
name: green
description: テストを通すための最小限の実装を行う。REDの次フェーズ。「実装して」「green」で起動。
allowed-tools: Task, Read, Write, Edit, Bash, Grep, Glob
---

# TDD GREEN Phase

テストを通すための最小限の実装を行う（並列実行がデフォルト）。

## 禁止事項

- 過剰な実装（テストに必要ない機能）
- リファクタリング（REFACTORで行う）
- 新しいテスト作成（REDで行う）

## Workflow

### Step 1: Cycle doc確認（Hard Gate）

```bash
CYCLE_DOC=$(grep -L 'phase: DONE' docs/cycles/*.md 2>/dev/null | head -1)
```

| 結果 | アクション |
|------|-----------|
| 見つかった | Cycle doc を読み込んで続行 |
| 見つからない | BLOCK: 「進行中の Cycle doc がありません。kickoff を実行してください」で中断 |

WIPのテストケースを抽出。

### Step 2: ファイル依存関係分析

テストケースを対象ファイル別にグルーピング。同一ファイル→同一workerに割り当て（競合回避）。

### Step 3: green-worker並列起動

Taskツールで `dev-crew:green-worker` を並列起動。

### Step 4: 結果収集・マージ

全workerの完了を待ち、結果を統合。失敗時は該当workerのみ再試行。

### Step 5: 全テスト実行→成功確認

全テストが**成功**すること（GREEN状態）を確認。

### Verification Gate

| 結果 | 判定 | アクション |
|------|------|-----------|
| 全テスト成功 | PASS | REFACTORへ自動進行 |
| テスト失敗 | BLOCK | 該当worker再試行 |

### Step 6: Cycle doc更新（Progress Log）

Cycle doc の Progress Log に追記し、frontmatter の `phase` を `GREEN`、`updated` を現在時刻に更新:

```markdown
### YYYY-MM-DD HH:MM - GREEN
- Implementation complete, all tests passing
- Phase completed
```

### Step 7: 完了

GREEN完了。次: Orchestrate時は自動REFACTOR / 手動時は `/refactor`。

## Reference

- 詳細: [reference.md](reference.md)
- green-worker: [../../agents/green-worker.md](../../agents/green-worker.md)
