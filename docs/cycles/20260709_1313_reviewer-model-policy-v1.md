---
feature: reviewer-model-policy-v1
cycle: 20260709_1313
phase: DONE
complexity: standard
test_count: 6
risk_level: medium
retro_status: captured
codex_session_id: "019f4519-eff7-7f73-8bf4-f705ece58f32"
created: 2026-07-09 13:13
updated: 2026-07-13 16:02
---

# reviewer-policy v1: reviewer のモデル方針を設定可能にする（repo-default + HIGH-gated escalation）

## Scope Definition

### In Scope
- [ ] `.claude/dev-crew.json` に top-level `review_policy`（`reviewer_model` / `escalate_high_to`）を追加
- [ ] `skills/review/SKILL.md` Step 4 Specialist Panel に「review_policy を読みモデルを解決」の 1-2 行追記（<100 行厳守）
- [ ] `skills/review/steps-subagent.md` の `model: "sonnet"` 固定を「policy 解決モデル」への置換指示ブロックに変更。NON-NEGOTIABLE floor（security+correctness は model 不問で常時起動）を明記
- [ ] `skills/review/reference.md` に review_policy 解決規則の詳細（allowlist・precedence・HIGH escalation・self=inherit・Codex peer-vendor 常時・human 未対応）を追記
- [ ] `rules/review-triage.md` + `.claude/rules/review-triage.md`（byte-identical mirror）に「モデル tier は review_policy と合成（HIGH → escalate_high_to）」を追記
- [ ] `skills/onboard/reference.md`: (a) dev-crew.json 生成 heredoc に review_policy 追加、(b) CLAUDE.md 生成に「## Reviewer Policy」宣言セクション（Delegation Rules 隣接）、(c) onboard 検証テーブルに presence-check 行
- [ ] `tests/test-review-policy.sh`（新規）— TC-01〜06（下記 Test List）
- [ ] `docs/STATUS.md` Test Scripts 112→113 + Completed 行 + Done 65→66
- [ ] `tests/test-codify-insight.sh` TC-19 の期待値 `Test Scripts | 112` → `113`（逆向き契約、新規テストファイル追加のため）

### Out of Scope
- per-cycle frontmatter 上書き（codex_mode パターン）— follow-up issue化
- `human` policy（pause 制御フロー）— follow-up issue化
- reviewer agent frontmatter の model 既定変更（`test-review-integration-v24.sh` TC-04 の allowlist `^(sonnet|haiku)$` は不変・非対象）

### Files to Change（全量、追加・削除禁止、plan 記載順）
1. `.claude/dev-crew.json` — `review_policy` object 追加（`reviewer_model: "self"`）
2. `skills/review/SKILL.md` — Step 4 に policy 解決の 1-2 行
3. `skills/review/steps-subagent.md` — `model: "sonnet"` → policy 解決モデル置換指示。NON-NEGOTIABLE floor 明記
4. `skills/review/reference.md` — review_policy 解決規則の詳細
5. `rules/review-triage.md` + `.claude/rules/review-triage.md` — risk tier × model tier 合成の注記（byte-identical mirror）
6. `skills/onboard/reference.md` — heredoc + CLAUDE.md 生成 + 検証テーブル
7. `tests/test-review-policy.sh`（新規）— 契約テスト
8. `docs/STATUS.md` — Test Scripts 112→113 + Completed 行 + Done 65→66
9. `tests/test-codify-insight.sh` — TC-19 期待値 112→113

## Environment

### Scope
- Layer: bash / doc project（review skill 群 + config + onboard + 契約テスト）
- Plugin: dev-crew
- Risk: MED — review skill 本体（meta: レビュー機構自身の変更）+ config + onboard。動作は prose-driven（Task-spawn の model 引数）で、契約テストにより pin。NON-NEGOTIABLE（security+correctness 常時起動）は不変。可逆

### Runtime
- 環境: bash / macOS。Codex 復旧済み。version gate PASS

### Dependencies (key packages)
- なし（新規外部依存追加なし）

### Risk Interview (BLOCK only)
- 該当なし（見積 MED は BLOCK 未満）

## Context & Dependencies

### Reference Documents
- v2.12 バックログ。前提 #164（risk-classifier の doc-diff FP、cycle 20260709_1125）解消済みのため HIGH 判定が信頼でき、「HIGH のみ上位モデル」のコスト設計が成立する
- ユーザー承認済み設計（AskUserQuestion、3点）: 構造化フィールド + CLAUDE.md 併記 / upper・peer 優先・self は fallback / HIGH のみ上位モデル
- v1 スコープ確認（離席中 Recommended 採用）: (1) repo-default のみ（per-cycle 上書きは defer）/ (2) allowlist = self/sonnet/haiku/opus/fable / (3) `human` policy は follow-up defer
- `rules/multi-file-consistency.md`（review skill の SKILL.md + steps-* + reference の DRY sweep）
- `rules/review-triage.md`（risk tier テーブル）
- `rules/state-ownership.md`（v1 は frontmatter field 追加なしのため対象外）

### Dependent Features
- `skills/review/`（SKILL.md / steps-subagent.md / reference.md）
- `.claude/dev-crew.json`（onboard が生成、review skill が読む）
- `skills/onboard/`（dev-crew.json 生成 + CLAUDE.md 生成）
- `tests/test-review-integration-v24.sh`（TC-04 frontmatter allowlist、非対象だが隣接契約として architect が確認済み）
- `tests/test-codify-insight.sh`（TC-19、Test Scripts count pin）
- `tests/test-rules-mirror.sh`（rules/ ↔ .claude/rules/ byte-identical 保証）

### Related Issues/PRs
- #164（前 cycle、HIGH 判定の信頼性回復）→ 本 cycle の escalation gate の前提

## Problem（実測済み、architect が現物確認）

- reviewer は全て **sonnet に pin 済み**（`skills/review/steps-subagent.md:71-102` の複数 `model: "sonnet"` Task-spawn、一部 `model: "haiku"`）。Opus/Fable で駆動している著者に対し reviewer が executor より弱い逆立ち状態。
- 設定サーフェスは存在: `.claude/dev-crew.json`（現状 `{"dev_crew_version": "2.10.0"}` のみ、review_policy 未存在）/ `rules/review-triage.md` の risk tier テーブル。
- reviewer の model 上書きは Task-spawn レベル（steps-subagent.md prose）で行われ、agent frontmatter ではない → frontmatter allowlist test（`test-review-integration-v24.sh` TC-04、`agents/*-reviewer.md` frontmatter の `model` を `^(sonnet|haiku)$` で検証）は触らずに済む。review_policy 値用の別 allowlist（`self|sonnet|haiku|opus|fable`）を新設するだけ。
- NON-NEGOTIABLE reviewer（security+correctness）は doc-only で契約テストなし。本 cycle が初の contract 化対象。

## Baseline（実測、architect が現物確認、grep/Read のみ・テスト実行なし）

- `skills/review/steps-subagent.md:71-102`: Always-on（security-reviewer, correctness-reviewer, maintainability-reviewer 等）と Risk-gated（performance/api-contract/observability/product/usability 等）双方に `model: "sonnet"` または `model: "haiku"` の Task-spawn が確認できた。plan の指摘と一致。
- `.claude/dev-crew.json`: 実読で `{"dev_crew_version": "2.10.0"}` のみを確認。`review_policy` 不在。
- `tests/test-codify-insight.sh:397` 付近: TC-19 が `grep -qE "Test Scripts[[:space:]]*\|[[:space:]]*112"` で `Test Scripts | 112` を pin していることを確認。新規テストファイル追加（`tests/test-review-policy.sh`）により 113 への更新が必須（逆向き契約、plan 記載の通り）。
- `rules/review-triage.md` と `.claude/rules/review-triage.md`: `diff` で byte-identical を確認（追記後も mirror 維持が必須）。
- `skills/onboard/reference.md`: `dev-crew.json 生成手順`（heredoc、`cat > .claude/dev-crew.json << EOF ... EOF`）が `dev_crew_version` のみを書き出すことを確認。`### Delegation Rules` セクションが存在し、隣接位置に「## Reviewer Policy」宣言セクションを追加する余地があることを確認。
- `skills/review/SKILL.md`: 現状 50 行。plan の「1-2 行追記、<100 行厳守」は制約内で feasible。
- `docs/STATUS.md`: `Test Scripts | 112` / `Done (unarchived) | 65` を実読で確認。plan 記載の 112→113 / 65→66 と一致。
- `tests/test-review-integration-v24.sh` TC-04: `agents/*-reviewer.md` のグロブに対し frontmatter `model` を `get_frontmatter` で取得し `^(sonnet|haiku)$` で検証していることを確認。review_policy の Task-spawn レベル上書き（steps-subagent.md prose）とは別レイヤーであり、非対象・非影響であることを確認。
- **軽微な差異（要記録・非 BLOCK 要因）**: plan の逆向き契約 sweep 項目「NON-NEGOTIABLE（security+correctness 常時起動）が現状 doc-only で契約テストなし（`grep -rn "NON-NEGOTIABLE" tests/` が 0 件）」について、architect が実行した結果は **1 件ヒット**（`tests/test-maintainability-reviewer.sh:112` の `"TC-09: maintainability-reviewer Condition is Always (NON-NEGOTIABLE)"`）。ただしこの 1 件は maintainability-reviewer 自身の「Condition is Always」ロジックに関するコメントであり、security+correctness reviewer の常時起動契約とは無関係。plan の核心主張（security+correctness の NON-NEGOTIABLE 起動契約テストが存在しない）自体は真であり、grep literal の期待値「0 件」との数値不一致は plan の軽微な baseline 誤差に過ぎない。GREEN フェーズで TC-04（新設 test-review-policy.sh 内、steps-subagent.md + reference.md を対象）を実装する際、この既存の無関係ヒットと混同しないよう scope（対象ファイル）を明示する。

## 逆向き契約 sweep（plan 転記、GREEN 前に Block 0 で再実測）

- 新規テストファイル → count bump 必須: `tests/test-codify-insight.sh` が `Test Scripts | 112` を pin。113 に更新 + STATUS.md。`grep -rn "Test Scripts | 112\|\b112\b" tests/ docs/STATUS.md` を Block 0 で実行し全ヒットを更新。
- 追記 rule literal の pre-existing count 0 を Block 0 で実測（review-triage 追記語）。
- `review_policy` の pre-existing 参照が repo に無いことを確認（新概念）。architect による実読で `.claude/dev-crew.json` に不在を確認済み（新概念であることを裏付け）。
- steps-subagent.md の `model: "sonnet"` を policy 化する箇所と、それを pin する既存テストの有無を確認（`grep -rn 'model: "sonnet"' skills/review/ tests/`）。architect 実読で steps-subagent.md 側の複数箇所を確認済み。tests/ 側の既存 pin 有無は Block 0 で再実測すること（本 KICKOFF では未実施）。

## 設計 — review_policy スキーマと解決規則（GREEN の SSOT）

`.claude/dev-crew.json` に top-level `review_policy` を追加:

```json
{
  "dev_crew_version": "2.10.0",
  "review_policy": {
    "reviewer_model": "self",
    "escalate_high_to": null
  }
}
```

- **`reviewer_model`**: LOW/MED tier の Claude reviewer が走るモデル。値 = enumerate-and-reject `self | sonnet | haiku | opus | fable`。既定 `self`（= Task の `model:` を省略して executor 継承 → 「reviewer が sonnet 固定で executor より弱い」逆立ちを解消。ユーザー原案「デフォルトの自身」に一致）。
- **`escalate_high_to`**: HIGH tier で **代わりに**使うモデル（`null` = escalation なし = reviewer_model と同じ）。承認済み「HIGH のみ上位モデル」を符号化。例: `"fable"` → HIGH review のみ Fable。
- **解決順（承認済み precedence: upper/peer → self fallback）**: policy に upper（escalate_high_to）指定あり かつ HIGH tier → その model / else reviewer_model（既定 self）/ **peer-vendor（Codex）は直交で常時 always-on**（`which codex` gate、既存）。人間（human）は v1 対象外。
- **NON-NEGOTIABLE 不変**: security-reviewer + correctness-reviewer は policy/score 不問で常時起動。policy が制御するのは「どのモデルで走るか」であって「起動するか」ではない（security review bypass を config で作らない）。#164 cycle で classifier header に明記した原則の延長。

## Test List

### TODO
(none)

### WIP
(none)

### DISCOVERED
(none)

### DONE
- [x] TC-01 | Given: .claude/dev-crew.json | When: review_policy.reviewer_model を読む | Then: 値が allowlist `self|sonnet|haiku|opus|fable` 内（enumerate-and-reject、不正値は FAIL）
- [x] TC-02 | Given: .claude/dev-crew.json | When: escalate_high_to を読む | Then: `null` or allowlist 内
- [x] TC-03 | Given: skills/review/steps-subagent.md | When: policy 解決指示を grep | Then: 「review_policy を読み model を解決」の contiguous phrase が存在（`model: "sonnet"` literal 固定でない指示）
- [x] TC-04 | Given: skills/review/steps-subagent.md + rules/review-triage.md | When: NON-NEGOTIABLE floor + negative 契約を grep | Then: security+correctness が policy/score 不問で常時起動する記述 かつ review-triage.md に「correctness 省略可」literal が不在（floor 退行防止）
- [x] TC-05 | Given: skills/onboard/reference.md | When: dev-crew.json 生成 heredoc + CLAUDE.md 生成を grep | Then: review_policy 生成 + 「Reviewer Policy」宣言セクションが含まれる
- [x] TC-06 | Given: skills/review/steps-subagent.md | When: Code Mode の security/correctness/maintainability Task を grep | Then: `model: "sonnet"` literal が除去され prose 解決指示に置換（TC-34 drift guard 回避）

## Implementation Notes

### Goal
reviewer のモデル方針を repo-default で設定可能にし、「reviewer が executor より弱い」逆立ちを解消しつつ、HIGH tier のみ上位モデルへエスカレーションするコスト設計を実現する。NON-NEGOTIABLE（security+correctness 常時起動）は不変のまま契約テスト化する。

### Design Approach
上記「設計 — review_policy スキーマと解決規則」節を SSOT とする。GREEN フェーズはこの節をそのまま実装する。plan file は IMMUTABLE のため、以後の設計調整（Codex plan review 指摘等）は本 Cycle doc のセクションを更新する（doc-mutations.md 準拠、ただし本節は plan からの transcription であり、以後の追記は新規セクション追加で行う）。

## Verification（integration-verification 準拠、rc 明示 + real-path + full suite）

```bash
bash tests/test-review-policy.sh; echo "review-policy rc=$? (expected 0)"
bash tests/test-rules-mirror.sh; echo "rules-mirror rc=$? (review-triage 追記後も byte-identical)"
bash tests/test-codify-insight.sh; echo "codify-insight rc=$? (TC-19 count 113 更新後 PASS)"
# real-path: review_policy を inline jq で解決して model を出す最小 harness
jq -r '.review_policy.reviewer_model // "self"' .claude/dev-crew.json; echo "-> self 期待"
jq -r '.review_policy.escalate_high_to // "null"' .claude/dev-crew.json
# full suite: Holdings 親構造複製 snapshot・直列、Block 0 baseline と diff（空=回帰ゼロ）
```

**self-apply**: 本 cycle 自身の REVIEW は現行 policy（reviewer=sonnet 固定）で走る（実装前）。実装後の初適用は次 cycle。self-review の逆説を retrospective で記録候補。

## Upstream References

- ユーザー承認済み設計（構造化フィールド / upper-peer 優先 self fallback / HIGH のみ上位）+ v1 縮小合意
- #164（前 cycle、HIGH 判定の信頼性回復）→ 本 cycle の escalation gate の前提
- `rules/multi-file-consistency.md`（review skill の SKILL.md + steps-* + reference の DRY sweep）/ `rules/review-triage.md`（risk tier）/ `rules/state-ownership.md`（v1 は frontmatter field 追加なしのため対象外）

## 注記

**Design Review Gate（architect、2026-07-09 13:16 実施）**: PASS（詳細は Progress Log KICKOFF エントリ参照）。

## Progress Log

### 2026-07-09 13:16 - KICKOFF (architect)
- sync-plan Phase completed
- Cycle doc created from approved plan (`/Users/morodomi/.claude/plans/gentle-stirring-hopper.md`)
- Scope definition ready。Files to Change 9件は plan を全量転記（追加・削除なし）
- **Design Review Gate 判定: PASS**（スコア目安 15/100、詳細は下記）
  - **Scope**: Files to Change 9件（<=10 充足、ちょうど境界内）。review skill 群（SKILL.md/steps-subagent.md/reference.md）+ config + onboard + rule mirror + 新規 test + STATUS.md + count-fix test という meta（レビュー機構自身）変更だが、v1 は明示的に scope 縮小済み（per-cycle 上書き defer / human policy defer / agent frontmatter model 既定変更は非対象）。YAGNI 違反なし
  - **Architecture**: `skills/review/steps-subagent.md:71-102` を実読し複数の `model: "sonnet"`/`"haiku"` Task-spawn を確認（plan 記載と一致）。`.claude/dev-crew.json` が `dev_crew_version` のみであることを実読確認。`tests/test-codify-insight.sh` の TC-19 が `Test Scripts | 112` を pin していることを確認（113 bump の逆向き契約が正当）。`rules/review-triage.md` と `.claude/rules/review-triage.md` の byte-identical mirror を diff で確認。`skills/onboard/reference.md` の dev-crew.json 生成 heredoc（`dev_crew_version` のみ）と `### Delegation Rules` セクションの存在を確認し、review_policy 追加余地・Reviewer Policy セクション追加余地を確認。`skills/review/SKILL.md` が現状 50 行で <100 行制約内に収まることを確認。`tests/test-review-integration-v24.sh` TC-04（`agents/*-reviewer.md` frontmatter allowlist `^(sonnet|haiku)$`）が Task-spawn レベルの policy 解決とは別レイヤーであり非対象・非影響であることを確認
  - **軽微な差異**: plan の逆向き契約 sweep 項目「`grep -rn "NON-NEGOTIABLE" tests/` が 0 件」との記載に対し、実測は 1 件（`tests/test-maintainability-reviewer.sh:112`、無関係な既存コメント）。plan の核心主張（security+correctness NON-NEGOTIABLE の契約テスト不在）自体は真であり、数値不一致は軽微な baseline 誤差。BLOCK要因とはしないが、GREEN で TC-04 実装時に対象ファイル（steps-subagent.md + reference.md）を明示し混同を避けるよう Cycle doc 本文（Baseline節）に記録済み
  - **Test List**: 6件、非空。正常系（TC-01/02 の allowlist 内 value）・異常系（TC-01/02 の enumerate-and-reject、不正値 FAIL）・存在検証（TC-03/04/05/06 の grep ベース contract）を網羅。Given/When/Then は plan 記載のまま転記、全て grep/jq で検証可能な具体的入出力
  - **Risk**: plan 記載の MED は、review skill 本体（meta 変更）+ config + onboard という多面的だが prose-driven かつ可逆な変更内容と整合。NON-NEGOTIABLE 不変の明記により security bypass リスクは排除設計済み
  - 検証条件（照合済み）: steps-subagent.md の model 固定箇所、dev-crew.json 現状、TC-19 pin 値、review-triage mirror、onboard heredoc/Delegation Rules 隣接、SKILL.md 行数余裕、TC-04 frontmatter allowlist 非影響 — 全て現物と整合。NON-NEGOTIABLE grep 数のみ 0→1 の軽微差異（無関係ヒット、非 BLOCK）
- 次フェーズ: plan-review（Codex competitive）へ

## Codify Decisions
(none — retro_status: none)

### 2026-07-09 13:25 - BLOCK 0 BASELINE + PLAN REVIEW (Codex competitive) — BLOCK 2件、ユーザー確認待ち

**Block 0 baseline（Holdings 親構造複製 snapshot、直列）**: 112/112 全 rc=0（scratchpad/baseline-cycle4.txt）。codify gate: 20260709_1125 の captured retro を triage 済み（Insight 1→test-patterns / Insight 2→review-triage、実装は codify 実装 cycle、observation は no-codify、resolved 遷移）。

**PLAN REVIEW 判定: BLOCK 2 / WARN 1**。codex_session_id: 019f4519-eff7-7f73-8bf4-f705ece58f32。Codex はテスト実行禁止遵守。

- **BLOCK 1（plan 中核前提の事実誤認）**: plan の「`self` = Task の model 省略で executor 継承」は不正確。Claude Code の model 解決順は env → per-invocation model → **subagent frontmatter** → main model。reviewer agent は frontmatter に `model: sonnet/haiku` を持つため、Task で省略すると executor でなく **frontmatter（sonnet）に落ちる**。→ 「デフォルト self = reviewer が executor 同等」は現構造では成立しない。技術的解決策: (a) skill が「self なら orchestrator 自身の現モデルを明示的に Task に渡す」prose（frontmatter 変更不要、prose-driven）、(b) reviewer frontmatter の `model:` を削除して真の inherit（scope 増 + TC-04/TC-34 破壊）、(c) `self` を廃し明示モデルのみ（default sonnet、opt-in で fable/opus）。**(a) が intent 忠実だが、default self = 全 review が executor tier = コスト増をユーザーが承認したことになる — 承認は誤前提の上だったため要再確認**。
- **BLOCK 2（隣接契約の見落とし）**: `tests/test-agents-structure.sh` TC-32（review-briefer haiku）/ TC-33（design-reviewer sonnet）/ **TC-34（frontmatter vs steps-*.md の model drift 検査）**。code-mode reviewer の model literal を policy 化すると TC-34 が drift 検出。解決: policy 制御 reviewer の Task から model literal を**削除**（prose 解決に）→ TC-34 の静的 grep は literal 不在で skip → PASS。ただし Files to Change に test-agents-structure.sh の確認/調整を追加。
- **WARN（既存の矛盾）**: `rules/review-triage.md:11` に「trivial 案件では Claude correctness 省略可」が残存。本 cycle が pin する NON-NEGOTIABLE floor（security+correctness 常時）と矛盾。同 cycle で削除/限定 + negative grep 契約が必要。
- **Codex の妥当な補足**: 契約テストで pin 可能なのは schema/allowlist/手順文/固定 literal 除去/NON-NEGOTIABLE 記述/onboard 生成物/mirror/count まで。**実行時の実モデル選択は決定論的に pin 不能**（Claude Code・env・org allowlist 依存）。112→113 count bump は妥当。

**判定: RED に進まず、ユーザーに BLOCK 1 の意味論・コスト判断を確認する**（genuine scope change）。cycle は KICKOFF で保留。

### 2026-07-13 15:23 - PLAN REVIEW BLOCK 解消（ユーザー判断確定）

ユーザー判断: **判断1 = 案1 / 判断2 = 案2**。plan は IMMUTABLE のため精緻化設計は本 Cycle doc を SSOT とする（doc-mutations.md 準拠）。

**BLOCK 1 解消（判断1=案1: self = orchestrator が自モデルを明示）**:
- `review_policy.reviewer_model` allowlist: `self | sonnet | haiku | opus | fable`。既定 `self`。
- **self の解決規則（GREEN 実装契約）**: policy が `self` のとき、orchestrator/review skill は「**自分（呼び出し元）が現在動いているモデル**を Task の `model:` に明示的に渡す」。Task で省略しない（省略すると frontmatter の sonnet に落ちるため）。→ 既定 self = reviewer が executor 同等 tier。frontmatter 変更は不要（Out of Scope 維持）。
- explicit 値（sonnet/haiku/opus/fable）: その model を Task に渡す。`escalate_high_to` あり かつ HIGH tier: その model を代わりに渡す（承認済み precedence）。
- 実行時の実モデルは決定論的に pin 不能（Codex 補足）。契約テストは「self なら自モデルを明示する手順文が存在」「固定 sonnet literal が policy 制御 reviewer から除去されている」を pin する。

**BLOCK 2 解消（TC-34 drift 回避）**:
- policy 制御対象（code-mode の Claude reviewer: security/correctness/maintainability + risk-gated の performance/api-contract/observability/test-reviewer）の Task から **`model: "X"` literal を削除**し、prose 解決指示に置換。→ `test-agents-structure.sh` TC-34 の静的 grep（`Task(...model:"X"...)`）は literal 不在で当該 call を skip → drift 検出なし → PASS。
- **非対象（literal 維持）**: review-briefer（haiku、圧縮 helper）/ design-reviewer・test-reviewer の plan-mode spawn / product・usability（haiku、意図的に安価）。TC-32（briefer haiku）/ TC-33（design sonnet）は非影響。
- **Files to Change 追加**: `tests/test-agents-structure.sh` — GREEN 後に TC-32/33/34 が PASS 維持することを確認（変更不要の想定だが、literal 削除の影響を検証対象に含める。必要なら調整）。

**WARN 解消（判断2=案2: correctness は床維持、trivial 緩和は他 reviewer に限定）**:
- `rules/review-triage.md`（+ mirror）L11 の「trivial 案件では Claude correctness 省略可」を **「trivial 案件では maintainability 省略可（security+correctness は floor として常時必須）」** に書き換え。correctness を NON-NEGOTIABLE floor に維持。
- **negative grep 契約（TC-04 に追加）**: `review-triage.md` の LOW tier 行に「correctness 省略可」literal が**存在しないこと**を assert（correctness が floor から外れる退行を防ぐ）。

**Files to Change 更新（plan 9 + 追加 1 = 10）**:
- 10. `tests/test-agents-structure.sh` — literal 削除後の TC-32/33/34 PASS 維持確認（drift guard 非破壊）

**判定: BLOCK 全解消。Block 2a (RED) へ。**

### 2026-07-13 15:28 - RED (red-worker)

新規 `tests/test-review-policy.sh` を作成（TC-01〜06、全6件）。`BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"` + `set -euo pipefail` + pass/fail counter の既存規約に準拠。個別実行のみ（`bash tests/test-review-policy.sh`）、full suite・nested runner 未実行。

**RED 時点の実測（全 TC FAIL、exit code=1、本物の RED を確認）**:
- TC-01: FAIL — `.claude/dev-crew.json` に `review_policy.reviewer_model` キー不在（`jq -e` existence check、`// "self"` fallback による偽 PASS を回避）
- TC-02: FAIL — `review_policy.escalate_high_to` キー不在（`has()` existence check、値 null 前提の fallback による偽 PASS を回避）
- TC-03: FAIL — `skills/review/steps-subagent.md` に「review_policy を読みモデルを解決」「orchestrator 自身の現モデルを Task に明示的に渡す」の両 literal 不在
- TC-04: FAIL — steps-subagent.md に NON-NEGOTIABLE floor phrase「policy/score 不問で常時起動」不在（negative 契約側は未到達。floor phrase 不在の時点で FAIL 確定のため後続 rules/review-triage.md の負の条件は未評価）
- TC-05: FAIL — `skills/onboard/reference.md` の dev-crew.json 生成 heredoc に `review_policy` 不在
- TC-06: FAIL（3件）— Code Mode の security-reviewer/correctness-reviewer/maintainability-reviewer Task に `model: "sonnet"` literal が現存（GREEN 前の正しい RED）

**満足可能性の事前検証**: scratchpad 上の隔離コピー（実装ファイルは非改変）に GREEN 相当の変更を仮適用し、同一テストスクリプトが 6/6 PASS（exit 0）することを確認。テストが充足不能な設計になっていないことを検証済み。隔離コピーは検証後に破棄。

**想定外事象**: なし。TC-04/TC-06 の Given 対象ファイルは KICKOFF 時点の Test List（`rules/review-triage.md + mirror` / 独立 TC）と異なり、2026-07-13 15:23 エントリ（BLOCK 解消・SSOT）の定義に従って実装（TC-04 に negative 契約統合、TC-06 は steps-subagent.md 単体の literal 除去 3 reviewer 限定）。Test List 本体も本エントリで WIP 記述をこの定義に同期済み。

- Phase completed

### 2026-07-13 15:36 - GREEN (green-worker)

「設計 — review_policy スキーマと解決規則」節 + 2026-07-13 15:23 BLOCK 解消エントリを SSOT として全 10 ファイルを実装。

**変更ファイル**:
1. `.claude/dev-crew.json` — top-level `review_policy`（`reviewer_model: "self"`, `escalate_high_to: null`）追加。`dev_crew_version` は保持
2. `skills/review/steps-subagent.md` — Specialist Panel 直前に「Step 3.5: Reviewer Model 解決 (review_policy)」ブロックを新設（self 解決規則 + NON-NEGOTIABLE floor 明記 + 非対象 reviewer 明示）。Code Mode の security-reviewer/correctness-reviewer/maintainability-reviewer + risk-gated 4 reviewer（performance/api-contract/observability/test-reviewer）の Task から `model: "sonnet"` literal を削除し `# model: Step 3.5 の review_policy 解決モデル` コメントに置換。review-briefer/product-reviewer/usability-reviewer（haiku）・Plan Mode の design-reviewer/test-reviewer（sonnet）は literal 維持（非対象）
3. `skills/review/SKILL.md` — Step 4 に review_policy 解決の 1 行追記（50 行のまま、<100 行制約内）
4. `skills/review/reference.md` — 「review_policy 解決規則」節を新設（フィールド表・解決順・Codex peer-vendor 直交・human 未対応・NON-NEGOTIABLE floor・実行時制約）
5. `rules/review-triage.md` + `.claude/rules/review-triage.md` — LOW tier 行を「trivial 案件では maintainability 省略可（security+correctness は floor として常時必須）」に書き換え（判断2=案2）。「モデル tier との合成」注記を追加。cp で mirror 同期、diff 空を確認
6. `skills/onboard/reference.md` — (a) dev-crew.json 生成 heredoc に `review_policy` 追加、(b) `### Delegation Rules` 直後に「## Reviewer Policy」宣言セクション追加（self/upper/peer 説明）、(c) 「ファイル単位の差分チェック」表に `review_policy` presence-check 行追加
7. `tests/test-review-policy.sh` — RED 成果物（触らず）
8. `docs/STATUS.md` — `Test Scripts | 112` → `113`（Completed 行 + Done 65→66 は commit skill が担当のため本 phase では対象外）
9. `tests/test-codify-insight.sh` — TC-19 の期待値 `Test Scripts | 112` → `113`（grep literal + メッセージ文言 + コメント行を同期更新）
10. `tests/test-agents-structure.sh` — 変更不要と確認（TC-32/33/34 が PASS 維持することを実行して確認済み、literal 削除の影響なし）

**GREEN 確認（個別実行、full suite・nested runner 不使用）**:
- `bash tests/test-review-policy.sh` rc=0（PASS 6 / FAIL 0 / TOTAL 6、TC-01〜06 全 PASS）
- `bash tests/test-agents-structure.sh` rc=0（PASS 18 / FAIL 0、TC-32/33/34 含め全 PASS、drift guard 非破壊）
- `bash tests/test-rules-mirror.sh` rc=0（PASS 3 / FAIL 0、review-triage.md 追記後も byte-identical）
- `bash tests/test-codify-insight.sh` rc=0（PASS 23 / FAIL 0、TC-19 が Test Scripts=113 で PASS）
- `bash tests/test-review-integration-v24.sh` rc=0（12 passed / 0 failed、TC-04 frontmatter allowlist 非影響）
- `diff rules/review-triage.md .claude/rules/review-triage.md` → 差分なし（"review-triage mirror identical"）
- `jq . .claude/dev-crew.json` → valid JSON
- `wc -l skills/review/SKILL.md` → 50 行（<100 行制約内）

**想定外事象**: なし。全 GREEN 確認コマンドが期待通り rc=0 で完了。TC-10（steps-subagent.md Code Mode Task() count = 11、test-review-integration-v24.sh）も literal 削除後に変わらず PASS（Task() 呼び出し数自体は不変、model 引数のみ変更）であることを確認。

- Phase completed

### 2026-07-13 15:39 - REFACTOR + SELF-APPLY (PdM)

- チェックリスト 7 項目: Step 3.5「Reviewer Model 解決」は単一責務の prose ブロックで policy/self/explicit/escalate/NON-NEGOTIABLE を明示。config/doc 変更のみで構造リファクタ不要（no-op）。重複コード・定数化等いずれも該当なし
- Verification Gate: review-policy 6/6 / agents-structure 18/18（TC-32/33/34 drift 非破壊）/ rules-mirror 3/3 / codify-insight 23/23（count 113）/ review-integration 12/12 / SKILL.md 50 行（<100）/ label 契約 grep rc=1（clean）
- self-apply: rule C（親構造複製 baseline 112/112）/ rule D（bash 変更なし、tests は RED 成果物）/ rule E（全 worker + PdM が date 実測）— 準拠
- Phase completed

### 2026-07-13 15:52 - REVIEW (Codex competitive + 3 Claude reviewers, HIGH tier)

- **リスクスコア**: risk-classifier.sh 実測 HIGH 75（review pipeline 自身 + security floor に触れる meta 変更、multi-file）。#164 修正済み classifier のため doc-heavy 部の FP なし。HIGH tier で Codex + correctness + security + maintainability の 4 view 実施。全 reviewer に「テスト実行禁止・静的のみ」明示
- 判定: **Codex BLOCK 1 + WARN 1 / correctness WARN(MED 1) / security PASS / maintainability WARN(4)**
- **triage（accept-apply 7 / reject 0）**:
  1. **Codex BLOCK（escalate_high_to=self の floor break）**: accept-apply。`escalate_high_to: "self"` が生の `model: "self"`（未定義）を Task に渡し、HIGH 時に floor 起動を失敗させ得る。→ Step 3.5 手順4 + reference.md 解決順1 を「escalate_high_to も self を同じ規則で解決（生 self を渡さない）」に修正。加えて security の非 blocking 提案「allowlist 外 → self フォールバック（fail-safe）」も Step 3.5 手順5 + reference.md に追記
  2. **correctness MED（review-triage L11 自己矛盾）**: accept-apply。**PdM の判断2=案2 実装が誤り** — LOW tier の reviewer は Codex+correctness+security の3つで maintainability は存在しない（MED から参加）。「maintainability 省略可」は省略対象不在で無意味、かつ steps-subagent が maintainability を Always-on に置くのと矛盾。→ LOW tier の trivial 緩和句を**削除**し「security+correctness は floor として trivial でも常時必須（省略しない）」に。mirror 同期。negative contract（correctness/maintainability 省略可 とも 0 件）確認
  3. **maintainability F1（test-reviewer の risk-gated 誤ラベル）**: accept-apply。test-reviewer は flags-based（risk 非依存）。Step 3.5 + reference.md の分類表記を「risk-gated の performance/api-contract/observability + flags-based の test-reviewer」に分離
  4. **maintainability F2（reference.md ⇔ steps-subagent の DRY drift）**: accept-apply。TC-03 を reference.md の self-rule も pin する形に拡張（片方編集での drift 検出）。※ maint が review skill に steps-teams.md 不在を確認 — multi-mode drift は reference⇔steps の2ファイルのみ
  5. **maintainability F3（非対象リスト不完全）**: accept-apply。「非対象」を **Plan Mode 全 reviewer + review-briefer + Code Mode の product/usability** に包括的に書き換え（security/performance が Plan Mode で対象と誤解される穴を塞ぐ）
  6. **Codex WARN + maintainability F4（TC-06 が 3 reviewer のみ）**: accept-apply。TC-06 を Code Mode section-scoped で 7 reviewer（+ performance/api-contract/observability/test）に拡張
  7. **security PASS**: config で floor bypass 経路なしを確認（floor Task は review_policy と無関係に無条件実行、最悪でも fail-safe = 弱モデルで実行、fail-open ではない）。本 cycle が floor の**初の契約テスト**（TC-04/06）を追加した点も改善と評価
- 適用後検証: review-policy 6/6（TC-03 drift + TC-06 7件）/ agents-structure 18/18（TC-34 非破壊）/ rules-mirror 3/3（review-triage byte-identical）/ negative contract 0 件 / escalate_high_to self 解決記述あり / SKILL.md 50 行 / label 契約 clean
- Phase completed

## DISCOVERED

- [x] D1: per-cycle frontmatter 上書き（codex_mode パターン）→ issue #170 起票済み（v1 Out of Scope）
- [x] D2: human policy（REVIEW で人間承認、pause 制御フロー）→ issue #171 起票済み（v1 Out of Scope）
- [x] D3: reviewer agent frontmatter の model 既定見直し（真の inherit 化、TC-04/TC-34 同時修正が必要で scope 大）→ issue #172 起票済み

## Retrospective

抽出時刻: 2026-07-13 16:00
抽出方法: Cycle doc 全体（Codex plan BLOCK 2 / code BLOCK 1 / PdM 判断2 の実装誤り / reviewer 4 view）からの失敗→最終解→insight ペア抽出

### Insight 1: 「省略した引数は上位を継承する」系の前提は、実際の解決順を doc で確認してから plan に書く
- **Failure**: plan 中核前提「self = Task の model 省略で executor 継承」が事実誤認。実際の Claude Code の model 解決順は env → 呼び出し時 model → **subagent frontmatter** → main model で、reviewer は frontmatter に model:sonnet を持つため省略しても executor でなく sonnet に落ちる。Codex plan review が公式 doc 参照で反証（BLOCK）。approve は誤前提の上で得ていた
- **Final fix**: 「self なら orchestrator 自身の現モデルを Task に明示的に渡す（省略しない）」に再定義。ユーザーに意味論・コストを再確認して承認を得直した
- **Insight**: **「省略/デフォルトで上位（executor/親）を継承する」という前提は、フレームワークの解決順を一次ソース（公式 doc）で確認してから plan に書く。特に model/config/env の継承は直感と逆のことが多い。否定形前提（rules/plan-discipline.md）の姉妹版: 「継承する」という肯定形前提も未検証なら書かない**
- **一般化**: plan-discipline.md 追記候補（継承前提の一次ソース確認）。adversarial reviewer が公式 doc を引いて反証した実例

### Insight 2: 既存の分類テーブルに項目を置換投入する時は、その項目が当該行に実在するか確認する
- **Failure**: PdM の判断2=案2 実装で review-triage.md LOW tier の「correctness 省略可」を「maintainability 省略可」に単純置換した。しかし maintainability は LOW tier（Codex+correctness+security の3 views）に存在せず MED tier から参加する。「存在しない項目を省略可」という無意味な文になり、かつ steps-subagent が maintainability を Always-on に置くのと矛盾。correctness reviewer が表構造との突合で検出
- **Final fix**: LOW tier の trivial 緩和句自体を削除（3 views 全てが floor なら省略対象が無い）
- **Insight**: **テーブル/リストの項目を置換投入する時は、置換先の行/tier にその項目が実在するかを構造と突合してから書く。「A を B に置換」は A と B が同じ文脈（同じ tier/行/scope）に属する時のみ意味を持つ。異なる tier の項目を持ち込むと省略対象不在・二重定義等の構造矛盾を生む**
- **一般化**: review-triage.md の tier 構造への変更時の checklist 候補。single-line replace の落とし穴

### 成功事例（observation）: 2 段階の adversarial review（plan + code）が誤前提と実装ミスを別々に捕捉
- Codex plan review が「self=継承」の誤前提を BLOCK で、Codex code review が「escalate_high_to=self の floor break」を BLOCK で、correctness reviewer が「判断2 の tier 構造矛盾」を検出。**plan phase と code phase で異なる層の誤りが出る**ため、両 phase で adversarial review を回す価値が実証された。特に config スキーマ（escalate_high_to の値解決）は plan では見えず code で初めて露出する。security reviewer は「config で floor を bypass できないか」を独立検証し PASS を出した — meta 変更（review 機構自身）では floor の堅牢性を専任で確認する価値

### 2026-07-13 16:02 - COMMIT

- 最終 full suite（Holdings 親構造複製 snapshot、直列、review-fix 反映後）: **113/113 全 rc=0（新 test-review-policy.sh 含む、回帰ゼロ）**（scratchpad/final2-cycle4.txt）
- pre-commit-gate（明示指定）rc=0 PASS → commit skill 経由で phase: DONE 遷移してから commit（Block 3 手順、frontmatter 区間限定編集）
- STATUS.md: Done 65→66、Test Scripts 113、Last updated 2026-07-13、Completed 行追加。README/AGENTS/CLAUDE は skill 数・description 不変（review_policy は挙動変更）のため SKIP
- commit 同梱: 実装 9 ファイル + test-review-policy.sh（新規）+ 本 cycle doc + docs/cycles/20260709_1125（Block 0 codify gate 出力）
- feature branch → PR → --admin merge
- Phase completed
