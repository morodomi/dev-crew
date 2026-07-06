---
feature: rules-path-scoping
cycle: 20260625_1101
phase: DONE
complexity: standard
test_count: 4
risk_level: LOW
retro_status: resolved
codex_session_id: "019efc89-e96b-7bc3-9d00-4004e6987657"
created: 2026-06-25
updated: 2026-07-06 11:40
---

# Rules Path Scoping

## Scope Definition

### In Scope
- [ ] `rules/test-patterns.md` に `paths: ["tests/**"]` frontmatter を追加
- [ ] `.claude/rules/test-patterns.md` に同一 frontmatter を追加（mirror、byte-identical 必須）
- [ ] `rules/skill-authoring.md` に `paths: ["skills/**"]` frontmatter を追加
- [ ] `.claude/rules/skill-authoring.md` に同一 frontmatter を追加（mirror、byte-identical 必須）
- [ ] `tests/test-rules-path-scoping.sh` を新規作成（RED テスト 4 TC）
- [ ] `docs/STATUS.md` の Test Scripts カウントを +1
- [ ] `docs/cycles/20260625_1101_rules-path-scoping.md` Cycle doc（本ファイル）

### Out of Scope
- B: git-safety.md の main-push / force-push 常時 hook 化（follow-up cycle）
- C: doc-mutations APPEND-ONLY / state-ownership plan-IMMUTABLE の PreToolUse(Edit) gate 化（follow-up cycle）
- rules 同期のワンコマンド化（toil 削減の nice-to-have、follow-up cycle）
- TDD ワークフロー系ルール（plan-discipline, doc-mutations, state-ownership 等）のpath-scoping（phase をまたいで規律が抜けるため非スコープ維持が正解）

### Files to Change (target: 10 or less)
- `rules/test-patterns.md` — 先頭に `paths: ["tests/**"]` frontmatter 追加
- `.claude/rules/test-patterns.md` — 同一 frontmatter（mirror、byte-identical 必須）
- `rules/skill-authoring.md` — 先頭に `paths: ["skills/**"]` frontmatter 追加
- `.claude/rules/skill-authoring.md` — 同一 frontmatter（mirror、byte-identical 必須）
- `tests/test-rules-path-scoping.sh` — 新規 RED テスト（4 TC）
- `docs/STATUS.md` — Test Scripts カウント +1（新テストファイル追加に伴う）
- `tests/test-codify-insight.sh` — **REVIEW collateral fix**: TC-19 の Test Scripts hardcode 112 → 113（逆向き契約。Codex code review Finding 3 で検出）
- `docs/cycles/20260625_1101_rules-path-scoping.md` — Cycle doc（本ファイル）

## Environment

### Scope
- Layer: Documentation / Rule files
- Plugin: bash (shell scripts)
- Risk: 10 (LOW)

### Runtime
- Language: bash (macOS zsh / GNU bash)

### Dependencies (key packages)
- awk: POSIX awk（frontmatter 範囲スキャン）
- grep: POSIX grep（pattern 検査）

### Risk Interview (BLOCK only)
- N/A（Risk LOW のため不要）

## Context & Dependencies

### Reference Documents
- `docs/decisions/` — ADR（本 cycle は ADR 対象外）
- `rules/test-patterns.md` — bash テストの落とし穴（dogfood 対象）
- `rules/skill-authoring.md` — SKILL.md 執筆規律（dogfood 対象）
- `rules/integration-verification.md` — real-path invocation 要件
- `tests/test-rules-mirror.sh` — mirror 整合性ガード（TC-04 の既存カバー）

### Dependent Features
- test-rules-mirror.sh: rules/ と .claude/rules/ の byte-identical 保証

### Related Issues/PRs
- N/A

## Test List

### TODO
(none)

### WIP
(none)

### DISCOVERED
- 本 cycle 起因なし。baseline の pre-existing FAIL 3件は #135 (CLAUDE.md staleness) で追跡済み（Progress Log 参照）

### DONE
- [x] TC-01: `rules/test-patterns.md` の frontmatter に `paths:` があり `tests/**` を含む
- [x] TC-02: `rules/skill-authoring.md` の frontmatter に `paths:` があり `skills/**` を含む
- [x] TC-03: 両ファイルの frontmatter delimiter `^---$` が 2 個（開閉 balanced）
- [x] TC-04: `.claude/rules/` 側の 2 コピーも同一 frontmatter（mirror 維持）

## Implementation Notes

### Goal
path-scoping により非関連サイクルのコンテキスト消費を削減する。`test-patterns.md`（67行）と `skill-authoring.md`（50行）の合計 117 行を常時ロードから「関連時のみロード」へ移行する。

### Background
Anthropic 公式ブログ「Steering Claude Code」の 7 ステアリング手段フレームワークで dev-crew 全体を棚卸しした結果、path-scoping が唯一の明確に未実装かつ安全な改善だった。ブログの決定的な制約として、**path-scoped ルールは compaction 後にコンテキストから削除され、該当パスに触れるまで再ロードされない**。orchestrate は phase 境界で phase-compact するため、TDD ワークフロー系ルールを scope すると phase をまたいで規律が抜ける。安全に scope できるのは「ファイルローカルで、該当ファイル編集時のみ必要」な 2 本のみ。mirror 規約（test-rules-mirror.sh）により `rules/` と `.claude/rules/` は byte-identical 必須。両コピーに同一 frontmatter を追加する。

### Design Approach
frontmatter 形式はブログ準拠の quoted-list 形式を採用:

```yaml
---
paths:
  - "tests/**"
---
```

frontmatter 範囲検査は `awk '/^---$/{c++;next} c==1{print}'` で body から分離（test-patterns.md 自身の推奨パターンを dogfood）。whole-file grep は body の同一文字列を誤検出するため禁止（test-patterns.md 規約準拠）。SKILL.md 100 行制約という最重要点は AGENTS.md Key Constraints に常時記載があり冗長性は保たれる。

## Verification

**Real-path invocation を最低 1 件含めること** (rules/integration-verification.md)。

```bash
# 新テスト RED→GREEN
bash tests/test-rules-path-scoping.sh; echo "rc=$?"

# 既存テスト non-regression（mirror + rule-docs + risk-classifier）
for t in test-rules-mirror test-codify-rule-docs test-risk-classifier \
         test-discovered-debt-cleanup test-rule-agent-prompts-parallel-clause \
         test-review-step5-synthesis-clause; do
  bash tests/$t.sh >/dev/null 2>&1; printf "%s rc=%d\n" "$t" "$?"
done

# real-path: frontmatter が awk frontmatter-scan で正しく抽出されるか（integration-verification 規約）
awk '/^---$/{c++;next} c==1{print}' rules/test-patterns.md | grep -q "tests/\*\*" && echo "scan OK"

# 全構造テスト
for f in tests/test-*.sh; do bash "$f" >/dev/null 2>&1; printf "%s rc=%d\n" "$(basename $f)" "$?"; done | grep -v "rc=0" || echo "ALL PASS"
```

Evidence: (orchestrate が自動記入)

## Progress Log

### 2026-06-25 11:01 - KICKOFF
- Cycle doc created from plan file /Users/morodomi/.claude/plans/replicated-mixing-snowflake.md
- Scope definition ready
- Phase completed

### 2026-06-25 - PLAN REVIEW (Codex competitive)
- risk-classifier.sh 実測: LOW score:25（self-declared LOW と一致、cycle 20260525_1249 Insight 5 準拠で classifier 採用）
- Codex plan review (session 019efc89-e96b-7bc3-9d00-4004e6987657): full-suite baseline 実行中に 420s timeout で打ち切り。実質 findings 取得済み:
  - 確認: `test-v2-release.sh` TC-04 が「STATUS.md test count == 実 test 数」を強制。新 test 追加 → STATUS.md +1 必須（Files list に既収載、Insight 1 遵守）
  - flag: TC-13 経由の `test-cycle-retrospective.sh` FAIL は timeout artifact と判定（単体実行 PASS 15/0、編集有無で rc=0 一致を実測）。real failure ではない
- scope / Files list / test 契約に対する BLOCK なし → 実質 PASS、Block 2a (RED) へ進行

### 2026-06-25 - BLOCK 0 BASELINE (per-test timeout 60s, 112 tests)
- REAL_FAILURES: 5 件のうち
  - `test-doc-consistency.sh` / `test-meta-doc-consistency.sh` (rc=124): 全 test を回す集約メタテストの 60s timeout artifact（real failure ではない）
  - `test-hooks-structure.sh` (rc=1): CLAUDE.md 62日未更新 (>30日) で `check-claude-md-staleness.sh` が WARNING 出力 → 期待不一致。**pre-existing、issue #135 で追跡済み**
  - `test-factory-model-adaptation.sh` TC-14 / `test-trap-handler.sh` (rc=1): 内部で test-hooks-structure.sh を呼ぶための cascade FAIL（#135 と同根）
- 結論: 全 pre-existing 失敗は #135 (OPEN, CLAUDE.md/AGENTS.md staleness) 由来。本 cycle の path-scoping とは無関係、新規 regression ゼロ。in-scope fix せず（staleness clock リセットは band-aid、real fix は #135 の test hardening）。本 cycle scope 維持

### 2026-06-25 - RED (red-worker)
- `tests/test-rules-path-scoping.sh` 新規作成（4 TC、frontmatter 範囲 awk 分離 + ERE non-escaped alternation + pipefail 回避を dogfood）
- 実行: 6 assertion FAIL (rc=1) — frontmatter 未追加の正常 RED 確認

### 2026-06-25 - GREEN (green-worker)
- 4 rule ファイル先頭に block-list frontmatter 追加（test-patterns → `tests/**`、skill-authoring → `skills/**`）。canonical/mirror byte-identical
- `docs/STATUS.md`: Test Scripts 112 → 113（実 test 数一致、test-v2-release.sh TC-04 契約）、Last updated 2026-06-25
- 検証実測: path-scoping PASS / mirror 両ペア IDENTICAL / 非回帰 7 テスト (rules-mirror, codify-rule-docs, risk-classifier, discovered-debt-cleanup, rule-agent-prompts-parallel-clause, review-step5-synthesis-clause, v2-release) 全 rc=0 / real-path awk scan OK
- Phase completed

### 2026-06-25 - REFACTOR
- Verification Gate: bash -n 構文 OK、test exit 契約あり（`[ "$FAIL" -eq 0 ] && exit 0 || exit 1`）、rule ファイルは frontmatter +4行のみで肥大化なし（test-patterns 67→71, skill-authoring 50→54）
- frontmatter 追加に構造的リファクタ不要（no-op）。static analysis: shellcheck 未インストールのため bash -n で代替
- Phase completed

### 2026-06-25 - VERIFY (Product Verification)
- Cycle doc `## Verification` block を Block 2b/2c で実測実行済み: 新テスト PASS + 非回帰 7 テスト rc=0 + real-path awk frontmatter scan OK（integration-verification 規約の real-path invocation 充足）
- Phase completed

### 2026-06-25 - REVIEW (competitive: Codex + Claude correctness)
- risk LOW score:25 → review-triage LOW tier。Claude correctness-reviewer + Codex code review を並列起動
- **Claude correctness-reviewer**: VERDICT PASS (blocking_score 8)。ただし TC-04 を「frontmatter 発散は検出」と評価し body drift 見逃しを看過（competitive review の価値が出た反例）
- **Codex code review** (session resume): **BLOCK score 58**、3 critical findings。全て実測再現付き
- **3-category triage (review-triage 規約)**:
  - Finding 1 (TC-04 が frontmatter のみ比較 → mirror body drift を false-pass) → **accept-apply**: full-file `diff` に変更（body drift 検出 + RED guard 維持）
  - Finding 2 (`frontmatter_of()` が line-1 anchor 無し → heading 先行で false-pass) → **accept-apply**: `awk 'NR==1{if($0!="---")exit}...'` で line-1 anchor
  - Finding 3 (`test-codify-insight.sh` TC-19 が Test Scripts 112 hardcode → STATUS.md 113 で**実 regression**) → **accept-apply**: TC-19 を 113 に更新。逆向き契約 sweep `grep -rn 112 tests/` で該当が同 file のみと確認
  - WARN (prior cycle doc 20260525_1249 が scope 外で modified) → **reject**: Block 0 codify-insight の意図的作業（codify gate ドレイン）。理由付き reject
- **修正の敵対的実証** (Codex の repro fixture で検証): body drift → TC-04 FAIL / heading 先行 → TC-01 FAIL / test-codify-insight rc=0。本体 4/4 PASS
- **再検証**: scope 9 テスト全 rc=0、mirror 両ペア byte-identical、STATUS.md count 113==実113、bash 構文 OK
- BLOCK 解消（全 finding を Codex 自身の repro 方法で fixed 実証）→ PASS、Block 2e へ
- Phase completed

### 2026-06-25 - DISCOVERED
- 本 cycle 起因の新規スコープ外項目なし。baseline pre-existing FAIL は #135 (CLAUDE.md staleness) で追跡済み
- retrospective Insight 1/2/3 は retro_status: captured として次 orchestrate Block 0 codify gate でドレイン予定。特に Insight 1（count 変更時の逆向き契約 sweep）は cycle 20260525_1249 Insight 1 の即 codify を促す実害事例

### 2026-06-25 - COMMIT
- feature/rules-path-scoping に commit、PR #139 作成（main 直接 commit 不可、remote+PR 運用）
- 9 files: rules frontmatter ×4（canonical+mirror）/ STATUS.md count / test-rules-path-scoping.sh (new) / test-codify-insight.sh (TC-19 collateral) / 2 cycle docs
- pre-commit-gate PASS、.git/hooks pre-commit (yaml-frontmatter) PASS
- Phase completed

## Next Steps

1. [Done] KICKOFF
2. [Done] RED
3. [Done] GREEN
4. [Done] REFACTOR
5. [Done] REVIEW
6. [Done] COMMIT
7. [Done] DONE

## Retrospective

抽出時刻: 2026-06-25
抽出方法: Cycle doc 全体（plan / Block 0 baseline / Codex plan review / RED / GREEN collateral fix / REVIEW competitive BLOCK→fixed）からの失敗→最終解→insight ペア抽出

### Insight 1: count/status 変更 cycle の検証は curated リストでなく逆向き契約 sweep で行う
- **Failure**: GREEN で `docs/STATUS.md` を Test Scripts 112→113 に更新したが、検証は plan の curated 非回帰リスト（`test-codify-insight.sh` を含まない）のみ実行。`test-codify-insight.sh` TC-19 が `Test Scripts | 112` を hardcode していたため regression が GREEN 検証を素通りし、Codex code review で BLOCK (Finding 3) として初めて検出された
- **Final fix**: TC-19 を 113 に更新 + 逆向き契約 sweep `grep -rn 112 tests/` で該当が同 file のみと確認、collateral fix として Files list 即時同期
- **Insight**: **count/status を変更する cycle の GREEN 検証は、plan の curated リストでなく `grep -rln "<old-value>" tests/` の逆向き契約 sweep 結果を全て実行する**。curated 非回帰リストは検証範囲を恣意的に狭め、hardcode された逆向き契約を見逃す
- **一般化**: 本失敗は直前 Block 0 で drain した cycle 20260525_1249 Insight 1（count 変更時の逆向き契約明示）と Insight 2（Block 0 full-suite baseline 必須）が予言したもの。**deferred 判定した cycle 20260525_1249 Insight 1 を即 codify すべき強い証拠**（recurring かつ実害発生）。`plan-discipline.md` の「count/status 変更時に grep -rn 実測」を GREEN 検証フェーズにも適用する codify 候補

### Insight 2: single reviewer の「検出する」主張は検出境界を問わないと over-claim を見逃す
- **Failure**: Claude correctness-reviewer が TC-04 を「frontmatter 発散を正しく検出」と PASS 評価。実際は frontmatter のみ比較で body drift を見逃す論理欠陥があり、Codex が fixture 実測で BLOCK
- **Final fix**: TC-04 を full-file `diff` に変更
- **Insight**: reviewer が「テストが X を検出する」と主張する際、**検出対象の境界（frontmatter only か full-file か）と "what does it NOT catch" を明示させる**。single-reviewer の肯定主張は competitive review なしでは over-claim を見逃す。Claude + Codex competitive review の価値の実証事例
- **一般化**: `rules/review-triage.md` の reviewer prompt に「肯定的 verdict には検出境界と非検出ケースを明記」を追加する codify 候補。observation 寄り

### Insight 3: full-suite baseline は per-test timeout wrap で実行する
- **Failure**: Block 0 と Codex plan review で full-suite が 2分 timeout。`test-doc-consistency.sh` / `test-meta-doc-consistency.sh` が内部で全 test を実行する集約メタテストのため。外側 timeout が途中 kill → 走っていた `test-cycle-retrospective.sh` を偽 FAIL と誤報告（timeout artifact）
- **Final fix**: `timeout 60 bash "$f"` の per-test wrap で baseline 再取得 → real failure（#135 由来 1件 cascade）と timeout artifact を正しく分離
- **Insight**: **full-suite baseline は per-test timeout（`timeout 60 bash "$f"`）で個別実行する**。集約メタテストの内部全実行 + 外側単一 timeout の組合せは「どの test が遅い/落ちた」を timeout artifact で誤判定させる
- **一般化**: cycle 20260525_1249 Insight 2（Block 0 full-suite baseline 必須、#136）の実行手法を具体化。observation 寄り、#136 の follow-up cycle で手法として codify 候補

## Codify Decisions

triage 実施: 2026-07-01（後続 cycle plan-discipline-green-sweep の orchestrate Block 0 codify gate で処理）。

### Insight 1
- **Decision**: codified
- **Destination**: rule (`rules/plan-discipline.md` 推奨 + 出典)
- **Reason**: count/status 変更 cycle の GREEN 検証を逆向き契約 sweep で全実行する規律。recurring（20260525_1249 #1 が予告）かつ実害発生（本 cycle の TC-19 regression）。**後続 cycle plan-discipline-green-sweep で実装中**（本 codify を triggering する cycle）
- **Decided**: 2026-07-01

### Insight 2
- **Decision**: no-codify
- **Reason**: single reviewer の over-claim を competitive review が捕捉する observation。Claude + Codex competitive review は CONSTITUTION / feedback で既に必須運用。rule 化で強制する新規性は薄い（reviewer prompt への「非検出ケース明記」追加は将来 review-triage 改善時に検討）
- **Decided**: 2026-07-01

### Insight 3
- **Decision**: deferred
- **Destination**: new-cycle (#136)
- **Reason**: full-suite baseline の per-test timeout wrap 手法。cycle 20260525_1249 Insight 2 / issue #136（orchestrate Block 0 baseline step 追加）の実行手法として同 follow-up cycle に統合するのが適切
- **Decided**: 2026-07-01
