---
feature: fix-post-approve-sync-plan-direct-call
cycle: 20260326_1710
phase: DONE
complexity: trivial
test_count: 3
risk_level: low
codex_session_id: ""
created: 2026-03-26 17:10
updated: 2026-03-26 17:20
---

# fix: Post-Approve Action で sync-plan を直接呼ばせない

## Scope Definition

### In Scope
- [ ] agents/sync-plan.md の description に「Skill()での直接呼び出し不可」を追記
- [ ] .claude/rules/post-approve.md に禁止事項セクションを追加
- [ ] skills/onboard/reference.md の Post-Approve Action テンプレートを /orchestrate 一本に簡素化
- [ ] tests/test-post-approve-action.sh のテストを orchestrate 経由に更新

### Out of Scope
- tests/test-onboard-tdd-workflow-template.sh のワークフロー概念図変更（直接呼び出し指示ではないため変更不要）

### Files to Change (target: 10 or less)
- agents/sync-plan.md (edit)
- .claude/rules/post-approve.md (edit)
- skills/onboard/reference.md (edit)
- tests/test-post-approve-action.sh (edit)

## Environment

### Scope
- Layer: Shell script (Bash) + Markdown
- Plugin: N/A
- Risk: LOW (PASS)

### Runtime
- Language: Bash / Markdown

### Dependencies (key packages)
- (なし)

### Risk Interview (BLOCK only)
- (Risk: LOW のためスキップ)

## Context & Dependencies

### Reference Documents
- agents/sync-plan.md - 修正対象（description 強化）
- .claude/rules/post-approve.md - 修正対象（禁止事項追加）
- skills/onboard/reference.md - 修正対象（テンプレート簡素化）
- tests/test-post-approve-action.sh - 修正対象（テスト更新）

### Dependent Features
- orchestrate: sync-plan を内部で Agent() として呼び出す設計

### Related Issues/PRs
- (なし)

## Test List

### TODO
- [ ] TC-01: agents/sync-plan.md の description に「Skill()での直接呼び出し不可」が含まれる
- [ ] TC-02: .claude/rules/post-approve.md に「Skill(dev-crew:sync-plan)」の直接呼び出し禁止が記載されている
- [ ] TC-03: skills/onboard/reference.md の Post-Approve Action テンプレートが /orchestrate に委譲し、dev-crew:sync-plan の直接呼び出しを含まない

### WIP
(none)

### DISCOVERED
(none)

### DONE
(none)

## Implementation Notes

### Goal
`Skill(dev-crew:sync-plan)` の "Unknown skill" エラーを防ぐ。sync-plan は Agent（subagent_type）であり Skill ではないため、LLM が Skill() で直接呼び出さないようドキュメントを修正する。

### Background
sync-plan は orchestrate が内部で Agent として呼ぶ設計だが、onboard テンプレートの Post-Approve Action セクションが `dev-crew:sync-plan` を直接呼ぶ手順を記載しているため、LLM がそのまま `Skill()` で呼んでしまい "Unknown skill" エラーになる。

### Design Approach
3点の修正で誤呼び出しを防止する:

1. **agents/sync-plan.md description 強化**: 「Skill()での直接呼び出し不可 — 必ず /orchestrate 経由」を明記
2. **.claude/rules/post-approve.md 禁止事項追加**: `Skill(dev-crew:sync-plan)` 直接呼び出し禁止、分解実行禁止を明記
3. **onboard/reference.md テンプレート簡素化**: Post-Approve Action を「/orchestrate を起動する。それだけ。」に統一し、sync-plan/plan-review の個別手順を削除

テスト (test-post-approve-action.sh) も「sync-plan が存在するか」から「/orchestrate への委譲か」「直接 sync-plan 呼び出しがないか」に更新する。

## Verification

```bash
bash tests/test-post-approve-action.sh && bash tests/test-onboard-tdd-workflow-template.sh
```

Evidence: 23/23 PASS (test-post-approve-action 15 + test-onboard-tdd-workflow-template 8)

## Progress Log

### 2026-03-26 17:10 - INIT
- Cycle doc created
- Scope definition ready

### 2026-03-26 17:12 - RED
- TC-01, TC-02 追加、TC-03 更新。TC-01/TC-02 FAIL確認

### 2026-03-26 17:15 - GREEN
- sync-plan.md description 強化
- post-approve.md 禁止事項セクション追加
- onboard/reference.md テンプレート簡素���
- 23/23 PASS

### 2026-03-26 17:18 - REVIEW
- PASS (LOW risk, docs-only changes)
- Phase completed

---

## Next Steps

1. [Done] INIT
2. [Done] PLAN
3. [Done] RED
4. [Done] GREEN
5. [Done] REFACTOR (skip - docs only)
6. [Done] REVIEW
7. [Done] COMMIT
