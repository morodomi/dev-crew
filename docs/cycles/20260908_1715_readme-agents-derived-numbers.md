---
feature: README/AGENTS derived-number removal
cycle: 20260908_1715
phase: DONE
complexity: standard
test_count: 6
risk_level: low
retro_status: resolved
codex_mode: no
codex_session_id: "01a07e86-41cc-7391-84b6-1e5e662db190"
plan_file: /Users/morodomi/.claude/plans/twinkling-petting-kitten.md
created: 2026-09-08 17:15
updated: 2026-09-10 13:03
---

# README/AGENTS の派生数値を削除し、pin と連鎖契約を一掃する（#210 Cycle 2/2、issue #214）

## Scope Definition

### In Scope

- [ ] `AGENTS.md` — L65/L66 をツリー行の literal へ置換（L71 の `decisions (ADR)` は触らない）
- [ ] `README.md` — L93/L94 をツリー行の literal へ置換 + L104/107/110/113 見出しから `(13)(5)(7)(3)` を除去（見出し配下のスキル名リストは残す）
- [ ] `tests/test-skills-structure.sh` — L100-144（TC-B1 + TC-B2）削除
- [ ] `tests/test-agents-md-count.sh` — ファイルごと削除（`git rm`）
- [ ] `tests/test-doc-consistency.sh` — L26-34（TC-01）のみ削除、L24 の `ACTUAL_COUNT=` は保持。header 欠番リスト更新
- [ ] `tests/test-cycle-retrospective.sh` — L236-251（TC-15）削除。header を `TC-01 to TC-13（欠番: 14, 15）` へ
- [ ] `tests/test-agents-md-propagation.sh` — L32-44（TC-14）削除。header を `TC-08` へ（ファイルは残す）
- [ ] `tests/test-review-integration-v24.sh` — L164-169（TC-11）削除
- [ ] `tests/test-doc-consistency.sh` — TC-33a〜f + helper `assert_min_hits` / `assert_exact_hits` を追加（上記 5 と同一ファイル。実装ファイル数としては二重計上しない）
- [ ] `CHANGELOG.md` — `[Unreleased]` の Removed / Changed

**implementation files: 9**（番号 1〜10 のうち、`tests/test-doc-consistency.sh` の削除と追加は同一ファイルにつき二重計上しない）。

**commit に同梱される lifecycle artifact（実装対象ではないが差分に現れる）**:
- 本 Cycle doc（`docs/cycles/20260908_1715_readme-agents-derived-numbers.md`）
- `docs/STATUS.md`（commit skill Step 3 が「常に」Completed へ移動する）
- 前 cycle doc `docs/cycles/20260907_1324_status-derived-numbers.md`（Block 0 codify gate による `captured` → `resolved` 遷移。承認済み Files to Change には現れないが commit に同梱される。plan-discipline L41 に基づく scope 同梱の透明化）

### Out of Scope

- `tests/test-agents-structure.sh` の pass メッセージ内の陳腐化数値（L116 `All 32 agents`（実数 40 で既に誤り）、L412/428 `29 agents`、L517 `Declared roster (40)`、L673/683 `33 total` / `All 15`）— Reason: assertion ではなく表示文字列であり、契約は名前集合（TC-41）と frontmatter で成立している。ただし L116 が誰にも気づかれず誤っている事実は本 cycle の主張を補強する実例のため DISCOVERED に記録する
- `tests/test-skill-map.sh:59` T-06 / `tests/test-doc-alignment.sh:79` T-07 の stale literal `34 agents|28 skills`（`40 agents` の再混入を検出できない）— Reason: ユーザ裁定（AskUserQuestion 2026-09-08）により対象を AGENTS.md / README.md の 2 file に限定。DISCOVERED へ
- `ROADMAP.md` の「現在地」が v2.12.0 のまま（実際は v2.17.0 リリース済み）— Reason: 別種の doc drift。DISCOVERED へ
- `tests/test-agents-structure.sh:513` TC-41 の 40 名ハードコード roster（`g1_agents` 29 + `g23_names` 4 + `deferred_agents` 7）の実ファイル導出化 — Reason: Socrates Alternative C。agent 追加時の更新負担は本 cycle 後もここに残る。ただし TC-41 は名前集合 diff で重複・欠落を検出する実効契約であり、導出化には「実効性を失わない設計」が別途必要。DISCOVERED へ
- `scripts/gates/pre-commit-gate.sh:85` の check #2（Codex review 記録）が cycle doc 全体を `Codex.*review` で grep するため、Plan Review Record が転記された時点で恒久的に vacuous PASS になる（Socrates 指摘）— Reason: gate 自体の設計問題で本 cycle の scope 外。DISCOVERED へ
- 契約テストの COMMIT 経路への配線 — Reason: #211。本 cycle 完了により対象が確定する
- 本方針の CONSTITUTION 原則への昇格 — Reason: §8 の規定により ADR が必要

## Environment

### Scope
- Layer: Plugin repo（shell tests + markdown doc）
- Plugin: bash 3.2.57(1)-release (arm64-apple-darwin25) / jq 1.7.1 / git 2.49.0
- Risk: 10 (PASS) — Limited カテゴリ（test 修正・documentation）+10。Security/External/Data/Scope の +60/+40 は非該当（rubric: `skills/spec/reference.md` keyword score 表）

### Runtime
- Language: bash 3.2.57(1)-release (arm64-apple-darwin25)

### Dependencies (key packages)
- jq: 1.7.1
- git: 2.49.0

### Version Gate
- **PASS** — `.claude/dev-crew.json` `dev_crew_version: 2.17.0` = `installed_plugins.json` `2.17.0`（実測、plan Baseline 節）

### Risk Interview (BLOCK only)
- 該当なし（Risk 10 = PASS のため BLOCK インタビュー未発生）

## Context & Dependencies

### Reference Documents
- `skills/onboard/reference.md:406` — 「派生数値は doc に書かない」の配布指針。本 cycle が dev-crew 自身をこの指針に整合させる対象
- `skills/onboard/reference.md:359` — onboard は AGENTS.md をテンプレートから生成し dev-crew 自身の AGENTS.md をコピー・参照しない（緊急性の主張を撤回する根拠）
- `docs/architecture.md:76,82` — 置換の先例（既に新方針の形になっているツリー行）
- `docs/cycles/archive/20260309_1751` — TC-B1/TC-B2 が契約導入時点で既に誤っていたことを示す RED ログ（`TC-B1 (33 vs 32)` / `TC-B2 (19 vs 18)`）
- `rules/test-patterns.md` — `$(cmd) ... $?` 並置の fail-open パターン（RED sweep 設計で踏みかけた）
- `rules/plan-discipline.md` — 連番次値の実測（TC-33 採番）、Block 0 codify の scope 同梱透明化

### Dependent Features
- Cycle 1/2: `docs/cycles/20260907_1324_status-derived-numbers.md`（STATUS.md 系、PR #215、merge 済み）。本 cycle はその後半で、Cycle 1 完了により生じた repo 内の自己矛盾を解消する

### Related Issues/PRs
- Issue #210: per-fact 判断（2026-09-07 ユーザ裁定）の本体
- Issue #214: 本 cycle の起票元（PdM 起票、README 見出しスコープは #210 裁定に含まれず PdM 追加分と判明）
- Issue #211: 契約テストの COMMIT 経路への配線（Out of Scope → DISCOVERED）
- Issue #216: 承認前の決定論 lint（`scripts/gates/plan-lint.sh`）
- Issue #217: Step 8 findings triage + regex を RED へ移す
- Issue #218: 再混入契約の設計規則

## Recall

`bash scripts/recall-candidates.sh . AGENTS.md README.md tests/test-skills-structure.sh tests/test-agents-md-count.sh tests/test-doc-consistency.sh tests/test-cycle-retrospective.sh CHANGELOG.md` の実測上位:

### docs/cycles/20260421_2342_agents-md-count-fix.md（score 1.08）
- **何が起きたか**: `AGENTS.md` L65 を `41 agents` → `40 agents` に直し、`tests/test-agents-md-count.sh` を新規作成した cycle。本 cycle が削除する当のファイルを作った cycle である。Insight 1「`set -euo pipefail` 下で subject の rc と grep 結果を両方見たい時は pipe を使わず output capture → grep 分離」
- **当時の前提**: doc の数値は契約で pin して守る価値がある
- **今回も同じ前提か**: No — 明示的に覆す。当時の判断は「drift したから pin する」であり、pin は実際に機能した（本 plan Context の表）。本 cycle が覆すのは「そもそもその数値を doc に置く必要があるか」という一段上の問い。当時の判断が間違っていたのではなく、前提が変わった（#210 の per-fact 判断）。この cycle doc の Verification に `test-cross-references.sh が TC-B1 経由で PASS` と書かれていたことが、本 plan の ABORT 波及調査の出発点になった

### docs/cycles/20260702_1200_skill-inventory-cleanup.md（score 0.26、Cycle 1 からの継承）
- **何が起きたか**: skill 3 件削除。Insight 1「baseline は immutable snapshot 上で計測し evidence を並行プロセスから隔離する」、Insight 2「テストを実行するプロセス同士の並行起動は transient FAIL を量産する。読み取り並列・実行直列」
- **今回も同じ前提か**: Yes。本 cycle も削除が主で検証は full suite の green 維持に依存する。V-5 は親構造込み隔離 snapshot で行い、V-3 の変異注入は PdM が直列で実施する

### docs/cycles/20260703_1650_parallel-skill-removal.md（score 0.26）
- **何が起きたか**: Insight 1「同じ規約違反が異なる worker で再発する場合、原因は worker でなく委譲 prompt の共通テンプレート」（追跡ラベル混入が 3 cycle 連続再発）。Insight 2「フェーズを実行した主体が Test List の遷移まで担う」
- **今回も同じ前提か**: Yes。本 cycle は「既存 TC の削除」が主で新規 TC は 6 件（TC-33a〜f）のみのため Test List の遷移漏れが起きやすい。RED/GREEN の委譲 prompt に遷移義務を明記し、cycle 番号・issue 番号をコードコメントへ書かせる指示を含めない

### 自己観察（Cycle 1 から継続中の未解決パターン）
Cycle 1 の Retrospective は 4 件の insight を `captured` のまま残していたが、`docs/cycles/20260907_1324_status-derived-numbers.md` は 2026-09-08 に Block 0 codify gate によって `retro_status: resolved` へ遷移済み（`## Codify Decisions` 追記済み、実測: 本 cycle doc 生成時点で working tree に反映されている）。特に Insight 2（両側 oracle）は本 plan の Test List に先取りで適用済みであり、TC-33 の regex 設計（round 1〜4）がその最初の適用事例である。

## Test List

### TODO

**共通パターン**（実装で 1 度だけ定義し全 TC で共有する）:
```
TC33_TREE_RE='^[[:space:]│]*[├└]──[[:space:]]+(agents|skills)/.*[0-9]'
TC33_HEAD_RE='^###[[:space:]]+(Development Workflow|Security|Language Quality|Meta)[[:space:]]+\([[:space:]]*[0-9]+[[:space:]]*\)[[:space:]]*$'
```
regex は Codex plan review attempt 1 の P1 指摘（検出漏れ・過剰検出・相殺）を受けて全面再設計し round 4 で確定（両側 oracle は plan 段階で実測済み、詳細は plan `## Verification` V-3 と `## 両側 oracle` 節を参照）。round 4 が受け入れる限界: `agents/` `skills/` 以外のツリー行（例: `├── tests/  # 116 test scripts`）は対象外。TC33_HEAD_RE は 4 見出し名限定 + 括弧付きカウントを行末まで固定するため `### Security for PHP 8` 等の正当な将来記述は誤検出しない。

（TC-33a〜f は RED 実装完了・実測 FAIL/PASS 確認済みのため WIP へ移動。下記 WIP セクション参照）

**TC-33f を「合計 4 件」にしてはいけない**（Codex P1-3、PdM 実測で再現）: 合計方式は `### Development Workflow` の重複と `### Security` の欠落が相殺して 4 件になり PASS してしまう。実測 fixture（Development Workflow ×2、Security 欠落、Language Quality ×1、Meta ×1）で合計方式は 4 件＝PASS、個別方式は `Development Workflow=2` / `Security=0` を検出した。4 見出しを**個別に** exact-1 検査すること。

**RED での期待挙動**（red-worker が「RED が壊れている」と誤報告しないための明示）:

| TC | RED（doc 未編集）での結果 | 理由 |
|---|---|---|
| TC-33a / 33b | FAIL | doc に数値が残っている |
| TC-33c | FAIL | 見出しに `(13)` 等が残っている |
| TC-33d / 33e | PASS | ツリー行は最初から存在する。overshoot 防止のガードであり RED→GREEN 遷移を持たない |
| TC-33f | FAIL | 現在の見出しは `### Security (5)` で、`$` 終端の regex に一致しない（0 件） |

**新規 helper が必要**（`tests/test-doc-consistency.sh` に追加）: 既存の `assert_zero_hits`（L452-465）は 0 件契約専用で `>= 1` や `== N` を表現できない。TC-33d/e/f のために `count_hits` を土台にした **`assert_min_hits`（tc_id, file, flags, pattern, min, label）** と **`assert_exact_hits`（... expected, label）** を追加する。両者とも `assert_zero_hits` と同一の防御を持たせること — `hits=$(count_hits ...) || rc=$?` の形で rc を分離し、rc=1（ファイル欠落）と rc=2（grep 実行エラー）を vacuous PASS にせず `fail()` で報告する。裸の `hits=$(count_hits ...)` にすると `test-meta-doc-consistency.sh` の fixture（`AGENTS.md` を作らない）で `set -euo pipefail` 下に abort し、meta test 3 TC が連鎖 FAIL する。

**削除した TC が「消えたこと」自体は negative 契約にしない** — Cycle 1 の判断（pin の zoo 化を再生産する）を踏襲。削除の検証は full suite が green であることで足りる。

**RED の完了条件（機械ゲート、`echo` で終わらせず exit code で判定する）**:
```bash
red_sweep_ok=1
check() {
  rc=0
  grep -qE "$2" "$1" 2>/dev/null || rc=$?
  case "$rc" in
    0) echo "NG: pattern still present in $1"; red_sweep_ok=0 ;;
    1) echo "ok: $1" ;;
    *) echo "NG: grep failed on $1 (rc=$rc) — cannot verify"; red_sweep_ok=0 ;;
  esac
}
check tests/test-skills-structure.sh        'TC-B1|TC-B2'
check tests/test-doc-consistency.sh         '^# TC-01:'
check tests/test-cycle-retrospective.sh     '^# TC-15:'
check tests/test-agents-md-propagation.sh   '^# TC-14:'
check tests/test-review-integration-v24.sh  '^# TC-11:'
if [ -f tests/test-agents-md-count.sh ]; then echo "NG: test-agents-md-count.sh still exists"; red_sweep_ok=0; else echo "ok: removed"; fi
echo "RED_SWEEP_OK=$red_sweep_ok"
[ "$red_sweep_ok" -eq 1 ]
```
最終行の `[ "$red_sweep_ok" -eq 1 ]` がブロックの rc を決める。`echo` で終わらせると `RED_SWEEP_OK=0` でも rc=0 になり機械ゲートとして機能しない。

### WIP
(none)

### DISCOVERED

Out of Scope（plan `## Out of Scope`）からの転記候補:

- `tests/test-agents-structure.sh` の pass メッセージ内の陳腐化数値（L116 `All 32 agents` は実数 40 で既に誤り。L412/428 `29 agents`、L517 `Declared roster (40)`、L673/683 `33 total` / `All 15`）— assertion ではなく表示文字列。L116 の誤りは「pin なしの数値は誰にも気づかれず誤ったままになる」実例として記録
- `tests/test-skill-map.sh:59` T-06 / `tests/test-doc-alignment.sh:79` T-07 の stale literal `34 agents|28 skills`（`40 agents` の再混入を検出できない）— ユーザ裁定により本 cycle は AGENTS.md / README.md の 2 file に限定
- `ROADMAP.md` の「現在地」が v2.12.0 のまま（実際は v2.17.0 リリース済み）
- `tests/test-agents-structure.sh:513` TC-41 の 40 名ハードコード roster の実ファイル導出化（Socrates Alternative C）。TC-41 自体は名前集合 diff で重複・欠落を検出する実効契約であり、導出化には実効性を失わない設計が別途必要
- `scripts/gates/pre-commit-gate.sh:85` の check #2 が cycle doc 全体を `Codex.*review` で grep するため、Plan Review Record 転記時点で恒久的に vacuous PASS になる（Socrates 指摘、gate 設計問題）
- 契約テストの COMMIT 経路への配線（issue #211、本 cycle完了で対象確定）
- 本方針の CONSTITUTION 原則への昇格（§8 により ADR が必要）
- `reviewed_plan_hash` フィールド名の改名（検証しているのは「レビュー来歴」ではなく「承認時点から本文が不変であること」であり、フィールド名が誤解を誘う）

### DONE

- [x] TC-33a: Given 変更後の `AGENTS.md` / When `TC33_TREE_RE` を `-cE` で grep / Then 0 件（RED: FAIL → GREEN: `AGENTS.md` L65/66 を置換 literal へ編集し PASS を実測確認）
- [x] TC-33b: Given 変更後の `README.md` / When 同 `TC33_TREE_RE` / Then 0 件（RED: FAIL → GREEN: `README.md` L93/94 を置換 literal へ編集し PASS を実測確認）
- [x] TC-33c: Given 変更後の `README.md` / When `TC33_HEAD_RE` を `-cE` で grep / Then 0 件（RED: FAIL → GREEN: L104/107/110/113 見出しから件数表記を除去し PASS を実測確認）
- [x] TC-33d: Given 変更後の `AGENTS.md` / When `├── agents/` と `├── skills/` を `-cF` で grep / Then 各 1 件以上（overshoot 防止の positive 契約であり RED→GREEN の FAIL→PASS 遷移を持たない。GREEN 後も PASS 維持を実測確認）
- [x] TC-33e: Given 変更後の `README.md` / When 同 / Then 各 1 件以上（TC-33d と同一理由で RED→GREEN 遷移を持たない。GREEN 後も PASS 維持を実測確認）
- [x] TC-33f: Given 変更後の `README.md` / When 4 見出しを `^### <name>$` で 1 つずつ grep / Then 各ちょうど 1 件（RED: FAIL ×4 → GREEN: 4 見出し全てで件数表記除去後 PASS を実測確認）

## Implementation Notes

### Goal
`skills/onboard/reference.md:406` の「派生数値は doc に書かない」指針に dev-crew 自身の `AGENTS.md` / `README.md` を整合させ、その違反を強制していた逆向き契約（6 TC・4 ファイル直接 + 1 ファイル二次）を削除し、再混入を防ぐ静的な negative/positive 契約（TC-33a〜f）に置き換える。

### Background
#210 の per-fact 判断（2026-09-07 ユーザ裁定）に基づく削除作業の後半（Cycle 1/2 は STATUS.md 系、PR #215、merge 済み）。Cycle 1 で `skills/onboard/reference.md` L406 の指針が反転されたことで repo 内に自己矛盾が生じている。

削除根拠は「全部が drift する」ではなく per-fact:

| 事実 | 現在の pin | drift 実績 | 削除根拠 |
|---|---|---|---|
| `AGENTS.md:65` `40 agents (flat)` | TC-B1 + `test-agents-md-count.sh` 全体（TC-01/TC-02）。二次的に `test-agents-md-propagation.sh` TC-14 | 契約導入時点で既に誤っていた（20260309_1751 RED ログ: `TC-B1 (33 vs 32)`）。契約導入後の drift も検出（2026-04-21 に 41→40） | pin は機能しているが代償が 3 TC + 二次 1 TC・約 95 行 |
| `AGENTS.md:65` `19 security agents` | TC-B2 | 契約導入時点で既に誤っていた（`TC-B2 (19 vs 18)`）。契約以後の drift 記録はなし | 同上。さらに強い根拠: 契約が無い間この数値は誰にも気づかれず誤ったままだった |
| `AGENTS.md:66` `28 skills` | なし（無契約） | 未検出（現在値は正しい） | STATUS.md の `\| Agents \| 41 \|` が 4.5 ヶ月誤ったまま放置されたのと同一形状 |
| `README.md:93,94` `40 agents` / `28 skills` | TC-01 + TC-15 | なし | 2 契約のコスト |
| `README.md:104,107,110,113` `(13)(5)(7)(3)` | なし（無契約） | 未検出（現在値は正しい。13+5+7+3=28 で実数一致） | 無契約。次に skill を増減した瞬間に静かに誤りになる |

半分は pin されており（コストの問題）、半分は無契約（drift 爆弾）。両者とも削除に帰着するが理由は別。

**緊急性の主張は撤回済み**（Socrates 指摘、PdM 実測で確認）: onboard は AGENTS.md をテンプレートから生成し dev-crew 自身の AGENTS.md をコピー・参照しないため、tag を跨いでも誤った配布物は生まれない。dogfood 矛盾は原則整合の問題として本物だが時限性はない。dogfood 論拠の射程も `reference.md:406` が名指しする AGENTS.md / STATUS.md のみに限定され、README の 6 行は per-fact 表の行 4・行 5 単独で支える。

**CONSTITUTION は根拠にしない**: §8「コードから導出可能な情報は書かない」は「何を CONSTITUTION.md に書くか」を定める節であり repo 全体の原則ではない（Cycle 1 で訂正済み）。§7「5-Layer Authority」も layer 間矛盾の裁定規則であり本件（dogfood 矛盾）には当たらない。根拠は #210 の per-fact 判断と dogfood 整合の 2 点のみ。

**Ambiguity Resolution（AskUserQuestion、2026-09-08）**:
- `test-review-integration-v24.sh` TC-11 の hardcoded `40` は本 cycle で修正する
- 新設 negative 契約 TC-33 の検査対象は AGENTS.md と README.md のみ（`docs/architecture.md` / `docs/skill-map.md` には既に T-07 / T-06 という別の negative 契約があるため対象を重ねない）

**Socrates 反論への裁定（AskUserQuestion、2026-09-08）**:
- 反論1（README 見出し `(13)(5)(7)(3)` は残すべきでは）: 裁定は現行維持（削除する）。見出しの数値はどの契約にも pin されていない（`grep -rn 'Development Workflow (' tests/ scripts/ skills/ rules/ .claude/rules/` が 0 件）。「1 行下を数えれば目視できる」は「誰かが数え直す」という人間の規律への依存であり #210 が STATUS.md で否定した前提そのもの
- 反論2（Alternative C: 正味で得か）: 裁定は実行する。理由は本数（8→6 で微減）ではなく性質の変化 — 旧契約は agent/skill 増減のたびに数値の追随更新を要求するが新契約（静的 negative/positive）は永久に更新不要。TC-41 の roster 導出化は DISCOVERED へ

### Design Approach

**A. phase 分割 — RED がテスト側、GREEN が doc 側を持つ**:
- RED（red-worker）: 契約の削除（TC-B1/B2、`test-agents-md-count.sh` ファイルごと、TC-01、TC-15、TC-14、TC-11）と新規 negative/positive 契約 TC-33a〜f の追加。この時点で新契約は FAIL（doc に数値が残っているため）
- GREEN（green-worker）: `AGENTS.md` / `README.md` / `CHANGELOG.md` のみを編集

**順序が必須である理由**: 逆順（GREEN が先に数値を消す）にすると TC-B1 が abort し、`test-skills-structure.sh` は TC-B2 も Summary も出さずに rc=1 で死ぬ。RED が契約を先に消せば `test-skills-structure.sh` は rc=0 で Summary に到達し（実測済み）、以降の判定は常に読める。REFACTOR はテストを触ることを禁じられているため、この分割以外に安全な順序はない。

**RED の部分実行が GREEN で修復不能になる問題への対策**（Socrates 指摘）: red-worker が削除を一部やり残すと、doc 未編集の RED 時点では PASS してしまい漏れが見えず、GREEN が doc を編集した瞬間に FAIL するが green-worker はテストを触れないため自力で直せない。したがって RED の完了条件に「削除識別子の 0 件 sweep」を機械的に含める（上記 Test List の RED sweep ブロック、`grep -c` は使わず `grep -qE ...; rc=$?` の即時 abort を避けるため `|| rc=$?` で受ける）。

**B. Files to Change** の詳細は Scope Definition 参照。`AGENTS.md` L65/L66 の置換 literal:
```
├── agents/          # Agent definitions (flat), security agents included
├── skills/          # Skills (each: SKILL.md + reference.md)
```
`README.md` L93/L94 の置換 literal（`docs/architecture.md:76,82` の先例に逐語で揃える）:
```
├── agents/                      # Agents (flat)
├── skills/                      # Skills (flat)
```
見出し L104/107/110/113 は `(13)(5)(7)(3)` を除去し `### Development Workflow` / `### Security` / `### Language Quality` / `### Meta` へ。この 8 本の literal に対して TC-33 の全 regex を実測済み（合成 fixture ではなく実際に書き込む文字列に対する oracle）。

**委譲 prompt の制約**（recall: cycle 20260703_1650 Insight 1）: RED/GREEN の委譲 prompt に (a) 追跡番号・issue 番号・cycle 番号をコードコメントへ書かせる指示を含めない、(b) Test List の状態遷移（TODO → DONE）を実行主体が担うことを明記する、の 2 点を必ず入れる。

## Verification

**すべて bash code block として書く。** `skills/orchestrate/reference.md` の Product Verification 実装は「`## Verification` セクション内の bash コードブロックからコマンドを抽出して順次実行する」と規定しており、inline code は抽出されない。各ブロックは独立に実行される前提なので `SCRATCH` 等の変数はブロックごとに定義する。判定は実行した出力を根拠として貼る。

### V-1: abort が解消し、rc-consumer が回復する

```bash
set -uo pipefail
cd "$(git rev-parse --show-toplevel)"
echo "GEN-STAMP: TCB1=$(grep -c 'TC-B1' tests/test-skills-structure.sh || true) files=$(find tests -maxdepth 1 -name 'test-*.sh' | wc -l | tr -d ' ')"
# 1) abort していないこと: rc=0 かつ Summary に到達
out=$(bash tests/test-skills-structure.sh 2>&1); rc=$?
printf 'test-skills-structure rc=%d summary=%d\n' "$rc" "$(printf '%s' "$out" | grep -c '=== Summary ===' || true)"
# 2) rc-consumer 5 件（6 件目の test-agents-md-count.sh は削除されるため対象外）
for t in test-cross-references test-stale-references test-precompact test-orchestrate-compact test-no-auto-transitions; do
  r=0; bash "tests/$t.sh" >/dev/null 2>&1 || r=$?
  printf '%s rc=%d\n' "$t" "$r"
done
# 3) 削除したファイルが実在しないこと
[ -f tests/test-agents-md-count.sh ] && echo "NG: still exists" || echo "ok: test-agents-md-count.sh removed"
```
期待: `rc=0 summary=1`、5 行すべて `rc=0`、`ok: ... removed`。

### V-2: 削除の地雷（共有変数・abort 増幅器）が踏まれていない

```bash
set -uo pipefail
cd "$(git rev-parse --show-toplevel)"
for t in test-doc-consistency test-meta-doc-consistency test-cycle-retrospective test-agents-md-propagation test-review-integration-v24; do
  r=0; bash "tests/$t.sh" >/dev/null 2>&1 || r=$?
  printf '%s rc=%d\n' "$t" "$r"
done
# ACTUAL_COUNT 保持の確認（TC-02 が vacuous PASS 経路を通ること）
bash tests/test-doc-consistency.sh 2>&1 | grep -c 'does not hardcode skill count' || true
# meta test が「abort 前に死んだ」報告を出していないこと
bash tests/test-meta-doc-consistency.sh 2>&1 | grep -c 'aborted before reaching Summary' || true
```
期待: 5 行すべて `rc=0`、`does not hardcode` が 1、`aborted before` が 0。

### V-3: TC-33a〜f の変異注入 oracle（両側・最小単位）

**変異は必ず最小単位へ分解して 1 つずつ行う。** round 1 の穴（`40 agents` と `19 security agents` を一体で戻すと前者だけで検出されて後者の漏れが隠れる）の再発防止。変異注入とテスト実行を並行させない。

```bash
set -uo pipefail
cd "$(git rev-parse --show-toplevel)"
SCRATCH=$(mktemp -d)
cp AGENTS.md "$SCRATCH/A.orig"; cp README.md "$SCRATCH/R.orig"
restore() { cp "$SCRATCH/A.orig" AGENTS.md; cp "$SCRATCH/R.orig" README.md; }
# 後始末は `rm -r` を使う。強制フラグ付きの再帰削除は ~/.claude/hooks/bash-safety.sh が
# 文字列一致で exit 2 ブロックするため、このコメント自体にもその綴りを書かない
# （実測: grep パターンに含めただけでブロックされた）。
trap 'restore; rm -r "$SCRATCH"' EXIT INT TERM

probe() { # $1=説明 $2=期待FAILするTC $3=期待FAIL件数
  r=0; out=$(bash tests/test-doc-consistency.sh 2>&1) || r=$?
  # fail() は printf "  \033[31mFAIL\033[0m %s\n" で出力するため、FAIL と TC 名の間に
  # ANSI reset が入る。固定文字列 'FAIL TC-33a' では 0 件になる（実測）ので -E で .* を挟む。
  got=$(printf '%s' "$out" | grep -cE "FAIL.*$2" || true)
  if [ "$got" -eq "$3" ]; then st=ok; else st="NG(expected $3)"; fi
  printf '%-52s %s got=%s %s\n' "$1" "$2" "$got" "$st"
  restore
}
# --- negative 契約: 削除した形を最小単位で戻すと検出するか ---
sed -i '' 's|# Agent definitions (flat), security agents included|# 40 agents (flat)|' AGENTS.md;         probe "AGENTS: 40 agents だけ戻す" TC-33a 1
sed -i '' 's|# Agent definitions (flat), security agents included|# Agent definitions, 19 security agents|' AGENTS.md; probe "AGENTS: 19 security agents だけ戻す" TC-33a 1
sed -i '' 's|# Skills (each: SKILL.md + reference.md)|# 28 skills|' AGENTS.md;                            probe "AGENTS: 28 skills を戻す" TC-33a 1
sed -i '' 's|# Agents (flat)|# 40 agents|' README.md;                                                    probe "README: 40 agents を戻す" TC-33b 1
sed -i '' 's|# Skills (flat)|# 28 skills|' README.md;                                                    probe "README: 28 skills を戻す" TC-33b 1
sed -i '' 's|^### Security$|### Security (5)|' README.md;                                                probe "README: ### Security (5) へ戻す" TC-33c 1
sed -i '' 's|^### Security$|### Security ( 5 )|' README.md;                                              probe "README: 空白変種 ( 5 )" TC-33c 1
# --- positive 契約: 削除しすぎを検出するか ---
sed -i '' '/^├── agents\//d' AGENTS.md;                                                                  probe "AGENTS: agents ツリー行を削除" TC-33d 1
sed -i '' '/^├── skills\//d' README.md;                                                                  probe "README: skills ツリー行を削除" TC-33e 1
sed -i '' 's|^### Security$||' README.md;                                                                probe "README: ### Security 見出しを削除" TC-33f 1
# --- 相殺の検出（合計方式なら通ってしまう形）---
# TC-33f は 4 見出しを個別に exact-1 検査するため、DW 重複(2件) と Security 欠落(0件) の
# 2 つが独立に FAIL する。期待値は 1 ではなく 2（Codex attempt 3 指摘）。
sed -i '' 's|^### Security$|### Development Workflow|' README.md;                                        probe "README: DW 重複 + Security 欠落" TC-33f 2
# --- helper の rc=1 経路（vacuous PASS でなく fail であること） ---
mv AGENTS.md "$SCRATCH/A.hidden";                                                                        probe "AGENTS.md を不在にする" TC-33a 1
cp "$SCRATCH/A.orig" AGENTS.md
if cmp -s AGENTS.md "$SCRATCH/A.orig" && cmp -s README.md "$SCRATCH/R.orig"; then echo "restored: ok"; else echo "restored: NG"; fi
```
期待: 各行が `ok`（期待件数と実測が一致）、最後に `restored: ok`。`NG` が 1 つでもあれば契約が変異を検出できていない。
`probe` は期待件数を引数で受ける — TC-33f の相殺 probe だけは**2 件 FAIL が正しい**（4 見出しを個別検査するため、重複と欠落が別々に落ちる）。一律「1」を期待すると、正しく動いている契約を NG と誤判定する。

### V-4: pre-commit-gate（二段階）

`## Verification` は orchestrate Block 2c.5 で REVIEW **より前**に実行されるため、この時点で gate が rc=0 になることは構造的にありえない（`scripts/gates/pre-commit-gate.sh` が REVIEW 完了を最初に検査する）。よって VERIFY 時点は「正しく BLOCK すること」を確認する。

```bash
set -uo pipefail
cd "$(git rev-parse --show-toplevel)"
CYCLE=$(ls -t docs/cycles/*.md | head -1)
r=0; out=$(bash scripts/gates/pre-commit-gate.sh "$CYCLE" 2>&1) || r=$?
printf 'gate rc=%d review_block=%d\n' "$r" "$(printf '%s' "$out" | grep -ci 'REVIEW' || true)"
```
VERIFY 時点の期待: `rc=1` かつ REVIEW 未完了の BLOCK メッセージ。
**COMMIT 直前**（REVIEW + RETROSPECTIVE 完了後）に同ブロックを再実行し `rc=0` を確認する — これは Block 3 の責務であり VERIFY では要求しない。

### V-5: full suite（隔離 snapshot、115/115）

```bash
set -uo pipefail
cd "$(git rev-parse --show-toplevel)"
TREE_RE='^[[:space:]│]*[├└]──[[:space:]]+(agents|skills)/.*[0-9]'
stamp=$(grep -cE "$TREE_RE" AGENTS.md README.md 2>/dev/null | tr '\n' ' ' || true)
echo "GEN-STAMP: tree_hits=[$stamp] files=$(find tests -maxdepth 1 -name 'test-*.sh' | wc -l | tr -d ' ')"
# 親構造ごと複製（tests/test-paradigm-selection.sh が $BASE_DIR/../../docs/ を読む）
SNAP=$(mktemp -d)
# repo 全体の複製を残さない。強制フラグ付きの再帰削除は bash-safety.sh に
# ブロックされるため `rm -r` を使う（綴りを書くとこのブロック自体が実行不能になる）
RESULT=$(mktemp)
trap 'rm -r "$SNAP"; rm -f "$RESULT"' EXIT INT TERM
mkdir -p "$SNAP/docs" "$SNAP/agents"
cp ../../docs/test_architecture.md "$SNAP/docs/" 2>/dev/null || true
cp -R . "$SNAP/agents/dev-crew"
( cd "$SNAP/agents/dev-crew"
  for f in tests/test-*.sh; do r=0; bash "$f" >/dev/null 2>&1 || r=$?; printf '%s rc=%d\n' "$(basename "$f")" "$r"; done | sort > "$RESULT" )
echo "total=$(wc -l < "$RESULT" | tr -d ' ')"
grep -v 'rc=0$' "$RESULT" || echo "rc!=0: none"
```
結果ファイルは `$SNAP` の外（`$RESULT`）に置く — snapshot ごと消すと集計結果まで消えるため。
期待: `tree_hits=[AGENTS.md:0 README.md:0 ]`、`files=115`、`total=115`、`rc!=0: none`。
`|| r=$?` で rc を先に捕まえてから `printf` する（`bash "$f"; printf ... "$?"` は `set -e` 下で失敗テストの `printf` に到達せず、失敗を無言で落とす）。baseline は同じ手順で **116/116 rc=0** を実測済み。

### V-6: sweep

```bash
set -uo pipefail
cd "$(git rev-parse --show-toplevel)"
TREE_RE='^[[:space:]│]*[├└]──[[:space:]]+(agents|skills)/.*[0-9]'
HEAD_RE='^###[[:space:]]+(Development Workflow|Security|Language Quality|Meta)[[:space:]]+\([[:space:]]*[0-9]+[[:space:]]*\)[[:space:]]*$'
if grep -qE "$TREE_RE" AGENTS.md README.md; then echo "NG: tree count remains"; else echo "ok: tree 0"; fi
if grep -qE "$HEAD_RE" README.md; then echo "NG: heading count remains"; else echo "ok: heading 0"; fi
```
期待: `ok: tree 0` と `ok: heading 0`。
`grep -c` を判定に使わない — 0 件でも stdout に `0` を出しつつ rc=1 を返すため、`set -e` 下では成功が失敗扱いになる。`if grep -q` 形にする。

**repo 全体の sweep は達成不能なので行わない**: `CHANGELOG.md` / `docs/cycles/` / `docs/STATUS.md` の Completed 行 / `ROADMAP.md:10` / `tests/test-skill-map.sh:59`（negative 契約の literal 自身）が履歴記述として `28 skills` 等を保持する。Cycle 1 で Codex が `grep -rn 'Test Scripts'` を「達成不能」として BLOCK した判断と同型。

Evidence: (orchestrate が自動記入)

## Progress Log

### 2026-09-08 17:15 - KICKOFF
- Cycle doc created (sync-plan agent, plan file: /Users/morodomi/.claude/plans/twinkling-petting-kitten.md)
- Scope definition ready
- Phase completed

### 2026-09-08 17:15 - Plan Review (pre-approval)
- codex_session_id: 01a07e86-41cc-7391-84b6-1e5e662db190
- verdict: WARN（attempt 4、2026-09-08 15:41。P1 なし / 残 P2×3 は反映済み）
- reviewed_plan_hash: 421152ef0c0053472a3235a0784402bfacbea67856405dfcf17857d12710dfd1
- findings 要約:
  - **Claude design-reviewer（important×3 / optional×1、全件実測で裏付け取得後に反映）**: (1) TC-33d/e は既存 `assert_zero_hits` では表現できず、裸の `count_hits` 代入は meta fixture（`AGENTS.md` 不在）で abort する → `assert_min_hits` / `assert_exact_hits` を fail-closed で新設と明記。(2) `test-cycle-retrospective.sh` の header 更新先を `TC-01 to TC-14` としていたが、TC-14 は Cycle 1 で既に削除済みで存在しない → `TC-01 to TC-13（欠番 14, 15）` へ。(3) `19 security agents` の「drift 実績なし」が誤り → `docs/cycles/archive/20260309_1751` の RED ログ `TC-B2 (19 vs 18)` を根拠に「契約導入時点で既に誤っていた」へ訂正（主張を弱めるのではなく強める訂正）。(4) 「6 TC（5 ファイル）」の内訳が曖昧 → 直接 4 ファイル + 二次 1 ファイルへ
  - **Codex attempt 1 (BLOCK, P1×3 / P2×4)**: (1) Verification #7 が達成不能 — `## Verification` は orchestrate Block 2c.5 で REVIEW 前に走るため pre-commit-gate は必ず rc=1 → VERIFY 時点は「rc=1 で BLOCK」、COMMIT 直前に rc=0 の二段階へ。(2) TC-33a/b の regex に検出漏れと過剰検出の両方 — `19 security agents` 単独は 0 件（漏れ）、`Run 2 agents in parallel` は 1 件（過剰）。PdM の oracle は変異 probe を一体で戻していたため前半の一致で穴が隠れていた → ツリー行限定 regex へ再設計し、分解 probe で再実測。(3) TC-33c/f も同型 — `### Security ( 5 )` を見逃し `### HTTP status (404)` を誤検出。TC-33f の「合計 4 件」は重複+欠落で相殺され通る（fixture で再現） → 4 見出し名限定 + 見出しごと exact-1 へ。(4) TC-33d/e の abort-safe helper 未指定（design-reviewer と重複）。(5) Files 見出しを「implementation files: 9」とし STATUS.md を lifecycle artifact として明記。(6) 「ABORT consumer 6 件の回復」は誤り — 6 件目は削除されるため回復対象は 5 件。(7) Verification が再現可能コマンドになっていない（rc 全件集計 / `trap` 復元 / TC 最大値の数値抽出）
  - **Socrates（Codex attempt 2 の代行、verdict WARN）**: Codex の P1×3 は「実測で 3 件とも解消、反証なし」と確認。新規に 5 件。(1) `[└├]` の `LC_ALL=C` fail-open 仮説 → PdM 実測で反証（BSD grep は 2 件を正しく検出）。ただし対案の否定 ASCII クラスは nest 形 `│   ├── skills/` を捕捉するという別の理由で正しく、採用。(2) `(agents|skills)/` 限定が `├── tests/  # 116 test scripts` を素通りさせる（実測 0 件）→ ディレクトリ限定を外し、置換後の実ツリー行 10 本で 0 件を再実測して採用。(3) README 見出しの scope 疑義 → ユーザ裁定（現行維持）。(4) 「配布物として矛盾が固定化する」の機序が不成立 → onboard はテンプレート生成で dev-crew 自身の AGENTS.md をコピーしない（`reference.md:359`）。緊急性の主張を撤回し、dogfood 論拠の射程が AGENTS.md 2 行に限定されることも明記。(5) RED の部分実行を検出する手段がない → RED 完了条件に削除識別子の 0 件 sweep を追加。加えて内部矛盾 3 件（新規 TC「5 件」→ 6 件 / GEN-STAMP の `grep -c` 無ガード / 旧 regex の残存）を修正
  - **Codex attempt 2 (BLOCK, P1×3 / P2×3、hash `e02f883a…`)**: (1) `TC33_TREE_RE` round 2 がツリー行限定になっていない — `├── docs/  # See RFC 2119` / `├── docs/v2/` / `├── python3/` / ツリー行でない `2026 ── release 2` を誤検出し、`── ` の空白 1 個固定のため `├──  tests/`（2 個）と TAB 変種を見逃す（PdM 全件実測で再現）→ round 3 で「ツリー枝の構造 + コメント内のカウント表現」の両方を要求する形へ。(2) `TC33_HEAD_RE` round 2 が `### Security for PHP 8` / `### Development Workflow v2` / `### Meta for 2026` / `### Language Quality: Python 3` を誤検出（実測で再現）→ Codex 提案の「括弧付きカウント suffix を行末まで固定」を採用。round 2 で「意図的に許容」と書いた過剰検出は事後正当化だったため撤回。(3) Verification が自動実行不能 — `skills/orchestrate/reference.md` の実装は `## Verification` 内の bash コードブロックのみを抽出実行するが、大半が inline code だった。加えて `$SCRATCH` 未定義、snapshot 作成コマンド欠落、`bash "$f"; printf "$?"` が `set -e` 下で失敗テストの記録に到達しない → V-1〜V-6 の 6 ブロックへ全面書き直し（各ブロック自己完結、`|| r=$?` で rc 先取り）。(4) plan L130 の「6 件の consumer は自動回復」が stale（6 件目は削除される）。(5) TREE oracle の実ファイル行数が誤り（10 本と記載、実際は AGENTS.md 7 + README.md 8 = 15 本）→ 15 本を 1 行ずつ判定した表を掲載。(6) Verification の表ヘッダ二重。加えて RED sweep の `grep -c` が `set -e` 下で abort する点も修正
  - **Codex attempt 3 (BLOCK, P1×2 / P2×3、hash `9d7d171d…`)**: HEAD regex・15 行 oracle・consumer 数・表ヘッダ・相殺設計は「解消」と明言された。未解消は次の 2 件。(1) TREE regex の「カウント名詞クラス」は網羅不能 — `# 40 definitions` / `# 12 ADRs` / `# 3 plugins` / `# 40 AGENTS` / `# 40+ agents` / `# 19 security-focused agents` を見逃し（PdM 実測で 7 件すべて 0）、`# RFC 2119 rules` / `# PHP 8 agent compatibility` / `# 2 docker images`（`docker` が `[Dd]oc` に一致）/ `- Example: ├── agents/ # 2 agents` を誤検出（実測 6 件すべて 1）→ round 4 で一般化を放棄し `agents/` `skills/` のツリー行限定 + 数字一律拒否へ。(2) V-3 が実行不能 — ブロック内コメントに強制フラグ付き再帰削除の綴りを書いており bash-safety hook に文字列一致でブロックされる、`grep -c 'FAIL TC-33a'` が ANSI reset のため 0 件になる（`fail()` は `printf "  \033[31mFAIL\033[0m %s\n"`）、相殺 probe は TC-33f が 2 件 FAIL するのに期待値 1 と書いていた → 3 点とも修正し、Verification の全 bash ブロックを `bash -n` と禁止綴り検査で確認（ブロック内 0 件。plan の散文には制約を説明するための言及が残るが、実行対象ではない）。(3) P2: RED sweep が fail-open（grep rc>=2 を ok 扱い、`echo` 終端で rc=0）→ rc 分離 + `[ "$red_sweep_ok" -eq 1 ]` 終端へ。(4) P2: V-5 が snapshot を残す → cleanup trap 追加（結果ファイルは snapshot 外へ）。(5) P2: 節名 `round 2` と旧 Verification 番号 → 修正
  - **Codex attempt 4 (WARN, P1 なし / P2×3、hash `79450202…`)**: round 4 の scope 変更と V-3 の 3 修正は「実測上成立」、attempt 3 の P1×2 は「解消」と明言された。残 P2 は 3 件で全て修正済み。(1) RED sweep が依然 `set -e` で中断 — `grep -qE ...; rc=$?` は grep が rc=1（＝削除完了後の正常状態）を返した瞬間に abort し `rc=$?` に到達しない。`rules/test-patterns.md` が明文で禁じる「`$(cmd) ... $?` 並置」の同族を、その rule を持つ repo の plan で踏んでいた → `rc=0; grep ... || rc=$?` へ。両側 oracle で実測（新形は `reached` に到達し rc=1/rc=2 を分離、`red_sweep_ok=0` で block rc=1。旧形は `reached` を出さず abort）。(2) V-5 の `$RESULT` 一時ファイルが残る → trap へ追加。(3)「plan 全体で禁止綴り 0 件」は事実と異なる（Plan Review Record に 1 件残存）→ 綴りを除去し、主張を「Verification の bash ブロック内で 0 件」へ限定
- review_attempts:
  - {started: 09:58, completed: 10:12, verdict: BLOCK}
  - {started: 14:44, completed: 14:52, verdict: BLOCK}
  - {started: 15:05, completed: 15:14, verdict: BLOCK}
  - {started: 15:32, completed: 15:41, verdict: WARN}
- review_notes: Codex は上記 4 回。加えて (a) 10:20 の再開試行は usage limit（`try again at 2:38 PM`）で中断し review に至らず、one-shot cron で 14:43 に再実行した。(b) その待ち時間に Socrates を attempt 2 の代行 adversarial reviewer として起動し 10:41 に WARN を得た（代行であり Codex attempt ではないため `review_attempts` には含めない）。(c) Claude design-reviewer を 1 回実施（important×3 / optional×1）。各 findings の内容は `findings 要約` を参照
- plan_presented: 2026-09-08 17:04
- unresolved_blocks: なし（attempt 4 で BLOCK は解消し verdict は WARN。残 P2×3 は本文へ反映済みで、うち最重要である RED sweep の `set -e` 中断は両側 oracle で実測確認した。attempt 5 は実施していない — 残件が P2 かつ修正が実行による検証を経ているため）
- 注記（レビュー回数について）: spec Step 8 は「最終版を 1 回だけ再レビュー」と規定するが、attempt 1/2/3 がいずれも BLOCK だったためユーザ裁定（AskUserQuestion ×2）により attempt 3・4 を実施した。理由は 3 回とも「検査コマンドが達成不能」「契約が意味を検査していない」という実害のある指摘であり、かつ PdM の修正が毎回新しい欠陥を生んでいたため。attempt 4 で P1 が消え、指摘が P2 のみになったことをもって収束と判断した
- round 4 の設計転換について: attempt 1〜3 の regex はいずれも「ツリー行一般の派生数値」を捉えようとして失敗した。round 4 は #210 の目的を「削除した事実が、削除した場所へ戻ることの検出」に限定し、`agents/` `skills/` の 2 行だけを対象にする。代償として `├── tests/  # 116 test scripts` を検出しない（Socrates が最も churn が高いと指摘した行）。これは意図的な受容であり、より広い契約が必要なら #211 と併せて別途設計する
- override: 不要（unresolved BLOCK なし）
- 注記（Record 書式の事後修正、2026-09-08 17:04）: 最初の承認後、sync-plan が hash 不一致で BLOCK した。実測の結果、本 Record が 4 つの決定論チェックに落ちていたことが判明した: (1) `reviewed_plan_hash` に whole-file の `shasum -a 256 $PLAN` を記録していた。gate（`scripts/gates/pre-red-gate.sh` L281）と sync-plan が使う正準アルゴリズムは `awk '$0=="## Plan Review Record"{exit}{print}' | shasum -a 256`（Record 行より前の本文のみ）。4 attempt すべて同じ誤りで、編集の有無に関わらず一致し得ない値だった。(2) `review_attempts` が `- {reviewer: ..., started: ...}` の形で `started` が先頭キーでなく、gate の `grep -c '^  - {started:'` が 0 件になっていた。`skills/spec/reference.md` は「この書式は pre-red-gate.sh の grep 契約であり書式の自由度を持たない」と明記している。(3) `verdict` を markdown 太字 `**WARN**` で書いており、gate の enum `^- verdict: (PASS|WARN|BLOCK-overridden|BLOCK)` に不一致。(4) `plan_presented` に HH:MM がない。修正は Record 内のみに限定した。`## Plan Review Record` より前の本文は 1 バイトも変更していない（正準 hash は `421152ef…` のまま不変）。`state-ownership.md` の「承認後 IMMUTABLE」との緊張はユーザ裁定（AskUserQuestion 2026-09-08）により plan mode へ戻して修正 → 再承認という経路で処理した。`reviewed_plan_hash` が検証しているのはレビュー来歴ではなく「承認時点から本文が不変であること」である（gate は記録値を信用せず plan_file から再算出する）。フィールド名が誤解を誘うため、改名は DISCOVERED 候補。この 4 件はいずれも「SKILL.md の要約だけ読んで reference.md を読まない」という単一の根本原因の帰結であり、Verification の inline code 問題・bash-safety の禁止綴り問題と合わせて同一原因の 5 例目まで数えられる。恒久対策として承認前の決定論 lint（`scripts/gates/plan-lint.sh`）を issue #216 に起票した。#217（Step 8 findings triage + regex を RED へ移す）、#218（再混入契約の設計規則）も併せて起票済み
- Phase completed

### 2026-09-08 17:15 - sync-plan hash 一次照合（sync-plan agent）
- 正準アルゴリズム（`awk '$0=="## Plan Review Record"{exit}{print}' <plan_file> | shasum -a 256`）で plan ファイルの実 hash を再計算した
- 実測値: `421152ef0c0053472a3235a0784402bfacbea67856405dfcf17857d12710dfd1`
- Record 記載値: `421152ef0c0053472a3235a0784402bfacbea67856405dfcf17857d12710dfd1`
- **一致（MATCH）**。前回の中断理由（whole-file hash の誤記録）は解消済みであることを sync-plan 自身の実行結果として確認した
- Phase completed

---

### 2026-09-08 17:29 - Design Review Gate / Post-Transfer Verification

- architect 判定: **WARN**（転記欠落による BLOCK なし / scope 実質変更なし）
- 独立検証: architect が `bash scripts/gates/pre-red-gate.sh <cycle doc>` を再実行し PASS rc=0、正準 hash を独立再計算して MATCH を確認（PdM の宣言を信用しない手順を実施）
- 実ファイル突合: AGENTS.md:65-71 / README.md:92-114 / test-doc-consistency.sh L24・L26-34 / test-cycle-retrospective.sh L236-251 / test-agents-md-propagation.sh L32-44 / test-review-integration-v24.sh L164-169 / test-skills-structure.sh TC-B1/B2 / test-agents-md-count.sh の存在 — すべて plan の Baseline 実測記述と一致
- scope: implementation files 9、Files to Change 10 項目とも plan と完全一致。独自の追加・削除なし。lifecycle artifact の区別も一致
- 内部整合: RED→GREEN の順序、TC-33a〜f の RED 期待挙動表（33d/33e は PASS）、V-3 の変異注入 probe が 6 TC を全カバーすることを確認
- 数値 drift 再発チェック: `9` / `115` / `116` / `6 つの TC` / `4 ファイル` / `TC-01 to TC-13` / round 4 の regex 2 本を grep 走査し stale な旧記述なし
- **WARN の内容**: plan の `## Baseline`（101 行）が Cycle doc に転記されていない。原因は `agents/sync-plan.md` Step 2 の転記表に Baseline スロットが存在しないこと。**sync-plan の再実行では修復されない**（同一出力を再生産するのみ）ため、PdM が Cycle doc へ独立セクションとして追記した（本エントリの直後、doc-mutations.md の APPEND-ONLY 準拠）
- DISCOVERED 候補 3 件を記録（TC-11 削除理由の 3 根拠 / TC 採番コマンド / TC-01 header 更新先の注記が Cycle doc 本文で省略）
- Phase completed

### 2026-09-08 18:04 - RED

- 実装済み（red-worker 委譲、コード作業完了・検証済み。本エントリは記録のみ）:
  - 削除: `tests/test-skills-structure.sh` TC-B1 + TC-B2 / `tests/test-agents-md-count.sh`（`git rm`）/ `tests/test-doc-consistency.sh` TC-01（L24 の `ACTUAL_COUNT=` は保持）/ `tests/test-cycle-retrospective.sh` TC-15 / `tests/test-agents-md-propagation.sh` TC-14 / `tests/test-review-integration-v24.sh` TC-11
  - 追加: `tests/test-doc-consistency.sh` に helper `assert_min_hits()` L461 / `assert_exact_hits()` L480（rc=1/rc=2 を分離し fail-closed）+ TC-33a〜f
- 実測（PdM が直列実行して取得。マシン負荷回避のため red-worker による再実行はしていない）:
```
GEN-STAMP: TCB1=0 TC33=26 files=115

RED 完了条件 sweep:
  ok: tests/test-skills-structure.sh
  ok: tests/test-doc-consistency.sh
  ok: tests/test-cycle-retrospective.sh
  ok: tests/test-agents-md-propagation.sh
  ok: tests/test-review-integration-v24.sh
  ok: removed (test-agents-md-count.sh)
  RED_SWEEP_OK=1

bash tests/test-skills-structure.sh
  rc=0 summary=1
  PASS: 5 / FAIL: 0 / TOTAL: 5
  → TC-B1 削除前は L110 で abort し Summary に到達しなかった。abort 解消を確認

bash tests/test-doc-consistency.sh
  rc=1 summary=1
  PASS: 35 / FAIL: 7 / TOTAL: 42
  TC-33a  PASS=0 FAIL=1
  TC-33b  PASS=0 FAIL=1
  TC-33c  PASS=0 FAIL=1
  TC-33d  PASS=2 FAIL=0
  TC-33e  PASS=2 FAIL=0
  TC-33f  PASS=0 FAIL=4
  → FAIL 合計 7 = 33a(1) + 33b(1) + 33c(1) + 33f(4)。期待外の失敗 0 件
  → 33d/33e が PASS ×2 なのは agents/ と skills/ の 2 チェックを持つため（RED 期待表どおり）
  → 33f が FAIL ×4 なのは 4 見出しを個別に exact-1 検査するため（合計方式の相殺を避ける設計）
  → Summary に到達しており ACTUAL_COUNT 保持による abort 回避を確認

bash tests/test-meta-doc-consistency.sh
  rc=0
  PASS: 4 / FAIL: 0 / TOTAL: 4
  'aborted before reaching Summary' の報告: 0 件
  → abort 増幅器が発火していないことを確認

test 数: 116 → 115（test-agents-md-count.sh 削除）
```
- Test List: TC-33a〜f を TODO から WIP へ遷移（詳細は `## Test List` WIP セクション参照）。TC-33d/TC-33e は overshoot 防止の positive 契約で RED 時点で既に PASS しており、FAIL→PASS の RED→GREEN 遷移を持たない
- red_state_verified: true（TC-33a/b/c/f は FAIL、TC-33d/e は設計どおり PASS。期待外の結果なし）
- Phase completed

### 2026-09-08 18:11 - GREEN

- 実装済み（green-worker 委譲、コード作業完了・検証済み）:
  - `AGENTS.md` L65/66 を `├── agents/          # Agent definitions (flat), security agents included` / `├── skills/          # Skills (each: SKILL.md + reference.md)` へ置換（L71 の `decisions (ADR)` は未変更）
  - `README.md` L93/94 を `├── agents/                      # Agents (flat)` / `├── skills/                      # Skills (flat)` へ置換（`docs/architecture.md:76,82` の先例に逐語で一致）
  - `README.md` L104/107/110/113 の見出しから件数表記を除去: `### Development Workflow` / `### Security` / `### Language Quality` / `### Meta`（見出し配下のスキル名リストは維持）
  - `CHANGELOG.md` `[Unreleased]` に Removed（削除した TC 識別子の列挙）/ Changed（README 見出し変更 + TC-33 helper 追加の説明）を追記。削除した数値そのものは記載していない
- 実測（PdM が直列実行、並行実行なし）:
```
bash tests/test-doc-consistency.sh
  rc=0
  PASS: 42 / FAIL: 0 / TOTAL: 42
  TC-33a PASS / TC-33b PASS / TC-33c PASS / TC-33d PASS(x2) / TC-33e PASS(x2) / TC-33f PASS(x4)

bash tests/test-doc-alignment.sh
  rc=0
  PASS: 9 / FAIL: 0 / TOTAL: 9

bash tests/test-skill-map.sh
  rc=0
  PASS: 7 / FAIL: 0 / TOTAL: 7

bash tests/test-decision-records.sh
  rc=0
  PASS: 12 / FAIL: 0 / TOTAL: 12
  TC-12: AGENTS.md Project Structure mentions decisions (ADR) → L71 の literal を破壊していないことを確認
```
- Test List: TC-33a〜f を WIP から DONE へ遷移（`## Test List` DONE セクション参照）。TC-33d/33e は RED 時点で既に PASS していた overshoot 防止契約であり、本エントリで「GREEN 後も PASS 維持」を実測確認した
- 4 テストとも直列実行（並行実行はしていない。RED 時点で実測された load average 悪化の再発を避けるため）
- Phase completed

### 2026-09-08 18:15 - REFACTOR

- **判定: no-op（コード変更なし）**。チェックリスト 7 項目を今 cycle の変更ファイルへ適用し、いずれも改善不要と確認した
- **1 重複コード**: TC-33a〜f は 6 件すべて helper 経由（`assert_zero_hits` ×3 / `assert_min_hits` ×4 / `assert_exact_hits` ×4）。インライン実装の残存なし。前 cycle Insight 4「helper へ集約したら呼び出し元を grep で数えてから完了とする」を満たす
- **2 定数化**: `TC33_TREE_RE` / `TC33_HEAD_RE` を `tests/test-doc-consistency.sh:751-752` で 1 度だけ定義し、それぞれ 9 回 / 6 回参照。regex の重複記述なし
- **3 未使用定義**: `tests/test-review-integration-v24.sh` の `code_tasks` / `plan_tasks` / `socrates_tasks` / `step2_tasks` が孤立に見えたが**誤検知**。算術式 `$((code_tasks + step2_tasks + socrates_tasks))` 内では `$` なしで参照されるため、`\$var` 形の grep では拾えない。TC-11 削除で孤立した定義は 0 件（Cycle 1 の `$ACTUAL_TESTS` と同型の地雷は発生していない）
- **4〜6 let→const / メソッド分割 / N+1**: bash のため非該当。新規 helper 2 本はいずれも単一責務・20 行未満で分割不要
- **7 命名一貫性**: `assert_zero_hits` / `assert_min_hits` / `assert_exact_hits` の一貫した族。既存 helper の命名規則を踏襲
- **付随確認**: 変更した 5 test file すべて `bash -n` rc=0。`tests/test-doc-consistency.sh` の header 欠番リスト（01, 03, 06-10, 26, 27）が実装の TC 番号集合と整合（`01` は header 行自身にのみ出現し実 TC としては不在）。`CHANGELOG.md` の追記は識別子のみで派生数値の混入なし（`[0-9]+ (agents|skills)` 実測 0 件）
- **テスト再実行は行っていない**: REFACTOR がコードを変更していないため、GREEN で実測した rc=0（doc-consistency 42/42、doc-alignment 9/9、skill-map 7/7、decision-records 12/12）がそのまま有効。全 suite は VERIFY の V-5 で実行する
- Phase completed

### 2026-09-08 19:14 - VERIFY (Product Verification)

V-1〜V-6 を**直列で**実行した（並行起動は本 cycle 内で load average 14 まで上げ両方を遅延させた実測がある。recall: cycle 20260702_1200 #2「読み取り並列・実行直列」）。以下はすべて実行出力の貼付であり宣言ではない。

**V-1: abort 解消と rc-consumer の回復** — PASS
```
GEN-STAMP: TCB1=0 files=115
test-skills-structure rc=0 summary=1
test-cross-references rc=0 / test-stale-references rc=0 / test-precompact rc=0
test-orchestrate-compact rc=0 / test-no-auto-transitions rc=0
ok: test-agents-md-count.sh removed
```
TC-B1 削除前は L110 の無ガード grep が `set -euo pipefail` 下で abort し Summary に到達しなかった。5 consumer すべてが rc=0 へ回復し、Baseline で予測した ABORT 波及が解消したことを確認。

**V-2: 削除の地雷（共有変数・abort 増幅器）** — PASS
```
test-doc-consistency rc=0 / test-meta-doc-consistency rc=0 / test-cycle-retrospective rc=0
test-agents-md-propagation rc=0 / test-review-integration-v24 rc=0
'does not hardcode skill count' = 1   （ACTUAL_COUNT 保持、TC-02 の vacuous PASS 経路）
'aborted before reaching Summary' = 0 （meta test の abort 増幅器が発火していない）
PASS: 42 / FAIL: 0 / TOTAL: 42
```

**V-3: 変異注入 oracle（最小単位で 1 つずつ、12 probe）** — PASS 12/12 + 復元 ok
```
AGENTS: 40 agents だけ戻す              TC-33a got=1 ok
AGENTS: 19 security agents だけ戻す     TC-33a got=1 ok
AGENTS: 28 skills を戻す                TC-33a got=1 ok
README: 40 agents を戻す                TC-33b got=1 ok
README: 28 skills を戻す                TC-33b got=1 ok
README: ### Security (5) へ戻す         TC-33c got=1 ok
README: 空白変種 ( 5 )                  TC-33c got=1 ok
AGENTS: agents ツリー行を削除            TC-33d got=1 ok
README: skills ツリー行を削除            TC-33e got=1 ok
README: ### Security 見出しを削除        TC-33f got=1 ok
README: DW 重複 + Security 欠落          TC-33f got=2 ok
AGENTS.md を不在にする                   TC-33a got=1 ok
restored: ok
```
要点 3 件: (1) `19 security agents` 単独の検出は round 1 regex が見逃した形で、probe を最小単位へ分解して初めて測れた。(2) 括弧内空白変種 `( 5 )` は round 2 が見逃した形。(3) DW 重複 + Security 欠落で TC-33f が **2 件** FAIL するのは、合計方式なら相殺して偽 PASS する形を個別 exact-1 検査が捕まえた証拠。最後の probe はファイル不在時に **vacuous PASS ではなく fail()** が出ることの確認で、helper の rc=1 経路が fail-closed であることを示す。

**V-4: pre-commit-gate（二段階の第 1 段）** — PASS（期待どおり BLOCK）
```
gate rc=1
BLOCK: REVIEW not completed in Progress Log. Run review before commit.
```
`## Verification` は orchestrate Block 2c.5 で REVIEW より前に走るため rc=0 は構造的にありえない。ここで rc=0 が返る方が異常（gate が REVIEW 完了を検査していないことになる）。**第 2 段の rc=0 確認は COMMIT 直前に行う。**

**V-5: full suite（親構造込み隔離 snapshot）** — PASS
```
GEN-STAMP: tree_hits=[README.md:0 AGENTS.md:0 ] files=115
total=115
rc!=0: none
```
baseline は同一手順で 116/116 rc=0。`test-agents-md-count.sh` 削除により 115 へ減り、**pre-existing FAIL が 0 件だったため 1 件の FAIL も本 cycle 起因と断定できる状態で 115/115 を達成**。世代スタンプが編集後のツリーを測ったことを出力自身で示している。

**V-6: sweep** — PASS
```
ok: tree 0
ok: heading 0
```

- real-path invocation: V-4 で `scripts/gates/pre-commit-gate.sh` を実 cycle doc に対して実行済み（rules/integration-verification.md の要求を満たす）
- Phase completed

### 2026-09-08 19:46 - REVIEW

competitive review（risk-classifier 決定論判定 **MEDIUM score:55** → MED tier）。Codex + correctness-reviewer + test-reviewer の 3 者を起動した。security-reviewer の代わりに test-reviewer を当てたのは、本 cycle が外部入力・認証を扱わない削除主体の変更であり、**新設した契約自身が「動かない番犬」でないか**が最大のリスクだったため。

**verdict は宣言せず `skills/review/severity-verdict.sh` を実行して得た**（前 cycle Insight 1「決定論ゲートの判定を PdM が宣言で上書きしてはならない」の適用）:

```
WARN critical:0 important:2 optional:3 invalid:0
```

#### findings triage（rules/review-triage.md の 3 分岐）

| id | severity | category | 内容 |
|---|---|---|---|
| B | important | accept-apply | **TC-33d/e の overshoot ガードが vacuous だった**。`-cF` の全文部分一致のため、ツリー行を削除して同一文字列をコメント等へ移すと PASS する。Codex 再現手順で実測（`-cF=1` で通過、`TC33_TREE_RE` も 0 のため TC-33b も通過）。**Codex P2-2 / correctness optional-2 / test-reviewer optional-2 の 3 者が独立に同じ 1 行へ収束** |
| E | important | accept-apply | `TC33_TREE_RE` の widening 側（`agents/` `skills/` 行の任意の数字を一律拒否）がコード内コメントに未記載。将来の正当な追記（`see ADR-12` / `OWASP Top 10` 等）が理由不明の FAIL を生む（実測: 3/4 の probe が拒否される）。加えて assert の label が変数名そのもので FAIL 時に原因を説明しない |
| A | optional | accept-apply | `tests/test-agents-md-propagation.sh` の `SKILLS_STRUCTURE_TEST` は削除済み TC-14 専用の孤立依存。不在時に `fail()` を経由せず `exit 1` で Summary 未到達の hard-exit になる |
| D | optional | accept-apply | `tests/test-doc-consistency.sh` header の範囲上限 `TC-33` は plain TC-33 が実装に 0 件のため `TC-32` が正しい |
| C | optional | **accept-defer** | TC-33f が `## Skills` 配下に限定されておらず、見出しを別 section へ移しても PASS する。`section_grep` の導入が必要なため DISCOVERED（別 cycle） |
| F | optional | **reject** | helper 3 本の rc ハンドリング三重化の統合。比較演算子を引数化すると各 helper の意図が読み取りにくくなり、3 関数とも 20 行未満で重複量が小さい。可読性とのトレードオフで現状維持が妥当 |

#### 適用した修正の両側 oracle（実測）

**B（アンカー化）**: `-cF "├── agents/"` → `-cE '^[[:space:]│]*[├└]──[[:space:]]+agents/'`（skills/ も同様、計 4 assert）
```
Codex 反例（行削除 + コメントへ移動）: 修正前 -cF=1（通過） → 修正後 0（正しく FAIL）
実ファイル: AGENTS agents=1 skills=1 / README agents=1 skills=1
書式変種: `└── agents/`=1, `│   ├── skills/`=1, `├──  agents/`（空白2）=1  ← negative/positive の非対称を解消
誤検出: `├── tests/`=0, `├── scripts/hooks/`=0, `see ├── agents/ in the tree`=0, `# ├── agents/ example`=0
```

**A/D/E**: `COMMIT_SKILL` のみ要求する形へ縮小 / header を `TC-01 ~ TC-32` へ / widening 注記を追加し label を `AGENTS.md agents/skills ツリー行コメント中の数字` 等の人間可読文言へ

#### 修正後の再検証（修正が新しい欠陥を生んでいないことの確認）

3 ラウンド連続で「修正が新しい欠陥を生む」を踏んだ cycle のため、修正後に必ず再実測した。
```
GEN-STAMP: tree_hits=[AGENTS.md:0 README.md:0 ] anchored_asserts=4 files=115
test-doc-consistency        rc=0  PASS: 42 / FAIL: 0
test-agents-md-propagation  rc=0  PASS: 1  / FAIL: 0
test-meta-doc-consistency   rc=0  PASS: 4  / FAIL: 0
test-doc-alignment          rc=0  PASS: 9  / FAIL: 0
test-decision-records       rc=0  PASS: 12 / FAIL: 0
TC-33a=PASS1 33b=PASS1 33c=PASS1 33d=PASS2 33e=PASS2 33f=PASS4（FAIL いずれも 0）
full suite（親構造込み隔離 snapshot）: total=115 / rc!=0: none
```

#### 自己観察（Retrospective 候補）

**B は私の V-3 変異注入 oracle が見逃していた穴である。** plan には「TC-33a/b は行が消えれば 0 件で vacuous PASS になるため、d/e と対で初めて意味を持つ」と書いていたのに、**その d/e 自身が vacuous だった**。V-3 の 12 probe は「行を削除する」形しか持たず、「削除して同じ文字列を別の場所へ移す」を測っていなかった。oracle が穴を持つと、その穴の中では契約が壊れていても緑になる。regex を 4 ラウンド作り直した本 cycle の構造が、検証側にもそのまま現れた。

- Phase completed

### 2026-09-08 19:48 - DISCOVERED

本 cycle で検出した scope 外項目の起票結果。**すべて「散文で定めた契約に、実行時の検査がない」という同一の形**に収束している。

| issue | 内容 | 検出経路 |
|---|---|---|
| #216 | `scripts/gates/plan-lint.sh` — 承認前の決定論 lint。正準 hash の算出・書込、Verification の bash ブロック抽出 + `bash -n` + 禁止綴り走査、Record 書式を pre-red-gate と同じ grep で検査、attempt 上限 | plan review 5 ラウンドの分析。Codex の P1 がほぼ全て lint 級だった |
| #217 | Step 8 に findings triage（accept-apply/defer/reject）+ regex 実装を plan から RED へ移す | 同上。plan が 606 行へ膨張した機序 |
| #218 | 再混入防止契約の設計規則を rules へ 1 行で条項化（削除 literal を削除位置に pin、一般化は別 cycle） | regex 4 ラウンド作り直しの反省 |
| #219 | sync-plan の転記契約に `## Baseline` スロットがなく、実測した地雷情報が worker に届かない | architect の Post-Transfer Verification（WARN） |
| #220 | TC-33f を README の `## Skills` 配下へ限定する（見出しを別 section へ移すと素通り） | Codex code review P2-3（本 cycle REVIEW の finding C、accept-defer） |
| #221 | worker のフェーズ完了マーカー欠落が phase 出口で検出されず COMMIT まで気づかない | 本 cycle の RED で実際に発生 |

**既存 issue に紐づけたもの**（新規起票せず）:
- #220 は #212（`test-doc-consistency.sh` の section 抽出重複解消）と同一ファイル・同一機構のため、まとめて実施するのが妥当と本文に明記した
- #211（契約テストの COMMIT 経路への配線）は plan の Out of Scope に記載のとおり、本 cycle 完了により対象が確定した（TC-23/24/28 + TC-29〜32f + TC-33a〜f）

**reject した finding**（REVIEW の F）: helper 3 本の rc ハンドリング三重化の統合。比較演算子を引数化すると各 helper の意図が読み取りにくくなり、3 関数とも 20 行未満で重複量が小さい。起票しない。

**plan の Out of Scope から未起票のまま残る項目**（本 cycle では対象外と裁定済み、必要になった時点で起票）:
- `tests/test-agents-structure.sh` の pass メッセージ内の陳腐化数値（L116 `All 32 agents` は実数 40 で既に誤り。assertion ではなく表示文字列）
- `tests/test-skill-map.sh` T-06 / `tests/test-doc-alignment.sh` T-07 の stale literal `34 agents|28 skills`（`40 agents` の再混入を検出できない）
- `ROADMAP.md` の「現在地」が v2.12.0 のまま（実際は v2.17.0 リリース済み） — #177 が同主題
- `tests/test-agents-structure.sh:513` TC-41 の 40 名ハードコード roster の実ファイル導出化
- `scripts/gates/pre-commit-gate.sh:85` の check #2（Codex review 記録）が Plan Review Record 転記により恒久 vacuous PASS になる（Socrates 指摘）

- Phase completed

## Next Steps

1. [Done] KICKOFF
2. [Done] RED
3. [Done] GREEN
4. [Done] REFACTOR
4.5 [Done] VERIFY
5. [Done] REVIEW
6. [Done] COMMIT <- Current
7. [Done] DONE

---

## Baseline（実測、2026-09-08）

Explore agent の全量調査と、PdM による実ファイル・実行での再確認。**narrative でなく実測**（plan-discipline L12）。

### 削除対象（実測した行番号と文言）

```
AGENTS.md:65:├── agents/          # 40 agents (flat), 19 security agents
AGENTS.md:66:├── skills/          # 28 skills (each: SKILL.md + reference.md)
README.md:93:├── agents/                      # 40 agents
README.md:94:├── skills/                      # 28 skills
README.md:104:### Development Workflow (13)
README.md:107:### Security (5)
README.md:110:### Language Quality (7)
README.md:113:### Meta (3)
```

`AGENTS.md` 全文（84 行）を走査し、上記 2 行以外に派生数値は**存在しない**。`AGENTS.md:18` の `Skills available: spec, red, ...` は**数値を含まない名前集合**であり削除対象外（TC-23 が `skills/*/` と集合比較で pin）。`CLAUDE.md` は Cycle 1 で `Available skills (28 total)` 行を削除済みで clean（TC-25 が恒久 negative 契約）。

### 置換の先例（既に新方針の形になっている実在の記述）

```
docs/architecture.md:76:├── agents/                       # Agents (flat)
docs/architecture.md:82:├── skills/                       # Skills (flat)
```

これは**同じツリー行の、既に変換済みの形**である。本 cycle はこの先例に揃える。

### 逆向き契約（削除必須）— 実測した fragility

| ファイル | TC | 行範囲 | 壊れ方（実測） |
|---|---|---|---|
| `tests/test-skills-structure.sh` | TC-B1 + TC-B2 | L100-144 | **ABORT**。L5 `set -euo pipefail`、L110/L139 の抽出 grep が**無ガード**。実測: 数値を消すと rc=1、`TC-B2` に到達せず `=== Summary ===` も出力されない |
| `tests/test-agents-md-count.sh` | 全体 | 全 50 行 | clean FAIL（2/2）。**ファイル全体が `40` の pin 専用**。名指し参照は自身の header コメント L2 のみ（`grep -rn 'test-agents-md-count'` 実測） |
| `tests/test-doc-consistency.sh` | TC-01 | L26-34 | clean FAIL（L29 に `\|\| true`） |
| `tests/test-cycle-retrospective.sh` | TC-15 | L236-251 | clean FAIL（L5 は `set -uo pipefail` で `-e` なし、L242 に `\|\| true`） |
| `tests/test-agents-md-propagation.sh` | TC-14 | L32-44 | **連鎖破壊**。`sed -n '/TC-B1/,/TC-B2/p'` で TC-B1/B2 のブロックを抽出しており、TC-B1/B2 削除で範囲が空になる。実測: `FAIL TC-14: TC-B1/TC-B2 not targeting AGENTS.md (B1=0, B2=0)` |

**issue #214 の本文はこの `test-agents-md-propagation.sh` TC-14 を挙げていない**。Cycle 1 の `test-codify-insight.sh` TC-20 → `test-cycle-retrospective.sh` TC-14 と**同型の連鎖**であり、`grep -rn -E "awk .*/\^?# ?TC-|sed -n '/TC-" tests/*.sh` の全 repo 走査で、この 2 行（L36/L37）以外に TC ブロック抽出は存在しないことを確認済み。

**ファイル自体は残す**: `test-agents-md-propagation.sh` の存在は `tests/test-doc-consistency.sh:490` TC-22 が `assert_zero_hits` で要求しており、`count_hits` はファイル欠落時に rc=1 を返して `fail "$tc_id: $label not found"` になる。TC-14 のみ削除し TC-08 を残す。

### ABORT の波及範囲（遷移状態でのみ発生、実測）

数値を先に消して TC-B1 を残すと、`test-skills-structure.sh` の abort が rc=1 として以下へ伝播する（すべて rc のみを見る consumer）:

```
tests/test-cross-references.sh:70        TC-05
tests/test-stale-references.sh:104       TC-08
tests/test-precompact.sh:145             TC-14
tests/test-orchestrate-compact.sh:195    TC-14
tests/test-no-auto-transitions.sh:115    TC-04
tests/test-agents-md-count.sh:22-23      TC-01
```

加えて全 suite を回す増幅器 2 件: `tests/test-doc-consistency.sh:721` TC-13、`tests/test-factory-model-adaptation.sh:157` TC-14。

**PdM 実測（隔離 snapshot）**: TC-B1/B2 を実際に削除すると `test-skills-structure.sh` は rc=0 で `PASS: 5 / FAIL: 0` の Summary に到達する。上記 6 件の consumer のうち **5 件は自動回復し、6 件目の `test-agents-md-count.sh` は本 cycle で削除されるため「回復」しない**（存在しなくなる）。**この差が Design A の phase 分割の根拠**。

### 削除の地雷 — 共有変数（Cycle 1 の `$ACTUAL_TESTS` と同型）

```
tests/test-doc-consistency.sh:24:ACTUAL_COUNT=$(find "$BASE_DIR/skills" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
tests/test-doc-consistency.sh:42:elif [ "$arch_count" = "$ACTUAL_COUNT" ]; then
tests/test-doc-consistency.sh:43:  pass "architecture.md skill count ($arch_count) = actual ($ACTUAL_COUNT)"
tests/test-doc-consistency.sh:45:  fail "architecture.md skill count ($arch_count) != actual ($ACTUAL_COUNT)"
```

L24 は TC-01 のコメントブロック直下にあるが **TC-02 が消費している**。L23-34 を一括削除すると TC-02 が未定義変数を参照し `set -euo pipefail`（L5）で abort する。**L26-34 のみ削除し L24 は保持する**。この危険は repo 内に前例コメントとして既に記録されている（`tests/test-v2-release.sh:67-68`）。

さらに増幅器がある: `tests/test-meta-doc-consistency.sh` は `test-doc-consistency.sh` を fixture 上で 3 回実行し、`grep -c "^=== Summary ==="` が 0 なら `fail "... aborted before reaching Summary"` とする（L65-70, L88-93, L112-117）。abort させると meta test 3 TC が連鎖 FAIL する。

### 壊れないことを確認済み（除外根拠つき）

| 対象 | 除外根拠 |
|---|---|
| `tests/test-review-integration-v24.sh:167` | filesystem を数えるのみで AGENTS.md を読まない（後述 B-8 で別理由により削除） |
| `tests/test-skill-map.sh:59` T-06 / `tests/test-doc-alignment.sh:79` T-07 / `tests/test-orchestrate-a2b.sh:197` TC-12 | **他ファイル**（skill-map.md / architecture.md）への negative 契約。本 cycle の編集対象外 |
| `tests/test-decision-records.sh:132` | `AGENTS.md` L71 の `decisions (ADR)` literal を要求。**同じツリー fence 内なので L71 は絶対に触らない** |
| `tests/test-agents-structure.sh:592` TC-44 | `AGENTS.md` L56 の Constraints 表（数値なし） |
| `tests/test-doc-consistency.sh:504` TC-23 | `AGENTS.md` L18 の skill 名集合（数値なし） |
| `tests/test-doc-consistency.sh:58` TC-04 / `:67` TC-05 | README の `skill-maker` / `security-audit` という**名前**を要求。見出し配下のスキル名リストを残せば PASS |
| `tests/test-cycle-retrospective.sh:212` TC-13 / `tests/test-codify-insight.sh:359` TC-18 | 4 doc に skill 名を要求。README L105 / AGENTS.md L18 が満たす |
| `tests/test-hooks-structure.sh:81` | AGENTS.md を fixture へ snapshot するのみ |
| `tests/test-v2-release.sh:73` | README にテスト数がないため L61 の空判定分岐（vacuous pass）へ入る。実測: 当該 grep の出力は空 |
| `run-tests.sh:11` | glob 列挙。`.github/` に CI workflow は存在しない |
| `ROADMAP.md:10` `(33→40 agents)` | **履歴記述**として保持。除外根拠: Cycle 1 が STATUS.md Completed 行の「Test Scripts 115→116」を同じ理由で保持した先例に従う。契約による pin はなし |
| `tests/test-codify-insight.sh` TC-19/TC-20 | **既に存在しない**（Cycle 1 で削除済み。L359 `TC-18` → L385 `TC-21` と番号が飛ぶ）。cycle doc の記述は削除前の状態の記録 |

### 実測ずみのテスト総数

`find tests -maxdepth 1 -name 'test-*.sh' | wc -l` = **116**。`test-agents-md-count.sh` の削除で **115** になる。この総数を pin する契約は `grep -rnE '\b116\b' tests/ scripts/ skills/ rules/ .claude/rules/ README.md AGENTS.md CLAUDE.md docs/*.md` の実測で**存在しない**（ヒットは STATUS.md の Completed 行 2 件＝履歴記述と、`docs/v3-constitution-design.md:104` の無関係な行番号のみ）。

### full suite baseline

親構造ごと複製した隔離 snapshot（`holdings-snap/docs/test_architecture.md` + `agents/dev-crew/`。`tests/test-paradigm-selection.sh:16` が `$BASE_DIR/../../docs/` を読む repo 外依存を持つため）で全 116 本を実行。

**実測結果（2026-09-08）: `total=116 / rc!=0: none` — 116/116 が rc=0。** 世代スタンプ `40agents=AGENTS.md:1 README.md:1 TCB1=4` を実行コマンドに埋め込み、**未編集ツリーを測ったことを出力自身で確認**した（recall: cycle 20260904_1521 Insight 3「バックグラウンド実行の出力は『いつのコードを測ったか』を確認してから読む」。Cycle 1 ではこれを 3 回踏んだため、本 cycle は最初の実行から適用する）。

**pre-existing FAIL は 0 件**。したがって本 cycle 後の full suite は **115/115 rc=0** でなければならず、1 件でも FAIL すれば本 cycle が原因である（plan-discipline L14「pre-existing FAIL の先送り」の判断は不要）。

> **転記の出所**: 上記は plan `## Baseline` 節の逐語転記。`agents/sync-plan.md` Step 2 の転記表に Baseline スロットが無いため sync-plan では転記されず、architect の Post-Transfer Verification（WARN）を受けて PdM が補完した。RED/GREEN の worker が読むのは Cycle doc であり、ここに書かれた地雷（`ACTUAL_COUNT` 共有変数・TC-B1 の abort・TC-14 の連鎖破壊・ABORT 波及 6 consumer）を知らずに作業すると踏む。

### 2026-09-08 19:50 - COMMIT

- 全ゲート PASS: `pre-commit-gate.sh` **rc=0**（VERIFY 時点は rc=1 `BLOCK: REVIEW not completed` で、V-4 の二段階契約が両端とも期待どおり動作した）/ Test List 未完了 0 件 / RED・GREEN・REFACTOR・REVIEW の `Phase completed` 各 1 件 / `retro_status: captured`
- **doc 更新の要否**: `git diff --name-only HEAD | grep -qE '^(skills|agents)/'` が SKIP を返したため README/AGENTS/CLAUDE の一覧更新は不要（本 cycle は README/AGENTS を**編集対象**として触るが、skills/ agents/ ディレクトリ自体は未変更）
- **STATUS.md**: Completed 行を追加。**Current State 表は Cycle 1 で削除済みのため数値同期は発生しない** — 従来必要だった Test Scripts / Skills / Agents の手動更新が構造的に消えている（#210 の成果）
- **commit 同梱**: 承認済み implementation files 9 + 新規 Cycle doc + 前 cycle doc `20260907_1324`（Block 0 codify による `captured` → `resolved` 遷移、scope 同梱として plan に明記済み）
- test 数 116 → **115**（`tests/test-agents-md-count.sh` 削除）。full suite **115/115 rc=0**（親構造込み隔離 snapshot、REVIEW 修正適用後に再実測）
- 追跡ラベル混入の最終確認: `git diff HEAD -- tests/ AGENTS.md README.md` に issue 番号・cycle 番号の追加なし
- Phase completed

## Retrospective

### Insight 1: SKILL.md の要約だけ読んで reference.md を読まない — 単一の原因が独立した 6 件の欠陥として現れた

- **Failure**: plan review を **5 ラウンド**回し約 7 時間を消費した。plan は 606 行へ膨張し、その間 commit は 0 行。attempt 1/2/3 がいずれも BLOCK で、**毎回 PdM の修正が新しい欠陥を生んだ**。極めつけに sync-plan が hash 不一致で BLOCK し、実測すると Plan Review Record が**決定論チェック 4 つに落ちていた**
- **Final fix**: Fable に助言を求めて規定を読み直したところ、`skills/spec/reference.md` Step 8 は「findings を draft plan へ直接反映してから**最終版を1回だけ再レビューして打ち切る**」と明記しており、さらに「未解消 BLOCK は `unresolved_blocks` に列挙し**承認提示文で人間の明示 override を要求**、override 時は verdict を `BLOCK-overridden`」という**脱出ハッチが正規手順として存在していた**。attempt 4 の verdict は既に WARN・`unresolved_blocks: なし` で、止まっていたのはレビュー判定ではなく Record の書式だった
- **Insight**: **同一の根本原因が独立した 6 件の欠陥として現れた** — (1) 正準 hash アルゴリズムの誤用（whole-file shasum を 4 回記録。gate は Record 行より前のみを hash する。編集の有無に関わらず一致し得ない値だった）(2) Verification を inline code で記述（orchestrate は bash ブロックのみ抽出実行）(3) `review_attempts` が `started` 先頭キーでない（reference.md が「この書式は grep 契約であり**書式の自由度を持たない**」と明記）(4) `verdict` の markdown 太字（enum 不一致）(5) `unresolved_blocks` の markdown 太字（verdict=WARN との整合検査で BLOCK）(6) bash ブロック内コメントの禁止綴り。**うち (4)(5) は gate と同じ grep を実際に走らせて初めて出た** — Fable も PdM も事前に列挙できていない
- **一般化**: dev-crew は Progressive Disclosure（SKILL.md < 100 行、詳細は reference.md）を設計思想にしているが、**参照先を読まなくても先へ進めてしまう**構造になっている。CONSTITUTION §4-6 は「プロセス強制は決定論的コード、品質検出は LLM」と定めるのに、Step 8 では純粋に機械的な契約（hash・書式・bash ブロック・attempt 上限）を散文に置き、**検査を LLM reviewer に払わせていた**。Codex の P1 はほぼ全て lint 級であり、1 秒で終わる検査に 1 ラウンド数時間を払っていたことになる。恒久対策は #216（`plan-lint.sh`）。「読んだか」は検査できないが、**読まなくて済むようにはできる**

### Insight 2: oracle が穴を持つと、その穴の中では契約が壊れていても緑になる — positive 契約にも両側 oracle が要る

- **Failure**: VERIFY の V-3 変異注入は **12 probe すべて `ok`** を返した。それにもかかわらず REVIEW で `TC-33d/e`（overshoot 防止の positive 契約）が **vacuous** だと判明した。`-cF "├── agents/"` は全文部分一致のため、ツリー行を削除して同じ文字列をコメント等へ移すだけで PASS する（Codex 再現手順で実測 `-cF=1`）。plan には「TC-33a/b は行が消えれば 0 件で vacuous PASS になるため、d/e と対で初めて意味を持つ」と書いていたのに、**その d/e 自身が守っていなかった**
- **Final fix**: Codex P2-2 / correctness optional-2 / test-reviewer optional-2 の **3 者が独立に同じ 1 行へ収束**。行頭アンカー付き `-cE '^[[:space:]│]*[├└]──[[:space:]]+agents/'` へ変更し、両側 oracle で再測（反例が 0 で FAIL / 実ファイル各 1 / 書式変種 `└──`・nested・空白 2 を検出 / 誤検出 0）
- **Insight**: **negative 契約に 4 ラウンドかけた一方、positive 契約は「行が存在すればいい」と素朴に書いて検証しなかった。** V-3 の probe は「行を削除する」形しか持たず、「削除して同じ文字列を別の場所へ移す」を測っていない。前 cycle Insight 2「negative 契約は検出できることだけを測ると振り子が振れる」の**対称版が必要**: positive 契約も「守るべきものが本当に守られているか」を、素朴な満たし方（文字列がどこかにあればよい）で通らないことまで測る
- **一般化**: 契約を書いたら、その契約を**最も安易に満たす方法**を 1 つ考えて probe にする。「行を消す」より「行を消して文字列を別所へ置く」の方が安易な満たし方であり、そちらを測っていなかった

### Insight 3: plan に書いた規律と、実行時に守る規律は別物

- **Failure**: red-worker の実行中に検証コマンドを並行起動し、load average が **14.37** まで上がって両方が遅延した。worker は 45 tool use 後に中途半端な応答で打ち切られ、**コード変更は完了していたのに Cycle doc の記録が一切残らなかった**（`phase: KICKOFF` のまま、Progress Log エントリなし、Test List 遷移なし）
- **Final fix**: `TaskStop` で両方停止 → 負荷が落ちるのを待って直列で再実行 → 実測値を渡して記録のみを別 worker へ委譲
- **Insight**: 「読み取り並列・実行直列」は recall（cycle 20260702_1200 #2）で拾い、**plan の Recall 節に「V-3 の変異注入は PdM が直列で実施する」と明記していた**。それでも実行時に破った。**規律を plan に書くことは、実行時にそれを守ることを保証しない**
- **一般化**: 並行起動は「起動する側が忘れる」型の違反であり、prompt や plan への記載では防げない。テストを実行するプロセスの起動前に `pgrep -f 'tests/test-'` を確認する、を機械的手順として組み込む（#221 の phase-exit-gate に含められる）

### Insight 4: 「参照されているか」でなく「その参照に意味があるか」を見る

- **Failure**: REFACTOR のチェックリスト項目 3（未使用定義）で、`tests/test-agents-md-propagation.sh` の `SKILLS_STRUCTURE_TEST` を見逃した。私の検査は「参照回数 0 のトップレベル代入」を探すものだったが、この変数は L17 の存在確認ループで**参照されていた**ため掛からなかった。しかしその参照自体が、削除済み TC-14 のためだけに必要だった死んだ足場であり、当該ファイルが将来リネーム・削除されると `fail()` を経由せず `exit 1` で Summary 未到達の hard-exit になる
- **Final fix**: Codex P2-1 と correctness optional-1 の 2 者が指摘 → `COMMIT_SKILL` のみを要求する形へ縮小
- **Insight**: 削除 cycle では「削除対象と一緒に消えるべき足場」が残りやすい。**参照カウントは足場の生死を判定できない** — 足場同士が互いを参照していれば両方とも「参照あり」になる。判定には「残った TC が実際にそのファイルを読むか」という**用途の追跡**が要る
- **一般化**: REFACTOR の未使用定義チェックを「参照 0」から「**残存する assertion のいずれかが実際に消費しているか**」へ変える

### 想起漏れ

- **設問**: 今回の手戻りは、過去のどの cycle doc を最初に読んでいれば防げたか
- **回答**: **cycle doc では防げなかった。読むべきだったのは `skills/spec/reference.md` の Step 8 節である。** これは想起漏れの新しい型を示している。`scripts/recall-candidates.sh` による強制想起は**機能した** — `docs/cycles/20260421_2342_agents-md-count-fix.md` を score 1.08 で拾い、その Verification に書かれていた「`test-cross-references.sh` が TC-B1 経由で PASS」という一文が、本 cycle の ABORT 波及調査（6 consumer + 増幅器 2 件）の起点になった。しかし **recall の対象は `docs/cycles/**` のみで、skill の reference.md は対象外**である。本 cycle の 6 件の欠陥はすべて reference.md に答えが書かれていた。recall を「過去の失敗」だけでなく「**これから使う skill の詳細仕様**」へ広げるか、あるいは #216 の plan-lint で機械的契約を script 側へ移して reference.md を読む必要自体を減らすか。後者の方が CONSTITUTION §4-6 に忠実である

## Codify Decisions

### Insight 1
- **Decision**: codified
- **Destination**: rule
- **Tier**: always
- **Reason**: 「SKILL.md の要約だけ読んで reference.md を読まない」は直近 10 cycle 中 3 cycle で再発（20260828_1030 / 20260723_1103 / 20260717_1605）。ただし「reference.md を読め」という散文条項を足すのは本 insight 自身が否定する対策であるため、**即時 rule 化するのは 1 条項に限る** — 「決定論 gate が読む書式（正準 hash・enum・grep 契約）を新設・変更したときは、gate と同じコマンドを実際に走らせて確認してから記録する」を plan-discipline.md へ。本 cycle では欠陥 6 件中 2 件（verdict / unresolved_blocks の markdown 太字）が、実際に gate の grep を走らせて初めて検出された。構造的対策（機械的契約を散文から script へ移す）は issue #216（plan-lint.sh）として起票済みで、そちらが本体。想起漏れ設問の回答（recall の対象が docs/cycles/** に限られ skill の reference.md を含まない）も #216 の射程に入る
- **Decided**: 2026-09-10 13:03

### Insight 2
- **Decision**: codified
- **Destination**: rule
- **Tier**: cycle-scoped
- **Reason**: 「両側 oracle」は直近 10 cycle 中 2 cycle（20260907_1324 / 20260903_1130）で言及され本 cycle が **3 回目**だが、rules/ には 1 件も条項が存在しない（grep 実測 0 件）。2-strike を超えているため rule へ昇格する。条項は test-patterns.md へ: 「契約を書いたら、その契約を**最も安易に満たす方法**を 1 つ考えて probe にする。negative 契約だけでなく positive 契約にも適用する（『行が存在する』を『行を消して同じ文字列を別所へ置く』で破れないか測る）」。本 cycle では TC-33d/e が 12 probe すべて ok を返しながら vacuous であり、Codex・correctness・test-reviewer の 3 者が独立に同じ 1 行へ収束した
- **Decided**: 2026-09-10 13:03

### Insight 3
- **Decision**: codified
- **Destination**: rule
- **Tier**: cycle-scoped
- **Reason**: 「読み取り並列・実行直列」は agent-prompts.md L37 に**既に条項として存在する**（cycle 20260702_1200 #2 由来）。それでも本 cycle で破られ load average 14.37 に達し、worker が打ち切られて Cycle doc の記録が全て失われた。直近 10 cycle でも 2 cycle が同型に言及（20260721_1503 / 20260717_1605）。**散文条項が 3 回目に破られた**ため、2-strike rule（cycle 20260703_1215 #2）に従い機械的手順へ格上げする: 「テストを実行するプロセスを起動する前に  が空であることを確認する」を agent-prompts.md の当該条項へ追記。issue #221 の phase-exit-gate に取り込める場合はそちらへ寄せる
- **Decided**: 2026-09-10 13:03

### Insight 4
- **Decision**: codified
- **Destination**: inline-update
- **Reason**: novel（直近 10 cycle に同型なし）。skills/refactor/SKILL.md のチェックリスト項目 3「未使用import」を「未使用定義（残存する assertion のいずれかが実際に消費しているか）」へ拡張する 1 行の変更で、次 cycle の REFACTOR から即座に効く。参照カウントは足場の生死を判定できない（足場同士が互いを参照していれば両方とも「参照あり」になる）という判定基準そのものの誤りであり、rule 化より skill のチェックリスト本体を直す方が適切
- **Decided**: 2026-09-10 13:03
