#!/bin/bash
# test-tfidf-summary-script.sh - Unit tests for scripts/tfidf-summary.sh
# TC-16: Script exists and is executable
# TC-17: Empty log.jsonl → empty array []
# TC-18: Sessions < 20 → empty array (bootstrap)
# TC-19: Normal data → valid JSON array output
# TC-20: Output has required fields (term, tf, idf, tfidf, count, sessions)
# TC-21: learn SKILL.md references tfidf-summary.sh

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$BASE_DIR/scripts/tfidf-summary.sh"
PASS=0
FAIL=0
TMPDIR_ROOT=""

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

setup_tmpdir() {
  TMPDIR_ROOT="$(mktemp -d)"
}

teardown_tmpdir() {
  [ -n "$TMPDIR_ROOT" ] && rm -rf "$TMPDIR_ROOT"
}

trap teardown_tmpdir EXIT

# Generate N sessions of test data (each session has 5 entries)
generate_test_data() {
  local file="$1"
  local num_sessions="$2"
  > "$file"
  for i in $(seq 1 "$num_sessions"); do
    local sid="session-$(printf '%03d' "$i")"
    echo "{\"timestamp\":\"2026-01-01T00:00:00Z\",\"session_id\":\"$sid\",\"tool_name\":\"Bash\",\"target\":\"git status\"}" >> "$file"
    echo "{\"timestamp\":\"2026-01-01T00:01:00Z\",\"session_id\":\"$sid\",\"tool_name\":\"Edit\",\"target\":\"/path/to/file.php\"}" >> "$file"
    echo "{\"timestamp\":\"2026-01-01T00:02:00Z\",\"session_id\":\"$sid\",\"tool_name\":\"Read\",\"target\":\"/path/to/file.ts\"}" >> "$file"
    echo "{\"timestamp\":\"2026-01-01T00:03:00Z\",\"session_id\":\"$sid\",\"tool_name\":\"Bash\",\"target\":\"python test.py\"}" >> "$file"
    echo "{\"timestamp\":\"2026-01-01T00:04:00Z\",\"session_id\":\"$sid\",\"tool_name\":\"Grep\",\"target\":\"/path/to/file.php\"}" >> "$file"
  done
}

echo "=== TF-IDF Summary Script Tests ==="

# TC-16: Script exists and is executable
echo ""
echo "TC-16: Script exists and is executable"
if [ -x "$SCRIPT" ]; then
  pass "Script exists and is executable"
else
  fail "Script does NOT exist or is not executable at $SCRIPT"
fi

# TC-17: Empty log.jsonl → empty array []
echo ""
echo "TC-17: Empty log.jsonl → empty array []"
setup_tmpdir
EMPTY_LOG="$TMPDIR_ROOT/empty.jsonl"
touch "$EMPTY_LOG"
OUTPUT="$(bash "$SCRIPT" "$EMPTY_LOG" 2>/dev/null)" || true
if [ "$OUTPUT" = "[]" ]; then
  pass "Empty log.jsonl outputs []"
else
  fail "Empty log.jsonl did NOT output []; got: $OUTPUT"
fi
teardown_tmpdir

# TC-18: Sessions < 20 → empty array (bootstrap)
echo ""
echo "TC-18: Sessions < 20 → empty array (bootstrap)"
setup_tmpdir
SMALL_LOG="$TMPDIR_ROOT/small.jsonl"
generate_test_data "$SMALL_LOG" 10
OUTPUT="$(bash "$SCRIPT" "$SMALL_LOG" 2>/dev/null)" || true
if [ "$OUTPUT" = "[]" ]; then
  pass "Sessions < 20 outputs []"
else
  fail "Sessions < 20 did NOT output []; got: $OUTPUT"
fi
teardown_tmpdir

# TC-19: Normal data → valid JSON array output
echo ""
echo "TC-19: Normal data → valid JSON array output"
setup_tmpdir
NORMAL_LOG="$TMPDIR_ROOT/normal.jsonl"
generate_test_data "$NORMAL_LOG" 25
OUTPUT="$(bash "$SCRIPT" "$NORMAL_LOG" 2>/dev/null)" || true
if echo "$OUTPUT" | jq -e 'type == "array"' > /dev/null 2>&1; then
  pass "Normal data outputs valid JSON array"
else
  fail "Normal data did NOT output valid JSON array; got: $OUTPUT"
fi
teardown_tmpdir

# TC-20: Output has required fields (term, tf, idf, tfidf, count, sessions)
echo ""
echo "TC-20: Output has required fields"
setup_tmpdir
FIELDS_LOG="$TMPDIR_ROOT/fields.jsonl"
generate_test_data "$FIELDS_LOG" 25
OUTPUT="$(bash "$SCRIPT" "$FIELDS_LOG" 2>/dev/null)" || true
REQUIRED_FIELDS=("term" "tf" "idf" "tfidf" "count" "sessions")
MISSING=""
for field in "${REQUIRED_FIELDS[@]}"; do
  if ! echo "$OUTPUT" | jq -e ".[0] | has(\"$field\")" > /dev/null 2>&1; then
    MISSING="$MISSING $field"
  fi
done
if [ -z "$MISSING" ]; then
  pass "Output has all required fields"
else
  fail "Output missing fields:$MISSING"
fi
teardown_tmpdir

# TC-21: learn SKILL.md references tfidf-summary.sh
echo ""
echo "TC-21: learn SKILL.md references tfidf-summary.sh"
if grep -q 'tfidf-summary\.sh' "$BASE_DIR/skills/learn/SKILL.md"; then
  pass "learn SKILL.md references tfidf-summary.sh"
else
  fail "learn SKILL.md does NOT reference tfidf-summary.sh"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS"
echo "FAIL: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi

exit 0
