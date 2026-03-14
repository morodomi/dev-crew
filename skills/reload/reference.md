# Reload Reference

## Context Restoration Details

### Cycle Doc Parse Specification

reload は Cycle doc の以下のセクションを順にパースする:

| Section | Parse Target | Required |
|---------|-------------|----------|
| frontmatter `status:` | 現在のフェーズ (INIT/RED/GREEN/REFACTOR/REVIEW) | Yes |
| Context | スコープ、環境情報 | Yes |
| PLAN > Test List | テスト項目一覧 | Yes |
| Phase Summary > Artifacts | ファイルパス一覧 | No |
| Phase Summary > Decisions | 設計判断の記録 | No |
| Progress Log | 最新エントリ | No |

### Frontmatter Format

```yaml
---
title: "Cycle description"
status: RED
created: 2024-01-01T10:00:00
---
```

`status` の有効値: `INIT`, `RED`, `GREEN`, `REFACTOR`, `REVIEW`

### Artifacts Loading

Phase Summary の Artifacts セクションに記載されたファイルパスを Read で読み込む。

```markdown
### Phase: RED - Completed at 14:30
**Artifacts**: tests/feature_test.py, src/feature.py
```

- パスはプロジェクトルートからの相対パス
- 存在しないファイルはスキップし、警告を表示
- 読み込み順は記載順

## Error Handling

| Scenario | Action |
|----------|--------|
| Cycle doc が見つからない | 「Cycle docが見つかりません」メッセージを表示して終了 |
| `docs/cycles/` ディレクトリが存在しない | 同上 |
| frontmatter に `status` がない | 最新の Phase Summary から推定 |
| Artifacts のファイルが存在しない | 警告を表示してスキップ、他のファイルは読み込み継続 |
| Cycle doc が空 | 「Cycle docが空です」メッセージを表示して終了 |

## Phase to Next Action Mapping

| Current Phase | Next Action | Command |
|---------------|-------------|---------|
| INIT | plan modeで設計を継続 | EnterPlanMode |
| RED | 実装を開始 | /green |
| GREEN | 品質改善 | /refactor |
| REFACTOR | レビュー | /review |
| REVIEW | コミット | /commit |

## Output Format

```
================================================================================
Context Reload Complete
================================================================================
Cycle doc: docs/cycles/20240101_1000_feature.md
Phase: RED
Scope: Add login validation
Artifacts loaded: 3 files
  - tests/test_login.py (OK)
  - src/login.py (OK)
  - src/validator.py (NOT FOUND - skipped)
Next action: /green で実装を開始
================================================================================
```
