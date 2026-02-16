---
feature: japanese-ux-research
cycle: 20260216_0000
phase: PLAN
created: 2026-02-16 00:00
updated: 2026-02-16 00:10
issue: "#4"
---

# research: Japanese vs Western UI/UX design patterns

## Scope Definition

### In Scope
- [ ] docs/research/japanese-ux-patterns.md: 日本 vs 西洋 UI/UX の差分調査
- [ ] 10+ 具体的差分リスト（各項目に UI 実装例）
- [ ] Designer Agent プロンプト設計に使える形式
- [ ] テストで研究ドキュメントの構造バリデーション
- [ ] 各パターンに具体的コード差分/UIコンポーネント差分を含むこと（質的基準）

### Out of Scope
- Designer Agent 本体の実装 (#5)
- plan-review への統合 (#6)
- 実際の CSS/コンポーネント実装
- skill-maker によるスキル作成（#4 COMMIT 後に別サイクル）

### Files to Change (target: 10 or less)
- docs/research/japanese-ux-patterns.md (new)
- tests/test-japanese-ux-research.sh (new)

## Environment

### Scope
- Layer: Markdown (research document) + Shell (test)
- Plugin: dev-crew
- Risk: LOW (ドキュメント追加のみ、既存コード変更なし)

### Runtime
- Node: v22.17.0
- Python: 3.13.3
- OS: Darwin 25.2.0

### Dependencies (key packages)
- Claude Code Plugin system
- Web search for research

## Context & Dependencies

### Reference Documents
- Issue #4: research: Japanese vs Western UI/UX design patterns
- Issue #5: feat: designer agent with Japanese design principles (依存先)
- Issue #6: feat: integrate designer with plan-review workflow (依存先)

### Dependent Features
- None (this is a P0 prerequisite)

### Related Issues/PRs
- #5, #6 depend on this research output

## Implementation Notes

### Research Areas (from Issue #4)
1. 情報密度の違い（高密度 vs ミニマリズム）
2. タイポグラフィ（日本語フォント、行間、文字サイズ）
3. カラーパレット（日本の Web サイトで好まれる色調）
4. ナビゲーションパターン（メガメニュー、パンくず等）
5. フォームデザイン（ふりがな、郵便番号自動入力等）
6. モバイルファーストの日本的アプローチ
7. マイクロインタラクション（控えめ vs 派手）
8. 信頼性表現（バッジ、認証マーク、運営者情報）

### Acceptance Criteria
- [ ] 西洋との具体的な差分が 10 項目以上リスト化
- [ ] 各差分に UI 実装での具体例
- [ ] Designer Agent のプロンプト設計に使える形式
- [ ] 各パターンに具体的コード差分/UIコンポーネント差分を1つ以上含むこと
- [ ] 各パターンに Design Token レベルの方向性を含むこと (例: "spacing: compact vs relaxed"、具体値は不要)

## Document Structure Design

### `docs/research/japanese-ux-patterns.md` 構成

```
# Japanese vs Western UI/UX Design Patterns
## Overview (研究目的、スコープ、Designer Agent での活用方法)
## Categories
### 1. Visual Design (視覚デザイン)
  #### P-01: Information Density (情報密度)
  #### P-02: Typography (タイポグラフィ)
  #### P-03: Color Palette (カラーパレット)
  #### P-04: Visual Hierarchy (視覚的階層)
### 2. Information Architecture (情報設計)
  #### P-05: Navigation Patterns (ナビゲーション)
  #### P-06: Content Strategy (コンテンツ戦略)
  #### P-07: Form Design (フォームデザイン)
### 3. Interaction Design (インタラクションデザイン)
  #### P-08: Microinteractions (マイクロインタラクション)
  #### P-09: Mobile-First Approach (モバイルファースト)
### 4. Trust & Credibility (信頼性)
  #### P-10: Trust Signals (信頼性表現)
  #### P-11: Social Proof (ソーシャルプルーフ)
  #### P-12: Compliance Display (法令遵守表示)
## Designer Agent Prompt Reference (プロンプト用構造化データ)
## Sources (参考文献)
```

### 各パターン項目の統一フォーマット

```markdown
#### P-XX: Pattern Name (日本語名)

| Aspect | Japanese Pattern | Western Pattern |
|--------|-----------------|-----------------|
| 概要   | ...             | ...             |

**Japanese Approach:**
- 具体的な特徴 (箇条書き)

**Western Approach:**
- 具体的な特徴 (箇条書き)

**Implementation Guidelines:**
- Designer Agent が使う具体的な実装指針
- CSS/HTML の具体例やフレームワーク推奨

**Examples:**
- 日本: サイト名/スクリーンショット説明
- 西洋: サイト名/スクリーンショット説明
```

### Designer Agent Prompt Reference セクション

最終セクションに JSON-like 構造化データを配置。
Designer Agent のプロンプトから直接参照・引用可能な形式。

```markdown
## Designer Agent Prompt Reference

<!-- 以下は Designer Agent が参照する構造化データ -->

### Decision Matrix

| Pattern ID | Category | JP Priority | Western Priority | Key Difference |
|-----------|----------|-------------|-----------------|----------------|
| P-01 | visual | high-density | minimal | ... |
| ...  | ...    | ...         | ...     | ... |

### Quick Reference (per pattern)
- P-01: "Japanese users expect X; Western users expect Y. Default to Z."
- ...
```

## Test List

### TODO
- TC-30: japanese-ux-patterns.md ファイル存在チェック
- TC-31: 必須セクション存在チェック (Overview, Categories, Designer Agent Prompt Reference, Sources)
- TC-32: パターン項目数が 10 以上 (P-01 ~ P-10+)
- TC-33: 各パターンに統一フォーマット (Japanese Pattern, Western Pattern, Implementation Guidelines)
- TC-34: Designer Agent Prompt Reference セクションに Decision Matrix テーブル存在
- TC-35: Sources セクションに参考文献 5 件以上
- TC-36: 4 カテゴリ全て存在 (Visual Design, Information Architecture, Interaction Design, Trust & Credibility)
- TC-37: 各パターンに Examples セクション存在
- TC-38: [Negative] 空の japanese-ux-patterns.md で TC-32 が失敗すること

### WIP
(none)

### DISCOVERED
(none)

### DONE
(none)

## Progress Log

### Phase: REVIEW - Completed at 00:50
**Artifacts**: quality-gate results (6 reviewers)
**Decisions**: Correctness BLOCK 82 → Socrates Protocol → proceed (metrics fix + modern baseline note)
**Metrics**: max_score=82, pass=5, block=1
**Next Phase Input**: COMMIT

### 2026-02-16 00:50 - REVIEW (quality-gate)
- 6 reviewer 並行レビュー: Correctness 82, Performance 35, Security 15, Guidelines 18, Risk 5, Architecture 25
- 最大スコア: 82/100 (Correctness) → BLOCK
- Socrates Protocol: 条件付き proceed (Cycle doc metrics 修正 + P-02 modern baseline 注記)
- 修正 2 点適用: line_count 600+→466, バグ数 4→3, P-02 に modern 16px 注記追加
- DISCOVERED: なし
- 次: COMMIT フェーズへ進行

### Phase: REFACTOR - Completed at 00:45
**Artifacts**: docs/research/japanese-ux-patterns.md (refactored), tests/test-japanese-ux-research.sh (refactored)
**Decisions**: refactoring=DRY + constants + Given/When/Then + content consistency fixes
**Metrics**: line_count=2, file_count=2, test_count=9
**Next Phase Input**: source files on disk, run quality gate

### 2026-02-16 00:45 - REFACTOR (refactorer)
- テストスクリプト: 定数化 (MIN_PATTERN_COUNT, MIN_SOURCE_COUNT, GREP_CONTEXT), DRY (check_all_present helper), Given/When/Then コメント追加
- 研究ドキュメント: P-02 font-size-base 修正 (JP=16px min / Western=14px min), Decision Matrix P-01 閾値追加, Sources 書式統一
- 見送り: TC-33/TC-37 統合 (可読性低下), Sources URL 追加 (推測リスク)
- 9/9 テスト PASS + 95/95 全テスト PASS (regression なし)
- 次: REVIEW フェーズへ進行

### Phase: GREEN - Completed at 00:40
**Artifacts**: docs/research/japanese-ux-patterns.md (new), tests/test-japanese-ux-research.sh (bug fix)
**Decisions**: 12 patterns with unified format, 10 sources, test bugs fixed (macOS BSD compatibility)
**Metrics**: line_count=466, file_count=2, test_count=9
**Next Phase Input**: source files on disk, refactor for quality

### 2026-02-16 00:40 - GREEN (green-worker)
- docs/research/japanese-ux-patterns.md 作成 (12 patterns, 4 categories)
- テストバグ修正 3 件 (macOS BSD sed/grep 互換性: grep -qA 抑制、sed BRE \+ / \s 非対応)
- 9/9 テスト PASS + 110/110 全テスト PASS (regression なし)
- 次: REFACTOR フェーズへ進行

### Phase: RED - Completed at 00:30
**Artifacts**: tests/test-japanese-ux-research.sh (new)
**Decisions**: 9 test cases (TC-30~TC-38), all failing as expected
**Next Phase Input**: test file on disk, implement research document to make them pass
**Metrics**: line_count=150, file_count=1, test_count=9

### 2026-02-16 00:30 - RED (red-worker)
- tests/test-japanese-ux-research.sh 作成 (TC-30~TC-38)
- RED 状態確認: TC-30 FAIL (ファイル未存在で early exit)
- 空ファイルでの確認: 2 PASS / 7 FAIL (TC-30 + TC-38 pass)
- 次: GREEN フェーズへ進行

### Phase: PLAN - Completed at 00:20
**Artifacts**: Cycle doc updated with PLAN section, Test List (TC-30~TC-38)
**Decisions**: architecture=4 categories/12 patterns, Socrates=Option A (skill-maker 分離)
**Next Phase Input**: Test List items TC-30 ~ TC-38
**Metrics**: line_count=0 (new files), file_count=2, test_count=9

### 2026-02-16 00:20 - Socrates Protocol (plan-review WARN 72)
- Usability Reviewer WARN (72) に対して Socrates Protocol 発動
- Socrates 指摘:
  1. skill-maker は明確なスコープクリープ → #4 から分離 (採用)
  2. AC に質的基準が不足 → 各パターンに具体的コード差分/UI差分を追加 (採用)
  3. #6 は #4 に依存しない → 依存グラフ修正 (採用)
- ユーザー判断: Option A (skill-maker 分離、#4 は research のみ)
- Cycle doc 更新: In Scope から skill-maker 除外、Out of Scope に追加、AC に質的基準追加
- Socrates 追加反論: Implementation Guidelines に Design Token 方向性が必須 (CSS具体値は不要)
- PdM 受理: AC に Design Token レベルの方向性を追加

### 2026-02-16 00:15 - plan-review
- 5 reviewer 並行レビュー (4/5 成功、Product reviewer エラー)
- Scope: 15, Architecture: 45, Risk: 25, Usability: 72
- 最大スコア: 72/100 (Usability Reviewer)
- 判定: WARN
- 主な指摘: Decision Matrix 条件不足、Implementation Guidelines 抽象的、拡張性なし

### 2026-02-16 00:10 - PLAN (architect)
- ドキュメント構造設計完了: 4 カテゴリ、12 パターン項目 (P-01 ~ P-12)
- カテゴリ: Visual Design (4), Information Architecture (3), Interaction Design (2), Trust & Credibility (3)
- 統一フォーマット: Japanese/Western 比較テーブル + Implementation Guidelines + Examples
- Designer Agent Prompt Reference: Decision Matrix テーブル + Quick Reference
- Test List: TC-30 ~ TC-38 (9 テストケース、うち 1 negative)
- Web 調査から得た知見:
  - 情報密度: 日本はホリスティック注意、西洋はフォーカス型
  - タイポグラフィ: 漢字の複雑さが視覚階層手法を制約 (色/枠線で代用)
  - カラー: 明るいトーン優勢、ダーク避ける傾向
  - フォーム: ふりがな、郵便番号 (7 桁) → 住所自動補完、姓→名順
  - 信頼性: セキュリティバッジ、運営者情報、法令遵守表示を重視

### 2026-02-16 00:00 - INIT
- Cycle doc created
- Issue #4, P0, phase-3
- 対象: research doc (new) + test (new)
- Risk: LOW (ドキュメント追加のみ)
- skill-maker によるスキル作成も実施予定
