# dev-crew

AI development team as a single Claude Code plugin.

> docs are in migration. [docs/PHILOSOPHY.md](docs/PHILOSOPHY.md) is authoritative when other docs disagree.

## Start Here

1. Read [docs/PHILOSOPHY.md](docs/PHILOSOPHY.md) for target workflow
2. Check [docs/STATUS.md](docs/STATUS.md) and `docs/cycles/` for active work
3. If an `IN_PROGRESS` cycle exists, continue it; otherwise start with `spec`

## Tech Stack

- **Target Languages**: PHP, Python, TypeScript, JavaScript, Flutter, Hugo
- **Security**: OWASP Top 10, CWE Top 25

## Quick Start

```bash
# Run all structure validation tests
for f in tests/test-*.sh; do bash "$f"; done

# Run a specific test
bash tests/test-plugin-structure.sh
```

## Key Constraints

| Constraint | Rule |
|-----------|------|
| SKILL.md | < 100 lines. Detail goes in reference.md (Progressive Disclosure) |
| Agents | Markdown with YAML frontmatter (name, description, model) |
| Cycle docs | `docs/cycles/YYYYMMDD_HHMM_description.md` |
| Git | `<type>: <subject>` (feat/fix/docs/refactor/test/chore) |
| Tests | All changes require passing tests before commit |

## Structure

```
dev-crew/
├── agents/          # Agents (flat markdown)
├── skills/          # Skills (each: SKILL.md + reference.md)
├── rules/           # Always-applied rules (git-safety, security, git-conventions)
├── tests/           # Shell test scripts
└── docs/            # See docs/README.md
```

## References

| Topic | Location |
|-------|----------|
| Philosophy & dev flow | [docs/PHILOSOPHY.md](docs/PHILOSOPHY.md) |
| Roadmap | [docs/ROADMAP.md](docs/ROADMAP.md) |
| Architecture | [docs/architecture.md](docs/architecture.md) |
| Skills | Plugin system auto-discovery (SKILL.md description) |
| Terminology | [docs/terminology.md](docs/terminology.md) |
| Status | [docs/STATUS.md](docs/STATUS.md) |
