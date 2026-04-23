---
feature: discovered-followup-mirror-rules
cycle: 20260423_0926
phase: COMMIT
complexity: standard
test_count: 109
risk_level: low
retro_status: captured
codex_session_id: "019db7be-8fe9-7440-9ec8-a3fabf622646"
created: 2026-04-23 09:26
updated: 2026-04-23 10:30
---

# DISCOVERED 3 Items Follow-up (mirror + plan-discipline + test-patterns)

## Scope Definition

### In Scope
- [ ] `rules/` → `.claude/rules/` の 8 ファイル mirror (copy): 7 codified rule docs + state-ownership.md
- [ ] `rules/plan-discipline.md` に自動化 grep literal 推奨 + 出典追加
- [ ] `rules/test-patterns.md` に command substitution `||` pitfall 禁止事項 + 出典追加
- [ ] `tests/test-rules-mirror.sh` 新規作成 (mirror 完全性テスト + 明示 allowlist)
- [ ] `tests/test-codify-rule-docs.sh` に TC-11, TC-12 追加
- [ ] `tests/test-codify-insight.sh` TC-19 の hardcoded 108 → 109 bump (逆向きテスト契約)
- [ ] `docs/STATUS.md` test count 108 → 109 更新

### Out of Scope
- ROADMAP Step 1.5 (captured 可視化) の着手 (Reason: 本サイクルは cleanup のみ)
- `.claude/rules/post-approve.md` の rules/ への逆 mirror (Reason: Claude-specific ファイルは一方向 mirror の対象外)
- `skills/onboard/` の .claude/rules/ 一覧更新 (Reason: 「mirror all rules」方針の onboard 反映は別 cycle、DISCOVERED に計上)
- cycle 20260422_1313 Insight 5 の実装 (doc-mutations.md に cycle 参照 rule 追記、judgment-only record)

### Files to Change (target: 15 files — scope +5 from initial plan per Codex plan+code review)
- `.claude/rules/test-patterns.md` (new) — rules/ から copy
- `.claude/rules/plan-discipline.md` (new) — rules/ から copy
- `.claude/rules/agent-prompts.md` (new) — rules/ から copy
- `.claude/rules/multi-file-consistency.md` (new) — rules/ から copy
- `.claude/rules/review-triage.md` (new) — rules/ から copy
- `.claude/rules/doc-mutations.md` (new) — rules/ から copy
- `.claude/rules/skill-authoring.md` (new) — rules/ から copy
- `.claude/rules/state-ownership.md` (new) — rules/ から copy (Codex plan review で追加発覚)
- `rules/plan-discipline.md` (edit) — 自動化 grep literal 推奨 + 出典追加
- `rules/test-patterns.md` (edit) — `$(cmd||cmd)` pitfall 禁止事項 + 出典追加
- `tests/test-rules-mirror.sh` (new) — mirror 完全性テスト + 明示 allowlist (Claude-specific: post-approve.md)
- `tests/test-codify-rule-docs.sh` (edit) — TC-11, TC-12 追加 (section-specific grep で strict 化、Codex code review で強化)
- `tests/test-codify-insight.sh` (edit) — TC-19 hardcoded 108 → 109 bump (Codex plan review で regression 検出)
- `docs/STATUS.md` (edit) — test count 108 → 109
- `.gitignore` (edit) — `.claude/rules/` を un-ignore (Codex code review で mirror が git untracked の致命的 regression を検出、修正)

## Environment

### Scope
- Layer: Infrastructure (bash tests + markdown rules のみ)
- Plugin: N/A (言語非依存)
- Risk: 15 (PASS)

### Runtime
- Language: bash (shell scripts)

### Dependencies (key packages)
- N/A

### Risk Interview (BLOCK only)
- N/A

## Context & Dependencies

### Reference Documents
- `docs/cycles/20260422_1313_rule-docs-codify-followup.md` — 原典 3 項目の出典 (DISCOVERED/follow-up/no-codify)
- `CONSTITUTION.md` — mirror 方針 (AI 協働原則) の根拠
- `ROADMAP.md` — Step 1.5 着手前 cleanup として本サイクルを位置付け

### Dependent Features
- cycle 20260422_1313 の codify 結果: `rules/` に 7 rule docs が存在することが前提。本 cycle では追加で `rules/state-ownership.md` (既存) + 既存 3 (git-*/security) を含む全 11 ファイルを mirror 対象とする

### Related Issues/PRs
- PR #131 (cycle 20260422_1313_rule-docs-codify-followup) — 原典サイクル

## Test List

### TODO
- [ ] TL-1 (test-rules-mirror.sh TC-01): rules/*.md 各ファイルが .claude/rules/ に identical で存在する
- [ ] TL-1b (test-rules-mirror.sh TC-02): .claude/rules/ の extra ファイルは明示 allowlist (post-approve.md) のみ許可
- [ ] TL-2 (test-codify-rule-docs.sh TC-11): plan-discipline.md に「grep -rn」キーワードと cycle 1313 出典が存在する
- [ ] TL-3 (test-codify-rule-docs.sh TC-12): test-patterns.md の禁止事項に command substitution pitfall と cycle 1313 出典が存在する
- [ ] TL-4 (test-codify-insight.sh TC-19): Test Scripts | 109 に bump (逆向きテスト契約修正)
- [ ] TL-5 (metadata): STATUS.md の Test Scripts count が 109 になっている

### WIP
(none)

### DISCOVERED
- [ ] skills/onboard/ の .claude/rules/ 一覧を「mirror all rules」方針に更新 (Codex plan review 指摘、別 cycle)
- [ ] rules/doc-mutations.md に「rule 内 cycle 参照は full filename or cycle_id のみ」を追記 (cycle 1313 Insight 5 codified、judgment-only record)
- [ ] rules/doc-mutations.md に「GREEN collateral fix の即時 SSOT 同期」を追記 (cycle 1313 Insight 2 deferred の解消)
- [ ] rules/skill-authoring.md に「insight generalize 時は原文引用 + generalize 理由 1 行」を追記 (cycle 1313 Insight 3 deferred の解消)
- [ ] tests/test-rules-mirror.sh に TC-03 (CLAUDE_ONLY_FILES allowlist 自体の self-assertion) 追加 (test-reviewer optional 指摘)
- [ ] tests/test-rules-mirror.sh の nullglob edge case (空ディレクトリ時の偽陰性) 対応 (correctness-reviewer optional 指摘)

### DONE
(none)

## Implementation Notes

### Goal
`rules/` 全 11 ファイル (PR #131 codify 済み 7 + state-ownership.md + 既存 3) を `.claude/rules/` に mirror し、drift を自動検証するテストを追加する。同時に前サイクルで defer した 2 件の追記 (plan-discipline + test-patterns) を完了し、rule document 体系を完備させる。加えて Codex code review で発覚した `.gitignore` regression (.claude/ 配下が untracked) を修正し mirror を git 管理下に置く。

### Background
cycle 20260422_1313 で 23 insights を 7 rule documents に codify したが、3 件が DISCOVERED/follow-up として残存した:
1. `.claude/rules/` への mirror (本 cycle 実行時点で対象 8 ファイル: codify 済み 7 + state-ownership.md — copy + drift 防止テスト)
2. plan checklist 自動化 (grep literal 組込) — rules/plan-discipline.md 追記
3. `$(cmd || cmd)` command substitution pitfall — rules/test-patterns.md 追記

### Design Approach
- **Mirror 方式**: identical copy (`.claude/rules/` は Claude Code が直接参照するため rules/ と同一内容を保持)
- **drift 防止**: `tests/test-rules-mirror.sh` で `diff <(rules/X.md) <(.claude/rules/X.md)` を全ファイルに適用
- **one-way allowlist**: Claude-specific extras は明示 allowlist (`CLAUDE_ONLY_FILES=("post-approve.md")`) で列挙。`grep -v` 等のブラックリストは使わない (Codex plan review 指摘)
- **scope 完全性**: `rules/*.md` 全 11 ファイル (state-ownership.md 含む) を mirror 対象 (Codex plan review で発覚)
- **逆向きテスト契約**: STATUS.md test count bump (108→109) 時は `grep -rn "108" tests/` で hardcoded 参照を検出、test-codify-insight.sh TC-19 も同時更新 (Codex plan review で regression path 発覚 — 本 cycle の Insight 1 rule の dogfood 適用)
- **plan-discipline.md 追記**: 「推奨」セクションに grep literal 貼付ルール + `## 出典` セクションに cycle 1313 Insight 1 参照
- **test-patterns.md 追記**: 「禁止事項」セクションに command substitution `||` pitfall 説明 + `## 出典` セクションに cycle 1313 Insight 4 参照

## Verification

```bash
# 1. 全テスト実行
for f in tests/test-*.sh; do bash "$f"; done

# 2. mirror 完全性
bash tests/test-rules-mirror.sh

# 3. content 追記確認
bash tests/test-codify-rule-docs.sh

# 4. metadata 整合
grep -E "Test Scripts.*109" docs/STATUS.md

# 5. diff 確認
diff <(ls rules/*.md | xargs -n1 basename | sort) <(ls .claude/rules/*.md | xargs -n1 basename | grep -v post-approve | sort)
```

Evidence: (orchestrate が自動記入)

## Progress Log

### 2026-04-23 09:26 - KICKOFF
- Cycle doc created from plan: /Users/morodomi/.claude/plans/shimmying-swimming-orbit.md
- Design Review Gate (architect): PASS (score: 5)
- Codex plan review: **BLOCK** → 4 件指摘を反映して scope 拡大:
  1. state-ownership.md が mirror 対象に含まれていなかった → 追加 (mirror 8 ファイルに拡大)
  2. test-codify-insight.sh TC-19 の hardcoded 108 が regression path → scope に追加
  3. onboard skill docs の staleness → DISCOVERED に計上 (別 cycle)
  4. mirror allowlist が brittle (grep -v) → 明示 allowlist array に変更
- 修正後 scope: 13 files (+3 from initial plan)
- Phase completed (Codex review 反映済)

### 2026-04-23 09:35 - RED
- `tests/test-rules-mirror.sh` 新規作成 (TC-01/TC-02): TC-01 FAIL (8 files missing in .claude/rules/), TC-02 PASS
- `tests/test-codify-rule-docs.sh` TC-11/TC-12 追加: TC-11 FAIL (20260422_1313 出典未追加), TC-12 FAIL (command substitution pitfall 未追加)
- `tests/test-codify-insight.sh` TC-19 bump 108→109: TC-19 FAIL (STATUS.md が 108 のまま)
- RED 状態確認済み: test-rules-mirror.sh (PASS: 1, FAIL: 8), test-codify-rule-docs.sh (PASS: 10, FAIL: 2), test-codify-insight.sh (PASS: 19, FAIL: 1)

### 2026-04-23 09:45 - GREEN
- `rules/plan-discipline.md` 編集: 「推奨」セクションに grep literal 貼付ルール 2 件追加、`## 出典` に cycle 20260422_1313 Insight 1 追記
- `rules/test-patterns.md` 編集: 「禁止事項」に command substitution `||` pitfall 追加、「推奨」に `if/elif/else` 明示パターン追加、`## 出典` に cycle 20260422_1313 Insight 4 追記
- 8 ファイルを `rules/` → `.claude/rules/` に identical copy (agent-prompts, doc-mutations, multi-file-consistency, plan-discipline, review-triage, skill-authoring, state-ownership, test-patterns)
- `docs/STATUS.md` Test Scripts 108 → 109 更新
- test-rules-mirror.sh: PASS 2 / FAIL 0
- test-codify-rule-docs.sh: PASS 12 / FAIL 0
- test-codify-insight.sh: PASS 20 / FAIL 0
- 全テストスイート: FAIL 13 件 (全て pre-existing、新規 regression 0 件)

### 2026-04-23 09:55 - REFACTOR
- チェックリスト全項目で改善不要と判断 (詳細は以下)
  - 重複コード: pass/fail 関数の重複は bash test 慣例として許容
  - 定数化: BASE_DIR / RULES_DIR / CLAUDE_RULES_DIR / CLAUDE_ONLY_FILES 適切に定数化済み
  - メソッド分割: TC-01/TC-02 は独立ループで自己説明的、bash 関数化でかえって可読性低下リスクあり — 改善不要
  - 命名一貫性: has_skills32 / has_scripts109 形式で一貫
  - 出典 format: 両 rule doc とも `cycle YYYYMMDD_HHMM Insight N — 説明文` 形式で統一済み
  - self-apply: 禁止パターン (`$(cmd1 || cmd2)` fallback / `grep -i` case-insensitive) は test-rules-mirror.sh / TC-11 / TC-12 に混入なし
  - identical 契約: 全 11 ファイル diff ゼロ確認済み
- Verification Gate 全通過: test-rules-mirror.sh PASS 2/2, test-codify-rule-docs.sh PASS 12/12, test-codify-insight.sh PASS 20/20

### 2026-04-23 10:20 - REVIEW → GREEN RETRY (max 1 回)
- Codex code review: **BLOCK** (critical) + correctness/test-reviewer important findings
  - **BLOCK**: `.gitignore:3 .claude/` が mirror 全ファイルを untracked 化 (`git ls-files .claude/rules/` は post-approve.md のみ)。fresh clone/CI で reproducible でない致命的 regression
  - **Important (TC-11/12)**: fallback 条件 (rule を知っていても / Insight 4 / $(cmd1 || cmd2)) が assertion 意図を曖昧化、section 外の whole-file grep で偽 PASS のリスク
  - **WARN (doc drift)**: Files to Change (target: 13) 表記 vs 実 14 項目、Goal/Background が「7-file mirror」のまま scope 拡大を反映していない
  - Optional findings (nullglob / 変数名 / allowlist self-assertion) → 別 cycle へ defer
- 修正内容:
  - `.gitignore` `.claude/` → `.claude/*` + `!.claude/dev-crew.json` + `!.claude/rules/` に変更し mirror を tracking (15 files total)
  - TC-11/TC-12 を section-specific grep に強化: `section_grep` ヘルパを追加、「推奨」「禁止事項」「出典」セクションを awk で抽出して grep
  - cycle doc Goal/Background/Files count を整合 (15 files, 8-file mirror を明示)
- 修正後 Verification: test-rules-mirror.sh PASS 2/2、test-codify-rule-docs.sh PASS 12/12 (strict section grep 通過)、test-codify-insight.sh PASS 20/20、identical 契約 11/11
- git status 確認: `.claude/rules/*.md` 11 ファイルが untracked → tracked 候補に遷移済

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

抽出時刻: 2026-04-23 10:30
抽出方法: Cycle doc 全体 (plan / Codex plan review BLOCK / RED / GREEN / REFACTOR / Codex code review BLOCK → GREEN retry / re-review PASS) からの失敗→最終解→insight ペア抽出

### Insight 1: `.gitignore` 盲点 — 「ファイル作成 ≠ git 管理」の規律破綻

- **Failure**: GREEN phase で 8 mirror files を `.claude/rules/` に作成し、全 3 target テスト PASS + identical 契約 PASS + VERIFY 全 PASS を達成。しかし `.gitignore:3 .claude/` が mirror 全ファイルを ignore し、`git ls-files .claude/rules/` は post-approve.md 1 件のみ。fresh clone/CI で reproducible でない致命的 regression を「GREEN 完了」と誤認。Codex code review が `git ls-files` + `git check-ignore` で露呈させて BLOCK。
- **Final fix**: `.gitignore` を `.claude/*` + `!.claude/dev-crew.json` + `!.claude/rules/` に変更。既存 ignore 対象 (settings.local.json / scheduled_tasks.lock / agent-memory) は保持。mirror 11 ファイルが untracked に遷移、commit 可能状態に。
- **Insight**: **bash test PASS は git tracking を保証しない**。新規ファイル作成 cycle の GREEN Verification に `git status` + `git check-ignore` を必須化すべき。特に mirror/sync 系は `.gitignore` との相互作用を明示検証しないと false GREEN になる。今後: 新規ファイル作成系の meta-test で `git ls-files | grep -qF "<new_file>"` assertion を標準パターンに。
- **一般化**: file system 存在と git index 存在は独立 contract。両方を Verification Gate に含めないと GREEN は false positive。test suite が working tree 基準で動作する以上、git 側の確認を明示的に行う必要がある。

### Insight 2: rule を codify する cycle が同じ rule に再度違反した (2nd self-fail)

- **Failure**: 本 cycle は cycle 1313 Insight 1「自動化 grep literal を plan に貼れ」を `rules/plan-discipline.md` に codify することが目的の 1 つ。しかし plan phase で test count 108→109 bump に対し `grep -rn "108" tests/` を実行せず、test-codify-insight.sh TC-19 の hardcoded 108 regression を見逃した。Codex plan review が指摘し scope +1 file で修正。cycle 1313 の同じ self-fail が再発。
- **Final fix**: plan/cycle doc に test-codify-insight.sh TC-19 bump を scope 追加、GREEN で実装。Codex plan review が fallback として機能。
- **Insight**: **rule を codify する cycle 自身が、再度その rule に従わなかった** (cycle 1313 Insight 1 の 2 連続再発)。codify 済 rule を「読む」だけでは不十分。LLM の rule 適用は「意識した瞬間のみ有効」な fragile contract で、plan template に **count/state bump トリガで自動実行される grep literal セクション** がないと再発する。hook (e.g. PreCompact で「bump 系変更時は `grep -rn <old-value> tests/` 実行結果必須」を検査) を検討。
- **一般化**: rule を 2 連続で違反するのは偶発でなく構造的。rule 文書化 → 読む → 適用の 3 段で LLM は「読む」で止まる。自動化 (hook/必須フィールド/grep literal) がない rule は繰り返し破られる。Insight 1 の「文書化は必要条件、自動化は十分条件」が実証的に再確認された。

### Insight 3: plan review と code review は独立した検出力を持つ

- **Failure**: Codex plan review (BLOCK → 4 件指摘解消) で「OK」となり GREEN に進んだが、plan review は `.gitignore` 副作用を検出できない (plan 記述上は正しく、実装時の git 状態は plan review 時点では未発生)。GREEN 完了後の code review で初めて `git ls-files` ベース検査が可能になり、.gitignore 問題が露呈。
- **Final fix**: REVIEW phase を plan review と独立した gate として維持。GREEN retry で `.gitignore` 修正 + TC 強化 + cycle doc drift 修正。Codex re-review で PASS。
- **Insight**: **plan review と code review は独立検出力を持ち、両方必須**。plan review は設計整合性を、code review は実装副作用 (git / filesystem / config) を検出する。特に新規ファイル作成 cycle は code review で `git ls-files` / `git check-ignore` 検査が不可欠。competitive review を 2 段運用する設計の価値が定量的に確認された (本 cycle は plan review + code review の双方で異なる critical を検出)。
- **一般化**: review phase を省略すると、phase-specific にしか見えない副作用が commit まで生存する。両 phase で Codex competitive review を維持する運用方針は継続すべき。

### Insight 4: section-specific grep > whole-file grep (test assertion 強度の原則)

- **Failure**: TC-11/TC-12 初版は whole-file grep + 3 段 fallback 条件 (Insight 4 / $(cmd1 \|\| cmd2) / 20260422_1313) の組み合わせで、rule doc の構造化 section (推奨 / 禁止事項 / 出典) 内に literal が存在することを保証しなかった。test-reviewer + Codex code review が「assertion roulette」「future misplaced text で false positive」と指摘。
- **Final fix**: `section_grep` helper を test-codify-rule-docs.sh に追加。awk で `## 出典` / `## 禁止事項` / `## 推奨` を抽出後 `grep -cF` で literal を検査。fallback を削除し 1 TC = 1 section + 1 pattern に統一。
- **Insight**: **assertion は「該当 section 内に」「特定 literal が」存在することを検査すべき**。whole-file substring match + fallback alternatives は test smell。rule doc のような構造化テキストを検査する場合、section 境界を awk で抽出してから grep する pattern を標準化 (test-patterns.md 追加候補)。cycle B #1「whole-file grep で frontmatter state」と同系統の pitfall。
- **一般化**: 意図が「X 章に Y が書かれている」なら、テストも章を抽出してから検査する。section 境界を無視すると「本文に Y があれば PASS」というゆるい assertion になる。

### Insight 5: Cycle doc metadata drift は scope 変更時に構造的に発生する

- **Failure**: Codex plan review で scope +3 (state-ownership / TC-19 bump / onboard defer) を反映した際、Files to Change 表記 "target: 13" が残存し、Goal/Background の「7-file mirror」narrative も更新漏れ。Codex code review が再度指摘。更に GREEN retry で +2 (.gitignore / TC 強化) して 15 files になっても、narrative の更新を忘れかけた。
- **Final fix**: Files to Change count 13→15、Goal/Background を "11 ファイル mirror / 8-file mirror (state-ownership 含む)" に整合。
- **Insight**: **scope 変更は必ず 3 箇所 drift を誘発する** (Files list 本体 / 表題 count / Goal/Background narrative)。cycle doc の 1 箇所修正は残り 2 箇所を取りこぼす risk。将来: cycle doc linter で `Files to Change (target: N)` の N と listed items 数の整合、および narrative 内の古い N-file 表記残存を静的チェックする meta-test 追加候補。手動では毎 cycle で review 指摘が発生し続ける。
- **一般化**: scope 拡大時の文書修正は「1 箇所修正 = 残 2 箇所 drift」が定常的。count check + stale number grep は meta-test で自動化可能な機械的規律。

### Insight 6 (no-codify 候補): Codex plan review BLOCK は「良い BLOCK」

- **Observation**: Codex plan review が 4 件 BLOCK した内訳 (state-ownership 追加 / TC-19 regression / onboard staleness / allowlist 強化) はいずれも実装前に scope 修正できた critical 級。もし BLOCK を bypass していたら GREEN で再工数 (scope +3 file) が発生する状態。BLOCK は「plan を通さない拒否」ではなく「plan を良くする最後の機会」として機能した。
- **Final fix**: N/A (observation のみ)
- **Insight**: **Codex BLOCK は投資対効果が高い**。特に plan review の BLOCK は、GREEN で scope が +N file 発覚するより遥かに安価に修正できる段階での検出。BLOCK を回避する方向の対応ではなく、BLOCK 内容を scope 取り込みで吸収する運用が正解。
- **一般化**: 2nd-order dogfood observation (cycle 1313 Insight 6 と同系統)。rule 化して他 cycle に強制するものではないが、BLOCK 対応方針として暗黙に共有すべき。
