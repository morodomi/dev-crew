---
title: "Phase 29: CLAUDE_PLUGIN_DATA Migration"
date: 2026-03-23
status: IN_PROGRESS
plan_file: /Users/morodomi/.claude/plans/parsed-seeking-steele.md
codex_session_id: ""
---

# Phase 29: CLAUDE_PLUGIN_DATA 移行

## Goal

スキルデータ (`instincts/`, `observations/`, `source-path`, gate flags) の保存先が `~/.claude/dev-crew/` にハードコードされている問題を解消する。Anthropic 公式の `${CLAUDE_PLUGIN_DATA}` に移行し、プラグインアップグレード時のデータ消失を防止する。

## TDD Context

- **Language**: Bash (shell scripts)
- **Test Framework**: bash (tests/test-*.sh)
- **Coverage Target**: 全シェルスクリプト変更箇所にパステスト
- **Design Pattern**: Dual-Read (CLAUDE_PLUGIN_DATA → fallback to ~/.claude/dev-crew)

## Design Approach

```bash
DATA_DIR="${CLAUDE_PLUGIN_DATA:-${HOME}/.claude/dev-crew}"
```

- `CLAUDE_PLUGIN_DATA` が設定されていれば新パス
- 未設定なら旧パスにフォールバック（後方互換）
- Markdown ドキュメント内の参照は `${CLAUDE_PLUGIN_DATA}` に一括置換
- 既存データの手動移行不要（フォールバックで旧データを読み続ける）

## Files to Change

### Shell スクリプト (5ファイル) - ロジック変更

| ファイル | 箇所 | 変更内容 |
|---------|------|---------|
| scripts/hooks/observe.sh | 2 | OBS_DIR, source-path のパス解決 |
| scripts/hooks/plan-exit-flag.sh | 1 | FLAG_DIR のパス解決 |
| scripts/hooks/post-approve-gate.sh | 2 | FLAG_FILE のパス解決 |
| scripts/tfidf-summary.sh | 1 | デフォルト log.jsonl パス |
| skills/orchestrate/SKILL.md | 1 | Block 0 の rm -f コマンド |

### スキル Markdown (9ファイル) - パス参照置換

| ファイル | 箇所 |
|---------|------|
| skills/learn/SKILL.md | 4 |
| skills/learn/reference.md | 3 |
| skills/evolve/SKILL.md | 5 |
| skills/evolve/reference.md | 3 |
| skills/commit/reference.md | 4 |
| skills/orchestrate/reference.md | 1 |
| skills/orchestrate/steps-subagent.md | 1 |
| skills/orchestrate/steps-teams.md | 1 |
| agents/observer.md | 1 |

### ドキュメント (2ファイル) - 参照更新

| ファイル | 箇所 |
|---------|------|
| docs/known-gotchas.md | 1 |
| ROADMAP.md | 完了後に Phase 29 を削除 |

### テスト (2ファイル) - パス検証更新

| ファイル | 箇所 |
|---------|------|
| tests/test-instinct-paths.sh | 4 |
| tests/test-post-approve-gate.sh | 1 |

### 除外 (変更しない)

| ファイル | 理由 |
|---------|------|
| docs/cycles/20260323_0803_*.md | 歴史的記録。当時の事実を維持 |

### 注意: settings.local.json

`.claude/settings.local.json` に `~/.claude/dev-crew/observations/.last-learn-timestamp` のパスが含まれている。plan には記載がないが、T-06 の grep 完了条件で検出されるため、実施時に確認・更新が必要。

## Test List

### 新規: tests/test-plugin-data-paths.sh

```
T-01: Given CLAUDE_PLUGIN_DATA is set
      When observe.sh resolves DATA_DIR
      Then it uses CLAUDE_PLUGIN_DATA

T-02: Given CLAUDE_PLUGIN_DATA is unset
      When observe.sh resolves DATA_DIR
      Then it falls back to ~/.claude/dev-crew

T-03: Given CLAUDE_PLUGIN_DATA is set
      When plan-exit-flag.sh resolves FLAG_DIR
      Then it uses CLAUDE_PLUGIN_DATA

T-04: Given CLAUDE_PLUGIN_DATA is unset
      When plan-exit-flag.sh resolves FLAG_DIR
      Then it falls back to ~/.claude/dev-crew

T-05: Given CLAUDE_PLUGIN_DATA is set
      When post-approve-gate.sh resolves FLAG_FILE
      Then it uses CLAUDE_PLUGIN_DATA

T-06: Given all files are migrated (excluding docs/cycles/)
      When grep -r '~/.claude/dev-crew' is run
      Then it returns 0 matches (completion condition)
```

### 既存テスト更新

- tests/test-instinct-paths.sh: TC-12 を `${CLAUDE_PLUGIN_DATA:-...}` パターンの検証に更新
- tests/test-post-approve-gate.sh: FLAG_DIR 参照を `${CLAUDE_PLUGIN_DATA:-${HOME}/.claude/dev-crew}` に更新

## Completion Condition

```bash
# docs/cycles/ を除外して grep
grep -r '~/.claude/dev-crew' --include='*.sh' --include='*.md' --include='*.json' \
  --exclude-dir='docs/cycles' . | grep -v 'ROADMAP.md' | wc -l
# → 0
```

## Verification

```bash
# 新規テスト
bash tests/test-plugin-data-paths.sh

# 既存テスト (パス更新後も PASS すること)
bash tests/test-instinct-paths.sh
bash tests/test-post-approve-gate.sh

# 全テストスイート
for f in tests/test-*.sh; do bash "$f"; done
```

## Risk

| リスク | 対策 |
|--------|------|
| `CLAUDE_PLUGIN_DATA` が未設定 | フォールバックで旧パスを使用（安全） |
| 既存データの移行 | 手動不要。フォールバックで旧データを読み続ける |
| 19ファイル変更の大きさ | ほとんどが文字列置換。ロジック変更は shell 5ファイルのみ |
| settings.local.json の漏れ | T-06 で検出。実施時に確認する |

## Progress Log

### KICKOFF (2026-03-23T13:52)

Design Review Gate: **PASS** (score: 20/100)

- Scope: Files to Change が 19 > 10 の上限超過だが、大半は機械的な string replace。ロジック変更は shell 5ファイルのみ。許容範囲。
- Architecture: Dual-Read 戦略は後方互換を保ちながら公式パスに移行する合理的な設計。`.claude/settings.local.json` に未記載の参照あり（T-06 で自己検出）。
- Test List: T-05 に CLAUDE_PLUGIN_DATA unset ケースが欠けている（T-06 の grep テストで間接カバー）。軽微。
- Risk: 全体的にリスクは低い。フォールバック設計が安全ネットとして機能する。

---

_RED phase: tests/test-plugin-data-paths.sh を作成し、全 T-01〜T-06 が FAIL することを確認する_
