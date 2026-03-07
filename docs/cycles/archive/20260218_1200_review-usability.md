# Cycle: Review Usability 改善

- issue: #37
- phase: COMMIT
- started: 2026-02-18 12:00

## Context

v2 restructuring の quality-gate レビューで usability-reviewer が WARN (score 62) を出した。
指摘: mode判定が暗黙的、BLOCK復帰フローが mode別に明示されていない。

## Scope

### In Scope
- review/SKILL.md: mode 明示出力 + BLOCK mode 別復帰
- review/steps-subagent.md: mode 通知 + BLOCK 出力テンプレート
- review/reference.md: BLOCK Recovery セクション追加
- tests/test-v2-restructuring.sh: TC-27~30 追加

### Out of Scope
- agent出力形式統一 (Issue #18 で解決済み)

## PLAN

### Test List
- TC-27: SKILL.md Step 0 に `[REVIEW] Mode:` 出力指示がある
- TC-28: SKILL.md Step 5 BLOCK 行に plan/code 別復帰がある
- TC-29: steps-subagent.md に `[REVIEW] Mode:` 通知指示がある
- TC-30: reference.md に BLOCK Recovery セクションがある

### Files to Change
- MODIFY: skills/review/SKILL.md (+3 lines)
- MODIFY: skills/review/reference.md (+24 lines)
- MODIFY: skills/review/steps-subagent.md (+21 lines)
- MODIFY: tests/test-v2-restructuring.sh (+62 lines)

## Progress Log

- 2026-02-18 12:00 RED: TC-27~30 追加、4/4 FAIL 確認
- 2026-02-18 12:05 GREEN: 4ファイル修正、30/30 PASS
- 2026-02-18 12:10 REFACTOR: 旧表現「前フェーズに戻る」をreference.mdから除去、全テスト PASS
- 2026-02-18 12:15 REVIEW: 全21テストスイート PASS (240 tests)、SKILL.md 86行 (< 100)

## DISCOVERED

(none)
