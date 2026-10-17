@AGENTS.md

# dev-crew (Claude Code Extensions)

## Claude Code Integration

- plan mode: spec + design consolidated in plan file
- /compact: PreCompact hook (scripts/hooks/pre-compact.sh) persists phase summary before compaction

**Auto-orchestrate after plan approve (Post-Approve Action)**: plan review（Claude + Codex）は承認前（plan mode 内、spec Step 8）で完了済み。plan approve後は `/orchestrate` を起動する。orchestrate が sync-plan（転記）→ architect（転記後検証）→ TDDサイクルを全て管理する。

## Codex Integration

Codex が利用可能な場合、Plan Review は Claude + Codex の competitive で実行。RED/GREEN の委譲は codex_mode (full/no) で制御。REFACTOR は Claude が主担当（Codex fallback）。REVIEW は敵対的レビュー 1 回 + 指摘の振り分け（Codex 既定、Codex 不在・失敗時は `dev-crew:adversarial-reviewer`）。詳細は [CONSTITUTION.md](CONSTITUTION.md) 参照。

```bash
# plan review は承認前（spec Step 8、plan mode 内、read-only sandbox）で実行。
# session ID は plan の Plan Review Record 経由で sync-plan が Cycle doc frontmatter
# codex_session_id へ転記する（orchestrate 自身は取得しない）
codex exec --sandbox read-only "review plan <planファイルパス>" < /dev/null

# RED/GREEN 委譲（codex_session_id があれば resume <session-id>、なければ resume --last）
# フラグは resume より前に置く（後ろに置くと rc=2）。stdin がパイプのままだとハングするので < /dev/null
codex exec --sandbox workspace-write resume <session-id> "red docs/cycles/xxx.md" < /dev/null
codex exec --sandbox workspace-write resume <session-id> "green docs/cycles/xxx.md" < /dev/null

# REVIEW は新しいセッションで実行する（resume しない。実装の文脈を持ち込まない）
# Codex 不在・失敗時は dev-crew:adversarial-reviewer に代行させる
# プロンプトは skills/orchestrate/adversarial-review.md の「## 頼み方」の文を使う
codex exec --sandbox read-only "review code docs/cycles/xxx.md" < /dev/null
```

Codex 不在時は Claude fallback（既存スキルそのまま）。ただし REVIEW は例外で、`dev-crew:adversarial-reviewer` が代行し、それも失敗したら BLOCK する（レビューを省略しない）。

## Skills

一覧は AGENTS.md（`@AGENTS.md` で import 済み）を参照。

- **cycle-retrospective**: TDD サイクル末尾で失敗-成功ペアを抽出する advisory スキル (「retrospective」「振り返り」で起動)
- **codify-insight**: retrospective insights を既定では自動 triage し、`skill` 候補/低確信時のみ確認する decide gate。モデルからは起動しない。`/dev-crew:codify-insight` を入力して起動する (orchestrate は件数を通知するだけ)

## Token Optimization

Phase-boundary compaction:
- Phase output persisted to Cycle doc before compaction
- Context restored from files, not conversation history
- plan review (承認前) → plan approve → compact + accept edits on → auto-orchestrate

## Hooks

| Event | Matcher | Script | Purpose |
|-------|---------|--------|---------|
| PostToolUse | Edit\|Write\|Bash | `scripts/hooks/observe.sh` | Logs tool usage patterns for learn skill |
| PostToolUse | Skill\|Agent | `~/.claude/hooks/observe-skills.sh` | Logs Skill/Agent usage for prune planning (global hook) |
| PreToolUse | Bash | `scripts/hooks/no-verify-guard.sh` | Blocks --no-verify commands (exit 2) |
| PreCompact | manual | `scripts/hooks/pre-compact.sh` | Persists phase summary before /compact |

## 人間の判断点（ブラウザで見せる）

terminal では図が読めず、長い報告は流れる。以下の 3 点では **1 枚の md を書き、`mdopen <path>` を案内してから** AskUserQuestion で OK/NG を求める。terminal に長文を流して判断を求めない。

| 止める場所 | 見せるもの |
|---|---|
| 計画の承認前 | `docs/OVERVIEW.md` の図の上で「どこを触るか」。作る量の見積もりも添える |
| 規模が予想を超えたとき | 想定と実際の差分。続行 / 分割 / 縮小を選んでもらう |
| REVIEW 完了後・COMMIT 前 | 結局どこが変わったか。テスト結果だけを報告しない |

実装の細部は AI 側で完結させる。既存の動きを変えるかどうかだけを、COMMIT 前の md で人間に戻す。ただし**指摘に応えると規模が膨らむ場合は「規模が予想を超えたとき」に該当する**。

## Usage Patterns

| Scenario | Mode | Context Management |
|---------|--------|------------|
| Task search | plan mode | search-task → spec |
| Small-Medium | plan mode → accept edits on | spec (+plan-review) → approve → /orchestrate (sync-plan + TDD内包) |
| Large (auto) | plan mode → accept edits on (AGENT_TEAMS=1) | spec → orchestrate (Task() for isolation) |
| Session resume | accept edits on | Cycle doc を読み IN_PROGRESS cycle を継続 |
| auto-learn | accept edits on (DEV_CREW_AUTO_LEARN=1) | auto learn after commit (20+ observations) |
