# dev-crew

AI development team as a single Claude Code plugin.

## Start Here

1. Read [CONSTITUTION.md](CONSTITUTION.md) for principles and [docs/workflow.md](docs/workflow.md) for development flow
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

## TDD Workflow

```
spec → sync-plan → plan-review → orchestrate(RED → GREEN → REFACTOR → REVIEW → COMMIT)
```

Cycle docs: `docs/cycles/YYYYMMDD_HHMM_<topic>.md`

### Post-Approve Action

Plan mode を抜けたら、直接実装に入らず以下を順に実行する:

1. Plan mode を抜けたら、Cycle Doc に内容をコピーする (`dev-crew:sync-plan`)
   - Cycle Doc なしの実装は `pre-red-gate.sh` でブロックされる
2. Cycle Doc をレビューする (`dev-crew:review --plan`)
   - BLOCK 判定なら Plan に戻る
3. レビュー通過後、実装フローを回す (`dev-crew:orchestrate`)
   - RED → GREEN → REFACTOR → REVIEW → COMMIT を自律管理
   - PASS/WARN → 自動進行、BLOCK → 再試行 → ユーザー報告
   - COMMIT 前に `pre-commit-gate.sh` で REVIEW 完了を検証

## Quality Standards

| Metric | Target |
|--------|--------|
| Test coverage | 90%+ (min 80%) |
| Static analysis | 0 errors |
| Test design | Given/When/Then |
| SKILL.md | < 100 lines |

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
├── agents/          # 40 agents (flat), 21 security agents
├── skills/          # Skills (each: SKILL.md + reference.md)
├── scripts/gates/   # Deterministic gate scripts (pre-red, pre-commit)
├── rules/           # Always-applied rules (git-safety, security, git-conventions)
├── tests/           # Shell test scripts
└── docs/            # See docs/README.md
    └── decisions/   # Architecture decisions (ADR)
```

## References

| Topic | Location |
|-------|----------|
| Constitution (principles) | [CONSTITUTION.md](CONSTITUTION.md) |
| Workflow (dev flow) | [docs/workflow.md](docs/workflow.md) |
| Roadmap | [ROADMAP.md](ROADMAP.md) |
| Architecture | [docs/architecture.md](docs/architecture.md) |
| Skills | Plugin system auto-discovery (SKILL.md description) |
| Terminology | [docs/terminology.md](docs/terminology.md) |
| Status | [docs/STATUS.md](docs/STATUS.md) |
