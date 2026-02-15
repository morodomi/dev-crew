# Phase Compact Reference

## Overview

phase-compactはTDDフェーズ境界でコンテキストを永続化し、
会話履歴の圧縮を促すスキル。OpenClawのmemory flushパターンをTDDに適用。

## Compaction Points

各フェーズ遷移で永続化・復元する内容:

| Transition | Persist to Cycle Doc | Restore From |
|------------|---------------------|--------------|
| INIT -> PLAN | scope, environment, goal | Cycle doc |
| PLAN -> RED | Test List, design decisions | Cycle doc + Test List section |
| RED -> GREEN | test file paths, failure descriptions | Cycle doc + test files on disk |
| GREEN -> REFACTOR | impl file paths, test results | Cycle doc + source files on disk |
| REFACTOR -> REVIEW | refactored file list, changes summary | Cycle doc + source files on disk |
| REVIEW -> COMMIT | review score, issues found | Cycle doc + review summary |

**Note**: COMMIT はサイクルの終端。COMMIT後のphase-compactは不要（次サイクルは新しいINITで開始）。

## Phase Summary Details

### INIT -> PLAN

```markdown
### Phase: INIT - Completed at HH:MM
**Artifacts**: docs/cycles/YYYYMMDD_HHMM_feature-name.md
**Decisions**: scope=[layer], risk=[score]([verdict])
**Metrics**: line_count=[N], file_count=[N], test_count=0
**Next Phase Input**: Cycle doc ready for PLAN phase
```

### PLAN -> RED

```markdown
### Phase: PLAN - Completed at HH:MM
**Artifacts**: Cycle doc updated with PLAN section, Test List (N items)
**Decisions**: architecture=[approach], test strategy=[approach]
**Metrics**: line_count=[N], file_count=[N], test_count=[N]
**Next Phase Input**: Test List items TC-01 ~ TC-NN
```

### RED -> GREEN

```markdown
### Phase: RED - Completed at HH:MM
**Artifacts**: [test file paths]
**Decisions**: test framework=[name], N tests created, all failing
**Metrics**: line_count=[N], file_count=[N], test_count=[N]
**Next Phase Input**: test files on disk, implement to make them pass
```

### GREEN -> REFACTOR

```markdown
### Phase: GREEN - Completed at HH:MM
**Artifacts**: [implementation file paths]
**Decisions**: N/N tests passing
**Metrics**: line_count=[N], file_count=[N], test_count=[N]
**Next Phase Input**: source files on disk, refactor for quality
```

### REFACTOR -> REVIEW

```markdown
### Phase: REFACTOR - Completed at HH:MM
**Artifacts**: [refactored file paths]
**Decisions**: refactoring=[changes made or "no changes needed"]
**Metrics**: line_count=[N], file_count=[N], test_count=[N]
**Next Phase Input**: source files on disk, run quality gate
```

### REVIEW -> COMMIT

```markdown
### Phase: REVIEW - Completed at HH:MM
**Artifacts**: quality-gate results
**Decisions**: verdict=[PASS/WARN/BLOCK], score=[max score]
**Metrics**: line_count=[N], file_count=[N], test_count=[N]
**Next Phase Input**: all tests passing, ready to commit
```

## Restore Procedure

次フェーズ開始時のコンテキスト復元手順:

1. Cycle docを読み込む (`ls -t docs/cycles/*.md | head -1`)
2. Phase Summary セクションで前フェーズの成果物を確認
3. Artifacts に記載されたファイルを読み込む
4. Next Phase Input の指示に従って作業を開始

## Token Savings Estimate

| Phase Count | Without Compaction | With Compaction | Savings |
|-------------|-------------------|-----------------|---------|
| 7 phases | ~100% context | ~50% per phase | ~50% |
| + quality-gate (6 agents) | +600% subagent context | unchanged | ~70% |
| + plan-review (5 agents) | +500% subagent context | unchanged | ~70% |

## Integration with Auto-Compact

`CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` と phase-compact は独立:

| Mechanism | Trigger | Purpose |
|-----------|---------|---------|
| auto-compact | Context window usage % | 自動的な会話圧縮 |
| phase-compact | Phase boundary | 意図的な永続化 + 明示的圧縮 |

phase-compact は auto-compact の前に実行することで、
重要な情報がCycle docに永続化された状態で圧縮が行われる。

## Limitations

- `/compact` はプログラムから直接呼べない（ユーザー操作が必要）
- Phase Summary は手動で生成（LLMが現フェーズの成果を要約）
- セッション跨ぎの復元は Cycle doc + ファイルの再読み込みで対応
