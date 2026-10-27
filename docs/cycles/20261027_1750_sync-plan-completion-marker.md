---
feature: sync-plan-completion-marker
cycle: 20261027_1750
phase: DONE
complexity: standard
test_count: 6
risk_level: low
retro_status: captured
codex_mode: no
codex_session_id: "01a17c4c-0140-75e2-ba23-c95b865c934d"
plan_file: /Users/morodomi/.claude/plans/271-velvet-rossum.md
created: 2026-10-27 17:50
updated: 2026-10-27 18:15
---

# sync-plan-completion-marker (#285)

SYNC-PLAN の完了記録を、書く役の定義とテストで保証する（+ 別リポジトリへの deferred の起票）。

## Scope Definition

### In Scope

A1. `agents/sync-plan.md`
- [ ] 「対象 PHASE_NAME」に SYNC-PLAN を足す（`KICKOFF / SYNC-PLAN / RED / ...`）
- [ ] Step 4 を「Progress Log に完了エントリを書いてから結果 JSON を返す」に変え、書く形を code block で示す:
  ```
  ### <ts> - SYNC-PLAN
  - Cycle doc generated from plan (Test List N items, Plan Review Record transferred)
  - Phase completed
  ```
  `<ts>` は Step 2 の `$NOW` と同じ形（`YYYY-MM-DD HH:MM`）。書く位置は Step 3.5 の Plan Review の転記の後
- [ ] 理由を 1 行添える: pre-red-gate は 1 エントリ内に sync-plan の語と `Phase completed` を求め、KICKOFF と Plan Review の転記はどちらも単独では満たさない

A2. `skills/orchestrate/steps-subagent.md` と `steps-teams.md` の「Phase Summary 永続化 (sync-plan→RED)」のテンプレートの末尾に `- Phase completed` を足す。見出し（`### Phase: SYNC-PLAN - Completed at HH:MM`）は変えない。見出しを `### <時刻> - SYNC-PLAN` にそろえるかどうかは #221（出口での検出）と一緒に決める（#221 にコメント済み）

B. `skills/codify-insight/`
- [ ] reference.md に節「別リポジトリへの deferred」を足す。対象は、Decision が `deferred` で、直し先がこのリポジトリの外にあるもの（典型例は、導入先で実行していて直し先が dev-crew 本体の agents / skills / scripts / rules のとき。判定は既存の Rule Tier Contract と同じく `.claude-plugin/plugin.json` の `name` が `dev-crew` かどうかを使う）
- [ ] その Insight には `- **Upstream issue**: <issue URL>` を書く。URL は AskUserQuestion で聞く。既存の「1 cycle につき 1 回の batch」に含め、別の質問を増やさない。答えが無い、または起票しないと言われたら `- **Upstream issue**: 未起票` と書く
- [ ] Annotation Format の deferred の例に `Upstream issue` の行（別リポジトリの場合だけ）を足す
- [ ] SKILL.md の「AskUserQuestion Fallback」の条件に「別リポジトリへの deferred の issue URL」を 1 項足す。あわせて、質問 0 件で済ませる条件（SKILL.md:64 付近の「全件 recurrence or high-confidence なら質問 0 件」と、reference.md の「Question 0 件の条件」）に「別リポジトリへの deferred が無い」を足す。高確信で別リポジトリへ deferred にしたときに、URL の確認を飛ばさないため。SKILL.md は 99 行で、TC-02 は 100 行未満を求めるので、同じ節の中で行を減らす（既存の文意は変えない）
- [ ] 「編集してよいのは Codify Decisions への追記…だけ」の制約は変えない（URL は Codify Decisions に書くので、制約の範囲内）

C. テスト（下の Test List）

D. `CHANGELOG.md` の `[Unreleased]` に Fixed を 2 項

### Out of Scope
- pre-red-gate.sh のロジック変更 (Reason: gate は正しく、書く側が形を保証していないのが原因)
- PdM のテンプレートの見出しの形 (Reason: #221 で決める)
- `rules/agent-prompts.md:21` の散文の書き換え (Reason: ほかのフェーズにも掛かる規則なので残す。SYNC-PLAN の分が契約になった旨の追記は DISCOVERED に回す)
- `skills/red/SKILL.md:24-30` に残る古い range scan の説明 (Reason: gate はエントリ単位の scan に変わっている。DISCOVERED に回す)
- codify-insight の再発の数え上げ範囲（直近 10 件）の変更
- 導入先の rules・cycle の修正 (Reason: 導入先のセッションで行う)

### Files to Change (target: 10 or less)

| # | File | 変更 |
|---|------|------|
| 1 | agents/sync-plan.md | PHASE_NAME に SYNC-PLAN、Step 4 に完了エントリの code block |
| 2 | skills/orchestrate/steps-subagent.md | Phase Summary のテンプレート末尾に `- Phase completed` |
| 3 | skills/orchestrate/steps-teams.md | 同上 |
| 4 | skills/codify-insight/reference.md | 「別リポジトリへの deferred」節、Annotation Format の例 |
| 5 | skills/codify-insight/SKILL.md | Fallback の条件に 1 項（行数は 99 以下を保つ） |
| 6 | tests/test-pre-red-gate.sh | TC-R16(a-d) |
| 7 | tests/test-sync-plan-progress-log.sh | TC-06 |
| 8 | tests/test-codify-insight.sh | TC-28 |
| 9 | CHANGELOG.md | [Unreleased] Fixed 2 項 |

## Environment

### Scope
- Layer: Backend (bash gate / 契約テスト、Markdown の agent / skill 定義)
- Plugin: bash / Markdown
- Risk: 約 20 (PASS)。gate のロジックは変えない。定義の文面と、その文面を gate に通すテストだけを変える

### Runtime
- Language: bash（`.claude/dev-crew.json` 2.20.1 = installed 2.20.1、version gate 一致）
- リリース: 承認後の cycle で commit まで。2.21.0 のタグは cycle の後に release-skill で行う

### Dependencies (key packages)
- なし（既存 helper `make_fixture_plan` を使用）

### Risk Interview (BLOCK only)
- (none: Risk PASS)

## Context & Dependencies

### Reference Documents
- scripts/gates/pre-red-gate.sh:130-141 - `###` エントリ 1 つに「SYNC-PLAN（または sync-plan）」と「Phase completed」の両方を求める
- agents/sync-plan.md:185 - 対象 PHASE_NAME に SYNC-PLAN が無い。Step 4（:114-119）は結果 JSON を返すだけ
- skills/orchestrate/steps-subagent.md:96 / steps-teams.md:87 - Phase Summary のテンプレートに `Phase completed` の行が無い。steps-codex.md:33 は Block 1 をこの 2 つに任せている
- skills/codify-insight/SKILL.md:5 - `allowed-tools: Read, Edit, AskUserQuestion, Glob`（Bash を持たないので自分では起票できない）
- rules/agent-prompts.md:21 - 前回の直し先（散文。契約テストにはなっておらず再発した）
- CONSTITUTION 原則 6「決定論的プロセス保証」: gate は既にある。今回は gate が読む形を、書く側の定義とテストで保証する
- 方針「手順は緩め、前後は固める」: SYNC-PLAN の完了は RED の前の「前」に当たる。散文の rule で 3 回止まらなかったので、2-strike rule（plan-discipline）に従って契約にする
- 修正提案には実害の証拠: dev-crew 自身で 3 回、導入先で 2 回

### Dependent Features
- pre-red-gate: scripts/gates/pre-red-gate.sh（変更しない）
- Rule Tier Contract: skills/codify-insight（`.claude-plugin/plugin.json` の `name` 判定）

### Related Issues/PRs
- Issue #285: SYNC-PLAN の完了記録の保証（公開面には導入先の名前を出さない）
- Issue #221: 出口での検出（PdM テンプレートの見出しの形はここで決める）

## Recall

`bash scripts/recall-candidates.sh . agents/sync-plan.md skills/orchestrate/steps-subagent.md skills/orchestrate/steps-teams.md skills/codify-insight/SKILL.md skills/codify-insight/reference.md tests/test-pre-red-gate.sh tests/test-sync-plan-progress-log.sh tests/test-codify-insight.sh` の上位:

- docs/cycles/20260421_1809_sync-plan-progress-log-format.md（1.17）: Progress Log の見出しの形を定めた cycle。Insight 3「case-insensitive の部分一致で skill 名と phase 名を混同する」→ TC-06 は連続した句で検査する。Insight 1「agent の scope drift」→ sync-plan に書かせる内容は code block 1 つに限る
- docs/cycles/20260717_1126_approval-reorder.md（0.40）: Plan Review (pre-approval) の strict 契約と hash。TC-R16 の fixture はこの契約を満たす形で作る（`make_fixture_plan` を使う）。#4 が今回の散文の rule の出典
- docs/cycles/20260716_1328_doc-drift-fix.md（0.40）: negative sweep は新文言でも oracle 実測 → TC-06 の句が Step 4 の block で偽 PASS しないことを RED 前に確かめる
- docs/cycles/20261015_1750_codify-auto-run-stop.md（0.35）: codify-insight の編集範囲の制限。B はこの範囲（Codify Decisions への追記）の中に収める

## Test List

既存の helper を使う: `make_fixture_plan`（test-pre-red-gate.sh。plan と正準 hash を作る）。doc 内の code block の取り出しは「見出し区間を先に切り出し、その中の fenced block を読む」二段にする（test-patterns の推奨。別の節の decoy を拾わないため）。区間の切り出しは固定文字列の前方一致（awk の `index()`）で行う。

pre-red-gate の fixture はどれも、frontmatter（`phase: RED`、`plan_file`）と、テンプレートどおりの KICKOFF、正しい `Plan Review (pre-approval)` を持つ。違いは足すエントリだけ。

### DONE
RED 完了 (2026-10-27 17:55)。TC-R16(a-d) / TC-06 / TC-28(a-e) のテストを書いた。(a) は PASS (対照)、残りは FAIL。GREEN 待ち。
- [x] TC-R16(a) 対照: Given KICKOFF + Plan Review だけの Cycle doc、When pre-red-gate を実行、Then rc=1 で出力に `sync-plan not completed`（a〜c の PASS が、足したエントリによるものだと保証する）
- [x] TC-R16(b) エージェントの経路: Given `agents/sync-plan.md` の `### Step 4` 区間から、`### <ts> - SYNC-PLAN` で始まる fenced block を取り出し、`<ts>` を時刻に置き換えて (a) に足した Cycle doc、When pre-red-gate、Then rc=0。block が見つからなければ FAIL（setup error と明示）
- [x] TC-R16(c) PdM の経路（subagent）: Given `steps-subagent.md` の `### Phase Summary 永続化 (sync-plan→RED)` 区間の fenced block を、プレースホルダのまま (a) に足した Cycle doc、When pre-red-gate、Then rc=0
- [x] TC-R16(d) PdM の経路（teams）: (c) と同じ手順で `steps-teams.md` から取り出す、Then rc=0
- [x] TC-06（test-sync-plan-progress-log.sh）: Given `agents/sync-plan.md` の `**対象 PHASE_NAME**:` の行、Then `SYNC-PLAN` を語として含む（`KICKOFF / SYNC-PLAN /` の連続した句で検査し、Step 4 の block の語では通らないようにする）
- [x] TC-28（test-codify-insight.sh）: 契約ごとに、該当区間に限って連続した句で検査する（区間の外の同じ語では通らない）
  - (a) 対象の判定: reference.md の「別リポジトリへの deferred」節に、`deferred` と `plugin.json` の `name` による判定の句がある
  - (b) URL と未起票の使い分け: 同じ節に、条件と記録値が 1 行に並んだ句が 2 つある。「URL が答えられたら `- **Upstream issue**: <issue URL>`」と「答えが無い、または起票しないなら `- **Upstream issue**: 未起票`」。条件の部分と記録値の部分を同じ行で検査する（片方を消すか、入れ替えると FAIL）
  - (c) batch の制約: 同じ節に「1 cycle につき 1 回の batch」に含める句がある
  - (d) Annotation Format: reference.md の `## Annotation Format` 区間の fenced block に `**Upstream issue**` の行がある
  - (e) 質問の条件: SKILL.md の `### AskUserQuestion Fallback` 区間に issue URL の項があり、SKILL.md の質問 0 件の条件の文と reference.md の `### Question 0 件の条件` 区間の両方に「別リポジトリへの deferred が無い」という否定まで含む句がある（「ある」に逆転すると FAIL）
  - TC-02（SKILL.md 100 行未満）は引き続き通る

RED で落ちることを確かめるもの: (b)(c)(d)、TC-06、TC-28。(a) は今の main でも通る（対照）。RED の時点で (c)(d) が rc=1 になることが、今回の不具合の再現になる。

検出力の確認（GREEN の後、変異で 1 回ずつ）:
- sync-plan.md の block から `- Phase completed` を消す → (b) が FAIL
- steps-subagent.md のテンプレートの `- Phase completed` を消す → (c) が FAIL（teams も同様に (d)）
- reference.md の対象判定の句、Annotation Format の `Upstream issue` の行、質問 0 件の条件の句を 1 つずつ消す → TC-28 の (a)(d)(e) がそれぞれ FAIL
- (b) の 2 つの句から条件の部分を消す、または URL と未起票を入れ替える → (b) が FAIL。(e) の「無い」を「ある」に変える → (e) が FAIL
- 確かめたら元に戻す。変異はリポジトリの外の複製で行う

### TODO
(none: 上の WIP へ移動)

### DISCOVERED
- PdM の Phase Summary の見出し（`### Phase: SYNC-PLAN - Completed at`）と、エージェントの `### <ts> - SYNC-PLAN` の形の不一致。#221（出口での検出）で決める（architect 17:51 の観察）→ 新しく起票しない。#221 にコメント済み
- `rules/agent-prompts.md:21` に、SYNC-PLAN の分が定義とテストで契約になった旨を追記する（architect 17:51 の観察）→ issue #286
- `skills/red/SKILL.md:24-30` に、gate が使わなくなった range scan（`awk '/SYNC.PLAN|sync-plan/,/Phase completed/'`）の説明が残っている（architect 17:51 の観察）→ issue #286

### WIP
(none: 上の DONE へ移動)

## Implementation Notes

### Goal
SYNC-PLAN の完了記録（1 つの `###` エントリ内に `SYNC-PLAN` と `Phase completed`）を、書く役（sync-plan エージェントと PdM のテンプレート）の定義とテストで保証する。あわせて、別リポジトリへの deferred の issue URL を codify-insight が記録する手順を足す。

### Background
pre-red-gate は、`###` で始まる 1 つのエントリに「SYNC-PLAN（または sync-plan）」と「Phase completed」の両方を求める（`scripts/gates/pre-red-gate.sh:130-141`）。この記録を書く役は 2 つあるが、どちらの定義もこの形を保証していない（main 282b38a で確認）。

- sync-plan エージェント: `agents/sync-plan.md:185` の「対象 PHASE_NAME」は `KICKOFF / RED / GREEN / REFACTOR / REVIEW / COMMIT / DONE` で、SYNC-PLAN が無い。Step 4（`:114-119`）は「結果 JSON を返す」だけ。sync-plan が必ず書く 2 つのエントリは、どちらも単独では条件を満たさない。KICKOFF（テンプレート `skills/spec/templates/cycle.md` の `- Cycle doc created / - Scope definition ready`）は、どちらの語も含まない。`Plan Review (pre-approval)` は `Phase completed` を含むが、sync-plan の語を含まない
- PdM: `skills/orchestrate/steps-subagent.md:96` と `steps-teams.md:87` の Phase Summary のテンプレート（`### Phase: SYNC-PLAN - Completed at HH:MM`）に `Phase completed` の行が無い。`steps-codex.md:33` は Block 1 をこの 2 つに任せている

再現: KICKOFF と Plan Review の転記に PdM のテンプレートを足すと rc=1 `BLOCK: sync-plan not completed`。テンプレートに `- Phase completed` を 1 行足すと rc=0。エージェントが `### <ts> - SYNC-PLAN` + `- Phase completed` を書けば、テンプレートが元のままでも rc=0。

実害の記録:
- dev-crew 自身で 3 回。`docs/cycles/20260707_0936_codified-rules-batch-impl.md`（PdM が 09:52 に補記）、`docs/cycles/20260717_1126_approval-reorder.md` #4（rule 化）、`docs/cycles/20260903_1130_severity-verdict.md:259-261`（architect が「3 回目」と記録。sync-plan を再実行して 11:41 の SYNC-PLAN エントリで通過）
- 導入先でも少なくとも 2 回（issue #285。公開面には導入先の名前を出さない）
- 前回の直し先は `rules/agent-prompts.md:21` の散文（「委譲 prompt に書け」「2-strike で自動契約化」）。契約テストにはなっておらず、その後も再発した

あわせて扱う B: 導入先で codify-insight が「dev-crew 本体で直すべき」と deferred にした Insight が、dev-crew の issue にならずに途切れた（2 回）。codify-insight は Bash を持たない（`skills/codify-insight/SKILL.md:5` `allowed-tools: Read, Edit, AskUserQuestion, Glob`）ので、自分では起票できない。再発の数え上げは直近 10 件だけを見るので、間が開くと拾えない。

### Design Approach
- gate のロジックは変えない。書く側（agents/sync-plan.md、orchestrate の Phase Summary テンプレート）が gate の読む形を出すよう定義を直し、その定義の文面を実際に pre-red-gate に通す契約テスト（TC-R16）で保証する
- 2-strike rule（plan-discipline）に従い、散文の rule から契約テストへ移す
- codify-insight は Bash を持たないため、起票はせず Upstream issue の URL（または未起票）を Codify Decisions に記録する。AskUserQuestion は既存の 1 cycle 1 回の batch に含める
- SKILL.md は 99 行で TC-02 が 100 行未満を要求するので、同じ節の中で行を減らして収める
- code block の取り出しは「見出し区間を先に切り出し、その中の fenced block を読む」二段。区間の切り出しは awk の `index()` による固定文字列の前方一致

## Verification

**Real-path invocation を最低 1 件含めること** (rules/integration-verification.md)。

```bash
bash run-tests.sh tests/test-pre-red-gate.sh
bash run-tests.sh tests/test-sync-plan-progress-log.sh
bash run-tests.sh tests/test-codify-insight.sh
# 全件（baseline は 2026-10-21 main 282b38a で 121/121。テストファイルは増やさないので 121 のまま）
bash run-tests.sh
```

- 上の「検出力の確認」の変異で検出力を確かめる（リポジトリの外の複製で行い、確かめたら元に戻す）
- REVIEW は敵対的レビュー 1 回 + 振り分け（v2.20.1 の手順）

Evidence: (orchestrate が自動記入)

## Progress Log

Format for each phase entry (**strict, required by pre-commit-gate.sh**):

```
### YYYY-MM-DD HH:MM - PHASE_NAME
- [completed action]
- Phase completed
```

### 2026-10-27 17:50 - KICKOFF
- Cycle doc created
- Scope definition ready

### 2026-10-27 17:50 - Plan Review (pre-approval)
- codex_session_id: 01a17c4c-0140-75e2-ba23-c95b865c934d
- review_attempts:
  - {started: 2026-10-27 16:38, completed: 2026-10-27 16:42, verdict: WARN}
  - {started: 2026-10-27 16:43, completed: 2026-10-27 16:44, verdict: WARN}
- findings 要約: 1 回目 P2×2・P3×1（質問 0 件の条件が URL の確認を飛ばせる / TC-28 が契約の欠落を検出できない / Step 4 の行番号のずれ）。2 回目 P2×1（TC-28(b)(e) が条件の欠落・逆転を検出できない）。すべて反映した。3 回目のレビューはしない（Step 8 の規定）
- unresolved_blocks: なし
- plan_presented: 2026-10-27 16:46
- reviewed_plan_hash: ccd1c379b5d0c90ee6729a23505eacb3526a33197e51e8f4a014d0998f111e5a
- verdict: WARN
- Phase completed

### 2026-10-27 17:50 - SYNC-PLAN
- Cycle doc generated from plan (Test List 6 items, Plan Review Record transferred)
- Phase completed

### 2026-10-27 17:51 - ARCHITECT
- Post-Transfer Verification: Plan Review Record 6 フィールド（codex_session_id / review_attempts / reviewed_plan_hash / plan_presented / unresolved_blocks / verdict）は plan と一致。In Scope / Out of Scope / Files to Change(9) / Test List(6) も欠落・逸脱なし
- 実ファイル突合: sync-plan.md PHASE_NAME 行に SYNC-PLAN 無し、Step 4 は結果 JSON のみ、steps-subagent/teams のテンプレートに Phase completed 無し、pre-red-gate.sh のエントリ単位 scan（SYNC.PLAN|sync-plan と Phase completed）を確認。SKILL.md 99 行、採番（TC-R16 / TC-06 / TC-28）は既存と衝突しない
- real-path: `bash scripts/gates/pre-red-gate.sh <cycle_doc>` rc=0 PASS
- 観察のみ（DISCOVERED 候補）: (1) 見出し形 `### Phase: SYNC-PLAN` と `### <ts> - SYNC-PLAN` の不一致は #221 で決定 (2) agent-prompts.md:21 に SYNC-PLAN が契約化された旨の追記 (3) skills/red/SKILL.md:24-30 の古い range scan 説明
- verdict: PASS（転記欠落なし、scope 変更なし）
- Phase completed

### 2026-10-27 17:55 - RED
- Test code created, 9 tests failing (test-pre-red-gate.sh: TC-R16(b)(c)(d) の 3 件 FAIL、(a) 対照は PASS / test-sync-plan-progress-log.sh: TC-06 の 1 件 FAIL / test-codify-insight.sh: TC-28(a)(b)(c)(d)(e) の 5 件 FAIL)。(c)(d) は rc=1 `BLOCK: sync-plan not completed`（不具合の再現）。(b) は Step 4 に block が無い setup error
- Phase completed

### 2026-10-27 17:58 - GREEN
- Implementation complete, all tests passing（test-pre-red-gate.sh 30 PASS / test-sync-plan-progress-log.sh 6 PASS / test-codify-insight.sh 31 PASS。逆向き契約として tests/ 内で agents/sync-plan・steps-subagent・steps-teams・codify-insight・CHANGELOG を参照する 45 本も rc=0。SKILL.md は 99 行）
- Phase completed

### 2026-10-27 18:01 - GREEN Gate 2 (PdM)
- 全件 `bash run-tests.sh`: PASS 121 / FAIL 0 / TOTAL 121
- 検出力（リポジトリの外の複製で変異を 1 つずつ）: 12/12 検出。sync-plan.md の block の marker 削除 → TC-R16(b)、steps-subagent / steps-teams の marker 削除 → (c)(d)、PHASE_NAME から SYNC-PLAN 削除 → TC-06、reference.md の判定の句 → TC-28(a)、URL の条件の削除・URL と未起票の入れ替え → (b)、batch の句 → (c)、Annotation の行 → (d)、Question 0 件の条件の行・SKILL.md の「無い」→「ある」・Fallback の項 → (e)
- 変異なしの複製の対照: TC-R16・TC-06・TC-28 は PASS（落ちたのは複製に README.md 等を含めなかった TC-18 だけ）
- Phase completed

### 2026-10-27 18:02 - REFACTOR
- refactor (checklist) + Verification Gate passed。7 項目を確認し、変更なし。TC-28(a)〜(c) の setup error の分岐は、どの TC が落ちたかを出力で区別するために残した。fence を意識した区間切り出しの helper は test-pre-red-gate.sh と test-codify-insight.sh に 1 つずつあるが、テストの間で共有する仕組みがないので統合しない
- Verification Gate: 全件 121/121（18:01）、変更した 3 本は `bash -n` で構文 OK。shellcheck は環境に無い
- Phase completed

### 2026-10-27 18:13 - REVIEW
- Codex review: 直す 1 / 人間に戻す 0 / 記録のみ 0
- 指摘: P2「TC-28 の `printf | grep -qF` が pipefail の下で、約 100KB の区間だと SIGPIPE で偽 FAIL する」（Codex が再現）。場所は今回の diff で足した行で、test-patterns の禁止事項に当たる。修正役（green-worker）が、今回足した同じ形の 8 か所（TC-28 6、TC-R16(a) 1、TC-06 1）を here-string に置き換えた。scratch で旧形の偽 FAIL と新形の PASS を再現
- レビューの前後で作業ツリーは変わっていない（Codex は read-only）。修正役は未追跡ファイルを足していない（前後の一覧が一致）
- 修正後の全件: PASS 121 / FAIL 0 / TOTAL 121（REFACTOR 時と同じ）
- Phase completed

### 2026-10-27 18:15 - COMMIT
- COMMIT 前の判断点の md をユーザーが確認し、OK（人間に戻す 0 件）。pre-commit-gate PASS。STATUS.md の Completed と NEXT.md の #271 の記述を更新。README / AGENTS / CLAUDE は skill・agent の一覧が変わらないので更新しない
- Phase completed

---

## Next Steps

1. [Done] KICKOFF
2. [Done] SYNC-PLAN
3. [Next] RED <- Current
4. [ ] GREEN
5. [ ] REFACTOR
6. [ ] REVIEW
7. [ ] COMMIT
8. [ ] DONE

## Retrospective

### Insight 1

- **Failure**: SYNC-PLAN の完了記録の欠落は、2026-07-17 に `rules/agent-prompts.md` へ「委譲 prompt に書け。2-strike で自動契約化」と書いて codify した。しかし契約テストにはならず、その後も dev-crew で 1 回（20260903_1130 で「3 回目」）、導入先で 2 回再発した。rule の文面は、prompt を書く者が思い出すかどうかに頼っていた
- **Final fix**: 書く役の定義（agents/sync-plan.md の Step 4、PdM のテンプレート 2 つ）に完了エントリの形を置き、その code block を doc から取り出して実際に pre-red-gate に通すテスト（TC-R16）で固定した。変異 12 件で検出力を確かめた
- **Insight**: gate が読む形を codify するときは、rule の散文ではなく、書く役の定義にその形を置き、定義の文面を gate に通すテストで固定する。rule に「自動契約化」と書いても、テストが無ければ契約ではない

### Insight 2

- **Failure**: RED の委譲 prompt に「`cmd | grep -q` を pipefail 下で使わない」と書き、test-patterns にも禁止事項としてあった。それでも red-worker は TC-28・TC-R16(a)・TC-06 に `printf | grep -qF` を 8 か所書いた。小さい入力ではテストが通るので、GREEN と REFACTOR では気付かず、REVIEW の Codex が約 100KB の入力で偽 FAIL を再現した
- **Final fix**: 修正役が here-string（`grep -qF -- 'pattern' <<< "$VAR"`）に置き換えた
- **Insight**: prompt と rule の両方に書いても守られない禁止形は、機械的に見つけられる形（`| grep -q` と `set -o pipefail` が同じファイルにある）なので、RED の後に PdM が diff を grep して確かめる。文面をこれ以上足しても防げない

### 想起漏れ

- **設問**: 今回の手戻りは、過去のどの cycle doc を最初に読んでいれば防げたか
- **回答**: 該当なし
