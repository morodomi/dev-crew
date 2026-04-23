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
│  └──────────────┘                              │
│                                    ↓ approve │
├──────────────────────────────────────────────┤
│  normal mode (実行フェーズ)                   │
│  ┌──────────────────────────┐                 │
│  │ SYNC-PLAN                │                 │
│  │  → Cycle doc 生成        │                 │
│  └──────────────────────────┘                 │
│       │                                       │
│  ┌──────────────────────────┐                 │
│  │ plan-review (Codex competitive) │          │
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
│  │ review(code)  │ (Claude + Codex competitive)│
│  └───────────────┘                             │
│       │                                       │
│  ■ pre-commit-gate.sh (決定論的ゲート)         │
│       │                                       │
│  ┌─────────┐                                   │
│  │ COMMIT  │                                   │
│  └─────────┘                                   │
└─────────────────────────────────────────────┘
```

## Plugin Architecture

### Single Plugin Structure

dev-crewは単一のClaude Code Plugin。1回のinstallで全機能が有効化される。

```
dev-crew/
├── .claude-plugin/plugin.json    # Single plugin metadata
├── agents/                       # Agents (flat, see STATUS.md for counts)
│   ├── Orchestration: socrates.md
│   ├── Implementation: architect.md, sync-plan.md, red-worker.md, green-worker.md, refactorer.md
│   ├── Review: *-reviewer.md + review-briefer.md
│   ├── Security: *-attacker.md, recon-agent.md, etc.
│   └── Meta: observer.md
├── skills/                       # Skills (flat, see STATUS.md for counts)
│   ├── Workflow: spec/, red/, green/, refactor/, review/, commit/, reload/, cycle-retrospective/
│   ├── Orchestration: orchestrate/, phase-compact/, strategy/
│   ├── Diagnostic: diagnose/, parallel/
│   ├── Setup: onboard/, skill-maker/
│   ├── Security: security-scan/, attack-report/, context-review/, generate-e2e/, security-audit/
│   ├── Language Quality: php-quality/, python-quality/, ts-quality/, etc.
│   └── Meta: learn/, evolve/
├── rules/                        # Always-applied rules
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
| Phase-compact | ~50% per phase | phase-compact skill |
| Haiku for simple tasks | ~70% cost reduction | model: "haiku" in Task tool |
| Progressive Disclosure | SKILL.md loading only | Already implemented |
| Tool output filtering | ~70% per git command | Hook-based preprocessing |

## Session Continuity

### Orchestrate Mode (Task()分離)

Task()委譲で各フェーズのcontextは自動分離。PdMが直接Phase SummaryをCycle docに書き込む。

### Manual Mode (PreCompact + reload)

1. PreCompact hook → Phase Summary自動追記
2. `/compact` で会話履歴を圧縮
3. `/reload` でCycle docからコンテキスト復元

### Across Sessions

- `/reload` で前回セッションのCycle docからコンテキスト復元
- memory/ files for cross-session knowledge
- meta plugin learn/evolve for pattern accumulation

## Agile Loop: codify-insight

### 位置づけ

`cycle-retrospective` → COMMIT → **次サイクル開始時に `codify-insight`** → 次サイクル実行、という順で動作する。
codify-insight は orchestrate Block 0 から自動起動される。

### フロー

```
[前サイクル完了]
  retro_status: captured (cycle-retrospective で insight 抽出済み)
  │
  ▼
[次 /orchestrate 開始]
  Block 0: Codify gate — frontmatter-only scan で captured cycles を検出
  │  非空 → Skill(dev-crew:codify-insight) を起動
  │
  ▼
codify-insight
  │  原則は自動 triage（rule / inline-update / defer / no-codify）
  │  skill 候補 / low-confidence のときだけ AskUserQuestion
  │  Cycle doc EOF に ## Codify Decisions を append (APPEND-ONLY)
  │  全 insight 判定完了 → retro_status: captured → resolved
  │
  ▼
  [通常の orchestrate フローへ]
```

### 設計原則

- **APPEND-ONLY**: 既存 `## Retrospective` セクションは変更しない。`## Codify Decisions` を EOF に追記するのみ。
- **Frontmatter-only scan**: whole-file grep は body 引用テキストに self-trigger する。`awk` で frontmatter のみ抽出。
- **MVP 意味論**: `codified` は判断の記録のみ。実際の書き出しは follow-up cycle で実施。
- **Autonomous default**: まず AI が triage し、`skill` 候補や低確信ケースだけ人に聞く。
- **Idempotency**: `### Insight N` heading の存在で判定済みを確認。partial 完了でも再起動で残分のみ処理。

詳細: [skills/codify-insight/reference.md](../skills/codify-insight/reference.md)

## Scoring & Judgment

### Review Scores

| Score | Verdict | Action |
|-------|---------|--------|
| 0-49 | PASS | Auto-proceed |
| 50-79 | WARN | Socrates Protocol -> human judgment |
| 80-100 | BLOCK | Socrates Protocol -> human judgment |

### Socrates Protocol

WARN/BLOCK時にSocrates(Devil's Advocate)が反論を提示:
1. PdMの提案に対して3+の反論を生成
2. 代替案を提示
3. 人間が最終判断: proceed / fix / abort
