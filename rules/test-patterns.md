---
paths:
  - "tests/**"
---
# Test Patterns — bash 落とし穴と meta test 設計

テストスクリプト作成時の再発防止パターン集。cycle 20260421_1043 〜 20260702_1930 の複数 cycle から抽出した insight を具体的な禁止事項と推奨実装としてまとめる。

## 禁止事項

- **case-insensitive grep**: `grep -i` は skill 名と phase 名を混同させる。固有 prefix との一致には `-E` + word boundary を使う (cycle 20260421_1809 #3)
- **`$(cmd) ... $?` 並置**: コマンド間で `$?` が上書きされ偽の成功報告になる。実行直後に `rc=$?` を取得せよ (cycle 20260422_0937 #3)
- **`bash subject | grep -q` 直接 pipe**: pipefail masking でテスト結果が不正確になる (cycle 20260421_2342 #1)
- **meta test で logic copy-paste**: テスト対象と同じロジックをコピーすると drift する。subject script を直接実行する (cycle 20260421_1043 #2)
- **whole-file grep で frontmatter state**: body 内の同一文字列を誤検出する。awk で frontmatter 範囲限定で parse せよ (cycle 20260422_1146 #1)
- **command substitution 内の `||` fallback**: `$(grep -cF "A" || grep -ciE "B" || true)` は第1 grep が 0 件 (exit 1) でも第2 grep が実行され stdout が連結される (例: `0\n1`)。後続の `[ "$var" -ge 1 ]` で `integer expression expected` エラー。短絡動作と数値取得を混同しない (cycle 20260422_1313 #4)
- **whole-file grep で structured doc の contract assertion**: VERIFY block 等 section 内の
  記述を検査する際、whole-file grep では section 外の unrelated 記述で偽 PASS する
  (cycle 20260424_0900 #2)
- **`grep -E "a\|b"` の escape alternation**: ERE mode では `|` が直接 alternation、
  `\|` はリテラル pipe となり alternation 無効化 (実測 rc=1 で silent no-match)
  (cycle 20260424_1119 #2)
- **単体語で pin**: doc/rule への追記を検査する test で、section 既存項目にも出現し得る単体語を literal にしない。false-pass する (cycle 20260701_1120 #1)
- **section_grep へ ERE メタ文字を含む見出しを渡す**: heading 引数が awk 動的 regex として解釈される実装では、丸括弧・+・. を含むフル見出しが silent no-match（count=0）になる (cycle 20260703_2035 #2)
- **set -e 下の裸 command-substitution 代入の単発修正**: 1 箇所直す時は同ファイル内の全 $(...) 代入を同型 sweep してから閉じる。1 箇所の fix は隣の同型を「次に踏まれる地雷」に変える (cycle 20260706_1216 #2)
- **逆向き契約に相対アンカーを使う**: リリースで指示対象が変わる相対アンカー（first / latest / 先頭セクション）を逆向き契約に使わない。契約対象がリリースで履歴に確定したら immutable な絶対アンカー（確定 version セクション）へ pin し直す。テストが不誠実な記述（「変更なし」を Breaking に書く等の契約駆動 workaround）を強制し始めたら、記述でなく契約の設計を疑う (docs/cycles/20260721_1503_rules-load-trigger-reclassification.md #1)

## 推奨

- `grep` は case-sensitive + word boundary + 固有 prefix で使う (cycle 20260421_1043 #3, cycle 20260421_1809 #3)
- 終了コード取得パターン: `output=$(cmd 2>&1 || true); echo "$output" | grep -q pattern`
- rc 記録パターン: `bash cmd; rc=$?; printf "%s rc=%d\n" "$name" "$rc"` (cycle 20260422_0937 #3)
- meta test は `BASE_DIR` env override で subject script を直接実行する (cycle 20260421_1043 #2)
- fixture-based meta test の他 TC 呼び出しは `|| true` + `2>/dev/null` で defensive 化 (cycle 20260421_1043 #4)
- meta test から既存 test を invoke する場合、recursive runner への skip 登録を plan 段階で設計する (cycle 20260421_1043 #5)
- frontmatter scan: `awk '/^---$/{c++;next} c==1{print}'` で body から分離 (cycle 20260422_1146 #1)
- 条件分岐は `if/elif/else` で明示。数値取得は 1 回のみ: `count=$(grep -cF "pattern" file || true)` (cycle 20260422_1313 #4)
- section-specific grep: `section_grep` helper (tests/test-codify-rule-docs.sh) を再利用。
  structured doc に対しては awk で H2/H3 heading 範囲を抽出 → grep pattern 適用
  (cycle 20260424_0900 #2)
- regex alternation: `grep -E "a|b|c"` (non-escaped、ERE の標準) を使う。mode 決定時は
  `printf` oracle 実測で rc 確認 (例: `printf 'x\nb\n' | grep -E "a|b"; echo rc=$?`)
  (cycle 20260424_1119 #2)
- 追記検査 test は追記内容にのみ現れる「contiguous phrase」を literal に使う (cycle 20260701_1120 #1)
- literal 採用前に `section_grep` で section 内「pre-existing count」= 0 を実測してから確定する (cycle 20260701_1120 #2)
- 「分岐 × 既存チェック」の組み合わせ経路それぞれに「出力文字列 assert」を置く。rc のみでは非ブロッキング WARN の silent skip を検出できない (cycle 20260702_1930 #2)
- 同一セマンティクスを複数実装に要求する時は先に「挙動チェックリスト」（空入力・欠落フィールド・形式混在・異常系）を列挙し各実装に適用する (cycle 20260702_1930 #3)
- 外部コマンド出力を while で消費する時は command substitution で変数に受けて rc を直後検査してからループする。process substitution / pipe 直結は上流失敗を silent skip にする (cycle 20260703_1215 #3)
- section_grep の heading はメタ文字を含まない短縮見出し（前方一致）で渡す。helper 自体は fixed-string 比較（awk index() の prefix 判定）にして ERE 解釈を排除する (cycle 20260703_2035 #2)
- dead code だった検証ロジックを蘇生させる fix は、蘇生した経路の実行時間・副作用・下流の未検証コードを再検査する。「動いていなかったコードが動き出す」は機能追加と同じ検証重量で扱う (cycle 20260706_1216 #2)
- `cmd | grep -q`（早期終了する consumer）を `set -o pipefail` 下で使わない。upstream が SIGPIPE で非ゼロ終了し pipefail が pipeline rc をそれに書き換えるため「match したのに if が false」になる。fix は file/変数に materialize して pipe を消すか `grep ... >/dev/null` にする。`set -e` の if 免除規則は pipefail の rc 書き換えを免除しない（別機構）。small fixture は awk が grep 終了前に出力完了するため SIGPIPE を隠す (docs/cycles/20260709_1125_risk-classifier-doc-diff-fix.md #1)
- 図/フロー/テーブルの構造契約 test は「ノードトークン + 隣接ノードとの位置」で pin する。汎用部分文字列でなく実ノードのトークン（`DONE (cycle`、`│ DONE` 等 diagram の実体）で grep し、隣接ノードとの位置関係（COMMIT ノード < DONE ノード）を確認する。散文の同語（`phase: DONE` 等）が同ファイルにあると部分文字列 grep は偽 PASS する (docs/cycles/20260715_1346_v2.12-docs-alignment.md #1)
- rc を検査したいコマンドは pipe に入れない。pipefail は最右の非ゼロを返し先頭の rc を保証しないため、ガード付き多段 pipe は「先頭コマンド単独実行 + rc 先取り → フィルタ分離」に分解する。エラー経路（rc>=2）の oracle は不在パスでは誘発できない場合があり（grep -r --include は不在 dir で silent rc=1）、`chmod 000` の権限拒否 fixture で誘発する (docs/cycles/20260716_1328_doc-drift-fix.md #1)
- negative sweep（0 件契約）のパターンは、現状の違反例に match するだけでなく「置換後の新文言に不一致（新文言不一致）」を RED 前に `printf` oracle で実測してから採用する。reviewer の提案パターンも無検証で採用しない（指摘が正しくても対案が正しいとは限らない） (docs/cycles/20260716_1328_doc-drift-fix.md #3)
- hash/署名/checksum の同一性保証は、boundary を「行全体一致」等の曖昧性ゼロな規則で先に固定し fixture で pin してから値を記録する（hash boundary fixture pin）。部分文字列 split は本文引用で誤切断する。二次検証は一次と異なる実装（別言語/別ツール）で行い、被検証者の実装を流用しない（false MATCH 防止） (docs/cycles/20260717_1126_approval-reorder.md #1)
- doc 内の code block/フロー図を契約テストする時は「見出し区間を先行抽出 → 区間内 code block を走査」の二段にする。whole-file の fenced block scan は別 section の decoy を拾い、対象が退行しても他 section の正例で偽 PASS する。section_grep の適用範囲を見出し内記述から区間内 code block へ拡張する (docs/cycles/20260717_1605_approval-reorder-cycle2.md #1)
- doc に機械可読契約（集計コマンド・schema regex）を書く時は、実行可能コマンド（そのまま動く変数表記、プレースホルダ非使用）と、実データ形状（転記・fence・空行・decoy）を再現した fixture oracle TC を最初から対で作る。散文契約は「もっともらしいが動かないコマンド」を許す (docs/cycles/20260723_1103_cycle-doc-trailer-and-recall-miss-question.md #1)

- 「テストが全部通る」は契約が守られている証拠ではない。oracle が弱いと言われたら実装に変異を 1 つ入れて実測する。inert stub（全部壊す）を塞いでも「部分的に正しい出力」は素通りする。変異は順序の逆転・値の差し替え・削除して痕跡だけ残す、まで当て、文言 pin は主張にしか現れない連続句にする。新設 TC は修正前の実装で FAIL を実測し、rc だけでなくメッセージも pin して経路を区別する。Codex と Claude の review は互いに見落とした欠陥を出したので、変異注入と別 reviewer を併用する (20260910_1312 #3、20260913_0059 #1、20260916_1634 #3、20261005_1639 #3。いずれも「通るのに守っていない」ため 1 条にまとめた)
- 変異の「未検出」をテストの穴と決める前に、変異が実行される行に入ったかを確かめる。置換元は、コメントや説明文に同じ文字列が無いことを grep で確かめた、コードにしか無い前後の文脈で指定する (20261028_1047 #1)
- negative 契約は両側を同一セッションで測る。(a) 削除対象を戻すと検出する (b) 将来の正当な追記は誤検出しない。誤検出の指摘に応えた修正は検出漏れを、検出漏れの指摘は誤検出を生み、regex を 4 ラウンド作り直した。上の「新文言不一致」条項の残り半分 (20260907_1324 #2)
- helper へ集約したら、その helper を呼ぶべき同型の箇所を grep で数え、全て置き換えてから完了とする（REFACTOR で「集約対象パターンの残存 0 件」を確かめる） (20260907_1324 #4)
- 機械検証されるフィールドのテンプレート例は、検証を通らない空値で書き、説明は fence 外に書く。プレースホルダ文字列は gate の regex に有効値として通る。gate の実 regex で「コピー直後は FAIL、実値で PASS」を実測する (20260724_1450 #2)
- rename 契約（旧キー→新キー）は、新キーが旧キーの部分文字列（`allowed-tools` ⊃ `tools`）でないかを先に確かめ、そうなら語境界で pin する。RED の完了条件に「旧状態の fixture で FAIL」の実測を含める (20260828_1030 #2)
- ディレクトリの総数・集合を契約にする前に、`grep -rn "BASE_DIR.*agents/" tests/` のように実 tree へ書く他のテストを列挙する。fixture 名を除外するか、per-file の内容ベース契約にする (20260828_1030 #3)
- テストが pin する前提は実環境で確かめる。外部 CLI の呼び出し形は、フラグの有無でなく `--help` と最小実行で実測した動く形で pin する（廃止された Codex のフラグを pin したテストが、rc=2 で止まる呼び出しを緑のまま残した）。テスト内だけの除外（参照資料を agents/ から外す等）は、実行環境の規則（Claude Code は agents/*.md を全て agent として登録する）でも成り立つか確かめる (20261003_2200 #1、20261004_0020 #1。「テストの世界の前提が本番とずれる」でまとめた)
- 変化を検出するテストは、同じ fixture の操作の前後で比べる。別々に作った fixture 同士の比較は、時刻や乱数の差で、検出していなくても PASS する (20261016_1645 #4)
- 「起動する文字列に句が入っている」契約は、行でなく起動の引用文字列（`Task(...prompt: "…"`、`codex exec` の prompt）を切り出して検査する。連続空白を 1 つにそろえ、単一引用符も呼び出しとみなす。「危険な権限を渡さない」の pin は、安全な指定の存在でなく危険な綴り（長いフラグ・短いフラグ・`-c` の設定上書き・bypass）を列挙して否定し、変異も綴りごとに入れる (20261028_1047 #2、20261111_1730 #2。切り出してから検査する点が共通のためまとめた)
- 呼び出しの文字列を変えるときは、テスト内の固定文字列だけでなく旧い形に一致する正規表現も探す。「一致した行すべてが X を持つ」型の検査には、一致が 1 行以上あることの assert を添える。一致が減っても FAIL せず黙って弱くなる (20261111_1105 #2)

実装側（gate・hook・skill の bash）の類似教訓は `rules/shell-scripts.md`。

## 具体例

```bash
# BAD: $? が上書きされる
result=$(some_cmd)
do_other_thing
if [ $? -eq 0 ]; then ...  # do_other_thing の rc を見ている

# GOOD: 直後に rc を保存
bash tests/some-test.sh
rc=$?
printf "some-test rc=%d\n" "$rc"
```

```bash
# BAD: pipefail masking
bash subject.sh | grep -q "expected"

# GOOD: 出力を変数で受け取り
output=$(bash subject.sh 2>&1 || true)
echo "$output" | grep -q "expected"
```

## 出典

- `docs/cycles/20260421_1043_test-doc-consistency-tc02-fix.md` Insights 2, 3, 4, 5
- `docs/cycles/20260421_1809_sync-plan-progress-log-format.md` Insight 3
- `docs/cycles/20260421_2342_agents-md-count-fix.md` Insight 1
- `docs/cycles/20260422_0937_advisory-terminology-fix.md` Insight 3
- `docs/cycles/20260422_1146_codify-insight-skill.md` Insight 1
- cycle 20260422_1313 Insight 4 — bash $(cmd1 || cmd2) fallback pitfall
- `docs/cycles/20260701_1120_plan-discipline-green-sweep.md` Insights 1, 2
- `docs/cycles/20260702_1930_gate-active-cycle-fix.md` Insights 2, 3
- `docs/cycles/20260703_1215_test-hardening-rule-codify.md` Insight 3
- cycle 20260703_2035 #2 — section_grep heading の ERE 解釈と fixed-string 化
- cycle 20260706_1216 #2 — 裸 command-substitution 同型 sweep + dead code 蘇生の再検査
- `docs/cycles/20260709_1125_risk-classifier-doc-diff-fix.md #1` — SIGPIPE consumer を pipefail 下で使わない（pipe materialize / grep >/dev/null）
- `docs/cycles/20260715_1346_v2.12-docs-alignment.md #1` — 図契約はノードトークン + 隣接位置で pin
- `docs/cycles/20260716_1328_doc-drift-fix.md #1` — 多段 pipe rc 先取り + 権限拒否 fixture でエラー経路誘発
- `docs/cycles/20260716_1328_doc-drift-fix.md #3` — negative sweep は新文言不一致も oracle 実測
- `docs/cycles/20260717_1126_approval-reorder.md #1` — hash boundary fixture pin + 二次検証の実装独立
- `docs/cycles/20260717_1605_approval-reorder-cycle2.md #1` — doc 内 code block 契約は見出し区間先行抽出
- `docs/cycles/20260721_1503_rules-load-trigger-reclassification.md #1` — 逆向き契約に相対アンカーを使わない + 契約駆動 workaround 検出
- `docs/cycles/20260723_1103_cycle-doc-trailer-and-recall-miss-question.md #1` — 機械可読契約は実行可能コマンド + fixture oracle 対
