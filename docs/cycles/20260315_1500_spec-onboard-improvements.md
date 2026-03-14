---
feature: spec-onboard-improvements
cycle: 20260315_1500
phase: DONE
complexity: standard
test_count: 14
risk_level: low
created: 2026-03-15 15:00
updated: 2026-03-15 15:00
---

# DISCOVERED fixes + onboard improvements (11.6)

## Scope Definition

### In Scope
- [ ] spec/reference.md: Plan File Template Workflow行修正
- [ ] spec/reference.ja.md: Plan File Templateセクション追加
- [ ] onboard/reference.md: AGENTS.md/CLAUDE.mdテンプレート改善 + Codexセットアップ
- [ ] tests/test-spec-onboard-improvements.sh (new, 14 TCs)

### Environment
- Layer: Both (skill definition + documentation)
- Plugin: N/A
- Risk: 15 (PASS - documentation only, 3 files)
- Language: Shell (tests), Markdown (skills/docs)
- Dependencies: None

### Out of Scope
- spec Post-Approve Action本文変更 (Reason: orchestrateが内部的に正しい順序を管理)
- Codex session isolation (Reason: アーキテクチャ変更が必要、スコープ外)

### Files to Change (4 files)
- skills/spec/reference.md (edit) - Workflow行修正
- skills/spec/reference.ja.md (edit) - Plan File Templateセクション追加
- skills/onboard/reference.md (edit) - AGENTS.md/CLAUDE.mdテンプレート改善 + Codexセットアップ
- tests/test-spec-onboard-improvements.sh (new) - 14 TCs

## Test List

### Sub-task 1: spec template (4 TCs)
- [ ] TC-01: reference.md Workflow行に "plan review" が "sync-plan" より前にある
- [ ] TC-02: reference.ja.md に Plan File Template セクションが存在する
- [ ] TC-03: reference.ja.md Workflow行に "plan review" or "レビュー" が含まれる
- [ ] TC-04: reference.md Post-Approve Action が orchestrate 単一アクション

### Sub-task 2: onboard AGENTS.md (4 TCs)
- [ ] TC-05: onboard/reference.md に "Start Here" パターンが存在する
- [ ] TC-06: onboard/reference.md に `for f in` テストコマンドパターンが存在する
- [ ] TC-07: onboard/reference.md に数値カウントは STATUS.md へのガイダンスがある
- [ ] TC-08: onboard/reference.md に migration note パターンが存在する

### Sub-task 3: onboard CLAUDE.md + Codex (4 TCs)
- [ ] TC-09: onboard/reference.md に Codex Integration テンプレートパターンが存在する
- [ ] TC-10: onboard/reference.md に Skills trigger table 不要の記述がある
- [ ] TC-11: onboard/reference.md に sync-skills ガイダンスが存在する
- [ ] TC-12: onboard/reference.md に Codex セッション作成ガイダンスが存在する

### Constraints + Regression (2 TCs)
- [ ] TC-13: onboard/SKILL.md が 100行以下
- [ ] TC-14: key existing tests pass (test-plugin-structure.sh)

## Phase Summary

### RED
- Status: DONE
- Tests: tests/test-spec-onboard-improvements.sh (14 TCs, 12 failing)

### GREEN
- Status: DONE
- All 14 TCs passing

### REFACTOR
- Status: DONE (no changes needed - documentation only)

### REVIEW
- Status: DONE
- Regression: test-plugin-structure.sh 6/6 pass

### COMMIT
- Status: READY

## DISCOVERED

### D1: onboard モード判定の改善 (High)

`dev-crew-installed` モードでワークフロー変化を検知できない。テンプレートバージョンの概念がなく、古い onboard で作った CLAUDE.md と最新テンプレートの区別がつかない。

対象パターン:
- CLAUDE.md のみ + dev-crew 途中開発済み + ワークフロー変化未検知
- AGENTS.md が symlink の場合、Write で symlink 先を破壊する可能性

ユーザーの実環境パターン:
1. CLAUDE.md のみ設定済み、dev-crew 途中開発、ワークフロー変化検知不可
2. CLAUDE.md 設定済み、TDD なし
3. CLAUDE.md なし新規
4. AGENTS.md あり
5. AGENTS.md symlink あり
6. AGENTS.md なし

### D2: Codex session isolation

サイクル間のセッション分離。アーキテクチャ変更が必要。(前サイクルからの持ち越し)
