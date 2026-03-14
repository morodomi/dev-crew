# Terminology

Source of truth for naming conventions in dev-crew.

## Naming Layers

| Layer | Convention | Examples |
|-------|-----------|----------|
| Phase names | UPPERCASE | SPEC, RED, GREEN, REFACTOR, REVIEW, COMMIT, DONE |
| Skill names | lowercase | spec, red, green, refactor, review, commit |
| Agent names | lowercase | sync-plan, architect, red-worker, green-worker, etc. |
| Claude Code built-in commands | slash-prefixed | /compact, /plan |

## Canonical Rules

### refactor

- `refactor` is the **skill name** and **phase name** (REFACTOR)
- Implementation: checklist-driven independent logic (no external dependency)
- In workflow diagrams and documentation, use `refactor` (the skill/phase)

### Phase vs Skill

A phase is a step in the TDD cycle (UPPERCASE). A skill is the implementation that executes a phase (lowercase). They share the same name but differ in capitalization and context:

- "The REFACTOR phase" = the step in the workflow
- "Run the refactor skill" = the command that executes it

## Language Policy

| Context | Language | Rationale |
|---------|----------|-----------|
| README.md, docs/ | English | Repository-facing, international readability |
| CLAUDE.md | English + Japanese | Operator guidance; Japanese for workflow context |
| SKILL.md description (frontmatter) | Japanese allowed | Bilingual trigger support for Claude Code |
| SKILL.md body | Either | Keep concise; match existing convention per file |
| agents/*.md | English | Agent definitions are structural |
| rules/*.md | English | Rules are structural |
