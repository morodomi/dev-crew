---
feature: designer-plan-review-integration
cycle: 20260216_1500
phase: DONE
created: 2026-02-16 15:00
updated: 2026-02-16 15:00
issue: "#6"
---

# feat: integrate designer with plan-review workflow

## Scope Definition

### In Scope
- [ ] skills/plan-review/SKILL.md: designerを6番目のレビュアーとして追加（条件付き起動）
- [ ] skills/plan-review/reference.md: designer agent の詳細追加
- [ ] skills/plan-review/steps-subagent.md: designer の並行起動追加（条件付き）

### Out of Scope
- designer agent 自体の変更（#5 で完了済み）
- usability-reviewer の変更
- orchestrate skill の変更

### Acceptance Criteria
- [ ] plan-reviewにdesigner連携が組み込まれている
- [ ] UI関連PLANでdesignerレビューが実行される
- [ ] UI非関連PLANではdesignerがスキップされる
- [ ] 構造バリデーションテスト通過（SKILL.md < 100行）

## Environment

- Language: Markdown (plugin definition files)
- Test: bash tests/test-skills-structure.sh

## Context & Dependencies

- Depends on: #1 (structure tests), #5 (designer agent)
- designer agent: agents/designer.md（12パターンのUI/UXガイドライン提案）
- usability-reviewer: REVIEW phaseのユーザビリティ検証（designerとの役割分離済み）

## Risk

- SKILL.md 100行制限: 現在76行 → 条件付きdesigner追加で数行増加、収まる見込み
- usability-reviewerとの重複: designer.mdに Role Boundary が明記済み

## Implementation Notes

### PLAN

#### 設計方針

**1. UI関連判定基準（条件付き起動）**

Cycle doc の Scope Definition から UI/フロントエンド関連を自動判定:

```
UI関連キーワード:
- Component/View/Template/Form/Page 等のファイル
- UI/UX/フロントエンド/デザイン 等の説明文
- React/Vue/Flutter/HTML 等の技術スタック
```

判定ロジック:
1. Cycle doc の Environment セクションから技術スタック確認
2. In Scope の変更ファイルパスから UI コンポーネント検出
3. 説明文に UI/UX 関連キーワードが含まれるか確認
4. 上記いずれか該当 → designer 起動

**2. 5+1 構成の実装方法**

既存の plan-review workflow に designer を条件付きで追加:

```
steps-subagent.md:
- 既存5エージェント（scope, architecture, risk, product, usability）は常に起動
- UI関連判定 TRUE → designer を6番目に並行起動（model: sonnet）
- UI関連判定 FALSE → designer スキップ（5エージェントのみ）

designer の役割: ガイドライン提案のみ（scoring 対象外）
- blocking_score は5 reviewer のみで計算
- designer は UI/UX Design Guidelines を返す（JSON blocking_score なし）
- 統合結果では reviewer スコアとは別セクションにガイドラインを表示
```

**3. SKILL.md 100行制限を守る方法**

現在75行、追加内容は約10-15行の見込み:

```
追加箇所:
- Step 2 に「条件付きでdesigner起動」の1文（2行）
- Step 3 結果統合テーブルに designer 行追加（1行）
- Reference セクションに「designer 詳細は reference.md 参照」（1行）

reference.md に詳細を記載:
- designer agent の役割
- UI関連判定基準の詳細
- usability-reviewer との重複回避
```

**4. 変更ファイル詳細**

| ファイル | 変更内容 | 行数影響 |
|---------|---------|---------|
| SKILL.md | Step 2 に条件付き designer 起動の説明追加 | +3行 |
| SKILL.md | Step 3 結果統合テーブルに designer 行追加 | +1行 |
| SKILL.md | Reference セクションに designer 参照リンク追加 | +1行 |
| reference.md | designer agent セクション追加（詳細情報） | +30行 |
| steps-subagent.md | 6番目に条件付き designer Task() 追加 | +5行 |

合計: SKILL.md 80行（制限内）、reference.md 105行、steps-subagent.md 38行

**5. usability-reviewer との重複回避**

designer.md に Role Boundary が既に定義済み:

```
Designer (PLAN phase):
- 設計方針・パターン選択・UIトークン推奨を提案
- 実装前の設計ガイドライン作成

usability-reviewer (REVIEW phase):
- 実装済みコードのユーザビリティ検証
- WCAG準拠・アクセシビリティチェック
```

PLANフェーズで designer、REVIEWフェーズで usability-reviewer という時間軸分離により重複なし。

**6. Cycle doc へのガイドライン記録**

designer が提案した UI/UX Design Guidelines は Cycle doc の PLAN セクションに記録される:

```markdown
### PLAN

(Architect による設計)

### UI/UX Design Guidelines

(Designer による提案)
- Target Audience: Japanese / Western / Both
- Selected Patterns: P-01, P-02, P-07 等
- Design Tokens: spacing, font-size-base 等
```

この情報を REVIEW フェーズで usability-reviewer が参照し、実装との整合性を確認する。

### Test List

#### TC-01: 構造バリデーション（SKILL.md 100行制限）

**Given**: skills/plan-review/SKILL.md が変更済み
**When**: `bash tests/test-skills-structure.sh` を実行
**Then**: SKILL.md が100行以内で PASS

#### TC-02: 構造バリデーション（全ファイル整合性）

**Given**: plan-review skill の3ファイルが変更済み
**When**: `bash tests/test-skills-structure.sh` を実行
**Then**:
- SKILL.md, reference.md, steps-subagent.md が存在
- frontmatter が valid

#### TC-03: UI関連判定（TRUE: React フロントエンド）

**Given**: Cycle doc Environment に "React" と記載
**When**: plan-review が Cycle doc を読み込み
**Then**: designer が6番目のレビュアーとして起動される

#### TC-04: UI関連判定（TRUE: コンポーネントファイル）

**Given**: In Scope に "src/components/UserForm.tsx" が含まれる
**When**: plan-review が Cycle doc を読み込み
**Then**: designer が6番目のレビュアーとして起動される

#### TC-05: UI関連判定（TRUE: 説明文に UI キーワード）

**Given**: Scope Definition に "UI/UX デザイン改善" と記載
**When**: plan-review が Cycle doc を読み込み
**Then**: designer が6番目のレビュアーとして起動される

#### TC-06: UI関連判定（FALSE: バックエンドのみ）

**Given**: Environment "PHP/Laravel", In Scope "src/Services/AuthService.php"
**When**: plan-review が Cycle doc を読み込み
**Then**: designer がスキップされ、5エージェントのみ起動

#### TC-07: 並行起動（5+1エージェント）

**Given**: UI関連判定 TRUE
**When**: steps-subagent.md の手順を実行
**Then**:
- 5つの reviewer Task() + 1つの designer Task() が並行実行される
- 各 Task に model: "sonnet" が指定されている
- designer に target_audience と ui_scope が渡される

#### TC-08: 結果統合（designer あり）

**Given**: 5エージェントが blocking_score を返し、designer がガイドラインを返す
**When**: Step 3 結果統合を実行
**Then**:
- blocking_score の最大スコアは5 reviewer のみで計算される
- designer のガイドラインは別セクションとして統合結果に含まれる

#### TC-09: 結果統合（designer なし）

**Given**: 5エージェントのみが blocking_score を返す
**When**: Step 3 結果統合を実行
**Then**:
- 最大スコアが正しく計算される
- designer の記載がない

#### TC-10: reference.md に designer セクション追加

**Given**: reference.md が変更済み
**When**: reference.md を読む
**Then**:
- "designer" セクションが存在
- UI関連判定基準が記載されている
- usability-reviewer との役割分離が説明されている

#### TC-11: steps-subagent.md に designer Task 追加

**Given**: steps-subagent.md が変更済み
**When**: steps-subagent.md を読む
**Then**:
- 6番目の Task として designer が記載されている
- 条件付き起動の説明がある
- model: "sonnet" が指定されている

#### TC-12: ガイドライン記録（Cycle doc）

**Given**: designer が UI/UX Design Guidelines を提案
**When**: plan-review が完了
**Then**:
- Cycle doc PLAN セクションに Guidelines が追加される
- Target Audience, Selected Patterns, Design Tokens が記載される

#### TC-13: usability-reviewer との重複回避

**Given**: UI関連 PLAN で plan-review 実行
**When**: designer (PLAN) と usability-reviewer (REVIEW) の出力を比較
**Then**:
- designer: 設計方針・パターン選択の提案
- usability-reviewer: 実装コードのアクセシビリティ検証
- 時間軸（フェーズ）と検証対象が分離されている

### Progress Log

- 2026-02-16 15:00 [INIT] Cycle doc created for #6
- 2026-02-16 15:XX [PLAN] Design completed: 5+1 architecture (conditional designer), UI detection logic, 13 test cases
- 2026-02-16 15:XX [PLAN] plan-review WARN (68): product-reviewer「designer レビュー価値の実証的検証が不足」
- 2026-02-16 15:XX [PLAN] Socrates Protocol: O1(偽陰性)→追記で対処, O2(blocking_score未定義)→**Option C採用**(scoring対象外), O3(命名)→見出し修正
- 2026-02-16 15:XX [PLAN] Human judgment: Option C (designer scoring対象外、ガイドライン提案のみ統合) → proceed
- 2026-02-16 16:XX [RED] Test script created: tests/test-designer-integration.sh (7 test cases, 2 PASS / 9 FAIL)
- 2026-02-16 16:XX [GREEN] Implementation completed: SKILL.md (76行, 100行以内), reference.md (+31行), steps-subagent.md (+10行) → 7 PASS / 0 FAIL
- 2026-02-16 16:XX [REFACTOR] Code quality improvements completed:
  - SKILL.md: 用語統一（5エージェント → 最大6エージェント）、説明の簡潔化
  - reference.md: テーブル整列、blocking_score 計算ロジック明示化
  - steps-subagent.md: 用語統一、構造整理、エラーハンドリング文言改善
  - test-designer-integration.sh: コメント可読性向上
  - 全テスト PASS (designer-integration: 7/7, skills-structure: 5/5, agents-structure: 3/3)
- 2026-02-16 17:XX [REVIEW] quality-gate BLOCK (score 88): correctness-reviewer「結果収集の出力形式不整合(JSON/Markdown混在)、target_audience取得元未定義、並行起動フロー曖昧、TC-03~06テスト未実装」
- 2026-02-16 17:XX [GREEN] Re-execution: 5 issues fix (steps-subagent.md output format, target extraction, execution flow; test coverage +5 cases)
- 2026-02-16 18:XX [REVIEW] quality-gate PASS (score 35): All 6 reviewers PASS (correctness:35, risk:35, performance:15, security:15, architecture:15, guidelines:5)
- 2026-02-16 18:XX [DISCOVERED] #19 起票: designer レビュー価値の実証的検証
- 2026-02-16 18:XX [COMMIT] Cycle complete

### DISCOVERED

- designer レビュー価値の実証的検証（複数サイクル後にUI設計品質への効果を評価） → #19
