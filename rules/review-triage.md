---
paths:
  - "docs/cycles/**"
---
# Review Triage — review findings の Risk-based 処理

review findings をリスクスコアに応じてスケールし、3 カテゴリでトリアージする規律。

## Risk-based Reviewer Scaling

review のコストはリスクスコアに比例させる (cycle 20260421_2342 #3 + cycle 20260422_1146 #6):

| Score | Tier | Reviewer |
|-------|------|----------|
| 0–30  | LOW  | Codex + correctness + security (3 views)。security+correctness は floor として trivial (1 file / 1 line / Codex approve 一発) でも常時必須（省略しない） |
| 30–60 | MED  | LOW + maintainability |
| 60+   | HIGH | MED + architectural / design-reviewer 候補 |

**根拠**: cycle 20260421_2342 #3 は「Risk LOW + Codex approve 一発 → correctness skip 可」の運用評価だったが、cycle 20260709_1313（reviewer-model-policy-v1）で security+correctness を NON-NEGOTIABLE floor として維持する方針に改め、trivial 案件の省略対象を maintainability に限定した。cycle 20260422_1146 #6 は Score 115 (HIGH) の dogfood で「LOW: 2 views + Codex」「MEDIUM: +maintainability」「HIGH: +architectural」を明文化。両者は重複せず階段状に厚くする指針。

**モデル tier との合成**: 上記の risk tier（LOW/MED/HIGH、reviewer 起動数の制御）と `review_policy`（reviewer_model/escalate_high_to、reviewer が走るモデルの制御）は直交する別軸。HIGH tier では `review_policy.escalate_high_to` が設定されていればそのモデルへエスカレーションする。詳細: `skills/review/reference.md` の review_policy 解決規則。

## Findings 3-Category Triage

review findings は以下の 3 カテゴリに分類して処理する (cycle 20260422_0937 #5):

| Category | 定義 | アクション |
|----------|------|-----------|
| accept-apply | scope 内 invariant 強化 (2-3 行 fix で可能) | 即適用。review log に記録 |
| accept-defer | architectural / scope 越え | DISCOVERED に記録 + follow-up cycle |
| reject | 根拠なし / 方針違反 | 根拠付きで reject。review log に理由を記載 |

## Severity → Verdict 集計（SSOT: skills/review/severity-verdict.sh）

3-category triage 後、accepted（accept-apply + accept-defer、reject は除外）の findings を severity（critical/important/optional）で集計し、`skills/review/severity-verdict.sh verdict <triage.json> [--invalid <name>]...` が決定論的に verdict を判定する（`--invalid` は Step 4.4 で確定した INVALID reviewer を再実行時も含め全呼び出しで引き継ぐ）（docs/cycles/20260903_1130_severity-verdict.md）:

- critical ≥ 1 件 → BLOCK
- important ≥ 1 件（critical 0 件） → WARN
- いずれもなし → PASS
- reject カテゴリの findings は severity に関わらず集計から除外する
- **fail-closed 差別化**: reviewer の JSON 出力が検証（retry 1 回後もなお）不正な場合、`security-reviewer` / `correctness-reviewer` は NON-NEGOTIABLE floor として BLOCK、それ以外の reviewer は WARN floor（欠損を PASS に落とさない）

## Dependencies & Degradation

`skills/review/severity-verdict.sh` は jq に依存する（`validate`/`verdict` の両サブコマンドとも）。

- **jq 必須**: JSON パース・型検証・severity/category 集計は全て jq 式で行う。macOS は `brew install jq`、Debian/Ubuntu 系は `apt-get install jq` でインストールできる
- **DEGRADED 挙動**: jq が PATH 上に見つからない場合、`validate`/`verdict` とも `DEGRADED: jq not found` を出力し exit 0 で返す（fail-open）。この場合 PdM は script による決定論検証をスキップし、Severity 基準表（`skills/review/reference.md` 参照）を手動適用して `severity-verdict.sh` と同一フォーマットの verdict 行を Progress Log に記録する
- **NON-NEGOTIABLE floor は jq 非依存**: `--invalid security-reviewer`/`correctness-reviewer` による BLOCK 固定は jq の有無に関わらず必ず stdout に反映される（DEGRADED 注記が出る場合も stderr のみ）。fail-closed の保証を jq の可用性に依存させない設計

## JSON Validation & Retry Protocol

reviewer JSON 出力の検証と再試行は以下の決定論的手順に従う（SSOT: `skills/review/severity-verdict.sh`、詳細手順は `skills/review/steps-subagent.md` Step 4.4）:

1. `severity-verdict.sh validate <dir>` で全 reviewer JSON を検証する
2. **INVALID を返した場合のみ**、該当 reviewer へ script の error 行を verbatim で含めて re-request する（**最大 1 回**。LLM の主観による re-request は行わない）
3. 再 validate してもなお INVALID の場合、その reviewer 名を `--invalid <name>` として `severity-verdict.sh verdict` に渡す（fail-closed）
4. `--invalid` に `security-reviewer`/`correctness-reviewer` が含まれれば verdict は BLOCK 固定、それ以外の reviewer は WARN floor
5. 3-category triage 後の accepted findings（reject 除外）は `verdict` の集計対象。**reject に分類された finding は severity に関わらず verdict に一切効かない**（例: severity=critical でも reject なら他に accepted な critical/important が無い限り verdict は PASS）

## 禁止事項

- accept/reject の理由を残さずに findings を処理しない
- リスクスコアに関わらず全 findings に同一レベルの review コストをかけない

## 推奨

- review 開始前にリスクスコアを算出し、tier を決定する
- 全 findings を 3-category に分類してから適用順を決める
- reject した findings は「なぜ reject か」を 1 行で review log に記録する
- competitive review で reviewer 間の判定割れが起きたら、多数決や権威でなく「機構レベルの分解 + 実測 oracle」で決着させる。bash の rc 伝播（pipefail / set -e / SIGPIPE / command substitution）は reviewer ごとに mental model が違うため、実際に踏ませる fixture を作って観測する (docs/cycles/20260709_1125_risk-classifier-doc-diff-fix.md #2)
- tier テーブル置換（分類テーブル/リストへの項目置換投入）は、置換先の行/tier にその項目が実在するかを構造と突合してから書く。「A を B に置換」は A と B が同じ文脈（同じ tier/行/scope）に属する時のみ意味を持ち、異なる tier の項目を持ち込むと省略対象不在・二重定義等の構造矛盾を生む (docs/cycles/20260709_1313_reviewer-model-policy-v1.md #2)

## 出典

- `docs/cycles/20260421_2342_agents-md-count-fix.md` Insight 3 (trivial scope で Claude correctness skip)
- `docs/cycles/20260422_0937_advisory-terminology-fix.md` Insight 5 (3-category findings triage)
- `docs/cycles/20260422_1146_codify-insight-skill.md` Insight 6 (Risk-based reviewer scaling の階層定義、HIGH 実測例)
- `docs/cycles/20260709_1125_risk-classifier-doc-diff-fix.md #2` — 判定割れは機構分解 + 実測 oracle で決着
- `docs/cycles/20260709_1313_reviewer-model-policy-v1.md #2` — tier テーブル置換は実在の構造突合
