# Learn - Reference

SKILL.md の詳細情報。必要時のみ参照。

## MEMORY.md との棲み分け

| 観点 | MEMORY.md | instinct |
|------|-----------|----------|
| 性質 | 長期知識 | 短期パターン |
| 編集者 | 人間が検証・編集 | 自動抽出 (未検証) |
| 形式 | Markdown (フリーテキスト) | JSONL (構造化) |
| スコープ | プロジェクトローカル | ユーザーグローバル (${CLAUDE_PLUGIN_DATA}/) |
| 用途 | 次セッションのシステムプロンプト | evolve のクラスタリング入力 |

MEMORY.md に書くべきもの: 確認済みのプロジェクト規約、ツール設定、ユーザー嗜好。
instinct に蓄積されるもの: 未検証の作業パターン、エラー解決履歴、繰り返しワークフロー。

### confidence 閾値の意味

| confidence | 分類 | 扱い |
|------------|------|------|
| < 0.5 | ノイズ | 破棄（保存しない） |
| 0.5 - 0.79 | 有望だが要観察 | instinct として保存。evolve の入力候補 |
| >= 0.8 | 安定パターン | instinct として保存 + MEMORY.md 昇格候補として提示 |

### instinct → MEMORY.md 昇格パス

instinct は以下の3つのパスで MEMORY.md に昇格できる:

1. **自動提示**: confidence >= 0.8 の instinct を learn 実行時にユーザーへ昇格候補として提示
2. **evolve 経由**: evolve でスキル化された instinct の知見を MEMORY.md に追記
3. **手動確認**: ユーザーが3回以上再現を確認した instinct を手動で MEMORY.md に記載

### 具体例

MEMORY.md に書くべき例: 「このプロジェクトでは静的解析の最も厳格なレベルを使用する」（確認済みの規約）

instinct に蓄積される例: 「配列アクセス時に null check を追加するパターンが2回観測された」（未検証、confidence 0.6）

昇格候補の例: 「テスト前に必ず static analysis を実行するワークフローが5セッション連続で観測された」（confidence 0.85、安定パターン）

## .last-learn-timestamp

learn 実行のタイムスタンプを管理するファイル。auto-learn の閾値ゲートで使用。

| 項目 | 値 |
|------|-----|
| パス | `${CLAUDE_PLUGIN_DATA}/observations/.last-learn-timestamp` |
| 形式 | ISO 8601 UTC (`2026-02-24T12:00:00Z`) |
| 更新タイミング | learn の Step 6 完了後 |
| 用途 | 前回 learn 以降の observation 数をカウントする基準 |

不在時: 全 observation をカウント対象とする（初回実行時）。

## instinct 蓄積場所

保存先: `${CLAUDE_PLUGIN_DATA}/instincts/`（ユーザーグローバル）

選択理由:
- クロスプロジェクトでパターンが蓄積され、プロジェクト横断の知見が活用できる
- ユーザーホーム配下のため、プロジェクト Git リポジトリを汚さない
- learn/evolve/observe.sh が同一パスを参照し、依存関係がシンプル

## instinct フォーマット

```json
{"id":"inst-20260213-001", "trigger":"Static analysis error on collection access", "action":"Add null check before collection access", "confidence":0.7, "domain":"tdd", "evidence":["Cycle doc 20260213", "git log abc123"], "created":"2026-02-13"}
```

### フィールド定義

| フィールド | 型 | 説明 |
|-----------|-----|------|
| id | string | inst-YYYYMMDD-NNN 形式 |
| trigger | string | パターンが発火する条件 |
| action | string | 推奨アクション |
| confidence | float | 信頼度 (0.0-1.0) |
| domain | string | 関連ドメイン (tdd, security, etc.) |
| evidence | string[] | 根拠となるソース |
| created | string | 作成日 (YYYY-MM-DD) |

## TF-IDF サマリ計算

### Term 定義

`{tool_name}:{category}` 形式。tool_name に応じたカテゴリ抽出:

| tool_name | category | 例 |
|-----------|----------|-----|
| Bash | コマンド名 (target の先頭トークン) | `Bash:aws`, `Bash:docker` |
| Edit, Write | 拡張子 (target のファイル拡張子) | `Edit:*.php`, `Write:*.md` |
| Read, Grep, Glob | 拡張子 (target のファイル拡張子) | `Read:*.ts`, `Grep:*.py` |
| Task | subagent_type | `Task:dev-crew:observer` |
| その他 | tool_name そのまま | `WebSearch:WebSearch` |

### 計算式

- **TF (Term Frequency)**: セッション内の出現割合の平均
  - `TF = avg(count_in_session / total_ops_in_session)` (全セッションの平均)
- **IDF (Inverse Document Frequency)**: セッション横断の希少性
  - `IDF = log2(total_sessions / (sessions_with_term + 1))`
- **TF-IDF**: `TF * IDF`

### ブートストラップ期間

セッション数 < 20 の場合、IDF が統計的に不安定。TF-IDF サマリを生成せず、observer に tfidf_summary を渡さない。observer は回数ベースのフォールバックテーブルを使用する。

### tfidf_summary 出力形式

```json
[
  {"term": "Bash:aws", "tf": 0.012, "idf": 4.5, "tfidf": 3.27, "count": 120, "sessions": 15},
  {"term": "Edit:*.php", "tf": 0.008, "idf": 3.2, "tfidf": 1.00, "count": 47, "sessions": 22}
]
```

## 品質フィルタ詳細

confidence 閾値 0.5 は仮値。運用データで調整予定。

調整方針:
- 有用な instinct が頻繁に破棄される場合 → 閾値を下げる (0.3)
- ノイズ instinct が多すぎる場合 → 閾値を上げる (0.7)

## 検出対象パターン

| パターン | 検出方法 | 例 |
|---------|---------|-----|
| ユーザー修正 | 「いや」「違う」等の否定語 + 直後の変更 | 「pytest じゃなくて unittest」|
| エラー解決 | エラーメッセージ + 成功した修正 | PHPStan レベル9 対応 |
| 繰り返しワークフロー | 同一ツール列が3回以上出現 | Read → Edit → Bash (test) |
| ツール選好 | 特定ツールの優先的使用 | Grep よりも Explore を使う |
