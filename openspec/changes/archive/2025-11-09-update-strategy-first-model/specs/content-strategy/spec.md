# Content Strategy Spec Delta

**Change ID**: `update-strategy-first-model`  
**Affects**: content-strategy

---

## MODIFIED Requirements

### Requirement: Strategy Pattern Framework

The system SHALL provide a modular strategy framework for content selection with persona-scoped cluster access and proactive gap identification.

**Architecture Shift**: Strategies now evaluate pillar coverage first, identify gaps, and recommend content creation before selecting from existing photos.

#### Scenario: Strategy evaluates pillar coverage before selection

- **GIVEN** a strategy is initialized with persona context
- **AND** persona has 3 active pillars
- **WHEN** the strategy prepares to select content
- **THEN** strategy SHALL evaluate coverage for all pillars
- **AND** strategy SHALL identify any content gaps
- **AND** strategy SHALL prioritize gap-filling over rotation

#### Scenario: Strategy recommends content creation for gaps

- **GIVEN** a pillar has a critical content gap
- **AND** no suitable photos exist for the pillar
- **WHEN** strategy attempts to select content for that pillar
- **THEN** strategy SHALL detect the gap
- **AND** strategy SHALL recommend AI prompt generation
- **AND** strategy SHALL skip to next pillar if gap cannot be filled immediately

#### Scenario: Strategy selects from existing photos when no gaps

- **GIVEN** all pillars have adequate photo coverage
- **AND** no critical gaps exist
- **WHEN** strategy selects next content
- **THEN** strategy SHALL use rotation/variety logic
- **AND** strategy SHALL select from available photos
- **AND** strategy SHALL apply existing selection rules (quality, recency, variety)

---

## ADDED Requirements

### Requirement: Gap-Aware Content Selection

The system SHALL prioritize content selection for pillars with gaps and integrate gap analysis into the selection workflow.

#### Scenario: Select from pillar with smallest gap

- **GIVEN** Pillar A has gap of 2 photos
- **AND** Pillar B has gap of 0 photos (surplus)
- **AND** Pillar C has gap of 5 photos
- **WHEN** strategy selects next pillar to post from
- **THEN** strategy MAY prioritize Pillar A or C based on priority
- **AND** strategy SHALL NOT ignore gaps in selection logic

#### Scenario: Track gap reduction over time

- **GIVEN** a pillar started with gap of 10 photos
- **AND** 6 posts have been made from that pillar
- **WHEN** evaluating gap status
- **THEN** gap SHALL be updated to 4 photos
- **AND** pillar status SHALL improve from :critical to :low
- **AND** strategy SHALL adjust pillar priority accordingly
