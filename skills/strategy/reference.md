# strategy Reference

SKILL.mdの詳細情報。必要時のみ参照。

## リサーチ詳細

### OSS 類似実装調査

```
WebSearch("keyword + github open source implementation")
```

結果を以下の形式で整理:
- リポジトリ名 + URL
- アプローチの要約
- 採用/不採用の理由

### 技術トレンド調査

```
WebSearch("keyword + best practices 2026")
```

### コスト試算

ActiveUser N人ごとのインフラコスト概算:
- Compute (Lambda/ECS/EC2)
- Storage (S3/RDS/DynamoDB)
- Network (CloudFront/API Gateway)

## タスク分解ガイドライン

### 粒度

- 1 issue = 1 TDD サイクルで完了可能な粒度
- 目安: 変更ファイル数 5 以下、変更行数 200 以下
- これを超える場合はさらに分割

### Acceptance Criteria

各 issue に以下を含める:
- 機能要件（Given/When/Then 形式推奨）
- 非機能要件（パフォーマンス、セキュリティ等）
- テスト基準（カバレッジ目標）

### 依存関係

issue 間の依存は GitHub の task list で管理:

```markdown
## Dependencies
- [ ] #42 (前提: 認証基盤)
- [ ] #43 (前提: DB スキーマ)
```

## Phase A → Phase B の接続

Strategy (Phase A) で作成した Issues は:
1. `search-task` で次の issue を選択
2. `orchestrate` で TDD サイクル (Phase B) を実行
3. Discovered items は `gh issue create` で自動登録
4. 次の `search-task` で自動的に拾える

## Questioning Protocol

### AskUserQuestion テンプレート

各質問は以下の形式で提示:
- question: 判断が必要な論点
- options: 2-4個、各選択肢に pros/cons を description に含める
- multiSelect: 原則 false

### 決定記録テーブル

| # | 論点 | 選択肢 | 決定 | 理由 |
|---|------|--------|------|------|
| D1 | [論点] | A / B / C | [選択] | [根拠] |
| D2 | [論点] | A / B | TBD | 実装フェーズで判明次第決定 |

Issue作成時にTechnical Notesへ転記する。

### ラウンド上限

- 1ステップ最大3ラウンド
- 3ラウンド後の曖昧点は「TBD」として記録し次ステップへ
- TBDはIssueのAcceptance Criteriaに「要確認」として明記
