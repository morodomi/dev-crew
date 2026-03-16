# v3 Design: Constitution-Driven Development

> Phase 1 設計資料。Issue #75 の Acceptance Criteria。
> 実装は Phase 6 で行う。本資料は Phase 2-4 の適用検証の入力としても使用する。

## 1. CONSTITUTION.md 理想形

配置: `dev-crew/CONSTITUTION.md`（ルート直下）

### 構成

```
CONSTITUTION.md（~50行）

1. One Sentence
2. Goal / Non-Goals
3. 前提（世界観 + Core Problem）
4. 原則（6個）
5. Quality Standards
6. Human vs AI 責務
7. Source of Truth（5-Layer Authority）
8. 変更ポリシー
```

### 各章の内容

#### 1. One Sentence

人間が楽をするための開発体制。

#### 2. Goal / Non-Goals

- **Goal**: 人間の判断負荷を減らしつつ、壊れにくい変更を高速に出す
- **Non-Goals**: 人間排除、完全自動化、最小トークン消費、レビュー省略

#### 3. 前提

AIがコードを生成する時代、人間は「やりたいこと」と「OK/NG」だけ出す。
AIは確率的に90%正しい出力をするが、コードもワークフローも90%では足りない。
残り10%を埋めるのがテスト・レビュー・静的解析・決定論的ゲートであり、dev-crewが存在する理由。

#### 4. 原則

1. **AI-first**: 設計・実装・テスト・レビュー・コミットの全工程をAIが実行。人間はゴールを伝え、判断ポイントでOK/NGを出すだけ
2. **多角的レビュー**: 同じコードを異なるAI、異なるレビュアーが見る。品質は「どの視点で、どれだけレビューしたか」で決まる
3. **性格差の活用**: Claude=計画・調整型（PdM/Orchestrator）、Codex=辛口ベテラン型（Implementer+Reviewer）。作る側/壊す側の意図的分離ではなく、性格差を武器にした品質担保
4. **Fallback**: 単一モデルでもフローが回る設計。Codex利用可能時に優先委譲、不在時はClaude fallback
5. **速度とのトレードオフ**: 完璧を求めて速度を犠牲にしない。AIなら3-5分で終わるレビューを複数回・複数視点で回す
6. **決定論的プロセス保証**: プロセス強制は決定論的コード（ゲートスクリプト）、品質検出はLLM（レビューエージェント）。LLMに「手順を守れ」と指示するのではなく、ゲートが exit 1 でBLOCKする

#### 5. Quality Standards

| Metric | Target |
|--------|--------|
| Test coverage | 90%+ (min 80%) |
| Static analysis | 0 errors |
| Test design | Given/When/Then |

#### 6. Human vs AI 責務

| 担当 | 責務 |
|------|------|
| AI が担う | 設計案生成、実装、テスト作成、レビュー、指摘抽出、コミット |
| 人間が担う | 優先順位決定、曖昧仕様の確定、最終承認、トレードオフ裁定 |
| AI に期待しない | 手順の自然遵守、事実の無検証保証、ビジネス責任の代行 |

#### 7. Source of Truth（5-Layer Authority）

| Layer | Name | 内容 | 例 |
|-------|------|------|-----|
| 0 | CONSTITUTION | 原則・判断基準 | CONSTITUTION.md |
| 1 | MISSION | プロジェクトの存在理由 | AGENTS.md Overview |
| 2 | PLANNING | 何を実現するか | ROADMAP.md, spec, cycle doc |
| 3 | DESIGN | どう実現するか | docs/*, decisions/ |
| 4 | PROCEDURE & ENFORCEMENT | 具体的手順と強制機構 | skills/reference.md, gates/*.sh |

- **矛盾時**: 上位レイヤーが勝つ
- **未定義時**: 上位レイヤーの原則に照らして判断
- **下位文書の責務**: 上位レイヤーと矛盾しないこと。矛盾を発見したら上位に合わせて修正

#### 8. 変更ポリシー

- CONSTITUTION の変更は ADR 必須（docs/decisions/ に記録）
- **書かないこと**: workflow 詳細、モデル固有の運用、一時的 workaround、具体スクリプトの細部
- これらは workflow.md, architecture.md, STATUS.md に置く

---

## 2. PHILOSOPHY.md 分解マッピング

| 現 PHILOSOPHY.md セクション | 行 | 行き先 |
|---|---|---|
| 一言 | 5-7 | CONSTITUTION.md §1 |
| 前提 | 9-11 | CONSTITUTION.md §3 |
| 90/10 問題 | 13-19 | CONSTITUTION.md §3（統合） |
| 原則 1. AI-first | 22-24 | CONSTITUTION.md §4 |
| 原則 2. 多角的レビュー | 26-28 | CONSTITUTION.md §4 |
| 原則 3. 性格差の活用 | 30-37 | CONSTITUTION.md §4 |
| 原則 4. Fallback | 39-41 | CONSTITUTION.md §4 |
| 原則 5. 速度とのトレードオフ | 43-45 | CONSTITUTION.md §4 |
| 原則 6. 決定論的プロセス保証 | 47-57 | CONSTITUTION.md §4 |
| 開発フロー図 | 60-105 | docs/workflow.md |
| 承認と確認 | 107-114 | docs/workflow.md |
| 決定論的ゲート | 116-123 | docs/workflow.md |
| Findings 判断 | 125-136 | docs/workflow.md |
| sync-plan | 138-139 | docs/workflow.md |
| Phase-Boundary Compaction | 141-149 | docs/architecture.md（既存） |
| Cycle Doc as State Handoff | 151-162 | docs/architecture.md（既存） |
| 決定論的ゲートによるプロセス保証 | 164-171 | docs/workflow.md |
| なぜこの体制か | 173-175 | CONSTITUTION.md §3 に統合 |

---

## 3. 新設・廃止・統合

### 新設

| ファイル | 内容 | Layer |
|---|---|---|
| CONSTITUTION.md | 最上位規範（~50行） | 0 |
| ROADMAP.md（ルート直下に移動） | 何を実現するか | 2 |
| docs/workflow.md | 開発フロー、承認、ゲート、Findings判断 | 3 |

### 廃止

| ファイル | 理由 | 吸収先 |
|---|---|---|
| docs/PHILOSOPHY.md | CONSTITUTION + workflow + architecture に分解 | 上記3ファイル |
| docs/document-hierarchy.md | Source of Truth 階層を CONSTITUTION §7 に吸収 | CONSTITUTION.md |

### 統合

| 情報 | 現在地 | 移動先 |
|---|---|---|
| ファイル配置マップ | document-hierarchy.md | docs/skill-map.md（末尾に追加） |
| Quality Standards | AGENTS.md | CONSTITUTION.md §5（昇格）。AGENTS.md からは参照のみ |

---

## 4. 影響ファイル一覧

Phase 6 実装時に変更が必要なファイルの完全リスト。

### 参照更新（PHILOSOPHY.md → CONSTITUTION.md）

| ファイル | 現在の参照 | 変更内容 |
|---|---|---|
| CLAUDE.md | `[docs/PHILOSOPHY.md]` | `CONSTITUTION.md` に更新 |
| AGENTS.md | `[docs/PHILOSOPHY.md]` + migration 注記 | `CONSTITUTION.md` に更新、注記削除 |
| skills/onboard/reference.md | PHILOSOPHY.md 参照 | CONSTITUTION.md に更新 |
| skills/orchestrate/steps-codex.md | PHILOSOPHY.md 準拠 | CONSTITUTION.md に更新 |
| docs/README.md | ナビゲーション | CONSTITUTION.md 追加、PHILOSOPHY.md 削除 |
| docs/skill-map.md | Authority: PHILOSOPHY.md | Authority: CONSTITUTION.md + workflow.md |
| scripts/gates/pre-red-gate.sh | コメント内 PHILOSOPHY.md 参照 | CONSTITUTION.md に更新 |
| scripts/gates/pre-commit-gate.sh | コメント内 PHILOSOPHY.md 参照 | CONSTITUTION.md に更新 |

### 構造変更

| ファイル | 変更内容 |
|---|---|
| docs/ROADMAP.md | ルート直下に移動。方針記述を CONSTITUTION ドリブンに更新 |
| docs/architecture.md | PHILOSOPHY.md の実装設計セクション統合。フロー図は workflow.md に移管 |
| docs/skill-map.md | ファイル配置マップ（document-hierarchy.md から）追加 |

---

## 5. ディレクトリ構成（理想形）

```
dev-crew/
├── CONSTITUTION.md          # Layer 0: 最上位規範
├── AGENTS.md                # Layer 1: Mission + Quick Start
├── ROADMAP.md               # Layer 2: 何を実現するか
├── CLAUDE.md                # Claude Code 設定
├── agents/                  # エージェント定義
├── skills/                  # スキル定義
├── scripts/
│   ├── gates/               # 決定論的ゲート
│   └── hooks/               # フック
├── rules/                   # 常時適用ルール
├── tests/                   # テスト
└── docs/
    ├── STATUS.md             # 現在の状態
    ├── workflow.md           # 開発フロー（NEW: PHILOSOPHY.md から分離）
    ├── architecture.md       # システム設計
    ├── skill-map.md          # スキル/エージェント/ゲートリファレンス
    ├── terminology.md        # 用語規約
    ├── usability.md          # UX 設計
    ├── codex-patterns.md     # Codex パターン集
    ├── known-gotchas.md      # 既知問題
    ├── decisions/            # ADR
    ├── cycles/               # TDD サイクル
    ├── project-conventions/  # プロジェクト固有規約
    ├── metrics/              # メトリクス
    ├── research/             # リサーチ
    └── archive/              # アーカイブ
```

---

## 6. 未決事項（Phase 2-4 で検証）

| # | 論点 | 検証先 |
|---|---|---|
| 1 | onboard 先プロジェクトに CONSTITUTION.md を強制生成するか | Phase 7 |
| 2 | App 型での CONSTITUTION 構成は Skills 型と同じか | Phase 2 |
| 3 | CLI 型での CONSTITUTION 構成は Skills 型と同じか | Phase 3 |
| 4 | Data/ML 型での CONSTITUTION 構成は Skills 型と同じか | Phase 4 |
| 5 | 一般化テンプレート vs プロジェクト型別テンプレート | Phase 5 |
| 6 | Layer 名は全プロジェクト型で共通か | Phase 5 |

---

## 7. レビュー履歴

| レビュアー | 結果 | 主な指摘と対応 |
|---|---|---|
| Socrates Protocol | 3 objections | onboard 波及→Phase 7 で対応 / 分割是非→採用 / 配置マップ→skill-map.md に統合 |
| GPT Review | 4 corrections | Goal/Non-Goals 追加 / 前提圧縮 / 矛盾解決ルール吸収 / 変更ポリシー補強 |
| design-reviewer | PASS (22) | 影響ファイル漏れ追加 / Source of Truth を Layer 構造維持 / ROADMAP 方針更新 |
