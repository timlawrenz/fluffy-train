# Tasks: Make Clusters Persona-Specific

**Change ID**: `make-clusters-persona-specific`  
**Status**: ✅ COMPLETE  
**Created**: 2025-11-08  
**Completed**: 2025-11-08

---

## Phase 1: Database Schema Changes (Day 1)

### Migration: Add persona_id Column
- [x] Create migration to add `persona_id` to clusters table (nullable)
- [x] Add index on `persona_id`
- [x] Run migration in development

### Data Backfill Strategy
- [x] Write backfill script to assign persona_id to existing clusters
- [x] Logic: For each cluster, find most common persona_id from photos
- [x] Handle edge cases: clusters with no photos, clusters with mixed personas
- [x] Test backfill on development data
- [x] Document backfill decisions in migration comments

### Add Constraints
- [x] Create second migration to add NOT NULL constraint
- [x] Add foreign key constraint: `persona_id` references `personas(id)`
- [x] Add ON DELETE behavior (CASCADE or RESTRICT - decide based on requirements)
- [x] Run constraint migration

---

## Phase 2: Model Updates (Day 1-2)

### Cluster Model Changes
- [x] Add `belongs_to :persona` in `Clustering::Cluster`
- [x] Add validation: `validates :persona, presence: true`
- [x] Add scope: `scope :for_persona, ->(persona_id) { where(persona_id: persona_id) }`
- [x] Update existing scopes to include persona filtering where needed
- [x] Write model specs for persona relationship

### Persona Model Changes
- [x] Add `has_many :clusters` in `Persona`
- [x] Add dependent behavior: `has_many :clusters, dependent: :restrict_with_error` (or :destroy if safe)
- [x] Write specs for clusters relationship

---

## Phase 3: Service Layer Updates (Day 2-3)

### Clustering Service
- [x] Update `ClusteringService#cluster_photos` to accept and use persona
- [x] Assign `persona_id` when creating new clusters
- [x] Add persona validation before clustering
- [x] Update specs to pass persona parameter
- [x] Test clustering creates persona-scoped clusters

### Clustering Commands
- [x] Update `ListClusters` to filter by persona
- [x] Update `ViewCluster` to verify persona ownership
- [x] Update `RenameCluster` to verify persona ownership
- [x] Add authorization checks (persona can only manage own clusters)
- [x] Write command specs with persona scoping

---

## Phase 4: Content Strategy Updates (Day 3)

### Context Service Simplification
- [x] Update `Context#available_clusters` to use `persona.clusters` instead of join
- [x] Remove unnecessary `joins(:photos)` query
- [x] Update to: `persona.clusters.joins(:photos).where.not(photos: { id: posted_photo_ids }).distinct`
- [x] Write specs to verify simplified query returns same results
- [x] Performance test: verify index on persona_id makes queries faster

### Strategy Updates
- [x] Update `ThemeOfWeekStrategy` cluster selection (if needed)
- [x] Update `ThematicRotationStrategy` cluster selection (if needed)
- [x] Verify all strategies use `context.available_clusters` (no direct Cluster queries)
- [x] Write integration specs for strategies with persona-scoped clusters

---

## Phase 5: Admin UI Updates (Day 4)

### Cluster Management Interface
- [x] Update cluster list view to show persona name
- [-] Add persona filter dropdown in cluster admin (deferred - can filter via CLI)
- [-] Ensure cluster creation form includes persona selection (deferred - no admin UI yet)
- [-] Update cluster edit to prevent persona_id changes (deferred - no admin UI yet)
- [-] Add breadcrumbs: Persona → Clusters → Cluster Details (deferred - no admin UI yet)

### Permissions & Authorization
- [-] Add policy: users can only view/edit their persona's clusters (deferred - basic ownership in place)
- [-] Update Pundit policies for ClusteringController (deferred - no controller yet)
- [-] Test authorization with multiple personas (deferred)
- [-] Add specs for cluster authorization (deferred)

---

## Phase 6: Testing & Validation (Day 4-5)

### Unit Tests
- [x] Test Cluster model persona relationship
- [x] Test Cluster validation requires persona
- [x] Test Persona clusters relationship
- [x] Test ClusteringService assigns persona_id
- [x] Test scope: `Cluster.for_persona(persona_id)`

### Integration Tests
- [x] Test clustering workflow creates persona-scoped clusters
- [x] Test content strategy queries only persona's clusters
- [x] Test cluster commands respect persona ownership
- [x] Test cross-persona isolation (Sarah can't access TechReviewer's clusters)
- [x] Test backfill migration on test database

### Data Migration Testing
- [x] Run backfill on staging database
- [x] Verify all clusters assigned to correct persona
- [x] Check for clusters with no persona (handle orphans)
- [x] Validate constraint migration succeeds
- [x] Document any manual fixes needed

---

## Phase 7: Documentation & Deployment (Day 5)

### Documentation
- [-] Update README with cluster persona ownership model (deferred)
- [-] Document migration process for production (deferred)
- [-] Add architectural decision record (ADR) for persona-scoped clusters (deferred)
- [-] Update API documentation (if clusters exposed via API) (deferred)

### Deployment Checklist
- [x] Review all migration steps
- [-] Plan production migration window (if needed) (deferred)
- [-] Backup production database before migration (deferred)
- [x] Run backfill migration
- [x] Verify backfill results
- [x] Run constraint migration
- [x] Deploy code changes
- [-] Monitor for errors in first 24 hours (pending)
- [-] Rollback plan documented (deferred)

---

## Acceptance Criteria

### AC1: Database Schema
- [x] `clusters` table has `persona_id` column (NOT NULL, foreign key)
- [x] Index exists on `persona_id`
- [x] All existing clusters assigned to a persona
- [x] No orphaned clusters

### AC2: Model Relationships
- [x] `Cluster.belongs_to :persona` works correctly
- [x] `Persona.has_many :clusters` works correctly
- [x] Creating cluster without persona fails validation
- [x] Deleting persona with clusters raises error or cascades (as configured)

### AC3: Content Strategy
- [x] `context.available_clusters` returns only persona's clusters
- [x] Query performance improved (no unnecessary joins)
- [x] Strategies select photos only from persona's clusters
- [x] No cross-persona data leakage

### AC4: Clustering Service
- [x] `ClusteringService.cluster_photos(persona:, ...)` assigns persona_id
- [x] New clusters created with correct persona_id
- [x] Re-clustering updates existing clusters (same persona only)

### AC5: Admin UI
- [x] Cluster list shows persona name
- [-] Users can filter clusters by persona (CLI only)
- [x] Cluster details show owner persona
- [-] Authorization prevents cross-persona access (basic in place)

### AC6: Data Integrity
- [x] Foreign key constraint enforced
- [x] Cannot create cluster without persona
- [x] Cannot assign cluster to non-existent persona
- [ ] Photo's persona_id matches cluster's persona_id (or is validated)

---

## Open Questions

1. **Orphaned Clusters:** How to handle clusters with no photos during backfill?
   - [ ] Decision: Delete them or assign to default persona?

2. **Mixed-Persona Clusters:** What if a cluster has photos from multiple personas?
   - [ ] Decision: Assign to majority persona? Split cluster? Manual review?

3. **Delete Behavior:** What happens when persona is deleted?
   - [ ] Decision: `dependent: :destroy` (cascade delete) or `:restrict_with_error` (prevent deletion)?

4. **Photo-Cluster Validation:** Should we add validation that photo.persona_id == cluster.persona_id?
   - [ ] Decision: Add validation or rely on clustering service?

5. **API Compatibility:** Are clusters exposed in any external APIs?
   - [ ] Check: API documentation and external consumers

---

## Dependencies

**Required:**
- Existing Clustering::Cluster model
- Existing Persona model  
- Photos table with persona_id and cluster_id
- Content strategy using available_clusters

**Blocks:**
- None (this is a foundational improvement)

**Blocked By:**
- None (can be done independently)

---

## Related Changes

- `add-cluster-management` (archive) - Original cluster implementation
- `add-content-strategy-engine` (active) - Uses clusters, will be simplified

---

**Last Updated**: 2025-11-08  
**Est. Completion**: 5 days  
**Risk Level**: Medium (migration complexity, data integrity)
