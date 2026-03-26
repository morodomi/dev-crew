# Post-Approve Action

Plan mode を抜けたら `/orchestrate` を起動する。それだけ。

orchestrate が sync-plan → plan-review → RED → GREEN → REFACTOR → REVIEW → COMMIT を全て管理する。

Edit/Write を直接行わず、必ず /orchestrate に委譲すること。

## 禁止事項

- `Skill(dev-crew:sync-plan)` の直接呼び出し禁止（sync-plan は Agent であり Skill ではない）
- `Skill(dev-crew:review --plan)` の /orchestrate 外での呼び出し禁止
- sync-plan → plan-review → orchestrate のような分解実行禁止

全て `/orchestrate` に委譲すること。orchestrate が内部で適切に呼び出す。
