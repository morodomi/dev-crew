---
name: red
description: テストコードを作成し、失敗することを確認する（並列実行対応）。PLANの次フェーズ。「テスト書いて」「red」で起動。
allowed-tools: Task, Read, Write, Edit, Bash, Grep, Glob
---

## 禁止事項

- 実装コード作成（GREENで行う）
- テストを通すための実装

## Workflow

### Cycle Doc Gate
`grep -L 'phase: DONE' docs/cycles/*.md | head -1` → found: continue / not found: BLOCK(run spec)

### Pre-RED Gate (deterministic)
`bash scripts/gates/pre-red-gate.sh` → exit 0: continue / exit 1: BLOCK(message indicates missing step)

Test ListのTODOからテストケースを選択してWIPに移動。

### Complexity Gate

Test List に対してREDフェーズ開始時に評価する。詳細: [reference.md](reference.md#complexity-classification)

| Class | Criteria | Stages |
|-------|----------|--------|
| trivial | 1-2 items, Example only, no escalation triggers | Stage 1 as 1-line GWT; Stage 2 skip; Stage 3 |
| standard | 3-5 items, Example only, no complex escalation triggers | Stage 1 simplified; Stage 2 Review skip; Stage 3 |
| complex | 6+ items OR any non-Example paradigm | Full 3-stage (all stages) |

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
`Tests fail → PASS(→GREEN) | Tests pass → BLOCK(review test conditions)`

### Cycle doc更新
Progress Log追記(`### {date} - RED\n- {summary}\n- Phase completed`) + frontmatter更新(phase/updated)

### 完了

RED完了。次: Orchestrate時は自動GREEN / 手動時は `/green`。

## Reference

- 詳細: [reference.md](reference.md)
- red-worker: [../../agents/red-worker.md](../../agents/red-worker.md)
