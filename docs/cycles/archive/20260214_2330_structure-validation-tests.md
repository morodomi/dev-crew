# Cycle: Structure Validation Tests

## Metadata
- **Issue**: #1
- **Created**: 2026-02-14 23:30
- **Risk**: 10 (PASS)
- **Scope**: Shell scripts (bash)

## Environment
- OS: macOS Darwin 25.2.0 (arm64)
- Shell: bash 3.2.57 / zsh 5.9
- Project: dev-crew (Claude Code Plugin)

## Goal

dev-crew pluginの構造整合性を検証するテストスクリプト3本を作成する。
全issueの前提となるテスト基盤。

## Scope

### In Scope
- `tests/test-plugin-structure.sh` - plugin.json, agents/, skills/, rules/, hooks/ 検証
- `tests/test-skills-structure.sh` - SKILL.md行数, frontmatter検証
- `tests/test-agents-structure.sh` - agent .md frontmatter検証

### Also In Scope (GREEN phase fix)
- `skills/attack-report/SKILL.md` - 132 -> 67行に縮小 (reference.mdへ分離)
- `skills/context-review/SKILL.md` - 125 -> 59行に縮小 (reference.mdへ分離)
- `skills/flask-quality/SKILL.md` - 103 -> 52行に縮小 (reference.mdへ分離)

### Out of Scope
- CI/CD integration
- 新スキル・エージェントの作成

## Validation Targets

| Target | Check |
|--------|-------|
| `.claude-plugin/plugin.json` | 有効なJSON |
| `agents/*.md` | frontmatter (name, description) |
| `skills/*/SKILL.md` | 存在 + < 100行 + frontmatter |
| `rules/*.md` | 存在 |
| `hooks/hooks.json` | 有効なJSON |

## PLAN

### 設計方針

bashスクリプト3本。各スクリプトは独立実行可能。終了コードで成否を判定。
- 成功: exit 0 + サマリ表示
- 失敗: exit 1 + 失敗箇所を表示

### ファイル構成

```
tests/
├── test-plugin-structure.sh   # plugin全体構造
├── test-skills-structure.sh   # skills検証
└── test-agents-structure.sh   # agents検証
```

### 検証ルール

1. **plugin.json**: `jq` で有効JSON判定
2. **agents/*.md**: `---` で囲まれたfrontmatterに `name:` と `description:` が存在
3. **skills/*/SKILL.md**: 存在 + 行数 < 100 + frontmatter (`name:`, `description:`)
4. **rules/*.md**: 1ファイル以上存在
5. **hooks/hooks.json**: `jq` で有効JSON判定

### 共通パターン

- カウンタ方式: pass/fail カウント → 最終サマリ
- 色付き出力: PASS=green, FAIL=red
- BASE_DIR: スクリプトからの相対パスでプロジェクトルートを解決

## Test List

### TODO
- [ ] TC-01: [正常系] test-plugin-structure.sh - plugin.jsonが有効なJSONであること
- [ ] TC-02: [正常系] test-plugin-structure.sh - agents/ディレクトリに.mdファイルが存在すること
- [ ] TC-03: [正常系] test-plugin-structure.sh - skills/ディレクトリにサブディレクトリが存在すること
- [ ] TC-04: [正常系] test-plugin-structure.sh - rules/ディレクトリに.mdファイルが存在すること
- [ ] TC-05: [正常系] test-plugin-structure.sh - hooks/hooks.jsonが有効なJSONであること
- [ ] TC-06: [正常系] test-agents-structure.sh - 全agentにname frontmatterが存在すること
- [ ] TC-07: [正常系] test-agents-structure.sh - 全agentにdescription frontmatterが存在すること
- [ ] TC-08: [正常系] test-skills-structure.sh - 全skillにSKILL.mdが存在すること
- [ ] TC-09: [正常系] test-skills-structure.sh - 全SKILL.mdが100行以下であること
- [ ] TC-10: [正常系] test-skills-structure.sh - 全SKILL.mdにname frontmatterが存在すること
- [ ] TC-11: [正常系] test-skills-structure.sh - 全SKILL.mdにdescription frontmatterが存在すること
- [ ] TC-12: [異常系] test-plugin-structure.sh - plugin.jsonが不正な場合にFAILすること
- [ ] TC-13: [異常系] test-agents-structure.sh - frontmatter欠損agentでFAILすること
- [ ] TC-14: [異常系] test-skills-structure.sh - 100行超のSKILL.mdでFAILすること

## Progress

- [x] INIT
- [x] PLAN (Risk PASS - plan-review省略)
- [x] RED (3 failures: agents script crash, 3 over-limit SKILL.md)
- [x] GREEN (14/14 PASS)
- [x] REFACTOR (変更なし - 早すぎる抽象化を回避)
- [x] REVIEW (quality-gate PASS: max score 38, grep pattern修正適用)
- [x] COMMIT
