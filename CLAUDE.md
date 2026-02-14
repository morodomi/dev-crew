# dev-crew

AI development team environment as Claude Code Plugins.

## Tech Stack

- **Distribution**: Claude Code Plugins
- **Target Languages**: PHP, Python, TypeScript, JavaScript, Flutter, Hugo
- **Quality Tools**: Language-specific (see each plugin)
- **Security**: OWASP Top 10, CWE Top 25

## Project Structure

```
dev-crew/
├── plugins/
│   ├── core/              # PdM + TDD workflow + review agents
│   │   ├── agents/        # pdm, engineer, designer, reviewers
│   │   └── skills/        # init, plan, red, green, refactor, review, commit, orchestrate, phase-compact
│   ├── php/               # PHPStan, Pint, PHPUnit
│   ├── python/            # pytest, mypy, Black
│   ├── typescript/        # tsc, ESLint, Jest
│   ├── javascript/        # ESLint, Prettier, Jest
│   ├── flask/             # pytest-flask, mypy
│   ├── flutter/           # dart analyze, flutter test
│   ├── hugo/              # hugo build, htmltest
│   ├── security/          # OWASP security scanning
│   └── meta/              # Pattern learning, skill evolution
├── scripts/               # Structure validation tests
└── docs/                  # Design docs, cycle docs
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

## Plugin Architecture

Each plugin is self-contained:
```
plugin-name/
├── .claude-plugin/
│   └── plugin.json
├── agents/          # Optional: agent definitions (.md)
├── skills/
│   └── skill-name/
│       ├── SKILL.md       # < 100 lines
│       └── reference.md   # Detailed reference
└── README.md
```

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

## Test Commands

```bash
bash scripts/test-plugins-structure.sh
```
