---
feature: gate-active-cycle-fix
cycle: 20260702_1930
phase: COMMIT
complexity: standard
test_count: 9
risk_level: medium
retro_status: resolved
codex_session_id: ""
created: 2026-07-02 19:30
updated: 2026-07-03 12:10
---

# Gate Active Cycle Fix — pre-commit/pre-red gate の ACTIVE_CYCLE 選択修正（issue #145）

## Scope Definition

### In Scope
- [ ] `scripts/gates/pre-commit-gate.sh` L24-41 の引数解釈 + ACTIVE_CYCLE 選択ロジックを新契約に書き換え（$1 polymorphic: `.md` ファイル=明示指定 / ディレクトリ=latest-updated non-DONE 選択 / それ以外=BLOCK invalid argument。後続チェック L43-90 は不変）
- [ ] `scripts/gates/pre-red-gate.sh` L24-33 に同型の書き換え
- [ ] `tests/test-pre-commit-gate.sh` へ TC 追加（新規ファイル禁止、count 112 維持）: 複数 non-DONE で latest-updated 選択 / `$1` 明示指定 / `$1` 不在パス BLOCK / updated 形式混在の決定論
- [ ] `tests/test-pre-red-gate.sh` へ同型 TC 追加（複数 non-DONE + 明示指定）
- [ ] `rules/integration-verification.md` + `.claude/rules/integration-verification.md`（byte-identical mirror）— L29 の実行例を明示指定形式の正式な使い方として更新

### Out of Scope
- 旧 non-DONE 15 doc の phase を DONE へ一括遷移する cleanup（Reason: COMMIT→DONE 遷移の責務が workflow に未定義という根本問題を含む。別 cycle へ defer。DISCOVERED で起票）
- parallel スキルの削除/作り直し判断（Reason: ユーザー確認待ち。本 cycle のスコープ外）
- #143 inverse contract / test-patterns rule 実装 / RED false-pass step（Reason: 次の test hardening cycle に束ねる）

### Files to Change（全量、plan 承認時点。独自判断で追加・削除しないこと）
1. `scripts/gates/pre-commit-gate.sh` — L24-41 の引数解釈 + 選択ロジックを新契約に書き換え（後続チェック L43-90 は不変）
2. `scripts/gates/pre-red-gate.sh` — L24-33 に同型の書き換え
3. `tests/test-pre-commit-gate.sh` — TC 追加（新規ファイルは作らない、count 112 維持）:
   - 複数 non-DONE fixture（古い COMMIT doc + 新しい REVIEW doc）で latest-updated が選ばれる
   - `$1` = cycle doc パス明示指定でその doc だけ検査される
   - `$1` = 不在パスで invalid argument BLOCK
   - updated 日付のみ / 日時あり混在で決定論的に選択される
4. `tests/test-pre-red-gate.sh` — 同型 TC 追加（複数 non-DONE + 明示指定）
5. `rules/integration-verification.md` + `.claude/rules/integration-verification.md`（byte-identical mirror）— L29 の実行例を新契約の正式な使い方として明記（`$cycle_doc` 明示指定を推奨形に）
6. `docs/cycles/20260702_1930_gate-active-cycle-fix.md` — Cycle doc（本ファイル）

count 変更なし（STATUS.md / test-codify-insight.sh TC-19 は触らない）。STATUS.md は COMMIT 時の Completed 行追記のみ。

## Environment

### Scope
- Layer: Backend（bash gate scripts + bash test scripts + doc mirror）
- Plugin: dev-crew 内 bash/doc project（integration-verification.md の project type 分類に準拠）
- Risk: 40（WARN）

### Runtime
- Bash（macOS zsh 実行環境、スクリプト自体は `#!/bin/bash` + `set -euo pipefail`）

### Dependencies (key packages)
- なし（awk / grep / sed / mktemp のみ、標準 POSIX/GNU 互換ツール）

### Risk Interview (BLOCK only)
- 該当なし（Risk ~40 は WARN 帯であり BLOCK 帯（60+）に未到達のため、Risk Interview は不要）

## Context & Dependencies

### Reference Documents
- `rules/integration-verification.md` — L29 の実行例が現行 project_root 契約と矛盾しており本 cycle で解消する対象
- `.claude/rules/multi-file-consistency.md` — 「deterministic gate は case 文で期待値を enumerate し、それ以外は明示的に reject する」原則。新契約の `$1` 三分岐（.md file / directory / else→BLOCK）はこの原則に準拠
- `.claude/rules/plan-discipline.md` — baseline 実測・逆向き契約 sweep の規律。本 plan は Explore 調査で該当箇所を実測済み
- CONSTITUTION.md 原則6「決定論的プロセス保証」— pre-commit-gate.sh / pre-red-gate.sh の存在意義そのもの

### Dependent Features
- `scripts/gates/pre-commit-gate.sh` — 後続チェック（REVIEW log / Codex review / retro_status、L43-90）は `$ACTIVE_CYCLE` 変数を読むのみで選択ロジックの変更に影響されない
- `scripts/gates/pre-red-gate.sh` — 同様に sync-plan / Plan Review チェック（L40-50）は `$ACTIVE_CYCLE` を読むのみ
- gate script の呼び出し元: orchestrate / commit skill は言及のみで bash 実行する呼び出し元は存在しない（Explore 調査で確定）。唯一の実行例が `rules/integration-verification.md:29`

### Related Issues/PRs
- Issue #145: pre-commit-gate.sh の ACTIVE_CYCLE 選択が glob 先頭の non-DONE cycle を検査し、REVIEW を飛ばした COMMIT を機械的に BLOCK する gate の存在意義が実質無効化されているバグ
- Stacked on PR #146（feature/skill-inventory-cleanup、base: d6a3c91）

## Test List

### TODO
- [ ] TC-06: Given 既存 TC 全量（test-pre-commit-gate / -retro / test-pre-red-gate）+ full suite, When 一括実行, Then 112/112 で回帰なし（GREEN 後の VERIFY で実施）

### WIP
(none)

### DISCOVERED
(none)

### DONE
- [x] TC-01: Given 古い `phase: COMMIT`（updated 旧）と新しい `phase: COMMIT`（updated 新）の 2 doc を持つ fixture, When `pre-commit-gate.sh <fixture_root>` を実行, Then updated 最新の REVIEW doc が検査対象になる（REVIEW log 不足の BLOCK メッセージが新 doc 起因で出る） — test-pre-commit-gate.sh TC-08 として契約化（GREEN: rc=1、"20260601_0000_new" を出力に含み PASS）
- [x] TC-02: Given 検査対象 doc のパスを `$1` に直接指定, When gate 実行, Then その doc のみが検査され、他の non-DONE doc の状態に影響されない — test-pre-commit-gate.sh TC-09 / test-pre-red-gate.sh T-09 として契約化（GREEN: 明示 doc は new=BLOCK(1)/old=PASS(0) で PASS）
- [x] TC-03: Given `$1` に存在しないパス, When gate 実行, Then `BLOCK: invalid argument` 相当で exit 1 — test-pre-commit-gate.sh TC-10 として契約化（GREEN: rc=1 + "invalid" 文字列ありで PASS）
- [x] TC-04: Given updated が `YYYY-MM-DD`（時刻なし）と `YYYY-MM-DD HH:MM` の混在 fixture, When fallback 選択, Then lexicographic 最大が決定論的に選ばれる — tie-break として test-pre-commit-gate.sh TC-11 に具体化（updated 同値時の filename tail 選択、GREEN: b が選ばれ PASS）。明示 DONE doc の enumerate-and-reject は TC-12 で契約化（GREEN: doc 名を含む BLOCK メッセージで PASS）
- [x] TC-05: Given pre-red-gate に同型の複数 non-DONE fixture, When 実行, Then latest-updated doc が選ばれる + 明示指定モードが機能する — test-pre-red-gate.sh T-08（dir mode 選択）/ T-09（明示指定）として契約化（GREEN: 両方 PASS）
- [x] TC-09 (test-phase-gate.sh, F1 sweep): Given skills/red・green・refactor・commit・review/SKILL.md + orchestrate/steps-subagent.md・steps-teams.md の 7 ファイル, When 探索行を検査, Then 全ファイルが新スニペット（contiguous phrase `sort | tail -1 | cut -f2`）を使い `| head -1` が残存しない — test-phase-gate.sh TC-09 として契約化（GREEN: 7 ファイル全て新型で PASS）

## Implementation Notes

### Goal
`pre-commit-gate.sh` / `pre-red-gate.sh` の ACTIVE_CYCLE 選択ロジックを、glob 先頭の non-DONE cycle doc を機械的に選ぶ現行実装から、`updated` frontmatter 最新の doc を選ぶ（または `$1` で明示指定できる）新契約に書き換え、REVIEW を飛ばした COMMIT を機械的に BLOCK する gate の存在意義を回復する。

### Background
cycle 20260702_1200 の COMMIT 時に実測で露呈したバグ（issue #145）。`pre-commit-gate.sh` は glob（辞書=時系列）順で最初の non-DONE cycle doc を ACTIVE_CYCLE として検査するため、non-DONE doc が複数併存すると本来の対象 cycle を検査しない。実測: non-DONE 15件が滞留しており、現在 gate が検査するのは 2ヶ月前の `20260421_1809`（本来の対象は updated 最新の doc）。CONSTITUTION 原則6「決定論的プロセス保証」が実質無効化されている。

兄弟 gate `pre-red-gate.sh:24-33` にも完全同型のバグが存在し横展開が必須。後続チェック（REVIEW log / Codex review / retro_status）は全て `$ACTIVE_CYCLE` 変数を読むだけのため、修正は選択ロジックに閉じる。gate を bash 実行する呼び出し元は存在せず、唯一の実行例 `rules/integration-verification.md:29` は cycle doc パスを渡す想定で書かれており、現行の project_root 契約と矛盾している（cycle 20260702_1200 の VERIFY で誤用として実測発覚済み）。

### Design Approach

**選択ロジックの新契約（両 gate 共通）**: `$1` を polymorphic に解釈する。

| $1 | 挙動 |
|----|------|
| `.md` ファイルパス（実在） | その doc を ACTIVE_CYCLE として直接検査（明示指定モード）。`docs/cycles/` 配下であることは要求しない（fixture 互換） |
| ディレクトリ（実在、default `.`） | `$1/docs/cycles/*.md` の non-DONE から frontmatter `updated:` が lexicographic 最大の doc を選択。同値時は filename 降順（新しい cycle 番号優先）。updated 欠落 doc は `0000-00-00` 扱いで最古に |
| それ以外（不在パス等） | `BLOCK: invalid argument` で exit 1（multi-file-consistency の enumerate-and-reject 準拠） |

採用理由:
- 明示指定モードは決定論性が最大で、`rules/integration-verification.md:29` の既存記述（`$cycle_doc` を渡す）がそのまま正しくなる（文書と実装の矛盾解消）
- ディレクトリモードの latest-updated 選択は手動実行・後方互換用 fallback。updated は non-DONE 全 15件に存在することを実測確認済み
- 旧 doc 15件の phase を DONE に一括遷移する案は不採用（歴史的 doc の状態一括変更は別の意思決定。DISCOVERED で起票）

**逆向き契約 sweep（実測済み）**:
- gate script への参照: `rules/integration-verification.md:29`（+mirror）のみが実行例。`agents/sync-plan.md:143,155` は Progress Log header 互換性の説明で、選択ロジック変更の影響なし
- 既存 gate テスト（T-01〜TC-11）は全て単一 doc fixture + project_root 引数 → ディレクトリモードの fallback として引き続き成立（単一 non-DONE なら latest-updated = その doc）。回帰なしを full suite で検証
- count 112 の hardcode 契約（TC-19）: 新規テストファイルを作らないため不変

**Design Review Gate 判定（Read-only 調査、tests/ 実行なし）**:
- PASS（Risk ~40, WARN 帯）
- 検証1（既存 gate テスト単一 doc fixture の回帰）: `tests/test-pre-commit-gate.sh` T-01〜T-04・TC-06・TC-07、`tests/test-pre-red-gate.sh` T-01〜T-07、`tests/test-pre-commit-gate-retro.sh`（固定 fixture ファイル名 `20260101_0000_test.md` 単一 doc）を確認。全て単一 non-DONE doc の fixture のみで構成されており、ディレクトリモードの fallback は「候補が1件なら無条件でその doc を選ぶ」ため回帰なしと判定
- 検証2（updated 欠落 doc の 0000-00-00 扱いと T-06/T-07 の整合）: T-06/T-07 は `phase:` frontmatter 自体が存在しない doc（old-format / no-frontmatter）が唯一の doc であるケースで、これらは既存の `[ -z "$phase" ] && continue` により phase チェック段階で完全に除外され ACTIVE_CYCLE 候補にすら入らない（BLOCK: No active Cycle doc found）。新契約の「updated 欠落 → 0000-00-00 扱い」は phase フィールドを持つが updated フィールドを欠く doc にのみ適用される別ケースであり、両者は排他的条件のため矛盾なし
- 検証3（multi-file-consistency.md の enumerate-and-reject 原則との整合）: 新契約の `$1` 三分岐（`.md` file 実在 / directory 実在 / それ以外）は「期待値を enumerate し、それ以外は明示的に reject する」原則に準拠。GREEN 実装では `if [ -f ] / elif [ -d ] / else BLOCK` の enumerate 構造で実装すること
- Files to Change 現物確認: `pre-commit-gate.sh` L24-41（PROJECT_ROOT 代入 〜 ACTIVE_CYCLE 空チェックの `fi`）、`pre-red-gate.sh` L24-33（ACTIVE_CYCLE 選択 for ループ）、`rules/integration-verification.md` L29 と `.claude/rules/integration-verification.md` L29 が byte-identical であることを Read で実測確認済み。plan の行番号記述と実物が一致

## Verification（real-path invocation）

**Real-path invocation を最低 1 件含めること** (rules/integration-verification.md)。

```bash
SCRATCH=/private/tmp/claude-501/-Users-morodomi-Projects-MorodomiHoldings-agents-dev-crew/74f3a9a9-3af1-4977-80a3-f0ee96a13dd1/scratchpad

# 1) real-path: 実 repo で fallback 選択が最新 updated の doc を選ぶ（修正前は 20260421_1809 を選んでいた）
bash scripts/gates/pre-commit-gate.sh . 2>&1 | head -3; echo "rc=$?"
# 期待: 検査対象が updated 最新の non-DONE doc（本 cycle doc）になっていること

# 2) real-path: 明示指定モード（integration-verification.md L29 の記載形式がそのまま動く）
bash scripts/gates/pre-commit-gate.sh docs/cycles/20260702_1930_gate-active-cycle-fix.md; echo "rc=$?"

# 3) real-path: pre-red-gate も同様に確認
bash scripts/gates/pre-red-gate.sh . 2>&1 | head -3; echo "rc=$?"

# 4) mirror byte-identical
diff rules/integration-verification.md .claude/rules/integration-verification.md && echo IDENTICAL

# 5) full suite（snapshot baseline と diff、rc≠0 は FAIL 扱い、|| true で握り潰さない）
for f in tests/test-*.sh; do timeout 2400 bash "$f" >/dev/null 2>&1; printf "%s rc=%d\n" "$(basename $f)" "$?"; done | sort > "$SCRATCH/after.txt"
if grep -v "rc=0" "$SCRATCH/after.txt"; then echo "VERIFY FAIL"; false; else echo "all rc=0"; fi
diff "$SCRATCH/baseline-gatefix.txt" "$SCRATCH/after.txt" && echo "no regression"
```

baseline（`baseline-gatefix.txt`）は orchestrate Block 0 で snapshot 複製上で取得する（前 cycle Insight 1: live tree での baseline は並行プロセスに破壊されるため隔離必須）。

Evidence: (orchestrate が自動記入)

## Progress Log

Format for each phase entry (**strict, required by pre-commit-gate.sh**):

```
### YYYY-MM-DD HH:MM - PHASE_NAME
- [completed action]
- Phase completed
```

### 2026-07-02 19:30 - KICKOFF
- Cycle doc created from plan `/Users/morodomi/.claude/plans/delegated-roaming-pelican.md`（issue #145）
- Design Review Gate 実施（Read-only、tests/ 未実行 — baseline 実測は PdM が snapshot 複製上で並行取得中のため、テスト実行プロセスの直列化原則に従い本 gate では実行しない）
- 判定: PASS（Risk ~40, WARN 帯）。既存 gate テストの単一 doc fixture 回帰なし、updated 欠落 doc の扱いと T-06/T-07 の非矛盾、multi-file-consistency.md の enumerate-and-reject 原則との整合を確認
- Files to Change 全量（6件）を plan から verbatim 転記。独自判断での追加・削除なし
- Scope definition ready
- Phase completed

### 2026-07-02 19:50 - PLAN REVIEW (Codex competitive)
- Codex plan review: **BLOCK**（F1）+ WARN 3（F2-F4）。triage（全て accept-apply、reject 0）:
- **F1 (BLOCK: sweep 漏れ — LLM 側手順に同型バグ) → accept-apply、scope +7 files**:
  - Codex 指摘は steps-subagent.md / steps-teams.md / commit SKILL.md の 3 箇所だが、PdM 追加 sweep で **7 箇所**を確定: `grep -L 'phase: DONE' ... | head -1` 型 = skills/red/SKILL.md:18, skills/green/SKILL.md:19, skills/refactor/SKILL.md:21, skills/commit/SKILL.md:10。awk first-match 型 = skills/review/SKILL.md, skills/orchestrate/steps-subagent.md:42, skills/orchestrate/steps-teams.md:35
  - 全 7 箇所を gate と同一セマンティクス（updated lexicographic 最大の non-DONE、filename 昇順 tie-break で tail 選択）の canonical one-liner に差し替える。GREEN の scope に追加（rules/doc-mutations.md SSOT 即時同期に従い本エントリで Files list を拡張）
  - 逆向き契約確認済み: test-phase-gate.sh TC-01〜 は「`phase: DONE` 文字列 + BLOCK|spec の存在」のみを assert し、新スニペットも `phase: DONE` を含むため非破壊。test-review-plan-gate.sh の orchestrate 参照も文字列レベルで互換
- **F2 (WARN: tie-break TC 欠如) → accept-apply**: Test List に TC-07 を追加（updated 同値 2 doc で filename 降順選択）
- **F3 (WARN: 明示指定モードの穴) → accept-apply**: 契約を補強 — 明示指定 doc が phase 欠落 or `phase: DONE` の場合は BLOCK（enumerate-and-reject）。STATUS.md count 警告用の PROJECT_ROOT は `*/docs/cycles/*.md` パターン時に doc の 2 階層上から導出、それ以外は `.`。Test List に TC-08 を追加（DONE doc 明示指定で BLOCK）
- **F4 (WARN: updated 比較の将来堅牢性) → accept-apply**: 実装指針 — `printf '%s\t%s\n' "$updated" "$f" | sort | tail -1 | cut -f2` の全行 lexicographic 比較とし、空白 field split（sort -k1,1 等）を使わない。ISO T 形式混入時も文字列比較で破綻しない
- **Notes → accept**: 新規 multi-doc TC は TC ごとに fixture サブディレクトリを隔離（test-pre-commit-gate-retro.sh の make_gate_fixture 方式踏襲）
- **追加 TC-09**（前 cycle codify Insight 1/2 の contiguous-phrase pin を dogfood）: 7 skill docs の探索行が新スニペット（`sort | tail -1 | cut -f2` を含む）であり `| head -1` 型 first-match が残存しないことを assert する TC を test-phase-gate.sh に追加
- test_count: 6 → 9（frontmatter 同期）
- Codex session id: stdout 非出力のため未記録
- 判定: BLOCK 事由（F1）は scope 拡張で解消 → Block 2a (RED) へ

#### Files to Change 拡張（F1 反映後の全量、GREEN はこれを正とする）
1-6. plan 記載の 6 項目（両 gate / 両 gate テスト / integration-verification.md + mirror / Cycle doc）
7. skills/red/SKILL.md:18 — Hard Gate 探索行を canonical one-liner に差し替え
8. skills/green/SKILL.md:19 — 同上
9. skills/refactor/SKILL.md:21 — 同上
10. skills/commit/SKILL.md:10 — Cycle Doc Gate 探索行を同差し替え
11. skills/review/SKILL.md — awk first-match 探索を同セマンティクスに差し替え
12. skills/orchestrate/steps-subagent.md:42 — 同上
13. skills/orchestrate/steps-teams.md:35 — 同上
14. tests/test-phase-gate.sh — TC-09（スニペット pin）追加

### 2026-07-02 20:20 - RED
- 対象 3 ファイルに TC 追加（新規テストファイル作成なし、count 112 維持）:
  - `tests/test-pre-commit-gate.sh`: TC-08〜TC-12（5件、各 TC 専用 fixture サブディレクトリ `$TMPDIR/tc08`〜`tc12` で隔離）
    - TC-08: dir mode で updated 最新の non-DONE doc（new）が選ばれ REVIEW 未完了で BLOCK
    - TC-09: 明示指定モード（$1=doc パス）で new/old それぞれ単独検査
    - TC-10: $1 不在パスで `invalid` 文字列を含む BLOCK
    - TC-11: updated 同値 tie-break で filename tail（b）が選ばれる
    - TC-12: 明示指定 + `phase: DONE` doc で BLOCK
  - `tests/test-pre-red-gate.sh`: T-08〜T-09（2件、`$TMPDIR/t08`〜`t09` で隔離）
    - T-08: dir mode で updated 最新の non-DONE doc（new）が選ばれ Plan Review 未完了で BLOCK
    - T-09: 明示指定モードで new/old それぞれ単独検査
  - `tests/test-phase-gate.sh`: TC-09（1件、`check_selection_snippet` helper で 7 ファイル一括検査、TC-17 の ALL_UNDER 集約パターンに準拠し単一 pass/fail に集約）
    - 対象 7 ファイル: skills/red/SKILL.md, skills/green/SKILL.md, skills/refactor/SKILL.md, skills/commit/SKILL.md, skills/review/SKILL.md, skills/orchestrate/steps-subagent.md, skills/orchestrate/steps-teams.md
    - 探索行の特定は `docs/cycles/*.md`（fixed-string）+ `phase: DONE` の AND 条件で一意化（orchestrate 2 ファイルの retro_status codify-gate ループと Current State 表示行を誤検出しないことを事前 dry-run で確認済み）
- 3 ファイル個別実行結果（full suite 未実行、直列化原則に従い個別のみ）:
  - `bash tests/test-pre-commit-gate.sh` rc=1、PASS 7 / FAIL 5（TC-08〜TC-12 のみ FAIL、T-01〜T-04・T-06・TC-06・TC-07 は PASS 維持）
  - `bash tests/test-pre-red-gate.sh` rc=1、PASS 7 / FAIL 2（T-08〜T-09 のみ FAIL、T-01〜T-07 は PASS 維持）
  - `bash tests/test-phase-gate.sh` rc=1、PASS 22 / FAIL 1（TC-09 のみ FAIL、TC-01〜TC-22 は PASS 維持）
- 想定外事象: なし。全新規 TC が意図通り FAIL（RED）、既存 TC は全て PASS を維持
- test_count: frontmatter 9 のまま据え置き（Test List WIP 6項目のうち TC-09(phase-gate) は plan review F1 由来の追加契約点）
- Phase completed

### 2026-07-02 20:50 - GREEN
- Files to Change 拡張後の全量（14 項目）を対象に、選択ロジックを新契約へ書き換え:
  - `scripts/gates/pre-commit-gate.sh` L22-... — `$1` 三分岐（`.md` file 実在=明示指定 / directory 実在=dir mode fallback / else=BLOCK invalid argument）に書き換え。明示指定は phase 欠落・`phase: DONE` を enumerate-and-reject。dir mode は `updated\tpath` を `sort | tail -1 | cut -f2` の全行 lexicographic 比較で選択（F4 準拠、sort -k 未使用）。updated 欠落は `0000-00-00` 扱い。選択確定時に `Active Cycle: <path>` を出力。PROJECT_ROOT は明示指定時 `*docs/cycles/*.md` パターンなら doc の 2 階層上、それ以外は `.`。後続チェック（L43-90 相当）は無変更
  - `scripts/gates/pre-red-gate.sh` — 同型の書き換え（後続の sync-plan / Plan Review チェックは無変更）
  - `skills/red/SKILL.md:18`, `skills/green/SKILL.md:19`, `skills/refactor/SKILL.md:21`, `skills/commit/SKILL.md:10`, `skills/review/SKILL.md:22`, `skills/orchestrate/steps-subagent.md:42`, `skills/orchestrate/steps-teams.md:35` — 探索行を canonical one-liner（`for f in docs/cycles/*.md; do awk ... grep -q 'phase: DONE' || printf '%s\t%s\n' "$(awk ... updated ...)" "$f"; done | sort | tail -1 | cut -f2`）に統一差し替え。各ファイル 1 行差し替えのみで行数不変
  - `rules/integration-verification.md` L29 + `.claude/rules/integration-verification.md` L29 — 実行例を「$1 に cycle doc パスを渡すと明示検査（推奨）。project root を渡すと updated 最新の non-DONE を自動選択」に更新。`diff` で byte-identical 確認済み
- GREEN 確認（個別実行、rc 一覧）:
  - `tests/test-pre-commit-gate.sh` rc=0（PASS 12 / FAIL 0、TC-08〜TC-12 含む全 PASS）
  - `tests/test-pre-red-gate.sh` rc=0（PASS 9 / FAIL 0、T-08〜T-09 含む全 PASS）
  - `tests/test-pre-commit-gate-retro.sh` rc=0（PASS 6 / FAIL 0、既存 retro fixture 回帰なし）
  - `tests/test-phase-gate.sh` rc=0（PASS 23 / FAIL 0、TC-09 selection snippet 含む全 PASS、TC-17 SKILL.md 行数上限 PASS）
  - `tests/test-review-plan-gate.sh` rc=0（PASS 13 / FAIL 0、orchestrate 文字列契約回帰なし）
  - `tests/test-orchestrate-compact.sh` rc=0（PASS 17 / FAIL 0）
  - `tests/test-skill-map.sh` rc=0（PASS 7 / FAIL 0）
- real-path smoke:
  - `bash scripts/gates/pre-commit-gate.sh .` → `Active Cycle: ./docs/cycles/20260702_1930_gate-active-cycle-fix.md` を選択（updated 最新の non-DONE = 本 cycle doc）。REVIEW 未完了で `BLOCK: REVIEW not completed in Progress Log.` (rc=1、想定通り)
  - `bash scripts/gates/pre-commit-gate.sh docs/cycles/20260702_1930_gate-active-cycle-fix.md`（明示指定、integration-verification.md L29 記載形式）→ 同じ doc を検査し同じ BLOCK (rc=1、想定通り)
  - `bash scripts/gates/pre-red-gate.sh .` → 同 doc を選択し `PASS: All pre-RED gate checks passed.` (rc=0、sync-plan + Plan Review 記録済みのため想定通り)
- SKILL.md 行数確認: red 81 / green 52 / refactor 59 / commit 91 / review 50（review/SKILL.md は 100 行制約外だが確認、全て 100 行以下）
- 想定外事象: なし
- Phase completed

### 2026-07-02 21:00 - REFACTOR (PdM 検証)
- 選択ロジックは本 cycle で新規に書き直したテスト済みコードのため構造的リファクタ不要（no-op）
- Verification Gate: `bash -n` 両 gate OK（shellcheck はローカル不在で skip）、spot 4 test（pre-commit-gate / pre-red-gate / phase-gate / pre-commit-gate-retro）全 rc=0、integration-verification.md mirror byte-identical、real-path で `Active Cycle: ./docs/cycles/20260702_1930_gate-active-cycle-fix.md` の正選択を確認
- green-worker の指示外調整 1 件を承認: PROJECT_ROOT 導出パターンを `*/docs/cycles/*.md` → `*docs/cycles/*.md`（先頭スラッシュなし）に変更。相対パス呼び出し（integration-verification.md 記載形式）がマッチしないための技術的必然
- Phase completed

### 2026-07-02 21:30 - VERIFY (Product Verification, Block 2c.5)
- Evidence: /tmp/dev-crew-verify-20260702_1930/verify.log
- real-path: dir mode → `Active Cycle: ./docs/cycles/20260702_1930_gate-active-cycle-fix.md`（updated 最新の non-DONE を正選択。修正前は 20260421_1809 を選んでいた）+ REVIEW 未完了 BLOCK（この時点の正常挙動）
- real-path: 明示指定モード（integration-verification.md L29 記載形式）→ 同 doc を直接検査。文書と実装の矛盾解消を実証
- real-path: pre-red-gate → 同 doc 選択、PASS
- mirror byte-identical
- **full suite: 112/112 全 rc=0、baseline-gatefix.txt との diff 空 = 回帰ゼロ**（snapshot 隔離 baseline との機械的比較、rc≠0 は握り潰さない改訂 Verification を実行）
- Phase completed

### 2026-07-02 21:55 - REVIEW FIX (green-worker)
- REVIEW で BLOCK した findings 5点を修正。red-first で TC-13/TC-14 を先に追加し FAIL を確認してから fix を適用:
  - **Fix 1 (security HIGH)**: 両 gate の明示指定分岐に docs/cycles/ 配下必須チェックを追加。`ARG_ABS="$(cd "$(dirname "$ARG")" && pwd)/$(basename "$ARG")"` で絶対パス正規化した上で `case "$ARG_ABS" in */docs/cycles/*.md) ;; *) BLOCK; esac`。pin: test-pre-commit-gate.sh TC-13（docs/cycles/ 外の偽造 .md を明示指定 → BLOCK + 出力に "docs/cycles" を含む）。red 確認: fix 前は rc=0 で PASS してしまう（TC-13 FAIL）。fix 後 rc=1 で BLOCK（TC-13 PASS）
  - **Fix 2 (correctness BLOCK)**: 両 gate の明示指定分岐の PROJECT_ROOT 導出を dirname 2重 → 3重に修正（`docs/cycles/foo.md` → project root は 3 階層上）。ARG_ABS 基準で導出。pre-red-gate は PROJECT_ROOT 未消費（dead value）だが同型維持のため同修正。pin: test-pre-commit-gate.sh TC-14（STATUS.md 不一致 count fixture を明示指定で実行し WARN 出力を assert）。red 確認: fix 前は PROJECT_ROOT が1階層浅く STATUS.md が見つからず WARN 未出力（TC-14 FAIL）。fix 後 WARN 出力（TC-14 PASS）
  - **Fix 3 (Codex BLOCK)**: 7 skill docs（red/green/refactor/commit/review/SKILL.md, orchestrate/steps-subagent.md, orchestrate/steps-teams.md）の canonical one-liner を、空 glob 対応（`[ -f "$f" ] || continue`）+ phase 存在必須（`grep -q '^phase:' || continue`）+ DONE 除外（`grep -q 'phase: DONE' && continue`）+ updated の ISO-T 正規化（`gsub(/T/," ")`）を含む形に差し替え、gate 本体とのセマンティクス一致を確保。test-phase-gate.sh TC-09（sort|tail|cut-f2 契約 + head -1 非残存）で差し替え後も PASS を確認
  - **Fix 4 (Codex WARN)**: 両 gate の dir mode で updated 値の `T` を空白に正規化（`tr 'T' ' '`）してから sort。ISO 形式混入時も同日内の時系列比較を保証
  - **Fix 5 (maint HIGH×3)**: tests/test-pre-commit-gate.sh:239, tests/test-pre-red-gate.sh:181, tests/test-phase-gate.sh:300 のコメントから「, issue #145」等の追跡番号句を削除（TC 番号・内容は無変更）。新規 TC-13/TC-14 のコメントにも追跡番号は付与していない
  - 適用外（PdM 判断により defer/reject、対応不要）: maint MED（gate 間重複の drift guard）と LOW（echo 集約）→ DISCOVERED へ defer。Codex note（tab/newline パス）→ reject（doc パスは repo 命名規約下で発生しない）
- 完了確認（個別実行、全 rc=0）:
  - `tests/test-pre-commit-gate.sh` rc=0（PASS 14 / FAIL 0、TC-13/TC-14 含む）
  - `tests/test-pre-red-gate.sh` rc=0（PASS 9 / FAIL 0）
  - `tests/test-phase-gate.sh` rc=0（PASS 23 / FAIL 0、TC-09 selection snippet 新契約で PASS）
  - `tests/test-pre-commit-gate-retro.sh` rc=0（PASS 6 / FAIL 0、既存 retro fixture 回帰なし）
- real-path smoke（期待通り）:
  - `bash scripts/gates/pre-commit-gate.sh .` → `Active Cycle: ./docs/cycles/20260702_1930_gate-active-cycle-fix.md` 選択、REVIEW 未完了で BLOCK rc=1
  - `bash scripts/gates/pre-commit-gate.sh docs/cycles/20260702_1930_gate-active-cycle-fix.md`（明示指定）→ 同 doc を検査、同じ BLOCK rc=1
- 想定外事象: なし
- Phase completed

### 2026-07-02 22:10 - REVIEW (Codex competitive + 3 Claude reviewers, MED tier)
- 判定: Codex **BLOCK** / correctness **BLOCK** / security **BLOCK 相当（HIGH 1）** / maintainability **WARN（HIGH 3 + MED/LOW）**
- findings 3-category triage:
  - **accept-apply（5 fix、全て red-first で pin TC 付き適用済み）**:
    1. security HIGH: 明示指定モードが docs/cycles/ 外の任意 .md を信頼（偽造 doc で gate 通過を実機実証）→ ARG_ABS 正規化 + `*/docs/cycles/*.md` 必須化。pin: TC-13
    2. correctness BLOCK（Codex F2 同指摘）: PROJECT_ROOT の dirname 1 回不足で STATUS.md count 警告が明示指定モードで silent skip → dirname 3 重化。pin: TC-14
    3. Codex BLOCK: 7 skill docs one-liner が gate と非同一セマンティクス（空 glob false-found・phase 欠落 doc を候補化）→ `[ -f ]` + phase 存在必須 + DONE 除外 + T 正規化を含む canonical form に統一
    4. Codex WARN: updated の ISO `T` 形式混在で同日順序が崩れる → 両 gate で tr 'T' ' ' 正規化
    5. maint HIGH×3: テストコメントの「issue #145」追跡番号を除去（グローバル規約準拠、TC 内容不変）
  - **accept-defer → DISCOVERED**: maint MED（両 gate の選択ロジック重複に drift guard なし）、maint LOW（Active Cycle echo の分岐重複）
  - **reject（根拠付き）**: Codex note の tab/newline 含みパス — cycle doc パスは repo 命名規約（YYYYMMDD_HHMM_topic.md）下にあり発生しない。fixture も同規約
- 適用後検証: test-pre-commit-gate（14 PASS、TC-13/14 含む）/ test-pre-red-gate（9 PASS）/ test-phase-gate（23 PASS）/ test-pre-commit-gate-retro（6 PASS）全 rc=0。PdM による偽造 doc 実弾確認で BLOCK を確認
- BLOCK 事由は全て解消 → Block 2e へ
- Phase completed

### 2026-07-02 22:12 - DISCOVERED (Block 2e)
- D1: 旧 non-DONE cycle doc 15 件の phase: DONE 一括遷移 + COMMIT→DONE 遷移責務の workflow 未定義（plan スコープ外宣言済み。gate の latest-updated 選択で実害は解消したが、「non-DONE = active」の意味論修復は残課題）→ issue 起票
- D2: 両 gate の選択ロジック重複（約48行）に drift guard がない（maint MED）+ Active Cycle echo の分岐重複（maint LOW）。共有 lib 化は「gate 単体 full validation」原則との整合検討が必要 → issue 起票
- parallel 削除/作り直し・test hardening 束ね cycle は既存 issue（#142/#143）で追跡済みのため新規起票なし
- issue 起票結果: D1=#147, D2=#148

### 2026-07-02 22:40 - COMMIT
- REVIEW FIX 適用後の最終 full suite: **112/112 全 rc=0、baseline-gatefix.txt との diff 空（回帰ゼロ）**（scratchpad/final-gatefix.txt）
- pre-commit gate は本 cycle で修正した gate 自身を**明示指定モードで dogfood**（`bash scripts/gates/pre-commit-gate.sh docs/cycles/20260702_1930_gate-active-cycle-fix.md`）— #145 の「対象 cycle を検査しない」穴が塞がった状態での初の実運用
- branch feature/gate-active-cycle-fix（#146 の上に stack）で commit、PR を feature/skill-inventory-cleanup base で作成
- Phase completed

---

## Next Steps

1. [Done] KICKOFF
2. [Done] RED
3. [Done] GREEN <- Current
4. [ ] REFACTOR
5. [ ] REVIEW
6. [ ] COMMIT
7. [ ] DONE

## Retrospective

抽出時刻: 2026-07-02 22:30
抽出方法: Cycle doc 全体（PLAN REVIEW BLOCK / REVIEW 4系統 BLOCK×3+WARN / red-first fix）からの失敗→最終解→insight ペア抽出

### Insight 1: パス引数を取る gate は「信頼するディレクトリ境界」を契約に含める
- **Failure**: 明示指定モードの設計（plan + Codex plan review F3 の補強後も）は引数の**形式**（.md file / dir / other）は enumerate したが**位置**（tree 内/外）を定義せず、docs/cycles/ 外の偽造 doc（phase: COMMIT + REVIEW 記録 + retro_status: resolved を完備）で COMMIT gate を素通りできる穴が GREEN 実装に入った。security reviewer が実機再現で検出
- **Final fix**: `cd+pwd` による絶対パス正規化 + `*/docs/cycles/*.md` 必須化 + 偽造 doc fixture の TC-13 で pin
- **Insight**: **ファイルパスを受ける gate/validator の enumerate-and-reject は、値の形式だけでなく「どのディレクトリ配下を信頼するか」の境界を含めて列挙する**。discipline gate は adversary への防御ではないが、LLM の hallucination パス渡しは現実的な入力分布であり境界検証が実害を防ぐ
- **一般化**: rules/multi-file-consistency.md の enumerate-and-reject 原則の拡張候補（「位置も enumerate する」）

### Insight 2: 分岐追加時は「新分岐 × 既存チェック」の組み合わせ経路に観測可能な TC を置く
- **Failure**: 明示指定モード（新分岐）と STATUS.md count 警告（既存チェック）の組み合わせ経路に TC がなく、PROJECT_ROOT の dirname off-by-one（`docs` を指す）で警告が silent skip されるバグが GREEN を素通り。RED の 8 TC は全て選択ロジック自体を検査し、非ブロッキング警告の消失は全体 rc に現れない。correctness reviewer が fixture 実測で検出
- **Final fix**: dirname 3 重化 + TC-14（明示指定 + STATUS 不一致 fixture で `WARN:` 出力文字列を assert）
- **Insight**: **分岐を追加したら、分岐ごとに既存チェックの出力（特に非ブロッキング WARN）が生きていることを出力文字列 assert で観測する**。rc のみの検証は「黙って何もしなくなった」regression を検出できない
- **一般化**: 20260701_1120 Insight 1（追記内容の contiguous phrase pin）の実行時版 — 「観測されない経路は壊れていても GREEN」

### Insight 3: 「同一セマンティクス」の複数実装は挙動チェックリストを列挙してから適用する
- **Failure**: PLAN REVIEW で PdM が起草した canonical one-liner が gate 実装の guard（空 glob の -f check、phase 欠落 doc の除外）を欠いた簡略版で、「gate と同一セマンティクス」の要求を自ら満たさなかった。文字列 pin（test-phase-gate TC-09）は再混入防止には効くがセマンティクス同値性は検証しないため素通り。Codex code review が bash 実行で挙動差を検出
- **Final fix**: 空 glob / phase 欠落 / DONE 除外 / ISO-T 正規化を含む canonical form に 7 ファイル統一
- **Insight**: **複数実装に「同一セマンティクス」を要求する時は、先に挙動チェックリスト（空入力・欠落フィールド・形式混在・異常系）を列挙し、各実装をリストに対して検証する**。代表実装からの目視転記は guard を落とす
- **一般化**: 本 cycle の maint MED（gate 間 drift guard 不在、#148）と同根。セマンティクス同値性の検証は文字列比較でなく挙動比較

### 成功事例（observation）: perspective-diverse review の相補性
- 4 系統が互いに排他的な欠陥を検出: security=偽造パス、correctness=dirname off-by-one、Codex=one-liner セマンティクス乖離、maintainability=追跡番号混入。重複指摘は dirname 1 件のみ。レンズ分離設計（rules/review-triage.md MED tier）の有効性を実証

## Codify Decisions

triage 実施: 2026-07-03 12:10（後続 cycle test-hardening-rule-codify の orchestrate Block 0 codify gate で処理）。全件 high-confidence の autonomous triage（skill 候補なし、質問 0 件）。実装は同 cycle（test-hardening-rule-codify が rule 実装 cycle そのものであるため、decision と implementation を同時に行う — 無関係 cycle の commit を汚さない慣行と矛盾しない）。

### Insight 1
- **Decision**: codified
- **Destination**: rule (rules/multi-file-consistency.md + .claude/rules/ mirror)
- **Reason**: enumerate-and-reject 原則の拡張 —「パス引数の enumerate は値の形式だけでなく位置（信頼するディレクトリ境界）も列挙対象」。偽造 doc で gate 通過という実害 evidence あり
- **Decided**: 2026-07-03 12:10

### Insight 2
- **Decision**: codified
- **Destination**: rule (rules/test-patterns.md + .claude/rules/ mirror)
- **Reason**: 「分岐追加時は分岐 × 既存チェックの組み合わせ経路に出力文字列 assert を置く」。非ブロッキング WARN の silent skip という実害 evidence あり
- **Decided**: 2026-07-03 12:10

### Insight 3
- **Decision**: codified
- **Destination**: rule (rules/test-patterns.md + .claude/rules/ mirror)
- **Reason**: 「同一セマンティクスの複数実装は挙動チェックリスト列挙後に各実装へ適用」。one-liner セマンティクス乖離の実害 evidence あり
- **Decided**: 2026-07-03 12:10

### 成功事例（observation）
- **Decision**: no-codify
- **Reason**: perspective-diverse review の相補性は rules/review-triage.md 既存 tier 設計の実証であり、新規 rule 化は不要
- **Decided**: 2026-07-03 12:10
