# Test Architecture の dev-crew 統合検討

## 背景

`Keiba/docs/test_architecture.md` にテストアーキテクチャ文書が完成した。
これを dev-crew にどう統合するかの選択肢とトレードオフを整理する。

## 選択肢

### A: `.claude/rules/test-architecture.md` としてルール化

全セッションで自動適用される。

**メリット**:
- 設定コスト最小。ファイルを置くだけ
- 全開発者 (AI含む) が同じ基準でテストを書く
- 既存の `tdd-workflow.md`, `testing-guide.md` と自然に共存

**デメリット**:
- コンテキストウィンドウを常に消費する (文書が長い場合)
- 強制力が強い。プロジェクトによっては過剰な場合がある
- rules は「常に適用」なので、テストを書かないタスク (docs, chore) でもロードされる

**実装**: `test_architecture.md` からルール向けの要約版 (30行程度) を抽出し、rules/ に配置。詳細は docs/ を参照させる。

### B: `test-review` スキル化

RED フェーズ後にテスト品質チェックを行う専用スキル。

**メリット**:
- 必要な時だけ呼び出せる。コンテキスト効率が良い
- テスト品質のチェックリストを詳細に定義できる
- WARN / BLOCK の判定ロジックを実装できる

**デメリット**:
- スキル開発コストがかかる (定義ファイル + エージェント)
- 呼び出しを忘れると機能しない (orchestrate に組み込む必要がある)
- RED → test-review → GREEN とフェーズが増え、サイクルが重くなる

**実装**: `skills/test-review/` にスキル定義。orchestrate の RED 後に自動呼び出しを追加。

### C: `red` スキルの拡張

既存 RED スキルに spec 生成ステップを追加する。

**メリット**:
- 既存フローに自然に統合。追加フェーズ不要
- RED フェーズの品質が上がる
- 開発者の学習コストゼロ

**デメリット**:
- RED スキルの責務が増える (テスト作成 + spec品質チェック)
- 既存の RED ワークフローを壊すリスク
- spec 品質チェックと テスト作成が密結合になる

**実装**: `red-worker` エージェントのプロンプトに spec チェックリストを追加。

## 決定

**Option C (red拡張) を採用。** (2026-03-06)

3者（Claude/Gemini/Grok）で統合方針を議論し合意。
「思想をルール化するだけでは行動が変わらない。red-workerのプロンプトに直接組み込むことで、テスト生成の質を上げる」が結論。

### 実装内容

1. `agents/red-worker.md` — Workflow に Step 0: Test Strategy Classification 追加
2. `skills/red/reference.md` — Test Architecture Guide セクション追加

### Option A を不採用とした理由

- ルールは全セッションでロードされるが、テスト戦略の判定が必要なのはREDフェーズのみ
- red-workerに直接組み込む方が、テスト作成の「行動」を確実に変えられる
- reference.md の Progressive Disclosure で詳細は必要時のみ参照
