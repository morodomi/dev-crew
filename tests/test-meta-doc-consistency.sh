#!/bin/bash
# test-meta-doc-consistency.sh - meta test for test-doc-consistency.sh TC-02 semantics
# Fixture-based: BASE_DIR env override で test-doc-consistency.sh を実行し TC-02 の振る舞いを検証
# TC-01 ~ TC-04

set -uo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

TMPDIR_FIXTURE="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_FIXTURE"' EXIT

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

SUBJECT="$BASE_DIR/tests/test-doc-consistency.sh"

echo "=== Meta Test: test-doc-consistency.sh TC-02 Semantics ==="

if [ ! -f "$SUBJECT" ]; then
  echo "ERROR: test-doc-consistency.sh not found at $SUBJECT"
  exit 1
fi

########################################
# Helper: build fixture directory structure
# $1 - fixture dir (must exist)
# $2 - architecture.md content
# $3 - number of skill dirs to create
########################################
make_fixture() {
  local fixture_dir="$1"
  local arch_content="$2"
  local skill_count="$3"

  mkdir -p "$fixture_dir/docs" "$fixture_dir/skills"
  echo "$arch_content" > "$fixture_dir/docs/architecture.md"
  echo "# placeholder" > "$fixture_dir/README.md"

  local i=1
  while [ "$i" -le "$skill_count" ]; do
    mkdir -p "$fixture_dir/skills/skill-$i"
    touch "$fixture_dir/skills/skill-$i/.gitkeep"
    i=$((i + 1))
  done
}

########################################
# TC-01: architecture.md に count なし + skills/ 2 dirs
# → TC-02 が "does not hardcode" PASS を返す
########################################
echo ""
echo "TC-01: TC-02 passes when architecture.md has no hardcoded skill count"

FIXTURE_01="$TMPDIR_FIXTURE/tc01"
make_fixture "$FIXTURE_01" "# Skills (flat, see STATUS.md for counts)" 2

# BASE_DIR override で test-doc-consistency.sh を実行し TC-02 行のみ抽出
tc02_output_01="$(BASE_DIR="$FIXTURE_01" bash "$SUBJECT" 2>&1 | grep -E "TC-02|does not hardcode" || true)"

if echo "$tc02_output_01" | grep -q "does not hardcode"; then
  pass "TC-01: TC-02 outputs 'does not hardcode' PASS when count absent"
else
  fail "TC-01: expected 'does not hardcode' in TC-02 output, got: $tc02_output_01"
fi

########################################
# TC-02: architecture.md に "2 skills" + skills/ 2 dirs
# → TC-02 が "= actual (2)" PASS を返す
########################################
echo ""
echo "TC-02: TC-02 passes when architecture.md count matches actual (2)"

FIXTURE_02="$TMPDIR_FIXTURE/tc02"
make_fixture "$FIXTURE_02" "# 2 skills available (see STATUS.md for details)" 2

tc02_output_02="$(BASE_DIR="$FIXTURE_02" bash "$SUBJECT" 2>&1 | grep -E "TC-02.*skill count|architecture\.md skill count.*= actual \(2\)" || true)"

# Tighten to architecture.md-specific PASS line to avoid false-positive match
# from TC-01's "README.md skill count (2) = actual (2)" (Codex/correctness review)
if echo "$tc02_output_02" | grep -qE "architecture\.md skill count \(2\) = actual \(2\)"; then
  pass "TC-02: TC-02 outputs 'architecture.md skill count (2) = actual (2)' PASS"
else
  fail "TC-02: expected 'architecture.md skill count (2) = actual (2)' PASS in TC-02 output, got: $tc02_output_02"
fi

########################################
# TC-03: architecture.md に "99 skills" + skills/ 2 dirs (mismatch)
# → TC-02 が "!= actual" FAIL を返す
########################################
echo ""
echo "TC-03: TC-02 fails when architecture.md count does not match actual (99 vs 2)"

FIXTURE_03="$TMPDIR_FIXTURE/tc03"
make_fixture "$FIXTURE_03" "# 99 skills (outdated)" 2

tc02_output_03="$(BASE_DIR="$FIXTURE_03" bash "$SUBJECT" 2>&1 | grep -E "TC-02|architecture\.md skill count.*!= actual" || true)"

# Tighten to architecture.md-specific FAIL line to avoid false-positive match
# from any other test's "!= actual" output (Codex/correctness review)
if echo "$tc02_output_03" | grep -qE "architecture\.md skill count \(99\) != actual \(2\)"; then
  pass "TC-03: TC-02 outputs 'architecture.md skill count (99) != actual (2)' FAIL"
else
  fail "TC-03: expected 'architecture.md skill count (99) != actual (2)' FAIL in TC-02 output, got: $tc02_output_03"
fi

########################################
# TC-04: 実 repo (BASE_DIR default) で test-doc-consistency.sh 実行
# → TC-02 が PASS + strict assertion:
#   stdout に "TC-02.*skill count check" + "PASS.*architecture\.md does not hardcode skill count" の両方ヒット
########################################
echo ""
echo "TC-04: Real repo run: TC-02 PASS with strict output assertion (no header-only match)"

real_output="$(bash "$SUBJECT" 2>&1 || true)"

header_hit=false
pass_hit=false

if echo "$real_output" | grep -qE "TC-02.*skill count check"; then
  header_hit=true
fi

if echo "$real_output" | grep -qE "PASS.*architecture\.md does not hardcode skill count"; then
  pass_hit=true
fi

if $header_hit && $pass_hit; then
  pass "TC-04: TC-02 PASS with both header and PASS message present in real repo run"
elif ! $header_hit; then
  fail "TC-04: 'TC-02.*skill count check' header not found in output"
elif ! $pass_hit; then
  fail "TC-04: 'PASS.*architecture.md does not hardcode skill count' not found in output (header present but PASS text missing)"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
