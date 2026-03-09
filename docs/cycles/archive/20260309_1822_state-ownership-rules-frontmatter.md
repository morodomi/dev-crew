---
feature: state-ownership-rules-frontmatter
cycle: 20260309_1822
phase: DONE
complexity: standard
test_count: 6
risk_level: low
created: 2026-03-09 18:22
updated: 2026-03-09 18:22
---

# State ownership rules + Cycle doc frontmatter enrichment

## Scope Definition

### In Scope
- [ ] Create `rules/state-ownership.md` (new, ~35 lines) defining plan file immutability, Cycle doc append-only rule, and frontmatter update permissions table
- [ ] Enrich `skills/spec/templates/cycle.md` frontmatter with `complexity`, `test_count`, `risk_level` fields
- [ ] Update `skills/kickoff/reference.md` with frontmatter initialization instructions

### Out of Scope
- Runtime enforcement of ownership rules (Reason: convention-based, not code-enforced)
- Changes to other agents or skills beyond kickoff reference (Reason: YAGNI)

### Files to Change (target: 10 or less)
- `rules/state-ownership.md` (new)
- `skills/spec/templates/cycle.md` (edit)
- `skills/kickoff/reference.md` (edit)

## Environment

### Scope
- Layer: N/A (Markdown rule files + templates)
- Plugin: dev-crew
- Risk: 15 (PASS)

### Runtime
- Language: N/A (Markdown only)

### Dependencies (key packages)
- None

### Risk Interview (BLOCK only)
- N/A

## Context & Dependencies

### Reference Documents
- `skills/spec/templates/cycle.md` - current cycle doc template being enriched
- `skills/kickoff/reference.md` - kickoff instructions being updated
- `rules/git-safety.md` - existing rule file as structural reference

### Dependent Features
- RED fast-path (complexity field in frontmatter used by red skill)

### Related Issues/PRs
- Cycle 20260309_1803: red-skill-complexity-fast-path (consumer of complexity field)

## Test List

### TODO
- [ ] TC-S1: rules/state-ownership.md exists and contains plan file immutability rule
- [ ] TC-S2: rules/state-ownership.md contains Cycle doc append-only rule
- [ ] TC-S3: rules/state-ownership.md contains frontmatter update permissions table
- [ ] TC-S4: Cycle doc template contains complexity field in frontmatter
- [ ] TC-S5: Cycle doc template contains test_count field in frontmatter
- [ ] TC-S6: Cycle doc template contains risk_level field in frontmatter

### WIP
(none)

### DISCOVERED
(none)

### DONE
(none)

## Implementation Notes

### Goal
Define clear state ownership rules to resolve ambiguity about who owns which state and when. Enrich Cycle doc frontmatter to provide machine-readable contracts for agents (especially RED fast-path).

### Background
GPT review identified "weak machine-readable contracts" as root cause of design debt. State source of truth is unclear: plan files, Cycle docs, and source files each have different ownership semantics that are currently implicit.

### Design Approach

**(A) rules/state-ownership.md** — new file defining three ownership domains:
1. Plan file: IMMUTABLE after approve
2. Cycle doc: APPEND-ONLY log + structured frontmatter (field-level permissions per phase)
3. Source files: SINGLE SOURCE OF TRUTH

**(B) Cycle doc frontmatter enrichment** — add to template:
```yaml
complexity: trivial|standard|complex  # used by RED fast-path
test_count: N
risk_level: low|medium|high
```

**(C) Frontmatter update permissions** (in state-ownership.md):
| Phase | Permitted frontmatter changes |
|-------|-------------------------------|
| kickoff | initialize all fields |
| red | update complexity, test_count |
| green | update phase only |
| review | body log only (no frontmatter) |

## Progress Log

### 2026-03-09 18:22 - KICKOFF
- Cycle doc created from plan context
- Design Review Gate: PASS (score: 15, pre-reviewed by architect)
- Phase completed

---

## Next Steps

1. [Done] KICKOFF <- Current
2. [Next] RED
3. [ ] GREEN
4. [ ] REFACTOR
5. [ ] REVIEW
6. [ ] COMMIT
