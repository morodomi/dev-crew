---
feature: review-fixer-location-check
cycle: 20261028_1047
phase: DONE
complexity: standard
test_count: 23
risk_level: low
retro_status: captured
codex_mode: no
codex_session_id: "01a18025-9343-7061-af1a-6bf0b8267181"
plan_file: /Users/morodomi/.claude/plans/271-velvet-rossum.md
created: 2026-10-28 10:47
updated: 2026-10-28 12:54
---

# #271: 修正役を起動する前に、PdM が指摘の場所と diff を照らす

## Scope Definition

### In Scope
- [ ] A. 新しいスクリプト `scripts/gates/finding-in-diff.sh <ファイル> <行>`: 指摘の場所が今回の diff の中にあるかを終了コードで判定する
  - 終了コード 0（diff の中）: ファイルが未追跡（`git ls-files --others --exclude-standard`）、または `git diff HEAD` の変更行に行が入る。追加・変更の hunk `+c,d`（d>0）は c〜c+d-1 を中とする（d を省いたら 1）。削除だけの hunk `+c,0` は c と c+1 を中とする
  - 終了コード 1（diff の外）: 追跡ファイル（index か HEAD にある）だと確かめられ、行が変更行に入らない。ファイルが diff に無い追跡ファイルも 1。1 を返すのはこの場合だけ
  - 終了コード 2（判定できない）: 引数の数が違う、行が正の整数でない、git repo の外、HEAD が無い、パスがリポジトリの外を指す、パスが追跡も未追跡（ignore を除く）もされていない、パスに clean filter（`git check-attr filter` が unspecified / unset 以外）が掛かっている、git の失敗。stderr に理由を 1 行。2 は「元からある欠陥」と断定しない側に倒すためのもので、PdM は今までどおり修正役に任せる
  - パスはリポジトリのルートからの相対パスとして読む（`./` は外す。絶対パスはルートの下ならルートからの相対に直す）。どのディレクトリから実行しても同じ結果
  - `git diff` は `--no-color --no-ext-diff --no-textconv -U0 --inter-hunk-context=0` で呼ぶ（cycle 20261016_1645 Insight 1）。`diff.interHunkContext` が大きいと離れた 2 つの変更が 1 つの hunk にまとまり、間の未変更行まで「diff の中」になる（Codex が実測）
  - clean filter は `--no-textconv` では外れず、diff の行番号を作業ツリーの行番号からずらしたり変更を隠したりする。掛かっているパスは判定せず 2 にする
  - 作業ツリーと index を変えない（読むだけ）
- [ ] B. 3 つの steps（`skills/orchestrate/steps-codex.md` / `steps-subagent.md` / `steps-teams.md`）の REVIEW 手順 2 の先頭（「「直す」が 0 件なら修正役を起動せず」の前）に場所の照合を書く。文面は 3 ファイルで同じにする
  - 修正役を起動する前に、PdM が P1・P2 の指摘ごとに、レビュー結果にある場所（ファイル:行）で `bash scripts/gates/finding-in-diff.sh <ファイル> <行>` を実行する
  - 終了コード 1 の指摘は、元からある欠陥として修正役に「直す」として渡さない。受け入れ条件に関わるなら「人間に戻す」、関わらないなら「記録のみ」にして DISCOVERED に回す
  - 終了コード 0・2 と、場所が書かれていない指摘は、今までどおり修正役の振り分けに任せる
  - 起動の条件: 照合の後に修正役へ渡す指摘（P1・P2 のうち終了コード 1 でないもの）が 1 件以上残れば、修正役を起動する。残らなければ「直す」は 0 件で、修正役を起動しない
  - 修正役の起動 prompt（codex exec の文字列と Task の prompt の両方）に、diff の外と判定した指摘を「直さない指摘: [ファイル:行 と、指摘の 1 行目]」として書く。番号ではなく場所と原文で指す
  - 「直さない指摘」は PdM が振り分け済みなので、修正役は振り分けも報告もしない（二重に数えないため）
  - 件数の行（直す / 人間に戻す / 記録のみ）は、PdM が照合で振り分けた分と、修正役の報告の分を足したものにする。修正役を起動しないときは、P3 の指摘を PdM が「記録のみ」として数える
  - 既存の句「「直す」が 0 件なら修正役を起動せず」は残す（TC-18 の逆向き契約）。手順の番号は変えない
- [ ] C. `skills/orchestrate/adversarial-review.md`: `## 頼み方` の依頼文に場所（ファイル:行。行は作業ツリーの今の行番号）を足す。`## 振り分け` に 1 文足す（PdM が「直さない指摘」として渡したものは、直さず、振り分けも報告もしない）
- [ ] D. テスト（Test List 参照）
- [ ] E. `CHANGELOG.md` の `[Unreleased]` に Changed を 1 項

### Out of Scope
- 修正役を 2 段に分ける案 (Reason: 研究メモの「見直す条件」が起きるまで作らない)
- 場所が無い・判定できない指摘を人間に戻すこと (Reason: ユーザー決定。問いを増やさない)
- 行の範囲を広げる判定（関数単位、呼び出し元の追跡） (Reason: 今回は hunk の行だけ)
- 修正役（green-worker / Codex）とレビュー役（adversarial-reviewer）の定義の変更
- pre-commit-gate など既存の gate のロジック
- 照合の結果を Cycle doc に別の形式で記録すること (Reason: 件数の行に含めるだけ)

### Files to Change (target: 10 or less)
- scripts/gates/finding-in-diff.sh (new)
- skills/orchestrate/steps-codex.md (edit)
- skills/orchestrate/steps-subagent.md (edit)
- skills/orchestrate/steps-teams.md (edit)
- skills/orchestrate/adversarial-review.md (edit)
- tests/test-finding-in-diff.sh (new, TC-01〜17)
- tests/test-adversarial-review.sh (edit, TC-27〜32)
- CHANGELOG.md (edit)

## Environment

### Scope
- Layer: Backend (dev-crew 本体: scripts/gates、skills/orchestrate、tests、CHANGELOG)
- Plugin: bash
- Risk: 25 (PASS)。低〜中。REVIEW の流れに手順を 1 つ足す。修正役・レビュー役の定義と gate のロジックは変えない

### Runtime
- Language: bash 3.2.57（macOS）
- git 2.56.0
- version gate: `.claude/dev-crew.json` 2.21.0 = installed 2.21.0
- codex_mode: no（RED/GREEN は Claude の worker）
- リリース: cycle の中では commit まで。タグは cycle の後に release-skill で

### Dependencies (key packages)
- git: 2.56.0
- scripts/gates/worktree-fingerprint.sh（TC-14 で使用）

## Context & Dependencies

### Reference Documents
- docs/research/review-fixer-impact-2026-10.md - 2026-10-21 の計測（M1 の素通り、M3 の正答）
- docs/cycles/20261016_1645_adversarial-review-triage.md - Insight 1（git 設定を通した見え方の上に gate を作らない）、Insight 4（同じ fixture の前後で比べる）
- docs/cycles/20261020_0955_review-gaps.md - Insight 1（実測した失敗例そのものに当てる）、Insight 3（fence を境界にしない）
- CONSTITUTION 原則 6「決定論的プロセス保証」、原則 5「レビューは回数ではなく予算で止める」

### Dependent Features
- REVIEW 手順 2: skills/orchestrate/steps-codex.md, steps-subagent.md, steps-teams.md
- 振り分け規則: skills/orchestrate/adversarial-review.md
- 既存の文面契約テスト: tests/test-adversarial-review.sh（`check_steps_review_has` と `sec`）

### Related Issues/PRs
- Issue #271: 修正役を起動する前に、PdM が指摘の場所と diff を照らす

## Recall

`bash scripts/recall-candidates.sh . skills/orchestrate/steps-codex.md skills/orchestrate/steps-subagent.md skills/orchestrate/steps-teams.md skills/orchestrate/adversarial-review.md scripts/gates/finding-in-diff.sh tests/test-adversarial-review.sh` の上位:

- docs/cycles/20261016_1645_adversarial-review-triage.md（1.60）: Insight 1「gate を、相手が書き換えられる git の設定（filter・textconv・exclude・hooks）を通した見え方の上に作らない」→ `git diff` は `--no-ext-diff --no-textconv --no-color` で呼び、TC-08 で固定する。Insight 4「変化の検出は同じ fixture の前後で比べる」→ TC-14
- docs/cycles/20261020_0955_review-gaps.md（0.60）: Insight 1「検出の仕組みを選ぶ前に、実測した失敗例そのものに当てる」→ TC-13 で M1・M3 の fixture に当てる。Insight 3「Markdown の節の切り出しでコードブロックの内側を境界にしない」→ TC-27〜30 は既存の fence-aware な `sec` を使う

## Test List

スクリプトのテスト（tests/test-finding-in-diff.sh）は、一時ディレクトリに git repo を作り、実際にスクリプトを実行して終了コードを見る。fixture は 1 つのテストの中で前後を作る（cycle 20261016_1645 Insight 4）。

### TODO

文面の契約（tests/test-adversarial-review.sh。既存の `check_steps_review_has` と `sec` を使う。番号は実装の最大値 TC-26 を実測して決めた）:

（TC-01〜17、TC-27〜32 は RED を書き終えたので WIP へ移した）

RED で落ちることを確かめるもの: TC-01〜17（スクリプトが無い）、TC-27〜32。

検出力の確認（GREEN の後、リポジトリの外の複製に変異を 1 つずつ入れる）:
- 削除だけの hunk の扱いを消す → TC-05 が FAIL
- d を省いたときの既定 1 を 0 にする → TC-02 が FAIL
- `--no-ext-diff` / `--no-textconv` を消す → TC-08 が FAIL
- ルートへの cd を消す → TC-07 が FAIL
- 未追跡の判定を消す → TC-01 と TC-13（M3）が FAIL
- steps の 1 つで照合の段落を「「直す」が 0 件」の後ろへ移す → TC-27 が FAIL
- 終了コード 1 と 2 の扱いを入れ替える → TC-28 が FAIL
- `--inter-hunk-context=0` を消す → TC-15 が FAIL
- clean filter の検査を消す → TC-16 が FAIL
- 追跡の確認を消して、diff に無いパスを一律 1 にする → TC-17 が FAIL
- 修正役の起動文字列（codex exec / Task のどれか 1 つ）から「直さない指摘」を消す → TC-31 が FAIL
- 件数を足す句、「振り分けも報告もしない」、P3 を PdM が数える句を 1 つずつ消す → TC-32 が FAIL
- 起動文字列の「直さない指摘: [ファイル:行」を「直さない指摘: [番号]」に戻す → TC-31 が FAIL

### WIP
(none)

### DISCOVERED
(none)

### DONE
GREEN 済み（全件 PASS）。TC の本文は plan（plan_file）の Test List の文言どおり。
- [x] TC-01 未追跡（tests/test-finding-in-diff.sh）
- [x] TC-02 変更行
- [x] TC-03 diff に無いファイル
- [x] TC-04 複数行の hunk の境界
- [x] TC-05 削除だけの hunk
- [x] TC-06 index だけの変更
- [x] TC-07 パスの書き方
- [x] TC-08 git の設定に左右されない
- [x] TC-09 引数の誤り（rc=2 かつ stderr が空でない）
- [x] TC-10 repo の外
- [x] TC-11 リポジトリの外を指すパス
- [x] TC-12 HEAD が無い repo
- [x] TC-13 計測の失敗例（M1 は pager.py 5 で rc=1、M3 は api.py 6 で rc=0）
- [x] TC-14 読むだけ（worktree-fingerprint.sh の前後比較）
- [x] TC-15 離れた 2 つの変更（diff.interHunkContext=100）
- [x] TC-16 clean filter
- [x] TC-17 追跡も未追跡もされていないパス
- [x] TC-27 照合が修正役の起動より先（tests/test-adversarial-review.sh）
- [x] TC-28 終了コード 1 と 0・2・場所なしの扱い（条件と扱いの組）
- [x] TC-29 `## 頼み方` の依頼文に「ファイル:行」
- [x] TC-30 `## 振り分け` の「直さない指摘」「振り分けも報告もしない」
- [x] TC-31 修正役の起動文字列に「直さない指摘: [ファイル:行」
- [x] TC-32 起動の条件と件数の 4 句
- [x] TC-R1: tests/test-finding-in-diff.sh::TC-18（GIT_LITERAL_PATHSPECS=1 でも変更行は 0）（REVIEW で追加）
- [x] TC-R2: tests/test-finding-in-diff.sh::TC-19（GIT_DIFF_OPTS=-u10 でも未変更行は 1）（REVIEW で追加）
- [x] TC-R3: tests/test-finding-in-diff.sh::TC-20（バイナリ扱いで hunk が取れないときは 2）（REVIEW で追加）

## Implementation Notes

### Goal
REVIEW の修正役が、ほかの機能の動きを変える修正を「直す」に入れることがある（#271）。修正役を起動する前に、PdM が指摘の場所（ファイル:行）を今回の diff と照らし、diff の外（元からある欠陥）と判定した指摘を修正役に「直す」として渡さないようにする。

### Background
2026-10-21 に v2.20.1 の文面で修正段階を 4 回流して測った（`docs/research/review-fixer-impact-2026-10.md`）。

- 元からある欠陥の fixture（M1）で、修正役は 1 回素通りした。共有の `page_count` を直して呼び出し元の footer の出力を変え、それを「意図した波及」と書いた。呼び出し元のテストは「再現テスト」として申告していたので、修正役を 2 段に分ける案では捕まえられない
- PdM は M1 の 2 回とも「指摘の場所 `pager.py:5` は初期 commit のままで、今回の diff はテストを足しただけ」で止めた
- diff が入れた欠陥の fixture（M3）では、2 回とも正しかった

ユーザー決定（2026-10-21）: PdM が 2 回ともしていたこの照合を、修正役を起動する前の手順にする。段に分ける案は作らない。

ユーザー決定（2026-10-28、spec で）:
- 照合は判定スクリプト + 手順で入れる（散文の rule だけでは再発するため）
- 人間への問いを増やさない。場所が書かれていない指摘と、判定できなかった指摘は、今までどおり修正役の振り分けに任せる。diff の外と判定した指摘は、内容（受け入れ条件に関わるか）で「人間に戻す」か「記録のみ」に分ける（`## 振り分け` の既存の規則のまま）

今の文面（main e3aba76）で確かめたこと:
- 3 つの steps の REVIEW 手順 2 は、「直す」の件数を見て修正役を起動するだけ。指摘の場所を diff と照らす手順は無い
- `adversarial-review.md` の `## 振り分け` には「今回の diff が入れたものではない、元からある欠陥は直さない」がある。M1-2 の修正役はこれを使わなかった
- `## 頼み方` の依頼文は、指摘に重大度と再現手順を求めるが、場所（ファイル:行）を求めていない。`agents/adversarial-reviewer.md:49` の出力の型には「場所」がある

### Design Approach
- 照合を PdM の読みではなくスクリプトの終了コードにする（原則 6）。0 = diff の中、1 = diff の外、2 = 判定できない。1 を返すのは「追跡ファイルだと確かめられ、行が変更行に入らない」場合だけで、疑わしきは 2 に倒す
- 1 の指摘だけを修正役に渡さない。0・2・場所なしは今までどおり修正役の振り分けに任せ、人間への問いを増やさない
- 修正役の起動 prompt に「直さない指摘: [ファイル:行 ...」を入れ、M1 型と M3 型が混ざって起動したときも M1 型が直されないようにする。修正役は「直さない指摘」を振り分けも報告もしないので二重計上しない
- 再レビューは足さない（原則 5）。修正役の定義と既存 gate のロジックは変えない
- 研究メモの「見直す条件」（diff の中の指摘で修正役が呼び出し元の動きを変えたら、段に分ける案を見直す）は残す

## Verification

- `bash run-tests.sh tests/test-finding-in-diff.sh`、`bash run-tests.sh tests/test-adversarial-review.sh`
- `bash run-tests.sh`（全件。baseline は main e3aba76 で 121/121。テストファイルが 1 本増えるので 122）
- Real-path invocation: 研究メモの M1・M3 の fixture をスクリプトで作り直し、`bash scripts/gates/finding-in-diff.sh pager.py 5`（rc=1 を期待）と `bash scripts/gates/finding-in-diff.sh api.py 6`（rc=0 を期待）を手で流して TC-13 と同じ結果になることを見る
- REVIEW は敵対的レビュー 1 回 + 振り分け（この cycle の REVIEW から、新しい手順 2 で回す）

Evidence: (orchestrate が自動記入)

## Progress Log

### 2026-10-28 10:47 - KICKOFF
- Cycle doc created from plan (/Users/morodomi/.claude/plans/271-velvet-rossum.md)
- Scope definition ready
- codex_mode: no (RED/GREEN は Claude の worker)
- Phase completed

### 2026-10-28 10:47 - Plan Review (pre-approval)
- codex_session_id: 01a18025-9343-7061-af1a-6bf0b8267181
- review_attempts:
  - {started: 2026-10-28 10:35, completed: 2026-10-28 10:39, verdict: WARN}
  - {started: 2026-10-28 10:40, completed: 2026-10-28 10:42, verdict: WARN}
- findings 要約: 1 回目 P2×4・P3×2（起動条件と未分類の指摘の関係 / `diff.interHunkContext` で未変更行が hunk に入る / clean filter で行番号がずれる / 「直さない指摘」の受け渡しと件数のテストが無い / TC-14 が失敗同士の一致で通る / 追跡も未追跡もされていないパスの扱い）。2 回目 P2×2・P3×1（PdM 分と修正役分の二重計上 / 番号と原文の対応が未定義 / P3 だけのときの記録担当）。すべて反映した。3 回目のレビューはしない（Step 8 の規定）
- unresolved_blocks: なし
- plan_presented: 2026-10-28 10:45
- reviewed_plan_hash: f48b318eb08cca86c158c0788fd21e57037be5bb12d5f3a99223a83bd1ac2c70
- verdict: WARN
- Phase completed

### 2026-10-28 10:47 - SYNC-PLAN
- Cycle doc generated from plan (Test List 32 items, Plan Review Record transferred)
- Phase completed

### 2026-10-28 10:48 - ARCHITECT
- verdict: PASS（転記欠落なし / scope 実質変更なし / 観察のみ 3 件）
- Design Review Gate: Files to Change 8 件（10 以下）。In Scope は A〜E で具体的。Test List は正常系・境界値（TC-04/05/15）・異常系（TC-09〜12/16/17）を網羅し、各項目が Given/When/Then で検証可能。Risk 25 は「手順 1 つ追加、gate ロジック不変」と整合
- 実ファイル突合:
  - steps-codex.md:143 / steps-subagent.md:201 / steps-teams.md:246 の REVIEW 手順 2「修正」は、「「直す」が 0 件なら修正役を起動せず」で始まる 1 行。照合は同じ行のこの句より前に置ける（TC-27 の前提を満たす）。finding-in-diff の既出は skills・tests・scripts に 0 件（新規）
  - adversarial-review.md: `## 頼み方` に fenced block の依頼文あり（TC-29 の対象）、場所（ファイル:行）の指定は未記載。`## 振り分け`:42 に「元からある欠陥は直さない」あり（TC-30 は 1 文足す形で成立）
  - tests/test-adversarial-review.sh: `sec()`:65、`review_sec()`:87、`check_steps_review_has()`:90 が実在。最大 TC 番号は TC-26 を実測し、TC-27〜32 の採番は有効。scripts/gates/worktree-fingerprint.sh は実在（TC-14 で使用可）。tests/test-finding-in-diff.sh は未作成（TC-01〜17 は RED で落ちる）
  - `bash scripts/gates/pre-red-gate.sh <cycle_doc>` を実行: PASS（rc=0）
- Post-Transfer Verification: plan の Scope（A〜E）、Files（8 件）、Test List（TC-01〜17・27〜32）、検出力の確認、Plan Review Record（codex_session_id / review_attempts 2 件 / findings 要約 / unresolved_blocks / plan_presented / reviewed_plan_hash / verdict）が Cycle doc の frontmatter・本文・Progress Log に欠落なく反映されている
- 観察のみ（DISCOVERED 相当。frontmatter は修正しない）:
  1. test_count: frontmatter は 32 だが、Test List の実数は 23 件（TC-01〜17 の 17 件 + TC-27〜32 の 6 件）。32 は最大の TC 番号であり件数ではない。RED が test_count を更新する時に実数へ直す
  2. steps-codex.md:147 の green-worker 代行は「prompt に同じパスのレビュー結果を渡す」という散文で、`Task(subagent_type: "dev-crew:green-worker"` の prompt 文字列を持たない（subagent・teams は持つ）。TC-31 は「3 つの steps の Task prompt」に「直さない指摘: [ファイル:行」を求めるため、GREEN で steps-codex.md の Task にも prompt 文字列を足す必要がある。Files to Change の範囲内で scope は変わらない
  3. 手順 2 の先頭に照合・起動の条件・件数の足し算を入れると、既存の 1 行がさらに長くなる。TC-27 が「同じ行の中」を要求するため、行を分けず 1 行に収める（分けるなら TC-27 の「同じ行」を直す）
- Phase completed

### 2026-10-28 11:05 - RED
- tests/test-finding-in-diff.sh を新規作成（TC-01〜17、46 アサーション）。tests/test-adversarial-review.sh に TC-27〜32 を追記
- test_count を実数 23 に更新（ARCHITECT 観察 1）
- FAIL 件数: test-finding-in-diff.sh は 17 TC すべて FAIL（スクリプトが無く rc=127。46 アサーション中 46 件 FAIL）/ test-adversarial-review.sh は新規 TC-27〜32 の 6 件 FAIL、既存 TC-01〜26 と TC-14 は 32 件 PASS のまま
- 全件 `bash run-tests.sh`: PASS 120 / FAIL 2 / TOTAL 122。落ちたのはこの 2 ファイルだけ（baseline 121 + 新規 1 本）
- 検証: リポジトリの外の試作スクリプトを置いて tests/test-finding-in-diff.sh を流すと 46/46 PASS（テスト側の fixture が成立することの確認）。試作は repo に入れていない
- TC-09 の stderr 検査は rc=2 のときだけ通す（スクリプト不在時の bash のエラー文で偽 PASS しない）
- 注意（GREEN 向け）: steps-codex.md の green-worker 代行は散文で、TC-31 のために `Task(subagent_type: "dev-crew:green-worker"` の prompt 文字列を持つ行が要る
- Phase completed

### 2026-10-28 11:15 - GREEN
- 変更: scripts/gates/finding-in-diff.sh（新規・実行権限付き）、skills/orchestrate/steps-codex.md / steps-subagent.md / steps-teams.md（REVIEW 手順 2 の先頭に照合・起動の条件・件数。3 ファイル同文）、skills/orchestrate/adversarial-review.md（頼み方に場所、振り分けに 1 文）、CHANGELOG.md（[Unreleased] Changed）
- steps-codex.md の green-worker 代行に `Task(subagent_type: "dev-crew:green-worker", model: "sonnet", prompt: ...)` を足し、3 steps の Task prompt と codex exec resume の文字列に「直さない指摘: [ファイル:行 と、指摘の 1 行目]」を入れた
- 判断: 手順 2 の説明文に「codex exec」と書くと test-codex-session-unify.sh（codex exec の形の検査）が散文の行を拾って FAIL したため、「Codex への起動文字列」と書いた
- 結果: tests/test-finding-in-diff.sh PASS / tests/test-adversarial-review.sh PASS / 全件 `bash run-tests.sh` PASS 122 / FAIL 0 / TOTAL 122（1 回目の全件実行は並行実行の干渉で test-codex-session-isolation.sh が落ち、単独では PASS。test-codex-session-unify.sh の FAIL は上の文言が原因で修正済み）
- Phase completed

### 2026-10-28 11:25 - GREEN 検出力の確認
- 変異 19 件を 1 つずつ入れて検出力を確認し、16 件を検出、3 件が未検出だった
- 未検出の 3 件をテストを強めて検出するようにした（実装・doc は変えていない）:
  1. TC-02 の `d` 既定（`c = s; d = 1` を `d = 0` に変える）: tests/test-finding-in-diff.sh の TC-02 に「6 行目（変更行の次の行）は rc=1」を追加
  2. TC-31 の Task prompt の除去、3. TC-31 の Task prompt の番号化（`直さない指摘: [番号]`）: tests/test-adversarial-review.sh の TC-31 が、Task( の後の `prompt: "…"` の閉じ引用符までの中だけを検査するようにした。steps-codex.md の `codex exec ... resume` も、resume の後の引用された prompt 文字列の中にあることを検査する。3 つの steps すべてに適用
- 確認（リポジトリの外のコピーで変異）: TC-02 の `d = 0` は TC-02 が FAIL / Task prompt の除去と番号化はどちらも TC-31 が FAIL。今の実装では両テストとも全 PASS
- 全件 `bash run-tests.sh` PASS 122 / FAIL 0 / TOTAL 122
- Phase completed

### 2026-10-28 11:32 - REFACTOR
- 補足（PdM）: 上の「16 件を検出」は 1 回目の実行の数え方。1 回目は 14/19 で、未検出 5 件のうち 2 件（`--no-ext-diff --no-textconv` と `--inter-hunk-context=0` の除去）は変異スクリプトの誤りだった（同じ文字列がヘッダのコメントに先に出てくるので、コードではなくコメントを書き換えていた）。コード側を書き換えるよう直すと検出した。残り 3 件がテストの穴で、上の手当てで検出した。手当て後に 19 件すべてを流し直し、19/19 を検出した（変異は scratchpad の mut271/run_mut.py）
- チェックリスト 7 項目を finding-in-diff.sh と 2 つのテストに当てた。重複・定数・未使用・命名に直す箇所は無い。スクリプトは 1 つの責務（場所の判定）で、パスの正規化と hunk の解析は 1 か所ずつ。変更なし
- 静的解析: shellcheck は未導入。`bash -n scripts/gates/finding-in-diff.sh` は OK
- 全件 `bash run-tests.sh` PASS 122 / FAIL 0 / TOTAL 122（REVIEW の修正段階の比較基準）
- Phase completed

### 2026-10-28 11:33 - VERIFY
- real-path: このリポジトリで `bash scripts/gates/finding-in-diff.sh` を直接実行（/tmp/dev-crew-verify-20261028_1047/real-path.txt）。steps-codex.md の変更行 143 → 0、未変更の 1 行目 → 1、未追跡の tests/test-finding-in-diff.sh → 0、README.md:1 → 1、存在しないパス → 2、ignore 対象（__pycache__）→ 2

### 2026-10-28 11:49 - REVIEW
- Codex（新しいセッション、read-only）で敵対的レビューを 1 回。P2 × 3、すべて実行で再現済み: (1) `GIT_LITERAL_PATHSPECS=1` で変更行が 1 になる（finding-in-diff.sh:76）(2) `GIT_DIFF_OPTS=-u10` で未変更行が 0 になる（:95）(3) `core.bigFileThreshold` でバイナリ扱いになると変更があっても 1（:110）
- 新しい手順 2 の照合をこの cycle 自身に当てた: 3 件とも `finding-in-diff.sh scripts/gates/finding-in-diff.sh <行>` が 0（未追跡の新規ファイル）。直さない指摘: なし。3 件を修正役（green-worker）に渡した
- 修正役: 3 件とも直す。スクリプト冒頭で pathspec 系と GIT_DIFF_OPTS・GIT_EXTERNAL_DIFF の環境変数を unset、`Binary files` の行があれば 2。再現テスト TC-18〜20 を先に足し、修正前に 5 件 FAIL を確認（TC-R1〜R3）
- PdM の確認: Codex の再現コマンド 3 本を流し直し、40 行目 0 / 39 行目 1 / バイナリ扱い 2。全件 122/122（REFACTOR 時点から新たな FAIL なし）。未追跡ファイルの一覧は修正の前後で同じ
- Codex review: 直す 3 / 人間に戻す 0 / 記録のみ 0
- Phase completed

### 2026-10-28 12:54 - COMMIT
- COMMIT 前の md で人間が確認（決めてほしいことなし）。pre-commit-gate PASS、全件 122/122。STATUS.md・NEXT.md を更新
- Phase completed

---

## Next Steps

1. [Done] KICKOFF
2. [Done] SYNC-PLAN <- Current
3. [Next] RED
4. [ ] GREEN
5. [ ] REFACTOR
6. [ ] REVIEW
7. [ ] COMMIT
8. [ ] DONE

## Retrospective

### Insight 1

- **Failure**: GREEN の後の変異で、`--no-ext-diff --no-textconv` と `--inter-hunk-context=0` の除去が「未検出」と出た。変異スクリプトは文字列の最初の 1 か所を置き換えていて、同じ文字列がヘッダのコメントに先に出てくるため、コードではなくコメントを書き換えていた。テストの穴だと誤って読みかけた
- **Final fix**: 置き換え元を、コードにしか無い前後の文脈（`-U0 --inter-hunk-context=0 -- "$spec"` など）まで含めた文字列に変えて流し直し、検出を確かめた
- **Insight**: 変異の「未検出」は、テストの穴と決める前に、変異が実行される行に入ったかを確かめる。置き換え元は、コメントや説明文に同じ文字列が無いことを grep で確かめた、コードにしか無い文脈で指定する

### Insight 2

- **Failure**: TC-31 は「直さない指摘: [ファイル:行」が Task( の行にあるかを見ていた。同じ行の前のほうにある説明文にも同じ句があるので、Task の prompt 文字列から句を消しても、番号に変えても PASS した
- **Final fix**: 行の中で `Task(subagent_type: "dev-crew:green-worker"` の後ろの `prompt: "` から閉じ引用符までを取り出し、その中だけを検査するようにした。codex exec の resume の文字列も、引用された prompt の中だけを検査する
- **Insight**: 「起動する文字列に句が入っている」契約は、行単位ではなく、起動の引用文字列そのものを切り出して検査する。説明文と起動の文字列が同じ行に並ぶ doc では、行単位の検査は説明文の同じ句で通る

### Insight 3

- **Failure**: finding-in-diff.sh は、Recall（cycle 20261016_1645 Insight 1）に従って git の設定（external diff・textconv・interHunkContext）の影響を外したが、環境変数（`GIT_LITERAL_PATHSPECS`・`GIT_DIFF_OPTS`）と、hunk が出ない差分（`core.bigFileThreshold` によるバイナリ扱い）が残った。REVIEW の Codex が 3 件とも実行で再現した
- **Final fix**: スクリプトの冒頭で pathspec 系と diff 系の環境変数を unset し、`Binary files` の行があれば 2（判定できない）にした。TC-18〜20 で固定した
- **Insight**: git の出力を読む gate は、設定（config）だけでなく、出力を変える環境変数も入力として扱って外す。「hunk が無い」を「変更が無い」と同一視しない。差分はあるのに行が取れない場合は、判定できない側に倒す

### 想起漏れ

- **設問**: 今回の手戻りは、過去のどの cycle doc を最初に読んでいれば防げたか
- **回答**: docs/cycles/20261016_1645_adversarial-review-triage.md（Recall で読み、Insight 1 を git の設定にだけ当てた。環境変数まで当てていれば Insight 3 の手戻りは防げた）
