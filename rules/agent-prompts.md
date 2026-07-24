---
paths:
  - "docs/cycles/**"
---
# Agent Prompts — architect / subagent 委譲の契約

architect や subagent へ委譲する際のプロンプト設計規律。scope drift を防ぎ、Files list の完全伝達を保証する。

## 禁止事項

- **sloppy な Files list 伝達**: architect 依頼時に「plan の Files to Change 参照」とだけ書き、全量列挙を省略しない。scope drift の原因になる (cycle 20260421_1809 #1, cycle 20260420_1752 #2)
- **間接的ファイルの黙示**: agents/*.md など間接的に影響するファイルは明示列挙せよ。暗黙期待は落とされやすい

## 推奨

- architect / sync-plan プロンプトに以下の一文を含める:
  「plan v\<N\> の Files to Change を全量尊重すること。独自判断で追加・削除しないこと」
- 影響範囲に agents/*.md が含まれる場合は個別ファイル名を列挙する
- scope が確定したら Files list を verbatim でコピー & paste して伝達する
- 委譲 prompt の「完了時の義務」に、フェーズ記録（Progress Log 見出し・frontmatter updated）の timestamp を date "+%Y-%m-%d %H:%M" の実測値で記録する契約を明記する。LLM は実測なしでは「もっともらしい時刻」を推定生成する。updated は gate の選択キーであり逆行・未来値は決定性を汚染する (cycle 20260706_1216 #3)
- 委譲 prompt テンプレートに、委譲 worker のフェーズ完了マーカー（`<PHASE> ... Phase completed`）を gate が読める形で Progress Log に記録する義務を必須項目化する。sync-plan 相当を代行する場合の SYNC-PLAN 完了マーカー欠落は pre-red-gate を BLOCK し得る（2 回再発 → 2-strike で自動契約化） (docs/cycles/20260717_1126_approval-reorder.md #4)
- timestamp 契約（cycle 20260706_1216 #3）を「委譲 prompt」から「Progress Log 追記全般（orchestrator 自身の追記を含む）」へ拡張する。timestamp を含む追記は `TS=$(date "+%Y-%m-%d %H:%M")` を追記コマンドと同一ステップの先頭で実測し変数展開で埋め込む。別ステップでの実測は世代がずれる (docs/cycles/20260721_1503_rules-load-trigger-reclassification.md #2)
- 二次検証者（独立再計算・MATCH 主張）には一次と異なる実装（別言語/別ツール）を使わせる。検証者が被検証者の実装を流用すると同一バグを再現して false MATCH を出す (docs/cycles/20260717_1126_approval-reorder.md #1)

## 並列起動時の prompt 契約 (3+ subagent fan-out)

3 以上の subagent / reviewer / worker を並列起動する場合、各 prompt に以下を明示する:

- **担当範囲**: この subagent が扱う対象 (ファイル / モジュール / レイヤー)
- **入力**: 共通 Brief + 担当範囲固有のコンテキスト
- **出力形式**: 後段で統合可能な構造 (JSON / Markdown table / 固定 schema)
- **統合キー**: 他 subagent との突合 ID (file path / issue ID / finding category)
- **検証条件**: subagent 自身が出力前に確認すべき自己検証項目

並列度が上がるほど曖昧な prompt は曖昧な出力を増幅する。単一委譲なら「Files list 全量列挙」で足りるが、N=3+ では統合可能性まで設計する必要がある。

「読み取り並列・実行直列」の原則（テストを実行するプロセスは tree 書き込み・他のテスト実行と直列化）を守り、各並列 prompt に「テスト実行可否」（full suite / 個別 / 禁止）を明示する (cycle 20260702_1200 #2)。

同じ規約違反が複数 worker で再発する場合、原因は worker ではなく委譲 prompt の共通テンプレートにある。違反除去と同時に指示テンプレートを疑い grep 監査する (cycle 20260703_1650 #1)。

## 具体例

```markdown
## architect への委譲プロンプト例

plan v3 の実装を依頼します。
Files to Change（全量、追加・削除禁止）:
- skills/orchestrate/SKILL.md
- agents/orchestrate.md
- docs/cycles/20260420_1752_xxx.md

plan v3 の Files to Change を全量尊重し、独自判断で追加・削除しないこと。
特に agents/orchestrate.md は間接的変更なので必ず含めること。
```

## 出典

- `docs/cycles/20260420_1752_v2.8-orchestrate-integration.md` Insight 2
- `docs/cycles/20260421_1809_sync-plan-progress-log-format.md` Insight 1
- 会話レビュー (2026-05-25): Kimi Agent Swarm 記事の "synthesis bottleneck" 抽象原則 (`## 並列起動時の prompt 契約` の根拠)
- cycle 20260702_1200 #2
- cycle 20260703_1650 #1 — 再発違反の原因は委譲 prompt テンプレート
- cycle 20260706_1216 #3 — 委譲 worker のフェーズ記録 timestamp は date 実測必須
- `docs/cycles/20260717_1126_approval-reorder.md #4` — 委譲 worker のフェーズ完了マーカーを必須項目化（2-strike）
- `docs/cycles/20260717_1126_approval-reorder.md #1` — 二次検証者の実装独立性（被検証者の実装を流用しない）
- `docs/cycles/20260721_1503_rules-load-trigger-reclassification.md #2` — timestamp 契約を Progress Log 追記全般へ拡張
