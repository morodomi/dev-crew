# ADR-002: cycle-retrospective + codify-insight 設計（v2.7 Agile Loop Step 1+1b）

## Status: accepted

## Context

dev-crew の TDD サイクルは spec → orchestrate → sync-plan → plan-review → RED → GREEN → REFACTOR → REVIEW → COMMIT で完結している。一方、サイクル中の「最初の失敗 → 最終解 → 事前知識化」のループは閉じていない。既存の learn / evolve は hook ログから非同期にパターンを抽出する仕組みで、failure-success ペアの言語化は扱わない。

mizchi/chezmoi-dotfiles の `retrospective-codify` skill を参考に、サイクル末で技術知見を codify するループを dev-crew に組み込む方針を検討した。

設計は Codex との 2 ラウンドの批判的レビューを経て合意した。Codex の主要な修正提案を取り込んだ最終仕様を本 ADR に固定する。

## Decision Scorecard

| 項目 | 評価 | 理由 |
|------|------|------|
| Requirements Fit | A | 既存 learn/evolve では拾えない failure-success ペアの codify ループを閉じる |
| Security | A | inline 実行は抽出のみで repo 改変は Cycle doc の append に限定。codify は人間承認 |
| Operability | B | auto blocking で忘却防止。extraction failure 時は retry + override で hard-block を回避 |
| Complexity | C | 5 ステップに分割、Step 3a 完了後に運用評価で 3b 以降の必要性を再判定 |
| Testability | B | inline 抽出は LLM 出力依存。Cycle doc セクション追記・frontmatter 状態遷移は検証可能 |

## Arguments

### Accepted

- **位置**: cycle-retrospective を REVIEW → DISCOVERED 処理 → cycle-retrospective → COMMIT に配置。同じ COMMIT に Retrospective セクションを含める（post-commit の worktree 汚染を回避）
- **inline 範囲**: blocking path には抽出のみ。dedup と codify target 分類は codify-insight 側で実行（重い処理を inline から外す）
- **失敗時挙動**: retry 上限 N 回 + ユーザー override 可。LLM 都合の一時失敗で hard-block しない
- **codify-insight = decide gate**: 次回 /orchestrate 開始時、`retro_status: captured` がある Cycle を自動 triage する。既定は AI が `codified` / `deferred` / `no-codify` を決め、`skill` 候補や low-confidence 時のみ AskUserQuestion で補助する。「codify 実行」は強制しない（緊急修正フローを止めない）
- **状態モデル**: frontmatter は `retro_status: none | captured | resolved` の 3 値。本文 insight 個別に `codified | deferred | no-codify` を持たせる
- **resolved の意味**: 全 insight 処理方針が決定済み（codify 実行有無は問わない）。「insight なし」と「override skip」も resolved に含める
- **rejected insight は instinct 自動送りしない**: 軸が違う（採用/却下 = 意思決定、codify/instinct = 知識成熟度）ので混ぜない
- **Goal doc**: 2-8 Cycle / 1-3 週の中間粒度。docs/goals/YYYYMMDD_<name>.md。時間箱なし、達成 or abandon で閉じる
- **frontmatter 最小化**: cycle_id / goal_id / issue_id / status / retro_status / review_verdict / verification_status まで。phase metrics は本文 ## Metrics か sidecar に逃がす
- **timestamp は orchestrate のみが書く**: 各 phase skill や hook は書かない
- **agile namespace で dev-crew 内吸収**: 別プラグイン化しない。`dev-crew:agile-*` 命名で内部 namespace 整理
- **flow-analyze / knowledge-prune は最初手動**: 定期実行は運用で価値が見えてから
- **段階的実装**: Step 1 → 1.5 → 2 → 3a → 運用評価 → 3b → 4 → 5

### Rejected

- **COMMIT 後に新 gate を足す**: worktree が汚れ、TDD の完了定義が崩れる
- **N Cycle = Sprint**: AI では 1 cycle の重さが揺れすぎ、N を先に決めても意味がない
- **Stakeholder proxy 役**: 実ユーザー入力なしだと AI が自分で作った acceptance criteria を自分で採点する
- **Velocity tracker に authority を持たせる**: 計測器に留めるべき
- **LLM 抽出失敗を hard-block**: モデル都合の一時失敗まで停止させるとフローが弱くなる
- **codify 実行を強制**: ast-grep ルールや skill 追記は実質的にプロダクト変更で、別 cycle に分けるべき場合がある。緊急修正前に強制すると詰まる。decide gate で十分
- **rejected insight → instinct 自動送り**: 採用/却下と知識成熟度を混ぜると学習系が濁る
- **frontmatter に phase metrics 全載せ**: 既存の validate-cycle-frontmatter.sh と state-ownership.md をほぼ作り直しになる。会話コンテキストも圧迫
- **agile-crew 別プラグイン化**: 社員モデル膨張防止のため namespace で吸収
- **8 事業 sprint 同期**: project-local flow + portfolio sync の方が AI-first に合う

### Deferred

- Step 3a 完了後の運用評価で Step 3b 以降の必要性を再判定
- マルチプロジェクト global view（将来 repo 外 index で集約）
- Sprint overlay（cadence 管理が必要になったら導入）
- agile-crew 系で auto-discovery 劣化が顕在化した場合の追加対策（公開 skill 制限・narrow trigger 化）

## Decision

v2.7 Agile Loop の Step 1+1b として以下を実装する。残りステップは Step 1+1b の運用結果を踏まえて段階的に進める。

### Step 1: cycle-retrospective skill

- 配置: `skills/cycle-retrospective/SKILL.md`
- 起動: REVIEW 合格 → DISCOVERED 処理 → cycle-retrospective → COMMIT に自動 blocking で挿入
- 入力: 当該 Cycle doc 全体（plan / phase summaries / review verdicts / test failures / retry log / DISCOVERED 処理結果）
- 処理: failure → final fix → insight ペアを抽出（mizchi 方式）。dedup と codify target 分類は実行しない
- 出力: Cycle doc の `## Retrospective` セクションに append、frontmatter `retro_status: captured` を立てる
- 失敗時: retry 上限 N 回（推奨 2 回）。超過した場合はユーザー override を求める
  - override 採択時は `## Retrospective` に `Extraction skipped by override` を残し、`retro_status: resolved` に遷移
  - 全 retry 失敗で override も拒否された場合は `Extraction failed after N retries` を残す（同じく `resolved`）
  - **override は `no-codify` に偽装しない**。`no-codify` は実際に抽出された insight への判断にのみ使う

### Step 1b: codify-insight skill

- 配置: `skills/codify-insight/SKILL.md`
- 起動: 次回 /orchestrate 開始時、`docs/cycles/` をスキャンして `retro_status: captured` がある Cycle が見つかったら自動起動（新 Cycle 開始の前段）
- 処理: captured insights を cycle 単位で自動 triage する
  - 次 cycle の TDD を即 harden できるもの → `codified`（通常 `rule` / `inline-update`）
  - post-TDD の広い改善や follow-up が妥当なもの → `deferred`（通常 `new-cycle`）
  - observation-only / duplicate / 2nd-order note → `no-codify`
  - `skill` 候補や low-confidence 時のみ AskUserQuestion を使う（1 insight ごとではなく 1 cycle につき 1 回の batch 確認を優先）
- 全 insight 処理完了で `retro_status: resolved` に遷移
- codify 実行自体は強制しない

### 学びゼロケース

- 抽出結果が空の場合、`## Retrospective` に `No reusable lesson this cycle` を残し `retro_status: resolved` で完了
- decide gate もスキップ（処理対象なし）

## Consequences

- 知見の codify ループが閉じる。failure-success ペアを retrospective が、横断観測パターンを learn/evolve が担う、という責務分離が成立する
- /orchestrate 起動時に decide gate が走るため、初回適用時には既存 cycle に対して captured が無い前提（migration 不要）
- LLM 抽出失敗時の override 経路により hard-block を回避する一方、運用初期に override が多発する可能性がある。retry 件数と override 発生は flow-analyze（Step 3b）で監視対象とする
- 既存 learn / evolve / known-gotchas / DISCOVERED との境界を明文化する必要があるため、Step 1 実装時に workflow.md と architecture.md を同時更新する
- agile namespace を導入することで dev-crew のスキル数が増える。auto-discovery 劣化の兆候が出たら Deferred 項目（公開制限・narrow trigger）を発動する
