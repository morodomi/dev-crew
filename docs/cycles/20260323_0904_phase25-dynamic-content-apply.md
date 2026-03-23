---
title: "Phase 25: 動的スキルコンテンツ注入 段階的適用"
date: 2026-03-23
phase: DONE
updated: 2026-03-23
plan_file: /Users/morodomi/.claude/plans/temporal-spinning-shell.md
---

# Phase 25: 動的スキルコンテンツ注入 段階的適用

## Context

Phase 24で`!`command``構文のPoC完了（ADR-001 accepted）。この構文はSKILL.md内にシェルコマンドを埋め込み、スキル起動時にClaude Codeが実行結果でプレースホルダを置換する。各スキルが毎回Bash/Readツールコールで取得していた動的情報を、プロンプト構築時に自動注入することでツールコール削減・レイテンシ改善を実現する。

Phase 25はこれを高ROIスキル5つ（orchestrate→reload→spec→red→green）に段階適用する。

## Upstream References

- ROADMAP.md Phase 25: 高ROIスキルから適用、reference.md更新、テスト新設
- ADR-001 (adr-dynamic-skill-content.md): 読み取り専用・即完了・エラーハンドリング必須・コードブロック外配置

## PLAN

### Design Approach

frontmatter直後・`#` タイトルの前に `## Current State` セクションを新設し、`!`command``をまとめる。

**注入コマンド:**

| コマンド | 用途 | 対象 |
|---------|------|------|
| `` !`ls -t docs/cycles/*.md 2>/dev/null \| head -5 \|\| echo "(none)"` `` | 最新Cycle doc一覧 | orchestrate |
| `` !`ls -t docs/cycles/*.md 2>/dev/null \| head -1 \|\| echo "(none)"` `` | 最新Cycle doc特定 | reload, spec, red, green |
| `` !`git log --oneline -5 2>/dev/null \|\| echo "(no commits)"` `` | 直近コミット | orchestrate |

STATUS.mdの全文注入は見送り（内容が大きくトークン増加で逆効果）。

**行数制限対応:**

| スキル | 現在 | 追加 | 結果 | 対応 |
|--------|------|------|------|------|
| orchestrate | 100 | +5 | 105 → 99 | rm -fコードブロック→インライン化(-2), Block 2a-2dコード例をインライン化(-4) で余裕確保 |
| reload | 75 | +4 | 79 | 不要 |
| spec | 95 | +4 | 99 | 不要（ギリギリ） |
| red | 78 | +4 | 82 | 不要 |
| green | 49 | +4 | 53 | 不要 |

### In Scope

1. `tests/test-dynamic-content.sh` にTC-07/07f/08/09追加
2. `skills/green/SKILL.md` — `## Current State` セクション追加（パイロット）
3. `skills/reload/SKILL.md` — `## Current State` セクション追加
4. `skills/red/SKILL.md` — `## Current State` セクション追加
5. `skills/spec/SKILL.md` — `## Current State` セクション追加（99行、慎重に）
6. `skills/orchestrate/SKILL.md` — 圧縮 + `## Current State` 追加
7. `docs/decisions/adr-dynamic-skill-content.md` — Phase 25適用結果を追記

### Files to Change

- `skills/orchestrate/SKILL.md`
- `skills/reload/SKILL.md`
- `skills/spec/SKILL.md`
- `skills/red/SKILL.md`
- `skills/green/SKILL.md`
- `tests/test-dynamic-content.sh`
- `docs/decisions/adr-dynamic-skill-content.md`

### Test List

#### TC-07: SKILL.mdに動的注入構文が存在する（5スキル分）

```
Given: {skill}/SKILL.md が存在する（orchestrate, reload, spec, red, green）
When: コードブロック外の内容を検査する
Then: `!`ls -t docs/cycles/` パターンを含むこと
```

- [ ] TC-07-orchestrate: orchestrate/SKILL.md に ls cycles パターンあり
- [ ] TC-07-reload: reload/SKILL.md に ls cycles パターンあり
- [ ] TC-07-spec: spec/SKILL.md に ls cycles パターンあり
- [ ] TC-07-red: red/SKILL.md に ls cycles パターンあり
- [ ] TC-07-green: green/SKILL.md に ls cycles パターンあり

#### TC-07f: orchestrate専用git log注入

```
Given: orchestrate/SKILL.md が存在する
When: コードブロック外の内容を検査する
Then: `!`git log --oneline` パターンを含むこと
```

- [ ] TC-07f: orchestrate/SKILL.md に git log パターンあり

#### TC-08: 100行制限チェック

```
Given: 動的注入対象の5つのSKILL.md
When: 各ファイルの行数を計測する
Then: 全て100行以下であること
```

- [ ] TC-08-orchestrate: orchestrate/SKILL.md が100行以下
- [ ] TC-08-reload: reload/SKILL.md が100行以下
- [ ] TC-08-spec: spec/SKILL.md が100行以下
- [ ] TC-08-red: red/SKILL.md が100行以下
- [ ] TC-08-green: green/SKILL.md が100行以下

#### TC-09: コードブロック内の`!`command``禁止チェック

```
Given: 動的注入対象の5つのSKILL.md
When: コードブロック内を検査する
Then: コードブロック内に !` パターンが存在しないこと
```

- [ ] TC-09-orchestrate: orchestrate/SKILL.md のコードブロック内に !` なし
- [ ] TC-09-reload: reload/SKILL.md のコードブロック内に !` なし
- [ ] TC-09-spec: spec/SKILL.md のコードブロック内に !` なし
- [ ] TC-09-red: red/SKILL.md のコードブロック内に !` なし
- [ ] TC-09-green: green/SKILL.md のコードブロック内に !` なし

## Verification

1. `bash tests/test-dynamic-content.sh` — 全TC PASS
2. `for f in tests/test-*.sh; do bash "$f"; done` — 既存テスト回帰なし
3. 各SKILL.mdが100行以下であること（TC-08で検証）

## Progress Log

### 2026-03-23 - SYNC-PLAN

- Design Review Gate: PASS（スコア5）
- planファイル読み込み・審査完了
- Cycle doc生成完了
- Phase completed

### 2026-03-23 - RED

- TC-07/07f/08/09 テスト追加（test-dynamic-content.sh）
- 6件FAIL確認（TC-07x5 + TC-07f）
- Phase completed

### 2026-03-23 - GREEN

- 5スキルにCurrent Stateセクション追加（orchestrate/reload/spec/red/green）
- orchestrate圧縮（100→89行）+ 動的注入
- 全20件PASS
- Phase completed

### 2026-03-23 - REFACTOR

- テストファイルヘッダコメント更新（Phase 24→Phase 24+25）
- ADR Phase 25適用結果追記
- Verification Gate通過（全20件PASS）
- Phase completed

### 2026-03-23 - REVIEW

- Security: PASS (8/100) — 読み取り専用コマンドのみ、秘密鍵露出なし
- Correctness: PASS (5/100) — 圧縮情報欠落なし、awk判定正確、行数制限遵守
- Aggregate: PASS (6.5/100)
- Phase completed
