---
paths:
  - "**/*.sh"
  - "scripts/**"
  - "skills/**"
---
# Shell Scripts — gate・hook・skill の bash を書くときの規律

gate・hook・skill が呼ぶ bash / jq を書くときの再発防止集。テストを書くときの類似教訓は `rules/test-patterns.md`（paths が `tests/**` のため、実装側では読み込まれない。重複は承知で短く書く）。

## 入力を疑う

- LLM が生成した JSON を扱う jq は、全ての式の最上流で型を確かめてから field access する（`select(type=="object")` 等）。型違いの入力で jq が exit 5 で落ちると、契約行ごと失われ「検証が契約外でクラッシュ」になる。enum 判定に `index()` を使わず `any(.==$s)` にする（配列引数は部分配列検索になる）。1 箇所直したら同一ファイル内の同型の jq 式を全て sweep する (20260903_1130 #2)
- コマンドを検査する hook / gate は、文字列への正規表現でなく shell と同じ規則の引数分解から始める。引用符・global option・複合コマンドで漏れる。検査できなかったときは exit 2 で止める（PreToolUse は exit 2 以外の失敗を通す） (20261004_0030 #1)
- 既存のスキャンを件数や通知に転用するときは、流用元の潜在欠陥も引き継ぐ。コメント行・引用・pipefail 下の巨大入力の fixture を最初の Test List に入れる。`cmd | grep -q` は pipefail 下で SIGPIPE により rc が書き換わるので `grep ... >/dev/null` にして入力を最後まで消費する (20261015_1750 #2。`rules/test-patterns.md` の pipefail 条項と同じ教訓の実装側)
- Markdown の節を行単位で切り出すときは、コードブロック（fence の内側）の `### ` 等を境界にしない。テスト側の「見出し区間を先に抽出する」の実装側 (20261020_0955 #3)

## 環境を外す

- git の出力を読む gate は、設定（external diff・textconv・interHunkContext）だけでなく、出力やパス解決を変える環境変数（`GIT_LITERAL_PATHSPECS`・`GIT_DIFF_OPTS`・`CDPATH`）も入力として扱って外す。`cd` は `CDPATH= cd` にする。「hunk が無い」を「変更が無い」と同一視せず、差分はあるのに行が取れない（`Binary files`）ときは判定できない側（2）に倒す。計算を別スクリプトの呼び出しに替えると、パス解決という入力が増える (20261028_1047 #3、20261104_1025 #3。同じ「環境変数を外す」教訓の再発 2 回のため 1 条にした)
- 改ざんの検出は、相手が書き換えられる設定（git の filter・textconv・exclude・hooks）を通した見え方の上に作らない。入力は実体のバイト列にし、設定そのもの（`.git` の config・exclude・hooks、refs、stash）も入力に含める (20261016_1645 #1)

## 共通化と複製

- 重複を helper へ集約するときは、集約元の各実装が持っていた防御（rc 検査・型ガード・早期 return）の和集合を helper が保持しているかを、同一ファイル内の前例（why コメント付きは特に）と突合する。DRY は振る舞いを 1 箇所に集めることで、防御も振る舞いに含まれる (20260906_1120 #2。集約の完全性は `rules/test-patterns.md` の helper 条項)
- 「既存の gate X と同じ検査」を新しい gate に書くときは、行の選び方（最初か最後か）・文字の種類・空白の扱いまで X のコードから写す。同じ入力を両方の gate に流して答えが一致することをテストにする (20261104_1025 #2)
