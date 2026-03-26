---
feature: fix-risk-classifier-grep-vc
cycle: 20260326_1654
phase: DONE
complexity: trivial
test_count: 2
risk_level: low
codex_session_id: ""
created: 2026-03-26 16:54
updated: 2026-03-26 17:05
---

# fix: risk-classifier.sh の grep -vc 0件時に整数比較エラー

## Scope Definition

### In Scope
- [ ] `skills/review/risk-classifier.sh` line 63 の grep -vc パターン修正
- [ ] `docs/known-gotchas.md` line 32 の対策コード例を正しいパターンに修正

### Out of Scope
- (特になし)

### Files to Change (target: 10 or less)
- `skills/review/risk-classifier.sh` (edit)
- `docs/known-gotchas.md` (edit)

## Environment

### Scope
- Layer: Shell script (Bash)
- Plugin: なし
- Risk: 10 (PASS)

### Runtime
- Language: Bash (sh)

### Dependencies (key packages)
- (外部依存なし)

### Risk Interview (BLOCK only)
- (Risk: LOW のため非該当)

## Context & Dependencies

### Reference Documents
- `skills/review/risk-classifier.sh` - 修正対象スクリプト
- `docs/known-gotchas.md` - バグパターン記載ドキュメント（修正対象）
- `tests/test-risk-classifier.sh` - 既存テストスイート

### Dependent Features
- plan-review スキル: risk-classifier.sh を呼び出す

### Related Issues/PRs
- (なし)

## Test List

### TODO
(none)

### WIP
(none)

### DONE
- [x] TC-01 (T-08): Empty file list produces valid integer for file_count
- [x] TC-02 (T-09): All files are fixture files (0 real files)

### DISCOVERED
(none)

### DONE
(none)

## Implementation Notes

### Goal
`risk-classifier.sh` の `grep -vc` が0件ヒット時に整数比較エラーが発生するバグを修正する。

### Background
`risk-classifier.sh` 63行目で `grep -vc` が0件ヒット時に exit code 1 + stdout "0" を返し、`|| echo "0"` が追加の "0" を出力するため `file_count="0\n0"` となる。整数比較 `[ "$file_count" -gt 5 ]` が失敗し、plan review が実行できない。

加えて `docs/known-gotchas.md` にバグパターンが「対策」として記載されており、同じバグを再生産するリスクがある。

### Design Approach

**risk-classifier.sh line 63 修正:**

Before:
```bash
file_count=$(grep -vcE '\.(scm|fixture|snap|mock|seed)$|fixtures/|__snapshots__/' "$FILES_LIST" 2>/dev/null || echo "0")
```

After:
```bash
file_count=$(grep -vcE '\.(scm|fixture|snap|mock|seed)$|fixtures/|__snapshots__/' "$FILES_LIST" 2>/dev/null) || file_count=0
```

根拠: 70行目の `has_modified` が同じパターンで正しく動作している。

**docs/known-gotchas.md line 32 修正:**

Before:
```bash
count=$(grep -c 'pattern' file 2>/dev/null || echo "0")
```

After:
```bash
count=$(grep -c 'pattern' file 2>/dev/null) || count=0
```

## Verification

```bash
bash tests/test-risk-classifier.sh
```

Evidence: 9/9 PASS (T-01~T-09)

## Progress Log

### 2026-03-26 16:54 - INIT
- Cycle doc created
- Scope definition ready

### 2026-03-26 16:56 - RED
- T-08, T-09 追加。T-08 FAIL確認（バグ再現）

### 2026-03-26 16:58 - GREEN
- risk-classifier.sh line 63: `|| echo "0"` → `) || file_count=0`
- risk-classifier.sh line 82: dir_count パイプも同パターン修正
- known-gotchas.md: 対策コード例を正しいパターンに修正
- 9/9 PASS

### 2026-03-26 17:00 - REFACTOR
- チェックリスト全項目確認、改善不要
- Verification Gate PASS (9/9)
- Phase completed

### 2026-03-26 17:05 - REVIEW
- Correctness: PASS (25), Security: PASS (0)
- Aggregate: PASS (12)
- Phase completed

---

## Next Steps

1. [Done] INIT
2. [Done] PLAN
3. [Done] RED
4. [Done] GREEN
5. [Done] REFACTOR
6. [Done] REVIEW
7. [Done] COMMIT
