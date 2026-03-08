---
name: python-quality
description: Python品質チェック。pytest/mypy/Black実行時に使用。「Pythonの品質チェック」「静的解析」で起動。
allowed-tools: Bash, Read, Grep, Glob
---

## Tools
test: `pytest` | types: `mypy --strict` | lint: `ruff check` | format: `black` + `isort`

## Standards

| 項目 | 目標 |
|------|------|
| mypy | strict mode |
| カバレッジ | 90%+ |
| ruff/black | エラー0 |

## Reference
- [reference.md](reference.md)
