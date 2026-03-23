# Archived Roadmap: v2 / v2.4 / v2.5 / v2.6 / v2.7 / v3

> このファイルは ROADMAP.md から完了済みセクションをアーカイブしたもの。
> Phase 1-10 は [development-plan.md](development-plan.md) を参照。

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
| tests/ | 6ファイル rename + 内容更新 |

### 11.2 Codex 委譲インターフェース (完了)

orchestrate スキルに Codex 委譲パスを追加。各実行フェーズのスキルにもCodex委譲情報を反映。

### 11.3 競争的レビュー (完了)

- review スキルに Codex レビュー統合
- Claude review + Codex review の findings 集約フロー

### 11.4 exspec 統合 (完了)

- RED 最終ステップに exspec 実行を追加

### 11.5 マイグレーション検証 (完了)

- 11.1 実施時に既存テスト・参照を全て更新済み。live docs の kickoff 参照 0 件を確認。

### 11.6 onboard スキル改善 (完了)

AGENTS.md / CLAUDE.md テンプレート改善、Codex 環境セットアップ誘導。

### 11.7 refactor スキル再構築 (完了)

`/simplify` 依存を解消し、独自の品質改善ロジックをスキル内に持つ。

### 11.8 付属スキルの差し込み位置整理 (完了)

### 11.9 ディレクトリ構成の AI-Driven 標準化 (完了)

### 11.10 決定論的ゲート基盤 (v2.1.0, 完了)

| 項目 | 内容 |
|------|------|
| pre-red-gate.sh | RED開始前にCycle doc存在・sync-plan完了・Plan Review記録を検証 |
| pre-commit-gate.sh | COMMIT前にCode Review記録・Codex competitive review記録・STATUS.md同期を検証 |

### 11.11 Review品質改善 (v2.1.0, 完了)

### 11.12 テスト設計品質 + ツール改善 (v2.1.0, 完了)

## Phase 12: ドキュメント体系整備 (完了)

## Phase 13: スキルマップ (完了)

---

## v2.4: Review Taxonomy 体系化 (全Phase完了)

セキュリティレビューが OWASP Top 10 / CWE Top 25 に基づく 19 attacker agent で体系化されているのに対し、Plan Review / Test Review / Code Review は汎用的な観点のみだった。権威ある参照元に基づき、専門 reviewer agent を体系的に追加する。

設計原則:
- **CLI（決定論）と Agent（意味論）の責務分離**
- **Risk-gated scaling**: リスク検出時のみ専門 agent を追加起動
- **既存 review スキルに統合**: スキル数は増やさない
- **段階的追加**: 1体ずつ追加→テスト→次へ

### Phase 14: Code Review 強化 (完了)

- 14.1 maintainability-reviewer 新設 (Always-on, Sonnet)
- 14.2 api-contract-reviewer 新設 (Risk-gated, Sonnet)
- 14.3 observability-reviewer 新設 (Risk-gated, Sonnet)
- 14.4 performance-reviewer 強化 (並行性観点追加)

### Phase 15: Test Review 強化 (完了)

- 15.1 test-reviewer 新設 (Code mode, Risk-gated, Sonnet)
- 15.2 test-reviewer Plan mode 設計
- 15.3 Socrates Devil's Advocate review pipeline 統合

### Phase 16: Plan Review 強化 (完了)

- 16.1 change-safety-reviewer 新設 (Risk-gated, Sonnet)
- 16.2 impact-reviewer 新設 (Risk-gated, Sonnet)
- 16.3 resiliency-reviewer 新設 (Risk-gated, Sonnet)
- 16.4 design-reviewer 強化 (過剰設計検出追加)
- 16.5 test-reviewer Plan mode 統合
- 16.6 risk-classifier.sh 拡張

### Phase 17: 統合・リリース (v2.4.0, 完了)

最終: 33 agents → 40 agents / 29 skills → 29 skills

### 参照元一覧

| 参照元 | 対象 agent | URL |
|--------|-----------|-----|
| Fowler Code Smells | maintainability | https://refactoring.guru/refactoring/smells |
| Google Engineering Practices | maintainability | https://google.github.io/eng-practices/review/ |
| Google API Design Guide | api-contract | https://cloud.google.com/apis/design |
| Microsoft REST API Guidelines | api-contract | https://github.com/microsoft/api-guidelines |
| Google SRE Book | observability, resiliency | https://sre.google/sre-book/monitoring-distributed-systems/ |
| OpenTelemetry Semantic Conventions | observability | https://opentelemetry.io/docs/specs/semconv/ |
| SEI CERT Coding Standards | performance | https://wiki.sei.cmu.edu/confluence/display/seccode |
| xUnit Test Patterns | test-reviewer | http://xunitpatterns.com/ |
| Google SWE Book Ch11-12 | test-reviewer | https://abseil.io/resources/swe-book/html/ch11.html |
| Fowler Evolutionary DB Design | change-safety | https://martinfowler.com/articles/evodb.html |
| C4 Model | impact | https://c4model.com/ |
| AWS Well-Architected Reliability | resiliency | https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/ |

---

## v2.5: Constitution-Driven Enforcement (全Phase完了)

CONSTITUTION 原則6（決定論的プロセス保証）の実現。

### Phase 18: Post-Approve Action 強制 (完了)

Post-Approve Action を hook（plan-exit-flag.sh + post-approve-gate.sh）で決定論的に強制。

### Phase 18.1: Constitution 整合性チェック (完了)

spec/plan-review に CONSTITUTION.md との整合性チェックを追加。

### Phase 18.2: Socrates Plan Adversarial Review (完了)

Codex 不在時に Socrates を plan adversarial reviewer として起動。

---

## v3: Constitution-Driven Development (全Phase完了)

CONSTITUTION.md を最上位規範（Layer 0）として導入し、PHILOSOPHY.md を分解・再構成。

### Phase 1-5: 設計 (完了)

CONSTITUTION.md 構成設計、App/CLI/Data・ML型適用検討、一般化判断。

### Phase 6: dev-crew authority migration (完了)

CONSTITUTION.md 新設、PHILOSOPHY.md 分解、参照移行。

### Phase 7: onboard CONSTITUTION 対応 (完了)

onboard スキルに CONSTITUTION.md 生成を追加。

### Phase 8: リリース (v2.3.0 → v2.5.2, 完了)

Constitution 機能は v2.3.0 でリリース。以降 v2.5.2 まで段階的に強化。

---

## v2.6: exspec 深層統合 + ワークフロー厳格化 (凍結)

exspec CLI (v0.3.0) の lint / observe / init を dev-crew ワークフローに深層統合する計画。exspec CLI 側の実装が進まず、2026-03-23 時点で凍結。

### Phase 19: ディレクトリ構造厳格化 (未着手)
### Phase 20: Socrates コスト最適化 (未着手)
### Phase 21: exspec observe 統合 (未着手、exspec 依存)
### Phase 22: exspec init 統合 (未着手、exspec 依存)
### Phase 23: exspec lint 連携評価・改善 (未着手、exspec 依存)

---

## v2.7: 動的スキルコンテンツ注入 (全Phase完了)

SKILL.md 内に `` !`command` `` を埋め込むことで、スキル起動時にシェルコマンドの出力をプロンプトにインライン注入する。

### Phase 24: 設計・PoC (完了)

`` !`command` `` 構文の動作検証。orchestrate で試験導入し、トークン削減を確認。ADR記録済み。

### Phase 25: 段階的適用 (完了)

orchestrate → reload → spec → red/green に適用。

### v2.8 Phase 26: --no-verify hook (完了)

PreToolUse Bash hook で `--no-verify` を含むコマンドを決定論的にブロック。no-verify-guard.sh 新設、onboard テンプレートにも追加。

### v2.6 Phase 27: Gotchas セクション体系化 (完了)

高頻度6スキル(orchestrate/spec/red/green/review/commit)の reference.md に ## Gotchas テーブル追加(各5項目)。test-gotchas-structure.sh 新設(8テスト)。docs/known-gotchas.md に evolve 連携規約追加。Codex plan review + 3 reviewer findings 反映。

### v2.6 Phase 28: On-demand hooks PoC (完了)

SKILL.md frontmatter hooks の公式サポートを確認。/careful スキル新設(破壊コマンド5パターン検出)。careful-guard.sh + test-careful-hook.sh(13テスト)。Socrates/Codex review 反映。

### v2.6 Phase 29: CLAUDE_PLUGIN_DATA 移行 (完了)

19ファイル、38+参照を `${CLAUDE_PLUGIN_DATA:-${HOME}/.claude/dev-crew}` に移行。dual-read で後方互換。test-plugin-data-paths.sh 新設(6テスト)。
