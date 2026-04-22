# Multi-File Consistency — 並行実装と deterministic gate の一貫性

同一 workflow を複数ファイルで並行実装する際の一貫性保証と、deterministic gate の防御設計。

## 禁止事項

- **grep 存在 check のみで順序検証しない**: 同一 workflow を N ファイルで実装する際に「文字列が存在するか」だけ確認し、「A → B の順序」を検証しない (v2.8-orchestrate-integration Insight 3)
- **gate の部分委任**: deterministic gate が他 validator に依存して単独で full validation しない設計は避ける (v2.8-orchestrate-integration Insight 4)

## 推奨

- N ファイル並行実装では「section A が section B より前に出現するか」を行番号比較でテスト契約化する
- deterministic gate は case 文で期待値を enumerate し、それ以外の値は明示的に reject する
- gate script は単体で `bash gate.sh <input>` として全検証を完了できる設計にする

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
