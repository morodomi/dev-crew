# Cycle: PreCompact Hook + reload skill

- issue: Issue 1 from evolution plan
- status: REVIEW
- created: 2026-02-24

## Context

auto-compactがフェーズ途中で発火するとコンテキストが消失するリスクがある。手動`/compact`実行時にCycle docへの永続化を自動化し、compact後のコンテキスト復元をreloadスキルで行う。

## PLAN

### Design

**PreCompact Hook:**
- `hooks/hooks.json` に PreCompact エントリ追加（matcher: `manual`）
- `scripts/hooks/pre-compact.sh` を作成
  - 最新Cycle doc特定
  - Cycle docが存在しない場合 → exit 0（no-op）
  - Progress Logに `YYYY-MM-DD HH:MM - PreCompact: phase=[PHASE], snapshot saved` を追記
  - 常にexit 0

**reload skill:**
- `skills/reload/SKILL.md` を新規作成
- Cycle docからコンテキストを復元
- トリガー: `reload`, `コンテキスト復元`

### Test List

- [ ] TC-01: hooks.json has PreCompact entry
- [ ] TC-02: PreCompact matcher is "manual"
- [ ] TC-03: PreCompact command references pre-compact.sh with ${CLAUDE_PLUGIN_ROOT}
- [ ] TC-04: pre-compact.sh exists and is executable
- [ ] TC-05: pre-compact.sh exits 0 when no Cycle doc exists
- [ ] TC-06: pre-compact.sh appends Progress Log entry when Cycle doc exists
- [ ] TC-07: Progress Log entry contains phase and timestamp
- [ ] TC-08: skills/reload/ directory exists
- [ ] TC-09: reload SKILL.md exists and < 100 lines
- [ ] TC-10: reload SKILL.md has name/description frontmatter
- [ ] TC-11: reload SKILL.md contains Workflow section
- [ ] TC-12: reload SKILL.md references Cycle doc loading
- [ ] TC-13: hooks.json is valid JSON
- [ ] TC-14: Existing structure validation still passes

## RED

tests/test-precompact-reload.sh created with 14 test cases. All failed as expected.

## GREEN

- hooks/hooks.json: Added PreCompact entry (matcher: "manual")
- scripts/hooks/pre-compact.sh: Created - reads latest Cycle doc, appends Progress Log entry
- skills/reload/SKILL.md: Created - context restore workflow after /compact
- CLAUDE.md: Updated project structure and skills table

## REFACTOR

No refactoring needed. Changes are minimal and focused.

## REVIEW

All 14 new tests pass. All 10 existing hooks tests pass. Structure validation passes.

## DISCOVERED

(none)
