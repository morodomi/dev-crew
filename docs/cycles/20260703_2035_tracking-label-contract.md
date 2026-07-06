---
feature: tracking-label-contract
cycle: 20260703_2035
phase: DONE
complexity: standard
test_count: 8
risk_level: medium
retro_status: resolved
codex_session_id: ""
created: 2026-07-03 20:35
updated: 2026-07-06 11:40
---

# codify 実装 (2) — #151 追跡ラベル自動契約 + codified/captured insight 5 件の rule 実装

## Scope Definition

### In Scope
- [ ] rule 5 ペア（rules/X.md + .claude/rules/X.md byte-identical、計10ファイル）への追記: test-patterns / plan-discipline / integration-verification / agent-prompts / doc-mutations
- [ ] tests/test-codify-rule-docs.sh に TC-34〜38 追加（上記 5 追記の pin）
- [ ] tests/test-doc-consistency.sh に TC-17 追加（#151 本体: tests/*.sh コメント行の追跡ラベル `cycle 2026[0-9]{4}_[0-9]{4}` / `issue #[0-9]+` が 0 件であることを assert）
- [ ] tests/test-factory-model-adaptation.sh:160 の `cycle 20260427_0930` ラベル除去（WHY「cascade timeout 対応」は保持、TC-17 の GREEN 対象）

### Out of Scope
- #147（次の Task 2 cycle）、#148 / #144（v2.12 以降）、CHANGELOG 補完（Task 3）
- 20260703_1650 Insight 3（削除 cycle の予告 FAIL 列挙）→ no-codify 判定済み（observation。同 cycle Codify Decisions 参照）

### Files to Change（全量、plan 承認時点。追加・削除禁止）

#### A. rule 追記（5 ペア = 10 ファイル）
1. `rules/test-patterns.md` — 禁止事項 or 推奨に「外部コマンド出力を while で消費する時は command substitution で**変数に受けて** rc を直後検査してからループする（**process substitution** / pipe 直結は上流失敗を silent skip にする）」+ 出典 20260703_1215
2. `.claude/rules/test-patterns.md`（1と byte-identical）
3. `rules/plan-discipline.md` — 推奨に「指示・rule 文書で 2 回防げなかった規約違反は 3 回目を待たず**自動契約に昇格**する（**2-strike** rule）」+ 出典 20260703_1215
4. `.claude/rules/plan-discipline.md`（3と byte-identical）
5. `rules/integration-verification.md` — 「新 rule cycle への self-apply」節に「新 rule を定義する cycle は REVIEW 前に**全成果物**（テスト・スクリプト・doc）へ新 rule を checklist 適用する」+ 出典 20260703_1215
6. `.claude/rules/integration-verification.md`（5と byte-identical）
7. `rules/agent-prompts.md` — 「同じ規約違反が複数 worker で再発する場合、原因は worker ではなく**委譲 prompt** の共通**テンプレート**にある — 違反除去と同時に指示テンプレートを grep 監査する」+ 出典 20260703_1650
8. `.claude/rules/agent-prompts.md`（7と byte-identical）
9. `rules/doc-mutations.md` — SSOT 即時同期の項に「フェーズを**実行した主体**がそのフェーズで完了した **Test List 遷移**まで行う」+ 出典 20260703_1650
10. `.claude/rules/doc-mutations.md`（9と byte-identical）

#### B. テスト編集（新規ファイルなし、count 112 不変）
11. `tests/test-codify-rule-docs.sh` — TC-34〜38（上記 5 追記の pin、TC-27 テンプレート踏襲、contiguous literal + 出典 cycle_id）
12. `tests/test-doc-consistency.sh` — **TC-17（#151 本体）**: `tests/*.sh` のコメント行（`^[[:space:]]*#`）に `cycle 2026[0-9]{4}_[0-9]{4}` または `issue #[0-9]+` が 0 件であることを assert。fixture の heredoc frontmatter（`cycle:` 行）はコメント行でないため構造的に非対象。git ls-files 不要（tests/ 直接 glob + BASE_DIR、rc は変数受け直後検査 — 本 cycle が追記する process-substitution rule の self-apply）
13. `tests/test-factory-model-adaptation.sh` — L160 コメントから `cycle 20260427_0930` ラベル除去（WHY「cascade timeout 対応」は保持）— TC-17 の GREEN

#### C. Cycle doc
14. `docs/cycles/20260703_2035_tracking-label-contract.md`（sync-plan 生成、本ファイル）

## Environment

### Scope
- Layer: Documentation / Test contracts（実装コードなし、rule 定義・テスト契約のみ）
- Plugin: dev-crew（bash/doc project）
- Risk: ~40（WARN 帯）

### Runtime
- Language: Bash（テストスクリプト）、Markdown（rule docs）

### Dependencies (key packages)
- なし（新規依存追加なし）

### Risk Interview (BLOCK only)
- 該当なし（Risk ~40 は WARN 帯であり BLOCK 未満）

## Context & Dependencies

### Reference Documents
- `docs/cycles/20260703_1215_test-hardening-rule-codify.md` — codified 済み insight (a) integration-verification self-apply 拡張、(b) test-patterns の process-substitution rc 検査の出典元
- `docs/cycles/20260703_1650_parallel-skill-removal.md` — captured insight (d)(e)(f) の出典元。Codify Decisions で (d)→agent-prompts.md codified、(e)→doc-mutations.md codified、(f)→no-codify を確定済み（retro_status: resolved、frontmatter 実測確認済み）
- `.claude/rules/plan-discipline.md` — 2-strike rule の追記先。baseline 実測・逆向き契約 sweep の適用元
- `.claude/rules/agent-prompts.md` — 委譲 prompt テンプレート監査原則の追記先
- `.claude/rules/doc-mutations.md` — SSOT 即時同期節への Test List 遷移責務追記先
- `.claude/rules/integration-verification.md` — self-apply 節への全成果物 checklist 追記先
- `.claude/rules/test-patterns.md` — process substitution rc 検査パターンの追記先

### Dependent Features
- `tests/test-codify-rule-docs.sh`: TC-33 が最終（本 cycle で TC-34〜38 を追加）
- `tests/test-doc-consistency.sh`: TC-16 が最終（本 cycle で TC-17 を追加）
- `tests/test-rules-mirror.sh`: rules/ と .claude/rules/ の byte-identical 契約（既存）

### Related Issues/PRs
- issue #151（追跡ラベル自動契約、本 cycle の主目的）
- ROADMAP v2.11 残タスク1（ユーザー承認済み: 「1,2,3,4 の順で実行」の一部）

## Test List

### TODO
(none)

### WIP

### DISCOVERED
(none)

### DONE
- [x] TC-01: Given rules/test-patterns.md, When section_grep で「変数に受けて」「process substitution」+ 出典 20260703_1215, Then count ≥1（TC-34、GREEN で PASS）
- [x] TC-02: Given rules/plan-discipline.md, When 「自動契約に昇格」「2-strike」+ 出典, Then count ≥1（TC-35、GREEN で PASS）
- [x] TC-03: Given rules/integration-verification.md, When 「全成果物」+ 出典, Then count ≥1（TC-36、GREEN で PASS）
- [x] TC-04: Given rules/agent-prompts.md, When 「委譲 prompt」「テンプレート」連続句 + 出典 20260703_1650, Then count ≥1（TC-37、GREEN で PASS）
- [x] TC-05: Given rules/doc-mutations.md, When 「実行した主体」「Test List 遷移」+ 出典, Then count ≥1（TC-38、GREEN で PASS）
- [x] TC-06: Given tests/*.sh のコメント行, When 追跡ラベル pattern を grep, Then 0 件（TC-17、5 ファイル 5 件のラベル除去後に GREEN で PASS）
- [x] TC-07: Given rules/ と .claude/rules/, When test-rules-mirror.sh, Then byte-identical（GREEN 後の 5 ペア追記を含め再検証・PASS 維持）
- [x] TC-08: Given 全 suite, When 一括実行, Then baseline との diff 空（112/112、GREEN 完了後に検証）（VERIFY で完了: full suite 112/112・baseline diff 空）

## Implementation Notes

### Goal
ROADMAP v2.11 残タスク1（ユーザー承認済み）。issue #151（追跡ラベルの自動 inverse contract）と、直近 2 cycle（20260703_1215 codified / 20260703_1650 captured）の insight 5 件を同一ファミリーとして一括実装する。

### Background
- #151: テストコメントへの cycle 番号 / issue 番号混入が 3 cycle 連続再発し、発生源が PdM の委譲 prompt テンプレートと判明済み。手動レビュー検出（3 回とも maintainability）から自動契約へ昇格する — これ自体が今回追記する 2-strike rule の初適用
- codified 済み（20260703_1215）: (a) integration-verification self-apply 拡張、(b) test-patterns の process-substitution rc 検査。deferred（同 #2）: (c) 2-strike rule → #151 と同 cycle 実装の判定済み
- captured（20260703_1650、本 cycle の orchestrate Block 0 codify gate で triage 済み・resolved）: (d) 再発違反は委譲 prompt テンプレートを疑う → agent-prompts.md、(e) フェーズ実行主体が Test List 遷移まで担う → doc-mutations.md、(f) 削除 cycle の予告 FAIL 列挙 → no-codify（observation）

### Design Approach
RED で TC-34〜38（5 rule 追記の pin）+ TC-17（#151 本体、tests/*.sh コメント行の追跡ラベル 0 件契約）を先に追加し、TC-17 が factory-model-adaptation.sh:160 の残存ラベルで実 FAIL することを確認する。GREEN で rule 5 ペアを追記（rules/ + .claude/rules/ byte-identical）し、ラベルを除去する。REVIEW 前に integration-verification 新 rule の self-apply（本 cycle の全成果物へ本 cycle が追記する 5 rule を checklist 適用）を実施し Progress Log に記録する。

## Verification（real-path invocation — usage 実測済み形式のみ）

```bash
SCRATCH=/private/tmp/claude-501/-Users-morodomi-Projects-MorodomiHoldings-agents-dev-crew/74f3a9a9-3af1-4977-80a3-f0ee96a13dd1/scratchpad
bash tests/test-codify-rule-docs.sh; echo "rc=$?"
bash tests/test-rules-mirror.sh; echo "rc=$?"
# TC-17 相当の直接検査
grep -rnE '^[[:space:]]*#.*(cycle 2026[0-9]{4}_[0-9]{4}|issue #[0-9]+)' tests/*.sh || echo "label 0件"
# real-path: pre-commit-gate 明示指定
bash scripts/gates/pre-commit-gate.sh docs/cycles/20260703_2035_tracking-label-contract.md; echo "rc=$?"
# full suite（snapshot baseline 比較）
for f in tests/test-*.sh; do timeout 2400 bash "$f" >/dev/null 2>&1; printf "%s rc=%d\n" "$(basename $f)" "$?"; done | sort > "$SCRATCH/after-label.txt"
if grep -v "rc=0" "$SCRATCH/after-label.txt"; then echo "VERIFY FAIL"; false; else echo "all rc=0"; fi
diff "$SCRATCH/baseline-label.txt" "$SCRATCH/after-label.txt" && echo "no regression"
```

Evidence: (orchestrate が自動記入)

self-apply（integration-verification 新 rule の初 dogfood）: REVIEW 前に「本 cycle の全成果物（TC-34〜38 / TC-17 / rule 文面）へ本 cycle が追記する 5 rule を checklist 適用」を PdM が実施し Progress Log に記録する。

## Progress Log

### 2026-07-03 20:35 - KICKOFF

**Design Review Gate 実施結果: PASS**

以下を Read/grep で現物追認し、plan 記載の実測事実と完全一致を確認（tests/ の実行はせず読み取りのみ、teammate 指示に基づく）:

- 次 TC 番号: `tests/test-codify-rule-docs.sh` の最終 TC は TC-33（L684-698、multi-file-consistency.md 追記の pin）→ 本 cycle は TC-34〜38 が正しい採番
- 次 TC 番号: `tests/test-doc-consistency.sh` の最終 TC は TC-16（L144-178、live tracked files inverse contract）→ 本 cycle は TC-17 が正しい採番
- `tests/test-factory-model-adaptation.sh:160` — `# Skip self and known recursive / slow tests (cascade timeout 対応、cycle 20260427_0930)` の残存ラベルを現物確認（plan 記載「実 RED 対象が 1 件現存」と一致）
- 追跡ラベル pattern `^[[:space:]]*#.*(cycle 2026[0-9]{4}_[0-9]{4}|issue #[0-9]+)` を `tests/*.sh` 全体に実行 → hit は factory-model-adaptation.sh:160 の 1 件のみ。plan 記載の「TC-17 は追加直後に実 FAIL する（1件）」と完全一致
- 新 literal の pre-existing count（各対象 rule ファイル全体で実測）: `変数に受けて`=0 / `process substitution`=0（test-patterns.md）、`自動契約に昇格`=0 / `2-strike`=0（plan-discipline.md）、`全成果物`=0・`checklist`=1（integration-verification.md、単体語のため連続句「全成果物」自体は非衝突）、`委譲 prompt`=0 / `テンプレート`=0（agent-prompts.md）、`実行した主体`=0・`Test List`=1（doc-mutations.md、単体句「Test List」のみで「Test List 遷移」の連続句は 0）。plan 記載の実測値と完全一致
- rules/ と .claude/rules/ の 5 対象ファイル（test-patterns / plan-discipline / integration-verification / agent-prompts / doc-mutations）を `diff -q` で全て byte-identical と確認
- `tests/test-*.sh` の総数を `ls tests/test-*.sh | wc -l` で 112 と確認（`docs/STATUS.md` の `Test Scripts | 112` と一致、plan 記載「count 112 不変」の baseline と一致）
- codify gate 処理済みの確認: `docs/cycles/20260703_1650_parallel-skill-removal.md` の frontmatter（未 staged 変更）で `retro_status: resolved` を確認。同ファイル末尾 `## Codify Decisions` セクションで Insight 1（→ agent-prompts.md codified）、Insight 2（→ doc-mutations.md codified）、Insight 3（→ no-codify）が記録済みであることを確認。plan 記載「captured（20260703_1650、本 cycle の orchestrate Block 0 codify gate で triage 予定）」は処理済みの前提で正しい
- TC-17 pattern の false-positive 耐性確認: `tests/test-pre-commit-gate-retro.sh` の `make_gate_fixture()`（L26-）を確認。fixture の frontmatter は `echo "cycle: 20260101_0000"` 等のシェルコマンド行として生成されており、`^[[:space:]]*#` で始まるコメント行ではない。よって TC-17 のコメント行限定 grep はこの fixture 生成コードを誤検出しない。また fixture 自体は `mktemp -d` で tests/ 外の一時ディレクトリに書き出されるため、`tests/*.sh` glob のスキャン対象にも構造的に含まれない。plan 記載「fixture の heredoc frontmatter はコメント行でないため構造的に非対象」を実物で確認

**注記**: 作業ディレクトリに `docs/cycles/20260703_1650_parallel-skill-removal.md` の未 staged 変更あり（前 cycle #142 の Codify Decisions セクション追記 + retro_status: captured → resolved、orchestrate Block 0 codify gate 処理結果）。本 cycle の Files to Change には含まれず、scope 外として変更せず維持。

**テスト実行**: 本 KICKOFF では tests/ の実行は行っていない（PdM が snapshot baseline を並行取得中のため、読み取りのみに限定。teammate 指示に基づく）。

**判定**: Design Review Gate PASS。plan の実測事実・Files to Change・Test List・Verification の記載は全て現物と一致し、齟齬・虚偽記載なし。frontmatter 初期化完了（phase: KICKOFF、retro_status: none）。

### 2026-07-03 21:00 - PLAN REVIEW (Codex competitive)
- 判定: **WARN 3**（BLOCK なし）。triage 全件 accept-apply:
- **F1（TC-17 の rc=2 false-pass / fixture 互換）**: TC 本体は「変数受け + rc 直後検査 + 対象ファイル 0 件も FAIL」で実装（process-substitution rule の self-apply）。BASE_DIR fixture 実行時（test-meta-doc-consistency）にも abort せず fail 集計する構造にする
- **F2（pattern 意図の明文化 + 範囲確定）**: PdM が case-insensitive + 区切り文字許容の広い pattern `(cycle[: (]+2026[0-9]{4}|issue #[0-9]+)` で全 sweep を実測 → **hit は 5 ファイル 5 行のみ**（factory-model:160 / rules-path-scoping:3 / spec-onboard-improvements:3 / skill-maker:3 / stale-references:3）。契約はこの広い pattern を採用し、GREEN で 5 件全て除去（global CLAUDE.md 規約の完全実装）。scope +4 ファイル（header 1 行編集）を Files to Change に追加（SSOT 即時同期）
- **F3（TC-36 の section 設計）**: 追記先「新 rule cycle への self-apply」は H3 で section_grep（H2 のみ対応）が使えないため、TC-36 は H2「適用範囲」に対して contiguous literal「全成果物」+「checklist 適用」を検査する設計に変更
- baseline-label.txt: **112/112 全 rc=0**（隔離 snapshot、commit 678f907 + codify gate 編集済み 20260703_1650 を含む）
- 判定: Block 2a (RED) へ

#### Files to Change 拡張（F2 反映、GREEN はこれを正とする）
15. tests/test-rules-path-scoping.sh:3 — header の cycle 番号ラベル除去
16. tests/test-spec-onboard-improvements.sh:3 — 同上
17. tests/test-skill-maker.sh:3 — 同上
18. tests/test-stale-references.sh:3 — header の Issue 番号ラベル除去（WHY 記述は保持）

### 2026-07-03 21:40 - RED

**変更対象**: `tests/test-codify-rule-docs.sh`（TC-34〜38 追加）、`tests/test-doc-consistency.sh`（TC-17 追加）の 2 ファイルのみ。rule 追記・ラベル除去は GREEN の scope として未着手。

**事前必須（rules/test-patterns.md A2 + red skill Stage 3.5）: pre-existing count 実測**

`section_grep` ヘルパーで各追記対象 section の pre-existing count を実測（全て 0 を確認）:

```
TC-34 推奨:変数に受けて=0 / 推奨:process substitution=0 / 出典:20260703_1215=0
TC-35 推奨:自動契約に昇格=0 / 推奨:2-strike=0 / 出典:20260703_1215=0
TC-36 適用範囲:全成果物=0 / 適用範囲:checklist 適用=0 / 出典:20260703_1215=0
TC-37 並列起動時の prompt 契約:委譲 prompt=0 / 同:テンプレートを疑=0 / 出典:20260703_1650=0
TC-38 SSOT 即時同期:実行した主体=0 / 同:Test List 遷移=0 / 出典:20260703_1650=0
```

**発見事項（Design Review 時点で未検出の実装上の罠）**:

1. `section_grep` の見出しマッチは awk 正規表現の直渡しであり、括弧を含む見出し文字列
   （`並列起動時の prompt 契約 (3+ subagent fan-out)` / `SSOT 即時同期 (cycle 20260422_1313 #2)`）
   を渡すと丸括弧が ERE のグルーピングとして解釈され、対象 section が一切マッチしない
   （count は常に 0 = 偽 PASS のリスク）。既知の既存文言（`担当範囲` / `collateral fix`）で
   フル見出し vs 括弧を除いた短縮見出しを比較実測して確認: フル見出しでは count=0（未マッチ）、
   短縮見出しでは正しく count が拾えることを確認した。TC-37 は
   `並列起動時の prompt 契約`、TC-38 は `SSOT 即時同期` の短縮見出しを採用（TC-13 の
   既存 convention と一致）。
2. TC-37/TC-38 のコメントに追記理由を書く際、自分自身が「cycle 20260422_1313」という
   追跡ラベルを literal で書いてしまい、自分が追加した TC-17（tests/*.sh コメント行の
   追跡ラベル 0 件契約）に自己違反するインシデントが 2 件発生（
   `tests/test-codify-rule-docs.sh` の TC-37/TC-38 コメント、
   `tests/test-doc-consistency.sh` の TC-17 セクション見出しコメント `(issue #151)`）。
   両方とも即座に検出し、cycle 番号 / issue 番号を含まない言い換えに修正済み
   （本 cycle が追記する 2-strike rule・self-apply 精神の RED 時点での実地確認）。

**TC-17 契約詳細（#151 本体）**:

- パターン: `^[[:space:]]*#.*(cycle[: (]+2026[0-9]{4}|issue #[0-9]+)`（case-insensitive、PLAN REVIEW F2 の広域 pattern）
- 対象ファイル一覧を配列 `TEST_FILES=("$BASE_DIR"/tests/*.sh)` で受け、件数 0 なら glob 失敗として FAIL（rules/plan-discipline.md 準拠）
- grep 結果は `LABEL_HITS=$(...) || LABEL_HITS_RC=$?` の form で受け、rc を直後検査。
  `set -euo pipefail` 環境で bare `$(...)` 代入だと grep rc=1（無マッチ = 期待される GREEN 後の状態）でも
  `set -e` がスクリプト全体を即時中断することを実測で確認（`x=$(grep ... 2>/dev/null)` 単体で検証、
  script が `echo` に到達せず終了）。`|| LABEL_HITS_RC=$?` で回避し、rc=1→PASS / rc=0→FAIL(hits) /
  rc≥2→FAIL(grep error) の 3 分岐にした
- BASE_DIR fixture 実行（test-meta-doc-consistency 相当）で `tests/` が存在しない場合、
  glob が展開されず literal path が渡り grep rc=2（No such file）になるが、上記 rc 分岐により
  abort せず TC-17 が FAIL 計上されるだけでスクリプトは Summary まで到達することを
  孤立実行で実測確認済み（"script reached end" ログ出力を確認）

**Pre-existing hit 実測（PLAN REVIEW F2 の広域 pattern を再実測、5 ファイル 5 件で完全一致）**:

```
tests/test-factory-model-adaptation.sh:160:  # Skip self and known recursive / slow tests (cascade timeout 対応、cycle 20260427_0930)
tests/test-rules-path-scoping.sh:3:# TC-01 to TC-04 for rules-path-scoping cycle (20260625_1101)
tests/test-skill-maker.sh:3:# Cycle: 20260215_1500_skill-maker
tests/test-spec-onboard-improvements.sh:3:# Cycle: 20260315_1500_spec-onboard-improvements
tests/test-stale-references.sh:3:# Issue #28: update stale references after auto-transition removal (#27)
```

**自己証明（inverse contract の健全性）**: TC-17 ロジックを孤立実行で 3 パターン検証。
(a) 現状の実 repo → `RESULT=FAIL_HITS_FOUND`（rc=0, 5 件）、
(b) 上記 5 件を除去したフィクスチャ → `RESULT=PASS`（rc=1）、
(c) `tests/` 不在フィクスチャ → `RESULT=FAIL_GREP_ERROR` かつ script は abort せず末尾まで到達。
(a)→(b) の遷移で FAIL→PASS が切り替わることを確認し、「対象行を除去すると FAIL が解消する」
ことを自己証明した。

**RED 実行結果（個別実行、full suite・nested runner なし）**:

```
bash tests/test-codify-rule-docs.sh; echo "rc=$?"
→ rc=1, PASS: 33 / FAIL: 5 / TOTAL: 38（TC-01〜33 PASS 維持、TC-34〜38 のみ FAIL）

bash -n tests/test-doc-consistency.sh
→ syntax OK（単体実行は TC-13 の nested runner のため禁止。TC-17 部分ロジックの
  孤立実行で FAIL/PASS 遷移を上記の通り検証）

bash tests/test-rules-mirror.sh; echo "rc=$?"
→ rc=0（rules/ と .claude/rules/ の byte-identical 契約、本 cycle 未着手のため無変化で PASS 維持を確認）
```

**想定外事象**: 上記「発見事項」2 件（section_grep 括弧問題、コメント内 self-violation 2 箇所）。
いずれも RED フェーズ内で検出・是正済み。plan file・Files to Change の変更は不要（実装ロジックの
記述方法のみの是正であり、テスト対象の契約内容・対象ファイルに変更はない）。

**判定**: RED 完了。TC-34〜38・TC-17 は全て意図通り FAIL（本物の RED）。他 TC は無影響（回帰なし）。GREEN へ進む。

---

### 2026-07-03 22:15 - GREEN

**変更ファイル（15 件、Files to Change #1-13, #15-18 全量）**:

A. rule 追記（5 ペア = 10 ファイル、rules/ と .claude/rules/ を同一内容で更新し byte-identical 維持）:
1. `rules/test-patterns.md` / `.claude/rules/test-patterns.md` — 推奨末尾に「変数に受けて」「process substitution」literal + 出典に `docs/cycles/20260703_1215_test-hardening-rule-codify.md` Insight 3
2. `rules/plan-discipline.md` / `.claude/rules/plan-discipline.md` — 推奨末尾に「自動契約に昇格」「2-strike」literal + 出典に cycle 20260703_1215 #2
3. `rules/integration-verification.md` / `.claude/rules/integration-verification.md` — 「新 rule cycle への self-apply」節末尾に「全成果物」「checklist 適用」literal + 出典に cycle 20260703_1215 #1
4. `rules/agent-prompts.md` / `.claude/rules/agent-prompts.md` — 「並列起動時の prompt 契約」節末尾に「委譲 prompt」「テンプレートを疑」literal + 出典に cycle 20260703_1650 #1
5. `rules/doc-mutations.md` / `.claude/rules/doc-mutations.md` — 「SSOT 即時同期」節末尾に「実行した主体」「Test List 遷移」literal + 出典に cycle 20260703_1650 #2

B. 追跡ラベル除去（5 ファイル、TC-17 の GREEN、WHY 記述は保持しラベルのみ除去）:
6. `tests/test-factory-model-adaptation.sh:160` — `cycle 20260427_0930` 除去（`cascade timeout 対応` は保持）
7. `tests/test-rules-path-scoping.sh:3` — `(20260625_1101)` 除去
8. `tests/test-skill-maker.sh:3` — `# Cycle: 20260215_1500_skill-maker` 行を削除（隣接行が同内容を重複記述しており情報欠落なし）
9. `tests/test-spec-onboard-improvements.sh:3` — `# Cycle: 20260315_1500_spec-onboard-improvements` 行を削除（同上）
10. `tests/test-stale-references.sh:3` — `Issue #28: ... (#27)` を除去し `# update stale references after auto-transition removal` に置換（WHY 保持）

**編集前 pin 確認**: `grep -rn "cascade timeout\|20260427_0930|TC-01 to TC-04 for rules-path-scoping|20260625_1101|Cycle: 20260215_1500_skill-maker|Cycle: 20260315_1500_spec-onboard-improvements|Issue #28" tests/*.sh` を実行し、対象コメント行自身以外に pin する assertion がないことを確認済み（`tests/test-codify-rule-docs.sh` の TC-27 は `20260625_1101` を出典 section の値として検査しているが `#` コメント行ではなくコード行のため TC-17 pattern と無衝突）。

**GREEN 確認結果（個別実行、全 rc=0）**:

```
bash tests/test-codify-rule-docs.sh; echo rc=$?
→ PASS: 38 / FAIL: 0 / TOTAL: 38, rc=0（TC-34〜38 含め全 PASS）

grep -rniE '^[[:space:]]*#.*(cycle[: (]+2026[0-9]{4}|issue #[0-9]+)' tests/*.sh
→ 0 件（grep rc=1、TC-17 相当の直接検査 PASS）

bash tests/test-rules-mirror.sh; echo rc=$?
→ PASS: 3 / FAIL: 0, rc=0（rule 追記後も rules/ と .claude/rules/ byte-identical 維持）

bash tests/test-rules-path-scoping.sh; echo rc=$?   → PASS 4/4, rc=0
bash tests/test-skill-maker.sh; echo rc=$?           → PASS 23/23, rc=0
bash tests/test-spec-onboard-improvements.sh; echo rc=$? → PASS 14/14, rc=0
bash tests/test-stale-references.sh; echo rc=$?     → PASS 9/9, rc=0
bash -n tests/test-factory-model-adaptation.sh       → syntax OK（nested runner のため単体実行禁止、TC-14 経由で full suite 時に検証）

ls tests/test-*.sh | wc -l → 112（plan 記載の「count 112 不変」と一致）
diff -q rules/{test-patterns,plan-discipline,integration-verification,agent-prompts,doc-mutations}.md .claude/rules/{同}.md → 差分なし（5 ペア全て byte-identical）
```

**判定**: GREEN 完了。TC-34〜38・TC-17 は全て意図通り PASS。TC-07（mirror）も再検証 PASS。TC-08（full suite baseline diff）は REFACTOR/VERIFY フェーズで検証予定のため WIP に残置。`tests/test-codify-rule-docs.sh` / `tests/test-doc-consistency.sh` の RED 成果物は変更なし。REFACTOR へ進む。

### 2026-07-03 22:30 - REFACTOR + SELF-APPLY (PdM)
- rule/テスト追記のみの cycle のため構造的リファクタ不要（no-op）。対象 6 test rc=0、mirror 5 ペア identical、label 直接 grep 0 件
- **self-apply checklist 実行（integration-verification 新 rule「全成果物へ checklist 適用」の初 dogfood）**:
  1. process-substitution rule → TC-17 実装が変数受け + rc 直後検査を採用（準拠）
  2. 2-strike rule → 本 cycle 自体が初適用（追跡ラベル 3 回再発 → 自動契約化）
  3. 全成果物 checklist → 本チェックリストの実行そのもの
  4. 委譲 prompt テンプレート監査 → 本 cycle の red/green prompt に cycle 番号を含む指示なし（RED worker は自己違反 2 件を Stage 3.5 で自主検出・修正済み）
  5. Test List 遷移 → GREEN が TC-01〜07 を DONE へ即時遷移、TC-08 は VERIFY 残置（準拠）
- Phase completed

### 2026-07-03 23:00 - VERIFY (Product Verification, Block 2c.5)
- Evidence: /tmp/dev-crew-verify-20260703_2035/verify.log（full suite は途中 kill のため同 log に再実行分を追記）
- 単体: codify-rule-docs（38/38）/ rules-mirror rc=0。TC-17 直接検査: label 0件（rc 直後検査形式）
- real-path: pre-commit-gate 明示指定 → 本 cycle doc 選択、REVIEW 未完了 BLOCK（正常）
- **full suite: 112/112 全 rc=0、baseline-label.txt との diff 空 = 回帰ゼロ**
- Phase completed

### 2026-07-03 23:45 - REVIEW (Codex competitive + 3 Claude reviewers, MED tier)
- 判定: Codex **WARN 3** / correctness **WARN（HIGH 1）** / security **PASS** / maintainability **PASS（LOW 3）**
- triage（accept-apply 7 / reject 0）:
  1. Codex F1: TC-17 の glob 0 件検査が bash default glob で実効しない → nullglob 化 + 孤立実行で (a) 実 repo PASS / (b) tests/ 不在 FAIL を実証
  2. Codex F2: TC-08 の DONE 遷移漏れ + Next Steps stale → PdM が遷移（本 cycle 追記 rule「実行した主体が Test List 遷移まで担う」の self-apply 違反を自己修正）
  3. Codex F3 + correctness HIGH: **PdM の frontmatter 遷移一括置換が cycle doc 本文を汚染**（20260703_1650 の KICKOFF エントリが commit 前に汚染→commit 混入→codify で二重汚染。correctness が git show HEAD 対比で無言書き換えを検出）→ 本文 2 箇所を真の値に復元 + 20260703_1650 EOF に APPEND-ONLY 準拠の訂正記録を追記
  4. maint LOW1: 用語揺れ「自動検出」→「自動契約」統一
  5. maint LOW2: integration-verification 追記を bullet 整形（literal 保持、mirror 同期）
  6. maint LOW3（出典形式の既存 drift）→ 既存 drift の継続でありスコープ外、対応なし（reject ではなく defer 扱い、恒久対応は不要と判断）
- 適用後: codify-rule-docs 38/38 / rules-mirror 3/3 / TC-17 孤立実行 (a)(b) / 用語 grep 0 件 — 全て確認済み
- Phase completed

### 2026-07-04 00:20 - COMMIT
- 最終 full suite: **112/112 全 rc=0、baseline-label.txt との diff 空（回帰ゼロ）**（scratchpad/final-label.txt）
- pre-commit gate 明示指定モードで dogfood 後 commit、PR 作成・merge（ユーザー包括承認済み）
- Phase completed

---

## Next Steps

1. [Done] KICKOFF
2. [Done] PLAN REVIEW (Codex competitive)
3. [Done] RED
4. [Done] GREEN <- Current
5. [Next] REFACTOR
6. [ ] REVIEW
7. [ ] COMMIT
8. [ ] DONE

## Retrospective

抽出時刻: 2026-07-04 00:05
抽出方法: Cycle doc 全体（PLAN REVIEW WARN 3 / RED の罠 2 件 / REVIEW の HIGH 1 件）からの失敗→最終解→insight ペア抽出

### Insight 1: frontmatter の状態遷移は frontmatter 範囲限定で編集する（whole-file replace は本文を汚染する）
- **Failure**: PdM の retro/codify 処理が Python の全文 str.replace で frontmatter を遷移させ、Progress Log 本文中の同一文字列（「retro_status: none」等の記録的言及）を巻き込んだ。1 回目の汚染は commit 684537a に混入して見逃され、2 回目の codify 処理で二重汚染。correctness reviewer が `git show HEAD` 対比で「commit 済み本文の無言書き換え」として検出
- **Final fix**: 本文 2 箇所を当時の真の値に復元し、対象 cycle doc EOF に APPEND-ONLY 準拠の訂正記録を追記。行アンカー付き（re.MULTILINE の ^...$ 一致、count=1）置換に切り替え
- **Insight**: **frontmatter の状態遷移は frontmatter 区間限定（行頭アンカー + count=1、または awk 区間抽出）で編集する。全文一括置換は本文中の記録的言及を必ず巻き込む**。test-patterns.md の「whole-file grep で frontmatter state 禁止」の**編集版**であり、grep で禁止した誤りを edit で再発させた
- **一般化**: doc-mutations.md 追記候補。cycle doc は「状態」と「状態についての記録」が同居する文書であり、状態遷移操作は構造を認識して行う

### Insight 2: section_grep へ渡す見出しは ERE メタ文字を含まない短縮形にする
- **Failure**: 括弧付き見出し（「並列起動時の prompt 契約 (3+ subagent fan-out)」等）をフル見出しで section_grep に渡すと、丸括弧が awk ERE のグルーピングとして解釈され対象 section に一切マッチしない（count=0 の silent no-match = TC が永遠に FAIL、または逆に偽 PASS 設計の温床）。RED worker が既存文言の比較実測で検出
- **Final fix**: 括弧を含まない短縮見出し（前方一致）を採用（TC-13 の既存 convention と同じ）
- **Insight**: **section_grep の heading 引数は ERE として解釈される。メタ文字（括弧・+・.）を含む見出しは短縮形で渡すか、helper を fixed-string 比較に変更する**。literal の pre-existing count 実測（A2 rule）は「マッチする section を正しく切り出せている」ことが前提であり、見出しマッチ自体の検証も必要
- **一般化**: test-patterns.md 追記候補（section_grep 使用規約）。helper の fixed-string 化は #148（drift guard）系の改修と同時が効率的

### 成功事例（observation）: 新契約を書く worker の自己違反を Stage 3.5 が即検出
- TC-17（追跡ラベル禁止契約）を実装する red-worker 自身のコメントが TC-17 に違反する 2 箇所を、Stage 3.5（False-pass 自己証明）の実行過程で自主検出・修正。前 cycle で追加した red skill step と 2-strike rule が設計通り機能した実証。「契約を書く者が最初の違反者になる」パターンは自動契約の即時自己適用でのみ防げる

## Codify Decisions

triage 実施: 2026-07-06 10:10（後続 cycle phase-lifecycle-completion-gate の orchestrate Block 0 codify gate で処理）。autonomous triage、質問 0 件。frontmatter 遷移は行アンカー + count=1 の範囲限定編集で実施（本 doc の Insight 1 の即時適用）。

### Insight 1
- **Decision**: codified
- **Destination**: rule (rules/doc-mutations.md + .claude/rules/ mirror)
- **Reason**: 「frontmatter の状態遷移は frontmatter 区間限定で編集する。全文一括置換は本文中の記録的言及を巻き込む」。二重汚染 + commit 混入の実害 evidence あり。実装は次の codify 実装 cycle（本 cycle は #147 phase lifecycle が scope のため混ぜない）
- **Decided**: 2026-07-06 10:10

### Insight 2
- **Decision**: codified
- **Destination**: rule (rules/test-patterns.md + .claude/rules/ mirror)
- **Reason**: 「section_grep の heading 引数は ERE 解釈される。メタ文字を含む見出しは短縮形で渡す」。silent no-match の実測 evidence あり。実装は次の codify 実装 cycle（helper の fixed-string 化は #148 と同時が効率的、と origin insight が示唆）
- **Decided**: 2026-07-06 10:10

### 成功事例（observation）
- **Decision**: no-codify
- **Reason**: Stage 3.5 + 2-strike rule の有効性実証は前 2 cycle で codify 済みの rule 群の追認であり、新規 rule 化は不要
- **Decided**: 2026-07-06 10:10
