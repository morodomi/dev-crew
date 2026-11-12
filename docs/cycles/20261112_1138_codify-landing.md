---
feature: codify-landing
cycle: 20261112_1138
phase: DONE
complexity: standard
test_count: 17
risk_level: medium
retro_status: captured
codex_session_id: "01a1cd91-7447-7b03-9314-59c2d3792eb4"
plan_file: /Users/morodomi/.claude/plans/sparkling-dreaming-bengio.md
created: 2026-11-12 11:38
updated: 2026-11-12 13:02
---

# codify-landing

codified の rules への反映を出典の逆リンクで数え、反映待ち 66 件を統合して着地させる（Issue #223）。

## Scope Definition

### In Scope

1. [ ] `scripts/codify-landing.sh`（新規）: `bash codify-landing.sh <repo_root> [--count]`。`docs/cycles/*.md` の `## Codify Decisions` から `Decision: codified` かつ `Destination: rule…` の insight を集め、着地していない `<cycle_id> #N` を 1 行ずつ出す。`--count` は件数だけ。引数の誤りは exit 2。rules が無い repo でも動く
2. [ ] テスト `tests/test-codify-landing.sh`（新規）: fixture でスクリプトの判定を固め、実際の作業ツリーで未着地 0 件を固める
3. [ ] Block 0 の codify notice に、未着地の件数の通知を足す。呼び出しは `bash "<orchestrate の Base directory>/../../scripts/codify-landing.sh" . --count`（tests/test-skill-script-paths.sh の形）。同じ通知のコードを持つ 4 文書を揃える: orchestrate の SKILL.md・reference.md・steps-subagent.md・steps-teams.md（tests/test-codify-insight.sh :452・:657 が 4 文書の一致を要求し、:407 がコードを実行して整数 1 行を要求する）。captured を数える既存のコードはそのまま残し、未着地の件数は別のコードブロックにする。SKILL.md は 100 行以下を保つ
4. [ ] codify-insight/reference.md の Rule Tier Contract の反映の段落に、反映するときは条項の行か `## 出典` に `(<cycle_id> #N)` を書くこと、取り下げは `docs/codify-withdrawn.md` に理由付きで書くことを足す
5. [ ] 反映待ち 66 件の着地（統合して減らす）。書き先:
   - rules/test-patterns.md（tests/**）: 約 20 件
   - rules/plan-discipline.md: 約 13 件（always の 1 件を含む）
   - rules/agent-prompts.md: 約 9 件
   - rules/shell-scripts.md（新規、scripts/**・skills/**/*.sh）: 9 件
   - rules/review-triage.md・doc-mutations.md・integration-verification.md・skill-authoring.md・multi-file-consistency.md: 計 約 15 件
   - cycle id はあるが番号の無い 14 件: 既存の条項を確かめて、出典に番号を足す
   - 各 rule の `.claude/rules/` の mirror を同じ内容にする（tests/test-rules-mirror.sh）
6. [ ] `docs/codify-withdrawn.md`（新規）: 取り下げの台帳
7. [ ] rule ファイルの数や名前を見ている既存テストを新しいファイルに合わせる（RED で `grep -rnE 'rules/[a-z-]+\.md|test-patterns\.md' tests/` を洗う）
8. [ ] CHANGELOG `[Unreleased]`、docs/STATUS.md

### Out of Scope

- `resolved` の意味の変更、codify-insight の編集範囲の変更 (Reason: ユーザー決定)
- Destination の書式を確定パスに縛ること (Reason: #223 やること 2。今回やらない)
- Destination が inline-update / skill の 7 件 (Reason: rule ではない)
- 既存 60 件の条項の書き直し (Reason: 出典の書式を揃えるだけでも触らない)
- codify-insight 自身に件数を出させること (Reason: codify-insight は Bash を持たない。`allowed-tools: Read, Edit, AskUserQuestion, Glob`)
- 導入先の rules の棚卸し (Reason: 導入先のセッションでスクリプトを走らせれば数えられる)

### Files to Change (target: 10 or less → 超える)

rules 9 本 + mirror 9 本（新規 1 対を含む）、スクリプト 1、テスト 1 + 既存テスト 1〜3、skill 文書 2、台帳 1、CHANGELOG、STATUS。rules の変更は記述の追加と出典の追記で、手順の新設はスクリプトと Block 0 の 1 行だけ。

- scripts/codify-landing.sh (new)
- tests/test-codify-landing.sh (new)
- docs/codify-withdrawn.md (new)
- rules/shell-scripts.md, .claude/rules/shell-scripts.md (new)
- rules/{test-patterns, plan-discipline, agent-prompts, review-triage, doc-mutations, integration-verification, skill-authoring, multi-file-consistency}.md と .claude/rules/ の同名 (edit)
- skills/orchestrate/{SKILL.md, reference.md, steps-subagent.md, steps-teams.md}, skills/codify-insight/reference.md (edit)
- tests/test-codify-insight.sh（Block 0 の 4 文書一致の検査に新しいコードブロックを含める）、tests/test-codify-rule-docs.sh（触らない。TC-57 の契約を守ることを確かめるだけ）
- CHANGELOG.md, docs/STATUS.md (edit)
- rule ファイルの集合を見ている既存テスト (edit、RED で特定)

### 止める基準

- GREEN の後に rules/ の合計が 900 行を超えたら止めて人間に戻す（今 657 行。数える時点は GREEN 完了時、数える対象は rules/*.md の `wc -l` の合計）
- 取り下げが 15 件を超えたら止めて人間に戻す（統合ではなく取り下げに流れていないかを確かめる）。数える時点は GREEN 完了時、数える対象は docs/codify-withdrawn.md の、理由を持ち実在の insight を指す行の一意の `<cycle_id> #N`

## Environment

### Scope
- Layer: Backend（bash のスクリプト 1 本とテスト、rules と skill の文書）
- Plugin: なし（dev-crew 本体。`bash run-tests.sh`）
- Risk: 35 (WARN)。rules の文面を広く変える（導入先へ mirror で配られる）・新しい rule ファイル・Block 0 の手順追加

### Runtime
- Language: bash 3.2 / zsh

### Dependencies (key packages)
- なし（bash / awk / grep のみ）

### Risk Interview (BLOCK only)
- 該当なし（WARN。以下は WARN 確認の自己回答）
- 影響: rules/ の変更は、次の onboard で導入先の `.claude/rules/` に mirror される。Block 0 の通知は導入先でも動く（導入先の rules は `.claude/rules/` にしかないので、スクリプトは両方を読む）
- 変わる動き: orchestrate の開始時に、rules に反映されていない codified の件数を 1 行で知らせる（0 件なら出さない）。進行は止めない
- 変えないもの: codify-insight の判定と `resolved` の意味、codify-insight の編集範囲（rules を編集しない）、state-ownership の表

## Context & Dependencies

### Reference Documents
- docs/cycles/*.md の `## Codify Decisions` - 判定の入力
- skills/codify-insight/reference.md - Rule Tier Contract
- tests/test-codify-insight.sh - Block 0 の 4 文書一致（:407・:452・:657）
- tests/test-codify-rule-docs.sh - TC-57（20260717_1605 #2 の条項と出典が rules に無いことを要求。緩めない）
- tests/test-rules-path-scoping.sh - TC-07（always 層の行数凍結、canonical 76 / mirror 103）
- tests/test-rules-mirror.sh, tests/test-skill-script-paths.sh

### Dependent Features
- orchestrate Block 0 codify notice: skills/orchestrate/SKILL.md, reference.md, steps-subagent.md, steps-teams.md
- codify-insight: skills/codify-insight/reference.md

### Related Issues/PRs
- Issue #223: codified の rules への反映を数える仕組み
- 関連する feedback: rules は読むたびにコストがかかる（feedback_rules_hide_their_cost）。行数を上限で縛る

## Recall

### docs/cycles/20260422_1313_rule-docs-codify-followup.md
- **何が起きたか**: 23 件の insight を rules にした cycle。2 つの insight を都合よくまとめて原典と違う条項を書き、Codex に原典と照らされて直した（Insight 3）。テスト数を上げたとき逆向き契約を grep せず、TC が落ちた（Insight 1）
- **当時の前提**: Reason や要約から条項を書いてよい
- **今回も同じ前提か**: No。統合するときは原文（Failure / Final fix / Insight）を読み直し、まとめた理由を 1 行書く。rule ファイルの数を見ているテストは RED で grep する

### docs/cycles/20260423_0926_discovered-followup-mirror-rules.md
- **何が起きたか**: mirror を作ったが `.gitignore` で git に入っていなかった
- **当時の前提**: ファイルがあれば commit される
- **今回も同じ前提か**: No。新しい rules/shell-scripts.md の mirror は `git status` に出ることを GREEN で確かめる（今の .gitignore は `!.claude/rules/` を持つ）

## Test List

### TODO

`tests/test-codify-landing.sh`（新規）。fixture は `mktemp -d` の中に `docs/cycles/` と `rules/`（または `.claude/rules/`）を作る:

### WIP

(none)

### DISCOVERED
(none)

### DONE

`tests/test-codify-landing.sh`（新規）と `tests/test-codify-insight.sh`（edit: TC-15c / TC-16c / TC-17c / TC-27c を追加）で GREEN を確認済み。TC-10 は一回限りの計測で、Progress Log の「TC-10」に記録:

- [x] TC-10: Given 作業ツリーを GREEN 前の状態（今の main）, When スクリプトを実行する, Then 未着地は 66 件で、その ID の集合が使い捨ての集計（landing.tsv の EXACT 以外）と一致する。対象の ID の集合（rule 行き）も出し、Codex の数え方（134）との差を ID ごとに原文で確かめる。このときだけの確認で、テストには残さない（RED の記録に貼る）
- [x] TC-01: Given 引数なし・存在しないディレクトリ・未知のオプション, When スクリプトを実行する, Then exit 2 で usage を stderr に出す
- [x] TC-02: Given codified・rule の Insight 1 と、rules/x.md に `(20260101_0000 #1)` がある fixture, When 実行する, Then 何も出さず、`--count` は 0
- [x] TC-03: Given 出典の形が `docs/cycles/20260101_0000_x.md #2`・`Insight 3`・`Insights 1, 2, 4`・`#1, #5` の rules, When 実行する, Then どれも着地とみなす
- [x] TC-04: Given 見出しが `### Insight 1:`（コロン付き）、Decision の後ろに説明が続く Codify Decisions, When 実行する, Then 番号 1 の codified として扱う
- [x] TC-04b: Given 1 つの doc に `## Codify Decisions` が 2 つ（最初は空）あり、コードブロックの中に偽の `## Codify Decisions` と `### Insight 9` があり、見出しが `### Insight 2（補足）` の形のもの, When 実行する, Then 2 つ目の節の insight を数え、コードブロックの中は数えず、括弧付きの見出しは番号 2 として扱う
- [x] TC-05: Given no-codify・deferred の insight と、codified で Destination が inline-update / skill の insight, When 実行する, Then どれも出さない
- [x] TC-06: Given rules に `20260101_0000 #12` しかないときの #1、`20260101_0000 #1, 20260202_0000 #2` の行での 20260101_0000 #2、別の cycle id の同じ番号, When 実行する, Then どれも未着地として出す
- [x] TC-07: Given rules/ が無く `.claude/rules/local-x.md` に出典がある導入先の形, When 実行する, Then 着地とみなす
- [x] TC-08: Given `docs/codify-withdrawn.md` に `- 20260101_0000 #1 — 理由` と、理由の無い `- 20260101_0000 #2`, When 実行する, Then #1 は出さず、#2 は出す
- [x] TC-09: Given 未着地が 2 件, When 実行する, Then `<cycle_id> #N` を 1 行ずつ出し、`--count` は `2` だけを出す。rc は 0
- [x] TC-11: Given 実際の作業ツリー, When `codify-landing.sh "$BASE_DIR" --count`, Then 0
- [x] TC-12: Given `docs/codify-withdrawn.md` の各行, When 読む, Then どれも理由を持ち、消えた仕組みを指す commit かパスを持ち、指す `<cycle_id> #N` が実際に codified・rule の insight として存在する
- [x] TC-13: Given orchestrate の SKILL.md・reference.md・steps-subagent.md・steps-teams.md, When Block 0 を読む, Then 4 文書とも `codify-landing.sh` を Base directory からの相対で呼ぶ同じコードブロックを持ち、0 件なら通知しない旨を持つ。SKILL.md は 100 行以下。captured を数える既存のコードブロックは変わらない
- [x] TC-13b: Given 導入先の形の fixture repo（rules/ が無く `.claude/rules/` と docs/cycles/ がある）と、別の場所にある本体の作業ツリー, When fixture repo を cwd にして、Block 0 のコードブロックの `<orchestrate の Base directory>` を本体の skills/orchestrate に置き換えて実行する, Then fixture repo の未着地の件数が整数 1 行で出る
- [x] TC-14: Given codify-insight/reference.md, When Rule Tier Contract を読む, Then `(<cycle_id> #N)` の書式と `docs/codify-withdrawn.md` を挙げる
- [x] TC-15: Given rules/shell-scripts.md, When frontmatter を読む, Then 1 行目から始まり、paths に `**/*.sh`・`scripts/**`・`skills/**` を持ち、`**` 単独や `**/*` を持たない（always 層の行数は変わらない）
- [x] TC-R1: tests/test-codify-landing.sh::TC-16a・TC-16b（REVIEW で追加。Insight でない `### ` 見出しで番号を切る）
- [x] TC-R2: tests/test-codify-landing.sh::TC-17（REVIEW で追加。出典の行の無関係な `#N` を着地にしない）
- [x] TC-R3: tests/test-codify-landing.sh::TC-18（REVIEW で追加。4 連バッククォートの fence）
- [x] TC-R4: tests/test-codify-landing.sh::TC-19a〜TC-19d（REVIEW の「人間に戻す」を人間が「直す」と決めて追加。`~~~` の fence）

### 変異で確かめること（REFACTOR 後）

- rules のどれか 1 条の出典から `#N` を消す → TC-11 が落ちる
- 判定の「直前の cycle id に結び付ける」を外す → TC-06 が落ちる
- 台帳の理由の検査を外す → TC-08 が落ちる
- Destination の rule の絞り込みを外す → TC-05 が落ちる
- Block 0 の呼び出しを `bash scripts/codify-landing.sh` に戻す → TC-13 と test-skill-script-paths が落ちる

## Implementation Notes

### Goal

#223: codify-insight が `codified`・`Destination: rule` と判定した insight が rules に書かれないまま残る問題を、rule → cycle doc の逆リンク（出典）で着地を数える仕組みと、反映待ち 66 件の統合・着地で解消する。

### Background

`resolved` は「判定が済んだ」の意味で、反映する主体が決まっていない。導入先では 42 件が 7 週間反映されず、同じ失敗が 2 cycle 続けて再発した。本体でも積み上がっている。

2026-11-12 の実測（本体、`docs/cycles/*.md` の `## Codify Decisions` 全件）:

- codified 134 件 / deferred 56 / no-codify 80。codified のうち Destination が rule のもの 126 件（inline-update 5・skill 2・new-cycle 1 は対象外）
- rules/ に「cycle id + insight 番号」の出典があるもの 60 件
- cycle id は出典にあるが insight 番号が無いもの 14 件
- どこにも出てこないもの 52 件（20 cycle、20260723_1328 以降）
- 反映待ちは計 66 件。rules/ の現在の行数は 657 行

数え方で母数が変わる: 承認前レビューで Codex が fence の外の全 Codify 節を別に数えると、rule 134 / 着地 68 / 未着地 66 だった（docs/cycles/20260709_1125_risk-classifier-doc-diff-fix.md は :173 に空の節、:344 に本当の節を持つ）。未着地の 66 は一致するが、母数と着地は一致しない。RED で新しいスクリプトの「対象の ID の集合」と「未着地の ID の集合」を、使い捨ての集計と Codex の数え方の両方と照らし、差があればその ID を 1 件ずつ原文で確かめて記録する。

ユーザー決定（2026-11-12）:
- 反映待ちは統合して減らす。同じ教訓は 1 条にまとめて出典を並べ、既存の条項と重なるものは出典を足すだけにし、消えた仕組みに依存するものは理由を書いて取り下げる
- 仕組みは「件数を出す + 本体でテスト」。`resolved` の意味は変えない
- #223 と今回の 11 件を 1 本の cycle で扱ってよい

### Design Approach

- 判定はスクリプト 1 本に集め、Block 0 の通知と本体のテストが同じスクリプトを呼ぶ
- 着地の単位は insight 1 件。統合した条項は出典に複数の `<cycle_id> #N` を並べる
- 新しく書く出典は `(<cycle_id> #N)` の形に揃える（cycle_id は `YYYYMMDD_HHMM`）。既存の書き方も受け付ける
- 反映の作業（GREEN）: insight の原文（`## Retrospective` の Failure / Final fix / Insight。Reason の要約だけで書かない）を読んで条項にする。書き先ごとに worker を分け、同じファイルを 2 人で編集しない。取り下げの候補は worker が PdM に返し、台帳は PdM が書く。mirror は書き先の worker が同時に揃える

Ambiguity Resolution:

- 「着地」の判定: rules/*.md と .claude/rules/*.md のどこかの行に、cycle id（`YYYYMMDD_HHMM`）とその insight 番号が出典の形で並んでいれば着地とする。番号の形は `#N`・`Insight N`・`Insights 1, 2, N`・`#1, #N` を受け付ける。同じ行に別の cycle id があるときは、直前の cycle id に結び付ける
- 取り下げ: `docs/codify-withdrawn.md` に `- <cycle_id> #N — <理由>` と書いたものは着地扱いにする。理由の無い行は数えない。rules 本文には書かない
- 取り下げてよい理由は「依存する仕組みが消えた」だけにする（例: steps-codex、codex_mode full、消えた自動 codify）。台帳の行には、消えた仕組みと、消えたことが分かる commit か削除済みのパスを書く。「テストやゲートがある」は取り下げの理由にしない（20260724_1450 で TC-65 があっても codified にした例）
- 統合: 他の insight と同じ教訓なら、統合先の条項に両方の出典を並べる。これは着地で、台帳には書かない
- 取り下げの既知の候補: `20260717_1605 #2`（消えた自動 codify に依存）。tests/test-codify-rule-docs.sh TC-57 はこの条項と出典が rules に無いことを要求しているので、rules には書かず台帳に入れる。TC-57 は緩めない
- tier が `always` の 1 件（20260908_1715 #1）: always 層は行数が凍結されている（TC-07、canonical 76 / mirror 103）。交換で always に入れる案は取らず、cycle-scoped の rule に置き、理由を Cycle doc に書く
- `scripts/**`・`skills/**`・`**/*.sh` を paths に持つ 9 件: 新しい file-scoped rule `rules/shell-scripts.md` に置き、paths は元の insight の範囲の和にする: `**/*.sh`（20260903_1130 #2、20260906_1120 #2）、`scripts/**`、`skills/**`（20261015_1750 #2、20261020_0955 #3）。`**/*.sh` は .sh に限るので、Rule Tier Contract の「repo 全域の glob」には当たらない

Plan Review attempt 2 の重要 1 件（RED/GREEN で対応）: tests/test-codify-insight.sh の extract_bash_fence（:323）は節内の bash ブロックを全部連結し、TC-15b（:409）がまとめて実行するので、別のコードブロックに分けるだけでは「整数 1 行」の契約を守れない。captured のブロックと未着地のブロックを別々に取り出せるようにし、TC-15b は captured のブロックだけを実行する（未着地のブロックの実行は TC-13b が受け持つ）。

## Verification

**Real-path invocation を最低 1 件含めること** (rules/integration-verification.md)。

```bash
bash run-tests.sh tests/test-codify-landing.sh
bash scripts/codify-landing.sh . ; bash scripts/codify-landing.sh . --count   # 何も出さない / 0
bash run-tests.sh            # 全体。122 本 + 1 本 = 123 本で FAIL 0
wc -l rules/*.md | tail -1   # 900 以下
grep -c '^- ' docs/codify-withdrawn.md   # 15 以下
```

Evidence: (orchestrate が自動記入)

## Progress Log

### 2026-11-12 11:38 - KICKOFF
- Cycle doc created
- Scope definition ready

### 2026-11-12 11:38 - Plan Review (pre-approval)
- codex_session_id: 01a1cd91-7447-7b03-9314-59c2d3792eb4
- review_attempts:
  - {started: 2026-11-12 11:23, completed: 2026-11-12 11:30, verdict: WARN}
  - {started: 2026-11-12 11:31, completed: 2026-11-12 11:32, verdict: WARN}
- findings 要約: attempt 1（WARN、BLOCK 0・重要 4・軽微 1）: 未着地 66 件の一致だけでは読み落としを検知できない（全 Codify 節を数えると rule 134 / 着地 68。空の初回節を持つ doc がある）/ 取り下げ理由「テストやゲートがある」が広すぎる、20260717_1605 #2 は TC-57 の不在契約を守って台帳へ / Block 0 の通知コードは 4 文書の一致と実行テスト（test-codify-insight.sh :407・:452・:657）に縛られる / shell rule の paths が元の範囲（`**/*.sh`・`skills/**`）を外す / 取り下げ 15 件の数える時点が未定義 → 全て反映。attempt 2（WARN、重要 1）: test-codify-insight.sh の extract_bash_fence（:323）は節内の bash ブロックを全部連結し、TC-15b（:409）がまとめて実行するので、別のコードブロックに分けるだけでは「整数 1 行」の契約を守れない → 再レビューは 1 回までなので plan 本文は変えず、ここに記録して RED/GREEN で対応する: captured のブロックと未着地のブロックを別々に取り出せるようにし、TC-15b は captured のブロックだけを実行する（未着地のブロックの実行は TC-13b が受け持つ）
- unresolved_blocks: なし
- plan_presented: 2026-11-12 11:32
- reviewed_plan_hash: a7e610b560c77887897d155211d9a3a8372d57cef16abc0f2af7947bcb8a2b4f
- verdict: WARN
- Phase completed

### 2026-11-12 11:38 - SYNC-PLAN
- Cycle doc generated from plan (Test List 17 items, Plan Review Record transferred)
- Phase completed

### 2026-11-12 11:40 - DESIGN REVIEW
- verdict: WARN（BLOCK 要因なし。RED で下記 2 点を拾えば進行可）
- Post-Transfer Verification: 転記欠落なし。codex_session_id / plan_file / Plan Review (pre-approval) エントリ（review_attempts 2 件、reviewed_plan_hash、verdict、unresolved_blocks）が plan と一致。Scope / Files / Test List 17 件 / 止める基準 / 変異一覧も plan と一致。`bash scripts/gates/pre-red-gate.sh` を実行して PASS（rc=0）
- 3 分岐: 転記欠落 = なし / scope 実質変更 = なし（Files to Change は plan 全量を尊重、追加・削除なし）/ 観察のみ = 下の (a)(b)
- 実ファイル突合の結果:
  - tests/test-codify-insight.sh: extract_bash_fence（:323）は `^```bash` 〜 `^```` の中身を全部連結する。TC-15b（:407）は SKILL.md の連結スニペットを fixture（scripts/ の無い mktemp dir）で実行して整数 1 行を要求する。:452 の check_steps_notice と :657 の TC-27 は、4 文書のスニペットが SKILL.md と文字列一致することを要求する。したがって未着地用ブロックを足すと、連結結果が変わり TC-15b が壊れる（fixture に scripts/codify-landing.sh が無い）。plan の「captured のブロックと未着地のブロックを分けて取り出す」方針と両立する。条件: 取り出しの関数を 2 つ（または fence の序数指定）にして、4 文書の一致検査は両方のブロックに、TC-15b の実行は captured のブロックだけに掛ける。節の区切りは、SKILL.md が次の `**` 行か `#` 行、steps が次の `##` 行まで。新しいブロックは節の内側に置けば抽出される。`**` で始まる行を節の途中に置かないこと
  - tests/test-codify-rule-docs.sh TC-57（:1128 付近）は plan-discipline.md に条項本文（`codify gate は前 cycle doc を変更`）と出典（`...approval-reorder-cycle2.md #2`）が無いことだけを要求する。docs/codify-withdrawn.md は検査対象外なので、20260717_1605 #2 を台帳へ入れる方針と両立する。台帳の行は `docs/cycles/...md #2` と書かず `20260717_1605 #2` の形にするのが安全（scripts は rules しか読まないので影響はないが、将来 TC-57 の対象が広がっても当たらない）
  - tests/test-rules-path-scoping.sh: ファイル一覧の固定は TC-01〜05 が名指しの rule（test-patterns, skill-authoring, 7 本の cycle-scoped）だけで、新ファイルは対象外。TC-07 は paths を持たない rule だけを always として数えるので、paths を持つ shell-scripts.md は always の行数（canonical 76 / mirror 103）に入らない。TC-04 の mirror 一致は新ファイルを名指ししていない。両立する
  - tests/test-rules-mirror.sh: rules/*.md を走査する形で件数の固定がない（固定は CLAUDE_ONLY_FILES = post-approve.md の 1 件だけ）。.claude/rules/shell-scripts.md は `git check-ignore` に引っかからない（rc=1）。両立する
  - skills/orchestrate/SKILL.md は現在 93 行（wc -l）。通知の節は 41〜44 行目で、未着地のブロック（fence 2 行 + コマンド 1 行 + 通知文 1 行）を足すと約 97〜98 行になり、100 行以下に収まる。ただし余裕は 2〜3 行。コマンドは 1 行に収め、説明は reference.md に寄せること
- (a) 観察のみ: tests/test-skill-script-paths.sh は呼び出し箇所を SITES の固定一覧（:31〜46）で持ち、一覧にない呼び出しは検査しない。plan の変異「Block 0 の呼び出しを `bash scripts/codify-landing.sh` に戻す → test-skill-script-paths が落ちる」は、TC-01 が `bash scripts/` を禁じるので落ちる（一覧への追加なしでも成立）。ただし TC-02/03/05 でモード間一致と実在を固めるには SITES に 4 文書の行を足す必要がある。plan の Files to Change には無い（Related Issues の参照のみ）。RED で足すなら、Cycle doc の Files に即時同期する（doc-mutations の SSOT 即時同期）。足さない場合は TC-13 / TC-13b が実在を受け持つので必須ではない
- (b) 観察のみ: TC-15 の「`**/*` を持たない」は部分文字列の grep だと `**/*.sh` に当たって誤って落ちる。paths の各値を行単位で取り出し、値が `**` か `**/*` に一致するかを完全一致で見ること
- RED で拾うこと（既に plan に書いてある）: rule ファイルの集合を見ているテストの洗い出し。今回の grep で、固定件数や固定一覧を持つ既存テストは見つからなかった（test-discovered-debt-cleanup.sh の SWEEP_FILES は 5 本の名指しで、新ファイルに影響しない）。mirror の件数は 12 + post-approve の 13 本だが、件数の固定はない
- Phase completed

### 2026-11-12 11:47 - RED
- 作ったファイル: tests/test-codify-landing.sh（新規、TC-01〜09・04b・11〜15・13b。TC-10 は一回限りの計測なので入れない）、tests/test-codify-insight.sh（edit）
- test-codify-insight.sh の変更（Plan Review attempt 2 の指摘への対応）: extract_bash_fence は残し、`extract_fence_with <pat>` を足して `extract_captured_fence`（`retro_status` を含むブロック）と `extract_landing_fence`（`codify-landing.sh` を含むブロック）に分けた。check_notice_section の NOTICE_SNIPPET は captured のブロックだけ、NOTICE_LANDING_SNIPPET は未着地のブロック。TC-15b は SKILL_NOTICE_SNIPPET（captured のみ）を実行するので、未着地のブロックが足されても整数 1 行の契約は変わらない。:452 の TC-16/17 と TC-27 は captured の一致検査のまま残し、未着地のブロックの一致検査を TC-15c（SKILL.md に別ブロックがある）・TC-16c・TC-17c・TC-27c として追加
- 逆向き契約の洗い出し: `grep -rnE 'codify-landing|codify-withdrawn|shell-scripts' tests/` は新規 2 ファイル作成前は 0 件
- GREEN への申し送り: 0 件なら通知しない旨は、節の中に `未着地` と `通知しない` を同じ行に持つ文で書く（TC-13）。呼び出しの 1 行は `bash "<orchestrate の Base directory>/../../scripts/codify-landing.sh" . --count`（TC-13）。未着地のブロックは `retro_status` を含めない（TC-15c）
- RED 実測: `bash tests/test-codify-landing.sh` は PASS 0 / FAIL 26。TC-01〜09・11 は scripts/codify-landing.sh が無い（rc=127）、TC-12 は docs/codify-withdrawn.md が無い、TC-13・13b は Block 0 に未着地のブロックが無い、TC-14 は Rule Tier Contract に書式と台帳が無い、TC-15 は rules/shell-scripts.md が無い。`bash tests/test-codify-insight.sh` は PASS 30 / FAIL 4（新規の TC-15c・16c・17c・27c のみ。既存 TC は全て PASS のまま）
- fixture の判定が満たせることの確認: scratchpad に使い捨ての参照実装を置き、TC-01〜09 が全て PASS になることを確かめた（GREEN の実装ではない）
- RED state verified
- Phase completed

### 2026-11-12 11:53 - GREEN (part 1)
- 作ったもの: scripts/codify-landing.sh（新規。awk で fence 外の Codify Decisions を読み、rules 各行の cycle id 直後の番号を直前の cycle id に結び付け、台帳の理由付き行を着地扱い）、orchestrate の 4 文書（SKILL.md・reference.md・steps-subagent.md・steps-teams.md）の Block 0 に未着地の件数のコードブロックと通知文、codify-insight/reference.md の Rule Tier Contract に出典の書式・台帳・スクリプトの記述。SKILL.md は 97 行
- テスト: tests/test-codify-landing.sh PASS 20 / FAIL 3（TC-11・TC-12・TC-15 は後半の担当で想定どおり）、tests/test-codify-insight.sh PASS 34 / FAIL 0、tests/test-skill-script-paths.sh PASS 5 / FAIL 0
- 実測: `bash scripts/codify-landing.sh . --count` は 66（plan の未着地 66 件と一致）

### 2026-11-12 11:54 - TC-10（一回限りの計測、PdM）
- 未着地の ID の集合: 新しいスクリプトの出力 66 件と、使い捨ての集計（landing.tsv の EXACT 以外）66 件を diff して一致（差 0）
- 対象の ID の集合（rule 行き）: docs/cycles だけを複製した repo（rules なし）でスクリプトを走らせて 125 件。使い捨ての集計は 126 行だったが、重複を除くと 125 件で一致。差の 1 行は 20260422_1146 #1 で、この doc は :110 の `## Codify Decisions` が ```markdown のコードブロック（テンプレートの例）の中にあり、使い捨ての集計はそれを数えていた。新しいスクリプトはコードブロックの中を数えない（TC-04b の想定どおり）
- Codex の数え方の 134: codified の全件（rule 126 行 + inline-update 5 + skill 2 + new-cycle 1 = 134）と一致する。Codex は Destination で絞らずに数えていたと見られる。rule 以外の 8 件も着地側（68 = 60 + 8）に数えていれば、未着地 66 は一致する（ID の一覧は Codex の出力に無いので、ここは件数の照合まで）
- 結論: 母数 125、未着地 66、着地 59（125 − 66）。plan の「着地 60」は重複行の 1 件を含んだ数だった

### 2026-11-12 12:05 - GREEN (part 2)
- 反映待ち 66 件を 3 人の green-worker で着地させた（書き先のファイルごとに分け、同じファイルを 2 人で編集しない。テストは各 worker に実行させず PdM がまとめて実行）
  - test-patterns.md + 新規 shell-scripts.md（paths: `**/*.sh`・`scripts/**`・`skills/**`）: 25 件、+40 行。統合 4 条（変異・修正前 FAIL の 4 件、テストの前提を実環境で確かめる 2 件、起動の引用文字列と危険な権限の綴り 2 件、git の gate の環境変数 2 件）
  - plan-discipline.md + review-triage.md + integration-verification.md: 27 件、+22 行。統合 5 条。20260908_1715 #1（tier always）は plan-discipline.md（cycle-scoped）に置いた（always 層は行数が凍結されている）
  - agent-prompts.md + doc-mutations.md + multi-file-consistency.md + skill-authoring.md: 13 件、+16 行。統合 2 条
- 取り下げ 1 件: 20260717_1605 #2（Block 0 の codify gate の自動起動に依存。commit 4f55121 で消えた）を docs/codify-withdrawn.md に記録。tests/test-codify-rule-docs.sh TC-57 の不在契約は保ったまま
- 全体テストで tests/test-codex-mode-removed.sh が FAIL した（TC-02: plan-discipline.md の新しい条項が例に `codex_mode` を書いた、TC-09a: test-patterns.md の新しい条項が例に `--full-auto` を書いた）。#297 の「instruction files に残さない」契約に当たったので、例の書き方を変えて mirror も揃えた
- 止める基準: rules/*.md の合計 735 行（上限 900）、取り下げ 1 件（上限 15）。どちらも基準内
- 確認: `bash scripts/codify-landing.sh . --count` は 0。`bash run-tests.sh` は PASS 123 / FAIL 0。新しい .claude/rules/shell-scripts.md は git status に untracked で出る（gitignore されていない）
- REFACTOR への申し送り: plan-discipline.md に置いた 20260910_1312 #1（完了通知の意味論）と 20260913_0059 #2（委譲文の破壊的コマンド）は、Reason の書き先が agent-prompts.md。20260910_1312 #1 は agent-prompts.md の既存の完了通知の条項と重なる。plan-discipline.md の 20260908_1715 #2 / 20260913_0059 #5 の条項と test-patterns.md の変異の条項も一部重なる
- GREEN Phase completed

### 2026-11-12 12:11 - REFACTOR
- チェックリスト: 重複コード → plan-discipline.md に置いた 20260910_1312 #1（完了通知では逐次化しない）を、agent-prompts.md の既存の完了通知の条項の末尾に統合した（既存の文は変えず 1 文足した）。20260913_0059 #2（委譲文の破壊的コマンド）も Reason の書き先どおり agent-prompts.md に移した。mirror も揃えた。未使用 → scripts/codify-landing.sh の awk の未使用変数 `tail` と未使用の局所変数 `t` を消した。定数化・命名・分割は変更なし
- 変異（scratch のコピー上、BASE_DIR を差し替えて実行）: M1 出典から `#N` を消す → TC-11 FAIL / M2 直前の cycle id に結び付ける処理を外す → TC-06b・TC-11 FAIL / M3 台帳の理由の検査を外す → TC-08 FAIL / M4 Destination の rule 絞り込みを外す → TC-05・TC-11 FAIL / M5 Block 0 の呼び出しを相対に戻す → TC-13 と test-skill-script-paths TC-01 FAIL。5/5 検出
- M3 の 1 回目は置き換えた正規表現が `#N` の後ろの空白を要求したままで、理由の無い行がそこで弾かれて検査を外したことにならず「未検出」と出た。置き換えが検査を本当に外したかを確かめて作り直し、検出を確かめた（20261028_1047 #1 の教訓どおり、未検出をテストの穴と決める前に変異が効いているかを見た）
- Verification Gate: `bash -n` OK（shellcheck は環境に無い）。`bash scripts/codify-landing.sh . --count` は 0。`bash run-tests.sh` は PASS 123 / FAIL 0。rules/*.md の合計 735 行
- Phase completed

### 2026-11-12 12:13 - VERIFY
- Evidence: /tmp/dev-crew-verify-20261112_1138/verify.txt
- `bash run-tests.sh tests/test-codify-landing.sh` PASS 1 / FAIL 0。`bash scripts/codify-landing.sh .` は出力なし、`--count` は 0（real-path invocation）。rules/*.md 735 行（上限 900）。台帳 1 行（上限 15）
- Phase completed

### 2026-11-12 12:26 - REVIEW
- Codex review: 失敗（利用上限、解除 15:48）。adversarial-reviewer で代行: 直す 3 / 人間に戻す 1 / 記録のみ 6
- 対象: `git diff HEAD --name-only` と未追跡の新規ファイル 28 本（本 cycle と無関係な既存の未追跡ファイル .agents/・docs/research/・scripts/gates/__pycache__/・skills-lock.json は外した）。worktree-fingerprint は前後一致（b08f071b…）。finding-in-diff は P1・P2 とも 0（diff の中）
- 直す 3（修正役 green-worker。再現テストを先に足し、修正前で FAIL を確認）:
  - P1: `### Insight N` 以外の `### ` 見出し（`### 成功事例` など）の後の Decision が直前の insight の判定を上書きし、対象を 9 件取りこぼしていた（20260702_1930 #3、20260703_2035 #2、20260706_1020 #2、20260706_1216 #3、20260709_1125 #2、20260709_1313 #2、20260715_1346 #2、20260716_1328 #3、20260717_1126 #4。どれも今は着地済みで件数には影響なし）→ Insight でない `### ` 見出しで番号を切る（TC-16a・TC-16b）
  - P2: 出典の行の後ろの無関係な `#N`（`PR #2`）も着地とみなしていた → cycle id の後ろの最初の `#N` と、そこに `, #M`・`、#M` で続くものだけにする（TC-17）
  - P2: 4 連バッククォートの fence の中の ``` で fence の判定が反転していた → 開いた長さ以上のバッククォートでだけ閉じる（TC-18）
- 人間に戻す 1: `~~~` の fence の中の偽の `## Codify Decisions` 節を読み飛ばすようにしてよいか（レビュー自身が要件の外としている。本体の docs/cycles に `~~~` の fence は無い）
- 記録のみ 6（P3）: 台帳の区切りが ASCII の `-` だと未着地として出る（安全側）/ Decision・Destination の書き方の揺れ（`` `rule` ``・`Rule`）で対象から外れる（Destination の書式は Out of Scope）/ `# ` 見出しが節を終わらせない / 同じ cycle id の doc が 2 つあると番号が混ざる / 否定文中の言及も着地とみなす（仕様どおり）/ サブディレクトリを cwd にすると 0（captured の既存スキャンと同じ前提）
- TC-10 の訂正（追記。上の TC-10 の記録は書き換えない）: 「母数 125」「Codex は Destination で絞らずに数えていた」は誤り。125 は P1 の欠陥で 9 件取りこぼした数で、Codex の 134 が rule 行きの正しい件数だった。使い捨ての集計も同じく `### 成功事例` の後の Decision で上書きされ、2 つの実装が同じ欠陥で一致していた（期待値の出所が独立していなかった）。修正後、docs/cycles だけの repo で対象は 134 件
- 修正後: `bash run-tests.sh` PASS 123 / FAIL 0（REFACTOR 時と同じく落ちたものなし）。`--count` は 0。修正役の前後で未追跡ファイルの一覧は同じ
- Phase completed

### 2026-11-12 12:27 - DISCOVERED
- 起票なし。REVIEW の P3 6 件は影響が小さく記録のみ（上の REVIEW 節）。Destination の書き方の揺れ・確定パス化は #223 の「やること 2」に残る（本 cycle の Out of Scope）。`~~~` の fence は COMMIT 前の md で人間に戻す
- Phase completed

### 2026-11-12 13:01 - HUMAN DECISION（REVIEW の人間に戻す 1 件）
- COMMIT 前の md（`~~~` の fence の中の偽の節を数える件）で、人間が「直してから commit」を選んだ
- green-worker が再現テスト TC-19a〜d を先に足し（修正前で a・b・d が FAIL、c は反転しないことの回帰固定）、fence の判定を「開いた文字（` か ~）と同じ文字で、開いた長さ以上の並びでだけ閉じる」にした（Codify Decisions を読む awk だけ）
- 確認: `bash run-tests.sh` PASS 123 / FAIL 0、`--count` 0、docs/cycles だけの repo で対象 134 件のまま
- 残る CommonMark との差（範囲外、記録のみ）: fence の開始行の 3 スペースまでの字下げ、info string にバッククォートを含む行

### 2026-11-12 13:02 - COMMIT
- docs/STATUS.md の Completed に追記、In Progress の「rules への反映は未着手、#223」を完了に更新。CHANGELOG [Unreleased] に Added 2・Changed 1。skills/ の変更は既存 skill の文面だけで、skill 一覧（README・AGENTS.md・CLAUDE.md）は変わらない
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

- **Failure**: TC-10 で、新しいスクリプトの対象 ID の集合（125 件）と使い捨ての集計を照らして「一致」とし、Codex の 134 件との差は「Destination で絞らずに数えた（126 + 8 = 134）」と件数の算術で説明した。plan は「差を ID ごとに原文で確かめる」と書いていたが、ID ごとの確認はしなかった。実際は 2 つの実装が同じ欠陥（`### 成功事例` の後の Decision が直前の Insight を上書きする）を持ち、9 件を同じように取りこぼしていた。REVIEW の adversarial-reviewer が、欠陥を直したコピーで 134 件になることを示した
- **Final fix**: 修正役が Insight でない `### ` 見出しで番号を切るように直し、TC-16a・TC-16b で固定した。TC-10 の結論は REVIEW 節で訂正を追記した
- **Insight**: 独立の数え方と件数が食い違ったら、差を説明できる算術の仮説で閉じず、片側にだけある ID を列挙して原文で確かめる。期待値を自分で書いた別の集計から取るときは、その集計が被検証物と同じ読み方（節・見出しの切り方）をしていないかを先に疑う。同じ読み方なら、一致は同じ欠陥の一致でしかない

### Insight 2

- **Failure**: rules に新しく書いた条項の例に、消した機能の名前（`codex_mode`）と廃止されたフラグ（`--full-auto`）をそのまま書いた。#297 で入れた「instruction files に残さない」テスト（test-codex-mode-removed.sh TC-02・TC-09a）は rules も対象にしていて、全体テストで落ちた。3 人の worker には「テストは実行しない」と指示していたので、PdM の全体実行まで気付かなかった
- **Final fix**: 例を「消す機能の設定キー」「廃止された Codex のフラグ」と一般名で書き直し、mirror も揃えた
- **Insight**: rules は negative sweep（「この語が 0 件」の契約）の対象でもある。消した仕組みや廃止したフラグを教訓の例に挙げるときは、literal でなく一般名で書く。並列で rules を書かせて worker にテストを禁じるときは、PdM が最初の全体実行で negative sweep の FAIL を見る前提で、その旨を委譲 prompt に書いておく

### 想起漏れ

- **設問**: 今回の手戻りは、過去のどの cycle doc を最初に読んでいれば防げたか
- **回答**: docs/cycles/20260910_1312_retro-insight-ledger.md（Insight 5「二次検証の独立性は言語でなく期待値の出所で決まる」。今回 rules/agent-prompts.md に着地させたばかりの条項で、TC-10 に当てていれば Insight 1 の手戻りは防げた）
