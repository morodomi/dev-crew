---
feature: skill-script-base-paths
cycle: 20261111_1105
phase: DONE
complexity: standard
test_count: 12
risk_level: medium
retro_status: resolved
codex_session_id: 01a1c84d-0970-7d81-bc50-6bf19afb8da4
codex_mode: no
plan_file: /Users/morodomi/.claude/plans/sparkling-dreaming-bengio.md
created: 2026-11-11 11:05
updated: 2026-11-12 10:51
---

# skill が呼ぶ本体スクリプトを Base directory からの相対にする（#292 を広げる）+ 引用符付き plan_file

## Scope Definition

### In Scope

- [ ] skill 文書の呼び出しを Base directory からの相対にする（パターンは 1 つ）: `bash scripts/gates/<name>.sh` → `bash "<orchestrate の Base directory>/../../scripts/gates/<name>.sh"`
  - [ ] `skills/orchestrate/steps-subagent.md`・`steps-codex.md`・`steps-teams.md`: pre-red-gate、worktree-fingerprint（各 3 か所）、finding-in-diff
  - [ ] `skills/orchestrate/SKILL.md:93`: COMMIT の pre-commit-gate に呼び出しの形を足す（同じ行の中で。行数は 98 のまま）
  - [ ] `skills/spec/SKILL.md:87`・`reference.md:583`・`reference.ja.md:523`: recall-candidates（`<spec の Base directory>`）。spec の SKILL.md は 97 行のまま
  - [ ] `skills/red/SKILL.md:68`・`reference.md:339`: exspec-check（`<red の Base directory>`）
  - [ ] `skills/learn/SKILL.md:48`: tfidf-summary（`<learn の Base directory>`）
  - [ ] `skills/review/steps-subagent.md:21,122,158`: `bash skills/review/risk-classifier.sh` / `severity-verdict.sh`（skill の中にあるスクリプト）→ `bash "<review の Base directory>/<name>.sh"`。agents/*-reviewer.md の `skills/review/severity-verdict.sh` は「集計する」という説明だけなので変えない
  - [ ] Base directory が表示されない経路（agent が reference を直接読む場合）では「その文書がある skill のディレクトリ」と読む旨を、#291 の注記（`skills/spec/reference.md:17`）と同じく各文書の最初の出現に 1 回だけ書く
- [ ] `scripts/gates/pre-red-gate.sh:245`: 値の両端が同じ引用符（`"…"` または `'…'`）のときだけ外す。片側だけの引用符は外さず、今までどおり BLOCK
- [ ] 既存テストの逆向き契約の更新: `tests/test-adversarial-review.sh` TC-27 が `bash scripts/gates/finding-in-diff.sh` の文字列を固定しているので、新しい形に合わせる
- [ ] 新しい契約テスト `tests/test-skill-script-paths.sh`
- [ ] `tests/test-reviewer-scoring.sh` TC-12 の検索を引用符付きの呼び出しにも一致させる（Plan Review attempt 2 の指摘。RED で対応）
- [ ] CHANGELOG `[Unreleased]`

### Out of Scope

- 導入先で pre-red-gate が実行されていない疑い（実行記録がほぼ無い）の調査 (Reason: 原因が相対パスかは未確認。この修正の後に導入先の記録で見る。DISCOVERED)
- `rules/integration-verification.md:35` の `bash scripts/gates/pre-commit-gate.sh` (Reason: dev-crew 本体の中の検証の例として書かれているので、相対のままで正しい)
- `skills/onboard` が導入先に `scripts/` を配る案 (Reason: plugin を参照させる #247 の方向と逆になる)
- 計測で見つかった他の不具合（一時ファイルの後片付け、codex_mode の既定値、override の書式など） (Reason: 別の issue)

### Files to Change (target: 10 or less)

- skills/orchestrate/steps-subagent.md (edit)
- skills/orchestrate/steps-codex.md (edit)
- skills/orchestrate/steps-teams.md (edit)
- skills/orchestrate/SKILL.md (edit)
- skills/spec/SKILL.md, reference.md, reference.ja.md (edit)
- skills/red/SKILL.md, reference.md (edit)
- skills/learn/SKILL.md (edit)
- skills/review/steps-subagent.md (edit)
- scripts/gates/pre-red-gate.sh (edit)
- tests/test-adversarial-review.sh (edit, TC-27)
- tests/test-pre-red-gate.sh (edit, TC を追加)
- tests/test-skill-script-paths.sh (new)
- tests/test-reviewer-scoring.sh (edit, TC-12。Plan Review attempt 2 で追加)
- CHANGELOG.md (edit)

文書の編集は 1 パターンの置き換えで、ファイル数は 10 を超えるが規模は小さい。既存の `bash` 呼び出しの置き換えが 23 か所（scripts/ 20 + skills/review 3）、パスなしの指示を呼び出しの形にするものが 2 か所（red SKILL.md:68、orchestrate SKILL.md:93）。

## Environment

### Scope
- Layer: Backend（plugin の skill 文書 + bash gate）
- Plugin: なし（dev-crew 本体。bash のテスト `bash run-tests.sh`）
- Risk: 30 (WARN)

### Runtime
- Language: bash 3.2（macOS 既定）/ zsh

### Dependencies (key packages)
- git, awk, sed, shasum
- jq: tfidf-summary.sh が非空ログで使う

### Risk Interview (BLOCK only)
(none: verdict は WARN)

WARN 確認（自己回答）:
- 影響: pre-red-gate の plan_file の読み取りは信頼境界（(v) `$HOME/.claude/plans` 配下の絶対パスに限る）の直前にある。引用符を外す処理は境界検査より前に置き、外した後の値に境界検査をそのままかける。境界検査の順序と条件は変えない
- 既存の動き: 引用符なしの plan_file の扱いは変えない

## Context & Dependencies

### Reference Documents
- skills/spec/reference.md:17 - #291 の Base directory 注記（同じ形に揃える）
- skills/onboard/SKILL.md Step 6 - 導入先に配られるのは rules と hooks だけ
- CONSTITUTION.md - 決定論的ゲートは残す方向（フロー再設計「前と後は固める」）と矛盾しない。gate が導入先で確実に動くようにする変更
- ROADMAP / NEXT.md - 手順 2・3 とは独立。計測の結果から優先した保守

### Dependent Features
- pre-approve-gate (#291): 同じ `<X の Base directory>/../../scripts/gates/...` の形を先行して採用
- scripts/gates/pre-red-gate.sh の信頼境界 (v)

### Related Issues/PRs
- Issue #292: 既存の相対呼び出し（worktree-fingerprint / pre-red-gate / finding-in-diff / exspec-check）。今回 recall-candidates.sh・pre-commit-gate.sh・tfidf-summary.sh・review の 2 スクリプトまで広げる
- Issue #291 / PR #293: pre-approve-gate
- Ambiguity Resolution: Scope は「#292 を広げて直す」をユーザーが選択（2026-11-11）。書き方は #291 と同じ `bash "<X の Base directory>/../../scripts/..."`。シェル変数にまとめる案は採らない（Claude Code の Bash 呼び出しは変数を次の呼び出しへ持ち越さない）

## Recall

### docs/cycles/20261104_1025_pre-approve-gate.md
- **何が起きたか**: 新しい gate を既存と同じ相対パスで呼ぶ plan が、承認前の Codex review で「導入先に scripts/gates が無い」と BLOCK された。Base directory からの相対に直し、既存の呼び出しは #292 に回した。REVIEW で、`cd "$(dirname "$0")"` が CDPATH を export した環境でパスを 2 行出して退行した
- **当時の前提**: skill の起動時に Base directory が表示され、モデルがそれを手順の `<X の Base directory>` に当てはめる
- **今回も同じ前提か**: Yes。ただし orchestrate の steps-*.md と red の reference.md は、agent や Codex が直接読む経路がある。Base directory が表示されない経路での読み方を注記する。スクリプト側のパス解決は変えないので、CDPATH の問題は増えない

### docs/cycles/20261028_1047_review-fixer-location-check.md
- **何が起きたか**: TC-31 は行単位で句を探していたので、説明文に同じ句があると起動文字列から句を消しても PASS した。変異がコメントを書き換えていて「未検出」と誤読しかけた
- **当時の前提**: 説明文と起動の文字列が同じ行に並ぶ
- **今回も同じ前提か**: Yes。`steps-*.md` の finding-in-diff は説明文の行の中にある。TC-02 は、説明文の言及（パスなしの `scripts/gates/...`）ではなく `bash "<` で始まる呼び出しの文字列そのものを切り出して検査する。変異は、置き換え元がコードにしか無い文脈であることを grep で確かめてから入れる

### docs/cycles/20261016_1645_adversarial-review-triage.md
- **何が起きたか**: worktree-fingerprint.sh を導入した。git の clean filter などで変更を隠せる抜け道を REVIEW で直した
- **当時の前提**: fingerprint は呼び出し元の cwd の git の作業ツリーを見る
- **今回も同じ前提か**: Yes。呼び出しのパスだけ変え、cwd は導入先の repo のまま。TC-04 で、本体の外の repo を cwd にして動くことを確かめる

### docs/cycles/20260717_1126_approval-reorder.md
- **何が起きたか**: Plan Review Record と plan_file の hash による同一性の保証を入れ、pre-red-gate を硬化した（信頼境界 (v)）
- **当時の前提**: plan_file は sync-plan が引用符なしの絶対パスで書く
- **今回も同じ前提か**: No。導入先では sync-plan が引用符付きで書いた実例がある。引用符を外したうえで (v) をそのままかける

## Test List

### TODO
(none)

### DONE

`tests/test-skill-script-paths.sh`（新規）:

- [ ] TC-01: Given skills/ 配下の全 .md, When `bash ` の直後に引用符なしの `scripts/` または `skills/` が続く行を探す, Then 0 件（相対パスの呼び出しが残っていない）
- [ ] TC-02: Given 一覧の呼び出し箇所（orchestrate の steps 3 ファイル × pre-red-gate・worktree-fingerprint・finding-in-diff、spec 3 文書の recall-candidates、red 2 文書の exspec-check、learn の tfidf-summary、orchestrate SKILL.md の pre-commit-gate、review steps-subagent の risk-classifier・severity-verdict）, When 各文書を読む, Then それぞれ `bash "<S の Base directory>/…<name>.sh"` を含み、S はその文書がある skill の名前と一致する
- [ ] TC-03: Given TC-02 で見つけた各呼び出し, When `skills/<S>/` を起点に `…` の部分を本体の中で解決する, Then 実在するファイルを指す（`../` の段数やスクリプト名の誤りを捕まえる）
- [ ] TC-04: Given 本体の外に作った一時 git repo（scripts/ が無い。初期 commit と、`Cycle-Doc:` トレーラー付きで fixture 固有の Cycle doc と問い合わせ対象ファイルを一緒に入れた commit を持つ）を cwd にする, When TC-03 で解決したパスで recall-candidates.sh（root に `.`、問い合わせ対象ファイルを引数）と worktree-fingerprint.sh を実行する, Then recall は fixture 固有の Cycle doc を候補に返し、fingerprint は fixture のファイルを書き換える前後で値が変わる（本体の repo を見る誤実装では落ちる）
- [ ] TC-05: Given orchestrate の steps 3 ファイル, When REVIEW 節を読む, Then 3 ファイルとも同じ形の呼び出しを持つ（モード間で揃っている）

`tests/test-pre-red-gate.sh`（追加。番号は RED で実装の最大値を実測して決める）:

- [ ] TC-Q1: Given plan_file が `"…"` で囲まれた、他は PASS する Cycle doc, When gate を流す, Then PASS（修正前は BLOCK「missing or unreadable」）
- [ ] TC-Q2: Given plan_file が `'…'` で囲まれている, When gate を流す, Then PASS
- [ ] TC-Q3: Given PASS fixture の実在する信頼ディレクトリ内の plan_file に、開始の引用符だけを付けた値（`"/…/plan.md`）, When gate を流す, Then BLOCK（片側の引用符まで外す誤実装なら PASS になるので、変異を検出できる）
- [ ] TC-Q4: Given 引用符付きで信頼ディレクトリの外を指す plan_file, When gate を流す, Then 信頼境界の BLOCK（引用符を外しても境界検査が効く）
- [ ] TC-Q5: Given 引用符なしの plan_file（既存の PASS fixture）, When gate を流す, Then 今までどおり PASS

`tests/test-adversarial-review.sh`:

- [ ] TC-27（更新）: Given 固定文字列を新しい形に更新, When orchestrate の steps 3 ファイルを読む, Then 3 ファイルとも、finding-in-diff.sh の呼び出しが「「直す」が 0 件なら修正役を起動せず」より前の同じ行にある

`tests/test-reviewer-scoring.sh`（Plan Review attempt 2 の指摘で追加。番号は既存の TC-12 を更新）:

- [ ] TC-12（更新）: Given review の呼び出しが `bash "<review の Base directory>/severity-verdict.sh" verdict` の引用符付きになった, When TC-12 が `severity-verdict\.sh"? verdict` で実呼び出しを検索する, Then 引用符付きの呼び出しにも一致し、実呼び出しから `--invalid` を除く変異で FAIL する（説明文の一致では PASS しない）

### DISCOVERED
- 導入先で pre-red-gate の実行記録がほとんど無い（plan の Out of Scope）→ issue #295
- REVIEW P3-2: skills/red/reference.md:374 の再実行がスクリプト名だけ → 起票しない。実害の記録が無く、341 行の呼び出しの形を引き継ぐと読める。導入先で相対パスに組み立て直された記録が出たら直す
- REVIEW P3-3: Base directory が当てはめられないと rc=127 になり、steps-*.md に扱いが無い → 起票しない。修正前の相対パスでも同じで悪化ではなく、実害の記録も無い。#295 の確認で 127 の記録が出たら一緒に扱う
- REVIEW P3-1: 閉じ引用符の後ろの空白・CR → 起票しない。安全側の BLOCK で、末尾空白・CR は変えないと plan で決めた範囲
- 記録の乱れ: GREEN の Test List 遷移が見出しの入れ替えで行われた → 起票しない（この cycle の記録だけの問題）

### WIP
(none)

### 変異で確かめること（REFACTOR 後）

- 1 か所だけ相対パスに戻す → TC-01 が落ちる
- `<orchestrate の Base directory>` を `<spec の Base directory>` に変える → TC-02 が落ちる
- `../../` を `../` にする → TC-03 が落ちる
- pre-red-gate の引用符の処理を消す → TC-Q1/Q2 が落ちる
- 両側一致の条件を片側に緩める → TC-Q3 が落ちる
- review の実呼び出しから `--invalid` を除く → test-reviewer-scoring.sh TC-12 が落ちる

## Implementation Notes

### Goal

導入先で、skill が呼ぶ本体スクリプトがすべて解決できるようにする。引用符付きの plan_file も受け付ける。

### Background

skill の手順は本体のスクリプトを `bash scripts/gates/<name>.sh` の相対パスで呼んでいる。dev-crew 本体の作業ツリーでは動くが、導入先の repo には `scripts/` が無い（onboard が配るのは rules と hooks だけ。`skills/onboard/SKILL.md` Step 6）。#291 で新しい pre-approve-gate だけは `<spec の Base directory>/../../scripts/gates/...` の形にしたが、既存の呼び出しは範囲外として残した（#292）。

2026-11-11 に事業側の Cycle doc 112 件（v2.20.0 以降に更新）を読んで計測した結果:

- `scripts/recall-candidates.sh` が「このリポジトリに無い」となった記録が 2 件（導入先の 1 リポジトリ、2 cycle）。実害あり
- gate 本体が見つからずに失敗した記録は 0 件。ただし pre-red-gate の実行記録自体がほとんど無い（26 件中 0 件、10 件中 0 件の群がある）。黙って飛ばされている可能性があるが未確認
- pre-commit-gate は、skill のどこにもパス付きの呼び出しが無い（`skills/orchestrate/SKILL.md:93` は名前だけ）
- 別の不具合: frontmatter の `plan_file` が引用符付きだと pre-red-gate が BLOCK した（1 件。PdM が委譲 prompt に「引用符なし」と書いて回避を続けている）

引用符の不具合は実測で再現済み:

```
$ printf -- '---\nplan_file: "/Users/x/.claude/plans/a.md"\n---\n' | awk '/^---$/{c++;next} c==1{print}' | grep '^plan_file:' | head -1 | sed 's/^plan_file: *//'
"/Users/x/.claude/plans/a.md"
```

`scripts/gates/pre-red-gate.sh:245` の `sed` が引用符を残すので、続く `[ ! -f "$plan_file" ]` で「missing or unreadable」の BLOCK になる。

実測した呼び出しの一覧（grep literal）:

```
$ grep -rnE "bash [^ ]*scripts/" skills agents rules --include='*.md'
skills/learn/SKILL.md:48           tfidf-summary.sh
skills/spec/reference.ja.md:523    recall-candidates.sh
skills/spec/SKILL.md:87            recall-candidates.sh
skills/spec/reference.md:583       recall-candidates.sh
skills/red/reference.md:339        exspec-check.sh
skills/orchestrate/steps-subagent.md:117,188,189,195,201   pre-red-gate / worktree-fingerprint x3 / finding-in-diff
skills/orchestrate/steps-codex.md:52,130,131,137,143        同上
skills/orchestrate/steps-teams.md:139,232,233,240,246       同上
rules/integration-verification.md:35   pre-commit-gate.sh（本体内の例。対象外）
skills/careful/SKILL.md:10         ${CLAUDE_PLUGIN_ROOT} 付き（対象外、すでに解決できる）

$ grep -rnE "bash skills/[a-z-]+/[a-z-]+\.sh" skills --include='*.md'   # Codex review attempt 1 の指摘で追加
skills/review/steps-subagent.md:21,122,158   risk-classifier.sh / severity-verdict.sh x2
```

パスなしの言及で実行を指示しているもの: `skills/red/SKILL.md:68`（exspec-check）、`skills/orchestrate/SKILL.md:93`（pre-commit-gate）。説明だけのもの（`agents/sync-plan.md:191`、`agents/adversarial-reviewer.md:36`、`skills/spec/reference.md:47,574` など）は変えない。

スクリプト側は呼び出し元の cwd の git を見る（`finding-in-diff.sh:41`、`worktree-fingerprint.sh:64` は `git rev-parse --show-toplevel`。`recall-candidates.sh` は引数で project root を取る。`pre-red-gate.sh:282` は兄弟の plan-hash.sh を `$0` から `CDPATH= cd` で解決）。呼び出しのパスを変えても、スクリプトの中身を変える必要はない。

逆向き契約の確認:

```
$ grep -rnE "bash scripts/(gates/)?[a-z-]+\.sh" tests/*.sh   # 文書の文字列を固定しているもの
tests/test-adversarial-review.sh:1005  line_ordered "$body" "bash scripts/gates/finding-in-diff.sh" ...   ← 更新する
tests/test-recall-candidates.sh:331    grep -cF "recall-candidates.sh"   ← 名前の部分一致なので新しい形でも通る
tests/test-adversarial-review.sh:264   check_steps_review_has ... "worktree-fingerprint.sh"   ← 同上
```

### Design Approach

呼び出しの形（#291 の `skills/spec/reference.md:17` と同じ）:

```
bash "<orchestrate の Base directory>/../../scripts/gates/pre-red-gate.sh" "$CYCLE_DOC"
before=$(bash "<orchestrate の Base directory>/../../scripts/gates/worktree-fingerprint.sh"); before_rc=$?
```

pre-red-gate の引用符の扱い（245 行の後、`[ -z ]` 判定の前）:

```bash
case "$plan_file" in
  \"*\") plan_file=${plan_file#\"}; plan_file=${plan_file%\"} ;;
  \'*\') plan_file=${plan_file#\'}; plan_file=${plan_file%\'} ;;
esac
```

1 文字の `"` だけの値は、両側の一致にならないよう長さ 2 以上を条件にする（RED で境界を固定する）。末尾の空白・CR の扱いは今と同じ（変えない）。

## Verification

**Real-path invocation を最低 1 件含めること** (rules/integration-verification.md)。

```bash
bash run-tests.sh tests/test-skill-script-paths.sh
bash run-tests.sh tests/test-pre-red-gate.sh
bash run-tests.sh tests/test-adversarial-review.sh
bash run-tests.sh tests/test-reviewer-scoring.sh
bash run-tests.sh            # 全体（baseline は Block 0 で実測）
wc -l skills/*/SKILL.md | awk '$1 > 100 && !/total/'   # 空であること
grep -rnE 'bash scripts/' skills --include='*.md'      # 0 件
```

Evidence: (orchestrate が自動記入)

## Progress Log

Format for each phase entry (**strict, required by pre-commit-gate.sh**):

```
### YYYY-MM-DD HH:MM - PHASE_NAME
- [completed action]
- Phase completed
```

### 2026-11-11 11:05 - KICKOFF
- Cycle doc created
- Scope definition ready

### 2026-11-11 11:05 - Plan Review (pre-approval)
- codex_session_id: 01a1c84d-0970-7d81-bc50-6bf19afb8da4
- review_attempts:
  - {started: 2026-11-11 10:50, completed: 2026-11-11 10:53, verdict: WARN}
  - {started: 2026-11-11 10:54, completed: 2026-11-11 10:55, verdict: WARN}
- findings 要約: attempt 1（WARN。重要 2・軽微 2）: skills/review/steps-subagent.md の `bash skills/review/*.sh` 3 か所が漏れている / TC-04 が exit 0 だけでは導入先の repo を見たことを保証しない（fixture 固有の候補と fingerprint の変化を見る、recall はファイル引数と commit が要る）/ TC-Q3 は実在するパスに開始の引用符だけを付けないと変異を検出できない / 件数のずれと jq の依存の抜け → 全て反映。attempt 2（WARN、P2 1 件）: review の呼び出しを `bash "<review の Base directory>/severity-verdict.sh" verdict` にすると、`tests/test-reviewer-scoring.sh` TC-12 の検索 `severity-verdict\.sh verdict` が実呼び出しに一致しなくなり、`--invalid` が消えても説明文の一致で PASS する → 再レビューは 1 回までなので plan 本文は変えず、ここに記録して RED で対応する: TC-12 の検索を引用符付きの呼び出し（`severity-verdict\.sh"? verdict`）にも一致させ、実呼び出しから `--invalid` を除く変異で FAIL することを確かめる。Files to Change に `tests/test-reviewer-scoring.sh` を加える
- unresolved_blocks: なし
- plan_presented: 2026-11-11 10:56
- reviewed_plan_hash: b0962c1daa38d26c07e251e2ef91ca87f73b3cd3f3df6fd93fb9a7ab32b7ea68
- verdict: WARN
- Phase completed

### 2026-11-11 11:05 - SYNC-PLAN
- Cycle doc generated from plan (Test List 12 items, Plan Review Record transferred)
- Phase completed

### 2026-11-11 11:06 - ARCHITECT (Post-Transfer Verification + Design Review Gate)
- Post-Transfer Verification: PASS。Plan Review Record の全フィールド（codex_session_id / plan_file / review_attempts 2 件 / findings 要約 / reviewed_plan_hash / plan_presented / verdict / unresolved_blocks）が frontmatter と Progress Log の `Plan Review (pre-approval)` に転記済み。転記欠落なし。Files to Change は plan の全量 + tests/test-reviewer-scoring.sh（attempt 2 で承認前に記録済み、scope 変更ではない）。test_count 12 = TC-01..05 + TC-Q1..Q5 + TC-27 + TC-12 で一致
- real-path: `bash scripts/gates/pre-red-gate.sh <cycle_doc>` → PASS (rc=0)
- 実ファイル突合: pre-red-gate.sh:245（sed `s/^plan_file: *//` が引用符を残す）と :282（plan-hash.sh を CDPATH= cd で解決）、test-adversarial-review.sh:1005（TC-27 の固定文字列）と :264、test-reviewer-scoring.sh:367（`severity-verdict\.sh verdict` 検索）、review/steps-subagent.md:21,122,158、orchestrate steps-* の呼び出し行（subagent 117,188,189,195,201 / codex 52,130,131,137,143 / teams 139,232,233,240,246）、spec SKILL.md:87・reference.md:583・reference.ja.md:523、red reference.md:339、learn SKILL.md:48、finding-in-diff.sh:41、worktree-fingerprint.sh:64 は全て実在し内容一致。置き換え 23 か所（scripts/ 20 + review 3）の件数も一致。orchestrate SKILL.md 98 行・spec SKILL.md 97 行（同一行内の置換で維持可能）。解決先 scripts/recall-candidates.sh・scripts/tfidf-summary.sh・scripts/gates/{exspec-check,pre-red-gate,worktree-fingerprint,finding-in-diff,pre-commit-gate}.sh は実在
- Design Review Gate: WARN。Scope: Files to Change が 17 ファイル（目標 10 以下）。plan 本文が 1 パターン置換で小規模と明記しており YAGNI 違反ではない。Architecture: 呼び出し形は #291（spec reference.md:17）と一致、引用符処理は境界検査 (v) の前に置く設計で整合。Test List: 正常系・境界（片側引用符 Q3）・異常系（境界外 Q4）・既存挙動（Q5）を網羅、変異対応あり。Risk: 30 (WARN) は pre-red-gate の信頼境界直前の変更と整合
- scope 実質変更: なし（再承認不要）
- 観察（DISCOVERED 候補、scope 影響なし）: (1) test-pre-red-gate.sh の既存 TC 命名は TC-R* で最大 TC-R16。plan の TC-Q* は RED で最大値を実測して採番すること (2) rules/integration-verification.md:35 の `bash scripts/gates/pre-commit-gate.sh` は Out of Scope どおり残るため、Verification の `grep -rnE 'bash scripts/' skills` は skills のみ対象で 0 件になる想定と整合 (3) steps-* の finding-in-diff 呼び出しは長い説明行内にあるため、TC-02 は行全体でなく `bash "<` で始まる文字列を切り出す設計（Recall どおり）を RED で守ること
- Phase completed

### 2026-11-11 11:09 - PdM 判断（Block 1 境界）
- architect WARN（ファイル数のみ）→ 自動進行
- codex_mode: no（ユーザー選択 2026-11-11。RED/GREEN は red-worker / green-worker、Gate 1/2 は PdM が実行）
- Baseline: `bash run-tests.sh` → PASS 123 / FAIL 0
- Phase completed

### 2026-11-11 11:13 - RED
- 作成: tests/test-skill-script-paths.sh（新規。TC-01〜TC-05。TC-02 は `bash "<` で始まる呼び出しの文字列を grep -o で切り出し、期待の形と全文一致を検査）
- 追加: tests/test-pre-red-gate.sh に TC-R17(a)〜(e)（既存の最大は TC-R16 を実測）。対応: (a)=TC-Q1 / (b)=TC-Q2 / (c)=TC-Q3 / (d)=TC-Q4 / (e)=TC-Q5
- 更新: tests/test-adversarial-review.sh TC-27（固定文字列を新しい形へ）、tests/test-reviewer-scoring.sh TC-12（検索を `severity-verdict\.sh"\{0,1\} verdict` にし、steps-subagent.md の `bash "<` を含む実呼び出し行が 1 本以上一致することも assert）
- FAIL の確認（修正前）: test-skill-script-paths.sh は 5 TC 全て FAIL（TC-01 は相対呼び出し 23 行が残る、TC-02〜05 は `bash "<` の呼び出しが無い）/ test-pre-red-gate.sh は TC-R17(a)(b)(d) が FAIL（`plan_file is missing or unreadable`）、(c)(e) は修正前でも PASS / TC-27 FAIL / TC-12 FAIL（実呼び出し行が無い）
- 非 vacuous の確認: 本体の外の複製（scratchpad）で skills の呼び出しだけ新しい形に変えると TC-01・TC-04・TC-05 が PASS、複製に残した名前だけの 2 か所（orchestrate SKILL.md・red SKILL.md）だけ TC-02/03 が FAIL。TC-04 は解決したパスで本体の外の repo に対し動く
- Phase completed

### 2026-11-11 11:17 - GREEN
- 変更: skills/orchestrate/steps-{subagent,codex,teams}.md（pre-red-gate・worktree-fingerprint 3 か所・finding-in-diff を `bash "<orchestrate の Base directory>/../../scripts/gates/<name>.sh"` に。pre-red-gate の直前に Base directory 注記を 1 回）、orchestrate/SKILL.md:93（pre-commit-gate の呼び出しを同じ行に。行数は増やさない）、spec SKILL.md・reference.md・reference.ja.md（recall-candidates）、red SKILL.md・reference.md（exspec-check。reference.md に注記）、learn SKILL.md（tfidf-summary）、review/steps-subagent.md（risk-classifier・severity-verdict validate/verdict。`--invalid` は維持。注記 1 回）
- 変更: scripts/gates/pre-red-gate.sh（plan_file の両端が同じ引用符のときだけ外す。片側のみは外さない。(v) の順序・条件は不変。ヘッダコメントに 1 行足した）、CHANGELOG.md [Unreleased] Fixed 2 項目
- spec reference.md・reference.ja.md は #291 の注記（17 行目付近）が既にあるので追加の注記は書かなかった。orchestrate/spec/red/learn の SKILL.md は行数を増やさないため注記なし
- テスト: test-skill-script-paths.sh・test-pre-red-gate.sh・test-adversarial-review.sh・test-reviewer-scoring.sh 全て PASS。`bash run-tests.sh` 全体 PASS 124 / FAIL 0。SKILL.md 100 行超なし、`bash (scripts|skills)/` の残り 0 件
- Test List: 全 12 項目を WIP から DONE へ移した（見出しの入れ替えのみ。文面は不変）
- Phase completed

### 2026-11-11 11:23 - REFACTOR
- Gate 2（PdM 実測）: `bash run-tests.sh` → PASS 124 / FAIL 0
- チェックリスト 7 項目: 変更は呼び出しの置き換えと 6 行の case のみで、共通化・定数化の対象なし。新規テストは `bash -n` で構文 OK（shellcheck は未導入）
- 変異（本体の外の git 複製で Edit により注入、確認後 `git checkout` で戻した）: 相対パスに戻す → TC-01 FAIL / `<orchestrate の Base directory>` を `<spec の …>` に → TC-02・TC-05 FAIL / exspec の `../../` を `../` に → TC-02・TC-03 FAIL / review の verdict 呼び出しから `--invalid` を除く → test-reviewer-scoring TC-12 FAIL / 引用符の処理を消す → TC-R17(a)(b)(d) FAIL / 両側一致を片側に緩める → TC-R17(c) FAIL。6/6 検出
- 記録の乱れ（DISCOVERED 候補）: GREEN の Test List 遷移が見出しの入れ替えで行われ、節の並びが TODO・DONE・DISCOVERED・WIP になり、DONE の項目が `[ ]` のまま
- Phase completed

### 2026-11-11 11:24 - VERIFY
- real-path: 本体の外の git repo（scripts/ が無い）を cwd にして `bash "<dev-crew>/skills/orchestrate/../../scripts/gates/worktree-fingerprint.sh"` → 64 桁 hex、rc=0。`bash "<dev-crew>/skills/spec/../../scripts/recall-candidates.sh" . README.md` → rc=0（候補 0 件）
- SKILL.md 100 行超なし。`bash (scripts|skills)/` の残り 0 件
- Phase completed

### 2026-11-11 11:27 - REVIEW
- Codex review: 失敗（利用上限。15:19 まで使えない）。adversarial-reviewer で代行: 直す 0 / 人間に戻す 0 / 記録のみ 3
- 作業ツリー: worktree-fingerprint の前後一致（16c42175…5937、rc=0 両方）
- 指摘: P1 0 / P2 0 / P3 3。直すが 0 件なので修正役は起動していない。P3 は PdM が記録のみとして数えた（`/tmp/dev-crew-review-20261111_1105/review.md`）
  - P3-1 pre-red-gate.sh:250-253 閉じ引用符の後ろの空白・コメント・CR、コロンの後のタブでは引用符を外さず BLOCK（再現済み、安全側。末尾空白・CR は変えないと plan で決めた範囲の外）
  - P3-2 skills/red/reference.md:374 BLOCK 時の再実行がスクリプト名だけ（TC-01 の検査外）→ DISCOVERED
  - P3-3 steps-*.md の呼び出しで Base directory が当てはめられないと rc=127。pre-red-gate は 0/1、finding-in-diff は 0/1/2 しか扱いが無い（修正前と同じで悪化ではない）→ DISCOVERED
- Phase completed

### 2026-11-11 11:33 - COMMIT
- pre-commit-gate PASS。人間の確認（COMMIT 前の md）を経て fix/skill-script-base-paths に commit。STATUS.md 更新。Closes #292
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

- **Failure**: plan の最初の版は、相対パスの呼び出しを `grep -rnE "bash [^ ]*scripts/"` で洗い出し、skill の中に置かれたスクリプトの呼び出し（`bash skills/review/risk-classifier.sh`・`severity-verdict.sh` の 3 か所）を落としていた。承認前の Codex plan review（attempt 1）が指摘した
- **Final fix**: `bash skills/[a-z-]+/[a-z-]+\.sh` も洗い、review の 3 か所を範囲に加えた。TC-01 は `bash ` の直後に引用符なしの `scripts/` または `skills/` が続く行を探す形にした
- **Insight**: 同じ欠陥の呼び出しを洗い出すときは、置き場所の名前（`scripts/`）ではなく呼び出しの形（`bash ` の直後に相対パス）で探す。欠陥は「どこにあるスクリプトか」ではなく「どう呼んでいるか」で決まる

### Insight 2

- **Failure**: 呼び出しを `bash "<review の Base directory>/severity-verdict.sh" verdict` に変えると、`tests/test-reviewer-scoring.sh` TC-12 の検索 `severity-verdict\.sh verdict` が実呼び出しに一致しなくなる。説明文の一致だけが残り、実呼び出しから `--invalid` が消えても PASS する状態になるところだった。plan の逆向き契約の確認は固定文字列（`bash scripts/...`）しか grep しておらず、承認前の最終レビュー（attempt 2）で初めて見つかった
- **Final fix**: TC-12 の検索を `severity-verdict\.sh"? verdict` にし、`bash "<` を含む実呼び出しの行が 1 本以上一致することも assert した。`--invalid` を除く変異で FAIL することを REFACTOR で確かめた
- **Insight**: 呼び出しの文字列を変えるときの逆向き契約の確認は、テストの中の固定文字列だけでなく、旧い形に一致する正規表現も探す。「一致した行すべてが X を持つ」型の検査は、一致が減っても FAIL せず、黙って弱くなる

### Insight 3

- **Failure**: GREEN の委譲 prompt に「通った項目を WIP から DONE へ移す」と書いたところ、green-worker は項目を移さずに `### WIP` と `### DONE` の見出しを入れ替えた。節の並びが崩れ、DONE の項目は `[ ]` のまま残った
- **Final fix**: この cycle では記録の乱れとして DISCOVERED に残した（gate の判定には影響しない）
- **Insight**: Test List の遷移を委譲するときは「項目を DONE の見出しの下へ移し、`[x]` にする。見出しと節の並びは変えない」まで書く。「移す」だけでは、見出しを書き換えても同じ結果に見える

### 想起漏れ

- **設問**: 今回の手戻りは、過去のどの cycle doc を最初に読んでいれば防げたか
- **回答**: 該当なし

## Codify Decisions

### Insight 1
- **Decision**: codified
- **Destination**: rule
- **Tier**: cycle-scoped
- **Reason**: 再発 2 回（この cycle と 20261111_1730 #1）。rules/plan-discipline.md に足す。直す範囲や消す範囲を洗い出すときは、置き場所や設定の名前ではなく、欠陥や機能の実際の形（呼び出しの形、使う仕組み）で探し、名前を持たない consumer（配布用のテンプレートなど）を拾う
- **Decided**: 2026-11-12 10:51

### Insight 2
- **Decision**: codified
- **Destination**: rule
- **Tier**: file-scoped
- **Paths**: tests/**
- **Reason**: rules/test-patterns.md に足す。呼び出しの文字列を変えるときは、テストの中の固定文字列だけでなく、旧い形に一致する正規表現も探す。「一致した行すべてが X を持つ」型の検査には、一致が 1 行以上あることの assert を添える
- **Decided**: 2026-11-12 10:51

### Insight 3
- **Decision**: codified
- **Destination**: rule
- **Tier**: cycle-scoped
- **Reason**: rules/agent-prompts.md に足す。Test List の遷移を委譲するときは「項目を DONE の見出しの下へ移し `[x]` にする。見出しと節の並びは変えない」まで書く
- **Decided**: 2026-11-12 10:51
