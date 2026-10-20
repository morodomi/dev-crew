---
name: commit
description: 変更をGitコミットしてTDDサイクルを完了する。REVIEWの次フェーズ。「コミットして」「commit」で起動。
allowed-tools: Read, Write, Edit, Bash
---

## Workflow

### Cycle Doc Gate
`for f in docs/cycles/*.md; do [ -f "$f" ] || continue; fm=$(awk '/^---$/{c++;next} c==1{print}' "$f"); echo "$fm" | grep -q '^phase:' || continue; echo "$fm" | grep -q 'phase: DONE' && continue; printf '%s\t%s\n' "$(echo "$fm" | awk 'sub(/^updated: */,""){gsub(/T/," ");print;exit}')" "$f"; done | sort | tail -1 | cut -f2` → found: continue / not found: BLOCK(run spec)

**Phase Ordering Gate**: Progress Log に `REVIEW` の `Phase completed` 記録があるか確認。なければ BLOCK: 「先に review を実行してください」

**Test List Completion Gate**: Test List の TODO/WIP/DISCOVERED に未完了項目（`- [ ] TC-`）が残っていれば BLOCK。DISCOVERED残項目は review の DISCOVERED→Issue 処理に戻す。詳細: [reference.md](reference.md#test-list-completion-gate)

**Progress Log Completeness Gate**: Progress Log に RED/GREEN/REFACTOR/REVIEW の全4フェーズの `Phase completed` 記録があるか確認。不足フェーズがあれば BLOCK。詳細: [reference.md](reference.md#progress-log-completeness-gate)

### Pre-COMMIT Gate (deterministic)

Cycle doc の Progress Log を確認し、以下が全て満たされなければ BLOCK:

1. **REVIEW完了**: Progress Log に `### ... - REVIEW` セクションがあり、`Phase completed` 記録がある
2. **Codex review記録** (`which codex` 成功時のみ): 最後の REVIEW 節に件数の行 `- Codex review: 直す N / 人間に戻す M / 記録のみ K`（または Codex 失敗時の代行の形）がある
3. **retro_status check**: retro_status: captured / resolved で PASS。none で BLOCK (cycle-retrospective 実行)、field 不在も BLOCK（frontmatter に `retro_status: none` を足して cycle-retrospective を実行）

```bash
# 最後の `### ... - REVIEW` 見出しから次の `### ` 見出しの手前まで
SEC=$(awk '/^```/{fence=!fence} !fence&&/^### /{on=($0 ~ /^### .* - REVIEW/); if(on)buf=""} on{buf=buf $0 "\n"} END{printf "%s",buf}' "$CYCLE_DOC")
# 1. REVIEW チェック
grep -qi 'Phase completed' <<<"$SEC"
# 2. Codex review チェック（codex利用可能時のみ）
which codex && grep -qE '^- Codex review: (失敗（[^）]*）。adversarial-reviewer で代行: )?直す [0-9]+ / 人間に戻す [0-9]+ / 記録のみ [0-9]+' <<<"$SEC"
```

いずれか失敗 → BLOCK（不足ステップを案内）

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
| AGENTS.md | skills/ or agents/ 変更時 | cross-toolセクションの更新 |
| CLAUDE.md | skills/ or agents/ 変更時 | Skills セクションの更新 |

```bash
git diff --name-only HEAD | grep -qE '^(skills|agents)/' && echo "UPDATE" || echo "SKIP"
```

Progress Log追記(`### {date} - COMMIT\n- {summary}\n- Phase completed`) + frontmatter更新(phase/updated)

### Step 4: コミットメッセージ生成 + 実行

Type: feat / fix / refactor / test。Cycle doc の issue 参照を含める。詳細: [reference.md](reference.md#commit-message)

コミットメッセージ末尾のトレーラーブロックに `Cycle-Doc: <Cycle Doc Gate で解決した active cycle doc パス>` を必ず含める（repo-relative パス 1 件、`Co-Authored-By:` と同じトレーラーブロック内）。詳細: [reference.md](reference.md#commit-message)

```bash
git add <files> && git commit -m "..."
```

### Step 5: サイクル完了 + レビュー結果サマリー

`TDDサイクル完了: [hash] - [機能名]` を出力。

その後、Cycle doc Progress Log から REVIEW findings を読み取り、以下のサマリーを出力:

```
## Review Findings サマリー
- 指摘数: N件 (直す N / 人間に戻す M / 記録のみ K)
- 主な修正: [直すにした指摘の要約]
- DISCOVERED: [記録のみにして起票した項目]
- 人間に戻した問い: [人間に戻した指摘の問い]
```

ユーザーが「何を指摘されて、どう修正したか」を commit 後に確認できる情報提供。
ゲートではなく情報出力のため、findings がなくても BLOCK しない。

### Step 6: Auto-Learn (Optional)

`DEV_CREW_AUTO_LEARN=1` かつ観測数 20件以上で learn スキル自動実行。詳細: [reference.md](reference.md#auto-learn)

## Reference

- 詳細: [reference.md](reference.md)
- Gitコンベンション: `.claude/rules/git-conventions.md`（`local-git-conventions.md` があれば併せて）
