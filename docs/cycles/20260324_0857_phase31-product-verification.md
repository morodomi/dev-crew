---
feature: product-verification
cycle: phase31-product-verification
phase: DONE
complexity: standard
test_count: 9
risk_level: low
codex_session_id: ""
created: 2026-03-24 08:57
updated: 2026-03-24 08:57
---

# Phase 31: Product Verification PoC

## Scope Definition

### In Scope
- [ ] `tests/test-product-verify.sh` 新規作成（TC-01〜TC-09）
- [ ] `skills/spec/templates/cycle.md` に `## Verification` セクション追加
- [ ] `skills/orchestrate/SKILL.md` に Block 2c.5 追加
- [ ] `skills/orchestrate/reference.md` に Product Verification 詳細セクション追加
- [ ] `skills/orchestrate/steps-subagent.md` に VERIFY ステップ追加（REFACTOR→REVIEW間）
- [ ] `skills/orchestrate/steps-teams.md` に VERIFY ステップ追加（REFACTOR→REVIEW間）
- [ ] `skills/orchestrate/steps-codex.md` に VERIFY ステップ追加（REFACTOR→REVIEW間）

### Out of Scope
- ROADMAP.md の ShaReco参照削除（issue起票済み → DISCOVERED セクション参照）
- Product Verification 専用スキルの新規作成（YAGNI: orchestrateが直接実行）

### Files to Change (target: 10 or less)
- `tests/test-product-verify.sh` (new)
- `skills/spec/templates/cycle.md` (edit)
- `skills/orchestrate/SKILL.md` (edit)
- `skills/orchestrate/reference.md` (edit)
- `skills/orchestrate/steps-subagent.md` (edit)
- `skills/orchestrate/steps-teams.md` (edit)
- `skills/orchestrate/steps-codex.md` (edit)

## Environment

### Scope
- Layer: Shell + Docs
- Plugin: bash
- Risk: 35 (WARN)

### Runtime
- Language: bash (shell script)

### Dependencies (key packages)
- (none)

### Risk Interview (BLOCK only)
- (N/A - PASS判定)

## Context & Dependencies

### Reference Documents
- [skills/orchestrate/SKILL.md] - Block 2c→2d 間への Block 2c.5 挿入先
- [skills/orchestrate/reference.md] - Product Verification 詳細セクション追加先
- [skills/orchestrate/steps-subagent.md] - VERIFY ステップ追加先
- [skills/orchestrate/steps-teams.md] - VERIFY ステップ追加先
- [skills/orchestrate/steps-codex.md] - VERIFY ステップ追加先
- [skills/spec/templates/cycle.md] - `## Verification` セクション追加先

### Dependent Features
- orchestrate Block 2c (REFACTOR): VERIFY はこのステップの直後に実行
- orchestrate Block 2d (REVIEW): VERIFY の結果は advisory evidence として渡す

### Related Issues/PRs
- DISCOVERED: ROADMAP.md に ShaReco（非公開事業）への直接参照あり → issue起票予定

## Test List

### TODO
- [ ] TC-01: Cycle docテンプレートに `## Verification` セクションが存在
- [ ] TC-02: orchestrate SKILL.md の Progress Checklist に VERIFY ステップが存在
- [ ] TC-03: orchestrate SKILL.md の Workflow に Block 2c.5 が存在
- [ ] TC-04: reference.md に Product Verification セクションが存在
- [ ] TC-05: steps-subagent.md に VERIFY ステップが REFACTOR→REVIEW 間に存在
- [ ] TC-06: steps-teams.md に VERIFY ステップが REFACTOR→REVIEW 間に存在
- [ ] TC-07: Verification は non-blocking (advisory) と明記されている
- [ ] TC-08: Evidence ディレクトリが /tmp に指定されている
- [ ] TC-09: Verification セクション不在時のスキップ挙動が明記されている

### WIP
(none)

### DISCOVERED
- ROADMAP.md に ShaReco（非公開事業）への直接参照あり → 公開リポジトリから削除すべき（issue起票予定）

### DONE
(none)

## Implementation Notes

### Goal
REFACTOR後・REVIEW前に、実装結果がプロダクトとして動作するかを検証するステップを追加する。既存のVerification Gate（テスト+lint+format）はコード品質の検証だが、Product VerificationはUI描画・API応答・E2Eスモークなどのプロダクトレベル検証。

### Background
- 既存の Verification Gate はコード品質（テスト全PASS + 静的解析0件 + フォーマット）を検証
- Product Verification はプロダクト動作（UI・API・E2Eスモーク）を検証する補完的ステップ
- Cycle doc の `## Verification` セクションにコマンドを記載する駆動方式を採用
- advisory evidence（非blocking）のため、失敗してもREVIEWをブロックしない

### Design Approach

**D1: 位置** - orchestrate Block 2c (REFACTOR) と Block 2d (REVIEW) の間に Block 2c.5 (VERIFY) を挿入。

**D2: 性質** - advisory evidence。失敗してもREVIEWをブロックしない。

**D3: Cycle doc駆動** - `## Verification` セクションにbashコードブロックでコマンドを記載。セクション不在→サイレントスキップ。

**D4: エビデンス** - `/tmp/dev-crew-verify-{cycle-id}/` に保存。Cycle doc Progress Logにポインタのみ。

**D5: 新スキル不要** - orchestrateがPdMとして直接実行（YAGNI）。

## Verification

```bash
bash tests/test-product-verify.sh
# リグレッション
bash tests/test-phase-gate.sh
for f in tests/test-*.sh; do bash "$f"; done
```

## Progress Log

### 2026-03-24 08:57 - KICKOFF
- Design Review Gate: PASS (score: 10/100)
  - Scope明確（Docs + Shell tests のみ）
  - YAGNI遵守（新スキル不要、orchestrate直接実行）
  - advisory/non-blocking設計が一貫
  - テストリスト網羅的（TC-01〜TC-09、正常系/境界値/異常系）
  - リスクスコア35と変更内容が整合
- Cycle doc created

---

## Next Steps

1. [Done] INIT <- Current
2. [Next] RED
3. [ ] GREEN
4. [ ] REFACTOR
5. [ ] VERIFY (advisory)
6. [ ] REVIEW
7. [ ] COMMIT
