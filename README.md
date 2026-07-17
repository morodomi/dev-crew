# dev-crew

> **No external support.** This repository is developed for personal use and published as-is for reference. No issues, PRs, or feature requests will be addressed.

AI development team environment for Claude Code. Install once, use across all projects.

## What is this?

A single Claude Code plugin that provides an autonomous AI development team:

- **PdM** (Product Manager): Orchestrates the entire development workflow
- **Engineer**: TDD-driven implementation (RED/GREEN/REFACTOR)
- **Designer**: UI/UX design support (Japanese/Western pattern comparison)
- **Security Auditor**: OWASP-based vulnerability scanning
- **Reviewers**: Parallel code review (correctness, performance, security, architecture, etc.)
- **Meta Learner**: Session pattern extraction and skill evolution

## Philosophy

> Human laziness as a design principle.

AI generates 90% correct code. The remaining 10% is caught by tests, multi-perspective reviews, and static analysis. Humans only provide goals and approve/reject at key gates. See [CONSTITUTION.md](CONSTITUTION.md).

### Claude + Codex Integration

Claude and Codex have different personalities. dev-crew uses that as a feature:

| AI | Role | Personality |
|----|------|-------------|
| Claude | Planner/Orchestrator | Agreeable, lenient reviews |
| Codex | Implementer/Reviewer | Blunt, thorough reviews |

When Codex is available, Plan Review and Code Review always run competitively (Claude + Codex). RED/GREEN delegation is user's choice (`full`: Codex, `no`: Claude). When Codex is unavailable, Claude handles everything (fallback).

## Installation

```bash
/plugin marketplace add morodomi/dev-crew
/plugin install dev-crew@dev-crew
```

## Quick Start

1. Enter plan mode
2. `spec: <your task>` (e.g. "spec: add input validation to the login form")
3. Plan review runs automatically (Claude design review + Codex, if available) — findings are reflected before you approve
4. Approve the design
5. Orchestrate runs automatically (sync-plan → RED → GREEN → REFACTOR → REVIEW → COMMIT)

## Core Workflow

```
spec (design phase)
  plan mode → Ambiguity Detection → explore → design → Test List → QA
  → Claude plan-review → (Codex plan-review, if available; findings reflected, re-reviewed once)
  → approve → sync-plan (Cycle doc, Plan Review Record transferred) → (Codex delegation: full/no)

RED → GREEN → REFACTOR → REVIEW → COMMIT (execution phase)
```

Integrates with Claude Code built-in features (plan mode, /compact),
performing automatic context compaction at each phase boundary.

## Usage Example

```
You: "spec: add input validation to the login form"
     → Claude enters plan mode, runs Ambiguity Detection,
       asks clarifying questions, builds a Test List
     → Claude reviews the plan
     → Codex reviews the plan (if available), findings are resolved before approval

You: approve the plan (exits plan mode)
     → /orchestrate auto-starts (a single entry point — sync-plan, architect,
       and the delegation-mode question all happen internally, not as separate
       manual steps before orchestrate runs): sync-plan (Cycle doc, Plan Review
       Record transferred) → architect (Design Review Gate + Post-Transfer
       Verification) → Choose Codex delegation for RED/GREEN (full/no)
     → orchestrate continues: RED → GREEN → REFACTOR → REVIEW → cycle-retrospective → COMMIT
     → Each phase delegated to specialist agents (Codex or Claude workers)
     → Competitive review (Claude + Codex) at REVIEW phase
     → Findings summary shown after commit
```

Each phase boundary persists output to the Cycle doc and triggers context
compaction, so long sessions stay within the context window.

## Structure

```
dev-crew/
├── .claude-plugin/plugin.json   # Single plugin
├── agents/                      # 40 agents
├── skills/                      # 28 skills
├── rules/                       # Git safety, conventions, security
├── hooks/hooks.json             # Phase-boundary compaction hooks
├── scripts/hooks/               # Shell scripts for hooks
├── tests/                       # Structure validation
└── docs/                        # See docs/README.md
```

## Skills

### Development Workflow (13)
spec, red, green, refactor, review, commit, orchestrate, diagnose, onboard, sync-skills, skill-maker, cycle-retrospective, codify-insight

### Security (5)
security-scan, attack-report, context-review, generate-e2e, security-audit

### Language Quality (7)
php-quality, python-quality, ts-quality, js-quality, flask-quality, flutter-quality, hugo-quality

### Meta (3)
learn, evolve, careful

## Background Reading (Japanese)

- [暴走するAIを飼い慣らすまで9ヶ月。dev-crewを公開する](https://note.com/morodomi/n/ne40fb866f9c6)
- [10個の自作スキルを捨ててClaude Codeのデフォルトに戻した](https://note.com/morodomi/n/nd960ef99d0f3)
- [コンテキストウィンドウは制約じゃない。フェーズの区切りだ](https://note.com/morodomi/n/n55b4b658e80e)
- [typo修正に4人のレビュアーは要らない。リスクベースレビューの設計](https://note.com/morodomi/n/n00074c4f1d1e)
- [AIにセキュリティレビューさせるなら、防御側ではなく攻撃側をやらせろ](https://note.com/morodomi/n/n99f7722c2e99)

## License

MIT
