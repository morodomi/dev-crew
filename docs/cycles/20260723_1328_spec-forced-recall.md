---
feature: spec-forced-recall
cycle: 20260723_1328
phase: DONE
complexity: standard
test_count: 16
risk_level: medium
retro_status: captured
codex_session_id: "019f8d37-91ba-7551-a0af-70ca0aa356d4"
codex_mode: no
plan_file: /Users/morodomi/.claude/plans/hashed-tickling-honey.md
created: 2026-07-23 13:29
updated: 2026-07-23 15:37
---

# spec-time forced recall of related cycle docs

## Scope Definition

### In Scope
- [ ] scripts/recall-candidates.sh を新規作成し、共変更 + トレーラー優先の決定論的候補生成を実装する
- [ ] skills/spec/SKILL.md に Step 7.2: Forced Recall を追加（L83/L95 圧縮で 2 行捻出、<100 行維持）
- [ ] skills/spec/reference.md + reference.ja.md に `## Forced Recall {#forced-recall}` セクションと Plan File Template への `## Recall` ブロックを追加
- [ ] agents/sync-plan.md の転記テーブルに Recall 行を追加
- [ ] skills/spec/templates/cycle.md に転記先 `## Recall` セクションを追加
- [ ] tests/test-recall-candidates.sh を新規作成（fixture git repo による script 契約 + doc 契約）
- [ ] docs/STATUS.md の Test Scripts 114→115 同期
- [ ] tests/test-codify-insight.sh TC-19 の 114→115 同期（regex + echo + `has_scripts114`→`has_scripts115` rename + bump 履歴コメント）
- [ ] CHANGELOG.md [Unreleased] Added 追記

### Out of Scope
- R4 集計スクリプト（想起採否の機械集計） (Reason: 計測期間終了時に実装予定、本 cycle は data 蓄積の基盤のみ)
- Plan File Template への `## Files to Change` ブロック正式化 (Reason: 現行慣行 [agent-prompts rule の全量列挙] で機能中。R4 計測で入力欠落 miss が出たら再評価)
- rules 降格棚卸し（cycle-scoped → 想起層） (Reason: R4 完了後に実施、v2.14 からの継続 DISCOVERED)

### Files to Change（全量 10 件。追加・削除禁止 — architect の ≤10 制約ちょうど、余白ゼロ。GREEN/REFACTOR で collateral fix が発生した場合は scope +1 の即時 SSOT 記録 + REVIEW 裁定で処理する — design review WARN の事前明記）
- scripts/recall-candidates.sh (new)
- skills/spec/SKILL.md (edit)
- skills/spec/reference.md (edit)
- skills/spec/reference.ja.md (edit)
- agents/sync-plan.md (edit)
- skills/spec/templates/cycle.md (edit)
- tests/test-recall-candidates.sh (new)
- docs/STATUS.md (edit)
- tests/test-codify-insight.sh (edit)
- CHANGELOG.md (edit)

**scope 同梱注記**: docs/cycles/20260723_1103_cycle-doc-trailer-and-recall-miss-question.md — orchestrate Block 0 codify gate 出力（retro_status: resolved + Codify Decisions 追記、2026-07-23 13:28）。本 cycle commit に同梱する（内容編集はしない）。

## Environment

### Scope
- Layer: Plugin 全体（doc/bash プロジェクトのため Backend/Frontend 区分は非該当）
- Plugin: bash + markdown（テストは tests/test-*.sh）
- Risk: 30 (WARN — spec ワークフローへのステップ追加 + 新規 script。security/external/DB 該当なし)

### Runtime
- Language: bash 3.2.57, git 2.49.0

### Dependencies (key packages)
- なし（shell テストのみ）

### Risk Interview (BLOCK only)
- 該当なし（Risk 30 = WARN。BLOCK ではないため Risk Interview 不要）

## Context & Dependencies

### Reference Documents
- docs/cycles/20260723_1103_cycle-doc-trailer-and-recall-miss-question.md - R1 トレーラー + R3 想起漏れ設問の先行 cycle（PR #190）。本 cycle はその上に spec-time forced recall 本体を構築する
- 要求仕様書（2026-07-17、issue #187） - データソース制約（既存のみ・frontmatter 拡張なし・SQLite/embeddings なし）、助言者形式原則、提示件数・除外なしの原則の出典
- rules/integration-verification.md - real-path invocation 契約（本 cycle の Verification section の設計根拠）
- rules/multi-file-consistency.md - 順序検証・deterministic gate の設計根拠（recall-candidates.sh の awk 集計・hash 境界設計）
- rules/doc-mutations.md - hash 境界（`## Recall` を Plan Review Record より前に配置する順序制約の根拠）

### Dependent Features
- spec skill (Step 8: Codex plan review): Forced Recall はこの直前（Step 7.2）に発火し、想起結果が plan review の検査対象になる
- sync-plan agent: `## Recall` の転記テーブル行追加を必要とする
- pre-red-gate.sh: hash 境界の正準アルゴリズムが `## Recall` の配置位置を規定する

### Related Issues/PRs
- Issue #187: R2 ロードマップ（ユーザー決定 2026-07-22）に従う本体実装

## Test List

### TODO
(none — all items transitioned to WIP in RED)

注記: fixture git repo は mktemp -d + trap EXIT + `git -C` init + GIT_AUTHOR_*/GIT_COMMITTER_* 環境固定（決定論）で構築する。前例なし（新規パターン導入、`grep -rln "git init" tests/ scripts/` 0 件）。doc 契約（TC-D1〜D3）は見出し区間先行抽出で検査し、whole-file grep は禁止。

### WIP
(none — all 16 transitioned to DONE in GREEN)

### DISCOVERED
- R4 集計スクリプト（10 サイクル分の Recall 採否 + 想起漏れ回答の機械集計）: 計測期間終了時に実装。データは本 cycle の `## Recall`（plan→cycle doc 転記、hash 保護）+ 想起漏れ回答（二段回収契約済み）で蓄積される
- Plan File Template への `## Files to Change` ブロック正式化（探索で指摘された gap — recall の入力アンカーが慣行依存）: 現行慣行（agent-prompts rule による全量列挙）で機能しているため見送り。R4 計測で入力欠落 miss が出たら再評価
- rules 降格棚卸し（cycle-scoped → 想起層）: R4 完了後（v2.14 からの継続）

### DONE
- [x] TC-S1（トレーラー優先）
- [x] TC-S2（共変更 fallback）
- [x] TC-S3（ハブ減衰）
- [x] TC-S4（recency tie-break）
- [x] TC-S5（0 件 + exit code）
- [x] TC-S6（現存しない doc の除外報告）
- [x] TC-S7（冪等）
- [x] TC-S8（上位 N 制限 + TSV 形式）
- [x] TC-S9（正本変更ゼロ）
- [x] TC-S10（archive 解決）
- [x] TC-S11（ペア重複排除）
- [x] TC-D1（spec 統合）
- [x] TC-D2（reference 両言語）
- [x] TC-D3（転記配線）
- [x] TC-R1（回帰: post-approve-ordering proxy）
- [x] TC-R2（回帰: ja Template proxy）

## Implementation Notes

### Goal
spec フェーズの固定点に「変更予定ファイルに関連する過去 cycle doc の自動提示」を注入する。pull 型検索（問い合わせ待ち）を廃し、ワークフロー固定点で必ず発火させる構造にすることで、想起を記憶力の問題から構造の問題に変える。

### Background
強制想起（issue #187、要求仕様書 2026-07-17）の本体。先行 cycle（20260723_1103、PR #190）で R1 トレーラーと R3 想起漏れ設問が稼働済み。本 cycle はその上に spec-time forced recall 本体を構築する。

設計の中心（要求仕様書 + 事前議論で確定済み）:
- データソースは既存のもののみ: `git log --name-only`（共変更）+ Cycle-Doc トレーラー（R1、確定リンク優先）+ 既存 cycle doc。frontmatter 拡張・SQLite・embeddings は使わない
- ハブファイル重み付けは必須（2026-07-21 実測: STATUS.md は 49 cycle doc、orchestrate SKILL は 33 に共変更リンク vs 葉ファイル 4-6。重み付けなしでは「常に直近 5 サイクル」に縮退する）
- 発火点は spec の Files to Change 確定後・Step 8（Codex plan review）前。想起結果が plan に入ることで「当時の前提が今回も成立するか」自体が plan review の検査対象になる
- 提示は助言者形式 3 点セット（何が起きたか / 当時の前提 / 今回も同じ前提か）、上位 5 件程度・新しい順優先・該当なしも 1 行明示（沈黙しない）
- 提示結果は plan の独立セクションに記録 — R4 の行動基準「参照が plan 本文に残存」の計測はこれを grep する
- 正本（cycle doc・コード）変更ゼロ / 常駐プロセスなし / 冪等

#### Ambiguity Resolution（事前議論で確定済み）
- 候補生成は決定論 script（テスト可能）、助言者形式 3 点セットの要約のみ LLM（spec 実行時に上位候補の cycle doc を読む）
- ハブ重み付けの方式: ファイル F の寄与 = 1 / (F に共変更リンクする cycle doc 数)（IDF 相当。除外でなく重み — 仕様原則「導出構造は miss 実測まで追加しない」「古いものも除外しない」と整合）
- トレーラーリンクは共変更推定より高優先（確定来歴）。過去 348 コミット（トレーラーなし）は共変更推定でカバー
- spec SKILL.md は 99 行のため、ステップ追加は圧縮とセット（圧縮対象は探索で確定）

#### Baseline 実測（2026-07-23、Explore agents 2 体）
- spec SKILL.md = 99 行。TC-R4（tests/test-post-approve-ordering.sh:154-170）が Step 8 見出し存在 + `<100` 行を厳密 pin → ステップ追加は圧縮とセットが必須。圧縮対象確定: L83（Step 7.1 の憲法 doc 列挙 → reference.md#constitution-check に既存、重複） + L95（Step 8 の resume フラグ注記 → reference.md:13 と verbatim 重複、既存アンカーあり）で計 ~2 行捻出
- hash 境界の確認: 正準 hash = `## Plan Review Record` 行より前の全内容（scripts/gates/pre-red-gate.sh:274-284）。`## Recall` を Record より前（Plan File Template の TDD Context 後、reference.md:536-538 間）に置けば hash 領域内 = 承認後改変から保護され R4 計測が信頼できる。必然の順序制約: Recall は Step 8 実行前に書き終える（Step 8 後の追記は reviewed_plan_hash を無効化し pre-red-gate BLOCK）
- sync-plan は固定転記テーブル（agents/sync-plan.md:56-64）— `## Recall` は自動転記されない。テーブル行追加 + templates/cycle.md へ転記先セクション追加が必要
- reference.ja.md（519 行）は準ミラー — Step 8 / Plan File Template を含み lockstep 更新必須（tests/test-spec-onboard-improvements.sh TC-02 が ja の Template を pin）
- fixture git repo のテスト前例ゼロ（`grep -rln "git init" tests/ scripts/` 0 件）→ 新規パターン導入: mktemp + `git -C "$TMPREPO" init` + GIT_AUTHOR_*/GIT_COMMITTER_* 環境固定（決定論）。script は `git -C "$ROOT"` 経由設計にする（root 注入でテスト可能に。前例: tests/test-doc-consistency.sh:156 の rc 明示捕捉付き `git -C`）
- trailer 抽出構文の動作実証（git 2.49.0）: `git log --format='%H%x09%(trailers:key=Cycle-Doc,valueonly)'` が single-pass・TSV 直行・トレーラー不在は空文字列。現在トレーラー付きコミット 1 件（0446aac）を実測確認
- 性能実測: 354 コミット・73 cycle docs で full-history name-only スキャン 0.229s → spec 所要時間への影響は無視可能（受入 7-3 充足）
- SIGPIPE 契約（pre-red-gate.sh:57-63）: `git log | grep -q` 禁止。変数捕捉 + herestring or `git log | awk`（awk は最後まで読む）に統一。bash 3.2: declare -A / mapfile 禁止 → 集計は awk 連想配列（SUBSEP 複合キー、前例 scripts/tfidf-summary.sh:85-131。sqrt/log も awk で可）
- count 逆向き契約（grep literal）: docs/STATUS.md:12 `| Test Scripts | 114 |` + tests/test-codify-insight.sh TC-19（`has_scripts114` regex）の 2 箇所を 114→115 同期。scripts/ のファイル数 pin は存在しない（test-plugin-structure は下限のみ）→ 新規 script 追加は非破壊
- 関連スイート baseline: 直近 full suite 114/114 rc=0（cycle 20260723_1103 REFACTOR Gate 実測）

### Design Approach

1. **scripts/recall-candidates.sh（新規・決定論）**
   - 引数: `recall-candidates.sh <project_root> <file>...`（root 注入でテスト可能）。`-n <N>` で上位件数（既定 5）
   - 規約: `#!/bin/bash` + `set -euo pipefail`、エラー様式 `ERROR:`/stderr、exit 0=正常（0 件でも正常）、1=引数/環境エラー（scripts/ 既存規約準拠）
   - ロジック（awk 1 パス集計、SUBSEP 複合キー）:
     - (a) `git -C "$ROOT" log --format='C%x09%H%x09%(trailers:key=Cycle-Doc,valueonly)' --name-only` を単一実行で走査
     - (b) コミットにトレーラーあり → そのコミットの cycle doc リンクはトレーラー値のみ（確定来歴、共変更 doc は無視）。従サイクルのリンク喪失は仕様と整合済み（cycle 20260723_1103 で確定した「主サイクル 1 件のみ」トレーラー仕様の継承であり新規逸脱ではない — design review INFO で結論確定）
     - (c) トレーラーなし → 同一コミット内の docs/cycles/*.md を共変更リンクとする
     - (d) 入力ファイル F ごとの寄与 = 1 / (F のリンク先 distinct cycle doc 数)（ハブ減衰。IDF 相当、除外はしない）を候補 doc に合算。実効性は実データで検証済み（design review 実測: docs/STATUS.md は 74 コミット・57 distinct doc にリンク、内訳 count=1×31 / count=2×25 / count=3×1 — 単一ハブ入力でも count>1 の doc が直近サイクルより上位に出るため recency 縮退は起きない）
     - (e) 順位: score 降順 → 同点は新しい cycle（ファイル名の YYYYMMDD_HHMM 降順）
     - (f) 履歴上のリンク先 `docs/cycles/<basename>.md` は `docs/cycles/<basename>.md` → `docs/cycles/archive/<basename>.md` の順で現在パスに解決する（archive には 37 doc が現存・可読 — Codex Finding 1。仕様「古いものも除外しない」の遵守）。両方に存在しない場合のみ除外し、除外件数を stderr に 1 行報告（no silent caps）。出力パスは解決後の現在パス
     - (f2) スコアリングは unique (入力ファイル F, cycle doc) ペア集合の上で行う（Codex Finding 2）: 同一ペアが複数コミットに出現しても寄与は 1 回のみ。分母（F のリンク先 distinct doc 数）もペア集合から算出 — 頻繁編集 doc の過大評価を防ぐ
     - (g) 出力: TSV `score\t<resolved-cycle-doc-path>`（archive 解決後の現在パス）上位 N 件。0 件時は stdout 空 + exit 0（提示側が「関連なし」を記録）
2. **spec への統合（Step 7.2、hash 順序制約準拠）**
   - SKILL.md: L83/L95 圧縮で 2 行捻出し、Step 7.1 の直後に Step 5.5 型 2-3 行の Step 7.2: Forced Recall を追加:「Files to Change 確定後・Step 8 の前に `scripts/recall-candidates.sh . <files...>` を実行し、上位候補を助言者形式で plan の `## Recall` に記録する。詳細: reference.md#forced-recall」。TC-R4 の `<100` を維持
   - reference.md + reference.ja.md: `## Forced Recall {#forced-recall}` セクション新設 — script 実行方法、上位候補の cycle doc の読み方（Retrospective / Codify Decisions / DISCOVERED 中心）、助言者形式 3 点セットの記録形式（各候補につき `### docs/cycles/<file>` + `- **何が起きたか**` / `- **当時の前提**` / `- **今回も同じ前提か**` の 3 行）、0 件時は「関連する過去サイクルなし」1 行、命令形で書かない（助言者原則 — 過剰保守化の防止）。Plan File Template（en:514-557 / ja:455-501 の両方）の TDD Context 後・Plan Review Record 前に `## Recall` ブロックを追加
3. **plan → Cycle doc 転記**: agents/sync-plan.md の転記テーブル（L58-64）に `| Recall | ## Recall（関連過去サイクル・助言者形式） |` 行を追加。skills/spec/templates/cycle.md に転記先 `## Recall` セクションを追加（test-frontmatter-retro-status TC-02 の negative pin は `## Retrospective` placeholder のみが対象で非抵触 — RED で確認）
4. **テスト（tests/test-recall-candidates.sh 新規）**: fixture git repo（mktemp -d + trap EXIT + `git -C` init + GIT_AUTHOR_*/GIT_COMMITTER_* 固定）による script 契約 + doc 契約（上記 Test List 参照）

## Verification

Real-path invocation を最低 1 件含めること (rules/integration-verification.md)。

```bash
# 契約テスト（本 cycle の主対象）
bash tests/test-recall-candidates.sh
bash tests/test-post-approve-ordering.sh
bash tests/test-spec-onboard-improvements.sh
bash tests/test-pre-red-gate.sh
bash tests/test-codify-insight.sh
# real-path invocation（integration-verification 準拠）: 実履歴への実行。
# 既知の確定リンク: skills/commit/reference.md はトレーラー付きコミット 0446aac で
# docs/cycles/20260723_1103_...md とリンク済み → 1 位に来ることを実測
bash scripts/recall-candidates.sh . skills/commit/reference.md | head -5
bash scripts/recall-candidates.sh . skills/commit/reference.md | head -1 | grep -c "20260723_1103"
# ハブ減衰の実挙動: docs/STATUS.md（49 doc リンクのハブ）単独入力で直近 5 cycle への縮退が
# 起きないこと（上位に低頻度リンクの doc が混ざる）を目視確認し evidence 保存
bash scripts/recall-candidates.sh . docs/STATUS.md | head -5
# 正本変更ゼロの実 repo 検証: script 実行前後で working tree が不変
git status --porcelain > /tmp/recall-before.txt && bash scripts/recall-candidates.sh . skills/commit/reference.md > /dev/null && git status --porcelain > /tmp/recall-after.txt && diff /tmp/recall-before.txt /tmp/recall-after.txt && echo "TREE UNCHANGED"
# full suite（Block 0 baseline は隔離 snapshot 上で実測。fail counter で集約 — 最終 exit が失敗を伝搬）
fails=0; for f in tests/test-*.sh; do bash "$f" >/dev/null 2>&1; rc=$?; echo "$f rc=$rc"; [ "$rc" -ne 0 ] && fails=$((fails+1)); done; echo "FAILS=$fails"; [ "$fails" -eq 0 ]
```

Evidence: (orchestrate が自動記入)

## Progress Log

### 2026-07-23 13:29 - Plan Review (pre-approval)
- codex_session_id: 019f8d37-91ba-7551-a0af-70ca0aa356d4
- review_attempts:
  - {started: 2026-07-23 13:24, completed: 2026-07-23 13:25, verdict: BLOCK}
  - {started: 2026-07-23 13:25, completed: 2026-07-23 13:26, verdict: PASS}
- findings 要約: Claude design review（Step 7、blocking_score 30）: WARN 2（scope 10/10 余白ゼロの明記 / 正本変更ゼロの直接テスト欠如 → TC-S9 + Verification 追加）+ INFO 2（トレーラー従サイクル整合の結論明記 / ハブ減衰の実データ検証記録）→ 全反映。Codex attempt 1 (BLOCK 3件): (1)[High] archive 済み 37 doc の誤除外 — 仕様「古いもの除外なし」と矛盾 → 二段パス解決 + TC-S10 (2)[Medium] (F,doc) ペア重複排除の未定義 → unique ペア集合上のスコアリング + TC-S11 (3)[Low] full suite loop の exit 伝搬 → fail counter 集約。全反映。Codex attempt 2: PASS（3 件解消確認。非ブロッキング表記 1 点 — 出力形式の resolved-path 表記 — も反映済み）
- unresolved_blocks: なし（attempt 2 で PASS。表記修正は非ブロッキング指摘の反映であり設計・テスト契約の変更なし）
- plan_presented: 2026-07-23 13:26
- reviewed_plan_hash: b54cd78c0466055b4abe06545dac7b0a4cdcfe92f76fc08ecf5c591b267a8e88
- verdict: PASS
- Phase completed

### 2026-07-23 13:29 - KICKOFF
- Cycle doc created
- Scope definition ready
- Phase completed

### 2026-07-23 13:34 - Architect (Design Review Gate + Post-Transfer Verification)
- Design Review Gate: score ~12/100 → **PASS**. Scope 10/10 Files to Change with explicit 余白ゼロ + collateral-fix contingency note; Design Approach (a)-(g) specific and internally consistent; Test List 16 items (TC-S1-S11 + TC-D1-D3 + TC-R1-R2) covers normal/boundary/exception categories in verifiable Given/When/Then form; Risk 30/WARN → risk_level: medium is consistent with change content (new script + workflow step, no security/external/DB)
- 実ファイル突合結果:
  - (a) scripts/recall-candidates.sh・tests/test-recall-candidates.sh とも未存在 — 確認済み（RED 未着手のため期待通り）
  - (b) skills/spec/SKILL.md = 99 行を実測確認。L83（憲法ドキュメント列挙、reference.md:587-597 `#constitution-check` と重複）・L95（resume flag 前置注記、reference.md:13 と重複）を実測確認 — 圧縮対象の主張は正確
  - (c) agents/sync-plan.md 転記テーブル（L58-64）に Recall 行は未存在 — 確認済み（未着手のため期待通り）
  - (d) docs/STATUS.md:12 = `| Test Scripts | 114 |`、tests/test-codify-insight.sh:399 `has_scripts114` regex を実測確認 — count 契約の主張は正確
  - (e) docs/cycles/archive/ に 37 doc 現存・可読（サンプル 3 件 wc -l 実施、非空）。docs/cycles/ と archive/ の basename 重複は 0 件 — 二段パス解決の前提（曖昧衝突なし）は成立
  - (f) Files to Change 10/10（architect ≤10 制約ちょうど）、余白ゼロ注記・collateral fix 対応（scope +1 即時記録 + REVIEW 裁定）が事前明記済み — 整合
- Post-Transfer Verification（plan ↔ Cycle doc 突合）:
  - Plan Review Record: codex_session_id / verdict PASS / reviewed_plan_hash / review_attempts（BLOCK→PASS 2 attempts）/ unresolved_blocks なし — 全フィールド転記一致を確認。reviewed_plan_hash は正準アルゴリズム（`awk '$0=="## Plan Review Record"{exit}{print}' <plan> | shasum -a 256`）で再計算し `b54cd78c...` と完全一致（実測、hash 領域整合性は健全）
  - Files to Change 10 件・余白ゼロ注記・scope 同梱注記: plan と Cycle doc で完全一致（verbatim）
  - Test List 16 件（TC-S1〜S11, TC-D1〜D3, TC-R1〜R2）: 全項目 verbatim 一致、test_count: 16 と整合
  - Verification section: bash ブロック内容 verbatim 一致（Cycle doc 側に "Real-path invocation を最低 1 件含めること" の定型注記が先頭に付加されているのみ、テンプレート由来で非問題）
  - DISCOVERED 3 項目: plan と Cycle doc で完全一致
  - 設計方針 (a)-(g): plan Design Approach と Cycle doc Implementation Notes で完全一致
  - 転記欠落: なし / scope 実質変更: なし
  - 観察のみ（DISCOVERED 追記不要、記録のみ）: 「scope 同梱注記」（docs/cycles/20260723_1103_....md を本 cycle commit に同梱）は plan 本文に verbatim ソースがなく、sync-plan が Block 0 の運用文脈（同 doc の retro_status: resolved・Codify Decisions 追記・git status M を実測確認済み、事実関係は正確）から補記したものと判断。設計・テスト契約・Files to Change に変更を及ぼさないため「観察のみ」に分類し、再承認は不要と判断
- 判定: **PASS**（BLOCK 0 件、scope 実質変更 0 件）。plan ファイルは未編集（読み取りのみ）。orchestrate は Block 2a（RED）へ進行可
- Phase completed

### 2026-07-23 13:50 - RED
- Test code created, 14 tests failing (RED)。tests/test-recall-candidates.sh 新規作成（16 TC）
- 内訳: TC-S1〜S11（script 契約、fixture git repo）+ TC-D1〜D3（doc 契約、見出し区間先行抽出）は新挙動未実装のため FAIL（14 件）。TC-R1/R2（回帰非破壊 proxy、既存 pin 存在検査）は既存契約が健在のため PASS（2 件）— cycle 20260723_1103 の TC-R1/R2 代替と同型
- fixture: mktemp -d + trap EXIT cleanup + `git -C "$REPO" -c init.defaultBranch=main init` + GIT_AUTHOR_*/GIT_COMMITTER_* 固定 export（決定論）。トレーラー付き/なし・ハブ/葉・archive 移動・重複ペア・除外・該当なしの各シナリオを合成コミットで構築
- script 契約は先頭に `[ -f "$SCRIPT" ]` 存在 guard を置き、scripts/recall-candidates.sh 未存在の現在は「script does not exist」で FAIL
- 契約 literal: TSV `score\t<resolved-cycle-doc-path>`、既定上位 5、archive 二段解決、unique (F,doc) ペア、stderr 除外報告、exit 0=正常。bash 3.2 互換・SIGPIPE 契約遵守（script 出力は変数捕捉、`bash subject | grep` 直結なし）
- oracle 検証: 設計 (a)-(g) の参照実装を fixture に適用し、f1→a1 のみ / f3H+f3L→l3 先頭(score 1) > hub docs(0.333) / f4→new4 先頭(tie recency) / f11→d11 score 1(dedup) / f8→6 候補(script が 5 に cap) / f10→archive パス / f6→stderr 除外・stdout 空 を確認済み（GREEN の実装ターゲット確定）
- 実行結果: `bash tests/test-recall-candidates.sh` → PASS 2 / FAIL 14 / TOTAL 16、rc=1（RED 確認）。他テストは baseline 並行実行中のため未実行（読み取り並列・実行直列）
- Phase completed

### 2026-07-23 14:18 - GREEN
- Implementation complete, all 16 tests passing。scripts/recall-candidates.sh 新規実装 + doc 配線 9 ファイル編集
- scripts/recall-candidates.sh: `set -euo pipefail`、`<project_root> <file>... [-n N]`。git log（Cycle-Doc トレーラー inline + --name-only）を Q 優先行と結合し awk 単一パス集計（`split("",arr)` clear で bash 3.2 互換、SIGPIPE 契約遵守: git log | awk 直結・grep -q 直結なし）。トレーラー優先 / 共変更 fallback / unique (F,doc) ペア寄与 1/distinct / archive 二段パス解決 + stderr 除外報告 / score 降順→basename 降順 tie-break は `sort -k1,1nr -k2,2r` + `awk 'NR<=n'`（head 不使用で SIGPIPE 回避）
- doc 配線: SKILL.md Step 7.2 追加（L83/L95 圧縮 + 4項目リスト inline 化で 99→97 行、<100 維持・Step 8/--sandbox read-only pin 保持）/ reference.md + reference.ja.md に `## Forced Recall {#forced-recall}` + Template `## Recall`（Plan Review Record より前）/ sync-plan.md 転記行 / templates/cycle.md `## Recall`（Retrospective placeholder 不追加）
- count 同期: docs/STATUS.md 114→115 + test-codify-insight.sh TC-19（has_scripts114→has_scripts115 rename + bump 履歴 1 行）。test-orchestrate-a2b TC-15（動的 count 契約）で 115=実数 115 を確認
- 検証: bash tests/test-recall-candidates.sh 16/16 PASS rc=0。回帰 test-post-approve-ordering / test-spec-onboard-improvements / test-pre-red-gate / test-codify-insight / test-post-approve-action / test-spec-upstream / test-orchestrate-a2b / test-v2-release 全 rc=0。wc -l SKILL.md=97。real-path: `recall-candidates.sh . skills/commit/reference.md | head -1` → 20260723_1103 が 1 位（tie 内 recency 首位）。read-only: 実行前後で git status --porcelain 不変
- 逆向き契約 sweep: `grep -rln "114" tests/` の残存は test-codify-insight.sh の bump 履歴コメントのみ（live assertion なし）
- Phase completed

---

## Next Steps

1. [Done] KICKOFF <- Current
2. [Next] RED
3. [ ] GREEN
4. [ ] REFACTOR
5. [ ] REVIEW
6. [ ] COMMIT
7. [ ] DONE

### 2026-07-23 14:29 - REFACTOR

- チェックリスト 7 項目適用: 改善対象ゼロ（scripts/recall-candidates.sh は SIGPIPE 契約・bash 3.2・awk 1 パス集計・二段解決の規約準拠を実読確認。tests/ は REFACTOR 禁止事項により対象外）
- Verification Gate: bash -n lint OK（script + test）+ full suite 115/115 FAILS=0（baseline 114/114 + 新規 1、regression ゼロ）
- baseline 補足: 隔離 snapshot の初回実測で 4 件 FAIL → 単一根本原因（snapshot に Holdings 親 docs/test_architecture.md 未複製 → test-paradigm-selection FAIL → 他 3 件は再帰 cascade）を切り分け、親 docs 補完後に 114/114 FAILS=0 確定（隔離 snapshot の親構造複製 insight の再確認事例）
- Phase completed

### 2026-07-23 15:36 - REVIEW

**Competitive review 構成**: Claude panel 4 名（HIGH tier、risk-classifier score 105）+ Codex（resume 019f8d37）。blocking_score: security 5 / maintainability 8 / correctness 28 / design 78。Codex verdict: BLOCK 1 + WARN 1 + INFO 1。

**Findings Judgment（3-category triage、計 13 件）**:

accept-apply（適用済み 5 件）:
1. [Codex BLOCK / design BLOCK-2 関連] 単一ハブ入力の recency 縮退が設計ノート (d) と reference 両言語の契約文言に矛盾 → **仕様の許容挙動として文書化**（reference.md / reference.ja.md の該当文言を「減衰は入力ファイル間の相対重み。単一ハブのみは同点→新しい順（許容挙動、miss 計測で拡張判断）」へ修正、byte-identical lockstep）+ TC-S3 に lone-hub characterization（同点 + 新しい順）を追加 pin
2. [design BLOCK-1] Step 7.2 の発火位置矛盾（Files to Change 確定前に配置）→ SKILL.md 内で設計フロー行の後・Step 8 直前へ移設し「設計で Files to Change が確定した直後」と明記（97 行維持、TC-D1/TC-R4 PASS）
3. [Codex WARN] TC-S9 が script 失敗時も vacuous PASS → `RECALL_RC == 0` を判定条件に追加
4. [correctness WARN] basename 衝突時の誤帰属（cycles/ と archive/ に同名の別 doc）の暗黙不変条件 → script ヘッダに「basename は両 dir 横断で一意を維持」の invariant を明文化（oracle で再現確認済み・現リポジトリ衝突 0 件実測）
5. [design INFO] GREEN の SKILL.md 圧縮手段逸脱（4 項目リスト 1 行化）→ Codex INFO の裁定通り「plan 記載の 2 箇所では物理行が捻出できず、意味欠落なしの追加圧縮は妥当」として承認記録

**scope 実質変更の再承認（doc-mutations 3 分岐、design BLOCK-2 の監査ギャップ解消）**:
- 対象: plan 設計ノート (d) の「単一ハブ入力でも縮退しない」実データ主張は、Codex plan review Finding 2 が要求した unique (F,doc) ペア契約の帰結として**成立しない**（設計ノートの検証が per-commit 集計前提だった）。plan review PASS の根拠の一部が反転したため scope 実質変更として扱う
- **AskUserQuestion による再承認済み（2026-07-23）**: 「縮退を許容仕様化」を選択。追加スコアリング信号は仕様書 §4 の「miss 実測まで追加しない」原則に従い R4 計測後に判断
- Verification の「縮退が起きないことを目視確認」項目は本裁定により**期待値が反転**: 実測 evidence（/tmp/dev-crew-verify-20260723_1328/product-verification.log の hub query 出力 = 全同点 0.017544・新しい順）は許容仕様の実挙動記録として保存

accept-defer（follow-up、#185 コメント予定 3 件）:
- [correctness INFO] 重複トレーラーの 2 件目 silent drop / core.quotePath 対象ファイル名の silent miss / rename 追跡なし — いずれも本番経路（ASCII 命名・commit スキル単一トレーラー契約）では発火しない低確率エッジ。診断出力の追加は #185 のテスト強度強化と同時に判断
- [maintainability INFO] awk 配列命名ケース不揃い / section helper の 5 実装目（#185 統合対象に追加）
- basename 衝突の runtime guard（ヘッダ文書化より強い防御）

reject（1 件、理由付き）:
- [design WARN 再承認要求のうち「REVIEW 記録欠落」] → reject ではなく本エントリで解消（design review は REVIEW エントリ作成前の中間状態を観察したもの。監査証跡は本エントリ + 再承認記録で完備）

**検証**: 修正後 tests/test-recall-candidates.sh 16/16 rc=0、test-post-approve-ordering / test-spec-onboard-improvements rc=0。security 実測: パス走査は basename-before-concat で構造的に不可能（模範例評価）。correctness oracle 実測: merge commit 経路・sort tie-break・float 決定論（30 回 byte-identical）は全て正しい
- Phase completed

### 2026-07-23 15:36 - DISCOVERED 起票

- REVIEW accept-defer 4 群（recall エッジ診断 / basename runtime guard / helper 統合 5 実装目 / awk 命名）→ issue #185 へ統合コメント
- R4 集計スクリプト・rules 降格棚卸し → 既存 issue #187 で追跡継続（plan DISCOVERED 通り）
- Phase completed

## Retrospective

抽出時刻: 2026-07-23 15:37
抽出方法: Cycle doc 全体（plan review BLOCK→PASS / baseline 誤 FAIL 切り分け / code review 13 findings・再承認 1 件）からの失敗→最終解→insight 抽出

### Insight 1: 設計時の実データ検証は「最終契約の式」で再実行しないと無効になる。中間設計での実測は契約変更で silently 失効する
- **Failure**: 設計ノート (d) の「単一ハブでも縮退しない」は per-commit 集計前提の実データ検証だった。その後 Codex plan review Finding 2 が unique (F,doc) ペア契約を導入し、検証済み主張が**式の変更で失効**したのに、主張のテキストは plan にそのまま残存 → 実装後に design reviewer が矛盾を検出し、scope 実質変更の再承認（AskUserQuestion）まで発展
- **Final fix**: 縮退を許容仕様として再承認 + reference 両言語の契約文言修正 + lone-hub characterization TC で実挙動を pin
- **Insight**: **plan 内の実測ベース主張には「どの式・どの契約バージョンで測ったか」を併記し、レビューで式が変わったら依存する主張を再実測してから残す。式の変更（ペア重複排除等）は、その式で検証済みだった全主張の失効チェックをセットで行う**
- **一般化**: rules/plan-discipline.md 追記候補（実測主張の前提式併記 + 式変更時の失効 sweep）

### Insight 2: ワークフロー step の挿入位置は「前提が成立する時点」を doc の実行順で検証する。見出し番号の隣接ではなく前提の充足順で置く
- **Failure**: Step 7.2 を「Step 7.1 の直後」という見出し隣接で配置した結果、前提（Files to Change 確定）が成立する設計フローより前に置かれ、doc の実行順に読むと前提未成立で発火する構造矛盾。plan review（Codex PASS）も探索エージェントの配置推奨も見逃し、design reviewer が実行順トレースで検出
- **Final fix**: 設計フロー行の後・Step 8 直前へ移設し、発火条件を「設計で Files to Change が確定した直後」と自己記述化
- **Insight**: **手順 doc へ step を挿入する時は、番号や見出しの隣接ではなく「その step の前提条件が直前までに成立しているか」を doc を頭から実行するトレースで検証する。前提条件は step 自身の文中に書く（位置に依存させない）**
- **一般化**: rules/multi-file-consistency.md の順序検証原則（行番号比較）の適用対象を「workflow doc の前提充足順」へ拡張する追記候補

### 想起漏れ

- **設問**: 今回の手戻りは、過去のどの cycle doc を最初に読んでいれば防げたか
- **回答**: 該当なし

### 2026-07-23 15:37 - COMMIT

- pre-commit-gate（明示指定）rc=0 PASS
- EXPECTED_CYCLE_DOC 捕捉済み（commit 前）: docs/cycles/20260723_1328_spec-forced-recall.md
- STATUS.md: Done 73→74 + Completed 行（Test Scripts 115 は GREEN 同期済み、Last updated 2026-07-23 前 cycle 同期済み）
- commit 同梱: scripts 1 + skills/spec 4 + agents/sync-plan.md + tests 2 + docs/STATUS.md + CHANGELOG.md + 本 cycle doc + docs/cycles/20260723_1103（Block 0 codify 出力、REVIEW 裁定済み）
- Phase completed
