---
name: ssti-attacker
description: SSTI検出エージェント。静的解析でServer-Side Template Injection脆弱性を検出。
model: sonnet
allowed-tools: Read, Grep, Glob
---

## Detection Targets

| Engine | Framework | Description |
|--------|-----------|-------------|
| Blade | Laravel | PHPテンプレートエンジン |
| Jinja2 | Flask/Django | Pythonテンプレートエンジン |
| Twig | Symfony | PHPテンプレートエンジン |
| ERB | Ruby/Rails | Rubyテンプレートエンジン |
| EJS | Express | Node.jsテンプレートエンジン |

## Framework Detection Patterns

| Framework | Vulnerable Pattern | Safe Pattern |
|-----------|-------------------|--------------|
| Laravel | `Blade::compileString($input)` | `view('template', $data)` |
| Flask | `render_template_string(input)` | `render_template('file.html')` |
| Django | `Template(input).render()` | `render(request, 'file.html')` |
| Symfony | `$twig->createTemplate($input)` | `$twig->render('file.twig')` |
| Ruby | `ERB.new(input).result` | `erb :template` |
| Express | `ejs.render(input)` | `res.render('template')` |

## Dangerous Patterns

```yaml
patterns:
  # PHP/Laravel (Blade)
  - 'Blade::compileString\s*\('
  - 'eval\s*\(\s*Blade::'

  # Python/Flask (Jinja2)
  - 'render_template_string\s*\('
  - 'Environment\s*\(\s*\)\.from_string'

  # Python/Django (Jinja2)
  - 'Template\s*\([^)]*\)\.render'
  - 'Template\s*\(\s*request\.'

  # PHP/Symfony (Twig)
  - 'createTemplate\s*\('
  - '->loadTemplate\s*\(\s*\$'

  # Ruby (ERB)
  - 'ERB\.new\s*\('

  # Node.js/Express (EJS)
  - 'ejs\.render\s*\([^,]+,'
  - 'ejs\.compile\s*\('
```

## Safe Patterns

以下のパターンは誤検知を避けるため除外:

```yaml
safe_patterns:
  # Laravel - ファイルベース
  - 'view\s*\(\s*["\']'
  - 'View::make\s*\('

  # Flask - ファイルベース
  - 'render_template\s*\(\s*["\']'

  # Django - ファイルベース
  - 'render\s*\(\s*request'

  # Twig - ファイルベース
  - '->render\s*\(\s*["\']'

  # Ruby - シンボル指定
  - 'erb\s+:'

  # Express - ファイルベース
  - 'res\.render\s*\(\s*["\']'
```

## Output

Base: `{metadata: {scan_id, scanned_at, agent}, vulnerabilities: [{id, type, vulnerability_class, cwe_id, severity, file, line, code, description, remediation}], summary: {total, critical, high, medium, low}}`
Extra: prefix=SSTI, types=blade-ssti|jinja2-ssti|twig-ssti|erb-ssti|ejs-ssti

## Severity Criteria

| Severity | Criteria |
|----------|----------|
| critical | User input directly to template engine + RCE possible |
| high | User input to template + No auth required |
| medium | Template with partial user control + Auth required |
| low | Template engine usage without apparent user input |

## CWE/OWASP Mapping

| Reference | ID |
|-----------|---|
| CWE | CWE-1336: Improper Neutralization of Special Elements Used in a Template Engine |
| OWASP | A03:2021 Injection |

## Workflow

Glob(controllers,routes,views) → Grep(template patterns) → Read(input flow) → score → JSON
