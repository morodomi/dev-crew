---
title: "TC展開テンプレートにParadigm Selection追加"
phase: DONE
created: 2026-03-08 14:00
updated: 2026-03-08 14:15
---

# TC展開テンプレートにParadigm Selection + Contract/Property/MR欄を追加

## Background

test_architecture.md の理想形（4つの性質 + 3パラダイム: Data Contract, Property-Based Testing, Metamorphic Testing）が、red-workerのTC展開テンプレートに反映されていない。red-worker Step 0 で2領域分類は行うが、その分類結果がTC展開に引き継がれず、毎回example-basedテストに落ちる。

検証はexspecに委譲する設計（疎結合）。dev-crewの責務は「生成ガイド」のみ。

## Scope

### In Scope

1. `skills/red/reference.md`: TC展開テンプレートにParadigm Selection + Contract/Property/MR記述欄を追加
2. `agents/red-worker.md`: Step 0の分類結果をTC展開に引き継ぐフローを明記
3. `MorodomiHoldings/docs/test_architecture.md`: SSOT としてコピー（済）

### Out of Scope

- exspecルールの変更（別リポジトリ）
- Skip基準（trivial関数のContract省略）→ 運用後に別サイクルで対応
- Test Plan Review (Stage 2) の強化 → exspec Tier 2 完成後に対応
- Verification Gate への4性質チェック追加 → exspec が担う

## Design

### TC展開テンプレート（変更後）

```markdown
### TC-XX: [テストケース名]

- **Given**: [前提条件 + 具体データ]
- **When**: [操作 + 具体入力値]
- **Then**: [期待結果 + 具体出力値]
- **Category**: [正常系 / 異常系 / 境界値 / 権限 / セキュリティ]
- **Paradigm**: [Contract / Property / Metamorphic / Example]
- **Invariant**: [不変量の記述（Property/Metamorphic時。Example時は省略可）]
- **Test File**: [tests/xxx_test.{ext}]
```

### red-worker Step 0 → TC展開の接続

Step 0で決定論的/確率的を判定 → 判定結果に基づきParadigm欄のデフォルトを設定:
- 決定論的 → Contract + Property 優先
- 確率的 → Metamorphic Relation 優先
- バグ修正 → Example（再現テスト）優先

## Test List

### TODO

### WIP

### DONE
- [x] TC-01: reference.md TC展開テンプレートに Paradigm 欄が存在する
- [x] TC-02: reference.md TC展開テンプレートに Invariant 欄が存在する
- [x] TC-03: red-worker.md に Paradigm Selection が TC展開に引き継がれる記述がある
- [x] TC-04: MorodomiHoldings/docs/test_architecture.md が存在する（SSOT）
- [x] TC-05: reference.md が authority source を参照している（回帰）
- [x] TC-06: reference.md が2領域モデルを保持している（回帰）
- [x] TC-07: reference.md が言語別ツールマッピングを保持している（回帰）

## Progress Log

### 2026-03-08 14:00 - KICKOFF
- Cycle doc created
- test_architecture.md copied to MorodomiHoldings/docs/
- Phase completed

### 2026-03-08 14:10 - RED
- Test script created: tests/test-paradigm-selection.sh (7 TCs)
- 3 tests failing (TC-01, TC-02, TC-03), 4 passing (TC-04~07 regression)
- Phase completed

### 2026-03-08 14:15 - GREEN
- reference.md: TC template に Paradigm + Invariant 欄追加、Paradigm Selection ガイド追加
- reference.md: Cycle doc記録フォーマット例にも Paradigm + Invariant 追加
- red-worker.md: Step 0 分類結果を Paradigm 欄に引き継ぐフロー追加、Step 3 にパラダイム別テスト作成指針追加
- All 7 tests PASS, architecture-dedup regression 7/7 PASS
- Phase completed

### 2026-03-08 14:20 - REVIEW
- Security review: PASS (score 0, 0 issues)
- Correctness review: PASS (score 25, 1 important + 2 optional)
- Fixed: Cycle doc Design節のInvariant説明文を実装に合わせて統一
- Fixed: TC-03の検証を「Paradigm欄に反映」文言の直接grepに改善
- All 14 tests PASS (paradigm-selection 7/7 + architecture-dedup 7/7)
- Phase completed
