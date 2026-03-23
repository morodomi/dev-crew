---
feature: pre-red-gate / pre-commit-gate 旧形式Cycle doc誤検出修正
cycle: 20260324_0003_fix-gate-old-format
phase: DONE
complexity: trivial
test_count: 3
risk_level: low
codex_session_id: ""
created: 2026-03-24 00:03
updated: 2026-03-24 00:03
---

# Issue #102: pre-red-gate.sh 旧形式Cycle doc誤検出修正

## Scope Definition

### In Scope
- [ ] `pre-red-gate.sh` の active cycle 検出ロジック修正（`phase:` フィールド不在をスキップ）
- [ ] `pre-commit-gate.sh` の同ロジック修正
- [ ] `test-pre-red-gate.sh` に T-06, T-07 追加
- [ ] `test-pre-commit-gate.sh` に T-06 追加

### Out of Scope
- test-phase-gate.sh の変更（リグレッション確認のみ、変更なし）

### Files to Change (target: 10 or less)
- `scripts/gates/pre-red-gate.sh` (edit)
- `scripts/gates/pre-commit-gate.sh` (edit)
- `tests/test-pre-red-gate.sh` (edit)
- `tests/test-pre-commit-gate.sh` (edit)

## Environment

### Scope
- Layer: Shell
- Plugin: bash
- Risk: 20 (PASS)

### Runtime
- Language: bash (zsh compatible)

### Dependencies (key packages)
- awk: POSIX
- grep: POSIX

### Risk Interview (BLOCK only)
(N/A - PASS)

## Context & Dependencies

### Reference Documents
- [CONSTITUTION.md](../../CONSTITUTION.md) - 原則6: 決定論的プロセス保証

### Dependent Features
- pre-red-gate.sh: TDD RED フェーズ前提チェック
- pre-commit-gate.sh: COMMIT 前提チェック

### Related Issues/PRs
- Issue #102: pre-red-gate.sh 旧形式Cycle doc誤検出

## Test List

### TODO
- [ ] TC-01 (pre-red T-06): 旧形式Cycle doc (phase:フィールドなし) がスキップされ、BLOCKになる
  - Given: docs/cycles/ に phase: フィールドを持たないCycle docのみ存在
  - When: pre-red-gate.sh を実行
  - Then: exit 1 (BLOCK) かつ "No active Cycle doc" メッセージ
- [ ] TC-02 (pre-red T-07): frontmatterなしCycle docがスキップされ、BLOCKになる
  - Given: docs/cycles/ にfrontmatter（---区切り）を持たないCycle docのみ存在
  - When: pre-red-gate.sh を実行
  - Then: exit 1 (BLOCK)
- [ ] TC-03 (pre-commit T-06): 旧形式Cycle doc (phase:フィールドなし) がスキップされ、BLOCKになる
  - Given: docs/cycles/ に phase: フィールドを持たないCycle docのみ存在
  - When: pre-commit-gate.sh を実行
  - Then: exit 1 (BLOCK) かつ "No active Cycle doc" メッセージ

### WIP
(none)

### DISCOVERED
(none)

### DONE
(none)

## Implementation Notes

### Goal
`pre-red-gate.sh` / `pre-commit-gate.sh` が旧形式Cycle doc（`phase:` フィールドなし）をnon-DONEとみなし、誤ってactiveとして扱うバグを修正する。

### Background
根本原因: `! grep -q 'phase: DONE'` が `phase:` フィールド自体の不在を区別できない。旧形式docは `phase: DONE` を含まないため、誤ってactiveとみなされる。

### Design Approach

**Before (両gate共通):**

    if ! awk '/^---$/{c++;next} c==1{print}' "$f" | grep -q 'phase: DONE'; then
      ACTIVE_CYCLE="$f"
      break
    fi

**After:**

    phase=$(awk '/^---$/{c++;next} c==1{print}' "$f" | grep '^phase:' | head -1 | sed 's/^phase: *//')
    [ -z "$phase" ] && continue  # Skip docs without phase field
    if [ "$phase" != "DONE" ]; then
      ACTIVE_CYCLE="$f"
      break
    fi

既存テストフィクスチャ（T-01〜T-05）は全て `phase: RED` or `phase: DONE` を含むため、リグレッションなし。

## Progress Log

### 2026-03-24 00:03 - KICKOFF
- Design Review Gate: WARN (score: 15/100)
  - 警告: Test List に Given/When/Then 形式の明示なし（planレベルでは許容、Cycle doc上で補完済み）
- Cycle doc created
- Scope definition ready

### 2026-03-24 00:03 - INIT
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
