# Cycle: dev-crew v2 Restructuring

- issue: v2 restructuring plan
- phase: COMMIT
- started: 2026-02-18 05:45

## Context

dev-crew v2 リストラクチャリング。品質を落とさずにコスト削減し、実際の開発チームのように機能する AI 開発環境を構築する。

## Scope

### In Scope
- Step 1: review-briefer + design-reviewer agent 作成
- Step 2: Risk Classification ロジック実装
- Step 3: 統一 review skill 作成
- Step 4: orchestrate フロー更新
- Step 5: 旧 agent/skill 退役
- Step 6: Discovered -> Issue 自動化
- Step 7: strategy skill 作成
- Step 8: commit skill 更新

### Out of Scope
- On-Demand Advanced Capabilities (将来拡張)

## Environment
- Plugin: dev-crew (Claude Code Plugin)
- Tests: 20 test scripts, 196 total tests (all passing at baseline)

## PLAN

### Architecture
- Two-Phase Architecture: Strategy (企画) + Execution (実行)
- Unified review skill: mode plan/code, risk-based scaling
- Review Brief pattern: haiku で diff/plan 圧縮
- Risk Classification: deterministic shell script (LLM不使用)

### Test List
- TC-01: review-briefer.md has required frontmatter (name, description, model: haiku)
- TC-02: design-reviewer.md has required frontmatter (name, description, model: sonnet)
- TC-03: design-reviewer.md covers scope + architecture + risk verification
- TC-04: risk-classifier.sh exists and is executable
- TC-05: risk-classifier.sh returns correct risk levels for known patterns
- TC-06: review/SKILL.md supports mode: plan and mode: code
- TC-07: review/steps-subagent.md has Risk Classification + Brief + Specialist panel
- TC-08: orchestrate references review skill instead of plan-review/quality-gate
- TC-09: Retired agents (scope/architecture/risk/guidelines-reviewer) do not exist
- TC-10: Retired skills (plan-review/, quality-gate/) do not exist
- TC-11: No stale references to retired agents/skills
- TC-12: review SKILL.md has DISCOVERED -> gh issue create logic
- TC-13: strategy skill exists with required structure
- TC-14: commit SKILL.md includes issue reference
- TC-15: All existing tests still pass (regression)

### Files to Change
- NEW: agents/review-briefer.md, agents/design-reviewer.md
- NEW: skills/review/risk-classifier.sh, skills/review/steps-subagent.md
- NEW: skills/strategy/SKILL.md, skills/strategy/reference.md
- MODIFY: skills/review/SKILL.md, skills/review/reference.md
- MODIFY: skills/orchestrate/SKILL.md, steps-subagent.md, steps-teams.md
- MODIFY: skills/commit/SKILL.md
- DELETE: agents/scope-reviewer.md, architecture-reviewer.md, risk-reviewer.md, guidelines-reviewer.md
- DELETE: skills/plan-review/, skills/quality-gate/
- MODIFY: tests/test-agents-structure.sh, test-reviewer-scoring.sh, test-cross-references.sh, test-stale-references.sh, test-orchestrate-compact.sh
- NEW: tests/test-v2-restructuring.sh

## Progress Log

- 2026-02-18 05:45 Baseline: 20 test files, 196 tests, all passing
- 2026-02-18 08:30 [REVIEW] quality-gate WARN (score 62): usability-reviewer「Mode判定の暗黙性、BLOCK回復フローの明示性不足」
- 2026-02-18 12:15 [FOLLOW-UP] Issue #37 で usability 指摘を解消 → docs/cycles/20260218_1200_review-usability.md

## DISCOVERED

(none)
