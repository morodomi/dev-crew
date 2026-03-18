# Roadmap

> Phase 1-10 の完了履歴は [docs/archive/development-plan.md](docs/archive/development-plan.md) を参照。
> Phase 11-13 (v2) の詳細は本ファイル下部を参照。

## 現在地

v2.5.0 リリース済み。v3 (Constitution-Driven Development) Phase 1-7 完了。
v2.4 は Review Taxonomy 体系化。Phase 14-17 完了。v2.4.1 で DISCOVERED 修正。
v2.4.2 で Phase 13 skill-map + Phase 18 Post-Approve Action 強制。
v2.4.3 で Post-Approve Action を hook 化。
v2.5.0: Constitution-Driven Enforcement（hook 強制 + Constitution Check + Socrates Plan Review）。
v2.6 計画中（Phase 21-23: exspec 深層統合 + Phase 19-20: 構造厳格化・コスト最適化）。

## v3: Constitution-Driven Development

CONSTITUTION.md を最上位規範（Layer 0）として導入し、PHILOSOPHY.md を分解・再構成する。
詳細設計: [v3-constitution-design.md](docs/v3-constitution-design.md) / Issue: #75

### Phase 1: dev-crew CONSTITUTION 理想形 (設計完了)

- CONSTITUTION.md の構成設計（8章、~50行）
- PHILOSOPHY.md の分解マッピング
- 5-Layer Authority 定義
- 影響ファイル一覧の完全化

### Phase 2: App 型適用検討

一般化した適用ガイドを docs/ に資料化。プロジェクト固有情報は含めない。

### Phase 3: CLI 型適用検討

同上。

### Phase 4: Data/ML 型適用検討

同上。

### Phase 5: 一般化 vs 個別最適化

Phase 2-4 の検証結果を基に判断:
- 一般化テンプレート 1 本で済むか
- プロジェクト型別テンプレートが必要か
- Layer 名は全型で共通か

### Phase 6: dev-crew 自体を理想形に変更 (完了)

CONSTITUTION.md 新設、PHILOSOPHY.md 分解、参照移行（authority migration）。

### Phase 7: 他プロジェクト向けスキル実装 (完了)

onboard スキルに CONSTITUTION.md 生成を追加。
型検出（Skills/App/CLI/Data/ML/Generic/混合）+ 共通骨格5章 + 型別拡張章テンプレート。
migration 支援（philosophy.md スキャン、CLAUDE.md 肥大化検出）。

### Phase 8: リリース (v2.3.0, 完了)

---

## v2.5: Constitution-Driven Enforcement

CONSTITUTION 原則6（決定論的プロセス保証）の実現。hook によるプロセス強制、Constitution 整合性チェック、Socrates adversarial review を追加。

### Phase 18: Post-Approve Action 強制 (完了)

Post-Approve Action を hook（plan-exit-flag.sh + post-approve-gate.sh）で決定論的に強制。
rules/memory/onboard テンプレートの3層から、hook による確実なブロックに移行。

| 項目 | 状態 |
|------|------|
| plan-exit-flag.sh | 完了: ExitPlanMode 後にフラグファイル作成 |
| post-approve-gate.sh | 完了: フラグ存在時に Edit/Write をブロック（exit 2） |
| orchestrate クリア | 完了: orchestrate 起動時にフラグ削除 |
| テスト | 完了: 9 テストケース（test-post-approve-gate.sh） |

### Phase 18.1: Constitution 整合性チェック (完了)

spec/plan-review に CONSTITUTION.md との整合性チェックを追加。

| 項目 | 状態 |
|------|------|
| spec reference.md | 完了: Constitution Check ステップ追加 |
| design-reviewer agent | 完了: constitution_alignment 観点追加 |
| テスト | 完了: test-post-approve-action.sh に検証追加 |

### Phase 18.2: Socrates Plan Adversarial Review (完了)

Codex 不在時に Socrates を plan adversarial reviewer として起動。

| 項目 | 状態 |
|------|------|
| orchestrate reference.md | 完了: Codex 不在時 Socrates fallback |
| spec reference.md | 完了: Socrates plan review パス追加 |
| テスト | 完了: test-post-approve-action.sh に検証追加 |

---

## v2.6: exspec 深層統合 + ワークフロー厳格化

exspec CLI (v0.3.0) の lint / observe / init を dev-crew ワークフローに深層統合する。現行の RED フェーズ gate（exspec-check.sh）を超え、spec・onboard・review フェーズにも exspec を活用する。

### Phase 21: exspec observe 統合

exspec observe のテスト-コードマッピングを spec/RED フェーズで活用し、テストカバレッジのギャップを可視化する。

| 項目 | 内容 |
|------|------|
| spec 連携 | spec フェーズで `exspec observe` を実行し、未テストの本番コードを特定。Test List 作成の入力にする |
| RED 連携 | RED フェーズ完了時に `exspec observe` で新規テストのマッピング検証（テストが意図した本番コードを参照しているか） |
| ゲートスクリプト | scripts/gates/exspec-observe-check.sh 新設 |
| テスト | test-exspec-observe-integration.sh 新設 |

### Phase 22: exspec init 統合

exspec init（`.exspec.toml` 自動生成）を onboard スキルに統合する。

| 項目 | 内容 |
|------|------|
| 前提 | exspec 側で `exspec init` コマンドが実装済みであること |
| onboard 連携 | onboard スキルのセットアップフローに `exspec init` を追加。フレームワーク検出 → `.exspec.toml` 生成 |
| exspec 未インストール時 | スキップ（既存パターン踏襲） |
| テスト | test-onboard-exspec-init.sh 新設 |

### Phase 23: exspec lint 連携評価・改善

現行の `exspec-check.sh` を評価し、observe データとの組み合わせや severity 調整を検討する。

| 項目 | 内容 |
|------|------|
| 連携評価 | RED gate での exspec lint 実績（BLOCK/WARN 検出率、FP 率）を収集・分析 |
| observe 連動 | observe の unmapped ファイル情報を lint の context として渡す可能性を検討 |
| severity 調整 | dev-crew コンテキストでの severity 最適化（例: WARN → BLOCK 昇格の条件定義） |
| --strict モード | CI 統合時の `--strict` 適用基準を策定 |

### Phase 19: ディレクトリ構造厳格化

ROADMAP.md, STATUS.md, docs/cycles/ の構造規約をルール化し、検証スクリプトを新設する。

| 項目 | 内容 |
|------|------|
| 構造規約ルール | rules/ にディレクトリ構造ルールを追加 |
| 検証スクリプト | test-directory-structure.sh 新設（必須ファイル・ディレクトリの存在確認） |
| onboard 反映 | onboard スキルのテンプレートに構造規約を反映 |

### Phase 20: Socrates コスト最適化

LOW risk PR での Socrates 起動をスキップし、Opus トークンコストを削減する。

| 項目 | 内容 |
|------|------|
| Risk-gated 条件 | risk-classifier.sh の score が LOW (0-29) の場合、Step 4.5 Socrates をスキップ |
| 期待効果 | LOW risk PR（全体の ~60%）で Opus コスト削減 |
| テスト | risk level 別の Socrates 起動有無テスト |

---

## v2.4: Review Taxonomy 体系化

セキュリティレビューが OWASP Top 10 / CWE Top 25 に基づく 19 attacker agent で体系化されているのに対し、Plan Review / Test Review / Code Review は汎用的な観点のみだった。権威ある参照元に基づき、専門 reviewer agent を体系的に追加する。

設計原則:
- **CLI（決定論）と Agent（意味論）の責務分離**: 既存の *-quality スキル / exspec / gate script が CLI 層を担い、新設 agent は意味論に集中する
- **Risk-gated scaling**: 全 PR で全 agent を起動しない。リスク検出時のみ専門 agent を追加起動
- **既存 review スキルに統合**: スキル数は増やさない。review スキルの内部で呼ぶ agent が増える
- **段階的追加**: セキュリティ 19 agent の成功パターンを踏襲。1体ずつ追加→テスト→次へ

Phase 順序は ROI 順（頻度 x 効果）。Code Review は毎サイクル実行で最も効果が高い。

### Phase 14: Code Review 強化 (完了)

GREEN/REFACTOR 後の品質レビュー。既存の *-quality スキルが CLI 層を担い、agent は意味論に集中。毎サイクル Always-on で起動するため ROI が最も高い。

#### 14.1 maintainability-reviewer 新設

「読めるか・変更しやすいか」に特化。correctness（動くか）とは分離。

| 項目 | 内容 |
|------|------|
| 参照元 | Fowler [Code Smells](https://refactoring.guru/refactoring/smells) (5カテゴリ22種) + [SonarQube Cognitive Complexity](https://www.sonarsource.com/resources/library/code-smells/) + [Google Engineering Practices](https://google.github.io/eng-practices/review/) |
| 観点 | Bloaters, OO Abusers, Change Preventers, Dispensables, Couplers / SRP / ドメイン命名 |
| 起動条件 | Always-on |
| CLI 層 | 既存 *-quality (Linter/formatter) がカバー。agent は Linter が拾えない意味論を担当 |
| モデル | Sonnet |

#### 14.2 api-contract-reviewer 新設

API の破壊的変更と設計品質。

| 項目 | 内容 |
|------|------|
| 参照元 | [Google API Design Guide](https://cloud.google.com/apis/design) + [Microsoft REST API Guidelines](https://github.com/microsoft/api-guidelines) + [Azure Breaking Changes Guidelines](https://github.com/Azure/azure-rest-api-specs/blob/main/documentation/Breaking%20changes%20guidelines.md) |
| 観点 | required field 後追い追加、enum 値削除、レスポンス型変更、URL パス変更、エラー構造、リソース命名 |
| 起動条件 | Risk-gated: API/エンドポイントファイル変更時 |
| モデル | Sonnet |

#### 14.3 observability-reviewer 新設

本番での可観測性。

| 項目 | 内容 |
|------|------|
| 参照元 | Google [SRE Book](https://sre.google/sre-book/monitoring-distributed-systems/) (Four Golden Signals) + [OpenTelemetry Semantic Conventions](https://opentelemetry.io/docs/specs/semconv/) + [CNCF Observability Whitepaper](https://github.com/cncf/tag-observability/blob/main/whitepaper.md) |
| 観点 | エラーパスのログ有無、構造化ログ(JSON)、trace ID 伝播、メトリクス計装、ハードコード閾値 |
| 起動条件 | Risk-gated: エラーハンドリング/ログ変更時 |
| モデル | Sonnet |
| 注意 | correctness-reviewer の「例外処理」観点と重複しうる。agent 間 dedup ルールを定義すること |

#### 14.4 performance-reviewer 強化

既存 agent の rubric を参照元ベースで深化。

| 項目 | 内容 |
|------|------|
| 追加参照元 | [SEI CERT Coding Standards](https://wiki.sei.cmu.edu/confluence/display/seccode) (並行性観点) |
| 追加 rubric | N+1 クエリパターン、O(n²) ループ、shared mutable state、ロック順序不整合 |
| 変更内容 | 既存の Algorithm efficiency / Memory usage に加え、並行性観点を吸収 |

### Phase 15: Test Review 強化 (完了)

RED フェーズの品質に直結。ROI 2番目。

#### 15.1 test-reviewer 新設 (Code mode)

テストコード品質を見る。RED 後のレビューで起動。

| 項目 | 内容 |
|------|------|
| 参照元 | [xUnit Test Patterns](http://xunitpatterns.com/) (Meszaros, 68パターン + 18テストスメル) + Google [SWE Book Ch11-12](https://abseil.io/resources/swe-book/html/ch11.html) |
| Code mode 観点 | Fragile Test, Obscure Test, Mystery Guest, Conditional Test Logic, Test Code Duplication |
| 起動条件 | Risk-gated: テストファイル変更時 |
| CLI 層との連携 | exspec が RED 後のテストコード静的解析を担当（既存） |
| モデル | Sonnet |

#### 15.3 Socrates Devil's Advocate review pipeline 統合

review pipeline の Step 4.5 に Socrates を組み込み、reviewer の忖度バイアスと二次影響の見逃しを構造的に検出する。

| 項目 | 内容 |
|------|------|
| タイミング | Specialist Panel → **Socrates** → Score Aggregation |
| 起動条件 | 全レビュー（PASS/WARN/BLOCK 問わず） |
| モデル | Opus |
| メカニズム | Socrates は反論+選択肢を返すのみ。PdM が Score Escalation 基準に基づき verdict 昇格を判断 |
| 役割分担 | Reviewer = 広さ（専門ドメイン網羅）、Socrates = 深さ（変更の二次影響を掘る） |

#### 15.2 test-reviewer Plan mode 拡張

Phase 16 で Plan Review に統合する際に Plan mode を追加。Phase 15 では Code mode のみ先行実装。

| 項目 | 内容 |
|------|------|
| Plan mode 観点 | TC カバレッジ（Scope 項目あたり TC 数）、異常系 TC 有無、テスト独立性、Given/When/Then 形式 |
| 起動条件 | Always-on (Plan mode) |
| 依存 | Phase 16 の Plan Review 統合基盤 |

### Phase 16: Plan Review 強化 (完了)

spec 時のみ起動。頻度は低いが設計レベルの問題を防ぐ。

#### 16.1 change-safety-reviewer 新設

ロールバック安全性 + マイグレーション安全性を統合した観点。

| 項目 | 内容 |
|------|------|
| 参照元 | Fowler [Evolutionary DB Design](https://martinfowler.com/articles/evodb.html) + [Feature Toggles](https://martinfowler.com/articles/feature-toggles.html) + [Parallel Change](https://martinfowler.com/bliki/ParallelChange.html) |
| サブ観点 | deploy rollback / schema migration / feature flag / blast radius / irreversible step detection |
| 起動条件 | Risk-gated: risk-classifier.sh によるリスク判定（後述） |
| モデル | Sonnet |
| 注意 | design-reviewer の risk 観点は**移管しない**（scope と risk の相関判断を維持）。change-safety は design-reviewer が risk フラグを出した後の**追加深掘り**として起動 |

#### 16.2 impact-reviewer 新設

変更の連鎖影響と破壊範囲を分析する。

| 項目 | 内容 |
|------|------|
| 参照元 | [C4 Model](https://c4model.com/) + SEI [ATAM](https://www.sei.cmu.edu/library/architecture-tradeoff-analysis-method-collection/) |
| 観点 | 依存モジュール列挙、公開 API 変更有無、SPOF 生成、循環依存 |
| 起動条件 | Risk-gated: risk-classifier.sh によるリスク判定 |
| モデル | Sonnet |

#### 16.3 resiliency-reviewer 新設

耐障害性・カスケード障害防止の観点。Gemini/Grok/GPT 全員が独立観点として追加を推奨。

| 項目 | 内容 |
|------|------|
| 参照元 | [AWS Well-Architected Reliability Pillar](https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/) + Google [SRE Book](https://sre.google/sre-book/monitoring-distributed-systems/) |
| 観点 | タイムアウト設定、リトライ戦略(backoff/jitter)、サーキットブレーカー、カスケード障害防止 |
| 起動条件 | Risk-gated: 外部通信/非同期処理検出時 |
| モデル | Sonnet |

#### 16.4 design-reviewer 強化

既存 agent の rubric に過剰設計検出を明示追加。**risk 観点は維持**（scope-risk 相関判断を保つ）。

| 項目 | 内容 |
|------|------|
| 追加参照元 | Fowler Code Smells [Dispensables](https://refactoring.guru/refactoring/smells/dispensables) (Speculative Generality, Dead Code) |
| 追加 rubric | 不要抽象化、1箇所からしか呼ばれない interface、未使用の設定パラメータ |
| 変更内容 | risk 維持 + 過剰設計観点を追加 |

#### 16.5 test-reviewer Plan mode 統合

15.2 で設計した Plan mode を Plan Review に組み込む。

#### 16.6 risk-classifier.sh 拡張

Risk-gated agent の起動条件を決定論的に判定する。既存の risk-classifier.sh を拡張。

| 新条件 | 判定方法 | 起動する agent |
|--------|---------|---------------|
| スキーマ変更 | migration ファイル検出、ORM model 定義変更 | change-safety-reviewer |
| API 変更 | route/controller/endpoint ファイル変更 | api-contract-reviewer (Code) / change-safety (Plan) |
| 外部通信 | HTTP client/SDK import、async/await パターン | resiliency-reviewer |
| 広範囲変更 | 変更ファイルのディレクトリ分散度 | impact-reviewer |
| エラーハンドリング | try/catch/except ブロック変更 | observability-reviewer |
| テストファイル | test ディレクトリ内ファイル変更 | test-reviewer |

### Phase 17: 統合・リリース (完了)

#### 17.1 段階的統合テスト

セキュリティ 19 agent の成功パターンを踏襲。1体ずつ追加→テスト→次へ。

各 agent 追加時の検証:
1. 既存 reviewer との重複指摘検出（deduplication テスト）
2. Risk-gated 起動条件の精度検証（過去 10 サイクルで再現テスト）
3. review スキル統合後のリグレッションテスト

#### 17.2 review スキル Risk-gated scaling 拡張

新設 agent を review スキルの選択ロジックに組み込む。

```
Always-on（全サイクル）:
  Plan: design-reviewer, test-reviewer (Plan mode)
  Code: correctness-reviewer, security-reviewer, maintainability-reviewer

Risk-gated（risk-classifier.sh 判定時のみ）:
  Plan: change-safety-reviewer, impact-reviewer, resiliency-reviewer, product-reviewer
  Code: api-contract-reviewer, observability-reviewer, performance-reviewer,
        test-reviewer (Code mode), usability-reviewer
```

#### 17.3 スキルマップ更新

Phase 13 のスキルマップに新 agent の位置を追加。

#### 17.4 リリース (v2.4.0)

### 統廃合サマリ

| Agent | 現状 | v2.4 後 | 変更 |
|-------|------|-------|------|
| design-reviewer | Plan: スコープ + アーキ + リスク | Plan: スコープ + アーキ + リスク + 過剰設計 | risk 維持、過剰設計追加 |
| product-reviewer | Plan: ビジネス判断 | 維持 | - |
| correctness-reviewer | Code: ロジック + エッジケース | 維持 | - |
| performance-reviewer | Code: 効率 + メモリ | 強化: + 並行性 | 並行性を吸収 |
| security-reviewer | Code: OWASP | 維持 | - |
| usability-reviewer | Code: UX/UI | 維持 | - |
| **maintainability-reviewer** | - | **新設**: Code: 保守性 (Always-on) | - |
| **api-contract-reviewer** | - | **新設**: Code: API 契約 | - |
| **observability-reviewer** | - | **新設**: Code: 可観測性 | - |
| **test-reviewer** | - | **新設**: Plan+Code: TC 品質 + テストスメル (dual mode) | - |
| **change-safety-reviewer** | - | **新設**: Plan: ロールバック + マイグレーション | design-reviewer の深掘り |
| **impact-reviewer** | - | **新設**: Plan: 依存分析 + 影響範囲 | - |
| **resiliency-reviewer** | - | **新設**: Plan: 耐障害性 | - |

最終: 33 agents → 40 agents / 29 skills → 29 skills（変更なし）

### 実装順序

```
Phase 14: Code Review（ROI 最大、毎サイクル起動）
  14.1 maintainability-reviewer → テスト → 統合
  14.2 api-contract-reviewer → テスト → 統合
  14.3 observability-reviewer → テスト → 統合（correctness との dedup 確認）
  14.4 performance-reviewer 強化 → テスト
    ↓
Phase 15: Test Review（ROI 2番目、RED 品質直結）
  15.1 test-reviewer Code mode → テスト → 統合
    ↓
Phase 16: Plan Review（頻度低、設計レベル防御）
  16.1 change-safety-reviewer → テスト → 統合
  16.2 impact-reviewer → テスト → 統合
  16.3 resiliency-reviewer → テスト → 統合
  16.4 design-reviewer 強化 → テスト
  16.5 test-reviewer Plan mode 統合
  16.6 risk-classifier.sh 拡張
    ↓
Phase 17: 統合・リリース
  17.1 段階的統合テスト（全 agent 横断）
  17.2 review スキル統合
  17.3 スキルマップ更新
  17.4 v2.4.0 リリース
```

### 参照元一覧

| 参照元 | 形式 | 対象 agent | URL |
|--------|------|-----------|-----|
| Fowler Code Smells | カタログ (22種) | maintainability | https://refactoring.guru/refactoring/smells |
| SonarQube Cognitive Complexity | ルール集 | maintainability | https://www.sonarsource.com/resources/library/code-smells/ |
| Google Engineering Practices | ガイドライン | maintainability | https://google.github.io/eng-practices/review/ |
| Google API Design Guide | チェックリスト | api-contract | https://cloud.google.com/apis/design |
| Microsoft REST API Guidelines | チェックリスト | api-contract | https://github.com/microsoft/api-guidelines |
| Azure Breaking Changes | チェックリスト | api-contract | https://github.com/Azure/azure-rest-api-specs/blob/main/documentation/Breaking%20changes%20guidelines.md |
| Google SRE Book | 章立て体系 | observability, resiliency | https://sre.google/sre-book/monitoring-distributed-systems/ |
| OpenTelemetry Semantic Conventions | 仕様 | observability | https://opentelemetry.io/docs/specs/semconv/ |
| CNCF Observability Whitepaper | ホワイトペーパー | observability | https://github.com/cncf/tag-observability/blob/main/whitepaper.md |
| SEI CERT Coding Standards | ルール集 | performance (並行性) | https://wiki.sei.cmu.edu/confluence/display/seccode |
| xUnit Test Patterns | パターン集 (68+18) | test-reviewer | http://xunitpatterns.com/ |
| Google SWE Book Ch11-12 | ガイドライン | test-reviewer | https://abseil.io/resources/swe-book/html/ch11.html |
| Fowler Evolutionary DB Design | 記事 | change-safety | https://martinfowler.com/articles/evodb.html |
| Fowler Feature Toggles | 記事 | change-safety | https://martinfowler.com/articles/feature-toggles.html |
| C4 Model | モデリング手法 | impact | https://c4model.com/ |
| SEI ATAM | 評価手法 | impact | https://www.sei.cmu.edu/library/architecture-tradeoff-analysis-method-collection/ |
| AWS Well-Architected Reliability | チェックリスト | resiliency | https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/ |
| Fowler Dispensables | カタログ (部分) | design-reviewer | https://refactoring.guru/refactoring/smells/dispensables |

---

## v2 (完了): Claude + Codex 統合開発フロー

## Phase 11: Claude + Codex 統合開発フロー

PHILOSOPHY.md の target philosophy を既存スキルに反映する。

### 11.1 kickoff → sync-plan 移行 (完了)

kickoff スキルを sync-plan agent に置き換え、spec 内部から呼ぶ軽量エージェント化。

#### マイグレーション対象

| 対象 | 変更内容 |
|------|---------|
| skills/kickoff/ | sync-plan agent に変換。spec から Task() で呼び出し |
| skills/spec/ | sync-plan 呼び出しを追加。plan review → approve → sync-plan の順序 |
| skills/orchestrate/ | kickoff → sync-plan 参照更新。Post-Approve Action 修正 |
| skills/review/ | Cycle Doc Gate の kickoff 参照更新 |
| skills/red/, green/, commit/ | Cycle Doc Gate の kickoff 参照更新 |
| skills/refactor/, diagnose/ | kickoff 参照更新 |
| skills/strategy/ | Step 4 の review(plan) を spec 内部 Codex plan review に修正 |
| agents/architect.md | Skill(kickoff) 呼び出しを sync-plan に更新 |
| rules/state-ownership.md | kickoff パーミッション行を sync-plan に更新 |
| CLAUDE.md | Usage Patterns、Auto-orchestrate 記述更新 |
| AGENTS.md | Workflow セクション更新 |
| docs/terminology.md | kickoff → sync-plan 用語更新 |
| docs/architecture.md | フロー図更新 |
| docs/usability.md | kickoff 参照更新 |
| docs/project-conventions/skill-md-frontmatter.md | kickoff 参照更新 |
| tests/ | 6ファイル rename + 内容更新 (test-auto-kickoff, test-kickoff-debate, test-architect-improvement, test-decision-records, test-phase-gate, test-state-ownership) |

#### 互換性方針

kickoff エイリアスは残さない。完全置換。live docs から `kickoff` が 0 件になることをマイグレーション完了条件とする。

```bash
# 完了条件チェック（履歴ドキュメントは除外）
rg "kickoff" skills/ CLAUDE.md AGENTS.md docs/ \
  --glob '!docs/cycles/**' \
  --glob '!docs/ROADMAP.md' \
  --glob '!docs/STATUS.md' \
  --glob '!docs/archive/**'
# → 0 件で完了
```

### 11.2 Codex 委譲インターフェース (完了)

orchestrate スキルに Codex 委譲パスを追加。各実行フェーズのスキルにもCodex委譲情報を反映。

#### セッション管理

| イベント | 操作 | 備考 |
|---------|------|------|
| plan review 時 | `codex exec` で新規セッション作成 | plan ファイルパスをプロンプトに含める |
| RED/GREEN/REVIEW 委譲 | `codex exec resume --last` | cwd フィルタにより同ディレクトリ内の最新セッションが選ばれる |
| サイクル完了 | セッション破棄 | 次サイクルは新規 |
| resume 失敗時 | 新規セッション作成で retry | stale session は自動回避 |

#### Codex 利用可否判定

```
which codex && codex exec --full-auto "echo ok" → 成功: Codex 利用可能
→ 失敗: Claude fallback（既存スキルそのまま）
```

#### 委譲フロー

```
orchestrate
  ├─ Codex 利用可能
  │   ├─ RED: codex exec resume --last "red docs/cycles/xxx.md"
  │   ├─ GREEN: codex exec resume --last "green docs/cycles/xxx.md"
  │   ├─ REFACTOR: Claude（独自ロジック。Codex fallback）
  │   └─ REVIEW: Claude review + codex exec resume --last "review code docs/cycles/xxx.md"
  │
  └─ Codex 不在
      └─ 全フェーズ Claude（現行動作維持）
```

#### スキル別 Codex 委譲ドキュメント更新

| スキル | 更新内容 |
|--------|---------|
| skills/red/reference.md | Codex 委譲セクション追加（Codex優先、Claude fallback） |
| skills/green/reference.md | Codex 委譲セクション追加（Codex優先、Claude fallback） |
| skills/review/SKILL.md + steps-subagent.md | 競争的レビューパターン追加（Claude + Codex 並行） |
| skills/refactor/SKILL.md | Codex fallback 記述追加。`/simplify` は Claude 専用だが、Codex には独自 refactor を実行させる |
| skills/orchestrate/steps-codex.md | REVIEW の「supplementary」を「competitive」に修正 |

### 11.3 競争的レビュー (完了)

- review スキルに Codex レビュー統合
- Claude review + Codex review の findings 集約フロー
- findings 判断ロジック: Accept / Reject / AskUserQuestion / DISCOVERED / ADR

### 11.4 exspec 統合 (完了)

- RED 最終ステップに exspec 実行を追加
- exspec 未インストール時はスキップ（既存パターン踏襲）

### 11.5 マイグレーション検証 (完了)

- ~~kickoff → sync-plan の grep ベース参照チェックテスト追加~~
- ~~既存テストの kickoff 参照を sync-plan に更新~~
- ~~マイグレーション完了条件: live docs の kickoff 参照が 0 件（11.1 の完了条件チェックコマンド参照）~~
- 11.1 実施時に既存テスト・参照を全て更新済み。live docs の kickoff 参照 0 件を確認。

### 11.6 onboard スキル改善 (完了)

今回のdev-crew自身のドキュメント整備で得た知見を、onboard skillが他プロジェクトで生成するドキュメントに反映する:

#### AGENTS.md テンプレート改善
- Start Here セクション（最初の行動指針）
- テストコマンドの正確性（`bash tests/*.sh` ではなく `for f in; do bash "$f"; done`）
- 数値カウントはSTATUS.mdに任せ、AGENTS.mdには書かない
- migration注記パターン（対象プロジェクトに上位方針文書がある場合のみ。なければ不要）

#### CLAUDE.md テンプレート改善
- Codex Integrationセクションのパターンを反映
- Skills trigger table は不要（プラグインシステムが自動検出）

#### Codex 環境セットアップ
- sync-skills スキルへの誘導を追加
- Codex 利用可能時の初期セッション作成案内

対象: skills/onboard/reference.md

### 11.7 refactor スキル再構築 (完了)

現状 refactor は Claude Code の `/simplify` に完全委譲しているが、Codex には `/simplify` がない。cross-tool で動作する独自 refactor ロジックを復活させる。

- `/simplify` 依存を解消し、独自の品質改善ロジックをスキル内に持つ
- Claude 実行時: 独自ロジック（`/simplify` は使わない。または optional で併用）
- Codex 実行時: 同じ独自ロジックで動作
- 観点: N+1、変数宣言、const、重複コード、未使用変数、型の一貫性

#### `/simplify` 依存の波及箇所

| 対象 | 変更内容 |
|------|---------|
| skills/refactor/SKILL.md | `/simplify` 委譲を独自ロジックに置換 |
| skills/refactor/reference.md | 独自 refactor ロジックの詳細を記述 |
| skills/orchestrate/steps-subagent.md | refactor 委譲パスの更新 |
| skills/orchestrate/steps-teams.md | refactor 委譲パスの更新 |
| skills/orchestrate/reference.md | REFACTOR フェーズ説明の更新 |
| skills/reload/SKILL.md | REFACTOR 復元時の参照更新 |
| skills/reload/reference.md | REFACTOR 復元時の参照更新 |
| CLAUDE.md | `/simplify` 参照の更新 |
| docs/terminology.md | refactor 用語説明の更新 |

### 11.10 決定論的ゲート基盤 (v2.1.0, 完了)

「プロセス強制は決定論的コード、品質検出はLLM」の責務分離原則に基づく。

| 項目 | 内容 |
|------|------|
| pre-red-gate.sh | RED開始前にCycle doc存在・sync-plan完了・Plan Review記録を検証 |
| pre-commit-gate.sh | COMMIT前にCode Review記録・Codex competitive review記録・STATUS.md同期を検証 |

### 11.11 Review品質改善 (v2.1.0, 完了)

| 項目 | 内容 |
|------|------|
| spec上流整合性チェック | requirements/ROADMAPとの整合確認、design-reviewerにupstream観点追加 |
| steps-codex.md改善 | REVIEWプロンプトのスコープ制限、Why Competitive Review Works文書化、Open Questions追跡 |
| correctness-reviewer拡張 | テストアサーション品質観点追加 |
| red reference品質ルール | Design Spec照合、AND条件ルール、検証粒度ルール、動的取得推奨 |

### 11.12 テスト設計品質 + ツール改善 (v2.1.0, 完了)

| 項目 | 内容 |
|------|------|
| risk-classifier.sh | 低リスクファイルタイプ除外、新規ファイルのみbonus skip |
| codex-patterns.md | Codex高確率検出パターン集 |
| known-gotchas.md | macOS symlink canonicalize等の既知問題集 |

### 11.8 付属スキルの差し込み位置整理 (完了)

dev-crew のフロー外で動作するスキル群の位置づけとCodex対応を整理。

| スキル | 現状 | 課題 |
|--------|------|------|
| search-task | 別プラグイン（dev-crew外） | dev-crew スキルではない。Phase 13 のスキルマップからも除外 |
| onboard | プロジェクト初期化 | 11.6 で対応 |
| sync-skills | Codex 用シンボリックリンク生成 | onboard から誘導すべき |
| skill-maker | スキル作成支援 | そのままで問題なし |
| diagnose | バグ調査 | kickoff 参照更新のみ（11.1） |
| learn / evolve | メタ学習 | そのままで問題なし |

### 11.9 ディレクトリ構成の AI-Driven 標準化 (完了)

onboard がプロジェクトに生成するディレクトリ構成を、どこまで dev-crew でコントロールするかの方針決定。

検討事項:
- `docs/cycles/` は必須（TDD サイクル管理）
- `docs/STATUS.md` は必須（状態管理）
- `.claude/rules/` はどこまで？（git-safety, security は標準化する価値あり）
- `.claude/hooks/` はどこまで？（observe, pre-compact は dev-crew 固有）
- AGENTS.md / CLAUDE.md の構成はどこまで規約化するか
- 他ツール（Codex, Copilot）が期待するディレクトリ構成との整合

## Phase 12: ドキュメント体系整備

> 前提: Phase 11.10-11.12（決定論的ゲート + Review品質改善）完了済み。ゲートの存在を前提としてドキュメントを更新する。

### 12.1 既存ドキュメント整理

- README.md 新規作成（docs/ ナビゲーション）（完了）
- STATUS.md 更新（最新サイクル反映）（完了）
- development-plan.md アーカイブ化（完了）
- skills-catalog.md アーカイブ化（完了。Phase 13 スキルマップで後継）

### 12.2 AGENTS.md / CLAUDE.md 更新 (完了)

- AGENTS.md: 決定論的ゲート（pre-red-gate, pre-commit-gate）をTDD Workflowに追記
- CLAUDE.md: REFACTOR主従明記、Usage Patterns整合
- architecture.md: フロー図にゲート追加、ハードコード数値削除

## Phase 13: スキルマップ (完了)

各スキルが開発フローのどこで、誰（Claude/Codex）が使うかを明示する。決定論的ゲートをフロー上の位置に含める。

```
フロー上の位置          スキル/ゲート            主担当        fallback
─────────────────────────────────────────────────────────────────
企画                    strategy                Claude        -
設計                    spec                    Claude        -
  曖昧性検出            (spec内蔵)              Claude        -
  plan review           review --plan           Codex         Claude
  Cycle doc生成         sync-plan               Claude        -
■ pre-red-gate.sh       (決定論的)              script        -
テスト作成              red                     Codex         Claude
  テスト静的解析        exspec                  (tool)        skip
実装                    green                   Codex         Claude
品質改善                refactor                Claude        Codex
レビュー                review                  Claude+Codex  Claude
■ pre-commit-gate.sh    (決定論的)              script        -
コミット                commit                  Claude        -
───────────────────────────────────────────────────────────────
コンテキスト管理        phase-compact, reload   Claude        -
バグ調査                diagnose                Claude        -
並列開発                parallel                Claude        -
プロジェクト初期化      onboard + sync-skills   Claude        -
セキュリティ            security-scan/audit     Claude        -
メタ学習                learn, evolve           Claude        -
言語別品質              *-quality               (auto)        -
スキル作成              skill-maker             Claude        -
```

## 優先順位

| Phase | 優先度 | 理由 |
|-------|--------|------|
| 11.1 | P0 | 全体の前提。kickoff が残ると他の全タスクがドリフトする |
| 11.7 | P1 | refactor の cross-tool 対応。Codex 委譲の前提条件 |
| 11.2 | P1 | PHILOSOPHY.md の核心。日常の開発効率に直結 |
| 11.3 | P1 | 11.2 と密結合。同時実装が効率的 |
| 11.4 | P2 | exspec の成熟度次第。独立して進められる |
| 11.5 | P1 | 11.1 と同時。マイグレーション品質保証 |
| 11.6 | P2 | 11.1, 11.2 完了後に着手 |
| 11.8 | P2 | 方針決定のみ。実装は各スキルの修正時に吸収 |
| 11.9 | P3 | 長期課題。onboard の進化に合わせて段階的に |
| 12 | P2 | 11.1 完了後に開始 |
| 13 | P2 | 11/12 完了後に確定 |

## 順序

```
11.1 sync-plan 移行 + 11.5 マイグレーション検証
  ↓
11.7 refactor 再構築
  ↓
11.2 Codex 委譲 + 11.3 競争的レビュー
  ↓
11.4 exspec 統合
  ↓
11.6 onboard 改善 + 11.8 付属スキル整理
  ↓
12 ドキュメント整備
  ↓
13 スキルマップ確定
  ↓
11.9 ディレクトリ標準化（長期）
```

## 方針

- 各サブタスクは独立した TDD サイクルで実施
- v3: CONSTITUTION.md を最上位規範とし、PHILOSOPHY.md から authority を移行
- v2: PHILOSOPHY.md を正（target philosophy）とし、既存ドキュメントを順次移行（完了）
- security 系エージェント/スキルは現状維持
