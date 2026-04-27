# Test Patterns — bash 落とし穴と meta test 設計

テストスクリプト作成時の再発防止パターン集。cycle 20260421_1043 〜 20260422_0937 + cycle 20260422_1146 から抽出した 8 つの insight を具体的な禁止事項と推奨実装としてまとめる。

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
