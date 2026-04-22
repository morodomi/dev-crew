---
feature: codify-insight
cycle: cycle-b-codify-insight
phase: REVIEW
complexity: standard
test_count: 20
risk_level: medium
retro_status: resolved
codex_session_id: "019db316-9c2c-74f0-b32d-0b7d92de9e17"
created: 2026-04-22 11:46
updated: 2026-04-22 14:00
---

# Cycle B: codify-insight skill 新設 (ROADMAP Step 1b)

## Scope Definition

### In Scope (Revised after Codex plan review round 1: 15 files)
- [ ] `skills/codify-insight/SKILL.md` 新設 (< 100 lines)
- [ ] `skills/codify-insight/reference.md` 新設
- [ ] `tests/test-codify-insight.sh` 新設 (20 TCs)
- [ ] `rules/state-ownership.md` — codify-insight 行追加 (retro_status captured→resolved + updated + body `## Codify Decisions` section append)
- [ ] `skills/orchestrate/SKILL.md` Block 0 — codify gate pre-check (frontmatter-only scan)
- [ ] `skills/orchestrate/reference.md` — Block 0 pre-check 詳細
- [ ] **`skills/orchestrate/steps-subagent.md` Block 0 — mirror update** (Round 1 WARN #1 反映)
- [ ] **`skills/orchestrate/steps-teams.md` Block 0 — mirror update** (Round 1 WARN #1 反映)
- [ ] **`tests/test-cycle-retrospective.sh` TC-14 — Skills 31→32 bump** (Round 1 BLOCK #2 反映)
- [ ] `ROADMAP.md` L33 — 未着手 → 完了
- [ ] `docs/STATUS.md` — Skills 31→32, Test Scripts 106→107
- [ ] `README.md` — Skills list + `31 skills` → `32 skills`
- [ ] `CLAUDE.md` — Skill list に codify-insight 追加
- [ ] `AGENTS.md` — Skills セクション追加
- [ ] `docs/workflow.md` + `docs/architecture.md` — codify-insight 説明追加

### Out of Scope
- 23 accumulated insights の実処理 (smoke-test レベルのみ — 未検証 skill で本番処理はリスク)
- `codify now` 選択時の自動 rule/skill 追記 (MVP は判定記録のみ — ADR-002 L86 準拠)
- 新 gate script 作成 (codify-insight は soft skill、hard gate ではない)
- pre-commit-gate.sh 拡張

### Files to Change (Revised after Round 1: 15 files — new 3, modified 12)

**New**:
- `skills/codify-insight/SKILL.md` (new)
- `skills/codify-insight/reference.md` (new)
- `tests/test-codify-insight.sh` (new)

**Modified**:
- `rules/state-ownership.md` (edit)
- `skills/orchestrate/SKILL.md` (edit — Block 0 codify gate)
- `skills/orchestrate/reference.md` (edit — Block 0 pre-check 詳細)
- `skills/orchestrate/steps-subagent.md` (edit — Block 0 mirror) **[Round 1 WARN #1]**
- `skills/orchestrate/steps-teams.md` (edit — Block 0 mirror) **[Round 1 WARN #1]**
- `tests/test-cycle-retrospective.sh` (edit — TC-14 bump 31→32) **[Round 1 BLOCK #2]**
- `ROADMAP.md` (edit)
- `docs/STATUS.md` (edit — Skills 31→32, tests 106→107)
- `README.md` (edit — `31 skills` → `32 skills`)
- `CLAUDE.md` (edit)
- `AGENTS.md` (edit)
- `docs/workflow.md` (edit)
- `docs/architecture.md` (edit)

## Environment

### Scope
- Layer: Plugin structure (shell scripts + markdown)
- Plugin: dev-crew (skill authoring)
- Risk: 50 (WARN 上限、Round 1 改訂後)

### Runtime
- Language: bash (test scripts), Markdown (skill files)

### Dependencies (key packages)
- cycle-retrospective: precedent mirror pattern
- ADR-002: source of truth (docs/decisions/adr-cycle-retrospective.md L77-91)
- state-ownership.md: frontmatter mutation 権限管理

### Risk Interview
- Risk type: Multi-file orchestration integration
- orchestrate Block 0 invasive change: Block 0に captured scan step追加 → 既存TDDサイクル進行を壊さない保証必要
- Markdown parsing fuzziness: insight delimiter contract を reference.md に明記して mitigate
- Timestamp ownership: codify-insight は標準 mutator として retro_status + updated を所有 (Round 2 WARN #2 反映、例外カーブ不要)
- orchestrate SKILL.md 行数境界: 現行97行 → Block 0追加で ~100行境界、TC-02で自動検出

## Context & Dependencies

### Reference Documents
- `docs/decisions/adr-cycle-retrospective.md` L77-86 — Step 1b 仕様 (source of truth)
- `docs/decisions/adr-cycle-retrospective.md` L30-33 — state model + rejected insight 非自動送り
- `docs/decisions/adr-cycle-retrospective.md` L88-91 — 学びゼロケース
- `skills/cycle-retrospective/SKILL.md` — precedent (mirror pattern)
- `tests/test-cycle-retrospective.sh` — test precedent (15 TC 構成)
- `rules/state-ownership.md` — frontmatter mutation 権限

### Dependent Features
- cycle-retrospective (Step 1): retro_status: captured を生成する上流
- orchestrate Block 0: codify-insight の auto-invoke 統合先

### Related Issues/PRs
- ROADMAP Step 1b (v2.7 Agile Loop)
- ADR-002 (accepted, 2026-04-20)

## Design Decisions (Revised after Codex plan review round 1)

### Annotation format — `## Codify Decisions` 末尾セクション方式 (Round 1 BLOCK #3 反映)

既存 `## Retrospective` セクションは **一切変更しない** (APPEND-ONLY 遵守)。Cycle doc EOF に新セクション `## Codify Decisions` を append:

```markdown
## Codify Decisions

### Insight 1
- **Decision**: codified
- **Destination**: rule
- **Reason**: (optional)
- **Decided**: 2026-04-22 12:34

### Insight 2
- **Decision**: deferred
- **Reason**: 別 cycle で実装予定 (required for deferred)
- **Decided**: 2026-04-22 12:35
```

per-insight inline annotation (元案) は insight 2 件以上で middle-insert 発生し APPEND-ONLY 違反 → 却下。

### Idempotency contract
`## Codify Decisions` セクション内の `### Insight N` heading 存在 = 該当 insight 判定済み。`retro_status: resolved` 遷移は全 insight 判定完了時のみ (partial では captured 維持、再起動で残分のみ処理)。

### Fixed decision markers (TC-13 契約化)
- `codified` / `deferred` / `no-codify` (変更・言い換え禁止)

### `codified` marker MVP 意味論 (Round 2 WARN #1 反映)

ADR-002 L81 は `codify now` を「即時 ast-grep / CLAUDE.md / skill に書き出し、または codify 用の新 cycle を起票」と定義するが、本 MVP 実装では **user が codify-now 判断と destination を記録するのみ**、実際の書き出しは follow-up 作業に委ねる (ADR-002 L86「codify 実行は強制しない」との整合)。

MVP 範囲での `codified` marker 意味:
- user が「この insight は codify すると決めた」ことを明示判断として記録
- destination (rule / skill / instinct / new-cycle / inline-update) を明記して作業方向を固定
- 実際のコード書き出しは user が follow-up cycle で実施 (orchestrate の新 cycle 起票 or 手動 edit)

将来 step 1c (または別 cycle) で「codify now 選択時の自動書き出し」を追加する際、marker の語義を変えず範囲を拡張する方針。

### Frontmatter-only scan (Round 1 BLOCK #1 反映)
whole-file grep は body-text self-trigger 発生 (本 plan/cycle doc でも `retro_status: captured` を本文引用)。必ず frontmatter のみ抽出:
```bash
for f in docs/cycles/*.md; do
  awk '/^---$/{c++;next} c==1{print}' "$f" | grep -q 'retro_status: captured' && echo "$f"
done
```
既存 precedent: steps-subagent.md L31 (`phase: DONE` の frontmatter-only scan)。

### Timestamp/state ownership (Round 1 WARN #2 反映)
codify-insight は frontmatter `retro_status` (captured → resolved) + `updated` 所有。body `## Codify Decisions` セクション append (標準 mutator pattern)。`Decided` は body audit trail、ADR-002 L36「timestamp は orchestrate のみが書く」は frontmatter timestamp (created/updated) 限定と解釈。

### Orchestrate Block 0 integration (3 files mirror — Round 1 WARN #1 反映)
`orchestrate/SKILL.md` + `steps-subagent.md` + `steps-teams.md` 各 Block 0 の先頭に step 0 追加。steps-codex.md は delegate (既存フローと同一) のため不変。

### Failure modes (ADR L30-33 準拠)
- `retro_status: none` cycle → skip
- `retro_status: resolved` cycle → skip (idempotent)
- `retro_status: captured` だが `## Retrospective` 空 → data integrity warning + skip
- User mid-gate abort (Ctrl-C) → partial annotations 残す、frontmatter 遷移なし、次回 re-run で残 insight のみ処理
- 複数 cycles が captured → filename sort order (chronological) で順次処理
- rejected insight → instinct/learn/evolve に自動送りしない (ADR-002 L33, L49)

## Test List

### TODO (20 TCs, Revised after Codex round 1)
- [ ] TC-01: SKILL.md frontmatter valid (validate-yaml-frontmatter.sh PASS)
- [ ] TC-02: SKILL.md line count ≤ 100 (hard limit)
- [ ] TC-03: allowed-tools に Read, Edit, AskUserQuestion, Glob 全含
- [ ] TC-04: description に codify-insight/codify/decide gate trigger 含
- [ ] **TC-05 (Round 1 BLOCK #1, Round 2 WARN #2 強化): frontmatter-only scan positive + negative** — SKILL.md workflow が `awk '/^---$/{c++;next} c==1{print}'` pattern を含む (positive) AND bare `grep -l 'retro_status: captured'` / `grep -rl 'retro_status: captured'` は含まない (negative)
- [ ] TC-06: reference.md に 3-option `codify now`/`defer with reason`/`no-codify` verbatim
- [ ] TC-07: reference.md に defer=reason 必須、no-codify=任意 の記述
- [ ] TC-08: SKILL.md に resolved/none 双方の skip 挙動明記
- [ ] TC-09: reference.md に "no captured cycles found → no-op exit 0" 記述
- [ ] **TC-10 (Round 1 BLOCK #3): `## Codify Decisions` 末尾セクション方式** — reference.md が per-insight inline ではなく EOF 新セクション append と記述
- [ ] TC-11: reference.md に APPEND-ONLY 明記 (既存 Retrospective 不変、Codify Decisions は EOF 新セクション)
- [ ] TC-12: reference.md に captured→resolved 遷移トリガが「全 insight 判断完了時」
- [ ] TC-13: reference.md に `codified`/`deferred`/`no-codify` 3 canonical 文字列契約
- [ ] TC-14: `rules/state-ownership.md` に codify-insight 行 (retro_status + updated + `## Codify Decisions` body append)
- [ ] TC-15: `orchestrate/SKILL.md` Block 0 に codify gate + frontmatter-only scan
- [ ] **TC-16 (Round 1 WARN #1, Round 2 WARN #2 強化): `steps-subagent.md` Block 0 mirror positive + negative** — codify gate pre-check + awk pattern 存在 (positive) AND bare `grep -l 'retro_status: captured'` 不在 (negative)
- [ ] **TC-17 (Round 1 WARN #1, Round 2 WARN #2 強化): `steps-teams.md` Block 0 mirror positive + negative** — 同上
- [ ] TC-18: README/CLAUDE/AGENTS/STATUS 全 4 files で grep 'codify-insight' マッチ
- [ ] TC-19: STATUS.md `Skills | 32` AND `Test Scripts | 107`、README `32 skills`
- [ ] **TC-20 (Round 1 BLOCK #2): `tests/test-cycle-retrospective.sh` TC-14 bump 31→32**

### WIP
(none)

### DISCOVERED
- **insight 列挙仕様不明**: codify-insight SKILL.md は `## Retrospective` から insight を列挙する方法を明示していない。correctness reviewer 指摘、実装 agent が `### Insight N` heading で count するのが暗黙標準だが spec 化は別 cycle で。
- **AskUserQuestion option → marker mapping 未文書化**: `codify now` → `codified` 等の変換規則が reference.md に未記述。correctness reviewer 指摘、実装時は trivial だが docs で明示すれば誤解防止。
- **scan pattern の共有化**: frontmatter-only awk パターンが 5 箇所に重複 (maintainability reviewer)、`phase: DONE` scan と合わせ `scripts/scan-cycle-frontmatter.sh <field> <value>` 抽出候補。Step 1c (auto-codify) 導入時の先行 refactor 適任。
- **awk edge case (security reviewer)**: frontmatter 内に `---` を含む YAML block scalar で誤 skip の理論リスク。現 frontmatter は単純 key:value のみで実害なし、将来対応候補。

### DONE
(none)

## Verification

```bash
cd /Users/morodomi/Projects/MorodomiHoldings/agents/dev-crew

# 1. 新 test script PASS (20 TCs after Round 1 revision)
bash tests/test-codify-insight.sh 2>&1 | tail -5
# 期待: PASS: 20 / FAIL: 0 / TOTAL: 20

# 2. cycle-retrospective test 回帰なし (TC-14 bump 31→32 適用後)
bash tests/test-cycle-retrospective.sh 2>&1 | tail -3
# 期待: PASS: 15 / FAIL: 0 / TOTAL: 15

# 3. test-v2-release.sh counts sync
bash tests/test-v2-release.sh 2>&1 | tail -3
# 期待: PASS: 8 / FAIL: 0 / TOTAL: 8

# 4. frontmatter-only scan 効果確認 (self-trigger 防止)
for f in docs/cycles/20260422_1146_codify-insight-skill.md; do
  awk '/^---$/{c++;next} c==1{print}' "$f" | grep -q 'retro_status: captured' && echo "FALSE POSITIVE: $f"
done
# 期待: 出力なし (本 doc frontmatter は retro_status: none、body 引用は除外される)

# 5. Full suite per-test 回帰 (non-lossy)
for f in tests/test-*.sh; do
  bash "$f" >/dev/null 2>&1
  rc=$?
  printf "%s rc=%d\n" "$(basename $f)" "$rc"
done | sort > /tmp/cycle-b-after.txt
diff /tmp/cycle-b-baseline.txt /tmp/cycle-b-after.txt
# 期待: test-codify-insight.sh rc=0 1 行追加、9 既存 FAIL 不変、95 PASS 不変

# 6. test-review-plan-gate.sh (frontmatter-only contract) 維持
bash tests/test-review-plan-gate.sh 2>&1 | tail -3
# 期待: rc=0 不変

# 7. orchestrate/SKILL.md 100行境界
wc -l skills/orchestrate/SKILL.md
# 期待: ≤ 100
```

Evidence: (orchestrate が自動記入)

## plan_review

- **Rounds**: 4 (Round 1 BLOCK → Round 2 BLOCK → Round 3 BLOCK → Round 4 WARN accepted)
- **Critical fixes applied**: frontmatter-only scan (BLOCK #1), test-cycle-retrospective.sh TC-14 bump (BLOCK #2), `## Codify Decisions` EOF append 方式 (BLOCK #3), steps-*.md mirror scope (WARN #1), timestamp ownership 明文化 (WARN #2), `codified` MVP 意味論 (Round 2 WARN #1), TC-05/16/17 symmetric 化 (Round 2 WARN #2)
- **Scope evolution**: 12 files/17 TCs/Risk 45 → 15 files/20 TCs/Risk 50
- **Final verdict**: PASS (Round 4 WARN accepted per eval-4 insight #5 triage rule)
- **Codex session**: 019db316-9c2c-74f0-b32d-0b7d92de9e17
- **SSOT**: Cycle doc (plan file frozen post-Round 1 per state-ownership.md IMMUTABLE convention)

## Progress Log

### 2026-04-22 11:46 - KICKOFF
- Cycle doc created from plan file `/Users/morodomi/.claude/plans/eval-4-eval-3-crystalline-snowflake.md`
- Design Review Gate: PASS (score: 10) — Files 12 > 10 (+5), orchestrate 行数境界 97→100 (+5)
- Scope definition ready
- Phase completed

### 2026-04-22 11:55 - CODEX_PLAN_REVIEW_R1 → BLOCK
- Codex plan review round 1 verdict: **BLOCK** (3 critical + 2 WARN)
- BLOCK #1: Block 0 pre-check が whole-file grep → 本 plan/cycle doc body に `retro_status: captured` 引用があり self-trigger、frontmatter-only 必須
- BLOCK #2: test-cycle-retrospective.sh TC-14 が `Skills | 31` を hardcode、STATUS.md 31→32 で regression。scope 追加必須
- BLOCK #3: per-insight inline annotation は APPEND-ONLY 違反 (insight 2 件以上で middle-insert)。`## Codify Decisions` 末尾セクション方式に再設計必須
- WARN #1: steps-subagent.md / steps-teams.md の Block 0 mirror 更新欠落 (A2b で学んだ pattern)
- WARN #2: timestamp ownership の `updated` 所有が未明記

### 2026-04-22 12:05 - PLAN_REVISED
- Plan file 改訂: scope 12 → 15 files, test count 17 → 20 TCs, risk 45 → 50
- Annotation 方式: per-insight inline → `## Codify Decisions` 末尾セクション append (APPEND-ONLY 遵守)
- Scan: whole-file grep → frontmatter-only awk 抽出 (steps-subagent.md L31 precedent 流用)
- scope 追加 3 files: tests/test-cycle-retrospective.sh, steps-subagent.md, steps-teams.md
- Test List 追加 3 TCs: TC-05 (frontmatter-only), TC-16/17 (steps-*.md mirror), TC-10 再設計 (Codify Decisions), TC-20 (test bump)
- timestamp ownership 明文化: codify-insight は retro_status + updated + body section append (標準 mutator pattern)
- Next: Codex plan review round 2

### 2026-04-22 12:20 - CODEX_PLAN_REVIEW_R2 → BLOCK
- Codex plan review round 2 verdict: **BLOCK** (1 BLOCK + 2 WARN)
- BLOCK: Cycle doc が partial update、Files to Change / Risk / Verification block が plan file と不整合。Round 2 が古い contract を review する状態
- WARN #1: `codified` marker 意味論が ADR-002 L81 と不整合 — MVP は判定記録のみだが ADR は「即時書き出し」を含意
- WARN #2: TC-05 は negative assertion 含むが TC-16/17 は positive のみで asymmetric

### 2026-04-22 12:25 - CYCLE_DOC_FULLY_SYNCED
- Cycle doc Files to Change: 12 → 15 files 更新
- Risk: 45 → 50 更新
- Verification block: 17-test expectations → 20-test expectations 更新
- TC-05/16/17 に negative assertion 追加で symmetric 化
- Design Decisions に `codified` marker MVP 意味論 section 追加 (ADR-002 との範囲差を明示)
- Next: Codex plan review round 3

### 2026-04-22 12:35 - CODEX_PLAN_REVIEW_R3 → BLOCK
- Codex plan review round 3 verdict: **BLOCK** (2 BLOCK + 1 WARN)
- BLOCK: plan file が cycle doc と drift。TC-05/16/17 negative assertion と `codified` MVP semantics が plan file に未反映
- WARN: cycle doc L82 "Timestamp ownership 例外" 古い語 (既に更新 `標準 mutator` だが Codex 検出時に未反映と誤認?)

### 2026-04-22 12:42 - PLAN_FILE_SYNCED + SSOT_DECLARED
- plan file TC-05/16/17 に positive + negative assertion 追加
- plan file Design Decisions に `codified` MVP 意味論 section 追加
- cycle doc L82 確認: `Timestamp ownership: codify-insight は標準 mutator として...` に更新済 (Edit は Round 2 時点で完了、Codex Round 3 が stale cache 参照の可能性)
- Going forward: **cycle doc を single source of truth** として固定。plan file は initial approval 時点 + Round 1 critical fix 時点で freeze (state-ownership.md L7-10 IMMUTABLE convention 遵守)

### 2026-04-22 12:45 - CODEX_PLAN_REVIEW_R4 → WARN
- Codex plan review round 4 verdict: **WARN** (1 WARN のみ)
- WARN: cycle doc L82 "Timestamp ownership" 記述を stale と判定 (実際は「例外」→「標準 mutator」に修正済、Codex の perception 問題と判断)
- 残 BLOCK なし、Round 3 の plan/cycle sync 完了
- Accept 判断: eval-4 insight #5 (WARN 2-category triage) に基づき scope-irrelevant nitpick として accept、Round 5 追跡せず
- Codex session ID: 019db316-9c2c-74f0-b32d-0b7d92de9e17

### 2026-04-22 12:48 - PLAN_REVIEW_COMPLETE
- Round 1 BLOCK: 3 critical issues → 全解消 (frontmatter-only / APPEND-ONLY / test-cycle-retrospective.sh bump)
- Round 2 BLOCK + WARN: cycle doc partial update + codified semantics + TC asymmetry → 全解消
- Round 3 BLOCK: plan/cycle drift → 全解消 (plan freeze + cycle SSOT 宣言)
- Round 4 WARN: 軽微 perception issue → accept
- Total 4 rounds、scope 12→15 files、TCs 17→20 (eval-4 の 2 rounds より厚い、複雑設計 + ADR 整合で妥当)
- plan_review 完了、Block 2a (RED) へ進行

### 2026-04-22 13:02 - RED
- `tests/test-codify-insight.sh` 新規作成 (20 TCs, cycle-retrospective precedent mirror)
- 実行結果: PASS 0 / FAIL 22 (TC-18 が 4 sub-assertions 含むため TOTAL 22 表示、論理 20 TCs 全 FAIL)
- TC-18 STATUS.md only 偶発的 PASS (cycle doc が 'codify-insight' を含むため)
- RED 状態確認済
- Phase completed

### 2026-04-22 13:10 - GREEN
- 15 files 変更 (new 3 + modified 12):
  - new: `skills/codify-insight/SKILL.md` (68 行), `reference.md`, `tests/test-codify-insight.sh`
  - modified: orchestrate/SKILL.md (92 行), steps-subagent/teams.md Block 0, orchestrate/reference.md, state-ownership.md, test-cycle-retrospective.sh (TC-14 bump 31→32), STATUS.md, README.md, CLAUDE.md, AGENTS.md, ROADMAP.md, docs/workflow.md, docs/architecture.md
- Verification: test-codify-insight.sh 20/20, test-cycle-retrospective.sh 15/15, test-v2-release.sh 8/8
- Baseline diff: 新 test 1 行追加のみ、9 pre-existing FAIL 不変、97 PASS 不変 (baseline 106 tests @ 6dfec86 = 97 PASS + 9 FAIL、after 107 tests = 98 PASS + 9 FAIL)、regression 0
- orchestrate/SKILL.md: 97→92 行 (concise 化で hard limit 内、簡潔化により 5 行削減)
- codify-insight/SKILL.md: 68 行 (< 100 hard limit)
- Phase completed

### 2026-04-22 13:25 - REVIEW (competitive)
- Risk Classifier: HIGH (score 115)
- Claude-side reviewers (parallel):
  - correctness-reviewer: blocking_score 28 (PASS)、important x 2: insight 列挙仕様未明記、option→marker mapping 未文書化、optional x 1: TC-20 抽出パターン脆弱性
  - security-reviewer: blocking_score 5 (PASS)、optional x 1: awk YAML block scalar edge case
  - maintainability-reviewer: blocking_score 22 (PASS)、optional x 3: DRY (intentional mirror)、reference.md Block 0 冗長、SKILL.md L42 inline code 不整合
- Codex code review (session 019db316): **BLOCK** (1 BLOCK + 2 WARN)
  - BLOCK: Block 0 partial-run contract under-specified — codify-insight は partial abort 許容するが orchestrate 側の exit code 契約不在
  - WARN #1: docs/workflow.md 図で COMMIT→codify→pre-commit-gate→COMMIT の重複 (AGENTS.md/architecture.md との drift)
  - WARN #2: cycle doc GREEN log の baseline 数値が誤り (95 PASS と記載、実際 97 PASS)
- Accept 判断:
  - BLOCK exit contract: **ACCEPT・適用** — codify-insight SKILL.md に Exit Contract section 追加 (block-or-complete 契約、cycle-retrospective precedent 準拠)、orchestrate SKILL.md Block 0 に exit 0/1 分岐明記
  - WARN #1 workflow diagram: **ACCEPT・適用** — 重複 pre-commit-gate + COMMIT 削除、cycle N → cycle N+1 の transition を明示
  - WARN #2 baseline 数値: **ACCEPT・適用** — GREEN log を「97 PASS」に訂正
  - Claude important 2 件 (insight enum, option→marker mapping): **DEFER** (DISCOVERED 記録、実装時暗黙解釈で動作、spec 化は別 cycle)
  - Other optional: **DEFER** (DISCOVERED 記録)
- 修正後: target test 20/20 維持、SKILL.md 75 行 (< 100)、orchestrate 92 行 (< 100)
- Aggregate verdict: **PASS** (blocking_score 全 < 50、Codex BLOCK 3 件全適用、important はスコープ外 DISCOVERED)
- Phase completed

### 2026-04-22 13:15 - REFACTOR
- チェックリスト評価: 7 項目全て OK
  - 重複コード: scan pattern 4-5 箇所重複あるが Codex round 1 WARN #1 で要求された intentional mirror (state-ownership 準拠) のため維持。scripts/ 抽出は architectural 変更で MVP 範囲外
  - 定数化: Fixed markers 一貫
  - メソッド分割: SKILL.md 68 行 / reference.md section 分割で適切
  - 命名一貫性: codify-insight / Codify Decisions / Decision-Destination-Reason-Decided 全て一貫
- 追加変更なし判定
- Verification Gate: target test 20/20, retrospective 15/15, v2-release 8/8 再確認 PASS
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

抽出時刻: 2026-04-22 13:42
抽出方法: Cycle doc 全体 (4 rounds plan review / RED / GREEN / REFACTOR / REVIEW / DISCOVERED) からの失敗→最終解→insight ペア抽出

### Insight 1: frontmatter state scan は必ず frontmatter のみ抽出せよ

- **Failure**: 当初 plan の Block 0 codify gate を `grep -l 'retro_status: captured' docs/cycles/*.md` で実装提案。Codex Round 1 BLOCK #1 で「本 plan/cycle doc 自身が本文で `retro_status: captured` を複数回引用しており、whole-file grep は self-trigger する」と指摘。
- **Final fix**: `awk '/^---$/{c++;next} c==1{print}' "$f" | grep -q 'retro_status: captured'` で frontmatter のみ抽出。既存 precedent (`skills/orchestrate/steps-subagent.md` L31 の phase: DONE scan) を流用。TC-05 で positive+negative assertion を契約化。
- **Insight**: frontmatter の state 値で cycle を分類するスキャンは**必ず frontmatter のみ parse する**。meta-documenting (docs 自身が例として state 値を引用する) はプロジェクトで一般的で、body match は常に self-trigger する。awk block delimiter counting (`c==1`) パターンを内部標準として採用する。将来 YAML block scalar 内 `---` で破綻する可能性は DISCOVERED 記録。
- **一般化**: "doc state" を "doc body" で grep しない。structural parse を原則とする。

### Insight 2: 逆向き test contract (文字列/数値を固定値で assert するテスト) を事前検索せよ

- **Failure**: Skill 追加で STATUS.md の Skills 数を 31→32 に変更する必要があったが、`tests/test-cycle-retrospective.sh` TC-14 が `Skills | 31` を hardcode していることに気づかず当初 scope に含めなかった。Codex Round 1 BLOCK #2 で指摘。eval-4 insight #1 (逆向き契約 grep) の再発。
- **Final fix**: scope に test-cycle-retrospective.sh 追加、TC-14 を 32 に bump、TC-20 で bump 契約化。
- **Insight**: Count/state を bump する変更の前に必ず `grep -rn "<value>" tests/` で hardcode assertion を検索する。eval-4 insight #1 の手順を formal checklist 化: (1) 変更する固定値を列挙 (Skills=31, test_count=106 等)、(2) 各値について `grep -rn "<value>" tests/` 実行、(3) ヒットしたテストを scope に追加。
- **一般化**: Duplicate information principle — 同じ値を複数箇所で hardcode している状態は brittle。長期的には dynamic assertion (count を実測して比較) への置換候補。今は scope 拡張で対処。

### Insight 3: 既存セクション内の per-item 追記は APPEND-ONLY 違反、独立セクション + 参照で代用する

- **Failure**: 当初 plan で Cycle doc の `## Retrospective` 内の各 `### Insight N` ブロック末尾に Decision/Destination/Reason/Decided の annotation を inline append する設計。Codex Round 1 BLOCK #3 で「insight 2 件以上で Insight 1 annotation が Insight 2 の前への middle-insert になり、state-ownership.md の APPEND-ONLY 違反」と指摘。
- **Final fix**: `## Codify Decisions` 新セクションを Cycle doc EOF に append する方式に再設計。既存 Retrospective は不変、新セクション内で `### Insight N` heading で既存 insight を参照。cycle-retrospective skill 自身の `## Retrospective` EOF append pattern が precedent。
- **Insight**: APPEND-ONLY 制約下で per-item metadata を追加したい時は、**独立した新セクションを EOF に append し、既存 item を heading 名で参照する**。middle-insert は常に禁止。新セクション方式は parse も容易になる副次効果あり (既存セクション不変ゆえ section-level diff が小さい)。
- **一般化**: state-ownership の APPEND-ONLY は structural rule。per-item 追記の誘惑は設計段階で reject し、別セクションでの表現に置換する。

### Insight 4: Plan file は approve 後 IMMUTABLE、Codex review 改訂は Cycle doc のみに反映する

- **Failure**: Codex plan review が 4 rounds に達した原因の半分は「plan file と cycle doc の drift 修正」。Round 1 で BLOCK 受けて plan file を改訂 → Round 2 で cycle doc だけ更新 → Round 3 で drift 指摘 → Round 4 で plan file 再改訂。2 artifacts の同期を繰り返したため rounds が膨張。
- **Final fix**: Round 3 時点で「plan file は `rules/state-ownership.md` L7-10 IMMUTABLE after approve 遵守、Cycle doc を Codex review の single source of truth」と宣言。以降 Cycle doc のみ改訂。
- **Insight**: **Plan approve 後は plan file を絶対に編集しない**。`state-ownership.md` IMMUTABLE 規則を厳守する。Codex plan review の改訂指摘はすべて Cycle doc に反映し、plan file は「approve 時点のスナップショット + Round 1 critical fix のみ」として freeze する (Round 1 BLOCK が critical spec 欠陥だった場合のみ例外、以降は Cycle doc SSOT)。
- **一般化**: 複数 doc に同じ情報を持たせると drift が必ず発生する。SSOT を宣言し、以降は片方向更新を徹底する。drift を検出しやすくする仕組み (test / gate) を用意するのがより堅牢。

### Insight 5: Skill 間 invoke には exit contract を両側に明記する

- **Failure**: codify-insight を orchestrate Block 0 から auto-invoke する設計で、partial abort 時の orchestrate 側挙動が未定義。Codex code review で BLOCK「Block 0 partial-run contract under-specified」。
- **Final fix**: cycle-retrospective precedent (abort → exit 1 + stderr → orchestrate BLOCK) を踏襲、codify-insight SKILL.md に Exit Contract section 明示、orchestrate SKILL.md Block 0 に exit 0/1 分岐明記。両側同時更新。
- **Insight**: Skill が別 skill から invoke される場合、**exit code と副作用 (frontmatter 遷移 etc.) の契約を callee SKILL.md に明記**、**caller 側の対応ロジックも同時更新**。片側だけの仕様記述は atomic-append assumption を暗黙に残し壊れる。Precedent (cycle-retrospective) を常に参照して mirror する。
- **一般化**: Inter-skill protocol は caller/callee 両側が一致必要。新規 skill 作成時の checklist に「exit contract specification + caller integration update」を追加する。

### Insight 6: Risk HIGH (60+) は Claude 3 reviewer + Codex parallel を最低ラインにする

- **Failure**: 本 cycle の Risk Classifier は HIGH (score 115)、eval-4 は LOW (25)。同じ review pipeline を適用すると HIGH cycle では architectural findings を見落とす (eval-4 が correctness + security のみで済んだのは scope が小さかったため)。
- **Final fix**: Claude 3 reviewer (correctness + security + maintainability) + Codex を並行実行。maintainability-reviewer が DRY (5 箇所重複)、SKILL.md/reference.md 分離妥当性、Fowler code smells を独立に評価し、correctness/security と視点がかぶらず有効だった。
- **Insight**: **Risk score が reviewer 数/種別を決定する**。LOW (0-30): security + correctness + Codex (3 views)。MEDIUM (30-60): + maintainability。HIGH (60+): + architectural/design-reviewer 候補。Score 115 は eval-4 (25) の 4.6 倍、review 厚みも比例 scale で OK。Findings triage も HIGH では 3 categories (accept-apply / accept-defer / reject) 必須。
- **一般化**: Risk-based scaling を review pipeline に明示 default として組み込む。今は ad-hoc 判断、将来 review skill 自体に「HIGH なら maintainability を自動追加」ロジックを入れると良い (Step 1c 以降の候補)。

## Codify Decisions

### Insight 1: frontmatter state scan は必ず frontmatter のみ抽出せよ
- **Decision**: codified
- **Destination**: rule
- **Reason**: "doc state は doc body で grep しない、awk c==1 frontmatter-only parse を内部標準" rule
- **Decided**: 2026-04-22 14:00

### Insight 2: 逆向き test contract (文字列/数値を固定値で assert するテスト) を事前検索せよ
- **Decision**: codified
- **Destination**: rule
- **Reason**: eval-4 #1 と統合、同じ rule document で canonical 記述
- **Decided**: 2026-04-22 14:00

### Insight 3: 既存セクション内の per-item 追記は APPEND-ONLY 違反、独立セクション + 参照で代用する
- **Decision**: codified
- **Destination**: rule
- **Reason**: "APPEND-ONLY 制約下で per-item metadata 追加は独立セクション + heading 参照で代用" rule
- **Decided**: 2026-04-22 14:00

### Insight 4: Plan file は approve 後 IMMUTABLE、Codex review 改訂は Cycle doc のみに反映する
- **Decision**: codified
- **Destination**: rule
- **Reason**: "plan approve 後は plan file 絶対編集禁止、SSOT 宣言で片方向更新" rule (state-ownership.md 補強)
- **Decided**: 2026-04-22 14:00

### Insight 5: Skill 間 invoke には exit contract を両側に明記する
- **Decision**: codified
- **Destination**: skill
- **Reason**: skill-maker SKILL.md の checklist に "exit contract specification + caller integration update" 追加 (architectural codification)
- **Decided**: 2026-04-22 14:00

### Insight 6: Risk HIGH (60+) は Claude 3 reviewer + Codex parallel を最低ラインにする
- **Decision**: codified
- **Destination**: skill
- **Reason**: review skill 自体に "Risk-based reviewer scaling (LOW: 2+Codex, MEDIUM: +maintainability, HIGH: +architectural)" 組み込む (将来改修)
- **Decided**: 2026-04-22 14:00
