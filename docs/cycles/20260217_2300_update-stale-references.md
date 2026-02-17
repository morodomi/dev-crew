---
issue: "#28"
phase: DONE
---

# Update stale references after auto-transition removal

## Background

Issue #27 (token optimization) removed auto-transition Skill() chains and `--no-auto-report` / `--auto-e2e` options from `security-scan/SKILL.md`. Some references in other files are now stale.

## Scope

1. **skills/generate-e2e/SKILL.md** - description references `security-scanの--auto-e2eオプションでも自動実行される` but `--auto-e2e` was removed from security-scan (now in security-audit)
2. **skills/security-scan/reference.md** - documents `--no-auto-report` and `--auto-e2e` options in "Auto Transition" section which no longer exist

## Design

### Change 1: generate-e2e/SKILL.md (line 3, description frontmatter)

**Current**:
```
security-scanの--auto-e2eオプションでも自動実行される
```

**After**:
```
security-auditの--auto-e2eオプションでも自動実行される
```

Rationale: `--auto-e2e` was moved from security-scan to security-audit (the orchestrator skill). The generate-e2e description should point to the correct skill.

### Change 2: security-scan/reference.md - Phase 4: AUTO TRANSITION (lines 70-93)

**Current** (lines 70-93): Documents auto-transition with Skill() chains, `--no-auto-report`, and `--auto-e2e` options.

**After**: Replace with "Phase 4: COMPLETION" section that reflects the current behavior (no auto-transition). The current SKILL.md shows a completion banner with manual next-step suggestions.

```markdown
### Phase 4: COMPLETION

スキャン完了後、結果サマリーと次のステップを表示する。

**表示例**:
```
================================================================================
SCAN完了
================================================================================
検出件数: Critical 0, High 2, Medium 1

次のステップ:
- レポート生成: /attack-report
- スキャン+レポート一括: /security-audit
================================================================================
```

自動的な Skill() チェーン遷移は行わない（Issue #27 で除去）。
```

### Change 3: security-scan/reference.md - LEARN Phase timing (lines 194, 196-198)

**Current** (line 194):
```
AUTO TRANSITION / E2E 完了後に実行。スキャン結果から以下を auto memory に保存する。
```

**After**:
```
REPORT Phase 完了後に実行。スキャン結果から以下を auto memory に保存する。
```

**Current** (lines 196-198):
```
**実行タイミング**:
\```
AUTO TRANSITION → [OPTIONAL] E2E → LEARN Phase
\```
```

**After**:
```
**実行タイミング**:
\```
REPORT → LEARN Phase
\```
```

Rationale: security-scan no longer has AUTO TRANSITION. Per the current SKILL.md workflow (`RECON → SCAN → REPORT → LEARN`), LEARN runs directly after REPORT.

### Files to Change

| File | Change |
|------|--------|
| `skills/generate-e2e/SKILL.md` | description: `security-scan` -> `security-audit` |
| `skills/security-scan/reference.md` | Phase 4 section rewrite + LEARN Phase timing update |

### Files NOT Changed (verification)

| File | Reason |
|------|--------|
| `skills/security-audit/SKILL.md` | Already correctly documents `--auto-e2e` -- no change needed |
| `skills/security-scan/SKILL.md` | Already updated in #27 -- no stale references |

## Test List

Tests are designed as a new shell script `tests/test-stale-references.sh` following the existing test infrastructure pattern (TC-XX format, pass/fail helpers, set -euo pipefail).

| TC | Description | Type | Validation |
|----|-------------|------|------------|
| TC-01 | generate-e2e/SKILL.md does not reference `--auto-e2e` as a security-scan option | grep | grep for `security-scanの--auto-e2e` returns 0 matches |
| TC-02 | generate-e2e/SKILL.md references security-audit for `--auto-e2e` | grep | grep for `security-auditの--auto-e2e` returns 1+ match |
| TC-03 | security-scan/reference.md does not document `--no-auto-report` option | grep | grep for `--no-auto-report` in reference.md returns 0 matches |
| TC-04 | security-scan/reference.md does not document `--auto-e2e` option | grep | grep for `--auto-e2e` in reference.md returns 0 matches |
| TC-05 | security-scan/reference.md does not have "AUTO TRANSITION" as a phase heading | grep | grep for `Phase 4: AUTO TRANSITION` returns 0 matches |
| TC-06 | security-scan/reference.md LEARN Phase does not reference AUTO TRANSITION timing | grep | grep for `AUTO TRANSITION` in LEARN Phase section returns 0 matches |
| TC-07 | Regression: existing test-no-auto-transitions.sh still passes | exec | Run test-no-auto-transitions.sh, exit code 0 |
| TC-08 | Regression: existing test-skills-structure.sh still passes | exec | Run test-skills-structure.sh, exit code 0 |
| TC-09 | Regression: existing test-cross-references.sh still passes | exec | Run test-cross-references.sh, exit code 0 |

## DISCOVERED

- **LEARN Phase timing reference** (lines 194, 198 of reference.md): Also references "AUTO TRANSITION" in the Memory Integration section. Added as Change 3 above and TC-06 to verify.
