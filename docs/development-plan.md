# Development Plan

## Phase 1: Migration (DONE)

既存スキルをdev-crewに統合。単一plugin構造にフラット化完了。

### 完了事項

- tdd-core -> agents/ + skills/ (root直下)
- tdd-php/python/ts/js/flask/flutter/hugo -> skills/*-quality/
- redteam-core -> agents/*-attacker.md + skills/security-scan/ etc.
- meta-skills -> agents/observer.md + skills/learn/ + skills/evolve/
- 全`tdd-`参照を除去
- 単一plugin.json作成（marketplace.json廃止）
- rules/ 作成（git-safety, git-conventions, security）
- hooks/hooks.json 作成（プレースホルダー）

---

## Phase 1.5: Test Infrastructure (DONE)

構造バリデーションテストを作成。全Phaseの前提基盤。

### 完了事項

- `tests/test-plugin-structure.sh` - plugin.json, agents/, skills/, rules/, hooks/ 検証
- `tests/test-agents-structure.sh` - エージェント frontmatter 検証
- `tests/test-skills-structure.sh` - SKILL.md 行数 + frontmatter 検証
- 3つの over-limit SKILL.md を修正 (attack-report, context-review, flask-quality)
- GitHub Issues #1-#9 登録完了

### Issue Tracking

| Issue | Title | Phase | Status |
|-------|-------|-------|--------|
| #1 | test: structure validation scripts | 1.5 | DONE |
| #2 | feat: phase-compact skill | 2 | Open |
| #3 | feat: orchestrate phase-compact integration | 2 | Open |
| #4 | research: Japanese vs Western UI/UX | 3 | Open |
| #5 | feat: designer agent (Japanese design) | 3 | Open |
| #6 | feat: designer + plan-review integration | 3 | Open |
| #7 | feat: model selection hints | 4 | Open |
| #8 | feat: hook-based tool output filtering | 4 | Open |
| #9 | chore: SKILL.md size audit | 4 | Open |

---

## Phase 2: phase-compact Skill (New Development)

新規スキル。TDDフェーズ境界でのcontext compaction。

### Design

```
skills/phase-compact/
├── SKILL.md          # スキル定義
└── reference.md      # 実装詳細
```

### Behavior

1. 現在のフェーズの成果物をCycle docに追記
2. Phase Summary format:
   ```markdown
   ### Phase: [PHASE_NAME] - Completed at HH:MM
   **Artifacts**: [file list]
   **Decisions**: [key decisions made]
   **Next Phase Input**: [what next phase needs]
   ```
3. `/compact` を実行（または実行を促す）
4. 次フェーズの開始時にCycle docを読み直してコンテキスト復元

### Integration Points

- `orchestrate` skill がフェーズ遷移時に`phase-compact`を呼ぶ
- Manual実行も可能: `/phase-compact`

### Open Questions

- `/compact` をプログラムから直接呼べるか？
  - 呼べない場合: ユーザーに `/compact` 実行を促すメッセージを表示
  - 呼べる場合: 自動実行
- `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` との併用戦略

---

## Phase 3: Designer Agent (New Development)

### Design

```
core/agents/designer.md
```

### Scope

- UI/UXデザインレビュー
- Refactoring UI原則に基づく提案
- Tailwind CSS / shadcn/ui パターン提案
- PLANフェーズでUI設計が含まれる場合に起動

### Dependencies

- ux-design skill (既存) の知識をagent化
- plan-review でusability-reviewerと連携

---

## Phase 4: Optimization (Post-Migration)

### 4.1 Model Selection Optimization

各エージェントに最適なモデルを割り当て:

| Agent | Model | Rationale |
|-------|-------|-----------|
| pdm | Opus | 判断・調整が必要 |
| architect | Sonnet | 設計は中程度の複雑さ |
| red-worker | Sonnet | テスト作成は中程度 |
| green-worker | Sonnet | 実装は中程度 |
| guidelines-reviewer | Haiku | ルールベースで十分 |
| scope-reviewer | Haiku | チェックリスト的 |
| correctness-reviewer | Sonnet | 論理的判断が必要 |
| security-reviewer | Sonnet | セキュリティ知識が必要 |

### 4.2 Tool Output Filtering

git log, git diff等の出力をHookでフィルタリング:
- 不要な情報を除去
- 70%+のtoken削減

### 4.3 Skill Loading Optimization

- SKILL.mdの更なるスリム化
- reference.mdの遅延ロード確認
- 未使用プラグインのスキル説明がsystem promptに含まれないことを確認

---

## Timeline

| Phase | Content | Estimate |
|-------|---------|----------|
| Phase 1 | Migration | Current session |
| Phase 2 | phase-compact | Next session (dev-crew/) |
| Phase 3 | Designer Agent | After phase-compact is stable |
| Phase 4 | Optimization | Iterative, per session |

---

## Success Criteria

| Metric | Current | Target |
|--------|---------|--------|
| Session duration | < 5h window | Full 5h window |
| Plugins to install | 12 individual | 10 from 1 collection |
| marketplace.json count | 4 | 1 |
| Rules duplication | 3 copies | 1 copy |
| Phase token usage | Unknown | Measurable via StatusLine |
