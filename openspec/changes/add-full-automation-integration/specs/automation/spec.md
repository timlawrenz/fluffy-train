# Automation Orchestration Capability

**Change**: add-full-automation-integration  
**Status**: ADDED

---

## ADDED Requirements

### Requirement: Automated Post Creation

The system SHALL automatically create scheduled posts daily without manual intervention, integrating content strategy, caption generation, and hashtag generation.

#### Scenario: Create tomorrow's posts nightly

- **GIVEN** Sarah's persona with active content strategy
- **AND** strategy posting frequency is 4 posts per week (Wed-Fri + 1 rotating)
- **AND** current day is Tuesday
- **WHEN** the nightly automation task runs at 11:00 PM
- **THEN** 4 draft posts are created for Wednesday
- **AND** each post has a selected photo, cluster, caption, and hashtags
- **AND** each post has optimal_time_calculated within 9am-12pm ET Wednesday
- **AND** all posts have status 'draft'
- **AND** automation log records creation of 4 posts

#### Scenario: Integrate persona-aware caption generation

- **GIVEN** Sarah's persona with caption_config configured (Milestone 5a)
- **WHEN** automated post creation runs
- **THEN** captions are generated using CaptionGenerations::Generator (persona-aware)
- **AND** caption_metadata is stored with method: "persona_aware"
- **AND** captions match Sarah's lifestyle voice and tone

#### Scenario: Integrate intelligent hashtag generation

- **GIVEN** Sarah's persona with hashtag_strategy configured (Milestone 5b)
- **WHEN** automated post creation runs
- **THEN** hashtags are generated using HashtagGenerations::Generator (intelligent)
- **AND** hashtag_metadata is stored with method: "intelligent_generation"
- **AND** hashtags include content-specific, persona-aligned, and optimal mix

#### Scenario: Handle multiple personas

- **GIVEN** 2 personas with active strategies (Sarah: 4 posts/week, Alex: 3 posts/week)
- **AND** both personas have posts needed tomorrow
- **WHEN** nightly automation runs
- **THEN** 4 draft posts are created for Sarah
- **AND** 3 draft posts are created for Alex
- **AND** each persona's posts follow their respective strategies

#### Scenario: Skip persona without active strategy

- **GIVEN** a persona without content strategy configured
- **WHEN** nightly automation runs
- **THEN** no posts are created for that persona
- **AND** automation log records "Skipping {persona.name}: No active strategy"

---

### Requirement: Automated Post Publishing

The system SHALL automatically publish scheduled posts at their optimal times without manual intervention.

#### Scenario: Publish posts at optimal time

- **GIVEN** a draft post with optimal_time_calculated = 9:00 AM today
- **AND** current time is 9:05 AM (within 1-hour window)
- **WHEN** the hourly publishing task runs
- **THEN** the post is published to Instagram
- **AND** post status is updated to 'posted'
- **AND** posted_at timestamp is recorded
- **AND** provider_post_id (Instagram ID) is stored
- **AND** ContentStrategy::HistoryRecord is created

#### Scenario: Skip posts not yet due

- **GIVEN** draft posts with optimal_time_calculated in the future
- **AND** current time is before optimal_time
- **WHEN** hourly publishing task runs
- **THEN** no posts are published
- **AND** automation log shows "No posts scheduled for posting at this time"
- **AND** log shows next scheduled post time

#### Scenario: Publish multiple posts in window

- **GIVEN** 2 draft posts with optimal_time_calculated within the last hour
- **WHEN** hourly publishing task runs
- **THEN** both posts are published to Instagram
- **AND** both posts have status 'posted' and provider_post_id set
- **AND** automation log records 2 successful publishes

---

### Requirement: Continuous Scheduling

The system SHALL run automation tasks on a predefined schedule using cron or background jobs.

#### Scenario: Schedule nightly post creation

- **GIVEN** automation is configured with Whenever gem
- **WHEN** cron schedule is generated
- **THEN** `automation:create_tomorrow_posts` task is scheduled daily at 11:00 PM
- **AND** task runs automatically without manual trigger
- **AND** crontab shows correct schedule entry

#### Scenario: Schedule hourly post publishing

- **GIVEN** automation is configured with Whenever gem
- **WHEN** cron schedule is generated
- **THEN** `scheduling:post_scheduled` task is scheduled every hour
- **AND** task runs automatically without manual trigger
- **AND** crontab shows correct schedule entry

---

### Requirement: Health Checks

The system SHALL perform health checks before automation cycles to ensure prerequisites are met.

#### Scenario: Health check passes

- **GIVEN** Instagram API credentials are valid
- **AND** database is accessible
- **AND** photo library has at least 50 available photos
- **WHEN** health check runs before automation
- **THEN** health check passes
- **AND** automation cycle proceeds
- **AND** log records "Health check passed"

#### Scenario: Health check fails on missing photos

- **GIVEN** photo library has fewer than 50 available photos
- **WHEN** health check runs
- **THEN** health check fails
- **AND** automation cycle is skipped
- **AND** alert notification is sent: "Photo library exhausted (<50 photos)"
- **AND** log records "Health check failed: Insufficient photos"

#### Scenario: Health check fails on invalid credentials

- **GIVEN** Instagram API credentials are expired or invalid
- **WHEN** health check runs
- **THEN** health check fails
- **AND** automation cycle is skipped
- **AND** alert notification is sent: "Instagram credentials invalid"
- **AND** log records "Health check failed: API credentials invalid"

---

### Requirement: Error Handling and Retry Logic

The system SHALL handle failures gracefully with retry logic and fallback mechanisms.

#### Scenario: Retry on transient failure

- **GIVEN** a draft post ready to publish
- **AND** Instagram API returns rate limit error
- **WHEN** publishing is attempted
- **THEN** system retries up to 3 times with exponential backoff (1s, 2s, 4s)
- **AND** if retry succeeds, post is marked 'posted'
- **AND** log records "Posting succeeded after 2 retries"

#### Scenario: Mark as failed after max retries

- **GIVEN** a draft post ready to publish
- **AND** Instagram API fails 3 consecutive times
- **WHEN** max retries are exhausted
- **THEN** post status is updated to 'failed'
- **AND** error is logged with details
- **AND** alert notification is sent: "Posting failed for post #{post.id}"

#### Scenario: Circuit breaker opens after repeated failures

- **GIVEN** 5 consecutive posting failures
- **WHEN** circuit breaker threshold is reached
- **THEN** circuit breaker opens (state: 'open')
- **AND** all subsequent posting attempts are blocked for 1 hour
- **AND** alert notification is sent: "Circuit breaker opened - Instagram API failing"
- **AND** log records "Circuit breaker OPEN: Blocking requests for 1 hour"

#### Scenario: Circuit breaker half-open test

- **GIVEN** circuit breaker has been open for 1 hour
- **WHEN** timeout expires
- **THEN** circuit breaker enters 'half-open' state
- **AND** system attempts one test post
- **AND** if test succeeds: circuit closes, resume normal operation
- **AND** if test fails: circuit stays open for another hour

#### Scenario: Fallback to basic strategy on failure

- **GIVEN** ContentStrategy::SelectNextPost fails
- **WHEN** post creation is attempted
- **THEN** system falls back to CuratorsChoice strategy (highest aesthetic score)
- **AND** post is created successfully using fallback
- **AND** log records "ContentStrategy failed, using CuratorsChoice fallback"

---

### Requirement: Structured Logging

The system SHALL log all automation activities with structured, searchable logs.

#### Scenario: Log post creation steps

- **GIVEN** automated post creation runs
- **WHEN** posts are created
- **THEN** log entries are written to log/automation.log
- **AND** each log entry has format: `[timestamp] LEVEL [component] message (context)`
- **AND** log includes: photo selected, caption generated, hashtags generated, post created
- **AND** log includes persona name, photo ID, post ID, optimal time

Example log output:
```
[2024-11-04 23:00:01] INFO [Sarah] Selecting next post with ContentStrategy
[2024-11-04 23:00:02] INFO [Sarah] Selected photo 1234, cluster: Urban Exploration
[2024-11-04 23:00:03] INFO [Sarah] Generated caption (persona-aware, 87 chars)
[2024-11-04 23:00:04] INFO [Sarah] Generated hashtags (intelligent, 9 tags)
[2024-11-04 23:00:05] INFO [Sarah] Created scheduled post 567 for 2024-11-05 09:00:00 EST
```

#### Scenario: Log posting steps

- **GIVEN** automated post publishing runs
- **WHEN** posts are published
- **THEN** log entries are written to log/automation.log
- **AND** each step is logged: URL generation, Instagram API call, status update
- **AND** Instagram post ID is logged
- **AND** errors are logged with full stack trace

---

### Requirement: Automation Health Dashboard

The system SHALL provide a web dashboard to monitor automation pipeline status and health.

#### Scenario: Display pipeline status

- **GIVEN** automation has run successfully
- **WHEN** admin views /admin/automation_health
- **THEN** dashboard displays:
  - Last run timestamp
  - Next run timestamp
  - Health status: "Healthy" (green) or "Unhealthy" (red)
  - Total posts created today
  - Total posts published today

#### Scenario: Display upcoming posts

- **GIVEN** draft posts exist for next 7 days
- **WHEN** admin views dashboard
- **THEN** dashboard displays upcoming posts table with:
  - Scheduled date/time
  - Persona name
  - Photo thumbnail
  - Cluster name
  - Status (draft)
- **AND** posts are sorted by optimal_time_calculated (ascending)

#### Scenario: Display recent posts

- **GIVEN** posts published in last 7 days
- **WHEN** admin views dashboard
- **THEN** dashboard displays recent posts table with:
  - Posted date/time
  - Persona name
  - Photo thumbnail
  - Instagram post URL
  - Status (posted, failed)
- **AND** posts are sorted by posted_at (descending)

#### Scenario: Display errors and warnings

- **GIVEN** automation encountered errors in last 24 hours
- **WHEN** admin views dashboard
- **THEN** dashboard displays errors section with:
  - Error count
  - Recent error messages
  - Affected posts (post ID, persona)
  - Circuit breaker status (open/closed)

---

### Requirement: 3-Day Autonomous Operation

The system SHALL run fully autonomously for at least 3 consecutive days without manual intervention, meeting all acceptance criteria from Milestone 5c roadmap.

#### Scenario: Day 1 autonomous operation

- **GIVEN** automation is configured and started
- **AND** Sarah's persona has active strategy (4 posts/week)
- **WHEN** Day 1 nightly task runs
- **THEN** 4 draft posts are created for Day 2
- **AND** each post has persona-aware caption and intelligent hashtags
- **WHEN** Day 2 hourly tasks run
- **THEN** 4 posts are published to Instagram at optimal times (9am-12pm)
- **AND** all posts have correct captions, hashtags, and images on Instagram
- **AND** no errors are logged

#### Scenario: Day 2 autonomous operation

- **GIVEN** Day 1 completed successfully
- **WHEN** Day 2 nightly task runs
- **THEN** 4 more draft posts are created for Day 3
- **AND** posts are different from Day 1 (no duplicates)
- **WHEN** Day 3 hourly tasks run
- **THEN** 4 posts are published to Instagram at optimal times
- **AND** all posts have correct content
- **AND** no manual intervention required

#### Scenario: Day 3 autonomous operation

- **GIVEN** Day 1 and Day 2 completed successfully
- **WHEN** Day 3 nightly task runs
- **THEN** 4 more draft posts are created for Day 4
- **WHEN** Day 4 hourly tasks run
- **THEN** 4 posts are published to Instagram
- **AND** total of 12 posts created and published over 3 days
- **AND** zero manual interventions required
- **AND** automation log shows all successful operations

---

### Requirement: Notifications

The system SHALL send notifications for key automation events and errors.

#### Scenario: Daily summary notification

- **GIVEN** nightly automation created posts
- **WHEN** post creation completes
- **THEN** notification is sent with summary:
  - "✅ Created 4 posts for tomorrow (Sarah)"
  - List of photos and scheduled times
- **AND** notification is sent via configured channel (Slack/email)

#### Scenario: Post success notification

- **GIVEN** a post is successfully published to Instagram
- **WHEN** publishing completes
- **THEN** notification is sent:
  - "✅ Posted to Sarah's Instagram: [Instagram URL]"
  - Photo thumbnail
  - Caption preview
- **AND** notification includes link to Instagram post

#### Scenario: Post failure notification

- **GIVEN** a post fails to publish after max retries
- **WHEN** post is marked as 'failed'
- **THEN** notification is sent:
  - "❌ Posting failed for post #{post.id}"
  - Error message
  - Persona and photo details
- **AND** notification includes actionable next steps

#### Scenario: Health check failure notification

- **GIVEN** health check fails before automation
- **WHEN** automation cycle is skipped
- **THEN** notification is sent:
  - "⚠️ Automation health check failed: {reason}"
  - Details of failure (e.g., "Instagram credentials invalid")
  - Recommended action
- **AND** notification is marked as critical priority

---

## MODIFIED Requirements

### Requirement: Content Strategy Caption Integration

The ContentStrategy.generate_caption method SHALL be enhanced to integrate persona-aware caption generation from Milestone 5a.

#### Scenario: Use persona-aware caption when configured

- **GIVEN** Sarah's persona with caption_config configured
- **WHEN** ContentStrategy.generate_caption is called
- **THEN** CaptionGenerations::Generator is invoked (persona-aware)
- **AND** caption matches Sarah's voice and style
- **AND** caption_metadata includes method: "persona_aware"

#### Scenario: Fallback to generic caption when not configured

- **GIVEN** a persona without caption_config
- **WHEN** ContentStrategy.generate_caption is called
- **THEN** photo_analysis.caption is used (generic fallback)
- **AND** caption_metadata includes method: "photo_analysis"

---

### Requirement: Content Strategy Hashtag Integration

The BaseStrategy.select_hashtags method SHALL be enhanced to integrate intelligent hashtag generation from Milestone 5b.

#### Scenario: Use intelligent hashtags when configured

- **GIVEN** Sarah's persona with hashtag_strategy configured
- **WHEN** BaseStrategy.select_hashtags is called
- **THEN** HashtagGenerations::Generator is invoked (intelligent)
- **AND** hashtags include content-specific, persona-aligned, and optimal mix
- **AND** hashtag_metadata includes method: "intelligent_generation"

#### Scenario: Fallback to basic hashtags when not configured

- **GIVEN** a persona without hashtag_strategy
- **WHEN** BaseStrategy.select_hashtags is called
- **THEN** HashtagEngine.generate is used (basic fallback)
- **AND** hashtag_metadata includes method: "basic"

---

## Implementation Notes

### Automation Task Structure

```ruby
# lib/tasks/automation.rake
namespace :automation do
  desc 'Create tomorrow\'s scheduled posts for all personas'
  task :create_tomorrow_posts => :environment do
    Automation::CreateTomorrowPosts.call
  end
  
  desc 'Run health check before automation'
  task :health_check => :environment do
    result = Automation::HealthCheck.call
    exit 1 unless result.success?
  end
end
```

### Cron Schedule (Whenever gem)

```ruby
# config/schedule.rb
every 1.day, at: '11:00 pm' do
  rake "automation:health_check && automation:create_tomorrow_posts"
end

every 1.hour do
  rake "scheduling:post_scheduled"
end
```

### Service Architecture

```
Automation::CreateTomorrowPosts
  ├── Load active personas
  ├── Calculate posts needed per persona
  ├── For each post:
  │   ├── ContentStrategy::SelectNextPost.call()
  │   │   ├── Select photo + cluster
  │   │   ├── Generate caption (5a integration)
  │   │   └── Generate hashtags (5b integration)
  │   ├── Scheduling::Post.create!(status: 'draft', ...)
  │   └── Log creation
  └── Send daily summary notification

Automation::HealthCheck
  ├── Check Instagram API credentials
  ├── Check database connectivity
  ├── Check photo availability (>50 photos)
  └── Return success/failure

Automation::RetryStrategy
  ├── Retry with exponential backoff (1s, 2s, 4s)
  ├── Max 3 retries
  └── If all fail: Mark as failed, notify

Automation::CircuitBreaker
  ├── Track consecutive failures
  ├── States: Closed, Open (1 hour), Half-Open (test)
  └── Open circuit after 5 failures
```

### Dashboard Controller

```ruby
# app/controllers/admin/automation_health_controller.rb
class Admin::AutomationHealthController < ApplicationController
  def index
    @pipeline_status = {
      last_run: last_automation_run,
      next_run: next_automation_run,
      health: pipeline_health
    }
    @upcoming_posts = Scheduling::Post.draft.upcoming(7.days)
    @recent_posts = Scheduling::Post.posted.recent(7.days)
    @errors = recent_errors(24.hours)
    @per_persona_stats = calculate_persona_stats
  end
end
```

### Logging Format

```ruby
# Use structured logging
logger = Logger.new('log/automation.log')
logger.info "[#{persona.name}] Created scheduled post #{post.id} for #{optimal_time}"
logger.error "[Post #{post.id}] Instagram posting failed: #{error.message}"
```

### Integration Points

```ruby
# In ContentStrategy.generate_caption()
def generate_caption(photo, hashtags)
  if persona.caption_config.present?
    result = CaptionGenerations::Generator.generate(
      photo: photo, persona: persona, cluster: cluster
    )
    caption = result.text
    metadata = result.metadata
  else
    caption = photo.photo_analysis&.caption || ""
    metadata = { method: 'photo_analysis' }
  end
  
  full_caption = "#{caption}\n\n#{hashtags.join(' ')}"
  { text: full_caption, metadata: metadata }
end

# In BaseStrategy.select_hashtags()
def select_hashtags(photo:, cluster:)
  if context.persona.hashtag_strategy.present?
    result = HashtagGenerations::Generator.generate(
      photo: photo, persona: context.persona, cluster: cluster, count: 9
    )
    return result.hashtags
  end
  
  HashtagEngine.generate(photo: photo, cluster: cluster, count: 9)
end
```
