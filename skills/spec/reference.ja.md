# spec Reference (Japanese)

SKILL.mdの詳細情報。必要時のみ参照。

## Step 8: 承認前 Plan Review (Codex) {#step-8-pre-approval-plan-review}

Codex plan review は**承認前**（plan mode 内、ExitPlanMode 前）に実行する契約。Step 7 完了後に実行し、findings を draft plan へ直接反映してから最終版を1回だけ再レビューして打ち切る（cycle 20260717_1126_approval-reorder）。

### 手順

1. `codex exec --sandbox read-only "review plan <plan path>"` を実行する。session id は下記3段 fallback で取得する。**`--full-auto` での実行は禁止**（plan review は read-only sandbox 必須。`--full-auto` は書き込み権限を伴うため plan mode の read-only 原則に反する）
2. findings を draft plan へ直接反映する
3. 最終版を1回だけ再レビューする: `codex exec --sandbox read-only resume <session-id> "..."`（**フラグは resume より前置**。後置は rc=2 実測済み。ここも `--full-auto` 禁止、`--sandbox read-only` 固定）
4. `## Plan Review Record` を plan に記録する（フィールド様式は下記）
5. 未解消 BLOCK は Record の `unresolved_blocks` に列挙し、承認提示文で人間の明示 override を要求する。人間が override した場合は verdict を `BLOCK-overridden` とし、Record の `override` フィールドに承認内容を引用する
6. Codex 不在時（`which codex` 失敗）: Step 8 の Codex 呼び出しは skip するが、**Record 自体の記録は必須**（詳細は下記「Codex 不在時」参照）

### codex_session_id 取得契約（3段 fallback）

1. stdout header の `session id:` 行から uuid を regex 抽出
2. (1) 失敗時: `~/.codex/sessions/<Y/M/D>/rollout-*-<uuid>.jsonl` の最新ファイル名から抽出（実行時刻突合で他セッション混入を排除）
3. (1)(2) 両方失敗時: `codex_session_id: ""` + `extraction_failed: true` を Record に記録し、degraded 経路（RED 以降は `resume --last`）へフォールバックする

### Plan Review Record 様式（canonical フィールド）

| フィールド | 内容 |
|-----------|------|
| codex_session_id | uuid or ""（extraction_failed 時） |
| verdict | PASS / WARN / BLOCK-overridden |
| reviewed_plan_hash | 下記アルゴリズムで算出した sha256 |
| findings 要約 | attempt 毎の要約 |
| review_attempts | [{started, completed, verdict}, ...]（Codex 不在時は `[]`） |
| plan_presented | 承認提示時刻 |
| unresolved_blocks | なし or 列挙 |
| override | verdict が `BLOCK-overridden` の場合のみ必須。人間の明示承認を引用（例: 「〇〇の理由により承認、△△担当が確認」） |
| codex_unavailable | Codex 不在時のみ `true` を記録（存在しない場合はフィールド自体を省略） |

### 正準 hash アルゴリズム

plan ファイル中、**行全体が `## Plan Review Record` に一致する最初の行**より前の全内容（当該行を含まない、バイト列そのまま）の sha256:

```bash
awk '$0=="## Plan Review Record"{exit}{print}' plan.md | shasum -a 256
```

sync-plan（一次照合）と pre-red-gate.sh（決定論的最終防衛、frontmatter `plan_file:` から再算出）で二重照合する。過去に部分文字列 split による誤 hash が発生した実例あり — 必ず「行全体一致」で判定すること。

### Codex 不在時

`which codex` が失敗する場合、Codex 呼び出し（手順1-3）は skip するが、**`## Plan Review Record` 自体の記録は省略しない**（silent skip 禁止）。以下の形で Record を作成する:

- `verdict` / `reviewed_plan_hash`: Claude が自前で判定・算出する（`reviewed_plan_hash` は正準アルゴリズムで計算可能、Codex 不在でも算出できる）
- `review_attempts`: `[]`（空配列。Codex レビューを実施していないため）
- `codex_unavailable: true` を記録する

## リスクスコア判定の詳細

### スコア閾値（reviewと統一）

| スコア | 判定 | アクション |
|--------|------|-----------|
| 0-29 | PASS | 確認表示のみで自動進行 |
| 30-59 | WARN | 簡易質問（Step 4.6）→ スコープ確認（Step 5） |
| 60-100 | BLOCK | Brainstorm & リスク質問（Step 4.7） |

### キーワード別スコア

| カテゴリ | キーワード | スコア |
|----------|-----------|--------|
| セキュリティ | ログイン, 認証, 認可, パスワード, セッション, 権限, トークン | +60 |
| 外部依存 | API, 外部連携, 決済, webhook, サードパーティ | +60 |
| データ影響 | DB変更, マイグレーション, スキーマ, テーブル追加 | +60 |
| 影響範囲 | リファクタリング, 大規模, 全体, アーキテクチャ | +40 |
| 限定的 | テスト追加, ドキュメント, コメント, README | +10 |
| 見た目のみ | UI修正, 色, 文言, typo, CSS, スタイル | +10 |
| デフォルト | 上記以外 | 0 |

### 判定ロジック

```
1. ユーザー入力をキーワードで部分一致検索
2. 同一カテゴリ内は最大1回のみ加算（重複なし）
3. 異なるカテゴリは合算（上限100）
4. 該当なしはデフォルト0（PASS）

計算例:
- 「typo修正」= +10 → PASS
- 「バグ修正」= 0 → PASS（キーワードなし）
- 「リファクタリング」= +40 → WARN
- 「認証機能」= +60 → BLOCK
- 「認証+パスワード」= +60 → BLOCK（同一カテゴリ）
- 「認証+API」= +100 → BLOCK（異カテゴリ合算、上限）
```

### 複数リスクタイプ該当時の処理

複数カテゴリに該当する場合、**全てのリスクタイプの質問を順次実行**する。

```
例: 「ログイン機能でAPI連携してDBも変更」
→ セキュリティ質問（認証方式、2FA等）
→ 外部連携質問（API認証、エラー処理等）
→ データ変更質問（既存データ影響、ロールバック等）
```

Cycle docには全ての回答を記録する。

### WARN質問（30-59）

スコープ確認前に2つの軽量な質問を行う。結果はCycle docに記録しない。

```yaml
questions:
  - question: "代替アプローチは検討しましたか？"
    header: "Alternatives"
    options:
      - label: "はい、これが最善"
        description: "代替案を評価した上でこれを選択"
      - label: "いいえ、でもスコープは小さい"
        description: "低リスクなのでこのまま進める"
      - label: "選択肢を議論したい"
        description: "もう少し検討が必要"
    multiSelect: false
  - question: "影響範囲を把握していますか？"
    header: "Impact"
    options:
      - label: "はい、特定ファイルに限定"
        description: "境界が明確で低リスク"
      - label: "はい、複数箇所に影響"
        description: "広めだが管理可能"
      - label: "不明、調査が必要"
        description: "追加分析が必要かも"
    multiSelect: false
```

**目的**: 中リスク変更に対する簡易確認。BLOCK時の完全なインタビューは不要。

### Brainstorm（深掘り）質問（BLOCK: 60以上）

リスクタイプ別質問の前に、まず問題の本質を明確化:

```yaml
questions:
  - question: "本当に解決したい問題は何ですか？"
    header: "Problem"
    options:
      - label: "ユーザー要望"
        description: "ユーザーから明確なリクエストがあった"
      - label: "技術的負債"
        description: "既存コードが問題を起こしている"
      - label: "ビジネス要件"
        description: "ビジネス目標達成に必要"
      - label: "パフォーマンス問題"
        description: "現行システムが遅い"
    multiSelect: false
  - question: "代替アプローチは検討しましたか？"
    header: "Alternatives"
    options:
      - label: "はい、これが最善"
        description: "代替案を評価した上でこれを選択"
      - label: "いいえ、もっと検討したい"
        description: "他の選択肢を議論したい"
      - label: "部分的な解決策がある"
        description: "既存機能の拡張で対応可能"
    multiSelect: false
```

**目的**: 問題を十分に理解せずに実装を始めることで生じる過剰設計を防止。

参考: [superpowers/brainstorming](https://github.com/obra/superpowers/blob/main/skills/brainstorming/SKILL.md)

### BLOCK（60以上）時のリスクタイプ別質問

検出キーワードに応じて、以下のAskUserQuestionを実行:

#### セキュリティ関連（ログイン, 認証, 権限, パスワード）

```yaml
questions:
  - question: "認証方式はどれを使用しますか？"
    header: "Auth"
    options:
      - label: "セッション"
        description: "サーバーサイドセッション管理"
      - label: "JWT"
        description: "トークンベース認証"
      - label: "OAuth"
        description: "外部プロバイダ連携"
      - label: "既存拡張"
        description: "現行認証システムを拡張"
    multiSelect: false
  - question: "対象ユーザーは？"
    header: "Users"
    options:
      - label: "一般ユーザー"
        description: "通常の利用者"
      - label: "管理者"
        description: "管理機能を持つユーザー"
      - label: "両方"
        description: "権限レベルで分離"
    multiSelect: false
  - question: "2FA（二要素認証）は必要ですか？"
    header: "2FA"
    options:
      - label: "必要"
        description: "初期リリースから実装"
      - label: "不要"
        description: "パスワードのみ"
      - label: "後で検討"
        description: "将来的に追加予定"
    multiSelect: false
```

#### 外部連携関連（API, webhook, 決済, サードパーティ）

```yaml
questions:
  - question: "API認証方式は？"
    header: "API Auth"
    options:
      - label: "APIキー"
        description: "静的なキーで認証"
      - label: "OAuth2"
        description: "トークンベース"
      - label: "署名付きリクエスト"
        description: "HMAC等で署名"
    multiSelect: false
  - question: "エラー処理の方針は？"
    header: "Errors"
    options:
      - label: "リトライ"
        description: "失敗時に再試行"
      - label: "フォールバック"
        description: "代替処理に切り替え"
      - label: "即時エラー"
        description: "ユーザーに通知"
    multiSelect: true  # リトライ+フォールバック併用が一般的なため
  - question: "レート制限への対応は？"
    header: "Rate Limit"
    options:
      - label: "キューイング"
        description: "リクエストをキューで管理"
      - label: "バックオフ"
        description: "指数バックオフで再試行"
      - label: "不要"
        description: "制限に達しない想定"
    multiSelect: false
```

#### データ変更関連（DB, マイグレーション, スキーマ）

```yaml
questions:
  - question: "既存データへの影響は？"
    header: "Data Impact"
    options:
      - label: "影響なし"
        description: "新規テーブル/カラムのみ"
      - label: "データ変換必要"
        description: "既存データのマイグレーション"
      - label: "データ削除あり"
        description: "一部データの削除・統合"
    multiSelect: false
  - question: "ロールバック方法は？"
    header: "Rollback"
    options:
      - label: "自動ロールバック"
        description: "ダウンマイグレーション対応"
      - label: "手動復旧"
        description: "バックアップから復元"
      - label: "前方互換"
        description: "新旧両方で動作"
    multiSelect: false
```

### Cycle docへの記録形式

```markdown
## Environment

### Scope
- Layer: Backend
- Plugin: php
- Risk: 65 (BLOCK)  # ← スコア形式

### Risk Details（BLOCK時のみ）
- 検出キーワード: 認証, API
- 合計スコア: 65（認証+60, 重複なし）
- 影響範囲: 3-5ファイル
- 外部依存: DB変更あり
```

## 詳細ワークフロー

### 既存サイクル確認の詳細

```bash
# 最新のCycle docを検索
ls -t docs/cycles/*.md 2>/dev/null | head -1
```

**進行中サイクルがある場合**:

```
⚠️ 既存のTDDサイクルが進行中です。

最新: docs/cycles/20251028_1530_XXX.md

選択肢:
1. [推奨] 既存サイクルを継続
2. 新規サイクルを開始（並行開発）

どうしますか？
```

### スコープ（Layer）確認の詳細

AskUserQuestion で確認:

```
この機能のスコープを選択してください:
1. Backend（PHP/Python サーバーサイド）
2. Frontend（JavaScript/TypeScript クライアントサイド）
3. Both（フルスタック）
```

**プラグインマッピング:**

| Layer | Framework | Plugin |
|-------|-----------|--------|
| Backend | Laravel | php |
| Backend | Flask | flask |
| Backend | Django | python |
| Backend | WordPress | php |
| Backend | Generic PHP | php |
| Backend | Generic Python | python |
| Frontend | JavaScript | js |
| Frontend | TypeScript | ts |
| Frontend | Alpine.js | js |
| Both | Laravel + JS | php, js |

**Cycle doc への記録:**

```markdown
## Environment

### Scope
- Layer: Backend
- Plugin: php
```

### 機能名生成の詳細

**ガイドライン**:
- 10〜20文字程度
- 「〜機能」「〜追加」などの接尾辞

**例**:
| やりたいこと | 機能名 |
|------------|--------|
| ユーザーがログインできるようにしたい | ユーザーログイン機能 |
| データをCSV形式でエクスポートしたい | CSVエクスポート機能 |
| 検索機能を追加したい | 検索機能追加 |
| パスワードリセットメールを送信する | パスワードリセット機能 |

**不明確な場合**:

```
機能名をより具体的に教えてください。

良い例: ユーザー認証機能、データ検索機能
悪い例: 機能、新しいやつ、あれ
```

## Error Handling

### Gitリポジトリでない場合

```
⚠️ このディレクトリはGitリポジトリではありません。

TDDサイクルの完了時にコミット操作が必要になるため、
Gitリポジトリでの使用を推奨します。

続行しますか？
```

### ディレクトリ作成失敗

```
エラー: docs/cycles ディレクトリの作成に失敗しました。

対応:
1. 権限確認: ls -la ./
2. 手動作成: mkdir -p docs/cycles
```

## 曖昧性検出 (Ambiguity Detection) {#ambiguity-detection}

Step 4.8 で実行する仕様曖昧性の検出・解消プロセス。AskUserQuestion による Questioning Protocol で不足情報を選択肢形式で解消する。

### トリガー条件

全 risk level (PASS/WARN/BLOCK) で実行する。ただし BLOCK のリスク質問で既にカバー済みのカテゴリはスキップする。

### 5カテゴリの検出シグナルと質問テンプレート

| カテゴリ | 検出シグナル | 質問例 |
|----------|-------------|--------|
| Data | "エクスポート", "インポート", "CSV", "データ" | 対象データ? フォーマット? 件数上限? |
| API | "API", "エンドポイント", "webhook" | どのAPI? 認証方式? エラー処理? |
| UI/UX | "画面", "フォーム", "ボタン", "ページ" | どの画面? ユーザーフロー? レスポンシブ? |
| Scope | 曖昧動詞 ("追加", "改善", "修正", "更新") | どのコンポーネント? 何が変わる? 影響範囲? |
| Edge cases | エラー/制限の明示なし | 失敗時の振る舞い? 空状態? 上限値? |

### AskUserQuestion テンプレート

各カテゴリで検出されたシグナルに基づき、AskUserQuestion で構造化質問を実施:

```yaml
questions:
  - question: "[カテゴリ固有の質問]"
    header: "[カテゴリ名]"
    options:
      - label: "[具体的な選択肢A]"
        description: "[選択肢Aの説明]"
      - label: "[具体的な選択肢B]"
        description: "[選択肢Bの説明]"
    multiSelect: false
```

- 1ラウンド 2-4問
- 検出カテゴリのみ質問（全カテゴリを毎回聞かない）

### Questioning Protocol ルール

| ルール | 内容 |
|--------|------|
| 質問数 | 1ラウンド 2-4問 |
| ラウンド上限 | 最大3ラウンド |
| 3ラウンド後 | 残る曖昧点は「TBD」として記録し次ステップへ |
| スキップ条件 | 20語以上の具体的な記述があるカテゴリはスキップ可 |

### 記録

決定事項をplanファイルのTDD Context末尾に追記:

```markdown
### 曖昧性解消
- Data: CSV形式、最大10,000行
- Scope: UserControllerのみ変更
- Edge cases: 空ファイル時はエラーメッセージ表示
```

## Plan File Template {#plan-file-template}

planファイルに記録するTDDコンテキストのテンプレート:

```markdown
## TDD Context

- Workflow: TDD (plan-review → sync-plan → RED → GREEN → REFACTOR → REVIEW → COMMIT)
- Cycle doc: sync-plan エージェントが docs/cycles/ に作成
- Feature: [機能名 (3-5語)]

### Environment
- Layer: [Backend / Frontend / Both]
- Plugin: [php / flask / python / js / ts]
- Risk: [0-100] ([PASS / WARN / BLOCK])
- Language: [バージョン情報]
- Dependencies: [主要パッケージ]

### Risk Details (BLOCK時のみ)
- [リスク質問の回答]

### Ambiguity Resolution (該当時)
- [カテゴリ]: [解決内容]

## Plan Review Record

- codex_session_id: [uuid or "" if extraction_failed]
- verdict: [PASS / WARN / BLOCK-overridden]
- reviewed_plan_hash: [sha256、算出法は Step 8 参照]
- findings 要約: [attempt毎の要約]
- review_attempts:
  - {started: [HH:MM], completed: [HH:MM], verdict: [PASS/WARN/BLOCK]}
- plan_presented: [YYYY-MM-DD HH:MM]
- unresolved_blocks: [なし or 列挙]

## Post-Approve Action

approve後、compact + accept edits on に遷移したら `/orchestrate` のみを起動する（sync-plan・委譲確認等を個別に直接実行してから orchestrate を呼ぶのではない — 以下は全て /orchestrate 内部で自動的に行われる: sync-plan → architect → RED → GREEN → REFACTOR → REVIEW → COMMIT）:
- sync-plan: Cycle doc を作成する（Step 8 の記録を転記。sync-plan エージェントが docs/cycles/ に生成）
- architect: 設計レビュー（Design Review Gate）+ Post-Transfer Verification（転記検証）
- plan-review は承認前に完了済み（詳細は spec Step 8 参照。再実行しない）
- Codex が利用可能なら AskUserQuestion: RED/GREEN を Codex に委譲するか確認 (full/no)。選択結果を Cycle doc frontmatter の `codex_mode` に記録
```

この後、plan mode内で探索・設計・Test List定義・QAチェック・Step 8（承認前レビュー）を続行する。

## プロジェクト固有のカスタマイズ

### 検証の追加例

```bash
# Node.js
if [ ! -f "package.json" ]; then
  echo "警告: package.json が見つかりません"
fi

# Python
if [ ! -f "requirements.txt" ]; then
  echo "警告: requirements.txt が見つかりません"
fi
```

### Cycle docテンプレートの拡張

プロジェクト固有のセクションを `templates/cycle.md` に追加可能。
