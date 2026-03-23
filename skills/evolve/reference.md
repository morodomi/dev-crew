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

evolve 実行前に `${CLAUDE_PLUGIN_DATA}/backup/YYYYMMDD_HHMM/` にスナップショットを保存。

ロールバック手順:
```bash
# 直前の evolve を取り消す
cp -r ${CLAUDE_PLUGIN_DATA}/backup/YYYYMMDD_HHMM/* ${CLAUDE_PLUGIN_DATA}/evolved/
```

## source-path 解決

evolve は source-path ファイルからプラグインルートを解決する:

1. `${CLAUDE_PLUGIN_DATA}/source-path` ファイルを読む（observe.sh が自動生成）
2. source-path が存在しない場合: AskUserQuestion でプラグインルートを確認
3. source-path のパスに `plugin.json` が存在することを検証

### テスト検証

contribute 前に全テストを実行:
```bash
for f in test-*.sh; do bash "$f"; done
```

## GitHub Issue 作成 (導入提案)

生成されたスキル/エージェントを dev-crew に導入するため、`morodomi/dev-crew` に Issue を作成する。
ローカルの dev-crew プラグインソースは書き換えない。導入判断はメンテナーが行う。

### Issue フォーマット

| 項目 | 値 |
|------|-----|
| リポジトリ | `morodomi/dev-crew` |
| タイトル | `feat: evolve提案 - <スキル名>` |
| ラベル | `evolve` |
| 本文 | 概要、由来instinct一覧、生成物全文、staging パス |

### Issue 作成フロー

1. staging (`${CLAUDE_PLUGIN_DATA}/evolved/<スキル名>/`) の生成物を読み取る
2. `gh issue create` で Issue 作成
3. Issue URL をユーザーに報告

### 旧 --contribute モード (廃止)

以前は `--contribute` でローカルの dev-crew ソースに直接コピーしていたが、他ユーザーへの影響を考慮し廃止。
Issue 経由での導入提案に一本化。

## 成功基準 (価値検証)

初期目標:
- 10セッション以上 learn 実行
- 3件以上の instinct 抽出
- 1件以上がスキル化承認される

上記を満たさない場合、learn の検出精度または instinct フォーマットの見直しを検討。
