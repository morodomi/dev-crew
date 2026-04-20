# Cycle Doc Template

Copy and create `docs/cycles/YYYYMMDD_HHMM_<feature-name>.md`.

---

```markdown
---
feature: [feature-area]
cycle: [cycle-identifier]
phase: INIT
complexity: [trivial|standard|complex]
test_count: [number]
risk_level: [low|medium|high]
retro_status: none
codex_session_id: ""
created: YYYY-MM-DD HH:MM
updated: YYYY-MM-DD HH:MM
---

# [Feature Name]

## Scope Definition

### In Scope
- [ ] [Implementation item 1]
- [ ] [Implementation item 2]

### Out of Scope
- [Item] (Reason: [reason])

### Files to Change (target: 10 or less)
- [file-path] (new/edit)

## Environment

### Scope
- Layer: [Backend / Frontend / Both]
- Plugin: [php / flask / python / js / ts]
- Risk: [0-100] ([PASS / WARN / BLOCK])

### Runtime
- Language: [Python 3.12.0 / PHP 8.3.0 / Node 20.0.0]

### Dependencies (key packages)
- [package]: [version]
- [package]: [version]

### Risk Interview (BLOCK only)
- Risk type: [Security / External API / Data Changes]
- [Question 1]: [Answer]
- [Question 2]: [Answer]
- [Question 3]: [Answer]

## Context & Dependencies

### Reference Documents
- [docs/xxx.md] - [reason]

### Dependent Features
- [Feature]: [file-path]

### Related Issues/PRs
- Issue #[number]: [title]

## Test List

### TODO
- [ ] TC-01: [test case]
- [ ] TC-02: [test case]

### WIP
(none)

### DISCOVERED
(none)

### DONE
(none)

## Implementation Notes

### Goal
[User input]

### Background
[Fill in PLAN]

### Design Approach
[Fill in PLAN]

## Verification

Product Verification コマンド（省略可能）。orchestrate が REFACTOR 後に実行し、結果を Evidence として保存する。
advisory evidence（非ブロッキング）。セクション不在またはコマンドなし → サイレントスキップ。

```bash
# 例: curl -s http://localhost:8080/api/health | jq .status
# 例: npx playwright test e2e/smoke.spec.ts
```

Evidence: (orchestrate が自動記入)

## Progress Log

Format for each phase entry:

```
### YYYY-MM-DD HH:MM - PHASE_NAME
- [completed action]
- Phase completed
```

Phase-specific content:
- RED: `Test code created, N tests failing`
- GREEN: `Implementation complete, all tests passing`
- REFACTOR: `refactor (checklist) + Verification Gate passed`
- REVIEW: `review(code) score:NN verdict:PASS/WARN/BLOCK`
- COMMIT: `Committed: [hash]`

### YYYY-MM-DD HH:MM - INIT
- Cycle doc created
- Scope definition ready

---

## Next Steps

1. [Done] INIT <- Current
2. [Next] PLAN
3. [ ] RED
4. [ ] GREEN
5. [ ] REFACTOR
6. [ ] REVIEW
7. [ ] COMMIT
```
