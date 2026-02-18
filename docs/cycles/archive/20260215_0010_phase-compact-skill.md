# Cycle: Phase-Compact Skill

## Metadata
- **Issue**: #2
- **Created**: 2026-02-15 00:10
- **Risk**: 30 (WARN)
- **Scope**: Markdown skill definition (SKILL.md + reference.md)

## Environment
- OS: macOS Darwin 25.2.0 (arm64)
- Project: dev-crew (Claude Code Plugin)
- Predecessor: #1 structure validation tests (DONE)

## Goal

TDDフェーズ境界でのcontext compactionスキルを新規作成する。
各フェーズ完了時にCycle docにPhase Summaryを永続化し、
compact後に次フェーズがCycle docからコンテキストを復元できるようにする。

## Scope

### In Scope
- `skills/phase-compact/SKILL.md` (< 100行)
- `skills/phase-compact/reference.md` (詳細仕様)

### Out of Scope
- orchestrateとの統合 (#3)
- auto-compact設定
- StatusLine連携

## Design Decisions
- `/compact` はプログラムから呼べないため、ユーザーに実行を促す方式
- Phase Summaryは Cycle doc に追記する形式
- 復元はCycle doc読み直しで行う

## PLAN

### 設計方針

既存フェーズスキル(init, plan, red, green, refactor, review, commit)と同じ構造:
- SKILL.md: ワークフロー概要、Progress Checklist、Phase Summary format
- reference.md: Compaction Points詳細、各フェーズの永続化/復元仕様

### ファイル構成

```
skills/phase-compact/
├── SKILL.md          # < 100行。ワークフロー + Phase Summary template
└── reference.md      # Compaction Points table + restore手順
```

### Phase Summary Format (SKILL.md で定義)

```markdown
### Phase: [PHASE_NAME] - Completed at HH:MM
**Artifacts**: [file list]
**Decisions**: [key decisions made]
**Next Phase Input**: [what next phase needs]
```

### Compaction Points (reference.md で定義)

| Transition | Persist to Cycle Doc | Restore from |
|------------|---------------------|--------------|
| INIT -> PLAN | scope, env | Cycle doc |
| PLAN -> RED | Test List | Cycle doc + Test List |
| RED -> GREEN | test file paths | Cycle doc + test files on disk |
| GREEN -> REFACTOR | impl file paths | Cycle doc + source files on disk |
| REFACTOR -> REVIEW | refactored file paths | Cycle doc + source files on disk |
| REVIEW -> COMMIT | review summary | Cycle doc + review |

### Workflow (3 steps)

1. Cycle doc の現フェーズ Progress を `[x]` に更新
2. Phase Summary を Cycle doc に追記
3. ユーザーに `/compact` 実行を促す + 次フェーズ案内

## Test List

### TODO
- [ ] TC-01: [正常系] skills/phase-compact/ ディレクトリが存在すること
- [ ] TC-02: [正常系] SKILL.md が存在し100行以下であること
- [ ] TC-03: [正常系] SKILL.md に name/description frontmatter があること
- [ ] TC-04: [正常系] SKILL.md に Phase Summary format テンプレートが含まれること
- [ ] TC-05: [正常系] SKILL.md に Workflow セクションが含まれること
- [ ] TC-06: [正常系] reference.md が存在すること
- [ ] TC-07: [正常系] reference.md に Compaction Points テーブルが含まれること
- [ ] TC-08: [正常系] reference.md に全6遷移 (INIT->PLAN ~ REVIEW->COMMIT) が定義されていること
- [ ] TC-09: [正常系] 既存構造バリデーションテスト(test-skills-structure.sh)が通ること
- [ ] TC-10: [異常系] Phase Summary format の必須フィールド欠損を検出できること

## Progress

- [x] INIT
- [x] PLAN
- [x] RED (8 FAIL / 2 PASS - skill not yet created)
- [x] GREEN (10/10 PASS)
- [x] REFACTOR (変更なし)
- [x] REVIEW (quality-gate PASS: score 25)
- [x] COMMIT
