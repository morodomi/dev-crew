# Cycle Doc Template

Copy and create `docs/cycles/YYYYMMDD_HHMM_<feature-name>.md`.

---

```markdown
---
feature: [feature-area]
cycle: [cycle-identifier]
phase: KICKOFF
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

**Real-path invocation を最低 1 件含めること** (rules/integration-verification.md)。
テストコード実行だけでは config-wire gap を見逃す (can miss when tests bypass runtime wiring)。

```bash
# CLI 例
python -m myapp --config config.yaml && grep "loaded: value" /tmp/myapp.log

# Web 例
docker compose up -d && curl -fsS localhost:8080/health && docker compose down

# Config 変更時 (motivating bug)
python -m myapp --config new.yaml && grep "loaded_from: new.yaml" /tmp/myapp.log

# Library 例
python -c "from mymod import run; run('config.yaml')"

# テスト実行 (補完)
for f in tests/test-*.sh; do bash "$f"; done
```

Evidence: (orchestrate が自動記入)

## Progress Log

Format for each phase entry (**strict, required by pre-commit-gate.sh**):

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

### YYYY-MM-DD HH:MM - KICKOFF
- Cycle doc created
- Scope definition ready

---

## Next Steps

1. [Done] KICKOFF <- Current
2. [Next] RED
3. [ ] GREEN
4. [ ] REFACTOR
5. [ ] REVIEW
6. [ ] COMMIT
7. [ ] DONE
```
