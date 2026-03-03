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
│   ├── architect.md       # KICKOFF phase (plan→Cycle doc)
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
│   ├── init/              # TDD context + Ambiguity Detection (plan mode)
│   ├── kickoff/           # Plan file → Cycle doc
│   ├── red/               # Test Plan → Review → Code (Stage 1-3)
│   ├── green/             # Minimal implementation
│   ├── refactor/          # /simplify delegation + Verification Gate
│   ├── review/            # Quality check
│   ├── commit/            # Git commit
│   ├── orchestrate/       # PdM orchestration (plan mode起点)
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
plan mode (常にここから開始)
  ├─ init: TDDコンテキスト + 仕様曖昧性検出（Questioning Protocol）
  ├─ 探索・設計
  ├─ Test List定義
  └─ QAチェック
  ↓ approve → auto-compact

normal mode (実行フェーズ)
  ├─ kickoff: planファイル → Cycle doc生成
  ├─ red: テスト計画検証 + 失敗テスト作成（Stage 1-3）
  ├─ green: 最小実装
  ├─ /simplify: コード品質改善（refactorスキルが委譲）
  ├─ review: リスクベースコードレビュー
  └─ commit: Git commit + auto-learn
```

Claude Code組み込み機能との連携:
- plan mode: init + 設計をplanファイルに集約
- /simplify: refactorスキルが実行を委譲
- /compact: phase-compactスキルがCycle doc更新後に案内

## Token Optimization

Phase-boundary compaction:
- Phase output persisted to Cycle doc before compaction
- Context restored from files, not conversation history
- plan mode → approve → auto-compact で自然なコンテキスト圧縮

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
| init | "start", "new feature" | INIT (plan mode) |
| kickoff | "kickoff" | KICKOFF |
| red | "write test", "red" | RED |
| green | "implement", "green" | GREEN |
| refactor | "refactor" | REFACTOR (/simplify委譲) |
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
| 小〜中規模 | plan mode → accept edits on | init(plan mode) → kickoff → red → green → /simplify → review → commit |
| 中規模 + 圧縮 | plan mode → accept edits on | phase-compact → /compact → /reload を各フェーズ間で |
| 大規模 (自動) | plan mode → accept edits on (AGENT_TEAMS=1) | init → orchestrate（Task()で自動分離）|
| セッション再開 | accept edits on | /reload → 現在フェーズから継続 |
| auto-learn 有効 | accept edits on (DEV_CREW_AUTO_LEARN=1) | commit 後に自動で learn 実行 (20件以上の観測時) |
