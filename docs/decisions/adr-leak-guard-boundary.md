# ADR-005: 公開 repo への固有名の混入をどこで止めるか（leak-guard-boundary）

## Status: accepted

## Context

dev-crew は公開 repo で、公開ポートフォリオとして維持する（docs/NEXT.md §1）。一方、cycle doc や issue には、dev-crew を使った非公開プロジェクトの名前や実 path が入り込む。

- 実害: 非公開プロジェクト名と持株会社名が tip に混入し、PR #230 で除去した。履歴には残っている
- 9 月の cycle で使った漏洩ガード（V-7）は、その cycle の Verification の中で 1 回動いただけで、repo には入っていない
- V-7 の穴（#225、#227 を統合）:
  - これから作る commit message と PR 本文を検査していない
  - diff 全体を見るので、既に commit 済みの名前が文脈行に現れると誤検知する
- 公開面は git の tip だけではない。issue / PR のコメントは commit を通らずに公開される

## Decision Scorecard

| 項目 | 評価 | 理由 |
|------|------|------|
| Requirements Fit | 高 | 実際に起きた混入経路（diff・commit message・PR / issue 本文）をすべて通る場所で止める |
| Security | 中 | 禁止語を知っている人が回避するのは止めない（目的は事故の防止） |
| Operability | 高 | 禁止語リストが無い環境では汎用の path 検査だけで動く |
| Complexity | 中 | 検査スクリプト 1 本 + PreToolUse hook 1 本。新しい状態ファイルは持たない |
| Testability | 高 | 一時 git repo と一時の禁止語リストで、実ツリーに触れずに検査できる |

## Arguments

### Accepted

- **検査する対象は 3 つ**: diff の追加行、commit message、PR / issue の本文。公開に至る経路をすべて覆う
- **追加行だけを見る**: 既に commit 済みの名前（文脈行）は検査しない。過去の混入は PR #230 で tip から除去済みで、履歴の扱いは別の判断（NEXT.md §2）
- **禁止語は repo の外から読む**: 既定は `~/.config/dev-crew/project-labels.tsv` の 2 列目。public な test やスクリプトに禁止語を直書きすると、それ自体が漏洩になる。環境変数 `DEV_CREW_LEAK_DENYLIST` で差し替えられる（テスト用）
- **汎用の検査は repo に置く**: ホームディレクトリ直下で、ドットで始まらない階層に入る実 path（`$HOME` 配下の Projects や Documents など）を禁止する。`plan_file` が使う `$HOME/.claude/plans/...` のようなドットで始まる階層は許可する（ユーザ名は保護対象に含めない。2026-09-10 の判断を踏襲）
- **止める場所は PreToolUse hook**: Claude Code が `git commit` / `git push` / `gh pr create|edit|comment` / `gh issue create|edit|comment` を実行する直前に、コマンド文字列（`-m` や `--body` の本文を含む）と、`-F` / `--body-file` で渡したファイル、commit・push の場合は追加行と commit message を検査し、見つかれば exit 2 で止める。規律（指示文）ではなく機械で止める
- **登録先は dev-crew repo の `.claude/settings.json`**: 対象は dev-crew だけ。plugin の `hooks/hooks.json` に置くと、dev-crew を使う非公開 repo にも効いてしまう
- **出力に禁止語を書かない**: 見つかった場所と「禁止語リストの何行目か」だけを出す。ログやターミナル出力の貼り付けから漏れないようにする

### Rejected

- **既 commit 済みの出現を allowlist で持つ**（#227 の案 b）: allowlist 自体が禁止語の一覧になる。追加行だけを見れば不要
- **plugin 全体の hook にする**: 非公開 repo では固有名を書くのが正しい。公開 repo だけの制約を全利用者に課さない
- **git の pre-commit / commit-msg hook にする**: `.git/hooks` は版管理されず、clone ごとに入れ直しが要る。issue / PR の本文も止められない
- **full suite の中で repo 全体を走査する**: 既存の履歴（tip に残る過去の cycle doc）を毎回走査することになり、追加行だけを見る方針と矛盾する。full suite には挙動テスト（一時 repo 上）だけを載せる

### Deferred

- 履歴（過去の commit）に残る固有名の扱い（NEXT.md §2 の A〜D）
- Claude Code を通さない操作（人間が手で打つ `git commit`、GitHub の Web UI での編集）。hook の範囲外

## Decision

`scripts/gates/leak-guard.sh`（本体は `leak-guard.py`）を検査に使い、dev-crew repo の `.claude/settings.json` に登録した PreToolUse（Bash）hook から呼ぶ。検査対象は diff の追加行・commit message・PR / issue の本文。禁止語は repo の外のファイルから読み、汎用の実 path 検査は repo に置く。

## Consequences

- Claude Code 経由の commit / push / PR / issue 操作で、固有名と実 path の混入が機械的に止まる
- 禁止語リストが無い環境（他の clone、CI）では、汎用の path 検査だけが動く
- コマンドは shell と同じ規則（Python の shlex）で引数に分解し、`&&` などで繋いだ操作を 1 つずつ検査する。`cd` と `git -C` は操作ごとの対象 repo に反映する。正規表現でコマンド文字列全体を見る方式は、引用符・スペース・global option・複合コマンドで検査が漏れたため採らない（初版の Codex review で再現）
- push は送る ref の未公開 commit を 1 つずつ検査する。追加して後の commit で消した禁止語も、その commit ごと公開されるため
- 対象の操作を含むのに検査できない場合（解析できないコマンド、git の失敗、python3 が無い）は止める。PreToolUse は exit 2 以外の異常終了を通してしまうため、失敗はすべて exit 2 にする
- 汎用の path 検査は、引数として渡すファイル path には適用しない。本文（`-m`、`--body`、`-F` / `--body-file` の中身）と追加行に適用する
- 例示のための path も止まる。ドキュメントやテストでは `$HOME` などの変数表記で書く
- 既に commit 済みの固有名は止めない。履歴の扱いは NEXT.md §2 で別に決める
- 誤検知した場合は、禁止語リストを直すか、本文の書き方を変える（hook を一時的に外す運用は作らない）
