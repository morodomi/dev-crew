---
name: kickoff
description: plan modeで承認されたplanファイルからCycle docを生成する。plan mode承認後の最初のフェーズ。「kickoff」「キックオフ」で起動。
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

# TDD KICKOFF Phase

plan modeで承認されたplanファイルを読み取り、Cycle docを生成する。

## Progress Checklist

```
KICKOFF Progress:
- [ ] planファイル読み取り → 情報抽出
- [ ] Cycle doc生成（テンプレートから）
- [ ] Test List・設計情報の転記
- [ ] 完了メッセージ表示
```

## 禁止事項

- planファイルの内容を変更しない（読み取りのみ）
- 実装コード作成（GREENで行う）
- テストコード作成（REDで行う）

## Workflow

### Step 1: Read Plan File

plan modeで作成・承認されたplanファイルを読み取り、以下の情報を抽出:

- **TDD Context**: feature name, environment, scope, risk
- **探索結果**: 既存パターン、影響範囲
- **設計方針**: アーキテクチャ、依存関係
- **Test List**: 正常系/境界値/エッジケース/異常系
- **QAチェック結果**: カバレッジ・粒度・セキュリティ・独立性

### Step 2: Generate Cycle Doc

Feature nameからファイル名を生成し、[templates/cycle.md](../spec/templates/cycle.md) からCycle docを作成。

```bash
mkdir -p docs/cycles
```

planファイルから以下をCycle docに転記:

| Cycle doc セクション | planファイルからの転記元 |
|---------------------|----------------------|
| Scope Definition | In Scope / Out of Scope / Files to Change |
| Environment | Layer, Plugin, Risk, Runtime, Dependencies |
| Risk Interview | BLOCK時のインタビュー回答 |
| Context & Dependencies | 依存関係・参照ドキュメント |
| Implementation Notes | Goal, Background, Design Approach |

### Step 3: Transfer Test List

planファイルのTest ListをCycle docのTest Listセクションに転記。

```markdown
## Test List

### TODO
- [ ] TC-01: [test case]
- [ ] TC-02: [test case]

### WIP
(none)

### DISCOVERED
(none)

### DONE
(none)
```

### Step 4: Complete

```
================================================================================
KICKOFF完了
================================================================================
planファイルからCycle docを生成しました。

Cycle doc: docs/cycles/YYYYMMDD_HHMM_feature-name.md

Design Review Gate: architectにより事前実施済み

次のステップ:
- Orchestrate: 自動的にREDフェーズへ進行します
- 手動: /review --plan で設計レビューを再実行可能
================================================================================
```

## Reference

- [reference.md](reference.md) / Templates: [../spec/templates/cycle.md](../spec/templates/cycle.md)
