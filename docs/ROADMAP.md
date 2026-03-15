# Roadmap

> Phase 1-10 の完了履歴は [archive/development-plan.md](archive/development-plan.md) を参照。

## 現在地

Phase 11 主要完了（11.1-11.3, 11.5-11.7）。v2.0.2 リリース準備中。
Open Issues: #56（Codex competitive review 強制）。
残り: 11.4, 11.8, 11.9（低優先度）→ Phase 12, 13 へ。

## Phase 11: Claude + Codex 統合開発フロー

PHILOSOPHY.md の target philosophy を既存スキルに反映する。

### 11.1 kickoff → sync-plan 移行 (完了)

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
| skills/strategy/ | Step 4 の review(plan) を spec 内部 Codex plan review に修正 |
| agents/architect.md | Skill(kickoff) 呼び出しを sync-plan に更新 |
| rules/state-ownership.md | kickoff パーミッション行を sync-plan に更新 |
| CLAUDE.md | Usage Patterns、Auto-orchestrate 記述更新 |
| AGENTS.md | Workflow セクション更新 |
| docs/terminology.md | kickoff → sync-plan 用語更新 |
| docs/architecture.md | フロー図更新 |
| docs/usability.md | kickoff 参照更新 |
| docs/project-conventions/skill-md-frontmatter.md | kickoff 参照更新 |
| tests/ | 6ファイル rename + 内容更新 (test-auto-kickoff, test-kickoff-debate, test-architect-improvement, test-decision-records, test-phase-gate, test-state-ownership) |

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

### 11.2 Codex 委譲インターフェース (完了)

orchestrate スキルに Codex 委譲パスを追加。各実行フェーズのスキルにもCodex委譲情報を反映。

#### セッション管理

| イベント | 操作 | 備考 |
|---------|------|------|
| plan review 時 | `codex exec` で新規セッション作成 | plan ファイルパスをプロンプトに含める |
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
  │   ├─ REFACTOR: Claude（独自ロジック。Codex fallback）
  │   └─ REVIEW: Claude review + codex exec resume --last "review code docs/cycles/xxx.md"
  │
  └─ Codex 不在
      └─ 全フェーズ Claude（現行動作維持）
```

#### スキル別 Codex 委譲ドキュメント更新

| スキル | 更新内容 |
|--------|---------|
| skills/red/reference.md | Codex 委譲セクション追加（Codex優先、Claude fallback） |
| skills/green/reference.md | Codex 委譲セクション追加（Codex優先、Claude fallback） |
| skills/review/SKILL.md + steps-subagent.md | 競争的レビューパターン追加（Claude + Codex 並行） |
| skills/refactor/SKILL.md | Codex fallback 記述追加。`/simplify` は Claude 専用だが、Codex には独自 refactor を実行させる |
| skills/orchestrate/steps-codex.md | REVIEW の「supplementary」を「competitive」に修正 |

### 11.3 競争的レビュー (完了)

- review スキルに Codex レビュー統合
- Claude review + Codex review の findings 集約フロー
- findings 判断ロジック: Accept / Reject / AskUserQuestion / DISCOVERED / ADR

### 11.4 exspec 統合

- RED 最終ステップに exspec 実行を追加
- exspec 未インストール時はスキップ（既存パターン踏襲）

### 11.5 マイグレーション検証 (完了)

- ~~kickoff → sync-plan の grep ベース参照チェックテスト追加~~
- ~~既存テストの kickoff 参照を sync-plan に更新~~
- ~~マイグレーション完了条件: live docs の kickoff 参照が 0 件（11.1 の完了条件チェックコマンド参照）~~
- 11.1 実施時に既存テスト・参照を全て更新済み。live docs の kickoff 参照 0 件を確認。

### 11.6 onboard スキル改善 (完了)

今回のdev-crew自身のドキュメント整備で得た知見を、onboard skillが他プロジェクトで生成するドキュメントに反映する:

#### AGENTS.md テンプレート改善
- Start Here セクション（最初の行動指針）
- テストコマンドの正確性（`bash tests/*.sh` ではなく `for f in; do bash "$f"; done`）
- 数値カウントはSTATUS.mdに任せ、AGENTS.mdには書かない
- migration注記パターン（対象プロジェクトに上位方針文書がある場合のみ。なければ不要）

#### CLAUDE.md テンプレート改善
- Codex Integrationセクションのパターンを反映
- Skills trigger table は不要（プラグインシステムが自動検出）

#### Codex 環境セットアップ
- sync-skills スキルへの誘導を追加
- Codex 利用可能時の初期セッション作成案内

対象: skills/onboard/reference.md

### 11.7 refactor スキル再構築 (完了)

現状 refactor は Claude Code の `/simplify` に完全委譲しているが、Codex には `/simplify` がない。cross-tool で動作する独自 refactor ロジックを復活させる。

- `/simplify` 依存を解消し、独自の品質改善ロジックをスキル内に持つ
- Claude 実行時: 独自ロジック（`/simplify` は使わない。または optional で併用）
- Codex 実行時: 同じ独自ロジックで動作
- 観点: N+1、変数宣言、const、重複コード、未使用変数、型の一貫性

#### `/simplify` 依存の波及箇所

| 対象 | 変更内容 |
|------|---------|
| skills/refactor/SKILL.md | `/simplify` 委譲を独自ロジックに置換 |
| skills/refactor/reference.md | 独自 refactor ロジックの詳細を記述 |
| skills/orchestrate/steps-subagent.md | refactor 委譲パスの更新 |
| skills/orchestrate/steps-teams.md | refactor 委譲パスの更新 |
| skills/orchestrate/reference.md | REFACTOR フェーズ説明の更新 |
| skills/reload/SKILL.md | REFACTOR 復元時の参照更新 |
| skills/reload/reference.md | REFACTOR 復元時の参照更新 |
| CLAUDE.md | `/simplify` 参照の更新 |
| docs/terminology.md | refactor 用語説明の更新 |

### 11.8 付属スキルの差し込み位置整理

dev-crew のフロー外で動作するスキル群の位置づけとCodex対応を整理。

| スキル | 現状 | 課題 |
|--------|------|------|
| search-task | 別プラグイン（dev-crew外） | dev-crew スキルではない。Phase 13 のスキルマップからも除外 |
| onboard | プロジェクト初期化 | 11.6 で対応 |
| sync-skills | Codex 用シンボリックリンク生成 | onboard から誘導すべき |
| skill-maker | スキル作成支援 | そのままで問題なし |
| diagnose | バグ調査 | kickoff 参照更新のみ（11.1） |
| learn / evolve | メタ学習 | そのままで問題なし |

### 11.9 ディレクトリ構成の AI-Driven 標準化

onboard がプロジェクトに生成するディレクトリ構成を、どこまで dev-crew でコントロールするかの方針決定。

検討事項:
- `docs/cycles/` は必須（TDD サイクル管理）
- `docs/STATUS.md` は必須（状態管理）
- `.claude/rules/` はどこまで？（git-safety, security は標準化する価値あり）
- `.claude/hooks/` はどこまで？（observe, pre-compact は dev-crew 固有）
- AGENTS.md / CLAUDE.md の構成はどこまで規約化するか
- 他ツール（Codex, Copilot）が期待するディレクトリ構成との整合

## Phase 12: ドキュメント体系整備

> Phase 11.1（sync-plan 移行）完了後に開始。用語・フローが確定してからドキュメントを更新する。

### 12.1 既存ドキュメント整理

- README.md 新規作成（docs/ ナビゲーション）（完了）
- STATUS.md 更新（最新サイクル反映）（完了）
- development-plan.md アーカイブ化（完了）
- skills-catalog.md アーカイブ化（完了。Phase 13 スキルマップで後継）

### 12.2 AGENTS.md / CLAUDE.md 更新

- AGENTS.md: Codex Integration セクション
- CLAUDE.md: PHILOSOPHY.md との整合、sync-plan 反映
- architecture.md: PHILOSOPHY.md の開発フロー + Codex 並列モデルとの整合

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
品質改善                refactor                Claude        Codex
レビュー                review                  Claude+Codex  Claude
コミット                commit                  Claude        -
───────────────────────────────────────────────────────────────
コンテキスト管理        phase-compact, reload   Claude        -
バグ調査                diagnose                Claude        -
並列開発                parallel                Claude        -
プロジェクト初期化      onboard + sync-skills   Claude        -
セキュリティ            security-scan/audit     Claude        -
メタ学習                learn, evolve           Claude        -
言語別品質              *-quality               (auto)        -
スキル作成              skill-maker             Claude        -
```

## 優先順位

| Phase | 優先度 | 理由 |
|-------|--------|------|
| 11.1 | P0 | 全体の前提。kickoff が残ると他の全タスクがドリフトする |
| 11.7 | P1 | refactor の cross-tool 対応。Codex 委譲の前提条件 |
| 11.2 | P1 | PHILOSOPHY.md の核心。日常の開発効率に直結 |
| 11.3 | P1 | 11.2 と密結合。同時実装が効率的 |
| 11.4 | P2 | exspec の成熟度次第。独立して進められる |
| 11.5 | P1 | 11.1 と同時。マイグレーション品質保証 |
| 11.6 | P2 | 11.1, 11.2 完了後に着手 |
| 11.8 | P2 | 方針決定のみ。実装は各スキルの修正時に吸収 |
| 11.9 | P3 | 長期課題。onboard の進化に合わせて段階的に |
| 12 | P2 | 11.1 完了後に開始 |
| 13 | P2 | 11/12 完了後に確定 |

## 順序

```
11.1 sync-plan 移行 + 11.5 マイグレーション検証
  ↓
11.7 refactor 再構築
  ↓
11.2 Codex 委譲 + 11.3 競争的レビュー
  ↓
11.4 exspec 統合
  ↓
11.6 onboard 改善 + 11.8 付属スキル整理
  ↓
12 ドキュメント整備
  ↓
13 スキルマップ確定
  ↓
11.9 ディレクトリ標準化（長期）
```

## 方針

- 各サブタスクは独立した TDD サイクルで実施
- PHILOSOPHY.md を正（target philosophy）とし、既存ドキュメントを順次移行
- security 系エージェント/スキルは現状維持（PHILOSOPHY 違反なし）
