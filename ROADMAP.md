# Roadmap

> 完了済みの Phase 1-10 は [docs/archive/development-plan.md](docs/archive/development-plan.md) を参照。
> 完了済みの v2/v2.4/v2.5/v3 は [docs/archive/roadmap-v2-v3-completed.md](docs/archive/roadmap-v2-v3-completed.md) を参照。

## 現在地

v2.5.2 リリース済み。全完了済みバージョン:
- v2 (Phase 11-13): Claude + Codex 統合開発フロー
- v2.4 (Phase 14-17): Review Taxonomy 体系化 (33→40 agents)
- v2.5 (Phase 18): Constitution-Driven Enforcement
- v3 (Phase 1-8): Constitution-Driven Development

次: v2.6 (ワークフロー厳格化) + v2.7 (動的スキルコンテンツ)

---

## v2.7: 動的スキルコンテンツ注入

SKILL.md 内に `` !`command` `` を埋め込むことで、スキル起動時にシェルコマンドの出力をプロンプトにインライン注入する。Claude Code がスキル呼び出し時にコマンドを実行し、結果でプレースホルダを置換する。モデルは実行結果のみを見る。

### 効果

- ツールコール削減: 起動時の Read/Bash が不要になり、トークンとレイテンシを削減
- コンテキスト鮮度: スキル起動時点の最新状態が常にプロンプトに含まれる
- 宣言的: 「何を注入するか」を SKILL.md に明示。手続き的な取得ロジックが不要

### 適用候補

| スキル | 注入内容 | 現状 |
|--------|---------|------|
| orchestrate | `git log --oneline -5` | Read で Cycle doc を毎回取得 |
| reload | 最新 Cycle doc の内容 | ls + Read の2ステップ |
| spec | STATUS.md の TODO リスト | Read ツールコール |
| red / green | `.exspec.toml` の有無・内容 | Bash で確認 |
| commit | `git diff --stat` | Bash で取得 |
| review | risk-classifier.sh の出力 | Bash で実行 |

### Phase 24: 設計・PoC

| 項目 | 内容 |
|------|------|
| 構文検証 | `` !`command` `` がClaude Codeでサポートされているか検証 |
| PoC | 1スキル（orchestrate）で試験導入し、トークン削減量を計測 |
| 制約整理 | コマンド実行タイミング、エラー時の挙動、セキュリティ考慮事項 |

### Phase 25: 段階的適用

| 項目 | 内容 |
|------|------|
| 高ROIスキルから適用 | orchestrate → reload → spec → red/green |
| reference.md 更新 | 動的注入の使用ガイドラインを追記 |
| テスト | 注入結果の検証テスト新設 |

---

## v2.6: exspec 深層統合 + ワークフロー厳格化

exspec CLI (v0.3.0) の lint / observe / init を dev-crew ワークフローに深層統合する。現行の RED フェーズ gate（exspec-check.sh）を超え、spec・onboard・review フェーズにも exspec を活用する。

### Phase 21: exspec observe 統合

exspec observe のテスト-コードマッピングを spec/RED フェーズで活用し、テストカバレッジのギャップを可視化する。

| 項目 | 内容 |
|------|------|
| spec 連携 | spec フェーズで `exspec observe` を実行し、未テストの本番コードを特定。Test List 作成の入力にする |
| RED 連携 | RED フェーズ完了時に `exspec observe` で新規テストのマッピング検証 |
| ゲートスクリプト | scripts/gates/exspec-observe-check.sh 新設 |
| テスト | test-exspec-observe-integration.sh 新設 |

### Phase 22: exspec init 統合

exspec init（`.exspec.toml` 自動生成）を onboard スキルに統合する。

| 項目 | 内容 |
|------|------|
| 前提 | exspec 側で `exspec init` コマンドが実装済みであること |
| onboard 連携 | onboard スキルのセットアップフローに `exspec init` を追加 |
| テスト | test-onboard-exspec-init.sh 新設 |

### Phase 23: exspec lint 連携評価・改善

現行の `exspec-check.sh` を評価し、observe データとの組み合わせや severity 調整を検討する。

| 項目 | 内容 |
|------|------|
| 連携評価 | RED gate での exspec lint 実績を収集・分析 |
| severity 調整 | dev-crew コンテキストでの severity 最適化 |
| --strict モード | CI 統合時の `--strict` 適用基準を策定 |

### Phase 19: ディレクトリ構造厳格化

ROADMAP.md, STATUS.md, docs/cycles/ の構造規約をルール化し、検証スクリプトを新設する。

| 項目 | 内容 |
|------|------|
| 構造規約ルール | rules/ にディレクトリ構造ルールを追加 |
| 検証スクリプト | test-directory-structure.sh 新設 |
| onboard 反映 | onboard スキルのテンプレートに構造規約を反映 |

### Phase 20: Socrates コスト最適化

LOW risk PR での Socrates 起動をスキップし、Opus トークンコストを削減する。

| 項目 | 内容 |
|------|------|
| Risk-gated 条件 | risk-classifier.sh の score が LOW (0-29) の場合、Socrates をスキップ |
| 期待効果 | LOW risk PR（全体の ~60%）で Opus コスト削減 |
| テスト | risk level 別の Socrates 起動有無テスト |

---

## 方針

- 各サブタスクは独立した TDD サイクルで実施
- security 系エージェント/スキルは現状維持
