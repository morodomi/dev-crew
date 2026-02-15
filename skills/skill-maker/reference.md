# Skill Maker - Reference

SKILL.mdの詳細情報。Anthropic公式「The Complete Guide to Building Skills for Claude」に基づく。

---

## Description Guide

descriptionはスキルの発火判定に使われる最重要フィールド。

### Structure

```
[WHAT: 何をするか] + [WHEN: いつ使うか] + [Key capabilities]
```

### Requirements

- WHAT（機能説明）とWHEN（トリガー条件）の両方を含めること
- 1024文字以内
- XMLタグ（< >）禁止
- 具体的なtrigger phrasesを含める

### Negative Triggers

過剰発火を防ぐため、否定条件も記述する:

```yaml
description: Advanced data analysis for CSV files. Use for
  statistical modeling, regression. Do NOT use for simple
  data exploration (use data-viz skill instead).
```

### Good Examples

```yaml
# Good - specific and actionable
description: Analyzes design files and generates developer
  handoff documentation. Use when user asks for "design specs",
  "component documentation", or "design-to-code handoff".

# Good - includes trigger phrases
description: Manages project workflows including sprint planning
  and task creation. Use when user mentions "sprint", "tasks",
  or asks to "create tickets".
```

### Bad Examples

```yaml
# Bad - too vague
description: Helps with projects.

# Bad - missing triggers (no WHEN)
description: Creates sophisticated multi-page documentation.

# Bad - too technical, no user triggers
description: Implements the Project entity model with
  hierarchical relationships.
```

---

## 5 Skill Patterns

### Pattern 1: Sequential Workflow Orchestration

Use when: Multi-step processes in a specific order.

```markdown
### Step 1: Create Account
Call MCP tool: `create_customer`

### Step 2: Setup Payment
Call MCP tool: `setup_payment_method`
Wait for: payment method verification

### Step 3: Create Subscription
Call MCP tool: `create_subscription`
Parameters: plan_id, customer_id (from Step 1)
```

Key techniques: explicit ordering, dependencies, validation at each stage, rollback instructions.

### Pattern 2: Multi-MCP Coordination

Use when: Workflows span multiple services.

```markdown
### Phase 1: Design Export (Figma MCP)
1. Export design assets
2. Generate specifications

### Phase 2: Asset Storage (Drive MCP)
1. Upload all assets
2. Generate shareable links

### Phase 3: Task Creation (Linear MCP)
1. Create development tasks
2. Attach asset links
```

Key techniques: clear phase separation, data passing between MCPs, validation before next phase.

### Pattern 3: Iterative Refinement

Use when: Output quality improves with iteration.

```markdown
### Initial Draft
1. Fetch data, generate first draft

### Quality Check
1. Run validation script
2. Identify issues

### Refinement Loop
1. Address each issue
2. Re-validate
3. Repeat until quality threshold met
```

Key techniques: explicit quality criteria, validation scripts, know when to stop.

### Pattern 4: Context-Aware Tool Selection

Use when: Same outcome, different tools depending on context.

```markdown
### Decision Tree
1. Check file type and size
2. Determine best storage:
   - Large files (>10MB): cloud storage MCP
   - Collaborative docs: Notion/Docs MCP
   - Code files: GitHub MCP
```

Key techniques: clear decision criteria, fallback options, transparency about choices.

### Pattern 5: Domain-Specific Intelligence

Use when: Skill adds specialized knowledge beyond tool access.

```markdown
### Before Processing (Compliance Check)
1. Fetch transaction details
2. Apply compliance rules
3. Document compliance decision

### Processing
IF compliance passed: process transaction
ELSE: flag for review
```

Key techniques: domain expertise in logic, compliance before action, audit trail.

---

## Testing Guide (3 Areas)

### 1. Triggering Tests

Goal: Ensure skill loads at the right times.

```
Should trigger:
- "Help me set up a new workspace"
- "I need to create a project"
- "Initialize for Q4 planning"

Should NOT trigger:
- "What's the weather?"
- "Help me write Python code"
```

Test 10-20 queries. Target: 90% trigger rate on relevant queries.

### 2. Functional Tests

Goal: Verify correct outputs.

```
Test: Create project with 5 tasks
Given: Project name "Q4 Planning", 5 descriptions
When: Skill executes workflow
Then:
  - Project created
  - 5 tasks with correct properties
  - No API errors
```

### 3. Performance Comparison

Goal: Prove skill improves results vs baseline.

```
Without skill:
- 15 back-and-forth messages
- 3 failed API calls
- 12,000 tokens consumed

With skill:
- 2 clarifying questions only
- 0 failed API calls
- 6,000 tokens consumed
```

---

## Troubleshooting

### Skill Doesn't Trigger (Under-triggering)

Symptom: Skill never loads automatically.

Solutions:
- Add more trigger phrases to description
- Include paraphrased versions of key terms
- Add domain-specific keywords

Debug: Ask Claude "When would you use the [skill name] skill?"

### Skill Triggers Too Often (Over-triggering)

Symptom: Skill loads for unrelated queries.

Solutions:
1. Add negative triggers: "Do NOT use for..."
2. Be more specific in description
3. Clarify scope boundaries

### Instructions Not Followed

Symptom: Skill loads but Claude doesn't follow instructions.

Common causes and solutions:
1. Instructions too verbose -> use bullet points, move details to references/
2. Instructions buried -> put critical instructions at top, use ## Important headers
3. Ambiguous language -> use specific, actionable commands

### Large Context Issues

Symptom: Skill seems slow or responses degraded.

Solutions:
1. Keep SKILL.md under 100 lines (dev-crew rule)
2. Move detailed docs to reference.md (Progressive Disclosure)
3. Reduce number of simultaneously enabled skills

---

## Allowed-Tools Guide

The `allowed-tools` frontmatter field restricts which tools a skill can use.

### Format

```yaml
allowed-tools: "Bash(python:*) Bash(npm:*) WebFetch"
```

### Common Patterns

| Skill Type | Recommended allowed-tools |
|-----------|--------------------------|
| Read-only analysis | "Read Glob Grep" |
| Code generation | "Read Glob Grep Write Edit Bash" |
| Web research | "WebFetch WebSearch Read" |
| MCP workflow | "mcp__server-name__*" |

### When to Use

- Security: restrict skills that handle sensitive data
- Clarity: make skill's capabilities explicit
- Safety: prevent unintended side effects

---

## Security Constraints

### Forbidden in Frontmatter

1. **XML angle brackets** (< >) - frontmatter appears in system prompt; malicious content could inject instructions
2. **Reserved names** - skills with "claude" or "anthropic" in name are reserved by Anthropic
3. **Code execution in YAML** - safe YAML parsing prevents code execution

### Frontmatter Validation Rules

- name: kebab-case only, no spaces, no capitals
- description: under 1024 characters
- No XML tags anywhere in frontmatter
- YAML delimiters (---) required

---

## Validation Checklist

### Before Development

- [ ] Identified 2-3 concrete use cases
- [ ] Tools identified (built-in or MCP)
- [ ] Planned folder structure

### During Development

- [ ] Folder named in kebab-case
- [ ] SKILL.md file exists (exact spelling, case-sensitive)
- [ ] YAML frontmatter has --- delimiters
- [ ] name field: kebab-case, no spaces, no capitals
- [ ] description includes WHAT and WHEN
- [ ] No XML tags anywhere
- [ ] Instructions are clear and actionable
- [ ] Error handling included
- [ ] Examples provided
- [ ] References clearly linked
- [ ] SKILL.md under 100 lines (dev-crew rule)

### Before Upload / Distribution

- [ ] Tested triggering on obvious tasks
- [ ] Tested triggering on paraphrased requests
- [ ] Verified doesn't trigger on unrelated topics
- [ ] Functional tests pass
- [ ] Tool integration works (if applicable)

### After Upload

- [ ] Test in real conversations
- [ ] Monitor for under/over-triggering
- [ ] Collect user feedback
- [ ] Iterate on description and instructions

---

## Skill Body Writing Guide

### Recommended Structure

```markdown
---
name: your-skill
description: [WHAT + WHEN + triggers]
---

# Your Skill Name

## Progress Checklist
(trackable checkboxes)

## Instructions

### Step 1: [First Major Step]
Clear explanation with examples.

### Step 2: [Next Step]
...

## Examples
Input/output pairs demonstrating usage.

## Troubleshooting
Common errors and solutions.
```

### Progressive Disclosure

- **SKILL.md**: Core workflow only (< 100 lines)
- **reference.md**: Detailed guidance, examples, edge cases
- Link from SKILL.md to reference.md sections

### Tips

- Be specific and actionable (not "validate data" but "Run `scripts/validate.py --input {file}`")
- Include error handling for common failures
- Use AskUserQuestion for user input, not assumptions
