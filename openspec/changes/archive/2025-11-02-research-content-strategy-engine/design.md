# Design Considerations: Content Strategy Engine Research

## Context

This design document outlines the key technical considerations and decision points for the Content Strategy Engine research phase. The goal is to explore architecture options and make informed decisions before implementation begins.

## Goals

- Define a clear, extensible strategy pattern for content selection
- Design state management that supports multi-day strategies
- Ensure clean integration with existing Milestone 3 (scheduler) and 4a/4b (clusters)
- Create observability for strategy behavior and debugging
- Balance flexibility for future strategies with simplicity for the two initial strategies

## Non-Goals

- Implementing strategies beyond "Theme of the Week" and "Thematic Rotation"
- Building a UI for strategy configuration (initial version can use CLI/config files)
- Performance optimization (premature for current scale)
- Real-time strategy switching (not in Milestone 4c acceptance criteria)

## Key Design Questions

### 1. Strategy Pattern Architecture

**Decision needed**: How should strategies be implemented?

**Options to explore**:

**A) Plugin/Registry Pattern**
```ruby
# Strategies register themselves
StrategyRegistry.register(:theme_of_week, ThemeOfWeekStrategy)
StrategyRegistry.register(:thematic_rotation, ThematicRotationStrategy)

# Scheduler invokes current strategy
strategy = StrategyRegistry.get(current_strategy_name)
image = strategy.select_image
```

*Pros*: Easy to add new strategies, decoupled, testable
*Cons*: More indirection, requires registry management

**B) Class Hierarchy**
```ruby
class Strategy
  def select_image
    raise NotImplementedError
  end
end

class ThemeOfWeekStrategy < Strategy
  def select_image
    # Implementation
  end
end
```

*Pros*: Simple, familiar OOP pattern, type safety
*Cons*: Can lead to tight coupling, inheritance complexity

**C) Module/Concern Composition**
```ruby
module StrategyBehavior
  def select_image
    raise NotImplementedError
  end
end

class ThemeOfWeek
  include StrategyBehavior
  def select_image; ...; end
end
```

*Pros*: Flexible composition, Ruby idiomatic
*Cons*: Can be harder to reason about, implicit contracts

**Research task**: Compare these approaches with real Rails examples and recommend one.

### 2. State Management

**Decision needed**: How do we persist strategy state?

**State requirements**:
- Active strategy name
- Current cluster (for Theme of the Week)
- Day counter (for 7-day tracking)
- Last rotation index (for Thematic Rotation)
- History of selections

**Options to explore**:

**A) Database Table (ActiveRecord)**
```ruby
# strategy_states table
# - id, strategy_name, state_json, updated_at
StrategyState.current.update(state_json: { cluster_id: 5, day: 3 })
```

**B) Redis/Key-Value Store**
```ruby
REDIS.set('strategy:current', 'theme_of_week')
REDIS.hset('strategy:state', 'cluster_id', 5)
```

**C) Configuration File (YAML)**
```yaml
# config/strategy_state.yml
active_strategy: theme_of_week
state:
  cluster_id: 5
  day_count: 3
```

**Research task**: Evaluate persistence options considering: simplicity, existing infrastructure, concurrency, auditability.

### 3. Cluster Selection for Rotation

**Decision needed**: What order should "Thematic Rotation" use?

**Options to explore**:
- Alphabetical by cluster name
- Chronological by cluster creation date
- Random selection (with tracking to avoid repeats)
- Weighted by cluster size (bigger clusters appear more often)
- User-defined priority list

**Considerations**:
- Should all clusters be included or only curated/named clusters?
- What happens when a new cluster is added mid-rotation?
- Should rotation state reset when clusters change?

**Research task**: Recommend default behavior with rationale and consider configurability.

### 4. Integration Points

**Areas to investigate**:

**With Milestone 3 Scheduler**:
- Where in the posting pipeline does strategy get invoked?
- How does scheduler handle strategy failures?
- What parameters does scheduler pass to strategy?

**With Milestone 4a/4b Clusters**:
- What queries are needed? (e.g., `Cluster.all`, `Cluster.find(id).images.unposted`)
- How to handle cluster not found errors?
- Should strategies cache cluster data?

**With Posting History**:
- How to mark images as posted?
- How to filter already-posted images?
- Should posting history be cluster-aware?

**Research task**: Map out all integration touchpoints and define clear interfaces.

### 5. Error Handling & Edge Cases

**Scenarios to document**:
1. **Strategy runs out of images**: What's the fallback? Switch strategies? Select from all clusters?
2. **Cluster deleted mid-strategy**: Continue with remaining images? Switch strategies? Fail loudly?
3. **User switches strategy mid-week**: Graceful transition? Reset state? Complete current cycle?
4. **No clusters available**: System-wide failure state? Default to unfiltered selection?
5. **Duplicate posting**: Ensure no image is posted twice due to state race conditions

**Research task**: For each scenario, recommend resolution approach with clear reasoning.

## Architecture Principles

**Keep it simple**: Two strategies don't justify complex plugin infrastructure unless extensibility is a clear requirement for Milestone 5+.

**Fail safely**: Strategies should degrade gracefully. If a strategy fails, fallback to simplest strategy or fail with clear error.

**Auditability**: Every strategy decision should be logged. Debugging "why was this image posted" should be straightforward.

**Testability**: Strategies should be unit-testable in isolation from scheduler and database.

## Open Questions

These questions should be answered during research:

1. **Does Milestone 5 roadmap require additional strategies?** (Check if we need extensibility now)
2. **What's the intended user interaction for selecting "Theme of the Week" cluster?** (CLI arg? Config file? Future UI?)
3. **Should strategies be reusable for other platforms?** (Future: Facebook, Twitter)
4. **Is strategy selection dynamic or deploy-time?** (Can users switch without code changes?)
5. **What metrics/observability tools already exist?** (Integrate with existing logging/monitoring)

## Risks & Trade-offs

**Risk**: Over-engineering for two strategies
- *Mitigation*: Research similar systems in Rails ecosystem; follow established patterns

**Risk**: State management bugs in multi-day strategies
- *Mitigation*: Comprehensive testing of state transitions; clear state machine documentation

**Risk**: Tight coupling between strategy and cluster implementation
- *Mitigation*: Define clear interface contracts; use dependency injection

**Risk**: Poor observability makes debugging difficult
- *Mitigation*: Log every decision point; include strategy name in all log lines

## Success Metrics for Research

This design exploration succeeds when:
- [ ] Architecture decision is made with clear rationale documented
- [ ] State management approach handles all identified edge cases
- [ ] Integration points are mapped with defined contracts
- [ ] Error handling approach covers all major failure modes
- [ ] Implementation plan is clear and unblocked

## Next Steps After Design

1. Review design document with stakeholders
2. Get approval on architecture decisions
3. Create implementation proposal based on research findings
4. Begin implementation following the validated design
