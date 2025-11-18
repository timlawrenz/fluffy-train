# Documentation Update: Strategy-First Content Model

## Why

**Current Reality:** fluffy-train has evolved from a photo-first clustering system to a strategy-first content planning system, but the specs don't reflect this architectural shift.

**The Evolution:**

**Phase 1 (Original - Photo-First):**
```
Large Photo Set → DBSCAN/K-means Clustering → Organize into Clusters → Post
```
- Problem: Arbitrary groupings based on visual similarity
- No strategic coherence
- Reactive content management

**Phase 2 (Current - Strategy-First):**
```
Content Pillars → Gap Analysis → AI Recommendations → Create Content → Manual Curation → Post
```
- Strategic themes define what content is needed
- AI generates specific prompts for missing content
- Clusters are deliberately created, not auto-generated
- Proactive content planning

**What's Implemented (but not documented):**
- ✅ `ContentPillars::GapAnalyzer` - identifies content gaps by pillar
- ✅ `AI::ContentPromptGenerator` - generates detailed image prompts for gaps
- ✅ `AI::GeminiClient` - interfaces with Gemini 2.5 Pro
- ✅ TUI "AI Content Suggestions" view - end-to-end gap → prompt → cluster workflow
- ✅ Clusters auto-created from AI suggestions with `ai_prompt` field
- ✅ Many-to-many pillar ↔ cluster relationships
- ✅ Full documentation in `docs/ai-content-suggestions.md`

**What's Legacy (but still in specs as primary):**
- `Clustering::ClusteringService` - K-means clustering for existing photo batches
- Photo-first workflow descriptions
- Cluster specs focused on auto-generation

**The Gap:**
Current specs describe clustering as the primary workflow, when it's actually a legacy/optional tool. The real workflow is strategy-first with AI-driven gap filling.

## What Changes

This proposal updates existing specs to accurately document the current architecture:

### 1. Update `clustering` Spec

**Changes:**
- Reposition clustering as **optional legacy tool** for organizing existing photo batches
- Document **manual cluster creation** as primary method
- Add `ai_prompt` field documentation
- Clarify clusters are now strategic, not automatic

**New Requirements:**
- Manual cluster creation with persona ownership
- AI-suggested cluster creation workflow
- Optional K-means clustering for legacy photo organization

### 2. Update `content-pillars` Spec

**Changes:**
- Emphasize gap analysis as core capability
- Document AI recommendation integration
- Clarify strategy-first workflow

**New Requirements:**
- Gap analysis identifies missing content by pillar
- AI prompt generation for content gaps
- Cluster suggestion workflow

### 3. Update `content-strategy` Spec

**Changes:**
- Shift from "select from existing photos" to "identify gaps and recommend creation"
- Document AI integration points
- Clarify proactive vs reactive strategy

**New Requirements:**
- Strategy evaluates pillar coverage
- Identifies content gaps requiring creation
- Integrates with AI prompt generation

### 4. Add New `ai-content-generation` Spec

**New Capability:**
- AI prompt generation using Gemini 2.5 Pro
- Persona-aware prompt engineering
- Pillar-aligned content suggestions
- Cluster creation from AI prompts

## Impact

**Affected Specs:**
- MODIFIED: `clustering` (reposition as legacy/optional)
- MODIFIED: `content-pillars` (add AI recommendations)
- MODIFIED: `content-strategy` (strategy-first model)
- ADDED: `ai-content-generation` (new capability spec)

**Affected Code:**
- None - this is documentation-only update
- All implementation already exists

**Benefits:**
- Specs accurately reflect current architecture
- Clear distinction between legacy and modern workflows
- New contributors understand the strategy-first model
- Prevents confusion about clustering's role

**Non-Breaking:**
- Documentation-only change
- No code modifications
- Legacy clustering service remains available

## Timeline

**Estimated Duration:** 2-3 hours

**Phase 1: Spec Updates (1-2 hours)**
- Update `clustering/spec.md` with legacy positioning
- Update `content-pillars/spec.md` with AI integration
- Update `content-strategy/spec.md` with strategy-first model

**Phase 2: New Spec (1 hour)**
- Create `ai-content-generation/spec.md`
- Document Gemini integration
- Document prompt generation workflow

**Phase 3: Validation (30 minutes)**
- Run `openspec validate --strict`
- Ensure all scenarios have proper format
- Verify delta operations correct

## Success Metrics

**Accuracy:**
- ✅ Specs describe implemented functionality
- ✅ Legacy clustering clearly marked as optional
- ✅ Strategy-first workflow documented as primary

**Clarity:**
- ✅ New contributors understand current architecture
- ✅ Clear examples of modern workflow
- ✅ Proper positioning of all capabilities

**Completeness:**
- ✅ All implemented features have spec coverage
- ✅ AI integration fully documented
- ✅ Gap analysis workflow clear

## References

- `docs/ai-content-suggestions.md` - Implementation guide
- `docs/content-pillars-clusters-guide.md` - Current best practices
- `lib/ai/content_prompt_generator.rb` - AI prompt generation
- `packs/content_pillars/app/services/content_pillars/gap_analyzer.rb` - Gap analysis
- `lib/tui/views/ai_prompts_view.rb` - TUI workflow
