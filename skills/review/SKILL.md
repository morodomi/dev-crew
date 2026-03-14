---
name: review
description: 統一レビュースキル。mode "plan"（設計レビュー）または "code"（コードレビュー）で動作。Risk-based scaling でエージェント数を最適化。REFACTORの次フェーズ。「レビューして」「review」で起動。
allowed-tools: Task, Read, Edit, Bash, Grep, Glob
---

## Mode Determination

| 引数/コンテキスト | Mode | 入力ソース |
|------------------|------|-----------|
| `--plan` or PLAN直後 | "plan" | planファイル |
| `--code` or REFACTOR直後 | "code" | `git diff HEAD` |
| 引数なし | "code" (default) | `git diff HEAD` |

## Workflow

### Gate (mode別)

**plan mode**: planファイルの存在確認。なければ BLOCK: 「先に spec を実行してください」

**code mode only**:
- Cycle Doc Gate (frontmatter のみ): `for f in docs/cycles/*.md; do awk '/^---$/{c++;next} c==1{print}' "$f" | grep -q 'phase: DONE' || echo "$f"; done | head -1` → found: continue / not found: BLOCK(run spec)
- Phase Ordering Gate: Progress Log に `REFACTOR` の `Phase completed` 記録があるか確認。なければ BLOCK: 「先に refactor を実行してください」

Mode を判定し出力: `[REVIEW] Mode: plan` or `[REVIEW] Mode: code`

### Step 1-5: Review Pipeline

1. **Risk Classification**: `risk-classifier.sh` で決定論的判定
2. **Review Brief**: review-briefer (haiku) で圧縮 Brief 生成
3. **Lint-as-Code** (code mode のみ): 静的解析ツール実行
4. **Specialist Panel**: Always-on: security-reviewer + correctness-reviewer (code) / design-reviewer (plan)。Risk-gated: performance/product/usability-reviewer。詳細: [steps-subagent.md](steps-subagent.md)
5. **Score Aggregation**: 80-100=BLOCK(plan→PLAN再設計/code→RED/GREEN/REFACTOR) / 50-79=WARN / 0-49=PASS

### Cycle doc更新
Progress Log追記(`### {date} - REVIEW\n- {summary}\n- Phase completed`) + frontmatter更新(phase/updated)

### Step 7: DISCOVERED -> Issue

Cycle doc の DISCOVERED セクション未起票項目を `gh issue create` で起票。詳細: [reference.md](reference.md#discovered-issue-起票)

## Codex Integration

Codex 利用可能時、orchestrate が本スキルと Codex レビューを並行実行し、findings を統合する（competitive review）。単体 `/review` 実行時は Claude-side pipeline のみ動作する。詳細: [steps-codex.md](../orchestrate/steps-codex.md)

## Reference

- 詳細: [reference.md](reference.md)
- Risk Classifier: [risk-classifier.sh](risk-classifier.sh)
