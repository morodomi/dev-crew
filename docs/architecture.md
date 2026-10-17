# Architecture Design

## Overview

dev-crewは、AI開発チームをClaude Code Pluginとして実現する。
PdM（プロダクトマネージャー）がワークフロー全体をオーケストレートし、
Engineer、Designer、Security Auditorが各フェーズを担当する。

## System Architecture

```
User
  │
  ├── plan mode で /spec
  │
  ▼
┌─────────────────────────────────────────────┐
│  plan mode (設計フェーズ)                     │
│  ┌──────────────┐  ┌─────────┐  ┌──────────┐  │
│  │ INIT         │→│ 探索設計 │→│ Test List│  │
│  │ +Ambiguity   │  └─────────┘  └──────────┘  │
│  └──────────────┘        │                    │
│                            ▼                   │
│  ┌──────────────────────────────────────────┐ │
│  │ plan-review (Claude + Codex competitive)  │ │
│  │  → findings を draft plan へ直接反映       │ │
│  │  → 最終版を1回だけ再レビュー               │ │
│  │  → Plan Review Record 記録                │ │
│  └──────────────────────────────────────────┘ │
│                                    ↓ approve │
├──────────────────────────────────────────────┤
│  normal mode (実行フェーズ)                   │
│  ┌──────────────────────────┐                 │
│  │ SYNC-PLAN                │                 │
│  │  → Plan Review Record 転記 + Cycle doc 生成│
│  └──────────────────────────┘                 │
│       │                                       │
│  ┌──────────────────────────┐                 │
│  │ architect (Post-Transfer Verification) │    │
│  └──────────────────────────┘                 │
│       │                                       │
│  ■ pre-red-gate.sh (決定論的ゲート)           │
│       │                                       │
│  ┌──────────────────────┐                      │
│  │ RED (テスト作成)       │                    │
│  └──────────┬───────────┘                      │
│  ┌──────────▼──┐  ┌───────────┐                │
│  │ GREEN       │→│ REFACTOR  │                │
│  └─────────────┘  └───────────┘                │
│       │                                       │
│  ┌───────────────┐                             │
│  │ 敵対的レビュー1回 + 指摘の振り分け       │
│  │ (Codex / 代行: adversarial-reviewer)     │
│  └───────────────┘                             │
│       │                                       │
│  ■ pre-commit-gate.sh (決定論的ゲート)         │
│       │                                       │
│  ┌─────────┐                                   │
│  │ COMMIT  │                                   │
│  └─────────┘                                   │
│       │                                       │
│  ┌─────────┐                                   │
│  │ DONE    │                                   │
│  └─────────┘                                   │
└─────────────────────────────────────────────┘
```

## Plugin Architecture

### Single Plugin Structure

dev-crewは単一のClaude Code Plugin。1回のinstallで全機能が有効化される。

```
dev-crew/
├── .claude-plugin/plugin.json    # Single plugin metadata
├── agents/                       # Agents (flat)
│   ├── Orchestration: socrates.md
│   ├── Implementation: architect.md, sync-plan.md, red-worker.md, green-worker.md, refactorer.md
│   ├── Review: *-reviewer.md + review-briefer.md
│   ├── Security: *-attacker.md, recon-agent.md, etc.
│   └── Meta: observer.md
├── skills/                       # Skills (flat)
│   ├── Workflow: spec/, red/, green/, refactor/, review/, commit/, cycle-retrospective/
│   ├── Orchestration: orchestrate/
│   ├── Diagnostic: diagnose/
│   ├── Setup: onboard/, skill-maker/
│   ├── Security: security-scan/, attack-report/, context-review/, generate-e2e/, security-audit/
│   ├── Language Quality: php-quality/, python-quality/, ts-quality/, etc.
│   └── Meta: learn/, evolve/
├── rules/                        # Rules by load trigger: always / cycle-scoped / file-scoped
├── hooks/hooks.json              # Auto-loaded hooks
└── scripts/hooks/                # Shell scripts for hooks
```

## Token Optimization Architecture

### Problem

Agent Teams + review(code: 3-6並行) により、
1セッションで5時間windowを使い切る。
主因は会話履歴の累積。v2ではRisk-Based Scalingで改善。
review(plan) は廃止し、plan-review + pre-red-gate.sh に置き換え済み。

### Solution: Phase-Boundary Compaction

OpenClawのmemory flush パターンをTDDフェーズに適用:

```
Phase N 完了
  │
  ├── 1. Phase Summary をCycle docに追記
  │      (成果物、決定事項、次フェーズへの引継ぎ)
  │
  ├── 2. /compact 実行
  │      (会話履歴を圧縮)
  │
  └── 3. Phase N+1 開始
         Cycle docを読み直してコンテキスト復元
```

### Compaction Points

| Transition | Persist | Restore |
|------------|---------|---------|
| plan mode → sync-plan | planファイル (scope, env, Test List) | planファイル |
| sync-plan -> RED | Cycle doc (Test List) | Cycle doc + Test List |
| RED Stage 1-2 | Formal Test Plan in Cycle doc | Cycle doc + Test Plan |
| RED Stage 3 -> GREEN | Test files (on disk) | Cycle doc + test files |
| GREEN -> REFACTOR | Implementation (on disk) | Cycle doc + source files |
| REFACTOR -> REVIEW | Refactored code (on disk) | Cycle doc + source files |
| REVIEW -> COMMIT | Review report | Cycle doc + review |

### Additional Token Savings

| Strategy | Expected Reduction | Implementation |
|----------|-------------------|----------------|
| Phase-boundary compaction | ~50% per phase | PreCompact hook (scripts/hooks/pre-compact.sh) |
| Haiku for simple tasks | ~70% cost reduction | model: "haiku" in Task tool |
| Progressive Disclosure | SKILL.md loading only | Already implemented |
| Tool output filtering | ~70% per git command | Hook-based preprocessing |

## Session Continuity

### Orchestrate Mode (Task()分離)

Task()委譲で各フェーズのcontextは自動分離。PdMが直接Phase SummaryをCycle docに書き込む。

### Manual Mode (PreCompact)

1. PreCompact hook → Phase Summary自動追記
2. `/compact` で会話履歴を圧縮
3. 新セッションで Cycle doc（docs/cycles/）から IN_PROGRESS cycle を読み継続する

### Across Sessions

- Cycle doc（docs/cycles/）が phase 状態を永続化し、セッションを跨いだ作業再開の起点になる
- memory/ files for cross-session knowledge
- meta plugin learn/evolve for pattern accumulation

## Agile Loop: codify-insight

### 位置づけ

`cycle-retrospective` → COMMIT → 次サイクル開始時に orchestrate が未処理件数を通知 → 人間が任意のタイミングで **`/dev-crew:codify-insight` を手動起動**、という順で動作する。
codify-insight は orchestrate から自動起動されない（2026-10 に廃止。自動起動がタスク外の変更を commit に混ぜたため）。

### フロー

```
[前サイクル完了]
  retro_status: captured (cycle-retrospective で insight 抽出済み)
  │
  ▼
[次 /orchestrate 開始]
  Block 0: Codify notice — frontmatter-only scan で captured の Cycle doc を数える
  │  1 件以上 → 件数を 1 行通知するだけ（起動しない）。件数にかかわらず次へ進む
  │
  ▼
[人間が別に /dev-crew:codify-insight を実行。タスクとは別の commit]
  │  原則は自動 triage（rule / inline-update / defer / no-codify）
  │  skill 候補 / low-confidence のときだけ AskUserQuestion
  │  Cycle doc EOF に ## Codify Decisions を append (APPEND-ONLY)
  │  全 insight 判定完了 → retro_status: captured → resolved
  │  編集するのは対象 Cycle doc のみ。rules 等への反映は別サイクル
```

### 設計原則

- **APPEND-ONLY**: 既存 `## Retrospective` セクションは変更しない。`## Codify Decisions` を EOF に追記するのみ。
- **Frontmatter-only scan**: whole-file grep は body 引用テキストに self-trigger する。`awk` で frontmatter のみ抽出。
- **MVP 意味論**: `codified` は判断の記録のみ。実際の書き出しは follow-up cycle で実施。
- **Autonomous default**: まず AI が triage し、`skill` 候補や低確信ケースだけ人に聞く。
- **Idempotency**: `### Insight N` heading の存在で判定済みを確認。partial 完了でも再起動で残分のみ処理。

詳細: [skills/codify-insight/reference.md](../skills/codify-insight/reference.md)

## Scoring & Judgment

### Review Verdict

code mode の REVIEW は、敵対的レビュー 1 回（Codex 既定、不在・失敗時は adversarial-reviewer）の指摘を「直す / 人間に戻す / 記録のみ」に振り分ける。severity による verdict と Socrates Protocol は使わない（`skills/orchestrate/adversarial-review.md`、`docs/decisions/adr-adversarial-review.md`）。以下は plan mode（`review --plan`）の判定。

各 reviewer は issue ごとに `severity: critical|important|optional` を返す。`skills/review/severity-verdict.sh` が accept-apply/accept-defer の findings（reject 除外）を集計して verdict を決定論的に判定する:

| Severity | Verdict | Action |
|----------|---------|--------|
| なし | PASS | Auto-proceed |
| important >= 1 (critical 0) | WARN | Socrates Protocol -> human judgment |
| critical >= 1 | BLOCK | Socrates Protocol -> human judgment |

### Socrates Protocol

plan review の WARN/BLOCK時にSocrates(Devil's Advocate)が反論を提示:
1. PdMの提案に対して3+の反論を生成
2. 代替案を提示
3. 人間が最終判断: proceed / fix / abort
