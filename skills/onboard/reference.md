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

### 1.4 symlink 検出

AGENTS.md / CLAUDE.md が symlink の場合、Write で symlink 先を破壊する危険がある。ファイル操作の前に検出する。

```bash
# symlink チェック
[ -L AGENTS.md ] && echo "AGENTS.md is symlink -> $(readlink AGENTS.md)"
[ -L CLAUDE.md ] && echo "CLAUDE.md is symlink -> $(readlink CLAUDE.md)"
```

#### symlink 検出時のユーザー確認フロー

symlink を検出した場合、AskUserQuestion で以下を確認:

1. **symlink 先を表示**: `readlink -f <file>` でリンク先の絶対パスを提示
2. **選択肢を提示**:
   - (A) symlink を解除してローカルコピーに変換: `cp --remove-destination "$(readlink AGENTS.md)" AGENTS.md`
   - (B) symlink 先を直接編集（リンク先の他プロジェクトにも影響する旨を警告）
   - (C) onboard を中止

> sync-skills の Case 4 (Conflict → Ask user) パターンと同様。ユーザー判断なしに symlink を操作しない。

### 1.5 プロジェクト状態判定

#### 検出シグナル

| # | シグナル | チェック方法 |
|---|---------|-------------|
| 0 | AGENTS.md 存在 | `[ -f AGENTS.md ]` |
| 1 | CLAUDE.md 存在 | `[ -f CLAUDE.md ]` |
| 2 | TDD セクション | CLAUDE.md/AGENTS.md 内に `## TDD Workflow` or `## Quick Commands` |
| 3 | .claude/rules/ | `[ -d .claude/rules ]` |
| 4 | .claude/hooks/ | `[ -d .claude/hooks ]` |
| 5 | docs/STATUS.md | `[ -f docs/STATUS.md ]` |

#### モード分類マトリクス

| モード | CLAUDE.md | AGENTS.md | TDDセクション | rules | STATUS |
|-------|-----------|-----------|-------------|-------|--------|
| `fresh` | なし | なし | - | - | - |
| `existing-no-tdd` | いずれかあり | いずれかあり | なし | なし | なし |
| `dev-crew-installed` | - | - | いずれかあり | - | - |

#### 分類ロジック

```bash
if [ ! -f CLAUDE.md ] && [ ! -f AGENTS.md ]; then
  MODE="fresh"
elif grep -q "TDD Workflow\|Quick Commands" CLAUDE.md AGENTS.md 2>/dev/null || \
     [ -d .claude/rules ] || [ -f docs/STATUS.md ]; then
  MODE="dev-crew-installed"
else
  MODE="existing-no-tdd"
fi
```

> **Note**: AGENTS.md のみ存在するケース（CLAUDE.md なし）は `existing-no-tdd` に分類される。`fresh` は両ファイルとも不在の場合のみ。layout判定（`agents-md-first` / `claude-md-only` / `none`）はモード分類と直交する別軸。

#### dev-crew-installed 時の個別アーティファクト不足検出

```bash
# 各アーティファクトの存在チェック
MISSING=()
[ -f AGENTS.md ] || MISSING+=("AGENTS.md")
grep -q "TDD Workflow" CLAUDE.md AGENTS.md 2>/dev/null || MISSING+=("TDD Workflow section")
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
- **セクション差分検出**: 現在のファイル内容とテンプレートをセクション単位で比較し、差分を表示
- 更新範囲の確認:
  - TDDセクションのリフレッシュ（テンプレート最新化）
  - 不足アーティファクトの補完
  - rules/ ファイルの更新

##### セクション差分検出チェック項目

以下のセクションをテンプレートと比較し、差分の有無を報告:

| # | 対象ファイル | セクション | 比較内容 |
|---|-------------|-----------|---------|
| 1 | AGENTS.md | TDD Workflow | Workflow 行に Codex plan review の記述があるか |
| 2 | AGENTS.md | Quick Commands | テスト・カバレッジコマンドが最新か |
| 3 | CLAUDE.md | AI Behavior Principles | テンプレートとの内容差分 |
| 4 | CLAUDE.md | Codex Integration | Codex Integration セクションの有無チェック（不在なら追加候補） |
| 5 | CLAUDE.md | Post-Approve Action | Post-Approve Action 形式が plan ファイルに含まれているか |

---

## Step 3: docs/ 構造

`docs/README.md` と `docs/STATUS.md` を作成。STATUS.md は commit で自動更新される。

---

## Step 4: AGENTS.md + CLAUDE.md 生成

### Two-File Model

AGENTS.md と CLAUDE.md は役割が異なる:

- **AGENTS.md** = cross-tool 情報。他のAIツール（Codex, Copilot等）でも利用可能な、プロジェクトの技術スタック・テストコマンド・ワークフロー等を記載する。
- **CLAUDE.md** = Claude固有設定。`@AGENTS.md` import で cross-tool 情報を取り込みつつ、Claude Code 専用の振る舞い原則（PdMロール、委譲ルール等）を追加する。

この2ファイルモデルにより、Claude以外のツールもAGENTS.mdからプロジェクト情報を読み取れる。

### AGENTS.md マージ戦略 (最大5セクション)

| セクション | 戦略 |
|-----------|------|
| Overview (Tech Stack含む) | 既存を保持、Tech Stack部は新規で上書き |
| Quick Commands | 新規で上書き |
| TDD Workflow | 新規で上書き |
| Quality Standards | 新規で上書き |
| Project Structure | 条件付き: 自動検出成功時のみ生成 |
| カスタムセクション | 既存を保持 |

### CLAUDE.md マージ戦略 (最大2セクション)

| セクション | 戦略 |
|-----------|------|
| `@AGENTS.md` import | 先頭行に配置（必須） |
| AI Behavior Principles | 新規で上書き |
| カスタムセクション | 既存を保持 |

CLAUDE.md テンプレート先頭:

```markdown
@AGENTS.md

# ${PROJECT_NAME} (Claude Code Extensions)
```

### モード別マージ詳細

#### fresh モード

AGENTS.md + CLAUDE.md をテンプレートから生成。

#### existing-no-tdd モード

1. `cp CLAUDE.md CLAUDE.md.bak` でバックアップ（CLAUDE.md存在時）
2. `cp AGENTS.md AGENTS.md.bak` でバックアップ（AGENTS.md存在時）
3. 既存ファイルの H2 セクション一覧を列挙（存在するファイルのみ）
4. AGENTS.md: cross-tool必須セクション（Quick Commands, TDD Workflow, Quality Standards）を追加（不在時は新規生成）
5. CLAUDE.md: `@AGENTS.md` import + AI Behavior Principlesを追加（不在時は新規生成）
6. セクション数チェック: AGENTS.md > 5 の場合は統合を提案（警告表示）
7. Deletion Test を実施

#### dev-crew-installed モード

1. `cp CLAUDE.md CLAUDE.md.bak` でバックアップ
2. `cp AGENTS.md AGENTS.md.bak` でバックアップ（AGENTS.md存在時）
3. テンプレートとの差分チェック（各セクション単位）
4. 差分ありのセクションのみ更新提案を表示
5. 各セクション個別に承認/スキップを確認
6. 不足アーティファクト（rules, hooks, STATUS.md）を補完

##### 更新提案の具体的チェック項目

Step 2 のセクション差分検出結果に基づき、以下を具体的にチェック:

| # | チェック項目 | 対象 | 判定基準 |
|---|-------------|------|---------|
| 1 | Post-Approve Action 形式チェック | CLAUDE.md / plan テンプレート | `## Post-Approve Action` セクションが plan テンプレートに存在し、compact-safe 注記があるか |
| 2 | Workflow 行の KICKOFF → sync-plan / Codex plan review 更新チェック | AGENTS.md TDD Workflow | Workflow 行が `KICKOFF -> sync-plan` と `Codex plan review` を含む最新版か確認し、旧表記ならマージ戦略テーブル通り TDD Workflow セクションをテンプレートで新規で上書き提案 |
| 3 | Codex Integration セクション有無チェック | CLAUDE.md | `## Codex Integration` セクションが存在するか。不在なら追加提案（テンプレートから生成） |
| 4 | sync-skills ガイダンス有無 | CLAUDE.md / AGENTS.md | Codex 連携時の sync-skills 実行案内があるか |
| 5 | Quick Commands 上書きチェック | AGENTS.md Quick Commands | コマンド差分があればマージ戦略テーブル通り Quick Commands セクションをテンプレートで新規で上書き提案 |

差分がないセクションは更新提案を出さない（不要な変更を避ける）。差分があるセクションのみユーザーに提示し、個別に承認を得る。

### AGENTS.md 必須セクション

${PROJECT_NAME}, Overview (Tech Stack含む), Quick Commands (${TEST_COMMAND}, ${COVERAGE_COMMAND}),
TDD Workflow, Quality Standards。
Project Structure は自動検出成功時のみ追加 (最大5セクション)。

#### AGENTS.md テンプレートガイダンス

- **Start Here セクション**: AGENTS.md 冒頭に「Start Here」セクションを配置し、新規参入者が最初に読むべきドキュメント（PHILOSOPHY.md等）と、STATUS.md/cycles/ での現在の作業状況確認を案内する。
- **テストコマンド**: Quick Commands には具体的な実行コマンドを記載する。シェルテストの場合は `for f in tests/test-*.sh; do bash "$f"; done` パターンを推奨。フレームワーク固有のコマンド（`php artisan test`, `pytest` 等）と併記する。
- **数値カウントは STATUS.md へ**: AGENTS.md にスキル数・エージェント数等の数値カウントを書かない。変更のたびに更新が必要になる。カウントは STATUS.md に記載し、AGENTS.md からは「STATUS.md を参照」と案内する。
- **Migration note**: ドキュメントが移行中の場合、冒頭に migration note を記載する。例: `> docs are in migration. [docs/PHILOSOPHY.md](docs/PHILOSOPHY.md) is authoritative when other docs disagree.`

### CLAUDE.md 必須セクション

`@AGENTS.md` import, AI Behavior Principles (最大2セクション)。

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

#### CLAUDE.md テンプレートガイダンス

- **Codex Integration セクション**: Codex が利用可能なプロジェクトでは、CLAUDE.md に Codex Integration セクションを追加する。`codex exec --full-auto` でのplan review、`codex exec resume --last --full-auto` でのセッション継続パターンを記載する。
- **Skills trigger table は不要**: CLAUDE.md にスキルのトリガーワード一覧テーブルを書かない。スキルの `SKILL.md` に `description` フィールドがあり、Claude Code のプラグインシステムが自動でマッチングする。trigger table は陳腐化しやすく、メンテナンスコストが高い。

#### Codex セットアップガイダンス

- **sync-skills**: プロジェクトで dev-crew プラグインを使用している場合、Codex が dev-crew のスキル定義を参照できるよう、`sync-skills` でスキル情報を AGENTS.md に同期する。Codex は Claude Code プラグインを直接読めないため、この同期が必要。
- **Codex セッション作成**: 初回は `codex exec --full-auto "review plan <planファイルパス>"` で新規セッションを作成する。以降は `codex exec resume --last --full-auto "指示"` でセッションを継続し、Context Cache を活用する。

### Migration from Single-CLAUDE.md

既存プロジェクトが CLAUDE.md のみ（claude-md-only レイアウト）の場合のマイグレーション手順:

1. `existing-no-tdd` モード: onboard が AGENTS.md を新規生成し、CLAUDE.md から cross-tool セクション（Tech Stack, Quick Commands, TDD Workflow, Quality Standards）を AGENTS.md に移動。CLAUDE.md 先頭に `@AGENTS.md` import を追加。
2. `dev-crew-installed` モード: 既存 CLAUDE.md の TDD 関連セクションを AGENTS.md に分離。CLAUDE.md は `@AGENTS.md` import + AI Behavior Principles のみに簡素化。
3. いずれのモードでも `cp CLAUDE.md CLAUDE.md.bak`（AGENTS.md存在時は `cp AGENTS.md AGENTS.md.bak` も）で事前バックアップを取得。

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
| AGENTS.md マージ失敗 | `cp AGENTS.md.bak AGENTS.md` で復旧。.bakファイルはonboard開始時に自動作成される |
| CLAUDE.md/AGENTS.md 誤編集 | `cp <file>.bak <file>` で .bak から復旧。.bak が無い場合は `git checkout -- <file>` で復元 |
| .bak ファイル不在 | `git log --oneline <file>` で直近コミットを確認し `git checkout <hash> -- <file>` で復旧 |
| poetry/uv 判別不可 | ユーザーに確認 |

---

## メンテナンスガイド

### Feedback Loop

Claude が誤った動作をしたら: 誤りを修正 -> 再発防止ルールを CLAUDE.md に追加 -> git commit。この繰り返しで CLAUDE.md が進化する。

### 定期レビュー

数週間ごとに `/memory` で CLAUDE.md を監査し、陳腐化した指示を削除する。コードベースの変化に合わせて CLAUDE.md も更新すること。
