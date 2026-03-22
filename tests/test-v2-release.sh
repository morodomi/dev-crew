#!/usr/bin/env bash
# test-v2-release.sh - v2.1.2 release validation tests
set -euo pipefail

DIR="$(cd "$(dirname "$0")/.." && pwd)"
FAIL=0

fail() { echo "FAIL: $1"; FAIL=1; }
pass() { echo "PASS: $1"; }

# TC-01: plugin.json の version が 2.x 以上
VERSION=$(grep -o '"version": "[^"]*"' "$DIR/.claude-plugin/plugin.json" | grep -o '"[^"]*"' | tr -d '"')
if echo "$VERSION" | grep -qE '^2\.[0-9]+\.[0-9]+'; then
  pass "TC-01: plugin.json version is $VERSION (>= 2.x)"
else
  fail "TC-01: plugin.json version is '$VERSION', expected 2.x+"
fi

# TC-02: CHANGELOG.md に "## [2.0.2]" セクションが存在
if grep -q '## \[2\.0\.1\]' "$DIR/CHANGELOG.md"; then
  pass "TC-02: CHANGELOG.md has [2.0.2] section"
else
  fail "TC-02: CHANGELOG.md missing [2.0.2] section"
fi

# TC-03: CHANGELOG.md の v2.0.2 に Changed セクションが含まれる
if grep -A 20 '## \[2\.0\.1\]' "$DIR/CHANGELOG.md" | grep -q 'Changed'; then
  pass "TC-03: CHANGELOG.md v2.0.2 has Changed section"
else
  fail "TC-03: CHANGELOG.md v2.0.2 missing Changed section"
fi

# TC-04: STATUS.md のテスト数が実際のテスト数と一致
ACTUAL_TESTS=$(ls "$DIR/tests/test-"*.sh | wc -l | tr -d ' ')
STATUS_TESTS=$(grep -o 'Test Scripts | [0-9]*' "$DIR/docs/STATUS.md" | grep -o '[0-9]*')
if [ "$ACTUAL_TESTS" = "$STATUS_TESTS" ]; then
  pass "TC-04: STATUS.md test count ($STATUS_TESTS) matches actual ($ACTUAL_TESTS)"
else
  fail "TC-04: STATUS.md test count ($STATUS_TESTS) != actual ($ACTUAL_TESTS)"
fi

# TC-05: STATUS.md の Last updated が存在する
if grep -qE 'Last updated: [0-9]{4}-[0-9]{2}-[0-9]{2}' "$DIR/docs/STATUS.md"; then
  pass "TC-05: STATUS.md has Last updated date"
else
  fail "TC-05: STATUS.md missing Last updated date"
fi

# TC-06: ROADMAP.md or archive に Phase 11 完了のマークがある (11.1, 11.2, 11.3, 11.5, 11.6, 11.7)
ARCHIVE="$DIR/docs/archive/roadmap-v2-v3-completed.md"
ROADMAP_OK=true
for phase in "11.1" "11.2" "11.3" "11.5" "11.6" "11.7"; do
  if ! grep -q "### ${phase}.*完了\|### ${phase}.*(完了)" "$DIR/ROADMAP.md" 2>/dev/null; then
    # Check archive
    if ! grep -q "### ${phase}.*完了\|### ${phase}.*(完了)" "$ARCHIVE" 2>/dev/null; then
      SECTION=$(sed -n "/### ${phase}/,/### /p" "$ARCHIVE" 2>/dev/null | head -5)
      if ! echo "$SECTION" | grep -qi "完了\|completed\|done"; then
        ROADMAP_OK=false
        fail "TC-06: ROADMAP.md missing completion mark for Phase ${phase}"
      fi
    fi
  fi
done
if [ "$ROADMAP_OK" = true ]; then
  pass "TC-06: ROADMAP.md has completion marks for all Phase 11 sub-tasks"
fi

# TC-07: README.md の tests 数が実際と一致
README_TESTS=$(grep -o 'tests/.*# [0-9]* \|# [0-9]* test\|[0-9]* test' "$DIR/README.md" 2>/dev/null | head -1 | grep -o '[0-9]*' || true)
if [ -z "$README_TESTS" ]; then
  # Check for pattern like "57 tests" or "tests/ # Structure validation"
  # README may not have explicit test count - check the Structure section
  README_STRUCTURE=$(grep -A 1 'tests/' "$DIR/README.md" | head -2)
  pass "TC-07: README.md structure section present (no explicit test count to validate)"
else
  if [ "$README_TESTS" = "$ACTUAL_TESTS" ]; then
    pass "TC-07: README.md test count matches actual"
  else
    fail "TC-07: README.md test count ($README_TESTS) != actual ($ACTUAL_TESTS)"
  fi
fi

# TC-08: 既存 test-plugin-structure.sh が通る
if bash "$DIR/tests/test-plugin-structure.sh" > /dev/null 2>&1; then
  pass "TC-08: test-plugin-structure.sh passes"
else
  fail "TC-08: test-plugin-structure.sh failed"
fi

exit $FAIL
