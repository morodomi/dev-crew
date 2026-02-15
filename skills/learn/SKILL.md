---
name: learn
description: "セッションからパターンを抽出し instinct として蓄積する。「learn」「パターン抽出」「セッション振り返り」で起動。"
allowed-tools: Task, Read, Write, Bash, Grep, Glob
---

# Learn - セッションパターン抽出

セッションの作業パターンを検出し、instinct (構造化パターン) として蓄積する。

## 前提

- プロジェクトディレクトリ内で実行すること
- Git 管理下であること (git log / git diff を使用)

## 実行手順

### Step 1: 初回チェック (Empty State)

蓄積先ディレクトリを確認。存在しない場合は自動作成しオンボーディングメッセージを表示:

```
meta-skills へようこそ。
learn はセッションの作業パターンを記録し、evolve でスキルに進化させます。
初回セットアップを実行しました。
```

```bash
mkdir -p .claude/meta-skills/instincts/
```

### Step 2: 入力ソース収集

以下の情報を収集する:

| ソース | コマンド |
|--------|---------|
| Cycle doc | `ls -t docs/cycles/*.md 2>/dev/null \| head -1` |
| 変更履歴 | `git log --oneline -20` |
| 変更ファイル | `git diff --name-only HEAD~5..HEAD` |
| observations | `cat .claude/meta-skills/observations/log.jsonl 2>/dev/null` |

### Step 3: ユーザー補足情報

AskUserQuestion で確認:
- 「このセッションで気づいたパターンはありますか?」
- 選択肢: エラー解決 / ワークフロー改善 / ツール選好 / 特になし

### Step 4: observer エージェントに委譲

Task tool で observer を起動し、収集した入力ソースを渡す:

```
Task(subagent_type: "dev-crew:observer", prompt: "...")
```

### Step 5: 品質フィルタ + 保存

observer の出力から instinct を選別:

| confidence | 判定 |
|------------|------|
| >= 0.5 | 保存 (.claude/meta-skills/instincts/ に JSONL 追記) |
| < 0.5 | 破棄 (理由付きで報告) |

confidence >= 0.8 の instinct は MEMORY.md 昇格候補としてユーザーに提示する。棲み分けルール詳細: [reference.md](reference.md#memorymd-との棲み分け)

### Step 6: 結果報告

```
N 件のパターンを保存しました。
現在の蓄積: X 件。evolve 可能まであと Y 件。
```

## Reference

詳細: [reference.md](reference.md)
