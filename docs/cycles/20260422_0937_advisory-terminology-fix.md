---
feature: advisory-terminology-fix
cycle: eval-4
phase: REVIEW
complexity: trivial
test_count: 6
risk_level: low
retro_status: captured
codex_session_id: "019db29f-ab0e-7632-a181-e52b68ce33ac"
created: 2026-04-22 09:37
updated: 2026-04-22 11:02
---

# eval-4: TC-09 "advisory" 用語置換 (Revised after Codex plan review round 1)

## Scope Definition

### In Scope (Revised: 2 files / 2 lines)
- [ ] `skills/orchestrate/steps-codex.md` L90: `advisory evidence、委譲不要` → `参考エビデンス、委譲不要`
- [ ] `skills/orchestrate/steps-teams.md` L185: `advisory evidence、委譲不要` → `参考エビデンス、委譲不要` (mirror)

### Out of Scope (改訂理由明記)
- **`skills/orchestrate/reference.md`** — `test-product-verify.sh` TC-07 が `grep -qi 'advisory'` AND `grep -qiE 'non.blocking'` を要求する契約対象。変更すると TC-07 が regression する。
- **`skills/orchestrate/SKILL.md`** — L24/L78 は reference.md の契約用語にクロスリンクする形で 'advisory' を使用。reference.md と整合性を保つため不変とする。
- **`skills/orchestrate/steps-subagent.md` (L146, L150)** — 別モード (subagent mode) 向けの execution note。テスト未要求、Codex 推奨 `codex/teams mirror まで` を採用し scope 外とする。
- `CLAUDE.md` (dev-crew) L32 `advisory スキル` — cycle-retrospective の skill nature 記述、別文脈
- `tests/test-codex-delegation-interface.sh` (authoritative として扱う。eval-1/2/3 pattern: 源を test に合わせる)

### Files to Change (target: 10 or less)
- `skills/orchestrate/steps-codex.md` (edit: 1 line)
- `skills/orchestrate/steps-teams.md` (edit: 1 line)

## Environment

### Scope
- Layer: Both (doc-only変更)
- Plugin: dev-crew
- Risk: 10 (PASS)

### Runtime
- Language: N/A (doc change only)

### Dependencies (key packages)
- なし

### Risk Interview (BLOCK only)
- N/A

## Context & Dependencies

### Reference Documents
- `docs/cycles/20260421_2342_agents-md-count-fix.md` — eval-3 precedent: pre-existing FAIL 解消 pattern
- `CONSTITUTION.md` — Codex 委譲関係の competitive review 原則
- `skills/orchestrate/reference.md#product-verification` — VERIFY の evidence nature 定義（非ブロッキング）

### Dependent Features
- なし

### Related Issues/PRs
- なし (dogfood eval-4 cycle)

## Test List

### TODO
- [ ] TC-A1: TC-09 解消確認 — Given: steps-codex.md L90 の `advisory` を `参考` に置換 / When: `bash tests/test-codex-delegation-interface.sh` / Then: TC-09 PASS、Summary `PASS: 18 / FAIL: 0 / TOTAL: 18`
- [ ] TC-A2: test-codex-delegation-interface.sh 既存項目の回帰なし — Given: TC-A1完了後 / When: 同テスト実行 / Then: TC-01〜TC-08, TC-10〜TC-18 全て PASS 維持
- [ ] TC-A3: test-product-verify.sh 契約維持 (TC-07 含む) — Given: reference.md 不変 / When: `bash tests/test-product-verify.sh` / Then: Summary `PASS: 9 / FAIL: 0 / TOTAL: 9`、特に TC-07 `Verification is documented as advisory/non-blocking` が PASS 継続
- [ ] TC-A4: Full suite per-test regression (non-lossy) — Given: baseline pre-captured @ main 84bb571 (`/tmp/eval-4-baseline.txt`、10 件 rc=1、95 件 rc=0) / When: 変更後の `for f in tests/test-*.sh; do bash "$f" >/dev/null 2>&1; rc=$?; printf "%s rc=%d\n" "$(basename $f)" "$rc"; done | sort` を baseline と diff / Then: 差分は 1 行のみ (`test-codex-delegation-interface.sh rc=1 → rc=0`)、他 9 pre-existing FAIL は不変、95 件 PASS も不変
- [ ] TC-A5: mirror 整合 — Given: steps-codex.md L90 / steps-teams.md L185 を同じ表現に更新 / When: 両行テキスト比較 / Then: 本文完全一致
- [ ] TC-A6: semantic bridge 保持 — Given: 変更後 / When: `grep -n 'reference.md#product-verification' skills/orchestrate/steps-codex.md skills/orchestrate/steps-teams.md` / Then: 両ファイルに cross-link が残存 (読者が '参考エビデンス' の formal definition '`advisory evidence`' を reference.md で辿れる)

### WIP
(none)

### DISCOVERED
- **eval-3 cycle doc frontmatter incomplete**: `docs/cycles/20260421_2342_agents-md-count-fix.md` が `cycle`/`created`/`updated` フィールド欠損で `test-directory-structure.sh` TC-DS03 が FAIL (3 件)。eval-3 時に見逃し。eval-5 以降 or follow-up で解消。
- **Pre-existing FAIL 9 件の存在**: main 84bb571 で `test-doc-consistency.sh`, `test-factory-model-adaptation.sh`, `test-japanese-ux-research.sh`, `test-no-verify-guard.sh`, `test-orchestrate-a2b.sh`, `test-plugin-data-paths.sh`, `test-v201-fixes.sh` および上記 `test-directory-structure.sh`, `test-codex-delegation-preference.sh` が rc=1。eval-1〜3 narrative では 5 件と記載されていたが実測 10 件。原因分析・解消は eval-5 以降の候補。
- **test-advisory-terminology.sh の VERIFY-block 精度**: 現在 TC-02/TC-03 はファイル全体を grep、意図上は VERIFY セクション限定。将来 'advisory evidence' が別セクションに導入された場合に false-negative の可能性。`awk`/`sed` で VERIFY セクションを slice して grep する案を将来強化候補とする (Codex code review round 1 WARN、非ブロッキング)。

### DONE
(none)

## Implementation Notes

### Goal
`tests/test-codex-delegation-interface.sh` TC-09 の pre-existing FAIL を解消する。TC-09 は `steps-codex.md` が 'advisory'（case-insensitive）を含まないことを要求しているが、現状 L90 に `advisory evidence` が存在し FAIL している。

### Background
TC-09 は Codex 委譲関係における historical ban-word (`advisory` → `competitive` への transition) を守るためのテスト。しかし `steps-codex.md` L90 の `advisory evidence` は Product Verification の「非ブロッキング evidence」という別文脈での使用であり、意図は全く異なる。テスト仕様を変更するのではなく、eval-1/2/3 pattern（源を test に合わせる）に従い、steps-codex.md および mirror 関係の steps-teams.md の表記を日本語表現 (`参考エビデンス`) に変更する。

### Design Approach (Revised after Codex plan review round 1)
- 置換は純粋な用語レベル変更のみ (semantic 保存、reference.md の formal definition に bridge)
- **reference.md は不変** — `test-product-verify.sh` TC-07 契約対象のため
- **SKILL.md も不変** — reference.md の契約用語と doc-reference 一貫性維持
- **mirror 関係の steps-codex.md / steps-teams.md の 2 ファイルのみ変更** (Codex 推奨 "codex/teams mirror まで")
- 代替案 A (1行のみ) は mirror 不一致、代替案 C (全 orchestrate ファイル) は TC-07 regression、代替案 D (TC-09 relax) は憲法違反リスクで不採用

## Verification

```bash
# 1. TC-09 解消確認
bash tests/test-codex-delegation-interface.sh 2>&1 | grep -E 'TC-09|Summary'
# 期待: TC-09 PASS / Summary: PASS: 18 / FAIL: 0 / TOTAL: 18

# 2. TC-07 回帰防止確認 (reference.md 不変が効いていること)
bash tests/test-product-verify.sh 2>&1 | grep -E 'TC-07|Summary'
# 期待: TC-07 PASS / Summary: PASS: 9 / FAIL: 0 / TOTAL: 9

# 3. Full suite per-test 回帰確認 (non-lossy)
for f in tests/test-*.sh; do
  bash "$f" >/dev/null 2>&1
  printf "%s rc=%d\n" "$(basename $f)" "$?"
done
# 期待: baseline (main @ 84bb571) と比較し、test-codex-delegation-interface.sh のみ rc 1 → 0 に変化、他は同一

# 4. 変更対象ファイルから 'advisory' 除去確認
grep -n -i 'advisory' skills/orchestrate/steps-codex.md skills/orchestrate/steps-teams.md
# 期待: 出力なし

# 5. reference.md 不変 (契約維持)
grep -c -i 'advisory' skills/orchestrate/reference.md
# 期待: 3 (元々の L435, L443, L464 残存)

# 6. mirror 整合確認
diff <(sed -n '90p' skills/orchestrate/steps-codex.md) <(sed -n '185p' skills/orchestrate/steps-teams.md)
# 期待: 両行完全一致 (差分 0)
```

Evidence: (orchestrate が自動記入)

## plan_review

- **Round 1**: BLOCK (reference.md 変更が TC-07 regression、steps-subagent.md 見逃し、TC-A3 lossy) — 全指摘反映済
- **Round 2**: WARN (baseline 過小申告、TC-A4 git stash unsafe) — baseline 実測と TC-A4 修正で受容判断
- **Codex session**: 019db29f-ab0e-7632-a181-e52b68ce33ac
- **Final verdict**: PASS (WARN は受容、Option B (steps-codex.md + steps-teams.md mirror) 採用)

## Progress Log

### 2026-04-22 09:37 - KICKOFF
- Cycle doc created from plan: `/Users/morodomi/.claude/plans/eval-4-eval-3-crystalline-snowflake.md`
- Design Review Gate: PASS (score: 5)
  - Scope: 4 files / 7 lines, YAGNI violation なし (score: 0)
  - Architecture: CONSTITUTION違反なし、Codex委譲関係への影響なし (score: 0)
  - Test List: TC-A1〜A5, Given/When/Then 全カテゴリ網羅 (score: 0)
  - Risk: score 10 と変更内容（純粋doc置換・semantic保存）が整合 (score: 5)
  - Alternative A/B/C の棄却理由が論理的
- Scope definition ready
- Phase completed

### 2026-04-22 09:50 - CODEX_PLAN_REVIEW_R1 → BLOCK
- Codex plan review round 1 verdict: **BLOCK**
- 指摘 1: `test-product-verify.sh` TC-07 が `reference.md` の `'advisory'` + `'non-blocking'` 両方存在を要求 → 当初 plan の reference.md 変更は TC-07 regression を引き起こす
- 指摘 2: `steps-subagent.md` L146/L150 にも 'advisory' 残存 → consistency goal に対して当初 scope 不整合
- 指摘 3: TC-A3 verification が `tail -30` で lossy、全 per-test 結果を捕捉できない
- Codex 推奨: scope を "steps-codex.md only, or at most codex/teams mirror" に縮小、reference.md 不変、per-test regression check 明示化

### 2026-04-22 09:55 - PLAN_REVISED
- Plan file 改訂: scope 4 files/7 lines → **2 files/2 lines** (steps-codex.md + steps-teams.md mirror)
- reference.md / SKILL.md / steps-subagent.md は Out of Scope に明示移動
- Test List 改訂: TC-A1〜A6 (6 項目), TC-A3 は test-product-verify.sh 契約維持を独立 TC 化
- TC-A4 は per-test exit code 比較方式に変更 (non-lossy)
- Next: Codex plan review round 2

### 2026-04-22 10:08 - CODEX_PLAN_REVIEW_R2 → WARN
- Codex plan review round 2 verdict: **WARN** (Round 1 BLOCK 全 3 件解消 + 軽微 2 件指摘)
- 指摘 1: baseline 過小申告 (`test-directory-structure.sh` も FAIL、eval-3 cycle doc frontmatter 欠損が原因)
- 指摘 2: TC-A4 の `git stash` 例が unsafe
- Approved: scope 2 files/2 lines, test-product-verify.sh 契約維持、semantic bridge

### 2026-04-22 10:18 - BASELINE_CAPTURED + PLAN_FINALIZED
- Baseline 実測 (`/tmp/eval-4-baseline.txt` @ main 84bb571): **10 件 rc=1** (pre-existing FAIL), 95 件 rc=0
- Codex round 2 の指摘 1 が更に拡張: eval-1〜3 narrative の「5 件」は実測と不整合、実際は 10 件
- TC-A4 更新: baseline diff 方式に統一、`git stash` 例削除
- DISCOVERED に 9 件 pre-existing FAIL 詳細記録 (eval-5 以降の候補)
- Plan/Cycle doc finalized、Codex round 2 WARN は軽微につき受容
- Next: Block 2a (RED)

### 2026-04-22 10:25 - RED
- 新規 test script: `tests/test-advisory-terminology.sh` (4 TCs: TC-01 advisory 除去, TC-02 mirror, TC-03 semantic bridge, TC-04 TC-07 契約維持)
- 実行結果: PASS 3 / FAIL 1 (TC-01 FAIL) — RED 状態確立
- Phase completed

### 2026-04-22 10:30 - GREEN
- 変更: `steps-codex.md` L90、`steps-teams.md` L185 の `advisory evidence、委譲不要` → `参考エビデンス、委譲不要` (green-worker 委譲)
- 追加発見: 新規 test script 追加により `test-v2-release.sh` TC-04 が FAIL (STATUS.md test count 105 vs actual 106)
- 対応: `docs/STATUS.md` L12-14 を `Test Scripts: 106` + `Last updated: 2026-04-22` に更新 (直接) → test-v2-release.sh PASS 復活
- Verification: target test PASS 4/4, TC-09 テスト PASS 18/18, test-product-verify.sh PASS 9/9
- Baseline diff: `test-codex-delegation-interface.sh` rc=1→0 (期待通り), 他 9 件 pre-existing FAIL 不変, 他 95 件 PASS 不変
- Phase completed

### 2026-04-22 10:35 - REFACTOR
- 対象: `tests/test-advisory-terminology.sh` (新規 test script)
- 適用: DRY — VERIFY_LINE_PATTERN / PV_CROSSLINK を定数化 (grep パターンの 2 箇所重複を解消)
- Source code (steps-codex.md / steps-teams.md / STATUS.md) は doc 変更のみで追加リファクタ不要
- Verification Gate: target test PASS 4/4, test-codex-delegation-interface.sh PASS 18/18, test-product-verify.sh PASS 9/9, test-v2-release.sh PASS 8/8
- Phase completed

### 2026-04-22 10:50 - REVIEW (competitive)
- Risk Classifier: LOW (score 25)
- Claude-side reviewers:
  - correctness-reviewer: blocking_score 12 (PASS)、2 optional: TC-02 grep -c の空文字 edge case、TC-01 steps-teams coverage 欠落
  - security-reviewer: blocking_score 3 (PASS)、1 optional: TC-02 grep -c 可読性改善
- Codex code review (session 019db29f-ab0e-7632-a181-e52b68ce33ac): **WARN**
  - 主要指摘: TC-02/TC-03 がファイル全体を grep、VERIFY セクション限定ではない (test-precision gap)
  - 非ブロッキング、Codex 自身が "not a new blocker" と明記
  - Tests 実測結果: test-advisory-terminology.sh 4/4, test-codex-delegation-interface.sh 18/18, test-product-verify.sh 9/9, test-v2-release.sh 8/8 (並行確認)
- Accept 判断:
  - TC-01 steps-teams coverage 追加 (3 reviewer 共通指摘、2 行追加で invariant 強化): **ACCEPT・適用**
  - TC-02 grep -c edge case: 現実に影響なし、将来パターン変化時にのみ顕在化: **DEFER** (DISCOVERED 記録)
  - VERIFY-block slicing: architectural 強化で scope 越える、将来候補: **DEFER** (DISCOVERED 記録)
- 修正後 target test 再実行: 4/4 PASS 維持
- Aggregate verdict: **PASS** (全 reviewer blocking_score < 50、Codex WARN は軽微、主要指摘 1 件は適用済)
- Phase completed

---

## Next Steps

1. [Done] KICKOFF
2. [Done] RED
3. [Done] GREEN
4. [Done] REFACTOR
5. [Done] REVIEW
6. [Next] COMMIT
7. [ ] DONE

## Retrospective

抽出時刻: 2026-04-22 11:02
抽出方法: Cycle doc 全体 (plan review rounds / phase summaries / reviewer findings / DISCOVERED) からの失敗→最終解→insight ペア抽出

### Insight 1: Doc 変更 scope 決定時、「テスト契約」の逆向き依存を grep で先行検索する

- **Failure**: 当初 plan は orchestrate スキル 4 ファイル (reference.md 含む) で 'advisory' を一括置換する Option B を採用。Codex plan review round 1 で **BLOCK**。理由は `test-product-verify.sh` TC-07 が `reference.md` に 'advisory' が **含まれること** を契約として要求しており、置換により逆方向の regression を発生させる。
- **Final fix**: scope を 2 files/2 lines (steps-codex.md + steps-teams.md mirror) に縮小、reference.md を明示的に Out of Scope に移動し、TC-07 契約維持の DAG を plan/Cycle doc に記録。
- **Insight**: 「ファイル内の特定文字列を除去」する前に、その文字列の **存在を前提とする** テスト (`grep -qi`, `grep -q`) が他ファイルにないかを `grep -rn "grep .*'<target>'" tests/` で先行検索する。用語統一を主張する plan は、逆向きテストとの契約衝突を必ずチェックする。TC-A3 のような "invariant preservation" TC をデフォルトで plan に含める。
- **一般化**: "source を test に合わせる" pattern (eval-1/2/3 の成功 pattern) は万能ではない。複数テストが **互いに排他的な不変条件** を課している場合は、scope 最小化が先に来る。

### Insight 2: Baseline は narrative ではなく実測で取る

- **Failure**: 前 session の narrative 「pre-existing FAIL 5 件中 3 件解消」を鵜呑みにした初期 plan。Codex round 2 で `test-directory-structure.sh` も FAIL と指摘され、実測すると **pre-existing FAIL は 10 件** (narrative の 2 倍) と判明。
- **Final fix**: `for f in tests/test-*.sh; do bash "$f" >/dev/null 2>&1; rc=$?; printf "%s rc=%d\n" "$(basename $f)" "$rc"; done | sort > /tmp/eval-4-baseline.txt` で main @ 84bb571 の baseline を実測、10 件を DISCOVERED に記録。
- **Insight**: 「前 cycle の narrative 情報」は記憶が短期化された後のレポートであり、現状と乖離する。cycle 開始時の Block 0 で必ず baseline を実測し、retrospective 末尾に「残 pre-existing FAIL 一覧」を appendix として記録する運用を新規検討。
- **一般化**: narrative > 実測 は常に疑う。Codex の "not taking on faith" スタンスが正しかった。Claude 側は「信頼されているファクト」として扱ってしまいがち。

### Insight 3: `$?` 捕捉は即 `rc=$?` に格納する (subshell 展開前に消える)

- **Failure**: 最初の baseline capture で `bash "$f" >/dev/null 2>&1; printf "%s rc=%d\n" "$(basename $f)" "$?"` とした結果、**全テストが rc=0 と偽報告** された。`$(basename $f)` が先に評価され、その exit code (0) が `$?` を上書きしていた。
- **Final fix**: `bash "$f" >/dev/null 2>&1; rc=$?; printf "%s rc=%d\n" "$(basename $f)" "$rc"` と rc を即座に変数に格納。
- **Insight**: `$?` を `printf`/`echo` に渡す場合、他の subshell 展開が引数リストに混ざる瞬間に上書きされる。**実行直後の次の文で必ず `rc=$?` として変数捕捉する** ことを rule-of-thumb とする。特に for-loop + printf は典型的な落とし穴。
- **一般化**: bash の `$?` は glossy な global 変数で寿命が極端に短い。`pipefail`/`errexit` + 即時キャプチャの組み合わせが堅牢。

### Insight 4: 新規 test script 追加は meta-test (test count 等) に波及する

- **Failure**: GREEN phase で `tests/test-advisory-terminology.sh` を新規追加すると、`test-v2-release.sh` TC-04 が FAIL (STATUS.md 宣言 105 vs 実測 106)。予期せぬ regression として判明。
- **Final fix**: `docs/STATUS.md` の `Test Scripts: 105` を 106 に更新、`Last updated` を同日に bump。scope 外だが必須 collateral として cycle 内で処理。
- **Insight**: test script 追加は `docs/STATUS.md` (test count)、README.md (もし言及) のような meta-doc に同期が必要。plan 時点で "新規 test file 追加 → STATUS.md 更新も scope に含む" を checklist 化する。eval-3 の AGENTS.md agent count 整合と同じ pattern (count declaration のドリフト防止)。
- **一般化**: "count を宣言する doc" は実体変更のたびに同期が必要。類似 meta-doc を `grep -rl "Test Scripts\|Agents\|Skills" docs/` で洗い出して sync-doc 一覧を作る価値あり (将来 skill 化候補)。

### Insight 5: Codex WARN は軽微でも「適用可能な強化」を切り出して反映する

- **Failure**: Review phase で Codex が `test-advisory-terminology.sh` TC-01 の steps-teams.md coverage 欠落を指摘 (WARN)。放置すれば将来 steps-teams.md のみ drift した場合に invariant が破れるリスク。
- **Final fix**: TC-01 に `grep -qi 'advisory' "$STEPS_TEAMS"` チェックを追加 (2 行、scope 内の invariant 強化と判断)。VERIFY-block slicing は architectural 強化として DEFER し DISCOVERED 記録。
- **Insight**: competitive review の WARN は「今すぐ BLOCK ではないが、review findings を 2 カテゴリ分離する」— (a) scope 内 invariant 強化 (2 行レベル → 即適用)、(b) architectural / scope 越え → DISCOVERED 記録 + follow-up。PdM の accept 判断を記録し、将来同様 WARN 処理の template 化。
- **一般化**: review findings は「accept・適用」「accept・defer」「reject」の 3 分岐を明示的に判断・記録する。silent ignore は retrospective 抽出対象を失う。
