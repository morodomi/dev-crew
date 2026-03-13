---
feature: ai-adapter-sync-skills
cycle: 20260313_2205
phase: COMMIT
complexity: standard
test_count: 0
risk_level: low
created: 2026-03-13 22:05
updated: 2026-03-13 23:33
---

# Phase 1: AI Adapter Layer + sync-skills

## Scope Definition

### In Scope
- [x] スキル定義: skills/sync-skills/SKILL.md + reference.md
- [x] ROADMAP更新: adapter削除、sync-skills簡素化
- [x] AGENTS.md: CLAUDE.mdから共通部分を分離（symlink→実ファイル化）
- [x] CLAUDE.md: @AGENTS.md import + Claude固有拡張に整理、sync-skills trigger追加

### Out of Scope
- Phase 2 (Debate Skill) - 別サイクル
- アダプタスクリプト (不要: Bash toolで直接呼び出し)
- スタンドアロンスクリプト (不要: SKILL.mdワークフローで代替)

### Files to Change (target: 10 or less)
- skills/sync-skills/SKILL.md (new)
- skills/sync-skills/reference.md (new)
- ROADMAP.md (edit)
- AGENTS.md (new - was symlink)
- CLAUDE.md (edit)

## Environment

### Scope
- Layer: CLI / Shell Scripts
- Plugin: shell
- Risk: 20 (PASS)

### Runtime
- Language: Bash (zsh compatible)
- Dependencies: jq, readlink

### Dependencies (key packages)
- jq: JSON parsing for installed_plugins.json
- coreutils: readlink for symlink resolution

### Risk Interview (BLOCK only)
N/A (PASS)

## Context & Dependencies

### Reference Documents
- ROADMAP.md - Phase 1 definition
- scripts/hooks/observe.sh - shell script structure, jq patterns
- tests/test-skills-structure.sh - test patterns (pass/fail, TC numbers, tmpdir)
- skills/onboard/SKILL.md - skill definition pattern

### Dependent Features
- installed_plugins.json: ~/.claude/plugins/installed_plugins.json

### Related Issues/PRs
- None

## Test List

### TODO
(none - スキル定義のみ。構造テストはtest-skills-structure.shでカバー)

### DISCOVERED
- adapter layer不要: Bash toolで直接codex CLI呼び出し可能。スクリプト抽象化は過剰
- sync-skills.shスクリプト不要: SKILL.mdワークフローで代替。LLMが実行する前提

### DONE
(none)

## Implementation Notes

### Goal
Claude Codeプラグインのスキルを`.agents/skills/`にsymlinkし、Codexから発見可能にするスキルを定義する。

### Background
ROADMAP.md Phase 1の実装。既存の手動symlink実績: note/.agents/skills/, exspec/.agents/skills/ (prefix無し)。

### Design Approach
- SKILL.md + reference.mdでワークフローを定義（スタンドアロンスクリプト不要）
- Claude Codeがスキル実行時にBash toolでjq/ln -sを直接操作
- Codex呼び出しもBash toolで直接（`codex exec`, `which codex`等）

## Progress Log

### 2026-03-13 22:05 - KICKOFF
- Cycle doc created
- Scope definition ready

### 2026-03-13 22:21 - RED
- test-sync-skills.sh created (12 TCs)
- test-codex-adapter.sh created (8 TCs)
- All tests failing as expected (no implementation yet)
- Phase completed

### 2026-03-13 22:23 - GREEN
- scripts/sync-skills.sh implemented (12/12 TC pass)
- scripts/adapters/codex.sh implemented (8/8 TC pass)
- All 20 tests passing
- Regression: plugin-structure 6/6 pass, skills-structure existing failure (unrelated)
- Phase completed

### 2026-03-13 22:26 - REFACTOR
- sync-skills.sh: N+1 jq calls refactored to single jq invocation (@tsv)
- codex.sh: no changes needed (already clean)
- /simplify review: pass()/fail() duplication is existing pattern, out of scope
- Verification Gate: 20/20 tests pass
- Phase completed

### 2026-03-13 22:29 - REVIEW (initial)
- review(code) security:38 correctness:58 aggregate:48 verdict:PASS
- Phase completed

### 2026-03-13 23:33 - SCOPE REVISION
- adapter layer削除: Bash toolで直接呼び出し可能。スクリプト抽象化は過剰
- sync-skills.shスクリプト削除: SKILL.mdワークフローで代替
- Deleted: scripts/sync-skills.sh, scripts/adapters/codex.sh, tests/test-sync-skills.sh, tests/test-codex-adapter.sh
- Created: skills/sync-skills/SKILL.md, skills/sync-skills/reference.md
- ROADMAP.md updated: adapter関連削除
- Codex review: 5 findings (prefix矛盾、trigger未登録、scope漏れ、one-liner注釈、AGENTS.md件数) → 全件対応済み
- Phase completed

---

## Next Steps

1. [Done] KICKOFF
2. [Done] RED/GREEN/REFACTOR/REVIEW (initial - adapter + script approach)
3. [Done] SCOPE REVISION (adapter削除、SKILL.md方式に変更)
4. [Done] Codex review (5 findings → fixed)
5. [Next] COMMIT
