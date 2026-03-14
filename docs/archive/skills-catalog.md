# Skills Catalog

## Core Plugin Skills

### Workflow Skills (7 phases)

| Skill | Origin | Rename | Description |
|-------|--------|--------|-------------|
| spec | tdd-init | Yes (remove tdd-) | TDDコンテキスト設定 + 仕様曖昧性検出（Questioning Protocol, 5カテゴリ） |
| kickoff | tdd-plan | Yes (plan→kickoff) | planファイル→Cycle doc生成 |
| red | tdd-red | Yes | テスト計画検証(Stage 1-3) + テストコード作成。red-workerを並列spawn |
| green | tdd-green | Yes | テストを通す最小実装。green-workerを並列spawn |
| refactor | tdd-refactor | Yes | delegates to /simplify + Verification Gate |
| review | tdd-review | Yes | 品質チェック: tests + coverage + static analysis + unified review (risk-based) |
| commit | tdd-commit | Yes | git add/commit + STATUS.md更新 |

### Orchestration Skills

| Skill | Origin | Rename | Description |
|-------|--------|--------|-------------|
| orchestrate | tdd-orchestrate | Yes | PdMとして全フェーズ自律管理。Socrates Protocol対応 |
| phase-compact | NEW | - | フェーズ境界でのcompaction。Cycle docに永続化後/compact |
| strategy | NEW (v2) | - | 企画フェーズ。要件理解→リサーチ→設計→GitHub Issue作成 |
| reload | NEW | - | /compact後のコンテキスト復元。Cycle docから現在フェーズを復元 |

### Diagnostic Skills

| Skill | Origin | Rename | Description |
|-------|--------|--------|-------------|
| diagnose | tdd-diagnose | Yes | 3+仮説を並列調査。根本原因特定 |
| parallel | tdd-parallel | Yes | クロスレイヤー並列開発。Agent Teams必須 |

### Setup Skills

| Skill | Origin | Rename | Description |
|-------|--------|--------|-------------|
| onboard | tdd-onboard | Yes | プロジェクト初期セットアップ。AGENTS.md + CLAUDE.md生成 |
| skill-maker | NEW | - | Anthropic公式ガイド準拠の対話型スキル作成・レビュー支援 |

---

## Core Plugin Agents

### Orchestration (2)

| Agent | Origin | Description |
|-------|--------|-------------|
| pdm | tdd-orchestrate内 | PdM。全フェーズ管理、判断、人間へのエスカレーション |
| socrates | socrates | Devil's Advocate。WARN/BLOCK時に反論提示 |

### Implementation (4)

| Agent | Origin | Description |
|-------|--------|-------------|
| architect | architect | KICKOFFフェーズ。Design Review Gate + planファイル→Cycle doc変換 |
| red-worker | red-worker | REDテスト作成ワーカー。Step 0で決定論的/確率的を判定しテスト戦略を選択 |
| green-worker | green-worker | GREEN実装ワーカー |
| refactorer | refactorer | REFACTORコード改善 |

### Design (1) - NEW

| Agent | Origin | Description |
|-------|--------|-------------|
| designer | NEW | UI/UXデザイン支援。Refactoring UI原則ベース |

### Reviewers (7) (v2: unified review)

| Agent | Origin | Mode | Model | Description |
|-------|--------|------|-------|-------------|
| review-briefer | NEW (v2) | both | haiku | Review Brief生成。入力トークン圧縮 |
| design-reviewer | NEW (v2) | plan | sonnet | 統合設計レビュー (scope+architecture+risk) |
| correctness-reviewer | same | code | sonnet | 論理エラー、エッジケース、例外処理 |
| performance-reviewer | same | both | sonnet | アルゴリズム効率、N+1、メモリ |
| security-reviewer | same | both | sonnet | 入力検証、認証、SQLi/XSS |
| product-reviewer | same | both | haiku | ユーザー価値、コスト妥当性、優先度 |
| usability-reviewer | same | both | haiku | UX/UI、アクセシビリティ、ユーザーフロー |

---

## Security Plugin Skills

| Skill | Origin | Rename | Description |
|-------|--------|--------|-------------|
| security-scan | security-scan | No | RECON->SCAN->REPORT。5 or 13エージェント並行 |
| attack-report | attack-report | No | 脆弱性レポート生成(JSON + Markdown) |
| context-review | context-review | No | ビジネスロジック確認 |
| generate-e2e | generate-e2e | No | 脆弱性からE2Eテスト自動生成 |
| security-audit | NEW | - | security-scan + attack-reportを一括実行するオーケストレータ |

## Security Plugin Agents (18)

| Agent | Description |
|-------|-------------|
| recon-agent | エンドポイント列挙、技術スタック特定 |
| injection-attacker | SQL/NoSQL/Command Injection |
| xss-attacker | Reflected/Stored/DOM XSS |
| auth-attacker | 認証バイパス、JWT脆弱性 |
| csrf-attacker | CSRF、Cookie属性 |
| api-attacker | BOLA/BFLA/Mass Assignment |
| file-attacker | Path Traversal、LFI/RFI |
| ssrf-attacker | SSRF、クラウドメタデータ |
| ssti-attacker | Server-Side Template Injection |
| xxe-attacker | XML External Entity |
| wordpress-attacker | WordPress固有脆弱性 |
| crypto-attacker | 弱い暗号、デバッグモード |
| error-attacker | 不適切な例外処理 |
| sca-attacker | 依存関係脆弱性(OSV API) |
| dast-crawler | Playwright URL自動発見 |
| dynamic-verifier | SQLi/XSS/Auth/CSRF動的検証 |
| false-positive-filter | 誤検知除外 |
| attack-scenario | 脆弱性チェーン分析 |

---

## Language Plugin Skills (1 skill each)

| Plugin | Skill | Tools |
|--------|-------|-------|
| php | php-quality | PHPStan, Pint, PHPUnit/Pest |
| python | python-quality | pytest, mypy, Black/isort |
| typescript | ts-quality | tsc, ESLint, Prettier, Jest/Vitest |
| javascript | js-quality | ESLint, Prettier, Jest/Vitest |
| flask | flask-quality | pytest-flask, mypy, Black/isort |
| flutter | flutter-quality | dart analyze, dart format, flutter test |
| hugo | hugo-quality | hugo build, htmltest, template metrics |

---

## Meta Plugin Skills

| Skill | Origin | Description |
|-------|--------|-------------|
| learn | meta-skills/learn | セッションパターン抽出。instinct(JSONL)として蓄積 |
| evolve | meta-skills/evolve | instinctをクラスタリングしてスキル/エージェント自動生成 |

## Meta Plugin Agents

| Agent | Origin | Description |
|-------|--------|-------------|
| observer | meta-skills/observer | パターン検出、confidence scoring |

---
