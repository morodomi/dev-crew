---
feature: kickoff-to-sync-plan-migration
cycle: 20260314_2159
phase: REVIEW
complexity: complex
test_count: 15
risk_level: medium
created: 2026-03-14 21:59
updated: 2026-03-14 22:42
---

# Phase 11.1: kickoff → sync-plan Migration

## Scope Definition

### In Scope
- [ ] sync-plan agent 作成 (agents/sync-plan.md)
- [ ] kickoff ディレクトリを archive へ移動
- [ ] architect.md を Skill(kickoff) → Task(sync-plan) に変更
- [ ] orchestrate 関連ファイル更新 (SKILL.md, reference.md, steps-*.md)
- [ ] spec 関連ファイル更新 (SKILL.md, reference.md)
- [ ] Gate メッセージ更新 (red/green/refactor/review/commit/diagnose)
- [ ] rules/state-ownership.md 更新
- [ ] ドキュメント更新 (architecture.md, terminology.md, usability.md, skill-md-frontmatter.md)
- [ ] テスト更新 + 新規 migration テスト

### Out of Scope
- Cycle doc の phase: KICKOFF 名称変更 (Reason: 既存 cycle doc との互換性)
- strategy/SKILL.md の review(plan) 変更 (Reason: orchestrate/spec と直交する独立機能)

### Files to Change (target: 10 or less)
- agents/sync-plan.md (new)
- agents/architect.md (edit)
- skills/orchestrate/SKILL.md (edit)
- skills/orchestrate/reference.md (edit)
- skills/orchestrate/steps-subagent.md (edit)
- skills/orchestrate/steps-teams.md (edit)
- skills/orchestrate/steps-codex.md (edit)
- skills/spec/SKILL.md (edit)
- skills/spec/reference.md (edit)
- skills/red/SKILL.md (edit)
- skills/green/SKILL.md (edit)
- skills/refactor/SKILL.md (edit)
- skills/review/SKILL.md (edit)
- skills/commit/SKILL.md (edit)
- skills/commit/reference.md (edit)
- skills/diagnose/SKILL.md (edit)
- rules/state-ownership.md (edit)
- docs/architecture.md (edit)
- docs/terminology.md (edit)
- docs/usability.md (edit)
- docs/project-conventions/skill-md-frontmatter.md (edit)
- skills/kickoff/ (archive) → docs/archive/skills-kickoff/
- tests/ (rename + edit multiple)

## Environment

### Scope
- Layer: Both
- Plugin: N/A (plugin structure migration)
- Risk: 40 (WARN)

### Runtime
- Shell scripts (bash)
- Markdown files

### Dependencies (key packages)
- None (documentation/configuration changes only)

## Context & Dependencies

### Reference Documents
- [docs/PHILOSOPHY.md](../PHILOSOPHY.md) - Target workflow definition
- [docs/ROADMAP.md](../ROADMAP.md) - Phase 11.1 planning

### Dependent Features
- orchestrate skill: workflow control
- spec skill: plan mode entry point
- All phase skills: gate messages

## Test List

### TODO
- [ ] TC-01: agents/sync-plan.md exists with frontmatter (name, description, model)
- [ ] TC-02: agents/sync-plan.md contains Cycle doc generation workflow
- [ ] TC-03: agents/sync-plan.md contains Debate Workflow
- [ ] TC-04: skills/kickoff/ directory does not exist; test-auto-kickoff.sh and test-kickoff-debate.sh do not exist
- [ ] TC-05: agents/architect.md references Task(sync-plan), not Skill(kickoff)
- [ ] TC-06: orchestrate/steps-subagent.md Block 1 references sync-plan
- [ ] TC-07: orchestrate/steps-teams.md Block 1 references sync-plan
- [ ] TC-08: orchestrate/SKILL.md contains no "kickoff" references
- [ ] TC-09: spec/SKILL.md Post-Approve Action references sync-plan
- [ ] TC-10: Gate messages in red/green/refactor/review/commit say "run spec"
- [ ] TC-11: state-ownership.md references sync-plan, not kickoff
- [ ] TC-12: docs/architecture.md contains no "kickoff" in flow diagram
- [ ] TC-13: docs/terminology.md does not list kickoff as skill name
- [ ] TC-14: rg "kickoff" skills/ CLAUDE.md AGENTS.md docs/ --glob '!docs/cycles/**' --glob '!docs/ROADMAP.md' --glob '!docs/STATUS.md' --glob '!docs/archive/**' returns 0 results
- [ ] TC-15: All existing tests pass (regression)

### WIP
(none)

### DISCOVERED
(none)

### DONE
(none)

## Implementation Notes

### Goal
Migrate kickoff skill to sync-plan agent as first step toward PHILOSOPHY.md target workflow.

### Background
kickoff exists as an independent skill (skills/kickoff/) that generates Cycle docs from plan files. The target architecture merges this into a sync-plan agent (agents/sync-plan.md) called via Task() from spec, eliminating kickoff as a user-visible phase.

### Design Approach
1. Create sync-plan agent consolidating kickoff SKILL.md + reference.md logic
2. Archive kickoff directory to docs/archive/skills-kickoff/
3. Update all references: architect → Task(sync-plan), gate messages → "run spec"
4. Update documentation and tests
5. Sequencing: Sub-task 1 → 2 → 3 → 4 → 5

### Debate Summary
- Rounds: 1 (Codex plan review)
- Accepted: TC-14 exclusion paths specified; TC-04 expanded to cover test file renames
- Rejected: strategy/SKILL.md migration (explicitly Out of Scope per plan; separate cycle)
- Clarified: state-ownership.md uses agent name (sync-plan) in permission table, phase name KICKOFF preserved in Cycle docs

## Progress Log

### 2026-03-14 21:59 - KICKOFF
- Cycle doc created from plan (Phase 11.1)
- Phase completed

### 2026-03-14 22:00 - RED
- Created test-sync-plan-migration.sh with 15 test cases
- All tests failing (RED state confirmed)
- Phase completed

### 2026-03-14 22:10 - GREEN
- Sub-task 1: Created agents/sync-plan.md, archived skills/kickoff/ to docs/archive/skills-kickoff/
- Sub-task 2: Updated architect.md (Skill(kickoff) → Task(sync-plan)), orchestrate files (SKILL.md, reference.md, steps-*.md)
- Sub-task 3: Updated gate messages in 6 skills (run kickoff → run spec), state-ownership.md, spec files
- Sub-task 4: Updated architecture.md, terminology.md, usability.md, skill-md-frontmatter.md
- Sub-task 5: Renamed test files, updated test-architect-improvement.sh, test-decision-records.sh, test-phase-gate.sh, test-state-ownership.sh, test-doc-consistency.sh
- All 15 migration tests passing
- Phase completed

### 2026-03-14 22:30 - REFACTOR
- No refactoring needed (documentation migration, no code logic)
- Phase completed

### 2026-03-14 22:42 - REVIEW
- Codex plan review completed (3 findings: TC-14 exclusions, test rename verification, strategy scope)
- 15/15 migration tests passing
- Pre-existing test failures verified as unrelated to migration
- Phase completed
