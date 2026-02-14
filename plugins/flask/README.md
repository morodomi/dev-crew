# flask

Flask quality tools for TDD workflow with Claude Code.

## Installation

```bash
/plugin install flask@dev-crew
```

## Requirements

- Python 3.10+
- pytest-flask 1.3.0+
- Flask 2.3+ (Flask 3.x recommended)

## Skills

| Skill | Description |
|-------|-------------|
| flask-quality | Flask quality checks (pytest-flask, mypy, Black) |

## Tools

| Tool | Command |
|------|---------|
| pytest | `pytest` (with pytest-flask) |
| mypy | `mypy --strict` |
| Black | `black .` |
| isort | `isort .` |

## Flask-specific Features

- **pytest-flask** fixtures (client, app, app_context)
- **App Factory Pattern** support
- Session and authentication testing patterns

## Usage with Core Plugin

```bash
/plugin install core@dev-crew
/plugin install flask@dev-crew
```

See `flask-quality` skill for detailed usage and examples.
