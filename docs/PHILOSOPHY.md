# Philosophy

> このドキュメントはdev-crewの目指す姿（target philosophy）を記述する。既存の運用ドキュメント（CLAUDE.md, architecture.md, 各SKILL.md）は移行途上であり、矛盾がある場合はこのドキュメントを正とする。

## 一言

人間が楽をするための開発体制。

## 前提

AIがコードを生成する時代、人間は「やりたいこと」と「OK/NG」だけ出す。設計から実装まで全てAIが実行する。「ログイン機能を追加して」と言えば設計が完了し、OKを出せば実装が完了する。それが目指す体験。

## 90/10 問題

AIは確率的に90%正しいコードを出力する。だがプログラムは残り10%が間違っていてはいけない。この10%を埋めるのがテスト、レビュー、静的解析（linter, exspec）の役割であり、dev-crewが存在する理由。

## 原則

### 1. AI-first

設計・実装・テスト・レビュー・コミットの全工程をAIが実行する。人間はゴールを伝え、判断ポイントでOK/NGを出すだけ。

### 2. 多角的レビュー

AIの確率的出力を、複数の視点で検証する。同じコードを異なるAI（Claude, Codex）、異なるレビュアー（security, correctness, performance）が見ることで、単一視点では見逃す問題を捕捉する。品質は「どの視点で、どれだけレビューしたか」で決まる。

### 3. 性格差の活用

| AI | 役割 | 性格 |
|----|------|------|
| Claude | PdM/Orchestrator: 設計、調整、判断、REFACTOR | 計画・調整型。忖度気質で甘めの評価 |
| Codex | Implementer + Reviewer: テスト作成、実装、レビュー（利用可能時に優先） | 辛口ベテランエンジニア気質。忖度しない |

これは「作る側/壊す側」の意図的な分離ではなく、AIの持つ性格差を武器にした品質担保。

### 4. Fallback

全ての人がClaude + Codex両方の契約を持つわけではない。usage上限で片方が使えなくなることもある。dev-crewのスキルは単一モデルでもフローが回るように設計する。ClaudeがPdM/Orchestratorとして常駐し、Codexが利用可能な場合に実装・レビューを優先的に委譲する。

### 5. 速度とのトレードオフ

人間なら1-2ヶ月かかる実装を2時間で終わらせることが理想。レビューに1日使えばバグは減るが、AIなら3-5分で終わる。完璧を求めて速度を犠牲にしない。

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
  │  → (Codex plan-review → findings → Claude判断)  ← Codex利用可能時
  │  → (Codex委譲確認: full/no)                      ← Codex利用可能時
  │  → compact
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
COMMIT (Claude)
```

### 承認と確認

人間の主要な承認ゲートは2箇所:

1. **spec完了時**: 設計方針の承認。「これで作っていい？」
2. **REVIEW後（debate時のみ）**: Claude/Codexのレビューで意見が割れた場合の最終判断。軽微な修正（エラー修正、try catch等）は両者ACCEPTで自動進行。

※ spec中の曖昧性検出では AskUserQuestion による追加確認が入る。これは承認ではなく、誤実装を防ぐための仕様確定プロセス。

### Findings判断

Codexのレビュー結果をClaudeが知的誠実性をもって判断する:

| 判断 | 条件 |
|------|------|
| Accept | 指摘が妥当 → 即修正 |
| Reject | 明確な理由を説明でき、Codexが納得できる |
| AskUserQuestion | ビジネス判断が必要、またはdebateが発生 |
| DISCOVERED | 今回のスコープ外 → 次回タスクへ |
| ADR | アーキテクチャ上の重要決定 → 記録 |

### sync-plan

sync-plan = 承認済みplanをCycle docへ昇格させる軽量エージェント。旧kickoffのCycle doc生成責務を置き換える。specの内部サブタスクとして実行され、ユーザーからは独立フェーズとして見えない。

## なぜこのフローが成立するか

### Phase-Boundary Compaction

各フェーズの成果をCycle docに永続化し、フェーズ間でコンテキストを圧縮する。これにより:

- 各フェーズは前フェーズの全会話履歴を持つ必要がない
- Cycle docとファイルシステム（テストコード、実装コード）からコンテキストを復元する
- Claude/Codex間のハンドオフもCycle doc経由で成立する

### Cycle Doc as State Handoff

Cycle docがフェーズ間の状態引き継ぎの単一ソース:

| 遷移 | Cycle docに永続化するもの |
|------|--------------------------|
| spec(sync-plan) → RED | スコープ、環境、Test List |
| RED → GREEN | テスト計画、テストファイル |
| GREEN → REFACTOR | 実装ファイル |
| REFACTOR → REVIEW | リファクタ結果 |
| REVIEW → COMMIT | レビュー結果、findings |

## なぜこの体制か

AIが大量にコードを生成する時代、バグの少ないソフトウェアを作れるかは「生成したコードを、どの視点で、どれだけレビューしたか」にかかっている。人間がやっていたら1ヶ月かかるレビューをAIが3分で終わらせる。その3分を複数回、複数視点で回すことで、人間が楽をしながら品質を担保する。
