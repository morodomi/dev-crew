# Keiba Project Conventions for dev-crew

Keiba (競馬予想システム) から dev-crew への要望・規約。
dev-crew本体のスキル定義は汎用のまま維持し、Keiba固有の規約はここに記録する。

## テストアーキテクチャ

正式ドキュメント: `Keiba/docs/test_architecture.md`

### テスト配置

| 状況 | 配置先 |
|------|--------|
| 新規テスト | `tests/specs/` |
| 既存テストの修正 | 元のファイル（修正ついでに specs/ 移行を検討） |
| 確率的テスト (ML等) | `tests/statistical/` |
| 既存テスト (動いている) | 触らない |

### テスト設計原則

dev-crew の Given/When/Then に加えて、以下を意識:

| 原則 | 内容 | 違反例 |
|------|------|--------|
| **What not How** | 入出力の契約を検証。実装手順を検証しない | mock地獄、内部メソッド呼び出し順のアサート |
| **DAMP over DRY** | 1テストを読めば仕様が完結する | 共通ヘルパーに隠れた前提条件 |
| **Self-contained** | 1ファイル内でContract+Propertiesが完結 | conftest.pyへの過度な依存 |

### テストパターン (2領域モデル)

| 領域 | テストパターン | Keiba具体例 |
|------|--------------|------------|
| 決定論的 | Data Contract (Pandera) + Property-Based Testing (Hypothesis) | 特徴量計算、ROI計算、パーサー |
| 確率的 | Metamorphic Testing + 統計的Property | LightGBMモデル、Harvileシミュレーション |

### Mock方針

- 外部依存 (netkeiba API, JRDB, Slack) のみ最小限mock
- 内部実装詳細へのmockは避ける
- DB: インメモリSQLite + conftest.py の `conn` fixture を使う

## 言語・ツール

| 項目 | Keiba |
|------|-------|
| 言語 | Python |
| テスト | pytest |
| 静的解析 | mypy |
| フォーマッタ | black, isort |
| Data Contract | Pandera |
| Property-Based | Hypothesis |

## スキル定義への改善提案

dev-crew本体に取り込むべきと判断された場合、PR/Issueで提案する。

### 提案済み (未実施)

1. **reference.md の Test Architecture Guide 圧縮** (#45): 現在 reference.md に詳細コピーがあるが、プロジェクトの `docs/test_architecture.md` への参照 + 要点のみに圧縮することで重複管理を解消できる
2. **例のPHP偏重の解消** (#46): red-worker, green-worker, reference.md の例がPHP中心 → **擬似コード化で解消済み**
3. **refactorer.md の「Leadに報告」** (#47): SendMessage/Lead概念が現アーキテクチャで有効か要確認
