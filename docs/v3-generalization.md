# v3 Design: 一般化設計（Phase 5）

> Phase 1-4 の型別検証と横断分析を基にした最終設計判断。

## 判断結果サマリ

| # | 論点 | 判断 |
|---|---|---|
| 1 | テンプレート設計 | 共通骨格5章 + 型別拡張（ガイド付き自由） |
| 2 | 適用閾値 | 全プロジェクト必須。小規模でも短くてよい |
| 3 | ドキュメントとコードの乖離 | 「コードから導出可能な情報は書かない」を変更ポリシーに含める |
| 4 | Experiment Workflow | プロジェクト固有。dev-crewはTDDのみ提供 |
| 5 | philosophy.md集約 | 全型に適用可能。CONSTITUTION導入時に既存philosophy系を吸収 |
| 6 | 型別追加章の名前 | ガイド付き自由。推奨名を提示するがカスタマイズ可 |

## 1. CONSTITUTIONテンプレート構造

### 共通骨格（全プロジェクト必須、5章）

```markdown
# CONSTITUTION

## One Sentence
[プロジェクトの存在理由を一文で]

## Goal / Non-Goals
- **Goal**: [最適化対象]
- **Non-Goals**: [やらないこと]

## Human vs AI 責務
| 担当 | 責務 |
|------|------|
| AI が担う | [具体的に] |
| 人間が担う | [具体的に] |
| AI に禁止/期待しない | [具体的に] |

## Source of Truth
| Layer | Name | 実体 |
|-------|------|------|
| 0 | CONSTITUTION | このファイル |
| 1 | MISSION | AGENTS.md Overview |
| 2 | PLANNING | ROADMAP.md, spec, cycle doc |
| 3 | DESIGN | docs/* |
| 4 | PROCEDURE & ENFORCEMENT | skills/*, gates/* |

矛盾時: 上位レイヤーが勝つ。
未定義時: 上位レイヤーの原則に照らして判断。

## 変更ポリシー
- CONSTITUTION の変更は ADR 必須
- コードから導出可能な情報は書かない
- 書かないこと: [workflow詳細, モデル固有運用, 一時的workaround]
```

### 型別拡張ガイド

共通骨格の後に、プロジェクトの型に応じて追加章を設ける。
以下は推奨名であり、プロジェクトが自由にカスタマイズ可能。

#### Skills型（開発方法論）

| 推奨章名 | 内容 |
|---|---|
| 前提 | 世界観、Core Problem |
| 原則 | 開発原則（不変のトレードオフ判断基準） |
| Quality Standards | 品質基準（カバレッジ、静的解析等） |

#### App型（プロダクト）

| 推奨章名 | 内容 |
|---|---|
| Domain Boundaries | ドメイン制約、文化的・法的配慮 |
| Product Principles | プロダクトのトレードオフ判断基準 |

#### CLI型（ツール）

| 推奨章名 | 内容 |
|---|---|
| Detection Philosophy | 何を検出し、何を見逃すか |
| Severity / Confidence Policy | 出力レベルとFP許容度 |
| Scope Boundaries | 対応範囲と既知の制限 |

#### Data/ML型（データ・意思決定）

| 推奨章名 | 内容 |
|---|---|
| Data Integrity Principles | データリーク防止、再現性、検証義務 |
| Model Evaluation Philosophy | 評価指標、バックテスト方法論、リリース判断基準 |
| Decision Boundaries | 意思決定への変換ルール、資金管理制約 |

### 混合型

複数の型を兼ねるプロジェクト（例: Data/ML + App）は、複数の型の追加章を組み合わせる。

## 2. onboardでの生成方針

### 型の自動検出

onboardスキルがプロジェクトをスキャンして型を推定:

| 検出シグナル | 型 |
|---|---|
| skills/, agents/ ディレクトリ | Skills |
| src/ + public/ or pages/ or app/ | App |
| CLI entrypoint (main.rs, cli.py, bin/) | CLI |
| models/, data/, notebooks/, experiments/ | Data/ML |
| 上記の組み合わせ | 混合型 |

### 生成フロー

```
onboard
  ├── プロジェクトスキャン
  ├── 型の推定 → AskUserQuestion で確認
  ├── 共通骨格の生成（5章、[TBD] プレースホルダ付き）
  ├── 型別追加章の推奨 → AskUserQuestion で選択
  └── CONSTITUTION.md 生成
       ├── 自動記入可能: Source of Truth, 変更ポリシー
       └── 人間が記入: One Sentence, Goal/Non-Goals, 型別追加章
```

### 既存プロジェクトへの適用

既にonboard済みのプロジェクトにCONSTITUTIONを導入する場合:

1. 既存の philosophy.md, design_philosophy.md 等をスキャン
2. CONSTITUTION候補の情報を抽出・提案
3. CLAUDE.md の肥大化を検出し、分離を提案
4. TDDワークフロー記述の重複を検出し、削除を提案

## 3. AIの壊れ方とCONSTITUTIONの関係

（詳細は v3-failure-modes.md 参照）

| 壊れ方 | CONSTITUTIONでの対処 | 補完する仕組み |
|---|---|---|
| ハルシネーション | Domain/Scope境界の明示 | ドメインドキュメント |
| 確率的スキップ | 原則の明文化 | 決定論的ゲート |
| 構造的盲点 | 検査義務の原則化 | テスト、検証ツール |

**CONSTITUTIONは「何を守るべきか」を定義する。「守らせる」のはゲートとテストの役割。**

## 4. 残存論点（実装フェーズで解決）

| # | 論点 | 解決タイミング |
|---|---|---|
| 1 | CONSTITUTION.mdの行数ガイドライン（~50行推奨だが強制するか） | Phase 6 |
| 2 | 既存プロジェクトのCLAUDE.md分離の自動化度合い | Phase 7 |
| 3 | CONSTITUTION変更のADR運用（docs/decisions/ の整備状況） | Phase 6 |
| 4 | 混合型プロジェクトでの章の優先順位 | Phase 7 |

## 5. Phase 6-8 の実装スコープ確定

### Phase 6: dev-crew authority migration

| サブタスク | 内容 |
|---|---|
| 6.1 | CONSTITUTION.md 新設（共通骨格 + Skills型拡張） |
| 6.2 | PHILOSOPHY.md → CONSTITUTION + workflow.md + architecture.md 分解 |
| 6.3 | document-hierarchy.md 廃止（CONSTITUTION §Source of Truth に吸収） |
| 6.4 | 参照更新（CLAUDE.md, AGENTS.md, skills/*, gates/*, docs/*） |
| 6.5 | ROADMAP.md ルート直下移動 |
| 6.6 | テスト更新 |

### Phase 7: onboard CONSTITUTION対応

| サブタスク | 内容 |
|---|---|
| 7.1 | 型検出ロジック実装 |
| 7.2 | CONSTITUTION.md テンプレート生成 |
| 7.3 | 既存プロジェクト向け migration支援（philosophy.md集約、CLAUDE.md分離提案） |
| 7.4 | テスト |

### Phase 8: リリース (v3.0.0)

| サブタスク | 内容 |
|---|---|
| 8.1 | breaking change ドキュメント |
| 8.2 | バージョンバンプ |
| 8.3 | リリースノート |
