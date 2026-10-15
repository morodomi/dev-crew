---
feature: codify-auto-run-stop
cycle: 20261015_1750
phase: DONE
complexity: standard
test_count: 8
risk_level: low
retro_status: captured
codex_session_id: "01a13eb7-5fb3-7690-921b-8cdb8838c59b"
reviewed_plan_hash: 044b7731f8ca2a17d9d31bf66f4bc2eb0816f34de8b5b26e6c73608e08d94692
plan_file: /Users/morodomi/.claude/plans/dazzling-bubbling-feather.md
created: 2026-10-15 18:04
updated: 2026-10-15 23:48
---

# codify-insight の自動実行を止める（フロー再設計 手順 0）

## Scope Definition

### In Scope / Files to Change
- `skills/orchestrate/SKILL.md` — Block 0 の「0. Codify gate」を「0. Codify notice」に変更。captured を数えて 1 行通知するだけで、件数にかかわらず次へ進む。`Skill(dev-crew:codify-insight)` を起動しない。通知文は固定文言「未処理の振り返りを持つ Cycle doc が N 件あります（retro_status: captured）。処理するときは /dev-crew:codify-insight を別に実行し、タスクとは別の commit にしてください。」（現 98 行、100 行未満を維持）
- `skills/orchestrate/steps-subagent.md` / `steps-teams.md` — Block 0 の同じ節を同じ内容に変更
- `skills/orchestrate/steps-codex.md` — L44「codify-insight も同一で、既定は自動 triage…」を削除
- `skills/orchestrate/reference.md` — 「Block 0 Pre-Check: Codify Gate」を通知の仕様に書き換え（frontmatter-only scan の理由の節は残す）。通知文の定型をここに置く
- `skills/codify-insight/SKILL.md`:
  - frontmatter に `disable-model-invocation: true` を追加（モデル自身による起動経路を塞ぐ。人間の `/dev-crew:codify-insight` は使える。Claude Code 公式仕様の「Control who invokes a skill」）
  - description から「次サイクル開始時に /orchestrate Block 0 から自動起動」「次サイクル開始時」の起動語を削除し、手動起動のみと書く
  - `## Restrictions` を追加。契約文は次の 3 文を固定文言で置く（テストが固定文字列で照合する）:
    - 「編集してよいのは、対象 Cycle doc の `## Codify Decisions` への追記と、frontmatter の `retro_status` と `updated` の更新だけ。」
    - 「rules、skills、agents、STATUS.md を含む、それ以外のファイルは編集しない。codified の反映は別サイクルで行う。」
    - 「codify の変更はタスクの変更と同じ commit に入れない。」
  - Exit Contract の orchestrate 連携記述を手動起動前提に直す
  - 100 行未満（≤ 99 行）を維持。超えるなら Exit Contract の詳細を reference.md へ移す
- `skills/codify-insight/reference.md`:
  - Rule Tier Contract の「反映先は follow-up 実装主体が…」に、固定文言「follow-up は別サイクルで行い、codify-insight の実行中には反映しない。」を足す
  - 「`codified` Marker MVP 意味論」節の「次 cycle / 手動 edit / 別 skill で実施」「新 cycle 起票 or 手動 edit」を、同じ固定文言に揃える（rule 以外の destination にも効かせる）
- `ROADMAP.md` — Step 1b の「次回 /orchestrate 開始時 decide gate」を「手動起動の decide gate（2026-10 に自動起動を廃止）」に。Step 1.5「captured 可視化（未処理 insight 件数の警告）」は「一部完了: 未処理 Cycle doc 件数の通知（insight 件数ではない）」と明記する
- `docs/STATUS.md` — L110〜111 の Step 1b / 1.5 の記述を ROADMAP と揃える
- `rules/plan-discipline.md` と `.claude/rules/plan-discipline.md`（byte-identical mirror）— Block 0 codify 同梱の推奨条項と、その出典行を削除（原因が無くなるため）
- `docs/workflow.md` — 「[次サイクル Block 0] codify-insight ← 自動起動」の図を、通知 + 手動起動に変更
- `docs/architecture.md` — 「Agile Loop: codify-insight」節の自動起動の記述を同様に変更
- `docs/decisions/adr-cycle-retrospective.md` — 末尾に改訂注記（2026-10: 自動起動を通知に変更。理由は実験の観測と L18「codify は人間承認」との不整合）
- `CLAUDE.md` — Skills 節の codify-insight の 1 行を手動起動に合わせる
- `CHANGELOG.md` — [Unreleased] に Changed 1 項目
- `tests/test-codify-insight.sh` — TC-15/16/17 を書き換え、TC-15b・TC-24〜26 を追加（Test List 参照）。既存 TC-02 の行数判定 `-le 100` を AGENTS.md の制約どおり `-lt 100` に直す
- `tests/test-codify-rule-docs.sh` — TC-57（同梱条項の存在 pin）を、条項が無いことの確認に置き換え

### Out of Scope
- cycle-retrospective（retro_status: captured を付ける側）の変更。振り返りの記録はこれまでどおり
- codify-insight の triage ロジック（recurrence pre-triage、autonomous batch）の変更
- 過去の Cycle doc 本文にある Block 0 codify の記述（履歴なので触らない）
- フロー再設計の手順 1 以降（敵対的レビュー、指摘の振り分けなど）

## Environment

### Scope
- Layer: plugin docs（Markdown の skill / rule / doc と shell テスト。Backend/Frontend 該当なし）
- Plugin: なし（dev-crew 本体、tests は bash）
- Risk: 15 (PASS) — 実行コードの変更なし。skill の指示文・doc・テストのみ

### Runtime
- Language: bash, Markdown

### Dependencies (key packages)
- なし

### Risk Interview (BLOCK only)
(BLOCK なし。該当せず)

## Context & Dependencies

### Reference Documents
- docs/research/flow-rethink-2026-10.md §5.7 — 比較実験（現行フロー A は 9 回中 9 回、タスクと無関係な変更を commit に入れた）
- docs/decisions/adr-cycle-retrospective.md — ADR-002（L18「codify は人間承認」、L48・L86「codify 実行は強制しない」）

### Dependent Features
- test-rules-mirror.sh: rules/plan-discipline.md と .claude/rules/plan-discipline.md の byte-identical
- test-post-approve-action.sh: Block 0 の記述
- test-cycle-doc-ssot.sh TC-07/08: Block 0 の保持

### Related Issues/PRs
- なし

### Ambiguity Resolution
- Scope: 自動起動は「通知のみ」に置き換える（完全削除ではない）。rules 編集の禁止も同梱（ユーザー回答）
- Data: captured の検出スキャン（frontmatter-only awk）はそのまま残し、通知の件数に使う

### Background
2026-10 の比較実験（docs/research/flow-rethink-2026-10.md §5.7、ブランチ docs/flow-experiment-2026-10）で、現行フロー（A）は 9 回中 9 回、タスクと無関係な変更を修正の commit に入れた。原因は 2 つ。

1. orchestrate Block 0 の codify gate が、起動のたびに codify-insight を自動で走らせる。過去の Cycle doc（Codify Decisions 追記、retro_status 遷移）や STATUS.md の変更が、今回のタスクの commit に同梱される。rules/plan-discipline.md はこの同梱を「透明化せよ」と注記しているだけで、止めていない。
2. codify-insight の契約は「判断の記録のみ（MVP、ADR-002 L86、cycle 20260422_1146 の Out of Scope）」だが、実験では AI が Block 0 の途中で `.claude/rules/testing-guide.md` に heredoc で条項を追記した。reference.md の「反映先は follow-up 実装主体が…」が曖昧で、実行中の AI が自分を実装主体と解釈した。ADR-002 L18「codify は人間承認」にも反する。

ユーザーの決定（AskUserQuestion）:
- 自動起動は止め、Block 0 は「未処理の振り返りが N 件ある」と通知するだけにする。処理は人間が `/dev-crew:codify-insight` を呼んだときに、タスクとは別の commit で行う。
- codify-insight 実行中に rules などを書き換える穴も、この cycle で塞ぐ。

## Recall

### docs/cycles/20260422_1146_codify-insight-skill.md
- **何が起きたか**: codify-insight と Block 0 codify gate を導入した cycle。Out of Scope に「codify now 選択時の自動 rule/skill 追記（MVP は判定記録のみ — ADR-002 L86 準拠）」とある
- **当時の前提**: codify-insight は判断の記録だけを行い、反映は人間か別サイクルが行う。Block 0 の自動起動は「判断の記録」だけなので無害
- **今回も同じ前提か**: No。実験で、自動起動中に AI が rules を書き換えた。判断の記録だけでも、前 cycle doc の変更がタスクの commit に混ざる

### docs/cycles/20260721_1503_rules-load-trigger-reclassification.md
- **何が起きたか**: 「反映責務: codify-insight は tier/paths を記録するのみ、実ファイル書き出しは行わない。follow-up 実装主体が反映」を reference.md に書いた cycle。同 cycle で Block 0 codify の出力を scope 同梱注記として commit に混ぜている
- **当時の前提**: 「follow-up 実装主体」が誰かは文脈で分かる
- **今回も同じ前提か**: No。実行中の AI が自分を実装主体と解釈した。主体を「別サイクル」と明記する

### docs/cycles/20260423_0926_discovered-followup-mirror-rules.md
- **何が起きたか**: rules/ と .claude/rules/ の mirror を byte-identical に揃え、test-rules-mirror.sh で pin した
- **当時の前提**: rules/ を変えたら mirror も同時に変える
- **今回も同じ前提か**: Yes。plan-discipline.md は両方を同じ内容で変更する

## Upstream References

- CONSTITUTION: 手順は目的のための手段で見直す対象。人間は判断を担う（codify の反映は人間の判断）
- ADR-002 L18「codify は人間承認」、L48・L86「codify 実行は強制しない」— 本変更はこれに沿う方向。ADR に改訂注記を足す
- docs/research/flow-rethink-2026-10.md §5.7・findings「5. 現行フローは、頼んでいない変更を毎回 commit に入れた」

## Test List

Block 0 の通知は、実行できるスニペットとして書く（captured の件数を 1 行で出力し、件数にかかわらず exit 0 で先へ進む）。テストはこのスニペットを SKILL.md から取り出して実際に実行する。

### TODO
(none)

各 TC は修正前のファイルで FAIL することを RED で実測する（vacuous test を避ける）。

### WIP
(none)

### DISCOVERED
- [architect 観察] codify-insight/SKILL.md は現 97 行。`## Restrictions`（見出し + 3 文）追加で 100 行以上になる可能性が高い。plan の逃げ道どおり、Exit Contract（L91-93 付近）の詳細を reference.md へ移して 99 行以下に収める
- [architect 観察] SKILL.md L91・L93 に「orchestrate Block 0 は次ステップへ進行」「Block 0 codify gate で再スキャン」の旧記述が残る。plan の「Exit Contract の orchestrate 連携記述を手動起動前提に直す」で扱うが、Block 0 / codify gate の語を negative assert で pin すると取り残しを防げる
- [architect 観察] tests/test-rules-path-scoping.sh TC-10 と tests/test-local-rules-separation.sh TC-04 が codify-insight/reference.md の Rule Tier Contract を pin している。reference.md の同節に固定文言を足す際、既存 pin を壊さないか GREEN で回帰確認する（回帰項目の `bash run-tests.sh` 全件でカバーされる）
- [REVIEW accept-defer] codify-insight の Edit を対象 Cycle doc に機械的に限定する（hook 案）→ issue #259
- [REVIEW accept-defer] captured 通知に閾値か最古の Cycle doc 名を出す → issue #260
- [REVIEW accept-defer] cycle-retrospective の出力に手動 codify の案内を足す → issue #261

### DONE
- [x] TC-15: orchestrate/SKILL.md Block 0「0. Codify notice」節が通知のみ（Skill 起動・待機条件なし、固定通知文、「件数にかかわらず次へ進む」、frontmatter-only awk）
- [x] TC-15b: SKILL.md の通知スニペットを fixture で実行し 0/1/3/1 と exit 0 を確認。REVIEW 修正で frontmatter 内コメント行のみ（0 件）と約 1MB frontmatter を `bash -o pipefail` で実行（1 件）を追加
- [x] TC-16: steps-subagent.md の通知節（TC-15 の (a)〜(d) + bare grep 無し + スニペットが SKILL.md と同一）
- [x] TC-17: steps-teams.md の通知節（TC-16 と同じ）
- [x] TC-24: steps-codex.md に codify-insight を起動・自動 triage する記述が無い
- [x] TC-25: codify-insight/SKILL.md が手動起動のみ + Restrictions 3 文。REVIEW 修正で allowed-tools に Bash / Write が無いことを追加
- [x] TC-26: codify-insight/reference.md の Rule Tier Contract 節と MVP 意味論節に固定文言があり、旧文言が無い
- [x] TC-27（REVIEW で追加）: orchestrate/reference.md Block 0 節のスニペット・通知文が SKILL.md と同一
- [x] TC-57（置換）: rules/plan-discipline.md に codify gate 条項と出典行が無い
- [x] 回帰: `bash run-tests.sh` 全件 119/119 PASS、100 行以上の SKILL.md なし

## Implementation Notes

### Goal
codify-insight の自動起動を止め、Block 0 は未処理の振り返りがある Cycle doc の件数を通知するだけにする。処理は人間が `/dev-crew:codify-insight` を手動で呼び、タスクとは別の commit で行う。codify-insight 実行中に rules などを書き換える穴も塞ぐ。

### Background
上記 Context & Dependencies の Background を参照（plan の Context を転記）。

### Design Approach
- orchestrate Block 0: codify gate を notice に置換。frontmatter-only awk の captured スキャンは維持し、件数の通知にだけ使う
- codify-insight: `disable-model-invocation: true` でモデル起動経路を塞ぎ、`## Restrictions` の固定 3 文で編集範囲を契約化する
- reference.md の「follow-up 実装主体」の曖昧さを、固定文言「follow-up は別サイクルで行い、codify-insight の実行中には反映しない。」で解消する
- rules/plan-discipline.md は mirror と同時に変更（byte-identical を維持）

## Verification

1. `bash run-tests.sh` 全件 PASS（変更前の baseline と比較し、新たな FAIL なし）
2. `wc -l skills/*/SKILL.md | awk '$2 != "total" && $1 >= 100'` が空（AGENTS.md の制約は 100 行未満）
3. `diff rules/plan-discipline.md .claude/rules/plan-discipline.md` が空
4. `grep -rn "Skill(dev-crew:codify-insight)" skills/orchestrate/` が 0 件
5. 実地確認: captured の Cycle doc を 1 つ置いた一時コピーで `claude -p "/dev-crew:orchestrate"` 相当を走らせるのは重いので行わない。代わりに、変更後の Block 0 の文面を読んで、起動指示が通知に置き換わったことを REVIEW で確認する（弱い確認であることを Cycle doc に記録）

Evidence: (orchestrate が自動記入)

## Plan Review Record

- codex_session_id: 01a13eb7-5fb3-7690-921b-8cdb8838c59b
- verdict: WARN
- reviewed_plan_hash: 044b7731f8ca2a17d9d31bf66f4bc2eb0816f34de8b5b26e6c73608e08d94692
- findings 要約: attempt 1 BLOCK（P1: モデル起動経路が残る → disable-model-invocation、P2×5: TC-25 偽 PASS / TC-15〜17 が通知のみを検証できない / reference MVP 節の矛盾 / ROADMAP・STATUS の更新漏れ / 行数チェックが total 行を拾う）→ 全件反映。attempt 2 WARN（P2: Step 1.5 を insight 件数でなく Cycle doc 件数で完了扱い / P3: TC-02 が 100 行を許容）→ 2 件とも反映（Step 1.5 は一部完了と明記、通知文を「Cycle doc が N 件」に、TC-02 を -lt 100 に）
- review_attempts:
  - {started: 17:39, completed: 17:43, verdict: BLOCK}
  - {started: 17:44, completed: 17:46, verdict: WARN}
- plan_presented: 2026-10-15 17:47
- unresolved_blocks: なし
- override:

## Progress Log

Format for each phase entry (**strict, required by pre-commit-gate.sh**):

```
### YYYY-MM-DD HH:MM - PHASE_NAME
- [completed action]
- Phase completed
```

### 2026-10-15 18:04 - KICKOFF
- Cycle doc created from plan (dazzling-bubbling-feather.md)
- Scope definition ready
- Block 0: captured の cycle doc 1 件（20261005_1639_local-rules-separation.md）を検出。本 cycle は Block 0 の codify 自動起動を止める変更で、ユーザー決定（通知のみ）を先行適用し、codify-insight は起動しなかった。通知のみ出力。
- Phase completed

### 2026-10-15 18:30 - RED
- tests/test-codify-insight.sh: TC-15/16/17 を書き換え（Block 0「0. Codify notice」区間を先行抽出して判定、TC-16/17 は SKILL.md とスニペット同一を確認）。TC-15b（fixture で通知スニペットを実行し 0/1/3/1 と exit 0 を確認）・TC-24・TC-25・TC-26 を追加。TC-02 を `-lt 100` に変更
- tests/test-codify-rule-docs.sh: TC-57 を「条項と出典行が無い」の確認に置換
- 現行実装での実測: test-codify-insight.sh は PASS 18 / FAIL 14。FAIL = TC-15, 15b, 16, 17, 24, 25, 26。TC-02 は 97 行で PASS。test-codify-rule-docs.sh は PASS 64 / FAIL 1（TC-57 のみ）
- 正の経路は scratchpad の模擬実装（期待どおりの SKILL/steps/reference）で TC-15〜17・24〜26 が全て PASS することを確認（vacuous でない）
- Phase completed

### 2026-10-15 18:04 - Plan Review (pre-approval)
- codex_session_id: 01a13eb7-5fb3-7690-921b-8cdb8838c59b
- review_attempts:
  - {started: 17:39, completed: 17:43, verdict: BLOCK}
  - {started: 17:44, completed: 17:46, verdict: WARN}
- findings 要約: attempt 1 BLOCK（P1: モデル起動経路が残る → disable-model-invocation、P2×5: TC-25 偽 PASS / TC-15〜17 が通知のみを検証できない / reference MVP 節の矛盾 / ROADMAP・STATUS の更新漏れ / 行数チェックが total 行を拾う）→ 全件反映。attempt 2 WARN（P2: Step 1.5 を insight 件数でなく Cycle doc 件数で完了扱い / P3: TC-02 が 100 行を許容）→ 2 件とも反映（Step 1.5 は一部完了と明記、通知文を「Cycle doc が N 件」に、TC-02 を -lt 100 に）
- unresolved_blocks: なし
- plan_presented: 2026-10-15 17:47
- reviewed_plan_hash: 044b7731f8ca2a17d9d31bf66f4bc2eb0816f34de8b5b26e6c73608e08d94692
- override:
- verdict: WARN
- computed_plan_hash (sync-plan 実測, 正準アルゴリズム): 044b7731f8ca2a17d9d31bf66f4bc2eb0816f34de8b5b26e6c73608e08d94692（Record 記載値と一致）
- Phase completed

### 2026-10-15 18:04 - SYNC-PLAN
- Cycle doc generated: docs/cycles/20261015_1750_codify-auto-run-stop.md
- Plan Review Record transferred (Step 3.5)。hash 一次照合: 一致
- Test List 9 項目（TC-15, 15b, 16, 17, 24, 25, 26, 57 置換, 回帰）を転記
- Phase completed

### 2026-10-15 18:07 - ARCHITECT (Design Review Gate + Post-Transfer Verification)
- pre-red-gate real-path 実行: `bash scripts/gates/pre-red-gate.sh docs/cycles/20261015_1750_codify-auto-run-stop.md` → PASS (rc=0)
- Post-Transfer Verification: Plan Review Record 全フィールド（codex_session_id / verdict / reviewed_plan_hash / review_attempts / unresolved_blocks）と Files to Change（15 項目）・Test List（9 項目）・Out of Scope が plan と一致。転記欠落なし、scope 変更なし
- Design Review Gate: Files to Change は実質 15 ファイル（mirror 含む）で目安 10 超だが、doc/test のみの同一テーマ変更。plan 内で正当化済みのため WARN 相当の観察のみ
- 実ファイル突合: orchestrate/SKILL.md L41 に「0. Codify gate」、steps-codex.md L44 に「codify-insight も同一…」、reference.md L46 / L177-178 に旧文言、STATUS.md L110-111・ROADMAP.md L19-20・workflow.md L67・architecture.md L160-180・CLAUDE.md L36・TC-15/16/17/TC-57 が実在。TC-24〜26 は未使用で採番衝突なし（最大 TC-23）
- verdict: PASS（観察のみ 3 件を DISCOVERED に記録）
- Phase completed

### 2026-10-15 18:13 - GREEN
- 実装: orchestrate SKILL.md / steps-subagent / steps-teams を「0. Codify notice」（件数を整数 1 行で出す bash スニペット、常に exit 0、固定通知文、件数にかかわらず次へ進む）に置換。steps-codex の codify-insight 行を削除。orchestrate reference.md の Block 0 節を通知の仕様に書き換え（アンカー維持）
- codify-insight SKILL.md: `disable-model-invocation: true`、description を手動起動のみに、`## Restrictions` 3 文、Block 0 の語を除去。Exit Contract の詳細を reference.md の `## Exit Contract` へ移動（99 行）。reference.md の Rule Tier Contract / MVP 節に固定文言を追加
- ROADMAP / STATUS / workflow / architecture / ADR 改訂注記 / CLAUDE.md / CHANGELOG を更新。plan-discipline.md（rules/ と .claude/rules/）から Block 0 codify 条項と出典行を削除（byte-identical 維持）
- 副次: orchestrate SKILL.md の行数確保のため、Mode Selection 直下の重複リンク行（詳細: reference/steps-*）を削除（同じリンクは Block 2 に既出）
- 結果: `bash run-tests.sh` 119/119 PASS。100 行以上の SKILL.md なし。mirror diff 空。`Skill(dev-crew:codify-insight)` の grep は skills/orchestrate/ で 0 件
- Phase completed

### 2026-10-15 18:17 - REFACTOR
- チェックリスト 7 項目を確認。テストの共通処理は既にヘルパ（extract_notice_skill / extract_notice_steps / extract_bash_fence / check_notice_section / check_steps_notice）に集約済みで、改善不要
- 静的解析: shellcheck は環境に未導入。`bash -n` で構文 OK
- PdM 再実測: `bash run-tests.sh` 119/119 PASS。通知スニペットを実リポジトリで実行し、captured 1 件に対し `1` と rc=0（real-path）
- 注記: RED エントリの時刻 18:30 は実測値ではない（GREEN 18:13 より後になっている）。APPEND-ONLY のため書き換えず、ここに記録する
- Phase completed

### 2026-10-15 18:27 - REVIEW fixes
- 通知スニペットの件数誤りを修正。先に tests/test-codify-insight.sh の TC-15b へ fixture を追加（frontmatter 内の `# retro_status: captured` コメント行と引用フィールドのみ → 0 件、約 1MB の frontmatter を持つ captured doc を `bash -o pipefail -c` で実行 → 1 件）。修正前のスニペットで 2 ケースとも FAIL を実測（コメントのみは `1`、1MB は `0`）。その後 `grep -E '^retro_status:[[:space:]]*captured[[:space:]]*$' >/dev/null`（行全体照合、入力を最後まで消費）に変更。orchestrate の SKILL.md / steps-subagent.md / steps-teams.md / reference.md の 4 か所を同一に更新し、codify-insight/SKILL.md の Hard Gate も同じ形に揃えた
- TC-27 を追加（orchestrate/reference.md の Block 0 節のスニペット・通知文が SKILL.md と同一）。TC-25 に allowed-tools に Bash / Write が無い負の条件を追加。TC-15b の fixture 後始末を `trap ... EXIT`（rm 対象は mktemp の戻り値のみ）に変更
- ADR の本文 2 か所（L30・L80 付近）に改訂注記を追記。codify-insight/SKILL.md の description を「モデルからは起動しない。/dev-crew:codify-insight を入力して起動する」に整理し、CLAUDE.md の該当行も同旨に変更。docs/STATUS.md の Step 1b を [x]、Last updated を 2026-10-15 に更新
- Test List の完了項目を DONE へ移動（TODO は (none)）
- 結果: `bash run-tests.sh` 119/119 PASS。100 行以上の SKILL.md なし
- Phase completed

### 2026-10-15 18:32 - REVIEW
- Risk: HIGH (115)。Codex（WARN）+ correctness / security / maintainability / design の 5 者
- accept-apply（上の REVIEW fixes で適用）: 通知件数の誤り（部分一致・pipefail 下の SIGPIPE。Codex important）、reference.md を同一性照合の対象に（maintainability important）、ADR 本文の旧記述（maintainability important）、自然言語起動の整理（design important）、Test List 完了状態（Codex important）、allowed-tools の負の条件・fixture の trap・STATUS 整合（optional）
- 副次: codify-insight/SKILL.md の Hard Gate にも同じ部分一致の欠陥があり、同じ形に揃えた（scope 同梱、REVIEW fixes に記録）
- accept-defer: Edit の機械的制限（security important）→ #259、通知の閾値（design important）→ #260、retrospective の案内 → #261
- reject: Mode Selection のリンク行削除（同じリンクが L67 に残り導線は消えていない）。テストヘルパの読みやすさ・TC-24 の言い換え検出（optional、現状の契約で再混入は主経路で検出できる）
- 判定: WARN（important を accept-defer で持ち越すため）。PdM 再実測: 119/119 PASS、pipefail 下で実リポジトリの件数 1・rc=0
- Phase completed

### 2026-10-15 23:48 - COMMIT
- 人間の確認（REVIEW 後・COMMIT 前の判断点）: 変更の要約を mdopen で提示し、commit の承認を得た
- pre-commit-gate PASS。STATUS.md の Completed に追記。ブランチ docs/flow-experiment-2026-10 に commit（push・PR は未実施）
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

- **Failure**: plan の TC-25 は、Restrictions 節に「rules」「編集しない」「別サイクル」「commit」の語があるかを見る設計だった。Codex plan review が、逆の指示（「rules は自由に編集してよい…同じ commit に含める」）でも PASS することをメモリ上で実証した
- **Final fix**: 契約文を 3 文の固定文言として plan に書き、テストは固定文字列で全文を照合する形にした
- **Insight**: 禁止や義務を表す文章の契約は、語の有無でなく固定文全体で pin する。語の有無の検査は、否定を反転した文でも通る

### Insight 2

- **Failure**: 通知の件数スキャンは、旧 codify gate の `grep -q 'retro_status: captured'` をそのまま流用した。plan review も RED/GREEN も通ったが、code review（Codex）が、frontmatter 内のコメント行を数えること、`bash -o pipefail` 下で大きな frontmatter だと SIGPIPE で数え落とすことを再現した。同じ欠陥は codify-insight の Hard Gate にもあった
- **Final fix**: 行全体の照合 `grep -E '^retro_status:[[:space:]]*captured[[:space:]]*$' >/dev/null` にし、入力を最後まで消費する。TC-15b にコメント行と 1MB の fixture を足し、修正前に FAIL することを実測した
- **Insight**: 既存のスキャンを「件数」や「通知」に転用するときは、流用元の潜在欠陥も引き継ぐ前提で、コメント・引用・巨大入力（pipefail 下）の fixture を最初の Test List に入れる。`cmd | grep -q` は pipefail 下の SIGPIPE を疑う

### 想起漏れ

- **設問**: 今回の手戻りは、過去のどの cycle doc を最初に読んでいれば防げたか
- **回答**: docs/cycles/20260709_1125_risk-classifier-doc-diff-fix.md
