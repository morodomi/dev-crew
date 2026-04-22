---
name: orchestrate
description: "TDDサイクル全体をPdM（Product Manager）として自律管理。plan mode起点でワークフロー制御。sync-plan→RED→GREEN→REFACTOR→REVIEW→COMMITを専門エージェントに委譲・判断する。Manual trigger: 「orchestrate」「全体管理」「PdMモード」。Do NOT use for 個別フェーズのみの実行（→ 各フェーズスキル）。"
allowed-tools: Task, Read, Write, Bash, Grep, Glob, AskUserQuestion
---

## Current State
!`ls -t docs/cycles/*.md 2>/dev/null | head -5 || echo "(none)"`
!`git log --oneline -5 2>/dev/null || echo "(no commits)"`

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
- [ ] Block 2c.5: VERIFY — Product Verification (advisory, skip if absent)
- [ ] Block 2d: REVIEW — Skill(review --code) でコードレビュー → 自律判断
- [ ] Block 2e: DISCOVERED — スコープ外項目をissue起票
- [ ] Block 2f: RETROSPECTIVE — Skill(dev-crew:cycle-retrospective) で失敗-成功 insight 抽出
- [ ] Block 3: COMMIT → 完了
```

## PdM の原則

- 自分で実装・テスト・レビューしない → 専門 Teammate/Subagent に委譲
- PASS/WARN → 自動進行、BLOCK → 再試行 → ユーザーに報告
- 曖昧なまま進まない → AskUserQuestion で確認

## Workflow

### Block 0: Prerequisite Check

**0. Codify gate** — frontmatter-only scan:
`for f in docs/cycles/*.md; do awk '/^---$/{c++;next} c==1{print}' "$f" | grep -q 'retro_status: captured' && echo "$f"; done`
非空 → `Skill(dev-crew:codify-insight)` 起動。exit 0 (全 resolved) → 次へ。exit 1 (abort) → BLOCK、/orchestrate 再起動を案内。空 → no-op。

**最初に実行**: TaskCreate でタスクを登録。詳細: [reference.md](reference.md#task-list)

planファイルを起点に開始地点を決定する:

1. **planファイルあり?**
   → YES: 未完了 cycle doc あり? plan-review 記録あり → Block 2a / なし → Progress Log 再開 / cycle doc なし → Block 1
   → NO: 新規開始 (plan mode): `Skill(dev-crew:spec)` → 設計・Test List → `Skill(dev-crew:review, args: "--plan")` → approve → Block 1

### Block 1: Sync-Plan (with Design Review)

1. **sync-plan**: architect が Design Review Gate を実施後、PASS/WARN なら Cycle doc 生成
2. **Codex不在時: Socrates adversarial review** — `which codex` 失敗時、Socrates を計画への adversarial reviewer として起動。詳細: [reference.md](reference.md#socrates-plan-review)
3. **自律判断**: PASS/WARN → Block 2a へ、BLOCK → sync-plan再実行

### Block 2: Implementation

**MUST**: 次のフェーズに進む前に、現フェーズの完了条件を確認せよ。詳細手順はモードに応じて参照: [steps-subagent.md](steps-subagent.md) / [steps-teams.md](steps-teams.md) / [steps-codex.md](steps-codex.md)

#### Block 2a: RED
Task(red-worker, sonnet): Cycle doc + TC → テスト作成・失敗確認

#### Block 2b: GREEN
Task(green-worker, sonnet): Cycle doc → テストを通す最小実装・全PASS確認

#### Block 2c: REFACTOR
Skill(dev-crew:refactor): Verification Gate通過（テスト全PASS + 静的解析0件 + フォーマット）

#### Block 2c.5: VERIFY (Product Verification)
`## Verification` セクションのコマンドを実行。advisory evidence（非ブロッキング）。セクション不在 → スキップ。詳細: [reference.md](reference.md#product-verification)

#### Block 2d: REVIEW
Skill(dev-crew:review, args: "--code"): competitive review（Codex利用可能時）
**判定**: PASS/WARN → Block 2e へ、BLOCK → GREEN再実行（max 1回）

#### Block 2e: DISCOVERED
スコープ外項目をCycle docに記録し、GitHub issueに起票（起票→ `issue #N` 参照、reject→ 理由記載）。

#### Block 2f: RETROSPECTIVE
Skill(dev-crew:cycle-retrospective): 失敗-成功 insight 抽出、retro_status: captured/resolved 遷移。abort (exit 1) → COMMIT 停止「/orchestrate を再起動してください」。詳細: [reference.md](reference.md#block-2f)

### Block 3: Finalization

1. **COMMIT**: git add & commit（PdM 直接実行）
2. **完了報告**: サイクル完了をユーザーに報告

## Mode Selection

詳細: [reference.md](reference.md) | [steps-codex.md](steps-codex.md) | [steps-teams.md](steps-teams.md) | [steps-subagent.md](steps-subagent.md)
