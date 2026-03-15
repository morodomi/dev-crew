# sync-skills Reference

## installed_plugins.json Structure

```json
{
  "version": 2,
  "plugins": {
    "dev-crew@dev-crew": [{
      "scope": "user",
      "installPath": "~/.claude/plugins/cache/dev-crew/dev-crew/2.0.0",
      "version": "2.0.0"
    }],
    "novel-skills@novel-skills": [{
      "scope": "local",
      "projectPath": "/path/to/project",
      "installPath": "~/.claude/plugins/cache/novel-skills/novel-skills/abc123",
      "version": "abc123"
    }]
  }
}
```

## Symlink Handling

### Case 1: Nothing exists -> Create

```bash
ln -s "$install_path/skills/$skill_name" ".agents/skills/$skill_name"
```

### Case 2: Correct symlink exists -> Skip

```bash
current=$(readlink ".agents/skills/$skill_name")
# $current == $target -> skip
```

### Case 3: Broken symlink -> Replace

```bash
rm ".agents/skills/$skill_name"
ln -s "$target" ".agents/skills/$skill_name"
```

### Case 4: Conflict (different target) -> Ask user

既存symlinkが別のtargetを指している場合、ユーザーに確認:
- 上書き: 既存を削除して新規作成
- スキップ: 既存を維持

### Case 5: Skill name collision (multiple plugins)

2つのpluginに同名スキルがある場合もCase 4と同じ扱い。

## Scope Filtering

| scope | 条件 | 対象 |
|-------|------|------|
| user | 常に | 全プロジェクト |
| local | projectPath一致 | 指定プロジェクトのみ |

## Quick Reference (user-scope only, new symlinks only)

以下はuser-scopeプラグインの新規symlinkのみを作成する簡易版。
壊れたsymlink修復やconflict確認はSKILL.mdワークフローで対応する。

```bash
mkdir -p .agents/skills && \
jq -r '.plugins | to_entries[] | .value[] | select(.scope == "user") | .installPath' \
  ~/.claude/plugins/installed_plugins.json | \
while read -r path; do
  [ -d "$path/skills" ] || continue
  for skill in "$path"/skills/*/; do
    name=$(basename "$skill")
    [ -L ".agents/skills/$name" ] || ln -s "$skill" ".agents/skills/$name"
  done
done
```

Note: local-scopeのフィルタリング、壊れたsymlink修復、衝突処理は含まない。
完全な処理はSKILL.mdのワークフローに従う。

## Existing Manual Setup

手動symlink実績:
- `note/.agents/skills/` (note-skills)
- `exspec/.agents/skills/` (dev-crew)
