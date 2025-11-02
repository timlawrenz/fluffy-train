# Implementation Tasks: Content Strategy Engine

## PHASE 1: Foundation (Week 1)

### 1.1 Database Migrations

- [x] 1.1.1 Create migration: content_strategy_state table
  - [ ] Add persona_id reference (non-null, indexed unique)
  - [ ] Add active_strategy string field
  - [ ] Add strategy_config jsonb field
  - [ ] Add state_data jsonb field
  - [ ] Add started_at timestamp
  - [ ] Add timestamps

- [x] 1.1.2 Create migration: content_strategy_history table
  - [ ] Add persona_id reference (non-null, indexed)
  - [ ] Add post_id reference (non-null)
  - [ ] Add cluster_id reference (nullable, indexed)
  - [ ] Add strategy_name string
  - [ ] Add decision_context jsonb
  - [ ] Add created_at timestamp (indexed with persona_id)

- [x] 1.1.3 Create migration: enhance scheduling_posts table
  - [ ] Add cluster_id bigint (indexed)
  - [ ] Add strategy_name string (indexed)
  - [ ] Add optimal_time_calculated datetime
  - [ ] Add hashtags jsonb (default: [])

- [x] 1.1.4 Run migrations in development
- [x] 1.1.5 Verify schema with db:schema:dump

### 1.2 Pack Structure

- [x] 1.2.1 Create pack: packs/content_strategy/
- [x] 1.2.2 Create package.yml with dependencies
- [x] 1.2.3 Set up directory structure:
  - [ ] app/models/content_strategy/
  - [ ] app/services/content_strategy/
  - [ ] app/strategies/content_strategy/
  - [ ] app/concerns/content_strategy/
  - [ ] app/commands/content_strategy/
  - [ ] spec/

### 1.3 Base Models

- [x] 1.3.1 Create ContentStrategy::StrategyState model
  - [ ] Add belongs_to :persona association
  - [ ] Add get_state(key) method
  - [ ] Add set_state(key, value) method
  - [ ] Add update_state(key, updates) method
  - [ ] Add validations

- [x] 1.3.2 Create ContentStrategy::HistoryRecord model
  - [ ] Add belongs_to :persona association
  - [ ] Add belongs_to :post association
  - [ ] Add belongs_to :cluster (optional) association
  - [ ] Add scopes: recent, for_persona, for_cluster

- [x] 1.3.3 Write model specs

### 1.4 Configuration System

- [x] 1.4.1 Create ContentStrategy::StrategyConfig class
  - [ ] Add ActiveModel::Model and Attributes
  - [ ] Define posting frequency attributes
  - [ ] Define timing attributes
  - [ ] Define variety attributes
  - [ ] Define format attributes
  - [ ] Define hashtag attributes
  - [ ] Add validations
  - [ ] Add from_yaml class method

- [x] 1.4.2 Create config/content_strategy.yml
  - [ ] Define default configuration
  - [ ] Define development overrides
  - [ ] Define production settings
  - [ ] Document all parameters

- [x] 1.4.3 Create ContentStrategy::ConfigLoader
  - [ ] Load configuration from YAML
  - [ ] Merge environment-specific settings
  - [ ] Cache loaded config

- [x] 1.4.4 Write configuration specs

### 1.5 Context and State Cache

- [x] 1.5.1 Create ContentStrategy::Context class
  - [ ] Initialize with persona and current_time
  - [ ] Load posting_history
  - [ ] Load state from cache
  - [ ] Provide available_clusters
  - [ ] Provide recent_cluster_ids
  - [ ] Provide posts_this_week
  - [ ] Provide state_config

- [x] 1.5.2 Create ContentStrategy::StateCache
  - [ ] Implement cache_key generation
  - [ ] Implement get(persona_id) with Rails.cache
  - [ ] Implement invalidate(persona_id)
  - [ ] Set TTL to 5 minutes

- [x] 1.5.3 Create ContentStrategy::PostingHistory service
  - [ ] Initialize with persona
  - [ ] Implement recent_posts(days:)
  - [ ] Implement posts_this_week
  - [ ] Implement cluster_usage_history(days:)

- [x] 1.5.4 Write context and cache specs

### 1.6 Base Strategy Pattern

- [x] 1.6.1 Create ContentStrategy::BaseStrategy class
  - [ ] Define select_cluster(available_clusters, context) interface
  - [ ] Define select_photo(cluster, context) interface
  - [ ] Implement optimal_posting_time(date, context)
  - [ ] Implement generate_hashtags(photo, cluster, context)
  - [ ] Implement enforce_variety?(cluster, context)
  - [ ] Add initialize(config = {})
  - [ ] Add validate_config!
  - [ ] Add lifecycle hooks: on_photo_selected, on_post_scheduled, on_post_completed

- [x] 1.6.2 Create ContentStrategy::Registry class
  - [ ] Implement register(name, strategy_class)
  - [ ] Implement get(name)
  - [ ] Implement list
  - [ ] Handle UnknownStrategyError

- [x] 1.6.3 Write base strategy specs

### 1.7 Shared Concerns

- [x] 1.7.1 Create ContentStrategy::TimingOptimization module
  - [ ] Define OPTIMAL_WINDOWS constant (by day of week)
  - [ ] Implement calculate_optimal_time(date, preferred_time)
  - [ ] Parse time windows
  - [ ] Apply timezone conversions
  - [ ] Select best window for given day

- [x] 1.7.2 Create ContentStrategy::VarietyEnforcement module
  - [ ] Implement recent_clusters(days:)
  - [ ] Implement days_since_cluster_used(cluster_id)
  - [ ] Implement variety_score(cluster, history)
  - [ ] Implement enforce_gap?(cluster, gap_days)

- [x] 1.7.3 Create ContentStrategy::FormatOptimization module
  - [ ] Implement recommend_format(photo, context)
  - [ ] Consider account size
  - [ ] Consider recent format usage
  - [ ] Apply format preferences from config

- [x] 1.7.4 Write concern specs

### 1.8 Error Handling

- [x] 1.8.1 Define ContentStrategy::Error hierarchy
  - [ ] ContentStrategy::Error (base)
  - [ ] UnknownStrategyError
  - [ ] NoAvailableClustersError
  - [ ] NoUnpostedPhotosError
  - [ ] InvalidConfigurationError
  - [ ] StrategyStateError

- [x] 1.8.2 Write error handling specs

## PHASE 2: Core Strategies (Week 2)

### 2.1 Theme of the Week Strategy

- [ ] 2.1.1 Create ContentStrategy::ThemeOfWeekStrategy
  - [ ] Inherit from BaseStrategy
  - [ ] Register with Registry
  - [ ] Implement select_cluster(available_clusters, context)
    - [ ] Check if current theme is active (same week)
    - [ ] Return current cluster if has unposted photos
    - [ ] Select new theme if week changed or cluster exhausted
    - [ ] Filter recently used clusters
    - [ ] Pick cluster with most unposted photos
  - [ ] Implement select_photo(cluster, context)
    - [ ] Query unposted photos with photo_analysis
    - [ ] Order by aesthetic_score DESC
    - [ ] Return first (highest quality)
  - [ ] Implement on_photo_selected hook
    - [ ] Update theme_of_week state
    - [ ] Track current_cluster_id
    - [ ] Track started_at, posts_count, week_number

- [ ] 2.1.2 Add helper methods
  - [ ] week_active?(context)
  - [ ] select_new_theme(available_clusters, context)
  - [ ] current_posts_count(context)

- [x] 2.1.3 Write ThemeOfWeekStrategy specs
  - [ ] Test cluster selection when theme active
  - [ ] Test new theme selection at week boundary
  - [ ] Test variety enforcement
  - [ ] Test state updates
  - [ ] Test edge cases (no clusters, exhausted clusters)

### 2.2 Thematic Rotation Strategy

- [ ] 2.2.1 Create ContentStrategy::ThematicRotationStrategy
  - [ ] Inherit from BaseStrategy
  - [ ] Register with Registry
  - [ ] Implement select_cluster(available_clusters, context)
    - [ ] Load rotation state
    - [ ] Initialize rotation if empty or changed
    - [ ] Get next cluster in rotation
    - [ ] Advance if cluster exhausted
  - [ ] Implement select_photo(cluster, context)
    - [ ] Alternate between best (aesthetic_score) and random
    - [ ] Toggle selection_mode in state
  - [ ] Implement on_photo_selected hook
    - [ ] Advance rotation index
    - [ ] Toggle selection mode
    - [ ] Update last_rotated_at

- [ ] 2.2.2 Add helper methods
  - [ ] initialize_rotation(available_clusters, context)
  - [ ] advance_rotation(available_clusters, context)
  - [ ] rotation_order_changed?(rotation_state, available_clusters)

- [x] 2.2.3 Write ThematicRotationStrategy specs
  - [ ] Test rotation initialization
  - [ ] Test cluster advancement
  - [ ] Test selection mode toggling
  - [ ] Test rotation order changes
  - [ ] Test edge cases

### 2.3 Cluster Integration

- [x] 2.3.1 Enhance Clustering::Cluster model
  - [ ] Add scope: available_for_posting
  - [ ] Add scope: with_unposted_photos
  - [ ] Add method: unposted_photos
  - [ ] Add method: last_posted_at

- [x] 2.3.2 Enhance Photo model (if needed)
  - [ ] Add scope: unposted
  - [ ] Add scope: in_cluster(cluster_id)
  - [ ] Add method: posted?

- [x] 2.3.3 Update Scheduling::Post model
  - [ ] Add scope: posted (where status: posted)
  - [ ] Add belongs_to :cluster (optional)

- [x] 2.3.4 Write integration specs

### 2.4 Hashtag Generation

- [x] 2.4.1 Create ContentStrategy::HashtagEngine service
  - [ ] Implement generate(photo, cluster, count:)
  - [ ] Query photo tags/caption for relevant terms
  - [ ] Mix popular, medium, niche hashtags (2-3-3 ratio)
  - [ ] Return array of hashtag strings

- [x] 2.4.2 Create hashtag configuration
  - [ ] Define popular hashtags pool
  - [ ] Define niche hashtag patterns
  - [ ] Allow per-cluster hashtag overrides

- [x] 2.4.3 Write hashtag generation specs

## PHASE 3: Integration (Week 3)

### 3.1 Command Chain

- [ ] 3.1.1 Create ContentStrategy::Commands::LoadStrategyState
  - [ ] Input: persona
  - [ ] Load or create StrategyState record
  - [ ] Output: state

- [ ] 3.1.2 Create ContentStrategy::Commands::LoadPostingHistory
  - [ ] Input: persona
  - [ ] Query recent posts
  - [ ] Output: posting_history

- [ ] 3.1.3 Create ContentStrategy::Commands::SelectStrategy
  - [ ] Input: state
  - [ ] Get strategy name from state
  - [ ] Lookup strategy class from Registry
  - [ ] Instantiate with config
  - [ ] Output: strategy

- [ ] 3.1.4 Create ContentStrategy::Commands::SelectCluster
  - [ ] Input: strategy, context
  - [ ] Call strategy.select_cluster
  - [ ] Handle NoAvailableClustersError
  - [ ] Output: cluster

- [ ] 3.1.5 Create ContentStrategy::Commands::SelectPhoto
  - [ ] Input: strategy, cluster, context
  - [ ] Call strategy.select_photo
  - [ ] Handle NoUnpostedPhotosError
  - [ ] Output: photo

- [ ] 3.1.6 Create ContentStrategy::Commands::CalculateOptimalTime
  - [ ] Input: strategy, scheduled_date, context
  - [ ] Call strategy.optimal_posting_time
  - [ ] Apply timezone conversions
  - [ ] Output: optimal_time

- [ ] 3.1.7 Create ContentStrategy::Commands::GenerateHashtags
  - [ ] Input: strategy, photo, cluster, context
  - [ ] Call strategy.generate_hashtags
  - [ ] Output: hashtags

- [ ] 3.1.8 Create ContentStrategy::Commands::UpdateStrategyState
  - [ ] Input: strategy, photo, cluster, context
  - [ ] Call strategy lifecycle hooks
  - [ ] Update state in database
  - [ ] Invalidate cache
  - [ ] Create history record

- [ ] 3.1.9 Create ContentStrategy::SelectNextPost chain
  - [ ] Require: persona
  - [ ] Return: photo, caption, scheduled_at, cluster, hashtags
  - [ ] Chain all commands in sequence

- [ ] 3.1.10 Write command chain specs

### 3.2 Scheduler Integration

- [ ] 3.2.1 Create feature flag: content_strategy_enabled
  - [ ] Add to configuration
  - [ ] Default: false
  - [ ] Per-persona override support

- [ ] 3.2.2 Modify posting rake task
  - [ ] Check feature flag for persona
  - [ ] If enabled: Use ContentStrategy::SelectNextPost
  - [ ] If disabled: Use existing logic
  - [ ] Log strategy usage

- [ ] 3.2.3 Update Scheduling::SchedulePost command
  - [ ] Accept cluster_id parameter (optional)
  - [ ] Accept strategy_name parameter (optional)
  - [ ] Accept optimal_time_calculated parameter (optional)
  - [ ] Accept hashtags parameter (optional)
  - [ ] Store in scheduling_posts table

- [ ] 3.2.4 Write scheduler integration specs

### 3.3 Configuration Management

- [ ] 3.3.1 Create CLI command: content_strategy:configure
  - [ ] Accept persona parameter
  - [ ] Accept strategy name
  - [ ] Accept configuration YAML/options
  - [ ] Create or update StrategyState
  - [ ] Validate configuration

- [ ] 3.3.2 Create CLI command: content_strategy:status
  - [ ] Show active strategy per persona
  - [ ] Show current state summary
  - [ ] Show recent posting history
  - [ ] Show upcoming posts

- [ ] 3.3.3 Write CLI command specs

### 3.4 Error Handling & Fallbacks

- [ ] 3.4.1 Implement fallback mechanism in SelectNextPost
  - [ ] Try primary strategy
  - [ ] On NoAvailableClustersError: Relax variety rules
  - [ ] On NoUnpostedPhotosError: Notify and raise
  - [ ] On other errors: Log and fallback to simple selection

- [ ] 3.4.2 Create simple fallback strategy
  - [ ] Select random cluster with unposted photos
  - [ ] No state management
  - [ ] Basic timing (current time + 1 hour)

- [ ] 3.4.3 Write fallback specs

## PHASE 4: Observability & Polish (Week 4)

### 4.1 Logging

- [ ] 4.1.1 Create ContentStrategy::Logger service
  - [ ] Implement log_selection
  - [ ] Implement log_timing_calculation
  - [ ] Implement log_strategy_switch
  - [ ] Implement log_error
  - [ ] Use structured logging (JSON)

- [ ] 4.1.2 Add logging throughout
  - [ ] Log strategy selection in SelectStrategy
  - [ ] Log cluster selection in SelectCluster
  - [ ] Log photo selection in SelectPhoto
  - [ ] Log timing calculation
  - [ ] Log state updates
  - [ ] Log errors with context

- [ ] 4.1.3 Configure log levels
  - [ ] Info for normal operations
  - [ ] Warn for fallbacks
  - [ ] Error for failures

### 4.2 Metrics

- [ ] 4.2.1 Create ContentStrategy::Metrics service
  - [ ] Implement track_selection(strategy_name, cluster_id)
  - [ ] Implement track_timing(overhead_ms)
  - [ ] Implement track_posting_frequency(persona_id, count)
  - [ ] Implement track_variety_score(persona_id, score)

- [ ] 4.2.2 Add metrics throughout
  - [ ] Track strategy usage
  - [ ] Track cluster rotation
  - [ ] Track selection duration
  - [ ] Track state cache hits/misses

- [ ] 4.2.3 (Optional) Set up monitoring dashboard

### 4.3 Audit Trail

- [ ] 4.3.1 Enhance history records
  - [ ] Store decision_context with:
    - [ ] Available clusters
    - [ ] Recent clusters
    - [ ] Variety score
    - [ ] Selection reason
    - [ ] Optimal time window
    - [ ] Posts this week

- [ ] 4.3.2 Create admin query interface
  - [ ] Query history by persona
  - [ ] Query history by cluster
  - [ ] Query history by date range
  - [ ] Export to CSV

### 4.4 Documentation

- [ ] 4.4.1 Write README for content_strategy pack
  - [ ] Overview and purpose
  - [ ] Architecture summary
  - [ ] Strategy descriptions
  - [ ] Configuration guide
  - [ ] Integration points

- [ ] 4.4.2 Document configuration options
  - [ ] All YAML parameters
  - [ ] Defaults and ranges
  - [ ] Per-persona overrides
  - [ ] Examples

- [ ] 4.4.3 Create strategy extension guide
  - [ ] How to create new strategies
  - [ ] BaseStrategy interface
  - [ ] Registration process
  - [ ] Testing guidelines

- [ ] 4.4.4 Write operational runbook
  - [ ] Enabling/disabling feature flag
  - [ ] Monitoring health
  - [ ] Debugging issues
  - [ ] Common problems and solutions

### 4.5 Testing & Validation

- [ ] 4.5.1 Write integration tests
  - [ ] Full flow: persona → photo selection
  - [ ] Multiple strategies
  - [ ] State persistence across selections
  - [ ] Variety enforcement
  - [ ] Timing optimization

- [ ] 4.5.2 Write end-to-end tests
  - [ ] Enable feature flag
  - [ ] Trigger posting rake task
  - [ ] Verify strategy usage
  - [ ] Verify optimal time
  - [ ] Verify variety
  - [ ] Verify state updates

- [ ] 4.5.3 Performance testing
  - [ ] Measure strategy selection time
  - [ ] Measure state query time
  - [ ] Measure total overhead
  - [ ] Verify < 200ms target

- [ ] 4.5.4 Load testing (optional)
  - [ ] Multiple personas simultaneously
  - [ ] Redis cache behavior
  - [ ] Database query performance

### 4.6 Deployment Preparation

- [ ] 4.6.1 Review all specs (ensure 100% pass)
- [ ] 4.6.2 Run linter and fix issues
- [ ] 4.6.3 Review code for security issues
- [ ] 4.6.4 Update CHANGELOG
- [ ] 4.6.5 Create deployment checklist
  - [ ] Run migrations
  - [ ] Deploy code
  - [ ] Enable feature flag for test persona
  - [ ] Monitor for 24 hours
  - [ ] Gradually enable for more personas
  - [ ] Full rollout after 1 week

### 4.7 Rollout & Monitoring

- [ ] 4.7.1 Deploy to staging
  - [ ] Run migrations
  - [ ] Test with test personas
  - [ ] Verify logs and metrics

- [ ] 4.7.2 Deploy to production
  - [ ] Run migrations
  - [ ] Feature flag OFF initially
  - [ ] Monitor application health

- [ ] 4.7.3 Enable for test persona
  - [ ] Set feature flag for 1 persona
  - [ ] Monitor for 48 hours
  - [ ] Check logs for errors
  - [ ] Verify optimal timing
  - [ ] Verify variety enforcement

- [ ] 4.7.4 Gradual rollout
  - [ ] Enable for 5 more personas
  - [ ] Monitor for 1 week
  - [ ] Enable for 25% of personas
  - [ ] Monitor for 1 week
  - [ ] Enable for 50% of personas
  - [ ] Monitor for 1 week
  - [ ] Enable for all personas

- [ ] 4.7.5 Post-deployment validation
  - [ ] All success metrics met
  - [ ] No production errors
  - [ ] Performance targets achieved
  - [ ] User feedback positive

## Notes

- Each checkbox represents an atomic task
- Total estimated effort: 4 weeks
- Dependencies marked implicitly by phase ordering
- All tasks should include tests where applicable
- Code review required before merging to main
- Feature flag allows safe rollout and rollback
