# Cycle: onboard スキル調査 (#26)

- Status: DONE
- Issue: #26
- Created: 2026-02-18

## Goal

Zenn記事「how-to-write-a-great-claude-md」を調査し、onboard スキルに取り込むべき改善を特定。
タスク分解して Issue に登録。不要なら理由を明記してリジェクト。

## Context

- 対象記事: https://zenn.dev/farstep/articles/how-to-write-a-great-claude-md
- 既存関連: #24 (AGENTS.md調査) → #30, #31, #32 が派生済み
- 現在の onboard: skills/onboard/SKILL.md (91行), reference.md (139行)

## Scope

- Zenn 記事の調査・分析
- 現在の onboard スキルとの差分特定
- 改善候補の Issue 起票 or リジェクト判断
- skill-maker 使用が指示されている

## PLAN

### 記事の主要知見サマリー

Zenn 記事「how-to-write-a-great-claude-md」の主要論点:

1. **Deletion Test**: 「この行を削除したら Claude が間違うか?」 -- No なら削除候補
2. **500行バジェット**: 全 CLAUDE.md 合計で ~500行以内。超過でコンテキスト全体が低関連扱いリスク
3. **Instruction Budget**: フロンティアモデルは ~200 指示で均一劣化開始。選択的無視ではなく全体の遵守率が低下
4. **Progressive Disclosure (3層)**: L1=CLAUDE.md (毎セッション), L2=rules/docs (タスク関連時), L3=skills/agents (オンデマンド)
5. **書くべきもの/書くべきでないもの**: コードから推測不能なコマンド・規約・ゴッチャのみ。標準規約・プラチュード・リンター代替は不要
6. **推奨構造**: Overview, Code Style, Commands, Architecture, Gotchas の5セクション (~30行の具体例あり)
7. **アンチパターン**: 詰め込み、リンター代替、`/init` 出力そのまま使用、禁止のみ(代替なし)、タスク固有指示のグローバル配置
8. **`.claude/rules/` path targeting**: paths フロントマターでファイルパスに応じた rules を分離
9. **`@` import**: CLAUDE.md から `@docs/xxx.md` で参照 (5階層まで再帰)
10. **Skills 2パターン**: auto-invoke (description のみコスト) vs manual-invoke (disable-model-invocation でゼロコスト)
11. **強調の節約**: IMPORTANT / YOU MUST は少数に限定、乱用で効果薄れる
12. **Feedback Loop**: Claude の誤り -> 修正 -> CLAUDE.md にルール追加 -> git commit
13. **定期レビュー**: `/memory` で数週間ごとに監査、陳腐化指示を削除
14. **Auto Memory 分掌**: CLAUDE.md は「人が与える指示」、Auto Memory は「Claude が取るメモ」

### 差分分析結果

#### A. 既に対応済み (onboard 現行 or #24 派生 Issue)

| 記事の知見 | 対応状況 |
|-----------|---------|
| セクション数上限 | #30 で対応予定 (6セクション以内) |
| Project Structure 条件化 | #30 で対応予定 |
| 検出失敗プレースホルダー | #30 で対応予定 |
| 陳腐化防止 | #31 で対応予定 (pre-commit hook) |
| HTML コメント構造保護 | #32 で検証予定 |
| Progressive Disclosure (3層) | reference.md Step 5 で階層 CLAUDE.md 推奨済み。Step 6 で .claude/rules/ 生成済み |
| 500行バジェット | reference.md Step 5 に「合計500行以内目安」記載済み |

#### B. 未対応 -- 新規改善候補

| # | 記事の知見 | 現状の onboard | Gap |
|---|-----------|---------------|-----|
| B1 | Deletion Test ガイダンス | なし | 生成後に「各行が必要か」を自己チェックする指示がない |
| B2 | Instruction Budget 警告 | なし | 指示数 ~200 上限の概念が onboard テンプレートに反映されていない |
| B3 | 書くべきもの/書くべきでないものの判定基準 | なし | テンプレートが「何を書くか」は示すが「何を書かないか」は示さない |
| B4 | アンチパターン警告 | なし | /init 出力そのまま使用、リンター代替などの警告がない |
| B5 | `@` import 活用推奨 | なし | 階層 CLAUDE.md は推奨するが `@` import の案内がない |
| B6 | Skills auto-invoke vs manual-invoke の案内 | なし | skills を作る際の使い分けガイダンスがない |
| B7 | 強調の節約ルール | なし | IMPORTANT 乱用防止の指針がない |
| B8 | Feedback Loop + 定期レビュー | なし | 生成後のメンテナンスプロセスが案内されていない |
| B9 | Auto Memory 分掌の説明 | なし | CLAUDE.md と Auto Memory の使い分けが説明されていない |
| B10 | path targeting rules | Step 6 で rules/ 作成はするが paths フロントマター未使用 | 汎用 rules のみで path-scoped rules の案内がない |

### 採用/リジェクト判断一覧

| # | 候補 | 判断 | 理由 |
|---|------|------|------|
| B1 | Deletion Test ガイダンス | **ADOPT** | CLAUDE.md 生成後の品質向上に直結。Step 4 末尾に1行追加。コスト極小 |
| B2 | Instruction Budget 警告 | **REJECT** | #30 のセクション数上限 (6以内) + 既存500行バジェットで実質カバー済み。指示数カウントは実装困難で費用対効果低い |
| B3 | 書くべきもの/書くべきでないもの判定基準 | **ADOPT** | テンプレートの「何を埋めるか」だけでなく「何を省くか」のガイドラインは CLAUDE.md 品質に重要。reference.md に判定表として追加 |
| B4 | アンチパターン警告 | **ADOPT (B3 に統合)** | B3 の判定基準表にアンチパターンを含めれば独立項目不要 |
| B5 | `@` import 活用推奨 | **ADOPT** | Step 5 (階層 CLAUDE.md) に自然に追加可能。既存の階層推奨と相補的 |
| B6 | Skills auto/manual-invoke 案内 | **REJECT** | onboard の責務外。skill-maker の責務 |
| B7 | 強調の節約ルール | **ADOPT (B3 に統合)** | 「書くべきでないもの」の一種として B3 判定表に含める |
| B8 | Feedback Loop + 定期レビュー | **ADOPT** | Step 9 の Next Steps に1行追加 + reference.md に詳細。メンテナンスサイクルの案内 |
| B9 | Auto Memory 分掌の説明 | **REJECT** | Auto Memory は Claude Code の標準機能。onboard で説明するのはバジェットの無駄遣い |
| B10 | path targeting rules | **ADOPT** | Step 6 で paths フロントマターの使用例を1つ示すだけでコスト極小 |

### plan-review 修正 (Socrates Protocol 選択肢2)

- B2/B9: リジェクト維持（根拠は健全、reviewer 指摘で覆す理由なし）
- B1: Step 4 末尾に配置維持（意味的配置を優先、行数のための移動はしない）
- 行数対策: SKILL.md Step 1 の bash コード例 (4行) を reference.md に移動して確保
- Discoverability: 各 Step で reference.md へのリンクを明示（ミニチェックリストは不採用）

### 採用項目サマリー (5件)

| ID | 改善内容 | 変更箇所 | 変更規模 |
|----|---------|---------|---------|
| B1 | Deletion Test ガイダンス追加 | SKILL.md Step 4 + reference.md Step 4 | 小 (1-2行) |
| B3+B4+B7 | CLAUDE.md コンテンツ判定基準表 | reference.md Step 4 に新規セクション追加 | 中 (判定表 ~15行) |
| B5 | `@` import 活用推奨 | SKILL.md Step 5 + reference.md Step 5 | 小 (2-3行) |
| B8 | メンテナンスプロセス案内 | SKILL.md Step 9 + reference.md に新規セクション | 小 (3-5行) |
| B10 | path targeting rules 案内 | reference.md Step 6 | 小 (例示 ~5行) |

### 実装計画

**Phase 1: SKILL.md 行数確保**

1. Step 1 の bash コード例 (4行) を reference.md に移動し、SKILL.md では「検出コマンドは [reference.md](reference.md) 参照」に置き換え

**Phase 2: reference.md の拡充** (B3+B4+B7, B5, B8, B10)

1. Step 4 に「CLAUDE.md コンテンツ判定基準」セクション追加（判定表 + アンチパターン + 強調節約ルール）
2. Step 5 に `@` import 説明追加
3. Step 6 に path targeting rules (paths フロントマター) 例示追加
4. 末尾に「メンテナンスガイド」セクション追加 (Feedback Loop + 定期レビュー)

**Phase 3: SKILL.md の微修正** (B1, B5, B8)

1. Step 4 末尾に Deletion Test の1行指示追加 + reference.md リンク
2. Step 5 に `@` import 1行言及 + reference.md リンク
3. Step 9 にメンテナンス案内1行 + reference.md リンク

## Test List

### 構造テスト (自動化可能)

- [ ] TC-01: SKILL.md が 100行以下であること
- [ ] TC-02: reference.md に「コンテンツ判定基準」セクションが存在すること
- [ ] TC-03: reference.md に「書くべきもの」「書くべきでないもの」の両方が記載されていること
- [ ] TC-04: reference.md Step 5 に `@` import の説明が含まれること
- [ ] TC-05: reference.md Step 6 に path targeting (paths フロントマター) の例示が含まれること
- [ ] TC-06: reference.md に「メンテナンス」セクションが存在すること
- [ ] TC-07: SKILL.md Step 4 に Deletion Test の言及があること
- [ ] TC-08: SKILL.md Step 9 にメンテナンス案内が含まれること

### 内容テスト (レビュー確認)

- [ ] TC-09: 判定基準表がアンチパターンを含んでいること (overstuffing, linter substitute, /init as-is, prohibition-only)
- [ ] TC-10: 強調の節約ルール (IMPORTANT 乱用防止) が判定基準に含まれること
- [ ] TC-11: Feedback Loop (誤り -> ルール追加 -> commit) が説明されていること
- [ ] TC-12: 定期レビュー (`/memory` 活用) が説明されていること
- [ ] TC-13: 既存 #30, #31, #32 と重複する変更がないこと

## RED

Test script: `tests/test-onboard-research.sh`

Results (all expected):
- TC-01: PASS - SKILL.md is 90 lines (<= 100)
- TC-02: FAIL - content criteria section not found
- TC-03: FAIL - missing inclusion and/or exclusion criteria
- TC-04: FAIL - @ import explanation not found in Step 5
- TC-05: FAIL - path targeting example not found in Step 6
- TC-06: FAIL - maintenance section not found
- TC-07: FAIL - Deletion Test not mentioned in Step 4
- TC-08: FAIL - maintenance guidance not found in Step 9

Summary: PASS 1 / FAIL 7 / TOTAL 8 -- RED confirmed

## GREEN

### Changes

**SKILL.md (85 lines, was 90)**
- Step 1: bash code block (4 lines) moved to reference.md, replaced with link
- Step 4: Added Deletion Test guidance (1 line) + reference.md link
- Step 5: Added `@docs/xxx.md` import mention (1 line)
- Step 9: Added maintenance guidance (1 line) + reference.md link

**reference.md (176 lines, was 139)**
- Step 1: Added detection commands (moved from SKILL.md)
- Step 4: Added "CLAUDE.md コンテンツ判定基準" section (inclusion/exclusion criteria, anti-patterns table, Deletion Test)
- Step 5: Added "@ import" subsection
- Step 6: Added "path targeting rules" subsection with `paths:` frontmatter example
- End: Added "メンテナンスガイド" section (Feedback Loop + 定期レビュー)

### Test Results

```
PASS: 8 / FAIL: 0 / TOTAL: 8
```

- TC-01: PASS - SKILL.md is 85 lines (<= 100)
- TC-02: PASS - content criteria section found
- TC-03: PASS - both inclusion and exclusion criteria found
- TC-04: PASS - @ import explanation found in Step 5
- TC-05: PASS - path targeting (paths frontmatter) example found in Step 6
- TC-06: PASS - maintenance section found
- TC-07: PASS - Deletion Test mentioned in Step 4
- TC-08: PASS - maintenance guidance found in Step 9

Regression: skills structure tests (TC-08, TC-09, TC-10, TC-11, TC-14) all PASS

## REFACTOR

No changes needed. Review findings:

- **Consistency**: Heading levels correct throughout (## steps, ### subsections, #### sub-items)
- **Clarity**: New sections (コンテンツ判定基準, メンテナンスガイド, @ import, path targeting) integrate naturally
- **No duplication**: SKILL.md summarizes + links; reference.md has details. No content overlap
- **Progressive Disclosure**: SKILL.md at 85 lines with appropriate reference.md links
- **No #30/#31/#32 overlap**: Confirmed new content addresses only B1/B3+B4+B7/B5/B8/B10
- **No trailing whitespace or formatting issues**

Tests: 8/8 (onboard-research) + 5/5 (skills-structure) all PASS

## REVIEW

quality-gate WARN (75)。Socrates Protocol 選択肢2 (critical 既存問題の難易度確認 + 軽微修正) を採用。

- correctness: 75 (WARN) - Step 6 .claude/ パス曖昧 (既存), @ import エラーハンドリング不足
- performance: 75 (WARN) - reference.md リンク重複, 判定基準の常時ロード
- security: 35 (PASS)
- guidelines: 62 (WARN) - AI Behavior Principles コードブロック外 (既存), "プラチュード" 誤字
- product: 72 (WARN) - Deletion Test 具体例不足, B6/B9 再検討提案
- usability: 72 (WARN) - Step 4 密度, 判定基準の discoverability

対応:
- "プラチュード" → "platitude: 陳腐な決まり文句" に修正 (新規行の問題)
- critical 既存問題 2件: 設計判断が必要 → DISCOVERED 起票
- テスト: 8/8 PASS + 5/5 PASS (regression なし)

## DISCOVERED

1. reference.md L68-88: AI Behavior Principles テンプレートがコードブロック外で document 構造を壊している (既存問題、設計判断が必要)
2. reference.md L138: Step 6 "core の .claude/" の参照先が曖昧 (既存問題、onboard 動作仕様の明確化が必要)
3. Deletion Test に具体例がない (B1 の改善余地。例: "Use clean code principles" → 削除 / "Run migrations before seeding" → 保持)
4. @ import と階層 CLAUDE.md の使い分け decision tree がない (B5 の改善余地)
