# review Reference

SKILL.mdの詳細情報。必要時のみ参照。

## Mode 判定詳細

| コンテキスト | Mode | 判定方法 |
|-------------|------|---------|
| orchestrate から PLAN 後に呼ばれた | plan | 直前フェーズが PLAN |
| orchestrate から REFACTOR 後に呼ばれた | code | 直前フェーズが REFACTOR |
| `review --plan` | plan | 引数指定 |
| `review --code` | code | 引数指定 |
| `review` (引数なし) | code | デフォルト |

## Risk Classification 詳細

### Signal と Points

| Signal | Points | 検出方法 |
|--------|:------:|---------|
| auth/security ファイル変更 | +25 | ファイルパスに auth/security/login/password 等 |
| SQL/DB 操作追加 | +25 | diff に SELECT/INSERT/UPDATE/DELETE/DB:: 等 |
| crypto/token/secret パターン | +30 | diff に password/secret/token/hash/encrypt 等 |
| API contract 変更 | +15 | ファイルパスに route/api/controller 等 |
| ファイル数 > 5 | +15 | 変更ファイル数 |
| 変更行数 > 200 | +20 | diff 行数 |
| UI コンポーネント変更 | +10 | ファイルパスに component/view/page/.vue/.tsx 等 |

### Level 判定

| Points | Level | Plan Review Agents | Code Review Agents |
|--------|-------|:------------------:|:------------------:|
| 0-29 | LOW | 2 | 3 |
| 30-59 | MEDIUM | 3-4 | 4-5 |
| 60+ | HIGH | 5-6 | 5-6 |

## Review Brief 形式

```markdown
## Review Brief
### Change Summary
- Type: [new feature | bug fix | refactor | docs | test]
- Scope: [files/dirs changed, count]
- Risk Level: [LOW/MEDIUM/HIGH] (score: NN)

### Key Changes (per-file, 2-3 lines each)
### Security-Relevant Changes
### Logic Hotspots
### Risk Flags
```

## Agent Roster (Plan Mode)

| Agent | Model | Condition |
|-------|-------|-----------|
| review-briefer | Haiku | Always |
| design-reviewer | Sonnet | Always |
| security-reviewer | Sonnet | If auth/security flags |
| product-reviewer | Haiku | If API/user-facing flags |
| performance-reviewer | Sonnet | If DB/perf flags |
| usability-reviewer | Haiku | If UI flags |
| designer | Sonnet | If UI + UI tech stack |

## Agent Roster (Code Mode)

| Agent | Model | Condition |
|-------|-------|-----------|
| review-briefer | Haiku | Always |
| security-reviewer | Sonnet | **Always (NON-NEGOTIABLE)** |
| correctness-reviewer | Sonnet | **Always (NON-NEGOTIABLE)** |
| performance-reviewer | Sonnet | If DB/perf/large-data flags |
| product-reviewer | Haiku | If API/user-facing flags |
| usability-reviewer | Haiku | If UI flags |
| Lint-as-Code | - | Always (ESLint/PHPStan/mypy, LLMコスト0) |

## ブロッキングスコア基準

各エージェントが0-100のブロッキングスコアを返す（0 = 問題なし, 100 = ブロック必須）:

| スコア | 判定 | アクション |
|--------|------|-----------|
| 80-100 | BLOCK | 修正必須 (plan→PLAN再設計 / code→RED/GREEN/REFACTOR) |
| 50-79 | WARN | 警告確認後、次フェーズへ |
| 0-49 | PASS | 次フェーズへ自動進行 |

## BLOCK Recovery

BLOCK 判定時、mode に応じて復帰先が異なる。

### plan mode の BLOCK 復帰

1. BLOCK 指摘事項を Cycle doc の DISCOVERED に記録
2. PLAN フェーズに戻って再設計
3. 再設計後、再度 review --plan を実行

復帰先: **PLAN**

### code mode の BLOCK 復帰

1. BLOCK 指摘事項を Cycle doc の DISCOVERED に記録
2. 指摘内容に応じて適切なフェーズに戻る:
   - ロジックエラー → RED (再現テスト作成) → GREEN (修正)
   - 設計上の問題 → REFACTOR
   - セキュリティ脆弱性 → RED (攻撃テスト作成) → GREEN (修正)
3. 修正後、再度 review --code を実行

復帰先: **RED / GREEN / REFACTOR** (指摘内容に依存)

## 品質チェック詳細

### 静的解析レベル

**PHP (PHPStan)**:
- Level 0-4: 基本的なチェック
- Level 5-6: 中級
- Level 7-8: 厳格（推奨）

**Python (mypy)**:
- 通常モード: 基本的な型チェック
- strict モード: 厳格な型チェック（推奨）

### カバレッジ計測

**除外対象**:
- 設定ファイル
- マイグレーション
- シーダー

## Error Handling

### 品質基準未達

```
品質基準を満たしていません。

対応:
1. 問題をDISCOVEREDに追加
2. REDフェーズに戻ってテスト作成
3. GREENフェーズで修正
4. 再度REVIEWを実行
```

## DISCOVERED issue 起票

REVIEW の PASS/WARN 後、COMMIT の前に実行する。

### データソース

Cycle doc の `### DISCOVERED` セクションから読み取る。

### 判断基準

| 条件 | アクション |
|------|-----------|
| DISCOVERED が空 or `(none)` | スキップ（issue起票なし） |
| 全項目が起票済み（`→ #` 付き） | スキップ |
| 未起票の項目あり | ユーザー確認後に起票 |

### 事前チェック

```bash
gh auth status 2>/dev/null || echo "gh CLI未認証。issue起票をスキップします。"
```

### issue 起票コマンド

```bash
gh issue create --title "[DISCOVERED] <要約>" --body "$(cat <<'EOF'
## 発見元
- Cycle: docs/cycles/<cycle-doc>.md
- Phase: REVIEW
- Reviewer: <reviewer名 or 手動>

## 内容
<DISCOVERED セクションの記載内容>
EOF
)" --label "discovered"
```

### 重複防止

起票済みの項目は Cycle doc で `→ #<issue番号>` マークが付く。
`→ #` が付いている項目は起票をスキップする。

## Competitive Review (via Orchestrate)

Codex 利用可能時、orchestrate が Claude レビュー（本スキル）と Codex レビューを並行実行し、PdM が findings を裁定する。

### Findings Judgment

| 判断 | 条件 |
|------|------|
| Accept | 指摘が妥当 → 即修正 |
| Reject | 明確な理由を説明でき、Codex が納得できる |
| AskUserQuestion | ビジネス判断が必要、または debate が発生 |
| DISCOVERED | 今回のスコープ外 → 次回タスクへ |
| ADR | アーキテクチャ上の重要決定 → 記録 |

本スキルの責務は Claude-side レビューパイプライン。Codex 実行と findings 統合は orchestrate（[steps-codex.md](../orchestrate/steps-codex.md)）が制御する。

## コスト比較

| Scenario | v1 (Current) | v2 (Proposed) | Savings |
|----------|:------------:|:-------------:|:-------:|
| LOW risk (80%) | 11 agents, ~88K tokens | 5 agents, ~25K tokens | ~72% |
| MEDIUM risk | 11 agents, ~88K tokens | 7-9 agents, ~45K tokens | ~49% |
| HIGH risk | 11-12 agents | 10-12 agents, ~75K tokens | ~15% |
