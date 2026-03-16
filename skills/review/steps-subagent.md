# Unified Review - Subagent Mode

常に Subagent モードで実行する（環境変数に関わらず）。

> **NOTE**: Codex 利用可能時、orchestrate が本スキルと並行して Codex レビューを実行し、findings を統合する。Codex 側の手順は [steps-codex.md](../orchestrate/steps-codex.md) を参照。

## Step 0: Mode Notification

mode 決定後、ユーザーに明示出力する:

```
[REVIEW] Mode: plan (設計レビュー)
[REVIEW] Mode: code (コードレビュー)
```

## Step 1: Risk Classification

決定論的にリスクレベルを判定（LLM不使用）:

```bash
bash skills/review/risk-classifier.sh
# Output: "LOW|MEDIUM|HIGH score:NN"
```

plan mode の場合は Cycle doc の変更予定ファイルとPLANセクションからファイルリストを生成する。

### Risk-Based Agent Scaling

| Level | Points | Plan Review | Code Review |
|-------|--------|:-----------:|:-----------:|
| LOW | 0-29 | 2 agents | 4 agents |
| MEDIUM | 30-59 | 3-4 agents | 5-6 agents |
| HIGH | 60+ | 5-6 agents | 6-7 agents |

## Step 2: Review Brief

review-briefer (haiku) で Brief を生成:

```
Task(subagent_type: "dev-crew:review-briefer", model: "haiku", prompt: "以下のdiff/planからReview Briefを生成せよ。mode: [plan|code]. 内容: [diff or PLAN section]")
```

Brief は全 Specialist に渡される入力トークン圧縮用サマリー。

## Step 3: Lint-as-Code (code mode のみ)

code mode の場合、静的解析ツールを実行（LLMコスト0）:

```bash
# PHP
./vendor/bin/phpstan analyse --level=8 2>&1 || true
./vendor/bin/pint --test 2>&1 || true
# Python
mypy --strict src/ 2>&1 || true
black --check . 2>&1 || true
# TypeScript
npx tsc --noEmit 2>&1 || true
npx eslint . 2>&1 || true
```

Lint 結果は Specialist Panel に渡す（旧ガイドラインレビューの代替）。

## Step 4: Specialist Panel (並行起動)

Risk level と mode に応じてエージェントを選択し、**全エージェントを一括並行起動**:

### Code Mode

```
# Always-on (NON-NEGOTIABLE)
Task(subagent_type: "dev-crew:security-reviewer", model: "sonnet", prompt: "Review Brief: [brief]. Lint results: [lint]. コードをセキュリティ観点でレビューせよ。")
Task(subagent_type: "dev-crew:correctness-reviewer", model: "sonnet", prompt: "Review Brief: [brief]. コードの正確性をレビューせよ。")
Task(subagent_type: "dev-crew:maintainability-reviewer", model: "sonnet", prompt: "Review Brief: [brief]. Lint results: [lint]. コードを保守性観点でレビューせよ。Fowler Code Smells 5カテゴリ（Bloaters, OO Abusers, Change Preventers, Dispensables, Couplers）+ SRP + 命名。")

# Risk-gated (MEDIUM/HIGH のみ)
Task(subagent_type: "dev-crew:performance-reviewer", model: "sonnet", prompt: "...")  # DB/perf flags
Task(subagent_type: "dev-crew:api-contract-reviewer", model: "sonnet", prompt: "Review Brief: [brief]. Lint results: [lint]. APIの契約品質をレビューせよ。破壊的変更検出、REST設計品質、エラー構造の一貫性。")  # API/endpoint flags
Task(subagent_type: "dev-crew:observability-reviewer", model: "sonnet", prompt: "Review Brief: [brief]. Lint results: [lint]. 可観測性をレビューせよ。エラーパスのログ有無、構造化ログ、trace ID伝播、メトリクス計装。correctness-reviewerとのdedup: 例外処理の存在有無はcorrectness担当、ログ出力品質はobservability担当。")  # error-handling/logging flags
Task(subagent_type: "dev-crew:product-reviewer", model: "haiku", prompt: "...")       # API/user-facing flags
Task(subagent_type: "dev-crew:usability-reviewer", model: "haiku", prompt: "...")      # UI flags
```

### Plan Mode

```
# Always-on
Task(subagent_type: "dev-crew:review-briefer", model: "haiku", prompt: "...")  # Step 2 で実行済み
Task(subagent_type: "dev-crew:design-reviewer", model: "sonnet", prompt: "Review Brief: [brief]. 設計をスコープ・アーキテクチャ・リスク観点でレビューせよ。")

# Risk-gated (MEDIUM/HIGH のみ)
Task(subagent_type: "dev-crew:security-reviewer", model: "sonnet", prompt: "...")      # auth/security flags
Task(subagent_type: "dev-crew:product-reviewer", model: "haiku", prompt: "...")        # API/user-facing flags
Task(subagent_type: "dev-crew:performance-reviewer", model: "sonnet", prompt: "...")   # DB/perf flags
Task(subagent_type: "dev-crew:usability-reviewer", model: "haiku", prompt: "...")      # UI flags
Task(subagent_type: "dev-crew:designer", model: "sonnet", prompt: "...")               # UI + UI tech stack
```

## Step 5: Score Aggregation

全エージェントの blocking_score を集計（designer はスコア対象外）:

| 最大スコア | 判定 | アクション |
|-----------|------|-----------|
| 80-100 | BLOCK | 修正必須 (下記テンプレート参照) |
| 50-79 | WARN | 警告確認 |
| 0-49 | PASS | 問題なし |

### BLOCK 時の mode 別出力テンプレート

plan mode:
```
[REVIEW] BLOCK (score NN): PLAN フェーズに戻って再設計してください。
指摘事項: ...
```

code mode:
```
[REVIEW] BLOCK (score NN): RED/GREEN/REFACTOR のいずれかに戻って修正してください。
指摘事項: ...
```

Cycle doc の Progress Log に記録:
```
- YYYY-MM-DD HH:MM [REVIEW] review MODE (score NN): verdict
```

## Step 6: DISCOVERED

PASS/WARN の場合、Cycle doc の DISCOVERED セクションを確認し、未起票項目を `gh issue create` で起票。
詳細: [reference.md](reference.md#discovered-issue-起票)

## エラーハンドリング

- 並行起動失敗時は順次実行にフォールバック
- Specialist が Brief 不十分と判断 → raw diff で再実行 (Automatic Fallback)
