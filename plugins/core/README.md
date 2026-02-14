# core

Language-agnostic TDD workflow skills for Claude Code.

## Installation

```bash
/plugin install core@dev-crew
```

## Skills

| Skill | Description |
|-------|-------------|
| init | Start new TDD cycle, create Cycle doc |
| plan | Design implementation plan |
| red | Write failing tests |
| green | Minimal implementation to pass tests |
| refactor | Improve code quality |
| review | Quality checks (test, lint, coverage, quality-gate) |
| commit | Git commit |
| quality-gate | 4-agent parallel code review with confidence scoring |
| plan-review | 3-agent parallel design review |

## Agents

Review agents for quality-gate and plan-review:

| Agent | Focus |
|-------|-------|
| correctness-reviewer | Logic errors, edge cases, exception handling |
| performance-reviewer | Algorithm efficiency, N+1, memory usage |
| security-reviewer | Input validation, auth, SQLi/XSS |
| guidelines-reviewer | Coding standards, naming conventions |
| scope-reviewer | Scope validity, file count |
| architecture-reviewer | Design consistency, patterns |
| risk-reviewer | Impact analysis, breaking changes |

## Workflow

```
INIT → PLAN → RED → GREEN → REFACTOR → REVIEW → COMMIT
```

## Confidence Scoring

quality-gate and plan-review use confidence scores:

| Score | Result | Action |
|-------|--------|--------|
| 80-100 | BLOCK | Must fix before proceeding |
| 50-79 | WARN | Warning, can continue |
| 0-49 | PASS | No issues |

## Usage with Language Plugins

Combine with language-specific plugins:

```bash
# PHP development
/plugin install core@dev-crew
/plugin install php@dev-crew

# Python development
/plugin install core@dev-crew
/plugin install python@dev-crew
```
