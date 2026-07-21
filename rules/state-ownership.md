---
paths:
  - "docs/cycles/**"
---
# State Ownership Rules

Defines who owns which state and when mutations are permitted.

## Source of Truth Domains

### Plan File — mutable before approve, IMMUTABLE after approve

**承認前**: plan is mutable. Codex plan review (spec Step 8, pre-approval) findings are reflected directly into the draft plan — this is the designated reflection target while the plan is unapproved.

**承認後**: Once the plan is approved, the plan file must not be modified.
It is a read-only contract for the rest of the cycle.

### Cycle Doc — APPEND-ONLY log + structured frontmatter

Body text (Progress Log, Test List transitions) is append-only.
Never rewrite or delete existing log entries.
Frontmatter fields may be updated per the permissions table below.

### Source Files — SINGLE SOURCE OF TRUTH for implementation

All implementation decisions are reflected in source files.
Cycle doc records what was done; source files define what is.

## Frontmatter Update Permissions

| Phase | Allowed Updates |
|-------|----------------|
| sync-plan | Initialize all frontmatter fields (feature, phase, complexity, test_count, risk_level, retro_status (= none), created, updated). **転記権限**: transcribes `codex_session_id` / `plan_file` / the `Plan Review (pre-approval)` Progress Log entry from the plan's `## Plan Review Record` into the Cycle doc |
| cycle-retrospective | retro_status (none → captured / none → resolved), updated |
| codify-insight | retro_status (captured → resolved), updated, body ## Codify Decisions section append |
| red | complexity, test_count, phase, updated |
| green | phase, updated |
| refactor | phase, updated |
| review | Body log only (no frontmatter changes except phase, updated) |
| commit | phase (COMMIT→DONE 終端), updated |
