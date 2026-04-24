---
feature: discovered-debt-cleanup
cycle: 20260424_1119
phase: COMMIT
complexity: standard
test_count: 6
risk_level: low
retro_status: captured
codex_session_id: "019dbd4e-b160-7450-b3cf-141978b8217a"
created: 2026-04-24 11:19
updated: 2026-04-24 12:02
---

# DISCOVERED 3 項目 debt 解消 cycle

## Scope Definition

### In Scope

- [ ] `skills/careful/SKILL.md` に `allowed-tools:` (空値) 追加 — hook-only skill の convention 一致
- [ ] 4 worker agents (sync-plan / green-worker / red-worker / refactorer) の `model:` frontmatter audit → 全て既存のため記録のみ (no-code-change)
- [ ] 5 rule files × 2 (rules/ + .claude/rules/ mirror) 計 24 occurrences の informal alias sweep
  - `eval-1` → `20260421_1043`, `eval-2` → `20260421_1809`, `eval-3` → `20260421_2342`, `eval-4` → `20260422_0937`, `Cycle B` → `20260422_1146`, `A2b` → `20260420_1752`

### Out of Scope

- doc-mutations.md への適用 (前 cycle 20260423_0926 で resolved 済)
- 他 rule files (informal alias 0 件確認済)
- セマンティクス変更・ロジック変更

### Files to Change (target: 11 — mirror 契約で 5×2 + skill 1)

**rules/ (authoritative)**
- `rules/agent-prompts.md` (edit, 1 occurrence)
- `rules/plan-discipline.md` (edit, 6 occurrences)
- `rules/review-triage.md` (edit, 3 occurrences)
- `rules/skill-authoring.md` (edit, 2 occurrences)
- `rules/test-patterns.md` (edit, 12 occurrences)

**.claude/rules/ (mirror)**
- `.claude/rules/agent-prompts.md` (edit)
- `.claude/rules/plan-discipline.md` (edit)
- `.claude/rules/review-triage.md` (edit)
- `.claude/rules/skill-authoring.md` (edit)
- `.claude/rules/test-patterns.md` (edit)

**skill frontmatter**
- `skills/careful/SKILL.md` (edit, 1 line insert)

Total: 11 files (target 10 超過 justified: mirror 契約必然 + 分割不能)

## Environment

### Scope
- Layer: Infrastructure (rule docs + skill frontmatter)
- Plugin: N/A (workflow 横断)
- Risk: **18 / 100 (LOW)**
  - scope: string replacement (no semantics change)
  - blast radius: 11 files、全て doc/config
  - test coverage: mirror 契約 + rule 構造検証で自動検出
  - reversibility: 完全 (git revert)

### Runtime
- Language: Bash (tests), Markdown (rules/skills)
- Dependencies: N/A

## Context & Dependencies

### Reference Documents

- `.claude/rules/doc-mutations.md` "Cycle 参照 format (cycle 20260422_1313 #5)" — 「informal 略称は永続 artifact では使わない」rule の self-apply
- `.claude/rules/skill-authoring.md` "Insight 引用の原則 (cycle 20260422_1313 #3)" — `#N` 番号は原文維持
- `tests/test-rules-mirror.sh` — TC-01 mirror 契約 (rules/ ↔ .claude/rules/ 整合)

### Baseline 実測結果 (plan 作成前)

| 項目 | 実測値 |
|------|--------|
| rules/ informal alias 件数 | **25 件** (内訳: doc-mutations.md L31 の rule 説明文 1件 [= 例示、sweep 対象外] + 他 5 files 24件 [sweep 対象]) |
| .claude/rules/ informal alias 件数 | 同一 (mirror) |
| tests/ 内 informal alias 出現 | 12 occurrences across 6 files — 全て**コメント・echo・historical reference** (例: `# for v2.7 Agile Loop Cycle A2b`)、test assertion や逆向き契約は**0 件** (scope 外) |
| worker agents model: 存在 | 4/4 全て確認済 |
| careful SKILL.md allowed-tools: | 不在 → 要追加 |

### Scope 境界の明確化 (Codex plan review BLOCK 対応)

Codex plan review で以下の 2 点を指摘された:
1. `grep -c "Cycle B\|eval-[0-9]\|A2[ab]" rules/*.md` の総計は **25** (plan 記述の 24 は doc-mutations.md を除外した数値だが、除外理由を明記すべき)
2. `grep -rn "...alias..." tests/` は **0 件ではない** (12 occurrences across 6 files)

**回答 (scope 精密化)**:
- doc-mutations.md L31 の `(eval-N、A2b、Cycle B)` は「これら略称を永続 artifact で使うな」という **rule 説明文の例示** であり、sweep 対象ではない (skill-authoring.md "Insight 引用の原則" の原文維持条項にも準拠)
- tests/ 内 12 occurrences は全て test コメント・echo 文言で、過去 cycle の historical reference として意図的に保持されている (test assertion や 逆向き契約には一切関与しない)
- 本 cycle の sweep 対象は **5 rule files × 2 mirror = 10 files、計 24 → 0 occurrences**。rule 本文の inline tag のみ。
- TL-3/TL-4 の 0 件 assertion は「対象 5 files のみ」に scope 限定する (grep path を `rules/{agent-prompts,plan-discipline,review-triage,skill-authoring,test-patterns}.md` に明示)

### Alias Mapping

| alias | full cycle prefix |
|-------|------------------|
| `eval-1` | `20260421_1043` |
| `eval-2` | `20260421_1809` |
| `eval-3` | `20260421_2342` |
| `eval-4` | `20260422_0937` |
| `Cycle B` | `20260422_1146` |
| `A2b` | `20260420_1752` |

### Dependent Features

- mirror 契約: `tests/test-rules-mirror.sh` TC-01 が rules/ ↔ .claude/rules/ 整合を自動検証
- SKILL.md 100 行制限: careful は現在 33 行 → 1 行追加でも safe

### Related DISCOVERED Items

- cycle 20260423_0926: careful allowed-tools 欠落 → 本 cycle で解消
- cycle 20260423_0926: worker agents model 欠落 → 実測で既存確認、記録のみ
- cycle 20260422_1313 Insight 5 (doc-mutations.md rule): informal alias sweep 持ち越し 2 cycle 目

## Test List

### TODO

- [ ] **TL-1**: `bash tests/test-rules-mirror.sh` — mirror 契約 (rules/ ↔ .claude/rules/ 整合) 回帰。全 5 files で同一置換されていること
- [ ] **TL-2**: `bash tests/test-codify-rule-docs.sh` — rule 構造検証 (H2 sections + key phrase) 回帰。置換が本文構造を破壊しないこと
- [ ] **TL-3**: alias 残留検査 (rules/) — `grep -E "Cycle B|eval-[0-9]|A2[ab]" rules/agent-prompts.md rules/plan-discipline.md rules/review-triage.md rules/skill-authoring.md rules/test-patterns.md` が **0 件** (対象 5 files のみ、doc-mutations.md 例示行は scope 外)。`-E` mode では `|` が alternation (escaped `\|` 使用禁止)
- [ ] **TL-4**: alias 残留検査 (.claude/rules/) — 同 5 files の mirror 側で同 `grep -E` で **0 件**
- [ ] **TL-5**: `grep -q "^allowed-tools:" skills/careful/SKILL.md` — allowed-tools: 行存在 assertion
- [ ] **TL-6**: worker agents model: assertion — `for f in agents/{sync-plan,green-worker,red-worker,refactorer}.md; do grep -q "^model: " "$f"; done` (baseline 回帰 guard)

### WIP

(none)

## Verification

```bash
# 1. mirror gate (real-path invocation)
bash tests/test-rules-mirror.sh; echo "mirror rc=$?"

# 2. rule 構造 gate
bash tests/test-codify-rule-docs.sh; echo "codify-rule-docs rc=$?"

# 3. full baseline
for f in tests/test-*.sh; do
  bash "$f" >/dev/null 2>&1
  rc=$?
  [ $rc -ne 0 ] && echo "FAIL: $(basename $f) rc=$rc"
done

# 4. alias 残留確認 (expected: 0 lines) — 対象 5 files のみ (doc-mutations.md 例示行は scope 外)
SWEEP_FILES="agent-prompts.md plan-discipline.md review-triage.md skill-authoring.md test-patterns.md"
for f in $SWEEP_FILES; do
  grep -E "Cycle B|eval-[0-9]|A2[ab]" "rules/$f" ".claude/rules/$f"
done | wc -l

# 5. careful skill allowed-tools 存在確認 (expected: 1 line)
grep -c "^allowed-tools:" skills/careful/SKILL.md

# 6. worker agent model 存在確認 (expected: 4 lines)
for f in agents/sync-plan.md agents/green-worker.md agents/red-worker.md agents/refactorer.md; do
  grep "^model:" "$f"
done | wc -l
```

## Progress Log

### KICKOFF (2026-04-24 11:19)

- Plan file: `/Users/morodomi/.claude/plans/1-precious-hammock.md`
- Design Review Gate: **PASS** (score: 5)
  - Files 11 > 10 (+5): mirror 契約必然、justification 明記で許容
  - Architecture: 既存 convention 準拠 (worker agents model: 全確認済)
  - Test List: TL-1〜TL-6 全カテゴリ網羅
  - Risk 18/100: スコープと整合
- Baseline 実測: rules/ 25 occurrences (doc-mutations.md 1件除外 → sweep 対象 24件)、tests/ 逆向き契約 0件
- Worker agents model: 4/4 全て `model: sonnet` 確認済 → no-code-change 確定
- 次フェーズ: /orchestrate → plan-review → RED → GREEN → REFACTOR → REVIEW → COMMIT

### Plan Review (Codex #1: BLOCK → 2026-04-24 11:25)

- Codex session: `019dbd4e-b160-7450-b3cf-141978b8217a`
- **BLOCK 理由 (2 点)**:
  1. `grep -c ... rules/*.md` 総計 **25** (plan 記述 24 は doc-mutations.md を除外した数値、除外理由が plan 本文に不明瞭)
  2. `grep -rn ... tests/` 結果は **0 件ではない** (6 files 12 occurrences)
- **対応**: Cycle doc (SSOT) の baseline セクションに scope 境界を明記。plan file は IMMUTABLE 維持 (`.claude/rules/doc-mutations.md` L13-17)。TL-3/TL-4 の grep path を対象 5 files に明示限定 (`doc-mutations.md` 例示行は scope 外、tests/ は historical reference で scope 外)。

### Plan Review (Codex #2: BLOCK → 2026-04-24 11:32)

- Codex session: `019dbd4e-b160-7450-b3cf-141978b8217a` (resume)
- **BLOCK 理由**: Verification section step 4 の `grep -rn ... rules/ .claude/rules/` が broad grep のままで doc-mutations.md 例示行を拾う → SSOT 内で self-contradict
- **対応**: step 4 を `SWEEP_FILES` loop に変更し、対象 5 files × 2 mirror のみに限定

### Plan Review (Codex #3: BLOCK → 2026-04-24 11:35)

- **BLOCK 理由**: TL-3/TL-4 で `grep -E "...\|..."` とエスケープしたため `-E` mode で `\|` がリテラル `|` 扱いとなり alternation が効かない (実測 rc=1 = no match、意図しない成功)
- **対応**: TL-3/TL-4 の grep を `grep -E "Cycle B|eval-[0-9]|A2[ab]"` (non-escaped) に修正。`-E` mode での `|` alternation 使用を明記

### Plan Review (Codex #4: APPROVED → 2026-04-24 11:36)

- **verdict**: APPROVED
- Codex の 3 回 BLOCK を通じて以下を精密化:
  - #1: rules/ 25件の内訳 (doc-mutations.md 例示 vs sweep 対象) / tests/ historical reference 明記
  - #2: Verification step 4 を scoped loop 化
  - #3: `grep -E` の pipe を non-escaped alternation に修正
- 4 回目で APPROVED。3 cycle 連続の Codex BLOCK パターン (cycle 20260424_0900 Insight 4 2nd-order observation) を本 cycle でも踏襲

### RED (2026-04-24)

- テストファイル作成: `tests/test-discovered-debt-cleanup.sh`
- TC-01: FAIL (rules/ 対象 5 files に informal alias 24 件残存) — RED 確認
- TC-02: FAIL (.claude/rules/ 対象 5 files に informal alias 24 件残存) — RED 確認
- TC-03: FAIL (skills/careful/SKILL.md に allowed-tools: 行が存在しない) — RED 確認
- TC-04: PASS (全 4 worker agents に model: 行が存在する) — baseline regression guard
- TL-1 回帰: `test-rules-mirror.sh` PASS (3/3) — 既存テスト baseline 維持
- TL-2 回帰: `test-codify-rule-docs.sh` PASS (19/19) — 既存テスト baseline 維持
- RED 状態検証: TC-01/02/03 FAIL、TC-04 PASS (期待通り)

### GREEN (2026-04-24 13:10)

- TC-01 PASS: rules/ 対象 5 files informal alias sweep 完了 (24 → 0 occurrences)
  - `rules/agent-prompts.md`: `(eval-2 #1, A2b #2)` → `(cycle 20260421_1809 #1, cycle 20260420_1752 #2)`
  - `rules/plan-discipline.md`: 6 occurrences (eval-1/2/4 + Cycle B + A2b) 全て置換完了
  - `rules/review-triage.md`: 3 occurrences (eval-3, Cycle B, eval-4) 全て置換完了
  - `rules/skill-authoring.md`: 2 occurrences (A2b, Cycle B) 見出し含め置換完了
  - `rules/test-patterns.md`: 12 occurrences (eval-1〜4 + Cycle B) 全て置換完了
- TC-02 PASS: .claude/rules/ 同 5 files mirror 側に同一置換適用完了
  - mirror 整合: `test-rules-mirror.sh` PASS (3/3) — rules/ ↔ .claude/rules/ identical 確認
- TC-03 PASS: `skills/careful/SKILL.md` frontmatter に `allowed-tools:` 行を `description:` 行の次に追加
- TC-04 PASS: worker agents model: 全 4 files baseline 回帰 guard (no-change 確認)
- TL-2 回帰: `test-codify-rule-docs.sh` PASS (19/19) — rule 構造に影響なし
- full-suite: `test-directory-structure.sh` TC-DS03 FAIL (pre-existing: 20260421_2342_agents-md-count-fix.md の cycle/created/updated フィールド欠落) — 本 cycle scope 外

### REFACTOR (2026-04-24 11:47)

- **対象**: `tests/test-discovered-debt-cleanup.sh` のみ (rule docs/skill frontmatter は string-replacement のため refactor 対象外)
- **Checklist driven**:
  - #1 重複コード: TC-01/TC-02 の count logic 重複 → `count_alias_in_dir()` helper 関数抽出 (DRY)
  - #2 定数化: `ALIAS_PATTERN` 定数化 (`Cycle B|eval-[0-9]|A2[ab]`)
  - #3-#4 (N/A, bash), #5 メソッド分割: count 処理を関数へ
  - #6 (N/A), #7 命名一貫性: `count_alias_in_dir` は snake_case (既存 test convention)
  - TC-03/TC-04 の冗長な `: # ok` / 空条件を簡素化 (`[ -z "$output" ]` 統一)
- **Verification Gate PASS**:
  - `test-discovered-debt-cleanup.sh`: 4/4 PASS (refactor 後も全 TC PASS)
  - `test-rules-mirror.sh`: 3/3 PASS (mirror 整合維持)
  - `test-codify-rule-docs.sh`: 19/19 PASS (rule 構造維持)
  - full-suite baseline: `test-directory-structure.sh` TC-DS03 FAIL のみ (pre-existing、scope 外)
- Phase completed

### VERIFY (2026-04-24 11:47)

Product Verification (real-path invocation, rules/integration-verification.md self-apply):

1. `bash tests/test-rules-mirror.sh` → PASS 3/3 (real-path consumer 実行)
2. `bash tests/test-codify-rule-docs.sh` → PASS 19/19
3. Alias sweep assertion (対象 5 files × 2 mirror): **0 occurrences**
4. `skills/careful/SKILL.md` allowed-tools 行存在: **1 行**
5. Worker agents model: 存在: **4/4**
6. `bash scripts/validate-yaml-frontmatter.sh <changed-files>`: no error (real-path validator 実行)

Advisory evidence 全 PASS。integration-verification rule 自己適用を dogfood で確認。

### REVIEW (2026-04-24 11:55)

- **Risk Classification**: classifier 出力 `HIGH score:120` (auth/security keyword 部分一致 false positive — `skill-authoring` の "auth" matching)。実質 risk は plan 時点の **18/100 (LOW)** 維持 (doc-only edits、semantics 変更なし)
- **Review Coverage** (Risk-based scaling per rules/review-triage.md):
  - **Codex competitive review**: 2 round
    - #1 BLOCK: `tests/test-discovered-debt-cleanup.sh` と `docs/cycles/20260424_1119_discovered-debt-cleanup.md` が untracked (`??`) → `git diff HEAD` に含まれず commit から抜け落ちるリスク
    - #2 APPROVED (findings: []): `git add` で 2 files stage 後、mirror diff 空 / test 全 PASS / validator OK を確認
  - **Claude correctness-reviewer**: API 529 Overloaded で fail → Codex thorough review (mirror diff/frontmatter validator/test execution/file-tracking check) を primary coverage とみなす。review-triage.md "trivial scope で Claude correctness skip 可" の準用
- **3-category findings triage**:
  - accept-apply: Codex #1 指摘の untracked file staging → 本 cycle 内で `git add` 実施済
  - accept-defer: なし
  - reject: なし
- **verdict**: PASS (advisory 評価 LOW、Codex APPROVED)
- Phase completed

### DISCOVERED

- [ ] cycle `20260421_2342_agents-md-count-fix.md` の frontmatter に `cycle/created/updated` field 欠落 → `test-directory-structure.sh TC-DS03` FAIL の原因 (pre-existing、本 cycle sweep 対象外)。別 cycle で frontmatter backfill 推奨
- [ ] `docs/cycles/*.md` 内 title や body にも informal alias (`eval-3`, `eval-4` 等) が存在 (例: cycle 20260421_2342 の title `AGENTS.md agent count 整合 (eval-3)`)。rule 本文 sweep の scope 外だったが、doc-mutations.md rule の精神は cycle doc にも適用され得る。別 cycle で sweep 検討
- [ ] `risk-classifier.sh` で `skill-authoring.md` が auth keyword 部分一致で false-positive HIGH 判定 (+25)。word boundary か negative lookahead で精密化推奨
- [ ] cycle 20260424_0900 codify 決定 (Insight 1/2/3) の rule file への実装 (inline-update to integration-verification.md, test-patterns.md, plan-discipline.md) が本 cycle では行われず、judgment-only record のみ。次 cycle で実装

### DONE

- [x] careful skill の allowed-tools frontmatter 追加 (cycle 20260423_0926 DISCOVERED 解消)
- [x] 4 worker agents model frontmatter audit → 既存確認のみ (cycle 20260423_0926 DISCOVERED 解消)
- [x] 5 rule files × 2 mirror 計 24 occurrences の informal alias sweep (cycle 20260422_1313 Insight 5 持ち越し 2 cycle 目、解消)

## Retrospective

抽出時刻: 2026-04-24 11:55
抽出方法: Cycle doc 全体 (plan / sync-plan / Codex plan review #1-#4 / RED / GREEN / REFACTOR / VERIFY / Codex code review #1-#2) からの失敗→最終解→insight ペア抽出

### Insight 1: baseline 実測の「除外数値の理由」は plan 本文に明記必須

- **Failure**: plan 作成時 `rules/ informal alias 件数 24件` と書いたが、これは `doc-mutations.md` の例示 1 件を除外した数値。除外理由 (rule 説明文の例示なので sweep 対象外) を plan 本文に明記せず、総計 25 件との乖離を Codex plan review #1 で指摘され BLOCK。同じ文脈で `tests/ 内逆向き契約 0 件` も書いたが、実際は 12 occurrences (historical reference) が存在し、これも除外理由明記なしで BLOCK。
- **Final fix**: Cycle doc (SSOT) の baseline table に「25 件 (doc-mutations.md 1件 = 例示、除外) + 他 5 files 24件 (sweep 対象)」のように **内訳 + 除外理由** を明記。tests/ も「12 occurrences は全て historical reference、test assertion ゼロ」と明記。plan file は IMMUTABLE 維持 (doc-mutations.md L13-17)。
- **Insight**: **pattern-based grep の baseline 数値は「何を含め、何を除くか」を明記する**。特に 1) 除外する occurrences の category (例示/historical reference/etc) と、2) 除外判断の根拠 (どの rule に基づくか) を plan 本文に記載しないと、Codex が総計値で検算して必ず BLOCK する。plan-discipline.md "narrative な baseline 記述禁止" rule (cycle 20260422_0937 #2) の系として「除外数値の justification 明記」を拡張候補。
- **一般化**: grep-based metric で "N occurrences" と書くときは、同じ grep を実行した者が同じ数値に辿り着ける **再現可能性** が plan の要件。grep command + scope path + 除外 filter + 理由の 4 点セットで記述する。

### Insight 2: `grep -E` と BRE mode で `|` のエスケープ要件は逆転する

- **Failure**: TL-3/TL-4 で `grep -E "Cycle B\|eval-[0-9]\|A2[ab]"` と alternation を escape したが、`-E` (ERE mode) では `|` が既に特殊文字なので `\|` はリテラル pipe を意味する。実測 `printf 'Cycle B\neval-4' | grep -E "Cycle B\|eval-[0-9]\|A2[ab]"` → rc=1 (no match) で意図しない false-positive 0 件判定。Codex plan review #3 で BLOCK。
- **Final fix**: `grep -E "Cycle B|eval-[0-9]|A2[ab]"` (non-escaped) に修正。`-E` mode では `|` が直接 alternation として動作。
- **Insight**: **`grep -E` (ERE) と `grep` (BRE) で `|` のエスケープ要件は逆**。ERE: `|` が特殊文字 (escape すると literal)、BRE: `\|` が alternation (escape しないと literal pipe)。test-patterns.md rule の「grep は case-sensitive + word boundary + 固有 prefix」系の追記候補: "alternation 使用時は mode (ERE/BRE) と escape の整合を必ず実測で確認"。
- **一般化**: regex 構文のエスケープ要件は dialect (POSIX BRE/ERE/PCRE) で逆転しうる。test 作成時は `printf` で oracle 入力を用意して実測 rc を確認するのが最も安全。

### Insight 3: code review は `git status --short` で untracked 状態を事前検査すべき

- **Failure**: Codex code review #1 で、新規作成した `tests/test-discovered-debt-cleanup.sh` と `docs/cycles/20260424_1119_discovered-debt-cleanup.md` が untracked (`??`) のまま `git diff HEAD` に含まれていない状態を指摘され BLOCK。review pipeline は diff base で動作するが、untracked file は diff から抜け落ちるため、regression test や Cycle doc SSOT が commit から脱落するリスク。
- **Final fix**: `git add tests/test-discovered-debt-cleanup.sh docs/cycles/20260424_1119_discovered-debt-cleanup.md` で明示的に staging → Codex に resume で再 review → APPROVED。
- **Insight**: **review pipeline の前処理で `git status --short` を実行し、untracked (`??`) / unstaged deletion を検出する gate が必要**。特に新規 test file / Cycle doc など「commit で必ず含めるべき artifact」が untracked のまま進むと、`git diff HEAD` ベースの review が完全性を保証できない。review skill の gate に「untracked artifact detection」追記候補。
- **一般化**: diff-based review は base との相対で動くため「git index に入っていない新規 file」は sliently 脱落する。review 開始時の pre-gate に `git status` 検査を入れるのが safer。

### Insight 4: 過去 `no-codify` 判定の根拠が recurrence で無効化される場合、codify-insight の duplicate-negative rule に例外を認める

- **Failure (decision)**: cycle 20260424_0900 captured の Insight 2 (section-specific grep 標準化) は、過去 cycle 20260423_0926 Insight 4 で no-codify 判定済 (reason: 「一般性未確認」)。codify-insight reference.md の recurrence rule では「1+ で過去 no-codify 判定 → no-codify (duplicate negative)」が strict 解釈だが、今回 2 回目再発で「一般性未確認」根拠そのものが実証的に無効化された。機械的に duplicate negative で処理すると、実証されたパターンを永久に codify できない。
- **Final fix**: ユーザー確認 (AskUserQuestion fallback) で `codified → rule (test-patterns.md)` に昇格。
- **Insight**: **recurrence-aware triage の "duplicate negative" rule には「過去 no-codify 理由が recurrence で無効化されたか」を判定する例外が必要**。現行 rule は reason を unread で duplicate-negative 適用するが、recurrence 自体が reason を validate/invalidate する signal なので、reason-aware の判定に拡張する。codify-insight reference.md の Recurrence 節に追記候補。
- **一般化**: 過去の判断は永続的には正しくない。再発は単なる duplicate signal ではなく「過去判断の根拠が time-tested かどうか」の test。LLM-driven triage で「reason が恒常的か時限的か」を区別するプロンプト設計が必要。

### Insight 5 (observation、no-codify): Codex competitive review は `git status` も自発的に検査する

- **Observation**: Codex code review #1 で、明示的に指示していないにもかかわらず `git status --short` を自発実行し、untracked file 検出を findings に含めた。これは Codex の review coverage が diff の内容だけでなく git index 状態まで及ぶことを示す 2nd-order evidence。cycle 20260424_0900 Insight 4 (3 cycle 連続 Codex plan review BLOCK で scope 拡大) の code review 版。
- **Final fix**: N/A (observation)
- **Insight**: Codex review は repo 状態を rich に検査する tool として運用が定着。rule 化して強制する性質ではないが、PdM として「Codex review は file tracking 状態の gate を含む」ことを前提に活用。
