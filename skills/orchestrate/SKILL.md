---
name: orchestrate
description: "TDDサイクル全体をPdM（Product Manager）として自律管理。plan mode起点でワークフロー制御。sync-plan→RED→GREEN→REFACTOR→REVIEW→COMMITを専門エージェントに委譲・判断する。Manual trigger: 「orchestrate」「全体管理」「PdMモード」。Do NOT use for 個別フェーズのみの実行（→ 各フェーズスキル）。"
allowed-tools: Task, Read, Write, Bash, Grep, Glob, AskUserQuestion
---

# TDD Orchestrate (PdM Mode)

TDDサイクル全体をPdM (Product Manager) として管理。plan mode起点でワークフロー制御。

## Progress Checklist

```
orchestrate Progress:
- [ ] Block 0: planファイル / Cycle doc 確認 → 開始地点決定
- [ ] Block 1: sync-plan (with Design Review) → 自律判断
- [ ] Block 2a: RED — Task(red-worker) でテスト作成、失敗確認
- [ ] Block 2b: GREEN — Task(green-worker) で実装、全テストPASS確認
- [ ] Block 2c: REFACTOR — Skill(refactor) で品質改善
- [ ] Block 2d: REVIEW — Skill(review --code) でコードレビュー → 自律判断
- [ ] Block 2e: DISCOVERED — スコープ外項目をissue起票
- [ ] Block 3: COMMIT → 完了
```

## PdM の原則

- 自分で実装・テスト・レビューしない → 専門 Teammate/Subagent に委譲
- PASS/WARN → 自動進行、BLOCK → 再試行 → ユーザーに報告
- 曖昧なまま進まない → AskUserQuestion で確認

## Workflow

### Block 0: Prerequisite Check

**最初に実行**: post-approve gate フラグを解除する:
```bash
rm -f "${HOME}/.claude/dev-crew/.plan-approved"
```

planファイルを起点に開始地点を決定する:

1. **planファイルあり?**
   → YES:
     a. 未完了 cycle doc あり (`phase: DONE` 以外)?
        - plan-review 記録あり (Cycle doc に `plan_review` セクション存在)? → Block 1 スキップ → Block 2a (RED) へ
        - plan-review 記録なし? → Progress Log から再開
     b. cycle doc なし → Block 1 (sync-plan) へ
   → NO:
     → 新規開始 (plan mode):
     1. `Skill(dev-crew:spec)` でTDDコンテキスト設定
     2. 探索・設計・Test List・QA
     3. `Skill(dev-crew:review, args: "--plan")` で設計レビュー
     4. approve → compact → Block 1 へ

### Block 1: Sync-Plan (with Design Review)

1. **sync-plan**: architect が Design Review Gate を実施後、PASS/WARN なら Cycle doc 生成
2. **Codex不在時: Socrates adversarial review** — `which codex` 失敗時、Socrates を計画への adversarial reviewer として起動。詳細: [reference.md](reference.md#socrates-plan-review)
3. **自律判断**: PASS/WARN → Block 2a へ、BLOCK → sync-plan再実行

### Block 2: Implementation

**MUST**: 次のフェーズに進む前に、現フェーズの完了条件を確認せよ。詳細手順はモードに応じて参照: [steps-subagent.md](steps-subagent.md) / [steps-teams.md](steps-teams.md) / [steps-codex.md](steps-codex.md)

#### Block 2a: RED
```
Task(subagent_type: "dev-crew:red-worker", model: "sonnet", prompt: "Cycle doc: [path]. 担当テストケース: [TC-XX]. テストを作成し、失敗を確認せよ。")
```
**完了条件**: テストが作成され、実行して失敗（RED状態）を確認

#### Block 2b: GREEN
```
Task(subagent_type: "dev-crew:green-worker", model: "sonnet", prompt: "Cycle doc: [path]. テストを通す最小限の実装を行え。")
```
**完了条件**: 全テストがPASS（GREEN状態）を確認

#### Block 2c: REFACTOR
```
Skill(dev-crew:refactor)
```
**完了条件**: Verification Gate通過（テスト全PASS + 静的解析0件 + フォーマット適用）

#### Block 2d: REVIEW
```
Skill(dev-crew:review, args: "--code")
```
Codex利用可能時は competitive review も実行。
**判定**: PASS/WARN → Block 2e へ、BLOCK → GREEN再実行（max 1回）

#### Block 2e: DISCOVERED
スコープ外項目をCycle docに記録し、GitHub issueに起票（起票→ `issue #N` 参照、reject→ 理由記載）。

### Block 3: Finalization

1. **COMMIT**: git add & commit（PdM 直接実行）
2. **完了報告**: サイクル完了をユーザーに報告

## Mode Selection

codex_mode (full/no) は RED/GREEN の委譲先を制御。ユーザー選択優先。詳細: [reference.md](reference.md) | [steps-codex.md](steps-codex.md) | [steps-teams.md](steps-teams.md) | [steps-subagent.md](steps-subagent.md)
