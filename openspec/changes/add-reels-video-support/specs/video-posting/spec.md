# Reels & Video Posting Capability

**Change**: add-reels-video-support  
**Status**: ADDED

---

## ADDED Requirements

### Requirement: Video Asset Model

The system SHALL support video files as first-class media assets alongside photos.

**Details:**
- Video files (MP4, MOV) can be ingested into the library
- Video metadata (duration, aspect ratio, codec, audio) SHALL be extracted and stored
- Videos SHALL be validated against Instagram Reels requirements (3-90s duration, 0.5-1.91 aspect ratio, ≤4GB)
- Videos SHALL have polymorphic association via `MediaAsset` model
- Videos SHALL be associated with clusters (same as photos)

#### Scenario: Ingest Valid Video File

- **GIVEN** a directory contains a valid MP4 file (15s, 1080x1920, H.264/AAC)
- **WHEN** user runs `rake videos:ingest[/path/to/videos]`
- **THEN** video record SHALL be created with correct metadata
- **AND** MediaAsset SHALL be created with media_type: video, post_format: reel
- **AND** thumbnail SHALL be extracted and stored
- **AND** CLIP + DINO embeddings SHALL be generated
- **AND** no validation errors SHALL occur

#### Scenario: Reject Invalid Video Duration

- **GIVEN** a directory contains an invalid MP4 file (2s duration, too short)
- **WHEN** user runs `rake videos:ingest[/path/to/videos]`
- **THEN** video SHALL be skipped (not ingested)
- **AND** warning SHALL be logged: "Video too short (2s), minimum 3s for Reels"
- **AND** no Video or MediaAsset record SHALL be created

#### Scenario: Reject Invalid Aspect Ratio

- **GIVEN** a video file with aspect ratio 1.78 (landscape, 16:9)
- **WHEN** Videos::IngestionService processes the file
- **THEN** video SHALL be rejected (aspect ratio > 1.91)
- **AND** warning SHALL be logged: "Video aspect ratio 1.78 exceeds Instagram limit (0.5-1.91)"
- **AND** no Video or MediaAsset record SHALL be created

---

### Requirement: Instagram Reels API Integration

The Instagram::Client SHALL support creating and publishing Reels via Instagram Graph API v20.0+.

**Details:**
- Method: `create_reel_container(video_url:, caption:, cover_url:)` creates Reel container
- Method: `check_container_status(container_id:)` checks async processing status
- Method: `publish_reel_container(creation_id:)` publishes with retry logic
- Retry mechanism with exponential backoff (up to 10 attempts, 5s intervals)
- Error handling for processing failures, timeouts, invalid formats

#### Scenario: Create Reel Container via API

- **GIVEN** valid Instagram credentials configured
- **AND** public video URL: `https://example.com/video.mp4`
- **AND** caption: "Exploring the city 🏙️ #Reels"
- **WHEN** Instagram::Client.create_reel_container(video_url: url, caption: caption) is called
- **THEN** API request SHALL be sent to Instagram with media_type: 'REELS'
- **AND** container creation ID SHALL be returned (e.g., "17234567890")
- **AND** no API errors SHALL occur

#### Scenario: Wait for Reel Processing

- **GIVEN** Reel container created (creation_id: "12345")
- **AND** Instagram processing video (status: 'IN_PROGRESS')
- **WHEN** Instagram::Client.check_container_status(container_id: "12345") is called
- **THEN** status SHALL be checked via API
- **AND** SHALL return: `{ status_code: 'IN_PROGRESS' }`
- **AND** retry mechanism SHALL wait 5 seconds and check again

#### Scenario: Publish Processed Reel

- **GIVEN** Reel container processed (status: 'FINISHED')
- **AND** container ID: "12345"
- **WHEN** Instagram::Client.publish_reel_container(creation_id: "12345") is called
- **THEN** API request SHALL be sent to publish media
- **AND** Instagram post ID SHALL be returned (e.g., "17987654321")
- **AND** Reel SHALL be visible on Instagram profile and Reels tab

#### Scenario: Handle Processing Timeout

- **GIVEN** Reel container created
- **AND** status remains 'IN_PROGRESS' after 10 retries (50 seconds)
- **WHEN** Instagram::Client.publish_reel_container(creation_id: "12345", max_retries: 10) is called
- **THEN** method SHALL raise Error: "Reel processing timed out"
- **AND** post SHALL be marked as 'failed'
- **AND** admin notification SHALL be sent

---

### Requirement: Format Selection Logic

The content strategy engine SHALL intelligently select post format (Reel, Carousel, Static) based on configuration and variety rules.

**Details:**
- Strategy configuration includes: `prefer_reels`, `reel_posts_per_week`, `video_duration_preference`, `avoid_format_repetition`
- Format selection algorithm checks Reel quota, video availability, and variety rules
- Format distribution tracked in history

#### Scenario: Select Video for Reel Post

- **GIVEN** Sarah's strategy config: `prefer_reels: true, reel_posts_per_week: 1`
- **AND** 0 Reels posted this week
- **AND** videos available in target cluster "Urban Exploration"
- **WHEN** ContentStrategy::SelectNextPost.call(persona: sarah) is executed
- **THEN** selected media_asset SHALL be a video
- **AND** post_format SHALL be 'reel'
- **AND** caption SHALL be Reel-appropriate (hook, punchy)
- **AND** hashtags SHALL include #Reels, #ReelsInstagram

#### Scenario: Respect Reel Quota

- **GIVEN** Sarah's strategy config: `reel_posts_per_week: 1`
- **AND** 1 Reel already posted this week
- **AND** videos available in target cluster
- **WHEN** ContentStrategy::SelectNextPost.call(persona: sarah) is executed
- **THEN** selected media_asset SHALL NOT be a video
- **AND** post_format SHALL be 'carousel' or 'static'
- **AND** format selection SHALL skip Reels (quota reached)

#### Scenario: Avoid Consecutive Reels

- **GIVEN** Sarah's strategy config: `avoid_format_repetition: true, reel_posts_per_week: 2`
- **AND** last post was a Reel
- **AND** videos available
- **WHEN** ContentStrategy::SelectNextPost.call(persona: sarah) is executed
- **THEN** selected media_asset SHALL NOT be a video
- **AND** post_format SHALL be 'carousel' or 'static'
- **AND** variety rule SHALL prevent back-to-back Reels

#### Scenario: Fallback When No Videos Available

- **GIVEN** Sarah's strategy config: `prefer_reels: true, reel_posts_per_week: 1`
- **AND** 0 Reels posted this week
- **AND** NO videos available in any cluster
- **WHEN** ContentStrategy::SelectNextPost.call(persona: sarah) is executed
- **THEN** format selection SHALL detect no videos available
- **AND** SHALL fall back to carousel or static
- **AND** SHALL log warning: "Reels preferred but no videos available, selecting photo"
- **AND** post SHALL be created with photo media_asset

---

### Requirement: Video URL Generation

The system SHALL generate publicly accessible HTTPS URLs for video files to send to Instagram API.

**Details:**
- Service: `Videos::PublicUrlGenerator.call(video:)` generates URLs
- Supports cloud storage (S3, Cloudflare R2) or local serving
- URLs MUST be HTTPS and publicly accessible (Instagram requirement)
- Temporary signed URLs with 1-hour expiration (security)

#### Scenario: Generate Public Video URL

- **GIVEN** a video record with file_path: "/videos/urban_exploration.mp4"
- **WHEN** Videos::PublicUrlGenerator.call(video: video) is executed
- **THEN** public HTTPS URL SHALL be returned
- **AND** URL SHALL be accessible without authentication
- **AND** URL SHALL expire after 1 hour

---

### Requirement: Error Handling & Recovery

The system SHALL gracefully handle video upload failures with retry logic and circuit breaker.

**Details:**
- Retry logic: Up to 3 retries for transient failures with exponential backoff (1s, 2s, 4s)
- Circuit breaker: After 5 consecutive failures, pause Reel posting for 1 hour
- Status updates: Mark post as 'failed' with error message
- Notifications: Alert admin on persistent failures

#### Scenario: Transient Failure Retry

- **GIVEN** scheduled Reel post
- **AND** Instagram API rate limit hit (429 error)
- **WHEN** PostReelJob executes
- **THEN** first attempt SHALL fail with 429 error
- **AND** SHALL retry after 1 second
- **AND** retry SHALL succeed
- **AND** post status SHALL be 'posted'
- **AND** no admin alert SHALL be sent (transient failure resolved)

#### Scenario: Circuit Breaker Opens After Persistent Failures

- **GIVEN** 5 consecutive Reel posts failed (Instagram API down)
- **WHEN** 6th Reel post is scheduled
- **THEN** circuit breaker SHALL open
- **AND** Reel posting SHALL be paused for 1 hour
- **AND** strategy SHALL fall back to static/carousel posts
- **AND** admin notification SHALL be sent: "Reel posting circuit breaker opened"

---

### Requirement: Weekly Format Distribution

The system SHALL maintain balanced format distribution per persona's strategy configuration.

**Details:**
- Format mix: Reels (25%), Carousels (50%), Static (25%) adjustable per persona
- Weekly quota enforcement (e.g., 1 Reel/week for Sarah)
- Format variety rules prevent monotony

#### Scenario: Create Weekly Schedule with Format Mix

- **GIVEN** Sarah's strategy config: 4 posts/week, 1 Reel/week
- **AND** week starts Monday
- **WHEN** automation creates 4 posts for the week
- **THEN** SHALL create 1 Reel post (video)
- **AND** SHALL create 2 Carousel posts (multiple photos)
- **AND** SHALL create 1 Static post (single photo)
- **AND** format distribution SHALL be: 25% Reels, 50% Carousels, 25% Static
- **AND** all posts SHALL be in different clusters

---

## MODIFIED Requirements

### Requirement: Unified Clustering

The clustering engine SHALL cluster videos and photos together based on thematic similarity.

**Changes:**
- Clustering::ClusteringService now handles `MediaAsset` (not just `Photo`)
- Cluster::photos association extended to Cluster::media_assets

#### Scenario: Cluster Videos with Photos

- **GIVEN** 100 photos already clustered into 10 clusters
- **AND** 20 videos ingested with embeddings
- **WHEN** user runs clustering algorithm
- **THEN** videos SHALL be assigned to existing clusters based on thematic similarity
- **AND** at least 2 clusters SHALL contain mix of videos + photos
- **AND** cluster viewing SHALL show both media types

---

### Requirement: Format-Aware Caption Generation

The caption generation system (Milestone 5a) SHALL produce format-appropriate captions for Reels, Carousels, and Static posts.

**Changes:**
- Add `format:` keyword to CaptionGenerations::Generator.generate()
- Update prompt builder with format-specific guidance

**Details:**
- Reel captions: Hook in first line, punchy (60-100 chars), call to action
- Carousel captions: Hint at story, encourage swiping
- Static captions: Thoughtful, longer-form acceptable

#### Scenario: Generate Reel-Specific Caption

- **GIVEN** video asset from "Urban Exploration" cluster
- **AND** format: reel
- **AND** persona: Sarah (witty, curious)
- **WHEN** CaptionGenerations::Generator.generate(photo: video, persona: sarah, format: :reel) is called
- **THEN** caption SHALL include hook (e.g., "Ever wonder what's hiding in plain sight?")
- **AND** SHALL be concise (60-100 characters)
- **AND** metadata SHALL include `{ format: 'reel' }`

---

### Requirement: Format-Aware Hashtag Generation

The hashtag generation system (Milestone 5b) SHALL include format-specific hashtags for Reels.

**Changes:**
- Add `format:` keyword to HashtagGenerations::Generator.generate()
- Add Reel hashtag pool to configuration

**Details:**
- Reel-specific hashtags: #Reels, #ReelsInstagram, #Trending
- Avoid spammy tags: #Viral, #FYP
- Format tags appended to cluster/content-based tags (total: 9-12)

#### Scenario: Generate Reel-Specific Hashtags

- **GIVEN** video asset from "Urban Exploration" cluster
- **AND** format: reel
- **WHEN** HashtagGenerations::Generator.generate(photo: video, cluster: cluster, format: :reel, count: 9) is called
- **THEN** base hashtags SHALL include cluster-appropriate tags (6 tags)
- **AND** Reel-specific tags SHALL include #Reels, #ReelsInstagram (3 tags)
- **AND** total SHALL be 9 hashtags
- **AND** no spammy tags SHALL be included (#Viral, #FYP)

---

### Requirement: Scheduling System Enhancement

The scheduling system SHALL support video posts and differentiate handling for Reels vs static posts.

**Changes:**
- Migration: Add media_asset_id, media_type, post_format, video_metadata to scheduling_posts
- Create PostReelJob with retry logic
- Update scheduling:post_scheduled to check media_type

**Details:**
- Background job: `Scheduling::PostReelJob` handles Reel publishing asynchronously
- Static/carousel posts handled synchronously (existing flow)
- History records capture `post_format` for analytics

#### Scenario: Post Scheduled Reel Asynchronously

- **GIVEN** scheduled post with media_type: video, post_format: reel, status: draft
- **AND** optimal_time_calculated: 5 minutes ago (due)
- **WHEN** rake task `scheduling:post_scheduled` runs
- **THEN** system SHALL detect video post
- **AND** SHALL delegate to Scheduling::PostReelJob.perform_later(post.id)
- **AND** background job SHALL generate public video URL
- **AND** SHALL create Reel container
- **AND** SHALL wait for processing
- **AND** SHALL publish Reel
- **AND** SHALL update post: status: 'posted', posted_at: now, provider_post_id
- **AND** history record SHALL be created with post_format: 'reel'

---

## Integration Examples

### Example 1: End-to-End Reel Posting

```ruby
# Sarah persona with Reels-enabled strategy
persona = Persona.find_by(name: 'sarah')
persona.strategy_config = {
  format: {
    prefer_reels: true,
    reel_posts_per_week: 1
  }
}

# Automation pipeline (Milestone 5c)
# Nightly: Create tomorrow's posts
result = ContentStrategy::SelectNextPost.call(persona: persona)
# Selects 1 video (Reel) + 3 photos

post = Scheduling::Post.create!(
  persona: persona,
  media_asset: result.media_asset,  # Video
  media_type: :video,
  post_format: :reel,
  caption: result.caption,  # Reel-aware caption
  hashtags: result.hashtags,  # #Reels, #ReelsInstagram
  optimal_time_calculated: tomorrow_9am
)

# Hourly: Publish due posts
Scheduling::PostReelJob.perform_now(post.id)

# Result: Reel on Instagram with correct caption, hashtags
# Performance tracking: reach, non-follower %, engagement
```

### Example 2: Weekly Format Distribution

```ruby
# Sarah's config: 4 posts/week, 1 Reel
week_schedule = []

4.times do |i|
  result = ContentStrategy::SelectNextPost.call(persona: sarah)
  week_schedule << result.post_format
end

week_schedule
# => ['reel', 'carousel', 'static', 'carousel']
# Format mix: 25% Reels, 50% Carousels, 25% Static ✅
```
