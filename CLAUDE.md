@AGENTS.md

# dev-crew (Claude Code Extensions)

## Claude Code Integration

- plan mode: spec + design consolidated in plan file
- /compact: phase-compact skill updates Cycle doc before compaction

**Auto-orchestrate after plan approve**: The `## Post-Approve Action` section in plan files persists in compressed context after compact. This triggers /orchestrate automatically after compact + accept edits on transition.

## Codex Integration

Codex が利用可能な場合、Plan Review と Code Review は常時 competitive に実行。RED/GREEN の委譲は codex_mode (full/no) で制御。詳細は [docs/PHILOSOPHY.md](docs/PHILOSOPHY.md) 参照。

```bash
# plan review（planファイルに対して実行）
codex exec --full-auto "review plan <planファイルパス>"

# RED/GREEN/REVIEW 委譲（同一セッション継続、--lastでcwdフィルタ）
codex exec resume --last --full-auto "red docs/cycles/xxx.md"
codex exec resume --last --full-auto "green docs/cycles/xxx.md"
codex exec resume --last --full-auto "review code docs/cycles/xxx.md"
```

Codex 不在時は Claude fallback（既存スキルそのまま）。

## Token Optimization

Phase-boundary compaction:
- Phase output persisted to Cycle doc before compaction
- Context restored from files, not conversation history
- plan approve → compact + accept edits on → auto-orchestrate

## Hooks

| Event | Matcher | Script | Purpose |
|-------|---------|--------|---------|
| PostToolUse | Edit\|Write\|Bash | `scripts/hooks/observe.sh` | Logs tool usage patterns for learn skill |
| PreCompact | manual | `scripts/hooks/pre-compact.sh` | Persists phase summary before /compact |

## Usage Patterns

| Scenario | Mode | Context Management |
|---------|--------|------------|
| Task search | plan mode | search-task → strategy |
| Small-Medium | plan mode → accept edits on | spec → approve → sync-plan → plan-review → auto-orchestrate |
| Medium + compact | plan mode → accept edits on | phase-compact → /compact → /reload between phases |
| Large (auto) | plan mode → accept edits on (AGENT_TEAMS=1) | spec → orchestrate (Task() for isolation) |
| Session resume | accept edits on | /reload → continue from current phase |
| auto-learn | accept edits on (DEV_CREW_AUTO_LEARN=1) | auto learn after commit (20+ observations) |
