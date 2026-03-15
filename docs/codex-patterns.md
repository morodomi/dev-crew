# Codex Detection Patterns

Codex が高確率で検出するパターン集。Review 時の参考として使用する。

## Patterns

### 1. early-return-case-leak
**Confidence**: 0.85
**説明**: switch/match の case 内で early return が漏れ、後続 case に fallthrough するパターン。
**例**: if 条件で return せずに break のみ → 意図しないコード実行。

### 2. api-input-duplication
**Confidence**: 0.80
**説明**: API エンドポイントで同一入力フィールドを複数箇所で個別にバリデーションし、一方の更新が漏れるパターン。
**例**: Controller と FormRequest で同じフィールドを二重定義 → 片方だけ更新。

### 3. ambiguous-scope-boundary
**Confidence**: 0.75
**説明**: 関数やモジュールのスコープ境界が曖昧で、内部状態が外部から変更可能なパターン。
**例**: public メソッドが内部キャッシュを直接公開 → 外部から破壊可能。

### 4. unused-field-scope-creep
**Confidence**: 0.70
**説明**: データ構造に未使用フィールドが追加され、スコープが不必要に拡大するパターン。
**例**: API レスポンスに将来用フィールドを先行追加 → YAGNI 違反。

### 5. hot-loop-redundant-io
**Confidence**: 0.75
**説明**: ループ内で毎回同じ I/O 操作（DB クエリ、ファイル読み込み）を実行するパターン。
**例**: for ループ内で毎回 `config.get()` を呼び出し → ループ外にホイスト可能。

## Usage

Review フェーズで Codex findings と照合し、上記パターンに該当する指摘は Accept 優先度を上げる。
Claude correctness-reviewer は上記パターンを補完する観点（未実装検出、セマンティクス区別）に集中する。
