---
name: commit
description: 変更をGitコミットしてTDDサイクルを完了する。REVIEWの次フェーズ。「コミットして」「commit」で起動。
allowed-tools: Read, Write, Edit, Bash
---

# TDD COMMIT Phase

変更をGitコミットしてTDDサイクルを完了する。

## Workflow

### Step 1: Cycle doc確認（Hard Gate）

```bash
CYCLE_DOC=$(grep -L 'phase: DONE' docs/cycles/*.md 2>/dev/null | head -1)
```

| 結果 | アクション |
|------|-----------|
| 見つかった | Cycle doc を読み込んで続行 |
| 見つからない | BLOCK: 「進行中の Cycle doc がありません。kickoff を実行してください」で中断 |

**Phase Ordering Gate**: Progress Log に `REVIEW` の `Phase completed` 記録があるか確認。なければ BLOCK: 「先に review を実行してください」

### Step 2: 変更確認 + Pre-commit Hook

```bash
git status && git diff --stat
ls .husky/pre-commit .git/hooks/pre-commit 2>/dev/null
```

### Step 3: ドキュメント更新

| ドキュメント | 条件 | 更新内容 |
|------------|------|---------|
| Cycle doc | 常に | phase: DONE, Progress Log に COMMIT 記録 |
| STATUS.md | 常に | 完了タスクを Completed に移動 |
| README.md | skills/ or agents/ 変更時 | スキル一覧・構成の更新 |
| CLAUDE.md | skills/ or agents/ 変更時 | Skills セクションの更新 |

```bash
git diff --name-only HEAD | grep -qE '^(skills|agents)/' && echo "UPDATE" || echo "SKIP"
```

Progress Log に追記し、frontmatter の `phase` を `DONE`、`updated` を現在時刻に更新:

```markdown
### YYYY-MM-DD HH:MM - COMMIT
- Committed: [hash]
- Phase completed
```

### Step 4: コミットメッセージ生成 + 実行

Type: feat / fix / refactor / test。Cycle doc の issue 参照を含める。詳細: [reference.md](reference.md#commit-message)

```bash
git add <files> && git commit -m "..."
```

### Step 5: サイクル完了

`TDDサイクル完了: [hash] - [機能名]` を出力。

### Step 6: Auto-Learn (Optional)

`DEV_CREW_AUTO_LEARN=1` かつ観測数 20件以上で learn スキル自動実行。詳細: [reference.md](reference.md#auto-learn)

## Reference

- 詳細: [reference.md](reference.md)
- Gitコンベンション: `.claude/rules/git-conventions.md`
