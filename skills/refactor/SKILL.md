---
name: refactor
description: /simplifyにコード品質改善を委譲し、Verification Gateで品質を確認する。GREENの次フェーズ。「リファクタして」「refactor」で起動。
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

## 禁止事項

- テストを壊す変更
- 新機能の追加（次のサイクルで）
- テストの削除・変更

## Workflow

### Cycle Doc Gate
`grep -L 'phase: DONE' docs/cycles/*.md | head -1` → found: continue / not found: BLOCK(run kickoff)

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
`Tests PASS + lint 0 + format OK → PASS(→REVIEW) | fail → fix & retry`

### Cycle doc更新
Progress Log追記(`### {date} - REFACTOR\n- {summary}\n- Phase completed`) + frontmatter更新(phase/updated)

### 完了
Output: REFACTOR完了。次: orchestrate→自動REVIEW / 手動→ /review

## Reference

- 詳細: [reference.md](reference.md)
