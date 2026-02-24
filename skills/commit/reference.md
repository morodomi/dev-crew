# commit Reference

SKILL.mdの詳細情報。必要時のみ参照。

## コミットメッセージ詳細

### Type一覧

| Type | 説明 | 例 |
|------|------|-----|
| feat | 新機能 | feat: ログイン機能追加 |
| fix | バグ修正 | fix: パスワード検証エラー修正 |
| docs | ドキュメント | docs: README更新 |
| refactor | リファクタリング | refactor: 認証ロジック整理 |
| test | テスト | test: ログインテスト追加 |
| chore | その他 | chore: 依存関係更新 |

### 良いコミットメッセージ

```
feat: ユーザーログイン機能

- メールアドレスとパスワードでログイン
- セッション管理
- ログアウト機能

Closes #123

🤖 Generated with Claude Code

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Error Handling

### コミットが失敗した場合

```
⚠️ コミットが失敗しました。

確認:
1. pre-commit hookのエラー
2. コミットメッセージのフォーマット
3. ステージングされたファイル
```

### pushを求められた場合

```
コミットは完了しました。

pushは明示的に要求された場合のみ実行します。
pushしますか？
```

## Auto-Learn

COMMIT 後に learn を自動実行する仕組み。`DEV_CREW_AUTO_LEARN=1` 環境変数で有効化。

### トリガー条件

| 条件 | 値 | 必須 |
|------|-----|------|
| `DEV_CREW_AUTO_LEARN` 環境変数 | `1` | Yes |
| `~/.claude/dev-crew/observations/log.jsonl` 存在 | ファイルが存在する | Yes |
| 前回 learn 以降の観測数 | 20件以上 | Yes |

### 失敗時の挙動

| 状況 | アクション |
|------|-----------|
| learn 正常完了 | 結果サマリーを表示 |
| learn 失敗 | 警告ログのみ表示、COMMIT 完了はブロックしない |
| learn タイムアウト | 警告ログのみ表示、サイクル正常終了 |

Auto-Learn は best-effort。サイクルの成否に影響しない。

## Cycle doc完了形式

```markdown
---
feature: auth
cycle: login-implementation
phase: DONE
created: 2025-01-15 10:00
updated: 2025-01-15 15:30
---

# ユーザーログイン機能

## Test List

### DONE
- [x] TC-01: 有効な認証情報でログイン成功
- [x] TC-02: 無効なパスワードでエラー
- [x] TC-03: 存在しないユーザーでエラー

## Progress Log

### 2025-01-15 15:30 - COMMIT
- コミット完了: abc1234
- TDDサイクル完了
```
