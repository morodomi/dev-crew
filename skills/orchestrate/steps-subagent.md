# TDD Orchestrate - Subagent Chain Mode

環境変数 `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` が無効時の手順。
各フェーズを Task() で subagent に委譲し、コンテキスト分離を実現する。

注: 各 Phase は独立した subagent で実行される。重い作業は subagent 内で完結し、
PdM には結果サマリーのみ返却されるため、コンテキストが自然に圧縮される。

**Phase Summary は Block 境界のみ（2箇所）**: Agent Teams mode（5箇所）との非対称は意図的。
Task() 委譲により各フェーズが既にコンテキスト分離されているため、
Block 内の中間 Phase Summary は冗長。Block 境界での永続化で十分。

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

- **未完了 cycle doc あり** → path を確定し、Progress Log の最終完了 Phase の次から再開
- **なし (DONE のみ or cycle doc なし)** → Block 1 (kickoff) へ直行

**典型的フロー**: spec → review --plan → approve → compact → orchestrate 自動起動時は、
plan ファイルが存在し cycle doc はまだないため Block 1 (kickoff) に直行する。

### 2. 新規開始 (plan mode)

plan ファイルが存在しない場合、plan mode で新規開始:

1. `Skill(dev-crew:spec)` でTDDコンテキスト設定（planファイルに記録）
2. 探索・設計・Test List・QAチェックをplan mode内で実施
3. `Skill(dev-crew:review, args: "--plan")` で設計レビュー
4. approve → auto-compact → normal modeへ → Block 1 へ

## Block 1: Kickoff (with Design Review)

> Pre-Flight Check:
> - [ ] plan modeが承認済みか？
> - [ ] planファイルが存在するか？

### KICKOFF

> **MUST**: Task() で委譲すること。PdM による Skill() 直接呼び出し禁止。

```
Task(subagent_type: "dev-crew:architect", model: "sonnet", prompt: "planファイルを読み取り、Design Review Gate を実施した後、PASS/WARN なら Skill(dev-crew:kickoff) を実行して Cycle doc を生成せよ。BLOCK の場合は Cycle doc を生成せず、問題点を報告せよ。")
→ architect が Design Review Gate を実施
→ PASS/WARN: Skill(kickoff) 実行 → 結果 JSON 返却（pre_review 付き）
→ BLOCK: 失敗 JSON 返却（pre_review.verdict = "BLOCK"）
```

architect の結果 JSON の `pre_review.verdict` で分岐:

- PASS → Phase Summary 永続化 → Block 2 へ
- WARN → 警告ログ出力 → Phase Summary 永続化 → Block 2 へ（v5.0 互換）
- BLOCK → Task() を再起動して KICKOFF 再実行（max 1回）→ 再度 BLOCK ならユーザーに報告

### Delegation Decision

Phase Summary の metrics を評価し、delegation decision を行う。
Subagent Chain モードでは **全フェーズを Task() で委譲する**（lightweight threshold 以下でも同様）。
PdM は Skill() を直接呼び出してはならない（REFACTOR・review・COMMIT を除く）。
Fallback は Task() spawn エラー時のみ適用される（後述）。

### Phase Summary 永続化 (KICKOFF→RED)

PdM が Cycle doc に Phase Summary を追記:

```markdown
### Phase: KICKOFF - Completed at HH:MM
**Artifacts**: Cycle doc updated with PLAN section, Test List (N items)
**Decisions**: architecture=[approach], test strategy=[approach]
**Pre-Review**: verdict=[PASS/WARN/BLOCK], score=[N], issues=[summary]
**Next Phase Input**: Test List items TC-01 ~ TC-NN
**Subagent**: agent_id={architect_agent_id}, tokens={total_tokens}
```

## Block 2: Implementation

> Pre-Flight Check:
> - [ ] KICKOFF: Task() で委譲しているか？
> - [ ] RED/GREEN: Task() で worker に委譲しているか？
> - [ ] Skill() 直接呼び出しは REFACTOR・review・COMMIT のみか？

### RED

> **MUST**: Task() で委譲すること。PdM による Skill() 直接呼び出し禁止。

```
Task(subagent_type: "dev-crew:red-worker", model: "sonnet", prompt: "Cycle doc: [path]. 担当テストケース: [TC-XX]. テストを作成し、失敗を確認せよ。")
→ red-worker が subagent 内でテスト作成
→ 結果 JSON 返却
```

PdM がテスト失敗（RED 状態）を確認。

### GREEN

> **MUST**: Task() で委譲すること。PdM による Skill() 直接呼び出し禁止。

```
Task(subagent_type: "dev-crew:green-worker", model: "sonnet", prompt: "Cycle doc: [path]. テストを通す最小限の実装を行え。")
→ green-worker が subagent 内で実装
→ 結果 JSON 返却
```

PdM が全テスト成功（GREEN 状態）を確認。

### REFACTOR + Verification Gate

> NOTE: refactor 内部で Skill("simplify") を呼び出し済みのため、Skill() 直接呼び出しが正しい。

Skill(dev-crew:refactor) を呼び出し、内部で Skill("simplify") を実行後、Verification Gate で品質確認:

```
Skill(dev-crew:refactor)
→ Skill("simplify") 実行 + Verification Gate（テスト全PASS + 静的解析0件 + フォーマット適用）
```

### REVIEW

> NOTE: review 内部で subagent 化済みのため、Skill() 直接呼び出しが正しい。

```
Skill(dev-crew:review, args: "--code")
→ review(code) が Risk Classification + Brief + Specialist Panel を実行
→ security-reviewer + correctness-reviewer は常時起動 (NON-NEGOTIABLE)
```

PdM がスコアを判定:
- PASS/WARN → DISCOVERED 判断へ
- BLOCK → GREEN の Task() を再起動して修正（max 1回）

### Phase Summary 永続化 (Block2→Block3)

Block 2 完了後、PdM が Cycle doc に Phase Summary を追記:

```markdown
### Phase: REVIEW - Completed at HH:MM
**Artifacts**: review results (mode: code)
**Decisions**: verdict=[PASS/WARN/BLOCK], score=[max score]
**Next Phase Input**: all tests passing, ready to commit
**Subagent**: agent_id={review_agent_id}, tokens={total_tokens}
```

### DISCOVERED 判断

REVIEW が PASS/WARN の場合、Cycle doc の DISCOVERED セクションを確認し、
スコープ外の未起票項目を GitHub issue に起票する。
詳細は review の [reference.md](../review/reference.md#discovered-issue-起票) を参照。

## Block 3: Finalization

```
Skill(dev-crew:commit)
→ サイクル完了
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

## 判断基準

Subagent Chain モードでも PdM の判断基準は同一:

| スコア | 判定 | アクション |
|--------|------|-----------|
| 0-49 | PASS | 次 Block へ自動進行 |
| 50-79 | WARN | 警告ログ、次 Block へ自動進行 |
| 80-100 | BLOCK | 1回目: 自動再試行、2回目: ユーザーに報告 |

## Fallback

Task() の起動に失敗した場合（subagent spawn エラー、タイムアウト等）のみ適用。

1. 警告を表示: 「Task() 委譲に失敗しました。Skill() 直接実行にフォールバックします。」
2. 該当フェーズを Skill() で直接実行:

| Phase | Fallback |
|-------|----------|
| KICKOFF | `Skill(dev-crew:kickoff)` |
| RED | `Skill(dev-crew:red)` |
| GREEN | `Skill(dev-crew:green)` |
| REFACTOR | `Skill(dev-crew:refactor)` |
| REVIEW | `Skill(dev-crew:review)` |

3. Cycle doc の Progress Log に fallback を記録
4. Phase Summary の Subagent 行を `**Subagent**: fallback (Skill direct)` とする
