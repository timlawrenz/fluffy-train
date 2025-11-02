# Content Strategy Engine

The Content Strategy Engine intelligently selects and schedules Instagram content using proven best practices derived from analyzing 10M+ posts. It bridges cluster-based image organization with automated content distribution.

## Overview

This system encodes Instagram domain knowledge into executable strategies that:
- Select optimal posting times (5-8am, 10am-3pm windows)
- Enforce content variety (2-3 day gaps between similar themes)
- Generate relevant hashtags (5-12 tags per post)
- Manage posting frequency (3-5 posts/week)
- Apply format recommendations (Reels vs Carousels)

## Quick Start

### Basic Usage

```ruby
# Select next post using default strategy
persona = Persona.find(1)
result = ContentStrategy::SelectNextPost.new(persona: persona).call

if result[:success]
  photo = result[:photo]
  cluster = result[:cluster]
  optimal_time = result[:optimal_time]
  hashtags = result[:hashtags]
  
  # Create post with recommended settings
  Scheduling::Post.create!(
    persona: persona,
    photo: photo,
    cluster: cluster,
    scheduled_at: optimal_time,
    hashtags: hashtags
  )
else
  puts "Error: #{result[:error]}"
end
```

### Using Specific Strategy

```ruby
# Use Theme of Week strategy
result = ContentStrategy::SelectNextPost.new(
  persona: persona,
  strategy_name: :theme_of_week_strategy
).call

# Use Thematic Rotation strategy
result = ContentStrategy::SelectNextPost.new(
  persona: persona,
  strategy_name: :thematic_rotation_strategy
).call
```

## Available Strategies

### Theme of Week Strategy

Focuses on one cluster (theme) for an entire week, then switches to a new theme.

**Best for:**
- Building consistent narrative
- Deep exploration of a theme
- Establishing visual identity

**Behavior:**
- Selects one cluster at the start of each week
- Posts 3-5 photos from that cluster during the week
- Automatically switches to new cluster on week boundary
- Enforces variety rules when selecting new themes

**State Tracking:**
```ruby
state = ContentStrategy::StrategyState.find_by(persona: persona)
state.get_state(:week_number)  # => "2025-W44"
state.get_state(:cluster_id)   # => 123
```

### Thematic Rotation Strategy

Rotates through available clusters, posting from different themes each time.

**Best for:**
- Diverse content feed
- Showcasing variety
- Testing multiple themes

**Behavior:**
- Maintains rotation index across clusters
- Advances to next cluster after each post
- Applies variety enforcement
- Alternates between best quality and random selection

**State Tracking:**
```ruby
state = ContentStrategy::StrategyState.find_by(persona: persona)
state.get_state(:rotation_index)  # => 5
```

## Configuration

Edit `config/content_strategy.yml`:

```yaml
development:
  # Posting frequency (per week)
  posting_frequency_min: 3
  posting_frequency_max: 5
  posting_days_gap: 1

  # Optimal posting times (local timezone)
  optimal_time_start_hour: 5
  optimal_time_end_hour: 8
  alternative_time_start_hour: 10
  alternative_time_end_hour: 15
  timezone: "UTC"

  # Content variety rules
  variety_min_days_gap: 2
  variety_max_same_cluster: 3

  # Hashtag strategy
  hashtag_count_min: 5
  hashtag_count_max: 12

  # Format preferences
  format_prefer_reels: false
  format_prefer_carousels: true
```

### Configuration Reference

| Setting | Default | Description |
|---------|---------|-------------|
| `posting_frequency_min` | 3 | Minimum posts per week |
| `posting_frequency_max` | 5 | Maximum posts per week |
| `posting_days_gap` | 1 | Minimum days between posts |
| `optimal_time_start_hour` | 5 | Start of optimal posting window |
| `optimal_time_end_hour` | 8 | End of optimal posting window |
| `variety_min_days_gap` | 2 | Days between similar themes |
| `variety_max_same_cluster` | 3 | Max uses of same cluster per week |
| `hashtag_count_min` | 5 | Minimum hashtags per post |
| `hashtag_count_max` | 12 | Maximum hashtags per post |
| `timezone` | "UTC" | Timezone for optimal time calculations |

## Architecture

### Core Components

**Models:**
- `StrategyState` - Persists strategy state per persona
- `HistoryRecord` - Audit log of posting decisions
- `StrategyConfig` - Configuration with validation

**Services:**
- `ConfigLoader` - Loads YAML configuration
- `Context` - Execution context with history and state
- `StateCache` - Redis-backed caching (<10ms queries)
- `StrategyRegistry` - Plugin system for strategies
- `HashtagEngine` - Intelligent hashtag generation

**Strategies:**
- `BaseStrategy` - Abstract base with lifecycle hooks
- `ThemeOfWeekStrategy` - Weekly theme focus
- `ThematicRotationStrategy` - Rotating selection

**Concerns:**
- `TimingOptimization` - Optimal posting time calculation
- `VarietyEnforcement` - Content variety rules
- `FormatOptimization` - Hashtag and format recommendations

### Data Flow

```
SelectNextPost
  ↓
Context (loads state, history, clusters)
  ↓
Strategy Selection (from StrategyState)
  ↓
Strategy Execution (select_next_photo)
  ↓
  ├─ Select Cluster (with variety enforcement)
  ├─ Select Photo (unposted from cluster)
  ├─ Calculate Optimal Time (timing windows)
  └─ Generate Hashtags (HashtagEngine)
  ↓
Return Result (photo, cluster, time, hashtags)
```

## Database Schema

### content_strategy_states
Tracks active strategy and state per persona.

| Column | Type | Description |
|--------|------|-------------|
| persona_id | bigint | Foreign key (unique) |
| active_strategy | string | Current strategy name |
| strategy_config | jsonb | Strategy-specific config |
| state_data | jsonb | Strategy state (week, cluster, etc) |
| started_at | datetime | When strategy started |

### content_strategy_histories
Audit log of all posting decisions.

| Column | Type | Description |
|--------|------|-------------|
| persona_id | bigint | Foreign key |
| post_id | bigint | Foreign key to scheduling_posts |
| cluster_id | bigint | Cluster used (nullable) |
| strategy_name | string | Strategy that made decision |
| decision_context | jsonb | Full decision context |
| created_at | datetime | When decision was made |

### Enhancements to scheduling_posts

| Column | Type | Description |
|--------|------|-------------|
| cluster_id | bigint | Cluster photo belongs to |
| strategy_name | string | Strategy that selected it |
| optimal_time_calculated | datetime | Calculated optimal time |
| hashtags | jsonb | Generated hashtags |

## Instagram Best Practices (Encoded)

Based on research analyzing 10M+ posts:

### Optimal Posting Times
- **Primary window:** 5-8am local time (2.25x reach)
- **Secondary window:** 10am-3pm local time
- **Avoid:** Late evening (after 9pm)

### Posting Frequency
- **Sweet spot:** 3-5 posts per week
- **Minimum:** 1 post per week to maintain presence
- **Maximum:** 7 posts per week (risk of oversaturation)

### Content Variety
- **Gap between similar themes:** 2-3 days minimum
- **Max same cluster per week:** 3 posts
- **Prevents:** Content fatigue and audience burnout

### Hashtag Strategy
- **Optimal count:** 5-12 hashtags
- **Mix ratio:** 2 popular : 3 medium : 3 niche
- **Categories:** landscape, portrait, urban, nature, food

### Format Preferences
- **Carousels:** 3x engagement vs static posts
- **Reels:** Favored by algorithm (higher reach)
- **Static posts:** Good for single strong images

## Error Handling

### Common Errors

**UnknownStrategyError**
```ruby
begin
  SelectNextPost.new(persona: persona, strategy_name: :invalid).call
rescue ContentStrategy::UnknownStrategyError => e
  puts e.message
  # => "Unknown strategy: invalid. Available: theme_of_week_strategy, thematic_rotation_strategy"
end
```

**NoAvailableClustersError**
```ruby
# Raised when persona has no clusters
rescue ContentStrategy::NoAvailableClustersError => e
  puts e.message
  # => "No available clusters for persona 1"
end
```

**NoUnpostedPhotosError**
```ruby
# Raised when cluster is exhausted
rescue ContentStrategy::NoUnpostedPhotosError => e
  puts e.message
  # => "No unposted photos available in cluster 'Mountain Landscapes'"
end
```

## Advanced Usage

### Custom Strategy Configuration

```ruby
# Override configuration for specific persona
state = ContentStrategy::StrategyState.find_or_create_by!(persona: persona)
state.strategy_config = {
  posting_frequency_max: 7,
  hashtag_count_min: 10,
  timezone: 'America/Los_Angeles'
}
state.save!
```

### Accessing Strategy State

```ruby
state = ContentStrategy::StrategyState.find_by(persona: persona)

# Get state value
week = state.get_state(:week_number)

# Set state value
state.set_state(:cluster_id, 123)

# Update nested state
state.update_state(:stats, { posts_count: 5 })

# Reset strategy state
state.reset_state!
```

### Querying History

```ruby
# Recent posting history
history = ContentStrategy::HistoryRecord
  .for_persona(persona.id)
  .recent_days(7)

# Cluster usage
cluster_history = ContentStrategy::HistoryRecord
  .for_cluster(cluster.id)
  .recent

# By strategy
strategy_history = ContentStrategy::HistoryRecord
  .for_persona(persona.id)
  .where(strategy_name: 'theme_of_week_strategy')
```

### Manual Hashtag Generation

```ruby
photo = Photo.find(1)
cluster = Clustering::Cluster.find(1)

hashtags = ContentStrategy::HashtagEngine.generate(
  photo: photo,
  cluster: cluster,
  count: 10
)
# => ["#mountain", "#landscapes", "#nature", ...]
```

## Testing

Run the test suite:

```bash
bundle exec rspec packs/content_strategy/spec
```

### Example Test

```ruby
RSpec.describe ContentStrategy::SelectNextPost do
  let(:persona) { create(:persona) }
  let(:cluster) { create(:cluster, persona: persona) }
  let!(:photo) { create(:photo, cluster: cluster, persona: persona) }

  it 'selects next photo successfully' do
    result = described_class.new(persona: persona).call
    
    expect(result[:success]).to be true
    expect(result[:photo]).to eq(photo)
    expect(result[:cluster]).to eq(cluster)
    expect(result[:hashtags]).to be_present
  end
end
```

## Troubleshooting

### Strategy not working

**Check strategy is registered:**
```ruby
ContentStrategy::StrategyRegistry.all
# => [:theme_of_week_strategy, :thematic_rotation_strategy]
```

**Check persona has clusters:**
```ruby
Clustering::Cluster.where(persona: persona).count
# => Should be > 0
```

**Check clusters have unposted photos:**
```ruby
cluster.unposted_photos.count
# => Should be > 0
```

### State issues

**Clear corrupted state:**
```ruby
state = ContentStrategy::StrategyState.find_by(persona: persona)
state.reset_state!
```

**Invalidate cache:**
```ruby
ContentStrategy::StateCache.invalidate(persona.id)
```

### Configuration not loading

**Reload configuration:**
```ruby
ContentStrategy::ConfigLoader.reload!
```

**Check YAML syntax:**
```bash
ruby -ryaml -e "YAML.load_file('config/content_strategy.yml')"
```

## Performance

### Caching Strategy

- **StateCache:** 5-minute TTL, <10ms queries
- **Context:** Memoizes queries within request
- **Registry:** Singleton, loaded once at boot

### Optimization Tips

1. Use `with_unposted_photos` scope to filter clusters
2. Batch history queries with `recent_days(n)`
3. Cache frequently accessed configuration
4. Use database indexes on `cluster_id`, `strategy_name`

## Contributing

### Adding a New Strategy

1. Create strategy class inheriting from `BaseStrategy`:

```ruby
module ContentStrategy
  class MyNewStrategy < BaseStrategy
    def select_next_photo
      # Your logic here
      {
        photo: selected_photo,
        cluster: cluster,
        optimal_time: get_optimal_posting_time(photo: selected_photo),
        hashtags: select_hashtags(photo: selected_photo, cluster: cluster),
        format: recommend_format(photo: selected_photo, config: context.config)
      }
    end
  end
end
```

2. Register strategy in `Engine`:

```ruby
def register_strategies
  StrategyRegistry.register(:my_new_strategy, MyNewStrategy)
end
```

3. Add tests in `spec/strategies/my_new_strategy_spec.rb`

### Code Style

- Follow Rails conventions
- Use descriptive method names
- Add comments for complex logic
- Write tests for new features

## Support

For issues or questions:
1. Check this documentation
2. Review research docs in `docs/research/content-strategy-engine/`
3. Check OpenSpec proposal in `openspec/changes/add-content-strategy-engine/`
4. Review specs in `openspec/specs/content-strategy/`

## License

See main project LICENSE file.
