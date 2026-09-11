# Next Steps

最終更新: 2026-09-11

次に何をするかの単一の参照点。着手したら該当項目を `docs/cycles/` の cycle doc へ移し、ここからは削る。

---

## 1. ポートフォリオとしての性格を決める（他の判断の前提）

**これが決まらないと 2 と 3 の設計が確定しない。**

この repo は公開ポートフォリオ（営業・転職）として維持する方針。資産は cycle doc に残る「AI コーディングの苦悩」— 失敗ペア 307 件、BLOCK 記録 23 件、再実行記録 86 箇所、「再発」の記述 83 箇所 / 27 doc。7 ヶ月の継続がないと貯まらない種類の記録で、再現困難。

**問題は価値ではなく伝わり方。** tracked 72,591 行のうち cycle doc が約 37%。読者が最初に開いた doc が 800 行の process 記録なら、読まれるのは「深さ」ではなく「要約できていない」。

### 決めること

- ポートフォリオの主張は「plugin を作った」か「再現可能な engineering system を運用してきた証拠がある」か
  - 後者なら cycle doc が差別化要因そのもの。削れない
  - 前者なら 118 本は不要

### やること（後者を採る場合）

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

## 2. 履歴側の固有名（1 の決定に依存）

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

**現時点の見立て: C が最も強い公開境界。** ただし 1 が決まってからでないと「履歴をどこまで持っていくか」「issue を移すか」が決まらない。

`filter-repo --replace-text` は commit の親子関係・日時・message・diff をすべて維持する（変わるのは SHA）。「sanitize = 失う」ではない。

### 注意

- 個人 Gmail は「消すべき」ではなく「意図して選ぶ」項目。転職・営業用途なら本人と紐づくこと自体が目的でもある
- 強制 push は `.claude/rules/git-safety.md` で禁止。C を採れば不要

---

## 3. 予防契約（1 の決定と独立に着手可）

固有名の再混入を機械的に防ぐ。**禁止語を public な test に直書きすると、その test 自体が新しい漏えいになる。**

設計:

- 一般的な絶対パス regex は public な test に置く
- 固有名の denylist は repo 外（`~/.config/dev-crew/`）から注入し、無ければ skip
- full suite に載せる（本 cycle の V-7 は当該 cycle の Verification でしか走らない）

対応表の現在地: `~/.config/dev-crew/project-labels.tsv`（両 repo の外、権限 600）

---

## 4. 逐次実行の判定条件を機械化する

**根拠は十分。本 cycle で規律に 4 回抵触し、うち 2 回で実害が出た。**

| # | 事象 | 実害 |
|---|---|---|
| 1 | architect が full suite と他を並行実行 | `test-doc-consistency.sh` の非再現 FAIL（D-06） |
| 2 | 完了通知を見て次を起動したが通知元に child が残存 | full suite と green-worker が並走 |
| 3 | REVIEW 中に外部 reviewer と検算を並行 | なし |
| 4 | load 38 の状態で full suite を起動 | **OOM kill + snapshot 26MB 残留**（trap が発火せず） |

**診断**: 逐次化の判定を「自分の管理下のプロセス」だけで定義したのが狭すぎた。`pgrep -f 'tests/test-'` は 4 で 0 を返している。

### やること

- 起動前チェックを 3 条件へ: テストプロセス 0 / load < 閾値 / 空きメモリ > 閾値
- snapshot の後始末を kill 耐性にする（trap は SIGKILL で発火しない。起動時に古い snapshot を掃除する形が確実）
- 完了通知の意味論を明記（"no live background children of its own" であって「完全終了」ではない）

2-strike rule を超えている。条項の追加ではなく機械化の段階。

---

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

その他の backlog は `gh issue list` を参照。
