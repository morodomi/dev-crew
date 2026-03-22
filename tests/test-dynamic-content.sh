#!/bin/bash
# test-dynamic-content.sh - Phase 24 動的スキルコンテンツ注入 ADR 構造チェック
# TC-06 のみ自動テスト（TC-01〜TC-05 は手動検証）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo "PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $desc (expected=$expected, actual=$actual)"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Dynamic Content ADR Structure Checks ==="

# TC-06: ADR が docs/decisions/ に存在する
ADR_FILE="$SCRIPT_DIR/docs/decisions/adr-dynamic-skill-content.md"
if [ -f "$ADR_FILE" ]; then
  assert_eq "TC-06: ADR file exists" "true" "true"
else
  assert_eq "TC-06: ADR file exists" "true" "false"
fi

# TC-06a: ADR に Status が含まれる
if grep -q "^## Status:" "$ADR_FILE" 2>/dev/null; then
  assert_eq "TC-06a: ADR has Status section" "true" "true"
else
  assert_eq "TC-06a: ADR has Status section" "true" "false"
fi

# TC-06b: ADR に Findings セクションが含まれる
if grep -q "## Findings" "$ADR_FILE" 2>/dev/null; then
  assert_eq "TC-06b: ADR has Findings section" "true" "true"
else
  assert_eq "TC-06b: ADR has Findings section" "true" "false"
fi

# TC-06c: ADR に使用ガイドラインが含まれる
if grep -q "使用ガイドライン" "$ADR_FILE" 2>/dev/null; then
  assert_eq "TC-06c: ADR has usage guidelines" "true" "true"
else
  assert_eq "TC-06c: ADR has usage guidelines" "true" "false"
fi

# --- Summary ---
echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
