---
feature: テストスイートの入れ子重複を除去し、run-tests.sh を縮小する
cycle: 20260916_1634
phase: DONE
complexity: complex
test_count: 30
risk_level: medium
retro_status: captured
codex_session_id: "(取得失敗)"
plan_file: /Users/morodomi/.claude/plans/magical-plotting-sketch.md
created: 2026-09-16 16:34
updated: 2026-09-16 18:24
---

# テストスイートの入れ子重複を除去し、run-tests.sh を縮小する

## Scope Definition

### In Scope

**A. 入れ子の重複を除去（本丸）**
- [ ] `tests/test-doc-consistency.sh` の TC-13（全テスト nested 実行）を削除
- [ ] `tests/test-factory-model-adaptation.sh` の TC-14（全テスト nested 実行）を削除
- [ ] `rules/plan-discipline.md` の推奨行の direct loop を `bash run-tests.sh` へ（mirror: `.claude/rules/plan-discipline.md`。`tests/test-rules-mirror.sh` が完全一致を要求）
- [ ] `skills/spec/templates/cycle.md` の汎用テンプレート direct loop は残しつつ、dev-crew 向けには runner 優先である旨を注記
- [ ] `docs/decisions/adr-test-isolation-boundary.md`（ADR-004、現在 untracked）を実測に基づき書き直し、Status を accepted へ

**B. `run-tests.sh` の縮小**（詳細テーブルは Implementation Notes 参照）
- [ ] コピーして実行の機構は残す。APFS clone (`cp -c`) は不採用のまま
- [ ] 指紋の三点照合・再試行プロトコルを削る
- [ ] source tree 境界チェックは残す（最小化）。staleness 判定・owner metadata・reaper は削る
- [ ] PID・起動時刻・所有者・reaper を削る（通常終了の cleanup と警告は残す）
- [ ] admission: プロセス数判定は残す。load 判定・memory 判定は削る
- [ ] `.claude/test-serialization.json` を削除し、`.gitignore` の negation 行も削除
- [ ] exit code を 0/1/2/3 へ縮小（4, 5 廃止。signal 由来の 129/130/143 は別途残る）
- [ ] 実行後 live tree 変化の advisory を削る
- [ ] `DEV_CREW_RUNNER_LIB_ONLY`（source-as-library）を削る
- [ ] `pgrep` の自己・祖先除外は実装のみ残す（Linux 向け defense-in-depth。macOS では実 pgrep により vacuous）
- [ ] `DEV_CREW_TEST_HOOK_*` を全削除し、F2（TC-48）の検証手段を `cp` shim へ差し替える（**案 a 確定**。詳細は Implementation Notes）

**B-2. コピーだけを残すことの帰結（受容する失敗）を ADR-004 と `run-tests.sh` のコメントに明記**
- [ ] 詳細は Implementation Notes 参照（5 項目）

**C. 実行時間の調査**
- [ ] A の前後、B の前後で同一条件・単独実行にて計測し、458 → 117 回への実行回数低減と時間短縮を数値で示す

### Out of Scope
- 排他ロック (Reason: 前 cycle から継続して不採用)
- hook による inline ループの誘導 (Reason: Cycle B のまま、別 plan)
- `docs/STATUS.md` の更新 (Reason: 古さは優先理由にならない)

### Files to Change (target: 10 or less — 本 cycle は **13 件**、削除主体のため超過。architect の Post-Transfer Verification で確認済み)
- `tests/test-doc-consistency.sh` (edit) — TC-13 削除
- `tests/test-factory-model-adaptation.sh` (edit) — TC-14 削除
- `run-tests.sh` (edit) — B の縮小
- `tests/test-run-tests-runner.sh` (edit) — 削除した機構に対応する TC を削除、TC-48 の検証手段を差し替え
- `rules/plan-discipline.md` (edit) + `.claude/rules/plan-discipline.md` (edit) — mirror 必須ペア。推奨行の direct loop を `bash run-tests.sh` へ
- `.claude/test-serialization.json` (delete) — load / memory admission を外すと全キーが不要
- `.gitignore` (edit) — 上に伴い negation 行を削除
- `docs/decisions/adr-test-isolation-boundary.md` (edit, 現在 untracked) — ADR-004 を実測に基づいて書き直し、Status を accepted へ
- `docs/OVERVIEW.md` (edit) — exit code 表と「テストの走らせ方」を実態に合わせる
- `skills/spec/templates/cycle.md` (edit) — 汎用テンプレートの direct loop は残し、dev-crew 向けには runner 優先である旨を注記
- `CHANGELOG.md` / `docs/NEXT.md` (edit)

**scope 同梱の注記**: Block 0 の codify gate が前 cycle doc（`docs/cycles/20260913_0059_runner-admission-snapshot.md`）を本 cycle 起票前に既に更新済み（sync-plan 起動時点の `git status` で `M docs/cycles/20260913_0059_runner-admission-snapshot.md` を確認済み。`retro_status: captured → resolved` と Codify Decisions 5 件の追記）。この差分は承認済み Files には現れないが、本 cycle の commit に同梱される。

**前提条件**: PR #241（F2 の修正）の merge が先。本 cycle はその上に載る。→ merge 済みを確認済み（`git log` 直近: `3f75c2b Merge pull request #241 from morodomi/fix/explicit-target-false-pass`、`c985a5c fix: 明示指定したテストが snapshot に無いと成功扱いになる欠陥を修正`）。

## Environment

### Scope
- Layer: Tooling / Infra（この repo のテスト実行基盤。`run-tests.sh` は bash script）
- Plugin: N/A（言語プラグイン横断ではなく dev-crew 自身の repo 運用基盤）
- Risk: 未算出（**正直な記録**: 本 plan は標準 spec の「## TDD Context」+ Risk 数値評価ステップを経ておらず、手動起票 + Codex plan review 4 round という別経路で承認されている。sync-plan が独自に Risk 数値を捏造することはしない。frontmatter `risk_level: medium` は「repo 内のみの影響 / 外部ユーザーなし / 単一開発者運用」と「全サイクルの test 実行 SSOT である `run-tests.sh` 本体・mirror 条項・ADR を同時に触る blast radius」を突き合わせた sync-plan の仮設定であり、architect の Post-Transfer Verification で再確認されたい）
- 影響範囲: この repo のみ

### Runtime
- 対象環境: macOS（Darwin）。前 cycle（20260913_0059）と同じ runner 本体を対象とするため、`pgrep` / `mktemp -d` / `shasum -a 256` / `awk` 等 BSD/macOS 系ツールが引き続き使用される
- 数値比較は `awk`（`bc` は使わない。既存方針を踏襲）

### Dependencies (key packages)
- 外部パッケージ依存なし（bash + macOS 標準コマンドのみ）
- `jq`: 本 cycle で依存を**除去**（load admission 削除に伴い `.claude/test-serialization.json` の `jq` 処理も削除。B 参照）

### Risk Interview (BLOCK only)
N/A — 本 plan は spec 標準の Risk BLOCK 判定を経ていない（上記 Environment/Scope の Risk 欄参照）。Codex plan review（Round 1〜4、下記 Plan Review Record）が実質的なリスクレビューとして機能している。

## Context & Dependencies

### Reference Documents
- `docs/cycles/20260913_0059_runner-admission-snapshot.md` — 前 cycle。「間違った問題を解いた」の当事者。本 cycle はその過剰実装を実測に基づき削る
- `rules/plan-discipline.md:23` — 推奨行に direct loop が今も残っている（実測確認済み）。本 cycle の scope 追加の根拠
- `tests/test-rules-mirror.sh` — `rules/` と `.claude/rules/` の完全一致を要求する契約
- `docs/decisions/adr-test-isolation-boundary.md`（現在 untracked）— ADR-004 草案。Status: deferred のまま残っており、本 cycle で accepted へ書き直す

### Dependent Features
- `run-tests.sh` — Cycle A で確立された、この repo の正規テスト実行入口
- `tests/test-doc-consistency.sh` TC-13 / `tests/test-factory-model-adaptation.sh` TC-14 — 削除対象。入れ子構造の当事者
- `tests/test-run-tests-runner.sh` — B で削る機構に対応する TC 群を持つ。TC-48 は F2 の唯一の決定論的検証

### Related Issues/PRs
- PR #241 — F2（明示 target が snapshot に無いと成功扱いになる欠陥）の修正。本 cycle の前提条件で merge 済み

## Recall

`scripts/recall-candidates.sh` の上位候補と、本 cycle における適用先。

### 1. `docs/cycles/20260421_1043` Insight 5 — 入れ子は最初から問題だった

> 「TC-13 が `tests/test-*.sh` を全実行 → meta test が走る → meta test の TC-04 が `bash tests/test-doc-consistency.sh` を再実行 → 無限再帰のリスク。green-worker が GREEN フェーズで気付いて TC-13 skip 条件を追加」

**本 cycle への適用**: 当時の対処は「skip 条件を足す」だった。構造そのものを疑っていない。本 cycle は skip リストを調整するのではなく TC-13 / TC-14 を削除する。

### 2. `docs/cycles/20260427_0930` — skip リストと timeout が反応的に育ってきた

> `test-factory-model-adaptation.sh` TC-14 の timeout `30s → 60s → 90s`、skip リストに `test-meta-doc-consistency.sh` / `test-review-integration-v24.sh` / `test-phase-compact.sh` を追加。理由は「recursive meta-tests で cascade timeout が発生し flaky FAIL を引き起こしていた」

**本 cycle への適用**: これが削除の最も強い根拠。この repo は数ヶ月にわたり、timeout 調整・skip リスト拡張・flaky FAIL の調査という保守コストを払い続けてきた。その全部が「runner と重複する構造」を維持するための出費だった。削除すればこの保守負債ごと消える。

### 3. `rules/test-patterns.md` — meta test の設計条項

> 「meta test は `BASE_DIR` env override で subject script を直接実行する」「fixture-based meta test の他 TC 呼び出しは `|| true` + `2>/dev/null` で defensive 化」

**本 cycle への適用**: 条項は「meta test が他テストを呼ぶ」ことを前提に書かれている。TC-13 / TC-14 を削除しても、fixture ベースで他テストを呼ぶ正当な meta test（`test-trap-handler.sh` 等）は残るため条項は有効。削除対象は「スイート全体を無差別に再実行する」2 件に限る。

### 4. `docs/cycles/20260913_0059`（前 cycle）— 間違った問題を解いた

**本 cycle への適用**: 前 cycle は「テストが遅い」を所与として受け入れ、遅さの原因を測らずにコピーの整合性機構を作った。本 cycle は先に測った（入れ子 1 回 = 161 秒）。Verification では推定値の確認を必ず行い、推定のまま結論にしない。

## Test List

現行 57 TC を 3 分類する。**これが複雑さ予算の合格条件**（削除群と残す最小群を列挙できること）。

**ファイル間の TC 番号重複に関する注意**: `tests/test-run-tests-runner.sh` 内の TC 番号（TC-11〜TC-48 等）と、`tests/test-doc-consistency.sh` の TC-13、`tests/test-factory-model-adaptation.sh` の TC-14 は**別ファイル・別物**（plan 実測確認済み）。以下の分類表はすべて `tests/test-run-tests-runner.sh` 内の TC を指す。`test-doc-consistency.sh` TC-13 と `test-factory-model-adaptation.sh` TC-14 の削除は Scope Definition A に別掲済みで、この 57 の内数ではない。

### TODO

#### 削除する TC（31件、`tests/test-run-tests-runner.sh`）

| 群 | TC | 消える理由 |
|---|---|---|
| 設定ファイル | TC-11, TC-12, TC-13 | `.claude/test-serialization.json` と `jq` 処理を削除 |
| load 判定 | TC-05, TC-10 | load admission を削除 |
| memory 判定 | TC-06 | memory admission を削除（測れていない） |
| 複数条件の fail-open | TC-07, TC-08, TC-09 | 条件が `pgrep` 1 つになり、多条件の組み合わせ検査が不要 |
| 三点照合・ABA・再試行・特殊ファイル | TC-21, TC-22, TC-23, TC-24, TC-24b, TC-25c | 照合機構ごと削除 |
| owner / liveness / reaper | TC-28, TC-29, TC-29b, TC-30, TC-31, TC-32, TC-33, TC-34, TC-35, TC-35b | 永続 metadata と次回起動時 reaper を削除 |
| live tree advisory | TC-36, TC-37, TC-38 | advisory を削除 |
| source-as-library | TC-45 | `DEV_CREW_RUNNER_LIB_ONLY` を削除（除外ロジックの検証手段も道連れ。受容する） |
| 除外の対向 oracle | TC-04, TC-04b | 実 `pgrep` 経由では macOS 上 vacuous。TC-45 と併せて検証手段を失う |

削除 TC 数: **31**（3+2+1+3+6+10+3+1+2）

- [ ] 上記 31 TC を `tests/test-run-tests-runner.sh` から削除
- [ ] 上記削除に対応する `run-tests.sh` 本体の機構（B 参照）を削除

#### 残す最小 TC（26件、`tests/test-run-tests-runner.sh`）

| 群 | TC | 守るもの |
|---|---|---|
| admission | TC-01, TC-02, TC-03 | プロセス数判定。`pgrep` rc=1 は正常な 0 件 |
| 引数の正規化・拒否 | TC-14〜TC-20（TC-18a/18b/18c 含む） | repo 外・`..`・symlink・非 `tests/`・不正命名・0 件・不存在 |
| snapshot 上での実行 | TC-25, TC-25b（+ TC-20 は cross-cutting） | 親構造の複製 / `.git` の複製。TC-20（marker が snapshot 内にのみ出る）の主所属は「引数」群とし、件数は 1 度だけ数える |
| 後始末 | TC-26, TC-27, TC-27c | 正常終了・signal 時の cleanup、冪等性 |
| **source tree 境界** | **TC-46** | **`TMPDIR` が repo 配下のとき snapshot を source tree 内に作らない**。削除すると `cp -Rp "$BASE_DIR"` が snapshot を再帰的に含む事故が復活する |
| F2 | TC-48 | `cp` shim へ差し替え（hook 依存を解消） |
| 条項・doc | TC-39〜TC-44 | 既存契約の維持 |

残す TC 数: **26**（admission 3 + 引数 10 + snapshot 実行 2 + 後始末 3 + 境界 1 + F2 1 + 条項 6）

**31 + 26 = 57。分類は網羅的かつ排他的。**

- [ ] 上記 26 TC が削除対象と誤って重複削除されないことを確認

#### 新設する TC（2件）

| TC | 内容 |
|---|---|
| 新規 1 | コピー失敗が `exit 2`（`1` と混ざらない）。`1` は実行したテストの FAIL のみ |
| 新規 2 | 残骸がある状態で起動すると警告が出る（削除はしない）。走査対象は境界判定後の実際の snapshot root（生の `$TMPDIR` ではない。repo 内 TMPDIR で fallback した経路でも確認する）。0 件時に stderr を出さないこと |

#### 変更する TC（3件）

| TC | 変更 |
|---|---|
| TC-44 | `rules/plan-discipline.md` の「具体例に独自 loop が無い」検査を、推奨行の direct loop を再導入しない契約まで拡張。mirror も対象 |
| TC-46 | `SAFE_TMPDIR` の決定ロジック全体ではなく、最小の source tree 境界チェックの契約へ書き換え |
| TC-48 | hook 依存を `cp` shim へ差し替え |

**承認時点の想定 TC 数: 57 − 31 + 2 = 28 ラベル**（アサーション 29。TC-27b は TC-27 のブロックに同居し、header の「58 total」はこれを数えた値）。

**最終実績: 57 − 31 + 4 = 30 ラベル / 31 アサーション。** 承認後の REVIEW mini-iteration で新設 2 件を追加したため（**TC-51**: `pgrep` fail-open 3 経路、**TC-52**: `exit 1` の単独 pin）。いずれも**既に宣言済みの契約を pin するもので新しい状態は持ち込んでいない**（複雑さ予算 6 項目は 0 のまま）。実装差分が net negative であることの判定材料とする。

### WIP

RED で失敗するテストコードを作成済み（`tests/test-run-tests-runner.sh`）。削除（GREEN の仕事）は未着手:

- [ ] 新規1: コピー失敗時の exit code が 2 であること（1 との混同がないこと）を検証する TC を追加（TC-49 として実装。実測 FAIL: rc=5、目標 rc=2）
- [ ] 新規2: 残骸検出時の警告出力（削除はしない、境界判定後の実際の snapshot root を走査、0件時は無出力）を検証する TC を追加（TC-50 として実装。実測 FAIL: 50-a/50-c が未実装機能のため失敗、50-b は要求どおり無警告で通過）
- [ ] TC-44: mirror 込みで direct loop 再導入禁止の契約へ拡張（実測 FAIL: `rules/plan-discipline.md` 本体・mirror とも「## 推奨」の direct loop が未修正）
- [ ] TC-46: 最小の source tree 境界チェック契約へ書き換え（実測 PASS。determine_safe_tmpdir は本 cycle で変更しない生存機構のため regression pin として現時点で通る。棄却実験で non-vacuous を確認: fixture 内の fallback 行を無効化すると self-referential `cp -Rp` に陥りハング/timeout — 「静かに PASS する」壊れ方ではないことを確認。ホスト保護のため完走はさせずタイムアウトで停止、trap による後始末を確認、実プロセス・残留ディレクトリなしを確認済み）
- [ ] TC-48: `DEV_CREW_TEST_HOOK_BEFORE_COPY` 依存を `cp` shim へ差し替え（実測 PASS。F2 本体のロジックは本 cycle で変更しないため現時点で通る。棄却実験で non-vacuous を確認: `cp` shim を `real`（削除なし）に変えると rc=0 に反転し assertion が FAIL することを確認）

### DISCOVERED

architect の Post-Transfer Verification（2026-09-16）で検出した軽微な不整合。転記欠落・scope実質変更には該当せず、実装（RED以降）への影響もないため観察として記録する:

1. **In Scope C（line 45）の実行回数表記ミス**: 当初「658→117 回」と記載されていた。plan の確定値および本 Cycle doc 他所は一貫して **458→117 回**（117+115+113+113=458）。**PdM が修正済み**
2. **Files to Change ヘッダ（line 52）の件数表記ミス**: 「本 cycle は 12 件」と記載されているが、実際のリスト項目数は plan と完全一致する **13 件**（ファイル欠落なし。architect が全 13 ファイルの実在を確認済み）。カウント表記のみの誤り
3. **`DEV_CREW_TEST_HOOK_*` 参照「9 箇所」の実測差異**: plan 由来の記述（line 265 Implementation Notes 内、plan 本文からの転記）。`grep -n "DEV_CREW_TEST_HOOK" run-tests.sh tests/test-run-tests-runner.sh` で実測すると計 **14 行**（TC 使用箇所: TC-21/TC-22/TC-23/TC-24/TC-25c/TC-48 の6箇所 + run-tests.sh 実装4行（BEFORE_COPY/AFTER_COPY の if/呼び出し）+ コメント4行）。sync-plan の転記誤りではなく plan 自体の数値だが、正確な実測値として RED 実装者へ申し送る。F2 の設計判断（hook 全削除 → `cp` shim 置換、TC-48 差し替え）には影響しない
4. **B-2見出し（line 41）の記載追加**: 「ADR-004 と `run-tests.sh` のコメントに明記」とあるが、plan の B-2 節（表本体）は ADR-004 のみを明記対象としており、`run-tests.sh` のコメント追記は plan に明示されていない sync-plan 側の解釈追加。対象ファイル自体は Files to Change に既に含まれるため実害はないが、独自追加である旨を記録する（「独自判断で追加・削除しない」原則の透明化）
5. **`reviewed_plan_hash` は plan-format drift（観察、BLOCK ではない）**: plan の `## Plan Review Record` は narrative（Round 1〜4）形式で、構造化スキーマフィールド（`reviewed_plan_hash` / `review_attempts` の started・completed）を持たない（`grep -n "reviewed_plan_hash\|review_attempts" <plan>` → 該当なし）。sync-plan は canonical algorithm（`awk '$0=="## Plan Review Record"{exit}{print}' <plan> | shasum -a 256`）で独自に実測し `da4d25f38e5da5b910a53ba7f1d8714b4c31e1a35d4042a9cb56f4f0305b1f56` を記録。architect が独立に同一コマンドで再計算し**一致確認**、かつ `bash scripts/gates/pre-red-gate.sh` の PASS（exit 0）でも整合を確認済み。plan の mtime（2026-09-16 16:27）は Cycle doc 作成時刻（16:34）より前で、承認後の plan 変更なし（IMMUTABLE 契約遵守）。転記欠落ではなく plan 側テンプレート非準拠の観察

上記いずれも scope 実質変更・転記欠落には該当しないため BLOCK 対象外。architect 判定は WARN（下記 Progress Log 参照）。

6. **`exit 1`（実行したテストの FAIL のみ、流用禁止）を単独で pin する生存 TC が存在しなかった**: RED（2026-09-16 17:07）が「DISCOVERED 候補（RED では追加せず報告のみ）」として発見（`grep -n 'RUN_RC" -eq 1'` 該当なし）、GREEN（2026-09-16 17:25）が本 cycle の scope（新設 TC = TC-49/TC-50 のみ）に含まれないとして据え置き、REFACTOR でも未着手のまま残っていた安全弁の穴。31 件の TC 削除により FAIL 集計 → `exit 1` の経路を検証する生存 TC が偶然ゼロになっていた。**REVIEW mini-iteration（2026-09-16、Codex BLOCK + Claude WARN A1）で TC-52 として解消済み**: `exit 42` で終了する dummy test を追加し、`RUN_RC == 1` かつ stdout に `FAIL: 1` と失敗テスト名（`test-zz-failing.sh`）が現れることを pin。修正前の `run-tests.sh`（末尾の `exit 1` を `exit 9` へ mutate）で TC-52 が FAIL することを実測し non-vacuous と実証済み（詳細は下記 REVIEW mini-iteration Progress Log 参照）

### DONE
(none)

## Implementation Notes

### Goal
前 cycle（20260913_0059）が積み上げた過剰実装（指紋の三点照合・PID/所有者追跡・reaper・exit code 肥大）を実測に基づいて削り、テストスイートの入れ子重複（`test-doc-consistency.sh` TC-13 と `test-factory-model-adaptation.sh` TC-14 が `run-tests.sh` と役割重複してスイート全体を再実行している構造）を除去して `run-tests.sh` を縮小する。

### Background

**遅さの正体（実測）**:

```
フルスイート（117 本）
  ├─ test-doc-consistency.sh
  │    └─ TC-13 が 115 本を nested 実行
  │         └─ その中で test-factory-model-adaptation.sh も走る
  │              └─ TC-14 がさらに 113 本を nested 実行   ← 二重の入れ子
  └─ test-factory-model-adaptation.sh（単独でも走る）
       └─ TC-14 が 113 本を nested 実行
```

実測: 入れ子 1 回分（`test-factory-model-adaptation.sh` 単独）= 161 秒。1 テストあたり約 1.4 秒。実行回数は **458 回 → 117 回**（117 + 115 + 113 + 113 = 458、確定値）。同一の低負荷条件で約 11 分 → 約 3 分が見込める（要実測確認、C で実施）。

**複雑さ予算（宣言）**: 本 cycle は削除が主体。持ち込む状態の種類を数える（行数ではない）。

| 予算項目 | 今回許す量 |
|---|---|
| 新しい永続状態・metadata | **0** |
| 新しい lifecycle / cleanup protocol | **0** |
| 新しい設定形式 | **0** |
| 新しい exit code | **0**（減らす方向のみ） |
| 新しい OS 固有意味論への依存 | **0** |
| 並行性・所有権・時刻の扱い | **0**（既存を減らす） |

**「net negative」は行数で測らない**（行数を絶対化すると圧縮して読めないコードを書く誘惑が生まれる）。**判定は上表の 6 項目が全て 0 であること、かつ Test List で「削除する TC 群」と「残す最小 TC 群」を列挙できること（上記 Test List 参照）で行う。** 増える場合は境界を超えたと判断し、一度だけ確認する。

### Design Approach

**A. 入れ子の重複を除去**: TC-13 / TC-14 はどちらも「全テストを実行する」だけで `run-tests.sh` と役割が重複する。外部から TC-13 / TC-14 を pin している契約は無い（実測確認済み。他ファイルの同番号 TC は別物）。「失われる保証は無い」は不正確なので訂正する: 失われるのは「`bash tests/test-doc-consistency.sh` や factory を個別に実行しただけで、その時点の全スイートが通ることも分かる」という暗黙の保証である。正規入口を `run-tests.sh` に一本化する以上これは受容できるが、技術的に強制されてはいない。`rules/plan-discipline.md:23` は今も direct loop を Block 0 の推奨として残しているため、scope に追加する。

**B. `run-tests.sh` の縮小**:

| 機構 | 判断 | 残る保証 / 受容する失敗 |
|---|---|---|
| コピーして実行 | **残す** | 実行中の書き換えによる非再現 FAIL を消す。入れ子を潰しても窓は消えない（本 cycle 中に規律違反が 6 回、うち 1 回は PdM）。コスト約 2 秒 |
| ~~APFS clone (`cp -c`)~~ | **不採用** | 0.82 秒と 2.04 秒の差は、削除後の約 3 分に対して実質的でない。一方で `cp` の OS 実装差と fallback という**新しい OS 固有意味論を持ち込む**。自分で宣言した予算（OS 固有依存 0）と矛盾する |
| 指紋の三点照合 | **削る** | コピー中の変更を検出しなくなる。そもそも原子的コピーは保証していなかった（指紋計算自体がファイルを順に読むため、計算中の編集で指紋自体が混成になる） |
| 再試行プロトコル | 削る | 上に伴い不要 |
| **source tree 境界チェック** | **残す（最小化）** | **削れない。** `TMPDIR` が repo 配下を指す場合、snapshot を source tree 内に作ってしまい `cp -Rp "$BASE_DIR"` が snapshot を再帰的に含む。採用: repo 内を指すときだけ `/tmp` へ fallback する 3 行程度の境界判定を残す。**削除するのは staleness 判定・owner metadata・reaper であって、この境界ではない** |
| PID・起動時刻・所有者・reaper | **削る** | 強制終了後の残骸を自動回収しない。通常終了の掃除は残し、残骸は報告に留める（13〜17 分は実測値であって上限ではなく、age 削除は停止・スリープ中の実行を消し得る） |
| admission: テストプロセス数 | 残す | 多重起動の抑止。受容する失敗: 完全には防がない（check-then-act race、runner を経由しない起動、probe 利用不可時の skip） |
| **admission: load** | **削る** | 防いだ実績が無く、C の通常時ベンチマークでは効果を検証できない。受容する失敗: CPU 混雑時にテストが遅くなる・他プロセスと競合する。これを外すと `.claude/test-serialization.json`・`jq` による設定処理・`.gitignore` の negation 例外も**まとめて消える** |
| **admission: memory** | **削る** | **測れていない。** `free + inactive` で 6,198 MB と報告する一方、実 `Pages free` は 75 MB（80 倍の過大評価）。この判定が「6.7GB 空いています」と答えた直後にジョブが 2 回停止した |
| exit code | **0 / 1 / 2 / 3 へ縮小** | `0`=全通過 / `1`=実行したテストの FAIL のみ（流用禁止）/ `2`=runner が開始不能（admission 拒否・snapshot 作成失敗・コピー失敗を統合）/ `3`=引数拒否。`4` `5` を廃止。これは通常完了時の値であり、signal 終了の 129/130/143 は別途残る |
| 実行後の live tree 変化の advisory | 削る | ノイズ |
| source-as-library（`DEV_CREW_RUNNER_LIB_ONLY`） | **削る** | production の状態空間をテスト都合で増やしている。現状 env 変数だけで runner を bypass できる欠陥もある |
| `pgrep` の自己・祖先除外 | **残す（実装のみ）** | 除外は必要（`run-tests.sh tests/test-foo.sh` は自身の cmdline に `tests/test-` を含むため）。受容する失敗: 検証手段を失う（TC-45 が source-as-library に依存しており道連れ）。macOS では実 `pgrep` が OS 既定で自己・祖先を除外するため実 pgrep 経由の TC は vacuous。Linux 向け defense-in-depth として残すが、契約では守られない |
| テスト用 hook（`DEV_CREW_TEST_HOOK_*`） | **条件付きで削る** | F2 を残すなら全削除とは両立しない（下記 F2 参照） |

**F2（明示 target が snapshot に無いと成功扱い）の修正は残す。** PR #241 で入れた分であり、コピーを続ける限り必要。ただし F2 の唯一の決定論的検証である TC-48 は `DEV_CREW_TEST_HOOK_BEFORE_COPY` に依存している（実測確認済み。hook は計 **14 行**で参照される（実測。TC 使用 6 箇所 = TC-21/22/23/24/25c/48、`run-tests.sh` 実装 4 行、コメント 4 行）。うち TC-48 が 1 件）。hook を全削除すると F2 の検証手段が消える。

**方針は承認前に決め切られている（実装時の選択にしない）。案 a を採用する。** fixture 側で `cp` を shim し、「検証後・コピー前に対象を消す」状況を再現して TC-48 を置換する。`DEV_CREW_TEST_HOOK_*` は**全削除**する。**a が成立しなければ実装を止めて再計画する。案 b（hook を 1 つ残す）は不採用。** 理由: production に「テスト都合の経路」を残さない。前 cycle では `DEV_CREW_RUNNER_LIB_ONLY` が env 変数だけで runner を bypass できる欠陥になった。同じ構造を残さない。

**B-2. コピーだけを残すことの帰結（受容する失敗の明示）**:

| 項目 | 内容 |
|---|---|
| **受容する** | コピー中に編集が入ると、どの live revision にも一致しない混成 snapshot の上でテストが走り得る |
| **なお守られる** | コピー完了後のテストは frozen な snapshot を読むため、実行中の live tree 編集との混読は防ぐ。これが本来の目的 |
| **受容する** | 強制終了後の残骸を自動削除しない。起動時に対象パスを警告するだけで、ディスクを消費し続け得る |
| **警告は残す（判断）** | 「scan ごと削って無通知にする」案も検討したが、macOS の `TMPDIR` 自動掃除は当てにならない（実測: 2024-10 の残骸が 11 ヶ月残存、エントリ 257 件）。ただし警告は最小限に留める（**走査対象は生の `$TMPDIR` ではなく、境界判定後の実際の snapshot root**。`TMPDIR` が repo 配下を指して fallback した経路も同じ root を見るため残骸を見逃さない）。肥大していたのは `SAFE_TMPDIR` の決定ロジックと staleness 判定であり、そちらは削除対象 |
| **残す** | runner 自身の `trap` による正常終了・TERM/INT 時の cleanup。削るのは永続 owner metadata と次回起動時の reaper だけ |

**C. 実行時間の調査**: A の前後、B の前後で計測し、どこが効いたかを数値で示す。推定（約 11 分の内訳）が正しいかの確認を含む。

## Verification

1. **A の前後で実行時間を計測**（同一条件、単独実行）
2. **B の前後で実行時間を計測**
3. 延べテスト実行回数を数え、**458 回 → 117 回**になったことを確認
4. 削除した機構に対応する TC が残っていないことを確認（削除する TC 群と残す最小 TC 群を Test List で列挙。上記参照）
5. `rules/` と `.claude/rules/` の mirror 一致（`tests/test-rules-mirror.sh`）
6. フルスイート全通過

**計測はホストが空いているときに行う。** 本 plan の作成中、メモリ逼迫でジョブが 2 回停止した（実 free 75〜256 MB、compressor に 18.5GB）。**負荷をかけて guard を試すことはしない。**

Evidence: (orchestrate が自動記入)

## Progress Log

### 2026-09-16 16:34 - KICKOFF
- Cycle doc created from plan（`/Users/morodomi/.claude/plans/magical-plotting-sketch.md`）
- Scope definition ready
- Phase completed

### 2026-09-16 16:34 - Plan Review (pre-approval)
- codex_session_id: (取得失敗)
- review_attempts:
  - {started: 不明（plan に個別ラウンドの開始/終了時刻の記載なし）, completed: 不明（plan に個別ラウンドの開始/終了時刻の記載なし）, verdict: BLOCK}
  - {started: 不明（plan に個別ラウンドの開始/終了時刻の記載なし）, completed: 不明（plan に個別ラウンドの開始/終了時刻の記載なし）, verdict: BLOCK}
  - {started: 不明（plan に個別ラウンドの開始/終了時刻の記載なし）, completed: 不明（plan に個別ラウンドの開始/終了時刻の記載なし）, verdict: BLOCK}
  - {started: 不明（plan に個別ラウンドの開始/終了時刻の記載なし）, completed: 不明（plan に個別ラウンドの開始/終了時刻の記載なし）, verdict: WARN}
- findings 要約:
  - Round 1（`codex exec --sandbox read-only`）→ BLOCK 5件: (a)「失われる保証は無い」が不正確 → 訂正し `rules/plan-discipline.md` を scope へ（mirror 込み）、(b) F2 と hook 全削除が両立しない → TC-48 の hook 依存を実測確認（参照9箇所）、(c) exit code の分類が未決 → `1` は流用禁止、`2` に開始不能を統合、signal は別途、(d) **`cp -c` は外すべきと指摘 → 撤回。自分が宣言した予算（OS固有依存0）と矛盾していた**、(e) load admission も削除を推奨 → 採用。設定JSON・`jq`処理・`.gitignore`例外もまとめて消える
  - Round 2（`resume --last`）→ BLOCK 2件: F2の方針を実装時の選択にせず決め切れ → 案aを採用と確定（aが成立しなければ止めて再計画、案bは不採用）。Test Listが未確定のままでは自分で定義した承認条件を満たさない → 削除/残す/新設/変更を確定。`skills/spec/templates/cycle.md` がFilesに無い → 追加。追加提案: 起動時scanも削れる → 警告のみ残す判断（macOSのTMPDIR自動掃除が当てにならないことを実測確認: 2024-10の残骸が11ヶ月残存、エントリ257件。警告は3行に留め、肥大の原因だったSAFE_TMPDIR決定ロジックとstaleness判定は削除）
  - **Round 3（`resume --last`）→ BLOCK 2件: `SAFE_TMPDIR` を全削除すると source tree 境界が消える → `TMPDIR` が repo 配下のとき snapshot を source tree 内に作り `cp -Rp "$BASE_DIR"` が再帰的に含む。削ってはいけないものを削ろうとしていた。最小の境界判定を残しTC-46をその契約へ変更。** Test Listの数が不整合 → 実測で確定（57ラベル/58アサーション、TC-27bはTC-27と同居）。削除31/残す26/31+26=57で網羅かつ排他。想定57−31+2=28ラベル
  - Round 4（`resume --last`）→ WARN。実装開始可。承認前のBLOCKはすべて閉じたと判定。実装中対応3件: (1) TC-20の主所属を明示（件数計算は元々正しい）、(2) 残骸警告は生の`$TMPDIR`ではなく境界判定後の実際のsnapshot rootを走査する（repo内TMPDIRで`/tmp`へfallbackした場合に見逃すため。新設TCもこの経路で確認）、(3) 0件時にstderrを出さない実装にする（`ls`ではなくglobの存在確認）
- unresolved_blocks: なし（Round 4「承認前の BLOCK はすべて閉じた」と判定）
- reviewed_plan_hash: da4d25f38e5da5b910a53ba7f1d8714b4c31e1a35d4042a9cb56f4f0305b1f56（sync-plan が canonical algorithm `awk '$0=="## Plan Review Record"{exit}{print}' <plan> | shasum -a 256` で実測。plan 側 Record に reviewed_plan_hash の記載自体が無いため、plan 記載値との一次照合は不可。実測値をそのまま記録する）
- verdict: WARN（実装開始可。承認前の BLOCK はすべて閉じたと判定）
- Phase completed

### 2026-09-16 16:37 - SYNC-PLAN
- Cycle doc generated from plan (`/Users/morodomi/.claude/plans/magical-plotting-sketch.md`)
- Plan Review Record (pre-approval) transferred from plan (narrative Round 1-4 form; review_attempts timestamps not recorded in source, placeholders used; reviewed_plan_hash newly measured by sync-plan since plan side lacked the field)
- Test List transferred: 削除31 / 残す26 / 新設2 / 変更3（TC-44, TC-46, TC-48）
- Phase completed

### 2026-09-16 16:43 - ARCHITECT (Post-Transfer Verification + Design Review Gate)
- **TC番号衝突リスク**: Cycle doc の「ファイル間の TC 番号重複に関する注意」（Test List 節冒頭）を実ファイルと突合。`tests/test-doc-consistency.sh` の TC-13（nested全実行）と `tests/test-run-tests-runner.sh` 独自の TC-13（config file absent → default admission、720行）は別物、`tests/test-factory-model-adaptation.sh` の TC-14（nested全実行）と `tests/test-run-tests-runner.sh` 独自の TC-14（tests/test-foo.sh 引数解決、741行）も別物であることを実測確認。Cycle doc の曖昧さ回避の注記は**正確**。BLOCK事由なし
- **`reviewed_plan_hash`**: plan の Plan Review Record にスキーマフィールドなし（実測: grep 該当なし）。sync-plan 記録値 `da4d25f38e5da5b910a53ba7f1d8714b4c31e1a35d4042a9cb56f4f0305b1f56` を architect が独立再計算し一致確認。`pre-red-gate.sh` も PASS（exit 0）。plan mtime（16:27）は Cycle doc 作成（16:34）より前で承認後の plan 変更なし。**(b) 観察（plan-format drift）と裁定。BLOCKではない**（DISCOVERED #5 参照）
- **書き換えチェック（softening検出）**: F2方針（案a確定・案b不採用・不成立なら止めて再計画）、source tree境界（削れない・repo配下TMPDIRのみ/tmp fallback）、`cp -c`不採用（OS固有依存0の予算と矛盾）、複雑さ予算6項目=0＋Test List列挙可能性、の4点を plan と Cycle doc（Scope Definition + Implementation Notes）で逐語比較。**いずれも緩められていない**（Round 3「削ってはいけないものを削ろうとしていた」の自己批判文言も line 311 に保持）
- **scope同梱（Block 0 codify gate、前cycle doc更新）**: Cycle doc Files to Change節の注記（line 65）が `rules/plan-discipline.md:41` の透明化要求を満たすことを確認。git status で `M docs/cycles/20260913_0059_runner-admission-snapshot.md` を実際に確認済み。追加アクション不要
- **実ファイル突合**: Files to Change 13件（plan/Cycle doc 完全一致）全ての実在を確認。`.gitignore` の negation行（`!.claude/test-serialization.json`）、`run-tests.sh` の `SAFE_TMPDIR` source tree境界ロジック（522-828行）、`docs/decisions/adr-test-isolation-boundary.md` の `Status: deferred`（accepted へ書き換え予定と整合）を実測確認
- **転記完全性**: Test List数値（削除31/残す26/新設2/変更3/31+26=57/28ラベル29アサーション）、B-2受容失敗5項目、Verification 6項目（「負荷をかけてguardを試すことはしない」含む）、Plan Review Record Round1〜4（Round3の自己批判文言含む）、Recall 4件（適用先明記4/4）を plan と逐語比較し**全て転記漏れなし**
- **軽微な不整合2件+観察2件を検出・DISCOVERED へ記録**（詳細は DISCOVERED 参照）: (1) In Scope C の実行回数「658→117」は誤記、正は「458→117」（**PdM が修正済み**）。(2) Files to Change ヘッダ「12件」は誤記、実際は13件（欠落なし）。(3) `DEV_CREW_TEST_HOOK_*`「9箇所」はplan由来の数値だが実測14行、F2の設計判断には無影響。(4) B-2見出しの「run-tests.shのコメント」明記はplanに無い sync-plan の解釈追加（実害なし、透明化のため記録）
- **risk_level: medium の裁定**: 妥当と判定。repo内限定・単一開発者運用だが、全サイクルのtest実行SSOTである`run-tests.sh`本体・mirror条項・ADRを同時に触るblast radiusを踏まえた判断として承認。再承認不要
- **Files to Change 13件（>10）の裁定**: 削除主体のcycleとして許容。内訳: 削除1件（`.claude/test-serialization.json`）、mirror必須ペア2件（`rules/plan-discipline.md`+`.claude/rules/plan-discipline.md`）、changelog/next 2件、実質的な設計変更を伴う本体ファイルは実質8件程度。YAGNI違反なし
- `bash scripts/gates/pre-red-gate.sh docs/cycles/20260916_1634_shrink-runner-remove-nesting.md` を real-path 実行し PASS（exit 0）を確認
- テスト実行について: 本検証中、フルスイート・`tests/test-doc-consistency.sh` は一切起動していない（起動禁止指示を遵守）。事前に `pgrep -f 'run-tests'` = 0 を確認済み。実行したのは `grep`/`awk`/`shasum`/`diff`/`ls`/`stat` 等の読み取りコマンドと `pre-red-gate.sh`（単体 deterministic gate）のみ
- **Design Review Gate 判定: WARN**（3分岐: 転記欠落=0、scope実質変更=0、軽微な不整合2件+観察2件=DISCOVERED記録済み）。orchestrate は警告付きで Block 2a (RED) へ進行可
- Phase completed

---

## Next Steps

1. [Done] KICKOFF <- Current
2. [Next] RED
3. [ ] GREEN
4. [ ] REFACTOR
5. [ ] REVIEW
6. [ ] COMMIT
7. [ ] DONE

### 2026-09-16 17:07 - RED
- **削除対象 31 TC の実在確認**（`tests/test-run-tests-runner.sh`、grep 実測）: 設定ファイル TC-11(L579)/TC-12(L698)/TC-13(L720)、load TC-05(L410)/TC-10(L556)、memory TC-06(L435)、fail-open TC-07(L461)/TC-08(L482)/TC-09(L537)、三点照合等 TC-21(L909)/TC-22(L939)/TC-23(L974)/TC-24(L1000)/TC-24b(L1024)/TC-25c(L1093)、owner/reaper TC-28(L1256)/TC-29(L1274)/TC-29b(L1300)/TC-30(L1322)/TC-31(L1338)/TC-32(L1354)/TC-33(L1369)/TC-34(L1387)/TC-35(L1402)/TC-35b(L1422)、advisory TC-36(L1452)/TC-37(L1466)/TC-38(L1493)、lib-only TC-45(L1523)、除外oracle TC-04(L356)/TC-04b(L378)。**31 件全て実在を確認（3+2+1+3+6+10+3+1+2=31、Test List 記載と一致）**。誤りなし
- **番号衝突の別物2件の実在確認**: `tests/test-doc-consistency.sh` TC-13（L820「All existing tests pass」、nested 全実行）、`tests/test-factory-model-adaptation.sh` TC-14（L153「既存テスト全PASSの確認」、nested 全実行）。いずれも `tests/test-run-tests-runner.sh` 内の同番号 TC とは別物であることを実測確認（Cycle doc の注記どおり）
- **新設 TC 2件・変更 TC 3件を `tests/test-run-tests-runner.sh` に実装**（`run-tests.sh` 本体は不変更、削除の実行なし）:
  - TC-49（新規1、コピー失敗 exit 2）: fixture に `cp` shim（PATH 差し替え、既存 pgrep/sysctl/vm_stat shim と同形式、new_fixture へ追加、デフォルト real passthrough）を追加し fail モードで検証。**実測 FAIL**（現行は exit 5。目標 exit 2 は B の縮小後）
  - TC-50（新規2、残骸警告）: 単一 TC 内に 50-a（通常 SAFE_TMPDIR 下の残骸を警告・削除しない）/50-b（0件時は stderr 完全無音）/50-c（TMPDIR が repo 配下で /tmp へ fallback した経路でも実際の fallback 先を走査する。symlink 差異のため basename で照合）を TC-42/44 と同じ ok/detail 集約パターンで実装。**実測 FAIL**（50-a, 50-c: 現行は残骸警告機能自体が存在しない。50-b: 現行は元々無音のため単体では PASS ―― 全体は 1 ラベルなので FAIL 集計）
  - TC-44（変更）: 「## 具体例」チェック（既存、regression pin）に加え「## 推奨」の direct loop 不在チェックを `rules/plan-discipline.md` 本体・mirror 両方に追加。**実測 FAIL**（両ファイルとも「## 推奨」に `for f in tests/test-*.sh` が現存）
  - TC-46（変更）: compute_manifest の mktemp 内部機構検証（三点照合ごと削除予定）から、「TMPDIR が repo 配下でも snapshot が source tree 外に作られる」最小の境界チェック検証へ縮小。**実測 PASS**（regression pin。determine_safe_tmpdir は B で「残す」対象のため不変。TC-40/41 と同型の pre-existing-PASS pin）。**vacuous でないことを棄却実験で確認**: fixture コピー限定で fallback 行（`candidate="/tmp"`）を無効化したところ、$SNAP が $BASE_DIR 内に作られ `cp -Rp` が自己再帰コピーに陥り完走せず（timeout で強制終了。rc は観測できなかったが「静かに PASS する」壊れ方ではないことは確認）。ホストメモリ保護のため完走までは待たず、trap による fixture 後始末（残留プロセスなし・残留ディレクトリなし `ps aux`/`find` で確認済み）を確認して終了。**GREEN への警告**: determine_safe_tmpdir（run-tests.sh L524-543）の fallback ロジックへの回帰はテスト失敗ではなく**ハング**として現れるため、周辺機構を削る際にこの関数の中身へは触れないこと
  - TC-48（変更）: `DEV_CREW_TEST_HOOK_BEFORE_COPY` 依存を、fixture 専用の `cp` shim（delete-before モード。本番コードの hook 変数を一切参照しない）へ差し替え。**実測 PASS**（regression pin。F2 の検証対象ロジック自体は本 cycle で不変のため）。**vacuous でないことを棄却実験で確認**: shim を real モード（削除なし）に変えると rc=0 に反転し assertion が FAIL することを確認 ―― shim の削除動作が rc=3 を駆動していることの証明
- **フルスイート実行**（`bash tests/test-run-tests-runner.sh`、許可されたコマンド。`test-doc-consistency.sh`/`test-factory-model-adaptation.sh` は起動せず）: PASS 57 / FAIL 3、ラベル数 60（既存 58 + 新規 2）。FAIL は TC-44 / TC-49 / TC-50 の 3 件のみで設計どおり。他 55 ラベルは無回帰（`cp` shim 追加の副作用なし。TC-12 の PATH 全置換・TC-04 の独自起動を含め確認）。末尾の `Killed: 9 sleep 600` は TC-02/TC-04b が起動した背景 sleep を `cleanup_all` trap が正常に後始末した際のログであり異常ではない
- **DISCOVERED 候補（RED では追加せず報告のみ）**: exit code 1（「実行したテストの FAIL のみ、流用禁止」）を単独で pin する生存 TC が現状ゼロ（`grep -n 'RUN_RC" -eq 1'` 該当なし）。31 件削除後にこの契約を守る TC が本当に無くなるため、GREEN or 別 cycle での追加を検討要
- **GREEN への申し送り**: (1) ファイルヘッダ L3 の「TC-01~TC-48 ... (58 total)」は TC-49/50 追加で既に古い。31 削除時に併せて書き換えること。(2) TC-48 のコメント中「manifest mismatch で 1 回リトライ」は三点照合削除後は成立しない記述のため、リトライ機構削除と同時に文言を整理すること
- Phase completed

### 2026-09-16 17:25 - GREEN
- **ステップ1（A: 入れ子除去）を単独計測**: `tests/test-doc-consistency.sh` の TC-13 と `tests/test-factory-model-adaptation.sh` の TC-14 を削除。計測は「A のみ適用（B は未適用、run-tests.sh は旧版のまま）」の状態で実施（scratchpad にバックアップした旧 run-tests.sh を一時的に戻し、A 適用後の test-run-tests-runner.sh は当然 FAIL するため計測目的でのみ実行、結果は破棄）。`time (bash run-tests.sh)` 実測: **154.82s (2:34.82)**、TOTAL: **117**（PASS 116 / FAIL 1 = test-run-tests-runner.sh。旧 run-tests.sh と新 test-run-tests-runner.sh の版ずれによる想定内 FAIL、A の効果測定には無関係）。458→117 の実行回数低減を実測確認
- **ステップ2（B: run-tests.sh 縮小）を実装**: 指紋の三点照合（compute_manifest/compute_manifest_or_fail/manifest A/B/C 比較）・再試行プロトコル（MAX_SNAPSHOT_ATTEMPTS）・PID/起動時刻/所有者/reaper（write_owner_metadata/is_stale/owner ベースの startup_cleanup）・admission の load/memory 判定（eval_load/eval_mem/K_LOAD/MEM_MIN_MIB）・config 読み込み全体（.claude/test-serialization.json・jq・get_num_key/get_bool_key/load_config）・実行後 live tree advisory（report_live_changes/FINAL_SOURCE_MANIFEST）・`DEV_CREW_RUNNER_LIB_ONLY`・`DEV_CREW_TEST_HOOK_BEFORE_COPY`/`DEV_CREW_TEST_HOOK_AFTER_COPY` を削除。source tree 境界チェック（determine_safe_tmpdir）・pgrep 自己祖先除外（build_exclude_set/is_excluded_pid）・admission のプロセス数判定（eval_pgrep）・コピーして実行（cp -Rp、単発、再試行なし）・trap による正常終了/TERM/INT/HUP 時の cleanup・F2（run_tests_in_snapshot 内の snapshot 再検証）は温存。新設: `startup_residue_scan`（境界判定後の実際の SAFE_TMPDIR を existence-guarded glob で走査し、残留 snapshot を警告のみ・削除しない・0 件時 stderr 無音）。exit code を 0/1/2/3 に統合（旧 4/5 は起動不能系として 2 に統合）。run-tests.sh: 1068 行 → 479 行
- **ステップ2完了後を単独計測**: `time (bash run-tests.sh)` 実測: **148.96s (2:28.96)**、PASS 117 / FAIL 0、exit 0。B 適用前後で **154.82s → 148.96s**（約 4% 減、誤差範囲に近い）。**推定（約11分→約3分）との差異を報告**: A 単独の時点で既に 154.82s（約2.6分）に達しており、推定の「約3分」にほぼ到達していた。B は複雑さ・保守負債の削減が主目的であり（cycle doc Implementation Notes 表参照）、追加の wall-clock 短縮は小さかった（三点照合・再試行・load/memory 判定は「発火しない限りコストがほぼゼロ」な分岐だったため、削除の効果は速度でなく複雑さに出た）。推定は方向として正しかったが、内訳（Aで大半、Bはわずか）は plan の想定より偏っていた
- **rules/plan-discipline.md（+ mirror）**: line 23「Block 0 で `for f in tests/test-*.sh; ...` を実行し baseline を実測する」を「Block 0 で `bash run-tests.sh` を実行し baseline を実測する（正規 runner を使う。独自の direct loop を書かない）」へ変更。`.claude/rules/plan-discipline.md` に同一内容を複製（diff -q で完全一致確認）
- **`.claude/test-serialization.json` を削除**（`git rm --cached` + `rm -f`）。`.gitignore` の negation 行 `!.claude/test-serialization.json` を削除
- **`skills/spec/templates/cycle.md`**: 汎用テンプレートの direct loop（line 116 `for f in tests/test-*.sh; do bash "$f"; done`）はそのまま残し、直後に「dev-crew 自身の repo では run-tests.sh を使う」旨の注記のみ追加（他プロジェクトへ存在しないコマンドを配布しない）
- **`docs/OVERVIEW.md`**: exit code 表を 0/1/2/3 に更新（4/5 削除、signal 系は別枠と明記）。「テストの走らせ方」の説明文を load/memory admission 前提から admission=プロセス数のみ・残骸は警告のみへ修正。「最近変えたところ」に本 cycle の行を追加し、「未解決の課題（縮小を検討中）」を解決済みとして書き換え
- **TC 追加（RED が発見した欠落を埋める）**: TC-49（コピー失敗 exit 2 を単独 pin）は RED で既に実装済み。exit 1（実行したテストの FAIL のみ、流用禁止）を単独で pin する生存 TC が引き続きゼロである点は RED の DISCOVERED 候補のまま据え置き、本 cycle の scope（Test List 新設 2 件 = TC-49/TC-50）に含まれないため追加しない。DISCOVERED へ転記
- **tests/test-run-tests-runner.sh**: 31 TC を削除（TC-04/04b/05/06/07/08/09/10/11/12/13/21/22/23/24/24b/25c/28/29/29b/30/31/32/33/34/35/35b/36/37/38/45）。削除は TC 単位のブロック delete（sed 範囲指定、境界を手動確認）。ヘッダコメント（TC 範囲・invented contracts・exit code 説明）を実態に合わせて書き換え。TC-44/46/48 は RED 実装済みのものをそのまま使用（変更なし）
- **tests/test-doc-consistency.sh**: TC-13（全テスト nested 実行）を削除。ヘッダの「欠番」リストに 13 を追加
- **tests/test-factory-model-adaptation.sh**: TC-14（全テスト nested 実行）を削除。ヘッダコメントを更新
- **フルスイート最終結果**: `bash run-tests.sh` PASS 117 / FAIL 0 / TOTAL 117、exit 0（上記ステップ2計測時の実行と同一）。`bash tests/test-run-tests-runner.sh` 単独: PASS 29 / FAIL 0（28 ラベル、TC-27/TC-27b が 1 ラベル内 2 assertion）
- **既存契約の非回帰確認**: `tests/test-rules-mirror.sh`（PASS 3/3）、`tests/test-codify-rule-docs.sh` TC-30（PASS）、`tests/test-spec-onboard-improvements.sh` TC-06（PASS）、`tests/test-evolve-contribute.sh` TC-20（PASS）、`tests/test-post-approve-gate-removal.sh` TC-07（PASS）を個別実行し確認
- **複雑さ予算 6 項目、全て 0 を確認**: 新しい永続状態・metadata=0（owner metadata 削除のみ、新設なし）／新しい lifecycle・cleanup protocol=0（trap ベースの既存 cleanup を維持、residue scan は警告のみで新しい protocol ではない）／新しい設定形式=0（config を削除のみ、新設なし）／新しい exit code=0（4/5 を 2 へ統合、減らす方向のみ）／新しい OS 固有意味論への依存=0（cp -c 不採用のまま）／並行性・所有権・時刻の扱い=0（PID/owner/start token 追跡を削除のみ、新設なし）
- **実装差分（net negative 確認）**: `git diff --stat` で 10 ファイル変更、+366 / -1703（.claude/test-serialization.json の削除含む）。net -1337 行
- **メモリ状況**: 実行前後で `vm_stat` の Pages free を都度確認（実測範囲 64MB〜363MB で推移、逼迫時は待機。負荷をかけての guard 試行はせず）。`pgrep -f 'run-tests'` は各実行前に 0 件を確認
- **git checkout -- は使用せず**。作業前に scratchpad へ全対象ファイルをバックアップ（shasum -a 256 記録済み、復元可能）
- Phase completed

### 2026-09-16 17:36 - REFACTOR
- **ADR-004（`docs/decisions/adr-test-isolation-boundary.md`）を全面書き直し**: 旧草案は「コピーが重い」という誤った前提（APFS clone検討）の上に立っていたため実測に基づき刷新。Status: `deferred` → `accepted`。決定事項（入れ子除去・コピーは残す・三点照合/PID/所有者/reaper/load/memory admission/live tree advisory/hookを削除・排他ロック不採用・exit code 0-3）、受容する失敗5項目（B-2参照: 混成snapshot／実行中の混読は防ぐ／残骸は自動削除しない／全スイート保証はrun-tests.sh実行時のみ／自己・祖先除外は検証手段を失う）、メモリ判定の実測（`free + inactive` 6,198MB 報告 vs 実 `Pages free` 75MB、80倍過大評価）、A/Bの速度寄与の分離（A単独154.82秒でほぼ到達、B適用後148.96秒＝約4%・誤差域）を明記。`docs/decisions/TEMPLATE.md` の形式（Status/Context/Decision Scorecard/Arguments(Accepted/Rejected/Deferred)/Decision/Consequences）に準拠
- **`hook.*でブロックされる` 逆向き契約（TC-07）を遵守**: ADR本文・CHANGELOG追記の両方で該当綴りを使用していないことを `grep -rE 'hook.*でブロックされる' --include="*.md" . | grep -v docs/cycles/ | grep -v docs/archive/` で実測確認（0件）
- **CHANGELOG.md `[Unreleased]` に `### Removed` セクションを追記**: 入れ子除去（458→117回）・run-tests.sh縮小（1,068→479行、削除した機構の列挙、メモリ判定の実測根拠）・ADR-004 accepted化を記録。縮小（B）の速度寄与が小さいこと（148.96秒、Aの154.82秒から約4%）を明記し「速度改善のほぼ全部はAの効果」と誤解を防ぐ記述にした
- **`docs/NEXT.md` item 4 を更新**: 見出しを「Cycle A 完了 / Cycle B・C 残」→「Cycle A・B 完了 / Cycle C 残」に変更。Cycle Bで完了した内容（入れ子除去・run-tests.sh縮小・排他ロック不採用確定）とA/B速度寄与の分離を追記。残タスクを「hookによるinlineループ誘導（TC-07契約の縮小要否含む）」「Insight 4のhook改修」「排他ロック（必要性が実測されるまで不採用、時間経過だけでは着手しない）」の3項目に整理。「Insight 4のhook改修」の出典を実測で特定: `docs/cycles/20260913_0059_runner-admission-snapshot.md` Retrospective Insight 4（safety hookがコマンド文字列全体でなく実行文脈で判定すべき、という診断）
- **`run-tests.sh`（479行）を `rules/test-patterns.md` の bash 落とし穴チェックリストと照合**: 該当箇所なし。`raw="$(pgrep ...)"; rc=$?` の直後rc取得、`cp_err="$(cp ...)"` 後の直後`$?`チェック（間に他コマンドなし、rules #2の「並置」パターンには非該当）、here-stringによるwhile消費（pipe/process substitution回避）、`bash subject | grep -q`直接pipeの不使用、をいずれも確認。**振る舞い変更は行っていない**（DISCOVEREDへ送る改善提案も無し。既存コメントは全てWHY型で、追跡番号ではなく`docs/cycles/*.md`への相対パス参照——この repo の scripts/gates・scripts/hooks 全体で確立された規約——であり書き換え不要と判断）
- **`docs/OVERVIEW.md` を再確認**: exit code表（0/1/2/3、signal別枠）・「テストの走らせ方」（admission=プロセス数のみ、残骸は警告のみで削除しない）が実装と一致することを確認。派生数値（行数・TC数）の新規追加なし（既存の「最近変えたところ」表にある458→117回の記述は本cycle自身の変更点を説明する履歴的記述であり、変更しなかった）
- `bash run-tests.sh` フルスイート実測: PASS 117 / FAIL 0 / TOTAL 117、exit 0（実行前 `pgrep -f 'run-tests'` = 0、`vm_stat` Pages free 確認済み）
- Phase completed

### 2026-09-16 18:10 - GREEN (mini-iteration)
- **対象**: REVIEW 指摘の mini-iteration。Codex BLOCK 3 件（A2/A3/B2 相当）+ Claude WARN 4 件（A1/A2/B1/C 相当）を解消。前 REVIEW 時点のベースラインは `bash run-tests.sh` 117/117 PASS（158秒）・`bash tests/test-run-tests-runner.sh` 29 アサーション/28 ラベル PASS
- **A1（exit 1 未 pin、Claude WARN）**: `tests/test-run-tests-runner.sh` に **TC-52** を新設。`exit 42` で終了する dummy test（`test-zz-failing.sh`）を追加し、`RUN_RC == 1` かつ stdout に `FAIL: 1` と失敗テスト名が現れることを pin。**non-vacuous 実測確認**: `run-tests.sh` 末尾の `exit 1` を一時的に `exit 9` へ mutate（scratchpad にバックアップ済みの状態から sed 編集 → 検証 → 復元）したところ TC-52 が FAIL（rc=9）することを確認し、mutate 前の状態に `diff` で完全一致復元
- **A2（pgrep fail-open 3 経路未検証、Codex+Claude 両 WARN/BLOCK）**: **TC-51** を新設。`set_pgrep_absent()`（定義済み・呼び出しゼロだった fixture helper）を含む 3 サブケース（51-a: probe absent = rc=127 で「rc>=2」分岐と共有、51-b: rc=0 かつ非数値出力、51-c: rc=0 かつ空出力）で、admission が SKIP（stderr にその旨）しつつ BLOCK 化・クラッシュ化せず実行が snapshot まで進むことを pin。**non-vacuous 実測確認（2 回の独立した mutation 実験）**: (1) `eval_pgrep()` の「rc>=2」分岐を `skip`→`block` に mutate → 51-a が FAIL（rc=2、where 空）することを確認・復元。(2) 「rc=0 空出力」「rc=0 非数値」の両分岐を `skip`→`ok`（stderr 無出力）に mutate → 51-b/51-c が FAIL（stderr 空で skip 未検出）することを確認・復元。3 経路とも独立に検出力を持つことを実証
- **A3（TC-49 が検証対象未到達、Codex BLOCK）**: `build_snapshot()` は parent doc コピー（`run-tests.sh:368` 付近）→ repo コピー（`:377` 付近）の順で最大 2 回 `cp` を呼ぶが、fixture の `cp` shim `fail` モードは**全呼び出し**を失敗させるため、旧 TC-49 は parent doc が fixture に存在する状態で実行され、常に**最初の**（parent doc）コピーで止まっていた（メッセージは `failed to copy the parent doc`）。TC-49 の直前に `rm -f "$F_REPO/docs/test_architecture.md"` を追加して `[ -f "$PARENT_DOC_SRC" ]` ガードを false にし、`cp` 呼び出しを repo コピー 1 回のみに限定。assertion に `failed to copy the repo` の literal pin を追加（rc のみでは経路を区別できないため）。**non-vacuous 実測確認**: 追加した `rm -f` 行を一時的に無効化（旧の壊れた形へ戻す）して実行したところ、TC-49 が FAIL し、実際のエラーメッセージが `failed to copy the parent doc`（`failed to copy the repo` ではない）であることを確認 — Codex 指摘の「本来検証したい repo コピーに到達していない」を直接再現。復元して TC-49 が PASS に戻ることを確認
- **B1（rules/plan-discipline.md が削除済み機構を現行扱い、Codex BLOCK 相当）**: `rules/plan-discipline.md`（+ mirror `.claude/rules/plan-discipline.md`、`cp` 後 `diff` で完全一致確認）の「## 具体例」（旧: 「…三者照合（A==B==C）+ 起動時掃除を内包する正規 runner…」）と「## 出典」（旧: 「…三者照合を内包する正規 runner…」）を、本 cycle B で実際に残った機構（admission[プロセス数判定のみ] + 境界チェック付きコピー + 起動時の残骸警告[削除はしない]）を正しく記述する文言へ書き換え。「## 出典」には cycle 20260916_1634 の参照を追加し、三点照合等は「cycle 20260916_1634 で削除済み」と明記（現在時制での誤claim を除去）。**TC-44 を拡張**: 既存の「## 具体例」「## 推奨」チェックに加え、「## 具体例」「## 出典」の両方について `三者照合` という literal が（rules/ と mirror の両方で）不在であることを負のアサートとして追加。実測: 修正前の状態で TC-44 を実行すると FAIL（この負のアサート自体は前の GREEN で見逃されていた通り）、修正後は PASS することを `bash tests/test-run-tests-runner.sh` の一括実行で確認
- **B2（削除済み機構を指すコメントの一掃、Claude WARN）**: (1) ファイルヘッダ（旧: 「TC-28~38 and TC-45」のみで削除範囲を過小記述）を実測ベースの完全な内訳（TC-04/04b・05/06/10・07/08/09・11/12/13・21/22/23/24/24b/25c・28~35/35b・36/37/38・45、計31件）へ書き換え。(2) TC-48 のコメント（旧: 「compute_manifest attempt 1 の pre-copy manifest_A ... 1 回リトライ」を現行動作であるかのように記述）を、三点照合・リトライが削除済みで該当しない旨へ書き換え。(3) `run_subject()` の `EXTRA_ENV` コメント（旧: 「callers (TC-21/22/23/24/25c/37)」= 全て削除済み TC）を実際の呼び出し元（TC-46/TC-50）へ修正。(4) `add_git_repo()` のコメント（旧: 「for TC-25b/25c only」、TC-25c は削除済み）を「for TC-25b only」へ修正
- **C（さらに削る、両 reviewer 指摘）**: 削除前に `grep` で全て未参照であることを確認してから削除。(1) `NOJQ_BIN` jq-absence farm（削除済み TC-12 専用、run-tests.sh は jq を一切呼ばないことを `grep -n jq run-tests.sh` で確認 = 該当なし）。(2) `sysctl`/`vm_stat` PATH shim 一式 + `set_sysctl_*`/`set_vmstat_*`/`vmstat_text`/`set_vmstat_fake_pages`（production の `run-tests.sh` が `sysctl`/`vm_stat` を一切呼ばないことを実測確認。呼び出し元は `set_admission_healthy()` のみだったため同関数を `set_pgrep_fake 1 ""` のみへ簡略化）。(3) `write_config()`（定義のみ、呼び出しゼロ）。(4) `mk_stale_snap()`/`touch_backdate()`（定義のみ、呼び出しゼロ。削除済み TC-28~35b 専用）。(5) `new_fixture()` 内の `.claude/test-serialization.json` 生成（+ `mkdir` の `.claude` ディレクトリ）。A2 で `set_pgrep_absent()` を使うため `pgrep` shim は残置（指示どおり）。`cp` shim も TC-48/49 で使用中のため残置
- **D（ADR + Cycle doc の補完）**: (1) `docs/decisions/adr-test-isolation-boundary.md` の Consequences（受容する失敗）に項目 6「`pgrep` probe 利用不可時は admission を fail-open で skip する」を追記（Implementation Notes の B 表には既にあったが ADR 本体への転記漏れだった）。(2) 本 Cycle doc の構造化 `### DISCOVERED` セクションに項目 6「`exit 1` を単独で pin する生存 TC が存在しなかった」を追記し、A1 で TC-52 として解消済みである旨を併記
- **フルスイート最終結果**: `bash run-tests.sh`: PASS 117 / FAIL 0 / TOTAL 117, exit 0（実行前 `pgrep -f 'run-tests'` = 0 を確認、バックグラウンド実行の完了を `pgrep` ポーリングで待機してから結果確認）。`bash tests/test-run-tests-runner.sh` 単独: PASS 31 / FAIL 0（30 ラベル / 31 アサーション、TC-27/TC-27b が 1 ラベル内 2 assertion。TC-51/TC-52 の新設分でラベル 28→30、アサーション 29→31）
- **非回帰確認**: `tests/test-rules-mirror.sh`（PASS 3/3）、`tests/test-codify-rule-docs.sh` TC-30（PASS）、`tests/test-post-approve-gate-removal.sh`（PASS 8/8、TC-07 「hook.*でブロックされる」0件を含む。全体 grep でも本 mini-iteration が触れたファイル群に該当文言は Cycle doc 自身の grep コマンド記述内の 1 件のみ = 対象外仕様どおり）を個別実行し確認
- **`git diff --stat` net negative 確認**: 12 ファイル変更、+523 / -1863（`.claude/test-serialization.json` 削除含む）。net **-1340 行**（前 GREEN 終了時点の net -1337 から、A1/A2 の新設 TC 分の増加を C の追加削除が上回り、さらに 3 行深掘り）
- **破壊的操作なし**: `git checkout --` は使用せず。作業開始前に `rules/plan-discipline.md`・`.claude/rules/plan-discipline.md`・`run-tests.sh`・`tests/test-run-tests-runner.sh`・`docs/decisions/adr-test-isolation-boundary.md`・本 Cycle doc を scratchpad へバックアップし `shasum -a 256` を記録（復元可能性を確保）。mutation 実験は全て一時編集 → 検証 → `cp` で backup から復元 → `diff`/`shasum` で完全一致確認のサイクルで実施し、`run-tests.sh` は本 mini-iteration の最終状態で backup と完全に同一（byte-identical, shasum 一致）であることを確認済み（production コード自体は変更していない — 今回の全修正は `tests/`・`rules/`・`docs/` のみ）
- **メモリ状況**: 実行前後で `vm_stat` の Pages free を都度確認（実測範囲 約 60MB〜140MB で推移、フルスイート実行はバックグラウンドで開始し `pgrep` ポーリングで完了待機。負荷をかけての guard 試行はせず）。`pgrep -f 'run-tests'` は各実行前に 0 件を確認
- Phase completed

### 2026-09-16 18:21 - REVIEW

**competitive review（Codex + Claude）を実施。**

**Round 1 — Codex: BLOCK 3 件**

| # | 指摘 |
|---|---|
| 1 | **TC-49 が検証対象に到達していない。** `cp` shim の fail モードが全呼び出しを失敗させるため、最初の parent doc コピーで止まり **repo コピー経路（`run-tests.sh:377`）に達していなかった**。メッセージも `failed to copy the parent doc` で、両方 exit 2 のため rc だけ見て通っていた |
| 2 | **`exit 1`（実行したテストの FAIL のみ）を pin する TC がゼロ。** RED が欠落を発見し PdM が GREEN へ追加を指示したが**実施されていなかった** |
| 3 | **`pgrep` fail-open の 3 経路（probe 不在 / 非数値 / 空出力）が未検証。** fixture helper `set_pgrep_absent()` は定義済みだが呼び出しゼロ |

**Round 1 — Claude: WARN 4 件 / INFO 4 件**（BLOCK なし）

Codex と重複: `exit 1` 未 pin / `pgrep` fail-open 未検証 / fixture の死んだ足場 / TC-48 コメントの陳腐化。

**Claude のみが検出**: **`rules/plan-discipline.md:47`（+ mirror）が、本 cycle で削除した三者照合と起動時掃除を現行動作として記述したまま。** 当該ファイルは Files to Change に含まれ実際に編集したにもかかわらず、削除機構の説明が残っていた。TC-44 はこの文言の不在を検査していなかったため契約もすり抜けた。

Claude はさらに **PdM の前提の誤りを訂正**した。委譲文に「`exit 1` の TC は 1 件追加された経緯がある」と書いたのに対し「実際にはまだ埋まっていない。プロンプトの前提は実測と食い違う」と指摘し、これが正しかった。

**mini-iteration**: 7 件すべて解消。

- **TC-52 新設**（`exit 1` の単独 pin）。`exit 1` → `exit 9` の mutation で検出力を実証
- **TC-51 新設**（`pgrep` fail-open 3 経路）。skip→block と skip→ok の 2 種類 mutation で各経路の検出力を実証
- **TC-49 修正**。parent doc を除去して repo コピー経路のみ通し、`failed to copy the repo` の literal を pin。**修正前の形に戻すと対象外経路で FAIL することを実測確認**
- `rules/plan-discipline.md` + mirror を実態へ修正、TC-44 に三者照合の不在アサートを追加
- **fixture の死んだ足場を削除**（`NOJQ_BIN` farm / `sysctl`・`vm_stat` shim 一式 / `write_config()` / `mk_stale_snap()`・`touch_backdate()` / legacy 設定ファイル生成）。全て grep で未参照確認後
- ADR Consequences に `pgrep` fail-open skip を追記

**`run-tests.sh` は mini-iteration 前後で byte 一致。** 指摘は全てテスト側と doc 側であり、**production の振る舞いは一切変えていない**。「テストが守っていなかった」のであって「実装が壊れていた」のではない。

**Round 2 — Codex: 実装 BLOCK 3 件は閉じたが記録不整合で commit 待ち**

- Cycle doc の `test_count` が 28 のまま（実装は 30 ラベル / 31 アサーション）。**複雑さ予算の合格条件に「Test List で削除群と残す群を列挙できること」を掲げながら、自分の合格条件を満たしていなかった**
- ADR と Cycle doc の残骸 scan 記述が生の `$TMPDIR` を走査すると読める（実装は境界判定後の snapshot root を走査）

**記録修正**: `test_count: 30` へ。**承認時点の想定（28）と最終実績（30）を両方残し**、mini-iteration で 2 件追加した経緯を明記した（数字だけ上書きすると承認時の合意と最終形の差が見えなくなる）。走査対象の記述も両文書で実装に合わせた。follow-up 指摘（fixture コメント、未参照 helper `set_pgrep_real` / `reset_evidence`）も同時に解消。

**最終結果**: `bash run-tests.sh` **PASS 117 / FAIL 0**、`bash tests/test-run-tests-runner.sh` **PASS 31 / FAIL 0**（30 ラベル）。差分 **+524 / −1,866（net −1,342 行）**。

**判定: PASS**

- Phase completed

## Retrospective

### Insight 1: 「遅い」の原因を測らずに対策を作った — 前 cycle の 1,068 行は速度に一切寄与していなかった

- **Failure**: 前 cycle（`20260913_0059`）は「テストが 13〜17 分かかる」を所与とし、**原因を測らずに**「コピーを取る → コピーの整合性を保証しなければ」と進んで、指紋の三点照合・PID 追跡・所有者記録・再試行プロトコル・exit code 体系を積み上げた。35 行が 1,068 行になった
- **Final fix**: 本 cycle で先に測った。遅さの正体は **2 本のテストがスイート全体を再実行していること**（延べ 458 回）で、**コピーは 2.04 秒**だった。入れ子を除去すると **154.82 秒**、`run-tests.sh` を 479 行へ縮小しても **148.96 秒**
- **Insight**: **B（縮小）の追加短縮は約 4% で誤差域。速度改善のほぼ全部が A（入れ子除去）の効果だった。** つまり前 cycle が作った 1,068 行は、速度問題の解決に**一切寄与していなかった**
- **一般化**: 「X が遅い」を受け取ったら、**X の内訳を測るまで対策を設計しない**。前 cycle は「コピーが必要」までは正しく、「だからコピーを保証する機構が要る」で外した。**正しい前提から誤った問題へ滑る**経路がある

### Insight 2: 保守負債は「対策の形」で何ヶ月も可視化されないことがある

- **Failure**: 入れ子実行は 2026-04-21 の時点で「無限再帰のリスク」として認識され、対処は **skip 条件の追加**だった。2026-04-27 には `TC-14` の timeout が **30 → 60 → 90 秒**へ拡張され、skip リストに 3 本が追加された。理由は「recursive meta-tests で cascade timeout が発生し flaky FAIL を引き起こしていた」
- **Final fix**: 本 cycle で **TC-13 / TC-14 を削除**した。どちらも「全テストを実行する」だけで `run-tests.sh` と役割が重複していた
- **Insight**: **この repo は約 5 ヶ月、timeout 調整・skip リスト拡張・flaky FAIL 調査という保守コストを払い続けていた。その全部が「runner と重複する構造」を維持するための出費だった。** 誰も「そもそもなぜ個別テストがスイート全体を再実行するのか」を問わなかった
- **一般化**: **同じ箇所に対策が繰り返し積まれているとき、対策ではなく構造を疑う。** timeout の延長・skip リストの拡張・除外条件の追加が続いたら、それは「その構造が間違っている」という信号である

### Insight 3: 新設した TC が vacuous である事故が、1 cycle で 4 回起きた

- **Failure**: 本 cycle と前 cycle で、**新設・既存の TC が「何も守っていない」ケースが 4 件**見つかった

| TC | 何に隠れていたか | 発見者 |
|---|---|---|
| TC-04 / TC-04b | macOS `pgrep` が OS 既定で自己と祖先を除外する | 変異注入 |
| TC-46 初版 | BSD `mktemp` が `$TMPDIR` より `_CS_DARWIN_USER_TEMP_DIR` を優先する | 実装者の自己検証 |
| TC-49 | `cp` shim が全呼び出しを失敗させ、**対象外の経路（parent doc）で成功していた** | Codex code review |
| （`exit 1` の pin） | そもそも存在しなかった。PdM が追加を指示したが実施されず | RED が発見、Codex と Claude が再指摘 |

- **Final fix**: いずれも**修正前の実装に戻して FAIL することを実測**してから確定した
- **Insight**: **「テストを追加した」は「契約が守られた」の証拠にならない。** 4 件とも追加・存在の時点では気づけず、変異注入・棄却実験・別 reviewer が見つけた。特に TC-49 は **rc だけを見て経路を区別していなかった**ため、名前と実際の検証対象が食い違っていた
- **一般化**: 新設 TC は**修正前の実装で FAIL することを実測する**。rc だけでなく**メッセージも pin**して経路を区別する

### Insight 4: 問いの向きが答えの向きを決める — 今回は削除方向で機能した

- **Failure**（前 cycle）: 「穴を探せ」とだけ聞いた結果、5 ラウンドで BLOCK が積み上がり、指摘は 1 件ずつ全部正しいまま全体が肥大した
- **Final fix**（本 cycle）: レビュー依頼に「**追加方向の指摘だけでなく、さらに削れる箇所があればそれも指摘してください**」を明示的に含めた
- **Insight**: 結果、**両 reviewer が独立に同じ 120 行の死んだ足場を指摘**した（production から機構を削ったのにテスト側の shim が丸ごと残っていた）。Codex は load admission の削除まで提案し、それに伴って設定ファイル・`jq` 処理・`.gitignore` の例外がまとめて消えた
- **一般化**: **レビューの問いに削除方向を含めないと、削除方向の指摘は出ない。** モデルを変えても問いが同じなら両方とも追加方向にしか働かない（前 cycle の観測）。逆に問いを変えれば、同じモデルが削除方向を出す

### Insight 5: 条項は「読まれない」段階でも失敗する

- **Failure**: `rules/doc-mutations.md` は「informal 略称（eval-N、A2b、**Cycle B**）は永続 artifact では使わない。cross-reference は絶対識別子で行う」と定めており、**`Cycle B` を禁止例として名指し**している。さらに `docs/cycles/20260424_1119` は**この alias を除去するためだけに回された cycle** で、対応表まで作られていた。それでも PdM は `Cycle A/B/C` を使い、REFACTOR で呼称が衝突した（`Cycle B` は履歴上 **4 つの別物**を指していた）
- **Final fix**: 全て filename prefix 参照へ置換し、`docs/NEXT.md` に経緯を注記した
- **Insight**: 前 cycle の Insight 4 は「**条項を読み、引用しさえしたが、適用先を狭く解釈した**」だった。今回は**その手前で、条項を読んですらいない**
- **一般化**: 条項の失敗には少なくとも 3 段階ある。**(1) 読まれない (2) 読んでも適用先を誤る (3) 適用しようと書いた文章自体が違反になる**（前 cycle の Insight 4、safety hook の綴り問題）。**(1) は条項を増やしても解けない。** 機械側（gate・hook）でしか塞げない

### 想起漏れ

- **設問**: 今回の手戻りは、過去のどの cycle doc を最初に読んでいれば防げたか
- **回答**: **`docs/cycles/20260427_0930` と `docs/cycles/20260421_1043`。そして実際に読んで、実際に効いた。**
  - Recall で両方が上位に出た。`20260421_1043` Insight 5（TC-13 の無限再帰リスク、対処は skip 条件の追加）と `20260427_0930`（timeout 30→60→90、skip リスト拡張、cascade timeout による flaky FAIL）
  - **この 2 件が「削除」という結論の最も強い根拠になった。** 「対策が繰り返し積まれている ＝ 構造が間違っている」という読み方ができたのは、履歴が残っていたから
  - 前 cycle で codify した「Recall に引用だけでなく**適用先を 1 行書く**」も実行し、機能した
- **効かなかったもの**: `rules/doc-mutations.md` の cycle 参照 format 条項（Insight 5）。**Recall の対象が cycle doc に限られており、rules/ は含まれない。** 読む機会が構造的に無かった
- **有効な対策**: Recall の対象に **rules/ を含める**か、少なくとも「本 cycle で編集する doc に関係する条項」を機械的に提示する。今回 `rules/plan-discipline.md` を編集しながら、同じ `rules/` にある doc-mutations.md の条項を見ていない

### 2026-09-16 18:23 - RETROSPECTIVE

- Phase completed
