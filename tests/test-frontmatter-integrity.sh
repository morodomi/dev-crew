#!/bin/bash
# test-frontmatter-integrity.sh - Cycle doc frontmatter value integrity checks
# TC-I1 ~ TC-I11: fixture-based validation of frontmatter field values + body contamination

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VALIDATOR="$BASE_DIR/scripts/validate-cycle-frontmatter.sh"
TMPDIR_FIX="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_FIX"' EXIT

PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

# Helper: create fixture cycle doc
# Usage: make_fixture <filename> <frontmatter_body> [extra_body]
make_fixture() {
  local file="$TMPDIR_FIX/$1"
  local fm="$2"
  local body="${3:-}"
  {
    echo "---"
    echo "$fm"
    echo "---"
    if [ -n "$body" ]; then
      echo ""
      echo "$body"
    fi
  } > "$file"
  echo "$file"
}

echo "=== Frontmatter Integrity Tests ==="

# --- Prerequisite check ---
echo ""
echo "Prerequisite: validate-cycle-frontmatter.sh exists"
if [ ! -f "$VALIDATOR" ]; then
  fail "Prerequisite: scripts/validate-cycle-frontmatter.sh not found"
  echo ""
  echo "=== Summary ==="
  echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
  exit 1
fi

# --- Normal cases ---

# TC-I1: All fields with correct values -> PASS
echo ""
echo "TC-I1: All fields with correct values -> PASS"
FIXTURE=$(make_fixture "i1.md" "$(cat <<'FM'
feature: test-feature
cycle: test-cycle
phase: RED
complexity: standard
test_count: 5
risk_level: medium
created: 2026-03-09 10:00
updated: 2026-03-09 10:00
FM
)")
if bash "$VALIDATOR" "$FIXTURE" >/dev/null 2>&1; then
  pass "TC-I1: valid frontmatter accepted"
else
  fail "TC-I1: valid frontmatter rejected"
fi

# TC-I2: phase=DONE (terminal value) -> PASS
echo ""
echo "TC-I2: phase=DONE (terminal value) -> PASS"
FIXTURE=$(make_fixture "i2.md" "$(cat <<'FM'
feature: test-feature
cycle: test-cycle
phase: DONE
complexity: complex
test_count: 3
risk_level: high
created: 2026-03-09 10:00
updated: 2026-03-09 10:00
FM
)")
if bash "$VALIDATOR" "$FIXTURE" >/dev/null 2>&1; then
  pass "TC-I2: phase=DONE accepted"
else
  fail "TC-I2: phase=DONE rejected"
fi

# --- Abnormal cases ---

# TC-I3: phase=INVALID -> FAIL
echo ""
echo "TC-I3: phase=INVALID -> FAIL"
FIXTURE=$(make_fixture "i3.md" "$(cat <<'FM'
feature: test-feature
cycle: test-cycle
phase: INVALID
complexity: standard
test_count: 5
risk_level: medium
created: 2026-03-09 10:00
updated: 2026-03-09 10:00
FM
)")
if bash "$VALIDATOR" "$FIXTURE" >/dev/null 2>&1; then
  fail "TC-I3: invalid phase accepted"
else
  pass "TC-I3: invalid phase rejected"
fi

# TC-I4: complexity=medium (not a valid value) -> FAIL
echo ""
echo "TC-I4: complexity=medium -> FAIL"
FIXTURE=$(make_fixture "i4.md" "$(cat <<'FM'
feature: test-feature
cycle: test-cycle
phase: GREEN
complexity: medium
test_count: 5
risk_level: low
created: 2026-03-09 10:00
updated: 2026-03-09 10:00
FM
)")
if bash "$VALIDATOR" "$FIXTURE" >/dev/null 2>&1; then
  fail "TC-I4: invalid complexity accepted"
else
  pass "TC-I4: invalid complexity rejected"
fi

# TC-I5: test_count=0 -> FAIL
echo ""
echo "TC-I5: test_count=0 -> FAIL"
FIXTURE=$(make_fixture "i5.md" "$(cat <<'FM'
feature: test-feature
cycle: test-cycle
phase: RED
complexity: trivial
test_count: 0
risk_level: low
created: 2026-03-09 10:00
updated: 2026-03-09 10:00
FM
)")
if bash "$VALIDATOR" "$FIXTURE" >/dev/null 2>&1; then
  fail "TC-I5: test_count=0 accepted"
else
  pass "TC-I5: test_count=0 rejected"
fi

# TC-I6: test_count=-1 -> FAIL
echo ""
echo "TC-I6: test_count=-1 -> FAIL"
FIXTURE=$(make_fixture "i6.md" "$(cat <<'FM'
feature: test-feature
cycle: test-cycle
phase: RED
complexity: trivial
test_count: -1
risk_level: low
created: 2026-03-09 10:00
updated: 2026-03-09 10:00
FM
)")
if bash "$VALIDATOR" "$FIXTURE" >/dev/null 2>&1; then
  fail "TC-I6: test_count=-1 accepted"
else
  pass "TC-I6: test_count=-1 rejected"
fi

# TC-I7: risk_level=critical (not a valid value) -> FAIL
echo ""
echo "TC-I7: risk_level=critical -> FAIL"
FIXTURE=$(make_fixture "i7.md" "$(cat <<'FM'
feature: test-feature
cycle: test-cycle
phase: RED
complexity: standard
test_count: 5
risk_level: critical
created: 2026-03-09 10:00
updated: 2026-03-09 10:00
FM
)")
if bash "$VALIDATOR" "$FIXTURE" >/dev/null 2>&1; then
  fail "TC-I7: invalid risk_level accepted"
else
  pass "TC-I7: invalid risk_level rejected"
fi

# --- Body contamination ---

# TC-I8: body contains "phase: RED" -> FAIL
echo ""
echo "TC-I8: body contains 'phase: RED' -> FAIL"
FIXTURE=$(make_fixture "i8.md" "$(cat <<'FM'
feature: test-feature
cycle: test-cycle
phase: RED
complexity: standard
test_count: 5
risk_level: medium
created: 2026-03-09 10:00
updated: 2026-03-09 10:00
FM
)" "phase: RED")
if bash "$VALIDATOR" "$FIXTURE" >/dev/null 2>&1; then
  fail "TC-I8: body contamination (phase:) accepted"
else
  pass "TC-I8: body contamination (phase:) rejected"
fi

# TC-I9: body contains "complexity: trivial" -> FAIL
echo ""
echo "TC-I9: body contains 'complexity: trivial' -> FAIL"
FIXTURE=$(make_fixture "i9.md" "$(cat <<'FM'
feature: test-feature
cycle: test-cycle
phase: GREEN
complexity: standard
test_count: 5
risk_level: medium
created: 2026-03-09 10:00
updated: 2026-03-09 10:00
FM
)" "complexity: trivial")
if bash "$VALIDATOR" "$FIXTURE" >/dev/null 2>&1; then
  fail "TC-I9: body contamination (complexity:) accepted"
else
  pass "TC-I9: body contamination (complexity:) rejected"
fi

# --- Boundary values ---

# TC-I10: test_count=1 (minimum positive integer) -> PASS
echo ""
echo "TC-I10: test_count=1 (minimum positive) -> PASS"
FIXTURE=$(make_fixture "i10.md" "$(cat <<'FM'
feature: test-feature
cycle: test-cycle
phase: INIT
complexity: trivial
test_count: 1
risk_level: low
created: 2026-03-09 10:00
updated: 2026-03-09 10:00
FM
)")
if bash "$VALIDATOR" "$FIXTURE" >/dev/null 2>&1; then
  pass "TC-I10: test_count=1 accepted"
else
  fail "TC-I10: test_count=1 rejected"
fi

# --- Structural errors ---

# TC-I11: Missing closing --- (frontmatter not closed) -> FAIL
echo ""
echo "TC-I11: Missing closing --- -> FAIL"
FIXTURE="$TMPDIR_FIX/i11.md"
{
  echo "---"
  echo "feature: test-feature"
  echo "phase: RED"
  echo "complexity: standard"
  echo "test_count: 5"
  echo "risk_level: medium"
  echo ""
  echo "phase: RED"
} > "$FIXTURE"
if bash "$VALIDATOR" "$FIXTURE" >/dev/null 2>&1; then
  fail "TC-I11: unclosed frontmatter accepted"
else
  pass "TC-I11: unclosed frontmatter rejected"
fi

# --- Required field presence (Phase 30: directory structure strictification) ---

# TC-I12: Missing feature field -> FAIL
echo ""
echo "TC-I12: Missing feature field -> FAIL"
FIXTURE=$(make_fixture "i12.md" "$(cat <<'FM'
cycle: test-cycle
phase: RED
complexity: standard
test_count: 5
risk_level: medium
created: 2026-03-09 10:00
updated: 2026-03-09 10:00
FM
)")
if bash "$VALIDATOR" "$FIXTURE" >/dev/null 2>&1; then
  fail "TC-I12: missing feature field accepted"
else
  pass "TC-I12: missing feature field rejected"
fi

# TC-I13: Missing cycle field -> FAIL
echo ""
echo "TC-I13: Missing cycle field -> FAIL"
FIXTURE=$(make_fixture "i13.md" "$(cat <<'FM'
feature: test-feature
phase: GREEN
complexity: standard
test_count: 3
risk_level: low
created: 2026-03-09 10:00
updated: 2026-03-09 10:00
FM
)")
if bash "$VALIDATOR" "$FIXTURE" >/dev/null 2>&1; then
  fail "TC-I13: missing cycle field accepted"
else
  pass "TC-I13: missing cycle field rejected"
fi

# TC-I14: Missing created field -> FAIL
echo ""
echo "TC-I14: Missing created field -> FAIL"
FIXTURE=$(make_fixture "i14.md" "$(cat <<'FM'
feature: test-feature
cycle: test-cycle
phase: RED
complexity: trivial
test_count: 2
risk_level: low
updated: 2026-03-09 10:00
FM
)")
if bash "$VALIDATOR" "$FIXTURE" >/dev/null 2>&1; then
  fail "TC-I14: missing created field accepted"
else
  pass "TC-I14: missing created field rejected"
fi

# TC-I15: Missing updated field -> FAIL
echo ""
echo "TC-I15: Missing updated field -> FAIL"
FIXTURE=$(make_fixture "i15.md" "$(cat <<'FM'
feature: test-feature
cycle: test-cycle
phase: RED
complexity: standard
test_count: 5
risk_level: medium
created: 2026-03-09 10:00
FM
)")
if bash "$VALIDATOR" "$FIXTURE" >/dev/null 2>&1; then
  fail "TC-I15: missing updated field accepted"
else
  pass "TC-I15: missing updated field rejected"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
