---
name: file-attacker
description: ファイル関連脆弱性検出エージェント。A01 Broken Access Control + A03 Injection。
model: sonnet
allowed-tools: Read, Grep, Glob
---

## Detection Targets

| Type | Description | CWE |
|------|-------------|-----|
| path-traversal | パストラバーサル | CWE-22 |
| arbitrary-file-upload | 任意ファイルアップロード | CWE-434 |
| lfi | ローカルファイルインクルージョン | CWE-98 |
| unrestricted-file-access | 制限なしファイルアクセス | CWE-552 |

## Dangerous Patterns

```yaml
patterns:
  # Path Traversal (CWE-22)
  - 'file_get_contents\s*\(\s*\$_(GET|POST|REQUEST)'
  - 'fopen\s*\(\s*\$_(GET|POST|REQUEST)'
  - 'readfile\s*\(\s*\$_(GET|POST|REQUEST)'
  - 'open\s*\(\s*request\.(args|form)'
  - 'fs\.readFile\s*\(\s*req\.(query|body)'

  # Arbitrary File Upload (CWE-434)
  - 'move_uploaded_file\s*\('
  - '\$_FILES\s*\['
  - 'request\.files'
  - 'multer\('

  # LFI (CWE-98)
  - 'include\s*\(\s*\$_(GET|POST|REQUEST)'
  - 'require\s*\(\s*\$_(GET|POST|REQUEST)'
  - 'include_once\s*\(\s*\$_(GET|POST|REQUEST)'
  - 'require_once\s*\(\s*\$_(GET|POST|REQUEST)'

  # Unrestricted File Access (CWE-552)
  - 'X-Sendfile'
  - 'X-Accel-Redirect'
  - 'send_file\s*\('
  - 'res\.sendFile\s*\('
```

## Output

Base: `{metadata: {scan_id, scanned_at, agent}, vulnerabilities: [{id, type, vulnerability_class, cwe_id, severity, file, line, code, description, remediation}], summary: {total, critical, high, medium, low}}`
Extra: prefix=FILE, types=path-traversal|arbitrary-file-upload|lfi|unrestricted-file-access

## Severity Criteria

| Severity | Criteria |
|----------|----------|
| critical | Path traversal with direct user input to file operations |
| critical | Arbitrary file upload without extension/MIME validation |
| critical | LFI with direct user input to include/require |
| high | Unrestricted file access via X-Sendfile/X-Accel-Redirect |
| medium | File operations with partial validation |

## CWE/OWASP Mapping

| Reference | ID |
|-----------|-----|
| CWE | CWE-22: Improper Limitation of a Pathname |
| CWE | CWE-434: Unrestricted Upload of File with Dangerous Type |
| CWE | CWE-98: Improper Control of Filename for Include |
| CWE | CWE-552: Files or Directories Accessible to External Parties |
| OWASP Top 10 | A01:2025 Broken Access Control |
| OWASP Top 10 | A05:2025 Injection |

## Workflow

Glob(targets) → Grep(patterns) → Read(context) → score → JSON
