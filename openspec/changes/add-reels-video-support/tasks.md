# Tasks: Add Reels & Video Support to Instagram Posting

**Change ID**: `add-reels-video-support`  
**Status**: Not Started  
**Created**: 2024-11-04

---

## Progress

**Current Status:** Planning / Research Phase
**Overall Completion:** 0%

**Note:** This milestone adds video/Reels support to boost non-follower reach from 16% to 30%+. Currently only static images are supported. Reels provide 2.25x reach multiplier per Instagram research.

**Key Question:** What are Instagram Reels? 
- Short-form vertical videos (9:16 aspect ratio, 3-90 seconds)
- Heavily favored by Instagram algorithm for discovery
- Instagram recommends: "1 Reel + 10 posts each week" for growth

---

## Phase 1: Research & Requirements (Week 1, Days 1-2)

### Instagram Reels Research
- [ ] Understand Reels format requirements (aspect ratio, duration, codecs)
- [ ] Review Instagram Graph API Reels endpoints
- [ ] Study Reels best practices (hooks, timing, trending audio)
- [ ] Analyze video generation APIs (if generating from photos)
- [ ] Document findings

### Video Asset Requirements
- [ ] Define supported video formats (MP4, MOV)
- [ ] Define technical requirements (resolution, bitrate, codecs)
- [ ] Define metadata requirements (duration, aspect ratio, audio)
- [ ] Research video thumbnail generation
- [ ] Document requirements

### Video Source Strategy
- [ ] Option A: User-provided videos (manual upload) - **START HERE**
- [ ] Option B: Generate videos from photos (slideshow/motion)
- [ ] Option C: Stock video libraries (Pexels, Unsplash)
- [ ] Option D: AI-generated videos (FLUX Video, Runway ML) - **FUTURE**
- [ ] Make decision and document rationale

---

## Phase 2: Data Model & Storage (Week 1, Days 2-3)

### Video Model
- [ ] Create `videos` table migration
  - [ ] id, filename, file_path, content_type
  - [ ] duration_seconds, width, height, aspect_ratio
  - [ ] codec_name, bitrate, framerate
  - [ ] uploaded_at, processed_at
  - [ ] persona_id (optional)
- [ ] Create Video model (`app/models/video.rb`)
- [ ] Add ActiveStorage attachment for video file
- [ ] Add validations (file type, size, duration)
- [ ] Write specs for Video model

### Video Analysis Model
- [ ] Create `video_analyses` table migration
  - [ ] video_id, thumbnail_url
  - [ ] embedding (vector for clustering)
  - [ ] detected_objects (jsonb)
  - [ ] quality_score, aesthetic_score
  - [ ] analyzed_at
- [ ] Create VideoAnalysis model
- [ ] Add association to Video
- [ ] Write specs for VideoAnalysis model

### Polymorphic Media Asset
- [ ] Update `scheduling_posts` to support polymorphic media
  - [ ] Add `media_asset_id` and `media_asset_type` columns
  - [ ] Add `media_type` enum (:photo, :video)
  - [ ] Add `post_format` enum (:static, :carousel, :reel)
- [ ] Update Scheduling::Post model with polymorphic association
- [ ] Migrate existing posts to use polymorphic association
- [ ] Write specs for polymorphic media

---

## Phase 3: Video Ingestion & Processing (Week 2, Days 1-3)

### Video Upload Interface
- [ ] Create admin video upload form
- [ ] Support bulk video upload (multiple files)
- [ ] Add progress indicator for uploads
- [ ] Create VideoUploads controller
- [ ] Write specs for upload controller

### Video Processing Service
- [ ] Create `app/services/videos/processor.rb`
- [ ] Extract video metadata (duration, resolution, codec) using FFmpeg
- [ ] Validate Reels requirements (3-90s, portrait/square)
- [ ] Generate thumbnail image (first frame or mid-point)
- [ ] Store processed metadata
- [ ] Write specs for video processing

### Video Embedding & Clustering
- [ ] Create `app/services/videos/embed.rb`
- [ ] Extract key frame for embedding generation
- [ ] Use existing CLIP embedding (same as photos)
- [ ] Store video embedding in video_analyses
- [ ] Integrate videos into existing clustering system
- [ ] Write specs for video embedding

### Background Jobs
- [ ] Create `ProcessVideoJob` for async video processing
- [ ] Create `EmbedVideoJob` for async embedding generation
- [ ] Queue jobs after video upload
- [ ] Handle job failures gracefully
- [ ] Write specs for video jobs

---

## Phase 4: Instagram Reels API Integration (Week 2, Days 3-5)

### Instagram Graph API Client Enhancement
- [ ] Research Instagram Reels publishing endpoints
- [ ] Add `create_reel_container` method to Instagram::Client
- [ ] Implement video upload to Instagram server
- [ ] Implement container status checking (FINISHED, ERROR, IN_PROGRESS)
- [ ] Add polling logic for processing completion
- [ ] Add timeout handling (max 5 minutes)
- [ ] Write specs for Reels API methods

### Reel Publishing Service
- [ ] Create `app/services/instagram/publish_reel.rb`
- [ ] Upload video to Instagram via API
- [ ] Poll for processing status
- [ ] Publish once processing complete
- [ ] Return Instagram post ID and URL
- [ ] Handle API errors gracefully
- [ ] Write specs for Reel publishing

### Background Job
- [ ] Create `PostReelJob` for async Reel posting
- [ ] Implement retry logic (3 attempts)
- [ ] Handle timeout scenarios
- [ ] Update Scheduling::Post status
- [ ] Write specs for PostReelJob

---

## Phase 5: Content Strategy Integration (Week 3, Days 1-2)

### Format Selection Logic
- [ ] Update `BaseStrategy` to support video selection
- [ ] Add `reel_posts_per_week` config (default: 1)
- [ ] Implement format variety logic (no 2 Reels in a row)
- [ ] Balance Reels, Carousels, and Static posts
- [ ] Write specs for format selection

### Video Selection
- [ ] Extend `SelectNextPost` to query videos
- [ ] Select video from cluster (same logic as photos)
- [ ] Prefer videos not posted in last 30 days
- [ ] Mark selected video in history
- [ ] Write specs for video selection

### Reels-Aware Caption Generation
- [ ] Enhance caption generation for Reels format
- [ ] Use attention-grabbing hooks for Reels
- [ ] Keep captions punchy (50-100 chars for Reels)
- [ ] Add Reel-specific emoji usage
- [ ] Write specs for Reel caption generation

### Reels-Aware Hashtag Generation
- [ ] Add Reel-specific hashtags (#Reels, #ReelsInstagram)
- [ ] Include trending audio hashtags (if available)
- [ ] Prioritize discovery-focused hashtags
- [ ] Write specs for Reel hashtag generation

---

## Phase 6: Scheduling & Publishing (Week 3, Days 2-3)

### Scheduling System Update
- [ ] Update `scheduling:post_scheduled` task to handle videos
- [ ] Detect `media_type: :video` posts
- [ ] Delegate to `PostReelJob` for video posts
- [ ] Delegate to existing logic for photo posts
- [ ] Write specs for scheduling task updates

### Posting Logic
- [ ] Update `Instagram::PostScheduledContent` command
- [ ] Branch on `post_format`: :reel vs :static/:carousel
- [ ] Call appropriate posting service
- [ ] Track posting status and Instagram URL
- [ ] Write specs for posting command

### History Tracking
- [ ] Update `ContentStrategy::HistoryRecord` to track post_format
- [ ] Capture Reel vs Static post in history
- [ ] Use history for format variety logic
- [ ] Write specs for history tracking

---

## Phase 7: Testing & Validation (Week 3, Days 4-5)

### Unit Tests
- [ ] Test video metadata extraction
- [ ] Test video validation (duration, aspect ratio)
- [ ] Test thumbnail generation
- [ ] Test Reels API client methods
- [ ] Test format selection logic

### Integration Tests
- [ ] Test video upload → processing → embedding → clustering
- [ ] Test content strategy selects video
- [ ] Test Reel publishing end-to-end
- [ ] Test caption/hashtag generation for Reels
- [ ] Test scheduling and posting Reels

### Manual Testing
- [ ] Upload 10 test videos (various formats, durations)
- [ ] Verify metadata extraction correct
- [ ] Verify clustering works with videos
- [ ] Post test Reel to Instagram (test account)
- [ ] Verify Reel appears correctly on Instagram

### Performance Testing
- [ ] Benchmark video processing time (target: <30s for 30s video)
- [ ] Benchmark Reel publishing time (target: <5 minutes)
- [ ] Test concurrent video uploads
- [ ] Test API rate limits

---

## Phase 8: Monitoring & Rollout (Week 4, Days 1-2)

### Dashboard Updates
- [ ] Add video library stats to dashboard
- [ ] Show upcoming Reels in schedule
- [ ] Display Reel vs Photo post breakdown
- [ ] Add video processing status indicator
- [ ] Add Reel performance metrics (reach, engagement)

### Metrics Tracking
- [ ] Track Reel reach vs Static post reach
- [ ] Track non-follower % for Reels vs Statics
- [ ] Compare engagement rates
- [ ] Validate 2.25x reach multiplier hypothesis
- [ ] Generate weekly performance reports

### Gradual Rollout
- [ ] Start with 1 Reel per week for Sarah
- [ ] Monitor performance for 2 weeks
- [ ] Increase to 2 Reels per week if successful
- [ ] Roll out to other personas

---

## Phase 9: Documentation & Training (Week 4, Days 3-5)

### User Documentation
- [ ] Write video upload guide
- [ ] Document Reels best practices
- [ ] Create Reels optimization checklist
- [ ] Add FAQ for common video issues
- [ ] Update README with Reels features

### Admin Guide
- [ ] Document video processing pipeline
- [ ] Explain format selection logic
- [ ] Troubleshoot video upload failures
- [ ] Explain Reel API error handling

### Developer Documentation
- [ ] Document video data model
- [ ] Document Reels API integration
- [ ] Document format selection algorithm
- [ ] Add code comments for complex logic

---

## Acceptance Criteria Validation

### AC1: Video Ingestion
- [ ] Verify 50+ MP4 videos successfully uploaded
- [ ] Verify metadata extracted (duration, aspect ratio, codec)
- [ ] Verify thumbnails generated
- [ ] Verify videos validated against Reels requirements

### AC2: Instagram Reels API
- [ ] Verify Reel media container created
- [ ] Verify processing status checked correctly
- [ ] Verify Reel published successfully
- [ ] Verify error handling works (failed uploads, timeouts)

### AC3: Content Strategy
- [ ] Verify ContentStrategy selects videos from clusters
- [ ] Verify format selection respects `reel_posts_per_week` quota
- [ ] Verify format variety maintained (no 2 Reels in a row)
- [ ] Verify Reels mixed with Carousels and Statics

### AC4: End-to-End Posting
- [ ] Verify scheduled post with `media_type: :video` created
- [ ] Verify scheduling task detects video and delegates to PostReelJob
- [ ] Verify background job uploads video, waits, publishes
- [ ] Verify post status updated to 'posted' with Instagram URL
- [ ] Verify HistoryRecord captures Reel format

### AC5: Performance Impact (30 Days)
- [ ] Verify Sarah posts 1 Reel per week
- [ ] Measure non-follower reach increase (target: 16% → 30%+)
- [ ] Measure Reels reach vs Static posts (target: 2x+)
- [ ] Measure total weekly reach increase (target: +25%+)

### AC6: Format-Aware Generation
- [ ] Verify captions are Reel-appropriate (hooks, punchy)
- [ ] Verify hashtags include Reel-specific tags
- [ ] Verify caption + hashtag fits Instagram limits

---

## Open Questions

### Q1: How do we source videos initially?
- [ ] **Decision**: Start with user-provided videos (manual upload)
- [ ] Future: Explore AI video generation (Milestone 6+)

### Q2: Should we support Stories?
- [ ] **Decision**: No. Stories are separate milestone (5.6)
- Stories have different requirements (ephemeral, 24h, different API)

### Q3: How handle videos without audio?
- [ ] **Decision**: Allow silent Reels, optionally add royalty-free music (future)

### Q4: Carousel + video support?
- [ ] **Decision**: Phase 2 enhancement (mixed media carousels)

### Q5: Video generation from photos?
- [ ] **Decision**: Future milestone (6+) - Ken Burns, parallax, AI motion

---

## Risk Mitigation

### Risk: Video processing slow (>30s)
- Use FFmpeg with optimized settings
- Process videos in background jobs
- Add progress indicators for user

### Risk: Reels API processing timeout
- Implement robust polling with backoff
- Max 5-minute timeout
- Notify admin if timeout occurs

### Risk: Video library exhaustion
- Health check warns if <20 videos available
- Alert admin to upload more videos
- Temporarily reduce Reel frequency

### Risk: Aspect ratio mismatch
- Validate aspect ratio during upload
- Reject non-portrait/square videos
- Provide clear error messages

---

## Dependencies

**Required (Complete):**
- ✅ Instagram::Client (Milestone 3)
- ✅ ContentStrategy::SelectNextPost (Milestone 4c)
- ✅ Clustering system (Milestone 4a)
- ✅ Scheduling::Post model (Milestone 3)

**Required (In Progress):**
- ⏳ Caption Generation (Milestone 5a) - For Reel-aware captions
- ⏳ Hashtag Generation (Milestone 5b) - For Reel-specific hashtags

**External:**
- FFmpeg (video processing)
- Instagram Graph API (Reels endpoints)

---

## Related Changes

- `add-content-strategy-engine` (Milestone 4c) - Provides format selection
- `add-persona-caption-generation` (Milestone 5a) - Provides Reel captions
- `add-automated-hashtag-generation` (Milestone 5b) - Provides Reel hashtags
- `add-full-automation-integration` (Milestone 5c) - Will integrate Reels automation

---

**Last Updated**: 2024-11-04  
**Est. Completion**: 4-5 weeks from start  
**Assignee**: TBD  
**Priority**: High - Critical for improving Sarah's 16% non-follower reach
