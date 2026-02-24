---
name: reload
description: compact後にCycle docからコンテキストを復元する。「reload」「コンテキスト復元」で起動。
allowed-tools: Read, Glob, Grep
---

# Reload

compact後にCycle docからTDDサイクルのコンテキストを復元するスキル。

## Progress Checklist

```
reload Progress:
- [ ] 最新Cycle doc特定
- [ ] フェーズ・成果物の復元
- [ ] 復元サマリー表示
```

## Workflow

### Step 1: 最新Cycle doc特定

```bash
ls -t docs/cycles/*.md 2>/dev/null | head -1
```

Cycle docが見つからない場合:

```
Cycle docが見つかりません。
TDDサイクル外のため、reload不要です。
```

### Step 2: Cycle doc読み込み・フェーズ特定

Cycle docを全文読み込み、以下を把握:

| 項目 | 読み取り元 |
|------|-----------|
| 現在のフェーズ | `- status:` フロントマター |
| スコープ | Context / PLAN セクション |
| Test List | PLAN > Test List |
| 成果物 | Phase Summary > Artifacts |
| 決定事項 | Phase Summary > Decisions |
| Progress Log | 最新エントリ |

### Step 3: artifacts読み込み

Phase SummaryのArtifactsに記載されたファイルパスを読み込む。
存在しないファイルはスキップし、警告を表示。

### Step 4: 復元サマリー表示

```
================================================================================
Context Reload Complete
================================================================================
Cycle doc: [パス]
Phase: [現在のフェーズ]
Scope: [スコープ概要]
Artifacts loaded: [N files]
Next action: [フェーズに応じた次のアクション]
================================================================================
```

## Phase → Next Action マッピング

| Phase | Next Action |
|-------|-------------|
| INIT | /plan で設計を開始 |
| PLAN | /red でテスト作成を開始 |
| RED | /green で実装を開始 |
| GREEN | /refactor でリファクタリング |
| REFACTOR | /review でレビュー |
| REVIEW | /commit でコミット |
