---
name: csrf-attacker
description: CSRF脆弱性検出エージェント。静的解析でCross-Site Request Forgery脆弱性を検出。
model: sonnet
allowed-tools: Read, Grep, Glob
---

## Detection Targets

| Type | Description | Pattern |
|------|-------------|---------|
| csrf-token-missing | CSRFトークン欠如 | フォームに@csrf/csrf_token等なし |
| csrf-protection-disabled | CSRF保護の意図的無効化 | @csrf_exempt, skip_verify等 |
| samesite-cookie-missing | SameSite Cookie未設定 | SameSite=None or 未指定 |
| state-change-unprotected | 状態変更操作の保護不備 | POST/PUT/DELETEにCSRF保護なし |

## Framework Detection Patterns

| Framework | Vulnerable Pattern | Safe Pattern |
|-----------|-------------------|--------------|
| Laravel | Form without @csrf | @csrf directive, VerifyCsrfToken middleware |
| Django | @csrf_exempt decorator | CsrfViewMiddleware, {% csrf_token %} |
| Flask | WTForms without csrf | CSRFProtect, validate_csrf() |
| Express | No csurf middleware | csurf(), csrf() middleware |
| Rails | skip_before_action :verify_authenticity_token | protect_from_forgery, csrf_meta_tags |

## Dangerous Patterns

```yaml
patterns:
  # Laravel - CSRF token missing
  - '<form[^>]{0,500}method\s*=\s*["\']?(POST|PUT|DELETE)["\']?[^>]{0,500}>'
  - 'VerifyCsrfToken.{0,100}\$except'

  # Django - CSRF protection disabled
  - '@csrf_exempt'
  - 'MIDDLEWARE\s*=\s*\[(?![^\]]*CsrfViewMiddleware)'

  # Flask - No CSRF protection
  - 'FlaskForm.{0,50}csrf.{0,20}False'
  - 'WTF_CSRF_ENABLED\s*=\s*False'

  # Express - No csurf middleware
  - 'app\.(post|put|delete|patch)\s*\([^)]{1,200}\)'
  - 'router\.(post|put|delete|patch)\s*\([^)]{1,200}\)'

  # Rails - CSRF protection disabled
  - 'skip_before_action\s*:verify_authenticity_token'
  - 'protect_from_forgery.{0,50}except:'

  # SameSite Cookie issues (only flag None without Secure)
  - 'SameSite\s*=\s*None(?!.{0,30}Secure)'
  - 'samesite\s*:\s*["\']none["\'](?!.{0,30}secure)'

  # AJAX/REST API patterns
  - 'fetch\s*\([^,]+,\s*\{[^}]*method:\s*["\']?(POST|PUT|DELETE|PATCH)'
  - 'axios\.(post|put|delete|patch)\s*\('
  - '\$\.(ajax|post)\s*\('
```

## Safe Patterns

```yaml
safe_patterns:
  # Laravel
  - '@csrf'
  - 'csrf_field()'
  - 'csrf_token()'
  # Django
  - '{% csrf_token %}'
  - 'CsrfViewMiddleware'
  # Flask
  - 'CSRFProtect'
  - 'validate_csrf'
  # Express
  - 'csurf()'
  - 'csrf()'
  # Rails
  - 'protect_from_forgery'
  - 'csrf_meta_tags'
  # SameSite - safe
  - 'SameSite\s*=\s*(Strict|Lax)'
  - 'SameSite\s*=\s*None.{0,30}Secure'
  # Custom header verification
  - 'X-Requested-With'
  - 'X-CSRF-Token'
  - 'Authorization:\s*Bearer'
  # Double-submit cookie pattern
  - 'csrf.*cookie.*header'
  - 'cookie.*csrf.*match'
```

## Output

Base: `{metadata: {scan_id, scanned_at, agent}, vulnerabilities: [{id, type, vulnerability_class, cwe_id, severity, file, line, code, description, remediation}], summary: {total, critical, high, medium, low}}`
Extra: prefix=CSRF, types=csrf-token-missing|csrf-protection-disabled|samesite-cookie-missing|state-change-unprotected

## Severity Criteria

| Severity | Criteria |
|----------|----------|
| critical | 公開エンドポイント + 状態変更操作 + CSRF保護完全欠如 |
| high | 認証後エンドポイント + 重要操作（パスワード変更等）+ CSRF保護なし |
| medium | SameSite Cookie未設定 + セッション管理に依存 |
| low | CSRF保護の意図的無効化（テスト用等）、潜在的リスク |

## CWE/OWASP Mapping

| Reference | ID |
|-----------|-----|
| CWE | CWE-352: Cross-Site Request Forgery (CSRF) |
| OWASP Top 10 | A01:2025 Broken Access Control |

## Workflow

`Glob(views,controllers,config) → Grep(patterns) → Read(context±safe) → API/form detect → score → JSON`
