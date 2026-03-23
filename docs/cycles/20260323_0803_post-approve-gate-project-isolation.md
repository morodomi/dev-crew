---
feature: post-approve-gate-project-isolation
cycle: 20260323_0803
phase: DONE
complexity: trivial
test_count: 4
risk_level: low
codex_session_id: ""
issue: "#93"
created: 2026-03-23 08:03
updated: 2026-03-23 08:03
---

# Issue #93: post-approve-gate フラグのプロジェクト分離

## Scope Definition

### In Scope
- [ ] `scripts/hooks/plan-exit-flag.sh` のフラグファイル名にpwdハッシュを含める
- [ ] `scripts/hooks/post-approve-gate.sh` の同じハッシュロジックでフラグ参照・手動クリアメッセージ更新
- [ ] `skills/orchestrate/SKILL.md` Block 0のフラグ削除コマンドをハッシュ対応に更新
- [ ] `tests/test-post-approve-gate.sh` ハッシュベースのフラグ名対応 + プロジェクト分離テスト追加

### Out of Scope
- フラグのTTLや期限ロジックの変更
- 他hookスクリプトへの影響

### Files to Change (target: 10 or less)
- `scripts/hooks/plan-exit-flag.sh` (edit)
- `scripts/hooks/post-approve-gate.sh` (edit)
- `skills/orchestrate/SKILL.md` (edit)
- `tests/test-post-approve-gate.sh` (edit)

## Environment

### Scope
- Layer: Hook scripts（bash）
- Plugin: N/A
- Risk: 15 (PASS)

### Runtime
- Language: bash (shell script)

### Dependencies (key packages)
- md5 (macOS) / md5sum (Linux) - 両対応フォールバック構文を使用

### Risk Interview (BLOCK only)
- N/A（Risk Score 15 PASS のためインタビュー不要）

## Context & Dependencies

### Reference Documents
- [CONSTITUTION.md] - 原則6: 決定論的プロセス保証
- [scripts/hooks/plan-exit-flag.sh] - 修正対象。現行はグローバルパス固定
- [scripts/hooks/post-approve-gate.sh] - 修正対象。現行はグローバルパス固定
- [skills/orchestrate/SKILL.md] - Block 0のrm -fコマンド更新対象

### Dependent Features
- post-approve-gate.sh: Issue #93のバグ発端スクリプト

### Related Issues/PRs
- Issue #93

## Test List

### TODO
(none)

### WIP
(none)

### DISCOVERED
(none)

### DONE
- [x] TC-01: Given plan-exit-flag.sh実行, When フラグ作成, Then ファイル名にpwdハッシュが含まれること
- [x] TC-02: Given プロジェクトAでフラグ作成, When プロジェクトBでpost-approve-gate実行, Then ブロックされないこと（exit 0）
- [x] TC-03: Given プロジェクトAでフラグ作成, When プロジェクトAでpost-approve-gate実行, Then ブロックされること（exit 2）
- [x] TC-04: Given 期限切れフラグ, When post-approve-gate実行, Then 許可されること（exit 0）

## Implementation Notes

### Goal
`~/.claude/dev-crew/.plan-approved` フラグをプロジェクト固有にし、プロジェクトAのplan approveがプロジェクトBのEdit/WriteをブロックするバグIssue #93を修正する。

### Background
フラグファイルが全プロジェクト共通パスのため、プロジェクトAでplan approveするとプロジェクトBのEdit/Writeもブロックされる。pwdのハッシュをフラグファイル名に含めてプロジェクト固有にする。

### Design Approach
- `plan-exit-flag.sh`: `PROJECT_HASH=$(pwd | md5 -q 2>/dev/null || echo "$PWD" | md5sum | cut -d' ' -f1)` でハッシュ生成、`FLAG_FILE="${FLAG_DIR}/.plan-approved-${PROJECT_HASH}"` に変更
- `post-approve-gate.sh`: 同じハッシュロジックでフラグ参照。手動クリアメッセージも更新
- `skills/orchestrate/SKILL.md` Block 0: `rm -f "${HOME}/.claude/dev-crew/.plan-approved-${PROJECT_HASH}"` に更新
- `tests/test-post-approve-gate.sh`: プロジェクト分離テスト追加（TC-02: 異なるpwd → exit 0）

## Progress Log

### 2026-03-23 08:03 - KICKOFF
- Cycle doc created
- Design Review Gate: PASS (score 5)
- planファイル: /Users/morodomi/.claude/plans/async-scribbling-quill.md

### 2026-03-23 - RED
- tests/test-post-approve-gate.sh をハッシュベースに書き換え（TC-01〜TC-04）
- 7件失敗、6件通過（RED状態確認）
- Phase completed

### 2026-03-23 - REVIEW
- Risk: LOW (score 0)
- Security: PASS（md5は一意性確保のみ、暗号用途でない）
- Correctness: PASS（両スクリプト同一ハッシュロジック、macOS/Linux両対応）
- Codex review: スキップ（小規模バグ修正）
- Phase completed

### 2026-03-23 - COMMIT
- Phase completed

### 2026-03-23 - REFACTOR
- チェックリスト7項目確認、リファクタリング不要
- Verification Gate PASS（13件 + plugin構造6件）
- Phase completed

### 2026-03-23 - GREEN
- plan-exit-flag.sh: PROJECT_HASH導入、フラグ名を `.plan-approved-${PROJECT_HASH}` に変更
- post-approve-gate.sh: 同じハッシュロジックで参照、手動クリアメッセージ更新
- orchestrate SKILL.md: Block 0のフラグ削除コマンドをハッシュ対応に更新
- 13件全PASS
- Phase completed

---

## Next Steps

1. [Done] INIT
2. [Done] RED
3. [Done] GREEN
4. [Done] REFACTOR
5. [Done] REVIEW
6. [Done] COMMIT
