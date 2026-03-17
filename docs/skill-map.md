# Skill Map

> Authority: [CONSTITUTION.md](../CONSTITUTION.md) + [workflow.md](workflow.md) が正。このドキュメントはスキル/エージェント/ゲートの実装リファレンス。
> Counts: [STATUS.md](STATUS.md) 参照。

## TDD Workflow Skills

| Phase | Skill/Gate | Primary | Fallback | Notes |
|-------|-----------|---------|----------|-------|
| 企画 | strategy | Claude | - | |
| 設計 | spec | Claude | - | 曖昧性検出内蔵 |
| plan review | review --plan | Codex | Claude | competitive |
| Cycle doc生成 | sync-plan | Claude | - | agent |
| **pre-red-gate.sh** | **(決定論的)** | **script** | **-** | Cycle doc存在・sync-plan完了・Plan Review記録を検証 |
| テスト作成 | red | Codex | Claude | codex_mode依存 |
| テスト静的解析 | exspec | (tool) | skip | 未インストール時skip |
| 実装 | green | Codex | Claude | codex_mode依存 |
| 品質改善 | refactor | Claude | Codex | |
| レビュー | review | Claude+Codex | Claude | competitive, Risk-gated scaling (v2.4) |
| **pre-commit-gate.sh** | **(決定論的)** | **script** | **-** | REVIEW完了・Codex review記録・STATUS.md同期を検証 |
| コミット | commit | Claude | - | |

## Support Skills

| Category | Skill | Purpose |
|----------|-------|---------|
| Context | phase-compact | Phase境界でCycle docに永続化 |
| Context | reload | compact後のコンテキスト復元 |
| Orchestration | orchestrate | TDDサイクル全体の自律管理 |
| Diagnostic | diagnose | 複雑なバグの並列仮説調査 |
| Diagnostic | parallel | クロスレイヤー並列開発 |
| Setup | onboard | プロジェクトTDD初期化 |
| Setup | skill-maker | スキル作成支援 |
| Setup | sync-skills | Codex用symlinkセットアップ |
| Security | security-scan | 脆弱性検出 |
| Security | security-audit | スキャン+レポート一括 |
| Security | attack-report | レポート生成 |
| Security | context-review | 誤検知確認 |
| Security | generate-e2e | E2Eテスト自動生成 |
| Meta | learn | セッションパターン抽出 |
| Meta | evolve | instinctからスキル自動進化 |
| Language | *-quality | 言語別品質チェック (auto) |

## Review Agent Roster (v2.4)

### Plan Mode

| Agent | Condition | Phase |
|-------|-----------|-------|
| design-reviewer | Always-on | 既存 (16.4 強化) |
| test-reviewer | Always-on | 15.1 新設 + 16.5 Plan統合 |
| security-reviewer | Risk-gated: auth/security | 既存 |
| product-reviewer | Risk-gated: API/user-facing | 既存 |
| performance-reviewer | Risk-gated: DB/perf | 既存 (14.4 強化) |
| usability-reviewer | Risk-gated: UI | 既存 |
| designer | Risk-gated: UI + tech stack | 既存 |
| change-safety-reviewer | Risk-gated: migration/schema | 16.1 新設 |
| impact-reviewer | Risk-gated: wide-change | 16.2 新設 |
| resiliency-reviewer | Risk-gated: external-comm | 16.3 新設 |

### Code Mode

| Agent | Condition | Phase |
|-------|-----------|-------|
| security-reviewer | Always-on | 既存 |
| correctness-reviewer | Always-on | 既存 |
| maintainability-reviewer | Always-on | 14.1 新設 |
| performance-reviewer | Risk-gated: DB/perf | 既存 (14.4 強化) |
| api-contract-reviewer | Risk-gated: API/endpoint | 14.2 新設 |
| observability-reviewer | Risk-gated: error/logging | 14.3 新設 |
| product-reviewer | Risk-gated: API/user-facing | 既存 |
| usability-reviewer | Risk-gated: UI | 既存 |
| test-reviewer | Flags-based: test-file | 15.1 新設 |

### Cross-cutting

| Agent | Role | Phase |
|-------|------|-------|
| review-briefer | Brief 生成 (Haiku) | 既存 |
| socrates | Devil's Advocate (Opus) | 15.3 統合 |
| risk-classifier.sh | 決定論的リスク判定 (11シグナル) | 16.6 拡張 |

## File Placement Map

どのスキルが何をどこに生成するかの一覧。

| スキル | 生成ファイル | レイヤー |
|--------|-------------|---------|
| onboard | AGENTS.md, CLAUDE.md, docs/STATUS.md, docs/README.md, .claude/rules/*, .claude/hooks/* | L1, L3, L4 |
| spec | docs/cycles/YYYYMMDD_HHMM_*.md (plan files) | L2 |
| sync-plan | docs/cycles/YYYYMMDD_HHMM_*.md (Cycle doc) | L2 |
| skill-maker | skills/*/SKILL.md, skills/*/reference.md | L4 |
| commit | docs/STATUS.md (自動更新) | L3 |
| review | Cycle doc の Review Summary セクション | L2 |
| phase-compact | Cycle doc の Phase Summary セクション | L2 |
| learn | docs/instincts/*.md | L3 |
