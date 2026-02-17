#!/bin/bash
# test-security-audit-reference.sh - security-audit reference.md validation
# TC-REF-01 ~ TC-REF-17

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

REFERENCE_FILE="$BASE_DIR/skills/security-audit/reference.md"

echo "=== Security-Audit Reference.md Tests ==="
echo ""

# TC-REF-01: reference.md が Overview セクションを含む
echo "TC-REF-01: Overview section exists"
if [ -f "$REFERENCE_FILE" ] && grep -q "^## Overview" "$REFERENCE_FILE"; then
  pass "TC-REF-01: Overview section found"
else
  fail "TC-REF-01: Overview section not found"
fi

# TC-REF-02: reference.md が Workflow Details セクションを含む
echo ""
echo "TC-REF-02: Workflow Details section exists"
if [ -f "$REFERENCE_FILE" ] && grep -q "^## Workflow Details" "$REFERENCE_FILE"; then
  pass "TC-REF-02: Workflow Details section found"
else
  fail "TC-REF-02: Workflow Details section not found"
fi

# TC-REF-03: reference.md が Options セクションを含む
echo ""
echo "TC-REF-03: Options section exists"
if [ -f "$REFERENCE_FILE" ] && grep -q "^## Options" "$REFERENCE_FILE"; then
  pass "TC-REF-03: Options section found"
else
  fail "TC-REF-03: Options section not found"
fi

# TC-REF-04: reference.md が Output Examples セクションを含む
echo ""
echo "TC-REF-04: Output Examples section exists"
if [ -f "$REFERENCE_FILE" ] && grep -q "^## Output Examples" "$REFERENCE_FILE"; then
  pass "TC-REF-04: Output Examples section found"
else
  fail "TC-REF-04: Output Examples section not found"
fi

# TC-REF-05: reference.md が Error Handling セクションを含む
echo ""
echo "TC-REF-05: Error Handling section exists"
if [ -f "$REFERENCE_FILE" ] && grep -q "^## Error Handling" "$REFERENCE_FILE"; then
  pass "TC-REF-05: Error Handling section found"
else
  fail "TC-REF-05: Error Handling section not found"
fi

# TC-REF-06: reference.md が Limitations セクションを含む
echo ""
echo "TC-REF-06: Limitations section exists"
if [ -f "$REFERENCE_FILE" ] && grep -q "^## Limitations" "$REFERENCE_FILE"; then
  pass "TC-REF-06: Limitations section found"
else
  fail "TC-REF-06: Limitations section not found"
fi

# TC-REF-07: reference.md が References セクションを含む
echo ""
echo "TC-REF-07: References section exists"
if [ -f "$REFERENCE_FILE" ] && grep -q "^## References" "$REFERENCE_FILE"; then
  pass "TC-REF-07: References section found"
else
  fail "TC-REF-07: References section not found"
fi

# TC-REF-08: Options セクションに --full-scan の説明がある
echo ""
echo "TC-REF-08: --full-scan option documented"
if [ -f "$REFERENCE_FILE" ] && grep -q -- "--full-scan" "$REFERENCE_FILE"; then
  pass "TC-REF-08: --full-scan option found"
else
  fail "TC-REF-08: --full-scan option not found"
fi

# TC-REF-09: Options セクションに --auto-e2e の説明がある
echo ""
echo "TC-REF-09: --auto-e2e option documented"
if [ -f "$REFERENCE_FILE" ] && grep -q -- "--auto-e2e" "$REFERENCE_FILE"; then
  pass "TC-REF-09: --auto-e2e option found"
else
  fail "TC-REF-09: --auto-e2e option not found"
fi

# TC-REF-10: Options セクションに --dynamic の説明がある
echo ""
echo "TC-REF-10: --dynamic option documented"
if [ -f "$REFERENCE_FILE" ] && grep -q -- "--dynamic" "$REFERENCE_FILE"; then
  pass "TC-REF-10: --dynamic option found"
else
  fail "TC-REF-10: --dynamic option not found"
fi

# TC-REF-11: Options セクションに --target の説明がある
echo ""
echo "TC-REF-11: --target option documented"
if [ -f "$REFERENCE_FILE" ] && grep -q -- "--target" "$REFERENCE_FILE"; then
  pass "TC-REF-11: --target option found"
else
  fail "TC-REF-11: --target option not found"
fi

# TC-REF-12: Workflow Details が Task() 委譲フローを記述している
echo ""
echo "TC-REF-12: Task() delegation flow documented"
if [ -f "$REFERENCE_FILE" ] && grep -q "Task()" "$REFERENCE_FILE"; then
  pass "TC-REF-12: Task() delegation flow found"
else
  fail "TC-REF-12: Task() delegation flow not found"
fi

# TC-REF-13: Error Handling が security-scan 失敗時を記述している
echo ""
echo "TC-REF-13: security-scan error handling documented"
if [ -f "$REFERENCE_FILE" ] && grep -q "security-scan" "$REFERENCE_FILE" && grep -q -i "error\|fail" "$REFERENCE_FILE"; then
  pass "TC-REF-13: security-scan error handling found"
else
  fail "TC-REF-13: security-scan error handling not found"
fi

# TC-REF-14: Error Handling が attack-report 失敗時を記述している
echo ""
echo "TC-REF-14: attack-report error handling documented"
if [ -f "$REFERENCE_FILE" ] && grep -q "attack-report" "$REFERENCE_FILE" && grep -q -i "error\|fail" "$REFERENCE_FILE"; then
  pass "TC-REF-14: attack-report error handling found"
else
  fail "TC-REF-14: attack-report error handling not found"
fi

# TC-REF-15: Error Handling が generate-e2e 失敗時を記述している
echo ""
echo "TC-REF-15: generate-e2e error handling documented"
if [ -f "$REFERENCE_FILE" ] && grep -q "generate-e2e" "$REFERENCE_FILE" && grep -q -i "error\|fail" "$REFERENCE_FILE"; then
  pass "TC-REF-15: generate-e2e error handling found"
else
  fail "TC-REF-15: generate-e2e error handling not found"
fi

# TC-REF-16: Output Examples が完了メッセージ例を含む
echo ""
echo "TC-REF-16: Output Examples with completion message"
if [ -f "$REFERENCE_FILE" ] && grep -A 10 "^## Output Examples" "$REFERENCE_FILE" | grep -q -i "complete\|success\|finish"; then
  pass "TC-REF-16: Completion message example found"
else
  fail "TC-REF-16: Completion message example not found"
fi

# TC-REF-17: References が security-scan, attack-report, generate-e2e を参照している
echo ""
echo "TC-REF-17: References include required skills"
if [ -f "$REFERENCE_FILE" ] && grep -A 10 "^## References" "$REFERENCE_FILE" | grep -q "security-scan" && \
   grep -A 10 "^## References" "$REFERENCE_FILE" | grep -q "attack-report" && \
   grep -A 10 "^## References" "$REFERENCE_FILE" | grep -q "generate-e2e"; then
  pass "TC-REF-17: All required skill references found"
else
  fail "TC-REF-17: Not all required skill references found"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
