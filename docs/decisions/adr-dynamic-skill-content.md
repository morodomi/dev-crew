# ADR-001: SKILL.md 動的コンテンツ注入（!`command` 構文）

## Status: accepted

## Context

Anthropic Xの投稿で `!`command`` 構文が紹介された。SKILL.md内にシェルコマンドを埋め込み、スキル起動時にClaude Codeが実行結果でプレースホルダを置換する機能。dev-crewの各スキルはRead/Bashツールコールで動的情報を毎回取得しており、この構文でトークンとレイテンシを削減できる可能性がある。

Phase 24（v2.7）として構文サポートの検証を実施した。

## Decision Scorecard

| 項目 | 評価 | 理由 |
|------|------|------|
| Requirements Fit | A | ツールコール削減・コンテキスト鮮度向上の要件に合致 |
| Security | B | ワーキングディレクトリ制約あり。秘密鍵露出リスクは低いが注意必要 |
| Operability | C | 権限設定が必要（settings.local.json）。対話的承認不可 |
| Complexity | A | SKILL.mdに1行追加するだけ。実装コスト極小 |
| Testability | C | 手動検証のみ。自動テストで展開結果を検証する手段がない |

## Findings（検証結果）

### 構文サポート: YES

Claude Code は `!`command`` 構文を認識し、スキル呼び出し時にシェルコマンドを実行しようとする。

### 権限要件

| 要件 | 詳細 |
|------|------|
| 権限チェック | `settings.local.json` の `permissions.allow` に登録されたコマンドのみ実行可能 |
| 対話的承認 | **不可** — スキル内の動的コマンドはプロンプトなしで即エラー |
| ワーキングディレクトリ | コマンドはセッションのワーキングディレクトリ内に制約される |
| エラー時挙動 | 権限エラー: スキル読み込み自体が失敗（`Error: Shell command permission check failed`） |

### 展開タイミング

スキル呼び出し時（プロンプト構築時）。モデルにプロンプトが渡される前にコマンドが実行され、結果で置換される。

## Arguments

### Accepted

- **段階的導入**: 高ROIスキル（orchestrate, reload）から適用し、効果を計測してから横展開
- **読み取り専用コマンドのみ**: `git log`, `cat`, `grep`, `ls` 等の副作用なしコマンドに限定
- **settings.local.json への事前登録**: 使用するコマンドは明示的に許可リストに追加する運用

### Rejected

- **全スキル一括適用**: 権限設定の複雑さと検証コストから、段階的に進める
- **副作用のあるコマンド**: `rm`, `git commit`, `curl -X POST` 等は動的注入に不適切
- **長時間実行コマンド**: タイムアウト挙動が未定義のため、即座に完了するコマンドのみ

### Deferred

- **自動テスト方法**: 展開結果をプログラマティックに検証する手段がない。Claude Code側の機能追加を待つ
- **onboard テンプレートへの推奨パターン追加**: Phase 25 で横展開時に検討

## Decision

`!`command`` 構文をdev-crewで採用する。以下のガイドラインに従う:

### 推奨パターン

```markdown
## Current State
!`git log --oneline -5`

## Active Cycle
!`grep -L 'phase: DONE' docs/cycles/*.md 2>/dev/null | head -1`
```

### 使用ガイドライン

| ルール | 理由 |
|--------|------|
| 読み取り専用コマンドのみ | 副作用防止 |
| 即座に完了するコマンド（< 1秒） | タイムアウトリスク回避 |
| `2>/dev/null` または `\|\| echo "fallback"` でエラーハンドリング | スキル読み込み失敗防止 |
| `settings.local.json` に事前許可登録 | 権限エラー防止 |
| 秘密鍵・認証情報を出力するコマンド禁止 | セキュリティ |
| コードブロック内に `!`command`` を書かない | 意図しない展開防止 |

### 非推奨パターン

```markdown
<!-- NG: 副作用あり -->
!`git commit -m "auto"`

<!-- NG: 長時間実行 -->
!`npm install`

<!-- NG: 秘密鍵露出 -->
!`cat .env`

<!-- NG: ワーキングディレクトリ外 -->
!`cat /etc/passwd`
```

## Consequences

- Phase 25 で orchestrate → reload → spec → red/green に段階適用
- 各スキルで使用するコマンドを `settings.local.json` に登録する手順が必要
- onboard スキルで新規プロジェクトに推奨パターンを案内（Phase 25 以降）
- 自動テストは構造チェック（ADR存在確認）のみ。展開結果の検証は手動
