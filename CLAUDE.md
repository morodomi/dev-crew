# dev-crew

AI development team environment as a single Claude Code Plugin.

## Tech Stack

- **Distribution**: Claude Code Plugin (single plugin, user-level install)
- **Target Languages**: PHP, Python, TypeScript, JavaScript, Flutter, Hugo
- **Security**: OWASP Top 10, CWE Top 25

## Project Structure

```
dev-crew/
├── .claude-plugin/
│   └── plugin.json        # Single plugin metadata
├── agents/                # 34 agents (flat)
│   ├── architect.md       # PLAN phase design
│   ├── red-worker.md      # RED test creation
│   ├── green-worker.md    # GREEN implementation
│   ├── refactorer.md      # REFACTOR quality
│   ├── socrates.md        # Devil's Advocate advisor
│   ├── observer.md        # Pattern detection (meta)
│   ├── *-reviewer.md      # 9 review agents
│   └── *-attacker.md      # 18 security agents
├── skills/                # 26 skills (flat)
│   ├── init/              # Cycle start
│   ├── plan/              # Design + Test List
│   ├── red/               # Failing tests
│   ├── green/             # Minimal implementation
│   ├── refactor/          # Code quality
│   ├── review/            # Quality check
│   ├── commit/            # Git commit
│   ├── orchestrate/       # PdM orchestration
│   ├── plan-review/       # 5-agent design review
│   ├── quality-gate/      # 6-agent code review
│   ├── diagnose/          # Parallel bug investigation
│   ├── parallel/          # Cross-layer parallel dev
│   ├── onboard/           # Project setup
│   ├── security-scan/     # OWASP scanning
│   ├── attack-report/     # Vulnerability report
│   ├── learn/             # Pattern extraction
│   ├── evolve/            # Skill evolution
│   └── *-quality/         # 7 language quality tools
├── rules/                 # Always-applied rules
│   ├── git-safety.md
│   ├── git-conventions.md
│   └── security.md
├── hooks/
│   └── hooks.json         # Auto-loaded hook definitions
├── scripts/
│   └── hooks/             # Shell scripts for hooks
├── tests/                 # Structure validation scripts
└── docs/                  # Design docs + cycle docs
```

## Workflow

```
INIT -> PLAN -> RED -> GREEN -> REFACTOR -> REVIEW -> COMMIT
```

Each phase boundary: persist output -> compact -> load from artifact.

## Token Optimization

Phase-boundary compaction:
- Phase output persisted to Cycle doc before compaction
- Context restored from files, not conversation history
- Inspired by OpenClaw's memory flush pattern

## Quality Standards

| Metric | Target |
|--------|--------|
| Coverage | 90%+ (minimum 80%) |
| Static analysis | 0 errors |
| SKILL.md | < 100 lines |

## Development Rules

1. All changes follow TDD cycle with Cycle doc in `docs/cycles/`
2. SKILL.md < 100 lines (Progressive Disclosure to reference.md)
3. Agents defined as Markdown with specific prompts
4. plugin.json must be valid JSON

## File Naming

- Cycle docs: `docs/cycles/YYYYMMDD_HHMM_description.md`

## Git Conventions

```
<type>: <subject>

feat | fix | docs | refactor | test | chore
```

## Skills (Trigger Keywords)

| Skill | Trigger | Phase |
|-------|---------|-------|
| init | "start", "new feature" | INIT |
| plan | "design", "plan" | PLAN |
| red | "write test", "red" | RED |
| green | "implement", "green" | GREEN |
| refactor | "refactor" | REFACTOR |
| review | "review" | REVIEW |
| commit | "commit" | COMMIT |
| orchestrate | (auto from init) | META |
| phase-compact | (auto between phases) | META |
| plan-review | (auto after plan) | PLAN+1 |
| quality-gate | (auto in review) | REVIEW+1 |
| diagnose | "investigate", "diagnose" | SPECIAL |
| security-scan | "security scan" | SECURITY |
| learn | "learn", "extract patterns" | META |
| evolve | "evolve", "skill evolution" | META |
