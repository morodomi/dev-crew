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
| レビュー | review | Claude+Codex | Claude | competitive |
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
