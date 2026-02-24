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

### Source Path 解決

| 優先度 | ソース | パス |
|--------|--------|------|
| 1 | キャッシュ | `~/.claude/dev-crew/source-path` (observe.sh が毎回更新) |
| 2 | ユーザー入力 | AskUserQuestion で dev-crew ソースパスを質問 |

### Contribute テーブル

| 項目 | デフォルト | --contribute |
|------|-----------|-------------|
| 出力先 | `~/.claude/dev-crew/evolved/` | `{source-path}/skills/` or `{source-path}/agents/` |
| テスト | なし | 全テスト実行: `for f in {source-path}/tests/test-*.sh; do bash "$f"; done` |
| 失敗時 | - | コピーを削除しロールバック。staging に残す |
| Git 操作 | なし | ユーザーに `{source-path}` での commit を促す |

### Contribute フロー

1. `cat ~/.claude/dev-crew/source-path` でパス取得（不在時は AskUserQuestion）
2. `{source-path}/.claude-plugin/plugin.json` の存在を確認（不在時はエラー終了）
3. staging から `{source-path}/skills/` or `{source-path}/agents/` にコピー
4. 全テスト実行: `for f in {source-path}/tests/test-*.sh; do bash "$f"; done`
5. テスト失敗 → コピーを削除し、staging に残す + エラーメッセージ表示
6. テスト成功 → 「`{source-path}` で commit して反映してください」とユーザーに案内

### 安全性

- 既存ファイルの上書き前にバックアップを取得 (Step 5 と同一)
- 全テストスイート (`test-*.sh`) がゲートとなり、不正な定義ファイルの混入を防止
- パス検証: `plugin.json` の存在確認で誤ったディレクトリへのコピーを防止

## 成功基準 (価値検証)

初期目標:
- 10セッション以上 learn 実行
- 3件以上の instinct 抽出
- 1件以上がスキル化承認される

上記を満たさない場合、learn の検出精度または instinct フォーマットの見直しを検討。
