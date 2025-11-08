# Hashtag Generations Pack

Intelligent, persona-aware hashtag generation for Instagram posts.

## Overview

This pack enhances the basic `HashtagEngine` with content-based analysis, persona alignment, and relevance scoring to generate optimized hashtags that maximize reach and engagement.

## Components

### Services

**`HashtagGenerations::Generator`** - Main service for intelligent hashtag generation
- Integrates all components
- Falls back to basic HashtagEngine if no persona strategy
- Returns hashtags with metadata

**`HashtagGenerations::ObjectMapper`** - Maps photo objects to relevant hashtags
- Uses `photo_analysis.detected_objects`
- Contextual mappings (e.g., sunset → #GoldenHour, #SunsetLovers)
- Comprehensive object-to-hashtag dictionary

**`HashtagGenerations::ContentAnalyzer`** - Extracts content-based tags
- Analyzes photo content
- Combines object-based and analysis tags
- Returns unique content-specific hashtags

**`HashtagGenerations::PersonaAligner`** - Filters tags by persona niche
- Applies persona hashtag strategy
- Adds target hashtags
- Removes avoided hashtags

**`HashtagGenerations::RelevanceScorer`** - Scores and ranks hashtags
- Categorizes by size (large/medium/niche)
- Scores by relevance and specificity
- Returns ranked hashtag list

**`HashtagGenerations::MixOptimizer`** - Optimizes hashtag mix
- Implements optimal size distribution
- Balanced: 2-3 large, 3-4 medium, 3-5 niche
- Respects persona size_mix preference

## Usage

### Basic Usage

```ruby
result = HashtagGenerations::Generator.generate(
  photo: photo,
  persona: persona,
  cluster: cluster,
  count: 10
)

result[:hashtags]
# => ["#GoldenHour", "#CityVibes", "#UrbanSunset", ...]

result[:metadata]
# => { method: 'intelligent', generated_by: '...', ... }
```

### Configure Persona Strategy

```ruby
persona.hashtag_strategy = {
  niche_categories: ['lifestyle', 'fashion', 'urban'],
  target_hashtags: [
    '#LifestylePhotography', 
    '#FashionDaily', 
    '#CityVibes'
  ],
  avoid_hashtags: ['#Like4Like', '#FollowForFollow'],
  size_mix: 'balanced'  # or 'niche_heavy' or 'broad_reach'
}
persona.save!
```

### Size Mix Options

- **balanced**: 2-3 large, 3-4 medium, 3-5 niche (default)
- **niche_heavy**: 1-2 large, 2-3 medium, 5-7 niche (high engagement)
- **broad_reach**: 3-4 large, 3-4 medium, 2-3 niche (maximum reach)

## Integration

The intelligent generator is automatically used by content strategies when a persona has `hashtag_strategy` configured:

```ruby
# In BaseStrategy
def select_hashtags(photo:, cluster:)
  if persona.hashtag_strategy.present?
    # Use intelligent generation
    HashtagGenerations::Generator.generate(...)
  else
    # Fallback to basic HashtagEngine
    HashtagEngine.generate(...)
  end
end
```

## Architecture

```
HashtagGenerations::Generator
  ├── ContentAnalyzer.extract_tags(photo)
  │   └── ObjectMapper.map_objects(detected_objects)
  │
  ├── PersonaAligner.filter_tags(tags, persona)
  │   └── Apply persona.hashtag_strategy
  │
  ├── RelevanceScorer.score_and_rank(tags)
  │   └── Score by size category and relevance
  │
  └── MixOptimizer.optimize(scored_tags)
      └── Select optimal mix by distribution
```

## Examples

### Example 1: Urban Sunset Photo

**Input:**
- Photo with detected objects: building, sunset, sky
- Persona: Sarah (lifestyle, casual)
- Cluster: Urban Exploration

**Output:**
```ruby
[
  "#GoldenHour",           # Content (sunset)
  "#UrbanSunset",          # Content (urban + sunset)
  "#CityVibes",            # Persona target
  "#ArchitectureLovers",   # Content (building)
  "#LifestylePhotography", # Persona target
  "#SkyLovers",            # Content (sky)
  "#EveningVibes",         # Medium size
  "#UrbanPhotography",     # Cluster
  "#ModernArchitecture",   # Content (building)
  "#EverydayMoments"       # Persona target
]
```

### Example 2: Coffee Shop Morning

**Input:**
- Photo with detected objects: coffee, person, woman
- Persona: Sarah (lifestyle)
- Cluster: Coffee Culture

**Output:**
```ruby
[
  "#CoffeeTime",          # Content (coffee)
  "#CoffeeLovers",        # Persona target
  "#MorningVibes",        # Medium size
  "#ButFirstCoffee",      # Content (coffee)
  "#LifestylePhotography",# Persona target
  "#CoffeeCulture",       # Content (coffee)
  "#PortraitPhotography", # Content (person)
  "#CoffeePhotography",   # Content (coffee)
  "#EverydayMoments",     # Persona target
  "#CozyMorning"          # Medium size
]
```

## Testing

Run specs:
```bash
bundle exec rspec packs/personas/spec/models/personas/hashtag_strategy_spec.rb
```

Test generation:
```bash
bin/rails runner '
persona = Persona.find_by(name: "sarah")
photo = persona.photos.joins(:photo_analysis).first

result = HashtagGenerations::Generator.generate(
  photo: photo,
  persona: persona,
  cluster: photo.cluster,
  count: 10
)

puts result[:hashtags].join(", ")
'
```

## Dependencies

- `content_strategy` - HashtagEngine fallback
- `personas` - Persona model and hashtag_strategy

## Future Enhancements

- Trending hashtag detection (API integration)
- Banned hashtag database (shadowban prevention)
- Performance tracking by hashtag
- A/B testing framework
- Multi-language support
