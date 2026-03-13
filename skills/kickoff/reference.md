# kickoff Reference

SKILL.mdの詳細情報。必要時のみ参照。

## planファイルからの転記ガイド

### 必須情報

planファイルから以下の情報をCycle docに転記する:

| 情報 | Cycle docセクション | 必須 |
|------|---------------------|------|
| Feature name | タイトル + ファイル名 | Yes |
| In Scope / Out of Scope | Scope Definition | Yes |
| Files to Change | Scope Definition | Yes |
| Layer / Plugin / Risk | Environment > Scope | Yes |
| Language / Dependencies | Environment > Runtime | Yes |
| Risk Interview | Environment > Risk Interview | BLOCKのみ |
| Design Approach | Implementation Notes | Yes |
| Test List | Test List > TODO | Yes |

### planファイルに情報がない場合

| 状況 | 対応 |
|------|------|
| 必須情報が欠落 | ユーザーに確認してCycle docに直接記録 |
| Riskフィールドなし | WARN（標準）として扱う |
| Test Listが空 | エラー: plan modeでTest Listを作成してください |

## フロントマター初期化

KICKOFFフェーズでCycle docを作成する際、全フロントマターフィールドを初期化する。

| フィールド | 設定値 | 参照元 |
|-----------|--------|--------|
| feature | フィーチャー名 | planファイル |
| cycle | YYYYMMDD_HHMM | ファイル名から |
| phase | KICKOFF | 固定 |
| complexity | trivial/standard/complex | planのRiskスコア・規模から仮設定（REDが正式値で上書き） |
| test_count | テスト数 | Test Listのカウント |
| risk_level | low/medium/high | planのRiskフィールドから判断 |
| created | 現在日時 | `date` コマンドで取得 |
| updated | 現在日時 | createdと同値で初期化 |

complexity判断基準（仮値）: Risk 0-20 → trivial, 21-50 → standard, 51+ → complex。REDフェーズでTest List item数ベースの正式分類に上書きされる。
risk_level判断基準: Risk 0-29 → low, 30-59 → medium, 60+ → high。

## タスク粒度

### 基準: 2-5分で完了する1アクション

各タスクは「2-5分で完了できる1つのアクション」に分割する。

| 粒度 | 判断 | 対応 |
|------|------|------|
| 2-5分 | 適切 | そのまま |
| 5分超 | 大きすぎ | 分割する |
| 2分未満 | 小さすぎ | 統合を検討 |

参考: [superpowers/writing-plans](https://github.com/obra/superpowers/blob/main/skills/writing-plans/SKILL.md)

## Test List設計 {#test-list-template}

**Cycle doc テンプレート**:

```markdown
## Test List

### TODO
- [ ] TC-01: [正常系]
- [ ] TC-02: [境界値]
- [ ] TC-03: [エッジケース]
- [ ] TC-04: [異常系]
```

**Given/When/Then形式**:

```
TC-01: ユーザーが有効な認証情報でログインできる
  Given: 有効なユーザーが存在する
  When: 正しい認証情報でログイン
  Then: ダッシュボードにリダイレクト
```

**テストカテゴリ**:

| カテゴリ | 必須 | 適用条件 |
|---------|------|---------|
| 正常系 | 常時 | - |
| 境界値 | 常時 | - |
| エッジケース | 常時 | - |
| 異常系 | 常時 | - |
| 権限 | 条件付き | 認証機能時 |
| 外部依存 | 条件付き | API/DB連携時 |
| セキュリティ | 条件付き | 入力処理時 |

## クロスレイヤー検出

### parallel 提案条件

`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` が有効な場合のみ実行。

| 検出条件 | 判定 |
|---------|------|
| Scope Layer が "Both" | クロスレイヤー |
| In Scope に Backend + Frontend が含まれる | クロスレイヤー |
| Files to Change に 3+ ディレクトリ接頭辞 | クロスレイヤー |

検出時: AskUserQuestion で「parallel（並列開発）を利用しますか？」と提案。

ユーザーが承認 → Cycle doc に記録。review(plan) 後、RED の代わりに `Skill(dev-crew:parallel)` を実行。
ユーザーが拒否 → 通常の red → green → refactor。

## Phase Completion

KICKOFFフェーズ完了後の確認事項。

### チェックリスト

- [ ] Cycle doc の Scope Definition が記録済み
- [ ] Cycle doc の Environment が記録済み
- [ ] Test List が Cycle doc に転記済み
- [ ] Design Approach が Cycle doc に記録済み

## Debate Workflow

### Pre-check

`which codex` で存在確認。不在 → "Codex not available, falling back to review --plan" をProgress Logに記録し、既存plan-reviewを実行。

### Round Loop (max 3)

1. Cycle docをCodexに渡す:
   ```bash
   codex exec --full-auto -o /tmp/codex_debate_r{N}.md -C <project-dir> \
     "Review this Cycle doc and provide counter-arguments: <cycle-doc-path>"
   ```
   初回は新規セッション。session IDをCycle docに記録。
   2回目以降は resume --last（cwdフィルタで同ディレクトリの最新セッションを選択。debate中に別のcodex execを同一ディレクトリで実行しないこと）:
   ```bash
   codex exec resume --last --full-auto -o /tmp/codex_debate_r{N}.md \
     "Response to your counter-arguments: <response-content>"
   ```

2. 反論を読み取り、分類:
   - **Accepted**: 設計変更が必要な具体的指摘 → 設計に反映
   - **Rejected**: 理解したがスコープ外 or リスク受容 → 理由を記録
   - **Deferred**: 人間判断に委ねる → Human Clarificationへ

3. 収束判断:
   - 新しいAccepted指摘がない → 収束
   - 全指摘がRejected → 収束
   - 3ラウンド到達 → 強制収束
   - Deferred残り → 人間に確認してから収束判断

4. Critical/Importantは必ず議論。OptionalはPdMが必要と判断したらCycle docに取り入れる。

### Human Clarification

Deferred項目は選択方式で人間に確認:

```
Q: "<曖昧な仕様>" について:
1. <Option A>
2. <Option B>
3. <Option C (スコープ外にする)>
4. 上記以外（自由記述）
```

選択肢4（フリーフォーム）を常に含め、事前フレーミングに縛られない逃げ道を確保する。

回答後、未収束の指摘が残る場合はRound Loopに戻る（残りラウンド上限を消費する）。

### Result Recording

Cycle doc Implementation Notes に追記:

```markdown
### Debate Summary
- Rounds: N
- Codex Session: <session-id>
- Accepted: [採用した指摘と対応]
- Rejected: [却下した指摘と理由]
- Deferred: [人間判断に委ねた項目と結果]
```

### ADR (cross-cycle判断のみ)

通常のサイクルではCycle doc記録で十分。以下の場合のみ `docs/decisions/ADR-NNN.md` を作成:
- 複数サイクルに影響する設計判断
- 過去のADRを覆す判断
- 人間がDeferred判断を下した場合

ADRテンプレート:

```markdown
# ADR-NNN: タイトル

## Status: accepted | rejected | deferred

## Context
何が問題だったか

## Decision Scorecard
| 項目 | 評価 | 理由 |
|------|------|------|
| Requirements Fit | ... | ... |
| Security | ... | ... |
| Operability | ... | ... |
| Complexity | ... | ... |
| Testability | ... | ... |

## Arguments
### Accepted
### Rejected
### Deferred

## Decision
何を決めたか

## Consequences
その結果どうなるか
```

## Error Handling

### planファイルが見つからない

```
planファイルが見つかりません。

plan modeでINIT + 設計を先に実行してください:
1. EnterPlanMode
2. /spec
3. 探索・設計・Test List作成
4. approve
```

### Test Listが空

```
Test Listが見つかりません。

plan modeでTest Listを作成してください。
```

## エラーメッセージ設計

異常系テストケース作成時に参照。ユーザーフレンドリーなエラーメッセージを設計する。

### 原則

1. **ポジティブフレーミング**: 否定形より肯定形で表現
2. **ユーザーを責めない**: システム視点で状況を説明
3. **次のアクションを提示**: 何をすべきか明示する
4. **技術用語を避ける**: ユーザー視点の言葉を使用

### パターン表

| 避ける | 推奨 |
|--------|------|
| 0件見つかりました | 該当するデータがありません |
| 入力が間違っています | 有効な形式で入力してください |
| 権限がありません | この操作には管理者権限が必要です |
| エラーが発生しました | 処理を完了できませんでした。再度お試しください |
| 無効な値です | 1以上の数値を入力してください |
| 失敗しました | 保存できませんでした。接続を確認してください |
