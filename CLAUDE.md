@AGENTS.md

# dev-crew (Claude Code Extensions)

## Claude Code Integration

- plan mode: spec + design consolidated in plan file
- /compact: phase-compact skill updates Cycle doc before compaction

**Auto-orchestrate after plan approve**: plan approve後は必ず sync-plan → plan-review → orchestrate の順序で実行する。`## Post-Approve Action` section が plan file と compressed context に残り、compact後もこの順序を維持する。

**Plan approve トリガー認識**: 以下はすべて plan approve イベントとして扱い、sync-plan から開始する:
- plan mode で Accept を押した場合
- 「Implement the following plan:」でプランが渡された場合
- 「この plan を実行して」等の指示を受けた場合
- plan ファイルに `Post-Approve Action` セクションがある場合
直接実装に入ってはいけない。Cycle doc なしの実装は pre-red-gate.sh でブロックされる。

## Codex Integration

Codex が利用可能な場合、Plan Review と Code Review は常時 competitive に実行。RED/GREEN の委譲は codex_mode (full/no) で制御。REFACTOR は Claude が主担当（Codex fallback）。REVIEW は Claude + Codex competitive。詳細は [CONSTITUTION.md](CONSTITUTION.md) 参照。

```bash
# plan review（planファイルに対して実行）→ session ID を Cycle doc frontmatter codex_session_id に記録
codex exec --full-auto "review plan <planファイルパス>"

# RED/GREEN/REVIEW 委譲（codex_session_id があれば resume <session-id>、なければ resume --last）
codex exec resume <session-id> --full-auto "red docs/cycles/xxx.md"
codex exec resume <session-id> --full-auto "green docs/cycles/xxx.md"
codex exec resume <session-id> --full-auto "review code docs/cycles/xxx.md"
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
| PostToolUse | Skill\|Agent | `~/.claude/hooks/observe-skills.sh` | Logs Skill/Agent usage for prune planning (global hook) |
| PreCompact | manual | `scripts/hooks/pre-compact.sh` | Persists phase summary before /compact |

## Usage Patterns

| Scenario | Mode | Context Management |
|---------|--------|------------|
| Task search | plan mode | search-task → strategy |
| Small-Medium | plan mode → accept edits on | spec → approve → sync-plan → plan-review → compact → auto-orchestrate (gates内包) |
| Medium + compact | plan mode → accept edits on | phase-compact → /compact → /reload between phases |
| Large (auto) | plan mode → accept edits on (AGENT_TEAMS=1) | spec → orchestrate (Task() for isolation) |
| Session resume | accept edits on | /reload → continue from current phase |
| auto-learn | accept edits on (DEV_CREW_AUTO_LEARN=1) | auto learn after commit (20+ observations) |
