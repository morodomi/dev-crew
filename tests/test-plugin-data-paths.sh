#!/bin/bash
# test-plugin-data-paths.sh - Tests for CLAUDE_PLUGIN_DATA migration
# T-01: observe.sh DATA_DIR uses CLAUDE_PLUGIN_DATA when set
# T-02: observe.sh DATA_DIR falls back to ~/.claude/dev-crew when unset
# T-03: deprecated scripts (plan-exit-flag.sh / post-approve-gate.sh) remain absent (cycle dc89b17 v2.6.6)
# T-06: no ~/.claude/dev-crew hardcodes outside docs/cycles/ and ROADMAP.md

set -uo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== Plugin Data Paths Tests ==="

# ---------------------------------------------------------------------------
# Helper: resolve DATA_DIR from a script file in a subshell with given env
# Extracts the line containing CLAUDE_PLUGIN_DATA pattern and evaluates it.
# ---------------------------------------------------------------------------
resolve_data_dir() {
  local script="$1"
  local var_name="$2"
  # Extract the assignment line for the variable that uses CLAUDE_PLUGIN_DATA
  local line
  line=$(grep "CLAUDE_PLUGIN_DATA" "$script" | grep "${var_name}=" | head -1)
  if [ -z "$line" ]; then
    echo "__NOT_FOUND__"
    return
  fi
  eval "$line"
  eval echo "\$$var_name"
}

# ---------------------------------------------------------------------------
# T-01: Given CLAUDE_PLUGIN_DATA=/tmp/test-pd,
#       When observe.sh resolves DATA_DIR,
#       Then DATA_DIR uses CLAUDE_PLUGIN_DATA
# ---------------------------------------------------------------------------
echo ""
echo "T-01: observe.sh uses CLAUDE_PLUGIN_DATA when set"

OBSERVE_SCRIPT="$BASE_DIR/scripts/hooks/observe.sh"

RESOLVED=$(
  export HOME="$HOME"
  export CLAUDE_PLUGIN_DATA="/tmp/test-pd"
  line=$(grep "CLAUDE_PLUGIN_DATA" "$OBSERVE_SCRIPT" | grep "DATA_DIR=" | head -1)
  if [ -z "$line" ]; then echo "__NOT_FOUND__"; exit 0; fi
  eval "$line"
  echo "$DATA_DIR"
)

if [ "$RESOLVED" = "/tmp/test-pd" ]; then
  pass "T-01: DATA_DIR=/tmp/test-pd when CLAUDE_PLUGIN_DATA is set"
else
  fail "T-01: expected DATA_DIR=/tmp/test-pd, got: ${RESOLVED} (observe.sh missing CLAUDE_PLUGIN_DATA support)"
fi

# ---------------------------------------------------------------------------
# T-02: Given CLAUDE_PLUGIN_DATA unset,
#       When observe.sh resolves DATA_DIR,
#       Then DATA_DIR=$HOME/.claude/dev-crew
# ---------------------------------------------------------------------------
echo ""
echo "T-02: observe.sh falls back to ~/.claude/dev-crew when CLAUDE_PLUGIN_DATA unset"

EXPECTED_FALLBACK="$HOME/.claude/dev-crew"

RESOLVED=$(
  export HOME="$HOME"
  unset CLAUDE_PLUGIN_DATA 2>/dev/null || true
  line=$(grep "CLAUDE_PLUGIN_DATA" "$OBSERVE_SCRIPT" | grep "DATA_DIR=" | head -1)
  if [ -z "$line" ]; then echo "__NOT_FOUND__"; exit 0; fi
  eval "$line"
  echo "$DATA_DIR"
)

if [ "$RESOLVED" = "$EXPECTED_FALLBACK" ]; then
  pass "T-02: DATA_DIR falls back to $EXPECTED_FALLBACK"
else
  fail "T-02: expected DATA_DIR=$EXPECTED_FALLBACK, got: ${RESOLVED}"
fi

# ---------------------------------------------------------------------------
# T-03: deprecated scripts (plan-exit-flag.sh / post-approve-gate.sh) remain absent
# Given: cycle dc89b17 (v2.6.6) で plan-exit-flag.sh と post-approve-gate.sh が削除された
# When: scripts/hooks/ (歴史的削除パス、cycle dc89b17 で確認) を確認
# Then: 両 deprecated script が存在しない
# ---------------------------------------------------------------------------
echo ""
echo "T-03: deprecated scripts (plan-exit-flag.sh / post-approve-gate.sh) remain absent (cycle dc89b17 v2.6.6)"

PLAN_EXIT_FLAG="$BASE_DIR/scripts/hooks/plan-exit-flag.sh"
POST_APPROVE_GATE="$BASE_DIR/scripts/hooks/post-approve-gate.sh"

if [ ! -f "$PLAN_EXIT_FLAG" ] && [ ! -f "$POST_APPROVE_GATE" ]; then
  pass "T-03: deprecated scripts absent (post-approve-gate flag removed in cycle dc89b17)"
else
  fail "T-03: deprecated script(s) reappeared, contradicting dc89b17 deprecation"
fi

# ---------------------------------------------------------------------------
# T-06: grep completion condition -
#       no ~/.claude/dev-crew references in non-cycle files (excluding ROADMAP.md)
# ---------------------------------------------------------------------------
echo ""
echo "T-06: no ~/.claude/dev-crew hardcodes outside docs/cycles/ and ROADMAP.md"

COUNT=$(
  grep -r '~/.claude/dev-crew' \
    --include='*.sh' --include='*.md' --include='*.json' \
    --exclude-dir='cycles' \
    "$BASE_DIR" 2>/dev/null \
  | grep -v 'ROADMAP.md' \
  | grep -v 'CLAUDE_PLUGIN_DATA' \
  | grep -v 'test-plugin-data-paths.sh' \
  | grep -v 'test-instinct-paths.sh' \
  | wc -l \
  | tr -d ' '
)

if [ "$COUNT" -eq 0 ]; then
  pass "T-06: 0 hardcoded ~/.claude/dev-crew references found"
else
  fail "T-06: found $COUNT hardcoded ~/.claude/dev-crew references (should be 0)"
  # Show the offending lines for debugging
  grep -r '~/.claude/dev-crew' \
    --include='*.sh' --include='*.md' --include='*.json' \
    --exclude-dir='cycles' \
    "$BASE_DIR" 2>/dev/null \
  | grep -v 'ROADMAP.md' \
  | grep -v 'CLAUDE_PLUGIN_DATA' \
  | grep -v 'test-plugin-data-paths.sh' \
  | grep -v 'test-instinct-paths.sh' \
  | head -20 || true
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "=== Summary ==="
echo "PASS: $PASS"
echo "FAIL: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi

exit 0
