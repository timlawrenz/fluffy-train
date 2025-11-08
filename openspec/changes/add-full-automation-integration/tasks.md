# Tasks: Full Automation & Integration

**Change ID**: `add-full-automation-integration`  
**Status**: Not Started  
**Created**: 2024-11-04

---

## Progress

**Current Status:** Planning / Prerequisites in Progress
**Overall Completion:** 0%

**Note:** This milestone integrates and automates existing components (Milestones 4c, 5a, 5b). All building blocks exist individually but need continuous automation via cron/scheduler.

**Prerequisites:**
- ✅ Content Strategy Engine (Milestone 4c) - Complete
- ⏳ Caption Generation (Milestone 5a) - In Progress
- ⏳ Hashtag Generation (Milestone 5b) - Not Started

---

## Phase 1: Automated Post Creation (Week 1, Days 1-2)

### Post Creation Task
- [ ] Create `lib/tasks/automation.rake`
- [ ] Implement `automation:create_tomorrow_posts` task
- [ ] For each active persona:
  - [ ] Calculate posts needed based on strategy frequency
  - [ ] Call ContentStrategy::SelectNextPost
  - [ ] Generate captions (with Milestone 5a enhancements)
  - [ ] Generate hashtags (with Milestone 5b enhancements)
  - [ ] Create draft Scheduling::Post records
- [ ] Add comprehensive logging to `log/automation.log`
- [ ] Write specs for post creation task

### Error Handling
- [ ] Handle photo library exhaustion gracefully
- [ ] Handle API failures (caption/hashtag generation)
- [ ] Fallback to generic captions/hashtags if AI unavailable
- [ ] Alert on creation failures
- [ ] Write specs for error scenarios

---

## Phase 2: Automated Post Publishing (Week 1, Days 2-3)

### Post Publishing Task Enhancement
- [ ] Enhance existing `scheduling:post_scheduled` task
- [ ] Find draft posts where `optimal_time_calculated <= now`
- [ ] Post to Instagram via Instagram::Client
- [ ] Update status to 'posted' with timestamp
- [ ] Record Instagram post ID and URL
- [ ] Add retry logic for transient failures
- [ ] Write specs for publishing enhancements

### Retry Strategy
- [ ] Create `app/services/automation/retry_strategy.rb`
- [ ] Implement exponential backoff (1s, 5s, 15s delays)
- [ ] Max 3 retry attempts per post
- [ ] Track retry count in post metadata
- [ ] Write specs for retry strategy

### Circuit Breaker
- [ ] Create `app/services/automation/circuit_breaker.rb`
- [ ] Open circuit after 5 consecutive failures
- [ ] Half-open state after 30 minutes
- [ ] Prevent spam posting during outages
- [ ] Write specs for circuit breaker

---

## Phase 3: Scheduler Configuration (Week 1, Days 3-4)

### Cron Configuration (Option 1)
- [ ] Add `whenever` gem to Gemfile
- [ ] Create `config/schedule.rb`
- [ ] Schedule `automation:create_tomorrow_posts` at 11:00 PM daily
- [ ] Schedule `scheduling:post_scheduled` every hour
- [ ] Generate crontab with `whenever --update-crontab`
- [ ] Write deployment documentation

### Solid Queue Configuration (Option 2 - Rails 8)
- [ ] Create recurring job for post creation
- [ ] Create recurring job for post publishing
- [ ] Configure job schedules in `config/solid_queue.yml`
- [ ] Add job monitoring and logging
- [ ] Write deployment documentation

### Decision: Choose Scheduler
- [ ] Evaluate Cron vs Solid Queue for production environment
- [ ] Document decision and rationale
- [ ] Implement chosen scheduler

---

## Phase 4: Monitoring & Health Checks (Week 1, Days 4-5)

### Health Check Service
- [ ] Create `app/services/automation/health_check.rb`
- [ ] Check Instagram API credentials valid
- [ ] Check photo library has sufficient photos (>50)
- [ ] Check recent posting success rate (>80%)
- [ ] Check active personas have strategies configured
- [ ] Write specs for health checks

### Automation Logger
- [ ] Create `app/services/automation/logger.rb`
- [ ] Log to `log/automation.log` with structured format
- [ ] Log levels: INFO (success), WARN (retry), ERROR (failure)
- [ ] Include context: persona, photo, timestamp, error details
- [ ] Write specs for logging

### Metrics Tracking
- [ ] Create `automation_metrics` table (date, persona, posts_created, posts_published, failures)
- [ ] Add migration for metrics tracking
- [ ] Record daily metrics
- [ ] Write specs for metrics

---

## Phase 5: Monitoring Dashboard (Week 2, Days 1-3)

### Dashboard Controller
- [ ] Create `app/controllers/admin/automation_controller.rb`
- [ ] Implement `index` action (dashboard overview)
- [ ] Implement `health` action (health status)
- [ ] Implement `logs` action (recent logs)
- [ ] Add authentication/authorization (admin only)

### Dashboard Views
- [ ] Create `app/views/admin/automation/index.html.haml`
- [ ] Display pipeline status (last run, next run, health)
- [ ] Display upcoming posts (next 7 days)
- [ ] Display recent posts (last 7 days with status)
- [ ] Display error count (last 24 hours)
- [ ] Display per-persona stats

### Dashboard Components
- [ ] Create ViewComponent for pipeline status
- [ ] Create ViewComponent for upcoming posts list
- [ ] Create ViewComponent for recent posts list
- [ ] Create ViewComponent for health indicators
- [ ] Style with Tailwind CSS

### Real-Time Updates (Stretch)
- [ ] Add Turbo Streams for live updates
- [ ] Auto-refresh dashboard every 60 seconds
- [ ] Show posting in progress indicator

---

## Phase 6: Alerting System (Week 2, Days 3-4)

### Notification Service
- [ ] Create `app/services/automation/notifier.rb`
- [ ] Implement email notifications
- [ ] Implement Slack notifications (optional)
- [ ] Configure notification channels
- [ ] Write specs for notifications

### Alert Types
- [ ] Daily summary: Posts created for tomorrow
- [ ] Success: Post published to Instagram
- [ ] Warning: Retry occurred (API rate limit)
- [ ] Error: Posting failed after 3 retries
- [ ] Critical: Circuit breaker opened
- [ ] Health: Health check failed

### Notification Configuration
- [ ] Add notification settings to persona config
- [ ] Allow enabling/disabling alerts per type
- [ ] Configure quiet hours (no alerts 11 PM - 7 AM)
- [ ] Write specs for configuration

---

## Phase 7: Integration & Enhancement (Week 2, Days 4-5)

### Content Strategy Integration
- [ ] Update `ContentStrategy.generate_caption` to use Milestone 5a generator
- [ ] Check for `persona.caption_config` presence
- [ ] Fallback to `photo_analysis.caption` if not configured
- [ ] Store `caption_metadata`
- [ ] Write integration specs

### Hashtag Integration
- [ ] Update `BaseStrategy.select_hashtags` to use Milestone 5b generator
- [ ] Check for `persona.hashtag_strategy` presence
- [ ] Fallback to `HashtagEngine` if not configured
- [ ] Store `hashtag_metadata`
- [ ] Write integration specs

### End-to-End Pipeline Test
- [ ] Create integration test for full pipeline
- [ ] Test: Nightly creation → Hourly publishing → Instagram post
- [ ] Verify captions from Milestone 5a
- [ ] Verify hashtags from Milestone 5b
- [ ] Verify metadata tracking
- [ ] Write comprehensive integration specs

---

## Phase 8: 3-Day Autonomy Test (Week 3, Days 1-3)

### Test Setup
- [ ] Configure Sarah persona with:
  - [ ] `caption_config` (Milestone 5a)
  - [ ] `hashtag_strategy` (Milestone 5b)
  - [ ] Content strategy (4 posts/week)
- [ ] Ensure 50+ photos available in library
- [ ] Enable automation scheduler
- [ ] Configure test notifications

### Day 1 Validation
- [ ] Run automation, verify 4 posts created
- [ ] Verify captions are persona-aware
- [ ] Verify hashtags are content-based
- [ ] Verify posts published at optimal times
- [ ] Check Instagram for correct content
- [ ] Review automation.log for errors

### Day 2 Validation
- [ ] Verify 4 more posts created automatically
- [ ] Verify no duplicates or repetition
- [ ] Verify format variety (carousels, statics)
- [ ] Verify posts published successfully
- [ ] Check dashboard metrics

### Day 3 Validation
- [ ] Verify 4 more posts created automatically
- [ ] Verify total 12 posts on Instagram
- [ ] Verify no manual intervention required
- [ ] Verify error recovery worked (if any)
- [ ] Review full test logs

### Acceptance Validation
- [ ] Assert: 12 posts created and published
- [ ] Assert: Zero manual interventions
- [ ] Assert: All posts have Instagram URLs
- [ ] Assert: Dashboard shows healthy status
- [ ] Assert: Notifications sent correctly

---

## Phase 9: Documentation & Deployment (Week 3, Days 4-5)

### Documentation
- [ ] Write automation setup guide
- [ ] Document scheduler configuration (cron/Solid Queue)
- [ ] Document monitoring dashboard usage
- [ ] Document alerting configuration
- [ ] Document troubleshooting common issues
- [ ] Update README with automation features

### Deployment Guide
- [ ] Write production deployment checklist
- [ ] Document environment variables needed
- [ ] Document cron setup on production server
- [ ] Document Instagram API credential configuration
- [ ] Document backup and recovery procedures

### Production Deployment
- [ ] Deploy automation tasks to production
- [ ] Configure scheduler (cron/Solid Queue)
- [ ] Test health checks in production
- [ ] Run first manual creation cycle
- [ ] Monitor first 24 hours
- [ ] Enable full automation

### Production Smoke Test
- [ ] Run automation for 1 day in production
- [ ] Manually verify first batch of posts
- [ ] Check Instagram for correct captions, hashtags, images
- [ ] Review automation.log for warnings
- [ ] Confirm dashboard shows healthy status
- [ ] Validate notifications received

---

## Acceptance Criteria Validation

### AC1: Continuous Automation
- [ ] Verify posts created daily without manual trigger
- [ ] Verify posts published hourly automatically
- [ ] Test: System runs for 3 days autonomously

### AC2: Integration
- [ ] Verify caption generation (Milestone 5a) integrated
- [ ] Verify hashtag generation (Milestone 5b) integrated
- [ ] Verify metadata tracked correctly

### AC3: Error Handling
- [ ] Verify retry logic works (3 attempts)
- [ ] Verify circuit breaker opens after 5 failures
- [ ] Verify graceful fallbacks (generic captions/hashtags)

### AC4: Monitoring
- [ ] Verify dashboard shows all key metrics
- [ ] Verify logs capture all pipeline stages
- [ ] Verify health checks run correctly

### AC5: Alerts
- [ ] Verify daily summary notifications
- [ ] Verify success notifications
- [ ] Verify error notifications
- [ ] Verify critical alerts (circuit breaker)

### AC6: Performance
- [ ] Verify post creation completes in <30 seconds
- [ ] Verify publishing completes in <10 seconds
- [ ] Verify dashboard loads in <2 seconds

---

## Risk Mitigation

### Risk: Cron misconfiguration
- Test cron schedule in staging
- Dashboard shows next run time
- Alert if no posts created in 24 hours

### Risk: Instagram API changes
- Circuit breaker stops posting after 5 failures
- Notifications alert admin immediately
- Fallback to manual posting

### Risk: Photo library exhaustion
- Health check warns if <50 photos available
- Alert admin to upload more photos
- Reduce posting frequency temporarily

### Risk: Over-posting
- Strategy config limits posting frequency
- Dashboard shows upcoming posts
- Max 5 posts per day hard limit

---

## Dependencies

**Required (Complete):**
- ✅ ContentStrategy::SelectNextPost (Milestone 4c)
- ✅ Instagram::Client (Milestone 3)
- ✅ Scheduling::Post model (Milestone 3)

**Required (In Progress):**
- ⏳ Caption Generation (Milestone 5a) - Can proceed with fallback
- ⏳ Hashtag Generation (Milestone 5b) - Can proceed with fallback

**Optional:**
- Whenever gem (for Cron)
- Solid Queue (Rails 8 recurring jobs)
- Slack API (for notifications)

---

## Open Questions

1. **Cron vs Solid Queue?**
   - [ ] Decision: Which scheduler for production?
   - Production environment: Heroku/cloud vs VPS?

2. **Notification channels?**
   - [ ] Email only or add Slack?
   - Decision: Based on team preference

3. **Health check frequency?**
   - [ ] Decision: Every hour, daily, or on-demand?

4. **Pre-posting review queue?**
   - [ ] Decision: Optional human approval before posting?
   - Recommendation: Yes for first month, then optional

---

## Related Changes

- `add-content-strategy-engine` (Milestone 4c) - Provides selection logic
- `add-persona-caption-generation` (Milestone 5a) - Provides caption generation
- `add-automated-hashtag-generation` (Milestone 5b) - Provides hashtag generation

---

**Last Updated**: 2024-11-04  
**Est. Completion**: 3 weeks (after 5a & 5b complete)  
**Assignee**: TBD  
**Prerequisites**: Milestones 5a and 5b must be complete or near-complete
