# python

Python quality tools for TDD workflow with Claude Code.

## Installation

```bash
/plugin install python@dev-crew
```

## Skills

| Skill | Description |
|-------|-------------|
| python-quality | Python quality checks (pytest, mypy, Black) |

## Tools

| Tool | Command |
|------|---------|
| pytest | `pytest` |
| mypy | `mypy --strict` |
| Black | `black .` |
| isort | `isort .` |
| ruff | `ruff check .` |

## Usage with Core Plugin

Combine with core for full TDD workflow:

```bash
/plugin install core@dev-crew
/plugin install python@dev-crew
```
