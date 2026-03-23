---
phase: DONE
---

# Phase 15.3: Socrates Devil's Advocate review pipeline 統合

## Metadata

| Key | Value |
|-----|-------|
| Status | IN_PROGRESS |
| Phase | COMMIT |
| Created | 2026-03-17 |
| Branch | feature/phase-15-1-test-reviewer |
| Risk | LOW |

## Context

review pipeline では各 reviewer が blocking_score を返し、最大スコアで PASS/WARN/BLOCK を判定する。しかし reviewer 自体が LLM であるため、忖度バイアスにより important 指摘を出しつつもスコアを低めに付ける傾向がある（例: Phase 15.1 で correctness-reviewer が important 5件出しつつ score 42 = PASS）。

Socrates agent を Step 4 (Specialist Panel) と Step 5 (Score Aggregation) の間に Devil's Advocate フェーズとして組み込み、reviewer の忖度バイアスを構造的に検出する。

## Scope

### In Scope

| # | 内容 | ファイル | type |
|---|------|---------|------|
| 1 | steps-subagent.md に Step 4.5 Devil's Advocate 追加 | skills/review/steps-subagent.md | modify |
| 2 | reference.md に Score Escalation セクション追加 | skills/review/reference.md | modify |
| 3 | socrates.md の description 更新（全判定で発動） | agents/socrates.md | modify |
| 4 | ROADMAP.md に Phase 15.3 追記 | ROADMAP.md | modify |
| 5 | テスト新設 | tests/test-socrates-review-integration.sh | new |
| 6 | STATUS.md 更新 | docs/STATUS.md | modify |

### Out of Scope

- Socrates 自体の性格変更（既に反論専門として適切に定義済み）
- Socrates にスコア付けさせる（advisor はスコアを付けない原則を維持）
- orchestrate スキルの変更（orchestrate は review スキルを呼ぶだけ）

## Design

### Step 4.5: Devil's Advocate (steps-subagent.md)

Step 4 完了後、Socrates を起動して reviewer スコアの妥当性を検証。

```
Task(subagent_type: "dev-crew:socrates", model: "opus", prompt: "
phase: review:[plan|code]
score: [max blocking_score]
reviewer_summary: [各reviewerのスコアとissuesサマリ]
pdm_proposal: [auto-verdictに基づく判断提案: PASS/WARN/BLOCK]
cycle_doc: [cycle docパス]
")
```

### Score Escalation - PdM 判断基準 (reference.md)

Socrates は反論+選択肢を返すだけ（advisor 原則維持）。Escalation 判定は PdM が行う。

| Socrates の反論内容 | 元の verdict | PdM の判断 |
|-------------------|-------------|-----------|
| 反論なし（稀） | そのまま | そのまま |
| 反論あり、二次影響の指摘なし | そのまま | そのまま |
| 反論あり、reviewer が見逃した二次影響を指摘 | PASS | PdM が WARN に昇格を検討 |
| 反論あり、reviewer のスコアと指摘件数に乖離 | PASS/WARN | PdM が 1段階昇格を検討 |
| 反論あり、BLOCK 妥当性の補強 | BLOCK | BLOCK（変化なし） |

原則: PdM は verdict を下げない（厳しい方向にのみ作用）。

### socrates.md description 更新

旧: 「WARN/BLOCK時に発動」
新: 「全判定で発動」（PASS 時こそ忖度が最も危険）

## Test List

- [x] TC-01: steps-subagent.md に "Step 4.5" または "Devil's Advocate" が含まれる
- [x] TC-02: steps-subagent.md に socrates の Task 呼び出しが含まれる
- [x] TC-03: reference.md に Score Escalation セクションが含まれる
- [x] TC-04: reference.md に PASS から WARN への昇格ルールが含まれる
- [x] TC-05: socrates.md の description に review pipeline 関連の記述がある
- [x] TC-06: socrates.md の description に「WARN/BLOCK時」が含まれない（旧表現の除去確認）
- [x] TC-07: ROADMAP.md に Phase 15.3 が含まれる
- [x] TC-08: リグレッション: 関連テスト全通過

### DISCOVERED

- Socrates の起動条件を Risk-gated にする検討（LOW risk PR でのコスト最適化）

## Progress Log

### 2026-03-17 02:00 - PLAN

- Cycle doc 作成
- Socrates 反証: 3反論（advisor原則矛盾、コスト、False Positive蓄積）
- 反論1採用: Escalation 判定は PdM が行う設計に修正（advisor 原則維持）
- 反論2/3却下: 見逃しリスク > コスト/False Positive リスク
- Keiba 実例: reviewer が見逃したキャッシュ invalidation を Socrates が検出 → 広さ(reviewer) vs 深さ(Socrates) の分担が有効

### 2026-03-17 02:10 - RED

- テスト 8件作成 (test-socrates-review-integration.sh)
- TC-05 のみ通過（socrates.md 本文に既存記述）、6件失敗、TC-08 通過
- Phase completed

### 2026-03-17 02:15 - GREEN

- skills/review/steps-subagent.md: Step 4.5 Devil's Advocate 追加（Socrates Task 呼び出し）
- skills/review/reference.md: Score Escalation セクション追加（PdM 判断基準）
- agents/socrates.md: description 更新（全判定で発動、忖度バイアス+二次影響検出）
- ROADMAP.md: Phase 15.3 追記
- docs/STATUS.md: 更新
- 全8テスト通過
- REFACTOR: Markdown のみ、改善対象なし
- Phase completed

### 2026-03-17 02:30 - REVIEW

- Socrates 単体 code review（Step 4.5 適用）
- 反論1: 全判定 Opus 起動は Risk-gated scaling 原則と矛盾 → DISCOVERED（次フェーズで検討）
- 反論2: Score Escalation の「検討」が曖昧 → 据え置き（PdM 裁量は意図的設計）
- 反論3: テスト順序チェック不足 → 据え置き（LLM 実行のため文字列チェックで十分）
- verdict: PASS
- Phase completed
