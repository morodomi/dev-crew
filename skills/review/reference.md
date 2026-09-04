# review Reference

SKILL.mdの詳細情報。必要時のみ参照。

## plan mode 前提

plan mode review は **plan file 前提**で動作する（Cycle doc 不在でも動作する）。Cycle doc は承認後に sync-plan が生成するため、承認前の plan mode review（Codex plan review より前、または人間承認前の Claude design review）は Cycle doc に依存できない。ファイルリスト・PLAN セクションは plan ファイル単体から抽出する。

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
| テストファイル変更 | +10 | ファイルパスに test/spec/__tests__ 等 |
| スキーマ/migration 変更 | +20 | ファイルパスに migration/schema/model 等 |
| 外部通信パターン | +15 | diff に fetch/axios/requests/HttpClient 等 |
| 広範囲変更 (dir spread>=3) | +15 | 変更ファイルのディレクトリ分散度 >= 3 |

### Level 判定

| Points | Level | Plan Review Agents | Code Review Agents |
|--------|-------|:------------------:|:------------------:|
| 0-29 | LOW | 2 | 4 |
| 30-59 | MEDIUM | 3-4 | 5-6 |
| 60+ | HIGH | 5-6 | 6-7 |

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
| test-reviewer | Sonnet | Always (Plan mode) |
| security-reviewer | Sonnet | If auth/security flags |
| product-reviewer | Haiku | If API/user-facing flags |
| performance-reviewer | Sonnet | If DB/perf flags |
| usability-reviewer | Haiku | If UI flags |
| designer | Sonnet | If UI + UI tech stack |
| change-safety-reviewer | Sonnet | If migration/schema flags |
| impact-reviewer | Sonnet | If wide-change flags |
| resiliency-reviewer | Sonnet | If external-comm flags |

## Agent Roster (Code Mode)

| Agent | Model | Condition |
|-------|-------|-----------|
| review-briefer | Haiku | Always |
| security-reviewer | Sonnet | **Always (NON-NEGOTIABLE)** |
| correctness-reviewer | Sonnet | **Always (NON-NEGOTIABLE)** |
| maintainability-reviewer | Sonnet | **Always (NON-NEGOTIABLE)** |
| performance-reviewer | Sonnet | If DB/perf/large-data flags |
| api-contract-reviewer | Sonnet | If API/endpoint flags |
| observability-reviewer | Sonnet | If error-handling/logging flags |
| product-reviewer | Haiku | If API/user-facing flags |
| usability-reviewer | Haiku | If UI flags |
| test-reviewer | Sonnet | If test-file flags |
| Lint-as-Code | - | Always (ESLint/PHPStan/mypy, LLMコスト0) |

## Severity 基準

各エージェントが `severity: critical|important|optional` を issue ごとに返す。verdict への集計は accept-apply/accept-defer に残った findings（reject は除外）を対象に `skills/review/severity-verdict.sh` が行う:

| Severity | 判定 | アクション |
|----------|------|-----------|
| critical ≥ 1 | BLOCK | 修正必須 (plan→PLAN再設計 / code→RED/GREEN/REFACTOR) |
| important ≥ 1 (critical 0) | WARN | 警告確認後、次フェーズへ |
| いずれもなし | PASS | 次フェーズへ自動進行 |

## review_policy 解決規則

`.claude/dev-crew.json` の top-level `review_policy` が、policy 制御対象 reviewer（Code Mode の security-reviewer / correctness-reviewer / maintainability-reviewer、risk-gated の performance-reviewer / api-contract-reviewer / observability-reviewer、および flags-based の test-reviewer）が走るモデルを決定する。

```json
{
  "review_policy": {
    "reviewer_model": "self",
    "escalate_high_to": null
  }
}
```

### フィールド

| フィールド | allowlist | 既定 | 意味 |
|-----------|-----------|------|------|
| `reviewer_model` | `self \| sonnet \| haiku \| opus \| fable` (enumerate-and-reject) | `self` | LOW/MED tier で reviewer が走るモデル |
| `escalate_high_to` | `null \| self \| sonnet \| haiku \| opus \| fable` | `null` | HIGH tier で **代わりに**使うモデル。`null` = escalation なし |

### 解決順（precedence）

1. risk tier が **HIGH** かつ `escalate_high_to` が非 null → `escalate_high_to` を**下記 2 と同じ規則で解決してから** Task の `model:` に渡す（`escalate_high_to` が `self` の場合も 2 の self 解決を適用し、生の `self` を渡さない）
2. それ以外（LOW/MED、または `escalate_high_to` が `null`）→ `reviewer_model` を解決
   - `self`: reviewer agent の frontmatter が sonnet に pin されているため、Task で `model:` を省略すると frontmatter の sonnet に落ちる（orchestrator の現モデルには自動継承されない）。そのため **self なら orchestrator 自身が現在動いているモデルを Task の `model:` に明示的に渡す**（省略しない）
   - **allowlist 外の値**（`self|sonnet|haiku|opus|fable` 以外）: `self` にフォールバック（fail-safe。未定義 model literal を Task に渡さず、floor の起動を壊さない）
   - `sonnet | haiku | opus | fable`: その値をそのまま Task の `model:` に渡す
3. **Codex（peer-vendor）は直交で常時 always-on**（`which codex` gate、既存の competitive review 機構）。review_policy はモデル選択の対象ではなく、Codex 実行有無に影響しない
4. `human` policy（人間レビューへの一時停止）は v1 対象外（follow-up issue）

### NON-NEGOTIABLE floor（不変）

security-reviewer と correctness-reviewer は `review_policy`/risk score に関係なく常時起動する。policy が制御するのは「どのモデルで走るか」であって「起動するか」ではない。config でこの起動を無効化することはできない（security review bypass 防止）。

### 実行時制約

実行時にどのモデルが実際に選ばれるかは Claude Code の env / org allowlist に依存するため決定論的に pin できない。契約テスト（`tests/test-review-policy.sh`）が pin するのは schema/allowlist・手順文の存在・固定 model literal の除去・NON-NEGOTIABLE 記述であり、実モデル選択そのものではない。

## Verdict Escalation (PdM 判断基準)

Step 4.5 で Socrates が返した反論に基づき、PdM が verdict の昇格を判断する。Socrates は反論+選択肢を返すのみで、severity や verdict は付けない（advisor 原則維持）。昇格根拠は「件数と score の乖離」ではなく、Socrates が示した**見落とし・二次影響の実証**とする。

| Socrates の反論内容 | 元の verdict | PdM の判断 |
|-------------------|-------------|-----------|
| 反論なし（稀） | そのまま | そのまま |
| 反論あり、二次影響の指摘なし | そのまま | そのまま |
| 反論あり、reviewer が見逃した二次影響を指摘 | PASS | WARN に昇格を検討 |
| 反論あり、important の見落としを具体的に実証 | PASS/WARN | 1段階昇格を検討 |
| 反論あり、BLOCK 妥当性の補強 | BLOCK | BLOCK（変化なし） |

原則: PdM は verdict を下げない（厳しい方向にのみ作用）。

### 判断の根拠例

- important の見落とし（reviewer が指摘しなかった具体的な箇所）を Socrates が実証 → WARN 昇格検討
- キャッシュ構造変更 + reviewer がデプロイ影響を未指摘 → 二次影響見逃し → WARN 昇格検討
- critical 0件 + optional のみ → 反論があっても verdict 維持

## BLOCK Recovery

BLOCK 判定時、mode に応じて復帰先が異なる。

### plan mode の BLOCK 復帰

1. BLOCK 指摘事項を記録する。Cycle doc が既に存在する場合は DISCOVERED セクションへ、承認前で Cycle doc 不在の場合はそのターンの応答に含めて出力する（plan file 前提、skip）
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

## Gotchas

| # | 症状 | 原因 | 対策 |
|---|------|------|------|
| G-01 | mode判定誤り(planをcodeで実行) | 引数なしはcode(default) | --plan/--codeを明示指定 |
| G-02 | REFACTOR記録未検出 | Progress Log表記揺れ | grep -qiEでcase insensitive |
| G-03 | LOW riskで全agent起動 | Risk-based scaling不適用 | risk-classifier.sh判定に従う |
| G-04 | Codex competitive review未試行 | CLAUDE.mdルール忘れ | steps-codex.mdのCompetitive Reviewセクション参照 |
| G-05 | DISCOVERED issue起票忘れ | Step 7スキップ | review完了前にDISCOVERED確認 |
