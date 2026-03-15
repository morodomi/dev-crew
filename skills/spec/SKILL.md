---
name: spec
description: TDDサイクルのコンテキストをplan mode内で設定する（plan mode専用）。Triggers on "spec", "new feature", "start TDD", "add feature", "機能追加", "TDDを始めたい", "新しい機能", "開発を始める", "新規開発". Do NOT use for continuing an existing cycle (check docs/cycles/ first).
allowed-tools: Read, Bash, Grep, Glob, AskUserQuestion
---

# TDD INIT Phase (Plan Mode)

plan mode内でTDDコンテキストを設定し、planファイルに記録する。

## Plan Mode Check

**plan modeでない場合**: 「plan modeで開始してください。EnterPlanMode → /spec」と案内して終了。

## Progress Checklist

```
INIT Progress:
- [ ] STATUS確認 → 環境収集 → 既存cycle確認
- [ ] 実装内容確認 → リスク評価 → スコープ確認
- [ ] planファイルにTDDコンテキスト記録
```

## Restrictions

- planファイルへの記録のみ（Cycle docはsync-planで作成）
- No implementation planning（plan modeの探索・設計で行う）
- No test/implementation code

## Workflow

### Step 1: Check Project Status

```bash
cat docs/STATUS.md 2>/dev/null
```

If not found, recommend `onboard`. Also check hooks: [reference.md](reference.md#hooks-check)

#### Version Gate

1. `.claude/dev-crew.json` を読む。`.claude/dev-crew.json missing` なら警告して停止。
2. `installed_plugins.json` から現在の dev-crew バージョンを取得して比較する。
3. 記録済みバージョンと不一致なら警告して停止する。

### Step 2: Collect Environment Info

Collect language versions and key packages. Details: [reference.md](reference.md)

### Step 3: Check Existing Cycles

```bash
ls -t docs/cycles/*.md 2>/dev/null | head -1
```

If an active cycle exists, recommend continuing it.

### Step 4: Ask What to Implement

Ask "What feature do you want to implement?" e.g., login, CSV export.

### Step 4.5: Risk Score Assessment

Calculate risk score (0-100). Keyword scores: [reference.md](reference.md)

| Score | Result | Action |
|-------|--------|--------|
| 0-29 | PASS | Auto-proceed |
| 30-59 | WARN | Quick questions ([reference.md](reference.md#warn-questions-30-59)) |
| 60-100 | BLOCK | Brainstorm ([reference.md](reference.md#brainstorm-questions-block-60-1)) |

### Step 4.8: Ambiguity Detection ([reference.md](reference.md#ambiguity-detection))

ユーザーの回答から仕様の曖昧さを検出し、Questioning Protocolで解消。カテゴリ: Data, API, UI/UX, Scope, Edge cases

### Step 5: Scope (Layer) Confirmation

Use AskUserQuestion to confirm scope. Details: [reference.md](reference.md)

| Layer | Description | Plugin |
|-------|-------------|--------|
| Backend | PHP/Python etc. | php, python, flask |
| Frontend | JavaScript/TypeScript | js, ts |
| Both | Full stack | Multiple plugins |

### Step 6: Record to Plan File

planファイルにTDDコンテキストを記録。テンプレート: [reference.md](reference.md#plan-file-template)

**必須**: planファイル末尾に `## Post-Approve Action` セクションを含めること。これがcompact後のauto-orchestrateトリガーになる。

### Step 7: Continue in Plan Mode

specの記録後、plan mode内で以下を続行（specスキルの範囲外）:

1. **探索**: コードベース調査（最低5ファイル読む）
2. **設計**: アーキテクチャ決定、設計方針
3. **Test List**: Given/When/Then形式
4. **QAチェック**: カバレッジ・粒度・セキュリティ・独立性

→ review --plan → approve → 自動orchestrate（sync-plan→RED→GREEN→...）

## Reference

Details: [reference.md](reference.md) | Japanese: [reference.ja.md](reference.ja.md)
