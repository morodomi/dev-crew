# Integration Verification — real-path invocation で config gap を検出する

unit test は mock/direct call を使うと「宣言された config/option が production path で呼ばれていない」gap を見逃す (can miss when tests bypass runtime wiring)。Cycle の Verification Gate に real-path invocation を 1 件以上含めることで latent wire-gap を phase 内で検出する。

## 適用範囲

non-trivial cycle で strong recommended (advisory spirit 維持、non-blocking)。Verification section 不在 or real-path invocation なしの場合は orchestrate が WARN ログを出力するが、cycle は block しない。

## 禁止事項

- Verification section に `bash tests/test-*.sh` + `grep`/`diff` のみしか書かない (real-invocation ゼロ = structural test のみ)
- mock/stub で assertion するだけ
- echo / printf で動作を偽装

## 推奨 (project type 別)

- **CLI**: `python -m app --config path && grep <expected> /tmp/stdout`
- **Web**: `docker compose up -d && curl -fsS localhost:PORT/health && docker compose down`
- **Config 変更時** (motivating bug): `python -m myapp --config new.yaml && grep "loaded_from: new.yaml" /tmp/myapp.log`
- **Library**: `python -c "from mymod import run; run('config.yaml')"`
- **dev-crew 内 (bash/doc project)**: gate/consumer/validator を real path で実行 — 例 `bash scripts/gates/pre-commit-gate.sh $cycle_doc` or `bash scripts/validate-yaml-frontmatter.sh`。grep/diff のみは structural test として扱う

## Evidence 記録

`## Verification` section に bash code block で記述。orchestrate Block 2c.5 が自動実行し stdout/stderr を `/tmp/dev-crew-verify-{cycle-id}/` に保存。exit code は `|| true` で吸収 (advisory 維持)。

## 出典

- Kyotei YAML config wire-gap bug (別 repo、2026-04-24 発見)
- `docs/cycles/20260424_0900_integration-verification-rule.md` — integration verification rule codify cycle
- `docs/cycles/20260423_1045_discovered-cycle2-followup.md` Insight 1 (REFACTOR full-suite baseline 必須) の対称ルール
