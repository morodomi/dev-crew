# Known Gotchas

開発中に遭遇した既知の問題と対策集。

## macOS symlink canonicalize mismatch

### 問題
macOS で `/var` は `/private/var` へのシンボリックリンク。`realpath` と `readlink -f` で異なる結果が返る場合がある。
テストで絶対パス比較を行うと、片方が `/var/...`、もう片方が `/private/var/...` となり不一致になる。

### 対策
パス比較の両辺を canonicalize する:
```bash
# 両辺を realpath で正規化してから比較
actual=$(realpath "$path1")
expected=$(realpath "$path2")
[ "$actual" = "$expected" ]
```

### 影響範囲
- テストスクリプトでの一時ファイルパス比較
- sync-skills のシンボリックリンク検証
- Codex セッション管理の cwd フィルタ

## grep -c で0件時の挙動

### 問題
`grep -c` は一致が0件の場合 exit code 1 を返す。`set -e` 環境下でスクリプトが中断する。

### 対策
```bash
count=$(grep -c 'pattern' file 2>/dev/null || echo "0")
```

### 影響範囲
- ゲートスクリプト（pre-red-gate.sh, pre-commit-gate.sh）
- risk-classifier.sh
- テストスクリプト全般

## evolve 連携規約

evolve の将来拡張として、instinct を Gotchas に変換する際のルール。現在は手動追記。evolve が直接 reference.md を編集する機能は未実装（evolve は ${CLAUDE_PLUGIN_DATA}/evolved/ へのステージングと GitHub Issue 提案のみ）。

### 追記先の判断

| スコープ | 追記先 |
|---------|--------|
| このスキルでしか発生しない | 各スキルの `skills/<name>/reference.md` の `## Gotchas` テーブル |
| 複数スキルに影響する | `docs/known-gotchas.md` |

### G-番号規則

- スキル reference.md の Gotchas テーブルにのみ適用（known-gotchas.md のエントリには G-番号を付与しない）
- 既存の最大番号 + 1 で連番付与
- 例: G-05 が最後なら次は G-06

### テーブル行フォーマット

```markdown
| G-NN | [症状の簡潔な記述] | [根本原因] | [具体的な対策] |
```
