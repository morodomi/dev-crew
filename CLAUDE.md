@AGENTS.md

# dev-crew (Claude Code Extensions)

## Distribution

Claude Code Plugin (single plugin, user-level install)

## Claude Code Integration

- plan mode: spec + design consolidated in plan file
- /simplify: refactor skill delegates execution
- /compact: phase-compact skill updates Cycle doc before compaction

**Auto-orchestrate after plan approve**: The `## Post-Approve Action` section in plan files persists in compressed context after compact. This triggers /orchestrate automatically after compact + accept edits on transition. orchestrate manages kickoff→RED→GREEN→REFACTOR→REVIEW→COMMIT. (Note: This CLAUDE.md is only loaded within the plugin directory, so Post-Approve Action in plan files is the sole trigger in other projects)

## Token Optimization

Phase-boundary compaction:
- Phase output persisted to Cycle doc before compaction
- Context restored from files, not conversation history
- plan approve → compact + accept edits on → auto-orchestrate

## Hooks

| Event | Matcher | Script | Purpose |
|-------|---------|--------|---------|
| PostToolUse | Edit\|Write\|Bash | `scripts/hooks/observe.sh` | Logs tool usage patterns for learn skill |
| PreCompact | manual | `scripts/hooks/pre-compact.sh` | Persists phase summary before /compact |

## SKILL.md Convention

- SKILL.md < 100 lines (Progressive Disclosure to reference.md)

## Skills (Trigger Keywords)

| Skill | Trigger | Phase |
|-------|---------|-------|
| spec | "spec", "new feature" | SPEC (plan mode) |
| kickoff | "kickoff" | KICKOFF (+ optional Codex debate) |
| red | "write test", "red" | RED |
| green | "implement", "green" | GREEN |
| refactor | "refactor" | REFACTOR (/simplify delegation) |
| review | "review" | REVIEW |
| commit | "commit" | COMMIT |
| orchestrate | (auto from spec) | META (Codex委譲対応) |
| phase-compact | (auto between phases) | META |
| reload | "reload" | META |
| strategy | "strategy" | PHASE A |
| diagnose | "investigate", "diagnose" | SPECIAL |
| security-scan | "security scan" | SECURITY |
| learn | "learn", "extract patterns" | META |
| evolve | "evolve", "skill evolution" | META |
| onboard | "onboard", "setup" | SETUP |
| parallel | "parallel", "cross-layer" | SPECIAL |
| attack-report | "attack report" | SECURITY |
| security-audit | "security audit" | SECURITY |
| context-review | "context review" | META |
| generate-e2e | "generate e2e" | TEST |
| skill-maker | "skill maker", "new skill" | META |
| sync-skills | "sync-skills", "skill sync" | SETUP |
| *-quality (7) | (auto per language) | QUALITY |

## Usage Patterns

| Scenario | Mode | Context Management |
|---------|--------|------------|
| Task search | plan mode | search-task → strategy |
| Small-Medium | plan mode → accept edits on | spec → review --plan → approve → auto-orchestrate |
| Medium + compact | plan mode → accept edits on | phase-compact → /compact → /reload between phases |
| Large (auto) | plan mode → accept edits on (AGENT_TEAMS=1) | spec → orchestrate (Task() for isolation) |
| Session resume | accept edits on | /reload → continue from current phase |
| auto-learn | accept edits on (DEV_CREW_AUTO_LEARN=1) | auto learn after commit (20+ observations) |
