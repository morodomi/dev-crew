---
name: review
description: 統一レビュースキル。mode "plan"（設計レビュー）または "code"（コードレビュー）で動作。Risk-based scaling でエージェント数を最適化。REFACTORの次フェーズ。「レビューして」「review」で起動。
allowed-tools: Task, Read, Bash, Grep, Glob
---

# Unified Review

設計またはコードを Risk-based scaling でレビューする統一スキル。

## Mode Determination

| 引数/コンテキスト | Mode | 入力ソース |
|------------------|------|-----------|
| `--plan` or PLAN直後 | "plan" | Cycle doc PLAN セクション |
| `--code` or REFACTOR直後 | "code" | `git diff HEAD` |
| 引数なし | "code" (default) | `git diff HEAD` |

## Progress Checklist

```
review Progress:
- [ ] Step 0: Mode 判定
- [ ] Step 1: Risk Classification (決定論的)
- [ ] Step 2: Review Brief 生成 (haiku)
- [ ] Step 3: Lint-as-Code (code mode のみ)
- [ ] Step 4: Specialist Panel (並行起動, risk-gated)
- [ ] Step 5: Score Aggregation -> PASS/WARN/BLOCK
- [ ] Step 6: DISCOVERED -> gh issue create
```

## Workflow

### Step 0: Mode 判定

引数または直前フェーズから mode を決定し、ユーザーに明示出力する。
出力: `[REVIEW] Mode: plan (設計レビュー)` or `[REVIEW] Mode: code (コードレビュー)`

### Step 1: Risk Classification

`skills/review/risk-classifier.sh` で決定論的にリスクレベルを判定（LLM不使用）。
手順: [steps-subagent.md](steps-subagent.md)

### Step 2: Review Brief (haiku)

review-briefer (haiku) で diff/plan を圧縮した Brief を生成。

### Step 3: Lint-as-Code (code mode のみ)

静的解析ツール実行（ESLint/PHPStan/mypy等）。LLMコスト0。

### Step 4: Specialist Panel

Risk level に応じてエージェント数をスケール:

**Always-on (code mode)**:
- security-reviewer (NON-NEGOTIABLE)
- correctness-reviewer (NON-NEGOTIABLE)

**Always-on (plan mode)**:
- design-reviewer

**Risk-gated**:
- performance-reviewer (DB/perf flags)
- product-reviewer (API/user-facing flags)
- usability-reviewer (UI flags)

手順: [steps-subagent.md](steps-subagent.md)

### Step 5: Score Aggregation

| 最大スコア | 判定 | アクション |
|-----------|------|-----------|
| 80-100 | BLOCK | 修正必須 (plan→PLAN再設計 / code→RED/GREEN/REFACTOR) |
| 50-79 | WARN | 警告表示、継続可能 |
| 0-49 | PASS | 問題なし |

### Step 6: DISCOVERED -> Issue

Cycle doc の DISCOVERED セクションを確認し、未起票項目を `gh issue create` で起票。
詳細: [reference.md](reference.md#discovered-issue-起票)

## Reference

- 詳細: [reference.md](reference.md)
- Risk Classifier: [risk-classifier.sh](risk-classifier.sh)
