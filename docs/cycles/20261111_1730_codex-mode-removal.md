---
feature: codex-mode-removal
cycle: 20261111_1730
phase: DONE
complexity: complex
test_count: 16
risk_level: medium
retro_status: captured
codex_mode: no
codex_session_id: "01a1c9aa-78d6-7a53-a656-dd016260c5c0"
plan_file: /Users/morodomi/.claude/plans/sparkling-dreaming-bengio.md
created: 2026-11-11 17:29
updated: 2026-11-11 23:09
---

# codex_mode の full（RED/GREEN の Codex 委譲）の経路を消す（#297）

## Scope Definition

### In Scope

- [ ] 1. `skills/orchestrate/steps-codex.md` を削除する
- [ ] 2. orchestrate の文書
  - SKILL.md: Block 1 の手順 4（codex_mode / 委譲モード）、Block 2 のモード一覧、`## Mode Selection` 節。行数は 98 から減る
  - reference.md: `## TDD Gate` の委譲モード表と Gate 1/2 のスキップ、Test Plan 凍結の Codex の記述。`## Session Management` は「`codex_session_id` は承認前の plan review のセッション（spec Step 8 の再レビューで使う）。orchestrate は Codex を resume しない。REVIEW は毎回新しいセッションで、ID を保存しない」に縮め、状態別動作の表と `resume --last` のフォールバックの説明を消す
  - steps-subagent.md・steps-teams.md: 冒頭の「Codex利用可能時は steps-codex.md が優先される」を消す。REVIEW 節の「steps-codex.md の REVIEW は resume しない唯一の例外」「（codex_mode に関わらない）」を「新しいセッションで実行し、resume しない」に言い換える。修正の段の「Codex への起動文字列と Task の prompt の両方」を「Task の prompt」にする（steps-subagent.md:203、steps-teams.md:248）
  - adversarial-review.md:3 の steps-codex へのリンク
- [ ] 3. 他の skill
  - spec の reference.md・reference.ja.md: Post-Approve の委譲確認（:567 / :509）、plan テンプレートの Post-Approve Action の 1 行、:23 の「degraded 経路（RED 以降は `resume --last`）」を「Step 8 の再レビューは `resume --last`」にする
  - red・green の reference.md: `## Codex Delegation` 節、steps-codex へのリンク、green の gotcha G-05
  - review の SKILL.md:49、reference.md:273,290、steps-subagent.md:5（Codex のレビューは orchestrate の REVIEW 節と adversarial-review.md を指す）
  - onboard の reference.md:501-507 の Codex Integration テンプレートを read-only にする（`codex exec --sandbox read-only "<prompt>" < /dev/null` と `codex exec --sandbox read-only resume <session-id> "<prompt>" < /dev/null`）。:514 の「RED/GREEN 実装委譲は … read-only ではない」の括弧を消す
- [ ] 4. 上位の文書: CLAUDE.md の Codex Integration（:14 の codex_mode の文、:22-25 の RED/GREEN 委譲のコマンド例）、CONSTITUTION §4 原則 3・4、新しい ADR `docs/decisions/adr-codex-review-only.md`（TEMPLATE.md の形）、README.md（:31 の役割表、:78 の手順）、docs/workflow.md（:19 の委譲確認、:28・:33 の「(Codex: full時)」）、docs/skill-map.md の red/green 行
- [ ] 5. テスト（Explore で 19 本を仕分け済み + plan review で 2 本追加。A=消す 約 30 / B=向け直し 約 18 / C=一覧から外す 約 20 / D=反転か削除 約 14）
  - 丸ごと消す: test-orchestrate-codex.sh、test-codex-session-unify.sh、test-steps-codex-improvements.sh。残す契約は新しいテストへ移す:
    - unify TC-08（`--full-auto` 不在と、呼び出しごとの `< /dev/null`。対象は CLAUDE.md・AGENTS.md・rules/・.claude/rules/・agents/・skills/、継続行を連結してから 1 呼び出しずつ判定）
    - orchestrate-codex TC-08 の REVIEW の出力先（各 REVIEW の Codex コマンドが `-o "/tmp/dev-crew-review-<cycle_id>/review.md"` を持つ）
    - improvements T-01/T-02（対象の列挙と「再レビューしない」）
  - 他のテストを名前で実行している TC（delegation-preference TC-11、session-isolation TC-12/13、v201 TC-10）から、消すファイルを外す
  - test-review-plan-gate.sh:206 は steps-codex.md が無いと `exit 1` でファイルごと落ちるので外す
  - test-product-verify.sh TC-10 の件数 `-ge 4` を 3 に。test-rules-path-scoping.sh の「nine/three」の件数も直す
  - 「advisory」を見る TC（advisory-terminology TC-01、delegation-interface TC-09）は teams だけに向け直す（subagent には「advisory」がある）
  - test-adversarial-review.sh TC-09e の「唯一の例外」の検査を、「新しいセッション」と「resume しない」の検査に変える
  - test-onboard-tdd-workflow-template.sh TC-03・TC-C2-2d: workspace-write の存在を要求する契約を反転し、read-only と `< /dev/null` を要求する
  - test-reviewer-scoring.sh:360 のコメントの steps-codex.md を消す
  - 新規: tests/test-codex-mode-removed.sh
- [ ] 6. CHANGELOG `[Unreleased]`

### Out of Scope

- `codex_session_id` の扱い（plan への記録、sync-plan の転記、pre-red-gate の (ii) 検査）(Reason: 承認後に読む側は無くなるが、gate の契約なので別に判断する → DISCOVERED)
- 過去の Cycle doc に残る `codex_mode:` の欄 (Reason: 読むものが無くなるのでそのまま)
- 既に導入先の CLAUDE.md にある workspace-write の行 (Reason: #247)
- REVIEW の Codex の sandbox を書き込み可にする案 (Reason: 2026-11-11 に「記録のみ」と決定済み)
- REFACTOR の「Codex fallback」の記述（CLAUDE.md・docs/workflow.md）(Reason: RED/GREEN の委譲とは別の経路なので今回は触らない)

### Files to Change (target: 10 or less → 超える)

文書 21（削除 1、新規 ADR 1 を含む）+ テスト 21（削除 3、新規 1）。どれも記述の削除と言い換えで、新しい手順は足さない。消す行が足す行より多い。

- skills/orchestrate/steps-codex.md (delete)
- skills/orchestrate/{SKILL.md, reference.md, steps-subagent.md, steps-teams.md, adversarial-review.md} (edit)
- skills/{spec/reference.md, spec/reference.ja.md, red/reference.md, green/reference.md, review/SKILL.md, review/reference.md, review/steps-subagent.md, onboard/reference.md} (edit)
- CLAUDE.md, CONSTITUTION.md, README.md, docs/workflow.md, docs/skill-map.md, CHANGELOG.md (edit)
- docs/decisions/adr-codex-review-only.md (new)
- tests/test-codex-mode-removed.sh (new)
- tests/test-{orchestrate-codex, codex-session-unify, steps-codex-improvements}.sh (delete)
- 他のテスト 17 本 (edit)

### 止める基準

GREEN の後に、上の 21 本以外のテストファイルが予定外に FAIL したら、その本数を数える。3 本を超えたら止めて人間に戻す（数える対象は既存のテストファイル、数える時点は GREEN 完了時）。

## Environment

### Scope
- Layer: Backend（plugin の skill 文書と bash のテスト。gate スクリプトは変えない）
- Plugin: なし（dev-crew 本体。`bash run-tests.sh`）
- Risk: 40 (WARN)。フローの経路を 1 つ消す・CONSTITUTION の文言を変える・onboard の配布物を変える

### Runtime
- Language: bash 3.2 / zsh

### Dependencies (key packages)
- なし（dev-crew 本体。`bash run-tests.sh`）

### Execution Mode
- codex_mode: no（ユーザー決定: この cycle 自体が codex_mode を廃止するもので、RED/GREEN は Claude worker）

### WARN 確認（自己回答）
- 影響: Codex が入っている導入先は、今まで steps-codex.md を通っていた。消した後は steps-subagent.md（AGENT_TEAMS=1 なら steps-teams.md）を通る。REVIEW の Codex 実行と adversarial-reviewer への代行は両ファイルにすでにあり、動きは変わらない
- 変わる動き: codex_mode を聞かなくなる。RED/GREEN と REVIEW の修正役は常に Claude の worker。onboard が新しく配る CLAUDE.md の Codex コマンドは read-only になる
- 変えないもの: 承認前の Codex plan review（spec Step 8）、`codex_session_id` の記録と転記と pre-red-gate の検査（Step 8 の再レビューの resume で使う。承認後に使う側は無くなるが、gate の契約なので今回は触らない → DISCOVERED）。既に導入先にある CLAUDE.md の workspace-write の行（onboard の生成物の追従は #247）

## Context & Dependencies

### Reference Documents
- CONSTITUTION.md §4 原則 3「Codex=辛口ベテラン型（Implementer+Reviewer）」、原則 4「Codex利用可能時に優先委譲、不在時はClaude fallback」と食い違う。§8「CONSTITUTION の変更は ADR 必須」なので、ADR を足してから改める:
  - 原則 3: Codex=辛口ベテラン型（Reviewer）
  - 原則 4: 単一モデルでもフローが回る設計。Codex はレビューに使う。Codex が無い・失敗したとき、承認前の plan review は skip して記録し（`codex_unavailable`、Claude 側の review --plan は残る）、code の REVIEW は adversarial-reviewer が代行する（adversarial-reviewer は code REVIEW 専用。`agents/adversarial-reviewer.md:11,19`）
  - 原則 2（別の視点で壊しにいくレビュー）とは整合する。実装と別の視点は REVIEW の Codex（または adversarial-reviewer）が担う
  - 注記: Plan Review Record attempt 2 の指摘 (a) により、実装時は原則 4 の skip を「Codex が無いとき」に限る（Progress Log の Plan Review (pre-approval) を参照）
- README.md の役割表（Codex | Implementer/Reviewer）と手順の説明も合わせる
- docs/decisions/TEMPLATE.md - ADR の形
- .claude/rules/post-approve.md - 承認後の Codex plan review 再実行禁止
- skills/spec/reference.md Step 8 - 承認前 plan review の正規手順

### Dependent Features
- orchestrate steps（subagent / teams）: skills/orchestrate/steps-subagent.md, skills/orchestrate/steps-teams.md
- onboard の Codex Integration テンプレート: skills/onboard/reference.md
- adversarial-reviewer（Codex 不在・失敗時の REVIEW 代行）: agents/adversarial-reviewer.md

### Related Issues/PRs
- Issue #297: codex_mode の full（RED/GREEN の Codex 委譲）の経路を消す
- Issue #247: 既に配った CLAUDE.md の workspace-write の行（onboard の生成物の追従）

### 実測した参照（grep literal、2026-11-11）

```
$ grep -rnE 'codex_mode|steps-codex' skills agents rules CLAUDE.md AGENTS.md CONSTITUTION.md README.md docs/workflow.md docs/skill-map.md
skills/orchestrate/{SKILL.md:62,67,98, reference.md:141,163-184, steps-codex.md(全体), steps-subagent.md:6,179, steps-teams.md:6,223, adversarial-review.md:3}
skills/{green/reference.md:149,161, red/reference.md:300, review/SKILL.md:49, review/reference.md:273,290, review/steps-subagent.md:5}
skills/spec/{reference.md:567, reference.ja.md:509}
CLAUDE.md:14 / docs/skill-map.md:13,15
agents/・rules/・scripts/: 0 件（codex_mode を読む gate は無い）
$ grep -rnE 'resume --last|起動文字列|RED 以降|workspace-write' skills agents rules CLAUDE.md AGENTS.md .claude/rules | grep -v steps-codex
skills/spec/reference{,.ja}.md:23 / skills/onboard/reference.md:503,504,514 / skills/orchestrate/reference.md:141,147,157
skills/orchestrate/steps-subagent.md:203 / steps-teams.md:248 / CLAUDE.md:22-25
$ grep -nE 'Implementer|優先委譲|full/no|full時' CONSTITUTION.md README.md docs/workflow.md
CONSTITUTION.md:23,24 / README.md:31,78 / docs/workflow.md:19,28,33
$ grep -lE 'steps-codex|codex_mode' tests/*.sh | wc -l
19   （+ test-onboard-tdd-workflow-template.sh は workspace-write の存在を要求: :80, :166）
```

run-tests.sh はテストを `tests/test-*.sh` の glob で探すので、テストファイルを消しても runner は変えなくてよい。

## Recall

### docs/cycles/20261016_1645_adversarial-review-triage.md
- **何が起きたか**: 敵対的レビュー 1 回の REVIEW を 3 モードに入れた。規模の基準を「15 本を超えたら止める」と書き、red-worker が新しい TC の数と読んで止めた
- **当時の前提**: 3 モードの REVIEW 節を同じ文で揃える
- **今回も同じ前提か**: No。モードは 2 つになる。止める基準は、数える対象（既存のテストファイル）と時点（GREEN 完了時）を名指しで書いた

### docs/cycles/20261003_2200_codex-delegation-0159.md
- **何が起きたか**: codex-cli 0.159 で `--full-auto` が廃止され、RED/GREEN の委譲が止まっていたのを直した。onboard のテンプレートもこのとき workspace-write の形にした
- **当時の前提**: RED/GREEN を Codex に委譲する経路を残す
- **今回も同じ前提か**: No。経路ごと消す。`--full-auto` を使わないことと呼び出しごとの `< /dev/null` の検査は、残る `codex exec`（plan review と REVIEW、onboard のテンプレート）に対して TC-09 で同じ範囲のまま続ける

## Test List

### TODO

`tests/test-codex-mode-removed.sh`（新規）。「実行手順を書くファイル」= CLAUDE.md・AGENTS.md・rules/*.md・.claude/rules/*.md・agents/*.md・skills/**/*.md:

(DONE へ移動。2026-11-11 17:47 GREEN 完了時)

### WIP
(none)

### DISCOVERED
- 観察 (ARCHITECT): Reference Documents の原則 4 の文案は plan 原文のまま「無い・失敗したとき」と書かれ、直後の注記（attempt 2 (a)）で「無いとき」に限ると訂正している。GREEN で CONSTITUTION に書くのは注記側。文案と注記が同居するので red-worker/green-worker への委譲 prompt に明記する
- 観察 (ARCHITECT): Files to Change が 10 を超える（plan が明示済み）。GREEN 完了時に予定外 FAIL を数える止める基準が唯一の歯止めなので、baseline 124 本の実測と 21 本の名簿を RED 前に固定しておく
- 観察 (ARCHITECT): onboard/reference.md の旧説明（:514）は fence の外にあり、TC-11 の範囲を拡げる対応が RED で必須（plan Record attempt 2 (b)）
- `codex_session_id`（plan の Record、sync-plan の転記、pre-red-gate の (ii)）は承認後に読む側が無くなった → 起票しない。spec Step 8 の再レビューの resume で今も使い、gate の検査も成立している。読む側が無いことの実害の記録は無い（2026-11-11 DISCOVERED、PdM）
- REVIEW の P3 3 件（README の delegation-mode の言及、テストの古いコメント 2 か所、ADR の #297 自己参照）→ 起票しない。結果も手順も変わらない記述の残りで、実害が無い
- 観察 (ARCHITECT) 3 件 → 起票しない。いずれも RED/GREEN で対応済み（原則 4 は「無いとき」に限定、止める基準の予定外 FAIL 0、TC-11 の範囲拡大）

### DONE
- [x] TC-01: steps-codex.md が存在しない（tests/test-codex-mode-removed.sh）
- [x] TC-02: 実行手順を書くファイルと CONSTITUTION・README・workflow・skill-map に `codex_mode` が 0 件
- [x] TC-03: 同じ範囲と tests/ に `steps-codex` が 0 件
- [x] TC-04: すべての `codex exec` 呼び出しが read-only、workspace-write 0 件
- [x] TC-05: subagent・teams の REVIEW 節に read-only + `-o review.md` の Codex 呼び出しがちょうど 1 つ、「resume しない」、green-worker の修正役だけ
- [x] TC-06: orchestrate/SKILL.md のモード一覧が subagent・teams の 2 つ、93 行
- [x] TC-07: spec reference.md・reference.ja.md に委譲確認と「RED 以降」が無い
- [x] TC-08: CONSTITUTION 原則 3・4 の改定（plan review の skip は Codex が無いときだけ）と ADR
- [x] TC-09: `--full-auto` 不在、呼び出しごとの `< /dev/null`（旧 unify TC-08 の範囲のまま）
- [x] TC-10: REVIEW 節の対象の列挙と「再レビューしない」（旧 improvements T-01/T-02）
- [x] TC-11: onboard のテンプレートとセットアップガイダンスが read-only、「RED/GREEN 実装委譲」が無い
- [x] TC-U1: test-adversarial-review.sh の更新
- [x] TC-U2: delegation-preference・session-isolation・delegation-interface・v201 の更新
- [x] TC-U3: C のファイル 11 本の更新
- [x] TC-U4: test-onboard-tdd-workflow-template.sh の反転
- [x] TC-U5: 3 本の削除

### 変異で確かめること（REFACTOR 後）

- steps-codex.md を戻す → TC-01 が落ちる（中身に `steps-codex` の文字列は無いので TC-03 は落ちない）
- steps-subagent.md の冒頭に「Codex利用可能時は steps-codex.md が優先される」を戻す → TC-03 が落ちる
- orchestrate/SKILL.md に `codex_mode` の 1 行を戻す → TC-02 が落ちる
- steps-subagent.md の REVIEW に `codex exec --sandbox workspace-write resume` の修正役を戻す → TC-04・TC-05 が落ちる
- steps-subagent.md の REVIEW の Codex 呼び出しから `-o "/tmp/dev-crew-review-<cycle_id>/review.md"` だけを消す → TC-05 が落ちる
- onboard の テンプレートの 1 行を workspace-write に戻す → TC-04・TC-11 が落ちる
- onboard/reference.md:514 の旧説明（RED/GREEN 実装委譲）を戻す → TC-11 が落ちる
- 1 行に 2 つある `codex exec` の片方から `< /dev/null` を消す → TC-09 が落ちる
- CONSTITUTION 原則 3 に「Implementer」を戻す → TC-08 が落ちる

## Implementation Notes

### Goal

Codex を使うのはレビュー（承認前の plan review と REVIEW）だけにし、どれも read-only にする。orchestrate の実装フェーズは subagent / teams の 2 モードだけにし、codex_mode の問いと欄を無くす。ユーザー決定（2026-11-11）: 既定値を足すのではなく、`full` の経路ごと消す。

### Background

orchestrate は cycle ごとに codex_mode（RED/GREEN を Codex に任せるか）を AskUserQuestion で聞いている。導入先の Cycle doc 128 件（2026-10-19 以降に更新、2026-11-11 実測）では `full` 0 件、`no` 42 件（うち引用符付き 9）、定義外の `yes` 4 件、記録なし 82 件。答えの変わらない問いが cycle ごとに 1 つ増え、誰も通らない `full` の経路を REVIEW などの変更のたびに 3 モード分手入れしている。

探索で分かったこと: `skills/orchestrate/steps-codex.md` は `full` 専用ではなく、「`which codex` が成功したら優先される」モードとして、Codex が入っている環境では `no` でも毎回通っている（`steps-subagent.md:6`、`steps-teams.md:6` の NOTE、`steps-codex.md:11`）。ただし `full` を除くと、中身は `steps-subagent.md` と同じになる:

- REVIEW: `steps-subagent.md` の REVIEW 節は、すでに `which codex` 成功時に新しいセッションで Codex を実行し、修正役は green-worker。steps-codex との差は「`codex_mode: full` なら修正役を Codex で resume」の分岐と、その説明だけ（diff で実測）
- RED/GREEN: `no` のときは steps-codex も Task(red-worker)/Task(green-worker) に落ちる
- Open Questions Response（steps-codex.md:170）は承認後の Codex plan review の名残。plan review は承認前（spec Step 8）に移っており、承認後の再実行は禁止（`.claude/rules/post-approve.md`）

もう 1 つの consumer: onboard が導入先の CLAUDE.md に配る Codex Integration のテンプレート（`skills/onboard/reference.md:501-507`）は `codex exec --sandbox workspace-write` を「非対話実行」「セッション継続」として配り、同 :514 は「RED/GREEN 実装委譲はこのコマンドを使う」と書いている。

### Design Approach

- 消した後の流れ: Block 2 は `AGENT_TEAMS=1 → steps-teams.md、それ以外 → steps-subagent.md` の 2 つだけ。REVIEW の Codex 実行（`which codex` 成功時、新しいセッション、`codex exec --sandbox read-only -o ".../review.md"`）は両ファイルにある既存の記述をそのまま使う
- 不変条件「Codex に書き込み権限を渡さない」: 実行手順を書くファイル（CLAUDE.md・AGENTS.md・rules/・.claude/rules/・agents/・skills/）に `codex exec --sandbox workspace-write` が残らない。承認前の plan review も REVIEW も、onboard が配るテンプレートも read-only
- 書き換えで残す句: 「`resume` しない」「`which codex`」（session-isolation TC-08/09、orchestrate-codex TC-04 の移設先が見る）

Ambiguity Resolution:
- 方針: 既定値を足す案ではなく、経路ごと消す（ユーザー決定 2026-11-11、#297）
- steps-codex.md は消す。full を除いた中身は steps-subagent.md と同じ（REVIEW 節の diff で実測）
- Open Questions Response 節は、承認後の plan review の名残なので移さずに消す
- 「REVIEW は resume しない唯一の例外」は、orchestrate が他で resume しなくなると例外ではなくなる。句を温存せず、「REVIEW は毎回新しいセッション。resume しない」に言い換え、その句を見ている既存テストを新しい契約に合わせる

## Verification

**Real-path invocation を最低 1 件含めること** (rules/integration-verification.md)。

```bash
bash run-tests.sh tests/test-codex-mode-removed.sh
bash run-tests.sh            # 全体。baseline 124 本から 3 本減って 1 本増え、122 本で FAIL 0
grep -rn 'codex_mode\|steps-codex' skills agents rules CLAUDE.md AGENTS.md CONSTITUTION.md README.md docs/workflow.md docs/skill-map.md   # 0 件
grep -rn 'workspace-write' skills agents rules CLAUDE.md AGENTS.md .claude/rules   # 0 件
wc -l skills/*/SKILL.md | awk '$1 > 100 && !/total/'   # 空
```

Evidence: (orchestrate が自動記入)

## Progress Log

Format for each phase entry (**strict, required by pre-commit-gate.sh**):

```
### YYYY-MM-DD HH:MM - PHASE_NAME
- [completed action]
- Phase completed
```

### 2026-11-11 17:29 - KICKOFF
- Cycle doc created
- Scope definition ready
- codex_mode: no (ユーザー決定: この cycle 自体が codex_mode を廃止するもので、RED/GREEN は Claude worker)

### 2026-11-11 17:29 - Plan Review (pre-approval)
- codex_session_id: 01a1c9aa-78d6-7a53-a656-dd016260c5c0
- review_attempts:
  - {started: 2026-11-11 17:12, completed: 2026-11-11 17:22, verdict: BLOCK}
  - {started: 2026-11-11 17:24, completed: 2026-11-11 17:27, verdict: WARN}
- findings 要約: 14:14 の初回は Codex の利用上限で失敗（出力なし。ユーザー判断で 15:19 の解除を待った）。attempt 1（BLOCK、BLOCK 1・重要 6・軽微 2）: onboard のテンプレートが workspace-write を配り、逆向きのテストが存在を要求している / 消すテストの REVIEW 出力先 `-o review.md` の検査が移らない / TC-09 の範囲と呼び出し単位の判定が縮む / spec:23「RED 以降は resume --last」と修正役の「Codex への起動文字列」が literal 検索で拾えない / 「唯一の例外」を温存する理由がない / 新しい原則 4 が plan review と code REVIEW の代行を混同 / CONSTITUTION 変更に ADR が無い / reviewer-scoring:360 のコメント漏れ / 復元変異で TC-03 は落ちない → 全て反映。attempt 2（WARN、重要 2）: (a) 原則 4 の案が「Codex が失敗したとき」も plan review を skip して `codex_unavailable` と書くが、spec reference.md:37,53 は不在時だけに限り、pre-red-gate.sh:221 はこのフラグで試行記録の検査を免除する (b) TC-11 の範囲がリテラルテンプレートの fence だけで、禁止したい「RED/GREEN 実装委譲」は fence の外の onboard/reference.md:514 にあり空振りする → 再レビューは 1 回までなので plan 本文は変えず、ここに記録して RED/GREEN で対応する: (a) 原則 4 は「Codex が無いとき」に限る（失敗時の plan review の扱いは変えない。今は人間に戻している）。TC-08 で原則 4 に「失敗」で skip する文が無いことも確かめる (b) TC-11 の範囲を「Codex Integration リテラルテンプレート + Codex セットアップガイダンス」にし、:514 の旧説明を戻す変異で落ちることを確かめる
- unresolved_blocks: なし
- plan_presented: 2026-11-11 17:28
- reviewed_plan_hash: 59922f7c5317a02966431f728013d81cbc9d5bed9668b395c135aac1140de806
- verdict: WARN
- override: (empty)
- hash 一次照合: plan 実 hash と一致（正準アルゴリズムで再計算）
- Phase completed

### 2026-11-11 17:29 - SYNC-PLAN
- Cycle doc generated from plan (Test List 16 items, Plan Review Record transferred)
- Phase completed

### 2026-11-11 17:30 - ARCHITECT
- verdict: WARN（Design Review Gate: WARN / Post-Transfer Verification: 転記欠落なし・scope 実質変更なし）
- 実測: `bash scripts/gates/pre-red-gate.sh <cycle_doc>` = PASS（rc=0、real-path）。test_count 16 = TC-01..11 + TC-U1..U5 で plan と一致
- Design Review Gate:
  - Scope: Files to Change が 10 を大きく超える（文書 21 + テスト 21）。plan 自身が超過を明示し、止める基準（GREEN 後に予定外 FAIL が 3 本超で人間に戻す）を置いている。新しい手順を足さず削除と言い換えが中心。WARN 理由はこの規模のみ
  - Architecture: 実ファイル突合で、onboard/reference.md:503-504 に workspace-write が現存、:514 に「RED/GREEN 実装委譲」が現存、CONSTITUTION.md:23-24 に Implementer・優先委譲が現存、orchestrate/SKILL.md は 98 行、steps-codex.md は現存（削除対象）。plan の参照と一致。pre-red-gate.sh:216-221 の codex_unavailable 免除も plan の記述どおり
  - Test List: 非空、正常系（TC-01..11）・反転契約（TC-U4）・変異検証を備え Given/When/Then で検証可能。TC-05 は REVIEW 節の呼び出し数「ちょうど 1 つ」で変異に強い
  - Risk: 40 (WARN) は変更内容（経路削除・CONSTITUTION 文言・配布物）と整合
- Post-Transfer Verification:
  - Plan Review Record のフィールド（codex_session_id / verdict / reviewed_plan_hash / review_attempts 2 件 / plan_presented / unresolved_blocks）は frontmatter と Progress Log の Plan Review (pre-approval) に全て反映済み。転記欠落なし
  - 判断依頼の点（sync-plan が Record attempt 2 の (a)(b) を TC 注記として書き添え、変異リストに 1 行足した件）: plan の Plan Review Record は (a) 原則 4 を「Codex が無いとき」に限り TC-08 で「失敗」で skip する文が無いことを確かめる、(b) TC-11 の範囲を「リテラルテンプレート + セットアップガイダンス」にし :514 の旧説明を戻す変異で落ちることを確かめる、と対応方針まで書いている。Cycle doc の追記は TC-08 の括弧注記、TC-11 の括弧注記、Reference Documents の注記、変異リストの `onboard/reference.md:514` の 1 行で、この方針の転記に収まる。In Scope・Out of Scope・Files to Change・Test List の件数（16）は不変。判定: scope 実質変更ではない、再承認は不要
  - 注意: Cycle doc の Test List 本文と plan の Test List 本文は括弧注記の有無で一致しない。plan は承認後 immutable のため、RED/GREEN は Cycle doc 側の注記つきを正とする
- DISCOVERED への記録（観察のみ、scope 影響なし）は Test List の DISCOVERED 節を参照
- Phase completed

### 2026-11-11 17:41 - RED
- baseline（Block 0、17:31 実測）: `bash run-tests.sh` = PASS 124 / FAIL 0 / TOTAL 124
- pre-red-gate: PASS（`bash "<orchestrate の Base directory>/../../scripts/gates/pre-red-gate.sh" docs/cycles/20261111_1730_codex-mode-removal.md`、rc=0）
- red-worker 2 本を担当ファイルを分けて並行に起動（新規テスト / 既存テスト）
- 新規 tests/test-codex-mode-removed.sh（TC-01〜11）: 今の作業ツリーで PASS 5 / FAIL 12。通る TC-05（各検査）・06b・09a・09b・10 は既存の内容で成立する契約の移設で、変異（`-o` を消す、2 つ目の codex exec、`< /dev/null` の片方欠落、`--full-auto`、101 行など）で落ちることを scratchpad の一時コピーで確認
- 既存テスト 17 本を編集し、3 本（test-orchestrate-codex.sh、test-codex-session-unify.sh、test-steps-codex-improvements.sh）を git rm。仕分けは scratchpad の triage-297.md どおり。外れた点: session-isolation TC-04 は `resume しない` の検査に、v201 TC-07/08 は delegation-preference TC-06/12 と重複するので削除、delegation-interface TC-03/06 は新 TC-03 に当たらないよう `"steps-""codex"` と分けて書いた
- 全体: PASS 117 / FAIL 5 / TOTAL 122。FAIL は test-codex-mode-removed.sh と、契約を反転した test-codex-delegation-interface.sh・test-codex-delegation-preference.sh・test-onboard-tdd-workflow-template.sh、その連鎖の test-v201-fixes.sh（TC-10 が delegation-preference を実行する）。予定外の FAIL 0
- 残る注意: TC-05 の「resume しない」は今は旧文「steps-codex.md の REVIEW は resume しない唯一の例外」で満たされている。GREEN の言い換え後に新しい文で満たされることを確かめる
- Phase completed

### 2026-11-11 17:47 - GREEN
- green-worker 2 本を担当ファイルを分けて並行に起動（skill の文書 / 上位の文書と ADR）
- skills: steps-codex.md を git rm。orchestrate の SKILL.md（98 → 93 行、Block 1 の codex_mode と Mode Selection 節を削除、Block 2 は subagent / teams の 2 つ）、reference.md（TDD Gate の委譲モードと full 時スキップ、Session Management を 1 段落に）、steps-subagent・teams（冒頭の NOTE、REVIEW 節を「新しいセッションで実行し resume しない」、修正役は Task の prompt だけ）、adversarial-review.md、spec reference.md・ja（委譲確認の削除、「Step 8 の再レビューは resume --last」）、red・green reference.md（Codex Delegation 節、G-05）、review の 3 本、onboard reference.md（テンプレートを read-only）
- 上位: docs/decisions/adr-codex-review-only.md（新規）、CONSTITUTION §4 原則 3「Codex=辛口ベテラン型（Reviewer）」、原則 4「Codex が無いとき、承認前の plan review は skip して記録し（codex_unavailable）、code の REVIEW は adversarial-reviewer が代行する。Codex が失敗したときも adversarial-reviewer が代行する」、CLAUDE.md（codex_mode の文と RED/GREEN 委譲のコマンド例）、README.md、docs/workflow.md、docs/skill-map.md、CHANGELOG [Unreleased]
- 全体: `bash run-tests.sh` = PASS 122 / FAIL 0 / TOTAL 122（124 − 削除 3 + 新規 1）。止める基準の予定外 FAIL: 0 本
- Verification の grep: `codex_mode|steps-codex` 0 件、`workspace-write` 0 件、100 行超の SKILL.md なし
- 申し送り（REFACTOR で判断）: orchestrate/reference.md の gotcha G-03「Codex session ID stale → 新規セッション作成で retry」は orchestrate が resume しなくなった後も残っている。REVIEW 節の「`resume` しない（… resume しない）」は既存テストの 2 つの形を同じ文で満たすための重複
- Phase completed

### 2026-11-11 17:55 - REFACTOR
- 申し送り 2 点を処理: orchestrate/reference.md の G-03（Codex session ID stale）の行を削除（orchestrate は resume しない。tests に参照なし）。steps-subagent.md・steps-teams.md の REVIEW 節の重複した言い回しを「前のセッションを resume しない。新しいセッションで Codex を実行する（`resume` しないのは、実装の文脈を持ち込まないため）」に整えた（両方の形を見る既存テストを満たしたまま）
- 消した経路への言及の sweep（`Codex ?委譲|Codex に委譲|RED/GREEN と Codex|委譲モード|tdd-gate|Implementer`、skills・agents・rules・上位文書・OVERVIEW・architecture・terminology）: 0 件
- チェックリスト 1〜7: 文書とテストの削除・言い換えのみで、重複・定数・未使用・命名の追加対応なし
- Verification Gate: `bash run-tests.sh` = PASS 122 / FAIL 0 / TOTAL 122。変更した .md の frontmatter 検証 rc=0
- 変異（scratchpad の m297 コピー上、本体は不変）: M1 steps-codex.md を戻す → TC-01（ほか TC-02・04）/ M2 旧 NOTE → TC-03 / M3 SKILL.md に codex_mode → TC-02 / M4 REVIEW に workspace-write の修正役 → TC-04・05 / M5 `-o review.md` を消す → TC-05 / M6 onboard テンプレートを workspace-write → TC-04・11 / M7 onboard セットアップガイダンスに「RED/GREEN 実装委譲」 → TC-11 / M8 1 行 2 呼び出しの片方の `< /dev/null` 欠落 → TC-09b / M9 原則 3 に Implementer → TC-08a / M10 原則 4 に「失敗したときも plan review は skip」 → TC-08a。全 10 件を検出、戻した後は FAIL 0
- Phase completed

### 2026-11-11 17:55 - VERIFY
- `bash run-tests.sh tests/test-codex-mode-removed.sh` = PASS 17 / FAIL 0
- `bash run-tests.sh` = PASS 122 / FAIL 0（baseline 124 − 削除 3 + 新規 1）
- `grep -rn 'codex_mode\|steps-codex' skills agents rules CLAUDE.md AGENTS.md CONSTITUTION.md README.md docs/workflow.md docs/skill-map.md` = 0 件
- `grep -rn 'workspace-write' skills agents rules CLAUDE.md AGENTS.md .claude/rules` = 0 件
- `wc -l skills/*/SKILL.md | awk '$1 > 100'` = 空（orchestrate 93 行）
- real-path: `bash scripts/gates/pre-red-gate.sh docs/cycles/20261111_1730_codex-mode-removal.md` = PASS（RED 前）
- Phase completed

### 2026-11-11 18:14 - REVIEW
- Codex review: 失敗（利用上限。17:56 開始、17:58 に rc=1、出力なし。解除は 20:20）。adversarial-reviewer で代行: 直す 2 / 人間に戻す 0 / 記録のみ 3
- 対象: `git diff HEAD --name-only` と、この cycle の未追跡 3 件（Cycle doc、ADR、新しいテスト）の計 43 件。前からある未追跡（.agents/、docs/research/ の 2 件、scripts/gates/__pycache__/、skills-lock.json）は対象外
- worktree-fingerprint: 前 52af5368…ea6a / 後 52af5368…ea6a（一致、rc=0）
- finding-in-diff: P2-1 tests/test-codex-mode-removed.sh:63 = 0、P2-2 CONSTITUTION.md:24 = 0（どちらも diff の中。修正役へ渡した）
- 直す P2-1: TC-04/TC-09 が単一引用符の prompt、`-s danger-full-access`、`--sandbox read-only -c sandbox_mode=…`、`--dangerously-bypass-approvals-and-sandbox`、`codex  exec`（空白 2 つ）を素通りさせた → 連続空白を 1 つにそろえて切り出し、単一引用符も呼び出しとみなし、read-only 併記でも危険な sandbox 指定を落とす。修正前のテストでの素通りと修正後の FAIL を scratch のコピーで確認
- 直す P2-2: CONSTITUTION 原則 4 の最後の文が失敗時の plan review にも代行を当てるように読めた → 「Codex が失敗したときの code の REVIEW も adversarial-reviewer が代行する」。TC-08a は「失敗」を含む文が adversarial-reviewer と REVIEW を含み、plan を含まないことを要求（「省略」等の言い換えも落ちる）
- 記録のみ P3-1: README.md:74-75 に「delegation-mode question」の言及が残る / P3-2: tests/test-adversarial-review.sh:277 のコメントと test-onboard-tdd-workflow-template.sh:139-143 の TC-C2-2 の説明が古い（結果は変わらない）/ P3-3: ADR:48 が配り直しの追跡先に #297 自身を挙げている
- 修正後の全体: PASS 122 / FAIL 0。未追跡ファイルは修正の前後で同じ（修正役が足したファイルなし）
- Phase completed

### 2026-11-11 23:09 - COMMIT
- pre-commit-gate: PASS（`bash "<orchestrate の Base directory>/../../scripts/gates/pre-commit-gate.sh" docs/cycles/20261111_1730_codex-mode-removal.md`）
- COMMIT 前の md をユーザーに提示し、「commit する」の回答（人間に戻す 0 件）
- docs/STATUS.md の Completed と In Progress を更新
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

- **Failure**: plan の最初の版は、消す範囲を `grep -rnE 'codex_mode|steps-codex'` で洗い出し、onboard が導入先の CLAUDE.md に配る Codex Integration のテンプレート（`codex exec --sandbox workspace-write` を「非対話実行」として配り、RED/GREEN 実装委譲に使えと書く）を落としていた。逆向きのテスト（test-onboard-tdd-workflow-template.sh の TC-03・TC-C2-2d）も workspace-write の存在を要求していた。承認前の Codex plan review（attempt 1、BLOCK）が見つけた
- **Final fix**: `workspace-write`・`resume --last`・「RED 以降」・「起動文字列」でも洗い、onboard の reference.md と逆向きのテストを範囲に加えた。不変条件「実行手順を書くファイルの `codex exec` はすべて read-only」を TC-04 で pin した
- **Insight**: 機能を消すときは、設定の名前（codex_mode）やファイル名で探すだけでは足りない。その機能が実際に使う仕組み（書き込みできる sandbox の呼び出し）の形で探し、名前を持たない consumer（配布用のテンプレートなど）を拾う

### Insight 2

- **Failure**: 不変条件を pin する TC-04 は、二重引用符の prompt を持ち `codex exec`（空白 1 つ）で始まる呼び出しだけを数え、`--sandbox read-only` を含めば合格にしていた。単一引用符、`-s danger-full-access`、read-only と `-c sandbox_mode=…` の併記、`--dangerously-bypass-approvals-and-sandbox`、`codex  exec`（空白 2 つ）を素通りさせた。RED の変異確認は「workspace-write に戻す」形しか試しておらず、REVIEW（adversarial-reviewer による代行）で初めて見つかった
- **Final fix**: 連続空白を 1 つにそろえてから呼び出しを切り出し、単一引用符も呼び出しとみなし、read-only の併記があっても危険な sandbox 指定（短いフラグ、`-c` の設定、bypass）を落とすようにした。修正前のテストで素通りすることと、修正後に落ちることを scratch のコピーで確かめた
- **Insight**: 「危険な権限を渡さない」を pin するテストは、「安全な指定がある」ことの確認だけでは成立しない。危険な権限を与える綴り（長いフラグ・短いフラグ・設定の上書き・bypass）を列挙して否定し、空白や引用符の揺れを正規化してから判定する。変異確認も、その綴りごとに入れる

### Insight 3

- **Failure**: CONSTITUTION 原則 4 の文案は、承認前の plan review で 2 回直された。最初は plan review と code REVIEW の代行を混同し、次は「Codex が無い・失敗したとき plan review を skip」と書いて、失敗時は人間に戻す今の運用と食い違った。GREEN の後も最後の文「Codex が失敗したときも adversarial-reviewer が代行する」が対象を限らず、REVIEW で 3 回目の指摘（P2-2）になった
- **Final fix**: 文ごとに対象を名指しした（「承認前の plan review は」「code の REVIEW は」「Codex が失敗したときの code の REVIEW も」）。TC-08a で、「失敗」を含む文が REVIEW と adversarial-reviewer を含み、plan を含まないことを要求した
- **Insight**: 2 種類のレビューのように扱いの違うものの fallback を 1 つの原則に書くときは、文ごとに主語（どのレビューか）を書く。主語を省いた文は、読み手が前の文の対象を引き継ぐかどうかで意味が変わる

### 想起漏れ

- **設問**: 今回の手戻りは、過去のどの cycle doc を最初に読んでいれば防げたか
- **回答**: docs/cycles/20261111_1105_skill-script-base-paths.md
