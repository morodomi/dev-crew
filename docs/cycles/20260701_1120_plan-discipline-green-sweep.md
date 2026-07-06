---
feature: plan-discipline-green-sweep
cycle: 20260701_1120
phase: DONE
complexity: simple
test_count: 1
risk_level: LOW
retro_status: resolved
codex_session_id: "019f1b7c-a332-7493-a31c-384e3e05a4b0"
created: 2026-07-01 11:21
updated: 2026-07-06 11:40
---

# Plan Discipline — GREEN 検証 sweep ルール codify

## Scope Definition

### In Scope
- [ ] `rules/plan-discipline.md` の「推奨」section に GREEN 検証 sweep 項目を1件追加 + 「出典」に cycle 参照追加
- [ ] `.claude/rules/plan-discipline.md` を identical mirror 更新
- [ ] `tests/test-codify-rule-docs.sh` に新 TC（TC-27）追加（section_grep helper 再利用）
- [ ] Cycle doc

### Out of Scope
- STATUS.md count 変更なし（新 test file を追加しない、既存 test への TC 追加のみ）
- `.claude/dev-crew.json` マーカー修正はユーザー判断で follow-up 保留
- 20260525_1249 Insight 3 / 20260625_1101 Insight 2・3 の codify — 本 cycle は Insight 1 のみ

### Files to Change (target: 10 or less)
- `rules/plan-discipline.md` — 推奨 +1項目、出典 +1参照
- `.claude/rules/plan-discipline.md` — identical mirror
- `tests/test-codify-rule-docs.sh` — 新 TC（次連番: TC-27）追加
- `docs/cycles/20260701_1120_plan-discipline-green-sweep.md` — Cycle doc 自身

## Environment

### Scope
- Layer: Documentation / Rules
- Plugin: bash / shell (dev-crew dogfood)
- Risk: 10 (PASS)

### Runtime
- Language: bash / shell (dev-crew 自身のルール文書)

### Dependencies (key packages)
- tests/test-codify-rule-docs.sh — section_grep helper (L220-229)
- rules/plan-discipline.md — 既存 rule 文書

### Risk Interview (BLOCK only)
(N/A — Risk LOW)

## Context & Dependencies

### Reference Documents
- `rules/plan-discipline.md` — 追記対象の rule 文書
- `.claude/rules/plan-discipline.md` — identical mirror（同期対象）
- `tests/test-codify-rule-docs.sh` — section_grep helper 再利用（TC-27 追加先）
- `docs/cycles/20260625_1101_rules-path-scoping.md` — 本 insight の出典サイクル
- `rules/test-patterns.md` — whole-file grep 禁止規約（section_grep 使用の根拠）
- `rules/integration-verification.md` — Verification section の real-path invocation 規約

### Dependent Features
- `tests/test-codify-rule-docs.sh`: section_grep helper (L220-229) を TC-27 が再利用

### Related Issues/PRs
- PR #139 (path-scoping, OPEN) — 本 cycle は独立、main から新 feature ブランチで作業

## Test List

### TODO
(none)

### WIP
(none)

### DISCOVERED
(none)

### DONE
- [x] TC-27: `rules/plan-discipline.md`「推奨」section に `curated` + `GREEN` + (`逆向き契約` or `sweep`) literal 存在 AND「出典」に `20260625_1101` 参照存在。section_grep helper 再利用（Codex plan review WARN 反映で核心語 sweep/逆向き契約 を追加強化）

## Implementation Notes

### Goal
前サイクル (20260625_1101) の REVIEW で Codex competitive review が検出した実 regression（STATUS.md count 変更後に curated 非回帰リストのみ検証し `test-codify-insight.sh` TC-19 の hardcode contract を見逃した問題）を `rules/plan-discipline.md` に codify し、テストで rule text の存在を強制する。

### Background
- cycle 20260625_1101 retrospective Insight 1: count/status 変更 cycle の GREEN 検証は curated 非回帰リストでなく逆向き契約 sweep で全実行する
- cycle 20260525_1249 Insight 1（count 変更時の逆向き契約明示）と Insight 2（Block 0 full-suite baseline）がこの問題を予告していた
- 実 regression 事例: STATUS.md の Test Scripts を 112→113 に更新したが、`test-codify-insight.sh` TC-19 が `Test Scripts | 112` を hardcode → curated リストのみ検証では素通り

### Design Approach
dev-crew の rule codification 標準パターン（cycle 20260424_0900 と同型）に従う:
1. `rules/plan-discipline.md` の「推奨」section 末尾に新項目を追記
2. `tests/test-codify-rule-docs.sh` に TC-27 を追加（RED: rule 未追記で FAIL 確認）
3. rule 追記（GREEN: TC-27 PASS）
4. `.claude/rules/plan-discipline.md` を byte-identical mirror 更新
- whole-file grep 禁止（test-patterns.md 規約）→ section_grep helper 再利用
- SKILL.md 100 行制約：本 cycle は SKILL.md に触れない（rule doc + test のみ）

## Verification

```bash
# 新 TC RED→GREEN
bash /Users/morodomi/Projects/MorodomiHoldings/agents/dev-crew/tests/test-codify-rule-docs.sh; echo "rc=$?"

# mirror byte-identical
diff /Users/morodomi/Projects/MorodomiHoldings/agents/dev-crew/rules/plan-discipline.md /Users/morodomi/Projects/MorodomiHoldings/agents/dev-crew/.claude/rules/plan-discipline.md && echo "IDENTICAL"

# real-path: section_grep で推奨/出典 抽出が正しいか
awk '$0 ~ "^## 推奨"{s=1;next} s&&/^## /{s=0} s' /Users/morodomi/Projects/MorodomiHoldings/agents/dev-crew/rules/plan-discipline.md | grep -c "curated"
awk '$0 ~ "^## 出典"{s=1;next} s&&/^## /{s=0} s' /Users/morodomi/Projects/MorodomiHoldings/agents/dev-crew/rules/plan-discipline.md | grep -c "20260625_1101"
```

Evidence: (orchestrate が自動記入)

## Progress Log

### 2026-07-01 11:21 - KICKOFF
- Cycle doc created from plan file /Users/morodomi/.claude/plans/replicated-mixing-snowflake.md
- Scope definition ready
- Test List: 1 item (TC-27)
- Files to Change: 4 files
- Phase completed

### 2026-07-01 - PLAN REVIEW (Codex competitive, no-test static)
- Design Review Gate: PASS score 25 (LOW, risk-classifier 採用)
- Codex plan review (session 019f1b7c-a332-7493-a31c-384e3e05a4b0): **WARN score 84**、2 findings（いずれも accept-apply）:
  - TC-27 の literal `curated`+`GREEN` は section 内に別々存在で false-pass 余地 → **強化**: 核心語 `逆向き契約` または `sweep` も literal に含める（追記 rule 文は全語を含むため GREEN で満たす）
  - Verification 手動抽出例が `GREEN` 未確認 → **追加**: 推奨 section の `GREEN` grep を Verification に加える
  - checks (1)(2)(3) 全 PASS: section_grep 方針一致 / 既存 L24 PLAN 時 sweep と phase 相違で矛盾なし / mirror + count 不変判断 正当
- 逆向き契約 sweep (本 cycle が codify する規律) を **自己適用**: git diff は plan-discipline.md + mirror + test-codify-rule-docs.sh の3 file、count 不変（新 test file なし）。`grep -rln "test_count\|TC-27" tests/` の逆向き契約なし
- BLOCK なし → Block 2a (RED) へ、強化 TC-27 で実装
- **Branch 戦略補正**: Related Issues の「main から分岐」は誤り。実際は #139 の上に stack（20260625_1101 の retrospective/codify 状態が #139 に存在するため。main 分岐では codify gate が誤発火する）

### 2026-07-01 - RED (red-worker)
- `tests/test-codify-rule-docs.sh` に TC-27 追加（section_grep helper 再利用、`逆向き契約`/`sweep` OR は個別取得 + `||` 評価）
- 実行: TC-27 FAIL、TC-01〜26 PASS、rc=1 — rule 未追記の正常 RED

### 2026-07-01 - GREEN (green-worker)
- `rules/plan-discipline.md` 推奨 +1項目 / 出典 +1参照、`.claude/rules/plan-discipline.md` byte-identical mirror
- 27/27 PASS、mirror IDENTICAL
- Phase completed

### 2026-07-01 - REFACTOR
- doc + test 追記のみで構造的リファクタ不要（no-op）。bash -n 構文 OK
- Phase completed

### 2026-07-01 - VERIFY (Product Verification + 本 cycle 規律の自己適用 dogfood)
- 推奨 literals 実測: curated 1 / GREEN 1 / 逆向き契約|sweep 3 / 出典 20260625_1101 1
- mirror byte-identical、count 不変 113==実113
- **自己適用**: 本 cycle が codify する「逆向き契約 sweep」を dogfood。`grep -rln "plan-discipline|TC-27" tests/` で curated リスト（test-codify-rule-docs のみ想定）より広い **5 test** を検出（test-agents-structure / test-commit-auto-learn / test-discovered-debt-cleanup / test-v2-restructuring / test-codify-rule-docs）→ 全 rc=0。sweep が curated リストの盲点を埋める実証
- 非回帰: test-rules-mirror / test-v2-release rc=0
- Phase completed

### 2026-07-01 - REVIEW (Codex competitive code review)
- risk LOW 25 → review-triage LOW/trivial tier。Codex code review (session resume, no-test static)
- **Codex code review: BLOCK score 78**、1 critical finding（本 cycle テーマの自己言及的 catch）:
  - TC-27 の `逆向き契約`/`sweep` 単体 OR 検査が false-pass。推奨 section に既存項目で `逆向き契約`(L4) と `sweep`(L10「影響範囲 sweep」) が存在するため、新規追記行がその語を欠いても TC-27 が成立 → **追記行を pin できていない**
- **triage: accept-apply**（本 cycle が codify する「テストは契約を pin せよ」規律の実例。dogfood）:
  - TC-27 を単体語検査から**新規行にのみ現れる連続句**検査に変更: `GREEN 検証は curated`（count 1）+ `逆向き契約 sweep`（count 1、既存の `影響範囲 sweep` とは別）+ 出典 `20260625_1101`
  - echo header も新記述に同期
- **敵対的実証**（test-codify-rule-docs.sh は BASE_DIR override 非対応のため fixture 不可 → ロジック直接証明）: 新規行あり → 連続句 count 1+1、新規行除去 → count 0+0（= TC-27 FAIL）。false-pass 解消を証明
- **再検証（逆向き契約 sweep 自己適用）**: `grep -rln "plan-discipline|TC-27|test-codify-rule-docs" tests/` の5 test + 契約 test（rules-mirror, v2-release）全 rc=0、count 不変 113、mirror IDENTICAL
- checks: 追記 section 構造維持 / mirror byte-identical / 20260625_1101 の Codify Decisions 追記が APPEND-ONLY 準拠 — 全 PASS
- BLOCK 解消 → PASS、Block 2e へ
- Phase completed

### 2026-07-01 - DISCOVERED
- test-codify-rule-docs.sh が `BASE_DIR` env override 非対応（`$(cd..)` 固定）で fixture-based meta test 不可。他 test は override 対応。observation、本 cycle scope 外（fixture 代替にロジック直接証明で対処済み）。将来の test-infra 統一時に検討
- 新規 scope 外項目の issue 起票なし（軽微、記録のみ）

## Next Steps

1. [Done] KICKOFF
2. [Done] RED
3. [Done] GREEN
4. [Done] REFACTOR
5. [Done] REVIEW
6. [Done] COMMIT
7. [Done] DONE

## Retrospective

抽出時刻: 2026-07-01
抽出方法: Cycle doc 全体（plan review WARN / RED / GREEN / REVIEW BLOCK→fixed）からの失敗→最終解→insight ペア抽出

### Insight 1: rule-codify test の literal は「新規追記行にのみ現れる連続句」で pin する
- **Failure**: TC-27 が `curated`/`GREEN`/`逆向き契約`/`sweep` を**単体語**で section_grep 検査。しかし `逆向き契約`(推奨 L4) と `sweep`(推奨 L10「影響範囲 sweep」) は既存項目に存在するため、新規追記行がその語を欠いても TC-27 が false-pass。Codex code review が BLOCK で検出
- **Final fix**: 新規行にのみ現れる連続句 `GREEN 検証は curated` + `逆向き契約 sweep` で検査。ロジック直接証明で「行除去 → count 0 → FAIL」を確認
- **Insight**: **doc/rule への追記を検査する test は、追記内容にのみ現れる contiguous phrase を literal にする**。単体語は section 既存項目で false-pass する。section_grep は section を絞るが「その section の**どの行**か」までは絞らないため、語の pre-existing 有無の確認が必須
- **一般化**: `tests/test-codify-rule-docs.sh` の他 section_grep TC（TC-11/22/23 等）も同型 false-pass リスクを持つ可能性 → 監査候補（次 cycle DISCOVERED 級）

### Insight 2: literal 強化提案は section 内 pre-existing count 確認とセットでないと不十分
- **Failure**: plan-review WARN が「`逆向き契約`/`sweep` を literal に追加」と提案 → 従ったが両語とも推奨 section に既存 → 強化が不十分で code-review BLOCK に至った。competitive review の2段（plan WARN → code BLOCK）を要した
- **Final fix**: 連続句 + `grep -cF` で pre-existing count=1（新規行のみ）を実測確認してから採用
- **Insight**: **test literal を追加/強化する時は `section_grep <file> <section> <literal>` の pre-existing count を実測し、0 であることを確認する**（追記後に 1 になる = 追記が pin される）。「語を増やす」だけでは pre-existing で無効化される
- **一般化**: Insight 1 の予防手順。literal 選定を実測ベースにする（plan-discipline.md「未確認で記述しない」の test-literal 版）

### Insight 3: 逆向き契約 sweep の自己適用 dogfood が有効に機能した（success）
- **Failure**: なし（成功事例）
- **Final fix**: 本 cycle が codify した「逆向き契約 sweep」を GREEN/REVIEW 検証で self-apply。`grep -rln "plan-discipline|TC-27|test-codify-rule-docs" tests/` が curated 想定（test-codify-rule-docs のみ）より広い5 test を検出 → 全 rc=0
- **Insight**: **新 rule を codify する cycle は、その rule を同 cycle の検証で self-apply して dogfood する**。rule の実用性が即検証される（integration-verification.md の self-apply precedent と一致）
- **一般化**: observation 寄り。integration-verification.md 既存規律の追認事例

### 2026-07-01 - COMMIT
- feature/plan-discipline-green-sweep（#139 の上に stack）に commit e6710b5、5 files
- pre-commit-gate PASS、.git/hooks pre-commit PASS
- PR base は feature/rules-path-scoping（#139）に設定した stacked PR
- Phase completed

---

## Retrospective 補遺

### メタパターン注記（codify 候補として強調）
Codex competitive review が **3 cycle 連続で test-false-pass 級 BLOCK/regression を検出**: 20260625_1101 (TC-04 body drift + TC-19 count hardcode)、本 cycle (TC-27 単体語 false-pass)。RED test が「契約を pin するか」を書き手が adversarial に自己検証していない systemic gap を示唆。RED phase に「新規 test は fixture/ロジックで false-pass 不在を証明する」step を追加する higher-order codify 候補（Insight 1/2 を包含）

## Codify Decisions

triage 実施: 2026-07-02（後続 cycle skill-inventory-cleanup の orchestrate Block 0 codify gate で処理）。Recurrence pre-triage: test-false-pass 級 BLOCK が 3 cycle 連続（20260625_1101 / 本 cycle / 20260421_2342）で再発 2+ 該当。

### Insight 1
- **Decision**: codified
- **Destination**: rule (rules/test-patterns.md + .claude/rules/ mirror)
- **Reason**: 再発 2+ で promotion 確定（pre-triage 自動）。「追記検査 test は追記内容にのみ現れる contiguous phrase を literal にする」を test-patterns.md に追記。実装は次 cycle（20260525_1249 precedent: rule 編集を伴う insight は無関係 cycle の commit を汚さない）
- **Decided**: 2026-07-02 12:00

### Insight 2
- **Decision**: codified
- **Destination**: rule (rules/test-patterns.md + .claude/rules/ mirror、Insight 1 と同一節)
- **Reason**: Insight 1 の予防手順（literal 採用前に section 内 pre-existing count=0 を実測）。同一 rule 節に統合して追記。実装は次 cycle（同上）
- **Decided**: 2026-07-02 12:00

### Insight 3
- **Decision**: no-codify
- **Reason**: 成功事例の observation。integration-verification.md 既存規律（self-apply dogfood）の追認であり新規 rule 化不要
- **Decided**: 2026-07-02 12:00

### Insight 4（Retrospective 補遺 メタパターン）
- **Decision**: deferred
- **Destination**: new-cycle
- **Reason**: RED phase への「新規 test の false-pass 不在を自己証明する step」追加は red スキル変更を伴う skill 候補。ユーザー確認で deferred: new-cycle を選択。Insight 1/2 の rule 化で当面の防御は確保
- **Decided**: 2026-07-02 12:00
