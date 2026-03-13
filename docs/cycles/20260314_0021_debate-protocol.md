---
feature: debate-protocol
cycle: 20260314_0021
phase: DONE
complexity: trivial
test_count: 9
risk_level: low
created: 2026-03-14 00:21
updated: 2026-03-14 00:58
---

# Debate Protocol (kickoff拡張)

## Scope Definition

### In Scope
- [ ] kickoff SKILL.md: debateステップ追加（Codex有無チェック + debate呼び出し or plan-reviewフォールバック）
- [ ] kickoff reference.md: debateワークフロー詳細（Codex呼び出し、ラリーロジック、収束判断、不明点の選択方式表示、結果のCycle doc追記）
- [ ] docs/decisions/ 運用ルール: reference.mdにADRテンプレートとガイドライン記載（ディレクトリ作成は初回debate時）
- [ ] ROADMAP.md: Phase 2ステータス更新
- [ ] CLAUDE.md: kickoff説明にdebate言及追加

### Out of Scope
- 新規スキル・エージェント作成（kickoff拡張で収まる前提）
- Phase 4 (Workflow Integration: RED/GREEN委譲)
- Phase 5 (Decision Records の自動化)
- socrates.mdの変更（既存のClaude Code単体反論役として維持）

### Files to Change (5)
- skills/kickoff/SKILL.md (edit)
- skills/kickoff/reference.md (edit)
- ROADMAP.md (edit)
- CLAUDE.md (edit)
- AGENTS.md (edit)

## Environment

### Scope
- Layer: Plugin
- Plugin: dev-crew (skill definition)
- Risk: 15 (PASS)

### Runtime
- Language: Markdown (skill definitions)

### Dependencies (key packages)
- codex CLI: optional (debate skipped if absent)

### Risk Interview (BLOCK only)
N/A (PASS)

## Context & Dependencies

### Reference Documents
- [ROADMAP.md](../../ROADMAP.md) - Multi-AI Orchestration roadmap, Phase 2 spec
- [skills/kickoff/SKILL.md](../../skills/kickoff/SKILL.md) - Current kickoff workflow
- [skills/kickoff/reference.md](../../skills/kickoff/reference.md) - Current kickoff reference

### Dependent Features
- sync-skills (Phase 1): DONE

### Related Issues/PRs
- ROADMAP Phase 2: kickoff debate integration

## Test List

### TODO
- [ ] TC-01: [正常系] kickoff SKILL.mdにStep 3.5が存在し、Codexチェック→debate or plan-reviewフォールバックの分岐が記述されている
- [ ] TC-02: [正常系] reference.mdにDebate Workflowセクションが存在し、Round Loop / Human Clarification / Result Recording / ADRの4サブセクションがある
- [ ] TC-03: [正常系] reference.mdのcodex execコマンドが--full-autoフラグを含む
- [ ] TC-04: [正常系] reference.mdにresume --lastパターンが記述されている
- [ ] TC-05: [正常系] reference.mdにmax 3ラウンドの収束条件が明記されている
- [ ] TC-06: [正常系] reference.mdにADRテンプレートとADR作成条件が記述されている
- [ ] TC-07: [正常系] ROADMAP.mdのPhase 2がDONEまたはin-progressに更新されている
- [ ] TC-08: [境界値] kickoff SKILL.mdが100行以内に収まっている
- [ ] TC-09: [異常系] Codex不在時のplan-reviewフォールバックがSkill.mdに明記されている

### WIP
(none)

### DISCOVERED
(none)

### DONE
(none)

## Implementation Notes

### Goal
kickoffスキルを拡張し、Cycle doc作成後にCodexとの反論ラリーを行う。Sub AI不在時は既存plan-review（Claude Code単体critique）にフォールバック。

### Background
ROADMAP Phase 2。現在kickoffは4ステップ（plan読み取り → Cycle doc生成 → Test List転記 → 完了）。ここにdebateステップを追加する。

### Design Approach
kickoff SKILL.mdにStep 3.5としてdebate呼び出しを追加。debate本体のワークフロー詳細はreference.mdに記載（Progressive Disclosure）。

### Debate Summary (REVIEW)
- Rounds: 1 (Claude Code design-reviewer + Codex)
- Codex Session: 019ce7cc-bae3-78b2-8eb9-87c3c25ef96f
- Accepted:
  - フォールバック: skip → 既存plan-review（Claude Code単体critique）に変更
  - 収束状態: Acknowledged廃止 → Accepted/Rejected/Deferred（ROADMAP準拠）
  - ROADMAP Phase 2定義: "Debate Skill" → "kickoff拡張でのdebate統合"に更新
  - Human Clarificationにフリーフォーム逃げ道を追加
- Rejected:
  - `which codex`が弱いチェックという指摘: optional機能なので十分。認証失敗時はcodex exec自体がエラーになり、そこでスキップすればよい
  - 独立スキルにすべきという指摘: kickoff内で100行に収まるなら統合でよい（人間判断）
  - テストが構造チェックのみという指摘: スキル定義変更のみなので構造テストで十分
- Deferred: なし

## Progress Log

### 2026-03-14 00:21 - KICKOFF
- Cycle doc created
- Scope definition ready
- Test List transferred (9 items)
- Phase completed

### 2026-03-14 00:21 - RED
- Test script created: tests/test-kickoff-debate.sh (9 tests, all failing)
- Docs-only cycle: RED/GREEN combined (test creation + implementation in same step)
- Phase completed

### 2026-03-14 00:39 - GREEN
- 5 files edited: SKILL.md, reference.md, ROADMAP.md, CLAUDE.md, AGENTS.md
- All 9 debate tests passing
- Existing structure tests (TC-08~TC-14) passing. TC-B1/B2 pre-existing bug (CLAUDE.md @AGENTS.md import)
- Phase completed

### 2026-03-14 00:42 - REFACTOR
- /simplify: Fixed set -e bug in test script (grep && var=true → if/then, 7 occurrences)
- Skipped: ADR template duplication (different contexts), test merging (traceability)
- Verification Gate passed (9/9 PASS)
- Phase completed

### 2026-03-14 00:48 - REVIEW
- review(code) score:31 verdict:WARN→PASS (after fixes)
- security-reviewer: PASS (0), correctness-reviewer: WARN (62→fixed)
- Fixed: TC-02 comment (4→5 subsections), fallback result recording, Deferred loop flow, resume --last note
- Phase completed

### 2026-03-14 00:58 - COMMIT
- All changes committed
- Phase completed

---

## Next Steps

1. [Done] KICKOFF
2. [Done] RED
3. [Done] GREEN
4. [Done] REFACTOR
5. [Done] REVIEW
6. [Done] COMMIT
