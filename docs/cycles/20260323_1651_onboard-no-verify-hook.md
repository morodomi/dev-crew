---
feature: onboard-no-verify-hook
cycle: 20260323_1651
phase: DONE
complexity: trivial
test_count: 3
risk_level: low
codex_session_id: ""
created: 2026-03-23 16:51
updated: 2026-03-23 17:00
---

# Issue #88: onboardテンプレートにno-verify-guard hook推奨追加

## Scope Definition

### In Scope
- [ ] `.claude/hooks/recommended.md` を更新: PreToolUse/Bashにおいてインラインのcaseをno-verify-guard.shスクリプト参照に変更。インライン版はfallbackとして残す
- [ ] Hook一覧テーブルにno-verify-guard.shの説明を追加
- [ ] `skills/onboard/reference.md` Step 6の説明文を更新（決定論的ブロックの語句を追加）
- [ ] `tests/test-onboard-no-verify-hook.sh` を新規作成

### Out of Scope
- no-verify-guard.sh スクリプト自体の変更（Phase 26実装済み）
- recommended.md 以外のhookファイルの変更

### Files to Change (target: 10 or less)
- `.claude/hooks/recommended.md` (edit)
- `skills/onboard/reference.md` (edit)
- `tests/test-onboard-no-verify-hook.sh` (new)

## Environment

### Scope
- Layer: Backend (shell script / markdown)
- Plugin: N/A (Documentation + Template)
- Risk: 15 (PASS)

### Runtime
- Language: bash (hook scripts)

### Dependencies (key packages)
- N/A (テンプレート・ドキュメント更新のみ)

### Risk Interview (BLOCK only)
- N/A (PASS判定)

## Context & Dependencies

### Reference Documents
- `scripts/hooks/no-verify-guard.sh` - 参照対象スクリプト本体
- `ROADMAP.md` Phase 26 - 「onboardテンプレートにも推奨hookとして追加」
- `CONSTITUTION.md` 原則6 - 決定論的プロセス保証

### Dependent Features
- Phase 26: no-verify-guard.sh 実装（20260323_0031_no-verify-guard.md）

### Related Issues/PRs
- Issue #88: onboardテンプレートにno-verify-guard hookを推奨hookとして追加

## Test List

### TODO
(none)

### WIP
(none)

### DISCOVERED
(none)

### DONE
- [x] TC-01: Given recommended.md, When grepで "no-verify-guard" を検索, Then マッチすること
- [x] TC-02: Given recommended.md, When JSONブロックを抽出, Then PreToolUse/Bash hookにno-verify関連エントリがあること
- [x] TC-03: Given onboard reference.md Step 6, When hookの説明を確認, Then 決定論的ブロックの記述があること

## Implementation Notes

### Goal
onboardスキルが新規プロジェクトに配布する推奨hookテンプレートに、Phase 26で実装済みの `no-verify-guard.sh` を反映する。

### Background
Phase 26で `scripts/hooks/no-verify-guard.sh` を実装済み。現状の `.claude/hooks/recommended.md` には既にインライン版のno-verifyガードがあるが、`no-verify-guard.sh` スクリプトの存在やdev-crewプラグインとしての利用方法が明記されていない。ROADMAP Phase 26の残タスクとして対応が必要。

### Design Approach
1. `recommended.md` のPreToolUse/Bash hookにスクリプト参照エントリを追加。インライン版はポータビリティのためfallbackとして残す（スクリプトがない環境向け）
2. Hook一覧テーブルに `no-verify-guard.sh` の行を追加
3. `onboard/reference.md` Step 6の説明文に「決定論的ブロック」の語句を追記
4. `tests/test-onboard-no-verify-hook.sh` でドキュメント内容の存在を検証

**WARN (Design Review Gate)**: `no-verify-guard.sh` は `--no-verify` のみを検出する。`rm -rf` と `--force` の検出はインライン版に依存するため、インライン版の完全削除は不可。実装時に注意すること。

## Progress Log

### 2026-03-23 16:51 - KICKOFF
- Cycle doc created
- Design Review Gate: WARN (スコア30)
- WARN: `no-verify-guard.sh` は `--no-verify` のみ対象。`rm -rf`・`--force` はインラインcaseに残存させること
- Scope definition ready

### 2026-03-23 17:00 - RED
- tests/test-onboard-no-verify-hook.sh 新規作成（TC-01〜TC-03）
- 3件全FAIL確認（RED状態）

### 2026-03-23 17:00 - GREEN
- .claude/hooks/recommended.md: no-verify-guard.shスクリプト参照追加、Hook一覧テーブル更新
- skills/onboard/reference.md: Step 6に「決定論的ブロック」の語句追加
- 3件全PASS

### 2026-03-23 17:00 - REFACTOR
- チェックリスト7項目確認、リファクタリング不要
- Verification Gate PASS（新規3件 + 既存12件 + plugin構造6件）
- Phase completed

### 2026-03-23 17:00 - REVIEW
- Risk: LOW (score 0)
- Security: PASS（Markdown/テストのみ）
- Correctness: PASS（インライン版残存、スクリプト参照追加）
- Score: PASS
- DISCOVERED: .claude/ が .gitignore 対象のため recommended.md は git追跡外（プラグイン配布で管理、既知の構造）
- Phase completed

---

## Next Steps

1. [Done] KICKOFF
2. [Done] RED
3. [Done] GREEN
4. [Done] REFACTOR
5. [Done] REVIEW
6. [Done] COMMIT

### 2026-03-23 17:00 - COMMIT
- Codex review: スキップ（ドキュメント変更のみ、ユーザー判断）
- Phase completed
