# Development Plan

## Phase 1: Migration (Current)

既存スキルをdev-crewにコピー・リネームする。機能変更なし。

### 1.1 Core Plugin Migration

Source: `tdd-skills/plugins/tdd-core/`
Target: `dev-crew/plugins/core/`

Changes:
- Directory: `tdd-core` -> `core`
- plugin.json: name, description, repository更新
- Skills rename: `tdd-init` -> `init`, `tdd-plan` -> `plan`, etc.
- SKILL.md内のトリガーキーワード更新
- reference.md内の`tdd-`参照を更新
- Agents: 変更なし（tdd-プレフィックスなし）

### 1.2 Language Plugin Migration

| Source | Target | Changes |
|--------|--------|---------|
| tdd-php | php | plugin.json, README, skill name: `php-quality` (unchanged) |
| tdd-python | python | plugin.json, README, skill name: `python-quality` (unchanged) |
| tdd-ts | typescript | plugin.json, README, skill name: `ts-quality` (unchanged) |
| tdd-js | javascript | plugin.json, README, skill name: `js-quality` (unchanged) |
| tdd-flask | flask | plugin.json, README, skill name: `flask-quality` (unchanged) |
| tdd-flutter | flutter | plugin.json, README, skill name: `flutter-quality` (unchanged) |
| tdd-hugo | hugo | plugin.json, README, skill name: `hugo-quality` (unchanged) |

### 1.3 Security Plugin Migration

Source: `redteam-skills/plugins/redteam-core/`
Target: `dev-crew/plugins/security/`

Changes:
- Directory: `redteam-core` -> `security`
- plugin.json: name `security`, description, repository更新
- Skills/Agents: 内部名は変更なし

### 1.4 Meta Plugin Migration

Source: `meta-skills/`
Target: `dev-crew/plugins/meta/`

Changes:
- plugin.json: name `meta`, repository更新
- Skills/Agents: 変更なし

### 1.5 Marketplace Configuration

Create: `dev-crew/.claude-plugin/marketplace.json`

```json
{
  "name": "dev-crew",
  "owner": { "name": "morodomi" },
  "plugins": [
    { "name": "core", "source": "./plugins/core" },
    { "name": "php", "source": "./plugins/php" },
    { "name": "python", "source": "./plugins/python" },
    { "name": "typescript", "source": "./plugins/typescript" },
    { "name": "javascript", "source": "./plugins/javascript" },
    { "name": "flask", "source": "./plugins/flask" },
    { "name": "flutter", "source": "./plugins/flutter" },
    { "name": "hugo", "source": "./plugins/hugo" },
    { "name": "security", "source": "./plugins/security" },
    { "name": "meta", "source": "./plugins/meta" }
  ]
}
```

---

## Phase 2: phase-compact Skill (New Development)

新規スキル。TDDフェーズ境界でのcontext compaction。

### Design

```
core/skills/phase-compact/
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
