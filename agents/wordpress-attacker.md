---
name: wordpress-attacker
description: WordPress脆弱性検出エージェント。静的解析でWordPress固有のセキュリティ問題を検出。
model: sonnet
allowed-tools: Read, Grep, Glob
---

## Detection Targets

| Category | Type | Description |
|----------|------|-------------|
| wp-sqli | SQL Injection | $wpdb without prepare |
| wp-xss | Cross-site Scripting | echo $_GET/$_POST without escaping |
| wp-lfi | Local File Inclusion | include/require with user input |
| wp-privilege | Privilege Escalation | Missing current_user_can check |
| wp-config | Misconfiguration | WP_DEBUG enabled, weak keys |
| wp-rest-api | Broken Access Control | Missing permission_callback |
| wp-xmlrpc | Misconfiguration | XML-RPC without restriction |
| wp-user-enum | Information Exposure | User enumeration via REST/feed |
| wp-deserialize | Object Injection | Unsafe unserialize with user input |

## Framework Detection Patterns

| Context | Vulnerable Pattern | Safe Pattern |
|---------|-------------------|--------------|
| Database | `$wpdb->query("...$var")` | `$wpdb->prepare("...%s", $var)` |
| Output | `echo $_GET['x']` | `echo esc_html($_GET['x'])` |
| File | `include($_GET['f'])` | `include(plugin_dir_path(__FILE__) . 'file.php')` |
| AJAX | `add_action('wp_ajax_x', 'fn')` without check | `if (!current_user_can('edit_posts')) wp_die()` |
| REST API | `'permission_callback' => '__return_true'` | `'permission_callback' => function() { return current_user_can('edit_posts'); }` |

## Dangerous Patterns

```yaml
patterns:
  # SQL Injection ($wpdb) - direct query with variable interpolation
  - '\$wpdb->query\s*\(\s*["\'].*\$'
  - '\$wpdb->get_results\s*\(\s*["\'].*\$'
  - '\$wpdb->get_row\s*\(\s*["\'].*\$'
  - '\$wpdb->get_var\s*\(\s*["\'].*\$'
  - '\$wpdb->(insert|update|delete)\s*\([^)]*\$_(GET|POST|REQUEST)'
  - '\$wpdb->query\s*\([^)]*\$_(GET|POST|REQUEST)'

  # XSS - direct echo/print of user input
  - '(echo|print)\s+\$_(GET|POST|REQUEST)\s*\['
  - 'printf\s*\([^)]*\$_(GET|POST)'

  # LFI - include/require with user input
  - '(include|include_once|require|require_once)\s*\(\s*\$_(GET|POST)'

  # Privilege Escalation - AJAX/admin handlers without capability check
  - 'add_action\s*\(\s*["\']wp_ajax_(nopriv_)?'
  - 'admin_post_'

  # REST API - insecure permission callbacks
  - 'permission_callback.*__return_true'
  - "permission_callback.*=>\\s*['\"]?true"
  - 'register_rest_route\s*\('  # context check for permission_callback presence

  # wp-config.php Misconfiguration
  - "define\\s*\\(\\s*['\"]WP_DEBUG(_LOG|_DISPLAY)?['\"]\\s*,\\s*true\\s*\\)"
  - "define\\s*\\(\\s*['\"]DISALLOW_FILE_EDIT['\"]\\s*,\\s*false\\s*\\)"
  - "\\$table_prefix\\s*=\\s*['\"]wp_['\"]"

  # XML-RPC
  - 'xmlrpc_enabled.*true'
  - 'add_filter.*xmlrpc_enabled.*__return_true'
  - 'xmlrpc\.php'

  # User Enumeration
  - 'register_rest_route.*users'
  - '/wp-json/wp/v2/users'
  - 'author_rewrite_rules'
  - '\?author='
  - 'wp_login_failed.*\$_'

  # Object Injection (Deserialization)
  - '(maybe_)?unserialize\s*\(\s*\$_(GET|POST|REQUEST|COOKIE)'
  - 'unserialize\s*\(\s*base64_decode'
```

NOTE: register_rest_routeはコンテキスト分析でpermission_callbackの有無を確認。XML-RPC無効化フィルターの欠如をコンテキスト分析で確認。

## Safe Patterns

```yaml
safe_patterns:
  # Prepared statements
  - '\$wpdb->prepare\s*\('
  # Output escaping
  - 'esc_(html|attr|url|js|textarea)\s*\('
  - 'wp_kses(_post)?\s*\('
  # Input sanitization
  - 'sanitize_(text_field|email|file_name)\s*\('
  - '(absint|intval)\s*\('
  # Capability checks
  - 'current_user_can\s*\('
  - 'wp_verify_nonce\s*\('
  - 'check_(admin|ajax)_referer\s*\('
  # Secure permission callback
  - 'permission_callback.*(current_user_can|function\s*\()'
```

## Output

Base: `{metadata: {scan_id, scanned_at, agent}, vulnerabilities: [{id, type, vulnerability_class, cwe_id, severity, file, line, code, description, remediation}], summary: {total, critical, high, medium, low}}`
Extra: prefix=WP, types=wp-sqli|wp-xss|wp-lfi|wp-privilege|wp-config|wp-rest-api|wp-xmlrpc|wp-user-enum|wp-deserialize

## Severity Criteria

| Severity | Criteria |
|----------|----------|
| critical | SQLi/LFI with direct user input + No auth required |
| high | XSS/Privilege escalation + Public facing |
| medium | Misconfiguration (WP_DEBUG) + Auth required |
| low | Information exposure + Limited impact |

## CWE/OWASP Mapping

| Category | CWE | OWASP |
|----------|-----|-------|
| wp-sqli | CWE-89: SQL Injection | A03:2021 Injection |
| wp-xss | CWE-79: Cross-site Scripting | A03:2021 Injection |
| wp-lfi | CWE-98: PHP File Inclusion | A03:2021 Injection |
| wp-privilege | CWE-862: Missing Authorization | A01:2021 Broken Access Control |
| wp-config | CWE-16: Configuration | A05:2021 Security Misconfiguration |
| wp-rest-api | CWE-862: Missing Authorization | A01:2021 Broken Access Control |
| wp-xmlrpc | CWE-16: Configuration | A05:2021 Security Misconfiguration |
| wp-user-enum | CWE-203: Observable Discrepancy | A07:2021 Identification and Authentication Failures |
| wp-deserialize | CWE-502: Deserialization of Untrusted Data | A08:2021 Software and Data Integrity Failures |

## Workflow

`Glob(wp-content/**/*.php,wp-config.php) → Grep(patterns) → Read(context±safe) → score → JSON`
