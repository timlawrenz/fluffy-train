# Content Pillars Spec Delta

**Change ID**: `update-strategy-first-model`  
**Affects**: content-pillars

---

## ADDED Requirements

### Requirement: AI-Powered Content Gap Recommendations

The system SHALL generate AI-powered content creation prompts for pillars with identified content gaps.

#### Scenario: Generate AI prompts for pillar with gap

- **GIVEN** a pillar has a content gap of 5 photos
- **WHEN** requesting AI recommendations for the pillar
- **THEN** the system SHALL generate detailed image prompts
- **AND** prompts SHALL include scene, outfit, mood, and photography style
- **AND** prompts SHALL align with pillar theme and persona aesthetic
- **AND** prompts SHALL be suitable for AI image generation tools

#### Scenario: Create clusters from AI prompts

- **GIVEN** AI has generated 3 content prompts for a pillar
- **WHEN** creating clusters from the prompts
- **THEN** 3 clusters SHALL be created with ai_prompt field populated
- **AND** clusters SHALL be automatically linked to the pillar
- **AND** cluster names SHALL reflect the prompt's scene/theme
- **AND** clusters SHALL be empty, ready for photo import

#### Scenario: Save AI prompts for reference

- **GIVEN** AI prompts have been generated
- **WHEN** user chooses to save prompts
- **THEN** prompts SHALL be saved to markdown files
- **AND** files SHALL be organized by persona and pillar
- **AND** files SHALL include full prompt and structured metadata

---

### Requirement: Gap Analysis Integration with Content Creation

The system SHALL integrate gap analysis with AI-powered content recommendations to support proactive content planning.

#### Scenario: Detect gap and offer AI suggestions

- **GIVEN** gap analysis identifies a critical gap (>5 photos needed)
- **WHEN** viewing the gap analysis results
- **THEN** the system SHALL offer to generate AI content prompts
- **AND** user can trigger prompt generation directly from gap view
- **AND** generated prompts SHALL create clusters linked to the pillar

#### Scenario: Track AI-generated vs manual clusters

- **GIVEN** a pillar has both AI-generated and manual clusters
- **WHEN** querying the pillar's clusters
- **THEN** clusters with ai_prompt field SHALL be identifiable
- **AND** the system can differentiate between creation methods
- **AND** both types function identically in content selection

---

## MODIFIED Requirements

### Requirement: Content Gap Analysis

System SHALL analyze content gaps by comparing pillar target posts against available photos, and SHALL recommend content creation when gaps are identified.

**Acceptance Criteria:**
- Calculate posts_needed per pillar based on weight and timeframe
- Count available (unposted) photos across pillar's clusters
- Identify gap = posts_needed - photos_available
- Return status: :ready, :low, :critical, :exhausted
- Support configurable lookahead period (default 30 days)
- Recommend AI prompt generation for critical gaps

#### Scenario: Identify critical content gap and recommend creation

- **GIVEN** Thanksgiving pillar with weight 30%
- **AND** 30 total posts needed in next 30 days
- **AND** Thanksgiving target is 9 posts (30% of 30)
- **AND** 0 photos available in pillar's clusters
- **WHEN** running gap analysis
- **THEN** gap SHALL be 9
- **AND** status SHALL be :exhausted
- **AND** priority SHALL be :high
- **AND** system SHALL recommend AI prompt generation

#### Scenario: Gap filled through AI-suggested content creation

- **GIVEN** a pillar had a gap of 5 photos
- **AND** AI prompts were generated and clusters created
- **AND** 6 photos were generated and imported to clusters
- **WHEN** running gap analysis again
- **THEN** gap SHALL be -1 (surplus)
- **AND** status SHALL be :ready
- **AND** no content creation SHALL be recommended
