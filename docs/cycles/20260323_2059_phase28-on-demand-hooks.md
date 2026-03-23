---
feature: phase28-on-demand-hooks
cycle: 20260323_2059
phase: DONE
complexity: standard
test_count: 13
risk_level: low
codex_session_id: ""
created: 2026-03-23 20:59
updated: 2026-03-23 20:59
---

# v2.6 Phase 28: On-demand hooks フィージビリティスパイク

## Scope Definition

### In Scope
- [ ] `skills/careful/SKILL.md` 新規作成: on-demand hook 付きスキル (frontmatter hooks 構文)
- [ ] `scripts/hooks/careful-guard.sh` 新規作成: 破壊コマンド検出・ブロック
- [ ] `tests/test-careful-hook.sh` 新規作成: hook スクリプトの検出ロジックテスト (T-01〜T-10)
- [ ] `.claude-plugin/marketplace.json` 編集: careful スキル追加

### Out of Scope
- SKILL.md frontmatter hooks が未サポートの場合の代替実装（Phase 28 Close 後に ADR 記録）
- careful スキル以外への on-demand hooks 適用
- 既存グローバル hooks の変更

### Files to Change (target: 10 or less)
- `skills/careful/SKILL.md` (new)
- `scripts/hooks/careful-guard.sh` (new)
- `tests/test-careful-hook.sh` (new)
- `.claude-plugin/marketplace.json` (edit)

## Environment

### Scope
- Layer: Plugin infrastructure (shell + YAML)
- Plugin: dev-crew (hooks system)
- Risk: 5 (PASS)

### Runtime
- Language: bash (hook script + test), YAML frontmatter (SKILL.md)

### Dependencies (key packages)
- jq: JSON stdin パース (no-verify-guard.sh 同様)
- bash: hook スクリプト実行環境

### Risk Interview (BLOCK only)
- N/A (PASS判定)

## Context & Dependencies

### Reference Documents
- Anthropic Skills Best Practices (Thariq, 2026-03): 「Skills can include hooks that are only activated when the skill is called」
- `scripts/hooks/no-verify-guard.sh`: careful-guard.sh の設計パターン元
- ROADMAP.md Phase 28 - On-demand hooks PoC

### Dependent Features
- Phase 26: no-verify-guard hook (20260323_1651_onboard-no-verify-hook.md) — careful-guard.sh の設計パターン源
- Phase 27: Gotchas 体系化 (20260323_2007_phase27-gotchas-structure.md)

### Related Issues/PRs
- v2.6 Phase 28 (plan file: parsed-seeking-steele.md)

## Test List

### TODO
- [ ] T-01: Given `{"tool_input":{"command":"rm -rf /tmp/safe"}}`, When careful-guard.sh, Then exit 0 (safe path, not blocked)
- [ ] T-02: Given `{"tool_input":{"command":"rm -rf /"}}`, When careful-guard.sh, Then exit 2 (blocked)
- [ ] T-03: Given `{"tool_input":{"command":"rm -rf ~/"}}`, When careful-guard.sh, Then exit 2 (blocked)
- [ ] T-04: Given `{"tool_input":{"command":"DROP TABLE users"}}`, When careful-guard.sh, Then exit 2 (blocked)
- [ ] T-05: Given `{"tool_input":{"command":"git push --force origin main"}}`, When careful-guard.sh, Then exit 2 (blocked)
- [ ] T-06: Given `{"tool_input":{"command":"git push --force-with-lease"}}`, When careful-guard.sh, Then exit 0 (allowed)
- [ ] T-07: Given `{"tool_input":{"command":"git reset --hard HEAD"}}`, When careful-guard.sh, Then exit 2 (blocked)
- [ ] T-08: Given `{"tool_input":{"command":"kubectl delete pod foo"}}`, When careful-guard.sh, Then exit 2 (blocked)
- [ ] T-09: Given `{"tool_input":{"command":"echo hello"}}`, When careful-guard.sh, Then exit 0 (safe command)
- [ ] T-10: Given `skills/careful/SKILL.md`, When frontmatter を確認, Then `hooks:` セクションが存在すること

### WIP
(none)

### DISCOVERED
(none)

### DONE
(none)

## Implementation Notes

### Goal
SKILL.md frontmatter の `hooks:` 構文を使った on-demand hooks を `/careful` スキルで PoC する。スキル呼び出し時のみ破壊コマンド検出 hook が有効になることを検証する。

### Background
Thariq (Anthropic, 2026-03) が「Skills can include hooks that are only activated when the skill is called」と明言。Claude Code は SKILL.md frontmatter に `hooks:` フィールドをサポートしており、スキル呼び出し時のみ有効になる on-demand hooks を定義可能。dev-crew では常時有効 hooks (no-verify-guard, post-approve-gate 等) は実績があるが、スキルスコープの on-demand hooks は未使用。

### Design Approach

#### careful-guard.sh
no-verify-guard.sh パターンを踏襲。stdin から JSON を読み、Bash コマンドを解析して危険パターンを検出。

検出対象:
| パターン | 理由 |
|---------|------|
| `rm -rf /` or `rm -rf ~` | ルート/ホーム全削除 |
| `DROP TABLE` or `DROP DATABASE` | DB破壊 |
| `git push --force` (force-with-lease以外) | リモート履歴破壊 |
| `git reset --hard` | ローカル変更消失 |
| `kubectl delete` | K8sリソース削除 |

#### SKILL.md frontmatter hooks 構文
```yaml
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "bash ${CLAUDE_PLUGIN_ROOT}/scripts/hooks/careful-guard.sh"
```

#### PoC 成功基準
1. careful-guard.sh が危険コマンドを正しく検出・ブロック (exit 2)
2. SKILL.md frontmatter の hooks 構文がパースエラーなしで受理される
3. `/careful` 実行後にセッション内で hook が有効になる

#### PoC 失敗時の代替案
SKILL.md frontmatter hooks が Claude Code で未サポートの場合:
- 代替: careful を通常スキルとし、実行時に hooks.json を動的編集するパターン
- ADR に「frontmatter hooks 未サポート」を記録し、Phase 28 を Close

## Progress Log

### 2026-03-23 20:59 - KICKOFF
- Cycle doc created
- Design Review Gate: PASS (スコア 5)
- no-verify-guard.sh パターン確認済み。careful-guard.sh はこれを踏襲
- SKILL.md 100行制限: 設計通り 100行ちょうど。TC-09 が safety net として機能
- marketplace.json: careful スキルエントリ追加のみ (単純な配列追加)
- T-01〜T-10: 10件、正常系3件(T-01/T-06/T-09)・異常系6件(T-02〜T-05/T-07/T-08)・構造1件(T-10)

### 2026-03-23 21:10 - RED
- test-careful-hook.sh 新規作成 (T-01~T-13, Codex/Socrates指摘反映でT-11~T-13追加)
- 13/13 FAIL (careful-guard.sh/SKILL.md 未存在)
- Phase completed

### 2026-03-23 21:15 - GREEN
- scripts/hooks/careful-guard.sh 新規作成 (no-verify-guard.shパターン踏襲)
- skills/careful/SKILL.md 新規作成 (frontmatter hooks付き)
- 13/13 PASS
- Phase completed

### 2026-03-23 21:20 - REFACTOR
- チェックリスト7項目確認: 改善不要
- Verification Gate: 13/13 PASS
- Phase completed

### 2026-03-23 21:45 - REVIEW
- Security: PASS (28), Socrates/Codex plan review反映済み
- 修正: sed パターン --force-with-lease=<refname> バイパス修正
- 修正後テスト: 13/13 PASS
- Codex plan review: frontmatter hooks公式ドキュメントで確認済み
- Phase completed

---

## Next Steps

1. [Done] KICKOFF
2. [Done] RED
3. [Done] GREEN
4. [Done] REFACTOR
5. [Done] REVIEW
6. [ ] COMMIT
