# Research Proposal: Content Strategy Engine (Milestone 4c)

## Why

Milestone 4c represents a critical integration point that bridges cluster-based image organization with automated content distribution. However, we currently lack the **domain knowledge** to build a content strategy system that understands what makes Instagram content successful. 

Simply selecting images from clusters isn't enough - we need to understand:
- **Instagram platform best practices**: Optimal posting times, frequency, content formats
- **Engagement patterns**: What drives likes, comments, shares, and saves
- **Content strategy frameworks**: How professional creators and brands approach content planning
- **Algorithmic considerations**: How Instagram's algorithm prioritizes content
- **Audience behavior**: When and how users consume content

Additionally, we need to design the technical architecture to encode this knowledge and make it actionable.

This research phase will explore:
1. **Instagram Domain Knowledge** (NEW - primary focus)
2. Strategy pattern design and extensibility
3. State management for multi-day strategies
4. Integration points with existing systems

## Research Questions

### 1. Instagram Platform Knowledge (CRITICAL - New Section)

**Posting Timing & Frequency:**
- What are optimal posting times for Instagram? (By day of week, time of day)
- How does timing vary by audience demographics/location?
- What posting frequency maximizes engagement without oversaturation?
- Should we avoid posting during "high competition" windows?

**Content Format Best Practices:**
- Static posts vs. Carousels vs. Reels: engagement differences?
- Image aspect ratios: Square (1:1) vs. Portrait (4:5) vs. other - what performs best?
- Does the Instagram algorithm favor certain content types?
- How do format preferences change over time?

**Hashtag & Caption Strategy:**
- How many hashtags is optimal? (Instagram allows 30, but what's effective?)
- Hashtag placement: in caption vs. first comment?
- Hashtag types: niche vs. broad, branded vs. trending
- Caption length and style impact on engagement
- Call-to-action patterns that drive engagement

**Engagement & Algorithm:**
- What signals does Instagram's algorithm prioritize? (Saves, shares, comments, time spent)
- How quickly after posting do you need engagement?
- Does consistent posting time train audience behavior?
- How does the algorithm handle accounts posting the same type of content repeatedly?

**Content Strategy Frameworks:**
- What are proven content strategy approaches? (80/20 rule, thematic weeks, storytelling arcs)
- How do successful creators balance consistency vs. variety?
- What is "content pillars" strategy and how to implement it?
- Theme-based posting: best practices for sustaining a theme over days/weeks

**Audience Behavior Patterns:**
- When is your audience most active? (Research tools/methods to determine this)
- How to analyze Instagram Insights for strategy optimization
- Do different content themes attract different audience segments?

### 2. Strategy Knowledge Encoding

**How do we make domain knowledge actionable?**
- Should strategies be rule-based or learning-based?
- How configurable should timing/format preferences be?
- Can we encode "posting windows" and "content variety rules"?
- Should the system support A/B testing different strategies?

**Strategy Parameterization:**
- What knobs should users control? (posting time, frequency, format mix)
- What should be automatic/algorithm-driven?
- How do we encode constraints? (e.g., "no more than 2 similar themes per week")

### 3. Architecture & Design Patterns
- **How should strategies be implemented?** (Plugin-based, class inheritance, functional composition)
- **How do strategies consume domain knowledge?** (Configuration files, database, hardcoded rules)
- **What interface contract do all strategies need?** (Common methods, configuration format)
- **Where does strategy configuration live?** (Database, YAML, environment variables)

### 4. State Management
- **How do we track multi-day strategy state?** (e.g., "Theme of the Week" needs to remember which cluster for 7 days)
- **How do we track posting history for variety?** (Avoid posting similar content too frequently)
- **What happens on strategy switches?** (Mid-week changes, rollback scenarios)
- **How do we handle edge cases?** (Running out of images in a cluster, cluster deletion mid-strategy)

### 5. Cluster Selection Logic
- **"Theme of the Week": How does a user select a cluster?** (CLI parameter, web UI, configuration file)
- **"Thematic Rotation": What's the rotation order?** (Alphabetical, creation order, random, weighted by size)
- **Should rotation respect "variety rules"?** (Don't repeat similar themes too close together)
- **How do we handle empty or exhausted clusters?**

### 6. Integration with Existing Systems
- **Milestone 3 scheduler touchpoints**: Where does strategy execution hook into the posting pipeline?
- **Milestone 4a/4b cluster data**: What queries do strategies need? (List clusters, get unposted images from cluster)
- **Posting history**: How do strategies query what's been posted and mark images as used?
- **Instagram API**: Can we retrieve optimal posting times from Instagram Insights?

### 7. Observability & Debugging
- **What should be logged?** (Strategy selection, cluster chosen, decision reasoning, timing choices)
- **How do we audit strategy behavior over time?**
- **What metrics matter?** (Images posted per cluster, strategy switches, failures, engagement per strategy)

## Research Activities

### Phase 1: Instagram Domain Knowledge Research (Estimated 4-6 hours) **NEW**

- [ ] **1.1 Literature review on Instagram best practices**
  - [ ] 1.1.1 Research optimal posting times studies (2024-2025 data)
  - [ ] 1.1.2 Review Instagram algorithm documentation/updates
  - [ ] 1.1.3 Study hashtag strategy research (current best practices)
  - [ ] 1.1.4 Review content format performance data (Reels vs static posts)
  
- [ ] **1.2 Content strategy framework research**
  - [ ] 1.2.1 Study professional creator content calendars
  - [ ] 1.2.2 Research "content pillars" methodology
  - [ ] 1.2.3 Review thematic content planning approaches
  - [ ] 1.2.4 Analyze consistency vs. variety balancing techniques
  
- [ ] **1.3 Engagement pattern analysis**
  - [ ] 1.3.1 Research Instagram Insights interpretation
  - [ ] 1.3.2 Study "golden hour" posting (first hour engagement importance)
  - [ ] 1.3.3 Review audience behavior patterns
  - [ ] 1.3.4 Analyze engagement metric priorities (saves > comments > likes)
  
- [ ] **1.4 Competitive analysis**
  - [ ] 1.4.1 Analyze 5-10 successful accounts in similar niches
  - [ ] 1.4.2 Document their posting frequency and timing patterns
  - [ ] 1.4.3 Note their content variety and thematic approaches
  - [ ] 1.4.4 Identify common patterns and best practices

- [ ] **1.5 Create domain knowledge synthesis document**
  - [ ] 1.5.1 Summarize key findings and recommendations
  - [ ] 1.5.2 Identify "rules" that should be encoded in strategies
  - [ ] 1.5.3 Note areas of uncertainty requiring A/B testing
  - [ ] 1.5.4 Prioritize which practices to implement first

### Phase 2: Strategy Knowledge Encoding (Estimated 3-4 hours) **NEW**

- [ ] **2.1 Define strategy configuration schema**
  - [ ] 2.1.1 Design posting time windows configuration
  - [ ] 2.1.2 Design content variety rules (minimum days between similar themes)
  - [ ] 2.1.3 Design hashtag strategy parameters
  - [ ] 2.1.4 Design A/B testing support structure
  
- [ ] **2.2 Map domain knowledge to strategy implementations**
  - [ ] 2.2.1 "Theme of the Week": How does it respect variety rules?
  - [ ] 2.2.2 "Thematic Rotation": How does it optimize posting times?
  - [ ] 2.2.3 Both: How do they handle format optimization?
  - [ ] 2.2.4 Both: How do they select optimal hashtags?

### Phase 3: Discovery (Estimated 2-4 hours)
- [ ] 3.1 Review Milestone 3 implementation
  - [ ] 3.1.1 Document scheduler architecture and entry points
  - [ ] 3.1.2 Identify posting pipeline flow and hooks
  - [ ] 3.1.3 Review posting history logging mechanism
  
- [ ] 3.2 Review Milestone 4a/4b implementation
  - [ ] 3.2.1 Document cluster data model and schema
  - [ ] 3.2.2 Identify available queries (list clusters, get images)
  - [ ] 3.2.3 Understand cluster naming and metadata structure
  
- [ ] 3.3 Research strategy pattern implementations
  - [ ] 3.3.1 Survey Ruby/Rails plugin patterns (5-10 examples)
  - [ ] 3.3.2 Review ActiveJob adapter pattern
  - [ ] 3.3.3 Examine OmniAuth provider pattern
  - [ ] 3.3.4 Document pros/cons of each approach
  
- [ ] 3.4 Create system context diagram
  - [ ] 3.4.1 Map data flows between Milestones 3, 4a, 4b, and 4c
  - [ ] 3.4.2 Identify all integration touchpoints
  - [ ] 3.4.3 Document current system constraints

### Phase 4: Design Exploration (Estimated 3-5 hours)

- [ ] 4.1 Architect strategy pattern options
  - [ ] 4.1.1 Design Option A: Plugin-based (Rails engine/gem pattern)
  - [ ] 4.1.2 Design Option B: Class inheritance (Strategy base class)
  - [ ] 4.1.3 Design Option C: Functional composition (modules/concerns)
  - [ ] 4.1.4 Create comparison matrix with trade-offs
  
- [ ] 4.2 Prototype basic strategy interface
  - [ ] 4.2.1 Write minimal BaseStrategy or Strategy module
  - [ ] 4.2.2 Implement stub ThemeOfWeekStrategy (with timing + variety logic)
  - [ ] 4.2.3 Implement stub ThematicRotationStrategy (with timing + variety logic)
  - [ ] 4.2.4 Validate interface handles domain knowledge requirements
  
- [ ] 4.3 Design state management
  - [ ] 4.3.1 Define required state fields (active_strategy, current_cluster, day_count, last_themes, etc.)
  - [ ] 4.3.2 Choose storage mechanism (DB table, Redis, config file)
  - [ ] 4.3.3 Design state transition logic
  - [ ] 4.3.4 Create state machine diagram
  
- [ ] 4.4 Map error scenarios and edge cases
  - [ ] 4.4.1 Document: Strategy runs out of images in cluster
  - [ ] 4.4.2 Document: Cluster deleted mid-strategy
  - [ ] 4.4.3 Document: User switches strategy mid-execution
  - [ ] 4.4.4 Document: No clusters available for rotation
  - [ ] 4.4.5 Design fallback and recovery mechanisms

### Phase 5: Technical Specification (Estimated 2-3 hours)

- [ ] 5.1 Define strategy API contract
  - [ ] 5.1.1 Document required methods (e.g., select_image, get_optimal_posting_time, select_hashtags)
  - [ ] 5.1.2 Define configuration format (YAML schema or Ruby DSL) with domain knowledge
  - [ ] 5.1.3 Specify return types and error handling
  - [ ] 5.1.4 Document lifecycle hooks (before_post, after_post)
  
- [ ] 5.2 Create data model specification
  - [ ] 5.2.1 Design strategy_state table schema (if DB-based)
  - [ ] 5.2.2 Design strategy_history/audit log schema
  - [ ] 5.2.3 Design posting_time_windows configuration structure
  - [ ] 5.2.4 Define indexes and constraints
  - [ ] 5.2.5 Document migration plan
  
- [ ] 5.3 Write integration guide
  - [ ] 5.3.1 Document how scheduler calls strategy (including time optimization)
  - [ ] 5.3.2 Specify cluster query interface needed
  - [ ] 5.3.3 Define posting history update contract
  - [ ] 5.3.4 Create integration test scenarios
  
- [ ] 5.4 Create sequence diagrams
  - [ ] 5.4.1 "Theme of the Week" full execution flow (with timing logic)
  - [ ] 5.4.2 "Thematic Rotation" full execution flow (with variety checking)
  - [ ] 5.4.3 Strategy switch scenario
  - [ ] 5.4.4 Error recovery scenario
  
- [ ] 5.5 Draft acceptance criteria
  - [ ] 5.5.1 Define testable criteria for "Theme of the Week"
  - [ ] 5.5.2 Define testable criteria for "Thematic Rotation"
  - [ ] 5.5.3 Define domain knowledge validation criteria (posts at optimal times, respects variety)
  - [ ] 5.5.4 Define edge case validation criteria
  - [ ] 5.5.5 Define observability requirements

## Expected Deliverables

1. **Instagram Domain Knowledge Document** (NEW - Primary Deliverable)
   - Optimal posting times and frequency recommendations
   - Content format best practices (aspect ratios, types)
   - Hashtag strategy guidelines
   - Engagement optimization techniques
   - Content variety rules and constraints
   - Sources and references for all findings

2. **Strategy Configuration Schema** (NEW)
   - Posting time window definitions
   - Content variety rule encoding
   - Hashtag selection parameters
   - A/B testing framework

3. **Architecture Decision Record (ADR)**
   - Chosen pattern with rationale
   - How strategies consume domain knowledge
   - Comparison of alternatives considered
   - Trade-offs and limitations

4. **Technical Specification Document**
   - Strategy interface definition (including domain knowledge methods)
   - State management schema
   - Integration guide with existing milestones
   - Error handling patterns

5. **Implementation Plan**
   - Breakdown of tasks.md for actual implementation
   - Estimated effort per task
   - Dependencies and risks
   - Phasing: MVP (basic timing) vs. advanced (full optimization)

6. **Prototype/POC Code** (Optional)
   - Minimal working example of strategy pattern
   - Mock integration showing timing optimization
   - Demonstration of both strategies with domain knowledge

## Success Criteria

This research phase is complete when:
- [x] Instagram domain knowledge is documented with actionable recommendations and sources
- [x] Key content strategy rules are identified and can be encoded (posting times, variety, frequency)
- [x] We have a clear, documented architecture decision for strategy implementation
- [x] Strategy configuration schema supports domain knowledge parameters
- [x] State management approach handles multi-day strategies and posting history
- [x] Integration points with Milestones 3, 4a, 4b are mapped and documented
- [x] Both "Theme of the Week" and "Thematic Rotation" strategies have detailed sequence diagrams showing how they apply domain knowledge
- [x] Edge cases and error scenarios are identified and have resolution plans
- [x] A detailed implementation plan (tasks.md) can be created from the research findings
- [x] We can articulate how the system will "know about content strategy" beyond just theme selection

**✅ ALL SUCCESS CRITERIA MET**

## Research Deliverables (Completed)

All research documentation has been moved to `docs/research/content-strategy-engine/`:

1. **Instagram Domain Knowledge Document** (`instagram-domain-knowledge.md` - 24KB)
   - Optimal posting times from analysis of 10M+ posts
   - Algorithm hierarchy and engagement signals
   - Format performance (Reels, Carousels, Static)
   - Posting frequency and variety rules
   - Hashtag strategy and caption best practices
   - Content pillar methodology (3-1-3-1 framework)
   - 30+ authoritative sources cited with confidence levels

2. **Architecture Design Document** (`architecture-design.md` - 28KB)
   - Complete technical specification
   - Class-based strategy pattern design
   - Database schema (2 new tables, column additions)
   - Full implementation of both strategies
   - State management (PostgreSQL + Redis)
   - Integration layer with scheduler and clusters
   - Error handling and observability
   - 4-week migration plan

3. **Research Summary** (`research-summary.md` - 12KB)
   - Executive summary of findings
   - Key insights and architectural decisions
   - Implementation readiness assessment
   - Risk mitigation strategies
   - Next steps and recommendations

## Timeline

**Estimated Duration**: 2-3 weeks (14-22 hours total research time)

**Phases**:
- Days 1-3: Phase 1 (Instagram Domain Knowledge Research) - **NEW, HIGH PRIORITY**
- Days 4-5: Phase 2 (Strategy Knowledge Encoding) - **NEW**
- Days 6-7: Phase 3 (Discovery - technical systems)
- Days 8-11: Phase 4 (Design Exploration)  
- Days 12-14: Phase 5 (Technical Specification)

**Note**: Instagram domain knowledge research is the critical path and highest priority.

## Impact

This research proposal does not implement features. It prepares for the implementation of Milestone 4c by answering open technical questions and creating a detailed specification.

**Affected components**:
- Automated posting scheduler (Milestone 3) - needs timing optimization
- Cluster management system (Milestone 4a/4b) - needs variety/history tracking
- Future capability: content-strategy (to be created) - will encode domain knowledge

**Risks if skipped**:
- System posts at suboptimal times, reducing engagement
- Content becomes repetitive or oversaturates audience
- No encoding of proven Instagram best practices
- Strategies that are technically correct but strategically naive
- Tightly coupled, inflexible implementation
- Difficulty adding new strategies or adapting to platform changes
- State management bugs in multi-day strategies
- Poor integration with existing systems requiring refactoring

**Key insight**: A content strategy engine without content strategy knowledge is just a randomizer with themes.

## Next Steps After Research

Once research is complete:
1. Review findings with stakeholders
2. Create implementation proposal: `add-content-strategy-engine`
3. Define specs with ADDED Requirements for new capability
4. Begin implementation following the detailed plan
