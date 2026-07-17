# Post-Approve Action

Plan mode を抜けたら `/orchestrate` を起動する。それだけ。

Codex plan review（承認前レビュー）は plan mode 内、spec Step 8（[skills/spec/reference.md](../../skills/spec/reference.md#step-8-pre-approval-plan-review)）で正規手順として実行済み。承認後の /orchestrate は sync-plan（転記）→ architect（転記後検証）→ RED → GREEN → REFACTOR → REVIEW → COMMIT を全て管理する。

Edit/Write を直接行わず、必ず /orchestrate に委譲すること。

## pre-approval plan review（正規手順）

- **承認前**: plan mode 内、spec Step 8 で `codex exec --sandbox read-only "review plan <path>"` を実行し、findings を draft plan へ直接反映、最終版を1回だけ再レビューする。これが正規の実行経路
- **承認後の plan review 再実行は禁止**: 承認後に Codex plan review を再度実行しない（scope 拡大が実測 3 cycle 連続で発生した旧フローの反省）
- **承認後 findings の 3 分岐**: sync-plan 転記後、architect が Post-Transfer Verification で以下の 3 分岐により判断する

| 分岐 | 条件 | アクション |
|------|------|-----------|
| 転記欠落 | Plan Review Record が Cycle doc に反映されていない | BLOCK |
| scope 実質変更 | 承認済み scope からの実質的な逸脱 | 再承認（AskUserQuestion） |
| 観察のみ | 軽微な観察事項 | DISCOVERED に記録 |

## 禁止事項

- `Skill(dev-crew:sync-plan)` の直接呼び出し禁止（sync-plan は Agent であり Skill ではない）
- **plan mode 内 pre-approval 実行は正規、承認後の再実行は禁止**（旧条項「`Skill(dev-crew:review --plan)` の /orchestrate 外での呼び出し禁止」を改訂。plan mode 内での review --plan・Codex plan review は spec Step 8 の一部として正規に実行される）
- sync-plan → architect → orchestrate のような分解実行禁止

全て `/orchestrate` に委譲すること。orchestrate が内部で適切に呼び出す。
