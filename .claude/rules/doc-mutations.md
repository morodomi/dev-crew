# Doc Mutations — Cycle doc と plan file の不変性規則

Cycle doc の APPEND-ONLY 契約と plan file の IMMUTABLE 制約。情報の SSOT を守ることで drift を防ぐ。

## APPEND-ONLY 契約 (Cycle B #3)

Cycle doc の body は APPEND-ONLY。既存セクション内への middle-insert は違反:

- **禁止**: 既存 `## Progress Log` エントリの間に新エントリを挿入する
- **禁止**: 既存 Test List の TODO 項目を直接書き換える (状態遷移は WIP / DONE への移動のみ)
- **代替**: 新情報は常に EOF 方向の独立セクションとして追記する。既存 item を参照する場合は heading 名で言及する

## Plan File IMMUTABLE (Cycle B #4)

plan approve 後は plan file を編集しない (`rules/state-ownership.md` L7-10 準拠):

- **禁止**: Codex plan review での改訂指摘を plan file に反映する
- **正しい対応**: Codex 指摘は Cycle doc の Progress Log に反映し、Cycle doc を SSOT とする
- **根拠**: 同じ情報を 2 箇所 (plan file + Cycle doc) に持つと必ず drift する。SSOT 宣言で片方向更新を徹底

## 推奨

- Cycle doc の更新は常に追記方向。過去ログの書き換えは禁止
- plan file は approve スナップショットとして freeze。読み取り専用で参照する
- Codex review 指摘の適用先は Cycle doc の該当セクション

## 出典

- `docs/cycles/20260422_1146_codify-insight-skill.md` Insights 3, 4
