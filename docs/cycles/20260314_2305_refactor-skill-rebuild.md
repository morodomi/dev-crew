---
feature: refactor-skill-rebuild
cycle: 20260314_2305
phase: DONE
complexity: standard
test_count: 16
risk_level: medium
created: 2026-03-14 23:05
updated: 2026-03-14 23:05
---

# Refactor Skill Rebuild - /simplify dependency removal

## Scope Definition

### In Scope
- [ ] refactor SKILL.md + reference.md: /simplify -> independent checklist
- [ ] Peripheral docs: CLAUDE.md, terminology.md, README.md, reload, cycle template
- [ ] Orchestrate files: SKILL.md, reference.md, steps-subagent.md, steps-teams.md, steps-codex.md
- [ ] Tests: update existing + new test-refactor-rebuild.sh (16 TCs)

### Out of Scope
- PHILOSOPHY.md changes (Reason: authoritative doc, not in scope)
- ROADMAP.md changes (Reason: tracking doc, not in scope)
- docs/cycles/ archive (Reason: historical, no updates)

### Files to Change (16 files - all /simplify reference removals, indivisible)
- skills/refactor/SKILL.md (edit)
- skills/refactor/reference.md (edit)
- skills/orchestrate/SKILL.md (edit)
- skills/orchestrate/reference.md (edit)
- skills/orchestrate/steps-subagent.md (edit)
- skills/orchestrate/steps-teams.md (edit)
- skills/orchestrate/steps-codex.md (edit)
- CLAUDE.md (edit)
- docs/terminology.md (edit)
- README.md (edit)
- skills/reload/SKILL.md (edit)
- skills/reload/reference.md (edit)
- skills/spec/templates/cycle.md (edit)
- tests/test-doc-consistency.sh (edit)
- tests/test-subagent-task-delegation.sh (edit)
- tests/test-refactor-rebuild.sh (new)

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
- docs/PHILOSOPHY.md - target workflow (Claude=REFACTOR, fallback: Codex)

### Dependent Features
- orchestrate skill: delegates REFACTOR phase
- reload skill: references /simplify in next-action mapping

### Related Issues/PRs
- None

## Test List

### TODO
- [ ] TC-01: refactor/SKILL.md does NOT contain `/simplify`
- [ ] TC-02: refactor/SKILL.md contains checklist (チェックリスト or checklist)
- [ ] TC-03: orchestrate/SKILL.md does NOT contain `/simplify`
- [ ] TC-04: orchestrate/reference.md does NOT contain `/simplify`
- [ ] TC-05: steps-subagent.md REFACTOR section does NOT contain `Skill("simplify")`
- [ ] TC-06: steps-teams.md REFACTOR section does NOT contain `Skill("simplify")`
- [ ] TC-07: steps-codex.md does NOT contain `/simplify`
- [ ] TC-08: CLAUDE.md does NOT contain `/simplify`
- [ ] TC-09: README.md does NOT contain `/simplify`
- [ ] TC-10: terminology.md does NOT contain `/simplify`
- [ ] TC-11: reload/SKILL.md does NOT contain `/simplify`
- [ ] TC-12: reload/reference.md does NOT contain `/simplify`
- [ ] TC-13: cycle.md template does NOT contain `/simplify`
- [ ] TC-14: All existing tests pass (regression)
- [ ] TC-15: refactor/SKILL.md Verification Gate unchanged (Tests PASS + lint + format)
- [ ] TC-16: refactor/SKILL.md contains prohibition rules (テストを壊す, 新機能, テスト削除)

### WIP
(none)

### DISCOVERED
(none)

### DONE
(none)

## Implementation Notes

### Goal
Remove /simplify dependency from refactor skill and replace with independent checklist-driven refactoring logic that works cross-tool (Claude + Codex).

### Background
refactor skill currently delegates to Claude Code built-in `/simplify`. Codex lacks `/simplify`, so cross-tool execution fails. PHILOSOPHY.md targets Claude=REFACTOR with Codex fallback.

### Design Approach
1. Replace `/simplify` delegation with 7-item checklist (DRY, constants, unused imports, let->const, method split, N+1, naming consistency)
2. Incremental approach: 1 improvement -> test -> next improvement
3. Verification Gate unchanged: Tests PASS + lint 0 + format OK

### Sequencing (revised)
Sub-task 1 (refactor SKILL.md + reference.md) -> Sub-task 3 (peripheral docs) -> Sub-task 2 (orchestrate files) -> Sub-task 4 (tests)

## Progress Log

### 2026-03-14 23:05 - INIT
- Cycle doc created
- Scope definition ready

### 2026-03-14 23:05 - PLAN REVIEW (Codex)
- Codex findings: 1 High (file count > 10, accepted as indivisible), 2 Medium (type annotations removed from checklist, TC-10 strengthened)
- All findings addressed

### 2026-03-14 23:10 - RED
- Test code created: tests/test-refactor-rebuild.sh (16 TCs)
- 12 tests failing (TC-01~06, 08~13), TC-07 pre-passing, TC-14~16 pending
- Phase completed

### 2026-03-15 00:00 - GREEN
- All 16 files edited to remove /simplify references
- refactor/SKILL.md rewritten with 7-item checklist
- refactor/reference.md expanded with new patterns (unused import, let->const, N+1, naming)
- rg verification: 0 /simplify matches in scope
- All key tests passing (doc-consistency, subagent-delegation, plugin-structure)
- Phase completed

### 2026-03-15 00:05 - REFACTOR
- Checklist review: no changes needed (Markdown + Shell only)
- Phase completed

### 2026-03-15 00:05 - REVIEW
- Codex code review: 1 High (recursive test loop - fixed), 1 Medium (TC-14 scope - fixed)
- All /simplify references confirmed removed (rg verification)
- Cross-references consistent
- Verification Gate and prohibition rules preserved
- 16/16 tests PASS
- review(code) score:25 verdict:PASS
- Phase completed

---

## Next Steps

1. [Done] INIT <- Current
2. [Next] RED
3. [ ] GREEN
4. [ ] REFACTOR
5. [ ] REVIEW
6. [ ] COMMIT
