---
name: refactor
description: /simplifyにコード品質改善を委譲し、Verification Gateで品質を確認する。GREENの次フェーズ。「リファクタして」「refactor」で起動。
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

# TDD REFACTOR Phase

Claude Code組み込みの `/simplify` にコード品質改善を委譲し、Verification Gateで品質を確認する。

## Progress Checklist

コピーして進捗を追跡:

```
REFACTOR Progress:
- [ ] 最新Cycle doc確認
- [ ] 現在のテストが全てPASSすることを確認
- [ ] /simplify でコード品質改善を実行
- [ ] Verification Gate通過
- [ ] Cycle doc更新
- [ ] 完了メッセージ表示
```

## 禁止事項

- テストを壊す変更
- 新機能の追加（次のサイクルで）
- テストの削除・変更

## Workflow

### Step 1: Cycle doc確認

```bash
ls -t docs/cycles/*.md 2>/dev/null | head -1
```

### Step 2: テスト確認

全テストがPASSすることを確認してから開始。

### Step 3: /simplify 実行

Claude Code組み込みの `/simplify` にコード品質改善を委譲する。

```
/simplify を実行してください。
対象: 今回のサイクルで変更・作成したファイル
```

/simplify が3エージェント並列でコードをレビュー・改善する。完了後、Verification Gateに進む。

### Verification Gate

| チェック | 条件 | 判定 |
|----------|------|------|
| テスト | 全PASS | 必須 |
| 静的解析 | エラー0 | 必須 |
| フォーマット | 適用済み | 必須 |

全て通過 → Cycle doc更新 → REVIEWへ進行。失敗時は修正して再試行。

### Step 5: Cycle doc更新

Cycle docのProgress Logに REFACTOR完了を記録。

### Step 6: 完了

```
================================================================================
REFACTOR完了
================================================================================
/simplify + Verification Gate通過。テストは全てPASS。

次のステップ:
- Orchestrate使用時: 自動的にREVIEWが実行されます
- 手動実行時: /review で次フェーズを開始してください
================================================================================
```

## Reference

- 詳細: [reference.md](reference.md)
