---
feature: risk-classifier-doc-diff-fix
cycle: 20260709_1125
phase: DONE
complexity: standard
test_count: 6
risk_level: low
retro_status: captured
codex_session_id: "019f44b8-2415-7870-93ec-cec1ef1fef71"
created: 2026-07-09 11:30
updated: 2026-07-09 12:13
---

# #164: risk-classifier の doc-diff 過大スコア修正（code-scoped content signals）

## Scope Definition

### In Scope
- [ ] `skills/review/risk-classifier.sh`: `code_only_diff()` awk helper 追加（`+++ b/<path>` から現ファイルを追跡、doc-ext `.md|.markdown|.txt|.rst|.mdx` の hunk を除外、header 不明な行は fail-open で scan）。SQL(L96)・external(L106)・行数(L111) をこの helper 経由の stream で計算。crypto(L101) と全 file-path シグナルは変更なし
- [ ] `tests/test-risk-calibration.sh`: (a) TC-04 fixture を legitimate MEDIUM に修正（FP 非依存化）、(b) 新 TC: doc-only diff（.md に `updated:`/`deleted`）→ not HIGH(<60)、(c) 新 TC: mixed diff（code .sh の SQL + doc .md）→ SQL は code 部から発火
- [ ] `tests/test-risk-classifier.sh`: 既存 T-02（crypto headerless fixture）が fail-open で不変を確認する回帰 TC、または code_only_diff の unit assertion 1 件

### Out of Scope
- reviewer-policy 機構は本 cycle に含めない（次サイクル）。本 cycle は classifier の信頼性回復のみ

### Files to Change（全量、追加・削除禁止）
1. `skills/review/risk-classifier.sh` — `code_only_diff()` awk helper 追加。SQL/external/行数を code-scoped 化。crypto/file-path シグナルは不変。header コメントに code-scoped / full-scoped シグナルの区別を明記
2. `tests/test-risk-calibration.sh` — TC-04 fixture 修正（FP 非依存化）+ 新 TC 2件（doc-only not-HIGH / mixed diff で SQL は code 部発火）
3. `tests/test-risk-classifier.sh` — crypto headerless fixture 回帰確認 TC または code_only_diff unit assertion
4. `docs/cycles/20260709_1125_risk-classifier-doc-diff-fix.md`（sync-plan 生成、本ファイル）
5. `docs/STATUS.md` — commit 時 Completed 行 + Done (unarchived) 64→65。Test Scripts 112 不変

## Environment

### Scope
- Layer: Bash (deterministic gate script) + test contracts
- Plugin: dev-crew
- Risk: LOW-MED — risk-classifier.sh の content/行数シグナルの scope を code hunk に限定する surgical な awk filter。gate の scoring 意味論に触れるが自己完結・可逆・既存テストで回帰検出可

### Runtime
- 環境: bash / macOS。Codex 復旧済み（0.142.5）。version gate PASS（2.10.0=2.10.0）

### Dependencies (key packages)
- なし（新規依存追加なし）

### Risk Interview (BLOCK only)
- 該当なし（見積 LOW-MED は BLOCK 未満）

## Context & Dependencies

### Reference Documents
- v2.12 の3番目のサイクル。reviewer-policy 機構（次サイクル）のコスト前提「上位モデル reviewer は HIGH でのみ起動」が信頼できるスコアの上に立つよう、risk-classifier の doc-diff FP を先に潰す（ユーザー承認の順序: #164 → reviewer-policy）
- `rules/multi-file-consistency.md`「gate は enumerate-and-reject / 決定論性維持」→ code-only filter は拡張子 allowlist ベースで決定論的
- `rules/plan-discipline.md`「count/status 変更の GREEN 検証は逆向き契約 sweep 全実行」→ TC-04 casualty を plan で先取り検出済み

### Dependent Features
- `tests/test-risk-calibration.sh`（既存 TC-01〜06）
- `tests/test-risk-classifier.sh`（既存 T-01〜10）
- `scripts/gates/pre-red-gate.sh` / `scripts/gates/pre-commit-gate.sh`（risk-classifier.sh を内部利用）

### Related Issues/PRs
- #164（risk-classifier doc-diff 過大スコア報告）
- PR #166 / commit 7737a73（HIGH 85 実測対象の doc cycle diff）

## Problem（実測済み、main = 1334227）

- #164 の報告: `skills/review/risk-classifier.sh:96` の SQL シグナル `grep -qiE 'SELECT|INSERT|UPDATE|DELETE|...'` が case-insensitive・境界なしのため、Markdown frontmatter の `updated:` や本文の「deleted」等に +25 で反応。
- **実測**: 直近 doc cycle（PR #166、commit 7737a73、rule doc + test のみ）を classifier に食わせると **HIGH 85**。内訳 = SQL +25（FP、`updated:` 系マッチ）/ 行数>200 +20（695 行）/ file数>5 +15（12 file）/ dir spread +15（4 dir）/ test +10。
- **SQL FP 単独除去では不十分**: 85 − 25 = **60 = まだ HIGH**（閾値 60）。doc cycle を HIGH から外すには content シグナル + 行数シグナルの category error（コード挙動の指標を散文に適用）を直す必要がある。
- **プロトタイプ実証**: content(SQL/external) + 行数を「code hunk のみ」で計算すると、doc cycle は SQL 0・code 行 <200 → **85 → 40 = MEDIUM**（HIGH 脱出）。実コード diff の SQL は検出維持、headerless fixture も従来通りスキャン。

## Baseline（実測、architect が現物確認）

- `skills/review/risk-classifier.sh` の SQL シグナル（L96 `grep -qiE 'SELECT|INSERT|UPDATE|DELETE|DROP|CREATE TABLE|DB::|database|migration|\.query\(|\.execute\('`）・crypto（L101）・external（L106）・行数（L111 `wc -l`）の存在を実読で確認。行番号は plan 記載と完全一致。
- commit 7737a73 の実 diff（`git show 7737a73` / `git diff-tree --no-commit-id --name-only -r 7737a73`）を現行 classifier に投入し実測: `HIGH score:85`（12 files, 695 diff lines）。plan 記載の HIGH 85 と完全一致。
- code hunk 抽出実測（`tests/test-codify-rule-docs.sh` の hunk のみ、他11ファイルは全て `.md`）: 113 行（<200）。SQL パターン・external パターンともに **マッチなし**。crypto パターンも全 diff 中マッチなし（design rationale の「本 cycle の doc diff では crypto=0」と一致）。
  → code-only 化後のスコア = 85 − 25(SQL) − 20(行数) = **40 = MEDIUM**（プロトタイプ主張と完全一致、architect が実データで再現）。
- `tests/test-risk-calibration.sh` TC-04 fixture（`docs/d.md` に「Updated.」）を実読で確認: SQL 正規表現の `UPDATE` は case-insensitive のため `"Updated"` の先頭6文字 `"Updat e"`（Update）にマッチ。TC-04 現状スコア内訳 = dirspread15 + test10 + SQL25(FP) = 50 = MEDIUM。code-only 化で SQL 分が消え 25 = LOW に低下し、既存 assertion（MEDIUM or HIGH）が FAIL することを確認（casualty 実証済み）。
- `tests/test-risk-calibration.sh` TC-03（`auth/login.php` の SELECT + `migrations/001.sql` の CREATE TABLE）・TC-05（`auth/token.php` の crypto+SQL）: 対象ファイルはいずれも `.php`/`.sql` で doc-ext 除外リスト（`.md|.markdown|.txt|.rst|.mdx`）に含まれないため、code-only 化後も code hunk として scan される。影響なしを確認。
- `docs/STATUS.md` 実測: `Done (unarchived) | 64` / `Test Scripts | 112`。plan 記載の 64→65 / 112 不変と一致。
- baseline 実行（bash tests/test-*.sh の rc）は PdM が並行して snapshot baseline を取得中のため、本 architect フェーズでは実行しない（テスト実行禁止の指示に従う）。rc baseline は RED フェーズ開始前に別途取得される。

## 逆向き契約 sweep（実測、grep literal 貼付）

- **TC-04 は SQL FP 依存（要修正、casualty）**: `tests/test-risk-calibration.sh` TC-04（wide 4 dirs → MEDIUM+）の fixture は `docs/d.md` の「Updated.」が SQL FP を踏んで +25 し、dirspread15+test10+SQL25=50=MEDIUM に到達している。code-only 修正後は SQL 0 → 25=LOW に落ち **TC-04 assertion が FAIL**。→ 本 cycle で fixture を legitimate な MEDIUM に修正する（同一 subject=classifier のテストなので scope 内）。
- **TC-03 / TC-05 は影響なし**: SQL が `auth/login.php`・`migrations/001.sql`（`.sql` は doc-ext 除外リストに含めない）・`auth/token.php` の code hunk にあるため code-only 後も発火。TC-05 の crypto は all-hunks 維持で不変。
- **TC-01（Markdown only → LOW）**: .md 除外後も LOW 維持（むしろ 25→0 に低下、LOW 帯内）。
- 新規テストファイルなし（既存 2 test へ TC 追加/修正）→ Test Scripts 112 不変、STATUS.md bump 不要。
- `grep -rn "score:85\|score:60\|score:50" tests/` 相当で score literal の逆向き契約は Block 0（RED 開始前）で再実行する。

## 設計判断: なぜ SQL/external/行数は code-only で crypto は all-hunks か

- **code-scoped（SQL / external / 行数volume）**: これらは「コードの挙動リスク」（SQL injection surface、外部通信、コード量）の指標。散文にマッチしても意味を持たない純ノイズ。code hunk のみで計算するのが原理的に正しい。
- **full-scoped（crypto/secret）**: 秘密情報の露出は `.md` を含む**どのファイルでも**リスク。code-only にすると markdown にコミットされた credential を見逃す blind spot を作る。よって all-hunks 維持（本 cycle の doc diff では crypto=0 なので挙動不変）。
- **file-path シグナル（auth/api/ui/test/filecount/schema/dirspread）**: 変更の「広さ」を測る指標で hunk 内容と独立。不変。
- fail-open 原則: `+++ b/` header で doc と明示されない hunk は scan する（headerless fixture・実 git diff の両方で安全側）。real code を under-score しない。

## Test List

### TODO
(none)

### WIP
(none)

### DISCOVERED
(none)

### DONE
- [x] calib TC-04（修正） — Given: 6 modified real files across 3 dirs (src/lib/tests)、FP 非依存の filecount+dirspread+test signal / When: classifier 実行 / Then: MEDIUM+ / RED 実測: `MEDIUM score:40`（PASS）/ GREEN 実測: `MEDIUM score:40`（PASS、維持）
- [x] calib TC-新1 — Given: doc-only diff（rules/*.md + docs/*.md、`updated:`/`deleted` 含む、8 file・3 dir 相当）/ When: classifier 実行 / Then: level != HIGH（score<60）/ RED 実測: `HIGH score:65`（FAIL、想定通り）/ GREEN 実測: `MEDIUM score:40`（PASS、SQL FP 除去で HIGH 脱出）
- [x] calib TC-新2 — Given: mixed diff（code .sh に real SQL(`DB::query`/`SELECT`) + doc .md に `updated:`）/ When: classifier 実行 / Then: SQL シグナル発火（code 由来）、score>=25 / RED 実測: `LOW score:25`（PASS）/ GREEN 実測: `LOW score:25`（PASS、同値維持）
- [x] calib TC-新3 — Given: doc hunk + 削除 code ファイル（`+++ /dev/null`、旧パス `--- a/src/legacy.php`、hunk に `-` 付き SELECT/DB::）の混在 diff / When: classifier 実行 / Then: 削除 code の SQL が score に反映（under-score なし、score>=25）/ RED 実測: `LOW score:25`（PASS）/ GREEN 実測: `LOW score:25`（PASS、堅牢版 code_only_diff が old path で code 判定し同値維持）
- [x] calib TC-新4 — Given: binary diff（`diff --git a/img.png b/img.png` + `Binary files ... differ`、`+++` ヘッダなし）/ When: classifier 実行 / Then: クラッシュせず正常な `level:score` 出力 / RED 実測: `LOW score:0`, rc=0（PASS）/ GREEN 実測: `LOW score:0`, rc=0（PASS、堅牢性回帰確認）
- [x] classifier T-11（crypto headerless 回帰） — Given: headerless fixture（`+password = hash(input)`、file=`src/auth/login.php`）/ When: classifier 実行 / Then: crypto+auth 発火維持（fail-open）、score==55 exactly / RED 実測: `MEDIUM score:55`（PASS）/ GREEN 実測: `MEDIUM score:55`（PASS、fail-open 不変）

## Implementation Notes

### Goal
risk-classifier.sh の doc-diff 過大スコア FP を修正し、reviewer-policy 機構（次サイクル）の前提となるスコア信頼性を回復する。

### Design Approach
`code_only_diff()` awk helper を新設し、`+++ b/<path>` header を追跡して doc-ext（`.md|.markdown|.txt|.rst|.mdx`）hunk を除外したストリームを SQL・external・行数シグナルの入力とする。crypto と file-path シグナルは既存のまま全 diff / 全ファイルリストを対象に計算する。header 不明の hunk は fail-open（scan する）。

## Verification（integration-verification 準拠、rc 明示 + real-path + full suite）

```bash
bash tests/test-risk-calibration.sh; echo "risk-calibration rc=$? (expected 0)"
bash tests/test-risk-classifier.sh; echo "risk-classifier rc=$? (expected 0)"
# real-path: 実 doc cycle 相当の diff で not HIGH を実証
FILES=$(mktemp); DIFF=$(mktemp); git show 7737a73 > "$DIFF"; git diff-tree --no-commit-id --name-only -r 7737a73 > "$FILES"
bash skills/review/risk-classifier.sh "$FILES" "$DIFF"; echo "-> expected MEDIUM/LOW (was HIGH 85)"
# real-path: 実コード SQL diff で HIGH 維持（TP 回帰なし）
bash scripts/gates/pre-red-gate.sh docs/cycles/20260709_1125_risk-classifier-doc-diff-fix.md; echo "pre-red rc=$?"
bash scripts/gates/pre-commit-gate.sh docs/cycles/20260709_1125_risk-classifier-doc-diff-fix.md; echo "pre-commit rc=$? (expected 1: REVIEW 前 BLOCK)"
# full suite: Holdings 親構造複製 snapshot・直列、Block 0 baseline と diff（空=回帰ゼロ）
```

Evidence: (orchestrate が自動記入)

architect による事前実データ検証（本 KICKOFF フェーズで実施、テスト実行なし・grep/読み取りのみ）:
```
$ FILES=$(mktemp); DIFF=$(mktemp); git show 7737a73 > "$DIFF"; git diff-tree --no-commit-id --name-only -r 7737a73 > "$FILES"; bash skills/review/risk-classifier.sh "$FILES" "$DIFF"
HIGH score:85
$ (code hunk のみ抽出 → SQL/external パターン grep) → 両方 no match, hunk行数=113(<200)
→ 85 - 25(SQL) - 20(行数) = 40 = MEDIUM 予測（GREEN で code_only_diff 実装後に再検証）
```

## Upstream References

- メモリ再開ポインタ v2.12 バックログ、reviewer-policy の前提整備（#164）
- rules/multi-file-consistency.md「gate は enumerate-and-reject / 決定論性維持」→ code-only filter は拡張子 allowlist ベースで決定論的
- rules/plan-discipline.md「count/status 変更の GREEN 検証は逆向き契約 sweep 全実行」→ TC-04 casualty を plan で先取り検出済み

## 注記

**Design Review Gate（architect、2026-07-09 11:30 実施）**: PASS（詳細は Progress Log KICKOFF エントリ参照）。

## Progress Log

### 2026-07-09 11:30 - KICKOFF (architect)
- sync-plan Phase completed
- Cycle doc created from approved plan (`/Users/morodomi/.claude/plans/gentle-stirring-hopper.md`)
- Scope definition ready。Files to Change 5件は plan を全量転記（追加・削除なし）
- **Design Review Gate 判定: PASS**（スコア目安 10/100、詳細は下記）
  - **Scope**: Files to Change 5件（<=10 充足）。修正対象は risk-classifier.sh 1本 + test 2本 + cycle doc + STATUS.md のみ。YAGNI 違反なし（reviewer-policy 機構は明示的に Out of Scope として次サイクルへ分離済み）
  - **Architecture**: `skills/review/risk-classifier.sh` を実読し、SQL シグナル(L96)・crypto(L101)・external(L106)・行数(L111) の存在と行番号を plan 記載と完全一致で確認。commit 7737a73 の実 diff を現行 classifier に投入し `HIGH score:85` を実測（plan 主張と完全一致）。code hunk 抽出実測で SQL/external ともに no-match・行数113(<200)・crypto no-match を確認し、「85−25−20=40=MEDIUM」という plan のプロトタイプ主張を architect 自身のデータで再現。`tests/test-risk-calibration.sh` TC-04 の fixture（`docs/d.md`「Updated.」）が SQL 正規表現の `UPDATE` に前方一致することを実読で確認し、TC-04 casualty を検証済み。TC-03/TC-05 の対象ファイル拡張子（`.php`/`.sql`）が doc-ext 除外リストに含まれないことも確認し、影響なし判定を裏付けた
  - **Test List**: 4件、非空。正常系（TC-03/TC-05 相当の既存回帰維持）・境界値（TC-04 修正、doc-ext 境界）・異常系相当（headerless fixture の fail-open 回帰）を網羅。Given/When/Then は plan 記載のまま転記、全て検証可能な具体的入出力
  - **Risk**: plan 記載の LOW-MED は、変更が単一 gate script の awk helper 追加 + 既存テスト2本の修正/追加という自己完結・可逆スコープと整合。frontmatter risk_level は low とする（作業内容が determinsitic script の scope 限定という低リスク改修であるため）
  - 検証条件（照合済み）: SQL/external/行数/crypto の行番号一致、TC-04 casualty 再現、TC-03/TC-05 非影響、HIGH 85 / code-only 40 の実測一致、STATUS.md 64/112 の実測一致 — 全て現物と整合
- 次フェーズ: plan-review（Codex competitive）へ

## Codify Decisions
(none — retro_status: none)

### 2026-07-09 11:37 - BLOCK 0 BASELINE + PLAN REVIEW (Codex competitive)

**Block 0 baseline（Holdings 親構造複製 snapshot、直列、rule C 自己適用）**: **112/112 全 rc=0**（scratchpad/baseline-cycle3.txt）。codify gate: 前 cycle 20260707_0936 の captured retro を本 Block 0 で triage 済み（全 3 件 no-codify、resolved 遷移）。captured scan 空を確認。

**PLAN REVIEW 判定: BLOCK 1 / WARN 1 / PASS 3**。codex_session_id: 019f44b8-2415-7870-93ec-cec1ef1fef71 を frontmatter に記録。Codex はテスト実行禁止を遵守（読み取り・rg のみ）。

**triage（BLOCK は accept-apply して Cycle doc の code_only_diff 契約を堅牢化。plan file は IMMUTABLE のため本 Cycle doc を実装 SSOT とする — doc-mutations.md 準拠）**:

- **B1（BLOCK、accept-apply）: `code_only_diff` の diff 境界仕様不足。** 私の初期プロトタイプ（`+++ b/<path>` のみ追跡）は (i) 削除ファイル `+++ /dev/null`（パスは `--- a/<path>` 側）、(ii) binary diff（`+++` なし）、(iii) diff metadata 行を扱えず、「doc hunk の後に code ファイル削除」で state が doc のまま code 削除を除外 → **real code を under-score する穴**。Codex 指摘は妥当。
  - **堅牢版 code_only_diff 契約（GREEN はこれを実装する）**:
    ```awk
    /^diff --git/ { indoc=0; inhunk=0; hasheader=1; next }   # per-file reset + metadata drop
    /^--- /       { a=$2; inhunk=0; next }                    # capture old path
    /^\+\+\+ /      { b=$2; p=(b=="/dev/null"?a:b); sub(/^[ab]\//,"",p);
                    indoc=(p ~ /\.(md|markdown|txt|rst|mdx)$/)?1:0; inhunk=0; next }  # +++ /dev/null は old path で doc/code 判定
    /^@@/         { inhunk=1; next }                          # hunk body 開始
    { if (hasheader && !inhunk) next; if (indoc) next; print } # metadata skip / doc skip / headerless は fail-open scan
    ```
  - **プロトタイプ実証済み（本 KICKOFF、テスト本体は未実行・oracle 単発のみ）**:
    - (a) doc hunk 後の削除 `.php` の `SELECT`/`DB::` → **保持（count=1）** = under-score 穴の解消
    - (b) binary diff → 0 行・クラッシュなし
    - (c) 実 doc cycle diff（7737a73）→ SQL 0・code 行 128(<200)
    - (d) headerless fixture `+password=...` → crypto scan 発火（fail-open）
    - (e) 実コード SQL diff → 保持（TP 回帰なし）

- **W1（WARN、accept-apply）: TC-04 の TC 名/意図明確化。** SQL FP 除去後は dirspread15+test10=25=LOW。修正 fixture は「FP 非依存の legitimate MEDIUM」を明示するため、TC 名を「wide change with >5 modified real files → MEDIUM+」等に更新し、filecount>5(+15) 等の FP 非依存シグナルで MEDIUM に到達させる（`docs/d.md` の「Updated.」依存を排除）。

- **P（PASS 3）**: content signal の code-scope 化（category error 修正）/ crypto all-hunks 維持 / fail-open 原則 — いずれも妥当と確認。

**Test List 追加（B1 反映、edge case 契約化）**:
- [x] TC-新3（REVIEW で TC-09 に rename）: Given doc hunk + 削除 code ファイル（`+++ /dev/null`）の混在 diff, When classifier 実行, Then 削除 code の SQL がスコアに反映（under-score なし）→ GREEN 実測 LOW 25 PASS
- [x] TC-新4（REVIEW で TC-10 に rename）: Given binary diff（`Binary files ... differ`）, When code_only_diff 通過, Then クラッシュせず content スコア 0 → GREEN 実測 LOW 0 PASS

- 判定: BLOCK 解消の堅牢版契約を Cycle doc に記録済み。Block 2a (RED) へ

### 2026-07-09 11:42 - RED (red-worker)

**担当**: tests/test-risk-calibration.sh（TC-04 修正 + TC-新1/新2/新3/新4）、tests/test-risk-classifier.sh（T-11 crypto headerless 回帰）。`skills/review/risk-classifier.sh` 本体は未変更（GREEN scope 外、rule 遵守）。

**RED の性質**: 本 cycle の TC は「現 classifier の FP を FAIL として顕在化」（TC-新1のみ）と「GREEN 堅牢版導入後も壊れない契約 pin」（TC-04/新2/新3/新4/T-11）の混在。各 fixture を現行 classifier に実投入し、以下の RED 時点実測を確認した:

| TC | Fixture | RED 実測 | 判定 |
|----|---------|----------|------|
| calib TC-04（修正） | 6 modified real files, 3 dirs (src/lib/tests), FP非依存 | `MEDIUM score:40` | PASS（filecount15+dirspread15+test10=40、`docs/d.md`「Updated.」casualty 排除確認） |
| calib TC-新1 | doc-only 8 files, 3 dirs (rules/docs/notes), `updated:`/`deleted` 含む | `HIGH score:65` | **FAIL**（想定通り。dirspread15+filecount15+test10+SQL-FP25=65≥60。GREEN で SQL 分除去→40=MEDIUM へ低下し PASS 予定） |
| calib TC-新2 | mixed: code `.sh`(`DB::query`/`SELECT`) + doc `.md`(`updated:`) | `LOW score:25` | PASS（SQL+25 のみ、code 由来発火を確認。GREEN 後も同値維持が回帰契約） |
| calib TC-新3 | doc hunk + 削除 code（`+++ /dev/null`、旧パス `src/legacy.php`、`-`付き SELECT/DB::） | `LOW score:25` | PASS（現状は全 diff scan のため SQL 既に反映。GREEN の堅牢版 code_only_diff が `+++ /dev/null` を旧パスで doc/code 判定し同値維持することが契約の主眼） |
| calib TC-新4 | binary diff（`Binary files ... differ`、`+++`なし） | `LOW score:0`, rc=0 | PASS（クラッシュなし、堅牢性回帰） |
| classifier T-11 | headerless `+password = hash(input)`, file=`src/auth/login.php` | `MEDIUM score:55` | PASS（auth25+crypto30=55 exact、fail-open 維持を回帰契約として pin） |

**テスト実行結果（個別実行、full suite/nested runner 不使用）**:
- `bash tests/test-risk-calibration.sh` → rc=1（9 passed, 1 failed = TC-新1 のみ FAIL、想定通り）
- `bash tests/test-risk-classifier.sh` → rc=0（11 passed, 0 failed、T-11 含め全 PASS。回帰契約 TC は RED 時点で PASS 維持が正しい状態）

**RED State 判定**: TC-新1 が現 classifier の doc-diff FP を明確に FAIL として顕在化（red_state_verified の中核根拠）。他 5 TC は「GREEN 後も壊れない契約」として fixture・assert を正しく用意し、RED 時点の実測値を上表に固定した。全 TC が FAIL する汎用 Verification Gate ではなく、cycle 設計で明示された「FP 顕在化 + 契約 pin の混在」を採用（delegation prompt 明記の通り）。

**想定外事象**: なし。全 fixture の実測値は事前予測（delegation prompt の期待値記述）と完全一致。

- Phase completed

### 2026-07-09 11:48 - GREEN (green-worker)

**担当**: `skills/review/risk-classifier.sh` のみ（テストファイルは RED 成果物、無変更）。

**実装内容**（Cycle doc「PLAN REVIEW (Codex competitive)」B1 の堅牢版 awk 契約をそのまま実装）:
1. `code_only_diff()` helper を新設。`+++ b/<path>` header を追跡し doc-ext（`.md|.markdown|.txt|.rst|.mdx`）hunk を除外。削除ファイル（`+++ /dev/null`）は `--- a/<path>` 側の旧パスで doc/code 判定。`diff --git`/`index`/`mode` 等の metadata 行は hunk body でないため除外。header 不明（headerless fixture）は `hasheader` 未設定=偽 → fail-open で全行 scan。
2. SQL シグナル（旧 L96）・external シグナル（旧 L106）・行数シグナル（旧 L111）を `code_only_diff "$DIFF_CONTENT" | grep/wc` 経由に変更。crypto（旧 L101、変更なし・all-hunks 維持）と全 file-path シグナル（auth/api/ui/test/filecount/schema/dirspread、変更なし）は元のまま `$DIFF_CONTENT`/`$FILES_LIST` を直接参照。
3. header コメントに「Signal scoping」セクションを追加し、code-scoped（SQL/external/line-volume）と full-scoped（crypto/secret、全 file-path signals）の区別とその理由（プローズ誤検知の排除 / secret 露出は全ファイル種でリスク）を明記。

**set -e/pipefail 安全性（rule self-apply）**: 新規 `code_only_diff "$DIFF_CONTENT" | grep -qiE ...` は `if` 条件内のみで使用（既存の `grep -qiE ... "$FILE"` if 判定と同型）。`diff_lines=$(code_only_diff "$DIFF_CONTENT" | wc -l | tr -d ' ')` は awk/wc/tr がいずれも常に rc=0 を返すため、旧実装（`wc -l < "$DIFF_CONTENT" | tr -d ' '`、fallback なし）と同じ安全性プロファイルで変更なし。`grep -n '=\$(' skills/review/risk-classifier.sh` でファイル内の全 command-substitution 代入を sweep し、他の代入（`file_count`/`has_modified`/`dir_count`）は既存の `|| fallback=0` パターンを維持しており今回の変更で新規に触れていないことを確認。

**テスト実行結果（個別実行、full suite/nested runner 不使用）**:
```
bash tests/test-risk-calibration.sh; echo "calibration rc=$?"
→ === Results: 10 passed, 0 failed === / calibration rc=0
bash tests/test-risk-classifier.sh; echo "classifier rc=$?"
→ PASS: 11 / FAIL: 0 / classifier rc=0
```
全 TC 実測（GREEN 後）:
| TC | GREEN 実測 | 判定 |
|----|-----------|------|
| calib TC-04 | `MEDIUM score:40` | PASS（維持） |
| calib TC-新1 | `MEDIUM score:40` | PASS（RED の `HIGH score:65` から HIGH 脱出、SQL FP 除去） |
| calib TC-新2 | `LOW score:25` | PASS（同値維持、SQL は code 由来で発火） |
| calib TC-新3 | `LOW score:25` | PASS（同値維持、削除 code の SQL under-score なし） |
| calib TC-新4 | `LOW score:0`, rc=0 | PASS（binary diff クラッシュなし） |
| classifier T-11 | `MEDIUM score:55` | PASS（headerless crypto fail-open 不変） |

**real-path 実測（doc cycle diff、was HIGH 85）**:
```
FILES=$(mktemp); DIFF=$(mktemp); git show 7737a73 > "$DIFF"; git diff-tree --no-commit-id --name-only -r 7737a73 > "$FILES"
bash skills/review/risk-classifier.sh "$FILES" "$DIFF"
→ MEDIUM score:40
```
plan/architect の予測（85−25(SQL)−20(行数)=40=MEDIUM）と完全一致。

**構文・環境確認**: `bash -n skills/review/risk-classifier.sh` → syntax OK。実行環境の awk は BSD awk（macOS 標準、gawk/mawk 不在）で、全テストが該当 awk 上で PASS したため互換性確認済み。

**想定外事象**: なし。全実測値が Cycle doc の堅牢版契約・plan 予測と完全一致。

- Phase completed

### 2026-07-09 11:49 - REFACTOR + SELF-APPLY (PdM)

- チェックリスト 7 項目: `code_only_diff` は単一責務の awk helper で header コメントに edge case（`/dev/null`・binary・metadata・headerless fail-open）を詳述済み。重複コード・定数化・N+1 等いずれも該当なし — **構造リファクタ不要（no-op）**
- Verification Gate: calibration rc=0（10/10）/ classifier rc=0（11/11）/ tracking-label grep rc=1（clean）/ `bash -n` syntax OK
- **self-apply checklist**: rule C（親構造複製 snapshot で baseline 実測 112/112）/ rule D（green-worker が既存代入 sweep、新規 `code_only_diff | grep` は if 内 grep と同型で裸代入新規なし）/ rule E（全 worker + PdM が date 実測記録）— 全て準拠
- Phase completed

### 2026-07-09 11:49 - VERIFY (Product Verification, Block 2c.5)

- Evidence: /tmp/dev-crew-verify-20260709_1125/
- 単体: calibration rc=0 / classifier rc=0
- **real-path（本 cycle の核心実証）**: 実 doc cycle diff（commit 7737a73）を修正後 classifier に投入 → **MEDIUM 40（was HIGH 85）**。#164 FP 解消を production path で実証
- gate real-path: pre-red rc=0 / pre-commit → REVIEW 前 BLOCK（正常）
- full suite（Holdings 親構造複製 snapshot、直列）: 結果は COMMIT エントリに記録
- Phase completed

### 2026-07-09 12:01 - REVIEW (Codex competitive + 3 Claude reviewers, HIGH tier)

- **リスクスコア**: risk-classifier.sh 自身の diff は **HIGH 125**（classifier + test fixture が実 SQL/crypto を含む code hunk = 正当な HIGH、FP ではない。修正が過剰抑制していない証左）。security-sensitive な gate 変更のため HIGH tier で Codex + correctness + security + maintainability の 4 view 実施。全 reviewer に「テスト実行禁止・静的のみ」を明示（rule E 精神 + agent-prompts テスト実行可否契約）
- 判定: **Codex BLOCK 1 / correctness WARN 2 / security WARN 2 / maintainability WARN 5**
- **triage（accept-apply 4 / accept-defer 2 / reject 0）**:
  1. **Codex BLOCK（pipefail + SIGPIPE under-score）**: accept-apply。`code_only_diff | grep -q` は grep 早期終了 → awk SIGPIPE(141) → `set -o pipefail` が pipeline を 141 にして `if` が「非検出」判定 → **大 diff で real code の SQL/external を under-score**。小 fixture では awk が先に終わるので tests は緑（flaky bug）。correctness の「if 条件で -e 免除だから安全」は pipefail の rc 書き換えを見落とした誤り。**修正**: `code_only_diff` を temp file に1回 materialize → file grep（pipe 廃止で SIGPIPE 解消 + maint#1 DRY 同時解消）。**実証**: 5001 行 code diff の先頭 SQL → MEDIUM 45（SQL+25 計上、under-score なし）
  2. **Codex WARN + correctness WARN1 + security WARN2（空白パス、3 reviewer 共通）**: accept-apply。awk パス抽出を `$2`（空白分割で truncate）→ `sub(/^--- /,"")` / `sub(/^\+\+\+ /,"")` の whole-line 抽出に変更。**実証**: `+++ b/docs/my file.md` + prose SQL → LOW 0（doc 認識、FP なし）
  3. **maintainability #2（TC 命名規約違反）**: accept-apply。`TC-新1〜4` → `TC-07〜10` に rename し TC-06 の後ろへ移動（TC-01〜10 monotonic）。10/10 PASS 確認
  4. **security WARN1 + maintainability #4/#5（doc note + 整列 + docstring）**: accept-apply。header コメントに「score は supplementary reviewer 選択のみ調整、NON-NEGOTIABLE security/correctness gate は score 非依存で常時起動 → code-scoping は security review を bypass しない」を明記 + awk 整列微修正
  5. **correctness WARN2（diff-of-diff の `+++ ` 誤認）**: accept-defer → DISCOVERED。hunk body 内の追加行が literal `++ path`（diff prefix で `+++ path` 化）だと header 誤認。理論的・低確率、現 fixture は非該当を確認。issue 化
  6. **maintainability #3（doc-ext リスト 3 箇所重複）**: accept-defer → DISCOVERED。将来拡張時の drift リスク（機能影響なし）。issue 化
- **security の重要確認（accept として記録）**: code-scoping は NON-NEGOTIABLE security/correctness reviewer（score 非依存）を bypass しない。crypto は full-scoped 維持で markdown の secret 露出を拾い続ける。doc-ext 偽装（`.md.php`）は `$` anchor で code 判定 → 悪用不可。逆方向（real code を `.md` 名で偽装）のみ blind spot だが supplementary reviewer の under-trigger に留まる
- 適用後検証: calibration 10/10 rc=0 / classifier 11/11 rc=0 / SIGPIPE 回帰（5001行）実証 / 空白パス実証 / doc cycle MEDIUM 40 維持 / label 契約 grep rc=1（clean）
- Phase completed

## DISCOVERED

- [x] D1: code_only_diff の hunk body 内 literal `+++ `/`--- ` 行 header 誤認（correctness WARN2、理論的・低確率）→ issue #167 起票済み
- [x] D2: doc-ext リスト 3 箇所重複（maintainability #3、drift リスク・機能影響なし）→ issue #168 起票済み

## Retrospective

抽出時刻: 2026-07-09 12:04
抽出方法: Cycle doc 全体（Codex plan BLOCK 1 / code BLOCK 1 / reviewer 間の正誤分岐）からの失敗→最終解→insight ペア抽出

### Insight 1: pipe + `grep -q` は set -o pipefail 下で SIGPIPE により「match したのに失敗」になる。small fixture では awk が先に終わり緑になる flaky bug
- **Failure**: GREEN で content signal を `code_only_diff "$DIFF" | grep -qiE '...'` に変更。全テスト緑。しかし Codex code review が「pipefail 下で grep -q 早期終了 → awk SIGPIPE(141) → pipeline rc=141 → `if` が非検出判定 → 大 diff で real code を under-score」を指摘（BLOCK）。small fixture では awk が grep 終了前に出力完了するため SIGPIPE が起きず緑になっていた（input-size 依存の flaky）。correctness reviewer は「if 条件だから set -e 免除で安全」と誤判定（pipefail が rc を書き換える点を見落とし、Codex と結論が割れた）
- **Final fix**: `code_only_diff` を temp file に1回 materialize → file を直接 grep（pipe 廃止で SIGPIPE 完全排除 + 3回パースの DRY 同時解消）。5001 行 code diff の先頭 SQL で under-score しないことを実証
- **Insight**: **`cmd | grep -q`（早期終了する consumer）を `set -o pipefail` 下で使わない。upstream が SIGPIPE で非ゼロ終了し、pipefail が pipeline rc をそれに書き換えるため「match したのに if が false」になる。fix は (a) file/変数に materialize して pipe を消す、(b) `grep -q` を `grep ... >/dev/null` に、のいずれか。`set -e` の if 免除規則は pipefail の rc 書き換えを免除しない — 両者は別機構**
- **一般化**: rules/test-patterns.md 追記候補（本 cycle が codify した「set -e 下の裸代入 同型 sweep」の pipe 版）。small fixture が SIGPIPE を隠す点は「テストが通っても production で壊れる」典型例

### Insight 2: reviewer 間で結論が割れたら、機構レベルまで分解して正誤を判定する（多数決でなく）
- **Failure**: 同じ pipe について Codex は BLOCK、correctness は PASS（安全）と正反対の判定。PdM が「correctness が緑だから安全」と多数決的に流していたら bug が残った
- **Final fix**: pipefail と set -e の if 免除を別機構として分解し、SIGPIPE→awk 141→pipefail rc 書き換え→if false の連鎖を追って Codex が正しいと確定。5001 行 fixture で実証
- **Insight**: **competitive review で判定が割れたら、多数決や権威でなく「機構レベルの分解 + 実測 oracle」で決着させる。特に bash の rc 伝播（pipefail / set -e / SIGPIPE / command substitution）は reviewer ごとに mental model が違うため、実際に踏ませる fixture を作って観測する**
- **一般化**: rules/review-triage.md 追記候補（reviewer 判定分岐時の tie-break は実測）。adversarial reviewer（Codex）が単独で正しいケースの実例

### 成功事例（observation）: plan-review の BLOCK を Cycle doc に記録して plan file IMMUTABLE を守った
- Codex plan review が code_only_diff の `/dev/null`・binary・metadata 境界不足を BLOCK。plan file は approve 後 IMMUTABLE のため、堅牢版 awk 契約を Cycle doc の PLAN REVIEW エントリに記録し実装 SSOT とした（doc-mutations.md 準拠）。plan と実装詳細の drift を防ぎつつ Codex 指摘を反映。既 codified の運用パターンの追認であり no-codify

### 2026-07-09 12:13 - COMMIT

- 最終 full suite（Holdings 親構造複製 snapshot、直列、review-fix 反映後）: **112/112 全 rc=0、baseline との diff 空（回帰ゼロ）**（scratchpad/final2-cycle3.txt）
- pre-commit-gate（明示指定）rc=0 PASS → commit skill 経由で phase: DONE 遷移してから commit（Block 3 手順、frontmatter 区間限定編集）
- Test List Completion Gate: PLAN REVIEW エントリ内の `- [ ] TC-新3/新4`（実装済み=TC-09/10）を完了状態に更新して gate 通過
- STATUS.md: Done (unarchived) 64→65、Last updated 2026-07-09、Completed 行追加。Test Scripts 112 不変。README/AGENTS/CLAUDE は risk-classifier.sh が helper script（skill 定義変更でない）のため SKIP
- commit 同梱: skills/review/risk-classifier.sh + tests/test-risk-calibration.sh + tests/test-risk-classifier.sh + 本 cycle doc + STATUS.md
- feature branch → PR → --admin merge。Closes #164
- Phase completed
