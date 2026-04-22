# TDD Orchestrate - Agent Teams Mode (Experimental)

環境変数 `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` が有効時の手順。
1つのチームが全 Phase を通して存続し、Phase ごとに Teammate を spawn/shutdown する。

> **NOTE**: Codex利用可能時は [steps-codex.md](steps-codex.md) が優先される。

## Block 0: Prerequisite Check

planファイルを起点に開始地点を決定する:

### 1. planファイルの存在確認

planファイルに `## TDD Context` セクションがあるか確認する。

- **あり** → 1a. へ
- **なし** → 2. へ

### 1a. 未完了 Cycle doc の確認

frontmatter のみを対象に `phase: DONE` でないファイルを抽出（本文中の文字列に影響されない）:

```bash
for f in docs/cycles/*.md; do awk '/^---$/{c++;next} c==1{print}' "$f" | grep -q 'phase: DONE' || echo "$f"; done 2>/dev/null | head -1
```

- **未完了 cycle doc あり** →
  - plan-review 記録あり (Cycle doc に `plan_review` セクション存在)? → Block 1 スキップ → Block 2a (RED) へ
  - plan-review 記録なし? → Progress Log の最終完了 Phase の次から再開
- **なし (DONE のみ or cycle doc なし)** → Phase 1 (Team 作成) → Phase 2 (sync-plan) へ直行

**典型的フロー**: spec → review --plan → approve → compact → orchestrate 自動起動時は、
plan ファイルが存在し cycle doc はまだないため Phase 1 (Team 作成) → Phase 2 (sync-plan) に直行する。

### 2. 新規開始 (plan mode)

plan ファイルが存在しない場合、plan mode で新規開始:

1. `Skill(dev-crew:spec)` でTDDコンテキスト設定（planファイルに記録）
2. 探索・設計・Test List・QAチェックをplan mode内で実施
3. `Skill(dev-crew:review, args: "--plan")` で設計レビュー
4. approve → auto-compact → normal modeへ → Phase 1 へ

## Phase 1: Team 作成

plan mode承認後、Teammate ツールでチームを作成（1回のみ）:

```
Teammate(operation: "spawnTeam", team_name: "dev-cycle")
```

### socrates (on-demand advisor)

socrates は WARN/BLOCK 時のみ on-demand で起動する。PASS サイクル (~80%) では spawn しない。
詳細: [../../agents/socrates.md](../../agents/socrates.md)

## Phase 2: Block 1 - Sync-Plan (with Design Review)

### SYNC-PLAN

architect teammate を起動し、Design Review Gate + Cycle doc 生成を委譲:

```
Task(subagent_type: "dev-crew:architect", team_name: "dev-cycle", name: "architect", model: "sonnet", prompt: "planファイルを読み取り、Design Review Gate を実施した後、PASS/WARN なら Task(dev-crew:sync-plan) を実行して Cycle doc を生成せよ。BLOCK の場合は Cycle doc を生成せず、問題点を報告せよ。")
→ Design Review Gate 実施
→ PASS/WARN: Task(sync-plan) 実行 → 結果報告
→ BLOCK: 失敗報告
→ SendMessage(type: "shutdown_request", recipient: "architect")
```

### Phase Summary 永続化 (sync-plan→RED)

architect 完了後、PdM が Cycle doc に Phase Summary を追記:

```markdown
### Phase: SYNC-PLAN - Completed at HH:MM
**Artifacts**: Cycle doc updated with PLAN section, Test List (N items)
**Decisions**: architecture=[approach], test strategy=[approach]
**Pre-Review**: verdict=[PASS/WARN/BLOCK], score=[N], issues=[summary]
**Next Phase Input**: Test List items TC-01 ~ TC-NN
**Subagent**: agent_id={architect_agent_id}, tokens={total_tokens}
```

### 自律判断

architect の `pre_review.verdict` でスコアベース判定:

- PASS (0-49) → Block 2a (Phase 3) へ自動進行
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

- proceed → Block 2a へ進行
- fix → architect を再起動して sync-plan 再実行（max 1回再試行）
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

Skill(dev-crew:refactor) を呼び出し、チェックリスト駆動でコード品質改善後、Verification Gate で品質確認:

```
Skill(dev-crew:refactor)
→ チェックリスト駆動リファクタリング + Verification Gate（テスト全PASS + 静的解析0件 + フォーマット適用）
```

### Phase Summary 永続化 (REFACTOR→REVIEW)

```markdown
### Phase: REFACTOR - Completed at HH:MM
**Artifacts**: [refactored file paths]
**Decisions**: refactor=[changes made or "no changes needed"]
**Next Phase Input**: source files on disk, run product verification (if defined)
**Subagent**: PdM direct (Skill(dev-crew:refactor))
```

### VERIFY (Product Verification)

PdM が直接 Bash で実行（参考エビデンス、委譲不要）。
Cycle doc `## Verification` セクション不在 → サイレントスキップ。
詳細: [reference.md](reference.md#product-verification)

### REVIEW (review code)

#### Claude レビュー

```
Skill(dev-crew:review, args: "--code")
→ review(code) が Risk Classification + Brief + Specialist Panel を実行
→ security-reviewer + correctness-reviewer は常時起動 (NON-NEGOTIABLE)
```

#### Codex competitive review（Codex 利用可能時）

`which codex` で Codex が利用可能なら、Claude レビューに加えて Codex レビューを実行する。
codex_mode に関わらず常時実行（codex_mode は RED/GREEN 委譲のみ制御）。

```bash
# codex_session_id があれば resume <session-id>、なければ resume --last にフォールバック
codex exec resume ${codex_session_id:-"--last"} --full-auto -o /tmp/codex_review.md \
  "Review uncommitted changes. セキュリティ・正確性・パフォーマンスの観点で問題を指摘せよ。"
```

`codex_session_id` は Cycle doc frontmatter から読み取る。Codex 失敗 → Claude レビューのみで続行。findings 裁定は steps-codex.md の Findings Judgment テーブルに準拠。

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

1. DISCOVERED が空 → スキップして Block 2f へ
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

### Block 2f: RETROSPECTIVE (cycle-retrospective)

DISCOVERED 完了後、COMMIT 前に実行する:

```
Skill(dev-crew:cycle-retrospective)
```

- 正常終了 (exit 0) → retro_status: captured または resolved → Block 3 へ
- abort signal (exit 1) → COMMIT をスキップして停止。「cycle-retrospective aborted by user. 手動で fix してから /orchestrate を再起動してください」と出力
- `default: abort`（安全側）。abort → BLOCK、proceed のみ Block 3 へ進行

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
2. `${CLAUDE_PLUGIN_DATA}/observations/log.jsonl` が存在する
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
