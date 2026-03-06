# Usability Design

## Installation UX

### Current (tdd-skills)

```bash
# 12回のinstallが必要
/plugin install tdd-core@tdd-skills
/plugin install tdd-php@tdd-skills
/plugin install tdd-python@tdd-skills
/plugin install tdd-ts@tdd-skills
/plugin install tdd-js@tdd-skills
/plugin install tdd-flask@tdd-skills
/plugin install tdd-flutter@tdd-skills
/plugin install tdd-hugo@tdd-skills
/plugin install redteam-core@redteam-skills
/plugin install note-skills@note-skills
/plugin install novel-skills@novel-skills
/plugin install meta-skills           # 未install
```

### Target (dev-crew)

```bash
# 開発環境は1コレクションから
/plugin install core@dev-crew
/plugin install php@dev-crew        # 必要な言語のみ
/plugin install security@dev-crew   # 任意
/plugin install meta@dev-crew       # 任意
```

## Trigger Keyword UX

### Principle

- 日本語と英語の両方でトリガー可能
- TDD用語に依存しすぎない（「テスト書いて」だけでなく「red」も可）
- 自然な会話から起動

### Keyword Map

| Intent | Japanese | English | Skill |
|--------|----------|---------|-------|
| 新機能開発 | 「機能追加」「新しい機能」 | "new feature", "spec" | spec |
| キックオフ | 「キックオフ」 | "kickoff" | kickoff |
| テスト作成 | 「テスト書いて」 | "red", "write test" | red |
| 実装 | 「実装して」 | "green", "implement" | green |
| リファクタ | 「リファクタして」 | "refactor" | refactor |
| レビュー | 「レビューして」 | "review" | review |
| コミット | 「コミットして」 | "commit" | commit |
| バグ調査 | 「原因調査」 | "investigate", "diagnose" | diagnose |
| セキュリティ | 「セキュリティスキャン」 | "security scan" | security-scan |
| 学習 | 「パターン抽出」 | "learn" | learn |

## Phase Transition UX

### Automatic (orchestrate mode)

```
User: 「ログイン機能を追加して」
  -> plan mode: INIT -> 探索 -> 設計 -> Test List -> QA -> approve
  -> normal mode: KICKOFF -> review(plan) -> RED -> GREEN -> /simplify -> review(code) -> COMMIT
  -> PdM: 「完了しました。PRを作成しますか？」
```

ユーザーが介入するのは:
1. INITでの要件確認
2. WARN/BLOCKでの判断
3. COMMIT後のPR作成判断

### Manual (skill-by-skill)

```
User: /spec
User: /plan
User: /red
User: /green
User: /refactor
User: /review
User: /commit
```

各フェーズを手動で実行。学習・確認したいときに使用。

## Compaction UX

### Transparent to User

フェーズ境界compactionはユーザーに意識させない:

```
PdM: 「PLANフェーズ完了。Test List:
  1. ログインフォーム表示テスト
  2. 認証成功テスト
  3. 認証失敗テスト

  REDフェーズに進みます。」

[内部: Cycle docに追記 -> /compact -> Cycle doc再読込]

PdM: 「REDフェーズを開始します。Test List項目1から...」
```

### Visible Feedback (StatusLine)

StatusLineに現在フェーズとtoken使用量を表示:

```
[PLAN] 45% ctx | 3/7 phases
```

## Error UX

### WARN (50-79)

```
PdM: 「review(plan)でWARN(score: 65)が出ました。」
Socrates: 「この設計には3つの懸念があります:
  1. ...
  2. ...
  3. ...」
PdM: 「どうしますか？ proceed / fix / abort」
```

### BLOCK (80-100)

```
PdM: 「review(code)でBLOCK(score: 85)です。修正が必要です。」
Socrates: 「Critical問題:
  1. [security] SQLインジェクション: user_input が未サニタイズ
  2. [correctness] null参照: line 42
  」
PdM: 「GREENに戻って修正します。」
```

## Cognitive Load Reduction

| Concern | Strategy |
|---------|----------|
| 多すぎるスキル名 | orchestrateで自動遷移。手動は7フェーズだけ覚える |
| レビュー結果の情報量 | Critical > Important > Optional で優先度表示 |
| token消費の不安 | StatusLineで残量可視化 |
| フェーズの現在位置 | Cycle docに進捗記録。途中復帰可能 |
