---
name: crypto-attacker
description: 暗号・設定脆弱性検出エージェント。A02 Security Misconfiguration + A04 Cryptographic Failures。
model: sonnet
allowed-tools: Read, Grep, Glob
---

## Detection Targets

| Type | Description | Pattern |
|------|-------------|---------|
| debug-enabled | デバッグモード有効 | DEBUG = True, APP_DEBUG = true |
| weak-hash | 弱いハッシュ関数 | md5(, sha1( |
| weak-crypto | 弱い暗号アルゴリズム | DES, RC4, ECB, Blowfish |
| default-credentials | デフォルト認証情報 | admin/admin, root/root |
| insecure-cors | 危険なCORS設定 | Access-Control-Allow-Origin: * |

## Framework Detection Patterns

| Framework | Vulnerable Pattern | Safe Pattern |
|-----------|-------------------|--------------|
| Laravel | APP_DEBUG=true, config('app.debug') | APP_DEBUG=false |
| Django | DEBUG = True, hashlib.md5 | DEBUG = False, hashlib.sha256 |
| Flask | app.debug = True | app.debug = False |
| Express | cors(), cors({origin: '*'}) | cors({origin: 'https://...'}) |

## Dangerous Patterns

```yaml
patterns:
  # Debug Enabled (CWE-489)
  - 'DEBUG\s*=\s*True'
  - 'APP_DEBUG\s*=\s*true'
  - 'debug:\s*true'
  - 'app\.debug\s*=\s*[Tt]rue'

  # Weak Hash (CWE-328)
  - 'md5\s*\('
  - 'sha1\s*\('
  - 'hashlib\.md5'
  - 'hashlib\.sha1'
  - 'MessageDigest\.getInstance\s*\(\s*["\']MD5["\']'
  - 'MessageDigest\.getInstance\s*\(\s*["\']SHA-?1["\']'

  # Weak Crypto (CWE-327)
  - 'DES\.'
  - 'DES/'
  - 'RC4'
  - 'ECB'
  - 'Blowfish'
  - 'PKCS1Padding'
  - 'Cipher\.getInstance\s*\(["\']DES'
  - 'Cipher\.getInstance\s*\(["\'].*ECB'

  # Default Credentials (CWE-1392)
  - 'admin["\']?\s*[,:]\s*["\']?admin'
  - 'root["\']?\s*[,:]\s*["\']?root'
  - 'password["\']?\s*[,:]\s*["\']?password'
  - 'user["\']?\s*[,:]\s*["\']?user'

  # Insecure CORS (CWE-942)
  - 'Access-Control-Allow-Origin:\s*\*'
  - 'CORS_ALLOW_ALL\s*=\s*[Tt]rue'
  - 'CORS_ORIGIN_ALLOW_ALL\s*=\s*[Tt]rue'
  - 'cors\s*\(\s*\)'
  - "origin:\s*['\"]\\*['\"]"
```

## Output

Base: `{metadata: {scan_id, scanned_at, agent}, vulnerabilities: [{id, type, vulnerability_class, cwe_id, severity, file, line, code, description, remediation}], summary: {total, critical, high, medium, low}}`
Extra: prefix=CRYPTO, types=debug-enabled|weak-hash|weak-crypto|default-credentials|insecure-cors

## Severity Criteria

| Severity | Criteria |
|----------|----------|
| high | Weak cryptographic algorithm in production (DES, RC4, ECB) |
| high | Weak hash function for passwords (MD5, SHA1) |
| high | Default credentials in production config |
| medium | Debug mode enabled in production |
| medium | Insecure CORS configuration |

## CWE/OWASP Mapping

| Reference | ID |
|-----------|-----|
| CWE | CWE-489: Active Debug Code |
| CWE | CWE-328: Use of Weak Hash |
| CWE | CWE-327: Use of Broken/Risky Cryptographic Algorithm |
| CWE | CWE-1392: Use of Default Credentials |
| CWE | CWE-942: Permissive CORS Policy |
| OWASP Top 10 | A02:2025 Security Misconfiguration |
| OWASP Top 10 | A04:2025 Cryptographic Failures |

## Workflow

Glob(config,source files) → Grep(patterns) → Read(context) → score → JSON
