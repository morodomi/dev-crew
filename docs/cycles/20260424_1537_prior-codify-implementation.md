---
feature: prior-codify-implementation
cycle: 20260424_1537
phase: COMMIT
complexity: standard
test_count: 13
risk_level: low
retro_status: captured
codex_session_id: "019dbe38-13af-7e43-a998-d8394fb2d681"
created: 2026-04-24 15:37
updated: 2026-04-24 16:55
---

# Cycle B: prior-codify implementation (F)

## Scope Definition

### In Scope
- [ ] rules/integration-verification.md に self-apply mandatory 条項追記 (0900-1)
- [ ] rules/test-patterns.md に section-specific grep + grep -E alternation escape 追記 (0900-2 + 1119-2)
- [ ] rules/plan-discipline.md に doc sweep + 除外数値明記 追記 (0900-3 + 1119-1)
- [ ] 上記 3 rules/ を .claude/rules/ に identical mirror (mirror 契約)
- [ ] skills/review/SKILL.md Gate section に pre-gate (git status --short) 追記 (1119-3)
- [ ] skills/codify-insight/reference.md に reason-aware duplicate-negative 例外追記 (1119-4)

### Out of Scope
- Cycle A (20260424_1356) の insights 実装 (scope 外。Cycle A insights は codify-insight Block 0 で triage される)
- 新規 test file の追加 (既存テストで全件検証可能)
- STATUS.md test count 更新 (test file 追加なし)

### Files to Change (target: 10 or less, actual: 9 — Codex plan review #1 Finding #5 対応で +1)
- `rules/integration-verification.md` (edit) — self-apply mandatory section 追記
- `rules/test-patterns.md` (edit) — section-specific grep + ERE alternation 追記
- `rules/plan-discipline.md` (edit) — doc sweep + 除外数値明記 追記
- `.claude/rules/integration-verification.md` (mirror)
- `.claude/rules/test-patterns.md` (mirror)
- `.claude/rules/plan-discipline.md` (mirror)
- `skills/review/SKILL.md` (edit) — Gate section に pre-gate 追記 (末尾 append、既存 bullets 順序保持)
- `skills/codify-insight/reference.md` (edit) — Reason-aware duplicate-negative 例外 subsection 追記 (既存 table 不変)
- `tests/test-codify-rule-docs.sh` (edit、Finding #5 対応で追加) — 新規 key phrase assertion を section-specific grep で追加 (drift 防止 reverse contract)

## Environment

### Scope
- Layer: Infrastructure (rules + skill docs)
- Plugin: N/A (workflow 横断)
- Risk: 25 / 100 (PASS)

### Runtime
- Language: Bash (tests), Markdown (rules/skills)
- Dependencies: N/A

## Context & Dependencies

### Reference Documents
- `docs/cycles/20260424_0900_integration-verification-rule.md` — 0900-1/0900-2/0900-3 の出典
- `docs/cycles/20260424_1119_discovered-debt-cleanup.md` — 1119-1/1119-2/1119-3/1119-4 の出典
- `.claude/rules/doc-mutations.md` — APPEND-ONLY 契約 (rule 追記は既存 section 末尾への append)
- `.claude/rules/skill-authoring.md` — Insight 引用の原則 (原文引用 + generalize 理由明記)
- `rules/integration-verification.md` — Verification section self-apply 要件

### Baseline 実測 (Codex plan review #1 Finding #4 対応、1119-1 rule dogfood 適用)

`.claude/rules/plan-discipline.md` "baseline 実測の除外数値明記" rule を本 Cycle doc baseline に適用:

**実測コマンド + 結果**:
```
$ git ls-files | wc -l          # total git-managed files
405
$ git ls-files rules/ | wc -l
12
$ git ls-files .claude/rules/ | wc -l
13
$ git ls-files skills/ | wc -l
82
$ git ls-files tests/ | wc -l
110
```

**対象ファイル数**:
- **含める数**: **9 files** (本 cycle で edit 対象)
- **除外する数**: **396 files** (= 405 total − 9)
- **除外 category 内訳**:
  - **category 1 (rules/ 他)**: **9 files** (= 12 rules/ − 3 target: integration-verification + test-patterns + plan-discipline)。除外根拠: 本 cycle 7 insights と関係ない rule docs (agent-prompts / doc-mutations / git-conventions 等)、`.claude/rules/doc-mutations.md` "APPEND-ONLY 契約" 準拠で scope 外
  - **category 2 (.claude/rules/ 他)**: **10 files** (= 13 .claude/rules/ − 3 target)。うち 1 件は `post-approve.md` (`CLAUDE_ONLY_FILES` allowlist、mirror 対象外)、残り 9 は rules/ 他と同様 scope 外
  - **category 3 (skills/ 他)**: **80 files** (= 82 skills/ − 2 target: review/SKILL.md + codify-insight/reference.md)。除外根拠: 1119-3 と 1119-4 の 2 skill 以外は insight と無関係
  - **category 4 (tests/ 他)**: **109 files** (= 110 tests/ − 1 target: test-codify-rule-docs.sh)。除外根拠: 本 cycle は doc 追記 + 既存 test 1 件への assertion 追加で、他 test file に影響しない
  - **category 5 (docs/ + root + scripts/ + 他)**: **188 files** (= 405 − 12 − 13 − 82 − 110)。除外根拠: doc/script 変更は sync-plan/commit phase が自動管理、本 cycle の直接 edit 対象外

**対象 file 行数** (9 files、実測):
```
$ wc -l rules/integration-verification.md rules/test-patterns.md rules/plan-discipline.md \
        .claude/rules/integration-verification.md .claude/rules/test-patterns.md .claude/rules/plan-discipline.md \
        skills/review/SKILL.md skills/codify-insight/reference.md \
        tests/test-codify-rule-docs.sh
 31 rules/integration-verification.md
 55 rules/test-patterns.md
 46 rules/plan-discipline.md
 31 .claude/rules/integration-verification.md
 55 .claude/rules/test-patterns.md
 46 .claude/rules/plan-discipline.md
 49 skills/review/SKILL.md
143 skills/codify-insight/reference.md
446 tests/test-codify-rule-docs.sh
```

### 前 cycle (Cycle A) の Retrospective は既に resolved
```
$ awk '/^---$/{c++;next} c==1{print}' docs/cycles/20260424_1356_small-debt-cleanup.md | grep retro_status
retro_status: resolved
```
Cycle A insights は本 Cycle B orchestrate Block 0 codify-insight で triage 済み (5 deferred + 2 no-codify)。本 cycle では扱わない。

### Dependent Features
- test-rules-mirror.sh: mirror 契約 TC-01 (rules/ ↔ .claude/rules/ 整合)
- test-codify-rule-docs.sh: rule 構造 key phrase 検証

### Related Issues/PRs
- (なし)

## Test List

### TODO
- [ ] TL-1: `bash tests/test-rules-mirror.sh` — mirror 契約 (3 rules/ ↔ .claude/rules/ 整合) 回帰
- [ ] TL-2: `bash tests/test-codify-rule-docs.sh` — rule 構造検証 (H2 sections + key phrase) 回帰
- [ ] TL-3: `bash tests/test-skills-structure.sh` — skills/review/SKILL.md が < 100 行制約を維持
- [ ] TL-4: `bash tests/test-directory-structure.sh` — 全体構造 (cycle doc 含む) 維持
- [ ] TL-5: key phrase assertion を `tests/test-codify-rule-docs.sh` に section-specific 恒久化 (Codex plan review #1 Finding #5 対応、#2 Finding #5 再対応)
  - 既存 `section_grep` helper (H2 only、`grep -cF` fixed-string) を再利用 (helper 拡張なし)
  - 全 7 key phrase を**H2 section 範囲 + fixed string** に書き換え (regex pattern 使用禁止):
    - `新 rule cycle` in `rules/integration-verification.md` H2 `適用範囲` (0900-1)
    - `section_grep` in `rules/test-patterns.md` H2 `推奨` (0900-2)
    - `grep -rlF` in `rules/plan-discipline.md` H2 `推奨` (0900-3)
    - `除外 category` in `rules/plan-discipline.md` H2 `推奨` (1119-1)
    - `alternation` in `rules/test-patterns.md` H2 `禁止事項` (1119-2、regex `grep -E.*alternation` から fixed string `alternation` に書き換え、既存 helper 対応)
    - `git status --short` in `skills/review/SKILL.md` H2 `Workflow` (1119-3、Gate は Workflow 内 H3 のため H2 `Workflow` section で捕捉)
    - `Reason-aware` in `skills/codify-insight/reference.md` H2 `Recurrence-aware Pre-triage` (1119-4)
  - **scope change 記録**: 当初「TL-5 の one-off grep を恒久 test 化」は既存 helper reuse で完結。helper 拡張なし、ad hoc grep → section_grep 移行のみ
  - dogfood 効果: 0900-2 codify (section_grep helper 再利用規律) を本 cycle で即適用
- [ ] TL-6: mirror diff 検証 (3 files の identical 確認)
  - `diff rules/integration-verification.md .claude/rules/integration-verification.md`
  - `diff rules/test-patterns.md .claude/rules/test-patterns.md`
  - `diff rules/plan-discipline.md .claude/rules/plan-discipline.md`

### WIP
(none)

### DISCOVERED
(判明次第追記)

### DONE
(none)

## Implementation Notes

### Goal
cycle 20260424_0900 + 20260424_1119 の計 7 codify 決定 (destination 明記・実装 follow-up) を rule/skill に inline-update で履行する。

### Background
codify-insight/reference.md ADR-002 L86「codify 実行は強制しない」の運用上、decision-only record は実装 cycle で actionable にする必要がある。2 cycle 分 (7 件) をまとめて履行するのが本 cycle。

### Design Approach

#### rules/integration-verification.md (0900-1)
既存「適用範囲」section 末尾に `### rule 新設 cycle への self-apply` subsection を追記:
「新 rule を定義する cycle は、同 rule で定義した real-path invocation pattern を cycle 自身の Verification section にも適用する (dogfood 必須)」
出典: docs/cycles/20260424_0900_integration-verification-rule.md Insight 1

#### rules/test-patterns.md (0900-2 + 1119-2)
禁止事項 section 末尾に 2 項目追加:
- whole-file grep で structured doc の contract assertion (section_grep 不使用による偽 PASS)
- `grep -E "a\|b"` の escape alternation (ERE では `\|` がリテラル pipe、alternation 無効化)
推奨 section 末尾に 2 項目追加:
- section-specific grep: section_grep helper 再利用 (awk で H2/H3 heading 範囲抽出 → grep)
- regex alternation: `grep -E "a|b|c"` (non-escaped, ERE 標準) + printf oracle 実測

#### rules/plan-discipline.md (0900-3 + 1119-1)
禁止事項 section 末尾に 1 項目追加:
- baseline 実測の除外理由不明記 (N 件と書く際、除外 category + 根拠 rule 参照を本文に必ず明記)
推奨 section 末尾に 2 項目追加:
- `grep -rlF '<既存概念>' skills/` で影響範囲 sweep を scope に含める
- 数値は「含める数 + 除外数 + 除外理由 (カテゴリ + 根拠 rule 参照)」の 3 要素明記

#### skills/review/SKILL.md Gate section (1119-3) — Codex plan review #1 Finding #2 対応

**middle-insert 回避**: 既存 bullets (`Cycle Doc Gate` / `Phase Ordering Gate`) の**順序を保持**し、Gate section の**末尾に append**:

```markdown
**code mode only**:
- Cycle Doc Gate (frontmatter のみ): ... (既存、変更なし)
- Phase Ordering Gate: ... (既存、変更なし)
- **Repo-state pre-check** (cycle 20260424_1119 #3): review 実行前に `git status --short` を先に確認し、`??` (untracked) or ` D` (unstaged deletion) を検出したら WARN + 対応案内。新規 test file / Cycle doc 等が未 staged のまま review されるのを防ぐ。
```

既存 bullets は一切動かさず、新 bullet のみ section 末尾に append。順序を強調する目的は「review 実行前に先に確認する」の本文記述で達成。49 行 → 54 行程度。100 行制約 safe。

#### skills/codify-insight/reference.md Recurrence section (1119-4) — Codex plan review #1 Finding #1+#3 対応

**middle-insert 回避**: 既存 frequency table (L59-65) は**一切変更しない**。Recurrence section の末尾に `### Reason-aware duplicate-negative 例外` subsection を **append** (table schema 拡張でなく追記テキストで表現)。

**原文引用** (skill-authoring.md "Insight 引用の原則" 準拠):
> cycle 20260424_1119 Insight 4: 「**recurrence-aware triage の "duplicate negative" rule には「過去 no-codify 理由が recurrence で無効化されたか」を判定する例外が必要**。現行 rule は reason を unread で duplicate-negative 適用するが、recurrence 自体が reason を validate/invalidate する signal なので、reason-aware の判定に拡張する。」

**generalize 理由**: cycle 20260424_1119 の Insight 2 処理 (過去 no-codify を recurrence で上書きしてユーザー確認で codify 昇格) が cycle 特有の一度きりの運用判断ではなく、「過去判断の根拠が時限的か恒常的か」という **LLM triage の一般的な問題**。rule 化で strict duplicate-negative の機械適用を防ぎ、reason-aware 判定を標準化する。

**追記内容** (section 末尾 append):

```markdown
### Reason-aware duplicate-negative 例外 (cycle 20260424_1119 #4)

既存 frequency table の `1+ で過去 no-codify 判定` 行は、過去 reason が時限的
(「一般性未確認」「localized pattern」「運用習慣で十分」等) な場合、recurrence で
根拠が実証的に invalidate されうる。strict な duplicate-negative 適用は "永久に
codify できない" lock-in を生むため、pre-triage phase で past reason を LLM に読ませ
「この reason は recurrence で invalidate されるか？」を判定する。invalidate されれば
normal autonomous triage へ fallback、そうでなければ既存 duplicate-negative を維持。

判定例 (reason が recurrence で invalidate されるケース):
- 「一般性未確認」 → 2 回目再発で一般性は実証済 → invalidate
- 「localized pattern」 → 他 context で再発 → invalidate
- 「運用習慣で十分」 → 運用違反が再発 → invalidate
```

既存 table は schema 保持、本 subsection の本文で「1+ で過去 no-codify 判定」の例外条件を記述する形式。

## Verification

```bash
# 1. mirror gate (real-path consumer、3 files の mirror 整合)
bash tests/test-rules-mirror.sh; echo "mirror rc=$?"

# 2. rule 構造 gate (既存 key phrase 維持 + 新 key phrase 検出)
bash tests/test-codify-rule-docs.sh; echo "codify-rule-docs rc=$?"

# 3. SKILL.md 行数制約 (100 行 hard limit)
wc -l skills/review/SKILL.md
# expected: < 100

# 4. key phrase presence (7 codify 決定が全て rule/skill 本文に反映されている)
grep -c "新 rule cycle\|section_grep\|grep -rlF\|除外\|Reason-aware\|git status --short" \
  rules/integration-verification.md rules/test-patterns.md rules/plan-discipline.md \
  skills/review/SKILL.md skills/codify-insight/reference.md

# 5. mirror diff 実測 (3 files の identical 確認)
diff rules/integration-verification.md .claude/rules/integration-verification.md && echo "iv-mirror OK"
diff rules/test-patterns.md .claude/rules/test-patterns.md && echo "tp-mirror OK"
diff rules/plan-discipline.md .claude/rules/plan-discipline.md && echo "pd-mirror OK"

# 6. full baseline (pre-existing FAIL のみ、本 cycle 起因ゼロ確認)
for f in tests/test-*.sh; do
  bash "$f" >/dev/null 2>&1
  rc=$?
  [ $rc -ne 0 ] && echo "FAIL: $(basename $f) rc=$rc"
done
# expected: pre-existing 6 FAIL (cycle 20260424_1356 DISCOVERED) のみ
```

dev-crew 内 bash/doc project のため、gate script (test-rules-mirror.sh) と consumer (test-codify-rule-docs.sh、test-skills-structure.sh) を real path で実行することで integration-verification rule に準拠した検証となる。

Evidence: (orchestrate が自動記入)

## Progress Log

### 2026-04-24 15:37 - KICKOFF
- Cycle doc created from plan `/Users/morodomi/.claude/plans/1-precious-hammock.md`
- Design Review Gate: PASS (score: 5) — 懸念事項なし。クリーンPASS
- Scope: 8 files (rules x3 + mirror x3 + skills x2)、Risk 25/100 (LOW)
- Phase completed

### 2026-04-24 15:45 - Codex plan review #1: BLOCK → Cycle doc SSOT 修正

- Codex session: `019dbe38-13af-7e43-a998-d8394fb2d681`
- **Finding #1 (high)**: 1119-4 既存 frequency table への新列追加 = middle-insert 違反 → 既存 table 不変、Recurrence section 末尾に subsection 追記方式に変更
- **Finding #2 (high)**: 1119-3 既存 bullets の前に pre-gate 差し込み = middle-insert 違反 → 既存 bullets 順序保持、section 末尾に append
- **Finding #3 (medium)**: 1119-4 に原文引用 + generalize 理由不足 → Insight 4 の原文引用 + 一般化理由を Cycle doc Design Approach に追記
- **Finding #4 (medium)**: Baseline section の "既に dogfood 適用" 主張と本文不整合 → Cycle doc に 9 files 内訳 + 3 除外 category + 除外根拠を明記 (Cycle doc が SSOT、plan file は IMMUTABLE)
- **Finding #5 (medium)**: TL-5 の one-off grep が弱い reverse contract → scope +1 で `tests/test-codify-rule-docs.sh` に section-specific key phrase assertion を追加 (Files to Change 8 → 9)
- **対応**: plan file は IMMUTABLE (doc-mutations.md L13-17 準拠)、Cycle doc を SSOT として全 5 findings 対応

### 2026-04-24 15:50 - Codex plan review #2: BLOCK (partial resolved) → Cycle doc 再修正

- **Finding #1-#3 resolved**: middle-insert 回避 + 原文引用 + generalize 理由追加は Codex が accept
- **Finding #4 残存 (high)**: Baseline section に `全件` / `40+` / `TBD` のあいまい表現が残存、empirical count 不足
  - **対応**: `git ls-files | wc -l` 等で total 405、rules/12、.claude/rules/13、skills/82、tests/110 を実測。除外 5 category に厳密分解 (9 / 10 / 80 / 109 / 188 = 396)
- **Finding #5 残存 (high)**: `section_grep` helper は H2 + `grep -cF` (fixed string) のみ。TL-5 の `grep -E.*alternation` regex 想定 / `Gate` H3 subsection は helper で検証不可
  - **対応**: 全 7 assertion を H2 section + fixed string に書き換え (`alternation` 単独、`Workflow` H2 で SKILL.md、`Recurrence-aware Pre-triage` H2 で codify-insight)。helper 拡張は行わず既存 helper で対応可能な literal/section 選択
- Codex resume で再 review 依頼予定

### 2026-04-24 16:10 - RED フェーズ完了

- `tests/test-codify-rule-docs.sh` に TC-20〜TC-26 を追加 (section_grep helper 再利用、H2 + fixed string)
- 実行結果: PASS 19 / FAIL 7 / TOTAL 26
  - TC-01〜TC-19: 全 PASS 維持 (既存テスト回帰なし)
  - TC-20: FAIL — `新 rule cycle` not found in integration-verification.md 適用範囲 (0900-1 未実装)
  - TC-21: FAIL — `section_grep` not found in test-patterns.md 推奨 (0900-2 未実装)
  - TC-22: FAIL — `grep -rlF` not found in plan-discipline.md 推奨 (0900-3 未実装)
  - TC-23: FAIL — `除外 category` not found in plan-discipline.md 推奨 (1119-1 未実装)
  - TC-24: FAIL — `alternation` not found in test-patterns.md 禁止事項 (1119-2 未実装)
  - TC-25: FAIL — `git status --short` not found in skills/review/SKILL.md Workflow (1119-3 未実装)
  - TC-26: FAIL — `Reason-aware` not found in codify-insight/reference.md Recurrence-aware Pre-triage (1119-4 未実装)
- RED 状態確認: 全 7 新 TC が期待通り FAIL → red_state_verified: true
- Phase completed

### 2026-04-24 16:30 - GREEN フェーズ完了

- TC-20〜TC-26 を通す最小実装を完了 (7 key phrase を 6 files に追記)
- rules/integration-verification.md H2 `適用範囲` 末尾に `### 新 rule cycle への self-apply` subsection 追記 (0900-1)
- rules/test-patterns.md H2 `禁止事項` 末尾に 2 項目追記 (whole-file grep + escape alternation)、H2 `推奨` 末尾に 2 項目追記 (section_grep + regex alternation) (0900-2 + 1119-2)
- rules/plan-discipline.md H2 `禁止事項` 末尾に 1 項目追記 (除外理由不明記)、H2 `推奨` 末尾に 2 項目追記 (grep -rlF + 除外 category) (0900-3 + 1119-1)
- .claude/rules/ 3 files identical mirror 済み (diff 空 = OK)
- skills/review/SKILL.md H2 `Workflow` Gate 末尾に `Repo-state pre-check` bullet 追記 (1119-3)、49 → 50 行 (< 100 制約 safe)
- skills/codify-insight/reference.md H2 `Recurrence-aware Pre-triage` 末尾に `### Reason-aware duplicate-negative 例外` subsection 追記 (1119-4)
- 実行結果: PASS 26 / FAIL 0 / TOTAL 26 (TC-20〜TC-26 全 PASS、TC-01〜TC-19 回帰なし)
- 回帰テスト: test-rules-mirror.sh PASS、test-skills-structure.sh PASS、test-directory-structure.sh PASS
- mirror diff: iv OK / tp OK / pd OK (identical 確認)
- Phase completed

### 2026-04-24 16:35 - REFACTOR

- 対象: 9 変更ファイル (3 rules + 3 mirror + 2 skills + 1 test)
- Checklist review: DRY / 定数化 / 未使用 import / let→const / メソッド分割 / N+1 / 命名 全て該当なし
  - TC-20〜TC-26 は同 pattern だが既存 TC-01〜TC-19 の shape と揃えるため helper 抽出しない (CLAUDE.md "Don't add abstractions beyond task requires" 準拠)
  - rule 追記は fixed string + 既存 section 末尾 append で minimal、refactor 対象なし
- Verification Gate PASS:
  - TL-2 (test-codify-rule-docs.sh): 26/26 PASS
  - TL-1 (test-rules-mirror.sh): 3/3 PASS
  - TL-3 (test-skills-structure.sh): 7/7 PASS
  - TL-4 (test-directory-structure.sh): 9/9 PASS
- Phase completed

### 2026-04-24 16:50 - VERIFY + REVIEW

- VERIFY (Product Verification real-path invocation):
  - test-rules-mirror 3/3, test-codify-rule-docs 26/26, test-skills-structure 7/7, test-directory-structure 9/9
  - key phrase 7/7 all present
  - mirror diff 3/3 identical
  - SKILL.md 50 lines (< 100 制約 safe)
- Codex code review #1 BLOCK → #2 APPROVED (Progress Log 時系列順序修正後)
  - #1 Finding (high): Progress Log で GREEN が RED より前、REFACTOR が Next Steps 後ろ配置 → 時系列順修正 + Next Steps を EOF に再配置
- Claude correctness-reviewer skip (Codex thorough review で primary coverage、rules/review-triage.md LOW-MEDIUM trivial scope 準用)
- verdict: PASS (Codex APPROVED 最終)
- Phase completed

### DISCOVERED

- [ ] Cycle doc Progress Log の順序 bug を複数 cycle で再発 — orchestrate が phase entry の順序維持を保証する gate が欠如。次 cycle で pre-commit-gate or sync-plan template の強化候補

### DONE

- [x] 0900-1: integration-verification.md に self-apply mandatory 追記
- [x] 0900-2: test-patterns.md に section_grep 再利用規律追記
- [x] 0900-3: plan-discipline.md に grep -rlF 影響範囲 sweep 追記
- [x] 1119-1: plan-discipline.md に baseline 除外数値明記追記
- [x] 1119-2: test-patterns.md に ERE alternation escape 落とし穴追記
- [x] 1119-3: review/SKILL.md に Repo-state pre-check 追記
- [x] 1119-4: codify-insight/reference.md に Reason-aware duplicate-negative 例外追記

---

## Next Steps

1. [Done] REVIEW
2. [Next] COMMIT
3. [ ] DONE

## Retrospective

抽出時刻: 2026-04-24 16:55
抽出方法: Cycle doc 全体 (plan / KICKOFF / Codex plan review #1 #2 #3 / RED / GREEN / REFACTOR / VERIFY / Codex code review #1 #2 / REVIEW) からの失敗→最終解→insight ペア抽出

### Insight 1: codify 決定から実装までの期間が長いとコンテキスト消失、insight 原文参照が必要になる

- **Observation**: cycle 20260424_0900 の 3 codify 決定は本 cycle 20260424_1537 で実装 (約 7 時間後)。cycle 20260424_1119 の 4 codify 決定は約 5.5 時間後。短期間ながら「decision → implementation」の間に Cycle A (1356) が挟まり、7 件の insight を改めて原文参照・再解釈する必要があった。
- **Final fix**: N/A (observation)
- **Insight**: **codify decision から implementation までの interval が短いほど context 消失コストが低い**。ADR-002 L86 "codify 実行は強制しない" の spirit を維持しつつ、「次の trivial cycle に codify 実装を詰める」慣行が効率的。orchestrate Block 0 の codify gate 後、同 cycle 内 or 次 cycle で実装を推奨する運用 norm として暗黙共有。
- **一般化**: knowledge → action 変換の遅延は cost を生む。TDD の "Fail fast" 精神を codify にも適用: "codify fast, implement fast"。

### Insight 2: plan 内の meta-claim (「既に適用済み」等) は evidence と必ず一致させる

- **Failure**: 本 plan で「Baseline 実測 section で既に dogfood 適用済み」と書いたが、実際の Baseline は 5 file 行数のみで、除外数値・category・根拠 rule が本文にない → Codex plan review #1 Finding #4 で BLOCK。"claim の integrity" が plan review の厳密検査対象。
- **Final fix**: Cycle doc Baseline section に empirical count (`git ls-files` 実測) + 9 files 内訳 + 5 除外 category (計 396 files) + 各 category 除外根拠を明記
- **Insight**: **plan 内で「rule X を適用済み」「dogfood 済み」等の meta-claim を書く場合、該当 evidence (実測 table、引用、具体数値) を plan 本文に揃えないと Codex plan review で必ず BLOCK される**。claim without evidence は plan-discipline.md "narrative baseline 禁止" (cycle 20260422_0937 #2) の拡張系。rule 追記候補: 「plan 内の meta-claim は必ず evidence を本文に併記」
- **一般化**: 実証主義。claim を書く → evidence を書く → cross-reference を書く の 3 ステップで claim integrity を保証。

### Insight 3: helper を plan で reuse する場合、helper の仕様制約 (input domain) を事前実測する

- **Failure**: TL-5 で既存 `section_grep` helper を reuse すると plan に書いたが、helper は H2 + `grep -cF` (fixed string) のみ対応。plan の想定は H3 subsection (Gate) + regex pattern (`grep -E.*alternation`)。Codex plan review #2 Finding #5 で BLOCK。helper 仕様を読まずに plan した結果。
- **Final fix**: helper 拡張せず、全 7 assertion を H2 section + fixed string literal に書き換え (`alternation` 単独、`Workflow` H2 で SKILL.md、`Recurrence-aware Pre-triage` H2 で codify-insight)
- **Insight**: **helper reuse を plan する前に helper の input domain / supported pattern / size constraints を実測確認する**。`head -20 helper_file` で spec を読むか、`helper_fn input_example` で実測。plan-discipline.md "narrative baseline 禁止" の helper 版 — 「仕様未確認で helper reuse 計画禁止」。rule 追記候補
- **一般化**: reuse は機械的な「共通化」ではなく、仕様の contract match が要件。API 仕様書を読まずに API を使わない、のと同じ discipline。

### Insight 4: APPEND-ONLY 契約は "section 末尾 append" のみ、"section 内 middle-insert" も違反

- **Failure**: 1119-3 の実装案で `skills/review/SKILL.md` の既存 bullets `Cycle Doc Gate` / `Phase Ordering Gate` の**前**に pre-gate bullet を差し込む plan。これは「section 末尾への append」ではなく「section 内の middle-insert」。Codex plan review #1 Finding #2 で BLOCK。1119-4 も既存 frequency table への新列追加 = middle-insert で Finding #1 BLOCK
- **Final fix**: 既存 bullets の**順序を保持**し、section 末尾に新 bullet を append。順序を強調したい場合は新 bullet 本文で「review 実行前に先に確認する」等を記述。既存 table は不変、Recurrence section 末尾に subsection 追記方式
- **Insight**: **doc-mutations.md "APPEND-ONLY 契約" の厳密な意味は「ファイル末尾 or section 末尾への append のみ、既存 bullet/table row の前後挿入も middle-insert 違反」**。rule 追記候補: 「bullets/table への追記は最終行の次にのみ可、既存順序の変更・挿入は禁止」
- **一般化**: immutable data structure の精神を doc にも適用。既存 element の reorder は edit、append は extension。両者を区別する。

### Insight 5: Progress Log の phase entry 順序は手動 append で壊れやすい、template or gate で enforcement 候補

- **Failure**: green-worker が GREEN entry を RED entry の**前**に append (時系列逆)、私が REFACTOR entry を Next Steps section の**後ろ**に append (section 構造破壊)。Codex code review #1 で BLOCK (high severity)
- **Final fix**: Progress Log を時系列順に並べ直し (RED → GREEN → REFACTOR)、Next Steps section を `---` 後 EOF に再配置
- **Insight**: **Cycle doc の Progress Log は手動 append で構造が壊れやすい (特に複数 agent が序列を考えずに EOF へ追記する場合)**。sync-plan template で Progress Log の構造を明示するか、pre-commit-gate で「Progress Log は `---` 前にあり phase entry が時系列順」を検証する gate 追加候補。cycle 20260424_1356 DISCOVERED Insight 6 (pre-commit-gate 数値 contract) と同系統の gate 強化
- **一般化**: 複数 actor が serial edit する shared document は、structural invariant を tool-enforced にすべき。LLM agent に形式を委ねると必ず崩れる。

### Insight 6 (observation、no-codify): section_grep helper の dogfood が同 cycle で完結した

- **Observation**: 0900-2 codify 決定「section_grep helper 再利用規律」を本 cycle の TC-20〜TC-26 (test-codify-rule-docs.sh) で即 self-apply。codify → 即 implementation → 即 dogfood の 3 ステップが 1 cycle 内で完結する sweet spot。
- **Final fix**: N/A (observation)
- **Insight**: codify 決定が「同 cycle で即適用可能」な場合、plan に self-apply を組み込むと rule 品質検証と implementation 検証を同時に行える。rule 化で強制する性質ではなく運用 norm として活用。

## Codify Decisions

### Insight 1
- **Decision**: deferred
- **Reason**: 新 cycle で codify-insight/reference.md に「follow-up cycle は短期間で実施する運用 norm」を追記 (現状 ADR-002 L86 "codify 実行は強制しない" は維持しつつ、context decay 防止として short-interval を推奨). 本 cycle scope 外
- **Decided**: 2026-04-24 16:55

### Insight 2
- **Decision**: deferred
- **Reason**: 新 cycle で plan-discipline.md に「plan 内の meta-claim は evidence 併記必須」を追記。"narrative baseline 禁止" (cycle 20260422_0937 #2) の claim integrity 拡張。本 cycle scope 外
- **Decided**: 2026-04-24 16:55

### Insight 3
- **Decision**: deferred
- **Reason**: 新 cycle で plan-discipline.md に「helper reuse を plan する前に helper 仕様 (input domain, pattern) を実測確認」を追記。本 cycle scope 外
- **Decided**: 2026-04-24 16:55

### Insight 4
- **Decision**: deferred
- **Reason**: 新 cycle で doc-mutations.md "APPEND-ONLY 契約" を厳密化 — 「section 内 middle-insert (既存 bullets の前/間への差し込み) も違反、bullets は section 末尾のみ append 可」を追記。本 cycle scope 外
- **Decided**: 2026-04-24 16:55

### Insight 5
- **Decision**: deferred
- **Reason**: 新 cycle で pre-commit-gate.sh または sync-plan template に「Progress Log の phase entry 時系列順 + Next Steps section は EOF 配置」を enforcement gate として追加。cycle 20260424_1356 DISCOVERED Insight 6 と同系統の gate 強化で合流可能。本 cycle scope 外
- **Decided**: 2026-04-24 16:55

### Insight 6
- **Decision**: no-codify
- **Reason**: Insight heading に明示された `(observation、no-codify)`。codify → 即 implementation → 即 dogfood の 3 ステップ完結は運用 norm として暗黙共有する性質で、rule 化不要
- **Decided**: 2026-04-24 16:55
