---
feature: no-verify-guard
cycle: 20260323_0031
phase: DONE
complexity: trivial
test_count: 12
risk_level: low
codex_session_id: ""
created: 2026-03-23 00:31
updated: 2026-03-23 00:31
---

# Phase 26: --no-verify hook（決定論的ブロック）

## Scope Definition

### In Scope
- [ ] `scripts/hooks/no-verify-guard.sh` の新規作成（PreToolUse Bash hook）
- [ ] `hooks/hooks.json` への PreToolUse Bash matcher エントリ追加
- [ ] `tests/test-no-verify-guard.sh` の新規作成（8ケース）
- [ ] `CLAUDE.md` Hooks テーブルへの no-verify-guard 行追加
- [ ] `docs/STATUS.md` Phase 26 完了・Test Scripts カウント更新

### Out of Scope
- rules/git-safety.md の変更（既存ルールで十分）
- git コマンド限定の絞り込み（安全側に倒して全ブロック）

### Files to Change (target: 10 or less)
- `scripts/hooks/no-verify-guard.sh` (new)
- `hooks/hooks.json` (edit)
- `tests/test-no-verify-guard.sh` (new)
- `CLAUDE.md` (edit)
- `docs/STATUS.md` (edit)

## Environment

### Scope
- Layer: CLI（シェルスクリプト + hooks設定）
- Plugin: N/A（シェルスクリプトのみ）
- Risk: 15 (PASS)

### Runtime
- Language: bash (shell script)

### Dependencies (key packages)
- jq（observe.sh で既に使用中。jq不在時はINPUT全体をgrepするフォールバック）

### Risk Interview (BLOCK only)
- N/A（Risk Score 15 PASS のためインタビュー不要）

## Context & Dependencies

### Reference Documents
- [ROADMAP.md] - v2.8 Phase 26 定義
- [CONSTITUTION.md] - 原則6: 決定論的プロセス保証
- [scripts/hooks/post-approve-gate.sh] - 実装パターン参照（PreToolUse exit 2 パターン）
- [hooks/hooks.json] - 既存hook設定。PreToolUse セクションに追記する
- [.claude/rules/git-safety.md] - --no-verify 禁止ルール（hook で決定論的に強制）

### Dependent Features
- post-approve-gate.sh: 同じ PreToolUse exit 2 パターンを先行実装

### Related Issues/PRs
- ROADMAP.md v2.8 Phase 26

## Test List

### TODO
- [ ] TC-01: `git commit -m "msg"`（--no-verify なし）→ exit 0（許可）
- [ ] TC-02: `git commit --no-verify -m "msg"` → exit 2（ブロック）
- [ ] TC-03: `git push --no-verify` → exit 2（ブロック）
- [ ] TC-04: `echo "--no-verify"`（git コマンドではない）→ exit 2（ブロック・安全側）
- [ ] TC-05: `grep --no-verify file.txt`（誤検知候補）→ exit 2（ブロック・--no-verify 自体を全遮断）
- [ ] TC-06: 空入力 → exit 0（許可）
- [ ] TC-07: ネストされたJSON `{"tool_input":{"command":"git commit --no-verify"}}` → exit 2（jqパース検証）
- [ ] TC-08: pretty-print JSON（改行・インデント付き）→ exit 2（フォーマット耐性）
- [ ] TC-09: jq不在時にINPUT全体からfallback検出 → exit 2（フォールバック検証）
- [ ] TC-10: hooks.json に no-verify-guard エントリが存在する → PASS
- [ ] TC-11: hooks.json に post-approve-gate エントリも共存している → PASS（既存hook保護）
- [ ] TC-12: CLAUDE.md Hooks テーブルに no-verify-guard が存在する → PASS

### WIP
(none)

### DISCOVERED
- onboard テンプレートへの推奨hook追加（ROADMAP記載あり、本サイクルではスコープ外）

### DONE
(none)

## Implementation Notes

### Goal
`--no-verify` を含む Bash コマンドを PreToolUse hook で決定論的にブロックする。LLMがルールを無視するリスクをゼロにする。

### Background
`--no-verify` は rules/git-safety.md で禁止されているが、LLMがルールを無視するリスクがある。CONSTITUTION 原則6「決定論的プロセス保証」に従い、post-approve-gate.sh と同じパターンで PreToolUse hook による決定論的ブロックに昇格する。

### Design Approach
- `scripts/hooks/no-verify-guard.sh`: stdin から tool_input（JSON）を読み取り、`--no-verify` を検出したら exit 2 でブロック。post-approve-gate.sh のパターンを踏襲。
- `hooks/hooks.json` の PreToolUse セクションに Bash マッチャーを追加。
- テストは `test-post-approve-gate.sh` のパターンを流用し Given/When/Then 形式で実装。
- stdin JSON のパース: jq 優先（`.tool_input.command // ""`）+ jq不在時はINPUT全体grep（安全側フォールバック）。observe.sh のパターンと一貫性を保つ。
- `--no-verify-signatures` 等もブロック対象（over-blocking で安全側に倒す。CONSTITUTION原則6優先）。

## Progress Log

### 2026-03-23 00:31 - INIT
- Cycle doc created
- Scope definition ready

### 2026-03-23 - RED
- test-no-verify-guard.sh 作成（12ケース）
- 全テスト失敗確認（RED状態）

### 2026-03-23 - GREEN
- no-verify-guard.sh 実装（jq優先 + grepフォールバック）
- hooks.json にBash matcher追加
- CLAUDE.md Hooksテーブル更新
- 12/12 PASS + 回帰0 FAIL

### 2026-03-23 - REFACTOR
- チェックリスト全項目確認、改善不要（31行のシンプルなスクリプト）
- Verification Gate PASS
- Phase completed

### 2026-03-23 - REVIEW
- security-reviewer: PASS (score 10)
- correctness-reviewer: PASS (score 42)
- 修正: set -euo pipefail, jq失敗時fallback, TC-09環境変数フラグ方式
- 全テスト12/12 PASS + 回帰0 FAIL
- Phase completed

---

## Next Steps

1. [Done] INIT <- Current
2. [Done] PLAN (planファイルから転記済み)
3. [Next] RED
4. [ ] GREEN
5. [ ] REFACTOR
6. [ ] REVIEW
7. [ ] COMMIT
