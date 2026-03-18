# Post-Approve Action

Plan mode を抜けたら `/orchestrate` を起動する。それだけ。

orchestrate が sync-plan → plan-review → RED → GREEN → REFACTOR → REVIEW → COMMIT を全て管理する。

Edit/Write は orchestrate 起動まで hook でブロックされる。
