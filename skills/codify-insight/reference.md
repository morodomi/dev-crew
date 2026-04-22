# codify-insight Reference

## Annotation Format

`## Codify Decisions` セクションは Cycle doc の EOF に append する (APPEND-ONLY contract)。
既存 `## Retrospective` セクションは変更しない (Retrospective 不変)。

```markdown
## Codify Decisions

### Insight 1
- **Decision**: codified
- **Destination**: rule
- **Reason**: (optional for codified/no-codify, REQUIRED for deferred)
- **Decided**: YYYY-MM-DD HH:MM

### Insight 2
- **Decision**: deferred
- **Reason**: 別 cycle で実装予定 (required for deferred)
- **Decided**: YYYY-MM-DD HH:MM
```

## Fixed Decision Markers (contract-enforced, 変更禁止)

| Marker | Reason | Destination |
|--------|--------|-------------|
| `codified` | — | rule / skill / instinct / new-cycle / inline-update |
| `deferred` | REQUIRED | — |
| `no-codify` | optional | — |

3 canonical strings: `codified` / `deferred` / `no-codify`。言い換え禁止。

## AskUserQuestion Options (verbatim)

```
1. codify now
2. defer with reason
3. no-codify
```

`defer with reason` 選択時: reason 入力必須。未入力は再確認する。
`no-codify` 選択時: reason 入力は optional。

## APPEND-ONLY Contract

- 既存 `## Retrospective` セクションは **一切変更しない** (existing content unchanged)
- `## Codify Decisions` は Cycle doc の新しい EOF セクションとして append
- per-insight inline annotation は禁止 (APPEND-ONLY 違反)
- `### Insight N` heading が `## Codify Decisions` 内に存在する = 判定済み (idempotency)

## State Transition

`retro_status: captured` → `resolved` へ遷移するトリガ: **全 insight 判断完了時 (all insights judged)**。
partial 判定では captured を維持し、再実行で残 insight のみ処理する。

遷移時: `retro_status` と `updated` を frontmatter で更新。

## No Captured Cycles

captured cycles が見つからない場合 → no-op exit 0:

```
No captured cycles found. Nothing to codify.
```

ログ出力のみ、Cycle doc 変更なし。

## `codified` Marker MVP 意味論 (ADR-002 との scope 差)

`codified` は「user がこの insight を codify すると判断した」ことの記録。
destination を明記して作業方向を固定する (judgment-only record)。

実際のコード書き出しは follow-up 作業 (user が次 cycle で実施)。
orchestrate の新 cycle 起票 or 手動 edit で実施する。

ADR-002 L86「codify 実行は強制しない」との整合。

## Failure Modes

| 状況 | 対応 |
|------|------|
| `retro_status: none` cycle | skip |
| `retro_status: resolved` cycle | skip (idempotent) |
| `## Retrospective` セクション空 | data integrity warning + skip |
| User mid-gate abort | partial annotations 残す、frontmatter 遷移なし |
| 複数 captured cycles | filename sort order (chronological) で順次処理 |
| rejected insight | instinct/learn/evolve に自動送りしない (ADR-002 L33) |
