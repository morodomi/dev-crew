# Cycle: Obsidian調査

phase: DONE (REJECTED)
issue: #25
date: 2026-02-17

## Goal

Zenn記事「Claude Code + Obsidian ワークフロー」を精査し、dev-crewプラグインまたは別プラグインに取り込むべき機能を提案・タスク分解する。取り込む必要がなければリジェクトする。

## Source

https://zenn.dev/fabrica/articles/2026-02-13_claude-code-obsidian-workflow

## Scope

- 記事内容の調査・分析
- 取り込み候補機能の特定
- タスク分解とissue起票（採用時）
- リジェクト判断（不要時）

## Test List

N/A (調査タスク)

## Decision

**REJECTED** - 以下の理由により取り込み不要と判断:

1. **スコープ外**: dev-crewはTDD/セキュリティ特化。ナレッジ管理は完全に別ドメイン
2. **汎用性が低い**: 個人のObsidian vault構造に強く依存し、プラグイン化しても再利用性が低い
3. **既存ツールで代替可能**: WebSearch + Write で記事のコア機能は実現可能
4. **iOS部分はスコープ外**: a-shell/iOSショートカットはClaude Codeプラグインの対象外

記事から得られた知見:
- Claude Codeスキルでファイル整理を自動化するパターンは参考になる
- frontmatter自動付与 + タグベースフォルダ振り分けは汎用テクニック

## DISCOVERED

(none)
