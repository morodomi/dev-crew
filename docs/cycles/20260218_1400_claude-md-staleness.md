# Cycle: CLAUDE.md 陳腐化警告 pre-commit hook

- **Issue**: #31
- **Phase**: REVIEW
- **Created**: 2026-02-18

## Goal

CLAUDE.md の最終更新が30日以上前の場合に警告を表示する pre-commit hook を追加する。
commit はブロックしない (常に exit 0)。

## Design

### 変更ファイル

| File | Action |
|------|--------|
| `scripts/hooks/check-claude-md-staleness.sh` | NEW |
| `hooks/hooks.json` | MODIFY (3rd PreCommit entry) |
| `tests/test-hooks-structure.sh` | MODIFY (TC-04~06) |

### Test List

- TC-04: hooks.json に check-claude-md-staleness.sh エントリがある
- TC-05: CLAUDE.md が最近更新されている場合、警告なしで exit 0
- TC-06: STALENESS_THRESHOLD_DAYS=0 設定時、警告メッセージを出力
