# hugo

Hugo SSG quality tools for TDD workflow with Claude Code.

## Installation

```bash
/plugin install hugo@dev-crew
```

## Skills

| Skill | Description |
|-------|-------------|
| hugo-quality | Hugo quality checks (build, htmltest, template metrics) |

## Tools

| Tool | Command |
|------|---------|
| Hugo Build | `hugo` |
| Hugo Server | `hugo server -D` |
| htmltest | `htmltest` |
| Template Metrics | `hugo --templateMetrics` |

## Usage with Core Plugin

Combine with core for full TDD workflow:

```bash
/plugin install core@dev-crew
/plugin install hugo@dev-crew
```
