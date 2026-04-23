# Plan Discipline — plan 作成・実行の規律

plan 作成・承認・実行における規律。実測ベースの計画、逆向き契約の検出、スコープの網羅性を徹底する。

## 禁止事項

- **未確認での Problem 記述**: 実コードを bash 実行せずに plan の Problem を書かない (eval-1 #1)
- **narrative な baseline 記述**: 前 cycle 報告を鵜呑みにせず、必ず自分で実測する (eval-4 #2)
- **逆向きテスト契約の無視**: `grep` が target 存在を要求するテストを見落として文字列を削除しない (eval-4 #1, Cycle B #2)
- **test count sync の範囲外化**: 新 test file 追加時に STATUS.md の Test Scripts 更新を scope に含めない (eval-4 #4)
- **pre-existing FAIL の先送り**: 本 cycle で 1 行 fix 可能か確認せずに DISCOVERED へ先送りしない (eval-2 #4)

## 推奨

- plan 記述前に target script を bash で実行し、実測結果を記録する
- Block 0 で `for f in tests/test-*.sh; ...` を実行し baseline を実測する
- plan 時に `grep -rn "<target_value>" tests/` で逆向き契約を検索する (count/state bump 時必須)
- 新規 test file → STATUS.md の test count 更新を scope checklist に追加する
- pre-existing FAIL 発見時「本 cycle 1 行 fix 可能？」を必ず確認する
- `grep -r "<file>" tests/ skills/commit/` で既存 convention の影響範囲を事前洗い出しする (A2b #5)
- count/status 変更時に `grep -rn "<old-value>" tests/` 実測結果を plan 本文に grep literal として貼付する (自動化 grep literal、cycle 20260422_1313 #1)
- 「rule 参照済」と「rule 適用済」を区別し、plan review checklist で literal 貼付の有無を検証する (cycle 20260422_1313 #1)

## 具体例

```bash
# Block 0: baseline 実測
for f in tests/test-*.sh; do
  bash "$f" >/dev/null 2>&1
  rc=$?
  printf "%s rc=%d\n" "$(basename $f)" "$rc"
done | sort > /tmp/baseline.txt
cat /tmp/baseline.txt

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
