# Cycle: Fix Cross-References

## Metadata
- **Issue**: #10
- **Created**: 2026-02-15 01:00
- **Risk**: 15 (PASS)
- **Scope**: Markdown files (20 files, ~53 replacements)

## Goal

旧プラグイン参照 (`core:`, `redteam-core:`, `meta-skills:`) を
`dev-crew:` に統一する。user install前の前提条件。

## Scope

### In Scope
- `core:` → `dev-crew:` (Skill/Task参照内のみ)
- `redteam-core:` → `dev-crew:` (同上)
- `meta-skills:` → `dev-crew:` (同上)

### Out of Scope
- プレーンテキストでの言及 (説明文中の "core" 等)
- plugin.json, hooks.json

## PLAN

### 方針
grep + 手動確認で誤置換を防ぐ。置換対象は以下パターンのみ:
- `Skill(core:` → `Skill(dev-crew:`
- `Skill(redteam-core:` → `Skill(dev-crew:`
- `subagent_type: "core:` → `subagent_type: "dev-crew:`
- `subagent_type: "meta-skills:` → `subagent_type: "dev-crew:`
- `Skill(core:*)` (onboard等の説明内)

### 注意: 置換してはいけないもの
- `redteam-core:` がファイル名やディレクトリパスとして使われている場合
- プレーンテキストの説明文

## Test List

### TODO
- [ ] TC-01: `core:` を含むSkill/Task参照が0件
- [ ] TC-02: `redteam-core:` を含むSkill/Task参照が0件
- [ ] TC-03: `meta-skills:` を含むSkill/Task参照が0件
- [ ] TC-04: `dev-crew:` 参照が正しい件数存在する
- [ ] TC-05: 構造バリデーションテスト全通過
- [ ] TC-06: [異常系] `tdd-core:` 参照が0件 (念のため確認)

## Progress

- [x] INIT
- [x] PLAN
- [x] RED
- [x] GREEN (55 dev-crew: references, 0 legacy refs)
- [x] REFACTOR (mechanical changes, no refactoring needed)
- [x] REVIEW (quality-gate PASS, score 10)
- [ ] COMMIT
