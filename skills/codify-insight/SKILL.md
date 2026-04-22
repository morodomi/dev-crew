---
name: codify-insight
description: "TDD サイクルの retrospective insights を codify/defer/no-codify で明示判断する decide gate スキル。次サイクル開始時に /orchestrate Block 0 から自動起動。「codify」「codify-insight」「insight codify」「次サイクル開始時」で手動起動も可。"
allowed-tools: Read, Edit, AskUserQuestion, Glob
---

# codify-insight

## Workflow

### Hard Gate

Captured cycles scan (frontmatter-only):

```bash
for f in docs/cycles/*.md; do
  awk '/^---$/{c++;next} c==1{print}' "$f" | grep -q 'retro_status: captured' && echo "$f"
done
```

非空 → 処理対象 cycles を収集。
空 → no-op exit 0: 「No captured cycles found. Nothing to codify.」を出力して終了。

### Idempotency Check

各 cycle doc の `retro_status` を確認:
- `retro_status: resolved` → skip（既に全 insight 判定済み）
- `retro_status: none` → skip（retrospective 未実行）
- `retro_status: captured` → 処理対象

`## Codify Decisions` セクション内の `### Insight N` heading 存在 = 該当 insight 判定済み。
partial 完了時は未判定 insight のみ処理し、captured を維持して再起動で残分を処理。

### Decide Gate (per insight)

`## Retrospective` セクションから各 insight を読み込み、以下の 3 択で AskUserQuestion:

```
Insight N: <insight 概要>
1. codify now   — destination (rule/skill/instinct/new-cycle/inline-update) を明記
2. defer with reason — 理由必須
3. no-codify    — 理由任意
```

### Output

Cycle doc EOF に `## Codify Decisions` セクションを append (APPEND-ONLY):

```markdown
## Codify Decisions

### Insight N
- **Decision**: codified
- **Destination**: rule
- **Reason**: (optional)
- **Decided**: YYYY-MM-DD HH:MM
```

既存 `## Retrospective` セクションは一切変更しない。

### State Transition

全 insight 判定完了時: `retro_status: captured` → `resolved` + `updated` を更新。
partial 完了時: frontmatter 遷移なし（captured 維持）。

### Exit Contract (orchestrate 連携)

cycle-retrospective precedent 準拠の block-or-complete 契約:
- **全 captured cycles が resolved** → exit 0。orchestrate Block 0 は次ステップへ進行。
- **User mid-gate abort** → exit 1 + stderr「codify-insight aborted by user. orchestrate should BLOCK and re-invoke /orchestrate」。orchestrate は BLOCK (cycle-retrospective abort と同じ pattern)。
- **captured 残存 (skill 異常終了)** → orchestrate は次回 /orchestrate 起動時に再度 Block 0 codify gate でスキャン、再処理。

## Reference

詳細: [reference.md](reference.md)
