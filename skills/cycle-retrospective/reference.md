# cycle-retrospective — Reference

詳細設計と実装仕様。SKILL.md のワークフローを補足する。

## 抽出アルゴリズム (mizchi/retrospective-codify 方式)

失敗-成功ペアの言語化に特化した 3 ステップ:

1. **失敗の言語化**: 最初に試みた実装・アプローチと、それがどう失敗したかを具体的に記述する
2. **最終解の言語化**: 最終的に成功した実装・アプローチを 1-2 文で記述する
3. **事前知識化**: 「次回この課題に取り組む自分に何を伝えるか」を指示形 1-3 文で記述する
4. **想起漏れの言語化**: 今回の手戻りは、過去のどの cycle doc を最初に読んでいれば防げたか（該当なし可）。回答は `## Retrospective` 内の `### 想起漏れ` に固定 2 行スキーマで記録する（下記出力テンプレート参照）

### 抽出ソース

Cycle doc の以下セクションをスキャン:

| ソース | 着目点 |
|--------|--------|
| Test List FAIL → PASS 遷移 | どのテストが最初に失敗し、何で解決されたか |
| Progress Log | retry / workaround / 試行錯誤の痕跡 |
| Phase Summaries | 各フェーズの失敗・修正の記録 |
| DISCOVERED | 設計上の想定外・制約の発見 |
| Review verdicts | レビューで指摘された問題と修正 |

## 出力テンプレート

```markdown
## Retrospective

### Insight 1

- **Failure**: <最初の試行と失敗内容>
- **Final fix**: <最終的に効いた解>
- **Insight**: <次回の自分への指示形 1-3 文>

### Insight 2

- **Failure**: ...
- **Final fix**: ...
- **Insight**: ...

### 想起漏れ

- **設問**: 今回の手戻りは、過去のどの cycle doc を最初に読んでいれば防げたか
- **回答**: 該当なし
```

`### 想起漏れ` は固定 2 行スキーマ（設問行 + 回答行）。回答行は行全体が `- **回答**: 該当なし` または `- **回答**: docs/cycles/<filename>.md`（複数時は `docs/cycles/a.md, docs/cycles/b.md` のカンマ区切り）に一致すること。他の表現・自由文で置き換えてはならない。手戻りゼロの cycle でも沈黙せず `該当なし` を明示記録する。

集計手順（10 サイクル計測の機械集計契約）: cycle doc 本文には plan 転記・例示の fenced テンプレートが含まれ得るため、whole-file grep は誤取得する。**最後の** `^## Retrospective$` セクション（EOF append 契約により実 Retrospective は常に最後）を先に抽出してから区間内を検査する:

```bash
# $cycle_doc は対象 cycle doc のパスを入れた変数（そのまま実行可能な形）
awk '/^## Retrospective$/{buf=""; found=1} found{buf=buf $0 ORS} END{printf "%s", buf}' "$cycle_doc" \
  | grep -A3 '^### 想起漏れ$' | grep '^- \*\*回答\*\*:'
```

出力は回答行ちょうど 1 行であること（`grep -A3` は見出し直後の空行を含むため。-A2 では回答行に届かない）。

### No-lesson 処理 (抽出成功 + 0 件、Codex P2-2 対応)

抽出 LLM 実行は**成功**したが、再利用可能な failure-success ペアが見つからない場合。これは「失敗」ではなく通常の exit path:

```markdown
## Retrospective

No reusable lesson this cycle

### 想起漏れ

- **設問**: 今回の手戻りは、過去のどの cycle doc を最初に読んでいれば防げたか
- **回答**: 該当なし
```

- retro_status: `resolved` に遷移
- **AskUserQuestion は実行しない** (user intervention 不要)
- Retry / override path とは別 (そちらは LLM エラー時のみ)
- no-lesson 経路でも `### 想起漏れ`（回答 `該当なし`）を必須で併記する（全正常終了経路で記録）

## Retry Policy (LLM エラー時のみ、Codex P2-2 対応)

**重要**: retry は「LLM 実行自体の失敗 (API error, parse error, etc.)」時のみ発動する。抽出成功 + 0 件 (no lesson) は retry 対象**ではない** (no-lesson path に直接遷移)。

LLM エラー時の動作:

- 初回抽出でエラー発生時、N=2 回リトライする
- 各リトライで抽象度を上げる (より一般化された insight を狙うことでエラー回避を試みる)
- リトライ 1: ドメイン固有の失敗から一般的なパターンへ抽象化
- リトライ 2: 技術的詳細を捨て、プロセス・判断ミスの観点で再スキャン
- 全 retry 失敗 → Override 2 路分離 (下記) へ

## Override 2 路分離 (Codex 2nd #3)

全 retry 失敗後、AskUserQuestion で 2 択を提示する:

### proceed (続行)

- Cycle doc に `## Retrospective` を append する
- 内容: `Extraction skipped by override` または `Extraction failed after N retries`
- 併せて `### 想起漏れ`（回答 `該当なし`）を必須で記録する（全正常終了経路で記録。abort のみ対象外）
- retro_status を `resolved` に遷移させる
- 通常の exit 0 で終了

### abort (中止)

- Cycle doc を**一切変更しない**
- stderr に「Retrospective aborted by user. orchestrate should BLOCK commit.」を出力
- exit 1 で終了 (orchestrate A2b 統合後は BLOCK signal として機能)

**重要**: override は `no-codify` や `no-lesson` に偽装してはならない。
proceed は明示的に `Extraction skipped by override` を記録し、abort は変更なし exit 1 とする。

## 固定文字列 Contract

以下の 3 文字列は参照実装として固定する (TC-09 で契約化):

| 状況 | 固定文字列 |
|------|-----------|
| override proceed (抽出スキップ) | `Extraction skipped by override` |
| retry N=2 失敗後 proceed | `Extraction failed after N retries` |
| 抽出 0 件 (no-lesson) | `No reusable lesson this cycle` |

これらの文字列は変更・省略・言い換えを禁止する。将来の skill 改修でも維持すること。

## Idempotency 仕様 (Codex 2nd #1)

- Cycle doc の frontmatter `retro_status` フィールドが `none` 以外の値の場合、skill は何もせず正常終了する
- retro_status = `captured`: 有効な insight を追記済み → skip
- retro_status = `resolved`: no-lesson / override proceed 済み → skip
- retro_status フィールド不在: Cycle doc が古い形式 → skip (安全側)
- skip 時は「既に処理済み (retro_status: $value)」を stdout に出力して exit 0

これにより重複追記を防止する (APPEND-ONLY 遵守)。

## Append 位置の固定

`## Retrospective` セクションは必ず **Cycle doc EOF (= ## Next Steps の後)** に append する。

- Middle-insert 禁止: 既存セクションの間への挿入は APPEND-ONLY 違反
- 既存 `## Retrospective` セクションが存在する場合: idempotency check で skip するため append しない
- 位置: `## Next Steps` セクションの後、ファイル末尾

## Frontmatter 更新ルール

state-ownership.md の cycle-retrospective 行に従い、以下のみ更新する:

| フィールド | 更新タイミング | 値 |
|-----------|--------------|-----|
| retro_status | Retrospective append 後 | `captured` (insight あり) / `resolved` (no-lesson / override-proceed) |
| updated | Retrospective append 後 | 現在時刻 (YYYY-MM-DD HH:MM) |

それ以外のフィールド (phase / complexity / test_count 等) は変更しない。

## A2b 予告 (orchestrate 統合)

A2a では skill は**手動起動のみ**。A2b で以下が追加される:

- orchestrate Block 2f: REVIEW → DISCOVERED → **cycle-retrospective** → COMMIT の順に挿入
- pre-commit-gate.sh: retro_status = none の場合に COMMIT を BLOCK
- commit/SKILL.md: gate 更新

codify-insight (Cycle B) が captured insight を decide gate で分類・体系化する予定。
