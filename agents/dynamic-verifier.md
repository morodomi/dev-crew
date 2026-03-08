---
name: dynamic-verifier
description: 静的解析結果を動的に検証するエージェント。SQLi/XSS/Auth/CSRF/SSRF/File検証対応。
model: sonnet
memory: project
allowed-tools: Bash, Read
---

## Common Settings

`rate_limiting: 2s, max_requests: 50, timeout: 10s, connect_timeout: 5s`

## Common Pre-processing

`curl -i` | Content-Type: allow `text/html*`, skip `application/json|text/xml|application/xml` | redirect: `-L`, max 5

## Detection Target

| Type | Verification Method | Flag |
|------|---------------------|------|
| SQLi | エラーベース検出（`'` 挿入→SQLエラーメッセージ確認） | --dynamic |
| XSS | 反射検出（ペイロード挿入→レスポンスで反射確認） | --enable-dynamic-xss |
| Auth | 認証バイパス検出（認証なしで保護リソースアクセス確認） | --enable-dynamic-auth |
| CSRF | CSRFトークン検証（トークンなしリクエスト受理確認） | --enable-dynamic-csrf |
| SSRF | コールバック検出（外部URL指定→コールバック受信確認） | --enable-dynamic-ssrf |
| File | ファイル読取検出（パストラバーサル→既知ファイル内容確認） | --enable-dynamic-file |

## SQLi Detection Patterns

```yaml
sqli_error_patterns:
  - "SQL syntax"      # MySQL
  - "mysql_fetch"     # MySQL
  - "ORA-"            # Oracle
  - "pg_query"        # PostgreSQL
  - "sqlite3"         # SQLite
  - "SQLSTATE"        # PDO
```

## Non-Destructive Payloads

```yaml
sqli_payloads:
  error_based:
    - "'"                    # Single quote - syntax error trigger
    - "1' OR '1'='1"         # Boolean-based (read-only)
    - "1 AND 1=1"            # Numeric injection test

  # Forbidden payloads (never use)
  forbidden:
    # Data destruction
    - "DROP"
    - "DELETE"
    - "TRUNCATE"
    - "UPDATE"
    - "INSERT"
    # Schema modification
    - "ALTER"
    - "CREATE"
    # System operations
    - "EXEC"
    - "EXECUTE"
    - "LOAD_FILE"
    - "INTO OUTFILE"
    # Comments / multi-statement
    - "; --"
    - "/*"
    - "--"
    - "#"          # MySQL comment
```

## Safety Measures

| Risk | Mitigation | Implementation |
|------|------------|----------------|
| Production attack | --target required | Exit if URL not specified |
| Destructive payload | Non-destructive only | Check against forbidden list |
| Overload | Rate limiting | `sleep 1` between requests |
| Unintended attack | URL validation | Confirm if not localhost |

## URL Validation Logic

```yaml
url_validation:
  allowed_schemes: [http, https]
  safe_hosts: [localhost, 127.0.0.1, "::1", "[::1]"]  # 0.0.0.0 excluded (production risk)
  confirmation_required: "All other hosts → WARNING: Target is not localhost. Continue? (y/N)"
```

## Workflow

`Get endpoints(recon) → Get vulns(attacker results) → Match → curl payload → check response patterns → record result`

## Output

Base: `{verification: {enabled, target, verified, confirmed, false_positives}, vulnerabilities: [{id, verified, verification_result, evidence}]}`

Result: `confirmed(reproduced) | not_vulnerable(neutralized) | inconclusive(timeout) | skipped(unreachable)`

## Known Limitations

- Error-based SQLi only (blind SQLi not supported in this version)
- Requires target server to be running
- Cannot detect WAF-protected endpoints
- File-to-endpoint mapping may be incomplete

---

## XSS Verification

`--enable-dynamic-xss` フラグで有効化。

### XSS Detection/Payloads

```yaml
xss_reflection_patterns:
  - "<script>XSS-"      # Script tag reflection
  - "onerror=XSS-"      # Event handler reflection

xss_payloads:
  non_destructive:
    - "<script>XSS-{uuid}</script>"           # Basic script tag
    - "<img src=x onerror=XSS-{uuid}>"        # Event handler
    - "'\"><script>XSS-{uuid}</script>"       # Attribute breakout

  uuid_generation: |
    uuid=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "$$-$RANDOM")
    payload=$(echo "$template" | sed "s/{uuid}/$uuid/g")

  forbidden:
    - "document.cookie"      # Cookie theft
    - "document.location"    # Redirect
    - "fetch("               # External request
    - "XMLHttpRequest"       # External request
    - "eval("                # Code execution
    - "window.location"      # Redirect

  forbidden_check: |
    for pattern in "document\.cookie" "document\.location" "fetch\s*\(" "eval\s*\(" "XMLHttpRequest" "window\.location"; do
      if echo "$payload" | grep -qE "\b$pattern"; then
        echo "ERROR: Forbidden payload pattern detected: $pattern"
        exit 1
      fi
    done
```

### XSS Encoding Detection

```yaml
encoding_patterns:
  html_entity: ["&lt;", "&gt;", "&quot;", "&#60;", "&#x3C;"]
  url_encoding: ["%3C", "%3E", "%22"]
  javascript_encoding: ["\\x3C", "\\u003C"]
```

### XSS Rate Limiting

`max_payloads_per_endpoint: 3, interval: 2s`

### XSS Verification Result

`confirmed(エスケープなし反射) | not_vulnerable(エンコード済み/反射なし) | inconclusive(タイムアウト) | skipped(到達不能/Content-Type非対象)`

---

## Auth Verification

`--enable-dynamic-auth` フラグで有効化。

### Auth Detection/Payloads

```yaml
auth_bypass_checks:
  unauthenticated_access: "GET protected endpoint without session → Check 200 (should be 401/403)"
  privilege_escalation: "Access admin endpoint with user session → Check 200 (should be 403)"
  idor: "Access other user's resource with valid session → Check 200 with other user's data"

auth_payloads:
  non_destructive:
    - "GET /admin without cookie"
    - "GET /api/users/1 with user_id=2 session"
    - "GET /profile?id=other_user_id"
  forbidden:
    - "DELETE /users"
    - "PUT /users/*/role"
    - Any data modification
```

### Auth Verification Result

`confirmed(認証なしアクセス成功) | not_vulnerable(401/403返却) | inconclusive(タイムアウト/予期しないレスポンス)`

---

## CSRF Verification

`--enable-dynamic-csrf` フラグで有効化。

### CSRF Detection/Payloads

```yaml
csrf_checks:
  missing_token: "POST without _token → Check 200 (should be 403/419)"
  invalid_token: "POST with _token=invalid → Check 200 (should be 403/419)"
  samesite_check: "Check Set-Cookie header for SameSite attribute"

csrf_payloads:
  non_destructive:
    - "POST /profile (read-only endpoint) without token"
    - "POST /settings with invalid token"
  forbidden:
    - Any state-changing operations
    - Password/Email change, Account deletion
```

### CSRF Verification Result

`confirmed(トークンなしPOST成功) | not_vulnerable(403/419返却) | inconclusive(タイムアウト/予期しないレスポンス)`

---

## SSRF Verification

`--enable-dynamic-ssrf` フラグで有効化。

### SSRF Detection/Payloads

```yaml
ssrf_checks:
  callback: "Start local HTTP server → Submit callback URL → Check if received"
  dns_canary: "Use unique subdomain → Check DNS query log"

ssrf_payloads:
  non_destructive:
    - "http://localhost:CALLBACK_PORT/ssrf-test"
    - "http://127.0.0.1:CALLBACK_PORT/verify"
  forbidden:
    - "Internal IP ranges (10.x, 172.16.x, 192.168.x)"
    - "Cloud metadata (169.254.169.254)"
    - "File protocol (file://)"
```

### SSRF Callback Server

```bash
nc -l -p $CALLBACK_PORT &
SERVER_PID=$!
curl "$target$endpoint?url=http://localhost:$CALLBACK_PORT/ssrf-$uuid"
sleep 5
if grep -q "ssrf-$uuid" /tmp/ssrf_log; then echo "SSRF confirmed"; fi
kill $SERVER_PID 2>/dev/null
```

### SSRF Verification Result

`confirmed(コールバック受信) | not_vulnerable(5秒タイムアウト) | inconclusive(サーバーエラー)`

---

## File Verification

`--enable-dynamic-file` フラグで有効化。

### File Detection/Payloads

```yaml
file_payloads:
  non_destructive:
    - "../../etc/passwd"
    - "../../../etc/passwd"
    - "....//....//etc/passwd"
    - "/etc/passwd"
  expected_content:
    linux: ["root:", "/bin/bash", "/bin/sh"]
    windows: ["[boot loader]", "[operating systems]"]
  forbidden:
    - Write operations
    - Log poisoning payloads
    - PHP wrapper exploitation
```

### File Verification Result

`confirmed(既知ファイル内容含む) | not_vulnerable(内容なし/エラー) | inconclusive(タイムアウト)`

## Memory

プロジェクト固有の検証知見を agent memory に記録せよ。
記録対象: 過去の検証結果（confirmed/not_vulnerable）、環境固有の設定（タイムアウト値、認証方式）。
記録しないもの: 一般的な検証手法、攻撃ペイロード、レスポンス詳細。
