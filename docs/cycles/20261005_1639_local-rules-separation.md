---
feature: local-rules-separation
cycle: 20261005_1639
phase: DONE
complexity: standard
test_count: 10
risk_level: low
retro_status: captured
codex_mode: no
codex_session_id: "01a10ae3-695a-7610-8eb7-1e2550aa37c0"
plan_file: /Users/morodomi/.claude/plans/compressed-doodling-cake.md
created: 2026-10-05 16:39
updated: 2026-10-05 17:25
---

# 導入先へ配る rules の 2 不具合を直す（rules の上書き消失 / baseline 手順の本体専用化）

## Scope Definition

### In Scope
- [ ] onboard Step 6 の mirror 対象を `rules/*.md` と同名のファイルだけに限定し、`.claude/rules/local-<name>.md` を触らない旨を明記（命名規約 / scope 規約 / 初回のみの移行手順 / 2-way diff の限界）
- [ ] codify-insight の反映先を本体（`rules/` + mirror）と導入先（`.claude/rules/local-<name>.md`）の 2 分岐にする（判定は `.claude-plugin/plugin.json` の `name`）
- [ ] spec / commit の SKILL.md で、名前指定の rule Read に `local-` 対のファイルも併せて読む旨を追記（行数は増やさない）
- [ ] `rules/plan-discipline.md` と mirror の baseline 手順を一般化（AGENTS.md の Quick Commands / Quick Start 参照。正規 runner 優先）、`## 具体例` に「dev-crew 本体の例」注記
- [ ] 契約テスト `tests/test-local-rules-separation.sh` を新規作成
- [ ] CHANGELOG `[Unreleased]` に Fixed 2 件

### Out of Scope
- #247（生成物へのコピーをやめる方向） (Reason: 今回は rules だけを扱う)
- #235（orchestrate Block 0 の baseline） (Reason: 文言の互換だけを保つ)
- #223 / #255 / #256 (Reason: 範囲外)
- `skills/onboard/reference.md:405` の Quick Commands テンプレートの古い direct loop (Reason: DISCOVERED に回す)
- `rules/plan-discipline.md:36,38` の snapshot 隔離条項の本体色 (Reason: DISCOVERED に回す)
- `local-` 用サブディレクトリ（`.claude/rules/local/`） (Reason: Claude Code の再帰読み込み仕様を一次ソースで確認していない。フラット prefix で仕様依存を避ける)

### Files to Change (target: 10 or less)
- skills/onboard/reference.md (edit)
- skills/onboard/SKILL.md (edit)
- skills/codify-insight/reference.md (edit)
- skills/spec/SKILL.md (edit)
- skills/commit/SKILL.md (edit)
- rules/plan-discipline.md (edit)
- .claude/rules/plan-discipline.md (edit)
- tests/test-local-rules-separation.sh (new)
- CHANGELOG.md (edit)

### 同梱される承認済み Files 外の差分（scope 同梱の注記）
orchestrate Block 0 の codify gate が、この cycle の起票前に前 cycle doc 4 本を更新済み（`retro_status: captured` → `resolved` と Codify Decisions の追記）。この差分は承認済み Files には現れないが、本 cycle の commit に同梱される。

- docs/cycles/20260916_1634_shrink-runner-remove-nesting.md (modified, codify gate 由来)
- docs/cycles/20261003_2200_codex-delegation-0159.md (modified, codify gate 由来)
- docs/cycles/20261004_0020_audit-contradictions.md (modified, codify gate 由来)
- docs/cycles/20261004_0030_leak-guard.md (modified, codify gate 由来)

## Environment

### Scope
- Layer: プラグイン定義（skills / rules）
- Plugin: Markdown + bash 契約テスト（dev-crew 本体）
- Risk: 25 (PASS) — doc と契約テストだけ。実行コードは変えない。セキュリティに関わるキーワードなし
- Codex mode: no（ユーザー決定済み。RED/GREEN は Claude が担当）

### Runtime
- Language: bash / Markdown
- Version Gate: dev-crew.json 2.18.2 = installed 2.18.2（OK）
- 進行中の cycle: なし（直近 2 本はどちらも DONE）

### Dependencies (key packages)
- bash: `run-tests.sh` 経由で実行
- 外部パッケージ追加なし

### Risk Interview (BLOCK only)
(BLOCK なし。該当せず)

## Context & Dependencies

### Reference Documents
- skills/onboard/reference.md:544,552 / skills/onboard/SKILL.md:76 - rules の identical mirror（Step 6）
- skills/codify-insight/reference.md:46 - 反映先の記述
- skills/spec/SKILL.md:73 / skills/commit/SKILL.md:91 - 名前指定の rule Read
- rules/plan-discipline.md:23,46-52 - `run-tests.sh` 固定の baseline 手順
- .claude/rules/skill-authoring.md - SKILL.md 100 行制約（spec 97 / commit 91 / onboard 96 を維持）

### Dependent Features
- onboard TC-19 契約: tests/test-onboard-research.sh:210（`identical mirror` 文言を維持）
- rules mirror 検査: tests/test-rules-mirror.sh, tests/test-rules-path-scoping.sh:206（TC-06、影響なし）
- run-tests.sh 文言契約: tests/test-run-tests-runner.sh の TC-41/43/44（維持）

### Related Issues/PRs
- Issue #247: 生成物へのコピーをやめる方向（矛盾しない。rules の mirror は続き、ローカルだけを分ける）
- Issue #235: orchestrate Block 0 の baseline（文言の互換だけ保つ）
- Issue #223 / #255 / #256: 範囲外

逆向き契約の sweep（実測）: `grep -rn "identical mirror\|同時適用\|follow-up 実装主体" tests/ skills/ rules/` の結果は `tests/test-onboard-research.sh:210`（TC-19、維持）、`tests/test-rules-path-scoping.sh:206`（TC-06、本体の mirror ペア検査で影響なし）、ほかは変更対象そのもの。

## Recall

`scripts/recall-candidates.sh` の上位候補:
- `20260721_1503_rules-load-trigger-reclassification` — 「onboard の mirror 指示は frontmatter ごと複製するので無変更で正しい」と判定した cycle。今回は、その前提（導入先に独自の条項がない）が崩れた例にあたる。tier は `paths:` frontmatter で決まるので、`local-` は対の本体 rule の scope（`paths:` の有無を含む）を写す
- `20260423_0926_discovered-followup-mirror-rules` — mirror の allowlist を明示配列にした cycle。`test-rules-mirror.sh` の CLAUDE_ONLY_FILES は本体の検査なので触らない
- `20260717_1605_approval-reorder-cycle2` — onboard の配布テンプレートを変えた前例（CHANGELOG [Unreleased] に記載）

## Test List

### TODO
(none — 全項目を DONE へ移動。scope B で置き換えた項目は DONE に注記)

### WIP
(none)

### DISCOVERED
- `skills/onboard/reference.md:405` の Quick Commands テンプレートが、廃止済みの `for f in tests/test-*.sh` を推奨している（範囲外）
- `rules/plan-discipline.md:36,38` の snapshot 隔離の条項も本体色が強い（範囲外）
- (architect) Codex round 2 の WARN 2 件（TC-01 文言 / E の runner 前提）を反映した版は Codex に再レビューされていない。承認版 hash は Codex が最後に見た版ではない（scope への影響なし、観察のみ）
- (architect) spec Step 8 が plan の Plan Review Record に canonical フィールド（reviewed_plan_hash / review_attempts started・completed / plan_presented）を書き漏らした。再発するなら spec Step 8 側の記録手順に原因がある（範囲外）

### DONE
- [x] TC-01: Given onboard reference の Step 6 / When `local-` の命名規約を探す / Then `.claude/rules/local-` の命名規約と、「通常の同期では `local-*.md` を作成・上書き・削除しない」が同じ行にある（scope B で移行時の例外の文言は削除）
- [x] TC-02（scope B で置き換え）: 旧「移行手順の 4 要素」→ 新: 「差分を表示し」の段落に、`置き換える前に \`local-<name>.md\` へ移す` の連続句と `2-way diff`・`区別できない` がある。Step 6 節に `初回のみ` と `#### ` の小見出しが 0 件
- [x] TC-02b（scope B で削除）: 移行の 3 段手順を削除したため対象なし。順序の契約は新 TC-02 の連続句が引き継ぐ
- [x] TC-02c: `local-` の scope 規約として「`paths:` があれば同じ値」「なければ frontmatter なし（always）」の両方が書かれている
- [x] TC-03: onboard SKILL.md の Step 6 に `local-*.md` の除外があり、100 行未満
- [x] TC-04: codify-insight の Rule Tier Contract に本体/導入先の 2 分岐があり、`` `name` が `dev-crew` ``・`rules/` の有無では判定しない、を連続句で pin（`other-plugin` の変異で FAIL を実測）
- [x] TC-05: spec は `local-plan-discipline.md`、commit は `local-git-conventions.md` の具体名で pin（削除の変異で FAIL を実測）。どちらも 100 行未満
- [x] TC-06: `rules/plan-discipline.md` と mirror の `## 推奨` に `Quick Commands`・`Quick Start`・`run-tests.sh`
- [x] TC-07（負側、強化版）: `## 推奨` の `run-tests.sh` を含む全行が `Quick Commands` か `Quick Start` も含む
- [x] TC-08: `## 具体例` に「dev-crew 本体の例」
- [x] 回帰: test-rules-mirror / test-onboard-research（TC-19）/ test-run-tests-runner（TC-41/43/44）/ test-rules-path-scoping が PASS。full suite 119/119
- [x] RED の条件: 修正前のファイルで FAIL を実測（初回 RED で 14 FAIL、scope B の RED で新 TC-02 の 4 FAIL、確認修正で変異 1 FAIL）

## Implementation Notes

### Goal
導入先独自のルールを、onboard が触らない別ファイル（`.claude/rules/local-<name>.md`）に置く。codify-insight の反映先もそこにする。baseline 手順は「AGENTS.md の Quick Commands」を参照先にして一般化する。

### Background
導入先プロジェクトから届いた実害 2 件。
1. onboard Step 6 は `rules/*.md` を全部 `.claude/rules/` へ identical mirror する（`skills/onboard/reference.md:544,552`, `SKILL.md:76`）。導入先では codify-insight の反映先も同じ mirror ファイルになる（`skills/codify-insight/reference.md:46`）。独自の条項（約 80 行）が mirror に積まれ、次の onboard で上書きされて消えるところだった（手で 3-way 比較して回避）。
2. `rules/plan-discipline.md` の `:23` の推奨と `:46-52` の具体例が `bash run-tests.sh` に固定。この rule は導入先すべてに mirror されるが `run-tests.sh` は本体にしかない。

### Design Approach
- A. 命名は `.claude/rules/local-<name>.md`（フラット prefix）。本体 rule を補足する条項は `local-<本体と同じ名前>.md` とし、本体 rule の scope を写す（`paths:` があれば同じ値、なければ frontmatter なし = always）。対応する本体 rule がない独自 topic は codify-insight の tier 契約どおり `paths:` を付ける。サブディレクトリは Claude Code の再帰読み込み仕様を一次ソースで確認していないため使わない。3-way マージは導入時の版の保存が別に要るため採らない
- B. onboard Step 6: mirror の対象を「`rules/*.md` と同じ名前のファイルだけ」と明記し `local-*.md` は触らない。既存 mirror が本体と異なる場合の移行手順（初回のみ）は、(1) 導入先にだけある行を抽出して提示、(2) `local-<name>.md` へ退避を提案しユーザー承認（なければ同 scope の frontmatter で新規作成、あれば既存の frontmatter と本文を残して末尾に追記し上書きしない）、(3) 退避後に mirror を本体で置き換える（順序を逆にしない）。限界として、2-way diff では「導入先が追記した行」と「上流で削除された行」を区別できないため退避候補はユーザーが仕分ける。TC-19 の契約（`identical mirror` 等）は維持
- C. codify-insight: 本体判定は `.claude-plugin/plugin.json` の `name` が `dev-crew` か（`rules/` の有無では判定しない）。本体は従来どおり `rules/` 正本と `.claude/rules/` mirror に同時適用、導入先（それ以外の全 repo）は `.claude/rules/local-<name>.md` に適用し mirror には書かない
- D. `skills/spec/SKILL.md:73`（plan-discipline）と `skills/commit/SKILL.md:91`（git-conventions）に「`local-` の付いた対のファイルがあれば併せて読む」を既存行の書き換えで追記（行数は増やさない。spec は 97 行、上限 100）
- E. `rules/plan-discipline.md:23` を「Block 0 で、AGENTS.md の Quick Commands（dev-crew 本体では Quick Start）にあるテストコマンドを実行し baseline を実測する。repo に正規 runner があればそれを使い、独自の direct loop を書かない（dev-crew 本体では `bash run-tests.sh`）」に変更。`## 具体例` 見出し直下に「dev-crew 本体の例」と明記し、コードは変えない。onboard テンプレート（`reference.md:405`）の古い direct loop は DISCOVERED。TC-44 の契約（推奨と具体例に `run-tests.sh` が残り、`for f in tests/test-*.sh` がない）は満たす

## Verification

**Real-path invocation を最低 1 件含めること** (rules/integration-verification.md)。

```bash
# 新規契約テスト
bash run-tests.sh tests/test-local-rules-separation.sh   # 全件 PASS

# full suite（baseline と比べ、新規テスト以外に FAIL が増えていない）
bash run-tests.sh

# 回帰
bash run-tests.sh tests/test-rules-mirror.sh
bash run-tests.sh tests/test-onboard-research.sh
bash run-tests.sh tests/test-run-tests-runner.sh
bash run-tests.sh tests/test-rules-path-scoping.sh

# SKILL.md 100 行制約
wc -l skills/spec/SKILL.md skills/commit/SKILL.md skills/onboard/SKILL.md
```

手で確認: onboard Step 6 を読んで、ローカルのファイルが消えないことが追えるか。

Evidence: (orchestrate が自動記入)

## Plan Review Record (pre-approval, 転記元: plan の ## Plan Review Record)

- Codex session: `01a10ae3-695a-7610-8eb7-1e2550aa37c0`
- Round 1: BLOCK
  - BLOCK: 移行時に既存の `local-` を上書きしうる -> 追記・上書き禁止・退避を先に行う順序を B に明記し、TC-02b を追加
  - BLOCK: `rules/` の有無では本体を判定できない -> `.claude-plugin/plugin.json` の `name` で判定（C、TC-04）
  - WARN: always rule（paths なし）と frontmatter 必須が矛盾 -> 「対の scope を写す（paths なしも含む）」（A、TC-02c）
  - WARN: Quick Commands と Quick Start の見出しの揺れ、およびテンプレートの loop -> 両方の見出しを名指しし、正規 runner を優先（E、TC-06）
- Round 2（最終版の再レビュー）: WARN、BLOCK なし
  - WARN: TC-01 が移行時の例外と矛盾していた -> TC-01 を「通常の同期」と「移行時」を区別する形に修正
  - WARN: 「導入先には正規 runner がない」は根拠なし -> 「正規 runner があればテンプレートの loop より優先」に修正
- 未解消の BLOCK: なし

## Progress Log

Format for each phase entry (**strict, required by pre-commit-gate.sh**):

```
### YYYY-MM-DD HH:MM - PHASE_NAME
- [completed action]
- Phase completed
```

### 2026-10-05 16:39 - KICKOFF
- Cycle doc created from plan (compressed-doodling-cake.md)
- Scope definition ready
- codex_mode: no（ユーザー決定済み）
- scope 同梱: 前 cycle doc 4 本の codify gate 更新差分（Scope Definition 参照）を本 cycle の commit に含める
- Phase completed

### 2026-10-05 16:39 - Plan Review (pre-approval)
- codex_session_id: 01a10ae3-695a-7610-8eb7-1e2550aa37c0
- review_attempts:
  - {started: 2026-10-05 16:07, completed: 2026-10-05 16:08, verdict: BLOCK}
  - {started: 2026-10-05 16:09, completed: 2026-10-05 16:09, verdict: WARN}
- findings 要約: Round 1 BLOCK 2 件（local- 上書き / 本体判定基準）と WARN 2 件、Round 2 WARN 2 件（TC-01 矛盾 / runner 前提の根拠なし）。全て plan へ反映済み
- unresolved_blocks: なし
- plan_presented: 2026-10-05 16:10 以降（推定。plan 最終編集 16:10 の直後に ExitPlanMode で提示。正確な提示時刻は未記録）
- reviewed_plan_hash: 113a17853634474e735207e525ba7f8615969dbfc96e93fa02f4b47c1d90316c （承認版 plan の hash。注意: Codex round 2 の後に WARN 2 件を plan へ反映したため、この hash は Codex が最後に見た版ではなく承認版のもの）
- correction (architect, 2026-10-05 16:41): 上の started/completed/plan_presented/reviewed_plan_hash/unresolved_blocks は、sync-plan 転記時点では「(plan Record に記載なし)」「0」だった。spec Step 8 で plan の Plan Review Record に canonical フィールドを書き漏らしたためで、plan は承認後 IMMUTABLE のため直せない。転記欠落として、未 commit の転記エントリを PdM 実測値（Codex session rollout の timestamp、出力ファイル mtime、plan mtime）で補正した。started/completed は実測、plan_presented は推定。hash は architect が正準アルゴリズムで再計算し一致を確認済み
- computed_plan_hash (sync-plan 実測, 正準アルゴリズム): 113a17853634474e735207e525ba7f8615969dbfc96e93fa02f4b47c1d90316c
- verdict: WARN（BLOCK なし）
- Phase completed

### 2026-10-05 16:39 - SYNC-PLAN
- Cycle doc generated: docs/cycles/20261005_1639_local-rules-separation.md
- Plan Review Record transferred (Step 3.5)。hash 一次照合: plan の Record に reviewed_plan_hash の記載がなく照合不能（architect へ報告）
- Test List 11 項目（TC-01, 02, 02b, 02c, 03-08, 回帰, RED 条件）を verbatim 転記
- Phase completed

### 2026-10-05 16:42 - ARCHITECT (Post-Transfer Verification + Design Review Gate)
- 判定: 転記欠落（Plan Review (pre-approval) エントリの started/completed/plan_presented/reviewed_plan_hash/unresolved_blocks）。scope 実質変更なし。Files to Change 9 件は plan と一致（全量尊重、追加・削除なし）
- 補正: 上記エントリを PdM 実測値で補正（spec Step 8 の記録漏れが原因。補正理由は当該エントリの correction 行に記載）。reviewed_plan_hash は plan から正準アルゴリズムで再計算し 113a1785...316c の一致を確認
- 実ファイル突合: spec 97 / commit 91 / onboard 96 行、各参照行（spec:73, commit:91, onboard SKILL:76, codify-insight reference:46, onboard reference:405,544,552, TC-19 at test-onboard-research.sh:210）が plan の記述どおり実在。plugin.json name=dev-crew。rules/plan-discipline.md と .claude/rules mirror は identical
- pre-red-gate.sh 実行: PASS（rc=0）
- Design Review Gate: WARN（Codex round 2 後の反映版が Codex 未再レビュー。DISCOVERED に記録）
- Phase completed

### 2026-10-05 16:45 - RED
- tests/test-local-rules-separation.sh を新規作成（TC-01, 02, 02b, 02c, 03, 04, 05, 06, 07, 08 の 10 ラベル / 17 assertion）。節は awk で先に切り出してから fixed-string grep
- 実測: 単体実行で PASS 3 / FAIL 14。PASS の 3 件は現状でも通る行数チェック（onboard SKILL 96 / spec 97 / commit 91 行、いずれも 100 未満）のみ
- 修正前の FAIL 理由: TC-01〜02c は onboard Step 6 に pin 語が 0 件、TC-03/05 は SKILL に `local-` なし、TC-04 は Rule Tier Contract に 4 語とも 0 件、TC-06 は推奨節に Quick Commands / Quick Start なし（run-tests.sh は既存）、TC-07 は旧文言が 1 件ずつ残存、TC-08 は具体例節に注記なし
- test_count は Test List 11 項目のうち回帰・RED 条件を除くテストファイルのラベル数 10
- Phase completed

### 2026-10-05 16:47 - GREEN
- Files to Change の 8 ファイルを Edit で変更（onboard reference / onboard SKILL / codify-insight reference / spec SKILL / commit SKILL / rules と mirror の plan-discipline / CHANGELOG）。追加・削除なし
- 実測: tests/test-local-rules-separation.sh は PASS 17 / FAIL 0。回帰 5 本（test-rules-mirror / test-onboard-research / test-run-tests-runner / test-rules-path-scoping / test-local-rules-separation）は run-tests.sh 経由で 5/5 PASS。SKILL.md は spec 97 / commit 91 / onboard 96 行のまま
- full suite は未実行（PdM が実行する）
- Phase completed

### 2026-10-05 16:50 - REFACTOR
- skills/onboard/reference.md の local- rules 命名の箇条を修正。独自 topic の `paths:` 必須の記述が always tier（`paths:` なし）と矛盾していたため、「scope は codify-insight の Rule Tier Contract どおりに決める（always は `paths:` なし）」に直した。pin 語は維持
- CHANGELOG と onboard reference の記述（local-<name>.md、退避、ユーザー承認、2-way diff の限界）に食い違いなし。他に重複・命名の不整合なし。plan-discipline は rules/ と .claude/rules/ が byte-identical
- 実測: 回帰 5 本（local-rules-separation / rules-mirror / onboard-research / run-tests-runner / rules-path-scoping）5/5 PASS。full suite は未実行
- Phase completed

### 2026-10-05 17:02 - RED (review mini-iteration, scope B)
- REVIEW 後の scope 判断「B: 移行節を削る」に合わせ tests/test-local-rules-separation.sh を書き直し。移行手順の契約 TC-02/02b/09/10/11/12 を削除し、新 TC-02 に置換（「差分を表示し」と同じ段落に local- への移動案内と 2-way diff の限界「区別できない」、節内に「初回のみ」と `####` 見出しが 0 件）。TC-01/02c/03〜08 は維持（TC-01 は移行手順の文に依存しない）。未使用の line_no helper と pin 語一覧コメントを削除
- 実測: PASS 16 / FAIL 4。FAIL は新 TC-02 の 4 件のみ（doc 未修正のため）。退行実証（一時コピー）: codify-insight の dev-crew を other-plugin に → TC-04 FAIL、spec の local-plan-discipline.md を消す → TC-05 FAIL
- Phase completed

### 2026-10-05 17:03 - GREEN (review mini-iteration, scope B)
- skills/onboard/reference.md: 「既存 mirror に導入先の変更がある場合の移行（初回のみ）」節（見出し、3 段手順、限界段落）を削除。「既存ファイルの更新時は差分を表示し」の段落に、導入先独自の行は置き換え前に local-<name>.md へ移すよう案内し、2-way diff では区別できないので移す行はユーザーが判断する旨を追記。local- rules 節から移行手順への言及とサブディレクトリ不使用の箇条を削除。Step 6 冒頭と差分チェック表の local-*.md 除外記述を「`local-*.md` は対象外（下記 local- rules）」に統一（identical mirror は維持）
- skills/codify-insight/reference.md: 導入先側の理由説明を「onboard reference の local- rules」への参照に置換。判定基準と本体側の適用先は維持
- CHANGELOG.md [Unreleased] Fixed の 1 件目サブ項目を「差分の承認時に local- へ移すよう案内する」に絞った
- 実測: tests/test-local-rules-separation.sh は PASS 20 / FAIL 0。run-tests.sh 経由の回帰 5 本（local-rules-separation / rules-mirror / onboard-research / run-tests-runner / rules-path-scoping）5/5 PASS。full suite は未実行
- Phase completed

### 2026-10-05 17:07 - RED (review confirmation fix)
- tests/test-local-rules-separation.sh TC-02: 「差分を表示し」段落に local- があるだけでは「置き換えた後に移す」へ変えても PASS する穴を塞ぐため、require_line で `置き換える前に \`local-<name>.md\` へ移す` の連続句が同じ行にあることを追加
- 実測: 現 doc で PASS 21 / FAIL 0。mktemp 配下の複製（BASE_DIR 上書き）で該当文を「置き換えた後に」へ変えると TC-02 が FAIL（PASS 20 / FAIL 1）。作業ツリーの doc は未変更。full suite は未実行
- Phase completed

### 2026-10-05 17:09 - REVIEW
- Risk: HIGH score:115（risk-classifier.sh）。Panel: security / correctness / maintainability / test + Codex competitive。入力は PdM が書き出した `git diff HEAD` のファイル（reviewer は git を実行できないため）
- raw severity_counts: security imp1/opt4、maintainability imp3/opt5、test imp2/opt5、correctness imp2/opt6、Codex imp2/opt2（Codex 本文は BLOCK と記載）
- 集計（round 1）: `WARN critical:0 important:7 optional:3 invalid:0`（accept-apply 9 / accept-defer 1 / reject 7）
- Socrates: 「移行の 3 段手順そのものが F1（承認しなかった行が消える）・F2（初回のみは誤り）・F3（行単位の退避は構造を壊す）の発生源。既存の『差分を表示し個別に承認』に退避先の案内を足せば足りる」と反論し、判定を覆すべきと主張
- 規模の判断: 指摘に応えると移行節が膨らむため、ユーザーに選択を求めた → **B: 移行節を削る**を選択。F1〜F3 と Codex の移行関連指摘は対象ごと消滅。F4（local- で本体の安全規則を緩められる）は記載先が実行時に読まれず実害の記録もないため reject
- mini-iteration: RED（移行 TC 削除、TC-04/05 を具体値で強化、変異で FAIL を実証）→ GREEN（移行節削除、重複の削減、CHANGELOG の短縮）
- Codex 確認 1 回（予算上限）: critical 1 件 — TC-02 が「置き換える前に移す」の順序を pin していない → 連続句で pin し、順序を逆にした変異で FAIL を実証（17:07 RED エントリ）。予算上限のため再レビューは回さない
- full suite: 119/119 PASS（scope B 適用後、TC-02 修正前に実測）
- Phase completed

### 2026-10-05 17:09 - DISCOVERED
- `skills/onboard/reference.md:405` の古いテンプレート → issue #247 にコメントで追記（同じ根の問題）
- `rules/plan-discipline.md:36,38`、`skills/onboard/validation.md:13`（導入先にない test-rules-mirror.sh を参照）、導入先の always tier の歯止め（REVIEW F10） → issue #257
- (architect) 承認版が Codex 再レビュー前の版 → reject（観察のみ。承認前の WARN 反映は Step 8 の手順どおり）
- (architect) spec Step 8 の Plan Review Record 記録漏れ → reject（pre-red-gate が決定論的に検出する設計で、今回も sync-plan の段階で検出された。1 回目）
- Phase completed

### 2026-10-05 17:25 - COMMIT
- pre-commit-gate PASS。Test List を DONE へ移動（scope B で置き換え・削除した TC は注記）。STATUS.md の Completed に追記
- 同梱: Block 0 codify gate で更新した前 cycle doc 4 本
- 注記: REVIEW / DISCOVERED の見出し時刻は当初実測なしで 17:10 と書き、date 実測（17:09）に訂正した
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

### Insight 1: plan review の問いに削除方向がなく、要らない手順を硬くした

- **Failure**: plan review を「穴を探せ」だけで依頼した。round 1 の BLOCK 2 件はどちらも移行の 3 段手順を前提にした指摘で、PdM は手順を削らずに硬くする方向で応えた（追記・上書き禁止・順序の明記、TC-02b の追加）。REVIEW では、その手順から F1〜F3 が生まれた
- **Final fix**: REVIEW の依頼に削除方向の問いを入れ、Socrates に「もっと単純な代案は成立するか」を問わせた。実害が出かけたときに欠けていたのは「退避先」と「onboard が退避先を触らない保証」だけで、既存の「差分を表示し個別に承認」で足りると判明した。移行節を削ると、差分は縮み、指摘の半分は対象ごと消えた
- **Insight**: 新しい手順を足す plan では、「実害の場面で実際に欠けていたものは何か」と「既存の手順で足りないか」を plan review の問いに含める。削除方向の問いは REVIEW だけでなく plan review にも要る

### Insight 2: 消失を防ぐ手順が、拒否経路で同じ消失を起こしていた

- **Failure**: 「行を退避してから置き換える」手順は、ユーザーが退避を承認しなかった場合の出口を持たず、そのまま置き換えに進めば行が消える形だった（F1）。plan review・RED・GREEN・REFACTOR を通って REVIEW まで残った
- **Final fix**: 手順ごと削除した（Insight 1）
- **Insight**: 承認を挟む保護手順を足すときは、各承認ステップの「拒否・一部承認」の経路を列挙し、その経路で守りたいものが失われないかを確かめる。正常系だけの契約テストでは見えない

### Insight 3: 文言を pin する契約テストは、順序や値を入れ替えた変異で通る

- **Failure**: 初版のテストは単語の存在で pin しており、手順の順序を入れ替える・判定対象を `other-plugin` に変える・Read 指示を消してコメントだけ残す、の変異で全部 PASS した（Codex が変異を入れて実測）。scope B の後も TC-02 は「置き換えた後に移す」で通った
- **Final fix**: 主張にしか現れない連続句（`置き換える前に \`local-<name>.md\` へ移す`、`` `name` が `dev-crew` ``、具体的なファイル名）で pin し、一時コピーで変異を入れて FAIL を実測した
- **Insight**: doc 契約テストは、守りたい主張の「反転」（順序の逆転・値の差し替え・削除して痕跡だけ残す）を変異として当て、FAIL を実測してから確定する

### 想起漏れ

- **設問**: 今回の手戻りは、過去のどの cycle doc を最初に読んでいれば防げたか
- **回答**: docs/cycles/20260916_1634_shrink-runner-remove-nesting.md
