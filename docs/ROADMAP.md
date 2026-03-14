# Roadmap

> Phase 1-10 の完了履歴は [archive/development-plan.md](archive/development-plan.md) を参照。

## 現在地

Phase 10 まで完了。TDDサイクル（spec→RED→GREEN→REFACTOR→REVIEW→COMMIT）は動作する。PHILOSOPHY.md で定義した target philosophy への移行が次の課題。

## Phase 11: Claude + Codex 統合開発フロー

PHILOSOPHY.md の target philosophy を既存スキルに反映する。

### 11.1 kickoff → sync-plan 移行

kickoff スキルを sync-plan agent に置き換え、spec 内部から呼ぶ軽量エージェント化。

#### マイグレーション対象

| 対象 | 変更内容 |
|------|---------|
| skills/kickoff/ | sync-plan agent に変換。spec から Task() で呼び出し |
| skills/spec/ | sync-plan 呼び出しを追加。plan review → approve → sync-plan の順序 |
| skills/orchestrate/ | kickoff → sync-plan 参照更新。Post-Approve Action 修正 |
| skills/review/ | Cycle Doc Gate の kickoff 参照更新 |
| skills/red/, green/, commit/ | Cycle Doc Gate の kickoff 参照更新 |
| skills/refactor/, diagnose/ | kickoff 参照更新 |
| CLAUDE.md | Skills テーブル、Usage Patterns、Auto-orchestrate 記述更新 |
| AGENTS.md | Workflow セクション、Project Structure 更新 |
| docs/terminology.md | kickoff → sync-plan 用語更新 |
| docs/archive/skills-catalog.md | アーカイブ済み。Phase 13 スキルマップで後継 |
| docs/architecture.md | フロー図更新 |

#### 互換性方針

kickoff エイリアスは残さない。完全置換。live docs から `kickoff` が 0 件になることをマイグレーション完了条件とする。

```bash
# 完了条件チェック（履歴ドキュメントは除外）
rg "kickoff" skills/ CLAUDE.md AGENTS.md docs/ \
  --glob '!docs/cycles/**' \
  --glob '!docs/ROADMAP.md' \
  --glob '!docs/STATUS.md' \
  --glob '!docs/archive/**'
# → 0 件で完了
```

### 11.2 Codex 委譲インターフェース

orchestrate スキルに Codex 委譲パスを追加。

#### セッション管理

| イベント | 操作 | 備考 |
|---------|------|------|
| spec 完了時 | `codex exec` で新規セッション作成 | Cycle doc パスをプロンプトに含める |
| RED/GREEN/REVIEW 委譲 | `codex exec resume --last` | cwd フィルタにより同ディレクトリ内の最新セッションが選ばれる |
| サイクル完了 | セッション破棄 | 次サイクルは新規 |
| resume 失敗時 | 新規セッション作成で retry | stale session は自動回避 |

#### Codex 利用可否判定

```
which codex && codex exec --full-auto "echo ok" → 成功: Codex 利用可能
→ 失敗: Claude fallback（既存スキルそのまま）
```

#### 委譲フロー

```
orchestrate
  ├─ Codex 利用可能
  │   ├─ RED: codex exec resume --last "red docs/cycles/xxx.md"
  │   ├─ GREEN: codex exec resume --last "green docs/cycles/xxx.md"
  │   ├─ REFACTOR: Claude（実装者と別視点）
  │   └─ REVIEW: Claude review + codex exec resume --last "review code docs/cycles/xxx.md"
  │
  └─ Codex 不在
      └─ 全フェーズ Claude（現行動作維持）
```

### 11.3 競争的レビュー

- review スキルに Codex レビュー統合
- Claude review + Codex review の findings 集約フロー
- findings 判断ロジック: Accept / Reject / AskUserQuestion / DISCOVERED / ADR

### 11.4 exspec 統合

- RED 最終ステップに exspec 実行を追加
- exspec 未インストール時はスキップ（既存パターン踏襲）

### 11.5 マイグレーション検証

- kickoff → sync-plan の grep ベース参照チェックテスト追加
- 既存テストの kickoff 参照を sync-plan に更新
- マイグレーション完了条件: live docs の kickoff 参照が 0 件（11.1 の完了条件チェックコマンド参照）

### 11.6 onboard AGENTS.md生成の改善

今回のdev-crew自身のAGENTS.md整備で得た知見を、onboard skillが他プロジェクトで生成するAGENTS.mdに反映する:

- Start Here セクション（最初の行動指針）
- テストコマンドの正確性（`bash tests/*.sh` ではなく `for f in; do bash "$f"; done`）
- 数値カウントはSTATUS.mdに任せ、AGENTS.mdには書かない
- migration注記パターン（対象プロジェクトに上位方針文書がある場合のみ。なければ不要）
- 対象: skills/onboard/reference.md のAGENTS.md + CLAUDE.mdテンプレート
- CLAUDE.mdテンプレートにもCodex Integrationセクションのパターンを反映

## Phase 12: ドキュメント体系整備

> Phase 11.1（sync-plan 移行）完了後に開始。用語・フローが確定してからドキュメントを更新する。

### 12.1 既存ドキュメント整理

- README.md 新規作成（docs/ ナビゲーション）
- STATUS.md 更新（最新サイクル反映）
- development-plan.md アーカイブ化（完了）
- skills-catalog.md アーカイブ化（完了。Phase 13 スキルマップで後継）

### 12.2 AGENTS.md / CLAUDE.md 更新

- AGENTS.md: エージェント数・テスト数の正確な値、Codex Integration セクション
- CLAUDE.md: PHILOSOPHY.md との整合、sync-plan 反映
- architecture.md: PHILOSOPHY.md の開発フローとの整合

## Phase 13: スキルマップ

各スキルが開発フローのどこで、誰（Claude/Codex）が使うかを明示する。

```
フロー上の位置          スキル                  主担当        fallback
─────────────────────────────────────────────────────────────────
企画                    strategy                Claude        -
設計                    spec                    Claude        -
  曖昧性検出            (spec内蔵)              Claude        -
  plan review           review --plan           Codex         Claude
  Cycle doc生成         sync-plan               Claude        -
テスト作成              red                     Codex         Claude
  テスト静的解析        exspec                  (tool)        skip
実装                    green                   Codex         Claude
品質改善                refactor (/simplify)    Claude        Codex
レビュー                review                  Claude+Codex  Claude
コミット                commit                  Claude        -
───────────────────────────────────────────────────────────────
コンテキスト管理        phase-compact, reload   Claude        -
バグ調査                diagnose                Claude        -
並列開発                parallel                Claude        -
プロジェクト初期化      onboard                 Claude        -
セキュリティ            security-scan/audit     Claude        -
メタ学習                learn, evolve           Claude        -
言語別品質              *-quality               (auto)        -
```

## 優先順位

| Phase | 優先度 | 理由 |
|-------|--------|------|
| 11 | P1 | PHILOSOPHY.md の理想を実現する核心。日常の開発効率に直結 |
| 12 | P2 | 11.1 完了後に開始。用語確定前にドキュメント更新すると手戻り |
| 13 | P2 | 11/12 完了後に自然と確定する |

## 順序

```
11.1 sync-plan 移行 → 11.5 マイグレーション検証
  ↓
11.2 Codex 委譲 → 11.3 競争的レビュー → 11.4 exspec
  ↓
12 ドキュメント整備（11.1 完了後に開始可能）
  ↓
13 スキルマップ確定
```

## 方針

- 各サブタスクは独立した TDD サイクルで実施
- PHILOSOPHY.md を正（target philosophy）とし、既存ドキュメントを順次移行
