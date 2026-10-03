---
feature: prompt audit で見つかった手順書の矛盾を直す
cycle: 20261004_0020
phase: DONE
complexity: standard
test_count: 5
risk_level: low
retro_status: captured
codex_session_id: ""
plan_file: ""
created: 2026-10-04 00:20
updated: 2026-10-04 00:20
---

# prompt audit で見つかった手順書の矛盾を直す

保守例外（docs/NEXT.md「現在地」2）。2026-10-03 の prompt audit で見つかった「手順書どうし、手順書と実装の食い違い」を直す・削る。新しい規則は足さない。

## Scope Definition

### In Scope

- [x] `skills/commit/SKILL.md`: retro_status 不在を「WARN で PASS」と説明していた → gate の実挙動（BLOCK）に合わせる
- [x] `rules/review-triage.md`（+ mirror）: tier 境界 0–30 / 30–60 が重なっていた → 実装（>=30 MEDIUM、>=60 HIGH）に合わせ 0–29 / 30–59 / 60+
- [x] `agents/false-positive-filter-reference.md`: frontmatter のない参照資料が、説明なし・全ツール付きの agent として登録されていた → `skills/security-scan/` へ移動
- [x] `skills/review/steps-subagent.md`: Raw Findings を Cycle doc に append する条項は、2026-09 の cycle doc 8 本で 1 度も守られていなかった → 削除
- [x] `rules/doc-mutations.md`（+ mirror）の行番号参照、`.claude/rules/post-approve.md` の「旧条項を改訂」という差分書き

### Out of Scope

- `agents/architect.md` に `disallowedTools: Write, Edit` を足す件: AGENTS.md の規則の理由（tools を絞った agent に memory を併用すると Write が有効化される）は、tools を持たない writer の architect には当てはまらない。矛盾ではないので触らない
- dev-crew の外（release-skill、search-task、親ディレクトリの CLAUDE.md、導入先 repo）

## Baseline（2026-10-03 実測）

- `scripts/gates/pre-commit-gate.sh:96`: retro_status 不在で `BLOCK: retro_status field missing`
- `skills/review/risk-classifier.sh`: `-ge 60` → HIGH、`-ge 30` → MEDIUM
- `ls docs/cycles/202609*.md`: 8 本、うち `## Raw Findings` を持つもの 0 本
- このセッションの agent 一覧に `dev-crew:false-positive-filter-reference`（Tools: All tools）が出ていた
- フルスイート 117/117 PASS

## Progress Log

### 2026-10-04（時刻未計測） - RED

- test-pre-commit-gate-retro TC-12（commit SKILL の説明が BLOCK）、test-risk-classifier T-12（tier 境界が実装と一致）、test-agents-structure TC-27（agents/ に参照資料を置かない）、test-review-step5-synthesis-clause TC-03（Raw Findings 条項が無い）を追加・置換
- 変更前の実装で 4 件 FAIL を確認
- RED Phase completed

### 2026-10-04（時刻未計測） - GREEN

- In Scope の 5 項目を修正。対象テスト PASS、フルスイート 117/117 PASS
- GREEN Phase completed

### 2026-10-04 00:18 - REVIEW

- Codex review（`codex exec --sandbox read-only -o ... < /dev/null`、rc=0）: P2 x2、P3 x1、削除候補 2
  - accept-apply P2: T-12 は閾値の存在しか見ていない → 閾値の直後で割り当てる tier まで確認
  - accept-apply P2: 既存の TC が `*-reference*` を除外しており、別名の非 agent ファイルがすり抜ける → 除外をすべて削除し、agents/ の全ファイルを agent 検査に通す
  - accept-apply P3: 削除で「手順4」の番号参照が切れた → 名前参照に変更
  - reject: 移動先の参照資料の冒頭にある配置理由（再発防止の説明として残す）、synthesis 末尾の説明文（分類手順の理由として残す）
- 隔離コピーで変異 2 件（agents/ に frontmatter のない md を置く、`-ge 60` を LOW に割り当てる）がいずれも FAIL になることを確認
- 追加したテストのラベルが既存の T-05 と重複していたので T-12 に振り直した
- REVIEW Phase completed

## Retrospective

- **最初の失敗 → 最終解**: TC-27 は「参照資料を agent 検査から除外できていること」を確認するテストで、参照資料が agents/ にあることを前提にしていた。実際の Claude Code は agents/*.md をすべて agent として登録するので、テストが守っていたのは誤った前提だった → 「agents/ には agent しか置かない」契約に反転した
- **事前知識化**: テストがファイルを除外しているときは、その除外が実行環境（ここでは Claude Code の登録規則）でも成り立つかを確かめる。テストの世界だけで除外すると、本番では除外されないものを守ってしまう
