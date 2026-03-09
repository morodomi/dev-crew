---
title: "Skip基準 + Test Plan Review paradigm alignment"
phase: DONE
created: 2026-03-08 14:30
updated: 2026-03-08 14:30
---

# Skip基準 + Test Plan Review paradigm alignment追加

## Background

前サイクル(dbabba1)でParadigm Selection + Contract/Property/MR欄をTC展開テンプレートに追加済み。
残りの2点を対応:

1. **Skip基準**: trivial関数（純粋関数かつI/Oがプリミティブ型のみ）にContract/Propertyを強制するとコンテキスト浪費。省略基準を明示する（Geminiの指摘）
2. **Test Plan Review (Stage 2) 強化**: レビューチェックリストにparadigm alignment項目を追加。Plan段階でmock地獄計画が素通りする問題を防ぐ（Grokの指摘）

## Scope

### In Scope

1. `skills/red/reference.md`: Paradigm Selectionガイドに Skip基準を追加
2. `skills/red/reference.md`: Test Plan Reviewチェックリストに paradigm alignment項目を追加

### Out of Scope

- red-worker.md の変更（今回はreference.mdのみ）
- exspecルールの変更

## Design

### Skip基準

Paradigm Selectionガイドの末尾に追加:

| 条件 | Paradigm | 理由 |
|------|----------|------|
| 純粋関数 + I/Oがプリミティブ型のみ | Example（またはProperty） | Contract定義のコストがテストの価値を上回る |
| ユーティリティ関数（文字列操作等） | Example | スキーマ定義不要 |

### Test Plan Review paradigm alignment

チェックリストテーブルに行追加:

| 6 | Paradigm整合性 | 決定論的コードにContract/Propertyが、確率的コードにMetamorphicが選択されているか |

## Test List

### TODO

### WIP

### DONE
- [x] TC-01: reference.md Paradigm Selectionガイドに Skip基準が存在する
- [x] TC-02: reference.md Test Plan Reviewチェックリストに paradigm alignment項目が存在する
- [x] TC-03: reference.md が2領域モデルを保持している（回帰）
- [x] TC-04: reference.md が言語別ツールマッピングを保持している（回帰）
- [x] TC-05: 前サイクルのテスト(test-paradigm-selection.sh)が全PASS（回帰）

## Progress Log

### 2026-03-08 14:30 - KICKOFF
- Cycle doc created
- Phase completed

### 2026-03-08 14:35 - RED
- Test script created: tests/test-skip-criteria-tp-review.sh (5 TCs)
- 2 tests failing (TC-01, TC-02), 3 passing (TC-03~05 regression)
- Phase completed

### 2026-03-08 14:40 - GREEN
- reference.md: Paradigm SelectionガイドにSkip基準テーブル追加
- reference.md: Test Plan Reviewチェックリストに Paradigm整合性(#6) 追加
- All 5 tests PASS, architecture-dedup 7/7 PASS, paradigm-selection 7/7 PASS
- Phase completed

### 2026-03-08 14:45 - REVIEW
- Correctness review: PASS (score 12, 2 important + 2 optional)
- Fixed: 「ユーティリティ関数」行を「純粋関数+プリミティブ」行に統合（重複排除）
- Fixed: 「ボーイスカウト」行を削除（Paradigm Selectionテーブルの「バグ修正→Example」と二重）
- All 19 tests PASS (skip-criteria 5/5 + paradigm-selection 7/7 + architecture-dedup 7/7)
- Phase completed
