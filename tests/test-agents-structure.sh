#!/bin/bash
# test-agents-structure.sh - dev-crew agent definition validation
# TC-06, TC-07, TC-13: frontmatter validation (existing)
# TC-21~TC-35: model field validation, legacy concept detection (existing)
# TC-36~TC-46: tools: frontmatter scoping (agent-tools-scoping cycle; RED addendum 2:
#   bare-key presence via has_frontmatter_key, TC-41 name-set diff, TC-43 fence scoping,
#   TC-44/45 word-boundary tools token, TC-46 memory 維持 + disallowedTools 再定義)

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

# Presence check for a frontmatter key regardless of value/space formatting.
# get_frontmatter requires "key: " (with trailing space) and returns empty for a
# bare "key:" line (no value), which made absence-contract TCs vacuously pass
# against a bare key (RED addendum 2, REVIEW BLOCK finding: TC-36/39/46 false-pass).
has_frontmatter_key() {
  local file="$1"
  local key="$2"
  local hits
  hits=$(awk '/^---$/{n++; next} n==1{print}' "$file" | grep -c "^${key}:" || true)
  [ "$hits" -ge 1 ]
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

# TC-35: No legacy Lead/SendMessage concepts in agent definitions
echo ""
echo "TC-35: No legacy Lead/SendMessage concepts"
legacy_count=0
for agent_file in "$BASE_DIR"/agents/*.md; do
  [ -f "$agent_file" ] || continue
  basename_file=$(basename "$agent_file")

  # Skip reference files
  if [[ "$basename_file" == *-reference* ]]; then
    continue
  fi

  # Check for legacy "Lead" references (as a role/entity, not general English word)
  if grep -qiE '(Leadに報告|Lead に報告|結果をLeadに|結果を Lead に|SendMessage)' "$agent_file"; then
    fail "TC-35: $basename_file contains legacy Lead/SendMessage concept"
    legacy_count=$((legacy_count + 1))
  fi
done

if [ "$legacy_count" -eq 0 ]; then
  pass "TC-35: No agent definitions contain legacy Lead/SendMessage concepts"
fi

# --- agent-tools-scoping (#194): TC-36~TC-45 ---
# Group definitions (explicit arrays, pinned per Cycle doc Files to Change B)
g1_agents=(
  api-contract-reviewer change-safety-reviewer correctness-reviewer design-reviewer impact-reviewer
  maintainability-reviewer observability-reviewer performance-reviewer product-reviewer resiliency-reviewer
  security-reviewer test-reviewer usability-reviewer
  socrates review-briefer observer
  api-attacker auth-attacker crypto-attacker csrf-attacker error-attacker file-attacker injection-attacker
  ssrf-attacker ssti-attacker wordpress-attacker xss-attacker xxe-attacker
  false-positive-filter
)
g23_names=(attack-scenario sca-attacker recon-agent dynamic-verifier)
g23_expected=("Read" "Read, Grep, Glob, Bash" "Bash, Read, Grep, Glob" "Bash, Read")
deferred_agents=(designer architect sync-plan red-worker green-worker refactorer dast-crawler)

# TC-36: [Given] non-reference agents 40 files / [When] frontmatter has bare-or-valued 'allowed-tools:' key / [Then] 0 hits (renamed to 'tools:')
# Presence判定は has_frontmatter_key（^key: 行存在）で行う。get_frontmatter の "key: "（要空白）依存だと
# 裸キー（値なし 'allowed-tools:' 単独行）を不在扱いにして false-pass する（REVIEW BLOCK 実証）。
echo ""
echo "TC-36: No agent has 'allowed-tools:' frontmatter (renamed to 'tools:')"
allowed_tools_count=0
for agent_file in "$BASE_DIR"/agents/*.md; do
  [ -f "$agent_file" ] || continue
  basename_file=$(basename "$agent_file")
  if [[ "$basename_file" == *-reference* ]]; then
    continue
  fi
  if has_frontmatter_key "$agent_file" "allowed-tools"; then
    fail "TC-36: $basename_file still has 'allowed-tools:' frontmatter (expected: renamed to 'tools:')"
    allowed_tools_count=$((allowed_tools_count + 1))
  fi
done
if [ "$allowed_tools_count" -eq 0 ]; then
  pass "TC-36: No agent has 'allowed-tools:' frontmatter"
fi

# TC-37: [Given] G1 29 agents / [When] get_frontmatter tools / [Then] exact match 'Read, Grep, Glob'
echo ""
echo "TC-37: G1 (reviewer/review補助/static attacker/filter) 29 agents 'tools:' = 'Read, Grep, Glob'"
g1_mismatch=0
for name in "${g1_agents[@]}"; do
  agent_file="$BASE_DIR/agents/${name}.md"
  if [ ! -f "$agent_file" ]; then
    fail "TC-37: ${name}.md not found"
    g1_mismatch=$((g1_mismatch + 1))
    continue
  fi
  tools_val=$(get_frontmatter "$agent_file" "tools")
  if [ "$tools_val" != "Read, Grep, Glob" ]; then
    fail "TC-37: ${name}.md 'tools:' is '$tools_val' (expected: 'Read, Grep, Glob')"
    g1_mismatch=$((g1_mismatch + 1))
  fi
done
if [ "$g1_mismatch" -eq 0 ]; then
  pass "TC-37: All G1 29 agents have 'tools: Read, Grep, Glob'"
fi

# TC-38: [Given] G2/G3 4 agents / [When] get_frontmatter tools / [Then] exact match per-file value
echo ""
echo "TC-38: G2/G3 4 agents 'tools:' exact match"
g23_mismatch=0
idx=0
while [ "$idx" -lt "${#g23_names[@]}" ]; do
  name="${g23_names[$idx]}"
  expected="${g23_expected[$idx]}"
  agent_file="$BASE_DIR/agents/${name}.md"
  if [ ! -f "$agent_file" ]; then
    fail "TC-38: ${name}.md not found"
    g23_mismatch=$((g23_mismatch + 1))
    idx=$((idx + 1))
    continue
  fi
  tools_val=$(get_frontmatter "$agent_file" "tools")
  if [ "$tools_val" != "$expected" ]; then
    fail "TC-38: ${name}.md 'tools:' is '$tools_val' (expected: '$expected')"
    g23_mismatch=$((g23_mismatch + 1))
  fi
  idx=$((idx + 1))
done
if [ "$g23_mismatch" -eq 0 ]; then
  pass "TC-38: All G2/G3 4 agents have exact-match 'tools:' values"
fi

# TC-39: [Given] deferred 7 agents (full inheritance) / [When] tools:/allowed-tools: presence (bare-key 対応) / [Then] neither key present
echo ""
echo "TC-39: Deferred 7 agents have neither 'tools:' nor 'allowed-tools:'"
deferred_violation=0
for name in "${deferred_agents[@]}"; do
  agent_file="$BASE_DIR/agents/${name}.md"
  if [ ! -f "$agent_file" ]; then
    fail "TC-39: ${name}.md not found"
    deferred_violation=$((deferred_violation + 1))
    continue
  fi
  if has_frontmatter_key "$agent_file" "tools" || has_frontmatter_key "$agent_file" "allowed-tools"; then
    fail "TC-39: ${name}.md has 'tools:' or 'allowed-tools:' (expected: neither, full inheritance)"
    deferred_violation=$((deferred_violation + 1))
  fi
done
if [ "$deferred_violation" -eq 0 ]; then
  pass "TC-39: All 7 deferred agents have neither 'tools:' nor 'allowed-tools:'"
fi

# TC-40: [Given] all 'tools:' values / [When] token-split (comma, trimmed) / [Then] every token in {Read, Grep, Glob, Bash}
# Protective contract: 33 agent の実データ（GREEN 済みの tools: 値）を検証する。RED 期（addendum 前）は
# 群ロースターに tools: がまだ実装されておらず空集合の vacuous PASS だったが、現在は非空集合を検証する。
echo ""
echo "TC-40: All 'tools:' values contain only canonical tokens {Read, Grep, Glob, Bash}"
canonical_violation=0
for agent_file in "$BASE_DIR"/agents/*.md; do
  [ -f "$agent_file" ] || continue
  basename_file=$(basename "$agent_file")
  if [[ "$basename_file" == *-reference* ]]; then
    continue
  fi
  tools_val=$(get_frontmatter "$agent_file" "tools")
  [ -z "$tools_val" ] && continue
  IFS=',' read -ra tokens <<< "$tools_val"
  for token in "${tokens[@]}"; do
    trimmed=$(echo "$token" | sed 's/^ *//; s/ *$//')
    case "$trimmed" in
      Read|Grep|Glob|Bash) ;;
      *)
        fail "TC-40: $basename_file 'tools:' contains non-canonical token '$trimmed'"
        canonical_violation=$((canonical_violation + 1))
        ;;
    esac
  done
done
if [ "$canonical_violation" -eq 0 ]; then
  pass "TC-40: All 'tools:' values contain only canonical tokens"
fi

# TC-41: [Given] declared name set (G1 29 + G2/G3 4 + deferred 7 = 40) / [When] diff'd against actual agents/*.md
#         basenames (excluding *-reference* and the test-hooks-structure.sh fixture 'test-drift-agent') / [Then] no diff
# Protective contract: count-only comparison (previous impl) misses duplicate+missing pairs that cancel out to
# the same total, and flaked under parallel test runs against the live-tree fixture agents/test-drift-agent.md
# (REVIEW BLOCK finding, reproduced). Name-set diff catches both failure modes and excludes the known fixture.
echo ""
echo "TC-41: Declared group roster (name set) matches actual non-reference agent files (name set)"
tc41_declared=$(printf '%s\n' "${g1_agents[@]}" "${g23_names[@]}" "${deferred_agents[@]}" | sort)
tc41_actual=$(ls "$BASE_DIR"/agents/*.md 2>/dev/null | xargs -n1 basename | sed 's/\.md$//' | grep -v -- '-reference' | grep -vx 'test-drift-agent' | sort)
tc41_diff=$(diff <(printf '%s\n' "$tc41_declared") <(printf '%s\n' "$tc41_actual") || true)
if [ -z "$tc41_diff" ]; then
  pass "TC-41: Declared roster (40) exactly matches actual non-reference agent file names"
else
  fail "TC-41: Declared roster vs actual agent files diff:
$tc41_diff"
fi

# TC-42: [Given] dast-crawler.md body / [When] grep -cF old/new Playwright tool names / [Then] old=0 each, new>=1 each
echo ""
echo "TC-42: dast-crawler.md body — old Playwright tool names removed, new tool names present"
dast_file="$BASE_DIR/agents/dast-crawler.md"
if [ ! -f "$dast_file" ]; then
  fail "TC-42: dast-crawler.md not found"
else
  dast_body_file=$(mktemp)
  awk '/^---$/{n++; next} n>=2{print}' "$dast_file" > "$dast_body_file"
  old_names=(mcp__playwright__navigate mcp__playwright__click mcp__playwright__screenshot mcp__playwright__evaluate)
  new_names=(mcp__playwright__browser_navigate mcp__playwright__browser_click mcp__playwright__browser_take_screenshot mcp__playwright__browser_evaluate)
  tc42_violation=0
  for old in "${old_names[@]}"; do
    old_count=$(grep -cF "$old" "$dast_body_file" || true)
    if [ "$old_count" -ne 0 ]; then
      fail "TC-42: dast-crawler.md body still contains old tool name '$old' ($old_count occurrences)"
      tc42_violation=$((tc42_violation + 1))
    fi
  done
  for new in "${new_names[@]}"; do
    new_count=$(grep -cF "$new" "$dast_body_file" || true)
    if [ "$new_count" -lt 1 ]; then
      fail "TC-42: dast-crawler.md body missing new tool name '$new'"
      tc42_violation=$((tc42_violation + 1))
    fi
  done
  rm -f "$dast_body_file"
  if [ "$tc42_violation" -eq 0 ]; then
    pass "TC-42: dast-crawler.md body has new Playwright tool names, no old names"
  fi
fi

# TC-43: [Given] evolve/reference.md agent-gen heading section (先行抽出、fence 対応) / [When] fence内の行のみを走査 / [Then] 'model:' と 'tools:' を含む
# Section 抽出は fence 内の decoy 見出し（テンプレ内 '## Input' 等）を実見出しと誤認しないよう infence フラグで
# 判定を止める（REVIEW BLOCK 実証: fence 非対応の区間抽出は '## Input' で早期終了しうる）。
# さらに model:/tools: の走査自体も fence 内限定にし、fence 外の decoy 行を拾わない（addendum 2 item 3）。
echo ""
echo "TC-43: evolve/reference.md agent-gen template has 'model:' and 'tools:' in code block"
evolve_ref="$BASE_DIR/skills/evolve/reference.md"
if [ ! -f "$evolve_ref" ]; then
  fail "TC-43: skills/evolve/reference.md not found"
else
  evolve_heading="### エージェント生成 (agent.md)"
  evolve_section=$(awk -v h="$evolve_heading" '
    $0 == h { found=1; next }
    found && !infence && /^```/ { infence=1; print; next }
    found && infence && /^```/ { infence=0; print; next }
    found && !infence && /^## / { exit }
    found && !infence && /^### / { exit }
    found { print }
  ' "$evolve_ref")
  evolve_fence_body=$(awk '
    /^```/ { infence = !infence; next }
    infence { print }
  ' <<< "$evolve_section")
  model_count=$(grep -cE '^model:' <<< "$evolve_fence_body" || true)
  tools_count=$(grep -cE '^tools:' <<< "$evolve_fence_body" || true)
  if [ "$model_count" -ge 1 ] && [ "$tools_count" -ge 1 ]; then
    pass "TC-43: evolve/reference.md agent-gen template contains 'model:' and 'tools:'"
  else
    fail "TC-43: evolve/reference.md agent-gen template missing 'model:' (count=$model_count) or 'tools:' (count=$tools_count)"
  fi
fi

# TC-44: [Given] AGENTS.md / [When] '| Agents |' 行 / [Then] 'tools' トークンを語境界で含む（'allowed-tools' 等の
#         '-tools' 部分文字列だけでは PASS しない）
# [[ == *tools* ]] は部分文字列一致のため 'allowed-tools' 単独でも PASS してしまう（REVIEW/Codex 実証）。
# 語境界判定に切り替える: 行頭または '-' 以外の文字の直後に続く 'tools' のみを一致とみなす。
echo ""
echo "TC-44: AGENTS.md '| Agents |' row mentions 'tools' (word-boundary, excludes bare 'allowed-tools')"
agents_md_file="$BASE_DIR/AGENTS.md"
if [ ! -f "$agents_md_file" ]; then
  fail "TC-44: AGENTS.md not found"
else
  agents_row=$(grep '^| Agents |' "$agents_md_file" || true)
  if [ -n "$agents_row" ] && grep -qE '(^|[^-])tools' <<< "$agents_row"; then
    pass "TC-44: AGENTS.md '| Agents |' row contains 'tools'"
  else
    fail "TC-44: AGENTS.md '| Agents |' row missing 'tools' (row: '$agents_row')"
  fi
fi

# TC-45: [Given] CHANGELOG.md '## [2.16.0]' 見出し区間 (先行抽出、次の '## ' まで) / [When] 区間内の行 /
#         [Then] 'allowed-tools' を含む行が1行以上 かつ '-tools' 以外の 'tools' トークンを含む行が1行以上
#         （同一行である必要はない。旧キーのみの行が存在しても、独立した 'tools' トークン行がなければ FAIL）
#         アンカーは immutable な確定 version セクションへ pin（rules/test-patterns.md:
#         「逆向き契約に相対アンカーを使わない」— v2.16.0 release が CHANGELOG の
#         '## [Unreleased]' を '## [2.16.0]' へ改名したことで相対アンカーが空区間を掴んだ再発防止）
echo ""
echo "TC-45: CHANGELOG.md '## [2.16.0]' section mentions 'allowed-tools' and a word-boundary 'tools' token"
changelog_file="$BASE_DIR/CHANGELOG.md"
if [ ! -f "$changelog_file" ]; then
  fail "TC-45: CHANGELOG.md not found"
else
  unreleased_section=$(awk '
    /^## \[2\.16\.0\]/ { found=1; next }
    found && /^## / { exit }
    found { print }
  ' "$changelog_file")
  tc45_allowed_tools_lines=0
  tc45_tools_token_lines=0
  if [ -n "$unreleased_section" ]; then
    while IFS= read -r line; do
      if [[ "$line" == *allowed-tools* ]]; then
        tc45_allowed_tools_lines=$((tc45_allowed_tools_lines + 1))
      fi
      if grep -qE '(^|[^-])tools' <<< "$line"; then
        tc45_tools_token_lines=$((tc45_tools_token_lines + 1))
      fi
    done <<< "$unreleased_section"
  fi
  if [ "$tc45_allowed_tools_lines" -ge 1 ] && [ "$tc45_tools_token_lines" -ge 1 ]; then
    pass "TC-45: CHANGELOG.md Unreleased section mentions 'allowed-tools' and a word-boundary 'tools' token"
  else
    fail "TC-45: CHANGELOG.md Unreleased section missing 'allowed-tools' line (count=$tc45_allowed_tools_lines) or word-boundary 'tools' token line (count=$tc45_tools_token_lines)"
  fi
fi

# TC-46: [Given] memory 保持 15 agent (PROBE D step 4 再々承認: memory + tools 併用は書込不可でも既存 memory の
#         起動時読取は可能と実測されたため、'memory 削除' を撤回し 'memory 維持 + disallowedTools' へ再定義) /
#         [When] frontmatter の memory:/disallowedTools: を検証 / [Then] memory: が 'project' に完全一致し、
#         disallowedTools: が 'Write, Edit' に完全一致。加えて不変条件: tools: を持つ 33 agent (G1+G2/G3) の
#         うち memory: を持つものは必ず disallowedTools: を持つ（memory 併用時の Write 越権対策、PROBE D 実測）
echo ""
echo "TC-46: memory 保持 15 agent は 'memory: project' + 'disallowedTools: Write, Edit'（+ 不変条件）"
memory_agents=(
  api-contract-reviewer change-safety-reviewer correctness-reviewer impact-reviewer
  maintainability-reviewer observability-reviewer performance-reviewer resiliency-reviewer
  security-reviewer test-reviewer socrates false-positive-filter
  attack-scenario recon-agent dynamic-verifier
)
tc46_violation=0
for name in "${memory_agents[@]}"; do
  agent_file="$BASE_DIR/agents/${name}.md"
  if [ ! -f "$agent_file" ]; then
    fail "TC-46: ${name}.md not found"
    tc46_violation=$((tc46_violation + 1))
    continue
  fi
  memory_val=$(get_frontmatter "$agent_file" "memory")
  if [ "$memory_val" != "project" ]; then
    fail "TC-46: ${name}.md 'memory:' is '$memory_val' (expected: 'project')"
    tc46_violation=$((tc46_violation + 1))
  fi
  disallowed_val=$(get_frontmatter "$agent_file" "disallowedTools")
  if [ "$disallowed_val" != "Write, Edit" ]; then
    fail "TC-46: ${name}.md 'disallowedTools:' is '$disallowed_val' (expected: 'Write, Edit')"
    tc46_violation=$((tc46_violation + 1))
  fi
done
# Invariant: any tools:-scoped agent (G1+G2/G3, 33 total) that has 'memory:' must also have 'disallowedTools:'.
for name in "${g1_agents[@]}" "${g23_names[@]}"; do
  agent_file="$BASE_DIR/agents/${name}.md"
  [ -f "$agent_file" ] || continue
  if has_frontmatter_key "$agent_file" "memory" && ! has_frontmatter_key "$agent_file" "disallowedTools"; then
    fail "TC-46: ${name}.md has 'memory:' without 'disallowedTools:' (invariant violation)"
    tc46_violation=$((tc46_violation + 1))
  fi
done
if [ "$tc46_violation" -eq 0 ]; then
  pass "TC-46: All 15 memory-retaining agents have 'memory: project' + 'disallowedTools: Write, Edit'; invariant holds across all 33 tools:-scoped agents"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
