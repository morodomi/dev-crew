# dev-crew

AI development team environment for Claude Code. Install once, use across all projects.

## What is this?

A single Claude Code plugin that provides an autonomous AI development team:

- **PdM** (Product Manager): Orchestrates the entire development workflow
- **Engineer**: TDD-driven implementation (RED/GREEN/REFACTOR)
- **Designer**: UI/UX design support (planned)
- **Security Auditor**: OWASP-based vulnerability scanning
- **Reviewers**: Parallel code review (correctness, performance, security, architecture, etc.)
- **Meta Learner**: Session pattern extraction and skill evolution

## Installation

```bash
/plugin install dev-crew
```

One command. All 33 agents, 29 skills, rules, and hooks are available.

## Core Workflow

```
INIT -> PLAN -> RED -> GREEN -> REFACTOR -> REVIEW -> COMMIT
```

Each phase boundary triggers automatic context compaction to maintain token efficiency.

## Token Optimization

Phase-boundary compaction inspired by [OpenClaw](https://github.com/openclaw/openclaw):

1. Phase output persisted to Cycle doc
2. `/compact` triggers at phase boundary
3. Next phase loads context from Cycle doc (not conversation history)

## Structure

```
dev-crew/
├── .claude-plugin/plugin.json   # Single plugin
├── agents/                      # 33 agents
├── skills/                      # 29 skills
├── rules/                       # Git safety, conventions, security
├── hooks/hooks.json             # Phase-boundary compaction hooks
├── scripts/hooks/               # Shell scripts for hooks
├── tests/                       # Structure validation
└── docs/                        # Architecture, design, user stories
```

## Skills

### Development Workflow (14)
init, plan, red, green, refactor, review, commit, orchestrate, strategy, diagnose, parallel, onboard, phase-compact, reload

### Security (5)
security-scan, attack-report, context-review, generate-e2e, security-audit

### Language Quality (7)
php-quality, python-quality, ts-quality, js-quality, flask-quality, flutter-quality, hugo-quality

### Meta/Tooling (3)
learn, evolve, skill-maker

## License

MIT
