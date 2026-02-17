# Cycle: Token消費量最適化 - Auto-Transition除去

phase: COMMIT
issue: #27
date: 2026-02-17

## Goal

Skill() の auto-transition チェーンを除去し、トークン消費量を削減する。重複実行バグ（plan-review 2重実行、quality-gate 2重実行）も解消する。

## Background

### Issue の起点

X.com のポストで、Skill() の逐次呼び出しがコンテキストフォークによるキャッシュ読み取り爆発を引き起こすことが報告された。3スキルを1つにまとめてバッチ化し、70%+改善。

### Skill() vs Task() のトークン特性

| 呼び出し方 | コンテキスト | トークン消費 |
|-----------|------------|------------|
| Skill() | 親の全会話コンテキストを継承（フォーク） | 重い（チェーンで累積） |
| Task() | 新規プロンプトのみで起動 | 軽い（固定） |

Skill(A) の中で Skill(B) を呼ぶと:

```
メイン会話: 50K tokens
  └─ Skill(A): 50K 継承 + 10K 追加 = 60K キャッシュ読み取り
       └─ Skill(B): 60K 継承 + 5K 追加 = 65K キャッシュ読み取り
```

チェーンが長いほどキャッシュ読み取りが累積する。

### dev-crew の現状

**orchestrate モード**: Cycle #15 で Task() 委譲に変換済み。問題なし。

**手動スキル呼び出し**: 6箇所に auto-transition（Skill() チェーン）が残存:

| ファイル | 行 | 遷移先 |
|---------|-----|--------|
| skills/plan/SKILL.md | 95 | `Skill(dev-crew:plan-review)` |
| skills/red/SKILL.md | 90 | `Skill(dev-crew:green)` |
| skills/green/SKILL.md | 87 | `Skill(dev-crew:refactor)` |
| skills/refactor/SKILL.md | 82 | `Skill(dev-crew:review)` |
| skills/security-scan/SKILL.md | 75 | `Skill(dev-crew:attack-report)` |
| skills/diagnose/SKILL.md | 78 | `Skill(dev-crew:plan)` |

手動で red→green→refactor→review を実行した場合の試算（50K base context）:

| フェーズ | auto-transition あり | auto-transition なし |
|---------|--------------------|--------------------|
| red | 50K | 50K |
| green | 65K (+15K 累積) | 50K |
| refactor | 75K (+10K 累積) | 50K |
| review | 85K (+10K 累積) | 50K |
| **合計** | **275K** | **200K** |

**差分: 75K 節約（27% 削減）**

### 重複実行バグ（2箇所）

**Bug A: Agent Teams mode で plan-review が 2 回実行**

1. `steps-teams.md:53` で architect が Skill(plan) を実行
2. plan/SKILL.md:95 の auto-transition で plan-review が architect 内で発火
3. architect 完了 → PdM に返る
4. `steps-teams.md:61` で PdM が再度 Skill(plan-review) を実行
5. plan-review が 2 回実行（5-6 reviewer x2 = 10-12 subagent）

**Bug B: Subagent Chain mode で quality-gate が 2 回実行される可能性**

1. `steps-subagent.md:111` で refactorer が Skill(refactor) を実行
2. refactor/SKILL.md:82 の auto-transition で Skill(review) が発火
3. review が quality-gate を実行（6 reviewer subagent）
4. refactorer 完了 → PdM に返る
5. `steps-subagent.md:122` で PdM が Skill(quality-gate) を実行
6. quality-gate が 2 回実行される可能性（6 reviewer x2 = 12 subagent）

## Scope

### 方針

1. TDD スキル（plan/red/green/refactor/diagnose）: auto-transition 除去、完了メッセージのみ
2. Security スキル: 新規 `security-audit` スキルで scan + report を Task() 委譲で orchestrate。既存 security-scan / attack-report は単機能化
3. orchestrate の整合性更新（重複実行バグ解消）

### 対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `tests/test-no-auto-transitions.sh` | 新規テスト |
| `skills/plan/SKILL.md` | auto-transition 除去 |
| `skills/red/SKILL.md` | auto-transition 除去 |
| `skills/green/SKILL.md` | auto-transition 除去 |
| `skills/refactor/SKILL.md` | auto-transition 除去 |
| `skills/diagnose/SKILL.md` | auto-transition 除去 |
| `skills/security-scan/SKILL.md` | auto-transition 除去、--no-auto-report 削除 |
| `skills/attack-report/SKILL.md` | description 更新 |
| `skills/security-audit/SKILL.md` | 新規スキル |
| `skills/orchestrate/steps-subagent.md` | plan-review/quality-gate の実行者明記 |
| `skills/orchestrate/steps-teams.md` | 同上 |
| `agents/architect.md` | plan-review は Lead が実行する旨明記 |

Risk: 20 (PASS)

## Acceptance Criteria

- [ ] 個別スキルの SKILL.md に auto-transition（Skill() チェーン）が存在しない
- [ ] security-audit スキルが scan + report を Task() で実行する
- [ ] orchestrate の steps-subagent.md / steps-teams.md が整合
- [ ] 既存テスト全 PASS

## PLAN

### 完了メッセージの形式

各スキルの auto-transition セクションを以下に置換:

```
================================================================================
[PHASE]完了
================================================================================
[成果サマリー]

次のステップ:
- Orchestrate使用時: 自動的に次フェーズが実行されます
- 手動実行時: /[next-skill] で次フェーズを開始してください
================================================================================
```

### security-audit スキル設計

```
/security-audit [target] [options]
  1. Task(security-scan) → JSON結果を取得
  2. Task(attack-report) → JSON → Markdownレポート生成
  3. [optional] Task(generate-e2e) → E2Eテスト生成（--auto-e2e時）
```

### orchestrate 整合性更新

**steps-subagent.md**:
- L44-47: architect は plan のみ実行。PdM が architect 完了後に Skill(plan-review) を実行
- L111-115: refactorer は refactor のみ実行。PdM が Skill(quality-gate) を実行

**steps-teams.md**:
- L48-56: 同上
- L155-163: 同上

**agents/architect.md**:
- L43: plan-review は Lead が実行する旨を明記

## Test List

### DONE
- [x] TC-01: [正常系] 個別スキルに auto-transition が存在しないこと → FAIL (5 violations: plan, red, green, refactor, diagnose)
- [x] TC-02: [正常系] フロー制御スキル (orchestrate/init/parallel/security-audit) は除外されること → PASS
- [x] TC-03: [境界値] 完了メッセージ内の Skill() 記述例はテスト対象外であること → PASS
- [x] TC-04: [回帰] 既存テスト (skills-structure, agents-structure, cross-references) が全 PASS → PASS
