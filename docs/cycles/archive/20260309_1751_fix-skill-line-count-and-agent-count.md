---
feature: fix-skill-line-count-and-agent-count
cycle: 20260309_1751
phase: DONE
created: 2026-03-09 17:51
updated: 2026-03-09 17:51
---

# Fix: spec/SKILL.md Line Count and CLAUDE.md Agent Count Comments

## Scope Definition

### In Scope
- [ ] Compress spec/SKILL.md Step 4.8 to bring line count to ≤ 100 (Issue A)
- [ ] Update CLAUDE.md agent count comment to match actual agent file count (Issue B)
- [ ] Update CLAUDE.md security agent count comment to match actual count (Issue B)
- [ ] Add TC-B1 and TC-B2 tests to test-skills-structure.sh for agent count verification

### Out of Scope
- Logic changes to any skill or agent behavior (only comment/formatting changes)
- Changes to reference.md or other documentation beyond CLAUDE.md and SKILL.md

### Files to Change (target: 10 or less)
- `skills/spec/SKILL.md` (edit — compress Step 4.8 from 3 lines to 1)
- `CLAUDE.md` (edit — update agent count comments on lines 17 and 27)
- `tests/test-skills-structure.sh` (edit — add TC-B1 and TC-B2)

## Environment

### Scope
- Layer: Meta (dev-crew internal tooling)
- Plugin: dev-crew
- Risk: 5 (PASS)

### Runtime
- Language: Bash (shell scripts), Markdown

### Dependencies (key packages)
- (none — plain Markdown and shell scripts)

### Risk Interview (BLOCK only)
- (not applicable — PASS risk level)

## Context & Dependencies

### Reference Documents
- `skills/spec/SKILL.md` — target file for Issue A fix
- `CLAUDE.md` — target file for Issue B fix
- `tests/test-skills-structure.sh` — existing TC-09, source for new TC-B1/TC-B2
- `skills/spec/reference.md` — Ambiguity Detection details already captured here

### Dependent Features
- (none)

### Related Issues/PRs
- Issue A: TC-09 fails because spec/SKILL.md is 101 lines (max 100)
- Issue B: CLAUDE.md comments claim "33 agents" and "19 security agents" but actual counts differ

## Test List

### TODO
- [ ] TC-A1: spec/SKILL.md must be ≤ 100 lines (existing TC-09 in test-skills-structure.sh — must pass after fix)
- [ ] TC-B1: CLAUDE.md agent count comment matches actual agent .md file count (excluding reference docs)
- [ ] TC-B2: CLAUDE.md security agent count comment matches actual security specialist .md file count

### WIP
(none)

### DISCOVERED
(none)

### DONE
(none)

## Implementation Notes

### Goal
Fix two broken invariants: (1) spec/SKILL.md exceeds 100-line limit causing TC-09 to fail, (2) CLAUDE.md agent count comments are stale and do not reflect the actual file counts.

### Background
- Issue A: spec/SKILL.md is 101 lines. The 100-line limit is enforced by TC-09 in test-skills-structure.sh. Step 4.8 (Ambiguity Detection) has 3 content lines that can be compressed to 1 since details already live in reference.md.
- Issue B: CLAUDE.md line 17 says "33 agents (flat)" and line 27 says "19 security agents". Actual count: 32 agent files (false-positive-filter-reference.md is a reference doc, not an agent). Security specialist count needs to be verified against actual files before updating.

### Design Approach
- Issue A: Inline-compress Step 4.8 in spec/SKILL.md to a single line (consistent with the progressive disclosure pattern used elsewhere in the file).
- Issue B: Count actual agent .md files and security specialist .md files programmatically, then update the two comment strings in CLAUDE.md to match. TC-B1 and TC-B2 enforce this going forward so the counts cannot silently drift again.
- Test approach: TC-B1/TC-B2 use shell `ls | grep | wc -l` to count actual files, then grep CLAUDE.md for the count string — making the tests self-verifying against the filesystem.

**WARN noted by architect**: The plan asserts 18 security specialists, but filesystem inspection shows 19 files matching the security-specialist pattern (including attack-scenario.md, dynamic-verifier.md, false-positive-filter.md, etc.). TC-B2 implementation must count actual files first and use that count as the expected value — do not hardcode 18.

## Progress Log

### 2026-03-09 17:51 - KICKOFF
- Cycle doc created
- Design Review Gate: WARN (score ~30) — plan's security agent count assertion (18) may differ from actual; TC-B2 must derive expected count from filesystem, not hardcode
- Scope definition ready

### 2026-03-09 17:54 - RED
- TC-B1 and TC-B2 added to tests/test-skills-structure.sh
- All 3 tests confirmed FAILING: TC-09 (101 lines), TC-B1 (33 vs 32), TC-B2 (19 vs 18)
- Tests derive counts from filesystem (no hardcoded values)

### 2026-03-09 17:56 - GREEN
- spec/SKILL.md compressed to 99 lines (was 101)
- CLAUDE.md agent counts updated: 32 agents, 18 security agents
- All 39 test files pass (0 failures)

### 2026-03-09 17:57 - REVIEW
- Risk: LOW (score 0)
- security-reviewer: PASS (0), correctness-reviewer: PASS (5)
- Max score: 5 → PASS
- No DISCOVERED items

---

## Next Steps

1. [Done] KICKOFF
2. [Done] RED
3. [Done] GREEN
4. [Skip] REFACTOR (trivial change)
5. [Done] REVIEW (PASS, score 5)
6. [Next] COMMIT
