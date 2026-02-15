---
feature: orchestrate-phase-compact
cycle: 20260215_1700
phase: DONE
created: 2026-02-15 17:00
updated: 2026-02-15 17:00
---

# orchestrate skill - phase-compact integration

## Scope Definition

### In Scope
- [ ] steps-teams.md: 各フェーズ遷移時にPhase Summary永続化 + subagentトークン記録
- [ ] steps-subagent.md: Skill()チェーン → Task()委譲に変更（コンテキスト分離）
- [ ] steps-subagent.md: Block境界でPhase Summary永続化 + subagentトークン記録
- [ ] 構造バリデーションテスト通過

### Out of Scope
- SKILL.md本体の変更（手順詳細はsteps-*.mdに委譲済み）
- phase-compact skill自体の機能変更
- Agent定義へのskills preload追加（A+Bパターン、別Issue #14で検証）

### Files to Change (target: 10 or less)
- skills/orchestrate/steps-teams.md (edit)
- skills/orchestrate/steps-subagent.md (edit)
- tests/test-orchestrate-compact.sh (new)

## Environment

### Scope
- Layer: Markdown (skill definition + bash test)
- Plugin: dev-crew
- Risk: 10 (PASS)

### Runtime
- Node: v22.17.0
- Python: 3.13.3
- OS: Darwin 25.2.0

### Dependencies (key packages)
- Claude Code Plugin system
- phase-compact skill (既存)

## Context & Dependencies

### Reference Documents
- skills/orchestrate/SKILL.md - オーケストレータ本体
- skills/orchestrate/steps-teams.md - Agent Teams モード手順
- skills/orchestrate/steps-subagent.md - Subagent Chain モード手順
- skills/phase-compact/SKILL.md - phase-compact スキル定義

### Dependent Features
- phase-compact skill (完了済み, #2)
- structure validation tests (完了済み, #1)

### Related Issues/PRs
- Issue #3: feat: orchestrate skill - phase-compact integration
- Issue #14: research: A+Bパターン検証（skills preload + Skill呼び出し二重ロード検証）

## Test List

### TODO

#### steps-teams.md: Phase Summary永続化
- [ ] TC-01: PLAN→RED 間に Phase Summary 永続化手順がある
- [ ] TC-02: RED→GREEN 間に Phase Summary 永続化手順がある
- [ ] TC-03: GREEN→REFACTOR 間に Phase Summary 永続化手順がある
- [ ] TC-04: REFACTOR→REVIEW 間に Phase Summary 永続化手順がある
- [ ] TC-05: REVIEW→COMMIT 間に Phase Summary 永続化手順がある
- [ ] TC-06: COMMIT 後に Phase Summary 永続化がない（不要）
- [ ] TC-07: Phase Summary に Subagent 行（agent_id, tokens）の記録指示がある

#### steps-subagent.md: Task()委譲 + コンテキスト分離
- [ ] TC-08: Block1 で Task() による subagent 委譲パターンがある（Skill()直接呼び出しでない）
- [ ] TC-09: Block2 で Task() による subagent 委譲パターンがある
- [ ] TC-10: Block1→Block2 間に Phase Summary 永続化手順がある
- [ ] TC-11: Block2→Block3 間に Phase Summary 永続化手順がある
- [ ] TC-12: Phase Summary に Subagent 行（agent_id, tokens）の記録指示がある

#### 構造検証
- [ ] TC-13: SKILL.md が 100 行以内を維持
- [ ] TC-14: 既存構造バリデーションテスト通過

### WIP
(none)

### DISCOVERED
(none)

### DONE
(none)

## Implementation Notes

### Goal
orchestrateスキルのフェーズ遷移時にphase-compactを自動呼び出しし、
Phase Summaryの永続化 -> compact -> 復元フローを組み込む。

### Background
phase-compact skill (#2) が完了済み。orchestrate skill はフェーズ遷移を管理するが、
現状phase-compactへの呼び出しがない。コンテキスト膨張によるトークン浪費を防ぐため、
各フェーズ遷移時にPhase Summaryを永続化し、コンテキスト圧縮の機会を設ける。

### Design Approach

**コンテキスト分離戦略（/compact代替）:**
- Subagentコンテキスト分離パターンを採用
- 各フェーズをTask()でsubagentに委譲 → 重い作業はsubagent内で実行
- PdMには結果サマリーのみ返却 → コンテキスト自然圧縮
- `/compact` の手動実行は不要

**Phase Summary記録:**
- 各フェーズ遷移時にPdMがPhase SummaryをCycle docに永続化
- Phase Summaryに `**Subagent**: agent_id={id}, tokens={total_tokens}` を記録
- A+Bパターン検証時のトークン比較データとして活用（Issue #14）

**Agent Teams mode (steps-teams.md):**
- 5 compaction points: PLAN→RED, RED→GREEN, GREEN→REFACTOR, REFACTOR→REVIEW, REVIEW→COMMIT
- 既にTask()でteammate起動済み → Phase Summary永続化を各遷移に追加
- subagentトークン数を記録

**Subagent Chain mode (steps-subagent.md):**
- Skill()チェーン → Task()委譲に変更（コンテキスト分離の実現）
- Task(subagent_type: "dev-crew:architect", prompt: "Cycle doc: X. Skill(dev-crew:plan)実行")
- 各Block内のフェーズもTask()で委譲（auto-transitionを廃止、PdMが全遷移を制御）
- Block境界でPhase Summary永続化 + subagentトークン記録

**COMMIT 後は不要**: phase-compact reference に記載の通り、次サイクルは新しい INIT で開始。

**Approach A (今回実装):**
- PdMがTask()でsubagent起動、subagent内でSkill()呼び出し
- agent定義・skill定義の変更不要

**Approach A+B (Issue #14で検証):**
- Agent定義にskills preload追加 + subagent内でSkill()呼び出し
- 二重ロードの有無をPhase Summaryのトークン数で検証

## Progress Log

### 2026-02-15 17:00 - INIT
- Cycle doc created
- Issue #3 (P0, phase-2), 依存先 #1, #2 は完了済み
- Risk: 10 (PASS)
- 対象: steps-teams.md + steps-subagent.md (edit) + テスト (new)

### 2026-02-15 17:05 - PLAN (v1)
- 簡易設計（Risk PASS）: Test List 10ケース
- Agent Teams: 5 compaction points（全フェーズ遷移）
- Subagent Chain: 2 compaction points（Block境界のみ）
- COMMIT後のphase-compactは不要（reference.md準拠）

### 2026-02-15 17:10 - plan-review BLOCK (85)
- scope: 25 PASS, architecture: 15 PASS, risk: 15 PASS, product: 25 PASS
- usability: 85 BLOCK - phase-compactの/compact手動要求がorchestrate自律フローを中断
- Socrates Protocol発動: Approach A/B分析、二重ロード未検証の指摘

### 2026-02-15 17:20 - PLAN (v2, revised)
- /compact代替: Subagentコンテキスト分離パターン採用（Task()委譲）
- Subagent ChainモードをSkill()チェーン→Task()委譲に変更
- Phase SummaryにSubagent行（agent_id, tokens）追加（A+B検証用データ）
- Approach A（Task+Skill指示）で実装、A+BはIssue #14で検証
- Test List 14ケースに拡張

### 2026-02-15 17:30 - RED
- tests/test-orchestrate-compact.sh 作成（14テスト）
- RED状態確認: 11 FAIL / 3 PASS
- FAIL: TC-01~05(teams Phase Summary), TC-07(teams Subagent行), TC-08~12(subagent Task委譲+Phase Summary)
- PASS: TC-06(COMMIT後なし), TC-13(SKILL.md行数72), TC-14(既存テスト)

### 2026-02-15 17:40 - REVIEW
- quality-gate BLOCK (85): risk-reviewer「breaking change, fallback未定義」
- 対応: steps-subagent.md に Fallback セクション追加 + Phase Summary 非対称の意図コメント追記
- 再テスト: 14/14 PASS + 全67テスト PASS
- DISCOVERED: なし

### 2026-02-15 17:35 - GREEN
- steps-teams.md: 5箇所にPhase Summary永続化ブロック追加 + Subagent行フォーマット
- steps-subagent.md: Skill()チェーン→Task()委譲に全面改修 + Phase Summary 2箇所
- 全14テスト PASS + 既存5テスト PASS

---

## Next Steps

1. [Done] INIT
2. [Done] PLAN
3. [Done] RED
4. [Done] GREEN
5. [Done] REFACTOR
6. [Done] REVIEW
7. [Done] COMMIT <- Complete
