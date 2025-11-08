# Proposal: Add Reels & Video Support to Instagram Posting

**Change ID:** `add-reels-video-support`  
**Status:** Draft  
**Created:** 2024-11-04  
**Milestone:** 5.5 (between 5b and 5c)  
**Priority:** High - Critical for reach optimization

---

## Problem Statement

### Current Limitation

The fluffy-train application currently **only supports static image posts** to Instagram. This creates a significant disadvantage:

**Performance Gap (Sarah's October Data):**
- **16% views from non-followers** - Far too low for growth
- **2.1k total reach** - Limited discovery potential
- **No Reels posted** - Missing Instagram's highest-reach format

**Research-Backed Disadvantage:**
- **Reels deliver 2.25x reach** vs static posts (research: 6M+ posts analyzed)
- **Reels generate 43% more engagement** than carousels
- **Reels heavily favored by algorithm** for Explore page, non-follower reach
- **Instagram explicitly recommends Reels** for growth ("Creating 1 reel and 10 posts each week")

### Business Impact

**Without Reels Support:**
- ❌ Missing 56% potential reach increase (2.25x multiplier)
- ❌ Unable to execute Instagram's recommended strategy (1 Reel + 10 posts/week)
- ❌ Limited non-follower discovery (stuck at 16% vs 30-50% possible)
- ❌ Cannot leverage trending audio for viral potential
- ❌ Reduced feed diversity hurts engagement

**With Reels Support:**
- ✅ Unlock 2.25x reach multiplier for growth
- ✅ Execute platform-recommended posting mix
- ✅ Increase non-follower reach to 30-50%
- ✅ Leverage trending audio and hashtag opportunities
- ✅ Provide format variety to reduce audience fatigue

### Why Now?

1. **Sarah's Instagram feedback explicitly recommends Reels** ("Creating 1 reel and 10 posts each week")
2. **Low non-follower reach (16%)** indicates poor discoverability
3. **Milestone 5b (Hashtags) + 5c (Automation) in progress** - Perfect timing for format expansion
4. **Research complete** - We have domain knowledge on Reels optimization
5. **Foundation exists** - Instagram Graph API client already built

---

## Proposed Solution

### High-Level Overview

**Extend fluffy-train to support Instagram Reels** by:
1. Adding video file support to photo library (MP4)
2. Implementing Reels-specific Instagram Graph API endpoints
3. Integrating Reels into content strategy engine (format selection logic)
4. Extending scheduling system to handle video posts
5. Adding Reels-specific metadata (audio, duration, aspect ratio)

### Architecture

#### Current State (Static Images Only)

```
┌─────────────────────────────────────────────────────────────┐
│ Content Strategy Engine                                     │
├─────────────────────────────────────────────────────────────┤
│ • SelectNextPost → Photo (static image)                     │
│ • Generate caption                                          │
│ • Generate hashtags                                         │
│ • Calculate optimal_time                                    │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ Scheduling::Post (draft)                                    │
├─────────────────────────────────────────────────────────────┤
│ • photo_id → Photo                                          │
│ • caption                                                   │
│ • hashtags                                                  │
│ • optimal_time_calculated                                   │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ Instagram::Client                                           │
├─────────────────────────────────────────────────────────────┤
│ • create_media_container(image_url, caption)                │
│ • publish_media_container(container_id)                     │
└─────────────────────────────────────────────────────────────┘
                       │
                       ▼
                   Instagram
               (Static Image Post)
```

#### Proposed State (Images + Reels/Videos)

```
┌─────────────────────────────────────────────────────────────┐
│ Content Strategy Engine                                     │
├─────────────────────────────────────────────────────────────┤
│ • SelectNextPost → MediaAsset (photo OR video)              │
│   ├─ If video: Mark as Reel                                 │
│   └─ If image: Static or Carousel                           │
│ • Generate caption (Reels-aware)                            │
│ • Generate hashtags (Reels-specific if video)               │
│ • Calculate optimal_time (Reels window if video)            │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ Scheduling::Post (draft)                                    │
├─────────────────────────────────────────────────────────────┤
│ • media_asset_id → MediaAsset (polymorphic)                 │
│ • media_type → 'photo' | 'video'                            │
│ • post_format → 'static' | 'carousel' | 'reel'              │
│ • caption (format-aware)                                    │
│ • hashtags                                                  │
│ • video_metadata → { duration, aspect_ratio, audio_name }   │
│ • optimal_time_calculated                                   │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ Instagram::Client (Enhanced)                                │
├─────────────────────────────────────────────────────────────┤
│ • create_media_container(image_url, caption)                │
│ • create_reel_container(video_url, caption, cover_url)      │
│ • publish_media_container(container_id)                     │
└─────────────────────────────────────────────────────────────┘
                       │
                       ▼
                   Instagram
         (Static Post OR Reel OR Carousel)
```

### Key Components

#### 1. Video/Media Asset Model (NEW)

**Purpose:** Unified storage for photos AND videos

```ruby
# app/models/media_asset.rb
class MediaAsset < ApplicationRecord
  # Polymorphic: Can be Photo or Video
  belongs_to :asset, polymorphic: true
  
  enum media_type: { photo: 0, video: 1 }
  enum post_format: { static: 0, carousel: 1, reel: 2 }
  
  # Common fields
  # - file_path: String
  # - file_size: Integer
  # - width: Integer
  # - height: Integer
  # - aspect_ratio: Decimal
  # - cluster_id: Integer (from clustering)
  # - aesthetic_score: Float
  # - created_at, updated_at
  
  # Video-specific
  # - duration: Integer (seconds)
  # - video_codec: String
  # - audio_codec: String
  # - audio_name: String (for trending audio)
  # - frame_rate: Integer
  
  validates :media_type, presence: true
  validates :file_path, presence: true, uniqueness: true
  validates :duration, presence: true, if: :video?
  validates :duration, numericality: { 
    greater_than_or_equal_to: 3,  # Instagram min
    less_than_or_equal_to: 90     # Instagram max for Reels
  }, if: :video?
end

# app/models/video.rb
class Video < ApplicationRecord
  has_one :media_asset, as: :asset
  
  # Video-specific embeddings if needed
  # - thumbnail_embeddings (CLIP for key frames)
  # - video_embeddings (future: video understanding)
end
```

**Migration Strategy:**
- Phase 1: Create `media_assets` table, `videos` table
- Phase 2: Backfill existing `photos` as media_assets (type: photo)
- Phase 3: Update associations (Scheduling::Post → media_asset_id)
- Phase 4: Deprecate direct photo_id (keep for backward compat)

#### 2. Instagram::Client Enhancement (MODIFIED)

**New Methods:**

```ruby
# packs/scheduling/app/clients/instagram/client.rb

# Create a Reel container
#
# @param video_url [String] Publicly accessible video URL
# @param caption [String] Caption text
# @param cover_url [String] Optional cover image URL
# @param share_to_feed [Boolean] Share Reel to main feed (default: true)
# @return [String] Container creation ID
def create_reel_container(video_url:, caption:, cover_url: nil, share_to_feed: true)
  response = connection.post("#{@account_id}/media") do |req|
    req.params['media_type'] = 'REELS'
    req.params['video_url'] = video_url
    req.params['caption'] = caption
    req.params['cover_url'] = cover_url if cover_url
    req.params['share_to_feed'] = share_to_feed
    req.params['access_token'] = @access_token
  end
  handle_response(response)['id']
end

# Check publishing status (Reels take longer to process)
#
# @param container_id [String] Media container ID
# @return [Hash] Status info: { status: 'IN_PROGRESS' | 'FINISHED' | 'ERROR' }
def check_container_status(container_id:)
  response = connection.get(container_id) do |req|
    req.params['fields'] = 'status_code,status'
    req.params['access_token'] = @access_token
  end
  handle_response(response)
end

# Enhanced publish with retry for Reels (they need processing time)
#
# @param creation_id [String] Container ID
# @param max_retries [Integer] Max status checks (default: 10)
# @param retry_delay [Integer] Seconds between checks (default: 5)
def publish_reel_container(creation_id, max_retries: 10, retry_delay: 5)
  # Check status until finished
  max_retries.times do
    status = check_container_status(container_id: creation_id)
    
    case status['status_code']
    when 'FINISHED'
      # Ready to publish
      return publish_media_container(creation_id)
    when 'ERROR'
      raise Error, "Reel processing failed: #{status['status']}"
    else
      # Still processing
      sleep(retry_delay)
    end
  end
  
  raise Error, 'Reel processing timed out'
end
```

**API Reference:**
- [Instagram Graph API - Reels Publishing](https://developers.facebook.com/docs/instagram-api/reference/ig-user/media#creating-reels)
- Key differences from static posts:
  - `media_type: 'REELS'` parameter required
  - Video processing takes 30-60 seconds (async)
  - Status check required before publishing
  - Cover image optional but recommended

#### 3. Content Strategy Integration (MODIFIED)

**Enhanced BaseStrategy:**

```ruby
# packs/content_strategy/app/services/content_strategy/base_strategy.rb

def select_media_asset(persona:, strategy_config:)
  # Determine format preference
  format = determine_format(persona, strategy_config)
  
  case format
  when :reel
    select_video_asset(persona)
  when :carousel
    select_carousel_photos(persona, count: 3..10)
  when :static
    select_photo_asset(persona)
  end
end

private

def determine_format(persona, config)
  # Strategy rules
  prefer_reels = config.dig(:format, :prefer_reels) || false
  prefer_carousels = config.dig(:format, :prefer_carousels) || true
  reel_frequency = config.dig(:format, :reel_posts_per_week) || 1
  
  # Check Reel quota for the week
  week_start = Date.today.beginning_of_week
  reels_this_week = ContentStrategy::HistoryRecord
    .where(persona: persona, posted_at: week_start..Date.today)
    .where(post_format: 'reel')
    .count
  
  # Format selection logic
  if prefer_reels && video_assets_available? && reels_this_week < reel_frequency
    :reel
  elsif prefer_carousels && rand < 0.4  # 40% carousels (research-backed)
    :carousel
  else
    :static
  end
end

def select_video_asset(persona)
  # Find best video from target cluster
  MediaAsset
    .where(media_type: :video, cluster_id: target_cluster_id)
    .where.not(id: posted_asset_ids(persona))
    .order(aesthetic_score: :desc, duration: :asc)  # Prefer shorter, higher quality
    .first
end
```

**Configuration Schema (strategy_config):**

```yaml
# Sarah's optimized config with Reels
posting_frequency_min: 4
posting_frequency_max: 4

format:
  prefer_reels: true                    # NEW
  prefer_carousels: true
  reel_posts_per_week: 1                # NEW: Instagram recommendation
  video_duration_preference: "short"    # NEW: "short" (15-30s) | "medium" (30-60s)
  
timing:
  optimal_time_start_hour: 9
  optimal_time_end_hour: 12
  reel_optimal_hours: [9, 10, 11]       # NEW: Reels-specific timing
  
variety:
  gap_days_between_same_cluster: 2
  avoid_format_repetition: true         # NEW: Don't post 2 Reels in a row
```

**Format Rotation Logic:**

```
Week Plan (Sarah: 4 posts/week, 1 Reel/week):
┌──────────┬────────────┬──────────────────────────────┐
│ Day      │ Format     │ Cluster                      │
├──────────┼────────────┼──────────────────────────────┤
│ Wed 9am  │ Reel       │ Urban Exploration            │
│ Thu 10am │ Carousel   │ Beach Lifestyle              │
│ Fri 11am │ Static     │ Home Interior                │
│ Sat 9am  │ Carousel   │ Travel Adventure             │
└──────────┴────────────┴──────────────────────────────┘

Format Diversity: ✅ 1 Reel, 2 Carousels, 1 Static
Cluster Diversity: ✅ No repeats
Timing: ✅ All within 9am-12pm optimal window
```

#### 4. Video Ingestion Pipeline (NEW)

**Purpose:** Process video files like photos (embeddings, clustering, scoring)

```ruby
# lib/tasks/videos.rake
namespace :videos do
  desc 'Ingest videos from directory'
  task :ingest, [:directory] => :environment do |t, args|
    directory = args[:directory] || ENV['VIDEO_DIR']
    
    Videos::IngestionService.call(directory: directory)
  end
  
  desc 'Generate embeddings for videos'
  task :generate_embeddings => :environment do
    Videos::EmbeddingService.call
  end
  
  desc 'Cluster videos with photos'
  task :cluster => :environment do
    # Combine video + photo embeddings for unified clustering
    Clustering::UnifiedClusteringService.call
  end
end
```

**Video Processing:**

```ruby
# app/services/videos/ingestion_service.rb
module Videos
  class IngestionService
    def self.call(directory:)
      Dir.glob("#{directory}/**/*.{mp4,mov}").each do |file_path|
        next if Video.exists?(file_path: file_path)
        
        # Extract metadata
        metadata = extract_video_metadata(file_path)
        
        # Validate
        next unless valid_for_reels?(metadata)
        
        # Create records
        video = Video.create!(
          file_path: file_path,
          duration: metadata[:duration],
          width: metadata[:width],
          height: metadata[:height],
          video_codec: metadata[:video_codec],
          audio_codec: metadata[:audio_codec]
        )
        
        MediaAsset.create!(
          asset: video,
          media_type: :video,
          post_format: :reel,
          duration: metadata[:duration],
          aspect_ratio: metadata[:aspect_ratio],
          file_path: file_path
        )
        
        # Generate thumbnail for clustering
        thumbnail_path = extract_thumbnail(file_path)
        generate_embeddings(thumbnail_path, video.id)
      end
    end
    
    private
    
    def valid_for_reels?(metadata)
      # Instagram Reels requirements
      metadata[:duration] >= 3 &&           # Min 3 seconds
      metadata[:duration] <= 90 &&          # Max 90 seconds
      metadata[:aspect_ratio] >= 0.5 &&     # Portrait or square
      metadata[:file_size] <= 4_000_000_000 # Max 4GB
    end
    
    def extract_video_metadata(file_path)
      # Use FFmpeg or similar
      {
        duration: 15,
        width: 1080,
        height: 1920,
        aspect_ratio: 0.5625,  # 9:16
        video_codec: 'h264',
        audio_codec: 'aac',
        file_size: 5_000_000
      }
    end
  end
end
```

**Clustering Strategy:**
- Extract **middle frame** as thumbnail
- Generate DINO + CLIP embeddings for thumbnail
- Cluster videos WITH photos (unified thematic clusters)
- Result: Videos and photos mixed in same clusters (e.g., "Urban Exploration" has both)

#### 5. Caption & Hashtag Adaptation (MODIFIED)

**Reels-Specific Caption Generation:**

```ruby
# Milestone 5a integration
# packs/content_strategy/app/services/caption_generations/generator.rb

def generate(photo:, persona:, cluster:, format: :static)
  prompt = build_prompt(photo, persona, cluster, format)
  
  result = OllamaClient.generate(
    model: persona.caption_config[:model],
    prompt: prompt
  )
  
  {
    text: result[:text],
    metadata: { format: format, model: persona.caption_config[:model] }
  }
end

private

def build_prompt(photo, persona, cluster, format)
  base = "You are #{persona.name}..."
  
  format_guidance = case format
  when :reel
    "This is a Reel (video). Write a caption that creates curiosity and encourages viewers to watch. Use a hook in the first line. Keep it punchy (60-100 chars)."
  when :carousel
    "This is a carousel post. Write a caption that hints at the story across multiple images. Encourage swiping."
  else
    "Write a thoughtful, engaging caption for this image."
  end
  
  "#{base}\n\n#{format_guidance}\n\nCluster: #{cluster.name}\n\nCaption:"
end
```

**Reels-Specific Hashtags:**

```ruby
# Milestone 5b integration
# packs/content_strategy/app/services/hashtag_generations/generator.rb

def generate(photo:, persona:, cluster:, format: :static, count: 9)
  base_tags = generate_base_tags(cluster, count: 7)
  
  format_tags = case format
  when :reel
    ['#Reels', '#ReelsInstagram', '#Trending']  # Reels-specific
  when :carousel
    ['#SwipeLeft', '#CarouselPost']
  else
    []
  end
  
  (base_tags + format_tags).take(count)
end
```

**Hashtag Research (Reels):**
- `#Reels` - 500M+ posts, high discovery
- `#ReelsInstagram` - 200M+ posts
- `#Trending` - Context-dependent
- Avoid over-generic tags like `#Viral` (spammy)

#### 6. Scheduling System Enhancement (MODIFIED)

**Database Changes:**

```ruby
# Migration: Add video support to scheduling_posts
class AddVideoSupportToSchedulingPosts < ActiveRecord::Migration[7.0]
  def change
    # Polymorphic association
    add_column :scheduling_posts, :media_asset_id, :bigint
    add_column :scheduling_posts, :media_type, :integer, default: 0  # photo
    add_column :scheduling_posts, :post_format, :integer, default: 0  # static
    
    # Video metadata
    add_column :scheduling_posts, :video_metadata, :jsonb, default: {}
    
    # Indexes
    add_index :scheduling_posts, :media_asset_id
    add_index :scheduling_posts, :media_type
    add_index :scheduling_posts, :post_format
    
    # Backward compatibility: Keep photo_id for now
    # Later: Data migration to populate media_asset_id from photo_id
  end
end
```

**Updated Model:**

```ruby
# packs/scheduling/app/models/scheduling/post.rb
module Scheduling
  class Post < ApplicationRecord
    belongs_to :photo, optional: true  # Backward compat
    belongs_to :media_asset, optional: true
    
    enum media_type: { photo: 0, video: 1 }
    enum post_format: { static: 0, carousel: 1, reel: 2 }
    
    validates :media_asset, presence: true, unless: :photo  # New or old
    validates :video_metadata, presence: true, if: :video?
    
    def media
      media_asset&.asset || photo
    end
    
    def reel?
      post_format == 'reel'
    end
  end
end
```

**Enhanced Posting Task:**

```ruby
# lib/tasks/scheduling.rake
namespace :scheduling do
  desc 'Post scheduled content (photos + videos)'
  task post_scheduled: :environment do
    due_posts = Scheduling::Post
      .where(status: 'draft')
      .where('optimal_time_calculated <= ?', Time.current)
      .where('optimal_time_calculated >= ?', 1.hour.ago)
    
    due_posts.each do |post|
      begin
        if post.reel?
          # Reels take longer - use background job
          Scheduling::PostReelJob.perform_later(post.id)
        else
          # Static/carousel - post immediately
          Scheduling::Commands::SendPostToInstagram.call(
            public_photo_url: generate_url(post.media),
            caption: post.caption,
            persona: post.persona
          )
          
          post.update!(status: 'posted', posted_at: Time.current)
        end
      rescue => e
        post.update!(status: 'failed', error_message: e.message)
        Rails.logger.error("Failed to post #{post.id}: #{e.message}")
      end
    end
  end
end
```

**Background Job for Reels:**

```ruby
# app/jobs/scheduling/post_reel_job.rb
module Scheduling
  class PostReelJob < ApplicationJob
    queue_as :default
    
    def perform(post_id)
      post = Scheduling::Post.find(post_id)
      
      # Upload video
      video_url = generate_public_video_url(post.media)
      cover_url = generate_public_cover_url(post.media)  # Thumbnail
      
      # Create Reel container
      instagram_client = Instagram::Client.new
      container_id = instagram_client.create_reel_container(
        video_url: video_url,
        caption: post.caption,
        cover_url: cover_url
      )
      
      # Wait for processing, then publish
      result = instagram_client.publish_reel_container(container_id)
      
      # Update post
      post.update!(
        status: 'posted',
        posted_at: Time.current,
        provider_post_id: result['id']
      )
      
      # Record in history
      ContentStrategy::HistoryRecord.create!(
        persona: post.persona,
        media_asset: post.media_asset,
        cluster_id: post.media_asset.cluster_id,
        strategy_type: post.strategy_type,
        post_format: post.post_format,
        posted_at: Time.current
      )
    rescue => e
      post.update!(status: 'failed', error_message: e.message)
      raise  # Retry job
    end
  end
end
```

---

## Implementation Plan

### Phase 1: Foundation (Days 1-3)

**Goal:** Add video/media asset data model

**Tasks:**
1. Create `media_assets` table
2. Create `videos` table
3. Create `MediaAsset` model (polymorphic)
4. Create `Video` model
5. Add associations
6. Write migration specs

**Acceptance:**
- Can create MediaAsset records for photos and videos
- Polymorphic association works (asset → Photo | Video)
- Validations enforce Instagram Reels requirements

### Phase 2: Video Ingestion (Days 4-6)

**Goal:** Process video files into system

**Tasks:**
1. Create `Videos::IngestionService`
2. Integrate FFmpeg for metadata extraction
3. Extract thumbnails for clustering
4. Generate CLIP/DINO embeddings for thumbnails
5. Create rake task `videos:ingest`
6. Test with sample videos

**Acceptance:**
- Can ingest folder of MP4 files
- Video metadata extracted (duration, aspect ratio, codec)
- Thumbnails generated and stored
- Embeddings generated for clustering

### Phase 3: Instagram API Enhancement (Days 7-9)

**Goal:** Support Reels publishing via Instagram Graph API

**Tasks:**
1. Add `create_reel_container` to Instagram::Client
2. Add `check_container_status` for async processing
3. Add `publish_reel_container` with retry logic
4. Write API integration specs
5. Test with Instagram test account

**Acceptance:**
- Can create Reel container via API
- Status check works (waits for processing)
- Can publish processed Reel
- Error handling for failed uploads

### Phase 4: Content Strategy Integration (Days 10-12)

**Goal:** Integrate Reels into strategy engine

**Tasks:**
1. Enhance BaseStrategy with format selection logic
2. Add `determine_format` method
3. Add `select_video_asset` method
4. Update strategy configuration schema
5. Implement format rotation rules
6. Test with ThemeOfTheWeekStrategy

**Acceptance:**
- Strategy can select video assets
- Format rotation works (1 Reel/week respected)
- Configuration supports `prefer_reels`, `reel_posts_per_week`
- Variety enforcement prevents consecutive Reels

### Phase 5: Caption & Hashtag Adaptation (Days 13-14)

**Goal:** Format-aware caption and hashtag generation

**Tasks:**
1. Add `format` parameter to CaptionGenerations::Generator
2. Build Reels-specific prompt templates
3. Add format-specific hashtag rules
4. Update hashtag pool with Reel tags
5. Test with sample videos

**Acceptance:**
- Captions for Reels are punchy and hook-driven
- Hashtags include Reel-specific tags (#Reels, #ReelsInstagram)
- Caption length appropriate for format

### Phase 6: Scheduling Enhancement (Days 15-17)

**Goal:** Support video posts in scheduling system

**Tasks:**
1. Migration: Add media_asset_id, media_type, post_format to scheduling_posts
2. Update Scheduling::Post model
3. Create Scheduling::PostReelJob
4. Enhance scheduling:post_scheduled task
5. Add video URL generation
6. Test end-to-end posting

**Acceptance:**
- Can create scheduled post with video
- Rake task handles Reels differently (background job)
- Reel posting works end-to-end (upload → process → publish)
- History records capture post_format

### Phase 7: Clustering Integration (Days 18-19)

**Goal:** Cluster videos with photos

**Tasks:**
1. Enhance Clustering::ClusteringService to handle MediaAssets
2. Combine photo + video embeddings in clustering
3. Update cluster assignment logic
4. Re-cluster library with videos included
5. Verify mixed clusters (photos + videos)

**Acceptance:**
- Videos and photos in same clusters
- Cluster browsing shows both media types
- Content strategy can select from mixed pools

### Phase 8: Testing & Validation (Days 20-22)

**Goal:** End-to-end testing and validation

**Tasks:**
1. Integration test: Ingest → Cluster → Strategy → Schedule → Post
2. Test Sarah's strategy with 1 Reel/week
3. Monitor Instagram Insights for Reel performance
4. Fix bugs and edge cases
5. Documentation update

**Acceptance:**
- Full pipeline works: Video ingested → Scheduled → Posted as Reel
- Sarah's strategy posts 1 Reel + 3 other posts/week
- Reels appear correctly on Instagram
- Monitoring dashboard shows Reels

### Phase 9: Production Deployment (Days 23-25)

**Goal:** Deploy to production

**Tasks:**
1. Deploy database migrations
2. Backfill existing photos as media_assets
3. Deploy code changes
4. Ingest initial video library
5. Update Sarah's strategy config (prefer_reels: true)
6. Monitor first week of Reels

**Acceptance:**
- Production database updated
- Existing photos migrated
- Videos ingested and clustered
- First Reel posted successfully
- Monitoring active

### Phase 10: Performance Monitoring (Weeks 4-6)

**Goal:** Measure impact and optimize

**Tasks:**
1. Track non-follower reach % (target: 30%+)
2. Compare Reel engagement vs static posts
3. Analyze optimal Reel timing
4. Optimize video duration preference
5. A/B test Reel frequency (1 vs 2 per week)
6. Adjust strategy based on data

**Success Metrics:**
- Non-follower reach increases from 16% to 30%+
- Reels achieve 2x+ reach vs static posts
- Total weekly reach increases 40%+
- Engagement rate maintained or improved

**Total Timeline:** ~5 weeks (25 days implementation + 2 weeks monitoring)

---

## Database Schema Changes

### New Tables

#### `media_assets` (Core abstraction)

```sql
CREATE TABLE media_assets (
  id BIGSERIAL PRIMARY KEY,
  asset_type VARCHAR(50) NOT NULL,        -- 'Photo' | 'Video'
  asset_id BIGINT NOT NULL,               -- Polymorphic ID
  media_type INTEGER NOT NULL DEFAULT 0,  -- 0: photo, 1: video
  post_format INTEGER NOT NULL DEFAULT 0, -- 0: static, 1: carousel, 2: reel
  
  -- File metadata
  file_path VARCHAR(500) NOT NULL UNIQUE,
  file_size BIGINT,
  
  -- Dimensions
  width INTEGER,
  height INTEGER,
  aspect_ratio DECIMAL(5,4),
  
  -- Clustering (inherited from photos/videos)
  cluster_id BIGINT REFERENCES clustering_clusters(id),
  
  -- Quality
  aesthetic_score FLOAT,
  technical_score FLOAT,
  
  -- Video-specific (NULL for photos)
  duration INTEGER,                       -- Seconds
  video_codec VARCHAR(50),
  audio_codec VARCHAR(50),
  audio_name VARCHAR(200),                -- Trending audio name
  frame_rate INTEGER,
  
  -- Timestamps
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  
  INDEX idx_media_assets_type (media_type),
  INDEX idx_media_assets_format (post_format),
  INDEX idx_media_assets_cluster (cluster_id),
  INDEX idx_media_assets_polymorphic (asset_type, asset_id),
  UNIQUE INDEX idx_media_assets_file_path (file_path)
);
```

#### `videos` (Video-specific data)

```sql
CREATE TABLE videos (
  id BIGSERIAL PRIMARY KEY,
  file_path VARCHAR(500) NOT NULL UNIQUE,
  
  -- Metadata
  duration INTEGER NOT NULL,              -- Seconds
  width INTEGER NOT NULL,
  height INTEGER NOT NULL,
  aspect_ratio DECIMAL(5,4),
  video_codec VARCHAR(50),
  audio_codec VARCHAR(50),
  audio_name VARCHAR(200),
  frame_rate INTEGER,
  file_size BIGINT,
  
  -- Thumbnail for clustering
  thumbnail_path VARCHAR(500),
  
  -- Embeddings (if needed separately)
  clip_embedding VECTOR(512),
  dino_embedding VECTOR(768),
  
  -- Clustering
  cluster_id BIGINT REFERENCES clustering_clusters(id),
  
  -- Quality
  aesthetic_score FLOAT,
  
  -- Timestamps
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  
  INDEX idx_videos_cluster (cluster_id),
  INDEX idx_videos_duration (duration),
  UNIQUE INDEX idx_videos_file_path (file_path)
);
```

### Modified Tables

#### `scheduling_posts` (Add video support)

```sql
ALTER TABLE scheduling_posts
  ADD COLUMN media_asset_id BIGINT REFERENCES media_assets(id),
  ADD COLUMN media_type INTEGER DEFAULT 0,      -- 0: photo, 1: video
  ADD COLUMN post_format INTEGER DEFAULT 0,     -- 0: static, 1: carousel, 2: reel
  ADD COLUMN video_metadata JSONB DEFAULT '{}',
  ADD INDEX idx_scheduling_posts_media_asset (media_asset_id),
  ADD INDEX idx_scheduling_posts_media_type (media_type),
  ADD INDEX idx_scheduling_posts_post_format (post_format);

-- video_metadata JSON structure:
-- {
--   "duration": 15,
--   "aspect_ratio": 0.5625,
--   "audio_name": "trending-song-2024",
--   "processing_time": 45,
--   "cover_image_url": "https://..."
-- }
```

#### `content_strategy_history_records` (Track format)

```sql
ALTER TABLE content_strategy_history_records
  ADD COLUMN media_asset_id BIGINT REFERENCES media_assets(id),
  ADD COLUMN post_format INTEGER DEFAULT 0,     -- 0: static, 1: carousel, 2: reel
  ADD INDEX idx_history_media_asset (media_asset_id),
  ADD INDEX idx_history_post_format (post_format);
```

#### `content_strategy_states` (Add format config)

```sql
-- strategy_config JSON enhancement:
-- {
--   "format": {
--     "prefer_reels": true,
--     "prefer_carousels": true,
--     "reel_posts_per_week": 1,
--     "video_duration_preference": "short",
--     "avoid_format_repetition": true
--   },
--   ...
-- }
```

---

## Configuration Updates

### Sarah's Strategy Config (Enhanced)

```yaml
# Sarah's optimized config WITH Reels support
active_strategy: "ContentStrategy::ThemeOfTheWeekStrategy"

strategy_config:
  posting_frequency_min: 4
  posting_frequency_max: 4
  
  format:
    prefer_reels: true                      # NEW: Enable Reels
    prefer_carousels: true
    reel_posts_per_week: 1                  # NEW: 1 Reel/week (Instagram rec)
    video_duration_preference: "short"      # NEW: 15-30s preferred
    avoid_format_repetition: true           # NEW: No 2 Reels in a row
    carousel_frequency: 0.4                 # 40% chance
  
  timing:
    optimal_time_start_hour: 9
    optimal_time_end_hour: 12
    timezone: "America/New_York"
    reel_optimal_hours: [9, 10, 11]         # NEW: Reels timing
  
  variety:
    gap_days_between_same_cluster: 2
    avoid_back_to_back_same_format: true    # NEW
  
  hashtags:
    count: 9
    strategy: "intelligent"                 # Milestone 5b
    reel_specific_tags: true                # NEW: Add #Reels, etc.
  
  captions:
    style: "persona_aware"                  # Milestone 5a
    format_aware: true                      # NEW: Reels get hooks
```

### Expected Weekly Schedule (Sarah)

```
Week 1 (4 posts):
┌────────────┬────────────┬──────────────────────┬─────────────────┐
│ Day        │ Time       │ Format               │ Cluster         │
├────────────┼────────────┼──────────────────────┼─────────────────┤
│ Wed Nov 6  │ 9:30 AM ET │ Reel (15s)           │ Urban Explor.   │
│ Thu Nov 7  │ 10:00 AM   │ Carousel (5 images)  │ Beach Life      │
│ Fri Nov 8  │ 11:00 AM   │ Static               │ Home Interior   │
│ Sat Nov 9  │ 9:00 AM    │ Carousel (3 images)  │ Travel Advent.  │
└────────────┴────────────┴──────────────────────┴─────────────────┘

Format Mix: ✅ 1 Reel, 2 Carousels, 1 Static (25% Reels)
Cluster Diversity: ✅ 4 different themes
Timing: ✅ All within 9am-12pm window
```

---

## Testing Strategy

### Unit Tests

```ruby
# spec/models/media_asset_spec.rb
RSpec.describe MediaAsset do
  it 'validates video duration is between 3-90 seconds' do
    video = build(:media_asset, :video, duration: 2)
    expect(video).not_to be_valid
    expect(video.errors[:duration]).to include('must be greater than or equal to 3')
  end
end

# spec/services/videos/ingestion_service_spec.rb
RSpec.describe Videos::IngestionService do
  it 'ingests valid MP4 files' do
    expect {
      described_class.call(directory: 'spec/fixtures/videos')
    }.to change(Video, :count).by(3)
  end
  
  it 'skips videos shorter than 3 seconds' do
    # ...
  end
end

# spec/clients/instagram/client_spec.rb
RSpec.describe Instagram::Client do
  describe '#create_reel_container' do
    it 'creates a Reel media container' do
      VCR.use_cassette('instagram/create_reel') do
        client = Instagram::Client.new
        container_id = client.create_reel_container(
          video_url: 'https://example.com/video.mp4',
          caption: 'Test Reel'
        )
        
        expect(container_id).to be_present
      end
    end
  end
end
```

### Integration Tests

```ruby
# spec/integration/reels_posting_spec.rb
RSpec.describe 'Reels Posting Pipeline' do
  it 'posts a Reel end-to-end' do
    # Setup
    persona = create(:persona, :sarah)
    video = create(:video, :with_embeddings)
    create(:media_asset, asset: video, media_type: :video, post_format: :reel)
    
    # Execute strategy
    result = ContentStrategy::SelectNextPost.call(persona: persona)
    
    expect(result.media_asset.media_type).to eq('video')
    expect(result.post_format).to eq('reel')
    
    # Create scheduled post
    post = Scheduling::Post.create!(
      persona: persona,
      media_asset: result.media_asset,
      caption: result.caption,
      media_type: :video,
      post_format: :reel,
      optimal_time_calculated: 5.minutes.ago
    )
    
    # Post to Instagram
    VCR.use_cassette('instagram/post_reel') do
      Scheduling::PostReelJob.perform_now(post.id)
    end
    
    post.reload
    expect(post.status).to eq('posted')
    expect(post.provider_post_id).to be_present
  end
end
```

### Performance Tests

```ruby
# spec/performance/video_ingestion_spec.rb
RSpec.describe 'Video Ingestion Performance' do
  it 'ingests 100 videos in under 5 minutes' do
    time = Benchmark.realtime do
      Videos::IngestionService.call(directory: 'spec/fixtures/videos_large')
    end
    
    expect(time).to be < 300  # 5 minutes
  end
end
```

---

## Risks & Mitigation

### Risk 1: Video Processing Time

**Risk:** Reels take 30-60 seconds to process on Instagram's servers, delaying publishing.

**Mitigation:**
- Use background job (Scheduling::PostReelJob) to avoid blocking
- Implement retry logic with exponential backoff
- Set max retry time to 10 minutes
- Send notification if processing fails

### Risk 2: Video Storage Costs

**Risk:** Videos are 10-100x larger than photos, increasing storage costs.

**Mitigation:**
- Compress videos before ingestion (FFmpeg)
- Use cloud storage with lifecycle policies (delete after posting)
- Set max file size limit (100MB)
- Archive old videos after 90 days

### Risk 3: Clustering Accuracy

**Risk:** Video thumbnails may not represent full video content, affecting clustering.

**Mitigation:**
- Extract multiple frames (beginning, middle, end) and average embeddings
- Manual cluster curation (Milestone 4b) to verify mixed clusters
- Future: Video-specific embeddings (CLIP-Video, VideoMAE)

### Risk 4: Instagram API Rate Limits

**Risk:** Reels API may have stricter rate limits than photo API.

**Mitigation:**
- Monitor rate limit headers in API responses
- Implement circuit breaker pattern (open after 5 failures)
- Space out Reel posts (not all at once)
- Fallback to static posts if Reel quota exceeded

### Risk 5: Audio/Music Copyright

**Risk:** Videos with copyrighted audio may be blocked by Instagram.

**Mitigation:**
- Use royalty-free audio libraries
- Detect audio tracks and warn if copyrighted
- Provide option to mute audio before upload
- Monitor post-publishing for takedowns

### Risk 6: Aspect Ratio Mismatch

**Risk:** Videos not in 9:16 format may be cropped or rejected.

**Mitigation:**
- Validate aspect ratio during ingestion (0.5-1.91 acceptable)
- Auto-crop videos to 9:16 if needed (FFmpeg)
- Prefer portrait videos in strategy selection
- Reject landscape videos (< 0.5 aspect ratio)

---

## Success Metrics

### Primary Metrics (Sarah's Account)

**Target Outcome (First 30 Days):**

| Metric                        | Before (Oct) | Target (Nov) | Stretch Goal |
|-------------------------------|--------------|--------------|--------------|
| Total Views                   | 2,100        | 3,500        | 5,000        |
| Non-Follower Reach %          | 16%          | 30%          | 40%          |
| Avg Reach per Post            | 64           | 125          | 175          |
| Reel Reach (avg)              | N/A          | 200+         | 300+         |
| Engagement Rate               | N/A          | 1.5%         | 2.0%         |
| New Followers                 | 3            | 10           | 20           |

**Leading Indicators (Week 1-2):**
- First Reel posted successfully ✅
- Reel reaches 2x+ static post performance ✅
- No posting failures or errors ✅
- Format variety maintained (1 Reel, 2 Carousels, 1 Static) ✅

**Engagement Breakdown:**
```
Expected Performance by Format:
┌────────────┬────────┬──────────┬──────────────┬────────┐
│ Format     │ Count  │ Avg      │ Non-Follower │ Engage │
│            │ /Week  │ Reach    │ Reach %      │ Rate   │
├────────────┼────────┼──────────┼──────────────┼────────┤
│ Reel       │ 1      │ 250      │ 45%          │ 1.8%   │
│ Carousel   │ 2      │ 100      │ 25%          │ 1.6%   │
│ Static     │ 1      │ 75       │ 20%          │ 1.2%   │
├────────────┼────────┼──────────┼──────────────┼────────┤
│ Total/Avg  │ 4      │ 131      │ 32%          │ 1.5%   │
└────────────┴────────┴──────────┴──────────────┴────────┘

Weekly Total: ~525 views (vs Oct: ~420)
Improvement: +25% reach, +100% non-follower discovery
```

### Technical Metrics

**System Performance:**
- Video ingestion: < 30 seconds per video
- Reel posting: < 90 seconds (including Instagram processing)
- Strategy execution: < 5 seconds (format selection)
- Error rate: < 5% (Reel posting failures)

**Data Quality:**
- Video clustering accuracy: 80%+ (manual validation)
- Format distribution: 25% Reels, 50% Carousels, 25% Static
- Timing accuracy: 95%+ posts within optimal window

---

## Future Enhancements

### Phase 2 Features (Post-MVP)

**1. Multi-Clip Reels**
- Stitch multiple short clips into one Reel
- Auto-transition effects
- Background music integration

**2. Video-Specific Embeddings**
- CLIP-Video for temporal understanding
- VideoMAE for action recognition
- Better clustering based on motion/content

**3. Trending Audio Integration**
- Instagram Trends API (if available)
- Auto-select trending audio for Reels
- Match audio to video content

**4. A/B Testing for Reels**
- Test different video lengths (15s vs 30s vs 60s)
- Test posting times for Reels specifically
- Test cover image variations

**5. Carousel + Video Mix**
- Carousels with video slides
- Instagram supports mixed media carousels

**6. Stories Integration**
- Repost Reels to Stories
- Use Stories for behind-the-scenes
- Integrate Stories into content strategy

---

## Dependencies

### External Services

**Required:**
- Instagram Graph API v20.0+ (Reels support)
- FFmpeg for video processing
- Cloud storage for video files (AWS S3, Cloudflare R2)

**Optional:**
- Video compression service (Cloudinary, Mux)
- Audio detection API (ACRCloud for music ID)
- Trending audio API (third-party)

### Existing Milestones

**Depends On:**
- ✅ Milestone 2: Photo Analysis (aesthetic scoring)
- ✅ Milestone 4a: Clustering Engine (embed videos in clusters)
- ✅ Milestone 4b: Cluster Management (curate mixed clusters)
- ✅ Milestone 4c: Content Strategy (format selection logic)
- ✅ Milestone 5a: Caption Generation (format-aware captions)
- 🟡 Milestone 5b: Hashtag Generation (format-aware hashtags)

**Enables:**
- Milestone 5c: Full Automation (Reels in automated pipeline)
- Milestone 5d: Feedback Loop (Reel performance tracking)
- Milestone 6: Generative Feedback (video generation)

---

## Acceptance Criteria

### From Roadmap (Adapted)

This milestone is not explicitly in the roadmap but fits between Milestones 5b and 5c. Acceptance criteria based on roadmap patterns:

**AC1: Video Ingestion**
- The system can successfully ingest a directory of at least 50 MP4 videos.
- Video metadata (duration, aspect ratio, codec) is extracted and stored.
- Thumbnails are generated for clustering.
- Videos are validated against Instagram Reels requirements (3-90s, portrait/square).

**AC2: Instagram Reels API Integration**
- The Instagram::Client can create a Reel media container via the Graph API.
- The client can check processing status and wait for completion.
- The client can publish the processed Reel.
- Error handling works for failed uploads, timeouts, and invalid formats.

**AC3: Content Strategy Integration**
- ContentStrategy can select video assets from clusters.
- Format selection logic respects `reel_posts_per_week` quota.
- Format variety is maintained (no 2 Reels in a row unless configured).
- Strategy correctly mixes Reels with Carousels and Static posts.

**AC4: End-to-End Posting**
- A scheduled post with `media_type: :video` is created by the content strategy.
- The scheduling task detects the video and delegates to PostReelJob.
- The background job uploads the video, waits for processing, and publishes.
- The post status is updated to 'posted' with Instagram post ID.
- The ContentStrategy::HistoryRecord captures the Reel format.

**AC5: Performance Impact**
- Sarah's account posts 1 Reel per week (per Instagram recommendation).
- Non-follower reach increases from 16% to 30%+ within 30 days.
- Reels achieve 2x+ reach compared to static posts.
- Total weekly reach increases by 25%+ compared to October baseline.

**AC6: Format-Aware Generation**
- CaptionGenerations::Generator produces Reel-appropriate captions (hooks, punchy).
- HashtagGenerations::Generator includes Reel-specific tags (#Reels, #ReelsInstagram).
- Caption + hashtag combination fits Instagram's character limits.

---

## Questions & Open Issues

### Q1: How do we source videos initially?

**Options:**
- **Option A:** User-provided videos (manual upload)
- **Option B:** Generate videos from photos (slideshow/motion effects)
- **Option C:** Stock video libraries (Pexels, Unsplash)
- **Option D:** AI-generated videos (FLUX Video, Runway ML)

**Recommendation:** Start with Option A (user-provided), explore Option D in Milestone 6.

### Q2: Should we support Stories?

Stories have different requirements (ephemeral, 24h, different API). Recommend separate milestone (Milestone 5.6).

### Q3: How handle videos without audio?

Instagram allows silent Reels. Option to add royalty-free music or post as-is.

### Q4: Carousel + video support?

Instagram supports mixed media carousels (images + videos). Add in Phase 2.

### Q5: Video generation from photos?

Ken Burns effect, parallax, AI motion (Runway ML). Future milestone (6+).

---

## References

### Instagram Graph API Documentation

- [Reels Publishing](https://developers.facebook.com/docs/instagram-api/reference/ig-user/media#creating-reels)
- [Media Publishing](https://developers.facebook.com/docs/instagram-api/guides/content-publishing)
- [Media Container Status](https://developers.facebook.com/docs/instagram-api/reference/ig-container)

### Research Sources

- Instagram Domain Knowledge Document (docs/research/content-strategy-engine/instagram-domain-knowledge.md)
  - Section 3: Content Format Performance
  - Section 4: Posting Frequency (Reels 4-7/week)
  - Section 2: Algorithm (Reels completion rate signal)

### Technical Resources

- FFmpeg: Video processing, transcoding, thumbnail extraction
- CLIP-Video: Temporal video embeddings (OpenAI)
- VideoMAE: Video understanding (Microsoft)

---

## Conclusion

Adding Reels/video support to fluffy-train is a **high-impact enhancement** that directly addresses Sarah's low non-follower reach (16%) and aligns with Instagram's algorithmic preferences. By implementing this milestone:

1. **Unlock 2.25x reach multiplier** (research-backed)
2. **Follow Instagram's recommendations** (1 Reel + 10 posts/week)
3. **Increase non-follower discovery** from 16% to 30%+
4. **Diversify content formats** to reduce audience fatigue
5. **Prepare for future automation** (Milestone 5c integration)

The implementation is **feasible** with existing infrastructure (Instagram API client, strategy engine, clustering) and requires **~5 weeks** including testing and monitoring.

**Next Steps:**
1. Approve proposal
2. Prioritize against Milestones 5b/5c timeline
3. Source initial video library (50+ videos)
4. Begin Phase 1 (data model)

---

**Proposal Author:** AI Assistant  
**Stakeholder:** Tim (Product Owner)  
**Review Date:** 2024-11-04  
**Target Start:** After Milestone 5b completion  
**Target Completion:** 5 weeks from start
