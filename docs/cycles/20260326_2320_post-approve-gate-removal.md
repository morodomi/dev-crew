---
feature: post-approve-gate-removal
cycle: 20260326_2320
phase: DONE
complexity: standard
test_count: 6
risk_level: medium
codex_session_id: ""
created: 2026-03-26 23:20
updated: 2026-03-26 23:30
---

# post-approve-gate フラグ廃止 + orchestrate TaskCreate 導入

## Scope Definition

### In Scope
- [ ] scripts/hooks/plan-exit-flag.sh を削除
- [ ] scripts/hooks/post-approve-gate.sh を削除
- [ ] hooks/hooks.json から ExitPlanMode エントリと post-approve-gate エントリを削除
- [ ] skills/orchestrate/SKILL.md Block 0 のフラグ解除コマンドを TaskCreate 指示に置換
- [ ] skills/orchestrate/reference.md の G-04 行を削除し TaskCreate/TaskUpdate 使用パターンを追記
- [ ] CLAUDE.md Hooks テーブルから plan-exit-flag, post-approve-gate の2行を削除
- [ ] .claude/rules/post-approve.md の hook ブロック記述を convention 記述に変更
- [ ] tests/test-post-approve-gate.sh を削除
- [ ] tests/test-hooks-structure.sh から TC-11, TC-12 を削除

### Out of Scope
- フラグ廃止以外の hook 構成変更（スコープ外）
- orchestrate の実行ロジック変更（TaskCreate/TaskUpdate の追加のみ）

### Files to Change
- scripts/hooks/plan-exit-flag.sh (DELETE)
- scripts/hooks/post-approve-gate.sh (DELETE)
- hooks/hooks.json (edit)
- skills/orchestrate/SKILL.md (edit)
- skills/orchestrate/reference.md (edit)
- CLAUDE.md (edit)
- .claude/rules/post-approve.md (edit)
- tests/test-post-approve-gate.sh (DELETE)
- tests/test-hooks-structure.sh (edit)

## Environment

### Scope
- Layer: Shell script + JSON + Markdown
- Plugin: N/A（スクリプト・設定ファイル直接編集）
- Risk: MEDIUM（hook 構成変更、複数ファイル影響）

### Runtime
- Language: bash / JSON / Markdown

### Dependencies (key packages)
- なし（外部依存なし）

### Risk Interview (BLOCK only)
- 該当なし（MEDIUM のため BLOCK インタビューなし）

## Context & Dependencies

### Reference Documents
- hooks/hooks.json - hook 構成の実態
- skills/orchestrate/SKILL.md - orchestrate スキル定義
- skills/orchestrate/reference.md - orchestrate 詳細リファレンス
- CLAUDE.md - プラグイン全体の設定
- .claude/rules/post-approve.md - Post-Approve Action ルール

### Dependent Features
- orchestrate: skills/orchestrate/SKILL.md（Block 0 の変更）
- TDD Workflow: フラグ廃止後も convention ルールで Post-Approve Action を強制

### Related Issues/PRs
- なし

## Test List

### TODO
- [ ] TC-01: hooks.json に ExitPlanMode エントリがない
- [ ] TC-02: hooks.json に post-approve-gate エントリがない
- [ ] TC-03: plan-exit-flag.sh が存在しない
- [ ] TC-04: post-approve-gate.sh が存在しない
- [ ] TC-05: orchestrate SKILL.md に TaskCreate 指示がある
- [ ] TC-06: 既存テスト回帰 (test-hooks-structure.sh 全PASS)

### WIP
(none)

### DISCOVERED
(none)

### DONE
(none)

## Implementation Notes

### Goal
post-approve-gate のフラグ機構（plan approve 後に Edit/Write をブロック）を廃止し、orchestrate で TaskCreate/TaskUpdate を使って TDD サイクルの進捗を可視化する。

### Background
post-approve-gate は Bash の echo/heredoc でバイパス可能なため、LLM に対する強制力がない。フラグ管理を廃止し、Post-Approve Action は rules/post-approve.md のルール記述（convention）で十分とする判断。

### Design Approach

#### A. フラグ機構の除去

hooks.json の変更:

Before:
```json
{
  "hooks": {
    "PostToolUse": [
      { "matcher": "ExitPlanMode", "hooks": [{ "command": "...plan-exit-flag.sh" }] },
      { "matcher": "Edit|Write|Bash", "hooks": [{ "command": "...observe.sh" }] }
    ],
    "PreToolUse": [
      { "matcher": "Edit|Write", "hooks": [{ "command": "...post-approve-gate.sh" }] },
      { "matcher": "Bash", "hooks": [{ "command": "...no-verify-guard.sh" }] }
    ]
  }
}
```

After:
```json
{
  "hooks": {
    "PostToolUse": [
      { "matcher": "Edit|Write|Bash", "hooks": [{ "command": "...observe.sh" }] }
    ],
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [{ "command": "...no-verify-guard.sh" }] }
    ]
  }
}
```

orchestrate SKILL.md Block 0 変更:

Before:
```
**最初に実行**: `DATA_DIR=... && rm -f "${DATA_DIR}/.plan-approved-${PROJECT_HASH}"` で post-approve gate フラグを解除する。
```

After:
```
**最初に実行**: TaskCreate で TDD サイクルのタスクを登録する。

タスク一覧:
1. sync-plan (Cycle doc 生成)
2. plan-review (設計レビュー)
3. RED (テスト作成)
4. GREEN (実装)
5. REFACTOR (品質改善)
6. REVIEW (コードレビュー)
7. COMMIT (コミット)

各 Block 開始時に TaskUpdate(status: "in_progress")、完了時に TaskUpdate(status: "completed")。
```

.claude/rules/post-approve.md 変更:

Before: `Edit/Write は orchestrate 起動まで hook でブロックされる。`
After: `Edit/Write を直接行わず、必ず /orchestrate に委譲すること。`

#### B. テスト整理

- tests/test-post-approve-gate.sh を削除
- tests/test-hooks-structure.sh から TC-11（plan-exit-flag.sh 存在確認）、TC-12（post-approve-gate.sh 存在確認）を削除

## Verification

```bash
bash /Users/morodomi/Projects/MorodomiHoldings/agents/dev-crew/tests/test-hooks-structure.sh
```

Evidence: 31/31 PASS (gate-removal 6 + hooks-structure 10 + post-approve-action 15)

## Progress Log

### 2026-03-26 23:20 - INIT
- Cycle doc created

### 2026-03-26 23:22 - RED
- TC-01〜TC-06 作成、全 FAIL 確認

### 2026-03-26 23:25 - GREEN
- plan-exit-flag.sh, post-approve-gate.sh, test-post-approve-gate.sh 削除
- hooks.json, SKILL.md, reference.md, CLAUDE.md, post-approve.md, test-hooks-structure.sh 更新
- 31/31 PASS

### 2026-03-26 23:28 - REVIEW
- PASS (docs/config removal, no security risk)
- Phase completed

---

## Next Steps

1. [Done] INIT
2. [Done] PLAN
3. [Done] RED
4. [Done] GREEN
5. [Done] REFACTOR (skip - removal only)
6. [Done] REVIEW
7. [Done] COMMIT
