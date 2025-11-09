# Tasks: Content Pillar System

**Change ID**: `add-content-pillar-system`  
**Status**: Proposal  
**Created**: 2025-11-08

---

## Phase 1: Database Foundation (Day 1)

### Migrations

- [x] Create migration: `content_pillars` table
  - [x] Add `persona_id` bigint (FK to personas, NOT NULL, indexed)
  - [x] Add `name` string (NOT NULL)
  - [x] Add `description` text
  - [x] Add `weight` decimal(5,2) (default 0.0, check: >= 0 AND <= 100)
  - [x] Add `active` boolean (default true, indexed)
  - [x] Add `start_date` date (nullable)
  - [x] Add `end_date` date (nullable)
  - [x] Add `guidelines` jsonb (default {})
  - [x] Add `target_posts_per_week` integer (nullable)
  - [x] Add `priority` integer (default 3, check: >= 1 AND <= 5)
  - [x] Add timestamps
  - [x] Add unique index on `[persona_id, name]`
  - [x] Add check constraint: end_date > start_date (when both present)

- [x] Create migration: `pillar_cluster_assignments` table
  - [x] Add `pillar_id` bigint (FK to content_pillars, NOT NULL)
  - [x] Add `cluster_id` bigint (FK to clusters, NOT NULL)
  - [x] Add `primary` boolean (default false)
  - [x] Add `notes` text
  - [x] Add timestamps
  - [x] Add unique index on `[pillar_id, cluster_id]`
  - [x] Add FK constraint with CASCADE on delete

- [x] Run migrations in development
- [x] Run migrations in test
- [x] Verify schema with `db:schema:dump`

---

## Phase 2: Model Layer (Day 1-2)

### ContentPillar Model

- [x] Create `packs/content_pillars/` pack
- [x] Create `package.yml` with dependencies
- [x] Create `ContentPillar` model (`app/models/content_pillar.rb`)
  - [x] Add `belongs_to :persona`
  - [x] Add `has_many :pillar_cluster_assignments, dependent: :destroy`
  - [x] Add `has_many :clusters, through: :pillar_cluster_assignments`
  - [x] Add validation: `validates :name, presence: true, uniqueness: { scope: :persona_id }`
  - [x] Add validation: `validates :weight, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }`
  - [x] Add validation: `validate :end_date_after_start_date`
  - [x] Add scope: `scope :active, -> { where(active: true) }`
  - [x] Add scope: `scope :current, -> { active.where('start_date IS NULL OR start_date <= ?', Date.current).where('end_date IS NULL OR end_date >= ?', Date.current) }`
  - [x] Add scope: `scope :by_priority, -> { order(priority: :desc, weight: :desc) }`
  - [x] Add method: `def current?` (checks date range)
  - [x] Add method: `def expired?` (past end_date)
  - [ ] Write specs

### PillarClusterAssignment Model

- [x] Create `PillarClusterAssignment` model
  - [x] Add `belongs_to :pillar, class_name: 'ContentPillar'`
  - [x] Add `belongs_to :cluster, class_name: 'Clustering::Cluster'`
  - [x] Add validation: uniqueness of cluster_id scoped to pillar_id
  - [x] Add validation: pillar and cluster belong to same persona
  - [ ] Write specs

### Enhanced Cluster Model

- [x] Update `Clustering::Cluster` model
  - [x] Add `has_many :pillar_cluster_assignments, dependent: :destroy`
  - [x] Add `has_many :pillars, through: :pillar_cluster_assignments, source: :pillar`
  - [x] Add scope: `scope :for_pillar, ->(pillar) { joins(:pillar_cluster_assignments).where(pillar_cluster_assignments: { pillar_id: pillar.id }) }`
  - [x] Add method: `def primary_pillar`
  - [x] Add method: `def pillar_names`
  - [ ] Write specs

### Enhanced Persona Model

- [x] Update `Persona` model
  - [x] Add `has_many :content_pillars, dependent: :restrict_with_error`
  - [x] Add validation: `validate :total_pillar_weight_valid`
  - [x] Add method: `def pillar_weight_total`
  - [ ] Write specs

---

## Phase 3: Services Layer (Day 2-3)

### Gap Analyzer Service

- [x] Create `ContentPillars::GapAnalyzer` service
  - [x] Add `.analyze(persona, days_ahead: 30)` method
  - [x] Calculate posts_needed per pillar (weight-based)
  - [x] Count available photos (unposted) per pillar
  - [x] Calculate gap (posts_needed - photos_available)
  - [x] Return status (:ready, :low, :critical)
  - [ ] Write specs

### Pillar Rotation Service

- [x] Create `ContentPillars::RotationService` service
  - [x] Add `.select_next_pillar(persona)` method
  - [x] Implement weighted rotation algorithm
  - [x] Consider posting history (underposted pillars prioritized)
  - [x] Respect date ranges (exclude expired pillars)
  - [x] Respect active status
  - [ ] Write specs

---

## Phase 4: Strategy Integration (Day 3-4)

### Pillar-Aware SelectNextPost

- [x] Update `ContentStrategy::SelectNextPost` command
  - [x] Add pillar selection step
  - [x] Limit cluster selection to pillar.clusters
  - [x] Pass pillar to caption generation
  - [x] Pass pillar to hashtag generation
  - [ ] Write integration specs

### Enhanced Caption Generation

- [x] Update `CaptionGenerations::PromptBuilder`
  - [x] Accept `pillar:` parameter
  - [x] Include pillar guidelines in prompt
  - [x] Use pillar tone/topics/avoid_topics
  - [ ] Write specs

### Enhanced Hashtag Generation

- [x] Update `HashtagGenerations::Generator`
  - [x] Accept `pillar:` parameter
  - [x] Align hashtags with pillar topics
  - [ ] Write specs

### History Tracking

- [x] Add `pillar_id` to `content_strategy_histories` table
  - [x] Migration to add column
  - [x] Add FK constraint
  - [x] Add index
- [x] Update `ContentStrategy::HistoryRecord` model
  - [x] Add `belongs_to :pillar, optional: true`
  - [x] Update create calls to include pillar
  - [ ] Write specs

---

## Phase 5: CLI & Management (Day 4-5)

### Pillar Management Rake Tasks

- [x] Create `lib/tasks/pillars.rake`
  - [x] Task: `pillars:list` - List all pillars for persona
  - [x] Task: `pillars:create` - Create new pillar
  - [x] Task: `pillars:show` - Show pillar details
  - [x] Task: `pillars:update` - Update pillar attributes
  - [x] Task: `pillars:deactivate` - Soft delete pillar
  - [x] Task: `pillars:assign_cluster` - Assign cluster to pillar
  - [x] Task: `pillars:remove_cluster` - Remove cluster from pillar
  - [x] Task: `pillars:gaps` - Show gap analysis
  - [ ] Write integration specs

---

## Phase 6: Dashboard Integration (Day 5-6)

### Enhanced Dashboard

- [x] Update `lib/tasks/content_dashboard.rake`
  - [x] Add "Content Pillars & Clusters" section
  - [x] Show pillar hierarchy (pillar → clusters → photos)
  - [x] Display pillar weights and targets
  - [x] Show gap analysis per pillar
  - [x] Indicate shared clusters (multiple pillars)
  - [x] Provide pillar-specific action items
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
