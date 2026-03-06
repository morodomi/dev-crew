---
name: onboard
description: 既存プロジェクトにTDD環境をセットアップする。フレームワーク検出、CLAUDE.md生成、docs/STATUS.md作成を行う。「TDDセットアップ」「onboard」「プロジェクト初期化」で起動。
allowed-tools: Read, Write, Bash, Grep, Glob
---

# TDD Onboard

既存プロジェクトにTDD環境をセットアップする。

## Progress Checklist

コピーして進捗を追跡:

```
Onboard Progress:
- [ ] プロジェクト分析（フレームワーク/テストツール検出）
- [ ] プロジェクト状態判定（fresh/existing-no-tdd/dev-crew-installed）
- [ ] 検出結果をユーザーに確認
- [ ] docs/ 構造作成（cycles/, README.md, STATUS.md）
- [ ] CLAUDE.md 生成（既存あればマージ）
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

状態判定ロジックと検出コマンドは [reference.md](reference.md) 参照。

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

### Step 4: CLAUDE.md 生成

- `fresh` → テンプレートから生成
- `existing-no-tdd` → TDDセクションをマージ（カスタム保持、6セクション上限警告）
- `dev-crew-installed` → TDDセクション更新/リフレッシュ確認
- Project Structure は自動検出成功時のみ追加

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

セットアップ完了メッセージを表示。次: spec で開発開始。
CLAUDE.md のメンテナンス（定期レビュー・Feedback Loop）について [reference.md](reference.md) を案内。

## Reference: [reference.md](reference.md)
