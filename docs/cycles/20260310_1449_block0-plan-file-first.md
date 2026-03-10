---
feature: block0-plan-file-first
cycle: 20260310_1449
phase: DONE
complexity: standard
test_count: 10
risk_level: low
created: 2026-03-10 14:49
updated: 2026-03-10 15:33
---

# Block 0 Plan ファイル起点の決定木 + review --plan 統合

## Scope Definition

### In Scope
- [x] orchestrate Block 0 を Plan ファイル起点の3分岐に変更
- [x] orchestrate Block 0 新規開始フローに review --plan 追加
- [x] review SKILL.md plan mode で Plan ファイルを Gate 対象にする
- [x] review SKILL.md code mode の Cycle Doc Gate / Phase Ordering Gate は維持
- [x] 既存テストの整合性維持

### Out of Scope
- orchestrate の実行時ロジック変更（ドキュメント修正のみ）
- review reference.md / steps-subagent.md の詳細更新

### Files to Change (target: 10 or less)
- skills/orchestrate/SKILL.md (edit)
- skills/orchestrate/steps-subagent.md (edit)
- skills/orchestrate/steps-teams.md (edit)
- skills/review/SKILL.md (edit)
- tests/test-review-plan-gate.sh (new)
- tests/test-cycle-doc-ssot.sh (edit)
- tests/test-tdd-enforcement.sh (edit)

## Environment

### Scope
- Layer: Markdown (skill procedure docs)
- Plugin: dev-crew
- Risk: 10 (PASS)

### Runtime
- OS: Darwin 25.2.0

### Dependencies (key packages)
- Claude Code Plugin system

## Context & Dependencies

### Root Cause
1. orchestrate Block 0 が Cycle doc を先に確認し、phase: DONE の cycle doc を未完了と誤認していた
2. Block 0 に review --plan が含まれず、spec 後の設計レビューが実行されなかった
3. review SKILL.md の plan mode が Cycle Doc Gate を通ろうとして BLOCK になっていた

### Design Decision
Plan ファイルを SSOT として起点にする3分岐:
1. Plan ファイルあり + 未完了 cycle doc → 再開
2. Plan ファイルあり + cycle doc なし/全 DONE → kickoff へ
3. Plan ファイルなし → 新規開始 (spec → review --plan → approve)

## Test List

### TODO
(none)

### WIP
(none)

### DISCOVERED
- ~~grep -L 'phase: DONE' body-text false negative~~ → 本サイクル内で修正済み (frontmatter-only awk matching)

### DONE
- [x] TC-01: SKILL.md Block 0 checks Plan file first
- [x] TC-02: steps-subagent.md Block 0 checks Plan file first
- [x] TC-03: steps-teams.md Block 0 checks Plan file first
- [x] TC-04: SKILL.md has dev-crew:review
- [x] TC-05: steps-subagent.md Block 0 has review --plan
- [x] TC-06: steps-teams.md Block 0 has review --plan
- [x] TC-07: review/SKILL.md plan mode input is Plan file
- [x] TC-08: review/SKILL.md Cycle Doc Gate is code mode only
- [x] TC-09: review/SKILL.md still has Cycle Doc Gate
- [x] TC-10: review/SKILL.md Phase Ordering Gate is code mode only

## Implementation Notes

### Goal
orchestrate 手動起動時に phase: DONE の cycle doc を誤認しない + review --plan を自動実行する

### Background
ユーザーが orchestrate を手動起動すると、DONE の cycle doc が存在するだけで「既存サイクルの続き」と誤解し RED に飛んでいた。また spec 後に review --plan が呼ばれず設計レビューがスキップされていた。

### Design Approach
Plan ファイルを起点とする決定木に変更。`grep -rL 'phase: DONE'` で DONE を除外。review SKILL.md の plan mode では Cycle Doc Gate をスキップし Plan ファイルの存在確認のみとする。

## Progress Log

### 2026-03-10 14:49 - KICKOFF
- Cycle doc created (retroactive)
- Phase completed

### 2026-03-10 14:49 - RED
- test-review-plan-gate.sh 10 tests created, all failing (7 FAIL)
- Phase completed

### 2026-03-10 14:49 - GREEN
- orchestrate SKILL.md, steps-subagent.md, steps-teams.md Block 0 変更
- review SKILL.md plan mode gate 変更
- test-cycle-doc-ssot.sh, test-tdd-enforcement.sh 更新
- All tests passing (10/10 new + all existing)
- Phase completed

### 2026-03-10 14:57 - REFACTOR
- TC-08/TC-10 false positive match fix (awk section extraction for precise validation)
- planファイル表記統一 (Plan ファイル / Plan file → planファイル)
- Verification Gate passed: all tests PASS
- Phase completed

### 2026-03-10 15:03 - REVIEW (round 1)
- DISCOVERED: grep -L body-text false negative → 即修正決定
- review(code) score:62 verdict:WARN
- security-reviewer: 10 (PASS), correctness-reviewer: 62 (WARN)
- Fix: grep -rL → grep -L (steps-subagent.md, steps-teams.md)
- DISCOVERED: grep -L body-text false negative (frontmatter-only matching needed)

### 2026-03-10 15:14 - RED/GREEN (DISCOVERED fix)
- TC-11~13: frontmatter-only matching のテスト追加 (3 tests)
- grep -L → awk frontmatter extraction に変更 (steps-subagent.md, steps-teams.md, review/SKILL.md)
- All tests passing (13/13 new + all existing)

### 2026-03-10 15:14 - REVIEW (round 2)
- review(code) DISCOVERED fix included, all tests PASS
- Phase completed

### 2026-03-10 15:33 - COMMIT
- Committed changes
- Phase completed
