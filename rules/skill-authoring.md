---
paths:
  - "skills/**"
---
# Skill Authoring — SKILL.md 100 行制約と inter-skill exit contract

SKILL.md のサイズ管理と、skill 間呼び出しの exit contract 設計規律。

## SKILL.md 100 行 hard limit (cycle 20260420_1752 #1)

SKILL.md は 100 行を超えてはならない (dev-crew quality standard):

- 既存 SKILL.md に追記する plan では、現行行数と目標行数の差分を事前に計算する
- compress target を plan 段階で具体化する (例: Block 0 task list を reference.md に移動)
- sync-plan の pre-review で気付くと scope 追加手戻りが発生する。plan 時点で行数を確認する

```bash
# SKILL.md 行数確認
wc -l skills/*/SKILL.md | sort -n | grep -v total
# 100 行を超えているものを特定
wc -l skills/*/SKILL.md | awk '$1 > 100 && !/total/'
```

## Inter-skill Exit Contract (cycle 20260422_1146 #5)

skill が別 skill から invoke される場合、callee SKILL.md に exit code + 副作用を明記する:

- **exit 0**: 正常終了。caller は次フェーズへ進む
- **exit 1**: 異常終了 (BLOCK)。caller は中断し、stderr メッセージをユーザーに提示する
- frontmatter 状態遷移など副作用も SKILL.md に明記する
- Caller 側 (例: orchestrate) にも exit 0/1 分岐ロジックを同時更新する (双方向契約)

**Precedent**: `skills/cycle-retrospective/SKILL.md` — abort 時に exit 1 + stderr → orchestrate が BLOCK

**Utility script の例外注記**: skill 本体（SKILL.md 経由で呼ばれるフェーズ制御）と異なり、決定論的 utility script は exit code の意味が個別に定義される場合がある。呼び出し側は「script の exit code」と「script が stdout に出す判定結果」を混同しないこと:

- `skills/review/risk-classifier.sh`: 常時 exit 0（判定結果は stdout の risk tier 行そのもの。exit code に判定は乗らない）
- `skills/review/severity-verdict.sh`: `verdict` サブコマンドは **判定結果（BLOCK/WARN/PASS）が exit 0 の stdout 行に乗る**（exit 0 は「集計が正常実行できた」ことのみを意味し PASS を意味しない）。異常系のみ非 0: `validate` の INVALID = exit 1、`verdict` の INVALID-TRIAGE = exit 2、両サブコマンド共通の usage エラー（引数不正） = exit 64

```markdown
## Exit Contract (callee SKILL.md に記述)

| Exit code | 意味 | Caller の対応 |
|-----------|------|--------------|
| 0 | 正常完了 | 次フェーズへ進む |
| 1 | BLOCK (abort) | 中断。stderr をユーザーに提示 |

副作用: frontmatter `retro_status` を `none → captured` に更新
```

## Insight 引用の原則 (cycle 20260422_1313 #3)

rule に insight を codify する際、**元の insight L## (Cycle doc 行番号) を引用として明示**する。generalize する場合は「なぜ generalize したか」を 1 行書く。LLM は insight を generalize する時、source より自分の "clean statement" を優先する bias があるため、原文引用の明示が一次防御となる。Codex competitive review は原典照合を担うが、引用の明示が無いと複数 source の merge bias を検出できない。

## 出典

- `docs/cycles/20260420_1752_v2.8-orchestrate-integration.md` Insight 1
- `docs/cycles/20260422_1146_codify-insight-skill.md` Insight 5
- `docs/cycles/20260422_1313_rule-docs-codify-followup.md` Insight 3 — insight 原文の改変禁止、generalize 時は理由明示
