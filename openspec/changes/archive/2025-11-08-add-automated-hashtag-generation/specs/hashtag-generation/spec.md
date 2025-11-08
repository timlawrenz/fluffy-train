# Hashtag Generation Capability

**Change**: add-automated-hashtag-generation  
**Status**: ADDED

---

## ADDED Requirements

### Requirement: Content-Based Hashtag Generation

The system SHALL generate hashtags based on image content analysis using detected objects from photo analysis.

#### Scenario: Generate content-specific hashtags from detected objects

- **GIVEN** a photo with detected_objects: ["sunset", "cityscape", "architecture"]
- **AND** object-to-hashtag mappings are configured
- **WHEN** hashtag generation is triggered
- **THEN** at least 3 content-specific hashtags are generated
- **AND** hashtags match detected objects (e.g., "#GoldenHour" from "sunset")
- **AND** hashtags are relevant to the image content

#### Scenario: Handle photos without detected objects

- **GIVEN** a photo with no detected_objects in photo_analysis
- **WHEN** hashtag generation is triggered
- **THEN** the system falls back to cluster-based hashtags
- **AND** at least 5 hashtags are generated
- **AND** generation does not fail

#### Scenario: Map objects to relevant hashtag categories

- **GIVEN** detected object "beach"
- **WHEN** generating hashtags
- **THEN** hashtags include "#BeachLife", "#OceanVibes", "#CoastalLiving"
- **AND** hashtags span different size categories (large, medium, niche)

---

### Requirement: Persona-Aligned Hashtag Strategy

The system SHALL align hashtag generation with persona-specific niche, topics, and target audience.

#### Scenario: Generate hashtags matching persona niche

- **GIVEN** Sarah's persona with hashtag_strategy configured
- **AND** niche_categories: ["lifestyle", "fashion", "travel"]
- **AND** target_hashtags: ["#LifestylePhotography", "#EverydayMagic"]
- **WHEN** hashtags are generated for Sarah's photo
- **THEN** at least 3 hashtags match persona niche categories
- **AND** target_hashtags are prioritized in selection
- **AND** avoid_hashtags are excluded from results

#### Scenario: Filter hashtags by persona preferences

- **GIVEN** a persona with avoid_hashtags: ["#like4like", "#followforfollow"]
- **AND** generated hashtag pool contains banned tags
- **WHEN** hashtags are filtered for persona
- **THEN** avoid_hashtags are removed from final selection
- **AND** no banned hashtags appear in results

#### Scenario: Use generic hashtags when no persona strategy configured

- **GIVEN** a persona without hashtag_strategy configured
- **WHEN** hashtags are generated
- **THEN** the system uses basic HashtagEngine (existing)
- **AND** cluster-based and popular hashtags are returned
- **AND** backward compatibility is maintained

---

### Requirement: Optimal Hashtag Mix Distribution

The system SHALL generate an optimal mix of large, medium, and niche hashtags to maximize reach and engagement.

#### Scenario: Generate optimal size distribution

- **GIVEN** persona.hashtag_strategy.size_preference: {large: 2, medium: 4, niche: 5}
- **AND** generated hashtag pool contains tags of all sizes
- **WHEN** hashtags are scored and selected
- **THEN** 2 large hashtags (1M+ posts) are included
- **AND** 4 medium hashtags (100K-500K posts) are included
- **AND** 5 niche hashtags (10K-50K posts) are included
- **AND** total count is 11 hashtags (within 5-12 range)

#### Scenario: Prioritize relevance over size category

- **GIVEN** a large hashtag with low relevance score (3.0)
- **AND** a niche hashtag with high relevance score (9.0)
- **WHEN** hashtags are ranked by score
- **THEN** the niche hashtag ranks higher than the large hashtag
- **AND** relevance takes precedence over size category

---

### Requirement: Relevance Scoring Algorithm

The system SHALL score hashtags based on content relevance, persona alignment, and size category to optimize selection.

#### Scenario: Calculate hashtag relevance score

- **GIVEN** a hashtag "#GoldenHour"
- **AND** photo has detected_object "sunset"
- **AND** cluster name contains "urban"
- **AND** persona niche_categories include "lifestyle"
- **WHEN** relevance score is calculated
- **THEN** score includes +5.0 for matching detected object
- **AND** score includes +3.0 for matching cluster theme
- **AND** score includes +4.0 for matching persona niche
- **AND** total score is >= 7.0 (high relevance)

#### Scenario: Penalize banned and spammy hashtags

- **GIVEN** a hashtag "#like4like" (banned)
- **WHEN** relevance score is calculated
- **THEN** score receives -10.0 penalty for banned hashtag
- **AND** final score is negative or very low
- **AND** hashtag is filtered out in final selection

---

### Requirement: Quality Control and Filtering

The system SHALL filter out banned, spammy, and irrelevant hashtags to maintain quality and avoid shadowban risk.

#### Scenario: Remove banned hashtags from results

- **GIVEN** generated hashtags include "#like4like", "#follow4follow"
- **AND** these are in the banned hashtag list
- **WHEN** quality filter is applied
- **THEN** banned hashtags are removed from results
- **AND** only quality hashtags remain
- **AND** a warning is logged about filtered hashtags

#### Scenario: Detect and remove spammy patterns

- **GIVEN** a hashtag "#FOLLOW" (all caps)
- **OR** a hashtag "#followforfollow" (engagement bait)
- **WHEN** quality filter is applied
- **THEN** spammy hashtags are detected and removed
- **AND** only legitimate hashtags remain

#### Scenario: Enforce relevance threshold

- **GIVEN** a hashtag with relevance score 1.5
- **AND** relevance threshold is 2.0
- **WHEN** quality filter is applied
- **THEN** the low-relevance hashtag is removed
- **AND** only hashtags with score >= 2.0 remain

---

### Requirement: Trending Hashtag Integration

The system SHALL support optional trending hashtag integration to increase post visibility when configured and trending data is available.

#### Scenario: Add trending hashtags when available

- **GIVEN** trending hashtags list contains "#MondayMotivation" for today
- **AND** persona.hashtag_strategy.use_trending is true
- **AND** trending tag is relevant to photo content (lifestyle/motivation)
- **WHEN** hashtags are generated
- **THEN** 1-2 trending hashtags are included in results
- **AND** trending hashtags are relevant to photo and persona
- **AND** total hashtag count does not exceed max (12)

#### Scenario: Skip trending when not relevant

- **GIVEN** trending hashtag "#TechTuesday" available
- **AND** photo is about beach lifestyle (not tech)
- **AND** persona niche is lifestyle (not tech)
- **WHEN** trending hashtags are evaluated
- **THEN** irrelevant trending hashtag is not included
- **AND** only relevant hashtags are used

#### Scenario: Manual trending list fallback

- **GIVEN** trending API is unavailable or not configured
- **WHEN** trending hashtags are requested
- **THEN** system uses manual curated list from config/trending_hashtags.yml
- **AND** hashtags are returned without failure
- **AND** list is cached for 24 hours

---

### Requirement: Hashtag Metadata Tracking

The system SHALL track hashtag generation metadata including method, sources, scores, and distribution for analysis.

#### Scenario: Store hashtag generation metadata

- **GIVEN** hashtags are generated with intelligent generator
- **WHEN** the post is created
- **THEN** hashtag_metadata is stored with method: "intelligent_generation"
- **AND** metadata includes content_tags count
- **AND** metadata includes persona_tags count
- **AND** metadata includes relevance_score
- **AND** metadata includes size_distribution breakdown

#### Scenario: Track hashtag sources for analytics

- **GIVEN** hashtags from multiple sources (content, persona, trending)
- **WHEN** metadata is stored
- **THEN** each hashtag's source is tracked
- **AND** content_tags: ["#GoldenHour", "#SunsetLovers"]
- **AND** persona_tags: ["#LifestylePhotography"]
- **AND** trending_tags: ["#MondayMotivation"]
- **AND** metadata enables future performance analysis

---

