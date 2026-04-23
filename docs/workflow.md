# Development Workflow

> CONSTITUTION.md の原則に基づく開発フロー。承認ゲート・決定論的ゲート・Findings判断の詳細。

## 開発フロー

```
User: 「ログイン機能追加して」
  │
  ▼
spec (Claude)
  │  plan mode → 設計・曖昧性検出(※)
  │  → approve(設計承認)                  ← 承認ゲート(1)
  │  → sync-plan(承認済みplanをCycle docへ昇格)
  │  → Claude plan-review → findings判断
  │  → (Codex plan review → findings → Claude判断)  ← Codex利用可能時
  │  → (Codex委譲確認: full/no)                      ← Codex利用可能時
  │  → compact
  │
  ▼
■ pre-red-gate.sh                          ← 決定論的ゲート(1)
  │  Cycle doc存在? sync-plan完了? Plan Review記録?
  │  exit 1 → BLOCK（不足ステップに戻す）
  │
  ▼
RED (Codex: full時)                        [fallback: Claude]
  │  テスト作成（正常系/異常系を忖度なしでカバー）
  │  → exspec（テスト静的解析）
  │
  ▼
GREEN (Codex: full時)                      [fallback: Claude]
  │  最小実装（テストを「通すだけ」の忖度をしない）
  │
  ▼
REFACTOR (Claude)                          [fallback: Codex]
  │  実装者と別の視点で品質改善
  │  N+1、変数宣言、const、重複コード
  │
  ▼
REVIEW (Claude + Codex)                    [fallback: Claude のみ]
  │  競争的レビュー → findings → Claude判断
  │  合意 → auto-COMMIT
  │  debate → AskUserQuestion             ← 承認ゲート(2)
  │
  ▼
cycle-retrospective (Claude)
  │  失敗-成功 insight 抽出。abort signal → COMMIT BLOCK
  │
  ▼
■ pre-commit-gate.sh                       ← 決定論的ゲート(2)
  │  REVIEW完了? Codex review記録? STATUS.md同期? retro_status?
  │  exit 1 → BLOCK（不足ステップに戻す）
  │
  ▼
COMMIT (Claude)
  │  cycle N コミット完了
  ╎
  ╎  ─── cycle N+1 起動 ───
  ╎
  ▼
[次サイクル Block 0] codify-insight (Claude) ← orchestrate Block 0 自動起動
  │  retro_status: captured の cycle doc を検出 (frontmatter-only scan)
  │  原則は自動 triage（rule / inline-update / defer / no-codify）
  │  skill 候補 / 低確信時のみ 1 回だけ確認
  │  Cycle doc EOF に ## Codify Decisions を append
  │  全 insight 判定 → retro_status: captured → resolved、次フェーズへ
  │  abort (exit 1) → BLOCK、/orchestrate 再起動案内
  │
  ▼
sync-plan → RED → GREEN → ... → COMMIT (cycle N+1 本体フロー、以下同じ)
```

## 承認と確認

人間の主要な承認ゲートは2箇所:

1. **spec完了時**: 設計方針の承認。「これで作っていい？」
2. **REVIEW後（debate時のみ）**: Claude/Codexのレビューで意見が割れた場合の最終判断。軽微な修正（エラー修正、try catch等）は両者ACCEPTで自動進行。

※ spec中の曖昧性検出では AskUserQuestion による追加確認が入る。これは承認ではなく、誤実装を防ぐための仕様確定プロセス。

## 決定論的ゲート

LLMの手順スキップを機械的に防止するゲートは2箇所:

1. **pre-red-gate.sh**: RED開始前。Cycle doc存在・sync-plan完了・Plan Review記録を検証
2. **pre-commit-gate.sh**: COMMIT開始前。REVIEW完了・Codex review記録・STATUS.md同期・retro_status を検証

承認ゲートは「人間が判断する」場所。決定論的ゲートは「LLMが忘れる」場所。両者は補完関係にある。

## Findings判断

Codexのレビュー結果をClaudeが知的誠実性をもって判断する:

| 判断 | 条件 |
|------|------|
| Accept | 指摘が妥当 → 即修正 |
| Reject | 明確な理由を説明でき、Codexが納得できる |
| AskUserQuestion | ビジネス判断が必要、またはdebateが発生 |
| DISCOVERED | 今回のスコープ外 → 次回タスクへ |
| ADR | アーキテクチャ上の重要決定 → 記録 |

## sync-plan

sync-plan = 承認済みplanをCycle docへ昇格させる軽量エージェント。旧kickoffのCycle doc生成責務を置き換える。specの内部サブタスクとして実行され、ユーザーからは独立フェーズとして見えない。

## 決定論的ゲートによるプロセス保証

LLMがPdMとしてフローを制御する以上、手順スキップは避けられない。ゲートスクリプトが `exit 1` でBLOCKすることで、Cycle docの状態が要件を満たすまで次フェーズに進めない。これはLLMへの指示（確率的）ではなく、シェルスクリプトの終了コード（決定論的）による保証。

| ゲート | チェック内容 | 防ぐ問題 |
|--------|-------------|---------|
| pre-red-gate.sh | Cycle doc, sync-plan, Plan Review | sync-plan飛ばし、レビューなし開発 |
| pre-commit-gate.sh | REVIEW, Codex review, STATUS.md, retro_status | レビューなしコミット、ドキュメント乖離、retrospective スキップ |
