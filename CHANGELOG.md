# Changelog

## [1.0.0] - 2026-03-03

Initial public release. 33 agents, 29 skills, 3 rules, hook-based automation.

### Phase 7: Factory Model Adaptation

- Ambiguity Detection (Questioning Protocol) in init skill
- RED phase 3-stage split: Test Plan, Test Plan Review, Test Code
- 14 validation tests for factory model

### Phase 6: Next Evolution

- CLAUDE.md staleness detection hook
- Onboard template simplification
- Risk Classifier tuning (LOW threshold)
- On-Demand Capabilities research (OSS survey, E2E benchmark)

### Phase 5.5: Orchestrator Redesign

- Plan mode-driven workflow unification
- refactor skill with /simplify delegation
- Phase-compact + /compact natural context compression

### Phase 5: v2 Restructuring

- Unified review skill (quality-gate + plan-review merged)
- Risk Classifier: deterministic reviewer scaling (LOW/WARN/BLOCK)
- review-briefer (haiku) for input token compression
- design-reviewer: integrated design review (scope + architecture + risk)
- strategy skill for project planning phase

### Phase 4: Optimization

- Model selection hints in agent frontmatter
- Hook-based tool output filtering (git log, git diff)
- SKILL.md slim-down + Progressive Disclosure to reference.md

### Phase 3: Designer Agent

- designer.md with Japanese/Western UI/UX comparison
- Integrated into review skill (plan mode)

### Phase 2: phase-compact

- Phase-boundary context compaction skill
- Cycle doc persistence for cross-phase context
- Orchestrate skill integration

### Phase 1.5: Test Infrastructure

- test-plugin-structure.sh, test-agents-structure.sh, test-skills-structure.sh
- SKILL.md size enforcement (< 100 lines)

### Phase 1: Migration

- Consolidated tdd-core, tdd-*, redteam-core, meta-skills into single plugin
- Flat structure: agents/, skills/, rules/, hooks/
- Single plugin.json (marketplace.json removed)
