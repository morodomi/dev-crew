# Changelog

## [Unreleased]

### Removed
- テストスイートの入れ子重複を除去した（`docs/cycles/20260916_1634_shrink-runner-remove-nesting.md`、ADR-004）: `tests/test-doc-consistency.sh` TC-13 と `tests/test-factory-model-adaptation.sh` TC-14（いずれも「全テストを nested 実行するだけ」の meta test で `run-tests.sh` と役割が重複していた）を削除。延べテスト実行回数は **458 回 → 117 回**。フルスイートは実測 **154.82 秒**（入れ子除去のみの単独計測）まで短縮
- `run-tests.sh` から前 cycle（20260913_0059）が積み上げた機構を削った: 指紋の三点照合・再試行プロトコル・PID/起動時刻/所有者追跡・reaper・admission の load/memory 判定・`.claude/test-serialization.json`（+ `jq` 処理 + `.gitignore` negation 行）・実行後 live tree advisory・`DEV_CREW_RUNNER_LIB_ONLY`（source-as-library）・`DEV_CREW_TEST_HOOK_BEFORE_COPY`/`DEV_CREW_TEST_HOOK_AFTER_COPY`。exit code は `0/1/2/3` の 4 値へ縮小（`4`/`5` 廃止。signal 終了 129/130/143 は別枠のまま）。**削る前に測った**: memory admission は `free + inactive` を空きメモリとして報告していたが、実 `Pages free` はその 1/80 で、この誤判定の直後にジョブが 2 回 OOM 停止していた。`run-tests.sh`: 1,068 行 → 479 行。`tests/test-run-tests-runner.sh` から対応する 31 TC を削除（TC-04/04b/05/06/07/08/09/10/11/12/13/21/22/23/24/24b/25c/28/29/29b/30/31/32/33/34/35/35b/36/37/38/45）。**この縮小自体の速度への寄与は小さい（148.96 秒、入れ子除去単独の 154.82 秒から約 4% で誤差に近い）** — 速度改善のほぼ全部は上の入れ子除去に由来し、本項の目的は複雑さ・保守負債の削減であって速度ではない
- ADR-004（`docs/decisions/adr-test-isolation-boundary.md`）の Status を `deferred` → `accepted` に確定。「コピーして実行」は残し、それ以外は上記のとおり削る境界を確定した。受容する失敗（混成 snapshot・残骸を自動削除しない・単体ファイル実行では全スイート保証が効かない・pgrep 自己/祖先除外の検証手段喪失）を明記

### Added
- `run-tests.sh` を dev-crew の正規 test runner にした。フルスイートも単一テストも同じ入口を通り、(1) **admission check**（テストプロセス数 / load1 / 空きメモリの 3 条件。条件単位 fail-open で、probe 不在・rc >= 2・空出力・非数値は当該条件のみ skip し stderr に明示）、(2) **immutable snapshot 上での実行**（`rules/plan-discipline.md` が既に条項化していた「baseline は immutable snapshot 複製上で実測する」を runner 本体へ適用。copy 直前の source / copy 後の snapshot / copy 後の source の **manifest 三者照合 `A == B == C`** が成立したときだけ実行し、コピー中の変更と ABA を検出する）、(3) 起動時の stale snapshot 掃除（age 単独では削除せず `.owner` の PID liveness と起動時刻トークンで判定）を行う。`.git` は snapshot へ複製しつつファイル単位 manifest からは除外し、suite が実際に読む `git ls-files -z` の出力を virtual entry として三者照合に含める。exit code は `0`=PASS / `1`=1 件以上 FAIL（既存契約、不変）/ `2`=admission BLOCK / `3`=引数拒否 / `4`=live tree 書き込み中による manifest 不一致 / `5`=インフラ障害 で一意に分離した。実行後の live tree 変化は **advisory**（exit code を変えない）— 結果の正しさを決めるのはコピー時点の一貫性であり、実行後の変化は「この baseline が現 HEAD を記述しているか」という別の話であるため。これにより orchestrate が worker 実行中に Cycle doc の Progress Log を追記する現行運用と衝突しない
- `.claude/test-serialization.json`: runner の閾値設定（`k_load` / `mem_min_mib` / `snapshot_stale_minutes` / `warn_on_live_changes`）。`load_max` を直接持たず `k_load` を持ち `ncpu × k_load` を実行時算出するのは、`16` が 8 core 機固有の値で他機では誤るため。キー欠落・型不一致・範囲外は**そのキーのみ**既定値へフォールバックし、設定破損で fail-open しない。`.gitignore` の `.claude/*` に対する negation 行が無いとこのファイルは commit されず設定全体が無効化されるため、negation を併せて追加した
- `tests/test-run-tests-runner.sh`（新規、TC 57 件）: 全て mktemp fixture で、runner を複製した subject と dummy test のみを使い実 `tests/` ツリーへ戻らない（戻ると runner 自身のフルスイート実行へ再帰する）。probe は `PATH` shim で fake 化し実機の負荷状態に依存させない

### Changed
- `AGENTS.md` Quick Start の 2 行を `bash run-tests.sh` / `bash run-tests.sh tests/test-plugin-structure.sh` へ。フルスイート起動の SSOT が `run-tests.sh`（どこからも参照されていなかった）と `AGENTS.md` の inline ループに二重化していた状態を解消した
- `rules/plan-discipline.md` の `## 具体例` を `bash run-tests.sh` 呼び出しへ。従来の正典 harness は独自の snapshot loop を持ちながら **`trap` を一切持たず**、これが snapshot 残留の出所だった。snapshot 所有を runner へ集約する以上、正典に別実装を残すと二重管理になる
- `rules/agent-prompts.md` の「読み取り並列・実行直列」条項に**完了通知の意味論**を追記: 完了通知は agent の turn が終わったことを示すだけで、その agent が起動した background descendant の終了を保証しない
- いずれも `.claude/rules/` 側の mirror を同時更新（`tests/test-rules-mirror.sh` が完全一致を要求する）

### Notes
- **設計は承認前 Codex plan review 5 ラウンドで 3 回縮小した**。初版「PreToolUse hook 単独」は、(a) 同種 hook が「バイパス可能」を理由に削除された先例（`docs/cycles/20260326_2320`）、(b) PreToolUse は tool call 直前に 1 回発火するだけでロックを保持せず、2 つの Bash 呼び出しが同時通過すれば両方が `pgrep=0` を観測する check-then-act race、の 2 点で誤っていた。「runner + 排他ロック」へ変更したが owner 公開前 race / reaper の crash recovery / PID 再利用 / ABA / signal の子伝播 が次々に必要になり、単一開発者の repo に分散システムの機構を持ち込む形になったため、ロックを Cycle C へ分離した。**ロックが潰していたのは「二重起動で時間と負荷を無駄にする」だけで、実害（実行中の tree 書き換えによる非再現 FAIL、OOM）はロック無しで消える**
- **REVIEW は Codex と Claude の competitive で BLOCK となり、両者は互いに見落とした欠陥を出した**。Codex は manifest/copy の fail-open（走査不能なディレクトリが A/B/C から同様に欠落すると不完全な snapshot でも `A==B==C` が成立する）と引数契約の穴（`tests/` 配下のディレクトリが通過して TOTAL=0 / exit 0）を、Claude は exit code 契約の破壊（インフラ障害を「テスト失敗」と誤報）と子孫除外が**呼び出し順序上の dead code** であること（`build_exclude_set()` は自分の子孫が存在しない時点で走る）を検出した。mini-iteration 後、変異注入の検出率は 10/12 → **12/12**
- 単一テスト経路のオーバーヘッドは manifest の batch 化で **31.5 秒 → 4.89 秒**。安全保証をオプションで捨てる `--no-snapshot` は導入していない
- 残余リスクは明示的に残した: 二重起動の TOCTOU（ロック不採用のため）、`run-tests.sh` を経由しない inline ループ（いずれも `docs/NEXT.md` item 4 に残タスクとして記載）

### Removed
- `AGENTS.md` / `README.md` のツリー行コメントに残っていた派生数値と、それらを pin していた逆向き契約を削除: `tests/test-skills-structure.sh` の TC-B1・TC-B2、`tests/test-agents-md-count.sh`（ファイルごと削除）、`tests/test-doc-consistency.sh` の TC-01、`tests/test-cycle-retrospective.sh` の TC-15、`tests/test-agents-md-propagation.sh` の TC-14、`tests/test-review-integration-v24.sh` の TC-11。`skills/onboard/reference.md` の「派生数値は doc に書かない」指針に dev-crew 自身の doc を整合させた
- `scripts/hooks/check-claude-md-staleness.sh` を削除（#207）: hooks.json / .git/hooks / skills/onboard のいずれにも登録がない orphan であり、かつ git commit 経過日数は「内容が現状と乖離しているか」の代理指標として機能していなかった（50 日 stale の CLAUDE.md は内容が正確で、8 日前更新の AGENTS.md 側に不整合があった）。関連する tests/test-hooks-structure.sh の TC-04/TC-05a〜f/TC-06 と staleness 専用 fixture helper 群、tests/test-agents-md-propagation.sh の TC-10/TC-11 も削除。直前 cycle（#144/#195）の hermetic 化は TC-03 の実ツリー汚染除去として独立に価値が残る（同 [Unreleased] の Fixed エントリ参照）
- docs/STATUS.md の Current State 表（派生数値 6 項目）を削除。git commit 経過日数と同じく「doc に書かれた派生数値」は読み手が実在せず drift を検出できない — Agents 値は約 4.5 ヶ月誤ったまま誰も気づかなかった。STATUS.md は「人間・PdM しか知らない編集的情報」（Completed / In Progress / TODO）のみを持つ。あわせて pre-commit-gate.sh の STATUS.md 同期 WARN（表削除により完全な no-op になる）と、これらを pin していた次の契約を削除: tests/test-v2-release.sh TC-04 / test-orchestrate-a2b.sh TC-15 / test-codify-insight.sh TC-19・TC-20 / test-cycle-retrospective.sh TC-14 / test-doc-consistency.sh TC-26・TC-27 / test-pre-commit-gate.sh T-03・T-04・TC-14。数値でなく識別子を列挙するのは、本エントリ自身が主題とする「doc に書かれた派生数値は再導出されず drift する」を繰り返さないため

### Added
- `scripts/retro-insight-ledger.sh`（新規）: 複数 repo の cycle doc の `## Retrospective` 節を凍結文法 grammar v2 で機械集計し、`ledger`（1 unit = 1 行の 10 列 TSV）と `summary`（Markdown + 機械可読ブロック）を stdout へ出す。合計値ではなく `doc` + `line` 付きの行単位台帳を成果物にすることで、第三者が原典へ戻って検証できる。repo path は対応表 TSV（`<label><TAB><repo_path>`）経由でのみ受け取り、**repo path 自体は出力に現れない**（label へ還元される）。ただし source 由来の文字列は出力を通過する — ledger の `doc` / `container` / `heading` 列と summary の `ZERO` / `SKIP` 行は、cycle doc 名と見出し本文を原文のまま載せる。したがって「出力は label / sha / dirty / files / digest しか含まない」ではなく、**匿名化されるのは repo path のみ**が正確な契約である。unit の form は 7 種（insight / failure-pattern / addendum-pair / pair / pair-bullet / prose-pair / numbered-item）、polarity は 3 値（explicit_failure / explicit_positive / unknown）で、**unknown を推定で埋めない**。unit にしない列挙は `SKIP ... kind=sub-field|derivative|standalone-positive` として、unit 0 件の doc は `ZERO ...` として明示列挙し、除外を沈黙させない。契約は `tests/test-retro-insight-ledger.sh`（TC-01〜TC-59、全て mktemp fixture）が pin する — とくに「太字 container ルールは全 unit ルールの後に評価する」評価順（TC-27）と「positive が failure に優先する」polarity 優先順位（TC-34）は実測した回帰の pin である
- tests/test-doc-consistency.sh に派生事実の契約テスト TC-20〜TC-28 を追加（#207）: AGENTS.md skills 名前集合 / CLAUDE.md Hooks 表 / CLAUDE.md の skills 一覧 negative 契約 / CLAUDE.md 1 行目の `@AGENTS.md` import を機械検査する（**当初含まれていた docs/STATUS.md の Skills・Agents 数の契約（TC-26/TC-27）は、同 [Unreleased] の Removed のとおり本リリース内で撤去された** — 読み手が実在しない派生数値を pin していたという判断の是正）。**これらは full suite 実行時にのみ検査される** — `pre-commit-gate.sh` も commit skill も現時点では呼んでおらず、COMMIT 経路での決定論的強制は未実装（#211）。したがって本変更は「時間ベース警告を機械検査へ置換した」のではなく「契約テストを追加した。強制は follow-up」が正確な状態である

### Changed
- `README.md` の Skills 見出し（Development Workflow / Security / Language Quality / Meta）から件数表記を除去。見出し配下のスキル名リストは維持し既存契約（TC-04/TC-05/TC-13/TC-18 等）を壊さない
- `tests/test-doc-consistency.sh` に helper `assert_min_hits` / `assert_exact_hits` と TC-33a〜f を追加し、削除した派生数値の再混入を検出する静的 negative（ツリー行の件数表記）/ positive（ツリー行・見出しの存在）契約へ置換
- CLAUDE.md から `Available skills (N total): ...` の skills 一覧行を削除（#207）: 1 行目の `@AGENTS.md` import により同一プロセス内で二重に読まれる純粋な重複であり、CONSTITUTION §8「コードから導出可能な情報は書かない」に反していた。一覧は AGENTS.md 側（Codex が読む cross-tool doc）に一本化
- docs/STATUS.md の `| Agents | 41 |` を `| Agents | 40 |` に修正（#207）: frontmatter を持つ agent の実数。`agents/false-positive-filter-reference.md` は reference doc で agent ではない
- skills/onboard/reference.md の指針を「数値カウントは STATUS.md へ」から「派生数値は doc に書かず実ファイルから導出する」へ反転

### Fixed
- tests/test-hooks-structure.sh の壁時計依存を解消（#144）: staleness hook の検査を fixture git repo（相対 backdate commit）へ移し、実行日に依存しない決定論的検証にした。連鎖 FAIL していた 3 test（test-doc-consistency / test-factory-model-adaptation / test-trap-handler）も回復する。**なお staleness hook 自体は同 [Unreleased] の Removed で削除されたため、この検証ロジックも併せて除去された**（TC-03 の実ツリー汚染除去 #195 は独立に残る）
- tests/test-hooks-structure.sh の drift 検出 fixture を実ソースツリーから mktemp snapshot へ隔離（#195）: 並行実行時に test-agents-structure.sh を汚染しなくなり、TC-41 の暫定除外を撤去した
- .claude/dev-crew.json の dev_crew_version を 2.17.0 に追随（spec Version Gate の誤 BLOCK 解消。自動化は #186）

## [2.17.0] - 2026-09-04

### Breaking
- **13 reviewer agent + architect の JSON 出力契約から `blocking_score`（0-100 の自己申告スコア）が消える**。verdict への反映は `skills/review/severity-verdict.sh` による severity（critical/important/optional）の決定論的集計に一本化される。**消費側の対応**: `blocking_score` を直接 parse していた caller（自作スクリプト・外部連携）は、reviewer JSON の `.issues[].severity` を読み取り `skills/review/severity-verdict.sh verdict` に triage.json として渡す経路へ移行すること
- **verdict の取得方法が変わる**: verdict は `severity-verdict.sh verdict` の **stdout 1 行**（`BLOCK|WARN|PASS critical:N important:N optional:N invalid:M`）から取得する。**script の exit code 0 は PASS を意味しない** — `validate`/`verdict` とも「検証・集計そのものが正常に実行できた」ことのみを表す exit code であり、判定結果は必ず stdout 行を読んで確認すること（`INVALID-TRIAGE`/usage エラーのみ非 0 exit、正常系の BLOCK/WARN/PASS はいずれも exit 0）
- **jq 依存**: `severity-verdict.sh` は jq に依存する。jq が PATH 上に無い環境では `validate`/`verdict` とも `DEGRADED: jq not found` を返し、PdM が Severity 基準表を手動適用する prose 縮退経路に落ちる（fail-open。検証なしを BLOCK にはしない）

### Changed
- reviewer の 0-100 blocking_score 自己採点を廃止し、`skills/review/severity-verdict.sh` による severity 決定論集計（accept-apply/accept-defer の critical≥1→BLOCK / important≥1→WARN / else PASS、reject 除外）に置換
- reject 除外の明文化: 3-category triage で `reject` に分類された finding は severity に関わらず verdict 集計から除外される（severity=critical でも reject なら verdict に効かない）。旧 Score Aggregation でも「reject カテゴリは集計外」（final blocking_score は accept-apply/accept-defer のみから算出）であり意味論は保存 — 新方式ではこの除外が script の決定論集計として機械化された
- reviewer JSON 出力を `severity-verdict.sh validate` で jq 検証するようにした。INVALID の場合は該当 reviewer へ error 行を verbatim で含めて最大 1 回のみ re-request し、なお INVALID なら fail-closed で差別化する（security-reviewer/correctness-reviewer は BLOCK、その他は WARN floor。欠損を PASS に落とさない）

## [2.16.0] - 2026-08-29

### Breaking
- 33 agent（reviewer/attacker 系）が frontmatter `tools:` で権限を限定され、暗黙の「全ツール継承」を失う。旧 `allowed-tools` キーは subagent では無視されていたため、実効挙動の変化は「全権限 → 限定」である
- memory 保持 15 agent は `disallowedTools: Write, Edit` により Write/Edit ツール経由の memory 更新は不可（起動時注入の読取は可）。Bash を持つ recon-agent / dynamic-verifier はシェル経由の書込経路が残るため、完全な read-only ではない（残余リスクとして記録）

### Changed
- agent frontmatter の `allowed-tools`（skill 専用キーで subagent では無視されていた）を正規キー `tools` に正規化し、reviewer/attacker 系 33 agent の宣言ツールを Read/Grep/Glob（+必要な 3 件は Bash）に限定。memory 併用時は tools 宣言外の Write が memory 外にも使える（実測）ため、memory 保持 15 agent は `memory: project` を維持しつつ `disallowedTools: Write, Edit` を追加した。これにより Write/Edit ツール経由の memory 更新は不可（起動時注入の読取は可）。Bash を持つ recon-agent / dynamic-verifier はシェル経由の書込経路が残るため、完全な read-only ではない（残余リスクとして記録）

### Fixed
- dast-crawler の Playwright MCP ツール名 drift（`mcp__playwright__navigate` 等の旧名を `browser_` prefix 付き新名へ修正）

## [2.15.0] - 2026-07-27

### Added
- spec に強制想起（Forced Recall、Step 7.2）を追加（#187）: Files to Change 確定後・Step 8 の前に `scripts/recall-candidates.sh` を実行し、変更予定ファイルに関連する過去 cycle doc を決定論的に提示する。データソースは既存のもののみ（`git log --name-only` の共変更 + Cycle-Doc トレーラーの確定リンク優先）で、ハブファイルは IDF 相当で寄与を減衰。上位候補を助言者形式 3 点セット（何が起きたか / 当時の前提 / 今回も同じ前提か）で plan の `## Recall` に記録し、sync-plan が Cycle doc へ転記する。正本変更ゼロ・冪等・常駐プロセスなし
- コミットメッセージに `Cycle-Doc: <path>` トレーラーを付与（commit スキル）: feature コミットと cycle doc を機械可読なリンクで結ぶ。値は Cycle Doc Gate が解決した主サイクル 1 件の repo-relative パス。commit スキル以外の経路（release-skill・手動コミット）には付与しない
- cycle-retrospective に想起漏れ設問を追加: 「今回の手戻りは、過去のどの cycle doc を最初に読んでいれば防げたか」を全正常終了経路で `### 想起漏れ` 固定 2 行スキーマ（回答 `該当なし` or `docs/cycles/<file>.md`）に記録し、機械集計可能にする
- 20260709 以降の 8 cycle に蓄積された codified insight 19 件を rules へ条項化（rules/{test-patterns, plan-discipline, review-triage, agent-prompts, integration-verification, multi-file-consistency, doc-mutations}.md + .claude/rules/ の同名 mirror へ同時反映）: SIGPIPE consumer 禁止・図契約のノードトークン pin・多段 pipe rc 先取り + 権限拒否 fixture・negative sweep の新文言不一致 oracle・hash boundary fixture pin・doc 内 code block の見出し区間先行抽出・逆向き契約の相対アンカー禁止・機械可読契約の実行可能コマンド化・継承デフォルト前提の一次ソース確認・連番次値の実装実測・Block 0 codify の scope 同梱透明化・判定割れの機構分解 + 実測 oracle・tier テーブル置換の構造突合・委譲 worker のフェーズ完了マーカー必須・timestamp 契約の Progress Log 追記全般拡張・gate 強化の全 caller pin・順序反転の negative assert・current-state 更新の doc 全体 sweep。加えて skills/spec の Plan File Template に `override` フィールドと review_attempts 厳密形式注記を追記（両言語 lockstep）

## [2.14.0] - 2026-07-22

### Changed
- Rules をロード契機（always / cycle-scoped / file-scoped）で分類し、TDD workflow rules を Cycle doc 操作時に限定してロードする構成へ変更

## [2.13.0] - 2026-07-21

### Breaking
- 承認ゲートの意味論変更（approval-reorder、#176）: plan review の実行タイミングが人間承認の前（plan mode 内、spec Step 8）へ変更。新形式の（`plan_file` を持つ）cycle doc では pre-red-gate が `plan_file` と Plan Review Record の存在を要求するようになった（plan_file 不在の legacy cycle doc は従来通り弱い fallback で通過）

### Added
- approval-reorder（#176/#179）: spec に Step 8（承認前 plan review）を追加。Cycle 1（PR #182）で機構・実行時 memory・権威 doc（AGENTS/CLAUDE/workflow/README/architecture）を新順序へ更新。Cycle 2 で残る narrative doc（usability.md フロー図・ROADMAP.md 現在地）と onboard 生成テンプレート（AGENTS.md TDD Workflow / Post-Approve Action / Codex セッション作成の read-only 化）を新順序へ伝播

## [2.12.0] - 2026-07-15

reviewer モデルの設定機構 + 品質規律の codify + risk-classifier 精度改善。v2.11.0 リリース後に main へ蓄積した4サイクル（#148/#165、codified rule/#166、#164/#169、reviewer-policy v1/#173）を一括リリース。

### Breaking
- Code Mode の policy 対象 reviewer が、従来の `model: "sonnet"` 固定から `self`（orchestrator 自身の現在モデルを Task に明示指定）へ変更（#173）。既存 install（`.claude/dev-crew.json` に `review_policy` 未設定）でも既定 `self` が適用され、reviewer は sonnet ではなく実行中モデルで走る。品質・コストへの影響は実行モデルと環境の allowlist 次第。従来挙動に戻すには `review_policy.reviewer_model` を `"sonnet"` に、HIGH のみ上位にするには `escalate_high_to` を設定する。Plan Mode の固定 reviewer は対象外

### Added
- reviewer-policy v1（#173）: `.claude/dev-crew.json` の `review_policy` で Code Mode の reviewer モデルを設定可能に（`reviewer_model` / `escalate_high_to`、allowlist self/sonnet/haiku/opus/fable）。HIGH tier のみ上位モデルへ escalation。security+correctness の NON-NEGOTIABLE floor を初の契約テスト化（TC-04/06）。onboard が dev-crew.json + CLAUDE.md 宣言を生成
- codified rule 7件を rules に実装: (1) 否定形前提の全 grep 根拠 (2) multi-mode skill の全モード契約テスト pin (3) 隔離 snapshot の親構造複製 + N件同時 FAIL の cascade 切り分け (4) 裸 command-substitution の同型 sweep (5) 委譲 worker の timestamp date 実測（以上 #166）(6) frontmatter 区間限定編集 (7) section_grep heading の fixed-string 化（以上 #165）
- gate 選択ロジック drift guard（#148、test-phase-gate TC-24）

### Changed
- review-triage の LOW tier を correctness floor 厳格化（trivial でも security+correctness は常時必須）

### Fixed
- risk-classifier の doc-diff 過大スコア FP（#164/#169）: SQL/external/行数シグナルを code hunk 限定に。doc-centric cycle が誤って HIGH 判定される問題を修正。pipefail 下の pipe+grep -q SIGPIPE under-score bug も修正
- section_grep の ERE 解釈を fixed-string 化（#165、括弧付き見出しの silent no-match 解消）
- phase 図（workflow.md / architecture.md）に COMMIT→DONE 終端を反映（#157）

## [2.11.0] - 2026-07-06

スキル棚卸しと品質規律の自動契約化。skill-audit（外部レビュー）を起点に、
死蔵スキルの削除・ゲート機構の修復・「指示で防げない規約の契約テスト化」を一括で実施。

### Removed
- 死蔵スキル 4 種を削除（32→28）: phase-compact / reload / strategy / parallel（#142）。PreCompact hook は存続
- テストコメントの追跡ラベル（cycle 番号・issue 番号）を全除去し、自動 inverse contract（TC-17）で再混入を禁止（#151）

### Fixed
- pre-commit/pre-red gate の ACTIVE_CYCLE 選択を latest-updated + 明示指定に修正（#145）。first-non-DONE 選択により 2 ヶ月前の doc を検査していた穴を解消。skill 文書 7 ファイルの同型探索も統一
- commit 時の phase: DONE 遷移を orchestrate 全モード（SKILL.md / steps-subagent / steps-codex / steps-teams）で commit skill 委譲に統一（#147）。完了済み 19 doc を DONE へ migration し「non-DONE = active」の意味論を修復（TC-18 invariant）

### Added
- codified insight 14 件を rules 8 ファイル + red skill に実装: contiguous phrase pin / pre-existing count 実測 / baseline snapshot 隔離 / 読み取り並列・実行直列 / usage 実測 / 信頼ディレクトリ境界 / process-substitution rc 検査 / 2-strike rule / 委譲 prompt テンプレート監査 / Test List 遷移責務ほか
- red skill に Stage 3.5「False-pass 自己証明」を新設
- 削除スキル名の path-form inverse contract（TC-16、#143）
- quality 系スキル 6 種の description 先鋭化（トリガー語衝突の解消）

## [2.10.0] - 2026-07-01

### Added
- plan-discipline: count/status 変更 cycle の GREEN 検証を逆向き契約 sweep で全実行する規律（curated リスト禁止、#140）
- rules の path-scoping（#139）

## [2.9.0] - 2026-05-25

### Added
- agent-prompts: 並列起動時の prompt 契約（3+ subagent fan-out の担当範囲・出力形式・統合キー・検証条件）
- review: Step 5 Findings Synthesis

## [2.8.0] - 2026-04-27

### Added
- rules/ ⇄ .claude/rules/ の byte-identical mirror 体制（#132）
- integration-verification rule: Verification Gate に real-path invocation を必須化（#133）
- 蓄積 codify 決定 7 件の rule/skill 実装

### Fixed
- pre-existing 6 FAIL の全解消（full baseline 0 FAIL 達成）
- careful allowed-tools / informal alias sweep / risk-classifier FP ほか debt 解消

## [2.7.0] - 2026-04-21

Agile Loop Step 1: cycle-retrospective ループの実用完成。
TDD サイクル末尾で「最初の失敗 → 最終解 → 事前知識化」のペアを抽出し、
Cycle doc に永続化する。pre-commit-gate で deterministic に検証。

設計: [ADR-002](docs/decisions/adr-cycle-retrospective.md)
PRs: #119 (A1 foundation) / #120 (A2a skill 本体) / #121 (A2b orchestrate 統合) / #122 (post-commit fixes)

### Added

- `skills/cycle-retrospective/` 新規 skill
  - Hard Gate (Cycle doc 存在 + phase REVIEW/COMMIT/DONE)
  - Idempotency Check (retro_status != none → skip)
  - Extraction (mizchi 方式 failure → final fix → insight)
  - Output (## Retrospective を Cycle doc EOF に append、retro_status 遷移)
  - Override 2 路分離 (proceed / abort、default abort)
- `frontmatter.retro_status: none|captured|resolved` 必須フィールド
  - sync-plan agent が新規 cycle で `none` 初期化
  - cycle-retrospective が `none → captured` (insight あり) または `none → resolved` (no-lesson / extraction failed override) に遷移
- `orchestrate Block 2f`: REVIEW → DISCOVERED → cycle-retrospective → COMMIT の自動順序
- `pre-commit-gate.sh check 4`: retro_status の deterministic 検証
  - `captured` / `resolved` → PASS
  - `none` / 空値 / 不在 / 無効値 → BLOCK
- 新規テスト: `tests/test-frontmatter-retro-status.sh` / `test-cycle-retrospective.sh` / `test-pre-commit-gate-retro.sh` / `test-orchestrate-a2b.sh`

### Changed

- `validate-cycle-frontmatter.sh`: retro_status 値の strict validation + body contamination check (行頭限定)
- `rules/state-ownership.md`: cycle-retrospective 行追加 (retro_status / updated)
- `skills/orchestrate/SKILL.md`: 106 → 97 行に compress + Block 2f 挿入
- `skills/orchestrate/{reference, steps-subagent, steps-teams, steps-codex}.md`: Block 2f + abort handling
- `skills/commit/SKILL.md`: Pre-COMMIT Gate に retro_status check 追記
- `docs/workflow.md` / `docs/architecture.md` / `README.md` / `AGENTS.md` / `CLAUDE.md`: cycle-retrospective 同期
- `skills/spec/templates/cycle.md`: frontmatter に retro_status: none 追加 (placeholder セクションは入れない)

### Breaking (edge case only)

- `pre-commit-gate.sh` が `retro_status` 不在 cycle doc を BLOCK するようになった
  - A1 以降の新規 cycle は sync-plan が自動で `retro_status: none` を初期化、影響なし
  - Archived cycles は phase: DONE で gate skip、影響なし
  - 影響対象: A1 以前の in-progress cycle doc を upgrade 後に commit しようとする場合のみ
  - 対処: frontmatter に `retro_status: none` を手動追加して cycle-retrospective を実行

## [2.6.6] - 2026-03-27

post-approve-gate廃止とorchestrateプロセス強化。

### Changed

- post-approve-gateフラグを廃止し、orchestrate TaskCreateに移行
- orchestrate TaskCreateの7件全登録を必須化

## [2.6.5] - 2026-03-27

Post-Approve Action安全性強化とバグ修正。

### Fixed

- Post-Approve Actionでsync-planを直接呼ばせないルール追加
- risk-classifier.sh の grep -vc 0件時に整数比較エラー修正

## [2.6.4] - 2026-03-26

hook環境変数の修正。

### Fixed

- hookのpwdをCLAUDE_PROJECT_DIRに置換 + set -u除去

## [2.6.3] - 2026-03-24

バックログ整理。

### Removed

- babysit-prをBacklogから削除

## [2.0.2] - 2026-03-15

Codex セッション分離と onboard テンプレート品質強化。

### Added

- Codex session isolation: Cycle ID ベースのセッションバインディング (#55)
- onboard reference.md に TDD Workflow リテラルテンプレート追加（表記ブレ防止）
- onboard reference.md に Codex Integration リテラルテンプレート追加（Auto-orchestrate トリガー行含む）
- CLAUDE.md マージ戦略を最大3セクション（Codex Integration 追加）に更新

### Fixed

- onboard テンプレートの plan-review 記述を Codex 非依存に修正
- Migration セクションに Codex Integration を追加（整合性修正）

## [2.0.1] - 2026-03-15

Codex 統合の整理と委譲スコープの明確化。

### Changed

- P0: sync-plan から Codex Debate を削除。Codex Plan Review は Post-Approve Action に一本化
- P1: commit 後に Review Findings サマリーを表示（指摘内容・修正内容の可視化）
- P2: codex_mode (full/no) は RED/GREEN 委譲のみ制御。Plan Review と Code Review は Codex 利用可能なら常時 competitive に実行
- P2: steps-subagent.md / steps-teams.md の REVIEW に Codex competitive review を追加
- REFACTOR のワーディングを PHILOSOPHY.md に合わせて Claude 主担当に修正
- Post-Approve Action の Codex plan review を codex_mode から分離

### Fixed

- #53: Codex 委譲確認を plan-review 時に実施
- #54: Post-Approve Action の順序修正 (sync-plan → plan-review)

## [2.0.0] - 2026-03-15

Claude + Codex 統合開発フロー。60+ commits since v1.0.0.

### Phase 11: Claude + Codex 統合開発フロー

- 11.1: kickoff → sync-plan 移行（完全置換、エイリアスなし）
- 11.2: Codex 委譲インターフェース（orchestrate に Codex パス追加）
- 11.3: 競争的レビュー（Claude + Codex 並行レビュー、findings 集約）
- 11.5: マイグレーション検証（kickoff 参照 0 件確認）
- 11.6: onboard スキル改善（AGENTS.md/CLAUDE.md テンプレート、symlink/commit ガイダンス）
- 11.7: refactor スキル再構築（/simplify 依存解消、チェックリスト駆動）

### Phase 10: docs-reorganization

- PHILOSOPHY.md 作成（target philosophy 定義）
- ROADMAP.md 作成（Phase 11+ 計画）
- README.md 刷新（Claude + Codex Integration セクション）
- development-plan.md / skills-catalog.md アーカイブ化

### Phase 9: Codex 環境整備

- sync-skills スキル（Codex 用 symlink 生成）
- AGENTS.md / CLAUDE.md 分離
- YAML frontmatter validation (yamllint)

### Phase 8: State Ownership + RED Fast-path

- State ownership rules + frontmatter enrichment
- RED skill complexity-based fast-path
- Auto-kickoff after plan approve
- ADR template and decision records

## [1.0.0] - 2026-03-03

Initial public release. 33 agents, 29 skills, 3 rules, hook-based automation.

### Phase 7: Factory Model Adaptation

- Ambiguity Detection (Questioning Protocol) in init skill
- RED phase 3-stage split: Test Plan, Test Plan Review, Test Code
- 14 validation tests for factory model

### Phase 6: Next Evolution

- CLAUDE.md staleness detection hook
- Onboard template simplification
- Risk Classifier tuning (LOW threshold)
- On-Demand Capabilities research (OSS survey, E2E benchmark)

### Phase 5.5: Orchestrator Redesign

- Plan mode-driven workflow unification
- refactor skill with /simplify delegation
- Phase-compact + /compact natural context compression

### Phase 5: v2 Restructuring

- Unified review skill (quality-gate + plan-review merged)
- Risk Classifier: deterministic reviewer scaling (LOW/WARN/BLOCK)
- review-briefer (haiku) for input token compression
- design-reviewer: integrated design review (scope + architecture + risk)
- strategy skill for project planning phase

### Phase 4: Optimization

- Model selection hints in agent frontmatter
- Hook-based tool output filtering (git log, git diff)
- SKILL.md slim-down + Progressive Disclosure to reference.md

### Phase 3: Designer Agent

- designer.md with Japanese/Western UI/UX comparison
- Integrated into review skill (plan mode)

### Phase 2: phase-compact

- Phase-boundary context compaction skill
- Cycle doc persistence for cross-phase context
- Orchestrate skill integration

### Phase 1.5: Test Infrastructure

- test-plugin-structure.sh, test-agents-structure.sh, test-skills-structure.sh
- SKILL.md size enforcement (< 100 lines)

### Phase 1: Migration

- Consolidated tdd-core, tdd-*, redteam-core, meta-skills into single plugin
- Flat structure: agents/, skills/, rules/, hooks/
- Single plugin.json (marketplace.json removed)
