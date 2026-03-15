---
feature: post-approve-ordering
cycle: 20260315_1600
phase: DONE
complexity: trivial
test_count: 6
risk_level: low
created: 2026-03-15 16:00
updated: 2026-03-15 16:00
---

# fix: Post-Approve Action ordering (#54)

## Scope Definition

### In Scope
- [x] skills/spec/reference.md: Post-Approve Action 手順1↔2入れ替え
- [x] skills/spec/reference.ja.md: 同上
- [x] tests/test-post-approve-ordering.sh (new, 6 TCs)

### Out of Scope
- PHILOSOPHY.md (Reason: authoritative doc, already correct)

### Files to Change (3 files)
- skills/spec/reference.md (edit)
- skills/spec/reference.ja.md (edit)
- tests/test-post-approve-ordering.sh (new)

## Environment

### Scope
- Layer: Documentation
- Plugin: dev-crew
- Risk: 10 (PASS - テンプレート文言修正のみ)

### Runtime
- Language: Shell (tests), Markdown (skills)

### Dependencies (key packages)
- None

## Context & Dependencies

### Reference Documents
- docs/PHILOSOPHY.md L53-55 - authoritative ordering (plan review → sync-plan)

### Related Issues/PRs
- DISCOVERED from #54 (codex-delegation-interface cycle)

## Test List

### DONE
- [x] TC-01: reference.md Post-Approve Action で Plan review が Cycle doc より前
- [x] TC-02: reference.ja.md Post-Approve Action で Plan review が Cycle doc より前
- [x] TC-03: reference.md Post-Approve Action に3ステップ全て含まれる
- [x] TC-04: reference.ja.md Post-Approve Action に3ステップ全て含まれる
- [x] TC-05: PHILOSOPHY.md で plan review が sync-plan より前 (authoritative source)
- [x] TC-06: test-plugin-structure.sh が通る (regression)

## Implementation Notes

### Goal
Post-Approve Action テンプレートの手順順序を PHILOSOPHY.md と一致させる。

### Background
spec の plan テンプレートで Cycle doc 作成 (sync-plan) が Plan review より前に記載されていた。Plan review は plan ファイルに対して実行する必要があるため、Cycle doc に昇格する前に行わなければならない。

### Design Decisions
1. テンプレートの手順1と2を入れ替えるだけ (PHILOSOPHY.md は既に正しい)

## Progress Log

### 2026-03-15 16:00 - RED
- Test code created: tests/test-post-approve-ordering.sh (4 TCs)
- TC-01, TC-02 failing (Plan review after Cycle doc), TC-03, TC-04 passing
- Phase completed

### 2026-03-15 16:05 - GREEN
- reference.md: Post-Approve Action 手順1↔2入れ替え
- reference.ja.md: 同上
- 4/4 tests PASS
- Phase completed

### 2026-03-15 16:05 - REFACTOR
- No changes needed (テンプレート文言修正のみ)
- Phase completed

### 2026-03-15 16:10 - REVIEW
- Codex code review: 2 findings (1 Medium, 1 Low), both Accept
  - Finding 1 (Medium): Accept - PHILOSOPHY.md を authoritative source として直接検証する TC-05 追加
  - Finding 2 (Low): Accept - 3ステップ存在確認を日本語版にも追加 (TC-04)
- テスト拡張後 6/6 tests PASS
- Phase completed

### 2026-03-15 16:15 - COMMIT
- 359d351 fix: Post-Approve Action ordering - Plan review before Cycle doc (#54)
- 4e37bf6 test: strengthen Post-Approve ordering tests per Codex review
- Phase completed
