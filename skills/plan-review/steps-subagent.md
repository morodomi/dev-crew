# Plan Review - Subagent Mode

常に Subagent モードで実行する（環境変数に関わらず）。

## 実行フロー

### Step A: UI関連判定

Cycle doc から以下を確認し、UI関連かどうかを判定する:

1. Environment セクション → UI 技術スタック（React, Vue, Flutter, Next.js 等）
2. In Scope → UI コンポーネントファイルパス（components/, views/, pages/ 等）
3. 説明文 → UI/UX キーワード

いずれか該当 → UI関連 TRUE（6エージェント起動）
すべて非該当 → UI関連 FALSE（5エージェント起動）

判定基準の詳細: [reference.md](reference.md)

### Step B: エージェント同時起動

UI関連判定の結果に応じて、**全エージェントを一括並行起動**する:

**UI関連 FALSE（5エージェント）:**

```
Task(subagent_type: "dev-crew:scope-reviewer", model: "sonnet", prompt: "...")
Task(subagent_type: "dev-crew:architecture-reviewer", model: "sonnet", prompt: "...")
Task(subagent_type: "dev-crew:risk-reviewer", model: "sonnet", prompt: "...")
Task(subagent_type: "dev-crew:product-reviewer", model: "sonnet", prompt: "...")
Task(subagent_type: "dev-crew:usability-reviewer", model: "sonnet", prompt: "...")
# model: 各エージェントの agents/*.md frontmatter の model フィールドに対応
```

**UI関連 TRUE（6エージェント）:**

上記5つに加え、designer を同時に起動:

```
Task(subagent_type: "dev-crew:designer", model: "sonnet", prompt: "...")
# model: agents/designer.md frontmatter の model フィールドに対応
```

各 reviewer に Cycle doc の PLAN セクション（設計方針、Test List、変更予定ファイル）を渡す。

designer には追加で以下を渡す（Cycle doc から抽出）:
- target_audience: Environment/Scope から対象ユーザー層を特定（日本向け/海外向け/両方）
- ui_scope: In Scope から UI 変更対象の範囲を特定

## 結果収集

5 reviewer は JSON を返す:

```json
{
  "blocking_score": 0-100,
  "issues": [...]
}
```

designer は Markdown（UI/UX Design Guidelines）を返す（blocking_score なし、スコア対象外）。

全エージェントの完了を待ち、Step 3（結果統合）へ進む。

## エラーハンドリング

並行起動失敗時は順次実行にフォールバック。
