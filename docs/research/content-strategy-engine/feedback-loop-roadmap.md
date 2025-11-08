# Content Strategy Feedback Loop: Implementation Roadmap

**Milestone**: 5d - Strategy Performance Feedback Loop  
**Status**: Planning  
**Priority**: High (unlocks data-driven optimization)  
**Estimated Timeline**: 6-8 weeks

---

## Executive Summary

This roadmap details the implementation of a **closed-loop learning system** that:
1. Collects real Instagram performance data via API
2. Analyzes patterns in posting success/failure
3. Automatically tunes strategy configurations
4. Provides actionable insights for manual optimization
5. Enables systematic A/B testing of strategies

**Key Insight from Sarah's Data**: Research-based defaults (5-8am, 3-5 posts/week) don't match her actual audience behavior (Wed-Fri 9am-12pm, oversaturated at 7.4 posts/week). We need a system that learns each persona's unique patterns.

---

## Phase 1: Instagram API Integration (Week 1-2)

### Objective
Connect to Instagram Graph API and pull basic insights for posted content.

### Prerequisites
- Instagram Business or Creator account (Sarah ✅)
- Facebook Page linked to Instagram account
- Facebook App with Instagram Graph API permissions
- Access token management system

### Technical Implementation

**1.1: API Client Setup**

Create Instagram Graph API client in `packs/instagram_integration/`:

```ruby
# app/services/instagram_integration/graph_api_client.rb
module InstagramIntegration
  class GraphApiClient
    BASE_URL = "https://graph.instagram.com/v18.0"
    
    def initialize(access_token)
      @access_token = access_token
    end
    
    def get_media_insights(media_id, metrics)
      # Fetch insights for specific post
      # Metrics: reach, impressions, engagement, likes, comments, saves, shares
    end
    
    def get_account_insights(account_id, metrics, period)
      # Fetch account-level insights
      # Metrics: follower_count, reach, profile_views
    end
    
    def get_online_followers(account_id)
      # Get audience activity times (hour of day, day of week)
    end
  end
end
```

**1.2: Credentials Management**

```ruby
# Add to personas table
rails g migration AddInstagramCredentialsToPersonas \
  instagram_account_id:string \
  instagram_access_token:text \
  instagram_token_expires_at:datetime

# Secure token storage
class Persona < ApplicationRecord
  encrypts :instagram_access_token
  
  def instagram_client
    @instagram_client ||= InstagramIntegration::GraphApiClient.new(
      decrypt_access_token
    )
  end
end
```

**1.3: Available Metrics**

Instagram Graph API provides:

**Media Insights** (per post):
- `reach` - Unique accounts reached
- `impressions` - Total views
- `engagement` - Likes + comments + saves + shares
- `likes` - Like count
- `comments` - Comment count  
- `saves` - Save count
- `shares` - Share count (DMs + Stories)
- `video_views` - For Reels/videos
- `reach_by_source` - Home/Explore/Profile/Hashtags breakdown

**Account Insights** (aggregate):
- `follower_count` - Total followers
- `reach` - Accounts reached (daily/weekly/28-day)
- `profile_views` - Profile visits
- `website_clicks` - Bio link clicks

**Audience Insights**:
- `online_followers` - Best times (by hour, by day)
- `follower_demographics` - Age, gender, location

### Deliverables
- [ ] Instagram Graph API client implemented and tested
- [ ] Persona model extended with Instagram credentials
- [ ] Token refresh mechanism (tokens expire every 60 days)
- [ ] Error handling for rate limits and auth failures
- [ ] Test coverage for API client

### Success Criteria
- Can authenticate Sarah's Instagram account
- Can pull insights for a specific post
- Can retrieve online_followers data
- Handles API errors gracefully

---

## Phase 2: Insights Storage & Collection (Week 3-4)

### Objective
Store performance data in database and automate regular collection.

### Technical Implementation

**2.1: Database Schema**

```ruby
# db/migrate/XXXXXX_create_content_strategy_insights.rb
class CreateContentStrategyInsights < ActiveRecord::Migration[7.0]
  def change
    create_table :content_strategy_insights do |t|
      # Relationships
      t.references :persona, null: false, foreign_key: true
      t.references :scheduling_post, foreign_key: true
      t.string :instagram_media_id, index: true
      
      # Timing
      t.datetime :posted_at, null: false
      t.string :day_of_week, limit: 10
      t.integer :hour_of_day
      
      # Performance metrics
      t.integer :reach
      t.integer :impressions
      t.integer :engagement
      t.integer :likes
      t.integer :comments
      t.integer :saves
      t.integer :shares
      t.integer :video_views
      
      # Calculated metrics
      t.decimal :engagement_rate, precision: 5, scale: 2
      t.decimal :non_follower_reach_pct, precision: 5, scale: 2
      t.decimal :save_rate, precision: 5, scale: 2
      
      # Context
      t.string :strategy_type, limit: 50
      t.bigint :cluster_id
      t.string :content_format, limit: 20  # reel, carousel, static
      t.text :hashtags, array: true, default: []
      
      # Reach breakdown (if available)
      t.jsonb :reach_by_source, default: {}
      
      # Metadata
      t.datetime :collected_at, null: false
      t.timestamps
    end
    
    add_index :content_strategy_insights, [:persona_id, :posted_at]
    add_index :content_strategy_insights, [:persona_id, :engagement_rate]
    add_index :content_strategy_insights, :day_of_week
    add_index :content_strategy_insights, :hour_of_day
    add_index :content_strategy_insights, :content_format
  end
end
```

**2.2: Model Implementation**

```ruby
# packs/content_strategy/app/models/content_strategy/insight.rb
module ContentStrategy
  class Insight < ApplicationRecord
    self.table_name = "content_strategy_insights"
    
    belongs_to :persona
    belongs_to :scheduling_post, optional: true
    belongs_to :cluster, class_name: "Clustering::Cluster", optional: true
    
    validates :persona_id, presence: true
    validates :posted_at, presence: true
    
    scope :recent, -> { where("posted_at > ?", 30.days.ago) }
    scope :by_format, ->(format) { where(content_format: format) }
    scope :high_performing, -> { where("engagement_rate > ?", 2.0) }
    
    # Calculate metrics
    before_save :calculate_derived_metrics
    
    def calculate_derived_metrics
      if engagement.present? && reach.present? && reach > 0
        self.engagement_rate = (engagement.to_f / reach * 100).round(2)
      end
      
      if reach.present? && impressions.present? && impressions > 0
        # Non-follower reach estimation
        follower_impressions = impressions * 0.7  # Rough estimate
        non_follower_reach = [0, reach - follower_impressions].max
        self.non_follower_reach_pct = (non_follower_reach / reach * 100).round(2)
      end
      
      if saves.present? && reach.present? && reach > 0
        self.save_rate = (saves.to_f / reach * 100).round(2)
      end
    end
    
    # Time-based queries
    scope :on_weekday, ->(day) { where(day_of_week: day.to_s.downcase) }
    scope :in_hour_range, ->(start_hour, end_hour) {
      where(hour_of_day: start_hour..end_hour)
    }
  end
end
```

**2.3: Collection Service**

```ruby
# app/services/content_strategy/insights_collector.rb
module ContentStrategy
  class InsightsCollector
    def initialize(persona)
      @persona = persona
      @client = persona.instagram_client
    end
    
    def collect_recent_insights(days_back: 7)
      posts = find_posts_needing_insights(days_back)
      
      posts.each do |post|
        collect_post_insights(post)
      end
    end
    
    private
    
    def find_posts_needing_insights(days_back)
      @persona.scheduling_posts
        .where("scheduled_at > ?", days_back.days.ago)
        .where(state: "published")
        .where.not(instagram_media_id: nil)
        .left_joins(:content_strategy_insights)
        .where(content_strategy_insights: { id: nil })
    end
    
    def collect_post_insights(post)
      metrics = @client.get_media_insights(
        post.instagram_media_id,
        %w[reach impressions engagement likes comments saves shares]
      )
      
      ContentStrategy::Insight.create!(
        persona: @persona,
        scheduling_post: post,
        instagram_media_id: post.instagram_media_id,
        posted_at: post.published_at,
        day_of_week: post.published_at.strftime("%A").downcase,
        hour_of_day: post.published_at.hour,
        reach: metrics["reach"],
        impressions: metrics["impressions"],
        engagement: metrics["engagement"],
        likes: metrics["likes"],
        comments: metrics["comments"],
        saves: metrics["saves"],
        shares: metrics["shares"],
        strategy_type: post.strategy_type,
        cluster_id: post.photo&.cluster_id,
        content_format: detect_format(post),
        collected_at: Time.current
      )
      
      Rails.logger.info "Collected insights for post #{post.id}: #{metrics['reach']} reach"
    rescue => e
      Rails.logger.error "Failed to collect insights for post #{post.id}: #{e.message}"
    end
    
    def detect_format(post)
      # Logic to determine if post was Reel, Carousel, or Static
      # May need to store this on scheduling_post
      post.content_format || "unknown"
    end
  end
end
```

**2.4: Scheduled Job**

```ruby
# app/jobs/content_strategy/collect_insights_job.rb
module ContentStrategy
  class CollectInsightsJob < ApplicationJob
    queue_as :default
    
    def perform
      Persona.where.not(instagram_account_id: nil).find_each do |persona|
        InsightsCollector.new(persona).collect_recent_insights
      end
    end
  end
end

# config/schedule.rb (whenever gem)
every 1.day, at: '2:00 am' do
  runner "ContentStrategy::CollectInsightsJob.perform_later"
end
```

### Deliverables
- [ ] `content_strategy_insights` table created
- [ ] `Insight` model with validations and scopes
- [ ] `InsightsCollector` service implemented
- [ ] Scheduled job runs daily
- [ ] Manual collection rake task for backfill

### Success Criteria
- Can store insights for a test post
- Daily job collects insights for all recent posts
- Insights data queryable for analysis
- No data loss or duplicates

---

## Phase 3: Analysis & Reporting (Week 5-6)

### Objective
Analyze collected data to identify patterns and generate actionable insights.

### Technical Implementation

**3.1: Performance Analyzer**

```ruby
# app/services/content_strategy/performance_analyzer.rb
module ContentStrategy
  class PerformanceAnalyzer
    def initialize(persona)
      @persona = persona
      @insights = persona.insights.recent
    end
    
    # Find best posting times
    def analyze_optimal_times
      hourly_performance = @insights
        .group(:hour_of_day)
        .average(:engagement_rate)
        .sort_by { |_, rate| -rate }
      
      daily_performance = @insights
        .group(:day_of_week)
        .average(:engagement_rate)
        .sort_by { |_, rate| -rate }
      
      {
        best_hours: hourly_performance.first(3).to_h,
        best_days: daily_performance.first(3).to_h,
        current_config: current_time_config,
        recommendation: generate_time_recommendation(hourly_performance, daily_performance)
      }
    end
    
    # Analyze format performance
    def analyze_format_effectiveness
      format_stats = @insights
        .group(:content_format)
        .select(
          "content_format",
          "AVG(engagement_rate) as avg_engagement",
          "AVG(reach) as avg_reach",
          "AVG(non_follower_reach_pct) as avg_nf_reach",
          "COUNT(*) as post_count"
        )
      
      {
        by_format: format_stats,
        recommendation: generate_format_recommendation(format_stats)
      }
    end
    
    # Detect oversaturation
    def analyze_posting_frequency
      posts_by_week = @insights
        .group_by { |i| i.posted_at.beginning_of_week }
        .transform_values { |insights| 
          {
            count: insights.size,
            avg_engagement: insights.map(&:engagement_rate).compact.avg,
            avg_reach: insights.map(&:reach).compact.avg
          }
        }
      
      # Correlation between frequency and engagement
      correlation = calculate_frequency_correlation(posts_by_week)
      
      {
        weekly_stats: posts_by_week,
        correlation: correlation,
        recommendation: generate_frequency_recommendation(correlation)
      }
    end
    
    # Calculate success metrics
    def calculate_kpis(period: 30.days)
      insights = @persona.insights.where("posted_at > ?", period.ago)
      
      {
        total_posts: insights.count,
        avg_reach: insights.average(:reach)&.round(0),
        avg_engagement_rate: insights.average(:engagement_rate)&.round(2),
        avg_non_follower_reach: insights.average(:non_follower_reach_pct)&.round(2),
        top_post: insights.order(reach: :desc).first,
        worst_post: insights.order(reach: :asc).first
      }
    end
    
    private
    
    def generate_time_recommendation(hourly, daily)
      # Compare current config to actual best times
      # Return suggestion if misalignment detected
    end
    
    def generate_format_recommendation(format_stats)
      # Suggest format mix based on performance
    end
    
    def generate_frequency_recommendation(correlation)
      # Suggest frequency adjustment if oversaturation detected
    end
  end
end
```

**3.2: Reporting Dashboard**

```ruby
# app/controllers/admin/strategy_insights_controller.rb
module Admin
  class StrategyInsightsController < AdminController
    def show
      @persona = Persona.find(params[:persona_id])
      @analyzer = ContentStrategy::PerformanceAnalyzer.new(@persona)
      
      @kpis = @analyzer.calculate_kpis(period: 30.days)
      @time_analysis = @analyzer.analyze_optimal_times
      @format_analysis = @analyzer.analyze_format_effectiveness
      @frequency_analysis = @analyzer.analyze_posting_frequency
    end
  end
end
```

**3.3: Monthly Report Generator**

```ruby
# app/services/content_strategy/monthly_report_generator.rb
module ContentStrategy
  class MonthlyReportGenerator
    def generate(persona, month)
      insights = persona.insights.where(
        posted_at: month.beginning_of_month..month.end_of_month
      )
      
      analyzer = PerformanceAnalyzer.new(persona)
      
      {
        period: "#{month.strftime('%B %Y')}",
        summary: {
          posts_published: insights.count,
          total_reach: insights.sum(:reach),
          avg_engagement_rate: insights.average(:engagement_rate),
          follower_growth: calculate_follower_growth(persona, month)
        },
        top_performers: insights.order(engagement_rate: :desc).limit(5),
        recommendations: [
          analyzer.analyze_optimal_times[:recommendation],
          analyzer.analyze_format_effectiveness[:recommendation],
          analyzer.analyze_posting_frequency[:recommendation]
        ].compact
      }
    end
  end
end
```

### Deliverables
- [ ] `PerformanceAnalyzer` with time, format, frequency analysis
- [ ] Admin dashboard showing insights
- [ ] Monthly report generator
- [ ] Visualization helpers (charts for best times, format comparison)

### Success Criteria
- Can identify best posting hours for Sarah (should show Wed-Fri 9-12pm)
- Can detect oversaturation (should flag 7.4 posts/week as high)
- Monthly report generates actionable recommendations
- Dashboard loads in <2 seconds

---

## Phase 4: Auto-Tuning Engine (Week 7-8)

### Objective
Automatically adjust strategy configurations based on performance data.

### Technical Implementation

**4.1: Auto-Tuner Service**

```ruby
# app/services/content_strategy/auto_tuner.rb
module ContentStrategy
  class AutoTuner
    CONFIDENCE_THRESHOLD = 15  # Minimum posts needed for tuning
    
    def initialize(persona)
      @persona = persona
      @analyzer = PerformanceAnalyzer.new(persona)
      @current_config = load_current_config
    end
    
    def suggest_tuning
      return { tunable: false, reason: "Insufficient data" } unless tunable?
      
      suggestions = []
      
      # Timing optimization
      time_suggestion = suggest_timing_adjustment
      suggestions << time_suggestion if time_suggestion
      
      # Frequency optimization
      freq_suggestion = suggest_frequency_adjustment
      suggestions << freq_suggestion if freq_suggestion
      
      # Format optimization
      format_suggestion = suggest_format_adjustment
      suggestions << format_suggestion if format_suggestion
      
      {
        tunable: suggestions.any?,
        suggestions: suggestions,
        confidence: calculate_confidence_score
      }
    end
    
    def apply_tuning!(suggestions)
      suggestions.each do |suggestion|
        apply_suggestion(suggestion)
      end
      
      log_tuning_event(suggestions)
    end
    
    private
    
    def suggest_timing_adjustment
      analysis = @analyzer.analyze_optimal_times
      best_hours = analysis[:best_hours].keys.first(3)
      current_start = @current_config.optimal_time_start_hour
      current_end = @current_config.optimal_time_end_hour
      
      # If best hours are significantly different from config
      if !best_hours.all? { |h| (current_start..current_end).include?(h) }
        new_start = best_hours.min
        new_end = best_hours.max + 1
        
        {
          type: :timing,
          current: { start: current_start, end: current_end },
          suggested: { start: new_start, end: new_end },
          reason: "Actual best times: #{best_hours.join(', ')} differ from config: #{current_start}-#{current_end}",
          impact_estimate: "+20-30% reach",
          confidence: :high
        }
      end
    end
    
    def suggest_frequency_adjustment
      analysis = @analyzer.analyze_posting_frequency
      
      # Check for oversaturation signal
      if analysis[:correlation] < -0.3  # Negative correlation: more posts = less engagement
        current_freq = @current_config.posting_frequency_max
        suggested_freq = [current_freq - 1, 3].max
        
        {
          type: :frequency,
          current: current_freq,
          suggested: suggested_freq,
          reason: "Negative correlation detected: oversaturation",
          impact_estimate: "+30-50% engagement per post",
          confidence: :medium
        }
      end
    end
    
    def suggest_format_adjustment
      analysis = @analyzer.analyze_format_effectiveness
      formats = analysis[:by_format]
      
      reels = formats.find { |f| f.content_format == "reel" }
      carousels = formats.find { |f| f.content_format == "carousel" }
      
      if reels && carousels
        if reels.avg_nf_reach > carousels.avg_nf_reach * 1.5
          # Reels significantly outperform for reach
          {
            type: :format,
            current: { prefer_reels: @current_config.format_prefer_reels },
            suggested: { prefer_reels: true },
            reason: "Reels showing 50%+ higher non-follower reach",
            impact_estimate: "+40-60% discovery",
            confidence: :high
          }
        end
      end
    end
    
    def tunable?
      @persona.insights.recent.count >= CONFIDENCE_THRESHOLD
    end
    
    def calculate_confidence_score
      post_count = @persona.insights.recent.count
      weeks_active = @persona.insights.recent.maximum(:posted_at).to_date.weeks_since(
        @persona.insights.recent.minimum(:posted_at).to_date
      )
      
      # Higher confidence with more posts over longer time
      [(post_count / 10.0 * 0.6 + weeks_active / 8.0 * 0.4), 1.0].min
    end
  end
end
```

**4.2: Tuning Audit Trail**

```ruby
# db/migrate/XXXXXX_create_strategy_tuning_events.rb
create_table :content_strategy_tuning_events do |t|
  t.references :persona, null: false, foreign_key: true
  t.string :tuning_type, null: false  # timing, frequency, format
  t.jsonb :old_config, default: {}
  t.jsonb :new_config, default: {}
  t.text :reason
  t.decimal :confidence_score, precision: 3, scale: 2
  t.string :applied_by  # "auto" or user ID
  t.timestamps
end
```

**4.3: User Review Interface**

```ruby
# app/controllers/admin/strategy_tunings_controller.rb
module Admin
  class StrategyTuningsController < AdminController
    def review
      @persona = Persona.find(params[:persona_id])
      @tuner = ContentStrategy::AutoTuner.new(@persona)
      @suggestions = @tuner.suggest_tuning
    end
    
    def apply
      @persona = Persona.find(params[:persona_id])
      @tuner = ContentStrategy::AutoTuner.new(@persona)
      
      suggestions = params[:suggestions]
      @tuner.apply_tuning!(suggestions)
      
      redirect_to admin_persona_insights_path(@persona),
        notice: "Strategy tuned successfully"
    end
  end
end
```

### Deliverables
- [ ] `AutoTuner` service with suggestion generation
- [ ] `strategy_tuning_events` audit table
- [ ] Admin review interface for approving suggestions
- [ ] Automatic monthly tuning job (with manual approval)

### Success Criteria
- Auto-tuner correctly identifies Sarah's timing misalignment
- Suggests reducing frequency from 7.4 to 4 posts/week
- Suggests enabling Reels preference
- All suggestions have clear rationale and impact estimates
- Tuning events are logged for audit

---

## Phase 5: A/B Testing Framework (Future Enhancement)

### Objective
Systematically test strategy variations to validate optimizations.

### High-Level Design

**A/B Test Structure**:
```ruby
{
  test_name: "posting_time_optimization",
  persona_id: 1,
  variant_a: { optimal_time_start_hour: 5, optimal_time_end_hour: 8 },
  variant_b: { optimal_time_start_hour: 9, optimal_time_end_hour: 12 },
  duration_weeks: 2,
  metric: "avg_engagement_rate",
  status: "running"
}
```

**Test Execution**:
- Alternate variants week-by-week (A/B/A/B pattern)
- Collect insights separately for each variant
- Calculate statistical significance
- Declare winner and apply permanently

**Implementation**: Future milestone after auto-tuning is proven

---

## Success Metrics & KPIs

### Phase 1 (API Integration)
- ✅ Authenticate at least 1 persona's Instagram account
- ✅ Successfully pull insights for 10+ posts
- ✅ Handle API errors without crashes

### Phase 2 (Data Collection)
- ✅ Store insights for 100+ posts across all personas
- ✅ Daily job runs successfully for 7 consecutive days
- ✅ Zero data loss or duplicates

### Phase 3 (Analysis)
- ✅ Dashboard loads in <2 seconds
- ✅ Analysis correctly identifies Sarah's Wed-Fri 9-12pm pattern
- ✅ Monthly report generates actionable recommendations

### Phase 4 (Auto-Tuning)
- ✅ Auto-tuner generates 3+ valid suggestions for Sarah
- ✅ Suggestions improve metrics by 20%+ when applied
- ✅ 100% of tuning events logged in audit trail

---

## Integration with Existing System

### Touchpoints

**1. Scheduling Pipeline** (`Scheduling::SchedulePost`):
- After post is published, store `instagram_media_id`
- After 24-48 hours, trigger insights collection
- Use insights to refine future scheduling decisions

**2. Strategy State** (`ContentStrategy::StrategyState`):
- Read config for auto-tuning
- Update config when tuning applied
- Store tuning metadata in state_data

**3. Admin Interface**:
- New "Performance" tab in persona management
- Monthly email with insights summary
- Manual tuning approval workflow

---

## Rollout Plan

### Week 1-2: Foundation
- Set up Instagram API client
- Test with Sarah's account
- Collect first batch of insights

### Week 3-4: Data Layer
- Deploy insights storage schema
- Implement collection job
- Backfill October data manually

### Week 5-6: Intelligence
- Build performance analyzer
- Create dashboard
- Generate first monthly report

### Week 7-8: Automation
- Implement auto-tuner
- Test suggestions on Sarah
- Deploy to production with manual approval

### Week 9+: Optimization
- Monitor auto-tuning results
- Refine suggestion algorithms
- Plan A/B testing framework

---

## Risk Mitigation

### Risk 1: Instagram API Rate Limits
**Mitigation**: 
- Cache responses for 24 hours
- Batch requests efficiently
- Implement exponential backoff

### Risk 2: Token Expiration
**Mitigation**:
- Auto-refresh tokens every 30 days
- Alert admin 7 days before expiration
- Graceful degradation if token invalid

### Risk 3: Insufficient Data for Tuning
**Mitigation**:
- Require minimum 15 posts before tuning
- Show confidence scores with suggestions
- Allow manual override with warnings

### Risk 4: Bad Auto-Tuning Suggestions
**Mitigation**:
- All suggestions require manual approval initially
- A/B test major changes
- Allow rollback within 48 hours
- Audit trail for all tuning events

---

## Future Enhancements (Beyond Phase 4)

### Machine Learning Integration
- Train ML model on historical insights
- Predict post performance before publishing
- Recommend best cluster/format combinations

### Cross-Persona Learning
- Aggregate insights across similar personas
- Transfer learnings between accounts
- Build industry-specific benchmarks

### Real-Time Optimization
- Monitor post performance in first hour
- Suggest caption edits or story shares to boost
- Alert for unusually high/low engagement

### Competitive Analysis
- Track competitor posting patterns
- Identify content gaps
- Benchmark performance vs niche average

---

## Conclusion

This feedback loop closes the gap between **research-based strategy** and **real-world performance**. By systematically collecting Instagram insights, analyzing patterns, and auto-tuning configurations, we enable each persona to evolve toward their optimal strategy.

**Key Benefits**:
1. **Data-Driven**: Decisions based on actual performance, not assumptions
2. **Persona-Specific**: Each account optimizes for its unique audience
3. **Automated**: Reduces manual configuration by 80%
4. **Transparent**: Full audit trail and confidence scores
5. **Continuous Improvement**: System learns and adapts over time

**Next Step**: Begin Phase 1 (Instagram API Integration) after Sarah's short-term optimizations are validated in November.

---

**Document Status**: Ready for Review  
**Estimated Effort**: 6-8 weeks (1 developer)  
**Dependencies**: Sarah's Instagram Business account, Facebook Page, API access  
**Blocker**: None - can start immediately
