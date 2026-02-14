# Skills Catalog

## Core Plugin Skills

### Workflow Skills (7 phases)

| Skill | Origin | Rename | Description |
|-------|--------|--------|-------------|
| init | tdd-init | Yes (remove tdd-) | Cycle doc作成。スコープ・環境を定義 |
| plan | tdd-plan | Yes | 実装計画作成、Test List定義(5-10件) |
| red | tdd-red | Yes | 失敗するテスト作成。red-workerを並列spawn |
| green | tdd-green | Yes | テストを通す最小実装。green-workerを並列spawn |
| refactor | tdd-refactor | Yes | コード品質改善（DRY, naming等）テスト維持 |
| review | tdd-review | Yes | 品質チェック: tests + coverage + static analysis + quality-gate |
| commit | tdd-commit | Yes | git add/commit + STATUS.md更新 |

### Review Gate Skills

| Skill | Origin | Rename | Agents | Description |
|-------|--------|--------|--------|-------------|
| plan-review | plan-review | No | 5並行 | 設計レビュー(scope, architecture, risk, product, usability) |
| quality-gate | quality-gate | No | 6並行 | コードレビュー(correctness, performance, security, guidelines, architecture + optional) |

### Orchestration Skills

| Skill | Origin | Rename | Description |
|-------|--------|--------|-------------|
| orchestrate | tdd-orchestrate | Yes | PdMとして全フェーズ自律管理。Socrates Protocol対応 |
| phase-compact | NEW | - | フェーズ境界でのcompaction。Cycle docに永続化後/compact |

### Diagnostic Skills

| Skill | Origin | Rename | Description |
|-------|--------|--------|-------------|
| diagnose | tdd-diagnose | Yes | 3+仮説を並列調査。根本原因特定 |
| parallel | tdd-parallel | Yes | クロスレイヤー並列開発。Agent Teams必須 |

### Setup Skills

| Skill | Origin | Rename | Description |
|-------|--------|--------|-------------|
| onboard | tdd-onboard | Yes | プロジェクト初期セットアップ。CLAUDE.md生成 |

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
| architect | architect | PLAN設計。Test List作成 |
| red-worker | red-worker | REDテスト作成ワーカー |
| green-worker | green-worker | GREEN実装ワーカー |
| refactorer | refactorer | REFACTORコード改善 |

### Design (1) - NEW

| Agent | Origin | Description |
|-------|--------|-------------|
| designer | NEW | UI/UXデザイン支援。Refactoring UI原則ベース |

### Reviewers (9)

| Agent | Origin | Gate | Description |
|-------|--------|------|-------------|
| correctness-reviewer | same | quality-gate | 論理エラー、エッジケース、例外処理 |
| performance-reviewer | same | quality-gate | アルゴリズム効率、N+1、メモリ |
| security-reviewer | same | quality-gate | 入力検証、認証、SQLi/XSS |
| guidelines-reviewer | same | quality-gate | コーディング規約、命名規則 |
| scope-reviewer | same | plan-review | 変更範囲、ファイル数、依存関係 |
| architecture-reviewer | same | both | 設計整合性、パターン、レイヤー構造 |
| risk-reviewer | same | plan-review | 影響範囲、破壊的変更、ロールバック |
| product-reviewer | same | plan-review | ユーザー価値、コスト妥当性、優先度 |
| usability-reviewer | same | plan-review | UX/UI、アクセシビリティ、ユーザーフロー |

---

## Security Plugin Skills

| Skill | Origin | Rename | Description |
|-------|--------|--------|-------------|
| security-scan | security-scan | No | RECON->SCAN->REPORT。5 or 13エージェント並行 |
| attack-report | attack-report | No | 脆弱性レポート生成(JSON + Markdown) |
| context-review | context-review | No | ビジネスロジック確認 |
| generate-e2e | generate-e2e | No | 脆弱性からE2Eテスト自動生成 |

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

## New Skills (to be developed)

| Skill | Plugin | Priority | Description |
|-------|--------|----------|-------------|
| phase-compact | core | P0 | フェーズ境界compaction |
| designer workflow | core | P1 | UI/UXデザインワークフロー |
| dev-status | core | P2 | プロジェクト進捗ダッシュボード |
