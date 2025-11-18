# ai-content-generation Specification

## Purpose
TBD - created by archiving change update-strategy-first-model. Update Purpose after archive.
## Requirements
### Requirement: Gemini API Integration

The system SHALL integrate with Google Gemini 2.5 Pro API for AI-powered content prompt generation.

#### Scenario: Generate prompt with Gemini 2.5 Pro

- **GIVEN** Gemini API key is configured
- **AND** Gemini API is available
- **WHEN** requesting content prompt generation
- **THEN** system SHALL call Gemini 2.5 Pro API
- **AND** system SHALL receive structured prompt response
- **AND** response SHALL include scene, outfit, mood, and full prompt

#### Scenario: Handle API errors gracefully

- **GIVEN** Gemini API returns an error
- **WHEN** generating prompts
- **THEN** system SHALL catch the error
- **AND** system SHALL display user-friendly error message
- **AND** system SHALL NOT crash or lose user context

#### Scenario: Respect rate limits

- **GIVEN** multiple prompt generation requests
- **WHEN** approaching API rate limits
- **THEN** system SHALL handle rate limit errors
- **AND** system MAY implement backoff/retry logic
- **AND** user SHALL be informed of rate limit status

---

### Requirement: Persona-Aware Prompt Engineering

The system SHALL generate prompts that incorporate persona aesthetic, voice, and demographic attributes.

#### Scenario: Include persona aesthetic in prompt

- **GIVEN** Sarah persona with aesthetic "contemporary, authentic, relatable"
- **WHEN** generating a content prompt
- **THEN** prompt SHALL include aesthetic guidance
- **AND** prompt SHALL avoid overly staged or artificial scenarios
- **AND** photography style SHALL align with persona's aesthetic

#### Scenario: Include persona demographics

- **GIVEN** persona has age 28, location "San Francisco"
- **WHEN** generating prompt
- **THEN** prompt SHALL feature age-appropriate scenarios
- **AND** prompt MAY reference location-specific elements
- **AND** demographics SHALL influence outfit and activity suggestions

#### Scenario: Include persona voice attributes

- **GIVEN** persona voice is "warm, genuine, thoughtful"
- **WHEN** generating prompt
- **THEN** mood/vibe SHALL align with voice attributes
- **AND** scenes SHALL feel authentic to persona's voice
- **AND** prompt SHALL avoid conflicting tones

---

### Requirement: Pillar-Aligned Content Prompts

The system SHALL generate prompts that align with the specified content pillar's theme, guidelines, and topics.

#### Scenario: Generate prompts matching pillar theme

- **GIVEN** pillar "Thanksgiving 2024 Gratitude" with theme gratitude/autumn
- **WHEN** generating prompts for this pillar
- **THEN** prompts SHALL feature thanksgiving-adjacent themes
- **AND** prompts SHALL include autumn/cozy elements
- **AND** prompts SHALL avoid summer/spring imagery

#### Scenario: Include pillar guidelines

- **GIVEN** pillar guidelines specify tone "understated, grateful"
- **AND** guidelines include topics ["autumn", "gratitude", "cozy moments"]
- **WHEN** generating prompt
- **THEN** prompt SHALL incorporate specified topics
- **AND** prompt tone SHALL match guidelines
- **AND** prompt SHALL feel consistent with pillar strategy

#### Scenario: Respect pillar avoid_topics

- **GIVEN** pillar guidelines avoid_topics ["food", "turkey", "traditional thanksgiving"]
- **WHEN** generating prompt
- **THEN** prompt SHALL NOT include avoided topics
- **AND** system SHALL filter out conflicting suggestions
- **AND** prompts SHALL focus on allowed themes

---

### Requirement: Structured Prompt Output

The system SHALL parse AI responses into structured components for user review and cluster creation.

#### Scenario: Parse full prompt

- **GIVEN** AI response contains detailed image generation prompt
- **WHEN** parsing the response
- **THEN** system SHALL extract complete prompt text
- **AND** full prompt SHALL be usable in AI image tools
- **AND** prompt SHALL be stored in cluster's ai_prompt field

#### Scenario: Extract scene description

- **GIVEN** AI response includes "**Scene:** Golden hour farmhouse table"
- **WHEN** parsing structured components
- **THEN** system SHALL extract "Golden hour farmhouse table"
- **AND** scene SHALL be displayed separately for review
- **AND** scene MAY be used for cluster naming

#### Scenario: Extract outfit and mood details

- **GIVEN** AI response includes outfit and mood markers
- **WHEN** parsing response
- **THEN** system SHALL extract outfit description
- **AND** system SHALL extract mood/vibe description
- **AND** components SHALL be displayed for user review

---

### Requirement: Cluster Creation from AI Prompts

The system SHALL support creating clusters directly from AI-generated prompts with automatic pillar linking.

#### Scenario: Create cluster with ai_prompt field

- **GIVEN** an AI prompt has been generated
- **WHEN** user chooses to create cluster from prompt
- **THEN** cluster SHALL be created with ai_prompt field populated
- **AND** cluster SHALL belong to the persona
- **AND** cluster SHALL have descriptive name derived from scene

#### Scenario: Link cluster to originating pillar

- **GIVEN** prompts were generated for "Thanksgiving 2024" pillar
- **WHEN** creating clusters from prompts
- **THEN** clusters SHALL be automatically linked to the pillar
- **AND** PillarClusterAssignment SHALL be created
- **AND** assignment SHALL be marked as primary

#### Scenario: Save prompts to markdown files

- **GIVEN** AI prompts have been generated
- **WHEN** user chooses to save prompts
- **THEN** prompts SHALL be saved to docs/ai-prompts/ directory
- **AND** filename SHALL include persona, pillar, and timestamp
- **AND** file SHALL contain full prompt and metadata
- **AND** file SHALL be formatted as markdown

---

### Requirement: Multi-Prompt Generation

The system SHALL support generating multiple diverse prompts in a single request.

#### Scenario: Generate 3 prompts with variety

- **GIVEN** user requests 3 prompts for a pillar
- **WHEN** calling AI generation
- **THEN** system SHALL generate 3 distinct prompts
- **AND** prompts SHALL have different scenes/scenarios
- **AND** prompts SHALL all align with pillar theme
- **AND** prompts SHALL offer variety in mood/setting

#### Scenario: Limit prompt count for API efficiency

- **GIVEN** user requests more than 5 prompts
- **WHEN** processing the request
- **THEN** system SHALL clamp count to maximum of 5
- **AND** user SHALL be informed of the limit
- **AND** user can make multiple requests if needed

