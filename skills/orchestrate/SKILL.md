---
name: orchestrate
description: "TDDサイクル全体をPdM（Product Manager）として自律管理。plan mode起点でワークフロー制御。kickoff→RED→GREEN→REFACTOR→REVIEW→COMMITを専門エージェントに委譲・判断する。Manual trigger: 「orchestrate」「全体管理」「PdMモード」。Do NOT use for 個別フェーズのみの実行（→ 各フェーズスキル）。"
allowed-tools: Task, Read, Write, Bash, Grep, Glob, AskUserQuestion
---

# TDD Orchestrate (PdM Mode)

TDDサイクル全体をPdM (Product Manager) として管理するオーケストレータ。
plan mode起点でワークフロー制御を行う。

## Progress Checklist

```
orchestrate Progress:
- [ ] Block 0: planファイル / Cycle doc 確認 → 開始地点決定
- [ ] Block 1: kickoff (with Design Review) → 自律判断
- [ ] Block 2: RED → GREEN → REFACTOR → REVIEW → 自律判断 → DISCOVERED
- [ ] Block 3: COMMIT → 完了
```

## PdM の原則

- 自分で実装・テスト・レビューしない → 専門 Teammate/Subagent に委譲
- PASS/WARN → 自動進行、BLOCK → 再試行 → ユーザーに報告
- 曖昧なまま進まない → AskUserQuestion で確認

## Workflow

### Block 0: Prerequisite Check

planファイルを起点に開始地点を決定する:

1. **planファイルあり?**
   → YES:
     a. 未完了 cycle doc あり (`phase: DONE` 以外)? → Progress Log から再開
     b. なし → Block 1 (kickoff) へ
   → NO:
     → 新規開始 (plan mode):
     1. `Skill(dev-crew:spec)` でTDDコンテキスト設定
     2. 探索・設計・Test List・QA
     3. `Skill(dev-crew:review, args: "--plan")` で設計レビュー
     4. approve → compact → Block 1 へ

### Block 1: Kickoff (with Design Review)

1. **kickoff**: architect が Design Review Gate を実施後、PASS/WARN なら Cycle doc 生成
2. **自律判断**: PASS/WARN → Block 2 へ、BLOCK → kickoff再実行

### Block 2: Implementation

1. **RED**: red-worker にテスト作成を委譲
2. **GREEN**: green-worker に実装を委譲
3. **REFACTOR**: コード品質改善（内部で/simplifyに委譲）+ Verification Gate
4. **REVIEW**: 統一レビュー (mode: code) でコードレビュー
5. **自律判断**: PASS/WARN → DISCOVERED判断 → Block 3 へ、BLOCK → GREEN再実行
6. **DISCOVERED**: スコープ外項目をCycle docに記録し、GitHub issueに起票（起票→ `issue #N` 参照、reject→ 理由記載）

### Block 3: Finalization

1. **COMMIT**: git add & commit（PdM 直接実行）
2. **完了報告**: サイクル完了をユーザーに報告

## Mode Selection

`which codex` でCodex利用可能ならCodex Delegationを優先。不在時は既存モードにフォールバック。

| 条件 | モード | 手順 |
|------|--------|------|
| Codex利用可能 | Codex Delegation | [steps-codex.md](steps-codex.md) |
| Agent Teams有効 (`1`) | Agent Teams (PdM Hub) | [steps-teams.md](steps-teams.md) |
| 無効 / 未設定 | Subagent Chain | [steps-subagent.md](steps-subagent.md) |

## Judgment Criteria

| スコア | 判定 | PdM アクション |
|--------|------|---------------|
| 0-49 | PASS | 次 Block へ自動進行 |
| 50-79 | WARN | Socrates Protocol → 人間判断 (Agent Teams時) |
| 80-100 | BLOCK | Socrates Protocol → 人間判断 (Agent Teams時) |

Agent Teams 無効時は WARN 自動進行、BLOCK 自動再試行 (v5.0 互換)。
Socrates Protocol 詳細: [reference.md](reference.md)

## Reference

- PdM 責務・判断基準: [reference.md](reference.md)
- Codex 委譲手順: [steps-codex.md](steps-codex.md)
- Agent Teams 手順: [steps-teams.md](steps-teams.md)
- Subagent 手順: [steps-subagent.md](steps-subagent.md)
