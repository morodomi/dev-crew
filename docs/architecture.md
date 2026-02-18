# Architecture Design

## Overview

dev-crewは、AI開発チームをClaude Code Pluginとして実現する。
PdM（プロダクトマネージャー）がワークフロー全体をオーケストレートし、
Engineer、Designer、Security Auditorが各フェーズを担当する。

## System Architecture

```
User
  │
  ├── /init "feature description"
  │
  ▼
┌─────────────────────────────────────────────┐
│  PdM (Orchestrator)                         │
│  ┌─────────┐  ┌─────────┐  ┌───────────────┐ │
│  │ INIT    │→│ PLAN    │→│ review(plan) │ │
│  └─────────┘  └─────────┘  └───────────────┘ │
│       │            │              │           │
│       │    phase-compact    phase-compact      │
│       │            │              │           │
│  ┌─────────┐  ┌─────────┐  ┌───────────┐     │
│  │ RED     │→│ GREEN   │→│ REFACTOR  │     │
│  └─────────┘  └─────────┘  └───────────┘     │
│       │            │              │           │
│       │    phase-compact    phase-compact      │
│       │            │              │           │
│  ┌───────────────┐  ┌─────────┐               │
│  │ review(code) │→│ COMMIT  │               │
│  └───────────────┘  └─────────┘               │
└─────────────────────────────────────────────┘
```

## Plugin Architecture

### Single Plugin Structure

dev-crewは単一のClaude Code Plugin。1回のinstallで全機能が有効化される。

```
dev-crew/
├── .claude-plugin/plugin.json    # Single plugin metadata
├── agents/                       # 33 agents (flat)
│   ├── Orchestration: socrates.md
│   ├── Implementation: architect.md, red-worker.md, green-worker.md, refactorer.md
│   ├── Review (7): *-reviewer.md + review-briefer.md
│   ├── Security (18): *-attacker.md, recon-agent.md, etc.
│   └── Meta: observer.md
├── skills/                       # 26 skills (flat)
│   ├── Workflow (7): init/, plan/, red/, green/, refactor/, review/, commit/
│   ├── Orchestration (3): orchestrate/, phase-compact/, strategy/
│   ├── Diagnostic (2): diagnose/, parallel/
│   ├── Setup (1): onboard/
│   ├── Security (4): security-scan/, attack-report/, context-review/, generate-e2e/
│   ├── Language Quality (7): php-quality/, python-quality/, ts-quality/, etc.
│   └── Meta (2): learn/, evolve/
├── rules/                        # Always-applied rules
├── hooks/hooks.json              # Auto-loaded hooks
└── scripts/hooks/                # Shell scripts for hooks
```

## Token Optimization Architecture

### Problem

Agent Teams + review(code: 3-6並行) + review(plan: 2-6並行) により、
1セッションで5時間windowを使い切る。
主因は会話履歴の累積。v2ではRisk-Based Scalingで改善。

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
| INIT -> PLAN | Cycle doc (scope, env) | Cycle doc |
| PLAN -> RED | Test List | Cycle doc + Test List |
| RED -> GREEN | Test files (on disk) | Cycle doc + test files |
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

### Within Session (phase-compact)

Cycle doc acts as persistent state across compaction boundaries.

### Across Sessions (future: ai-company scope)

- cc-session-manager hooks for state save/restore
- memory/ files for cross-session knowledge
- meta plugin learn/evolve for pattern accumulation

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
