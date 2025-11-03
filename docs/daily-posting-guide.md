# Daily Posting Guide

This guide walks through the daily routine for posting content to Instagram using the Content Strategy Engine.

## Quick Start (Most Common)

The simplest way to post is using the automated content strategy:

```bash
# Post next photo using content strategy
bundle exec rails scheduling:post_with_strategy[sarah]
```

This will:
1. Use the Content Strategy Engine to select the optimal photo
2. Choose based on your active strategy (Theme of Week or Thematic Rotation)
3. Generate relevant hashtags
4. Calculate optimal posting time
5. Post immediately to Instagram

## Daily Workflow Options

### Option 1: Fully Automated (Recommended)

```bash
# Single command to select and post
bundle exec rails scheduling:post_with_strategy[sarah]
```

**Output:**
```
Selecting next photo using Content Strategy for persona: sarah
Successfully selected and posted photo: 12345
  Cluster: Mountain Landscapes
  Strategy: theme_of_week_strategy
  Hashtags: #mountain #nature #landscape #photography...
  Optimal time: 2025-11-04 06:15:00
```

### Option 2: Review Before Posting (Rails Console)

If you want to review the selection before posting:

```bash
bundle exec rails console
```

```ruby
# 1. Select next photo (without posting)
persona = Persona.find_by(name: 'sarah')
result = ContentStrategy::SelectNextPost.new(persona: persona).call

# 2. Review the selection
puts "Photo: #{result[:photo].path}"
puts "Cluster: #{result[:cluster].name}"
puts "Hashtags: #{result[:hashtags].join(' ')}"
puts "Caption: #{result[:photo].photo_analysis&.caption}"

# 3. If happy, create the post manually
post = Scheduling::Post.create!(
  persona: persona,
  photo: result[:photo],
  cluster: result[:cluster],
  strategy_name: result[:strategy_name],
  hashtags: result[:hashtags],
  caption: "#{result[:photo].photo_analysis&.caption}\n\n#{result[:hashtags].join(' ')}",
  status: 'draft'
)

# 4. Schedule/post it
Scheduling::SchedulePost.call(post: post)
```

### Option 3: Manual Selection (Full Control)

```ruby
# Start Rails console
bundle exec rails console

# 1. Browse available photos
persona = Persona.find_by(name: 'sarah')

# View photos by cluster
cluster = Clustering::Cluster.find_by(name: 'Mountain Landscapes')
cluster.unposted_photos.each do |photo|
  puts "#{photo.id}: #{photo.path}"
  puts "  Aesthetic score: #{photo.photo_analysis&.aesthetic_score}"
  puts "  Caption: #{photo.photo_analysis&.caption}"
  puts ""
end

# 2. Select a specific photo
photo = Photo.find(12345)

# 3. Generate hashtags (optional, or write your own)
hashtags = ContentStrategy::HashtagEngine.generate(
  photo: photo,
  cluster: cluster,
  count: 10
)

# 4. Create and post
post = Scheduling::Post.create!(
  persona: persona,
  photo: photo,
  cluster: cluster,
  caption: "Your custom caption\n\n#{hashtags.join(' ')}",
  status: 'draft'
)

Scheduling::SchedulePost.call(post: post)
```

## Checking Status

### View Content Strategy Status

```bash
# See current strategy, state, and recent posts
bundle exec rails content_strategy:show[sarah]
```

**Output:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Content Strategy Status for: sarah
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Active Strategy: theme_of_week_strategy
Started At: 2025-11-02

Strategy State:
  week_number: 2025-W44
  cluster_id: 5

Configuration:
  Posting frequency: 3-5/week
  Optimal time: 5:00-8:00
  Variety gap: 2 days
  Hashtags: 5-12 tags

Recent Posts (last 7 days):
  • 2025-11-02 - Mountain Landscapes (theme_of_week_strategy)
  • 2025-11-01 - Urban Photography (theme_of_week_strategy)
```

### View Posting History

```bash
# See all posts from last 7 days
bundle exec rails content_strategy:history[sarah,7]

# Or last 30 days
bundle exec rails content_strategy:history[sarah,30]
```

### Check Available Clusters

```ruby
# In Rails console
persona = Persona.find_by(name: 'sarah')

# See all clusters with unposted photos
Clustering::Cluster
  .joins(:photos)
  .where(photos: { persona: persona })
  .where.not(photos: { id: Scheduling::Post.pluck(:photo_id) })
  .distinct
  .each do |cluster|
    count = cluster.unposted_photos.count
    puts "#{cluster.name}: #{count} unposted photos"
  end
```

## Managing Strategies

### Change Active Strategy

```bash
# Switch to Thematic Rotation (posts from different clusters each time)
bundle exec rails content_strategy:set_strategy[sarah,thematic_rotation_strategy]

# Switch to Theme of Week (focuses on one cluster for 7 days)
bundle exec rails content_strategy:set_strategy[sarah,theme_of_week_strategy]
```

### List Available Strategies

```bash
bundle exec rails content_strategy:list_strategies
```

**Output:**
```
Available Content Strategies:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

theme_of_week_strategy
  Class: ContentStrategy::ThemeOfWeekStrategy
  Description: Focuses on one cluster for 7 days
  Best for: Consistent narrative, deep theme exploration

thematic_rotation_strategy
  Class: ContentStrategy::ThematicRotationStrategy
  Description: Rotates through available clusters
  Best for: Diverse feed, showcasing variety
```

### Reset Strategy State

If you want to start fresh (pick a new cluster, reset counters):

```bash
bundle exec rails content_strategy:reset[sarah]
```

## Troubleshooting

### No Photos Available

**Error:** "No cluster available" or "No photos available"

**Solutions:**
```ruby
# 1. Check if you have unposted photos
persona = Persona.find_by(name: 'sarah')
unposted_count = Photo.where(persona: persona)
  .where.not(id: Scheduling::Post.pluck(:photo_id))
  .count
puts "Unposted photos: #{unposted_count}"

# 2. Check if photos are in clusters
unclustered = Photo.where(persona: persona, cluster_id: nil).count
puts "Unclustered photos: #{unclustered}"

# If you have unclustered photos, run clustering:
# bundle exec rails clustering:cluster_photos[sarah]

# 3. Check max weekly posts reached
this_week = ContentStrategy::HistoryRecord
  .for_persona(persona.id)
  .where('created_at >= ?', Time.current.beginning_of_week)
  .count
puts "Posts this week: #{this_week}/5"
```

### Strategy Not Working as Expected

```bash
# Reset strategy state and try again
bundle exec rails content_strategy:reset[sarah]
bundle exec rails scheduling:post_with_strategy[sarah]
```

### View All Posts

```ruby
# In Rails console
persona = Persona.find_by(name: 'sarah')

# Recent posts
Scheduling::Post
  .where(persona: persona)
  .order(created_at: :desc)
  .limit(10)
  .each do |post|
    puts "#{post.created_at.to_date}: #{post.photo.path}"
    puts "  Status: #{post.status}"
    puts "  Cluster: #{post.cluster&.name || 'None'}"
    puts "  Strategy: #{post.strategy_name || 'Legacy'}"
    puts ""
  end
```

## Best Practices

### Recommended Daily Routine

**Morning (8:00 AM):**
```bash
# 1. Check status
bundle exec rails content_strategy:show[sarah]

# 2. Post for the day
bundle exec rails scheduling:post_with_strategy[sarah]
```

**Or use the legacy curator's choice:**
```bash
bundle exec rails scheduling:post_next_best[sarah]
```

### Optimal Posting Times

Based on Instagram research (encoded in the strategy):
- **Best:** 5:00-8:00 AM (2.25x reach potential)
- **Good:** 10:00 AM - 3:00 PM
- **Avoid:** After 9:00 PM

The Content Strategy Engine automatically calculates optimal times, but posts immediately when you run the command.

### Posting Frequency

**Recommended:** 3-5 posts per week
- **Minimum:** 1 post/week to maintain presence
- **Maximum:** 7 posts/week (risk of oversaturation)

The strategy engine tracks this and will warn if you exceed the configured maximum.

### Content Variety

The strategy engine automatically enforces:
- **2-3 day gaps** between similar themes (same cluster)
- **Maximum 3 posts** from same cluster per week

This prevents content fatigue and keeps your feed diverse.

## Configuration

To customize the strategy behavior, edit `config/content_strategy.yml`:

```yaml
development:
  posting_frequency_min: 3
  posting_frequency_max: 5
  optimal_time_start_hour: 5
  optimal_time_end_hour: 8
  variety_min_days_gap: 2
  hashtag_count_min: 5
  hashtag_count_max: 12
```

After editing, restart Rails for changes to take effect.

## Next Steps

- **Adding New Photos:** See [Adding New Photos Guide](./docs/adding-new-photos.md)
- **Reviewing Clusters:** See [Cluster Management Guide](./docs/04b-cluster-management.md)
- **Advanced Usage:** See [Content Strategy Pack README](./packs/content_strategy/README.md)
