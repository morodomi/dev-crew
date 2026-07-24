---
paths:
  - "docs/cycles/**"
---
# Multi-File Consistency — 並行実装と deterministic gate の一貫性

同一 workflow を複数ファイルで並行実装する際の一貫性保証と、deterministic gate の防御設計。

## 禁止事項

- **grep 存在 check のみで順序検証しない**: 同一 workflow を N ファイルで実装する際に「文字列が存在するか」だけ確認し、「A → B の順序」を検証しない (v2.8-orchestrate-integration Insight 3)
- **gate の部分委任**: deterministic gate が他 validator に依存して単独で full validation しない設計は避ける (v2.8-orchestrate-integration Insight 4)

## 推奨

- N ファイル並行実装では「section A が section B より前に出現するか」を行番号比較でテスト契約化する
- deterministic gate は case 文で期待値を enumerate し、それ以外の値は明示的に reject する
- gate script は単体で `bash gate.sh <input>` として全検証を完了できる設計にする
- パス引数の enumerate-and-reject は値の形式だけでなく位置 —「信頼するディレクトリ境界」— も列挙対象にする (cycle 20260702_1930 #1)
- multi-mode skill（SKILL.md + steps-*.md）への動作変更は、変更点を全モード doc に対する契約テストで pin する（TC-14a/b/c 型が template）。rule 文書による注意喚起は 2 度破られた — 契約テスト化が唯一の恒久防御 (cycle 20260706_1020 #2)
- A→B の順序反転では、B の定義に残る「B が A を呼ぶ」旧記述を grep で洗い、negative assert（旧呼び出しの不在）で pin する。positive assert（新記述の存在）だけでは旧記述と共存し二重実行する。順序変更は「新記述の追加」でなく「旧記述の除去 + 新記述」の対で完了する (docs/cycles/20260717_1126_approval-reorder.md #3)

## 具体例

```bash
# 順序検証: line_A < line_B を assert
line_a=$(grep -n "section-A" file.md | head -1 | cut -d: -f1)
line_b=$(grep -n "section-B" file.md | head -1 | cut -d: -f1)
[ "$line_a" -lt "$line_b" ] || fail "section-A must precede section-B"

# deterministic gate: expected values のみ通す
case "$phase" in
  RED|GREEN|REFACTOR|REVIEW|COMMIT) : ok ;;
  *) echo "ERROR: unexpected phase '$phase'" >&2; exit 1 ;;
esac
```

## 出典

- `docs/cycles/20260420_1752_v2.8-orchestrate-integration.md` Insights 3, 4
- cycle 20260702_1930 #1
- cycle 20260706_1020 #2 — multi-mode skill の全モード契約テスト pin
- `docs/cycles/20260717_1126_approval-reorder.md #3` — 順序反転は旧 caller 記述の negative assert で pin
