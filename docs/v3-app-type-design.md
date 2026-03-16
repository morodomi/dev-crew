# v3 Design: App型プロジェクトへのCONSTITUTION適用

> Phase 2 設計資料。Laravel/Bref App と Next.js SaaS を参考に一般化。
> プロジェクト固有情報は含まない。

## 1. Skills型との本質的な違い

| 観点 | Skills型 (dev-crew) | App型 |
|---|---|---|
| CONSTITUTIONの主語 | 開発方法論 | プロダクト |
| 「何を良いとするか」 | コード品質 | ユーザー価値 + コード品質 |
| 原則の性質 | AI-first, 多角的レビュー等 | ドメインルール, プロダクト約束 |
| 開発フロー | 自身が定義する | dev-crewから継承 |
| 品質基準 | 自身が定義する | dev-crewから継承 + App固有基準 |

**核心**: App型のCONSTITUTIONは「プロダクトの憲法」。開発原則はdev-crewのCONSTITUTIONが担うため、App側には書かない。

## 2. App型 CONSTITUTION.md 構成案

配置: `プロジェクトルート/CONSTITUTION.md`

```
CONSTITUTION.md（~40行）

1. One Sentence
2. Goal / Non-Goals
3. Domain Boundaries
4. Product Principles
5. Human vs AI 責務
6. Source of Truth
7. 変更ポリシー
```

### Skills型との共通章と差分

| 章 | Skills型 | App型 | 差分 |
|---|---|---|---|
| One Sentence | 開発体制の定義 | プロダクトの定義 | 主語が違う |
| Goal / Non-Goals | 開発の最適化目標 | ユーザー価値 | 内容が違う |
| 前提（世界観） | AI時代の開発 | **なし** | App型は不要。dev-crewが担う |
| 原則 | 開発原則6個 | **Product Principles** | 性質が違う |
| Quality Standards | カバレッジ等 | **なし** | dev-crewから継承。App固有基準があればここに追記 |
| Domain Boundaries | なし | **あり** | App型固有。ドメイン制約・文化的配慮 |
| Human vs AI | 開発の責務分離 | プロダクトの責務分離 | 内容が違う |
| Source of Truth | 5-Layer Authority | 同じ構造 | 共通 |
| 変更ポリシー | ADR必須 | 同じ | 共通 |

### 各章の内容ガイド

#### 1. One Sentence

プロダクトが何であるかを一文で。技術スタックは書かない。

例（一般化）:
- 「〇〇を□□で管理するSaaS」
- 「△△と××を融合した◇◇アプリケーション」

#### 2. Goal / Non-Goals

- **Goal**: ユーザーに何を提供するか。「〇〇体験を提供する」「□□の負荷を減らす」
- **Non-Goals**: プロダクトが担わないこと。スコープの明確化

#### 3. Domain Boundaries

プロダクト固有のドメイン制約。AIが最も間違えやすい領域。

含めるべきもの:
- ドメイン特有の計算ロジック・ビジネスルール
- 文化的・法的配慮事項
- データの扱い方（個人情報、センシティブデータ）
- 外部サービスとの契約的制約

#### 4. Product Principles

トレードオフ時の判断基準。開発原則ではなくプロダクト原則。

例:
- 「ユーザー体験 > パフォーマンス最適化」
- 「データ正確性 > 表示速度」
- 「既存ユーザーの互換性 > 新機能」

#### 5. Human vs AI 責務

App型では開発責務に加えて、**運用責務**の分離が重要。

| 担当 | 責務（App型で追加） |
|------|------|
| AI が担う | コード変更、テスト、レビュー、ドキュメント更新 |
| 人間が担う | デプロイ判断、本番データ操作、外部サービス契約、ユーザー対応 |
| AI に禁止 | 本番デプロイコマンド、ビルドコマンド、本番DB操作、課金設定変更 |

「AI に禁止」は App 型固有。Skills 型の「AI に期待しない」とは異なり、**明示的な禁止事項**。

#### 6. Source of Truth

5-Layer Authority 構造は共通。ただし各 Layer の実体が異なる。

| Layer | Name | App型での実体 |
|---|---|---|
| 0 | CONSTITUTION | CONSTITUTION.md（プロダクト原則） |
| 1 | MISSION | AGENTS.md Overview（プロジェクト概要） |
| 2 | PLANNING | ROADMAP.md, spec, cycle doc |
| 3 | DESIGN | docs/（API設計, DB設計, アーキテクチャ） |
| 4 | PROCEDURE & ENFORCEMENT | dev-crewスキル, gates, quality scripts |

**注意**: App型の Layer 4 は dev-crew が提供する。App自身は Layer 0-3 に責任を持つ。

#### 7. 変更ポリシー

Skills型と同じ。CONSTITUTION変更はADR必須。

書かないこと:
- 技術スタックの詳細（docs/architecture.md に置く）
- 環境セットアップ手順（README.md に置く）
- TDDワークフロー（dev-crewが提供）
- コマンドリファレンス（docs/ に置く）

## 3. 既存CLAUDE.mdとの関係

### 問題: CLAUDE.md肥大化パターン

あるLaravel AppのCLAUDE.md（854行）は、以下が1ファイルに混在している:

| 情報の種類 | 行数(概算) | 本来の場所 |
|---|---|---|
| プロダクト定義・原則 | ~50行 | **CONSTITUTION.md** |
| 技術スタック・設計 | ~150行 | docs/architecture.md |
| インフラ・デプロイ | ~100行 | docs/infrastructure.md |
| TDDワークフロー（全体の39%） | ~330行 | **dev-crewが提供（削除可能）** |
| AI指示・品質チェック | ~150行 | CLAUDE.md（残す） |
| トラブルシューティング | ~70行 | docs/ |

**dev-crew onboard済みプロジェクトでは、TDDワークフロー記述の39%が不要になる。**
dev-crewのスキルが同じ内容を提供するため。

### CONSTITUTION導入後のCLAUDE.md

CONSTITUTION.mdを導入した後、CLAUDE.mdに残すべき内容:

- Claude Code固有の設定（Codex統合、hooks）
- プロジェクト固有のAI制約（禁止コマンド等）
- 環境依存の注意事項

CLAUDE.mdは「ツール設定ファイル」に純化する。プロダクト原則はCONSTITUTION、設計はdocs/、手順はdev-crewが担う。

## 4. dev-crew統合済みApp型の良い設計パターン

あるNext.js SaaSのAGENTS.mdから抽出した、App型で参考にすべきパターン:

### CLAUDE.mdコンテンツ判定基準

| 書くべきもの | 書くべきでないもの |
|---|---|
| コードから推測不能なコマンド・規約 | 言語の標準規約（リンターで強制） |
| プロジェクト固有のワークフロー | 一般的なベストプラクティス |
| 環境セットアップの前提条件 | タスク固有の一時的な指示 |

### アンチパターン

| パターン | 問題 |
|---|---|
| 詰め込み (overstuffing) | 指示数~200超で遵守率低下 |
| リンター代替 | フォーマットは静的解析に任せる |
| IMPORTANT/YOU MUST の乱用 | 強調は少数に限定 |

これらはCONSTITUTIONの変更ポリシーに「書かないこと」として反映すべき。

## 5. onboard時のCONSTITUTION生成方針（Phase 7への入力）

onboardスキルがApp型プロジェクトにCONSTITUTION.mdを生成する際の方針:

1. **スキャフォールド**: 7章の骨格を生成し、人間が埋める部分を `[TBD]` で示す
2. **自動検出可能な章**: Source of Truth、変更ポリシーはテンプレートで生成
3. **人間が書くべき章**: One Sentence、Goal/Non-Goals、Domain Boundaries、Product Principles
4. **既存CLAUDE.mdからの抽出**: CLAUDE.mdが肥大化している場合、CONSTITUTION候補の情報を提案

### CLAUDE.md肥大化検出

```
CLAUDE.md行数 > 200行 → 「CONSTITUTION.mdへの分離を推奨」を提案
TDDワークフロー記述あり → 「dev-crewが提供するため削除可能」を提案
```

## 6. 結論

### 共通構造（全プロジェクト型で同じ）

- Source of Truth（5-Layer Authority）
- 変更ポリシー
- Human vs AI 責務（パターンは同じ、内容は異なる）

### App型固有

- Domain Boundaries（Skills型にはない）
- Product Principles（開発原則ではなくプロダクト原則）
- AI禁止事項（デプロイ、本番操作等）
- CLAUDE.md肥大化問題の解消

### Skills型固有（App型には不要）

- 前提（世界観 + 90/10問題）→ dev-crewのCONSTITUTIONが担う
- Quality Standards → dev-crewから継承
- 開発原則6個 → dev-crewのCONSTITUTIONが担う

## 7. Phase 5 への論点: ドキュメントとコードの乖離問題

既存プロジェクトのCLAUDE.mdが現在のソースコードと乖離している可能性がある。CONSTITUTION導入時にこの問題をどう扱うか。

### 情報の性質による正の所在

| 情報の性質 | 正（Source of Truth） | 例 |
|---|---|---|
| 原則・方針 | ドキュメント（CONSTITUTION） | Goal, Non-Goals, Product Principles |
| 現在の状態・機能 | コード（ソースコード + テスト） | 技術スタック、機能一覧、API仕様 |
| コードから推測不能な知識 | ドキュメント（CLAUDE.md） | 環境固有のコマンド、禁止事項、ゴッチャ |

### 選択肢（Phase 5で判断）

| 案 | 内容 | メリット | デメリット |
|---|---|---|---|
| A | onboardでコードスキャン→CLAUDE.md差分検出 | 乖離を自動検出 | 実装コスト高、誤検出リスク |
| B | CONSTITUTION + 「書かないこと」ルールで陳腐化を防ぐ | シンプル、維持コスト低 | 既存の乖離は手動修正が必要 |
| C | CLAUDE.mdを「コードから推測不能なもの」に限定し、残りはコードが正 | dev-crew統合済みApp型で実証済み | 既存プロジェクトの移行コスト |

### 原則

コードから導出可能な情報はドキュメントに書かない。書けば必ず乖離する。

## 8. レビュー履歴

| 入力 | 内容 |
|---|---|
| Laravel App CLAUDE.md (854行) | App型の肥大化パターン分析。TDD記述39%がdev-crewと重複 |
| Next.js SaaS AGENTS.md | CLAUDE.mdコンテンツ判定基準、アンチパターンの抽出 |
| Next.js SaaS CLAUDE.md | dev-crew統合済みApp型の理想的な簡潔さ |
