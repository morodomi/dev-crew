# TDD Orchestrate - Agent Teams Mode (Experimental)

環境変数 `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` が有効時の手順。
1つのチームが全 Phase を通して存続し、Phase ごとに Teammate を spawn/shutdown する。

> **NOTE**: Codex利用可能時は [steps-codex.md](steps-codex.md) が優先される。

## Block 0: Prerequisite Check

### 0. Codify notice (frontmatter-only scan)

```bash
n=0; for f in docs/cycles/*.md; do awk '/^---$/{c++;next} c==1{print}' "$f" 2>/dev/null | grep -E '^retro_status:[[:space:]]*captured[[:space:]]*$' >/dev/null && n=$((n+1)); done; echo "$n"
```

N が 1 以上なら「未処理の振り返りを持つ Cycle doc が N 件あります（retro_status: captured）。処理するときは /dev-crew:codify-insight を別に実行し、タスクとは別の commit にしてください。」と 1 行通知する。0 なら通知しない。件数にかかわらず次へ進む。

planファイルを起点に開始地点を決定する:

### 1. planファイルの存在確認

planファイルに `## TDD Context` セクションがあるか確認する。

- **あり** → 1a. へ
- **なし** → 2. へ

### 1a. 未完了 Cycle doc の確認

frontmatter のみを対象に `phase: DONE` でないファイルを抽出（本文中の文字列に影響されない）:

```bash
for f in docs/cycles/*.md; do [ -f "$f" ] || continue; fm=$(awk '/^---$/{c++;next} c==1{print}' "$f"); echo "$fm" | grep -q '^phase:' || continue; echo "$fm" | grep -q 'phase: DONE' && continue; printf '%s\t%s\n' "$(echo "$fm" | awk 'sub(/^updated: */,""){gsub(/T/," ");print;exit}')" "$f"; done 2>/dev/null | sort | tail -1 | cut -f2
```

- **未完了 cycle doc あり** →
  - plan-review 記録 **かつ** architect の Post-Transfer Verification 記録あり? → Block 1 スキップ → Block 2a (RED) へ
  - plan-review 記録はあるが architect の Post-Transfer Verification 記録なし? → Phase 2 から再開（sync-plan はスキップし architect のみ実行 — resume gap: sync-plan 完了直後に中断した場合、転記後検証を取りこぼさない）
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

socrates は plan 側（pre-review plan）の WARN/BLOCK 時のみ on-demand で起動する。code mode の REVIEW では起動しない。PASS サイクル (~80%) では spawn しない。
詳細: [../../agents/socrates.md](../../agents/socrates.md)

## Phase 2: Block 1 - Sync-Plan (with Design Review)

### SYNC-PLAN

sync-plan teammate（転記）→ architect teammate（転記後検証）の順で起動する:

```
Task(subagent_type: "dev-crew:sync-plan", team_name: "dev-cycle", name: "sync-plan", model: "sonnet", prompt: "planファイル: [path]。Cycle doc を生成し、plan の Plan Review Record を frontmatter/Progress Log へ転記せよ。")
→ sync-plan が Cycle doc 生成 + Plan Review Record 転記 → 結果報告
→ SendMessage(type: "shutdown_request", recipient: "sync-plan")

Task(subagent_type: "dev-crew:architect", team_name: "dev-cycle", name: "architect", model: "sonnet", prompt: "plan ファイルと Cycle doc [path] を比較し、Post-Transfer Verification を実施せよ。転記欠落=BLOCK / scope 実質変更=AskUserQuestion で再承認 / 観察のみ=DISCOVERED に記録。")
→ architect が転記後検証を実施 → 結果報告
→ SendMessage(type: "shutdown_request", recipient: "architect")
```

### Phase Summary 永続化 (sync-plan→RED)

architect 完了後、PdM が Cycle doc に Phase Summary を追記:

```markdown
### Phase: SYNC-PLAN - Completed at HH:MM
**Artifacts**: Cycle doc updated with PLAN section, Test List (N items)
**Decisions**: architecture=[approach], test strategy=[approach]
**Pre-Review**: verdict=[PASS/WARN/BLOCK], issues=[summary]
**Next Phase Input**: Test List items TC-01 ~ TC-NN
**Subagent**: agent_id={architect_agent_id}, tokens={total_tokens}
- Phase completed
```

### 自律判断

architect の `pre_review.verdict` で判定:

- PASS → Block 2a (Phase 3) へ自動進行
- WARN / BLOCK → Socrates Protocol 発動:

#### Socrates Protocol (pre-review plan)

1. PdM → Task() で socrates を on-demand 起動（Phase名, severity 内訳, reviewer サマリ, 提案, Progress Log）
   ```
   Task(subagent_type: "dev-crew:socrates", model: "opus", prompt: "Phase: pre-review:plan, Severities: [critical:N important:N], Summary: [...], Proposal: [...], Progress Log: [Cycle doc の Progress Log 全文]")
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

**フェーズ入口契約**: 各フェーズ（RED/GREEN/REFACTOR/REVIEW/COMMIT）の開始時に Cycle doc を読み、現在 phase・Test List・Progress Log を把握してから作業する（compaction 直後でも cycle-scoped rules の再ロードを保証する入口 Read）。

### Pre-RED Gate (deterministic)

```bash
bash scripts/gates/pre-red-gate.sh "$CYCLE_DOC"
```

exit 0 → RED へ。exit 1 → BLOCK（gate の出力メッセージで不足ステップを案内。sync-plan 未完了 / Plan Review (pre-approval) の strict 契約違反等）。

> **MUST**: inline の awk/grep による弱チェックを直書きしない。強化された gate script が唯一の判定源（deterministic gate の単独完結原則、rules/multi-file-consistency.md 準拠。3 モード全てが同一 gate を通る）。

### RED

N 個の red-worker teammate を起動（テストファイル別）:
委譲プロンプトは `rules/agent-prompts.md` の契約に従う。

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
Cycle doc `## Verification` セクション不在 or real-path invocation なし → WARN ログを出力しつつ非ブロッキングスキップ (rules/integration-verification.md)。
詳細: [reference.md](reference.md#product-verification)

### REVIEW

実装した文脈とは別の文脈で敵対的レビューを 1 回だけかけ、指摘を修正役が「直す / 人間に戻す / 記録のみ」に振り分ける。頼み方・振り分け・報告の型の単一出典は [adversarial-review.md](adversarial-review.md)。`review` skill は起動しない。

#### 手順

0. **対象の列挙**: `git diff HEAD --name-only` と `git ls-files --others --exclude-standard`（未追跡の新規ファイルを含める）。未追跡ファイルがあれば WARN を出し、レビュー対象に含める。ただし名前が `.env*`・`*.pem`・`*credentials*`・`*secret*` に当たる未追跡ファイルはレビュー対象から外し、WARN を出す（Codex は外部サービスなので秘密を送らない）。
1. **敵対的レビューを 1 回**: REVIEW 中は他の worker に作業ツリーを書かせない（前後の fingerprint 比較が崩れる。red-worker・green-worker の teammate は REVIEW に入る前に完了・shutdown させる）。入力は Cycle doc のパスと対象ファイルの一覧だけ。diff は渡さない（レビュー側が `git diff HEAD` を自分で実行して読み、未追跡ファイルは中身を読む）。レビュー結果は、どちらの経路でも固定のパス `/tmp/dev-crew-review-<cycle_id>/review.md` に置く（`<cycle_id>` は Cycle doc の frontmatter `cycle`。bash 呼び出しをまたいで使うので、変数に持たず固定のパスをそのまま書く）。`which codex` が成功する（codex_mode に関わらない）ときは新しいセッションで Codex を実行する。`resume` しない（steps-codex.md の REVIEW は resume しない唯一の例外）:
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
   Task(subagent_type: "dev-crew:adversarial-reviewer", team_name: "dev-cycle", name: "adversarial-reviewer", model: "opus", prompt: "Cycle doc: [path]. 対象ファイル: [一覧]. adversarial-review.md の ## 頼み方 に従い、git diff HEAD を自分で実行して読み、実行して再現できた指摘だけを high にして報告せよ。作業ツリーを変えるな。")
   → レビュー → 結果報告 → shutdown
   ```
   ```bash
   after=$(bash scripts/gates/worktree-fingerprint.sh); after_rc=$?
   ```
   - PdM は adversarial-reviewer の返答を、Codex と同じパス `/tmp/dev-crew-review-<cycle_id>/review.md` のファイルに書き出す（返答を同じパスのファイルに書き出す。これで修正役への受け渡しが両経路で同じになる）
   - 前後それぞれの終了コードと出力の形（64 桁の 16 進）を確かめる。取得失敗・空・形違いなら BLOCK（一致とみなさない）
   - 前後が違えば作業ツリーが変わっている。レビューを無効にして BLOCK。BLOCK したら `--list` を取り直し、前後の --list の差を人間に見せる（何が変わったかを見るため）
   - adversarial-reviewer も失敗したら BLOCK し、人間に報告する（レビューを省略しない）
2. **修正**: 修正役を起動する前に、PdM が P1・P2 の指摘ごとに、レビュー結果にある場所（ファイル:行）で `bash scripts/gates/finding-in-diff.sh <ファイル> <行>` を実行する（終了コード 0 = diff の中、1 = diff の外、2 = 判定できない）。終了コード 1 の指摘は、元からある欠陥として修正役に「直す」として渡さない。受け入れ条件に関わるなら「人間に戻す」、関わらないなら「記録のみ」にして DISCOVERED に回す。終了コード 0・2 と、場所が書かれていない指摘は、今までどおり修正役の振り分けに任せる。修正役の起動 prompt（Codex への起動文字列と Task の prompt の両方）には、終了コード 1 の指摘を「直さない指摘: [ファイル:行 と、指摘の 1 行目]」として書く（番号ではなく場所と原文で指す）。「直さない指摘」は PdM が振り分け済みなので、修正役は振り分けも報告もしない。件数の行（直す / 人間に戻す / 記録のみ）は、PdM が照合で振り分けた分と、修正役の報告の分を足したものにする。修正役を起動しないときは、P3 の指摘を PdM が「記録のみ」として数える。「直す」が 0 件なら修正役を起動せず、記録（3）へ進む。照合の後に、P1・P2 のうち終了コード 1 でないものとして修正役へ渡す指摘が 1 件以上残れば、修正役を起動する。起動するときは、修正役には常にそのファイルを渡す（`/tmp/dev-crew-review-<cycle_id>/review.md`）。Codex 成功なら Codex の出力、代行なら PdM が書き出した返答で、どちらも同じパス。green-worker teammate（`Task(subagent_type: "dev-crew:green-worker", team_name: "dev-cycle", name: "green-worker-fix", model: "sonnet", prompt: "Cycle doc: [path]. レビュー結果: /tmp/dev-crew-review-<cycle_id>/review.md. adversarial-review.md の ## 振り分け と ## 報告の型 に従え。直さない指摘: [ファイル:行 と、指摘の 1 行目]（無ければ「なし」）。")`）に渡し、「直す」だけを直させる。直す前に呼び出し元の検索と今の動きの固定を済ませ、既存のテストを弱めさせない。
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

### Phase Summary 永続化 (REVIEW→COMMIT)

REVIEW 完了後、PdM が Cycle doc に Phase Summary を追記:

```markdown
### Phase: REVIEW - Completed at HH:MM
**Artifacts**: adversarial review results (/tmp/dev-crew-review-<cycle_id>/review.md: Codex output or the adversarial-reviewer reply written by PdM)
**Decisions**: 直す=N, 人間に戻す=M, 記録のみ=K
**Next Phase Input**: all tests passing, ready to commit
**Subagent**: agent_id={fixer_agent_id}, tokens={total_tokens}
```

### DISCOVERED 判断

REVIEW 完了後、Cycle doc の DISCOVERED セクションを確認:

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

```
Skill(dev-crew:commit)
→ commit skill Step 3 が Cycle doc frontmatter を phase: DONE へ遷移させてから git add & commit
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
