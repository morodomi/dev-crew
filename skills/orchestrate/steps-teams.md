# TDD Orchestrate - Agent Teams Mode (Experimental)

環境変数 `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` が有効時の手順。
1つのチームが全 Phase を通して存続し、Phase ごとに Teammate を spawn/shutdown する。

## Block 0: Prerequisite Check

### Cycle Doc Validation

orchestrate 開始前に、既存の成果物を確認して開始地点を決定する:

1. **Cycle doc の存在確認**:
   - ```bash
     find docs/cycles -name '*.md' ! -path '*/archive/*' | head -1
     ```
   - cycle doc が存在 → path を確定し、Progress Log の最終完了 Phase の次から再開
   - cycle doc が存在しない → 2. へ

2. **Plan ファイルの存在確認** (cycle doc なしの場合):
   - plan ファイルが存在し、`## TDD Context` セクションを含む → Phase 1 (Team 作成) → Phase 2 (kickoff) へ直行
   - plan ファイルが存在しない → plan mode で開始:
     1. `Skill(dev-crew:spec)` でTDDコンテキスト設定（planファイルに記録）
     2. 探索・設計・Test List・QAチェックをplan mode内で実施
     3. approve → auto-compact → normal modeへ → Phase 1 へ

**典型的フロー**: spec → approve → compact → orchestrate 自動起動時は、
cycle doc はまだなく plan ファイルが存在するため Phase 1 (Team 作成) → Phase 2 (kickoff) に直行する。

## Phase 1: Team 作成

plan mode承認後、Teammate ツールでチームを作成（1回のみ）:

```
Teammate(operation: "spawnTeam", team_name: "dev-cycle")
```

### socrates (on-demand advisor)

socrates は WARN/BLOCK 時のみ on-demand で起動する。PASS サイクル (~80%) では spawn しない。
詳細: [../../agents/socrates.md](../../agents/socrates.md)

## Phase 2: Block 1 - Kickoff (with Design Review)

### KICKOFF

architect teammate を起動し、Design Review Gate + Cycle doc 生成を委譲:

```
Task(subagent_type: "dev-crew:architect", team_name: "dev-cycle", name: "architect", model: "sonnet", prompt: "planファイルを読み取り、Design Review Gate を実施した後、PASS/WARN なら Skill(dev-crew:kickoff) を実行して Cycle doc を生成せよ。BLOCK の場合は Cycle doc を生成せず、問題点を報告せよ。")
→ Design Review Gate 実施
→ PASS/WARN: Skill(kickoff) 実行 → 結果報告
→ BLOCK: 失敗報告
→ SendMessage(type: "shutdown_request", recipient: "architect")
```

### Phase Summary 永続化 (KICKOFF→RED)

architect 完了後、PdM が Cycle doc に Phase Summary を追記:

```markdown
### Phase: KICKOFF - Completed at HH:MM
**Artifacts**: Cycle doc updated with PLAN section, Test List (N items)
**Decisions**: architecture=[approach], test strategy=[approach]
**Pre-Review**: verdict=[PASS/WARN/BLOCK], score=[N], issues=[summary]
**Next Phase Input**: Test List items TC-01 ~ TC-NN
**Subagent**: agent_id={architect_agent_id}, tokens={total_tokens}
```

### 自律判断

architect の `pre_review.verdict` でスコアベース判定:

- PASS (0-49) → Block 2 (Phase 3) へ自動進行
- WARN (50-79) / BLOCK (80+) → Socrates Protocol 発動:

#### Socrates Protocol (pre-review plan)

1. PdM → Task() で socrates を on-demand 起動（Phase名, スコア, reviewer サマリ, 提案, Progress Log）
   ```
   Task(subagent_type: "dev-crew:socrates", model: "opus", prompt: "Phase: pre-review:plan, Score: [N], Summary: [...], Proposal: [...], Progress Log: [Cycle doc の Progress Log 全文]")
   ```
2. socrates → 反論を返却（Objections + Alternative 形式）
3. PdM → 人間にメリデメを構造化してテキスト出力（自由入力を求める）
4. 人間 → 自由入力で判断（proceed / fix / abort / 番号選択）

初回発動時のみユーザー案内を表示（[reference.md](reference.md#初回発動時のユーザー案内) 参照）。

- proceed → Block 2 へ進行
- fix → architect を再起動して KICKOFF 再実行（max 1回再試行）
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
→ 実装 → 結果報告 → shutdown
```

PdM が全テスト成功（GREEN 状態）を確認。

### Phase Summary 永続化 (GREEN→REFACTOR)

```markdown
### Phase: GREEN - Completed at HH:MM
**Artifacts**: [implementation file paths]
**Decisions**: N/N tests passing
**Next Phase Input**: source files on disk, run refactor for quality
**Subagent**: agent_id={green_worker_agent_id}, tokens={total_tokens}
```

### REFACTOR + Verification Gate

Skill(dev-crew:refactor) を呼び出し、内部で Skill("simplify") を実行後、Verification Gate で品質確認:

```
Skill(dev-crew:refactor)
→ Skill("simplify") 実行 + Verification Gate（テスト全PASS + 静的解析0件 + フォーマット適用）
```

### Phase Summary 永続化 (REFACTOR→REVIEW)

```markdown
### Phase: REFACTOR - Completed at HH:MM
**Artifacts**: [refactored file paths]
**Decisions**: refactor=[changes made or "no changes needed"]
**Next Phase Input**: source files on disk, run review
**Subagent**: PdM direct (Skill(dev-crew:refactor))
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

1. PdM → Task() で socrates を on-demand 起動（Phase名, スコア, reviewer サマリ, 提案, Progress Log）
   ```
   Task(subagent_type: "dev-crew:socrates", model: "opus", prompt: "Phase: review:code, Score: [N], Summary: [...], Proposal: [...], Progress Log: [Cycle doc の Progress Log 全文]")
   ```
2. socrates → 反論を返却（Objections + Alternative 形式）
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

### Auto-Learn (COMMIT 後)

条件を満たす場合、COMMIT 後に learn を自動実行:

1. `DEV_CREW_AUTO_LEARN=1` が設定されている
2. `~/.claude/dev-crew/observations/log.jsonl` が存在する
3. 前回 learn 以降の観測数が閾値 (20件) 以上

```
Skill(dev-crew:learn)
→ パターン抽出（失敗時: 警告ログのみ、COMMIT 完了をブロックしない）
```

learn 実行後、`.last-learn-timestamp` を現在時刻で更新する。
learn 失敗時は警告を表示して正常終了する。サイクル全体の成否には影響しない。

### Team Cleanup

チームを解散:

```
Teammate(operation: "cleanup")
```

## Fallback

Agent Teams の起動に失敗した場合:
- 警告を表示: 「Agent Teams が利用できません。Subagent Chain にフォールバックします。」
- [steps-subagent.md](steps-subagent.md) の手順に切り替え
