# TDD Orchestrate - Subagent Chain Mode

環境変数 `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` が無効時の手順。
各フェーズを Task() で subagent に委譲し、コンテキスト分離を実現する。

注: 各 Phase は独立した subagent で実行される。重い作業は subagent 内で完結し、
PdM には結果サマリーのみ返却されるため、コンテキストが自然に圧縮される。

**Phase Summary は Block 境界のみ（2箇所）**: Agent Teams mode（5箇所）との非対称は意図的。
Task() 委譲により各フェーズが既にコンテキスト分離されているため、
Block 内の中間 Phase Summary は冗長。Block 境界での永続化で十分。

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
   - cycle doc が存在 → path を確定し、Block 1 (Planning) へ
   - cycle doc が存在しない → Skill(dev-crew:init) を実行してから Block 1 へ

## Block 1: Planning

> Pre-Flight Check:
> - [ ] PLAN: Task() で architect に委譲しているか？
> - [ ] RED/GREEN/REFACTOR: Task() で worker に委譲しているか？
> - [ ] Skill() 直接呼び出しは review と COMMIT のみか？

### PLAN

> **MUST**: Task() で委譲すること。PdM による Skill() 直接呼び出し禁止。

```
Task(subagent_type: "dev-crew:architect", model: "sonnet", prompt: "Cycle doc: [path]. Skill(dev-crew:plan)を実行し、設計・Test Listを作成せよ。")
# model: agents/architect.md frontmatter の model フィールドに対応
→ architect が subagent 内で Skill(plan) を実行（review は実行しない）
→ 結果 JSON 返却
```

PdM が Skill(dev-crew:review) を `--plan` モードで実行し、スコアを判定:

```
Skill(dev-crew:review, args: "--plan")
→ review(plan) が Risk Classification + Brief + Specialist Panel を実行
→ 結果スコア返却
```

- PASS/WARN → Phase Summary 永続化 → Block 2 へ
- BLOCK → Task() を再起動して PLAN 再実行（max 1回）

### Delegation Rule

Subagent Chain モードでは **全フェーズを Task() で委譲する**。例外なし。
PdM は Skill() を直接呼び出してはならない（review と COMMIT を除く）。
Fallback は Task() spawn エラー時のみ適用される（後述）。
Phase Summary の metrics に基づく delegation decision は行わない（旧ロジック廃止）。

### Phase Summary 永続化 (PLAN→RED)

PdM が Cycle doc に Phase Summary を追記:

```markdown
### Phase: PLAN - Completed at HH:MM
**Artifacts**: Cycle doc updated with PLAN section, Test List (N items)
**Decisions**: architecture=[approach], test strategy=[approach]
**Next Phase Input**: Test List items TC-01 ~ TC-NN
**Subagent**: agent_id={architect_agent_id}, tokens={total_tokens}
```

## Block 2: Implementation

> Pre-Flight Check:
> - [ ] PLAN: Task() で architect に委譲しているか？
> - [ ] RED/GREEN/REFACTOR: Task() で worker に委譲しているか？
> - [ ] Skill() 直接呼び出しは review と COMMIT のみか？

### RED

> **MUST**: Task() で委譲すること。PdM による Skill() 直接呼び出し禁止。

```
Task(subagent_type: "dev-crew:red-worker", model: "sonnet", prompt: "Cycle doc: [path]. 担当テストケース: [TC-XX]. テストを作成し、失敗を確認せよ。")
# model: agents/red-worker.md frontmatter の model フィールドに対応
→ red-worker が subagent 内でテスト作成
→ 結果 JSON 返却
```

PdM がテスト失敗（RED 状態）を確認。

### GREEN

> **MUST**: Task() で委譲すること。PdM による Skill() 直接呼び出し禁止。

```
Task(subagent_type: "dev-crew:green-worker", model: "sonnet", prompt: "Cycle doc: [path]. テストを通す最小限の実装を行え。")
# model: agents/green-worker.md frontmatter の model フィールドに対応
→ green-worker が subagent 内で実装
→ 結果 JSON 返却
```

PdM が全テスト成功（GREEN 状態）を確認。

### REFACTOR

> **MUST**: Task() で委譲すること。PdM による Skill() 直接呼び出し禁止。

```
Task(subagent_type: "dev-crew:refactorer", model: "sonnet", prompt: "Cycle doc: [path]. Skill(dev-crew:refactor)を実行し、コード品質を改善せよ。")
# model: agents/refactorer.md frontmatter の model フィールドに対応
→ refactorer が subagent 内で Skill(refactor) 実行
→ 結果 JSON 返却
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

```bash
if [ "${DEV_CREW_AUTO_LEARN:-0}" = "1" ] && [ -f ~/.claude/dev-crew/observations/log.jsonl ]; then
  # learn を実行
fi
```

```
Skill(dev-crew:learn)
→ パターン抽出（失敗時: 警告ログのみ、COMMIT 完了をブロックしない）
```

learn 失敗時は警告を表示して正常終了する。サイクル全体の成否には影響しない。

## 判断基準

Subagent Chain モードでも PdM の判断基準は同一:

| スコア | 判定 | アクション |
|--------|------|-----------|
| 0-49 | PASS | 次 Block へ自動進行 |
| 50-79 | WARN | 警告ログ、次 Block へ自動進行 |
| 80-100 | BLOCK | 1回目: 自動再試行、2回目: ユーザーに報告 |

## Fallback

Task() の起動に失敗した場合（subagent spawn エラー、タイムアウト等）のみ適用。
PdM の判断による Skill() 直接実行は Fallback ではない（禁止）。

1. 警告を表示: 「Task() 委譲に失敗しました。Skill() 直接実行にフォールバックします。」
2. 該当フェーズを Skill() で直接実行:

| Phase | Fallback |
|-------|----------|
| PLAN | `Skill(dev-crew:plan)` |
| RED | `Skill(dev-crew:red)` |
| GREEN | `Skill(dev-crew:green)` |
| REFACTOR | `Skill(dev-crew:refactor)` |
| REVIEW | `Skill(dev-crew:review)` |

3. Cycle doc の Progress Log に fallback を記録:
   `- [Phase名] Task() failed, fallback to Skill() direct execution`
4. Phase Summary の Subagent 行を `**Subagent**: fallback (Skill direct)` とする
