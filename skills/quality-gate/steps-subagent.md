# Quality Gate - Subagent Mode

常に Subagent モードで実行する（環境変数に関わらず）。

## 6エージェント並行起動

Taskツールで6つのエージェントを並行起動（各エージェントの frontmatter model に準拠）:

```
Task(subagent_type: "dev-crew:correctness-reviewer", model: "sonnet", prompt: "...")
Task(subagent_type: "dev-crew:performance-reviewer", model: "sonnet", prompt: "...")
Task(subagent_type: "dev-crew:security-reviewer", model: "sonnet", prompt: "...")
Task(subagent_type: "dev-crew:guidelines-reviewer", model: "haiku", prompt: "...")
Task(subagent_type: "dev-crew:product-reviewer", model: "sonnet", prompt: "...")
Task(subagent_type: "dev-crew:usability-reviewer", model: "sonnet", prompt: "...")
# model: 各エージェントの agents/*.md frontmatter の model フィールドに対応
# guidelines-reviewer のみ haiku（ルールベース作業）、他は sonnet（判断力必要）
```

各エージェントに以下を渡す:

- 対象ファイル一覧（Step 1 で決定）
- 言語プラグイン情報（Step 2 で確認）

## 結果収集

各エージェントが独立に JSON を返す:

```json
{
  "blocking_score": 0-100,
  "issues": [...]
}
```

全エージェントの完了を待ち、Step 4（結果統合）へ進む。

## エラー時

並行起動失敗時は順次実行する。
