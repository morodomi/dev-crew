# Post-Approve Action

Plan mode を抜けたら（Accept 押下 / 「この plan を実行して」等）、直接実装に入らず以下を順に実行する:

1. Cycle Doc に内容をコピーする (`dev-crew:sync-plan`)
   - Cycle Doc なしの実装は `pre-red-gate.sh` でブロックされる
2. Cycle Doc をレビューする (`dev-crew:review --plan`)
   - BLOCK 判定なら Plan に戻る
3. レビュー通過後、実装フローを回す (`dev-crew:orchestrate`)
   - RED → GREEN → REFACTOR → REVIEW → COMMIT を自律管理
   - COMMIT 前に `pre-commit-gate.sh` で REVIEW 完了を検証

この順序のスキップは禁止。「急いでいる」「小さい変更」は理由にならない。
