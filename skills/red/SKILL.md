---
name: red
description: テストコードを作成し、失敗することを確認する（並列実行対応）。PLANの次フェーズ。「テスト書いて」「red」で起動。
allowed-tools: Task, Read, Write, Edit, Bash, Grep, Glob
---

# TDD RED Phase

テストコードを作成し、失敗することを確認する（並列実行がデフォルト）。

## 禁止事項

- 実装コード作成（GREENで行う）
- テストを通すための実装

## Workflow

### Step 1: Cycle doc確認（Hard Gate）

```bash
CYCLE_DOC=$(grep -L 'phase: DONE' docs/cycles/*.md 2>/dev/null | head -1)
```

| 結果 | アクション |
|------|-----------|
| 見つかった | Cycle doc を読み込んで続行 |
| 見つからない | BLOCK: 「進行中の Cycle doc がありません。kickoff を実行してください」で中断 |

Test ListのTODOからテストケースを選択してWIPに移動。

### Stage 1: Test Plan

Cycle doc の Test List を Given/When/Then + 具体テストデータに展開。詳細: [reference.md](reference.md#test-plan-stage)

### Stage 2: Test Plan Review

要件とテスト計画を照合（網羅性・カテゴリバランス）。Gap発見時は追加。詳細: [reference.md](reference.md#tp-review)

### Stage 3: Test Code

テストファイル依存関係分析 → red-worker並列起動 → 結果収集・マージ → テスト実行で**失敗**確認。
詳細: [reference.md](reference.md#dependency-analysis)

### exspec check (optional)

`which exspec` で存在確認。インストール済みなら実行、未インストールならスキップ。詳細: [reference.md](reference.md#exspec)

### Verification Gate

| 結果 | 判定 | アクション |
|------|------|-----------|
| テスト失敗 | PASS | GREENへ自動進行 |
| テスト成功 | BLOCK | テスト条件を見直して再試行 |

### Cycle doc更新（Progress Log）

Cycle doc の Progress Log に追記し、frontmatter の `phase` を `RED`、`updated` を現在時刻に更新:

```markdown
### YYYY-MM-DD HH:MM - RED
- Test code created, N tests failing
- Phase completed
```

### 完了

RED完了。次: Orchestrate時は自動GREEN / 手動時は `/green`。

## Reference

- 詳細: [reference.md](reference.md)
- red-worker: [../../agents/red-worker.md](../../agents/red-worker.md)
