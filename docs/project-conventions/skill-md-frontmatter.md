# SKILL.md Frontmatter YAML Rules

## Problem

Codex (OpenAI) loads SKILL.md files and parses the YAML frontmatter.
YAML values containing `:` (colon followed by space) are interpreted as mapping keys, causing parse errors.

### Error Example

```
⚠ /path/to/skills/orchestrate/SKILL.md: invalid YAML: mapping values are not allowed in this
  context at line 2 column 145
```

## Rule

`description` field MUST be quoted when it contains `:` (colon).

### NG

```yaml
---
name: orchestrate
description: sync-plan→RED→GREEN→REFACTOR→REVIEW→COMMITを専門エージェントに委譲・判断する。Manual trigger: 「orchestrate」
---
```

### OK

```yaml
---
name: orchestrate
description: "sync-plan→RED→GREEN→REFACTOR→REVIEW→COMMITを専門エージェントに委譲・判断する。Manual trigger: 「orchestrate」"
---
```

## Scope

All SKILL.md files in `skills/*/SKILL.md`.
Claude Code is tolerant of unquoted colons, but Codex is not.
Always quote to ensure cross-platform compatibility.
