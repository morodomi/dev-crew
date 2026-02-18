# Cycle: security-audit reference.md 追加

- Issue: #29
- phase: DONE
- Created: 2026-02-17

## Goal

`skills/security-audit/SKILL.md` (71 lines) に対応する `reference.md` を作成し、Progressive Disclosure パターンを完成させる。

## Context

- security-audit は Issue #27 で作成されたオーケストレータスキル
- security-scan → attack-report → (optional) generate-e2e を Task() で順次委譲
- 既存パターン: security-scan/reference.md (300行、詳細なワークフロー・スキーマ・エラーハンドリング)

## Acceptance Criteria

- [ ] `skills/security-audit/reference.md` が作成されている
- [ ] security-scan/reference.md と同等の Progressive Disclosure パターンに準拠
- [ ] ワークフロー詳細、オプション説明、エラーハンドリング、出力例を含む
- [ ] テストが通過する

## Test List

### Structure Tests (既存: tests/test-skills-structure.sh)

- [ ] TC-08: skills/security-audit/SKILL.md が存在する (PASS)
- [ ] TC-09: skills/security-audit/SKILL.md が100行以下 (PASS: 71行)
- [ ] TC-10: SKILL.md に name frontmatter がある (PASS)
- [ ] TC-11: SKILL.md に description frontmatter がある (PASS)

### Content Tests (新規: manual verification)

- [ ] TC-REF-01: reference.md が Overview セクションを含む
- [ ] TC-REF-02: reference.md が Workflow Details セクションを含む
- [ ] TC-REF-03: reference.md が Options セクションを含む
- [ ] TC-REF-04: reference.md が Output Examples セクションを含む
- [ ] TC-REF-05: reference.md が Error Handling セクションを含む
- [ ] TC-REF-06: reference.md が Limitations セクションを含む
- [ ] TC-REF-07: reference.md が References セクションを含む
- [ ] TC-REF-08: Options セクションに --full-scan の説明がある
- [ ] TC-REF-09: Options セクションに --auto-e2e の説明がある
- [ ] TC-REF-10: Options セクションに --dynamic の説明がある
- [ ] TC-REF-11: Options セクションに --target の説明がある
- [ ] TC-REF-12: Workflow Details が Task() 委譲フローを記述している
- [ ] TC-REF-13: Error Handling が security-scan 失敗時を記述している
- [ ] TC-REF-14: Error Handling が attack-report 失敗時を記述している
- [ ] TC-REF-15: Error Handling が generate-e2e 失敗時を記述している
- [ ] TC-REF-16: Output Examples が完了メッセージ例を含む
- [ ] TC-REF-17: References が security-scan, attack-report, generate-e2e を参照している

## Design

### Section Structure

reference.md は以下の7セクションで構成する (security-scan/reference.md パターンに準拠):

1. **Overview**
   - security-audit の役割: オーケストレータとして security-scan → attack-report → generate-e2e を順次実行
   - 一括実行の利点: 手動でスキル呼び出しを連鎖させる必要がない

2. **Workflow Details**
   - Step 1: security-scan 実行 (Task() で委譲)
     - オプション伝播: --full-scan, --dynamic, --target をそのまま渡す
     - 出力: JSON結果
   - Step 2: attack-report 実行 (Task() で委譲)
     - 入力: Step 1 の JSON結果
     - 出力: Markdown レポート
   - Step 3: generate-e2e 実行 (Task() で委譲、--auto-e2e 時のみ)
     - 入力: Step 1 の JSON結果
     - 出力: Playwright テストファイル
   - Step 4: 完了メッセージ表示

3. **Options**
   - --full-scan: 13エージェント並列実行 (security-scan に伝播)
   - --auto-e2e: レポート後に E2E テスト自動生成
   - --dynamic: SQLi 動的テストを有効化 (security-scan に伝播)
   - --target: 検証対象URL (--dynamic 時必須、security-scan に伝播)

4. **Output Examples** (順序変更: ポジティブ優先 - usability-reviewer 指摘)
   - 正常完了時の出力例 (Step 4 の完了メッセージ)
   - スキャン結果: 2C/3H/1M/0L
   - レポートパス: reports/security/YYYYMMDD_HHMM.md
   - --auto-e2e 時: tests/security/ に生成されたファイル一覧

5. **Error Handling**
   - security-scan 失敗時: エラーメッセージを表示し、中断 (attack-report 実行せず)
   - attack-report 失敗時: エラーメッセージを表示し、中断 (generate-e2e 実行せず)
   - generate-e2e 失敗時: エラーメッセージを表示 (スキャン+レポートは完了しているため、警告として扱う)

6. **Limitations**
   - 実際のスキャン・レポート・E2E生成ロジックは委譲先スキルに依存
   - 進捗表示なし (Task() が完了するまでブロック)
   - 中間結果の保存なし (各スキルが出力したファイルのみ残る)

7. **References** (各リンクに1行説明追加 - usability-reviewer 指摘)
   - [security-scan](../security-scan/SKILL.md) - 脆弱性スキャン実行（RECON→SCAN→REPORT）
   - [attack-report](../attack-report/SKILL.md) - スキャン結果をMarkdownレポートに変換
   - [generate-e2e](../generate-e2e/SKILL.md) - スキャン結果からPlaywright E2Eテスト自動生成

### Design Rationale

- **オーケストレータに特化**: security-audit は実装ロジックを持たず、Task() による委譲フローのみを記述
- **Progressive Disclosure**: SKILL.md (71行) はワークフロー概要のみ、reference.md は詳細なエラーハンドリング・オプション伝播・出力例を補完
- **security-scan/reference.md との差異**: security-scan は RECON → SCAN → REPORT の詳細フェーズを記述、security-audit は Task() 委譲フローのみ
- **テスト可能性**: TC-REF-01 ~ TC-REF-17 で各セクションの存在を検証可能

### Estimated Size

- security-scan/reference.md: 300行 (詳細なワークフロー・スキーマ・エラーハンドリング・Memory Integration)
- attack-report/reference.md: 264行 (CVSS 4.0 Vector Mapping, CWE/OWASP Mapping, Remediation Templates)
- generate-e2e/reference.md: 209行 (Template Variables, XSS/CSRF/Auth/SSRF Test Types)

**Estimated security-audit/reference.md**: 150-200行 (オーケストレータのためスキーマは不要、委譲フローとエラーハンドリングに集中)

## DISCOVERED

- TC-REF-13/14/15 の grep パターンをセクション内検索に改善 (correctness-reviewer WARN) → #33
- test script の I/O 重複最適化: ファイルを1回読み込み変数で再利用 (performance-reviewer WARN) → #34
- reference.md に Table of Contents 追加 (usability-reviewer WARN) → #35
