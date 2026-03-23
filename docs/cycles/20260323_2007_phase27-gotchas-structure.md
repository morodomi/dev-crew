---
feature: phase27-gotchas-structure
cycle: 20260323_2007
phase: DONE
complexity: medium
test_count: 8
risk_level: low
codex_session_id: ""
created: 2026-03-23 20:07
updated: 2026-03-23 20:07
---

# v2.6 Phase 27: Gotchas セクション体系化

## Scope Definition

### In Scope
- [ ] `tests/test-gotchas-structure.sh` 新規作成: 6スキルの Gotchas 存在確認 (T-01〜T-08)
- [ ] `skills/orchestrate/reference.md` 末尾に `## Gotchas` テーブル追加 (5項目)
- [ ] `skills/spec/reference.md` 末尾に `## Gotchas` テーブル追加 (5項目)
- [ ] `skills/red/reference.md` 末尾に `## Gotchas` テーブル追加 (5項目)
- [ ] `skills/green/reference.md` 末尾に `## Gotchas` テーブル追加 (5項目)
- [ ] `skills/review/reference.md` 末尾に `## Gotchas` テーブル追加 (5項目)
- [ ] `skills/commit/reference.md` 末尾に `## Gotchas` テーブル追加 (5項目)
- [ ] `docs/known-gotchas.md` evolve 連携規約セクション追加

### Out of Scope
- 上記6スキル以外のスキルへのGotchas追加
- SKILL.md の変更
- Gotchas コンテンツの実装ロジック変更

### Files to Change (target: 10 or less)
- `tests/test-gotchas-structure.sh` (new)
- `skills/orchestrate/reference.md` (edit: append)
- `skills/spec/reference.md` (edit: append)
- `skills/red/reference.md` (edit: append)
- `skills/green/reference.md` (edit: append)
- `skills/review/reference.md` (edit: append)
- `skills/commit/reference.md` (edit: append)
- `docs/known-gotchas.md` (edit: append)

## Environment

### Scope
- Layer: Documentation (Markdown + shell test)
- Plugin: dev-crew (all 6 core TDD skills)
- Risk: 5 (PASS)

### Runtime
- Language: bash (test script), Markdown (content)

### Dependencies (key packages)
- N/A (ドキュメント追記 + テストスクリプトのみ)

### Risk Interview (BLOCK only)
- N/A (PASS判定)

## Context & Dependencies

### Reference Documents
- Anthropic Skills Best Practices (Thariq, 2026-03): Gotchasセクションは「スキル内で最もシグナルが高いコンテンツ」
- `docs/known-gotchas.md`: 既存のクロスカッティングGotchas集
- ROADMAP.md Phase 27 - Gotchasセクション体系化

### Dependent Features
- Phase 25: Dynamic content injection (20260323_0904_phase25-dynamic-content-apply.md)
- Phase 26: no-verify-guard hook (20260323_1651_onboard-no-verify-hook.md)

### Related Issues/PRs
- v2.6 Phase 27 (plan file: parsed-seeking-steele.md)

## Gotchas コンテンツ (plan定義済み)

### orchestrate
| # | 症状 | 原因 | 対策 |
|---|------|------|------|
| G-01 | sync-plan/plan-reviewスキップ | Post-Approve Action違反 | Block 0でProgress Log確認 |
| G-02 | WARN/BLOCKで自動再試行ループ | 自動進行ロジック | Socrates Protocol経由で人間判断 |
| G-03 | Codex session ID stale | セッション期限切れ | 新規セッション作成でretry |
| G-04 | post-approve-gateフラグ残存 | orchestrate起動前にフラグ未解除 | Block 0冒頭のrm -f実行 |
| G-05 | PdMが直接実装コード記述 | 委譲ルール違反 | 「やらないこと」テーブル参照 |

### spec
| # | 症状 | 原因 | 対策 |
|---|------|------|------|
| G-01 | plan mode外で実行エラー | spec はplan mode専用 | 案内して終了 |
| G-02 | Post-Approve Actionセクション書き忘れ | auto-orchestrate不発 | Step 6テンプレート確認 |
| G-03 | 既存cycle無視で新規spec開始 | Step 3チェックスキップ | ls -t docs/cycles/*.md |
| G-04 | CONSTITUTION整合性チェック省略 | Step 7.1の省略 | Upstream Referencesに記録 |
| G-05 | Version Gate失敗 | onboard未実行 | onboard先行実行案内 |

### red
| # | 症状 | 原因 | 対策 |
|---|------|------|------|
| G-01 | テストが最初からPASS | 実装コード既存 or assertion不正 | Verification Gate確認 |
| G-02 | Pre-RED Gateでsync-plan未検出 | Progress Log表記揺れ | SYNC-PLANの表記確認 |
| G-03 | grep -cで0件時スクリプト中断 | grep exit code 1 + set -e | `grep -c ... \|\| echo "0"` |
| G-04 | trivialでStage 2 Review実行 | Complexity Gate見落とし | trivial: Stage 2 skip確認 |
| G-05 | exspec非対応言語でBLOCK | 言語マッピング未設定 | マッピングテーブルでSKIP確認 |

### green
| # | 症状 | 原因 | 対策 |
|---|------|------|------|
| G-01 | 複数workerが同一ファイル競合 | 依存関係分析漏れ | 同一ファイルは同一workerに集約 |
| G-02 | テスト要件超の実装(YAGNI違反) | GREEN段階で機能追加 | テスト要求外は実装しない |
| G-03 | 全worker失敗でリトライループ | 設計自体に問題 | 全失敗時はPLANに戻る |
| G-04 | REFACTORの作業をGREENで実行 | フェーズ責務混同 | ハードコード許容、REFACTORで改善 |
| G-05 | Codex委譲時にGate 2忘れ | codex_mode: full時のスキップ | steps-codex.mdのGate 2確認 |

### review
| # | 症状 | 原因 | 対策 |
|---|------|------|------|
| G-01 | mode判定誤り(planをcodeで実行) | 引数なしはcode(default) | --plan/--codeを明示指定 |
| G-02 | REFACTOR記録未検出 | Progress Log表記揺れ | grep -qiEでcase insensitive |
| G-03 | LOW riskで全agent起動 | Risk-based scaling不適用 | risk-classifier.sh判定に従う |
| G-04 | Codex competitive review未試行 | CLAUDE.mdルール忘れ | feedback記録参照 |
| G-05 | DISCOVERED issue起票忘れ | Step 7スキップ | review完了前にDISCOVERED確認 |

### commit
| # | 症状 | 原因 | 対策 |
|---|------|------|------|
| G-01 | Test List未完了でBLOCK | TODO/WIP残項目 | Completion Gate。DISCOVEREDはreviewに戻す |
| G-02 | Progress Log不完全でBLOCK | フェーズスキップ | 4フェーズ全記録確認 |
| G-03 | STATUS.md Test Scripts数不一致 | テスト追加後未更新 | Step 3ドキュメント更新で同期 |
| G-04 | --no-verifyでhookバイパス | 禁止コマンド | no-verify-guard.shがBLOCK |
| G-05 | 手動バージョン更新・タグ作成 | release-skill未使用 | 必ずrelease-skillを使う |

## Test List

### TODO
- [ ] T-01: Given skills/orchestrate/reference.md, When grepで "## Gotchas" を検索, Then マッチすること
- [ ] T-02: Given skills/spec/reference.md, When grepで "## Gotchas" を検索, Then マッチすること
- [ ] T-03: Given skills/red/reference.md, When grepで "## Gotchas" を検索, Then マッチすること
- [ ] T-04: Given skills/green/reference.md, When grepで "## Gotchas" を検索, Then マッチすること
- [ ] T-05: Given skills/review/reference.md, When grepで "## Gotchas" を検索, Then マッチすること
- [ ] T-06: Given skills/commit/reference.md, When grepで "## Gotchas" を検索, Then マッチすること
- [ ] T-07: Given 各スキルのreference.md, When Gotchasセクション以降を確認, Then テーブル行(|)が最低1行存在すること
- [ ] T-08: [Negative] Given Gotchas未追加のreference.md (一時ファイル), When test-gotchas-structure.sh を実行, Then FAILすること

### WIP
(none)

### DISCOVERED
(none)

### DONE
(none)

## Implementation Notes

### Goal
dev-crewの29スキル中0件だったGotchasセクションを、高頻度6スキル(orchestrate/spec/red/green/review/commit)から体系的に追加する。learn/evolveパイプラインの出力先としても機能させる。

### Background
Anthropic Skills Best Practices (Thariq, 2026-03) でGotchasセクションを「スキル内で最もシグナルが高いコンテンツ」と位置付け。既存の `docs/known-gotchas.md` はクロスカッティングな問題を扱うが、スキル固有のGotchasは各reference.mdに収録するのが適切。

### Design Approach
1. `tests/test-gotchas-structure.sh` を先に作成してREDを確立
2. 各reference.md末尾にplanで定義済みのGotchasテーブルを追記
3. `docs/known-gotchas.md` にevolve連携規約セクションを追加
4. 形式: `## Gotchas` 見出し + `| # | 症状 | 原因 | 対策 |` テーブル

### Gotchas形式規約
```markdown
## Gotchas

| # | 症状 | 原因 | 対策 |
|---|------|------|------|
| G-01 | ... | ... | ... |
```
- 軽量テーブル形式（1行で参照可能、LLMコンテキスト効率）
- スキル固有パターンのみ。クロスカッティングは docs/known-gotchas.md に残す

### evolve連携規約
1. evolveが新instinctをスキル固有Gotchasに追記 → `reference.md ## Gotchas` テーブルに行追加
2. G-番号は連番 (既存最大 + 1)
3. スコープ判定: 「このスキルでしか発生しない」→ スキルGotchas、「複数スキルに影響」→ known-gotchas.md

## Progress Log

### 2026-03-23 20:07 - KICKOFF
- Cycle doc created
- Design Review Gate: PASS (スコア5)
- 全6対象ファイル存在確認済み。test-gotchas-structure.shは新規作成要
- known-gotchas.md存在確認済み。evolve連携規約追記対象
- Gotchasコンテンツはplanに完全定義済み。実装時はplan参照で直接追記可能

### 2026-03-23 20:15 - RED
- test-gotchas-structure.sh 新規作成 (T-01~T-08)
- FAIL: 12 / PASS: 1 (T-08 negative test のみ PASS)
- Phase completed

### 2026-03-23 20:20 - GREEN
- 6スキルの reference.md 末尾に ## Gotchas テーブル追加
- docs/known-gotchas.md に evolve 連携規約セクション追加
- 8/8 PASS
- Phase completed

### 2026-03-23 20:25 - REFACTOR
- チェックリスト7項目確認: 改善不要
- Verification Gate: 8/8 PASS
- Phase completed

### 2026-03-23 20:35 - REVIEW
- Security: PASS (8), Correctness: PASS (22), Maintainability: PASS (22)
- Codex plan review: WARN (コンテンツ正確性指摘あり)
- 修正: commit G-03(BLOCK→警告), commit G-05(release-skill→Holdings側), review G-04(参照先具体化), red G-02(原因修正), evolve連携規約(手動追記明記+G-番号スコープ明記), T-07 else分岐追加
- 修正後テスト: 8/8 PASS
- Phase completed

### 2026-03-23 20:40 - COMMIT
- STATUS.md: Test Scripts 93→94, Phase 27完了記録
- Cycle doc: phase DONE
- Phase completed

---

## Next Steps

1. [Done] KICKOFF
2. [ ] RED
3. [ ] GREEN
4. [ ] REFACTOR
5. [ ] REVIEW
6. [ ] COMMIT
