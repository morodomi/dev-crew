---
feature: onboard-reference-hardening
cycle: phase6-discovered
phase: DONE
complexity: standard
test_count: 10
risk_level: low
created: 2026-03-14 17:38
updated: 2026-03-14 17:38
---

# Onboard Reference Hardening

## Scope Definition

### In Scope
- [ ] Sub-task 1: 分類ロジック修正 - AGENTS.md存在をfresh判定から除外 + MISSING配列にAGENTS.mdチェック追加 + TDDセクション検出にAGENTS.mdも対象追加
- [ ] Sub-task 2: 2ファイルメンタルモデル説明 (Two-File Model) - reference.md Step 4 + SKILL.md Step 4 両方
- [ ] Sub-task 3: マイグレーションパス文書化 (Single-CLAUDE.md → Two-File)
- [ ] Sub-task 4: エラーリカバリガイダンス (.bak復旧手順)

### Out of Scope
- onboard SKILLの実行ロジック変更 (Reason: ドキュメント改善のみ)
- モード分類マトリクスへの「AGENTS.md-only行」追加 (Reason: Phase 6でlayoutとmodeは直交と決定済み。layout軸は別テーブルで表現)

### Files to Change (target: 10 or less)
- skills/onboard/reference.md (edit) - Sub-task 1,2,3,4
- skills/onboard/SKILL.md (edit) - Sub-task 2 (Two-File Model説明追加)
- tests/test-onboard-discovered.sh (new) - 10 TCs

## Environment

### Scope
- Layer: Plugin
- Plugin: dev-crew
- Risk: 10 (PASS)

### Runtime
- Language: Shell (bash)

### Dependencies (key packages)
- grep, bash: system

## Context & Dependencies

### Reference Documents
- [skills/onboard/reference.md] - 修正対象
- [skills/onboard/SKILL.md] - スキル定義
- [AGENTS.md] - Two-File Model参照元

### Dependent Features
- Phase 6 (AGENTS.md Skill Propagation): 完了済み、本タスクはそのDISCOVERED項目

### Related Issues/PRs
- Phase 6 レビューで5件のDISCOVERED項目として記録

## Test List

### TODO
(none)

### WIP
(none)

### DISCOVERED
(none)

### DONE
- [x] TC-01: Given reference.md classification logic, When AGENTS.md-only project, Then not classified as fresh
- [x] TC-02: Given reference.md MISSING array, When reading, Then AGENTS.md check exists
- [x] TC-03: Given reference.md TDD section check, When reading, Then AGENTS.md is also searched
- [x] TC-04: Given reference.md, When reading classification logic, Then AGENTS.md existence prevents fresh classification (layout axis note exists)
- [x] TC-05: Given reference.md Step 4, When reading intro, Then two-file model explanation exists
- [x] TC-06: Given reference.md Step 4, When reading, Then cross-tool purpose is stated for AGENTS.md
- [x] TC-07: Given reference.md, When reading, Then migration section exists
- [x] TC-08: Given reference.md migration, When reading, Then single-CLAUDE.md upgrade path described
- [x] TC-09: Given reference.md error handling, When reading, Then AGENTS.md recovery case exists
- [x] TC-10: Given reference.md error handling, When reading, Then .bak restoration procedure exists

## Implementation Notes

### Goal
Phase 6レビューで発見された5件のDISCOVERED項目を全て解消し、onboard skillのreference.mdを完全にする。

### Background
Phase 6 (AGENTS.md Skill Propagation) は完了したが、レビューで分類ロジックの不整合、MISSING配列の欠落、メンタルモデル説明不足、マイグレーションパス未文書化、エラーリカバリ不足が記録された。

### Design Approach
reference.mdの該当箇所を順番に修正。分類ロジック→メンタルモデル→マイグレーション→エラーリカバリの順で実施。

## Progress Log

### 2026-03-14 17:38 - KICKOFF
- Cycle doc created
- 10 test cases defined from plan
- Scope: reference.md + SKILL.md documentation hardening (4 sub-tasks)
- Codex review: 3 findings反映 (SKILL.md追加、TC-04 layout軸修正、regression考慮)

### 2026-03-14 17:38 - RED
- Test file created: tests/test-onboard-discovered.sh (10 TCs)
- 8/10 FAIL, 2/10 PASS (TC-03, TC-06 already satisfied by existing docs)
- Existing tests (test-onboard-agents-md.sh, test-onboard-research.sh): all PASS
- Phase completed

### 2026-03-14 17:39 - GREEN
- Sub-task 1: Classification logic updated (AGENTS.md check in fresh/MISSING/TDD detection)
- Sub-task 2: Two-File Model explanation added to reference.md Step 4
- Sub-task 3: Migration from Single-CLAUDE.md section added
- Sub-task 4: 3 error recovery rows added (AGENTS.md merge fail, .bak restore, .bak absent)
- All 10 TCs PASS + 31 existing TCs PASS (0 regression)
- Phase completed

### 2026-03-14 17:40 - REFACTOR
- Removed unused $SKILL_CONTENT variable from test file
- Fixed TC-04 grep pattern (removed redundant alternative, used direct `-f AGENTS.md` check)
- /simplify: 3 parallel review agents (reuse, quality, efficiency)
- Verification Gate passed: 41/41 tests PASS
- Phase completed

### 2026-03-14 17:41 - REVIEW
- review(code) score:24 verdict:PASS
- Security: PASS (5) - no blocking issues
- Correctness: PASS (42) - 3 important findings fixed:
  - Matrix: AGENTS.md column added
  - TC-03: false positive fixed (grep assertion narrowed to classification logic)
  - Migration: AGENTS.md backup mention added
- 41/41 tests PASS after fixes
- Phase completed

### 2026-03-14 17:42 - COMMIT
- Committed all changes
- Phase completed

---

## Next Steps

1. [Done] KICKOFF
2. [Done] RED
3. [Done] GREEN
4. [Done] REFACTOR
5. [Done] REVIEW
6. [Done] COMMIT <- Current
