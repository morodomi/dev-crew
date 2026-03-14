# dev-crew

AI development team environment as a single plugin.

> Terminology conventions: see [docs/terminology.md](docs/terminology.md)

## Tech Stack

- **Target Languages**: PHP, Python, TypeScript, JavaScript, Flutter, Hugo
- **Security**: OWASP Top 10, CWE Top 25

## Project Structure

```
dev-crew/
├── agents/                # 32 agents (flat)
│   ├── architect.md       # KICKOFF phase (plan→Cycle doc)
│   ├── red-worker.md      # RED test creation
│   ├── green-worker.md    # GREEN implementation
│   ├── refactorer.md      # REFACTOR quality
│   ├── socrates.md        # Devil's Advocate advisor
│   ├── observer.md        # Pattern detection (meta)
│   ├── review-briefer.md  # Review Brief generation (haiku)
│   ├── designer.md        # UI/UX design guidance
│   ├── *-reviewer.md      # 6 review agents
│   └── *-attacker.md +    # 18 security agents
│       security specialists   (attackers, recon, DAST, etc.)
├── skills/                # 29 skills (flat)
│   ├── spec/              # TDD context + Ambiguity Detection
│   ├── kickoff/           # Plan file → Cycle doc (+ Codex debate)
│   ├── red/               # Test Plan → Review → Code (Stage 1-3)
│   ├── green/             # Minimal implementation
│   ├── refactor/          # Code quality improvement
│   ├── review/            # Quality check
│   ├── commit/            # Git commit
│   ├── orchestrate/       # PdM orchestration (+ Codex delegation)
│   ├── strategy/          # Planning phase
│   ├── diagnose/          # Parallel bug investigation
│   ├── parallel/          # Cross-layer parallel dev
│   ├── onboard/           # Project setup
│   ├── security-scan/     # OWASP scanning
│   ├── attack-report/     # Vulnerability report
│   ├── reload/            # Context restore
│   ├── learn/             # Pattern extraction
│   ├── evolve/            # Skill evolution
│   ├── context-review/    # Context integrity check
│   ├── generate-e2e/      # E2E test generation
│   ├── security-audit/    # Security audit report
│   ├── skill-maker/       # Interactive skill builder
│   └── *-quality/         # 7 language quality tools
├── rules/                 # Always-applied rules
│   ├── git-safety.md
│   ├── git-conventions.md
│   └── security.md
├── tests/                 # Structure validation scripts
└── docs/                  # Design docs + cycle docs + decisions (ADR)
```

## Workflow

```
Design phase
  ├─ spec: TDD context + ambiguity detection
  ├─ exploration & design
  ├─ Test List definition
  ├─ QA check
  └─ design review (required before approval)
  ↓ approve

Execution phase
  ├─ kickoff: plan → Cycle doc (+ optional Codex debate)
  ├─ red: test plan verification + failing tests (Stage 1-3)
  ├─ green: minimal implementation
  ├─ refactor: code quality improvement
  ├─ review: risk-based code review
  └─ commit: Git commit
```

## Quality Standards

| Metric | Target |
|--------|--------|
| Coverage | 90%+ (minimum 80%) |
| Static analysis | 0 errors |

## Development Rules

1. All changes follow TDD cycle with Cycle doc in `docs/cycles/`
2. Each skill directory: `SKILL.md` (concise) + `reference.md` (detailed docs)
3. Agents defined as Markdown with YAML frontmatter (name, description, model)

## Tests

50 shell scripts in `tests/`. Run: `bash tests/test-*.sh`
Covers: plugin structure, agent/skill structure, cross-references, TDD enforcement, hooks.

## File Naming

- Cycle docs: `docs/cycles/YYYYMMDD_HHMM_description.md`

## Git Conventions

```
<type>: <subject>

feat | fix | docs | refactor | test | chore
```
