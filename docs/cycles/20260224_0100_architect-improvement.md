# Cycle: architect agent prompt improvement

- issue: Issue 2 from evolution plan
- status: REVIEW
- created: 2026-02-24

## Context

architect agentのプロンプトを改善。(1) 探索フェーズ（Read-heavy）を設計前に強制 (2) QA Question Askerセクションを追加してTest List品質を向上。

## PLAN

### Design

**architect.md:**
- Workflowに探索フェーズ（Step 0）を追加: 最低5ファイル読んでから設計に入る
- Principlesに「探索優先」を追加

**plan SKILL.md:**
- Step 2.5: 探索フェーズ（コード・ドキュメントリーディング）追加
- Step 4: QA Question Asker（Test List作成前の自問）追加

**plan reference.md:**
- QA Question Askerセクション追加（4つの質問と記録フォーマット）

### Test List

- [ ] TC-01: architect.md contains exploration step (探索/Exploration)
- [ ] TC-02: architect.md mentions reading at least 5 files
- [ ] TC-03: architect.md Workflow has exploration before Skill(plan) execution
- [ ] TC-04: plan SKILL.md contains exploration step
- [ ] TC-05: plan SKILL.md contains QA Question Asker step
- [ ] TC-06: plan SKILL.md QA step comes before Test List step
- [ ] TC-07: plan reference.md contains QA Question Asker section
- [ ] TC-08: plan reference.md QA section has 4 questions
- [ ] TC-09: plan SKILL.md still under 100 lines
- [ ] TC-10: Existing structure validation still passes

## RED

tests/test-architect-improvement.sh created with 10 test cases. All failed as expected.

## GREEN

- agents/architect.md: Added exploration phase (Step 2) before Skill(plan), added "探索優先" principle
- skills/plan/SKILL.md: Added Step 2.5 (Exploration), Step 4 (QA Question Asker), condensed Test List categories
- skills/plan/reference.md: Added QA Question Asker section with 4 questions and recording format

## REFACTOR

No refactoring needed. SKILL.md exactly at 100 lines after condensing Test List table.

## REVIEW

All 10 new tests pass. All 28 existing test files pass (296 total tests, 0 failures).

## DISCOVERED

(none)
