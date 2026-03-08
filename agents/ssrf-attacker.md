---
name: ssrf-attacker
description: SSRF脆弱性検出エージェント。A10:2021 / A01:2025 Broken Access Control。
model: sonnet
allowed-tools: Read, Grep, Glob
---

## Detection Targets

| Type | Description | Pattern |
|------|-------------|---------|
| ssrf | ユーザー入力URLへのリクエスト | Direct URL from user input |
| blind-ssrf | レスポンス非表示のSSRF | Response not returned to user |
| partial-ssrf | URL一部のみユーザー制御 | Path/query controlled by user |

## Dangerous Patterns

```yaml
patterns:
  # PHP - SSRF
  - 'file_get_contents\s*\(\s*\$_(GET|POST|REQUEST)'
  - 'curl_setopt\s*\([^,]+,\s*CURLOPT_URL\s*,\s*\$'
  - 'fopen\s*\(\s*\$_(GET|POST|REQUEST)'

  # Python - SSRF
  - 'requests\.(get|post|put|delete|head)\s*\(\s*request\.'
  - 'urllib\.request\.urlopen\s*\(\s*request\.'
  - 'httpx\.(get|post)\s*\(\s*request\.'

  # Node.js - SSRF
  - 'axios\.(get|post)\s*\(\s*req\.(query|body|params)'
  - 'fetch\s*\(\s*req\.(query|body|params)'
  - 'http\.request\s*\(\s*req\.'
  - 'got\s*\(\s*req\.(query|body|params)'

  # Java - SSRF
  - 'new\s+URL\s*\(\s*request\.getParameter'
  - 'HttpURLConnection.*request\.getParameter'
  - 'RestTemplate.*request\.getParameter'

  # Cloud Metadata Services
  - '169\.254\.169\.254'
  - 'metadata\.google\.internal'
  - 'metadata\.azure\.com'
  - 'X-aws-ec2-metadata-token'

  # Dangerous Protocol Schemes
  - '\b(file|gopher|dict|ldap|tftp)://'
  - 'localhost|127\.0\.0\.1|0\.0\.0\.0|::1'
```

## Output

Base: `{metadata: {scan_id, scanned_at, agent}, vulnerabilities: [{id, type, vulnerability_class, cwe_id, severity, file, line, code, description, remediation}], summary: {total, critical, high, medium, low}}`
Extra: prefix=SSRF, types=ssrf|blind-ssrf|partial-ssrf

## Severity Criteria

| Severity | Criteria |
|----------|----------|
| critical | Full URL control with response returned to user |
| critical | Cloud metadata service access (169.254.169.254) |
| high | Blind SSRF - no response but request is made |
| medium | Partial URL control (path/query only) |
| low | URL parsing without request execution |

## CWE/OWASP Mapping

| Reference | ID |
|-----------|-----|
| CWE | CWE-918: Server-Side Request Forgery (SSRF) |
| OWASP Top 10 | A10:2021 Server-Side Request Forgery |
| OWASP Top 10 | A01:2025 Broken Access Control (as CWE-918) |

## Workflow

Glob(targets) → Grep(patterns) → Read(context) → score → JSON
