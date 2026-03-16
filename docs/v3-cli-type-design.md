# v3 Design: CLI型プロジェクトへのCONSTITUTION適用

> Phase 3 設計資料。exspec (Rust CLI) を参考に一般化。
> プロジェクト固有情報は含まない。

## 1. Skills型・App型との本質的な違い

| 観点 | Skills型 (dev-crew) | App型 | CLI型 |
|---|---|---|---|
| CONSTITUTIONの主語 | 開発方法論 | プロダクト | ツールの判断哲学 |
| 「何を良いとするか」 | コード品質 | ユーザー価値 | 検出精度・信頼性 |
| 原則の性質 | AI-first等 | ドメインルール | FP/FN方針、検出範囲 |
| 開発フロー | 自身が定義する | dev-crewから継承 | dev-crewから継承 |
| 固有の懸念 | ワークフロー遵守 | ドメイン制約 | 精度と信頼性 |

**核心**: CLI型のCONSTITUTIONは「ツールの判断哲学」。何を検出し、何を検出せず、どのレベルの確信で報告するか。

## 2. CLI型の特徴: 既にCONSTITUTION相当が分散している

exspecの調査で判明した重要な事実:

| CONSTITUTION候補の情報 | 現在の場所 | 問題 |
|---|---|---|
| What it Is / Is NOT | docs/philosophy.md | 正しい場所だが、CONSTITUTIONとして認識されていない |
| Design Principles (4個) | ROADMAP.md 冒頭 | ロードマップと原則が混在 |
| Source of Truth | CLAUDE.md | ツール設定ファイルに原則が混在 |
| Severity Philosophy | docs/philosophy.md | philosophy.mdに含まれている |
| Known Limitations | docs/philosophy.md | 同上 |

**CLI型は既に原則を持っているが、分散している。** CONSTITUTION化は「新規作成」ではなく「集約」。

## 3. CLI型 CONSTITUTION.md 構成案

配置: `プロジェクトルート/CONSTITUTION.md`

```
CONSTITUTION.md（~50行）

1. One Sentence
2. Goal / Non-Goals（What it Is / Is NOT）
3. Detection Philosophy
4. Severity / Confidence Policy
5. Scope Boundaries
6. Human vs AI 責務
7. Source of Truth
8. 変更ポリシー
```

### Skills型・App型との共通章と差分

| 章 | Skills型 | App型 | CLI型 |
|---|---|---|---|
| One Sentence | 開発体制の定義 | プロダクトの定義 | ツールの定義 |
| Goal / Non-Goals | 開発の最適化 | ユーザー価値 | **What it Is / Is NOT** |
| 前提 | 世界観 + 90/10 | なし | なし |
| 原則 | 開発原則6個 | Product Principles | **Detection Philosophy** |
| Severity Policy | なし | なし | **あり（CLI型固有）** |
| Domain Boundaries | なし | あり | **Scope Boundaries** |
| Quality Standards | カバレッジ等 | dev-crewから継承 | dev-crewから継承 |
| Human vs AI | 開発の責務分離 | プロダクトの責務分離 | ツールの責務分離 |
| Source of Truth | 5-Layer Authority | 同じ | 同じ |
| 変更ポリシー | ADR必須 | 同じ | 同じ |

### 各章の内容ガイド

#### 1. One Sentence

ツールが何であるかを一文で。

例（一般化）:
- 「〇〇を静的解析で検出するリンター」
- 「□□を自動化するCLI」

#### 2. Goal / Non-Goals（What it Is / Is NOT）

CLI型では Goal/Non-Goals を **What it Is / Is NOT** として表現するのが自然。
ツールの境界を明確にする。

- **Is**: 何をするツールか
- **Is NOT**: 何をしないか、何と混同されるか

これはGPT案の「Non-Goals」に対応するが、CLI型では「Not a coverage tool」「Not an AI reviewer」のように**混同されうるものを明示的に否定する**パターンが重要。

#### 3. Detection Philosophy

CLI型固有の原則。「何を検出し、何を見逃すか」のトレードオフ判断。

含めるべきもの:
- 検出の根拠（静的? 動的? ヒューリスティック?）
- 精度の方針（false positive vs false negative のどちらを重視するか）
- 検出できないものの明示（semantic vs structural）
- 将来的な拡張の方向性

#### 4. Severity / Confidence Policy

CLI出力の信頼性を定義する。ユーザーの信頼獲得に直結。

例（一般化）:
| Level | Meaning | FP許容度 |
|---|---|---|
| BLOCK/ERROR | ほぼ確実に問題 | ゼロに近い |
| WARN | 問題の可能性が高い | 低い |
| INFO | 検討の価値あり | ある程度許容 |

**核心**: 最も厳しいレベルでFPを出すとツールの信頼が崩壊する。

#### 5. Scope Boundaries

検出対象と非対象の明確な境界。

含めるべきもの:
- 対応言語/フレームワーク
- 既知の制限事項（技術的に検出不可能なもの）
- ツールが判断を委ねるもの（human/AI review に委譲）

#### 6. Human vs AI 責務

CLI型では「ツール vs 人間/AI」の責務分離。

| 担当 | 責務 |
|---|---|
| ツールが担う | 構造的な検出、高速・低コスト実行、機械的判定 |
| 人間/AIが担う | 意味的判断、FP判定、ルール設定のカスタマイズ |
| ツールが担わない | 意味的妥当性の判断、コード修正の提案 |

#### 7. Source of Truth

5-Layer Authority 構造は共通。CLI型での実体:

| Layer | Name | CLI型での実体 |
|---|---|---|
| 0 | CONSTITUTION | CONSTITUTION.md（判断哲学） |
| 1 | MISSION | AGENTS.md Overview |
| 2 | PLANNING | ROADMAP.md |
| 3 | DESIGN | docs/（SPEC.md, configuration.md, languages/） |
| 4 | PROCEDURE & ENFORCEMENT | dev-crewスキル, gates |

CLI型では Layer 3 に **SPEC.md**（ルール仕様 = 入力→期待出力）が入る。
これはApp型にはない、CLI型固有の重要ドキュメント。

#### 8. 変更ポリシー

共通。CONSTITUTION変更はADR必須。

書かないこと:
- 個別ルールの詳細仕様（SPEC.md に置く）
- 設定オプションの説明（docs/configuration.md に置く）
- 言語固有の挙動（docs/languages/ に置く）
- TDDワークフロー（dev-crewが提供）

## 4. 既存ドキュメントからの集約マッピング

CLI型プロジェクトでCONSTITUTION.mdを導入する際、既存ドキュメントからの集約パターン:

| 既存の場所 | 内容 | CONSTITUTION.mdへ |
|---|---|---|
| docs/philosophy.md | What Is / Is NOT, Detection Philosophy, Severity | §1, §2, §3, §4 に昇格 |
| ROADMAP.md 冒頭 | Design Principles | §3 に統合 |
| CLAUDE.md | Source of Truth定義 | §7 に昇格 |
| docs/philosophy.md | Known Limitations | §5 に統合 |

**集約後の処理**:
- docs/philosophy.md → 廃止（CONSTITUTIONに吸収）
- ROADMAP.md → Design Principles セクション削除（CONSTITUTIONに移動）
- CLAUDE.md → Source of Truth定義削除（CONSTITUTIONに移動）

## 5. 小規模CLIへの適用可能性

小規模CLI（30-35ファイル）へのCONSTITUTION適用:

| 観点 | 判断 |
|---|---|
| CONSTITUTION.md必要か | 規模に対して過剰。CLAUDE.mdに原則を記述すれば十分 |
| 5-Layer Authority必要か | Layer 0-1 で十分。Layer 2-4 は不要 |
| Detection Philosophy必要か | 検出ツールでないCLIには不要 |

**結論**: 小規模CLIにはCONSTITUTION.mdの強制は不適切。閾値を設ける必要がある（Phase 5で判断）。

## 6. Phase 5 への論点

| # | 論点 |
|---|---|
| 1 | CONSTITUTION.md の適用閾値（プロジェクト規模・複雑度の基準） |
| 2 | 小規模プロジェクトでの簡易版CONSTITUTION（CLAUDE.md内に原則セクションを設ける案） |
| 3 | CLI型の Detection Philosophy / Severity Policy は他の型にも応用可能か |
| 4 | philosophy.md → CONSTITUTION.md の集約はCLI型固有か、全型に適用可能か |

## 7. 3型の比較サマリ

| 章 | Skills型 | App型 | CLI型 |
|---|---|---|---|
| One Sentence | 共通 | 共通 | 共通 |
| Goal / Non-Goals | 共通 | 共通 | **What Is / Is NOT** |
| 前提 | あり | なし | なし |
| 原則 | 開発原則 | Product Principles | **Detection Philosophy** |
| Severity Policy | なし | なし | **あり** |
| Domain / Scope | なし | Domain Boundaries | **Scope Boundaries** |
| Quality Standards | あり | 継承 | 継承 |
| Human vs AI | 共通パターン | 共通パターン | **ツール vs 人間/AI** |
| Source of Truth | 共通 | 共通 | 共通 (+ SPEC.md) |
| 変更ポリシー | 共通 | 共通 | 共通 |

### 共通骨格（全型で必須）

1. One Sentence
2. Goal / Non-Goals
3. Human vs AI 責務
4. Source of Truth（5-Layer Authority）
5. 変更ポリシー

### 型別追加章

- **Skills型**: 前提（世界観）、開発原則、Quality Standards
- **App型**: Domain Boundaries、Product Principles
- **CLI型**: Detection Philosophy、Severity Policy、Scope Boundaries

## 8. レビュー履歴

| 入力 | 内容 |
|---|---|
| exspec CLAUDE.md (94行) | Source of Truth定義、ドキュメント配置ルール抽出 |
| exspec AGENTS.md (164行) | dev-crew統合済みCLI型の構造分析 |
| exspec docs/philosophy.md (65行) | CONSTITUTION候補の情報が集中。4 Properties、Severity Philosophy |
| exspec ROADMAP.md (80行冒頭) | Design Principles 4個の抽出 |
| 小規模CLI (30-35ファイル) | 小規模CLIへの適用可能性の検証 |
