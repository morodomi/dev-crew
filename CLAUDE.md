# dev-crew

AI development team environment as a single Claude Code Plugin.

## Tech Stack

- **Distribution**: Claude Code Plugin (single plugin, user-level install)
- **Target Languages**: PHP, Python, TypeScript, JavaScript, Flutter, Hugo
- **Security**: OWASP Top 10, CWE Top 25

## Project Structure

```
dev-crew/
├── .claude-plugin/
│   └── plugin.json        # Single plugin metadata
├── agents/                # 33 agents (flat)
│   ├── architect.md       # PLAN phase design
│   ├── red-worker.md      # RED test creation
│   ├── green-worker.md    # GREEN implementation
│   ├── refactorer.md      # REFACTOR quality
│   ├── socrates.md        # Devil's Advocate advisor
│   ├── observer.md        # Pattern detection (meta)
│   ├── review-briefer.md  # Review Brief generation (haiku)
│   ├── designer.md        # UI/UX design guidance
│   ├── *-reviewer.md      # 6 review agents
│   └── *-attacker.md +    # 19 security agents
│       security specialists   (attackers, recon, DAST, etc.)
├── skills/                # 29 skills (flat)
│   ├── init/              # Cycle start
│   ├── plan/              # Design + Test List
│   ├── red/               # Failing tests
│   ├── green/             # Minimal implementation
│   ├── refactor/          # Code quality
│   ├── review/            # Quality check
│   ├── commit/            # Git commit
│   ├── orchestrate/       # PdM orchestration
│   ├── strategy/          # Phase A: 企画フェーズ
│   ├── diagnose/          # Parallel bug investigation
│   ├── parallel/          # Cross-layer parallel dev
│   ├── onboard/           # Project setup
│   ├── security-scan/     # OWASP scanning
│   ├── attack-report/     # Vulnerability report
│   ├── reload/            # Context restore after compact
│   ├── learn/             # Pattern extraction
│   ├── evolve/            # Skill evolution
│   ├── context-review/    # Context integrity check
│   ├── generate-e2e/      # E2E test generation
│   ├── security-audit/    # Security audit report
│   ├── skill-maker/       # Interactive skill builder
│   └── *-quality/         # 7 language quality tools
├── rules/                 # Always-applied rules
│   ├── git-safety.md
│   ├── git-conventions.md
│   └── security.md
├── hooks/
│   └── hooks.json         # Auto-loaded hook definitions
├── scripts/
│   └── hooks/             # Shell scripts for hooks
├── tests/                 # Structure validation scripts
└── docs/                  # Design docs + cycle docs
```

## Workflow

```
INIT -> PLAN -> RED -> GREEN -> REFACTOR -> REVIEW -> COMMIT
```

Each phase boundary: persist output -> compact -> load from artifact.

## Token Optimization

Phase-boundary compaction:
- Phase output persisted to Cycle doc before compaction
- Context restored from files, not conversation history
- Inspired by OpenClaw's memory flush pattern

## Quality Standards

| Metric | Target |
|--------|--------|
| Coverage | 90%+ (minimum 80%) |
| Static analysis | 0 errors |
| SKILL.md | < 100 lines |

## Development Rules

1. All changes follow TDD cycle with Cycle doc in `docs/cycles/`
2. SKILL.md < 100 lines (Progressive Disclosure to reference.md)
3. Agents defined as Markdown with specific prompts
4. plugin.json must be valid JSON

## File Naming

- Cycle docs: `docs/cycles/YYYYMMDD_HHMM_description.md`

## Git Conventions

```
<type>: <subject>

feat | fix | docs | refactor | test | chore
```

## Skills (Trigger Keywords)

| Skill | Trigger | Phase |
|-------|---------|-------|
| init | "start", "new feature" | INIT |
| plan | "design", "plan" | PLAN |
| red | "write test", "red" | RED |
| green | "implement", "green" | GREEN |
| refactor | "refactor" | REFACTOR |
| review | "review" | REVIEW |
| commit | "commit" | COMMIT |
| orchestrate | (auto from init) | META |
| phase-compact | (auto between phases) | META |
| reload | "reload", "コンテキスト復元" | META |
| strategy | "strategy", "企画" | PHASE A |
| diagnose | "investigate", "diagnose" | SPECIAL |
| security-scan | "security scan" | SECURITY |
| learn | "learn", "extract patterns" | META |
| evolve | "evolve", "skill evolution" | META |
| onboard | "onboard", "setup" | SETUP |
| parallel | "parallel", "cross-layer" | SPECIAL |
| attack-report | "attack report" | SECURITY |
| security-audit | "security audit" | SECURITY |
| context-review | "context review" | META |
| generate-e2e | "generate e2e" | TEST |
| skill-maker | "skill maker", "new skill" | META |
| *-quality (7) | (auto per language) | QUALITY |

## Usage Patterns

| シナリオ | モード | Context管理 |
|---------|--------|------------|
| タスク探し | plan mode | search-task → strategy |
| 小〜中規模 | accept edits on | 手動: init → plan → red → ... |
| 中規模 + 圧縮 | accept edits on | phase-compact → /compact → /reload を各フェーズ間で |
| 大規模 (自動) | accept edits on (AGENT_TEAMS=1) | init → orchestrate（Task()で自動分離）|
| セッション再開 | accept edits on | /reload → 現在フェーズから継続 |
| auto-learn 有効 | accept edits on (DEV_CREW_AUTO_LEARN=1) | commit 後に自動で learn 実行 (20件以上の観測時) |
