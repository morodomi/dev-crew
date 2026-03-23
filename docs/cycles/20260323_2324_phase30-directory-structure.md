---
feature: directory-structure
cycle: phase30-directory-structure
phase: DONE
complexity: trivial
test_count: 9
risk_level: low
codex_session_id: ""
created: 2026-03-23 23:24
updated: 2026-03-23 23:24
---

# Phase 30: ディレクトリ構造厳格化

## Scope Definition

### In Scope
- [ ] `tests/test-directory-structure.sh` 新規作成 (TC-DS01〜DS09)
- [ ] `scripts/validate-cycle-frontmatter.sh` 拡張 (feature/cycle/created/updated 存在チェック追加)
- [ ] `skills/onboard/validation.md` 更新 (#8: docs/cycles/ 命名規約チェック追加)
- [ ] `skills/onboard/reference.md` 更新 (Cycle doc命名規約の明示)

### Out of Scope
- 旧形式Cycle docの移行 (Reason: Grandfathering方針。D1参照)
- docs/cycles/archive/ の検証 (Reason: D2参照)
- 本文の必須セクション検証 (Reason: fragile。D3参照)

### Files to Change (target: 10 or less)
- `tests/test-directory-structure.sh` (new)
- `scripts/validate-cycle-frontmatter.sh` (edit)
- `skills/onboard/validation.md` (edit)
- `skills/onboard/reference.md` (edit)

## Environment

### Scope
- Layer: Shell + Docs
- Plugin: bash
- Risk: 15 (PASS)

### Runtime
- Language: bash (macOS/Linux portable)

### Dependencies (key packages)
- (none)

### Risk Interview (BLOCK only)
- (N/A - PASS)

## Context & Dependencies

### Reference Documents
- `tests/test-plugin-structure.sh` - テストパターン参照元
- `tests/test-frontmatter-integrity.sh` - TC-I1〜I11 リグレッション対象
- `scripts/validate-cycle-frontmatter.sh` - 拡張対象 (現在: phase/complexity/test_count/risk_level値検証)
- `skills/spec/templates/cycle.md` - 正規のfrontmatterテンプレート
- `skills/onboard/validation.md` - 既存7チェック項目

### Dependent Features
- Phase 31 (Product Verification PoC) - 本Phaseが構造契約の前提となる

### Related Issues/PRs
- (none)

## Test List

### TODO
- [ ] TC-DS01: docs/cycles/ ディレクトリが存在する
- [ ] TC-DS02: 全Cycle docファイル名が YYYYMMDD_HHMM_*.md パターンに一致 (archive/除外)
- [ ] TC-DS03: 新形式Cycle docが必須frontmatterフィールドを持つ (feature, cycle, created, updated)
- [ ] TC-DS04: [Negative] 不正なファイル名パターンを検出 (fixture)
- [ ] TC-DS05: [Negative] 必須frontmatterフィールド欠落を検出 (fixture)
- [ ] TC-DS06: 旧形式Cycle doc (status:/title:) がスキップされる
- [ ] TC-DS07: archiveディレクトリのdocがスキップされる
- [ ] TC-DS08: frontmatterなしのCycle docがスキップされる
- [ ] TC-DS09: ファイル名のタイムスタンプが妥当な範囲 (月01-12, 日01-31, 時00-23, 分00-59)

### WIP
(none)

### DISCOVERED
(none)

### DONE
(none)

## Implementation Notes

### Goal
docs/cycles/ の構造規約を検証スクリプトで決定論的に強制する。Phase 31 (Product Verification PoC) の前提となる構造契約。

### Background
v2.6.0リリース後の品質強化。実態調査で以下の問題が判明:
- Phase 29等の旧形式frontmatter (title/date/status) が混在
- 一部Cycle docにfrontmatter自体がない (Phase 13, 14等)
- ファイル命名パターンの検証なし

### Design Approach

**D1: Grandfathering** - 旧形式Cycle docは検証対象外。新テンプレート形式 (`feature:` フィールドあり) のみ検証。完了済みサイクルの移行はリスクに見合わない。

**D2: Archive skip** - `docs/cycles/archive/` は検証対象外。

**D3: Machine-critical invariants のみ**

| Invariant | Level |
|-----------|-------|
| ファイル名 `YYYYMMDD_HHMM_*.md` | machine-critical |
| 必須frontmatter (feature, cycle, phase, complexity, test_count, risk_level, created, updated) | machine-critical |
| 有効なphase値 | machine-critical (既存validator) |
| 本文の必須セクション | 対象外 (fragile) |

**D4: 新形式検出ロジック** - frontmatter内に `feature:` があれば新形式とみなし検証。なければスキップ。

**validate-cycle-frontmatter.sh の拡張**

既存の `fm_val()` ヘルパーを再利用。phase検証の前に4フィールドの存在チェックを追加:
```bash
# 0. required field presence
for FIELD in feature cycle created updated; do
  VAL=$(fm_val "$FIELD")
  if [ -z "$VAL" ]; then
    error "required field missing or empty: '$FIELD'"
  fi
done
```

**新形式検出ロジック (test-directory-structure.sh)**
```bash
is_new_format() {
  local file="$1"
  head -20 "$file" | sed -n '/^---$/,/^---$/p' | grep -q "^feature:"
}
```

**ファイル名バリデーション (ポータブル)**
macOS/Linux両対応のため `date` コマンドでなく正規表現でバリデーション:
```
^[0-9]{4}(0[1-9]|1[0-2])(0[1-9]|[12][0-9]|3[01])_([01][0-9]|2[0-3])[0-5][0-9]_.+\.md$
```

## Progress Log

### 2026-03-23 23:24 - KICKOFF
- Design Review Gate: PASS (score: 10/100)
- Cycle doc created
- Scope definition confirmed

### 2026-03-23 23:24 - SYNC-PLAN
- sync-plan completed: Cycle doc generated from plan file
- Plan Review: PASS (score: 10/100)
- Phase completed

---

## Next Steps

1. [Done] KICKOFF
2. [Done] RED
3. [Done] GREEN
4. [Done] REFACTOR
5. [Done] REVIEW (Security: PASS 8, Correctness: WARN 72, Aggregate: PASS 40)
6. [Done] COMMIT
