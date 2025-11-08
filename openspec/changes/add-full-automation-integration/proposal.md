# Implementation Proposal: Full Automation & Integration

## Why

**Existing System:** fluffy-train has successfully implemented all the building blocks for fully autonomous Instagram posting:
- ✅ **Milestone 2**: Photo analysis (quality, aesthetics, content detection)
- ✅ **Milestone 3**: Automated posting engine with basic scheduling
- ✅ **Milestone 4a-c**: Clustering, curation, and content strategy engine
- ✅ **Milestone 5a**: Persona-driven caption generation
- ✅ **Milestone 5b**: Intelligent hashtag generation (in progress)

**Current Status (Analyzed from codebase):**
- ✅ Content Strategy Engine: `ContentStrategy::SelectNextPost` (Milestone 4c)
- ✅ Caption Generation: `Photos::Analyse::Caption` with persona enhancement (Milestone 5a)
- ✅ Hashtag Generation: `HashtagEngine` with intelligent enhancement (Milestone 5b)
- ✅ Instagram API Integration: `Instagram::Client` and posting commands
- ✅ Scheduling System: `Scheduling::Post` model with status tracking
- ✅ Rake Tasks: 
  - `scheduling:create_scheduled_post` - Create scheduled posts
  - `scheduling:post_scheduled` - Post due scheduled posts
  - `scheduling:post_with_strategy` - Immediate posting with content strategy
- ✅ **All components work individually but lack continuous automation**

**What Milestone 5c Does:**
Milestone 5c is NOT about building new features - it's about **integrating and automating** what already exists:

1. **Pipeline Integration**: Connect caption generation (5a) + hashtag generation (5b) into scheduling
2. **Continuous Automation**: Add cron/scheduler to run autonomously for days/weeks
3. **End-to-End Testing**: Validate the complete pipeline works reliably
4. **Monitoring & Logging**: Ensure visibility into the autonomous operation
5. **Error Handling**: Robust failure recovery for unattended operation

**Current State:**
```
Manual Process Today:
  1. User runs: bundle exec rails scheduling:create_scheduled_post[sarah]
  2. System creates draft post with caption + hashtags + optimal time
  3. User runs: bundle exec rails scheduling:post_scheduled
  4. System posts to Instagram at scheduled time
  
✅ Works: All pieces exist and function
❌ Missing: Continuous automation (no cron, requires manual trigger)
❌ Missing: Multi-day autonomy (post creation must be manual)
❌ Missing: End-to-end integration testing
```

**Solution:**
Milestone 5c completes the autonomous pipeline by:
1. **Automated Post Creation**: Daily cron job to create tomorrow's scheduled posts
2. **Automated Post Publishing**: Hourly cron job to publish due posts
3. **Integration Testing**: 3-day autonomous test run with no manual intervention
4. **Monitoring Dashboard**: View pipeline status and health
5. **Error Recovery**: Automatic retry and fallback mechanisms

---

## What Changes

This proposal **integrates and automates** existing components. We're not building new generation capabilities - we're making the system run autonomously without manual intervention.

**Existing System (Already Working):**
- `ContentStrategy::SelectNextPost` - Selects photo + cluster + hashtags + time
- `Photos::Analyse::Caption` - Generates captions (Milestone 5a enhancement in progress)
- `HashtagEngine` → `HashtagGenerations::Generator` - Generates hashtags (5b enhancement)
- `Scheduling::Post` - Stores scheduled posts with status
- `Instagram::Client` - Posts to Instagram
- `scheduling:create_scheduled_post` - Creates draft posts
- `scheduling:post_scheduled` - Publishes draft posts at scheduled time

**New Enhancements (Add):**

### 1. Continuous Automation System

**a) Automated Post Creation (Daily)**
- New: `lib/tasks/automation.rake` task `automation:create_tomorrow_posts`
- Runs daily at 11:00 PM (configurable)
- For each active persona:
  - Calculate how many posts needed tomorrow (based on strategy frequency)
  - Call `ContentStrategy::SelectNextPost` for each post
  - Create draft `Scheduling::Post` records with optimal times
  - Generate captions using persona-aware generator (Milestone 5a)
  - Generate hashtags using intelligent generator (Milestone 5b)
- Logs all creation steps to `log/automation.log`

**b) Automated Post Publishing (Hourly)**
- Enhanced: `scheduling:post_scheduled` task (already exists)
- Runs every hour (configurable, e.g., every 15 minutes)
- Finds draft posts where `optimal_time_calculated <= now`
- Posts to Instagram via `Instagram::Client`
- Updates status to 'posted' and records `posted_at`
- Logs all publishing steps

**c) Scheduler Configuration**
- Option 1: **Cron** (Linux/Mac production)
  - Add `config/schedule.rb` for Whenever gem
  - Define cron schedule for creation and publishing tasks
- Option 2: **Solid Queue** (Rails 7.1+ background jobs)
  - Use recurring jobs for automation tasks
  - Better for Heroku/cloud deployments
- Option 3: **Sidekiq-Cron** (if using Sidekiq)
  - Define recurring jobs for automation

### 2. Pipeline Integration Enhancements

**Enhance: ContentStrategy.generate_caption()**
- Currently: Returns `photo.photo_analysis.caption + hashtags`
- Enhanced: Check for `persona.caption_config` (Milestone 5a)
- If configured: Use `CaptionGenerations::Generator.generate()` (persona-aware)
- If not: Fallback to `photo_analysis.caption` (generic)
- Store `caption_metadata` in scheduling_posts

**Enhance: BaseStrategy.select_hashtags()**
- Currently: Returns `HashtagEngine.generate()` (generic)
- Enhanced: Check for `persona.hashtag_strategy` (Milestone 5b)
- If configured: Use `HashtagGenerations::Generator.generate()` (intelligent)
- If not: Fallback to `HashtagEngine.generate()` (basic)
- Store `hashtag_metadata` in scheduling_posts

**Integration Flow:**
```
Nightly (11:00 PM):
  automation:create_tomorrow_posts
    ↓
  For each persona with active strategy:
    ↓
  ContentStrategy::SelectNextPost.call()
    ├── Select photo (cluster + variety + recency)
    ├── Calculate optimal_time (strategy config: 9am-12pm)
    ├── Generate caption (persona-aware if 5a configured)
    ├── Generate hashtags (intelligent if 5b configured)
    └── Return photo, cluster, time, caption, hashtags
    ↓
  Scheduling::Post.create!(status: 'draft', optimal_time_calculated: tomorrow_9am)
    ↓
  Log: "Created scheduled post #{post.id} for #{persona.name} at #{optimal_time}"

Hourly (every hour):
  scheduling:post_scheduled
    ↓
  Find Scheduling::Post.where(status: 'draft', optimal_time_calculated <= now)
    ↓
  For each due post:
    ├── Generate public photo URL
    ├── Post to Instagram (caption + hashtags + photo)
    ├── Update status: 'posted', posted_at: now
    ├── Record in ContentStrategy::HistoryRecord
    └── Log: "Posted #{post.id} successfully, Instagram ID: #{instagram_id}"
```

### 3. Monitoring & Observability

**Add: Automation Health Dashboard**
- New: `app/views/admin/automation_health.html.erb`
- Show:
  - Pipeline status (last run, next run)
  - Scheduled posts (upcoming 7 days)
  - Recent posts (last 7 days with status)
  - Errors and warnings
  - Per-persona stats (posts scheduled, posts published, failures)

**Add: Detailed Automation Logging**
- New: `log/automation.log` (separate from rails log)
- Structured logging with timestamps
- Log levels: INFO, WARN, ERROR
- Include context: persona, photo_id, post_id, strategy_name
- Example:
  ```
  [2024-11-04 23:00:00] INFO [automation:create_tomorrow_posts] Starting post creation for 2024-11-05
  [2024-11-04 23:00:01] INFO [Sarah] Selecting next post with ContentStrategy
  [2024-11-04 23:00:02] INFO [Sarah] Selected photo 1234, cluster: Urban Exploration
  [2024-11-04 23:00:03] INFO [Sarah] Generated caption (persona-aware, 87 chars)
  [2024-11-04 23:00:04] INFO [Sarah] Generated hashtags (intelligent, 9 tags)
  [2024-11-04 23:00:05] INFO [Sarah] Created scheduled post 567 for 2024-11-05 09:00:00 EST
  [2024-11-04 23:00:06] INFO [automation:create_tomorrow_posts] Completed: 1 post(s) created
  
  [2024-11-05 09:00:00] INFO [scheduling:post_scheduled] Found 1 post(s) ready to publish
  [2024-11-05 09:00:01] INFO [Post 567] Generating public URL for photo 1234
  [2024-11-05 09:00:02] INFO [Post 567] Posting to Instagram for persona Sarah
  [2024-11-05 09:00:05] INFO [Post 567] Posted successfully, Instagram ID: 17234567890
  [2024-11-05 09:00:06] INFO [Post 567] Recorded in strategy history
  [2024-11-05 09:00:07] INFO [scheduling:post_scheduled] Completed: 1 post(s) published
  ```

**Add: Slack/Email Notifications (Optional)**
- New: `Automation::Notifier` service
- Send notifications for:
  - Daily summary (posts created for tomorrow)
  - Posting success (with Instagram URL)
  - Posting failures (with error details)
  - Pipeline health warnings (no posts scheduled, repeated failures)
- Integration: Slack webhook or ActionMailer

### 4. Error Handling & Recovery

**Add: Retry Logic**
- New: `Automation::RetryStrategy` concern
- Retry failed operations with exponential backoff
- Max retries: 3 attempts
- Retry scenarios:
  - Instagram API rate limit (wait and retry)
  - Network timeout (immediate retry)
  - Photo URL generation failure (retry after 1 minute)

**Add: Fallback Mechanisms**
- If ContentStrategy fails: Fallback to CuratorsChoice (highest aesthetic score)
- If caption generation fails: Use generic caption from photo_analysis
- If hashtag generation fails: Use basic HashtagEngine
- If Instagram API fails: Mark post as 'failed', log error, notify admin

**Add: Circuit Breaker**
- New: `Automation::CircuitBreaker` service
- If Instagram API fails 5 times in a row: Stop posting for 1 hour (circuit open)
- After 1 hour: Try one test post (half-open)
- If succeeds: Resume normal operation (circuit closed)
- If fails: Stay open for another hour

**Add: Health Checks**
- New: `automation:health_check` rake task
- Run before each automation cycle
- Check:
  - Instagram API credentials valid
  - Database connectivity
  - Photo storage accessible
  - At least N photos available for next post
- If health check fails: Skip cycle, send alert

### 5. End-to-End Integration Testing

**Add: 3-Day Autonomy Test Suite**
- New: `spec/integration/automation/three_day_autonomy_spec.rb`
- Simulate 3 days of autonomous operation
- Test flow:
  1. Setup: Create persona with strategy config
  2. Day 1: Run `automation:create_tomorrow_posts`, verify 4 draft posts created
  3. Day 1: Advance time, run `scheduling:post_scheduled`, verify posts published
  4. Day 2: Run automation again, verify new posts created
  5. Day 3: Run automation again, verify pipeline still working
  6. Assert: 12 total posts created and published over 3 days
  7. Assert: All posts have captions, hashtags, correct timing
  8. Assert: No errors in automation log

**Add: End-to-End Smoke Test**
- New: `spec/integration/automation/end_to_end_smoke_spec.rb`
- Test complete pipeline with real components (no mocking)
- Flow:
  1. Create persona with full config (caption + hashtag strategies)
  2. Trigger `automation:create_tomorrow_posts`
  3. Verify draft post created with persona-aware caption + intelligent hashtags
  4. Mock Instagram API (don't actually post)
  5. Trigger `scheduling:post_scheduled`
  6. Verify post marked as 'posted', status updated, history recorded

---

## Impact

**Affected Specs:**
- MODIFIED: `scheduling` (add continuous automation)
- MODIFIED: `content-strategy` (enhance caption/hashtag integration)
- ADDED: `automation` (new continuous automation orchestration)

**Affected Code:**
- New: `lib/tasks/automation.rake` (daily post creation task)
- Enhance: `packs/scheduling/lib/tasks/scheduled_posting.rake` (already exists, minor enhancements)
- New: `config/schedule.rb` (Whenever gem cron schedule)
- New: `app/services/automation/` (orchestration services)
  - `Automation::CreateTomorrowPosts` (daily post creation)
  - `Automation::HealthCheck` (pre-flight checks)
  - `Automation::Notifier` (Slack/email alerts)
  - `Automation::RetryStrategy` (exponential backoff)
  - `Automation::CircuitBreaker` (failure protection)
- New: `app/controllers/admin/automation_health_controller.rb` (dashboard)
- New: `app/views/admin/automation_health.html.erb` (health UI)
- New: `spec/integration/automation/` (3-day autonomy tests)

**Benefits:**
- **True Autonomy**: System runs for days/weeks without manual intervention
- **Reliability**: Robust error handling and recovery mechanisms
- **Observability**: Detailed logging and monitoring dashboard
- **Integration Complete**: Captions (5a) + Hashtags (5b) fully integrated
- **Production-Ready**: Cron scheduling for unattended operation
- **Testable**: Comprehensive end-to-end integration tests

**Risks:**
- Cron misconfiguration could cause missed posts (mitigation: health dashboard alerts)
- Instagram API changes could break posting (mitigation: circuit breaker + notifications)
- Photo library exhaustion (mitigation: health check warns if < 50 photos available)
- Over-posting if frequency misconfigured (mitigation: strategy frequency limits)

---

## Architecture Overview

### Current System (Milestone 4c + 5a + 5b)

```
Components Exist (Manual Trigger):
  
  1. Photo Selection:
     ContentStrategy::SelectNextPost.call(persona: sarah)
       └── Returns: photo, cluster, optimal_time, hashtags

  2. Caption Generation:
     photo.photo_analysis.caption (generic)
     OR CaptionGenerations::Generator (persona-aware, Milestone 5a)

  3. Hashtag Generation:
     HashtagEngine.generate() (basic)
     OR HashtagGenerations::Generator (intelligent, Milestone 5b)

  4. Post Creation:
     Scheduling::Post.create!(
       photo: photo,
       caption: caption,
       hashtags: hashtags,
       optimal_time_calculated: time,
       status: 'draft'
     )

  5. Post Publishing:
     Find draft posts where optimal_time <= now
     Instagram::Client.create_media_container()
     Instagram::Client.publish_media_container()
     Update status: 'posted'

❌ Problem: All steps require manual trigger
❌ Problem: No continuous automation for multi-day operation
```

### Enhanced System (Milestone 5c)

```
Continuous Automation (Unattended Operation):

╔══════════════════════════════════════════════════════════════════╗
║                     NIGHTLY AUTOMATION                           ║
║                   (11:00 PM Daily Cron)                          ║
╚══════════════════════════════════════════════════════════════════╝
  automation:create_tomorrow_posts
       ↓
  [Health Check]
  ├── Instagram API credentials OK?
  ├── Database accessible?
  ├── Photos available (>50)?
  └── If all pass: Continue, else: Alert & skip
       ↓
  [For Each Active Persona]
       ↓
  Calculate posts needed tomorrow
  (based on strategy.posting_frequency)
       ↓
  [For Each Post Needed]
       ↓
  ContentStrategy::SelectNextPost.call()
  ├── Select photo (cluster strategy)
  ├── Calculate optimal_time (9am-12pm window)
  ├── Generate caption
  │   └── If persona.caption_config? Use CaptionGenerations::Generator
  │       Else: Use photo_analysis.caption
  ├── Generate hashtags
  │   └── If persona.hashtag_strategy? Use HashtagGenerations::Generator
  │       Else: Use HashtagEngine
  └── Return complete post data
       ↓
  Scheduling::Post.create!(
    status: 'draft',
    optimal_time_calculated: tomorrow_9am,
    caption: caption (persona-aware),
    hashtags: hashtags (intelligent),
    caption_metadata: {...},
    hashtag_metadata: {...}
  )
       ↓
  Log: "Created post #{post.id} for #{persona.name} at #{optimal_time}"
       ↓
  [Notification: Daily Summary]
  "✅ Created 4 posts for tomorrow (Sarah)"

╔══════════════════════════════════════════════════════════════════╗
║                    HOURLY AUTOMATION                             ║
║                 (Every Hour, e.g., :00 Cron)                     ║
╚══════════════════════════════════════════════════════════════════╝
  scheduling:post_scheduled
       ↓
  Find Scheduling::Post.where(
    status: 'draft',
    optimal_time_calculated <= now
  )
       ↓
  If posts.empty?
    Log: "No posts due at this time"
    Show next scheduled post time
    Exit
       ↓
  [For Each Due Post]
       ↓
  [Try with Retry Logic]
  ├── Generate public photo URL
  ├── Post to Instagram
  │   └── Instagram::Client.create_media_container(photo_url, caption)
  │   └── Instagram::Client.publish_media_container(container_id)
  ├── Update post status: 'posted', posted_at: now
  ├── Record in ContentStrategy::HistoryRecord
  └── Log: "Posted #{post.id}, Instagram ID: #{instagram_id}"
       ↓
  [If Failure]
  ├── Retry up to 3 times (exponential backoff)
  ├── If still fails: Mark as 'failed', log error
  ├── If 5 failures in a row: Open circuit breaker (stop posting 1 hour)
  └── Send notification: "❌ Posting failed for post #{post.id}"
       ↓
  [Notification: Post Success]
  "✅ Posted to Sarah's Instagram: [Instagram URL]"

╔══════════════════════════════════════════════════════════════════╗
║                    MONITORING DASHBOARD                          ║
║               (Admin UI: /admin/automation_health)               ║
╚══════════════════════════════════════════════════════════════════╝
  Display:
  ├── Pipeline Status
  │   ├── Last run: 2024-11-04 23:00:00
  │   ├── Next run: 2024-11-05 23:00:00
  │   └── Status: ✅ Healthy
  ├── Upcoming Posts (Next 7 Days)
  │   ├── 2024-11-05 09:00 - Sarah - Urban Exploration
  │   ├── 2024-11-05 10:30 - Sarah - Beach Lifestyle
  │   └── ... (12 total scheduled)
  ├── Recent Posts (Last 7 Days)
  │   ├── 2024-11-04 09:15 - Sarah - Posted ✅
  │   ├── 2024-11-03 10:00 - Sarah - Posted ✅
  │   └── ... (8 total posted)
  ├── Errors & Warnings
  │   └── None (circuit closed, API healthy)
  └── Per-Persona Stats
      └── Sarah: 8 posted, 12 scheduled, 0 failed
```

---

## Key Design Decisions

### 1. Scheduler Choice

**Decision**: Use **Whenever gem** for cron-based scheduling (production), Solid Queue as alternative for cloud.

**Rationale**:
- Cron: Industry standard, reliable, works on Linux/Mac servers
- Whenever: Ruby DSL for defining cron schedules (maintainable)
- Solid Queue: Rails 7.1+ native, better for Heroku/cloud (no cron)
- Start with Whenever (simpler), provide Solid Queue alternative

**Implementation**:
```ruby
# config/schedule.rb (Whenever gem)
every 1.day, at: '11:00 pm' do
  rake "automation:create_tomorrow_posts"
end

every 1.hour do
  rake "scheduling:post_scheduled"
end

# Or with Solid Queue:
# config/initializers/solid_queue.rb
SolidQueue.recurring do
  on "automation:create_tomorrow_posts", every: 1.day, at: "23:00"
  on "scheduling:post_scheduled", every: 1.hour
end
```

### 2. Post Creation Timing

**Decision**: Create tomorrow's posts at **11:00 PM** (one day ahead).

**Rationale**:
- Gives buffer time for review if needed
- Avoids rush during posting window (9am-12pm)
- Allows troubleshooting overnight
- Consistent with "plan ahead" content strategy

**Alternative Considered**: Create posts 1 hour before posting
- Pros: More responsive to last-minute changes
- Cons: No buffer, harder to debug, risky during posting window

### 3. Posting Frequency

**Decision**: Check for due posts **every hour** (configurable).

**Rationale**:
- Balance between responsiveness and API load
- Hourly is sufficient for Instagram (not time-critical like Twitter)
- Reduces risk of rate limiting
- Can be increased to every 15 minutes if needed

**Future Enhancement**: Smart scheduling based on optimal_time
- E.g., only check at :00, :15, :30, :45 during posting windows (9am-12pm)
- Skip overnight checks (no posts scheduled 1am-6am)

### 4. Integration Point for Captions and Hashtags

**Decision**: Integrate at `ContentStrategy::SelectNextPost` level, not in rake task.

**Rationale**:
- DRY: Single integration point, works for both automated and manual posting
- Testable: Can test caption/hashtag integration without running cron
- Flexible: Easy to add new strategies without changing automation

**Implementation**:
```ruby
# In ContentStrategy.generate_caption()
def generate_caption(photo, hashtags)
  if persona.caption_config.present?
    # NEW: Persona-aware (Milestone 5a)
    result = CaptionGenerations::Generator.generate(
      photo: photo, persona: persona, cluster: cluster
    )
    caption = result.text
    metadata = result.metadata
  else
    # EXISTING: Generic fallback
    caption = photo.photo_analysis&.caption || ""
    metadata = { method: 'photo_analysis' }
  end
  
  full_caption = "#{caption}\n\n#{hashtags.join(' ')}"
  { text: full_caption, metadata: metadata }
end

# In BaseStrategy.select_hashtags()
def select_hashtags(photo:, cluster:)
  if context.persona.hashtag_strategy.present?
    # NEW: Intelligent (Milestone 5b)
    result = HashtagGenerations::Generator.generate(
      photo: photo, persona: context.persona, cluster: cluster, count: 9
    )
    return result.hashtags
  end
  
  # EXISTING: Basic fallback
  HashtagEngine.generate(photo: photo, cluster: cluster, count: 9)
end
```

### 5. Error Handling Strategy

**Decision**: Three-tier error handling (Retry → Circuit Breaker → Manual Intervention).

**Rationale**:
- Tier 1 (Retry): Handle transient failures (network, rate limits)
- Tier 2 (Circuit Breaker): Prevent cascading failures (API down)
- Tier 3 (Manual): Alert admin for persistent issues

**Circuit Breaker States**:
- **Closed** (Normal): Posting works, all requests allowed
- **Open** (Failure): 5+ consecutive failures, block requests for 1 hour
- **Half-Open** (Testing): After 1 hour, try one test post
  - Success → Close circuit
  - Failure → Open for another hour

### 6. Observability Design

**Decision**: Structured logging to separate `log/automation.log` + Admin dashboard.

**Rationale**:
- Separate log: Easier to monitor automation without Rails noise
- Structured format: Machine-readable for log aggregation (e.g., Splunk, ELK)
- Dashboard: Non-technical users can monitor pipeline health
- Actionable: Clear next steps when errors occur

**Log Format**:
```
[timestamp] LEVEL [component] message (context)
[2024-11-04 23:00:05] INFO [Sarah] Created scheduled post 567 for 2024-11-05 09:00:00 EST
[2024-11-05 09:00:05] ERROR [Post 567] Instagram posting failed: Rate limit exceeded (retry in 60s)
```

---

## Implementation Plan

### Phase 1: Automation Infrastructure (Days 1-3)

**1.1 Scheduler Setup**
- Install Whenever gem
- Create `config/schedule.rb` with cron definitions
- Add `automation:create_tomorrow_posts` rake task
- Configure logging to `log/automation.log`
- Test: Run manually, verify cron schedule generated

**1.2 Nightly Post Creation Task**
- Implement `lib/tasks/automation.rake`
- Task: `automation:create_tomorrow_posts`
- Logic:
  - Get all personas with active strategies
  - Calculate posts needed per persona (based on frequency)
  - Call `ContentStrategy::SelectNextPost` for each
  - Create draft `Scheduling::Post` records
- Test: Run for Sarah, verify 4 draft posts created with tomorrow's times

**1.3 Enhance Hourly Publishing Task**
- Review existing `scheduling:post_scheduled` (already works!)
- Add structured logging
- Add retry logic (3 attempts with exponential backoff)
- Test: Create draft post with optimal_time = now, verify publishes

### Phase 2: Integration with Milestones 5a & 5b (Days 4-5)

**2.1 Caption Generation Integration**
- Modify `ContentStrategy.generate_caption()` method
- Add check: `if persona.caption_config.present?`
- If yes: Call `CaptionGenerations::Generator.generate()` (Milestone 5a)
- If no: Fallback to `photo_analysis.caption`
- Store `caption_metadata` in post
- Test: Create post with Sarah (has caption_config), verify persona-aware caption

**2.2 Hashtag Generation Integration**
- Modify `BaseStrategy.select_hashtags()` method
- Add check: `if persona.hashtag_strategy.present?`
- If yes: Call `HashtagGenerations::Generator.generate()` (Milestone 5b)
- If no: Fallback to `HashtagEngine.generate()`
- Store `hashtag_metadata` in post
- Test: Create post with Sarah (has hashtag_strategy), verify intelligent hashtags

**2.3 End-to-End Integration Test**
- Create `spec/integration/automation/pipeline_integration_spec.rb`
- Test flow: ContentStrategy → Caption (5a) → Hashtags (5b) → Draft Post
- Assert: Caption is persona-aware, hashtags are intelligent
- Assert: Metadata stored correctly

### Phase 3: Error Handling & Recovery (Days 6-7)

**3.1 Retry Logic**
- Create `Automation::RetryStrategy` concern
- Implement exponential backoff (1s, 2s, 4s waits)
- Apply to Instagram API calls
- Test: Mock API failure, verify retries

**3.2 Circuit Breaker**
- Create `Automation::CircuitBreaker` service
- Track consecutive failures (in-memory or Redis)
- States: Closed, Open (1 hour timeout), Half-Open (test)
- Test: Simulate 5 failures, verify circuit opens

**3.3 Health Checks**
- Create `automation:health_check` rake task
- Check: Instagram API credentials, database, photo availability
- Run before each automation cycle
- Test: Mock API credential failure, verify health check fails

**3.4 Fallback Mechanisms**
- If ContentStrategy fails: Fallback to CuratorsChoice (highest aesthetic)
- If caption generation fails: Use photo_analysis.caption
- If hashtag generation fails: Use basic HashtagEngine
- Test: Mock ContentStrategy failure, verify fallback works

### Phase 4: Monitoring & Observability (Days 8-9)

**4.1 Automation Dashboard**
- Create `app/controllers/admin/automation_health_controller.rb`
- Create `app/views/admin/automation_health.html.erb`
- Display:
  - Pipeline status (last run, next run)
  - Upcoming posts (7 days)
  - Recent posts (7 days with status)
  - Errors and warnings
  - Per-persona stats
- Test: Access /admin/automation_health, verify data displayed

**4.2 Structured Logging**
- Enhance automation tasks with detailed logging
- Format: `[timestamp] LEVEL [component] message (context)`
- Write to `log/automation.log` (separate from Rails log)
- Test: Run automation, verify logs are structured and readable

**4.3 Notifications (Optional)**
- Create `Automation::Notifier` service
- Slack integration: Webhook for alerts
- Notifications:
  - Daily summary (posts created)
  - Posting success (with Instagram URL)
  - Posting failure (with error details)
- Test: Trigger notification, verify Slack message received

### Phase 5: End-to-End Testing (Days 10-12)

**5.1 3-Day Autonomy Test**
- Create `spec/integration/automation/three_day_autonomy_spec.rb`
- Simulate 3 days of autonomous operation:
  - Day 1: Run nightly creation → hourly publishing
  - Day 2: Run nightly creation → hourly publishing
  - Day 3: Run nightly creation → hourly publishing
- Assert: 12 posts created and published over 3 days
- Assert: All posts have correct captions, hashtags, timing
- Assert: No errors in automation.log

**5.2 Failure Recovery Test**
- Create `spec/integration/automation/failure_recovery_spec.rb`
- Test scenarios:
  - Instagram API rate limit → Retry succeeds
  - 5 consecutive failures → Circuit breaker opens
  - Photo URL generation failure → Fallback to re-upload
  - ContentStrategy failure → Fallback to CuratorsChoice
- Assert: System recovers gracefully, posts eventually published

**5.3 Integration Smoke Test**
- Create `spec/integration/automation/smoke_test_spec.rb`
- Full pipeline with real components (no mocking):
  - Setup: Sarah with caption_config + hashtag_strategy
  - Run: `automation:create_tomorrow_posts`
  - Assert: Draft post created with persona-aware caption + intelligent hashtags
  - Mock: Instagram API (don't actually post to production)
  - Run: `scheduling:post_scheduled`
  - Assert: Post status updated to 'posted'

### Phase 6: Production Deployment & Testing (Days 13-14)

**6.1 Production Setup**
- Deploy to staging environment
- Configure cron with Whenever: `whenever --update-crontab`
- Verify cron jobs scheduled: `crontab -l`
- Monitor first automated cycle (nightly + hourly)

**6.2 Live 3-Day Test**
- Enable automation for Sarah in production
- Monitor for 3 consecutive days:
  - Day 1: Verify 4 posts created at 11pm, posted at 9am-12pm
  - Day 2: Verify 4 more posts created, posted correctly
  - Day 3: Verify 4 more posts created, posted correctly
- Check:
  - All posts on Instagram with correct captions, hashtags
  - No errors in automation.log
  - Dashboard shows healthy status
  - No manual intervention required

**6.3 Documentation & Handoff**
- Document automation setup (scheduler, tasks, monitoring)
- Create troubleshooting guide (common errors, recovery steps)
- Document monitoring dashboard usage
- Create runbook for on-call (how to disable, restart, debug)

**Total Timeline**: 2 weeks (integration + testing + deployment)

---

## Dependencies

### Existing Infrastructure (Leveraged)
✅ `ContentStrategy::SelectNextPost` - Photo selection (Milestone 4c)
✅ `Photos::Analyse::Caption` - Caption generation (Milestone 2)
✅ `CaptionGenerations::Generator` - Persona-aware captions (Milestone 5a)
✅ `HashtagEngine` - Basic hashtag generation (Milestone 4c)
✅ `HashtagGenerations::Generator` - Intelligent hashtags (Milestone 5b)
✅ `Scheduling::Post` - Post storage and status tracking
✅ `Instagram::Client` - Instagram API integration
✅ `scheduling:post_scheduled` - Existing hourly publishing task
✅ Persona model with strategy config

### New Infrastructure (Building)
- `lib/tasks/automation.rake` - Nightly post creation
- `config/schedule.rb` - Cron schedule (Whenever gem)
- `app/services/automation/` - Automation orchestration
  - `Automation::CreateTomorrowPosts` - Daily post creation service
  - `Automation::HealthCheck` - Pre-flight checks
  - `Automation::RetryStrategy` - Exponential backoff retry
  - `Automation::CircuitBreaker` - Failure protection
  - `Automation::Notifier` - Slack/email alerts
- `app/controllers/admin/automation_health_controller.rb` - Dashboard
- `app/views/admin/automation_health.html.erb` - Health UI
- `spec/integration/automation/` - 3-day autonomy tests

### External Dependencies
- **Whenever gem** - Cron scheduling (Ruby DSL)
- Optional: **Solid Queue** - Alternative for Heroku/cloud
- Optional: **Slack webhook** - For notifications

---

## Success Criteria

### Milestone 5c Acceptance Criteria (from Roadmap):

✅ **Criterion 1**: The application can run fully autonomously for **3 consecutive days**, each day correctly selecting an image based on the active strategy, generating a persona-driven caption with hashtags, and scheduling it via a social media API.

**Implementation**:
- Nightly cron job creates tomorrow's posts (4 per day for Sarah)
- Hourly cron job publishes draft posts at optimal times
- Runs for 3 days with no manual intervention
- Total: 12 posts created and published autonomously

✅ **Criterion 2**: The final post content scheduled on the social media platform correctly contains the selected image, a thematically appropriate caption, and relevant hashtags.

**Implementation**:
- Caption: Generated by `CaptionGenerations::Generator` (persona-aware, Milestone 5a)
- Hashtags: Generated by `HashtagGenerations::Generator` (intelligent, Milestone 5b)
- Image: Selected by `ContentStrategy::SelectNextPost` (cluster strategy)
- Verification: Check Instagram posts, verify caption + hashtags match

✅ **Criterion 3**: The system correctly logs all key steps of the fully automated process, from selection to generation to scheduling.

**Implementation**:
- Structured logging to `log/automation.log`
- Log entries for:
  - Post creation (photo selected, caption generated, hashtags generated)
  - Post scheduling (optimal time calculated, draft created)
  - Post publishing (Instagram API called, status updated)
  - Errors and warnings (failures, retries, circuit breaker state)
- Dashboard displays pipeline status and health

### Additional Success Metrics:

- **Reliability**: 95%+ success rate over 30 days (posted / scheduled)
- **Autonomy**: Zero manual interventions required during 3-day test
- **Observability**: All pipeline stages visible in dashboard and logs
- **Recovery**: System recovers from transient failures (API rate limits)
- **Integration**: Captions and hashtags correctly integrate from 5a + 5b

---

## Testing Strategy

### 1. Unit Tests
- Test individual services: `Automation::CreateTomorrowPosts`, `Automation::HealthCheck`
- Test retry logic: `Automation::RetryStrategy`
- Test circuit breaker: `Automation::CircuitBreaker` (open, closed, half-open)

### 2. Integration Tests
- **Pipeline Integration**: ContentStrategy → Caption → Hashtags → Draft Post
- **End-to-End Flow**: Nightly creation → Hourly publishing → Instagram post
- **Failure Recovery**: API failure → Retry → Circuit breaker → Recovery

### 3. 3-Day Autonomy Test (Acceptance Test)
- **Setup**: Sarah persona with caption_config + hashtag_strategy
- **Day 1**: Run automation, verify 4 posts created and published
- **Day 2**: Run automation, verify 4 more posts created and published
- **Day 3**: Run automation, verify 4 more posts created and published
- **Assert**: 12 total posts on Instagram, no errors, no manual intervention

### 4. Production Smoke Test
- Run automation in production for 1 day
- Manually verify first batch of posts
- Check Instagram for correct captions, hashtags, images
- Review automation.log for any warnings
- Confirm dashboard shows healthy status

---

## Monitoring & Alerts

### Dashboard Metrics (Admin UI)
- **Pipeline Status**: Last run, next run, health status
- **Upcoming Posts**: Next 7 days (persona, photo, time)
- **Recent Posts**: Last 7 days (status, Instagram URL)
- **Error Count**: Failures in last 24 hours
- **Per-Persona Stats**: Posts scheduled, posted, failed

### Alerts (Slack/Email)
- **Daily**: Summary of posts created for tomorrow
- **Success**: Post published to Instagram (with URL)
- **Warning**: Retry occurred (API rate limit)
- **Error**: Posting failed after 3 retries
- **Critical**: Circuit breaker opened (5+ consecutive failures)
- **Health**: Health check failed (credentials invalid, photos exhausted)

### Log Monitoring
- Monitor `log/automation.log` for errors
- Alert on ERROR level messages
- Track posting success rate (INFO: "Posted successfully")
- Detect patterns (repeated retries, circuit breaker opens)

---

## Risk Mitigation

### Risk: Cron misconfiguration (missed posts)
**Mitigation**:
- Test cron schedule in staging before production
- Dashboard shows next run time (verify it's correct)
- Alert if no posts created in 24 hours

### Risk: Instagram API changes break posting
**Mitigation**:
- Circuit breaker stops posting after 5 failures (prevents spam)
- Notifications alert admin immediately
- Fallback: Manual posting via existing rake task

### Risk: Photo library exhaustion
**Mitigation**:
- Health check warns if < 50 photos available
- Alert admin to upload more photos
- Fallback: Reduce posting frequency temporarily

### Risk: Over-posting (frequency misconfigured)
**Mitigation**:
- Strategy config limits: posting_frequency_min/max
- Dashboard shows upcoming posts (review before deployment)
- Max 5 posts per day per persona (hard limit)

### Risk: Caption/hashtag generation failures
**Mitigation**:
- Graceful fallbacks: photo_analysis.caption, basic HashtagEngine
- System continues posting even if enhancements fail
- Log warnings for manual review

---

## Future Enhancements (Post-MVP)

### Advanced Scheduling
- Adaptive timing based on engagement patterns (Milestone 5d)
- Multi-persona coordination (avoid posting all accounts at once)
- Seasonal adjustments (holiday posting schedules)

### Advanced Error Handling
- Automatic credential refresh (Instagram token expiry)
- Smart retry (detect transient vs permanent failures)
- Self-healing (restart services, clear caches)

### Enhanced Monitoring
- Real-time dashboard (WebSockets, auto-refresh)
- Performance metrics (posting latency, API response time)
- Cost tracking (API calls, storage, compute)

### Content Quality Gates
- Pre-posting review queue (optional human approval)
- A/B testing (test caption/hashtag variants)
- Content diversity checks (avoid posting similar photos back-to-back)

---

**Last Updated**: 2024-11-04  
**Status**: Ready for Review and Implementation  
**Prerequisites**: Milestone 5a (Caption Generation) and 5b (Hashtag Generation) complete
