---
name: evolve
description: "蓄積された instinct をクラスタリングし、スキル/エージェント定義を自動生成する。「evolve」「スキル進化」で起動。"
allowed-tools: Read, Write, Bash, Grep, Glob
---

# Evolve - Instinct からスキル/エージェント進化

蓄積された instinct をクラスタリングし、再利用可能なスキルまたはエージェントに進化させる。

## 前提

- learn スキルで instinct が蓄積されていること
- ~/.claude/dev-crew/instincts/ に JSONL ファイルが存在すること

## 実行手順

### Step 1: instinct 読み込み + Empty State チェック

```bash
wc -l ~/.claude/dev-crew/instincts/*.jsonl 2>/dev/null
```

instinct が不足している場合:

```
現在 X 件の instinct が蓄積されています。
クラスタリングには同一 domain で 3件以上の類似パターンが必要です。
learn を継続して instinct を蓄積してください。
```

0件の場合: 「instinct が蓄積されていません。まず learn を実行してください。」

### Step 2: クラスタリング (ルールベース)

以下のルールで類似 instinct をグルーピング:

1. **domain 一致**: 同一 domain フィールドの instinct を抽出
2. **trigger キーワード類似**: trigger 内のキーワードトークン重複率 > 50%
3. **閾値**: 3件以上のグループをクラスタとして採用
4. **品質条件**: グループ内全件が confidence >= 0.5

### Step 3: ユーザー承認

クラスタごとにプレビューを表示し、AskUserQuestion で確認:

```
クラスタ: 「PHPStan 型エラー対応」(3件の instinct)
- inst-20260213-001: array access null check
- inst-20260214-003: return type declaration
- inst-20260215-002: strict_types annotation

このクラスタからスキルを生成しますか?
```

選択肢: 生成する / スキル名を変更して生成 / スキップ

### Step 4: スキル/エージェント生成

承認されたクラスタから定義ファイルを生成:

- デフォルト出力先: `~/.claude/dev-crew/evolved/` (staging)
- `--contribute` 時: dev-crew ソース (`skills/` or `agents/`) に直接出力
- 生成物に由来 instinct ID をコメントとして埋め込む

### Step 5: バックアップ + 結果報告

生成前に既存ファイルのバックアップを `~/.claude/dev-crew/backup/` に保存。

```
スキル「phpstan-type-fix」を生成しました。
由来: inst-20260213-001, inst-20260214-003, inst-20260215-002
保存先: ~/.claude/dev-crew/evolved/phpstan-type-fix/SKILL.md
```

### Step 6: Contribute to dev-crew (Optional)

`--contribute` 指定時、生成物を dev-crew ソースに書き戻す:

1. staging (`~/.claude/dev-crew/evolved/`) から `skills/` or `agents/` にコピー
2. 構造検証テスト実行 (`bash tests/test-skills-structure.sh`, `bash tests/test-agents-structure.sh`)
3. テスト失敗時: 書き戻しをロールバックし、staging に残す
4. テスト成功時: ユーザーに commit を促す

デフォルト (contribute なし): staging に出力して終了。

## Reference

詳細: [reference.md](reference.md)
