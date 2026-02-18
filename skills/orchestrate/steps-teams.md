# TDD Orchestrate - Agent Teams Mode (Experimental)

環境変数 `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` が有効時の手順。
1つのチームが全 Phase を通して存続し、Phase ごとに Teammate を spawn/shutdown する。

## Block 0: Prerequisite Check

### Cycle Doc Validation

orchestrate 開始前に、Issue 番号と cycle doc の対応を確認する:

1. Issue 番号の特定:
   - ユーザー指定がある場合はそれを使用
   - 指定がない場合は AskUserQuestion で確認

2. Cycle doc の存在確認:
   ```bash
   find docs/cycles -name '*.md' -exec grep -l "issue:.*#${ISSUE_NUM}" {} +
   ```

3. 分岐処理:
   - cycle doc が存在 → path を確定し、Phase 1 (Team 作成) へ
   - cycle doc が存在しない → Skill(dev-crew:init) を実行してから Phase 1 へ

## Phase 1: Team 作成

Teammate ツールでチームを作成（INIT 時に1回のみ）:

```
Teammate(operation: "spawnTeam", team_name: "dev-cycle")
```

### socrates 起動（常駐 advisor）

Team 作成直後に socrates を spawn する。全 Phase を通じて常駐し、PdM の判断に反論する:

```
Task(subagent_type: "general-purpose", team_name: "dev-cycle", name: "socrates", model: "opus", mode: "plan")
# model: agents/socrates.md frontmatter の model フィールドに対応
```

socrates は read-only advisor であり、reviewer ではない。詳細: [../../agents/socrates.md](../../agents/socrates.md)

## Phase 2: Block 1 - Planning

### PLAN

architect teammate を起動し、設計・Test List 作成を委譲:

```
Task(subagent_type: "general-purpose", team_name: "dev-cycle", name: "architect", model: "sonnet")
# model: agents/architect.md frontmatter の model フィールドに対応
→ Skill(plan) 実行（review は実行しない）
→ 結果報告
→ SendMessage(type: "shutdown_request", recipient: "architect")
```

### review(plan)

統一レビュー (mode: plan) で設計レビュー:

```
Skill(dev-crew:review, args: "--plan")
→ review(plan) が Risk Classification + Brief + Specialist Panel を実行
```

### Phase Summary 永続化 (PLAN→RED)

review(plan) 完了後、PdM が Cycle doc に Phase Summary を追記:

```markdown
### Phase: PLAN - Completed at HH:MM
**Artifacts**: Cycle doc updated with PLAN section, Test List (N items)
**Decisions**: architecture=[approach], test strategy=[approach]
**Next Phase Input**: Test List items TC-01 ~ TC-NN
**Subagent**: agent_id={architect_agent_id}, tokens={total_tokens}
```

### 自律判断

スコアベース判定:

- PASS (0-49) → Block 2 (Phase 3) へ自動進行
- WARN (50-79) / BLOCK (80+) → Socrates Protocol 発動:

#### Socrates Protocol (review plan)

1. PdM → socrates に判断提案を SendMessage（Phase名, スコア, reviewer サマリ, 提案）
2. socrates → PdM に反論を返答（Objections + Alternative 形式）
3. PdM → 人間にメリデメを構造化してテキスト出力（自由入力を求める）
4. 人間 → 自由入力で判断（proceed / fix / abort / 番号選択）

初回発動時のみユーザー案内を表示（[reference.md](reference.md#初回発動時のユーザー案内) 参照）。

- proceed → Block 2 へ進行
- fix → architect を再起動して PLAN 再実行（max 1回再試行）
- abort → サイクル中断

### Delegation Decision

Phase Summary の metrics を評価し、次 Phase の実行方法を決定する:

| Metric | Lightweight Threshold | Heavy |
|--------|-----------------------|-------|
| line_count | < 200 | >= 200 |
| file_count | < 3 | >= 3 |

- 全 metrics が lightweight → PdM 直接実行（Skill() 呼び出し）
- いずれかが heavy → teammate 委譲（Task() 呼び出し）
- Default: always delegate to teammate (safest for token budget)

## Phase 3: Block 2 - Implementation

### RED

N 個の red-worker teammate を起動（テストファイル別）:

```
Task(subagent_type: "dev-crew:red-worker", team_name: "dev-cycle", name: "red-worker-N", model: "sonnet")
# model: agents/red-worker.md frontmatter の model フィールドに対応
→ テスト作成 → 結果報告 → shutdown
```

PdM がテスト失敗（RED 状態）を確認。

### Phase Summary 永続化 (RED→GREEN)

```markdown
### Phase: RED - Completed at HH:MM
**Artifacts**: [test file paths]
**Decisions**: test framework=[name], N tests created, all failing
**Next Phase Input**: test files on disk, implement to make them pass
**Subagent**: agent_id={red_worker_agent_id}, tokens={total_tokens}
```

### GREEN

N 個の green-worker teammate を起動（実装ファイル別）:

```
Task(subagent_type: "dev-crew:green-worker", team_name: "dev-cycle", name: "green-worker-N", model: "sonnet")
# model: agents/green-worker.md frontmatter の model フィールドに対応
→ 実装 → 結果報告 → shutdown
```

PdM が全テスト成功（GREEN 状態）を確認。

### Phase Summary 永続化 (GREEN→REFACTOR)

```markdown
### Phase: GREEN - Completed at HH:MM
**Artifacts**: [implementation file paths]
**Decisions**: N/N tests passing
**Next Phase Input**: source files on disk, refactor for quality
**Subagent**: agent_id={green_worker_agent_id}, tokens={total_tokens}
```

### REFACTOR

refactorer teammate を起動:

```
Task(subagent_type: "general-purpose", team_name: "dev-cycle", name: "refactorer", model: "sonnet")
# model: agents/refactorer.md frontmatter の model フィールドに対応
→ Skill(refactor) 実行 → 結果報告 → shutdown
```

### Phase Summary 永続化 (REFACTOR→REVIEW)

```markdown
### Phase: REFACTOR - Completed at HH:MM
**Artifacts**: [refactored file paths]
**Decisions**: refactoring=[changes made or "no changes needed"]
**Next Phase Input**: source files on disk, run review
**Subagent**: agent_id={refactorer_agent_id}, tokens={total_tokens}
```

### REVIEW (review code)

統一レビュー (mode: code) でコードレビュー:

```
Skill(dev-crew:review, args: "--code")
→ review(code) が Risk Classification + Brief + Specialist Panel を実行
→ security-reviewer + correctness-reviewer は常時起動 (NON-NEGOTIABLE)
```

### Phase Summary 永続化 (REVIEW→COMMIT)

review(code) 完了後、PdM が Cycle doc に Phase Summary を追記:

```markdown
### Phase: REVIEW - Completed at HH:MM
**Artifacts**: review results (mode: code)
**Decisions**: verdict=[PASS/WARN/BLOCK], score=[max score]
**Next Phase Input**: all tests passing, ready to commit
**Subagent**: agent_id={review_agent_id}, tokens={total_tokens}
```

### 自律判断

スコアベース判定:

- PASS (0-49) → DISCOVERED 判断へ自動進行
- WARN (50-79) / BLOCK (80+) → Socrates Protocol 発動:

#### Socrates Protocol (review code)

1. PdM → socrates に判断提案を SendMessage（Phase名, スコア, reviewer サマリ, 提案）
2. socrates → PdM に反論を返答（Objections + Alternative 形式）
3. PdM → 人間にメリデメを構造化してテキスト出力（自由入力を求める）
4. 人間 → 自由入力で判断（proceed / fix / abort / 番号選択）

- proceed → DISCOVERED 判断へ進行
- fix → green-worker を再起動して修正（max 1回再試行）
- abort → サイクル中断

### DISCOVERED 判断

REVIEW が PASS/WARN の場合、Cycle doc の DISCOVERED セクションを確認:

1. DISCOVERED が空 → スキップして Block 3 へ
2. 起票済み（`→ #` 付き）の項目 → スキップ
3. 未起票の項目がある場合:

```bash
# 事前チェック
gh auth status 2>/dev/null || echo "gh CLI未認証。issue起票をスキップします。"
```

ユーザーに確認:
```
DISCOVERED items found:
1. [項目の要約]
GitHub issue を作成しますか? (Y/n)
```

承認後、各項目に対して:
```bash
gh issue create --title "[DISCOVERED] <要約>" --body "$(cat <<'EOF'
## 発見元
- Cycle: docs/cycles/<cycle-doc>.md
- Phase: REVIEW
- Reviewer: <reviewer名 or 手動>

## 内容
<DISCOVERED セクションの記載内容>
EOF
)" --label "discovered"
```

起票後、Cycle doc の DISCOVERED セクションに `→ #<issue番号>` を付記。

## Phase 4: Block 3 - Finalization

### COMMIT

PdM (Lead) が直接実行:

```
git add <files>
git commit -m "..."
```

### Team Cleanup

socrates を shutdown してからチームを解散:

```
SendMessage(type: "shutdown_request", recipient: "socrates")
Teammate(operation: "cleanup")
```

## Fallback

Agent Teams の起動に失敗した場合:
- 警告を表示: 「Agent Teams が利用できません。Subagent Chain にフォールバックします。」
- [steps-subagent.md](steps-subagent.md) の手順に切り替え
