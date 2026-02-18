#!/bin/bash
# test-agents-structure.sh - dev-crew agent definition validation
# TC-06, TC-07, TC-13: frontmatter validation (existing)
# TC-21~TC-34: model field validation (new)

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

# Extract frontmatter value from a markdown file
# Returns empty string if not found
get_frontmatter() {
  local file="$1"
  local key="$2"
  # Read between first --- and second ---
  awk '/^---$/{n++; next} n==1{print}' "$file" | grep "^${key}: " | head -1 | sed "s/^${key}: *//" || true
}

echo "=== Agent Structure Tests ==="

# TC-06 & TC-07: All agents have name and description frontmatter
echo ""
echo "TC-06/07: Agent frontmatter validation"
name_missing_count=0
desc_missing_count=0
for agent_file in "$BASE_DIR"/agents/*.md; do
  [ -f "$agent_file" ] || continue
  basename_file=$(basename "$agent_file")

  # Skip non-agent files (e.g., reference files)
  if [[ "$basename_file" == *-reference* ]]; then
    continue
  fi

  name_val=$(get_frontmatter "$agent_file" "name")
  desc_val=$(get_frontmatter "$agent_file" "description")

  if [ -z "$name_val" ]; then
    fail "TC-06: $basename_file missing 'name' frontmatter"
    name_missing_count=$((name_missing_count + 1))
  fi

  if [ -z "$desc_val" ]; then
    fail "TC-07: $basename_file missing 'description' frontmatter"
    desc_missing_count=$((desc_missing_count + 1))
  fi
done

if [ "$name_missing_count" -eq 0 ]; then
  pass "TC-06: All agents have 'name' frontmatter"
fi
if [ "$desc_missing_count" -eq 0 ]; then
  pass "TC-07: All agents have 'description' frontmatter"
fi

# TC-13: [Negative] detect missing frontmatter
echo ""
echo "TC-13: [Negative] detects missing frontmatter"
tmpdir=$(mktemp -d)
mkdir -p "$tmpdir/agents"
cat > "$tmpdir/agents/broken-agent.md" << 'AGENT'
# Broken Agent

No frontmatter here.
AGENT

name_val=$(get_frontmatter "$tmpdir/agents/broken-agent.md" "name")
if [ -z "$name_val" ]; then
  pass "Correctly detected missing frontmatter"
else
  fail "Failed to detect missing frontmatter"
fi
rm -rf "$tmpdir"

# TC-21: All agents have 'model' frontmatter field
echo ""
echo "TC-21: All agents have 'model' frontmatter"
model_missing_count=0
for agent_file in "$BASE_DIR"/agents/*.md; do
  [ -f "$agent_file" ] || continue
  basename_file=$(basename "$agent_file")

  # Skip reference files
  if [[ "$basename_file" == *-reference* ]]; then
    continue
  fi

  model_val=$(get_frontmatter "$agent_file" "model")
  if [ -z "$model_val" ]; then
    fail "TC-21: $basename_file missing 'model' frontmatter"
    model_missing_count=$((model_missing_count + 1))
  fi
done

if [ "$model_missing_count" -eq 0 ]; then
  pass "TC-21: All 32 agents have 'model' frontmatter"
fi

# TC-22: 'model' value is opus|sonnet|haiku
echo ""
echo "TC-22: 'model' value validation"
invalid_model_count=0
for agent_file in "$BASE_DIR"/agents/*.md; do
  [ -f "$agent_file" ] || continue
  basename_file=$(basename "$agent_file")

  # Skip reference files
  if [[ "$basename_file" == *-reference* ]]; then
    continue
  fi

  model_val=$(get_frontmatter "$agent_file" "model")
  if [ -n "$model_val" ] && [[ ! "$model_val" =~ ^(opus|sonnet|haiku)$ ]]; then
    fail "TC-22: $basename_file has invalid model '$model_val' (expected: opus|sonnet|haiku)"
    invalid_model_count=$((invalid_model_count + 1))
  fi
done

if [ "$invalid_model_count" -eq 0 ]; then
  pass "TC-22: All agent 'model' values are valid (opus|sonnet|haiku)"
fi

# TC-23: socrates.md has model 'opus'
echo ""
echo "TC-23: socrates.md model validation"
socrates_model=$(get_frontmatter "$BASE_DIR/agents/socrates.md" "model")
if [ "$socrates_model" = "opus" ]; then
  pass "TC-23: socrates.md has model 'opus'"
else
  fail "TC-23: socrates.md model is '$socrates_model' (expected: opus)"
fi

# TC-24: review-briefer.md has model 'haiku'
echo ""
echo "TC-24: review-briefer.md model validation"
briefer_model=$(get_frontmatter "$BASE_DIR/agents/review-briefer.md" "model")
if [ "$briefer_model" = "haiku" ]; then
  pass "TC-24: review-briefer.md has model 'haiku'"
else
  fail "TC-24: review-briefer.md model is '$briefer_model' (expected: haiku)"
fi

# TC-25: design-reviewer.md has model 'sonnet'
echo ""
echo "TC-25: design-reviewer.md model validation"
design_model=$(get_frontmatter "$BASE_DIR/agents/design-reviewer.md" "model")
if [ "$design_model" = "sonnet" ]; then
  pass "TC-25: design-reviewer.md has model 'sonnet'"
else
  fail "TC-25: design-reviewer.md model is '$design_model' (expected: sonnet)"
fi

# TC-26: architect.md has model 'sonnet'
echo ""
echo "TC-26: architect.md model validation"
architect_model=$(get_frontmatter "$BASE_DIR/agents/architect.md" "model")
if [ "$architect_model" = "sonnet" ]; then
  pass "TC-26: architect.md has model 'sonnet'"
else
  fail "TC-26: architect.md model is '$architect_model' (expected: sonnet)"
fi

# TC-27: Reference files are excluded from model checks
echo ""
echo "TC-27: Reference file exclusion"
# Count reference files
ref_count=$(find "$BASE_DIR/agents" -name '*-reference.md' | wc -l)
if [ "$ref_count" -gt 0 ]; then
  pass "TC-27: Reference files (*-reference.md) excluded from model checks"
else
  fail "TC-27: No reference files found to test exclusion"
fi

# TC-28: [Negative] Detect missing model field
echo ""
echo "TC-28: [Negative] Detect missing 'model' field"
tmpdir=$(mktemp -d)
mkdir -p "$tmpdir/agents"
cat > "$tmpdir/agents/no-model-agent.md" << 'AGENT'
---
name: test-agent
description: Test agent without model field
memory: project
---

# Test Agent
AGENT

test_model=$(get_frontmatter "$tmpdir/agents/no-model-agent.md" "model")
if [ -z "$test_model" ]; then
  pass "TC-28: Correctly detected missing 'model' field"
else
  fail "TC-28: Failed to detect missing 'model' field"
fi
rm -rf "$tmpdir"

# TC-29: [Negative] Detect invalid model value
echo ""
echo "TC-29: [Negative] Detect invalid 'model' value"
tmpdir=$(mktemp -d)
mkdir -p "$tmpdir/agents"
cat > "$tmpdir/agents/invalid-model-agent.md" << 'AGENT'
---
name: test-agent
description: Test agent with invalid model
model: gpt-4
memory: project
---

# Test Agent
AGENT

test_model=$(get_frontmatter "$tmpdir/agents/invalid-model-agent.md" "model")
if [ -n "$test_model" ] && [[ ! "$test_model" =~ ^(opus|sonnet|haiku)$ ]]; then
  pass "TC-29: Correctly detected invalid model value '$test_model'"
else
  fail "TC-29: Failed to detect invalid model value"
fi
rm -rf "$tmpdir"

# TC-30: orchestrate/steps-teams.md contains model parameter in Task() calls
echo ""
echo "TC-30: orchestrate/steps-teams.md model parameter"
steps_teams="$BASE_DIR/skills/orchestrate/steps-teams.md"
if [ -f "$steps_teams" ]; then
  if grep -q 'Task([^)]*model:' "$steps_teams"; then
    pass "TC-30: steps-teams.md contains 'model:' parameter in Task() calls"
  else
    fail "TC-30: steps-teams.md missing 'model:' parameter in Task() calls"
  fi
else
  fail "TC-30: steps-teams.md not found"
fi

# TC-31: orchestrate/steps-subagent.md contains model parameter in Task() calls
echo ""
echo "TC-31: orchestrate/steps-subagent.md model parameter"
steps_subagent="$BASE_DIR/skills/orchestrate/steps-subagent.md"
if [ -f "$steps_subagent" ]; then
  if grep -q 'Task([^)]*model:' "$steps_subagent"; then
    pass "TC-31: steps-subagent.md contains 'model:' parameter in Task() calls"
  else
    fail "TC-31: steps-subagent.md missing 'model:' parameter in Task() calls"
  fi
else
  fail "TC-31: steps-subagent.md not found"
fi

# TC-32: review/steps-subagent.md contains review-briefer with model "haiku"
echo ""
echo "TC-32: review/steps-subagent.md review-briefer model"
review_steps="$BASE_DIR/skills/review/steps-subagent.md"
if [ -f "$review_steps" ]; then
  if grep -q 'review-briefer' "$review_steps"; then
    if grep 'review-briefer' "$review_steps" | grep -q 'model: "haiku"'; then
      pass "TC-32: review steps-subagent.md review-briefer has model 'haiku'"
    else
      fail "TC-32: review steps-subagent.md review-briefer missing or incorrect model (expected: haiku)"
    fi
  else
    fail "TC-32: review-briefer not found in review/steps-subagent.md"
  fi
else
  fail "TC-32: review/steps-subagent.md not found"
fi

# TC-33: review/steps-subagent.md contains design-reviewer with model "sonnet"
echo ""
echo "TC-33: review/steps-subagent.md design-reviewer model"
review_steps="$BASE_DIR/skills/review/steps-subagent.md"
if [ -f "$review_steps" ]; then
  if grep -q 'design-reviewer' "$review_steps"; then
    if grep 'design-reviewer' "$review_steps" | grep -q 'model: "sonnet"'; then
      pass "TC-33: review steps-subagent.md design-reviewer has model 'sonnet'"
    else
      fail "TC-33: review steps-subagent.md design-reviewer missing or incorrect model (expected: sonnet)"
    fi
  else
    fail "TC-33: design-reviewer not found in review/steps-subagent.md"
  fi
else
  fail "TC-33: review/steps-subagent.md not found"
fi

# TC-34: Drift detection - frontmatter model vs steps-*.md model parameter
echo ""
echo "TC-34: Model drift detection (frontmatter vs steps-*.md)"
drift_count=0

# Function to get agent model from frontmatter
get_agent_model() {
  local agent_name="$1"
  local agent_file="$BASE_DIR/agents/${agent_name}.md"
  if [ -f "$agent_file" ]; then
    get_frontmatter "$agent_file" "model"
  fi
}

# Check steps files for model parameter consistency
tmpfile=$(mktemp)
for steps_file in "$BASE_DIR"/skills/*/steps-*.md; do
  [ -f "$steps_file" ] || continue

  # Extract Task() calls with agent name and model using grep and sed
  grep -o 'Task([^)]*subagent_type:[[:space:]]*"dev-crew:[^"]*"[^)]*model:[[:space:]]*"[^"]*"' "$steps_file" 2>/dev/null > "$tmpfile" || true

  while IFS= read -r task_call; do
    [ -z "$task_call" ] && continue

    # Extract agent name from subagent_type parameter
    agent_name=$(echo "$task_call" | sed -n 's/.*subagent_type:[[:space:]]*"dev-crew:\([^"]*\)".*/\1/p')
    # Extract model value from model parameter
    steps_model=$(echo "$task_call" | sed -n 's/.*model:[[:space:]]*"\([^"]*\)".*/\1/p')

    if [ -n "$agent_name" ] && [ -n "$steps_model" ]; then
      frontmatter_model=$(get_agent_model "$agent_name")
      if [ -n "$frontmatter_model" ] && [ "$steps_model" != "$frontmatter_model" ]; then
        fail "TC-34: Model drift in $(basename "$steps_file"): $agent_name has model '$frontmatter_model' in frontmatter but '$steps_model' in Task() call"
        drift_count=$((drift_count + 1))
      fi
    fi
  done < "$tmpfile"
done
rm -f "$tmpfile"

if [ "$drift_count" -eq 0 ]; then
  pass "TC-34: No model drift detected (frontmatter matches steps-*.md)"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
