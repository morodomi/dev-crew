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

## 並列起動時の prompt 契約 (3+ subagent fan-out)

3 以上の subagent / reviewer / worker を並列起動する場合、各 prompt に以下を明示する:

- **担当範囲**: この subagent が扱う対象 (ファイル / モジュール / レイヤー)
- **入力**: 共通 Brief + 担当範囲固有のコンテキスト
- **出力形式**: 後段で統合可能な構造 (JSON / Markdown table / 固定 schema)
- **統合キー**: 他 subagent との突合 ID (file path / issue ID / finding category)
- **検証条件**: subagent 自身が出力前に確認すべき自己検証項目

並列度が上がるほど曖昧な prompt は曖昧な出力を増幅する。単一委譲なら「Files list 全量列挙」で足りるが、N=3+ では統合可能性まで設計する必要がある。

「読み取り並列・実行直列」の原則（テストを実行するプロセスは tree 書き込み・他のテスト実行と直列化）を守り、各並列 prompt に「テスト実行可否」（full suite / 個別 / 禁止）を明示する (cycle 20260702_1200 #2)。

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
