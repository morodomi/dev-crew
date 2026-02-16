---
feature: model-selection-hints
cycle: 20260216_1432
phase: DONE
created: 2026-02-16 14:32
updated: 2026-02-16 14:32
issue: "#7"
---

# feat: model selection hints for agents

## Scope Definition

### In Scope
- [ ] agents/*.md: 全34エージェントのfrontmatterに `model` フィールドを追加
- [ ] skills/orchestrate/steps-teams.md: Task() 呼び出しで model パラメータを参照する手順追加
- [ ] skills/orchestrate/steps-subagent.md: 同上
- [ ] skills/plan-review/steps-subagent.md: reviewer 起動時に model パラメータ参照
- [ ] skills/quality-gate/steps-subagent.md: reviewer 起動時に model パラメータ参照

### Out of Scope
- 実行時のモデル自動選択ロジック（将来の最適化）
- コスト計算・トークン消費の計測
- モデル未対応環境でのフォールバック（Claude Code が自動処理）

### Acceptance Criteria
- [ ] 全エージェントに model フィールドがfrontmatterに記載
- [ ] orchestrate が model を参照して Task tool の model パラメータに渡す手順が記載
- [ ] plan-review / quality-gate が model を参照して起動する手順が記載
- [ ] 構造バリデーションテスト通過

## Environment

- Language: Markdown (plugin definition files)
- Test: bash tests/test-agents-structure.sh

## Context & Dependencies

- Depends on: #1 (structure tests) - 完了済み
- 34 agents in agents/ directory (false-positive-filter-reference.md はリファレンスのため除外)
- Issue #7 のモデル割当方針に準拠

## Risk

- frontmatter に未知のフィールドを追加 → Claude Code Plugin は未知フィールドを無視するため安全
- model 指定が steps-*.md の手順に反映されないリスク → テストで検証

## Implementation Notes

### PLAN

#### 概要

全34エージェント（`false-positive-filter-reference.md` はリファレンスファイルのため除外）の
frontmatter に `model` フィールドを追加し、orchestrate / plan-review / quality-gate の
Task() 呼び出し手順でエージェントの `model` フィールドを参照するよう更新する。

#### 設計方針

1. **frontmatter への `model` フィールド追加**
   - 有効値: `opus`, `sonnet`, `haiku`
   - 既存フィールド (`name`, `description`, `memory`, `allowed-tools`) の後に追加
   - フィールド順序: `name` → `description` → `model` → `memory` → `allowed-tools`

2. **モデル割当方針**

   Issue #7 で明示された12エージェント + 残り22エージェントの割当:

   | Model | Agents | Rationale |
   |-------|--------|-----------|
   | opus | socrates | 高度な批判的思考が必要 |
   | sonnet | architect, red-worker, green-worker, refactorer, scope-reviewer, correctness-reviewer, security-reviewer, performance-reviewer, usability-reviewer, designer, architecture-reviewer, product-reviewer, risk-reviewer | 中程度以上の判断力が必要 |
   | haiku | guidelines-reviewer | ルールベース/チェックリスト的作業 |
   | sonnet | observer | パターン検出には分析力が必要 |
   | sonnet | 全attacker系 (13), recon-agent, false-positive-filter, dynamic-verifier, attack-scenario, dast-crawler | セキュリティ分析には中程度以上の判断力が必要 |

   **scope-reviewer sonnet 維持の根拠**: plan-review で最も有用なフィードバック（score 45）を返したエージェント。haiku に降格するとレビュー品質が低下するリスクがある。

   全34エージェントの完全なマッピング:

   | Agent | Model |
   |-------|-------|
   | architect | sonnet |
   | red-worker | sonnet |
   | green-worker | sonnet |
   | refactorer | sonnet |
   | socrates | opus |
   | observer | sonnet |
   | designer | sonnet |
   | guidelines-reviewer | haiku |
   | scope-reviewer | sonnet |
   | correctness-reviewer | sonnet |
   | security-reviewer | sonnet |
   | performance-reviewer | sonnet |
   | usability-reviewer | sonnet |
   | architecture-reviewer | sonnet |
   | product-reviewer | sonnet |
   | risk-reviewer | sonnet |
   | api-attacker | sonnet |
   | auth-attacker | sonnet |
   | crypto-attacker | sonnet |
   | csrf-attacker | sonnet |
   | error-attacker | sonnet |
   | file-attacker | sonnet |
   | injection-attacker | sonnet |
   | sca-attacker | sonnet |
   | ssrf-attacker | sonnet |
   | ssti-attacker | sonnet |
   | wordpress-attacker | sonnet |
   | xss-attacker | sonnet |
   | xxe-attacker | sonnet |
   | recon-agent | sonnet |
   | false-positive-filter | sonnet |
   | dynamic-verifier | sonnet |
   | attack-scenario | sonnet |
   | dast-crawler | sonnet |

3. **steps-*.md の更新方針**

   - `orchestrate/steps-teams.md`: Task() 呼び出しに `model` パラメータを追加。
     エージェントの frontmatter から model を参照する旨のコメントを付記。
     例: `Task(subagent_type: "dev-crew:architect", team_name: "dev-cycle", name: "architect", model: "sonnet")`
   - `orchestrate/steps-subagent.md`: 同上。
     例: `Task(subagent_type: "dev-crew:architect", model: "sonnet", prompt: "...")`
   - `plan-review/steps-subagent.md`: 既に `model: "sonnet"` がハードコードされている。
     Issue #7 の方針に合わせて各エージェントの model を個別に設定する。
     guidelines-reviewer のみ `model: "haiku"` に変更。scope-reviewer は `model: "sonnet"` 維持。
   - `quality-gate/steps-subagent.md`: 同上。
     guidelines-reviewer を `model: "haiku"` に変更。

4. **テスト拡張**

   `tests/test-agents-structure.sh` に以下のテストケースを追加:
   - 全エージェントに `model` フィールドが存在すること
   - `model` の値が `opus`, `sonnet`, `haiku` のいずれかであること
   - リファレンスファイルはスキップされること（既存ロジック）

#### 変更対象ファイル

| File | Change |
|------|--------|
| agents/*.md (34 files) | frontmatter に `model` フィールド追加 |
| skills/orchestrate/steps-teams.md | Task() に model パラメータ追加 |
| skills/orchestrate/steps-subagent.md | Task() に model パラメータ追加 |
| skills/plan-review/steps-subagent.md | 各 reviewer の model を個別設定 |
| skills/quality-gate/steps-subagent.md | guidelines-reviewer の model を haiku に変更 |
| tests/test-agents-structure.sh | model フィールドのバリデーションテスト追加 |

### Test List

#### TODO
- [ ] TC-21: [正常系] 全34エージェントの frontmatter に `model` フィールドが存在する
- [ ] TC-22: [正常系] `model` の値が `opus|sonnet|haiku` のいずれかである
- [ ] TC-23: [正常系] socrates.md の model が `opus` である
- [ ] TC-24: [正常系] guidelines-reviewer.md の model が `haiku` である
- [ ] TC-25: [正常系] scope-reviewer.md の model が `sonnet` である
- [ ] TC-26: [正常系] architect.md の model が `sonnet` である（sonnet 代表テスト）
- [ ] TC-27: [境界値] リファレンスファイル (false-positive-filter-reference.md) は model チェック対象外
- [ ] TC-28: [異常系] model フィールドが無いエージェントファイルを検出できる（negative test）
- [ ] TC-29: [異常系] model が無効な値 (例: "gpt-4") のエージェントファイルを検出できる（negative test）
- [ ] TC-30: [正常系] orchestrate/steps-teams.md の Task() 呼び出しに model パラメータが含まれる
- [ ] TC-31: [正常系] orchestrate/steps-subagent.md の Task() 呼び出しに model パラメータが含まれる
- [ ] TC-32: [正常系] plan-review/steps-subagent.md で guidelines-reviewer の model が "haiku" である（該当する場合）
- [ ] TC-33: [正常系] quality-gate/steps-subagent.md で guidelines-reviewer の model が "haiku" である
- [ ] TC-34: [正常系] frontmatter の model 値と steps-*.md の model パラメータが一致する（ドリフト検出）

Note: TC-06, TC-07, TC-13 are existing frontmatter validation tests. Model tests start at TC-21 to avoid conflicts.

### Progress Log

- 2026-02-16 14:32 [INIT] Cycle doc created for #7
- 2026-02-16 14:45 [PLAN] Design and Test List created by architect
- 2026-02-16 14:50 [PLAN] plan-review WARN (65): product-reviewer「コストベースライン未設定、quality-gate矛盾、回帰チェック不足」
- 2026-02-16 14:55 [PLAN] Socrates Protocol: O1(scope-reviewer haiku降格矛盾)→**sonnet維持**, O2(ドリフトテスト不足)→TC-14追加, O3(エージェント数35→34)→修正
- 2026-02-16 14:55 [PLAN] Human judgment: scope-reviewer sonnet維持、haiku は guidelines-reviewer のみ → proceed
- 2026-02-16 15:15 [RED] Test script created in tests/test-agents-structure.sh
- 2026-02-16 15:15 [RED] All 14 test cases implemented and verified to FAIL (RED state confirmed)
- 2026-02-16 15:30 [GREEN] All implementation completed, tests PASS (17/17)
- 2026-02-16 16:00 [REFACTOR] Code quality improvements: test variable names clarity, model parameter comments in steps-*.md
- 2026-02-16 16:30 [REVIEW] quality-gate WARN (72): guidelines-reviewer「TC-06/TC-13番号重複」
- 2026-02-16 16:40 [GREEN] TC番号リナンバリング (TC-01~14 → TC-21~34) で重複解消、17/17 PASS
- 2026-02-16 16:45 [DISCOVERED] 2件: haiku品質検証、pre-commit hook追加

### REFACTOR

#### 変更内容

1. **tests/test-agents-structure.sh - 変数名の明確化**
   - `name_fail` → `name_missing_count`: 欠落カウントであることを明示
   - `desc_fail` → `desc_missing_count`: 同上
   - `model_fail` → `model_missing_count`: 同上
   - `invalid_model_fail` → `invalid_model_count`: 無効値カウントであることを明示
   - `drift_fail` → `drift_count`: ドリフト検出カウントであることを明示

2. **tests/test-agents-structure.sh - コメント改善**
   - TC-14: `# Extract agent name` → `# Extract agent name from subagent_type parameter`
   - TC-14: `# Extract model from Task() call` → `# Extract model value from model parameter`

3. **skills/orchestrate/steps-teams.md - model パラメータコメント追加**
   - socrates, architect, red-worker, green-worker, refactorer の Task() 呼び出しに
     `# model: agents/*.md frontmatter の model フィールドに対応` を追加

4. **skills/orchestrate/steps-subagent.md - model パラメータコメント追加**
   - architect, red-worker, green-worker, refactorer の Task() 呼び出しに
     `# model: agents/*.md frontmatter の model フィールドに対応` を追加

5. **skills/plan-review/steps-subagent.md - model パラメータコメント追加**
   - 5エージェント起動箇所に `# model: 各エージェントの agents/*.md frontmatter の model フィールドに対応` を追加
   - designer 起動箇所に `# model: agents/designer.md frontmatter の model フィールドに対応` を追加

6. **skills/quality-gate/steps-subagent.md - model パラメータコメント追加**
   - 6エージェント起動箇所に以下を追加:
     ```
     # model: 各エージェントの agents/*.md frontmatter の model フィールドに対応
     # guidelines-reviewer のみ haiku（ルールベース作業）、他は sonnet（判断力必要）
     ```

#### テスト結果

```bash
$ bash tests/test-agents-structure.sh
=== Summary ===
PASS: 17 / FAIL: 0 / TOTAL: 17
```

全テスト PASS。機能への影響なし。

#### リファクタリング観点

- **DRY原則**: コメント重複なし（各 Task() 呼び出しに個別のコメント）
- **命名改善**: `*_fail` → `*_count` で意図を明確化
- **可読性向上**: model パラメータの出典を明示し、ドリフトリスク低減
- **用語統一**: "34エージェント" 表記を維持（35ファイル中1つはリファレンス）

### GREEN (修正)

#### 問題

quality-gate WARN (cycle log 16:00) で指摘された TC 番号重複:
- TC-06: 既存の name frontmatter 検証（行27）と新規の architect model 検証が衝突
- TC-07: 既存の description frontmatter 検証と新規の reference file exclusion が衝突
- TC-13: 既存の missing frontmatter negative test（行62）と新規の quality-gate model 検証が衝突

#### 修正内容

新規追加の model テスト (TC-01~TC-14) を TC-21~TC-34 にリナンバリング。
既存テスト（TC-06, TC-07, TC-13）はそのまま維持。

| 旧 TC | 新 TC | テスト内容 |
|-------|-------|-----------|
| TC-01 | TC-21 | model フィールド存在チェック |
| TC-02 | TC-22 | model 値バリデーション |
| TC-03 | TC-23 | socrates opus 検証 |
| TC-04 | TC-24 | guidelines-reviewer haiku 検証 |
| TC-05 | TC-25 | scope-reviewer sonnet 検証 |
| TC-06 | TC-26 | architect sonnet 検証 |
| TC-07 | TC-27 | reference file exclusion |
| TC-08 | TC-28 | missing model negative test |
| TC-09 | TC-29 | invalid model negative test |
| TC-10 | TC-30 | orchestrate steps-teams model param |
| TC-11 | TC-31 | orchestrate steps-subagent model param |
| TC-12 | TC-32 | plan-review guidelines model |
| TC-13 | TC-33 | quality-gate guidelines model |
| TC-14 | TC-34 | model drift detection |

#### 変更ファイル

- tests/test-agents-structure.sh: TC 番号リナンバリング、ヘッダーコメント追記
- docs/cycles/20260216_1432_model-selection-hints.md: Test List の TC 番号更新

#### テスト結果

```bash
$ bash tests/test-agents-structure.sh
=== Summary ===
PASS: 17 / FAIL: 0 / TOTAL: 17
```

全テスト PASS。機能への影響なし。TC 番号の衝突を解消。

### DISCOVERED

- guidelines-reviewer の haiku 降格後の品質検証（数サイクル後にレビュー品質への影響を評価）
- pre-commit hook に TC-34 ドリフト検出を追加（SSOT 手動同期リスクの緩和）
