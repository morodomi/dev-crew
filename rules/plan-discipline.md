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
- **test count sync の範囲外化**: 新 test file 追加時に STATUS.md の Test Scripts 更新を scope に含めない (cycle 20260422_0937 #4)
- **pre-existing FAIL の先送り**: 本 cycle で 1 行 fix 可能か確認せずに DISCOVERED へ先送りしない (cycle 20260421_1809 #4)
- **baseline 実測の除外理由不明記**: `grep -c ... rules/*.md` 等で「N 件 (除外)」と書く際、
  除外 category (例示 / historical reference / etc) と除外根拠 (どの rule に基づくか) を
  本文に明記しないと、Codex plan review で必ず BLOCK される (cycle 20260424_1119 #1)
- **否定形前提の未検証記述**: 「X が未定義/存在しない」という plan 前提は、定義があるべき場所（skill/rule/steps/reference）の全 grep 結果を根拠として plan に貼付し、「なぜ現状が壊れているか」の発生機序を 1 件実測特定してから書く。機序未診断の対策は症状への回避策になる (cycle 20260706_1020 #1)

## 推奨

- plan 記述前に target script を bash で実行し、実測結果を記録する
- Block 0 で `for f in tests/test-*.sh; ...` を実行し baseline を実測する
- plan 時に `grep -rn "<target_value>" tests/` で逆向き契約を検索する (count/state bump 時必須)
- 新規 test file → STATUS.md の test count 更新を scope checklist に追加する
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

## 具体例

```bash
# Block 0: baseline 実測（immutable snapshot 複製上で実行し、evidence は隔離 path に保存）
SNAP=$(mktemp -d)
cp -R . "$SNAP"
(
  cd "$SNAP"
  for f in tests/test-*.sh; do
    bash "$f" >/dev/null 2>&1
    rc=$?
    printf "%s rc=%d\n" "$(basename "$f")" "$rc"
  done | sort
) > "$SCRATCH/baseline.txt"
cat "$SCRATCH/baseline.txt"

# 逆向き契約検索: STATUS.md の Test Scripts カウント変更前に
grep -rn "107\|Test Scripts" tests/ skills/commit/
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
