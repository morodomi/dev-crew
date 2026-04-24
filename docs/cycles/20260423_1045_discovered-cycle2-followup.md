---
feature: discovered-cycle2-followup
cycle: 20260423_1045
phase: COMMIT
complexity: standard
test_count: 109
risk_level: low
retro_status: resolved
codex_session_id: "019db7be-8fe9-7440-9ec8-a3fabf622646"
created: 2026-04-23 10:45
updated: 2026-04-24 09:00
---

# DISCOVERED 4 Items Follow-up (cycle 20260423_0926 派生)

## Scope Definition

### In Scope
- [ ] rules/doc-mutations.md に SSOT 即時同期 section 追加 (cycle 1313 Insight 2)
- [ ] rules/doc-mutations.md に Cycle 参照 format section 追加 (cycle 1313 Insight 5)
- [ ] rules/skill-authoring.md に Insight 引用の原則 section 追加 (cycle 1313 Insight 3)
- [ ] .claude/rules/doc-mutations.md を rules/ と identical mirror
- [ ] .claude/rules/skill-authoring.md を rules/ と identical mirror
- [ ] tests/test-rules-mirror.sh に TC-03 (allowlist self-assertion) + nullglob ガード追加
- [ ] tests/test-codify-rule-docs.sh に TC-13/TC-14/TC-15 追加 (TL-2/3/4)
- [ ] tests/test-codify-rule-docs.sh に TL-6 TC 追加 (onboard staleness 検証)
- [ ] skills/onboard/SKILL.md L76 を "mirror all rules" 表現に更新
- [ ] skills/onboard/reference.md L540/L547-549 を mirror all 方針に更新
- [ ] skills/onboard/validation.md L13-14 の git-safety/security hardcoded 2 行を汎用 mirror check に置換 (Codex plan review 指摘、真の stale 箇所)

### Out of Scope
- tests/test-onboard-validation.sh の git-safety/security 個別チェック更新 (DISCOVERED 計上、validation.md 側を正とし test は別 cycle で追従)

### Files to Change (target: 10, actual 10)
- `rules/doc-mutations.md` (edit)
- `rules/skill-authoring.md` (edit)
- `.claude/rules/doc-mutations.md` (edit)
- `.claude/rules/skill-authoring.md` (edit)
- `tests/test-rules-mirror.sh` (edit)
- `tests/test-codify-rule-docs.sh` (edit)
- `tests/test-onboard-research.sh` (edit) — TC-19 を mirror-all 方針に追従 (GREEN 後 full-suite 実行で cascade 4 ファイル regression が発覚、baseline restore)
- `skills/onboard/SKILL.md` (edit)
- `skills/onboard/reference.md` (edit)
- `skills/onboard/validation.md` (edit) — Codex plan review で追加発覚

Total: 10 files (at target)

## Environment

### Scope
- Layer: Infrastructure (rules + tests + skill docs)
- Plugin: N/A
- Risk: 15/100 (PASS)

### Runtime
- Language: bash (shell tests)

### Dependencies (key packages)
- N/A (doc/test edits only)

### Risk Interview (BLOCK only)
- N/A

## Context & Dependencies

### Reference Documents
- `docs/cycles/20260423_0926_discovered-followup-mirror-rules.md` — 前 cycle (直接原典、DISCOVERED 4 項目の発生源)
- `docs/cycles/20260422_1313_rule-docs-codify-followup.md` — cycle 1313 Insights 2, 3, 5 の原典
- `rules/doc-mutations.md` — 追記対象 rule file
- `rules/skill-authoring.md` — 追記対象 rule file
- `tests/test-rules-mirror.sh` — TC-03 追加対象
- `tests/test-codify-rule-docs.sh` — TC-13/14/15 + TL-6 TC 追加対象

### Dependent Features
- mirror 方針: PR #132 `feat/mirror-rules-and-followup` (未マージ)

### Related Issues/PRs
- PR #132: feat/mirror-rules-and-followup (本 cycle はこのブランチに追加 commit)

## Test List

### TODO
(none — all promoted to DONE)

### DONE
- [x] TL-1 (TC-03): allowlist self-assertion — CLAUDE_ONLY_FILES = ("post-approve.md") を bash tests/test-rules-mirror.sh で検証 → PASS
- [x] TL-2 (TC-13): doc-mutations.md SSOT 即時同期 section — "collateral fix" + "即時更新" キーワード + 出典 "20260422_1313" → PASS
- [x] TL-3 (TC-14): doc-mutations.md Cycle 参照 format section — "full filename" + "cycle_id" キーワード + 出典 "20260422_1313" → PASS
- [x] TL-4 (TC-15): skill-authoring.md Insight 引用の原則 section — "原文引用" + "generalize" キーワード + 出典 "20260422_1313" → PASS
- [x] TL-5 (TC-01 回帰): identical mirror 契約 — test-rules-mirror.sh TC-01 が全ファイル drift ゼロで PASS
- [x] TL-6a: skills/onboard/SKILL.md と reference.md で wording が一致 ("rules/*.md を .claude/rules/ に mirror" の forward 表現で統一、post-approve.md 混入を避ける) → PASS
- [x] TL-6b: skills/onboard/*.md の hardcoded 3-file enumeration ("git-safety, security, git-conventions") が 0 件 → PASS
- [x] TL-6c: skills/onboard/validation.md L13-14 の hardcoded "test -f .claude/rules/git-safety.md" "test -f .claude/rules/security.md" が 0 件 (汎用 mirror check に置換済み) → PASS

### WIP
(none)

### DISCOVERED
- [ ] rules/*.md 他 5 ファイル (agent-prompts, plan-discipline, review-triage, skill-authoring, test-patterns) に残存する informal cycle alias (eval-1..4 / A2b / Cycle B) を full filename or cycle_id に置換 (cycle 20260422_1313 Insight 5 / 本 cycle doc-mutations.md の Cycle 参照 format rule self-apply 違反、Codex code review WARN)
  - 計 24 occurrences: test-patterns.md 12 / plan-discipline.md 6 / review-triage.md 3 / skill-authoring.md 2 / agent-prompts.md 1
  - 別 cycle で sweep + 置換 + mirror copy を一括実施

### DONE
(none)

## Implementation Notes

### Goal
cycle 20260423_0926 (mirror-rules-and-followup) の DISCOVERED 4 項目を解消し、onboard staleness を修正する。PR #132 の同ブランチに追加 commit することで PR scope を完結させる。

### Background
- cycle 1313 で Insights 2, 3, 5 が deferred/codified-judgment-only 扱いで pending だった
- PR #132 の cycle 0926 で mirror 方針が確定、test-rules-mirror.sh を新設した際に 4 件の DISCOVERED が捕捉された
- cycle 0926 の Codex plan review #3 で onboard skill docs が stale 化した事実が指摘された

### Design Approach

**Item 1 + 2: rules/doc-mutations.md への 2 section 追加**

`## 推奨` の後に 2 つの H2 section を挿入し、`## 出典` に cycle 1313 参照を追加:
- `## SSOT 即時同期 (cycle 20260422_1313 #2)` — GREEN phase collateral fix は Cycle doc Files list も即時更新
- `## Cycle 参照 format (cycle 20260422_1313 #5)` — rule 内の cycle 参照は full filename prefix か cycle_id frontmatter 値を使う

**Item 3: rules/skill-authoring.md への 1 section 追加**

`## 出典` の前に H2 section を追加:
- `## Insight 引用の原則 (cycle 20260422_1313 #3)` — insight codify 時は元 Cycle doc 行番号を引用として明示

**Identical mirror 契約 (mandatory)**

Item 1-3 の rule 編集後、`.claude/rules/` に identical copy を即時反映。TC-01 で自動検証される。

**Item 4: tests/test-rules-mirror.sh 強化**

- TC-03 追加: `CLAUDE_ONLY_FILES` allowlist の size=1 かつ要素 "post-approve.md" を assert
- TC-01/TC-02 の for ループに `[ -e "$src_file" ] || continue` nullglob ガードを追加
- `shopt -s nullglob` は使わない (副作用あり)。既存 test-agents-structure.sh と同パターン

**Item 5: skills/onboard/ 更新 (wording 一貫化重要)**

全 3 ファイルで **forward direction** (`rules/*.md` を `.claude/rules/` に mirror) の表現に統一。reverse direction (`.claude/rules/*.md` を copy) は post-approve.md (Claude-only) を含んでしまい onboard scope と矛盾するため使わない。

- SKILL.md L76: `rules/: git-safety, security, git-conventions` → `rules/: 全 rules/*.md を .claude/rules/ に identical mirror`
- reference.md L540: 3-file list → `rules/*.md 全ファイルを .claude/rules/ へ mirror` (forward direction で統一)
- reference.md L547-549: 3 行テーブル → 汎用 1 行 (`rules/*.md` と identical mirror、drift は test-rules-mirror.sh で検出)
- validation.md L13-14: `test -f .claude/rules/git-safety.md` + `test -f .claude/rules/security.md` 2 行 → 汎用 1 行 (`for f in rules/*.md; do test -f ".claude/rules/$(basename $f)"; done` が全成功、or test-rules-mirror.sh 参照)

## Verification

```bash
# 1. 全テスト実行
for f in tests/test-*.sh; do bash "$f"; done

# 2. 新規 TC 単独
bash tests/test-rules-mirror.sh       # TC-01/02/03 PASS (2→3)
bash tests/test-codify-rule-docs.sh   # TC-01..15 PASS (12→15)

# 3. mirror 契約
for f in rules/*.md; do diff "$f" ".claude/rules/$(basename $f)"; done  # all empty

# 4. onboard staleness 解消確認
grep -c "git-safety, security, git-conventions" skills/onboard/SKILL.md skills/onboard/reference.md
# 期待: 0 (hardcoded list 削除済)

# 5. onboard mirror all 表現
grep -cF "rules/*.md" skills/onboard/SKILL.md skills/onboard/reference.md
# 期待: 各 1 件以上
```

Evidence: (orchestrate が自動記入)

## Progress Log

### 2026-04-23 10:45 - KICKOFF
- Cycle doc created from plan /Users/morodomi/.claude/plans/shimmying-swimming-orbit.md
- Design Review Gate (architect): PASS (score: 5)
- Codex plan review: **BLOCK** → 2 件指摘を反映して scope 拡大:
  1. validation.md L13-14 が真の stale 箇所 (test ファイルではない) → scope に追加
  2. SKILL.md ("rules/*.md" forward) vs reference.md ("`.claude/rules/*.md`" reverse) の wording 不整合 → forward direction で統一 (post-approve.md 混入防止)
- 修正後 scope: 9 files (+1 from initial)
- Branch: feat/mirror-rules-and-followup (PR #132 に追加 commit)
- Phase completed (Codex review 反映済)

### 2026-04-23 10:55 - RED
- tests/test-rules-mirror.sh: TC-03 (self-assertion) + nullglob ガード追加 → PASS 3/3 (TC-03 は permanent contract)
- tests/test-codify-rule-docs.sh: TC-13/14/15/16/17/18 追加 → PASS 12 / FAIL 6 / TOTAL 18
  - TC-13 FAIL: doc-mutations.md に SSOT 即時同期 section 未追加
  - TC-14 FAIL: doc-mutations.md に Cycle 参照 format section 未追加
  - TC-15 FAIL: skill-authoring.md に Insight 引用の原則 section 未追加
  - TC-16 FAIL: onboard/SKILL.md に "rules/*.md" glob 表記なし
  - TC-17 FAIL: onboard/*.md に "git-safety, security, git-conventions" 残存
  - TC-18 FAIL: validation.md に hardcoded git-safety/security 2 行残存
- RED state verified: 6 tests fail as expected

### 2026-04-23 11:10 - REFACTOR
- チェックリスト全 7 項目を評価: リファクタリング不要と判断
  1. 重複コード: `section_grep` helper 共通利用済み。TC-16 の直接 `grep -cF` は意図的差異
  2. 定数化: "git-safety, security, git-conventions" は stale 検出用 literal (意図的)
  3-6. 未使用 import / let→const / メソッド分割 / N+1: N/A (bash/doc)
  7. 命名一貫性: `count_*` 形式で統一。TC-11/12 の `_in_source` suffix 差異は pre-existing (テスト変更禁止)
- section header フォーマット `## <title> (cycle <id> #N)` が 3 section すべてで統一確認
- self-apply (Insight 3): 出典セクションに `原典 cycle + Insight 番号 + 一行要約` が 3 件全て引用済み確認
- identical 契約: rules/*.md 11/11 diff ゼロ確認
- wording 一貫性: onboard/SKILL.md + reference.md 共に forward direction (`rules/*.md` → `.claude/rules/`) 表現を確認
- Verification Gate: test-rules-mirror.sh PASS 3/3, test-codify-rule-docs.sh PASS 18/18, identical 11/11
- Phase completed

### 2026-04-23 12:20 - REVIEW (Codex code review)
- Codex code review: **WARN** (non-blocking)
  - Self-apply 違反: 本 cycle で codify した「Cycle 参照 format」rule (cycle doc の alias 禁止) に対し、同 rule doc 内の `## APPEND-ONLY 契約 (Cycle B #3)` と `## Plan File IMMUTABLE (Cycle B #4)` が informal alias を使っていた
  - Fix: `(Cycle B #3/4)` → `(cycle 20260422_1146 #3/4)` に置換、.claude/rules/ にも identical mirror
  - Sweep: 他 5 rule files (agent-prompts / plan-discipline / review-triage / skill-authoring / test-patterns) に計 24 occurrences の informal alias 残存 → scope 過大のため DISCOVERED 計上 (別 cycle で sweep)
- 他の Codex 指摘: `.claude/rules/` mirror identical / TC-03 + nullglob guards / section_grep reuse / onboard forward direction / TC-19 fix / hidden regression none — 全 clean
- Claude 側 review は test-reviewer / correctness-reviewer で triage 不要と判断 (doc/test edits のみ、Risk 15/100)
- Verification: test-codify-rule-docs.sh 18/18 / test-rules-mirror.sh 3/3 / 4 onboard cascade PASS / full-suite baseline restore は並行実行中
- Phase: REVIEW 完了、判定 WARN → PASS 相当 (fix 完了で残 BLOCK なし)

### 2026-04-23 11:50 - GREEN RETRY (full-suite regression fix)
- REFACTOR 後の full-suite baseline 実測で 11 件 new regression 発覚 (baseline 9 → 20)
  - 真の regression 1 件: test-onboard-research.sh TC-19 (reference.md 変更で "git-safety.*作成" パターンが hit しなくなった)
  - Cascade 3 件: test-onboard-agents-md.sh TC-13 / test-onboard-mode-detection.sh TC-11 / test-onboard-d1d2d3.sh TC-07/TC-08 (いずれも test-onboard-research.sh を invoke → 連鎖 FAIL)
  - Flaky 7 件: test-agents-md-count, test-agents-structure, test-cross-references, test-cycle-retrospective, test-designer-agent, test-api-contract-reviewer, test-architect-improvement (2nd run で PASS、CPU contention による timing flake)
- Fix: tests/test-onboard-research.sh TC-19 を mirror-all 方針に追従 (regex を `rules/\*\.md.*作成|identical mirror|test-rules-mirror\.sh` に更新)
- 修正後確認: test-onboard-research.sh / agents-md / mode-detection / d1d2d3 の 4 ファイル全て PASS
- scope +1 file: tests/test-onboard-research.sh を Files to Change に追加 (total 10)
- **Self-apply 警告**: 本 cycle の Goal に「onboard docs 更新」を含めた以上、onboard 関連テストも scope に予め含めるべきだった。sync-plan 時に `grep -rn "git-safety" tests/` を実行すれば事前検出可能

### 2026-04-23 11:05 - GREEN
- rules/doc-mutations.md: `## SSOT 即時同期 (cycle 20260422_1313 #2)` + `## Cycle 参照 format (cycle 20260422_1313 #5)` section 追加 + 出典 2 行追加 → TC-13/14 PASS
- rules/skill-authoring.md: `## Insight 引用の原則 (cycle 20260422_1313 #3)` section 追加 + 出典 1 行追加 → TC-15 PASS
- .claude/rules/doc-mutations.md + .claude/rules/skill-authoring.md: identical mirror (cp) → TC-01 回帰維持
- skills/onboard/SKILL.md L76: `rules/: rules/*.md を全て .claude/rules/ に identical mirror` 表現に更新 → TC-16 PASS
- skills/onboard/reference.md L540: 3-file list → `rules/*.md 全ファイルを .claude/rules/ に identical mirror` (forward direction) に更新 → TC-16 PASS
- skills/onboard/reference.md L547-549: 3 行テーブル → 汎用 1 行 (`rules/*.md` と identical mirror) に置換 → TC-17 PASS
- skills/onboard/validation.md L13-14: git-safety/security 個別 2 行 → 汎用 mirror check 1 行 (L5: test-rules-mirror.sh 参照) に置換、#6/#7 を #6/#7 に番号整理 → TC-17/18 PASS
- test-codify-rule-docs.sh: PASS 18/18 (FAIL 0) ← 6 tests promoted from RED
- test-rules-mirror.sh: PASS 3/3 (TC-01 identical mirror 契約維持)
- test-onboard-validation.sh: PASS 5/5 (regression なし)
- diff rules/*.md .claude/rules/*.md: 全 11 ファイル差分ゼロ確認

---

## Next Steps

1. [Done] KICKOFF
2. [Done] RED
3. [Done] GREEN (+ RETRY)
4. [Done] REFACTOR
5. [Done] REVIEW
6. [Next] COMMIT
7. [ ] DONE

## Retrospective

抽出時刻: 2026-04-23 12:30
抽出方法: Cycle doc 全体 (plan / Codex plan review BLOCK #1 / RED / GREEN / REFACTOR / full-suite baseline 発覚 GREEN RETRY / Codex code review WARN + self-apply fix) からの失敗→最終解→insight ペア抽出

### Insight 1: REFACTOR Verification Gate が target tests のみで full suite を確認していない

- **Failure**: REFACTOR phase 完了時、Verification Gate で 3 target tests (test-rules-mirror/test-codify-rule-docs/test-codify-insight) + identical 契約 11/11 のみ確認し「PASS」と判定。その後の full-suite baseline 実測で 11 件 new regression を発覚 (baseline 9 → 20)。真の regression は 1 件 (test-onboard-research.sh TC-19)、cascade 4 件、flaky 6 件の内訳。
- **Final fix**: GREEN RETRY で test-onboard-research.sh TC-19 を mirror-all 方針に追従 (`"git-safety.*作成"` → `"rules/\*\.md.*作成|identical mirror|test-rules-mirror\.sh"`)。4 onboard cascade tests 全 PASS。baseline 9 復元。
- **Insight**: **REFACTOR の Verification Gate は target tests では不十分、全 tests/test-*.sh の baseline regression check を必須化すべき**。特に doc 変更を含む cycle は、doc-consuming test が hidden cascade を引き起こす。今回は test-onboard-research.sh が reference.md content を直接 grep で検査していたため、我々の書換で該当 regex が外れた。現行 refactor skill の「Tests PASS」文言が LLM に狭く解釈された (target のみ = PASS と判定)。
- **一般化**: Verification Gate 定義は subject (target or full suite) を明示すべき。「Tests PASS」は曖昧で safety 低い。doc 変更 cycle の規律として、REFACTOR 後に `for f in tests/test-*.sh; do bash "$f"; done` で full baseline 比較を要求する運用を標準化。

### Insight 2: doc を変更する cycle は「doc-consuming test」を plan 段階で逆検索すべき

- **Failure**: sync-plan 時 scope = 「rule 追記 + onboard docs 更新 + test 強化 (新 TC)」と定義したが、既存テスト (test-onboard-research.sh TC-19) が onboard reference.md の content literal を grep で検査する hidden dependency を認識していなかった。plan review (architect + Codex) も doc 変更側の整合性は check したが「doc を参照する既存 test の regression 可能性」は評価対象外。GREEN 後 full-suite baseline で初めて露呈。
- **Final fix**: GREEN RETRY で tests/test-onboard-research.sh を scope に追加、TC-19 regex を新 design に追従。
- **Insight**: **「変更する doc」と「変更する doc を参照する test」は plan 段階で同時列挙すべき**。cycle 20260422_1313 Insight 1 の逆向きテスト契約 (count/state bump 時の `grep -rn "<old-value>" tests/`) の doc 版が必要。今回でいえば sync-plan 時に `grep -rn "git-safety" tests/` を実行していれば事前検出可能だった。plan-discipline.md 追加候補 (次 cycle、DISCOVERED)。
- **一般化**: doc の content に依存する test は hidden dependency。doc 変更系 cycle は "grep -rn <keyword from old doc content> tests/" を plan の scope addition checklist に含める。cycle 1313 Insight 1 の応用範囲を doc 変更まで拡大。

### Insight 3: 新 rule を codify する cycle は同 rule の file 内 self-apply が必須

- **Failure**: 「Cycle 参照 format」rule (「rule 内 cycle 参照は full filename or cycle_id、informal alias 禁止」) を rules/doc-mutations.md に新設したが、同ファイル内の既存 H2 header `## APPEND-ONLY 契約 (Cycle B #3)` と `## Plan File IMMUTABLE (Cycle B #4)` が新 rule 違反のまま。Codex code review WARN で発覚。他 5 rule files (test-patterns/plan-discipline/review-triage/skill-authoring/agent-prompts) にも計 24 occurrences の informal alias 残存。
- **Final fix**: doc-mutations.md 内の 2 H2 を `(cycle 20260422_1146 #3)` / `(cycle 20260422_1146 #4)` に置換、.claude/rules/ にも mirror。他 5 files (24 occurrences) は scope 過大のため DISCOVERED 計上。
- **Insight**: **新 rule を codify する cycle は、少なくとも「rule を書いた file 内」の既存 content への self-apply (compliance 修正) を mandatory に含める**。broader sweep (他 rule files) は defer 可能だが、file 内 self-apply を skip すると「rule が書いてあるファイル自身が rule 違反」という矛盾が発生する。Codex competitive review が検出する前提ではなく、PdM として codify 時の default checklist にすべき。cycle 1313 Insight 6 / cycle 20260423_0926 Insight 6 の 2nd-order dogfood の延長: self-apply scope の明示が必要。
- **一般化**: 新 rule 追加は「新 section の追記」だけでなく「既存 content の compliance 検査 + 修正」も自動的に scope 扱いすべき。最小限: rule を追記する file 内。optional: repo-wide sweep。

### Insight 4 (observation、no-codify 候補): cascade 連鎖検出は full-suite baseline のみで可視化できる

- **Observation**: test-onboard-research.sh TC-19 の 1 件 regression が test-onboard-agents-md / onboard-mode-detection / onboard-d1d2d3 に連鎖して計 4 cascade となった。target test だけの検証では連鎖の全貌が見えず、full-suite baseline 実測で初めて 4 件が同一根源と分析できた。また同タイミングで 7 件の flaky (CPU contention timing 起因) も一時的に FAIL 状態になっていた。
- **Final fix**: N/A (observation のみ)
- **Insight**: full-suite baseline 実測は「真の regression + cascade + flaky」の 3 要素を同時に露呈させる。個別 test 実行では flaky は偶発的に PASS し、cascade は根源 test しか見えない。sync-plan / REFACTOR / REVIEW の各 gate で full-suite baseline を取得する投資は、cascade 分析と flaky 識別のためにも正当化される。
- **一般化**: test の健全性は個別 PASS ではなく suite-level 統計 (FAIL 件数の時系列比較) で評価すべき。observation として蓄積、actionable rule 化の判断は dogfood 再現が複数 cycle で得られた段階。

## Codify Decisions

autonomous batch triage (cycle 20260424 integration-verification-rule cycle 起動時)。recurrence scan: 全 insight 初出 (novel)、recurrence 0-1。

### Insight 1
- **Decision**: codified
- **Destination**: rule (plan-discipline.md)
- **Reason**: REFACTOR Verification Gate を full-suite baseline 必須化する規律。plan-discipline.md の既存「逆向きテスト契約 / 事前 grep」系と同族。judgment-only record、実装は refactor skill 変更を伴う別 cycle
- **Decided**: 2026-04-24 09:00

### Insight 2
- **Decision**: codified
- **Destination**: rule (plan-discipline.md)
- **Reason**: 「doc 変更 cycle は doc-consuming test を plan 段階で grep 逆検索」を plan-discipline.md に追記。cycle 20260422_1313 Insight 1 (逆向きテスト契約) の doc 版として明記。judgment-only record
- **Decided**: 2026-04-24 09:00

### Insight 3
- **Decision**: codified
- **Destination**: rule (skill-authoring.md)
- **Reason**: 「新 rule codify は書いた file 内の self-apply mandatory」を skill-authoring.md に追記。cycle 20260422_1313 Insight 3 (原文引用) の範囲拡大。judgment-only record
- **Decided**: 2026-04-24 09:00

### Insight 4
- **Decision**: no-codify
- **Reason**: 元から observation marked。full-suite baseline の価値は既に Insight 1 で codify 済、重複回避
- **Decided**: 2026-04-24 09:00
