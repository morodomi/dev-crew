---
name: commit
description: 変更をGitコミットしてTDDサイクルを完了する。REVIEWの次フェーズ。「コミットして」「commit」で起動。
allowed-tools: Read, Write, Edit, Bash
---

## Workflow

### Cycle Doc Gate
`grep -L 'phase: DONE' docs/cycles/*.md | head -1` → found: continue / not found: BLOCK(run kickoff)

**Phase Ordering Gate**: Progress Log に `REVIEW` の `Phase completed` 記録があるか確認。なければ BLOCK: 「先に review を実行してください」

**Test List Completion Gate**: Test List の TODO/WIP/DISCOVERED に未完了項目（`- [ ] TC-`）が残っていれば BLOCK。DISCOVERED残項目は review の DISCOVERED→Issue 処理に戻す。詳細: [reference.md](reference.md#test-list-completion-gate)

**Progress Log Completeness Gate**: Progress Log に KICKOFF/RED/GREEN/REFACTOR/REVIEW の全5フェーズの `Phase completed` 記録があるか確認。不足フェーズがあれば BLOCK。詳細: [reference.md](reference.md#progress-log-completeness-gate)

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

Progress Log追記(`### {date} - COMMIT\n- {summary}\n- Phase completed`) + frontmatter更新(phase/updated)

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
