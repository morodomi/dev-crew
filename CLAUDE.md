# dev-crew

AI development team environment as a single Claude Code Plugin.

> Terminology conventions: see [docs/terminology.md](docs/terminology.md)

## Tech Stack

- **Distribution**: Claude Code Plugin (single plugin, user-level install)
- **Target Languages**: PHP, Python, TypeScript, JavaScript, Flutter, Hugo
- **Security**: OWASP Top 10, CWE Top 25

## Project Structure

```
dev-crew/
├── .claude-plugin/
│   └── plugin.json        # Single plugin metadata
├── agents/                # 32 agents (flat)
│   ├── architect.md       # KICKOFF phase (plan→Cycle doc)
│   ├── red-worker.md      # RED test creation
│   ├── green-worker.md    # GREEN implementation
│   ├── refactorer.md      # REFACTOR quality
│   ├── socrates.md        # Devil's Advocate advisor
│   ├── observer.md        # Pattern detection (meta)
│   ├── review-briefer.md  # Review Brief generation (haiku)
│   ├── designer.md        # UI/UX design guidance
│   ├── *-reviewer.md      # 6 review agents
│   └── *-attacker.md +    # 18 security agents
│       security specialists   (attackers, recon, DAST, etc.)
├── skills/                # 29 skills (flat)
│   ├── spec/              # TDD context + Ambiguity Detection (plan mode)
│   ├── kickoff/           # Plan file → Cycle doc
│   ├── red/               # Test Plan → Review → Code (Stage 1-3)
│   ├── green/             # Minimal implementation
│   ├── refactor/          # refactor (delegates to /simplify) + Verification Gate
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
  ├─ spec: TDDコンテキスト + 仕様曖昧性検出（Questioning Protocol）
  ├─ 探索・設計
  ├─ Test List定義
  ├─ QAチェック
  └─ review --plan: 設計レビュー（approve前に必須）
  ↓ approve → "Yes, clear context + auto-accept edits" → compact

normal mode (実行フェーズ - compact直後に自動開始)
  ├─ kickoff: planファイル → Cycle doc生成（orchestrate経由で自動実行）
  ├─ red: テスト計画検証 + 失敗テスト作成（Stage 1-3）
  ├─ green: 最小実装
  ├─ refactor: コード品質改善（内部で/simplifyに委譲）
  ├─ review: リスクベースコードレビュー
  └─ commit: Git commit + auto-learn
```

Claude Code組み込み機能との連携:
- plan mode: spec + 設計をplanファイルに集約
- /simplify: refactorスキルが実行を委譲
- /compact: phase-compactスキルがCycle doc更新後に案内

**plan approve後の自動orchestrate**: planファイルの `## Post-Approve Action` セクションがcompact後の圧縮コンテキストに残る。これを読んでcompact + accept edits on遷移直後に /orchestrate を自動実行する。orchestrateがkickoff→RED→GREEN→REFACTOR→REVIEW→COMMITを自動管理する。（注: このCLAUDE.mdはプラグインディレクトリ内でのみロードされるため、他プロジェクトではplanファイルのPost-Approve Actionが唯一のトリガー）

## Token Optimization

Phase-boundary compaction:
- Phase output persisted to Cycle doc before compaction
- Context restored from files, not conversation history
- plan approve → compact + accept edits on → 自動orchestrate でシームレスに実行フェーズへ

## Hooks

| Event | Matcher | Script | Purpose |
|-------|---------|--------|---------|
| PostToolUse | Edit\|Write\|Bash | `scripts/hooks/observe.sh` | Logs tool usage patterns for learn skill |
| PreCompact | manual | `scripts/hooks/pre-compact.sh` | Persists phase summary before /compact |

## Quality Standards

| Metric | Target |
|--------|--------|
| Coverage | 90%+ (minimum 80%) |
| Static analysis | 0 errors |
| SKILL.md | < 100 lines |

## Development Rules

1. All changes follow TDD cycle with Cycle doc in `docs/cycles/`
2. SKILL.md < 100 lines (Progressive Disclosure to reference.md)
3. Each skill directory: `SKILL.md` (concise) + `reference.md` (detailed docs)
4. Agents defined as Markdown with YAML frontmatter (name, description, model)
5. plugin.json must be valid JSON

## Tests

33 shell scripts in `tests/`. Run: `bash tests/test-*.sh`
Covers: plugin structure, agent/skill structure, cross-references, TDD enforcement, hooks.

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
| spec | "spec", "new feature" | SPEC (plan mode) |
| kickoff | "kickoff" | KICKOFF |
| red | "write test", "red" | RED |
| green | "implement", "green" | GREEN |
| refactor | "refactor" | REFACTOR (/simplify委譲) |
| review | "review" | REVIEW |
| commit | "commit" | COMMIT |
| orchestrate | (auto from spec) | META |
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
| 小〜中規模 | plan mode → accept edits on | spec → review --plan → approve → 自動orchestrate |
| 中規模 + 圧縮 | plan mode → accept edits on | phase-compact → /compact → /reload を各フェーズ間で |
| 大規模 (自動) | plan mode → accept edits on (AGENT_TEAMS=1) | spec → orchestrate（Task()で自動分離）|
| セッション再開 | accept edits on | /reload → 現在フェーズから継続 |
| auto-learn 有効 | accept edits on (DEV_CREW_AUTO_LEARN=1) | commit 後に自動で learn 実行 (20件以上の観測時) |
