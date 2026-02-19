# Evolve - Reference

SKILL.md の詳細情報。必要時のみ参照。

## クラスタリング詳細

### ルールベースアルゴリズム

1. domain フィールドで初期グルーピング
2. 各グループ内で trigger のトークン重複率を計算
   - トークン化: スペース + 記号で分割
   - 重複率 = (共通トークン数 / 短い方のトークン数) * 100
   - 閾値: 50% 以上で「類似」判定
3. 類似ペアから連結成分 (connected components) を構成
4. 3件以上の連結成分をクラスタとして採用

### 将来拡張: LLM ベースクラスタリング

ルールベースで不十分な場合、observer エージェントに類似判定を委譲:
- instinct の trigger/action を LLM に渡して「同一パターンか?」を判定
- 精度は上がるがコスト増

## 生成テンプレート

### スキル生成 (SKILL.md)

```markdown
---
name: {generated-name}
description: "{cluster-summary}"
---

# {Generated Name}

{cluster-summary}

<!-- Evolved from: {instinct-ids} -->
<!-- Evolved at: {date} -->

## Workflow

{steps derived from instinct actions}
```

### エージェント生成 (agent.md)

```markdown
---
name: {generated-name}
description: "{cluster-summary}"
---

# {Generated Name}

<!-- Evolved from: {instinct-ids} -->

## Input
{derived from instinct triggers}

## Output
{derived from instinct actions}

## Workflow
{steps derived from evidence patterns}
```

## バックアップ + ロールバック

evolve 実行前に `~/.claude/dev-crew/backup/YYYYMMDD_HHMM/` にスナップショットを保存。

ロールバック手順:
```bash
# 直前の evolve を取り消す
cp -r ~/.claude/dev-crew/backup/YYYYMMDD_HHMM/* ~/.claude/dev-crew/evolved/
```

## Contribute Mode

`--contribute` 指定時、evolve の生成物を dev-crew ソースに書き戻すモード。

| 項目 | デフォルト | --contribute |
|------|-----------|-------------|
| 出力先 | `~/.claude/dev-crew/evolved/` | `skills/` or `agents/` |
| 構造検証 | なし | `test-skills-structure.sh` / `test-agents-structure.sh` 実行 |
| 失敗時 | - | ロールバックし staging に残す |
| Git 操作 | なし | ユーザーに commit を促す |

### Contribute フロー

1. Step 4 で生成した定義ファイルを staging path から dev-crew ソースにコピー
2. 構造検証テストを実行
3. テスト失敗 → コピーを削除し、staging に残す + エラーメッセージ表示
4. テスト成功 → 「commit して反映してください」とユーザーに案内

### 安全性

- 既存ファイルの上書き前にバックアップを取得 (Step 5 と同一)
- 構造検証テストがゲートとなり、不正な定義ファイルの混入を防止

## 成功基準 (価値検証)

初期目標:
- 10セッション以上 learn 実行
- 3件以上の instinct 抽出
- 1件以上がスキル化承認される

上記を満たさない場合、learn の検出精度または instinct フォーマットの見直しを検討。
