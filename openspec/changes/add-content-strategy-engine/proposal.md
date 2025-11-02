# Implementation Proposal: Content Strategy Engine

## Why

The research phase (research-content-strategy-engine) is complete. We now have comprehensive Instagram domain knowledge and a production-ready technical architecture. This proposal implements the Content Strategy Engine to intelligently select and schedule content using proven Instagram best practices.

**Problem:** Currently, content selection is manual or random. The system doesn't apply Instagram strategy knowledge about optimal posting times, content variety, or engagement patterns.

**Solution:** Implement a strategy engine that encodes Instagram best practices (optimal timing, variety enforcement, format optimization) as executable strategies, bridging cluster-based organization with intelligent automated distribution.

**Research Foundation:** 
- 170+ research tasks completed
- 64KB of research documentation in `docs/research/content-strategy-engine/`
- Data from 10M+ Instagram posts analyzed
- Architecture fully designed with 28KB technical specification

## What Changes

This proposal adds a new `content-strategy` capability implementing:

1. **Strategy Pattern Framework**
   - BaseStrategy class with common interface
   - Strategy registry for extensibility
   - Shared concerns: TimingOptimization, VarietyEnforcement, FormatOptimization

2. **Two Core Strategies**
   - ThemeOfWeekStrategy: Focus on one cluster for 7 days, respecting variety rules
   - ThematicRotationStrategy: Rotate through clusters, varying selection

3. **Domain Knowledge Integration**
   - Optimal posting time calculation (5-8am, 10am-3pm local time)
   - Content variety enforcement (2-3 day gap between similar themes)
   - Posting frequency control (3-5 posts/week)
   - Hashtag generation (5-12 relevant tags)
   - Format recommendations (Reels vs Carousels)

4. **State Management**
   - Database tables: `content_strategy_state`, `content_strategy_history`
   - Redis caching for performance (<10ms state queries)
   - Multi-day strategy state tracking

5. **Integration Layer**
   - SelectNextPost command chain
   - Integration with existing scheduler (Milestone 3)
   - Enhanced cluster queries (Milestone 4a/4b)
   - Posting history tracking

6. **Configuration System**
   - YAML-based configuration with sensible defaults
   - Per-persona strategy selection
   - Configurable timing windows, variety rules, hashtag counts

7. **Observability**
   - Structured logging for all strategy decisions
   - Metrics tracking (selection time, strategy usage, cluster rotation)
   - Audit trail in database

## Impact

**Affected Specs:**
- ADDED: `content-strategy` (new capability)
- MODIFIED: `scheduling` (integration with strategy engine)
- MODIFIED: `clustering` (enhanced queries for strategy selection)

**Affected Code:**
- New pack: `packs/content_strategy/`
- Modified: `packs/scheduling/` (integration points)
- Modified: `packs/clustering/` (new scopes and methods)
- New: Database migrations (2 tables, column additions)
- New: Configuration file `config/content_strategy.yml`

**Benefits:**
- Posts at optimal times based on millions of posts analyzed (2.25x reach potential)
- Prevents content fatigue with variety enforcement
- Applies proven Instagram strategies automatically
- Flexible and extensible for future strategies
- Full observability and control

**Risks:**
- Added complexity in posting pipeline (~200ms overhead)
- New state management requires monitoring
- Configuration required per persona
- **Mitigation:** Feature flag, fallback mechanisms, smart defaults, staged rollout

**Breaking Changes:** None - additive only with feature flag

## Timeline

**Estimated Duration:** 4 weeks to production-ready MVP

**Phase 1: Foundation (Week 1)**
- Database migrations
- BaseStrategy and Registry
- StrategyState and Context models
- Shared concerns (Timing, Variety, Format)
- Unit tests

**Phase 2: Core Strategies (Week 2)**
- ThemeOfWeekStrategy implementation
- ThematicRotationStrategy implementation
- Cluster integration (scopes, queries)
- PostingHistory service
- Strategy tests

**Phase 3: Integration (Week 3)**
- SelectNextPost command chain
- Scheduler integration with feature flag
- Configuration system
- Error handling and fallbacks
- Integration tests

**Phase 4: Observability & Polish (Week 4)**
- Logging and metrics
- Audit trail
- Documentation
- Performance testing
- End-to-end validation

**Deployment:** Staged rollout with feature flag per persona

## Success Metrics

**Performance:**
- Strategy selection < 100ms
- State queries < 10ms (cached)
- Total overhead < 200ms per post

**Behavior:**
- 90%+ of posts at optimal times (5-8am or 10am-3pm)
- Zero theme repeats within configured gap (default 3 days)
- Posting frequency maintained (3-5 posts/week)
- Variety score > 0.7 over 14-day window

**Quality:**
- All tests passing (unit, integration, E2E)
- Zero production errors for 1 week
- Audit trail captures all decisions
- Feature flag enables safe rollout

## References

**Research Documentation:**
- `docs/research/content-strategy-engine/instagram-domain-knowledge.md` (24KB)
- `docs/research/content-strategy-engine/architecture-design.md` (28KB)
- `docs/research/content-strategy-engine/research-summary.md` (12KB)

**Research Proposal:**
- `openspec/changes/research-content-strategy-engine/`

**Key Findings:**
- Optimal times: 5-8am, 10am-3pm (Tue-Thu strongest) - from analysis of 10M+ posts
- Algorithm: Saves > Shares > Comments > Likes
- Formats: Reels (2.25x reach), Carousels (1.38-10% engagement)
- Frequency: 3-5 posts/week optimal
- Hashtags: 5-12 relevant tags
- Variety: 2-3 day gap between similar themes
