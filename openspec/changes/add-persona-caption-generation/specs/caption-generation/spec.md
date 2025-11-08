# Caption Generation Capability

**Change**: add-persona-caption-generation  
**Status**: ADDED

---

## ADDED Requirements

### Requirement: Caption Generation

The system SHALL generate Instagram captions that match each persona's configured voice, style, and tone.

#### Scenario: Generate caption for photo with cluster theme context

- **GIVEN** a photo in the "Urban Exploration" cluster
- **AND** Sarah's persona configured with casual tone
- **AND** Sarah's voice attributes include "witty" and "authentic"
- **WHEN** the caption generation is triggered
- **THEN** a caption is generated between 100-150 characters
- **AND** the caption matches Sarah's casual tone
- **AND** the caption references the urban/architecture theme
- **AND** the caption includes 1-2 emoji based on style config
- **AND** the caption does not repeat phrases from last 10 captions

#### Scenario: Generate caption without image description

- **GIVEN** a photo without an available image description
- **AND** the photo's cluster is "Nature"
- **WHEN** caption generation is triggered
- **THEN** the caption is generated using only cluster theme
- **AND** the caption quality is acceptable (no degradation)
- **AND** the caption includes nature-related context

#### Scenario: Generate multiple caption variations

- **GIVEN** a photo in any cluster
- **AND** generation is requested with variations: 3
- **WHEN** caption generation is triggered
- **THEN** 3 distinct captions are generated
- **AND** all captions match the persona voice
- **AND** captions have < 30% phrase overlap with each other
- **AND** one caption is marked as primary selection

---

### Requirement: Persona Configuration Storage

The system SHALL store and manage caption generation configuration per persona.

#### Scenario: Configure persona voice and style

- **GIVEN** Sarah's persona exists
- **WHEN** I set caption_config with tone: casual, voice_attributes: witty and authentic, use_emoji: true, emoji_density: moderate, avg_length: medium, topics: lifestyle and creativity
- **AND** I save the persona
- **THEN** the caption_config is stored in the database
- **AND** subsequent caption generations use this config

#### Scenario: Validate persona configuration

- **GIVEN** an invalid caption_config with tone: invalid_tone and avg_length: not_a_size
- **WHEN** I attempt to save the persona
- **THEN** validation fails
- **AND** an error message explains: "tone must be one of: casual, professional, playful, inspirational, edgy"
- **AND** an error message explains: "avg_length must be one of: short, medium, long"

---

### Requirement: Repetition Avoidance

The system SHALL detect and avoid repetitive phrases when generating captions.

#### Scenario: Detect and avoid recent common phrases

- **GIVEN** Sarah's last 5 captions contain the phrase "just another day"
- **WHEN** a new caption is generated
- **THEN** the new caption does not include "just another day"
- **AND** the new caption maintains persona voice
- **AND** generation time is not significantly increased (< 1 second overhead)

#### Scenario: Allow repeated themes with varied wording

- **GIVEN** Sarah's last 3 posts were from "Coffee Culture" cluster
- **AND** captions used themes: "morning coffee", "caffeine fix", "daily brew"
- **WHEN** a new caption is generated for another "Coffee Culture" photo
- **THEN** the caption references coffee theme
- **AND** uses different wording than previous 3 captions
- **AND** the caption is still thematically appropriate

---

### Requirement: Instagram Compliance Validation

The system SHALL ensure generated captions comply with Instagram guidelines and technical limits.

#### Scenario: Enforce caption length limit

- **GIVEN** a generated caption is 2500 characters long
- **WHEN** post-processing is applied
- **THEN** the caption is truncated to 2200 characters maximum
- **AND** truncation occurs at a natural break point (sentence/word boundary)
- **AND** the truncated caption remains coherent

#### Scenario: Remove prohibited content patterns

- **GIVEN** a generated caption contains a prohibited pattern: "click link in bio"
- **WHEN** validation is applied
- **THEN** the prohibited phrase is removed or rephrased
- **AND** the caption remains coherent without the phrase
- **AND** a warning is logged about the content violation

---

### Requirement: Scheduling Integration

The system SHALL automatically generate captions when creating scheduled posts.

#### Scenario: Generate caption during post scheduling

- **GIVEN** the content strategy selects a photo to schedule
- **AND** the photo belongs to Sarah's persona
- **AND** caption generation is enabled for Sarah
- **WHEN** the scheduling post is created
- **THEN** a caption is automatically generated
- **AND** the caption is stored with the scheduled post
- **AND** caption_metadata records the generation method and timestamp
- **AND** scheduling completes successfully

#### Scenario: Handle caption generation failure gracefully

- **GIVEN** the content strategy selects a photo to schedule
- **AND** the Ollama service is unavailable
- **WHEN** caption generation is attempted
- **THEN** the system falls back to template generation
- **AND** a default caption is created using the cluster theme
- **AND** the post is still scheduled successfully
- **AND** an error is logged for monitoring
- **AND** caption_metadata marks this as a fallback caption

---

### Requirement: Manual Review Support

The system SHALL allow humans to review and edit generated captions before posting.

#### Scenario: Preview generated caption before scheduling

- **GIVEN** I'm scheduling a post for Sarah
- **WHEN** I request a caption preview
- **THEN** a caption is generated and displayed
- **AND** I can see the caption text and metadata
- **AND** I can regenerate if unsatisfied
- **AND** I can manually edit the caption
- **AND** I can approve and schedule with edited caption

#### Scenario: Track caption edit patterns

- **GIVEN** 10 captions have been generated for Sarah
- **AND** I edit 5 of them before posting
- **AND** edits primarily change tone/emoji usage
- **WHEN** I view caption generation analytics
- **THEN** edit frequency is shown (50%)
- **AND** common edit patterns are summarized
- **AND** suggestions for config improvements are provided

---

## MODIFIED Requirements

### Requirement: Persona Model Extension

The Persona model SHALL be extended to support caption generation configuration.

#### Scenario: Access caption config from persona

- **GIVEN** Sarah's persona exists with caption_config set
- **WHEN** I load the persona: Persona.find_by(name: 'sarah')
- **THEN** I can access: persona.caption_config
- **AND** the config returns a CaptionConfig object
- **AND** I can read: persona.caption_config.tone
- **AND** I can update: persona.caption_config.style[:use_emoji] = false

---

### Requirement: SchedulingPost Model Extension

The SchedulingPost model SHALL store caption generation metadata.

#### Scenario: Store caption generation details

- **GIVEN** a caption is generated for a scheduled post
- **WHEN** the post is created
- **THEN** caption_metadata is stored with model: llava:latest, generated_at: timestamp, method: ai_generated, quality_score: 8.5, variations: 3
- **AND** I can query posts by generation method
- **AND** I can filter by quality_score

---

## Implementation Notes

### Database Schema Changes

```sql
-- Add to personas table
ALTER TABLE personas ADD COLUMN caption_config jsonb DEFAULT '{}';

-- Add to scheduling_posts table
ALTER TABLE scheduling_posts ADD COLUMN caption_metadata jsonb DEFAULT '{}';
CREATE INDEX idx_scheduling_posts_caption_metadata ON scheduling_posts USING gin(caption_metadata);
```

### Service Architecture

```
CaptionGenerations::Generator (main entry point)
  ├── Personas::CaptionConfig (config model)
  ├── PromptBuilder (builds AI prompts)
  ├── ContextBuilder (cluster + image context)
  ├── RepetitionChecker (avoid phrase repetition)
  ├── OllamaClient (AI generation)
  ├── PostProcessor (format, validate)
  └── Result (returned caption with metadata)
```

### Integration Point

```ruby
# In content strategy scheduling flow
caption = CaptionGenerations::Generator.generate(
  photo: photo,
  persona: persona,
  cluster: cluster
)

Scheduling::SchedulePost.create!(
  photo: photo,
  scheduled_at: time,
  caption: caption.text,
  caption_metadata: caption.metadata
)
```
