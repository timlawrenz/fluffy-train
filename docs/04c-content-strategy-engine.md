# Content Strategy Engine (Milestone 4c)

> **Status:** Phase 2 - 40% Complete (35/87 tasks)  
> **Location:** `packs/content_strategy/`  
> **Full Documentation:** See `packs/content_strategy/README.md`

## What is it?

The Content Strategy Engine intelligently selects and schedules Instagram content using proven best practices from analyzing 10M+ posts. It applies Instagram domain knowledge to optimize posting times, enforce content variety, and generate relevant hashtags.

## Quick Start

```ruby
# Select next post for a persona
persona = Persona.find(1)
result = ContentStrategy::SelectNextPost.new(persona: persona).call

if result[:success]
  Scheduling::Post.create!(
    persona: persona,
    photo: result[:photo],
    cluster: result[:cluster],
    scheduled_at: result[:optimal_time],
    hashtags: result[:hashtags]
  )
end
```

## Available Strategies

### Theme of Week Strategy
- Focuses on one cluster for 7 days
- Posts 3-5 photos from that theme
- Switches to new theme weekly
- **Best for:** Consistent narrative, deep theme exploration

### Thematic Rotation Strategy
- Rotates through all available clusters
- Posts from different theme each time
- **Best for:** Diverse feed, showcasing variety

## Instagram Best Practices (Encoded)

Based on research from 10M+ Instagram posts:

| Practice | Recommendation | Impact |
|----------|---------------|--------|
| **Posting Times** | 5-8am, 10am-3pm local | 2.25x reach |
| **Posting Frequency** | 3-5 posts/week | Optimal engagement |
| **Content Variety** | 2-3 day gaps between similar themes | Prevents fatigue |
| **Hashtags** | 5-12 relevant tags | Optimal discovery |
| **Format** | Carousels preferred | 3x engagement vs static |

## Configuration

Edit `config/content_strategy.yml`:

```yaml
development:
  posting_frequency_min: 3
  posting_frequency_max: 5
  optimal_time_start_hour: 5
  optimal_time_end_hour: 8
  variety_min_days_gap: 2
  hashtag_count_min: 5
  hashtag_count_max: 12
  timezone: "UTC"
```

## Architecture

### Core Components

```
SelectNextPost Command
  ↓
Context (state, history, clusters)
  ↓
Strategy (ThemeOfWeek or ThematicRotation)
  ↓
Concerns (Timing, Variety, Format)
  ↓
Result (photo, cluster, time, hashtags)
```

### Database Tables

- **content_strategy_states** - Active strategy per persona
- **content_strategy_histories** - Audit log of decisions
- **scheduling_posts** - Enhanced with cluster_id, strategy_name, hashtags

## Key Features Implemented

✅ **Phase 1: Foundation (Week 1) - Complete**
- Database schema (3 migrations)
- BaseStrategy and StrategyRegistry
- Two core strategies (Theme of Week, Thematic Rotation)
- Shared concerns (Timing, Variety, Format)
- Configuration system with YAML
- Context and StateCache

✅ **Phase 2: Enhancements (Week 2) - 40% Complete**
- Error handling hierarchy
- Cluster integration (scopes, methods)
- HashtagEngine (intelligent generation)
- RSpec test foundation
- Model enhancements

🚧 **Phase 3: Integration (Week 3) - Not Started**
- Command chain architecture
- Scheduler integration
- Workflow testing

🚧 **Phase 4: CLI & Observability (Week 4) - Not Started**
- CLI commands
- Logging and metrics
- Monitoring

## Research Foundation

All functionality is based on comprehensive research:

- **Instagram Domain Knowledge** (24KB)
  - Optimal posting times analysis
  - Engagement patterns
  - Algorithm priorities
  - Content strategy frameworks

- **Architecture Design** (28KB)
  - Technical specification
  - Class diagrams
  - Integration patterns
  - State management design

- **Research Summary** (12KB)
  - Key findings
  - Implementation recommendations
  - Risk mitigation

📁 See `docs/research/content-strategy-engine/` for full research documentation.

## Usage Examples

### Select Next Post

```ruby
result = ContentStrategy::SelectNextPost.new(
  persona: persona,
  strategy_name: :theme_of_week_strategy
).call

puts "Photo: #{result[:photo].path}"
puts "Cluster: #{result[:cluster].name}"
puts "Time: #{result[:optimal_time]}"
puts "Hashtags: #{result[:hashtags].join(' ')}"
```

### Generate Hashtags

```ruby
hashtags = ContentStrategy::HashtagEngine.generate(
  photo: photo,
  cluster: cluster,
  count: 10
)
# => ["#mountain", "#landscape", "#nature", ...]
```

### Query History

```ruby
# Recent posts
ContentStrategy::HistoryRecord
  .for_persona(persona.id)
  .recent_days(7)

# Cluster usage
cluster.last_posted_at
cluster.unposted_photos_count
```

## Testing

```bash
# Run all content strategy tests
bundle exec rspec packs/content_strategy/spec

# Test specific component
bundle exec rspec packs/content_strategy/spec/services/hashtag_engine_spec.rb
```

## Error Handling

The system includes proper error classes:

- `UnknownStrategyError` - Invalid strategy name
- `NoAvailableClustersError` - Persona has no clusters
- `NoUnpostedPhotosError` - Cluster exhausted

## Performance

- **StateCache:** <10ms queries with Redis
- **Configuration:** Loaded once at boot
- **History queries:** Optimized with indexes

## Documentation

- **Full README:** `packs/content_strategy/README.md` (12KB)
- **Research Docs:** `docs/research/content-strategy-engine/` (64KB)
- **OpenSpec Proposal:** `openspec/changes/add-content-strategy-engine/`
- **Specs:** `openspec/specs/content-strategy/spec.md`

## Contributing

See `packs/content_strategy/README.md` for:
- Adding new strategies
- Code style guidelines
- Testing requirements
- Architecture patterns

## Related Milestones

- **Milestone 3:** Automated posting scheduler (integration point)
- **Milestone 4a:** Clustering engine (provides clusters)
- **Milestone 4b:** Cluster management (UI for cluster organization)
- **Milestone 4c:** Content Strategy Engine (this feature)

## Next Steps

1. Complete Phase 2 (strategy specs, logging)
2. Phase 3 integration with scheduler
3. Add CLI commands for strategy management
4. Add observability and metrics
5. Production rollout with feature flags

---

**Version:** Phase 2 (40% complete)  
**Last Updated:** 2025-11-02  
**Estimated Completion:** 2 more weeks
