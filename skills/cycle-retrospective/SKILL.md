---
name: cycle-retrospective
description: "TDD サイクル末尾で「最初の失敗 → 最終解 → 事前知識化」のペアを抽出する advisory スキル。失敗-成功ペアの言語化に特化、dedup/codify 分類は codify-insight (Cycle B) に委譲。「retrospective」「振り返り」「サイクル振り返り」で起動。"
allowed-tools: Read, Edit, AskUserQuestion
---

# cycle-retrospective

## Workflow

### Hard Gate

- Cycle doc が **存在するか** のみ check (phase 値は問わない、advisory なので REVIEW 中・DONE 後・任意のタイミング許可)
- Cycle doc 不在 → BLOCK: 「先に spec/orchestrate を実行してください」
- 存在すれば phase に関わらず続行 (実際の重複防止は Idempotency Check で行う)

### Idempotency Check

- frontmatter `retro_status` が `none` 以外 (captured / resolved / フィールド不在) → skip + 「既に処理済み (retro_status: $value)」を出力して exit 0
- `retro_status: none` の場合のみ抽出フェーズへ進む

### Extraction (LLM)

- Cycle doc 全体を読む (plan / phase summaries / review verdicts / test failures / retry log / DISCOVERED)
- Failure → Final fix → Insight ペアを抽出 (詳細手順: reference.md)
- 抽出失敗 → retry N=2 → 全失敗時は AskUserQuestion で override (proceed / abort)

### Output (Cycle doc 更新)

state-ownership.md の cycle-retrospective 行に従う:

- **Body**: `## Retrospective` を Cycle doc EOF (`## Next Steps` の後) に append (APPEND-ONLY 遵守、middle-insert 禁止、既存内容は一切変更しない)
- **frontmatter**: `retro_status` (none → captured / none → resolved) と `updated` のみ更新
  - `captured`: 有効な insight を追記した場合
  - `resolved`: no-lesson / override-proceed (`Extraction skipped by override` または `Extraction failed after N retries`) の場合
- **abort 選択時**: Cycle doc は変更せず、stderr に「Retrospective aborted by user. orchestrate should BLOCK commit.」を出力して exit 1

## Reference

詳細: [reference.md](reference.md)
