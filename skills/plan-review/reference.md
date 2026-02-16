# Plan Review - Reference

SKILL.mdの詳細情報。必要時のみ参照。

## エージェント詳細

### scope-reviewer

スコープ妥当性を検証:
- 変更範囲の明確さ
- ファイル数10個以下
- 依存関係の考慮

### architecture-reviewer

設計整合性を検証:
- 既存設計との一貫性
- デザインパターンの適切な使用
- レイヤー構造と責務分離

### risk-reviewer

リスクを評価:
- 既存機能への影響
- 後方互換性
- ロールバック可能性

### designer（条件付き起動）

UI関連PLANの場合にのみ起動するガイドライン提案エージェント。blocking_score の対象外。

#### UI関連判定基準

以下のいずれかに該当する場合、UI関連と判定:

1. Environment セクションに UI 技術スタック記載（React, Vue, Flutter, HTML, Next.js, Nuxt.js, Angular, Svelte 等）
2. In Scope に UIコンポーネントファイルパス（components/, views/, templates/, pages/, layouts/ 等）
3. 説明文に UI/UX キーワード（UI, UX, フロントエンド, デザイン, ユーザーインターフェース 等）

偽陰性パターン（見落としやすいUI関連ファイル）:
- theme.ts / tokens.ts 等のデザイントークン定義
- CSS-in-JS 設定ファイル（styled-components, emotion）
- Tailwind config / Storybook 定義
- .css / .scss / .less ファイル

#### designer への入力パラメータ

Cycle doc から以下を抽出して designer に渡す:

- target_audience: Environment/Scope の記載から対象ユーザー層を判定（Japanese / Western / Both）。明記なければ Both とする
- ui_scope: In Scope の UI 関連ファイル・機能を列挙し、変更対象の範囲を要約

#### designer vs usability-reviewer

| 観点         | designer (PLAN)              | usability-reviewer (REVIEW)        |
|--------------|------------------------------|------------------------------------|
| フェーズ     | PLAN（設計時）               | REVIEW（実装後）                   |
| 対象         | 設計方針・パターン           | 実装コード                         |
| 出力         | UI/UX ガイドライン提案       | アクセシビリティ検証結果           |
| スコアリング | なし（提案のみ）             | blocking_score                     |

## ブロッキングスコア詳細

blocking_score は 5 reviewer のみで計算（0-100、designer は対象外）:

| スコア | 判定  | アクション                   |
|--------|-------|------------------------------|
| 80-100 | BLOCK | PLANに戻って修正必須         |
| 50-79  | WARN  | 警告確認後、REDへ進行可      |
| 0-49   | PASS  | REDへ自動進行                |

## 出力形式

各エージェントの出力:

```json
{
  "blocking_score": 75,
  "issues": [
    {
      "severity": "important",
      "message": "変更ファイル数が目安の10個を超えています",
      "suggestion": "スコープを分割して複数サイクルに"
    }
  ]
}
```

## 結果統合

最大スコアで判定（designer はスコア対象外）:

```
================================================================================
plan-review 完了
================================================================================
スコア: 75 (WARN)

scope-reviewer: 75 (WARN)
  - 変更ファイル数が目安の10個を超えています

architecture-reviewer: 30 (PASS)
risk-reviewer: 40 (PASS)

UI/UX Design Guidelines (designer):
  - Target Audience: Japanese
  - Selected Patterns: P-01, P-02, P-07
  - Design Tokens: spacing-scale, font-size-base

警告があります。確認してREDへ進むか、PLANに戻るか選択してください。
================================================================================
```
