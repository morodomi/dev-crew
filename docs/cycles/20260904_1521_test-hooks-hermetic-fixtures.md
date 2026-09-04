---
feature: test-hooks hermetic fixtures
cycle: 20260904_1521
phase: DONE
complexity: standard
test_count: 9
risk_level: low
retro_status: captured
codex_mode: no
codex_session_id: "01a06b00-9f34-72d0-b02f-e554f73879f7"
plan_file: /Users/morodomi/.claude/plans/twinkling-petting-kitten.md
created: 2026-09-04 15:21
updated: 2026-09-04 18:20
---

# test-hooks-structure hermetic 化（#144 壁時計依存 + #195 実ツリー fixture 隔離）

## Scope Definition

### In Scope
- [ ] A. tests/test-hooks-structure.sh: TC-03 を実ツリーから mktemp snapshot へ移す + TC-05 系の fixture git repo 化 + TC-06 の fixture 付け替え
- [ ] B. tests/test-agents-structure.sh: BASE_DIR env override 化 + TC-41 暫定除外撤去
- [ ] C. .claude/dev-crew.json: dev_crew_version "2.16.0" → "2.17.0"（1行）
- [ ] D. CHANGELOG.md: `## [Unreleased]` 新設 + Fixed 記載、docs/STATUS.md: Completed 行追加

### Out of Scope
- hook 本体の挙動変更（閾値・メッセージ・対象ファイル）(Reason: #144 はテスト設計の欠陥であり hook は仕様どおり)
- #186 本体（release-skill への bump step 追加）(Reason: リリースフロー変更は別 cycle。本 cycle は値の追随のみ)
- meta test 3 本（test-doc-consistency 等）の変更 (Reason: TC-05 解消で自動回復する cascade の根本 fix)
- #144 案(b) 連鎖切断・案(c) 閾値運用変更 (Reason: 案(a) 根治を採用)

### Files to Change (target: 10 or less)
- tests/test-hooks-structure.sh (edit, 主対象)
- tests/test-agents-structure.sh (edit, BASE_DIR env override + TC-41 除外撤去)
- .claude/dev-crew.json (edit, 1行)
- CHANGELOG.md (edit, `## [Unreleased]` 新設)
- docs/STATUS.md (edit, Completed 行追加、COMMIT phase で)

## Environment

### Scope
- Layer: Plugin repo（shell tests のみ。Backend/Frontend 区分は非適用）
- Plugin: bash 3.2.57 / jq 1.7.1 / git 2.49.0
- Risk: 10 (PASS) — Limited カテゴリ（test addition/修正）+10。Security/External/Data/Scope の +60/+40 カテゴリはいずれも非該当（rubric: skills/spec/reference.md の keyword score 表）

### Runtime
- Language: GNU bash 3.2.57(1)-release (arm64-apple-darwin25)

### Dependencies (key packages)
- git: fixture repo 作成に使用
- mktemp: 単一 root + trap cleanup

### Risk Interview (BLOCK only)
- 該当なし — Risk は 10 (PASS) であり BLOCK 閾値未達のため Risk Interview は未実施

## Context & Dependencies

### Reference Documents
- 修理対象はテスト自身であり、hook 本体（scripts/hooks/check-claude-md-staleness.sh）は変更しない

### Ambiguity Resolution（ユーザー決定含む、探索・設計方針として転記）
- Scope: #144+#195 に scope C（dev_crew_version 1 行 bump）を追加 — AskUserQuestion で「override して続行 + 1 行修正同梱」を選択済み
- hook 本体の変更有無: 変更しない（テスト側の修理で完結。hook の挙動は現行を characterization として pin）

### Related Issues/PRs
- Issue #144: CLAUDE.md staleness hook 壁時計依存によるテスト non-hermetic 化
- Issue #195: TC-03 drift 検出 fixture の実ソースツリー直下作成による flake
- Issue #186: release-skill への bump step 追加（本 cycle は範囲外、値の追随のみ）

## Recall

### docs/cycles/archive/20260218_1400_claude-md-staleness.md（score 0.70）
- **何が起きたか**: staleness hook と TC-04〜06 を新設した起源 cycle。TC-05 の Given「CLAUDE.md が最近更新されている場合」は当時（2026-02-18、CLAUDE.md commit 直後）恒常的に真だった
- **当時の前提**: 「CLAUDE.md は常に最近更新されている」— リポジトリが若く、前提の失効を fixture で防ぐ発想がなかった
- **今回も同じ前提か**: **No**。49 日無更新で前提が偽になり FAIL。本 cycle はまさにこの前提を fixture 制御に置き換える

### docs/cycles/20260314_1112_agents-md-skill-propagation.md（score 0.50）
- **何が起きたか**: staleness hook の対象に AGENTS.md を追加（CLAUDE.md → CLAUDE.md+AGENTS.md）
- **当時の前提**: 両ファイルが独立に staleness 判定される
- **今回も同じ前提か**: **Yes**。fixture は両ファイルを持ち、TC-05f で AGENTS.md 単独 stale を pin する

## Baseline（実測、2026-09-04）

- `bash tests/test-hooks-structure.sh` → **9/10 FAIL 1**（TC-05: `[WARNING] CLAUDE.md は 48 日間更新されていません` を検出して FAIL）
- `bash tests/test-agents-structure.sh` → rc=0（standalone PASS）
- full suite（前日、HEAD 隔離 worktree ×2 で実測）→ 112/116。FAIL 4 = test-hooks-structure / test-doc-consistency / test-factory-model-adaptation / test-trap-handler（単一根本原因 TC-05 の nested cascade、plan-discipline「N 件同時 FAIL は単一根本原因を疑う」に合致・棄却実験済み: 隔離 worktree でも同一 4 件）
- 逆向き契約 sweep: `grep -rn 'test-drift' tests/ skills/ rules/` → 計 8 件（tests/test-hooks-structure.sh 5 件 = 変更対象自身、tests/test-agents-structure.sh 3 件）。変更対象ファイルを除外した実質の逆向き契約は test-agents-structure.sh:508,510,515（TC-41 の暫定除外とその根拠コメント）。`grep -rn 'export BASE_DIR'` → 0 件（BASE_DIR env 化は他 test の呼び出しに影響しない）。STATUS.md Test Scripts=116 は不変（新規 test file なし）のため count 契約変更なし

## Test List

### TODO
(none)

### WIP
(none)

### DISCOVERED
(none)

### DONE
- [x] TC-03: Given agents/ + skills/ + AGENTS.md + CHANGELOG.md を複製した mktemp snapshot に、既存 agent を opus で参照する steps-*.md のみを追加 / When `BASE_DIR=$SNAP bash "$BASE_DIR/tests/test-agents-structure.sh"` / Then exit 1 かつ model drift 固有の診断行を含み Summary に到達し `FAIL: 1`（drift 由来のみ）。And 実行前後で実ツリーに新規 fixture ファイルが存在しない
- [x] TC-05a: Given fixture git repo（CLAUDE.md+AGENTS.md を現在時刻 commit）/ When fixture cwd で hook 実行 / Then 出力空 + exit 0
- [x] TC-05b: Given 40 日前 backdate commit / When 閾値 30（既定）で実行 / Then `[WARNING]` を含む出力 + exit 0
- [x] TC-05c: Given 20 日前 backdate commit / When 既定閾値で実行 / Then 出力空 + exit 0
- [x] TC-05d: Given git repo でない dir + CLAUDE.md / When 実行 / Then 出力空 + exit 0（last_modified=0 経路）
- [x] TC-05e: Given 40 日前 stale fixture + SKIP_STALENESS_CHECK=1 / When 実行 / Then 出力空 + exit 0
- [x] TC-05f: Given CLAUDE.md fresh + AGENTS.md 40 日前 / When 実行 / Then AGENTS.md の WARNING のみ（CLAUDE.md 行なし）
- [x] TC-06: Given fixture repo（60 秒 backdate commit）+ STALENESS_THRESHOLD_DAYS=0 / When 実行 / Then `[WARNING]` + exit 0（`age > 0` を保証。実リポ依存の除去のみで意味は現行同一）
- [x] TC-41（test-agents-structure.sh 側）: Given 暫定除外撤去後の name-set diff / When standalone 実行 / Then PASS（fixture 汚染なしで実集合一致）

## Implementation Notes

### Goal
tests/test-hooks-structure.sh の 2 つの非 hermetic 設計（#144 壁時計依存 / #195 実ツリー fixture 汚染）を解消し、full suite を 112/116 → 116/116 に回復する。

### Background
full suite が 112/116 で常態 red 化している。原因は tests/test-hooks-structure.sh の 2 つの非 hermetic 設計:

1. **#144**: TC-05 が「CLAUDE.md が最近更新されている」という Given を fixture で制御せず実リポジトリの壁時計に依存。CLAUDE.md 最終 commit は cf67c3b（2026-07-17、49 日前）で staleness hook（閾値 30 日）が WARNING を出し FAIL。meta test 3 本（test-doc-consistency TC-13 / test-factory-model-adaptation TC-14 / test-trap-handler T-04）が test-hooks-structure.sh を再帰実行するため 1 FAIL が 4 scripts に増幅（全て実測済み。HEAD 隔離 worktree でも同一 = コード無関係、時間経過のみで red）。
2. **#195**: TC-03 が drift 検出 fixture（agents/test-drift-agent.md + skills/test-drift-skill/）を実ソースツリー直下に作成するため、並行実行中の他 test（test-agents-structure.sh TC-41 の存在ベース契約）が flake する（issue で再現済み）。TC-41 は暫定で fixture 名 `test-drift-agent` を明示除外中（tests/test-agents-structure.sh:515）。

修理対象はテスト自身であり、hook 本体（scripts/hooks/check-claude-md-staleness.sh）は変更しない。

付帯（scope C、AskUserQuestion で承認済み）: `.claude/dev-crew.json` の dev_crew_version が 2.16.0 のまま（installed 2.17.0）で spec の Version Gate が誤 BLOCK する。本 cycle は警告承知 override で開始した（20260721_1503 の前例踏襲）。1 行 bump を同梱し次 cycle 以降の誤 BLOCK を止める（release-skill 自動化の本体は #186 で別途）。

### Design Approach

既存 precedent の踏襲のみで実装する（新規パターンなし）:

- **BASE_DIR env override**: `BASE_DIR="${BASE_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"` — tests/test-doc-consistency.sh:7 / test-review-step5-synthesis-clause.sh:18 / test-rules-path-scoping.sh:7 と同型
- **fixture 隔離呼び出し**: `BASE_DIR="$FIXTURE" bash "$SUBJECT"` — tests/test-meta-doc-consistency.sh:65,88,112 と同型
- **fixture git repo の日付制御**: `GIT_COMMITTER_DATE="@$(( $(date +%s) - 40*86400 )) +0000"` で backdate commit（hook は `git log -1 --format=%ct` = committer time を読む）。「40 日前」は常に相対で決定論（壁時計からの独立）
- **単一 mktemp root + trap cleanup**: tests/test-severity-verdict.sh の FIXTURE_DIR パターンと同型

**A. tests/test-hooks-structure.sh**（主対象）

- TC-03: fixture を実ツリーから mktemp snapshot へ移す。`SNAP=$(mktemp -d)` に `cp -R "$BASE_DIR"/agents "$BASE_DIR"/skills "$BASE_DIR"/AGENTS.md "$BASE_DIR"/CHANGELOG.md`（4 対象。TC-44 は AGENTS.md、TC-45 は CHANGELOG.md を読む — tests/test-agents-structure.sh:594,614 で実測。当初 plan の「agents/ skills/ のみ」は誤りで、欠落すると TC-44/45 が「file not found」で FAIL し TC-03 が誤った理由で PASS する）→ snapshot 内に既存 agent を参照する不一致 steps-*.md のみを追加（新規 agent md を作らない: TC-41 の name-set diff は除外撤去後に必ず FAIL するため、drift 以外の理由で exit 1 になり検出力を失う）→ `BASE_DIR="$SNAP" bash "$BASE_DIR/tests/test-agents-structure.sh"`（コピー元・subject とも絶対パス、呼出元 cwd 非依存）
  - **判定の厳密化**: exit 1 だけでは不十分（他 TC の破損でも exit 1 になる）。model drift 固有の診断行が出力に含まれること + Summary 到達 + `FAIL: 1`（drift 由来の 1 件のみ）を併せて検証する。実ツリーへの書込ゼロ化
- TC-05: fixture git repo（mktemp + git init + CLAUDE.md/AGENTS.md を現在時刻で commit）で「recent → 警告なし・exit 0」を決定論化。hook は cwd 相対で `git log` するため `cd "$FIX"` で hook を絶対パス実行
- TC-05 系の追加 characterization（hook 現行挙動の pin、全て fixture 上）:
  - stale 側: 40 日前 backdate commit（閾値 30）→ `[WARNING]` 出力 + exit 0
  - 境界: 20 日前 backdate → 警告なし + exit 0
  - non-git dir（last_modified=0 経路）→ 警告なし + exit 0
  - `SKIP_STALENESS_CHECK=1` + stale fixture → 警告なし + exit 0
  - AGENTS.md 単独 stale（CLAUDE.md fresh）→ AGENTS.md の WARNING のみ（20260314_1112 で両ファイル対象化された経緯の pin）
- TC-06（threshold=0）: 実リポ依存から fixture へ付け替え。commit を基準時刻から 60 秒 backdate する（hook の条件は `age -gt $((THRESHOLD*86400))` = threshold 0 なら `age > 0` が必要。fresh commit と同一秒内実行では age=0 で警告が出ず FAIL する — scripts/hooks/check-claude-md-staleness.sh:26 で実測確認）
- 実ツリー fixture path（TEMP_AGENT/TEMP_SKILL_DIR）と cleanup trap を mktemp root の trap に置換。header コメントの TC 一覧を実装に合わせ更新
- git commit は `git -c user.email=test@test -c user.name=test commit` で環境の git config に非依存化

**B. tests/test-agents-structure.sh**（2 点のみ）

- L11: `BASE_DIR="${BASE_DIR:-$(...)}"` へ（env override 化。export 精査済みで既存呼び出し元に影響なし）
- TC-41（L508-515）: `grep -vx 'test-drift-agent'` 暫定除外と該当コメントを撤去（A の隔離により不要化。#195 記載の根治確認点）

**C. .claude/dev-crew.json**（1 行）

- dev_crew_version: "2.16.0" → "2.17.0"

**D. docs**

- CHANGELOG.md: v2.17.0 リリース時に `## [Unreleased]` は `## [2.17.0]` へ改名済みで現在先頭は [2.17.0]。よって `## [Unreleased]` を新設し、その下に Fixed（テスト hermetic 化 #144/#195 + dev_crew_version 追随）を書く。注意: tests/test-agents-structure.sh TC-45 は `## [2.16.0]` の絶対アンカーを見るため本追加の影響を受けない（相対アンカー禁止の codified rule 準拠）
- docs/STATUS.md: Completed 行追加（COMMIT phase で。Test Scripts=116 不変）
- 注記: orchestrate Block 0 codify gate が前 cycle doc（20260903_1130）を更新する場合は commit 同梱を透明化（plan-discipline 準拠）

RED の red 実測: 現行 TC-05 が FAIL（実測済み）を本 cycle の red とする。新 TC 群は hook 現行挙動の characterization であり、fixture oracle（backdate した fixture に対する hook の実出力）を RED 中に実測してから Then を確定する（test-patterns「negative sweep は oracle 実測」準拠）。

## Verification

**Real-path invocation を最低 1 件含めること** (rules/integration-verification.md)。

```bash
# dev-crew 内 (bash/doc project): gate/consumer/validator を real path で実行
1. bash tests/test-hooks-structure.sh   # 全 TC PASS（TC-05 系が壁時計非依存で green）
2. bash tests/test-agents-structure.sh  # rc=0（TC-41 除外撤去後）
3. 並行実行の flake 解消確認: bash tests/test-hooks-structure.sh & bash tests/test-agents-structure.sh  # 同時実行で両者 PASS（#195 の再現条件）
4. full suite（隔離 snapshot）→ 116/116（staleness cascade 4 件の解消がこの cycle の成果指標）
5. 時限性の消滅確認: fixture の相対 backdate により、TC-05b/c は実行日に依存しない（コードレビューで確認）

# テスト実行 (補完)
for f in tests/test-*.sh; do bash "$f"; done
```

Evidence: (orchestrate が自動記入)

## Progress Log

### 2026-09-04 15:21 - KICKOFF
- Cycle doc created (sync-plan により plan ファイルから転記)
- Scope definition ready

### 2026-09-04 15:21 - Plan Review (pre-approval)
- codex_session_id: 01a06b00-9f34-72d0-b02f-e554f73879f7
- review_attempts:
  - {started: 17:24, completed: 17:29, verdict: BLOCK}
  - {started: 17:33, completed: 17:37, verdict: PASS}
- findings 要約:
  - attempt 1 (BLOCK, critical 2 / important 1 / optional 1): (1) TC-03 の snapshot 対象が agents/ skills/ のみで AGENTS.md・CHANGELOG.md 欠落 → TC-44/45 が file-not-found FAIL し「誤った理由での exit 1」で TC-03 が偽 PASS。加えて新規 agent md 作成は TC-41 除外撤去後に必ず FAIL するため drift 検出力を失う（実機確認: tests/test-agents-structure.sh:594,614）→ snapshot 4 対象化 + 既存 agent 参照 steps のみ + drift 固有診断/Summary/`FAIL: 1` 判定へ修正。(2) TC-06 の fresh commit + threshold=0 は hook の `age -gt 0` 条件により同一秒で age=0 → 警告出ず FAIL（実機確認: scripts/hooks/check-claude-md-staleness.sh:26）→ 60 秒 backdate へ修正。(3) Risk 5 は rubric（0/10/40/60）から算出不能 → Limited +10 で再算出。(4) CHANGELOG 先頭は [2.17.0] で [Unreleased] は不在 → 新設と明記
  - attempt 2 (PASS, critical 0 / important 0 / optional 1): 4 件すべて解消を確認。optional = 逆向き契約 sweep の件数記述が不正確（実測 8 件: 変更対象自身 5 + test-agents-structure.sh 3）→ 除外後の実質 3 箇所を明記して修正済み
- unresolved_blocks: なし
- plan_presented: 2026-09-04 17:40
- reviewed_plan_hash: 62f5919cafb266d6e963a124d50eb35c8c09a0bc43fd7b0d8c7300f3dd52971c
- verdict: PASS
- Phase completed

### 2026-09-04 15:25 - SYNC-PLAN
- sync-plan によりplanファイル（/Users/morodomi/.claude/plans/twinkling-petting-kitten.md）からの転記完了。Context / TDD Context / Baseline / Design / Files to Change / Out of Scope / Test List / Verification / Recall を Cycle doc へ転記し、frontmatter（codex_session_id / plan_file 含む）を初期化した
- Phase completed

### 2026-09-04 15:40 - RED
- 対象: `tests/test-hooks-structure.sh` のみ編集（新規 test file なし、Test Scripts=116 不変を実測確認: `ls tests/test-*.sh | wc -l` → 116）。実装側（`tests/test-agents-structure.sh` の BASE_DIR env override 化 + TC-41 除外撤去）は GREEN フェーズへ持ち越し、本フェーズでは触れていない
- fixture oracle 実測（Then 確定前に fixture を作り実出力を確認、test-patterns 準拠）:
  - TC-03: scratch 上に BASE_DIR env override 適用済みコピーを作り `BASE_DIR=$SNAP` で実行した結果、診断行は正確に
    `Model drift in steps-test-drift.md: review-briefer has model 'haiku' in frontmatter but 'opus' in Task() call` で
    あることを確認（review-briefer は既存 agent, frontmatter model=haiku、fixture steps は model="opus" で参照し drift を作る）。
    rc=1, `FAIL: 1 / TOTAL: 29`, `=== Summary ===` 到達、TC-41 は名前集合不変のため PASS のままであることも確認
  - TC-05a〜f / TC-06: fixture git repo（`git -c user.email=test@test -c user.name=test commit` + 相対 backdate `GIT_COMMITTER_DATE`）を直接 hook 対象に実行し、Then（空出力/exit0、`[WARNING]` 有無、AGENTS.md 単独 stale 時に CLAUDE.md 行が出ないこと）を実測してから assert 文字列を確定した
- RED 実測結果: `bash tests/test-hooks-structure.sh` → **PASS: 14 / FAIL: 1**、exit=1（2 回連続実行で同一結果、決定論確認済み）
  - FAIL は **TC-03 のみ**: `exit=0 (expected 1); missing model-drift diagnostic line; FAIL count is not exactly 1;`
    — `test-agents-structure.sh` が `BASE_DIR` env override をまだ実装していないため、TC-03 が渡す `BASE_DIR=$SNAP` が
    無視され実ツリーを読み続け、drift 検出に至らず exit 0 のまま返る（GREEN で env override を実装すると解消する設計どおりの RED）
  - TC-01/02/04/05a/05b/05c/05d/05e/05f/06/07/08/09/10 は全て PASS（旧 TC-05 の壁時計依存 FAIL — CLAUDE.md 48 日超過による `[WARNING]` — は fixture 化により解消。本 cycle の red の起点だった旧 TC-05 FAIL はここで消滅し、TC-03 の新 FAIL に置き換わった）
- 並行実行 flake 再現チェック（#195 対象条件）: `bash tests/test-hooks-structure.sh` と `bash tests/test-agents-structure.sh` を同時実行し、後者は実ツリーに対して独立に `PASS: 29 / FAIL: 0` で完走することを確認（TC-03 の fixture が実ツリーへ汚染しないことの並行実測）
- 実ツリー書込みゼロ確認: TC-03 実行前後で `agents/test-drift-agent.md` / `skills/review/steps-test-drift.md` の非存在を assert し、`git status --porcelain` でも `tests/test-hooks-structure.sh` 以外の意図しない差分がないことを確認
- Phase completed

### 2026-09-04 15:44 - GREEN
- 対象: tests/test-agents-structure.sh（2 点）+ .claude/dev-crew.json（1 行）+ CHANGELOG.md（`## [Unreleased]` 新設）。tests/test-hooks-structure.sh は RED で完了済みのため未変更
- B. tests/test-agents-structure.sh:
  - L11: `BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"` を `BASE_DIR="${BASE_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"` へ変更（precedent 同型）
  - TC-41（旧 L507-515）: `grep -vx 'test-drift-agent'` 暫定除外とその根拠コメントを撤去。fixture 隔離により不要化（#195 根治確認）
- C. .claude/dev-crew.json: `dev_crew_version` を `"2.16.0"` → `"2.17.0"` に変更（1 行のみ）
- D. CHANGELOG.md: `# Changelog` 直後に `## [Unreleased]` を新設し、`### Fixed` に #144 / #195 / dev_crew_version 追随の 3 項目を記載
- 実測結果:
  1. `bash tests/test-hooks-structure.sh` → `PASS: 15 / FAIL: 0`（TC-03 を含め全 TC green。TC-03 は `test-agents-structure.sh` の BASE_DIR override 実装により意図どおり通過）
  2. `bash tests/test-agents-structure.sh` → `PASS: 29 / FAIL: 0 / TOTAL: 29`, rc=0
  3. 並行実行 flake 解消確認: `bash tests/test-hooks-structure.sh` と `bash tests/test-agents-structure.sh` を background で同時実行し、両者とも上記と同一の PASS/FAIL 結果で完走（#195 再現条件下での相互汚染なしを確認）
  4. `ls tests/test-*.sh | wc -l` → 116（不変、新規 test file なし）
  - full suite は本フェーズでは実行していない（PdM が Gate 2 で隔離 snapshot 実行）
- `git status --porcelain` で意図した 4 ファイル（`.claude/dev-crew.json` / `CHANGELOG.md` / `tests/test-agents-structure.sh` / `tests/test-hooks-structure.sh`）以外の diff（`docs/cycles/20260903_1130_severity-verdict.md` 含む）は本 GREEN フェーズの変更ではなく事前存在を確認
- Phase completed

---

## Next Steps

1. [Done] KICKOFF <- Current
2. [Done] RED
3. [Done] GREEN
4. [Next] REFACTOR
5. [ ] REVIEW
6. [ ] COMMIT
7. [ ] DONE

### 2026-09-04 16:27 - REFACTOR
- チェックリスト 7 項目を変更ファイル（tests/test-hooks-structure.sh / tests/test-agents-structure.sh）に適用
- #1 重複コード: TC-05a/b/c/e + TC-06 に 5 回重複していた「git init + CLAUDE.md/AGENTS.md 書き込み + backdate commit」の 4 行ブロックを `fixture_repo_with_docs <repo> <offset_seconds>` に共通化（20 行 → 5 行）。TC-05f は 2 commit を異なる age で作る必要があるため primitive を直接呼ぶまま残し、その理由を helper の doc コメントに明記
- #2 定数化: `3456000` 等のマジックナンバーを `DAY_SECONDS=86400` 経由の `$((40 * DAY_SECONDS))` へ。TC-06 の 60 秒だけは日スケールでないため素の秒数を維持
- #3〜#7（未使用 import / let→const / メソッド分割 / N+1 / 命名一貫性）: bash テストのため非該当、または既に helper 粒度が適切で改善不要
- Verification Gate: `bash -n` 構文 OK、tests/test-hooks-structure.sh 15/15 PASS、tests/test-agents-structure.sh 29/29 PASS
- Phase completed

### 2026-09-04 16:32 - VERIFY (Product Verification)
- real-path invocation（advisory evidence、/tmp/dev-crew-verify-20260904_1521/ に保存）:
  1. `bash tests/test-hooks-structure.sh` → PASS 15 / FAIL 0
  2. `bash tests/test-agents-structure.sh` → PASS 29 / FAIL 0（TC-41 暫定除外を撤去した状態）
  3. 並行実行（両者を同時起動して wait）→ hooks 15/15・agents 29/29 で両者 PASS。#195 の flake 再現条件でクリーン
  4. full suite（親構造ごと複製した隔離 snapshot）→ **116/116**（本 cycle の成果指標を達成。#144 cascade の 4 件解消）
- PdM 手順ミスの記録: 最初の Gate 2 snapshot を repo 単体で複製したため tests/test-paradigm-selection.sh:16 の repo 外依存（`$BASE_DIR/../../docs/test_architecture.md`）が壊れ、4 件が誤 FAIL した。rules/plan-discipline.md の「隔離 snapshot は複製前に repo 外依存を洗い親構造ごと複製する」(cycle 20260706_1216 #1) 未適用。親構造込みで取り直して 116/116 を確認
- Phase completed

### 2026-09-04 16:55 - REVIEW
- Risk: risk-classifier.sh = **HIGH score:70** → panel は MED+ 相当（correctness / security / test / maintainability）+ Codex competitive
- Step 4.4 Output Validation: `severity-verdict.sh validate` → 5 file すべて OK（correctness / security / test / maintainability / codex）、retry 0 回
- raw severity_counts: correctness 0/2/3、security 0/0/1、test-reviewer 0/3/2、maintainability 0/2/4、codex 0/2/0（P2×2）
- Socrates（Devil's Advocate）が reviewer 5 名の共通前提を破壊する 2 件を提起し、PdM が実測で **両方 CONFIRMED**:
  1. **hook は完全な orphan** — hooks.json・.git/hooks/pre-commit・onboard のいずれにも登録がなく呼び出し元はテストのみ（`grep -c staleness hooks/hooks.json` = 0、pre-commit は yaml-frontmatter のみ呼ぶ）。本 cycle は未配線スクリプトに 8 TC を固定した形になる
  2. **hook 本体のバグ** — git repo 内の未 commit ファイルで `git log -1 -- FILE` が exit 0 + 空 stdout を返し `|| echo "0"` が発火せず age=now。oracle 実測で「CLAUDE.md は 20700 日間更新されていません」を再現
- ユーザー裁定（AskUserQuestion）: hook は **現状維持 + issue 起票**、findings の適用範囲は **拡張適用（Socrates 選択肢 2）**
- 決定論集計: `severity-verdict.sh verdict triage.json` → **WARN critical:0 important:10 optional:7 invalid:0**
- triage: accept-apply 10 / accept-defer 7 / reject 0
- **accept-apply（本 cycle で適用済み）**:
  - [important] rc idiom 7 箇所 — `output=$(...)` 直後の `rc=$?` は set -e 下で到達不能（PdM が oracle 実測で確認）。`run_staleness_hook` helper に if/else 形で集約。**反証テスト**: hook を exit 7 に改変した複製ツリーで実行し、修正前は silent abort だった経路が `exit=7` を明示報告し Summary に到達することを実測（PASS 9 / FAIL 6）
  - [important] git 環境隔離 — `fixture_git` helper で `env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE` + `-c commit.gpgsign=false -c core.hooksPath=/dev/null`。hermetic 化 cycle が別種の環境依存を持ち込んでいた
  - [important] TC-05b / TC-06 の assert を `[WARNING] CLAUDE.md` と `[WARNING] AGENTS.md` の個別 assert へ（任意の `[WARNING]` 一致では CLAUDE.md 側が壊れても AGENTS.md だけで通っていた）
  - [important] cp -R の 4 対象が必要な理由をコード上にコメント（将来の簡略化リファクタによる bug 再導入の防止）
  - [optional] DAY_SECONDS sweep 漏れ（TC-05f）/ TC-03 の実ツリー drift-clean 前提の明記 / header コメント drift（TC-05d は非 git dir）/ trap を EXIT と INT,TERM に分離し INT,TERM は明示 exit 130 / helper コメントの呼び出し元列挙を除去 / TC-03 の vacuous guard に意図コメント
  - 途中経過: helper 初版で `printf` シリアライズを使い、空出力時に command substitution が末尾改行を落として rc が output に混入する自作バグを埋め込み 4 TC が FAIL。グローバル直接代入へ変更して解消（テストが自作バグを捕捉した）
- **accept-defer → issue 起票**: #206（hook 本体バグ: 未 commit ファイルで age=now）、#207（hook の去就裁定: 配線 or 削除。実ツリー CLAUDE.md 49 日 staleness の未対処も併記）、#208（検出力強化: 閾値境界 straddle / 両ファイル不在分岐の分離 / TC-03 fixture 自己所有化 / TC03_SNAP 命名）
- 検証: tests/test-hooks-structure.sh 15/15、tests/test-agents-structure.sh 29/29
- Phase completed

### 2026-09-04 18:18 - REVIEW 後 fix（逆向き契約違反の解消）
- **PdM の逆向き契約違反**: accept-apply で trap を `trap cleanup EXIT` + `trap 'cleanup; exit 130' INT TERM` の 2 行へ分割したが、`tests/test-trap-handler.sh` T-02 が `grep -q "trap.*EXIT.*INT.*TERM"` という**単一行形状**の逆向き契約を持っており T-02 が FAIL、test-doc-consistency / test-factory-model-adaptation に連鎖して full suite が 113/116 に低下した
- 機序: rules/plan-discipline.md「逆向きテスト契約の無視: grep が target 存在を要求するテストを見落として文字列を削除しない」「plan 時に `grep -rn "<target_value>" tests/` で逆向き契約を検索する」を編集前に適用しなかった。本 cycle 2 度目の codified rule 未適用（1 度目は隔離 snapshot の repo 外依存）
- **さらに報告誤り**: 切り分け中、trap 編集前に起動していたバックグラウンド実行の出力を世代確認せずに読み「live tree は 4 件とも rc=0」とユーザーに報告した。実際は live tree でも T-02 は FAIL しており、前 cycle Insight 1「出力を読んでも突合しない」と同型
- 対応: trap を 1 行形式へ revert し、分割できない理由（T-02 の形状 pin）をコード上にコメントで残した。trap hazard 自体は optional severity のため #208 に「test-trap-handler.sh T-02 の契約更新と同一変更で行う」条件付きで defer
- 検証（世代を明示して実測）: test-hooks-structure / test-trap-handler / test-doc-consistency / test-factory-model-adaptation すべて rc=0。full suite（親構造込み隔離 snapshot、17:59:08 取得・trap revert 後を grep で確認）→ **116/116 FAILED:none**
- Phase completed

---

## Retrospective

### Insight 1: 隔離 snapshot を作る前に repo 外依存を grep する（codified 済み条項の未適用、1 度目）
- **Failure**: Gate 2 の full suite を repo 単体で /private/tmp に複製して実行し、4 件が FAIL。原因は tests/test-paradigm-selection.sh:16 の `$BASE_DIR/../../docs/test_architecture.md`（MorodomiHoldings 直下）が snapshot では解決できなかったこと。私は一瞬これを「本 cycle の変更による regression」と読み、切り分けに往復を費やした
- **Final fix**: `holdings-snap/docs/test_architecture.md` + `agents/dev-crew/` の親構造ごと複製して 116/116 を確認
- **Insight**: **rules/plan-discipline.md「隔離 snapshot baseline は複製前に repo 外依存を洗い（例: `grep -rln '\.\./\.\.' tests/`）、依存する親構造ごと複製する」(cycle 20260706_1216 #1) は既に codified されている。読んだ rule を「実行するコマンド」に変換しないと適用されない。snapshot を作る手が動く前に、この grep を実行する 1 ステップを挟む**
- **一般化**: codified rule のうち「手順の前に実行すべき grep/検査」型の条項は、実行時に思い出す設計では守れない。gate script 化または委譲 prompt の必須項目化が必要（#202 の決定論化と同型の問題）

### Insight 2: 契約で pin された文字列を編集する前に逆向き契約を grep する（codified 済み条項の未適用、2 度目）
- **Failure**: REVIEW の accept-apply で `trap cleanup EXIT INT TERM` を 2 行へ分割したところ、tests/test-trap-handler.sh T-02 の `grep -q "trap.*EXIT.*INT.*TERM"`（単一行形状の逆向き契約）が FAIL し、meta test 2 本に連鎖して full suite が 113/116 に低下した
- **Final fix**: 1 行形式へ revert し、分割不可の理由をコード上にコメント化。trap hazard 自体は T-02 の契約更新とセットで行う条件付きで #208 へ defer
- **Insight**: **plan-discipline の「plan 時に `grep -rn "<target_value>" tests/` で逆向き契約を検索する」は plan 時だけでなく REVIEW の accept-apply 適用時にも必要。特に「テストファイル自身を編集する cycle」では、編集対象が他テストの pin 対象である確率が構造的に高い。REVIEW 段階の修正は plan の Files to Change 検討を経ていないぶん逆向き契約チェックが抜けやすい**
- **一般化**: 同一 cycle 内で plan-discipline の別条項を 2 回破った（Insight 1 と本件）。rules/plan-discipline.md の「〜する前に grep する」型条項を pre-flight checklist として一箇所に集約し、REFACTOR/REVIEW の適用時にも参照させる

### Insight 3: バックグラウンド実行の出力は「いつのコードを測ったか」を確認してから読む
- **Failure**: trap 分割による FAIL の切り分け中、trap 編集前に起動していたバックグラウンドジョブの出力を世代確認せずに読み、「live tree は 4 件とも rc=0」とユーザーに報告した。実際は live tree でも T-02 は FAIL しており、報告が誤っていた
- **Final fix**: 再実行して T-02 の FAIL を live tree でも確認。以後の full suite 実行では出力に `SNAPSHOT_TAKEN_AT` と対象文字列の grep 結果を含め、測定対象の世代を出力自身に埋め込んだ
- **Insight**: **並行実行した検証ジョブの結果は「起動時刻 vs 最終編集時刻」を突合してから読む。長時間ジョブと編集を並行させる運用では、出力に測定対象の世代（timestamp + 対象文字列の実測）を埋め込んで自己証明させる**
- **一般化**: 前 cycle Insight 1「委譲報告と実 diff を突合する」の同型（今回は自分の実行結果と自分の編集の突合）。「出力を読んだ」と「出力が何を測ったか確認した」は別物

### Insight 4: reviewer 全員が共有する前提は Socrates でしか壊れない
- **Failure**: reviewer 5 名（Claude 4 + Codex）が誰も「この hook は配線されているのか」を検証せず、全員が「production code の characterization test を強化する」前提でレビューした。Socrates が hooks.json / .git/hooks / onboard を実測して orphan であることを暴き、さらに hook 本体の未 commit ファイルバグ（age=now、20700 日警告）も掘り当てた
- **Final fix**: PdM が両方を oracle 実測で CONFIRMED し、ユーザー裁定（現状維持 + issue）→ #206 / #207 起票。cycle の成果自体（116/116 回復）は hook の去就と独立に有効と整理
- **Insight**: **panel を増やしても「全員が同じ前提を共有している」場合の盲点は消えない。Socrates への入力に severity_counts と findings だけでなく「この cycle が暗黙に前提している命題」を明示的に列挙して渡すと、破壊対象が定まり検出力が上がる**
- **一般化**: 今回 Socrates prompt に「二次影響」「見落とし」の設問を明示したことが orphan 発見に効いた。この 2 設問を Socrates 委譲の定型項目として skills/review 側に固定する候補

### 想起漏れ

- **設問**: 今回の手戻りは、過去のどの cycle doc を最初に読んでいれば防げたか
- **回答**: **docs/cycles/20260706_1216_codify-rules-impl-and-gate-drift-guard.md**（Insight 1: 隔離 snapshot の親構造複製）。本 cycle の Recall は変更予定ファイル（tests/test-hooks-structure.sh 等）を入力に取ったため staleness 系の cycle が上位に出たが、「full suite を隔離実行する」という**手順**に紐づく cycle は候補に出なかった。Recall の入力は Files to Change だけでなく「その cycle で実行する検証手順」も加味すべき、という #187 R4 計測への観察材料

### 2026-09-04 18:19 - Codex code review 記録（competitive review の実施証跡）
- 実行: `codex exec --sandbox read-only resume 01a06b00-9f34-72d0-b02f-e554f73879f7 "review code: <changed files>"`（session は plan review と同一。Claude panel 4 名と並行実行）
- Codex verdict: **WARN — P1: 0 / P2: 2 / P3: 0**（tokens 207,488）
- P2-1: TC-05b / TC-06 が任意の `[WARNING]` のみ assert し CLAUDE.md 側の stale 判定を単独保証できない → accept-apply（個別 assert 化で適用済み）
- P2-2: fixture commit がユーザーの Git 設定（commit.gpgSign / core.hooksPath / init.templateDir）から隔離されていない → accept-apply（`fixture_git` helper で適用済み）
- Codex の確認事項（PASS 判定部分）: 相対 backdate は epoch 秒基準で実行日に非依存、TC-03 は snapshot 4 対象 + drift 固有診断 + Summary + `FAIL: 1` の複合で別理由の偽 PASS/FAIL を防止、BASE_DIR の既定動作は不変で明示 fixture 呼び出し以外に副作用なし、構文・JSON・diff whitespace 検査 PASS
- P1/P2/P3 → severity 対応（steps-codex.md 手順 4）: P2 → important として triage.json に統合済み。統合後の決定論集計は上記 REVIEW エントリの `WARN critical:0 important:10 optional:7 invalid:0`

### 2026-09-04 18:20 - COMMIT
- 全ゲート PASS（pre-commit-gate rc=0 / Test List 未完了 0 / RED・GREEN・REFACTOR・REVIEW の Phase completed / Codex code review 記録 = WARN P2×2 の実施証跡 / retro_status: captured）
- STATUS.md: Completed 行追加 + Last updated 2026-09-04。Test Scripts 116（本 cycle で新規 test file なし、不変）
- commit 同梱: tests 2 + .claude/dev-crew.json + CHANGELOG + docs/STATUS.md + Cycle doc + 前 cycle codify 出力（Block 0、scope 同梱として透明化）
- Phase completed
