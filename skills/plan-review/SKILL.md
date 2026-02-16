---
name: plan-review
description: PLANフェーズの設計を最大6つの専門エージェントで並行レビュー（5 reviewer + 条件付き designer）。ブロッキングスコアでPASS(0-49)/WARN(50-79)/BLOCK(80-100)を判定。When this auto-triggers after PLAN phase completion（orchestrateまたはplanから自動呼び出し）。Manual trigger: 「plan-review」「設計レビュー」。
allowed-tools: Task, Read, Bash, Grep
---

# Plan Review

PLANフェーズの設計を最大6つの専門エージェントで並行レビューする（5 reviewer + 条件付き designer）。

## Progress Checklist

```
plan-review Progress:
- [ ] Cycle doc確認
- [ ] レビュー実行（Subagent + Sonnet）
- [ ] 結果統合・スコア判定
- [ ] 分岐判定（PASS/WARN/BLOCK）
```

## Workflow

### Step 1: Cycle doc確認

```bash
ls -t docs/cycles/*.md 2>/dev/null | head -1
```

PLANセクション（設計方針、Test List、変更予定ファイル）を読み込む。

### Step 2: レビュー実行

Subagent + Sonnet で並行実行。UI関連PLANの場合、条件付きで designer を6番目に起動。手順は [steps-subagent.md](steps-subagent.md) 参照。

### Step 3: 結果統合

5 reviewer のブロッキングスコアを集計（designer はスコア対象外）:

| 最大スコア | 判定 | アクション |
|-----------|------|-----------|
| 80-100 | BLOCK | 修正必須、進行不可 |
| 50-79 | WARN | 警告表示、継続可能 |
| 0-49 | PASS | 問題なし |

### Step 4: 分岐判定

#### PASS（スコア49以下）
```
設計レビュー完了。問題ありません。
→ REDフェーズへ進んでください
```

#### WARN（スコア50-79）
```
警告があります。確認してください。
1. 警告を確認してREDへ進む
2. PLANに戻って修正
```

#### BLOCK（スコア80以上）
```
重大な問題が検出されました。
→ PLANに戻って修正してください
（Progress Logに記録済み）
```

Cycle docのProgress Logに以下の形式で追記する:
```
- YYYY-MM-DD HH:MM [PLAN] plan-review BLOCK (score NN): reviewer「指摘要約」
```

## Reference

- エージェント定義: `../../agents/`
- スコアリング・出力形式: [reference.md](reference.md)
- designer 詳細・UI判定基準: [reference.md](reference.md)
