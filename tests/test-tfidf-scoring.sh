#!/bin/bash
# test-tfidf-scoring.sh - Verify TF-IDF + COUNT scoring in observer/learn pipeline
# TC-06: observer.md has TF-IDF base score table
# TC-07: observer.md has evidence_multiplier table
# TC-08: observer.md has 2-axis formula (tfidf_to_base * evidence_multiplier)
# TC-09: observer.md Input has tfidf_summary field
# TC-10: learn SKILL.md Step 2 has TF-IDF summary computation
# TC-11: learn reference.md has TF-IDF formulas (TF, IDF, TF-IDF)
# TC-12: learn reference.md has bootstrap threshold (sessions < 20)
# TC-13: learn reference.md has Term definition
# TC-14: observer.md has TF-IDF < 0.2 discard rule
# TC-15: observer.md has COUNT < 3 discard rule

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

echo "=== TF-IDF Scoring Tests ==="

# TC-06: observer.md has TF-IDF base score table (tfidf_to_base)
echo ""
echo "TC-06: observer.md has TF-IDF base score table"
if grep -q 'tfidf_to_base\|TF-IDF.*ベーススコア' "$BASE_DIR/agents/observer.md" && \
   grep -q '< 0\.2' "$BASE_DIR/agents/observer.md" && \
   grep -q '0\.85.*非常に特徴的' "$BASE_DIR/agents/observer.md"; then
  pass "observer.md has TF-IDF base score table"
else
  fail "observer.md does NOT have TF-IDF base score table"
fi

# TC-07: observer.md has evidence_multiplier table
echo ""
echo "TC-07: observer.md has evidence_multiplier table"
if grep -q 'evidence_multiplier\|証拠.*係数' "$BASE_DIR/agents/observer.md" && \
   grep -q '0\.8.*限定的' "$BASE_DIR/agents/observer.md" && \
   grep -q '1\.0.*十分' "$BASE_DIR/agents/observer.md"; then
  pass "observer.md has evidence_multiplier table"
else
  fail "observer.md does NOT have evidence_multiplier table"
fi

# TC-08: observer.md has 2-axis formula
echo ""
echo "TC-08: observer.md has 2-axis formula"
if grep -qE 'tfidf_to_base.*evidence_multiplier|ベーススコア.*係数' "$BASE_DIR/agents/observer.md"; then
  pass "observer.md has 2-axis formula"
else
  fail "observer.md does NOT have 2-axis formula"
fi

# TC-09: observer.md Input has tfidf_summary field
echo ""
echo "TC-09: observer.md Input has tfidf_summary field"
if grep -q 'tfidf_summary' "$BASE_DIR/agents/observer.md"; then
  pass "observer.md Input has tfidf_summary field"
else
  fail "observer.md Input does NOT have tfidf_summary field"
fi

# TC-10: learn SKILL.md Step 2 has TF-IDF summary computation
echo ""
echo "TC-10: learn SKILL.md Step 2 has TF-IDF summary computation"
if grep -q 'TF-IDF' "$BASE_DIR/skills/learn/SKILL.md" && \
   grep -q 'tfidf_summary' "$BASE_DIR/skills/learn/SKILL.md"; then
  pass "learn SKILL.md has TF-IDF summary computation"
else
  fail "learn SKILL.md does NOT have TF-IDF summary computation"
fi

# TC-11: learn reference.md has TF-IDF formulas
echo ""
echo "TC-11: learn reference.md has TF-IDF formulas"
if grep -qE 'log2|IDF.*log' "$BASE_DIR/skills/learn/reference.md" && \
   grep -qE 'TF.*IDF|TF-IDF' "$BASE_DIR/skills/learn/reference.md"; then
  pass "learn reference.md has TF-IDF formulas"
else
  fail "learn reference.md does NOT have TF-IDF formulas"
fi

# TC-12: learn reference.md has bootstrap threshold
echo ""
echo "TC-12: learn reference.md has bootstrap threshold (sessions < 20)"
if grep -qE 'ブートストラップ|bootstrap' "$BASE_DIR/skills/learn/reference.md" && \
   grep -q '20' "$BASE_DIR/skills/learn/reference.md"; then
  pass "learn reference.md has bootstrap threshold"
else
  fail "learn reference.md does NOT have bootstrap threshold"
fi

# TC-13: learn reference.md has Term definition
echo ""
echo "TC-13: learn reference.md has Term definition"
if grep -qE 'Term.*tool_name.*category|term.*ツール名.*カテゴリ' "$BASE_DIR/skills/learn/reference.md" || \
   grep -qE 'tool_name.*:.*category|Bash.*コマンド.*Edit.*拡張子' "$BASE_DIR/skills/learn/reference.md"; then
  pass "learn reference.md has Term definition"
else
  fail "learn reference.md does NOT have Term definition"
fi

# TC-14: observer.md has TF-IDF < 0.2 discard rule
echo ""
echo "TC-14: observer.md has TF-IDF < 0.2 discard rule"
if grep -qE '< 0\.2|<\s*0\.2' "$BASE_DIR/agents/observer.md" && \
   grep -qE '破棄|discard|baseline' "$BASE_DIR/agents/observer.md"; then
  pass "observer.md has TF-IDF < 0.2 discard rule"
else
  fail "observer.md does NOT have TF-IDF < 0.2 discard rule"
fi

# TC-15: observer.md has COUNT < 3 discard rule
echo ""
echo "TC-15: observer.md has COUNT < 3 discard rule"
if grep -qE '< 3|<\s*3' "$BASE_DIR/agents/observer.md" && \
   grep -q '証拠不足\|evidence.*insufficient\|破棄' "$BASE_DIR/agents/observer.md"; then
  pass "observer.md has COUNT < 3 discard rule"
else
  fail "observer.md does NOT have COUNT < 3 discard rule"
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
