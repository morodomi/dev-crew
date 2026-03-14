# TDD Orchestrate - Codex Delegation Mode

`which codex` でCodex利用可能時の手順。RED/GREEN/REVIEWをCodexに委譲し、Claude Code (PdM) がGate検証で品質を担保する。

## Pre-check

```bash
which codex
```

- 存在する → 本手順で進行
- 存在しない → [steps-subagent.md](steps-subagent.md) or [steps-teams.md](steps-teams.md) にフォールバック

## Session Management

- sync-plan debateでCodexセッション作成済み（Cycle docにsession ID記録済み）→ `resume --last` で継続
- debateなし → REDで新規セッション作成、session IDをCycle doc Progress Logに記録
- `resume --last` はcwdフィルタ済みのため同ディレクトリ内の最新セッションが選ばれる
- 同一ディレクトリで並行Codex実行禁止（1 cycle = 1 session）

## Block 0-1: Prerequisite & Sync-Plan

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

### REFACTOR (checklist-driven)

Claude/Codex どちらでも実行可能。チェックリスト駆動のため外部依存なし:

```
Skill(dev-crew:refactor)
```

### REVIEW via Codex (competitive)

Claude と Codex が独立にレビューし、PdM が findings を裁定する競争的レビュー。

1. **Codex レビュー実行**:
   ```bash
   codex exec resume --last --full-auto -o /tmp/codex_review.md "Review uncommitted changes. セキュリティ・正確性・パフォーマンスの観点で問題を指摘せよ。"
   ```
2. **Claude レビュー実行**: `Skill(dev-crew:review, args: "--code")` を並行実行
3. **Findings Aggregation**: 両レビュー結果を PdM が集約

Codex 失敗 → Claude レビューのみで続行（品質バー維持）。

### Findings Judgment

PdM が Codex findings を知的誠実性をもって裁定する（PHILOSOPHY.md 準拠）:

| 判断 | 条件 |
|------|------|
| Accept | 指摘が妥当 → 即修正 |
| Reject | 明確な理由を説明でき、Codex が納得できる |
| AskUserQuestion | ビジネス判断が必要、または debate が発生 |
| DISCOVERED | 今回のスコープ外 → 次回タスクへ |
| ADR | アーキテクチャ上の重要決定 → 記録 |

### Findings → Score Integration

1. PdM が Codex findings を Findings Judgment テーブルに基づき裁定
2. Accept した指摘は即修正（GREEN 再実行 or 直接修正）
3. 裁定結果を Cycle doc Progress Log に永続化（finding 内容 + Accept/Reject/DISCOVERED）
4. Claude review の blocking_score と Codex findings の裁定結果を統合してスコア判定

### REVIEW 後の判断

PdM が Claude + Codex 両方の結果を統合:
- **合意**（両者 PASS/WARN、Accept 済み修正完了）→ auto-COMMIT
- **debate**（Claude/Codex で判断が割れた）→ AskUserQuestion（承認ゲート(2)）
- BLOCK → GREEN 再実行（Codex or fallback）

### DISCOVERED 判断

既存モードと同一。Cycle doc の DISCOVERED セクションを確認し、未起票項目を GitHub issue に起票。

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
