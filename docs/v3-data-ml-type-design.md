# v3 Design: Data/ML型プロジェクトへのCONSTITUTION適用

> Phase 4 設計資料。Python/LightGBM Data/ML プロジェクトを参考に一般化。
> プロジェクト固有情報は含まない。

## 1. 他の型との本質的な違い

| 観点 | Skills型 | App型 | CLI型 | Data/ML型 |
|---|---|---|---|---|
| CONSTITUTIONの主語 | 開発方法論 | プロダクト | ツールの判断哲学 | データと意思決定 |
| 「何を良いとするか」 | コード品質 | ユーザー価値 | 検出精度 | 予測精度 + 利益 |
| 最も壊れやすい部分 | ワークフロー逸脱 | ドメイン制約違反 | FP/FN | データリーク |
| 固有の懸念 | プロセス遵守 | 文化的配慮 | 信頼性 | 再現性・検証可能性 |

**核心**: Data/ML型のCONSTITUTIONは「データと意思決定の憲法」。モデルの判断基準、検証方法、人間の最終判断の境界を定める。

## 2. Data/ML型が持つ固有のリスク

Data/ML型には他の型にはない**致命的リスク**がある:

| リスク | 説明 | CONSTITUTIONでの対処 |
|---|---|---|
| データリーク | 未来情報が学習データに混入 | 検証ルールを原則として明文化 |
| 過学習 | バックテスト最適化が本番で再現しない | 評価基準と閾値を事前固定 |
| 確率の過信 | モデル出力を盲信して過剰投資 | 人間の最終判断を明示 |
| 再現不可能 | seed未固定、環境差異で結果が変わる | 再現性要件を原則に含める |

これらはコード品質の問題ではなく**方法論の問題**。テストで防げない領域があり、CONSTITUTIONレベルで規定する必要がある。

## 3. Data/ML型 CONSTITUTION.md 構成案

配置: `プロジェクトルート/CONSTITUTION.md`

```
CONSTITUTION.md（~50行）

1. One Sentence
2. Goal / Non-Goals
3. Data Integrity Principles
4. Model Evaluation Philosophy
5. Decision Boundaries
6. Human vs AI 責務
7. Source of Truth
8. 変更ポリシー
```

### 他の型との共通章と差分

| 章 | Skills型 | App型 | CLI型 | Data/ML型 |
|---|---|---|---|---|
| One Sentence | 共通 | 共通 | 共通 | 共通 |
| Goal / Non-Goals | 共通 | 共通 | What Is/Is NOT | 共通 |
| 前提 | あり | なし | なし | なし |
| 原則 | 開発原則 | Product | Detection | **Data Integrity** |
| 固有章1 | なし | Domain Boundaries | Severity Policy | **Model Evaluation** |
| 固有章2 | なし | なし | Scope Boundaries | **Decision Boundaries** |
| Quality Standards | あり | 継承 | 継承 | 継承 |
| Human vs AI | 共通 | 共通 | 共通 | 共通（内容が重い） |
| Source of Truth | 共通 | 共通 | 共通 | 共通（実験データ含む） |
| 変更ポリシー | 共通 | 共通 | 共通 | 共通 |

### 各章の内容ガイド

#### 1. One Sentence

システムの最終目的を一文で。手段（ML、データ分析）ではなく目的を書く。

例（一般化）:
- 「〇〇における利益を最大化するシステム」
- 「□□データから△△を予測し、意思決定を支援する」

#### 2. Goal / Non-Goals

- **Goal**: 最終的な最適化対象。「的中率」ではなく「利益」のように、真の目的関数を明示
- **Non-Goals**: 手段を目的化しないための制約。「精度最高のモデルを作ること」は Goal ではない場合がある

**Data/ML型で特に重要**: Goal の定式化がモデル設計を決定する。ここが曖昧だとモデルの方向がブレる。

#### 3. Data Integrity Principles

Data/ML型の最重要章。データの扱い方に関する不変の原則。

含めるべきもの:
- **データリーク防止**: 未来情報の使用禁止、学習/検証/テストの分離
- **再現性**: seed固定、環境固定、データバージョニング
- **検証義務**: 新しい特徴量追加時のリーク検査必須
- **スクレイピング倫理**: robots.txt準拠、レート制限

これらはコードレビューやテストでは完全に防げない。**原則として人間とAIの両方が守るべきルール。**

#### 4. Model Evaluation Philosophy

モデルの「良さ」を何で測るかの哲学。

含めるべきもの:
- 評価指標とその優先順位
- バックテスト方法論（Walk-Forward等）
- 「良すぎる結果」への疑い方（異常値検出の基準）
- リリース判断基準（どの指標がどの閾値を超えたら本番投入可能か）

**CONSTITUTIONに書く理由**: これらの基準はモデル改善のたびに「今回は基準を緩めてもいいか」という誘惑が生じる。原則として固定することで、基準変更にADRを要求する。

#### 5. Decision Boundaries

モデル出力から意思決定への変換ルール。

含めるべきもの:
- 期待値フィルタの閾値（事前固定、バックテスト内最適化禁止）
- 資金管理の制約（最大ベット額、損切りライン）
- 段階的リリース基準

**Data/ML型固有の理由**: モデルの出力は確率的。確率的出力を確定的な意思決定に変換するルールがCONSTITUTIONに必要。

#### 6. Human vs AI 責務

Data/ML型では**AIの判断とAIツールの判断**の区別が重要。

| 担当 | 責務 |
|---|---|
| AI（開発ツール）が担う | コード実装、テスト、レビュー、ドキュメント |
| AI（モデル）が担う | データから確率予測を出力 |
| 人間が担う | 最終的な投資判断、リリース判断、モデル切り替え判断 |
| 禁止 | モデル出力の自動執行（人間の確認なし）、バックテスト基準の事後変更 |

**2種類のAI**: 開発支援AI（Claude/Codex）と予測モデルAI（LightGBM等）を区別する。

#### 7. Source of Truth

5-Layer Authority 構造は共通。Data/ML型での実体:

| Layer | Name | Data/ML型での実体 |
|---|---|---|
| 0 | CONSTITUTION | CONSTITUTION.md（データ・意思決定の原則） |
| 1 | MISSION | AGENTS.md Overview |
| 2 | PLANNING | ROADMAP.md, experiment docs |
| 3 | DESIGN | docs/（design_philosophy, architecture, data_design） |
| 4 | PROCEDURE & ENFORCEMENT | dev-crewスキル, gates, experiment scripts |

**Data/ML型の特殊性**: Layer 2 に **experiment docs**（実験計画書 + 結果）が入る。TDDのcycle docとは別に、実験ワークフローの記録がある。

#### 8. 変更ポリシー

共通。CONSTITUTION変更はADR必須。

書かないこと:
- 個別特徴量の定義（コードで表現）
- ハイパーパラメータの具体値（実験docsに記録）
- データソースの接続情報（環境変数）
- TDDワークフロー（dev-crewが提供）

## 4. Experiment Workflow の位置づけ

Data/ML型には TDD Workflow とは別の **Experiment Workflow** がある:

```
TDD Workflow（dev-crew提供）:
  spec → sync-plan → RED → GREEN → REFACTOR → REVIEW → COMMIT

Experiment Workflow（プロジェクト固有）:
  計画書 → plan-review → 実験コード → code review → 実験実行 → 結果記載
```

| 観点 | TDD Workflow | Experiment Workflow |
|---|---|---|
| 目的 | コードの正しさを保証 | 仮説を検証 |
| 成果物 | テスト + 実装コード | 実験結果 + 知見 |
| 判断基準 | テスト通過 | バックテスト指標 |
| CONSTITUTIONとの関係 | dev-crewが提供 | プロジェクトが定義 |

**CONSTITUTIONは Experiment Workflow の原則を定める（§3, §4）が、手順はdocs/に置く。**

## 5. Phase 5 への論点

| # | 論点 |
|---|---|
| 1 | Experiment Workflow の標準化: dev-crewが提供すべきか、プロジェクト固有か |
| 2 | Data Integrity Principles はdev-crewのルール(.claude/rules/)で強制可能か |
| 3 | Model Evaluation Philosophy の閾値はCONSTITUTION（不変）かdocs/（可変）か |
| 4 | 2種類のAI（開発AI vs 予測AI）の責務分離はCONSTITUTIONテンプレートに含めるべきか |
| 5 | App型のドキュメント乖離問題（Phase 2 §7）はData/ML型でより深刻（実験結果の陳腐化） |

## 6. 4型の比較サマリ

### 共通骨格（全型で必須）

1. One Sentence
2. Goal / Non-Goals
3. Human vs AI 責務
4. Source of Truth（5-Layer Authority）
5. 変更ポリシー

### 型別追加章

| 型 | 追加章 | 核心 |
|---|---|---|
| Skills | 前提, 開発原則, Quality Standards | 開発方法論 |
| App | Domain Boundaries, Product Principles | プロダクト価値 |
| CLI | Detection Philosophy, Severity Policy, Scope Boundaries | ツールの判断 |
| Data/ML | Data Integrity, Model Evaluation, Decision Boundaries | データと意思決定 |

### CONSTITUTIONが防ぐもの（型別）

| 型 | 防ぐもの |
|---|---|
| Skills | ワークフロー逸脱、目的のブレ |
| App | ドメイン制約違反、CLAUDE.md肥大化 |
| CLI | FP増加による信頼崩壊、スコープクリープ |
| Data/ML | データリーク、過学習、確率の過信 |

## 7. レビュー履歴

| 入力 | 内容 |
|---|---|
| Data/ML App AGENTS.md (70行) | dev-crew完全統合済みData/ML型の構造分析 |
| Data/ML App CLAUDE.md | AGENTS.md参照形式 |
| Data/ML App design_philosophy.md (196行) | CONSTITUTION候補: 最適化原則、二段階学習、データリーク防止、評価基準 |
| Data/ML App Experiment Workflow | TDDとは別の実験ワークフローの存在を確認 |
