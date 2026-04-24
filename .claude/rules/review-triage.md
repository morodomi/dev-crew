# Review Triage — review findings の Risk-based 処理

review findings をリスクスコアに応じてスケールし、3 カテゴリでトリアージする規律。

## Risk-based Reviewer Scaling

review のコストはリスクスコアに比例させる (cycle 20260421_2342 #3 + cycle 20260422_1146 #6):

| Score | Tier | Reviewer |
|-------|------|----------|
| 0–30  | LOW  | Codex + correctness + security (3 views)。trivial 案件 (1 file / 1 line / Codex approve 一発) では Claude correctness 省略可 |
| 30–60 | MED  | LOW + maintainability |
| 60+   | HIGH | MED + architectural / design-reviewer 候補 |

**根拠**: cycle 20260421_2342 #3 は「Risk LOW + Codex approve 一発 → correctness skip 可」の運用評価。cycle 20260422_1146 #6 は Score 115 (HIGH) の dogfood で「LOW: 2 views + Codex」「MEDIUM: +maintainability」「HIGH: +architectural」を明文化。両者は重複せず階段状に厚くする指針。

## Findings 3-Category Triage

review findings は以下の 3 カテゴリに分類して処理する (cycle 20260422_0937 #5):

| Category | 定義 | アクション |
|----------|------|-----------|
| accept-apply | scope 内 invariant 強化 (2-3 行 fix で可能) | 即適用。review log に記録 |
| accept-defer | architectural / scope 越え | DISCOVERED に記録 + follow-up cycle |
| reject | 根拠なし / 方針違反 | 根拠付きで reject。review log に理由を記載 |

## 禁止事項

- accept/reject の理由を残さずに findings を処理しない
- リスクスコアに関わらず全 findings に同一レベルの review コストをかけない

## 推奨

- review 開始前にリスクスコアを算出し、tier を決定する
- 全 findings を 3-category に分類してから適用順を決める
- reject した findings は「なぜ reject か」を 1 行で review log に記録する

## 出典

- `docs/cycles/20260421_2342_agents-md-count-fix.md` Insight 3 (trivial scope で Claude correctness skip)
- `docs/cycles/20260422_0937_advisory-terminology-fix.md` Insight 5 (3-category findings triage)
- `docs/cycles/20260422_1146_codify-insight-skill.md` Insight 6 (Risk-based reviewer scaling の階層定義、HIGH 実測例)
