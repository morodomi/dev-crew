---
name: strategy
description: 企画フェーズスキル。要件理解→リサーチ→設計→GitHub Issue作成を人間と協働で実行。plan modeで開始、またはsearch-taskで次タスク選択後に起動。「strategy」「企画」「要件定義」で起動。
allowed-tools: Task, Read, Write, Bash, Grep, Glob, WebSearch, WebFetch, AskUserQuestion
---

# Strategy (Phase A: 企画フェーズ)

人間(PO) + AI PdM が協働で企画を行い、GitHub Issues を作成する。

## Progress Checklist

```
strategy Progress:
- [ ] Step 1: 要件理解
- [ ] Step 2: リサーチ
- [ ] Step 3: 設計
- [ ] Step 4: review(plan)
- [ ] Step 5: GitHub Issue 作成
```

## Workflow

### Step 1: 要件理解

人間から要件を聞き取り、以下を整理:
- **目的**: 何を達成したいか
- **背景**: なぜ必要か
- **制約**: 技術的/ビジネス的制約

### Step 2: リサーチ

必要に応じて調査を実行:
- **既存コード分析**: Grep/Glob で関連コードを調査
- **OSS 類似実装**: WebSearch で類似OSSの実装を調査
- **技術トレンド**: WebSearch で最新の技術動向を確認
- **ドキュメント**: WebFetch で公式ドキュメントを参照

### Step 3: 設計

調査結果を基にアーキテクチャを設計:
- タスク分解（1 issue = 1 task 粒度）
- 各タスクの Acceptance Criteria 定義
- 依存関係の整理

### Step 4: review(plan)

設計を review(plan) でレビュー:
```
Skill(dev-crew:review, args: "--plan")
```

- PASS → Step 5 へ
- WARN → 人間に確認後、Step 5 へ
- BLOCK → Step 3 に戻って修正

### Step 5: GitHub Issue 作成

各タスクを GitHub Issue として起票:

```bash
gh issue create --title "<タスクタイトル>" --body "$(cat <<'EOF'
## Context
<背景・目的>

## Acceptance Criteria
- [ ] <受入条件1>
- [ ] <受入条件2>

## Technical Notes
<技術的な注意点>

## Dependencies
<依存する issue>
EOF
)"
```

## Reference

- 詳細: [reference.md](reference.md)
