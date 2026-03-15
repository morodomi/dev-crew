#!/bin/bash
# test-risk-classifier.sh - risk-classifier.sh fallback behavior tests
# T-01: No-args invocation outputs risk level (not usage error)
# T-02: Args invocation still works (backward compat)
# T-03: Trap cleanup registered for auto-generated temp files
# T-04: steps-subagent.md uses single command invocation

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$BASE_DIR/skills/review/risk-classifier.sh"
STEPS="$BASE_DIR/skills/review/steps-subagent.md"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== Risk Classifier Tests ==="

# T-01: No-args invocation outputs risk level (not usage error)
echo ""
echo "T-01: No-args invocation outputs risk level"

output=$(bash "$SCRIPT" 2>&1) || true
if echo "$output" | grep -qE '^(LOW|MEDIUM|HIGH) score:[0-9]+$'; then
  pass "No-args outputs risk level"
else
  fail "No-args did not output risk level, got: $output"
fi

# T-02: Args invocation still works (backward compat)
echo ""
echo "T-02: Args invocation with files works"

TMPFILES=$(mktemp)
TMPDIFF=$(mktemp)
trap 'rm -f "$TMPFILES" "$TMPDIFF"' EXIT

echo "src/auth/login.php" > "$TMPFILES"
echo "+password = hash(input)" > "$TMPDIFF"

output=$(bash "$SCRIPT" "$TMPFILES" "$TMPDIFF" 2>&1)
if echo "$output" | grep -qE '^(LOW|MEDIUM|HIGH) score:[0-9]+$'; then
  pass "Args invocation outputs risk level"
else
  fail "Args invocation failed, got: $output"
fi

# T-03: Script has trap EXIT for cleanup
echo ""
echo "T-03: Trap cleanup registered for auto-generated temp files"

if grep -q "trap.*EXIT" "$SCRIPT"; then
  pass "trap EXIT found in risk-classifier.sh"
else
  fail "trap EXIT NOT found in risk-classifier.sh"
fi

# T-04: steps-subagent.md uses single command invocation
echo ""
echo "T-04: steps-subagent.md uses single command (no /tmp/review-files.txt)"

if grep -q '/tmp/review-files.txt' "$STEPS"; then
  fail "steps-subagent.md still references /tmp/review-files.txt"
else
  pass "steps-subagent.md does not reference /tmp/review-files.txt"
fi

# T-05: Fixture-only changes don't inflate file count
echo ""
echo "T-05: Fixture-only files excluded from file count"

TMPFILES5=$(mktemp)
TMPDIFF5=$(mktemp)

# 6 fixture files + 1 real file = should count as 1 real file (not > 5)
cat > "$TMPFILES5" <<'FILES'
tests/fixtures/data1.fixture
tests/fixtures/data2.fixture
tests/__snapshots__/snap1.snap
tests/__snapshots__/snap2.snap
src/queries/test.scm
src/mocks/mock1.mock
src/app.ts
FILES
echo "+ some change" > "$TMPDIFF5"

output=$(bash "$SCRIPT" "$TMPFILES5" "$TMPDIFF5" 2>&1)
score5=$(echo "$output" | grep -oE 'score:[0-9]+' | grep -oE '[0-9]+')
# 7 files total but only 1 non-fixture, so file_count bonus (+15) should NOT apply
if [ "$score5" -lt 15 ]; then
  pass "Fixture-only files excluded from count (score: $score5)"
else
  fail "Fixture files not excluded: expected score<15, got score:$score5"
fi
rm -f "$TMPFILES5" "$TMPDIFF5"

# T-06: New-file-only changes skip file count bonus
echo ""
echo "T-06: New-file-only changes skip file count bonus"

TMPFILES6=$(mktemp)
TMPDIFF6=$(mktemp)

# 6 real files, all new (only --- /dev/null, no --- a/)
cat > "$TMPFILES6" <<'FILES'
src/new1.ts
src/new2.ts
src/new3.ts
src/new4.ts
src/new5.ts
src/new6.ts
FILES

cat > "$TMPDIFF6" <<'DIFF'
--- /dev/null
+++ b/src/new1.ts
+export const a = 1;
--- /dev/null
+++ b/src/new2.ts
+export const b = 2;
DIFF

output=$(bash "$SCRIPT" "$TMPFILES6" "$TMPDIFF6" 2>&1)
score6=$(echo "$output" | grep -oE 'score:[0-9]+' | grep -oE '[0-9]+')
# 6 files but all new → file_count bonus should be skipped
if [ "$score6" -eq 0 ]; then
  pass "New-file-only changes: file count bonus skipped"
else
  fail "New-file-only changes: expected score:0, got score:$score6"
fi
rm -f "$TMPFILES6" "$TMPDIFF6"

# T-07: Mixed changes (new + modified) keep file count bonus
echo ""
echo "T-07: Mixed changes keep file count bonus"

TMPFILES7=$(mktemp)
TMPDIFF7=$(mktemp)

cat > "$TMPFILES7" <<'FILES'
src/new1.ts
src/new2.ts
src/new3.ts
src/new4.ts
src/new5.ts
src/existing.ts
FILES

cat > "$TMPDIFF7" <<'DIFF'
--- /dev/null
+++ b/src/new1.ts
+export const a = 1;
--- a/src/existing.ts
+++ b/src/existing.ts
+modified line
DIFF

output=$(bash "$SCRIPT" "$TMPFILES7" "$TMPDIFF7" 2>&1)
score7=$(echo "$output" | grep -oE 'score:[0-9]+' | grep -oE '[0-9]+')
# Has modified file → file count bonus should apply (+15)
if [ "$score7" -ge 15 ]; then
  pass "Mixed changes: file count bonus applied (score: $score7)"
else
  fail "Mixed changes: expected score >= 15, got score:$score7"
fi
rm -f "$TMPFILES7" "$TMPDIFF7"

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS"
echo "FAIL: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi

exit 0
