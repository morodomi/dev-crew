# TDD Orchestrate - Codex Delegation Mode

`which codex` でCodex利用可能時の手順。RED/GREENをCodexに委譲し、REVIEWは新しいセッションの Codex で敵対的レビューを 1 回かける。Claude Code (PdM) がGate検証で品質を担保する。

## Pre-check

```bash
which codex
```

- 存在する → 本手順で進行
- 存在しない → [steps-subagent.md](steps-subagent.md) or [steps-teams.md](steps-teams.md) にフォールバック

### 委譲モード確認

Cycle doc frontmatter の `codex_mode` を読み取る。
**codex_mode は RED/GREEN の委譲先のみ制御する**。Plan Review と REVIEW のレビュー（敵対的レビュー）は codex_mode に関わらず Codex が利用可能なら実行。

- `codex_mode: full` → RED/GREEN を Codex に委譲、Gate 1/2 をスキップ
- `codex_mode: no` → RED/GREEN を Claude fallback（Task(red-worker)/Task(green-worker)）

未記録の場合のみ AskUserQuestion で確認し、結果を Cycle doc frontmatter に記録する。
ユーザー選択は環境検出（`which codex`）より常に優先される。

## Session Management

- plan review 時に Codex セッション作成 → session ID を Cycle doc frontmatter `codex_session_id` に記録
- 全 Codex コマンド: `codex_session_id` があれば `resume <session-id>`、なければ `resume --last` にフォールバック。ただし REVIEW は resume しない唯一の例外（新しいセッションでレビューする。[REVIEW via Codex](#review-via-codex) 参照）
- 同一ディレクトリでの並行 Codex 実行は非推奨だが、cycle-bound のため技術的には可能

## Block 0-1: Prerequisite & Sync-Plan

Prerequisite Check は steps-subagent.md / steps-teams.md と同一。Sync-Plan は sync-plan（転記）→ architect（転記後検証）の順で呼び出す:

```
Task(subagent_type: "dev-crew:sync-plan", model: "sonnet", prompt: "planファイル: [path]。Cycle doc を生成し、plan の Plan Review Record を frontmatter/Progress Log へ転記せよ。")
→ sync-plan が Cycle doc 生成 + Plan Review Record 転記 → 結果 JSON 返却

Task(subagent_type: "dev-crew:architect", model: "sonnet", prompt: "plan ファイルと Cycle doc [path] を比較し、Post-Transfer Verification を実施せよ。転記欠落=BLOCK / scope 実質変更=AskUserQuestion で再承認 / 観察のみ=DISCOVERED に記録。")
→ architect が転記後検証を実施 → 結果 JSON 返却
```

Codex委譲はBlock 2から。

## Block 2: Implementation

**フェーズ入口契約**: 各フェーズ（RED/GREEN/REFACTOR/REVIEW/COMMIT）の開始時に Cycle doc を読み、現在 phase・Test List・Progress Log を把握してから作業する（compaction 直後でも cycle-scoped rules の再ロードを保証する入口 Read）。

### Pre-RED Gate (deterministic)

```bash
bash scripts/gates/pre-red-gate.sh "$CYCLE_DOC"
```

exit 0 → RED へ。exit 1 → BLOCK（gate の出力メッセージで不足ステップを案内。sync-plan 未完了 / Plan Review (pre-approval) の strict 契約違反等）。

> **MUST**: inline の awk/grep による弱チェックを直書きしない。強化された gate script が唯一の判定源（deterministic gate の単独完結原則、rules/multi-file-consistency.md 準拠）。

### RED via Codex

委譲プロンプトは `rules/agent-prompts.md` の契約に従って構築する。

1. プロンプト構築: Cycle doc Test List + テスト対象ファイル情報
2. 実行:
   ```bash
   # codex_session_id があれば resume <session-id>、なければ resume --last
   codex exec --sandbox workspace-write -o /tmp/codex_red.md resume ${codex_session_id:-"--last"} "Cycle doc: [path]. Test List: [items]. テストを作成し、失敗を確認せよ。" < /dev/null
   ```
3. **Gate 1**: `codex_mode: full` 時はスキップ。それ以外はPdMがプロジェクトのテストコマンドを実行 → 新規テストがFAILし、テストコマンドが非ゼロexit codeを返すことを確認
4. Test Plan整合性（常時実行・全モード無条件）: テストがCycle doc Test Listと対応しているか確認
5. PASS → GREEN / FAIL → retry 1回 → fallback to Task(red-worker)

### GREEN via Codex

1. 実行:
   ```bash
   # codex_session_id があれば resume <session-id>、なければ resume --last
   codex exec --sandbox workspace-write -o /tmp/codex_green.md resume ${codex_session_id:-"--last"} "Cycle doc: [path]. テストを通す最小限の実装を行え。" < /dev/null
   ```
2. **Gate 2**: `codex_mode: full` 時はスキップ。それ以外はPdMがテストコマンドを実行 → 全テストPASS（ゼロexit code）確認（新規テスト含む）
3. PASS → REFACTOR / FAIL → retry 2回 → fallback to Task(green-worker)

### Phase Summary 永続化 (Block2 境界)

Subagent Chainモードと同様、Block境界でPhase Summaryを永続化する:

```markdown
### Phase: RED (Codex) - Completed at HH:MM
**Artifacts**: [test file paths]
**Decisions**: N tests created, all failing (Gate 1 passed)
**Codex Session**: resume --last (session: <id>)
```

GREEN完了後も同様に永続化。REVIEW の記録は REVIEW 節の件数の行と `- Phase completed`。

### REFACTOR (checklist-driven)

Claude が主担当（CONSTITUTION.md 準拠）。チェックリスト駆動のため外部依存なし:

```
Skill(dev-crew:refactor)
```

### VERIFY (Product Verification)

PdM が直接 Bash で実行（参考エビデンス、委譲不要）。
Cycle doc `## Verification` セクション不在 or real-path invocation なし → WARN ログを出力しつつ非ブロッキングスキップ (rules/integration-verification.md)。
詳細: [reference.md](reference.md#product-verification)

### REVIEW via Codex

実装した文脈とは別の文脈で敵対的レビューを 1 回だけかけ、指摘を修正役が「直す / 人間に戻す / 記録のみ」に振り分ける。頼み方・振り分け・報告の型の単一出典は [adversarial-review.md](adversarial-review.md)。`review` skill は起動しない。

REVIEW は resume しない唯一の例外である。codex_mode: full のとき `codex_session_id` は GREEN と同じセッションを指すので、resume すると実装者が自分をレビューすることになる。REVIEW のセッション ID は保存しない。

#### 手順

0. **対象の列挙**: `git diff HEAD --name-only` と `git ls-files --others --exclude-standard`（未追跡の新規ファイルを含める）。未追跡ファイルがあれば WARN を出し、レビュー対象に含める。ただし名前が `.env*`・`*.pem`・`*credentials*`・`*secret*` に当たる未追跡ファイルはレビュー対象から外し、WARN を出す（Codex は外部サービスなので秘密を送らない）。
1. **敵対的レビューを 1 回**: 入力は Cycle doc のパスと対象ファイルの一覧だけ。diff は渡さない（レビュー側が `git diff HEAD` を自分で実行して読み、未追跡ファイルは中身を読む）。レビュー結果は、どちらの経路でも固定のパス `/tmp/dev-crew-review-<cycle_id>/review.md` に置く（`<cycle_id>` は Cycle doc の frontmatter `cycle`。bash 呼び出しをまたいで使うので、変数に持たず固定のパスをそのまま書く）。Codex がある（`which codex` 成功）ときは新しいセッションで実行する:
   ```bash
   mkdir -p /tmp/dev-crew-review-<cycle_id>/scratch
   ```
   ```bash
   codex exec --sandbox read-only -o "/tmp/dev-crew-review-<cycle_id>/review.md" "<頼み方>" < /dev/null
   ```
   `<頼み方>` は adversarial-review.md の `## 頼み方` の依頼文に、Cycle doc のパスと対象ファイルの一覧を添えたもの。
   Codex が無い、または失敗した（error / timeout / 出力が空）ときは、新しい文脈の `dev-crew:adversarial-reviewer` に同じ入力と依頼文を渡す。前後で `worktree-fingerprint.sh` の出力を比べる:
   ```bash
   mkdir -p /tmp/dev-crew-review-<cycle_id>
   bash scripts/gates/worktree-fingerprint.sh --list > /tmp/dev-crew-review-<cycle_id>/before.list
   before=$(bash scripts/gates/worktree-fingerprint.sh); before_rc=$?
   ```
   ```
   Task(subagent_type: "dev-crew:adversarial-reviewer", model: "opus", prompt: "Cycle doc: [path]. 対象ファイル: [一覧]. adversarial-review.md の ## 頼み方 に従い、git diff HEAD を自分で実行して読み、実行して再現できた指摘だけを high にして報告せよ。作業ツリーを変えるな。")
   ```
   ```bash
   after=$(bash scripts/gates/worktree-fingerprint.sh); after_rc=$?
   ```
   - PdM は adversarial-reviewer の返答を、Codex と同じパス `/tmp/dev-crew-review-<cycle_id>/review.md` のファイルに書き出す（返答を同じパスのファイルに書き出す。これで修正役への受け渡しが両経路で同じになる）
   - 前後それぞれの終了コードと出力の形（64 桁の 16 進）を確かめる。取得失敗・空・形違いなら BLOCK（一致とみなさない）
   - 前後が違えば作業ツリーが変わっている。レビューを無効にして BLOCK。BLOCK したら `--list` を取り直し、前後の --list の差を人間に見せる（何が変わったかを見るため）
   - adversarial-reviewer も失敗したら BLOCK し、人間に報告する（レビューを省略しない）
2. **修正**: 修正役を起動する前に、PdM が P1・P2 の指摘ごとに、レビュー結果にある場所（ファイル:行）で `bash scripts/gates/finding-in-diff.sh <ファイル> <行>` を実行する（終了コード 0 = diff の中、1 = diff の外、2 = 判定できない）。終了コード 1 の指摘は、元からある欠陥として修正役に「直す」として渡さない。受け入れ条件に関わるなら「人間に戻す」、関わらないなら「記録のみ」にして DISCOVERED に回す。終了コード 0・2 と、場所が書かれていない指摘は、今までどおり修正役の振り分けに任せる。修正役の起動 prompt（Codex への起動文字列と Task の prompt の両方）には、終了コード 1 の指摘を「直さない指摘: [ファイル:行 と、指摘の 1 行目]」として書く（番号ではなく場所と原文で指す）。「直さない指摘」は PdM が振り分け済みなので、修正役は振り分けも報告もしない。件数の行（直す / 人間に戻す / 記録のみ）は、PdM が照合で振り分けた分と、修正役の報告の分を足したものにする。修正役を起動しないときは、P3 の指摘を PdM が「記録のみ」として数える。「直す」が 0 件なら修正役を起動せず、記録（3）へ進む。照合の後に、P1・P2 のうち終了コード 1 でないものとして修正役へ渡す指摘が 1 件以上残れば、修正役を起動する。修正役は GREEN と同じ委譲先で、`codex_mode: full` かつ `codex_session_id` があれば Codex、無ければ green-worker。修正役には常にそのファイルを渡す（`/tmp/dev-crew-review-<cycle_id>/review.md`）。Codex 成功なら Codex の出力、代行なら PdM が書き出した返答で、どちらも同じパス。adversarial-review.md の `## 振り分け` と `## 報告の型` を渡し、「直す」だけを直させる。直す前に呼び出し元の検索と今の動きの固定を済ませ、既存のテストを弱めさせない。
   ```bash
   codex exec --sandbox workspace-write resume "$codex_session_id" "Cycle doc: [path]. レビュー結果: /tmp/dev-crew-review-<cycle_id>/review.md. adversarial-review.md の ## 振り分け と ## 報告の型 に従え。直さない指摘: [ファイル:行 と、指摘の 1 行目]（無ければ「なし」）。" < /dev/null
   ```
   REVIEW の後の修正役は `codex_session_id` で resume する。`--last` は直前のレビューのセッションを指すので使わない。`codex_session_id` が無ければ、修正は `Task(subagent_type: "dev-crew:green-worker", model: "sonnet", prompt: "Cycle doc: [path]. レビュー結果: /tmp/dev-crew-review-<cycle_id>/review.md. adversarial-review.md の ## 振り分け と ## 報告の型 に従え。直さない指摘: [ファイル:行 と、指摘の 1 行目]（無ければ「なし」）。")` が行う（prompt に同じパスのレビュー結果を渡す）。
   - **未追跡ファイルの前後比較**: 修正役を起動する直前に、次のコマンドで未追跡ファイルの一覧を取って控える
     ```bash
     git ls-files --others --exclude-standard
     ```
   - 修正役が終わった後に、もう一度同じコマンドで一覧を取る
     ```bash
     git ls-files --others --exclude-standard
     ```
     増えたファイルのうち、修正役が報告で足したと書いたもの以外を、COMMIT 前の md の「片付け」に載せる（消すかどうかは人間が決める）
   - **修正段階の完了条件**: 修正役が success を返し、修正後に全件を流して、REFACTOR 完了時の全件結果（Progress Log の REFACTOR 記録）より新たに落ちていないこと。満たさなければ 1 回だけやり直し、それでも満たさなければ BLOCK して人間に報告する
   - 修正後に再レビューしない（レビューは回数でなく予算で止める。1 回かけたら終わり）
3. **記録**: PdM が Cycle doc の Progress Log に `### {date "+%Y-%m-%d %H:%M" の実測値} - REVIEW` の見出し、件数の行、`- Phase completed` を書き、frontmatter の phase / updated を更新する。件数の行は次のどれか:
   - `- Codex review: 直す N / 人間に戻す M / 記録のみ K`
   - `- Codex review: 失敗（<理由>）。adversarial-reviewer で代行: 直す N / 人間に戻す M / 記録のみ K`
   - `- Adversarial review: 直す N / 人間に戻す M / 記録のみ K`（Codex が無い環境）

   修正役が足したテストは、Cycle doc の Test List の DONE に `- [x] TC-R<n>: <テストファイル>::<テスト名>（REVIEW で追加）` の形で追記する（append-only）。
4. **COMMIT 前の判断点**: CLAUDE.md の判断点どおり、毎回 md を見せる。「人間に戻す」があれば、その md の先頭に「決めてほしいこと」として載せる。手順 2 で見つけた修正役の未追跡ファイルがあれば、「片付け」として載せる。
5. **セキュリティ**: security-reviewer は常時起動しない。敵対的レビューがセキュリティの問題を見つけたら、rules/security.md の「問題発見時」の手順がそのまま適用される。

### Open Questions Response

Codex plan review が Open Questions を出した場合:
1. 各質問への回答を Cycle doc の Design Decisions セクションに記録
2. 判断理由を1行添える
3. 未回答の Open Questions は次回 review で再指摘される

### DISCOVERED 判断

既存モードと同一。Cycle doc の DISCOVERED セクションを確認し、未起票項目を GitHub issue に起票。

### Block 2f: RETROSPECTIVE (cycle-retrospective)

DISCOVERED 完了後、COMMIT 前に実行する:

```
Skill(dev-crew:cycle-retrospective)
```

- 正常終了 (exit 0) → retro_status: captured または resolved → Block 3 へ
- abort signal (exit 1) → COMMIT をスキップして停止。「cycle-retrospective aborted by user. 手動で fix してから /orchestrate を再起動してください」と出力
- `default: abort`（安全側）。abort → BLOCK、proceed のみ Block 3 へ進行

## Block 3: Finalization

既存フローと同一:

```
Skill(dev-crew:commit)
```

## Fallback

| 状況 | アクション |
|------|-----------|
| Codex不在 (`which codex` 失敗) | AGENT_TEAMS=1 → steps-teams.md、それ以外 → steps-subagent.md |
| Codex exec失敗 (error/timeout) | 該当フェーズを既存フロー（Task()/Skill()）で実行。REVIEW は `dev-crew:adversarial-reviewer` で代行し、それも失敗したら BLOCK |
| Gate失敗 (retry超過) | 残フェーズ全てClaude Code代行 |

fallback発生時 → Cycle doc Progress Logに "Codex fallback: <reason>" を記録。
