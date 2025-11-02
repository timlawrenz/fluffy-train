# Content Strategy Engine - Architecture Design Document

**Status:** Research Phase  
**Date:** November 2, 2024  
**Version:** 1.0

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [System Context](#system-context)
3. [Architecture Decision](#architecture-decision)
4. [Strategy Pattern Design](#strategy-pattern-design)
5. [State Management](#state-management)
6. [Integration Points](#integration-points)
7. [Data Models](#data-models)
8. [Strategy Implementations](#strategy-implementations)
9. [Configuration Schema](#configuration-schema)
10. [Error Handling](#error-handling)
11. [Observability](#observability)
12. [Migration Plan](#migration-plan)

---

## Executive Summary

The Content Strategy Engine bridges cluster-based image organization with automated content distribution by encoding Instagram best practices as executable strategies. This document details the technical architecture for implementing intelligent, domain-knowledge-driven content selection.

**Key Architectural Decisions:**
- **Pattern:** Class-based strategy pattern with shared base class
- **State:** Database-backed state management with Redis caching
- **Configuration:** YAML-based with Ruby DSL for complex rules
- **Integration:** Service layer between scheduler and cluster management
- **Extensibility:** Plugin-like strategy registration system

**Core Capabilities:**
- Optimal posting time calculation
- Content variety enforcement (minimum 2-3 days between similar themes)
- Format optimization (Reels vs carousels)
- Posting frequency control (3-5 posts/week)
- Content pillar rotation
- Hashtag generation and rotation

---

## System Context

### Current System (Milestones 3, 4a, 4b)

**Milestone 3: Automated Posting**
- Scheduler: `Scheduling::SchedulePost` command chain
- Post Model: `Scheduling::Post` with state machine
- Current flow: Photo → Caption → Instagram API

**Milestone 4a/4b: Clustering**
- Cluster Model: `Clustering::Cluster` with photo associations
- Photos have `cluster_id` foreign key
- Commands: `ListClusters`, `ViewCluster`, `RenameCluster`

**Current Database Schema:**
```ruby
clusters (id, name, status, photos_count)
photos (id, persona_id, path, embedding, cluster_id)
scheduling_posts (id, photo_id, persona_id, caption, status, posted_at)
```

### New System: Content Strategy Engine (Milestone 4c)

Sits between scheduler and cluster management:
```
Scheduler → Strategy Engine → Cluster Selection → Photo Selection → Post Creation
```

---

## Architecture Decision

### Decision: Class-Based Strategy Pattern

**Rationale:**
- Ruby/Rails convention: prefer classes over complex modules
- Clear inheritance hierarchy
- Easy testing and mocking
- Familiar pattern to Rails developers
- Supports both configuration and programmatic behavior

### Alternatives Considered

**Option A: Module-Based (Rejected)**
- Pros: Flexible composition, multiple concerns
- Cons: Less discoverable, harder to enforce interface contracts
- Why rejected: Too abstract for this domain

**Option B: Rails Engine/Plugin (Rejected)**
- Pros: Full isolation, separate gem
- Cons: Overkill for initial implementation, deployment complexity
- Why rejected: Premature abstraction

**Option C: Functional Composition (Rejected)**
- Pros: Stateless, easy to test in isolation
- Cons: Doesn't fit Rails conventions, harder state management
- Why rejected: Fights framework conventions

### Chosen Pattern: Class-Based Strategy

**Benefits:**
- Single responsibility per strategy
- Clear interface contract via base class
- Easy to add new strategies
- Natural fit for Rails
- Can mix in shared concerns (e.g., TimingOptimization, VarietyEnforcement)

**Trade-offs:**
- More files to manage
- Requires registration system
- Class loading considerations

---

## Strategy Pattern Design

### Base Strategy Class

```ruby
module ContentStrategy
  class BaseStrategy
    # Interface contract - all strategies must implement these
    
    # Core selection methods
    def select_cluster(available_clusters, context)
      raise NotImplementedError
    end
    
    def select_photo(cluster, context)
      raise NotImplementedError
    end
    
    # Domain knowledge application
    def optimal_posting_time(scheduled_date, context)
      # Default implementation based on research
      TimingEngine.calculate_optimal_time(scheduled_date, context)
    end
    
    def generate_hashtags(photo, cluster, context)
      # Default implementation
      HashtagEngine.generate(photo, cluster, count: config.hashtag_count)
    end
    
    def enforce_variety?(cluster, context)
      # Check if cluster was used recently
      VarietyEnforcer.check(cluster, context.posting_history, config.variety_gap_days)
    end
    
    # Configuration and lifecycle
    def initialize(config = {})
      @config = StrategyConfig.new(config)
    end
    
    def validate_config!
      # Validate strategy-specific configuration
      true
    end
    
    # State management hooks
    def on_photo_selected(photo, cluster, context)
      # Hook for tracking selections
    end
    
    def on_post_scheduled(post, context)
      # Hook for updating state
    end
    
    def on_post_completed(post, context)
      # Hook for analytics
    end
    
    protected
    
    attr_reader :config
  end
end
```

### Strategy Registration System

```ruby
module ContentStrategy
  class Registry
    @strategies = {}
    
    class << self
      def register(name, strategy_class)
        @strategies[name.to_sym] = strategy_class
      end
      
      def get(name)
        @strategies[name.to_sym] || raise(UnknownStrategyError, name)
      end
      
      def list
        @strategies.keys
      end
    end
  end
end

# Usage in strategy files:
ContentStrategy::Registry.register(:theme_of_week, ThemeOfWeekStrategy)
```

### Shared Concerns/Modules

```ruby
module ContentStrategy
  module TimingOptimization
    # Encodes Instagram domain knowledge from research
    OPTIMAL_WINDOWS = {
      monday: ['05:00-08:00', '15:00-16:00'],
      tuesday: ['05:00-08:00', '11:00-18:00'],
      wednesday: ['17:00-17:00', '10:00-18:00'],
      thursday: ['16:00-17:00', '11:00-18:00'],
      friday: ['16:00-16:00', '11:00-14:00'],
      saturday: ['11:00-11:00', '10:00-13:00'],
      sunday: ['12:00-15:00', '19:00-19:00']
    }.freeze
    
    def calculate_optimal_time(date, preferred_time = nil)
      # Implementation using research data
    end
  end
  
  module VarietyEnforcement
    def recent_clusters(days: 7)
      # Query posting history
    end
    
    def days_since_cluster_used(cluster_id)
      # Calculate gap
    end
    
    def variety_score(cluster, history)
      # Score based on recency and similarity
    end
  end
  
  module FormatOptimization
    def recommend_format(photo, context)
      # Based on account size, recent formats, content type
      # Returns: :reel, :carousel, :static
    end
  end
end
```

---

## State Management

### Database Schema

**New Table: `content_strategy_state`**
```ruby
create_table :content_strategy_state do |t|
  t.references :persona, null: false
  t.string :active_strategy, null: false
  t.jsonb :strategy_config
  t.jsonb :state_data
  t.datetime :started_at
  t.timestamps
end

add_index :content_strategy_state, [:persona_id], unique: true
```

**New Table: `content_strategy_history`**
```ruby
create_table :content_strategy_history do |t|
  t.references :persona, null: false
  t.references :post, null: false
  t.references :cluster, null: true
  t.string :strategy_name
  t.jsonb :decision_context
  t.datetime :created_at
end

add_index :content_strategy_history, [:persona_id, :created_at]
add_index :content_strategy_history, [:cluster_id, :created_at]
```

**Updates to Existing Tables:**
```ruby
add_column :scheduling_posts, :cluster_id, :bigint
add_column :scheduling_posts, :strategy_name, :string
add_column :scheduling_posts, :optimal_time_calculated, :datetime
add_column :scheduling_posts, :hashtags, :jsonb, default: []

add_index :scheduling_posts, :cluster_id
add_index :scheduling_posts, :strategy_name
```

### State Data Structure

**StrategyState Model:**
```ruby
module ContentStrategy
  class StrategyState < ApplicationRecord
    self.table_name = 'content_strategy_state'
    
    belongs_to :persona
    
    # Strategy-specific state stored in state_data JSONB:
    # {
    #   "theme_of_week": {
    #     "current_cluster_id": 42,
    #     "started_at": "2024-11-01",
    #     "posts_count": 3,
    #     "week_number": 44
    #   },
    #   "thematic_rotation": {
    #     "rotation_order": [1, 5, 3, 8],
    #     "current_index": 2,
    #     "last_rotated_at": "2024-11-01"
    #   },
    #   "posting_frequency": {
    #     "posts_this_week": 3,
    #     "week_start": "2024-10-28"
    #   },
    #   "variety_tracking": {
    #     "recent_clusters": [
    #       {"cluster_id": 5, "posted_at": "2024-10-30"},
    #       {"cluster_id": 3, "posted_at": "2024-10-28"}
    #     ]
    #   }
    # }
    
    def get_state(key)
      state_data&.dig(key.to_s)
    end
    
    def set_state(key, value)
      self.state_data ||= {}
      self.state_data[key.to_s] = value
      save!
    end
    
    def update_state(key, updates)
      current = get_state(key) || {}
      set_state(key, current.merge(updates))
    end
  end
end
```

### Redis Caching Layer

```ruby
module ContentStrategy
  class StateCache
    def self.cache_key(persona_id)
      "content_strategy:state:#{persona_id}"
    end
    
    def self.get(persona_id)
      cached = Rails.cache.read(cache_key(persona_id))
      return cached if cached
      
      state = StrategyState.find_by(persona_id: persona_id)
      Rails.cache.write(cache_key(persona_id), state, expires_in: 5.minutes)
      state
    end
    
    def self.invalidate(persona_id)
      Rails.cache.delete(cache_key(persona_id))
    end
  end
end
```

---

## Integration Points

### 1. Scheduler Integration

**Current Flow:**
```
Rake task → SchedulePost → CreatePostRecord → SendToInstagram
```

**New Flow:**
```
Rake task → ContentStrategyEngine.select_next_post →
  → Strategy.select_cluster →
  → Strategy.select_photo →
  → Strategy.optimize_timing →
  → SchedulePost
```

**New Command: `SelectNextPost`**
```ruby
module ContentStrategy
  class SelectNextPost < GLCommand::Chainable
    requires persona: Persona
    returns photo: Photo, caption: String, scheduled_at: DateTime, 
            cluster: Clustering::Cluster, hashtags: Array
    
    chain Commands::LoadStrategyState,
          Commands::LoadPostingHistory,
          Commands::SelectStrategy,
          Commands::SelectCluster,
          Commands::SelectPhoto,
          Commands::CalculateOptimalTime,
          Commands::GenerateHashtags,
          Commands::UpdateStrategyState
  end
end
```

### 2. Cluster Management Integration

**Required Queries:**
```ruby
module Clustering
  class Cluster
    # New scopes for strategy engine
    scope :available_for_posting, -> {
      where(status: :active)
        .where('photos_count > 0')
    }
    
    scope :with_unposted_photos, -> {
      joins(:photos)
        .where.not(photos: { id: Scheduling::Post.posted.select(:photo_id) })
        .distinct
    }
    
    def unposted_photos
      photos.where.not(id: Scheduling::Post.posted.select(:photo_id))
    end
    
    def last_posted_at
      Scheduling::Post.posted
        .joins(:photo)
        .where(photos: { cluster_id: id })
        .maximum(:posted_at)
    end
  end
end
```

### 3. Photo Selection Integration

```ruby
module Clustering
  class Photo
    scope :unposted, -> {
      where.not(id: Scheduling::Post.posted.select(:photo_id))
    }
    
    scope :in_cluster, ->(cluster_id) {
      where(cluster_id: cluster_id)
    }
    
    def posted?
      Scheduling::Post.posted.exists?(photo_id: id)
    end
  end
end
```

### 4. Posting History Integration

```ruby
module ContentStrategy
  class PostingHistory
    def initialize(persona)
      @persona = persona
    end
    
    def recent_posts(days: 14)
      Scheduling::Post.posted
        .where(persona: @persona)
        .where('posted_at >= ?', days.days.ago)
        .includes(:cluster, :photo)
        .order(posted_at: :desc)
    end
    
    def posts_this_week
      start_of_week = Time.current.beginning_of_week
      Scheduling::Post.posted
        .where(persona: @persona)
        .where('posted_at >= ?', start_of_week)
        .count
    end
    
    def cluster_usage_history(days: 14)
      recent_posts(days: days)
        .group(:cluster_id)
        .pluck(:cluster_id, Arel.sql('MAX(posted_at) as last_used'))
        .to_h
    end
  end
end
```

---

## Data Models

### StrategyConfig

```ruby
module ContentStrategy
  class StrategyConfig
    include ActiveModel::Model
    include ActiveModel::Attributes
    
    # Posting frequency
    attribute :posts_per_week, :integer, default: 4
    attribute :minimum_gap_days, :integer, default: 1
    
    # Timing
    attribute :timezone, :string, default: 'UTC'
    attribute :preferred_posting_windows, default: {}
    attribute :use_optimal_timing, :boolean, default: true
    
    # Variety
    attribute :variety_gap_days, :integer, default: 3
    attribute :track_history_days, :integer, default: 14
    
    # Format
    attribute :format_preferences, default: { reels: 40, carousels: 30, static: 30 }
    
    # Hashtags
    attribute :hashtag_count, :integer, default: 8
    attribute :hashtag_rotation, :boolean, default: true
    
    # Content pillars
    attribute :content_pillars, default: []
    attribute :pillar_rotation_pattern, :string, default: '3-1-3-1'
    
    validates :posts_per_week, numericality: { greater_than: 0, less_than_or_equal_to: 7 }
    validates :variety_gap_days, numericality: { greater_than_or_equal_to: 0 }
    validates :hashtag_count, numericality: { in: 5..12 }
    
    def self.from_yaml(yaml_string)
      data = YAML.safe_load(yaml_string, permitted_classes: [Symbol])
      new(data)
    end
  end
end
```

### Context Object

```ruby
module ContentStrategy
  class Context
    attr_reader :persona, :posting_history, :state, :current_time
    
    def initialize(persona:, current_time: Time.current)
      @persona = persona
      @current_time = current_time
      @state = StateCache.get(persona.id)
      @posting_history = PostingHistory.new(persona)
    end
    
    def available_clusters
      @available_clusters ||= Clustering::Cluster
        .available_for_posting
        .with_unposted_photos
    end
    
    def recent_cluster_ids
      @recent_cluster_ids ||= posting_history
        .cluster_usage_history(days: state_config.track_history_days)
        .keys
    end
    
    def posts_this_week
      posting_history.posts_this_week
    end
    
    def state_config
      @state_config ||= StrategyConfig.new(state.strategy_config || {})
    end
  end
end
```

---

## Strategy Implementations

### Theme of the Week Strategy

```ruby
module ContentStrategy
  class ThemeOfWeekStrategy < BaseStrategy
    ContentStrategy::Registry.register(:theme_of_week, self)
    
    def select_cluster(available_clusters, context)
      # If we have an active theme, continue with it
      current_cluster_id = context.state.get_state('theme_of_week')&.dig('current_cluster_id')
      
      if current_cluster_id && week_active?(context)
        cluster = available_clusters.find { |c| c.id == current_cluster_id }
        return cluster if cluster&.unposted_photos&.any?
      end
      
      # Need new theme - select cluster respecting variety rules
      select_new_theme(available_clusters, context)
    end
    
    def select_photo(cluster, context)
      # Select best photo from cluster based on quality scores
      cluster.unposted_photos
        .joins(:photo_analysis)
        .order('photo_analyses.aesthetic_score DESC NULLS LAST')
        .first
    end
    
    def on_photo_selected(photo, cluster, context)
      # Update state to track theme of the week
      context.state.update_state('theme_of_week', {
        'current_cluster_id' => cluster.id,
        'started_at' => context.current_time,
        'posts_count' => (current_posts_count(context) + 1),
        'week_number' => context.current_time.strftime('%U').to_i
      })
    end
    
    private
    
    def week_active?(context)
      theme_state = context.state.get_state('theme_of_week')
      return false unless theme_state
      
      started_week = theme_state['week_number']
      current_week = context.current_time.strftime('%U').to_i
      
      started_week == current_week
    end
    
    def select_new_theme(available_clusters, context)
      # Filter out recently used clusters
      recent_ids = context.recent_cluster_ids
      candidates = available_clusters.reject { |c| recent_ids.include?(c.id) }
      
      # If all clusters recently used, use least recent
      candidates = available_clusters if candidates.empty?
      
      # Select cluster with most unposted photos
      candidates.max_by { |c| c.unposted_photos.count }
    end
    
    def current_posts_count(context)
      context.state.get_state('theme_of_week')&.dig('posts_count') || 0
    end
  end
end
```

### Thematic Rotation Strategy

```ruby
module ContentStrategy
  class ThematicRotationStrategy < BaseStrategy
    ContentStrategy::Registry.register(:thematic_rotation, self)
    
    def select_cluster(available_clusters, context)
      rotation_state = context.state.get_state('thematic_rotation') || {}
      
      # Initialize rotation if needed
      if rotation_state.empty? || rotation_order_changed?(rotation_state, available_clusters)
        initialize_rotation(available_clusters, context)
        rotation_state = context.state.get_state('thematic_rotation')
      end
      
      # Get next cluster in rotation
      current_index = rotation_state['current_index'] || 0
      rotation_order = rotation_state['rotation_order'] || []
      
      cluster_id = rotation_order[current_index]
      cluster = available_clusters.find { |c| c.id == cluster_id }
      
      # If cluster exhausted or deleted, move to next
      unless cluster&.unposted_photos&.any?
        return advance_rotation(available_clusters, context)
      end
      
      cluster
    end
    
    def select_photo(cluster, context)
      # Vary selection - alternate between best and random
      photos = cluster.unposted_photos.joins(:photo_analysis)
      
      selection_mode = context.state.get_state('thematic_rotation')&.dig('selection_mode') || 'best'
      
      if selection_mode == 'best'
        photos.order('photo_analyses.aesthetic_score DESC NULLS LAST').first
      else
        photos.order('RANDOM()').first
      end
    end
    
    def on_photo_selected(photo, cluster, context)
      # Advance to next cluster in rotation
      advance_rotation(context.available_clusters, context)
      
      # Toggle selection mode
      current_mode = context.state.get_state('thematic_rotation')&.dig('selection_mode') || 'best'
      new_mode = current_mode == 'best' ? 'random' : 'best'
      
      context.state.update_state('thematic_rotation', {
        'selection_mode' => new_mode,
        'last_rotated_at' => context.current_time
      })
    end
    
    private
    
    def initialize_rotation(available_clusters, context)
      # Create rotation order - prioritize clusters with more photos
      order = available_clusters
        .sort_by { |c| -c.unposted_photos.count }
        .map(&:id)
      
      context.state.set_state('thematic_rotation', {
        'rotation_order' => order,
        'current_index' => 0,
        'initialized_at' => context.current_time
      })
    end
    
    def advance_rotation(available_clusters, context)
      rotation_state = context.state.get_state('thematic_rotation')
      current_index = rotation_state['current_index']
      rotation_order = rotation_state['rotation_order']
      
      next_index = (current_index + 1) % rotation_order.length
      
      context.state.update_state('thematic_rotation', {
        'current_index' => next_index
      })
      
      # Return next cluster
      cluster_id = rotation_order[next_index]
      available_clusters.find { |c| c.id == cluster_id }
    end
    
    def rotation_order_changed?(rotation_state, available_clusters)
      existing_order = rotation_state['rotation_order'] || []
      current_ids = available_clusters.map(&:id).sort
      existing_order.sort != current_ids
    end
  end
end
```

---

## Configuration Schema

### YAML Configuration Format

```yaml
# config/content_strategy.yml
default: &default
  posts_per_week: 4
  minimum_gap_days: 1
  
  timing:
    timezone: 'America/New_York'
    use_optimal_timing: true
    preferred_windows:
      monday: ['06:00-08:00', '15:00-16:00']
      tuesday: ['06:00-08:00', '12:00-18:00']
      # ... other days
  
  variety:
    gap_days: 3
    track_history_days: 14
  
  format:
    preferences:
      reels: 40
      carousels: 30
      static: 30
  
  hashtags:
    count: 8
    rotation: true
    mix:
      popular: 2
      medium: 3
      niche: 3
  
  content_pillars:
    - name: 'inspiration'
      clusters: [1, 2, 3]
    - name: 'education'
      clusters: [4, 5]
    - name: 'behind_scenes'
      clusters: [6]
  
  pillar_rotation_pattern: '3-1-3-1'

development:
  <<: *default

production:
  <<: *default
  posts_per_week: 5
  variety:
    gap_days: 2
```

### Configuration Loader

```ruby
module ContentStrategy
  class ConfigLoader
    def self.load(environment = Rails.env)
      config_path = Rails.root.join('config', 'content_strategy.yml')
      yaml = YAML.load_file(config_path, permitted_classes: [Symbol])
      StrategyConfig.new(yaml[environment] || yaml['default'])
    end
  end
end
```

---

## Error Handling

### Error Classes

```ruby
module ContentStrategy
  class Error < StandardError; end
  
  class UnknownStrategyError < Error; end
  class NoAvailableClustersError < Error; end
  class NoUnpostedPhotosError < Error; end
  class InvalidConfigurationError < Error; end
  class StrategyStateError < Error; end
end
```

### Fallback Mechanisms

```ruby
module ContentStrategy
  class SelectNextPost
    def call
      # Try primary strategy
      begin
        execute_strategy
      rescue NoAvailableClustersError => e
        log_error(e)
        fallback_to_any_cluster
      rescue NoUnpostedPhotosError => e
        log_error(e)
        notify_user_no_content
        raise
      rescue StandardError => e
        log_error(e)
        fallback_to_simple_selection
      end
    end
    
    private
    
    def fallback_to_any_cluster
      # Ignore variety rules, select any cluster with photos
    end
    
    def fallback_to_simple_selection
      # Use SimplestStrategy - just pick random available photo
    end
  end
end
```

---

## Observability

### Logging

```ruby
module ContentStrategy
  class Logger
    def self.log_selection(strategy:, cluster:, photo:, context:)
      Rails.logger.info({
        event: 'content_strategy.selection',
        strategy: strategy.class.name,
        cluster_id: cluster.id,
        cluster_name: cluster.name,
        photo_id: photo.id,
        persona_id: context.persona.id,
        posts_this_week: context.posts_this_week,
        variety_gap_days: context.state_config.variety_gap_days,
        timestamp: Time.current
      }.to_json)
    end
    
    def self.log_timing_calculation(scheduled_time:, optimal_time:, context:)
      Rails.logger.info({
        event: 'content_strategy.timing',
        scheduled_time: scheduled_time,
        optimal_time: optimal_time,
        day_of_week: optimal_time.strftime('%A'),
        timezone: context.state_config.timezone
      }.to_json)
    end
  end
end
```

### Metrics

```ruby
module ContentStrategy
  class Metrics
    def self.track_selection(strategy_name, cluster_id)
      # Track with Prometheus/StatsD
      increment("content_strategy.selections.#{strategy_name}")
      increment("content_strategy.cluster_usage.#{cluster_id}")
    end
    
    def self.track_posting_frequency(persona_id, posts_count)
      gauge("content_strategy.posts_this_week", posts_count, tags: ["persona:#{persona_id}"])
    end
  end
end
```

### Audit Trail

```ruby
module ContentStrategy
  class HistoryRecord < ApplicationRecord
    self.table_name = 'content_strategy_history'
    
    belongs_to :persona
    belongs_to :post, class_name: 'Scheduling::Post'
    belongs_to :cluster, class_name: 'Clustering::Cluster', optional: true
    
    # decision_context JSONB stores:
    # {
    #   "available_clusters": [1, 2, 3],
    #   "recent_clusters": [5, 8],
    #   "variety_score": 0.8,
    #   "selection_reason": "highest_unposted_count",
    #   "optimal_time_window": "06:00-08:00",
    #   "posts_this_week": 3
    # }
  end
end
```

---

## Migration Plan

### Phase 1: Foundation (Week 1)
- [ ] Create database migrations
- [ ] Implement BaseStrategy and Registry
- [ ] Build StrategyState and Context models
- [ ] Add shared concerns (TimingOptimization, VarietyEnforcement)
- [ ] Write unit tests for base components

### Phase 2: Core Strategies (Week 2)
- [ ] Implement ThemeOfWeekStrategy
- [ ] Implement ThematicRotationStrategy
- [ ] Add integration with Cluster model
- [ ] Implement PostingHistory queries
- [ ] Write integration tests

### Phase 3: Integration (Week 3)
- [ ] Create SelectNextPost command chain
- [ ] Integrate with scheduler
- [ ] Add configuration system
- [ ] Implement error handling and fallbacks
- [ ] Write end-to-end tests

### Phase 4: Observability (Week 4)
- [ ] Add logging throughout
- [ ] Implement metrics tracking
- [ ] Create audit trail system
- [ ] Build admin UI for viewing strategy state
- [ ] Performance testing

### Deployment Strategy

**Staged Rollout:**
1. Deploy with feature flag disabled
2. Enable for test persona only
3. Monitor for 1 week
4. Gradually enable for more personas
5. Full rollout after 2 weeks of monitoring

**Rollback Plan:**
- Feature flag can disable immediately
- Falls back to simple photo selection
- No data loss - state preserved
- Can re-enable anytime

---

## Next Steps

1. **Review and approve** this architecture design
2. **Create implementation proposal** with detailed tasks
3. **Define acceptance criteria** for each component
4. **Begin Phase 1 implementation** with foundation

---

## Appendix

### Sequence Diagram: Theme of the Week Flow

```
User/Scheduler → SelectNextPost
                   ↓
                 LoadStrategyState
                   ↓
                 LoadPostingHistory
                   ↓
                 SelectStrategy → ThemeOfWeekStrategy
                   ↓
                 SelectCluster
                   ├→ Check current theme active?
                   │   ├→ Yes: Use current cluster
                   │   └→ No: Select new theme
                   │       ├→ Filter recently used
                   │       └→ Pick cluster with most photos
                   ↓
                 SelectPhoto
                   └→ Pick highest aesthetic score
                   ↓
                 CalculateOptimalTime
                   └→ Apply domain knowledge
                   ↓
                 GenerateHashtags
                   └→ Mix popular/niche tags
                   ↓
                 UpdateStrategyState
                   └→ Record theme usage
                   ↓
                 Return → SchedulePost
```

### Technology Stack

- **Framework:** Ruby on Rails 8.0
- **Database:** PostgreSQL 16
- **Cache:** Redis
- **Background Jobs:** Solid Queue
- **Testing:** RSpec
- **Monitoring:** Rails logger + optional external metrics

### Performance Considerations

- Strategy selection: < 100ms
- State queries: Cached in Redis (< 10ms)
- History queries: Indexed, < 50ms
- Total overhead: < 200ms per post selection

### Security Considerations

- Strategy configs stored in database (encrypted at rest)
- No sensitive data in logs
- State access scoped to persona
- Admin UI requires authentication
