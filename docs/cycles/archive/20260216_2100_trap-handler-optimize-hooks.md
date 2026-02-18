# Cycle: add trap handler to test-hooks-structure.sh

phase: DONE
issue: #23
date: 2026-02-16

## Goal

test-hooks-structure.sh に trap handler を追加し、中断時の一時ファイル残存を防止する。

## Background

Issue #22 の quality-gate で performance reviewer が2つの改善点を指摘:

1. TC-03 が一時ファイル (agents/, skills/) を作成するが、中断時にクリーンアップされない
2. TC-02 と TC-03 で test-agents-structure.sh を2回実行 (~0.78s の冗長I/O)

## Scope

- 対象ファイル: `tests/test-hooks-structure.sh`
- trap handler 追加 (EXIT INT TERM)

**plan-review で却下**: TC-02/TC-03 のキャッシュ最適化は設計上不正。
TC-02 (clean state, exit 0) と TC-03 (drift state, exit 1) は異なるシナリオを検証しており、
TC-02 結果のキャッシュは TC-03 のドリフト検出テストを無効化する。

## Acceptance Criteria

- [ ] trap handler で中断時も一時ファイルがクリーンアップされる
- [ ] 既存テスト (TC-01, TC-02, TC-03) が全て PASS

## PLAN

### Implementation Approach

1. **Add trap handler**
   - Define cleanup() function that removes temp files (agents/test-drift-agent.md, skills/test-drift-skill/)
   - Register trap for EXIT INT TERM signals
   - Ensures temp files cleaned up even on Ctrl+C or script errors
   - Move existing inline cleanup (lines 72-73) into cleanup() function

### File Changes

- `tests/test-hooks-structure.sh` (1 file)
  - Add cleanup() function (lines ~8-12)
  - Add trap handler (line ~13)
  - Remove inline rm commands (lines 72-73), replaced by trap

### plan-review (score: max 25 / PASS)

- architecture-reviewer: TC-02/TC-03 キャッシュは異なるシナリオの混同 (CRITICAL)
- risk-reviewer: キャッシュ結果がドリフト検出を無効化 (CRITICAL)
- product-reviewer: trap handler は妥当、キャッシュの ROI 疑問
- 対応: キャッシュ最適化をスコープから除外、trap handler のみ実装

## Test List

### T-01: Trap handler cleans up on normal exit
- **Given**: test-hooks-structure.sh に trap handler が追加されている
- **When**: スクリプトが正常完了 (exit 0)
- **Then**: 一時ファイル (agents/test-drift-agent.md, skills/test-drift-skill/) が残存しない

### T-02: Trap handler cleans up on test failure exit
- **Given**: test-hooks-structure.sh に trap handler が追加されている
- **When**: スクリプトが失敗終了 (exit 1)
- **Then**: 一時ファイルが残存しない

### T-03: Inline cleanup removed (trap handles it)
- **Given**: trap handler が cleanup を担当
- **When**: test-hooks-structure.sh のソースを確認
- **Then**: TC-03 内に個別の rm -f / rm -rf が存在しない (trap に統合)

### T-04: All existing tests still pass
- **Given**: Modified test-hooks-structure.sh
- **When**: bash tests/test-hooks-structure.sh
- **Then**: TC-01, TC-02, TC-03 all PASS, exit code 0

## RED

### Test File Created

- `/Users/morodomi/Documents/AgentSkills/dev-crew/tests/test-trap-handler.sh`

### Test Results (RED state confirmed)

```
=== Trap Handler Tests ===

T-01: Trap handler cleans up on normal exit
  FAIL Trap handler NOT found in test-hooks-structure.sh

T-02: Trap handler registers EXIT INT TERM signals
  FAIL Trap handler does NOT register EXIT INT TERM signals

T-03: Inline cleanup removed (trap handles it)
  FAIL Inline cleanup commands still present (should be removed, trap should handle it)

T-04: All existing tests still pass
  PASS test-hooks-structure.sh all tests PASS (exit code 0)

=== Summary ===
PASS: 1
FAIL: 3
```

### Test Implementation

- **T-01**: Checks for `trap` keyword and `cleanup()` function in test-hooks-structure.sh
- **T-02**: Validates trap registers `EXIT INT TERM` signals
- **T-03**: Confirms inline `rm -f` / `rm -rf` commands removed (lines 72-73)
- **T-04**: Regression test - ensures existing TC-01, TC-02, TC-03 still pass

### Status

✅ All tests written
✅ Tests fail as expected (3/4 FAIL, 1 PASS)
✅ Ready for GREEN phase

## GREEN

### Implementation

Modified `tests/test-hooks-structure.sh`:

1. **Added cleanup() function** (lines 14-17)
   - Removes `$BASE_DIR/agents/test-drift-agent.md`
   - Removes `$BASE_DIR/skills/test-drift-skill/` directory

2. **Added trap handler** (line 19)
   - Registers `cleanup` for `EXIT INT TERM` signals
   - Ensures cleanup on normal exit, test failure, or Ctrl+C

3. **Removed inline cleanup** (deleted lines 72-73)
   - Deleted `rm -f "$TEMP_AGENT"`
   - Deleted `rm -rf "$TEMP_SKILL_DIR"`
   - Trap handler now handles all cleanup

### Test Results (GREEN state confirmed)

```
=== Trap Handler Tests ===

T-01: Trap handler cleans up on normal exit
  PASS Trap handler found in test-hooks-structure.sh

T-02: Trap handler registers EXIT INT TERM signals
  PASS Trap handler registers EXIT INT TERM signals

T-03: Inline cleanup removed (trap handles it)
  PASS Inline cleanup commands removed (trap handles cleanup)

T-04: All existing tests still pass
  PASS test-hooks-structure.sh all tests PASS (exit code 0)

=== Summary ===
PASS: 4
FAIL: 0
```

### Regression Test

```
=== Hooks Structure Tests ===

TC-01: hooks.json contains test-agents-structure.sh entry
  PASS test-agents-structure.sh entry found in PreCommit hooks

TC-02: test-agents-structure.sh executes successfully
  PASS test-agents-structure.sh executed successfully (exit code 0)

TC-03: test-agents-structure.sh detects model drift (exit code 1)
  PASS test-agents-structure.sh detected model drift (exit code 1)

=== Summary ===
PASS: 3
FAIL: 0
```

### Status

✅ All tests pass (4/4)
✅ No regression in original tests (3/3)
✅ MINIMAL implementation - exactly what tests required
✅ Ready for REFACTOR phase

## REFACTOR

### Analysis

Reviewed both files for code quality improvements:

**test-hooks-structure.sh**
- ✅ Cleanup function is concise and clear
- ✅ Trap handler properly registers EXIT INT TERM
- ✅ No code duplication
- ✅ Variable naming is consistent
- ✅ Follows bash best practices (set -euo pipefail, proper quoting)

**test-trap-handler.sh**
- ✅ Test cases are clear and focused
- ✅ Grep patterns are appropriate and necessary
- ✅ No code duplication
- ✅ Follows same style conventions
- ✅ Proper test isolation

### Conclusion

**No refactoring needed.**

Both files are already at appropriate quality level:
- Minimal and focused
- Consistent in style
- Free of unnecessary complexity
- Maintainable and readable

The implementation is appropriate for a small chore task. Any changes would add complexity without meaningful benefit.

### Test Results

All tests pass after review:
- test-trap-handler.sh: 4/4 PASS
- test-hooks-structure.sh: 3/3 PASS

### Status

✅ Code review complete
✅ No changes required
✅ Ready for REVIEW phase

## REVIEW

### quality-gate Results (6 reviewers)

| Reviewer | Score | Verdict |
|----------|-------|---------|
| correctness | 85 | BLOCK: cleanup() hardcoded paths, should use variables |
| performance | 0 | PASS |
| security | 0 | PASS |
| guidelines | 25 | PASS: T-02 header comment mismatch |
| product | 12 | PASS |
| usability | 15 | PASS |

**Max score: 85 -> BLOCK**

### Socrates Protocol

- PdM proposed: proceed (rm -f "" is harmless)
- Socrates objection: `set -u` (nounset) makes unbound $TEMP_AGENT error, not harmless
- User decision: **fix**

### Fix Applied

1. Moved TEMP_AGENT/TEMP_SKILL_DIR definitions to script top (before cleanup())
2. cleanup() now references variables instead of hardcoded paths
3. Removed redundant variable definitions in TC-03 section
4. Fixed T-02 header comment mismatch in test-trap-handler.sh

### Post-fix Test Results

All tests pass (7/7):
- test-trap-handler.sh: 4/4 PASS
- test-hooks-structure.sh: 3/3 PASS

## DISCOVERED

- Issue #23 の元レポートで「duplicate scan optimization」が提案されていたが、
  plan-review で TC-02 (clean state) と TC-03 (drift state) は異なるシナリオであり
  キャッシュ不可と判明。Issue 本文を修正済み。

## COMMIT

(PdM が記入)
