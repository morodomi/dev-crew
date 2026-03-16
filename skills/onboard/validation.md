# Generated Files Validation

onboard完了時の健全性チェック。FAILは警告のみ（修正は強制しない）。

## チェック項目

| # | ファイル | チェック | コマンド |
|---|---------|---------|---------|
| 1 | AGENTS.md | TDD Workflow セクション | grep -q "TDD Workflow" AGENTS.md |
| 2 | AGENTS.md | Post-Approve Action | grep -q "Post-Approve Action" AGENTS.md |
| 3 | CLAUDE.md | @AGENTS.md import | head -1 CLAUDE.md \| grep -q "@AGENTS.md" |
| 4 | docs/STATUS.md | 存在 | test -f docs/STATUS.md |
| 5 | .claude/rules/ | git-safety存在 | test -f .claude/rules/git-safety.md |
| 6 | .claude/rules/ | security存在 | test -f .claude/rules/security.md |
| 7 | CONSTITUTION.md | 存在確認 | test -f CONSTITUTION.md |

## 実行方法

各項目をgrepで検証し、結果を表示:
- PASS: チェック通過
- WARN: 不足あり（修正を推奨するが強制しない）
