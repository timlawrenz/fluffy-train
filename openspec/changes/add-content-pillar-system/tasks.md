# Tasks: Content Pillar System

**Change ID**: `add-content-pillar-system`  
**Status**: Proposal  
**Created**: 2025-11-08

---

## Phase 1: Database Foundation (Day 1)

### Migrations

- [ ] Create migration: `content_pillars` table
  - [ ] Add `persona_id` bigint (FK to personas, NOT NULL, indexed)
  - [ ] Add `name` string (NOT NULL)
  - [ ] Add `description` text
  - [ ] Add `weight` decimal(5,2) (default 0.0, check: >= 0 AND <= 100)
  - [ ] Add `active` boolean (default true, indexed)
  - [ ] Add `start_date` date (nullable)
  - [ ] Add `end_date` date (nullable)
  - [ ] Add `guidelines` jsonb (default {})
  - [ ] Add `target_posts_per_week` integer (nullable)
  - [ ] Add `priority` integer (default 3, check: >= 1 AND <= 5)
  - [ ] Add timestamps
  - [ ] Add unique index on `[persona_id, name]`
  - [ ] Add check constraint: end_date > start_date (when both present)

- [ ] Create migration: `pillar_cluster_assignments` table
  - [ ] Add `pillar_id` bigint (FK to content_pillars, NOT NULL)
  - [ ] Add `cluster_id` bigint (FK to clusters, NOT NULL)
  - [ ] Add `primary` boolean (default false)
  - [ ] Add `notes` text
  - [ ] Add timestamps
  - [ ] Add unique index on `[pillar_id, cluster_id]`
  - [ ] Add FK constraint with CASCADE on delete

- [ ] Run migrations in development
- [ ] Run migrations in test
- [ ] Verify schema with `db:schema:dump`

---

## Phase 2: Model Layer (Day 1-2)

### ContentPillar Model

- [ ] Create `packs/content_pillars/` pack
- [ ] Create `package.yml` with dependencies
- [ ] Create `ContentPillar` model (`app/models/content_pillar.rb`)
  - [ ] Add `belongs_to :persona`
  - [ ] Add `has_many :pillar_cluster_assignments, dependent: :destroy`
  - [ ] Add `has_many :clusters, through: :pillar_cluster_assignments`
  - [ ] Add validation: `validates :name, presence: true, uniqueness: { scope: :persona_id }`
  - [ ] Add validation: `validates :weight, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }`
  - [ ] Add validation: `validate :end_date_after_start_date`
  - [ ] Add scope: `scope :active, -> { where(active: true) }`
  - [ ] Add scope: `scope :current, -> { active.where('start_date IS NULL OR start_date <= ?', Date.current).where('end_date IS NULL OR end_date >= ?', Date.current) }`
  - [ ] Add scope: `scope :by_priority, -> { order(priority: :desc, weight: :desc) }`
  - [ ] Add method: `def current?` (checks date range)
  - [ ] Add method: `def expired?` (past end_date)
  - [ ] Write specs

### PillarClusterAssignment Model

- [ ] Create `PillarClusterAssignment` model
  - [ ] Add `belongs_to :pillar, class_name: 'ContentPillar'`
  - [ ] Add `belongs_to :cluster, class_name: 'Clustering::Cluster'`
  - [ ] Add validation: uniqueness of cluster_id scoped to pillar_id
  - [ ] Add validation: pillar and cluster belong to same persona
  - [ ] Write specs

### Enhanced Cluster Model

- [ ] Update `Clustering::Cluster` model
  - [ ] Add `has_many :pillar_cluster_assignments, dependent: :destroy`
  - [ ] Add `has_many :pillars, through: :pillar_cluster_assignments, source: :pillar`
  - [ ] Add scope: `scope :for_pillar, ->(pillar) { joins(:pillar_cluster_assignments).where(pillar_cluster_assignments: { pillar_id: pillar.id }) }`
  - [ ] Add method: `def primary_pillar`
  - [ ] Add method: `def pillar_names`
  - [ ] Write specs

### Enhanced Persona Model

- [ ] Update `Persona` model
  - [ ] Add `has_many :content_pillars, dependent: :restrict_with_error`
  - [ ] Add validation: `validate :total_pillar_weight_valid`
  - [ ] Add method: `def pillar_weight_total`
  - [ ] Write specs

---

## Phase 3: Services Layer (Day 2-3)

### Gap Analyzer Service

- [ ] Create `ContentPillars::GapAnalyzer` service
  - [ ] Add `.analyze(persona, days_ahead: 30)` method
  - [ ] Calculate posts_needed per pillar (weight-based)
  - [ ] Count available photos (unposted) per pillar
  - [ ] Calculate gap (posts_needed - photos_available)
  - [ ] Return status (:ready, :low, :critical)
  - [ ] Write specs

### Pillar Rotation Service

- [ ] Create `ContentPillars::RotationService` service
  - [ ] Add `.select_next_pillar(persona)` method
  - [ ] Implement weighted rotation algorithm
  - [ ] Consider posting history (underposted pillars prioritized)
  - [ ] Respect date ranges (exclude expired pillars)
  - [ ] Respect active status
  - [ ] Write specs

---

## Phase 4: Strategy Integration (Day 3-4)

### Pillar-Aware SelectNextPost

- [ ] Update `ContentStrategy::SelectNextPost` command
  - [ ] Add pillar selection step
  - [ ] Limit cluster selection to pillar.clusters
  - [ ] Pass pillar to caption generation
  - [ ] Pass pillar to hashtag generation
  - [ ] Write integration specs

### Enhanced Caption Generation

- [ ] Update `CaptionGenerations::PromptBuilder`
  - [ ] Accept `pillar:` parameter
  - [ ] Include pillar guidelines in prompt
  - [ ] Use pillar tone/topics/avoid_topics
  - [ ] Write specs

### Enhanced Hashtag Generation

- [ ] Update `HashtagGenerations::Generator`
  - [ ] Accept `pillar:` parameter
  - [ ] Align hashtags with pillar topics
  - [ ] Write specs

### History Tracking

- [ ] Add `pillar_id` to `content_strategy_histories` table
  - [ ] Migration to add column
  - [ ] Add FK constraint
  - [ ] Add index
- [ ] Update `ContentStrategy::HistoryRecord` model
  - [ ] Add `belongs_to :pillar, optional: true`
  - [ ] Update create calls to include pillar
  - [ ] Write specs

---

## Phase 5: CLI & Management (Day 4-5)

### Pillar Management Rake Tasks

- [ ] Create `lib/tasks/pillars.rake`
  - [ ] Task: `pillars:list` - List all pillars for persona
  - [ ] Task: `pillars:create` - Create new pillar
  - [ ] Task: `pillars:show` - Show pillar details
  - [ ] Task: `pillars:update` - Update pillar attributes
  - [ ] Task: `pillars:deactivate` - Soft delete pillar
  - [ ] Task: `pillars:assign_cluster` - Assign cluster to pillar
  - [ ] Task: `pillars:remove_cluster` - Remove cluster from pillar
  - [ ] Task: `pillars:gaps` - Show gap analysis
  - [ ] Write integration specs

---

## Phase 6: Dashboard Integration (Day 5-6)

### Enhanced Dashboard

- [ ] Update `lib/tasks/content_dashboard.rake`
  - [ ] Add "Content Pillars & Clusters" section
  - [ ] Show pillar hierarchy (pillar → clusters → photos)
  - [ ] Display pillar weights and targets
  - [ ] Show gap analysis per pillar
  - [ ] Indicate shared clusters (multiple pillars)
  - [ ] Provide pillar-specific action items
  - [ ] Write specs

---

## Phase 7: Documentation (Day 6-7)

### User Documentation

- [ ] Create `docs/content-pillars-user-guide.md`
  - [ ] Explain pillar concept
  - [ ] Pillar vs cluster distinction
  - [ ] How to create pillars
  - [ ] How to assign clusters
  - [ ] Gap analysis interpretation
  - [ ] Best practices

### Developer Documentation

- [ ] Update architecture docs
  - [ ] Add pillar system to architecture diagrams
  - [ ] Document data model
  - [ ] Document rotation algorithm
  - [ ] API examples

### Migration Guide

- [ ] Create `docs/pillar-migration-guide.md`
  - [ ] How to organize existing clusters into pillars
  - [ ] Backward compatibility notes
  - [ ] Feature flag usage
  - [ ] Rollout strategy

---

## Phase 8: Testing & Validation (Day 7)

### Integration Testing

- [ ] End-to-end test: Create pillar, assign clusters, select post
- [ ] Test: Multi-pillar posting maintains weight ratios
- [ ] Test: Expired pillars excluded from selection
- [ ] Test: Cluster shared between pillars works correctly
- [ ] Test: Gap analysis accuracy
- [ ] Test: Dashboard displays correctly

### Performance Testing

- [ ] Benchmark pillar selection (< 50ms)
- [ ] Benchmark gap analysis (< 200ms)
- [ ] Benchmark dashboard render (< 500ms)

### Data Integrity Testing

- [ ] Test FK constraints
- [ ] Test weight validation
- [ ] Test date range validation
- [ ] Test persona-scoped isolation

---

## Acceptance Criteria

### AC1: Pillar Management
- [ ] Can create content pillar with strategic attributes
- [ ] Can assign multiple clusters to one pillar
- [ ] Can assign one cluster to multiple pillars
- [ ] Can deactivate pillar
- [ ] Weight validation prevents invalid totals

### AC2: Content Selection
- [ ] Strategy selects pillar based on weights
- [ ] Photo selection limited to pillar's clusters
- [ ] Posting history respects pillar coverage
- [ ] Expired pillars excluded

### AC3: Gap Analysis
- [ ] Accurately calculates posts needed per pillar
- [ ] Counts available photos per pillar
- [ ] Identifies content gaps
- [ ] Prioritizes by severity

### AC4: Dashboard
- [ ] Shows pillar hierarchy
- [ ] Displays gap status
- [ ] Provides actionable recommendations
- [ ] Renders in < 500ms

### AC5: CLI
- [ ] All pillar management tasks work
- [ ] Gap analysis command works
- [ ] Cluster assignment commands work

### AC6: Backward Compatibility
- [ ] Existing cluster-only workflows still function
- [ ] Non-pillar personas unaffected
- [ ] Feature can be disabled via flag

---

## Total: ~92 Tasks
