# Security Audit Reference

## Overview

security-audit は、セキュリティスキャンとレポート生成を一括実行するオーケストレータスキルである。Task() を使用して security-scan、attack-report、generate-e2e を順次委譲し、完全な監査ワークフローを自動化する。

## Workflow Details

security-audit は以下の4ステップで構成される:

### Step 1: security-scan 実行

```
Task(subagent_type: "general-purpose", model: "sonnet",
  prompt: "Skill(dev-crew:security-scan) を実行。対象: [target] [options]")
```

security-scan スキルを呼び出し、脆弱性検出結果をJSON形式で取得する。

### Step 2: attack-report 生成

```
Task(subagent_type: "general-purpose", model: "sonnet",
  prompt: "Skill(dev-crew:attack-report) を実行。入力: [scan結果JSON]")
```

Step 1で得られたJSON結果を入力として、Markdownレポートを生成する。

### Step 3: generate-e2e 生成 (optional)

`--auto-e2e` 指定時のみ実行:

```
Task(subagent_type: "general-purpose", model: "sonnet",
  prompt: "Skill(dev-crew:generate-e2e) を実行。入力: [scan結果JSON]")
```

検出された脆弱性に対応するPlaywright E2Eテストを自動生成する。

### Step 4: 完了報告

全ステップ完了後、完了メッセージと出力ファイルパスを表示する。

### オプション伝播

コマンドライン引数は委譲先スキルに伝播される:

| Option | 委譲先 | 効果 |
|--------|--------|------|
| --full-scan | security-scan | 全13エージェントを並列実行 |
| --dynamic | security-scan | SQLi動的検証を有効化 |
| --target | security-scan | 動的テスト対象URL |
| --auto-e2e | security-audit | generate-e2e を自動実行 |

## Options

### --full-scan

security-scanで全13エージェントを並列実行する。デフォルトはCore 5エージェントのみ実行。

```
/security-audit --full-scan
```

詳細は [security-scan](../security-scan/SKILL.md) を参照。

### --auto-e2e

レポート生成後、自動的にPlaywright E2Eテストコードを生成する。

```
/security-audit --auto-e2e
```

詳細は [generate-e2e](../generate-e2e/SKILL.md) を参照。

### --dynamic

SQLi動的検証を有効化する。`--target` と併用必須。

```
/security-audit --dynamic --target http://localhost:8000
```

詳細は [security-scan](../security-scan/SKILL.md) を参照。

### --target

動的テスト対象のベースURL。`--dynamic` 指定時に必須。

```
/security-audit --target http://localhost:8000 --dynamic
```

## Output Examples

### 正常完了時 (Successfully completed)

```
================================================================================
SECURITY AUDIT完了
================================================================================
スキャン+レポート生成が完了しました。

結果サマリ:
- スキャン件数: Critical 0, High 2, Medium 1, Low 0
- レポート: reports/20260217_1234_security-audit.md
- E2Eテスト: tests/security/ (3 files)

================================================================================
```

### 脆弱性未検出時

```
================================================================================
SECURITY AUDIT完了
================================================================================
スキャン+レポート生成が完了しました。

結果サマリ:
- スキャン件数: 0件（脆弱性未検出）
- レポート: reports/20260217_1234_security-audit.md

================================================================================
```

## Error Handling

### security-scan 失敗時

security-scan が失敗した場合、エラーメッセージを表示して中断する。attack-report および generate-e2e は実行されない。

**エラー例**:
```
ERROR: security-scan failed
原因: 対象ディレクトリが見つかりません: ./invalid-path

監査を中断します。
```

### attack-report 失敗時

attack-report が失敗した場合、エラーメッセージを表示して中断する。generate-e2e は実行されない。

**エラー例**:
```
ERROR: attack-report failed
原因: スキャン結果JSONの形式が不正です

レポート生成を中断します。
```

### generate-e2e 失敗時

generate-e2e が失敗した場合、エラーメッセージを表示するが、スキャンとレポートは正常完了として扱う。

**エラー例**:
```
WARNING: generate-e2e failed
原因: tests/security/ ディレクトリが既に存在します（--force 不使用）

スキャン+レポートは正常に完了しました。
```

## Limitations

- 委譲先スキルの機能に依存（security-scan, attack-report, generate-e2e）
- 進捗表示なし（各スキルの実行完了を待つ）
- 中間結果の保存なし（失敗時は最初からやり直し）
- 並列実行なし（Task() を順次実行）

## References

- [security-scan](../security-scan/SKILL.md) - 脆弱性スキャン実行（RECON → SCAN → REPORT）
- [attack-report](../attack-report/SKILL.md) - JSON → Markdownレポート変換
- [generate-e2e](../generate-e2e/SKILL.md) - Playwright E2Eテスト自動生成
