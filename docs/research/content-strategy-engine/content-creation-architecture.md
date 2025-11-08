# Content Pillar-Driven Creation Architecture

**Date**: 2025-11-06  
**Purpose**: Design system where content pillars drive photo generation, not vice versa  
**Status**: Architecture Design Phase

---

## Problem Statement

### Current System Limitations

**Existing Flow:**
```
Photos Uploaded → Image Analysis → Clustering (DBSCAN) → Strategy Selects from Clusters
```

**Issues:**
1. **Reactive, not proactive**: Can only post what already exists
2. **Cluster quality**: Visual similarity ≠ strategic coherence
3. **Content gaps**: No mechanism to identify missing content
4. **Manual intensive**: Need to manually ensure pillar coverage
5. **No creation guidance**: Don't know what to generate next

### Desired Flow

**New Flow:**
```
Content Strategy → Pillar Rotation → Content Gap Analysis → 
AI Prompt Generation → Human Creates Content → Curation → 
Manual Clustering → Scheduling → Posting
```

**Benefits:**
1. **Proactive creation**: Strategy drives what to make
2. **Strategic coherence**: Pillars guide content themes
3. **Gap identification**: System tells you what's missing
4. **AI assistance**: Generate creation prompts automatically
5. **Human curation**: Quality gate before posting

---

## Architecture Overview

### Core Components

```
┌─────────────────────────────────────────────────────────────┐
│                    Content Strategy Layer                    │
│  - Define content pillars (3-5 themes)                      │
│  - Set rotation patterns (3-1-3-1, weighted, etc.)         │
│  - Track pillar coverage over time                          │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                  Content Gap Analysis Layer                  │
│  - Identify which pillars need content                      │
│  - Calculate content needs by date                          │
│  - Prioritize based on posting schedule                     │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│               AI Prompt Generation Layer                     │
│  - Generate image creation prompts                          │
│  - Use Gemini/Ollama for prompt engineering                │
│  - Include persona aesthetic, pillar theme, context         │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                  Human Creation & Curation                   │
│  - User generates images with AI tool                       │
│  - Curates best candidates                                  │
│  - QUALITY GATE: Ensures brand alignment                   │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                   Manual Clustering Layer                    │
│  - Create named clusters per pillar/campaign                │
│  - Assign curated photos to clusters                        │
│  - Tag clusters with pillar metadata                        │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    Scheduling & Posting                      │
│  - Select from pillar-appropriate clusters                  │
│  - Generate captions/hashtags per pillar                    │
│  - Post according to strategy                               │
└─────────────────────────────────────────────────────────────┘
```

---

## Part 1: Content Pillar Definition System

### Database Schema

```ruby
# Add to personas table
class AddContentPillarsToPersonas < ActiveRecord::Migration[8.0]
  def change
    add_column :personas, :content_pillars, :jsonb, default: []
    add_index :personas, :content_pillars, using: :gin
  end
end

# Add to clusters table  
class AddPillarTagsToClusters < ActiveRecord::Migration[8.0]
  def change
    add_column :clusters, :pillar_name, :string
    add_column :clusters, :pillar_metadata, :jsonb, default: {}
    add_index :clusters, :pillar_name
  end
end

# New table: content_creation_requests
class CreateContentCreationRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :content_creation_requests do |t|
      t.references :persona, null: false, foreign_key: true
      t.string :pillar_name, null: false
      t.text :generation_prompt
      t.jsonb :context, default: {}
      t.integer :photos_needed, default: 1
      t.datetime :needed_by
      t.string :status, default: 'pending' # pending, in_progress, completed
      t.timestamps
    end
    
    add_index :content_creation_requests, :status
    add_index :content_creation_requests, :needed_by
  end
end
```

### ContentPillar Model

```ruby
# packs/personas/app/models/personas/content_pillar.rb
module Personas
  class ContentPillar
    include ActiveModel::Model
    include ActiveModel::Attributes
    
    attribute :name, :string
    attribute :description, :string
    attribute :weight, :integer, default: 20  # Percentage of content
    attribute :cluster_tags, :array, default: []
    attribute :generation_guidelines, :string
    attribute :example_prompts, :array, default: []
    attribute :seasonal_boost, :hash, default: {}
    
    validates :name, presence: true
    validates :weight, numericality: { in: 0..100 }
    
    def to_hash
      {
        name: name,
        description: description,
        weight: weight,
        cluster_tags: cluster_tags,
        generation_guidelines: generation_guidelines,
        example_prompts: example_prompts,
        seasonal_boost: seasonal_boost
      }
    end
    
    def self.from_hash(hash)
      return nil if hash.nil? || hash.empty?
      new(hash)
    end
    
    # Calculate if this pillar needs content based on recent posts
    def content_needed?(persona:, days_back: 14)
      recent_posts = persona.recent_posts(days_back)
      pillar_posts = recent_posts.select do |post|
        post.cluster&.pillar_name == name
      end
      
      expected_posts = (recent_posts.count * (weight / 100.0)).round
      actual_posts = pillar_posts.count
      
      actual_posts < expected_posts
    end
    
    # Get seasonal weight boost
    def effective_weight(date: Date.current)
      month = date.month
      boost = seasonal_boost[month.to_s] || 0
      [weight + boost, 100].min
    end
  end
end
```

### Persona Model Enhancement

```ruby
# packs/personas/app/models/persona.rb
class Persona < ApplicationRecord
  # ... existing code ...
  
  def content_pillars
    return [] if self[:content_pillars].nil? || self[:content_pillars].empty?
    @content_pillars ||= self[:content_pillars].map do |pillar_hash|
      Personas::ContentPillar.from_hash(pillar_hash)
    end
  end
  
  def content_pillars=(pillars)
    pillar_objects = pillars.map do |p|
      p.is_a?(Personas::ContentPillar) ? p : Personas::ContentPillar.new(p)
    end
    
    # Validate all pillars
    pillar_objects.each do |pillar|
      raise ArgumentError, pillar.errors.full_messages.join(', ') unless pillar.valid?
    end
    
    # Validate total weight
    total_weight = pillar_objects.sum(&:weight)
    raise ArgumentError, "Total pillar weights must equal 100 (got #{total_weight})" unless total_weight == 100
    
    self[:content_pillars] = pillar_objects.map(&:to_hash)
    @content_pillars = pillar_objects
  end
  
  def pillar_by_name(name)
    content_pillars.find { |p| p.name == name }
  end
  
  def recent_posts(days_back = 14)
    # Get posts from last N days
    start_date = days_back.days.ago
    Scheduling::Post.where(persona: self, status: 'posted')
                    .where('posted_at >= ?', start_date)
                    .order(posted_at: :desc)
  end
end
```

---

## Part 2: Content Gap Analysis Service

```ruby
# packs/content_strategy/app/services/content_strategy/gap_analyzer.rb
module ContentStrategy
  class GapAnalyzer
    def initialize(persona:, horizon_days: 30)
      @persona = persona
      @horizon_days = horizon_days
    end
    
    def analyze
      return [] if @persona.content_pillars.empty?
      
      gaps = []
      
      @persona.content_pillars.each do |pillar|
        gap = analyze_pillar(pillar)
        gaps << gap if gap[:photos_needed] > 0
      end
      
      gaps.sort_by { |g| g[:priority] }.reverse
    end
    
    private
    
    def analyze_pillar(pillar)
      # Calculate expected posts for this pillar in horizon
      posts_per_week = @persona.strategy_config&.posts_per_week || 3
      weeks = @horizon_days / 7.0
      expected_total_posts = (posts_per_week * weeks).round
      expected_pillar_posts = (expected_total_posts * (pillar.weight / 100.0)).round
      
      # Count available content in clusters tagged with this pillar
      available_photos = available_photos_for_pillar(pillar)
      
      # Count already scheduled posts for this pillar
      scheduled_posts = scheduled_posts_for_pillar(pillar)
      
      # Calculate gap
      photos_needed = [expected_pillar_posts - available_photos - scheduled_posts, 0].max
      
      {
        pillar_name: pillar.name,
        pillar_weight: pillar.weight,
        expected_posts: expected_pillar_posts,
        available_photos: available_photos,
        scheduled_posts: scheduled_posts,
        photos_needed: photos_needed,
        priority: calculate_priority(pillar, photos_needed, available_photos),
        next_post_date: estimate_next_post_date(pillar)
      }
    end
    
    def available_photos_for_pillar(pillar)
      clusters = Clustering::Cluster.where(
        persona: @persona,
        pillar_name: pillar.name
      )
      
      Photo.where(cluster: clusters)
           .where.not(id: scheduled_photo_ids)
           .count
    end
    
    def scheduled_posts_for_pillar(pillar)
      Scheduling::Post.joins(photo: :cluster)
                      .where(persona: @persona, status: 'scheduled')
                      .where('clusters.pillar_name = ?', pillar.name)
                      .count
    end
    
    def scheduled_photo_ids
      Scheduling::Post.where(persona: @persona, status: 'scheduled')
                      .pluck(:photo_id)
    end
    
    def calculate_priority(pillar, photos_needed, available_photos)
      # Higher priority if:
      # - More photos needed
      # - Less available content
      # - Higher pillar weight
      # - Seasonal boost active
      
      base_priority = photos_needed * 10
      scarcity_bonus = available_photos == 0 ? 50 : (10 / [available_photos, 1].max)
      weight_bonus = pillar.weight
      seasonal_bonus = pillar.effective_weight - pillar.weight
      
      base_priority + scarcity_bonus + weight_bonus + seasonal_bonus
    end
    
    def estimate_next_post_date(pillar)
      # Estimate when this pillar will be needed next
      # Based on rotation pattern and scheduled posts
      
      # Simple estimation: distribute evenly
      posts_per_week = @persona.strategy_config&.posts_per_week || 3
      days_between_posts = 7.0 / posts_per_week
      weeks_per_pillar = 100.0 / pillar.weight
      days_until_next = days_between_posts * weeks_per_pillar
      
      Date.current + days_until_next.days
    end
  end
end
```

---

## Part 3: AI Prompt Generation Service

```ruby
# packs/content_creation/app/services/content_creation/prompt_generator.rb
module ContentCreation
  class PromptGenerator
    def initialize(persona:, pillar:)
      @persona = persona
      @pillar = pillar
    end
    
    def generate(context: {})
      # Build prompt using AI (Gemini or Ollama)
      # Combines:
      # - Persona aesthetic guidelines
      # - Pillar theme and guidelines
      # - Seasonal/contextual information
      # - Example prompts from pillar
      
      system_prompt = build_system_prompt
      user_prompt = build_user_prompt(context)
      
      response = call_ai_service(system_prompt, user_prompt)
      
      {
        generation_prompt: response,
        pillar_name: @pillar.name,
        persona_name: @persona.name,
        context: context,
        generated_at: Time.current
      }
    end
    
    private
    
    def build_system_prompt
      <<~PROMPT
        You are an expert image generation prompt engineer for Instagram content.
        
        Your task is to create detailed, effective prompts for AI image generation tools
        that will produce Instagram-ready photos matching specific brand aesthetics.
        
        The prompts should be:
        - Highly detailed and specific
        - Include lighting, composition, mood
        - Specify subject appearance and styling
        - Match the brand's visual identity
        - Optimized for realistic, authentic-looking results
      PROMPT
    end
    
    def build_user_prompt(context)
      <<~PROMPT
        Generate an image generation prompt for Instagram content with these requirements:
        
        PERSONA: #{@persona.name}
        Brand Voice: #{@persona.caption_config&.voice_attributes&.join(', ')}
        
        CONTENT PILLAR: #{@pillar.name}
        Description: #{@pillar.description}
        Generation Guidelines: #{@pillar.generation_guidelines}
        
        CONTEXT:
        #{format_context(context)}
        
        EXAMPLE STYLE (from previous successful prompts):
        #{@pillar.example_prompts.sample || 'No examples yet'}
        
        Generate a detailed prompt for an AI image generator that will create a photo
        matching this pillar theme and persona aesthetic. The photo should feel authentic,
        not staged or artificial.
        
        Return only the generation prompt, no explanation.
      PROMPT
    end
    
    def format_context(context)
      context.map { |k, v| "#{k}: #{v}" }.join("\n")
    end
    
    def call_ai_service(system_prompt, user_prompt)
      # Use Gemini or Ollama
      client = ENV['PROMPT_GENERATOR'] == 'gemini' ? GeminiClient : OllamaClient
      
      client.generate(
        system: system_prompt,
        prompt: user_prompt,
        model: ENV['PROMPT_MODEL'] || 'gemini-1.5-flash'
      )
    rescue => e
      Rails.logger.error("Prompt generation failed: #{e.message}")
      # Fallback to template-based generation
      generate_template_prompt(context)
    end
    
    def generate_template_prompt(context)
      # Simple template fallback
      base = @pillar.example_prompts.sample || ""
      
      # Add context-specific details
      context.each do |key, value|
        base += " #{value}."
      end
      
      base
    end
  end
end
```

---

## Part 4: Content Creation Request System

```ruby
# packs/content_creation/app/models/content_creation/request.rb
module ContentCreation
  class Request < ApplicationRecord
    belongs_to :persona
    
    validates :pillar_name, presence: true
    validates :status, inclusion: { in: %w[pending in_progress completed] }
    
    scope :pending, -> { where(status: 'pending') }
    scope :urgent, -> { where('needed_by <= ?', 7.days.from_now).order(:needed_by) }
    
    def generate_prompt!(context: {})
      pillar = persona.pillar_by_name(pillar_name)
      raise "Pillar not found: #{pillar_name}" unless pillar
      
      generator = PromptGenerator.new(persona: persona, pillar: pillar)
      result = generator.generate(context: context.merge(self.context))
      
      update!(
        generation_prompt: result[:generation_prompt],
        context: result[:context]
      )
      
      result[:generation_prompt]
    end
    
    def mark_in_progress!
      update!(status: 'in_progress')
    end
    
    def mark_completed!
      update!(status: 'completed')
    end
  end
end
```

### Service to Create Requests from Gap Analysis

```ruby
# packs/content_creation/app/services/content_creation/request_builder.rb
module ContentCreation
  class RequestBuilder
    def self.create_from_gaps(persona:, horizon_days: 30)
      new(persona: persona, horizon_days: horizon_days).create_requests
    end
    
    def initialize(persona:, horizon_days:)
      @persona = persona
      @horizon_days = horizon_days
    end
    
    def create_requests
      gaps = ContentStrategy::GapAnalyzer.new(
        persona: @persona,
        horizon_days: @horizon_days
      ).analyze
      
      requests = []
      
      gaps.each do |gap|
        next if gap[:photos_needed] == 0
        
        request = ContentCreation::Request.create!(
          persona: @persona,
          pillar_name: gap[:pillar_name],
          photos_needed: gap[:photos_needed],
          needed_by: gap[:next_post_date],
          context: {
            priority: gap[:priority],
            available_photos: gap[:available_photos],
            expected_posts: gap[:expected_posts]
          }
        )
        
        # Auto-generate prompt
        request.generate_prompt!
        
        requests << request
      end
      
      requests
    end
  end
end
```

---

## Part 5: Manual Clustering Workflow

### Cluster Model Enhancement

```ruby
# packs/clustering/app/models/clustering/cluster.rb
module Clustering
  class Cluster < ApplicationRecord
    belongs_to :persona
    has_many :photos
    
    # New fields: pillar_name, pillar_metadata
    
    scope :for_pillar, ->(pillar_name) { where(pillar_name: pillar_name) }
    scope :with_available_photos, -> { 
      joins(:photos)
        .where.not(photos: { id: Scheduling::Post.scheduled.pluck(:photo_id) })
        .group('clusters.id')
        .having('COUNT(photos.id) > 0')
    }
    
    def add_photo(photo)
      photo.update!(cluster: self)
      increment!(:size)
    end
    
    def add_photos(photos)
      photos.each { |photo| add_photo(photo) }
    end
    
    def available_photos
      photos.where.not(id: Scheduling::Post.scheduled.pluck(:photo_id))
    end
    
    def set_pillar(pillar_name, metadata: {})
      update!(
        pillar_name: pillar_name,
        pillar_metadata: metadata
      )
    end
  end
end
```

### Rake Tasks for Manual Clustering

```ruby
# lib/tasks/content_creation.rake
namespace :content do
  desc "Create cluster for pillar"
  task :create_cluster, [:persona, :pillar_name, :cluster_name] => :environment do |t, args|
    persona = Persona.find_by!(name: args[:persona])
    pillar = persona.pillar_by_name(args[:pillar_name])
    
    raise "Pillar not found: #{args[:pillar_name]}" unless pillar
    
    cluster = Clustering::Cluster.create!(
      persona: persona,
      name: args[:cluster_name],
      pillar_name: pillar.name,
      size: 0,
      pillar_metadata: {
        created_for: 'manual_content_creation',
        pillar_description: pillar.description
      }
    )
    
    puts "✅ Created cluster: #{cluster.name} (ID: #{cluster.id})"
    puts "   Pillar: #{pillar.name}"
  end
  
  desc "Add photos to cluster by filename pattern"
  task :add_to_cluster, [:cluster_id, :pattern] => :environment do |t, args|
    cluster = Clustering::Cluster.find(args[:cluster_id])
    photos = cluster.persona.photos.where("filename LIKE ?", "%#{args[:pattern]}%")
    
    photos.each do |photo|
      cluster.add_photo(photo)
      puts "✓ Added: #{photo.filename}"
    end
    
    puts "\n✅ Added #{photos.count} photos to cluster '#{cluster.name}'"
  end
  
  desc "Analyze content gaps"
  task :analyze_gaps, [:persona] => :environment do |t, args|
    persona = Persona.find_by!(name: args[:persona])
    gaps = ContentStrategy::GapAnalyzer.new(persona: persona).analyze
    
    puts "\n📊 Content Gap Analysis for #{persona.name}\n"
    puts "─" * 80
    
    gaps.each do |gap|
      puts "\nPillar: #{gap[:pillar_name]} (#{gap[:pillar_weight]}%)"
      puts "  Expected posts: #{gap[:expected_posts]}"
      puts "  Available photos: #{gap[:available_photos]}"
      puts "  Already scheduled: #{gap[:scheduled_posts]}"
      puts "  📸 Photos needed: #{gap[:photos_needed]}"
      puts "  ⚡ Priority: #{gap[:priority]}"
      puts "  📅 Next post: ~#{gap[:next_post_date]}"
    end
  end
  
  desc "Generate content creation requests"
  task :create_requests, [:persona, :horizon_days] => :environment do |t, args|
    persona = Persona.find_by!(name: args[:persona])
    horizon = (args[:horizon_days] || 30).to_i
    
    requests = ContentCreation::RequestBuilder.create_from_gaps(
      persona: persona,
      horizon_days: horizon
    )
    
    puts "\n✨ Created #{requests.count} content creation requests\n"
    puts "─" * 80
    
    requests.each do |req|
      puts "\nPillar: #{req.pillar_name}"
      puts "Photos needed: #{req.photos_needed}"
      puts "Needed by: #{req.needed_by}"
      puts "Priority: #{req.context['priority']}"
      puts "\n📝 Generation Prompt:"
      puts req.generation_prompt
      puts "\n" + "─" * 80
    end
  end
end
```

---

## Part 6: Workflow Integration

### Complete Workflow Example

```bash
# 1. Analyze content gaps
rake content:analyze_gaps[sarah]

# Output shows:
# Pillar: Cozy Autumn Moments (30%)
#   Photos needed: 3
#   Priority: 85
#   Next post: ~2024-11-11

# 2. Generate creation requests
rake content:create_requests[sarah,30]

# Output includes AI-generated prompts for each gap

# 3. User creates photos with AI tool using prompts

# 4. Import photos
rake photos:import PERSONA=sarah PATH=./thanksgiving-morning-coffee/

# 5. Create cluster and assign photos
rake content:create_cluster[sarah,"Cozy Autumn Moments","Thanksgiving Morning Coffee Nov 2024"]

rake content:add_to_cluster[CLUSTER_ID,"morning-coffee-nov"]

# 6. Schedule post from cluster
rake content_strategy:schedule_next PERSONA=sarah PILLAR="Cozy Autumn Moments"
```

---

## Part 7: UI Considerations (Future)

### Content Creation Dashboard

```
╔══════════════════════════════════════════════════════════╗
║  Sarah - Content Creation Dashboard                      ║
╠══════════════════════════════════════════════════════════╣
║                                                           ║
║  📊 Content Gaps (Next 30 Days)                          ║
║  ┌────────────────────────────────────────────────────┐ ║
║  │ Cozy Autumn Moments (30%)          🔴 3 needed     │ ║
║  │ Urban Gratitude (25%)              🟡 1 needed     │ ║
║  │ Wellness & Self-Care (20%)         🟢 0 needed     │ ║
║  │ Community & Connection (10%)       🟢 0 needed     │ ║
║  │ Seasonal & Events (15%)            🟡 2 needed     │ ║
║  └────────────────────────────────────────────────────┘ ║
║                                                           ║
║  📝 Generation Requests (5)                              ║
║  ┌────────────────────────────────────────────────────┐ ║
║  │ ⚡ Thanksgiving Morning Coffee                      │ ║
║  │    Pillar: Cozy Autumn Moments                     │ ║
║  │    Needed: 3 photos by Nov 11                      │ ║
║  │    [View Prompt] [Mark Complete]                   │ ║
║  └────────────────────────────────────────────────────┘ ║
║                                                           ║
║  📁 Manual Clusters (8)                                  ║
║  ┌────────────────────────────────────────────────────┐ ║
║  │ Thanksgiving Morning Coffee (5 photos)             │ ║
║  │ Urban Fall Gratitude (0 photos) 🔴                 │ ║
║  │ Cozy Home Moments (3 photos)                       │ ║
║  └────────────────────────────────────────────────────┘ ║
╚══════════════════════════════════════════════════════════╝
```

---

## Summary

This architecture provides:

1. **Content Pillar Definition**: Store pillars with weights, guidelines, examples
2. **Gap Analysis**: Automatically identify what content is needed
3. **AI Prompt Generation**: Generate creation prompts using Gemini/Ollama
4. **Manual Curation**: Human quality gate before clustering
5. **Manual Clustering**: Organize curated photos by pillar/campaign
6. **Strategic Scheduling**: Select from pillar-appropriate clusters

### Key Relationship: One Pillar → Many Clusters

**IMPORTANT**: Each pillar should have **multiple smaller clusters** (10-30 photos each), not one giant cluster.

**Example:**
```
Pillar: "Hobbies & Downtime" (25%)
  ├── Cluster: "Gymnastics Floor Routine Nov 2024" (15 photos)
  ├── Cluster: "Gymnastics Balance Beam Dec 2024" (12 photos)
  ├── Cluster: "Yoga Morning Practice" (10 photos)
  ├── Cluster: "Reading Cozy Evenings" (12 photos)
  └── Cluster: "Weekend Hiking Trails" (10 photos)
```

**Benefits:**
- **Variety**: Different sub-themes prevent repetition
- **Quality**: Easier to curate 10-30 photos than 100s
- **Strategic**: Rotate which cluster to use within pillar
- **Freshness**: Diverse content from single pillar

See `docs/content-pillars-clusters-guide.md` for detailed best practices.

**Next Steps:**
1. Implement database migrations
2. Build core models (ContentPillar, Request)
3. Create gap analysis service
4. Implement prompt generation
5. Build rake tasks for workflow
6. Test with Thanksgiving content

**Status**: Architecture designed, ready for implementation discussion

---

*Generated: 2025-11-06*  
*Updated: 2025-11-06 - Added cluster sizing guidance*  
*Focus: Pillar-driven content creation, not cluster-driven*
