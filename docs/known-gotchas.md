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
