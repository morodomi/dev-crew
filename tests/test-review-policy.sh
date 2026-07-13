#!/bin/bash
# test-review-policy.sh - review_policy schema + reviewer model resolution contract tests
# TC-01 to TC-06

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

DEV_CREW_JSON="$BASE_DIR/.claude/dev-crew.json"
STEPS_SUBAGENT="$BASE_DIR/skills/review/steps-subagent.md"
REVIEW_REFERENCE="$BASE_DIR/skills/review/reference.md"
REVIEW_TRIAGE="$BASE_DIR/rules/review-triage.md"
ONBOARD_REFERENCE="$BASE_DIR/skills/onboard/reference.md"

echo "=== review-policy Contract Tests ==="

# TC-01: dev-crew.json review_policy.reviewer_model is present and within allowlist
echo ""
echo "TC-01: dev-crew.json review_policy.reviewer_model allowlist (enumerate-and-reject)"
if [ ! -f "$DEV_CREW_JSON" ]; then
  fail "TC-01: .claude/dev-crew.json does not exist"
else
  key_present=1
  jq -e '.review_policy.reviewer_model' "$DEV_CREW_JSON" >/dev/null 2>&1 || key_present=0
  reviewer_model=$(jq -r '.review_policy.reviewer_model // "self"' "$DEV_CREW_JSON" 2>/dev/null || echo "")
  if [ "$key_present" -ne 1 ]; then
    fail "TC-01: review_policy.reviewer_model key is absent (// \"self\" fallback would mask this)"
  else
    case "$reviewer_model" in
      self | sonnet | haiku | opus | fable)
        pass "TC-01: review_policy.reviewer_model='$reviewer_model' is within allowlist (self|sonnet|haiku|opus|fable)"
        ;;
      *)
        fail "TC-01: review_policy.reviewer_model='$reviewer_model' is NOT in allowlist (self|sonnet|haiku|opus|fable)"
        ;;
    esac
  fi
fi

# TC-02: dev-crew.json review_policy.escalate_high_to is present and null or within allowlist
echo ""
echo "TC-02: dev-crew.json review_policy.escalate_high_to null-or-allowlist"
if [ ! -f "$DEV_CREW_JSON" ]; then
  fail "TC-02: .claude/dev-crew.json does not exist"
else
  has_key=$(jq -r '(.review_policy // {}) | has("escalate_high_to")' "$DEV_CREW_JSON" 2>/dev/null || echo "false")
  escalate=$(jq -r '.review_policy.escalate_high_to // "null"' "$DEV_CREW_JSON" 2>/dev/null || echo "")
  if [ "$has_key" != "true" ]; then
    fail "TC-02: review_policy.escalate_high_to key is absent (has() check, not value-null check)"
  else
    case "$escalate" in
      null | self | sonnet | haiku | opus | fable)
        pass "TC-02: review_policy.escalate_high_to='$escalate' is null or within allowlist"
        ;;
      *)
        fail "TC-02: review_policy.escalate_high_to='$escalate' is NOT null nor in allowlist"
        ;;
    esac
  fi
fi

# TC-03: steps-subagent.md AND reference.md document policy resolution + self resolution rule
# (BLOCK 1 fix; reference.md 側も pin して両ファイルの drift を検出 — maintainability F2)
echo ""
echo "TC-03: steps-subagent.md + reference.md document review_policy resolution + self rule"
if [ ! -f "$STEPS_SUBAGENT" ]; then
  fail "TC-03: skills/review/steps-subagent.md does not exist"
elif [ ! -f "$REVIEW_REFERENCE" ]; then
  fail "TC-03: skills/review/reference.md does not exist"
else
  phrase_a=$(grep -cF "review_policy を読みモデルを解決" "$STEPS_SUBAGENT" || true)
  phrase_b=$(grep -cF "orchestrator 自身の現モデルを Task に明示的に渡す" "$STEPS_SUBAGENT" || true)
  phrase_c=$(grep -cF "orchestrator 自身が現在動いているモデルを Task の" "$REVIEW_REFERENCE" || true)
  if [ "$phrase_a" -ge 1 ] && [ "$phrase_b" -ge 1 ] && [ "$phrase_c" -ge 1 ]; then
    pass "TC-03: steps-subagent.md policy+self rule present AND reference.md self rule present (no drift)"
  elif [ "$phrase_a" -lt 1 ]; then
    fail "TC-03: steps-subagent.md missing 'review_policy を読みモデルを解決' phrase"
  elif [ "$phrase_b" -lt 1 ]; then
    fail "TC-03: steps-subagent.md missing self resolution phrase"
  else
    fail "TC-03: reference.md missing self resolution rule (drift from steps-subagent.md)"
  fi
fi

# TC-04: NON-NEGOTIABLE floor phrase present + negative contract (correctness 省略可 must be absent)
echo ""
echo "TC-04: NON-NEGOTIABLE floor phrase + negative 'correctness 省略可' contract"
if [ ! -f "$STEPS_SUBAGENT" ]; then
  fail "TC-04: skills/review/steps-subagent.md does not exist"
elif [ ! -f "$REVIEW_TRIAGE" ]; then
  fail "TC-04: rules/review-triage.md does not exist"
else
  floor_count=$(grep -cF "policy/score 不問で常時起動" "$STEPS_SUBAGENT" || true)
  negative_count=$(grep -cF "correctness 省略可" "$REVIEW_TRIAGE" || true)
  if [ "$floor_count" -ge 1 ] && [ "$negative_count" -eq 0 ]; then
    pass "TC-04: NON-NEGOTIABLE floor phrase present in steps-subagent.md + 'correctness 省略可' absent from review-triage.md"
  elif [ "$floor_count" -lt 1 ]; then
    fail "TC-04: steps-subagent.md missing NON-NEGOTIABLE floor phrase 'policy/score 不問で常時起動'"
  else
    fail "TC-04: rules/review-triage.md still contains 'correctness 省略可' (floor regression, WARN not resolved)"
  fi
fi

# TC-05: onboard/reference.md heredoc + Reviewer Policy declaration section
echo ""
echo "TC-05: onboard reference.md review_policy heredoc + Reviewer Policy section"
if [ ! -f "$ONBOARD_REFERENCE" ]; then
  fail "TC-05: skills/onboard/reference.md does not exist"
else
  heredoc_block=$(awk '
    index($0, "cat > .claude/dev-crew.json") > 0 {flag=1; next}
    flag && $0 == "EOF" {flag=0}
    flag
  ' "$ONBOARD_REFERENCE")
  heredoc_has_policy=$(printf '%s\n' "$heredoc_block" | grep -cF "review_policy" || true)
  section_has_policy=$(grep -cF "Reviewer Policy" "$ONBOARD_REFERENCE" || true)
  if [ "$heredoc_has_policy" -ge 1 ] && [ "$section_has_policy" -ge 1 ]; then
    pass "TC-05: onboard reference.md heredoc includes review_policy + 'Reviewer Policy' declaration section present"
  elif [ "$heredoc_has_policy" -lt 1 ]; then
    fail "TC-05: onboard dev-crew.json 生成 heredoc missing review_policy"
  else
    fail "TC-05: onboard reference.md missing 'Reviewer Policy' declaration section"
  fi
fi

# TC-06: policy-controlled reviewers (security/correctness/maintainability) have hardcoded
# model: "sonnet" literal removed from their Code Mode Task calls (TC-34 drift guard avoidance)
echo ""
echo "TC-06: Code Mode policy-controlled reviewers have model literal removed"
if [ ! -f "$STEPS_SUBAGENT" ]; then
  fail "TC-06: skills/review/steps-subagent.md does not exist"
else
  code_mode_block=$(awk '
    $0 == "### Code Mode" {flag=1; next}
    $0 == "### Plan Mode" {flag=0}
    flag
  ' "$STEPS_SUBAGENT")

  tc06_ok=true
  for reviewer in security-reviewer correctness-reviewer maintainability-reviewer performance-reviewer api-contract-reviewer observability-reviewer test-reviewer; do
    reviewer_line=$(printf '%s\n' "$code_mode_block" | grep "dev-crew:${reviewer}" || true)
    if [ -z "$reviewer_line" ]; then
      fail "TC-06: dev-crew:${reviewer} Task call not found in Code Mode block"
      tc06_ok=false
    elif printf '%s\n' "$reviewer_line" | grep -qF 'model: "sonnet"'; then
      fail "TC-06: dev-crew:${reviewer} Task still has hardcoded model: \"sonnet\" literal (drift guard TC-34 unresolved)"
      tc06_ok=false
    fi
  done
  if [ "$tc06_ok" = "true" ]; then
    pass "TC-06: all 7 Code Mode policy-controlled reviewers have model literal removed (prose-resolved)"
  fi
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
