#!/bin/bash
# test-v2-restructuring.sh - dev-crew v2 restructuring validation
# Validates: new agents, risk classifier, unified review, orchestrate flow,
#            retired agents/skills, strategy skill, commit update

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

get_frontmatter() {
  local file="$1"
  local key="$2"
  awk '/^---$/{n++; next} n==1{print}' "$file" | grep "^${key}: " | head -1 | sed "s/^${key}: *//" || true
}

echo "=== dev-crew v2 Restructuring Tests ==="

########################################
# Step 1: New Agents
########################################

echo ""
echo "--- Step 1: New Agents ---"

# TC-01: review-briefer.md exists with correct frontmatter
echo ""
echo "TC-01: review-briefer.md frontmatter"
BRIEFER="$BASE_DIR/agents/review-briefer.md"
if [ -f "$BRIEFER" ]; then
  name_val=$(get_frontmatter "$BRIEFER" "name")
  desc_val=$(get_frontmatter "$BRIEFER" "description")
  model_val=$(get_frontmatter "$BRIEFER" "model")
  if [ "$name_val" = "review-briefer" ] && [ -n "$desc_val" ] && [ "$model_val" = "haiku" ]; then
    pass "TC-01: review-briefer.md has correct frontmatter (name, description, model: haiku)"
  else
    fail "TC-01: review-briefer.md frontmatter incorrect (name='$name_val', model='$model_val')"
  fi
else
  fail "TC-01: review-briefer.md not found"
fi

# TC-02: design-reviewer.md exists with correct frontmatter
echo ""
echo "TC-02: design-reviewer.md frontmatter"
DESIGNER="$BASE_DIR/agents/design-reviewer.md"
if [ -f "$DESIGNER" ]; then
  name_val=$(get_frontmatter "$DESIGNER" "name")
  desc_val=$(get_frontmatter "$DESIGNER" "description")
  model_val=$(get_frontmatter "$DESIGNER" "model")
  if [ "$name_val" = "design-reviewer" ] && [ -n "$desc_val" ] && [ "$model_val" = "sonnet" ]; then
    pass "TC-02: design-reviewer.md has correct frontmatter (name, description, model: sonnet)"
  else
    fail "TC-02: design-reviewer.md frontmatter incorrect (name='$name_val', model='$model_val')"
  fi
else
  fail "TC-02: design-reviewer.md not found"
fi

# TC-03: design-reviewer.md covers scope + architecture + risk
echo ""
echo "TC-03: design-reviewer.md covers scope + architecture + risk"
if [ -f "$DESIGNER" ]; then
  scope_ok=false
  arch_ok=false
  risk_ok=false
  grep -qi "scope\|スコープ\|変更範囲" "$DESIGNER" && scope_ok=true
  grep -qi "architecture\|アーキテクチャ\|設計整合" "$DESIGNER" && arch_ok=true
  grep -qi "risk\|リスク\|影響範囲" "$DESIGNER" && risk_ok=true
  if $scope_ok && $arch_ok && $risk_ok; then
    pass "TC-03: design-reviewer.md covers scope, architecture, and risk"
  else
    fail "TC-03: design-reviewer.md missing: scope=$scope_ok, architecture=$arch_ok, risk=$risk_ok"
  fi
else
  fail "TC-03: design-reviewer.md not found"
fi

########################################
# Step 2: Risk Classifier
########################################

echo ""
echo "--- Step 2: Risk Classifier ---"

# TC-04: risk-classifier.sh exists and is executable
echo ""
echo "TC-04: risk-classifier.sh exists and is executable"
CLASSIFIER="$BASE_DIR/skills/review/risk-classifier.sh"
if [ -f "$CLASSIFIER" ] && [ -x "$CLASSIFIER" ]; then
  pass "TC-04: risk-classifier.sh exists and is executable"
else
  fail "TC-04: risk-classifier.sh not found or not executable"
fi

# TC-05: risk-classifier.sh returns LOW for non-risky files
echo ""
echo "TC-05: risk-classifier.sh LOW risk for non-risky files"
if [ -x "$CLASSIFIER" ]; then
  tmpdir=$(mktemp -d)
  echo "README.md" > "$tmpdir/files.txt"
  echo "docs/guide.md" >> "$tmpdir/files.txt"
  # Create minimal diff
  echo "+Added documentation line" > "$tmpdir/diff.txt"
  result=$(bash "$CLASSIFIER" "$tmpdir/files.txt" "$tmpdir/diff.txt" 2>/dev/null || true)
  rm -rf "$tmpdir"
  if echo "$result" | grep -qi "LOW"; then
    pass "TC-05: risk-classifier.sh returns LOW for docs-only changes"
  else
    fail "TC-05: risk-classifier.sh returned '$result' (expected: LOW)"
  fi
else
  fail "TC-05: risk-classifier.sh not executable, skipping"
fi

# TC-06: risk-classifier.sh returns HIGH for auth/security changes
echo ""
echo "TC-06: risk-classifier.sh HIGH risk for security changes"
if [ -x "$CLASSIFIER" ]; then
  tmpdir=$(mktemp -d)
  echo "app/auth/login.php" > "$tmpdir/files.txt"
  echo "app/middleware/AuthMiddleware.php" >> "$tmpdir/files.txt"
  echo "config/database.php" >> "$tmpdir/files.txt"
  echo "app/models/User.php" >> "$tmpdir/files.txt"
  echo "app/services/TokenService.php" >> "$tmpdir/files.txt"
  echo "app/controllers/ApiController.php" >> "$tmpdir/files.txt"
  # Create diff with security patterns
  cat > "$tmpdir/diff.txt" << 'DIFF'
+$query = DB::raw("SELECT * FROM users WHERE id = " . $id);
+$token = hash('sha256', $secret);
+password_hash($password, PASSWORD_DEFAULT);
+if (!Auth::check()) { abort(403); }
DIFF
  # Generate >200 lines
  for i in $(seq 1 210); do echo "+line $i" >> "$tmpdir/diff.txt"; done
  result=$(bash "$CLASSIFIER" "$tmpdir/files.txt" "$tmpdir/diff.txt" 2>/dev/null || true)
  rm -rf "$tmpdir"
  if echo "$result" | grep -qi "HIGH"; then
    pass "TC-06: risk-classifier.sh returns HIGH for security-heavy changes"
  else
    fail "TC-06: risk-classifier.sh returned '$result' (expected: HIGH)"
  fi
else
  fail "TC-06: risk-classifier.sh not executable, skipping"
fi

########################################
# Step 3: Unified Review Skill
########################################

echo ""
echo "--- Step 3: Unified Review Skill ---"

# TC-07: review/SKILL.md supports mode: plan and mode: code
echo ""
echo "TC-07: review/SKILL.md supports plan and code modes"
REVIEW_SKILL="$BASE_DIR/skills/review/SKILL.md"
if [ -f "$REVIEW_SKILL" ]; then
  plan_ok=false
  code_ok=false
  grep -q 'mode.*plan\|plan.*mode\|"plan"' "$REVIEW_SKILL" && plan_ok=true
  grep -q 'mode.*code\|code.*mode\|"code"' "$REVIEW_SKILL" && code_ok=true
  if $plan_ok && $code_ok; then
    pass "TC-07: review/SKILL.md supports both plan and code modes"
  else
    fail "TC-07: review/SKILL.md missing: plan=$plan_ok, code=$code_ok"
  fi
else
  fail "TC-07: review/SKILL.md not found"
fi

# TC-08: review/steps-subagent.md exists with Risk Classification + Brief + Specialist
echo ""
echo "TC-08: review/steps-subagent.md structure"
REVIEW_STEPS="$BASE_DIR/skills/review/steps-subagent.md"
if [ -f "$REVIEW_STEPS" ]; then
  risk_ok=false
  brief_ok=false
  specialist_ok=false
  grep -qi "risk.*classif\|risk-classifier\|リスク分類\|Risk Classification" "$REVIEW_STEPS" && risk_ok=true
  grep -qi "brief\|Review Brief" "$REVIEW_STEPS" && brief_ok=true
  grep -qi "specialist\|panel\|並行起動\|parallel" "$REVIEW_STEPS" && specialist_ok=true
  if $risk_ok && $brief_ok && $specialist_ok; then
    pass "TC-08: review/steps-subagent.md has Risk Classification, Brief, and Specialist panel"
  else
    fail "TC-08: review/steps-subagent.md missing: risk=$risk_ok, brief=$brief_ok, specialist=$specialist_ok"
  fi
else
  fail "TC-08: review/steps-subagent.md not found"
fi

# TC-09: review/SKILL.md references security-reviewer and correctness-reviewer as always-on
echo ""
echo "TC-09: review/SKILL.md always-on reviewers"
if [ -f "$REVIEW_SKILL" ]; then
  sec_ok=false
  cor_ok=false
  grep -qi "security-reviewer" "$REVIEW_SKILL" && sec_ok=true
  grep -qi "correctness-reviewer" "$REVIEW_SKILL" && cor_ok=true
  if $sec_ok && $cor_ok; then
    pass "TC-09: review/SKILL.md references security-reviewer and correctness-reviewer"
  else
    fail "TC-09: review/SKILL.md missing: security=$sec_ok, correctness=$cor_ok"
  fi
else
  fail "TC-09: review/SKILL.md not found"
fi

########################################
# Step 4: Orchestrate Flow Update
########################################

echo ""
echo "--- Step 4: Orchestrate Flow ---"

# TC-10: orchestrate/steps-subagent.md references review instead of plan-review/quality-gate
echo ""
echo "TC-10: orchestrate uses unified review"
ORCH_SUB="$BASE_DIR/skills/orchestrate/steps-subagent.md"
if [ -f "$ORCH_SUB" ]; then
  old_skill_ref=$(grep -cE 'dev-crew:plan-review|Skill\(.*plan-review' "$ORCH_SUB" 2>/dev/null || true)
  old_quality_gate=$(grep -c 'quality-gate' "$ORCH_SUB" 2>/dev/null || true)
  new_review=$(grep -c 'dev-crew:review' "$ORCH_SUB" 2>/dev/null || true)
  if [ "$old_skill_ref" -eq 0 ] && [ "$old_quality_gate" -eq 0 ] && [ "$new_review" -gt 0 ]; then
    pass "TC-10: orchestrate/steps-subagent.md uses unified review (no old skill refs)"
  else
    fail "TC-10: orchestrate still references old skill($old_skill_ref) or quality-gate($old_quality_gate), new review refs: $new_review"
  fi
else
  fail "TC-10: orchestrate/steps-subagent.md not found"
fi

# TC-11: orchestrate/steps-teams.md references review instead of plan-review/quality-gate
echo ""
echo "TC-11: orchestrate teams uses unified review"
ORCH_TEAMS="$BASE_DIR/skills/orchestrate/steps-teams.md"
if [ -f "$ORCH_TEAMS" ]; then
  old_skill_ref=$(grep -cE 'dev-crew:plan-review|Skill\(.*plan-review' "$ORCH_TEAMS" 2>/dev/null || true)
  old_quality_gate=$(grep -c 'quality-gate' "$ORCH_TEAMS" 2>/dev/null || true)
  new_review=$(grep -c 'dev-crew:review' "$ORCH_TEAMS" 2>/dev/null || true)
  if [ "$old_skill_ref" -eq 0 ] && [ "$old_quality_gate" -eq 0 ] && [ "$new_review" -gt 0 ]; then
    pass "TC-11: orchestrate/steps-teams.md uses unified review (no old skill refs)"
  else
    fail "TC-11: orchestrate teams still references old skill($old_skill_ref) or quality-gate($old_quality_gate), new review refs: $new_review"
  fi
else
  fail "TC-11: orchestrate/steps-teams.md not found"
fi

# TC-12: orchestrate/SKILL.md reflects new flow
echo ""
echo "TC-12: orchestrate/SKILL.md new flow"
ORCH_SKILL="$BASE_DIR/skills/orchestrate/SKILL.md"
if [ -f "$ORCH_SKILL" ]; then
  old_refs=$(grep -cE 'dev-crew:plan-review|Skill\(.*plan-review|quality-gate' "$ORCH_SKILL" 2>/dev/null || true)
  new_refs=$(grep -ci 'review' "$ORCH_SKILL" 2>/dev/null || true)
  if [ "$old_refs" -eq 0 ] && [ "$new_refs" -gt 0 ]; then
    pass "TC-12: orchestrate/SKILL.md uses unified review flow"
  else
    fail "TC-12: orchestrate/SKILL.md still has old skill refs($old_refs), review refs: $new_refs"
  fi
else
  fail "TC-12: orchestrate/SKILL.md not found"
fi

########################################
# Step 5: Retired Agents/Skills
########################################

echo ""
echo "--- Step 5: Retired Agents/Skills ---"

# TC-13: scope-reviewer.md does not exist
echo ""
echo "TC-13: scope-reviewer.md retired"
if [ ! -f "$BASE_DIR/agents/scope-reviewer.md" ]; then
  pass "TC-13: scope-reviewer.md retired (deleted)"
else
  fail "TC-13: scope-reviewer.md still exists"
fi

# TC-14: architecture-reviewer.md does not exist
echo ""
echo "TC-14: architecture-reviewer.md retired"
if [ ! -f "$BASE_DIR/agents/architecture-reviewer.md" ]; then
  pass "TC-14: architecture-reviewer.md retired (deleted)"
else
  fail "TC-14: architecture-reviewer.md still exists"
fi

# TC-15: risk-reviewer.md does not exist
echo ""
echo "TC-15: risk-reviewer.md retired"
if [ ! -f "$BASE_DIR/agents/risk-reviewer.md" ]; then
  pass "TC-15: risk-reviewer.md retired (deleted)"
else
  fail "TC-15: risk-reviewer.md still exists"
fi

# TC-16: guidelines-reviewer.md does not exist
echo ""
echo "TC-16: guidelines-reviewer.md retired"
if [ ! -f "$BASE_DIR/agents/guidelines-reviewer.md" ]; then
  pass "TC-16: guidelines-reviewer.md retired (deleted)"
else
  fail "TC-16: guidelines-reviewer.md still exists"
fi

# TC-17: skills/plan-review/ directory does not exist
echo ""
echo "TC-17: skills/plan-review/ retired"
if [ ! -d "$BASE_DIR/skills/plan-review" ]; then
  pass "TC-17: skills/plan-review/ retired (deleted)"
else
  fail "TC-17: skills/plan-review/ still exists"
fi

# TC-18: skills/quality-gate/ directory does not exist
echo ""
echo "TC-18: skills/quality-gate/ retired"
if [ ! -d "$BASE_DIR/skills/quality-gate" ]; then
  pass "TC-18: skills/quality-gate/ retired (deleted)"
else
  fail "TC-18: skills/quality-gate/ still exists"
fi

# TC-19: No stale references to retired agents in skills/
echo ""
echo "TC-19: No stale references to retired agents"
stale_hits=$(grep -rl 'scope-reviewer\|architecture-reviewer\|risk-reviewer\|guidelines-reviewer' "$BASE_DIR/skills/" --include='*.md' 2>/dev/null || true)
if [ -z "$stale_hits" ]; then
  pass "TC-19: No stale references to retired agents in skills/"
else
  fail "TC-19: Stale references found: $stale_hits"
fi

# TC-20: No stale references to plan-review/quality-gate skills
echo ""
echo "TC-20: No stale references to retired skills"
stale_hits=$(grep -rlE 'dev-crew:plan-review|Skill\(.*plan-review|quality-gate' "$BASE_DIR/skills/" --include='*.md' 2>/dev/null || true)
if [ -z "$stale_hits" ]; then
  pass "TC-20: No stale skill references to dev-crew:plan-review/quality-gate in skills/"
else
  fail "TC-20: Stale skill references found: $stale_hits"
fi

########################################
# Step 6: Discovered -> Issue
########################################

echo ""
echo "--- Step 6: Discovered -> Issue ---"

# TC-21: review/SKILL.md has DISCOVERED section
echo ""
echo "TC-21: review/SKILL.md DISCOVERED handling"
if [ -f "$REVIEW_SKILL" ]; then
  if grep -qi "DISCOVERED\|discovered" "$REVIEW_SKILL"; then
    pass "TC-21: review/SKILL.md has DISCOVERED handling"
  else
    fail "TC-21: review/SKILL.md missing DISCOVERED handling"
  fi
else
  fail "TC-21: review/SKILL.md not found"
fi

########################################
# Step 7: Strategy Skill
########################################

echo ""
echo "--- Step 7: Strategy Skill ---"

# TC-22: strategy/SKILL.md exists with required frontmatter
echo ""
echo "TC-22: strategy/SKILL.md exists"
STRATEGY="$BASE_DIR/skills/strategy/SKILL.md"
if [ -f "$STRATEGY" ]; then
  name_val=$(get_frontmatter "$STRATEGY" "name")
  desc_val=$(get_frontmatter "$STRATEGY" "description")
  if [ "$name_val" = "strategy" ] && [ -n "$desc_val" ]; then
    pass "TC-22: strategy/SKILL.md has correct frontmatter"
  else
    fail "TC-22: strategy/SKILL.md frontmatter incorrect (name='$name_val')"
  fi
else
  fail "TC-22: strategy/SKILL.md not found"
fi

# TC-23: strategy/SKILL.md under 100 lines
echo ""
echo "TC-23: strategy/SKILL.md line count"
if [ -f "$STRATEGY" ]; then
  line_count=$(wc -l < "$STRATEGY" | tr -d ' ')
  if [ "$line_count" -le 100 ]; then
    pass "TC-23: strategy/SKILL.md: $line_count lines (max 100)"
  else
    fail "TC-23: strategy/SKILL.md: $line_count lines (max 100)"
  fi
else
  fail "TC-23: strategy/SKILL.md not found"
fi

# TC-24: strategy/SKILL.md covers research + design + issue creation
echo ""
echo "TC-24: strategy/SKILL.md workflow"
if [ -f "$STRATEGY" ]; then
  research_ok=false
  design_ok=false
  issue_ok=false
  grep -qi "research\|リサーチ\|調査" "$STRATEGY" && research_ok=true
  grep -qi "design\|設計\|アーキテクチャ" "$STRATEGY" && design_ok=true
  grep -qi "issue\|チケット" "$STRATEGY" && issue_ok=true
  if $research_ok && $design_ok && $issue_ok; then
    pass "TC-24: strategy/SKILL.md covers research, design, and issue creation"
  else
    fail "TC-24: strategy missing: research=$research_ok, design=$design_ok, issue=$issue_ok"
  fi
else
  fail "TC-24: strategy/SKILL.md not found"
fi

########################################
# Step 8: Commit Skill Update
########################################

echo ""
echo "--- Step 8: Commit Skill ---"

# TC-25: commit/SKILL.md includes issue reference
echo ""
echo "TC-25: commit/SKILL.md issue reference"
COMMIT_SKILL="$BASE_DIR/skills/commit/SKILL.md"
if [ -f "$COMMIT_SKILL" ]; then
  if grep -qi "issue.*reference\|issue.*#\|Closes #\|Refs #\|issue 参照\|issue参照" "$COMMIT_SKILL"; then
    pass "TC-25: commit/SKILL.md includes issue reference"
  else
    fail "TC-25: commit/SKILL.md missing issue reference"
  fi
else
  fail "TC-25: commit/SKILL.md not found"
fi

########################################
# Step 9: Review Usability
########################################

echo ""
echo "--- Step 9: Review Usability ---"

# TC-27: SKILL.md Step 0 has explicit mode output instruction
echo ""
echo "TC-27: review/SKILL.md mode output instruction"
if [ -f "$REVIEW_SKILL" ]; then
  if grep -q '\[REVIEW\] Mode:' "$REVIEW_SKILL"; then
    pass "TC-27: review/SKILL.md Step 0 has explicit mode output instruction"
  else
    fail "TC-27: review/SKILL.md missing [REVIEW] Mode: output instruction"
  fi
else
  fail "TC-27: review/SKILL.md not found"
fi

# TC-28: SKILL.md Step 5 BLOCK row has mode-specific recovery
echo ""
echo "TC-28: review/SKILL.md mode-specific BLOCK recovery"
if [ -f "$REVIEW_SKILL" ]; then
  # Check that the BLOCK row itself contains mode-specific recovery paths
  block_line=$(grep 'BLOCK' "$REVIEW_SKILL" | grep '80-100' || true)
  if echo "$block_line" | grep -q 'plan' && echo "$block_line" | grep -q 'code'; then
    pass "TC-28: review/SKILL.md BLOCK row has plan and code recovery paths"
  else
    fail "TC-28: review/SKILL.md BLOCK row missing mode-specific recovery (got: '$block_line')"
  fi
else
  fail "TC-28: review/SKILL.md not found"
fi

# TC-29: steps-subagent.md has mode notification instruction
echo ""
echo "TC-29: review/steps-subagent.md mode notification"
if [ -f "$REVIEW_STEPS" ]; then
  if grep -q '\[REVIEW\] Mode:' "$REVIEW_STEPS"; then
    pass "TC-29: review/steps-subagent.md has mode notification instruction"
  else
    fail "TC-29: review/steps-subagent.md missing [REVIEW] Mode: notification"
  fi
else
  fail "TC-29: review/steps-subagent.md not found"
fi

# TC-30: reference.md has BLOCK Recovery section
echo ""
echo "TC-30: review/reference.md BLOCK Recovery section"
REVIEW_REF="$BASE_DIR/skills/review/reference.md"
if [ -f "$REVIEW_REF" ]; then
  if grep -qi 'BLOCK Recovery\|BLOCK 復帰' "$REVIEW_REF"; then
    pass "TC-30: review/reference.md has BLOCK Recovery section"
  else
    fail "TC-30: review/reference.md missing BLOCK Recovery section"
  fi
else
  fail "TC-30: review/reference.md not found"
fi

########################################
# Regression: SKILL.md line limits
########################################

echo ""
echo "--- Regression ---"

# TC-26: All SKILL.md files under 100 lines
echo ""
echo "TC-26: All SKILL.md under 100 lines"
over_limit=0
for skill_file in "$BASE_DIR"/skills/*/SKILL.md; do
  [ -f "$skill_file" ] || continue
  skill_name=$(basename "$(dirname "$skill_file")")
  line_count=$(wc -l < "$skill_file" | tr -d ' ')
  if [ "$line_count" -gt 100 ]; then
    fail "TC-26: $skill_name/SKILL.md has $line_count lines (max 100)"
    over_limit=$((over_limit + 1))
  fi
done
if [ "$over_limit" -eq 0 ]; then
  pass "TC-26: All SKILL.md under 100 lines"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
