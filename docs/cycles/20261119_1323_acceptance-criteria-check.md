---
feature: acceptance-criteria-check
cycle: 20261119_1323
phase: DONE
complexity: standard
test_count: 14
risk_level: medium
retro_status: captured
codex_session_id: "01a1f1fa-1294-7b70-a04d-48a86f524533"
plan_file: /Users/morodomi/.claude/plans/sparkling-dreaming-bengio.md
created: 2026-11-19 13:23
updated: 2026-11-19 14:30
---

# 受け入れ条件ごとに「確かめ方」を決めてから承認する（フロー見直し 手順 2 の最小版、#277）と v2.25.0

## Scope Definition

### In Scope

- [ ] 1. `scripts/gates/plan-lint.sh`（新規）: `bash plan-lint.sh <plan>`。受け入れ条件の検査。PASS は exit 0、BLOCK は exit 1 で理由を stdout に出す。未定の条件は問いを 1 件 1 行で並べる
- [ ] 2. `scripts/gates/pre-approve-gate.sh`: 既存の検査の後ろで plan-lint を呼ぶ（`$(CDPATH= cd "$(dirname "$0")" && pwd)/plan-lint.sh`、plan-hash の呼び方と同じ）
- [ ] 3. `skills/spec/SKILL.md` の Step 7: Test List の後、Step 7.2 の前に plan-lint を流すことを 1 行書く（`bash "<spec の Base directory>/../../scripts/gates/plan-lint.sh" <plan path>`）。97 行から 99 行以下
- [ ] 4. `skills/spec/reference.md`・`reference.ja.md`: Plan File Template に `## 受け入れ条件` の節を足し、書式と確かめ方の種類、未定のときの流れ（AskUserQuestion で聞いて書き直す）を書く
- [ ] 5. `agents/sync-plan.md` の転記表と `skills/spec/templates/cycle.md`: `## 受け入れ条件` を転記する
- [ ] 6. テスト: `tests/test-plan-lint.sh`（新規）。`tests/test-pre-approve-gate.sh` は PASS を期待する fixture（`mk_plan`）に受け入れ条件の節を足す。`tests/test-skill-script-paths.sh` の SITES に spec の plan-lint の呼び出しを足す
- [ ] 7. この cycle 自身の plan に `## 受け入れ条件` を書く（済）。GREEN の後に、この plan に plan-lint を流して PASS することを確かめる
- [ ] 8. CHANGELOG `[Unreleased]`、docs/STATUS.md
- [ ] 9. cycle を merge した後、release-skill で v2.25.0 をリリースする（#223・#295・本 cycle）

### Out of Scope

- #216 の他の検査（Verification の bash ブロック、Record の書式の前倒し、attempt 上限）
- #217（plan review の指摘の振り分け）、#235、#267
- COMMIT 前の md に条件ごとの結果を並べること、Reviewer の判定を条件に結び付けること
- 「人が確認」の件数の上限や割合の検査（リリース後に導入先の plan で測ってから決める）
- コマンドの確かめ方を plan mode で実行すること
- 導入先の承認済みの cycle への遡及

### Files to Change (target: 10 or less → 13)

- scripts/gates/plan-lint.sh (new)
- scripts/gates/pre-approve-gate.sh (edit)
- skills/spec/SKILL.md, skills/spec/reference.md, skills/spec/reference.ja.md (edit)
- skills/spec/templates/cycle.md (edit)
- agents/sync-plan.md (edit)
- tests/test-plan-lint.sh (new)
- tests/test-pre-approve-gate.sh, tests/test-skill-script-paths.sh (edit)
- CHANGELOG.md, docs/STATUS.md (edit)
- リリース時: .claude-plugin/marketplace.json, .claude-plugin/plugin.json, .claude/dev-crew.json（release-skill の Step 4）

### 実測した数（2026-11-19）

```
$ grep -rn '受け入れ条件' skills/spec/ agents/sync-plan.md
（0 件）
$ grep -n '受け入れ条件' skills/orchestrate/adversarial-review.md
10: Cycle doc のパス（Scope、受け入れ条件、Test List を読むこと）
42: ...受け入れ条件に関わるなら「人間に戻す」...
$ wc -l skills/spec/SKILL.md scripts/gates/pre-approve-gate.sh tests/test-pre-approve-gate.sh
97 / 79 / 437
$ grep -rln 'pre-approve-gate' tests/
tests/test-pre-approve-gate.sh
```

逆向き契約:
- test-pre-approve-gate の PASS を期待する TC は、plan-lint を呼ぶと受け入れ条件が無いので BLOCK に変わる。`mk_plan` で作る fixture は `mk_plan` に節を足せば直る。ただし TC-15 の 15a・15d は本文を手書きしており、15d は PASS を期待する。しかも 15d の hash（`good15`）は `mk_plan` の本文から計算するので、`mk_plan` を変えると手書きの本文と hash も合わなくなる（Codex の指摘、test-pre-approve-gate.sh:352〜383 で確認）。本文を 1 つの helper（`plan_body`）にまとめ、`mk_plan` と TC-12（12a・12b）・TC-15（15a・15d）が使う。TC-12 は BLOCK を期待する TC だが、本文に受け入れ条件が無いままだと、Record の節の打ち切りが壊れても plan-lint が代わりに BLOCK して rc=1 で通ってしまう（再レビューの指摘）。本文を揃えて、hash と plan_presented の検査だけで止まる形を保つ
- test-skill-script-paths TC-01 は skills の中の相対パスの `bash scripts/` を禁じる。新しい呼び出しも Base directory からの相対にする

### 止める基準

- 既存テストの手直しが RED の完了時点で 3 ファイルを超えたら止めて人間に戻す（数える対象は既存テストのファイル）
- spec の SKILL.md が 99 行を超える場合は、reference.md へ移す案を人間に戻す

## Environment

### Scope
- Layer: Backend（gate の bash スクリプト 1 本の新設と 1 本の変更、skill 文書、テスト）
- Plugin: なし（dev-crew 本体。`bash run-tests.sh`）
- Risk: 45 (WARN)。承認前の gate に BLOCK 条件を足す。導入先の plan 書式が変わる

### Runtime
- Language: bash 3.2 / zsh

### Dependencies (key packages)
- なし（bash / awk / shasum）

### Risk Interview (BLOCK only)
(none: WARN のため対象外。WARN 確認は Implementation Notes の「WARN 確認（自己回答）」を参照)

## Context & Dependencies

### Reference Documents
- CONSTITUTION.md 原則 6（決定論的プロセス保証）。機械的に確かめられる契約は LLM のレビューに払わせない（#216 の背景と同じ）
- docs/NEXT.md の手順 2。手順 2 と 3 の順番を決める前の計測（事業側で判断時間と質問を記録）は済んでいない。ユーザーは手順 2 を先に進めると決めた（2026-11-19）
- skills/orchestrate/adversarial-review.md:10, :42 - 「Cycle doc の受け入れ条件」を読む前提の既存記述

### Dependent Features
- pre-approve-gate: scripts/gates/pre-approve-gate.sh
- plan-hash: scripts/gates/plan-hash.sh（Record 境界の規則の元）
- spec Step 7 / Step 8: skills/spec/SKILL.md, skills/spec/reference.md

### Related Issues/PRs
- Issue #277: フロー見直し 手順 2（親。#216・#217 は閉じない）

## Recall

### docs/cycles/20261104_1025_pre-approve-gate.md
- **何が起きたか**: 新しい gate を相対パス `bash scripts/gates/...` で呼ぶ plan を書き、導入先には scripts/gates が無いと Codex に BLOCK された（Insight 1）。「既存の gate と同じ検査」と書いたのに行の選び方が違った（Insight 2）。別スクリプトの呼び出しに替えたら CDPATH で 2 行になった（Insight 3）
- **当時の前提**: 本体の作業ツリーで動けば導入先でも動く / 文面で「同じ」と書けば同じになる
- **今回も同じ前提か**: No。spec からの呼び出しは Base directory の相対（TC-12 と test-skill-script-paths）。pre-approve-gate からの呼び出しは plan-hash と同じ `CDPATH= cd`。pre-approve-gate と plan-lint の判定の一致を TC-11 で確かめる

### docs/cycles/20260723_1328_spec-forced-recall.md・20260717_1126_approval-reorder.md・20260716_1328_doc-drift-fix.md・20260314_2159_kickoff-to-sync-plan-migration.md
- spec の手順と承認前の流れを変えた過去の cycle。共変更の候補として挙がった。今回の対象（受け入れ条件の節と検査）に直接つながる失敗は無い

## 受け入れ条件

- AC-1: 受け入れ条件の節が無い、または条件が 0 件の plan は、承認前に BLOCK される
  - 確かめ方: テスト TC-01, TC-02
- AC-2: 確かめ方が無い・種類が不正・テストの TC-ID が Test List に無い・空の人が確認は BLOCK され、書式どおりの plan は PASS する
  - 確かめ方: テスト TC-03, TC-04, TC-05, TC-06, TC-07
- AC-3: 確かめ方が「未定」の条件があると BLOCK し、その問いを 1 件 1 行で出す
  - 確かめ方: テスト TC-08
- AC-4: コードブロックの中と Plan Review Record より後ろの記述は数えない
  - 確かめ方: テスト TC-09, TC-10
- AC-5: pre-approve-gate を通しても同じ判定になり、spec Step 7 から Base directory の相対で呼ばれる
  - 確かめ方: テスト TC-11, TC-12
- AC-6: この cycle 自身の plan に plan-lint を流すと PASS する
  - 確かめ方: コマンド `bash scripts/gates/plan-lint.sh /Users/morodomi/.claude/plans/sparkling-dreaming-bengio.md`
- AC-7: v2.25.0 が #223・#295・本 cycle を含めてリリースされる
  - 確かめ方: 人が確認（release-skill の Step 8 で、タグ v2.25.0 と CHANGELOG の [2.25.0] を見る）

## Test List

### TODO

`tests/test-plan-lint.sh`（新規）。fixture は mktemp の plan ファイル。各 TC は plan-lint の rc と出力の両方を見る:

(TC-01〜TC-13、TC-07b は RED で作成し WIP へ移した)

既存テストの手直し（RED で確定）: test-pre-approve-gate は本文を helper `plan_body`（受け入れ条件の節と Test List 付き）にまとめ、`mk_plan` と TC-12（12a・12b）・TC-15（15a・15d）がそれを使う。test-skill-script-paths の SITES に spec の plan-lint の行を足す。

### 変異で確かめること（REFACTOR 後）

- 節が無いときの検査を消す → TC-01 が落ちる
- TC-ID の照合を本文全体に広げる → TC-05 が落ちる
- fence の扱いを外す → TC-09 が落ちる
- Record より後ろも読む → TC-10 が落ちる
- Record の境界を fence の外だけで探す（plan-hash.sh とずらす） → TC-10 が落ちる
- 未定を PASS にする → TC-08 が落ちる
- pre-approve-gate から plan-lint の呼び出しを消す → TC-11 が落ちる
- spec SKILL.md から呼び出しを消す → TC-12 と test-skill-script-paths が落ちる

### WIP

(none)

### DISCOVERED
- REVIEW の記録のみ 3 件（条件の文が空の AC、`AC-1 ` の重複判定、CRLF・見出し末尾の空白）→ issue #304
- REVIEW の人間に戻す 1 件（節の中の `AC-` を持たない普通の文を BLOCK するか）→ COMMIT 前の md で人間に確かめる

### DONE

- [x] TC-01: Given `## 受け入れ条件` の節が無い plan, When plan-lint を流す, Then rc=1 で節が無いと出す
- [x] TC-02: Given 節はあるが `- AC-` の行が 0 件, When 流す, Then rc=1
- [x] TC-03: Given AC-1 に確かめ方の行が無い、または 2 行ある, When 流す, Then rc=1 で AC-1 を名指しする
- [x] TC-04: Given 確かめ方が `目視` など 4 種類のどれでもない, When 流す, Then rc=1
- [x] TC-05: Given `テスト TC-01, TC-99` で TC-99 が Test List に無い（Test List の外の本文には `TC-99` がある）, When 流す, Then rc=1 で TC-99 を名指しする
- [x] TC-06: Given `人が確認（）` と `人が確認（ ）`、バッククォートの無い `コマンド ls`、バッククォートの中が空か空白だけの `コマンド`、ID の無い `テスト`, When 流す, Then それぞれ rc=1
- [x] TC-07: Given テスト・コマンド・人が確認の 3 種類を 1 つずつ持つ正しい plan, When 流す, Then rc=0
- [x] TC-07b: Given AC-ID の重複（AC-1 が 2 回）, When 流す, Then rc=1
- [x] TC-08: Given AC-2 が `未定（問い: 古い表がある環境でも動く必要があるか）`、AC-3 も未定, When 流す, Then rc=1 で 2 つの問いを 1 件 1 行で出す
- [x] TC-09: Given 受け入れ条件の節と AC がコードブロック（``` と ~~~ の両方）の中にしか無い, When 流す, Then rc=1
- [x] TC-10: Given 節が `## Plan Review Record` より後ろにしか無い。または Test List の TC-ID が Record より後ろにしか無い。または、コードブロックの中に行全体が `## Plan Review Record` の行があり、正しい受け入れ条件の節がその後ろ（コードブロックの外）にしか無い, When 流す, Then それぞれ rc=1（Record の境界は plan-hash.sh と同じく、コードブロックの中でも効く）
- [x] TC-11: Given TC-01 と TC-07 の plan に正しい Record（hash 一致・plan_presented あり）を付けたもの, When pre-approve-gate を流す, Then 前者は rc=1 で plan-lint の理由を出し、後者は rc=0
- [x] TC-12: Given spec の SKILL.md, When Step 7 の区間（`### Step 7` から `### Step 8` の手前）を読む, Then `plan-lint.sh` の呼び出しが Step 7.2（Forced Recall）の行より前にある（呼び出しの順序だけを見る。パスの形と実在は test-skill-script-paths の SITES、SKILL.md の行数は test-recall-candidates の TC-D1 が既に見ている）
- [x] TC-13: Given spec reference.md と reference.ja.md の Plan File Template, When テンプレートの受け入れ条件の例を取り出して Test List と Record を足した plan にする, Then plan-lint は rc=0。sync-plan.md の転記表と cycle テンプレートに `受け入れ条件` がある
- [x] TC-R1: tests/test-plan-lint.sh::TC-R1 TC-ID を AC 側と Test List 側で同じに読む（REVIEW で追加）
- [x] TC-R2: tests/test-plan-lint.sh::TC-R2 TC の範囲表記を BLOCK する（REVIEW で追加）
- [x] TC-R3: tests/test-plan-lint.sh::TC-R3 U+3000・U+00A0 だけの記述を C と UTF-8 の両ロケールで BLOCK する（REVIEW で追加）
- [x] TC-R4: tests/test-plan-lint.sh::TC-R4 節の中の書式外の AC- 行を BLOCK する（REVIEW で追加）
- [x] TC-R5: tests/test-plan-lint.sh::TC-R5 Test List の見出しの注記・TC 行の注記・[X] を読む（REVIEW で追加）
- [x] TC-R6: tests/test-plan-lint.sh::TC-R6 長い fence を短い fence で閉じない（REVIEW で追加）
- [x] TC-R7: tests/test-plan-lint.sh::TC-R7 行頭のインラインコードが fence を開かない（REVIEW で追加）
- [x] TC-R8: tests/test-plan-lint.sh::TC-R8 タブを入れた AC の行で確かめ方の欠落を隠せない（REVIEW で追加）

## Implementation Notes

### Goal

フロー見直しは「中は緩め、前と後を固める」方針で、後（敵対的レビュー + 振り分け）は v2.20 系で入れた。前（受け入れ条件・範囲・境界・計測）を固める手順 2（#277）は未着手。受け入れ条件ごとに「確かめ方」を承認前に決め、決まらない条件は人に問いとして返す最小版を入れ、#223・#295 と合わせて v2.25.0 としてリリースする（ユーザー決定 2026-11-19、案 A）。

### Background

いまの plan には受け入れ条件の節そのものが無い（2026-11-19 実測）。

- `skills/spec/reference.md` の Plan File Template と `skills/spec/templates/cycle.md` に `受け入れ条件` の節は無い。`agents/sync-plan.md` の転記表にも無い
- 一方で REVIEW の依頼文（`skills/orchestrate/adversarial-review.md:10`）と振り分け（同 :42）は「Cycle doc の受け入れ条件」を読む前提で書かれている。読む先が無い

外部の 2 つの実測が同じ所を指している（どちらも dev-crew の流れで回したものではない。数も少ない）。

- 別の組織で AI に QA ループを 4 件回した試行では、外した原因が「受け入れ条件に確かめ方の決まらない条件があり、AI が止まって聞かずに仮定を置いて進めた」だった。課題として「実装前に受け入れ条件を見て、確かめ方の決まらない条件を人に返す」が挙がった
- 公開記事の agent チーム（Lead / Builder / Reviewer）でも、Lead が「タスクごとに受け入れ条件と確かめ方を決める」。Reviewer は確かめられなかったものを BLOCKED にする

TDD Context: Workflow TDD / Feature: acceptance-criteria-check / Issue: #277（親。#216・#217 は閉じない）

### Design Approach

WARN 確認（自己回答）:
- 影響: 新しい版を入れた導入先では、承認前に `## 受け入れ条件` の節が求められる。承認済みで実装中の cycle は影響を受けない（pre-approve-gate は承認前にしか走らない）
- 変わる動き: spec の Step 7 の終わり（Codex の plan review の前）に `plan-lint.sh` を流す。pre-approve-gate も最後に同じ検査を流す。確かめ方が「未定」の条件があれば BLOCK し、その問いを人に返す
- 変えないもの: pre-approve-gate の hash と plan_presented の検査、pre-red-gate、Plan Review Record の書式

Ambiguity Resolution:
- 書式: plan の `## 受け入れ条件` 節に、条件 1 つにつき 2 行で書く。
  ```
  - AC-1: <満たすべき条件>
    - 確かめ方: テスト TC-01, TC-02
  ```
  確かめ方の種類は 3 つと「未定」だけにする。
  - `テスト <TC-ID の並び>`: その ID が同じ plan の Test List に `TC-ID:` として実在すること
  - `` コマンド `<コマンド>` ``: バッククォートで囲んだコマンドがあること（plan mode では実行しない）
  - `人が確認（<何を見るか>）`: 括弧の中が空白だけでないこと
  - `未定（問い: <人に聞くこと>）`: 書いてよいが gate は BLOCK し、問いを並べて出す。spec は AskUserQuestion で人に聞き、答えで書き直してから流し直す
- 「人が確認」は逃げ道になりうる（#277 の未確認点「lint が欄埋めの文章を生むか」）。今回は件数を数えず、リリース後に導入先の plan で「人が確認」の割合を測る（Out of Scope）
- 置き場所: 新しい `scripts/gates/plan-lint.sh <plan>`。将来 #216 の検査を足せる名前にするが、今回入れるのは受け入れ条件の検査だけ。#216 は閉じない
- 流す時点は 2 か所: (1) spec Step 7 の終わり、Codex の plan review の前。ここで直せば hash の問題が起きない (2) pre-approve-gate の最後に plan-lint を呼ぶ。(1) を飛ばしても承認前に止まる（#295 と同じく、文面だけに頼らない）。(2) で初めて BLOCK すると、直すと hash が変わる。回復の手順は今の pre-approve-gate の hash 不一致と同じ（spec reference Step 8 の 7）
- 節を探す範囲: 先にファイルを、行全体が `## Plan Review Record` の最初の行の手前で切る。この境界は plan-hash.sh・pre-approve-gate と同じ規則で、コードブロックの中の行でも境界になる（hash の対象と lint の対象をずらさないため）。そのうえで、コードブロック（``` と ~~~、開いた文字と同じ文字で閉じる）の外だけを読み、行全体が `## 受け入れ条件` の見出しから次の `## ` までを節とする
- Test List の TC-ID: plan の `## Test List` 節の中で、コードブロックの外の `- [ ] TC-<ID>:` か `- [x] TC-<ID>:` の行から取る
- 引き継ぎ: sync-plan が `## 受け入れ条件` を Cycle doc に転記する（転記表に 1 行、cycle テンプレートに節）。REVIEW の依頼文が読む先ができる。COMMIT 前の md で条件ごとの結果を並べるのは次の段（Out of Scope）

設計:
- plan-lint.sh は `set -euo pipefail`、`LC_ALL=C` にしない（日本語の見出しを literal で比べる。全角括弧は括弧式に入れず文字列の前方・後方除去で扱う。#295 の REVIEW の教訓）
- awk 1 本で、まず行全体が `## Plan Review Record` の最初の行で読むのをやめ（fence の中でも。plan-hash.sh と同じ規則）、その手前の fence の外だけから受け入れ条件の節と Test List の節を取り出す
- 判定の順: 節が無い → BLOCK / AC が 0 件 → BLOCK / AC-ID の重複 → BLOCK / AC に確かめ方の行が無い・2 行以上 → BLOCK / 種類が 4 つのどれでもない → BLOCK / テストの TC-ID が Test List に無い → BLOCK / 未定がある → BLOCK（問いを並べる）/ すべて満たす → PASS
- 確かめ方の行は、AC の行の直後から次の `- AC-` か節の終わりまでで、行頭が空白 2 つ以上 + `- 確かめ方: ` のもの
- pre-approve-gate は plan-lint の stdout をそのまま出し、rc を引き継ぐ

承認前の確認（どこを触るか）:
- 作る量の見積もり: plan-lint.sh 100 行前後、新しい TC 14 本、既存テストの手直し 2 ファイル、文書 5 か所
- 導入先への影響: 次の版から、承認前に受け入れ条件と確かめ方が求められる。確かめ方の決まらない条件は、承認の前に人へ問いとして返る

## Verification

**Real-path invocation を最低 1 件含めること** (rules/integration-verification.md)。

```bash
bash run-tests.sh tests/test-plan-lint.sh
bash scripts/gates/plan-lint.sh /Users/morodomi/.claude/plans/sparkling-dreaming-bengio.md
bash scripts/gates/pre-approve-gate.sh /Users/morodomi/.claude/plans/sparkling-dreaming-bengio.md
bash run-tests.sh
wc -l skills/spec/SKILL.md
```

リリース（cycle を merge した後）: release-skill で v2.25.0。CHANGELOG の `[Unreleased]` には #223（codify-landing）・#295（pre-red-gate の記録）・本 cycle がある。リリース PR のマージはユーザーの確認を取る（release-skill の Step 6）。

Evidence: (orchestrate が自動記入)

## Progress Log

Format for each phase entry (**strict, required by pre-commit-gate.sh**):

```
### YYYY-MM-DD HH:MM - PHASE_NAME
- [completed action]
- Phase completed
```

### 2026-11-19 13:23 - KICKOFF
- Cycle doc created
- Scope definition ready

### 2026-11-19 13:23 - Plan Review (pre-approval)
- codex_session_id: 01a1f1fa-1294-7b70-a04d-48a86f524533
- review_attempts:
  - {started: 13:04, completed: 13:07, verdict: BLOCK}
  - {started: 13:08, completed: 13:09, verdict: WARN}
- findings 要約: attempt 1（BLOCK）: BLOCK 1 = test-pre-approve-gate の TC-15d は手書き本文で PASS を期待し、hash も mk_plan の本文から取るので mk_plan だけ直しても落ちる → 本文を helper plan_body にまとめる。重要 1 = Record 境界と fence 除外の順が曖昧 → plan-hash.sh と同じく Record 境界を先に（fence の中でも）効かせ、TC-10 と変異に追加。軽微 1 = TC-06 に空のコマンドと ID の無いテストを追加。削除 1 = TC-12 を呼び出し順序だけに絞る（パスは test-skill-script-paths、行数は test-recall-candidates TC-D1 が既に見ている）。attempt 2（WARN）: 重要 1 = TC-12a・12b も受け入れ条件が無いと plan-lint が代わりに BLOCK して検出力が落ちる → 12a・12b も plan_body を使う。レビュー後の変更: attempt 2 の重要 1 件の反映（Scope の逆向き契約の段落と Test List の「既存テストの手直し」の 2 か所に TC-12 を足しただけ）。再レビューは 1 回までのため、承認提示文で差分を示し、承認後の版の hash を記録した
- unresolved_blocks: なし
- plan_presented: 2026-11-19 13:10
- reviewed_plan_hash: 42447586b7504fe9106c96bbbed54c35d077b2d1b80d0e8d1fde6ca09ff79b09
- override: (空)
- verdict: WARN
- Phase completed

### 2026-11-19 13:23 - SYNC-PLAN
- Cycle doc generated from plan (Test List 14 items, Plan Review Record transferred)
- Phase completed

### 2026-11-19 13:24 - Post-Transfer Verification
- Design Review Gate: WARN（Files to Change 13 件で目標 10 件を超えるが、plan が理由を明記: リリース時の 3 ファイルを含む。YAGNI 違反なし。Risk 45 と変更内容は整合）
- 転記照合: PASS。codex_session_id / plan_file / review_attempts / verdict / plan_presented / unresolved_blocks / override は plan の Plan Review Record と一致。reviewed_plan_hash は `scripts/gates/plan-hash.sh` の出力 42447586b7504fe9106c96bbbed54c35d077b2d1b80d0e8d1fde6ca09ff79b09 と一致。`## 受け入れ条件` 節（AC-1〜AC-7）は plan と原文で一致（diff 差分なし）。Test List 14 件と test_count: 14 も一致
- `bash scripts/gates/pre-red-gate.sh` を実走: PASS
- 分岐判定: 転記欠落なし / scope 実質変更なし / 観察のみ 1 件
- 観察: plan の「実測した数」は pre-approve-gate.sh を 79 行とするが、検証時点の実測は 73 行（SKILL.md 97 行、test-pre-approve-gate.sh 437 行は一致）。判断には影響しない
- Phase completed

### 2026-11-19 13:24 - PRE-RED GATE
- pre-red-gate: PASS

### 2026-11-19 13:29 - RED
- 作成: tests/test-plan-lint.sh（TC-01〜TC-13、TC-07b）。既存の手直し 2 ファイル: tests/test-pre-approve-gate.sh（helper `plan_body` を足し、`mk_plan`・TC-12a/12b・TC-15a/15d が使う）、tests/test-skill-script-paths.sh（SITES に spec の SKILL.md・reference.md・reference.ja.md の plan-lint 呼び出し 3 行）
- RED の実測: test-plan-lint.sh rc=1 (PASS 1 / FAIL 37。PASS の 1 件は TC-11 の「正しい plan は既存の gate で rc=0」で、plan-lint 不在でも通る。BLOCK 側の TC-11 は FAIL)。test-pre-approve-gate.sh rc=0 (PASS 25 / FAIL 0。plan-lint をまだ呼ばないため既存の gate で全 PASS)。test-skill-script-paths.sh rc=1 (PASS 3 / FAIL 2。TC-02・TC-03 が plan-lint の呼び出し不在で落ちる)
- 固定した BLOCK 文言（plan-lint.sh の stdout。BLOCK 行は `BLOCK:` で始まる。GREEN はこれに合わせる）:
  - 節が無い: `BLOCK: no '## 受け入れ条件' section`
  - AC が 0 件: `BLOCK: '## 受け入れ条件' has no '- AC-N:' line`
  - AC-ID 重複: `BLOCK: duplicate AC-ID: AC-1`
  - 確かめ方の数: `BLOCK: AC-1: needs exactly one 確かめ方 line (found 0)` / `(found 2)`
  - 種類が不正: `BLOCK: AC-1: unknown 確かめ方 kind: 目視`
  - TC-ID が Test List に無い: `BLOCK: AC-1: TC-99 is not in the Test List`
  - テストに ID が無い: `BLOCK: AC-1: テスト needs at least one TC-ID`
  - コマンドが不正: `BLOCK: AC-1: コマンド needs a non-empty command in backticks`
  - 人が確認が空: `BLOCK: AC-1: 人が確認 needs a non-empty description`
  - 未定: `BLOCK: AC-2: 未定の問い: <問い>`（1 件 1 行、行全体が一致）
  - PASS: 行頭 `PASS:`、rc=0
- TC-13 の取り出し方: `## Plan File Template` 区間を fence を考慮して取り（fence 内の `## ` で打ち切らない）、その中の最初の ```markdown ブロックから `## 受け入れ条件` 節を取る。例に `テスト TC-NN` が 1 つ以上必要で、その ID を Test List に写して plan にする。GREEN はテンプレートの例にテストの種類を含めること
- TC-12 は `**Step 7.2:` で始まる行より前に `plan-lint.sh` を含む行があることを見る（plan-lint の行に `**Step 7.2:` を書かないこと）
- Phase completed

### 2026-11-19 13:32 - GREEN
- 変更ファイル: scripts/gates/plan-lint.sh（新規）、scripts/gates/pre-approve-gate.sh（最後に plan-lint を呼ぶ）、skills/spec/SKILL.md、skills/spec/reference.md、skills/spec/reference.ja.md、skills/spec/templates/cycle.md、agents/sync-plan.md、CHANGELOG.md、docs/STATUS.md
- テスト: test-plan-lint.sh rc=0 (PASS 38 / FAIL 0)、test-pre-approve-gate.sh rc=0 (PASS 25 / FAIL 0)、test-skill-script-paths.sh rc=0 (PASS 5 / FAIL 0)、test-recall-candidates.sh rc=0 (PASS 16 / FAIL 0)。sync-plan.md・templates/cycle.md・spec/reference・STATUS.md・CHANGELOG・spec/SKILL を参照する tests/ 39 本も全て rc=0
- plan-lint を本 plan に流した結果: rc=0（PASS: 7 acceptance criteria）。pre-approve-gate も rc=0
- skills/spec/SKILL.md: 99 行
- Phase completed

### 2026-11-19 13:37 - REFACTOR
- チェックリスト 7 項目を plan-lint.sh・pre-approve-gate.sh・test-plan-lint.sh に当てた。重複は空白を削る式の 2 か所だけで、helper にするほどではないため変更なし。定数化・未使用・命名も変更なし
- full suite（GREEN 後に PdM が実測）: `bash run-tests.sh` PASS 124 / FAIL 0。REFACTOR でコードは変えていない。/bin/bash 3.2 で test-plan-lint.sh PASS 38 / FAIL 0。shellcheck は環境に無い
- 見つけた不具合（REVIEW の修正役へ渡す。REFACTOR はテストを足せないため直さない）: `LC_ALL=C` で plan-lint を流すと、全角空白（U+3000）だけの `人が確認（　）` と `` コマンド `　` `` が PASS する。en_US.UTF-8・ja_JP.UTF-8 では BLOCK。`[[:space:]]` が C ロケールで U+3000 を含まないため（pre-red-gate-record の REVIEW と同じ型）
- Phase completed

### 2026-11-19 13:38 - VERIFY
- `## Verification` を実走（出力: /tmp/dev-crew-verify-20261119_1323/verify.txt）: test-plan-lint.sh PASS 38 / FAIL 0。本 plan に plan-lint rc=0（PASS: 7 acceptance criteria）。pre-approve-gate rc=0（PASS 行 2 つ）。SKILL.md 99 行。full suite は GREEN 後に 124 / 0
- real-path: plan-lint と pre-approve-gate を本 cycle の plan（実データ）に流した（AC-6）

### 2026-11-19 13:54 - REVIEW
- Codex review: 失敗（利用上限、15:04 まで）。adversarial-reviewer で代行: 直す 7 / 人間に戻す 1 / 記録のみ 3
- レビュー結果: /tmp/dev-crew-review-20261119_1323/review.md（代行の返答を PdM が書き出した）。worktree-fingerprint は前後で一致（a9d3089148b6c08377dbe56a6a2acb2bf3cbe6055c77153cf5e4b5eac51a488e）。P1・P2 の場所はすべて finding-in-diff.sh で rc=0（diff の中）
- 直す 7: (1) TC-ID の読み方が AC 側と Test List 側で違い、実在しない TC-ID で PASS した（P1）→ 両側を同じトークンにそろえ、範囲表記は BLOCK (2) C ロケールで U+3000・U+00A0 だけの記述が通る → バイト列を先に除く (4) `## Test List（…）`・`TC-01 (RED):`・`TC-01（注記）:` を誤って BLOCK → 読むようにして reference を日英で揃えた (5) 長い fence を短い fence で閉じた (6) 行頭のインラインコードで fence が開いた (7) タブで確かめ方の欠落を隠せた (10) `[X]` を数えなかった（4 の直しで解消）
- 人間に戻す 1: (3) 節の中の書式外の行が黙って無視される。`AC-` で始まる書式外の行（全角コロン・`*`・字下げ）は BLOCK にした。`AC-` を持たない普通の文（例: `- 本番 DB の既存データを消さない`）を BLOCK するかは既存の動きの範囲を変えるため人間に戻す
- 記録のみ 3: (8) 条件の文が空の AC が通る (9) `AC-1` と `AC-1 ` が重複にならない (11) CRLF・見出し末尾の空白で節が無いことになる（安全な側に倒れる）
- plan-lint.sh 202 → 242 行。tests/test-plan-lint.sh PASS 55 / FAIL 0（直す前は新設 TC が 14 FAIL）。full suite `bash run-tests.sh` PASS 124 / FAIL 0。本 plan に pre-approve-gate rc=0。修正役の未追跡ファイルの増加なし
- Phase completed

### 2026-11-19 14:01 - MUTATION
- 「変異で確かめること」の 8 種を、作業ツリーの写し（scratchpad の mut277）に 1 種ずつ当てて流した。8 種とも検出
  - M1 節が無いときの検査を消す → TC-01（ほか TC-09a〜c）が落ちた
  - M2 Test List との照合を飛ばす → TC-05・TC-10b・TC-R1a が落ちた
  - M3 fence の扱いを外す → TC-09a・09b（ほか TC-05）が落ちた
  - M4 Record より後ろも読む → TC-10a〜c が落ちた
  - M5 Record の境界を fence の外だけで探す → TC-10c が落ちた
  - M6 未定を PASS にする → TC-08 が落ちた
  - M7 pre-approve-gate から plan-lint の呼び出しを消す → TC-11 が落ちた
  - M8 spec SKILL.md から呼び出しを消す → TC-12 と test-skill-script-paths の TC-02・03 が落ちた

### 2026-11-19 14:29 - HUMAN DECISION
- REVIEW の人間に戻す 1 件（節の中の `AC-` を持たない普通の文）: 人間の回答は「読み飛ばしのまま」。plan-lint は変えず、reference.md・reference.ja.md の書式説明に「節には AC の行と確かめ方の行だけを書く。`AC-` を持たない文は読まれない」を 1 文足した
- commit: 人間の回答は「commit する」
- 足した後の full suite: `bash run-tests.sh` PASS 124 / FAIL 0

### 2026-11-19 14:30 - COMMIT
- plan-lint.sh の新設、pre-approve-gate からの呼び出し、spec・sync-plan・cycle テンプレートの受け入れ条件の節を commit。STATUS.md の Completed に移した
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

## Retrospective

### Insight 1

- **Failure**: plan-lint の Test List の読み方（見出しの完全一致、TC-ID をコロンの手前まで取る）を、spec の Plan File Template の書式だけから決めた。REVIEW で、実在の plan の写しに流すと約半数が「TC が Test List に無い」で誤って BLOCK すると分かった（`## Test List（…）`、`TC-01 (RED):`、`TC-01（注記）:`）
- **Final fix**: 見出しの後ろの注記と ID の後ろの注記を許し、reference に Test List の書式を日英で書いた（TC-R5）
- **Insight**: 自由に書かれてきた既存の文書（plan、Cycle doc）を読む gate を新しく作るときは、RED の前に、試作の読み方か grep を実物の集まり（docs/cycles、plan のフォルダ）に当てて、BLOCK になる割合と書き方の揺れを数える。見つかった揺れは Test List に入れる

### Insight 2

- **Failure**: 同じ TC-ID を、AC 側は `TC-[0-9A-Za-z_]+`、Test List 側は `TC-[^:]+:` と別の正規表現で取り出した。`TC-01-b` が `TC-01` と照合されて PASS し、実在する `TC-REF-15` は BLOCK した（REVIEW の P1）
- **Final fix**: 両側を同じトークン `TC-[0-9A-Za-z_]+([-.][0-9A-Za-z_]+)*` にそろえ、範囲表記は BLOCK にした（TC-R1、TC-R2）
- **Insight**: 1 本の gate の中で同じ識別子を 2 か所で読むときは、トークンの正規表現を 1 つ決めて両方で使う。テストには、実物にある `-` や `.` を含む ID と、短い ID の前方一致になる ID を入れる

### Insight 3

- **Failure**: C ロケールで全角空白（U+3000）だけの記述が通る欠陥を、前の cycle の REVIEW で pre-commit-gate について直したばかりなのに、plan-lint で再び作った。plan の設計には「LC_ALL=C にしない」「全角括弧を括弧式に入れない」は書いたが、空白の削除は書かず、Test List にもロケールの組み合わせが無かった。REFACTOR で気付き、REVIEW で直した（TC-R3）
- **Final fix**: U+3000 と U+00A0 のバイト列を先に除いてから `[[:space:]]` を除き、テストを C と UTF-8 の両ロケールで流した
- **Insight**: 前の cycle の REVIEW で直した型（ロケール、fence、空白）を持つ処理を新しい gate に書くときは、その直しを設計の文だけでなく Test List の項目（ロケールの組み合わせ）として写す。設計の文に書いた項目だけが守られ、書かなかった項目は再発した

### 想起漏れ

- **設問**: 今回の手戻りは、過去のどの cycle doc を最初に読んでいれば防げたか
- **回答**: docs/cycles/20261118_2304_pre-red-gate-record.md
