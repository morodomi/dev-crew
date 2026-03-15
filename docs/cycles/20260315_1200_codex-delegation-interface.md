---
feature: codex-delegation-interface
cycle: 20260315_1200
phase: DONE
complexity: standard
test_count: 18
risk_level: medium
created: 2026-03-15 12:00
updated: 2026-03-15 12:00
---

# Codex Delegation Interface + Competitive Review

## Scope Definition

### In Scope
- [ ] red/reference.md: Codex Delegation section
- [ ] green/reference.md: Codex Delegation section
- [ ] steps-codex.md: REVIEW supplementary → competitive
- [ ] review/SKILL.md: Codex Integration note
- [ ] review/steps-subagent.md: Codex cross-reference NOTE
- [ ] review/reference.md: Competitive Review section
- [ ] refactor/SKILL.md: Codex Execution note
- [ ] tests/test-codex-delegation-interface.sh (new, 18 TCs)

### Out of Scope
- PHILOSOPHY.md changes (Reason: authoritative doc, already correct)
- orchestrate/SKILL.md changes (Reason: no Codex-specific content needed)
- steps-subagent.md workflow changes (Reason: only adding cross-reference)

### Files to Change (8 files)
- skills/red/reference.md (edit)
- skills/green/reference.md (edit)
- skills/orchestrate/steps-codex.md (edit)
- skills/review/SKILL.md (edit)
- skills/review/steps-subagent.md (edit)
- skills/review/reference.md (edit)
- skills/refactor/SKILL.md (edit)
- tests/test-codex-delegation-interface.sh (new)

## Environment

### Scope
- Layer: Both (skill definition + documentation)
- Plugin: N/A (plugin structure change)
- Risk: 35 (WARN - multiple file changes, workflow impact)

### Runtime
- Language: Shell (tests), Markdown (skills/docs)

### Dependencies (key packages)
- None

## Context & Dependencies

### Reference Documents
- docs/PHILOSOPHY.md - target workflow, Findings Judgment table (lines 92-101)
- skills/orchestrate/steps-codex.md - current Codex delegation flow

### Dependent Features
- orchestrate skill: controls Codex delegation flow
- review skill: Claude-side review pipeline
- red/green skills: Codex-first execution

### Related Issues/PRs
- None

## Test List

### TODO
- [ ] TC-01: red/reference.md contains Codex heading
- [ ] TC-02: red/reference.md contains fallback mention
- [ ] TC-03: red/reference.md contains steps-codex.md reference
- [ ] TC-04: green/reference.md contains Codex heading
- [ ] TC-05: green/reference.md contains fallback mention
- [ ] TC-06: green/reference.md contains steps-codex.md reference
- [ ] TC-07: steps-codex.md REVIEW section contains "competitive"
- [ ] TC-08: steps-codex.md does NOT contain "supplementary"
- [ ] TC-09: steps-codex.md does NOT contain "advisory"
- [ ] TC-10: steps-codex.md contains Findings Judgment (Accept/Reject)
- [ ] TC-11: steps-codex.md contains DISCOVERED and ADR
- [ ] TC-12: review/SKILL.md contains Codex section
- [ ] TC-13: review/steps-subagent.md contains Codex cross-reference
- [ ] TC-14: review/reference.md contains Competitive Review section
- [ ] TC-15: review/reference.md contains Accept/Reject/AskUserQuestion
- [ ] TC-16: refactor/SKILL.md contains Codex mention
- [ ] TC-17: All modified SKILL.md files under 100 lines
- [ ] TC-18: Key existing tests pass (regression)

### WIP
(none)

### DISCOVERED
- [x] Post-Approve Action ordering → issue #54
- [x] Codex session isolation → issue #55

### DONE
(none)

## Implementation Notes

### Goal
Add Codex delegation documentation to red/green/review/refactor skills and upgrade steps-codex.md REVIEW from "supplementary" to "competitive" with Findings Judgment logic.

### Background
PHILOSOPHY.md defines RED/GREEN as Codex-first (Claude fallback) and REVIEW as Claude + Codex competitive review. Current state:
- steps-codex.md REVIEW is "supplementary" (advisory) instead of "competitive"
- red/green/review reference.md have no Codex sections
- Findings Judgment logic (Accept/Reject/AskUserQuestion/DISCOVERED/ADR) exists only in PHILOSOPHY.md

### Design Decisions
1. Competitive review owner = orchestrate (review skill stays Claude-side)
2. Findings Judgment at orchestrate level (PdM judges Codex findings)
3. red/green Codex sections are informational (execution authority is orchestrate)
4. steps-codex.md "supplementary" → "competitive", remove all "advisory"

### Sequencing
Sub-task 5 (tests - RED) → Sub-task 1 (red/green) → Sub-task 2 (steps-codex) → Sub-task 3 (review) → Sub-task 4 (refactor)

## Progress Log

### 2026-03-15 12:00 - INIT
- Cycle doc created
- Scope definition ready
- DISCOVERED: Post-Approve Action ordering issue recorded

### 2026-03-15 12:05 - PLAN REVIEW (Codex)
- Codex findings: 1 Critical, 3 High, 1 Medium
- Finding 1 (Critical): Accept - DISCOVERED ordering text corrected
- Finding 2 (High): Reject - orchestrate/SKILL.md delegates to steps-codex.md via Mode Selection, progressive disclosure
- Finding 3 (High): Reject - review=Claude-side pipeline, competitive aggregation=orchestrate responsibility (by design)
- Finding 4 (High): DISCOVERED - session isolation needs cycle id-based binding (separate scope)
- Finding 5 (Medium): Reject - content presence tests appropriate for documentation changes
- Phase completed

### 2026-03-15 12:10 - RED
- Test code created: tests/test-codex-delegation-interface.sh (18 TCs)
- 16 tests failing (TC-01~16), TC-17/18 pre-passing
- Phase completed

### 2026-03-15 12:15 - GREEN
- red/reference.md: Codex Delegation section added
- green/reference.md: Codex Delegation section added
- steps-codex.md: REVIEW supplementary → competitive, Findings Judgment table added
- review/SKILL.md: Codex Integration note added
- review/steps-subagent.md: Codex NOTE added
- review/reference.md: Competitive Review section with Findings Judgment table added
- refactor/SKILL.md: Codex Execution note added
- 18/18 tests PASS
- Phase completed

### 2026-03-15 12:15 - REFACTOR
- Checklist review: no changes needed (Markdown only, no code patterns to refactor)
- SKILL.md line counts: review=49, refactor=59 (both under 100)
- Phase completed

### 2026-03-15 12:20 - REVIEW
- Claude review: score 15, PASS (cross-references correct, Findings Judgment table matches PHILOSOPHY.md)
- Codex code review: 4 findings (2 High, 2 Medium), all Accept
  - Finding 1 (High): Accept - debate→AskUserQuestion / 合意→auto-COMMIT を REVIEW後の判断に追加
  - Finding 2 (High): Accept - Findings→Score Integration セクション追加で接続
  - Finding 3 (Medium): Accept - Cycle doc 永続化指示を追加
  - Finding 4 (Medium): Accept - review 単体では competitive mode にならないことを明示
- 修正適用後 18/18 tests PASS
- review(code) score:15 verdict:PASS
- Phase completed
