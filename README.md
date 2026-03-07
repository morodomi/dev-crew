# dev-crew

> **Not Maintained.** This repository is published as-is for reference. No issues, PRs, or feature requests will be addressed.

AI development team environment for Claude Code. Install once, use across all projects.

## What is this?

A single Claude Code plugin that provides an autonomous AI development team:

- **PdM** (Product Manager): Orchestrates the entire development workflow
- **Engineer**: TDD-driven implementation (RED/GREEN/REFACTOR)
- **Designer**: UI/UX design support (Japanese/Western pattern comparison)
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
plan mode (design phase)
  spec (+ Ambiguity Detection) → explore → design → Test List → QA → approve

normal mode (execution phase)
  kickoff → red (Plan → Review → Code) → green → /simplify → review → commit
```

Integrates with Claude Code built-in features (plan mode, /simplify, /compact),
performing automatic context compaction at each phase boundary.

## Token Optimization

Phase-boundary compaction inspired by [OpenClaw](https://github.com/openclaw/openclaw):

1. Phase output persisted to Cycle doc
2. `/compact` triggers at phase boundary
3. Next phase loads context from Cycle doc (not conversation history)
4. plan mode → approve → auto-compact for natural context compaction

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
spec, kickoff, red, green, refactor, review, commit, orchestrate, strategy, diagnose, parallel, onboard, phase-compact, reload

### Security (5)
security-scan, attack-report, context-review, generate-e2e, security-audit

### Language Quality (7)
php-quality, python-quality, ts-quality, js-quality, flask-quality, flutter-quality, hugo-quality

### Meta/Tooling (3)
learn, evolve, skill-maker

## Background Reading (Japanese)

- [暴走するAIを飼い慣らすまで9ヶ月。dev-crewを公開する](https://note.com/morodomi/n/ne40fb866f9c6)
- [10個の自作スキルを捨ててClaude Codeのデフォルトに戻した](https://note.com/morodomi/n/nd960ef99d0f3)
- [コンテキストウィンドウは制約じゃない。フェーズの区切りだ](https://note.com/morodomi/n/n55b4b658e80e)
- [typo修正に4人のレビュアーは要らない。リスクベースレビューの設計](https://note.com/morodomi/n/n00074c4f1d1e)
- [AIにセキュリティレビューさせるなら、防御側ではなく攻撃側をやらせろ](https://note.com/morodomi/n/n99f7722c2e99)

## License

MIT
