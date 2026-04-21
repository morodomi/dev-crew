---
feature: test-doc-consistency-tc02-fix
cycle: 20260421_1043
phase: DONE
complexity: trivial
test_count: 4
risk_level: low
retro_status: captured
codex_session_id: ""
created: 2026-04-21 10:43
updated: 2026-04-21 11:50
---

# test-doc-consistency TC-02 CONSTITUTION 準拠修正

## Scope Definition

### In Scope

- [ ] `tests/test-doc-consistency.sh` 編集:
  - TC-02: `arch_count=$(grep ... || true)` + `[ -z "$arch_count" ]` でスキップ処理追加。`set -euo pipefail` 環境での abort を防ぐ
  - TC-04: assertion を strict 強化（PASS 文言の明示確認）
  - `BASE_DIR` env override サポート行追加（meta test からの fixture 注入用）
- [ ] `tests/test-meta-doc-consistency.sh` 新規（または既存に統合）:
  - meta test: `BASE_DIR=/tmp/fixture-dir bash tests/test-doc-consistency.sh` を実行し PASS 終了を確認する

### Out of Scope

- architecture.md への skill count hardcode 追加（CONSTITUTION 原則「導出可能情報を hardcode しない」により禁止）
- TC-02 以外の TC の挙動変更
- test-doc-consistency.sh のリネームや TC 番号の再振り

## TDD Context

### Problem

`test-doc-consistency.sh` の TC-02 は `grep -oE '[0-9]+ skills' "$BASE_DIR/docs/architecture.md"` を実行する。
`architecture.md` に「N skills」形式のハードコード文字列が存在しない場合、`grep` は exit code 1 を返す。
スクリプトは `set -euo pipefail` で起動されているため、`grep` の non-zero exit により **スクリプト全体が abort** する。
TC-03 以降が実行されず、Summary も表示されない。

### Root Cause

CONSTITUTION 原則により `architecture.md` には skill count の hardcode が存在しない（正しい状態）。
しかし TC-02 は「hardcode があれば比較、なければ FAIL」という設計になっておらず、「grep no-match → abort」となっている。

### Design Approach

CONSTITUTION 準拠の2分岐設計:
1. `arch_count=$(grep ... || true)` で grep exit を吸収
2. `[ -z "$arch_count" ]` → `pass "architecture.md has no hardcoded skill count (CONSTITUTION compliant)"` でスキップ
3. `[ "$arch_count" = "$ACTUAL_COUNT" ]` → `pass` / else `fail` (regression guard)

meta test は `BASE_DIR` env override で fixture ディレクトリを注入し、実 script を直接実行する方式を採用。
TC-02 logic のコピーではなく、実 script の振る舞いを end-to-end で検証する。

### Files to Change

| File | Type | Description |
|------|------|-------------|
| `tests/test-doc-consistency.sh` | edit | TC-02 修正 + TC-04 strict 化 + BASE_DIR override サポート |
| `tests/test-meta-doc-consistency.sh` | new | meta test: fixture dir で実 script を実行して PASS を確認 |

## Test List

### TC-01: TC-02 がハードコードなし architecture.md で PASS を返す

- **Given**: `arch_count` が空文字（grep no-match + `|| true`）
- **When**: `[ -z "$arch_count" ]` が true
- **Then**: `pass "architecture.md has no hardcoded skill count (CONSTITUTION compliant)"` が出力される

### TC-02: TC-02 がハードコードあり architecture.md で比較する

- **Given**: fixture の `docs/architecture.md` に「31 skills」を含む
- **When**: `arch_count` が実際の skill 数と一致する
- **Then**: `pass` が出力される

### TC-03: meta test が実 script を fixture dir で実行して PASS 終了する

- **Given**: `BASE_DIR` を fixture ディレクトリに設定
- **When**: `bash tests/test-doc-consistency.sh` を実行
- **Then**: exit code 0、かつ出力に "PASS" が含まれる（strict assertion）

### TC-04: meta test が fixture で意図的に FAIL を検出できる

- **Given**: `BASE_DIR` に不整合な fixture（skill count mismatch）を設定
- **When**: `bash tests/test-doc-consistency.sh` を実行
- **Then**: exit code 非ゼロ、かつ出力に "FAIL" が含まれる

## Design Review Gate

- **Verdict**: PASS
- **Score**: 8
- **Issues**: なし
- **Notes**: meta test が実 script を直接実行する end-to-end 方式で drift リスクを排除。`set -euo pipefail` abort 挙動への対処として `|| true` + 空文字チェックは既存パターンと一致。

## Exit Conditions (Codex post-commit P2-2 を受けて scope 明確化)

このサイクルの完了条件 (本 cycle scope に限定):
- [x] `bash tests/test-doc-consistency.sh` の **TC-02 が PASS** ("does not hardcode" 文言出力)
- [x] `bash tests/test-meta-doc-consistency.sh` が全 TC PASS で exit 0
- [x] TC-02 修正による新規 regression なし (test-pre-commit-gate-retro.sh 等 other tests に影響なし)

### 本 cycle scope 外の pre-existing failures (別 cycle で対応)

`tests/test-doc-consistency.sh` 全体が exit 0 にならないのは、TC-13 (recursive runner) が以下の pre-existing failing tests を検出するため:

- `tests/test-codex-delegation-interface.sh`: `steps-codex.md still contains 'advisory'` で exit 1
- `tests/test-codex-delegation-preference.sh`: `SKILL.md missing user choice priority rule` で exit 1
- `tests/test-cross-references.sh`: `test-skills-structure.sh` 経由で `AGENTS.md declares 41 agents, actual is 40` で exit 1

これらは v2.7.0 リリース前から存在する failures であり、本 cycle の TC-02 fix とは独立。別 cycle (DISCOVERED) で個別に対応する。本 cycle では「test-doc-consistency.sh 全体が exit 0」を Exit condition として要求しない。

## Progress Log

### KICKOFF (2026-04-21 10:43)

Design Review Gate: PASS (score: 8)。plan v2 Codex Revise 2 点対応:
1. TC-02 現状記述を「script abort (set -euo pipefail + grep no-match)」に訂正
2. meta test を `BASE_DIR env override で実 script を fixture dir で実行` 方式に変更
3. TC-04 assertion を strict (PASS 文言) に強化

### RED (2026-04-21)

`tests/test-meta-doc-consistency.sh` 新規作成（4 TC）。

実行結果: PASS: 0 / FAIL: 4 / TOTAL: 4 → RED 状態確認済み。

各 TC の失敗理由:
- TC-01 FAIL: `BASE_DIR` env override が `test-doc-consistency.sh` に実装されていないため fixture を無視、実 repo の arch_count grep が `set -euo pipefail` により abort → "does not hardcode" 文言が出力されない
- TC-02 FAIL: `BASE_DIR` env override が無効 → fixture の 2 skill dirs を無視 → "PASS.*= actual (2)" が出力されない（実 repo の count=31 が使われる）
- TC-03 FAIL: `BASE_DIR` env override が無効 → fixture の "99 skills" を無視 → "!= actual" が出力されない
- TC-04 FAIL: TC-02 の header が現在 "architecture.md skill count matches actual" であり、期待する "skill count check" 文言が存在しない

作成ファイル: `tests/test-meta-doc-consistency.sh`（新規）

### 2026-04-21 11:00 - REVIEW

- Claude correctness-reviewer: PASS (blocking_score 18)
  - **important 1 件**: meta test TC-02/TC-03 の grep が TC-01 出力 ("README.md skill count (2) = actual (2)") にも誤マッチ可能 → false positive リスク
  - optional 2 件: set -e 統一, grep pattern 厳密化
- Codex code review: **Request changes**
  - 同 important 指摘 (`PASS.*= actual \(2\)` が TC-01 でも成立)
  - **対応**: GREEN 再実行 (max 1 回ルール内) で meta test grep を `architecture\.md skill count` 接頭辞付きに厳密化、PASS/FAIL 期待文字列を fully qualified に変更
- 再テスト: meta test 4/4 PASS 維持
- 総合判定: **PASS** (両 reviewer の important 指摘対処済)
- Phase completed

### REFACTOR (2026-04-21)

- 対象: tests/test-doc-consistency.sh, tests/test-meta-doc-consistency.sh
- チェックリスト確認:
  - 重複コード: TC-01/TC-02 の `grep -oE '[0-9]+ skills' ... | head -1 | grep -oE '[0-9]+' || true` パターンが 2 箇所重複。helper 化は overengineering (2 occurrences のみ、project 慣習 = function 抽出は 3+ から) のため**変更なし**
  - 定数化 / 未使用 import / let→const / メソッド分割 / N+1 / 命名一貫性: 該当なし
- Verification Gate: PASS
  - test-meta-doc-consistency.sh 4/4 PASS
  - test-doc-consistency.sh TC-02 = "PASS architecture.md does not hardcode skill count (CONSTITUTION principle honored)"
- Phase completed (no-op refactor、品質基準すでに満たしている)

### GREEN (2026-04-21)

`tests/test-doc-consistency.sh` を 4 箇所修正:

1. line 7: `BASE_DIR="${BASE_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"` — env override サポート追加
2. line 29: TC-01 の `readme_counts=$(grep ... 2>/dev/null | head -1 | grep -oE '[0-9]+' || true)` — meta test fixture で `set -euo pipefail` abort を防止
3. line 38-46: TC-02 を CONSTITUTION 準拠に変更（header 更新 + `|| true` + 空文字チェックで "does not hardcode" PASS 分岐追加）
4. line 194: TC-13 に `[ "$test_name" = "test-meta-doc-consistency.sh" ] && continue` 追加 — TC-13→meta test→TC-04→test-doc-consistency.sh の無限再帰を防止

meta test TC-01〜TC-04: 全 PASS 確認済み (4/4 PASS、自動実行も完了)。

### 2026-04-21 11:50 - POST-COMMIT FIX (Codex post-commit P2 対応)

Codex post-commit review (commit bbdab73) で 2 件 P2:

- **P2-1 meta test exit status drop**: `... | grep ... || true` で subject script の exit code を捨てており、TC-02 が正しい文言を print しても script broken なら catch できない。さらに grep が全 output 対象なので別 location からも match する false positive 残存
  - **対応**: TC-01/02/03 を `awk '/^TC-02:/{flag=1} flag{print} /^TC-0[3-9]:|^TC-1[0-9]:|^===/{exit}'` で TC-02 セクションのみ抽出してから grep。これにより「TC-02 セクション内に該当 PASS/FAIL 行が存在」を strict 検証
  - 再テスト: 4/4 PASS 維持
- **P2-2 cycle 完了判定が unresolved**: Cycle doc に "TC-04 自動実行: 実行中" 残存 + Exit condition「test-doc-consistency.sh が exit 0」が事実と乖離 (TC-13 が pre-existing failures を検出して exit 1)
  - **対応**: GREEN log の "実行中" を「全 PASS 確認済み」に更新。Exit Conditions セクションを scope 明確化に書き換え、pre-existing failures (test-codex-delegation-interface.sh / test-codex-delegation-preference.sh / test-cross-references.sh) を本 cycle scope 外として明記

## Implementation Notes

- `grep ... || true` パターンは `test-frontmatter-retro-status.sh` 等の既存テストで採用済み
- fixture ディレクトリは `/tmp/test-doc-consistency-fixture-$$` 等で一時作成し、テスト後削除
- `BASE_DIR` override は script 冒頭の `BASE_DIR=` 行より前に env が設定されている必要があるため、script 側で `BASE_DIR=${BASE_DIR:-"$(cd "$(dirname "$0")/.." && pwd)"}` 形式に変更する

## Retrospective

### Insight 1: plan の現状記述は「実コードを実行確認」してから書く

- **Failure**: TC-02 の挙動を「常に FAIL」と簡略化して plan に記述。Codex Revise で「実際は `set -euo pipefail` + grep no-match で script が silent abort する」と指摘
- **Final fix**: plan の Problem セクションを「abort (or fail) と、どちらにせよ script が完走しない」と訂正
- **Insight**: plan 作成時、対象 test の挙動は **grep + 実行で確認してから記述**。「FAIL」「abort」「skip」を曖昧に使い分けず、bash の挙動 (set -euo pipefail) も含めて精確に書く

### Insight 2: meta test (test を test する) は対象 script を直接実行する形が drift 防止に強い

- **Failure**: 当初 plan は meta test を「TC-02 logic を copy して fixture で検証」方式で設計。Codex から「実装 drift リスク + TC-04 grep が header だけで通る」と指摘
- **Final fix**: BASE_DIR env override 方式に変更し、meta test から実 test-doc-consistency.sh を fixture dir で実行
- **Insight**: meta test は対象 script を**そのまま実行**する形が最も drift に強い。logic copy/paste は最終手段。env override で fixture dir を渡せるよう対象 script に **`${BASE_DIR:-default}` 形式のフック**を入れることが前提

### Insight 3: meta test assertion は対象 TC を**特定する固有 prefix** で絞り込む

- **Failure**: meta test TC-02/TC-03 で `PASS.*= actual (2)` を grep。これは TC-01 の `README.md skill count (2) = actual (2)` にも match → false positive リスク。Codex Request changes + Claude correctness reviewer 一致で important 指摘
- **Final fix**: grep を `architecture\.md skill count.*= actual \(2\)` のように **検証対象 TC 固有の prefix (file path / section name)** で絞り込み
- **Insight**: meta test の grep assertion は、検証対象 TC を**一意特定する文字列** (file 名 / section 名 / TC 番号 + 文脈) を含める。共通文字列 (PASS, actual, FAIL 等) のみは false positive 源。**両 reviewer (Claude + Codex) が独立して同じ指摘** → よくある落とし穴

### Insight 4: fixture-based meta test 導入時、対象 script の他 TC が fixture 環境で abort しない defense を当てる

- **Failure**: meta test が空 fixture dir で test-doc-consistency.sh を実行 → TC-01 (README.md grep) が `set -euo pipefail` で abort → meta test 全体が失敗
- **Final fix**: TC-01 にも `|| true` + `2>/dev/null` を追加 (TC-02 の collateral fix として scope 内で対処)
- **Insight**: fixture-based meta test を導入するときは、対象 script の **fixture 環境 (空 file / 不在 file) でも abort しない defensive 化** を同時にやる。pipefail + grep no-match の落とし穴は複数 TC に潜むので、一括 sweep が有効

### Insight 5: 既存 test を実行する meta test は recursive runner (TC-13 等) に対する skip を初期に設計

- **Failure**: TC-13 が `tests/test-*.sh` を全実行 → meta test が走る → meta test の TC-04 が `bash tests/test-doc-consistency.sh` を再実行 → 無限再帰のリスク。green-worker が GREEN フェーズで気付いて TC-13 skip 条件を追加
- **Final fix**: TC-13 の skip リストに `test-meta-doc-consistency.sh` を追加 (1 行)
- **Insight**: 既存 test を `bash` で再実行する meta test を導入するときは、**recursive runner (test-doc-consistency.sh TC-13 のような他テスト全実行 logic) に対する skip 登録**を plan 段階で明示。後付けで気付くと巻き込み事故になる

