---
feature: agents-md-count-fix
phase: COMMIT
complexity: trivial
risk_level: low
test_count: 2
retro_status: resolved
---

# Cycle: AGENTS.md agent count 整合 (eval-3)

## Objective

`AGENTS.md` line 65 の agent count 宣言 (41) を実際の agent 数 (40、frontmatter 持ち) に整合させる。
`tests/test-skills-structure.sh` TC-B1 の pre-existing FAIL を解消する。

## TDD Context

- **Layer**: Backend (markdown doc edit のみ)
- **Plugin**: dev-crew meta
- **Files to Change**: `AGENTS.md` (1 ファイル)

## Design Approach

`AGENTS.md` line 65 を `# 41 agents (flat)` → `# 40 agents (flat)` に修正。

- `test-skills-structure.sh` TC-B1 が frontmatter-check で 40 をカウント
- `agents/false-positive-filter-reference.md` は reference doc (frontmatter なし) で agent ではないため count に含めない
- `README.md` は既に `# 40 agents` で正しい（変更不要）

## Test List

### TODO

- [ ] TC-01: `tests/test-skills-structure.sh` TC-B1 が PASS になる (AGENTS.md 宣言 = actual count 40)
  - Given: AGENTS.md line 65 が `# 40 agents (flat)`
  - When: `bash tests/test-skills-structure.sh` を実行し TC-B1 行を抽出
  - Then: `PASS.*declares 40 agents, actual is 40` がヒット
- [ ] TC-02: AGENTS.md line 65 が 40 agents 宣言 (static check)
  - Given: AGENTS.md
  - When: `grep "40 agents (flat)" AGENTS.md` 実行
  - Then: ヒット、かつ `41 agents (flat)` はヒットしない (negative assertion)

### WIP

(none)

### DISCOVERED

- `agents/false-positive-filter-reference.md` が `agents/` flat 配下に配置されているが frontmatter なしの reference doc で、test の count logic を混乱させる。長期的には `docs/references/` や skill-style sidecar pattern への移動を検討すべき (Option B 相当、別 cycle で structural refactor 候補)
- 他 pre-existing failures 2 件 (test-codex-delegation-interface.sh / -preference.sh) は eval-4/5 で順次対応予定

### DONE

(none)

## Verification

```bash
cd /Users/morodomi/Projects/MorodomiHoldings/agents/dev-crew

# 1. test-skills-structure.sh TC-B1 PASS 確認
bash tests/test-skills-structure.sh 2>&1 | grep "TC-B1"
# 期待: "PASS TC-B1: AGENTS.md declares 40 agents, actual is 40"

# 2. test-cross-references.sh が TC-B1 経由で PASS
bash tests/test-cross-references.sh 2>&1 | tail -3

# 3. 既存テスト regression 確認 (新規 regression なし)
for f in tests/test-*.sh; do bash "$f" > /dev/null 2>&1 || echo "FAIL: $(basename $f)"; done | sort
# 期待: eval-1/2 で既に記録された残 pre-existing failures (test-codex-delegation-* 等) のみ FAIL、test-skills-structure.sh と test-cross-references.sh は FAIL から消える
```

## Progress Log

### 2026-04-20 - RED

- 作成ファイル: `tests/test-agents-md-count.sh`
- TC-01: FAIL — TC-B1 が "declares 41 agents, actual is 40" で FAIL のため grep ヒットなし
- TC-02: FAIL — AGENTS.md に `40 agents (flat)` 不在 (has_40=0)、`41 agents (flat)` 存在 (has_41=1)
- RED 状態確認: 2 TC すべて FAIL (exit 1)

### 2026-04-21 23:42 - KICKOFF

- Design Review Gate: PASS (score: 8)
- plan: `/Users/morodomi/.claude/plans/validated-marinating-hopper.md`
- scope: AGENTS.md 1 file / 1 line (41 → 40)
- v2.7.0 運用評価第三 cycle (eval-3)。trivial scope で Block 2f 自動発火 + insight 抽出動作確認

### 2026-04-21 23:55 - RED

- tests/test-agents-md-count.sh 新規作成 (2 TC: TC-01 regression via existing TC-B1, TC-02 static grep)
- RED 状態確認: 2 FAIL

### 2026-04-22 00:05 - GREEN

- AGENTS.md line 65: `41 agents (flat)` → `40 agents (flat)` (1 行)
- test-agents-md-count.sh 修正: TC-01 で `bash ... | grep -q` の set -euo pipefail masking bug 発見 → output を一旦変数に保存する方式に修正 (subject が pre-existing で exit 1 でも grep 結果を正しく評価)
- test-agents-md-count.sh 2/2 PASS、test-skills-structure.sh TC-B1 PASS、test-cross-references.sh 6/6 PASS (eval-1/2 DISCOVERED 2 件連鎖解消)
- Phase completed

### 2026-04-22 00:10 - REFACTOR

- no-op (1 行変更、構造問題なし)
- Verification Gate: PASS
- Phase completed

### 2026-04-22 00:15 - REVIEW

- Codex code review: **approve 一発**、findings なし
- Claude correctness reviewer: Codex がクリーンなので skip (trivial scope のため)
- 総合判定: PASS
- Phase completed

## Retrospective

### Insight 1: small scope でも `set -euo pipefail + pipe + grep` の masking bug が発見される

- **Failure**: test-agents-md-count.sh TC-01 で `bash subject_test | grep -q` を使ったが、subject が pre-existing で exit 1 のとき pipefail が失敗伝播 → grep match しても test 全体が FAIL 判定。RED で想定通り FAIL したが、GREEN 後も `if` 判定が else に入って FAIL 継続
- **Final fix**: `output=$(bash subject 2>&1 || true)` で一旦 output を変数に保存、次に `echo "$output" | grep -q` で pipeline 分離。subject の exit code を明示的に捨てて grep 結果だけ評価
- **Insight**: `set -euo pipefail` 環境で「subject script の exit code と grep の結果を両方気にしたい」場合、pipe 直接使わず **output capture → grep 分離** が安全 pattern。eval-2 の meta test (subject_completed_NN check) も同族の問題、共通する insight として一般化すべき

### Insight 2: 小 scope cycle でも insight は 1-2 件抽出できる (retrospective loop の効率性)

- **Failure**: 当初想定「1 file / 1 line / trivial」で retrospective に値する insight は出ないかもと懸念
- **Final fix**: GREEN 中に pipefail bug 発見 → Insight 1 として抽出
- **Insight**: trivial scope でも「発見 vs 実装」のペアが 1 つでも生まれれば insight になる。retrospective loop は cycle size に依存せず機能する = **v2.7.0 Step 1 の coverage 証拠**。今後「trivial だから retrospective 省略」という判断はしない

### Insight 3: Codex が approve 一発のとき、Claude correctness reviewer の並列実行は省略できる

- **Failure**: 過去 cycle で Codex + Claude correctness を並列実行していたが、trivial scope では overkill
- **Final fix**: Codex code review が findings なしで approve → Claude correctness skip
- **Insight**: trivial scope (1 file / 1 line / risk low) では **Codex のみ code review** で十分。Claude correctness reviewer の並列化は medium 以上 risk で価値が出る。review コストの適応的運用

## Codify Decisions

### Insight 1: small scope でも `set -euo pipefail + pipe + grep` の masking bug が発見される
- **Decision**: codified
- **Destination**: rule
- **Reason**: "bash pipefail + pipe + grep は output capture で分離" rule (eval-4 #3 の `$?` 即捕捉と合わせ "pipefail + $ トラップ集" に整理)
- **Decided**: 2026-04-22 14:00

### Insight 2: 小 scope cycle でも insight は 1-2 件抽出できる (retrospective loop の効率性)
- **Decision**: no-codify
- **Reason**: dogfood observation、retrospective loop の coverage 特性記述であり rule 化しない
- **Decided**: 2026-04-22 14:00

### Insight 3: Codex が approve 一発のとき、Claude correctness reviewer の並列実行は省略できる
- **Decision**: codified
- **Destination**: rule
- **Reason**: "Risk LOW + Codex approve 一発は Claude correctness skip 可" rule (Cycle B #6 の Risk-based scaling 具体例)
- **Decided**: 2026-04-22 14:00
