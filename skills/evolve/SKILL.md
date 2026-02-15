---
name: evolve
description: "蓄積された instinct をクラスタリングし、スキル/エージェント定義を自動生成する。「evolve」「スキル進化」で起動。"
allowed-tools: Read, Write, Bash, Grep, Glob
---

# Evolve - Instinct からスキル/エージェント進化

蓄積された instinct をクラスタリングし、再利用可能なスキルまたはエージェントに進化させる。

## 前提

- learn スキルで instinct が蓄積されていること
- .claude/meta-skills/instincts/ に JSONL ファイルが存在すること

## 実行手順

### Step 1: instinct 読み込み + Empty State チェック

```bash
wc -l .claude/meta-skills/instincts/*.jsonl 2>/dev/null
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

- 出力先: `.claude/meta-skills/evolved/`
- 生成物に由来 instinct ID をコメントとして埋め込む

### Step 5: バックアップ + 結果報告

生成前に既存ファイルのバックアップを `.claude/meta-skills/backup/` に保存。

```
スキル「phpstan-type-fix」を生成しました。
由来: inst-20260213-001, inst-20260214-003, inst-20260215-002
保存先: .claude/meta-skills/evolved/phpstan-type-fix/SKILL.md
```

## Reference

詳細: [reference.md](reference.md)
