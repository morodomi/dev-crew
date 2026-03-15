---
name: onboard
description: 既存プロジェクトにTDD環境をセットアップする。フレームワーク検出、AGENTS.md + CLAUDE.md生成、docs/STATUS.md作成を行う。「TDDセットアップ」「onboard」「プロジェクト初期化」で起動。
allowed-tools: Read, Write, Bash, Grep, Glob
---

# TDD Onboard

## Progress Checklist

```
Onboard Progress:
- [ ] プロジェクト分析（フレームワーク/テストツール検出）
- [ ] プロジェクト状態判定（fresh/existing-no-tdd/dev-crew-installed）
- [ ] 検出結果をユーザーに確認
- [ ] docs/ 構造作成（cycles/, README.md, STATUS.md）
- [ ] AGENTS.md 生成（cross-tool情報、最大5セクション）
- [ ] CLAUDE.md 生成（@AGENTS.md import + AI Behavior、既存あればマージ）
- [ ] 階層CLAUDE.md推奨（任意）
- [ ] .claude/ 構造生成（rules/, hooks/）
- [ ] Pre-commit Hook確認（推奨）
- [ ] 初期Cycle doc作成
- [ ] Next Steps 表示
```

## Workflow

### Step 1: プロジェクト分析

フレームワークとツールを検出。加えてプロジェクト状態を判定:
- `fresh` / `existing-no-tdd` / `dev-crew-installed`

状態判定ロジック、**symlink 検出**、検出コマンドは [reference.md](reference.md) 参照。

### Step 2: 検出結果確認

AskUserQuestion で確認:
- フレームワーク、パッケージマネージャ
- プロジェクト状態（モード）と対応方針
- `dev-crew-installed` → 更新/リフレッシュ範囲の確認

モード別確認項目は [reference.md](reference.md) 参照。

### Step 3: docs/ 構造作成

```bash
mkdir -p docs/cycles
```

作成ファイル:
- `docs/README.md` - ドキュメント索引
- `docs/STATUS.md` - プロジェクト状況（commitで自動更新）

テンプレートは [reference.md](reference.md) を参照。

### Step 4: AGENTS.md + CLAUDE.md 生成 (Two-File Model)

AGENTS.md = cross-tool情報（他AIツールも利用可）、CLAUDE.md = Claude固有設定（`@AGENTS.md` importで連携）。

#### AGENTS.md (cross-tool、最大5セクション)

- `fresh` → テンプレートから生成
- `existing-no-tdd` / `dev-crew-installed` → 既存あればバックアップ後マージ
- Content: Overview, Quick Commands, TDD Workflow, Quality Standards, Project Structure(条件付き)

#### CLAUDE.md (Claude固有)

- 先頭に `@AGENTS.md` import を配置
- `fresh` → テンプレートから生成
- `existing-no-tdd` → AI Behavior Principlesをマージ（カスタム保持）
- `dev-crew-installed` → AI Behavior更新/リフレッシュ確認

テンプレートとマージ戦略は [reference.md](reference.md) を参照。
生成後に Deletion Test（各行を削除してもClaude が困らないなら削除）を実施。詳細は [reference.md](reference.md)。

### Step 5: 階層CLAUDE.md推奨（任意）

tests/, src/, docs/ に CLAUDE.md 配置を推奨（各30-50行）。
`@docs/xxx.md` 形式の import で外部ファイルを参照可能。詳細は [reference.md](reference.md)。

### Step 6: .claude/ 構造生成

ファイル単位で存在チェックし、不足分のみ作成。既存ファイルは更新確認。
rules/: git-safety, security, git-conventions。hooks/: recommended。詳細は [reference.md](reference.md)。

Hook設定の案内: `.claude/hooks/recommended.md` に推奨Hook設定が記載されている旨をユーザーに伝え、`~/.claude/settings.json` にコピーしてClaude Codeを再起動するよう案内する。

### Step 7: Pre-commit Hook確認（推奨）

hookなし → セットアップ推奨。詳細は [reference.md](reference.md) を参照。

### Step 8: 初期Cycle doc作成

`docs/cycles/YYYYMMDD_0000_project-setup.md` を作成。

### Step 9: 完了

セットアップ完了メッセージと**コミット案内**を表示。次: spec で開発開始。メンテナンス案内は [reference.md](reference.md) 参照。

## Reference: [reference.md](reference.md)
