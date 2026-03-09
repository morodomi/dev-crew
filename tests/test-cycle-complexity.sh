#!/bin/bash
# test-cycle-complexity.sh - Cycle complexity distribution analysis tests
# CC1 ~ CC10: fixture-based validation of analyze-cycle-complexity.sh output

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$BASE_DIR/scripts/analyze-cycle-complexity.sh"
TMPDIR_FIX="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_FIX"' EXIT

PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

# Helper: create temp base dir with docs/cycles/ structure
make_base() {
  local base="$TMPDIR_FIX/$1"
  mkdir -p "$base/docs/cycles/archive"
  echo "$base"
}

# Helper: create fixture cycle doc
# Usage: make_cycle <base_dir> <filename> <frontmatter_body> [archive]
make_cycle() {
  local dir="$1/docs/cycles"
  [ "${4:-}" = "archive" ] && dir="$1/docs/cycles/archive"
  local file="$dir/$2"
  {
    echo "---"
    echo "$3"
    echo "---"
    echo ""
    echo "# Test cycle doc"
  } > "$file"
}

echo "=== Cycle Complexity Distribution Tests ==="

# --- Prerequisite check ---
echo ""
echo "Prerequisite: analyze-cycle-complexity.sh exists"
if [ ! -f "$SCRIPT" ]; then
  fail "Prerequisite: scripts/analyze-cycle-complexity.sh not found"
  echo ""
  echo "=== Summary ==="
  echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
  exit 1
fi

# CC1: Empty directory (all sections output, exit 0)
echo ""
echo "CC1: Empty directory -> all sections, exit 0"
CC1_BASE=$(make_base "cc1")
CC1_OUT=$(bash "$SCRIPT" "$CC1_BASE")
CC1_OK=true
echo "$CC1_OUT" | grep -q "Total cycles | 0" || CC1_OK=false
echo "$CC1_OUT" | grep -q "## Summary" || CC1_OK=false
echo "$CC1_OUT" | grep -q "## Complexity Distribution" || CC1_OK=false
echo "$CC1_OUT" | grep -q "## Recent" || CC1_OK=false
echo "$CC1_OUT" | grep -q "## Phase x Complexity" || CC1_OK=false
echo "$CC1_OUT" | grep -q "## test_count by Complexity" || CC1_OK=false
echo "$CC1_OUT" | grep -q "## Fast-Path Eligibility" || CC1_OK=false
if [ "$CC1_OK" = true ]; then pass "CC1: empty dir produces all sections"; else fail "CC1: missing sections"; fi

# CC2: Full frontmatter 1 file -> standard | 1 | 100%
echo ""
echo "CC2: Full frontmatter 1 file"
CC2_BASE=$(make_base "cc2")
make_cycle "$CC2_BASE" "20260309_1000_test.md" "$(cat <<'FM'
feature: test
cycle: 20260309_1000
phase: GREEN
complexity: standard
test_count: 5
risk_level: medium
created: 2026-03-09 10:00
updated: 2026-03-09 10:00
FM
)"
CC2_OUT=$(bash "$SCRIPT" "$CC2_BASE")
if echo "$CC2_OUT" | grep -q "standard | 1 | 100%"; then
  pass "CC2: standard 1 file 100%"
else
  fail "CC2: expected 'standard | 1 | 100%'"
fi

# CC3: No frontmatter (legacy format) -> counted as missing complexity
echo ""
echo "CC3: No frontmatter (legacy format)"
CC3_BASE=$(make_base "cc3")
echo "# Legacy doc" > "$CC3_BASE/docs/cycles/20260101_0000_legacy.md"
CC3_OUT=$(bash "$SCRIPT" "$CC3_BASE")
if echo "$CC3_OUT" | grep -q "Total cycles | 1" && echo "$CC3_OUT" | grep -q "Missing complexity | 1"; then
  pass "CC3: legacy file counted as missing"
else
  fail "CC3: legacy file not handled correctly"
fi

# CC4: Mixed (with/without complexity) -> accurate missing rate
echo ""
echo "CC4: Mixed complexity presence"
CC4_BASE=$(make_base "cc4")
make_cycle "$CC4_BASE" "20260309_1000_with.md" "$(cat <<'FM'
feature: with
cycle: 20260309_1000
phase: RED
complexity: trivial
test_count: 3
risk_level: low
created: 2026-03-09 10:00
updated: 2026-03-09 10:00
FM
)"
echo "---
feature: without
phase: RED
created: 2026-03-09 11:00
updated: 2026-03-09 11:00
---
# No complexity" > "$CC4_BASE/docs/cycles/20260309_1100_without.md"
CC4_OUT=$(bash "$SCRIPT" "$CC4_BASE")
if echo "$CC4_OUT" | grep -q "Missing complexity | 1 (50%)"; then
  pass "CC4: missing rate 50% correct"
else
  fail "CC4: missing rate incorrect"
fi

# CC5: Phase x Complexity cross tabulation
echo ""
echo "CC5: Phase x Complexity"
CC5_BASE=$(make_base "cc5")
make_cycle "$CC5_BASE" "20260309_1000_red.md" "$(cat <<'FM'
feature: f1
cycle: c1
phase: RED
complexity: standard
test_count: 3
risk_level: low
created: 2026-03-09 10:00
updated: 2026-03-09 10:00
FM
)"
make_cycle "$CC5_BASE" "20260309_1100_done.md" "$(cat <<'FM'
feature: f2
cycle: c2
phase: DONE
complexity: trivial
test_count: 2
risk_level: low
created: 2026-03-09 11:00
updated: 2026-03-09 11:00
FM
)"
CC5_OUT=$(bash "$SCRIPT" "$CC5_BASE")
CC5_OK=true
echo "$CC5_OUT" | grep -qF "| RED | 0 | 1 | 0 | 0 |" || CC5_OK=false
echo "$CC5_OUT" | grep -qF "| DONE | 1 | 0 | 0 | 0 |" || CC5_OK=false
if [ "$CC5_OK" = true ]; then pass "CC5: phase x complexity correct"; else fail "CC5: cross tabulation incorrect"; fi

# CC6: test_count statistics (avg/min/max)
echo ""
echo "CC6: test_count statistics"
CC6_BASE=$(make_base "cc6")
make_cycle "$CC6_BASE" "20260309_1000_a.md" "$(cat <<'FM'
feature: a
cycle: c1
phase: GREEN
complexity: standard
test_count: 4
risk_level: low
created: 2026-03-09 10:00
updated: 2026-03-09 10:00
FM
)"
make_cycle "$CC6_BASE" "20260309_1100_b.md" "$(cat <<'FM'
feature: b
cycle: c2
phase: GREEN
complexity: standard
test_count: 8
risk_level: medium
created: 2026-03-09 11:00
updated: 2026-03-09 11:00
FM
)"
CC6_OUT=$(bash "$SCRIPT" "$CC6_BASE")
if echo "$CC6_OUT" | grep -q "standard | 2 | 6 | 4 | 8"; then
  pass "CC6: test_count stats correct"
else
  fail "CC6: test_count stats incorrect"
fi

# CC7: Recent N (fewer than 10) -> dynamic header
echo ""
echo "CC7: Recent N with fewer than 10"
CC7_BASE=$(make_base "cc7")
make_cycle "$CC7_BASE" "20260309_1000_a.md" "$(cat <<'FM'
feature: a
cycle: c1
phase: RED
complexity: trivial
test_count: 2
risk_level: low
created: 2026-03-09 10:00
updated: 2026-03-09 10:00
FM
)"
make_cycle "$CC7_BASE" "20260309_1100_b.md" "$(cat <<'FM'
feature: b
cycle: c2
phase: GREEN
complexity: standard
test_count: 5
risk_level: medium
created: 2026-03-09 11:00
updated: 2026-03-09 11:00
FM
)"
make_cycle "$CC7_BASE" "20260309_1200_c.md" "$(cat <<'FM'
feature: c
cycle: c3
phase: DONE
complexity: complex
test_count: 10
risk_level: high
created: 2026-03-09 12:00
updated: 2026-03-09 12:00
FM
)"
CC7_OUT=$(bash "$SCRIPT" "$CC7_BASE")
if echo "$CC7_OUT" | grep -q "## Recent 3 Cycles"; then
  pass "CC7: dynamic header 'Recent 3 Cycles'"
else
  fail "CC7: expected 'Recent 3 Cycles' header"
fi

# CC8: Fast-path eligibility (trivial+standard)
echo ""
echo "CC8: Fast-path eligibility"
# Reuse CC7 data (trivial=1, standard=1, complex=1 -> 2/3 = 66%)
CC8_OUT="$CC7_OUT"
if echo "$CC8_OUT" | grep -q "Eligible (trivial+standard) | 2 / 3 (66%)"; then
  pass "CC8: fast-path eligibility correct"
else
  fail "CC8: fast-path eligibility incorrect"
fi

# CC9: Active vs archived separation
echo ""
echo "CC9: Active vs archived counts"
CC9_BASE=$(make_base "cc9")
make_cycle "$CC9_BASE" "20260309_1000_active.md" "$(cat <<'FM'
feature: active
cycle: c1
phase: RED
complexity: standard
test_count: 3
risk_level: low
created: 2026-03-09 10:00
updated: 2026-03-09 10:00
FM
)"
make_cycle "$CC9_BASE" "20260309_0900_archived.md" "$(cat <<'FM'
feature: archived
cycle: c0
phase: DONE
complexity: trivial
test_count: 2
risk_level: low
created: 2026-03-09 09:00
updated: 2026-03-09 09:00
FM
)" "archive"
CC9_OUT=$(bash "$SCRIPT" "$CC9_BASE")
CC9_OK=true
echo "$CC9_OUT" | grep -q "Active | 1" || CC9_OK=false
echo "$CC9_OUT" | grep -q "Archived | 1" || CC9_OK=false
echo "$CC9_OUT" | grep -q "Total cycles | 2" || CC9_OK=false
if [ "$CC9_OK" = true ]; then pass "CC9: active/archived separation correct"; else fail "CC9: active/archived counts wrong"; fi

# CC10: All files missing complexity -> 100% missing
echo ""
echo "CC10: All files missing complexity"
CC10_BASE=$(make_base "cc10")
echo "---
feature: old1
phase: DONE
created: 2026-01-01 00:00
updated: 2026-01-01 00:00
---
# Old" > "$CC10_BASE/docs/cycles/20260101_0000_old1.md"
echo "---
feature: old2
phase: DONE
created: 2026-01-02 00:00
updated: 2026-01-02 00:00
---
# Old" > "$CC10_BASE/docs/cycles/20260101_0100_old2.md"
CC10_OUT=$(bash "$SCRIPT" "$CC10_BASE")
if echo "$CC10_OUT" | grep -q "Missing complexity | 2 (100%)"; then
  pass "CC10: 100% missing complexity"
else
  fail "CC10: expected 100% missing"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
