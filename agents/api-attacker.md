---
name: api-attacker
description: API脆弱性検出エージェント。静的解析でAPI Security Top 10脆弱性を検出。
model: sonnet
allowed-tools: Read, Grep, Glob
---

## Detection Targets

| Type | Description | Pattern |
|------|-------------|---------|
| Mass Assignment | 一括代入脆弱性 | $request->all(), fillable未定義 |
| BOLA | オブジェクトレベル認可不備 | IDパラメータの権限チェック漏れ |
| Rate Limiting | レート制限なし | throttle未設定のAPI |
| Excessive Data Exposure | 過剰なデータ露出 | 全カラム返却、機密フィールド露出 |

## Framework Detection Patterns

| Framework | Vulnerable Pattern | Safe Pattern |
|-----------|-------------------|--------------|
| Laravel | `$request->all()`, `Model::create($input)` | `$request->only()`, `$fillable` |
| Django | `Model(**request.data)` | Serializer with fields |
| Flask | `Model(**request.json)` | Schema validation |
| Express | `Model.create(req.body)` | Validation middleware |

## Dangerous Patterns

```yaml
patterns:
  # Mass Assignment
  - '\$request->all\s*\(\)'
  - 'Model::create\s*\(\s*\$request'
  - '\*\*request\.(data|json)'
  - 'create\s*\(\s*req\.body\s*\)'

  # BOLA - Missing ownership check
  - 'find\s*\(\s*\$id\s*\)'
  - 'findOrFail\s*\(\s*\$'
  - 'get_object_or_404\s*\('

  # Rate Limiting Missing
  - 'Route::.*->middleware\s*\([^)]*(?!throttle)'

  # Excessive Data Exposure
  - 'return\s+\$\w+->toArray\s*\(\)'
  - '->get\s*\(\)\s*$'
  - 'SELECT\s+\*\s+FROM'
```

## Output

Base: `{metadata: {scan_id, scanned_at, agent}, vulnerabilities: [{id, type, vulnerability_class, cwe_id, severity, file, line, code, description, remediation}], summary: {total, critical, high, medium, low}}`
Extra: prefix=API, types=mass-assignment|bola|rate-limiting|excessive-data-exposure

## Severity Criteria

| Severity | Criteria |
|----------|----------|
| critical | BOLA on sensitive resources (admin, payment) |
| high | Mass Assignment, Excessive Data Exposure |
| medium | Rate Limiting missing on auth endpoints |
| low | Rate Limiting missing on public endpoints |

## CWE/OWASP Mapping

| Reference | ID |
|-----------|-----|
| CWE | CWE-915: Mass Assignment |
| CWE | CWE-639: IDOR/BOLA |
| OWASP API Top 10 | API1:2023 BOLA |
| OWASP API Top 10 | API3:2023 Broken Object Property Level Authorization |

## Workflow

Glob(controllers,routes,models) → Grep(patterns) → Read(context) → score → JSON
