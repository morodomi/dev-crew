# TDD Onboard Reference

## Step 1: プロジェクト分析

### 検出コマンド

```bash
ls artisan 2>/dev/null          # Laravel
ls app.py wsgi.py 2>/dev/null   # Flask
ls wp-config.php 2>/dev/null    # WordPress
ls composer.json package.json pyproject.toml 2>/dev/null
```

### 1.1 フレームワーク検出

| 検出対象 | フレームワーク |
|---------|--------------|
| `artisan` | Laravel |
| `app.py` または `wsgi.py` | Flask |
| `manage.py` + django依存 | Django |
| `wp-config.php` | WordPress |
| 上記以外 | Generic |

### 1.2 パッケージマネージャ検出

| 検出対象 | パッケージマネージャ |
|---------|-------------------|
| `composer.json` | Composer (PHP) |
| `poetry.lock` | Poetry (Python) |
| `uv.lock` | uv (Python) |
| `package.json` | npm/yarn/pnpm |

### 1.3 テストツール検出

| FW | Test | Coverage | Lint | Fmt |
|----|------|----------|------|-----|
| Laravel | PHPUnit/Pest | `php artisan test --coverage` | PHPStan | Pint |
| Flask | pytest | `pytest --cov` | mypy | black |
| Django | pytest | `pytest --cov` | mypy | black |
| WordPress | PHPUnit | `phpunit --coverage-text` | PHPStan | WPCS |

### 1.4 プロジェクト状態判定

#### 検出シグナル

| # | シグナル | チェック方法 |
|---|---------|-------------|
| 1 | CLAUDE.md 存在 | `[ -f CLAUDE.md ]` |
| 2 | TDD セクション | CLAUDE.md 内に `## TDD Workflow` or `## Quick Commands` |
| 3 | .claude/rules/ | `[ -d .claude/rules ]` |
| 4 | .claude/hooks/ | `[ -d .claude/hooks ]` |
| 5 | docs/STATUS.md | `[ -f docs/STATUS.md ]` |

#### モード分類マトリクス

| モード | CLAUDE.md | TDDセクション | rules | STATUS |
|-------|-----------|-------------|-------|--------|
| `fresh` | なし | - | - | - |
| `existing-no-tdd` | あり | なし | なし | なし |
| `dev-crew-installed` | あり | いずれかあり | - | - |

#### 分類ロジック

```bash
if [ ! -f CLAUDE.md ]; then
  MODE="fresh"
elif grep -q "TDD Workflow\|Quick Commands" CLAUDE.md || \
     [ -d .claude/rules ] || [ -f docs/STATUS.md ]; then
  MODE="dev-crew-installed"
else
  MODE="existing-no-tdd"
fi
```

#### dev-crew-installed 時の個別アーティファクト不足検出

```bash
# 各アーティファクトの存在チェック
MISSING=()
grep -q "TDD Workflow" CLAUDE.md || MISSING+=("TDD Workflow section")
[ -d .claude/rules ] || MISSING+=(".claude/rules/")
[ -d .claude/hooks ] || MISSING+=(".claude/hooks/")
[ -f docs/STATUS.md ] || MISSING+=("docs/STATUS.md")
```

不足アーティファクトのリストを Step 2 で提示し、補完範囲をユーザーに確認する。

---

### Step 2 補足: モード別確認項目

#### fresh モード

従来と同じ。フレームワーク・パッケージマネージャの確認のみ。

#### existing-no-tdd モード

- 既存 CLAUDE.md のカスタムセクション一覧を表示
- マージ方針の確認（TDDセクション追加 / 上書き）
- セクション合計が6を超える場合は警告を表示

#### dev-crew-installed モード

- 検出結果サマリー（存在/不足アーティファクト一覧）
- 更新範囲の確認:
  - TDDセクションのリフレッシュ（テンプレート最新化）
  - 不足アーティファクトの補完
  - rules/ ファイルの更新

---

## Step 3: docs/ 構造

`docs/README.md` と `docs/STATUS.md` を作成。STATUS.md は commit で自動更新される。

---

## Step 4: CLAUDE.md 生成

### マージ戦略

| セクション | 戦略 |
|-----------|------|
| Overview (Tech Stack含む) | 既存を保持、Tech Stack部は新規で上書き |
| Quick Commands | 新規で上書き |
| TDD Workflow | 新規で上書き |
| Quality Standards | 新規で上書き |
| AI Behavior Principles | 新規で上書き |
| Project Structure | 条件付き: 自動検出成功時のみ生成 |
| カスタムセクション | 既存を保持 |

### モード別マージ詳細

#### fresh モード

従来どおりテンプレートから生成。

#### existing-no-tdd モード

1. `cp CLAUDE.md CLAUDE.md.bak` でバックアップ
2. 既存 CLAUDE.md の H2 セクション一覧を列挙
3. TDD 必須セクション（Quick Commands, TDD Workflow, Quality Standards, AI Behavior Principles）を追加
4. セクション数チェック: 合計 > 6 の場合は統合を提案（警告表示）
5. Deletion Test を実施

#### dev-crew-installed モード

1. `cp CLAUDE.md CLAUDE.md.bak` でバックアップ
2. テンプレートとの差分チェック（各 TDD セクション単位）
3. 差分ありのセクションのみ更新提案を表示
4. 各セクション個別に承認/スキップを確認
5. 不足アーティファクト（rules, hooks, STATUS.md）を補完

### CLAUDE.md 必須セクション

${PROJECT_NAME}, Overview (Tech Stack含む), Quick Commands (${TEST_COMMAND}, ${COVERAGE_COMMAND}),
TDD Workflow, Quality Standards, AI Behavior Principles。
Project Structure は自動検出成功時のみ追加 (最大6セクション)。

以下は AI Behavior Principles テンプレート:

```markdown
## AI Behavior Principles

### Role: PdM (Product Manager)

計画・調整・確認に徹し、実装は委譲。

### Mandatory: AskUserQuestion

曖昧な要件は全てヒアリング。

### Delegation Strategy

CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 → Agent Teams、それ以外 → 並行Subagent。

### Delegation Rules

- 実装 → green-worker に委譲
- テスト → red-worker に委譲
- 設計 → architect に委譲
- レビュー → reviewer に委譲
- 曖昧 → AskUserQuestion で確認

### CLAUDE.md コンテンツ判定基準

#### 書くべきもの

- コードから推測不能なコマンド・規約・ゴッチャ
- プロジェクト固有のワークフロー
- 環境セットアップの前提条件

#### 書くべきでないもの

- 言語の標準規約（リンターで強制できるもの）
- 一般的なベストプラクティス（platitude: 陳腐な決まり文句）
- タスク固有の一時的な指示

#### アンチパターン

| パターン | 問題 |
|---------|------|
| 詰め込み (overstuffing) | 指示数 ~200 超で全体の遵守率が低下 |
| リンター代替 (linter substitute) | フォーマットルールは静的解析に任せる |
| `/spec` 出力そのまま使用 | 不要な情報が多く含まれる |
| 禁止のみで代替なし (prohibition-only) | 「何をすべきか」を書く |
| IMPORTANT/YOU MUST の乱用 | 強調は少数に限定。多用で効果が薄れる |

#### Deletion Test

生成後、各行について「この行を削除したら Claude が間違うか?」を確認。No なら削除候補。
```

---

## Step 5: 階層CLAUDE.md推奨

| 制約 | 基準 |
|------|------|
| 深さ制限 | 第1階層まで（tests/, src/, docs/） |
| サイズ制限 | 各30-50行以内 |
| 合計予算 | 全CLAUDE.md合計 500行以内目安 |

推奨: tests/CLAUDE.md, src/CLAUDE.md, docs/CLAUDE.md。サブディレクトリは非推奨。

### @ import

CLAUDE.md から `@docs/architecture.md` のように外部ファイルを参照可能（5階層まで再帰）。大きなドキュメントを CLAUDE.md 外に分離し、必要時のみ読み込ませるために活用する。

---

## Step 6: .claude/ 構造

core の `.claude/` から Read してコピー: `.claude/rules/security.md`, `.claude/rules/git-safety.md`, `.claude/rules/git-conventions.md`, `.claude/hooks/recommended.md` (--no-verify + rm -rf ブロック)。

### ファイル単位の差分チェック

| ファイル | 不在時 | 存在時 |
|---------|--------|--------|
| `.claude/rules/git-safety.md` | 作成 | 内容差分あれば更新確認 |
| `.claude/rules/security.md` | 作成 | 内容差分あれば更新確認 |
| `.claude/rules/git-conventions.md` | 作成 | 内容差分あれば更新確認 |
| `.claude/hooks/recommended.md` | 作成 | 内容差分あれば更新確認 |

既存ファイルの更新時は差分を表示し、個別に承認を得る。

### path targeting rules

rules ファイルの paths フロントマターで、特定パスにのみ適用されるルールを作成可能:

```markdown
---
paths: tests/**
---
テストファイルではモックを優先し、外部APIを直接呼ばない。
```

---

## Step 7: Pre-commit Hook確認

| ツール | パス |
|--------|------|
| husky | `.husky/pre-commit` |
| native | `.git/hooks/pre-commit` |
| pre-commit framework | `.pre-commit-config.yaml` |

hookなし → セットアップ推奨。

---

## Step 8: 初期Cycle doc

spec スキルの [templates/cycle.md](../spec/templates/cycle.md) をベースに `docs/cycles/YYYYMMDD_0000_project-setup.md` を作成。

---

## 変数一覧

| 変数名 | 例 | フォールバック |
|--------|-----|-------------|
| `${PROJECT_NAME}` | my-app | ディレクトリ名 |
| `${BACKEND_LANGUAGE}`, `${BACKEND_FRAMEWORK}`, `${BACKEND_PLUGIN}` | PHP, Laravel, php | `[要設定]` |
| `${FRONTEND_LANGUAGE}`, `${FRONTEND_FRAMEWORK}`, `${FRONTEND_PLUGIN}` | TypeScript, Vue, ts | `[要設定]` |
| `${TEST_TOOL}`, `${TEST_COMMAND}` | PHPUnit, `php artisan test` | `[要設定]` |
| `${COVERAGE_COMMAND}` | `php artisan test --coverage` | `[要設定]` |
| `${STATIC_ANALYSIS}`, `${FORMATTER}` | PHPStan, Pint | `[要設定]` |

---

## エラーハンドリング

| 状況 | 対応 |
|------|------|
| フレームワーク検出失敗 | AskUserQuestion → 回答なければ `[要設定]` プレースホルダー |
| Project Structure 検出失敗 | セクションごと省略 |
| 既存 CLAUDE.md あり | バックアップ + マージ確認 |
| poetry/uv 判別不可 | ユーザーに確認 |

---

## メンテナンスガイド

### Feedback Loop

Claude が誤った動作をしたら: 誤りを修正 -> 再発防止ルールを CLAUDE.md に追加 -> git commit。この繰り返しで CLAUDE.md が進化する。

### 定期レビュー

数週間ごとに `/memory` で CLAUDE.md を監査し、陳腐化した指示を削除する。コードベースの変化に合わせて CLAUDE.md も更新すること。
