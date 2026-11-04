---
feature: pre-approve-gate
cycle: 20261104_1025
phase: DONE
complexity: standard
test_count: 14
risk_level: low
retro_status: captured
codex_mode: no
codex_session_id: "01a1a41c-7a3e-7803-b05e-04b90496f935"
plan_file: /Users/morodomi/.claude/plans/cuddly-discovering-donut.md
created: 2026-11-04 13:07
updated: 2026-11-04 15:31
---

# 承認前に Plan Review Record の hash と plan_presented を確かめる gate (#291)

## Scope Definition

### In Scope
- [ ] A. 新規 `scripts/gates/plan-hash.sh <plan>`: 正準アルゴリズム（行全体が `## Plan Review Record` の最初の行より上の内容の sha256）で hash を出す。見出しが無ければ exit 1。hash の計算をここ 1 か所にする
- [ ] B. 新規 `scripts/gates/pre-approve-gate.sh <plan>`: plan ファイルだけを見て、満たさなければ exit 1、満たせば exit 0
  1. 引数のファイルが存在する
  2. 行全体が `## Plan Review Record` の見出しがある（pre-red-gate の (vi) と同じ）
  3. Record 節（その見出しから次の `## ` 見出しまで）に `- reviewed_plan_hash:` があり、64 桁の 16 進数を含む（(iv) と同じ）
  4. その値が `plan-hash.sh` の出力と一致する（(vii) と同じ）
  5. Record 節に `- plan_presented:` があり、値が `YYYY-MM-DD HH:MM` で始まる。空と、テンプレートの `[YYYY-MM-DD HH:MM]` の写しを BLOCK
  - Record 節の外（本文）にある同名の行は読まない
  - SIGPIPE 対策は pre-red-gate と同じ（`producer | grep -q` を使わず、変数に取ってから here-string）
- [ ] C. `pre-red-gate.sh` の (vii) の計算を `plan-hash.sh` の呼び出しに替える。BLOCK の文言と検査の順番は変えない。plan-hash.sh は `$(dirname "$0")` から解決する（cwd に依存しない）
- [ ] D. spec の文面: Step 8 の末尾に「`plan_presented` を記入した後、ExitPlanMode の前に pre-approve-gate を実行し、BLOCK なら直してから承認に進む」を足す
  - 呼び出しパス: 導入先には `scripts/gates/` が無いため、spec skill の Base directory からの相対で `bash "<spec の Base directory>/../../scripts/gates/pre-approve-gate.sh" <plan path>`
  - `skills/spec/SKILL.md` の Step 8 の段落（現在 97 行。行を増やさず既存の段落に足す。100 行未満を守る）
  - `skills/spec/reference.md` と `reference.ja.md` の Step 8「手順」に 7 番目として足す。hash 不一致で BLOCK したときの回復はレビューした版に戻すこと。残す変更は承認提示文に「レビュー後の変更」として差分を示し、人間が承認した場合だけ `plan-hash.sh` の出力で記録し直し、Record の findings 要約に書く。黙って hash だけを記録し直さない
- [ ] E. CHANGELOG の [Unreleased] に追記

### Out of Scope
- ExitPlanMode の PreToolUse フック化 (Reason: issue で「別に決める」とされている)
- pre-red-gate に `plan_presented` の検査を足すこと (Reason: 受け入れ条件に無い。承認前で止まれば足りる)
- verdict・unresolved_blocks・review_attempts の承認前検査 (Reason: issue の対象外)
- `agents/sync-plan.md` に書かれた awk の算出コマンドの置き換え (Reason: 文面の説明で実装ではない)
- 既存 gate の呼び出しが `bash scripts/gates/...` の相対パスで導入先では見つからない問題 (Reason: 元からの欠陥で範囲外。COMMIT 時に issue 起票)

### Files to Change (target: 10 or less)
- scripts/gates/plan-hash.sh (new)
- scripts/gates/pre-approve-gate.sh (new)
- scripts/gates/pre-red-gate.sh (edit: (vii) の計算を plan-hash.sh 呼び出しに)
- tests/test-pre-approve-gate.sh (new)
- skills/spec/SKILL.md (edit: Step 8 の段落に 1 文)
- skills/spec/reference.md (edit: Step 8 手順 7)
- skills/spec/reference.ja.md (edit: Step 8 手順 7)
- CHANGELOG.md (edit: [Unreleased])

逆向き契約の確認: `grep -rn 'pre-red-gate' tests/` の該当は test-pre-red-gate.sh・test-doc-alignment.sh・test-constitution.sh・test-codify-rule-docs.sh。どれも pre-red-gate の存在と文言を見るだけで、hash の計算方法を pin していない。

## Environment

### Scope
- Layer: Backend（shell の gate スクリプト + spec skill の文面）
- Plugin: bash
- Risk: 25 (PASS) — 新しい gate の追加。既存 gate は hash 計算の呼び出し先だけ変える

### Runtime
- Language: bash（macOS / BSD）、`shasum -a 256`、awk、grep
- Baseline（実測 2026-11-04）: `bash tests/test-pre-red-gate.sh` → PASS 30 / FAIL 0

### Dependencies (key packages)
- shasum, awk, grep (OS 標準)

### Risk Interview (BLOCK only)
- (not applicable: Risk PASS)

## Context & Dependencies

### Reference Documents
- scripts/gates/pre-red-gate.sh - (iv)(vi)(vii) の既存検査と SIGPIPE 対策
- skills/spec/reference.md (Step 8) - pre-approval plan review の手順
- skills/onboard/SKILL.md Step 6 - 導入先に配るのは rules と hooks だけ
- .claude/rules/skill-authoring.md - SKILL.md 100 行制約

### Dependent Features
- pre-red-gate: scripts/gates/pre-red-gate.sh

### Related Issues/PRs
- Issue #291: 承認前に Plan Review Record の hash と plan_presented を確かめる gate

## Recall

### docs/cycles/20260717_1126_approval-reorder.md
- **何が起きたか**: Codex plan review を承認前へ移し、Plan Review Record と hash 同一性、pre-red-gate の硬化を入れた
- **当時の前提**: 承認後の pre-red-gate が二次照合すれば足りる
- **今回も同じ前提か**: No。承認後に止まっても plan を直せないことが導入先で 3 回の漏れとして出た。今回はその前段を足す

### docs/cycles/20260716_1328_doc-drift-fix.md
- **何が起きたか**: 文面の drift の修正。TC 番号の次値は実装から測るという教訓
- **当時の前提**: ヘッダの一覧は実装から drift する
- **今回も同じ前提か**: Yes。新しいテストファイルなので採番は TC-01 から

### docs/cycles/20260702_1930_gate-active-cycle-fix.md / 20260324_0003_fix-gate-old-format.md
- **何が起きたか**: gate が対象の Cycle doc を取り違える・古い形式で誤判定する問題の修正
- **当時の前提**: gate は Cycle doc を探して読む
- **今回も同じ前提か**: No。新しい gate は引数の plan だけを読み、探さない

## Test List

`tests/test-pre-approve-gate.sh`（fixture は mktemp の一時ディレクトリに作る）

### TODO

### WIP

### DISCOVERED
- 既存の gate（pre-red-gate・pre-commit-gate・finding-in-diff・worktree-fingerprint）を skill が `bash scripts/gates/...` の相対パスで呼んでいる。導入先には scripts/gates/ が無いので見つからない（plan review attempt 1 で検出した元からの欠陥。Scope の Out に記載済み）→ issue #292

### DONE
- [x] TC-01: Given hash と plan_presented が正しく埋まった plan, When pre-approve-gate, Then exit 0
- [x] TC-02: Given `- reviewed_plan_hash:` の値が空, Then exit 1
- [x] TC-03: Given 記録の後に Record より上の本文を 1 行変えた plan, Then exit 1（mismatch）
- [x] TC-04: Given `- plan_presented:` の値が空, Then exit 1
- [x] TC-05: Given `plan_presented` がテンプレートの `[YYYY-MM-DD HH:MM]` のまま, Then exit 1
- [x] TC-06: Given `plan_presented` の行が無い, Then exit 1
- [x] TC-07: Given `## Plan Review Record` の見出しが無い（本文中に引用としてだけ現れる）, Then exit 1
- [x] TC-08: Given 正しい `reviewed_plan_hash` の行が Record より上の本文にだけあり、Record 節には無い, Then exit 1
- [x] TC-09: Given 存在しないファイル・引数なし, Then exit 1
- [x] TC-10: Given TC-01 の fixture, When plan-hash.sh, Then 出力が `awk '$0=="## Plan Review Record"{exit}{print}' | shasum -a 256` と一致。見出しの無い plan では exit 1
- [x] TC-11: Given spec の SKILL.md・reference.md・reference.ja.md, Then Step 8 の区間に `../../scripts/gates/pre-approve-gate.sh` がある。reference.md・reference.ja.md の Step 8 区間に「黙って hash だけを記録し直さない」旨の文がある
- [x] TC-12: Given Record 節には hash と plan_presented が無く、正しい値の行が後ろの `## Post-Approve Action` 節にだけある plan, Then どちらも exit 1
- [x] TC-13: Given 本文に `"## Plan Review Record"` を引用として含む行が見出しより前にある plan, Then exit 0
- [x] TC-14: Given 別の cwd から絶対パスで gate を呼ぶ, Then exit 0
- [x] 非回帰: `bash tests/test-pre-red-gate.sh` PASS 30 / FAIL 0、`bash run-tests.sh` 123/123 PASS
- [x] TC-R15: tests/test-pre-approve-gate.sh::TC-15 duplicate reviewed_plan_hash lines use the last one（REVIEW で追加）
- [x] TC-R16: tests/test-pre-approve-gate.sh::TC-16 exported CDPATH does not break the relative-path call（REVIEW で追加）

## Implementation Notes

### Goal
導入先で `reviewed_plan_hash` と `plan_presented` が埋まらないまま ExitPlanMode に進んだ漏れ（3 回）を、承認の前（spec Step 8 末尾、ExitPlanMode の直前）で止める。

### Background
`scripts/gates/pre-red-gate.sh` は hash の欠落 (iv)・見出しの欠落 (vi)・不一致 (vii) を BLOCK するが、走るのは承認の後（RED の前）で、その時点では plan を直せない。`plan_presented` は pre-red-gate の検査対象外（`grep -n plan_presented scripts/gates/pre-red-gate.sh` は 0 件、実測）。同じ確認を承認前で走らせ、漏れをその場で直せるようにする。

### Design Approach
- hash の計算を `plan-hash.sh` の 1 か所にし、pre-approve-gate と pre-red-gate の両方がそれを呼ぶ
- pre-approve-gate は plan だけを読む（Cycle doc を探さない）。Record 節を `## ` 見出しで切り出して検査し、本文の同名行は読まない
- 導入先には scripts/gates/ が無いため、spec の Base directory からの相対パスで呼ぶ

## Verification

**Real-path invocation を最低 1 件含めること** (rules/integration-verification.md)。

1. `bash tests/test-pre-approve-gate.sh` 全件 PASS
2. 修正前の実装で TC が FAIL することを確かめる（変異: plan_presented の形の検査を外す、Record 節の切り出しを外す、hash の比較を外す → それぞれ対応する TC が FAIL）
3. `bash tests/test-pre-red-gate.sh` PASS 30
4. `bash run-tests.sh` 全件 PASS
5. この plan ファイル自身に対して pre-approve-gate を流し、exit 0 を確かめる（dogfood、real-path invocation）

Evidence: (orchestrate が自動記入)

## Progress Log

### 2026-11-04 13:07 - KICKOFF
- Cycle doc created
- Scope definition ready
- Phase completed

### 2026-11-04 13:07 - Plan Review (pre-approval)
- codex_session_id: 01a1a41c-7a3e-7803-b05e-04b90496f935
- review_attempts:
  - {started: 10:11, completed: 10:18, verdict: BLOCK}
  - {started: 10:19, completed: 10:20, verdict: WARN}
- findings 要約: attempt 1（BLOCK 2・WARN 2）: hash を記録し直すだけでレビューしていない変更が通る / 導入先に scripts/gates が無く相対パスでは呼べない（既存 gate にも同じ欠陥があり範囲外として起票予定）/ Record 節の後ろの節の値を読まないことのテストが無い / 部分一致の見出しで hash がずれる既知の失敗のテストが無い → 全て反映（TC-12〜14 追加、呼び出しを spec の Base directory からの相対に）。attempt 2（WARN 1）: hash 不一致からの回復で再レビューすると「再レビューは 1 回まで」と矛盾 → 回復はレビューした版に戻すこと、残す変更は承認提示文で人間に示すことに変更
- unresolved_blocks: なし
- plan_presented: 2026-11-04 10:21
- reviewed_plan_hash: d06b33428bfd504830ff41c4c1f1d66c8bc77485b2842f51c019b65b79de710c
- verdict: WARN（attempt 2 の WARN 1 件は反映済み。予算により再々レビューはしない）
- override: (空)
- hash 一次照合: plan の実 hash を正準アルゴリズムで再計算し、Record 記載値と一致を確認
- Phase completed

### 2026-11-04 13:07 - SYNC-PLAN
- Cycle doc generated from plan (Test List 14 items + 非回帰, Plan Review Record transferred)
- Phase completed

### Phase: SYNC-PLAN - Completed at 13:08
**Artifacts**: Cycle doc updated with PLAN section, Test List (14 items + 非回帰)
**Decisions**: architecture=plan-hash.sh に正準 hash を集約し pre-approve-gate.sh / pre-red-gate.sh が共有、test strategy=mktemp fixture の plan に対する exit code 検査 + spec 文面の区間 grep
**Pre-Review**: verdict=PASS, issues=なし（architect Post-Transfer Verification: 転記欠落なし・scope 変更なし・観察なし。pre-red-gate rc=0 を実測）
**Next Phase Input**: Test List items TC-01 ~ TC-14
**Subagent**: architect (Post-Transfer Verification)
- Phase completed

### 2026-11-04 13:09 - RED
- Created tests/test-pre-approve-gate.sh (TC-01 ~ TC-14, 21 assertions)
- bash -n OK. 実行結果: PASS 0 / FAIL 21（plan-hash.sh・pre-approve-gate.sh 未作成による rc=127、TC-11 は spec 文面未更新）。RED 状態を確認
- Phase completed

### 2026-11-04 13:11 - GREEN
- 変更: scripts/gates/plan-hash.sh (new), scripts/gates/pre-approve-gate.sh (new), scripts/gates/pre-red-gate.sh ((vii) を plan-hash.sh 呼び出しに), skills/spec/SKILL.md (Step 8 に 1 文), skills/spec/reference.md・reference.ja.md (手順 7 + 正準 hash 節に 1 文), CHANGELOG.md ([Unreleased] Added)
- 実測: tests/test-pre-approve-gate.sh PASS 21 / FAIL 0、tests/test-pre-red-gate.sh PASS 30 / FAIL 0、wc -l skills/spec/SKILL.md = 97、dogfood `bash scripts/gates/pre-approve-gate.sh <plan>` rc=0
- run-tests.sh 全体は未実行（PdM が実行）
- Phase completed

### 2026-11-04 13:14 - REFACTOR
- PdM 実測: `bash run-tests.sh` PASS 123 / FAIL 0 / TOTAL 123（新規 test-pre-approve-gate.sh を含む）
- 変異 6/6 検出（コピー上で実施）: plan_presented の形の検査を外す→TC-05 / Record 節の終端を外す→TC-12 ×2 / hash 比較を外す→TC-03 / plan-hash を部分一致で切る→TC-13 / hash を本文全体から読む→TC-12 / reference.ja.md の呼び出しを相対パスに戻す→TC-11
- チェックリスト 7 項目: 変更なし。見出しの存在確認が plan-hash.sh と pre-approve-gate.sh の両方にあるが、gate は自分の BLOCK 理由を出すために持つので残す
- 静的解析: shellcheck はこの環境に無い。`bash -n` は 4 本とも rc=0
- Phase completed

### 2026-11-04 13:22 - VERIFY
- 実経路: `bash scripts/gates/pre-approve-gate.sh <plan>` rc=0、`/tmp` から `skills/spec/../../scripts/gates/pre-approve-gate.sh` の絶対パスで rc=0、`pre-red-gate.sh <cycle doc>` rc=0。Evidence: /tmp/dev-crew-verify-20261104_1025/verify.txt
- Phase completed

### 2026-11-04 13:22 - REVIEW
- Codex review: 失敗（使用量の上限、15:05 まで不可）。adversarial-reviewer で代行: 直す 2 / 人間に戻す 0 / 記録のみ 2
- worktree fingerprint 前後一致（b8c738c1…def378）。finding-in-diff: P2 の場所 4 件とも 0（diff の中）
- 直す: P2-1 Record に hash 行が 2 本あると承認前と承認後で判定が分かれる → pre-approve-gate も最後の行を取る（pre-red-gate (iv) と同じ）。P2-2 CDPATH を export した環境で plan-hash.sh を見つけられない（pre-red-gate の退行）→ 両 gate の cd を `CDPATH= cd` に
- 記録のみ: P3-1 plan_presented は `9999-99-99 99:99` を通す（受け入れ条件の文言どおり）/ P3-2 hash 値の前後の文字を許す（pre-red-gate (iv) と同じ規則）
- 修正後: `bash run-tests.sh` PASS 123 / FAIL 0（REFACTOR 時と同じ、落ちたもの無し）。test-pre-approve-gate.sh PASS 25、test-pre-red-gate.sh PASS 30。未追跡ファイルは修正前と同じ
- Phase completed

### Phase: REVIEW - Completed at 13:22
**Artifacts**: adversarial review results (/tmp/dev-crew-review-20261104_1025/review.md: the adversarial-reviewer reply written by PdM)
**Decisions**: 直す=2, 人間に戻す=0, 記録のみ=2
**Next Phase Input**: all tests passing, ready to commit
**Subagent**: adversarial-reviewer (opus) + green-worker (fixer)

### 2026-11-04 15:31 - COMMIT
- pre-commit-gate PASS。STATUS.md に完了を追記。skills/agents 一覧の変更は無いので README/AGENTS/CLAUDE は更新なし
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

- **Failure**: 最初の plan は、新しい gate を既存の gate と同じ `bash scripts/gates/pre-approve-gate.sh` の相対パスで呼ぶと書いていた。承認前の Codex plan review が、導入先には scripts/gates/ が無い（onboard が配るのは rules と hooks だけ）と BLOCK した。既存の gate の呼び出しも同じ書き方だった（#292）
- **Final fix**: spec skill の起動時に表示される Base directory からの相対（`<spec の Base directory>/../../scripts/gates/pre-approve-gate.sh`）で呼ぶ形にし、TC-11 で 3 つの文書の Step 8 区間に固定した
- **Insight**: skill から本体のスクリプトを呼ぶ手順を書くときは、既存の呼び出しの書き方を写さず、導入先の repo にそのパスがあるかを onboard が配るものから確かめる。本体の作業ツリーで動くことは、導入先で動くことの証拠にならない

### Insight 2

- **Failure**: plan は「pre-red-gate の (iv) と同じ」と書いたが、GREEN の実装は hash 行を `grep -m1`（最初の行）と大文字を含む hex で取り、pre-red-gate は `tail -1`（最後の行）と小文字の hex で取っていた。Record に hash 行が 2 本ある plan で、承認前は PASS、承認後は BLOCK になった（REVIEW P2-1、adversarial-reviewer が再現）
- **Final fix**: 修正役が pre-approve-gate も最後の行を取る形に揃え、TC-15 で 2 通りの並びを固定した
- **Insight**: 「既存の gate X と同じ検査」を新しい gate に書くときは、行の選び方（最初か最後か）・文字の種類・空白の扱いまで X のコードから写し、同じ入力を両方の gate に流して答えが一致するかをテストにする。文面で「同じ」と書いても、選び方が違えば食い違う

### Insight 3

- **Failure**: pre-red-gate の hash の計算を、同じディレクトリの plan-hash.sh の呼び出しに替えたとき、パスを `$(cd "$(dirname "$0")" && pwd)` で解決した。CDPATH を export した環境では cd がパスを stdout にも出してパスが 2 行になり、修正前は PASS していた pre-red-gate が BLOCK した（REVIEW P2-2、退行）
- **Final fix**: 両 gate の cd を `CDPATH= cd` にし、TC-16 で CDPATH を付けた呼び出しを固定した
- **Insight**: 計算をその場の awk から別のスクリプトの呼び出しに替えると、パスの解決という新しい入力が増える。シェルの環境変数（CDPATH など）がその解決を変えるので、入力として扱って外す。git の出力を読む gate で環境変数を外した教訓と同じ形

### 想起漏れ

- **設問**: 今回の手戻りは、過去のどの cycle doc を最初に読んでいれば防げたか
- **回答**: docs/cycles/20261028_1047_review-fixer-location-check.md
