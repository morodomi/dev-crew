# Roadmap

> 完了済みの Phase 1-10 は [docs/archive/development-plan.md](docs/archive/development-plan.md) を参照。
> 完了済みの v2/v2.4/v2.5/v3 は [docs/archive/roadmap-v2-v3-completed.md](docs/archive/roadmap-v2-v3-completed.md) を参照。

## 現在地

v2.5.2 リリース済み。全完了済みバージョン:
- v2 (Phase 11-13): Claude + Codex 統合開発フロー
- v2.4 (Phase 14-17): Review Taxonomy 体系化 (33→40 agents)
- v2.5 (Phase 18): Constitution-Driven Enforcement
- v3 (Phase 1-8): Constitution-Driven Development

次: v2.6 (ワークフロー厳格化) + v2.7 (動的スキルコンテンツ) + v2.8 (スキル品質強化)

v2.6 は exspec CLI 側の実装待ちの部分があるため、v2.7/v2.8 と並行して進行可能なものから着手する。

---

## v2.8: スキル品質強化

Anthropic Skills Best Practices に基づくスキル品質の体系的強化。決定論的ガードレール、失敗パターンの蓄積、スキルデータの安定化を行う。

### Phase 26: --no-verify hook（決定論的ブロック）

`--no-verify` は rules/git-safety.md で禁止しているが、ルール違反はLLM依存。post-approve-gate.sh と同様に hook で決定論的にブロックする。ルールの「禁止記述」を「決定論的強制」に昇格させるもの（重複ではなくレイヤーの追加）。

| 項目 | 内容 |
|------|------|
| hook | PreToolUse Bash で `--no-verify` を含むコマンドをブロック（exit 2） |
| スクリプト | scripts/hooks/no-verify-guard.sh 新設 |
| 対象 | `git commit --no-verify`, `git push --no-verify` 等 |
| hooks.json | PreToolUse Bash マッチャーとして登録 |
| onboard | onboard テンプレートにも推奨 hook として追加 |
| テスト | test-no-verify-guard.sh 新設 |

### Phase 27: Gotchas セクション体系化

各スキルに Gotchas セクション（よくある失敗パターン）を追加。learn/evolve パイプラインの出力先としても機能させる。既存の docs/known-gotchas.md はクロスカッティングな問題（macOS 差異等）を扱い、スキル別 Gotchas はスキル固有の失敗パターンに特化する（二重管理ではなくスコープの分離）。

| 項目 | 内容 |
|------|------|
| 対象 | 高頻度スキル: orchestrate, spec, red, green, review, commit |
| ソース | instincts/ の蓄積、過去のセッション失敗パターン |
| 配置 | 各スキルの reference.md 末尾に `## Gotchas` セクション |
| known-gotchas.md | クロスカッティング問題はここに残す。スキル固有パターンは各スキルに移行 |
| evolve 連携 | evolve スキルが新 instinct を該当スキルの Gotchas に追記する機能 |
| テスト | test-gotchas-structure.sh（Gotchas セクション存在確認） |

### Phase 28: On-demand hooks（フィージビリティスパイク）

スキル呼び出し時にのみ有効になる hooks を活用。常時有効にすると邪魔だが、特定コンテキストでは必須なガードレールを提供する。

**リスク**: SKILL.md frontmatter での hooks 登録は Claude Code の公式機能だが、dev-crew での実績がない。v2.7 Phase 24 の PoC と同様に、まず構文検証から入る。Phase 24 の結果を待ってから着手するのが安全。

| 項目 | 内容 |
|------|------|
| 前提 | v2.7 Phase 24 で Claude Code の動的機能の信頼性が確認済みであること |
| 設計 | SKILL.md frontmatter に hooks 定義を追加する構文を検証 |
| ユースケース | `/careful`: prod 作業時に破壊コマンドブロック、`/freeze`: 特定ディレクトリ以外の編集ブロック |
| PoC | 1スキル（careful）で試験導入 |
| テスト | on-demand hook の有効化・無効化テスト |

### Phase 29: CLAUDE_PLUGIN_DATA 移行

スキルデータの保存先を `~/.claude/dev-crew/` から公式の `${CLAUDE_PLUGIN_DATA}` に移行。プラグインアップグレード時のデータ消失を防止する。

**影響範囲**: `~/.claude/dev-crew/` は以下の6+ファイルにハードコードされており、全箇所の書き換えが必要:
- skills/learn/SKILL.md（2箇所）
- skills/evolve/SKILL.md
- skills/commit/reference.md
- scripts/hooks/observe.sh
- tests/test-instinct-paths.sh
- その他 reference.md 内の参照

| 項目 | 内容 |
|------|------|
| 対象 | instincts/, observations/, source-path |
| 移行戦略 | dual-read: 新パス優先 → 旧パス fallback → 初回実行時に自動コピー |
| 参照スイープ | grep で `~/.claude/dev-crew` の全参照を洗い出し、完了条件とする |
| テスト | データパス解決テスト + 旧パスからの移行テスト |

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
| 前提 | Phase 24 の PoC で動作確認済みであること |
| 高ROIスキルから適用 | orchestrate → reload → spec → red/green |
| reference.md 更新 | 動的注入の使用ガイドラインを追記 |
| テスト | 注入結果の検証テスト新設 |

---

## v2.6: exspec 深層統合 + ワークフロー厳格化

exspec CLI (v0.3.0) の lint / observe / init を dev-crew ワークフローに深層統合する。現行の RED フェーズ gate（exspec-check.sh）を超え、spec・onboard・review フェーズにも exspec を活用する。

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

---

## 方針

- 各サブタスクは独立した TDD サイクルで実施
- security 系エージェント/スキルは現状維持
