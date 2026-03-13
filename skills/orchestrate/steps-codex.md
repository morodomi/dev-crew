# TDD Orchestrate - Codex Delegation Mode

`which codex` でCodex利用可能時の手順。RED/GREEN/REVIEWをCodexに委譲し、Claude Code (PdM) がGate検証で品質を担保する。

## Pre-check

```bash
which codex
```

- 存在する → 本手順で進行
- 存在しない → [steps-subagent.md](steps-subagent.md) or [steps-teams.md](steps-teams.md) にフォールバック

## Session Management

- kickoff debateでCodexセッション作成済み（Cycle docにsession ID記録済み）→ `resume --last` で継続
- debateなし → REDで新規セッション作成、session IDをCycle doc Progress Logに記録
- `resume --last` はcwdフィルタ済みのため同ディレクトリ内の最新セッションが選ばれる
- 同一ディレクトリで並行Codex実行禁止（1 cycle = 1 session）

## Block 0-1: Prerequisite & Kickoff

既存フロー（steps-subagent.md / steps-teams.md）と同一。Codex委譲はBlock 2から。

## Block 2: Implementation

### RED via Codex

1. プロンプト構築: Cycle doc Test List + テスト対象ファイル情報
2. 実行:
   ```bash
   codex exec resume --last --full-auto -o /tmp/codex_red.md "Cycle doc: [path]. Test List: [items]. テストを作成し、失敗を確認せよ。"
   ```
   セッションなければ:
   ```bash
   codex exec --full-auto -o /tmp/codex_red.md -C <dir> "Cycle doc: [path]. Test List: [items]. テストを作成し、失敗を確認せよ。"
   ```
3. **Gate 1**: PdMがプロジェクトのテストコマンドを実行 → 新規テストがFAILし、テストコマンドが非ゼロexit codeを返すことを確認
4. Test Plan整合性: テストがCycle doc Test Listと対応しているか確認
5. PASS → GREEN / FAIL → retry 1回 → fallback to Task(red-worker)

### GREEN via Codex

1. 実行:
   ```bash
   codex exec resume --last --full-auto -o /tmp/codex_green.md "Cycle doc: [path]. テストを通す最小限の実装を行え。"
   ```
2. **Gate 2**: PdMがテストコマンドを実行 → 全テストPASS（ゼロexit code）確認（新規テスト含む）
3. PASS → REFACTOR / FAIL → retry 2回 → fallback to Task(green-worker)

### Phase Summary 永続化 (Block2 境界)

Subagent Chainモードと同様、Block境界でPhase Summaryを永続化する:

```markdown
### Phase: RED (Codex) - Completed at HH:MM
**Artifacts**: [test file paths]
**Decisions**: N tests created, all failing (Gate 1 passed)
**Codex Session**: resume --last (session: <id>)
```

GREEN/REVIEW完了後も同様に永続化。

### REFACTOR (unchanged)

Codex委譲なし。Claude Code直接実行:

```
Skill(dev-crew:refactor)
```

### REVIEW via Codex (supplementary)

1. 実行:
   ```bash
   codex exec resume --last --full-auto -o /tmp/codex_review.md "Review uncommitted changes. セキュリティ・正確性・パフォーマンスの観点で問題を指摘せよ。"
   ```
2. Codexレビュー結果はProgress Logに追記（advisory）
3. 既存 `Skill(dev-crew:review, args: "--code")` を必ず実行（scoring権限はClaude Code側）
4. Codex失敗 → 既存reviewのみ（品質バー維持）

### REVIEW 後の判断

PdMがスコアを判定（既存reviewの結果で判断。Codexレビューはadvisory）:
- PASS/WARN → DISCOVERED 判断へ（既存モードと同一フロー）
- BLOCK → GREEN再実行（Codex or fallback）

### DISCOVERED 判断

既存モードと同一。Cycle docのDISCOVEREDセクションを確認し、未起票項目をGitHub issueに起票。

## Block 3: Finalization

既存フローと同一:

```
Skill(dev-crew:commit)
```

## Fallback

| 状況 | アクション |
|------|-----------|
| Codex不在 (`which codex` 失敗) | AGENT_TEAMS=1 → steps-teams.md、それ以外 → steps-subagent.md |
| Codex exec失敗 (error/timeout) | 該当フェーズを既存フロー（Task()/Skill()）で実行 |
| Gate失敗 (retry超過) | 残フェーズ全てClaude Code代行 |

fallback発生時 → Cycle doc Progress Logに "Codex fallback: <reason>" を記録。
