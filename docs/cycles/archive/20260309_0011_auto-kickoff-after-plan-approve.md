---
feature: auto-kickoff-after-plan-approve
cycle: 20260309_0011
phase: DONE
created: 2026-03-09 00:11
updated: 2026-03-09 00:11
---

# Auto-Kickoff After Plan Approve

## Scope Definition

### In Scope
- [ ] plan approve → compact + accept edits on 遷移後にkickoffが自動実行される仕組みの検証
- [ ] planファイルに `## Post-Approve Action` セクションを追加する方式の確立
- [ ] 4ファイルの更新（検証成功時）

### Out of Scope
- plan-reviewのplan mode内実行問題（別途対応）

### Files to Change (target: 10 or less)
- CLAUDE.md (edit)
- skills/spec/SKILL.md (edit)
- skills/spec/reference.md (edit)
- skills/kickoff/SKILL.md (edit)

## Environment

### Scope
- Layer: Backend (Shell/Markdown)
- Plugin: dev-crew (self-modification)
- Risk: 10 (PASS) - ドキュメント変更のみ、ロジックなし

### Runtime
- Language: Bash 3.2.57, Markdown

### Dependencies (key packages)
- なし

### Risk Interview (BLOCK only)
N/A (PASS)

## Context & Dependencies

### Reference Documents
- CLAUDE.md - Workflowセクション（Post-Approve Action方式の記載先）
- skills/spec/SKILL.md - specスキル定義
- skills/spec/reference.md - Plan File Template
- skills/kickoff/SKILL.md - kickoffスキル定義

### Dependent Features
- spec skill: planファイル生成
- kickoff skill: Cycle doc生成

### Related Issues/PRs
- なし

## Formal Test Plan

### TC-01: approve後のauto-kickoff (検証済み)
- Given: planファイルに `## Post-Approve Action` セクションがある
- When: plan approve → compact + accept edits on で遷移
- Then: Post-Approve Action の指示に従いkickoffが自動実行される
- Paradigm: Manual observation (このセッション自体が検証)

### TC-02: Cycle doc正常生成 (検証済み)
- Given: planの内容がcompact後のコンテキストに残っている
- When: kickoffを実行
- Then: docs/cycles/ にCycle docが生成される
- Paradigm: Manual observation

### TC-03: CLAUDE.md Workflow に Post-Approve Action 記載
- Given: CLAUDE.md が存在する
- When: Workflow セクションを読む
- Then: "Post-Approve Action" の説明と review --plan のステップが含まれる
- Data: grep -c "Post-Approve Action" CLAUDE.md >= 1

### TC-04: spec/reference.md Plan File Template に Post-Approve Action セクション
- Given: skills/spec/reference.md が存在する
- When: Plan File Template セクションを読む
- Then: テンプレート内に `## Post-Approve Action` が含まれる
- Data: grep -c "Post-Approve Action" skills/spec/reference.md >= 1

### TC-05: spec/SKILL.md Step 6 に Post-Approve Action 必須記載
- Given: skills/spec/SKILL.md が存在する
- When: Step 6 を読む
- Then: Post-Approve Action がplanファイルの必須要素として記載されている
- Data: grep -c "Post-Approve Action" skills/spec/SKILL.md >= 1

### TC-06: kickoff/SKILL.md description が auto-execution を反映
- Given: skills/kickoff/SKILL.md が存在する
- When: YAML frontmatter の description を読む
- Then: plan approve後の自動実行に言及している
- Data: description に "auto" または "Post-Approve" を含む

## Test List

### TODO
(none)

### WIP
(none)

### DISCOVERED
(none)

### DONE
- [x] TC-01: approve後のauto-kickoff (このセッションで検証済み - PASS)
- [x] TC-02: Cycle doc正常生成 (このセッションで検証済み - PASS)
- [x] TC-03: CLAUDE.md Workflow に Post-Approve Action 記載 (PASS)
- [x] TC-04: spec/reference.md Plan File Template に Post-Approve Action セクション (PASS)
- [x] TC-05: spec/SKILL.md Step 6 に Post-Approve Action 必須記載 (PASS)
- [x] TC-06: kickoff/SKILL.md description が auto-execution を反映 (PASS)

## Implementation Notes

### Goal
plan approve → compact + accept edits on の遷移後に、kickoff が自動実行されるようにする。

### Background
現状、plan approve後にkickoffを手動で呼ぶ必要がある。compact後のコンテキストにkickoff実行の指示が残らないことが原因仮説。planファイルに `## Post-Approve Action` を書き、compact後にこの指示が読まれてkickoffが走るか検証する。

### Design Approach
1. `git checkout .` で未検証の差分を戻す（Step 0 - 完了）
2. kickoff自動実行の検証（このCycle doc生成が成功 = TC-02 PASS）
3. 検証結果に基づき4ファイルを更新

| 検証結果 | 次のアクション |
|---------|--------------|
| kickoff自動実行された | Post-Approve Action方式を採用。4ファイルを再修正 |
| kickoff自動実行されなかった | 別アプローチを検討 |

## Progress Log

### 2026-03-09 00:11 - KICKOFF
- Cycle doc created
- git checkout . で4ファイルの未検証差分を戻した
- Post-Approve Action により kickoff が自動実行された（TC-01 検証中）

---

## Next Steps

1. [Done] KICKOFF
2. [Done] RED
3. [Done] GREEN
4. [Done] REFACTOR
5. [Done] REVIEW
6. [Done] COMMIT <- Current
