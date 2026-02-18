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

---

## Step 3: docs/ 構造

`docs/README.md` と `docs/STATUS.md` を作成。STATUS.md は commit で自動更新される。

---

## Step 4: CLAUDE.md 生成

### マージ戦略

| セクション | 戦略 |
|-----------|------|
| Overview | 既存を保持 |
| Tech Stack | 新規で上書き |
| Quick Commands | 新規で上書き |
| TDD Workflow | 新規で上書き |
| Quality Standards | 新規で上書き |
| Project Structure | 既存を保持 |
| カスタムセクション | 既存を保持 |

### CLAUDE.md 必須セクション

${PROJECT_NAME}, Overview, Tech Stack, Quick Commands (${TEST_COMMAND}, ${COVERAGE_COMMAND}), TDD Workflow, Quality Standards, Project Structure, 以下の AI Behavior Principles:

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
| `/init` 出力そのまま使用 | 不要な情報が多く含まれる |
| 禁止のみで代替なし (prohibition-only) | 「何をすべきか」を書く |
| IMPORTANT/YOU MUST の乱用 | 強調は少数に限定。多用で効果が薄れる |

#### Deletion Test

生成後、各行について「この行を削除したら Claude が間違うか?」を確認。No なら削除候補。

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

init スキルの [templates/cycle.md](../init/templates/cycle.md) をベースに `docs/cycles/YYYYMMDD_0000_project-setup.md` を作成。

---

## 変数一覧

| 変数名 | 例 |
|--------|-----|
| `${PROJECT_NAME}` | my-app |
| `${BACKEND_LANGUAGE}`, `${BACKEND_FRAMEWORK}`, `${BACKEND_PLUGIN}` | PHP, Laravel, php |
| `${FRONTEND_LANGUAGE}`, `${FRONTEND_FRAMEWORK}`, `${FRONTEND_PLUGIN}` | TypeScript, Vue, ts |
| `${TEST_TOOL}`, `${TEST_COMMAND}` | PHPUnit, `php artisan test` |
| `${COVERAGE_COMMAND}` | `php artisan test --coverage` |
| `${STATIC_ANALYSIS}`, `${FORMATTER}` | PHPStan, Pint |

---

## エラーハンドリング

| 状況 | 対応 |
|------|------|
| フレームワーク検出失敗 | AskUserQuestion で確認 |
| 既存 CLAUDE.md あり | バックアップ + マージ確認 |
| poetry/uv 判別不可 | ユーザーに確認 |

---

## メンテナンスガイド

### Feedback Loop

Claude が誤った動作をしたら: 誤りを修正 -> 再発防止ルールを CLAUDE.md に追加 -> git commit。この繰り返しで CLAUDE.md が進化する。

### 定期レビュー

数週間ごとに `/memory` で CLAUDE.md を監査し、陳腐化した指示を削除する。コードベースの変化に合わせて CLAUDE.md も更新すること。
