# Development Plan

## Phase 1: Migration (DONE)

既存スキルをdev-crewに統合。単一plugin構造にフラット化完了。

### 完了事項

- tdd-core -> agents/ + skills/ (root直下)
- tdd-php/python/ts/js/flask/flutter/hugo -> skills/*-quality/
- redteam-core -> agents/*-attacker.md + skills/security-scan/ etc.
- meta-skills -> agents/observer.md + skills/learn/ + skills/evolve/
- 全`tdd-`参照を除去
- 単一plugin.json作成（marketplace.json廃止）
- rules/ 作成（git-safety, git-conventions, security）
- hooks/hooks.json 作成（プレースホルダー）

---

## Phase 1.5: Test Infrastructure (DONE)

構造バリデーションテストを作成。全Phaseの前提基盤。

### 完了事項

- `tests/test-plugin-structure.sh` - plugin.json, agents/, skills/, rules/, hooks/ 検証
- `tests/test-agents-structure.sh` - エージェント frontmatter 検証
- `tests/test-skills-structure.sh` - SKILL.md 行数 + frontmatter 検証
- 3つの over-limit SKILL.md を修正 (attack-report, context-review, flask-quality)
- GitHub Issues #1-#9 登録完了

### Issue Tracking

| Issue | Title | Phase | Status |
|-------|-------|-------|--------|
| #1 | test: structure validation scripts | 1.5 | DONE |
| #2 | feat: phase-compact skill | 2 | DONE |
| #3 | feat: orchestrate phase-compact integration | 2 | DONE |
| #4 | research: Japanese vs Western UI/UX | 3 | DONE |
| #5 | feat: designer agent (Japanese design) | 3 | DONE |
| #6 | feat: designer + plan-review integration | 3 | DONE |
| #7 | feat: model selection hints | 4 | DONE |
| #8 | feat: hook-based tool output filtering | 4 | DONE |
| #9 | chore: SKILL.md size audit | 4 | DONE |

---

## Phase 2: phase-compact Skill (DONE)

TDDフェーズ境界でのcontext compaction。orchestrate skillと統合済み。

---

## Phase 3: Designer Agent (DONE)

designer.md 作成済み。review スキル (--plan mode) に統合済み。

---

## Phase 4: Optimization (DONE)

### 4.1 Model Selection Optimization (DONE)

agent frontmatter に model hints 実装済み。

### 4.2 Tool Output Filtering (Closed: #8)

git log, git diff等の出力をHookでフィルタリング。Closed。

### 4.3 Skill Loading Optimization (DONE)

SKILL.md スリム化 + reference.md Progressive Disclosure 実装済み。

---

## Phase 5: v2 Restructuring (DONE)

統一 review skill、risk-based scaling、strategy skill を導入。

### 完了事項

- quality-gate + plan-review を統一 review skill に統合
- Risk Classifier による reviewer 数動的スケーリング (LOW/WARN/BLOCK)
- review-briefer (haiku) による入力トークン圧縮
- design-reviewer による統合設計レビュー (scope+architecture+risk)
- strategy skill (企画フェーズ) 新設

---

## Phase 5.5: Orchestrator Redesign (DONE)

self-contained型からオーケストレータ型ワークフローへ再設計 (#43)。

### 完了事項

- plan mode起点のワークフロー統一
- refactor skill導入（内部で/simplifyに委譲）
- phase-compact + /compact 自然なコンテキスト圧縮
- CLAUDE.md スキル/エージェント数更新

---

## Phase 6: Next Evolution (DONE)

### Closed Issues

| Issue | Title | Priority | Status |
|-------|-------|----------|--------|
| #31 | CLAUDE.md 陳腐化警告 hook | P1 | Closed |
| #30 | onboard テンプレート簡素化 | P1 | Closed |
| #32 | HTML コメント構造保護の検証 | P2 | Closed |
| #19 | designer レビュー価値の検証 | P2 | Closed |
| #8 | hook-based tool output filtering | P2 | Closed |
| #36 | Risk Classifier チューニング (LOW閾値の実運用検証) | P2 | Closed |
| #38 | On-Demand Capabilities (OSS調査・E2Eベンチマーク) | P2 | Closed |

### Evolution Themes (Closed)

1. **Risk Classifier チューニング** - LOW閾値 (0-29) の実運用データ収集後に再調整
2. **Usability 改善** - mode判定の明示化、BLOCK復帰フロー、agent出力形式統一
3. **On-Demand Capabilities** - OSS類似実装調査、E2Eテスト自動生成、ベンチマーク

---

## Phase 7: Factory Model Adaptation (DONE)

Addy Osmani「The Factory Model」から取り入れる改善。
コスト最適化を維持しつつ、仕様精度とテスト検証を強化する。

### 7.1 Spec Precision (仕様精度の強化)

**課題**: specスキルのStep 4「何を実装するか聞く」が1問で終わり、曖昧な仕様がそのまま下流に流れる。

**方針**: fumiya-kume/claude-code digプラグインのアプローチを参考に、AskUserQuestionによる構造化質問でplan mode内の曖昧さを体系的に排除する。

**対象スキル**: spec (Step 4強化)

**設計方針**:
- カテゴリ別の曖昧性検出（データ、API、UI/UX、スコープ、エッジケース）
- AskUserQuestion で2-4問ずつ、選択肢付きで質問
- 曖昧さが残る限りループ。全解消後にplan mode設計フェーズへ進む
- token消費を抑えるため、既存plan mode内で完結（新エージェント不要）

**NOT doing**:
- 並行エージェントによるファクトリー化（token消費問題。将来検討）

### 7.2 Test Plan Verification (テスト計画の検証)

**課題**: REDフェーズでテスト作成と同時にテスト計画を暗黙的に決めており、要件定義との突合がない。

**方針**: REDフェーズを3段階に分割する。

1. **Test Plan**: 要件からテスト計画を作成（Given/When/Then一覧）
2. **Test Plan Review**: テスト計画を要件定義（Cycle doc）と照合し、漏れ・過剰を検証
3. **Test Code**: 検証済みテスト計画からテストコードを作成

**対象スキル**: red (内部フェーズ分割)

**設計方針**:
- red-worker agentに渡す前にテスト計画をCycle docに記録
- テスト計画の検証はplan mode内のQAチェック強化で対応可能（新エージェント不要）
- 現行のTest List（plan mode Step 7.3）を「テスト計画」として正式化し、要件との突合ステップを追加

**NOT doing**:
- ADR運用（entire.io等の外部ツール連携は将来検討）
- 人間の役割再定義（対応不要）

### 完了事項

- spec SKILL.md: Step 4.8 Ambiguity Detection 追加（93→99行）
- spec reference.md / reference.ja.md: Ambiguity Detection セクション追加（5カテゴリ、Questioning Protocol、3ラウンド上限）
- red SKILL.md: Stage 1-3 構造に再編（96→89行）。旧Step 2-5の例示をreference.mdへ移動
- red reference.md: Test Plan Stage / Test Plan Review セクション追加（Gap分析、DISCOVERED項目フロー）
- tests/test-factory-model-adaptation.sh: TC-01〜TC-14（14テスト全PASS）

---

## Phase 8: Design Review Gate Integration (DONE)

orchestrate の設計レビューを kickoff 前に実施するよう変更。

### 完了事項

- architect agent に Design Review Gate (Scope/Architecture/Test List/Risk) を追加
- architect output JSON に pre_review フィールド (verdict/score/issues) 追加
- orchestrate Block 1 から review(plan) Skill 呼び出しを削除
- steps-subagent.md / steps-teams.md で architect Task() prompt を更新
- reference.md の Phase Ownership、再試行ロジック、Socrates Protocol 発動条件を更新
- kickoff 完了メッセージを更新
- `/review --plan` は手動実行用として維持

---

## Phase 9: Test Architecture Integration (DONE)

テストアーキテクチャ思想をREDフェーズに統合。

### 完了事項

- red-worker.md に Step 0: Test Strategy Classification 追加（決定論的/確率的の判定）
- reference.md に Test Architecture Guide セクション追加（2領域モデル、設計原則、Mock方針、言語別ツール、フォールバック戦略）
- 3者議論（Claude/Gemini/Grok）で Option C (red拡張) に合意。思想文書: `Keiba/docs/test_architecture.md`

---

## Phase 10: Commit Completion Validation (DONE)

commitスキルにTest List / Progress Logの包括的な完了検証を追加。

### 完了事項

- commit/SKILL.md に Test List Completion Gate 追加（未完了TC残存でBLOCK）
- commit/SKILL.md に Progress Log Completeness Gate 追加（全5フェーズの Phase completed 記録を要求）
- commit/reference.md に両Gateの詳細ロジック追加（判定コード、不足時の対応表）
- tests/test-phase-gate.sh に TC-19〜TC-22 追加（全22テストPASS）

---

## Timeline

| Phase | Content | Status |
|-------|---------|--------|
| Phase 1 | Migration | DONE |
| Phase 1.5 | Test Infrastructure | DONE |
| Phase 2 | phase-compact | DONE |
| Phase 3 | Designer Agent | DONE |
| Phase 4 | Optimization | DONE |
| Phase 5 | v2 Restructuring | DONE |
| Phase 5.5 | Orchestrator Redesign | DONE |
| Phase 6 | Next Evolution | DONE |
| Phase 7 | Factory Model Adaptation | DONE |
| Phase 8 | Design Review Gate Integration | DONE |
| Phase 9 | Test Architecture Integration | DONE |
| Phase 10 | Commit Completion Validation | DONE |
