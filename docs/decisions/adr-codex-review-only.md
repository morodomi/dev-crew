# ADR: Codex をレビューだけに使い、codex_mode と steps-codex.md を消す

## Status: accepted

## Context

orchestrate は、RED/GREEN を Codex に委譲するかを `codex_mode`（full / no）で聞き、full のときだけ `skills/orchestrate/steps-codex.md` の手順で動かしていた。導入先の Cycle doc 128 件を実測した。

- full: 0 件
- no: 42 件（うち 9 件は引用符付きで記録されていた）
- 定義にない値（yes）: 4 件
- 記録なし: 82 件

full を選んだ記録は 1 件もない。答えが変わらない問いを毎回聞き、誰も通らない経路の手順・テスト・文書を手入れし続けるコストだけが残っていた。引用符付きの no や定義外の yes は、値の読み取りが記録の揺れに耐えていなかったことも示す。

Codex が実際に価値を出しているのはレビューの側で、承認前の plan review と code の REVIEW はどちらも read-only で動く。

## Decision Scorecard

| 項目 | 評価 | 理由 |
|------|------|------|
| Requirements Fit | 高 | 実測で使われていない経路を消し、使われている用途（レビュー）に絞る |
| Security | 高 | Codex が書き込む経路がなくなり、`codex exec` は全て read-only になる |
| Operability | 高 | 導入先の問いが 1 つ減り、2 通りの実行経路が 1 通りになる |
| Complexity | 高 | steps-codex.md と codex_mode の分岐・値の正規化が消える |
| Testability | 高 | 「codex_mode が無い」「workspace-write の呼び出しが 0 件」を構造テストで pin できる |

## Arguments

### Accepted
- codex_mode と steps-codex.md を消す。RED/GREEN と REVIEW の修正役は常に Claude の worker が担当する
- Codex はレビュー（承認前の plan review と code の REVIEW）だけに使い、どの呼び出しも read-only にする
- CONSTITUTION §4 の原則 3 を「Codex=Reviewer」に、原則 4 を「Codex が無いとき plan review は skip して記録し、code の REVIEW は adversarial-reviewer が代行する」に改める

### Rejected
- 既定値を `no` にして問いだけやめる案: 問いは消えるが、full の経路・手順・テストが残り、その手入れのコストが続く。誰も通らない経路を残す理由にならない

### Deferred
- `codex_session_id` は承認後に読む側が無くなる。plan の Plan Review Record 経由の転記を残すか消すかは別に判断する

## Decision

`codex_mode` と `skills/orchestrate/steps-codex.md` を消し、Codex はレビューだけに使う（read-only）。CONSTITUTION §4 の原則 3・4 を上の文言に改める。

## Consequences

- 導入先は `codex_mode` を聞かれなくなる
- 既に導入先へ配った CLAUDE.md には workspace-write の `codex exec` の行が残る。配り直しの扱いは #297、#247 で追う
- `codex_session_id` は承認後に読む側が無くなる。扱いは別に判断する
- RED/GREEN を Codex に任せたい導入先は、この経路を失う。実測では 0 件だった
