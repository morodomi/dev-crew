# ts

TypeScript quality tools for TDD workflow with Claude Code.

## Installation

```bash
/plugin install ts@dev-crew
```

## Skills

| Skill | Description |
|-------|-------------|
| ts-quality | TypeScript quality checks (tsc, ESLint, Prettier, Jest/Vitest) |

## Tools

| Tool | Command |
|------|---------|
| Type Check | `npx tsc --noEmit` |
| ESLint | `npx eslint .` |
| Prettier | `npx prettier --check .` |
| Jest | `npx jest` |
| Vitest | `npx vitest run` |

## Difference from js

| Feature | js | ts |
|---------|--------|--------|
| Type Check | - | `tsc --noEmit` |
| ESLint | Basic rules | `@typescript-eslint` |
| strict mode | - | Recommended |

## Usage with Core Plugin

Combine with core for full TDD workflow:

```bash
/plugin install core@dev-crew
/plugin install ts@dev-crew
```
