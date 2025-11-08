# content-strategy Specification

## Purpose
TBD - created by archiving change add-content-strategy-engine. Update Purpose after archive.
## Requirements
### Requirement: Strategy Pattern Framework

The system SHALL provide a modular strategy framework for content selection with persona-scoped cluster access.

#### Scenario: Strategy selects from persona's clusters only
- **GIVEN** a strategy is initialized with persona context
- **AND** multiple personas have clusters in the system
- **WHEN** the strategy queries available clusters
- **THEN** only the persona's clusters SHALL be returned
- **AND** clusters from other personas SHALL be excluded
- **AND** query SHALL use direct persona.clusters relationship

#### Scenario: Efficient cluster availability check
- **GIVEN** a persona with 10 clusters
- **WHEN** content strategy checks available clusters
- **THEN** the query SHALL use `persona.clusters` instead of joining through photos
- **AND** query execution SHALL be faster than previous join-based approach
- **AND** result SHALL include only clusters with unposted photos

#### Scenario: Cross-persona isolation in multi-user scenario
- **GIVEN** Sarah and TechReviewer both using the system
- **AND** both have active content strategies
- **WHEN** Sarah's strategy selects a cluster
- **THEN** only Sarah's clusters SHALL be available for selection
- **AND** TechReviewer's strategy SHALL only see TechReviewer's clusters
- **AND** no data leakage between personas SHALL occur

### Requirement: Theme of the Week Strategy

The system SHALL provide a "Theme of the Week" strategy that focuses content on one cluster for 7 consecutive days.

#### Scenario: Continue active theme
- **GIVEN** a theme is active for the current week
- **AND** the cluster has unposted photos
- **WHEN** selecting the next post
- **THEN** the system SHALL use the same cluster
- **AND** select the highest quality photo based on aesthetic score

#### Scenario: Start new theme at week boundary
- **GIVEN** a new week has started
- **OR** the current cluster is exhausted
- **WHEN** selecting the next post
- **THEN** the system SHALL select a new cluster
- **AND** filter out clusters used in the last 14 days (configurable)
- **AND** choose the cluster with the most unposted photos
- **AND** record the new theme in state with week number

#### Scenario: Track theme state
- **GIVEN** a photo is selected from a theme cluster
- **WHEN** the selection is complete
- **THEN** the system SHALL update theme state with:
  - current_cluster_id
  - started_at timestamp
  - posts_count (incremented)
  - week_number

### Requirement: Thematic Rotation Strategy

The system SHALL provide a "Thematic Rotation" strategy that rotates through clusters sequentially.

#### Scenario: Initialize rotation order
- **GIVEN** no rotation state exists
- **OR** the available clusters have changed
- **WHEN** initializing rotation
- **THEN** the system SHALL create a rotation order
- **AND** prioritize clusters by unposted photo count (descending)
- **AND** store rotation_order array and current_index in state

#### Scenario: Advance through rotation
- **GIVEN** a rotation is active
- **WHEN** selecting the next post
- **THEN** the system SHALL use the cluster at current_index
- **AND** select photo alternating between best (aesthetic_score) and random
- **AND** advance to the next cluster in rotation
- **AND** wrap around to index 0 when reaching the end

#### Scenario: Handle exhausted cluster in rotation
- **GIVEN** the current cluster in rotation has no unposted photos
- **WHEN** selecting the next post
- **THEN** the system SHALL advance to the next cluster
- **AND** continue until finding a cluster with unposted photos
- **OR** raise NoUnpostedPhotosError if all clusters exhausted

### Requirement: Optimal Posting Time Calculation

The system SHALL calculate optimal posting times based on Instagram best practices research.

#### Scenario: Calculate optimal time for weekday
- **GIVEN** a scheduled posting date on Tuesday
- **WHEN** calculating optimal time
- **THEN** the system SHALL recommend a time within optimal windows:
  - 5am-8am local time
  - OR 11am-6pm local time
- **AND** prefer the window closest to preferred time if provided
- **AND** apply timezone conversion for the persona

#### Scenario: Use different windows by day of week
- **GIVEN** scheduled posting dates on different days
- **WHEN** calculating optimal time
- **THEN** the system SHALL use day-specific windows:
  - Monday: 5am-8am, 3pm-4pm
  - Tuesday: 5am-8am, 11am-6pm
  - Wednesday: 5pm, 10am-6pm
  - Thursday: 4pm-5pm, 11am-6pm
  - Friday: 4pm, 11am-2pm
  - Saturday: 11am, 10am-1pm
  - Sunday: 12pm-3pm, 4pm-5pm

### Requirement: Content Variety Enforcement

The system SHALL enforce content variety rules to prevent audience fatigue.

#### Scenario: Block recently used cluster
- **GIVEN** a cluster was posted within the variety gap period (default 3 days)
- **WHEN** selecting a cluster
- **THEN** the system SHALL exclude that cluster from selection
- **AND** only consider clusters not used within the gap period

#### Scenario: Allow all clusters when all recently used
- **GIVEN** all available clusters were used within the variety gap
- **WHEN** selecting a cluster
- **THEN** the system SHALL allow any cluster
- **AND** prefer the least recently used cluster

#### Scenario: Track posting history for variety
- **GIVEN** posts are being scheduled
- **WHEN** checking variety enforcement
- **THEN** the system SHALL query posts from the last 14 days (configurable)
- **AND** track which clusters were used and when
- **AND** calculate days since each cluster's last use

### Requirement: State Management

The system SHALL persist strategy state across multiple posting cycles.

#### Scenario: Create state on first use
- **GIVEN** a persona has no strategy state
- **WHEN** selecting content with a strategy
- **THEN** the system SHALL create a StrategyState record
- **AND** initialize with default configuration
- **AND** set active_strategy to the configured strategy name

#### Scenario: Load state from cache
- **GIVEN** a persona has existing strategy state
- **WHEN** selecting content
- **THEN** the system SHALL load state from Redis cache if available
- **AND** cache TTL SHALL be 5 minutes
- **OR** load from database if cache miss
- **AND** populate cache for subsequent requests

#### Scenario: Update state after selection
- **GIVEN** a photo is selected
- **WHEN** the selection is complete
- **THEN** the system SHALL update strategy-specific state data
- **AND** invalidate the Redis cache
- **AND** create a history record with decision context

### Requirement: Posting History Tracking

The system SHALL track posting history for strategy decision-making.

#### Scenario: Query recent posts
- **GIVEN** a persona and date range
- **WHEN** querying posting history
- **THEN** the system SHALL return posts within the date range
- **AND** include cluster information
- **AND** include photo information
- **AND** order by posted_at descending

#### Scenario: Calculate posts this week
- **GIVEN** a persona
- **WHEN** checking posting frequency
- **THEN** the system SHALL count posts since start of current week
- **AND** use the persona's timezone for week boundaries

#### Scenario: Get cluster usage history
- **GIVEN** a persona and lookback period (default 14 days)
- **WHEN** checking cluster usage
- **THEN** the system SHALL return a map of cluster_id → last_posted_at
- **AND** only include clusters with posts in the period

### Requirement: Configuration Management

The system SHALL support flexible configuration per persona.

#### Scenario: Load configuration from YAML
- **GIVEN** a config/content_strategy.yml file exists
- **WHEN** loading configuration
- **THEN** the system SHALL load default settings
- **AND** override with environment-specific settings (development, production)
- **AND** validate all configuration parameters

#### Scenario: Override configuration per persona
- **GIVEN** a persona with custom configuration in strategy_config
- **WHEN** loading configuration for that persona
- **THEN** the system SHALL merge persona overrides with defaults
- **AND** validate the merged configuration

#### Scenario: Validate configuration
- **GIVEN** a configuration with parameters
- **WHEN** validating the configuration
- **THEN** posts_per_week MUST be 1-7
- **AND** variety_gap_days MUST be >= 0
- **AND** hashtag_count MUST be 5-12
- **AND** timezone MUST be a valid timezone string

### Requirement: Hashtag Generation

The system SHALL generate relevant hashtags for posts, with support for intelligent generation when persona strategy is configured.

#### Scenario: Generate mixed hashtag set
- **GIVEN** a photo, cluster, and hashtag count of 8
- **WHEN** generating hashtags
- **THEN** the system SHALL return 8 hashtags
- **AND** include 2 popular hashtags (>100K posts)
- **AND** include 3 medium hashtags (<100K posts)
- **AND** include 3 niche-specific hashtags

#### Scenario: Use cluster-specific hashtags
- **GIVEN** a cluster with custom hashtag configuration
- **WHEN** generating hashtags
- **THEN** the system SHALL include cluster-specific hashtags
- **AND** mix with general relevant hashtags

#### Scenario: Route to intelligent generator when strategy configured

- **GIVEN** persona has hashtag_strategy configured
- **WHEN** generating hashtags
- **THEN** HashtagGenerations::Generator is invoked (intelligent path)
- **AND** persona strategy is passed to generator
- **AND** hashtags and metadata are returned

#### Scenario: Fallback to basic generator when no strategy

- **GIVEN** persona has no hashtag_strategy configured
- **WHEN** generating hashtags
- **THEN** HashtagEngine is invoked (existing basic path)
- **AND** cluster-based and popular hashtags are returned
- **AND** backward compatibility is maintained

### Requirement: Error Handling and Fallbacks

The system SHALL handle errors gracefully with fallback mechanisms.

#### Scenario: Fallback when no clusters available
- **GIVEN** no clusters meet variety requirements
- **WHEN** selecting a cluster
- **THEN** the system SHALL relax variety rules
- **AND** select from any available cluster with unposted photos
- **AND** log a warning about fallback usage

#### Scenario: Raise error when no photos available
- **GIVEN** no clusters have unposted photos
- **WHEN** selecting content
- **THEN** the system SHALL raise NoUnpostedPhotosError
- **AND** include context about available clusters in error

#### Scenario: Fallback to simple selection on strategy error
- **GIVEN** the primary strategy encounters an unexpected error
- **WHEN** selecting content
- **THEN** the system SHALL log the error with full context
- **AND** fall back to simple random selection
- **AND** skip state management
- **AND** use basic timing (current time + 1 hour)

### Requirement: Observability and Audit Trail

The system SHALL provide comprehensive logging and audit capabilities.

#### Scenario: Log strategy selection decisions
- **GIVEN** a cluster and photo are selected
- **WHEN** the selection completes
- **THEN** the system SHALL log structured data including:
  - strategy name
  - cluster_id and cluster_name
  - photo_id
  - persona_id
  - posts_this_week count
  - variety_gap_days
  - timestamp

#### Scenario: Create audit history record
- **GIVEN** a post is scheduled via strategy
- **WHEN** the post is created
- **THEN** the system SHALL create a HistoryRecord with:
  - persona_id
  - post_id
  - cluster_id (if applicable)
  - strategy_name
  - decision_context (available clusters, recent clusters, variety score, selection reason, optimal time window, posts this week)

#### Scenario: Track performance metrics
- **GIVEN** a strategy selection completes
- **WHEN** tracking metrics
- **THEN** the system SHALL record:
  - strategy usage count (by strategy name)
  - cluster usage count (by cluster_id)
  - selection duration (in milliseconds)
  - state cache hit/miss ratio

### Requirement: Feature Flag Control

The system SHALL support gradual rollout via feature flags.

#### Scenario: Disable strategy engine via flag
- **GIVEN** content_strategy_enabled is false for a persona
- **WHEN** the posting task runs
- **THEN** the system SHALL use the legacy posting logic
- **AND** skip strategy selection entirely

#### Scenario: Enable strategy engine via flag
- **GIVEN** content_strategy_enabled is true for a persona
- **WHEN** the posting task runs
- **THEN** the system SHALL use ContentStrategy::SelectNextPost
- **AND** apply the configured strategy

#### Scenario: Per-persona flag override
- **GIVEN** different personas with different flag values
- **WHEN** posting for each persona
- **THEN** the system SHALL respect per-persona flag settings
- **AND** allow mixed rollout (some with strategy, some without)

### Requirement: Integration with Scheduler

The system SHALL integrate with the existing posting scheduler.

#### Scenario: Pass strategy data to scheduler
- **GIVEN** a photo is selected via strategy
- **WHEN** scheduling the post
- **THEN** the system SHALL provide:
  - photo (Photo object)
  - caption (String)
  - scheduled_at (DateTime with optimal time)
  - cluster (Cluster object)
  - hashtags (Array of strings)

#### Scenario: Store strategy metadata in post record
- **GIVEN** a post is created from strategy selection
- **WHEN** the post is saved
- **THEN** the system SHALL store:
  - cluster_id
  - strategy_name
  - optimal_time_calculated
  - hashtags (jsonb array)

### Requirement: Cluster Query Enhancement

The system SHALL enhance cluster queries for strategy needs.

#### Scenario: Query available clusters for posting
- **GIVEN** clusters exist
- **WHEN** querying available clusters
- **THEN** the system SHALL return clusters where:
  - status is active
  - AND photos_count > 0
  - AND has at least one unposted photo

#### Scenario: Get unposted photos for cluster
- **GIVEN** a cluster with photos
- **WHEN** querying unposted photos
- **THEN** the system SHALL return photos where:
  - photo is in the cluster
  - AND photo has not been posted (no scheduling_post with status: posted)

#### Scenario: Get cluster last posted time
- **GIVEN** a cluster that has been posted before
- **WHEN** querying last_posted_at
- **THEN** the system SHALL return the most recent posted_at timestamp
- **AND** query via scheduling_posts joined with photos

