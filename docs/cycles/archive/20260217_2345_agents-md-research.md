# Cycle: AGENTS.md調査

phase: DONE
issue: #24
date: 2026-02-17

## Goal

ブログ記事「AGENTS.md generator」を精査し、dev-crewプラグインに取り込むべき機能を調査・タスク分解する。取り込む必要がなければリジェクトする。

## Source

https://nyosegawa.github.io/posts/agents-md-generator/

## Scope

- 記事内容の調査・分析
- AGENTS.md の概念と dev-crew への適用可能性評価
- タスク分解とissue起票（採用時）
- リジェクト判断（不要時）

## Test List

N/A (調査タスク)

## Decision

**ADOPTED** - 以下の知見を onboard スキル改善として取り込む:

### 採用項目 (Socrates 反論反映後)

1. **セクション数上限**: root CLAUDE.md は 6 セクション以内。行数ではなく構造単位で制約
2. **Project Structure 条件化**: 自動検出時のみ生成。手動追加は任意
3. **AI Behavior Principles**: 現状維持 (Socrates 反論受け入れ: 全項目 dev-crew 固有で必須)
4. **陳腐化防止**: Maintenance Notes セクションではなく pre-commit hook で CLAUDE.md 最終更新 30日超警告
5. **HTML コメント構造保護**: 検証テスト PASS を条件に採用
6. **プレースホルダー**: 検出失敗フォールバックとして `[To be determined]` を限定導入

### 不採用項目

- AGENTS.md 生成 (Codex/Gemini 用、現時点で不要)
- 20-30行ハード制限 (TDD ワークフローに不適合)
- Maintenance Notes セクション (pre-commit hook で代替)

## DISCOVERED

- onboard テンプレート簡素化 → #30
- CLAUDE.md 陳腐化警告 hook → #31
- HTML コメント構造保護の検証 → #32
