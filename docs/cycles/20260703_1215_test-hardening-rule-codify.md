---
feature: test-hardening-rule-codify
cycle: 20260703_1215
phase: COMMIT
complexity: complex
test_count: 10
risk_level: medium
retro_status: captured
codex_session_id: ""
created: 2026-07-03 12:15
updated: 2026-07-03 16:00
---

# test hardening — codify 済み insight 9 件の rule/skill 実装 + inverse contract（#143）

## Scope Definition

### In Scope
- [ ] rules/test-patterns.md + .claude/rules/test-patterns.md: 禁止事項 A1（単体語 pin 禁止）+ 推奨 A1/A2/A3/A4 の 4 項目 + 出典 20260701_1120・20260702_1930
- [ ] rules/plan-discipline.md + .claude/rules/plan-discipline.md: 推奨 B（immutable snapshot 複製 + 並行プロセスから隔離）+ 出典 20260702_1200
- [ ] rules/agent-prompts.md + .claude/rules/agent-prompts.md: 並列起動時の prompt 契約節に C（読み取り並列・実行直列 + テスト実行可否の明示）+ 出典 20260702_1200
- [ ] rules/integration-verification.md + .claude/rules/integration-verification.md: 推奨に D（usage を実測確認してから記載）+ 出典 20260702_1200
- [ ] rules/multi-file-consistency.md + .claude/rules/multi-file-consistency.md: 推奨に E（enumerate-and-reject は位置＝信頼するディレクトリ境界も列挙）+ 出典 20260702_1930
- [ ] skills/red/SKILL.md: Stage 3 後に Stage 3.5「False-pass 自己証明」2-3 行 + reference.md link（100 行以内厳守）
- [ ] skills/red/reference.md: Stage 3.5 の手順詳細（新規 test literal を対象から除去 → count 0 / FAIL を実証する手順、A1/A2 の適用手順）
- [ ] tests/test-codify-rule-docs.sh: TC-28（A1+A2）、TC-29（A3+A4）、TC-30（B）、TC-31（C）、TC-32（D）、TC-33（E）— TC-27 テンプレート踏襲
- [ ] tests/test-doc-consistency.sh: TC-16 — live tree（docs/cycles・CHANGELOG.md・docs/decisions・docs/archive 除外）で `skills/(phase-compact|reload|strategy)` が 0 hit（inverse contract、#143）
- [ ] tests/test-phase-gate.sh: red/SKILL.md の新 step を contiguous phrase で pin する新 TC（次連番 TC-23、pre-existing count=0 を RED で実測して literal 確定）

### Out of Scope
- parallel スキルの削除/作り直し（Reason: #142、ユーザー確認待ち）
- #147（non-DONE doc の DONE 遷移）/ #148（gate 間 drift guard）/ #144（flaky 調査）（Reason: 本 cycle の rule-codify family と無関係）
- 20260702_1930 の成功事例 observation（perspective-diverse review）の rule 化（Reason: no-codify 判定済み。rules/review-triage.md 既存 tier 設計の実証であり新規 rule 化不要）

### Files to Change (target: 10 or less — 本 cycle は 3 source cycle + issue #143 の backlog を一括実装するため 16 file。Design Review Gate で over-target を important 判定・accept 済み。詳細は Progress Log 参照)
1. `rules/test-patterns.md` (edit)
2. `.claude/rules/test-patterns.md` (edit, mirror)
3. `rules/plan-discipline.md` (edit)
4. `.claude/rules/plan-discipline.md` (edit, mirror)
5. `rules/agent-prompts.md` (edit)
6. `.claude/rules/agent-prompts.md` (edit, mirror)
7. `rules/integration-verification.md` (edit)
8. `.claude/rules/integration-verification.md` (edit, mirror)
9. `rules/multi-file-consistency.md` (edit)
10. `.claude/rules/multi-file-consistency.md` (edit, mirror)
11. `skills/red/SKILL.md` (edit)
12. `skills/red/reference.md` (edit)
13. `tests/test-codify-rule-docs.sh` (edit, TC-28〜33 追加)
14. `tests/test-doc-consistency.sh` (edit, TC-16 追加)
15. `tests/test-phase-gate.sh` (edit, 新 TC 追加)
16. `docs/cycles/20260703_1215_test-hardening-rule-codify.md` (new, Cycle doc 自身)

## Environment

### Scope
- Layer: Documentation / Test contracts（実装コードなし、rule 追記・スキル定義・テストのみ）
- Plugin: dev-crew（bash/doc project、integration-verification.md の project type 分類に準拠）
- Risk: 40（WARN）

### Runtime
- Bash（テストスクリプト、macOS zsh 実行環境）、Markdown（rules/skills/docs）

### Dependencies (key packages)
- なし（新規依存追加なし。grep/sed/wc 等 標準 POSIX/GNU 互換ツールのみ）

### Risk Interview (BLOCK only)
- 該当なし（Risk 40 は WARN 帯であり BLOCK 帯（60+）未到達）

## Context & Dependencies

### Reference Documents
- `docs/cycles/20260701_1120_plan-discipline-green-sweep.md` - A1/A2（test-patterns.md）+ F（RED false-pass 自己証明、Insight 4 deferred:new-cycle）の出典
- `docs/cycles/20260702_1200_skill-inventory-cleanup.md` - B（plan-discipline.md）/ C（agent-prompts.md）/ D（integration-verification.md）の出典
- `docs/cycles/20260702_1930_gate-active-cycle-fix.md` - E（multi-file-consistency.md）/ A3・A4（test-patterns.md）の出典。Codify Decisions は本 cycle 冒頭の orchestrate Block 0 codify gate で triage 済み（retro_status: captured → resolved、2026-07-03 12:10）。3 insight 全て codified→rule、Destination は plan の想定（E→multi-file-consistency.md、A3/A4→test-patterns.md）と完全一致を確認
- `rules/test-patterns.md` / `rules/plan-discipline.md` / `rules/agent-prompts.md` / `rules/integration-verification.md` / `rules/multi-file-consistency.md` - 追記対象の既存 rule 5 件
- `skills/red/SKILL.md` / `skills/red/reference.md` - Stage 3.5 追加対象

### Dependent Features
- なし（rule/skill doc 追記のみ、他機能への実行時依存なし）

### Related Issues/PRs
- Issue #143: 削除スキル名の inverse contract テスト追加（stale-ref 検査）。20260702_1200 Codex code review F3（accept-defer）が起点。issue 本文で「20260701_1120 Codify Decisions と同一ファミリーであり同一 cycle での実装を推奨」と明記 — 本 cycle（G destination）で対応

## Test List

### TODO
- [ ] TC-09: Given rules/ と .claude/rules/, When test-rules-mirror.sh, Then byte-identical（既存 TC が自動検査。GREEN で mirror 実施後に検証）
- [ ] TC-10: Given 全 suite, When 一括実行, Then baseline-hardening.txt と diff が空（回帰ゼロ）

### WIP
(none)

### DISCOVERED
(none)

### DONE
- [x] TC-01: Given rules/test-patterns.md, When section_grep で A1/A2 の contiguous literal + 出典 20260701_1120 を検査, Then 各 count ≥1（tests/test-codify-rule-docs.sh TC-28、GREEN で rule 追記後 PASS 確認）
- [x] TC-02: Given rules/test-patterns.md, When A3/A4 literal + 出典 20260702_1930, Then count ≥1（TC-29、PASS 確認）
- [x] TC-03: Given rules/plan-discipline.md 推奨, When 「immutable snapshot 複製」系 literal + 出典 20260702_1200, Then count ≥1（TC-30、PASS 確認）
- [x] TC-04: Given rules/agent-prompts.md 並列契約節, When 「読み取り並列・実行直列」「テスト実行可否」+ 出典, Then count ≥1（TC-31、PASS 確認）
- [x] TC-05: Given rules/integration-verification.md 推奨, When 「usage を実測」系 literal + 出典, Then count ≥1（TC-32、PASS 確認）
- [x] TC-06: Given rules/multi-file-consistency.md 推奨, When 「信頼するディレクトリ境界」+ 出典, Then count ≥1（TC-33、PASS 確認）
- [x] TC-07: Given live tree（4 ディレクトリ/ファイル除外）, When `skills/(phase-compact|reload|strategy)` を grep, Then 0 hit（tests/test-doc-consistency.sh TC-16。git ls-files ベースの直接 grep で STALE_HITS=0 を再確認）
- [x] TC-08: Given skills/red/SKILL.md, When 新 step の contiguous phrase を grep, Then 存在 + wc -l ≤ 100（tests/test-phase-gate.sh TC-23、85 行で PASS 確認）

## Implementation Notes

### Goal
直近 3 cycle（20260701_1120 / 20260702_1200 / 20260702_1930）の retrospective で codified→rule 判定された insight 9 件（A1-A4, B, C, D, E, F）と issue #143（G）を一括実装し、rule-codify backlog を解消する。

### Background
rule-codify cycle は「retrospective で codified 判定 → 実装は次 cycle」という運用（無関係 cycle の commit を汚さない慣行）を繰り返す過程で、3 cycle 分の insight が実装待ちで積み上がった。issue #143 も同一ファミリー（20260702_1200 Codex code review F3、20260701_1120 Codify Decisions と同一テーマ）として issue 本文で同一 cycle 実装を推奨されている。本 cycle はこれらを一括で rule/skill/test に反映する。

### Design Approach
- 5 rule ファイル（test-patterns / plan-discipline / agent-prompts / integration-verification / multi-file-consistency）各々に、出典 cycle を明記した推奨（一部禁止事項）項目を追記し、`.claude/rules/` 側へ byte-identical mirror する（既存 test-rules-mirror.sh が自動検査）
- 追記する contiguous phrase literal は全て RED 時点で pre-existing count=0 を実測済み（下記実測値参照）。false-pass（rule.md 内に既に部分一致する語が存在し、rule 追記前から TC が誤って PASS する事故）を A2 の自己適用で事前に排除
- skills/red/SKILL.md には Stage 3（テスト失敗確認）の直後に Stage 3.5「False-pass 自己証明」を 2-3 行で追加し、詳細手順は reference.md に委譲する（SKILL.md 100 行制約を遵守）
- tests/test-doc-consistency.sh の TC-16 は inverse contract（削除済みスキル名が live tree に再混入していないことを検査）。path-form literal（`skills/(phase-compact|reload|strategy)`）を用い、単語形式の grep が起こす false positive（例: reference.md:193 "Error handling strategy?"）を構造的に回避する
- 新規テストファイルは作成しない（既存 3 test file への TC 追加のみ）ため、STATUS.md の Test Scripts カウントへの波及なし

## Verification

**Real-path invocation を最低 1 件含めること** (rules/integration-verification.md)。integration-verification.md の self-apply 要件: 本 cycle は D（usage 実測 rule）を定義する cycle であるため、以下の Verification は全て usage を実測確認済みの形式のみ使用する（rule の自己適用）。

```bash
SCRATCH=/private/tmp/claude-501/-Users-morodomi-Projects-MorodomiHoldings-agents-dev-crew/74f3a9a9-3af1-4977-80a3-f0ee96a13dd1/scratchpad
# 1) real-path: 対象テスト単体（usage: 引数なし、実測確認済み）
bash tests/test-codify-rule-docs.sh; echo "rc=$?"
bash tests/test-rules-mirror.sh; echo "rc=$?"
# test-doc-consistency.sh は TC-13 が nested full-suite runner のため単体実行しない（Codex plan review F2）。TC-16 相当の直接検査:
cd "$(git rev-parse --show-toplevel)" && git ls-files | grep -vE "^docs/(cycles|decisions|archive)/|^CHANGELOG\.md$" | xargs grep -lE "skills/(phase-compact|reload|strategy)" || echo "inverse contract 0 hit"
bash tests/test-phase-gate.sh; echo "rc=$?"
# 2) real-path: pre-commit-gate 明示指定モード（usage は前 cycle で実装・実測済み）
bash scripts/gates/pre-commit-gate.sh docs/cycles/20260703_1215_test-hardening-rule-codify.md; echo "rc=$?"
# 3) full suite（snapshot baseline と diff、rc≠0 は FAIL 扱い）
for f in tests/test-*.sh; do timeout 2400 bash "$f" >/dev/null 2>&1; printf "%s rc=%d\n" "$(basename $f)" "$?"; done | sort > "$SCRATCH/after-hardening.txt"
if grep -v "rc=0" "$SCRATCH/after-hardening.txt"; then echo "VERIFY FAIL"; false; else echo "all rc=0"; fi
diff "$SCRATCH/baseline-hardening.txt" "$SCRATCH/after-hardening.txt" && echo "no regression"
# 4) inverse contract の実弾: 除外なし grep で歴史文書のみ hit することを目視確認
grep -rEl "skills/(phase-compact|reload|strategy)" . --exclude-dir=.git | sort
```

Evidence: (orchestrate が自動記入)

## Progress Log

### 2026-07-03 12:15 - KICKOFF
- Design Review Gate 実施（architect 相当、design-reviewer への委譲ではない軽量審査）: **PASS score 30**
  - Scope: Files to Change 16 件（target 10 以下を超過）を **important 判定・accept**。理由: 全 16 件が「出典 cycle が確定済みの codified insight 9 件 + issue #143」への 1:1 対応で、YAGNI 違反（投機的な追加）は無し。各 rule 追記は 1-4 行、test 追記は既存 TC-27 テンプレート踏襲の TC 1 件ずつであり、新規ロジック・新規アーキテクチャ導入なし。20260701_1120（同型 rule-codify cycle、当時 4 file）の延長として、3 cycle 分の backlog を一括処理する明示的な意図が plan Context に記載されている
  - Architecture: Design Approach は具体的（追記位置・literal 候補・mirror 検査手法まで確定済み）。既存コードとの整合性を実測で確認（下記）
  - Test List: 10 項目、Given/When/Then 形式、正常系（TC-01〜06, TC-09）+ 逆向き契約（TC-07）+ 境界（TC-08: 100 行制約）+ 回帰確認（TC-10）でカテゴリ網羅
  - Risk: Risk 40（WARN 帯）は「実装コードなし、rules/tests/skill doc のみ」という変更内容と整合。BLOCK 帯（60+）には未到達
  - 判定: PASS のため sync-plan 相当（本エージェント自身）で Cycle doc 生成に進行
- **実測による裏取り（plan 記載値との照合、全て一致）**:
  - test-patterns.md 既存語数: 実測=2 / 分岐=1 / assert=1 / 同一=1（plan 記載と一致）。候補 6 literal（contiguous phrase / pre-existing count / 分岐 × 既存チェック / 出力文字列 assert / 同一セマンティクス / 挙動チェックリスト）は whole-file count=0 を確認 — false-pass リスクなし
  - plan-discipline.md: baseline=7（既存）。候補 2 literal（immutable snapshot 複製 / 並行プロセスから隔離）count=0
  - agent-prompts.md: 並列=4（既存）。候補 2 literal（読み取り並列・実行直列 / テスト実行可否）count=0
  - integration-verification.md: script=1（既存）。候補 1 literal（usage を実測）count=0
  - multi-file-consistency.md: enumerate=1, reject=1（既存）。候補 1 literal（信頼するディレクトリ境界）count=0
  - mirror 5 ファイル（test-patterns / plan-discipline / agent-prompts / integration-verification / multi-file-consistency）: rules/ と .claude/rules/ 間で byte-identical を確認済み（diff -q 全て一致）
  - skills/red/SKILL.md: 81 行（余白 19 行）を確認。構造は Stage 3（L57）→ exspec check（L62）→ Verification Gate（L68）の順で、plan 記載の「Stage 3 後・Verification Gate 前」挿入位置と一致
  - tests/test-codify-rule-docs.sh: 最終 TC は TC-27（L547-569）で、次連番 TC-28 を確認
  - tests/test-doc-consistency.sh: TC 一覧は TC-01/02/04/05/11-15（欠番あり、既存の連番慣行）。BASE_DIR override 対応済み（L7）を確認。次連番 TC-16 を確認
  - tests/test-phase-gate.sh: TC-01〜22 が既存。次連番 TC-23（plan の「次連番」は数値未確定だったため本 KICKOFF で確定）
  - live tree 逆向き契約実測: `grep -rEl "skills/(phase-compact|reload|strategy)" . --exclude-dir=.git --exclude-dir=docs/cycles --exclude-dir=docs/decisions --exclude-dir=docs/archive --exclude=CHANGELOG.md` は **0 hit**（plan 記載の「live tree 0 hit 確認済み」と一致）
  - 20260702_1930 の Codify Decisions（本 KICKOFF 開始前に orchestrate Block 0 codify gate で処理済み、retro_status: captured → resolved、2026-07-03 12:10）: Insight 1（E→multi-file-consistency.md）/ Insight 2（A3→test-patterns.md）/ Insight 3（A4→test-patterns.md）の Destination は plan の想定と完全一致。成功事例 observation は no-codify（想定通り）
  - 20260701_1120 / 20260702_1200 の Codify Decisions も遡って確認: A1/A2→test-patterns.md（Insight 1/2）、F→red skill deferred:new-cycle（Insight 4）、B→plan-discipline.md（Insight 1）、C→agent-prompts.md 並列契約節（Insight 2）、D→integration-verification.md（Insight 3）— 全て plan のテーブルと 1:1 一致
  - issue #143 本文を実測確認: タイトル「削除スキル名の inverse contract テスト追加（stale-ref 検査）」、20260702_1200 Codex code review F3 起点、「20260701_1120 Codify Decisions と同一ファミリーであり同一 cycle での実装を推奨」と明記 — plan の G destination 記述と一致
- Cycle doc created
- Scope definition ready

### 2026-07-03 12:50 - PLAN REVIEW (Codex competitive)
- Codex plan review: **BLOCK 2 + WARN 2**。triage（全て accept-apply、reject 0）:
- **F1 (BLOCK: TC-16 の除外 grep が false-fail) → accept-apply**: `grep --exclude-dir` は path prune として不完全で、ignored local file `.claude/settings.local.json:177` の `Skill(dev-crew:strategy)` にも hit する（Codex 実測）。TC-16 は **git ls-files ベースの tracked-live 契約**に変更: `git ls-files | grep -vE "^docs/(cycles|decisions|archive)/|^CHANGELOG\.md$" | xargs grep -lE "skills/(phase-compact|reload|strategy)"` → 0 hit。PdM 追認済み（本 tree で 0 hit）。untracked/ignored file は契約対象外となり除外列挙も 4 → 構造的に解決
- **F2 (BLOCK: test-doc-consistency は nested full-suite runner) → accept-apply**: Verification の「単体」リストから除外し、TC-16 相当の直接 grep に置換（本エントリで Verification 改訂済み）。TC-16 の suite 内検証は full suite ステップが担う
- **F3 (WARN: TC-28 が A1 の禁止事項を pin しない) → accept-apply**: TC-28 の契約に禁止事項 section の contiguous literal（候補「単体語」系連続句、RED で pre-existing count=0 実測後に確定）を追加。落とすと「禁止事項なしでも PASS」する穴の防止
- **F4 (WARN: baseline snapshot の前提記載) → accept-apply**: baseline-hardening.txt の provenance を記録 — snapshot は commit 146f05c + 意図的未コミット変更 1 件（docs/cycles/20260702_1930 の codify gate 編集）を含み、本 cycle doc（untracked）は**含まない**（snapshot 取得が architect の doc 生成前）。112/112 全 rc=0
- Codex 確認済み事項: TC-28〜33 候補 literal は section 内 0 hit / red SKILL.md 100 行余裕 / codify-rule-docs・phase-gate 単体 PASS
- 判定: BLOCK 事由は F1/F2 の設計変更で解消 → Block 2a (RED) へ

### 2026-07-03 13:20 - RED
- **rules/test-patterns.md A2 自己適用（false-pass 事前排除）**: 全 literal 候補を `section_grep` で pre-existing count 実測。以下全て **count=0**（false-pass リスクなし）:
  - test-patterns.md 禁止事項「単体語で pin」= 0 / 推奨「contiguous phrase」= 0 / 推奨「pre-existing count」= 0 / 出典「20260701_1120」= 0
  - test-patterns.md 推奨「分岐 × 既存チェック」= 0 / 「出力文字列 assert」= 0 / 「挙動チェックリスト」= 0 / 出典「20260702_1930」= 0
  - plan-discipline.md 推奨「immutable snapshot 複製」= 0 / 「並行プロセスから隔離」= 0 / 出典「20260702_1200」= 0
  - agent-prompts.md 並列起動時の prompt 契約「読み取り並列・実行直列」= 0 / 「テスト実行可否」= 0 / 出典「20260702_1200」= 0
  - integration-verification.md 推奨「usage を実測」= 0 / 出典「20260702_1200」= 0
  - multi-file-consistency.md 推奨「信頼するディレクトリ境界」= 0 / 出典「20260702_1930」= 0
  - red/SKILL.md「false-pass 不在を自己証明」= 0（TC-23 候補）
- **tests/test-codify-rule-docs.sh**: TC-28〜33 を TC-27 テンプレート踏襲で追加（section_grep + `-ge 1` && 連結 + elif で失敗理由分離）。TC-28 は Codex plan review F3 反映で禁止事項 section の pin（「単体語で pin」）も契約に含めた
- **tests/test-doc-consistency.sh**: TC-16 を「Regression」section（TC-13 nested full-suite runner）より前、「Terminology Consistency」section 直後に追加。Codex plan review F1/F2 反映:
  - `grep --exclude-dir` 方式は不採用（ignored local file への hit + path prune 不全）。`git -C "$BASE_DIR" ls-files` ベースの tracked-live 契約に変更
  - xargs 空入力対策として xargs を使わず、`while IFS= read -r f; do ...; done < <(git ls-files | grep -vE ...)` の read ループで 1 ファイルずつ判定（rules/test-patterns.md 準拠パターン）
- **tests/test-phase-gate.sh**: TC-23 を TC-22（Commit Completion Validation）の後、既存「Selection Snippet Consistency」section（TC-09 重複番号）の前に追加。red/SKILL.md に Stage 3.5 が未実装のため FAIL
- **RED 確認（個別実行）**:
  - `bash tests/test-codify-rule-docs.sh`: rc=1、PASS 27 / FAIL 6 / TOTAL 33。FAIL は TC-28〜33 の 6 件のみ、TC-01〜27 は全 PASS（回帰なし）
  - `bash tests/test-phase-gate.sh`: rc=1、PASS 23 / FAIL 1 / TOTAL 24。FAIL は TC-23 のみ、TC-01〜22 + Selection Snippet Consistency (TC-09) は全 PASS（回帰なし）
  - `bash -n tests/test-doc-consistency.sh`: 構文 OK（このスクリプトは TC-13 が nested full-suite runner のため単体実行しない — Verification 記載の方針通り）
  - TC-16 のロジック直接証明: `git ls-files | grep -vE "^docs/(cycles|decisions|archive)/|^CHANGELOG\.md$"` の while ループ判定で **STALE_HITS=0**（PASS 相当）。除外フィルタを外した場合は **STALE_HITS=9**（docs/archive/roadmap-v2-v3-completed.md 1件 + docs/cycles 配下 8 件、全て historical reference）。tests/test-doc-consistency.sh 自身への自己参照ヒットなし（ファイル内の `grep -E` パターン文字列はリテラル `skills/phase-compact` 等の部分文字列を含まないため、ERE 上マッチしないことを確認）
- 想定外事象: なし。新規テストファイル作成なし（既存 3 ファイルへの TC 追加のみ、STATUS.md test count 変更なし）
- Cycle doc frontmatter: phase → RED, updated → 2026-07-03 13:20
- Phase completed

---

### 2026-07-03 14:05 - GREEN
- **変更ファイル（12 件、全量）**:
  1. `rules/test-patterns.md` (edit) — 禁止事項に「単体語で pin」1件、推奨に「contiguous phrase」「pre-existing count」「分岐 × 既存チェック」「出力文字列 assert」「挙動チェックリスト」5件、出典に 20260701_1120・20260702_1930 参照 1件を末尾追記
  2. `.claude/rules/test-patterns.md` (edit, mirror) — 1 と byte-identical
  3. `rules/plan-discipline.md` (edit) — 推奨に「immutable snapshot 複製」「並行プロセスから隔離」、出典に 20260702_1200 参照を末尾追記
  4. `.claude/rules/plan-discipline.md` (edit, mirror) — 3 と byte-identical
  5. `rules/agent-prompts.md` (edit) — 「並列起動時の prompt 契約」節末尾に「読み取り並列・実行直列」「テスト実行可否」、出典に 20260702_1200 参照を追記
  6. `.claude/rules/agent-prompts.md` (edit, mirror) — 5 と byte-identical
  7. `rules/integration-verification.md` (edit) — 「推奨 (project type 別)」節末尾に「usage を実測」、出典に 20260702_1200 参照を追記
  8. `.claude/rules/integration-verification.md` (edit, mirror) — 7 と byte-identical
  9. `rules/multi-file-consistency.md` (edit) — 推奨に「信頼するディレクトリ境界」、出典に 20260702_1930 参照を追記
  10. `.claude/rules/multi-file-consistency.md` (edit, mirror) — 9 と byte-identical
  11. `skills/red/SKILL.md` (edit) — Stage 3 後・exspec check 前に Stage 3.5「False-pass 自己証明」2行を追加（81→85行）
  12. `skills/red/reference.md` (edit) — Test Execution 節後に `## False-pass Self-Proof {#false-pass-self-proof}` セクション（3手順 + rules/test-patterns.md 参照）を追加
- **GREEN 確認（個別実行、全て rc=0）**:
  - `bash tests/test-codify-rule-docs.sh` → rc=0、PASS 33 / FAIL 0 / TOTAL 33（TC-28〜33 含む全 PASS）
  - `bash tests/test-phase-gate.sh` → rc=0、PASS 24 / FAIL 0 / TOTAL 24（TC-23 含む全 PASS、red/SKILL.md 85 行を確認）
  - `bash tests/test-exspec-integration.sh` → rc=0、PASS 8 / FAIL 0（T-08: SKILL.md 85 行 ≤ 100 を再確認）
  - `bash tests/test-red-complexity-gate.sh` → rc=0、PASS 6 / FAIL 0（TC-R6: SKILL.md 85 行 ≤ 100 を再確認）
  - `test-doc-consistency.sh` は nested full-suite runner のため個別実行せず、TC-16 契約の直接 grep で確認: `git ls-files | grep -vE "^docs/(cycles|decisions|archive)/|^CHANGELOG\.md$" | while read f; do grep -lE "skills/(phase-compact|reload|strategy)" "$f"; done` → 0 hit（新規追記した rule 文面が削除済みスキル名の path-form を含まないことを確認。追記文は全て具体スキル名を含まない一般化された文言のみ）
  - `test-rules-mirror.sh` は個別実行せず、mirror 5 ペア全て `diff rules/X.md .claude/rules/X.md` で差分ゼロを直接確認済み（cp 後 diff 実行、上記編集ログ参照）
- 想定外事象: なし。tests/ 配下（RED 成果物）は無変更。STATUS.md の Test Scripts カウントへの波及なし（新規 test file 追加なし）
- Cycle doc frontmatter: phase → GREEN, updated → 2026-07-03 14:05
- Test List: TC-01〜08 を WIP → DONE に移動。TC-09（test-rules-mirror.sh）・TC-10（full suite baseline diff）は VERIFY phase 用に TODO へ残置
- Phase completed

### 2026-07-03 13:55 - REFACTOR (PdM 検証)
- rule/skill doc + テスト追記のみの cycle のため構造的リファクタ不要（no-op）
- Verification Gate: test-codify-rule-docs（33）/ test-phase-gate（24）/ test-rules-mirror / test-exspec-integration / test-red-complexity-gate 全 rc=0、mirror 5 ペア diff 空、red/SKILL.md 85 行（≤100）、inverse contract 直接 grep 0 hit
- Phase completed

### 2026-07-03 14:30 - VERIFY (Product Verification, Block 2c.5)
- Evidence: /tmp/dev-crew-verify-20260703_1215/verify.log
- 単体: codify-rule-docs / rules-mirror / phase-gate 全 rc=0
- TC-16 相当の直接検査（git ls-files ベース）: inverse contract 0 hit
- real-path: pre-commit-gate 明示指定 → 本 cycle doc を正しく選択し REVIEW 未完了で BLOCK（この段階の正常挙動 — 前 cycle で修正した gate が本 cycle を実際に守っている実証）
- **full suite: 112/112 全 rc=0、baseline-hardening.txt との diff 空 = 回帰ゼロ**（snapshot 隔離 baseline、rule B の自己適用）
- Phase completed

### 2026-07-03 15:10 - REVIEW FIX (green-worker)
- REVIEW で BLOCK（Codex 1 + maintainability 3）が出たため 6 件を修正。
- **Fix 1 (Codex BLOCK, tests/test-doc-consistency.sh TC-16)**: `git ls-files` の失敗（non-git dir 等）が process substitution 内で空出力を生み、while ループが黙って 0 回実行され `STALE_HITS=0` のまま PASS してしまう silent false-pass を修正。
  - **red-first 実証（修正前）**: non-git 一時ディレクトリを `BASE_DIR` に見立てた旧ロジックを再現実行 → `STALE_HITS(non-git dir, current logic)=0` → `=> PASS (BUG: silent false-pass on git failure)` を確認（バグの直接証明）
  - 修正: `tracked=$(git -C "$BASE_DIR" ls-files 2>/dev/null)` + 直後の `rc=$?` を取得し rc≠0 なら fail。filter 後の対象ファイル数 `target_count` が 0 なら fail（filter 過剰の false-pass も防止）。その上で従来の while ループ判定を維持
  - **修正後の再実証**: non-git dir → `FAIL: git ls-files failed (rc=128)`、実リポジトリ → `PASS (301 files checked)` を確認（両条件で意図通りの分岐を実証）
- **Fix 2 (maintainability BLOCK×3)**: 追跡番号ラベルコメントを除去（WHY 本文は保持）
  - `tests/test-codify-rule-docs.sh` TC-28 直前コメント: 「(Codex plan review F3 反映: ..., cycle 20260703_1215)」→「A1 の禁止事項も pin する（推奨のみだと禁止形を落としても PASS するため）」に書き換え
  - `tests/test-doc-consistency.sh` TC-16 直前コメント: 「(Codex plan review F1, cycle 20260703_1215)。」を除去し、「ignored local file への hit / path prune 不全を避けるため git ls-files ベース」の WHY 部分を保持（Fix 1 のコメント全面改訂と合わせて実施）
  - `tests/test-phase-gate.sh` TC-23 直前コメント: 「(TC-23, cycle 20260701_1120 Insight 4 deferred:new-cycle)」→「RED False-pass Self-proof の存在検査」の WHY 型に書き換え
  - 追加で `tests/test-doc-consistency.sh:138` の section header 「(issue #143)」ラベルも同一 cycle 内の追加分として検出したため除去（検証コマンドの 0 件契約を満たすため必須）
  - 検証: `grep -rnE "cycle 2026[0-9]{4}|issue #[0-9]" tests/test-codify-rule-docs.sh tests/test-doc-consistency.sh tests/test-phase-gate.sh` → rc=1（0 件、マッチなし）を確認
- **Fix 3 (maintainability WARN, rules/plan-discipline.md 具体例)**: baseline コードブロックを新 rule（immutable snapshot 複製 + evidence 隔離）に追随。`SNAP=$(mktemp -d); cp -R . "$SNAP"` で複製→複製内 (`cd "$SNAP"`) で実行→結果は `"$SCRATCH/baseline.txt"`（隔離 path）に保存する形へ書き換え。`/tmp/baseline.txt` の非隔離例を除去。TC-27/TC-30 の literal（「GREEN 検証は curated」「immutable snapshot 複製」等）は維持されたまま変更（既存行を保持し具体例ブロックのみ改訂）。`.claude/rules/plan-discipline.md` mirror 同期
- **Fix 4 (maintainability WARN, rules/integration-verification.md)**: 新規行を既存項目と同じ太字ラベル形式に統一 — `- **dev-crew 内 (bash/doc project)**: ...` の直後に `- **共通 (全 project type)**: Verification に書く script 呼び出しは「usage を実測」...` として追加（literal「usage を実測」は保持、TC-32 契約に影響なし）。`.claude/rules/integration-verification.md` mirror 同期
- **Fix 5 (maintainability LOW, rules/test-patterns.md)**: 出典の新規 1 行（2 cycle 併記）を 1 行 1 cycle の 2 行に分割（`docs/cycles/20260701_1120_...` と `docs/cycles/20260702_1930_...` を別行に）。TC-28/29 の literal「20260701_1120」「20260702_1930」はどちらの行にも contiguous に残るため契約非破壊。intro 文「〜8 つの insight」の固定 count 表現を「複数 cycle から抽出した insight」の count 非依存表現に更新（pre-existing stale 解消）。`.claude/rules/test-patterns.md` mirror 同期
- **完了確認（個別実行のみ、full suite は実行せず）**:
  - `bash tests/test-codify-rule-docs.sh` → rc=0、PASS 33 / FAIL 0 / TOTAL 33
  - `bash tests/test-phase-gate.sh` → rc=0、PASS 24 / FAIL 0 / TOTAL 24
  - `bash -n tests/test-doc-consistency.sh` → syntax OK（nested full-suite runner のため単体実行せず、TC-16 部分ロジックを直接実行し正常系 PASS（301 files checked）+ git 失敗系 FAIL（rc=128）の両方を確認、上記 Fix 1 参照）
  - `bash tests/test-rules-mirror.sh` → rc=0、PASS 3 / FAIL 0（mirror 5 ペア全て byte-identical を再確認）
- 想定外事象: `tests/test-doc-consistency.sh:138` の section header ラベルは Fix 2 の指定 3 箇所に含まれていなかったが、同一 cycle の追加分であり検証コマンドの契約（0 件）を満たすために追加除去。ラベル除去のみで WHY 本文・機能ロジックへの影響なし
- Cycle doc frontmatter: updated → 2026-07-03 15:10（phase は REFACTOR のまま）
- Phase completed

### 2026-07-03 15:30 - REVIEW (Codex competitive + 3 Claude reviewers, MED tier)
- 判定: Codex **BLOCK 1** / correctness **PASS**（逆条件実証・literal byte 一致まで確認）/ security **PASS** / maintainability **BLOCK 3 + WARN 2 + LOW 2**
- findings 3-category triage:
  - **accept-apply（6 fix、適用・再検証済み）**:
    1. Codex BLOCK: TC-16 の git ls-files が process substitution 内で silent fail（non-git dir で PASS を実証）→ rc 明示チェック + 対象 0 件 FAIL 化。red-first で修正前 PASS / 修正後 FAIL(rc=128 検出) を実証。**本 cycle が codify した「出力文字列 assert / silent skip 検出」rule が自 cycle のテストに刺さった dogfood**
    2. maint BLOCK×3(+1): テストコメントの追跡ラベル（cycle 番号 / issue #）除去、WHY 本文保持。green-worker が指定外 1 件（doc-consistency:138 の issue #143）も検出し除去。検証 grep 0 件
    3. maint WARN: plan-discipline 具体例を snapshot 隔離形式に追随更新（新 rule との矛盾解消）+ mirror
    4. maint WARN: integration-verification 新規行を「**共通 (全 project type)**:」ラベル形式に統一 + mirror
    5. maint LOW: test-patterns 出典の 1 行 1 cycle 分割 + intro の固定 count 表現除去 + mirror
  - **reject**: なし
- 適用後: codify-rule-docs 33/33 / phase-gate 24/24 / rules-mirror 3/3 全 rc=0（PdM 追認済み）、ラベル残存 0 件
- **再発の記録（retro 候補）**: テストコメントへの追跡ラベル混入は前 cycle（20260702_1930 REVIEW maint HIGH×3）に続く 2 cycle 連続の再発。worker prompt への禁止明示だけでは防げていない — 自動 inverse contract（tests/ コメントのラベル検査 TC）が codify 候補
- BLOCK 事由は全て解消 → Block 2e へ
- Phase completed

### 2026-07-03 15:32 - DISCOVERED (Block 2e)
- D1: テストコメント追跡ラベルの自動 inverse contract（2 cycle 連続再発の恒久対策。正当な参照 — rule 出典 section・cycle doc 本文・fixture frontmatter — と区別する pattern 設計が必要）→ issue 起票
- 既存 issue で追跡済みのため新規起票なし: #142（parallel）、#144（flaky）、#147（non-DONE 遷移）、#148（gate drift guard）
- issue 起票結果: D1=#151

### 2026-07-03 16:00 - COMMIT
- REVIEW FIX 適用後の最終 full suite: **112/112 全 rc=0、baseline-hardening.txt との diff 空（回帰ゼロ）**（scratchpad/final-hardening.txt）
- pre-commit gate は明示指定モードで dogfood 実行
- branch feature/test-hardening-rule-codify で commit、PR を main base で作成（closes #143）
- Phase completed

---

## Next Steps

1. [Done] KICKOFF
2. [Done] plan-review（Codex competitive）
3. [Done] RED
4. [Done] GREEN <- Current
5. [ ] REFACTOR
6. [ ] REVIEW
7. [ ] COMMIT
8. [ ] DONE

## Retrospective

抽出時刻: 2026-07-03 15:45
抽出方法: Cycle doc 全体（PLAN REVIEW BLOCK×2 / REVIEW BLOCK×4 / red-first fix）からの失敗→最終解→insight ペア抽出

### Insight 1: 新 rule を書く cycle は、その rule を同 cycle の成果物に checklist 適用してから REVIEW に出す
- **Failure**: 本 cycle が codify した「分岐 × 既存チェックの出力文字列 assert / silent skip 検出」rule の違反形（TC-16 の git ls-files が process substitution 内で silent fail）を、rule を書いた同じ RED 成果物が含んでいた。Codex code review が non-git dir 実証で検出
- **Final fix**: rc 明示チェック + 対象 0 件 FAIL 化。red-first で修正前 PASS / 修正後 FAIL を実証
- **Insight**: **rule の codify（文章化）と rule の適用（自分の成果物への checklist 実行）は別作業。新 rule を定義する cycle は、REVIEW 前に「本 cycle の全成果物に新 rule を checklist として適用したか」を確認する**。integration-verification.md の self-apply 原則（rule cycle は自 cycle Verification に self-apply）のテスト設計版
- **一般化**: RED worker prompt の自己検証項目に「本 cycle で codify する rule 自体への準拠」を含める運用

### Insight 2: 指示で 2 回失敗した規約は 3 回目を待たず自動 inverse contract 化する（2-strike rule）
- **Failure**: テストコメントへの追跡ラベル混入が 2 cycle 連続で再発（20260702_1930 で 3 件 → prompt に禁止を明示した本 cycle でも 4 件）。maintainability review が両回とも検出し手動除去
- **Final fix**: ラベル除去 + #151 起票（自動 inverse contract の設計）
- **Insight**: **prompt 指示・rule 文書で 2 回防げなかった規約違反は、3 回目を待たずに自動契約（inverse contract TC / gate）へ昇格する**。cycle 20260422_1313 #1「自動化なき規律は破綻する」の閾値付き運用形
- **一般化**: codify-insight の recurrence pre-triage（2+ 再発 → rule 昇格）と同じ 2-strike 閾値を「rule → 自動契約」の昇格にも適用する

### Insight 3: while ループへの process substitution は上流コマンドの rc を握り潰す
- **Failure**: `while read ...; done < <(git ls-files | ...)` 構成で git 失敗（rc=128）が捕捉されず、空ループ → STALE_HITS=0 → PASS の false-pass 経路が成立
- **Final fix**: `tracked=$(git -C "$BASE_DIR" ls-files 2>/dev/null)` で変数に受けて rc を直後検査 + filter 後の対象 0 件も FAIL 化
- **Insight**: **外部コマンドの出力を while で消費するテストは、command substitution で変数に受けて rc を直後検査してからループする**。process substitution / pipe への直結は上流失敗を silent skip にする（rules/test-patterns.md の rc 記録パターンの while-loop 版）
- **一般化**: test-patterns.md 追記候補（次の codify triage で判定）
