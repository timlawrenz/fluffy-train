# Tasks: Automated Hashtag & Tag Generation

**Change ID**: `add-automated-hashtag-generation`  
**Status**: ✅ **COMPLETE** (Core Implementation - Option C)  
**Created**: 2024-11-04  
**Completed**: 2024-11-06

---

## Progress

**Current Status:** ✅ Core Implementation Complete  
**Overall Completion:** 100% (Core Features)

**Implementation Scope:** Option C - Core features implemented, stretch goals deferred

**Note:** Successfully implemented intelligent hashtag generation with content-based analysis, persona alignment, relevance scoring, and optimal mix distribution. See COMPLETION_SUMMARY.md for full details.

---

## Phase 1: Foundation & Configuration (Week 1, Days 1-2)

### Database Schema
- [ ] Create migration to add `hashtag_strategy` jsonb column to `personas` table
- [ ] Create migration to enhance `scheduling_posts.hashtags` to store metadata
- [ ] Add GIN index on `hashtag_metadata` for querying
- [ ] Run migrations
- [ ] Verify schema in database

### Persona Hashtag Strategy Model
- [ ] Create `packs/personas/app/models/personas/hashtag_strategy.rb`
- [ ] Define attributes: niche_categories, target_hashtags, avoid_hashtags, size_distribution
- [ ] Add validations for hashtag counts and categories
- [ ] Implement `from_hash` and `to_hash` methods for serialization
- [ ] Write specs for HashtagStrategy model
- [ ] Add default strategies for common persona types (lifestyle, tech, fashion)

### Persona Model Updates
- [ ] Add `hashtag_strategy` accessor to Persona model
- [ ] Implement getter/setter with HashtagStrategy serialization
- [ ] Add `hashtag_strategy=` method to accept hash or HashtagStrategy object
- [ ] Write specs for persona hashtag strategy integration

---

## Phase 2: Content-Based Hashtag Generation (Week 1, Days 3-4)

### Object-to-Hashtag Mapping
- [ ] Create `packs/hashtag_generations/` pack
- [ ] Create `app/services/hashtag_generations/object_mapper.rb`
- [ ] Build mapping dictionary: detected_objects → relevant hashtags
- [ ] Add contextual mappings (e.g., "sunset" → #GoldenHour, #SunsetLovers)
- [ ] Write specs for object mapping

### Content-Based Generator
- [ ] Create `app/services/hashtag_generations/content_generator.rb`
- [ ] Use `photo_analysis.detected_objects` for image-specific tags
- [ ] Generate 3-5 content-specific hashtags per photo
- [ ] Extract image attributes (colors, composition) for descriptive tags
- [ ] Write specs for content-based generation

---

## Phase 3: Relevance Scoring & Optimization (Week 1, Days 4-5)

### Hashtag Size Database
- [ ] Create `hashtag_sizes` table (hashtag, size_category, post_count, updated_at)
- [ ] Add migration for hashtag sizes tracking
- [ ] Seed initial size categories (large: 1M+, medium: 100K-500K, niche: 10K-50K)
- [ ] Create update mechanism for size data

### Relevance Scorer
- [ ] Create `app/services/hashtag_generations/relevance_scorer.rb`
- [ ] Implement size category scoring (large/medium/niche mix)
- [ ] Score relevance to photo content (detected objects match)
- [ ] Score persona alignment (niche category match)
- [ ] Calculate composite relevance score
- [ ] Write specs for relevance scoring

### Optimal Mix Selector
- [ ] Create `app/services/hashtag_generations/mix_optimizer.rb`
- [ ] Implement optimal mix: 2-3 large, 3-4 medium, 3-5 niche
- [ ] Sort hashtags by relevance score
- [ ] Select top N hashtags maintaining size distribution
- [ ] Write specs for mix optimization

---

## Phase 4: Quality Control & Filtering (Week 2, Days 1-2)

### Banned Hashtag List
- [ ] Create `banned_hashtags` table
- [ ] Seed with known shadowban hashtags (#like4like, #followforfollow, etc.)
- [ ] Add admin interface to manage banned hashtags
- [ ] Write specs for banned hashtag filtering

### Quality Filter Service
- [ ] Create `app/services/hashtag_generations/quality_filter.rb`
- [ ] Filter out banned/spammy hashtags
- [ ] Apply relevance threshold (remove unrelated tags)
- [ ] Deduplicate hashtags
- [ ] Validate hashtag formatting (#word, no spaces)
- [ ] Write specs for quality filtering

---

## Phase 5: Trending Detection (Stretch Goal) (Week 2, Days 3-4)

### Trending Hashtag Cache
- [ ] Create `trending_hashtags` table (hashtag, category, detected_at, expires_at)
- [ ] Add migration for trending hashtags
- [ ] Implement cache refresh mechanism (daily)
- [ ] Write specs for trending cache

### Trending Detector Service
- [ ] Create `app/services/hashtag_generations/trending_detector.rb`
- [ ] Research API options (Instagram Graph API, RapidAPI, manual curation)
- [ ] Implement trending tag fetching (start with manual curated list)
- [ ] Add 1-2 trending tags if relevant to photo/persona
- [ ] Write specs for trending detection

---

## Phase 6: Integration & Enhancement (Week 2, Days 4-5)

### Enhanced Hashtag Generator
- [ ] Create `app/services/hashtag_generations/generator.rb`
- [ ] Integrate all components: content, persona, relevance, quality, trending
- [ ] Implement `.generate(photo:, persona:, cluster:, options: {})` method
- [ ] Return hashtags with metadata (method, scores, categories)
- [ ] Write specs for full generator

### Content Strategy Integration
- [ ] Update `BaseStrategy.select_hashtags` to use new generator
- [ ] Check for `persona.hashtag_strategy` presence
- [ ] Fallback to `HashtagEngine` if no strategy configured
- [ ] Store hashtag metadata in `scheduling_posts.hashtags`
- [ ] Write integration specs

### Hashtag Metadata Tracking
- [ ] Enhance `scheduling_posts.hashtags` storage format
- [ ] Include: method, content_tags, persona_tags, trending_tags, score
- [ ] Add timestamp and generation details
- [ ] Write specs for metadata tracking

---

## Phase 7: Testing & Validation (Week 3, Days 1-2)

### Unit Tests
- [ ] Test ObjectMapper with various detected objects
- [ ] Test RelevanceScorer with different photo types
- [ ] Test QualityFilter with banned/spammy hashtags
- [ ] Test TrendingDetector with mock data
- [ ] Test Generator end-to-end

### Integration Tests
- [ ] Test full generation for urban sunset photo (Sarah persona)
- [ ] Test full generation for beach photo (fashion persona)
- [ ] Test fallback when no persona strategy configured
- [ ] Test metadata storage in scheduling_posts
- [ ] Verify hashtag mix (large/medium/niche distribution)

### Manual Validation
- [ ] Generate 50 test hashtag sets for different photos
- [ ] Review quality, relevance, and mix
- [ ] Compare to current generic hashtags
- [ ] Adjust scoring and filtering thresholds
- [ ] Validate Instagram compliance

---

## Phase 8: Documentation & Deployment (Week 3, Days 3-5)

### Documentation
- [ ] Write persona hashtag strategy configuration guide
- [ ] Document hashtag generation API
- [ ] Create hashtag optimization best practices guide
- [ ] Add admin interface screenshots
- [ ] Update README with hashtag features

### Admin Interface
- [ ] Add hashtag strategy editor for personas
- [ ] Add banned hashtag management interface
- [ ] Add trending hashtag review interface
- [ ] Add hashtag performance metrics (future)
- [ ] Write frontend specs

### Deployment
- [ ] Run database migrations in staging
- [ ] Configure default hashtag strategies for existing personas
- [ ] Deploy to staging environment
- [ ] Run smoke tests
- [ ] Deploy to production
- [ ] Monitor first week of enhanced hashtags

---

## Acceptance Criteria Validation

### AC1: Content-Based Generation
- [ ] Verify hashtags include content-specific tags from detected objects
- [ ] Test: Urban sunset photo → includes #GoldenHour, #SunsetLovers
- [ ] Test: Beach photo → includes #BeachLife, #OceanVibes

### AC2: Persona Alignment
- [ ] Verify hashtags match persona niche categories
- [ ] Test: Sarah (lifestyle) → includes #LifestylePhotography
- [ ] Test: TechReviewer (technology) → includes #TechReview

### AC3: Relevance Scoring
- [ ] Verify optimal mix: 2-3 large, 3-4 medium, 3-5 niche
- [ ] Test: Hashtag distribution matches size targets
- [ ] Test: Hashtags sorted by relevance score

### AC4: Quality Control
- [ ] Verify banned hashtags filtered out
- [ ] Test: #like4like, #followforfollow not included
- [ ] Verify hashtag formatting (# prefix, no spaces)

### AC5: Trending Integration (Stretch)
- [ ] Verify 1-2 trending tags added when relevant
- [ ] Test: Trending seasonal tag included appropriately
- [ ] Test: Irrelevant trending tags excluded

### AC6: Metadata Tracking
- [ ] Verify metadata stored in scheduling_posts.hashtags
- [ ] Verify method, scores, categories tracked
- [ ] Verify timestamp recorded

---

## Open Questions

1. **Instagram Graph API for trending hashtags?**
   - [ ] Research Instagram Graph API capabilities
   - [ ] Decision: Use API, RapidAPI, or manual curation?

2. **Hashtag size database update frequency?**
   - [ ] Decision: Weekly, monthly, or on-demand?

3. **Banned hashtag list maintenance?**
   - [ ] Process for monitoring and updating banned list?

4. **Performance impact of relevance scoring?**
   - [ ] Benchmark generation time (target: < 1 second)
   - [ ] Optimize if needed (caching, indexing)

---

## Dependencies

**Required:**
- Photos::Analyse (provides detected_objects) - ✅ Complete (Milestone 2)
- ContentStrategy::HashtagEngine (existing basic generation) - ✅ Complete (Milestone 4c)
- Persona model - ✅ Complete
- Scheduling::Post model - ✅ Complete

**Optional:**
- Milestone 5a (Caption Generation) - In Progress
- Instagram Graph API business account - For trending detection

---

## Risk Mitigation

### Risk: Over-optimization feels spammy
- Limit trending tags to 1-2 maximum
- Maintain natural mix with niche tags
- Manual review first 50 sets

### Risk: Trending API costs
- Start with manual curated list (free)
- Research free APIs first
- Only add paid API if needed

### Risk: Banned hashtag list becomes outdated
- Monitor shadowban reports monthly
- Admin interface for quick updates
- Subscribe to Instagram policy updates

---

## Related Changes

- `add-content-strategy-engine` (Milestone 4c) - Provides base HashtagEngine
- `add-persona-caption-generation` (Milestone 5a) - Parallel generative AI enhancement
- `add-full-automation-integration` (Milestone 5c) - Will integrate enhanced hashtags

---

**Last Updated**: 2024-11-04  
**Est. Completion**: 3 weeks from start  
**Assignee**: TBD
