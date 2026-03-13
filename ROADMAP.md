# ROADMAP: Multi-AI Orchestration

## Vision

dev-crewを単一AIツール依存から脱却させ、Claude CodeとCodexを統合する。異なるモデルの視点を活かし、反論プロトコルで設計品質を昇華させる。

## Why

- 異なるモデルの視点で反論し合うことで、仕様の曖昧さが消える
- 現状はコピペでCycle docsをやり取りしており、非効率
- 特定AIツールへのロックインを避ける

## Design Principles

1. **CLIベース統合**: MCPは使わない。各AIのCLIを直接呼び出す
2. **ファイルベース通信**: Cycle docs / decisions/ を介して非同期に論点を記録
3. **AGENTS.md正本**: クロスツール共通の設定はAGENTS.mdに集約。CLAUDE.mdはClaude固有の拡張のみ
4. **Single-AI Baseline**: Claude Code単体で全フェーズが完結する。Sub AIは品質向上のオプション
5. **Main AI = Claude Code**: オーケストレーション・最終判断・承認はClaude Codeが担う

## Roles & Responsibilities

| 役割 | 担当 | 責務 |
|------|------|------|
| Phase Owner | Claude Code (Main AI) | 全フェーズの実行責任。Sub AI不在時は全て代行 |
| Phase Executor | Codex (Sub AI) | RED/GREEN/REVIEWの実行を委譲される |
| Plan Reviewer | Codex | 設計フェーズでの反論 |
| Phase Approver | Claude Code | 各フェーズの成果物を承認してから次へ進める |
| Final Go/No-Go | Human (株主) | 最終判断。設計理由の説明を受けて決定 |

## AI CLI Capabilities

| CLI | 非対話実行 | セッション継続 | ファイル操作 | 出力制御 |
|-----|-----------|--------------|------------|---------|
| `codex exec` | `--full-auto` | `resume <session-id>` | `--sandbox workspace-write` | `-o file`, `--json`, `--output-schema` |
| `claude` | Main AI | セッション内 | ネイティブ | ネイティブ |

### 呼び出しパターン

```bash
# Codex: 非対話実行
codex exec --full-auto -o <output> -C <dir> "プロンプト"
# Codex: セッション継続
codex exec resume <session-id> --full-auto -o <output> "プロンプト"
# Codex: コードレビュー
codex review --uncommitted
```

### 設定ファイルの読み込み

| CLI | デフォルト | AGENTS.mdを読ませる方法 |
|-----|----------|----------------------|
| Codex | `AGENTS.md` | ネイティブ対応 |
| Claude Code | `CLAUDE.md` | `@AGENTS.md` で import |

### 対象外としたAI CLI

- **Gemini CLI**: セッション継続(`-r`)、非対話実行(`-p`)、設定統一(`context.fileName`)の機能は確認済み。ただし現時点ではスコープ外とする。アダプタ層の設計は将来の追加を妨げない

## Architecture

```
Human (株主)
  │
  ▼
Claude Code (Main AI / Phase Owner / Approver)
  │
  ├── which codex で利用可能なSub AIを検出
  │
  ├── 設計フェーズ (SPEC/PLAN)
  │   ├── Claude Code: plan 作成
  │   ├── Codex: 反論 (codex exec) ← optional
  │   ├── Claude Code: 再反論・統合
  │   ├── [フォールバック] Codex不在 → 既存plan-review (Claude Code単体)
  │   └── 収束判断 → decisions/ に理由を記録
  │
  ├── 実装フェーズ
  │   ├── RED:      Codex (exec resume) or Claude Code
  │   ├── GREEN:    Codex (同セッション) or Claude Code
  │   ├── REFACTOR: Claude Code
  │   ├── REVIEW:   Codex (review --uncommitted) or Claude Code
  │   ├── COMMIT:   Claude Code
  │   └── [フォールバック] Codex不在 → Claude Code が全フェーズ代行
  │
  └── 人間への説明
      └── "なぜその設計になったか" を decisions/ から構成
```

## Config Unification

### Before (現状)

```
CLAUDE.md  ← Claude Code が読む
AGENTS.md  ← Codex が読む (内容はCLAUDE.mdのコピー)
```

### After (目標)

```
AGENTS.md (正本: 全AIが読む)
  ├── 設計思想、ルール、構造、ワークフロー
  ├── Codex: ネイティブに読む
  └── Claude Code: CLAUDE.md に @AGENTS.md で import

CLAUDE.md (Claude固有の拡張)
  ├── @AGENTS.md  ← 共通設定を import
  ├── スキルトリガー定義
  ├── フック定義
  └── サブエージェント定義
```

### Migration Strategy

1. CLAUDE.mdから共通部分をAGENTS.mdに移動
2. CLAUDE.mdに `@AGENTS.md` を追加してClaude Codeから読めるようにする
3. Claude CodeがAGENTS.mdをネイティブ対応したら `@AGENTS.md` 行を削除するだけ

## Debate Protocol (反論プロトコル)

### フロー

```
1. Claude Code が提案をファイルに書く
2. Codex に渡して反論を求める:
   codex exec --full-auto -o /tmp/codex_counter.md -C <project> < proposal.md
3. Claude Code が反論を読み、再反論 or 受け入れ
4. 収束するまで繰り返す (最大3ラウンド)
5. 合意した理由を docs/decisions/ にADRとして記録
6. 人間に説明して最終判断を仰ぐ
```

### 反論時に渡すコンテキスト

全文丸投げではなく、以下に限定する:
- 提案ファイル本体
- 現在のCycle doc要約（あれば）
- 関連ADR一覧（あれば）
- 変更対象ファイル一覧

### 採択基準 (Decision Scorecard)

反論の採用/却下はMain AIが以下5項目で判断し、ADRに記録する:

| 項目 | 評価内容 |
|------|---------|
| Requirements Fit | 要件との整合性 |
| Security | セキュリティリスク |
| Operability | 運用のしやすさ |
| Complexity | 複雑度は妥当か |
| Testability | テスト可能か |

統合記録のフォーマット:
- Accepted: 採用した論点と理由
- Rejected: 却下した論点と理由
- Deferred: 人間判断に委ねた論点

### Session管理

```bash
# Codex: 初回 → stderr に session id: <UUID>
codex exec --full-auto -C <project> "プロンプト"
# Codex: 継続
codex exec resume <session-id> --full-auto -o <output> "次のプロンプト"
```

Session IDはCycle docに記録する。

### 収束判断

Claude Code が以下を判断:
- 新しい論点が出なくなった
- 双方の主張が同じ結論に収束した
- トレードオフが明確になり、人間の判断を仰ぐべき状態になった
- 最大3ラウンドに到達した

## TDD Gate (テスト一貫性の担保)

Codex に RED/GREEN を委譲する際のゲート:

```
1. SPEC/PLANでTest Planを作成・凍結 (Claude Code)
2. RED: Codex はTest Planから逸脱不可
3. Claude Code がRED fail を確認 (Gate 1)
4. GREEN: Codex は最小実装
5. Claude Code がGREEN pass を確認 (Gate 2)
6. REFACTOR: Claude Code が実行
```

Test Planの凍結 = Cycle docに記載されたテスト項目をCodexが勝手に変更しない。
Gate通過 = Claude Codeがテスト結果を検証してから次フェーズへ進める。

## Implementation Phases

### Phase 1: AI Adapter Layer

シェルスクリプトとして実装（どのAIからも呼べるように）。

アダプタ契約:
- `detect()`: AI CLIの存在確認
- `invoke()`: 非対話実行
- `resume()`: セッション継続実行
- `review()`: コードレビュー実行
- `normalize_output()`: 出力の正規化
- `extract_session_id()`: セッションID抽出
- `timeout/retry`: タイムアウト・リトライ処理

### Phase 2: Debate Skill

反論プロトコルをdev-crewスキルとして実装。

- 入力: 提案ファイル (Markdown)
- 処理: 利用可能なSub AIに反論を求める（並列可）
- 出力: Decision Scorecardを含むADRをdocs/decisions/に作成
- 収束判断: Claude Code が行う
- フォールバック: Sub AI不在 → 既存plan-review（Claude Code単体）

### Phase 3: AGENTS.md Migration

Migration Strategyセクション参照。

### Phase 4: Workflow Integration

orchestrate スキルを拡張し、フェーズごとにSub AIへ委譲。

| フェーズ | Owner (Claude Code) | Codex | Codex不在時 |
|---------|-------------------|-------|------------|
| SPEC/PLAN | 作成 | 反論 | 既存plan-review |
| RED | Gate 1確認 | exec resume | Claude Codeが代行 |
| GREEN | Gate 2確認 | exec resume | Claude Codeが代行 |
| REFACTOR | 実行 | - | - |
| REVIEW | 実行 | review --uncommitted | Claude Codeが代行 |
| COMMIT | 実行 | - | - |

### Phase 5: Decision Records

`docs/decisions/` ディレクトリにADR (Architecture Decision Record) を蓄積。

```markdown
# ADR-001: タイトル

## Status: accepted

## Context
何が問題だったか

## Decision Scorecard
| 項目 | 評価 | 理由 |
|------|------|------|
| Requirements Fit | ... | ... |
| Security | ... | ... |
| Operability | ... | ... |
| Complexity | ... | ... |
| Testability | ... | ... |

## Arguments
### Accepted
- 採用した論点と理由
### Rejected
- 却下した論点と理由
### Deferred
- 人間判断に委ねた論点

## Decision
何を決めたか

## Consequences
その結果どうなるか
```

## Resolved Questions

1. **Gemini**: 検討の結果、現時点では対象外。機能は確認済み（セッション継続、非対話実行、設定統一）なので将来追加は容易
2. **設定ファイル統一**: AGENTS.md正本
3. **Main AI**: Claude Code固定。オーケストレーション・承認・最終判断を担う
4. **Graceful Degradation**: Single-AI Baseline = Claude Code単体で全フェーズ完結。Sub AIはoptional
5. **品質責任**: Phase Owner = Claude Code。Phase Executor = Codex。Phase Approver = Claude Code
6. **TDD一貫性**: Test Plan凍結 + Gate 1 (RED fail確認) + Gate 2 (GREEN pass確認)
7. **反論の採択基準**: Decision Scorecard (5項目) + 統合記録 (Accepted/Rejected/Deferred)
8. **コンテキスト範囲**: 提案本体 + Cycle doc要約 + 関連ADR + 変更対象一覧に限定
9. **コスト制御**: 反論ラウンド最大3回
10. **呼び出し層**: invoke_ai → AIごとのアダプタ契約 (7メソッド)
11. **セッションID管理**: Cycle docに記載する運用で確定
12. **AGENTS.md migration**: 互換期間不要。AGENTS.mdに共通部分を書き、CLAUDE.mdに`@AGENTS.md`を追加。ネイティブ対応後に行を消すだけ
13. **機密情報**: `.gitignore`準拠。リスク許容。漏洩時はAPI Key再発行
14. **出力フォーマット**: Markdown。LLMが受け取るのでJSON schema不要
15. **Gate証跡**: Cycle doc記録 + pre-commit hook推奨
16. **Session lifecycle**: 1サイクル1セッション。完了で破棄。Context肥大化防止

## Open Questions

なし。全て解消済み。

## Resolved Counter-Arguments (Round 3)

Codex R3で「条件付きGo」として残された2点への回答:

### 機密情報
リスク許容する。Claude CodeもCodexも同じワークスペースをローカルで見ている。漏洩時はAPI Key再発行で対応。`.gitignore`準拠で十分。

### 自動化契約
不要。理由:
- **Debate出力schema**: LLMが受け取る前提なのでMarkdownで十分。`--output-schema`でJSON強制する必要なし
- **Gate判定証跡**: Cycle docに記録 + pre-commit hookで担保。dev-crewの既存ワークフローでカバー済み
- **Session lifecycle**: 1サイクル1セッションID。引き継がない。Context肥大化を防ぐため、サイクル完了でセッション破棄

## Counter-Arguments Log

### Round 1 (Codex)

> 反論全文: /tmp/codex_counter.md

10項目の反論。主要指摘: Main AI責任の曖昧さ、反論プロトコルの実効性、TDD一貫性、セキュリティ。

### Round 1 (Gemini)

> 反論全文: /tmp/gemini_counter.md

4カテゴリの反論。Codexと共通する指摘が多い。追加: コンテキスト不足、キメラ設計リスク。

### Round 2 (Codex)

> 反論全文: /tmp/codex_counter2.md

解消された点: Gemini役割限定、設定統一、ADR。
未解消として具体提案: Phase Owner/Approver固定、Decision Scorecard、アダプタ契約、Test Plan凍結、Single-AI Baseline、マスキング3分類。
→ 本版でPhase Owner/Approver、Decision Scorecard、アダプタ契約、TDD Gate、Single-AI Baselineを反映。
