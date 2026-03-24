# Roadmap

> 完了済みの Phase 1-10 は [docs/archive/development-plan.md](docs/archive/development-plan.md) を参照。
> 完了済みの v2/v2.4/v2.5/v2.6/v2.7/v3 は [docs/archive/roadmap-v2-v3-completed.md](docs/archive/roadmap-v2-v3-completed.md) を参照。

## 現在地

v2.6.0 リリース済み。全完了済みバージョン:
- v2 (Phase 11-13): Claude + Codex 統合開発フロー
- v2.4 (Phase 14-17): Review Taxonomy 体系化 (33→40 agents)
- v2.5 (Phase 18): Constitution-Driven Enforcement
- v2.6 (Phase 26-29): スキル成熟化 (Gotchas, On-demand hooks, PLUGIN_DATA)
- v2.7 (Phase 24-25): 動的スキルコンテンツ注入
- v3 (Phase 1-8): Constitution-Driven Development

次: v2.6.x (構造厳格化 + Verification + Automation)

---

## v2.6.x: 構造厳格化 + Verification + Automation

v2.6.0 の品質強化に続き、構造規約・検証・自動化を追加する。

### Phase 30: ディレクトリ構造厳格化

docs/cycles/ の構造規約をルール化し、検証スクリプトで決定論的に強制する。Phase 31 で検証証跡を追加する前に構造契約を定める。

| 項目 | 内容 |
|------|------|
| 対象 | docs/cycles/ の必須構造（Cycle doc フォーマット、ファイル命名規約） |
| スコープ | machine-critical invariants のみ |
| 検証スクリプト | test-directory-structure.sh 新設 |
| onboard 反映 | onboard スキルのテンプレートに構造規約を反映 |

### Phase 31: Product Verification PoC

REFACTOR 後に実装結果を自動検証し、REVIEW の入力証跡とする。1プロジェクトで PoC。汎用化は実需が出てから。

**決定事項**（Socrates + Codex レビュー反映）:
- 挿入位置: **REFACTOR 後・REVIEW 前**に確定（CONSTITUTION 原則6）
- 性質: blocking gate ではなく **advisory evidence**
- 汎用フレームワーク設計は PoC 後まで行わない（YAGNI）
- 証跡はリポジトリ外保存、Cycle doc にはポインタのみ

| 項目 | 内容 |
|------|------|
| 位置づけ | REFACTOR → **Verification** → REVIEW |
| PoC 対象 | Web UI ありのプロジェクト1件（Playwright 適用可能） |
| 証跡保存 | `/tmp` or `.gitignore` 配下。Cycle doc にパス参照のみ |
| テスト | 検証スクリプトの実行・証跡ポインタ生成テスト |

### Phase 32: babysit-pr（GitHub Actions ベース）

COMMIT 後の PR マージ監視。GitHub Actions + gh CLI で決定論的に実装。dev-crew は commit 後に有効化を提案するのみ。

**決定事項**（Socrates + Codex レビュー反映）:
- Claude トークンで監視ループを回さない（CONSTITUTION 原則6）
- LLM 責務外（CONSTITUTION Section 6）
- GitHub Actions reusable workflow として dev-crew リポジトリ外で管理

| 項目 | 内容 |
|------|------|
| 実装 | .github/workflows/babysit-pr.yml（reusable workflow） |
| flaky CI | 1回失敗→自動再実行、2回連続→通知 |
| ガードレール | max retry: 2回、stale PR: 7日で通知、audit log |
| dev-crew 連携 | commit スキルが PR 作成後に Actions 有効化を提案 |

---

## 方針

- 各サブタスクは独立した TDD サイクルで実施
- security 系エージェント/スキルは現状維持
