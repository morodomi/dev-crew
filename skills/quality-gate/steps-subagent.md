# Quality Gate - Subagent Mode

常に Subagent モードで実行する（環境変数に関わらず）。

## 6エージェント並行起動

Taskツールで6つのエージェントを **model: sonnet** で**並行**起動:

```
Task(subagent_type: "dev-crew:correctness-reviewer", model: "sonnet", prompt: "...")
Task(subagent_type: "dev-crew:performance-reviewer", model: "sonnet", prompt: "...")
Task(subagent_type: "dev-crew:security-reviewer", model: "sonnet", prompt: "...")
Task(subagent_type: "dev-crew:guidelines-reviewer", model: "sonnet", prompt: "...")
Task(subagent_type: "dev-crew:product-reviewer", model: "sonnet", prompt: "...")
Task(subagent_type: "dev-crew:usability-reviewer", model: "sonnet", prompt: "...")
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
