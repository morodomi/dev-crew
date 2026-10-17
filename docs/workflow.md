# Development Workflow

> CONSTITUTION.md の原則に基づく開発フロー。承認ゲート・決定論的ゲート・Findings判断の詳細。

## 開発フロー

```
User: 「ログイン機能追加して」
  │
  ▼
spec (Claude)
  │  plan mode → 設計・曖昧性検出(※)
  │  → Claude plan-review (review --plan)             ← 設計レビュー
  │  → (Codex plan-review → findings → draft plan へ直接反映 → 最終版を1回だけ再レビュー)  ← Codex利用可能時、承認前（spec Step 8）
  │  → `## Plan Review Record` を plan に記録（Codex不在時は `codex_unavailable` 記録）
  │  → approve(レビュー済み plan の承認)               ← 承認ゲート(1)
  │  → sync-plan(Plan Review Record を Cycle doc へ転記)
  │  → architect(転記後検証: 転記欠落=BLOCK / scope実質変更=再承認 / 観察のみ=DISCOVERED)
  │  → (Codex委譲確認: full/no)                      ← Codex利用可能時
  │  → compact
  │
  ▼
■ pre-red-gate.sh                          ← 決定論的ゲート(1)
  │  Cycle doc存在? sync-plan完了? Plan Review (pre-approval) 記録・reviewed_plan_hash照合?
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
REVIEW (Codex)                             [fallback: adversarial-reviewer]
  │  敵対的レビュー 1 回 → 指摘を「直す / 人間に戻す / 記録のみ」に振り分け
  │  COMMIT 前に毎回 md を見せて OK/NG  ← 承認ゲート(2)
  │  （人間に戻すが 0 件なら、決めてほしいことは空）
  │
  ▼
cycle-retrospective (Claude)
  │  失敗-成功 insight 抽出。abort signal → COMMIT BLOCK
  │
  ▼
■ pre-commit-gate.sh                       ← 決定論的ゲート(2)
  │  REVIEW完了? Codex review記録? retro_status?
  │  exit 1 → BLOCK（不足ステップに戻す）
  │
  ▼
COMMIT (Claude)
  │  cycle N コミット完了
  │
  ▼
DONE (cycle N 完了)
  │  phase: DONE 遷移（commit skill Step 3）。cycle doc は完了 artifact として確定
  ╎
  ╎  ─── cycle N+1 起動 ───
  ╎
  ▼
[次サイクル Block 0] Codify notice ← orchestrate が件数を通知するだけ
  │  retro_status: captured の cycle doc を数える (frontmatter-only scan)
  │  1 件以上なら 1 行通知。件数にかかわらず次フェーズへ
  │
  ╎  （任意・別 commit）人間が /dev-crew:codify-insight を手動起動
  ╎  原則は自動 triage（rule / inline-update / defer / no-codify）
  ╎  Cycle doc EOF に ## Codify Decisions を append、retro_status: captured → resolved
  ╎  rules 等への反映は別サイクル
  │
  ▼
sync-plan → RED → GREEN → ... → COMMIT → DONE (cycle N+1 本体フロー、以下同じ)
```

## 承認と確認

人間の主要な承認ゲートは2箇所:

1. **spec完了時**: レビュー済み plan の承認。plan review（Claude 設計レビュー + Codex利用可能時は competitive review）は承認前に完了しており、人間は findings 反映済みの最終版に対して「これで作っていい？」と判断する
2. **REVIEW後（既存の動きが変わるときのみ）**: 振り分けで「人間に戻す」になった指摘（既存の動きを変えるかどうか）の判断。それ以外の実装の細部は AI 側で完結し、自動進行する。

※ spec中の曖昧性検出では AskUserQuestion による追加確認が入る。これは承認ではなく、誤実装を防ぐための仕様確定プロセス。

## 決定論的ゲート

LLMの手順スキップを機械的に防止するゲートは2箇所:

1. **pre-red-gate.sh**: RED開始前。Cycle doc存在・sync-plan完了・Plan Review (pre-approval) 記録（verdict enumerate・reviewed_plan_hash実照合含む）を検証
2. **pre-commit-gate.sh**: COMMIT開始前。REVIEW完了・Codex review記録・retro_status を検証

承認ゲートは「人間が判断する」場所。決定論的ゲートは「LLMが忘れる」場所。両者は補完関係にある。

## Findings判断

次の表は plan review の結果を、Claudeが知的誠実性をもって判断する基準。code mode の REVIEW は、この表ではなく `skills/orchestrate/adversarial-review.md` の 3 区分（直す / 人間に戻す / 記録のみ）に従う。

| 判断 | 条件 |
|------|------|
| Accept | 指摘が妥当 → 即修正 |
| Reject | 明確な理由を説明でき、Codexが納得できる |
| AskUserQuestion | ビジネス判断が必要、またはdebateが発生 |
| DISCOVERED | 今回のスコープ外 → 次回タスクへ |
| ADR | アーキテクチャ上の重要決定 → 記録 |

## sync-plan

sync-plan = 承認済みplanをCycle docへ昇格させ、plan の `## Plan Review Record`（Codex plan review の承認前記録）を Cycle doc frontmatter/Progress Log へ転記する軽量エージェント。旧kickoffのCycle doc生成責務を置き換える。転記後は architect が Post-Transfer Verification（転記欠落=BLOCK / scope実質変更=再承認 / 観察のみ=DISCOVERED）を実施する。

## 決定論的ゲートによるプロセス保証

LLMがPdMとしてフローを制御する以上、手順スキップは避けられない。ゲートスクリプトが `exit 1` でBLOCKすることで、Cycle docの状態が要件を満たすまで次フェーズに進めない。これはLLMへの指示（確率的）ではなく、シェルスクリプトの終了コード（決定論的）による保証。

| ゲート | チェック内容 | 防ぐ問題 |
|--------|-------------|---------|
| pre-red-gate.sh | Cycle doc, sync-plan, Plan Review | sync-plan飛ばし、レビューなし開発 |
| pre-commit-gate.sh | REVIEW, Codex review, retro_status | レビューなしコミット、retrospective スキップ |
