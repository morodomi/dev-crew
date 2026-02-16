---
feature: tc03-test-precision
cycle: 20260216_1800
phase: COMMIT
created: 2026-02-16 18:00
updated: 2026-02-16 18:15
issue: "#22"
---

# fix: TC-03 テスト精度改善

## Scope Definition

### In Scope
- test-hooks-structure.sh の TC-03 がドリフト検出 (TC-34) を正しく検証するよう修正
- temp agent の model 値を有効値に変更
- temp steps file の Task() パターンを TC-34 が認識できる形式に変更

### Out of Scope
- test-agents-structure.sh (TC-21~TC-34) のロジック変更
- 他の TC の修正
- hooks.json の変更

### Acceptance Criteria
- [ ] TC-03 が TC-34 (ドリフト検出) を正しくトリガーして PASS する
- [ ] TC-03 の temp agent が TC-22 (model値検証) を通過する
- [ ] TC-03 の temp steps file が TC-34 の grep パターンにマッチする
- [ ] 全テスト通過 (test-hooks-structure.sh, test-agents-structure.sh)

## Environment

- test-hooks-structure.sh: TC-01~TC-03 (hooks構造検証)
- test-agents-structure.sh: TC-06~TC-34 (agent構造検証)
- TC-22: model値は opus|sonnet|haiku のみ許可
- TC-34: frontmatter model vs steps-*.md の subagent_type + model のドリフト検出

## Problem Analysis

TC-03 の意図: temp agent + temp steps で model ドリフトを作り、test-agents-structure.sh がドリフト検出 (TC-34) で exit 1 を返すことを検証する。

実際の動作:
1. temp agent `model: claude-sonnet-4-5-20250929` → TC-22 (invalid model) で先に FAIL
2. temp steps `name="test-drift-agent"` → TC-34 の grep パターン `subagent_type: "dev-crew:..."` にマッチしない
3. TC-03 は exit code 1 を見て PASS と判定するが、実際は TC-22 で落ちている

修正案 (Issue #22 記載):
- temp agent: `model: sonnet` (有効値)
- temp steps: `subagent_type: "dev-crew:test-drift-agent"` + `model: "opus"` (TC-34 パターン準拠)

## Test List

### TODO
- [ ] TC-A: temp agent の model 値が TC-22 を通過する (`model: sonnet` は `^(opus|sonnet|haiku)$` にマッチ)
- [ ] TC-B: temp steps file が TC-34 の grep パターンにマッチする (`subagent_type: "dev-crew:test-drift-agent"` + `model: "opus"` の単一行 Task() 呼び出し)
- [ ] TC-C: TC-34 がドリフトを検出する (frontmatter `sonnet` vs steps `opus` の不一致で FAIL)
- [ ] TC-D: TC-03 の exit code 1 が TC-34 由来であることを確認 (TC-22 は PASS, TC-34 は FAIL)
- [ ] TC-E: temp ファイル削除後、test-agents-structure.sh が exit 0 で全 PASS (既存テストの回帰なし)
- [ ] TC-F: test-hooks-structure.sh 全体が PASS (TC-01, TC-02, TC-03 全て PASS)

### DONE
- [x] RED-1: Verify TC-03 currently passes (confirmed: PASS but for wrong reason - TC-22 instead of TC-34)
- [x] RED-2: Confirm temp files cause TC-22 to FAIL (confirmed: invalid model `claude-sonnet-4-5-20250929`)
- [x] RED-3: Confirm TC-34 does NOT detect drift with current temp steps format (confirmed: TC-34 shows PASS)
- [x] RED-4: Document TC-34 grep pattern requirements (single-line, subagent_type prefix, both params on same line)
- [x] RED-5: Define RED state (test precision insufficient - false positive on TC-22)

## PLAN

### 背景

TC-03 は test-agents-structure.sh のドリフト検出 (TC-34) をエンドツーエンドで検証するメタテスト。
現状は意図した TC-34 ではなく TC-22 (invalid model value) で exit 1 が発生しており、
TC-03 は "正しい理由で失敗している" という保証がない。

### 設計方針

**修正対象**: `tests/test-hooks-structure.sh` L42-70 (TC-03 の temp ファイル生成部分のみ)
**変更不要**: `tests/test-agents-structure.sh` (TC-34 のロジックはそのまま)

#### 変更1: temp agent の model 値修正

```diff
- model: claude-sonnet-4-5-20250929
+ model: sonnet
```

理由: `sonnet` は TC-22 の `^(opus|sonnet|haiku)$` にマッチする有効値。
TC-22 を通過させ、TC-34 でのみ検出されるようにする。

#### 変更2: temp steps file の Task() パターン修正

現在 (TC-34 にマッチしない):
```
Task(
  name="test-drift-agent",
  model="claude-opus-3-7-20250219",
  instructions="Test instructions"
)
```

修正後 (TC-34 の grep パターンに準拠):
```
Task(subagent_type: "dev-crew:test-drift-agent", model: "opus", prompt: "...")
```

理由:
- TC-34 の grep パターン: `Task([^)]*subagent_type:[[:space:]]*"dev-crew:[^"]*"[^)]*model:[[:space:]]*"[^"]*"`
- `subagent_type: "dev-crew:<name>"` 形式が必須 (既存 steps ファイルと同一形式)
- 単一行で記述 (grep は行単位マッチ)
- model 値を `"opus"` にし、frontmatter の `sonnet` との不一致を作る

#### ドリフト検出フロー (修正後)

1. temp agent `model: sonnet` → TC-22 PASS (有効値)
2. temp steps `subagent_type: "dev-crew:test-drift-agent", model: "opus"` → TC-34 の grep にマッチ
3. TC-34: agent frontmatter `sonnet` != steps `opus` → FAIL (ドリフト検出)
4. test-agents-structure.sh exit 1 → TC-03 PASS (正しい理由で失敗)

### ファイル構成

| ファイル | 変更 | 内容 |
|---------|------|------|
| `tests/test-hooks-structure.sh` | 修正 | L42-70: temp agent model + temp steps Task() 形式 |
| `tests/test-agents-structure.sh` | 変更なし | TC-34 ロジックはそのまま |

### リスク

- 低: 修正は TC-03 の temp ファイル内容のみ。TC-34 のロジックには触れない
- temp agent が `skills/test-drift-skill/steps-test-drift.md` に配置されるため TC-34 のグロブ `$BASE_DIR/skills/*/steps-*.md` にマッチする (確認済み)

## RED

### Current State Verification

**Date**: 2026-02-16 18:00

#### Step 1: TC-03 Currently Passes (Wrong Reason)

```bash
bash tests/test-hooks-structure.sh
```

Result:
```
TC-01: hooks.json contains test-agents-structure.sh entry
  PASS test-agents-structure.sh entry found in PreCommit hooks

TC-02: test-agents-structure.sh executes successfully
  PASS test-agents-structure.sh executed successfully (exit code 0)

TC-03: test-agents-structure.sh detects model drift (exit code 1)
  PASS test-agents-structure.sh detected model drift (exit code 1)

=== Summary ===
PASS: 3
FAIL: 0
```

✅ TC-03 currently passes, but we need to verify WHY it passes.

#### Step 2: Actual Failure Point (TC-22, NOT TC-34)

Manually created temp files matching TC-03's current implementation:

**temp agent**: `agents/test-drift-agent.md`
```yaml
model: claude-sonnet-4-5-20250929
```

**temp steps**: `skills/test-drift-skill/steps-test-drift.md`
```
Task(
  name="test-drift-agent",
  model="claude-opus-3-7-20250219",
  instructions="Test instructions"
)
```

Ran `test-agents-structure.sh` directly:

```
TC-22: 'model' value validation
  FAIL TC-22: test-drift-agent.md has invalid model 'claude-sonnet-4-5-20250929'
              (expected: opus|sonnet|haiku)

TC-34: Model drift detection (frontmatter vs steps-*.md)
  PASS TC-34: No model drift detected (frontmatter matches steps-*.md)
```

**Key Findings**:
1. ❌ Test fails at **TC-22** (invalid model value), NOT TC-34 (drift detection)
2. ✅ TC-34 shows **PASS** (temp steps file format doesn't match TC-34's grep pattern)
3. ❌ Current TC-03 gets exit code 1 from TC-22, not from TC-34 as intended

### RED State Definition

**Current behavior**: TC-03 passes because it sees exit code 1, but the failure is at the wrong validation stage.

**Expected behavior**: TC-03 should pass because TC-34 detects model drift (frontmatter vs steps mismatch).

**RED state confirmed**:
- ✅ Test executes (TC-03 passes)
- ❌ Test validates the wrong condition (TC-22 instead of TC-34)
- ❌ Test precision is insufficient (false positive)

**No code changes made** (RED phase: verification only).

### TC-34 Grep Pattern Analysis

**Pattern** (L309 of test-agents-structure.sh):
```bash
grep -o 'Task([^)]*subagent_type:[[:space:]]*"dev-crew:[^"]*"[^)]*model:[[:space:]]*"[^"]*"'
```

**Requirements for matching**:
1. Must be a **single line** (grep processes line-by-line)
2. Must contain `subagent_type: "dev-crew:<agent-name>"`
3. Must contain `model: "<value>"`
4. Both parameters must be within the same Task() call on the same line

**Current temp steps (does NOT match)**:
```
Task(
  name="test-drift-agent",
  model="claude-opus-3-7-20250219",
  instructions="Test instructions"
)
```

Problems:
- Multi-line format (grep won't match)
- Uses `name=` instead of `subagent_type: "dev-crew:..."`
- Missing the required `dev-crew:` prefix

**Required temp steps format (matches TC-34)**:
```
Task(subagent_type: "dev-crew:test-drift-agent", model: "opus", prompt: "...")
```

This must be a single line to match the grep pattern.

Next phase (GREEN): Modify `tests/test-hooks-structure.sh` L42-70 to:
1. Change temp agent model to `sonnet` (passes TC-22)
2. Change temp steps to single-line format: `Task(subagent_type: "dev-crew:test-drift-agent", model: "opus", prompt: "...")`
3. Create actual drift (frontmatter `sonnet` vs steps `opus`)
4. TC-34 will detect drift and fail, TC-03 will see exit 1 and pass (correct reason)

## GREEN

### Implementation

**Date**: 2026-02-16 18:15

#### Change 1: Temp Agent Model Value (L46)

```diff
- model: claude-sonnet-4-5-20250929
+ model: sonnet
```

**Rationale**: `sonnet` is a valid value matching TC-22's regex `^(opus|sonnet|haiku)$`. This allows TC-22 to PASS and ensures TC-34 is the only test that detects the drift.

#### Change 2: Temp Steps Task() Format (L58-70)

**Before** (multi-line, no subagent_type prefix, TC-34 grep pattern did NOT match):
```
cat > "$TEMP_STEPS" <<'EOF'
# Test Drift Steps

Task() call with drifted model:

```
Task(
  name="test-drift-agent",
  model="claude-opus-3-7-20250219",  # This drifts from frontmatter
  instructions="Test instructions"
)
```
EOF
```

**After** (single-line, subagent_type prefix, TC-34 grep pattern matches):
```
cat > "$TEMP_STEPS" <<'EOF'
# Test Drift Steps

Task(subagent_type: "dev-crew:test-drift-agent", model: "opus", prompt: "Test instructions")
EOF
```

**Rationale**:
- TC-34 grep pattern: `Task([^)]*subagent_type:[[:space:]]*"dev-crew:[^"]*"[^)]*model:[[:space:]]*"[^"]*"`
- Requires `subagent_type: "dev-crew:<name>"` format
- Must be single-line (grep processes line-by-line)
- Model `"opus"` mismatches frontmatter `sonnet` → drift detected

### Test Results

#### TC-03 Test Execution

```bash
bash tests/test-hooks-structure.sh
```

Result:
```
TC-01: hooks.json contains test-agents-structure.sh entry
  PASS test-agents-structure.sh entry found in PreCommit hooks

TC-02: test-agents-structure.sh executes successfully
  PASS test-agents-structure.sh executed successfully (exit code 0)

TC-03: test-agents-structure.sh detects model drift (exit code 1)
  PASS test-agents-structure.sh detected model drift (exit code 1)

=== Summary ===
PASS: 3
FAIL: 0
```

✅ All test-hooks-structure.sh tests PASS.

#### TC-03 Drift Detection Verification

Manually verified the drift detection flow:
1. Temp agent `model: sonnet` → TC-22 PASS (valid value)
2. Temp steps `Task(subagent_type: "dev-crew:test-drift-agent", model: "opus", ...)` → TC-34 grep matches
3. TC-34 extracts: frontmatter `sonnet` != steps `opus` → FAIL (drift detected)
4. test-agents-structure.sh exit 1 → TC-03 PASS (correct reason)

#### Baseline Test (No Temp Files)

```bash
bash tests/test-agents-structure.sh
```

Result:
```
TC-06/07: Agent frontmatter validation
  PASS TC-06: All agents have 'name' frontmatter
  PASS TC-07: All agents have 'description' frontmatter

TC-13: [Negative] detects missing frontmatter
  PASS Correctly detected missing frontmatter

TC-21: All agents have 'model' frontmatter
  PASS TC-21: All 34 agents have 'model' frontmatter

TC-22: 'model' value validation
  PASS TC-22: All agent 'model' values are valid (opus|sonnet|haiku)

TC-23: socrates.md model validation
  PASS TC-23: socrates.md has model 'opus'

TC-24: guidelines-reviewer.md model validation
  PASS TC-24: guidelines-reviewer.md has model 'haiku'

TC-25: scope-reviewer.md model validation
  PASS TC-25: scope-reviewer.md has model 'sonnet'

TC-26: architect.md model validation
  PASS TC-26: architect.md has model 'sonnet'

TC-27: Reference file exclusion
  PASS TC-27: Reference files (*-reference.md) excluded from model checks

TC-28: [Negative] Detect missing 'model' field
  PASS TC-28: Correctly detected missing 'model' field

TC-29: [Negative] Detect invalid 'model' value
  PASS TC-29: Correctly detected invalid model value 'gpt-4'

TC-30: orchestrate/steps-teams.md model parameter
  PASS TC-30: steps-teams.md contains 'model:' parameter in Task() calls

TC-31: orchestrate/steps-subagent.md model parameter
  PASS TC-31: steps-subagent.md contains 'model:' parameter in Task() calls

TC-32: plan-review/steps-subagent.md guidelines-reviewer model
  PASS TC-32: guidelines-reviewer not used in plan-review (skip)

TC-33: quality-gate/steps-subagent.md guidelines-reviewer model
  PASS TC-33: quality-gate guidelines-reviewer has model 'haiku'

TC-34: Model drift detection (frontmatter vs steps-*.md)
  PASS TC-34: No model drift detected (frontmatter matches steps-*.md)

=== Summary ===
PASS: 17 / FAIL: 0 / TOTAL: 17
```

✅ All test-agents-structure.sh tests PASS without temp files (no regression).

### Test List Status

#### DONE
- [x] TC-A: temp agent の model 値が TC-22 を通過する (✅ `model: sonnet` は `^(opus|sonnet|haiku)$` にマッチ)
- [x] TC-B: temp steps file が TC-34 の grep パターンにマッチする (✅ `Task(subagent_type: "dev-crew:test-drift-agent", model: "opus", ...)` 形式)
- [x] TC-C: TC-34 がドリフトを検出する (✅ frontmatter `sonnet` != steps `opus` → FAIL)
- [x] TC-D: TC-03 の exit code 1 が TC-34 由来であることを確認 (✅ TC-22 は PASS, TC-34 は FAIL, exit 1)
- [x] TC-E: temp ファイル削除後、test-agents-structure.sh が exit 0 で全 PASS (✅ 17/17 tests PASS)
- [x] TC-F: test-hooks-structure.sh 全体が PASS (✅ 3/3 tests PASS)

#### TODO
(none)

### Summary

Modified `tests/test-hooks-structure.sh` TC-03 to:
1. Use valid model value `sonnet` in temp agent (passes TC-22)
2. Use single-line Task() format with `subagent_type: "dev-crew:..."` in temp steps (matches TC-34 grep)
3. Create intentional drift (`sonnet` vs `opus`) detected by TC-34

**Result**: TC-03 now correctly validates drift detection (TC-34), not invalid model value (TC-22).

All tests PASS:
- ✅ test-hooks-structure.sh: 3/3
- ✅ test-agents-structure.sh: 17/17

## REFACTOR

スキップ（変更が test-hooks-structure.sh の temp ファイル内容 2箇所のみ。コード 86行でクリーンな構造、リファクタリング対象なし）

## REVIEW

### quality-gate 結果: PASS (max score: 35)

| Reviewer | Score | Verdict |
|----------|-------|---------|
| correctness | 0 | PASS |
| security | 0 | PASS |
| risk | 5 | PASS |
| guidelines | 10 | PASS |
| architecture | 15 | PASS |
| performance | 35 | PASS |

Performance reviewer 指摘 (改善提案、スコープ外):
- duplicate scan: TC-02 と TC-03 で test-agents-structure.sh を 2 回実行 (~0.78s 重複)
- trap handler: temp ファイルの中断時クリーンアップ

## DISCOVERED

- test-hooks-structure.sh の trap handler 追加 + duplicate scan 最適化 (performance reviewer 指摘)

## COMMIT

- tests/test-hooks-structure.sh: TC-03 temp ファイル修正 (model値 + Task()形式)
- docs/cycles/20260216_1800_tc03-test-precision.md: cycle doc
