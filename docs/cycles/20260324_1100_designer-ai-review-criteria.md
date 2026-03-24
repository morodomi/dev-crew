---
feature: designer-agent
cycle: 20260324_1100_designer-ai-review-criteria
phase: DONE
complexity: trivial
test_count: 3
risk_level: low
codex_session_id: ""
created: 2026-03-24 11:00
updated: 2026-03-24 11:00
---

# Issue #84: designer/ux-design に AI生成UIレビュー観点追加

## Scope Definition

### In Scope
- [ ] `agents/designer.md` に P-13〜P-17 (AI-Generated UI Review カテゴリ) を追加
- [ ] `docs/research/japanese-ux-patterns.md` に P-13〜P-17 の詳細ガイドライン追加
- [ ] `tests/test-designer-agent.sh` に TC-10〜TC-12 追加・PATTERN_COUNT 更新

### Out of Scope
- ux-design スキル（グローバル）への同様観点反映 (Reason: 別プラグインのため別タスク)

### Files to Change (target: 10 or less)
- `agents/designer.md` (edit)
- `docs/research/japanese-ux-patterns.md` (edit)
- `tests/test-designer-agent.sh` (edit)

## Environment

### Scope
- Layer: Docs
- Plugin: Shell tests (bash)
- Risk: 10 (PASS)

### Runtime
- Language: bash

### Dependencies (key packages)
- (none)

## Context & Dependencies

### Reference Documents
- `agents/designer.md` - 現在の12パターン定義（P-01〜P-12）
- `docs/research/japanese-ux-patterns.md` - パターン詳細ガイドライン（権威源）
- `tests/test-designer-agent.sh` - 既存TC-01〜TC-09

### Dependent Features
- (none)

### Related Issues/PRs
- Issue #84: designer/ux-design に AI生成UIレビュー観点追加

## Test List

### TODO
- [ ] TC-10: designer.md に P-13〜P-17 が存在する
- [ ] TC-11: designer.md に AI-Generated UI Review カテゴリが存在する
- [ ] TC-12: japanese-ux-patterns.md に P-13〜P-17 の詳細が存在する

### WIP
(none)

### DISCOVERED
(none)

### DONE
(none)

## Implementation Notes

### Goal
X投稿のAI生成UIレビュー観点を、dev-crewのdesigner agentのrubricに取り込む。現在12パターン(P-01〜P-12, 4カテゴリ)に、AI生成UI特有の5観点を新カテゴリとして追加する。

### Background
ux-designスキルは別プラグイン（グローバルスキル）のため、dev-crew側は `agents/designer.md` + `docs/research/japanese-ux-patterns.md` + テスト更新のみで対応する。

### Design Approach

新カテゴリ「AI-Generated UI Review」(P-13〜P-17) を追加:

| ID | 観点 | 内容 |
|----|------|------|
| P-13 | Priority Focus | 画面の主役が1つに絞られているか |
| P-14 | Context-Driven Design | UIパターンの機械的寄せ集めでなく、業務文脈から設計されているか |
| P-15 | Color Role Separation | ブランド色・操作色・状態色・注意色が分離されているか |
| P-16 | Real Data Resilience | 長文、0件、異常値、重複、欠損で破綻しないか |
| P-17 | Ruthless Elimination | 不要な装飾・情報が残っていないか |

既存パターンとの関係:
- P-13 は P-04 (Visual Hierarchy) の上位チェック
- P-15 は P-03 (Color Palette) の上位チェック
- P-14, P-16, P-17 は新規（AI生成UI特有）

## Verification

```bash
bash tests/test-designer-agent.sh
bash tests/test-designer-integration.sh
```

Evidence: (orchestrate が自動記入)

## Progress Log

### 2026-03-24 11:00 - KICKOFF
- Design Review Gate: PASS (score: 5/100)
- Cycle doc created
- Scope definition ready

---

## Next Steps

1. [Done] INIT <- Current
2. [Next] RED
3. [ ] GREEN
4. [ ] REFACTOR
5. [ ] REVIEW
6. [ ] COMMIT
