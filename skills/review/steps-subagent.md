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

plan mode は **plan file 前提**（Cycle doc 不在でも動作する。Cycle doc は sync-plan/承認後にのみ生成されるため、承認前の plan mode review はplan ファイル単体で完結する必要がある）: plan ファイルの Files to Change と PLAN セクションからファイルリストを生成する。

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

## Step 3.5: Reviewer Model 解決 (review_policy)

Specialist Panel 起動前に、policy 制御対象 reviewer（Code Mode の security-reviewer / correctness-reviewer / maintainability-reviewer、risk-gated の performance-reviewer / api-contract-reviewer / observability-reviewer、および flags-based の test-reviewer）について、`.claude/dev-crew.json` の review_policy を読みモデルを解決する:

1. `review_policy.reviewer_model`（既定 `self`）を読む
2. **`self` の場合**: reviewer は sonnet frontmatter に pin されているため、Task に `model:` を省略すると orchestrator の現行モデルではなく frontmatter の sonnet に落ちる。そのため **self なら orchestrator 自身の現モデルを Task に明示的に渡す**（省略しない）
3. **explicit 値**（sonnet/haiku/opus/fable）の場合: その model をそのまま Task に渡す
4. `escalate_high_to` が非 null かつ risk tier が HIGH の場合: reviewer_model の代わりに `escalate_high_to` を**同じ規則で解決してから**渡す（`self` なら手順2と同様に orchestrator の現モデルを明示。生の `self` を Task に渡さない）
5. **allowlist 外の値**（`self|sonnet|haiku|opus|fable` 以外）は `self` にフォールバック（fail-safe: 未定義 model literal を Task に渡さない）
6. **NON-NEGOTIABLE floor**: security-reviewer と correctness-reviewer は review_policy を読み model を解決した上でも、policy/score 不問で常時起動する。policy が制御するのはどのモデルで走るかであって、起動有無ではない（security review bypass を config で作らない）

**非対象（model literal 維持、policy 解決対象外）**: **Plan Mode の全 reviewer**（design-reviewer / test-reviewer / security-reviewer / performance-reviewer / change-safety-reviewer / impact-reviewer / resiliency-reviewer / designer 等）+ review-briefer（haiku）+ Code Mode の product-reviewer・usability-reviewer（haiku）。これらは既存の固定 model literal をそのまま使う。

## Step 4: Specialist Panel (並行起動)

Risk level と mode に応じてエージェントを選択し、**全エージェントを一括並行起動**:

### Code Mode

```
# Always-on (NON-NEGOTIABLE: security-reviewer/correctness-reviewer は policy/score 不問で常時起動)
Task(subagent_type: "dev-crew:security-reviewer", prompt: "Review Brief: [brief]. Lint results: [lint]. コードをセキュリティ観点でレビューせよ。")  # model: Step 3.5 の review_policy 解決モデル
Task(subagent_type: "dev-crew:correctness-reviewer", prompt: "Review Brief: [brief]. コードの正確性をレビューせよ。")  # model: Step 3.5 の review_policy 解決モデル
Task(subagent_type: "dev-crew:maintainability-reviewer", prompt: "Review Brief: [brief]. Lint results: [lint]. コードを保守性観点でレビューせよ。Fowler Code Smells 5カテゴリ（Bloaters, OO Abusers, Change Preventers, Dispensables, Couplers）+ SRP + 命名。")  # model: Step 3.5 の review_policy 解決モデル

# Risk-gated (MEDIUM/HIGH のみ)
Task(subagent_type: "dev-crew:performance-reviewer", prompt: "...")  # model: Step 3.5 解決モデル、DB/perf flags
Task(subagent_type: "dev-crew:api-contract-reviewer", prompt: "Review Brief: [brief]. Lint results: [lint]. APIの契約品質をレビューせよ。破壊的変更検出、REST設計品質、エラー構造の一貫性。")  # model: Step 3.5 解決モデル、API/endpoint flags
Task(subagent_type: "dev-crew:observability-reviewer", prompt: "Review Brief: [brief]. Lint results: [lint]. 可観測性をレビューせよ。エラーパスのログ有無、構造化ログ、trace ID伝播、メトリクス計装。correctness-reviewerとのdedup: 例外処理の存在有無はcorrectness担当、ログ出力品質はobservability担当。")  # model: Step 3.5 解決モデル、error-handling/logging flags
Task(subagent_type: "dev-crew:product-reviewer", model: "haiku", prompt: "...")       # API/user-facing flags
Task(subagent_type: "dev-crew:usability-reviewer", model: "haiku", prompt: "...")      # UI flags

# Flags-based (Risk level に関係なく、ファイルタイプフラグで起動)
Task(subagent_type: "dev-crew:test-reviewer", prompt: "Review Brief: [brief]. テストコード品質をレビューせよ。xUnit Test Patterns テストスメル（Fragile Test, Obscure Test, Mystery Guest, Conditional Test Logic, Test Code Duplication）、テスト独立性。")  # model: Step 3.5 解決モデル、test-file flags
```

### Plan Mode

```
# Always-on
Task(subagent_type: "dev-crew:review-briefer", model: "haiku", prompt: "...")  # Step 2 で実行済み
Task(subagent_type: "dev-crew:design-reviewer", model: "sonnet", prompt: "Review Brief: [brief]. 設計をスコープ・アーキテクチャ・リスク観点でレビューせよ。")
Task(subagent_type: "dev-crew:test-reviewer", model: "sonnet", prompt: "Review Brief: [brief]. Plan mode: TC カバレッジ、異常系、独立性、Given/When/Then を検証せよ。")

# Risk-gated (MEDIUM/HIGH のみ)
Task(subagent_type: "dev-crew:security-reviewer", model: "sonnet", prompt: "...")      # auth/security flags
Task(subagent_type: "dev-crew:product-reviewer", model: "haiku", prompt: "...")        # API/user-facing flags
Task(subagent_type: "dev-crew:performance-reviewer", model: "sonnet", prompt: "...")   # DB/perf flags
Task(subagent_type: "dev-crew:usability-reviewer", model: "haiku", prompt: "...")      # UI flags
Task(subagent_type: "dev-crew:designer", model: "sonnet", prompt: "...")               # UI + UI tech stack
Task(subagent_type: "dev-crew:change-safety-reviewer", model: "sonnet", prompt: "Review Brief: [brief]. ロールバック安全性・マイグレーション安全性を検証せよ。")  # migration/schema flags
Task(subagent_type: "dev-crew:impact-reviewer", model: "sonnet", prompt: "Review Brief: [brief]. 変更の連鎖影響と破壊範囲を分析せよ。")  # wide-change flags
Task(subagent_type: "dev-crew:resiliency-reviewer", model: "sonnet", prompt: "Review Brief: [brief]. 耐障害性・カスケード障害防止を検証せよ。")  # external-comm flags
```

PdM は各 reviewer の JSON を `$(mktemp -d)/<reviewer>.json` に保存する（Step 4.4 Output Validation の入力）。

## Step 4.4: Output Validation

`bash skills/review/severity-verdict.sh validate <dir>` を実行し、Step 4 で保存した各 reviewer JSON を検証する。

- 検証実行前に、起動した reviewer 数と保存した JSON 件数の一致を確認する（起動失敗・保存漏れの検出）
- 全 reviewer が OK（exit 0）なら Step 4.5 へ進む
- **INVALID を返した場合のみ**、該当 reviewer へ script が出した error 行を verbatim で含めて re-request する（**最大 1 回**）。LLM の主観による re-request は行わない
- 再 validate してもなお INVALID の場合、その reviewer 名を `--invalid <name>` として Step 5 の `severity-verdict.sh verdict` 呼び出しに渡す（fail-closed）。`security-reviewer` または `correctness-reviewer` が該当する場合、verdict は NON-NEGOTIABLE floor として BLOCK に固定される。それ以外の reviewer は WARN floor
- `DEGRADED: jq not found` の場合は script による検証をスキップし、PdM が Severity 基準表（reference.md 参照）を手動適用し、`severity-verdict.sh` と同一フォーマットの verdict 行（`BLOCK|WARN|PASS critical:N important:N optional:N invalid:M`）を Progress Log に記録して続行する

## Step 4.5: Devil's Advocate (Socrates)

Specialist Panel 完了後、Socrates を起動して reviewer の判定妥当性を検証する。Socrates は反論+選択肢を返すのみ（advisor 原則維持）。Escalation 判定は PdM が行う。

```
Task(subagent_type: "dev-crew:socrates", model: "opus", prompt: "
phase: review:[plan|code]
severity_counts: [reviewer 別 raw 件数（Synthesis 前の critical/important/optional 内訳）]
reviewer_summary: [各reviewerの severity 内訳と issues サマリ]
pdm_proposal: [auto-verdictに基づく判断提案: PASS/WARN/BLOCK]
cycle_doc: [cycle docパス。plan mode で Cycle doc 不在時（承認前）は plan ファイルパスを代わりに渡す]

各 reviewer の判定が忖度で甘くなっていないか検証せよ。
特に: important/critical の issue 数に対して見落とし・二次影響がある場合、
変更の二次影響を reviewer が見逃している場合を指摘せよ。
")
```

PdM は Socrates の反論を踏まえ、Verdict Escalation 基準（reference.md 参照）に基づき verdict の昇格を判断する。

## Step 5: Verdict Aggregation

### Findings Synthesis

Specialist Panel (Step 4) と Socrates (Step 4.5) 完了後、全 reviewer の findings を以下の手順で統合する。**Socrates は raw severity_counts (各 reviewer 個別の critical/important/optional 件数) を入力に取り、Synthesis は重複排除後の accepted findings (accept-apply + accept-defer) を確定する** — 時系列契約として両者を区別する。

1. **重複排除**: 同一 file:line への複数 reviewer 指摘は最も詳細な 1 件に集約。集約元 reviewer 名を併記
2. **3-category 分類** (`rules/review-triage.md` を SSOT として参照。定義は同 rule の Findings 3-Category Triage 節を verbatim 適用)
3. **raw finding index 保持**: 重複排除で落とした原 findings を Cycle doc の `## Raw Findings` セクションに append (synthesis 段階で証拠を失わない)。plan mode で Cycle doc 不在時（承認前）は append 先がないため、raw findings をそのターンの応答に含めて出力する（skip）
4. **集計入力**: PdM が triage 結果（severity+category）を triage.json に書き、`bash skills/review/severity-verdict.sh verdict <triage.json> [--invalid <name>]...` を実行する。その verdict 行（`BLOCK|WARN|PASS critical:N important:N optional:N invalid:M`）を Progress Log に記録する。下記 Verdict Aggregation サブセクションの判定基準は **この verdict 行** を根拠とする
   - 出力が `INVALID-TRIAGE: <理由>` の場合: triage.json を修正して再実行する（黙殺 PASS の禁止）
   - 出力が `DEGRADED: jq not found` の場合: PdM が Severity 基準表（reference.md 参照）を手動適用し、同一フォーマットの verdict 行を Progress Log に記録する

並列 reviewer (HIGH tier で 7 agents) の出力を単純連結すると synthesis 段階で context overflow する。category 分類 + raw index 保持で「集約後の判断」と「証拠保全」を両立する。

### Verdict Aggregation

Findings Synthesis 手順4の verdict 行（accept-apply/accept-defer の severity 集計、reject カテゴリは集計外）を判定基準とする（designer はスコア対象外（severity 集計にも含めない））:

| Severity | 判定 | アクション |
|----------|------|-----------|
| critical ≥ 1 | BLOCK | 修正必須 (下記テンプレート参照) |
| important ≥ 1 (critical 0) | WARN | 警告確認 |
| いずれもなし | PASS | 問題なし |

### BLOCK 時の mode 別出力テンプレート

plan mode:
```
[REVIEW] BLOCK (critical:N important:N): PLAN フェーズに戻って再設計してください。
指摘事項: ...
```

code mode:
```
[REVIEW] BLOCK (critical:N important:N): RED/GREEN/REFACTOR のいずれかに戻って修正してください。
指摘事項: ...
```

code mode、または plan mode で Cycle doc が既に存在する場合、Cycle doc の Progress Log に記録:
```
- YYYY-MM-DD HH:MM [REVIEW] review MODE (critical:N important:N): verdict
```
plan mode で Cycle doc 不在時（承認前）は記録先がないため skip（レビュー結果はそのターンの応答で報告する）。

## Step 6: DISCOVERED

code mode、または plan mode で Cycle doc が既に存在する場合: PASS/WARN なら Cycle doc の DISCOVERED セクションを確認し、未起票項目を `gh issue create` で起票。
plan mode で Cycle doc 不在時（承認前）: skip（DISCOVERED 追跡は承認後の Cycle doc 生成後に一元化する）。
詳細: [reference.md](reference.md#discovered-issue-起票)

## エラーハンドリング

- 並行起動失敗時は順次実行にフォールバック
- Specialist が Brief 不十分と判断 → raw diff で再実行 (Automatic Fallback)
