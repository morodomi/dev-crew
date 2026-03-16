# CONSTITUTION

## 1. One Sentence

人間が楽をするための開発体制。

## 2. Goal / Non-Goals

- **Goal**: 人間の判断負荷を減らしつつ、壊れにくい変更を高速に出す
- **Non-Goals**: 人間排除、完全自動化、最小トークン消費、レビュー省略

## 3. 前提

AIがコードを生成する時代、人間は「やりたいこと」と「OK/NG」だけ出す。
AIは確率的に90%正しい出力をするが、コードもワークフローも90%では足りない。
残り10%を埋めるのがテスト・レビュー・静的解析・決定論的ゲートであり、dev-crewが存在する理由。
バグの少ないソフトウェアを作れるかは「生成したコードを、どの視点で、どれだけレビューしたか」にかかっている。

## 4. 原則

1. **AI-first**: 設計・実装・テスト・レビュー・コミットの全工程をAIが実行。人間はゴールを伝え、判断ポイントでOK/NGを出すだけ
2. **多角的レビュー**: 同じコードを異なるAI、異なるレビュアーが見る。品質は「どの視点で、どれだけレビューしたか」で決まる
3. **性格差の活用**: Claude=計画・調整型（PdM/Orchestrator）、Codex=辛口ベテラン型（Implementer+Reviewer）。性格差を武器にした品質担保
4. **Fallback**: 単一モデルでもフローが回る設計。Codex利用可能時に優先委譲、不在時はClaude fallback
5. **速度とのトレードオフ**: 完璧を求めて速度を犠牲にしない。AIなら3-5分で終わるレビューを複数回・複数視点で回す
6. **決定論的プロセス保証**: プロセス強制は決定論的コード（ゲートスクリプト）、品質検出はLLM（レビューエージェント）。LLMに「手順を守れ」と指示するのではなく、ゲートが exit 1 でBLOCKする

## 5. Quality Standards

| Metric | Target |
|--------|--------|
| Test coverage | 90%+ (min 80%) |
| Static analysis | 0 errors |
| Test design | Given/When/Then |

## 6. Human vs AI 責務

| 担当 | 責務 |
|------|------|
| AI が担う | 設計案生成、実装、テスト作成、レビュー、指摘抽出、コミット |
| 人間が担う | 優先順位決定、曖昧仕様の確定、最終承認、トレードオフ裁定 |
| AI に期待しない | 手順の自然遵守、事実の無検証保証、ビジネス責任の代行 |

## 7. Source of Truth（5-Layer Authority）

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

## 8. 変更ポリシー

- CONSTITUTION の変更は ADR 必須（docs/decisions/ に記録）
- コードから導出可能な情報は書かない
- **書かないこと**: workflow 詳細、モデル固有の運用、一時的 workaround、具体スクリプトの細部
- これらは docs/workflow.md, docs/architecture.md, docs/STATUS.md に置く
