---
feature: fix-reviewer-scoring
cycle: 20260216_1049
phase: COMMIT
created: 2026-02-16 10:49
updated: 2026-02-16 11:15
issue: "#18"
---

# fix: 各reviewerのスコアリングの基準の明確化

## Problem Statement

quality-gate実行時、correctness-reviewerとperformance-reviewerがスコアの意味を誤解。
`"confidence": 85` を「自分のレビューへの自信度 85%」と解釈した。
意図は「問題の深刻度 85 = BLOCK」。

### Root Cause

1. JSONフィールド名 `"confidence"` が「自信度」と誤解される
2. セクション名 `## 信頼スコア基準` が「信頼/自信のスコア」と読める
3. skill description の `信頼スコアでPASS/WARN/BLOCK` も同様に曖昧

## Scope Definition

### In Scope

- [ ] 9 reviewer agents: `confidence` → 明確な名称に変更 + スコア説明を追加
- [ ] skills/quality-gate: SKILL.md + reference.md のスコア用語統一
- [ ] skills/plan-review: SKILL.md + reference.md のスコア用語統一
- [ ] skills/review/reference.md のスコア用語統一
- [ ] テストで用語統一を検証

### Out of Scope

- skills/spec の Risk score (別概念、変更不要)
- skills/plan のリスクスコア連動 (init由来、変更不要)
- skills/attack-report の CVSS score (外部規格、変更不要)
- orchestrate の判断基準テーブル (skills側の用語が修正されれば整合する)

### Files to Change (target: 10 or less)

Agents (9 files):
- agents/correctness-reviewer.md
- agents/performance-reviewer.md
- agents/security-reviewer.md
- agents/guidelines-reviewer.md
- agents/product-reviewer.md
- agents/risk-reviewer.md
- agents/scope-reviewer.md
- agents/architecture-reviewer.md
- agents/usability-reviewer.md

Skills (7 files):
- skills/quality-gate/SKILL.md
- skills/quality-gate/reference.md
- skills/quality-gate/steps-subagent.md
- skills/plan-review/SKILL.md
- skills/plan-review/reference.md
- skills/plan-review/steps-subagent.md
- skills/review/reference.md

Test (1 file):
- tests/test-reviewer-scoring.sh (new)

合計: 17ファイル (10超過だがagentsは全て同一パターンの機械的変更、skillsもパターン統一)

NOT in scope (confidence が別概念のファイル):
- agents/observer.md (confidence 0.0-1.0 = パターン信頼度、別概念)
- agents/false-positive-filter-reference.md (confidence 0.0-1.0 = 判定確度、別概念)
- skills/learn/reference.md (confidence 0.0-1.0 = instinct 信頼度、別概念)
- skills/diagnose/steps-subagent.md (confidence 0-100 = 仮説確信度、別概念)
- skills/diagnose/reference.md (confidence 0-100 = 仮説確信度、別概念)

### Naming Decision

| Before | After | Reason |
|--------|-------|--------|
| `"confidence"` | `"blocking_score"` | パイプラインのブロック度を直接表現、issues[].severity との衝突回避 |
| `信頼スコア基準` | `ブロッキングスコア基準` | 「信頼」の曖昧さ排除、BLOCK/WARN/PASS に直結 |
| `信頼スコア` | `ブロッキングスコア` | 統一 |

スコア方向: 0 = 問題なし(PASS), 100 = ブロック必須(BLOCK) (既存方向を維持)

Decision: Socrates Protocol (plan-review WARN 75) → `blocking_score` は `issues[].severity` と語幹衝突 → `blocking_score` に変更

## Environment

- Language: Markdown (agent/skill definitions)
- Test: bash script (structure validation)

## Risk

Risk: 15 (PASS)
- 既存の方向性(0=PASS, 100=BLOCK)は変更なし
- 用語のリネームのみで動作ロジックへの影響なし

## PLAN

### Design

3つのカテゴリで用語を統一する。全て機械的な置換。

#### Category A: Agent files (9 files)

対象: `agents/*-reviewer.md` 全9ファイル

全ファイルが同一パターン。変更箇所3点:

**変更1: JSON出力形式のフィールド名**

Before:
```json
{
  "confidence": 0-100,
  "issues": [...]
}
```

After:
```json
{
  "blocking_score": 0-100,
  "issues": [...]
}
```

**変更2: セクション見出し**

Before: `## 信頼スコア基準`
After: `## ブロッキングスコア基準`

**変更3: スコア説明の追加**

Before:
```
## 信頼スコア基準

- 80-100: BLOCK（修正必須）
- 50-79: WARN（警告）
- 0-49: PASS（問題なし）
```

After:
```
## ブロッキングスコア基準

blocking_score はレビュー結果がパイプラインをブロックすべき度合いを表す（0 = 問題なし, 100 = ブロック必須）。

- 80-100: BLOCK（修正必須）
- 50-79: WARN（警告）
- 0-49: PASS（問題なし）
```

#### Category B: Skill SKILL.md / reference.md (5 files)

対象:
- skills/quality-gate/SKILL.md
- skills/quality-gate/reference.md
- skills/plan-review/SKILL.md
- skills/plan-review/reference.md
- skills/review/reference.md

**B-1: YAML description (quality-gate/SKILL.md, plan-review/SKILL.md)**

Before: `信頼スコアでPASS(0-49)/WARN(50-79)/BLOCK(80-100)を判定`
After: `ブロッキングスコアでPASS(0-49)/WARN(50-79)/BLOCK(80-100)を判定`

**B-2: 本文中の「信頼スコア」(全5ファイル)**

Before: `各エージェントの信頼スコアを集計`
After: `各エージェントのブロッキングスコアを集計`

**B-3: セクション見出し (reference.md 3ファイル)**

Before: `## 信頼スコア詳細` / `### 信頼スコア`
After: `## ブロッキングスコア詳細` / `### ブロッキングスコア`

**B-4: セクション本文 (reference.md 3ファイル)**

Before: `各エージェントが0-100の信頼スコアを返す`
After: `各エージェントが0-100のブロッキングスコアを返す（0 = 問題なし, 100 = ブロック必須）`

**B-5: JSON例 (quality-gate/reference.md, plan-review/reference.md)**

Before: `"confidence": 85` / `"confidence": 75`
After: `"blocking_score": 85` / `"blocking_score": 75`

#### Category C: steps-subagent.md (2 files)

対象:
- skills/quality-gate/steps-subagent.md
- skills/plan-review/steps-subagent.md

**C-1: JSON例**

Before: `"confidence": 0-100`
After: `"blocking_score": 0-100`

### Test List

tests/test-reviewer-scoring.sh で以下を検証:

| ID | Test Case | What to verify |
|----|-----------|----------------|
| TC-01 | 全reviewer agentに `blocking_score` が存在 | 9ファイル全てで `"blocking_score"` を含むこと |
| TC-02 | 全reviewer agentに旧 `confidence` が残っていない | 9ファイル全てで `"confidence"` を含まないこと |
| TC-03 | 全reviewer agentに `ブロッキングスコア基準` セクションが存在 | 9ファイル全てで `ブロッキングスコア基準` を含むこと |
| TC-04 | 全reviewer agentに旧 `信頼スコア基準` が残っていない | 9ファイル全てで `信頼スコア基準` を含まないこと |
| TC-05 | 全reviewer agentにスコア説明文が存在 | 9ファイル全てで `0 = 問題なし` を含むこと |
| TC-06 | quality-gate SKILL.md に `ブロッキングスコア` がある | description に `ブロッキングスコア` を含むこと |
| TC-07 | plan-review SKILL.md に `ブロッキングスコア` がある | description に `ブロッキングスコア` を含むこと |
| TC-08 | skill reference.md に旧用語が残っていない | quality-gate, plan-review, review の reference.md で `信頼スコア` を含まないこと |
| TC-09 | steps-subagent.md に旧用語が残っていない | 2ファイルで `"confidence"` を含まないこと |
| TC-10 | スコープ外ファイルの confidence は変更されていない | observer.md, false-positive-filter-reference.md, learn/reference.md で `"confidence"` が残っていること |

## Progress Log

### INIT - 10:49
- Issue #18 の問題分析完了
- 根本原因: `confidence` フィールド名と `信頼スコア` セクション名の曖昧さ
- 影響ファイル14件特定
- Cycle doc 作成

### PLAN - 10:55
- 全17ファイルの現状を読み込み、変更パターンを3カテゴリ(A/B/C)に分類
- INIT で漏れていた3ファイルを発見: steps-subagent.md x2, skills/review/reference.md (Files to Change に追加)
- スコープ外の confidence 使用箇所(observer, false-positive-filter, learn)が別概念であることを確認
- Test List 10件作成 (TC-01 ~ TC-10)
- 設計完了、RED フェーズへ進行可能

### plan-review - 10:57
- 5 reviewer 並行レビュー完了
- Scope: 25, Architecture: 25, Risk: 15, Product: 15, Usability: 75
- 最大スコア: 75 (WARN) → Socrates Protocol 発動

### Socrates Protocol - 11:00
- Socrates 3 Objections + 2 Alternatives:
  - O1: `severity_score` と `issues[].severity` の語幹衝突 → **採用** → `blocking_score` に変更
  - O2: diagnose 等の追加ファイル漏れ → **部分採用** (diagnose は別概念、NOT in scope に追記)
  - O3: JSON コメント無効 → **採用** (JSON外のテキスト説明に変更)
  - A1: `blocking_score` → **採用** (衝突ゼロ、自己文書化、閾値直結)
  - A2: 段階的リリース → **見送り** (Markdown リネームでランタイムリスクなし)
- Human judgment: Option 1 (`blocking_score`, 17ファイル一括) → proceed
- PLAN 更新完了、RED フェーズへ

### RED - 11:05
- tests/test-reviewer-scoring.sh 作成 (10 test cases, 53 assertions)
- RED state: 1 PASS / 52 FAIL (TC-10 のみ PASS = スコープ外ガード)
- GREEN フェーズへ進行

### GREEN - 11:10
- 16ファイル全て更新完了
  - Category A: 9 reviewer agents (confidence → blocking_score, section heading + explanation)
  - Category B: 5 skill files (SKILL.md x2, reference.md x3)
  - Category C: 2 steps-subagent.md files
- Test実行: 10 PASS / 0 FAIL (53 assertions 全通過)
- REFACTOR フェーズへ進行可能

### REFACTOR - 11:15
- tests/test-reviewer-scoring.sh リファクタリング完了
  - 3つのヘルパー関数を追加 (check_all_files_contain, check_all_files_not_contain, check_single_file_contains)
  - TC-01 ~ TC-10 のループロジックを関数呼び出しに置換
  - 定数配列を上部に集約 (REVIEWER_FILES, REF_FILES, STEPS_FILES, SCOPE_EXTERNAL)
  - 238行 → 176行 (62行削減, 26%改善)
- Test実行: 10 PASS / 0 FAIL (53 assertions 全通過)
- 既存テスト確認:
  - test-agents-structure.sh: 3 PASS / 0 FAIL
  - test-skills-structure.sh: 5 PASS / 0 FAIL
- Agent/skill ファイルの整合性確認:
  - 全9 reviewer agents の説明文が完全一致
  - フォーマット統一確認済み
- REVIEW フェーズへ進行可能

### REVIEW - 11:20
- quality-gate 6 reviewer 並行実行完了
- スコア: Correctness 0, Performance 5, Security 15, Guidelines 0, Risk 5, Architecture 15
- 最大スコア: 15 (Security/Architecture) → PASS
- DISCOVERED: 未起票項目なし
- COMMIT フェーズへ進行

## DISCOVERED

- steps-subagent.md 2ファイル (quality-gate, plan-review) にも `"confidence": 0-100` が存在し、INIT の Files to Change に漏れていた。PLAN で追加済み。
