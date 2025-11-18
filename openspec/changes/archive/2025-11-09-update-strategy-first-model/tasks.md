# Tasks: Strategy-First Model Documentation Update

**Change ID**: `update-strategy-first-model`  
**Status**: Proposal  
**Created**: 2025-11-09

---

## Phase 1: Update Clustering Spec (1 hour)

### Reposition as Legacy/Optional

- [ ] Update Purpose section to clarify clustering is now optional
- [ ] Add note: "Manual cluster creation is the primary workflow"
- [ ] Document legacy K-means service for organizing existing photo batches

### Add Manual Cluster Creation

- [ ] Add requirement: Manual cluster creation with persona ownership
- [ ] Add requirement: AI-suggested cluster creation
- [ ] Add scenario: Create cluster manually with ai_prompt field
- [ ] Add scenario: Create cluster from AI suggestion

### Update Existing Requirements

- [ ] Mark auto-clustering requirements as "Legacy/Optional"
- [ ] Keep persona-scoped requirements (still valid)
- [ ] Keep cluster-photo consistency requirements (still valid)
- [ ] Update lifecycle management for manual clusters

---

## Phase 2: Update Content Pillars Spec (1 hour)

### Add AI Integration

- [ ] Add requirement: Gap analysis identifies missing content
- [ ] Add requirement: AI prompt generation for gaps
- [ ] Add requirement: Cluster suggestion workflow
- [ ] Add scenario: Analyze gap and request AI suggestions
- [ ] Add scenario: Create clusters from AI prompts
- [ ] Add scenario: Track which clusters are AI-generated

### Update Gap Analyzer

- [ ] Document existing GapAnalyzer service
- [ ] Add scenarios for gap calculation
- [ ] Add scenarios for priority determination
- [ ] Document integration with AI prompt generator

---

## Phase 3: Update Content Strategy Spec (30 minutes)

### Shift to Strategy-First Model

- [ ] Update Purpose: Strategy identifies gaps, recommends creation
- [ ] Add requirement: Evaluate pillar coverage
- [ ] Add requirement: Identify content gaps
- [ ] Add requirement: Recommend content creation
- [ ] Add scenario: Strategy detects gap and suggests AI prompt generation
- [ ] Add scenario: Strategy prefers gap-filling over rotation

### Keep Selection Logic

- [ ] Keep existing photo selection requirements (still needed)
- [ ] Update to note selection happens AFTER gap analysis
- [ ] Document fallback when no gaps exist

---

## Phase 4: Create AI Content Generation Spec (1 hour)

### New Spec File

- [ ] Create `openspec/changes/update-strategy-first-model/specs/ai-content-generation/`
- [ ] Create `spec.md` with ADDED requirements

### Core Requirements

- [ ] Requirement: Gemini API integration
  - [ ] Scenario: Generate prompt with Gemini 2.5 Pro
  - [ ] Scenario: Handle API errors gracefully
  - [ ] Scenario: Respect rate limits

- [ ] Requirement: Persona-aware prompt engineering
  - [ ] Scenario: Include persona aesthetic in prompt
  - [ ] Scenario: Include persona voice attributes
  - [ ] Scenario: Include demographics (age, location)

- [ ] Requirement: Pillar-aligned prompts
  - [ ] Scenario: Generate prompts matching pillar theme
  - [ ] Scenario: Include pillar guidelines (tone, topics)
  - [ ] Scenario: Respect pillar avoid_topics

- [ ] Requirement: Structured prompt output
  - [ ] Scenario: Parse full prompt
  - [ ] Scenario: Extract scene description
  - [ ] Scenario: Extract outfit details
  - [ ] Scenario: Extract mood/vibe

- [ ] Requirement: Cluster creation integration
  - [ ] Scenario: Create cluster with ai_prompt field
  - [ ] Scenario: Link cluster to pillar
  - [ ] Scenario: Save prompt to markdown file

---

## Phase 5: Validation & Polish (30 minutes)

### Validation

- [ ] Run `openspec validate update-strategy-first-model --strict`
- [ ] Fix any formatting issues
- [ ] Ensure all scenarios use proper format (#### Scenario:)
- [ ] Ensure all requirements use SHALL/MUST

### Documentation

- [ ] Update `openspec/project.md` if needed
- [ ] Ensure examples reference current workflow
- [ ] Cross-reference with existing docs

### Final Check

- [ ] All delta operations (ADDED/MODIFIED) have at least one scenario
- [ ] All requirements use normative language
- [ ] No orphaned requirements
- [ ] Consistent terminology throughout

---

## Summary

**Total Estimated Time**: 2-3 hours

- Phase 1: Clustering spec (1 hour)
- Phase 2: Content pillars spec (1 hour)
- Phase 3: Content strategy spec (30 minutes)
- Phase 4: AI content generation spec (1 hour)
- Phase 5: Validation (30 minutes)

**Total Tasks**: 50+ documentation updates  
**Critical Path**: Phases 1-4 (spec creation)  
**Essential**: Phase 5 (validation)
