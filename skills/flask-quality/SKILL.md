---
name: flask-quality
description: Flask品質チェック。pytest-flask/mypy/Black実行時に使用。「Flaskの品質チェック」「Flask テスト」で起動。
allowed-tools: Bash, Read, Grep, Glob
---

# Flask Quality Check

Flask プロジェクトの品質チェックツール。

## Commands

| ツール | コマンド | 用途 |
|--------|---------|------|
| pytest | `pytest` | テスト実行（pytest-flask） |
| mypy | `mypy --strict` | 型チェック |
| Black | `black .` | コードフォーマット |
| isort | `isort .` | import整理 |

## Flask-specific Fixtures

| Fixture | 用途 |
|---------|------|
| `client` | test_client インスタンス |
| `app` | Flask アプリケーション |
| `app_context` | アプリケーションコンテキスト |

## Usage

```bash
# テスト実行
pytest -v
pytest tests/test_routes.py
pytest --cov=src --cov-report=html

# 静的解析
mypy --strict src/
black .
isort .
```

## Quality Standards

| 項目 | 目標 |
|------|------|
| mypy | strict mode |
| カバレッジ | 90%+ |
| black/isort | エラー0 |

## Reference

- App Factory Pattern、conftest.py例: [reference.md](reference.md)
