---
feature: integration-verification-rule
cycle: 20260424_0900
phase: COMMIT
complexity: standard
test_count: 109
risk_level: low
retro_status: captured
codex_session_id: "019dbcfd-b821-7de2-a8b7-980e430b767b"
created: 2026-04-24 09:00
updated: 2026-04-24 10:20
---

# Integration Verification Rule — real-path invocation mandatory in Verification Gate

## Scope Definition

### In Scope
- [ ] `rules/integration-verification.md` 新規作成 (≤ 60 行、wording は "can miss when tests bypass runtime wiring" / "non-trivial cycle で strong recommended" で advisory spirit 維持)
- [ ] `.claude/rules/integration-verification.md` に identical mirror
- [ ] `skills/spec/templates/cycle.md` Verification section を real-path invocation 第一義に更新 (CLI / Web / Library / **Config 変更時** 4 例示、config が motivating bug なので必須)
- [ ] `skills/orchestrate/SKILL.md` Block 2c.5 に rule 参照 + WARN 動作明記
- [ ] `skills/orchestrate/reference.md` Product Verification 詳細に real-path invocation 原則追記
- [ ] `skills/orchestrate/steps-subagent.md` L155 silent skip → WARN 記述に統一 (Codex plan review #1 指摘、doc-consuming drift 防止)
- [ ] `skills/orchestrate/steps-teams.md` L194 silent skip → WARN 記述に統一
- [ ] `skills/orchestrate/steps-codex.md` L89 silent skip → WARN 記述に統一
- [ ] `tests/test-codify-rule-docs.sh` に TC-19 追加 (section_grep 再利用)
- [ ] `tests/test-product-verify.sh` に TC 追加 — real-path invocation なし時の WARN ログ assertion (Codex plan review #1 指摘)

### Out of Scope
- Kyotei の YAML bug fix (別 repo 作業)
- CI blocking gate 化 (advisory spirit 維持)
- Playwright / testcontainers 導入 (最軽量方針)
- careful allowed-tools 欠落・4 worker agents model frontmatter 欠落 (別 cycle → DISCOVERED)
- dev-crew config audit で検出された minor drift

### Files to Change (target: 10, actual 10 — scope +4 from initial plan per Codex plan review BLOCK)
- `rules/integration-verification.md` (new)
- `.claude/rules/integration-verification.md` (new, mirror)
- `skills/spec/templates/cycle.md` (edit) — Verification 4 例示 (CLI/Web/Library/Config)
- `skills/orchestrate/SKILL.md` (edit) — Block 2c.5 WARN 動作
- `skills/orchestrate/reference.md` (edit) — Product Verification real-path 原則
- `skills/orchestrate/steps-subagent.md` (edit) — silent skip → WARN (Codex 指摘)
- `skills/orchestrate/steps-teams.md` (edit) — silent skip → WARN (Codex 指摘)
- `skills/orchestrate/steps-codex.md` (edit) — silent skip → WARN (Codex 指摘)
- `tests/test-codify-rule-docs.sh` (edit) — TC-19 追加
- `tests/test-product-verify.sh` (edit) — WARN assertion TC 追加 (Codex 指摘)

Total: 10 files (at target)

### dev-crew 内 Self-apply の定義

dev-crew 自身は bash/doc project なので、real-path invocation は以下で代替:
- gate script 実行: `bash scripts/gates/pre-commit-gate.sh $cycle_doc`
- consumer script 直接呼出: `bash skills/<skill>/check.sh`
- validator 直接呼出: `bash scripts/validate-yaml-frontmatter.sh`

`grep` / `diff` のみの Verification は「structural test」で、real-path invocation の代替とみなさない (Codex plan review #2 指摘)。

## Environment

### Scope
- Layer: Infrastructure (rules + docs + tests)
- Plugin: N/A (workflow 横断)
- Risk: 15 / 100 (PASS)

### Runtime
- Language: Bash (shell scripts), Markdown

### Dependencies (key packages)
- N/A (doc/test edits のみ)

## Context & Dependencies

### Reference Documents
- `rules/` (11 existing files) — mirror 契約パターン
- `skills/orchestrate/SKILL.md` L73-74 — Block 2c.5 既存定義
- `tests/test-codify-rule-docs.sh` — section_grep helper (TC-01..TC-18)
- `CONSTITUTION.md` — AI 協働原則

### Dependent Features
- mirror 契約: `tests/test-rules-mirror.sh` TC-01 が rules/ ↔ .claude/rules/ 整合を自動検証
- test-codify-rule-docs.sh: section_grep helper を TC-19 で再利用

### Related Issues/PRs
- cycle 20260423_1045 Insight 1 (REFACTOR full-suite baseline 必須) の対となる「production path baseline 必須」
- Kyotei YAML config wire-gap bug (別 repo、本 cycle の動機)

## Test List

### TODO
- [ ] TL-1: `test-rules-mirror.sh TC-01 回帰` — mirror 契約 (rules/integration-verification.md 新規作成後も TC-01 PASS)
- [ ] TL-2: `test-codify-rule-docs.sh TC-19 新規` — rule 構造検証 (H2 sections + key phrase)
- [ ] TL-3: `test-rules-mirror.sh TC-02/03 回帰` — allowlist 不変 (CLAUDE_ONLY_FILES = post-approve.md 維持)
- [ ] TL-4: `spec template verification` — cycle.md Verification section に real-path invocation example ≥ 2
- [ ] TL-5: `orchestrate integration` — Block 2c.5 に rules/integration-verification.md 参照 + WARN 記述

### WIP
(none)

### DISCOVERED
- [ ] 既存 18 cycle の Verification section に retroactive real-path invocation 追加 (現状は migration 不要、新 cycle からのみ適用) — 別 cycle or 放置可
- [ ] `rules/integration-verification.md` も cycle 参照 format rule (cycle 1313 Insight 5) 自体を適用: 現状 `cycle 20260423_1045 Insight 1` を本文で参照しているが full filename ではなく short reference — alias sweep 時に修正対象
- [ ] careful skill の allowed-tools 欠落 + 4 worker agents (sync-plan/green-worker/red-worker/refactorer) の model frontmatter 欠落 (audit で検出、minor drift、別 cycle)
- [ ] 他 5 rule files (agent-prompts/plan-discipline/review-triage/skill-authoring/test-patterns) の informal alias sweep (前 cycle DISCOVERED、未処理)

### DONE
(none)

## Implementation Notes

### Goal
unit tests は mock を通すため「宣言された config/option が production path で呼ばれていない」config-wire-gap 型 bug を検出できない。Verification Gate に real-path invocation (CLI/docker+curl/python -m 等) を最低 1 件含めることを rule として codify し、dev-crew TDD workflow でこの種の bug を cycle 内で早期検出可能にする。

### Background
- Kyotei で YAML config 宣言が実ランタイムに反映されていない latent bug が発見された (cycle-specific に fix 済)
- 既存 18 cycle の Verification section は全て `bash tests/test-*.sh` + `grep`/`diff` のみで real-path invocation 実例ゼロ
- `rules/` に integration/smoke/e2e rule が存在しない (現状 11 ファイル)
- cycle 20260423_1045 Insight 1 「REFACTOR 前に full-suite baseline 必須」の対称として「production path baseline 必須」を rule 化

### Design Approach

**Item 1**: `rules/integration-verification.md` (new, ≤ 60 行)
- 適用範囲: 全 cycle で mandatory (advisory spirit は維持)
- 禁止事項: `bash tests/test-*.sh` + `grep`/`diff` のみ (real-invocation ゼロ)
- 推奨: CLI / Web (docker+curl) / Config 変更時 / Library の 4 パターン
- 出典セクションに Kyotei bug と本 cycle を記録

**Item 2**: `skills/spec/templates/cycle.md` Verification section (L92-100 書き換え)
- real-path invocation を第一義に配置 (CLI / Web / Library 3 例)
- 「real-path invocation を最低 1 件含めること (rules/integration-verification.md)」を冒頭に明記

**Item 3**: `skills/orchestrate/SKILL.md` Block 2c.5 (L73-74 更新)
- rule 参照追加: `rules/integration-verification.md`
- WARN ログ動作明記: real-path invocation なしの場合 WARN
- セクション不在 → WARN スキップ (advisory spirit 維持)

**Item 4**: `skills/orchestrate/reference.md` Product Verification 詳細 (L459-498 追記)
- real-path invocation の重要性 + rule 参照を追記
- 既存 advisory ロジックは変更しない

**Item 5**: `.claude/rules/integration-verification.md` — rules/ から identical mirror (mirror 契約)

**Item 6**: `tests/test-codify-rule-docs.sh` — TC-19 追加
```
# TC-19: rules/integration-verification.md exists + H1 + 禁止事項 に "bash tests/test" +
#         推奨 に "curl|docker|python -m" + 出典 に "Kyotei" or "20260424"
```
新テストファイル追加なし (STATUS.md test count 変化なし)。

## Verification

**Real-path invocation を最低 1 件含めること** (rules/integration-verification.md — 本 cycle が定義する rule を self-apply)。

```bash
# 1. 全テスト実行
for f in tests/test-*.sh; do bash "$f"; done

# 2. 新 TC 単独
bash tests/test-codify-rule-docs.sh  # TC-19 PASS (新規)
bash tests/test-rules-mirror.sh      # TC-01 PASS (rules/ 11→12 で identical 契約)

# 3. rule structure 確認 (real-path: grep on filesystem)
grep -c "^## " rules/integration-verification.md  # ≥ 3 (禁止事項/推奨/出典)

# 4. template 例示確認 (real-path invocation example)
grep -cE "docker|curl|python -m" skills/spec/templates/cycle.md  # ≥ 2

# 5. orchestrate Block 2c.5 に rule 参照あり
grep -cF "rules/integration-verification.md" skills/orchestrate/SKILL.md  # ≥ 1

# 6. mirror 契約 (real-path diff)
for f in rules/*.md; do diff "$f" ".claude/rules/$(basename $f)" >/dev/null && echo "OK: $f" || echo "DIFF: $f"; done

# 7. Self-apply dogfood: real-path invocation of actual validator (本 cycle rule を self-apply)
bash scripts/validate-yaml-frontmatter.sh docs/cycles/20260424_0900_integration-verification-rule.md
# → cycle doc frontmatter が YAML validator (production path) を通過することを確認
```

Evidence: (orchestrate が自動記入)

## Progress Log

### 2026-04-24 09:45 - REFACTOR
- チェックリスト全 7 項目評価: 改善不要
  - rule doc は section 毎 H2 適切、line 40 (< 60 制約)
  - TC-19 は section_grep 既存 helper を再利用 (重複なし)
  - WARN 文言統一が orchestrate/SKILL.md + steps-subagent/teams/codex.md の 4 箇所で一貫
- self-apply 確認: 本 cycle 自身の Verification section #7 に `bash scripts/validate-yaml-frontmatter.sh <cycle-doc>` を real-path invocation として含む (rule 定義の validator 実行 = dev-crew 内 real-path の正式パターン、`bash tests/test-*.sh` は structural test)
- Verification Gate: 3 target tests PASS (TC-19 19/19, TC-10 10/10, TC-01 3/3)、identical 契約 12/12
- Phase completed

### 2026-04-24 09:30 - GREEN
- rules/integration-verification.md 新規作成 (40 行、≤ 60 行制約適合、512 bytes ≥ 300 bytes)
- .claude/rules/integration-verification.md に identical mirror (rules/ 11→12 ファイル)
- skills/spec/templates/cycle.md Verification section 更新 (CLI/Web/Config/Library 4 例示)
- skills/orchestrate/SKILL.md Block 2c.5 に WARN + rules/integration-verification.md 参照追加
- skills/orchestrate/reference.md Product Verification に real-path invocation 原則追記
- skills/orchestrate/steps-subagent.md サイレントスキップ → WARN 記述に更新
- skills/orchestrate/steps-teams.md サイレントスキップ → WARN 記述に更新
- skills/orchestrate/steps-codex.md サイレントスキップ → WARN 記述に更新
- TC-19 PASS: rules/integration-verification.md 構造検証 (H1 + 禁止事項/推奨/出典 + key phrases + size)
- TC-10 PASS: orchestrate docs 4 ファイル全て WARN contract 検証
- TC-01 PASS: rules/ 12 ファイル全て .claude/rules/ と identical (mirror 契約)
- advisory-terminology テスト PASS 維持 (steps-codex/teams に "advisory" 含めず)
- Phase completed

### 2026-04-24 09:20 - RED
- TC-19 追加: tests/test-codify-rule-docs.sh (L385-438) — rules/integration-verification.md 構造検証 → FAIL (file not exist)
- TC-10 追加: tests/test-product-verify.sh (L111-125) — orchestrate docs WARN contract 検証 → FAIL (0/4 docs)
- 既存 TC-01〜TC-18 / TC-01〜TC-09 は全 PASS (回帰なし)
- RED 状態確認済 (red_state_verified: true)

### 2026-04-24 09:00 - KICKOFF
- Cycle doc created from plan /Users/morodomi/.claude/plans/shimmying-swimming-orbit.md
- Design Review Gate (architect): PASS (score: 5)
- Codex plan review: **BLOCK** → 3 件指摘を反映して scope 拡大:
  1. doc-consuming drift (steps-subagent/teams/codex.md の silent skip + test-product-verify.sh の WARN assertion 欠落) → 4 files scope 追加
  2. rule wording 過大 ("cannot detect" → "can miss when tests bypass runtime wiring"、"全 cycle mandatory" → "non-trivial cycle で strong recommended") + dev-crew 自身の real-path invocation 定義 (gate/consumer/validator 実行で代替、grep/diff のみは structural test とみなす)
  3. template example に Config 変更時 (motivating bug) を追加 (CLI/Web/Library/Config 4 例示)
- 修正後 scope: 10 files (+4 from initial plan)
- Branch: feat/integration-verification-rule (新規)
- Phase completed (Codex review 反映済)

---

## Next Steps

1. [Done] KICKOFF
2. [Done] RED
3. [Done] GREEN
4. [Done] REFACTOR
5. [Done] REVIEW (Codex BLOCK → fixes applied → WARN (minor drift) → PASS 同等)
6. [Next] COMMIT
7. [ ] DONE

## Retrospective

抽出時刻: 2026-04-24 10:20
抽出方法: Cycle doc 全体 (plan / Codex plan review BLOCK #3 / RED / GREEN / REFACTOR / Codex code review BLOCK #3 → fixes → WARN / re-review) からの失敗→最終解→insight ペア抽出

### Insight 1: Rule 定義と self-apply は同 cycle 内で consistent でないと Codex に必ず指摘される

- **Failure**: 本 cycle で integration-verification rule を定義し、「dev-crew 内 real-path = gate/consumer/validator 実行、grep/diff のみは structural test」と明記した。しかし同 cycle の Verification section では `bash tests/test-*.sh` + `grep`/`diff` のみを書き、REFACTOR log で「`bash tests/test-*.sh` は real-path invocation」と記述。Codex code review BLOCK で「self-apply が満たされていない」と指摘。
- **Final fix**: Verification section に `bash scripts/validate-yaml-frontmatter.sh <cycle-doc>` を追加 (production path validator 実行、real-path invocation)。REFACTOR log も「#7 validator 実行が正式 real-path、`bash tests/test-*.sh` は structural」と整合修正。
- **Insight**: **rule を新設する cycle の Verification section に、同 rule で定義した real-path invocation pattern を含める self-apply が mandatory**。test script 実行は structural test であり rule 自身の定義では production path ではない。cycle 20260423_1045 Insight 3「file 内 self-apply mandatory」の拡張形 — rule を書く cycle の Verification section にも適用される。
- **一般化**: 新 rule を定義する cycle は、同 rule を書く場所 (rule file, template, skill docs) だけでなく、**cycle 自身の Verification section** にも self-apply を dogfood として要求すべき。plan phase で「本 cycle の Verification section に自作 rule を適用できるか」を事前チェックする checklist が必要。

### Insight 2: whole-file grep は WARN contract の regression 検出力が弱い — section-specific grep 標準化

- **Failure**: TC-10 初版は 4 orchestrate docs に対し whole-file `grep -qE "WARN.*real-path invocation"` で検査。file 内に unrelated WARN 文言があれば偽 PASS する design。Codex code review で「doc drift を防げない、VERIFY block/exact line に限定すべき」と指摘。
- **Final fix**: awk で `^####* .*VERIFY` heading から次 `####* ` heading までの block を抽出、その block 内で `grep -qE` 検査するよう section-specific 化。
- **Insight**: **structured doc の assertion は常に section-specific grep を使う**。cycle 20260423_0926 Insight 4 (section-specific grep > whole-file grep) の WARN contract 版。test-codify-rule-docs.sh の `section_grep` helper が既に存在するが、test-product-verify.sh は独自実装になっていたので再利用機会。今後 section-specific grep を必要とする test は `section_grep` helper を活用する規律を強化。
- **一般化**: whole-file grep は「1 箇所に含まれる」弱い assertion。structured doc (H2/H3 sections) に対しては section 抽出 → grep pattern が標準。0926 Insight 4 の反復再発を防ぐには test-patterns.md への codify が次 cycle の候補。

### Insight 3: 新 rule cycle の plan review は必ず「既存 doc への影響範囲 sweep」を BLOCK 検出対象にする

- **Failure**: sync-plan 時 scope = 6 files (rule + template + orchestrate SKILL.md + reference.md + mirror + test)。しかし orchestrate には SKILL.md 以外に steps-subagent/teams/codex.md という 3 つの mode-specific docs があり、すべて "silent skip" 記述を持っていた。Codex plan review BLOCK で「doc-consuming drift、同 class のバグ (cycle 1 .gitignore, cycle 2 doc-consuming test regression) に該当」と指摘。scope +4 file (3 steps + test-product-verify.sh) が必要だった。
- **Final fix**: scope を 10 files に拡大、3 steps + test-product-verify.sh を追加。
- **Insight**: **新 rule cycle では「rule を記述する主 doc」だけでなく「同じ concept を重複記述している他 doc」を sweep で列挙すべき**。orchestrate の場合、Block 2c.5 / VERIFY section が SKILL.md + steps-subagent + steps-teams + steps-codex の 4 箇所に存在 (DRY 違反)。この重複を知らないと「SKILL.md だけ更新 → 他 3 つと不整合」という drift を起こす。plan-discipline.md に「新 rule cycle は `grep -rlF '<既存概念>' skills/` で影響範囲 sweep 必須」を codify 候補 (次 cycle)。
- **一般化**: doc に concept が重複記述されている場合、1 箇所 update は他の箇所と drift する。新 rule/concept 導入時は「同 concept を記述している doc の sweep」が scope の一部。cycle 20260422_1313 Insight 1 (逆向き grep 契約) の doc 版。

### Insight 4 (observation、no-codify): Codex plan review BLOCK が 3 cycle 連続で scope 拡大を triggered

- **Observation**: cycle 20260423_0926 (plan scope +3)、cycle 20260423_1045 (plan scope +1)、本 cycle (plan scope +4) で Codex plan review BLOCK が scope 拡大を必ず triggered。これは Codex が plan の「明示されていない影響範囲」を検出する能力が安定していることを示す。累計 scope underestimation rate = 3/3 (100%)、plan review BLOCK の期待値は確立している。
- **Final fix**: N/A (observation)
- **Insight**: Codex plan review BLOCK は「plan を通さない拒否」ではなく「plan を広げる機会」として 3 cycle 連続で機能している。scope 拡大の invest を plan 段階で吸収する運用は定着。
- **一般化**: 2nd-order dogfood observation。rule 化して強制するものではないが、PdM の運用判断として BLOCK は常に scope 拡大で応答する方針を暗黙に共有。
