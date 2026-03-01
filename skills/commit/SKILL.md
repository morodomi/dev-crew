---
name: commit
description: 変更をGitコミットしてTDDサイクルを完了する。REVIEWの次フェーズ。「コミットして」「commit」で起動。
allowed-tools: Read, Bash
---

# TDD COMMIT Phase

変更をGitコミットしてTDDサイクルを完了する。

## Progress Checklist

```
COMMIT Progress:
- [ ] git status/diff 確認
- [ ] Pre-commit Hook確認
- [ ] Cycle doc更新 (phase: DONE)
- [ ] STATUS.md 更新
- [ ] git add & commit
- [ ] サイクル完了
- [ ] Auto-Learn チェック
```

## Workflow

### Step 1: 変更確認

```bash
git status
git diff --stat
```

### Step 2: Pre-commit Hook確認

コミット時のテスト自動実行を確認:

```bash
ls .husky/pre-commit .git/hooks/pre-commit 2>/dev/null
```

| 状態 | メッセージ |
|------|-----------|
| hookあり | コミット時に自動実行されます |
| hookなし | 手動でテスト実行を推奨（reviewで実行済みならOK） |

### Step 3: Cycle doc更新

phase を DONE に変更。Next Stepsを更新。

### Step 4: docs/STATUS.md 更新

```bash
gh issue list --limit 10 --json number,title,labels
ls -t docs/cycles/*.md | head -5
```

STATUS.md を最新状態に更新。

### Step 5: コミットメッセージ生成

**Type**: feat / fix / refactor / test

Cycle doc の issue 参照（`issue: #NN` or `issue: ...`）を確認し、コミットメッセージに含める:

```
<type>: <subject> (#<issue_number>)

<body>

Refs #<issue_number>
Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

issue 参照がない場合は `Refs #` 行を省略する。

### Step 6: git add & git commit

```bash
git add <files>
git commit -m "..."
```

### Step 7: サイクル完了

```
TDDサイクル完了: [hash] - [機能名]
次: git push / init で新サイクル開始
```

### Step 8: Auto-Learn (Optional)

`DEV_CREW_AUTO_LEARN=1` かつ観測数 20件以上で learn スキルを自動実行。
失敗時は警告のみ (best-effort)。詳細: [reference.md](reference.md#auto-learn)

## Reference

- 詳細: [reference.md](reference.md)
- Gitコンベンション: `.claude/rules/git-conventions.md`
