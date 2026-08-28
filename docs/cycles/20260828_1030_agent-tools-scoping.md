---
feature: agent-tools-scoping
cycle: 20260828_1030
phase: DONE
complexity: standard
test_count: 14
risk_level: medium
retro_status: captured
codex_mode: no
codex_session_id: "01a04228-cbba-7352-b84a-b42f04baba70"
plan_file: /Users/morodomi/.claude/plans/refactored-beaming-seahorse.md
created: 2026-08-28 10:30
updated: 2026-08-28 15:13
---

# reviewer 系 agent の tools: scoping（#194）

## Scope Definition

### In Scope
- [ ] agents/*.md 33 ファイル + dast-crawler.md へ正規キー `tools:` 付与（キー順: name → description → model → memory → tools → disallowedTools。memory/disallowedTools は memory 保持 15 agent のみ付与、他 18 agent は tools のみ）
- [ ] 既存 `allowed-tools:`（18 件）を `tools:` へ rename（skill 専用キーで subagent では無視されるため）
- [ ] dast-crawler.md: `allowed-tools` 行削除（`tools:` 無し = 全継承のまま）+ 本文の Playwright ツール名 drift 修正（旧 `navigate/click/screenshot/evaluate` → 新 `browser_navigate/browser_click/browser_take_screenshot/browser_evaluate`）+ 「Playwright MCP はユーザー環境で設定済みが前提（plugin 非同梱）」の一文追記
- [ ] tests/test-agents-structure.sh へ契約 TC-36〜TC-45（+ 条件付き TC-46）を追加（新規 test file は作らない、`get_frontmatter()` 再利用）
- [ ] AGENTS.md:56 frontmatter 契約行を `(name, description, model, memory?, tools?)` に更新 + read-only/writer の 1 文追記
- [ ] skills/evolve/reference.md:45-51 の agent 生成テンプレートに `model: sonnet` / `tools: Read, Grep, Glob` を追加
- [ ] CHANGELOG.md に `## [Unreleased]` セクション新設（Breaking: 33 agent の暗黙全ツール継承喪失 + memory 保持 15 agent の disallowedTools による読取専用化・自動蓄積停止 / Changed: allowed-tools→tools 正規化 + 33 agent のツール限定、memory 保持 15 agent は `memory: project` 維持 + `disallowedTools: Write, Edit` 追加（probe D 実測結果確定: 起動時読取可・書込不可） / Fixed: dast-crawler ツール名 drift）
- [ ] GREEN 内で memory × tools の実効確認 runtime probe（scratchpad 配下の headless 新セッション、`claude -p --agents` 相当）を実施し、結果を Cycle doc Progress Log に記録（probe 0: 正の対照棄却実験 / 1: memory 外書込確認 / 2: `disallowedTools: Write, Edit` 抑止可否確認 / 3: `git status --short` clean 確認）

### Out of Scope
- `@playwright/mcp` の plugin 同梱（初稿案。撤回済み。理由: 外部実行物を追加しない方針、および plugin 配布 agent は `mcpServers` 非対応）
- dast-crawler への `tools:` 指定によるツール正規化（案 A 採用。playwright MCP 未設定環境での起動拒否を避けるため全継承のまま据え置き）
- #144（隔離 snapshot 上の逐次 rc=0 → standalone rc=1 の staleness 挙動）の根本修正（Issue へのコメント含め本 cycle では扱わない。DISCOVERED に記録のみ）
- ROADMAP.md「現在地」stale 記述の更新（#177 対象、本 cycle 範囲外）

### Files to Change (target: 10 or less)

**注記**: 本 cycle は「群単位で完全一致の値を pin する」契約テスト駆動の system-wide 変更のため、個別ファイル 34+ 件を group A〜D に集約して転記する（plan 本文の構造をそのまま踏襲）。

#### A. agents/*.md — `tools:` 付与 33 + dast-crawler 1（writer 6 + reference 1 は据え置き）

| 群 | ファイル | 操作 | tools 値（完全一致） |
|----|---------|------|---------|
| G1 reviewer 13 | api-contract / change-safety / correctness / design / impact / maintainability / observability / performance / product / resiliency / security / test / usability -reviewer.md | 追加 | `Read, Grep, Glob` |
| G1 review 補助 3 | socrates.md, review-briefer.md, observer.md | 追加 | `Read, Grep, Glob` |
| G1 static attacker 12 | api / auth / crypto / csrf / error / file / injection / ssrf / ssti / wordpress / xss / xxe -attacker.md | rename | `Read, Grep, Glob` |
| G1 filter 1 | false-positive-filter.md | rename | `Read, Grep, Glob` |
| G2 attack-scenario.md | 読取のみ | rename | `Read` |
| G3 sca-attacker.md | OSV API curl | rename | `Read, Grep, Glob, Bash` |
| G3 recon-agent.md | 列挙 | rename | `Bash, Read, Grep, Glob` |
| G3 dynamic-verifier.md | live probe | rename | `Bash, Read` |
| G4 dast-crawler.md | `allowed-tools` 行削除、`tools:` 無し + 本文 L29-32 ツール名修正 | — | （未指定 = 全継承） |

G1=29、G2=1、G3=3 → `tools:` を持つ agent 33。据え置き（`tools:` 無し）= designer.md, architect.md, sync-plan.md, red-worker.md, green-worker.md, refactorer.md, dast-crawler.md の 7。false-positive-filter-reference.md は frontmatter 無しの参照 doc（除外）。

#### B. tests/test-agents-structure.sh — 契約 TC 追加（TC-36〜TC-45、条件付き TC-46。新規 test file は作らない）

既存最大 TC-35。ヘッダコメント L3-4 も更新。群リストは test 内に明示配列で持つ（G1/G2/G3/据え置き 7）。

| TC | 契約 | RED 時の期待 |
|----|------|-------------|
| TC-36 | 非 reference agent 40 件の frontmatter に `allowed-tools:` が 0 件 | FAIL（18 件） |
| TC-37 | G1 29 件の `tools:` 値が `Read, Grep, Glob` に完全一致 | FAIL（0 件） |
| TC-38 | G2/G3 4 件の `tools:` 値が上表の値に完全一致 | FAIL |
| TC-39 | 据え置き 7 件は `tools:` も `allowed-tools:` も持たない | dast-crawler の allowed-tools で FAIL |
| TC-40 | 全 `tools:` 値のトークンが正準名集合 `Read Grep Glob Bash` のみ | 空集合で vacuous PASS（保護契約） |
| TC-41 | G1〜G3 33 件 + 据え置き 7 件 = 40 件で非 reference agent 全数と一致 | PASS（現状保護） |
| TC-42 | dast-crawler.md 本文に旧名 4 件が 0、新名 4 件が各 1 件以上 | FAIL |
| TC-43 | skills/evolve/reference.md 該当見出し区間内 code block に `model:` と `tools:` がある | FAIL |
| TC-44 | AGENTS.md の `\| Agents \|` 行に `tools` を含む | FAIL |
| TC-45 | CHANGELOG.md `## [Unreleased]` 見出し区間内に `allowed-tools` と `tools` 両語を含む行がある | FAIL |
| TC-46 | （probe D step 4 実測により確定: memory 削除ではなく memory 維持 + disallowedTools 併用へ再定義）memory 保持 15 件の `memory:` が `project`、`disallowedTools:` が `Write, Edit` に完全一致。加えて tools:-scoped 33 agent の不変条件（memory を持つものは必ず disallowedTools を持つ） | 実装済み |

#### C. docs
- `AGENTS.md:56`: `Markdown with YAML frontmatter (name, description, model)` → `(name, description, model, memory?, tools?)` + read-only/writer 説明の1文
- `skills/evolve/reference.md:45-51`: テンプレートに `model: sonnet` と `tools: Read, Grep, Glob` を追加（コメントで Edit/Write 必要な agent は tools 省略と明記）
- `CHANGELOG.md`: `## [Unreleased]` 新設。Breaking（33 agent の暗黙全ツール継承喪失 + memory 保持 15 agent の disallowedTools による読取専用化・自動蓄積停止） + Changed（allowed-tools→tools 正規化、33 agent のツール限定。memory 保持 15 agent は `memory: project` 維持 + `disallowedTools: Write, Edit` 追加で読取専用化） + Fixed（dast-crawler の Playwright ツール名 drift）
- `docs/STATUS.md`: Completed 行追加は commit skill の既定動作（本 cycle 固有 test は置かない、precedent 踏襲）。Test Scripts 115 / Agents 41 不変

#### D. GREEN 内 runtime probe（memory × tools の実効確認、成果物は Cycle doc 記録のみ）

scratchpad 配下の一時ディレクトリで headless の新セッションを起動して実測（`claude -p --agents` / cwd の `.claude/agents/` を新セッション開始時に読む）:

0. 正の対照（棄却実験）: `$SCRATCH/probe/.claude/agents/probe-memory-tools.md`（`memory: project`、`tools: Read, Grep, Glob`）を作成し、`claude -p --permission-mode bypassPermissions` で agent が実際に起動・応答することを確認。応答に seed 内容が含まれなければ probe 自体無効として D を保留
1. 同ディレクトリで `outside.txt` 作成を指示 → 有無と stdout 全文を Cycle doc に記録
2. 1 で書込が通った場合: `disallowedTools: Write, Edit` を追加して再実行 → 抑止できれば memory 保持 15 件に付与し TC-46 で pin。抑止できない場合は DISCOVERED と CHANGELOG に「memory 保持 15 agent は Write/Edit が残る（実測）」と明記し宣言契約のみで受入（ユーザー既決の override 対象、下記 Plan Review Record 参照）
3. probe ディレクトリは repo 外（scratchpad）。`git status --short` clean を GREEN 末尾で確認

## Environment

### Scope
- Layer: Plugin definition（agents/*.md frontmatter + shell tests）
- Plugin: dev-crew self（bash 3.2.57 / git 2.49.0 / yamllint 経由 scripts/validate-yaml-frontmatter.sh）
- Risk: 40 (WARN) — Scope Impact +40（34 ファイルの system-wide 変更）。External Dependency は該当なし（初稿の `@playwright/mcp` 同梱案は撤回、外部実行物を追加しない）。Security/Data キーワード該当なし

### Runtime
- Language: bash 3.2.57(1)-release (arm64-apple-darwin25)

### Dependencies (key packages)
- yamllint: validate-yaml-frontmatter.sh 経由
- codex-cli: 0.144.3

### Risk Interview (BLOCK only)
- 該当なし（Risk 40 は WARN であり BLOCK ではないため Risk Interview は未実施）

## Context & Dependencies

### Reference Documents
- 公式 doc https://code.claude.com/docs/en/sub-agents.md — subagent 正規キーは `tools:`（`allowed-tools` は skill 専用、subagent では無視される）。認識フィールド: name / description / tools / disallowedTools / model / permissionMode / skills / memory / mcpServers / maxTurns / isolation / hooks / background / color
- plugins-reference doc — 「For security reasons, `hooks`, `mcpServers`, and `permissionMode` are not supported for plugin-shipped agents」（plugin 配布 agent での mcpServers 非対応の根拠）
- docs/cycles/archive/20260216_1432_model-selection-hints.md — frontmatter キー順序規約（`name → description → model → memory → allowed-tools`）の当時の設定元。本 cycle は `allowed-tools` を `tools` に読み替えて順序自体は踏襲
- rules/test-patterns.md — 「whole-file grep で frontmatter state」判定禁止。TC-36〜45 は `get_frontmatter()` によるフロントマター範囲限定判定で準拠

### Dependent Features
- skills/review/steps-subagent.md:40,43,84,190 — reviewer が Brief を prompt で受け取る設計（reviewer から Bash を外す根拠）

### Related Issues/PRs
- Issue #194: reviewer 系 agent の tools scoping（CCAR-F Task Statement 2.3 評価 2026-08-27 で特定）

## Recall

`bash scripts/recall-candidates.sh . agents/security-reviewer.md agents/socrates.md agents/api-attacker.md tests/test-agents-structure.sh AGENTS.md docs/STATUS.md` 上位:

### docs/cycles/archive/20260216_1432_model-selection-hints.md（score 2.03）
- **何が起きたか**: 全 agent に `model:` を追加。フィールド順序を `name → description → model → memory → allowed-tools` と規定した
- **当時の前提**: `allowed-tools` が agent で有効なキーである、という暗黙の前提
- **今回も同じ前提か**: **No**。公式 doc で `allowed-tools` は skill 専用と確認。当時の順序規約は `tools` に読み替えて踏襲する（順序自体は妥当）

### docs/cycles/archive/20260218_0545_v2_restructuring.md（0.53）/ 20260216_1049_fix-reviewer-scoring.md（0.50）
- **何が起きたか**: 単一 plugin 化（`1c8225c` で allowed-tools が agents/ に入った commit）と reviewer スコア修正
- **当時の前提**: agent 定義の検査は name/description/model の存在で十分
- **今回も同じ前提か**: No。tools 契約を test-agents-structure.sh に追加する（同ファイルへの TC 追加で count 契約に触れない precedent: cycle 20260721_1503 L213）

### docs/cycles/20260317_0200_phase15_3_socrates_review_integration.md（0.26）
- **何が起きたか**: socrates を read-only 前提で pipeline 統合（socrates.md:24「Edit/Write/Bash 不可」、:65「reviewer を spawn しない」）
- **当時の前提**: プロンプト記述で read-only が守られる
- **今回も同じ前提か**: No。プロンプト規律を `tools:` で決定論化する（Agent/Task を含めないことで spawn 禁止も機械化）

## Test List

### TODO
(none)

### WIP
(none)

### DONE
- [x] TC-14: （probe D 実測により再定義・別 worker 対応、最終契約）Given memory 保持 15 agent / When `get_frontmatter memory` と `get_frontmatter disallowedTools` / Then memory は `project` を維持しつつ `disallowedTools: Write, Edit` を併記（memory: project + disallowedTools: Write, Edit）— TC-46 として Files to Change B へ未転記、本 RED では未着手 — GREEN で TC-46（tests/test-agents-structure.sh）として実装済み、PASS 確認
- [x] TC-01 (→ TC-36): Given 非 reference agent 40 件 / When frontmatter を awk 抽出し `^allowed-tools:` を数える / Then 0 — GREEN PASS
- [x] TC-02 (→ TC-37): Given G1 29 件 / When `get_frontmatter tools` / Then 文字列が `Read, Grep, Glob` に完全一致 — GREEN PASS
- [x] TC-03 (→ TC-38): Given G2/G3 4 件 / When 同上 / Then 各ファイル指定値に完全一致 — GREEN PASS
- [x] TC-04 (→ TC-39): Given 据え置き 7 件 / When `^tools:` と `^allowed-tools:` / Then 両方 0 — GREEN PASS
- [x] TC-05 (→ TC-40): Given 全 `tools:` 値 / When トークン分割 / Then 全て ∈ {Read, Grep, Glob, Bash} — GREEN PASS（保護契約）
- [x] TC-06 (→ TC-41): Given 群リスト合計 / When 非 reference agent 実数と比較 / Then 40 = 40 — GREEN PASS（保護契約）
- [x] TC-07 (→ TC-42): Given dast-crawler.md 本文 / When `grep -cF` 旧名 4・新名 4 / Then 旧 0 / 新 ≥1 — GREEN PASS
- [x] TC-08 (→ TC-43): Given evolve/reference.md / When 見出し区間の code block を抽出 / Then `model:` と `tools:` を含む — GREEN PASS
- [x] TC-09 (→ TC-44): Given AGENTS.md / When `| Agents |` 行 / Then `tools` を含む — GREEN PASS
- [x] TC-10: Given 変更後 agents/*.md / When scripts/validate-yaml-frontmatter.sh 全件 / Then rc=0（既存 test-yaml-frontmatter.sh TC-Y2）— GREEN で実行、非 reference agent 40 件 rc=0（SKIP/FAIL 0 件）
- [x] TC-11: Given 既存 model / memory pin（TC-21〜34、test-test-reviewer.sh 等 5 件）/ When full-suite / Then 回帰なし — GREEN で該当 test file 単体実行、全 PASS・回帰なし
- [x] TC-12: Given probe fixture（memory + tools 限定、headless 新セッション）/ When memory 外への書込を指示 / Then `outside.txt` の有無を Cycle doc に記録し D-2 で分岐 — Progress Log「2026-08-28 10:45 - PROBE D」で PdM が直接実測・記録済み
- [x] TC-13 (→ TC-45): Given CHANGELOG.md / When `## [Unreleased]` 区間を抽出 / Then `allowed-tools` と `tools` を含む行 ≥1 — GREEN PASS

### DISCOVERED
- #144 関連観察: 隔離 snapshot 上で「逐次 rc=0 → 直後 standalone rc=1」を再現（test-hooks-structure.sh / test-trap-handler.sh、TC-05: CLAUDE.md 40日 / AGENTS.md 36日の staleness 警告）。先行 test が残す状態の疑い。Issue へのコメントは scope 外、別途ユーザー判断
- test-agents-structure.sh TC-21 の pass 文字列「All 32 agents」が stale（cosmetic）
- dast-crawler は Playwright MCP のユーザー側設定が前提。plugin で MCP を提供する場合は `.mcp.json` 同梱（ツール名は `mcp__plugin_dev-crew_<server>__*`）が唯一の経路 — 別 Issue 候補

### DONE
(none)

QA: 契約 10 項目（+条件付き 1）を各 1 TC で pin。完全一致で「必要ツールの脱落」と「不要ツールの混入」を両方向検出。独立性: TC ごとに count を再取得。負の oracle: TC-42（Test List 上は TC-07）の旧名/新名 substring 関係を実測済み（`printf 'mcp__playwright__browser_navigate\n' | grep -cF "mcp__playwright__navigate"` = 0）。RED で vacuous PASS するのは保護契約（TC-05/06 に相当する TC-40/41）のみで、他は FAIL する。

## Implementation Notes

### Goal
agents/*.md 41 ファイルは全て harness 上「All tools」で起動している構造的逸脱（#194）を解消する。read-only / Bash 要の 33 agent + dast-crawler 1 に正規キー `tools:` で最小ツールセットを付与し、writer 6（designer/architect/sync-plan/red-worker/green-worker/refactorer）+ dast-crawler は据え置く（全継承）。契約テストで固定し、`memory: project` 併用時の実効ツールを runtime probe で実測記録する。

### Background
探索で発生機序を特定した:
- 18 agent は既に `allowed-tools:` を持つが、これは skill 専用キーで subagent では無視される。subagent の正規キーは `tools:`（未指定時は全ツール継承）
- 残り 22 agent（reviewer 13 / socrates / review-briefer / observer + writer 6）は tools 系キー自体が無い
- `grep -rn "^tools:" agents/` = 0 件

結果として reviewer が Write/Edit/Bash を持ち、「指摘を出す代わりに黙って直す」経路と、ツール選択肢過多による選択信頼性低下が全 agent に及んでいる。

**Baseline（実測、隔離 snapshot）**: `scratchpad/baseline.txt` — 115 test 中 rc=0 が 115（snapshot 上で逐次実行）。ただし standalone 実行では `test-hooks-structure.sh` / `test-trap-handler.sh` が rc=1（TC-05: CLAUDE.md 40日 / AGENTS.md 36日の staleness 警告）。同一 snapshot で逐次 rc=0 → 直後の standalone rc=1 を実測。#144（壁時計依存 + 先行 test が残す状態の疑い）の再現であり本 cycle 起因ではない。本 cycle は AGENTS.md を更新するため commit 後は staleness の片側が消えるが根本解は #144。

**逆向き契約 sweep**:
- `grep -rn "allowed-tools" tests/`: 該当は skill 側の検査のみ（test-phase-gate.sh:183,192 / test-codify-insight.sh:54-68 / test-cycle-retrospective.sh:50-58 / test-discovered-debt-cleanup.sh:75-84 / test-skill-maker.sh:196-200）。agents/ の allowed-tools を検査する test は 0 件 → rename で壊れる test なし
- agent frontmatter の既存 assertion は全て `^key:` grep か awk 範囲抽出で、位置・件数・許可キー列挙は 0 件（test-agents-structure.sh:17-23 `get_frontmatter`）
- `memory: project` pin 5 件（test-test-reviewer.sh:36、test-api-contract-reviewer.sh:46、test-maintainability-reviewer.sh:45、test-observability-reviewer.sh:45、test-performance-reviewer-enhancement.sh:43）: memory を維持するため影響なし
- yamllint oracle（scripts/validate-yaml-frontmatter.sh、実測 rc=0）: `tools: Read, Grep, Glob` PASS
- TC-42 negative oracle: `printf 'mcp__playwright__browser_navigate\n' | grep -cF "mcp__playwright__navigate"` = 0（旧名は新名の部分文字列にならない、実測済み）
- CHANGELOG.md: `[Unreleased]` セクションは現在存在しない（先頭は `## [2.15.0]`）→ 新設する

### Design Approach
**Ambiguity Resolution（人間決定含む）**:
- **キー名**: `allowed-tools` → `tools` へ rename（公式 doc 一次ソースで確定。両立させない — 無視されるキーを残すと次の drift を生む）
- **memory: project との共存**: 維持する（ユーザー決定、確定: PROBE D step 4 の再承認）。公式 doc「When memory is enabled: Read, Write, and Edit tools are automatically enabled so the subagent can manage its memory files」。`disallowedTools: Write, Edit` を追加すると Write/Edit は抑止できるが memory への書込も同時に不可になる（実測、PROBE D step 2/3）。一方で `disallowedTools: Write, Edit` を付けても起動時の既存 MEMORY.md 読取（tool 使用なし）は可能（実測、PROBE D step 4）。この「知見保持・書込不可・tools 逸脱不可」という組合せにより、当初検討した「memory 削除」（PROBE D 初回判定）を撤回し、memory 保持 15 agent は `memory: project` を維持したまま `disallowedTools: Write, Edit` を付与する方式で確定した
- **dast-crawler の MCP 依存**: `tools:` を付けず全継承にする（ユーザー決定、案 A）。理由: (1) `tools:` に mcp__playwright__* を正規化すると playwright MCP 未設定環境で agent が起動拒否される（v2.1.208+）、(2) plugin 配布 agent は `mcpServers` 非対応、(3) plugin `.mcp.json` 同梱は全ユーザーに playwright を強制するため不採用。無視されている `allowed-tools` 行は削除し、本文のツール名 drift（4 件）のみ修正
- **evolve テンプレート**: 含める（ユーザー決定）。現状 name/description のみで TC-21（model 必須）と既に不整合
- **Bash を reviewer から外す**: 外す。reviewer は Brief を prompt で受け取り、Brief 不足時は orchestrator が raw diff で再実行する設計であり、reviewer 自身が git diff を取る設計ではない。ただし 8 reviewer は file/line を出力するため Read/Grep/Glob は必要（review-briefer.md の 1500 token 上限で Brief が引用を省くため）

## Verification

**Real-path invocation を最低 1 件含めること**（rules/integration-verification.md）。

1. RED: TC-36〜39, 42〜44 が変更前に FAIL、TC-40/41 は保護契約として PASS（Cycle doc に明記）
2. GREEN: `bash tests/test-agents-structure.sh` 全 PASS、`bash scripts/validate-yaml-frontmatter.sh` を非 reference agent 40 件に適用し rc=0、probe D の結果を Cycle doc Progress Log に記録
3. 逆向き契約 sweep: `grep -rln "allowed-tools\|memory: project" tests/` の全 file を実行し回帰 0
4. full-suite: `bash run-tests.sh`（standalone FAIL の test-hooks-structure / test-trap-handler は #144 既知として切り分け。AGENTS.md 更新後は片側解消）
5. 実機（Real-path invocation）: plugin 再インストール後、本セッション相当の agent 一覧で `dev-crew:security-reviewer` が `(Tools: Read, Grep, Glob)`、`dev-crew:dast-crawler` が `(Tools: All tools)` と表示されること

```bash
# テスト実行（補完）
for f in tests/test-*.sh; do bash "$f"; done
```

Evidence: (orchestrate が自動記入)

## Progress Log

### 2026-08-28 10:30 - KICKOFF
- Cycle doc created
- Scope definition ready

### 2026-08-28 10:30 - Plan Review (pre-approval)
- codex_session_id: 01a04228-cbba-7352-b84a-b42f04baba70
- review_attempts:
  - {started: 16:39, completed: 16:46, verdict: BLOCK}
  - {started: 23:50, completed: 23:54, verdict: BLOCK}
- findings 要約: attempt 1 (BLOCK): mcpServers は plugin agent 非対応（採用 → 案 A に変更） / memory 併用で実効ツール未検証（採用 → GREEN runtime probe D） / memory pin 5 test の逆向き契約（採用 → 影響なしを明記） / TC が値を pin していない（採用 → 群別完全一致） / risk 誤分類（採用 → playwright 同梱撤回で External なし、40 維持） / CHANGELOG [Unreleased] 不在（採用 → 新設） / RED 期待の不正確（採用 → TC 別に明記） / #144 コメントは scope creep（採用 → DISCOVERED 経路のみ）。attempt 2 (BLOCK): 解消 5 件（mcpServers / memory 逆向き契約 / TC 値 pin / risk / RED 期待）。未解消 3 件を再レビュー後に plan へ反映: (a) memory 件数誤り 17→15 + attack-scenario 含む deny 対象 + CHANGELOG 文言を probe 結果条件付きに修正 (b) CHANGELOG を TC-45 で pin（STATUS 行は commit skill 既定、test 無しの precedent 踏襲） (c) #144 Issue コメントを scope から完全に外す。新規 BLOCK「probe が同セッションで起動不可」→ headless 新セッション（`claude -p`、scratchpad 配下 `.claude/agents/`）方式に変更（`--agents` フラグ存在を `claude --help` で実測）。Step 8 契約（再レビューは 1 回）により Codex 再々レビューは実施せず、残余は unresolved_blocks として人間 override に委ねる
- unresolved_blocks: memory 保持 15 agent の実効 Write/Edit は harness 仕様依存で plan 段階では未確定（probe D で実測。抑止不能なら宣言契約のみで受入）
- plan_presented: 2026-08-27 23:59
- reviewed_plan_hash: bf56d9a8a365ce6d02610930bce6f58271c53d774f7204df1a32927ae8e351f2
- override: ユーザーは AskUserQuestion で「memory 維持」と「runtime probe を scope に含める」を明示選択済み（2026-08-27）。ExitPlanMode 承認をもって本 unresolved_block の override とする（承認提示文に明記）
- verdict: BLOCK-overridden
- Phase completed

### 2026-08-28 10:35 - ARCHITECT
- Design Review Gate（plan 内部整合 + 実ファイル突合）: PASS（score ~15）
  - Scope: In Scope 8項目は具体的。Files to Change は群単位（A〜D）で34+ファイルを表現しているが、「群単位で完全一致の値を pin する契約テスト駆動の system-wide 変更」という注記付きで plan 本文の構造をそのまま転記しており、mirror 必然のケース（同一 rename を41ファイルへ機械的に適用）に該当。10件超過は軽微ペナルティのみ
  - Architecture: 実ファイル突合で以下を確認し plan の前提と一致を実測
    - `grep -l '^allowed-tools:' agents/*.md | wc -l` = 18、`grep -l '^tools:' agents/*.md` = 0（plan 記載と一致）
    - `agents/*.md` 実数 = 41（false-positive-filter-reference.md 含む）。G1(29)+G2(1)+G3(3)+据え置き7 = 40 + reference 1 = 41 で一致
    - dast-crawler.md: `allowed-tools: Read, Bash, mcp__playwright__*` と本文 L29-32 に旧ツール名 `mcp__playwright__navigate/click/screenshot/evaluate` を実測（plan の修正対象と一致）
    - socrates.md / security-reviewer.md: `tools:`/`allowed-tools:` 無し、`memory: project` あり（plan の「据え置き対象外・memory 保持」分類と一致）
    - api-attacker.md: 既存 `allowed-tools: Read, Grep, Glob`（rename 対象、plan と一致）
    - memory 保持 15件claim（G1 12 + G2 1 + G3 2）を個別 grep で実測し全15件が `memory: project` を保持することを確認
    - `tests/test-agents-structure.sh` 最大 TC = TC-35（plan の「既存最大 TC-35」と一致）、`get_frontmatter()` 関数は frontmatter 区間限定抽出（`awk '/^---$/{n++;next} n==1{print}'`）で rules/test-patterns.md の whole-file grep 禁止に準拠
  - Test List: 14項目、Given/When/Then 形式で全て bash oracle により検証可能。カテゴリは主に構造契約（正常系中心）だが本 cycle が doc/frontmatter の静的変更のみのため妥当
  - Risk: score 40 (WARN) は 34+ファイルの system-wide 変更と整合。Risk Interview は WARN のため未実施（plan 記載通り、BLOCK 時のみ必須）
- Post-Transfer Verification（plan ↔ Cycle doc 転記比較）: 転記欠落なし
  - Plan Review Record 全フィールド（codex_session_id / verdict / reviewed_plan_hash / findings 要約 / review_attempts 2件 / plan_presented / unresolved_blocks / override）が Progress Log 「2026-08-28 10:30 - Plan Review (pre-approval)」に verbatim 転記済み。frontmatter にも codex_session_id / plan_file が転記済み
  - Test List 14/14 転記済み（TC-01〜TC-14、内容は plan の番号なしリストと一致）
  - Files to Change: plan の群構成（G1〜G4、据え置き7、TC-36〜46）を Cycle doc In Scope / Files to Change / Test List へそのまま転記。scope 実質変更なし
  - reviewed_plan_hash（64桁 sha256、bf56d9a8...）は plan/Cycle doc 間で完全一致。承認後の plan 本文との再照合は不要（審査後の反映は state-ownership.md により plan 側は編集不可のため、hash はレビュー時点のスナップショットを指す）
- issues:
  - 観察: plan「memory pin 5 件」のうち test-api-contract-reviewer.sh:46 / test-maintainability-reviewer.sh:45 / test-observability-reviewer.sh:45 / test-performance-reviewer-enhancement.sh:43 の4件は、plan本文が想起した `grep "memory: project"` 形式の literal pin ではなく `get_frontmatter "$AGENT_FILE" "memory"` の戻り値を `"project"` と比較するシェル変数比較形式だった（test-test-reviewer.sh:36 のみ literal grep）。実測結果は「4件とも memory pin が機能的に存在し plan の主張（memory維持のため影響なし）は成立」であり、本 cycle は `memory:` 行を変更しないため regression リスクはない。scope 実質変更ではなく観察のみ
- discovered:
  - 上記 memory pin 表記差異の観察を Cycle doc DISCOVERED セクションへの追記は不要と判断（regression なし、cosmetic）。architect からの追加 DISCOVERED 項目なし（plan 由来の3件は sync-plan により既に DISCOVERED セクションに転記済みで重複記載を避ける）
- Phase completed

### 2026-08-28 10:46 - RED
- 担当: TC-01〜TC-13（Files to Change B の TC-36〜TC-45 に対応）。TC-14（旧 disallowedTools 条件付き）は担当範囲外のため未着手のまま TODO に残置
- 変更ファイル: `tests/test-agents-structure.sh` のみ（新規 test file 追加なし、`get_frontmatter()` 既存 helper を再利用）。ヘッダコメント（L3-4）を TC-36〜45 の範囲に更新
- 追加した群配列: G1 29（reviewer 13 + review補助 3 + static attacker 12 + filter 1）/ G2・G3 4（attack-scenario, sca-attacker, recon-agent, dynamic-verifier）/ 据え置き 7（designer, architect, sync-plan, red-worker, green-worker, refactorer, dast-crawler）
- 追加 TC:
  - TC-36: 非 reference agent 40 件に `allowed-tools:` が 0 件であること
  - TC-37: G1 29 件の `tools:` が `Read, Grep, Glob` に完全一致
  - TC-38: G2/G3 4 件の `tools:` が各期待値（`Read` / `Read, Grep, Glob, Bash` / `Bash, Read, Grep, Glob` / `Bash, Read`）に完全一致
  - TC-39: 据え置き 7 件が `tools:`/`allowed-tools:` を両方持たないこと
  - TC-40: 全 `tools:` 値のトークンが `{Read, Grep, Glob, Bash}` のみ（保護契約）
  - TC-41: G1+G2+G3(33) + 据え置き(7) = 40 が非 reference agent 実数と一致（保護契約）
  - TC-42: dast-crawler.md 本文の旧 Playwright ツール名 4 件が 0、新名 4 件が各 1 件以上
  - TC-43: skills/evolve/reference.md の見出し区間先行抽出 → code block 内に `model:`/`tools:` を含む
  - TC-44: AGENTS.md の `| Agents |` 行に `tools` を含む
  - TC-45: CHANGELOG.md `## [Unreleased]` 見出し区間（先行抽出）に `allowed-tools` と `tools` を両方含む行が1行以上
- RED 実行結果: `bash tests/test-agents-structure.sh` → PASS 20 / FAIL 63 / TOTAL 83、rc=1
  - FAIL: TC-36 FAIL（18件, 未 rename の allowed-tools 残存）/ TC-37 FAIL（29件, tools 未実装）/ TC-38 FAIL（4件, tools 未実装）/ TC-39 FAIL（dast-crawler.md の allowed-tools 残存で1件）/ TC-42 FAIL（旧名4件残存・新名0件）/ TC-43 FAIL（evolve/reference.md 未実装）/ TC-44 FAIL（AGENTS.md 未実装）/ TC-45 FAIL（CHANGELOG.md `## [Unreleased]` セクション不在）
  - PASS: TC-40 PASS（vacuous, 保護契約）/ TC-41 PASS（群ロースター40=非reference agent実数40、保護契約）
  - 既存 TC-06〜TC-35: 変更前スクリプトとの出力 diff で完全一致を確認（回帰なし。`diff` の差分は新規追加した TC-36〜45 ブロックのみ）
- 逆向き契約: TC-42 の負の oracle（旧名は新名の部分文字列にならない）を fixture 実測で確認済み（plan 記載の printf oracle と一致）
- rules/test-patterns.md 準拠: frontmatter は既存 `get_frontmatter()`（awk 区間限定抽出）を再利用。count は `grep -cF ... || true` で単発取得。CHANGELOG/evolve reference の区間契約は「見出し区間先行抽出 → 区間内走査」の二段構成。`cmd | grep -q` 直結は不使用（`[[ ]]` glob 比較または here-string + `grep -c`）
- 発見事項（担当外・並行して PdM が Progress Log「2026-08-28 10:45 - PROBE D」で記録済み）: probe D の実測により TC-14/Files to Change B の TC-46 が「disallowedTools pin」から「memory: 削除（15 agent）」へ再定義された。TC-46 の test-agents-structure.sh への追加および memory pin test 5 件（test-test-reviewer.sh 等）の契約反転は本 RED worker の担当外（ファイル境界: tests/test-agents-structure.sh のみ）のため未着手。別途 GREEN 前に対応が必要
- Phase completed

RED Phase completed

---

## Next Steps

1. [Done] KICKOFF
2. [Done] RED（addendum 2 まで完了。REVIEW BLOCK を受けた契約テスト修正 + memory 維持 + disallowedTools への再定義を含む）
3. [Done] GREEN (re-run) <- Current
4. [Next] REFACTOR
5. [ ] REVIEW
6. [ ] COMMIT
7. [ ] DONE

### Phase: SYNC-PLAN - Completed at 10:40
**Artifacts**: Cycle doc created with PLAN section, Test List (14 items), Plan Review Record transferred (hash MATCH)
**Decisions**: architecture=frontmatter tools: 正規化（G1/G2/G3 完全一致値、writer 7 据え置き）, test strategy=test-agents-structure.sh に TC-36〜46 追加（新規 file なし）, codex_mode=no（Claude worker）
**Pre-Review**: verdict=PASS, score=15, issues=memory pin 4 件は get_frontmatter 比較形式（観察のみ）
**Next Phase Input**: Test List items TC-01 ~ TC-14（TC-14 は probe 条件付き）
**Subagent**: agent=architect(sonnet), tokens=107285

### 2026-08-28 10:45 - PROBE D (memory × tools 実測、PdM 直接実行、repo 外 scratchpad/probe)
- 方式: scratchpad/probe に `.claude/agents/probe-memory-tools.md` を置き、`claude -p --permission-mode bypassPermissions` で headless 新セッション起動（同セッション内では agent 定義がロードされないため）
- step 0 正の対照: `memory: project` + `tools: Read, Grep, Glob` の agent が seed.txt を読んで内容 `PROBE-SEED-7731` を返答 → agent 起動・ロード確認 OK
- step 1: 同 agent に memory 外 `./outside.txt` の作成を指示 → **作成された**（Write ツール使用、`PROBE-WRITE-OK`）。memory 併用時は tools 宣言に無い Write が任意パスに使える（harness 実測）
- step 2: `disallowedTools: Write, Edit` を追加して再実行 → `TOOL-UNAVAILABLE`、`outside2.txt` 未作成。**抑止できる**
- 対照（memory なし + tools のみ）: `outside3.txt` 未作成。tools 宣言単独で Write が無いことを確認（tools 制限の有効性）
- step 3: step 2 構成で memory への保存を指示 → `TOOL-UNAVAILABLE: Write`、memory 書込も不可。**disallowedTools は memory 機能自体を更新不能にする**（plan 段階で未知の副作用）
- 判定: plan D-2 の「抑止できれば disallowedTools 採用」は memory 更新不能という scope 実質変更を伴うため AskUserQuestion で再承認 → ユーザー決定「**memory 削除で read-only 確定**」（memory: project を 15 agent から外し、tools のみ。disallowedTools は不使用）
- scope 追加（再承認済み）: (1) 15 agent の `memory: project` 行削除 + 本文 `## Memory` セクション（「agent memory に記録せよ」）の削除、recon-agent.md:128 の「Check auto memory」ステップの削除 (2) memory pin test 5 件（test-test-reviewer.sh TC-03 / test-api-contract-reviewer.sh TC-03 / test-maintainability-reviewer.sh TC-03 / test-observability-reviewer.sh TC-03 / test-performance-reviewer-enhancement.sh TC-03）を「memory を持たない」契約へ反転 (3) TC-46 を「tools: を持つ 33 agent は `memory:` を持たない」に再定義（disallowedTools pin は不採用）
- 対象 15: api-contract-reviewer change-safety-reviewer correctness-reviewer impact-reviewer maintainability-reviewer observability-reviewer performance-reviewer resiliency-reviewer security-reviewer test-reviewer socrates false-positive-filter attack-scenario recon-agent dynamic-verifier
- probe 成果物は repo 外。`git status --short` に混入なし

### 2026-08-28 10:50 - RED (addendum)
- 担当: PROBE D 再承認 scope（Progress Log「2026-08-28 10:45 - PROBE D」参照）のうち RED 追加分 2 件。ファイル境界を以下 6 ファイルへ拡張（agents/*.md には未着手）
- 変更ファイル:
  1. `tests/test-agents-structure.sh`: TC-46 追加「tools: を持つ33 agent（G1 29 + G2/G3 4、既存の群配列 g1_agents/g23_names を再利用）は frontmatter に `memory:` を持たない」。ヘッダコメントを TC-36〜46 の範囲に更新
  2. memory pin test 5 件の TC-03 を「memory を持たない」契約へ反転（TC 番号・構造は維持、pass/fail 文言のみ反転）:
     - `tests/test-test-reviewer.sh:34-36`（`grep -q '^memory:'` 有無を反転）
     - `tests/test-api-contract-reviewer.sh` TC-03（`get_frontmatter memory` が空であることを確認）
     - `tests/test-maintainability-reviewer.sh` TC-03（同上）
     - `tests/test-observability-reviewer.sh` TC-03（同上）
     - `tests/test-performance-reviewer-enhancement.sh` TC-03（同上）
- RED 実行結果（各 test file を単体実行、full suite は未実行）:
  - `bash tests/test-agents-structure.sh` → PASS 20 / FAIL 78 / TOTAL 98、rc=1。TC-46 が想定通り 15 件 FAIL（api-contract-reviewer, change-safety-reviewer, correctness-reviewer, impact-reviewer, maintainability-reviewer, observability-reviewer, performance-reviewer, resiliency-reviewer, security-reviewer, test-reviewer, socrates, false-positive-filter, attack-scenario, recon-agent, dynamic-verifier — PROBE D の「対象15」と完全一致）。残り 18 件（tools:-scoped だが元々 memory 無し）は PASS。TC-06〜45 の出力は追加前と完全一致（回帰なし）
  - `bash tests/test-test-reviewer.sh` → TC-03 FAIL（`memory: project` が残存、期待通り）。他 TC は変更前と同一（TC-17 のリグレッションチェックは test-agents-structure.sh が RED 中のため連鎖 FAIL — 本 cycle の RED 状態に起因する既知の連鎖であり新規異常ではない）
  - `bash tests/test-api-contract-reviewer.sh` → PASS 9 / FAIL 2 / TOTAL 11、rc=1。TC-03 FAIL（`memory: project` 残存）+ TC-11（test-agents-structure.sh 呼び出しの回帰チェック）が連鎖 FAIL（同上の理由）
  - `bash tests/test-maintainability-reviewer.sh` → PASS 9 / FAIL 2 / TOTAL 11、rc=1。同上パターン
  - `bash tests/test-observability-reviewer.sh` → PASS 9 / FAIL 2 / TOTAL 11、rc=1。同上パターン
  - `bash tests/test-performance-reviewer-enhancement.sh` → PASS 9 / FAIL 2 / TOTAL 11、rc=1。同上パターン
- 確認事項: `git status --short` で変更ファイルが上記 6 ファイル（+ 本 Cycle doc）のみであることを確認。`agents/*.md` への変更ゼロ（`git diff --stat -- agents/` 出力なし）
- Phase completed

RED Phase completed

### 2026-08-28 10:56 - GREEN
- 担当: Files to Change A〜C 全量（agents/*.md 34 ファイル + AGENTS.md + skills/evolve/reference.md + CHANGELOG.md）。tests/*.sh は RED（+addendum）で実装済みのため変更なし
- 変更ファイル 37: agents/*.md 34（G1 29 + G2/G3 4 + dast-crawler 1）+ AGENTS.md + skills/evolve/reference.md + CHANGELOG.md
- agents/*.md 34 ファイルへの適用内容:
  - G1 29（reviewer 13 + review 補助 3 + static attacker 12 + filter 1）: `tools: Read, Grep, Glob` を付与（review 補助・reviewer 系 16 は新規追加、attacker/filter 13 は `allowed-tools:` → `tools:` rename）
  - G2/G3 4（attack-scenario / sca-attacker / recon-agent / dynamic-verifier）: `allowed-tools:` → `tools:` rename、値は Files to Change A 記載値に完全一致（`Read` / `Read, Grep, Glob, Bash` / `Bash, Read, Grep, Glob` / `Bash, Read`）
  - dast-crawler.md: `allowed-tools:` 行削除（`tools:` は付与せず全継承のまま）。本文 L28-31 の旧 Playwright ツール名 4 件（`mcp__playwright__navigate/click/screenshot/evaluate`）を新名（`browser_navigate/browser_click/browser_take_screenshot/browser_evaluate`）へ修正、`## Playwright MCP Integration` 節に「Playwright MCP はユーザー環境で設定済みであることが前提（plugin は同梱しない）」を追記
  - memory 削除（PROBE D 再承認 scope）15 agent: `memory: project` frontmatter 行を削除。うち本文 `## Memory` セクション（見出し + 「agent memory に記録せよ」段落）を持つ 12 件（api-contract-reviewer, correctness-reviewer, maintainability-reviewer, observability-reviewer, performance-reviewer, security-reviewer, test-reviewer, socrates, false-positive-filter, attack-scenario, recon-agent, dynamic-verifier）は該当セクションを削除。残り 3 件（change-safety-reviewer, impact-reviewer, resiliency-reviewer）は元々 `## Memory` 本文セクションを持たず frontmatter 行削除のみ。recon-agent.md の Workflow 節「0. Check past scan context ... auto memory ... `--no-memory`」ステップを削除（1〜6 の番号はそのまま残置、削除対象は指示通り 0 のみ）
  - frontmatter キー順は全て `name → description → model → tools`（memory 削除後の 15 件も同順に一致）
  - 上記以外（writer 6 + dast-crawler + reference 1）は無変更
- docs 3 ファイル:
  - `AGENTS.md:56`: `(name, description, model)` → `(name, description, model, tools?). read-only agent は tools で Read/Grep/Glob に限定、writer は tools 省略で全継承` に更新
  - `skills/evolve/reference.md` 「### エージェント生成 (agent.md)」の code block frontmatter に `model: sonnet` / `tools: Read, Grep, Glob` を追加し、fence 直後に「Edit/Write が必要な agent は tools を省略する（全ツール継承）。」を追記
  - `CHANGELOG.md`: 先頭 `# Changelog` 直後に `## [Unreleased]` を新設（Changed: allowed-tools→tools 正規化 + 33 agent のツール限定 + memory 併用実効 Write 実測に基づく 15 agent の memory 削除 / Fixed: dast-crawler の Playwright MCP ツール名 drift）
- GREEN 実行結果:
  - `bash tests/test-agents-structure.sh` → **PASS 29 / FAIL 0 / TOTAL 29**、rc=0（TC-36〜46 全 PASS）
  - `bash scripts/validate-yaml-frontmatter.sh` を非 reference agent 40 件（`ls agents/*.md | grep -v reference`）に適用 → SKIP/FAIL 0 件、rc=0
  - 逆向き契約 sweep: `grep -rln "allowed-tools\|memory" tests/*.sh` の全 12 file を単体実行 — test-agents-structure.sh / test-api-contract-reviewer.sh / test-cycle-retrospective.sh / test-codify-insight.sh / test-discovered-debt-cleanup.sh / test-maintainability-reviewer.sh / test-observability-reviewer.sh / test-performance-reviewer-enhancement.sh / test-phase-gate.sh / test-test-reviewer.sh / test-yaml-frontmatter.sh / test-skill-maker.sh — **全 12 file rc=0、回帰 0**（memory pin 反転 5 件を含む）
  - full suite（run-tests.sh）は本 GREEN では未実行（PdM が Gate 2 で実行する契約、Cycle doc 冒頭指示通り）
  - `git status --short` 確認: 変更ファイルは agents/*.md 34 + AGENTS.md + CHANGELOG.md + skills/evolve/reference.md + 本 Cycle doc（+ セッション開始時から pre-existing だった docs/cycles/20260724_1450_codified-rules-batch-19.md と tests/*.sh 5 件、RED 由来）のみ。意図外ファイルなし
- Phase completed

GREEN Phase completed

### 2026-08-28 11:26 - REFACTOR
- チェックリスト 7 項目: 変更不要（テスト変更は禁止事項、agent frontmatter は key 順 name→description→model→tools・値とも群内一貫、Memory 節削除後の二重空行/末尾空行なし、CHANGELOG/evolve/dast 本文を目視確認）
- Verification Gate: test-agents-structure.sh 29/29 PASS、yaml validate rc=0（40 agent）、逆向き契約 sweep 12 file 回帰 0。full suite（隔離 snapshot、per-test timeout 120s）108/115: 残 7 = #144/#135 staleness cascade（test-hooks-structure / test-trap-handler / factory-model TC-14 / doc-consistency TC-13 / meta-doc-consistency の再帰実行）+ snapshot 上の path 起因 2 件（paradigm-selection / skip-criteria-tp-review、実 tree では PASS 7/7・5/5）。本 cycle 起因なし
- Phase completed

### 2026-08-28 11:26 - VERIFY (Product Verification, advisory)
- Evidence: /tmp/dev-crew-verify-20260828_1030/ (agents-structure.txt, yaml.txt)
- tests/test-agents-structure.sh rc=0 / yaml validate rc=0 / reverse sweep rc=0 / tools: 33 agent / memory: 残 1 agent（architect、据え置き writer で想定通り）
- 実機確認（plugin 再インストール後の agent 一覧表示）は REVIEW 後の release で実施（本セッションでは installed cache が 2.15.0 のため未実施）

## Raw Findings

### REVIEW (code) raw findings — 2026-08-28（Synthesis 前、重複排除前の原記録）
raw blocking_score: security 18 / correctness 82 / maintainability 12 / test 55 / impact 74 / product 38 / Codex 76 (WARN)
- correctness critical: TC-41 が agents/*.md 総数を動的カウントし、test-hooks-structure.sh の fixture（agents/test-drift-agent.md）で並行実行時に flake（再現済み）
- correctness important: recon-agent Step 0 削除で skills/security-scan/reference.md:182 の Memory Integration 節・SKILL.md --no-memory が空文化（scope 外の見落とし）
- correctness important: TC-43 の awk 区間抽出が fence 非対応、テンプレ内 `## Input` で切れる
- correctness optional: TC-42〜45 の対象ファイル存在ガード欠如 / TC-40 trim が半角 space のみ / test-test-reviewer.sh TC-03 が whole-file grep / memory 注入がランタイムで止まっているか未検証
- Codex P2: get_frontmatter が `^key: ` 要求のため裸キーを不在扱い（TC-36/39/46 false-pass）/ TC-41 count-only で重複+欠落を見逃す / TC-44/45 substring（allowed-tools ⊃ tools）/ TC-43 fence 未分離 / body の `## Memory` 削除・recon Step 0 削除に負の契約なし / full suite 108/115 と実機未検証 / Cycle doc の scope 記述が memory 維持のまま + Next Steps が KICKOFF
- impact critical: security-scan の Memory Integration が死んだ機能記述に / .claude/agent-memory/dev-crew-security-reviewer (3 files)・dev-crew-correctness-reviewer (2 files) の実データが孤立 / CHANGELOG に Breaking 節なし（v2.12/v2.13 の precedent）/ dast-crawler.md:33 Note の `evaluate` 旧名
- test important: test-test-reviewer.sh:36 whole-file grep（rules/test-patterns.md 抵触）/ TC-40 コメントが RED 時の説明のまま / TC-45 二重条件冗長 / TC-41 除外 predicate 不整合 / TC-37/38 重複
- security important: dast-crawler に disallowedTools: Write, Edit 未適用（prompt-injection-via-crawled-page）/ recon-agent の Bash は本文に根拠なし / memory 知見の移行先なし / TC-41 transient FAIL 観測 / AGENTS.md の「writer は省略」が dast-crawler に当てはまらない
- maintainability important: tools 規約の説明が AGENTS.md:56 と evolve/reference.md:69 に分散 / optional: TC-37/38/39/46 ループ重複・parallel array・TC-41 predicate
- product important: CHANGELOG Breaking 昇格 / dast-crawler MCP 依存の明記 / memory 知見の移行計画 / optional: memory pin 形式混在

### 2026-08-28 14:36 - REVIEW (code) — verdict BLOCK → GREEN 再実行 1 回
- Panel: security 18 / correctness 82 / maintainability 12 / test 55 / impact 74 / product 38 + Codex 76 (WARN) + Socrates（partial, BLOCK 推奨）。raw findings は `## Raw Findings` に保持
- **BLOCK 理由（数値ではなく契約の実体）**: 本 cycle の deliverable は「tools 契約を契約テストで固定する」ことだが、その契約テストが守るべき回帰で FAIL しない — TC-44/45 は `allowed-tools` ⊃ `tools` の部分文字列一致で旧キーのみでも PASS、TC-36/39/46 は get_frontmatter の `^key: `（末尾 space）依存で裸キーを不在扱い、TC-41 は test-hooks-structure.sh の fixture（agents/test-drift-agent.md）で並行実行時 flake（再現済み）、TC-43 は fence 非対応で `## Input` 行で区間が切れる。いずれも PdM の oracle で実証済み。加えて memory 削除の scope drift（skills/security-scan の Memory Integration / --no-memory が空文化）と CHANGELOG の Breaking 欠落
- **PROBE D step 4（Socrates 指摘で追試）**: `memory: project` + `disallowedTools: Write, Edit` の agent は起動時に既存 MEMORY.md が注入され読める（tool 使用 0 で seed 引用）。→ 「知見保持 / 書込不可 / tools 逸脱不可」の第 4 案が成立。「memory 削除」再承認は書込側の実測のみを根拠にしていたため前提が変わり、AskUserQuestion で再提示 → **ユーザー決定: A. memory 維持 + disallowedTools: Write, Edit**（memory 削除を撤回）
- GREEN 再実行 scope（RED addendum 2 → GREEN 2）:
  - agents 15 件: `memory: project` 復元 + `disallowedTools: Write, Edit` 追加（key 順 name → description → model → memory → tools → disallowedTools）。本文 `## Memory` は「参照のみ（書込不可、更新は手動 commit）」に改訂、recon-agent の Step 0 は読取参照として復元
  - tests: TC-36/39/46 の不在契約を `^key:` 行存在で判定 / TC-41 を declared-name 集合 vs 実ファイル名集合の比較 + `test-drift-agent.md` 明示除外 / TC-43 を fence 内限定 / TC-44/45 を語境界一致（`allowed-tools` 単独で FAIL する負の oracle を実測） / TC-46 を「memory 保持 15 件は disallowedTools = `Write, Edit`、tools 保持で memory を持つ agent は必ず disallowedTools を持つ」に再定義 / memory pin 5 test を `memory: project` 契約へ戻し test-test-reviewer.sh は frontmatter 範囲限定 / TC-40 コメント現状化 / 各修正 TC は「旧状態に戻すと FAIL」を 1 件ずつ実測記録
  - docs: skills/security-scan の Memory Integration を「読取のみ、書込は手動 commit」に改訂（--no-memory は読取スキップの意味に）/ dast-crawler.md:33 Note `evaluate` → `browser_evaluate` / CHANGELOG に `### Breaking`（33 agent の暗黙全権限喪失、memory は読取専用化、agent-memory は自動更新されない）/ AGENTS.md:56 に dast-crawler 例外（MCP 制約による全継承）/ Cycle doc の Scope・Files to Change に再承認 2 回分を統合
- DISCOVERED（別 Issue 候補）: test-hooks-structure.sh の実 tree fixture（mktemp 化）/ dast-crawler への disallowedTools 適用 / recon-agent の Bash 根拠 / agent-memory 孤児 dir（dev-crew-guidelines-reviewer, tdd-core-*）掃除 / 既存 memory 知見の rules/ への codify / TC-37〜46 のヘルパー共通化 / tools 規約説明の SSOT 化

### 2026-08-28 14:44 - RED (addendum 2)
- 担当: REVIEW BLOCK（14:36）で実証された契約テストの欠陥修正 + 新契約（memory 維持 + disallowedTools）への更新。ファイル境界: `tests/test-agents-structure.sh` + memory pin 5 test（test-test-reviewer.sh / test-api-contract-reviewer.sh / test-maintainability-reviewer.sh / test-observability-reviewer.sh / test-performance-reviewer-enhancement.sh）のみ。`agents/*.md` / docs には未着手（GREEN 2 の担当）
- 修正一覧（tests/test-agents-structure.sh）:
  1. `has_frontmatter_key <file> <key>` helper 新設（`awk '/^---$/{n++; next} n==1{print}' file | grep -c "^key:"` の行存在判定）。TC-36（allowed-tools 不在）/ TC-39（tools:・allowed-tools: 不在）を `get_frontmatter`（"key: " 要空白）依存から本 helper へ切替。get_frontmatter は裸キー（値なし `tools:` 単独行）を空文字列で返し不在扱いにする false-pass を持つ
  2. TC-41 を count 比較（`group_total -eq actual_count`）から declared 名前集合（g1+g23+deferred をソート）vs 実ファイル名集合（`agents/*.md` basename、`-reference` 除外、`test-drift-agent`（test-hooks-structure.sh の実 tree fixture）明示除外）の `diff` 比較へ変更。count 比較は重複+欠落が相殺するケースと並行実行時の fixture 汚染を見逃す
  3. TC-43 を fence-非対応の見出し区間抽出（`## Input` 等の decoy 見出しで早期終了しうる）から、awk の `infence` フラグで fence 内では見出し終端判定をスキップする区間抽出 + fence 内限定の model:/tools: 走査（二段構成）へ変更
  4. TC-44 を部分文字列一致（`[[ == *tools* ]]`、`allowed-tools` 単独でも PASS）から語境界判定（`grep -qE '(^|[^-])tools' <<< "$row"`、`-tools` を除外）へ変更
  5. TC-45 を「`allowed-tools` かつ `tools` を同一行に含む」判定から、区間内で「`allowed-tools` を含む行 ≥1」と「語境界 `tools` トークンを含む行 ≥1」を独立集計する判定へ変更（同一行必須を撤廃、旧キーのみの行の存在では PASS しないことを維持）
  6. TC-46 を全面再定義: 「tools: を持つ33 agent は memory: を持たない」→「memory 保持 15 agent（api-contract-reviewer change-safety-reviewer correctness-reviewer impact-reviewer maintainability-reviewer observability-reviewer performance-reviewer resiliency-reviewer security-reviewer test-reviewer socrates false-positive-filter attack-scenario recon-agent dynamic-verifier）は memory: が 'project' に完全一致 かつ disallowedTools: が 'Write, Edit' に完全一致。加えて不変条件: tools: を持つ33 agent（G1+G2/G3）のうち memory: を持つものは必ず disallowedTools: を持つ（`has_frontmatter_key` ベース）」
  7. TC-40 コメントを「33 agent の実データを検証。RED 期（addendum 前）は群ロースターに tools: 未実装で空集合の vacuous PASS だったが、現在は非空集合を検証する」に現状化
  8. TC-42（dast_file）/ TC-43（evolve_ref）/ TC-44（agents_md_file）/ TC-45（changelog_file）に `[ -f ]` ガードを追加（不在なら fail して分岐、TC-42 の mktemp は既存どおり分岐内で必ず `rm -f`）
  9. ヘッダコメント（L5-7）を addendum 2 の修正内容に更新
- 修正一覧（memory pin 5 test の TC-03）: 「memory: を持たない」契約（`-z`/whole-file grep）から「memory: project 契約」へ反転。test-api-contract-reviewer.sh / test-maintainability-reviewer.sh / test-observability-reviewer.sh / test-performance-reviewer-enhancement.sh は既存の frontmatter-scoped `get_frontmatter` を再利用し `[ "$memory_val" = "project" ]` へ変更。test-test-reviewer.sh のみ `get_frontmatter` helper が未定義だったため他 4 件と同一定義で新設し、TC-03 を whole-file `grep -q '^memory:'`（body の同一文字列を誤検出しうる）から `get_frontmatter` ベースの frontmatter 範囲限定判定へ切替
- 負の oracle 実測（各修正 TC、fixture は repo 外 /tmp、実 agent ファイル非変更）:
  - has_frontmatter_key: /tmp fixture に裸 `tools:`（値なし）を frontmatter へ設置 → `has_frontmatter_key` は検出（hits=1）、旧 `get_frontmatter` は空文字列を返し不在誤判定（regression 実証）
  - TC-41: declared 配列から1件欠落させた fixture 比較 → `diff` が非空（`extra-agent` 検出）。実 tree に `agents/test-drift-agent.md` を一時生成 → 除外ありは diff 空、除外なしは `test-drift-agent` が diff に出現（fixture 汚染を再現、生成後 rm 済み、`git status --short` で残留なし確認）
  - TC-43: heading 直後に `model:`/`tools:` を fence 外へ配置した decoy fixture → fence 限定走査は model_count=0/tools_count=0（誤検出しない）。実ファイル（fence 内に配置）は model_count=1/tools_count=1（正しく検出）
  - TC-44: `(model, tools?)` → PASS、`(model, allowed-tools?)`（旧キーのみ）→ NOMATCH で FAIL（語境界判定が `-tools` を正しく除外）
  - TC-45: 「`allowed-tools` のみ含み独立した `tools` トークンを含まない行」だけの fixture → allowed_tools_lines=1 だが tools_token_lines=0 で FAIL 相当（実 CHANGELOG.md の実文は両条件を満たし PASS）
  - TC-03 (memory pin 5 test): frontmatter に memory 不在、body に `memory: ...` で始まる行を持つ fixture → `get_frontmatter`（frontmatter 範囲限定）は空文字列（正しく不在判定）、旧 whole-file `grep -q '^memory:'` は body 行にマッチ（誤検出の再現）
- RED 実行結果（各 test file を単体実行、full suite 未実行、指示通り）:
  - `bash tests/test-agents-structure.sh` → PASS 28 / FAIL 30 / TOTAL 58、rc=1。TC-36〜45 全 PASS（agents は既に tools 化済みのため）。TC-46 が想定通り FAIL（memory 保持 15 agent × 2 assertion = 30 件、全て `memory:` / `disallowedTools:` 空文字列。不変条件チェックは 33 agent 全て memory: 不在のため違反 0 件で追加 FAIL なし）
  - `bash tests/test-test-reviewer.sh` → 15 passed / 2 failed。TC-03 FAIL（`memory: project` 期待に対し空文字列）+ TC-17 連鎖 FAIL（test-agents-structure.sh が RED 中のため）
  - `bash tests/test-api-contract-reviewer.sh` / `test-maintainability-reviewer.sh` / `test-observability-reviewer.sh` / `test-performance-reviewer-enhancement.sh` → 各 PASS 9 / FAIL 2 / TOTAL 11、rc=1。TC-03 FAIL（同上）+ 回帰チェック TC が連鎖 FAIL（同上理由）
- `bash -n` 構文チェック: 対象 6 ファイル全て OK
- `git status --short` で変更ファイルが上記 6 ファイル（+ 本 Cycle doc）のみであることを確認。`agents/*.md` への新規変更ゼロ（GREEN 1 由来の既存差分のみ残置、addendum 2 で新たに触れていない）
- Phase completed

RED Phase completed

### 2026-08-28 14:53 - GREEN (re-run)
- 担当: REVIEW BLOCK（14:36）+ RED addendum 2（14:44）で確定した最終形（memory 維持 + `disallowedTools: Write, Edit`）を agents/*.md 15 件と関連 doc へ実装。tests/*.sh は RED addendum 2 で実装済みのため変更なし
- 変更ファイル 21: agents/*.md 15（memory 保持 15 agent） + agents/dast-crawler.md（Note 文言のみ） + AGENTS.md + CHANGELOG.md + skills/security-scan/SKILL.md + skills/security-scan/reference.md + 本 Cycle doc（skills/evolve/reference.md は GREEN 1 で実装済みのため無変更）
- agents/*.md 15 件（api-contract-reviewer, change-safety-reviewer, correctness-reviewer, impact-reviewer, maintainability-reviewer, observability-reviewer, performance-reviewer, resiliency-reviewer, security-reviewer, test-reviewer, socrates, false-positive-filter, attack-scenario, recon-agent, dynamic-verifier）:
  - frontmatter に `memory: project` を復元 + `disallowedTools: Write, Edit` を追加。key 順は全件 `name → description → model → memory → tools → disallowedTools` に統一（`git diff HEAD -- agents/` で 15 件全て確認）
  - 本文 `## Memory` セクションを持っていた 12 件（api-contract-reviewer, correctness-reviewer, maintainability-reviewer, observability-reviewer, performance-reviewer, security-reviewer, test-reviewer, socrates, false-positive-filter, attack-scenario, recon-agent, dynamic-verifier）は元の Record/Skip 内容を維持したまま冒頭文を「起動時に注入される agent memory（`.claude/agent-memory/dev-crew-<agent>/MEMORY.md`）を過去知見として参照のみ行う（Write/Edit は disallowedTools で不可。更新は人間が手動で行う）」に書き換えて復元。残り 3 件（change-safety-reviewer, impact-reviewer, resiliency-reviewer）は元々本文 `## Memory` セクションを持たないため frontmatter のみ変更
  - recon-agent.md の Workflow Step 0（「Check past scan context」）を読取専用参照として復元。`--no-memory` は「読取スキップ」の意味に改訂（旧: 「読み書き両方を無効化」相当の含意を撤回）
- agents/dast-crawler.md: L33 の Note `` `evaluate` `` → `` `browser_evaluate` `` に修正（本文の tool 名一覧は GREEN 1 で既に新名化済みのため、この 1 箇所のみ残存していた drift）
- docs:
  - `AGENTS.md:56`: Agents 行に「例外: dast-crawler は Playwright MCP のツール名制約（未設定環境で起動拒否）のため tools 省略で全継承（writer ではない）」を追記
  - `skills/security-scan/SKILL.md:29`: `--no-memory` の説明を「起動時の memory 読取をスキップ（memory は読取専用、書込は行わない）」に変更。`:44-45`: LEARN Phase の説明を「スキャン結果を report に出力。memory への蓄積は人間の手動作業」に変更
  - `skills/security-scan/reference.md`: `## Memory Integration` 節（176-241 行、旧番号 176-239 + Memory Convention 見出し込み）を「読取専用、書込は人間の手動作業」の趣旨へ全面改訂（Overview / LEARN Phase / Memory Convention 冒頭文 / Memory Data Exclusion 冒頭文 / Known Limitations）。274 行（再開手順 3.）の `auto memory` 参照を「agent memory（読取専用）」に修正
  - `CHANGELOG.md` `## [Unreleased]` に `### Breaking` を `### Changed` の前へ新設: (1) 33 agent が `tools:` で権限限定され暗黙の全ツール継承を失う（旧 `allowed-tools` は無視されていたため実効変化は「全権限→限定」） (2) memory 保持 15 agent は `disallowedTools: Write, Edit` により memory が読取専用化、agent 自身の自動蓄積は停止、更新は `.claude/agent-memory/dev-crew-<agent>/MEMORY.md` を人間が手動編集。`### Changed` の memory 記述を「memory 削除」から「`memory: project` 維持 + `disallowedTools: Write, Edit` 追加で読取専用化」に修正。`allowed-tools` を含む行と語境界 `tools` トークンを含む行を維持（TC-45 実測確認）
  - Cycle doc: Scope Definition（In Scope の key 順記述、CHANGELOG scope bullet）/ Files to Change（TC-46 行、AGENTS.md/CHANGELOG 記述、C セクション）/ Implementation Notes（Design Approach「memory: project との共存」）の「memory 削除」「disallowedTools 未確定」記述を最終形（memory 維持 + `disallowedTools: Write, Edit`）へ統合。Next Steps の phase 表記を現状（GREEN (re-run) 完了、次 REFACTOR）に更新。Progress Log 既存エントリは無改変（追記のみ）
- GREEN 実行結果:
  - `bash tests/test-agents-structure.sh` → **PASS 29 / FAIL 0 / TOTAL 29**、rc=0（TC-36〜46 全 PASS、TC-46 は memory 保持 15 agent の `memory: project` + `disallowedTools: Write, Edit` 完全一致 + 33 agent 不変条件を確認）
  - memory pin 5 test 単体実行: `test-test-reviewer.sh`（17 passed / 0 failed, rc=0）、`test-api-contract-reviewer.sh` / `test-maintainability-reviewer.sh` / `test-observability-reviewer.sh` / `test-performance-reviewer-enhancement.sh`（各 PASS 11 / FAIL 0 / TOTAL 11, rc=0）— 全 5 件 TC-03 PASS（`memory: project` 契約に復帰）
  - `bash scripts/validate-yaml-frontmatter.sh` を非 reference agent 40 件（`agents/*.md` から `*reference*` 除外、bash 明示配列で 40 件確認）に適用 → SKIP/FAIL 出力 0 件、rc=0
  - 逆向き契約 sweep: `grep -rln "allowed-tools\|memory\|disallowedTools" tests/*.sh` の全 12 file（test-agents-structure.sh / test-api-contract-reviewer.sh / test-codify-insight.sh / test-cycle-retrospective.sh / test-discovered-debt-cleanup.sh / test-maintainability-reviewer.sh / test-observability-reviewer.sh / test-performance-reviewer-enhancement.sh / test-phase-gate.sh / test-test-reviewer.sh / test-yaml-frontmatter.sh / test-skill-maker.sh）を単体実行 — **全 12 file rc=0、回帰 0**
  - full suite（run-tests.sh）は本 GREEN では未実行（指示通り、PdM が Gate 2 で実行する契約）
  - `git status --short` 確認: 変更ファイルは agents/*.md 34（G1 29 + G2/G3 4 + dast-crawler 1、うち 15 件が本 re-run 対象）+ AGENTS.md + CHANGELOG.md + skills/evolve/reference.md + skills/security-scan/SKILL.md + skills/security-scan/reference.md + tests/*.sh 6（test-agents-structure.sh + memory pin 5 test、RED 由来）+ 本 Cycle doc（+ セッション開始時から pre-existing だった docs/cycles/20260724_1450_codified-rules-batch-19.md）のみ。意図外ファイルなし
- Phase completed

GREEN Phase completed

### 2026-08-28 15:10 - REVIEW accept-fix (docs)
- 担当: REVIEW（再レビュー、Codex WARN 79）の accept-fix。docs 文言のみ 4 件を修正（tests/ と agents/*.md frontmatter は無変更）
- `CHANGELOG.md`: `### Breaking` 2 項目目と `### Changed` の memory 記述を「memory が読取専用化」の不正確な要約から、「`disallowedTools: Write, Edit` により Write/Edit ツール経由の memory 更新は不可（起動時注入の読取は可）。Bash を持つ recon-agent / dynamic-verifier はシェル経由の書込経路が残るため、完全な read-only ではない（残余リスクとして記録）」へ修正
- `skills/security-scan/SKILL.md:29` の `--no-memory` 説明と `skills/security-scan/reference.md`（Overview の `--no-memory` 行）を「起動時注入自体は止められない（agent 定義が静的に `memory: project` を持つ）。`--no-memory` は注入済み memory を参照しない指示であり、隔離を保証しない」に修正（旧文言は「読み書き両方を無効化」の誤解を招く記述だった）
- `AGENTS.md:56` の Agents 行に「`memory` を持つ agent は必ず `disallowedTools: Write, Edit` を併記する（memory 併用時は tools 宣言外の Write が有効化されるため）」を追記。既存の `tools`（`-tools` 以外）語と dast-crawler 例外文は維持（TC-44 契約に影響なし）
- 本 Cycle doc: Test List TC-14 の記述を旧契約（「memory 削除」）から最終契約（memory 保持 15 件は `memory: project` + `disallowedTools: Write, Edit`）へ更新。Progress Log 既存エントリは無改変（追記のみ）。frontmatter `updated` を更新（`phase: GREEN` は維持）
- 検証: `bash tests/test-agents-structure.sh` → PASS 29 / FAIL 0 / TOTAL 29（TC-44/TC-45 含め全 PASS）。`git status --short` 確認: 変更ファイルは AGENTS.md / CHANGELOG.md / skills/security-scan/SKILL.md / skills/security-scan/reference.md / 本 Cycle doc のみ（他は GREEN (re-run) 由来の既存差分）。意図外ファイルなし
- Phase completed（phase は REVIEW のまま）

### 2026-08-28 15:12 - REVIEW (code, after GREEN re-run) — verdict WARN → 進行
- 再レビュー raw: correctness 12 / test 8 / Codex 79 (WARN)。Synthesis: 前回 BLOCK 理由 4 件（裸キー不在契約 / TC-41 flake+count-only / TC-43 fence / TC-44-45 substring）は全て解消を fixture 実測で確認（correctness・test 両 reviewer + Codex）。Codex 新規 P2 4 件は docs 文言 3 件を accept-fix（CHANGELOG の read-only 主張の精密化、--no-memory の意味、AGENTS.md の memory↔disallowedTools 対規則）、残り 1 件（TC-46 の memory 集合完全性）と `(^|[^-])tools` の両側境界は DISCOVERED（test 変更は GREEN 再実行 1 回上限のため次 cycle）
- 最終 score: category 別最大 = 79（Codex, WARN 帯）。Claude 側は 12。Socrates 指摘 1〜7 は step 4 追試 → 第 4 案採用で本質的に解消（知見保持 + 書込不可）、Bash 保持 2 agent のシェル書込経路は CHANGELOG に残余リスクとして明記
- Gate 2 full suite（隔離 snapshot snap3、per-test timeout 420s）: **115/115 rc=0**。standalone の test-hooks-structure TC-05 は staleness 依存で環境により FAIL（#144、本 cycle 起因なし）
- 実機確認（plugin 再インストール後の agent 一覧表示）は release 後の確認事項として残す
- Phase completed

### 2026-08-28 15:12 - DISCOVERED (Block 2e)
- 起票: https://github.com/morodomi/dev-crew/issues/195（hooks-structure fixture 隔離）/ https://github.com/morodomi/dev-crew/issues/196（dast-crawler disallowedTools・MCP・recon Bash）/ https://github.com/morodomi/dev-crew/issues/197（agent-memory 知見 codify・孤児 dir）/ https://github.com/morodomi/dev-crew/issues/198（TC-36〜46 強化・SSOT）
- 既存 Issue で追跡: #144（TC-05 壁時計依存、隔離 snapshot 逐次 rc=0 → standalone rc=1 を本 cycle で 2 回再現。コメント追記は scope 外、ユーザー判断）
- reject: dast-crawler を本 cycle で disallowedTools 適用（probe 未実施のため次 cycle）

## Retrospective

抽出時刻: 2026-08-28 15:13
抽出方法: Cycle doc 全体（PROBE D step 0〜4 / Codex plan review 2 attempt / REVIEW BLOCK → RED addendum 2 → GREEN 再実行 / 再レビュー）からの失敗→最終解→insight 抽出

### Insight 1: 「抑止できるか」だけ測った probe は、抑止の副作用（失われる機能）を測っていない。再承認に使う実測は「得るもの」と「失うもの」を対で測る
- **Failure**: PROBE D は step 1〜3 で「memory 併用時の Write 越権」「disallowedTools で抑止可」「memory 書込も不可」を測り、ユーザーは「memory 削除」を再承認した。しかし memory の価値の半分（起動時注入による読取）は未測定で、Socrates の指摘で step 4 を追試すると読取は生きていた。結果、GREEN 1 で削除した memory を GREEN 2 で復元する往復（15 agent × 2 回の編集、5 test の反転→再反転）が発生した
- **Final fix**: step 4（memory 注入の読取確認）を追試し、第 4 案（memory 維持 + disallowedTools: Write, Edit）で再々承認。REVIEW BLOCK → RED addendum 2 → GREEN 再実行で反映
- **Insight**: **機能を剥奪する判断を人間に再承認させる前に、剥奪で失う側の実測（本件なら「読めるか」）を必ず対で取る。「書けない」だけの実測は「機能が死ぬ」の証明にならない。probe 設計時に「この構成で残る機能 / 消える機能」の 2 列表を先に作り、両列を埋めてから AskUserQuestion に出す**
- **一般化**: rules/plan-discipline.md 追記候補（capability 剥奪の再承認は残存/喪失の両実測を前提にする）

### Insight 2: 部分文字列を含む語（allowed-tools ⊃ tools）を契約の pin に使うと、旧状態が新契約を通す。負の oracle は「旧状態そのもの」で取る
- **Failure**: TC-44/45 は `*tools*` の部分文字列一致で書かれ、`allowed-tools` だけの旧行でも PASS した（Codex P2 + PdM oracle で実証）。同時に get_frontmatter の `^key: `（末尾 space）依存で裸キーが不在扱いになり、TC-36/39/46 の不在契約が false-pass する構造だった。RED 時点で「新状態で FAIL する」ことは確認したが「旧状態で FAIL する」ことは確認していなかった
- **Final fix**: 語境界判定 `(^|[^-])tools` と `has_frontmatter_key`（`^key:` 行存在）を導入し、RED addendum 2 で各 TC に「旧状態 fixture で FAIL する」負の oracle を 1 件ずつ実測記録
- **Insight**: **rename 契約（旧キー→新キー）の test は、新キーが旧キーの部分文字列になっていないかを最初に確認し、なっていれば語境界で pin する。RED の完了条件は「未実装で FAIL」だけでなく「旧状態 fixture で FAIL」の実測を含める。rules/test-patterns.md の「negative sweep は新文言不一致を oracle で実測」の rename 版**
- **一般化**: rules/test-patterns.md 追記候補（rename 契約の部分文字列衝突チェック + 旧状態 fixture oracle を RED 完了条件に）

### Insight 3: 存在ベースの契約（ファイル総数・集合一致）は、他 test が実 tree に作る fixture で flake する。内容ベース契約は影響を受けない
- **Failure**: TC-41（agents/*.md の総数 = 40）は、test-hooks-structure.sh が実 tree に agents/test-drift-agent.md を作る間だけ FAIL した（baseline 取得中と REVIEW 中の 2 回再現）。TC-36〜40 は per-file 内容判定のため無影響だった
- **Final fix**: TC-41 を name 集合の diff に変え、既知 fixture 名を明示除外。根治（fixture の mktemp 隔離）は #195 へ
- **Insight**: **test 設計で「ディレクトリの総数・集合」を契約にする時は、`grep -rn "BASE_DIR.*agents/" tests/` で実 tree に書く test を先に列挙し、fixture 名を除外するか内容ベース契約に置き換える。plan-discipline の「隔離 snapshot baseline」は並行 agent の書込を防ぐが、test 自身が実 tree に書く経路は別問題**
- **一般化**: rules/test-patterns.md 追記候補（存在ベース契約は実 tree 書込 test の fixture を除外）

### Insight 4: フレームワークのキー名は「似た機能の別コンポーネントのキー」を流用しやすい。frontmatter キーの有効性は harness の表示（agent 一覧の Tools 欄）で実測できる
- **Failure**: 18 agent が skill 用キー `allowed-tools` を 7 か月間持ち続け、誰も無効に気付かなかった。archive cycle 20260216_1432 はこのキーを前提に順序規約まで作っていた
- **Final fix**: 公式 doc（sub-agents / plugins-reference）で `tools` が正規キー、`allowed-tools` は skill 専用と確認。加えて本セッションの agent 一覧に `(Tools: All tools)` と表示される事実を一次証拠にした
- **Insight**: **agent frontmatter に新キーを足す時は、セッション起動時の agent 一覧表示（Tools 欄）で反映を確認する。表示が変わらなければキーは無視されている。plan-discipline の「継承デフォルト前提は一次ソース確認」を「キー名の有効性は表示で実測」に拡張する**
- **一般化**: rules/plan-discipline.md 追記候補（frontmatter キー追加時は harness 表示で有効性を実測）

### 想起漏れ

- **設問**: 今回の手戻りは、過去のどの cycle doc を最初に読んでいれば防げたか
- **回答**: docs/cycles/20260424_1356_small-debt-cleanup.md

### 2026-08-28 15:13 - COMMIT
- pre-commit-gate（明示指定）rc=0 PASS。Cycle Doc / Phase Ordering / Test List Completion / Progress Log Completeness / Codex review 記録 / retro_status: captured の全ゲート PASS
- STATUS.md: Done 75→76 + Completed 行 + Last updated 2026-08-28。Test Scripts 115 不変（新規 test file なし）、Agents 41 不変
- commit 同梱: agents 34 + tests 6 + AGENTS.md + CHANGELOG.md + skills/evolve/reference.md + skills/security-scan 2 + 本 cycle doc + STATUS.md + docs/cycles/20260724_1450 の codify 出力（Block 0 codify、scope 同梱として透明化）
- Phase completed
