---
name: review
description: 統一レビュースキル。mode "plan"（設計レビュー）または "code"（コードレビュー）で動作。Risk-based scaling でエージェント数を最適化。REFACTORの次フェーズ。「レビューして」「review」で起動。
allowed-tools: Task, Read, Edit, Bash, Grep, Glob
---

# Unified Review

設計またはコードを Risk-based scaling でレビューする統一スキル。

## Mode Determination

| 引数/コンテキスト | Mode | 入力ソース |
|------------------|------|-----------|
| `--plan` or PLAN直後 | "plan" | Cycle doc PLAN セクション |
| `--code` or REFACTOR直後 | "code" | `git diff HEAD` |
| 引数なし | "code" (default) | `git diff HEAD` |

## Workflow

### Step 0: Cycle doc確認（Hard Gate）

```bash
CYCLE_DOC=$(grep -L 'phase: DONE' docs/cycles/*.md 2>/dev/null | head -1)
```

| 結果 | アクション |
|------|-----------|
| 見つかった | Cycle doc を読み込んで続行 |
| 見つからない | BLOCK: 「進行中の Cycle doc がありません。kickoff を実行してください」で中断 |

**Phase Ordering Gate**: Progress Log に `REFACTOR` の `Phase completed` 記録があるか確認。なければ BLOCK: 「先に refactor を実行してください」

Mode を判定し出力: `[REVIEW] Mode: plan` or `[REVIEW] Mode: code`

### Step 1-5: Review Pipeline

1. **Risk Classification**: `risk-classifier.sh` で決定論的判定
2. **Review Brief**: review-briefer (haiku) で圧縮 Brief 生成
3. **Lint-as-Code** (code mode のみ): 静的解析ツール実行
4. **Specialist Panel**: Always-on: security-reviewer + correctness-reviewer (code) / design-reviewer (plan)。Risk-gated: performance/product/usability-reviewer。詳細: [steps-subagent.md](steps-subagent.md)
5. **Score Aggregation**: 80-100=BLOCK(plan→PLAN再設計/code→RED/GREEN/REFACTOR) / 50-79=WARN / 0-49=PASS

### Step 6: Cycle doc更新（Progress Log）

Cycle doc の Progress Log に追記し、frontmatter の `phase` を `REVIEW`、`updated` を現在時刻に更新:

```markdown
### YYYY-MM-DD HH:MM - REVIEW
- review(code) score:NN verdict:PASS/WARN/BLOCK
- Phase completed
```

### Step 7: DISCOVERED -> Issue

Cycle doc の DISCOVERED セクション未起票項目を `gh issue create` で起票。詳細: [reference.md](reference.md#discovered-issue-起票)

## Reference

- 詳細: [reference.md](reference.md)
- Risk Classifier: [risk-classifier.sh](risk-classifier.sh)
