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
│  ┌─────────┐  ┌─────────┐  ┌─────────────┐ │
│  │ INIT    │→│ PLAN    │→│ plan-review │ │
│  └─────────┘  └─────────┘  └─────────────┘ │
│       │            │              │         │
│       │    phase-compact    phase-compact    │
│       │            │              │         │
│  ┌─────────┐  ┌─────────┐  ┌───────────┐   │
│  │ RED     │→│ GREEN   │→│ REFACTOR  │   │
│  └─────────┘  └─────────┘  └───────────┘   │
│       │            │              │         │
│       │    phase-compact    phase-compact    │
│       │            │              │         │
│  ┌──────────────┐  ┌─────────┐              │
│  │ quality-gate │→│ COMMIT  │              │
│  └──────────────┘  └─────────┘              │
└─────────────────────────────────────────────┘
```

## Plugin Architecture

### Plugin Dependency

```
core (required)
├── php / python / typescript / javascript / flask / flutter / hugo (optional, language-specific)
├── security (optional, pre-release audit)
└── meta (optional, pattern learning)
```

- `core` は必須。ワークフローエンジン + レビューエージェントを含む
- 言語プラグインはプロジェクトの言語に応じて選択
- `security` はリリース前監査用
- `meta` はパターン学習・スキル進化用

### Core Plugin Internal Architecture

```
core/
├── agents/
│   ├── Orchestration
│   │   ├── pdm.md              # PdM: 全フェーズ管理
│   │   └── socrates.md         # Devil's Advocate
│   │
│   ├── Implementation
│   │   ├── architect.md        # PLAN phase設計
│   │   ├── red-worker.md       # REDテスト作成
│   │   ├── green-worker.md     # GREEN実装
│   │   └── refactorer.md       # REFACTOR品質改善
│   │
│   ├── Design
│   │   └── designer.md         # UI/UXデザイン (NEW)
│   │
│   └── Review (parallel execution)
│       ├── correctness-reviewer.md
│       ├── performance-reviewer.md
│       ├── security-reviewer.md
│       ├── guidelines-reviewer.md
│       ├── scope-reviewer.md
│       ├── architecture-reviewer.md
│       ├── risk-reviewer.md
│       ├── product-reviewer.md
│       └── usability-reviewer.md
│
└── skills/
    ├── Workflow (7 phases)
    │   ├── init/
    │   ├── plan/
    │   ├── red/
    │   ├── green/
    │   ├── refactor/
    │   ├── review/
    │   └── commit/
    │
    ├── Review Gates
    │   ├── plan-review/        # 5 agent parallel
    │   └── quality-gate/       # 6 agent parallel
    │
    ├── Orchestration
    │   ├── orchestrate/        # PdM全体管理
    │   └── phase-compact/      # フェーズ境界compaction (NEW)
    │
    ├── Diagnostic
    │   ├── diagnose/           # 並列仮説調査
    │   └── parallel/           # クロスレイヤー並列開発
    │
    └── Setup
        └── onboard/            # プロジェクト初期セットアップ
```

## Token Optimization Architecture

### Problem

Agent Teams + quality-gate(6並行) + plan-review(5並行) により、
1セッションで5時間windowを使い切る。
主因は会話履歴の累積。

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
