#!/bin/bash
# test-pre-commit-gate-retro.sh - pre-commit-gate.sh retro_status check tests
# TC-06 to TC-09 (4 TCs) for v2.8 Agile Loop Cycle A2b
# Fixture-based: mktemp -d + trap for cleanup

set -uo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

TMPDIR_FIXTURE="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_FIXTURE"' EXIT

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

GATE="$BASE_DIR/scripts/gates/pre-commit-gate.sh"

# Helper: build a fixture cycle doc and directory structure for pre-commit-gate.sh
# Arguments:
#   $1 - fixture dir (must exist)
#   $2 - retro_status line: "retro_status: none" / "retro_status: captured" /
#        "retro_status: resolved" / "" (absent)
#   $3 - include_review_log: "yes" / "no"
make_gate_fixture() {
  local fixture_dir="$1"
  local retro_line="$2"
  local include_review="$3"

  mkdir -p "$fixture_dir/docs/cycles"

  local cycle_file="$fixture_dir/docs/cycles/20260101_0000_test.md"
  {
    echo "---"
    echo "feature: test-feature"
    echo "cycle: 20260101_0000"
    echo "phase: REVIEW"
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
    echo "## Progress Log"
    echo ""
    if [ "$include_review" = "yes" ]; then
      echo "### 2026-01-01 00:00 - REVIEW"
      echo ""
      echo "Codex review completed. No issues found."
      echo ""
      echo "Phase completed"
      echo ""
    fi
  } > "$cycle_file"
}

echo "=== pre-commit-gate.sh retro_status Check Tests (v2.8 Cycle A2b) ==="

if [ ! -f "$GATE" ]; then
  echo "ERROR: pre-commit-gate.sh not found at $GATE"
  exit 1
fi

# TC-06: pre-commit-gate.sh が retro_status: none で BLOCK を返す
# Given: fixture Cycle doc (retro_status: none, phase: REVIEW, REVIEW 完了記録あり)
# When:  bash pre-commit-gate.sh <fixture_dir> 2>&1
# Then:  exit 非0, 結合出力に "retro_status" を含む
echo ""
echo "TC-06: pre-commit-gate.sh blocks on retro_status: none"
FIXTURE_06="$TMPDIR_FIXTURE/tc06"
make_gate_fixture "$FIXTURE_06" "retro_status: none" "yes"
output_06="$(bash "$GATE" "$FIXTURE_06" 2>&1 || true)"
exit_06=$( (bash "$GATE" "$FIXTURE_06" > /dev/null 2>&1); echo $? )
if [ "$exit_06" -ne 0 ] && echo "$output_06" | grep -qi "retro_status"; then
  pass "TC-06: BLOCK on retro_status: none (exit=$exit_06, output contains 'retro_status')"
elif [ "$exit_06" -eq 0 ]; then
  fail "TC-06: expected BLOCK (exit non-0) but got exit 0 (output: $output_06)"
else
  fail "TC-06: exit non-0 but output does NOT contain 'retro_status' (output: $output_06)"
fi

# TC-07: pre-commit-gate.sh が retro_status: captured で PASS を返す
# Given: fixture Cycle doc (retro_status: captured, phase: REVIEW, REVIEW 完了記録あり)
# When:  bash pre-commit-gate.sh <fixture_dir>
# Then:  exit 0
echo ""
echo "TC-07: pre-commit-gate.sh passes on retro_status: captured"
FIXTURE_07="$TMPDIR_FIXTURE/tc07"
make_gate_fixture "$FIXTURE_07" "retro_status: captured" "yes"
if bash "$GATE" "$FIXTURE_07" > /dev/null 2>&1; then
  pass "TC-07: PASS on retro_status: captured (exit 0)"
else
  output_07="$(bash "$GATE" "$FIXTURE_07" 2>&1 || true)"
  fail "TC-07: expected PASS (exit 0) but BLOCK occurred (output: $output_07)"
fi

# TC-08: pre-commit-gate.sh が retro_status: resolved で PASS を返す
# Given: fixture Cycle doc (retro_status: resolved, phase: REVIEW, REVIEW 完了記録あり)
# When:  bash pre-commit-gate.sh <fixture_dir>
# Then:  exit 0
echo ""
echo "TC-08: pre-commit-gate.sh passes on retro_status: resolved"
FIXTURE_08="$TMPDIR_FIXTURE/tc08"
make_gate_fixture "$FIXTURE_08" "retro_status: resolved" "yes"
if bash "$GATE" "$FIXTURE_08" > /dev/null 2>&1; then
  pass "TC-08: PASS on retro_status: resolved (exit 0)"
else
  output_08="$(bash "$GATE" "$FIXTURE_08" 2>&1 || true)"
  fail "TC-08: expected PASS (exit 0) but BLOCK occurred (output: $output_08)"
fi

# TC-09: pre-commit-gate.sh が retro_status field 不在で BLOCK を返す (Codex post-commit P2 対応)
# 理由: A1 以降、retro_status は新規 Cycle doc の必須フィールド。
#   absent を許容すると cycle-retrospective idempotency (absent→skip) と組み合わせて
#   retrospective 必須化を bypass する抜け道になる。
# Given: fixture Cycle doc (retro_status フィールドなし, phase: REVIEW, REVIEW 完了記録あり)
# When:  bash pre-commit-gate.sh <fixture_dir> 2>&1
# Then:  exit 非0, 結合出力に "retro_status" または "missing" を含む
echo ""
echo "TC-09: pre-commit-gate.sh BLOCKs on absent retro_status (bypass prevention)"
FIXTURE_09="$TMPDIR_FIXTURE/tc09"
make_gate_fixture "$FIXTURE_09" "" "yes"
output_09="$(bash "$GATE" "$FIXTURE_09" 2>&1 || true)"
exit_09=$( (bash "$GATE" "$FIXTURE_09" > /dev/null 2>&1); echo $? )
if [ "$exit_09" -ne 0 ] && echo "$output_09" | grep -qiE "retro_status|missing"; then
  pass "TC-09: BLOCK on absent retro_status (exit=$exit_09, output mentions retro_status/missing)"
elif [ "$exit_09" -eq 0 ]; then
  fail "TC-09: expected BLOCK (exit non-0) for absent retro_status (bypass risk) but got exit 0 (output: $output_09)"
else
  fail "TC-09: exit non-0 but output does NOT mention retro_status/missing (output: $output_09)"
fi

# TC-10: pre-commit-gate.sh が retro_status: <invalid> で BLOCK (defense in depth、Codex review 対応)
# Given: fixture Cycle doc (retro_status: active, invalid な値)
# When:  bash pre-commit-gate.sh <fixture_dir> 2>&1
# Then:  exit 非0, 結合出力に "invalid" または "retro_status" を含む
echo ""
echo "TC-10: pre-commit-gate.sh blocks on invalid retro_status value"
FIXTURE_10="$TMPDIR_FIXTURE/tc10"
make_gate_fixture "$FIXTURE_10" "retro_status: active" "yes"
output_10="$(bash "$GATE" "$FIXTURE_10" 2>&1 || true)"
exit_10=$( (bash "$GATE" "$FIXTURE_10" > /dev/null 2>&1); echo $? )
if [ "$exit_10" -ne 0 ] && echo "$output_10" | grep -qiE "invalid|retro_status"; then
  pass "TC-10: BLOCK on invalid retro_status (exit=$exit_10, output contains error)"
elif [ "$exit_10" -eq 0 ]; then
  fail "TC-10: expected BLOCK for invalid value but got exit 0 (output: $output_10)"
else
  fail "TC-10: exit non-0 but output does NOT mention invalid/retro_status (output: $output_10)"
fi

# TC-11: pre-commit-gate.sh が retro_status: (present-but-empty) で BLOCK
# Given: fixture Cycle doc (retro_status: 空値)
# When:  bash pre-commit-gate.sh <fixture_dir> 2>&1
# Then:  exit 非0, 結合出力に "empty" または "retro_status" を含む
echo ""
echo "TC-11: pre-commit-gate.sh blocks on present-but-empty retro_status"
FIXTURE_11="$TMPDIR_FIXTURE/tc11"
make_gate_fixture "$FIXTURE_11" "retro_status:" "yes"
output_11="$(bash "$GATE" "$FIXTURE_11" 2>&1 || true)"
exit_11=$( (bash "$GATE" "$FIXTURE_11" > /dev/null 2>&1); echo $? )
if [ "$exit_11" -ne 0 ] && echo "$output_11" | grep -qiE "empty|retro_status"; then
  pass "TC-11: BLOCK on present-but-empty retro_status (exit=$exit_11)"
elif [ "$exit_11" -eq 0 ]; then
  fail "TC-11: expected BLOCK for empty value but got exit 0 (output: $output_11)"
else
  fail "TC-11: exit non-0 but output does NOT mention empty/retro_status (output: $output_11)"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
