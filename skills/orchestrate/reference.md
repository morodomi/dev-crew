# TDD Orchestrate Reference

PdM (Product Manager) オーケストレータの詳細ガイド。

## Task List (Block 0 で登録) {#task-list}

TaskCreate で TDD サイクルのタスクを登録する。各 Block 開始時に TaskUpdate(status: "in_progress")、完了時に TaskUpdate(status: "completed")。

1. sync-plan (Cycle doc 生成)
2. plan-review (設計レビュー)
3. RED (テスト作成)
4. GREEN (実装)
5. REFACTOR (品質改善)
6. REVIEW (コードレビュー)
7. cycle-retrospective (失敗-成功 insight 抽出)
8. COMMIT (コミット)

**MUST**: 8件全て登録すること。plan-review と cycle-retrospective を省略しない。

## Block 2f: RETROSPECTIVE {#block-2f}

DISCOVERED (Block 2e) 完了後、COMMIT (Block 3) 前に実行する。

```
Skill(dev-crew:cycle-retrospective)
```

### 終了条件

| 結果 | アクション |
|------|-----------|
| 正常終了 (exit 0) | retro_status が captured または resolved に遷移済み → Block 3 (COMMIT) へ |
| abort signal (exit 1) | COMMIT に進まず停止。「cycle-retrospective aborted by user. 手動で fix してから /orchestrate を再起動してください」と出力 |

### default 動作

`default: abort`（安全側）。proceed はユーザーが明示的に選択した場合のみ。abort signal を受信した場合、orchestrate は commit に進まず停止する（Codex #1 対応）。

## PdM の責務

### やること

| 責務 | 詳細 |
|------|------|
| plan mode管理 | INIT + 探索・設計・Test ListをplanファイルでABLOCK 時のエスカレーション |
| 自律判断 | PASS/WARN/BLOCK を自分で判定し、次 Phase へ自動進行 |
| Phase orchestration | 専門家の spawn/shutdown、Phase 間遷移 |
| Context 管理 | Cycle doc 読み書き、Phase 状態追跡 |
| Verification Gate | テスト実行、成功/失敗確認 |
| Git 操作 | commit, status, diff |
| DISCOVERED issue 起票 | スコープ外の DISCOVERED 項目を GitHub issue に起票 |

### やらないこと

| 禁止 | 委譲先 |
|------|--------|
| 実装コード作成 | green-worker |
| テストコード作成 | red-worker |
| Cycle doc生成 | architect (sync-plan) |
| コードレビュー | reviewer |
| コード品質改善 | refactor (checklist-driven) |
| 推測で進む | AskUserQuestion |

## Phase Ownership

| Phase | Owner | 委譲先 |
|-------|-------|--------|
| SPEC (plan mode) | PdM (Lead) 直接実行 | Skill(spec) |
| SYNC-PLAN (Design Review Gate) | PdM → architect | Task(sync-plan) + Design Review Gate |
| RED | PdM → N red-worker | 並列テスト作成 |
| GREEN | PdM → N green-worker | 並列実装 |
| REFACTOR | PdM → refactor (checklist-driven) | Skill(refactor) |
| REVIEW | PdM → risk-based reviewer | 討論/並列 review(code) |
| COMMIT | PdM (Lead) 直接実行 | - |

## Delegation Decision Criteria

PdM は前 Phase の metrics を評価し、次 Phase の実行方法を決定する:

| Metric | lightweight threshold | heavy threshold | decision if lightweight | decision if heavy |
|--------|----------------------|-----------------|-------------------------|-------------------|
| line_count | < 200 | >= 200 | PdM 直接実行 | 委譲 |
| file_count | < 3 | >= 3 | PdM 直接実行 | 委譲 |

**判断ロジック**:
- 全 metrics が lightweight → PdM が Skill() で直接実行（軽量な Phase）
- いずれかの metric が heavy → subagent/teammate に委譲（重い Phase）
- Default: always delegate (token budget 保護)

## 判断基準

### スコアベース判定 (Agent Teams 有効時)

| スコア | 判定 | PdM アクション | ユーザーに聞く |
|--------|------|---------------|---------------|
| 0-49 | PASS | 次 Phase へ自動進行 | - |
| 50-79 | WARN | Socrates Protocol → 人間判断 | メリデメ提示後に自由入力 |
| 80-100 | BLOCK | Socrates Protocol → 人間判断 | メリデメ提示後に自由入力 |

Agent Teams 無効時は v5.0 互換: WARN 自動進行、BLOCK 自動再試行。

### WARN/BLOCK 時の Socrates Protocol (v5.1 設計理由)

WARN (50-79) は判断が分かれるゾーン。Socrates Protocol で人間の知見を入れることが
最も ROI が高い。自律性 (v5.0) より判断精度 (v5.1) を優先する意図的な設計変更。
BLOCK (80+) も同様に Socrates Protocol を経由し、自動再試行ではなく人間が
「再試行/修正/中断」を判断する。

## Session Management

Cycle doc frontmatter の `codex_session_id` で Codex セッションを cycle にバインドする。

### codex_session_id の状態別動作

| 状態 | 動作 | 備考 |
|------|------|------|
| 空文字 `""` | `resume --last` にフォールバック | 初回 plan review 前の状態 |
| session ID あり | `resume <session-id>` で明示的にバインド | plan review 後の通常状態 |
| stale session (resume 失敗) | 新規セッション作成で retry → 新 ID を frontmatter に更新 | 自動回復 |

### 取得タイミング

plan review 時の `codex exec --full-auto` 実行後、出力から session ID を抽出し Cycle doc frontmatter `codex_session_id` に記録する。

### フォールバック

`codex_session_id` が空 or stale の場合、`resume --last` (cwd フィルタ) にフォールバックする。従来のセッション管理と後方互換。

## TDD Gate

Codex に RED/GREEN を委譲する際のゲート検証。

### 委譲モード (codex_mode)

`codex_mode` は RED/GREEN の委譲先のみ制御する。Plan Review と Code Review は codex_mode に関わらず Codex 利用可能なら常時実行。

| codex_mode | RED/GREEN | Gate 1/2 | Test Plan整合性 | Plan/Code Review |
|------------|-----------|----------|-----------------|------------------|
| `full` | Codex (codex exec) | スキップ | 常時実行 | 常時実行 (Codex利用可能時) |
| `no` | Claude (Task(worker)) | N/A | N/A | 常時実行 (Codex利用可能時) |

`codex_mode` は Post-Approve Action で AskUserQuestion により決定され、Cycle doc frontmatter に記録される。compact 後も復元可能。

### Gate 1 (RED → GREEN)

- `codex_mode: full` 時はスキップ
- それ以外: PdMがプロジェクトのテストコマンドを実行
- 新規テストがFAILし、テストコマンドが非ゼロexit codeを返すこと
- テストファイルがCycle doc Test Listのアイテムと対応すること
- 既存テスト（変更対象外）のPASS/FAILは問わない

### Gate 2 (GREEN → REFACTOR)

- `codex_mode: full` 時はスキップ
- それ以外: PdMがテストコマンドを実行
- 全テストがPASS（ゼロexit code）であること（新規テスト含む）

### Test Plan凍結

- Cycle doc Test ListはSPEC/PLANで凍結
- CodexはTest Planの変更不可（Gate検証で逸脱検出）

## 再試行ロジック

### BLOCK 時の再試行

| 場面 | 再試行上限 | 超過時のアクション |
|------|-----------|-------------------|
| SYNC-PLAN (Design Review BLOCK) | max 1回再試行 | ユーザーに報告、architect 再実行を依頼 |
| review(code) BLOCK | max 1回再試行 | ユーザーに報告、GREEN 修正を依頼 |

### テスト失敗時の再試行

| 場面 | 再試行上限 | 超過時のアクション |
|------|-----------|-------------------|
| RED テスト作成失敗 | max 2回再試行 | ユーザーに報告 |
| GREEN テスト失敗 | max 2回再試行 | ユーザーに報告 |

### エスカレーション条件

再試行上限を超えた場合、PdM はユーザーにエスカレーションする:

```
BLOCK が解消されません。
Phase: [Phase名]
試行回数: [N]回
エラー概要: [要約]

選択肢:
1. 手動で修正して続行
2. サイクルを中断
```

## Phase 遷移時のステータス更新

各 Phase 完了時、PdM は Progress Checklist を更新して出力する:

```
orchestrate Progress:
- [x] Block 0: plan mode → INIT → 探索・設計 → Test List → QA → approve
- [x] Block 1: sync-plan (with Design Review) → PASS
- [ ] Block 2a: RED (実行中) → 2b: GREEN → 2c: REFACTOR → 2d: REVIEW → 2e: DISCOVERED
- [ ] Block 3: COMMIT
```

これにより、ユーザーは長時間の自律実行中も進捗を把握できる。

## DISCOVERED issue 起票

REVIEW の PASS/WARN 後、COMMIT の前に実行する。

### データソース

Cycle doc の `### DISCOVERED` セクションから読み取る。

### 判断基準

| 条件 | アクション |
|------|-----------|
| DISCOVERED が空 or `(none)` | スキップ（issue起票なし） |
| 全項目が起票済み（`→ #` 付き） | スキップ |
| 未起票の項目あり | ユーザー確認後に起票 |

### 事前チェック

```bash
gh auth status 2>/dev/null || echo "gh CLI未認証。issue起票をスキップします。"
```

`gh` が利用不可の場合、DISCOVERED 項目を Cycle doc に残したまま COMMIT へ進行する。

### ユーザー確認ゲート

GitHub issue 作成は外部副作用のため、PdM 自律判断ではなくユーザー承認を求める:

```
DISCOVERED items found:
1. [項目1の要約]
2. [項目2の要約]

GitHub issue を作成しますか? (Y/n)
```

### 重複防止

起票済みの項目は Cycle doc で `→ #<issue番号>` マークが付く:

```markdown
### DISCOVERED
- パフォーマンス問題 → #42
- エラーハンドリング不足 → #43
```

`→ #` が付いている項目は起票をスキップする。

## Socrates Plan Review (Codex不在時) {#socrates-plan-review}

Codex が利用不可の場合、Block 1 の plan-review 後に Socrates を **計画への adversarial reviewer** として起動する。Step 4.5 の「reviewer バイアスチェック」とは目的が異なる。

### 目的の違い

| | Step 4.5 Socrates | Block 1 Socrates (本セクション) |
|---|---|---|
| 目的 | reviewer のスコアが甘くないか検証 | 計画自体に反論（Codex competitive review の代替） |
| 入力 | reviewer スコア + issues サマリ | plan 全文 + CONSTITUTION + reviewer verdict |
| タイミング | review skill 内 | orchestrate Block 1（plan-review 完了後） |
| 条件 | 常時 | Codex 不在時のみ |

### 起動条件

```bash
which codex >/dev/null 2>&1 || NEED_SOCRATES_PLAN=true
```

Codex 利用可能時はスキップ（Codex competitive review が同等の役割を果たす）。

### プロンプト

```
Task(subagent_type: "dev-crew:socrates", model: "opus", prompt: "
phase: review:plan (adversarial)
plan: [planファイルの全文]
constitution: [CONSTITUTION.md / AGENTS.md / CLAUDE.md の内容（存在するもの）]
reviewer_verdict: [plan-review の verdict と主要 issues]
cycle_doc: [Cycle doc パス]

Codex competitive review の代替として、計画自体に反論せよ。
reviewer のスコアではなく、計画の設計判断・スコープ・トレードオフに焦点を当てよ。
特に: CONSTITUTION の原則に反していないか、Non-Goals に該当しないか、
より良い代替設計がないかを検証せよ。
")
```

### PdM の判断

Socrates の反論を受け、PdM は以下を判断:

| Socrates の反論 | PdM アクション |
|----------------|---------------|
| 軽微な指摘のみ | そのまま Block 2a へ |
| CONSTITUTION 違反の指摘 | ユーザーに報告、plan 修正を検討 |
| より良い代替設計の提案 | ユーザーに選択肢を提示 |

## ADR Reference

orchestrate中にアーキテクチャ判断が発生した場合、`docs/decisions/` の既存ADRを参照する。

### 参照タイミング
- REVIEW: 設計変更が必要な場合、既存ADRとの整合性を確認
- NOTE: sync-plan時のADR作成はsync-plan agent内で自律処理されるため、orchestrateは関与しない

### 作成条件
agents/sync-plan.mdのADR作成条件に準拠:
- 複数サイクルに影響する判断
- 過去のADRを上書きする判断
- 人間に委ねた判断（deferred）

## Auto-Learn トリガー条件

COMMIT 後に learn を自動実行するための条件テーブル:

| 条件 | 値 | 必須 |
|------|-----|------|
| `DEV_CREW_AUTO_LEARN` 環境変数 | `1` | Yes |
| `${CLAUDE_PLUGIN_DATA}/observations/log.jsonl` 存在 | ファイルが存在する | Yes |

両条件を満たさない場合、Auto-Learn はスキップされる (サイレント)。

### 失敗時の挙動

| 状況 | アクション |
|------|-----------|
| learn 正常完了 | 結果サマリーを表示 |
| learn 失敗 | 警告ログのみ表示、COMMIT 完了はブロックしない |
| learn タイムアウト | 警告ログのみ表示、サイクル正常終了 |

Auto-Learn は best-effort であり、サイクルの成否に影響しない。

## Socrates Protocol

Agent Teams 有効時、pre-review:plan (Design Review Gate) / review(code) のスコアが WARN (50-79) または BLOCK (80+) の場合に発動する。
Socrates は on-demand advisor であり、reviewer とは異なる役割を持つ。
PASS サイクル (~80%) では spawn されず、コストゼロ。

### Protocol フロー

1. **PdM → Socrates (on-demand)**: Task() で socrates を起動し、判断提案を渡す (Phase名, スコア, reviewer サマリ, 提案, Cycle doc の Progress Log)
   ```
   Task(subagent_type: "dev-crew:socrates", model: "opus", prompt: "...")
   ```
   Progress Log を含めることで、常駐時と同等の判断履歴コンテキストを提供する。
2. **Socrates → PdM**: 反論を返却 (Objections + Alternative 形式)
3. **PdM → Human**: Socrates の反論を統合し、メリデメを構造化してテキスト出力
4. **Human → PdM**: 自由入力で判断を返す

### 障害時フォールバック

Socrates の Task() がタイムアウトまたは異常応答を返した場合、v5.0 互換ロジックにフォールバックする:

| 障害 | フォールバック動作 |
|------|-------------------|
| Socrates Task() 失敗/タイムアウト | WARN → 自動進行、BLOCK → 自動再試行 |
| Socrates 異常応答 (パース不能) | WARN → 自動進行、BLOCK → 自動再試行 |

フォールバック時は警告を表示:

```
Socrates が応答しません。v5.0 互換ロジックで進行します。
```

Protocol フローの Step 1 で Task() が失敗した場合、Step 2-4 をスキップしてフォールバックする。

### 人間の自由入力ハンドリング

有効な入力例:

| 入力 | 意味 |
|------|------|
| proceed | 現状のまま次 Phase へ進行 |
| fix | 指摘事項を修正してから進行 (Phase 再実行) |
| abort | サイクルを中断 |
| 1, 2, 3 | 提示された選択肢の番号で選択 |

不明瞭な入力 (曖昧な文言、無関係な内容) を受けた場合は再確認する (max 2回):

```
入力を解釈できません。以下から選択してください:
1. proceed - 進行
2. fix - 修正して再実行
3. abort - サイクル中断
```

2回再確認しても不明瞭な場合、デフォルト (proceed) で次 Phase へ進行する:

```
入力が2回不明瞭でした。デフォルト (proceed) で次 Phase へ進行します。
```

再試行カウンタは Socrates Protocol 発動ごとにリセットする。

### Progress Log 記録フォーマット

Socrates Protocol 発動時、Cycle doc の Progress Log に以下を追記:

```markdown
#### [Phase名] (Score: [N] [WARN/BLOCK]) - [HH:MM]
- PdM Proposal: [提案内容]
- Socrates Objection: [反論の要約]
- Human Decision: [人間の判断]
- Action: [次のアクション]
```

### 初回発動時のユーザー案内

サイクル内で初めて Socrates Protocol が発動する際、以下の案内を表示:

```
Socrates (Devil's Advocate advisor) が判断に反論します。
reviewer とは異なり、スコアは付けず代替案を提示します。
メリット・デメリットを確認し、自由入力で判断してください。
```

## Gotchas

| # | 症状 | 原因 | 対策 |
|---|------|------|------|
| G-01 | sync-plan/plan-reviewスキップ | Post-Approve Action違反 | Block 0でProgress Log確認 |
| G-02 | WARN/BLOCKで自動再試行ループ | 自動進行ロジック | Socrates Protocol経由で人間判断 |
| G-03 | Codex session ID stale | セッション期限切れ | 新規セッション作成でretry |
| G-05 | PdMが直接実装コード記述 | 委譲ルール違反 | 「やらないこと」テーブル参照 |

## Product Verification {#product-verification}

REFACTOR の Verification Gate（テスト+lint+format）とは異なる。
プロダクトが期待通り動作するか（UI描画、API応答、E2Eスモーク等）を確認する advisory evidence。

### 位置

REFACTOR (Block 2c) → **VERIFY (Block 2c.5)** → REVIEW (Block 2d)

### 性質

- **Advisory evidence**: 失敗しても REVIEW を non-blocking でブロックしない
- エビデンスは Cycle doc の Progress Log にポインタとして記録
- コマンドの exit code と stdout/stderr をキャプチャ

### 実行ロジック

1. Cycle doc から `## Verification` セクションを抽出
2. セクション内の bash コードブロックからコマンドを抽出
3. コマンドがない（セクション不在、空、コメントのみ）→ サイレントスキップ
4. コマンドがある場合:
   a. Evidence ディレクトリ作成: `/tmp/dev-crew-verify-{cycle-id}/`
   b. 各コマンドを順次実行、stdout/stderr を `verify-{n}.log` に保存
   c. exit code を記録（`|| true` で吸収、ブロッキングしない）
5. Cycle doc の Progress Log に結果を追記

### Progress Log フォーマット

```
### YYYY-MM-DD HH:MM - VERIFY
- Command 1: `<command>` → exit 0 (PASS) / exit N (FAIL)
- Evidence: /tmp/dev-crew-verify-{cycle-id}/
- Advisory: PASS/FAIL (non-blocking)
- Phase completed
```

### スキップ時

Progress Checklist に "(skipped)" 表示のみ。Progress Log には記録しない。
