#!/bin/bash
# test-frontmatter-retro-status.sh - retro_status field foundation tests
# TC-01 to TC-08 (9 TCs total) for v2.8 Agile Loop Cycle A1

set -uo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

TMPDIR_FIXTURE="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_FIXTURE"' EXIT

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

# Helper: build a minimal valid cycle doc fixture (frontmatter + body)
make_fixture() {
  local file="$1"
  local retro_line="$2"   # e.g. "retro_status: none" or "" (empty = omit field)
  local body="$3"         # additional body lines (may be empty)

  {
    echo "---"
    echo "feature: test-feature"
    echo "cycle: 20260101_0000"
    echo "phase: RED"
    echo "complexity: standard"
    echo "test_count: 1"
    echo "risk_level: low"
    if [ -n "$retro_line" ]; then
      echo "$retro_line"
    fi
    echo 'codex_session_id: ""'
    echo "created: 2026-01-01 00:00"
    echo "updated: 2026-01-01 00:00"
    echo "---"
    echo ""
    echo "# Test Fixture"
    echo ""
    if [ -n "$body" ]; then
      echo "$body"
    fi
  } > "$file"
}

VALIDATOR="$BASE_DIR/scripts/validate-cycle-frontmatter.sh"
CYCLE_TEMPLATE="$BASE_DIR/skills/spec/templates/cycle.md"
SYNC_PLAN_AGENT="$BASE_DIR/agents/sync-plan.md"
STATE_OWNERSHIP="$BASE_DIR/rules/state-ownership.md"

echo "=== retro_status Foundation Tests (v2.8 Cycle A1) ==="

# TC-01: cycle.md template contains retro_status: none field
echo ""
echo "TC-01: cycle.md template has retro_status: none field"
if [ ! -f "$CYCLE_TEMPLATE" ]; then
  fail "TC-01: skills/spec/templates/cycle.md does not exist"
elif grep -q "retro_status: none" "$CYCLE_TEMPLATE"; then
  pass "TC-01: cycle.md template contains retro_status: none"
else
  fail "TC-01: cycle.md template does NOT contain retro_status: none"
fi

# TC-02: cycle.md template does NOT have a ## Retrospective placeholder section
echo ""
echo "TC-02: cycle.md template has NO ## Retrospective placeholder"
if [ ! -f "$CYCLE_TEMPLATE" ]; then
  fail "TC-02: skills/spec/templates/cycle.md does not exist"
elif grep -q "^## Retrospective" "$CYCLE_TEMPLATE"; then
  fail "TC-02: cycle.md template CONTAINS ## Retrospective placeholder (should be absent)"
else
  pass "TC-02: cycle.md template correctly has no ## Retrospective placeholder"
fi

# TC-03: agents/sync-plan.md includes retro_status: none initialization
# Strengthened (Codex P3): assert that the same line containing retro_status also specifies "none"
# default — presence alone is insufficient (would pass on any text mentioning the field).
echo ""
echo "TC-03: agents/sync-plan.md includes retro_status: none initialization (default contract)"
if [ ! -f "$SYNC_PLAN_AGENT" ]; then
  fail "TC-03: agents/sync-plan.md does not exist"
else
  RETRO_LINE="$(grep "retro_status" "$SYNC_PLAN_AGENT" | head -1 || true)"
  if [ -z "$RETRO_LINE" ]; then
    fail "TC-03: agents/sync-plan.md does NOT contain retro_status"
  elif echo "$RETRO_LINE" | grep -q "none"; then
    pass "TC-03: agents/sync-plan.md initializes retro_status to none (line: '$RETRO_LINE')"
  else
    fail "TC-03: agents/sync-plan.md mentions retro_status but does NOT specify 'none' default (line: '$RETRO_LINE')"
  fi
fi

# TC-04: validate-cycle-frontmatter.sh accepts retro_status: none/captured/resolved
# Counted as a single TC: pass once if all 3 accepted, fail once otherwise (avoids inflating FAIL count)
echo ""
echo "TC-04: validator accepts retro_status none/captured/resolved"
TC04_PASS=true
TC04_REJECTED=""
for val in none captured resolved; do
  fixture="$TMPDIR_FIXTURE/tc04_${val}.md"
  make_fixture "$fixture" "retro_status: ${val}" ""
  if ! bash "$VALIDATOR" "$fixture" 2>/dev/null; then
    TC04_PASS=false
    TC04_REJECTED="${TC04_REJECTED}${val} "
  fi
done
if [ "$TC04_PASS" = "true" ]; then
  pass "TC-04: validator accepted all valid retro_status values (none/captured/resolved)"
else
  fail "TC-04: validator rejected valid value(s): $TC04_REJECTED"
fi

# TC-05: validate-cycle-frontmatter.sh rejects retro_status: active (invalid)
echo ""
echo "TC-05: validator rejects retro_status: active (invalid value)"
fixture_05="$TMPDIR_FIXTURE/tc05_invalid.md"
make_fixture "$fixture_05" "retro_status: active" ""
stderr_05="$(bash "$VALIDATOR" "$fixture_05" 2>&1 >/dev/null || true)"
if bash "$VALIDATOR" "$fixture_05" 2>/dev/null; then
  fail "TC-05: validator accepted retro_status: active (should reject)"
elif echo "$stderr_05" | grep -qi "retro_status"; then
  pass "TC-05: validator rejected retro_status: active with retro_status in stderr"
else
  fail "TC-05: validator rejected but stderr did not mention retro_status (got: $stderr_05)"
fi

# TC-06: validate-cycle-frontmatter.sh accepts missing retro_status field (legacy compat)
echo ""
echo "TC-06: validator accepts missing retro_status field (legacy compat)"
fixture_06="$TMPDIR_FIXTURE/tc06_absent.md"
make_fixture "$fixture_06" "" ""
if bash "$VALIDATOR" "$fixture_06" 2>/dev/null; then
  pass "TC-06: validator accepted cycle doc without retro_status field"
else
  fail "TC-06: validator rejected cycle doc without retro_status field (should accept for legacy compat)"
fi

# TC-07: validate-cycle-frontmatter.sh detects body-level line-initial retro_status: contamination
echo ""
echo "TC-07: validator detects line-initial retro_status: in body (contamination)"
fixture_07="$TMPDIR_FIXTURE/tc07_body_contamination.md"
# body line starts at column 0 with "retro_status: captured" — state-like metadata leak
make_fixture "$fixture_07" "retro_status: none" "retro_status: captured"
stderr_07="$(bash "$VALIDATOR" "$fixture_07" 2>&1 >/dev/null || true)"
if bash "$VALIDATOR" "$fixture_07" 2>/dev/null; then
  fail "TC-07: validator accepted body-level retro_status: line (should detect contamination)"
elif echo "$stderr_07" | grep -qiE "retro_status|body|contamination"; then
  pass "TC-07: validator detected body contamination (retro_status: at line start)"
else
  fail "TC-07: validator rejected but stderr did not mention retro_status/body/contamination (got: $stderr_07)"
fi

# TC-07b: validate-cycle-frontmatter.sh does NOT flag inline (non-line-initial) retro_status: in body
echo ""
echo "TC-07b: validator ignores inline retro_status: in body (no false positive)"
fixture_07b="$TMPDIR_FIXTURE/tc07b_inline.md"
# body line has "retro_status:" embedded mid-sentence — must NOT trigger contamination
make_fixture "$fixture_07b" "retro_status: none" "Some text retro_status: captured here"
if bash "$VALIDATOR" "$fixture_07b" 2>/dev/null; then
  pass "TC-07b: validator correctly ignored inline retro_status: (no false positive)"
else
  fail "TC-07b: validator falsely flagged inline retro_status: in body (should pass)"
fi

# TC-09: validator rejects present-but-empty retro_status (Codex review BLOCK fix)
echo ""
echo "TC-09: validator rejects present-but-empty retro_status"
fixture_09_empty="$TMPDIR_FIXTURE/tc09_empty.md"
make_fixture "$fixture_09_empty" "retro_status:" ""
fixture_09_ws="$TMPDIR_FIXTURE/tc09_whitespace.md"
make_fixture "$fixture_09_ws" "retro_status:    " ""
TC09_PASS=true
for fixture in "$fixture_09_empty" "$fixture_09_ws"; do
  if bash "$VALIDATOR" "$fixture" 2>/dev/null; then
    fail "TC-09: validator accepted present-but-empty retro_status (should reject): $fixture"
    TC09_PASS=false
  fi
done
if [ "$TC09_PASS" = "true" ]; then
  pass "TC-09: validator rejected present-but-empty retro_status (empty + whitespace-only)"
fi

# TC-08: rules/state-ownership.md sync-plan row mentions retro_status with default
# Strengthened (Codex P3): assert the sync-plan row specifies the "= none" default,
# not just the field name. Otherwise default semantics regression slips through.
echo ""
echo "TC-08: rules/state-ownership.md sync-plan row includes retro_status (= none) default"
if [ ! -f "$STATE_OWNERSHIP" ]; then
  fail "TC-08: rules/state-ownership.md does not exist"
else
  SYNCPLAN_LINE="$(grep "sync-plan" "$STATE_OWNERSHIP" || true)"
  if [ -z "$SYNCPLAN_LINE" ]; then
    fail "TC-08: rules/state-ownership.md has no sync-plan entry"
  elif echo "$SYNCPLAN_LINE" | grep -q "retro_status"; then
    # Stricter check: must also document the default value
    if echo "$SYNCPLAN_LINE" | grep -qE "retro_status[^|]*none"; then
      pass "TC-08: rules/state-ownership.md sync-plan row specifies retro_status with 'none' default"
    else
      fail "TC-08: rules/state-ownership.md sync-plan row mentions retro_status but does NOT specify 'none' default (line: $SYNCPLAN_LINE)"
    fi
  else
    fail "TC-08: rules/state-ownership.md sync-plan row does NOT contain retro_status (line: $SYNCPLAN_LINE)"
  fi
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
