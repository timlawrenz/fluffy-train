# Implementation Proposal: Persona-Driven Caption Generation

## Why

The content strategy engine (Milestone 4c) successfully selects and schedules Instagram posts intelligently, but **captions must still be written manually** for every post. This is time-consuming, inconsistent, and blocks full automation.

**Problem:** 
- Manual caption writing required for every scheduled post
- Tone/style inconsistency across posts
- Scaling bottleneck (Sarah needs 16-20 captions/month)
- No automated caption generation capability

**Solution:** 
Implement persona-driven caption generation that understands each account's voice and automatically generates Instagram-ready captions using existing AI infrastructure (Ollama + image_embed).

**Current State:**
- Content selection: ✅ Automated (Milestone 4c)
- Posting schedule: ✅ Optimized (Sarah: Wed-Fri 9am-12pm ET)
- Caption writing: ❌ Manual (this milestone fixes it)

## What Changes

This proposal adds a new `caption-generation` capability implementing:

1. **Persona Caption Configuration**
   - Tone, voice attributes, style preferences per persona
   - Topics to include/avoid
   - Example captions for learning
   - Database schema: `personas.caption_config` (jsonb)

2. **AI-Powered Generation Service**
   - `CaptionGenerations::Generator` service
   - Integration with existing OllamaClient (llava:latest model)
   - Image description context via image_embed
   - Cluster theme integration

3. **Quality Assurance Pipeline**
   - Repetition avoidance (checks last 20 captions)
   - Instagram compliance validation (2200 char limit)
   - Post-processing (emoji, formatting, line breaks)
   - Multiple variation generation with selection

4. **Content Strategy Integration**
   - Auto-generate captions when scheduling posts
   - Store caption metadata for tracking
   - Template fallback if AI unavailable
   - Manual review/edit capability

5. **Caption Metadata Tracking**
   - Generation method, model used, timestamp
   - Quality scores
   - Human edit patterns
   - Database schema: `scheduling_posts.caption_metadata` (jsonb)

## Impact

**Affected Specs:**
- ADDED: `caption-generation` (new capability)
- MODIFIED: `personas` (caption_config attribute)
- MODIFIED: `scheduling` (caption auto-generation)

## Architecture Overview

### Current System (Milestone 2 + 4c)

```
Photo Upload
     ↓
Photos::AnalysePhoto command chain
     ├── Sharpness, Exposure, Aesthetics
     ├── Object Detection  
     ├── Photos::Analyse::Caption ← EXISTING
     │   └── OllamaClient.generate_caption(file_path)
     │       └── Generic prompt: "Generate a short, engaging caption"
     └── Save to photo_analysis.caption
     
[Later: Content Strategy Selects Photo]
     ↓
ContentStrategy.generate_caption(photo, hashtags)
     ↓
caption = photo.photo_analysis.caption + hashtags
     ↓
Scheduling::Post.create!(caption: caption)
     ↓
Instagram API
```

### Enhanced System (Milestone 5a)

```
Photo Upload
     ↓
Photos::AnalysePhoto command chain
     ├── ... (unchanged)
     ├── Photos::Analyse::Caption ← KEEP (generic fallback)
     │   └── OllamaClient.generate_caption(file_path)
     └── Save to photo_analysis.caption
     
[Later: Content Strategy Selects Photo]
     ↓
ContentStrategy.generate_caption(photo, hashtags)
     ↓
Check: persona.caption_config present? ← NEW DECISION POINT
     │
     ├─ NO: Use photo_analysis.caption (existing) ← FALLBACK PATH
     │
     └─ YES: CaptionGenerations::Generator.generate() ← NEW PATH
              ├── Load persona.caption_config
              ├── Build context (cluster, recent captions)
              ├── PromptBuilder.build_persona_prompt()
              ├── OllamaClient.generate_caption_with_prompt() ← ENHANCED
              ├── PostProcessor.validate_and_format()
              └── Return (text, metadata)
     ↓
caption = generated_caption + hashtags
     ↓
Scheduling::Post.create!(
  caption: caption,
  caption_metadata: metadata ← NEW
)
     ↓
Instagram API
```

---

## Key Design Decisions

### 1. Backward Compatibility Strategy

**Decision**: Keep existing `Photos::Analyse::Caption` and add parallel persona-aware path.

**Rationale**:
- 58 existing captions work and shouldn't break
- Allows gradual rollout per-persona
- Generic captions still useful for personas without config
- Reduces risk of regression

**Implementation**:
```ruby
# In ContentStrategy.generate_caption()
def generate_caption(photo, hashtags)
  if persona.caption_config.present?
    # NEW: Persona-aware generation
    result = CaptionGenerations::Generator.generate(
      photo: photo,
      persona: persona,
      cluster: cluster
    )
    caption = result.text
    metadata = result.metadata
  else
    # EXISTING: Generic caption from photo analysis
    caption = photo.photo_analysis&.caption || ""
    metadata = { method: 'photo_analysis', model: 'llava:latest' }
  end
  
  # Combine with hashtags (unchanged)
  full_caption = caption.present? ? "#{caption}\n\n#{hashtags.join(' ')}" : hashtags.join(' ')
  
  { text: full_caption, metadata: metadata }
end
```

### 2. Persona Configuration Model

Store persona voice/style configuration in database:

```yaml
# persona.caption_config
tone: "casual"  # casual, professional, playful, inspirational, edgy
voice_attributes:
  - "witty"
  - "authentic"
  - "relatable"
style:
  use_emoji: true
  emoji_density: "moderate"  # none, sparse, moderate, heavy
  use_hashtags: false  # Handle in Milestone 5b
  avg_length: "medium"  # short (50-100), medium (100-150), long (150-200)
  use_questions: true
  use_calls_to_action: false
topics:
  - "lifestyle"
  - "creativity"
  - "daily moments"
avoid_topics:
  - "politics"
  - "controversial subjects"
example_captions:
  - "Just another Tuesday turning into magic ✨"
  - "Finding beauty in the ordinary moments"
  - "When life gives you lemons, photograph them 🍋"
```

### 3. Generation Timing Strategy

**Decision**: Generate captions at **scheduling time** (not photo analysis time) for persona-aware captions.

**Rationale**:
- Photo analysis time: Don't know which persona will use the photo (no context)
- Scheduling time: Know persona, cluster, recent captions (full context)
- Performance: Not time-critical at scheduling (can take 2-5 seconds)
- Flexibility: Can regenerate if persona config changes

**Implementation**:
```ruby
# Keep: Photos::Analyse::Caption (runs during photo upload)
# - Generates generic caption as fallback
# - Fast, no context needed

# New: CaptionGenerations::Generator (runs during scheduling)
# - Has full context: persona, cluster, recent posts
# - Can be persona-specific
# - Overrides generic caption if persona config exists
```

### 4. AI Provider Strategy

**Phase 1 (Current)**: Use Ollama (local, existing infrastructure)
- Model: `llava:latest` (already used successfully in Photos::Analyse::Caption)
- Existing: `OllamaClient.generate_caption(file_path:)` works
- Enhancement: Add `OllamaClient.generate_caption_with_prompt(file_path:, prompt:)`
- Pros: No API costs, privacy, proven to work (58 captions generated)
- Cons: Generic prompts, no persona awareness (this milestone fixes it)

**Phase 2 (Future)**: Support multiple providers (if needed)
- Ollama (local/free) - default
- OpenAI GPT-4 (high quality, paid) - if Ollama quality insufficient
- Anthropic Claude (high quality, paid) - alternative
- Google Gemini (free tier available) - another option

**Decision**: Start with enhanced Ollama, design for provider abstraction (but not implemented in MVP)

### 5. Prompt Enhancement Strategy

**Existing Prompt** (Photos::Analyse::Caption):
```ruby
# From OllamaClient.caption_generation_prompt
"Generate a short, engaging caption for this image, suitable for Instagram."
```
Simple, generic, works but no persona awareness.

**Enhanced Prompt** (CaptionGenerations::PromptBuilder):
```ruby
# Persona-aware prompt with context
"You are writing an Instagram caption for #{persona.name}.

VOICE & TONE:
- Tone: #{config.tone} (casual, upbeat)
- Voice attributes: #{config.voice_attributes.join(', ')} (witty, authentic, relatable)
- Topics: #{config.topics.join(', ')} (lifestyle, creativity, daily moments)

IMAGE CONTEXT:
- Theme: #{cluster.name} (Urban Exploration)
- Description: #{image_description} (city architecture, evening light)

RECENT CAPTIONS (avoid repeating these phrases):
#{recent_captions_sample}

STYLE GUIDELINES:
- Length: #{config.style[:avg_length]} (80-100 chars)
- Emoji: #{config.style[:emoji_density]} (1-2 moderate)
- Questions: #{config.style[:use_questions] ? 'encouraged' : 'avoid'}

Generate a caption that matches this persona's voice and fits the theme."
```

**Decision**: Build persona-aware prompts, fallback to generic if no config

### 6. Integration Point

Caption generation happens at **scheduling time** (when persona/cluster/context known):

```ruby
# Modified: ContentStrategy.generate_caption()
def generate_caption(photo, hashtags)
  if persona.caption_config.present?
    # NEW: Persona-aware generation
    result = CaptionGenerations::Generator.generate(
      photo: photo,
      persona: persona,
      cluster: cluster,
      options: { use_image_description: true, avoid_recent_phrases: true }
    )
    caption = result.text
    metadata = result.metadata
  else
    # EXISTING: Generic caption fallback
    caption = photo.photo_analysis&.caption || ""
    metadata = { method: 'photo_analysis', model: 'llava:latest' }
  end
  
  # Add hashtags (unchanged)
  full_caption = caption.present? ? "#{caption}\n\n#{hashtags.join(' ')}" : hashtags.join(' ')
  
  { text: full_caption, metadata: metadata }
end
```

---

## Implementation Plan

### Phase 1: Foundation & Configuration (Days 1-3)

**1.1 Database Schema**
- Migration: Add `caption_config` jsonb column to `personas` table
- Migration: Add `caption_metadata` jsonb column to `scheduling_posts` table
- No need to add `caption` column (already exists in both tables!)

**1.2 Persona Configuration Model**
- Create `Personas::CaptionConfig` ActiveModel
- Attributes: tone, voice_attributes, style, topics, avoid_topics, example_captions
- Validation for enums (tone, avg_length, emoji_density)
- Serialization methods (from_hash, to_hash)

**1.3 Configure Sarah's Voice**
- Analyze existing 58 captions to extract patterns
- Define Sarah's caption_config based on real data:
  - tone: 'casual'
  - voice_attributes: ['upbeat', 'lifestyle-focused', 'chic']
  - topics: ['fashion', 'lifestyle', 'beach', 'home', 'travel']
  - example_captions: [top 3-5 from existing data]

### Phase 2: Enhanced Generation Service (Days 4-7)

**2.1 OllamaClient Enhancement**
- Add `generate_caption_with_prompt(file_path:, prompt:)` method
- Keep existing `generate_caption(file_path:)` for backward compatibility
- Support custom system/user message structure

**2.2 Core Generator Service**
- Create `packs/caption_generations/` pack
- `CaptionGenerations::Generator` main service
- `CaptionGenerations::PromptBuilder` for persona-specific prompts
- `CaptionGenerations::ContextBuilder` for cluster/image context
- `CaptionGenerations::Result` value object (text, metadata)

**2.3 Context Building**
- Query recent captions (last 20 from scheduling_posts)
- Extract cluster theme from cluster.name
- Optional: Get image description from photo_analysis or image_embed
- Build persona-aware prompt

**2.4 Repetition Avoidance**
- `CaptionGenerations::RepetitionChecker` service
- Analyze recent captions for common 3+ word phrases
- Add "avoid these phrases" section to prompt

### Phase 3: Quality & Metadata (Days 8-10)

**3.1 Post-Processing Pipeline**
- `CaptionGenerations::PostProcessor` service
- Validate Instagram length (2200 chars max)
- Format line breaks for readability
- Adjust emoji based on persona style
- Remove prohibited content patterns

**3.2 Metadata Tracking**
- Store generation method ('persona_aware' vs 'photo_analysis')
- Store model used ('llava:latest')
- Store generation timestamp
- Store quality score (based on length, emoji, repetition check)
- Store persona config snapshot (for audit trail)

**3.3 Quality Scoring**
- Calculate score based on:
  - Length match to target (80-100 chars for Sarah)
  - Emoji count match (1-2 for Sarah)
  - No repetition of recent phrases
  - Instagram compliance

### Phase 4: Integration (Days 11-12)

**4.1 Content Strategy Integration**
- Modify `ContentStrategy.generate_caption()` method
- Add persona config check
- Route to persona-aware generator if config present
- Fallback to photo_analysis.caption if not
- Save caption_metadata to scheduling_posts

**4.2 Backward Compatibility**
- Ensure existing Photos::Analyse::Caption unchanged
- Ensure photo_analysis.caption still populated
- Ensure non-configured personas use generic captions
- Test that existing 58 captions still work

**4.3 Testing & Validation**
- Generate 20 test captions for Sarah with new system
- Compare quality to existing 58 captions
- Verify tone consistency
- Check repetition avoidance
- Validate metadata storage

### Phase 5: Rollout & Monitoring (Days 13-14)

**5.1 Gradual Rollout**
- Deploy to production with Sarah's caption_config
- Monitor first 10 captions generated
- Compare engagement vs baseline (future: Milestone 5d)
- Adjust persona config if needed

**5.2 Documentation**
- Document persona config format
- Document prompt engineering guidelines
- Document troubleshooting common issues
- Create admin guide for caption config

**Total Timeline**: 2 weeks (reduced from 3 weeks - leveraging existing infrastructure)

---

## Technical Specifications

### Database Migrations

```ruby
# Add caption_config to personas
add_column :personas, :caption_config, :jsonb, default: {}

# Add caption metadata to scheduling_posts
add_column :scheduling_posts, :caption_metadata, :jsonb, default: {}
add_index :scheduling_posts, :caption_metadata, using: :gin
```

### API Additions

**CaptionGenerations::Generator**
```ruby
result = CaptionGenerations::Generator.generate(
  photo: photo,
  persona: persona,
  cluster: cluster,
  options: {
    use_image_description: true,
    avoid_recent_phrases: true,
    max_length: 150
  }
)

result.text        # => "Just another Tuesday turning into magic ✨"
result.metadata    # => { model: "llava:latest", generated_at: ..., ... }
result.variations  # => [alt1, alt2, alt3] if requested
```

### Persona Configuration

```ruby
sarah = Persona.find_by(name: 'sarah')
sarah.caption_config = {
  tone: 'casual',
  voice_attributes: ['witty', 'authentic'],
  style: {
    use_emoji: true,
    emoji_density: 'moderate',
    avg_length: 'medium',
    use_questions: true
  },
  topics: ['lifestyle', 'creativity', 'daily moments'],
  example_captions: [...]
}
sarah.save!
```

---

## Success Criteria

### Functional Requirements
- [x] Generate captions for any photo in library
- [x] Match persona tone and style consistently
- [x] Use cluster themes for context
- [x] Avoid repetitive phrases across recent posts
- [x] Respect Instagram caption length limits
- [x] Integrate with content strategy engine

### Quality Requirements
- 90%+ of generated captions require no editing
- Captions maintain persona voice across 10+ consecutive posts
- No repetitive phrases in 20 consecutive captions
- Generated captions pass Instagram content guidelines

### Performance Requirements
- Caption generation completes in < 5 seconds
- Handles 50+ captions/day without degradation
- Graceful failure (fallback to template) if AI unavailable

---

## Risks & Mitigations

### Risk 1: Caption Quality Inconsistency
**Impact**: Medium  
**Mitigation**: 
- Extensive prompt engineering
- Multiple generation attempts with voting
- Human review for first 50 captions
- Track edit patterns, improve prompts

### Risk 2: AI Service Availability
**Impact**: High  
**Mitigation**:
- Implement fallback to template-based generation
- Queue caption generation (async)
- Retry logic with exponential backoff
- Cache working prompts

### Risk 3: Persona Voice Drift
**Impact**: Medium  
**Mitigation**:
- Validate generated captions against examples
- Track style metrics over time
- Allow manual voice recalibration
- Learn from human edits (future enhancement)

### Risk 4: Instagram Policy Violations
**Impact**: High  
**Mitigation**:
- Post-process to remove prohibited content
- Validate against Instagram guidelines
- Manual review queue for flagged captions
- Disable generation for sensitive topics

---

## Future Enhancements (Post-MVP)

### Phase 5: Advanced Features (Milestone 5b+)
- Automatic hashtag generation (Milestone 5b proper)
- Multi-language caption support
- Seasonal/event-aware captions
- Emoji recommendation engine

### Phase 6: Learning & Optimization (Milestone 5d)
- Track caption performance (engagement metrics)
- Learn from high-performing captions
- Auto-tune persona config based on data
- A/B test caption variations

### Phase 7: Multi-Provider Support
- OpenAI GPT-4 integration
- Anthropic Claude integration
- Google Gemini integration
- Cost/quality comparison dashboard

---

## Dependencies

### Existing Infrastructure (Leveraged)
✅ `Photos::Analyse::Caption` - Generic caption generation (Milestone 2)  
✅ `OllamaClient.generate_caption()` - AI integration with llava:latest  
✅ `photo_analyses.caption` - Base caption storage  
✅ `scheduling_posts.caption` - Final caption storage  
✅ `ContentStrategy.generate_caption()` - Caption assembly (base + hashtags)  
✅ Persona model  
✅ Scheduling::Post model  
✅ Content Strategy Engine  
✅ 58 existing captions as training examples

### New Infrastructure (Building)
- `Personas::CaptionConfig` - Voice configuration model
- `CaptionGenerations::Generator` - Persona-aware generator
- `CaptionGenerations::PromptBuilder` - Persona prompt synthesis
- `CaptionGenerations::PostProcessor` - Quality control
- `CaptionGenerations::RepetitionChecker` - Avoid duplicates

### External Dependencies
- None! Uses existing Ollama/image_embed infrastructure

---

## Acceptance Criteria

### User Stories

**As a content manager**, I want to:
- Configure Sarah's caption voice once
- Have captions generated automatically when scheduling posts
- Review and edit generated captions before posting
- See caption quality improve over time

**As the system**, I want to:
- Generate contextually appropriate captions
- Maintain consistent persona voice
- Avoid repetitive phrases
- Handle generation failures gracefully

### Testing Scenarios

**Scenario 1: Generate caption for photo in "Urban Exploration" cluster**
```
Given: Photo of city architecture
  And: Sarah's persona (casual, witty)
  And: Cluster "Urban Exploration"
When: Caption generation is triggered
Then: Caption should be 100-150 characters
  And: Should match casual tone
  And: Should reference architecture/city theme
  And: Should include 1-2 emoji
  And: Should not repeat phrases from last 10 captions
```

**Scenario 2: Fallback when AI service unavailable**
```
Given: OllamaClient connection fails
When: Caption generation is triggered
Then: System should use template fallback
  And: Caption should still match persona tone
  And: Error should be logged
  And: Manual review should be flagged
```

**Scenario 3: Multiple caption variations**
```
Given: Photo in "Nature" cluster
When: Caption generation with variations requested
Then: System should generate 3 variations
  And: All should match persona voice
  And: Each should be unique (< 30% phrase overlap)
  And: One should be selected as primary
```

---

## Documentation Needs

- [ ] Persona caption configuration guide
- [ ] Caption generation API documentation
- [ ] Prompt engineering guidelines
- [ ] Troubleshooting guide
- [ ] Admin interface screenshots

---

## Rollout Plan

### Week 1: Development
- Day 1-2: Database schema, persona config model
- Day 3-4: Basic generator service, Ollama integration
- Day 5: Image description integration

### Week 2: Polish & Integration
- Day 1-2: Post-processing, quality checks
- Day 3: Strategy engine integration
- Day 4: Admin interface
- Day 5: Testing & bug fixes

### Week 3: Validation & Launch
- Generate 50 test captions, review quality
- Fix prompt issues, tune persona configs
- Deploy to production with feature flag
- Monitor first week of auto-generated captions

---

## Open Questions

1. **Should we store multiple caption variations or just the selected one?**
   - Recommendation: Store selected + metadata about alternatives
   
2. **How many recent captions should we check for repetition?**
   - Recommendation: Last 20 captions or 30 days, whichever is less

3. **Should caption generation be synchronous or async?**
   - Recommendation: Synchronous for now (< 5s), move to async if needed

4. **Do we need a manual approval queue before posting?**
   - Recommendation: Yes for first month, then optional per persona

---

## Related Documents

- Milestone 4c: Content Strategy Engine (completed)
- Milestone 5b: Automated Hashtag Generation (next)
- Milestone 5c: Full Automation & Integration (future)
- Sarah Optimization Plan: `docs/research/content-strategy-engine/sarah-optimization-plan.md`

---

**Status**: Ready for Review  
**Next Steps**: Validate proposal, approve, create tasks.md
