---
feature: codify-rules-impl-and-gate-drift-guard
cycle: 20260706_1216
phase: DONE
complexity: standard
test_count: 5
risk_level: low
retro_status: captured
codex_session_id: "019f3573-1ba3-7040-a140-58b97fb1c0d3"
created: 2026-07-06 12:16
updated: 2026-07-06 16:16
---

# codify 実装 + #148 gate drift guard 統合サイクル

## Scope Definition

### In Scope
- [ ] rules/doc-mutations.md + .claude/rules/doc-mutations.md への新 H2「Frontmatter 遷移の区間限定編集 (cycle 20260703_2035 #1)」追記（byte-identical mirror）
- [ ] rules/test-patterns.md + .claude/rules/test-patterns.md への 禁止事項1 bullet + 推奨1 bullet + 出典1行 追記（byte-identical mirror）
- [ ] tests/test-codify-rule-docs.sh: section_grep の fixed-string 化（awk `$0 ~ "^## " h` → `index($0, "## " h) == 1`）+ TC-39/TC-40/TC-41 追加
- [ ] tests/test-phase-gate.sh: TC-24（pre-commit-gate.sh と pre-red-gate.sh の ACTIVE_CYCLE 選択ロジック drift guard、アンカー抽出 + 既知1行除外 diff）追加 + L3 header コメント `TC-01 ~ TC-22` → `TC-01 ~ TC-24` 修正
- [ ] #148 close（Closes #148）

### Out of Scope
- #148 の「Active Cycle echo 分岐重複」共有 lib 化（案(2)）: rules/multi-file-consistency.md「gate script は単体で full validation を完了できる設計」と衝突するため reject
- #148 LOW 項目（Active Cycle echo 分岐重複集約）: scope 外として defer（issue コメントに記録）
- 新規テストファイル作成（既存 2 ファイルへの TC 追加のみ。test count 112 は不変）

### Files to Change（全量、追加・削除禁止）
1. `rules/doc-mutations.md` — 新 H2「Frontmatter 遷移の区間限定編集 (cycle 20260703_2035 #1)」を「SSOT 即時同期」の直後に追加 + 出典1行追記
2. `.claude/rules/doc-mutations.md` — 1 と byte-identical mirror
3. `rules/test-patterns.md` — 禁止事項1 bullet + 推奨1 bullet + 出典1行追記
4. `.claude/rules/test-patterns.md` — 3 と byte-identical mirror
5. `tests/test-codify-rule-docs.sh` — (a) section_grep を fixed-string 化（L225 `$0 ~ "^## " h` → `index($0, "## " h) == 1`、L218-219 usage コメントの heading_regex → heading_prefix 更新）、(b) TC-39/TC-40/TC-41 追加
6. `tests/test-phase-gate.sh` — TC-24（gate 選択ブロック drift guard）追加 + L3 header コメント `TC-01 ~ TC-22` → `TC-01 ~ TC-24`（stale 修正の collateral 1行 fix。現 max は TC-23 と実測済み）
7. `docs/cycles/20260706_1216_codify-rules-impl-and-gate-drift-guard.md`（sync-plan 生成、本ファイル）
8. `docs/STATUS.md`（commit 時、Completed 行追加。Test Scripts 112 不変）

## Environment

### Scope
- Layer: Documentation / Test contracts（bash/doc project、実装コード変更なし）
- Plugin: dev-crew
- Risk: 20 (LOW) — rule doc + test のみ。gate 本体の動作変更なし

### Runtime
- Language: Bash（テストスクリプト）、Markdown（rule docs）
- 環境: bash / macOS。プラグイン version gate PASS（dev-crew.json 2.10.0 = installed 2.10.0）

### Dependencies (key packages)
- なし（新規依存追加なし）

### Risk Interview (BLOCK only)
- 該当なし（Risk 20 は LOW 帯であり BLOCK 未満）

## Context & Dependencies

### Reference Documents
- ROADMAP v2.12 バックログ先頭2項目（codify 実装、#148）に一致
- rules/multi-file-consistency.md（gate 単体 full validation 原則）→ 共有 lib 案 reject の根拠
- rules/state-ownership.md / rules/doc-mutations.md → 追記位置・APPEND-ONLY 遵守
- `docs/cycles/20260703_2035_tracking-label-contract.md` `## Codify Decisions` — Insight 1（→ rules/doc-mutations.md codified）、Insight 2（→ rules/test-patterns.md codified）の出典元。Insight 2 の Decision コメントが「helper の fixed-string 化は #148 と同時が効率的」と明記しており、本 cycle の統合根拠

### Dependent Features
- `tests/test-codify-rule-docs.sh`: 既存最終 TC は TC-38（本 cycle で TC-39〜41 を追加）
- `tests/test-phase-gate.sh`: 既存最終 TC は TC-23（本 cycle で TC-24 を追加、header コメントも同期修正）
- `tests/test-rules-mirror.sh`: rules/ と .claude/rules/ の byte-identical 契約（既存、無変更で維持検証）
- `scripts/gates/pre-commit-gate.sh` / `scripts/gates/pre-red-gate.sh`: TC-24 drift guard の検査対象（gate 本体は無変更）

### Related Issues/PRs
- Issue #148（ACTIVE_CYCLE 選択ロジック重複の drift guard、本 cycle で close）
- codify 元 cycle: `docs/cycles/20260703_2035_tracking-label-contract.md` Insight 1 / Insight 2

## Problem（全て実測済み、plan より転記）

1. **codified rule 2 件が未実装**（20260703_2035 `## Codify Decisions` で codified、実装は「次の codify 実装 cycle」に委ねられた）:
   - Insight 1 → rules/doc-mutations.md: frontmatter 遷移の区間限定編集（全文一括置換が本文を汚染し commit 混入した実害 evidence あり）
   - Insight 2 → rules/test-patterns.md: section_grep heading の ERE 解釈（括弧付きフル見出しで silent no-match の実測 evidence あり）
2. **#148**: ACTIVE_CYCLE 選択ロジックが `scripts/gates/pre-commit-gate.sh:24-76` と `scripts/gates/pre-red-gate.sh:21-73` に約49行重複。実測 diff（pre-commit 26-76 vs pre-red 23-73）は**1行のみ相違**（no-active-cycle BLOCK メッセージ、意図的な gate 別文言）。片側修正漏れを検知するテストがない（skills 7ファイル側には test-phase-gate.sh の check_selection_snippet が存在するのと非対称）。
3. **section_grep helper が ERE 解釈のまま**: `tests/test-codify-rule-docs.sh:220-229` の awk `$0 ~ "^## " h` は heading 引数を動的 regex として解釈する。

## Baseline（実測、live tree @ main 3c02fa5 clean、plan より転記）

```
codify-rule-docs rc=0 / phase-gate rc=0 / rules-mirror rc=0 / pre-commit-gate rc=0 / pre-red-gate rc=0
```

前 cycle 20260706_1020 COMMIT 時 full suite: 112/112 全 rc=0。orchestrate Block 0 で snapshot 隔離 full baseline を再実測する（rules/plan-discipline.md 準拠）。

## 逆向き契約 sweep（実測 grep literal 貼付、plan より転記）

- `grep -rn "\b112\b" tests/*.sh docs/STATUS.md` → tests/test-codify-insight.sh TC-19（`Test Scripts | 112` pin）+ docs/STATUS.md:12。**本 cycle は新規テストファイルを作らない**（既存2ファイルへの TC 追加のみ）ため count 112 は不変。bump 不要
- `grep -rn "No active Cycle doc found" tests/` → tests/test-pre-commit-gate.sh:313,374,434（コメント/期待メッセージ）。drift guard はこの1行を除外して diff するため無衝突
- section_grep 全 call site sweep: heading 引数10種・literal 引数全てに ERE メタ文字**0件**（`grep -oP ... | grep -E '[][(){}+.*^$|?\\]'` rc=1）→ fixed-string 化は既存~55 call site に対して非破壊
- 追記 literal の pre-existing count（全て0を実測確認）: doc-mutations.md「区間限定」「全文一括置換」「行頭アンカー」「20260703_2035」、test-patterns.md「ERE メタ文字」「短縮見出し」「fixed-string」「前方一致」「20260703_2035」

## 設計（plan より転記）

### A. rule 追記内容（rules/ と .claude/rules/ に同一適用）

**doc-mutations.md** 新 H2（「SSOT 即時同期」と「Cycle 参照 format」の間）:

```markdown
## Frontmatter 遷移の区間限定編集 (cycle 20260703_2035 #1)

frontmatter の状態遷移（phase / retro_status / updated）は frontmatter 区間限定で編集する:

- **禁止**: 全文一括置換（whole-file str.replace / sed 全域置換）での frontmatter 遷移。本文中の記録的言及（Progress Log の「retro_status: none」等）を巻き込み、commit 済み本文の無言書き換えを生む
- **正しい対応**: 行頭アンカー + count=1 の範囲限定置換（re.MULTILINE の `^...$` 一致）、または awk 区間抽出で frontmatter のみを対象にする
- 根拠: cycle doc は「状態」と「状態についての記録」が同居する文書。状態遷移操作は構造を認識して行う
```

出典追記: `- cycle 20260703_2035 #1 — frontmatter 遷移の区間限定編集（全文一括置換の本文汚染）`

**test-patterns.md**:

- 禁止事項末尾: `- **section_grep へ ERE メタ文字を含む見出しを渡す**: heading 引数が awk 動的 regex として解釈される実装では、丸括弧・+・. を含むフル見出しが silent no-match（count=0）になる (cycle 20260703_2035 #2)`
- 推奨末尾: `- section_grep の heading はメタ文字を含まない短縮見出し（前方一致）で渡す。helper 自体は fixed-string 比較（awk index() の prefix 判定）にして ERE 解釈を排除する (cycle 20260703_2035 #2)`
- 出典追記: `- cycle 20260703_2035 #2 — section_grep heading の ERE 解釈と fixed-string 化`

### B. section_grep fixed-string 化（rule の実装本体）

```awk
index($0, "## " h) == 1 {in_sec=1; next}
```

前方一致セマンティクス（`^## ` + heading prefix）は現行と同一、ERE 解釈のみ排除。heading/literal 引数のメタ文字0件実測により既存38 TC は無影響（GREEN で41/41実証）。

### C. #148 drift guard（issue 対応案(1)を採用）

- **採用**: TC-24 as inverse contract — 構造アンカー抽出 + 既知差分除外 diff
  - 抽出: `# $1 is polymorphic` コメント行（pre-commit:28 / pre-red:25 に存在実測済み）から最初の行頭 `fi`（pre-commit:76 / pre-red:73 に存在実測済み）まで。行番号 hardcode はしない（アンカーパターン抽出）
  - 抽出結果の行数 >= 40 を各々 assert（アンカー失敗の silent no-match 防御、rules/test-patterns.md「分岐×出力 assert」準拠）
  - `grep -vF 'BLOCK: No active Cycle doc found'` で既知の意図的1行差分を除外して diff → 空を assert
- **不採用（記録）**: 共有 lib 化（案(2)）は rules/multi-file-consistency.md「gate script は単体で full validation を完了できる設計」と衝突するため reject。#148 LOW 項目（Active Cycle echo 分岐重複集約）は scope 外として defer（issue コメントに記録）
- 本 cycle で #148 close（Closes #148）

## Test List

### TODO
(none)

### WIP
(none — 全項目 GREEN で DONE へ遷移)

### DISCOVERED
(none)

### DONE
- [x] TC-39 (codify-rule-docs): Given rules/doc-mutations.md, When section_grep「Frontmatter 遷移の区間限定編集」×「全文一括置換」+ 出典×「20260703_2035」, Then 各 count >= 1 [RED 時: FAIL（追記前）] — RED 実測: FAIL（想定通り）— GREEN 実測: PASS（rule 追記後、41/41 中の1件、rc=0）
- [x] TC-40 (codify-rule-docs): Given rules/test-patterns.md, When 禁止事項×「ERE メタ文字」+ 推奨×「短縮見出し」+ 出典×「20260703_2035」, Then 各 count >= 1 [RED 時: FAIL（追記前）] — RED 実測: FAIL（想定通り）— GREEN 実測: PASS（rule 追記後、41/41 中の1件、rc=0）
- [x] TC-41 (codify-rule-docs): Given rules/agent-prompts.md（既存・無変更）, When section_grep をフル括弧見出し「並列起動時の prompt 契約 (3+ subagent fan-out)」×「担当範囲」で呼ぶ, Then count >= 1 [RED 時: FAIL（ERE 解釈では count=0 — fix の回帰契約）] — RED 実測: FAIL（想定通り、pre-existing count=0 事前実測と一致）— GREEN 実測: PASS（section_grep fixed-string 化後、41/41 中の1件、rc=0）
- [x] TC-24 (phase-gate): Given 両 gate script, When アンカー抽出（>=40行 assert）→ 既知1行除外 → diff, Then diff 空 [RED 時: PASS（invariant 契約。RED では fixture 複製に1行変異を注入し FAIL することを Stage 3.5 で自己証明）] — RED 実測: PASS（invariant 契約通り）。Stage 3.5 自己証明: (a) 実 repo 抽出 → diff 空 → PASS、(b) mktemp fixture（pre-commit-gate.sh 複製、選択ロジック内 `sort | tail -1` → `sort | head -1` に1行変異）→ 同ロジック孤立実行で diff 非空 → FAIL を確認 — GREEN でも無変更のまま PASS 維持（25/25 中の1件、rc=0）
- [x] TC-M (meta-doc-consistency 既存 TC-01〜03): Given fixture（非 git dir）, When subject を BASE_DIR override で実行, Then Summary まで到達し abort しない [RED/事前状態: FAIL（TC-16 rc ガード dead code）] — GREEN: tests/test-doc-consistency.sh TC-16 の rc 取得を `tracked_rc=0; tracked=$(...) || tracked_rc=$?` 形式に修正 → test-meta-doc-consistency.sh 4/4 PASS（rc=0）で実証

mirror 同期は既存 test-rules-mirror.sh TC-01（byte-identical diff）が保証するため、新 TC は rules/ 側のみ検査（TC-11 以降の既存 convention 準拠）。

## Implementation Notes

### Goal
v2.12 最初のサイクル。メモリの再開ポインタ（codify実装 → #148）の先頭2項目を1 cycle に統合する。

### Background
統合根拠: 20260703_2035 Insight 2 の Codify Decision 自身が「helper の fixed-string 化は #148 と同時が効率的」と明記している。codified rule 2件が未実装のまま次サイクルに持ち越されており、#148 の gate drift guard 欠如も同時に解消することで section_grep helper の改修（fixed-string 化）を1回の変更で両方に活かす。

### Design Approach
RED で TC-39/TC-40（rule 追記2件の pin）+ TC-41（section_grep フル見出し回帰契約、fix 前は FAIL）+ TC-24（#148 drift guard、invariant 契約のため fixture 変異注入で自己証明）を追加。GREEN で rules/doc-mutations.md・rules/test-patterns.md（+ .claude/rules mirror）へ追記し、section_grep を fixed-string 化（`index($0, "## " h) == 1`）。REVIEW 前に self-apply checklist（frontmatter 遷移の区間限定編集・新 TC の短縮見出し使用・全成果物への rule checklist 適用）を実施する。

## Verification（integration-verification 準拠、real-path invocation 含む）

```bash
bash tests/test-codify-rule-docs.sh; echo rc=$?          # 41/41 期待
bash tests/test-phase-gate.sh; echo rc=$?                # TC-24 含め全 PASS 期待
bash tests/test-rules-mirror.sh; echo rc=$?              # mirror byte-identical 維持
bash scripts/gates/pre-red-gate.sh <本 cycle doc パス> || true      # real-path gate 実行
bash scripts/gates/pre-commit-gate.sh <本 cycle doc パス> || true   # REVIEW 前は BLOCK が正常
```

Evidence: (orchestrate が自動記入)

**新 rule cycle の self-apply checklist**（rules/integration-verification.md 準拠、REVIEW 前に実行）:
1. 本 cycle の frontmatter 遷移操作（sync-plan/commit）を区間限定編集で行ったか
2. 新 TC の section_grep 呼び出しが短縮見出しのみか（TC-41 の意図的フル見出しを除く — fixed-string 化後は安全であることの証明が目的）
3. 追記 rule を全成果物（テスト・doc）へ checklist 適用したか

**PLAN REVIEW F4/F5 反映版（Block 2c.5 はこちらを正とする — rc 明示 + full suite 追加。advisory 性質は維持し非ゼロ rc でも cycle は block しない）**:

```bash
bash tests/test-codify-rule-docs.sh; echo "codify-rule-docs rc=$? (expected 0, 41/41)"
bash tests/test-phase-gate.sh; echo "phase-gate rc=$? (expected 0, TC-24 含む)"
bash tests/test-rules-mirror.sh; echo "rules-mirror rc=$? (expected 0, byte-identical 維持)"
bash scripts/gates/pre-red-gate.sh docs/cycles/20260706_1216_codify-rules-impl-and-gate-drift-guard.md; echo "pre-red-gate rc=$? (real-path 実行、rc を記録)"
bash scripts/gates/pre-commit-gate.sh docs/cycles/20260706_1216_codify-rules-impl-and-gate-drift-guard.md; echo "pre-commit-gate rc=$? (expected 1: REVIEW 前は BLOCK が正常)"
# full suite（snapshot 隔離複製上で実行し、Block 0 baseline と diff — 空 = 回帰ゼロ）
# for f in tests/test-*.sh; do bash "$f" >/dev/null 2>&1; printf "%s rc=%d\n" "$(basename "$f")" "$?"; done | sort > final.txt; diff baseline-codify148.txt final.txt
```

## Upstream References

- ROADMAP v2.12 バックログ先頭2項目（codify 実装、#148）に一致
- rules/multi-file-consistency.md（gate 単体 full validation）→ 共有 lib 案 reject の根拠
- rules/state-ownership.md / doc-mutations.md → 追記位置・APPEND-ONLY 遵守

## 注記

作業ツリーに `docs/cycles/20260706_1020_phase-lifecycle-completion-gate.md` の未 staged 変更あり（別 cycle の codify gate 処理結果）。本 cycle の Files to Change に含まれないため触れない。

orchestrate Block 0 の期待動作（本 plan の scope 外だが自動発生）: 20260706_1020 の captured retro を codify gate が triage する（Insight 1: 否定形前提の grep 根拠必須 / Insight 2: multi-mode 契約 pin — 後者は TC-14a/b/c で実装済みのため no-codify または既 codified 追認が妥当）。triage 結果が新たな codified を生んでも本 cycle の Files to Change には追加しない（次 cycle 送り）。

## Progress Log

### 2026-07-06 12:16 - KICKOFF
- Cycle doc created from approved plan (/Users/morodomi/.claude/plans/gentle-stirring-hopper.md)
- Scope definition ready
- Phase completed

### 2026-07-06 12:30 - PLAN REVIEW (Codex competitive)
- 判定: **WARN 5**（BLOCK なし）。codex_session_id: 019f3573-1ba3-7040-a140-58b97fb1c0d3 を frontmatter に記録
- Codex 確認事項: section_grep の ERE 問題・codified rule 2 件・gate 49 行重複と既知差分 1 行は現物と一致。対象 baseline（codify-rule-docs 38/38 / phase-gate 24/24 / rules-mirror 3/3）PASS 確認
- triage（accept-apply 3 / accept-defer 1 / clarification 1）:
  - **F1（live tree clean 記載 vs 現状 dirty）**: clarification。plan の baseline 実測は approve 前の clean @ 3c02fa5 時点で正確。現在の dirty は Block 0 codify gate の処理結果（20260706_1020 の resolved 遷移 + Codify Decisions 追記、KICKOFF 注記済み）+ 本 cycle doc。plan は IMMUTABLE のため本 log を SSOT とする
  - **F2（ROADMAP 上 #148 は「v2.12 以降候補」）**: accept-apply（記載訂正）。「ROADMAP v2.12 バックログ先頭 2 項目」は正確には「メモリ再開ポインタ（ボード優先順）の先頭 2 項目。ROADMAP 上は v2.12 以降候補として整合」。scope への影響なし
  - **F3（test-phase-gate.sh の TC-09 重複ラベル）**: accept-defer。実測確認済み（L121 green Progress Log 用と L330 selection snippet 用で TC-09 が二重使用、加えて L3 header は TC-22 止まり）。既存 TC の renumber は Files to Change の範囲（TC-24 追加 + header 1 行）を越えるため DISCOVERED へ（Block 2e で issue 起票）
  - **F4（Verification の `|| true` が rc を潰す）**: accept-apply。Verification section 末尾に rc 明示版を追記（Block 2c.5 はそちらを正とする）。integration-verification rule の advisory 性質（非ゼロ rc でも block しない）は維持
  - **F5（final verification に full suite 明示なし）**: accept-apply。F4 反映版に full suite + baseline diff を追加
- **Block 0 baseline 実測の注記**: 初回 snapshot baseline（12:20 開始）は 5 件 rc=1 を報告したが、live tree 個別再実行で全 PASS を確認。原因は Codex plan review が並行して live tree 上でテストを実行したことによる衝突と推定（「読み取り並列・実行直列」原則の違反 — PdM が codex exec プロンプトにテスト実行禁止を明示しなかった委譲ミス。rules/agent-prompts.md「テスト実行可否の明示」の適用漏れ）。直列で baseline を再実測し、その結果を正とする（scratchpad/baseline-codify148.txt）
- 判定: Block 2a (RED) へ（baseline 再実測完了を待って開始）

### 2026-07-06 12:50 - BLOCK 0 BASELINE 完了（前エントリの推定訂正 + scope +1）

**訂正（APPEND-ONLY、前エントリ「Codex 並行実行衝突」推定は誤り）**: 直列再実測でも同一 5 件が FAIL し、並行衝突説は棄却。切り分けの結果、真因は 2 つ:

1. **snapshot 手法の欠陥（4 件の原因）**: `cp -R . $SNAP` は repo 単体複製のため、`tests/test-paradigm-selection.sh:16` の `HOLDINGS_DOC="$(cd "$BASE_DIR/../.." && pwd)/docs/test_architecture.md"`（repo 外依存）が解決不能 → TC-04 FAIL。残り 3 件（doc-consistency TC-13 / factory-model / skip-criteria TC-05）は paradigm-selection を nested 実行するカスケード。**対策**: snapshot は親構造ごと複製（`$SNAP/MorodomiHoldings/docs` + `$SNAP/MorodomiHoldings/agents/dev-crew`）。live tree 個別実行が「PASS」だったのは repo 外依存が本物のパスで解決できたため
2. **test-meta-doc-consistency の pre-existing FAIL（1 件、環境非依存）**: subject の `tests/test-doc-consistency.sh:155-156` TC-16 `tracked=$(git -C "$BASE_DIR" ls-files 2>/dev/null); tracked_rc=$?` が `set -euo pipefail` 下で dead code — fixture（非 git dir）で git rc=128 → set -e が rc ガード到達前に script を abort し、meta test TC-01〜03 の「Summary 到達」assert が FAIL。`git log -L` で **導入 commit db67871（2026-07-03、cycle 20260703_1215）から存在**を確認。皮肉にも「rc を `|| rc=$?` で受ける」rule (test-patterns.md、cycle 20260703_1215 #3) を codify した同一 cycle の成果物が同 rule に違反。HEAD の git archive snapshot でも再現し、本 cycle の変更とは無関係の真の pre-existing FAIL

**確定 baseline（Holdings 構造複製 snapshot、直列実行）**: 111/112 rc=0、`test-meta-doc-consistency.sh rc=1` のみ FAIL（scratchpad/baseline-codify148.txt）。過去 cycle の「112/112 全 rc=0」報告は 2026-07-03 以降 meta-doc-consistency について再現不能（当時 evidence は消失済みのため追及不能、本 cycle は実測を正とする）

**scope +1（plan-discipline「pre-existing FAIL は 1 行 fix 可能なら先送りしない」+ SSOT 即時同期）**:

#### Files to Change 拡張（GREEN はこれを正とする）
9. `tests/test-doc-consistency.sh` — TC-16 の rc 取得を `tracked_rc=0; tracked=$(git -C "$BASE_DIR" ls-files 2>/dev/null) || tracked_rc=$?` 形式に修正（2 行、本 cycle が実装する test-patterns rule「変数に受けて rc 直後検査」の適用そのもの）

#### Test List 追加（既存 FAIL を GREEN 化する項目、red-first は既に自然成立 — meta-doc TC-01〜03 が現に FAIL 中）
- [ ] TC-M (meta-doc-consistency 既存 TC-01〜03): Given fixture（非 git dir）, When subject を BASE_DIR override で実行, Then Summary まで到達し abort しない [現状: FAIL（TC-16 rc ガード dead code）]

---

### 2026-07-06 13:10 - RED

**担当範囲**: tests/test-codify-rule-docs.sh（TC-39/TC-40/TC-41 追加。section_grep helper 本体は無変更 — fixed-string 化は GREEN scope）、tests/test-phase-gate.sh（TC-24 追加 + L3 header コメント `TC-01 ~ TC-22` → `TC-01 ~ TC-24`）

**事前実測（Stage 3.5 事前必須、確定前 pre-existing count = 0 を再確認）**:
```
TC-39a doc-mutations Frontmatter見出し x 全文一括置換: 0
TC-39b doc-mutations 出典 x 20260703_2035: 0
TC-40a test-patterns 禁止事項 x ERE メタ文字: 0
TC-40b test-patterns 推奨 x 短縮見出し: 0
TC-40c test-patterns 出典 x 20260703_2035: 0
TC-41 agent-prompts フル括弧見出し x 担当範囲: 0
```
Cycle doc 逆向き契約 sweep の PdM 実測値（全 literal pre-existing count=0）と一致。

**test-codify-rule-docs.sh 実行結果**: `PASS: 38 / FAIL: 3 / TOTAL: 41`, rc=1
- TC-01〜38: 全 PASS（既存 convention 無破壊）
- TC-39/TC-40/TC-41: 全 FAIL（想定通り — rule 未追記 / section_grep 未 fixed-string 化のため）

**test-phase-gate.sh 実行結果**: `PASS: 25 / FAIL: 0 / TOTAL: 25`, rc=0
- TC-24 は invariant 契約のため RED 時点でも PASS（gate script 2 本のアンカー抽出が各 49 行、既知1行除外後 diff 空）

**TC-24 Stage 3.5 自己証明**（scratchpad/tc24-selfproof、gate 本体は無変更・fixture のみ変異）:
- (a) 実 repo: `awk '/# \$1 is polymorphic/,/^fi$/'` 抽出 → pre-commit-gate.sh 49行 / pre-red-gate.sh 49行 → 既知1行除外後 diff 空 → **PASS**
- (b) mktemp 複製 fixture（pre-commit-gate.sh を複製し選択ロジック内 `ACTIVE_CYCLE=$(printf '%s' "$candidates" | sort | tail -1 | cut -f2)` を `sort | head -1` に1行変異）→ 同抽出+diff ロジックを孤立実行 → diff 非空（変異行を検出）→ **FAIL**
- 結論: drift guard は実際に drift を検出できることを実証済み

**想定外事象**: なし。Stage 3.5 事前実測・自己証明ともに設計通りの結果（fixed-string 化前の section_grep が TC-41 で ERE 解釈により count=0 になる回帰契約が事前確認と一致、TC-24 の mutation 検出も想定通り機能）

**フェーズ完了**: RED Phase completed. Test List TODO → WIP 遷移済み（frontmatter phase: RED、区間限定編集で更新）

---

### 2026-07-06 13:45 - GREEN

**担当範囲（Files to Change #1-6 + #9 の GREEN worker 委譲分）**:
1. `rules/doc-mutations.md` — 新 H2「Frontmatter 遷移の区間限定編集 (cycle 20260703_2035 #1)」を「SSOT 即時同期」と「Cycle 参照 format」の間に追加 + 出典1行追記
2. `.claude/rules/doc-mutations.md` — 1 と byte-identical mirror（同一編集）
3. `rules/test-patterns.md` — 禁止事項末尾に ERE メタ文字 bullet、推奨末尾に短縮見出し bullet、出典末尾に 20260703_2035 #2 追記
4. `.claude/rules/test-patterns.md` — 3 と byte-identical mirror（同一編集）
5. `tests/test-codify-rule-docs.sh` — section_grep を fixed-string 化（`$0 ~ "^## " h` → `index($0, "## " h) == 1`）、L219 usage コメントの `heading_regex` → `heading_prefix (fixed-string)` に更新（TC-39/40/41 本体は RED 成果物のため無変更）
6. `tests/test-phase-gate.sh` — 無変更（TC-24 + header コメントは RED で追加済み、GREEN での追加編集なし）
9. `tests/test-doc-consistency.sh` — TC-16 の rc 取得を `tracked_rc=0` 初期化 + `tracked=$(git -C "$BASE_DIR" ls-files 2>/dev/null) || tracked_rc=$?` 形式に修正（`set -euo pipefail` 下で従来の `$(cmd); rc=$?` 並置が dead code だった問題を解消。rules/test-patterns.md「rc 記録パターン」の適用そのもの）

**確認結果（個別実行、rc 全量）**:
```
codify-rule-docs.sh rc=0 (PASS: 41 / FAIL: 0 / TOTAL: 41)
phase-gate.sh rc=0 (PASS: 25 / FAIL: 0 / TOTAL: 25)
rules-mirror.sh rc=0 (PASS: 3 / FAIL: 0)
pre-commit-gate.sh rc=0 (PASS: 14 / FAIL: 0)
pre-red-gate.sh rc=0 (PASS: 9 / FAIL: 0)
test-meta-doc-consistency.sh rc=0 (PASS: 4 / FAIL: 0) — TC-16 fix の GREEN 実証
diff rules/doc-mutations.md .claude/rules/doc-mutations.md → 空（rc=0）
diff rules/test-patterns.md .claude/rules/test-patterns.md → 空（rc=0）
bash -n tests/test-doc-consistency.sh → rc=0（単体実行禁止のため syntax check のみ）
```

**想定外事象（1件、TC-16 fix の副作用として発見・解決済み）**: test-meta-doc-consistency.sh の TC-04（「実 repo で subject 実行」）が初回 timeout 180s で rc=124（未完了）になった。原因切り分け: TC-16 修正前は `set -euo pipefail` 下で dead code バグにより TC-16 到達時に script が abort し、TC-13（「全 test-*.sh を nested 実行して regression 確認」ループ、tests/test-doc-consistency.sh:266-282）に到達せずスキップされていた。TC-16 fix で abort しなくなった結果、TC-13 が初めて実際に動作し、他 38 test file を serial 実行するため所要時間が大幅に増加した（rule 修正のバグではなく、修正によって隠れていた既存動作が顕在化）。timeout を 550s に延長して再実行し rc=0 / PASS 4/4 を確認。無限ループではないことを確定。orchestrate 側で以後 test-meta-doc-consistency.sh を実行する際はこの所要時間（数分オーダー）を考慮すること

**フェーズ完了**: GREEN Phase completed. Test List WIP → DONE 遷移済み（TC-39/TC-40/TC-41/TC-24/TC-M）。frontmatter phase: GREEN、区間限定編集で更新

### 2026-07-06 13:25 - REFACTOR + SELF-APPLY (PdM)

**timestamp 注記**: 直前 GREEN エントリの「13:45」は green-worker の時刻推定によるもので、実時刻（date 実測）では GREEN 完了は ~13:20、本 REFACTOR は 13:25。以後のフェーズ実行者は `date` 実測で記録すること（retro 候補）

- チェックリスト 7 項目実行: 重複コード（TC-24 は単一ブロック + 並列 awk 抽出 2 回で共通化不要 / TC-39〜41 は既存 per-TC convention 準拠）・定数化（gate パスは変数化済み）・未使用 import / let→const / メソッド分割 / N+1（bash/doc のため N/A）・命名一貫性（準拠）— **全項目改善不要、構造的リファクタなし（no-op）**
- Verification Gate: codify-rule-docs rc=0 / phase-gate rc=0 / rules-mirror rc=0 / doc-consistency syntax OK
- **self-apply checklist（integration-verification「新 rule cycle は全成果物へ checklist 適用」）**:
  1. frontmatter 遷移の区間限定編集 — PdM の codify gate 処理（20260706_1020）・本 doc の phase/updated 遷移とも周辺行コンテキスト付き unique match で実施（準拠）
  2. 新 TC の section_grep heading — TC-39/40 は短縮見出し、TC-41 のみ意図的フル括弧見出し（fixed-string 化の回帰契約として設計どおり）。heading 引数 sweep で確認済み（準拠）
  3. 追記 rule の全成果物適用 — TC-16 fix が「変数に受けて rc 直後検査」rule の適用そのもの。TC-24 の rc 取得も `|| true` 吸収 + 出力 assert 形式で test-patterns 準拠
- Phase completed

### 2026-07-06 15:00 - VERIFY (Product Verification, Block 2c.5)

- Evidence: /tmp/dev-crew-verify-20260706_1216/verify.log + scratchpad/final-codify148.txt
- 単体: codify-rule-docs rc=0（41/41）/ phase-gate rc=0（25/25、TC-24 含む）/ rules-mirror rc=0
- real-path: pre-red-gate 明示指定 rc=0（PASS）/ pre-commit-gate 明示指定 rc=1（REVIEW 前 BLOCK、期待どおりの正常動作）
- full suite（Holdings 構造複製 snapshot、直列）: 111/112。baseline との diff は 2 行 — meta-doc-consistency rc=1→0（TC-16 fix による意図した改善）、**doc-consistency rc=0→1（要調査）**
- doc-consistency の隔離単独再実行では 12/12 PASS（rc=0）— full-suite 文脈でのみ失敗する flaky 挙動で、既知 issue #144 と同型。TC-13（全 110 テストの nested 実行）内のどのテストが落ちたかを特定するため、doc-consistency 出力を捕捉する full suite を再実行中（結果は後続エントリに記録）
- Phase completed（doc-consistency flake は #144 系として追跡、COMMIT 前の最終 full suite で再判定）

### 2026-07-06 15:54 - REVIEW (Codex competitive + 4 Claude reviewers, HIGH tier)

- **リスクスコア**: risk-classifier.sh 実測 **HIGH 85**（plan 見積 LOW 20 と乖離）。内訳に diff 内容シグナルの FP を含む（case-insensitive `UPDATE|DELETE` が Markdown の `updated:`/`deleted` 頻出語に +25 で反応、+20 行数 +15 file count +15 dir spread +10 tests）。決定論的 gate の判定に従い HIGH tier（Codex + correctness + security + maintainability + design の 5 view）で実施。classifier の doc-diff FP は DISCOVERED へ
- 判定: Codex **WARN 3** / correctness **WARN（MED 1）** / security **PASS** / maintainability **WARN 2 + nit 1** / design **WARN 1**（BLOCK ゼロ）
- 全レビュアーに「テスト実行禁止・静的レビューのみ」を prompt で明示（agent-prompts「テスト実行可否」契約の適用。Codex も遵守を宣言）
- triage（accept-apply 5 / accept-defer 2 / reject 1 / 既記録 1）:
  1. **correctness MED（doc-consistency L160 裸代入）**: accept-apply。TC-16 fix と同型のハザードが隣接行に残存（fix により初めて到達可能になった経路）。`|| targets=""` を適用し、printf oracle で「全除外 → target_count=0 → FAIL 分岐到達」を実証（reviewer 提供の再現 oracle + 適用後 oracle 両方確認）
  2. **Codex W1（test_count 4→5 stale）**: accept-apply。TC-M 追加（scope +1）を RED が frontmatter に反映し損ねた遷移漏れの訂正。区間限定編集で 5 に更新
  3. **Codex W2（20260706_1020 の diff 混入 vs「触れない」記載）**: accept-apply（記載明確化）。同 doc の変更は本 orchestrate Block 0 codify gate の処理結果であり、**commit に同梱する**（前 cycle までの codify gate 出力同梱 precedent に従う）。Files to Change 拡張: 10. `docs/cycles/20260706_1020_phase-lifecycle-completion-gate.md`（Block 0 codify gate 出力、retro_status: resolved + Codify Decisions 追記）
  4. **Codex W3（TC-09 重複ラベル）**: PLAN REVIEW F3 で DISCOVERED 済み（重複記録しない）
  5. **maint M1（区間限定 vs 範囲限定の揺れ）**: accept-apply。新設 section 内の 1 箇所「範囲限定置換」→「区間限定置換」に統一（mirror 同期、rules-mirror rc=0 確認）。既存 rule の「範囲限定」（grep/parse 文脈）は rename しない — 編集文脈の用語は origin insight の「区間限定」を正とする
  6. **maint M2（TC-41 コメント時制 stale）**: accept-apply。「現行 ERE 実装」→「旧 ERE 実装」+ 現在形の記述に修正（GREEN 完了後の実装と整合）
  7. **maint nit（TC-24 の閾値 40 重複）**: reject。2 箇所の literal は既存テストスタイルの許容範囲、定数抽出は可読性向上が僅少
  8. **design D1（test-rule-agent-prompts-parallel-clause.sh:39 の同型 ERE 脆弱 helper）**: accept-defer → DISCOVERED。現行呼び出しはメタ文字なしで active bug ではないが、本 cycle が codify した bug class の残存 duplicate。issue 起票して次 cycle へ
- 適用後検証: codify-rule-docs rc=0 / rules-mirror rc=0 / doc-consistency `bash -n` OK / 追跡ラベル契約 grep rc=1（clean）/ L160 oracle 到達確認
- Phase completed

## DISCOVERED

- [x] D1: test-rule-agent-prompts-parallel-clause.sh:39-42 の section 抽出 helper が section_grep 旧実装と同型の ERE 脆弱パターン（heading を awk 動的 regex 解釈）。現行呼び出しは安全だが bug class が残存（design reviewer 検出）→ issue #162 起票済み
- [x] D2: tests/test-phase-gate.sh の TC-09 ラベル二重使用（L121 Progress Log 用 / L330 selection snippet 用）+ 番号体系整理（PLAN REVIEW F3、Codex W3 再指摘）→ issue #163 起票済み
- [x] D3: skills/review/risk-classifier.sh の diff 内容シグナルが Markdown 主体 diff で FP（case-insensitive `UPDATE|DELETE` が `updated:` 等に反応、+25）。doc-only cycle でスコアが常時過大 → issue #164 起票済み
- [x] D4: doc-consistency が full-suite 文脈でのみ rc=1 になる flaky 挙動（隔離単独では 12/12 PASS）。捕捉付き full-suite 再実行では 112/112 全 rc=0 で**再現せず** — 非決定的 flake として #144 と同群。#144 にコメント追記済み（2026-07-06）
- 補記: #148 の LOW 項目 defer は issue #148 にコメント済み（2026-07-06）
- [ ] D5: subagent worker のフェーズ timestamp 推定記載（GREEN が実時刻 13:20 頃に「13:45」を記載、前 cycle でも同様）。フェーズ記録は `date` 実測を必須化する prompt 契約が必要 → retro で扱う

## Next Steps

1. [Done] KICKOFF
2. [Done] RED
3. [Done] GREEN
4. [Done] REFACTOR
5. [Done] VERIFY + REVIEW <- Current
6. [Next] DISCOVERED 起票 + RETROSPECTIVE
7. [ ] COMMIT
8. [ ] DONE

### 2026-07-06 16:10 - FINAL VERIFY（レビュー修正込み最終 full suite）

- **112/112 全 rc=0**（Holdings 構造複製 snapshot、直列実行、scratchpad/final3-codify148.txt + /tmp/dev-crew-verify-20260706_1216/）
- baseline との diff: `test-meta-doc-consistency.sh rc=1→0` の 1 行のみ = TC-16 fix による意図した改善。**回帰ゼロ**
- D4 flake は捕捉付き再実行（112/112 rc=0）でも再現せず、#144 にコメント記録済み
- COMMIT へ

## Retrospective

抽出時刻: 2026-07-06 15:58
抽出方法: Cycle doc 全体（baseline 5 件 FAIL の誤診→再診 / TC-16 dead code の連鎖 / REVIEW 8 findings）からの失敗→最終解→insight ペア抽出

### Insight 1: snapshot baseline は repo 外依存を含む親構造ごと複製する。同時多発 FAIL は単一根本原因の cascade を疑う
- **Failure**: `cp -R . $SNAP` の repo 単体 snapshot で baseline を取ったところ 5 件 rc=1。第一診断は「Codex plan review の並行テスト実行との衝突」（もっともらしいが誤り — 直列再実行でも再現した）。真因は test-paradigm-selection.sh:16 の `$BASE_DIR/../../docs`（Holdings 親）依存が snapshot で解決不能になったこと。残り 4 件は同テストを nested 実行するカスケードだった
- **Final fix**: snapshot を親構造ごと複製（`$SNAP/MorodomiHoldings/docs` + `$SNAP/MorodomiHoldings/agents/dev-crew`）→ 111/112 に収束（残 1 件は独立の真の pre-existing FAIL）
- **Insight**: **(a) 隔離 snapshot は `grep -rn '\.\./\.\.' tests/` で repo 外依存を先に洗い、依存する親構造ごと複製する。(b) N 件同時 FAIL は N 個の独立バグではなく単一根本原因の nested cascade をまず疑い、nested 実行グラフ（どのテストがどれを呼ぶか）で切り分ける。(c) 「もっともらしい第一仮説」（並行衝突）は棄却実験（直列再実行）を経てから採用する**
- **一般化**: plan-discipline.md「baseline snapshot 隔離」rule の複製範囲補強候補

### Insight 2: set -e 下の裸 command-substitution 代入は file 内同型 sweep とセットで直す。dead code を蘇生させる fix は「初めて到達可能になる経路」の再検査必須
- **Failure**: TC-16 の `tracked=$(git ...)` が set -e で rc ガード到達前に abort する dead code を 2 行 fix した（導入 commit db67871 から 3 日間、fixture 文脈の meta-doc-consistency を FAIL させ続けた pre-existing bug。皮肉にも `|| rc=$?` rule を codify した同一 cycle の成果物が同 rule に違反していた）。しかし fix 直後の REVIEW で correctness reviewer が **1 行隣（L160）の同型裸代入**を検出 — TC-16 fix により初めて到達可能になった経路に同 class のハザードが残存していた。さらに fix の副作用で、abort により実行されていなかった TC-13（nested 全 110 テスト実行）が fixture 文脈で「蘇生」し、meta-doc の所要時間が数分オーダーに増加した
- **Final fix**: L160 に `|| targets=""` を適用し printf oracle で全除外ケースの到達を実証。所要時間増は実測値として記録
- **Insight**: **(a) set -e 環境で裸の `var=$(cmd)` を 1 箇所直す時は、同ファイル内の全 `$(...)` 代入を同型 sweep してから閉じる（1 箇所の fix は隣の同型を「次に踏まれる地雷」に変える）。(b) dead code だった検証ロジックを蘇生させる fix は、蘇生した経路の実行時間・副作用・下流の未検証コードを再検査する — 「動いていなかったコードが動き出す」は機能追加と同じ検証重量で扱う**
- **一般化**: test-patterns.md 追記候補（同型 sweep の義務化）

### Insight 3: 委譲 worker のフェーズ記録 timestamp は `date` 実測を prompt 契約に含める
- **Failure**: green-worker が Progress Log と frontmatter updated に「13:45」を記載したが実時刻は ~13:20（推定記載）。前 cycle 20260706_1020 でも updated: 14:10 と実時刻の乖離があり、PdM の後続編集（12:16）で updated が逆行する事態が発生。updated は gate の ACTIVE_CYCLE 選択キー（lexicographic tie-break）であり、逆行・未来値は選択の決定性を汚染し得る
- **Final fix**: REFACTOR エントリで実時刻系列を注記し、以後 PdM が date 実測で記録
- **Insight**: **フェーズ記録（Progress Log 見出し・frontmatter updated）の timestamp は `date "+%Y-%m-%d %H:%M"` の実測値のみ許可 — 委譲 prompt テンプレートの「完了時の義務」に実測コマンドを明記する**。LLM は「もっともらしい時刻」を推定生成する（timestamp 版 hallucination）
- **一般化**: agent-prompts.md「委譲 prompt テンプレート」追記候補（D5）

### 成功事例（observation）: FP 由来の HIGH tier review が真の findings を検出した
- risk-classifier の Markdown FP（#164）で LOW 想定 cycle が HIGH 85 判定になり 5 view review を実施した結果、correctness が L160 同型ハザード（fix 隣接の潜在バグ）、design が sibling ERE 脆弱 helper（#162）を検出。スコアの過大は「無駄コスト」ではなく本 cycle では実害検出に転じた。ただし classifier の FP 自体は decisiveness を損なうため #164 で是正する（review 厚みの決定は正しい入力に基づくべき）

### 2026-07-06 16:16 - COMMIT

- 最終 full suite: **112/112 全 rc=0**、baseline との diff は meta-doc-consistency rc=1→0（意図した改善）のみ = 回帰ゼロ（scratchpad/final3-codify148.txt）
- pre-commit-gate（明示指定）rc=0 PASS → commit skill 経由で phase: DONE へ遷移してから commit（Block 3 手順準拠、frontmatter は区間限定編集）
- STATUS.md: Completed 行追加、Done (unarchived) 62→63、Test Scripts 112 不変。README/AGENTS/CLAUDE は skills/・agents/ 無変更のため SKIP
- commit 同梱: 本 cycle 変更 8 ファイル + docs/cycles/20260706_1020（Block 0 codify gate 出力、REVIEW W2 で明記済み）+ STATUS.md
- feature branch → PR → merge（Closes #148）
- Phase completed
