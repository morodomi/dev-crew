---
feature: staleness hook removal + derived-fact contracts
cycle: 20260906_1120
phase: DONE
complexity: standard
test_count: 9
risk_level: low
retro_status: captured
codex_mode: no
codex_session_id: ""
plan_file: /Users/morodomi/.claude/plans/twinkling-petting-kitten.md
created: 2026-09-06 11:20
updated: 2026-09-06 14:57
---

# staleness hook 削除 + 派生事実の契約テスト化（#207）

## Scope Definition

### In Scope
- [ ] `scripts/hooks/check-claude-md-staleness.sh` を削除
- [ ] `tests/test-hooks-structure.sh`: TC-04 / TC-05a〜f / TC-06 と staleness 専用 helper（`fixture_git` / `fixture_git_init` / `fixture_commit_backdated` / `run_staleness_hook` / `DAY_SECONDS` / `fixture_repo_with_docs`）を削除。`FIXTURE_DIR` / `cleanup()` / `trap cleanup EXIT INT TERM` は TC-03 が使うため維持。header コメントの TC 一覧を残存 TC に合わせる
- [ ] `tests/test-agents-md-propagation.sh`: `STALENESS_HOOK` 変数と前提存在チェックから hook を外し、TC-10 / TC-11 を削除
- [ ] `tests/test-doc-consistency.sh` に派生事実の契約テストを追加（AGENTS.md skills名前集合 / CLAUDE.md Hooks表 / CLAUDE.md負の契約 / STATUS.md数値）
- [ ] `CLAUDE.md` から `Available skills (28 total): ...` の1行を削除（annotated な2行は残す）
- [ ] `docs/STATUS.md` の `| Agents | 41 |` を **40** に修正
- [ ] `CHANGELOG.md` に Removed / Changed エントリを追加

### Out of Scope
- hook の配線（wire）案 (Reason: ユーザー裁定で削除を選択済み)
- `skills/commit/SKILL.md` の更新トリガ自体の改修 (Reason: トリガは既に存在し機能している。決定論化は本 cycle の契約テストで代替される)
- AGENTS.md / README.md の skills 一覧の削除 (Reason: Codex が読む cross-tool doc であり harness 注入が効かないため実用がある)
- `#186`/`#177`（release-skill への同期組み込み） (Reason: 別 cycle)

### Files to Change (target: 10 or less)
- `scripts/hooks/check-claude-md-staleness.sh` (delete)
- `tests/test-hooks-structure.sh` (edit)
- `tests/test-agents-md-propagation.sh` (edit)
- `tests/test-doc-consistency.sh` (edit)
- `CLAUDE.md` (edit)
- `docs/STATUS.md` (edit)
- `CHANGELOG.md` (edit)

## Environment

### Scope
- Layer: Plugin repo（shell tests + doc のみ）
- Plugin: bash 3.2.57 / jq 1.7.1 / git 2.49.0
- Risk: 10 (PASS) — Limited カテゴリ（test 追加・documentation）+10。Security/External/Data/Scope の +60/+40 はいずれも非該当（rubric: skills/spec/reference.md keyword score表）

### Runtime
- Language: GNU bash 3.2.57(1)-release (arm64-apple-darwin25)

### Dependencies (key packages)
- jq: 1.7.1 (hooks.json 突合)
- git: 2.49.0

### Risk Interview (BLOCK only)
(該当なし — Risk 10 PASS のため BLOCK インタビューは未実施)

## Context & Dependencies

### Reference Documents
- `skills/spec/reference.md` - risk rubric keyword score表（Baseline Risk 10 PASS の根拠）
- `rules/test-patterns.md` - 「set -e 下の裸 command-substitution 代入」の再発防止（Design B abort-safety 制約の根拠）
- `docs/architecture.md` - TC-02 が CONSTITUTION §8 の先行判例として参照される

### Dependent Features
- `tests/test-skills-structure.sh` TC-B1 - agents 実数 40 の導出ロジック（frontmatter 判定。新規 TC-C1 がこれに統一）
- `tests/test-meta-doc-consistency.sh` - 新規 TC の abort-safety 検証対象（`make_fixture` L33-45 は AGENTS.md・hooks.json・STATUS.md・CLAUDE.md を含まない fixture）
- `tests/test-trap-handler.sh` - TC-03 の `FIXTURE_DIR` / `cleanup()` / `trap` 維持を保証する逆向き契約（T-01/02/03）
- `tests/test-post-approve-gate-removal.sh` TC-06/07 - 逆向き契約 sweep 対象（本 cycle の変更で無影響と確認済み）
- `skills/commit/SKILL.md:52` - CLAUDE.md 更新トリガ（既存の変更ベーストリガ、本 cycle では不変）

### Related Issues/PRs
- Issue #207: 本 cycle の起票元（staleness hook 削除 + 派生事実の契約テスト化）
- Issue #206: staleness hook 本体バグ（未 commit ファイルで `git log` が空を返し age=now → 「20700日間更新されていません」）
- Issue #31: staleness hook 起源（2026-02-18 導入）
- 前 cycle: `docs/cycles/20260904_1521_test-hooks-hermetic-fixtures.md`（REVIEW で Socrates が orphan 性と本体バグを発見し #206/#207 起票）

### 補足（scope 同梱の透明化）
orchestrate Block 0 の codify-insight が前 cycle doc（`docs/cycles/20260904_1521_test-hooks-hermetic-fixtures.md`）を更新済みであり、本 cycle の commit にその差分が同梱される見込み（plan-discipline 準拠の事前開示）。

## Recall

### docs/cycles/20260314_1112_agents-md-skill-propagation.md（score 1.50）
- **何が起きたか**: staleness hook の対象を CLAUDE.md 単独から CLAUDE.md + AGENTS.md へ拡張し、同時に commit skill の doc 更新テーブルへ AGENTS.md を追加した cycle。TC-10 / TC-11（本 cycle で削除する2件）はこの時に新設された
- **当時の前提**: hook が pre-commit で稼働しており、対象ファイルを増やす価値がある
- **今回も同じ前提か**: **No**。hook はその後 de-register され orphan 化した。当時追加した TC-10/11 は「hook の内容」を検査するもので、hook 削除と運命を共にする。なお同 cycle の REFACTOR で「test helper commonization は pre-existing pattern のため別 cycle へ」と defer された記録があり、本 cycle の helper 削除はその系譜を閉じる側の変更になる

### docs/cycles/archive/20260218_1400_claude-md-staleness.md（score 0.67）
- **何が起きたか**: hook と TC-04〜06 を新設した起源 cycle（issue #31）。Design の変更ファイルは hook 本体 + `hooks/hooks.json`（3rd PreCommit entry）+ test の3点
- **当時の前提**: プラグインの hooks.json に PreCommit エントリを置ける
- **今回も同じ前提か**: **No**。その後 TC-10（hooks.json に PreCommit エントリを持たない — プラグイン hook が全プロジェクトで発火するため）が契約化され、前提が撤回された。hook が de-register されたのはこの契約変更の帰結であり、本 cycle はその未完了だった後始末（本体とテストの削除）を完了させる

### docs/cycles/20260904_1521_test-hooks-hermetic-fixtures.md（score 0.27）
- **何が起きたか**: 直前 cycle。この hook のテストを hermetic 化し full suite を 116/116 へ回復させた。その REVIEW で Socrates が orphan 性と本体バグを発見し #206/#207 起票 → 本 cycle の起点
- **当時の前提**: hook は production code である（reviewer 5名全員が無検証で共有していた前提）
- **今回も同じ前提か**: **No**（Socrates が破壊）。前 cycle で投入した fixture helper 群は本 cycle で削除される。ただし前 cycle の成果本体（TC-03 の実ツリー汚染除去 = #195、full suite の 116/116 回復）は hook の去就と独立に残る。前 cycle Insight 1（隔離 snapshot の親構造複製）と Insight 2（編集前の逆向き契約 grep）は本 plan の Verification 6 と Baseline の sweep で先行適用済み

## Test List

### TODO
(none)

**Note（残存TCのハードコードpinについて）**: test-hooks-structure.sh / test-agents-md-propagation.sh / test-trap-handler.sh の rc=0 は恒久 TC にせず Verification の一時確認とする。残存 TC 数のハードコード pin は将来の TC 追加で無関係に壊れる brittle な契約であり、rc=0 自体は既存の test-doc-consistency TC-13 と test-trap-handler T-04 が再帰実行で既に検証済み。

**Note（TC番号の採番方針）**: TC番号は `tests/test-doc-consistency.sh` の実装から実測した最大値の次から採番する（ヘッダコメントの一覧はdrift前提で根拠にしない — plan-discipline / cycle 20260716_1328 #2）。

### WIP
(none)

### DISCOVERED
(none)

### DONE
- [x] TC-A1: Given hook削除後のrepo / When `[ -f scripts/hooks/check-claude-md-staleness.sh ]` / Then 不在（negative契約、test-doc-consistencyに追加）
- [x] TC-A2: Given 編集後のtest-hooks-structure.sh / When staleness関連文字列をgrep / Then `check-claude-md-staleness` `STALENESS_THRESHOLD_DAYS` `fixture_repo_with_docs` `run_staleness_hook` `DAY_SECONDS` がいずれも0件
- [x] TC-A3: Given 編集後のtest-agents-md-propagation.sh / When `STALENESS`をgrep / Then 0件（恒久negative契約）
- [x] TC-B1: Given AGENTS.mdの`Skills available:`行 / When 名前集合を実skillsディレクトリ集合と比較 / Then 完全一致（差分があれば欠落・余剰を両方向で報告）
- [x] TC-B2: Given AGENTS.mdに存在しないskillディレクトリを追加したfixture / When 同契約を実行 / Then FAILする（契約が実際に検出力を持つことのoracle）
- [x] TC-B3: Given CLAUDE.mdのHooks表 / When script basename集合をhooks.json登録分と比較（global表記行は除外）/ Then 一致
- [x] TC-B4: Given CLAUDE.md / When skill count・skills一覧の再導入をgrep / Then 0件（CONSTITUTION §8の恒久契約）
- [x] TC-C1: Given docs/STATUS.md / When `| Agents | N |`を**frontmatter判定**（`agents/*.md`のうち1行目が`---`のもの、test-skills-structure TC-B1と同一ロジック）による実数と比較 / Then 一致（40）
- [x] TC-C2: Given docs/STATUS.md / When `| Skills | N |`を`ls -d skills/*/ | wc -l`と比較 / Then 一致（28）

## Implementation Notes

### Goal
`scripts/hooks/check-claude-md-staleness.sh`（CLAUDE.md / AGENTS.md の未更新日数を警告する非ブロッキングhook）を削除し、時間ベースの警告を「派生事実（skills一覧・Hooks表・agents数）の機械検査による契約テスト」へ置き換える（#207）。

### Background
`scripts/hooks/check-claude-md-staleness.sh` は「CLAUDE.md / AGENTS.md が N 日更新されていない」と警告する非ブロッキング hook（2026-02-18、issue #31 で導入）。cycle 20260904_1521 の REVIEW で **完全な orphan**（`hooks/hooks.json` / `.git/hooks/pre-commit` / `skills/onboard` のいずれにも未登録、参照はテストのみ）と判明し、本体バグ（#206: 未 commit ファイルで `git log` が空を返し `age = now` → 「20700日間更新されていません」）も実測で再現済み。

削除を選ぶ根拠は「未使用だから」ではなく **測っている指標が間違っているから**:

| ファイル | 最終commit | hookの判定 | 実際の内容（本plan作成時に実測） |
|---|---|---|---|
| CLAUDE.md | 2026-07-17（50日前） | STALE警告 | **正確**（skills 28 = 実数、Hooks表 = hooks.json登録3 + global明示1で一致） |
| AGENTS.md | 2026-08-28（8日前） | 問題なし | STATUS.md「Agents 41」とAGENTS.md「40 agents」が**不整合** |

git commit経過日数は「内容が現状と乖離しているか」の代理指標として機能していない。hookが警告する側が正確で、沈黙する側に不整合がある。50日の警告が生んだ実害はゼロ。

同時に、ユーザーの当初認識「CLAUDE.mdの更新タイミングが無い」は事実と異なる — `skills/commit/SKILL.md:52` に「CLAUDE.md | skills/ or agents/変更時 | Skillsセクションの更新」という**変更ベースのトリガが既に存在**し、判定コマンド（`git diff --name-only HEAD | grep -qE '^(skills|agents)/'`）まで付いている。実際v2.16.0のagent-tools-scopingではAGENTS.mdが同時更新され、testsのみ触った前cycleでは正しく非発火だった。問題はトリガの不在ではなく、それが**プロンプトベースの規律で観測不能**なこと（CONSTITUTION §4-6「LLMに手順を守れと指示するのではなくゲートがBLOCKする」に反する状態）。

よって時間ベースの警告を削除し、**派生事実を機械検査する契約テスト**へ置き換える。full suiteが回るたびに検査され、本当に乖離したときだけ鳴る。

**Baseline（実測、2026-09-05）**:
- hookのorphan性: `grep -c staleness hooks/hooks.json` → **0**。`.git/hooks/pre-commit`は`pre-commit-yaml-frontmatter.sh`のみ呼ぶ。`skills/onboard/`に配布記述なし。`grep -rln 'check-claude-md-staleness'`の非cycle-docヒットは**tests/test-hooks-structure.shとtests/test-agents-md-propagation.shの2件のみ**
- 逆向き契約sweep:
  - `tests/test-trap-handler.sh` T-01/T-02/T-03がtest-hooks-structure.shの`^trap` / `cleanup()` / `trap.*EXIT.*INT.*TERM`（単一行）/ inline `rm -f.*TEMP_AGENT`不在をpin → **TC-03がFIXTURE_DIRを使い続けるため全て維持される**（前cycleでtrap分割を試みてFAILさせた実績あり。今回は触らない）
  - `tests/test-post-approve-gate-removal.sh` TC-06はtest-hooks-structure.shに`TC-11|TC-12`が**無いこと**を要求 → TC削除は無影響。同TC-07の"stale hook"はpost-approve-gateの文言（`hook.*でブロックされる`）で本件と無関係
  - `grep -rln 'Available skills\|28 total' tests/ skills/ rules/` → **0件**（CLAUDE.mdのskills記述は現在どのテストにもpinされていない = 削除しても逆向き契約に抵触しない）
- 派生事実の現況: skills実数28（AGENTS.md一覧・README「28 skills」・CLAUDE.md「28 total」すべて一致）。agentsは`ls agents/*.md` = 41だが`-reference`除外で**40**（AGENTS.md「40 agents」が正、STATUS.md「41」が誤り）
- 既存pin: test-doc-consistency TC-01がREADMEの`N skills`を実数と突合、TC-02がarchitecture.mdの非ハードコードを許容、TC-12がCLAUDE.mdの`## Usage Patterns`存在のみ検査（内容の突合は無し）
- full suite: 116/116（前cycle完了時、親構造込み隔離snapshotで実測）

**Ambiguity Resolution（AskUserQuestionで確定）**:
- **skills一覧**: CLAUDE.mdからは削除しAGENTS.md側をpinする。根拠は**`CLAUDE.md`の1行目が`@AGENTS.md`（実測確認済み）**であること — AGENTS.mdの`Skills available:`行はimport経由で既にClaudeのコンテキストへ入るため、CLAUDE.md側の`Available skills (28 total): ...`は同一プロセス内で二重に読まれる純粋な重複であり、CONSTITUTION §8「コードから導出可能な情報は書かない」に反する。この根拠はharnessのskill自動注入の有無に依存せずファイルだけで検証できる（`docs/architecture.md`が既に同原則でcountを持たず、test-doc-consistency TC-02がそれを「CONSTITUTION principle honored」としてPASS扱いにしている前例に従う）。**AGENTS.md側を残す理由**は「Codexがこれのみを読む」ため（Claudeもimport経由で読むのでCodex専用ではない）
- **削除範囲**: hook本体 + 関連8TC + fixture helper群 + test-agents-md-propagationのTC-10/11を全削除

### Design Approach

**A. hook削除**
- `scripts/hooks/check-claude-md-staleness.sh`を削除
- `tests/test-hooks-structure.sh`: TC-04 / TC-05a〜f / TC-06とstaleness専用helper（`fixture_git` / `fixture_git_init` / `fixture_commit_backdated` / `run_staleness_hook` / `DAY_SECONDS` / `fixture_repo_with_docs`）を削除。**`FIXTURE_DIR` / `cleanup()` / `trap cleanup EXIT INT TERM`はTC-03が使うため現状のまま維持**（test-trap-handlerの逆向き契約3本を守る）。headerコメントのTC一覧を残存TC（TC-01/02/03/07/08/09/10）に合わせる
- `tests/test-agents-md-propagation.sh`: `STALENESS_HOOK`変数と前提存在チェック（`for f in ... do [ -f "$f" ] || exit 1`）からhookを外し、TC-10 / TC-11を削除

**B. 派生事実の契約テスト（`tests/test-doc-consistency.sh`に追加、新規test fileなし）**

CLAUDE.mdからは`Available skills (28 total): ...`の1行を削除し、annotatedな2行（cycle-retrospective / codify-insightの起動語説明 — 導出不能な編集情報）は残す。

**abort-safety制約（必須）**: `tests/test-meta-doc-consistency.sh`の`make_fixture`（L33-45、実測確認済み）は`docs/architecture.md` / `README.md` / `skills/skill-N/`**のみ**を作り、AGENTS.md・hooks/hooks.json・docs/STATUS.md・CLAUDE.mdを含まないfixture上でtest-doc-consistency.shをBASE_DIR override実行する。よって新規TCは**対象ファイル欠落時にabortしてはならない** — 既存TC-01と同型の`2>/dev/null ... || true`防御を全ての`$(grep ...)` / `$(jq ...)`代入に付け、欠落時は`fail()`で報告してSummaryへ到達させる。これを怠ると`set -euo pipefail`下でsubjectがSummary到達前に落ち、meta testのTC-01/02/03（`subject_completed == 0 → fail`、tests/test-meta-doc-consistency.sh:69-70,92-93,116-117）がCOMMIT直前のfull suiteまで壊れたまま気付かれない（rules/test-patterns.md「set -e下の裸command-substitution代入」の再発）。

追加する契約（既存TC-01のcount突合パターンを流用）:
- **AGENTS.md skills名前集合**: `Skills available:`行をパースした集合が`ls -d skills/*/`のbasename集合と完全一致
- **CLAUDE.md Hooks表**: 表内のscript basename集合が`hooks/hooks.json`の登録commandから抽出したbasename集合と一致（`~/.claude/hooks/`始まりのglobal hook行は「global」表記を根拠に除外）
- **CLAUDE.mdの負の契約**: skill count / skills一覧が再導入されていない（CONSTITUTION §8の恒久化。architecture.mdに対するTC-02と同型）
- **STATUS.mdの数値**: Skills値 = `ls -d skills/*/`の数、Agents値 = `ls agents/*.md | grep -v -- '-reference'`の数

**C. agents数の定義統一**

`docs/STATUS.md`の`| Agents | 41 |`を**40**に修正する。`agents/false-positive-filter-reference.md`はagent定義ではなくreference doc（1行目が`# False Positive Filter - Reference`でfrontmatterを持たない）であり、AGENTS.mdの「40 agents (flat)」が正。

**導出ロジックは既存契約に揃える**: `tests/test-skills-structure.sh` TC-B1（L103-107）が既に「`agents/*.md`のうち1行目が`---`（frontmatter有り）のものを数える」という判定でAGENTS.mdの宣言と突合しており、実測で40を返してPASSしている。新規TC-C1を`grep -v -- '-reference'`というファイル名パターンで実装すると、同じ「40」という事実に**異なる導出ルールが2つ並立**し、将来frontmatter無しのファイルが`-reference`以外の名前で追加されたとき片方だけが検出漏れして両契約が無矛盾のまま乖離する。よってTC-C1は**TC-B1と同じfrontmatter判定を用いる**。

## Verification

**Real-path invocation を最低1件含めること** (rules/integration-verification.md)。

1. `bash tests/test-hooks-structure.sh` → rc=0、残存TCのみPASS（FAIL 0）
2. `bash tests/test-agents-md-propagation.sh` → rc=0
3. `bash tests/test-trap-handler.sh` → rc=0（trap契約の維持をreal-pathで確認）
4. `bash tests/test-doc-consistency.sh` → rc=0（新規契約TC込み）
5. **契約の検出力oracle（全5契約を実測）**: 一時的に (a) AGENTS.mdのskills一覧から1件削る → TC-B1がFAIL / (b) CLAUDE.md Hooks表の1行のscript basenameをhooks.jsonと不一致にする → TC-B3がFAIL / (c) CLAUDE.mdに`Available skills (28 total)`を書き戻す → TC-B4がFAIL / (d) STATUS.mdのAgentsを41に戻す → TC-C1がFAIL / (e) STATUS.mdのSkillsを実数と異なる値にする → TC-C2がFAIL。それぞれ実測してから元に戻す。特にTC-B3の「global行除外」は除外方向の反転や判定列の取り違えが起きやすく、oracle未実測だと「常にPASSする壊れた契約」を作り込み本cycleの目的（信頼できないsignalの排除）に反する（negative sweepは新文言不一致もoracle実測せよ、cycle 20260716_1328 #3）
5b. `bash tests/test-meta-doc-consistency.sh` → rc=0（新規TCのabort-safetyをfixture環境で直接確認。full suite待ちにすると手戻りが遅い）
6. full suite（**親構造ごと複製した隔離snapshot**: `holdings-snap/docs/test_architecture.md` + `agents/dev-crew/`。`tests/test-paradigm-selection.sh:16`がrepo外依存を持つため — cycle 20260706_1216 #1 / 前cycle Insight 1）→ 116/116
7. `grep -rn 'check-claude-md-staleness' --include='*.md' .`の非cycle-doc / 非CHANGELOGヒットが0件

Evidence: (orchestrate が自動記入)

## Progress Log

### 2026-09-06 11:20 - KICKOFF
- Cycle doc created
- Scope definition ready
- Phase completed

### 2026-09-06 11:20 - SYNC-PLAN
- sync-plan agent により plan ファイル（/Users/morodomi/.claude/plans/twinkling-petting-kitten.md）から Cycle doc への転記完了（Scope Definition / Environment / Context & Dependencies / Recall / Test List / Implementation Notes / Verification / Plan Review Record）
- 補足: orchestrate Block 0 の codify-insight が前 cycle doc（docs/cycles/20260904_1521_test-hooks-hermetic-fixtures.md）を更新済み。scope 同梱の透明化として本 cycle の commit に同梱される見込み（plan-discipline 準拠）
- Phase completed

### 2026-09-06 11:20 - Plan Review (pre-approval)
- codex_session_id: ""
- review_attempts:
  - {started: 19:41, completed: 19:47, verdict: FAILED-usage-limit}
  - {started: 19:52, completed: 19:59, verdict: WARN}
- findings 要約: Codex plan review は実行不能（`codex exec --sandbox read-only "review plan <path>"` が usage limit で exit 1、tokens 61,812 消費後に打ち切り、verdict出力なし）。silent skip を避けるため Claude 側 design-reviewer による代替レビューを実施。代替レビュー(important 3 / optional 3、全件PdMが実ファイルで検証しCONFIRMED、全件反映済み): [important] tests/test-meta-doc-consistency.sh の make_fixture(L33-45) が AGENTS.md・hooks.json・STATUS.md・CLAUDE.mdを含まずabortする懸念 → Design Bにabort-safety制約明記、Verification 5bにmeta test直接実行を追加。[important] Verification 5のoracleがTC-B1/TC-C1/TC-B4の3件のみでTC-B3/TC-C2の検出力が未実測 → 全5契約のoracleを(a)〜(e)として列挙。[important] agents実数40の導出がtest-skills-structure TC-B1(frontmatter判定)と新規TC-C1(ファイル名パターン)で異なり将来乖離しうる → TC-C1をfrontmatter判定へ統一。[optional] TC-A3の「残存TC数7」ハードコードpinがbrittle → 恒久TCから外しVerificationの一時確認へ降格。[optional] CHANGELOG [Unreleased]の#144/#195のFixedと文脈矛盾に見える → Removedエントリに前cycle成果の独立性を1文添える旨をFiles注記へ。[optional] 「harnessがskill一覧を自動注入する」という未検証の主張 → CLAUDE.md1行目が@AGENTS.md(実測確認)という根拠へ差し替え
- unresolved_blocks: なし（critical 0。Codex plan review自体が未実施である点はcodex_unavailableとして記録。Codex回復（9/7 11:53）後にpost-hocレビューを当てる場合は、承認後のplan review再実行禁止規約によりCycle docへの追記扱いとする）
- plan_presented: 2026-09-06 20:05
- reviewed_plan_hash: 194d493ca98e80a62b8da7b068baed9b27acd5839a65f65840bd1be772d96280
- codex_unavailable: true
- verdict: WARN
- Phase completed

---

## Next Steps

1. [Done] KICKOFF <- Current
2. [Next] RED
3. [ ] GREEN
4. [ ] REFACTOR
5. [ ] REVIEW
6. [ ] COMMIT
7. [ ] DONE

### 2026-09-06 11:40 - ARCHITECT (Post-Transfer Verification + Design Review Gate)
- **Post-Transfer Verification: PASS** — Plan Review Record（verdict WARN / codex_unavailable true / codex_session_id 空文字 / review_attempts 2 件）、Test List 9 件、Files to Change 7 件、Out of Scope 4 件、Verification 1〜7（5b 含む）、Recall 3 件がすべて欠落なく転記されている。reviewed_plan_hash は architect が独立に再算出して一致を確認（`awk '/^## Plan Review Record/{exit}{print}' plan.md | shasum -a 256`）。SYNC-PLAN 完了マーカーは手読みと pre-red-gate rc=0 の両方で確認
- **Design Review Gate: WARN**（実装前に解消が必要な観察 1 件 + 観察のみ 1 件）

#### 訂正 1: agents 実数の導出ロジック（plan 内部矛盾の是正、実装はこちらに従うこと）

plan L67 由来の Design B 記述（本 Cycle doc L178）が**古い導出式のまま残存**している:

> - **STATUS.md の数値**: Skills 値 = `ls -d skills/*/` の数、Agents 値 = `ls agents/*.md | grep -v -- '-reference'` の数

これは design-reviewer の指摘を受けて Design C と TC-C1（本 Cycle doc L110）を **frontmatter 判定**（`agents/*.md` のうち 1 行目が `---`、tests/test-skills-structure.sh TC-B1 と同一ロジック）へ統一した際の、PdM による反映漏れ。plan は承認後 IMMUTABLE のため plan 側は修正せず、**本エントリを実装時の正とする**。

- **実装が従うべき正**: TC-C1 は **frontmatter 判定**。L178 の `grep -v -- '-reference'` 式は無効
- 今日はどちらの式も 40 を返すため実害はない（architect が直接実行して確認: `ls agents/*.md` 総数 41 / frontmatter 判定 40 / `-reference` 除外 40）。しかし将来 frontmatter を持たないファイルが `-reference` 以外の名前で追加されると 2 つの契約が無矛盾のまま乖離する
- 3 分岐判定: **観察のみ**（scope の実質変更ではなく、承認済み Test List（TC-C1）の記述どおりに実装すれば足りる）

#### 訂正 2: scope 同梱注記の反復（DISCOVERED 候補）

orchestrate Block 0 の codify-insight が前 cycle doc を更新し commit へ同梱される、という透明化注記は **6 cycle 連続**で sync-plan が plan 由来でなく独自に追記している（20260717_1126 → 20260721_1503 → 20260723_1103 → 20260723_1328 → 20260903_1130 → 本 cycle）。architect が `git status --short docs/cycles/` で事実を確認済み（前 cycle doc が M、本 cycle doc が ??）。rules/plan-discipline.md の 2-strike rule 閾値をとうに超えているが自動化は未実装。scope 影響はないため観察のみとし、DISCOVERED で issue 起票を検討する

#### architect が直接実行で確認した事項（抜粋）

- hook の orphan 性（hooks.json 0 件 / .git/hooks/pre-commit は別 script / skills/onboard 0 件）
- TC-03 が FIXTURE_DIR・cleanup・trap を使い続けるため test-trap-handler T-01/T-02/T-03 は削除後も維持される
- test-post-approve-gate-removal TC-06 は `TC-11|TC-12` のみ禁止（TC-10 削除は無影響）、TC-07 の "stale hook" は無関係の別文言
- test-meta-doc-consistency.sh make_fixture（L33-45）は architecture.md / README.md / skills/skill-N のみ生成 → abort-safety 制約は実在かつ必要
- test-skills-structure.sh TC-B1 を直接実行し PASS（declares 40 / actual 40）
- CLAUDE.md 1 行目が `@AGENTS.md`、STATUS.md に `| Agents | 41 |`（修正対象のバグ）が現存
- 拡張 sweep: STATUS.md の旧値 41 や削除対象の CLAUDE.md skills 行を pin する test は存在しない
- Phase completed

### 2026-09-06 12:13 - RED
- `tests/test-doc-consistency.sh` に契約テスト TC-20〜TC-27 を追加（新規 test file なし、Test Scripts 116 不変を実測確認）。既存 TC 最大番号 19（`grep -oE '^# TC-[0-9]+' tests/test-doc-consistency.sh` 実測）から採番
- TC-20（=TC-A1）: `scripts/hooks/check-claude-md-staleness.sh` 不在の negative 契約
- TC-21（=TC-A2）: `tests/test-hooks-structure.sh` の staleness 専用識別子（`check-claude-md-staleness` / `STALENESS_THRESHOLD_DAYS` / `fixture_repo_with_docs` / `run_staleness_hook` / `DAY_SECONDS`）0 件契約
- TC-22（=TC-A3）: `tests/test-agents-md-propagation.sh` の `STALENESS` 0 件契約
- TC-23（=TC-B1）: AGENTS.md `Skills available:` 行の skill 名集合と `skills/*/` ディレクトリ集合の完全一致（欠落・余剰を両方向で報告）
- TC-24（=TC-B3）: CLAUDE.md Hooks 表の script basename 集合と `hooks/hooks.json` 登録 command の basename 集合の一致（`~/.claude/hooks/` 始まりの global hook 行は除外）
- TC-25（=TC-B4）: CLAUDE.md に `Available skills (N total)` が存在しない恒久 negative 契約（CONSTITUTION §8）
- TC-26（=TC-C1）: docs/STATUS.md `| Agents | N |` と frontmatter 判定（`tests/test-skills-structure.sh` TC-B1 と同一ロジック、architect 訂正 1 に従い `grep -v -- '-reference'` は不採用）による実数の一致
- TC-27（=TC-C2）: docs/STATUS.md `| Skills | N |` と `skills/*/` ディレクトリ数の一致
- abort-safety: 全ての新規 `$(grep ...)` / `$(jq ...)` / `$(find ...)` 代入に `2>/dev/null` + `|| true` を付与。対象ファイル欠落時は `fail()` で報告し Summary へ到達させる設計とし、`tests/test-meta-doc-consistency.sh` の fixture（AGENTS.md/hooks.json/STATUS.md/CLAUDE.md を含まない）で abort しないことを想定
- **実測 RED 結果**（`bash tests/test-doc-consistency.sh`、rc=1、PASS 19 / FAIL 5 / TOTAL 24）: FAIL = TC-20（hook 本体が現存）/ TC-21（staleness 識別子 28 件現存）/ TC-22（STALENESS 3 件現存）/ TC-25（`Available skills (28 total)` が CLAUDE.md に現存 1 件）/ TC-26（STATUS.md Agents=41 != 実数 40）。PASS = TC-23（AGENTS.md skills 一覧は現状正）/ TC-24（CLAUDE.md Hooks 表は現状正）/ TC-27（STATUS.md Skills=28 は現状正）+ 既存 TC 全件（TC-13 regression 含む）
- Test Scripts count 不変を実測確認: `ls tests/test-*.sh | wc -l` → 116（新規 test file 追加なし、`git status --short` は `tests/test-doc-consistency.sh` の modified のみ）
- Phase completed

### 2026-09-06 12:38 - GREEN
- 実装（In Scope A/B/C/D、承認済み Files to Change の範囲内）:
  - A-1: `scripts/hooks/check-claude-md-staleness.sh` を `git rm` で削除
  - A-2: tests/test-hooks-structure.sh から TC-04 / TC-05a〜f / TC-06 と staleness 専用 helper（fixture_git / fixture_git_init / fixture_commit_backdated / run_staleness_hook / DAY_SECONDS / fixture_repo_with_docs）を削除。**`FIXTURE_DIR` / `cleanup()` / `trap cleanup EXIT INT TERM` は単一行形状のまま維持**（test-trap-handler T-01/T-02/T-03 の逆向き契約。前 cycle で分割して壊した反省を委譲 prompt に明記した）。残存 TC は TC-01/02/03/07/08/09/10 の 7 件
  - A-3: tests/test-agents-md-propagation.sh から STALENESS_HOOK 変数・前提存在チェック・TC-10/TC-11 を削除
  - B: CLAUDE.md の `Available skills (28 total): ...` 行を削除し「一覧は AGENTS.md（`@AGENTS.md` で import 済み）を参照。」へ置換。annotated な 2 行（cycle-retrospective / codify-insight）は保持
  - C: docs/STATUS.md `| Agents | 41 |` → `| 40 |`（frontmatter を持つ agent の実数。false-positive-filter-reference.md は reference doc）
  - D: CHANGELOG [Unreleased] に Removed / Added / Changed を追記（前 cycle の hermetic 化が TC-03 の実ツリー汚染除去として独立に残る旨を明記）
- **PdM による委譲事故の検出と復旧**: green-worker が Verification 5（契約の検出力 oracle。plan 上は PdM の手順）を自発的に開始し、AGENTS.md の skills 一覧から `careful` を削除して TC-23 の FAIL を確認する段階で停止、**revert せずに放置**した。PdM が `git status` で承認済み Files to Change に無い `M AGENTS.md` を検出し `git checkout -- AGENTS.md` で復元。委譲報告のみを信じていれば壊れた AGENTS.md が commit に混入していた（前 cycle Insight 1「委譲報告と実 diff を grep で突合する」の適用で捕捉）
- green-worker はその後も「待機中」の非応答を 3 回返したため、GREEN の完了処理（検証実測・phase 遷移・本エントリの記録）は PdM が引き継いで実施した
- 検証（PdM 実測、RUN_AT=12:31:08 を出力に埋め込み世代を明示）: test-doc-consistency rc=0 / test-hooks-structure rc=0 / test-agents-md-propagation rc=0 / **test-trap-handler rc=0（trap 契約 3 本の維持を確認）** / test-meta-doc-consistency は別途確認 / `ls tests/test-*.sh | wc -l` = 116（不変）
- git status: 承認済み Files to Change 7 件（+ Cycle doc 2 件）のみ。意図外の変更なし
- Phase completed

### 2026-09-06 12:44 - GREEN 記録の訂正（PdM の誤認）
前エントリ（12:38 - GREEN）で「green-worker が AGENTS.md を **revert せずに放置した**」と記録したが、**これは PdM の誤認である**。green-worker の最終報告により以下が判明した:

- worker は Verification 5(a) の oracle（AGENTS.md から `careful` を一時削除 → TC-23 の FAIL を確認 → 復元）を **監視付きバックグラウンド実行の途中**であり、その後自力で `cp` バックアップから復元し `cmp` と `git diff --quiet` で完全一致を検証済みだった
- PdM が `git status` で観測した `M AGENTS.md` は **oracle 実行中の過渡状態**であり、放置された最終状態ではなかった。PdM の `git checkout -- AGENTS.md` は worker の復元を先回りした介入で、最終的なファイル内容は両者一致（現在 `git status --short AGENTS.md` は差分なし、`careful` も存在）
- worker が「待機中」の非応答を返していたのは Monitor 待ちのためで、作業放棄ではなかった

**この誤認自体が本 cycle の insight 候補**: 並行実行中の worker が作る過渡的な作業ツリー状態を、PdM が「事故」と誤判定した。前 cycle Insight 1（委譲報告と実 diff の突合）を適用した結果として検出したが、**「diff に想定外の変更がある」＝「事故」ではなく、worker が oracle や一時 fixture のために意図的に作る中間状態でもありうる**。突合で差分を見つけた場合、worker が完了しているか（停止通知の内容が最終報告か中間報告か）を先に判定すべきだった

- worker 側の最終検証（PdM の実測と一致）: test-doc-consistency PASS 24/24 / test-hooks-structure 7/7 / test-agents-md-propagation 2/2 / test-trap-handler rc=0 / test-meta-doc-consistency 4/4 / test 数 116
- **Verification 5(a) は worker が実測済み**（`careful` 削除 → `TC-23: mismatch — missing from AGENTS.md list=[careful]` で FAIL を確認）。残る (b)〜(e) は PdM が VERIFY フェーズで実施する

### 2026-09-06 12:49 - REFACTOR
- チェックリスト 7 項目を変更ファイル（tests/test-doc-consistency.sh）に適用
- **#1 重複コード**: TC-21 / TC-22 / TC-25 に 3 回重複していた「ファイル存在確認 → `grep -c` → 空文字を 0 に正規化 → 0 件判定 → pass/fail」ブロックを `assert_zero_hits <tc_id> <file> <grep_flags> <pattern> <label>` へ集約（約 33 行 → 6 行）。abort-safety の根拠（本 suite は test-meta-doc-consistency.sh から対象ファイルを持たない fixture 上で BASE_DIR override 実行されるため、裸の $(grep) 代入は set -e で Summary 到達前に abort する）を helper の doc コメントに一元化
- **挙動変更 1 件（意図的）**: TC-25 はファイル欠落時に vacuous PASS だったが、helper の fail-closed 方針に揃えて `fail()` 報告へ変更。CLAUDE.md の消失自体が検出すべき異常であるため。stale になった旧コメントも実装に合わせて更新
- #2 定数化 / #3 未使用 import / #4 let→const / #5 メソッド分割 / #6 N+1 / #7 命名一貫性: bash テストのため非該当、または既に適切（helper 化により TC21_FILE/TC22_FILE 等のローカル変数命名の不統一も解消）
- Verification Gate（PdM 実測、RUN_AT=12:42:05 / helper_uses=6 を出力に埋め込み世代明示）: `bash -n` 構文 OK、tests/test-doc-consistency.sh **PASS 24 / FAIL 0**（TC-20〜27 全 PASS）、tests/test-meta-doc-consistency.sh rc=0（helper 化後も abort-safety が維持されていることを fixture 環境で確認）
- Phase completed

### 2026-09-06 12:57 - VERIFY (Product Verification)
**契約の検出力 oracle を 5 契約すべてで実測**（Verification 5(a)〜(e)）。「常に PASS する壊れた契約」を作り込んでいないことの実証:

| oracle | 変異内容 | 結果 |
|---|---|---|
| (a) TC-23 | AGENTS.md の skills 一覧から `careful` を削除 | **FAIL 検出**（`missing from AGENTS.md list=[careful]`）※ green-worker が実測 |
| (b) TC-24 | CLAUDE.md Hooks 表の `observe.sh` → `observe-BROKEN.sh` | **FAIL 検出**（両側の集合を並記: `CLAUDE.md=[... observe-BROKEN.sh ...] hooks.json=[... observe.sh ...]`） |
| (c) TC-25 | CLAUDE.md に `Available skills (28 total)` を書き戻す | **FAIL 検出**（`has 1 hit(s)`） |
| (d) TC-26 | docs/STATUS.md の Agents を 41 へ戻す | **FAIL 検出**（`Agents (41) != actual (40)`） |
| (e) TC-27 | docs/STATUS.md の Skills を 27 へ | **FAIL 検出**（`Skills (27) != actual (28)`） |

- (b) は design-reviewer が「global 行の除外方向の反転や判定列の取り違えで壊れた契約になりやすい」と名指しで警告した箇所。実測で検出力を確認した
- 復元: `cmp -s` で backup と完全一致を確認（CLAUDE.md / docs/STATUS.md とも）。`git status --short` は承認済み Files to Change のみで意図外の残置なし
- real-path invocation（rules/integration-verification.md）: 削除対象 hook を呼ぶ経路が存在しないことは Baseline で確認済みのため、本 cycle の real-path 検証は「契約テスト自身を実データに対して実走させる」形で満たしている（上記 oracle 5 件 + Gate 2 の 5 テスト）
- Phase completed

### 2026-09-06 14:45 - REVIEW
- Risk: risk-classifier.sh = **HIGH score:60**。Codex は usage limit（回復 9/7 11:53）で **plan review・code review とも実行不能**のため、Claude panel を 4 名（correctness / test / impact / maintainability）に厚くして代替
- Step 4.4 Output Validation: `severity-verdict.sh validate` → 4 file すべて OK、retry 0 回
- raw severity_counts: correctness 0/1/4、test-reviewer 0/2/2、impact 0/1/1、maintainability 0/2/6
- 決定論集計: `severity-verdict.sh verdict triage2.json` → **WARN critical:0 important:7 optional:11 invalid:0**（accept-apply 9 / accept-defer 9 / reject 0）

#### Socrates が確定させた 3 件（PdM が全件実測で CONFIRMED）

1. **「時間ベース警告を機械検査へ置換した」は未成立** — pre-commit-gate.sh も commit skill も契約テストを呼ばない（実測）。削除した hook と同じ「呼ばれない防御」形状を新規に出荷することになる。rules/integration-verification.md の「gate ロジック強化と全 caller pin を分離して両方 pin せよ。前者だけでは dead な防御」が逐語で該当。Verification が real-path invocation を「契約テスト自身を実データに実走させる形で満たす」と再解釈したことが caller 側の問いを飛ばした経路
2. **assert_zero_hits は新規の見落としでなく同一ファイル 250 行上の TC-17 に対する退行** — TC-17 は「rc>=2 を 0 件 PASS に紛れ込ませない」を明記して実装済み。`grep -c` はマッチなしでも stdout に 0 を返して rc=1 のため、空文字正規化は実質 rc>=2 のときしか発火せず「abort-safety」を称した実行エラー隠蔽だった（PdM oracle 実測: no-match → out='0' rc=1 / grep-error → out='' rc=2）。しかも REFACTOR の Verification Gate は 24/24 PASS という happy path のみで、test-patterns.md の「エラー経路の oracle は chmod 000 で誘発」を未適用
3. **「派生事実を pin する」解法自体を誰も検証していない** — 反例が本 cycle 内にある。TC-17 のパターンが `issue #[0-9]+` 形式を要求するため、PdM が新規に入れた `(#207)` 表記が match せず 24/24 PASS のまますり抜けた（実測確認）。pin は「誰かが pin することを覚えていた形」しか覆わず、覆っていない形は PASS として見える

加えて Socrates は **PdM 設計の土台の穴**を指摘: Ambiguity Resolution 全体が乗っている「CLAUDE.md 1 行目が `@AGENTS.md`」を pin する契約が無く、この行が消えれば skills 一覧は失われるのに TC-23〜27 は全 PASS のままだった（TC-25 は「戻っていないこと」しか見ない）。dev-crew 自身の CLAUDE.md を pin する test は 0 件で、既存の `@AGENTS.md` 検査は onboard の**配布テンプレート**に対するものだけだった（実測）

#### ユーザー裁定（AskUserQuestion）

- gate 配線: **宣言を訂正して defer**（本 cycle では配線しない。Goal / CHANGELOG を正直な記述へ修正）
- pin 路線: **設計 issue に集約**（次に pin を足す前に生成化 / §8 準拠 / pin 継続を決める判断点を作る）

#### accept-apply（本 cycle で適用済み、9 件）

- [important] `assert_zero_hits` を TC-17 と同一実装へ回帰: rc を直後取得し rc>=2 は `fail` で「0 件」から分離。併せて `-e` を挟み `-` 始まりパターンのオプション誤解釈も防止
- [important] **TC-28 を新設** — CLAUDE.md 1 行目の `@AGENTS.md` を pin（Socrates が指摘した土台の無防備を解消）
- [important] test-doc-consistency.sh ヘッダの TC 一覧 drift を解消（TC-01〜TC-28 へ）
- [optional] `(#207)` 追跡ラベル 2 箇所を除去（グローバル CLAUDE.md の「追跡番号・監査ラベルを入れない」規約違反。TC-17 のパターンがこの形を検出できないことも #210 の材料）
- [optional] TC-21 のパターンに `fixture_commit_backdated` を補完 / `xargs -n1 basename` → `sed` （同ファイル TC-16 の回避方針に整合）/ TC-26 の `head` を裸 command substitution から guard 付きへ / docs/STATUS.md の Last updated を 2026-09-06 へ
- CHANGELOG: Added エントリに「full suite 実行時にのみ検査され COMMIT 経路での強制は未実装（#211）」を明記し「置換した」の overclaim を訂正。Fixed エントリにも「hook 自体は同 [Unreleased] で削除された」の双方向参照を追加

#### accept-defer → issue 起票

- **#210**（pin 路線の設計判断: 生成化 / CONSTITUTION §8 準拠 / pin 継続。**次に pin を足す前に判断する**）
- **#211**（COMMIT 経路への配線。「置換した」と言える条件を明記。#210 の判断が先）
- **#212**（extract_section の切り出し / 19 security agents の pin / TC-24 の Script 列限定 + extraction-failed 分岐 / grep_flags の enumerate-and-reject / assert_status_row helper）

#### 検証

- `bash tests/test-doc-consistency.sh` → **PASS 25 / FAIL 0 / rc=0**（TC-20〜28 全 PASS）
- 途中 1 回「FAIL: 1」を観測したが、これは PdM の連続編集（TC-28 追加とヘッダ修正の間）の**過渡状態**を読んだもので、編集完了後の再実行で 0 件を確認。前 cycle Insight 3（実行世代の確認）の再発
- Phase completed

---

## Retrospective

### Insight 1: 「1 つの読みを、期待どおりになるケースだけで確かめて確定する」— 本 cycle で 4 回踏んだ同型の癖
- **Failure**: 独立に見える 4 件が同一の機序だった。(a) agents 実数の導出を plan 内 3 箇所に書き、design-reviewer の指摘を反映した際に Design C と Test List だけ直して Design B を残し architect に検出された。(b) worker の `M AGENTS.md` を見て「事故」と断定し報告したが、実際は oracle 実行中の過渡状態で worker は復元予定だった。(c) REFACTOR で `assert_zero_hits` を導入し 24/24 PASS だけを見て確定したが、エラー経路（grep rc>=2）を試しておらず「実行エラーを PASS に隠す」実装だった。(d) accept-apply 適用の途中で走ったテストの「FAIL: 1」を読み、編集完了前の過渡状態と気付かず追跡に往復した
- **Final fix**: (a) Cycle doc に訂正エントリ + 委譲 prompt で正を明示 (b) worker 完了報告を待って訂正エントリを追記 (c) Socrates/reviewer 指摘後に oracle 実測 → TC-17 と同一実装へ回帰 (d) 編集完了後に再実行して PASS 25/FAIL 0 を確認
- **Insight**: **「確かめた」と言うには、期待どおりになるケースだけでなく『壊れているならここで落ちるはず』のケースを 1 つ通す必要がある。反例を作らない検証は検証ではない。特に (i) 同じ事実を複数箇所に書いたら全箇所を grep して数を数える、(ii) 並行実行中の観測は「その worker は完了しているか」を先に判定する、(iii) 新しい判定ロジックは正常系と異常系の両方の oracle を作ってから確定する**
- **一般化**: rules/test-patterns.md「エラー経路（rc>=2）の oracle は chmod 000 の権限拒否 fixture で誘発する」(20260716_1328 #1) は既に codified 済みだが、REFACTOR フェーズの Verification Gate には適用されていなかった。条項の適用範囲を「新規テスト作成時」から「判定ロジックを触る全フェーズ（REFACTOR 含む）」へ拡張すべき

### Insight 2: DRY 目的の共通化は、集約先が既存の防御を打ち消していないか同一ファイル内の前例と突合してから確定する
- **Failure**: REFACTOR で 3 箇所の重複を `assert_zero_hits` へ集約した際、同一ファイル 250 行上の TC-17 が「grep 結果は変数受け + rc 直後検査し rc>=2 を 0 件 PASS に紛れ込ませない」という防御をコメント付きで実装済みだったのに、新 helper は `|| true` で rc を捨てる形にした。3 契約（TC-21/22/25）すべてに欠陥が波及し、staleness 再導入の恒久検出という本 cycle の核が「動かない番犬」になっていた
- **Final fix**: correctness/test-reviewer の指摘 → PdM が oracle 実測（no-match は stdout に '0' + rc=1、grep-error のみ空 + rc=2）→ TC-17 と同一の rc 分離実装へ回帰。`-e` によるオプション誤解釈防止も同時に適用
- **Insight**: **重複を helper へ集約するとき、集約元の各実装が持っていた防御（rc 検査・型ガード・早期 return）の和集合を helper が保持しているかを確認する。DRY は「行数を減らす」ことではなく「振る舞いを 1 箇所に集める」ことであり、振る舞いには防御も含まれる。同一ファイル内に同種の処理があるなら、それが why コメントを持つ場合は特に、その why を helper へ持ち込めているか突合する**
- **一般化**: rules/test-patterns.md の「meta test で logic copy-paste 禁止」（DRY 側）に対する対称条項として「共通化時の防御の欠落禁止」を追記する候補

### Insight 3: 「呼ばれない防御」を削除する cycle は、置き換え先が呼ばれるかを Verification の必須項目にする
- **Failure**: 本 cycle は「orphan（誰も呼ばない）だから削除する」を根拠に staleness hook を削除し、代替として契約テストを新設したが、**その契約テストもどこからも呼ばれない**（pre-commit-gate も commit skill も実行しない）。削除したものと同じ形状を新規に出荷しかけた。Verification に「契約テスト自身を実データに実走させた」と書いたことで real-path invocation の要件を満たしたと解釈し、caller 側の問いを飛ばした
- **Final fix**: impact-reviewer が指摘 → Socrates が最重指摘として確定 → ユーザー裁定で「宣言を訂正して defer」。CHANGELOG と Cycle doc の Goal を「置換した」から「契約テストを追加した。COMMIT 経路での強制は #211」へ修正し、配線を issue 化
- **Insight**: **「X は誰からも呼ばれていないから削除する」という論法を使う cycle は、代替物について同じ問いに答える義務を負う。Verification に「代替物の caller を実測で示す」項目を必須で置く。rules/integration-verification.md の「gate 強化は gate ロジックと全 caller pin を分離して両方 pin する。前者だけでは dead な防御」は、削除 cycle にも対称に適用される**
- **一般化**: 「削除候補は着手前に呼び出し元を実測する」（前 cycle が orphan 性を先に検証していれば hermetic 化自体が不要だった）と対で rules/integration-verification.md へ追記する候補

### Insight 4: pin を足す解法は「覚えていた形」しか覆わない — 反例が同じ cycle 内で観測された
- **Failure**（成功の記録でもある）: 本 cycle は派生事実の drift を pin で防ぐ路線を採ったが、Socrates が同 cycle 内から反例を示した。TC-17（2-strike rule で自動契約化された追跡ラベルの逆向き契約）のパターンは `issue #[0-9]+` 形式を要求するため、PdM が新規に入れた `(#207)` 表記に match せず 24/24 PASS のまますり抜けた。同様に「19 security agents」も未 pin、ヘッダ TC 一覧も drift していた
- **Final fix**: `(#207)` を除去し、土台の `@AGENTS.md` 行を TC-28 として pin。ただし根本は解決していないため、ユーザー裁定で #210（生成化 / CONSTITUTION §8 準拠 / pin 継続 のいずれを採るか）を「次に pin を足す前に判断する」条件付きで起票
- **Insight**: **pin による drift 防止は、pin を書いた人が想定した違反形しか検出しない。想定外の形は「PASS」として見えるため、穴が増えても検出されない。pin を N 個足すたびに『この pin が覆っていない同種の形は何か』を 1 件挙げられるかを問い、挙げられないなら pin ではなく生成か削除（CONSTITUTION §8）を検討する**
- **一般化**: #210 の判断材料。本 insight 自体が「pin 路線の限界を pin では検出できない」という自己言及的な構造を持つ

### 想起漏れ

- **設問**: 今回の手戻りは、過去のどの cycle doc を最初に読んでいれば防げたか
- **回答**: **docs/cycles/20260716_1328_doc-drift-fix.md**（Insight 1: エラー経路の oracle は chmod 000 の権限拒否 fixture で誘発する / Insight 3: negative sweep のパターンは新文言不一致も oracle 実測してから採用する）。Insight 2 の `assert_zero_hits` 欠陥は、この条項を REFACTOR の Verification Gate に適用していれば作り込む前に検出できた。本 cycle の Recall は「変更予定ファイル」を入力に取ったため staleness / agents-md 系の cycle が上位に出たが、「判定ロジックを新規に書く」という**作業の性質**に紐づく cycle は候補に出なかった。前 cycle の想起漏れ回答（「full suite を隔離実行する手順に紐づく cycle が出なかった」）と同型で、Recall の入力に「その cycle で行う作業の種類」を加味すべきという #187 R4 計測への 2 例目の観察材料

### 2026-09-06 14:57 - COMMIT
- 全ゲート PASS（pre-commit-gate rc=0 / Test List 未完了 0 / RED・GREEN・REFACTOR・REVIEW の Phase completed / retro_status: captured）
- **gate の既知の弱点を明記**: pre-commit-gate の「Codex review 記録」チェックは `Codex.*review` の grep であり、本 cycle は **Codex の不在（usage limit）を記録した文字列**で通過している。実レビューは行われていない（前 cycle でも同型を記録済み）。Codex 回復後に post-hoc レビューを当てる場合は Cycle doc への追記扱いとする
- STATUS.md: Completed 行追加 + Done 78→79 + Last updated 2026-09-06（REVIEW の accept-apply で適用済み）。Test Scripts 116（新規 test file なし、不変）
- full suite（親構造込み隔離 snapshot、SNAP_AT=14:45:38 / TC-28 と rc ガードの存在を出力で確認）: **116/116 FAILED:none**
- commit 同梱: tests 3 + hook 削除 1 + CLAUDE.md + docs/STATUS.md + CHANGELOG + Cycle doc + 前 cycle codify 出力（Block 0、scope 同梱として透明化）
- Phase completed
