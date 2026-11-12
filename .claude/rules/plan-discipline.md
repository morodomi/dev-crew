---
paths:
  - "docs/cycles/**"
---
# Plan Discipline — plan 作成・実行の規律

plan 作成・承認・実行における規律。実測ベースの計画、逆向き契約の検出、スコープの網羅性を徹底する。

## 禁止事項

- **未確認での Problem 記述**: 実コードを bash 実行せずに plan の Problem を書かない (cycle 20260421_1043 #1)
- **narrative な baseline 記述**: 前 cycle 報告を鵜呑みにせず、必ず自分で実測する (cycle 20260422_0937 #2)
- **逆向きテスト契約の無視**: `grep` が target 存在を要求するテストを見落として文字列を削除しない (cycle 20260422_0937 #1, cycle 20260422_1146 #2)
- **pre-existing FAIL の先送り**: 本 cycle で 1 行 fix 可能か確認せずに DISCOVERED へ先送りしない (cycle 20260421_1809 #4)
- **baseline 実測の除外理由不明記**: `grep -c ... rules/*.md` 等で「N 件 (除外)」と書く際、
  除外 category (例示 / historical reference / etc) と除外根拠 (どの rule に基づくか) を
  本文に明記しないと、Codex plan review で必ず BLOCK される (cycle 20260424_1119 #1)
- **否定形前提の未検証記述**: 「X が未定義/存在しない」という plan 前提は、定義があるべき場所（skill/rule/steps/reference）の全 grep 結果を根拠として plan に貼付し、「なぜ現状が壊れているか」の発生機序を 1 件実測特定してから書く。機序未診断の対策は症状への回避策になる (cycle 20260706_1020 #1)

## 推奨

- plan 記述前に target script を bash で実行し、実測結果を記録する
- Block 0 で、AGENTS.md の Quick Commands（dev-crew 本体では Quick Start）にあるテストコマンドを実行し baseline を実測する。repo に正規 runner があればそれを使い、独自の direct loop を書かない（dev-crew 本体では `bash run-tests.sh`）
- plan 時に `grep -rn "<target_value>" tests/` で逆向き契約を検索する (count/state bump 時必須)
- pre-existing FAIL 発見時「本 cycle 1 行 fix 可能？」を必ず確認する
- `grep -r "<file>" tests/ skills/commit/` で既存 convention の影響範囲を事前洗い出しする (cycle 20260420_1752 #5)
- count/status 変更時に `grep -rn "<old-value>" tests/` 実測結果を plan 本文に grep literal として貼付する (自動化 grep literal、cycle 20260422_1313 #1)
- 「rule 参照済」と「rule 適用済」を区別し、plan review checklist で literal 貼付の有無を検証する (cycle 20260422_1313 #1)
- 新 rule / concept 導入時は `grep -rlF '<既存概念>' skills/` で影響範囲 sweep を
  scope に含める。orchestrate の SKILL.md + steps-subagent/teams/codex.md のような
  DRY 違反の複数 doc 記述を検出 (cycle 20260424_0900 #3)
- baseline 実測の数値は「含める数 + 除外する数 + 除外 category + 除外根拠 rule 参照」
  の要素を本文に明記する。単一の "N 件" だけでは plan review で不明瞭扱い
  (cycle 20260424_1119 #1)
- count/status 変更 cycle の GREEN 検証は curated 非回帰リストでなく `grep -rln "<old-value>" tests/` の逆向き契約 sweep 結果を全て実行する。curated リストは検証範囲を恣意的に狭め、test 内に hardcode された逆向き契約（count assertion 等）を見逃す (cycle 20260625_1101 #1、cycle 20260525_1249 #1 が予告)
- baseline は「immutable snapshot 複製」上で実測し、evidence ファイルを「並行プロセスから隔離」した path に保存する (cycle 20260702_1200 #1)。live tree での baseline は並行 agent に破壊・汚染される
- 指示・rule 文書で 2 回防げなかった規約違反は 3 回目を待たず自動契約に昇格する（2-strike rule、cycle 20260703_1215 #2）
- 隔離 snapshot baseline は複製前に repo 外依存を洗い（例: grep -rln '\.\./\.\.' tests/）、依存する親構造ごと複製する。N 件同時 FAIL は単一根本原因の nested cascade をまず疑い、第一仮説は棄却実験を経てから採用する (cycle 20260706_1216 #1)
- 「省略/デフォルトで上位（executor/親）を継承する」という継承デフォルト前提は、フレームワークの解決順を一次ソース（公式 doc）で確認してから plan に書く。model/config/env の継承は直感と逆のことが多い。否定形前提禁止の姉妹版で、肯定形の継承前提も未検証なら書かない (docs/cycles/20260709_1313_reviewer-model-policy-v1.md #1)
- 識別子の連番次値（TC 番号・count・連番の「次の値」）を plan に書く前に、`grep -n "TC-1[0-9]"` 等で当該ファイルの実装から最大値を実測する。ヘッダ・目次・一覧コメントは実装から drift する前提で扱い、採番の根拠にしない (docs/cycles/20260716_1328_doc-drift-fix.md #2)
- 逆向き契約の grep は plan 時だけで終えない。doc を変更する cycle は「変更する doc」と「その doc を参照する test」を plan で同時に列挙し、旧 doc の内容語で `grep -rn "<keyword>" tests/` する。契約で pin された文字列は REVIEW の accept-apply・REFACTOR で編集する前にも grep する（テスト自身を編集する cycle は他テストの pin 対象になりやすい）。doc 版と適用時点の拡張を 1 条にまとめた (20260423_1045 #2、20260904_1521 #2)
- plan 内の実測ベースの主張には「どの式・どの契約版で測ったか」を併記する。レビューで式が変わったら、その式で検証済みだった主張を再実測してから残す（残した主張は契約変更で黙って失効する） (20260723_1328 #1)
- capability を剥奪する判断を人間に再承認させる前に、「残る機能」と「消える機能」の 2 列を両方実測する。「書けない」だけの実測は「機能が死ぬ」の証明にならない（memory 削除→復元の往復が実害） (20260828_1030 #1)
- frontmatter のキーを足すときは、harness の agent 一覧表示（Tools 欄）で反映を確認する。表示が変わらなければキーは無視されている（skill 用 `allowed-tools` が agent で 7 か月無効だった） (20260828_1030 #4)
- 並行実行した検証ジョブの出力は、起動時刻と最終編集時刻を突合してから読む。出力に測定対象の世代（timestamp + 対象文字列の実測）を埋め込ませる (20260904_1521 #3)
- plan 内の主張を修正したら、その主張の別表現を plan 全体で grep してから閉じる（数値限定の条項は方針・設計判断の記述に及ばない。Design だけ直して Baseline・Verification に旧方針が残る型） (20260906_1120 #1)
- 決定論 gate が読む書式（正準 hash・enum・grep 契約）を新設・変更したら、記録の前に gate と同じコマンドを実際に走らせる。verdict の markdown 太字などは走らせて初めて見つかった (20260908_1715 #1)
- 契約・TC を書いたら、(a) 最も安易に満たす方法（文字列を別所へ移すだけ等）で通らないか、(b) 修正前の実装で実際に FAIL するかを実測する。レビュアーが示した発現機序も自環境で成立するとは限らない（macOS の裸 `mktemp` は `$TMPDIR` より `_CS_DARWIN_USER_TEMP_DIR` を優先し、Linux 前提の機序では TC が vacuous になった）。同じ「検出力を測る」教訓のためまとめた (20260908_1715 #2、20260913_0059 #5)
- 「何を守るか」を決める前に、それが今どれだけ露出しているかを実測する。秘匿できないもの（既に tracked 42 ファイルにある `$HOME` のユーザ名）を禁止語に入れても、守れず既存契約と衝突するだけになる (20260910_1312 #2)
- rule を Recall に引用したら、この cycle で何がその rule の対象かを 1 行で書く。条項の適用範囲を狭く読む失敗（測定器だけを baseline と読み、被測定物の入力 repo を外した）は、条項を増やしても防げない (20260910_1312 #4)
- 「X が遅い」「X が壊れる」を受けたら、内訳を測るまで対策を設計しない（延べ 458 回の再実行が原因で、コピーは 2.04 秒だった）。検出の仕組みを選ぶときは、issue の要約文でなく実測した失敗例の生の記録（diff・テスト・報告）に当て、その例を検出できるか確かめる。「測ってから対策を作る」の拡張としてまとめた (20260916_1634 #1、20261020_0955 #1)
- 承認を挟む保護手順を plan に書くときは、各承認ステップの「拒否・一部承認」の経路を列挙し、その経路で守りたいものが失われないか確かめる。正常系だけの契約テストでは見えない (20261005_1639 #2)
- ExitPlanMode の前に、Plan Review Record の項目を spec reference.md の様式と 1 行ずつ突き合わせる。承認後に不足に気付いたら、plan ではなく Cycle doc に書く (20261016_1645 #2)
- 止める基準を plan に書くときは、数える対象（新しい TC か、既存テストのファイルか、変更ファイルか）と数える時点を名指しする (20261016_1645 #3)
- 直す範囲・消す範囲を洗い出すときは、置き場所や設定の名前（`scripts/`・消す機能の設定キー）でなく、実際の形（`bash ` の直後の相対パス、使う sandbox の呼び出し）で探し、名前を持たない consumer（配布用テンプレート等）を拾う。同じ教訓の再発 2 回を 1 条にまとめた (20261111_1105 #1、20261111_1730 #1)

## 具体例

dev-crew 本体の例（導入先では、AGENTS.md の Quick Commands にあるテストコマンドに読み替える）。

```bash
# Block 0: baseline 実測。run-tests.sh が admission check（プロセス数判定
# のみ）+ 境界チェック付きコピー（source tree 外への immutable snapshot
# 複製）+ 起動時の残骸警告（削除はしない）を内包する正規 runner であり、
# 独自の snapshot loop をここに書かない（cycle 20260913_0059、
# cycle 20260916_1634）。
bash run-tests.sh > "$SCRATCH/baseline.txt" 2>&1
cat "$SCRATCH/baseline.txt"
```

## 出典

- `docs/cycles/20260420_1752_v2.8-orchestrate-integration.md` Insight 5
- `docs/cycles/20260421_1043_test-doc-consistency-tc02-fix.md` Insight 1
- `docs/cycles/20260421_1809_sync-plan-progress-log-format.md` Insight 4
- `docs/cycles/20260422_0937_advisory-terminology-fix.md` Insights 1, 2, 4
- `docs/cycles/20260422_1146_codify-insight-skill.md` Insight 2
- cycle 20260422_1313 Insight 1 — 自動化なき規律は破綻する
- cycle 20260625_1101 #1 — count/status 変更の GREEN 検証は逆向き契約 sweep で全実行（curated リストは hardcode contract を見逃す。実 regression 事例）
- cycle 20260702_1200 #1 — baseline snapshot 隔離
- cycle 20260703_1215 #2 — 2-strike rule（指示文書での繰り返し違反の自動契約化）
- cycle 20260706_1020 #1 — 否定形 plan 前提の全 grep 貼付 + 発生機序実測
- cycle 20260706_1216 #1 — 隔離 snapshot の親構造複製 + 単一根本原因 cascade + 棄却実験
- `docs/cycles/20260709_1313_reviewer-model-policy-v1.md #1` — 継承デフォルト前提は公式 doc の解決順で確認
- `docs/cycles/20260716_1328_doc-drift-fix.md #2` — 連番次値は実装 grep で実測（ヘッダは drift 前提）
- `docs/cycles/20260913_0059_runner-admission-snapshot.md` / `docs/cycles/20260916_1634_shrink-runner-remove-nesting.md` — baseline snapshot loop を `run-tests.sh`（admission[プロセス数判定] + 境界チェック付きコピー + 起動時の残骸警告を内包する正規 runner。三点照合・owner metadata・reaper・load/memory admission は cycle 20260916_1634 で削除済み）呼び出しへ集約
