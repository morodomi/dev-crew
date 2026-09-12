# Next Steps

最終更新: 2026-09-13

次に何をするかの単一の参照点。着手したら該当項目を `docs/cycles/` の cycle doc へ移し、ここからは削る。

---

## 1. ポートフォリオとしての性格【決定済み 2026-09-11】

**決定**: dev-crew は洗練された成果物ではなく、AI と格闘した記録と、そこから実現した安定運用・思想を示すもの。社長個人のエンジニアとしてのポートフォリオの一部として位置づける。**cycle doc は削らない。**

この repo は公開ポートフォリオ（営業・転職）として維持する方針。資産は cycle doc に残る「AI コーディングの苦悩」— 失敗ペア 307 件、BLOCK 記録 23 件、再実行記録 86 箇所、「再発」の記述 83 箇所 / 27 doc。7 ヶ月の継続がないと貯まらない種類の記録で、再現困難。

**問題は価値ではなく伝わり方。** tracked 72,591 行のうち cycle doc が約 37%。読者が最初に開いた doc が 800 行の process 記録なら、読まれるのは「深さ」ではなく「要約できていない」。

### 決定の内容

主張は「plugin を作った」ではなく「格闘の記録 + そこから実現した安定運用 + 思想」。
cycle doc が差別化要因そのものであり、削減対象ではない。

### やること（次回着手）

README に入口を作る。**削るのではなく navigate させる。** 3〜5 本の case study を選び、各 200 語で:

```
誤った仮説 → どう検出した → root cause → 作った再発防止契約 → 後続 cycle で再発しなかった証拠
```

候補（いずれも上記 5 点が揃っている）:

- `docs/cycles/20260904_1521_test-hooks-hermetic-fixtures.md` — 壁時計依存と実ツリー汚染の根治
- `docs/cycles/20260903_1130_severity-verdict.md` — reviewer の数値自己申告を廃し決定論集計へ
- `docs/cycles/20260908_1715_readme-agents-derived-numbers.md` — 派生数値を doc から撤去し再混入契約へ
- `docs/cycles/20260910_1312_retro-insight-ledger.md` — 再現不能だった集計を機械化。変異注入で oracle の弱さを数値化

失敗記録は、文脈が付いた瞬間に弱点ではなく能力の証明になる。

---

## 2. 履歴側の固有名【保留 2026-09-11】

1 は決定したが、2 の方針（A〜D）は保留。次回以降に回す。

tip からは除去済み（PR #230）。**履歴には残る。**

| 対象 | 規模 |
|---|---|
| 持株会社名 | 24 commit |
| 事業・顧客プロジェクト名 | 各 2〜7 commit |
| 削除した規約 doc（ドメイン + 外部 API 名 + 技術構成、55 行） | 履歴に全文 |
| 個人 Gmail | 382 commit（author email） |
| issue / PR の編集履歴 | 20 版前後。**UI 手作業でのみ削除可、API に mutation なし** |

### 選択肢

- **A. tip のみで受容** — 履歴と編集履歴は残る
- **B. in-place 書き換え（filter-repo + 強制 push）** — GitHub は rewrite 後も旧 commit が PR ref / cached SHA から到達可能と明記。PR diff も広く壊れる。**issue の編集履歴は git では消せない**
- **C. 旧 repo を rename + private 化し、sanitize 済み履歴で新 `dev-crew` を公開** — 汚染された issue / PR ごと private 側へ隔離できる。fork 0 / watcher 0 / star 1 なので移行コストは実質ゼロ
- **D. 受容 + 予防契約のみ** — remediation ではない。A〜C のいずれにも必須の追加策

**現時点の見立て: C が最も強い公開境界。** 1 の決定（cycle doc を資産として全保存）により「履歴は全量を持っていく」が前提になったため、C を採る場合も sanitize 対象は固有名のみで、commit 履歴そのものは維持される。残る論点は「issue / PR を移すか」。

`filter-repo --replace-text` は commit の親子関係・日時・message・diff をすべて維持する（変わるのは SHA）。「sanitize = 失う」ではない。

### 注意

- 個人 Gmail は「消すべき」ではなく「意図して選ぶ」項目。転職・営業用途なら本人と紐づくこと自体が目的でもある
- 強制 push は `.claude/rules/git-safety.md` で禁止。C を採れば不要

---

## 3. 予防契約【着手可 — 1 決定済み】

依存していた 1 が決定したため着手可能。2 の A〜D いずれを採っても、前方向の再混入防止という目的は変わらない。

固有名の再混入を機械的に防ぐ。**禁止語を public な test に直書きすると、その test 自体が新しい漏えいになる。**

設計:

- 一般的な絶対パス regex は public な test に置く
- 固有名の denylist は repo 外（`~/.config/dev-crew/`）から注入し、無ければ skip
- full suite に載せる（本 cycle の V-7 は当該 cycle の Verification でしか走らない）

対応表の現在地: `~/.config/dev-crew/project-labels.tsv`（両 repo の外、権限 600）

---

## 4. 逐次実行の機械化【Cycle A 完了 2026-09-13 / Cycle B・C 残】

`docs/cycles/20260913_0059_runner-admission-snapshot.md` で **Cycle A 完了**。

### 完了したこと（Cycle A）

`run-tests.sh` をこの repo の正規 runner にし、フルスイートも単一テストも同じ入口を通るようにした。

- **admission 3 条件**（テストプロセス数 / load1 / 空きメモリ）。条件単位 fail-open
- **immutable snapshot 上での実行**。manifest 三者照合 `A == B == C` が成立したときだけ実行し、コピー中の変更と ABA を検出する。**これで実行中の live tree 書き換えは構造的に無害になり、事故 1・2 の実害（非再現 FAIL）は根で消えた**
- 起動時の stale snapshot 掃除（age 単独では削除せず PID liveness と起動時刻トークンで判定）
- `rules/agent-prompts.md` に完了通知の意味論を追記

実測: TC 57 件・変異注入 12/12 検出・単一テスト経路 31.5 秒 → 4.89 秒（manifest batch 化。`--no-snapshot` は不採用）。

### 残っていること

| | 内容 | 理由 |
|---|---|---|
| **Cycle B** | hook による inline ループの runner 誘導 + `tests/test-post-approve-gate-removal.sh` TC-07 契約の縮小 | `run-tests.sh` を経由しない inline ループは現状素通りする。TC-07 は「廃止済み `post-approve-gate` の現在形記述」を doc から 0 件に保つ negative 契約であり、その検索語が新 hook の説明文にも一致してしまう（**この行を書いた時点で実際に踏んだ** — 検索語を引用しただけで FAIL した）。**文言回避は oracle gaming なので契約側を旧 `post-approve-gate` 限定へ縮小し、再注入 mutation で検出力を実測する** |
| **Cycle C** | 排他ロック | 二重起動の TOCTOU が残る。ただし owner 公開前 race・reaper の crash recovery・PID 再利用・ABA・signal の子伝播 が必要になり、単一開発者の repo に分散システムの機構を持ち込む形になったため分離した。**必要性が実運用で確かめられてから着手する** |

### 本 cycle で分かったこと（次に効く）

- **規律違反は本 cycle 中にさらに 2 件追加され計 6 件**。5 件目は sync-plan が admission なしでフルスイートを誤起動、**6 件目は PdM 自身**が worker 稼働中に並行してテストを起動した。「自分は分かっているから大丈夫」は成立しない
- 効いた条項と効かなかった条項の差は「**参照する工程が存在するか**」だった。plan 作成・Verification 実行という手を止める工程では過去 doc が実際に設計を変えた。一方「次の agent を起動する」という反射的操作には条項が届かない。**Cycle B・C を残す理由がここにある**

## 5. 台帳を使う後続作業（本 cycle の成果物が入力）

`retro-insight-ledger` で 6 repo / 177 doc / 628 unit の台帳を生成済み（private 側 `docs/metrics/`）。

- **item 2: taxonomy と除外基準の凍結** — polarity の `unknown` 456 件をどう扱うか。最初の論点は既に特定済み: 凍結文法 v2 は SKIP 3 クラスを定義しながら「列挙 1 件とは何か」を定義しておらず、実装が定義した。反証（定義を外すと 2 クラスの件数が動く）つきで cycle doc に記録済み
- **item 3: issue #223 を状態モデルへ書き直し** — `captured → triaged → applied → verified`。誤数値（130 / 382 / 73 件）は撤回済みだが本文は初版の構成のまま

---

## 未着手の DISCOVERED

| issue | 内容 |
|---|---|
| #225 | 漏洩ガードの検査範囲（commit message / PR 本文が未検査、4 クラス宣言に対し 2 クラスのみ検査、vacuity ガードが label 数に紐付かない） |
| #226 | `retro-insight-ledger.sh` の git 分岐（bare repo で無出力終了）と太字 container の非対称 |
| #227 | 既 commit 済みトークンの文脈行で漏洩ガードが false positive を出す |
| #228 | full suite ブロックが FAIL 時に診断情報を残さない |
| #233 | `docs/NEXT.md` が派生数値ガードの対象外 |
| #234 | `tests/` に trap を持たない `mktemp -d` が 10 本以上あり leak する |
| #235 | orchestrate の Block 0 に baseline 実測の指示がない（`plan-discipline.md:23` との乖離） |
| #236 | `20260424_1356` の codify `deferred` が 5 ヶ月未実装。**`deferred` の追跡機構が無いこと自体が論点** |
| #237 | 汎用テンプレート（onboard / spec / evolve）のテストコマンド表記の抽象化 |

その他の backlog は `gh issue list` を参照。
