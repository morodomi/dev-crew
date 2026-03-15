---
feature: ask-codex-delegation-preference
cycle: 20260315_1412
phase: DONE
complexity: standard
test_count: 11
risk_level: low
created: 2026-03-15 14:12
updated: 2026-03-15 14:12
---

# feat: ask Codex delegation preference at plan-review time (#53)

## Scope Definition

### In Scope
- [ ] PHILOSOPHY.md フロー図修正
- [ ] skills/spec/reference.md Post-Approve Action 修正
- [ ] skills/orchestrate/steps-codex.md に委譲モード分岐を追加
- [ ] skills/orchestrate/reference.md TDD Gate セクション更新
- [ ] tests/test-codex-delegation-preference.sh 新規作成

### Out of Scope
- 実装コード（Shell スクリプト等）の変更 (Reason: ドキュメント・設定変更のみのフィーチャー)
- Codex 本体の挙動変更 (Reason: スコープ外)

### Files to Change (target: 10 or less)
- docs/PHILOSOPHY.md (edit)
- skills/spec/reference.md (edit)
- skills/spec/reference.ja.md (edit)
- skills/orchestrate/steps-codex.md (edit)
- skills/orchestrate/reference.md (edit)
- skills/orchestrate/SKILL.md (edit)
- tests/test-codex-delegation-preference.sh (new)

## Environment

### Scope
- Layer: Documentation + Configuration
- Plugin: dev-crew
- Risk: 20 (PASS - ドキュメント修正のみ、ロジック変更なし)

### Runtime
- Language: Shell (tests), Markdown (skills/docs)

### Dependencies (key packages)
- なし

### Risk Interview (BLOCK only)
(N/A - Risk: PASS)

## Context & Dependencies

### Reference Documents
- [docs/PHILOSOPHY.md] - フロー図の修正対象
- [skills/spec/reference.md] - Post-Approve Action 修正対象
- [skills/orchestrate/steps-codex.md] - 委譲モード分岐の追加対象
- [skills/orchestrate/reference.md] - TDD Gate セクション更新対象

### Dependent Features
- Post-Approve ordering (#54): 直前サイクルで Post-Approve Action の順序を修正済み

### Related Issues/PRs
- Issue #53: ask Codex delegation preference at plan-review time

## Test List

### TODO
- [ ] TC-01: steps-codex.md Pre-check に委譲モード確認がある（AskUserQuestion or Cycle doc読み取り）
- [ ] TC-02: steps-codex.md Pre-check に "full" と "no" の選択肢がある
- [ ] TC-03: steps-codex.md Gate 1 に "full" 時スキップの条件が記載されている
- [ ] TC-04: steps-codex.md Gate 2 に "full" 時スキップの条件が記載されている
- [ ] TC-05: steps-codex.md Test Plan整合性チェックは常時実行（"常時" or 無条件）
- [ ] TC-06: reference.md TDD Gate に委譲モード説明がある
- [ ] TC-07: spec reference.md Post-Approve Action で sync-plan が plan-review より前にある
- [ ] TC-08: spec reference.md Post-Approve Action に Codex 委譲確認ステップがある
- [ ] TC-09: PHILOSOPHY.md フロー図で sync-plan が plan-review より前にある
- [ ] TC-10: PHILOSOPHY.md フロー図に Claude plan-review がある
- [ ] TC-11: 既存テスト test-orchestrate-codex.sh が通る (regression)
- [ ] TC-12: SKILL.md Mode Selection にユーザー選択優先のルールがある
- [ ] TC-13: spec reference.ja.md Post-Approve Action が reference.md と同じ順序である

### WIP
(none)

### DISCOVERED
(none)

### DONE
(none)

## Implementation Notes

### Goal
Post-Approve フローで Codex 委譲モードをユーザーに確認し、full/partial/none の選択結果を orchestrate に渡す。これにより、Codex を使いたくないケースや部分委譲ケースを明示的に制御できる。

### Background
現状の Post-Approve フローは Codex 利用可否を `which codex` で自動判定するが、ユーザーが明示的に委譲モードを選べない。plan-review 時点でユーザーに確認することで、意図しない自動委譲を防ぐ。

直前サイクル (#54) で Post-Approve Action の順序（plan-review → sync-plan）を修正済み。本サイクルはその順序を前提として委譲確認ステップを追加する。

### Design Approach
- plan-review 完了後、orchestrate 起動前に委譲モードを確認する
- 選択肢: full（全フェーズ Codex、Gate省略）/ no（Claude fallback）
- 選択結果は Cycle doc frontmatter の `codex_mode` に記録し compact 後も復元
- SKILL.md のディスパッチルールもユーザー選択を優先するよう変更
- Test Plan 整合性チェックは常時実行（委譲モードに関わらず）
- reference.ja.md も同期更新してドリフト防止

## Progress Log

### 2026-03-15 14:12 - INIT
- Cycle doc created
- Scope definition ready

---

## Next Steps

1. [Done] INIT <- Current
2. [Done] PLAN
3. [Next] RED
4. [ ] GREEN
5. [ ] REFACTOR
6. [ ] REVIEW
7. [ ] COMMIT
