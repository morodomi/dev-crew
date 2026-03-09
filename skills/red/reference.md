# red Reference

SKILL.mdの詳細情報。必要時のみ参照。

## Complexity Classification {#complexity-classification}

RED フェーズ開始時に Test List を評価し、処理パスを決定する。

| Class | Criteria | Stages |
|-------|----------|--------|
| trivial | 1-2 items, Example paradigm only, no escalation triggers | Stage 1 as 1-line GWT in test header; Stage 2 skipped; Stage 3 |
| standard | 3-5 items, Example paradigm only | Stage 1 simplified; Stage 2 Review skipped; Stage 3 |
| complex | 6+ items OR any non-Example paradigm | Full 3-stage unchanged |

### Escalation Conditions

以下の条件に1つでも該当する場合、item数に関わらず自動アップグレード:

| Condition | Escalates to |
|-----------|-------------|
| External I/O dependency (DB, API, file) | standard or above |
| Async / concurrency | standard or above |
| State transitions | complex |
| Property / Metamorphic paradigm | complex |

### Rationale

Fast-path は「要件緩和」であり「省略」ではない。thinking trace は常に保持される。trivial/standard では ceremony を軽くするだけで、本質的なテスト品質は維持する。

## Test Plan Stage {#test-plan-stage}

Stage 1 でテスト計画を正式化する手順。

### TC展開テンプレート

Test List の各項目を以下の形式で詳細化:

```markdown
### TC-XX: [テストケース名]

- **Given**: [前提条件 + 具体データ]
- **When**: [操作 + 具体入力値]
- **Then**: [期待結果 + 具体出力値]
- **Category**: [正常系 / 異常系 / 境界値 / 権限 / セキュリティ]
- **Paradigm**: [Contract / Property / Metamorphic / Example]
- **Invariant**: [不変量の記述（Property/Metamorphic時。Example時は省略可）]
- **Test File**: [tests/xxx_test.{ext}]
```

### Paradigm Selection ガイド

Step 0 の2領域分類結果に基づき、Paradigm欄を設定する:

| 分類結果 | 推奨Paradigm | Invariant記述例 |
|---------|-------------|----------------|
| 決定論的 | Contract + Property | 「出力スキーマが常にXを満たす」「正規化は冪等」 |
| 確率的 | Metamorphic | 「入力スケールを変えても順位は不変」「強い要素追加で既存スコア低下」 |
| バグ修正 | Example | 省略可（再現テストに集中） |

- Paradigm欄が**Example のみ**の場合、不変量を意識的に検討したか確認する
- 検討の上で Example が最適と判断した場合はそのまま進行（強制しない）

### Skip基準（Contract/Property省略可）

以下に該当する場合、Contract/Propertyを省略し Example で進行してよい:

| 条件 | 例 | 理由 |
|------|-----|------|
| 純粋関数 + I/Oがプリミティブ型のみ | `is_even(n) -> bool`, `slugify(s) -> str` | 不変量が自明で、スキーマ定義の価値がない |

- Skip判断は意識的に行うこと（「面倒だから」は理由にならない）
- 迷ったらContract/Propertyを書く（過剰な方が安全）

### 簡潔→詳細TC変換の例

| 簡潔 (Test List) | 詳細 (Formal Test Plan) |
|-------------------|------------------------|
| ログイン成功 | Given: email="test@example.com", password="Pass123!" / When: POST /login / Then: 200, session作成 |
| 空パスワードエラー | Given: email="test@example.com", password="" / When: POST /login / Then: 422, "Password required" |
| 最大文字数超過 | Given: name="a" * 256 / When: POST /users / Then: 422, "Name max 255 chars" |

### Cycle doc記録フォーマット

Cycle doc に「## Formal Test Plan」セクションとして追記:

```markdown
## Formal Test Plan

### TC-01: ユーザーログイン成功
- Given: 有効なユーザー (email: "test@example.com", password: "Pass123!")
- When: POST /api/login with valid credentials
- Then: 200 OK, セッション作成, ダッシュボードへリダイレクト
- Category: 正常系
- Paradigm: Contract
- Invariant: レスポンスは常に {status, token, user} スキーマを満たす
- Test File: tests/auth_test.{ext}
```

## Test Plan Review {#tp-review}

Stage 2 でテスト計画を要件と照合する手順。

### レビューチェックリスト

| # | チェック項目 | 内容 |
|---|-------------|------|
| 1 | 網羅性 | In Scope の全項目に対応するTCが存在するか |
| 2 | エッジケース | null/空/上限/下限のテストがあるか |
| 3 | エラー処理 | 各操作の失敗パターンがカバーされているか |
| 4 | セキュリティ | 認証・認可・入力検証のテストがあるか |
| 5 | 境界値 | 数値/文字列の境界値テストがあるか |
| 6 | Paradigm整合性 | 決定論的コードにContract/Propertyが、確率的コードにMetamorphicが選択されているか。全TCがExampleのみの場合はSkip基準に該当するか確認 |

### Gap分析プロセス

1. Cycle doc の **Scope** セクションの各項目を列挙
2. **Formal Test Plan** の各TCとマッピング
3. TCが存在しない Scope 項目 = **Gap**
4. Gap が見つかった場合:
   - Test List に DISCOVERED 項目として追加
   - Stage 1 に戻り、追加TCを展開

### Gap発見時のDISCOVERED項目追加フロー

```markdown
## Test List

### TODO
- [ ] TC-XX: [Gap分析で発見されたテストケース] ← DISCOVERED

### WIP
...
```

DISCOVERED項目はTest ListのTODOに追加し、次のStage 1実行で詳細化する。

## Dependency Analysis {#dependency-analysis}

テストケースを対象テストファイル別にグルーピングする例:

| テストファイル | テストケース |
|---------------|-------------|
| tests/auth_test.{ext} | TC-01, TC-02 |
| tests/user_test.{ext} | TC-03 |

**原則**: 同一テストファイル→同一workerに割り当て（競合回避）

## Test Execution {#test-execution}

テスト実行コマンドの例:

プロジェクトのテストコマンドで実行（*-quality スキル参照）。

## red-worker並列実行

### 概要

red-workerはREDフェーズで並列実行されるワーカーエージェント。Test List項目を受け取り、失敗するテストコードを作成する。

### 使用方法

```
Task tool で dev-crew:red-worker を起動:
- test_cases: 担当するテストケース
- cycle_doc: Cycle docのパス
- test_files: 作成対象のテストファイル
- language_plugin: 使用する言語プラグイン
```

### Shared Fixtures Handling

並列実行時の共有リソースの扱い:

| リソース | 対応方法 |
|----------|----------|
| conftest.py (pytest) | 並列化対象外、事前に作成 |
| TestCase基底クラス | 並列化対象外、事前に作成 |
| 共有fixture | worker起動前に作成しておく |
| データベースseed | 各workerで独立して実行 |

**原則**: 共有リソースが必要な場合、red-worker起動前にオーケストレーター（red）が作成する。

### 競合回避

- 同一テストファイルは同一workerに割り当て
- 異なるテストファイルは異なるworkerに割り当て可能
- workerは指定されたテストファイルのみ編集

## テスト設計の詳細

### Given/When/Then形式

```
Given: 前提条件（テストの初期状態）
When: アクション（テスト対象の操作）
Then: 期待結果（検証内容）
```

### テストカテゴリ

| カテゴリ | 説明 | 例 |
|---------|------|-----|
| 正常系 | 期待通りの動作 | 有効なデータでログイン成功 |
| 異常系 | エラーハンドリング | 無効なパスワードでエラー |
| 境界値 | 限界値のテスト | 最大文字数ちょうど |
| 権限 | 認可のテスト | 管理者のみアクセス可能 |

### カテゴリ別チェック項目

| カテゴリ | チェック項目 |
|----------|------------|
| **境界値** | 0、-1、MAX_INT、最小/最大長 |
| **エッジケース** | null、undefined、空文字、空配列 |
| **異常系** | 型違い、フォーマット違反、存在しないID |
| **権限** | 未認証、権限不足、他ユーザーのデータ |
| **外部依存** | API失敗、DB失敗、タイムアウト |
| **セキュリティ** | SQLi、XSS、パストラバーサル |

### テスト作成例

```
// Given: 有効なユーザーが存在
// When: 正しい認証情報でログイン
// Then: ダッシュボードにリダイレクト
test "user can login"
  setup: create_user(email: "test@example.com", password: "Pass123!")
  action: post("/login", {email, password})
  assert: response.status == 200
  assert: session.user != null
```

## Error Handling

### テストが成功してしまう場合

```
⚠️ テストが成功しました。REDフェーズでは失敗が期待されます。

確認:
1. 実装コードが既に存在していないか
2. テストの検証が正しいか
3. モックの設定が適切か
```

### テストフレームワークエラー

```
⚠️ テストフレームワークのエラーが発生しました。

確認:
1. 依存関係がインストールされているか
2. 設定ファイルが正しいか
```

## Test Architecture Guide {#test-architecture-guide}

テスト = 仕様の実行可能な表現（Executable Specification）。
詳細な思想・不採用記録: `Keiba/docs/test_architecture.md`

### 2領域モデル

| 領域 | テスト戦略 | 具体例 |
|------|-----------|--------|
| 決定論的 | Data Contract + Property-Based Testing | 特徴量計算、データ変換、CRUD |
| 確率的 | Metamorphic Testing + 統計的Property | ML推論、レコメンド、シミュレーション |

テスト設計原則・Mock方針: `Keiba/docs/test_architecture.md` を参照。

### 言語別ツールマッピング

| 言語 | Data Contract | Property-Based Testing |
|------|--------------|----------------------|
| Python | Pandera / Pydantic | Hypothesis |
| TypeScript | Zod / io-ts | fast-check |
| PHP | Laravel Validation / typed properties | parametrized test (フォールバック) |
| Flutter/Dart | freezed + json_serializable | parametrized test (フォールバック) |
| Hugo | YAML Schema / Frontmatter validation | N/A |

### フォールバック戦略（PBTライブラリなし環境）

PBTライブラリが未導入 or 未成熟の場合:
- **Contract**: 型定義 + バリデーション関数で代替
- **Property**: パラメタライズドテスト（境界値を人間/AIが網羅した配列で検証）
- **精神は同じ**: 「具体例の羅列」ではなく「不変量の検証」を意識する
