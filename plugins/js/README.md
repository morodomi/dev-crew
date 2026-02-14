# js

JavaScript quality tools for TDD workflow with Claude Code.

## Installation

```bash
/plugin install js@dev-crew
```

## Skills

| Skill | Description |
|-------|-------------|
| js-quality | JavaScript quality checks (ESLint, Prettier, Jest/Vitest) |

## Tools

| Tool | Command |
|------|---------|
| ESLint | `npx eslint .` |
| Prettier | `npx prettier --check .` |
| Jest | `npx jest` |
| Vitest | `npx vitest run` |

## Usage with Core Plugin

Combine with core for full TDD workflow:

```bash
/plugin install core@dev-crew
/plugin install js@dev-crew
```
