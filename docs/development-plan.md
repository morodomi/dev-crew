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
- /simplify委譲パターン導入（refactorスキル）
- phase-compact + /compact 自然なコンテキスト圧縮
- CLAUDE.md スキル/エージェント数更新

---

## Phase 6: Next Evolution (Planning)

### Closed Issues

| Issue | Title | Priority | Status |
|-------|-------|----------|--------|
| #31 | CLAUDE.md 陳腐化警告 hook | P1 | Closed |
| #30 | onboard テンプレート簡素化 | P1 | Closed |
| #32 | HTML コメント構造保護の検証 | P2 | Closed |
| #19 | designer レビュー価値の検証 | P2 | Closed |
| #8 | hook-based tool output filtering | P2 | Closed |

### Open Issues

| Issue | Title | Priority |
|-------|-------|----------|
| #36 | Risk Classifier チューニング (LOW閾値の実運用検証) | P2 |
| #38 | On-Demand Capabilities (OSS調査・E2Eベンチマーク) | P2 |

### Evolution Themes

1. **Risk Classifier チューニング** - LOW閾値 (0-29) の実運用データ収集後に再調整
2. **Usability 改善** - mode判定の明示化、BLOCK復帰フロー、agent出力形式統一
3. **On-Demand Capabilities** - OSS類似実装調査、E2Eテスト自動生成、ベンチマーク

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
| Phase 6 | Next Evolution | Planning |
