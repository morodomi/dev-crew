# Cycle: Socrates On-Demand + Pipeline Kickstart

- issue: (plan-driven sprint)
- status: REVIEW
- created: 2026-02-19

## Context

S2-1: Socrates on-demand化 -- PASS cycles (~80%) で opus 常駐コスト (~5K+ tokens) を完全排除。
WARN/BLOCK 時のみ Task() で on-demand spawn に変更。

## PLAN

### Design

**対象ファイル**:
- `skills/orchestrate/steps-teams.md` Phase 1: socrates 常駐 spawn を削除
- `skills/orchestrate/steps-teams.md` Socrates Protocol: SendMessage → Task() on-demand
- `skills/orchestrate/steps-teams.md` Team Cleanup: socrates shutdown を削除
- `skills/orchestrate/reference.md` Socrates Protocol: on-demand flow に更新
- `agents/socrates.md`: "常駐" 表現を削除、on-demand 対応

**品質担保**: Cycle doc の Progress Log を on-demand spawn 時の入力に含めることで判断履歴を補完。

### Test List

- TC-15: Phase 1 に socrates 常駐 spawn がないこと
- TC-16: Socrates Protocol が Task() で on-demand 起動すること
- TC-17: Team Cleanup に socrates shutdown がないこと

## RED

TC-15, TC-16, TC-17 added to test-orchestrate-compact.sh. All failed as expected.

## GREEN

- steps-teams.md: Removed permanent socrates spawn from Phase 1, replaced SendMessage with Task() in both Socrates Protocol sections, removed socrates shutdown from Team Cleanup
- reference.md: Updated Socrates Protocol flow to use Task() with Progress Log context
- agents/socrates.md: Replaced "常駐" with "on-demand", updated Context section

## REFACTOR

No refactoring needed. Changes are minimal and focused.

## REVIEW

All 26 test scripts pass (17/17 orchestrate tests including 3 new TCs).

## DISCOVERED

(none)
