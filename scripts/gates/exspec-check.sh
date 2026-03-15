#!/bin/bash
# exspec-check.sh - Optional exspec gate after RED phase
#
# Purpose:
#   REDフェーズで作成したテストコードの品質をexspec（テスト静的解析）で検証する。
#   assertion-free等の重大問題（BLOCK severity）を早期検出する。
#   exspec未インストール時・非対応言語時はスキップ（optional統合）。
#
# Usage: exspec-check.sh <test_path> <lang>
# Exit 0 = PASS or SKIP
# Exit 1 = BLOCK detected or usage error

set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: exspec-check.sh <test_path> <lang>"
  echo "  Supported languages: python, typescript, php, rust"
  exit 1
fi

TEST_PATH="$1"
EXSPEC_LANG="$2"

# 1. Check exspec installation
if ! command -v exspec >/dev/null 2>&1; then
  echo "SKIP: exspec not installed. Install with: pip install exspec"
  exit 0
fi

# 2. Check supported language
case "$EXSPEC_LANG" in
  python|typescript|php|rust)
    ;;
  *)
    echo "SKIP: Language '$EXSPEC_LANG' not supported by exspec. Supported: python, typescript, php, rust"
    exit 0
    ;;
esac

# 3. Run exspec (BLOCK severity only)
echo "Running exspec on $TEST_PATH (lang: $EXSPEC_LANG)..."
set +e
exspec "$TEST_PATH" --lang "$EXSPEC_LANG" --min-severity block --format terminal
rc=$?
exit $rc
