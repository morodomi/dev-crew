---
feature: agents-md-skill-propagation
cycle: phase-6
phase: DONE
complexity: standard
test_count: 14
risk_level: low
created: 2026-03-14 11:12
updated: 2026-03-14 17:21
---

# AGENTS.md Skill Propagation

## Scope Definition

### In Scope
- [ ] Sub-task 1: TC-B1/TC-B2 bug fix (grep target CLAUDE.md -> AGENTS.md)
- [ ] Sub-task 2: onboard AGENTS.md generation (SKILL.md + reference.md updates)
- [ ] Sub-task 3: Skill reference updates (commit/SKILL.md, skills-catalog.md, staleness hook)
- [ ] Sub-task 4: Test assertion updates (phase-gate, onboard-research)

### Out of Scope
- Actual onboard execution on target projects (Reason: this is doc/config changes only)
- AGENTS.md content generation logic runtime testing (Reason: onboard generates prompts, not runtime code)

### Files to Change (target: 10 or less)
- tests/test-skills-structure.sh (edit) - TC-B1/TC-B2 grep fix
- skills/onboard/SKILL.md (edit) - AGENTS.md generation step
- skills/onboard/reference.md (edit) - generation logic, mode detection, merge strategy
- skills/commit/SKILL.md (edit) - doc update table
- docs/skills-catalog.md (edit) - onboard entry update
- scripts/hooks/check-claude-md-staleness.sh (edit) - AGENTS.md check
- tests/test-onboard-agents-md.sh (new) - new test file
- tests/test-phase-gate.sh (edit) - AGENTS.md assertion
- tests/test-onboard-research.sh (edit) - backup + section count

## Environment

### Scope
- Layer: Both
- Plugin: dev-crew
- Risk: 15 (PASS)

### Runtime
- Language: Shell (bash)

### Dependencies (key packages)
- grep, bash (standard)

### Risk Interview (BLOCK only)
N/A - PASS

## Context & Dependencies

### Reference Documents
- AGENTS.md - dev-crew's own AGENTS.md (canonical pattern)
- CLAUDE.md - dev-crew's CLAUDE.md (@AGENTS.md import pattern)
- docs/decisions/ - ADR infrastructure from Phase 5

### Dependent Features
- Phase 3: AGENTS.md/CLAUDE.md separation (completed)
- onboard skill: current CLAUDE.md-only generation

### Related Issues/PRs
- ROADMAP Phase 6: AGENTS.md Skill Propagation

## Test List

### TODO
(none)

### WIP
(none)

### DISCOVERED
- [ ] Signal #0未使用: 検出シグナルテーブルにAGENTS.mdがあるが分類ロジックで未参照。AGENTS.mdのみ存在ケースがfresh扱いになる
- [ ] dev-crew-installed MISSING配列にAGENTS.md未追加
- [ ] 2ファイルメンタルモデル説明不足 (SKILL.md/reference.md)
- [ ] 既存single-CLAUDE.mdプロジェクトのマイグレーションパス未文書化
- [ ] エラーリカバリガイダンス不足 (誤ファイル編集時の復旧手順)

### DONE
- [x] TC-01: Given SKILL.md, When reading, Then description mentions AGENTS.md
- [x] TC-02: Given reference.md Step 4, When reading, Then AGENTS.md generation section exists
- [x] TC-03: Given reference.md Step 4, When reading, Then CLAUDE.md contains @AGENTS.md template
- [x] TC-04: Given reference.md mode detection, When reading, Then AGENTS.md is detection signal
- [x] TC-05: Given reference.md backup, When reading, Then AGENTS.md.bak is mentioned
- [x] TC-06: Given SKILL.md checklist, When reading, Then AGENTS.md step exists
- [x] TC-07: Given reference.md section count, When reading, Then max 5 AGENTS.md sections stated
- [x] TC-08: Given commit/SKILL.md, When reading doc table, Then AGENTS.md is listed
- [x] TC-09: Given skills-catalog.md, When reading onboard entry, Then AGENTS.md is mentioned
- [x] TC-10: Given staleness hook, When AGENTS.md exists, Then both AGENTS.md and CLAUDE.md are checked
- [x] TC-11: Given staleness hook, When AGENTS.md not exists, Then only CLAUDE.md is checked (backward compat)
- [x] TC-12: Given reference.md mode detection, When AGENTS.md absent, Then CLAUDE.md-based detection still works (backward compat)
- [x] TC-13: Given test-onboard-research.sh existing TCs, When Step 4 split applied, Then existing TCs still pass
- [x] TC-14: Given test-skills-structure.sh TC-B1/TC-B2, When grep target changed, Then tests pass against AGENTS.md

## Implementation Notes

### Goal
Propagate AGENTS.md canonical pattern to target projects via onboard skill, fix broken tests, and update all skill references.

### Background
Phase 3 completed AGENTS.md/CLAUDE.md separation for dev-crew itself. However, the onboard skill still only generates CLAUDE.md for target projects. TC-B1/TC-B2 tests are broken because they grep CLAUDE.md but content moved to AGENTS.md.

### Design Approach
1. Fix broken tests first (Sub-task 1)
2. Update onboard to generate both AGENTS.md + CLAUDE.md with @AGENTS.md import (Sub-task 2)
3. Propagate references across commit skill, catalog, and hooks (Sub-task 3)
4. Update test assertions for phase-gate and onboard-research (Sub-task 4)

Content split for target projects: AGENTS.md (max 5 sections: Overview, Quick Commands, TDD Workflow, Quality Standards, Project Structure) + CLAUDE.md (max 2 sections: @AGENTS.md import, AI Behavior Principles).

### Codex Debate Findings & Decisions

**Finding 1 (HIGH): Test coverage gap for existing onboard TCs**
- Decision: Sub-task 4 explicitly includes existing test-onboard-research.sh TC修正。TC-13追加で既存TC非破壊を検証。
- Step 4分割時、既存TCのgrep対象やセクション参照を同時更新する。

**Finding 2 (MEDIUM): Backward compatibility for mode detection**
- Decision: AGENTS.mdは**追加signal**として扱う。既存CLAUDE.mdベースの判定は維持。
- Layout判定: `agents-md-first` (AGENTS.md存在) / `claude-md-only` (CLAUDE.mdのみ) / `none`
- 既存3モード (fresh/existing-no-tdd/dev-crew-installed) との組み合わせは直交。TC-12で後方互換を検証。

**Finding 3 (MEDIUM): Staleness hook two-file model**
- Decision: **両ファイルをチェック**。AGENTS.md存在時はAGENTS.md + CLAUDE.md両方の鮮度を確認。AGENTS.md不在時はCLAUDE.mdのみ（現行動作維持）。
- TC-10/TC-11で両パターンを検証。

## Progress Log

### 2026-03-14 11:12 - KICKOFF
- Cycle doc created from plan
- 10 test cases transferred (TC-01 to TC-10)
- 4 sub-tasks sequenced: bug fix -> core -> propagation -> test updates
- Codex debate: 3 findings (1 HIGH, 2 MEDIUM). 4 TCs追加 (TC-11〜TC-14), test_count 10→14
- HIGH対応: 既存TC非破壊をTC-13で検証、Sub-task 4スコープ拡大
- MEDIUM対応: モード検出は追加signal(TC-12), staleness hookは両ファイル(TC-10/TC-11)

### 2026-03-14 17:21 - COMMIT
- Committed: AGENTS.md skill propagation (Phase 6)
- AGENTS.md test count updated (33→50)
- TC-09 regex tightened per Codex review
- Phase completed

### 2026-03-14 16:53 - REVIEW
- review(code) score:35 verdict:PASS
- 5 agents: security(5), correctness(22), performance(5), product(32), usability(35)
- 5 DISCOVERED items recorded (doc improvements for next cycle)
- Phase completed

### 2026-03-14 15:55 - REFACTOR
- /simplify: 3 parallel review agents (reuse, quality, efficiency)
- Fixed: redundant AGENTS.md existence guard in hook, LINES_AFTER_STEP divergence (40->30), fragile TC-11 regex, TC-13 output swallowing
- Skipped: test helper commonization (pre-existing pattern, separate cycle)
- Verification Gate passed: 75/75 tests
- Phase completed

### 2026-03-14 15:51 - GREEN
- 6 files edited: onboard/SKILL.md, onboard/reference.md, commit/SKILL.md, skills-catalog.md, check-claude-md-staleness.sh, test-skills-structure.sh
- 2 existing tests updated: test-onboard-research.sh (TC-09), test-phase-gate.sh (TC-13)
- All 75 tests passing across 6 test suites
- Phase completed

### 2026-03-14 11:16 - RED
- 2 test files created: test-onboard-agents-md.sh (9 TCs), test-agents-md-propagation.sh (5 TCs)
- 12 tests failing, 2 passing (TC-12/TC-13 backward compat already satisfied)
- Phase completed

---

## Next Steps

1. [Done] KICKOFF
2. [Done] RED
3. [Done] GREEN
4. [Done] REFACTOR
5. [Done] REVIEW
6. [Done] COMMIT <- Complete
