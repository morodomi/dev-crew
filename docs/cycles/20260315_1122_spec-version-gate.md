---
feature: spec-version-gate
cycle: 20260315_1122
phase: DONE
complexity: standard
test_count: 7
risk_level: low
created: 2026-03-15 11:22
updated: 2026-03-15 11:22
---

# spec バージョンチェック + onboard バージョン記録

## Scope Definition

### In Scope
- [ ] onboard/reference.md の Step 6 に `.claude/dev-crew.json` 生成を追加
- [ ] spec/SKILL.md の Step 1 にバージョンゲートを追加
- [ ] spec/reference.md にバージョン比較の詳細手順を追加
- [ ] tests/test-version-gate.sh を新規作成

### Out of Scope
- (実装コードの変更なし: ドキュメント+設定のみ)

### Files to Change (target: 10 or less)
- `skills/onboard/reference.md` (edit)
- `skills/spec/SKILL.md` (edit)
- `skills/spec/reference.md` (edit)
- `tests/test-version-gate.sh` (new)

## Environment

### Scope
- Layer: Documentation + Configuration
- Plugin: dev-crew
- Risk: 20 (PASS)

### Runtime
- Language: Shell (tests), Markdown (skills)

### Dependencies (key packages)
- jq: (system)

### Risk Interview (BLOCK only)
(N/A - Risk PASS)

## Context & Dependencies

### Reference Documents
- `skills/onboard/reference.md` - onboard手順の参照元
- `skills/spec/SKILL.md` - specスキルの定義
- `skills/spec/reference.md` - specスキルの詳細手順

### Dependent Features
(none)

### Related Issues/PRs
(none)

## Test List

### TODO
(none)

### WIP
(none)

### DISCOVERED
- [x] orchestrate Codex delegation: RED の初回実行で `codex exec --full-auto` を使ったが、debateなしのケースでも `codex exec resume --last --full-auto` を使うべき → issue #52

### DONE
- [x] TC-01: onboard/reference.md の Step 6 に `.claude/dev-crew.json` が記載されている
- [x] TC-02: onboard/reference.md に `dev_crew_version` の記録手順が含まれる
- [x] TC-03: onboard/reference.md の差分チェックテーブルに `.claude/dev-crew.json` がある
- [x] TC-04: spec/SKILL.md の Step 1 に Version Gate がある
- [x] TC-05: spec/SKILL.md に `.claude/dev-crew.json` missing 時の警告メッセージがある
- [x] TC-06: spec/reference.md にバージョン比較の詳細手順がある
- [x] TC-07: 既存 test-plugin-structure.sh が通る

## Implementation Notes

### Goal
spec起動時に `.claude/dev-crew.json` の存在とバージョンをチェックし、未セットアップを警告する。onboardでは `.claude/dev-crew.json` にインストール済みバージョンを記録する。

### Background
onboardでプロジェクトにdev-crewをセットアップした際、どのバージョンが適用済みかの記録がない。specスキルはバージョン確認なしに起動されるため、古い設定のままTDDサイクルが始まるリスクがある。

### Design Approach
- onboard: Step 6 にて `.claude/dev-crew.json` を生成し `dev_crew_version` を記録
- spec Step 1: `.claude/dev-crew.json` の存在チェック → 不在なら警告メッセージ表示
- spec reference.md: バージョン比較の詳細手順（現在バージョン vs 記録バージョン）を追記
- テスト: `tests/test-version-gate.sh` で各ドキュメントのキーワード存在を検証

## Progress Log

### 2026-03-15 11:22 - INIT
- Cycle doc created
- Scope definition ready

### Phase: RED (Codex) - Completed
**Artifacts**: tests/test-version-gate.sh (7 TCs)
**Decisions**: TC-01~06 FAIL, TC-07 (regression) PASS - Gate 1 passed
**Codex Session**: 019cef4e-8f3b-7542-a99b-1770130be29e

### Phase: GREEN (Codex) - Completed
**Artifacts**: skills/onboard/reference.md, skills/spec/SKILL.md, skills/spec/reference.md
**Decisions**: 3ファイル編集、全7テスト PASS - Gate 2 passed

### Phase: REFACTOR - Skipped
ドキュメントのみの変更、リファクタリング対象なし

### Phase: REVIEW (Claude + Codex) - Completed
**Score**: 0 (PASS)
**Codex Findings**:
- Accept: onboard jq に `// "unknown"` 追加（spec/reference.md との整合性）
- Accept: TC-06 を `installed_plugins.json` + `dev_crew_version` チェックに強化
- Reject: grep -A ウィンドウの脆さ（過剰エンジニアリング）

---

## Next Steps

1. [Done] INIT
2. [Done] RED
3. [Done] GREEN
4. [Done] REFACTOR (skipped)
5. [Done] REVIEW
6. [Next] COMMIT
