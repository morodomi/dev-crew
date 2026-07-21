---
paths:
  - "docs/cycles/**"
---
# Doc Mutations — Cycle doc と plan file の不変性規則

Cycle doc の APPEND-ONLY 契約と plan file の IMMUTABLE 制約。情報の SSOT を守ることで drift を防ぐ。

## APPEND-ONLY 契約 (cycle 20260422_1146 #3)

Cycle doc の body は APPEND-ONLY。既存セクション内への middle-insert は違反:

- **禁止**: 既存 `## Progress Log` エントリの間に新エントリを挿入する
- **禁止**: 既存 Test List の TODO 項目を直接書き換える (状態遷移は WIP / DONE への移動のみ)
- **代替**: 新情報は常に EOF 方向の独立セクションとして追記する。既存 item を参照する場合は heading 名で言及する

## Plan File — 承認前は可変、承認後は IMMUTABLE (cycle 20260422_1146 #4; cycle 20260717_1126 #2 で承認前/承認後の分岐を明確化)

plan approve 後は plan file を編集しない (`rules/state-ownership.md` L7-10 準拠)。**承認前は可変、承認後は IMMUTABLE** という片方向切替が本節の核:

- **承認前**: Codex plan review（spec Step 8）の findings は draft plan へ**直接反映**する。plan は承認前のため可変であり、これが正規の反映先
- **承認後**: plan file を編集しない（禁止）。承認後に発生した findings（architect の Post-Transfer Verification 等）は以下の 3 分岐で処理する

| 分岐 | 条件 | 反映先 |
|------|------|--------|
| 転記欠落 | Plan Review Record が Cycle doc に未反映 | sync-plan を再実行し Cycle doc へ反映（plan file には触れない） |
| scope 実質変更 | 承認済み scope からの逸脱 | 再承認（AskUserQuestion）。plan file は不変のまま Cycle doc に記録 |
| 観察のみ | 軽微な観察事項 | Cycle doc の DISCOVERED セクションに記録 |

- **根拠**: 同じ情報を 2 箇所 (plan file + Cycle doc) に持つと必ず drift する。承認前は plan が SSOT（可変）、承認後は Cycle doc が SSOT（plan は freeze）という片方向切替で drift を防ぐ

## 推奨

- Cycle doc の更新は常に追記方向。過去ログの書き換えは禁止
- plan file は approve スナップショットとして freeze。読み取り専用で参照する
- Codex review 指摘の適用先: 承認前は draft plan へ直接反映、承認後は Cycle doc の該当セクション（3 分岐に従う）

## SSOT 即時同期 (cycle 20260422_1313 #2)

GREEN phase の collateral fix (scope +1) は検出した瞬間に Cycle doc Files list も即時更新する。「GREEN 完了後まとめて更新」は drift を生む。orchestrator (PdM) の責務: scope 変更の瞬間に SSOT を sync する規律。SSOT 宣言は片方向更新の discipline を要求し、更新タイミングをフェーズ終了時に遅延させると必ず drift する。

フェーズを実行した主体がそのフェーズで完了した Test List 遷移まで行う。遷移の先送りは Codex review BLOCK の実害を生んだ (cycle 20260703_1650 #2)。

## Frontmatter 遷移の区間限定編集 (cycle 20260703_2035 #1)

frontmatter の状態遷移（phase / retro_status / updated）は frontmatter 区間限定で編集する:

- **禁止**: 全文一括置換（whole-file str.replace / sed 全域置換）での frontmatter 遷移。本文中の記録的言及（Progress Log の「retro_status: none」等）を巻き込み、commit 済み本文の無言書き換えを生む
- **正しい対応**: 行頭アンカー + count=1 の区間限定置換（re.MULTILINE の `^...$` 一致）、または awk 区間抽出で frontmatter のみを対象にする
- 根拠: cycle doc は「状態」と「状態についての記録」が同居する文書。状態遷移操作は構造を認識して行う

## Cycle 参照 format (cycle 20260422_1313 #5)

rule 内の cycle 参照は **full filename prefix** (例: `20260422_1313`) または **cycle_id frontmatter 値** を使う。informal 略称 (eval-N、A2b、Cycle B) は会話では許容だが永続 artifact (rule/doc) では使わない。cross-reference は絶対識別子で行う。

## 出典

- `docs/cycles/20260422_1146_codify-insight-skill.md` Insights 3, 4
- `docs/cycles/20260422_1313_rule-docs-codify-followup.md` Insight 2 — GREEN collateral fix は Cycle doc Files list を即時同期
- `docs/cycles/20260422_1313_rule-docs-codify-followup.md` Insight 5 — cycle 参照は full filename or cycle_id のみ使用
- cycle 20260703_1650 #2 — フェーズ実行主体が Test List 遷移まで担う
- cycle 20260703_2035 #1 — frontmatter 遷移の区間限定編集（全文一括置換の本文汚染）
- cycle 20260717_1126 #2 — Plan File の承認前/承認後分岐（Codex plan review の承認前移動 + 承認後 3 分岐）
