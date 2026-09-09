---
feature: STATUS derived-number removal
cycle: 20260907_1324
phase: DONE
complexity: standard
test_count: 5
risk_level: low
retro_status: resolved
codex_mode: no
codex_session_id: "01a079ce-a69b-7453-8f38-e2d7f3eb69c2"
plan_file: /Users/morodomi/.claude/plans/twinkling-petting-kitten.md
created: 2026-09-07 13:24
updated: 2026-09-08 16:32
---

# STATUS.md の派生数値を削除し、依存する pin と doc 参照を一掃する（#210 Cycle 1/2）

## Scope Definition

### In Scope
- [ ] `docs/STATUS.md` L3-13（`## Current State` 見出し + Metric 表 6 行）を削除。L14 `Last updated:` は保持
- [ ] `scripts/gates/pre-commit-gate.sh` L92-102（check #3）を削除し、残る check を 1〜3 へ再採番（ヘッダコメント L17 も同期）
- [ ] 逆向き契約（7 test file）の削除・置換
- [ ] doc 参照の修正（9 件、mirror 込み）
- [ ] `CHANGELOG.md`（Removed / Changed）
- [ ] 新規 negative 契約 TC-N1〜TC-N5 を `tests/test-doc-consistency.sh` に追加

### Out of Scope
- README.md / AGENTS.md のツリー図内の数値（`28 skills` / `40 agents (flat), 19 security agents`）と、それを pin する `tests/test-skills-structure.sh` TC-B1/TC-B2・`tests/test-agents-md-count.sh`・`tests/test-doc-consistency.sh` TC-01・`tests/test-cycle-retrospective.sh` TC-15 (Reason: ユーザー裁定により Cycle 2/2 で扱う)
- 契約テストの COMMIT 経路への配線 (Reason: #211。#210 の削除完了後に対象が 3 契約へ縮小した状態で着手する)
- 本方針の CONSTITUTION 原則への昇格 (Reason: §8 の規定により ADR が必要。本 cycle では #210 の記録を判断根拠とする)

### Files to Change (19 件。dev-crew の目安 10 を超えるが、数値削除とそれを指す全参照の修正が不可分なため — 分割すると存在しない数値を指す doc が残り、本 cycle の目的に反する。内訳: 削除対象本体 2 + test 7 + doc 9 + CHANGELOG 1)

**A. 削除対象本体**
- `docs/STATUS.md`（edit）— L3-13 の `## Current State` 見出しと表を削除。L14 `Last updated:` 以降は保持
- `scripts/gates/pre-commit-gate.sh`（edit）— L92-102 の check #3 削除。ヘッダコメント L17 の該当行も削除。残る check を 1〜3 へ再採番

**B. 逆向き契約の削除・置換（6 test file）**
- `tests/test-v2-release.sh`（edit）— TC-04 削除。TC-05 は維持
- `tests/test-orchestrate-a2b.sh`（edit）— TC-15 削除
- `tests/test-codify-insight.sh`（edit）— TC-19 + TC-20 削除
- `tests/test-cycle-retrospective.sh`（edit）— TC-14 削除。TC-15 は README 側なので Cycle 2 で扱う
- `tests/test-doc-consistency.sh`（edit）— TC-26 + TC-27 削除 + ヘッダ L3 の欠番リストに 26, 27 追記。新規 TC-N1〜N5 追加
- `tests/test-pre-commit-gate.sh`（edit）— T-03 / T-04 / TC-14 削除。gate check #3 の削除に連動

**C. doc 参照の修正 + TC-07 置換（test 1 + doc 9）**
- `tests/test-spec-onboard-improvements.sh`（edit）— TC-07 を新方針の契約へ置換
- `docs/architecture.md`（edit）— L76, L82 の `see STATUS.md for counts` を除去し、ツリーのコメントは残す
- `docs/skill-map.md`（edit）— L4 の `> Counts: STATUS.md 参照。` を削除 + L19 の gate 責務記述から `STATUS.md同期` を除去
- `docs/workflow.md`（edit）— L53 / L93 / L120 の 3 箇所（pre-commit-gate の責務として `STATUS.md同期` を明記）を修正
- `docs/README.md`（edit）— L18 の「サイクル数、テスト数」を実態に合わせる
- `skills/onboard/reference.md`（edit）— L406 の方針を反転。「派生数値は doc に書かず、必要なら実ファイルから導出する」旨へ書き換える
- `rules/plan-discipline.md`（edit）— L14 / L26 / L62 の test count sync 条項を削除
- `.claude/rules/plan-discipline.md`（edit）— 上記と mirror。cp + diff -q で同期を実測確認
- `skills/commit/SKILL.md`（edit）— L35 の STATUS.md 同期警告の記述を削除。L49 の `| STATUS.md | 常に | 完了タスクを Completed に移動 |` は test-phase-gate TC-18 が要求するため残す
- `skills/commit/reference.md`（edit）— L174 の G-03 行を削除

**D. CHANGELOG**
- `CHANGELOG.md`（edit）— Removed / Changed

## Environment

### Scope
- Layer: Plugin repo（shell tests + doc + gate script）
- Plugin: bash 3.2.57 / jq 1.7.1 / git 2.49.0
- Risk: 10 (PASS) — Limited カテゴリ（test 修正・documentation）+10。Security/External/Data/Scope の +60/+40 は非該当（rubric: skills/spec/reference.md keyword score 表）

### Runtime
- Language: GNU bash 3.2.57(1)-release (arm64-apple-darwin25)

### Dependencies (key packages)
- bash: 3.2.57
- jq: 1.7.1
- git: 2.49.0

### Risk Interview (BLOCK only)
- N/A（Risk 10、PASS）

## Context & Dependencies

### Reference Documents
- CONSTITUTION.md §8（変更ポリシー）— 前 cycle（20260906_1120）の誤読を本 plan が訂正。§8 は CONSTITUTION.md 自身の記述先決定を定める節であり、他 doc への制約ではない。本 cycle は #210 の per-fact 判断（読み手の実在）のみを根拠とする

### Dependent Features
- `scripts/gates/pre-commit-gate.sh` check #3（STATUS.md 同期 WARN）: fail-open 設計により削除しても既存フローへの影響なし
- `tests/test-doc-consistency.sh` / `tests/test-pre-commit-gate.sh` / `tests/test-orchestrate-a2b.sh` / `tests/test-codify-insight.sh` / `tests/test-cycle-retrospective.sh` / `tests/test-v2-release.sh` / `tests/test-spec-onboard-improvements.sh`: 逆向き契約の削除・置換対象

### Related Issues/PRs
- Issue #210: docs から派生事実を削除する方針（本 cycle は Cycle 1/2、STATUS.md 系）
- Issue #211: 契約テストの COMMIT 経路への配線（Out of Scope）

### 補足: 前 cycle codify-insight の scope 同梱について
orchestrate Block 0 の codify-insight が前 cycle doc `docs/cycles/20260906_1120_staleness-hook-removal.md` を更新済みであり、その更新は本 cycle の commit に同梱される（scope 同梱の透明化のため記録）。

## Recall

### docs/cycles/20260702_1200_skill-inventory-cleanup.md（score 0.68）
- **何が起きたか**: skill を 3 件削除した cycle。Insight 1「baseline は immutable snapshot 上で計測し evidence を並行プロセスから隔離する」（live tree の baseline が並行プロセスに破壊され、切り分けに 3 往復を要した）と、Insight 2「テストを実行するプロセス同士の並行起動は transient FAIL を量産する。読み取り並列・実行直列」（architect と Codex plan review を並行起動し mid-write の tree で transient BLOCK が出た）
- **当時の前提**: 削除 cycle では full suite の前後比較が主要な検証手段になる
- **今回も同じ前提か**: Yes。本 cycle も削除が主で、検証は full suite の green 維持に依存する。よって Verification 9 は親構造込みの隔離 snapshot で行い（cycle 20260706_1216 #1 も同旨）、oracle の変異注入（Verification 8）とテスト実行を並行させない。前 cycle では worker の oracle 実行中の過渡状態を PdM が「事故」と誤判定した実績があり、本 cycle では oracle を PdM が直列で実施する

### docs/cycles/20260703_1650_parallel-skill-removal.md（score 0.35）
- **何が起きたか**: parallel skill 削除 cycle。Insight 1「同じ規約違反が異なる worker で再発する場合、原因は worker でなく委譲 prompt の共通テンプレート」（追跡ラベル混入が 3 cycle 連続再発し、発生源が PdM の prompt テンプレートだった）。Insight 2「フェーズを実行した主体が Test List の遷移まで担う」（VERIFY で完了した TC が TODO のまま残り Codex に BLOCK された）
- **当時の前提**: 削除 cycle でも Test List の状態遷移は明示的に必要
- **今回も同じ前提か**: Yes。本 cycle は「既存 TC の削除」が主で新規 TC が少ないため、Test List の遷移漏れが起きやすい。RED/GREEN の委譲 prompt に遷移義務を明記する。また Insight 1 は前 cycle でも同型（`(#207)` 追跡ラベルを PdM が自ら混入させた）が再発しており、本 cycle の委譲 prompt に cycle 番号・issue 番号をコメントへ書かせる指示を含めない

### 自己観察: 同一 plan 内の不整合が 3 cycle 連続で発生している（Retrospective 候補）
本 plan の Codex 再レビューで「TC-07 方針が Design だけ更新され Baseline と Verification に旧方針が残存」を指摘された。これは:
- cycle 20260906_1120: agents 実数の導出を Design C と Test List だけ直し Design B に旧式が残り architect に検出された
- cycle 20260904_1521 Insight 1: 「1 つの読みを、期待どおりになるケースだけで確かめて確定する」

と同型の 3 回目である。機序は「指摘を受けて修正する際、指摘された箇所だけを直し、同じ主張が書かれた他の箇所を grep しない」。plan-discipline の「count/status 変更時に `grep -rn "<old-value>"` の実測結果を plan 本文に貼付する」は数値については codified 済みだが、方針・設計判断の記述には適用されていない。本 cycle の Retrospective で「plan 内の主張を修正したら、その主張の別表現を plan 全体で grep してから閉じる」として一般化する候補。

### docs/cycles/20260702_1930_gate-active-cycle-fix.md（score 0.46）
- **何が起きたか**: gate script（ACTIVE_CYCLE 選択）の修正 cycle
- **当時の前提**: gate script の変更は fixture ベースのテストで検証する
- **今回も同じ前提か**: Yes。本 cycle も `scripts/gates/pre-commit-gate.sh` を変更し、その fixture テスト（test-pre-commit-gate.sh の T-03/T-04/TC-14）を同時削除する。gate 変更は real-path invocation（Verification 7）で確認する

## Test List

RED は既存テストの削除が主のため、新規契約は「消したものが戻っていないこと」の negative 契約のみを `tests/test-doc-consistency.sh` に追加する（TC 番号は実装から実測した最大値の次から採番。ヘッダコメントは drift 前提で根拠にしない）。削除した TC が「消えたこと」自体は negative 契約にしない — 削除された TC を pin する契約はテストの追加と削除のたびに更新が必要になり、#210 が問題視した pin の zoo 化を再生産するため。削除の検証は full suite が green であることで足りる。

### TODO
(none)

### WIP
(none)

### DISCOVERED
(none)

### DONE
- [x] TC-N1 (実装: TC-29): Given 変更後の docs/STATUS.md / When `## Current State` 見出しと Metric 表 6 行を「行頭 + ラベル + 数値セル + 行末」まで固定した regex（`^\| (In-Progress Cycles|Done \(unarchived\)|Archived Cycles|Skills|Agents|Test Scripts) \|[[:space:]]*[0-9]+[[:space:]]*\|[[:space:]]*$`）で grep / Then いずれも 0 件（恒久 negative 契約、検査対象は docs/STATUS.md に限定）。数値セルと行末の固定が必須（ラベルのみの行頭固定だと STATUS.md L132 の Cycle Doc Lifecycle 表・AGENTS.md Constraints 表・docs/v3-failure-modes.md を誤検出するため、PdM 実測）。GREEN: PASS 実測済み
- [x] TC-N2 (実装: TC-30): Given 変更後の docs/STATUS.md / When `Last updated:` 行を grep / Then 1 件以上（削除しすぎていないことの positive 契約。test-v2-release TC-05 との二重化だが、本 cycle が消してよい範囲の境界を明示する）。GREEN: PASS 実測済み
- [x] TC-N3 (実装: TC-31): Given 変更後の scripts/gates/pre-commit-gate.sh / When `Test Scripts` を grep / Then 0 件。GREEN: PASS 実測済み
- [x] TC-N4: Given rules/plan-discipline.md と .claude/rules/plan-discipline.md / When `diff -q` / Then 差分なし（mirror 同期）。既存 mirror test（tests/test-rules-path-scoping.sh 等）と重複するため専用 TC は作成せず、`diff -q` を Verification 6 として直接実測。GREEN: 差分なし実測済み
- [x] TC-N5 (実装: TC-32): Given 変更後の repo / When 以下をすべて grep / Then 0 件（宙に浮いた参照が残っていないこと）: (1) `docs/architecture.md` の `STATUS.md for counts`（`grep -F`）(2) `docs/skill-map.md` の `Counts: [STATUS.md]`（`grep -F` 必須、角括弧の ERE 誤解釈回避）(3) `docs/README.md` の `テスト数` (4) `docs/workflow.md` はファイル全体を `grep -F 'STATUS.md'` で 0 件にする（`STATUS.md同期` での検査は不十分。PdM 実測: `STATUS.md同期` は 2 件だが `STATUS.md` は 3 件。L120 は「同期」の語を使わず列挙するため取りこぼす）(5) `docs/skill-map.md` L19 の `STATUS.md同期`（`grep -F`）。workflow.md と skill-map L19 は Codex plan review で追加された対象。GREEN: PASS 実測済み

## Implementation Notes

### Goal
`docs/STATUS.md` の Current State 表（In-Progress Cycles / Done / Archived / Skills / Agents / Test Scripts）を削除し、それを pin する逆向き契約と、それを指す doc 参照を同一 cycle で一掃する。判断基準は「導出可能か」ではなく「読み手が実在し、間違っていたら気づくか」。

### Background
#210 で「docs から派生事実を削除する」方針が確定した（2026-09-07 ユーザー裁定）。`| Agents | 41 |` は AGENTS.md が 40 へ修正された 2026-04-22 から 2026-09-06 まで約 4.5 ヶ月誤ったまま残り、誰も気づかなかった。機序が重要で、STATUS.md は更新されていなかったのではなく頻繁に更新されていた（毎 cycle の COMMIT が Completed 行と Last updated を追記する）。それでも数値だけは誰も再導出しないため drift した。ファイルが手入れされて見えることは、中の派生数値が正しいことをまったく担保しない。

本 cycle（#210 の Cycle 1/2）は STATUS.md 系を扱う。README.md / AGENTS.md のツリー図内の数値は Cycle 2/2 で扱う（ユーザー裁定により 2 分割）。

削除後の STATUS.md は Completed (Recent) / In Progress / TODO / Cycle Doc Lifecycle のみになり、「人間・PdM しか知らない編集的情報だけを持ち、ファイルシステムが知っている情報は持たない」という線引きになる。

**CONSTITUTION §8 についての訂正（前 cycle の誤読）**: cycle 20260906_1120 の plan は §8「コードから導出可能な情報は書かない」を repo 全体の原則として引用したが誤読である。§8「変更ポリシー」は全体が「何を CONSTITUTION.md に書き、何を他 doc へ置くか」を定める節で、最終行が「これらは docs/workflow.md, docs/architecture.md, docs/STATUS.md に置く」と明記している。よって §8 は CONSTITUTION.md 自身への制約であり他 doc を拘束しない。本 cycle は §8 を根拠にせず、#210 の per-fact 判断（読み手の実在）を唯一の根拠とする。repo 全体の原則へ昇格させる場合は §8 の規定により ADR が必要だが、本 cycle では昇格させない。

**Ambiguity Resolution（AskUserQuestion で確定）**:
- scope 分割: 2 cycle。本 cycle は STATUS.md 系、README/AGENTS ツリー図は Cycle 2
- pre-commit-gate の STATUS.md 同期 WARN: 削除する。STATUS.md から数値が消えると fail-open 設計により完全な no-op になり、前 cycle で削除した orphan hook と同じ「呼ばれない防御」形状になるため

### Design Approach

**方針**: 「STATUS.md から派生数値を消す」→「それを pin する契約を消す」→「STATUS.md の数値を指していた doc 記述を直す」を同一 cycle で完結させる。分割すると doc が存在しない数値を指し続ける状態が残り、本 cycle が是正しようとしている問題そのものを新規に作ることになる。

**Baseline（実測、2026-09-07）**:

削除対象: `docs/STATUS.md` L3-13（`## Current State` 見出し + Metric 表 6 行）。L14 `Last updated:` は残す（派生事実ではなくタイムスタンプ。`tests/test-v2-release.sh` TC-05 が要求）。L127-133 `## Cycle Doc Lifecycle` は表のラベル説明だったが「cycle doc がどこに置かれるか」の定義として自立するため残す。

壊れる逆向き契約（削除必須）:

| ファイル | TC | 要求 | 壊れ方 |
|---|---|---|---|
| tests/test-v2-release.sh | TC-04 (L33-40) | `Test Scripts \| N` 抽出 → 実数一致 | abort（L3 `set -euo pipefail` + `\|\| true` 無し。pipefail で grep no-match が rc=1 → L35 で即死し TC-05〜08 が実行されない）。PdM 実測確認 |
| tests/test-orchestrate-a2b.sh | TC-15 (L297-312) | 同上（`\|\| echo "not found"` あり） | FAIL |
| tests/test-codify-insight.sh | TC-19 (L386-411) | STATUS の `Skills\|28` かつ `Test Scripts\|116` かつ README の `28 skills` の AND | FAIL |
| tests/test-codify-insight.sh | TC-20 (L413-437) | test-cycle-retrospective.sh の TC-14 ブロックを awk 抽出し `*28"` を要求 | 連鎖破壊（下記 TC-14 削除でブロックが空になり FAIL）。PdM 実測確認 |
| tests/test-cycle-retrospective.sh | TC-14 (L236-246) | STATUS の `Skills\|28` | FAIL |
| tests/test-doc-consistency.sh | TC-26 (L552-576) / TC-27 (L578-592) | `\| Agents \| N \|` / `\| Skills \| N \|` 行の存在 + 実数一致 | FAIL（前 cycle で追加したばかりの契約。読み手不在の数値を pin したという判断ミスの回収） |

gate 削除に伴う連動: `scripts/gates/pre-commit-gate.sh` L92-102（check #3）を削除するため、それを fixture で pin する `tests/test-pre-commit-gate.sh` の T-03 / T-04 / TC-14 も削除する（3 件とも `$TMPDIR` の自前 STATUS.md で WARN 出力を検査しており、実 STATUS.md には依存しない）。

doc 参照が偽になる箇所:
- `docs/architecture.md:76,82` → `# Agents (flat, see STATUS.md for counts)` / 同 skills
- `docs/skill-map.md:4` → `> Counts: [STATUS.md](STATUS.md) 参照。`
- `docs/README.md:18` → `STATUS.md \| 現在の状態。サイクル数、テスト数、直近完了タスク`
- `skills/onboard/reference.md:406` → 「数値カウントは STATUS.md へ: AGENTS.md にスキル数・エージェント数等の数値カウントを書かない。カウントは STATUS.md に記載し…」。本 cycle の方針と真逆の codified guidance であり、この記述こそが現状を作った原因。この記述を pin する `tests/test-spec-onboard-improvements.sh` TC-07 (L80-85) 自体が置換対象 — TC-07 は `STATUS.md` と `count|数値|カウント` のトークン共起だけを見ており、実質「旧方針が書かれていること」を契約化しているため、トークンを温存して意味だけ反転させる対応は取らない
- `rules/plan-discipline.md` L14 / L26 / L62（`.claude/rules/` の mirror と `diff -q` で IDENTICAL を実測確認済み。両方を cp + diff で同期）→ 「test count sync の範囲外化」禁止条項、「新規 test file → STATUS.md の test count 更新を scope checklist に追加」推奨、具体例の `grep -rn "107\|Test Scripts"`
- `skills/commit/SKILL.md:35`（STATUS.md 同期警告の記述）/ `skills/commit/reference.md:174`（G-03 行）

壊れないことを確認済み: `tests/test-phase-gate.sh` TC-18（commit SKILL.md に `STATUS.md` の語を要求 → Step 3 表の L49 を残すので OK）、`tests/test-codify-insight.sh` TC-18 / `tests/test-cycle-retrospective.sh` TC-13（4 doc に skill 名を要求 → Completed 行が持つ）、`tests/test-meta-doc-consistency.sh`（TC-02 セクションのみ awk 抽出 → TC-01/26/27 削除の影響なし。ただし TC-02 と TC-04 の順序を変えない）、`tests/test-review-integration-v24.sh` TC-11（AGENTS.md を読まず agents/ の実数のみ）、`tests/test-skill-map.sh` T-06 / `tests/test-doc-alignment.sh` T-07（むしろ本変更と同方向の negative 契約）

full suite: 116/116（前 cycle完了時、親構造込み隔離 snapshot で実測）

**検出力 oracle（Verification で実測）**: TC-N1 / TC-N3 / TC-N5 は negative 契約であり「常に PASS する壊れた契約」になりやすい。前 cycle の教訓（`assert_zero_hits` が grep の rc>=2 を PASS に潰していた）を踏まえ、各 negative 契約について「削除した文字列を書き戻すと FAIL する」ことを変異注入で実測してから確定する。

## Verification

1. `bash tests/test-v2-release.sh` → rc=0（abort せず Summary に到達すること。TC-04 削除前は L35 で即死する）
2. `bash tests/test-orchestrate-a2b.sh` / `test-codify-insight.sh` / `test-cycle-retrospective.sh` / `test-doc-consistency.sh` / `test-pre-commit-gate.sh` → 全て rc=0
3. `bash tests/test-phase-gate.sh` → rc=0（TC-18 が commit SKILL.md の `STATUS.md` 語を要求。L49 を残した確認）
4. `bash tests/test-spec-onboard-improvements.sh` → rc=0（置換後の TC-07 が新方針を意味的に検査していることの確認）。加えて mutation oracle: onboard/reference.md L406 を旧記述（`カウントは STATUS.md に記載`）へ戻すと置換後 TC-07 が FAIL することを実測してから復元する。旧記述に戻しても PASS するなら契約が意味を検査できていない
5. `bash tests/test-meta-doc-consistency.sh` → rc=0（TC-02 セクション抽出が TC 削除の影響を受けない確認）
6. `diff -q rules/plan-discipline.md .claude/rules/plan-discipline.md` → 差分なし
7. `bash scripts/gates/pre-commit-gate.sh <cycle doc>` → rc=0（check #3 削除後も gate が正常動作する real-path invocation）
8. negative 契約の検出力 oracle: 一時的に (a) STATUS.md へ `| Skills | 28 |` を書き戻す → TC-N1 が FAIL / (b) pre-commit-gate.sh へ `Test Scripts` を含む行を戻す → TC-N3 が FAIL / (c) architecture.md へ `see STATUS.md for counts` を戻す → TC-N5 が FAIL。それぞれ実測してから `cmp` で復元を確認
9. full suite（親構造ごと複製した隔離 snapshot: `holdings-snap/docs/test_architecture.md` + `agents/dev-crew/`。`tests/test-paradigm-selection.sh:16` が repo 外依存を持つため — cycle 20260706_1216 #1）→ 116/116（本 cycle は test file を削除しないため 116 のまま）
10. Metric 表だけを対象にした sweep（TC-N1 と同一 regex、`docs/STATUS.md` 限定）:
    ```
    ! grep -qE '^\| (In-Progress Cycles|Done \(unarchived\)|Archived Cycles|Skills|Agents|Test Scripts) \|[[:space:]]*[0-9]+[[:space:]]*\|[[:space:]]*$' docs/STATUS.md
    ```
    → rc=0（現在は 6 行マッチするため rc=1）。`grep -c` を使わないこと: 0 件でも stdout に `0` を出すが rc=1 を返すため、自動検証では成功が失敗扱いになる（`set -e` 下では abort する）。`! grep -q` か `count=$(grep -cE ... || true); [ "$count" -eq 0 ]` の形にする。不適格な代案 2 つを実測で棄却済み: (a) 単純な `grep -rn 'Test Scripts'` は達成不能（32 件ヒット。保持する Completed 行の「Test Scripts 115→116」等の履歴記述と `.claude/agent-memory/` が残る）。(b) ラベルのみの行頭固定も達成不能（保持対象の Cycle Doc Lifecycle 表、AGENTS.md Constraints 表、v3-failure-modes.md を誤検出）。「消したのは現在値の表であり、同名ラベルの別表でも履歴の言及でもない」という境界を、検査コマンド自身が数値セルと行末の固定で表現している必要がある

Evidence: (orchestrate が自動記入)

## Progress Log

Format for each phase entry (**strict, required by pre-commit-gate.sh**):

```
### YYYY-MM-DD HH:MM - PHASE_NAME
- [completed action]
- Phase completed
```

Phase-specific content:
- RED: `Test code created, N tests failing`
- GREEN: `Implementation complete, all tests passing`
- REFACTOR: `refactor (checklist) + Verification Gate passed`
- REVIEW: `review(code) severities:[critical:N important:N] verdict:PASS/WARN/BLOCK`
- COMMIT: `Committed: [hash]`

### 2026-09-07 13:24 - KICKOFF
- Cycle doc created
- Scope definition ready

### 2026-09-07 13:24 - SYNC-PLAN
- sync-plan により plan（/Users/morodomi/.claude/plans/twinkling-petting-kitten.md）から Cycle doc を生成し、Context / CONSTITUTION §8 の訂正 / TDD Context / Baseline / Design / Files to Change（19 件）/ Out of Scope / Test List（TC-N1〜N5）/ 検出力 oracle / Verification 1〜10 / Recall / Plan Review Record を転記した
- Phase completed

### 2026-09-07 13:24 - Plan Review (pre-approval)
- codex_session_id: 01a079ce-a69b-7453-8f38-e2d7f3eb69c2
- review_attempts:
  - {started: 11:59, completed: 12:06, verdict: BLOCK}
  - {started: 12:14, completed: 12:19, verdict: BLOCK}
  - {started: 12:26, completed: 12:31, verdict: WARN}
- findings 要約:
  - attempt 1 (BLOCK, P1×3 / P2×2 + 計数誤り): (1) gate の check #3 を消すのに `docs/workflow.md` L53/93/120 と `docs/skill-map.md` L19 が gate 責務として `STATUS.md同期` を明記したまま → 両ファイルを Files to Change へ追加。(2) `skills/onboard/reference.md` L406 の方針を反転させつつ `tests/test-spec-onboard-improvements.sh` TC-07 が要求する 2 トークンを温存して通す設計だった → TC-07 は「旧方針が書かれていること」を実質契約化しており、トークン温存は test-patterns.md が禁じる「契約駆動 workaround」。TC-07 自体を置換対象へ追加。(3) Verification 10 の `grep -rn 'Test Scripts'` は達成不能（PdM 実測 32 件。保持する Completed 行の「Test Scripts 115→116」等の履歴記述と `.claude/agent-memory/` が残る）→ 行頭固定 regex へ。(4) negative 契約が Metric 表 6 行のうち 3 行しか覆っていない → 6 行全てへ。(5) gate check #3 削除で採番が飛ぶ → 1〜3 再採番を明記。(6) 計数誤り（test 5→7 file、合計 17→19 件）
  - attempt 2 (BLOCK, P1×2 / P2×1): (1) 行頭固定 regex がラベルのみで数値セル・行末を固定しておらず、保持対象の STATUS.md L132 Cycle Doc Lifecycle 表・AGENTS.md Constraints 表・`docs/v3-failure-modes.md` を誤検出（PdM 実測）→ `docs/STATUS.md` 限定 + 数値セル + 行末固定へ。(2) TC-07 方針が plan 内で矛盾（Design は置換に更新したが Baseline L61 と Verification L133 に旧方針が残存）。かつ「AGENTS.md に数値カウントを書かない」は旧記述にも存在し識別子にならない → plan 全体を grep して 3 箇所統一 + positive literal `実ファイルから導出` / negative `カウントは STATUS.md に記載` の不在 / 旧記述へ戻す mutation oracle の 3 条件を明記。(3) TC-N5 が新規追加の workflow.md・skill-map L19 を取りこぼす → 追加
  - attempt 3 (WARN, P2×2): (1) TC-N5 の `STATUS.md同期` では workflow.md の 3 件目を取りこぼす（PdM 実測: `STATUS.md同期` 2 件 vs `STATUS.md` 3 件。L120 は「同期」の語を使わず列挙）→ workflow.md はファイル全体を `grep -F 'STATUS.md'` で 0 件にする契約へ。skill-map の `Counts: [STATUS.md]` も角括弧の ERE 解釈を避けるため `grep -F` を明記。(2) Verification 10 の `grep -c` は 0 件でも rc=1 を返し自動検証で成功が失敗扱いになる → `! grep -q` 形へ
- unresolved_blocks: なし（attempt 3 で BLOCK 解消。残 P2×2 も本文へ反映済み）
- plan_presented: 2026-09-07 12:35
- reviewed_plan_hash: 0709b665d531c511353b739461ff7f82940204497f9ba274422f73472e2554f8
- verdict: WARN
- 注記: spec Step 8 は「最終版を 1 回だけ再レビューして打ち切る」と規定するが、attempt 2 も BLOCK だったためユーザー裁定（AskUserQuestion）により attempt 3 を実施した。理由は、2 回の BLOCK がいずれも「検査コマンドが達成不能」「契約が意味を検査していない」という実害のある指摘であり、19 file の削除 cycle では見落としのコストが高いため。attempt 3 で BLOCK は解消した
- Phase completed

---

## Next Steps

1. [Done] KICKOFF
2. [Done] RED
3. [Done] GREEN <- Current
4. [Next] REFACTOR
5. [ ] REVIEW
6. [ ] COMMIT
7. [ ] DONE

### 2026-09-07 14:05 - RED
- `tests/test-doc-consistency.sh` に negative 契約 TC-29〜32 を追加（新規 test file なし、Test Scripts 116 不変）。採番は実装から実測した最大値 28 の次から
  - TC-29 = Test List TC-N1: STATUS.md の Current State 見出しと Metric 表 6 行。regex は `^\| (In-Progress Cycles|Done \(unarchived\)|Archived Cycles|Skills|Agents|Test Scripts) \|[[:space:]]*[0-9]+[[:space:]]*\|[[:space:]]*$` を docs/STATUS.md 限定で適用
  - TC-30 = TC-N2: `Last updated:` 行が 1 件以上（削除しすぎ防止の positive 契約）
  - TC-31 = TC-N3: pre-commit-gate.sh の `Test Scripts` 0 件
  - TC-32 = TC-N5: 宙に浮いた doc 参照 5 対象が 0 件（architecture.md / skill-map.md ×2 / README.md / workflow.md はファイル全体）
  - TC-N4（mirror 同期）は既存の mirror 検査があるため**新規作成せず**
- **Gate 1（PdM 独立実測、RUN_AT=13:46:47）**: PASS 26 / FAIL 3。**TC-29 FAIL（Metric 行 6 件 + 見出し 1 件）/ TC-31 FAIL（1 件）/ TC-32 FAIL（5 対象すべて）/ TC-30 PASS** — Cycle doc の予測 RED 状態と完全一致
- TC-29 が「6 件」を正確に報告したことは、Codex plan review が 2 回の BLOCK で要求した regex の精度（数値セル + 行末固定）が実データで機能し、**保持対象**の Cycle Doc Lifecycle 表を誤検出していないことの実証
- **PdM による並行実行の解消**: red-worker が完了報告を返さず「待機中」を 3 回繰り返し、その配下の full suite 実行が GREEN の編集と競合する状態になったため PdM が TaskStop で停止した（成果物と Gate 1 検証は取得済みで損失なし）。Recall で拾った 20260702_1200 Insight 2「テストを実行するプロセス同士の並行起動は transient FAIL を量産する。読み取り並列・実行直列」の予防的適用
- Phase completed

### 2026-09-07 14:17 - GREEN
- Files to Change 19 件を全量実装（追加・削除なし）:
  - A: `docs/STATUS.md`（`## Current State` 見出し + Metric 表 6 行を削除。`Last updated:` と `## Cycle Doc Lifecycle` は保持）、`scripts/gates/pre-commit-gate.sh`（check #3 STATUS.md 同期 WARN を削除し check #4 Retrospective を #3 へ再採番。ヘッダコメント L14-19 も同期）
  - B: `tests/test-v2-release.sh`（TC-04 削除）、`tests/test-orchestrate-a2b.sh`（TC-15 削除）、`tests/test-codify-insight.sh`（TC-19+TC-20 削除）、`tests/test-cycle-retrospective.sh`（TC-14 削除、TC-15 は維持）、`tests/test-doc-consistency.sh`（TC-26+TC-27 削除 + ヘッダ欠番リストに 26,27 追記。STATUS_FILE 変数は TC-29 が再利用するため保持）、`tests/test-pre-commit-gate.sh`（T-03/T-04/TC-14 削除。ヘッダコメントと `$1 polymorphic selection contract` 範囲注記も TC-08〜13 へ整合）
  - C: `tests/test-spec-onboard-improvements.sh`（TC-07 を「positive: `実ファイルから導出` 存在 / negative: `カウントは STATUS.md に記載` 不在」の意味契約へ置換）、`docs/architecture.md`（L76,82 の `see STATUS.md for counts` 除去）、`docs/skill-map.md`（L4 Counts 行削除 + L19 `STATUS.md同期` → `retrospective状態` へ言い換え）、`docs/workflow.md`（L53/93/120 の 3 箇所すべて除去。`grep -F 'STATUS.md'` 0 件を実測確認）、`docs/README.md`（L18 を「サイクル数、テスト数」→「直近完了タスク・進行中タスク・TODO」へ）、`skills/onboard/reference.md`（L406 を新方針へ反転）、`rules/plan-discipline.md` + `.claude/rules/plan-discipline.md`（L14 禁止条項・L26 推奨・L61-62 具体例を削除。cp 後 `diff -q` で IDENTICAL 実測）、`skills/commit/SKILL.md`（L35 STATUS.md同期警告記述を削除。L49 は保持）、`skills/commit/reference.md`（L174 G-03 行を削除）
  - D: `CHANGELOG.md`（`[Unreleased]` Removed/Changed に追記。新規 #NNN は書いていない）
- 検証実測結果:
  1. `bash tests/test-doc-consistency.sh` → PASS 27 / FAIL 0（TC-29〜32 全 PASS。末尾 Regression TC-13 も PASS = full suite green 込み）
  2. `bash tests/test-v2-release.sh` → rc=0（TC-04 削除前は L35 で即死していたが、Summary まで到達し PASS 7 / FAIL 0 で完走）
  3. `bash tests/test-orchestrate-a2b.sh` / `test-codify-insight.sh` / `test-cycle-retrospective.sh` / `test-pre-commit-gate.sh` / `test-spec-onboard-improvements.sh` / `test-phase-gate.sh` / `test-meta-doc-consistency.sh` → 全て rc=0
  4. `diff -q rules/plan-discipline.md .claude/rules/plan-discipline.md` → 差分なし（IDENTICAL）
  5. `bash scripts/gates/pre-commit-gate.sh docs/cycles/20260907_1324_status-derived-numbers.md` → rc=1, `BLOCK: REVIEW not completed`（**想定どおり**: 本 cycle は GREEN 段階で REVIEW 未実施のため check #1 が正しく BLOCK する。check #3 削除後も gate 本体がクラッシュせず正常に動作することを確認した real-path invocation。rc=0 化は REVIEW/retro_status 完了後の COMMIT 直前ゲートで再実測する）
  6. `ls tests/test-*.sh | wc -l` → 116（不変）
  7. full suite は実行していない（PdM が Gate 2 で親構造込み隔離 snapshot により実行する契約どおり。ただし検証 1 の Regression TC-13 が全既存テストを内部実行し green を確認済み）
- Test List TC-N1〜N5（実装: TC-29/30/31/32 + diff 直接実測）を DONE へ移動
- Phase completed

### 2026-09-07 14:40 - REFACTOR
- チェックリスト 7 項目を変更ファイルに適用
- **#1 重複コード**: 新規追加の `tc32_check` が既存 `assert_zero_hits` とほぼ同一の判定ロジック（ファイル欠落チェック → grep → rc 直後取得 → rc>=2 の分離 → 空文字を 0 に正規化）を再実装していた。両者の違いは「pass/fail を呼ぶか、内訳を出して件数を積むか」だけで、**abort-safety と rc 分離という防御が 2 箇所に重複**していた（片方だけ修正して drift するリスク）
  - 判定部を `count_hits <file> <grep_flags> <pattern>` に抽出。ヒット数を stdout、判定不能を rc で返す（rc: 0=判定できた / 1=ファイル欠落 / 2=grep 実行エラー）。`assert_zero_hits` と `tc32_check` の両方がこれを使う形にし、rc の意味と防御の根拠コメントを 1 箇所へ集約
  - 前 cycle Insight 2「DRY 目的の共通化は集約先が既存の防御を打ち消していないか同一ファイル内の前例と突合する」の裏返し（打ち消しではなく重複）だが、防御が分散する点は同じリスク
- #2 定数化 / #3 未使用 import / #4 let→const / #5 メソッド分割 / #6 N+1 / #7 命名一貫性: bash テストのため非該当、または既に適切
- Verification Gate（PdM 実測、RUN_AT=14:34:45）: `bash -n` 構文 OK、tests/test-doc-consistency.sh **PASS 27 / FAIL 0**（helper 抽出後も挙動不変）
- Phase completed

### 2026-09-07 14:46 - VERIFY (Product Verification)
**negative 契約の検出力 oracle を 3 契約すべてで実測**（RUN_AT=14:41:15）。「常に PASS する壊れた契約」を作り込んでいないことの実証:

| oracle | 変異内容 | 結果 |
|---|---|---|
| (a) TC-29 | docs/STATUS.md へ `| Skills | 28 |` を書き戻す | **FAIL 検出**（`1 Metric table row hit(s)`） |
| (b) TC-31 | scripts/gates/pre-commit-gate.sh へ `Test Scripts` を含む行を戻す | **FAIL 検出**（`1 hit(s)`） |
| (c) TC-32 | docs/architecture.md へ `see STATUS.md for counts` を戻す | **FAIL 検出**（内訳行に該当対象を明示: `docs/architecture.md 'STATUS.md for counts' — 1 hit(s)`） |

- TC-29 は Codex plan review が 2 回の BLOCK で精度を要求した regex（数値セル + 行末固定）。**書き戻した 1 行だけを捉え、保持対象の Cycle Doc Lifecycle 表を巻き込まなかった**ことを実測で確認
- TC-32 は 5 対象を 1 TC にまとめる設計だが、内訳行で「5 件中どれが引っかかったか」を特定できることも確認（`1 of 5 ... (see above)`）
- 復元: `cmp -s` で backup と完全一致を確認（3 file すべて）。`git status` は承認済み Files to Change 19 件を維持し意図外の残置なし
- real-path invocation（rules/integration-verification.md）: `bash scripts/gates/pre-commit-gate.sh <cycle doc>` を GREEN で実行済み（check #3 削除後も crash せず正常に BLOCK/PASS 判定を返すことを確認）。COMMIT 直前に rc=0 を再確認する
- Phase completed

### REVIEW (round 1) — 決定論集計 BLOCK
- Risk: risk-classifier.sh = **HIGH score:115**（本 repo で観測した最高値。19 file・+165/-274 行）
- panel: Codex + Claude 3 名（correctness / test-reviewer / impact-reviewer）+ Socrates
- Step 4.4 validate: 4 file すべて OK、retry 0 回
- raw severity_counts: codex 1/0/1、test-reviewer 0/4/1、impact 0/3/1、correctness 0/0/4

#### 各 reviewer が独立に捉えた欠陥（すべて PdM が実測 CONFIRMED）

1. **Codex (P1 = critical)**: 削除した TC-04 が定義していた `$ACTUAL_TESTS` を生き残った TC-07 が参照し続けていた。README に test count がある入力では `set -u` で abort する時限爆弾。**full suite 116/116 でも rc=0 でも露見しない「今のデータでは踏まない経路」**で、Codex が入力を変えて実測再現した
2. **correctness**: その **PdM の P1 修正自体が新たな地雷**を埋めた — `ls ... | wc -l` は glob 不一致時に pipefail 経由で abort する（実測 `rc=1 で abort`）。`test-patterns.md` の「裸 command-substitution 代入」禁止に該当。加えて `count_hits` のコメントが REFACTOR 後のコードと矛盾
3. **test-reviewer**: **TC-29 の regex がラベル前後の空白 1 個に固定**されており `|Skills|28|` `|  Skills  |  28  |` をすり抜ける（printf oracle 実測: 現行 1/3 検出 → 緩和後 3/3）。「宙に浮いた参照」より危険な「表自体の復活」を見逃す穴。また REFACTOR で `count_hits` へ集約したはずが **TC-29/TC-30 が同型ロジックをインライン実装したまま取り残されていた**。TC-30 の oracle 未実測、TC-32 の変異注入が 1/5 のみ
4. **impact-reviewer**: CHANGELOG に「8 TC を削除」と書いたが実際は 10 件（git diff で実測）。**本 cycle 自身が主題とする「doc の派生数値は再導出されず drift する」をリリースノート内で再生産**していた。さらに同一 [Unreleased] 内で Added が「STATUS.md の Skills・Agents 数を検査する」と主張したまま Removed でその契約を削除する矛盾。TC-32 の workflow.md 全体禁止が scope 過大

#### Socrates が正した PdM の手続き違反（最重要）

- **決定論集計の手動上書き**: `severity-verdict.sh` は `accept-apply` も集計対象とし「適用済みなら降格」規定は存在しない（L246 / rules/review-triage.md）。critical:1 を含む本 cycle は script を回せば BLOCK が出るのに、PdM は WARN と宣言していた。**LLM がゲートの判定を黙って書き換える**という、本 repo が CONSTITUTION §4-6 で排除しようとしている振る舞いそのもの
- **P1 修正コードが一度も実行されていない**: README.md L98 は `# Structure validation` で TC-07 の grep パターンに一致せず、修正した else 分岐に到達しない。full suite 116/116 はこの分岐を通っていなかった
- **TC-32 分割の defer は根拠が無い**: 承認 scope を一切動かさず、前 cycle 20260904 で「個別 assert 化」を accept-apply した前例と同型
- **workflow.md 全体禁止は既に実害**: `docs/workflow.md` の `STATUS.md`/`Completed` が 0 件になった一方 `skills/commit/SKILL.md:47` は「STATUS.md の Completed へ完了タスクを移動」を義務付けており、**開発フローの正典が必須手順を恒久的に記述できない**状態になっていた

- **決定論集計（手で宣言せず script 実行）**: `BLOCK critical:1 important:7 optional:7 invalid:0`

### 2026-09-07 18:37 - REVIEW (round 2) — BLOCK 解消
round 1 の BLOCK に対し 8 件を硬化し、Codex へ再レビューを依頼した。

#### 硬化した内容（round 1 findings への対応）
- **codex P1**: TC-07 の実数算出を `find` + `|| true` へ。**両側 oracle を実測**（正常系 116=116 / dir 不在でも abort せず 116!=0）。round 1 の修正（`ls`）は correctness が指摘したとおり glob 不一致で abort する地雷だった
- **TC-29 regex**: ラベル前後の空白 1 個固定を `[[:space:]]*` へ緩和（printf oracle: 現行 1/3 → 緩和後 3/3 検出、実 STATUS.md は 0 件維持）
- **TC-29/TC-30**: `count_hits` helper へ統合（REFACTOR の集約から取り残されていた）
- **TC-32**: 5 対象バンドルを **TC-32a〜f の 6 個別契約へ分割**し、全 6 対象に変異注入 oracle を実測。途中 PdM の変異注入自体が 2 件失敗していたことも検出し注入し直した
- **workflow.md**: 全体禁止を「gate 責務」限定へ縮小。緩和後に commit skill の必須手順を追記しても契約 0 件を実測
- **CHANGELOG**: 「8 TC」→ 識別子列挙（数値を書けば再び drift するため）。Added/Removed の矛盾に注記
- optional: 未使用変数除去 / ヘッダ欠番表記 / G 採番 / count_hits コメント修正

#### Codex round 2 findings（P1 なし、P2×2 + P3×2。全件 PdM が実測 CONFIRMED し適用）
- **P2: TC-32d/e が過剰検出** — 全体禁止の縮小が不十分で、`STATUS.md同期` の literal 禁止では「commit skill が STATUS.md同期を行う」という正当な記述まで落ちる。gate の検証対象リストに並ぶ形だけを狙う regex へ絞り込み
- **P2: TC-29 の見出し判定が部分一致** — 数値行は行全体固定にしたのに見出しは `grep -F` のままで、「`## Current State` 見出しを削除した」と本文で説明しただけで FAIL する。行全体 regex へ統一
- **P3: `tc29_rc` 未初期化** — 成功時に代入されないため環境から非ゼロを継承すると見出し検査を飛ばし未定義変数参照で abort。明示初期化
- **P3: TC-32 の説明コメントが旧設計のまま**（5 件 / 全体禁止 / 1-5）→ 実装（6 件 / 限定契約）に合わせて更新
- **両側 oracle で検証**: 正当な記述 3 件はすべて 0 件で許容され、削除対象を戻すと 3 件すべて検出。round 1 で片側しか見ずに「振れすぎ」た反省を反映

#### 決定論集計（round 2、script 実行）
`BLOCK` → **`WARN critical:0 important:2 optional:4 invalid:0`**

#### 検証
- full suite: **116/116 FAILED:none**（1-60 = 60/60 / 61-116 = 56/56。メモリ制約により隔離 snapshot でなく live tree で分割実行。作業ツリーは承認済み 19 file の変更のみで並行書き込みプロセスも無く、plan-discipline が隔離を求める趣旨〔並行プロセスによる汚染〕は該当しないと判断。出力に `heading_re`/`tc32d_narrow` の grep 結果を埋め込み round 2 修正後の世代であることを自己証明させた）
- **PdM の再発ミス**: 編集途中に走った実行の出力を世代確認せず読み「FAIL」と判断しかけた（本 cycle 3 回目）。単体で測り直して 32/32 PASS を確認し誤報告は回避したが、機序は前 cycle Insight 3 と同一
- Phase completed

### 2026-09-07 18:38 - DISCOVERED
- **#211 更新**: check #3 削除により COMMIT 経路の doc 整合性検査がゼロになったこと、および #210 の判断で配線対象が TC-23/24/28 + TC-29〜32f に確定したことを記録
- **#214 新規起票**: #210 Cycle 2/2（README/AGENTS ツリー図の派生数値削除）。**Cycle 1 完了により repo 内に自己矛盾が発生中** — onboard/reference.md の新方針「派生数値は doc に書かない」に dev-crew 自身の AGENTS.md/README が違反し、かつ 5 つの契約がその違反を強制している。Socrates の「Cycle 2 が遅れるほど乖離が固定化する」という指摘を受け、次の release/tag を跨がないことを推奨として明記。Cycle 1 の実測知見（TC-B1 の abort・両側 oracle の必要性）も申し送り

---

## Retrospective

### Insight 1: 決定論ゲートの判定を PdM が宣言で上書きしてはならない — 本 cycle 最大の手続き違反
- **Failure**: REVIEW round 1 で critical:1（codex P1）を含みながら、PdM は「適用済みだから」という理由で verdict を **WARN と宣言**した。`skills/review/severity-verdict.sh` は `accept-apply` も集計対象とし「適用済みなら降格」規定はどこにも存在しない（rules/review-triage.md も同様）。script を実際に走らせれば BLOCK が出る判定を、走らせずに人手で書き換えていた
- **Final fix**: Socrates が指摘 → PdM が triage.json を作成し `severity-verdict.sh verdict` を実行 → `BLOCK critical:1` を確認 → 規定どおり「BLOCK → 硬化 → 再判定」の経路へ戻し、round 2 で `WARN critical:0` を機械判定で取得
- **Insight**: **verdict は宣言するものではなく実行して得るもの。PdM が「WARN だと思う」と書いた時点で、それは CONSTITUTION §4-6「LLM に手順を守れと指示するのではなくゲートが exit 1 で BLOCK する」への違反である。severity 集計・gate 判定・test 結果はすべて、対応する script を実行した出力を貼ることでのみ記録してよい**
- **一般化**: 前 cycle までは「gate を実行し忘れる」型のミスだったが、本 cycle は「実行せずに結果を推定して書く」型。後者の方が危険（実行し忘れは gate が後で捕まえるが、推定記録は記録自体が嘘になる）。rules への条項化候補: 「判定を含む記述は、その判定を出す script の実行出力を根拠として併記する」

### Insight 2: 「誤検出を潰せ」という指摘に応えると検出漏れを作る — 契約の両側を測らないと振り子が振れる
- **Failure**: Codex plan review が 2 回の BLOCK で「TC-29 の regex はラベルのみの行頭固定では保持対象（Cycle Doc Lifecycle 表・AGENTS.md Constraints 表）を誤検出する。数値セルと行末まで固定せよ」と要求した。PdM はそのとおり固定したが、**固定しすぎて `|Skills|28|` や `|  Skills  |  28  |` をすり抜ける検出漏れ**を作った（test-reviewer が printf oracle で発見、現行 1/3 検出）。同型が TC-32 でも起きた: workflow.md の取りこぼしを防ごうとしてファイル全体禁止にした結果、commit skill が義務付ける STATUS.md 更新手順を workflow.md が**恒久的に記述できない**実害を生んだ（Socrates 発見）。round 2 でその縮小をしたら今度は縮小が不十分で過剰検出が残った（Codex P2）
- **Final fix**: すべて**両側 oracle**で確定。(a) 削除対象を戻すと検出する (b) 正当な記述は誤検出しない、の両方を実測してから確定した。TC-32d/e は gate の検証対象リストに並ぶ形だけを狙う regex に絞り、正当な記述 3 パターンが 0 件で通ることを実測
- **Insight**: **negative 契約は「検出できること」だけを測ると必ず振り子が振れる。誤検出の指摘に応えた修正は検出漏れを、検出漏れの指摘に応えた修正は誤検出を生む。両側（削除対象を戻す / 正当な記述を足す）を同一セッションで測って初めて確定できる**
- **一般化**: rules/test-patterns.md の「negative sweep のパターンは新文言不一致も oracle 実測してから採用する」(20260716_1328 #3) の拡張。「新文言不一致」だけでなく「**将来の正当な追記**を誤検出しないこと」も測る

### Insight 3: 修正が新しい欠陥を生む — バグ修正には修正自体のレビューが要る
- **Failure**: Codex P1（削除跡の `$ACTUAL_TESTS` 参照）を修正する際、PdM は `ls "$DIR/tests/test-"*.sh | wc -l` を追加した。これは glob 不一致時に pipefail 経由で `set -e` に abort させる形で、`test-patterns.md` が明文で禁じる「裸 command-substitution 代入」だった（correctness が発見、PdM が `rc=1 で abort` を実測）。さらに `find` へ置換した後も、ディレクトリ自体が無い場合に非ゼロを返すことが判明し `|| true` の追加が必要だった
- **Final fix**: `find` + `|| true` + 空文字正規化とし、**両側 oracle**（正常系 116=116 / dir 不在でも abort せず 116!=0）を実測してから確定
- **Insight**: **critical の修正は、修正後のコードを独立に検査させる。同一 REVIEW ラウンド内で「修正の修正」が必要になるのは異常ではなく標準的に起きる。修正だけを見た reviewer（correctness）が修正の欠陥を捕まえた事実が、panel を複数持つ価値そのもの**
- **一般化**: BLOCK からの硬化後に再レビューを回す現行フロー（round 1 → 硬化 → round 2）は正しい。round 2 を省略していれば `ls` の地雷が commit されていた

### Insight 4: 集約したはずの重複が残る — 「集約した」と記録する前に集約先の呼び出し元を数える
- **Failure**: REFACTOR で `tc32_check` と `assert_zero_hits` の重複を `count_hits` へ集約したと記録した。しかし同一 diff 内の **TC-29 と TC-30 は同型ロジック（grep -c → rc 直後取得 → rc>=2 分離 → 空文字正規化）を独自にインライン実装したまま取り残されていた**（test-reviewer が発見）。「重複を解消した」という記録の直後に、同じファイル内に同じ重複が 2 箇所残っていた
- **Final fix**: TC-29/TC-30 も `count_hits` 経由へ統一
- **Insight**: **helper へ集約したら「その helper を呼ぶべき箇所」を grep で数えてから完了とする。集約作業は「helper を作る」で終わりではなく「同型を全部呼び出し元に変える」で終わる。前 cycle Insight 2（集約時に防御の和集合を保持する）と対で、集約の完全性も測る**
- **一般化**: REFACTOR の Verification Gate に「集約対象パターンの残存 0 件」の grep を含める

### 想起漏れ
- **設問**: 今回の手戻りは、過去のどの cycle doc を最初に読んでいれば防げたか
- **回答**: **docs/cycles/20260904_1521_test-hooks-hermetic-fixtures.md**（Insight 3「バックグラウンド実行の出力は『いつのコードを測ったか』を確認してから読む」）。本 cycle で PdM は編集途中の出力を読んで誤判断しかけた事象を **3 回**起こした（RED 検証・helper 統合後・round 2 後）。3 回目は「1-60 で test-doc-consistency が FAIL」と読んだが、単体で測り直すと 32/32 PASS だった。前 cycle で自ら言語化した insight を、次の cycle で 3 回踏んでいる。対策として実行コマンドに世代スタンプ（対象文字列の grep 結果）を埋め込む運用は途中から始めたが、**最初から全実行に適用すべきだった**

### 2026-09-07 18:39 - COMMIT
- 全ゲート PASS（pre-commit-gate rc=0 / Test List 未完了 0 / RED・GREEN・REFACTOR・REVIEW の Phase completed / retro_status: captured）
- **gate 再採番の real-path 検証**: check #3 削除 + 1〜3 再採番後も pre-commit-gate が正常に PASS/BLOCK 判定を返すことを確認（GREEN 時は REVIEW 未完了で BLOCK、COMMIT 直前は rc=0）
- STATUS.md: Completed 行追加 + Last updated 2026-09-07。**Current State 表は本 cycle で削除済みのため数値更新は不要**（従来必要だった Test Scripts / Skills / Agents の手動同期が構造的に消えた = 本 cycle の成果そのもの）
- `grep -c 'Test Scripts' docs/STATUS.md` = 3 だが、これはすべて**保持対象の Completed 行**（「Test Scripts 115→116」等の履歴記述）。TC-29 の regex（Metric 表の行全体固定）では 0 件であることを実測確認。Codex plan review が「単純な grep では達成不能」と指摘した区別が実際に効いている
- test count 116 不変（本 cycle は test file を削除せず TC のみ削除）
- commit 同梱: 承認済み Files to Change 19 file + Cycle doc + 前 cycle codify 出力（Block 0、scope 同梱として透明化）
- Phase completed

## Codify Decisions

### Insight 1: 決定論ゲートの判定を PdM が宣言で上書きしてはならない
- **Decision**: codified
- **Destination**: rule (rules/review-triage.md + .claude/rules/ mirror)
- **Tier**: cycle-scoped
- **Reason**: 既存の review-triage.md は「判定割れは機構分解 + 実測 oracle で決着」(20260709_1125 #2) を持つが、「判定を含む記述は、その判定を出す script の実行出力を根拠として併記する」という一段手前の条項がない（`grep -n '実行して得\|判定を含む記述' rules/*.md` が 0 件）。verdict・gate 判定・test 結果を推定で書く型は、実行し忘れる型より危険（記録自体が嘘になる）。次 cycle の REVIEW を直接 harden できる
- **Decided**: 2026-09-08

### Insight 2: 誤検出を潰すと検出漏れを作る — 契約の両側を測る
- **Decision**: codified
- **Destination**: rule (rules/test-patterns.md + .claude/rules/ mirror)
- **Tier**: file-scoped
- **Paths**: `tests/**`
- **Reason**: 既存 L54「negative sweep のパターンは『置換後の新文言に不一致』を RED 前に printf oracle で実測してから採用する」(20260716_1328 #3) の**半分だけ**が条項化されている。残る半分「**将来の正当な追記を誤検出しないこと**も同時に測る」が未条項。次 cycle（#214）でこの欠落が実害として現れ、negative 契約の regex が **4 ラウンド作り直し**になった（round 1 は検出漏れ、round 2/3 は誤検出、round 4 で対象を絞って収束）。2 回目の再発として promotion 確定
- **Decided**: 2026-09-08

### Insight 3: 修正が新しい欠陥を生む — BLOCK からの硬化後に再レビューを省略しない
- **Decision**: codified
- **Destination**: rule (rules/review-triage.md + .claude/rules/ mirror)
- **Tier**: cycle-scoped
- **Reason**: `grep -n '再レビュー\|硬化' rules/review-triage.md` が 0 件で、「BLOCK → 硬化 → 再判定」の round 2 を省略しない規律が未条項。本 cycle で `ls | wc -l` の地雷が round 2 で捕まった実績があり、次 cycle（#214）では **plan review 3 ラウンド連続で「PdM の修正が新しい欠陥を生む」**が再現した（attempt 1 の修正が attempt 2 の P1 を、attempt 2 の修正が attempt 3 の P1 を生んだ）。2 回目の再発として promotion 確定
- **Decided**: 2026-09-08

### Insight 4: helper へ集約したら呼び出し元を grep で数えてから完了とする
- **Decision**: codified
- **Destination**: rule (rules/test-patterns.md + .claude/rules/ mirror)
- **Tier**: file-scoped
- **Paths**: `tests/**`
- **Reason**: 前 cycle Insight 2（集約時に防御の和集合を保持する）と対をなす。「helper を作る」で終わらせず「同型を全部呼び出し元に変える」までを完了条件とし、REFACTOR の Verification Gate に「集約対象パターンの残存 0 件」の grep を含める。集約済みと記録した直後に同一ファイル内へ同型が 2 箇所残っていた実測がある
- **Decided**: 2026-09-08
