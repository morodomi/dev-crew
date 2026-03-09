---
feature: red-skill-complexity-fast-path
cycle: 20260309_1803
phase: DONE
created: 2026-03-09 18:03
updated: 2026-03-09 18:03
---

# Add complexity-based fast-path to RED skill

## Scope Definition

### In Scope
- [ ] Add complexity gate section to `skills/red/SKILL.md` (~8 lines)
- [ ] Add classification criteria, escalation conditions, and rationale to `skills/red/reference.md`

### Out of Scope
- Changing RED skill runtime behavior beyond gate logic (Reason: behavior change is SKILL.md-driven)
- Modifying red-worker agent (Reason: worker receives tasks after gate; no change needed)

### Files to Change (target: 10 or less)
- `skills/red/SKILL.md` (edit)
- `skills/red/reference.md` (edit)

## Environment

### Scope
- Layer: N/A (Markdown skill definition)
- Plugin: dev-crew
- Risk: 35 (WARN — frequently-used skill, behavior change)

### Runtime
- Language: N/A (Markdown + shell test scripts)

### Dependencies (key packages)
- N/A

### Risk Interview (BLOCK only)
- N/A (WARN level, not BLOCK)

## Context & Dependencies

### Reference Documents
- `skills/red/SKILL.md` — current 3-stage workflow definition
- `skills/red/reference.md` — detailed stage documentation
- `tests/test-skills-structure.sh` — enforces SKILL.md ≤ 100 lines (TC-09)

### Dependent Features
- red-worker agent: downstream receiver of gate output (unaffected)
- orchestrate skill: drives RED phase invocation (unaffected)

### Related Issues/PRs
- N/A

## Test List

### TODO
- [ ] TC-R1: Given trivial complexity (1-2 items, Example only, no escalation), SKILL.md specifies Stage 2 skip
- [ ] TC-R2: Given standard complexity (3-5 items, Example only), SKILL.md specifies Stage 2 Review skip
- [ ] TC-R3: Given complex complexity (6+ items OR non-Example paradigm), SKILL.md specifies full 3-stage
- [ ] TC-R4: Given trivial item count (2) + Property paradigm → escalates to complex
- [ ] TC-R5: Given standard item count (4) + external I/O → stays at standard (not demoted to trivial)
- [ ] TC-R6: SKILL.md must remain ≤ 100 lines after adding fast-path gate

### WIP
(none)

### DISCOVERED
(none)

### DONE
(none)

## Implementation Notes

### Goal
Reduce RED phase ceremony cost for simple changes. High-frequency skill usage means even small per-invocation savings compound significantly across a project lifecycle.

### Background
The current RED skill always runs the full 3-stage ceremony:
1. Stage 1: Test Plan (Given/When/Then expansion)
2. Stage 2: Test Plan Review (gap analysis, paradigm check)
3. Stage 3: Test Code (red-worker parallel execution)

For trivial changes (1-2 test items, pure Example paradigm, no escalation triggers), Stage 2 is ceremonial overhead with no incremental safety benefit. The fast-path is a "requirement relaxation" — the thinking trace is still produced, just in a lighter form.

### Design Approach

**Complexity classification** (evaluated at RED entry):

| Class | Criteria | Stages |
|-------|----------|--------|
| trivial | 1-2 Test List items, Example paradigm only, no escalation triggers | Stage 1 as 1-line GWT comment in test header; Stage 2 skipped; Stage 3 |
| standard | 3-5 items, Example paradigm only | Stage 1 simplified; Stage 2 Review skipped; Stage 3 |
| complex | 6+ items OR any non-Example paradigm | Full 3-stage (unchanged) |

**Escalation conditions** (auto-upgrade regardless of item count):
- External I/O dependency → standard or above
- Async/concurrency → standard or above
- State transitions → complex
- Property/Metamorphic paradigm → complex

**Key principle**: Fast-path is "requirement relaxation", not "omission". Thinking traces must always be preserved.

SKILL.md change: Add a `### Complexity Gate` subsection (~8 lines) before Stage 1, referencing classification details in reference.md.

reference.md change: Add `## Complexity Classification` section with the table, escalation conditions, and rationale.

## Progress Log

### 2026-03-09 18:03 - KICKOFF
- Cycle doc created from inline plan context
- Design Review Gate: PASS (score 15/100) — architect pre-review completed
- Scope: 2 files (SKILL.md, reference.md), 6 test cases
- Phase completed

### 2026-03-09 18:07 - RED
- Created tests/test-red-complexity-gate.sh with 6 test cases
- 5/6 tests failing (TC-R6 already passing as expected)

### 2026-03-09 18:09 - GREEN
- Added Complexity Gate table to skills/red/SKILL.md (59 lines, +10)
- Added Complexity Classification section to skills/red/reference.md (+25 lines)
- All 6 tests pass, all existing tests still pass

---

## Next Steps

1. [Done] KICKOFF
2. [Done] RED
3. [Done] GREEN
4. [Skip] REFACTOR
5. [WIP] REVIEW
6. [ ] COMMIT
