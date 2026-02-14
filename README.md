# dev-crew

AI development team environment for Claude Code. Install once at user level, use across all projects.

## What is this?

A Claude Code plugin collection that provides an autonomous AI development team:

- **PdM** (Product Manager): Orchestrates the entire development workflow
- **Engineer**: TDD-driven implementation (RED/GREEN/REFACTOR)
- **Designer**: UI/UX design support
- **Security Auditor**: OWASP-based vulnerability scanning
- **Reviewers**: Parallel code review (correctness, performance, security, architecture, etc.)

## Installation

```bash
# Install all plugins at user level
/plugin install core@dev-crew
/plugin install php@dev-crew
/plugin install python@dev-crew
/plugin install typescript@dev-crew
/plugin install javascript@dev-crew
/plugin install flask@dev-crew
/plugin install flutter@dev-crew
/plugin install hugo@dev-crew
/plugin install security@dev-crew
/plugin install meta@dev-crew
```

## Core Workflow

```
INIT -> PLAN -> RED -> GREEN -> REFACTOR -> REVIEW -> COMMIT
```

Each phase boundary triggers automatic context compaction to maintain token efficiency across long sessions.

## Token Optimization

dev-crew implements phase-boundary compaction inspired by [OpenClaw](https://github.com/openclaw/openclaw):

1. Phase output is persisted to Cycle doc
2. `/compact` triggers at phase boundary
3. Next phase loads context from Cycle doc (not conversation history)

## Plugin Structure

```
dev-crew/
├── plugins/
│   ├── core/          # PdM orchestration + TDD workflow + reviewers
│   ├── php/           # PHP quality (PHPStan, Pint, PHPUnit)
│   ├── python/        # Python quality (pytest, mypy, Black)
│   ├── typescript/    # TypeScript quality (tsc, ESLint, Jest)
│   ├── javascript/    # JavaScript quality (ESLint, Prettier, Jest)
│   ├── flask/         # Flask quality (pytest-flask, mypy)
│   ├── flutter/       # Flutter quality (dart analyze, flutter test)
│   ├── hugo/          # Hugo quality (hugo build, htmltest)
│   ├── security/      # Security scanning (OWASP Top 10)
│   └── meta/          # Pattern learning and skill evolution
├── scripts/           # Test scripts
└── docs/              # Design docs and cycle docs
```

## License

MIT
