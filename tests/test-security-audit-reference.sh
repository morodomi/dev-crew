#!/bin/bash
# test-security-audit-reference.sh - security-audit reference.md validation
# TC-REF-01 ~ TC-REF-19

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

REFERENCE_FILE="$BASE_DIR/skills/security-audit/reference.md"

# Section extraction constants
LINES_AFTER_ERROR_HANDLING=50
LINES_AFTER_SMALL_SECTIONS=10
MIN_CONTENT_REUSE_COUNT=10

echo "=== Security-Audit Reference.md Tests ==="
echo ""

# Read file once and reuse content
[ -f "$REFERENCE_FILE" ] || { echo "ERROR: $REFERENCE_FILE not found"; exit 1; }
CONTENT=$(cat "$REFERENCE_FILE")

# TC-REF-01: reference.md が Overview セクションを含む
echo "TC-REF-01: Overview section exists"
if echo "$CONTENT" | grep -q "^## Overview"; then
  pass "TC-REF-01: Overview section found"
else
  fail "TC-REF-01: Overview section not found"
fi

# TC-REF-02: reference.md が Workflow Details セクションを含む
echo ""
echo "TC-REF-02: Workflow Details section exists"
if echo "$CONTENT" | grep -q "^## Workflow Details"; then
  pass "TC-REF-02: Workflow Details section found"
else
  fail "TC-REF-02: Workflow Details section not found"
fi

# TC-REF-03: reference.md が Options セクションを含む
echo ""
echo "TC-REF-03: Options section exists"
if echo "$CONTENT" | grep -q "^## Options"; then
  pass "TC-REF-03: Options section found"
else
  fail "TC-REF-03: Options section not found"
fi

# TC-REF-04: reference.md が Output Examples セクションを含む
echo ""
echo "TC-REF-04: Output Examples section exists"
if echo "$CONTENT" | grep -q "^## Output Examples"; then
  pass "TC-REF-04: Output Examples section found"
else
  fail "TC-REF-04: Output Examples section not found"
fi

# TC-REF-05: reference.md が Error Handling セクションを含む
echo ""
echo "TC-REF-05: Error Handling section exists"
if echo "$CONTENT" | grep -q "^## Error Handling"; then
  pass "TC-REF-05: Error Handling section found"
else
  fail "TC-REF-05: Error Handling section not found"
fi

# TC-REF-06: reference.md が Limitations セクションを含む
echo ""
echo "TC-REF-06: Limitations section exists"
if echo "$CONTENT" | grep -q "^## Limitations"; then
  pass "TC-REF-06: Limitations section found"
else
  fail "TC-REF-06: Limitations section not found"
fi

# TC-REF-07: reference.md が References セクションを含む
echo ""
echo "TC-REF-07: References section exists"
if echo "$CONTENT" | grep -q "^## References"; then
  pass "TC-REF-07: References section found"
else
  fail "TC-REF-07: References section not found"
fi

# TC-REF-08: Options セクションに --full-scan の説明がある
echo ""
echo "TC-REF-08: --full-scan option documented"
if echo "$CONTENT" | grep -q -- "--full-scan"; then
  pass "TC-REF-08: --full-scan option found"
else
  fail "TC-REF-08: --full-scan option not found"
fi

# TC-REF-09: Options セクションに --auto-e2e の説明がある
echo ""
echo "TC-REF-09: --auto-e2e option documented"
if echo "$CONTENT" | grep -q -- "--auto-e2e"; then
  pass "TC-REF-09: --auto-e2e option found"
else
  fail "TC-REF-09: --auto-e2e option not found"
fi

# TC-REF-10: Options セクションに --dynamic の説明がある
echo ""
echo "TC-REF-10: --dynamic option documented"
if echo "$CONTENT" | grep -q -- "--dynamic"; then
  pass "TC-REF-10: --dynamic option found"
else
  fail "TC-REF-10: --dynamic option not found"
fi

# TC-REF-11: Options セクションに --target の説明がある
echo ""
echo "TC-REF-11: --target option documented"
if echo "$CONTENT" | grep -q -- "--target"; then
  pass "TC-REF-11: --target option found"
else
  fail "TC-REF-11: --target option not found"
fi

# TC-REF-12: Workflow Details が Task() 委譲フローを記述している
echo ""
echo "TC-REF-12: Task() delegation flow documented"
if echo "$CONTENT" | grep -q "Task()"; then
  pass "TC-REF-12: Task() delegation flow found"
else
  fail "TC-REF-12: Task() delegation flow not found"
fi

# TC-REF-13: Error Handling セクション内で security-scan 失敗時を記述している
echo ""
echo "TC-REF-13: security-scan error handling documented in Error Handling section"
if echo "$CONTENT" | grep -A "$LINES_AFTER_ERROR_HANDLING" "^## Error Handling" | grep -q "### security-scan 失敗時"; then
  pass "TC-REF-13: security-scan error handling found in Error Handling section"
else
  fail "TC-REF-13: security-scan error handling not found in Error Handling section"
fi

# TC-REF-14: Error Handling セクション内で attack-report 失敗時を記述している
echo ""
echo "TC-REF-14: attack-report error handling documented in Error Handling section"
if echo "$CONTENT" | grep -A "$LINES_AFTER_ERROR_HANDLING" "^## Error Handling" | grep -q "### attack-report 失敗時"; then
  pass "TC-REF-14: attack-report error handling found in Error Handling section"
else
  fail "TC-REF-14: attack-report error handling not found in Error Handling section"
fi

# TC-REF-15: Error Handling セクション内で generate-e2e 失敗時を記述している
echo ""
echo "TC-REF-15: generate-e2e error handling documented in Error Handling section"
if echo "$CONTENT" | grep -A "$LINES_AFTER_ERROR_HANDLING" "^## Error Handling" | grep -q "### generate-e2e 失敗時"; then
  pass "TC-REF-15: generate-e2e error handling found in Error Handling section"
else
  fail "TC-REF-15: generate-e2e error handling not found in Error Handling section"
fi

# TC-REF-16: Output Examples が完了メッセージ例を含む
echo ""
echo "TC-REF-16: Output Examples with completion message"
if echo "$CONTENT" | grep -A "$LINES_AFTER_SMALL_SECTIONS" "^## Output Examples" | grep -q -i "complete\|success\|finish"; then
  pass "TC-REF-16: Completion message example found"
else
  fail "TC-REF-16: Completion message example not found"
fi

# TC-REF-17: References が security-scan, attack-report, generate-e2e を参照している
echo ""
echo "TC-REF-17: References include required skills"
if echo "$CONTENT" | grep -A "$LINES_AFTER_SMALL_SECTIONS" "^## References" | grep -q "security-scan" && \
   echo "$CONTENT" | grep -A "$LINES_AFTER_SMALL_SECTIONS" "^## References" | grep -q "attack-report" && \
   echo "$CONTENT" | grep -A "$LINES_AFTER_SMALL_SECTIONS" "^## References" | grep -q "generate-e2e"; then
  pass "TC-REF-17: All required skill references found"
else
  fail "TC-REF-17: Not all required skill references found"
fi

# TC-REF-18: テストスクリプトが CONTENT 変数で1回読み込みを実行
echo ""
echo "TC-REF-18: Test script uses CONTENT variable for single file read"
if grep -q '^CONTENT="\?\$(cat "\$REFERENCE_FILE")\"\?' "$0"; then
  pass "TC-REF-18: CONTENT variable found for single file read"
else
  fail "TC-REF-18: CONTENT variable not found - file read optimization not implemented"
fi

# TC-REF-19: 全テストが CONTENT 変数を再利用（echo "$CONTENT" | grep）
echo ""
echo "TC-REF-19: All tests reuse CONTENT variable"
# Count number of test cases that use 'echo "$CONTENT" | grep' pattern
CONTENT_REUSE_COUNT=$(grep -c 'echo "\$CONTENT" | grep' "$0" || true)
# Expected: at least MIN_CONTENT_REUSE_COUNT tests should use this pattern
if [ "$CONTENT_REUSE_COUNT" -ge "$MIN_CONTENT_REUSE_COUNT" ]; then
  pass "TC-REF-19: Tests reuse CONTENT variable ($CONTENT_REUSE_COUNT instances)"
else
  fail "TC-REF-19: Insufficient CONTENT variable reuse ($CONTENT_REUSE_COUNT instances, expected >= $MIN_CONTENT_REUSE_COUNT)"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
