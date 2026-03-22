# spec Reference

Detailed information for SKILL.md. Refer only when needed.

## Version comparison

Step 1 の version comparison では、`.claude/dev-crew.json` の `dev_crew_version` と `~/.claude/plugins/installed_plugins.json` の dev-crew バージョンを比較する。

```bash
RECORDED_VERSION=$(jq -r '.dev_crew_version // "unknown"' .claude/dev-crew.json 2>/dev/null)
PLUGIN_VERSION=$(jq -r '.plugins["dev-crew@dev-crew"][0].version // "unknown"' ~/.claude/plugins/installed_plugins.json 2>/dev/null)
```

判定手順:

1. `.claude/dev-crew.json` がなければ warning を表示して停止する。
2. `RECORDED_VERSION` または `PLUGIN_VERSION` が `unknown` なら warning を表示して停止する。
3. 両者が一致すれば続行する。
4. 不一致なら version mismatch warning を表示して停止する。

## Risk Score Assessment Details

### Score Thresholds (unified with review)

| Score | Result | Action |
|-------|--------|--------|
| 0-29 | PASS | Show confirmation, auto-proceed |
| 30-59 | WARN | Quick questions (Step 4.6), then Scope confirmation (Step 5) |
| 60-100 | BLOCK | Brainstorm & risk questions (Step 4.7) |

### Keyword Scores

| Category | Keywords | Score |
|----------|----------|-------|
| Security | login, auth, authorization, password, session, permission, token | +60 |
| External Dependency | API, external integration, payment, webhook, third-party | +60 |
| Data Impact | DB change, migration, schema, table creation | +60 |
| Scope Impact | refactoring, large-scale, system-wide, architecture | +40 |
| Limited | test addition, documentation, comment, README | +10 |
| UI Only | UI fix, color, text, typo, CSS, style | +10 |
| Default | None of the above | 0 |

### Assessment Logic

```
1. Partial match search user input against keywords
2. Same category: max 1 addition (no duplicates)
3. Different categories: sum up (max 100)
4. No match: default 0 (PASS)

Examples:
- "typo fix" = +10 → PASS
- "bug fix" = 0 → PASS (no keyword match)
- "refactoring" = +40 → WARN
- "auth feature" = +60 → BLOCK
- "auth + password" = +60 → BLOCK (same category)
- "auth + API" = +100 → BLOCK (different categories, capped)
```

### Multiple Risk Types

When multiple categories match, **execute all risk-type questions sequentially**.

```
Example: "Login feature with API integration and DB changes"
→ Security questions (auth method, 2FA, etc.)
→ External API questions (API auth, error handling, etc.)
→ Data change questions (existing data impact, rollback, etc.)
```

Record all answers in the Cycle doc.

### WARN Questions (30-59)

Ask 2 lightweight questions to confirm scope before proceeding. Results are NOT recorded in Cycle doc.

```yaml
questions:
  - question: "Have you considered alternative approaches?"
    header: "Alternatives"
    options:
      - label: "Yes, this is the best option"
        description: "Evaluated alternatives and chose this"
      - label: "No, but scope is small enough"
        description: "Low risk, proceed anyway"
      - label: "Want to discuss options"
        description: "Need more exploration"
    multiSelect: false
  - question: "Do you understand the impact scope?"
    header: "Impact"
    options:
      - label: "Yes, limited to specific files"
        description: "Clear boundaries, low risk"
      - label: "Yes, but touches multiple areas"
        description: "Broader scope, manageable"
      - label: "Not sure, need to investigate"
        description: "May need more analysis"
    multiSelect: false
```

**Purpose**: Quick sanity check for medium-risk changes without the full BLOCK interview.

### Brainstorm Questions (BLOCK: 60+)

Before diving into risk-type questions, clarify the core problem:

```yaml
questions:
  - question: "What problem are you really trying to solve?"
    header: "Problem"
    options:
      - label: "User request"
        description: "Users explicitly asked for this feature"
      - label: "Technical debt"
        description: "Existing code is causing issues"
      - label: "Business requirement"
        description: "Required for business goals"
      - label: "Performance issue"
        description: "Current system is too slow"
    multiSelect: false
  - question: "Have you considered alternative approaches?"
    header: "Alternatives"
    options:
      - label: "Yes, this is the best option"
        description: "Evaluated alternatives and chose this"
      - label: "No, need to explore more"
        description: "Want to discuss other options"
      - label: "Partial solution exists"
        description: "Can extend existing functionality"
    multiSelect: false
```

**Purpose**: Prevent over-engineering by ensuring the problem is well-understood before implementation.

Reference: [superpowers/brainstorming](https://github.com/obra/superpowers/blob/main/skills/brainstorming/SKILL.md)

### Risk-Type Questions (BLOCK: 60+)

Execute AskUserQuestion based on detected keywords:

#### Security (login, auth, permission, password)

```yaml
questions:
  - question: "Which authentication method will you use?"
    header: "Auth"
    options:
      - label: "Session"
        description: "Server-side session management"
      - label: "JWT"
        description: "Token-based authentication"
      - label: "OAuth"
        description: "External provider integration"
      - label: "Extend existing"
        description: "Extend current auth system"
    multiSelect: false
  - question: "Target users?"
    header: "Users"
    options:
      - label: "Regular users"
        description: "Standard end users"
      - label: "Admins"
        description: "Users with admin privileges"
      - label: "Both"
        description: "Separated by permission level"
    multiSelect: false
  - question: "Is 2FA (two-factor authentication) required?"
    header: "2FA"
    options:
      - label: "Required"
        description: "Implement from initial release"
      - label: "Not required"
        description: "Password only"
      - label: "Consider later"
        description: "Plan to add in future"
    multiSelect: false
```

#### External Integration (API, webhook, payment, third-party)

```yaml
questions:
  - question: "API authentication method?"
    header: "API Auth"
    options:
      - label: "API Key"
        description: "Static key authentication"
      - label: "OAuth2"
        description: "Token-based"
      - label: "Signed request"
        description: "HMAC signature, etc."
    multiSelect: false
  - question: "Error handling strategy?"
    header: "Errors"
    options:
      - label: "Retry"
        description: "Retry on failure"
      - label: "Fallback"
        description: "Switch to alternative"
      - label: "Immediate error"
        description: "Notify user"
    multiSelect: true  # Retry + fallback combination is common
  - question: "Rate limiting approach?"
    header: "Rate Limit"
    options:
      - label: "Queuing"
        description: "Manage requests in queue"
      - label: "Backoff"
        description: "Exponential backoff retry"
      - label: "Not needed"
        description: "Won't hit limits"
    multiSelect: false
```

#### Data Changes (DB, migration, schema)

```yaml
questions:
  - question: "Impact on existing data?"
    header: "Data Impact"
    options:
      - label: "No impact"
        description: "New tables/columns only"
      - label: "Data conversion needed"
        description: "Migrate existing data"
      - label: "Data deletion"
        description: "Delete/merge some data"
    multiSelect: false
  - question: "Rollback method?"
    header: "Rollback"
    options:
      - label: "Auto rollback"
        description: "Down migration supported"
      - label: "Manual recovery"
        description: "Restore from backup"
      - label: "Forward compatible"
        description: "Works with old and new"
    multiSelect: false
```

### Recording Format in Cycle Doc

```markdown
## Environment

### Scope
- Layer: Backend
- Plugin: php
- Risk: 65 (BLOCK)  # ← Score format

### Risk Details (BLOCK only)
- Detected keywords: auth, API
- Total score: 65 (auth +60, no duplicates)
- Impact scope: 3-5 files
- External dependency: DB changes
```

## Hooks Check

In Step 1, after checking STATUS.md, verify hooks setup:

```bash
# Check if user has hooks configured
grep -q '"hooks"' ~/.claude/settings.json 2>/dev/null
```

**If hooks are not configured**, show recommendation:

```
Recommended hooks are available at .claude/hooks/recommended.md.
Copy the configuration to ~/.claude/settings.json for:
- --no-verify / rm -rf block
- Test file update reminders
- CLAUDE.md existence check
- Uncommitted changes warning
- Debug statement detection
```

**Do not auto-write to settings.json** (user must opt-in manually).

## Detailed Workflow

### Checking Existing Cycles

```bash
# Find latest Cycle doc
ls -t docs/cycles/*.md 2>/dev/null | head -1
```

**If an active cycle exists**:

```
⚠️ An existing TDD cycle is in progress.

Latest: docs/cycles/20251028_1530_XXX.md

Options:
1. [Recommended] Continue existing cycle
2. Start new cycle (parallel development)

What would you like to do?
```

### Scope (Layer) Confirmation Details

Use AskUserQuestion:

```
Select the scope for this feature:
1. Backend (PHP/Python server-side)
2. Frontend (JavaScript/TypeScript client-side)
3. Both (Full stack)
```

**Plugin Mapping:**

| Layer | Framework | Plugin |
|-------|-----------|--------|
| Backend | Laravel | php |
| Backend | Flask | flask |
| Backend | Django | python |
| Backend | WordPress | php |
| Backend | Generic PHP | php |
| Backend | Generic Python | python |
| Frontend | JavaScript | js |
| Frontend | TypeScript | ts |
| Frontend | Alpine.js | js |
| Both | Laravel + JS | php, js |

**Recording in Cycle doc:**

```markdown
## Environment

### Scope
- Layer: Backend
- Plugin: php
```

### Feature Name Generation

**Guidelines**:
- 3-5 words
- Descriptive suffix like "feature", "implementation"

**Examples**:
| What you want to do | Feature name |
|--------------------|--------------|
| Allow users to log in | User login feature |
| Export data as CSV | CSV export feature |
| Add search functionality | Search implementation |
| Send password reset emails | Password reset feature |

**If unclear**:

```
Please be more specific about the feature name.

Good examples: User authentication, Data search
Bad examples: Feature, New thing, That one
```

## Error Handling

### Not a Git Repository

```
⚠️ This directory is not a Git repository.

Git operations are required at the end of TDD cycle.
Recommend using within a Git repository.

Continue anyway?
```

### Directory Creation Failed

```
Error: Failed to create docs/cycles directory.

Solutions:
1. Check permissions: ls -la ./
2. Create manually: mkdir -p docs/cycles
```

## Project-Specific Customization

### Additional Validations

```bash
# Node.js
if [ ! -f "package.json" ]; then
  echo "Warning: package.json not found"
fi

# Python
if [ ! -f "requirements.txt" ]; then
  echo "Warning: requirements.txt not found"
fi
```

### Extending Cycle Doc Template

Add project-specific sections to `templates/cycle.md`.

## Ambiguity Detection {#ambiguity-detection}

Step 4.8 で実行する仕様曖昧性の検出・解消プロセス。strategy skill の Questioning Protocol パターンを再利用する。

### トリガー条件

全 risk level (PASS/WARN/BLOCK) で実行する。ただし BLOCK のリスク質問で既にカバー済みのカテゴリはスキップする。

### 5カテゴリの検出シグナルと質問テンプレート

| カテゴリ | 検出シグナル | 質問例 |
|----------|-------------|--------|
| Data | "export", "import", "CSV", "data" | 対象データ? フォーマット? 件数上限? |
| API | "API", "endpoint", "webhook" | どのAPI? 認証方式? エラー処理? |
| UI/UX | "page", "form", "button", "screen" | どの画面? ユーザーフロー? レスポンシブ? |
| Scope | 曖昧動詞 ("add", "improve", "fix", "update") | どのコンポーネント? 何が変わる? 影響範囲? |
| Edge cases | エラー/制限の明示なし | 失敗時の振る舞い? 空状態? 上限値? |

### AskUserQuestion テンプレート

各カテゴリで検出されたシグナルに基づき、AskUserQuestion で構造化質問を実施:

```yaml
questions:
  - question: "[カテゴリ固有の質問]"
    header: "[カテゴリ名]"
    options:
      - label: "[具体的な選択肢A]"
        description: "[選択肢Aの説明]"
      - label: "[具体的な選択肢B]"
        description: "[選択肢Bの説明]"
    multiSelect: false
```

- 1ラウンド 2-4問
- 検出カテゴリのみ質問（全カテゴリを毎回聞かない）

### Questioning Protocol ルール

| ルール | 内容 |
|--------|------|
| 質問数 | 1ラウンド 2-4問 |
| ラウンド上限 | 最大3ラウンド |
| 3ラウンド後 | 残る曖昧点は「TBD」として記録し次ステップへ |
| スキップ条件 | 20語以上の具体的な記述があるカテゴリはスキップ可 |

### 記録

決定事項をplanファイルのTDD Context末尾に追記:

```markdown
### Ambiguity Resolution
- Data: CSV形式、最大10,000行
- Scope: UserControllerのみ変更
- Edge cases: 空ファイル時はエラーメッセージ表示
```

## Plan File Template {#plan-file-template}

planファイルに記録するTDDコンテキストのテンプレート:

```markdown
## TDD Context

- Workflow: TDD (sync-plan → plan-review → RED → GREEN → REFACTOR → REVIEW → COMMIT)
- Cycle doc: sync-plan エージェントが docs/cycles/ に作成
- Feature: [feature name (3-5 words)]

### Environment
- Layer: [Backend / Frontend / Both]
- Plugin: [php / flask / python / js / ts]
- Risk: [0-100] ([PASS / WARN / BLOCK])
- Language: [version info]
- Dependencies: [key packages]

### Risk Details (BLOCK only)
- [risk interview answers]

### Ambiguity Resolution (if any)
- [category]: [resolution]

## Post-Approve Action

approve後は `/orchestrate` を起動する。orchestrate が全フェーズを管理する:
- sync-plan → Cycle doc 生成
- Codex plan review (codex exec --full-auto, 委譲確認不要)
- plan-review (Claude)

Edit/Write は orchestrate 起動まで hook (post-approve-gate.sh) でブロックされる。
```

この後、plan mode内で探索・設計・Test List定義・QAチェックを続行する。

## Upstream Consistency Check {#upstream-check}

### 手順

1. 上流ドキュメント検出:
   ```bash
   ls *requirements*.md docs/*requirements*.md ROADMAP.md docs/ROADMAP.md 2>/dev/null
   ```
2. 検出されたファイルを読み、planの設計方針との矛盾を確認
3. 矛盾がある場合、planの `## Upstream References` セクションに理由を明記:
   ```markdown
   ## Upstream References
   - ROADMAP.md Phase 11.10 と異なる点: [理由]
   - requirements.md の制約Xを緩和: [理由]
   ```
4. 上流ドキュメントが存在しない場合はスキップ（記録不要）

### 確認観点

| 観点 | 内容 |
|------|------|
| 用語一致 | 上流の用語と plan の用語が一致しているか |
| スコープ整合 | 上流で定義されたスコープの範囲内か |
| 優先度整合 | 上流の優先度と矛盾していないか |
| 制約尊重 | 上流の技術的制約を無視していないか |

## Constitution Check {#constitution-check}

プロジェクトの存在意義・原則と設計方針の整合性を確認する。

### 憲法ドキュメント検出

```bash
ls CONSTITUTION.md AGENTS.md CLAUDE.md README.md 2>/dev/null | head -1
```

優先度: CONSTITUTION.md > AGENTS.md > CLAUDE.md > README.md
最初に見つかったものを「憲法」として扱う。見つからなければスキップ。

### 確認観点

| 観点 | 内容 |
|------|------|
| Goal整合 | 設計がプロジェクトのGoalに貢献するか |
| Non-Goal違反 | Non-Goalsに該当する変更を含んでいないか |
| 原則遵守 | 原則（例: AI-first, 決定論的ゲート）に反していないか |
| 責務境界 | Human vs AI の責務を侵害していないか |

### 記録

矛盾がある場合、plan の `## Upstream References` に追記:

```markdown
## Upstream References
- CONSTITUTION.md 原則6に反する点: テキストルールで手順を強制 → hookベースのゲートに変更
```

矛盾がなければ記録不要（デフォルトで整合と見なす）。
