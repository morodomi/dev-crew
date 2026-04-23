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

## Default Mode: Autonomous Batch Triage

default は autonomous。per-insight AskUserQuestion を標準動作にしない。
1 cycle 分の insights をまとめて判断し、`## Codify Decisions` を一括で追記する。

AskUserQuestion は fallback のみ:
- `skill` destination candidate
- `codified` vs `deferred` が low confidence
- user が interactive codify を明示要求

質問が必要でも 1 insight ごとではなく、1 cycle につき 1 回の batch 確認を優先する。

## Recurrence-aware Pre-triage (質問スキップ)

autonomous triage の前段で過去 cycle との recurrence を検査し、確信度の高い insight を自動処理して質問機会を減らす。

### Scan 範囲

直近 10 cycle docs (ファイル名 chronological 降順) の以下 2 section を対象:
- `## Retrospective` の `### Insight N:` heading title + 本文 key phrase
- `## Codify Decisions` の `### Insight N` の `Decision` / `Destination` / `Reason`

### 頻度閾値 (frequency_threshold)

default: **2 回**。同じ insight key phrase が過去 N cycles で threshold 以上 hit した場合、promotion 対象とする。

| Hit count | 自動判定 | 理由 |
|-----------|---------|------|
| 0 (novel) | autonomous triage へ | 初出、通常判断 |
| 1 | autonomous triage へ | 再発未確定、通常判断 |
| 2+ (codified 実績あり) | `no-codify` (duplicate) | 既に rule 化済 |
| 2+ (codified 実績なし) | `codified` → `rule` (promotion) | 再発確定、rule 昇格 |
| 1+ で過去 `no-codify` 判定 | `no-codify` (duplicate negative) | 繰り返し no-codify と判定済 |

### Key phrase 抽出

- `### Insight N: <title>` の title 部分を取得
- title 冒頭 20 文字 + 主要 noun 2-3 語を signature とする
- signature で `grep -F` 相当の部分一致 scan (過剰 match を避けるため正規表現は避ける)

### Question 0 件の条件

以下すべて満たすと AskUserQuestion を実行しない:
- pre-triage ですべての insight が recurrence 判定済み
- 残りの autonomous triage が全て high-confidence (skill candidate なし、codified vs deferred 境界曖昧なし)
- user が interactive codify を要求していない

この場合 `## Codify Decisions` を書き出して summary のみ print。

## TDD Timing Heuristics

- pre-TDD / 次 cycle hardening（gate, checklist, prompt, test discipline）→ `codified` + `rule` or `inline-update`
- post-TDD の広い改善や follow-up が必要なもの → `deferred`（通常 `new-cycle`）
- observation-only / duplicate / 2nd-order note → `no-codify`
- `skill` は rare。2+ cycles 再発かつ複数 phase / repo で再利用できる workflow の時だけ選ぶ

## AskUserQuestion Options (verbatim, fallback only)

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

`codified` は「この insight を codify すると判断した」ことの記録（AI 自動 triage / user 確認のどちらでも可）。
destination を明記して作業方向を固定する (judgment-only record)。

実際のコード書き出しは follow-up 作業（次 cycle / 手動 edit / 別 skill で実施）。
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
