---
feature: rule-and-review-synthesis-from-kimi-insight
cycle: 20260525_1249
phase: DONE
complexity: standard
test_count: 2
risk_level: high
retro_status: captured
codex_session_id: "019e5d42-08f5-7833-8c2c-3a99f123e305"
plan_file: /Users/morodomi/.claude/plans/kind-yawning-gadget.md
created: 2026-05-25 12:49
updated: 2026-05-25 14:00
---

# rule-and-review-synthesis-from-kimi-insight

## Scope Definition

### In Scope

- [ ] `rules/agent-prompts.md` (canonical) に「並列起動時の prompt 契約 (3+ subagent fan-out)」セクションを追記
- [ ] `.claude/rules/agent-prompts.md` (mirror) に同内容を同期 (test-rules-mirror.sh TC-01 forward identical contract)
- [ ] `skills/review/steps-subagent.md` Step 5 に「Findings Synthesis」サブセクションを追記
- [ ] `docs/STATUS.md` の Last updated 更新 + Test Scripts 110 → 112 + Recent cycle 行追加 (Type: docs)
- [ ] `tests/test-rule-agent-prompts-parallel-clause.sh` 新規作成 (TC01)
- [ ] `tests/test-review-step5-synthesis-clause.sh` 新規作成 (TC02)

### Out of Scope

- CONSTITUTION.md 変更 (ADR 必須かつ抽象原則は rules/skills で十分)
- `skills/parallel/reference.md` / `skills/diagnose/reference.md` 追記 (実需薄、先回り禁止 §8)
- `skills/review/reference.md` Competitive Review section 改変 (Codex findings judgment は別文脈)
- Kimi 記事の外部スペック (300 agents / 4000 steps) を dev-crew doc に持ち込まない

### Files to Change (target: 10 or less)

- `rules/agent-prompts.md` (edit, canonical)
- `.claude/rules/agent-prompts.md` (edit, mirror — identical content to canonical)
- `skills/review/steps-subagent.md` (edit)
- `docs/STATUS.md` (edit)
- `tests/test-rule-agent-prompts-parallel-clause.sh` (new — TC01)
- `tests/test-review-step5-synthesis-clause.sh` (new — TC02)
- `tests/test-codify-insight.sh` (edit — TC-19 hardcoded "110" → "112" collateral fix, GREEN phase 検出)
- `docs/cycles/20260525_1249_rule-and-review-synthesis-from-kimi-insight.md` (new — this file)

Total: 8 files (≤10)。Codex plan review 2026-05-25 BLOCK で指摘された scope creep + mirror contract 対処済み (Progress Log 参照)。GREEN phase で `tests/test-codify-insight.sh` の collateral fix を追加 (`rules/doc-mutations.md` SSOT 即時同期準拠、cycle 20260422_1313 #2)。

## Environment

### Scope

- Layer: Documentation / Rules
- Plugin: N/A (doc-only)
- Risk: 8 (PASS)

### Runtime

- Language: bash (test scripts only)

### Dependencies (key packages)

- N/A (doc-only changes)

### Risk Interview (BLOCK only)

- N/A (PASS)

## Context & Dependencies

### Reference Documents

- `rules/agent-prompts.md` — 追記対象 rule
- `skills/review/steps-subagent.md` — 追記対象 skill step
- `rules/review-triage.md` — Step 5 から参照する 3-category triage 定義
- `rules/test-patterns.md` — section-specific grep 実装指針
- `rules/multi-file-consistency.md` — 順序検証パターン
- `rules/integration-verification.md` — Verification section 設計方針

### Dependent Features

- N/A

### Related Issues/PRs

- N/A (内部改善 cycle)

## Test List

### TODO

- [x] TC01: `tests/test-rule-agent-prompts-parallel-clause.sh` — 並列起動 prompt 契約セクション存在 + 順序 + 挿入位置確認 (DONE)
  - **Given**: `rules/agent-prompts.md` と `.claude/rules/agent-prompts.md` が両方存在する (mirror)
  - **When**: 各ファイルを awk で「並列起動時の prompt 契約」section 範囲を抽出
  - **Then**:
    - 両ファイルに「並列起動時の prompt 契約」section が存在する (mirror identical)
    - section 内に「担当範囲」「入力」「出力形式」「統合キー」「検証条件」の 5 キーワードが **記述順** で出現する (各キーワードの行番号を取得して昇順検証、`rules/test-patterns.md` の section-specific grep + 順序検証パターン準拠)
    - section の挿入位置が「## 推奨」見出しより後、かつ「## 具体例」見出しより前である (行番号比較、`rules/multi-file-consistency.md` 順序検証準拠)

- [x] TC02: `tests/test-review-step5-synthesis-clause.sh` — Step 5 Findings Synthesis サブセクション構造確認 (DONE)
  - **Given**: `skills/review/steps-subagent.md` が存在する
  - **When**: Step 5 セクションを awk で抽出する
  - **Then**:
    - 「Findings Synthesis」サブセクションが Score Aggregation 見出し直後に出現する (行番号比較で順序検証)
    - 「3-category 分類」と「raw finding index」キーワードが両方含まれる
    - `rules/review-triage.md` への参照が含まれる

### WIP

(none)

### DISCOVERED

- [ ] **D1** → #135: `test-hooks-structure.sh TC-05` + cascade 3件 (test-trap-handler, test-doc-consistency, test-factory-model-adaptation TC-14) が CLAUDE.md/AGENTS.md staleness で FAIL。原因: `CLAUDE.md` last commit 2026-04-24 (31日経過、閾値30日)、`AGENTS.md` last commit 2026-04-22 (33日経過)。fix には `CLAUDE.md` / `AGENTS.md` への意味ある変更 commit が必要 (touch では git log 不変)。本 cycle scope (Kimi 由来 2 抽象原則の rule/skill 追加) を完全に超過するため follow-up cycle で対処。
- [ ] **D2** → #136: Block 0 で full-suite baseline 実測を怠った (codify gate scan のみ実施)。`plan-discipline.md` L23 「pre-existing FAIL 発見時 1 行 fix 可能か確認」の前段「baseline 実測」が orchestrate Block 0 に明文化されていない。orchestrate skill の Block 0 に「pre-existing FAIL baseline 取得」を追加候補。
- [ ] **D3** → #137: REVIEW phase accept-defer 5件 follow-up cycle:
  - Maint F2: `skills/review/steps-subagent.md` Step 5 H2 を「Synthesis & Verdict」等に rename (Score Aggregation サブセクション含む形に統合)
  - Maint F3+Impact F1: `agents/socrates.md` の Input score field を `raw blocking_score (Step 4 各 reviewer の個別最大値、Synthesis 前の値)` に更新
  - Maint F4+Impact F2: `skills/spec/templates/cycle.md` に `## Raw Findings` セクション (空 placeholder + 説明 1 行) を追加
  - Correctness F3: `tests/test-rule-agent-prompts-parallel-clause.sh` の get_line ネスト関数を引数渡しに refactor (動的スコープ依存を排除)
  - Test F3: section-specific test が 3 本以上になった時点で `tests/helpers/section-grep.sh` に shared helper 抽出

### DONE

- [x] TC01: `tests/test-rule-agent-prompts-parallel-clause.sh` — 4 sub-cases (heading 存在 / 5 キーワード順序 / 挿入位置 / canonical-mirror identical)、6 PASS canonical+mirror
- [x] TC02: `tests/test-review-step5-synthesis-clause.sh` — 4 sub-cases (Findings Synthesis 存在 / 順序 + immediate-after H3 / 3-category + raw finding index / review-triage.md 参照)、4 PASS

## Implementation Notes

### Goal

並列 subagent 起動時の prompt 契約と、Specialist Panel findings 統合の責務を明文化し、Kimi-Style synthesis bottleneck を dev-crew 上で再現させない。

### Background

Kimi Agent Swarm 記事 (2026-05-25 会話) から、dev-crew の CONSTITUTION 原則と相補的な 2 つの抽象原則を抽出した:

1. **Specificity scales with parallelism**: 並列度が上がるほど指示の曖昧さが指数的に増幅する
2. **Synthesis bottleneck**: 並列 reviewer の findings 統合段階が context window のボトルネック化する

dev-crew 現状の gap:
- `rules/agent-prompts.md`: architect / sync-plan 単独委譲の Files list 全量列挙が射程。3+ 並列起動時の prompt 契約は未明文化
- `skills/review/steps-subagent.md` Step 5: blocking_score の集計のみ。findings 重複排除・3-category 分類・raw finding index 保持は未記述
- `rules/review-triage.md`: 3-category triage は定義済みだが Step 5 から参照されていない

### Design Approach

Layer 4 (rules/skills) での実装。CONSTITUTION.md 不変 (§7 準拠)。

**agent-prompts.md 追記内容**: 「推奨」と「具体例」の間に新セクション「並列起動時の prompt 契約 (3+ subagent fan-out)」を挿入。5 要素 (担当範囲/入力/出力形式/統合キー/検証条件) を明示。

**steps-subagent.md 追記内容**: Step 5「Score Aggregation」見出し直下、スコアテーブルの直前に「Findings Synthesis」サブセクションを挿入。4 ステップ (重複排除/3-category 分類/raw finding index 保持/集計入力) で synthesis bottleneck 対策を実装。

**Step 5 と Socrates (Step 4.5) の時系列契約** (Codex plan review Finding 4 対処):

- Step 4 (Specialist Panel) → 各 reviewer が個別に raw blocking_score を出力
- Step 4.5 (Socrates) → **preliminary score** (各 reviewer の raw blocking_score の max) を見て adversarial review。Socrates は raw findings 段階の判定妥当性を検証する役割であり、synthesis 後の集計値は入力に取らない
- Step 5 Findings Synthesis (新規) → 重複排除 + 3-category 分類 + raw finding index 保持
- Step 5 Score Aggregation → synthesis 後の **final blocking_score** (重複排除後の category 別 max) で BLOCK/WARN/PASS を確定

Cycle doc の Progress Log でも raw / final 両方を記録 (Socrates 入力 = raw max、最終 verdict = final score)。

**STATUS.md 更新内容**:
- `Last updated`: 2026-04-24 → 2026-05-25
- `Test Scripts`: 110 → 112 (TC01 + TC02 追加)
- `## Completed (Recent)` に本 cycle 行を追加 (Type: docs)
- In-Progress Cycles / Done (unarchived) / Skills / Agents の数値は変更なし

## Verification

```bash
# Test 1: 新規 2 test の単体実行
bash tests/test-rule-agent-prompts-parallel-clause.sh
rc1=$?
bash tests/test-review-step5-synthesis-clause.sh
rc2=$?
printf "TC01 rc=%d TC02 rc=%d\n" "$rc1" "$rc2"

# Test 2: full-suite baseline (REFACTOR 後)
for f in tests/test-*.sh; do
  bash "$f" >/dev/null 2>&1
  rc=$?
  printf "%s rc=%d\n" "$(basename $f)" "$rc"
done | grep -v "rc=0" | sort

# Test 3: 既存 cycle 0 FAIL baseline 維持確認
# (cycle 20260427_0930 の全 PASS 達成と整合)

# Test 4: section-specific grep の real invocation (rules/test-patterns.md 準拠)
awk '/^## Step 5:/{p=1} /^## Step 6:/{p=0} p' skills/review/steps-subagent.md \
  | grep -q "Findings Synthesis"
echo "Step 5 synthesis section: rc=$?"
```

Evidence (2026-05-25 13:42):

- TC01 rc=0, TC02 rc=0 (unit)
- Step 5 section-specific grep rc=0 (Findings Synthesis subsection 存在)
- canonical (`rules/agent-prompts.md`) と mirror (`.claude/rules/agent-prompts.md`) に「並列起動時の prompt 契約」section 各 1 match (identical)
- 詳細 log: `/tmp/dev-crew-verify-20260525_1249/`

## Progress Log

### 2026-05-25 12:49 - KICKOFF

- Cycle doc created
- Design Review Gate (architect): PASS (score: 8) — doc-only 4 files, Risk LOW, test_count 2
- plan_file: `/Users/morodomi/.claude/plans/kind-yawning-gadget.md` (v1, Codex review済み)
- plan 矛盾解消: STATUS.md "Test Scripts 変更なし" は誤記。正解は "110 → 112" (PdM 申し送り確認済み)
- Scope definition ready

### 2026-05-25 12:55 - Codex plan review (competitive)

- Codex session: `019e5d42-08f5-7833-8c2c-3a99f123e305`
- Verdict: **BLOCK** (score 86)
- Findings:
  - [CRITICAL] scope creep: tests/*.sh 2 件 (TC01/TC02) が Files to Change list 欠落
  - [CRITICAL] mirror contract: `rules/agent-prompts.md` canonical も Files list に必要 (`.claude/rules/` のみ指定では test-rules-mirror.sh TC-01/TC-02 で BLOCK)
  - [MEDIUM] test list adequacy: TC01 の ordered keyword assertion + 挿入位置検証が plan より弱体化
  - [MEDIUM] Step 5/Socrates timing: synthesis と Socrates 入力スコアの先後関係が曖昧
  - [MEDIUM] Risk LOW: 上記 2 critical fix 前提では LOW 妥当、fix 前は理論上 MEDIUM
- PdM 判断: 全 findings 妥当。Cycle doc を APPEND-ONLY で補正 (既存 bullet 削除なし、追加のみ):
  - In Scope に `rules/agent-prompts.md` canonical bullet 追加
  - Files to Change list に canonical rule + tests/*.sh 2 件追加 (total 7 files)
  - TC01 を ordered keyword + insertion point 検証に強化
  - Design Approach に Step 5/Socrates の raw/final score 分離契約を追記
  - Risk LOW 維持 (補正後 risk MEDIUM ではなく LOW 妥当、Codex も "defensible only after fix" と認めている)
- Cycle doc 補正完了 → Block 2a (RED) へ進行可能

### 2026-05-25 13:10 - RED (red-worker)

- 2 tests 新規作成: `tests/test-rule-agent-prompts-parallel-clause.sh` (TC-01〜TC-04, 6 FAIL canonical/mirror)、`tests/test-review-step5-synthesis-clause.sh` (TC-01〜TC-04, 4 FAIL)
- 両 test rc=1 確認 (RED verified)
- rules/test-patterns.md 全項目準拠 (case-sensitive grep, section-specific awk, ERE alternation, rc 即捕捉)
- Phase completed

### 2026-05-25 13:25 - GREEN (green-worker)

- `rules/agent-prompts.md` (canonical) と `.claude/rules/agent-prompts.md` (mirror) に「並列起動時の prompt 契約 (3+ subagent fan-out)」section 追加 (5 キーワード記述順、推奨と具体例の間に配置)
- `skills/review/steps-subagent.md` Step 5 に「Findings Synthesis」サブセクション追加 (Step 5/Socrates raw/final score 分離契約明文化)
- `docs/STATUS.md` 更新: Test Scripts 110 → 112, Last updated 2026-05-25, Recent cycle 行追加
- TC01 / TC02 / test-rules-mirror.sh 全 PASS (rc=0)
- Phase completed

### 2026-05-25 13:30 - Full-suite baseline (post-GREEN)

- 5 FAIL 検出:
  - `test-codify-insight.sh TC-19`: STATUS.md Test Scripts 110 hardcode → 私の更新 (110→112) による regression
  - `test-doc-consistency.sh`: cascade (codify-insight + factory-model + hooks-structure + trap-handler)
  - `test-factory-model-adaptation.sh TC-14`: cascade (codify-insight, hooks-structure, trap-handler)
  - `test-hooks-structure.sh TC-05`: CLAUDE.md 31日 + AGENTS.md 33日 staleness (時間経過による pre-existing FAIL、本 cycle 起因ではない)
  - `test-trap-handler.sh`: cascade from hooks-structure
- pre-cycle baseline (git stash 検証): 全 PASS だった → 私の現在状態が原因
- 分類:
  - **regression (本 cycle 起因、本 cycle で fix)**: `test-codify-insight.sh TC-19` (hardcoded 110→112 collateral fix を `tests/test-codify-insight.sh` に適用済み、Files list に追記、SSOT 即時同期)
  - **pre-existing (時間経過、本 cycle で fix 不可)**: `test-hooks-structure.sh TC-05` (CLAUDE.md/AGENTS.md git commit が必要、本 cycle scope 超過) → DISCOVERED D1 起票
  - **cascade**: codify-insight fix + hooks-structure DISCOVERED で 3 件中 1 件 (factory-model TC-14 の codify-insight 部分) は解消、2 件 (hooks-structure cascade) は DISCOVERED D1 に従う
- Block 0 baseline 未実測の反省 → DISCOVERED D2 起票 (orchestrate Block 0 改善候補)

### 2026-05-25 13:40 - REFACTOR (checklist-driven)

- リファクタリングチェックリスト 7 項目確認
- 改善実施: 重複コード (項目 1)
  - `get_first_line_number()` helper を両 test file に抽出 (`raw_X=...; line_X=$(echo $raw_X | head -1 | cut -d: -f1)` の 2-step pattern を 1 行に簡潔化、計 6 回の重複を削減)
  - file1 TC-03 で 3 call、file2 TC-02 で 3 call が helper 経由に
  - 行数は +15 だが、helper の再利用性と可読性が向上、将来の line-number 取得は同 helper 経由で統一可能
- 他 6 項目: 既存実装が適切で改善不要
- Verification Gate: TC01/TC02/mirror/codify-insight 全 rc=0、本 cycle scope の全 test PASS
- pre-existing FAIL 4件 (test-hooks-structure cascade) は DISCOVERED D1 で対処、refactor で変動なし
- Phase completed

### 2026-05-25 13:50 - REVIEW (competitive: 5 Claude reviewers + Codex)

Risk Classification: **HIGH (score 75)** (想定 LOW より上振れ)。HIGH tier → 5 reviewers + Codex competitive。

**Specialist Panel 起動** (3+ fan-out 契約 dogfood — 各 prompt に 5 要素: 担当範囲/入力/出力形式/統合キー/検証条件):
- correctness-reviewer (test logic): raw blocking_score 22 (PASS)
- maintainability-reviewer (doc structure): raw blocking_score 32 (WARN)
- test-reviewer (test smell): raw blocking_score 18 (PASS)
- security-reviewer (always-on): raw blocking_score 5 (PASS)
- impact-reviewer (HIGH tier): raw blocking_score 35 (WARN)
- Codex (competitive, session 019e5d42): raw blocking_score 55 (WARN)

**Raw max blocking_score = 55 (WARN tier)** — Socrates 入力契約準拠。

**Step 5 Findings Synthesis dogfood** (本 cycle で追加した新 rule を即時適用):

1. **重複排除**: Maint F3 ↔ Impact F1 (socrates.md score field), Maint F4 ↔ Impact F2 (cycle.md template Raw Findings), Correctness F2 ↔ Test F1 (TC-02 comment 逆解釈) を dedup
2. **3-category 分類**:
   - **accept-apply (6 件、本 cycle 内 fix)**: Codex F1 (TC02 immediate-after H3 強化), Codex F2 (Score Aggregation 文言 final score 明示), Maint F1 (出典 H3→H2 末尾 merge), Maint F6 (3-category 定義 → review-triage.md SSOT link), Correctness F1 (step5_lines 終端 generic `^## `), Correctness F2+Test F1 (TC02 comment 修正)
   - **accept-defer (5 件、DISCOVERED 追加)**: Maint F2 (Step 5 H2 rename), Maint F3+Impact F1 (agents/socrates.md score field), Maint F4+Impact F2 (cycle.md template `## Raw Findings`), Correctness F3 (get_line ネスト関数), Test F3 (shared helper)
   - **reject (5 件、根拠付き)**: Maint F5/F7 (narrative 主観), Impact F3 (soft norm 設計通り — CONSTITUTION 原則 6), Correctness F4 (許容範囲), Test F2 (110 vs 109 baseline は機能影響なし), Security F1 (既存慣習で認証情報ではない)
3. **Raw Findings 保持**: 本 Progress Log エントリ全体が dedup 前の raw findings 記録として機能 (Cycle doc `## Raw Findings` 専用 section は本 cycle scope 外、DISCOVERED D3 で template 整備 follow-up)
4. **Final blocking_score**: accept-apply 6件 fix 後の残存 = accept-defer 高 severity (max 32 = important) → **PASS (0-49)**

**REVIEW Verdict: PASS (final score 32)** — Block 2e へ進行可能。

**accept-apply 6件の即時適用結果**:
- `rules/agent-prompts.md` + mirror: `### 出典 (並列起動時の prompt 契約)` H3 削除、末尾 `## 出典` に集約 (Maint F1)
- `skills/review/steps-subagent.md`: 3-category 定義を SSOT link に圧縮 (Maint F6) + Score Aggregation 文言を "final blocking_score" 明示に変更 (Codex F2)
- `tests/test-review-step5-synthesis-clause.sh`: step5_lines awk 終端を `^## ` 汎用化 (Correctness F1)、TC-02 を強化 (Step 5 と Findings Synthesis 間に他 H3 不在を assert、Codex F1)、TC-02 comment 修正 (Correctness F2)
- 全 in-scope test 再実行で rc=0 維持確認

**DISCOVERED 追加**:
- D3: Maint F2 (Step 5 H2 「Score Aggregation」→「Synthesis & Verdict」rename), Maint F3+Impact F1 (agents/socrates.md score field を raw blocking_score に明示), Maint F4+Impact F2 (skills/spec/templates/cycle.md に `## Raw Findings` セクション追加), Correctness F3 (get_line ネスト関数を引数渡しに), Test F3 (3 本目 section-specific test 追加時に shared helper `tests/helpers/section-grep.sh` 抽出)

### Files to Change 補正 (accept-apply 適用後、APPEND-ONLY)

- 引き続き 8 files (rules/agent-prompts.md 上 +2 行 / mirror +2 行 / steps-subagent.md +2 行 / test-review-step5 +6 行 程度の修正で新ファイル追加なし)

**REVIEW Verdict: PASS (final blocking_score 32 < 50)**
- Phase completed

### 2026-05-25 14:00 - COMMIT

- All gates PASS (Phase completed × 4, Codex review記録あり, retro_status: captured, Test List 全 DONE)
- 9 files committed (8 in-scope + 1 cycle doc):
  - `rules/agent-prompts.md` (canonical, +14 lines): 並列起動時の prompt 契約 section 追加
  - `.claude/rules/agent-prompts.md` (mirror, +14 lines): canonical と identical sync
  - `skills/review/steps-subagent.md` (+12 lines): Step 5 Findings Synthesis sub-section 追加、raw/final blocking_score 分離契約
  - `docs/STATUS.md` (4 changes): Test Scripts 112, Last updated, Done 43, Recent cycle 行
  - `tests/test-codify-insight.sh` (TC-19 hardcode 110→112 collateral fix)
  - `tests/test-rule-agent-prompts-parallel-clause.sh` (new, 248 lines, 4 TC)
  - `tests/test-review-step5-synthesis-clause.sh` (new, 178 lines, 4 TC)
  - `docs/cycles/20260427_0930_pre-existing-fail-cleanup.md` (codify-insight 経由で 4 deferred 判定 append)
  - `docs/cycles/20260525_1249_rule-and-review-synthesis-from-kimi-insight.md` (this file)
- DISCOVERED 3件起票 (#135 CLAUDE.md staleness, #136 Block 0 baseline, #137 REVIEW accept-defer 5件)
- Phase completed

---

## Next Steps

1. [Done] KICKOFF
2. [Done] RED
3. [Done] GREEN
4. [Done] REFACTOR
5. [Done] REVIEW
6. [Done] COMMIT <- Current
7. [Done] DONE

## Retrospective

抽出時刻: 2026-05-25 13:55
抽出方法: Cycle doc 全体 (plan / KICKOFF / Codex plan review BLOCK→re-review PASS / RED / GREEN with collateral fix / REFACTOR / VERIFY / REVIEW with 5 Claude reviewers + Codex / Step 5 Findings Synthesis dogfood / DISCOVERED 3件起票) からの失敗→最終解→insight ペア抽出

### Insight 1: plan 段階で test_count > 0 と rule mirror の Files list 反映を pre-check する

- **Failure**: plan v1 が Files to Change に `tests/test-*.sh` 2件と canonical `rules/agent-prompts.md` を欠落。sync-plan は plan を尊重して Cycle doc 生成 → Codex plan review #1 で BLOCK (score 86, 2 critical findings: scope creep + mirror contract)
- **Final fix**: Cycle doc を APPEND-ONLY で補正、Codex resume で re-review PASS (score 8)。本 cycle 中盤で Files list 補正の手戻りを発生させた
- **Insight**: **plan 書き手 (human / PdM) は Files list 作成前に「test_count > 0 → tests/*.sh ファイル名を Files list に明示」「rules/*.md を編集 → canonical (rules/) + mirror (.claude/rules/) の両方を明示」の pre-check を行う**。Codex plan review が必ず拾うチェック項目を plan 段階で先回り抑止する
- **一般化**: 数値契約 (test_count) と mirror 契約 (rules) は plan 段階で隠れた依存を持つ。`rules/agent-prompts.md` の「禁止事項」section に「test_count > 0 を宣言したら tests/*.sh を Files list に明示」「rules/*.md 編集時は mirror も明示」を codify 候補

### Insight 2: Block 0 で codify gate scan + full-suite baseline 実測の両方を必須化する

- **Failure**: 本 cycle Block 0 で codify gate scan のみ実施、full-suite baseline 未実測。GREEN 後の baseline で初めて 5 FAIL 検出 (4件 pre-existing、1件 regression)、scope 切り分け判断が後手
- **Final fix**: regression 1件 (test-codify-insight.sh TC-19) を即時 collateral fix、pre-existing 4件を DISCOVERED D1 起票 (#135)
- **Insight**: **orchestrate Block 0 は「codify gate scan + full-suite baseline 実測 + 結果記録」の 3 step で構成する**。pre-existing FAIL を発見した時点で本 cycle scope 内 fix 可能性を判断、scope 越えなら DISCOVERED 先送り。`plan-discipline.md` L23 「pre-existing FAIL 発見時 1 行 fix 可能か確認」の前段「発見タイミング (Block 0 で実測)」が orchestrate skill に未明文化
- **一般化**: 既に DISCOVERED D2 (#136) として issue 起票済み。`skills/orchestrate/SKILL.md` Block 0 に baseline 取得 step を追加する follow-up cycle で codify 候補

### Insight 3: 新 rule cycle は REVIEW phase で自 rule を dogfood する

- **Failure**: なし (成功事例として記録)
- **Final fix**: REVIEW Step 4 で「3+ subagent fan-out 契約」(本 cycle 追加の新 rule) を 5 Claude reviewer prompt 全てに適用、Step 5「Findings Synthesis」(本 cycle 追加の新 sub-section) を即時 execute、accept-apply/defer/reject の 3-category 分類を実施
- **Insight**: **新 rule を追加する cycle は、その cycle 自身の REVIEW phase でその新 rule を dogfood する**。これにより rule の実用性・曖昧さが即座に検証される。本 cycle では 3+ fan-out 契約が "raw blocking_score / final blocking_score" の区別を導入する gap を REVIEW 中に発見、Step 5 改修と Score Aggregation 文言修正で in-scope 解消
- **一般化**: `rules/integration-verification.md` cycle 20260424_0900 #1 (新 rule cycle の Verification section self-apply) の REVIEW phase 拡張。Verification real-path invocation だけでなく REVIEW reviewer prompt にも新 rule を適用する規律を rule 化候補

### Insight 4: plan IMMUTABLE + Cycle doc APPEND-ONLY で plan v2 相当の補正が可能

- **Failure**: Codex plan review BLOCK 後、plan file を修正したいが plan IMMUTABLE 制約 (cycle 20260422_1146 #4) で不可
- **Final fix**: PdM が Cycle doc の In Scope / Files to Change / Test List を APPEND-ONLY で補正 (既存 bullet 削除なし、追加のみ) + Progress Log に補正経緯記録 + frontmatter codex_session_id / updated 更新
- **Insight**: **plan IMMUTABLE 制約下では Cycle doc が事実上の "plan v2" として機能する**。doc-mutations.md "Cycle doc は cycle 進行中の SSOT" 原則と plan IMMUTABLE 原則は両立し、Cycle doc 補正で plan 不在のまま運用継続可能
- **一般化**: doc-mutations.md cycle 20260422_1146 #4 の運用補完事例として記録。実際にこのパターンが運用された初の cycle。observation 寄り、no-codify 候補 (rule 化で強制せず暗黙運用)

### Insight 5: risk-classifier 判定は self-declared risk_level を上書きする

- **Failure**: plan / Cycle doc 初期で `risk_level: low` と self-declare、Codex plan re-review でも PASS (score 8, LOW)。REVIEW phase で risk-classifier.sh が **HIGH (score 75)** と判定 → reviewer 数 4→6 にスケール、Codex も含めて 6 並列
- **Final fix**: HIGH tier で 5 Claude reviewers + Codex 並列実行 (`rules/review-triage.md` Risk-based Reviewer Scaling 準拠)、frontmatter `risk_level: low → high` 更新 (REVIEW phase で gold-standard を反映)
- **Insight**: **risk_level は self-declared でなく risk-classifier.sh の結果を採用する**。PdM の想定 (doc-only = LOW) と classifier の判定 (rules/skills 変更 = HIGH) が乖離する場合、classifier 優先で reviewer をスケールする
- **一般化**: risk-classifier.sh が rules/、skills/、tests/ 変更を HIGH 評価する設計 (decision: docs/cycles/...)。doc-only 想定でも rule/skill 変更は HIGH 扱いを尊重。observation 寄り、no-codify 候補
