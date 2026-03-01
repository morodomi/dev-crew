# User Stories

## Persona

- **Name**: 個人開発者（morodomi）
- **Context**: 複数のSaaSプロジェクトを並行開発
- **Goal**: 全プロジェクトで統一された品質基準とワークフローで開発したい
- **Pain Point**: token消費が激しく、5時間windowを使い切る

---

## Epic 1: 統一開発環境

### US-1.1: グローバルインストール

**As a** 開発者
**I want to** dev-crewをuser levelで一度だけインストールする
**So that** 全プロジェクトで同じワークフローが使える

**Acceptance Criteria:**
- [ ] `/plugin install core@dev-crew` で全プロジェクトに適用される
- [ ] プロジェクト固有のスキルはプロジェクト側で作成可能
- [ ] 言語プラグインは必要なものだけ有効化できる

### US-1.2: プロジェクト初期セットアップ

**As a** 開発者
**I want to** 新プロジェクトで `/onboard` を実行する
**So that** CLAUDE.md, docs/, .claude/ が自動生成される

**Acceptance Criteria:**
- [ ] フレームワーク自動検出（PHP/Python/TS等）
- [ ] 適切な言語プラグインの推奨
- [ ] プロジェクトCLAUDE.mdのテンプレート生成

---

## Epic 2: Token最適化

### US-2.1: フェーズ境界compaction

**As a** 開発者
**I want to** TDDフェーズ間で自動的にcontextがcompactされる
**So that** 5時間windowを有効に使える

**Acceptance Criteria:**
- [ ] 各フェーズ完了時にCycle docにphase summaryが追記される
- [ ] /compact が自動実行される
- [ ] 次フェーズ開始時にCycle docからコンテキストが復元される
- [ ] compaction後もワークフローが正常に継続する

### US-2.2: Subagentのmodel最適化

**As a** 開発者
**I want to** 単純なタスクにはHaikuモデルが使われる
**So that** token消費とコストが削減される

**Acceptance Criteria:**
- [ ] red-worker, green-workerはSonnetで実行
- [ ] product-reviewer, usability-reviewer等チェックリストベースのレビューはHaikuで実行
- [ ] model選択の基準がドキュメント化されている

### US-2.3: 段階的コンテキストロード

**As a** 開発者
**I want to** スキル起動時にreference.mdが読まれ、それ以外では読まれない
**So that** 初期ロードのtoken消費が最小化される

**Acceptance Criteria:**
- [ ] SKILL.md < 100行（必須情報のみ）
- [ ] reference.mdはスキル実行時にのみ読み込み
- [ ] 未使用スキルのreference.mdがcontextに入らない

---

## Epic 3: PdMオーケストレーション

### US-3.1: 自律的フェーズ管理

**As a** 開発者
**I want to** PdMが全フェーズを自律的に管理する
**So that** 私はINITで要件を伝えるだけで開発が進む

**Acceptance Criteria:**
- [ ] plan mode(INIT→設計→Test List→QA) → KICKOFF → review(plan) → RED → GREEN → /simplify → review(code) → COMMIT が自動遷移
- [ ] WARN/BLOCKでSocrates Protocolが発動
- [ ] BLOCK時は人間にエスカレーション
- [ ] 各フェーズ間でphase-compactが実行される

### US-3.2: DISCOVERED issue管理

**As a** 開発者
**I want to** スコープ外の発見事項がGitHub issueとして記録される
**So that** 現在のサイクルのスコープが膨張しない

**Acceptance Criteria:**
- [ ] REVIEW後にスコープ外項目を検出
- [ ] ユーザー承認後にGitHub issue作成
- [ ] Cycle docに `-> #issue-number` で記録

---

## Epic 4: セキュリティ統合

### US-4.1: リリース前セキュリティスキャン

**As a** 開発者
**I want to** `/security-scan` でOWASP Top 10ベースの脆弱性スキャンを実行する
**So that** リリース前にセキュリティ問題を検出できる

**Acceptance Criteria:**
- [ ] 5コアエージェント並行スキャン（default）
- [ ] 13エージェントフルスキャン（--full-scan）
- [ ] Markdown + JSONレポート出力
- [ ] E2Eテスト自動生成

---

## Epic 5: パターン学習

### US-5.1: セッションパターン抽出

**As a** 開発者
**I want to** 開発セッションから繰り返しパターンを自動抽出する
**So that** 次回以降の開発が効率化される

**Acceptance Criteria:**
- [ ] `/learn` でCycle doc + git logからパターン抽出
- [ ] confidence >= 0.5 のパターンをinstinctとして保存
- [ ] confidence >= 0.8 のパターンをMEMORY.mdに昇格提案

### US-5.2: スキル自動進化

**As a** 開発者
**I want to** 蓄積されたinstinctが新しいスキルやエージェントに進化する
**So that** 開発ワークフローが継続的に改善される

**Acceptance Criteria:**
- [ ] 3+類似instinctでクラスタリング
- [ ] SKILL.md or agent.md 自動生成
- [ ] ロールバック可能（backup/保存）

---

## Epic 6: デザイナー統合 (Future)

### US-6.1: UI/UXデザイン支援

**As a** 開発者
**I want to** PdMがDesignerエージェントにUI設計を委任する
**So that** フロントエンド開発時にデザイン品質が担保される

**Acceptance Criteria:**
- [ ] designerエージェントがRefactoring UI原則に基づくレビュー
- [ ] PLAN phaseでUI設計が含まれる場合に自動起動
- [ ] Tailwind CSS / shadcn/ui のパターン提案

---

## Priority Matrix

| Epic | Priority | Status |
|------|----------|--------|
| Epic 1: 統一開発環境 | P0 | Ready (既存スキル移行) |
| Epic 2: Token最適化 | P0 | Design done, implement phase-compact |
| Epic 3: PdMオーケストレーション | P0 | Ready (既存orchestrate移行) |
| Epic 4: セキュリティ統合 | P1 | Ready (既存redteam移行) |
| Epic 5: パターン学習 | P1 | Ready (既存meta移行) |
| Epic 6: デザイナー統合 | P2 | New development required |
