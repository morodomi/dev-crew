# ADR-004: テスト実行をどこまで隔離するか（test-isolation-boundary）

## Status: accepted

## Context

`docs/cycles/20260913_0059_runner-admission-snapshot.md`（以下 `20260913_0059`）は「テストが遅い」を所与として受け入れ、遅さの原因を測らずに起動前チェック 3 条件・指紋の三点照合・PID/所有者追跡・reaper を積み上げた（35 行の要求が 1068 行の実装になった）。同じレビュアーに「釣り合っているか」を問い直すと過剰と判定され、しかも自分が過去に必須と判定した機構自体が過剰だと返ってきた。指摘は 1 件ずつ見れば全部正しく、全部に応えた結果として肥大した。

`docs/cycles/20260916_1634_shrink-runner-remove-nesting.md`（以下 `20260916_1634`）は、削る前にまず測った。

**遅さの真因**: `tests/test-doc-consistency.sh` の TC-13 と `tests/test-factory-model-adaptation.sh` の TC-14 が、それぞれ「全テストを nested 実行する」だけの meta test で、`run-tests.sh` と役割が重複していた。延べ実行回数は **458 回**（117 + 115 + 113 + 113）。この入れ子を除去すると **117 回**になる。

**速度への効果の内訳（実測、誤差解釈に注意）**:

| 段階 | フルスイート | 延べ実行回数 |
|---|---|---|
| 変更前 | 約 11 分（推定）/ 実測 13〜17 分 | 458 |
| A のみ適用（入れ子除去、`run-tests.sh` 本体は旧版のまま） | **154.82 秒** | 117 |
| A + B 適用（`run-tests.sh` 縮小: 1,068 行 → 479 行） | **148.96 秒** | 117 |

**A（入れ子除去）だけで 154.82 秒に到達しており、B（run-tests.sh の縮小）による追加短縮は約 4%（誤差に近い）。速度改善のほぼ全部が A の効果であり、B は速度にほとんど寄与していない。B の目的は複雑さ・保守負債の削減であって速度ではないことが数値で確定した。** 三点照合・再試行・load/memory 判定は「発火しない限りコストがほぼゼロ」な分岐だったため、削除の効果は速度でなく複雑さに出た。

**メモリ admission は「測れないものを測っているつもりでいた」**: `run-tests.sh` の起動前チェックは空きメモリを `free + inactive` の合算で判定していたが、これは実態を表していない。

| | 値 |
|---|---|
| `run-tests.sh` の報告（`free + inactive`） | 6,198 MB |
| 実際にすぐ使える量（`vm_stat` の `Pages free`） | 75 MB |

80 倍以上の過大評価だった。macOS の `inactive` は「いつでも捨てられるキャッシュ」で理屈の上では再利用できるが、すぐには空かない。設計時「圧縮済みメモリ（compressor）は即座に解放されないから足さない」と判断していたにもかかわらず、同じ理屈が当てはまる `inactive` は足していた。実害も出た。このチェックが「6.7GB 空いています、どうぞ」と答えた直後に、ジョブがメモリ不足で 2 回停止した。

## Decision Scorecard

| 項目 | 評価 | 理由 |
|------|------|------|
| Requirements Fit | A | 実測で遅さの真因（入れ子重複）を特定し解消。`20260916_1634` の複雑さ予算 6 項目（新しい永続状態・lifecycle・設定形式・exit code・OS 固有依存・並行性/所有権/時刻の扱い）が全て 0 を維持したまま完了 |
| Security | B | 影響範囲は repo 内のみで外部露出なし。ただし「コピーして実行」の残す判断は混成 snapshot を意図的に受容しており、下記 Consequences で明記が必須 |
| Operability | B | 残骸の自動削除を廃止したため、強制終了後は人間が手動で確認・削除する運用に変わる。ただし起動時の警告（3 行）で可視化はされる |
| Complexity | A | `run-tests.sh` は 1,068 行 → 479 行。削除した機構は全て「発火時のみコストが乗る」種類で、常時の複雑さのみが減った |
| Testability | B | 31 TC 削除・26 TC 維持・新設 2 TC・変更 3 TC で契約を再確定。ただし `DEV_CREW_RUNNER_LIB_ONLY`（TC-45）削除に伴い、pgrep 自己・祖先除外の対向 oracle（TC-04/TC-04b）も道連れで失われた |

## Arguments

### Accepted

- **入れ子除去（本丸）**: `test-doc-consistency.sh` TC-13 と `test-factory-model-adaptation.sh` TC-14（いずれも「全テストを nested 実行するだけ」の meta test）を削除し、正規入口を `run-tests.sh` 一本化する
- **コピーして実行は残す**: 実行中の live tree 書き換えによる非再現 FAIL を防ぐ。コスト実測約 2 秒
- **指紋の三点照合・再試行プロトコルは削る**: そもそも原子的コピーは保証していなかった。指紋計算自体がファイルを順に読むため、計算中に編集が入れば指紋自体が混成の観測になる。2 回でも 3 回でも「ある瞬間のきれいなコピー」は証明できない
- **source tree 境界チェックは残す（最小化）**: `TMPDIR` が repo 配下を指す場合、snapshot を source tree 内に作ってしまい `cp -Rp "$BASE_DIR"` が snapshot を再帰的に含む事故が起きる。ここだけは削れない
- **PID・起動時刻・所有者・reaper は削る**: 通常終了時の cleanup（`trap` による EXIT/TERM/INT/HUP）は残し、強制終了後の残骸は自動削除せず起動時に警告するだけに留める
- **admission: load 判定は削る**: 防いだ実績が無く、通常時ベンチマークでは効果を検証できなかった。これに伴い `.claude/test-serialization.json`・`jq` による設定処理・`.gitignore` の negation 例外もまとめて削除する
- **admission: memory 判定は削る**: 測れていないことが実測で確定した（`free + inactive` が実態を 80 倍過大評価し、直後に実害としてジョブが 2 回停止した）
- **admission: テストプロセス数判定は残す**: 多重起動の抑止として唯一実効性を確認できた条件
- **exit code を 0/1/2/3 へ縮小**: `0`=全通過 / `1`=実行したテストの FAIL のみ（流用禁止）/ `2`=runner が開始不能（admission 拒否・snapshot 作成失敗・コピー失敗を統合）/ `3`=引数拒否。`4`/`5` は廃止。signal 終了（TERM=143/INT=130/HUP=129）は別枠のまま変更しない
- **実行後の live tree 変化 advisory は削る**: snapshot を採った後の話であり、結果の正しさに関与しないノイズ
- **`DEV_CREW_RUNNER_LIB_ONLY`（source-as-library）は削る**: テスト容易性のために production の状態空間を増やしていた。env 変数だけで runner を bypass できる欠陥でもあった
- **テスト用 hook（`DEV_CREW_TEST_HOOK_*`）は全削除する**: F2（明示 target が snapshot に無いと成功扱いになる欠陥、PR #241 で修正済み）はコピーを続ける限り必要だが、その唯一の決定論的検証（TC-48）が hook 依存だった。方針は承認前に決め切った：fixture 側で `cp` を shim する案（案 a）を採用し、hook を 1 つ残す案（案 b）は不採用とした。production にテスト都合の経路を残さない
- **pgrep の自己・祖先除外は実装のみ残す**: Linux 向け defense-in-depth として実装は残すが、macOS では実 `pgrep` が OS 既定で自己・祖先を除外するため契約としては vacuous
- **排他ロックは不採用**: 二重起動が潰すのは「時間と負荷の無駄」だけで、実害（実行中の tree 書き換えによる非再現 FAIL、OOM）はコピーの導入だけで既に消えている。必要性が実測されるまで保留する

### Rejected

- **APFS clone（`cp -c`）**: 0.82 秒と 2.04 秒の差は、削除後の約 148.96 秒に対して実質的でない。一方で `cp` の OS 実装差と fallback という新しい OS 固有意味論を持ち込み、自ら宣言した複雑さ予算（OS 固有依存 0）と矛盾する
- **起動時 scan を「削って無通知」にする案**: macOS の `TMPDIR` 自動掃除は当てにならない（実測: 2024-10 の残骸が 11 ヶ月残存、257 件）。scan 自体は残し、警告は最小限に留める。**走査対象は生の `$TMPDIR` ではなく、境界判定後の実際の snapshot root**（`TMPDIR` が repo 配下を指して `/tmp` へ fallback した場合も同じ root を見るため、残骸を見逃さない）
- **age（経過時間）単独での残骸自動削除**: 13〜17 分は実測値であって上限ではない。停止・ハング・スリープ中の実行を誤って消し得る

### Deferred

- **排他ロック**: 必要性が実測されるまで不採用のまま。二重起動の TOCTOU は残余リスクとして明示的に残す
- **hook による inline ループの誘導（`docs/NEXT.md` item 4 参照）**: `rules/plan-discipline.md` の推奨行を direct loop から `bash run-tests.sh` へ変更する対応は本 cycle で完了したが、それを機械的に強制する hook 化は別 plan とする

## Decision

`run-tests.sh` は「起動前チェック（テストプロセス数のみ）→ source tree 境界チェック付きコピー（単発、指紋照合・再試行なし）→ コピー上での実行 → 通常終了/signal 時の cleanup」に縮小する。指紋の三点照合・PID/所有者追跡・reaper・load/memory admission・実行後 advisory・source-as-library・テスト用 hook は全て削除する。排他ロックは採らない。exit code は 0/1/2/3 の 4 値（signal は別枠）に統合する。テストスイートの入れ子重複（`test-doc-consistency.sh` TC-13 / `test-factory-model-adaptation.sh` TC-14）は削除し、正規入口を `run-tests.sh` に一本化する。

## Consequences

**受容する失敗**（`docs/cycles/20260916_1634_shrink-runner-remove-nesting.md` B-2 参照）:

1. **混成 snapshot**: コピー中に live tree の編集が入ると、どの revision にも一致しない混成 snapshot の上でテストが走り得る
2. **実行中の混読は防ぐ**（なお守られる保証）: コピー完了後のテストは frozen な snapshot を読むため、実行中の live tree 編集との混読は防ぐ。これが「コピーして実行」を残した本来の目的
3. **残骸は自動削除しない**: 強制終了後の残骸は自動削除せず、起動時に対象パスを警告するだけに留める。ディスクを消費し続け得る
4. **全スイートの保証は `run-tests.sh` 実行時のみ**: TC-13/TC-14 削除により、「`test-doc-consistency.sh` や `test-factory-model-adaptation.sh` を個別に実行しただけで、その時点の全スイートが通ることも分かる」という暗黙の保証が失われる。正規入口を `run-tests.sh` に一本化する以上これは受容できるが、技術的に強制されてはいない
5. **自己・祖先除外は検証手段を失う**: `DEV_CREW_RUNNER_LIB_ONLY`（TC-45）削除に伴い、対向 oracle だった TC-04/TC-04b も削除した。pgrep 自己・祖先除外の実装自体は Linux 向け defense-in-depth として残るが、契約テストでは守られない
6. **`pgrep` probe 利用不可時は admission を fail-open で skip する**: `eval_pgrep()` はプローブ不在（`pgrep` が PATH 上にない）・`rc >= 2`（プローブ自体の実行エラー）・`rc == 0` で空出力・`rc == 0` で非数値出力の 4 状況全てで「テストプロセス数」条件を BLOCK ではなく SKIP とし、stderr に理由を出して実行を継続する。多重起動の抑止という admission の目的上、プローブが壊れている／存在しない環境では検出できないまま通す（安全側に倒すなら BLOCK もあり得たが、プローブ障害だけで正規の実行が止まる方が実害が大きいと判断し fail-open を選んだ）。本 mini-iteration（REVIEW A2）で `tests/test-run-tests-runner.sh` TC-51 として 3 経路（probe absent / non-numeric output / rc=0 空出力。probe absent と汎用 rc>=2 は同一分岐のため 1 TC で束ねて検証）を初めて pin した

**その他の帰結**:

- `run-tests.sh` は 1,068 行 → 479 行（差分 +366 / −1,703、net −1,337 行）。ただし「net negative」は行数で判定しない。判定は `20260916_1634` が宣言した複雑さ予算 6 項目（新しい永続状態・lifecycle/cleanup protocol・設定形式・exit code・OS 固有意味論・並行性/所有権/時刻の扱い）が全て 0 であることで行った
- 削った機構（三点照合・load/memory admission）の大半は「発火しない限りコストがほぼゼロ」な分岐だったため、速度改善のほぼ全部は A（入れ子除去）に由来する。**縮小を速度目的で評価しないこと**。B の価値は保守負債の削減（timeout 調整・skip リスト拡張・flaky FAIL 調査という反応的な保守コストの継続的発生を止めたこと）にある
- メモリ admission の失敗は「機構が足りなかった」ではなく「測定方法自体が実態を表していなかった」ことが原因だった。今後 admission 条件を追加する際は、該当 OS 指標が実測とどれだけ乖離するかを事前に確認してから採用する
- 排他ロック・hook 誘導は Deferred のまま。次に効く条件は「必要性が実測されたとき」であり、時間経過や指摘の再発だけでは採用しない
